#!/usr/bin/env bash
# 2026.06.11 - v. 1.0 - install/update static FFmpeg (John Van Sickle builds) under /opt/ffmpeg-YYYYMMDD
#
# ffmpeg-install.sh
#
# Static builds: https://johnvansickle.com/ffmpeg/
# Git (master) builds are recommended for bug fixes; release builds are also available.
#

set -euo pipefail

FFMPEG_BASE_URL="https://johnvansickle.com/ffmpeg"
INSTALL_OPT="/opt"
BIN_FFMPEG="/usr/local/bin/ffmpeg"
BIN_FFPROBE="/usr/local/bin/ffprobe"
CURRENT_LINK="${INSTALL_OPT}/ffmpeg"
TEMP_CATALOG="${TEMP_CATALOG:-/mnt/ffmpeg-temp}"
FFMPEG_BUILD_KIND="${FFMPEG_BUILD_KIND:-git}"
ASSUME_YES=0
VERBOSE=1
NETWORK_TIMEOUT_SEC="${NETWORK_TIMEOUT_SEC:-120}"
FFMPEG_PROBE_TIMEOUT_SEC="${FFMPEG_PROBE_TIMEOUT_SEC:-15}"
REMOTE_BUILD_DATE=""
REMOTE_BUILD_LABEL=""

MACHINE_HW=""
FFMPEG_ARCH=""
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
Usage: $(basename "$0") [-h|--help] [-v|--version] [-y|--yes] [-q|--quiet] [--release] [--no_startup_delay]

Check the installed static FFmpeg build (if any), compare with the latest build on
johnvansickle.com for this CPU architecture, and optionally install or update.

Install layout:
  /opt/ffmpeg-YYYYMMDD/     versioned static build (ffmpeg, ffprobe, ...)
  /opt/ffmpeg               symlink to active build
  /usr/local/bin/ffmpeg     symlink into active build
  /usr/local/bin/ffprobe    symlink into active build

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  -y, --yes            Install/update without prompting (non-interactive OK).
  -q, --quiet          Less progress output (errors still shown).
  --release            Use release static builds instead of git (master) builds.
  --no_startup_delay   Skip random startup delay when run non-interactively.

Environment:
  TEMP_CATALOG              Download/extract workspace (default: /mnt/ffmpeg-temp).
  FFMPEG_BUILD_KIND         git (default) or release — same as --release when set to release.
  NETWORK_TIMEOUT_SEC       curl/wget timeout in seconds (default: 120).
  FFMPEG_PROBE_TIMEOUT_SEC  timeout for probing installed ffmpeg (default: 15).
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

http_head_field() {
    local url="$1"
    local field="$2"
    local headers=""

    if command -v curl >/dev/null 2>&1; then
        headers="$(curl -fsI --connect-timeout "${NETWORK_TIMEOUT_SEC}" --max-time "${NETWORK_TIMEOUT_SEC}" "$url" 2>/dev/null || true)"
    elif command -v wget >/dev/null 2>&1; then
        headers="$(wget --server-response --spider --timeout="${NETWORK_TIMEOUT_SEC}" "$url" 2>&1 || true)"
    else
        return 1
    fi

    printf '%s\n' "${headers}" | tr -d '\r' | awk -v want="${field}" '
        BEGIN { IGNORECASE = 1 }
        $1 == want ":" { sub(/^[^:]*:[[:space:]]*/, ""); print; exit }
    '
}

format_build_date_display() {
    local id="$1"
    if [[ "${id}" =~ ^([0-9]{4})([0-9]{2})([0-9]{2})$ ]]; then
        echo "${BASH_REMATCH[1]}.${BASH_REMATCH[2]}.${BASH_REMATCH[3]}"
        return 0
    fi
    [[ -n "${id}" ]] && echo "${id}" || echo "unknown"
}

format_build_with_date() {
    local build_id="$1" date_label="$2"
    if [[ -n "${build_id}" ]]; then
        if [[ -n "${date_label}" && "${date_label}" != "unknown" ]]; then
            echo "build ${build_id} (dated ${date_label})"
        else
            echo "build ${build_id}"
        fi
    else
        echo "not installed"
    fi
}

