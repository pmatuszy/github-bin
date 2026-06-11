#!/usr/bin/env bash
# 2026.06.11 - v. 1.7 - keep old installs as /opt/signal-cli-VERSION; /opt/signal-cli symlink → latest
# 2026.06.11 - v. 1.6 - version check: GitHub release dates; update prompt default [y/N]
# 2026.06.11 - v. 1.5 - x86_64: prebuilt signal-cli-VERSION-Linux-native.tar.gz (no Java/Rust/JNI); Pi/arm keeps JNI path
# 2026.06.11 - v. 1.4 - prompts: drop "(single key, Enter not required)" hint line
# 2026.06.11 - v. 1.3 - step 1: detect running signal-cli silently (no process list); still warn before install
# 2026.06.11 - v. 1.2 - if signal-cli daemon is running: skip version exec (hangs); read version from /opt symlinks; prompt before install
# 2026.06.11 - v. 1.1 - verbose progress: log each step; timeout on signal-cli version probe; visible GitHub/download status
# 2026.06.11 - v. 1.0 - initial release: check installed/latest signal-cli; prompt install/update on Raspberry Pi (libsignal JNI build)
#
# signal-install.sh
#
# x86_64 Linux: official GraalVM native build (signal-cli-VERSION-Linux-native.tar.gz)
# Pi / arm: JVM tarball + libsignal JNI build — procedure from:
#   https://github.com/pmatuszy/signal-cli-on-Raspberry-PI---WORKS-
#
# Releases: https://github.com/AsamK/signal-cli/releases
# protoc:   https://github.com/protocolbuffers/protobuf/releases (Pi/arm path only)
#

set -euo pipefail

SIGNAL_CLI_REPO="AsamK/signal-cli"
PROTOBUF_REPO="protocolbuffers/protobuf"
INSTALL_OPT="/opt"
BIN_LINK="/usr/local/bin/signal-cli"
CURRENT_LINK="${INSTALL_OPT}/signal-cli"
JAVA_JNI_DIR="/usr/java/packages/lib"
TEMP_CATALOG="${TEMP_CATALOG:-/mnt/signal-temp}"
ASSUME_YES=0
VERBOSE=1
NETWORK_TIMEOUT_SEC="${NETWORK_TIMEOUT_SEC:-60}"
SIGNAL_CLI_PROBE_TIMEOUT_SEC="${SIGNAL_CLI_PROBE_TIMEOUT_SEC:-20}"
RELEASE_PUBLISHED_DATE=""

TMP_WORK_DIR=""
cleanup_tmp_work_dir() {
    if [[ -n "${TMP_WORK_DIR:-}" && -d "${TMP_WORK_DIR}" ]]; then
        rm -rf "${TMP_WORK_DIR}"
    fi
}
trap cleanup_tmp_work_dir EXIT

