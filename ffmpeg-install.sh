#!/usr/bin/env bash
# 2026.06.11 - v. 2.1 - source build profiles: min/common/max/gpu/nvidia; --source-profile; interactive menu
# 2026.06.11 - v. 2.0 - source build: enable common external encoders (libmp3lame, x264, openssl, aom, …)
# 2026.06.11 - v. 1.9 - running ffmpeg: offer graceful/force kill or skip with version summary; fix pgrep false positives
# 2026.06.09 - v. 1.8 - after successful install: ffmpeg -version and script version banner
# 2026.06.09 - v. 1.7 - check for running ffmpeg/ffprobe before script and before install
# 2026.06.09 - v. 1.6 - prompts accept q to quit; show [y/N/q]
# 2026.06.11 - v. 1.5 - install to /usr/local/bin/ffmpeg-VERSION; ffmpeg/ffprobe -> versioned names
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
# Source fallback: compile official ffmpeg.org release tarball (static, common lib* encoders).
#

set -euo pipefail

FFMPEG_BASE_URL="https://johnvansickle.com/ffmpeg"
BIN_DIR="/usr/local/bin"
BIN_FFMPEG="${BIN_DIR}/ffmpeg"
BIN_FFPROBE="${BIN_DIR}/ffprobe"
INSTALL_OPT="/opt"
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
FFMPEG_KILL_GRACE_WAIT_SEC="${FFMPEG_KILL_GRACE_WAIT_SEC:-30}"
FFMPEG_KILL_FORCE_WAIT_SEC="${FFMPEG_KILL_FORCE_WAIT_SEC:-10}"
FFMPEG_CONFIGURE_EXTRA="${FFMPEG_CONFIGURE_EXTRA:-}"
FFMPEG_SOURCE_PROFILE="${FFMPEG_SOURCE_PROFILE:-}"
CLI_SOURCE_PROFILE=""
CLI_SOURCE_WITH_FDK=0
SOURCE_PROFILE=""
FFMPEG_SOURCE_WITH_FDK_AAC=0
FFMPEG_SOURCE_HAS_SVTAV1=0
FFMPEG_SOURCE_HAS_FDK_AAC=0
FFMPEG_SOURCE_PROFILE_READY=0
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
FFMPEG_RUNNING_ACK=0
FFMPEG_VERSION_SUMMARY_SHOWN=0

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
       [--dynamic-only] [--static-only] [--source-only]
       [--source-profile min|common|max|gpu|nvidia] [--source-with-fdk-aac]
       [--no_startup_delay]

When ffmpeg/ffprobe is running, offers graceful kill (SIGTERM), then force kill
(SIGKILL) if needed, or [S]kip to compare running vs installable versions.
Re-checks before any install step. With --yes, tries graceful then force kill.

Check installed ffmpeg against ffmpeg.org, then optionally install:
  1) prebuilt static (johnvansickle.com)
  2) dynamic package (apt)
  3) static/shared build compiled from the official ffmpeg.org release source
     Profiles: min, common (default), max, gpu (VAAPI), nvidia (NVENC/CUDA)
Older installs are moved aside, not deleted.

Install layout (/usr/local/bin):
  ffmpeg-VERSION            versioned binary (or symlink for apt)
  ffprobe-VERSION           matching ffprobe
  ffmpeg                    symlink -> ffmpeg-VERSION (active)
  ffprobe                   symlink -> ffprobe-VERSION (active)
  ffmpeg-VERSION-backup-*   same-name binary moved aside before replace

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  -y, --yes            Install without prompting: static if available, else apt
                       (does not auto-build from source; that is slow).
  -q, --quiet          Less progress output (errors still shown).

Interactive prompts use [y/N/q]: y = yes, Enter/N = no (default), q = quit.
  --release            Use release static builds instead of git (master) builds.
  --dynamic-only       Install distro ffmpeg via apt only.
  --static-only        Do not fall back to apt or source build.
  --source-only        Skip prebuilt static/apt; offer official source build only.
  --source-profile P   Source build profile: min, common, max, gpu, or nvidia
                       (skips profile menu). Default when omitted: common.
  --source-with-fdk-aac
                       With max profile: enable libfdk-aac (non-free, best AAC).
  --no_startup_delay   Skip random startup delay when run non-interactively.

Environment:
  TEMP_CATALOG              Download/extract workspace (default: /mnt/ffmpeg-temp).
  FFMPEG_BUILD_KIND         git (default) or release — same as --release.
  NETWORK_TIMEOUT_SEC       curl/wget timeout in seconds (default: 120).
  FFMPEG_PROBE_TIMEOUT_SEC  timeout for probing installed ffmpeg (default: 15).
  FFMPEG_KILL_GRACE_WAIT_SEC  seconds to wait after SIGTERM (default: 30).
  FFMPEG_KILL_FORCE_WAIT_SEC  seconds to wait after SIGKILL (default: 10).
  FFMPEG_CONFIGURE_EXTRA      Extra ./configure flags for source builds (space-separated).
  FFMPEG_SOURCE_PROFILE       Same as --source-profile (min|common|max|gpu|nvidia).
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

version_label_from_build_id() {
    local id="$1"
    id="${id%-src}"
    id="${id%-apt}"
    echo "${id}"
}

versioned_ffmpeg_bin() {
    echo "${BIN_DIR}/ffmpeg-$(version_label_from_build_id "$1")"
}

versioned_ffprobe_bin() {
    echo "${BIN_DIR}/ffprobe-$(version_label_from_build_id "$1")"
}

get_active_version_label() {
    local link=""
    link="$(readlink "${BIN_FFMPEG}" 2>/dev/null || true)"
    [[ "${link}" =~ ^ffmpeg-(.+)$ ]] || return 1
    echo "${BASH_REMATCH[1]}"
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
    if [[ "${name}" =~ ^ffmpeg-([0-9]+(\.[0-9]+)+)(-[^/]+)?$ ]]; then
        INSTALLED_BUILD_KIND="semver"
        INSTALLED_BUILD_SOURCE="localbin"
        set_installed_build_id "${BASH_REMATCH[1]}"
        return 0
    fi
    if [[ "${name}" =~ ^ffmpeg-([0-9]{8})$ ]]; then
        INSTALLED_BUILD_KIND="date"
        INSTALLED_BUILD_SOURCE="localbin"
        set_installed_build_id "${BASH_REMATCH[1]}"
        return 0
    fi
    return 1
}

