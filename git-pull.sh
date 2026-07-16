#!/bin/bash

# 2026.07.16 - v. 2.0 - chmod +x *.sh in bin after copy (git mode 644 must not break cron)
# 2026.07.16 - v. 1.9 - drop post-pull hooks (fleet migrations via Ansible on control host)
# 2026.07.15 - v. 1.8 - never use flat ${profile_root}/github-bin; self-detect repo from script path
# 2026.07.15 - v. 1.7 - script header: changelog block + description block
# 2026.07.15 - v. 1.6 - resolve repo from script dir; legacy /root/github-bin fallback
# 2026.07.15 - v. 1.5 - bin/repo paths: ${profile_location_dir:-$HOME}; profile_location_dir unset → $HOME
# 2026.07.15 - v. 1.4 - ensure ${profile_location_dir}/github/github-bin exists; cd with error check
# 2026.07.15 - v. 1.3 - GIT_REPO_DIRECTORY: ${profile_location_dir}/github/github-bin
# 2026.07.15 - v. 1.2 - GIT_REPO_DIRECTORY: $HOME/github/github-bin (was $HOME/github-bin)
# 2026.06.02 - v. 1.1 - add -h/--help, -v/--version, --no_startup_delay (parsed before header)
# 2026.05.26 - user-facing messages translated from Polish to English
# 2023.02.18 - v. 1.0 - some minor changes like printing script version in non-interactive mode
# 2023.02.11 - v. 1.0 - added GIT_SSH_COMMAND
# 2023.02.07 - v. 0.9 - added batch mode
# 2023.01.24 - v. 0.8 - added 2>/dev/null to one of the cp commands, size of the boxes width changed from 40 to 70
# 2023.01.13 - v. 0.7 - git clone is replaced with git pull, some small changes 
# 2022.12.13 - v. 0.6 - hostname specified with start (works with or without domainaname)
# 2022.09.30 - v. 0.5 - checking if we have access to remote repo
# 2022.05.18 - v. 0.4 - added removing git-pull.sh and gill-push.sh from $HOME/bin
#                       added set -o options at the beginning
# 2021.05.12 - v. 0.3 - added copying .[a-zA-Z0-9]
# 2021.04.08 - v. 0.2 - added HOST-SPECIFIC directory copy
# 2020.11.27 - v. 0.1 - initial release
#
# git-pull.sh
#
# Pull github-bin from GitHub; install scripts to ${profile_location_dir:-$HOME}/bin.
# Repo: ${profile_location_dir:-$HOME}/github/github-bin only (never ${profile_root}/github-bin).
#

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

Pull github-bin (and related local scripts) from the remote repository.

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  --no_startup_delay   Skip random startup delay when run non-interactively.

Arguments:
  batch                Non-interactive mode: auto-answer yes to prompts (for cron).
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

if (( ! script_is_run_interactively ));then    # jesli nie interaktywnie, to chcemy wyswietlic info, by poszlo do logow
  echo "${SCRIPT_VERSION}";echo 
fi

export github_project_name=github-bin
_GIT_BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_git-bin-common.sh
if [[ -f "${_GIT_BIN_DIR}/_git-bin-common.sh" ]]; then
  . "${_GIT_BIN_DIR}/_git-bin-common.sh"
  git_bin_resolve_paths
else
  # Bootstrap when helper not deployed yet: script inside clone is authoritative.
  export profile_root="${profile_location_dir:-$HOME}"
  if [[ -d "${_GIT_BIN_DIR}/.git" ]]; then
    export GIT_REPO_DIRECTORY="${_GIT_BIN_DIR}"
    if [[ "$(basename "$(dirname "${_GIT_BIN_DIR}")")" == "github" ]]; then
      export profile_root="$(cd "${_GIT_BIN_DIR}/../.." && pwd -P)"
    fi
  else
    export GIT_REPO_DIRECTORY="${profile_root}/github/${github_project_name}"
  fi
fi

