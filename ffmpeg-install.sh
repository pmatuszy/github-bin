#!/usr/bin/env bash
# v. 20260716.182500 - run make in clean subprocess (close inherited FDs before compile)

# 2026.06.23 - v. 2.1.23 - jellyfin profile: Jellyfin-like shared build (VAAPI+NVENC+FDK-AAC); common stays default
# 2026.06.26 - v. 2.1.22 - Ubuntu: libopenjp2-7-dev (not libopenjpeg-dev); optional pkg probe must not abort configure
# 2026.06.26 - v. 2.1.21 - source build: install apt deps before need_cmd pkg-config (was checked too early)
# 2026.06.16 - v. 2.1.20 - default install is official source build (common profile: libmp3lame, x264, …)
# 2026.06.12 - v. 2.1.19 - libfdk-aac prompt defaults to yes [Y/n/q]
# 2026.06.12 - v. 2.1.18 - remove old version dirs (legacy ffmpeg-* directories); encoder probe fallback
# 2026.06.12 - v. 2.1.17 - static install prompt shows planned version (e.g. 8.1.1)
# 2026.06.11 - v. 2.1.16 - quit exits immediately (no old-version removal prompt); skip backup-* in old-version list
# 2026.06.11 - v. 2.1.15 - ffprobe/ffplay version labels match ffmpeg; fix *-unknown; parse ffprobe/ffplay -version
# 2026.06.11 - v. 2.1.14 - column-align installed binary path lines (tool / kind / path)
# 2026.06.11 - v. 2.1.13 - fix local -a syntax in print_installed_tool_binary_paths (bash on backupche)
# 2026.06.11 - v. 2.1.12 - installed path listing: symlink target and resolved real file for each tool
# 2026.06.11 - v. 2.1.11 - version check prompt: show full paths to installed ffmpeg/ffprobe/ffplay binaries
# 2026.06.11 - v. 2.1.10 - versioned filenames use release semver (8.1.1); git static falls back to ffmpeg.org version
# 2026.06.11 - v. 2.1.9 - versioned bin names use semver or N-REV (not YYYYMMDD); migrate date-named bins
# 2026.06.11 - v. 2.1.8 - ffplay versioned layout; plain ff* -> versioned file + symlink; /bin/env; end summary
# 2026.06.11 - v. 2.1.7 - detect johnvansickle git ffmpeg (N-*-g*-YYYYMMDD) and localbin date builds
# 2026.06.11 - v. 2.1.6 - source install: absolute staging prefix, unset DESTDIR, recover ffmpeg from build tree
# 2026.06.11 - v. 2.1.5 - probe pkg-config (incl. static) before each --enable-lib*; fixes x265 etc. on jammy
# 2026.06.11 - v. 2.1.4 - skip libsvtav1 when SvtAv1Enc >= 0.9.0 not satisfied by pkg-config (e.g. jammy arm64)
# 2026.06.11 - v. 2.1.3 - skip libdav1d when distro dav1d < 1.0.0 (e.g. Ubuntu 22.04); libaom still used
# 2026.06.11 - v. 2.1.2 - max profile: --enable-chromaprint (not --enable-libchromaprint) for ffmpeg 8.x
# 2026.06.11 - v. 2.1.1 - fix nounset tarball URL, apt local -a syntax, duplicate profile/fdk prompts
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
# Static builds:     https://johnvansickle.com/ffmpeg/ (minimal codecs — usually no libmp3lame)
# Git (master) static builds are recommended for bug fixes; release static builds also exist.
# Default install:   compile official ffmpeg.org release (common profile: libmp3lame, x264, …).
# Jellyfin transcode: --source-profile jellyfin (shared, VAAPI+NVENC+FDK-AAC; long compile).
# Dynamic fallback:  distro ffmpeg package via apt.
# Static fallback:     prebuilt johnvansickle tarball when source build is declined or unavailable.
#

set -euo pipefail

FFMPEG_BASE_URL="https://johnvansickle.com/ffmpeg"
BIN_DIR="/usr/local/bin"
BIN_FFMPEG="${BIN_DIR}/ffmpeg"
BIN_FFPROBE="${BIN_DIR}/ffprobe"
BIN_FFPLAY="${BIN_DIR}/ffplay"
FFMPEG_ACTIVE_TOOLS=( ffmpeg ffprobe ffplay )
FFMPEG_TOOL_LABEL_WIDTH=7
FFMPEG_TOOL_KIND_WIDTH=11
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
FFMPEG_MAKE_JOBS="${FFMPEG_MAKE_JOBS:-1}"
FFMPEG_MAKE_NOFILE="${FFMPEG_MAKE_NOFILE:-}"
FFMPEG_SOURCE_WITH_LTO="${FFMPEG_SOURCE_WITH_LTO:-0}"
FFMPEG_SOURCE_DISABLE_LTO=0
FFMPEG_SOURCE_WITH_CUDA_NVCC="${FFMPEG_SOURCE_WITH_CUDA_NVCC:-0}"
FFMPEG_SOURCE_SKIP_CUDA_NVCC=0
FFMPEG_SOURCE_MAKE_RETRY_DONE=0
FFMPEG_SOURCE_MAKE_EMFILE_RETRY_DONE=0
FFMPEG_SOURCE_LAST_MAKE_RC=0
FFMPEG_SOURCE_LAST_MAKE_LOG=""
FFMPEG_SOURCE_PROFILE="${FFMPEG_SOURCE_PROFILE:-}"
CLI_SOURCE_PROFILE=""
CLI_SOURCE_WITH_FDK=0
SOURCE_PROFILE=""
FFMPEG_SOURCE_WITH_FDK_AAC=0
FFMPEG_SOURCE_HAS_SVTAV1=0
FFMPEG_SOURCE_HAS_DAV1D=0
FFMPEG_SOURCE_HAS_FDK_AAC=0
FFMPEG_SOURCE_PROFILE_READY=0
FFMPEG_SOURCE_SKIP_VULKAN=0
FFMPEG_VULKAN_HEADERS_UPGRADE_ATTEMPTED=0
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
INSTALLED_BUILD_SNAPSHOT_DATE=""
INSTALLED_GIT_REVISION=""
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

show_help() {
    cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [-y|--yes] [-q|--quiet] [--release]
       [--dynamic-only] [--static-only] [--source-only]
       [--source-profile min|common|max|gpu|nvidia|jellyfin] [--source-with-fdk-aac]
       [--no_startup_delay]

When ffmpeg/ffprobe is running, offers graceful kill (SIGTERM), then force kill
(SIGKILL) if needed, or [S]kip to compare running vs installable versions.
Re-checks before any install step. With --yes, tries graceful then force kill.

Check installed ffmpeg against ffmpeg.org, then optionally install:
  1) official source build (default) — common profile: libmp3lame, x264, x265, opus, aom, …
     Profiles: min, common (default), max, gpu (VAAPI), nvidia (NVENC/CUDA), jellyfin (Jellyfin-like)
  2) prebuilt static (johnvansickle.com — minimal codecs, usually no MP3 encode)
  3) dynamic package (apt)
Older installs are moved aside, not deleted.

Install layout (/usr/local/bin):
  ffmpeg-VERSION            versioned binary (release semver e.g. 8.1.1; apt uses 6.1.1-apt internally)
  ffprobe-VERSION           matching ffprobe
  ffplay-VERSION            matching ffplay (when present in static/source build)
  ffmpeg                    symlink -> ffmpeg-VERSION (active)
  ffprobe                   symlink -> ffprobe-VERSION (active)
  ffplay                    symlink -> ffplay-VERSION (active, when installed)
  ffmpeg-VERSION-backup-*   same-name binary moved aside before replace
  Plain ffmpeg/ffprobe/ffplay files are migrated to versioned names on startup.

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  -y, --yes            Install without prompting: official source build (common
                       profile) if ffmpeg.org version is known; else static or apt.
  -q, --quiet          Less progress output (errors still shown).

Default install prompt uses [Y/n/q]: Enter/Y = source common, n = other options, q = quit.
Other prompts use [y/N/q]: y = yes, Enter/N = no, q = quit.
  --release            Use release static builds instead of git (master) builds.
  --dynamic-only       Install distro ffmpeg via apt only.
  --static-only        Do not fall back to apt or source build.
  --source-only        Build from official ffmpeg.org source only (no static/apt prompts).
  --source-profile P   Source build profile: min, common, max, gpu, nvidia, or jellyfin
                       (with --source-only, skips profile confirmation prompts).
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
  FFMPEG_MAKE_JOBS            Parallel make jobs for source builds (default: 1).
  FFMPEG_MAKE_NOFILE          Open-file soft limit for make (default: process hard ulimit -Hn).
  FFMPEG_SOURCE_WITH_LTO      Set to 1 to pass --enable-lto=auto (jellyfin; off by default; can crash on some hosts).
  FFMPEG_SOURCE_WITH_CUDA_NVCC  Set to 1 to pass --enable-cuda-nvcc (CUDA filters; off by default).
  FFMPEG_SOURCE_PROFILE       Same as --source-profile (min|common|max|gpu|nvidia|jellyfin).
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

build_id_is_git_revision() {
    [[ "${1}" =~ ^N-[0-9]+$ ]]
}

version_label_is_date_only() {
    [[ "${1}" =~ ^[0-9]{8}$ ]]
}

