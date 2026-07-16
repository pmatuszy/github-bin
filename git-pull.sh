#!/bin/bash
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay
# Compatibility wrapper — use git-bin.sh pull (see git-bin.sh v3.0).
_GIT_BIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "${1:-}" in
  -h|--help)
    cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [OPTIONS...]

Compatibility wrapper for git-bin.sh pull.
All other arguments are passed through (e.g. batch, --no_startup_delay).

Options:
  -h, --help     Show this help and exit.
  -v, --version  Print git-bin.sh version and exit.
EOF
    exit 0
    ;;
  -v|--version)
    exec bash "${_GIT_BIN_ROOT}/git-bin.sh" -v pull
    ;;
esac
exec bash "${_GIT_BIN_ROOT}/git-bin.sh" pull "$@"