echo "(PGM) GIT_REPO_DIRECTORY=${GIT_REPO_DIRECTORY}"

export GIT_SSH_COMMAND='ssh -i $HOME/.ssh/id_SSH_ed25519_20230207_OpenSSH'

check_if_installed keychain

eval keychain -q --nogui --nocolor --eval id_rsa id_ed25519 id_SSH_ed25519_20230207_OpenSSH 2>&1

if [ -f $HOME/.keychain/$HOSTNAME-sh ];then
  . $HOME/.keychain/$HOSTNAME-sh
fi

if (( batch_mode == 1 )); then
  echo ; echo "(PGM) enabling batch mode (no questions asked)"
fi

echo
echo "Do you want to do kind of git pull and configure local scripts? [y/N]"

if (( $batch_mode == 0 ));then
  read -t 300 -n 1 p     # read one character (-n) with timeout of 300 seconds
else
  echo "y (autoanswer in a batch mode)"
  p=y # batch mode ==> we set the answer to 'y'
fi
echo
echo
if [ "${p}" == 'y' -o  "${p}" == 'y' ]; then
  mkdir -p "${profile_root}/github" "${profile_root}/bin"

  # sprawdzam, czy mam dostep do zdalnego repo
  echo git ls-remote git+ssh://git@github.com/pmatuszy/"${github_project_name}".git | boxes -s 70x3 -a c
  git ls-remote git+ssh://git@github.com/pmatuszy/"${github_project_name}".git 2>&1 >/dev/null
  if (( $? != 0 )); then
    echo  ; echo ; echo "No access to remote repository.... EXITING" ; echo ; echo
    exit 2
  fi

  if [[ ! -d "${GIT_REPO_DIRECTORY}/.git" ]]; then
    echo "git clone git+ssh://git@github.com/pmatuszy/${github_project_name}.git ${GIT_REPO_DIRECTORY}" | boxes -s 70x3 -a c
    git clone git+ssh://git@github.com/pmatuszy/"${github_project_name}".git "${GIT_REPO_DIRECTORY}" || {
      echo  ; echo ; echo "Clone into ${GIT_REPO_DIRECTORY} was not successful... EXITING" ; echo ; echo
      exit 3
    }
  fi

  cd "${GIT_REPO_DIRECTORY}" || {
    echo  ; echo ; echo "Cannot cd to ${GIT_REPO_DIRECTORY}... EXITING" ; echo ; echo
    exit 3
  }

  echo git pull git+ssh://git@github.com/pmatuszy/"${github_project_name}".git | boxes -s 70x3 -a c

  git pull git+ssh://git@github.com/pmatuszy/"${github_project_name}".git
  if (( $? != 0 )); then
    echo  ; echo ; echo "Pull was not successful... EXITING" ; echo ; echo
    exit 3
  fi

  cp ./* "${profile_root}/bin" 2>/dev/null
  cp ./HOST-SPECIFIC/`hostname`/* "${profile_root}/bin" 2>/dev/null
  cp ./HOST-SPECIFIC/`hostname`.*com/* "${profile_root}/bin" 2>/dev/null

  chmod +x "${profile_root}/bin"/*.sh 2>/dev/null

  # we copy hidden files to profile root ($HOME when profile_location_dir unset)
  cp ./HOST-SPECIFIC/`hostname`*/.[a-zA-Z0-9]* "${profile_root}"   2>/dev/null

  # cleanup
  rm -v "${profile_root}/bin/git-pull.sh" "${profile_root}/bin/git-push.sh" "${profile_root}/bin/git-fetch.sh" "${profile_root}/bin/vmware-fix.sh" "${profile_root}/bin/65535" 2>/dev/null
  rm -v "${profile_root}/bin/"*talled*client 2>/dev/null
  echo 
  echo git status | boxes -s 40x3 -a c
  echo 
  git status
else
  echo "no means no - I am exiting..."
  exit 1
fi

. /root/bin/_script_footer.sh
 