build_id_from_http_date() {
    local http_date="$1"
    if [[ "${http_date}" =~ ^[A-Za-z]{3},\ ([0-9]{1,2})\ ([A-Za-z]{3})\ ([0-9]{4}) ]]; then
        date -d "${http_date}" +%Y%m%d 2>/dev/null && return 0
    fi
    return 1
}

ffmpeg_tarball_basename() {
    if [[ "${FFMPEG_BUILD_KIND}" == "release" ]]; then
        echo "ffmpeg-release-${FFMPEG_ARCH}-static.tar.xz"
    else
        echo "ffmpeg-git-${FFMPEG_ARCH}-static.tar.xz"
    fi
}

ffmpeg_tarball_url() {
    local base="${FFMPEG_BASE_URL}"
    if [[ "${FFMPEG_BUILD_KIND}" == "release" ]]; then
        echo "${base}/releases/$(ffmpeg_tarball_basename)"
    else
        echo "${base}/builds/$(ffmpeg_tarball_basename)"
    fi
}

fetch_remote_build_metadata() {
    local url last_modified build_id=""

    REMOTE_BUILD_DATE=""
    REMOTE_BUILD_LABEL=""

    url="$(ffmpeg_tarball_url)"
    log_step "Checking remote static build (${FFMPEG_BUILD_KIND}, ${FFMPEG_ARCH})..."
    log_note "${url}"

    last_modified="$(http_head_field "${url}" "Last-Modified" || true)"
    if [[ -n "${last_modified}" ]]; then
        build_id="$(build_id_from_http_date "${last_modified}" || true)"
        if [[ -n "${build_id}" ]]; then
            REMOTE_BUILD_DATE="$(format_build_date_display "${build_id}")"
            REMOTE_BUILD_LABEL="${build_id}"
            log_note "Remote tarball last modified: ${REMOTE_BUILD_DATE}"
            return 0
        fi
    fi

    REMOTE_BUILD_DATE="unknown"
    REMOTE_BUILD_LABEL="latest"
    log_note "Could not read remote build date from HTTP headers; will compare after download."
}

detect_machine() {
    local hw="$1"
    MACHINE_HW="${hw}"
    case "${hw}" in
        x86_64|amd64) FFMPEG_ARCH="amd64" ;;
        aarch64|arm64) FFMPEG_ARCH="arm64" ;;
        i686|i386) FFMPEG_ARCH="i686" ;;
        armv7l|armv6l) FFMPEG_ARCH="armhf" ;;
        *)
            echo "ERROR: Unsupported CPU architecture for static FFmpeg: ${hw}" >&2
            echo "Supported: x86_64, aarch64/arm64, i686, armv7l (armhf)." >&2
            exit 1
            ;;
    esac
}

ffmpeg_versioned_path() {
    echo "${INSTALL_OPT}/ffmpeg-${1}"
}