print_version_banner() {
    local ver=unknown date= line title verline width=60
    while IFS= read -r line; do
        if [[ "$line" =~ ^#\ ([0-9]{4}\.[0-9]{2}\.[0-9]{2})\ -\ v\.\ ([0-9]+(\.[0-9]+)*) ]]; then
            date="${BASH_REMATCH[1]}"
            ver="${BASH_REMATCH[2]}"
            break
        fi
    done < "$0"
    title="$(basename "$0")"
    if [[ -n "$date" ]]; then
        verline="Version: ${ver} (${date})"
    else
        verline="Version: ${ver}"
    fi
    printf '┌%*s┐\n' "$width" '' | tr ' ' '─'
    printf '│ %-*.*s │\n' $((width - 2)) $((width - 2)) "$title"
    printf '│ %-*.*s │\n' $((width - 2)) $((width - 2)) "$verline"
    printf '└%*s┘\n' "$width" '' | tr ' ' '─'
}

show_help() {
    cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [-y|--yes] [-q|--quiet] [--no_startup_delay]

Check the installed signal-cli version (if any), compare with the latest GitHub
release, and optionally install or update. On x86_64 Linux uses the prebuilt
Linux-native tarball; on Raspberry Pi / arm builds libsignal JNI from source.

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  -y, --yes            Install/update without prompting (non-interactive OK).
  -q, --quiet          Less progress output (errors still shown).
  --no_startup_delay   Skip random startup delay when run non-interactively.

Environment:
  TEMP_CATALOG                  Build workspace (default: /mnt/signal-temp).
  NETWORK_TIMEOUT_SEC           curl/wget timeout for GitHub queries (default: 60).
  SIGNAL_CLI_PROBE_TIMEOUT_SEC  timeout for probing installed signal-cli (default: 20).
EOF
}

log_step() {
    (( VERBOSE == 1 )) || return 0
    printf '>>> %s\n' "$*" >&2
}

log_note() {
    (( VERBOSE == 1 )) || return 0
    printf '    %s\n' "$*" >&2
}

need_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "ERROR: Required command not found: $1" >&2
        exit 1
    fi
}

as_root_check() {
    if [[ "${EUID}" -ne 0 ]]; then
        echo "ERROR: Please run as root, for example:" >&2
        echo "  sudo bash $0" >&2
        exit 1
    fi
}

download_file() {
    local url="$1"
    local output="$2"

    log_step "Downloading: ${url}"
    log_note "Saving to: ${output}"

    if command -v curl >/dev/null 2>&1; then
        if (( VERBOSE == 1 )) && tty >/dev/null 2>&1; then
            curl -fL --connect-timeout "${NETWORK_TIMEOUT_SEC}" --max-time "${NETWORK_TIMEOUT_SEC}" \
                --progress-bar "$url" -o "$output"
            echo >&2
        else
            curl -fsSL --connect-timeout "${NETWORK_TIMEOUT_SEC}" --max-time "${NETWORK_TIMEOUT_SEC}" \
                "$url" -o "$output"
        fi
    elif command -v wget >/dev/null 2>&1; then
        wget --timeout="${NETWORK_TIMEOUT_SEC}" "$url" -O "$output"
    else
        echo "ERROR: Need curl or wget." >&2
        exit 1
    fi

    log_note "Download finished ($(du -h "$output" 2>/dev/null | awk '{print $1}' || echo '?'))"
}

fetch_url() {
    local url="$1"
    log_step "Fetching URL (timeout ${NETWORK_TIMEOUT_SEC}s): ${url}"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL --connect-timeout "${NETWORK_TIMEOUT_SEC}" --max-time "${NETWORK_TIMEOUT_SEC}" "$url"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- --timeout="${NETWORK_TIMEOUT_SEC}" "$url"
    else
        echo "ERROR: Need curl or wget." >&2
        exit 1
    fi
}

format_github_release_date() {
    local iso="$1"
    if [[ -z "${iso}" ]]; then
        echo "unknown"
        return 0
    fi
    if [[ "${iso}" =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2}) ]]; then
        echo "${BASH_REMATCH[1]}.${BASH_REMATCH[2]}.${BASH_REMATCH[3]}"
        return 0
    fi
    echo "${iso}"
}