resolve_active_ffmpeg_exe() {
    local target=""

    for target in "${BIN_FFMPEG}"; do
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

    for target in "${BIN_FFPROBE}"; do
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
    local exe="" build_id="" target="" link_name="" label=""

    if label="$(get_active_version_label 2>/dev/null)"; then
        INSTALLED_BUILD_KIND="semver"
        INSTALLED_BUILD_SOURCE="localbin"
        set_installed_build_id "${label}"
        return 0
    fi

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
            log_note "Installed build from ${BIN_FFMPEG} -> ${link_name}: ${INSTALLED_BUILD_ID} (${INSTALLED_BUILD_KIND})"
            return 0
        fi
    fi

    if [[ -e "${BIN_FFMPEG}" && ! -L "${BIN_FFMPEG}" ]]; then
        if parse_build_id_from_binary_name "${BIN_FFMPEG}"; then
            log_note "Installed build from ${BIN_FFMPEG}: ${INSTALLED_BUILD_ID}"
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
        log_note "No active ffmpeg binary found (${BIN_FFMPEG})"
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

collect_old_version_labels() {
    local path="" name="" label="" active=""

    active="$(get_active_version_label || true)"
    for path in "${BIN_DIR}"/ffmpeg-*; do
        [[ -e "${path}" ]] || continue
        [[ "${path}" == "${BIN_FFMPEG}" ]] && continue
        name="$(basename "${path}")"
        [[ "${name}" =~ ^ffmpeg-(.+)$ ]] || continue
        label="${BASH_REMATCH[1]}"
        [[ "${label}" == *-backup-* ]] && continue
        [[ -n "${active}" && "${label}" == "${active}" ]] && continue
        printf '%s\n' "${label}"
    done | sort -V -u
}

list_preserved_ffmpeg_versions() {
    local label="" active="" path="" name="" raw_labels=() labels=()

    active="$(get_active_version_label || true)"
    for path in "${BIN_DIR}"/ffmpeg-*; do
        [[ -e "${path}" ]] || continue
        name="$(basename "${path}")"
        [[ "${name}" =~ ^ffmpeg-(.+)$ ]] || continue
        label="${BASH_REMATCH[1]}"
        [[ "${label}" == *-backup-* ]] && continue
        raw_labels+=("${label}")
    done
    ((${#raw_labels[@]} > 0)) || return 0

    while IFS= read -r label; do
        [[ -n "${label}" ]] && labels+=("${label}")
    done < <(printf '%s\n' "${raw_labels[@]}" | sort -V -u)

    echo "  Versioned binaries in ${BIN_DIR}/:"
    for label in "${labels[@]}"; do
        if [[ -n "${active}" && "${label}" == "${active}" ]]; then
            echo "    ffmpeg-${label}  ffprobe-${label}  (active)"
        else
            echo "    ffmpeg-${label}  ffprobe-${label}"
        fi
    done
}

prompt_reply_is_yes() {
    case "${1}" in
        y|Y|yes|YES) return 0 ;;
        *) return 1 ;;
    esac
}

prompt_reply_is_quit() {
    case "${1}" in
        q|Q|quit|QUIT) return 0 ;;
        *) return 1 ;;
    esac
}

ffmpeg_cmdline_is_ffmpeg_or_ffprobe() {
    local cmd="$1"
    [[ "$cmd" =~ ^ffmpeg([[:space:]]|$) || "$cmd" =~ ^ffprobe([[:space:]]|$) ]]
}

ffmpeg_running_procs() {
    local line="" pid="" cmd=""

    if command -v pgrep >/dev/null 2>&1; then
        while IFS= read -r line; do
            [[ -n "${line}" ]] || continue
            [[ "$line" == *ffmpeg-install.sh* ]] && continue
            pid="${line%% *}"
            cmd="${line#"${pid}" }"
            cmd="${cmd# }"
            ffmpeg_cmdline_is_ffmpeg_or_ffprobe "${cmd}" || continue
            printf '%s\n' "${line}"
        done < <(
            pgrep -af ffmpeg 2>/dev/null || true
            pgrep -af ffprobe 2>/dev/null || true
        )
    else
        while IFS= read -r line; do
            [[ -n "${line}" ]] || continue
            [[ "$line" == *ffmpeg-install.sh* ]] && continue
            pid="${line%% *}"
            cmd="${line#"${pid}" }"
            cmd="${cmd# }"
            ffmpeg_cmdline_is_ffmpeg_or_ffprobe "${cmd}" || continue
            printf '%s\n' "${line}"
        done < <(ps -eo pid=,args= 2>/dev/null || true)
    fi
}

ffmpeg_running_pids() {
    local line="" pid=""
    while IFS= read -r line; do
        [[ -n "${line}" ]] || continue
        pid="${line%% *}"
        [[ "${pid}" =~ ^[0-9]+$ ]] && printf '%s\n' "${pid}"
    done < <(ffmpeg_running_procs)
}

ffmpeg_is_running() {
    local procs=""
    procs="$(ffmpeg_running_procs)"
    [[ -n "${procs}" ]]
}

ffmpeg_running_proc_count() {
    local count=0 line=""
    while IFS= read -r line; do
        [[ -n "${line}" ]] && (( count++ )) || true
    done < <(ffmpeg_running_procs)
    echo "${count}"
}

print_ffmpeg_running_process_list() {
    local count=0 line=""

    count="$(ffmpeg_running_proc_count)"
    echo
    echo "ffmpeg/ffprobe is currently running (${count} process(es)):"
    while IFS= read -r line; do
        [[ -n "${line}" ]] && echo "  ${line}"
    done < <(ffmpeg_running_procs)
    echo
    echo "Installing while ffmpeg is running can fail (binary in use) or leave jobs on old binaries."
}

signal_running_ffmpeg_procs() {
    local sig="$1" pid=""
    while IFS= read -r pid; do
        [[ -n "${pid}" ]] || continue
        kill "-${sig}" "${pid}" 2>/dev/null || true
    done < <(ffmpeg_running_pids)
}

