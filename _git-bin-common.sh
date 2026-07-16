#!/bin/bash

# 2026.07.16 - v. 0.3 - git_bin_run_post_pull_hooks: run idempotent migrate-* scripts after git-pull copy
# 2026.07.15 - v. 0.2 - canonical repo only: ${profile_root}/github/github-bin; drop flat github-bin
# 2026.07.15 - v. 0.1 - git_bin_resolve_paths: script dir, profile_location_dir:-HOME, legacy github-bin
#
# _git-bin-common.sh
#
# Shared path helpers for git-pull.sh, git-push.sh, git-fetch.sh (sourced, not executed).
# Canonical repo: ${profile_location_dir:-$HOME}/github/github-bin (never ${profile_root}/github-bin).
#

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

git_bin_run_post_pull_hooks() {
  local profile_root_val="${1:?profile_root required}" hook hook_path rc=0

  for hook in migrate-reboot-cron-once.sh; do
    hook_path="${profile_root_val}/bin/${hook}"
    if [[ ! -f "${hook_path}" ]]; then
      continue
    fi
    echo
    echo "(PGM) post-pull hook: ${hook}" | boxes -s 70x3 -a c
    echo
    if [[ -x "${hook_path}" ]]; then
      "${hook_path}" || rc=$?
    else
      bash "${hook_path}" || rc=$?
    fi
    if (( rc != 0 )); then
      echo "(PGM) warning: ${hook} exited ${rc} (git-pull continues)" >&2
      rc=0
    fi
  done
  return 0
}
