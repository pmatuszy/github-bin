#!/bin/bash

# 2026.06.19 - v. 0.1 - push economist private config (and public only when confirmed); then pull

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

Push local changes in economist repos to GitHub.

By default the private repo (economist.local.conf) is pushed when dirty.
The public scripts repo is pushed only after an explicit [y] confirmation.

Ends with git-economist-pull.sh to verify sync.

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  --no_startup_delay   Skip random startup delay when run non-interactively.

Arguments:
  batch                Push private repo without prompts; skip public unless dirty
                       and you answer y on the public prompt (batch still asks
                       for public with timeout default N).

Environment:
  ECONOMIST_GIT_ROOT, ECONOMIST_PUBLIC_DIR_NAME, ECONOMIST_PRIVATE_DIR_NAME
  (see git-economist-pull.sh --help)
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
  echo "(PGM) enabling batch mode (no questions asked for private repo)"
fi

if [[ ! -d "${ECONOMIST_PRIVATE_REPO}/.git" && ! -d "${ECONOMIST_PUBLIC_REPO}/.git" ]]; then
  echo
  echo "(PGM) No economist repos under ${ECONOMIST_GIT_ROOT}. Run git-economist-pull.sh first."
  echo
  exit 1
fi

echo
echo "Push economist private config from ${ECONOMIST_PRIVATE_REPO}? [y/N]"
if (( batch_mode == 0 )); then
  read -t 300 -n 1 p_private
else
  echo "y (autoanswer in batch mode)"
  p_private=y
fi
echo
echo

if [[ "${p_private}" == [yY] ]]; then
  git_economist_push_repo "${ECONOMIST_PRIVATE_REPO}" "${ECONOMIST_PRIVATE_GIT_URL}" "economist-weekly-audio-private" || exit $?
else
  echo "Skipping private repo push."
fi

if git_economist_repo_is_dirty "${ECONOMIST_PUBLIC_REPO}"; then
  echo
  echo "Public repo ${ECONOMIST_PUBLIC_REPO} has local changes."
  echo "Push public economist-weekly-audio scripts too? [y/N]"
  if (( batch_mode == 0 )); then
    read -t 300 -n 1 p_public
  else
    p_public=n
    echo "N (batch mode: public repo not pushed unless you run interactively)"
  fi
  echo
  echo
  if [[ "${p_public}" == [yY] ]]; then
    git_economist_push_repo "${ECONOMIST_PUBLIC_REPO}" "${ECONOMIST_PUBLIC_GIT_URL}" "economist-weekly-audio (public)" || exit $?
  else
    echo "Skipping public repo push."
  fi
else
  echo "Public repo: clean (nothing to push)."
fi

echo
if (( batch_mode == 0 )); then
  "${_GIT_ECO_BIN}/git-economist-pull.sh"
else
  "${_GIT_ECO_BIN}/git-economist-pull.sh" batch
fi

. /root/bin/_script_footer.sh