wait_for_ffmpeg_not_running() {
    local max_wait="${1:-${FFMPEG_KILL_GRACE_WAIT_SEC}}" i=0
    while (( i < max_wait )); do
        ffmpeg_is_running || return 0
        sleep 1
        ((++i))
    done
    return 1
}

kill_running_ffmpeg_gracefully() {
    local count=0

    ffmpeg_is_running || return 0
    count="$(ffmpeg_running_proc_count)"
    log_step "Sending SIGTERM to ${count} ffmpeg/ffprobe process(es)..."
    signal_running_ffmpeg_procs TERM
    if wait_for_ffmpeg_not_running "${FFMPEG_KILL_GRACE_WAIT_SEC}"; then
        log_note "All ffmpeg/ffprobe processes stopped."
        FFMPEG_RUNNING_ACK=0
        return 0
    fi
    return 1
}

kill_running_ffmpeg_forcefully() {
    local count=0

    ffmpeg_is_running || return 0
    count="$(ffmpeg_running_proc_count)"
    log_step "Sending SIGKILL to ${count} ffmpeg/ffprobe process(es)..."
    signal_running_ffmpeg_procs KILL
    if wait_for_ffmpeg_not_running "${FFMPEG_KILL_FORCE_WAIT_SEC}"; then
        log_note "All ffmpeg/ffprobe processes stopped."
        FFMPEG_RUNNING_ACK=0
        return 0
    fi
    return 1
}

print_running_ffmpeg_version_summary() {
    local pid="" exe="" ver=""
    declare -A seen_exes=()

    echo "  Running process binaries:"
    if ! ffmpeg_is_running; then
        echo "    (none)"
        return 0
    fi

    while IFS= read -r pid; do
        [[ -n "${pid}" ]] || continue
        exe="$(readlink -f "/proc/${pid}/exe" 2>/dev/null || true)"
        [[ -n "${exe}" ]] || continue
        [[ -n "${seen_exes[$exe]+x}" ]] && continue
        seen_exes[$exe]=1
        ver="$(probe_ffmpeg_semver "${exe}" || true)"
        if [[ -n "${ver}" ]]; then
            echo "    pid ${pid}: ${exe} — ffmpeg ${ver}"
        else
            echo "    pid ${pid}: ${exe} — version unknown"
        fi
    done < <(ffmpeg_running_pids)
}

print_ffmpeg_version_check_block() {
    local installed="$1" installed_date="$2"

    echo
    echo "ffmpeg version check (${FFMPEG_ARCH}):"
    print_running_ffmpeg_version_summary
    echo "  Active install:    $(format_installed_build_label "${installed}" "${installed_date}")"
    if [[ -n "${FFMPEG_ORG_VERSION}" ]]; then
        echo "  ffmpeg.org latest: ${FFMPEG_ORG_VERSION} (released ${FFMPEG_ORG_RELEASE_DATE:-unknown})"
    else
        echo "  ffmpeg.org latest: unknown"
    fi
    if (( STATIC_TARBALL_AVAILABLE == 1 )); then
        echo "  Static (${FFMPEG_BUILD_KIND}): available — $(ffmpeg_tarball_basename)"
        if build_id_is_date "${REMOTE_BUILD_LABEL}"; then
            echo "                     tarball dated ${REMOTE_BUILD_DATE}"
        elif [[ -n "${REMOTE_BUILD_LABEL}" && "${REMOTE_BUILD_LABEL}" != "latest" ]]; then
            echo "                     build label ${REMOTE_BUILD_LABEL}"
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
        echo "  Source build:      ffmpeg.org ${FFMPEG_ORG_VERSION} (profiles: min/common/max/gpu/nvidia)"
    else
        echo "  Source build:      ffmpeg.org release version unknown"
    fi
    echo
}

skip_running_ffmpeg_with_version_summary() {
    local installed="$1" installed_date="$2"

    FFMPEG_RUNNING_ACK=1
    FFMPEG_VERSION_SUMMARY_SHOWN=1
    log_note "Continuing without stopping running ffmpeg/ffprobe (at your risk)."
    print_ffmpeg_version_check_block "${installed}" "${installed_date}"
}

prompt_force_kill_or_skip_running_ffmpeg() {
    local installed="$1" installed_date="$2" reply=""

    while ffmpeg_is_running; do
        echo
        echo "Some ffmpeg/ffprobe process(es) are still running after SIGTERM."
        print_ffmpeg_running_process_list
        echo "  [F] Force kill (SIGKILL) and wait"
        echo "  [S] Skip — show versions, continue without stopping jobs"
        echo "  [Q] Quit"
        echo ">>> Waiting for your answer:"
        echo -n "Choice [F/s/q]: "
        read -r -n 1 reply || reply=""
        echo
        case "${reply}" in
            f|F)
                if kill_running_ffmpeg_forcefully; then
                    return 0
                fi
                echo "WARNING: Some ffmpeg/ffprobe processes could not be stopped." >&2
                ;;
            s|S)
                skip_running_ffmpeg_with_version_summary "${installed}" "${installed_date}"
                return 0
                ;;
            q|Q)
                echo "Quitting — stop ffmpeg and run this script again."
                exit 0
                ;;
            *)
                echo "Please choose F, s, or q."
                ;;
        esac
    done
    return 0
}

handle_running_ffmpeg_interactive() {
    local installed="$1" installed_date="$2" reply=""

    ffmpeg_is_running || return 0

    if (( ASSUME_YES == 1 )); then
        print_ffmpeg_running_process_list
        if kill_running_ffmpeg_gracefully; then
            return 0
        fi
        if kill_running_ffmpeg_forcefully; then
            return 0
        fi
        skip_running_ffmpeg_with_version_summary "${installed}" "${installed_date}"
        return 0
    fi

    while ffmpeg_is_running; do
        print_ffmpeg_running_process_list
        echo "  [K] Kill gracefully (SIGTERM) and wait for processes to exit"
        echo "  [S] Skip — show running vs installable versions, continue without stopping jobs"
        echo "  [Q] Quit"
        echo ">>> Waiting for your answer:"
        echo -n "Choice [K/s/q] (Enter=kill gracefully): "
        read -r -n 1 reply || reply=""
        echo
        case "${reply}" in
            s|S|n|N)
                skip_running_ffmpeg_with_version_summary "${installed}" "${installed_date}"
                return 0
                ;;
            k|K|y|Y|"")
                if kill_running_ffmpeg_gracefully; then
                    return 0
                fi
                prompt_force_kill_or_skip_running_ffmpeg "${installed}" "${installed_date}"
                return 0
                ;;
            q|Q)
                echo "Quitting — stop ffmpeg and run this script again."
                exit 0
                ;;
            *)
                echo "Unknown choice; try again."
                ;;
        esac
    done
    FFMPEG_RUNNING_ACK=0
    return 0
}

