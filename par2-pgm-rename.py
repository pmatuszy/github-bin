#!/usr/bin/env python3
# v. 20260806.081000 - regen hash sync also drops FastSum ';' comment lines
# v. 20260806.080500 - hash sync after PAR2 regenerate: drop old .par2 names, add new
# v. 20260805.190000 - hash lint/tidy subcommands; accept filenames with spaces in manifests
# v. 20260803.152000 - scan whole volume for FileDesc packets; patch in place when size is unchanged
# v. 20260803.072300 - rewrite volume PAR2: index head only + copy rest; verify rename stuck
# v. 20260802.154500 - read PAR2 metadata from volume-only sets; fix packet buffer refill
# v. 20260721.154223 - list-names subcommand; --pairs-file for large rename batches
# v. 20260719.093400 - hash inventory subcommand for startup scope summary

# 2026.07.19 - v. 1.2.7.0 - hash inventory CLI for par2-pgm-check startup (counts + in-scope paths)
# 2026.07.19 - v. 1.2.6.0 - hash inventory: report total hash files vs in-scope PAR2 matches
# 2026.07.19 - v. 1.2.5.0 - hash verify/update: in-scope PAR2 set only; skip when hash has no .par2 lines
# 2026.07.18 - v. 1.2.4.0 - initial release: MultiPar-compatible PAR2 filename rename (Python CLI)
"""Modify source filenames stored inside PAR2 files.

Command-line interface compatible with MultiPar's par2_rename.exe.
Based on par2_rename.py by Yutaka Sawada (MIT license).
"""

import glob
import hashlib
import os
import re
import shutil
import struct
import sys
import tempfile

VERSION = "1.2.6.0"
MAX_RENAMES = 16
INVALID_CHARS = '\\:*?"<>|'
READ_CHUNK = 2097152
SCAN_WINDOW = 65536
MAX_PACKET_BYTES = 16 * 1024 * 1024
PACKET_MAIN = b"PAR 2.0\x00Main\x00\x00\x00\x00"
PACKET_FILEDESC = b"PAR 2.0\x00FileDesc"


def usage():
    print(f"PAR2 Rename version {VERSION} (Python CLI)")
    print()
    print("Usage : <par file> [old filename//new filename]")
    print("        <par file> --pairs-file <path>")
    print("        <par file> list-names")
    print()
    print("  The <par file> can be absolute-path or relative-path.")
    print("  You can specify multiple sets of [old filename//new filename].")
    print("  The filename must be a relative-path as shown by QuickPar/MultiPar.")
    print(f"  Max entry is {MAX_RENAMES}.")
    print()
    print("  Directory separator in PAR2 files is '/'. Backslashes are converted.")
    print("  Because '//' separates old and new names, it cannot appear in filenames.")
    print()
    print("  Original PAR2 files are renamed to *_old.par2 before writing updates.")
    print("  Modified PAR2 files keep the original filenames.")
    print()
    print("Example:")
    print('  python par2_rename.py "archive.par2" oldname1//newname1 "old name2//new name2"')


def normalize_name(name):
    return name.replace("\\", "/")


def validate_new_name(name):
    for ch in INVALID_CHARS:
        if ch in name:
            return f'New filename cannot include "{ch}".'
    return None


def parse_rename_pair(arg):
    if "//" not in arg:
        raise ValueError(f'Invalid rename pair (missing "//"): {arg}')
    old_name, new_name = arg.split("//", 1)
    if old_name == "" or new_name == "":
        raise ValueError(f'Invalid rename pair (empty name): {arg}')
    old_name = normalize_name(old_name)
    new_name = normalize_name(new_name)
    if old_name == new_name:
        raise ValueError(f'Old and new names are the same: {old_name}')
    error = validate_new_name(new_name)
    if error:
        raise ValueError(error)
    return old_name, new_name


def is_backup_par2(file_name):
    file_base, file_ext = os.path.splitext(file_name)
    return file_ext.lower() == ".par2" and file_base.endswith("_old")


def backup_par2_name(file_name):
    file_base, file_ext = os.path.splitext(file_name)
    if file_ext.lower() != ".par2":
        raise ValueError(f"Not a PAR2 file: {file_name}")
    return file_base + "_old" + file_ext


def par2_base_name(file_name):
    file_base, file_ext = os.path.splitext(file_name)
    if file_ext.lower() != ".par2":
        return None
    if file_base.endswith("_old"):
        return None
    base_name = file_base.lower()
    base_name = re.sub(r"[.]vol\d*[-+_]\d+$", "", base_name)
    return base_name


