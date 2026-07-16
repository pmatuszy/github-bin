#!/usr/bin/env python3
"""Add v. YYYYMMDD.HHMMSS changelog line; centralize print_version_banner."""

from __future__ import annotations

import re
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TS = datetime.now().strftime("%Y%m%d.%H%M%S")
NEW_LINE = f"# v. {TS} - versioning format v. YYYYMMDD.HH24MISS\n"
NEW_FORMAT = re.compile(r"^# v\. [0-9]{8}\.[0-9]{6} - ")
SHEBANG = re.compile(r"^#![^\n]*\n")

LOADER = """for _svd in "${BASH_SOURCE[0]%/*}" "/root/github/github-bin" "/root/bin"; do
  if [[ -f "${_svd}/_script_version.sh" ]]; then
    # shellcheck source=/dev/null
    . "${_svd}/_script_version.sh"
    break
  fi
done
"""

PRINT_FN = re.compile(
    r"^print_version_banner\(\) \{\n.*?^\}\n",
    re.MULTILINE | re.DOTALL,
)

SKIP_DIRS = {"_oldy"}


def should_process(path: Path) -> bool:
    if any(part in SKIP_DIRS for part in path.parts):
        return False
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return False
    return text.startswith("#!")


def insert_version_line(text: str) -> str:
    if NEW_FORMAT.match(text.split("\n", 2)[1] if "\n" in text else ""):
        return text
    lines = text.splitlines(keepends=True)
    if not lines or not lines[0].startswith("#!"):
        if NEW_FORMAT.search(text):
            return text
        return NEW_LINE + text
    out = [lines[0]]
    rest = lines[1:]
    if rest and NEW_FORMAT.match(rest[0]):
        return text
    out.append(NEW_LINE)
    out.extend(rest)
    return "".join(out)


def replace_print_banner(text: str, path: Path) -> str:
    if path.name == "_script_version.sh":
        return text
    if "print_version_banner()" not in text:
        return text
    if PRINT_FN.search(text):
        return PRINT_FN.sub(LOADER, text, count=1)
    return text


def main() -> None:
    changed = 0
    for path in sorted(ROOT.rglob("*.sh")):
        if not should_process(path):
            continue
        original = path.read_text(encoding="utf-8", errors="replace")
        updated = insert_version_line(original)
        updated = replace_print_banner(updated, path)
        if updated != original:
            path.write_text(updated, encoding="utf-8", newline="\n")
            changed += 1
            print(path.relative_to(ROOT))
    print(f"Updated {changed} files (timestamp {TS})")


if __name__ == "__main__":
    main()