check_ffmpeg_running_before_install() {
    ffmpeg_is_running || return 0
    if (( FFMPEG_RUNNING_ACK == 1 )); then
        log_note "ffmpeg/ffprobe still running (you chose to skip stopping them)."
        return 0
    fi
    handle_running_ffmpeg_interactive "${INSTALLED_BUILD_ID}" ""
}

prompt_remove_old_ffmpeg_installs() {
    local old_labels=() label="" reply="" vffmpeg="" vffprobe=""

    while IFS= read -r label; do
        [[ -n "${label}" ]] && old_labels+=("${label}")
    done < <(collect_old_version_labels)

    ((${#old_labels[@]} > 0)) || return 0

    echo
    echo "Older ffmpeg version(s) in ${BIN_DIR} (not active):"
    for label in "${old_labels[@]}"; do
        echo "  ffmpeg-${label}  ffprobe-${label}"
    done
    echo

    if (( ASSUME_YES == 1 )); then
        log_note "Keeping old versioned binaries (--yes, no removal prompt)."
        return 0
    fi

    for label in "${old_labels[@]}"; do
        vffmpeg="${BIN_DIR}/ffmpeg-${label}"
        vffprobe="${BIN_DIR}/ffprobe-${label}"

        echo ">>> Waiting for your answer:"
        echo -n "Remove ffmpeg-${label} and ffprobe-${label}? [y/N/q] "
        read -r -n 1 reply || reply=""
        echo
        if prompt_reply_is_yes "${reply}"; then
            log_step "Removing ffmpeg-${label} and ffprobe-${label}"
            rm -f "${vffmpeg}" "${vffprobe}"
        elif prompt_reply_is_quit "${reply}"; then
            log_note "Quitting — keeping remaining old versions."
            return 0
        else
            log_note "Keeping ffmpeg-${label}."
        fi
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
    echo -n "Build static ffmpeg ${FFMPEG_ORG_VERSION} from official release source? [y/N/q] "
    read -r -n 1 reply || reply=""
    echo
    if prompt_reply_is_yes "${reply}"; then
        INSTALL_PLAN="source"
        ensure_source_build_profile_selected
        echo "Proceeding with official source build (profile: ${SOURCE_PROFILE})..."
    else
        echo "Quitting — no changes made."
        quit_prompt_with_optional_old_cleanup
    fi
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
    echo -n "Install dynamic ffmpeg via apt (${APT_FFMPEG_CANDIDATE})? [y/N/q] "
    read -r -n 1 reply || reply=""
    echo
    if prompt_reply_is_yes "${reply}"; then
        INSTALL_PLAN="dynamic"
        echo "Proceeding with apt install..."
    elif prompt_reply_is_quit "${reply}"; then
        echo "Quitting — no changes made."
        quit_prompt_with_optional_old_cleanup
    else
        prompt_build_from_source_fallback
    fi
}

prompt_install_plan() {
    local installed="$1" installed_date="$2" reply=""

    INSTALL_PLAN=""

    if (( FFMPEG_VERSION_SUMMARY_SHOWN == 0 )); then
        print_ffmpeg_version_check_block "${installed}" "${installed_date}"
    fi

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
        echo -n "Install static ffmpeg build? [y/N/q] "
        read -r -n 1 reply || reply=""
        echo
        if prompt_reply_is_yes "${reply}"; then
            INSTALL_PLAN="static"
            echo "Proceeding with static install..."
            return 0
        elif prompt_reply_is_quit "${reply}"; then
            echo "Quitting — no changes made."
            quit_prompt_with_optional_old_cleanup
        fi
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

normalize_legacy_versioned_bins() {
    local path="" label="" target="" ffprobe_path=""

    for path in "${BIN_DIR}"/ffmpeg-*-static; do
        [[ -f "${path}" ]] || continue
        [[ -L "${path}" ]] && continue
        if [[ "${path}" =~ ffmpeg-([0-9]+(\.[0-9]+)+)- ]]; then
            label="${BASH_REMATCH[1]}"
            target="${BIN_DIR}/ffmpeg-${label}"
            if [[ ! -e "${target}" ]]; then
                log_step "Renaming legacy $(basename "${path}") -> ffmpeg-${label}"
                mv -v "${path}" "${target}"
                ffprobe_path="${path/ffmpeg-/ffprobe-}"
                if [[ -f "${ffprobe_path}" && ! -L "${ffprobe_path}" && ! -e "${BIN_DIR}/ffprobe-${label}" ]]; then
                    mv -v "${ffprobe_path}" "${BIN_DIR}/ffprobe-${label}"
                fi
            fi
        fi
    done
}

link_active_ffmpeg_version() {
    local label="$1"

    log_step "Pointing active symlinks to ffmpeg-${label} and ffprobe-${label}"
    ln -sfn "ffmpeg-${label}" "${BIN_FFMPEG}"
    if [[ -e "${BIN_DIR}/ffprobe-${label}" ]]; then
        ln -sfn "ffprobe-${label}" "${BIN_FFPROBE}"
    fi
    ls -l "${BIN_FFMPEG}" "${BIN_FFPROBE}" 2>/dev/null || ls -l "${BIN_FFMPEG}"
}

install_versioned_bins_to_local() {
    local build_id="$1"
    local ffmpeg_src="$2"
    local ffprobe_src="${3:-}"
    local label="" vffmpeg="" vffprobe=""

    need_cmd install
    label="$(version_label_from_build_id "${build_id}")"
    vffmpeg="$(versioned_ffmpeg_bin "${build_id}")"
    vffprobe="$(versioned_ffprobe_bin "${build_id}")"

    if [[ -e "${vffmpeg}" ]]; then
        move_path_aside "${vffmpeg}"
    fi
    if [[ -n "${ffprobe_src}" && -e "${vffprobe}" ]]; then
        move_path_aside "${vffprobe}"
    fi

    log_step "Installing into ${BIN_DIR}: ffmpeg-${label}, ffprobe-${label}"
    install -m 755 "${ffmpeg_src}" "${vffmpeg}"
    if [[ -n "${ffprobe_src}" && -e "${ffprobe_src}" ]]; then
        install -m 755 "${ffprobe_src}" "${vffprobe}"
    fi
    chown root:root "${vffmpeg}"
    [[ -e "${vffprobe}" ]] && chown root:root "${vffprobe}"

    link_active_ffmpeg_version "${label}"
}

install_versioned_symlinks_to_local() {
    local build_id="$1"
    local ffmpeg_src="$2"
    local ffprobe_src="${3:-}"
    local label="" vffmpeg="" vffprobe=""

    label="$(version_label_from_build_id "${build_id}")"
    vffmpeg="$(versioned_ffmpeg_bin "${build_id}")"
    vffprobe="$(versioned_ffprobe_bin "${build_id}")"

    if [[ -e "${vffmpeg}" ]]; then
        move_path_aside "${vffmpeg}"
    fi
    if [[ -n "${ffprobe_src}" && -e "${vffprobe}" ]]; then
        move_path_aside "${vffprobe}"
    fi

    log_step "Installing into ${BIN_DIR}: ffmpeg-${label} -> ${ffmpeg_src}"
    ln -sfn "${ffmpeg_src}" "${vffmpeg}"
    if [[ -n "${ffprobe_src}" && -e "${ffprobe_src}" ]]; then
        ln -sfn "${ffprobe_src}" "${vffprobe}"
    fi

    link_active_ffmpeg_version "${label}"
}

source_profile_is_valid() {
    case "${1}" in
        min|common|max|gpu|nvidia) return 0 ;;
        *) return 1 ;;
    esac
}

source_profile_label() {
    case "${SOURCE_PROFILE}" in
        min) echo "minimal static (openssl, libmp3lame, x264, opus)" ;;
        common) echo "common static (recommended codec set)" ;;
        max) echo "max static (common + extra codecs)" ;;
        gpu) echo "GPU/VAAPI (shared libs, Intel/AMD)" ;;
        nvidia) echo "NVIDIA NVENC/CUDA (shared libs, non-free)" ;;
        *) echo "${SOURCE_PROFILE}" ;;
    esac
}