def find_par2_set(par_file_path):
    par_file_path = os.path.abspath(par_file_path)
    if not os.path.isfile(par_file_path):
        raise FileNotFoundError(f"PAR2 file not found: {par_file_path}")

    folder_path = os.path.dirname(par_file_path) or "."
    file_name = os.path.basename(par_file_path)
    base_name = par2_base_name(file_name)
    if base_name is None:
        raise ValueError(f"Not a PAR2 file: {par_file_path}")

    if is_backup_par2(file_name):
        raise ValueError(f"Select an active PAR2 file, not a backup: {file_name}")

    par_files = [file_name]
    for another_path in glob.glob(glob.escape(os.path.join(folder_path, base_name)) + "*.par2"):
        another_name = os.path.basename(another_path)
        if another_name == file_name or is_backup_par2(another_name):
            continue
        par_files.append(another_name)

    par_files.sort()
    return folder_path, par_files


def iter_par2_packets(handle, file_size, wanted_types):
    """Yield (offset, packet_size, packet) for packets of the wanted types.

    Positions are absolute, so hops over multi-megabyte recovery packets stay
    in sync no matter where in the file the critical packets live. Only wanted
    packets are read in full and checksum-verified.
    """
    window = b""
    window_at = 0
    cursor = 0

    def window_index(needed):
        nonlocal window, window_at
        index = cursor - window_at
        if index < 0 or index + needed > len(window):
            window_at = cursor
            handle.seek(window_at)
            window = handle.read(max(needed, SCAN_WINDOW))
            index = 0
        return index

    while cursor + 64 <= file_size:
        index = window_index(64)
        if len(window) - index < 64:
            break

        if window[index : index + 8] != b"PAR2\x00PKT":
            cursor += 1
            continue

        packet_size = struct.unpack_from("Q", window, index + 8)[0]
        if (
            packet_size < 64
            or packet_size % 4
            or packet_size > MAX_PACKET_BYTES
            or cursor + packet_size > file_size
        ):
            cursor += 1
            continue

        if window[index + 48 : index + 64] not in wanted_types:
            cursor += packet_size
            continue

        index = window_index(packet_size)
        packet = window[index : index + packet_size]
        if (
            len(packet) < packet_size
            or hashlib.md5(packet[32:]).digest() != packet[16:32]
        ):
            cursor += 1
            continue

        yield cursor, packet_size, packet
        cursor += packet_size


def filedesc_packet_name(packet, packet_size):
    name_end = packet_size
    while packet[name_end - 1] == 0:
        name_end -= 1
    return packet[120:name_end].decode("utf-8")


def read_source_names(folder_path, par_file_name):
    file_path = os.path.join(folder_path, par_file_name)
    file_size = os.path.getsize(file_path)
    set_id = None
    source_names = []
    expected_count = 0

    with open(file_path, "rb") as handle:
        packets = iter_par2_packets(handle, file_size, (PACKET_MAIN, PACKET_FILEDESC))
        for _offset, packet_size, packet in packets:
            packet_set_id = packet[32:48]
            if set_id is None:
                set_id = packet_set_id
            elif set_id != packet_set_id:
                continue

            if packet[48:64] == PACKET_MAIN:
                expected_count = struct.unpack_from("I", packet, 72)[0]
                if expected_count == 0:
                    break
                continue

            source_name = filedesc_packet_name(packet, packet_size)
            if source_name not in source_names:
                source_names.append(source_name)
            if expected_count and len(source_names) == expected_count:
                break

    if set_id is None:
        raise ValueError(f"Could not read PAR2 set metadata from: {par_file_name}")

    return set_id, source_names


def par2_metadata_file_order(folder_path, par_files):
    def sort_key(name):
        path = os.path.join(folder_path, name)
        try:
            size = os.path.getsize(path)
        except OSError:
            size = 1 << 62
        has_vol = 1 if ".vol" in name.lower() else 0
        return (has_vol, size, name.lower())

    return sorted(par_files, key=sort_key)


def read_set_metadata(folder_path, par_files):
    set_id = None
    source_names = []
    seen_names = set()
    errors = []

    for par_file_name in par2_metadata_file_order(folder_path, par_files):
        try:
            file_set_id, file_names = read_source_names(folder_path, par_file_name)
        except ValueError as error:
            errors.append(str(error))
            continue
        if set_id is None:
            set_id = file_set_id
        for name in file_names:
            if name not in seen_names:
                seen_names.add(name)
                source_names.append(name)

    if set_id is None:
        detail = errors[0] if errors else "no readable PAR2 packets found"
        raise ValueError(
            f"Could not read PAR2 set metadata from files in: {folder_path} ({detail})"
        )

    return set_id, source_names


