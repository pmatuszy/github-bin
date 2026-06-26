#!/usr/bin/env bash
# 2026.06.26 - v. 1.6 - run exiftool/perl with C.UTF-8 (or C) to avoid locale warnings on minimal systems
# 2026.06.17 - v. 1.5 - tarball downloads from SourceForge (exiftool.org tar.gz returns 404)
# 2026.06.14 - v. 1.4 - when ExifTool not found: prompt to install [y/N] default N, 300s timeout
# 2026.05.31 - v. 1.3 - update/reinstall prompt reads a single key (no Enter required)
# 2026.05.31 - v. 1.2 - fix "tmpdir: unbound variable" in EXIT trap (global TMP_WORK_DIR + guarded cleanup)
# 2026.05.31 - v. 1.1 - if exiftool already installed: print version and ask to update/reinstall or quit
# 2026.05.31 - v. 1.0 - initial release: install latest ExifTool under /usr/local and create symlinks
#
# video-pgm-install-exiftool.sh
#
# Installs the latest ExifTool under:
#   /usr/local/Image-ExifTool-<version>
#
# Creates/updates symlinks:
#   /usr/local/exiftool      -> /usr/local/Image-ExifTool-<version>
#   /usr/local/bin/exiftool  -> /usr/local/exiftool/exiftool
#
# Official latest version:
#   https://exiftool.org/ver.txt
#
# Full Linux/Unix tarball (since ~2026, not hosted on exiftool.org):
#   https://downloads.sourceforge.net/project/exiftool/Image-ExifTool-<version>.tar.gz
#

set -euo pipefail

BASE_URL="https://exiftool.org"
VERSION_URL="${BASE_URL}/ver.txt"
DOWNLOAD_BASE="https://downloads.sourceforge.net/project/exiftool"
INSTALL_BASE="/usr/local"
BIN_DIR="/usr/local/bin"

TMP_WORK_DIR=""
cleanup_tmp_work_dir() {
    if [[ -n "${TMP_WORK_DIR:-}" && -d "${TMP_WORK_DIR}" ]]; then
        rm -rf "${TMP_WORK_DIR}"
    fi
}
trap cleanup_tmp_work_dir EXIT

INSTALL_EXIFTOOL_READ_TIMEOUT="${INSTALL_EXIFTOOL_READ_TIMEOUT:-300}"

flush_stdin() {
    while read -r -t 0.001 -n 10000 _garbage 2>/dev/null; do :; done
}

# Read one key (no Enter). Sets REPLY; empty answer uses default_key.
exiftool_read_key() {
    local prompt="$1"
    local default_key="${2:-}"
    local timeout="${3:-${INSTALL_EXIFTOOL_READ_TIMEOUT}}"
    local answer=""

    if [[ ! -t 0 ]]; then
        REPLY="$default_key"
        return 0
    fi

    printf '%s' "$prompt"
    flush_stdin
    if [[ "$timeout" =~ ^[0-9]+$ ]] && (( timeout > 0 )); then
        read -t "$timeout" -n 1 answer || answer=""
    else
        read -n 1 answer || answer=""
    fi
    echo
    if [[ -z "$answer" ]]; then
        REPLY="$default_key"
    else
        REPLY="$answer"
    fi
}

need_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "ERROR: Required command not found: $1" >&2
        exit 1
    fi
}

# Perl warns when LANG/LC_* point at locales not generated on the system (common on minimal VMs).
exiftool_pick_locale() {
    local loc
    while IFS= read -r loc; do
        [[ -n "$loc" ]] || continue
        if locale -a 2>/dev/null | LC_ALL=C grep -Fxq "$loc"; then
            printf '%s' "$loc"
            return 0
        fi
    done <<'EOF'
C.UTF-8
C.utf8
POSIX
C
EOF
    printf '%s' 'C'
}

run_exiftool() {
    local lc
    lc="$(exiftool_pick_locale)"
    env LC_ALL="$lc" LANG="$lc" LANGUAGE= "$@"
}

as_root_check() {
    if [[ "${EUID}" -ne 0 ]]; then
        echo "ERROR: Please run as root, for example:" >&2
        echo "  sudo bash $0" >&2
        exit 1
    fi
}

detect_platform() {
    local os arch

    os="$(uname -s)"
    arch="$(uname -m)"

    if [[ "${os}" != "Linux" ]]; then
        echo "ERROR: This installer is for Linux only. Detected OS: ${os}" >&2
        exit 1
    fi

    case "${arch}" in
        x86_64|amd64)
            PLATFORM="linux-x86_64"
            ;;
        i386|i686)
            PLATFORM="linux-x86"
            ;;
        aarch64|arm64)
            PLATFORM="linux-arm64"
            ;;
        armv7l|armv6l|arm)
            PLATFORM="linux-arm"
            ;;
        *)
            echo "ERROR: Unsupported Linux architecture: ${arch}" >&2
            exit 1
            ;;
    esac

    echo "Detected platform: ${PLATFORM}"
    echo "Note: ExifTool official Linux/Unix package is Perl-based and not CPU-specific."
}

download_file() {
    local url="$1"
    local output="$2"

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" -o "$output"
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$url" -O "$output"
    else
        echo "ERROR: Need curl or wget." >&2
        exit 1
    fi
}

