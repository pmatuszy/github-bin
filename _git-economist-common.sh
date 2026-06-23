#!/bin/bash
# Shared helpers for git-economist-pull.sh and git-economist-push.sh (sourced, not executed).

# Server layout (override with env if needed):
#   /root/repos/github-economist-weekly-audio/
#   /root/repos/github-economist-weekly-audio-private/

git_economist_setup_ssh() {
  export GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-ssh -i \$HOME/.ssh/id_SSH_ed25519_20230207_OpenSSH}"

  check_if_installed keychain

  eval keychain -q --nogui --nocolor --eval id_rsa id_ed25519 id_SSH_ed25519_20230207_OpenSSH 2>&1

  if [[ -f "${HOME}/.keychain/${HOSTNAME}-sh" ]]; then
    # shellcheck source=/dev/null
    . "${HOME}/.keychain/${HOSTNAME}-sh"
  fi
}

git_economist_init_paths() {
  export ECONOMIST_GIT_ROOT="${ECONOMIST_GIT_ROOT:-/root/repos}"
  export ECONOMIST_PUBLIC_DIR_NAME="${ECONOMIST_PUBLIC_DIR_NAME:-github-economist-weekly-audio}"
  export ECONOMIST_PRIVATE_DIR_NAME="${ECONOMIST_PRIVATE_DIR_NAME:-github-economist-weekly-audio-private}"
  export ECONOMIST_PUBLIC_REPO="${ECONOMIST_GIT_ROOT}/${ECONOMIST_PUBLIC_DIR_NAME}"
  export ECONOMIST_PRIVATE_REPO="${ECONOMIST_GIT_ROOT}/${ECONOMIST_PRIVATE_DIR_NAME}"
  export ECONOMIST_GITHUB_USER="${ECONOMIST_GITHUB_USER:-pmatuszy}"
  export ECONOMIST_PUBLIC_GIT_URL="git+ssh://git@github.com/${ECONOMIST_GITHUB_USER}/economist-weekly-audio.git"
  export ECONOMIST_PRIVATE_GIT_URL="git+ssh://git@github.com/${ECONOMIST_GITHUB_USER}/economist-weekly-audio-private.git"
}

git_economist_repo_is_dirty() {
  local dir="$1"
  [[ -d "${dir}/.git" ]] || return 1
  [[ -n "$(git -C "${dir}" status --porcelain 2>/dev/null)" ]]
}

git_economist_check_remote() {
  local url="$1" label="$2"
  echo "git ls-remote ${url}" | boxes -s 70x3 -a c
  git ls-remote "${url}" >/dev/null 2>&1
  if (( $? != 0 )); then
    echo
    echo "No access to ${label} remote repository.... EXITING"
    echo
    return 2
  fi
  return 0
}

git_economist_sync_one_repo() {
  local dir="$1" url="$2" label="$3"
  local rc=0

  mkdir -p "${ECONOMIST_GIT_ROOT}"

  if [[ ! -d "${dir}/.git" ]]; then
    echo "git clone ${url} ${dir}" | boxes -s 70x3 -a c
    git clone "${url}" "${dir}" || rc=$?
  else
    echo "git -C ${dir} pull ${url}" | boxes -s 70x3 -a c
    git -C "${dir}" pull "${url}" || rc=$?
  fi

  if (( rc != 0 )); then
    echo
    echo "${label}: sync was not successful... EXITING"
    echo
    return 3
  fi
  return 0
}

git_economist_post_pull_setup() {
  local scripts_dir="${ECONOMIST_PUBLIC_REPO}/scripts"
  if [[ -d "${scripts_dir}" ]]; then
    chmod 700 "${scripts_dir}"/*.sh 2>/dev/null || true
  fi
}

git_economist_print_status() {
  local dir="$1" label="$2"
  echo
  echo "${label} — git status" | boxes -s 50x3 -a c
  echo
  if [[ -d "${dir}/.git" ]]; then
    git -C "${dir}" status
  else
    echo "(repository not present at ${dir})"
  fi
  echo
}

git_economist_push_repo() {
  local dir="$1" url="$2" label="$3"
  local rc=0

  if [[ ! -d "${dir}/.git" ]]; then
    echo "${label}: ${dir} does not exist — run git-economist-pull.sh first"
    return 1
  fi

  git -C "${dir}" remote set-url origin "${url}"

  if ! git_economist_repo_is_dirty "${dir}"; then
    echo "${label}: nothing to commit"
    return 0
  fi

  git -C "${dir}" add --all * .[a-zA-Z]* 2>/dev/null || true
  git -C "${dir}" add -A

  git -C "${dir}" commit -a -m "push from $(hostname) @ $(date '+%Y.%m.%d %H:%M:%S')" \
    | boxes -s 90x6 -a l -d ada-box

  echo "git push (${label})" | boxes -s 40x3 -a c
  git -C "${dir}" push || rc=$?

  if (( rc != 0 )); then
    echo
    echo "${label}: cannot push — exiting"
    echo
    return 2
  fi
  return 0
}