def build_rename_map(rename_args, source_names):
    if len(rename_args) > MAX_RENAMES:
        raise ValueError(f"Too many rename pairs (max {MAX_RENAMES}).")

    rename_map = {}
    for arg in rename_args:
        old_name, new_name = parse_rename_pair(arg)
        if old_name not in source_names:
            # Partial rename: index already has new_name, vol file may still have old_name.
            if new_name in source_names:
                rename_map[old_name] = new_name
                continue
            raise ValueError(f'Old filename not found in PAR2 set: "{old_name}"')
        if old_name in rename_map:
            raise ValueError(f'Duplicate old filename: "{old_name}"')
        if new_name in source_names and new_name != old_name:
            raise ValueError(f'New filename already exists in PAR2 set: "{new_name}"')
        if new_name in rename_map.values():
            raise ValueError(f'Duplicate new filename: "{new_name}"')
        rename_map[old_name] = new_name

    return rename_map


def restore_par2_file_times(source_path, backup_path, saved_times=None):
    ref_path = backup_path if os.path.exists(backup_path) else None
    if ref_path:
        ref_stat = os.stat(ref_path)
        os.utime(source_path, (ref_stat.st_atime, ref_stat.st_mtime))
        return
    if saved_times:
        os.utime(source_path, saved_times)


def build_filedesc_packet(packet_head, new_name):
    name_bytes = new_name.encode("utf-8")
    padded_len = len(name_bytes) + (-len(name_bytes) % 4)
    body_len = 120 + padded_len

    packet = bytearray(body_len)
    packet[0:120] = packet_head[0:120]
    packet[120 : 120 + len(name_bytes)] = name_bytes
    struct.pack_into("Q", packet, 8, body_len)
    packet[16:32] = hashlib.md5(bytes(packet[32:body_len])).digest()
    return bytes(packet)


def scan_rename_targets(file_path, set_id, rename_map):
    """Locate every FileDesc packet that needs renaming, anywhere in the file.

    Recovery volumes keep their critical packets after the recovery blocks, so
    the whole file has to be walked, not just its head.
    """
    targets = []
    file_size = os.path.getsize(file_path)

    with open(file_path, "rb") as handle:
        for offset, packet_size, packet in iter_par2_packets(
            handle, file_size, (PACKET_FILEDESC,)
        ):
            if packet[32:48] != set_id:
                continue
            current_name = filedesc_packet_name(packet, packet_size)
            new_name = rename_map.get(current_name)
            if new_name and new_name != current_name:
                targets.append(
                    (offset, packet_size, build_filedesc_packet(packet, new_name))
                )

    return targets


def patch_par2_packets_in_place(source_path, targets, saved_times):
    with open(source_path, "r+b") as handle:
        for offset, _packet_size, packet in targets:
            handle.seek(offset)
            handle.write(packet)
        handle.flush()
        os.fsync(handle.fileno())
    if saved_times:
        os.utime(source_path, saved_times)


def copy_file_range(reader, writer, start, end):
    reader.seek(start)
    remaining = end - start
    while remaining > 0:
        chunk = reader.read(min(READ_CHUNK, remaining))
        if not chunk:
            break
        writer.write(chunk)
        remaining -= len(chunk)


def rewrite_par2_file_with_targets(folder_path, par_file_name, targets, saved_times):
    source_path = os.path.join(folder_path, par_file_name)
    backup_path = os.path.join(folder_path, backup_par2_name(par_file_name))
    backup_exists = os.path.exists(backup_path)

    temp_fd, temp_path = tempfile.mkstemp(
        prefix=f".{par_file_name}.",
        suffix=".tmp",
        dir=folder_path,
    )
    os.close(temp_fd)

    try:
        with open(source_path, "rb") as reader, open(temp_path, "wb") as writer:
            position = 0
            for offset, packet_size, packet in targets:
                copy_file_range(reader, writer, position, offset)
                writer.write(packet)
                position = offset + packet_size
            reader.seek(position)
            shutil.copyfileobj(reader, writer, READ_CHUNK)

        if backup_exists:
            os.replace(temp_path, source_path)
        else:
            os.replace(source_path, backup_path)
            os.replace(temp_path, source_path)
        restore_par2_file_times(source_path, backup_path, saved_times)
    except Exception:
        if os.path.exists(temp_path):
            os.remove(temp_path)
        if not backup_exists and os.path.exists(backup_path) and not os.path.exists(source_path):
            os.replace(backup_path, source_path)
        raise


def rewrite_par2_file(folder_path, par_file_name, set_id, rename_map):
    source_path = os.path.join(folder_path, par_file_name)
    saved_times = None

    try:
        src_stat = os.stat(source_path)
        saved_times = (src_stat.st_atime, src_stat.st_mtime)
    except OSError as error:
        raise ValueError(f"PAR2 file not found: {par_file_name}") from error

    targets = scan_rename_targets(source_path, set_id, rename_map)
    if not targets:
        return 0

    if all(len(packet) == packet_size for _o, packet_size, packet in targets):
        patch_par2_packets_in_place(source_path, targets, saved_times)
    else:
        rewrite_par2_file_with_targets(folder_path, par_file_name, targets, saved_times)

    return len(targets)


