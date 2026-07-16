#!/usr/bin/env python3
"""Add standard -h/-v/--no_startup_delay CLI to scripts that lack it; fix broken -v order."""

from __future__ import annotations

import re
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TS = datetime.now().strftime("%Y%m%d.%H%M%S")
NEW_TOP = f"# v. {TS} - add -h/--help, -v/--version, --no_startup_delay\n"
SKIP_PARTS = {"_oldy", ".git"}
SKIP_NAMES = {
    "_script_header.sh",
    "_script_footer.sh",
    "_smart_disk_discovery.sh",
}

GIT_WRAPPERS = {
    "git-pull.sh": "pull",
    "git-push.sh": "push",
    "git-fetch.sh": "fetch",
}


def should_skip(path: Path) -> bool:
    if path.name in SKIP_NAMES:
        return True
    return any(part in SKIP_PARTS for part in path.parts)


def has_cli(text: str) -> bool:
    has_help = bool(re.search(r"-h\|--help", text))
    has_ver = bool(
        re.search(r"-v\|--version", text)
        or re.search(r"--version\)", text)
        or re.search(r"print_version_banner", text)
    )
    return has_help and has_ver


def uses_positional_args(body: str) -> bool:
    """Script expects non-option arguments after CLI parsing."""
    if re.search(r"\$#|\$@|\$1", body):
        return True
    return False


def extract_description(lines: list[str], basename: str) -> str:
    name = basename.replace(".sh", "")
    for i, line in enumerate(lines):
        s = line.strip()
        if re.match(rf"#\s*{re.escape(name)}\s*$", s, re.I):
            for j in range(i + 1, min(i + 6, len(lines))):
                t = lines[j].strip()
                if t.startswith("#") and t not in ("#", "# ---"):
                    desc = t.lstrip("#").strip()
                    if desc and not re.match(r"^v\.", desc) and not re.match(r"^[0-9]{4}\.", desc):
                        return desc
            break
    for line in lines:
        s = line.strip()
        if s.startswith("# ") and not re.match(r"# v\.", s) and not re.match(r"# [0-9]{4}\.", s):
            t = s[2:].strip()
            if t and len(t) < 120 and not t.startswith("!"):
                return t
    return f"Operational script ({name})."


def find_header_end(lines: list[str]) -> int:
    """Index of first executable line after shebang + changelog comments."""
    i = 0
    if lines and lines[0].startswith("#!"):
        i = 1
    while i < len(lines):
        line = lines[i]
        if line.strip() == "" or line.lstrip().startswith("#"):
            i += 1
            continue
        break
    return i


def update_top_changelog(lines: list[str]) -> list[str]:
    if len(lines) < 2:
        return lines
    if lines[1].startswith("# v. ") and "add -h/--help" in lines[1]:
        return lines
    out = [lines[0], NEW_TOP]
    if lines[1].startswith("# v. "):
        out.extend(lines[2:])
    else:
        out.extend(lines[1:])
    return out


def cli_block(basename: str, description: str, passthrough: bool) -> str:
    unknown = "    *) break ;;" if passthrough else (
        '    *) echo "Unknown argument: $1" >&2; '
        'echo "Try: $(basename "$0") --help" >&2; exit 1 ;;'
    )
    desc_line = description.replace("$", "\\$")
    return f'''
show_help() {{
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

{desc_line}

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  --no_startup_delay   Skip random startup delay (recommended for cron).
EOF
}}

HEADER_EXTRA_ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --no_startup_delay) HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY); shift ;;
    *) break ;;
  esac
done

. /root/bin/_script_header.sh "${{HEADER_EXTRA_ARGS[@]}}"

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help) show_help; exit 0 ;;
    -v|--version) print_version_banner; exit 0 ;;
{unknown}
  esac
done

'''.lstrip("\n")


def git_wrapper_block(subcmd: str) -> str:
    return f'''
case "${{1:-}}" in
  -h|--help)
    cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [OPTIONS...]

Compatibility wrapper for git-bin.sh {subcmd}.
All other arguments are passed through (e.g. batch, --no_startup_delay).

Options:
  -h, --help     Show this help and exit.
  -v, --version  Print git-bin.sh version and exit.
EOF
    exit 0
    ;;
  -v|--version)
    exec bash "${{_GIT_BIN_ROOT}}/git-bin.sh" -v {subcmd}
    ;;
esac
'''