version_from_install_path() {
    local path="$1"
    [[ -n "${path}" ]] || return 1
    if [[ "${path}" =~ /ffmpeg-([0-9]{8})(/|$) ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    fi
    return 1
}

resolve_active_ffmpeg_exe() {
    local target=""

    for target in "${BIN_FFMPEG}" "${CURRENT_LINK}/ffmpeg"; do
        if [[ -L "${target}" || -e "${target}" ]]; then
            target="$(readlink -f "${target}" 2>/dev/null || true)"
            if [[ -n "${target}" && -x "${target}" && ! -d "${target}" ]]; then
                echo "${target}"
                return 0
            fi
        fi
    done

    if command -v ffmpeg >/dev/null 2>&1; then
        command -v ffmpeg
        return 0
    fi

    return 1
}

resolve_active_ffprobe_exe() {
    local target=""

    for target in "${BIN_FFPROBE}" "${CURRENT_LINK}/ffprobe"; do
        if [[ -L "${target}" || -e "${target}" ]]; then
            target="$(readlink -f "${target}" 2>/dev/null || true)"
            if [[ -n "${target}" && -x "${target}" && ! -d "${target}" ]]; then
                echo "${target}"
                return 0
            fi
        fi
    done

    if command -v ffprobe >/dev/null 2>&1; then
        command -v ffprobe
        return 0
    fi

    return 1
}

parse_build_id_from_ffmpeg_version() {
    local text="$1"
    if [[ "${text}" =~ ffmpeg-git-([0-9]{8}) ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    fi
    if [[ "${text}" =~ ffmpeg-release-([0-9]{8}) ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    fi
    return 1
}

get_installed_build_id_from_filesystem() {
    local exe="" tree="" build_id="" target=""

    exe="$(resolve_active_ffmpeg_exe || true)"
    if [[ -n "${exe}" ]]; then
        build_id="$(version_from_install_path "${exe}" || true)"
        if [[ -n "${build_id}" ]]; then
            log_note "Installed build from active path ${exe}: ${build_id}"
            echo "${build_id}"
            return 0
        fi
    fi

    if [[ -L "${CURRENT_LINK}" ]]; then
        target="$(readlink -f "${CURRENT_LINK}" 2>/dev/null || true)"
        build_id="$(version_from_install_path "${target}" || true)"
        if [[ -n "${build_id}" ]]; then
            log_note "Installed build from ${CURRENT_LINK} -> ${target}: ${build_id}"
            echo "${build_id}"
            return 0
        fi
    fi

    return 1
}

get_installed_build_id() {
    local exe="" out="" rc=0 build_id=""

    exe="$(resolve_active_ffmpeg_exe || true)"
    if [[ -z "${exe}" ]]; then
        log_note "No active ffmpeg binary found (${BIN_FFMPEG}, ${CURRENT_LINK})"
        return 0
    fi

    log_step "Probing active ffmpeg (timeout ${FFMPEG_PROBE_TIMEOUT_SEC}s): ${exe}"
    if command -v timeout >/dev/null 2>&1; then
        out="$(timeout "${FFMPEG_PROBE_TIMEOUT_SEC}" "${exe}" -version 2>&1)" || rc=$?
    else
        out="$("${exe}" -version 2>&1)" || rc=$?
    fi

    if (( rc == 0 )); then
        build_id="$(parse_build_id_from_ffmpeg_version "${out}" || true)"
        if [[ -n "${build_id}" ]]; then
            log_note "Active ffmpeg reported: $(printf '%s' "${out}" | head -n1 | tr '\n' ' ')"
            echo "${build_id}"
            return 0
        fi
        log_note "Active ffmpeg: $(printf '%s' "${out}" | head -n1 | tr '\n' ' ')"
    elif (( rc != 124 )); then
        log_note "WARNING: ffmpeg version probe failed (exit ${rc})"
    fi

    if build_id="$(get_installed_build_id_from_filesystem)"; then
        log_note "Using active install path build id: ${build_id}"
        echo "${build_id}"
        return 0
    fi

    log_note "Active ffmpeg build id could not be determined."
    return 0
}

version_is_newer_than() {
    local a="$1" b="$2"
    [[ "$(printf '%s\n%s\n' "$b" "$a" | sort -V | tail -n1)" == "$a" && "$a" != "$b" ]]
}

get_active_ffmpeg_install_target() {
    readlink -f "${CURRENT_LINK}" 2>/dev/null || true
}

is_active_ffmpeg_install() {
    local entry="$1" active_target=""
    active_target="$(get_active_ffmpeg_install_target)"
    [[ -n "${active_target}" && "${entry}" == "${active_target}" ]]
}

list_preserved_ffmpeg_versions() {
    local entry="" found=0
    for entry in "${INSTALL_OPT}"/ffmpeg-[0-9]*; do
        [[ -e "${entry}" ]] || continue
        if (( found == 0 )); then
            echo "  Installs under ${INSTALL_OPT}/:"
            found=1
        fi
        if is_active_ffmpeg_install "${entry}"; then
            echo "    $(basename "${entry}")  (active)"
        else
            echo "    $(basename "${entry}")"
        fi
    done
}

collect_old_ffmpeg_install_paths() {
    local entry=""
    for entry in "${INSTALL_OPT}"/ffmpeg-[0-9]*; do
        [[ -e "${entry}" ]] || continue
        is_active_ffmpeg_install "${entry}" && continue
        printf '%s\n' "${entry}"
    done
}

prompt_remove_old_ffmpeg_installs() {
    local old_paths=() path="" reply="" name="" build_id=""

    while IFS= read -r path; do
        [[ -n "${path}" ]] && old_paths+=("${path}")
    done < <(collect_old_ffmpeg_install_paths | sort -V)

    ((${#old_paths[@]} > 0)) || return 0

    echo
    echo "Older ffmpeg install(s) found (not active):"
    for path in "${old_paths[@]}"; do
        build_id="$(version_from_install_path "${path}" || true)"
        if [[ -n "${build_id}" ]]; then
            echo "  ffmpeg-${build_id}"
        else
            echo "  $(basename "${path}")"
        fi
    done
    echo

    if (( ASSUME_YES == 1 )); then
        log_note "Keeping old installs (--yes, no removal prompt)."
        return 0
    fi

    for path in "${old_paths[@]}"; do
        build_id="$(version_from_install_path "${path}" || true)"
        name="ffmpeg-${build_id:-$(basename "${path}")}"

        echo ">>> Waiting for your answer:"
        echo -n "Remove ${name}? [y/N] "
        read -r -n 1 reply || reply=""
        echo
        case "${reply}" in
            y|Y|yes|YES)
                log_step "Removing old install: ${path}"
                rm -rf "${path}"
                ;;
            *) log_note "Keeping ${name}." ;;
        esac
    done
}

quit_prompt_with_optional_old_cleanup() {
    prompt_remove_old_ffmpeg_installs
    exit 0
}

build_id_is_known() {
    [[ "${1}" =~ ^[0-9]{8}$ ]]
}

prompt_install_or_update() {
    local latest="$1" installed="$2" latest_date="$3" installed_date="$4" reply=""
    local latest_known=0

    build_id_is_known "${latest}" && latest_known=1

    echo
    echo "ffmpeg static build check (${FFMPEG_BUILD_KIND}, ${FFMPEG_ARCH}):"
    echo "  Installed: $(format_build_with_date "${installed}" "${installed_date}")"
    if (( latest_known == 1 )); then
        echo "  Latest:    $(format_build_with_date "${latest}" "${latest_date}")"
    else
        echo "  Latest:    remote build date unknown (will verify after download)"
    fi
    echo

    if [[ -z "${installed}" ]]; then
        if (( ASSUME_YES == 1 )); then
            echo "Proceeding with fresh install (--yes)."
            return 0
        fi
        echo
        echo ">>> Waiting for your answer:"
        echo -n "Install static ffmpeg now? [Y/n] "
        read -r -n 1 reply || reply=""
        echo
        case "${reply}" in
            n|N|no|NO) echo "Quitting — no changes made."; quit_prompt_with_optional_old_cleanup ;;
            *) echo "Proceeding with install..." ;;
        esac
        return 0
    fi

    if (( latest_known == 0 )); then
        if (( ASSUME_YES == 1 )); then
            echo "Downloading latest static build (--yes)."
            return 0
        fi
        echo
        echo ">>> Waiting for your answer:"
        echo -n "Download and install/replace static ffmpeg? [y/N] "
        read -r -n 1 reply || reply=""
        echo
        case "${reply}" in
            y|Y|yes|YES) echo "Proceeding with download..." ;;
            *) echo "Quitting — no changes made."; quit_prompt_with_optional_old_cleanup ;;
        esac
        return 0
    fi

    if [[ "${installed}" == "${latest}" ]]; then
        if (( ASSUME_YES == 1 )); then
            echo "Reinstalling latest build (--yes)."
            return 0
        fi
        echo "You already have the latest detected build."
        echo
        echo ">>> Waiting for your answer:"
        echo -n "Reinstall anyway? [y/N] "
        read -r -n 1 reply || reply=""
        echo
        case "${reply}" in
            y|Y|yes|YES) echo "Proceeding with reinstall..." ;;
            *) echo "Quitting — no changes made."; quit_prompt_with_optional_old_cleanup ;;
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
        echo -n "Update ffmpeg build ${installed} -> ${latest} now? [y/N] "
        read -r -n 1 reply || reply=""
        echo
        case "${reply}" in
            y|Y|yes|YES) echo "Proceeding with update..." ;;
            *) echo "Quitting — no changes made."; quit_prompt_with_optional_old_cleanup ;;
        esac
        return 0
    fi

    echo "Installed build (${installed}) is newer than the detected remote build (${latest})."
    if (( ASSUME_YES == 1 )); then
        echo "Proceeding with reinstall of ${latest} (--yes)."
        return 0
    fi
    echo
    echo ">>> Waiting for your answer:"
    echo -n "Reinstall detected remote build ${latest} anyway? [y/N] "
    read -r -n 1 reply || reply=""
    echo
    case "${reply}" in
        y|Y|yes|YES) echo "Proceeding..." ;;
        *) echo "Quitting — no changes made."; quit_prompt_with_optional_old_cleanup ;;
    esac
}