HASH_EXTENSIONS = {
    ".sha512": "sha512",
    ".sha256": "sha256",
    ".md5": "md5",
}

# Digest, separator, then the rest of the line as the path: filenames may
# contain spaces. Anchoring the digest length keeps prose from matching.
HASH_LINE_RE = re.compile(r"^([a-fA-F0-9]{32,128})[ \t]+(\S.*?)[ \t]*$")
COMMENT_PREFIXES = ("#", ";")


def hash_algo_from_path(path):
    ext = os.path.splitext(path)[1].lower()
    algo = HASH_EXTENSIONS.get(ext)
    if algo is None:
        raise ValueError(f"Unsupported hash file type: {path}")
    return algo


def hash_path_basename(path_field):
    path = path_field.strip()
    if path.startswith("*"):
        path = path[1:]
    path = path.replace("\\", "/")
    return os.path.basename(path)


def parse_hash_file(hash_file_path):
    records = []
    with open(hash_file_path, "r", encoding="utf-8", errors="replace") as handle:
        for number, line in enumerate(handle, start=1):
            stripped = line.rstrip("\r\n")
            lstripped = stripped.lstrip()
            if not stripped.strip():
                records.append({"type": "blank", "raw": stripped, "line": number})
                continue
            if lstripped.startswith(COMMENT_PREFIXES):
                records.append(
                    {
                        "type": "comment",
                        "raw": stripped,
                        "marker": lstripped[0],
                        "line": number,
                    }
                )
                continue
            match = HASH_LINE_RE.match(stripped.strip())
            if not match:
                records.append({"type": "invalid", "raw": stripped, "line": number})
                continue
            path_field = match.group(2)
            records.append(
                {
                    "type": "entry",
                    "hash": match.group(1).lower(),
                    "path": path_field,
                    "basename": hash_path_basename(path_field),
                    "raw": stripped,
                    "line": number,
                }
            )
    return records


def hash_file_lint(hash_file_path):
    records = parse_hash_file(hash_file_path)
    counts = {"entries": 0, "comments": 0, "blank": 0, "invalid": 0, "semicolons": 0}
    invalid_lines = []

    for record in records:
        if record["type"] == "entry":
            counts["entries"] += 1
        elif record["type"] == "comment":
            counts["comments"] += 1
            if record["marker"] == ";":
                counts["semicolons"] += 1
        elif record["type"] == "blank":
            counts["blank"] += 1
        else:
            counts["invalid"] += 1
            if len(invalid_lines) < 5:
                invalid_lines.append(record["line"])

    counts["invalid_lines"] = invalid_lines
    return counts


def set_source_basenames(folder_path, par_file_path):
    """Basenames of the files the PAR2 set protects, or None when unknown."""
    if not par_file_path:
        return None
    try:
        set_folder, par_files = find_par2_set(par_file_path)
        _set_id, source_names = read_set_metadata(set_folder, par_files)
    except (ValueError, OSError):
        return None
    return {os.path.basename(name.replace("\\", "/")) for name in source_names}


def print_hash_lint(folder_path, par_file_path=None):
    """One tab-separated row per hash file, for the shell to act on."""
    protected = set_source_basenames(folder_path, par_file_path)

    for path in list_hash_files(folder_path):
        counts = hash_file_lint(path)
        if protected is None:
            in_set = "unknown"
        elif os.path.basename(path) in protected:
            in_set = "yes"
        else:
            in_set = "no"
        print(
            "\t".join(
                (
                    path,
                    str(counts["entries"]),
                    str(counts["comments"]),
                    str(counts["semicolons"]),
                    str(counts["invalid"]),
                    in_set,
                )
            )
        )