build_ids_comparable() {
    local a="$1" b="$2"
    build_id_is_date "${a}" && build_id_is_date "${b}" && return 0
    build_id_is_semver "${a}" && build_id_is_semver "${b}" && return 0
    build_id_is_git_revision "${a}" && build_id_is_git_revision "${b}" && return 0
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
        if [[ -n "${INSTALLED_BUILD_KIND}" ]]; then
            echo "installed (${BIN_FFMPEG}, build id unknown)"
            return 0
        fi
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
    if [[ -n "${INSTALLED_GIT_REVISION}" ]]; then
        if [[ -n "${date_label}" && "${date_label}" != "unknown" ]]; then
            echo "ffmpeg ${build_id} (git ${INSTALLED_GIT_REVISION}, snapshot ${date_label})"
        else
            echo "ffmpeg ${build_id} (git ${INSTALLED_GIT_REVISION})"
        fi
        return 0
    fi
    if [[ -n "${INSTALLED_FFMPEG_SEMVER}" ]]; then
        if [[ "${INSTALLED_FFMPEG_SEMVER}" == "${build_id}" ]]; then
            echo "ffmpeg ${build_id}"
        else
            echo "ffmpeg ${INSTALLED_FFMPEG_SEMVER} (${build_id})"
        fi
        return 0
    fi
    if build_id_is_date "${build_id}"; then
        format_build_with_date "${build_id}" "${date_label}" date
        return 0
    fi
    echo "build ${build_id}"
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
    local version="${1:-${FFMPEG_ORG_VERSION}}"
    echo "https://ffmpeg.org/releases/$(ffmpeg_org_release_tarball_name "${version}")"
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
    if [[ "${id}" =~ ^([0-9]+(\.[0-9]+)+)-src(-[a-z]+)?$ ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    fi
    if [[ "${id}" =~ ^([0-9]+(\.[0-9]+)+)-apt$ ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    fi
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

versioned_ffplay_bin() {
    echo "${BIN_DIR}/ffplay-$(version_label_from_build_id "$1")"
}

versioned_tool_bin() {
    local tool="$1" build_id="$2"
    echo "${BIN_DIR}/${tool}-$(version_label_from_build_id "${build_id}")"
}

run_env() {
    /bin/env "$@"
}

probe_tool_version_output() {
    local exe="$1"
    local out="" rc=0

    [[ -n "${exe}" && -x "${exe}" ]] || return 1
    if command -v timeout >/dev/null 2>&1; then
        out="$(timeout "${FFMPEG_PROBE_TIMEOUT_SEC}" "${exe}" -version 2>&1)" || rc=$?
    else
        out="$("${exe}" -version 2>&1)" || rc=$?
    fi
    (( rc == 0 )) || return 1
    printf '%s' "${out}"
}

# Filename label: release semver (8.1.1) — not calendar dates or git N-REV tokens.
resolve_version_label_from_version_output() {
    local text="$1"
    local fallback="${2:-}"
    local semver=""

    if semver="$(parse_ffmpeg_semver_from_version_output "${text}")"; then
        echo "${semver}"
        return 0
    fi
    if [[ "${text}" =~ ff(mpeg|probe|play)[[:space:]]+version[[:space:]]+([0-9]+(\.[0-9]+)+)-static ]]; then
        echo "${BASH_REMATCH[2]}"
        return 0
    fi
    if [[ "${text}" =~ ff(mpeg|probe|play)[[:space:]]+version[[:space:]]+N-[0-9]+-g[0-9a-fA-F]+-[0-9]{8} ]]; then
        if [[ -n "${fallback}" ]]; then
            echo "${fallback}"
            return 0
        fi
    fi
    return 1
}

resolve_version_label_from_executable() {
    local exe="$1"
    local fallback="${2:-}"
    local out=""

    out="$(probe_tool_version_output "${exe}" || true)"
    [[ -n "${out}" ]] || return 1
    resolve_version_label_from_version_output "${out}" "${fallback}"
}

planned_static_install_version() {
    if [[ -n "${FFMPEG_ORG_VERSION}" ]]; then
        echo "${FFMPEG_ORG_VERSION}"
        return 0
    fi
    if [[ -n "${REMOTE_BUILD_LABEL}" && "${REMOTE_BUILD_LABEL}" != "latest" ]]; then
        echo "${REMOTE_BUILD_LABEL}"
        return 0
    fi
    if [[ -n "${REMOTE_BUILD_DATE}" && "${REMOTE_BUILD_DATE}" != "unknown" ]]; then
        echo "${REMOTE_BUILD_DATE}"
        return 0
    fi
    return 1
}

label_from_executable() {
    local exe="$1"
    local label="" ffmpeg_label=""

    label="$(resolve_version_label_from_executable "${exe}" "${FFMPEG_ORG_VERSION:-}" || true)"
    if [[ -n "${label}" ]]; then
        echo "${label}"
        return 0
    fi
    ffmpeg_label="$(active_ffmpeg_version_label 2>/dev/null || true)"
    [[ -n "${ffmpeg_label}" ]] && echo "${ffmpeg_label}"
}

version_label_is_unknown() {
    [[ "${1:-}" == unknown ]]
}

version_label_is_backup_aside() {
    [[ "${1:-}" == backup-* || "${1:-}" == *-backup-* ]]
}

version_label_needs_semver_migration() {
    local label="$1"
    version_label_is_date_only "${label}" || build_id_is_git_revision "${label}" || version_label_is_unknown "${label}"
}

rename_versioned_tool_set_if_needed() {
    local old_label="$1" new_label="$2"
    local tool="" old_path="" new_path="" active_label=""

    [[ -n "${old_label}" && -n "${new_label}" && "${old_label}" != "${new_label}" ]] || return 0
    version_label_needs_semver_migration "${old_label}" || return 0

    active_label="$(get_active_version_label 2>/dev/null || true)"

    for tool in "${FFMPEG_ACTIVE_TOOLS[@]}"; do
        old_path="${BIN_DIR}/${tool}-${old_label}"
        new_path="${BIN_DIR}/${tool}-${new_label}"
        [[ -e "${old_path}" ]] || continue
        if [[ -e "${new_path}" && ! "${old_path}" -ef "${new_path}" ]]; then
            move_path_aside "${new_path}"
        fi
        if [[ ! -e "${new_path}" ]]; then
            log_step "Renaming ${tool}-${old_label} -> ${tool}-${new_label}"
            mv -v "${old_path}" "${new_path}"
        fi
        link="${BIN_DIR}/${tool}"
        if [[ -L "${link}" ]]; then
            current="$(readlink "${link}" 2>/dev/null || true)"
            if [[ "${current}" == "${tool}-${old_label}" ]]; then
                ln -sfn "${tool}-${new_label}" "${link}"
            fi
        elif [[ "${active_label}" == "${old_label}" && ! -e "${link}" ]]; then
            ln -sfn "${tool}-${new_label}" "${link}"
        fi
    done
}

normalize_mislabeled_versioned_bins() {
    local path="" name="" old_label="" version_label=""

    for path in "${BIN_DIR}"/ffmpeg-*; do
        [[ -e "${path}" ]] || continue
        [[ -f "${path}" || -L "${path}" ]] || continue
        name="$(basename -- "${path}")"
        [[ "${name}" =~ ^ffmpeg-(.+)$ ]] || continue
        old_label="${BASH_REMATCH[1]}"
        version_label_is_backup_aside "${old_label}" && continue
        version_label_needs_semver_migration "${old_label}" || continue
        version_label="$(resolve_version_label_from_executable "${path}" "${FFMPEG_ORG_VERSION:-}" || true)"
        [[ -n "${version_label}" ]] || continue
        rename_versioned_tool_set_if_needed "${old_label}" "${version_label}"
    done
}

normalize_local_bin_active_tool() {
    local tool="$1"
    local path="${BIN_DIR}/${tool}"
    local label="" versioned=""

    [[ -e "${path}" ]] || return 0
    [[ -L "${path}" ]] && return 0
    [[ -f "${path}" ]] || return 0

    label="$(label_from_executable "${path}" || true)"
    if [[ -z "${label}" ]]; then
        label="$(active_ffmpeg_version_label 2>/dev/null || true)"
    fi
    [[ -n "${label}" ]] || label="unknown"

    versioned="${BIN_DIR}/${tool}-${label}"
    if [[ ! -e "${versioned}" ]]; then
        log_step "Migrating plain ${tool} -> ${tool}-${label}"
        mv -v "${path}" "${versioned}"
    else
        log_step "Plain ${tool} duplicates ${tool}-${label}; moving plain file aside"
        move_path_aside "${path}"
    fi
    ln -sfn "${tool}-${label}" "${path}"
}

normalize_unknown_labeled_versioned_bins() {
    local correct_label=""

    correct_label="$(active_ffmpeg_version_label 2>/dev/null || true)"
    [[ -n "${correct_label}" && "${correct_label}" != unknown ]] || return 0
    rename_versioned_tool_set_if_needed "unknown" "${correct_label}"
}

normalize_local_bin_active_tools() {
    local tool=""

    normalize_mislabeled_versioned_bins
    for tool in "${FFMPEG_ACTIVE_TOOLS[@]}"; do
        normalize_local_bin_active_tool "${tool}"
    done
    normalize_unknown_labeled_versioned_bins
}

get_active_version_label() {
    local link=""
    link="$(readlink "${BIN_FFMPEG}" 2>/dev/null || true)"
    [[ "${link}" =~ ^ffmpeg-(.+)$ ]] || return 1
    echo "${BASH_REMATCH[1]}"
}

active_ffmpeg_version_label() {
    local label="" exe=""

    if label="$(get_active_version_label 2>/dev/null)"; then
        echo "${label}"
        return 0
    fi

    exe="$(readlink -f "${BIN_FFMPEG}" 2>/dev/null || true)"
    if [[ -n "${exe}" && -x "${exe}" && ! -d "${exe}" ]]; then
        if label="$(resolve_version_label_from_executable "${exe}" "${FFMPEG_ORG_VERSION:-}" || true)"; then
            [[ -n "${label}" ]] && echo "${label}" && return 0
        fi
    fi

    for exe in "${BIN_DIR}"/ffmpeg-*; do
        [[ -f "${exe}" && ! -L "${exe}" ]] || continue
        [[ "${exe}" == *-backup-* ]] && continue
        if label="$(resolve_version_label_from_executable "${exe}" "${FFMPEG_ORG_VERSION:-}" || true)"; then
            [[ -n "${label}" && "${label}" != unknown ]] && echo "${label}" && return 0
        fi
    done

    [[ -n "${FFMPEG_ORG_VERSION}" ]] && echo "${FFMPEG_ORG_VERSION}"
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

remove_versioned_tool_path() {
    local path="$1"

    [[ -n "${path}" && -e "${path}" ]] || return 0
    if [[ -d "${path}" && ! -L "${path}" ]]; then
        log_note "Removing directory ${path}"
        rm -rf -- "${path}"
        return 0
    fi
    rm -f -- "${path}"
}

remove_versioned_ffmpeg_set() {
    local label="$1"
    local tool="" path=""

    for tool in ffmpeg ffprobe ffplay; do
        path="${BIN_DIR}/${tool}-${label}"
        remove_versioned_tool_path "${path}"
    done
}

parse_ffmpeg_semver_from_version_output() {
    local text="$1"
    if [[ "${text}" =~ ff(mpeg|probe|play)[[:space:]]+version[[:space:]]+([0-9]+(\.[0-9]+)+) ]]; then
        echo "${BASH_REMATCH[2]}"
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

resolve_active_ffplay_exe() {
    local target=""

    for target in "${BIN_FFPLAY}"; do
        if [[ -L "${target}" || -e "${target}" ]]; then
            target="$(readlink -f "${target}" 2>/dev/null || true)"
            if [[ -n "${target}" && -x "${target}" && ! -d "${target}" ]]; then
                echo "${target}"
                return 0
            fi
        fi
    done

    if command -v ffplay >/dev/null 2>&1; then
        command -v ffplay
        return 0
    fi

    return 1
}

resolve_active_tool_exe() {
    case "${1}" in
        ffmpeg) resolve_active_ffmpeg_exe ;;
        ffprobe) resolve_active_ffprobe_exe ;;
        ffplay) resolve_active_ffplay_exe ;;
        *) return 1 ;;
    esac
}

print_tool_install_kind_line() {
    local tool="$1" kind="$2" detail="$3"
    printf '    %-*s %-*s %s\n' \
        "${FFMPEG_TOOL_LABEL_WIDTH}" "${tool}" \
        "${FFMPEG_TOOL_KIND_WIDTH}" "${kind}" \
        "${detail}"
}

print_tool_install_path_detail() {
    local tool="$1"
    local path="${BIN_DIR}/${tool}"
    local target="" hop="" resolved=""

    if [[ -L "${path}" ]]; then
        target="$(readlink "${path}" 2>/dev/null || true)"
        print_tool_install_kind_line "${tool}" "symlink:" "${path} -> ${target:-?}"
        if [[ -n "${target}" ]]; then
            if [[ "${target}" == /* ]]; then
                hop="${target}"
            else
                hop="${BIN_DIR}/${target}"
            fi
            if [[ -L "${hop}" ]]; then
                print_tool_install_kind_line "${tool}" "points to:" "${hop} -> $(readlink "${hop}" 2>/dev/null || echo '?')"
            elif [[ -f "${hop}" ]]; then
                print_tool_install_kind_line "${tool}" "points to:" "${hop}"
            fi
        fi
    elif [[ -f "${path}" ]]; then
        print_tool_install_kind_line "${tool}" "file:" "${path} (plain binary, not a symlink)"
    else
        return 1
    fi

    resolved="$(readlink -f "${path}" 2>/dev/null || true)"
    if [[ -n "${resolved}" && -x "${resolved}" && ! -d "${resolved}" ]]; then
        print_tool_install_kind_line "${tool}" "real file:" "${resolved}"
    fi
    return 0
}

tool_is_installed_under_bin_dir() {
    local tool="$1"
    local path="${BIN_DIR}/${tool}"
    [[ -e "${path}" || -L "${path}" ]]
}

print_installed_tool_binary_paths() {
    local tool=""
    local -a installed_tools=()

    for tool in "${FFMPEG_ACTIVE_TOOLS[@]}"; do
        if tool_is_installed_under_bin_dir "${tool}"; then
            installed_tools+=( "${tool}" )
        fi
    done

    if ((${#installed_tools[@]} == 0)); then
        echo "  Installed binaries: (none under ${BIN_DIR})"
        return 0
    fi

    echo "  Installed binaries:"
    for tool in "${installed_tools[@]}"; do
        print_tool_install_path_detail "${tool}" || true
    done
}

parse_build_id_from_ffmpeg_version() {
    local text="$1"
    if [[ "${text}" =~ ffmpeg-git-([0-9]{8}) ]]; then
        INSTALLED_BUILD_KIND="date"
        INSTALLED_BUILD_SOURCE="${INSTALLED_BUILD_SOURCE:-localbin}"
        echo "${BASH_REMATCH[1]}"
        return 0
    fi
    if [[ "${text}" =~ ffmpeg-release-([0-9]{8}) ]]; then
        INSTALLED_BUILD_KIND="date"
        INSTALLED_BUILD_SOURCE="${INSTALLED_BUILD_SOURCE:-localbin}"
        echo "${BASH_REMATCH[1]}"
        return 0
    fi
    # johnvansickle git static: ffmpeg/ffprobe/ffplay version N-123196-gba38fa206e-20260306
    if [[ "${text}" =~ ff(mpeg|probe|play)[[:space:]]+version[[:space:]]+(N-[0-9]+)-g[0-9a-fA-F]+-([0-9]{8}) ]]; then
        INSTALLED_GIT_REVISION="${BASH_REMATCH[2]}"
        INSTALLED_BUILD_SNAPSHOT_DATE="${BASH_REMATCH[3]}"
        INSTALLED_BUILD_SOURCE="${INSTALLED_BUILD_SOURCE:-localbin}"
        if semver="$(resolve_version_label_from_version_output "${text}" "${FFMPEG_ORG_VERSION:-}")"; then
            INSTALLED_BUILD_KIND="semver"
            echo "${semver}"
            return 0
        fi
        INSTALLED_BUILD_KIND="git"
        echo "${BASH_REMATCH[2]}"
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
    INSTALLED_BUILD_SNAPSHOT_DATE=""
    INSTALLED_GIT_REVISION=""
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
            elif [[ "${out}" =~ ffmpeg[[:space:]]+version[[:space:]]+(N-[0-9]+)-g[0-9a-fA-F]+-([0-9]{8}) ]]; then
                INSTALLED_GIT_REVISION="${BASH_REMATCH[1]}"
                INSTALLED_BUILD_SNAPSHOT_DATE="${BASH_REMATCH[2]}"
                INSTALLED_BUILD_SOURCE="localbin"
                if [[ "${INSTALLED_BUILD_KIND}" != semver ]]; then
                    INSTALLED_BUILD_KIND="git"
                fi
            fi
            if [[ "${exe}" =~ ^/usr/local/bin/ffmpeg-.+-static$ ]]; then
                INSTALLED_BUILD_SOURCE="localbin"
            fi
            if [[ "${exe}" == "${BIN_FFMPEG}" || "${exe}" == /usr/local/bin/ffmpeg ]]; then
                [[ "${INSTALLED_BUILD_KIND}" == date && -z "${INSTALLED_BUILD_SOURCE}" ]] && INSTALLED_BUILD_SOURCE="localbin"
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
        version_label_is_backup_aside "${label}" && continue
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
        version_label_is_backup_aside "${label}" && continue
        raw_labels+=("${label}")
    done
    ((${#raw_labels[@]} > 0)) || return 0

    while IFS= read -r label; do
        [[ -n "${label}" ]] && labels+=("${label}")
    done < <(printf '%s\n' "${raw_labels[@]}" | sort -V -u)

    echo "  Versioned binaries in ${BIN_DIR}/:"
    for label in "${labels[@]}"; do
        if [[ -n "${active}" && "${label}" == "${active}" ]]; then
            echo "    ffmpeg-${label}  ffprobe-${label}  ffplay-${label}  (active)"
        else
            echo "    ffmpeg-${label}  ffprobe-${label}  ffplay-${label}"
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

prompt_reply_is_no() {
    case "${1}" in
        n|N|no|NO) return 0 ;;
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
    print_installed_tool_binary_paths
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
        echo "  Source build:      ffmpeg.org ${FFMPEG_ORG_VERSION} (profiles: min/common/max/gpu/nvidia/jellyfin)"
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
        echo "  ffmpeg-${label}  ffprobe-${label}  ffplay-${label}"
    done
    echo

    if (( ASSUME_YES == 1 )); then
        log_note "Keeping old versioned binaries (--yes, no removal prompt)."
        return 0
    fi

    for label in "${old_labels[@]}"; do
        vffmpeg="${BIN_DIR}/ffmpeg-${label}"
        vffprobe="${BIN_DIR}/ffprobe-${label}"
        vffplay="${BIN_DIR}/ffplay-${label}"

        echo ">>> Waiting for your answer:"
        echo -n "Remove ffmpeg-${label}, ffprobe-${label}, ffplay-${label}? [y/N/q] "
        read -r -n 1 reply || reply=""
        echo
        if prompt_reply_is_yes "${reply}"; then
            log_step "Removing ffmpeg-${label}, ffprobe-${label}, ffplay-${label}"
            remove_versioned_ffmpeg_set "${label}"
        elif prompt_reply_is_quit "${reply}"; then
            log_note "Quitting — keeping remaining old versions."
            return 0
        else
            log_note "Keeping ffmpeg-${label}."
        fi
    done
}

quit_script() {
    print_local_bin_ffmpeg_summary
    exit 0
}

quit_prompt_with_optional_old_cleanup() {
    quit_script
}

build_id_is_known() {
    build_id_is_date "${1}" || build_id_is_semver "${1}" || build_id_is_git_revision "${1}"
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

prompt_install_source_build_default() {
    local reply=""

    if (( STATIC_ONLY == 1 || DYNAMIC_ONLY == 1 )); then
        return 1
    fi
    if ! ensure_ffmpeg_org_release_version; then
        log_note "Official ffmpeg.org release unknown; skipping default source build prompt."
        return 1
    fi

    if (( ASSUME_YES == 1 )); then
        INSTALL_PLAN="source"
        if [[ -z "${SOURCE_PROFILE}" && -z "${CLI_SOURCE_PROFILE}" && -z "${FFMPEG_SOURCE_PROFILE}" ]]; then
            SOURCE_PROFILE=common
        fi
        ensure_source_build_profile_selected
        echo "Proceeding with official source build (profile: ${SOURCE_PROFILE}, --yes)."
        return 0
    fi

    echo
    echo "Default: compile ffmpeg ${FFMPEG_ORG_VERSION} from official source (common profile)."
    echo "  Includes libmp3lame, x264, x265, opus, aom, openssl, and other common codecs."
    echo "  Prebuilt static builds (johnvansickle.com) usually lack external encoders such as MP3."
    echo ">>> Waiting for your answer:"
    echo -n "Build from official source (common profile)? [Y/n/q] "
    read -r -n 1 reply || reply=""
    echo
    if prompt_reply_is_quit "${reply}"; then
        echo "Quitting — no changes made."
        quit_prompt_with_optional_old_cleanup
    fi
    if prompt_reply_is_no "${reply}"; then
        return 1
    fi
    INSTALL_PLAN="source"
    if [[ -z "${SOURCE_PROFILE}" && -z "${CLI_SOURCE_PROFILE}" && -z "${FFMPEG_SOURCE_PROFILE}" ]]; then
        SOURCE_PROFILE=common
    fi
    ensure_source_build_profile_selected
    echo "Proceeding with official source build (profile: ${SOURCE_PROFILE})..."
    return 0
}

prompt_install_static_optional() {
    local reply="" static_version=""

    if (( STATIC_TARBALL_AVAILABLE != 1 )); then
        echo "Static build is not available for this architecture."
        return 1
    fi

    static_version="$(planned_static_install_version || true)"
    echo ">>> Waiting for your answer:"
    if [[ -n "${static_version}" ]]; then
        echo -n "Install prebuilt static ffmpeg ${static_version} instead (fewer codecs)? [y/N/q] "
    else
        echo -n "Install prebuilt static ffmpeg instead (fewer codecs)? [y/N/q] "
    fi
    read -r -n 1 reply || reply=""
    echo
    if prompt_reply_is_yes "${reply}"; then
        INSTALL_PLAN="static"
        echo "Proceeding with static install..."
        return 0
    fi
    if prompt_reply_is_quit "${reply}"; then
        echo "Quitting — no changes made."
        quit_prompt_with_optional_old_cleanup
    fi
    return 1
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
        if ! ensure_ffmpeg_org_release_version; then
            echo "ERROR: Could not determine an official ffmpeg.org release version to build." >&2
            quit_prompt_with_optional_old_cleanup
        fi
        INSTALL_PLAN="source"
        ensure_source_build_profile_selected
        echo "Proceeding with official source build (profile: ${SOURCE_PROFILE}, --source-only)."
        return 0
    fi

    if (( DYNAMIC_ONLY == 1 )); then
        if (( ASSUME_YES == 1 )); then
            INSTALL_PLAN="dynamic"
            echo "Proceeding with dynamic apt install (--yes)."
            return 0
        fi
        prompt_install_dynamic_fallback
        return 0
    fi

    if (( STATIC_ONLY == 1 )); then
        if (( ASSUME_YES == 1 )); then
            INSTALL_PLAN="static"
            echo "Proceeding with static install (--yes)."
            return 0
        fi
        prompt_install_static_optional || true
        if [[ -n "${INSTALL_PLAN}" ]]; then
            return 0
        fi
        echo "Quitting — no changes made."
        quit_prompt_with_optional_old_cleanup
    fi

    if prompt_install_source_build_default; then
        return 0
    fi

    prompt_install_static_optional || true
    if [[ -n "${INSTALL_PLAN}" ]]; then
        return 0
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

ensure_active_tool_symlink() {
    local tool="$1" label="$2"
    local path="${BIN_DIR}/${tool}" versioned="${BIN_DIR}/${tool}-${label}"

    [[ -e "${versioned}" ]] || return 1
    if [[ -e "${path}" && ! -L "${path}" ]]; then
        move_path_aside "${path}"
    fi
    ln -sfn "${tool}-${label}" "${path}"
    return 0
}

link_active_ffmpeg_tools() {
    local label="$1"
    local tool="" linked=()

    log_step "Pointing active symlinks to *-${label} (ffmpeg, ffprobe, ffplay)"
    for tool in "${FFMPEG_ACTIVE_TOOLS[@]}"; do
        if ensure_active_tool_symlink "${tool}" "${label}"; then
            linked+=( "${BIN_DIR}/${tool}" )
        fi
    done
    ((${#linked[@]} > 0)) && ls -l "${linked[@]}"
}

install_versioned_bins_to_local() {
    local build_id="$1"
    local ffmpeg_src="$2"
    local ffprobe_src="${3:-}"
    local ffplay_src="${4:-}"
    local label="" vffmpeg="" vffprobe="" vffplay=""

    need_cmd install
    label="$(version_label_from_build_id "${build_id}")"
    vffmpeg="$(versioned_ffmpeg_bin "${build_id}")"
    vffprobe="$(versioned_ffprobe_bin "${build_id}")"
    vffplay="$(versioned_ffplay_bin "${build_id}")"

    if [[ -e "${vffmpeg}" ]]; then
        move_path_aside "${vffmpeg}"
    fi
    if [[ -n "${ffprobe_src}" && -e "${vffprobe}" ]]; then
        move_path_aside "${vffprobe}"
    fi
    if [[ -n "${ffplay_src}" && -e "${vffplay}" ]]; then
        move_path_aside "${vffplay}"
    fi

    log_step "Installing into ${BIN_DIR}: ffmpeg-${label}, ffprobe-${label}${ffplay_src:+, ffplay-${label}}"
    install -m 755 "${ffmpeg_src}" "${vffmpeg}"
    if [[ -n "${ffprobe_src}" && -e "${ffprobe_src}" ]]; then
        install -m 755 "${ffprobe_src}" "${vffprobe}"
    fi
    if [[ -n "${ffplay_src}" && -e "${ffplay_src}" ]]; then
        install -m 755 "${ffplay_src}" "${vffplay}"
    fi
    chown root:root "${vffmpeg}"
    [[ -e "${vffprobe}" ]] && chown root:root "${vffprobe}"
    [[ -e "${vffplay}" ]] && chown root:root "${vffplay}"

    link_active_ffmpeg_tools "${label}"
}

install_versioned_symlinks_to_local() {
    local build_id="$1"
    local ffmpeg_src="$2"
    local ffprobe_src="${3:-}"
    local ffplay_src="${4:-}"
    local label="" vffmpeg="" vffprobe="" vffplay=""

    label="$(version_label_from_build_id "${build_id}")"
    vffmpeg="$(versioned_ffmpeg_bin "${build_id}")"
    vffprobe="$(versioned_ffprobe_bin "${build_id}")"
    vffplay="$(versioned_ffplay_bin "${build_id}")"

    if [[ -e "${vffmpeg}" ]]; then
        move_path_aside "${vffmpeg}"
    fi
    if [[ -n "${ffprobe_src}" && -e "${vffprobe}" ]]; then
        move_path_aside "${vffprobe}"
    fi
    if [[ -n "${ffplay_src}" && -e "${vffplay}" ]]; then
        move_path_aside "${vffplay}"
    fi

    log_step "Installing into ${BIN_DIR}: ffmpeg-${label} -> ${ffmpeg_src}"
    ln -sfn "${ffmpeg_src}" "${vffmpeg}"
    if [[ -n "${ffprobe_src}" && -e "${ffprobe_src}" ]]; then
        ln -sfn "${ffprobe_src}" "${vffprobe}"
    fi
    if [[ -n "${ffplay_src}" && -e "${ffplay_src}" ]]; then
        ln -sfn "${ffplay_src}" "${vffplay}"
    fi

    link_active_ffmpeg_tools "${label}"
}

source_profile_is_valid() {
    case "${1}" in
        min|common|max|gpu|nvidia|jellyfin) return 0 ;;
        *) return 1 ;;
    esac
}

source_profile_preset_externally() {
    [[ -n "${CLI_SOURCE_PROFILE}" || -n "${FFMPEG_SOURCE_PROFILE}" ]]
}

source_profile_label() {
    case "${SOURCE_PROFILE}" in
        min) echo "minimal static (openssl, libmp3lame, x264, opus)" ;;
        common) echo "common static (recommended codec set)" ;;
        max) echo "max static (common + extra codecs)" ;;
        gpu) echo "GPU/VAAPI (shared libs, Intel/AMD)" ;;
        nvidia) echo "NVIDIA NVENC/CUDA (shared libs, non-free)" ;;
        jellyfin) echo "Jellyfin-like shared (VAAPI+NVENC+FDK-AAC, non-free)" ;;
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

# Ubuntu 24.04+ uses libopenjp2-7-dev; older releases used libopenjpeg-dev.
apt_resolve_openjpeg_dev_package() {
    local pkg=""
    for pkg in libopenjpeg-dev libopenjp2-7-dev; do
        if apt_cache_has_package "${pkg}"; then
            printf '%s' "${pkg}"
            return 0
        fi
    done
    return 1
}

apt_install_openjpeg_dev_if_available() {
    local pkg=""
    if pkg="$(apt_resolve_openjpeg_dev_package)"; then
        apt_install_packages "${pkg}"
        return 0
    fi
    log_note "OpenJPEG dev not in apt (tried libopenjpeg-dev, libopenjp2-7-dev); libopenjpeg will be skipped."
    return 0
}

apt_install_packages() {
    local pkg=""
    local -a packages=()
    for pkg in "$@"; do
        [[ -n "${pkg}" ]] && packages+=( "${pkg}" )
    done
    ((${#packages[@]} > 0)) || return 0
    apt-get install -y "${packages[@]}"
}

apt_install_optional_packages() {
    local pkg=""
    local -a present=()
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
        FFMPEG_SOURCE_WITH_FDK_AAC=1
        return 0
    fi
    echo
    echo "max profile: optional libfdk-aac (non-free license, best AAC quality)."
    echo ">>> Waiting for your answer:"
    echo -n "Include libfdk-aac in this build? [Y/n/q] "
    read -r -n 1 reply || reply=""
    echo
    if prompt_reply_is_quit "${reply}"; then
        echo "Quitting — no changes made."
        quit_prompt_with_optional_old_cleanup
    fi
    if prompt_reply_is_no "${reply}"; then
        FFMPEG_SOURCE_WITH_FDK_AAC=0
    else
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
        jellyfin)
            echo
            echo "jellyfin profile builds a shared ffmpeg similar to Jellyfin's bundled ffmpeg:"
            echo "  VAAPI + NVENC + FDK-AAC + many codecs (non-free; long compile)."
            echo "  Optional GPU libraries are enabled when dev packages are present."
            if ! gpu_vaapi_runtime_looks_available && ! nvidia_runtime_looks_available; then
                echo "WARNING: no VAAPI or NVIDIA GPU detected; hardware encode may be unusable." >&2
            fi
            ;;
        *) return 0 ;;
    esac
    if (( ASSUME_YES == 1 )); then
        log_note "Continuing with ${SOURCE_PROFILE} profile (--yes)."
        return 0
    fi
    echo ">>> Waiting for your answer:"
    if [[ "${SOURCE_PROFILE}" == jellyfin ]]; then
        echo -n "Continue with jellyfin profile? [Y/n/q] "
    else
        echo -n "Continue with ${SOURCE_PROFILE} profile? [y/N/q] "
    fi
    read -r -n 1 reply || reply=""
    echo
    if prompt_reply_is_quit "${reply}"; then
        echo "Quitting — no changes made."
        quit_prompt_with_optional_old_cleanup
    fi
    if [[ "${SOURCE_PROFILE}" == jellyfin ]]; then
        if prompt_reply_is_no "${reply}"; then
            return 1
        fi
        return 0
    fi
    prompt_reply_is_yes "${reply}"
}

prompt_source_build_profile_menu() {
    local reply=""

    while true; do
        echo
        echo "Source build profile:"
        echo "  [1] common   — libmp3lame, x264, openssl, aom, … (default)"
        echo "  [2] min      — smaller/faster static build"
        echo "  [3] max      — common + extra codecs (optional libfdk-aac)"
        echo "  [4] gpu      — common + VAAPI (Intel/AMD; shared libs)"
        echo "  [5] nvidia   — common + NVENC/CUDA (NVIDIA; shared libs)"
        echo "  [6] jellyfin — Jellyfin-like shared build (VAAPI+NVENC+FDK-AAC)"
        echo "  [Q] Quit"
        echo ">>> Waiting for your answer:"
        echo -n "Choice [1/2/3/4/5/6/q] (Enter=common): "
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
            6|j|J) SOURCE_PROFILE=jellyfin; break ;;
            1|c|C|y|Y|"") SOURCE_PROFILE=common; break ;;
            *)
                echo "Unknown choice; try again."
                ;;
        esac
    done
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
    if [[ "${SOURCE_PROFILE}" == gpu || "${SOURCE_PROFILE}" == nvidia || "${SOURCE_PROFILE}" == jellyfin ]]; then
        if source_profile_preset_externally || (( ASSUME_YES == 1 )); then
            :
        elif ! prompt_confirm_gpu_or_nvidia_profile; then
            prompt_source_build_profile_menu
        fi
    fi
    log_note "Source build profile: ${SOURCE_PROFILE} ($(source_profile_label))"
    FFMPEG_SOURCE_PROFILE_READY=1
}

ffmpeg_source_static_build() {
    case "${SOURCE_PROFILE}" in
        gpu|nvidia|jellyfin) return 1 ;;
        *) return 0 ;;
    esac
}

ffmpeg_pkg_config_satisfied() {
    local spec="$1"

    if ffmpeg_source_static_build; then
        pkg-config --static --exists "${spec}" 2>/dev/null
    else
        pkg-config --exists "${spec}" 2>/dev/null
    fi
}

# FFmpeg 8.x configure: vulkan >= 1.3.277 (VK_HEADER_VERSION >= 277) and glslangValidator on PATH.
ffmpeg_source_vulkan_core_header_path() {
    local hdr=""
    for hdr in /usr/include/vulkan/vulkan_core.h /usr/local/include/vulkan/vulkan_core.h; do
        [[ -f "${hdr}" ]] || continue
        printf '%s\n' "${hdr}"
        return 0
    done
    return 1
}

ffmpeg_source_vulkan_cpp_flags() {
    pkg-config --cflags vulkan 2>/dev/null || true
}

ffmpeg_source_vulkan_header_version() {
    local hdr="" ver=""

    if hdr="$(ffmpeg_source_vulkan_core_header_path)"; then
        ver="$(awk '/^#define VK_HEADER_VERSION / { gsub(/[^0-9]/, "", $3); print $3; exit }' "${hdr}")"
        if [[ -n "${ver}" ]]; then
            printf '%s\n' "${ver}"
            return 0
        fi
    fi

    local cc="${CC:-gcc}" cflags=""
    cflags="$(ffmpeg_source_vulkan_cpp_flags)"
    # shellcheck disable=SC2086
    ver="$(printf '%s\n' '#include <vulkan/vulkan.h>' \
        | ${cc} ${cflags} -x c -E -dM - 2>/dev/null \
        | awk '/^#define VK_HEADER_VERSION / { gsub(/[^0-9]/, "", $3); print $3; exit }')"
    [[ -n "${ver}" ]] && printf '%s\n' "${ver}"
}

ffmpeg_source_vulkan_headers_cpp_ok() {
    local cc="${CC:-gcc}" cflags=""
    cflags="$(ffmpeg_source_vulkan_cpp_flags)"
    # shellcheck disable=SC2086
    printf '%s\n' \
        '#include <vulkan/vulkan.h>' \
        '#if !(defined(VK_VERSION_1_4) || (defined(VK_VERSION_1_3) && VK_HEADER_VERSION >= 277))' \
        '#error vulkan headers too old for ffmpeg 8.x' \
        '#endif' \
        | ${cc} ${cflags} -x c -E - >/dev/null 2>&1
}

ffmpeg_source_vulkan_pkg_ok() {
    if ffmpeg_source_static_build; then
        pkg-config --static --atleast-version=1.3.277 vulkan 2>/dev/null
    else
        pkg-config --atleast-version=1.3.277 vulkan 2>/dev/null
    fi
}

ffmpeg_source_vulkan_headers_acceptable() {
    local hdr="" hdr_ver=""

    hdr_ver="$(ffmpeg_source_vulkan_header_version)"
    if [[ -n "${hdr_ver}" && "${hdr_ver}" -ge 277 ]]; then
        return 0
    fi
    if hdr="$(ffmpeg_source_vulkan_core_header_path)"; then
        if grep -q '^#define VK_VERSION_1_4 ' "${hdr}" 2>/dev/null; then
            return 0
        fi
    fi
    ffmpeg_source_vulkan_headers_cpp_ok
}

ffmpeg_source_patch_vulkan_pkg_config_version() {
    local ver="${1:-1.3.283}"
    local pc=""
    local patched=0

    while IFS= read -r pc; do
        [[ -f "${pc}" && -w "${pc}" ]] || continue
        sed -i "s/^Version:.*/Version: ${ver}/" "${pc}"
        patched=1
    done < <(find /usr/lib /usr/local/lib /usr/share -name 'vulkan.pc' 2>/dev/null)

    if (( patched == 0 )); then
        log_note "vulkan.pc not found for pkg-config version patch (headers still upgraded)."
    fi
}

install_vulkan_headers_from_git() {
    local tag="vulkan-sdk-1.3.283.0"
    local pc_version="1.3.283"
    local build_dir=""
    local hdr_ver=""

    if ffmpeg_source_vulkan_headers_acceptable && ffmpeg_source_vulkan_pkg_ok; then
        return 0
    fi
    if (( FFMPEG_VULKAN_HEADERS_UPGRADE_ATTEMPTED == 1 )); then
        return 1
    fi
    FFMPEG_VULKAN_HEADERS_UPGRADE_ATTEMPTED=1

    need_cmd git
    need_cmd install
    build_dir="$(mktemp -d "${TEMP_CATALOG}/vulkan-headers.XXXXXX")"
    log_step "Installing Vulkan-Headers ${pc_version} from Khronos git (FFmpeg 8.x needs >= 1.3.277; Ubuntu 24.04 ships 1.3.275)..."

    if ! git clone --depth 1 --branch "${tag}" https://github.com/KhronosGroup/Vulkan-Headers.git "${build_dir}/Vulkan-Headers"; then
        log_note "Vulkan-Headers clone failed; vulkan/shaderc/libplacebo will be skipped."
        rm -rf "${build_dir}"
        return 1
    fi

    install -d /usr/include/vulkan
    cp -a "${build_dir}/Vulkan-Headers/include/vulkan/." /usr/include/vulkan/
    ffmpeg_source_patch_vulkan_pkg_config_version "${pc_version}"
    rm -rf "${build_dir}"

    hdr_ver="$(ffmpeg_source_vulkan_header_version)"
    if ffmpeg_source_vulkan_headers_acceptable; then
        log_note "Vulkan-Headers ${pc_version} installed under /usr/include/vulkan (VK_HEADER_VERSION=${hdr_ver:-unknown})."
        return 0
    fi
    log_note "Vulkan-Headers install did not satisfy FFmpeg 8.x header requirement (VK_HEADER_VERSION=${hdr_ver:-unknown})."
    return 1
}

ffmpeg_source_vulkan_configure_ready() {
    ffmpeg_source_vulkan_headers_acceptable || return 1
    ffmpeg_source_vulkan_pkg_ok || return 1
    command -v glslangValidator >/dev/null 2>&1 || return 1
    return 0
}

ffmpeg_source_log_vulkan_probe_status() {
    local hdr_ver=""

    if command -v glslangValidator >/dev/null 2>&1; then
        log_note "glslangValidator: $(command -v glslangValidator)"
    else
        log_note "glslangValidator not found."
    fi
    if pkg-config --exists vulkan 2>/dev/null; then
        log_note "vulkan pkg-config: $(pkg-config --modversion vulkan 2>/dev/null)"
        hdr_ver="$(ffmpeg_source_vulkan_header_version)"
        if [[ -n "${hdr_ver}" ]]; then
            log_note "VK_HEADER_VERSION: ${hdr_ver}"
        fi
    else
        log_note "vulkan not visible to pkg-config."
    fi
    if ffmpeg_source_vulkan_configure_ready; then
        log_note "Vulkan: ready for FFmpeg configure."
    elif ! ffmpeg_source_vulkan_headers_acceptable; then
        hdr_ver="$(ffmpeg_source_vulkan_header_version)"
        if [[ -n "${hdr_ver}" ]]; then
            log_note "Vulkan headers too old for FFmpeg 8.x (VK_HEADER_VERSION=${hdr_ver}; need >= 277 with VK_VERSION_1_3, or VK_VERSION_1_4)."
        else
            log_note "Vulkan headers do not meet FFmpeg 8.x requirement (vulkan >= 1.3.277)."
        fi
    elif ! ffmpeg_source_vulkan_pkg_ok; then
        log_note "Vulkan blocked — vulkan pkg-config below 1.3.277."
    elif ! command -v glslangValidator >/dev/null 2>&1; then
        log_note "Vulkan blocked — glslangValidator missing (install glslang-tools)."
    fi
}

ffmpeg_source_ensure_vulkan_build_deps() {
    case "${SOURCE_PROFILE}" in
        gpu|jellyfin) ;;
        *) return 0 ;;
    esac

    log_step "Ensuring Vulkan build dependencies (libvulkan-dev, glslang-tools, libglslang-dev)..."
    apt_install_optional_packages libvulkan-dev glslang-tools libglslang-dev

    if ! ffmpeg_source_vulkan_headers_acceptable || ! ffmpeg_source_vulkan_pkg_ok; then
        install_vulkan_headers_from_git || true
    fi

    if [[ "${SOURCE_PROFILE}" == jellyfin ]]; then
        apt_install_optional_packages libshaderc-dev libplacebo-dev
    fi

    ffmpeg_source_log_vulkan_probe_status
}

ffmpeg_source_try_enable_vulkan() {
    local args_var="$1"
    local -n _args="$args_var"
    local hdr_ver=""

    if (( FFMPEG_SOURCE_SKIP_VULKAN == 1 )); then
        return 0
    fi

    if ffmpeg_source_vulkan_configure_ready; then
        _args+=( --enable-vulkan )
        return 0
    fi
    if ! ffmpeg_pkg_config_satisfied vulkan; then
        log_note "vulkan disabled — vulkan not found via pkg-config."
        return 0
    fi
    if ! ffmpeg_source_vulkan_headers_acceptable; then
        hdr_ver="$(ffmpeg_source_vulkan_header_version)"
        if [[ -n "${hdr_ver}" ]]; then
            log_note "vulkan disabled — Vulkan headers too old (VK_HEADER_VERSION=${hdr_ver}; FFmpeg 8.x needs >= 277 with VK_VERSION_1_3, or VK_VERSION_1_4)."
        else
            log_note "vulkan disabled — Vulkan headers do not meet FFmpeg 8.x requirement (vulkan >= 1.3.277)."
        fi
        return 0
    fi
    if ! ffmpeg_source_vulkan_pkg_ok; then
        log_note "vulkan disabled — vulkan pkg-config below 1.3.277 (Khronos header upgrade may have failed)."
        return 0
    fi
    log_note "vulkan disabled — glslangValidator not found after apt install (glslang-tools may be unavailable in apt)."
    return 0
}

ffmpeg_source_try_enable_pkg() {
    local args_var="$1"
    local pkg_spec="$2"
    local flag="$3"
    local label="${4:-${flag#--enable-}}"
    local -n _args="$args_var"

    if ffmpeg_pkg_config_satisfied "${pkg_spec}"; then
        _args+=( "${flag}" )
        return 0
    fi
    if pkg-config --exists "${pkg_spec}" 2>/dev/null; then
        log_note "${label} disabled — installed but not available to pkg-config for this build (${pkg_spec})."
    else
        log_note "${label} disabled — ${pkg_spec} not found via pkg-config."
    fi
    return 0
}

ffmpeg_source_try_enable_openssl() {
    local args_var="$1"
    local -n _args="$args_var"

    if ffmpeg_pkg_config_satisfied 'openssl >= 3.0.0'; then
        _args+=( --enable-openssl )
    elif ffmpeg_pkg_config_satisfied openssl; then
        _args+=( --enable-openssl )
    else
        log_note "openssl disabled — not found via pkg-config."
    fi
}

probe_source_optional_codecs() {
    FFMPEG_SOURCE_HAS_DAV1D=0
    if ffmpeg_pkg_config_satisfied 'dav1d >= 1.0.0'; then
        FFMPEG_SOURCE_HAS_DAV1D=1
    elif pkg-config --exists dav1d 2>/dev/null; then
        log_note "dav1d $(pkg-config --modversion dav1d 2>/dev/null) is below 1.0.0 (FFmpeg 8.x needs dav1d >= 1.0.0); libdav1d disabled — libaom still provides AV1."
    elif apt_cache_has_package libdav1d-dev; then
        log_note "libdav1d-dev is installed but dav1d >= 1.0.0 is not visible to pkg-config; libdav1d disabled — libaom still provides AV1."
    else
        log_note "dav1d not available; libdav1d disabled — libaom still provides AV1."
    fi

    FFMPEG_SOURCE_HAS_SVTAV1=0
    case "${SOURCE_PROFILE}" in
        max|common|gpu|nvidia|jellyfin)
            if ffmpeg_pkg_config_satisfied 'SvtAv1Enc >= 0.9.0'; then
                FFMPEG_SOURCE_HAS_SVTAV1=1
            elif pkg-config --exists 'SvtAv1Enc >= 0.9.0' 2>/dev/null; then
                log_note "SvtAv1Enc >= 0.9.0 is installed but not available for static linking; libsvtav1 disabled."
            elif pkg-config --exists SvtAv1Enc 2>/dev/null; then
                log_note "SvtAv1Enc $(pkg-config --modversion SvtAv1Enc 2>/dev/null) is below 0.9.0 (FFmpeg 8.x needs SvtAv1Enc >= 0.9.0); libsvtav1 disabled."
            elif apt_cache_has_package libsvtav1-dev; then
                log_note "libsvtav1-dev is installed but SvtAv1Enc >= 0.9.0 is not visible to pkg-config; libsvtav1 disabled."
            else
                log_note "SvtAv1Enc not available; libsvtav1 disabled."
            fi
            ;;
    esac
}

ffmpeg_source_ffnvcodec_headers_present() {
    local prefix="${1:-/usr/local}"

    [[ -f "${prefix}/include/ffnvcodec/nvEncodeAPI.h" ]] \
        || [[ -f /usr/include/ffnvcodec/nvEncodeAPI.h ]]
}

ffmpeg_source_jellyfin_add_cuda_args() {
    local -n _args=$1

    if (( FFMPEG_SOURCE_WITH_CUDA_NVCC == 1 )) && (( FFMPEG_SOURCE_SKIP_CUDA_NVCC == 0 )) \
        && command -v nvcc >/dev/null 2>&1; then
        _args+=( --enable-cuda-nvcc )
        ffmpeg_source_try_enable_pkg _args libnpp --enable-libnpp libnpp
        return 0
    fi

    # FFmpeg 8.x enables cuda with ffnvcodec; NVENC/NVDEC need no cuda-nvcc/cuda-llvm.
    # Do not pass --enable-cuda-llvm (needs clang CUDA and fails configure when absent).
    _args+=( --disable-cuda-llvm )
}

install_nv_codec_headers_from_git() {
    local prefix="${1:-/usr/local}"

    if ffmpeg_source_ffnvcodec_headers_present "${prefix}"; then
        return 0
    fi
    need_cmd git
    need_cmd make
    local build_dir=""
    build_dir="$(mktemp -d "${TEMP_CATALOG}/nv-codec-headers.XXXXXX")"
    log_step "Installing nv-codec-headers from git into ${prefix} (NVENC/NVDEC)..."
    if ! git clone --depth 1 https://github.com/FFmpeg/nv-codec-headers.git "${build_dir}/nv-codec-headers"; then
        log_note "nv-codec-headers clone failed; NVENC/NVDEC may be disabled."
        rm -rf "${build_dir}"
        return 1
    fi
    if ! make -C "${build_dir}/nv-codec-headers" install PREFIX="${prefix}"; then
        log_note "nv-codec-headers install failed."
        rm -rf "${build_dir}"
        return 1
    fi
    rm -rf "${build_dir}"
    log_note "nv-codec-headers installed under ${prefix}."
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
        common|max|gpu|nvidia|jellyfin)
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
        max|gpu|nvidia|jellyfin)
            apt_install_optional_packages \
                libbluray-dev libchromaprint-dev \
                libgme-dev libopenmpt-dev libvidstab-dev libxml2-dev libshine-dev
            apt_install_openjpeg_dev_if_available
            ;;
    esac

    case "${SOURCE_PROFILE}" in
        max|common|gpu|nvidia|jellyfin)
            if apt_cache_has_package libsvtav1-dev; then
                pkgs+=( libsvtav1-dev )
            else
                log_note "libsvtav1-dev not in apt; SVT-AV1 encoder will be skipped."
            fi
            ;;
    esac

    if [[ "${SOURCE_PROFILE}" == jellyfin ]]; then
        FFMPEG_SOURCE_HAS_FDK_AAC=0
        if apt_cache_has_package libfdk-aac-dev; then
            pkgs+=( libfdk-aac-dev )
            FFMPEG_SOURCE_HAS_FDK_AAC=1
        else
            echo "ERROR: jellyfin profile requires libfdk-aac-dev (non-free)." >&2
            return 1
        fi
        pkgs+=( libfribidi-dev libzvbi-dev libgnutls28-dev libgmp-dev )
        apt_install_optional_packages \
            ocl-icd-opencl-dev opencl-headers \
            libvpl-dev
    elif [[ "${SOURCE_PROFILE}" == max ]] && (( FFMPEG_SOURCE_WITH_FDK_AAC == 1 )); then
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

    if [[ "${SOURCE_PROFILE}" == gpu || "${SOURCE_PROFILE}" == jellyfin ]]; then
        apt_install_optional_packages libva-dev libvdpau-dev libdrm-dev
    fi

    if [[ "${SOURCE_PROFILE}" == nvidia || "${SOURCE_PROFILE}" == jellyfin ]]; then
        apt_install_optional_packages nvidia-cuda-toolkit libnpp-dev
        install_nv_codec_headers_from_git /usr/local || true
    fi

    log_step "Installing compiler and profile packages..."
    apt_install_packages "${pkgs[@]}"
    ffmpeg_source_ensure_vulkan_build_deps
    probe_source_optional_codecs
    need_cmd pkg-config
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

    if [[ "${SOURCE_PROFILE}" == gpu || "${SOURCE_PROFILE}" == nvidia || "${SOURCE_PROFILE}" == jellyfin ]]; then
        args+=( --enable-shared --disable-static )
        pkg_config_flags=""
        extra_libs="-lpthread -lm -ldl"
    else
        args+=( --enable-static --disable-shared )
    fi

    if [[ "${SOURCE_PROFILE}" == jellyfin ]]; then
        args+=(
            --disable-doc
            --disable-ffplay
            --disable-libxcb
            --disable-sdl2
            --disable-xlib
            --extra-version=Jellyfin
        )
        if (( FFMPEG_SOURCE_WITH_LTO == 1 )) && (( FFMPEG_SOURCE_DISABLE_LTO == 0 )); then
            args+=( --enable-lto=auto )
        fi
    fi

    args+=(
        --pkg-config-flags="${pkg_config_flags}"
        "--extra-libs=${extra_libs}"
    )

    case "${SOURCE_PROFILE}" in
        min)
            args+=( --enable-libmp3lame )
            ffmpeg_source_try_enable_pkg args x264 --enable-libx264 libx264
            ffmpeg_source_try_enable_pkg args opus --enable-libopus opus
            ;;
        common|max|gpu|nvidia|jellyfin)
            # lame/theora/twolame/soxr/snappy: ffmpeg configure uses header/link checks, not pkg-config
            args+=(
                --enable-libmp3lame
                --enable-libtheora
                --enable-libsoxr
                --enable-libsnappy
                --enable-libtwolame
            )
            ffmpeg_source_try_enable_pkg args x264 --enable-libx264 libx264
            ffmpeg_source_try_enable_pkg args x265 --enable-libx265 x265
            ffmpeg_source_try_enable_pkg args vpx --enable-libvpx vpx
            ffmpeg_source_try_enable_pkg args opus --enable-libopus opus
            ffmpeg_source_try_enable_pkg args vorbis --enable-libvorbis vorbis
            ffmpeg_source_try_enable_pkg args "libass >= 0.11.0" --enable-libass libass
            ffmpeg_source_try_enable_pkg args "aom >= 2.0.0" --enable-libaom libaom
            ffmpeg_source_try_enable_pkg args "libwebp >= 0.2.0" --enable-libwebp libwebp
            ffmpeg_source_try_enable_pkg args freetype2 --enable-libfreetype libfreetype
            ffmpeg_source_try_enable_pkg args fontconfig --enable-libfontconfig libfontconfig
            ffmpeg_source_try_enable_pkg args "zimg >= 2.7.0" --enable-libzimg libzimg
            ffmpeg_source_try_enable_pkg args speex --enable-libspeex libspeex
            ;;
    esac

    if [[ "${SOURCE_PROFILE}" != jellyfin ]]; then
        ffmpeg_source_try_enable_openssl args
    fi

    if (( FFMPEG_SOURCE_HAS_SVTAV1 == 1 )); then
        args+=( --enable-libsvtav1 )
    fi
    if (( FFMPEG_SOURCE_HAS_DAV1D == 1 )); then
        args+=( --enable-libdav1d )
    fi

    if [[ "${SOURCE_PROFILE}" == max || "${SOURCE_PROFILE}" == gpu || "${SOURCE_PROFILE}" == nvidia || "${SOURCE_PROFILE}" == jellyfin ]]; then
        ffmpeg_source_try_enable_pkg args "libopenjp2 >= 2.1.0" --enable-libopenjpeg libopenjpeg
        ffmpeg_source_try_enable_pkg args libbluray --enable-libbluray libbluray
        ffmpeg_source_try_enable_pkg args libchromaprint --enable-chromaprint chromaprint
        ffmpeg_source_try_enable_pkg args libgme --enable-libgme libgme
        ffmpeg_source_try_enable_pkg args "libopenmpt >= 0.2.6557" --enable-libopenmpt libopenmpt
        ffmpeg_source_try_enable_pkg args "vidstab >= 0.98" --enable-libvidstab libvidstab
        ffmpeg_source_try_enable_pkg args libxml-2.0 --enable-libxml2 libxml2
        ffmpeg_source_try_enable_pkg args shine --enable-libshine libshine
    fi

    if [[ "${SOURCE_PROFILE}" == max ]] && (( FFMPEG_SOURCE_HAS_FDK_AAC == 1 )); then
        local n_args_before=${#args[@]}
        ffmpeg_source_try_enable_pkg args fdk-aac --enable-libfdk-aac libfdk-aac
        if (( ${#args[@]} > n_args_before )); then
            args+=( --enable-nonfree )
        fi
    fi

    if [[ "${SOURCE_PROFILE}" == gpu ]]; then
        ffmpeg_source_try_enable_pkg args libva --enable-vaapi vaapi
        ffmpeg_source_try_enable_pkg args libdrm --enable-libdrm libdrm
        ffmpeg_source_try_enable_vulkan args
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

    if [[ "${SOURCE_PROFILE}" == jellyfin ]]; then
        args+=( --enable-nonfree )
        ffmpeg_source_try_enable_pkg args gnutls --enable-gnutls gnutls
        ffmpeg_source_try_enable_pkg args gmp --enable-gmp gmp
        ffmpeg_source_try_enable_pkg args harfbuzz --enable-libharfbuzz harfbuzz
        ffmpeg_source_try_enable_pkg args fribidi --enable-libfribidi fribidi
        ffmpeg_source_try_enable_pkg args zvbi --enable-libzvbi zvbi
        if pkg-config --exists OpenCL 2>/dev/null || [[ -f /usr/include/CL/cl.h ]]; then
            args+=( --enable-opencl )
        else
            log_note "opencl disabled — OpenCL headers not found."
        fi
        ffmpeg_source_try_enable_pkg args libva --enable-vaapi vaapi
        ffmpeg_source_try_enable_pkg args libdrm --enable-libdrm libdrm
        ffmpeg_source_try_enable_vulkan args
        if (( FFMPEG_SOURCE_SKIP_VULKAN == 1 )); then
            :
        elif ffmpeg_source_vulkan_configure_ready; then
            ffmpeg_source_try_enable_pkg args "shaderc >= 2019.1" --enable-libshaderc shaderc
            ffmpeg_source_try_enable_pkg args "libplacebo >= 5.229.0" --enable-libplacebo libplacebo
        else
            log_note "shaderc/libplacebo skipped — vulkan is not available for configure."
        fi
        ffmpeg_source_try_enable_pkg args amf --enable-amf amf
        ffmpeg_source_try_enable_pkg args vpl --enable-libvpl vpl
        if (( FFMPEG_SOURCE_HAS_FDK_AAC == 1 )); then
            ffmpeg_source_try_enable_pkg args fdk-aac --enable-libfdk-aac libfdk-aac
        fi
        args+=(
            --enable-ffnvcodec
            --enable-cuvid
            --enable-nvdec
            --enable-nvenc
        )
        ffmpeg_source_jellyfin_add_cuda_args args
    fi

    if [[ -n "${FFMPEG_CONFIGURE_EXTRA}" ]]; then
        read -r -a configure_extra <<< "${FFMPEG_CONFIGURE_EXTRA}"
        args+=( "${configure_extra[@]}" )
    fi
    if (( FFMPEG_SOURCE_SKIP_VULKAN == 1 )); then
        args+=(
            --disable-vulkan
            --disable-libshaderc
            --disable-libplacebo
        )
    fi
    printf '%s\n' "${args[@]}"
}

ffmpeg_source_configure_args_has_vulkan() {
    local -a args=("$@")
    local flag=""

    for flag in "${args[@]}"; do
        case "${flag}" in
            --enable-vulkan|--enable-libshaderc|--enable-libplacebo) return 0 ;;
        esac
    done
    return 1
}

ffmpeg_source_clean_configure_tree() {
    if [[ -f Makefile ]]; then
        make distclean >/dev/null 2>&1 || true
    fi
    rm -f Makefile config.mak config.h config.fate config.asm config_components.h mapfile 2>/dev/null || true
    rm -f ffbuild/config.mak ffbuild/.config ffbuild/config.sh 2>/dev/null || true
    rm -f ffbuild/config.* 2>/dev/null || true
}

ffmpeg_source_collect_configure_args() {
    local staging="$1"
    local args_var="$2"
    local -n _args="$args_var"
    local flag=""

    _args=()
    while IFS= read -r flag; do
        [[ -n "${flag}" ]] && _args+=( "${flag}" )
    done < <(ffmpeg_source_configure_args "${staging}")
}

ffmpeg_source_run_configure() {
    local staging="$1"
    local -a args=()

    ffmpeg_source_collect_configure_args "${staging}" args
    log_note "Configure flags: ${args[*]}"
    ./configure "${args[@]}" || return 1
    if [[ ! -f ffbuild/config.mak ]]; then
        echo "ERROR: configure did not create ffbuild/config.mak." >&2
        return 1
    fi
}

ffmpeg_source_clean_build_objects() {
    if [[ -f Makefile ]]; then
        make clean >/dev/null 2>&1 || true
    fi
}

ffmpeg_source_print_make_log_tail() {
    local log="$1"
    local lines="${2:-40}"

    [[ -f "${log}" ]] || return 0
    echo "  Last ${lines} lines of make log (${log}):" >&2
    tail -n "${lines}" "${log}" >&2 || true
    echo >&2
}

ffmpeg_source_reconfigure_and_make() {
    local staging="$1"
    local src_dir="$2"
    local jobs="$3"

    cd "${src_dir}"
    ffmpeg_source_clean_build_objects
    ffmpeg_source_clean_configure_tree
    if ! ffmpeg_source_run_configure "${staging}"; then
        echo "ERROR: ffmpeg configure failed during make retry (see ffbuild/config.log)." >&2
        return 1
    fi
    ffmpeg_source_run_make "${jobs}" "${src_dir}"
}

ffmpeg_source_retry_make_after_segfault() {
    local staging="$1"
    local src_dir="$2"
    local jobs="$3"
    local rc="$4"
    local log="$5"

    if (( FFMPEG_SOURCE_MAKE_RETRY_DONE == 1 )); then
        return 1
    fi
    [[ "${SOURCE_PROFILE}" == jellyfin ]] || return 1
    ffmpeg_source_make_rc_indicates_segfault "${rc}" "${log}" || return 1

    FFMPEG_SOURCE_MAKE_RETRY_DONE=1
    FFMPEG_SOURCE_DISABLE_LTO=1
    FFMPEG_SOURCE_WITH_LTO=0

    if (( FFMPEG_SOURCE_WITH_CUDA_NVCC == 1 )); then
        echo ">>> make segfault — reconfiguring jellyfin without cuda-nvcc..." >&2
    else
        echo ">>> make segfault — clean jellyfin rebuild..." >&2
    fi
    FFMPEG_SOURCE_SKIP_CUDA_NVCC=1
    FFMPEG_SOURCE_WITH_CUDA_NVCC=0
    ffmpeg_source_reconfigure_and_make "${staging}" "${src_dir}" "${jobs}"
}

ffmpeg_source_mem_available_mb() {
    awk '/^MemAvailable:/ { printf "%d", int($2 / 1024); exit }' /proc/meminfo 2>/dev/null
}

ffmpeg_source_raise_stack_limit() {
    local soft="" hard="" target_kb=65536 raised=0

    soft="$(ulimit -s 2>/dev/null || echo 8192)"
    hard="$(ulimit -Hs 2>/dev/null || echo unlimited)"

    if [[ "${soft}" == "unlimited" ]]; then
        return 0
    fi
    if [[ "${soft}" =~ ^[0-9]+$ ]] && (( soft >= target_kb )); then
        return 0
    fi

    if [[ "${hard}" == "unlimited" ]]; then
        ulimit -s unlimited 2>/dev/null && raised=1
        (( raised == 1 )) || ulimit -s "${target_kb}" 2>/dev/null && raised=1
    elif [[ "${hard}" =~ ^[0-9]+$ ]]; then
        if (( target_kb > hard )); then
            target_kb="${hard}"
        fi
        ulimit -s "${target_kb}" 2>/dev/null && raised=1
    fi

    if command -v prlimit >/dev/null 2>&1; then
        if [[ "${hard}" == "unlimited" ]]; then
            prlimit --stack=unlimited:unlimited --pid="$$" >/dev/null 2>&1 && raised=1
        else
            prlimit --stack="${target_kb}:${hard}" --pid="$$" >/dev/null 2>&1 && raised=1
        fi
    fi

    soft="$(ulimit -s 2>/dev/null || echo unknown)"
    if (( raised == 1 )); then
        echo "    Raised stack limit (ulimit -s=${soft}; FFmpeg make can overflow the default stack)." >&2
    fi
}

ffmpeg_source_raise_nofile_limit() {
    local force="${1:-0}"
    local soft="" hard="" target="" raised=0

    soft="$(ulimit -Sn 2>/dev/null || echo 1024)"
    hard="$(ulimit -Hn 2>/dev/null || echo "${soft}")"

    if [[ -n "${FFMPEG_MAKE_NOFILE}" && "${FFMPEG_MAKE_NOFILE}" =~ ^[0-9]+$ ]]; then
        target="${FFMPEG_MAKE_NOFILE}"
    elif [[ "${hard}" =~ ^[0-9]+$ ]]; then
        target="${hard}"
    elif [[ "${soft}" =~ ^[0-9]+$ ]]; then
        target=$(( soft * 3 ))
    else
        target=65536
    fi

    if [[ "${hard}" =~ ^[0-9]+$ ]] && (( target > hard )); then
        target="${hard}"
    fi
    if (( force == 0 )) && [[ "${soft}" =~ ^[0-9]+$ ]] && (( soft >= target )); then
        return 0
    fi

    if ulimit -n "${target}" 2>/dev/null; then
        raised=1
    fi
    if command -v prlimit >/dev/null 2>&1; then
        if [[ "${hard}" =~ ^[0-9]+$ ]]; then
            prlimit --nofile="${target}:${hard}" --pid="$$" >/dev/null 2>&1 && raised=1
        else
            prlimit --nofile="${target}:${target}" --pid="$$" >/dev/null 2>&1 && raised=1
        fi
    fi

    soft="$(ulimit -Sn 2>/dev/null || echo unknown)"
    if (( raised == 1 )); then
        echo "    Raised open-file limit (ulimit -n=${soft}, hard=${hard})." >&2
    fi
}

ffmpeg_source_count_open_fds() {
    local -a fds=()

    mapfile -t fds < <(ls -1 /proc/self/fd 2>/dev/null)
    echo "${#fds[@]}"
}

ffmpeg_source_invoke_make() {
    local jobs="$1"
    local src_dir="$2"
    local hard="" wrapper="" rc=0

    shift 2
    hard="$(ulimit -Hn 2>/dev/null || echo 1048576)"
    wrapper="$(mktemp "${TEMP_CATALOG}/ffmpeg-make-wrapper.XXXXXX.sh")"
    cat > "${wrapper}" <<EOF
#!/usr/bin/env bash
set -e
for fd in \$(ls /proc/self/fd 2>/dev/null); do
    [[ "\${fd}" =~ ^[0-9]+\$ ]] || continue
    (( fd > 2 )) || continue
    eval "exec \${fd}>&-" 2>/dev/null || true
done
ulimit -n ${hard} 2>/dev/null || true
ulimit -s unlimited 2>/dev/null || true
cd $(printf '%q' "${src_dir}")
exec make -j${jobs}$(printf ' %q' "$@")
EOF
    chmod +x "${wrapper}"
    if command -v prlimit >/dev/null 2>&1 && [[ "${hard}" =~ ^[0-9]+$ ]]; then
        prlimit --nofile="${hard}:${hard}" --stack=unlimited:unlimited -- "${wrapper}"
    else
        "${wrapper}"
    fi
    rc=$?
    rm -f "${wrapper}"
    return "${rc}"
}

ffmpeg_source_prepare_make_jobs() {
    local ncpu="" nofile="" hard="" jobs="" max_jobs="" mem_mb="" ram_jobs="" mb_per_job=2048 stack_kb=""

    ffmpeg_source_raise_stack_limit
    ffmpeg_source_raise_nofile_limit 0
    stack_kb="$(ulimit -s 2>/dev/null || echo unknown)"

    ncpu="$(nproc 2>/dev/null || echo 2)"
    nofile="$(ulimit -Sn 2>/dev/null || echo 1024)"
    hard="$(ulimit -Hn 2>/dev/null || echo "${nofile}")"

    jobs="${ncpu}"
    max_jobs=$(( nofile / 128 ))
    (( max_jobs < 1 )) && max_jobs=1
    if (( nofile <= 12288 && max_jobs > 12 )); then
        max_jobs=12
    fi
    if (( nofile <= 3072 )); then
        max_jobs=6
    fi
    if (( jobs > max_jobs )); then
        echo "    Limiting make -j${ncpu} to -j${max_jobs} (ulimit -n=${nofile}; FFmpeg needs many open files)." >&2
        jobs="${max_jobs}"
    fi

    if [[ "${SOURCE_PROFILE}" == jellyfin || "${SOURCE_PROFILE}" == gpu || "${SOURCE_PROFILE}" == nvidia ]]; then
        mb_per_job=3072
    fi
    mem_mb="$(ffmpeg_source_mem_available_mb)"
    if [[ -n "${mem_mb}" && "${mem_mb}" =~ ^[0-9]+$ ]]; then
        ram_jobs=$(( mem_mb / mb_per_job ))
        (( ram_jobs < 1 )) && ram_jobs=1
        if (( jobs > ram_jobs )); then
            echo "    Limiting make -j${ncpu} to -j${ram_jobs} (~${mem_mb} MiB MemAvailable; parallel FFmpeg builds are memory-heavy)." >&2
            jobs="${ram_jobs}"
        fi
    fi

    if (( jobs == ncpu )); then
        echo "    make -j${jobs} (ulimit -n=${nofile}, stack=${stack_kb})." >&2
    fi

    if [[ "${FFMPEG_MAKE_JOBS}" =~ ^[0-9]+$ ]] && (( FFMPEG_MAKE_JOBS > 0 )) && (( jobs > FFMPEG_MAKE_JOBS )); then
        echo "    Limiting make -j${jobs} to -j${FFMPEG_MAKE_JOBS} (FFMPEG_MAKE_JOBS default cap)." >&2
        jobs="${FFMPEG_MAKE_JOBS}"
    fi
    echo "    Shell open FDs: $(ffmpeg_source_count_open_fds), ulimit -n=${nofile} (make uses a clean subprocess)." >&2
    printf '%s\n' "${jobs}"
}

ffmpeg_source_make_log_indicates_emfile() {
    local log="$1"
    [[ -f "${log}" ]] || return 1
    grep -qiE 'too many open files|EMFILE' "${log}" 2>/dev/null
}

ffmpeg_source_print_too_many_open_files_help() {
    local jobs="${1:-?}"
    local src_dir="${2:-.}"
    local nofile="" soft="" hard="" suggested=""

    nofile="$(ulimit -n 2>/dev/null || echo unknown)"
    soft="$(ulimit -Sn 2>/dev/null || echo unknown)"
    hard="$(ulimit -Hn 2>/dev/null || echo unknown)"
    if [[ "${nofile}" =~ ^[0-9]+$ ]]; then
        suggested=$(( nofile * 3 ))
        if [[ "${hard}" =~ ^[0-9]+$ ]] && (( suggested > hard )); then
            suggested="${hard}"
        fi
    fi

    echo >&2
    echo "================================================================================" >&2
    echo "  Too many open files — increase ulimit (max open file descriptors)" >&2
    echo "================================================================================" >&2
    echo >&2
    echo "  FFmpeg make failed with EMFILE. Often the install script shell has thousands of" >&2
    echo "  inherited open files after apt/configure; raising ulimit alone does not close them." >&2
    echo >&2
    echo "  Current limits: soft=${soft}  hard=${hard}  (ulimit -n shows ${nofile})" >&2
    echo "  Open FDs in this shell: $(ffmpeg_source_count_open_fds 2>/dev/null || echo '?')" >&2
    if [[ "${soft}" =~ ^[0-9]+$ && "${hard}" =~ ^[0-9]+$ ]] && (( soft >= hard )); then
        echo "  Soft limit is at hard max; check: cat /proc/sys/fs/file-nr" >&2
        echo "  and set TEMP_CATALOG to a local ext4 path (not NFS/VMware share)." >&2
    fi
    echo >&2
    echo "  Quick fix (this shell only):" >&2
    if [[ "${hard}" =~ ^[0-9]+$ ]]; then
        echo "    ulimit -n ${hard}" >&2
    fi
    if [[ "${suggested}" =~ ^[0-9]+$ ]] && (( suggested > 0 )); then
        echo "    ulimit -n ${suggested}    # 3× current soft limit" >&2
    fi
    echo >&2
    echo "  Resume — use a fresh shell (do not reuse the script shell if FD count is high):" >&2
    echo "    cd ${src_dir}" >&2
    if [[ "${hard}" =~ ^[0-9]+$ ]]; then
        echo "    ulimit -s unlimited && ulimit -n ${hard}" >&2
    else
        echo "    ulimit -s unlimited && ulimit -n 65536" >&2
    fi
    echo "    make -j1 ffmpeg ffprobe && make -j1" >&2
    echo "    # or: ffmpeg-install.sh --source-profile jellyfin --source-only" >&2
    echo >&2
    echo "  Permanent fix — append to /etc/security/limits.conf (match hard to soft):" >&2
    if [[ "${hard}" =~ ^[0-9]+$ ]]; then
        echo "    root soft nofile ${hard}" >&2
        echo "    root hard nofile ${hard}" >&2
        echo "    * soft nofile ${hard}" >&2
        echo "    * hard nofile ${hard}" >&2
    else
        echo "    root soft nofile unlimited" >&2
        echo "    root hard nofile unlimited" >&2
    fi
    echo "  Log out and back in, then verify: ulimit -n" >&2
    echo >&2
    echo "  Optional system-wide (/etc/sysctl.conf or sysctl.d, then sysctl -p):" >&2
    echo "    fs.file-max = 2097152" >&2
    echo "================================================================================" >&2
    echo >&2
}

ffmpeg_source_make_log_indicates_segfault() {
    local log="$1"
    [[ -f "${log}" ]] || return 1
    grep -qiE 'segmentation fault|segfault|signal 11|core dumped|killed' "${log}" 2>/dev/null
}

ffmpeg_source_make_rc_indicates_segfault() {
    local rc="$1"
    local log="$2"
    if (( rc == 139 || rc == 134 )); then
        return 0
    fi
    ffmpeg_source_make_log_indicates_segfault "${log}"
}

ffmpeg_source_print_make_failure_help() {
    local jobs="$1"
    local src_dir="$2"
    local log="$3"
    local rc="$4"

    if ffmpeg_source_make_log_indicates_emfile "${log}"; then
        ffmpeg_source_print_too_many_open_files_help "${jobs}" "${src_dir}"
        return 0
    fi
    if ffmpeg_source_make_rc_indicates_segfault "${rc}" "${log}"; then
        ffmpeg_source_print_make_segfault_help "${jobs}" "${src_dir}"
        return 0
    fi
    return 1
}

ffmpeg_source_print_make_segfault_help() {
    local jobs="${1:-?}"
    local src_dir="${2:-.}"
    local mem_mb=""

    mem_mb="$(ffmpeg_source_mem_available_mb)"

    echo >&2
    echo "================================================================================" >&2
    echo "  make crashed (segmentation fault)" >&2
    echo "================================================================================" >&2
    echo >&2
    echo "  Common causes on jellyfin builds:" >&2
    echo "    - Stack overflow (most likely if dmesg shows make[PID] segfault in libc.so.6, error 6):" >&2
    echo "      default ulimit -s (~8 MiB) is too small for FFmpeg's recursive make" >&2
    echo "    - CUDA NVCC compile (--enable-cuda-nvcc): nvcc can segfault on VMware VMs" >&2
    echo "    - Link-time optimization (LTO): gcc/lld can segfault on large FFmpeg trees" >&2
    echo "    - Out of memory: parallel jobs (NVENC/CUDA) can use several GB per job" >&2
    echo >&2
    if [[ -n "${mem_mb}" ]]; then
        echo "  MemAvailable now: ~${mem_mb} MiB." >&2
        if (( mem_mb >= 8192 && jobs == 1 )); then
            echo "  With -j1 and plenty of RAM, check dmesg: make+libc error 6 => raise ulimit -s." >&2
        else
            echo "  Script targets ~3 GiB per job for jellyfin when capping parallelism." >&2
        fi
        echo >&2
    fi
    echo "  This script raises ulimit -s before make. Manual fix: ulimit -s unlimited" >&2
    echo "  Jellyfin skips cuda-nvcc/cuda-llvm by default (NVENC via ffnvcodec). Set FFMPEG_SOURCE_WITH_CUDA_NVCC=1 for CUDA filters." >&2
    echo "  LTO is off by default; set FFMPEG_SOURCE_WITH_LTO=1 to pass --enable-lto=auto." >&2
    echo "  On segfault the script retries once with a clean reconfigure." >&2
    echo >&2
    echo "  Manual resume in the build tree:" >&2
    echo "    cd ${src_dir}" >&2
    echo "    ulimit -s unlimited" >&2
    echo "    make -j1 ffmpeg ffprobe && make -j1" >&2
    echo "    # or re-run: ffmpeg-install.sh --source-profile jellyfin --source-only" >&2
    echo >&2
    echo "  Permanent stack fix — append to /etc/security/limits.conf:" >&2
    echo "    * soft stack unlimited" >&2
    echo "    * hard stack unlimited" >&2
    echo "    root soft stack unlimited" >&2
    echo "    root hard stack unlimited" >&2
    echo >&2
    echo "  If it still crashes:" >&2
    echo "    - Add swap (e.g. 8G): fallocate -l 8G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile" >&2
    echo "    - Give the VM more RAM in VMware settings" >&2
    echo "    - Check dmesg for OOM killer / compiler crash lines" >&2
    echo "================================================================================" >&2
    echo >&2
}

ffmpeg_source_retry_make_after_emfile() {
    local src_dir="$1"
    local jobs="$2"
    local log="$3"

    (( FFMPEG_SOURCE_MAKE_EMFILE_RETRY_DONE == 0 )) || return 1
    ffmpeg_source_make_log_indicates_emfile "${log}" || return 1

    FFMPEG_SOURCE_MAKE_EMFILE_RETRY_DONE=1
    echo ">>> make failed (too many open files) — raising ulimit -n to hard limit and retrying..." >&2
    ffmpeg_source_raise_nofile_limit 1
    cd "${src_dir}"
    ffmpeg_source_run_make "${jobs}" "${src_dir}"
}

ffmpeg_source_run_make() {
    local jobs="$1"
    local src_dir="$2"
    local log="" rc=0

    log="$(mktemp "${TEMP_CATALOG}/ffmpeg-make.XXXXXX.log")"
    ffmpeg_source_invoke_make "${jobs}" "${src_dir}" ffmpeg ffprobe 2>&1 | tee "${log}"
    rc=${PIPESTATUS[0]}
    FFMPEG_SOURCE_LAST_MAKE_RC="${rc}"
    FFMPEG_SOURCE_LAST_MAKE_LOG="${log}"
    if (( rc != 0 )); then
        ffmpeg_source_print_make_failure_help "${jobs}" "${src_dir}" "${log}" "${rc}" || true
        ffmpeg_source_print_make_log_tail "${log}" 40
        return "${rc}"
    fi

    ffmpeg_source_invoke_make "${jobs}" "${src_dir}" 2>&1 | tee -a "${log}"
    rc=${PIPESTATUS[0]}
    FFMPEG_SOURCE_LAST_MAKE_RC="${rc}"
    FFMPEG_SOURCE_LAST_MAKE_LOG="${log}"
    if (( rc != 0 )); then
        ffmpeg_source_print_make_failure_help "${jobs}" "${src_dir}" "${log}" "${rc}" || true
        ffmpeg_source_print_make_log_tail "${log}" 40
        return "${rc}"
    fi
    rm -f "${log}"
    FFMPEG_SOURCE_LAST_MAKE_LOG=""
    return 0
}

source_build_encoder_is_available() {
    local ffmpeg_exe="$1" encoder="$2"

    "${ffmpeg_exe}" -hide_banner -h "encoder=${encoder}" >/dev/null 2>&1
}

print_source_build_encoder_check() {
    local ffmpeg_exe="$1"
    local line="" found=0 pattern="" encoder="" encoders=()

    [[ -n "${ffmpeg_exe}" && -x "${ffmpeg_exe}" ]] || return 0

    case "${SOURCE_PROFILE}" in
        min) encoders=( libmp3lame libx264 libopus ) ;;
        max)
            if (( FFMPEG_SOURCE_HAS_FDK_AAC == 1 )); then
                encoders=( libmp3lame libx264 libfdk_aac libaom libsvtav1 )
            else
                encoders=( libmp3lame libx264 libopus libaom libsvtav1 libtwolame )
            fi
            ;;
        gpu) encoders=( libmp3lame libx264 h264_vaapi hevc_vaapi ) ;;
        nvidia) encoders=( libmp3lame libx264 h264_nvenc hevc_nvenc ) ;;
        jellyfin) encoders=( libmp3lame libx264 libfdk_aac h264_vaapi h264_nvenc libsvtav1 ) ;;
        *) encoders=( libmp3lame libx264 libopus libaom libsvtav1 libtwolame ) ;;
    esac
    pattern="$(IFS='|'; echo "${encoders[*]}")"

    echo
    echo "Sample encoders in built ffmpeg (profile: ${SOURCE_PROFILE}):"
    while IFS= read -r line; do
        [[ -n "${line}" ]] || continue
        echo "  ${line}"
        found=1
    done < <("${ffmpeg_exe}" -hide_banner -encoders 2>&1 | grep -E "${pattern}" || true)
    if (( found == 0 )); then
        for encoder in "${encoders[@]}"; do
            if source_build_encoder_is_available "${ffmpeg_exe}" "${encoder}"; then
                echo "  ${encoder} (via -h encoder=${encoder})"
                found=1
            fi
        done
    fi
    if (( found == 0 )); then
        echo "  WARNING: expected encoders not found (check configure log)." >&2
    fi
}

