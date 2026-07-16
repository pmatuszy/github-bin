#!/usr/bin/env bash
# v. 20260716.163224 - versioning format v. YYYYMMDD.HH24MISS
# 2026.06.18 - v. 1.5 - fix URI probe: SQLite 3.53+ has no -uri flag (URI via FILENAME / sqlite3_config)
# 2026.06.16 - v. 1.4 - prompt before source compile; verify gcc/make/tar prereqs with apt hint
# 2026.06.16 - v. 1.3 - official prebuilt zip lacks -uri; probe before install, compile autoconf with SQLITE_USE_URI=1
# 2026.06.16 - v. 1.2 - install binaries directly in /usr/local/bin (no versioned tree)
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
#   /usr/local/bin/sqlite3
#   /usr/local/bin/sqldiff            (when shipped in zip)
#   /usr/local/bin/sqlite3_analyzer   (when shipped in zip)
#
# x86_64: try official sqlite-tools zip first; compile autoconf when prebuilt lacks -uri (usual)
# other:  build from sqlite-autoconf-*.tar.gz with -DSQLITE_USE_URI=1
#

set -euo pipefail

SQLITE_BASE_URL="https://www.sqlite.org"
SQLITE_DOWNLOAD_PAGE=""
BIN_DIR="/usr/local/bin"
BIN_LINK="${BIN_DIR}/sqlite3"
LEGACY_CURRENT_LINK="/usr/local/sqlite"

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

Install SQLite CLI with -uri / ?nolock=1 support into /usr/local/bin (root required).

Options:
  -y, --yes              Proceed without interactive prompts (includes compile if needed)
  --version X.Y.Z        Install this release (default: latest from sqlite.org)
  -h, --help             Show this help

Source compile (when official zip lacks -uri) needs: gcc or cc, make, sed, tar, gzip.
On Debian/Ubuntu: apt-get install -y build-essential

Environment:
  INSTALL_SQLITE_READ_TIMEOUT   Prompt timeout seconds (default: 300)
  NETWORK_TIMEOUT_SEC           curl/wget timeout (default: 120)

After install, ensure /usr/local/bin is before /usr/bin in PATH:
  hash -r
  which sqlite3
  sqlite3 -batch 'file::memory:' 'SELECT 1;'
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

sqlite_c_compiler() {
    if command -v gcc >/dev/null 2>&1; then
        printf '%s' gcc
        return 0
    fi
    if command -v cc >/dev/null 2>&1; then
        printf '%s' cc
        return 0
    fi
    return 1
}

print_compile_prerequisite_install_hint() {
    if command -v apt-get >/dev/null 2>&1; then
        echo "On Debian/Ubuntu, install build tools with:" >&2
        echo "  apt-get update" >&2
        echo "  apt-get install -y build-essential" >&2
    else
        echo "Install a C compiler (gcc), make, and build-essential-equivalent packages for your distro." >&2
    fi
}