def tidy_hash_file(hash_file_path):
    """Convert leading ';' comment markers to '#', which md5sum -c ignores.

    Rewrites the existing inode and restores the timestamps, so ownership,
    permissions and the modification date all survive.
    """
    before = hash_file_lint(hash_file_path)
    if before["semicolons"] == 0:
        return 0, f"No ';' comment lines in {os.path.basename(hash_file_path)}."

    with open(hash_file_path, "r", encoding="utf-8", errors="replace") as handle:
        original = handle.read()

    converted = 0
    lines = []
    for line in original.splitlines():
        stripped = line.lstrip()
        if stripped.startswith(";"):
            indent = line[: len(line) - len(stripped)]
            lines.append(f"{indent}#{stripped[1:]}")
            converted += 1
        else:
            lines.append(line)

    new_text = "\n".join(lines)
    if original.endswith("\n"):
        new_text += "\n"

    stat_before = os.stat(hash_file_path)
    # Truncate and rewrite in place: a new inode would drop owner and mode.
    with open(hash_file_path, "r+", encoding="utf-8", newline="") as handle:
        handle.seek(0)
        handle.write(new_text)
        handle.truncate()
    os.utime(hash_file_path, (stat_before.st_atime, stat_before.st_mtime))

    after = hash_file_lint(hash_file_path)
    if after["entries"] != before["entries"]:
        raise ValueError(
            f"Entry count changed while tidying {os.path.basename(hash_file_path)} "
            f"({before['entries']} -> {after['entries']}); file left as written."
        )

    return converted, (
        f"Converted {converted} ';' comment line(s) to '#' in "
        f"{os.path.basename(hash_file_path)} "
        f"({after['entries']} checksum entries unchanged, timestamp preserved)."
    )


def compute_file_hash(file_path, algo):
    digest = hashlib.new(algo)
    with open(file_path, "rb") as handle:
        while True:
            chunk = handle.read(READ_CHUNK)
            if not chunk:
                break
            digest.update(chunk)
    return digest.hexdigest().lower()


def is_par2_basename(name):
    if not name.lower().endswith(".par2"):
        return False
    return not is_backup_par2(name)


def par2_hash_entries(expected_by_basename):
    return {
        name: digest
        for name, digest in expected_by_basename.items()
        if is_par2_basename(name)
    }


def list_active_par2_files(folder_path):
    return sorted(
        name
        for name in os.listdir(folder_path)
        if name.lower().endswith(".par2") and not is_backup_par2(name)
    )


def resolve_scoped_par2_files(folder_path, par_file_path=None):
    if par_file_path:
        set_folder, par_files = find_par2_set(par_file_path)
        if os.path.abspath(set_folder) != os.path.abspath(folder_path):
            raise ValueError(
                f"PAR2 file is not in hash directory: {par_file_path}"
            )
        return par_files
    return list_active_par2_files(folder_path)


def list_hash_files(folder_path):
    candidates = []
    for pattern in ("*.sha512", "*.SHA512", "*.sha256", "*.SHA256", "*.md5", "*.MD5"):
        candidates.extend(glob.glob(os.path.join(folder_path, pattern)))
    return sorted(set(candidates))


def find_hash_file(folder_path):
    candidates = list_hash_files(folder_path)
    if not candidates:
        return None
    return candidates[0]


def entries_by_basename(hash_file_path):
    records = parse_hash_file(hash_file_path)
    return {
        record["basename"]: record["hash"]
        for record in records
        if record["type"] == "entry"
    }


def hash_inventory_for_scope(folder_path, par_file_path=None):
    hash_files = list_hash_files(folder_path)
    par_files = resolve_scoped_par2_files(folder_path, par_file_path)
    scope_set = set(par_files)
    with_any_par2 = 0
    relevant = []

    for path in hash_files:
        expected = entries_by_basename(path)
        par_entries = par2_hash_entries(expected)
        if par_entries:
            with_any_par2 += 1
        overlap = sorted(scope_set & set(par_entries.keys()))
        if overlap:
            relevant.append(
                {
                    "path": path,
                    "overlap": overlap,
                    "par_entries": par_entries,
                    "algo": hash_algo_from_path(path),
                }
            )

    return {
        "total_hash_files": len(hash_files),
        "with_any_par2_entries": with_any_par2,
        "relevant": relevant,
        "scope_par_files": par_files,
    }


def format_hash_inventory_lines(inventory, par_file_path=None):
    lines = []
    total = inventory["total_hash_files"]
    if total == 0:
        lines.append("No .sha512 / .sha256 / .md5 hash file found in this directory.")
        lines.append("Skipping PAR2 archive checksum verification.")
        return lines

    any_par2 = inventory["with_any_par2_entries"]
    relevant = inventory["relevant"]
    scope = inventory["scope_par_files"]

    lines.append(f"Found {total} hash file(s) in this directory.")
    lines.append(
        f"{any_par2} hash file(s) contain .par2 entries; "
        f"{len(relevant)} hash file(s) list in-scope PAR2 archive(s) for this set."
    )
    if par_file_path:
        lines.append(f"PAR2 set anchor: {os.path.basename(par_file_path)}")
    if scope:
        lines.append(
            f"In-scope PAR2 file(s) ({len(scope)}): {', '.join(scope)}"
        )
    else:
        lines.append("In-scope PAR2 file(s): (none)")
    lines.append(
        "Other hash-file paths and other PAR2 sets in this directory are not checked."
    )

    if not relevant:
        if any_par2 == 0:
            lines.append(
                "Skipping PAR2 archive checksum verification: "
                "no hash file in this directory contains .par2 entries."
            )
        else:
            lines.append(
                "Skipping PAR2 archive checksum verification: "
                "no hash file lists any in-scope PAR2 archive for this set."
            )
        return lines

    lines.append("Verifying checksums in:")
    for item in relevant:
        names = ", ".join(item["overlap"])
        lines.append(
            f"  - {os.path.basename(item['path'])} "
            f"({len(item['overlap'])} in-scope .par2 entr"
            f"{'y' if len(item['overlap']) == 1 else 'ies'}: {names})"
        )
    return lines