ffmpeg_source_resolve_staging_dir() {
    local work_dir="$1"
    local staging="${work_dir}/staging"

    mkdir -p "${staging}/bin"
    if command -v realpath >/dev/null 2>&1; then
        realpath "${staging}"
        return 0
    fi
    printf '%s/staging' "$(cd "${work_dir}" && pwd)"
}

# make install may only ship libraries when DESTDIR is set in the environment; copy from build tree if needed.
ffmpeg_source_ensure_staged_bins() {
    local staging="$1"
    local src_dir="$2"
    local destdir_path=""

    if [[ -x "${staging}/bin/ffmpeg" ]]; then
        return 0
    fi

    if [[ -n "${DESTDIR:-}" ]]; then
        destdir_path="${DESTDIR%/}${staging}/bin/ffmpeg"
        if [[ -x "${destdir_path}" ]]; then
            log_note "Found ffmpeg under DESTDIR (${destdir_path}); copying into staging prefix."
            install -m 755 "${destdir_path}" "${staging}/bin/ffmpeg"
            destdir_path="${DESTDIR%/}${staging}/bin/ffprobe"
            [[ -x "${destdir_path}" ]] && install -m 755 "${destdir_path}" "${staging}/bin/ffprobe"
            destdir_path="${DESTDIR%/}${staging}/bin/ffplay"
            [[ -x "${destdir_path}" ]] && install -m 755 "${destdir_path}" "${staging}/bin/ffplay"
            return 0
        fi
        log_note "DESTDIR=${DESTDIR} is set; make install may have skipped ${staging}/bin."
    fi

    if [[ -x "${src_dir}/ffmpeg" ]]; then
        log_note "Installing ffmpeg/ffprobe/ffplay from build tree into ${staging}/bin (make install left prefix/bin empty)."
        install -m 755 "${src_dir}/ffmpeg" "${staging}/bin/ffmpeg"
        [[ -x "${src_dir}/ffprobe" ]] && install -m 755 "${src_dir}/ffprobe" "${staging}/bin/ffprobe"
        [[ -x "${src_dir}/ffplay" ]] && install -m 755 "${src_dir}/ffplay" "${staging}/bin/ffplay"
        return 0
    fi

    return 1
}