verify_tarball_md5() {
    local tarball="$1"
    local md5_file="${tarball}.md5"
    local base dir

    if ! command -v md5sum >/dev/null 2>&1; then
        log_note "md5sum not available — skipping checksum verification."
        return 0
    fi

    base="$(basename "${tarball}")"
    dir="$(dirname "${tarball}")"
    download_file "$(ffmpeg_tarball_url).md5" "${md5_file}"
    log_step "Verifying ${base} checksum..."
    ( cd "${dir}" && md5sum -c "${base}.md5" )
    rm -f "${md5_file}"
}

build_id_from_extracted_dir() {
    local dir="$1"
    local name=""
    name="$(basename "${dir}")"
    if [[ "${name}" =~ ffmpeg-(git|release)-([0-9]{8})- ]]; then
        echo "${BASH_REMATCH[2]}"
        return 0
    fi
    return 1
}

link_ffmpeg_active_version() {
    local build_id="$1"
    local versioned=""

    versioned="$(ffmpeg_versioned_path "${build_id}")"
    if [[ ! -x "${versioned}/ffmpeg" ]]; then
        echo "ERROR: ffmpeg binary not found: ${versioned}/ffmpeg" >&2
        exit 1
    fi

    log_step "Pointing active symlinks to ${versioned}"
    ln -sfn "${versioned}" "${CURRENT_LINK}"
    ln -sfn "${versioned}/ffmpeg" "${BIN_FFMPEG}"
    if [[ -x "${versioned}/ffprobe" ]]; then
        ln -sfn "${versioned}/ffprobe" "${BIN_FFPROBE}"
    fi
    ls -l "${BIN_FFMPEG}" "${BIN_FFPROBE}" "${CURRENT_LINK}" 2>/dev/null || ls -l "${BIN_FFMPEG}" "${CURRENT_LINK}"
}