# Fetch signal-cli release metadata from GitHub. Empty version = latest.
# Sets RELEASE_PUBLISHED_DATE; prints version on stdout.
github_fetch_signal_cli_release() {
    local version="${1:-}"
    local json tag api_url published

    RELEASE_PUBLISHED_DATE=""

    if [[ -z "${version}" ]]; then
        api_url="https://api.github.com/repos/${SIGNAL_CLI_REPO}/releases/latest"
        log_step "Querying GitHub for latest ${SIGNAL_CLI_REPO} release..."
    else
        api_url="https://api.github.com/repos/${SIGNAL_CLI_REPO}/releases/tags/v${version}"
        log_note "Querying GitHub for ${SIGNAL_CLI_REPO} release v${version}..."
    fi
    log_note "${api_url}"

    if ! json="$(fetch_url "${api_url}" 2>/dev/null)"; then
        RELEASE_PUBLISHED_DATE="unknown"
        return 1
    fi

    tag="$(printf '%s\n' "$json" | grep -m1 '"tag_name"' | sed -E 's/.*"tag_name"[[:space:]]*:[[:space:]]*"v?([^"]+)".*/\1/')"
    published="$(printf '%s\n' "$json" | grep -m1 '"published_at"' | sed -E 's/.*"published_at"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')"
    RELEASE_PUBLISHED_DATE="$(format_github_release_date "${published}")"

    if [[ ! "$tag" =~ ^[0-9]+(\.[0-9]+)+$ ]]; then
        RELEASE_PUBLISHED_DATE="unknown"
        if [[ -n "${version}" ]]; then
            return 1
        fi
        echo "ERROR: Could not parse latest release version for ${SIGNAL_CLI_REPO} (got '${tag}')." >&2
        exit 1
    fi

    log_note "Release ${tag} published: ${RELEASE_PUBLISHED_DATE}"
    echo "${tag}"
}

github_latest_release_version() {
    local repo="$1"
    local json tag api_url

    api_url="https://api.github.com/repos/${repo}/releases/latest"
    log_step "Querying GitHub for latest ${repo} release..."
    log_note "${api_url}"

    json="$(fetch_url "${api_url}")"
    tag="$(printf '%s\n' "$json" | grep -m1 '"tag_name"' | sed -E 's/.*"tag_name"[[:space:]]*:[[:space:]]*"v?([^"]+)".*/\1/')"
    if [[ ! "$tag" =~ ^[0-9]+(\.[0-9]+)+$ ]]; then
        echo "ERROR: Could not parse latest release version for ${repo} (got '${tag}')." >&2
        exit 1
    fi
    log_note "Latest ${repo} release: ${tag}"
    echo "${tag}"
}

format_version_with_release_date() {
    local ver="$1" date="$2"

    if [[ -z "${ver}" ]]; then
        echo "not installed"
        return 0
    fi

    if [[ -n "${date}" && "${date}" != "unknown" ]]; then
        echo "${ver} (released ${date})"
    else
        echo "${ver}"
    fi
}

parse_signal_cli_version_output() {
    local text="$1"
    printf '%s\n' "$text" | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n1
}

version_from_install_path() {
    local path="$1"
    [[ -n "${path}" ]] || return 1
    if [[ "${path}" =~ signal-cli-([0-9]+\.[0-9]+(\.[0-9]+)?) ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    fi
    return 1
}

signal_cli_versioned_path() {
    echo "${INSTALL_OPT}/signal-cli-${1}"
}

# Legacy installs used a flat /opt/signal-cli file — rename before upgrading.
migrate_legacy_flat_native_binary() {
    local installed_version="$1"
    local versioned="" probed="" out=""

    if [[ ! -f "${CURRENT_LINK}" || -L "${CURRENT_LINK}" ]]; then
        return 0
    fi

    if [[ -z "${installed_version}" ]]; then
        if command -v timeout >/dev/null 2>&1; then
            out="$(timeout 5 "${CURRENT_LINK}" version 2>/dev/null || true)"
        else
            out="$("${CURRENT_LINK}" version 2>/dev/null || true)"
        fi
        installed_version="$(parse_signal_cli_version_output "${out}")"
        [[ -n "${installed_version}" ]] || installed_version="legacy"
    fi

    versioned="$(signal_cli_versioned_path "${installed_version}")"
    if [[ -e "${versioned}" ]]; then
        versioned="$(signal_cli_versioned_path "${installed_version}-backup-$(date +%Y%m%d%H%M%S)")"
    fi

    log_step "Preserving previous install as ${versioned}"
    mv -v "${CURRENT_LINK}" "${versioned}"
}

link_signal_cli_active_version() {
    local version="$1"
    local kind="$2"
    local versioned=""

    versioned="$(signal_cli_versioned_path "${version}")"

    if [[ "${kind}" == "jvm" ]]; then
        if [[ ! -x "${versioned}/bin/signal-cli" ]]; then
            echo "ERROR: JVM install not found: ${versioned}/bin/signal-cli" >&2
            exit 1
        fi
        log_step "Pointing active symlinks to ${versioned}"
        ln -sfn "${versioned}" "${CURRENT_LINK}"
        ln -sfn "${versioned}/bin/signal-cli" "${BIN_LINK}"
    else
        if [[ ! -f "${versioned}" ]]; then
            echo "ERROR: Native binary not found: ${versioned}" >&2
            exit 1
        fi
        log_step "Pointing active symlinks to ${versioned}"
        ln -sfn "${versioned}" "${CURRENT_LINK}"
        ln -sfn "${CURRENT_LINK}" "${BIN_LINK}"
    fi

    ls -l "${BIN_LINK}" "${CURRENT_LINK}"
}

list_preserved_signal_cli_versions() {
    local entry="" vers="" found=0
    for entry in "${INSTALL_OPT}"/signal-cli-[0-9]*; do
        [[ -e "${entry}" ]] || continue
        vers="$(version_from_install_path "${entry}" || true)"
        [[ -n "${vers}" ]] || continue
        if (( found == 0 )); then
            echo "  Preserved under ${INSTALL_OPT}/:"
            found=1
        fi
        echo "    signal-cli-${vers}"
    done
}

get_installed_signal_cli_version_from_filesystem() {
    local target="" vers="" candidate

    if [[ -L "${CURRENT_LINK}" ]]; then
        target="$(readlink -f "${CURRENT_LINK}" 2>/dev/null || true)"
        vers="$(version_from_install_path "${target}" || true)"
        if [[ -n "${vers}" ]]; then
            log_note "Installed version from ${CURRENT_LINK} -> ${target}: ${vers}"
            echo "${vers}"
            return 0
        fi
    fi

    if [[ -L "${BIN_LINK}" ]]; then
        target="$(readlink -f "${BIN_LINK}" 2>/dev/null || true)"
        vers="$(version_from_install_path "${target}" || true)"
        if [[ -n "${vers}" ]]; then
            log_note "Installed version from ${BIN_LINK} -> ${target}: ${vers}"
            echo "${vers}"
            return 0
        fi
    fi

    for candidate in "${INSTALL_OPT}"/signal-cli-[0-9]*; do
        [[ -d "${candidate}" ]] || continue
        vers="$(version_from_install_path "${candidate}" || true)"
        if [[ -n "${vers}" ]]; then
            log_note "Installed version inferred from directory ${candidate}: ${vers}"
            echo "${vers}"
            return 0
        fi
    done

    return 1
}

signal_cli_running_pids() {
  pgrep -af '[s]ignal-cli' 2>/dev/null || true
}

signal_cli_is_running() {
    local pids
    pids="$(signal_cli_running_pids)"
    [[ -n "${pids}" ]]
}

prompt_stop_signal_cli_before_install() {
    local pids="" reply=""

    pids="$(signal_cli_running_pids)"
    [[ -n "${pids}" ]] || return 0

    echo
    echo "signal-cli is still running:"
    printf '%s\n' "${pids}" | sed 's/^/  /'
    echo
    echo "Updating while the daemon runs can fail or leave a stale process using old files."
    echo "Stop it first (examples):"
    echo "  systemctl stop signal-cli"
    echo "  pkill -f 'signal-cli.*daemon'"
    echo

    if (( ASSUME_YES == 1 )); then
        log_note "Continuing anyway because --yes was given."
        return 0
    fi

    echo ">>> Waiting for your answer:"
    echo -n "Continue install/update without stopping signal-cli? [y/N] "
    read -r -n 1 reply || reply=""
    echo
    case "${reply}" in
        y|Y|yes|YES) log_note "Continuing while signal-cli is running (at your risk)." ;;
        *)
            echo "Quitting — stop signal-cli and run this script again."
            exit 0
            ;;
    esac
}

get_installed_signal_cli_version() {
    local exe="" out="" rc=0 vers=""

    if signal_cli_is_running; then
        if vers="$(get_installed_signal_cli_version_from_filesystem)"; then
            echo "${vers}"
            return 0
        fi
        return 0
    fi

    if vers="$(get_installed_signal_cli_version_from_filesystem)"; then
        log_note "Using install-path version (no need to exec signal-cli): ${vers}"
        echo "${vers}"
        return 0
    fi

    if command -v signal-cli >/dev/null 2>&1; then
        exe="$(command -v signal-cli)"
    elif [[ -x "${BIN_LINK}" ]]; then
        exe="${BIN_LINK}"
    fi

    if [[ -z "${exe}" ]]; then
        log_note "No signal-cli binary found on PATH or at ${BIN_LINK}"
        return 0
    fi

    log_step "Probing installed signal-cli (timeout ${SIGNAL_CLI_PROBE_TIMEOUT_SEC}s): ${exe}"
    if command -v timeout >/dev/null 2>&1; then
        out="$(timeout "${SIGNAL_CLI_PROBE_TIMEOUT_SEC}" "${exe}" version 2>&1)" || rc=$?
    else
        out="$("${exe}" version 2>&1)" || rc=$?
    fi

    if (( rc == 124 )); then
        log_note "WARNING: signal-cli version probe timed out after ${SIGNAL_CLI_PROBE_TIMEOUT_SEC}s."
        if vers="$(get_installed_signal_cli_version_from_filesystem)"; then
            log_note "Falling back to install-path version: ${vers}"
            echo "${vers}"
            return 0
        fi
        log_note "Install-path version also unknown."
        return 0
    fi
    if (( rc != 0 )); then
        log_note "WARNING: signal-cli version probe failed (exit ${rc}); output:"
        printf '%s\n' "$out" | sed 's/^/    /' >&2
        if vers="$(get_installed_signal_cli_version_from_filesystem)"; then
            log_note "Falling back to install-path version: ${vers}"
            echo "${vers}"
            return 0
        fi
        return 0
    fi

    log_note "signal-cli reported: $(printf '%s' "$out" | tr '\n' ' ')"
    parse_signal_cli_version_output "$out"
}

version_is_newer_than() {
    local a="$1" b="$2"
    [[ "$(printf '%s\n%s\n' "$b" "$a" | sort -V | tail -n1)" == "$a" && "$a" != "$b" ]]
}

detect_machine() {
    local hw arch rust_target protoc_arch

    hw="$(uname -m)"
    arch="$(uname --hardware-platform 2>/dev/null || uname -m)"

    case "${hw}" in
        x86_64|amd64)
            INSTALL_METHOD="native_x86_64"
            INSTALL_METHOD_LABEL="prebuilt Linux-native binary (x86_64)"
            rust_target=""
            ;;
        aarch64|arm64)
            INSTALL_METHOD="pi_jni"
            INSTALL_METHOD_LABEL="JVM tarball + libsignal JNI build (arm64)"
            rust_target="nightly-aarch64-unknown-linux-gnu"
            ;;
        armv7l|armv6l)
            INSTALL_METHOD="pi_jni"
            INSTALL_METHOD_LABEL="JVM tarball + libsignal JNI build (arm)"
            rust_target="nightly-armv7-unknown-linux-gnueabihf"
            ;;
        *)
            echo "ERROR: Unsupported CPU architecture: ${hw}" >&2
            echo "Supported: x86_64 (native), aarch64/arm (JNI build)." >&2
            exit 1
            ;;
    esac

    protoc_arch="${arch}"
    protoc_arch="${protoc_arch/aarch64/aarch_64}"

    MACHINE_HW="${hw}"
    PROTOC_ARCHITECTURE="${protoc_arch}"
    RUST_TARGET="${rust_target}"
}

