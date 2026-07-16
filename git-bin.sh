#!/bin/bash
# v. 20260716.170000 - show git diff --stat for incoming commits (replaces old git pull output)

# 20260716.165700 - deploy message: ASCII arrow (boxes mangles Unicode)

# 2026.07.16 - v. 3.1 - chmod +x git-bin.sh and wrappers in clone after sync (git mode 644)
# 2026.07.16 - v. 3.0 - consolidate git-pull/push/fetch/reset and _git-bin-common into one script
#
# git-bin.sh
#
# Manage the github-bin clone at ${profile_location_dir:-$HOME}/github/github-bin.
# Subcommands: pull (deploy to bin), push, fetch, reset.
# pull syncs the server clone to origin/master before copying scripts to ${profile_root}/bin.
#

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay] COMMAND [OPTIONS]

Manage github-bin: ${profile_location_dir:-\$HOME}/github/github-bin → ${profile_location_dir:-\$HOME}/bin

Commands:
  pull [batch]              Sync clone from GitHub; install scripts to bin (default for cron).
  push [batch]              Push local clone changes to GitHub; then pull.
  fetch                     git fetch only (interactive).
  reset [batch] [OPTIONS]   Reset clone to origin/master; optionally redeploy (pull).

Global options:
  -h, --help                Show this help and exit.
  -v, --version             Print script version and exit.
  --no_startup_delay        Skip random startup delay (recommended for cron).

Command options (reset):
  --no-deploy               Reset clone only; do not run pull afterward.
  --offline                 Reset to local origin/master without fetch.

Arguments:
  batch                     Non-interactive mode: auto-answer yes to prompts.

Examples:
  $(basename "$0") pull batch --no_startup_delay
  $(basename "$0") reset batch --no_startup_delay
  $(basename "$0") push batch
EOF
}

# --- shared helpers (formerly _git-bin-common.sh) ---

git_bin_setup_ssh() {
  export GIT_SSH_COMMAND='ssh -i $HOME/.ssh/id_SSH_ed25519_20230207_OpenSSH'

  if declare -f check_if_installed >/dev/null 2>&1; then
    check_if_installed keychain
  elif ! command -v keychain >/dev/null 2>&1; then
    echo "(PGM) keychain is not installed — cannot load GitHub SSH keys" >&2
    return 1
  fi

  eval keychain -q --nogui --nocolor --eval id_rsa id_ed25519 id_SSH_ed25519_20230207_OpenSSH 2>&1

  if [[ -f "${HOME}/.keychain/${HOSTNAME}-sh" ]]; then
    # shellcheck source=/dev/null
    . "${HOME}/.keychain/${HOSTNAME}-sh"
  fi
}

git_bin_profile_root() {
  if [[ -n "${profile_location_dir:-}" ]]; then
    printf '%s\n' "${profile_location_dir}"
  else
    printf '%s\n' "${HOME:-/root}"
  fi
}

git_bin_repo_from_script_dir() {
  local script_dir="$1" parent github_project_name="${github_project_name:-github-bin}"

  [[ -d "${script_dir}/.git" ]] || return 1

  export GIT_REPO_DIRECTORY="${script_dir}"

  if [[ "$(basename "${script_dir}")" == "${github_project_name}" ]]; then
    parent="$(dirname "${script_dir}")"
    if [[ "$(basename "${parent}")" == "github" ]]; then
      export profile_root="$(cd "$(dirname "${parent}")" && pwd -P)"
    else
      export profile_root="$(cd "${parent}" && pwd -P)"
    fi
  else
    export profile_root="$(git_bin_profile_root)"
  fi
  return 0
}

git_bin_resolve_paths() {
  local caller script_dir profile_root_val github_project_name="${github_project_name:-github-bin}"

  export github_project_name

  caller="${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}"
  script_dir="$(cd "$(dirname "${caller}")" && pwd -P)"

  if git_bin_repo_from_script_dir "${script_dir}"; then
    return 0
  fi

  profile_root_val="$(git_bin_profile_root)"
  export profile_root="${profile_root_val}"
  export GIT_REPO_DIRECTORY="${profile_root}/github/${github_project_name}"
}