perform_install() {
    local installed_build_id="${1:-}"
    local tarball url extracted_dir build_id="" versioned="" installed_versioned=""

    echo
    echo "part 1 — download static ffmpeg (${FFMPEG_BUILD_KIND}, ${FFMPEG_ARCH})"
    echo

    need_cmd tar
    need_cmd find
    need_cmd ln
    need_cmd mkdir
    need_cmd chmod
    need_cmd chown

    mkdir -p "${TEMP_CATALOG}"
    TMP_WORK_DIR="$(mktemp -d "${TEMP_CATALOG}/ffmpeg-install.XXXXXX")"
    tarball="${TMP_WORK_DIR}/$(ffmpeg_tarball_basename)"
    url="$(ffmpeg_tarball_url)"

    download_file "${url}" "${tarball}"
    verify_tarball_md5 "${tarball}"

    echo
    echo "part 2 — extract and install under ${INSTALL_OPT}"
    echo

    tar -xJf "${tarball}" -C "${TMP_WORK_DIR}"
    extracted_dir="$(find "${TMP_WORK_DIR}" -maxdepth 1 -mindepth 1 -type d -name 'ffmpeg-*-static' | head -n1)"
    if [[ -z "${extracted_dir}" || ! -d "${extracted_dir}" ]]; then
        echo "ERROR: extracted ffmpeg directory not found." >&2
        exit 1
    fi

    build_id="$(build_id_from_extracted_dir "${extracted_dir}" || true)"
    if [[ -z "${build_id}" ]]; then
        build_id="$(date +%Y%m%d)"
        log_note "Could not parse build date from directory name; using ${build_id}."
    fi
    log_note "Extracted: $(basename "${extracted_dir}")"
    log_note "Build id: ${build_id}"

    versioned="$(ffmpeg_versioned_path "${build_id}")"
    if [[ -d "${versioned}" ]]; then
        log_note "Replacing existing ${versioned}"
        rm -rf "${versioned}"
    fi

    mv -v "${extracted_dir}" "${versioned}"
    chmod 755 -R "${versioned}"
    chown root:root -R "${versioned}"

    link_ffmpeg_active_version "${build_id}"

    echo
    echo "part 3 — verify"
    echo

    if command -v timeout >/dev/null 2>&1; then
        timeout "${FFMPEG_PROBE_TIMEOUT_SEC}" ffmpeg -version | head -n3
        timeout "${FFMPEG_PROBE_TIMEOUT_SEC}" ffprobe -version | head -n1
    else
        ffmpeg -version | head -n3
        ffprobe -version | head -n1
    fi

    echo
    echo "ffmpeg installed/updated successfully."
    echo "  Build:   ${build_id} ($(format_build_date_display "${build_id}"))"
    echo "  Kind:    ${FFMPEG_BUILD_KIND}"
    echo "  Active:  ${CURRENT_LINK} -> $(readlink -f "${CURRENT_LINK}" 2>/dev/null || echo '?')"
    echo "  Binary:  ${BIN_FFMPEG}"
    list_preserved_ffmpeg_versions
    prompt_remove_old_ffmpeg_installs
}