is_pi_jni_install_method() {
    [[ "${INSTALL_METHOD}" == "pi_jni" ]]
}

check_platform_for_install_method() {
    if [[ "${INSTALL_METHOD}" == "native_x86_64" ]]; then
        echo "Install method: ${INSTALL_METHOD_LABEL}"
        return 0
    fi

    if grep -q "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
        echo "Running on Raspberry Pi hardware."
        echo "Install method: ${INSTALL_METHOD_LABEL}"
        return 0
    fi

    echo "WARNING: This does not look like Raspberry Pi hardware."
    echo "The libsignal JNI build procedure was written for Raspberry Pi aarch64."
    if (( ASSUME_YES == 0 )) && tty >/dev/null 2>&1; then
        echo -n "Continue with JNI build anyway? [y/N] "
        local reply=""
        read -r -n 1 reply || reply=""
        echo
        case "${reply}" in
            y|Y) ;;
            *) echo "Quitting."; exit 0 ;;
        esac
    elif (( ASSUME_YES == 0 )); then
        echo "ERROR: Not a Raspberry Pi and --yes was not given." >&2
        exit 1
    fi
}

prompt_install_or_update() {
    local latest="$1" installed="$2" latest_date="$3" installed_date="$4" reply=""

    echo
    echo "signal-cli version check:"
    echo "  Installed: $(format_version_with_release_date "${installed}" "${installed_date}")"
    echo "  Latest:    $(format_version_with_release_date "${latest}" "${latest_date}")"
    echo

    if [[ -z "${installed}" ]]; then
        if (( ASSUME_YES == 1 )); then
            echo "Proceeding with fresh install (--yes)."
            return 0
        fi
        echo
        echo ">>> Waiting for your answer:"
        echo -n "Install signal-cli ${latest} now? [Y/n] "
        read -r -n 1 reply || reply=""
        echo
        case "${reply}" in
            n|N|no|NO) echo "Quitting — no changes made."; exit 0 ;;
            *) echo "Proceeding with install..." ;;
        esac
        return 0
    fi

    if [[ "${installed}" == "${latest}" ]]; then
        if (( ASSUME_YES == 1 )); then
            echo "Reinstalling latest version (--yes)."
            return 0
        fi
        echo "You already have the latest version."
        echo
        echo ">>> Waiting for your answer:"
        if is_pi_jni_install_method; then
            echo -n "Reinstall / rebuild JNI anyway? [y/N] "
        else
            echo -n "Reinstall anyway? [y/N] "
        fi
        read -r -n 1 reply || reply=""
        echo
        case "${reply}" in
            y|Y|yes|YES) echo "Proceeding with reinstall..." ;;
            *) echo "Quitting — no changes made."; exit 0 ;;
        esac
        return 0
    fi

    if version_is_newer_than "${latest}" "${installed}"; then
        if (( ASSUME_YES == 1 )); then
            echo "Updating ${installed} -> ${latest} (--yes)."
            return 0
        fi
        echo
        echo ">>> Waiting for your answer:"
        echo -n "Update signal-cli ${installed} -> ${latest} now? [y/N] "
        read -r -n 1 reply || reply=""
        echo
        case "${reply}" in
            y|Y|yes|YES) echo "Proceeding with update..." ;;
            *) echo "Quitting — no changes made."; exit 0 ;;
        esac
        return 0
    fi

    echo "Installed version (${installed}) is newer than the published latest (${latest})."
    if (( ASSUME_YES == 1 )); then
        echo "Proceeding with reinstall of ${latest} (--yes)."
        return 0
    fi
    echo
    echo ">>> Waiting for your answer:"
    echo -n "Reinstall published version ${latest} anyway? [y/N] "
    read -r -n 1 reply || reply=""
    echo
    case "${reply}" in
        y|Y|yes|YES) echo "Proceeding..." ;;
        *) echo "Quitting — no changes made."; exit 0 ;;
    esac
}

