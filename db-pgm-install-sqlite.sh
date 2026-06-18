#!/usr/bin/env bash
# 2026.06.16 - v. 1.1 - fix 404 downloads: parse RELATIVE-URL from sqlite.org CSV (year/artifact paths)
# 2026.06.16 - v. 1.0 - install SQLite CLI with URI/?nolock=1 (official zip or autoconf build)
#
# db-pgm-install-sqlite.sh
#
# Installs a SQLite command-line shell with URI filename support enabled
# (SQLITE_USE_URI=1). Distro packages (e.g. Ubuntu apt sqlite3) often lack -uri
# even on SQLite 3.45+, which breaks CIFS/SMB cache access for rename.sh.
#
# Official downloads: https://www.sqlite.org/download.html
#
# Layout:
#   /usr/local/sqlite-<version>/bin/sqlite3
#   /usr/local/sqlite              -> /usr/local/sqlite-<version>
#   /usr/local/bin/sqlite3         -> /usr/local/sqlite/bin/sqlite3
#
# x86_64: official prebuilt sqlite-tools-linux-x64-*.zip when available
# other:  build from sqlite-autoconf-*.tar.gz with -DSQLITE_USE_URI=1
#

set -euo pipefail

SQLITE_BASE_URL="https://www.sqlite.org"
SQLITE_DOWNLOAD_PAGE=""
INSTALL_BASE="/usr/local"
BIN_DIR="/usr/local/bin"
CURRENT_LINK="${INSTALL_BASE}/sqlite"
BIN_LINK="${BIN_DIR}/sqlite3"

ASSUME_YES=0
CLI_PIN_VERSION=""
INSTALL_SQLITE_READ_TIMEOUT="${INSTALL_SQLITE_READ_TIMEOUT:-300}"
NETWORK_TIMEOUT_SEC="${NETWORK_TIMEOUT_SEC:-120}"

TMP_WORK_DIR=""
cleanup_tmp_work_dir() {
    if [[ -n "${TMP_WORK_DIR:-}" && -d "${TMP_WORK_DIR}" ]]; then
        rm -f -- "${TMP_WORK_DIR}/sqlite3" 2>/dev/null || true
        rm -rf "${TMP_WORK_DIR}"
    fi
}
trap cleanup_tmp_work_dir EXIT

usage() {
    cat <<'EOF'
Usage: db-pgm-install-sqlite.sh [options]

Install SQLite CLI with -uri / ?nolock=1 support under /usr/local (root required).

Options:
  -y, --yes              Proceed without interactive prompts
  --version X.Y.Z        Install this release (default: latest from sqlite.org)
  -h, --help             Show this help

Environment:
  INSTALL_SQLITE_READ_TIMEOUT   Prompt timeout seconds (default: 300)
  NETWORK_TIMEOUT_SEC           curl/wget timeout (default: 120)

After install, ensure /usr/local/bin is before /usr/bin in PATH:
  hash -r
  which sqlite3
  sqlite3 -help 2>&1 | grep -w uri
EOF
}

flush_stdin() {
    while read -r -t 0.001 -n 10000 _garbage 2>/dev/null; do :; done
}

sqlite_read_key() {
    local prompt="$1"
    local default_key="${2:-}"
    local timeout="${3:-${INSTALL_SQLITE_READ_TIMEOUT}}"
    local answer=""

    if [[ ! -t 0 ]] || (( ASSUME_YES )); then
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
            USE_PREBUILT_TOOLS=1
            ;;
        aarch64|arm64)
            PLATFORM="linux-arm64"
            USE_PREBUILT_TOOLS=0
            ;;
        i386|i686)
            PLATFORM="linux-x86"
            USE_PREBUILT_TOOLS=0
            ;;
        armv7l|armv6l|arm)
            PLATFORM="linux-arm"
            USE_PREBUILT_TOOLS=0
            ;;
        *)
            echo "ERROR: Unsupported Linux architecture: ${arch}" >&2
            exit 1
            ;;
    esac

    echo "Detected platform: ${PLATFORM}"
    if (( USE_PREBUILT_TOOLS )); then
        echo "Install method: official sqlite-tools-linux-x64 zip (when available)"
    else
        echo "Install method: compile sqlite-autoconf source with -DSQLITE_USE_URI=1"
    fi
}

download_file() {
    local url="$1"
    local output="$2"

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL --connect-timeout 30 --max-time "${NETWORK_TIMEOUT_SEC}" "$url" -o "$output"
    elif command -v wget >/dev/null 2>&1; then
        wget -q --timeout="${NETWORK_TIMEOUT_SEC}" "$url" -O "$output"
    else
        echo "ERROR: Need curl or wget." >&2
        exit 1
    fi
}

