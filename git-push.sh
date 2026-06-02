#!/bin/bash
 
# 2026.06.02 - v. 1.3 - add -h/--help, -v/--version, --no_startup_delay (parsed before header)
# 2023.02.11 - v. 1.2 - added GIT_SSH_COMMAND
# 2023.02.07 - v. 1.1 - added batch mode, added GIT_REPO_DIRECTORY variable
# 2023.01.26 - v. 1.0 - fixed script version print
# 2022.10.27 - v. 0.9 - added printing of the script version
# 2022.05.18 - v. 0.8 - added set -o options at the beginning
# 2021.04.08 - v. 0.8 - now calling git-pull.sh instead of duplicating its functionality here
# 2021.04.08 - v. 0.8 - now calling git-pull.sh instead of duplicating its functionality here
# 2021.02.18 - v. 0.7 - added exit code check after git push
# 2021.02.07 - v. 0.6 - git add --all * .[a-zA-Z]* , git remote set-url origin git+ssh: to not have
# 2021.02.07 - v. 0.6 - git add --all * .[a-zA-Z]* , git remote set-url origin git+ssh: to not have
#                       password prompts during pushes
# 2021.02.05 - v. 0.5 - git add --all * .[a-zA-Z]* 
# 2021.02.03 - v. 0.4 - added commit "-a" option so deleted files will be deleted from repo as well
# 2020.11.27 - v. 0.3 - changed rm to remove files from the directory not the whole directory
# 2020.11.26 - v. 0.2 - added second section with 'git pull'
# 2020.10.20 - v. 0.1 - initial release

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

Push local changes in github-bin to the remote repository.

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
export GIT_REPO_DIRECTORY=/root/"${github_project_name}"
export GIT_SSH_COMMAND='ssh -i $HOME/.ssh/id_SSH_ed25519_20230207_OpenSSH'

if [ ! -d "${GIT_REPO_DIRECTORY}" ];then
  echo ; echo "(PGM) GIT_REPO_DIRECTORY = $GIT_REPO_DIRECTORY doesn't exist. Quitting..." ; echo
  exit 1
fi

check_if_installed keychain

eval keychain -q --nogui --nocolor --eval id_rsa id_ed25519 id_SSH_ed25519_20230207_OpenSSH >/dev/null 2>&1

if [ -f $HOME/.keychain/$HOSTNAME-sh ];then
  . $HOME/.keychain/$HOSTNAME-sh
fi

keychain --nogui --nocolor id_rsa id_ed25519 id_SSH_ed25519_20230207_OpenSSH

if (( batch_mode == 1 )); then
  echo ; echo "(PGM) enabling batch mode (no questions asked)"
fi

cd "${GIT_REPO_DIRECTORY}" || exit 2

echo "github_project_name = $github_project_name"; echo

git remote set-url origin git+ssh://git@github.com/pmatuszy/${github_project_name}.git

echo "Do you want to do git push? [y/N]"
if (( $batch_mode == 0 ));then
  read -t 300 -n 1 p     # read one character (-n) with timeout of 300 seconds
else
  echo "y (autoanswer in a batch mode)"
  p=y # batch mode ==> we set the answer to 'y'
fi

echo
echo
if [ "${p}" == 'y' -o  "${p}" == 'y' ]; then
  git add --all * .[a-zA-Z]*
  git commit -a -m \""new push from `hostname` @ `date '+%Y.%m.%d %H:%M:%S'`"\" | boxes -s 90x6 -a l -d ada-box
  echo git push | boxes -s 40x3 -a c
  git push 
  if (( $? != 0 )); then
    echo ; echo '(PGM) cannot push - exiting' ; echo
    exit 2
  fi
else
  echo "no means no - I am exiting..."
  exit 1
fi
echo
echo

if (( $batch_mode == 0 ));then
  ./git-pull.sh
else
  ./git-pull.sh batch
fi

. /root/bin/_script_footer.sh