ensure_download_tools() {
    if command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1; then
        return 0
    fi
    log_step "Installing curl (needed for downloads)..."
    apt-get update
    apt-get install -y curl
}

install_apt_dependencies() {
    echo
    echo "part 1 — apt dependencies"
    echo
    log_step "Running apt-get update..."
    apt-get update
    log_step "Installing build/runtime packages..."
    apt-get install -y curl zip protobuf-compiler clang libclang-dev cmake make unzip wget
    log_step "Installing OpenJDK 21..."
    apt-get install -y openjdk-21-jdk
    log_note "apt dependencies done."
}

install_protoc() {
    local protoc_version="$1"
    local protoc_zip url

    echo
    echo "part 2 — protoc ${protoc_version}"
    echo

    protoc_zip="protoc-${protoc_version}-linux-${PROTOC_ARCHITECTURE}.zip"
    url="https://github.com/protocolbuffers/protobuf/releases/download/v${protoc_version}/${protoc_zip}"

    cd /tmp
    download_file "${url}" "${protoc_zip}"
    log_step "Installing protoc into /usr/local..."
    unzip -o "${protoc_zip}" -d /usr/local bin/protoc
    unzip -o "${protoc_zip}" -d /usr/local 'include/*'
    rm -f "${protoc_zip}"
    log_note "Installed: $(protoc --version 2>&1)"
}