download_to_stdout() {
    local url="$1"

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL --connect-timeout 30 --max-time "${NETWORK_TIMEOUT_SEC}" "$url"
    elif command -v wget >/dev/null 2>&1; then
        wget -q --timeout="${NETWORK_TIMEOUT_SEC}" -O - "$url"
    else
        echo "ERROR: Need curl or wget." >&2
        exit 1
    fi
}

# 3.53.2 -> 3530200 (see sqlite.org/download.html filename encoding).
sqlite_version_to_build_id() {
    local v="$1" major="" minor="" patch=""

    IFS=. read -r major minor patch _ <<< "$v"
    minor="${minor:-0}"
    patch="${patch:-0}"
    printf '%d%02d%02d00' "$major" "$minor" "$patch"
}

# 3530200 -> 3.53.2
sqlite_build_id_to_version() {
    local enc="$1" major="" rest="" minor="" patch=""

    [[ "$enc" =~ ^[0-9]+$ ]] || return 1
    major="${enc:0:1}"
    rest="${enc:1}"
    minor=$((10#${rest:0:2}))
    patch=$((10#${rest:2:2}))
    printf '%d.%d.%d' "$major" "$minor" "$patch"
}

fetch_sqlite_download_page() {
    if [[ -z "${SQLITE_DOWNLOAD_PAGE}" ]]; then
        SQLITE_DOWNLOAD_PAGE="$(download_to_stdout "${SQLITE_BASE_URL}/download.html")"
    fi
    printf '%s' "${SQLITE_DOWNLOAD_PAGE}"
}

fetch_latest_build_id() {
    local page="" enc=""

    page="$(fetch_sqlite_download_page)"
    enc="$(printf '%s' "$page" | grep -oE 'sqlite-autoconf-[0-9]+\.tar\.gz' | head -n 1 | sed -E 's/^sqlite-autoconf-([0-9]+)\.tar\.gz$/\1/')"
    if [[ -z "$enc" ]]; then
        echo "ERROR: Could not parse latest SQLite version from ${SQLITE_BASE_URL}/download.html" >&2
        return 1
    fi
    printf '%s' "$enc"
}

# sqlite.org serves files as https://www.sqlite.org/YYYY/artifact (CSV RELATIVE-URL in download.html).
resolve_download_path() {
    local artifact="$1"
    local page="" rel=""

    page="$(fetch_sqlite_download_page)"

    rel="$(printf '%s' "$page" | grep -E '^PRODUCT,' | grep -F "${artifact}" | head -n 1 | cut -d, -f3)"
    if [[ -z "$rel" ]]; then
        rel="$(printf '%s' "$page" | grep -oE "d391\('[^']+','[^']*/${artifact}'\)" | head -n 1 | sed -E "s/.*'([^']*${artifact})'.*/\1/")"
    fi
    if [[ -z "$rel" ]]; then
        rel="$(printf '%s' "$page" | grep -oE "[0-9]{4}/${artifact}" | head -n 1)"
    fi
    if [[ -z "$rel" ]]; then
        echo "ERROR: Could not resolve download path for ${artifact} (see ${SQLITE_BASE_URL}/download.html)." >&2
        return 1
    fi

    rel="${rel#/}"
    printf '%s/%s' "${SQLITE_BASE_URL}" "${rel}"
}

sqlite_has_uri_support() {
    local exe="$1"

    [[ -n "$exe" && -x "$exe" ]] || return 1
    if "${exe}" -help 2>&1 | grep -qE '(^|[[:space:]])-uri([[:space:]]|$)'; then
        return 0
    fi
    "${exe}" -uri 'file::memory:' 'SELECT 1;' >/dev/null 2>&1
}

print_sqlite_exe_info() {
    local label="$1"
    local exe="$2"

    echo "  ${label}: ${exe:-not found}"
    if [[ -n "$exe" && -x "$exe" ]]; then
        echo "    version: $("${exe}" --version 2>/dev/null | head -n 1 || echo unknown)"
        if sqlite_has_uri_support "$exe"; then
            echo "    -uri:    yes"
        else
            echo "    -uri:    no"
        fi
    fi
}

find_managed_sqlite() {
    if [[ -x "${BIN_LINK}" ]]; then
        printf '%s' "${BIN_LINK}"
        return 0
    fi
    if [[ -L "${CURRENT_LINK}" && -x "${CURRENT_LINK}/bin/sqlite3" ]]; then
        printf '%s' "${CURRENT_LINK}/bin/sqlite3"
        return 0
    fi
    return 1
}

get_installed_version() {
    local exe="$1" line=""

    [[ -n "$exe" && -x "$exe" ]] || return 0
    line="$("${exe}" --version 2>/dev/null | head -n 1)" || line=""
    [[ "$line" =~ ([0-9]+\.[0-9]+\.[0-9]+) ]] && printf '%s' "${BASH_REMATCH[1]}"
}

prompt_install_if_missing() {
    local latest="$1"

    echo "No /usr/local SQLite install found (with URI support)."
    echo "  Latest upstream version: ${latest}"
    print_sqlite_exe_info "System PATH sqlite3" "$(command -v sqlite3 2>/dev/null || true)"
    if [[ ! -t 0 ]] && ! (( ASSUME_YES )); then
        echo "Non-interactive session — not installing (default [N]). Use --yes to install."
        exit 0
    fi
    if (( ASSUME_YES )); then
        echo "Proceeding with install (--yes)."
        return 0
    fi
    sqlite_read_key "Install SQLite CLI with -uri support now? [y/N]: " n "${INSTALL_SQLITE_READ_TIMEOUT}"
    case "${REPLY}" in
        y|Y) echo "Proceeding with install..." ;;
        *) echo "Quitting — no changes made."; exit 0 ;;
    esac
}

