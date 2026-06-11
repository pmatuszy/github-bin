#!/usr/bin/env bash
# 2026.06.11 - v. 1.4 - third option: build static from ffmpeg.org official release source
# 2026.06.11 - v. 1.3 - install prompts default [y/N]; fix installed-metadata subshell; ffmpeg.org HTML parse
# 2026.06.11 - v. 1.2 - ffmpeg.org latest; static first then apt dynamic; move old installs aside
# 2026.06.11 - v. 1.1 - detect legacy /usr/local/bin/ffmpeg-VERSION-arch-static and release semver (e.g. 7.0.2)
# 2026.06.11 - v. 1.0 - install/update static FFmpeg (John Van Sickle builds) under /opt/ffmpeg-YYYYMMDD
#
# ffmpeg-install.sh
#
# Official releases: https://ffmpeg.org/download.html
# Static builds:     https://johnvansickle.com/ffmpeg/
# Git (master) static builds are recommended for bug fixes; release static builds also exist.
# Dynamic fallback: distro ffmpeg package via apt when static is unavailable.
# Source fallback: compile official ffmpeg.org release tarball (--enable-static).
#

set -euo pipefail

FFMPEG_BASE_URL="https://johnvansickle.com/ffmpeg"
INSTALL_OPT="/opt"
BIN_FFMPEG="/usr/local/bin/ffmpeg"
BIN_FFPROBE="/usr/local/bin/ffprobe"
CURRENT_LINK="${INSTALL_OPT}/ffmpeg"
TEMP_CATALOG="${TEMP_CATALOG:-/mnt/ffmpeg-temp}"
FFMPEG_BUILD_KIND="${FFMPEG_BUILD_KIND:-git}"
INSTALL_PLAN=""
DYNAMIC_ONLY=0
STATIC_ONLY=0
SOURCE_ONLY=0
ASSUME_YES=0
VERBOSE=1
NETWORK_TIMEOUT_SEC="${NETWORK_TIMEOUT_SEC:-120}"
FFMPEG_PROBE_TIMEOUT_SEC="${FFMPEG_PROBE_TIMEOUT_SEC:-15}"
FFMPEG_ORG_VERSION=""
FFMPEG_ORG_RELEASE_DATE=""
REMOTE_BUILD_DATE=""
REMOTE_BUILD_LABEL=""
STATIC_TARBALL_AVAILABLE=0
APT_FFMPEG_CANDIDATE=""
APT_FFMPEG_VERSION=""
INSTALLED_FFMPEG_SEMVER=""
INSTALLED_BUILD_ID=""
INSTALLED_BUILD_KIND=""
INSTALLED_BUILD_SOURCE=""

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
Usage: $(basename "$0") [-h|--help] [-v|--version] [-y|--yes] [-q|--quiet] [--release]
       [--dynamic-only] [--static-only] [--source-only] [--no_startup_delay]

Check installed ffmpeg against ffmpeg.org, then optionally install:
  1) prebuilt static (johnvansickle.com)
  2) dynamic package (apt)
  3) static build compiled from the official ffmpeg.org release source
Older installs are moved aside, not deleted.

Install layout:
  /opt/ffmpeg-VERSION/      prebuilt static or apt-tracked install
  /opt/ffmpeg-VERSION-src/  official-release source static build
  /opt/ffmpeg               symlink to active install
  /usr/local/bin/ffmpeg     symlink into active install
  /opt/ffmpeg-*-backup-*    previous installs preserved automatically

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  -y, --yes            Install without prompting: static if available, else apt
                       (does not auto-build from source; that is slow).
  -q, --quiet          Less progress output (errors still shown).
  --release            Use release static builds instead of git (master) builds.
  --dynamic-only       Install distro ffmpeg via apt only.
  --static-only        Do not fall back to apt or source build.
  --source-only        Skip prebuilt static/apt; offer official source build only.
  --no_startup_delay   Skip random startup delay when run non-interactively.

Environment:
  TEMP_CATALOG              Download/extract workspace (default: /mnt/ffmpeg-temp).
  FFMPEG_BUILD_KIND         git (default) or release — same as --release.
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