prepare_opt_and_download_signal_cli() {
    local version="$1"
    local installed_version="${2:-}"
    local archive url versioned

    echo
    echo "part 3 — signal-cli ${version} into ${INSTALL_OPT}"
    echo

    versioned="$(signal_cli_versioned_path "${version}")"
    migrate_legacy_flat_native_binary "${installed_version}"

    cd "${INSTALL_OPT}"
    log_step "Cleaning leftover download artifacts in ${INSTALL_OPT}..."
    rm -fv "signal-cli-${version}-Linux-native.tar.gz"* 2>/dev/null || true

    archive="signal-cli-${version}.tar.gz"
    url="https://github.com/AsamK/signal-cli/releases/download/v${version}/${archive}"

    if [[ -d "${versioned}" ]]; then
        log_note "Existing ${versioned} will be updated in place (older versions are kept)."
    fi

    download_file "${url}" "${archive}"
    log_step "Extracting ${archive} into ${INSTALL_OPT}..."
    tar xf "${archive}" -C "${INSTALL_OPT}"
    rm -fv "${archive}"

    link_signal_cli_active_version "${version}" jvm
}

prepare_opt_and_download_signal_cli_native() {
    local version="$1"
    local installed_version="${2:-}"
    local archive url versioned extracted_bin tmp_archive

    echo
    echo "part 1 — signal-cli ${version} Linux-native into ${INSTALL_OPT}"
    echo

    versioned="$(signal_cli_versioned_path "${version}")"
    migrate_legacy_flat_native_binary "${installed_version}"

    archive="signal-cli-${version}-Linux-native.tar.gz"
    url="https://github.com/AsamK/signal-cli/releases/download/v${version}/${archive}"

    TMP_WORK_DIR="$(mktemp -d)"
    tmp_archive="${TMP_WORK_DIR}/${archive}"

    download_file "${url}" "${tmp_archive}"
    log_step "Extracting ${archive}..."
    tar xf "${tmp_archive}" -C "${TMP_WORK_DIR}"
    rm -fv "${tmp_archive}"

    extracted_bin="${TMP_WORK_DIR}/signal-cli"
    if [[ ! -f "${extracted_bin}" ]]; then
        extracted_bin="$(find "${TMP_WORK_DIR}" -type f -name signal-cli 2>/dev/null | head -n1)"
    fi
    if [[ -z "${extracted_bin}" || ! -f "${extracted_bin}" ]]; then
        echo "ERROR: signal-cli binary not found inside ${archive}." >&2
        exit 1
    fi

    log_step "Installing native binary to ${versioned}"
    install -m 755 "${extracted_bin}" "${versioned}"
    chown root:root "${versioned}"

    link_signal_cli_active_version "${version}" native
}