prompt_if_already_installed() {
    local latest="$1"
    local managed_exe="" installed="" system_exe=""

    managed_exe="$(find_managed_sqlite 2>/dev/null || true)"
    system_exe="$(command -v sqlite3 2>/dev/null || true)"

    if [[ -z "$managed_exe" ]]; then
        prompt_install_if_missing "${latest}"
        return 0
    fi

    installed="$(get_installed_version "${managed_exe}")"
    echo "Managed SQLite install:"
    print_sqlite_exe_info "Command" "${managed_exe}"
    echo "  Latest upstream version: ${latest}"
    if [[ -n "$system_exe" && "$system_exe" != "$managed_exe" ]]; then
        print_sqlite_exe_info "System PATH sqlite3 (may differ)" "${system_exe}"
    fi

    if [[ -n "$installed" && "$installed" == "$latest" ]] && sqlite_has_uri_support "${managed_exe}"; then
        echo "You already have the latest managed build with -uri support."
        if (( ASSUME_YES )); then
            echo "Reinstalling (--yes)."
            return 0
        fi
        echo -n "Reinstall it anyway? [y/N] "
        read -r -n 1 REPLY || REPLY=""
        echo
        case "${REPLY}" in
            y|Y) echo "Reinstalling..." ;;
            *) echo "Quitting — no changes made."; exit 0 ;;
        esac
        return 0
    fi

    if (( ASSUME_YES )); then
        echo "Proceeding with update/install (--yes)."
        return 0
    fi
    echo -n "Update/install version ${latest} now? [Y/n] "
    read -r -n 1 REPLY || REPLY=""
    echo
    case "${REPLY}" in
        n|N) echo "Quitting — no changes made."; exit 0 ;;
        *) echo "Proceeding with update/install..." ;;
    esac
}

install_from_prebuilt_zip() {
    local version="$1" build_id="$2" target_dir="$3"
    local artifact="sqlite-tools-linux-x64-${build_id}.zip"
    local url="" archive=""

    url="$(resolve_download_path "${artifact}")" || return 1
    archive="${artifact}"

    echo "Download URL: ${url}"
    echo "Install target: ${target_dir}"

    download_file "${url}" "${archive}"
    need_cmd unzip
    unzip -q -o "${archive}"

    if [[ ! -x sqlite3 ]]; then
        echo "ERROR: sqlite3 binary not found in ${archive}" >&2
        return 1
    fi

    mkdir -p "${target_dir}/bin"
    install -m 755 sqlite3 "${target_dir}/bin/sqlite3"
    [[ -x sqldiff ]] && install -m 755 sqldiff "${target_dir}/bin/sqldiff"
    [[ -x sqlite3_analyzer ]] && install -m 755 sqlite3_analyzer "${target_dir}/bin/sqlite3_analyzer"
}