ffmpeg_source_build_id() {
    local version="$1"
    printf '%s-src-%s' "${version}" "${SOURCE_PROFILE}"
}

apt_cache_has_package() {
    apt-cache show "$1" >/dev/null 2>&1
}

apt_install_packages() {
    local pkg="" -a packages=()
    for pkg in "$@"; do
        [[ -n "${pkg}" ]] && packages+=( "${pkg}" )
    done
    ((${#packages[@]} > 0)) || return 0
    apt-get install -y "${packages[@]}"
}

apt_install_optional_packages() {
    local pkg="" -a present=()
    for pkg in "$@"; do
        if apt_cache_has_package "${pkg}"; then
            present+=( "${pkg}" )
        else
            log_note "Optional package not in apt, skipping: ${pkg}"
        fi
    done
    ((${#present[@]} > 0)) || return 0
    apt-get install -y "${present[@]}"
}

gpu_vaapi_runtime_looks_available() {
    [[ -e /dev/dri/card0 || -e /dev/dri/renderD128 ]] && return 0
    if command -v vainfo >/dev/null 2>&1; then
        vainfo >/dev/null 2>&1 && return 0
    fi
    return 1
}

nvidia_runtime_looks_available() {
    command -v nvidia-smi >/dev/null 2>&1 || return 1
    nvidia-smi >/dev/null 2>&1
}

prompt_source_fdk_aac_if_max() {
    local reply=""

    [[ "${SOURCE_PROFILE}" == max ]] || return 0
    if (( CLI_SOURCE_WITH_FDK == 1 )); then
        FFMPEG_SOURCE_WITH_FDK_AAC=1
        return 0
    fi
    if (( ASSUME_YES == 1 )); then
        return 0
    fi
    echo
    echo "max profile: optional libfdk-aac (non-free license, best AAC quality)."
    echo ">>> Waiting for your answer:"
    echo -n "Include libfdk-aac in this build? [y/N/q] "
    read -r -n 1 reply || reply=""
    echo
    if prompt_reply_is_quit "${reply}"; then
        echo "Quitting — no changes made."
        quit_prompt_with_optional_old_cleanup
    fi
    if prompt_reply_is_yes "${reply}"; then
        FFMPEG_SOURCE_WITH_FDK_AAC=1
    fi
}

prompt_confirm_gpu_or_nvidia_profile() {
    local reply="" hw=""

    case "${SOURCE_PROFILE}" in
        gpu)
            if ! gpu_vaapi_runtime_looks_available; then
                echo "WARNING: no VAAPI device detected (/dev/dri or vainfo failed)." >&2
            fi
            echo
            echo "gpu profile builds a shared ffmpeg with VAAPI (needs GPU drivers at runtime)."
            echo "Not suitable for fully static/offline binaries."
            ;;
        nvidia)
            hw="$(uname -m)"
            if [[ "${hw}" == aarch64 ]] && ! nvidia_runtime_looks_available; then
                echo "ERROR: nvidia profile is not available on this host (aarch64, no working nvidia-smi)." >&2
                return 1
            fi
            if ! nvidia_runtime_looks_available; then
                echo "WARNING: nvidia-smi not working; NVENC build may fail or be unusable." >&2
            fi
            echo
            echo "nvidia profile builds a shared ffmpeg with NVENC/CUDA (non-free, needs NVIDIA driver)."
            ;;
        *) return 0 ;;
    esac
    if (( ASSUME_YES == 1 )); then
        log_note "Continuing with ${SOURCE_PROFILE} profile (--yes)."
        return 0
    fi
    echo ">>> Waiting for your answer:"
    echo -n "Continue with ${SOURCE_PROFILE} profile? [y/N/q] "
    read -r -n 1 reply || reply=""
    echo
    if prompt_reply_is_quit "${reply}"; then
        echo "Quitting — no changes made."
        quit_prompt_with_optional_old_cleanup
    fi
    prompt_reply_is_yes "${reply}"
}

prompt_source_build_profile_menu() {
    local reply=""

    while true; do
        echo
        echo "Source build profile:"
        echo "  [1] common — libmp3lame, x264, openssl, aom, … (default)"
        echo "  [2] min    — smaller/faster static build"
        echo "  [3] max    — common + extra codecs (optional libfdk-aac)"
        echo "  [4] gpu    — common + VAAPI (Intel/AMD; shared libs)"
        echo "  [5] nvidia — common + NVENC/CUDA (NVIDIA; shared libs)"
        echo "  [Q] Quit"
        echo ">>> Waiting for your answer:"
        echo -n "Choice [1/2/3/4/5/q] (Enter=common): "
        read -r -n 1 reply || reply=""
        echo
        case "${reply}" in
            q|Q)
                echo "Quitting — no changes made."
                quit_prompt_with_optional_old_cleanup
                ;;
            2|m|M) SOURCE_PROFILE=min; break ;;
            3|x|X) SOURCE_PROFILE=max; break ;;
            4|g|G) SOURCE_PROFILE=gpu; break ;;
            5|n|N) SOURCE_PROFILE=nvidia; break ;;
            1|c|C|y|Y|"") SOURCE_PROFILE=common; break ;;
            *)
                echo "Unknown choice; try again."
                ;;
        esac
    done
    prompt_source_fdk_aac_if_max
    if ! prompt_confirm_gpu_or_nvidia_profile; then
        echo "Pick another profile:"
        SOURCE_PROFILE=""
        prompt_source_build_profile_menu
    fi
}