def print_hash_inventory_brief(folder_path, par_file_path=None):
    inventory = hash_inventory_for_scope(folder_path, par_file_path)
    relevant = inventory["relevant"]
    print(inventory["total_hash_files"])
    print(inventory["with_any_par2_entries"])
    print(len(relevant))
    for item in relevant:
        print(item["path"])


def verify_par2_hashes(folder_path, par_file_path=None):
    inventory = hash_inventory_for_scope(folder_path, par_file_path)
    preamble = format_hash_inventory_lines(inventory, par_file_path)
    if inventory["total_hash_files"] == 0:
        return True, None, "\n".join(preamble)

    relevant = inventory["relevant"]
    if not relevant:
        return True, None, "\n".join(preamble)

    par_files = inventory["scope_par_files"]
    errors = []
    verified = 0

    for par_name in par_files:
        sources = [item for item in relevant if par_name in item["overlap"]]
        if not sources:
            errors.append(
                f"{par_name}: missing from all {inventory['total_hash_files']} hash file(s)"
            )
            continue
        mismatch_files = []
        for item in sources:
            listed_hash = item["par_entries"][par_name]
            item_hash = compute_file_hash(
                os.path.join(folder_path, par_name), item["algo"]
            )
            if item_hash != listed_hash:
                mismatch_files.append(os.path.basename(item["path"]))
        if mismatch_files:
            errors.append(
                f"{par_name}: checksum mismatch in {', '.join(mismatch_files)}"
            )
            continue
        verified += 1

    if errors:
        message = "\n".join(preamble) + "\nPAR2 archive checksum verification failed:\n"
        message += "\n".join(f"  - {error}" for error in errors)
        return False, relevant[0]["path"], message

    ok_lines = preamble + [
        (
            f"PAR2 archive checksums OK: {verified} in-scope PAR2 file(s) match "
            f"across {len(relevant)} hash file(s)."
        )
    ]
    return True, relevant[0]["path"], "\n".join(ok_lines)


def _update_one_hash_file(folder_path, hash_file, par_files):
    algo = hash_algo_from_path(hash_file)
    par_files = set(par_files)
    with open(hash_file, "r", encoding="utf-8", errors="replace") as handle:
        original_text = handle.read()

    records = parse_hash_file(hash_file)
    output_lines = []
    updated_names = set()

    for record in records:
        if record["type"] != "entry" or record["basename"] not in par_files:
            output_lines.append(record["raw"])
            continue

        new_hash = compute_file_hash(os.path.join(folder_path, record["basename"]), algo)
        path_field = record["path"]
        if "  " in record["raw"]:
            sep = "  "
        elif "\t" in record["raw"]:
            sep = "\t"
        else:
            sep = " "
        output_lines.append(f"{new_hash}{sep}{path_field}")
        updated_names.add(record["basename"])

    for par_name in sorted(par_files - updated_names):
        new_hash = compute_file_hash(os.path.join(folder_path, par_name), algo)
        output_lines.append(f"{new_hash}  *./{par_name}")

    new_text = "\n".join(output_lines)
    if original_text.endswith("\n"):
        new_text += "\n"

    with open(hash_file, "w", encoding="utf-8", newline="\n") as handle:
        handle.write(new_text)

    appended = len(par_files - updated_names)
    touched = len(updated_names) + appended
    return touched


def update_par2_hashes(folder_path, hash_file=None, par_file_path=None):
    if hash_file is not None:
        par_files = resolve_scoped_par2_files(folder_path, par_file_path)
        touched = _update_one_hash_file(folder_path, hash_file, par_files)
        return True, (
            f"Updated PAR2 checksums in {os.path.basename(hash_file)} "
            f"({touched} in-scope entries)"
        )

    inventory = hash_inventory_for_scope(folder_path, par_file_path)
    relevant = inventory["relevant"]
    if inventory["total_hash_files"] == 0:
        return False, "No hash file found (nothing to update)."
    if not relevant:
        return False, (
            "No hash file lists in-scope PAR2 archives for this set (nothing to update)."
        )

    par_files = inventory["scope_par_files"]
    messages = []
    for item in relevant:
        touched = _update_one_hash_file(folder_path, item["path"], par_files)
        messages.append(
            f"{os.path.basename(item['path'])} ({touched} in-scope entries)"
        )
    return True, (
        f"Updated PAR2 checksums in {len(relevant)} hash file(s): "
        + "; ".join(messages)
    )