install_from_source() {
    local version="$1" build_id="$2" target_dir="$3"
    local artifact="sqlite-autoconf-${build_id}.tar.gz"
    local url="" src_dir=""

    url="$(resolve_download_path "${artifact}")" || return 1

    echo "Download URL: ${url}"
    echo "Install target: ${target_dir}"

    need_cmd gcc
    need_cmd make
    need_cmd sed

    download_file "${url}" "${artifact}"
    tar xzf "${artifact}"
    src_dir="sqlite-autoconf-${build_id}"
    [[ -d "$src_dir" ]] || { echo "ERROR: extracted source dir missing: ${src_dir}" >&2; exit 1; }

    (
        cd "$src_dir"
        ./configure \
            --prefix="${target_dir}" \
            --disable-static \
            CFLAGS="-DSQLITE_USE_URI=1 -DSQLITE_ENABLE_FTS5 -DSQLITE_ENABLE_JSON1 -DSQLITE_ENABLE_RTREE -O2"
        make -j"$(nproc 2>/dev/null || echo 2)"
        make install
    )
}

finalize_install() {
    local version="$1" target_dir="$2"

    ln -sfn "${target_dir}" "${CURRENT_LINK}"
    mkdir -p "${BIN_DIR}"
    ln -sfn "${CURRENT_LINK}/bin/sqlite3" "${BIN_LINK}"
    if [[ -x "${target_dir}/bin/sqldiff" ]]; then
        ln -sfn "${CURRENT_LINK}/bin/sqldiff" "${BIN_DIR}/sqldiff"
    fi
    if [[ -x "${target_dir}/bin/sqlite3_analyzer" ]]; then
        ln -sfn "${CURRENT_LINK}/bin/sqlite3_analyzer" "${BIN_DIR}/sqlite3_analyzer"
    fi

    echo "Verifying installation..."
    if ! sqlite_has_uri_support "${BIN_LINK}"; then
        echo "ERROR: Installed sqlite3 still lacks -uri support: ${BIN_LINK}" >&2
        exit 1
    fi
    "${BIN_LINK}" --version
    "${BIN_LINK}" -uri 'file::memory:' 'SELECT 1;'

    echo
    echo "SQLite installed successfully."
    echo "Version: $(get_installed_version "${BIN_LINK}")"
    echo "Directory: ${target_dir}"
    echo "Current symlink: ${CURRENT_LINK}"
    echo "Command: ${BIN_LINK}"
    echo
    echo "Ensure /usr/local/bin is before /usr/bin in PATH, then run:"
    echo "  hash -r"
    echo "  which sqlite3"
    echo "  sqlite3 -help 2>&1 | grep -w uri"
}

parse_args() {
    while (( $# > 0 )); do
        case "$1" in
            -y|--yes)
                ASSUME_YES=1
                shift
                ;;
            --version)
                [[ $# -ge 2 ]] || { echo "Missing value for --version" >&2; usage >&2; exit 1; }
                CLI_PIN_VERSION="$2"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                usage >&2
                exit 1
                ;;
        esac
    done
}

main() {
    local build_id="" version="" target_dir="" method=""

    parse_args "$@"
    as_root_check
    detect_platform

    need_cmd curl
    need_cmd mkdir
    need_cmd ln
    need_cmd install
    need_cmd rm

    if [[ -n "$CLI_PIN_VERSION" ]]; then
        if [[ ! "$CLI_PIN_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "ERROR: Invalid --version (expected X.Y.Z): ${CLI_PIN_VERSION}" >&2
            exit 1
        fi
        version="$CLI_PIN_VERSION"
        build_id="$(sqlite_version_to_build_id "${version}")"
    else
        build_id="$(fetch_latest_build_id)"
        version="$(sqlite_build_id_to_version "${build_id}")"
    fi

    echo "SQLite release: ${version} (build id ${build_id})"
    prompt_if_already_installed "${version}"

    target_dir="${INSTALL_BASE}/sqlite-${version}"
    if [[ -d "${target_dir}" ]]; then
        echo "Target already exists: ${target_dir}"
        echo "Reusing directory (will overwrite binaries)."
    fi
    mkdir -p "${target_dir}/bin"

    TMP_WORK_DIR="$(mktemp -d)"
    cd "${TMP_WORK_DIR}"

    if (( USE_PREBUILT_TOOLS )); then
        method="prebuilt zip"
        if ! (
            install_from_prebuilt_zip "${version}" "${build_id}" "${target_dir}"
        ); then
            echo "WARNING: prebuilt zip failed; falling back to source build." >&2
            method="source (fallback)"
            install_from_source "${version}" "${build_id}" "${target_dir}"
        fi
    else
        method="source"
        install_from_source "${version}" "${build_id}" "${target_dir}"
    fi

    echo "Install method used: ${method}"
    finalize_install "${version}" "${target_dir}"
}

main "$@"
