#!/usr/bin/env python3
"""Remove _script_version.sh loaders; source _script_header.sh before -v/--version."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKIP_DIRS = {"_oldy", ".git"}

LOADER = re.compile(
    r"\nfor _svd in \"\$\{BASH_SOURCE\[0\]%/\*\}\" \"/root/github/github-bin\" \"/root/bin\"; do\n"
    r"  if \[\[ -f \"\$\{_svd\}/_script_version\.sh\" \]\]; then\n"
    r"    # shellcheck source=/dev/null\n"
    r"    \. \"\$\{_svd\}/_script_version\.sh\"\n"
    r"    break\n"
    r"  fi\n"
    r"done\n\n?",
    re.MULTILINE,
)

PRE_HEADER_LOOP = """HEADER_EXTRA_ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --no_startup_delay) HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY); shift ;;
    *) break ;;
  esac
done

. /root/bin/_script_header.sh "${HEADER_EXTRA_ARGS[@]}"

"""

PRE_HEADER_LOOP_INDENT4 = """HEADER_EXTRA_ARGS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        --no_startup_delay) HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY); shift ;;
        *) break ;;
    esac
done

if [[ -f /root/bin/_script_header.sh ]]; then
    # shellcheck disable=SC1091
    . /root/bin/_script_header.sh "${HEADER_EXTRA_ARGS[@]}"
fi

"""


def remove_loader(text: str) -> str:
    return LOADER.sub("\n", text)


def split_simple_cli_loop(text: str) -> str:
    """Healthchecks/cron: move -h/-v after _script_header.sh."""
    pattern = re.compile(
        r"(HEADER_EXTRA_ARGS=\(\)\n)"
        r"while \[\[ \$# -gt 0 \]\]; do\n"
        r"  case \$1 in\n"
        r"    -h\|--help\) show_help; exit 0 ;;\n"
        r"    -v\|--version\) print_version_banner; exit 0 ;;\n"
        r"    --no_startup_delay\) HEADER_EXTRA_ARGS\+=\(NO_STARTUP_DELAY\); shift ;;\n"
        r"    \*\) echo \"Unknown argument: \$1\" >&2; echo \"Try: \$\(basename \"\$0\"\) --help\" >&2; exit 1 ;;\n"
        r"  esac\n"
        r"done\n\n"
        r"\. /root/bin/_script_header\.sh \"\$\{HEADER_EXTRA_ARGS\[@\]\}\"\n",
        re.MULTILINE,
    )
    repl = (
        PRE_HEADER_LOOP
        + "while [[ $# -gt 0 ]]; do\n"
        + "  case $1 in\n"
        + "    -h|--help) show_help; exit 0 ;;\n"
        + "    -v|--version) print_version_banner; exit 0 ;;\n"
        + "    *) echo \"Unknown argument: $1\" >&2; echo \"Try: $(basename \"$0\") --help\" >&2; exit 1 ;;\n"
        + "  esac\n"
        + "done\n"
    )
    return pattern.sub(repl, text, count=1)


def split_ffmpeg_loop(text: str) -> str:
    marker = "HEADER_EXTRA_ARGS=()\nwhile [[ $# -gt 0 ]]; do\n    case $1 in\n        -h|--help)"
    if marker not in text or PRE_HEADER_LOOP_INDENT4.strip() in text:
        return text
    old = (
        "HEADER_EXTRA_ARGS=()\n"
        "while [[ $# -gt 0 ]]; do\n"
        "    case $1 in\n"
        "        -h|--help) show_help; exit 0 ;;\n"
        "        -v|--version) print_version_banner; exit 0 ;;\n"
    )
    if old not in text:
        return text
    text = text.replace(
        "        --no_startup_delay) HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY); shift ;;\n",
        "",
        1,
    )
    text = text.replace(
        "done\n\nif [[ -f /root/bin/_script_header.sh ]]; then\n"
        "    # shellcheck disable=SC1091\n"
        "    . /root/bin/_script_header.sh \"${HEADER_EXTRA_ARGS[@]}\"\n"
        "fi\n",
        "done\n\n",
        1,
    )
    idx = text.find("HEADER_EXTRA_ARGS=()\nwhile [[ $# -gt 0 ]]; do")
    if idx == -1:
        return text
    return text[:idx] + PRE_HEADER_LOOP_INDENT4 + text[idx:]


def fix_cpu_stress_test(text: str) -> str:
    old = """HEADER_EXTRA_ARGS=()