def _write_hash_file_preserving_times(hash_file, new_text):
    try:
        stat_before = os.stat(hash_file)
        times = (stat_before.st_atime, stat_before.st_mtime)
    except OSError:
        times = None

    with open(hash_file, "r+", encoding="utf-8", newline="") as handle:
        handle.seek(0)
        handle.write(new_text)
        handle.truncate()

    if times:
        os.utime(hash_file, times)


def sync_hash_files_after_regen(folder_path, remove_names, new_par_names):
    """Refresh every hash manifest after a PAR2 set was regenerated.

    Drops checksum lines for retired PAR2 basenames, drops FastSum-style ';'
    comment lines (md5sum -c treats them as malformed), then ensures each new
    PAR2 archive has a current digest. '#' comments and blank lines stay.
    Manifests that never listed .par2 files still get the new entries.
    Modification times are preserved.
    """
    remove_set = {os.path.basename(name) for name in remove_names}
    new_names = sorted({os.path.basename(name) for name in new_par_names})
    hash_files = list_hash_files(folder_path)
    if not hash_files:
        return True, "No hash file in directory (nothing to update after regenerate)."
    if not new_names:
        return False, "No new PAR2 files given for hash sync."

    messages = []
    for hash_file in hash_files:
        algo = hash_algo_from_path(hash_file)
        with open(hash_file, "r", encoding="utf-8", errors="replace") as handle:
            original_text = handle.read()

        records = parse_hash_file(hash_file)
        output_lines = []
        updated = set()
        removed = 0
        dropped_semicolons = 0

        for record in records:
            if record["type"] == "comment" and record.get("marker") == ";":
                dropped_semicolons += 1
                continue
            if record["type"] != "entry":
                output_lines.append(record["raw"])
                continue
            base = record["basename"]
            if base in remove_set:
                removed += 1
                continue
            if base in new_names:
                new_hash = compute_file_hash(os.path.join(folder_path, base), algo)
                path_field = record["path"]
                if "  " in record["raw"]:
                    sep = "  "
                elif "\t" in record["raw"]:
                    sep = "\t"
                else:
                    sep = " "
                output_lines.append(f"{new_hash}{sep}{path_field}")
                updated.add(base)
                continue
            output_lines.append(record["raw"])

        appended = 0
        for par_name in new_names:
            if par_name in updated:
                continue
            new_hash = compute_file_hash(os.path.join(folder_path, par_name), algo)
            output_lines.append(f"{new_hash}  *./{par_name}")
            appended += 1

        new_text = "\n".join(output_lines)
        if original_text.endswith("\n") or new_text:
            new_text += "\n"

        if new_text != original_text:
            _write_hash_file_preserving_times(hash_file, new_text)

        detail = (
            f"updated {len(updated)}, added {appended}, "
            f"removed {removed} old .par2"
        )
        if dropped_semicolons:
            detail += f", dropped {dropped_semicolons} ';' comment line(s)"
        messages.append(f"{os.path.basename(hash_file)} ({detail})")

    return True, (
        f"Synced PAR2 checksums in {len(hash_files)} hash file(s): "
        + "; ".join(messages)
    )


def par2_index_file(par_files):
    index_file = par_files[0]
    for candidate in par_files:
        if ".vol" not in candidate.lower():
            index_file = candidate
            break
    return index_file


def read_par2_source_names(par_file_path):
    folder_path, par_files = find_par2_set(par_file_path)
    _, source_names = read_set_metadata(folder_path, par_files)
    return source_names


def list_source_names(par_file_path):
    folder_path, par_files = find_par2_set(par_file_path)
    source_names = read_par2_source_names(par_file_path)
    print(f"PAR2 set in: {folder_path}")
    print(f"PAR2 files: {len(par_files)}")
    print(f"Source files: {len(source_names)}")
    print()
    for name in source_names:
        print(name)


def list_source_names_only(par_file_path):
    for name in read_par2_source_names(par_file_path):
        print(name)


def parse_rename_argv(argv):
    if len(argv) < 2:
        raise ValueError("PAR2 index file required.")

    par_file_path = argv[1]
    rename_args = []
    index = 2
    while index < len(argv):
        token = argv[index]
        if token == "--pairs-file":
            if index + 1 >= len(argv):
                raise ValueError("--pairs-file requires a path.")
            with open(argv[index + 1], encoding="utf-8") as handle:
                for line in handle:
                    line = line.strip()
                    if line and not line.startswith("#"):
                        rename_args.append(line)
            index += 2
            continue
        rename_args.append(token)
        index += 1
    return par_file_path, rename_args


