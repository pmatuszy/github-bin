#!/bin/bash
# Compatibility wrapper — use git-bin.sh push (see git-bin.sh v3.0).
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/git-bin.sh" push "$@"