DURATION_CLI=""
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      exit 0
      ;;
    -v|--version)
      print_version_banner
      exit 0
      ;;
    --no_startup_delay)
      HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY)
      shift
      ;;
"""
    if old not in text:
        return text
    new = """HEADER_EXTRA_ARGS=()
DURATION_CLI=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --no_startup_delay)
      HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY)
      shift
      ;;
    *) break ;;
  esac
done

. /root/bin/_script_header.sh "${HEADER_EXTRA_ARGS[@]}"

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      exit 0
      ;;
    -v|--version)
      print_version_banner
      exit 0
      ;;
"""
    text = text.replace(old, new, 1)
    return text.replace(
        "done\n\n. /root/bin/_script_header.sh \"${HEADER_EXTRA_ARGS[@]}\"\n\n",
        "done\n\n",
        1,
    )


def fix_git_bin(text: str) -> str:
    text = remove_loader(text)
    text = text.replace(
        "# v. 20260716.163300 - versioning v. YYYYMMDD.HH24MISS; shared _script_version.sh for -v banner\n",
        "# v. 20260716.173600 - print_version_banner from _script_header.sh (source before -v)\n",
        1,
    )
    old_main = """# --- main ---

HEADER_EXTRA_ARGS=()
batch_mode=0
no_deploy=0
offline=0
command=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help) show_help; exit 0 ;;
    -v|--version) print_version_banner; exit 0 ;;
    --no_startup_delay) HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY); shift ;;
"""
    new_main = """# --- main ---

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
"""
    if old_main not in text:
        return text
    text = text.replace(old_main, new_main, 1)
    text = text.replace(
        "if [[ \"${command}\" == fetch ]]; then\n"
        "  set -o nounset\n"
        "  set -o pipefail\n"
        "else\n"
        "  . /root/bin/_script_header.sh \"${HEADER_EXTRA_ARGS[@]}\"\n"
        "fi\n\n",
        "",
        1,
    )
    return text


def fix_rename(text: str) -> str:
    text = remove_loader(text)
    text = text.replace(
        "        --version)\n"
        "            print_version_banner\n"
        "            exit 0\n"
        "            ;;\n",
        "        --version)\n"
        "            # shellcheck disable=SC1091\n"
        "            . /root/bin/_script_header.sh NO_STARTUP_DELAY\n"
        "            print_version_banner\n"
        "            exit 0\n"
        "            ;;\n",
        1,
    )
    return text


def process(path: Path) -> bool:
    if any(part in SKIP_DIRS for part in path.parts):
        return False
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return False
    if "_script_version.sh" not in text and path.name != "git-bin.sh":
        return False

    original = text
    if path.name == "git-bin.sh":
        text = fix_git_bin(text)
    elif path.name == "rename.sh":
        text = fix_rename(text)
    elif path.name == "ffmpeg-install.sh":
        text = remove_loader(text)
        text = split_ffmpeg_loop(text)
    elif path.name == "cpu-stress-test.sh":
        text = remove_loader(text)
        text = fix_cpu_stress_test(text)
    else:
        text = remove_loader(text)
        text = split_simple_cli_loop(text)

    if text == original:
        return False
    path.write_text(text, encoding="utf-8", newline="\n")
    return True


def main() -> None:
    changed = []
    for path in sorted(ROOT.rglob("*.sh")):
        if process(path):
            changed.append(path.relative_to(ROOT))
    print(f"Updated {len(changed)} script(s)")
    for p in changed:
        print(f"  {p}")


if __name__ == "__main__":
    main()