ffmpeg_source_report_staging_failure() {
    local staging="$1"
    local src_dir="$2"

    echo "ERROR: staged ffmpeg binary not found: ${staging}/bin/ffmpeg" >&2
    if [[ -d "${staging}/bin" ]]; then
        echo "  Contents of ${staging}/bin:" >&2
        ls -la "${staging}/bin" 2>/dev/null >&2 || true
    else
        echo "  Directory missing: ${staging}/bin" >&2
    fi
    if [[ -e "${src_dir}/ffmpeg" ]]; then
        echo "  Build tree has: ${src_dir}/ffmpeg (not executable?)" >&2
        ls -la "${src_dir}/ffmpeg" 2>/dev/null >&2 || true
    else
        echo "  Build tree binary missing: ${src_dir}/ffmpeg (link step may have failed — see ffbuild/config.log)." >&2
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

    FFMPEG_SOURCE_MAKE_RETRY_DONE=0
    FFMPEG_SOURCE_MAKE_EMFILE_RETRY_DONE=0

    echo
    echo "part 1 — official ffmpeg.org release source (${version}, profile: ${SOURCE_PROFILE})"
    echo

    normalize_legacy_versioned_bins
    install_source_build_dependencies || return 1

    need_cmd make
    need_cmd gcc
    need_cmd install

    tarball="$(ffmpeg_org_release_tarball_name "${version}")"
    url="$(ffmpeg_org_release_tarball_url "${version}")"
    build_id="$(ffmpeg_source_build_id "${version}")"

    mkdir -p "${TEMP_CATALOG}" "${BIN_DIR}"
    TMP_WORK_DIR="$(mktemp -d "${TEMP_CATALOG}/ffmpeg-source-build.XXXXXX")"
    staging="$(ffmpeg_source_resolve_staging_dir "${TMP_WORK_DIR}")"

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
    if ffmpeg_source_static_build; then
        echo "part 3 — configure and compile static build (this can take a long time)"
    else
        echo "part 3 — configure and compile shared build (this can take a long time)"
    fi
    echo

    cd "${src_dir}"
    ffmpeg_source_ensure_vulkan_build_deps
    FFMPEG_SOURCE_SKIP_VULKAN=0
    if ! ffmpeg_source_vulkan_configure_ready; then
        FFMPEG_SOURCE_SKIP_VULKAN=1
        log_note "Vulkan unavailable — configure will omit vulkan, libshaderc, and libplacebo (optional for jellyfin)."
    fi
    log_step "Running ffmpeg configure (profile ${SOURCE_PROFILE}, release ${version})..."

    if ! ffmpeg_source_run_configure "${staging}"; then
        local -a first_configure_args=()
        ffmpeg_source_collect_configure_args "${staging}" first_configure_args
        if ffmpeg_source_configure_args_has_vulkan "${first_configure_args[@]}"; then
            echo ">>> Configure failed with optional GPU stack — retrying without vulkan, libshaderc, and libplacebo..." >&2
            log_note "Vulkan is optional for transcoding (NVENC, VAAPI, and software paths still work)."
            FFMPEG_SOURCE_SKIP_VULKAN=1
            ffmpeg_source_clean_configure_tree
            if ! ffmpeg_source_run_configure "${staging}"; then
                echo "ERROR: ffmpeg configure failed after Vulkan fallback (see ffbuild/config.log)." >&2
                return 1
            fi
        else
            echo "ERROR: ffmpeg configure failed (see ffbuild/config.log)." >&2
            return 1
        fi
    fi

    jobs="$(ffmpeg_source_prepare_make_jobs)"
    log_step "Building with make -j${jobs}..."
    if ! ffmpeg_source_run_make "${jobs}" "${src_dir}"; then
        if (( jobs > 1 )); then
            echo ">>> make failed — retrying with make -j1..." >&2
        fi
        if (( jobs > 1 )) && ffmpeg_source_run_make 1 "${src_dir}"; then
            :
        elif ffmpeg_source_retry_make_after_emfile "${src_dir}" "${jobs}" "${FFMPEG_SOURCE_LAST_MAKE_LOG}"; then
            :
        elif ffmpeg_source_retry_make_after_segfault "${staging}" "${src_dir}" "${jobs}" \
            "${FFMPEG_SOURCE_LAST_MAKE_RC}" "${FFMPEG_SOURCE_LAST_MAKE_LOG}"; then
            :
        else
            echo "ERROR: ffmpeg make failed (see messages above; build tree: ${src_dir})." >&2
            return 1
        fi
    fi

    if [[ ! -x "${src_dir}/ffmpeg" ]]; then
        echo "ERROR: ffmpeg was not built in ${src_dir} (check ffbuild/config.log)." >&2
        return 1
    fi

    log_step "Staging install into prefix ${staging} before copying to ${BIN_DIR}..."
    if [[ -n "${DESTDIR:-}" ]]; then
        log_note "Unsetting DESTDIR for make install (was: ${DESTDIR})."
    fi
    run_env -u DESTDIR make install

    if ! ffmpeg_source_ensure_staged_bins "${staging}" "${src_dir}"; then
        ffmpeg_source_report_staging_failure "${staging}" "${src_dir}"
        return 1
    fi

    print_source_build_encoder_check "${staging}/bin/ffmpeg"

    install_versioned_bins_to_local "${build_id}" "${staging}/bin/ffmpeg" "${staging}/bin/ffprobe" "${staging}/bin/ffplay"
    print_install_success_summary "${build_id}" "official source ${SOURCE_PROFILE} ${version}"
    return 0
}