install_rust_toolchain() {
    echo
    echo "part 4 — rust toolchain (${RUST_TARGET})"
    echo

    if [[ -z "${RUST_TARGET}" ]]; then
        echo "ERROR: Unsupported CPU for rust JNI build: ${MACHINE_HW}" >&2
        exit 1
    fi

    if [[ -x "${HOME}/.cargo/bin/rustc" ]]; then
        log_note "rustup already present: $("${HOME}/.cargo/bin/rustc" --version 2>/dev/null || true)"
    else
        log_step "Installing rustup (this can take several minutes)..."
        curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain "${RUST_TARGET}" -y
    fi

    # shellcheck disable=SC1091
    source "${HOME}/.cargo/env" 2>/dev/null || export PATH="${PATH}:${HOME}/.cargo/bin"
    log_step "Selecting rust toolchain ${RUST_TARGET}..."
    rustup default "${RUST_TARGET}" 2>/dev/null || true
    log_note "Active rustc: $(rustc --version 2>&1)"
}

build_and_install_libsignal_jni() {
    local version="$1"
    local libversion jar_path jni_so build_root

    echo
    echo "part 5 — libsignal JNI for signal-cli ${version}"
    echo

    jar_path="$(find "${INSTALL_OPT}/signal-cli-${version}/lib/" -maxdepth 1 -mindepth 1 -name 'libsignal-client-*.jar' | head -n1)"
    if [[ -z "${jar_path}" ]]; then
        echo "ERROR: libsignal-client jar not found under ${INSTALL_OPT}/signal-cli-${version}/lib/" >&2
        exit 1
    fi

    libversion="$(basename "${jar_path}" | sed -E 's/^libsignal-client-//; s/\.jar$//')"
    log_note "libsignal-client jar: ${jar_path}"
    log_note "LIBVERSION = ${libversion}"

    mkdir -p "${TEMP_CATALOG}/signal-cli-install"
    build_root="${TEMP_CATALOG}/signal-cli-install"
    cd "${build_root}"

    download_file "https://github.com/signalapp/libsignal/archive/refs/tags/v${libversion}.tar.gz" "v${libversion}.tar.gz"
    log_step "Extracting libsignal sources..."
    tar xzf "v${libversion}.tar.gz"
    rm -fv "v${libversion}.tar.gz"
    mv -v "libsignal-${libversion}" libsignal

    log_step "Patching libsignal settings.gradle (remove android module)..."
    sed -i "s/include ':android'//" "${build_root}/libsignal/java/settings.gradle"
    log_step "Building libsignal JNI (this is the slow step — often 10–30+ minutes on a Pi)..."
    "${build_root}/libsignal/java/build_jni.sh" desktop

    jni_so="$(find "${build_root}/libsignal/target" -path '*/release/libsignal_jni.so' 2>/dev/null | head -n1)"
    if [[ -z "${jni_so}" || ! -f "${jni_so}" ]]; then
        echo "ERROR: libsignal_jni.so not found after build." >&2
        exit 1
    fi

    log_step "Patching jar with native libsignal_jni.so..."
    zip -d "${jar_path}" libsignal_jni.so 2>/dev/null || true
    zip "${jar_path}" "${jni_so}"

    mkdir -p "${JAVA_JNI_DIR}"
    log_step "Installing JNI library to ${JAVA_JNI_DIR}..."
    cp -v "${jni_so}" "${JAVA_JNI_DIR}/"
}

finalize_permissions_pi() {
    local version="$1"

    echo
    echo "part 6 — permissions and cleanup"
    echo

    chown root:root "${JAVA_JNI_DIR}/libsignal_jni.so"
    chmod 755 "${JAVA_JNI_DIR}/libsignal_jni.so"
    chmod 755 -R "${INSTALL_OPT}/signal-cli-${version}"
    chown root:root -R "${INSTALL_OPT}/signal-cli-${version}"

    rm -rf "${TEMP_CATALOG}/signal-cli-install"
}

verify_installation() {
    echo
    echo "part 7 — verify"
    echo
    cd /
    signal-cli version
}