ensure_source_build_profile_selected() {
    (( FFMPEG_SOURCE_PROFILE_READY == 1 )) && return 0

    if [[ -n "${SOURCE_PROFILE}" ]] && source_profile_is_valid "${SOURCE_PROFILE}"; then
        :
    elif [[ -n "${CLI_SOURCE_PROFILE}" ]]; then
        SOURCE_PROFILE="${CLI_SOURCE_PROFILE}"
    elif [[ -n "${FFMPEG_SOURCE_PROFILE}" ]]; then
        SOURCE_PROFILE="${FFMPEG_SOURCE_PROFILE}"
    else
        prompt_source_build_profile_menu
        return 0
    fi
    if ! source_profile_is_valid "${SOURCE_PROFILE}"; then
        echo "ERROR: invalid source profile: ${SOURCE_PROFILE}" >&2
        exit 1
    fi
    if (( CLI_SOURCE_WITH_FDK == 1 )); then
        FFMPEG_SOURCE_WITH_FDK_AAC=1
    fi
    if [[ "${SOURCE_PROFILE}" == max ]]; then
        prompt_source_fdk_aac_if_max
    fi
    if [[ "${SOURCE_PROFILE}" == gpu || "${SOURCE_PROFILE}" == nvidia ]]; then
        if ! prompt_confirm_gpu_or_nvidia_profile; then
            prompt_source_build_profile_menu
        fi
    fi
    log_note "Source build profile: ${SOURCE_PROFILE} ($(source_profile_label))"
    FFMPEG_SOURCE_PROFILE_READY=1
}

install_source_build_dependencies() {
    local -a pkgs=()

    echo
    echo "part 1 — build dependencies for official source compile (profile: ${SOURCE_PROFILE})"
    echo
    need_cmd apt-get
    log_step "Running apt-get update..."
    apt-get update

    pkgs=(
        build-essential pkg-config yasm nasm
        libunistring-dev zlib1g-dev
    )

    case "${SOURCE_PROFILE}" in
        min)
            pkgs+=(
                libssl-dev libmp3lame-dev libx264-dev libopus-dev
            )
            ;;
        common|max|gpu|nvidia)
            pkgs+=(
                libssl-dev
                libmp3lame-dev libx264-dev libx265-dev libvpx-dev
                libopus-dev libvorbis-dev libtheora-dev libass-dev libdav1d-dev
                libaom-dev libwebp-dev
                libfreetype-dev libfontconfig-dev libharfbuzz-dev
                libsoxr-dev libsnappy-dev libzimg-dev
                libspeex-dev libtwolame-dev
            )
            ;;
    esac

    case "${SOURCE_PROFILE}" in
        max|gpu|nvidia)
            apt_install_optional_packages \
                libopenjpeg-dev libbluray-dev libchromaprint-dev \
                libgme-dev libopenmpt-dev libvidstab-dev libxml2-dev libshine-dev
            ;;
    esac

    case "${SOURCE_PROFILE}" in
        max|common|gpu|nvidia)
            FFMPEG_SOURCE_HAS_SVTAV1=0
            if apt_cache_has_package libsvtav1-dev; then
                pkgs+=( libsvtav1-dev )
                FFMPEG_SOURCE_HAS_SVTAV1=1
            else
                log_note "libsvtav1-dev not in apt; SVT-AV1 encoder will be skipped."
            fi
            ;;
        *)
            FFMPEG_SOURCE_HAS_SVTAV1=0
            ;;
    esac

    if [[ "${SOURCE_PROFILE}" == max ]] && (( FFMPEG_SOURCE_WITH_FDK_AAC == 1 )); then
        FFMPEG_SOURCE_HAS_FDK_AAC=0
        if apt_cache_has_package libfdk-aac-dev; then
            pkgs+=( libfdk-aac-dev )
            FFMPEG_SOURCE_HAS_FDK_AAC=1
        else
            echo "ERROR: libfdk-aac-dev not available in apt; disable --source-with-fdk-aac or pick another profile." >&2
            return 1
        fi
    else
        FFMPEG_SOURCE_HAS_FDK_AAC=0
    fi

    if [[ "${SOURCE_PROFILE}" == gpu ]]; then
        apt_install_optional_packages libva-dev libvdpau-dev libdrm-dev libvulkan-dev
    fi

    if [[ "${SOURCE_PROFILE}" == nvidia ]]; then
        apt_install_optional_packages nvidia-cuda-toolkit libnpp-dev
    fi

    log_step "Installing compiler and profile packages..."
    apt_install_packages "${pkgs[@]}"
    log_note "Build dependencies installed."
}

