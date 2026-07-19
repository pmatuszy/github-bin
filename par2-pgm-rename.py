#!/usr/bin/env python3
# v. 20260719.092000 - scan all hash files; verify/update only manifests listing in-scope PAR2

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
import struct
import sys
import tempfile

VERSION = "1.2.6.0"
MAX_RENAMES = 16
INVALID_CHARS = '\\:*?"<>|'
READ_CHUNK = 2097152
REFILL_AT = 1048576
PACKET_BUFFER = 65536


def usage():
    print(f"PAR2 Rename version {VERSION} (Python CLI)")
    print()
    print("Usage : <par file> [old filename//new filename]")
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


def read_source_names(folder_path, par_file_name):
    file_path = os.path.join(folder_path, par_file_name)
    set_id = None
    source_names = []
    expected_count = 0

    with open(file_path, "rb") as handle:
        data = handle.read(READ_CHUNK)
        data_size = len(data)
        offset = 0

        while offset + 64 < data_size:
            if data[offset : offset + 8] != b"PAR2\x00PKT":
                offset += 1
                continue

            packet_size = struct.unpack_from("Q", data, offset + 8)[0]
            if offset + packet_size > data_size:
                offset += 8
                continue

            packet_hash = hashlib.md5(data[offset + 32 : offset + packet_size]).digest()
            if data[offset + 16 : offset + 32] != packet_hash:
                offset += 8
                continue

            packet_set_id = data[offset + 32 : offset + 48]
            if set_id is None:
                set_id = packet_set_id
            elif set_id != packet_set_id:
                offset += packet_size
                continue

            packet_type = data[offset + 48 : offset + 64]
            if packet_type == b"PAR 2.0\x00Main\x00\x00\x00\x00":
                expected_count = struct.unpack_from("I", data, offset + 72)[0]
                if expected_count == 0:
                    break
            elif packet_type == b"PAR 2.0\x00FileDesc":
                name_end = packet_size
                while data[offset + name_end - 1] == 0:
                    name_end -= 1
                source_name = data[offset + 120 : offset + name_end].decode("utf-8")
                if source_name not in source_names:
                    source_names.append(source_name)
                if expected_count and len(source_names) == expected_count:
                    break

            offset += packet_size

            if offset >= REFILL_AT:
                data = data[offset:data_size] + handle.read(READ_CHUNK - (data_size - offset))
                data_size = len(data)
                offset = 0

    if set_id is None:
        raise ValueError(f"Could not read PAR2 set metadata from: {par_file_name}")

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


def rewrite_par2_file(folder_path, par_file_name, set_id, rename_map):
    source_path = os.path.join(folder_path, par_file_name)
    backup_path = os.path.join(folder_path, backup_par2_name(par_file_name))
    buffer = bytearray(PACKET_BUFFER)
    rename_count = 0
    saved_times = None

    try:
        src_stat = os.stat(source_path)
        saved_times = (src_stat.st_atime, src_stat.st_mtime)
    except OSError:
        pass

    backup_exists = os.path.exists(backup_path)

    with open(source_path, "rb") as reader:
        data = reader.read(READ_CHUNK)
        data_size = len(data)

        temp_fd, temp_path = tempfile.mkstemp(
            prefix=f".{par_file_name}.",
            suffix=".tmp",
            dir=folder_path,
        )
        os.close(temp_fd)

        try:
            with open(temp_path, "wb") as writer:
                offset = 0
                while offset + 64 < data_size:
                    if data[offset : offset + 8] != b"PAR2\x00PKT":
                        writer.write(data[offset : offset + 1])
                        offset += 1
                        continue

                    packet_size = struct.unpack_from("Q", data, offset + 8)[0]
                    if offset + packet_size > data_size:
                        writer.write(data[offset : offset + 8])
                        offset += 8
                        continue

                    packet_hash = hashlib.md5(data[offset + 32 : offset + packet_size]).digest()
                    if data[offset + 16 : offset + 32] != packet_hash:
                        writer.write(data[offset : offset + 8])
                        offset += 8
                        continue

                    if set_id != data[offset + 32 : offset + 48]:
                        writer.write(data[offset : offset + packet_size])
                        offset += packet_size
                        continue

                    wrote_packet = False
                    if data[offset + 48 : offset + 64] == b"PAR 2.0\x00FileDesc":
                        name_end = packet_size
                        while data[offset + name_end - 1] == 0:
                            name_end -= 1
                        current_name = data[offset + 120 : offset + name_end].decode("utf-8")
                        new_name = rename_map.get(current_name)
                        if new_name and new_name != current_name:
                            buffer[0:120] = data[offset : offset + 120]
                            name_bytes = new_name.encode("utf-8")
                            name_len = len(name_bytes)
                            buffer[120 : 120 + name_len] = name_bytes

                            while name_len % 4 != 0:
                                buffer[120 + name_len] = 0
                                name_len += 1

                            buffer[8:16] = struct.pack("Q", 120 + name_len)
                            buffer[16:32] = hashlib.md5(buffer[32 : 120 + name_len]).digest()
                            writer.write(buffer[0 : 120 + name_len])
                            rename_count += 1
                            wrote_packet = True

                    if not wrote_packet:
                        writer.write(data[offset : offset + packet_size])

                    offset += packet_size

                    if offset >= REFILL_AT:
                        data = data[offset:data_size] + reader.read(READ_CHUNK - (data_size - offset))
                        data_size = len(data)
                        offset = 0

            if rename_count == 0:
                os.remove(temp_path)
                return 0

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

    return rename_count


HASH_EXTENSIONS = {
    ".sha512": "sha512",
    ".sha256": "sha256",
    ".md5": "md5",
}

HASH_LINE_RE = re.compile(r"^([a-fA-F0-9]+)\s+(\S+)\s*$")


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
        for line in handle:
            stripped = line.rstrip("\r\n")
            if not stripped.strip() or stripped.lstrip().startswith("#"):
                records.append({"type": "raw", "raw": stripped})
                continue
            match = HASH_LINE_RE.match(stripped.strip())
            if not match:
                records.append({"type": "raw", "raw": stripped})
                continue
            path_field = match.group(2)
            records.append(
                {
                    "type": "entry",
                    "hash": match.group(1).lower(),
                    "path": path_field,
                    "basename": hash_path_basename(path_field),
                    "raw": stripped,
                }
            )
    return records


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


def list_source_names(par_file_path):
    folder_path, par_files = find_par2_set(par_file_path)
    index_file = par_files[0]
    for candidate in par_files:
        if ".vol" not in candidate.lower():
            index_file = candidate
            break

    _, source_names = read_source_names(folder_path, index_file)
    print(f"PAR2 set in: {folder_path}")
    print(f"PAR2 files: {len(par_files)}")
    print(f"Source files: {len(source_names)}")
    print()
    for name in source_names:
        print(name)


def apply_renames(par_file_path, rename_args):
    folder_path, par_files = find_par2_set(par_file_path)
    index_file = par_files[0]
    for candidate in par_files:
        if ".vol" not in candidate.lower():
            index_file = candidate
            break

    set_id, source_names = read_source_names(folder_path, index_file)
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
            print(
                "Usage: par2-pgm-rename.py hash verify|update <directory> [par2-index]",
                file=sys.stderr,
            )
            return 1
        except (ValueError, OSError) as error:
            print(f"Error: {error}", file=sys.stderr)
            return 1

    if len(argv) < 2:
        usage()
        return 1

    par_file_path = argv[1]
    rename_args = argv[2:]

    try:
        if not rename_args:
            list_source_names(par_file_path)
            print()
            print("To rename, add pairs as: old filename//new filename")
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