perform_install_native() {
    local signal_version="$1"
    local installed_version="${2:-}"

    ensure_download_tools
    need_cmd tar
    need_cmd find
    need_cmd install
    need_cmd ln
    need_cmd chmod
    need_cmd chown

    prepare_opt_and_download_signal_cli_native "${signal_version}" "${installed_version}"
    verify_installation

    echo
    echo "signal-cli installed/updated successfully (Linux-native)."
    echo "  Version: $(get_installed_signal_cli_version)"
    echo "  Active:  ${CURRENT_LINK} -> $(readlink -f "${CURRENT_LINK}" 2>/dev/null || echo '?')"
    echo "  Binary:  ${BIN_LINK}"
    list_preserved_signal_cli_versions
}

perform_install_pi() {
    local signal_version="$1"
    local protoc_version="$2"
    local installed_version="${3:-}"

    install_apt_dependencies
    install_protoc "${protoc_version}"
    prepare_opt_and_download_signal_cli "${signal_version}" "${installed_version}"
    install_rust_toolchain
    build_and_install_libsignal_jni "${signal_version}"
    finalize_permissions_pi "${signal_version}"
    verify_installation

    echo
    echo "signal-cli installed/updated successfully."
    echo "  Version: $(get_installed_signal_cli_version)"
    echo "  Active:  ${CURRENT_LINK} -> $(readlink -f "${CURRENT_LINK}" 2>/dev/null || echo '?')"
    echo "  Binary:  ${BIN_LINK}"
    list_preserved_signal_cli_versions
}

main() {
    local installed="" latest="" protoc_latest="" latest_date="" installed_date=""

    log_step "Starting signal-cli install/update check..."
    as_root_check
    detect_machine
    check_platform_for_install_method

    log_step "Checking required local commands..."
    need_cmd grep
    need_cmd sed
    need_cmd sort
    if is_pi_jni_install_method; then
        need_cmd tar
        need_cmd zip
        need_cmd find
        need_cmd ln
        need_cmd mkdir
        need_cmd chown
        need_cmd chmod
    fi

    echo "Machine: ${MACHINE_HW} (protoc arch label: ${PROTOC_ARCHITECTURE})"
    echo

    if is_pi_jni_install_method; then
        log_step "Step 1/3 — detect installed signal-cli version"
    else
        log_step "Step 1/2 — detect installed signal-cli version"
    fi
    installed="$(get_installed_signal_cli_version)"

    if is_pi_jni_install_method; then
        log_step "Step 2/3 — fetch latest signal-cli release from GitHub"
    else
        log_step "Step 2/2 — fetch latest signal-cli release from GitHub"
    fi
    latest="$(github_fetch_signal_cli_release)"
    latest_date="${RELEASE_PUBLISHED_DATE}"

    if [[ -n "${installed}" ]]; then
        if github_fetch_signal_cli_release "${installed}" >/dev/null; then
            installed_date="${RELEASE_PUBLISHED_DATE}"
        else
            installed_date="unknown"
        fi
    fi

    if is_pi_jni_install_method; then
        log_step "Step 3/3 — fetch latest protoc release from GitHub"
        protoc_latest="$(github_latest_release_version "${PROTOBUF_REPO}")"
    fi

    log_step "Version check complete."
    prompt_install_or_update "${latest}" "${installed}" "${latest_date}" "${installed_date}"
    prompt_stop_signal_cli_before_install

    echo
    echo "Will install:"
    echo "  signal-cli: ${latest}"
    echo "  method:     ${INSTALL_METHOD_LABEL}"
    if is_pi_jni_install_method; then
        echo "  protoc:     ${protoc_latest}"
        echo "  temp dir:   ${TEMP_CATALOG}/signal-cli-install"
    else
        echo "  package:    signal-cli-${latest}-Linux-native.tar.gz"
    fi
    echo

    if [[ "${INSTALL_METHOD}" == "native_x86_64" ]]; then
        perform_install_native "${latest}" "${installed}"
    else
        perform_install_pi "${latest}" "${protoc_latest}" "${installed}"
    fi
}

HEADER_EXTRA_ARGS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help) show_help; exit 0 ;;
        -v|--version) print_version_banner; exit 0 ;;
        -y|--yes) ASSUME_YES=1; shift ;;
        -q|--quiet) VERBOSE=0; shift ;;
        --no_startup_delay) HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY); shift ;;
        *) echo "Unknown argument: $1" >&2; echo "Try: $(basename "$0") --help" >&2; exit 1 ;;
    esac
done

if [[ -f /root/bin/_script_header.sh ]]; then
    # shellcheck disable=SC1091
    . /root/bin/_script_header.sh "${HEADER_EXTRA_ARGS[@]}"
fi

main "$@"

if [[ -f /root/bin/_script_footer.sh ]]; then
    # shellcheck disable=SC1091
    . /root/bin/_script_footer.sh
fi
