#!/usr/bin/env bash
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

set -euo pipefail

BASE_URL="https://exiftool.org"
VERSION_URL="${BASE_URL}/ver.txt"
INSTALL_BASE="/usr/local"
BIN_DIR="/usr/local/bin"

TMP_WORK_DIR=""
cleanup_tmp_work_dir() {
    if [[ -n "${TMP_WORK_DIR:-}" && -d "${TMP_WORK_DIR}" ]]; then
        rm -rf "${TMP_WORK_DIR}"
    fi
}
trap cleanup_tmp_work_dir EXIT

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

# Print the currently installed exiftool version (empty if none/unreadable).
get_installed_version() {
    local exe="$1"
    local v=""

    [[ -n "${exe}" ]] || return 0
    if [[ -x "${exe}" ]] || command -v "${exe}" >/dev/null 2>&1; then
        v="$("${exe}" -ver 2>/dev/null | tr -d '[:space:]')" || v=""
    fi
    echo "${v}"
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
        echo "No existing ExifTool found — proceeding with a fresh install."
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

    read -r reply || reply=""

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
    url="${BASE_URL}/${archive}"

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
    perl "${extracted_dir}/exiftool" -ver >/dev/null

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
    "${bin_link}" -ver

    echo
    echo "ExifTool installed successfully."
    echo "Version: $("${bin_link}" -ver)"
    echo "Directory: ${target_dir}"
    echo "Current symlink: ${current_link}"
    echo "Command: ${bin_link}"
}

main "$@"