ffmpeg_source_configure_args() {
    local staging="$1"
    local -a args=()
    local pkg_config_flags="--static"
    local extra_libs="-lpthread -lm"

    args=(
        --prefix="${staging}"
        --disable-debug
        --enable-gpl
        --enable-version3
    )

    if [[ "${SOURCE_PROFILE}" == gpu || "${SOURCE_PROFILE}" == nvidia ]]; then
        args+=( --enable-shared --disable-static )
        pkg_config_flags=""
        extra_libs="-lpthread -lm -ldl"
    else
        args+=( --enable-static --disable-shared )
    fi

    args+=(
        --pkg-config-flags="${pkg_config_flags}"
        "--extra-libs=${extra_libs}"
        --enable-openssl
    )

    case "${SOURCE_PROFILE}" in
        min)
            args+=(
                --enable-libmp3lame
                --enable-libx264
                --enable-libopus
            )
            ;;
        common|max|gpu|nvidia)
            args+=(
                --enable-libmp3lame
                --enable-libx264
                --enable-libx265
                --enable-libvpx
                --enable-libopus
                --enable-libvorbis
                --enable-libtheora
                --enable-libass
                --enable-libdav1d
                --enable-libaom
                --enable-libwebp
                --enable-libfreetype
                --enable-libfontconfig
                --enable-libsoxr
                --enable-libsnappy
                --enable-libzimg
                --enable-libspeex
                --enable-libtwolame
            )
            ;;
    esac

    if (( FFMPEG_SOURCE_HAS_SVTAV1 == 1 )); then
        args+=( --enable-libsvtav1 )
    fi

    if [[ "${SOURCE_PROFILE}" == max || "${SOURCE_PROFILE}" == gpu || "${SOURCE_PROFILE}" == nvidia ]]; then
        pkg-config --exists libopenjp2 2>/dev/null && args+=( --enable-libopenjpeg )
        pkg-config --exists libbluray 2>/dev/null && args+=( --enable-libbluray )
        pkg-config --exists libchromaprint 2>/dev/null && args+=( --enable-libchromaprint )
        pkg-config --exists libgme 2>/dev/null && args+=( --enable-libgme )
        pkg-config --exists libopenmpt 2>/dev/null && args+=( --enable-libopenmpt )
        pkg-config --exists vidstab 2>/dev/null && args+=( --enable-libvidstab )
        pkg-config --exists libxml-2.0 2>/dev/null && args+=( --enable-libxml2 )
        pkg-config --exists shine 2>/dev/null && args+=( --enable-libshine )
    fi

    if [[ "${SOURCE_PROFILE}" == max ]] && (( FFMPEG_SOURCE_HAS_FDK_AAC == 1 )); then
        args+=( --enable-nonfree --enable-libfdk-aac )
    fi

    if [[ "${SOURCE_PROFILE}" == gpu ]]; then
        pkg-config --exists libva 2>/dev/null && args+=( --enable-vaapi )
        pkg-config --exists libdrm 2>/dev/null && args+=( --enable-libdrm )
        pkg-config --exists vulkan 2>/dev/null && args+=( --enable-vulkan )
    fi

    if [[ "${SOURCE_PROFILE}" == nvidia ]]; then
        args+=(
            --enable-nonfree
            --enable-nvenc
            --enable-cuvid
        )
        if command -v nvcc >/dev/null 2>&1; then
            args+=( --enable-cuda-nvcc --enable-libnpp )
        else
            log_note "nvcc not found; building NVENC without CUDA/NPP compile support."
        fi
    fi

    if [[ -n "${FFMPEG_CONFIGURE_EXTRA}" ]]; then
        read -r -a configure_extra <<< "${FFMPEG_CONFIGURE_EXTRA}"
        args+=( "${configure_extra[@]}" )
    fi
    printf '%s\n' "${args[@]}"
}

print_source_build_encoder_check() {
    local ffmpeg_exe="$1"
    local line="" found=0 pattern=""

    [[ -n "${ffmpeg_exe}" && -x "${ffmpeg_exe}" ]] || return 0

    case "${SOURCE_PROFILE}" in
        min) pattern='libmp3lame|libx264|libopus' ;;
        max)
            if (( FFMPEG_SOURCE_HAS_FDK_AAC == 1 )); then
                pattern='libmp3lame|libx264|libfdk_aac|libaom|libsvtav1'
            else
                pattern='libmp3lame|libx264|libopus|libaom|libsvtav1|libtwolame'
            fi
            ;;
        gpu) pattern='libmp3lame|libx264|h264_vaapi|hevc_vaapi' ;;
        nvidia) pattern='libmp3lame|libx264|h264_nvenc|hevc_nvenc' ;;
        *) pattern='libmp3lame|libx264|libopus|libaom|libsvtav1|libtwolame' ;;
    esac

    echo
    echo "Sample encoders in built ffmpeg (profile: ${SOURCE_PROFILE}):"
    while IFS= read -r line; do
        [[ -n "${line}" ]] || continue
        echo "  ${line}"
        found=1
    done < <("${ffmpeg_exe}" -hide_banner -encoders 2>/dev/null | grep -E "${pattern}" || true)
    if (( found == 0 )); then
        echo "  WARNING: expected encoders not found (check configure log)." >&2
    fi
}