# Return 0 when gcc/cc, make, sed, tar, gzip exist and the compiler can link a trivial program.
check_compile_prerequisites() {
    local -a missing=()
    local cc="" tmpsrc="" tmpexe=""

    if ! cc="$(sqlite_c_compiler)"; then
        missing+=( "gcc or cc (C compiler)" )
    fi
    command -v make >/dev/null 2>&1 || missing+=( make )
    command -v sed >/dev/null 2>&1 || missing+=( sed )
    command -v tar >/dev/null 2>&1 || missing+=( tar )
    if ! command -v gzip >/dev/null 2>&1 && ! command -v gunzip >/dev/null 2>&1; then
        missing+=( gzip )
    fi

    if (( ${#missing[@]} > 0 )); then
        echo "ERROR: Missing prerequisites for compiling sqlite3 from source:" >&2
        printf '  - %s\n' "${missing[@]}" >&2
        print_compile_prerequisite_install_hint
        return 1
    fi

    tmpsrc="$(mktemp --suffix=.c)"
    tmpexe="$(mktemp)"
    printf 'int main(void){return 0;}\n' >"${tmpsrc}"
    if ! "${cc}" "${tmpsrc}" -o "${tmpexe}" 2>/dev/null; then
        rm -f "${tmpsrc}" "${tmpexe}"
        echo "ERROR: C compiler found (${cc}) but failed to compile a test program." >&2
        print_compile_prerequisite_install_hint
        return 1
    fi
    rm -f "${tmpsrc}" "${tmpexe}"
    return 0
}

prompt_compile_from_source() {
    local reason="$1"
    local default_key="n"

    (( ASSUME_YES )) && default_key="y"

    echo
    echo "Source compile required: ${reason}"
    echo "Build uses sqlite-autoconf with -DSQLITE_USE_URI=1 (-uri / ?nolock=1 support)."
    echo "Downloads source and runs ./configure && make (typically a few minutes)."

    if ! check_compile_prerequisites; then
        exit 1
    fi
    echo "Build prerequisites: OK ($(sqlite_c_compiler), make, tar, sed)."

    if [[ ! -t 0 ]] && ! (( ASSUME_YES )); then
        echo "Non-interactive session — not compiling (default [N]). Use --yes to compile and install."
        exit 0
    fi

    sqlite_read_key "Compile sqlite3 from source now? [y/N]: " "${default_key}" "${INSTALL_SQLITE_READ_TIMEOUT}"
    case "${REPLY}" in
        y|Y) echo "Proceeding with source compile..." ;;
        *) echo "Quitting — no changes made."; exit 0 ;;
    esac
}

run_source_compile() {
    local build_id="$1"
    local reason="$2"

    prompt_compile_from_source "${reason}"
    install_from_source "${build_id}"
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
        echo "Install method: try official zip, else compile autoconf with -DSQLITE_USE_URI=1"
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

sqlite_uri_probe() {
    local exe="$1"
    local errtmp="" tmppath="" uri=""

    [[ -n "$exe" && -x "$exe" ]] || return 1

    errtmp="$(mktemp)"

    # SQLite 3.53+ shell: no -uri flag; URI enabled via sqlite3_config at startup.
    if "${exe}" -batch 'file::memory:' 'SELECT 1;' >/dev/null 2>"${errtmp}"; then
        rm -f -- "${errtmp}"
        return 0
    fi

    # Older builds: explicit -uri flag before the database argument.
    if "${exe}" -batch -uri 'file::memory:' 'SELECT 1;' >/dev/null 2>"${errtmp}"; then
        rm -f -- "${errtmp}"
        return 0
    fi
    rm -f -- "${errtmp}"

    tmppath="$(mktemp)"
    for uri in "file:${tmppath}?nolock=1" "file://${tmppath}?nolock=1"; do
        if "${exe}" -batch "${uri}" 'SELECT 1;' >/dev/null 2>/dev/null; then
            rm -f -- "${tmppath}"
            return 0
        fi
        if "${exe}" -batch -uri "${uri}" 'SELECT 1;' >/dev/null 2>/dev/null; then
            rm -f -- "${tmppath}"
            return 0
        fi
    done
    rm -f -- "${tmppath}"
    return 1
}

sqlite_has_uri_support() {
    sqlite_uri_probe "$1"
}

print_sqlite_exe_info() {
    local label="$1"
    local exe="$2"

    echo "  ${label}: ${exe:-not found}"
    if [[ -n "$exe" && -x "$exe" ]]; then
        echo "    version: $("${exe}" --version 2>/dev/null | head -n 1 || echo unknown)"
        if sqlite_has_uri_support "$exe"; then
            echo "    URI:     yes (file:...?nolock=1)"
        else
            echo "    URI:     no"
        fi
    fi
}

find_managed_sqlite() {
    if [[ -x "${BIN_LINK}" ]] && sqlite_has_uri_support "${BIN_LINK}"; then
        printf '%s' "${BIN_LINK}"
        return 0
    fi
    if [[ -L "${LEGACY_CURRENT_LINK}" && -x "${LEGACY_CURRENT_LINK}/bin/sqlite3" ]] \
        && sqlite_has_uri_support "${LEGACY_CURRENT_LINK}/bin/sqlite3"; then
        printf '%s' "${LEGACY_CURRENT_LINK}/bin/sqlite3"
        return 0
    fi
    return 1
}

install_tools_to_bin_dir() {
    local src_dir="${1:-.}"

    mkdir -p "${BIN_DIR}"
    install -m 755 "${src_dir}/sqlite3" "${BIN_LINK}"
    if [[ -x "${src_dir}/sqldiff" ]]; then
        install -m 755 "${src_dir}/sqldiff" "${BIN_DIR}/sqldiff"
    fi
    if [[ -x "${src_dir}/sqlite3_analyzer" ]]; then
        install -m 755 "${src_dir}/sqlite3_analyzer" "${BIN_DIR}/sqlite3_analyzer"
    fi
    if [[ -x "${src_dir}/sqlite3_rsync" ]]; then
        install -m 755 "${src_dir}/sqlite3_rsync" "${BIN_DIR}/sqlite3_rsync"
    fi
}

cleanup_legacy_install_layout() {
    if [[ -e "${BIN_LINK}" ]]; then
        rm -f "${BIN_LINK}"
    fi
    if [[ -L "${BIN_DIR}/sqldiff" ]]; then
        rm -f "${BIN_DIR}/sqldiff"
    fi
    if [[ -L "${BIN_DIR}/sqlite3_analyzer" ]]; then
        rm -f "${BIN_DIR}/sqlite3_analyzer"
    fi
    if [[ -L "${LEGACY_CURRENT_LINK}" ]]; then
        rm -f "${LEGACY_CURRENT_LINK}"
    fi
}

get_installed_version() {
    local exe="$1" line=""

    [[ -n "$exe" && -x "$exe" ]] || return 0
    line="$("${exe}" --version 2>/dev/null | head -n 1)" || line=""
    [[ "$line" =~ ([0-9]+\.[0-9]+\.[0-9]+) ]] && printf '%s' "${BASH_REMATCH[1]}"
}

prompt_install_if_missing() {
    local latest="$1"

    echo "No managed SQLite install found in ${BIN_DIR} (with URI support)."
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
    local build_id="$1"
    local artifact="sqlite-tools-linux-x64-${build_id}.zip"
    local url="" archive=""

    url="$(resolve_download_path "${artifact}")" || return 1
    archive="${artifact}"

    echo "Download URL: ${url}"
    echo "Install target: ${BIN_DIR}"

    download_file "${url}" "${archive}"
    need_cmd unzip
    unzip -q -o "${archive}"

    if [[ ! -x sqlite3 ]]; then
        echo "ERROR: sqlite3 binary not found in ${archive}" >&2
        return 1
    fi

    if ! sqlite_uri_probe "./sqlite3"; then
        echo "NOTE: Prebuilt sqlite3 cannot open file: URI databases." >&2
        return 1
    fi

    cleanup_legacy_install_layout
    install_tools_to_bin_dir "."
}

install_from_source() {
    local build_id="$1"
    local artifact="sqlite-autoconf-${build_id}.tar.gz"
    local url="" src_dir="" staging_prefix=""

    url="$(resolve_download_path "${artifact}")" || return 1

    echo "Download URL: ${url}"
    echo "Install target: ${BIN_DIR}"

    download_file "${url}" "${artifact}"
    tar xzf "${artifact}"
    src_dir="sqlite-autoconf-${build_id}"
    [[ -d "$src_dir" ]] || { echo "ERROR: extracted source dir missing: ${src_dir}" >&2; exit 1; }

    staging_prefix="$(mktemp -d)"
    (
        cd "$src_dir"
        ./configure \
            --prefix="${staging_prefix}" \
            --disable-static \
            CFLAGS="-DSQLITE_USE_URI=1 -DSQLITE_ENABLE_FTS5 -DSQLITE_ENABLE_JSON1 -DSQLITE_ENABLE_RTREE -O2"
        make -j"$(nproc 2>/dev/null || echo 2)"
        make install
    )

    if ! sqlite_uri_probe "${staging_prefix}/bin/sqlite3"; then
        rm -rf "${staging_prefix}"
        echo "ERROR: Compiled sqlite3 cannot open file: URI databases (?nolock=1)." >&2
        return 1
    fi

    cleanup_legacy_install_layout
    install_tools_to_bin_dir "${staging_prefix}/bin"
    rm -rf "${staging_prefix}"
}

finalize_install() {
    echo "Verifying installation..."
    if ! sqlite_uri_probe "${BIN_LINK}"; then
        echo "ERROR: Installed sqlite3 cannot open file: URI databases: ${BIN_LINK}" >&2
        exit 1
    fi
    "${BIN_LINK}" --version
    "${BIN_LINK}" -batch 'file::memory:' 'SELECT 1;'

    echo
    echo "SQLite installed successfully."
    echo "Version: $(get_installed_version "${BIN_LINK}")"
    echo "Command: ${BIN_LINK}"
    echo
    echo "Ensure /usr/local/bin is before /usr/bin in PATH, then run:"
    echo "  hash -r"
    echo "  which sqlite3"
    echo "  sqlite3 -batch 'file::memory:' 'SELECT 1;'"
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
    local build_id="" version="" method=""

    parse_args "$@"
    as_root_check
    detect_platform

    need_cmd curl
    need_cmd mkdir
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

    TMP_WORK_DIR="$(mktemp -d)"
    cd "${TMP_WORK_DIR}"

    if (( USE_PREBUILT_TOOLS )); then
        method="prebuilt zip"
        if ! (
            install_from_prebuilt_zip "${build_id}"
        ); then
            run_source_compile "${build_id}" "Official zip lacks -uri support."
            method="source"
        fi
    else
        run_source_compile "${build_id}" "No official Linux prebuilt for ${PLATFORM}."
        method="source"
    fi

    echo "Install method used: ${method}"
    finalize_install
}

main "$@"