print_local_bin_tool_row() {
    local tool="$1"
    local path="${BIN_DIR}/${tool}"
    local resolved="" ver_line=""

    echo "  ${tool}:"
    if ! print_tool_install_path_detail "${tool}"; then
        echo "    (not installed)"
        return 0
    fi
    if [[ -f "${path}" && ! -L "${path}" ]]; then
        echo "    WARNING: expected symlink -> ${tool}-VERSION"
    fi

    resolved="$(readlink -f "${path}" 2>/dev/null || true)"
    if [[ -n "${resolved}" && -x "${resolved}" ]]; then
        ver_line="$(probe_tool_version_output "${resolved}" 2>/dev/null | head -n1 || true)"
        if [[ -n "${ver_line}" ]]; then
            echo "    version: ${ver_line}"
        else
            echo "    version: (probe failed)"
        fi
    fi
}

print_local_bin_ffmpeg_summary() {
    local path=""

    echo
    echo "part — ${BIN_DIR} ffmpeg toolchain"
    echo
    echo "Files matching ${BIN_DIR}/ff*:"
    if compgen -G "${BIN_DIR}/ff*" >/dev/null 2>&1; then
        ls -l "${BIN_DIR}"/ff* 2>/dev/null || true
    else
        echo "  (none)"
    fi
    echo
    echo "Active tools:"
    for path in "${FFMPEG_ACTIVE_TOOLS[@]}"; do
        print_local_bin_tool_row "${path}"
    done
    echo
    list_preserved_ffmpeg_versions
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
    echo "           ${BIN_FFPLAY} -> $(readlink "${BIN_FFPLAY}" 2>/dev/null || echo '?')"
    list_preserved_ffmpeg_versions
    prompt_remove_old_ffmpeg_installs
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
    build_id="$(resolve_version_label_from_executable "${extracted_dir}/ffmpeg" "${FFMPEG_ORG_VERSION:-}" || true)"
    if [[ -z "${build_id}" ]]; then
        build_id="${static_semver}"
    fi
    if [[ -z "${build_id}" ]]; then
        build_id="unknown"
        log_note "Could not determine version label from static binary; using ${build_id}."
    elif [[ -n "${FFMPEG_ORG_VERSION}" && "${build_id}" == "${FFMPEG_ORG_VERSION}" ]]; then
        static_out="$(probe_tool_version_output "${extracted_dir}/ffmpeg" || true)"
        if [[ "${static_out}" =~ ffmpeg[[:space:]]+version[[:space:]]+N-[0-9]+-g ]]; then
            log_note "Static git snapshot binary; versioned filenames use ffmpeg.org release ${build_id}."
        fi
    fi
    log_note "Extracted: $(basename "${extracted_dir}")"
    log_note "Install version label: ${build_id}"
    if dir_date="$(build_id_from_extracted_dir "${extracted_dir}" || true)"; then
        log_note "Tarball directory build date: ${dir_date}"
    fi
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

    install_versioned_bins_to_local "${build_id}" "${extracted_dir}/ffmpeg" "${extracted_dir}/ffprobe" "${extracted_dir}/ffplay"
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
    apt_ffplay="$(command -v ffplay || true)"
    if [[ -z "${apt_ffmpeg}" || ! -x "${apt_ffmpeg}" ]]; then
        echo "ERROR: ffmpeg not found after apt install." >&2
        return 1
    fi

    ver="$(probe_ffmpeg_semver "${apt_ffmpeg}" || true)"
    [[ -n "${ver}" ]] || ver="${APT_FFMPEG_VERSION:-unknown}"
    build_id="${ver}-apt"

    install_versioned_symlinks_to_local "${build_id}" "${apt_ffmpeg}" "${apt_ffprobe}" "${apt_ffplay}"
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
    mkdir -p "${BIN_DIR}"
    detect_machine "$(uname -m)"
    fetch_ffmpeg_org_latest_release || true
    normalize_legacy_versioned_bins
    normalize_local_bin_active_tools

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
    if [[ -n "${INSTALLED_BUILD_SNAPSHOT_DATE}" ]]; then
        installed_date="$(format_build_date_display "${INSTALLED_BUILD_SNAPSHOT_DATE}")"
    elif build_id_is_date "${installed}"; then
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
        echo "  package: $(ffmpeg_org_release_tarball_name "${FFMPEG_ORG_VERSION}")"
        echo "  url:     $(ffmpeg_org_release_tarball_url "${FFMPEG_ORG_VERSION}")"
        echo "  profile: ${SOURCE_PROFILE:-common}"
        (( FFMPEG_SOURCE_WITH_FDK_AAC == 1 )) && echo "  extras:  libfdk-aac (non-free)"
        [[ "${SOURCE_PROFILE:-}" == jellyfin ]] && echo "  extras:  Jellyfin-like shared build (FDK-AAC, VAAPI, NVENC)"
    fi
    echo "  temp:    ${TEMP_CATALOG}"
    echo

    run_install_plan
    print_local_bin_ffmpeg_summary
}

HEADER_EXTRA_ARGS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        --no_startup_delay) HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY); shift ;;
        *) break ;;
    esac
done

if [[ -f /root/bin/_script_header.sh ]]; then
    # shellcheck disable=SC1091
    . /root/bin/_script_header.sh "${HEADER_EXTRA_ARGS[@]}"
fi

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
                echo "Invalid --source-profile: ${2} (use min, common, max, gpu, nvidia, or jellyfin)" >&2
                exit 1
            fi
            CLI_SOURCE_PROFILE="${2}"
            shift 2
            ;;
        --source-with-fdk-aac) CLI_SOURCE_WITH_FDK=1; shift ;;
        *) echo "Unknown argument: $1" >&2; echo "Try: $(basename "$0") --help" >&2; exit 1 ;;
    esac
done


main "$@"

if [[ -f /root/bin/_script_footer.sh ]]; then
    # shellcheck disable=SC1091
    . /root/bin/_script_footer.sh
fi