perform_install_build_from_source() {
    local version="${FFMPEG_ORG_VERSION}"
    local tarball url src_dir build_id="" staging="" jobs=""

    if ! ensure_ffmpeg_org_release_version; then
        echo "ERROR: ffmpeg.org release version is unknown." >&2
        return 1
    fi

    ensure_source_build_profile_selected

    echo
    echo "part 1 — official ffmpeg.org release source (${version}, profile: ${SOURCE_PROFILE})"
    echo

    need_cmd make
    need_cmd gcc
    need_cmd install
    need_cmd pkg-config
    normalize_legacy_versioned_bins
    install_source_build_dependencies

    tarball="$(ffmpeg_org_release_tarball_name "${version}")"
    url="$(ffmpeg_org_release_tarball_url "${version}")"
    build_id="$(ffmpeg_source_build_id "${version}")"

    mkdir -p "${TEMP_CATALOG}" "${BIN_DIR}"
    TMP_WORK_DIR="$(mktemp -d "${TEMP_CATALOG}/ffmpeg-source-build.XXXXXX")"
    staging="${TMP_WORK_DIR}/staging"

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

    echo
    echo "part 3 — configure and compile static build (this can take a long time)"
    echo

    cd "${src_dir}"
    log_step "Running ffmpeg configure (profile ${SOURCE_PROFILE}, release ${version})..."
    configure_args=()
    while IFS= read -r flag; do
        [[ -n "${flag}" ]] && configure_args+=( "${flag}" )
    done < <(ffmpeg_source_configure_args "${staging}")
    log_note "Configure flags: ${configure_args[*]}"
    ./configure "${configure_args[@]}"

    jobs="$(nproc 2>/dev/null || echo 2)"
    log_step "Building with make -j${jobs}..."
    make -j"${jobs}"
    log_step "Staging install before copying to ${BIN_DIR}..."
    make install

    if [[ ! -x "${staging}/bin/ffmpeg" ]]; then
        echo "ERROR: staged ffmpeg binary not found: ${staging}/bin/ffmpeg" >&2
        return 1
    fi

    print_source_build_encoder_check "${staging}/bin/ffmpeg"

    install_versioned_bins_to_local "${build_id}" "${staging}/bin/ffmpeg" "${staging}/bin/ffprobe"
    print_install_success_summary "${build_id}" "official source ${SOURCE_PROFILE} ${version}"
    return 0
}

print_run_finish_versions() {
    local ffmpeg_exe=""

    echo
    echo "part — installed ffmpeg version"
    echo
    ffmpeg_exe="$(resolve_active_ffmpeg_exe || true)"
    if [[ -n "${ffmpeg_exe}" && -x "${ffmpeg_exe}" ]]; then
        if command -v timeout >/dev/null 2>&1; then
            timeout "${FFMPEG_PROBE_TIMEOUT_SEC}" "${ffmpeg_exe}" -version
        else
            "${ffmpeg_exe}" -version
        fi
    elif command -v ffmpeg >/dev/null 2>&1; then
        if command -v timeout >/dev/null 2>&1; then
            timeout "${FFMPEG_PROBE_TIMEOUT_SEC}" ffmpeg -version
        else
            ffmpeg -version
        fi
    else
        echo "WARNING: could not run ffmpeg -version (binary not found)." >&2
    fi
    echo
    print_version_banner
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
    echo "  Active:  ${BIN_FFMPEG} -> $(readlink "${BIN_FFMPEG}" 2>/dev/null || echo '?')"
    echo "           ${BIN_FFPROBE} -> $(readlink "${BIN_FFPROBE}" 2>/dev/null || echo '?')"
    list_preserved_ffmpeg_versions
    prompt_remove_old_ffmpeg_installs
    print_run_finish_versions
}

perform_install_static() {
    local tarball url extracted_dir build_id="" static_semver=""

    echo
    echo "part 1 — download static ffmpeg (${FFMPEG_BUILD_KIND}, ${FFMPEG_ARCH})"
    echo

    need_cmd tar
    need_cmd find
    need_cmd ln
    need_cmd mkdir
    need_cmd install

    if (( STATIC_TARBALL_AVAILABLE == 0 )); then
        echo "ERROR: Static tarball is not available." >&2
        return 1
    fi

    normalize_legacy_versioned_bins
    mkdir -p "${TEMP_CATALOG}" "${BIN_DIR}"
    TMP_WORK_DIR="$(mktemp -d "${TEMP_CATALOG}/ffmpeg-install.XXXXXX")"
    tarball="${TMP_WORK_DIR}/$(ffmpeg_tarball_basename)"
    url="$(ffmpeg_tarball_url)"

    if ! download_file "${url}" "${tarball}"; then
        return 1
    fi
    verify_tarball_md5 "${tarball}"

    echo
    echo "part 2 — extract and install into ${BIN_DIR}"
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

    if [[ ! -x "${extracted_dir}/ffmpeg" ]]; then
        echo "ERROR: ffmpeg binary not found in extracted static build." >&2
        return 1
    fi

    install_versioned_bins_to_local "${build_id}" "${extracted_dir}/ffmpeg" "${extracted_dir}/ffprobe"
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
    normalize_legacy_versioned_bins
    mkdir -p "${BIN_DIR}"

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

    install_versioned_symlinks_to_local "${build_id}" "${apt_ffmpeg}" "${apt_ffprobe}"
    print_install_success_summary "${build_id}" "dynamic apt"
    return 0
}

run_install_plan() {
    check_ffmpeg_running_before_install

    case "${INSTALL_PLAN}" in
        static)
            if perform_install_static; then
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
    if ffmpeg_is_running; then
        log_step "Running ffmpeg/ffprobe detected — stop or skip before install prompts..."
        handle_running_ffmpeg_interactive "${installed}" "${installed_date}"
    fi
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
        echo "  profile: ${SOURCE_PROFILE:-common}"
        (( FFMPEG_SOURCE_WITH_FDK_AAC == 1 )) && echo "  extras:  libfdk-aac (non-free)"
    fi
    echo "  temp:    ${TEMP_CATALOG}"
    echo

    run_install_plan
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
        --source-profile)
            [[ $# -ge 2 ]] || { echo "Missing value for --source-profile" >&2; usage >&2; exit 1; }
            if ! source_profile_is_valid "${2}"; then
                echo "Invalid --source-profile: ${2} (use min, common, max, gpu, or nvidia)" >&2
                exit 1
            fi
            CLI_SOURCE_PROFILE="${2}"
            shift 2
            ;;
        --source-with-fdk-aac) CLI_SOURCE_WITH_FDK=1; shift ;;
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