get_latest_version() {
    local version

    version="$(download_file "${VERSION_URL}" - | tr -d '[:space:]')"

    if [[ ! "${version}" =~ ^[0-9]+(\.[0-9]+)+$ ]]; then
        echo "ERROR: Invalid ExifTool version received: '${version}'" >&2
        exit 1
    fi

    echo "${version}"
}

exiftool_archive_url() {
    local version="$1"
    printf '%s/Image-ExifTool-%s.tar.gz' "${DOWNLOAD_BASE}" "${version}"
}

# Print the currently installed exiftool version (empty if none/unreadable).
get_installed_version() {
    local exe="$1"
    local v=""

    [[ -n "${exe}" ]] || return 0
    if [[ -x "${exe}" ]] || command -v "${exe}" >/dev/null 2>&1; then
        v="$(run_exiftool "${exe}" -ver 2>/dev/null | tr -d '[:space:]')" || v=""
    fi
    echo "${v}"
}

# When ExifTool is missing, ask before downloading (default no; 300s timeout).
prompt_install_if_missing() {
    local latest="$1"

    echo "No ExifTool found on this system."
    echo "  Latest available version: ${latest}"
    if [[ ! -t 0 ]]; then
        echo "Non-interactive session — not installing (default [N])."
        exit 0
    fi
    exiftool_read_key "Install ExifTool now? [y/N]: " n "${INSTALL_EXIFTOOL_READ_TIMEOUT}"
    case "${REPLY}" in
        y|Y) echo "Proceeding with install..." ;;
        *) echo "Quitting — no changes made."; exit 0 ;;
    esac
}

# If exiftool is already installed, show its version and ask: update/install or quit.
prompt_if_already_installed() {
    local latest="$1"
    local bin_link="$2"
    local found_exe="" installed=""
    local reply=""

    if command -v exiftool >/dev/null 2>&1; then
        found_exe="$(command -v exiftool)"
    elif [[ -x "${bin_link}" ]]; then
        found_exe="${bin_link}"
    fi

    if [[ -z "${found_exe}" ]]; then
        prompt_install_if_missing "${latest}"
        return 0
    fi

    installed="$(get_installed_version "${found_exe}")"
    echo "ExifTool is already installed:"
    echo "  Command: ${found_exe}"
    echo "  Installed version: ${installed:-unknown}"
    echo "  Latest version:    ${latest}"

    if [[ -n "${installed}" && "${installed}" == "${latest}" ]]; then
        echo "You already have the latest version."
        echo -n "Reinstall it anyway? [y/N] "
    else
        echo -n "Update/install version ${latest} now? [Y/n] "
    fi

    read -r -n 1 reply || reply=""
    echo

    if [[ -n "${installed}" && "${installed}" == "${latest}" ]]; then
        case "${reply}" in
            y|Y|yes|YES) echo "Reinstalling..." ;;
            *) echo "Quitting — no changes made."; exit 0 ;;
        esac
    else
        case "${reply}" in
            n|N|no|NO) echo "Quitting — no changes made."; exit 0 ;;
            *) echo "Proceeding with update/install..." ;;
        esac
    fi
}

main() {
    as_root_check
    detect_platform

    need_cmd perl
    need_cmd tar
    need_cmd gzip
    need_cmd ln
    need_cmd mkdir
    need_cmd rm

    local version archive url extracted_dir target_dir current_link bin_link

    version="$(get_latest_version)"
    archive="Image-ExifTool-${version}.tar.gz"
    url="$(exiftool_archive_url "${version}")"

    extracted_dir="Image-ExifTool-${version}"
    target_dir="${INSTALL_BASE}/${extracted_dir}"
    current_link="${INSTALL_BASE}/exiftool"
    bin_link="${BIN_DIR}/exiftool"

    echo "Latest ExifTool version: ${version}"

    prompt_if_already_installed "${version}" "${bin_link}"

    echo "Download URL: ${url}"
    echo "Install target: ${target_dir}"

    TMP_WORK_DIR="$(mktemp -d)"

    cd "$TMP_WORK_DIR"

    echo "Downloading ${archive}..."
    download_file "$url" "$archive"

    echo "Extracting..."
    tar -xzf "$archive"

    if [[ ! -x "${extracted_dir}/exiftool" ]]; then
        echo "ERROR: Extracted exiftool executable not found." >&2
        exit 1
    fi

    echo "Testing downloaded ExifTool..."
    run_exiftool perl "${extracted_dir}/exiftool" -ver >/dev/null

    if [[ -d "${target_dir}" ]]; then
        echo "Target already exists: ${target_dir}"
        echo "Leaving existing directory in place."
    else
        echo "Installing to ${target_dir}..."
        mv "${extracted_dir}" "${target_dir}"
    fi

    echo "Creating symlink: ${current_link} -> ${target_dir}"
    ln -sfn "${target_dir}" "${current_link}"

    mkdir -p "${BIN_DIR}"

    echo "Creating symlink: ${bin_link} -> ${current_link}/exiftool"
    ln -sfn "${current_link}/exiftool" "${bin_link}"

    echo "Verifying installation..."
    run_exiftool "${bin_link}" -ver

    echo
    echo "ExifTool installed successfully."
    echo "Version: $(run_exiftool "${bin_link}" -ver)"
    echo "Directory: ${target_dir}"
    echo "Current symlink: ${current_link}"
    echo "Command: ${bin_link}"
}

main "$@"
