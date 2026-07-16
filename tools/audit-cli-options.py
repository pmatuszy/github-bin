#!/usr/bin/env python3
"""List *.sh scripts missing -h/--help and/or -v/--version CLI handling."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKIP_PARTS = {"_oldy", ".git"}
SKIP_NAMES = {
    "_script_header.sh",
    "_script_footer.sh",
    "_smart_disk_discovery.sh",
}


def should_skip(path: Path) -> bool:
    if path.name in SKIP_NAMES:
        return True
    return any(part in SKIP_PARTS for part in path.parts)


def analyze(text: str) -> tuple[bool, bool, bool]:
    has_help = bool(
        re.search(r"-h\|--help", text)
        or re.search(r'case \$1 in[\s\S]{0,200}?--help', text)
        or (re.search(r"\bshow_help\b", text) and re.search(r"--help|\-h", text))
    )
    has_version = bool(
        re.search(r"-v\|--version", text)
        or re.search(r"--version\)", text)
        or re.search(r"print_version_banner", text)
    )
    v_is_verbose = bool(re.search(r"-v\|--verbose", text)) and not re.search(
        r"-v\|--version", text
    )
    return has_help, has_version, v_is_verbose


def main() -> None:
    rows: list[tuple[str, bool, bool, bool]] = []
    for path in sorted(ROOT.rglob("*.sh")):
        if should_skip(path):
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        if not text.startswith("#!"):
            continue
        rel = path.relative_to(ROOT).as_posix()
        rows.append((rel, *analyze(text)))

    missing_both = [r for r in rows if not r[1] and not r[2]]
    missing_help_only = [r for r in rows if not r[1] and r[2]]
    missing_version_only = [r for r in rows if r[1] and not r[2]]
    missing_either = [r for r in rows if not r[1] or not r[2]]
    has_both = [r for r in rows if r[1] and r[2]]
    v_verbose = [r for r in rows if r[3]]

    print(f"Total scripts analyzed: {len(rows)}")
    print(f"Both -h/--help and -v/--version: {len(has_both)}")
    print(f"Missing either: {len(missing_either)}")
    print()
    print("=== Missing BOTH help and version ===")
    for rel, *_ in missing_both:
        print(rel)
    print()
    print("=== Has version but NO help ===")
    for rel, *_ in missing_help_only:
        print(rel)
    print()
    print("=== Has help but NO version ===")
    for rel, *_ in missing_version_only:
        print(rel)
    print()
    print("=== HAS BOTH help and version ===")
    for rel, *_ in sorted(has_both, key=lambda r: r[0]):
        print(rel)
    print()
    print("=== -v means verbose (not --version) ===")
    for rel, *_ in v_verbose:
        print(rel)


if __name__ == "__main__":
    main()