def remove_bare_header_source(text: str) -> str:
    text = re.sub(
        r"^\. /root/bin/_script_header\.sh\s*\n",
        "",
        text,
        count=1,
        flags=re.MULTILINE,
    )
    text = re.sub(
        r'^\. /root/bin/_script_header\.sh "\$\{HEADER_EXTRA_ARGS\[@\]\}"\s*\n',
        "",
        text,
        count=1,
        flags=re.MULTILINE,
    )
    return text


def fix_broken_v_order(text: str) -> str:
    """Split single loop that calls print_version_banner before header."""
    pattern = re.compile(
        r"(HEADER_EXTRA_ARGS=\(\)\n)"
        r"while \[\[ \$# -gt 0 \]\]; do\n"
        r"  case \$1 in\n"
        r"    -h\|--help\)[^\n]*\n(?:[^\n]*\n)*?"
        r"    -v\|--version\)[^\n]*\n(?:[^\n]*\n)*?"
        r"      print_version_banner[^\n]*\n(?:[^\n]*\n)*?"
        r"    --no_startup_delay\)[^\n]*\n"
        r"(?:    \*\)[^\n]*\n(?:[^\n]*\n)*?)?"
        r"  esac\n"
        r"done\n\n"
        r"\. /root/bin/_script_header\.sh \"\$\{HEADER_EXTRA_ARGS\[@\]\}\"\n",
        re.MULTILINE,
    )

    def repl(m: re.Match[str]) -> str:
        rest = m.group(0)
        # extract unknown handler if any
        unknown_match = re.search(r"    \*\)[^\n]+\n(?:      [^\n]+\n)*", rest)
        unknown = unknown_match.group(0).rstrip() if unknown_match else (
            '    *) echo "Unknown argument: $1" >&2; '
            'echo "Try: $(basename "$0") --help" >&2; exit 1 ;;\n'
        )
        help_block = re.search(
            r"    -h\|--help\)[^\n]*\n(?:      [^\n]+\n)*?      exit 0\n(?:      ;;|;;)",
            rest,
            re.MULTILINE,
        )
        help_lines = help_block.group(0) if help_block else "    -h|--help) show_help; exit 0 ;;\n"
        return (
            "HEADER_EXTRA_ARGS=()\n"
            "while [[ $# -gt 0 ]]; do\n"
            "  case $1 in\n"
            "    --no_startup_delay) HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY); shift ;;\n"
            "    *) break ;;\n"
            "  esac\n"
            "done\n\n"
            '. /root/bin/_script_header.sh "${HEADER_EXTRA_ARGS[@]}"\n\n'
            "while [[ $# -gt 0 ]]; do\n"
            "  case $1 in\n"
            f"{help_lines}"
            "    -v|--version)\n"
            "      print_version_banner\n"
            "      exit 0\n"
            "      ;;\n"
            f"{unknown}"
            "  esac\n"
            "done\n\n"
        )

    new_text, n = pattern.subn(repl, text, count=1)
    return new_text if n else text


def process_file(path: Path) -> bool:
    text = path.read_text(encoding="utf-8", errors="replace")
    if not text.startswith("#!"):
        return False

    original = text
    basename = path.name

    if basename in GIT_WRAPPERS:
        if "-h|--help" in text:
            return False
        lines = text.splitlines(keepends=True)
        lines = update_top_changelog(lines)
        text = "".join(lines)
        # insert after _GIT_BIN_ROOT line
        text = re.sub(
            r'(_GIT_BIN_ROOT="\$\(cd "\$\(dirname "\$\{BASH_SOURCE\[0\]\}"\)" && pwd\)"\n)',
            r"\1" + git_wrapper_block(GIT_WRAPPERS[basename]),
            text,
            count=1,
        )
    elif has_cli(text):
        text = fix_broken_v_order(text)
        if text != original:
            lines = text.splitlines(keepends=True)
            text = "".join(update_top_changelog(lines))
    else:
        lines = text.splitlines(keepends=True)
        lines = update_top_changelog(lines)
        idx = find_header_end(lines)
        body = "".join(lines[idx:])
        passthrough = uses_positional_args(body)
        desc = extract_description(lines, basename)
        block = cli_block(basename, desc, passthrough)
        body = remove_bare_header_source(body)
        new_lines = lines[:idx] + [block] + [body]
        text = "".join(new_lines)

    if text == original:
        return False
    path.write_text(text, encoding="utf-8", newline="\n")
    return True


def main() -> None:
    changed: list[str] = []
    for path in sorted(ROOT.rglob("*.sh")):
        if should_skip(path):
            continue
        if process_file(path):
            changed.append(path.relative_to(ROOT).as_posix())
    print(f"Updated {len(changed)} script(s)")
    for name in changed:
        print(f"  {name}")


if __name__ == "__main__":
    main()