main() {
    local installed="" latest="" installed_date="" latest_date=""

    log_step "Starting static ffmpeg install/update check..."
    as_root_check
    detect_machine "$(uname -m)"
    fetch_remote_build_metadata

    echo "Machine: ${MACHINE_HW} (static arch label: ${FFMPEG_ARCH})"
    echo "Build kind: ${FFMPEG_BUILD_KIND}"
    echo

    log_step "Step 1/2 — detect installed ffmpeg build"
    installed="$(get_installed_build_id)"
    if [[ -n "${installed}" ]]; then
        installed_date="$(format_build_date_display "${installed}")"
    fi

    log_step "Step 2/2 — compare with remote static build"
    latest="${REMOTE_BUILD_LABEL}"
    latest_date="${REMOTE_BUILD_DATE}"
    if ! build_id_is_known "${latest}"; then
        latest=""
        latest_date=""
    fi

    log_step "Version check complete."
    prompt_install_or_update "${latest}" "${installed}" "${latest_date}" "${installed_date}"

    echo
    echo "Will install:"
    echo "  package: $(ffmpeg_tarball_basename)"
    echo "  url:     $(ffmpeg_tarball_url)"
    echo "  temp:    ${TEMP_CATALOG}"
    echo

    perform_install "${installed}"
}

HEADER_EXTRA_ARGS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help) show_help; exit 0 ;;
        -v|--version) print_version_banner; exit 0 ;;
        -y|--yes) ASSUME_YES=1; shift ;;
        -q|--quiet) VERBOSE=0; shift ;;
        --release) FFMPEG_BUILD_KIND="release"; shift ;;
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
