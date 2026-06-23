#!/bin/bash

# 2026.06.19 - v. 0.1 - pull economist-weekly-audio + private config into /root/repos/github-economist-*

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
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay] [batch]

Pull economist-weekly-audio (scripts) and economist-weekly-audio-private (config)
from GitHub into sibling directories under /root/repos by default:

  /root/repos/github-economist-weekly-audio/
  /root/repos/github-economist-weekly-audio-private/

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  --no_startup_delay   Skip random startup delay when run non-interactively.

Arguments:
  batch                Non-interactive mode: auto-answer yes to prompts (for cron).

Environment:
  ECONOMIST_GIT_ROOT              Parent directory (default: /root/repos)
  ECONOMIST_PUBLIC_DIR_NAME       Public clone dir name
  ECONOMIST_PRIVATE_DIR_NAME      Private clone dir name
EOF
}

HEADER_EXTRA_ARGS=()
batch_mode=0
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help) show_help; exit 0 ;;
    -v|--version) print_version_banner; exit 0 ;;
    --no_startup_delay) HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY); shift ;;
    batch) batch_mode=1; shift ;;
    *) echo "Unknown argument: $1" >&2; echo "Try: $(basename "$0") --help" >&2; exit 1 ;;
  esac
done

. /root/bin/_script_header.sh "${HEADER_EXTRA_ARGS[@]}"

_GIT_ECO_BIN="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_git-economist-common.sh
. "${_GIT_ECO_BIN}/_git-economist-common.sh"

if (( ! script_is_run_interactively )); then
  echo "${SCRIPT_VERSION}"
  echo
fi

git_economist_init_paths
git_economist_setup_ssh

if (( batch_mode == 1 )); then
  echo
  echo "(PGM) enabling batch mode (no questions asked)"
fi

echo
echo "Pull economist repos into ${ECONOMIST_GIT_ROOT}? [y/N]"
echo "  public : ${ECONOMIST_PUBLIC_REPO}"
echo "  private: ${ECONOMIST_PRIVATE_REPO}"

if (( batch_mode == 0 )); then
  read -t 300 -n 1 p
else
  echo "y (autoanswer in batch mode)"
  p=y
fi
echo
echo

if [[ "${p}" != [yY] ]]; then
  echo "no means no - I am exiting..."
  exit 1
fi

git_economist_check_remote "${ECONOMIST_PRIVATE_GIT_URL}" "economist-weekly-audio-private" || exit $?
git_economist_check_remote "${ECONOMIST_PUBLIC_GIT_URL}" "economist-weekly-audio" || exit $?

git_economist_sync_one_repo "${ECONOMIST_PUBLIC_REPO}" "${ECONOMIST_PUBLIC_GIT_URL}" "economist-weekly-audio (public)" || exit $?
git_economist_sync_one_repo "${ECONOMIST_PRIVATE_REPO}" "${ECONOMIST_PRIVATE_GIT_URL}" "economist-weekly-audio-private" || exit $?

git_economist_post_pull_setup

git_economist_print_status "${ECONOMIST_PUBLIC_REPO}" "economist-weekly-audio (public)"
git_economist_print_status "${ECONOMIST_PRIVATE_REPO}" "economist-weekly-audio-private"

echo "Run pipeline:"
echo "  ${ECONOMIST_PUBLIC_REPO}/scripts/0-economist-runme.sh"

. /root/bin/_script_footer.sh
