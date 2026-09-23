# github-bin

A personal collection of standalone Bash sysadmin/utility scripts (`.sh`) for
managing Linux servers and Raspberry Pi hosts. There is no build system, package
manager, test suite, or CI — the "application" is the scripts themselves.

## Cursor Cloud specific instructions

### Layout / how scripts work
- Most scripts source shared helpers via a hardcoded absolute path:
  `. /root/bin/_script_header.sh` and `. /root/bin/_script_footer.sh`. In this
  repo those files live at the repo root, and the environment provides a
  `/root/bin` → repo-root symlink so scripts run unmodified. If a script fails
  with "No such file or directory" for `/root/bin/_script_header.sh`, recreate
  the symlink: `sudo ln -sfn "$PWD" /root/bin` from the repo root.
- `_script_header.sh` enables `set -o nounset`/`pipefail`, sets `LC_ALL=C`, and
  requires the `figlet` and `boxes` utilities (installed by the update script).
  `boxes` is always used (version banner); `figlet` is only used on a real TTY.
- The header adds a random startup delay when run non-interactively. Pass
  `--no_startup_delay` (or `NO_STARTUP_DELAY`) to skip it when scripting/testing.
- `HOST-SPECIFIC/<hostname>/` holds per-host overrides; many scripts target real
  hardware/servers (Raspberry Pi, ADSB, ZFS, VMware, backups) and cannot run
  meaningfully in this VM. Prefer self-contained scripts for smoke tests, e.g.
  `./32or64.sh --no_startup_delay`, `./date-show.sh -h`, `./cpu-temp.sh -h`.

### Lint / test / run
- Lint: `shellcheck <script>.sh`. Note several files intentionally embed crontab
  lines inside comments and one lacks a shebang, so repo-wide `shellcheck` will
  report pre-existing SC1064/SC1065/SC1073/SC2148 findings that are not caused by
  your changes — lint individual scripts you touch instead.
- There is no automated test suite. "Testing" means running a script end-to-end
  and inspecting its output.
- Run: execute a script directly (e.g. `./32or64.sh`). To see the interactive
  `figlet` banner path when there is no TTY, wrap it:
  `script -qec "./32or64.sh --no_startup_delay" /dev/null`.