http_status_code() {
    local url="$1"
    if command -v curl >/dev/null 2>&1; then
        curl -fsI -o /dev/null -w '%{http_code}' --connect-timeout "${NETWORK_TIMEOUT_SEC}" \
            --max-time "${NETWORK_TIMEOUT_SEC}" "$url" 2>/dev/null || echo "000"
        return 0
    fi
    if wget --spider --server-response --timeout="${NETWORK_TIMEOUT_SEC}" "$url" 2>&1 | grep -q ' 200 OK'; then
        echo "200"
    else
        echo "000"
    fi
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

build_id_is_date() {
    [[ "${1}" =~ ^[0-9]{8}$ ]]
}

build_id_is_semver() {
    [[ "${1}" =~ ^[0-9]+(\.[0-9]+)+$ ]]
}

build_ids_comparable() {
    local a="$1" b="$2"
    build_id_is_date "${a}" && build_id_is_date "${b}" && return 0
    build_id_is_semver "${a}" && build_id_is_semver "${b}" && return 0
    return 1
}

format_build_with_date() {
    local build_id="$1" date_label="$2" kind="${3:-date}"
    if [[ -z "${build_id}" ]]; then
        echo "not installed"
        return 0
    fi
    if [[ "${kind}" == "semver" ]]; then
        echo "release ${build_id} (${FFMPEG_ARCH} static)"
        return 0
    fi
    if [[ -n "${date_label}" && "${date_label}" != "unknown" ]]; then
        echo "build ${build_id} (dated ${date_label})"
    else
        echo "build ${build_id}"
    fi
}

format_installed_build_label() {
    local build_id="$1" date_label="$2"
    if [[ -z "${build_id}" && -z "${INSTALLED_FFMPEG_SEMVER}" ]]; then
        echo "not installed"
        return 0
    fi
    if [[ "${INSTALLED_BUILD_SOURCE}" == "apt" ]]; then
        echo "apt ${INSTALLED_FFMPEG_SEMVER:-${build_id}} (${APT_FFMPEG_CANDIDATE:-dynamic})"
        return 0
    fi
    if [[ "${INSTALLED_BUILD_SOURCE}" == "src" ]]; then
        echo "official source static ${INSTALLED_FFMPEG_SEMVER:-${build_id}}"
        return 0
    fi
    if [[ "${INSTALLED_BUILD_KIND}" == "semver" ]]; then
        local label
        label="$(format_build_with_date "${INSTALLED_FFMPEG_SEMVER:-${build_id}}" "" semver)"
        if [[ "${INSTALLED_BUILD_SOURCE}" == "localbin" ]]; then
            echo "${label}, ${BIN_FFMPEG}"
        else
            echo "${label}"
        fi
        return 0
    fi
    if [[ -n "${INSTALLED_FFMPEG_SEMVER}" ]]; then
        echo "build ${build_id} (ffmpeg ${INSTALLED_FFMPEG_SEMVER})"
        return 0
    fi
    format_build_with_date "${build_id}" "${date_label}" date
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

ffmpeg_org_release_tarball_name() {
    local version="${1:-${FFMPEG_ORG_VERSION}}"
    echo "ffmpeg-${version}.tar.xz"
}

ffmpeg_org_release_tarball_url() {
    echo "https://ffmpeg.org/releases/$(ffmpeg_org_release_tarball_name "$1")"
}

official_source_build_is_available() {
    [[ -n "${FFMPEG_ORG_VERSION}" ]]
}

ensure_ffmpeg_org_release_version() {
    if official_source_build_is_available; then
        return 0
    fi
    fetch_ffmpeg_org_latest_release || true
    official_source_build_is_available
}

fetch_ffmpeg_org_latest_release() {
    local html heading ver date_line

    FFMPEG_ORG_VERSION=""
    FFMPEG_ORG_RELEASE_DATE=""

    log_step "Querying ffmpeg.org for latest official release..."
    if ! html="$(fetch_url "https://ffmpeg.org/download.html" 2>/dev/null)"; then
        log_note "Could not fetch ffmpeg.org download page."
        return 1
    fi

    heading="$(printf '%s\n' "${html}" | grep -m1 '^### FFmpeg [0-9]' || true)"
    if [[ "${heading}" =~ ^###[[:space:]]FFmpeg[[:space:]]+([0-9]+(\.[0-9]+)+) ]]; then
        FFMPEG_ORG_VERSION="${BASH_REMATCH[1]}"
    fi
    if [[ -z "${FFMPEG_ORG_VERSION}" ]]; then
        FFMPEG_ORG_VERSION="$(printf '%s\n' "${html}" | grep -m1 -oiE 'ffmpeg-[0-9]+\.[0-9]+\.[0-9]+\.tar' \
            | sed -E 's/.*ffmpeg-([0-9]+\.[0-9]+\.[0-9]+)\.tar.*/\1/I')"
    fi
    if [[ -z "${FFMPEG_ORG_VERSION}" ]]; then
        FFMPEG_ORG_VERSION="$(printf '%s\n' "${html}" | grep -m1 -oE 'FFmpeg [0-9]+\.[0-9]+\.[0-9]+' | awk '{print $2}')"
    fi

    date_line="$(printf '%s\n' "${html}" | grep -m1 "${FFMPEG_ORG_VERSION} was released on" || true)"
    if [[ "${date_line}" =~ was[[:space:]]+released[[:space:]]+on[[:space:]]+([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
        FFMPEG_ORG_RELEASE_DATE="${BASH_REMATCH[1]//-/.}"
    fi

    if [[ -n "${FFMPEG_ORG_VERSION}" ]]; then
        log_note "ffmpeg.org latest stable release: ${FFMPEG_ORG_VERSION} (${FFMPEG_ORG_RELEASE_DATE:-date unknown})"
        return 0
    fi
    return 1
}

parse_apt_package_version() {
    local raw="$1"
    if [[ "${raw}" =~ ^[0-9]+:([0-9]+(\.[0-9]+)+) ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    fi
    if [[ "${raw}" =~ ^([0-9]+(\.[0-9]+)+) ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    fi
    return 1
}

get_apt_ffmpeg_candidate() {
    local policy=""

    APT_FFMPEG_CANDIDATE=""
    APT_FFMPEG_VERSION=""

    if ! command -v apt-cache >/dev/null 2>&1; then
        return 1
    fi

    policy="$(apt-cache policy ffmpeg 2>/dev/null | awk '/Candidate:/ {print $2; exit}' || true)"
    [[ -n "${policy}" && "${policy}" != "(none)" ]] || return 1

    APT_FFMPEG_CANDIDATE="${policy}"
    APT_FFMPEG_VERSION="$(parse_apt_package_version "${policy}" || true)"
    if [[ -n "${APT_FFMPEG_VERSION}" ]]; then
        log_note "Apt candidate ffmpeg package: ${policy} (upstream ${APT_FFMPEG_VERSION})"
    else
        log_note "Apt candidate ffmpeg package: ${policy}"
    fi
    return 0
}

static_tarball_is_available() {
    local url="$1" code=""

    code="$(http_status_code "${url}")"
    [[ "${code}" == "200" ]]
}

fetch_remote_build_metadata() {
    local url last_modified build_id=""

    REMOTE_BUILD_DATE=""
    REMOTE_BUILD_LABEL=""

    url="$(ffmpeg_tarball_url)"
    log_step "Checking remote static build (${FFMPEG_BUILD_KIND}, ${FFMPEG_ARCH})..."
    log_note "${url}"

    if static_tarball_is_available "${url}"; then
        STATIC_TARBALL_AVAILABLE=1
        log_note "Static tarball is available (HTTP 200)."
    else
        STATIC_TARBALL_AVAILABLE=0
        log_note "Static tarball is not available for ${FFMPEG_ARCH} (${FFMPEG_BUILD_KIND})."
    fi

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

set_installed_build_id() {
    INSTALLED_BUILD_ID="${1:-}"
}

version_from_install_path() {
    local path="$1"
    [[ -n "${path}" ]] || return 1
    if [[ "${path}" =~ /ffmpeg-([0-9]{8})(/|$) ]]; then
        INSTALLED_BUILD_KIND="date"
        INSTALLED_BUILD_SOURCE="opt"
        set_installed_build_id "${BASH_REMATCH[1]}"
        return 0
    fi
    if [[ "${path}" =~ /ffmpeg-([0-9]+(\.[0-9]+)+)-src(/|$) ]]; then
        INSTALLED_BUILD_KIND="semver"
        INSTALLED_BUILD_SOURCE="src"
        set_installed_build_id "${BASH_REMATCH[1]}-src"
        return 0
    fi
    if [[ "${path}" =~ /ffmpeg-([0-9]+(\.[0-9]+)+)-apt(/|$) ]]; then
        INSTALLED_BUILD_KIND="semver"
        INSTALLED_BUILD_SOURCE="apt"
        set_installed_build_id "${BASH_REMATCH[1]}-apt"
        return 0
    fi
    if [[ "${path}" =~ /ffmpeg-([0-9]+(\.[0-9]+)+)(/|$) ]]; then
        INSTALLED_BUILD_KIND="semver"
        INSTALLED_BUILD_SOURCE="opt"
        set_installed_build_id "${BASH_REMATCH[1]}"
        return 0
    fi
    if [[ "${path}" =~ /ffmpeg-legacy- ]]; then
        INSTALLED_BUILD_KIND="semver"
        INSTALLED_BUILD_SOURCE="legacy"
        return 1
    fi
    return 1
}

move_path_aside() {
    local path="$1"
    local aside=""

    [[ -n "${path}" && -e "${path}" ]] || return 0
    aside="${path}-backup-$(date +%Y%m%d%H%M%S)"
    while [[ -e "${aside}" ]]; do
        aside="${path}-backup-$(date +%Y%m%d%H%M%S)-$$"
    done
    log_step "Moving aside: ${path} -> ${aside}"
    mv -v "${path}" "${aside}"
}

parse_ffmpeg_semver_from_version_output() {
    local text="$1"
    if [[ "${text}" =~ ffmpeg[[:space:]]+version[[:space:]]+([0-9]+(\.[0-9]+)+) ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    fi
    return 1
}

probe_ffmpeg_semver() {
    local exe="$1"
    local out="" rc=0

    [[ -n "${exe}" && -x "${exe}" ]] || return 1
    if command -v timeout >/dev/null 2>&1; then
        out="$(timeout "${FFMPEG_PROBE_TIMEOUT_SEC}" "${exe}" -version 2>&1)" || rc=$?
    else
        out="$("${exe}" -version 2>&1)" || rc=$?
    fi
    (( rc == 0 )) || return 1
    parse_ffmpeg_semver_from_version_output "${out}"
}

parse_build_id_from_binary_name() {
    local path="$1"
    local name=""

    [[ -n "${path}" ]] || return 1
    name="$(basename "${path}")"

    if [[ "${name}" =~ ^ffmpeg-git-([0-9]{8})- ]]; then
        INSTALLED_BUILD_KIND="date"
        INSTALLED_BUILD_SOURCE="opt"
        set_installed_build_id "${BASH_REMATCH[1]}"
        return 0
    fi
    if [[ "${name}" =~ ^ffmpeg-release-([0-9]{8})- ]]; then
        INSTALLED_BUILD_KIND="date"
        INSTALLED_BUILD_SOURCE="opt"
        set_installed_build_id "${BASH_REMATCH[1]}"
        return 0
    fi
    if [[ "${name}" =~ ^ffmpeg-([0-9]+(\.[0-9]+)+)- ]]; then
        INSTALLED_BUILD_KIND="semver"
        INSTALLED_BUILD_SOURCE="localbin"
        set_installed_build_id "${BASH_REMATCH[1]}"
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
        INSTALLED_BUILD_KIND="date"
        echo "${BASH_REMATCH[1]}"
        return 0
    fi
    if [[ "${text}" =~ ffmpeg-release-([0-9]{8}) ]]; then
        INSTALLED_BUILD_KIND="date"
        echo "${BASH_REMATCH[1]}"
        return 0
    fi
    if [[ "${text}" =~ ffmpeg[[:space:]]+version[[:space:]]+([0-9]+(\.[0-9]+)+)-static ]]; then
        INSTALLED_BUILD_KIND="semver"
        INSTALLED_BUILD_SOURCE="${INSTALLED_BUILD_SOURCE:-opt}"
        echo "${BASH_REMATCH[1]}"
        return 0
    fi
    if semver="$(parse_ffmpeg_semver_from_version_output "${text}")"; then
        INSTALLED_BUILD_KIND="semver"
        INSTALLED_BUILD_SOURCE="${INSTALLED_BUILD_SOURCE:-apt}"
        echo "${semver}"
        return 0
    fi
    return 1
}

get_installed_build_id_from_filesystem() {
    local exe="" build_id="" target="" link_name="" link_dir=""

    exe="$(resolve_active_ffmpeg_exe || true)"
    if [[ -n "${exe}" ]]; then
        if version_from_install_path "${exe}" || parse_build_id_from_binary_name "${exe}"; then
            log_note "Installed build from active path ${exe}: ${INSTALLED_BUILD_ID} (${INSTALLED_BUILD_KIND})"
            return 0
        fi
    fi

    if [[ -L "${BIN_FFMPEG}" ]]; then
        link_name="$(readlink "${BIN_FFMPEG}" 2>/dev/null || true)"
        if parse_build_id_from_binary_name "${link_name}"; then
            link_dir="$(dirname "${BIN_FFMPEG}")"
            log_note "Installed build from ${BIN_FFMPEG} -> ${link_dir}/${link_name}: ${INSTALLED_BUILD_ID} (${INSTALLED_BUILD_KIND})"
            return 0
        fi
    fi

    if [[ -L "${CURRENT_LINK}" ]]; then
        target="$(readlink -f "${CURRENT_LINK}" 2>/dev/null || true)"
        if version_from_install_path "${target}"; then
            log_note "Installed build from ${CURRENT_LINK} -> ${target}: ${INSTALLED_BUILD_ID} (${INSTALLED_BUILD_KIND})"
            return 0
        fi
    fi

    return 1
}

get_installed_build_id() {
    local exe="" out="" rc=0 build_id=""

    INSTALLED_BUILD_ID=""
    INSTALLED_BUILD_KIND=""
    INSTALLED_BUILD_SOURCE=""
    INSTALLED_FFMPEG_SEMVER=""

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
        INSTALLED_FFMPEG_SEMVER="$(parse_ffmpeg_semver_from_version_output "${out}" || true)"
        build_id="$(parse_build_id_from_ffmpeg_version "${out}" || true)"
        if [[ -n "${build_id}" ]]; then
            if [[ "${out}" =~ ffmpeg[[:space:]]+version[[:space:]]+([0-9]+(\.[0-9]+)+)-static ]]; then
                INSTALLED_BUILD_KIND="semver"
                INSTALLED_BUILD_SOURCE="opt"
            fi
            if [[ "${exe}" =~ ^/usr/local/bin/ffmpeg-.+-static$ ]]; then
                INSTALLED_BUILD_SOURCE="localbin"
            fi
            log_note "Active ffmpeg reported: $(printf '%s' "${out}" | head -n1 | tr '\n' ' ')"
            set_installed_build_id "${build_id}"
            return 0
        fi
        log_note "Active ffmpeg: $(printf '%s' "${out}" | head -n1 | tr '\n' ' ')"
    elif (( rc != 124 )); then
        log_note "WARNING: ffmpeg version probe failed (exit ${rc})"
    fi

    if get_installed_build_id_from_filesystem; then
        log_note "Using active install path build id: ${INSTALLED_BUILD_ID}"
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

iter_preserved_ffmpeg_install_paths() {
    local entry=""
    for entry in \
        "${INSTALL_OPT}"/ffmpeg-[0-9]* \
        "${INSTALL_OPT}"/ffmpeg-legacy-* \
        "${INSTALL_OPT}"/ffmpeg-*-backup-*; do
        [[ -e "${entry}" ]] || continue
        printf '%s\n' "${entry}"
    done
}

list_preserved_ffmpeg_versions() {
    local entry="" found=0
    while IFS= read -r entry; do
        if (( found == 0 )); then
            echo "  Installs under ${INSTALL_OPT}/:"
            found=1
        fi
        if is_active_ffmpeg_install "${entry}"; then
            echo "    $(basename "${entry}")  (active)"
        else
            echo "    $(basename "${entry}")"
        fi
    done < <(iter_preserved_ffmpeg_install_paths | sort -V | awk '!seen[$0]++')
}

collect_old_ffmpeg_install_paths() {
    local entry=""
    while IFS= read -r entry; do
        is_active_ffmpeg_install "${entry}" && continue
        printf '%s\n' "${entry}"
    done < <(iter_preserved_ffmpeg_install_paths | sort -V | awk '!seen[$0]++')
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
    build_id_is_date "${1}" || build_id_is_semver "${1}"
}

apt_dynamic_is_available() {
    [[ -n "${APT_FFMPEG_CANDIDATE}" && "${APT_FFMPEG_CANDIDATE}" != "(none)" ]]
}

prompt_build_from_source_fallback() {
    local reply=""

    if (( STATIC_ONLY == 1 )); then
        echo "Quitting — no changes made."
        quit_prompt_with_optional_old_cleanup
    fi
    if ! ensure_ffmpeg_org_release_version; then
        echo "ERROR: Could not determine an official ffmpeg.org release version to build." >&2
        quit_prompt_with_optional_old_cleanup
    fi
    echo "  (slow — compiles the ffmpeg.org release tarball; not nightly/git.)"
    echo
    echo ">>> Waiting for your answer:"
    echo -n "Build static ffmpeg ${FFMPEG_ORG_VERSION} from official release source? [y/N] "
    read -r -n 1 reply || reply=""
    echo
    case "${reply}" in
        y|Y|yes|YES) INSTALL_PLAN="source"; echo "Proceeding with official source build..." ;;
        *) echo "Quitting — no changes made."; quit_prompt_with_optional_old_cleanup ;;
    esac
}

prompt_install_dynamic_fallback() {
    local reply=""

    if (( STATIC_ONLY == 1 )); then
        prompt_build_from_source_fallback
        return 0
    fi
    if ! apt_dynamic_is_available; then
        prompt_build_from_source_fallback
        return 0
    fi
    if (( ASSUME_YES == 1 )); then
        INSTALL_PLAN="dynamic"
        echo "Proceeding with dynamic apt install (--yes)."
        return 0
    fi
    echo
    echo ">>> Waiting for your answer:"
    echo -n "Install dynamic ffmpeg via apt (${APT_FFMPEG_CANDIDATE})? [y/N] "
    read -r -n 1 reply || reply=""
    echo
    case "${reply}" in
        y|Y|yes|YES) INSTALL_PLAN="dynamic"; echo "Proceeding with apt install..." ;;
        *) prompt_build_from_source_fallback ;;
    esac
}

prompt_install_plan() {
    local installed="$1" installed_date="$2" reply=""

    INSTALL_PLAN=""

    echo
    echo "ffmpeg version check (${FFMPEG_ARCH}):"
    if [[ -n "${FFMPEG_ORG_VERSION}" ]]; then
        echo "  ffmpeg.org latest: ${FFMPEG_ORG_VERSION} (released ${FFMPEG_ORG_RELEASE_DATE:-unknown})"
    else
        echo "  ffmpeg.org latest: unknown"
    fi
    echo "  Installed:         $(format_installed_build_label "${installed}" "${installed_date}")"
    if (( STATIC_TARBALL_AVAILABLE == 1 )); then
        echo "  Static (${FFMPEG_BUILD_KIND}): available — $(ffmpeg_tarball_basename)"
        if build_id_is_date "${REMOTE_BUILD_LABEL}"; then
            echo "                     tarball dated ${REMOTE_BUILD_DATE}"
        fi
    else
        echo "  Static (${FFMPEG_BUILD_KIND}): not available for ${FFMPEG_ARCH}"
    fi
    if apt_dynamic_is_available; then
        echo "  Apt dynamic:       ${APT_FFMPEG_CANDIDATE} (upstream ${APT_FFMPEG_VERSION:-?})"
    else
        echo "  Apt dynamic:       not available"
    fi
    if official_source_build_is_available; then
        echo "  Source build:      ffmpeg.org release ${FFMPEG_ORG_VERSION} (official tarball, static compile)"
    else
        echo "  Source build:      ffmpeg.org release version unknown"
    fi
    echo

    if (( SOURCE_ONLY == 1 )); then
        prompt_build_from_source_fallback
        return 0
    fi

    if (( DYNAMIC_ONLY == 1 )); then
        prompt_install_dynamic_fallback
        return 0
    fi

    if (( STATIC_TARBALL_AVAILABLE == 1 )); then
        if (( ASSUME_YES == 1 )); then
            INSTALL_PLAN="static"
            echo "Proceeding with static install (--yes)."
            return 0
        fi
        echo ">>> Waiting for your answer:"
        echo -n "Install static ffmpeg build? [y/N] "
        read -r -n 1 reply || reply=""
        echo
        case "${reply}" in
            y|Y|yes|YES) INSTALL_PLAN="static"; echo "Proceeding with static install..."; return 0 ;;
            *) ;;
        esac
    else
        echo "Static build is not available for this architecture."
    fi

    prompt_install_dynamic_fallback
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
    if [[ "${name}" =~ ffmpeg-([0-9]+(\.[0-9]+)+)- ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    fi
    return 1
}

preserve_legacy_local_bin_install() {
    local bin_dir path legacy_dir base ffprobe_path

    bin_dir="$(dirname "${BIN_FFMPEG}")"
    for path in "${bin_dir}"/ffmpeg-*-static; do
        [[ -f "${path}" ]] || continue
        [[ -L "${path}" ]] && continue
        base="$(basename "${path}")"
        legacy_dir="${INSTALL_OPT}/ffmpeg-legacy-${base#ffmpeg-}"
        if [[ -e "${legacy_dir}" ]]; then
            move_path_aside "${legacy_dir}"
        fi
        mkdir -p "${legacy_dir}"
        log_step "Preserving legacy static install: ${path} -> ${legacy_dir}/"
        mv -v "${path}" "${legacy_dir}/ffmpeg"
        ffprobe_path="${path/ffmpeg-/ffprobe-}"
        if [[ -f "${ffprobe_path}" && ! -L "${ffprobe_path}" ]]; then
            mv -v "${ffprobe_path}" "${legacy_dir}/ffprobe"
        fi
    done
}

migrate_active_install_aside() {
    local active=""

    active="$(get_active_ffmpeg_install_target)"
    [[ -n "${active}" && -d "${active}" ]] || return 0
    move_path_aside "${active}"
}

resolve_ffmpeg_bins_in_install_dir() {
    local versioned="$1"
    local ffmpeg_bin="" ffprobe_bin=""

    if [[ -x "${versioned}/bin/ffmpeg" ]]; then
        ffmpeg_bin="${versioned}/bin/ffmpeg"
        ffprobe_bin="${versioned}/bin/ffprobe"
    elif [[ -x "${versioned}/ffmpeg" ]]; then
        ffmpeg_bin="${versioned}/ffmpeg"
        ffprobe_bin="${versioned}/ffprobe"
    else
        return 1
    fi
    printf '%s\n%s\n' "${ffmpeg_bin}" "${ffprobe_bin}"
}

link_ffmpeg_active_version() {
    local build_id="$1"
    local versioned="" bins="" ffmpeg_bin="" ffprobe_bin=""

    versioned="$(ffmpeg_versioned_path "${build_id}")"
    bins="$(resolve_ffmpeg_bins_in_install_dir "${versioned}" || true)"
    ffmpeg_bin="$(printf '%s\n' "${bins}" | sed -n '1p')"
    ffprobe_bin="$(printf '%s\n' "${bins}" | sed -n '2p')"
    if [[ -z "${ffmpeg_bin}" || ! -x "${ffmpeg_bin}" ]]; then
        echo "ERROR: ffmpeg binary not found under ${versioned}" >&2
        exit 1
    fi

    log_step "Pointing active symlinks to ${versioned}"
    ln -sfn "${versioned}" "${CURRENT_LINK}"
    ln -sfn "${ffmpeg_bin}" "${BIN_FFMPEG}"
    if [[ -n "${ffprobe_bin}" && -x "${ffprobe_bin}" ]]; then
        ln -sfn "${ffprobe_bin}" "${BIN_FFPROBE}"
    fi
    ls -l "${BIN_FFMPEG}" "${BIN_FFPROBE}" "${CURRENT_LINK}" 2>/dev/null || ls -l "${BIN_FFMPEG}" "${CURRENT_LINK}"
}

install_source_build_dependencies() {
    echo
    echo "part 1 — build dependencies for official source compile"
    echo
    need_cmd apt-get
    log_step "Running apt-get update..."
    apt-get update
    log_step "Installing compiler and common codec development libraries..."
    apt-get install -y \
        build-essential pkg-config yasm nasm \
        libunistring-dev zlib1g-dev \
        libx264-dev libx265-dev libvpx-dev \
        libmp3lame-dev libopus-dev libvorbis-dev \
        libtheora-dev libass-dev libdav1d-dev
    log_note "Build dependencies installed."
}

perform_install_build_from_source() {
    local version="${FFMPEG_ORG_VERSION}"
    local tarball url src_dir build_id="" versioned="" jobs="" rc=0

    if ! ensure_ffmpeg_org_release_version; then
        echo "ERROR: ffmpeg.org release version is unknown." >&2
        return 1
    fi

    echo
    echo "part 1 — official ffmpeg.org release source (${version})"
    echo

    need_cmd make
    need_cmd gcc
    preserve_legacy_local_bin_install
    migrate_active_install_aside
    install_source_build_dependencies

    tarball="$(ffmpeg_org_release_tarball_name "${version}")"
    url="$(ffmpeg_org_release_tarball_url "${version}")"
    build_id="${version}-src"

    mkdir -p "${TEMP_CATALOG}"
    TMP_WORK_DIR="$(mktemp -d "${TEMP_CATALOG}/ffmpeg-source-build.XXXXXX")"

    echo
    echo "part 2 — download and extract official release tarball"
    echo
    download_file "${url}" "${TMP_WORK_DIR}/${tarball}"
    tar -xJf "${TMP_WORK_DIR}/${tarball}" -C "${TMP_WORK_DIR}"
    src_dir="${TMP_WORK_DIR}/ffmpeg-${version}"
    if [[ ! -d "${src_dir}" ]]; then
        echo "ERROR: source directory not found: ${src_dir}" >&2
        return 1
    fi

    versioned="$(ffmpeg_versioned_path "${build_id}")"
    if [[ -e "${versioned}" ]]; then
        move_path_aside "${versioned}"
    fi

    echo
    echo "part 3 — configure and compile static build (this can take a long time)"
    echo

    cd "${src_dir}"
    log_step "Running ffmpeg configure (static, official release ${version})..."
    ./configure \
        --prefix="${versioned}" \
        --enable-static \
        --disable-shared \
        --disable-debug \
        --enable-gpl \
        --enable-version3 \
        --pkg-config-flags="--static" \
        --extra-libs="-lpthread -lm"

    jobs="$(nproc 2>/dev/null || echo 2)"
    log_step "Building with make -j${jobs}..."
    make -j"${jobs}"
    log_step "Installing into ${versioned}..."
    make install

    printf 'official ffmpeg.org release %s (static source build)\n' "${version}" > "${versioned}/.install-source"
    chmod 755 -R "${versioned}"
    chown root:root -R "${versioned}"

    link_ffmpeg_active_version "${build_id}"
    verify_active_ffmpeg
    print_install_success_summary "${build_id}" "official source static ${version}"
    return 0
}

verify_active_ffmpeg() {
    echo
    echo "part — verify"
    echo
    if command -v timeout >/dev/null 2>&1; then
        timeout "${FFMPEG_PROBE_TIMEOUT_SEC}" ffmpeg -version | head -n3
        timeout "${FFMPEG_PROBE_TIMEOUT_SEC}" ffprobe -version | head -n1
    else
        ffmpeg -version | head -n3
        ffprobe -version | head -n1
    fi
}

print_install_success_summary() {
    local build_id="$1" kind="$2"
    echo
    echo "ffmpeg installed/updated successfully."
    echo "  Method:  ${kind}"
    echo "  Build:   ${build_id}"
    if [[ -n "${FFMPEG_ORG_VERSION}" ]]; then
        echo "  ffmpeg.org latest: ${FFMPEG_ORG_VERSION}"
    fi
    echo "  Active:  ${CURRENT_LINK} -> $(readlink -f "${CURRENT_LINK}" 2>/dev/null || echo '?')"
    echo "  Binary:  ${BIN_FFMPEG}"
    list_preserved_ffmpeg_versions
    prompt_remove_old_ffmpeg_installs
}

perform_install_static() {
    local had_legacy_localbin="${1:-0}"
    local tarball url extracted_dir build_id="" versioned="" static_semver=""

    echo
    echo "part 1 — download static ffmpeg (${FFMPEG_BUILD_KIND}, ${FFMPEG_ARCH})"
    echo

    need_cmd tar
    need_cmd find
    need_cmd ln
    need_cmd mkdir
    need_cmd chmod
    need_cmd chown

    if (( STATIC_TARBALL_AVAILABLE == 0 )); then
        echo "ERROR: Static tarball is not available." >&2
        return 1
    fi

    preserve_legacy_local_bin_install
    migrate_active_install_aside

    mkdir -p "${TEMP_CATALOG}"
    TMP_WORK_DIR="$(mktemp -d "${TEMP_CATALOG}/ffmpeg-install.XXXXXX")"
    tarball="${TMP_WORK_DIR}/$(ffmpeg_tarball_basename)"
    url="$(ffmpeg_tarball_url)"

    if ! download_file "${url}" "${tarball}"; then
        return 1
    fi
    verify_tarball_md5 "${tarball}"

    echo
    echo "part 2 — extract and install under ${INSTALL_OPT}"
    echo

    tar -xJf "${tarball}" -C "${TMP_WORK_DIR}"
    extracted_dir="$(find "${TMP_WORK_DIR}" -maxdepth 1 -mindepth 1 -type d -name 'ffmpeg-*-static' | head -n1)"
    if [[ -z "${extracted_dir}" || ! -d "${extracted_dir}" ]]; then
        echo "ERROR: extracted ffmpeg directory not found." >&2
        return 1
    fi

    static_semver="$(probe_ffmpeg_semver "${extracted_dir}/ffmpeg" || true)"
    build_id="$(build_id_from_extracted_dir "${extracted_dir}" || true)"
    if [[ -z "${build_id}" ]]; then
        if [[ -n "${static_semver}" ]]; then
            build_id="${static_semver}"
        else
            build_id="$(date +%Y%m%d)"
            log_note "Could not parse build id from directory name; using ${build_id}."
        fi
    fi
    log_note "Extracted: $(basename "${extracted_dir}")"
    log_note "Build id: ${build_id}"
    if [[ -n "${static_semver}" ]]; then
        log_note "Static binary reports ffmpeg ${static_semver}"
        if [[ -n "${FFMPEG_ORG_VERSION}" ]] && version_is_newer_than "${FFMPEG_ORG_VERSION}" "${static_semver}"; then
            log_note "Note: static build (${static_semver}) is older than ffmpeg.org latest (${FFMPEG_ORG_VERSION})."
            if apt_dynamic_is_available; then
                log_note "Apt may provide a newer dynamic build (${APT_FFMPEG_VERSION:-${APT_FFMPEG_CANDIDATE}})."
            fi
        fi
    fi

    versioned="$(ffmpeg_versioned_path "${build_id}")"
    if [[ -e "${versioned}" ]]; then
        move_path_aside "${versioned}"
    fi

    mv -v "${extracted_dir}" "${versioned}"
    chmod 755 -R "${versioned}"
    chown root:root -R "${versioned}"

    link_ffmpeg_active_version "${build_id}"
    verify_active_ffmpeg
    print_install_success_summary "${build_id}" "static ${FFMPEG_BUILD_KIND}"
    return 0
}

perform_install_dynamic() {
    local apt_ffmpeg="" apt_ffprobe="" versioned="" build_id="" ver=""

    echo
    echo "part 1 — dynamic ffmpeg via apt"
    echo

    if ! apt_dynamic_is_available; then
        echo "ERROR: No apt ffmpeg candidate available." >&2
        return 1
    fi

    need_cmd apt-get
    preserve_legacy_local_bin_install
    migrate_active_install_aside

    log_step "Running apt-get update..."
    apt-get update
    log_step "Installing ffmpeg package (${APT_FFMPEG_CANDIDATE})..."
    apt-get install -y ffmpeg

    apt_ffmpeg="$(command -v ffmpeg || true)"
    apt_ffprobe="$(command -v ffprobe || true)"
    if [[ -z "${apt_ffmpeg}" || ! -x "${apt_ffmpeg}" ]]; then
        echo "ERROR: ffmpeg not found after apt install." >&2
        return 1
    fi

    ver="$(probe_ffmpeg_semver "${apt_ffmpeg}" || true)"
    [[ -n "${ver}" ]] || ver="${APT_FFMPEG_VERSION:-unknown}"
    build_id="${ver}-apt"
    versioned="$(ffmpeg_versioned_path "${build_id}")"
    if [[ -e "${versioned}" ]]; then
        move_path_aside "${versioned}"
    fi

    mkdir -p "${versioned}"
    ln -sfn "${apt_ffmpeg}" "${versioned}/ffmpeg"
    if [[ -n "${apt_ffprobe}" && -x "${apt_ffprobe}" ]]; then
        ln -sfn "${apt_ffprobe}" "${versioned}/ffprobe"
    fi
    printf '%s\n' "apt ${APT_FFMPEG_CANDIDATE}" > "${versioned}/.install-source"
    chmod 755 "${versioned}"
    chown root:root -R "${versioned}"

    link_ffmpeg_active_version "${build_id}"
    verify_active_ffmpeg
    print_install_success_summary "${build_id}" "dynamic apt"
    return 0
}

run_install_plan() {
    local had_legacy_localbin="${1:-0}"

    case "${INSTALL_PLAN}" in
        static)
            if perform_install_static "${had_legacy_localbin}"; then
                return 0
            fi
            echo "Static install failed."
            if (( STATIC_ONLY == 1 )); then
                exit 1
            fi
            INSTALL_PLAN=""
            prompt_install_dynamic_fallback
            case "${INSTALL_PLAN}" in
                dynamic)
                    if perform_install_dynamic; then
                        return 0
                    fi
                    echo "Dynamic apt install failed."
                    INSTALL_PLAN=""
                    prompt_build_from_source_fallback
                    perform_install_build_from_source
                    ;;
                source) perform_install_build_from_source ;;
                *) quit_prompt_with_optional_old_cleanup ;;
            esac
            ;;
        dynamic)
            if perform_install_dynamic; then
                return 0
            fi
            echo "Dynamic apt install failed."
            INSTALL_PLAN=""
            prompt_build_from_source_fallback
            perform_install_build_from_source
            ;;
        source)
            perform_install_build_from_source
            ;;
        *)
            echo "Quitting — no install method selected."
            quit_prompt_with_optional_old_cleanup
            ;;
    esac
}

main() {
    local installed="" installed_date=""

    log_step "Starting ffmpeg install/update check..."
    as_root_check
    detect_machine "$(uname -m)"

    log_step "Step 1/4 — ffmpeg.org latest release"
    fetch_ffmpeg_org_latest_release || true

    log_step "Step 2/4 — static build availability"
    fetch_remote_build_metadata

    log_step "Step 3/4 — apt dynamic candidate"
    get_apt_ffmpeg_candidate || true

    echo "Machine: ${MACHINE_HW} (static arch label: ${FFMPEG_ARCH})"
    echo "Build kind: ${FFMPEG_BUILD_KIND}"
    echo

    log_step "Step 4/4 — detect installed ffmpeg"
    get_installed_build_id
    installed="${INSTALLED_BUILD_ID}"
    if build_id_is_date "${installed}"; then
        installed_date="$(format_build_date_display "${installed}")"
    fi

    log_step "Version check complete."
    prompt_install_plan "${installed}" "${installed_date}"

    echo
    echo "Will install:"
    echo "  plan:    ${INSTALL_PLAN}"
    if [[ "${INSTALL_PLAN}" == "static" ]]; then
        echo "  package: $(ffmpeg_tarball_basename)"
        echo "  url:     $(ffmpeg_tarball_url)"
    elif [[ "${INSTALL_PLAN}" == "dynamic" ]]; then
        echo "  package: ffmpeg (${APT_FFMPEG_CANDIDATE})"
    elif [[ "${INSTALL_PLAN}" == "source" ]]; then
        echo "  package: $(ffmpeg_org_release_tarball_name)"
        echo "  url:     $(ffmpeg_org_release_tarball_url)"
    fi
    echo "  temp:    ${TEMP_CATALOG}"
    echo

    local had_legacy_localbin=0
    [[ "${INSTALLED_BUILD_SOURCE}" == "localbin" ]] && had_legacy_localbin=1
    run_install_plan "${had_legacy_localbin}"
}

HEADER_EXTRA_ARGS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help) show_help; exit 0 ;;
        -v|--version) print_version_banner; exit 0 ;;
        -y|--yes) ASSUME_YES=1; shift ;;
        -q|--quiet) VERBOSE=0; shift ;;
        --release) FFMPEG_BUILD_KIND="release"; shift ;;
        --dynamic-only) DYNAMIC_ONLY=1; shift ;;
        --static-only) STATIC_ONLY=1; shift ;;
        --source-only) SOURCE_ONLY=1; shift ;;
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