git_bin_sync_clone_to_origin() {
  local offline="${1:-0}" always_reset="${2:-0}"
  local head_sha origin_sha ahead=0 behind=0 need_reset=0

  if (( offline == 0 )); then
    echo "git fetch origin" | boxes -s 70x3 -a c
    if ! git fetch origin master:refs/remotes/origin/master 2>&1; then
      git fetch origin || return 3
    fi
  fi

  if ! git rev-parse --verify origin/master >/dev/null 2>&1; then
    echo "(PGM) origin/master not found — cannot sync clone" >&2
    return 4
  fi

  head_sha="$(git rev-parse HEAD)"
  origin_sha="$(git rev-parse origin/master)"
  ahead=$(git rev-list --count origin/master..HEAD 2>/dev/null || echo 0)
  behind=$(git rev-list --count HEAD..origin/master 2>/dev/null || echo 0)

  echo "(PGM) Local HEAD:     ${head_sha:0:7} — $(git log -1 --format='%s' HEAD 2>/dev/null)"
  echo "(PGM) origin/master:  ${origin_sha:0:7} — $(git log -1 --format='%s' origin/master 2>/dev/null)"
  if (( ahead > 0 || behind > 0 )); then
    echo "(PGM) Branch status: ${ahead} ahead, ${behind} behind origin/master"
  fi

  if (( always_reset == 1 )); then
    need_reset=1
  elif [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
    need_reset=1
  elif [[ "${head_sha}" != "${origin_sha}" ]]; then
    need_reset=1
  fi

  if [[ "${head_sha}" != "${origin_sha}" ]]; then
    echo
    echo "Incoming changes (git diff --stat ${head_sha:0:7}..${origin_sha:0:7}):" | boxes -s 70x3 -a c
    echo
    git diff --stat "${head_sha}".."${origin_sha}"
    echo
  fi

  if (( need_reset == 1 )); then
    if [[ "${head_sha}" != "${origin_sha}" ]]; then
      if (( ahead > 0 )); then
        echo "(PGM) git reset --hard origin/master (${ahead} local commit(s) discarded)" | boxes -s 70x3 -a c
      elif (( behind > 0 )); then
        echo "(PGM) git reset --hard origin/master (${behind} commit(s) behind)" | boxes -s 70x3 -a c
      else
        echo "(PGM) git reset --hard origin/master" | boxes -s 70x3 -a c
      fi
    elif [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
      echo "(PGM) git reset --hard origin/master (discarding uncommitted changes)" | boxes -s 70x3 -a c
    else
      echo "(PGM) git reset --hard origin/master (refresh working tree)" | boxes -s 70x3 -a c
    fi
    git reset --hard origin/master || return 5
    git clean -fd
  else
    echo "(PGM) Clone already matches origin/master — no reset needed"
  fi

  echo "(PGM) Synced to: $(git rev-parse --short HEAD) — $(git log -1 --format='%s')"
  return 0
}

git_bin_init_context() {
  export github_project_name=github-bin
  _GIT_BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  git_bin_resolve_paths
}

git_bin_cleanup_bin_copies() {
  rm -v "${profile_root}/bin/git-bin.sh" \
        "${profile_root}/bin/git-pull.sh" "${profile_root}/bin/git-push.sh" "${profile_root}/bin/git-fetch.sh" \
        "${profile_root}/bin/git-bin-reset.sh" \
        "${profile_root}/bin/_git-bin-common.sh" \
        "${profile_root}/bin/_git-economist-common.sh" \
        "${profile_root}/bin/git-economist-pull.sh" "${profile_root}/bin/git-economist-push.sh" \
        "${profile_root}/bin/vmware-fix.sh" "${profile_root}/bin/65535" 2>/dev/null
  rm -v "${profile_root}/bin/"*talled*client 2>/dev/null
}

git_bin_confirm_yes() {
  local prompt="$1"
  echo
  echo "${prompt} [y/N]"
  if (( batch_mode == 0 )); then
    read -t 300 -n 1 p
  else
    echo "y (autoanswer in a batch mode)"
    p=y
  fi
  echo
  echo
  [[ "${p}" == 'y' || "${p}" == 'Y' ]]
}

# --- subcommands ---

cmd_pull() {
  if (( ! script_is_run_interactively )); then
    echo "${SCRIPT_VERSION}"
    echo
  fi

  git_bin_init_context
  echo "(PGM) GIT_REPO_DIRECTORY=${GIT_REPO_DIRECTORY}"
  git_bin_setup_ssh || exit 2

  if (( batch_mode == 1 )); then
    echo
    echo "(PGM) enabling batch mode (no questions asked)"
  fi

  git_bin_confirm_yes "Do you want to do kind of git pull and configure local scripts?" || {
    echo "no means no - I am exiting..."
    exit 1
  }

  mkdir -p "${profile_root}/github" "${profile_root}/bin"

  echo git ls-remote git+ssh://git@github.com/pmatuszy/"${github_project_name}".git | boxes -s 70x3 -a c
  git ls-remote git+ssh://git@github.com/pmatuszy/"${github_project_name}".git 2>&1 >/dev/null
  if (( $? != 0 )); then
    echo
    echo "No access to remote repository.... EXITING"
    echo
    exit 2
  fi

  if [[ ! -d "${GIT_REPO_DIRECTORY}/.git" ]]; then
    echo "git clone git+ssh://git@github.com/pmatuszy/${github_project_name}.git ${GIT_REPO_DIRECTORY}" | boxes -s 70x3 -a c
    git clone git+ssh://git@github.com/pmatuszy/"${github_project_name}".git "${GIT_REPO_DIRECTORY}" || {
      echo
      echo "Clone into ${GIT_REPO_DIRECTORY} was not successful... EXITING"
      echo
      exit 3
    }
  fi

  cd "${GIT_REPO_DIRECTORY}" || {
    echo
    echo "Cannot cd to ${GIT_REPO_DIRECTORY}... EXITING"
    echo
    exit 3
  }

  git_bin_sync_clone_to_origin 0 1 || {
    echo
    echo "Sync with origin/master was not successful... EXITING"
    echo
    exit 3
  }

  chmod +x ./git-bin.sh ./git-pull.sh ./git-push.sh ./git-fetch.sh 2>/dev/null || true

  echo "(PGM) Deploying clone -> ${profile_root}/bin" | boxes -s 70x3 -a c
  cp -a ./* "${profile_root}/bin/" || {
    echo "(PGM) ERROR: failed to copy scripts to ${profile_root}/bin" >&2
    exit 4
  }
  cp -a ./HOST-SPECIFIC/"$(hostname)"/* "${profile_root}/bin/" 2>/dev/null || true
  cp -a ./HOST-SPECIFIC/"$(hostname)".*com/* "${profile_root}/bin/" 2>/dev/null || true
  chmod +x "${profile_root}/bin"/*.sh 2>/dev/null || true
  cp -a ./HOST-SPECIFIC/"$(hostname)"*/.[a-zA-Z0-9]* "${profile_root}/" 2>/dev/null || true

  git_bin_cleanup_bin_copies

  echo "(PGM) Deploy complete. Example check: head -1 ${profile_root}/bin/watch-argonone-cli.sh"

  echo
  echo git status | boxes -s 40x3 -a c
  echo
  git status
}

cmd_push() {
  if (( ! script_is_run_interactively )); then
    echo "${SCRIPT_VERSION}"
    echo
  fi

  git_bin_init_context
  git_bin_setup_ssh || exit 2

  if [[ ! -d "${GIT_REPO_DIRECTORY}" ]]; then
    echo
    echo "(PGM) GIT_REPO_DIRECTORY = ${GIT_REPO_DIRECTORY} doesn't exist. Quitting..."
    echo
    exit 1
  fi

  keychain --nogui --nocolor id_rsa id_ed25519 id_SSH_ed25519_20230207_OpenSSH

  if (( batch_mode == 1 )); then
    echo
    echo "(PGM) enabling batch mode (no questions asked)"
  fi

  cd "${GIT_REPO_DIRECTORY}" || exit 2
  echo "github_project_name = ${github_project_name}"
  echo
  git remote set-url origin "git+ssh://git@github.com/pmatuszy/${github_project_name}.git"

  git_bin_confirm_yes "Do you want to do git push?" || {
    echo "no means no - I am exiting..."
    exit 1
  }

  git add --all * .[a-zA-Z]* 2>/dev/null || true
  git commit -a -m "new push from $(hostname) @ $(date '+%Y.%m.%d %H:%M:%S')" | boxes -s 90x6 -a l -d ada-box
  echo git push | boxes -s 40x3 -a c
  git push || {
    echo
    echo '(PGM) cannot push - exiting'
    echo
    exit 2
  }

  echo
  echo
  cmd_pull
}

cmd_fetch() {
  git_bin_init_context
  git_bin_setup_ssh || exit 2

  git_bin_confirm_yes "Do you want to do git fetch?" || {
    echo "no means no - I am exiting..."
    exit 1
  }

  if [[ ! -d "${GIT_REPO_DIRECTORY}" ]]; then
    echo
    echo "GIT_REPO_DIRECTORY = ${GIT_REPO_DIRECTORY} doesn't exist.... EXITING"
    echo
    exit 1
  fi

  cd "${GIT_REPO_DIRECTORY}" || exit 2

  git ls-remote "git+ssh://git@github.com/pmatuszy/${github_project_name}.git" 2>&1 >/dev/null
  if (( $? != 0 )); then
    echo
    echo "No access to remote repository.... EXITING"
    echo
    exit 2
  fi

  git fetch origin
  git status
}

cmd_reset() {
  git_bin_init_context
  echo "(PGM) GIT_REPO_DIRECTORY=${GIT_REPO_DIRECTORY}"

  if [[ ! -d "${GIT_REPO_DIRECTORY}/.git" ]]; then
    echo "(PGM) ${GIT_REPO_DIRECTORY} is not a git clone — run pull first" >&2
    exit 1
  fi

  git_bin_setup_ssh || exit 2

  git_bin_confirm_yes "Reset github-bin clone to origin/master (discards local commits and uncommitted changes)?" || {
    echo "no means no - I am exiting..."
    exit 1
  }

  cd "${GIT_REPO_DIRECTORY}" || exit 2

  if (( offline == 0 )); then
    git_bin_sync_clone_to_origin 0 || exit $?
  else
    echo "(PGM) --offline: skipping git fetch"
    git_bin_sync_clone_to_origin 1 || exit $?
  fi

  echo
  echo git status | boxes -s 40x3 -a c
  echo
  git status

  if (( no_deploy == 0 )); then
    echo
    echo "(PGM) running pull batch --no_startup_delay"
    batch_mode=1
    cmd_pull
  fi
}

# --- main ---

HEADER_EXTRA_ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --no_startup_delay) HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY); shift ;;
    *) break ;;
  esac
done

. /root/bin/_script_header.sh "${HEADER_EXTRA_ARGS[@]}"

batch_mode=0
no_deploy=0
offline=0
command=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help) show_help; exit 0 ;;
    -v|--version) print_version_banner; exit 0 ;;
    --no-deploy) no_deploy=1; shift ;;
    --offline) offline=1; shift ;;
    batch) batch_mode=1; shift ;;
    pull|push|fetch|reset)
      if [[ -n "${command}" ]]; then
        echo "Multiple commands specified" >&2
        exit 1
      fi
      command="$1"
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      echo "Try: $(basename "$0") --help" >&2
      exit 1
      ;;
  esac
done

if [[ -z "${command}" ]]; then
  echo "Missing COMMAND (pull|push|fetch|reset)" >&2
  echo "Try: $(basename "$0") --help" >&2
  exit 1
fi

case "${command}" in
  pull)  cmd_pull ;;
  push)  cmd_push ;;
  fetch) cmd_fetch ;;
  reset) cmd_reset ;;
esac

if [[ "${command}" != fetch ]]; then
  . /root/bin/_script_footer.sh
fi
