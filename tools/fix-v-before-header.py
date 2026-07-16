#!/usr/bin/env python3
"""Fix scripts that call print_version_banner before _script_header.sh."""

from __future__ import annotations

import re
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TS = datetime.now().strftime("%Y%m%d.%H%M%S")
TOP = f"# v. {TS} - source _script_header.sh before -v (print_version_banner)\n"

OLD = re.compile(
    r"(# --- parse[^\n]*---\n)?"
    r"HEADER_EXTRA_ARGS=\(\)\n"
    r"while \[\[ \$# -gt 0 \]\]; do\n"
    r"  case \$1 in\n"
    r"    -h\|--help\)\n"
    r"      show_help\n"
    r"      exit 0\n"
    r"      ;;\n"
    r"    -v\|--version\)\n"
    r"      print_version_banner\n"
    r"      exit 0\n"
    r"      ;;\n"
    r"    --no_startup_delay\)\n"
    r"      HEADER_EXTRA_ARGS\+=\(NO_STARTUP_DELAY\)\n"
    r"      shift\n"
    r"      ;;\n"
    r"    \*\)\n"
    r'      echo "Unknown argument: \$1" >&2\n'
    r'      echo "Try: \$\(basename "\$0"\) --help" >&2\n'
    r"      exit 1\n"
    r"      ;;\n"
    r"  esac\n"
    r"done\n\n"
    r'\. /root/bin/_script_header\.sh "\$\{HEADER_EXTRA_ARGS\[@\]\}"\n',
    re.MULTILINE,
)

NEW = """# --- parse --no_startup_delay, then header, then -h/-v ---
HEADER_EXTRA_ARGS=()
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
    *)
      echo "Unknown argument: $1" >&2
      echo "Try: $(basename "$0") --help" >&2
      exit 1
      ;;
  esac
done

"""


def main() -> None:
    fixed: list[str] = []
    for path in sorted(ROOT.rglob("*.sh")):
        if "_oldy" in path.parts:
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        if not OLD.search(text):
            continue
        new_text = OLD.sub(NEW, text, count=1)
        lines = new_text.splitlines(keepends=True)
        if len(lines) > 1 and lines[1].startswith("# v. "):
            lines = [lines[0], TOP, *lines[2:]]
        else:
            lines = [lines[0], TOP, *lines[1:]]
        path.write_text("".join(lines), encoding="utf-8", newline="\n")
        fixed.append(path.relative_to(ROOT).as_posix())
    print(f"Fixed {len(fixed)} script(s)")
    for name in fixed:
        print(f"  {name}")


if __name__ == "__main__":
    main()
