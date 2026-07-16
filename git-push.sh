#!/bin/bash
# Compatibility wrapper — use git-bin.sh push (see git-bin.sh v3.0).
_GIT_BIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "${_GIT_BIN_ROOT}/git-bin.sh" push "$@"
