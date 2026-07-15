#!/bin/bash
# Shared path helpers for git-pull.sh, git-push.sh, git-fetch.sh (sourced, not executed).

git_bin_resolve_paths() {
  local caller script_dir parent github_project_name="${github_project_name:-github-bin}"

  export github_project_name

  caller="${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}"
  script_dir="$(cd "$(dirname "${caller}")" && pwd -P)"

  if [[ -d "${script_dir}/.git" ]]; then
    export GIT_REPO_DIRECTORY="${script_dir}"
    if [[ "$(basename "${script_dir}")" == "${github_project_name}" ]]; then
      parent="$(dirname "${script_dir}")"
      if [[ "$(basename "${parent}")" == "github" ]]; then
        export profile_root="$(cd "$(dirname "${parent}")" && pwd -P)"
      else
        export profile_root="$(cd "${parent}" && pwd -P)"
      fi
    else
      export profile_root="${profile_location_dir:-$HOME}"
    fi
    return 0
  fi

  export profile_root="${profile_location_dir:-$HOME}"
  export GIT_REPO_DIRECTORY="${profile_root}/github/${github_project_name}"

  local legacy
  for legacy in \
    "${profile_root}/github/${github_project_name}" \
    "${profile_root}/github-bin" \
    "${profile_root}/${github_project_name}"; do
    [[ -d "${GIT_REPO_DIRECTORY}/.git" ]] && return 0
    [[ -d "${legacy}/.git" ]] || continue
    export GIT_REPO_DIRECTORY="${legacy}"
    return 0
  done
}