def apply_renames(par_file_path, rename_args):
    folder_path, par_files = find_par2_set(par_file_path)

    set_id, source_names = read_set_metadata(folder_path, par_files)
    rename_map = build_rename_map(rename_args, source_names)

    total_packets = 0
    modified_files = []
    for par_file_name in par_files:
        count = rewrite_par2_file(folder_path, par_file_name, set_id, rename_map)
        if count:
            modified_files.append(par_file_name)
            total_packets += count

    if not modified_files:
        print("No packets needed updating (rename may already be complete).")
    else:
        print(f"Modified {total_packets} packets in {len(modified_files)} PAR2 file(s).")
        for par_file_name in modified_files:
            backup_name = backup_par2_name(par_file_name)
            backup_path = os.path.join(folder_path, backup_name)
            if os.path.exists(backup_path):
                print(f"  {par_file_name}  (backup: {backup_name})")
            else:
                print(f"  {par_file_name}")
    for old_name, new_name in rename_map.items():
        print(f'  "{old_name}" -> "{new_name}"')

    _, names_after = read_set_metadata(folder_path, par_files)
    still_old = [old for old in rename_map if old in names_after]
    if still_old:
        quoted = ", ".join(f'"{name}"' for name in still_old)
        raise ValueError(
            f"PAR2 metadata still lists old filename(s) after rename: {quoted}"
        )


def main(argv):
    if len(argv) >= 3 and argv[1] == "hash":
        folder_path = os.path.abspath(argv[3] if len(argv) > 3 else ".")
        par_file_path = os.path.abspath(argv[4]) if len(argv) > 4 else None
        try:
            if argv[2] == "verify":
                ok, _, message = verify_par2_hashes(folder_path, par_file_path)
                print(message)
                return 0 if ok else 1
            if argv[2] == "update":
                ok, message = update_par2_hashes(
                    folder_path, par_file_path=par_file_path
                )
                print(message)
                return 0 if ok else 1
            if argv[2] == "inventory":
                print_hash_inventory_brief(folder_path, par_file_path)
                return 0
            if argv[2] == "lint":
                print_hash_lint(folder_path, par_file_path)
                return 0
            if argv[2] == "tidy":
                # Here argv[3] is the hash file itself, not a directory.
                if len(argv) < 4:
                    print(
                        "Usage: par2-pgm-rename.py hash tidy <hash-file>",
                        file=sys.stderr,
                    )
                    return 1
                converted, message = tidy_hash_file(os.path.abspath(argv[3]))
                print(message)
                return 0 if converted else 1
            if argv[2] == "sync-regen":
                # hash sync-regen <dir> --remove a.par2 b.par2 --add c.par2
                remove_names = []
                add_names = []
                mode = None
                for token in argv[4:]:
                    if token == "--remove":
                        mode = "remove"
                        continue
                    if token == "--add":
                        mode = "add"
                        continue
                    if mode == "remove":
                        remove_names.append(token)
                    elif mode == "add":
                        add_names.append(token)
                    else:
                        print(
                            "Usage: par2-pgm-rename.py hash sync-regen <directory> "
                            "--remove old.par2... --add new.par2...",
                            file=sys.stderr,
                        )
                        return 1
                ok, message = sync_hash_files_after_regen(
                    folder_path, remove_names, add_names
                )
                print(message)
                return 0 if ok else 1
            print(
                "Usage: par2-pgm-rename.py hash "
                "verify|update|inventory|lint <directory> [par2-index]\n"
                "       par2-pgm-rename.py hash tidy <hash-file>\n"
                "       par2-pgm-rename.py hash sync-regen <directory> "
                "--remove old.par2... --add new.par2...",
                file=sys.stderr,
            )
            return 1
        except (ValueError, OSError) as error:
            print(f"Error: {error}", file=sys.stderr)
            return 1

    if len(argv) < 2:
        usage()
        return 1

    try:
        if len(argv) >= 3 and argv[2] == "list-names":
            list_source_names_only(argv[1])
            return 0

        par_file_path, rename_args = parse_rename_argv(argv)
        if not rename_args:
            list_source_names(par_file_path)
            print()
            print("To rename, add pairs as: old filename//new filename")
            print("  Or: --pairs-file <path>  (one old//new pair per line)")
            return 0

        apply_renames(par_file_path, rename_args)
        return 0
    except (FileNotFoundError, FileExistsError, ValueError) as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1
    except OSError as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
