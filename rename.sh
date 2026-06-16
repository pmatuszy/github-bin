#!/usr/bin/env bash
# 2026.06.16 - v. 19.208.150000 - DB maintenance hash backfill verbose lines: include date/time stamp
# 2026.06.16 - v. 19.207.140000 - fix hash backfill set -e abort when jobs-remaining decrements to 0
# 2026.06.16 - v. 19.206.130000 - DB maintenance hash backfill TTY bar: 80 columns wide (was 20)
# 2026.06.16 - v. 19.205.120000 - DB maintenance hash backfill (non-verbose): TTY in-place bar + ETA; log file 5% milestones; no dot rows
# 2026.06.16 - v. 19.204.070000 - fix DB maintenance Ctrl-C: initialize stopped_by_user before maintenance (set -u)
# 2026.06.15 - v. 19.203.140000 - Ctrl-C during DB maintenance: flush pending SQL and print maintenance/backfill summary instead of silent exit
# 2026.06.15 - v. 19.202.120000 - DB maintenance hash backfill (non-verbose): milestone line every 1% or every 1000 hashes
# 2026.06.14 - v. 19.201.170000 - DB maintenance hash backfill: inventory (md5/sha512 slots), countdown in verbose, dots in non-verbose; AUTO+FULL profiles; fill each missing slot independently
# 2026.06.14 - v. 19.200.160000 - Olympus voice recorder: DM######.MP3/.WMA/.WAV (same rename rules as MP3)
# 2026.06.14 - v. 19.199.150000 - checksum group: target exists → same collision menu as plain renames (MD5, times, [O]/[C]/…)
# 2026.06.14 - v. 19.198.140000 - Olympus voice recorder DM######.MP3 → YYYYMMDD_HHMMSS_-_-_Olympus_voice_recorder-DM….MP3 (oldest exif/stat date)
# 2026.06.14 - v. 19.197.130000 - collision: [V] list directory; [C] overwrite all dest in this directory; drop duplicate [W]
# 2026.06.13 - v. 19.196.233000 - non-verbose: skip lone progress dot after [DRY-RUN] stdout status lines
# 2026.06.13 - v. 19.195.231500 - GoPro Mission 1 rename labels: GoPro_Mission1_Pro (not GOPRO_MISSION1PRO)
# 2026.06.13 - v. 19.194.224800 - GoPro Mission 1: GP######.JPG, firmware H26, Camera Model Name fallback
# 2026.06.12 - v. 19.193.190000 - after rename, update matching paths in _exclude-rename.sh.txt and print EXCLUDE FILE UPDATED lines
# 2026.06.12 - v. 19.192.180000 - help (-h): prompt to show environment tunables [y/N] default N, 5s timeout
# 2026.06.12 - v. 19.191.171500 - --date-placement front|original for BBC/iPlayer -date_ names (original: compact YYYYMMDD_HHMMSS in title, not at start)
# 2026.06.12 - v. 19.190.163000 - thumbs.db prompt [O]: delete this file and auto-delete all other thumbs.db for the rest of the run
# 2026.06.12 - v. 19.189.120000 - wrapped old→new: old and new paths start in the same column (line 2 indent = prefix width)
# 2026.06.12 - v. 19.188.120000 - wrapped Renamed/old→new: arrow + new path on line 2, column-aligned under prefix
# 2026.06.11 - v. 19.187.120000 - always skip _rename.sh.resume-state.json (any directory); check early in main loop
# 2026.06.11 - v. 19.186.120000 - Call recording <callee>_YYMMDD_HHMMSS → YYYYMMDD_HHMMSS_<callee>_Call_recording
# 2026.06.11 - v. 19.185.120000 - flatten prompt [C]: custom exclude pattern (incl. FLATTEN_EXACT=); match globs/fragments
# 2026.06.11 - v. 19.184.120000 - Anruf_aufnehmen: callee id may be phone digits or text (parse YYMMDD_HHMMSS from right)
# 2026.06.11 - v. 19.183.120000 - fix Anruf_aufnehmen =~ syntax (drop negated match; match normalized stem)
# 2026.06.11 - v. 19.182.120000 - Anruf aufnehmen <phone>_YYMMDD_HHMMSS → YYYYMMDD_HHMMSS_<phone>_Anruf_aufnehmen
# 2026.06.11 - v. 19.181.120000 - checksum verify: match sha512 lines with or without ./ prefix (ffmpeg-voice / sha512sum cwd style)
# 2026.06.09 - v. 19.180.120000 - rename/checksum prompts [C]: type custom exclude pattern, append to exclude file immediately
# 2026.06.10 - v. 19.179.174500 - embedded -date_YYYY-MM-DD_HH_MM_SS[_tail] (BBC/Our World exports) → YYYYMMDD_HHMMSS_title[_tail]; before and after hyphen compaction
# 2026.06.10 - v. 19.178.172000 - Signal timestamp-first: run before and after hyphen date compaction (idempotent; catches partial compact / reorder-safe)
# 2026.06.10 - v. 19.177.170000 - Signal signal-YYYY-MM-DD-HH-MM-SS[-tail]: timestamp first before hyphen date compaction (fixes signal-20260606-12-00-47-325 stuck after partial compact)
# 2026.06.10 - v. 19.176.163000 - Sony XAVC clip pairs C####.MP4 + C####M01.XML: CreationDate local wall-clock → YYYYMMDD_HHMMSS_-_-_MANUFACTURER_MODEL_C####[M01].ext; defer XML until MP4
# 2026.06.10 - v. 19.175.160000 - Screenshot_YYYY-MM-DD-HH-MM-SS + title tail (e.g. ...29 o prof. Miernowskim.jpg) → YYYYMMDD_HHMMSS_title-screenshot.ext
# 2026.06.10 - v. 19.174.154400 - fix Screenshot timestamp-first doubled basename (if-test leaked printf stdout); prefer Screenshot_YYYYMMDD-HH-MM-SS over ambiguous YYYY-MM-DD split
# 2026.06.10 - v. 19.173.150500 - Screenshot_* date+time (incl. Huawei Screenshot_YYYY-MM-DD-HH-MM-SS) → YYYYMMDD_HHMMSS-screenshot.ext; skip partial hyphen date compaction on Screenshot_ stems
# 2026.06.10 - v. 19.172.144800 - prompt [V]/[W] directory listing: print to stderr (visible when prompt runs inside $(...) e.g. GoPro lone _part_XX)
# 2026.06.10 - v. 19.171.140000 - archive/compressed (.zip .rar .tar .7z .gz etc.): preserve leading _ / __ through transform_basename (do not strip)
# 2026.06.10 - v. 19.170.133500 - checksum .sha512/.md5: preserve leading _ / __ on hash filenames through transform_basename; block rename only for _sumy_kontrolne.md5 manifest
# 2026.06.10 - v. 19.169.131000 - interactive prompts: [V] view parent directory on path-related menus (checksum, collision [W], mapping, NEF+XMP, flatten, lnk, DB hash, etc.)
# 2026.06.10 - v. 19.168.124500 - GoPro lone _part_XX prompt: [V] list parent directory (same listing as main rename prompt); re-prompt after listing
# 2026.06.10 - v. 19.167.121000 - transform_basename: Windows Screenshot YYYY-MM-DD HHMMSS in one pass (spaces + validated date + time); embedded YYYY-MM-DD hyphen compaction; finish pass after separator normalize
# 2026.06.09 - v. 19.166.233500 - GoPro _Proxy suffix: use Proxy not _Proxy in suffix segment (format already adds underscore; fixes __Proxy)
# 2026.06.09 - v. 19.165.232500 - rename prompt [V]: list parent directory (and inside OLD when it is a directory); re-prompt after listing
# 2026.06.09 - v. 19.164.180000 - startup defaults: colors yes, mode real, scope subdirs (Enter accepts on each prompt)
# 2026.06.09 - v. 19.163.172500 - rename prompt [S]: auto-yes for rest of directory across all extensions (not only anchor ext; fixes re-prompt when jpg/mp4 interleave)
# 2026.06.09 - v. 19.162.150000 - OLD prompt/preview lines yellow instead of red (readability); GoPro metadata rename separator _-_-_ instead of _-__-_ (legacy _-__-_ still recognized for _part_XX helpers)
# 2026.06.06 - v. 19.161.171300 - non-verbose: retract/skip lone progress dot around main rename OLD/NEW prompts
# 2026.06.06 - v. 19.160.131500 - GoPro exiftool date: take first Create Date line before tr -d newline (fixes doubled YYYYMMDD_HHMMSS in GOPR JPG names)
# 2026.06.06 - v. 19.159.125100 - GoPro [D]/[A]: persist strip flags across transform_name subshell; auto-rename without main prompt
# 2026.06.06 - v. 19.158.002500 - GoPro prompts: choice on same line as read_single_key; retract lone non-verbose progress dot before prompts
# 2026.06.06 - v. 19.157.002100 - GoPro lone _part_XX: return 0 when not applicable (fix set -E ERR trap abort in transform_name)
# 2026.06.02 - v. 19.156.120000 - Plain rename: update local .sha512/.md5 refs immediately; GoPro lone _part_XX prompt [D] directory / [A] whole run
# 2026.06.05 - v. 19.155.231500 - GoPro: omit _part_XX when only one chapter in dir; prompt to strip lone _part_XX from already-renamed files
# 2026.06.05 - v. 19.154.230000 - rename prompt [B]: skip directory where this file lives and entire subtree (SUBTREE= in exclude file)
# 2026.06.03 - v. 19.153.120000 - non-verbose: no main-loop progress dot on checksum files; skip dot after checksum-group OK (no lone "." between groups)
# 2026.06.02 - v. 19.152.160000 - fix colored "Renamed:" line: printf used %s for RESET so literal \e[0m appeared at end of line (now %b%s%b for green new path + reset)
# 2026.06.02 - v. 19.151.143000 - transform_basename: compact validated embedded dotted dates YYYY.M(M).D(D) anywhere in the stem (not only leading) → YYYYMMDD; year>=1980, real month/day; e.g. config_EdgeCHE_as_of_2021.11.01_040001.cfg.bz2.ssl → ..._20211101_040001...
# 2026.06.02 - v. 19.150.124500 - non-verbose checksum progress letters: small/single-reference lists (< NONVERBOSE_CHECKSUM_LIST_PER_LETTER_THRESHOLD) print NO S/M/H letters (a lone "S" between status lines was just noise); the ramp is kept only for very large lists (>= threshold)
# 2026.06.02 - v. 19.149.104500 - when colors enabled, entire NEW suggested-name lines (label + path) print in green (checksum preview, OLD/NEW prompts, arrow renames); OLD padded lines whole-line red
# 2026.06.02 - v. 19.148.103000 - non-verbose: a run of "DB SKIP" cache hits no longer alternates "DB SKIP" / "." — suppress the lone progress dot after a DB SKIP line (mirrors auto-dir "Renamed:"), so consecutive cache hits read as clean "DB SKIP" lines
# 2026.06.02 - v. 19.147.101500 - summary: "Affected entries (last 100)" lists only renames from THE CURRENT run (resume no longer shows stale entries from previous runs); header becomes "Affected entries this run (last 100):" on a resumed run, and prints "No entries affected this run" when a resumed run changed nothing
# 2026.06.02 - v. 19.146.095900 - resume: non-verbose "N out of total" continues from the checkpoint position (offset = discovered paths already matched/skipped this run + this-session examined, capped at total) so a resumed run is visibly counting from ~position, not from 1
# 2026.06.02 - v. 19.145.095000 - transform_basename: validated leading dotted date YYYY.M(M).D(D) + any non-digit separator → YYYYMMDD + rest (year>=1980, real month/day incl. leap years), then normalize; e.g. "2018.03.16 - LG ....sha512" → "20180316_-_LG_....sha512"
# 2026.06.01 - v. 19.144.154000 - window title: "[ cwd ] full_script_path options" (spaces inside brackets); also set GNU screen / tmux window name (ESC k) so it shows inside screen/tmux, not only xterm/VTE
# 2026.06.01 - v. 19.143.150000 - transform_basename: dotted date + separated time (YYYY.MM.DD <sep> HH<sep>MM<sep>SS[_tail]) → YYYYMMDD_HHMMSS[_tail] for any extension (e.g. checksum .sha512/.md5 sidecars)
# 2026.05.31 - v. 19.142.231100 - GoPro/camera raw: guard transform_gopro_camera_basename under set -e/ERR trap (no-metadata return 1 no longer prints "ERROR: command failed at line ..."); fall back to normal rename quietly
# 2026.05.31 - v. 19.141.183500 - GoPro/camera raw + exiftool missing: stop polluting suggested NEW name (stderr not stdout); one-time prompt suggests video-pgm-install-exiftool.sh and offers [S]kip-this-run / [Q]uit
# 2026.05.31 - v. 19.140.183200 - --version: print a short version banner (name + version) and exit; no paths/usage
# 2026.05.26 - v. 19.139.151200 - GoPro exiftool: RENAME_EXIFTOOL defaults to bundled luks-buffalo2 path when unset (EXIFLOC still overrides)
# 2026.05.26 - v. 19.138.150500 - GoPro rename: default exiftool at luks-buffalo2 Image-ExifTool path; EXIFLOC/RENAME_EXIFTOOL override; skip camera raw files with hint if missing
# 2026.05.26 - v. 19.137.143000 - GoPro camera files (GH/GX/ch/gx MP4, GOPR JPG): exiftool metadata rename to YYYYMMDD_HHMMSS_-__-_MODEL (from zmien-nazwe-CURRENT_DIRECTORY.sh)
# 2026.05.21 - v. 19.136.121500 - copy-series pad: include already-renamed siblings (Nasza_bomba_11.mp3) when computing max N so late files still get 04 not 4
# 2026.05.21 - v. 19.135.120000 - transform_basename: zero-pad media copy-series (N) before separator normalize; width from max N in same directory (2 digits for 10–99, 3 for 100+)
# 2026.05.19 - v. 19.134.114531 - Collision prompt: [P] delete source (keep destination; skip rename); [V] delete destination then rename (same as [O])
# 2026.05.09 - v. 19.133.154136 - SCRIPT_VERSION taken from this line: v. aa.bbb.HHMMSS — aa = month counter (19 now; bump aa next month); bbb = edit counter this month, add 1 on every edit (…125, 126, 127…); HHMMSS = local 24h wall-clock time for that edit (not computed at runtime). Every history row keeps the full triplet (aa.bbb.HHMMSS), not only this line. Workflow: insert a new top row with the next bbb and a new HHMMSS; push the prior first row down unchanged (it already carries its timestamp).
# 2026.05.09 - v. 19.132.112134 - Checksum recovery: capture find_best_path_for_missing_ref exit with set -e (return 1 is normal failure; command substitution must not abort the script)
# 2026.05.09 - v. 19.131.111354 - Ctrl-C cleanup: ignore nested SIGINT until summary; first-line feedback + faster checkpoint save (Python dedupe+JSON from streamed keys)
# 2026.05.09 - v. 19.130.110644 - Ctrl-C during interrupt cleanup: ignore nested SIGINT until summary (was trap - INT then second ^C killed shell before print_summary during slow checkpoint save)
# 2026.05.09 - v. 19.129.105425 - Resume: explain discovery vs checkpoint overlap; dedupe saved paths; mark built-in excluded paths processed; warn on low key match rate
# 2026.05.09 - v. 19.128.105224 - Resume checkpoint note about non-verbose progress wraps to MAX_LINE_LENGTH (continuation uses WRAP_MSG_INDENT)
# 2026.05.09 - v. 19.127.104821 - SCRIPT_VERSION history line documents bbb +1 per edit; HHMMSS documents time of that edit
# 2026.05.08 - v. 19.126.104609 - Checksum missing-ref recovery: try path rebuilt by transform_basename on each relative segment (parent dirs renamed); SKIP output shows that path when still missing
# 2026.05.08 - v. 19.125.172551 - Non-verbose main-loop "n out of total": numerator is paths examined this session (files_examined minus checkpoint baseline), not cumulative across prior interrupted runs
# 2026.05.08 - v. 19.124 - NEF+XMP RawFileName prompt: print question with printf so read_single_key answers on the same line; less blank spacing before keys
# 2026.05.08 - v. 19.123 - transform_basename: YYYY Mon DD HH-MM-SS.ext (English month abbr, spaces) → YYYY_Mon_DD_HH-MM-SS.ext
# 2026.05.08 - v. 19.122 - path_basename_is_thumbs_db: treat backslashes like slashes (Windows paths in checksum lists) so missing Thumbs.db refs get the remove-from-hash prompt
# 2026.05.08 - v. 19.121 - Resume: non-verbose main-loop milestone uses files_examined (not slot index); checkpoint paths register ./ and no-./ keys for processed lookup
# 2026.05.08 - v. 19.120 - Plain rename prompt: when path is a directory and --use-db, ask about updating DB entries for that subtree
# 2026.05.08 - v. 19.119 - Checksum mismatch: [I] ignore ref and continue; no full-verify state if any [I]; before/after rename show NOTE instead of VERIFIED/OK when [I] used
# 2026.05.08 - v. 19.118 - emit_wrap_old_arrow_new_stdout: when one line does not fit, print prefix+old+arrow on line 1 and indented new on line 2 (avoids lone “Renamed:” plus a wrapped old→new)
# 2026.05.08 - v. 19.116 - Checksum group preview: pad OLD/NEW labels to one width so hash-file and referenced paths start in the same column
# 2026.05.08 - v. 19.115 - transform_name: plain PXL_<digits>.ext via file birth/mtime; IMG/PXL stem-preserving rules
# 2026.05.08 - v. 19.114 - transform_name: IMG_* / PXL_* (embedded YYYYMMDD_HHMMSS) → YYYYMMDD_HHMMSS-<original stem>.ext; plain IMG_<digits> uses file birth/mtime for prefix
# 2026.05.08 - v. 19.113 - Collision prompt: [D] session — auto _OTHER (like [R]) for all further collisions whose source file is in the same directory
# 2026.05.08 - v. 19.110 - Window title: [invocation cwd] before resolved script path + argv
# 2026.05.08 - v. 19.109 - Version banner: semantic v from first line + local HHMMSS (e.g. 19.109.101646)
# 2026.05.08 - v. 19.108 - Large checksum prompt: skip [y/N/q] when line count is high but sum of on-disk target file sizes is below LARGE_HASHFILE_PROMPT_MIN_TOTAL_BYTES (default 30 GiB)
# 2026.05.08 - v. 19.107 - Collision _OTHER: single _OTHER + numeric disambiguation (_OTHER_2, …); collapse stacked *_OTHER_OTHER* in transform targets; strip trailing _OTHER before allocating
# 2026.05.08 - v. 19.106 - User prompts: prefix question lines and choice/readline prompts with (YYYY.MM.DD HH:MM:SS) local time; verbose_question_timestamp can log to stderr for mapping helpers
# 2026.05.08 - v. 19.105 - Large checksum-list prompt: show last successful full-verify time (absolute + relative); state under RENAME_CHECKSUM_VERIFY_STATE_DIR; record after all refs pass
# 2026.05.07 - v. 19.104 - NONVERBOSE_CHECKSUM_RAMP_CHARS: optional export/prefix override (default unchanged); -h lists it with a safe quoted example
# 2026.05.07 - v. 19.103 - -h/--help: alphabetized tunable env vars with examples; tunables honor prefix assignment or export at startup
# 2026.05.07 - v. 19.102 - Non-verbose checksum list progress: per-letter below NONVERBOSE_CHECKSUM_LIST_PER_LETTER_THRESHOLD (default 3000); batched min(n/10, max char cap) at/above; caps are script/env vars
# 2026.05.07 - v. 19.101 - Window title uses resolved script path; non-verbose main loop: every NONVERBOSE_MAIN_LOOP_PROGRESS_EVERY_N slots print "k out of total" line (ends dot row first)
# 2026.05.07 - v. 19.100 - SSH/terminal window title: set to script basename + all argv after parse; restore via CSI 23t on EXIT
# 2026.05.07 - v. 19.99 - Ctrl-C: one INT handler (rollback + checkpoint + summary); remove duplicate early on_interrupt; set -e-safe || true so summary always runs
# 2026.05.07 - v. 19.98 - Non-verbose checksum list progress: <500 entries → one S/M/H per line/ref; ≥500 → one letter per min(50,max(1,n/10)) entries (ramp between)
# 2026.05.07 - v. 19.97 - thumbs.db / torrent .URL no-op prompts: explain identical OLD/NEW; clearer menu; default skip without yellow wall + db_mark_checked
# 2026.05.07 - v. 19.96 - FILE= basename exceptions: apply to files and directories; [F] at rename prompt for dirs too (skip basename everywhere)
# 2026.05.07 - v. 19.95 - Directory renames: prompt says directory; SQLite subtree rewrite updates all checked_paths under prefix (not only warmed cache keys)
# 2026.05.07 - v. 19.94 - SQLite cache present prompt: [Q] Quit (same pattern as resume / DB hash prompts)
# 2026.05.07 - v. 19.93 - NEF+XMP: if XMP has no RawFileName markup, skip RawFileName prompts/notes (do not suggest adding it)
# 2026.05.07 - v. 19.92 - NEF+XMP RawFileName prompts: clarify metadata-only patch inside .xmp (not renaming paths); note recovery XMP may omit crs:RawFileName
# 2026.05.07 - v. 19.91 - transform_basename: same date-first rule for VID-YYYYMMDD-* as IMG- (gallery/WhatsApp)
# 2026.05.07 - v. 19.90 - transform_basename: trailing YYYY-MM-DD-HH-MM-SS → YYYYMMDD_HHMMSS_ prefix; IMG-YYYYMMDD-* (e.g. WhatsApp) → YYYYMMDD_IMG-* at start + normalize
# 2026.05.07 - v. 19.89 - NEF+XMP prompt: narrow OLD/NEW padding when no sidecar; transform_basename: ...-YYYY-MM-DD-HH-MM-SS.ext → ..._YYYYMMDD_HHMMSS.ext + normalize
# 2026.05.07 - v. 19.88 - NEF+XMP rename prompt: pad OLD/NEW/(sidecar) labels to same width so paths align
# 2026.05.07 - v. 19.87 - transform_basename: YYYY-MM-DD + HH-MM-SS camera rule now runs _normalize_basename_separators (spaces→_, collapse) on full result; early return had skipped that pass
# 2026.05.07 - v. 19.86 - NONVERBOSE_CHECKSUM_LETTER_CYCLE_EVENTS default 100 (was 50)
# 2026.05.07 - v. 19.85 - non-verbose checksum: S/M/H every stride * NONVERBOSE_CHECKSUM_LETTER_CYCLE_EVENTS (default 50, was 10); ramp maps across cycle-1 steps
# 2026.05.07 - v. 19.84 - non-verbose checksum ramp: backspace+overwrite in one cell until S/M/H; then advance column (fixes appended ramp strings on TTY)
# 2026.05.07 - v. 19.83 - non-verbose checksum ramp: ASCII step every N events (NONVERBOSE_CHECKSUM_EVENT_STRIDE_N), S/M/H every N*10; large hash lists prompt [y/N/q] default N (LARGE_HASHFILE_LINE_PROMPT_THRESHOLD)
# 2026.05.07 - v. 19.82 - non-verbose M/S/H: print one letter per 10 checksum progress events (resolve + verify + whole-file check share one counter)
# 2026.05.07 - v. 19.81 - non-verbose: one M/S/H per checksum list line when resolving refs (replaces verbose-only "Resolved ref" lines for that phase)
# 2026.05.07 - v. 19.80 - M/S/H: verify every checksum list ref (before/after rename + no-rename-needed real runs); whole-file checksum_check emits one letter; no-op groups skip dry-run verify
# 2026.05.07 - v. 19.79 - non-verbose progress (dots + M/S/H): write to /dev/tty when available (stdout is often block-buffered when not a TTY)
# 2026.05.07 - v. 19.78 - fix nonverbose_progress_stdout_line_char: use "verbose -> skip" (was inverted; dots and M/S/H never printed)
# 2026.05.07 - v. 19.77 - non-verbose checksum ref verify: M/S/H letters (same line wrap as dots) instead of silent checks
# 2026.05.07 - v. 19.76 - current-scope discovery Python: restore import sys (stdin/stdout/stderr)
# 2026.05.07 - v. 19.75 - current-directory scope: fast find→sort→shell path (no 64 MB read loop); clearer startup message (no full-tree wording)
# 2026.05.07 - v. 19.74 - NEF+XMP sidecar help text: flush-left lines ≤ MAX_LINE_LENGTH, breaks at sentence ends
# 2026.05.07 - v. 19.73 - NEF+XMP interactive prompt: explain sidecar RawFileName update after rename (comfort text)
# 2026.05.07 - v. 19.72 - non-verbose: skip one main-loop progress dot after auto-dir “Renamed:” line (avoids lone “.” between consecutive renames)
# 2026.05.07 - v. 19.71 - NEF+XMP “no rename needed” vlog: header + each path on own lines; slash-aware wrap (not fold -s on whole line)
# 2026.05.07 - v. 19.70 - non-verbose progress dots: newline every MAX_LINE_LENGTH dots so one line never exceeds that width
# 2026.05.06 - v. 19.69 - non-verbose main loop: print '.' per examined file; end dot line before other stdout or prompts
# 2026.05.06 - v. 19.68 - NEF+XMP RawFileName prompt: multi-line Keys menu (readability)
# 2026.05.06 - v. 19.67 - NEF+XMP RawFileName prompt: default yes ([Y/n/d/q]; Enter accepts)
# 2026.05.06 - v. 19.66 - NEF+XMP RawFileName: bold/colored verification line outside box; [d]irectory batch auto-apply (no further prompts in that dir)
# 2026.05.06 - v. 19.65 - NEF+XMP filesystem box: fold long lines (no filename truncation via %.*s)
# 2026.05.06 - v. 19.64 - vlog: fold long messages (was one huge continuation line after [VERBOSE])
# 2026.05.06 - v. 19.63 - NEF+XMP filesystem proof: Unicode box around paired NEF details (dynamic width ≤128 cols, long lines truncated)
# 2026.05.06 - v. 19.62 - NEF+XMP RawFileName prompt: verify proposed basename exists beside sidecar (inode match), ls/stat + ad-hoc md5 (no DB write), summary line old→new
# 2026.05.06 - v. 19.61 - NEF+XMP: RawFileName as element (<crs:RawFileName>...</crs:RawFileName>) or attribute; show current vs proposed fragment before confirm prompt
# 2026.05.06 - v. 19.60 - NEF+XMP: sync crs/RawFileName in sidecar to renamed NEF basename (preserve XMP mtime); always verify/prompt-fix mismatches (dry-run notes only)
# 2026.05.06 - v. 19.59 - verbose: one line for Samba/exfat case-only skip + “no rename” (main loop + checksum no-action); defer checksum ref/sum drop vlogs when group has no action
# 2026.05.06 - v. 19.58 - --version: same boxed banner as -h (adds DB + exclude lines); print_startup_banner optional detail mode
# 2026.05.06 - v. 19.57 - transform_name: Sprache_/Voice_ rule — always lowercase sprache label; tail case preserved (Voice unchanged)
# 2026.05.06 - v. 19.56 - transform_name: Sprache/Voice/Screen_Recording/YYYYMMDD-HHMMSS_slug media tails — preserve letter case (only slug non-alnum to hyphens)
# 2026.05.06 - v. 19.55 - transform_basename: date ranges YYYY.MM.DD-YYYY.MM.DD and YYYY.MM.DD-YYYY.MM-DD → YYYYMMDD-YYYYMMDD_tail (before single dotted-date rule)
# 2026.05.07 - v. 19.54 - transform_basename: YYYY.MM.DD-YYYY.MM.DD range → YYYYMMDD_YYYYMMDD_tail (dirs + files; before single dotted-date rule)
# 2026.05.07 - v. 19.53 - DB-cache checksum probe: save/restore ERR trap at caller (RETURN trap restored ERR before return 1 unwound under set -E)
# 2026.05.07 - v. 19.52 - checksum_file_has_renamable_refs: suppress ERR trap for intentional return 1/2 (set -E + errtrace fires on function return)
# 2026.05.07 - v. 19.51 - checksum_file_has_renamable_refs: avoid ERR/set -e on final return 1 (RETURN trap + no inner errexit toggle)
# 2026.05.07 - v. 19.50 - if SQLite cache file exists in start dir and --use-db omitted, prompt to enable it (default Y)
# 2026.05.07 - v. 19.49 - if findmnt is missing, print one-time install hint (util-linux) for mount-type detection
# 2026.05.07 - v. 19.48 - case-only skip: also FUSE SMB (GVFS fuse.gvfsd-fuse, smb path/SOURCE; fuse.rclone smb hints)
# 2026.05.07 - v. 19.47 - skip case-only renames (full basename incl. ext) on exfat and CIFS/Samba mounts (no prompt / no mv)
# 2026.05.07 - v. 19.46 - transform_basename: YYYY.MM.DD-tail.ext -> YYYYMMDD_tail.ext (dotted date prefix)
# 2026.05.06 - v. 19.45 - case-only: mv A→B→C with B in same directory as A/C only (no /tmp or TMPDIR)
# 2026.05.06 - v. 19.44 - case-only: mv only — A→B under TMPDIR then B→C (same-dir B breaks ci-CIFS “same file”)
# 2026.05.06 - v. 19.43 - case-only: mv A→random B→C only (same dir); drop TMPDIR copy pipeline
# 2026.05.06 - v. 19.42 - CRITICAL case-only: stage copy in local TMPDIR then cp→share (no hardlink/rm on ci-CIFS — deletes file)
# 2026.05.06 - v. 19.41 - case-only: if uniq and new are same inode (ci-CIFS), rm uniq not cp; restore path uses same guard
# 2026.05.06 - v. 19.40 - case-only final hop: mv uniq→new, else cp -p+cmp+rm uniq (CIFS mv-to-case-variant fails); cmp fallback to diff -q
# 2026.05.06 - v. 19.39 - CRITICAL case-only: hardlink (or cp+cmp) then rm old then mv uniq→new — never os.replace-only on CIFS (data loss risk)
# 2026.05.06 - v. 19.38 - case-only: exactly two hops mv old→.___ABC_case_uniq_*→new (bash + Python os.replace); drop three-hop
# 2026.05.06 - v. 19.37 - case-only Python: POSIX os.replace only (no cmd.exe); for Linux including CIFS/SMB mounts
# 2026.05.06 - v. 19.36 - case-only Python: final hop via cmd.exe ren on Win/MSYS/Cygwin + verify target exists (fix orphan .___case_ren_py_*.tmp)
# 2026.05.06 - v. 19.35 - case-only same-dir: three hops old→B₁→B₂→final (bash mv + Python); avoids MSYS mistaking B₁ and final for same file
# 2026.05.06 - v. 19.34 - case-only: try Python two-hop first when python3 exists (MSYS mv second hop falsely reports same file on NTFS)
# 2026.05.06 - v. 19.33 - case-only intermediate B always in same directory as file (no TMPDIR/parent staging)
# 2026.05.06 - v. 19.32 - case-only: always via intermediate B only (mv A→B→A'; Python matches); remove MoveFileEx / Python-before-mv
# 2026.05.06 - v. 19.31 - case-only: always stage via TMPDIR first (not only MSYS); try Python MoveFileExW when WINDIR (before bash mv)
# 2026.05.06 - v. 19.30 - case-only rename: python3 two-step os.replace via TMPDIR when bash mv still fails (MSYS)
# 2026.05.06 - v. 19.29 - case-only mv on MSYS/Cygwin: stage via TMPDIR mktemp first (parent-dir staging still hit NTFS same-file mv bug)
# 2026.05.06 - v. 19.28 - case-only mv: stage temp one directory above target dir (MSYS/NTFS second mv "same file"); fallback TMPDIR mktemp
# 2026.05.06 - v. 19.27 - rename prompt [S]: auto-yes only for similar names in current dir (same extension; leading _ if anchor had it)
# 2026.05.06 - v. 19.26 - per-directory [D] auto-yes: print each rename in non-verbose; case-only renames use two-step mv for case-insensitive FS
# 2026.05.06 - v. 19.25 - plain renames: .nef + matching .xmp in same directory are one pair (single prompt, both renamed)
# 2026.05.06 - v. 19.24 - checksum mismatch: quitting [Q] shows user-stop message (not "SHA512 incorrect"); finish_current_operation on checksum exits
# 2026.05.06 - v. 19.23 - checksum mismatch: show list-file times, stored hash, on-disk file times+hash before recovery [U]/[Q]
# 2026.05.06 - v. 19.22 - more MAX_LINE_LENGTH wrapping: checksum preview/recovery/thumbs/dry-run, collision details, exceptions via emit_wrap_exclude, summary rename list, torrent/thumbs paths, print_checksum_* helpers
# 2026.05.06 - v. 19.21 - central WRAP_MSG_INDENT + emit_wrap_* helpers; wrap long user-facing echo lines to MAX_LINE_LENGTH
# 2026.05.06 - v. 19.20 - wrap long checksum-group progress / FAIL / VERIFIED / OK lines to MAX_LINE_LENGTH
# 2026.05.06 - v. 19.19 - checksum verify loop: capture exit code with || vrc=$? so set -e does not abort before handling mismatch
# 2026.05.06 - v. 19.18 - wrap long same-inode (case-only) verbose line to MAX_LINE_LENGTH
# 2026.05.06 - v. 19.17 - checksum verify fail: recovery hint + optional [U] refresh hash from disk (before/after rename)
# 2026.05.06 - v. 19.16 - treat Photoshop native formats (.psd .psb .psdt) as media (is_media_file + common_media_ext_re)
# 2026.05.06 - v. 19.15 - YYYY-MM-DD + space/tab/underscore + HH-MM-SS + tail -> YYYYMMDD_HHMMSS early; transform_name tail allows space before title
# 2026.05.06 - v. 19.14 - treat .nef and .xmp as media (is_media_file + common_media_ext_re timestamp rules)
# 2026.04.30 - v. 19.13 - Sprache_/Voice_ YYMMDD_HHMMSS.ext (no tail segment) -> YYYYMMDD_HHMMSS-sprache/voice.ext
# 2026.04.30 - v. 19.12 - restore errexit after set +e captures (transform_name leaked set -e; ERR on checksum return 1)
# 2026.04.30 - v. 19.11 - YYYYMMDD HH-MM-SS[_tail].media -> YYYYMMDD_HH-MM-SS[_tail].media (space/tab before time)
# 2026.04.30 - v. 19.10 - set -e: mapping quit/manual return 0 from choose_*; capture $(transform_basename/name) with set +e
# 2026.04.30 - v. 19.09 - special-char mapping prompts: [o]ther replacement, [q]uit, [m]anual basename edit
# 2026.04.28 - v. 19.08 - offer to remove missing thumbs.db references from checksum files
# 2026.04.28 - v. 19.07 - normalize fully hyphenated YYYY-MM-DD-HH-MM-SS media timestamps with title tails
# 2026.04.28 - v. 19.06 - add [U] session auto-approve for extension-case-only renames on media + Microsoft Office files
# 2026.04.28 - v. 19.05 - normalize YYYYMMDD_at_HH.MM.SS (and HH-MM-SS) into YYYYMMDD_HHMMSS
# 2026.04.28 - v. 19.04 - date-time media normalization also accepts underscore time separators (HH_MM_SS)
# 2026.04.28 - v. 19.03 - when deleting thumbs.db, remove/update local checksum refs that point to it
# 2026.04.28 - v. 19.02 - offer [K] delete for thumbs.db (case-insensitive), including no-op rename cases
# 2026.04.28 - v. 19.01 - normalize YYYY-MM-DD[ _]HH[-.]MM[-.]SS[_tail|-tail].media (incl. mp4) after cleanup pass
# 2026.04.28 - v. 19.00 - normalize YYYY-MM-DD[ _]HH-MM-SS[_tail|-tail].media (incl. mp4) after cleanup pass
# 2026.04.27 - v. 18.99 - show/reuse HTML companion-dir recovery plan and update URL-encoded HTML refs
# 2026.04.27 - v. 18.98 - HTML companion dirs: recover when normalized companion exists; ignore empty target dir collisions
# 2026.04.27 - v. 18.97 - do not rename underscore-leading .par2 files, including checksum-group references
# 2026.04.24 - v. 18.96 - auto-reload _exclude-rename.sh.txt when it changes on disk during long runs; flatten honors new filters
# 2026.04.23 - v. 18.95 - strip _eBook-PL fragment from basenames (alongside _eBook.PL / eBook.PL)
# 2026.04.23 - v. 18.94 - Recording*.m4a: prepend YYYYMMDD_HHMMSS_-_ from oldest of birth/mtime (match case-insensitive)
# 2026.04.23 - v. 18.93 - Audiobook PL strip: _audiobook_pl only when not followed by letters (avoid _AudioBook_Player -> Smartayer)
# 2026.04.23 - v. 18.92 - reload _exclude-rename.sh.txt from disk before/after appending exceptions so external edits apply immediately
# 2026.04.23 - v. 18.91 - exclude file: FILE=basename (or FILE=glob) skips renames for that filename in any directory; prompt [F]
# 2026.04.23 - v. 18.90 - normalize YYYY-MM-DD_at_HH.MM.SS[_tail].ext -> YYYYMMDD_HHMMSS[_tail].ext
# 2026.04.23 - v. 18.89 - same-inode source/target: no rename prompt (case-insensitive FS); extension-only lowercasing for any ext (.MP4); [L] menu widened
# 2026.04.23 - v. 18.88 - underscore-leading .par2: allow renames but preserve leading _ in normalize (was: skip rename entirely)
# 2026.04.23 - v. 18.87 - wrap sqlite3 -uri fallback WARNING to respect MAX_LINE_LENGTH (two lines when needed)
# 2026.04.23 - v. 18.86 - sqlite3 without -uri: probe once, fall back to path open (nolock URI unavailable); warn once
# 2026.04.23 - v. 18.85 - SQLite checked_paths: full column list in CREATE (signature, hashes); batched ALTER migration before WAL; fix warmup SELECT
# 2026.04.23 - v. 18.84 - db_init: drop EXCLUSIVE/BEGIN IMMEDIATE (breaks CIFS); optional bootstrap via local TMPDIR + mv; then nolock URI
# 2026.04.23 - v. 18.83 - --db-maintenance implies maintenance-only (like --run-db-maintenance): skip db_init; exit 0 if cache DB missing
# 2026.04.23 - v. 18.82 - SQLite on broken FS: BEGIN IMMEDIATE schema + optional file URI ?nolock=1 for all DB access (CIFS/NFS SQLITE_BUSY)
# 2026.04.23 - v. 18.81 - db_init: remove orphan -wal/-shm/empty DB before open; busy_timeout + one retry after clearing lock artifacts (SQLITE_BUSY)
# 2026.04.23 - v. 18.80 - db_init: call db_migrate_legacy_file correctly; create SQLite schema before optional WAL pragmas (|| true); clearer init failure hint
# 2026.04.22 - v. 18.79 - preserve leading _ on *_okladka*.jpg cover filenames (media strip + stem normalize)
# 2026.04.22 - v. 18.78 - checksum group: clearer preview labels and prompt text (hash file vs referenced files; what Yes does)
# 2026.04.22 - v. 18.77 - protect .md5/.sha512 whose basename starts with _ or __ from checksum-file rename (keep leading underscores)
# 2026.04.22 - v. 18.76 - rename menu [L]: session auto-yes when suggestion only lowercases a mixed-case 3-letter alphabetic extension
# 2026.04.22 - v. 18.75 - rename menu [T]: delete *torrent*.URL shortcuts; allow no-op renames to menu for those; DB row delete on remove
# 2026.04.22 - v. 18.74 - fix DB path rewrite after mv: resolve old path via parent+basename; checksum file refs + .md5/.sha512 renames update rows
# 2026.04.22 - v. 18.73 - do not rename aggregate checksum manifest _sumy_kontrolne.md5 (basename, case-insensitive)
# 2026.04.22 - v. 18.72 - directories: never stem/ext split (no extensions); normalize full basename like extensionless files
# 2026.04.22 - v. 18.71 - if last-dot suffix has space or brackets (e.g. Site.PL - rest), normalize whole basename not only stem
# 2026.04.22 - v. 18.70 - strip Audiobook PL markers case-insensitively ([AudioBook PL], _AudioBook_PL, etc.; GNU sed I)
# 2026.04.22 - v. 18.69 - drop duplicate verbose_question_timestamp before prompts that echo the same line; green checksum-group question
# 2026.04.22 - v. 18.68 - green highlight for main rename and flatten questions; VERBOSE note: vlog() uses CYAN, many legacy lines use plain echo
# 2026.04.22 - v. 18.67 - transform_basename: replace & with and (M3U key normalize already did; plain renames did not)
# 2026.04.22 - v. 18.66 - strip .ebooksclub. from names (replace with single dot)
# 2026.04.22 - v. 18.65 - wrap long DB hash verbose lines: put path on continuation when prefix+path exceeds MAX_LINE_LENGTH
# 2026.04.22 - v. 18.64 - treat _rename.sh.resume-state.json as internal protected (never prompt rename)
# 2026.04.22 - v. 18.63 - flatten prompt: explain y/N/e/q; skip flatten when sole subdir is VIDEO_TS (DVD layout)
# 2026.04.22 - v. 18.62 - offer [E]/[X] exception options on checksum-group rename prompt (same as plain entries)
# 2026.04.21 - v. 18.61 - let user choose flatten result directory name (parent/child/manual edit with readline)
# 2026.04.21 - v. 18.60 - add flatten-only directory exception option to skip future flatten prompts for exact paths
# 2026.04.21 - v. 18.59 - add prompt to flatten directories that contain only one subdirectory with files
# 2026.04.21 - v. 18.58 - detect duplicated trailing file extensions (e.g. .mp4.mp4) and normalize to a single extension
# 2026.04.21 - v. 18.57 - strip repeated adjacent .WnA. marker fragments reliably during normalization
# 2026.04.20 - v. 18.56 - print startup banner before early resume question while keeping a single banner print in normal flow
# 2026.04.20 - v. 18.55 - speed up FULL maintenance hash backfill via SQL candidate filtering, one-time hash backend detection, and missing-hash partial index
# 2026.04.20 - v. 18.54 - initialize pending SQL temp file in manual maintenance mode so hash backfill updates can be queued safely
# 2026.04.20 - v. 18.53 - fix FULL maintenance hash backfill runtime by using inline md5/sha512 commands without late function dependencies
# 2026.04.20 - v. 18.52 - fix FULL maintenance hash backfill runtime by avoiding pre-definition call to is_checksum_file()
# 2026.04.20 - v. 18.51 - in FULL DB maintenance, backfill any missing md5/sha512 for existing file rows with progress and summary stats
# 2026.04.20 - v. 18.50 - do not defer plain-file renames because of checksum siblings; rename now and let checksum workflow update refs later
# 2026.04.20 - v. 18.49 - defer to checksum workflow only when sibling checksum files actually reference the file being renamed
# 2026.04.20 - v. 18.48 - defer to checksum workflow only when rename is needed and print only checksum siblings that actually exist
# 2026.04.20 - v. 18.47 - split long sibling-checksum defer verbose output into readable multi-line format
# 2026.04.20 - v. 18.46 - force checksum file processing when cached refs still need rename; defer sibling files explicitly to checksum workflow
# 2026.04.20 - v. 18.45 - in verbose mode, print whether DB row was inserted or updated right after plain file rename
# 2026.04.20 - v. 18.44 - add verbose DB subtree rewrite summary lines showing how many cached paths were remapped
# 2026.04.20 - v. 18.43 - preserve hash columns when rewriting DB paths and move DB row on plain file rename
# 2026.04.20 - v. 18.42 - prevent DB cache skip when transform_name indicates rename is still required (e.g. .WnA. cleanup)
# 2026.04.20 - v. 18.41 - avoid duplicate crosscheck/delete progress lines when count and percent thresholds coincide
# 2026.04.20 - v. 18.40 - add explicit delete-phase progress for DB maintenance missing-row cleanup
# 2026.04.20 - v. 18.39 - print DB maintenance crosscheck percent and absolute counters together in one progress line
# 2026.04.20 - v. 18.38 - increase DB maintenance crosscheck progress cadence to every 5% and every 500 checked paths
# 2026.04.20 - v. 18.37 - add DB maintenance crosscheck progress updates every 10% and every 1000 checked paths
# 2026.04.20 - v. 18.36 - wrap verbose DB-maintenance missing-file removal messages into clean two-line output
# 2026.04.20 - v. 18.35 - in verbose DB maintenance, state that missing filesystem files are removed from DB entries
# 2026.04.20 - v. 18.34 - in DB maintenance, verify cached paths exist on disk, remove missing rows, and print prune stats
# 2026.04.20 - v. 18.33 - remove .WnA. marker fragments from filenames during normalization
# 2026.04.20 - v. 18.32 - prompt before replacing existing DB hash values (Y/n/q) and log skip decisions explicitly
# 2026.04.20 - v. 18.31 - make DB hash verbose messages distinguish backfilled hashes from updated existing hashes
# 2026.04.20 - v. 18.30 - fix manual rename-by-editing output stream so prompt text is not captured as destination path
# 2026.04.19 - v. 18.29 - add manual "rename by editing" option with readline editing keys in plain rename prompt
# 2026.04.19 - v. 18.28 - remove periodic main-loop heartbeat verbose lines while keeping startup and resume progress logs
# 2026.04.19 - v. 18.27 - add startup transfer-to-shell progress after sorting so large handoff phase is visible
# 2026.04.19 - v. 18.26 - add verbose checkpoint-restore progress and periodic main-loop heartbeat to show activity
# 2026.04.19 - v. 18.25 - add richer verbose startup progress (buffered size + elapsed time) for long discovery/sort phase
# 2026.04.19 - v. 18.24 - wrap checksum-group referenced-file rename verbose lines using MAX_LINE_LENGTH helper
# 2026.04.19 - v. 18.23 - include timestamps in startup tags as [STARTUP YYYY-MM-DD HH:MM:SS]
# 2026.04.19 - v. 18.22 - show startup discovery/sort progress with verbose dots so long scans do not look stuck
# 2026.04.19 - v. 18.21 - show verbose timestamps on actual question lines (not after choice prompt)
# 2026.04.19 - v. 18.20 - print verbose timestamp before every interactive read_single_key prompt
# 2026.04.19 - v. 18.19 - make --run-db-maintenance imply DB mode and exit cleanly when DB file is missing
# 2026.04.19 - v. 18.18 - make DB maintenance manual-only via --run-db-maintenance and show verbose command steps
# 2026.04.19 - v. 18.17 - add SQLite maintenance modes (auto/off/full) with periodic optimize/checkpoint metadata
# 2026.04.19 - v. 18.16 - make early resume prompt quit option exit immediately
# 2026.04.19 - v. 18.15 - add quit option [q] to resume prompt flow
# 2026.04.19 - v. 18.14 - make ask-mode resume prompt default to resume ([Y/n]) to match default resume behavior
# 2026.04.19 - v. 18.13 - show resume first in --resume-state help values
# 2026.04.19 - v. 18.12 - make resume-state default to automatic resume and reflect it in help text
# 2026.04.19 - v. 18.11 - ask for resume immediately after CLI parsing and before startup preparation
# 2026.04.19 - v. 18.10 - mark default values in help option choices with [ ]
# 2026.04.19 - v. 18.9 - add interrupt checkpoint resume support with --resume-state mode
# 2026.04.19 - v. 18.8 - wrap long checksum verbose lines using MAX_LINE_LENGTH without splitting filenames
# 2026.04.19 - v. 18.7 - speed up DB hash cache lookups and avoid repeated subtree find scans during missing-ref recovery
# 2026.04.19 - v. 18.6 - bump script version
# 2026.04.19 - v. 18.5 - in verbose mode print a boxed startup summary of effective options with explanations
# 2026.04.19 - v. 18.3 - add a help example line and reorder displayed --mode/--scope option choices
# 2026.04.19 - v. 18.2 - derive SCRIPT_VERSION automatically from the first history line instead of hardcoding it
# 2026.04.18 - v. 18.1 - add exact path exceptions so a directory can be protected from rename while its subtree is still checked
# 2026.04.18 - v. 18.0 - broaden transform_name timestamp-style media renames to common audio extensions
# 2026.04.18 - v. 17.9 - rename Sprache_YYMMDD_HHMMSS_suffix and Voice_YYMMDD_HHMMSS_suffix media files to timestamped sprache/voice names
# 2026.04.18 - v. 17.8 - generalize Screen_Recording_YYYYMMDD_HHMMSS_suffix media renaming to timestamped screen_recording-<suffix> names
# 2026.04.18 - v. 17.7 - rename Screen_Recording_YYYYMMDD_HHMMSS_Signal media files to timestamped screen_recording-signal names
# 2026.04.15 - v. 17.6 - treat M3U helper exit code 3 as no-change under set -e and do not abort in wrapper/caller paths
# 2026.04.15 - v. 17.5 - treat no-change Python M3U helper exits as normal results under set -e and avoid aborting on no-update playlist checks
# 2026.04.15 - v. 17.2 - simplify no-op M3U messages to checked/no update needed and avoid OLD/NEW noise for effectively matching playlist entries
# 2026.04.14 - v. 16.8 - suppress no-op M3U UPDATED lines in both direct and subtree playlist rewrites, and skip identical replacement entries cleanly
# 2026.04.14 - v. 16.6 - fix fake no-op M3U UPDATED logs, make M3U key normalization safe for broken playlist bytes, and normalize apostrophes in playlist matching
# 2026.04.14 - v. 16.9 - fix broken quote normalization in M3U candidate matching and keep binary-safe playlist key output
# 2026.04.14 - v. 17.0 - show the startup banner before usage when -h or --help is used
# 2026.04.13 - v. 16.0 - skip slash-only M3U rewrites, persist per-kind hashes in DB, and remove stale DB rows missing on disk
# 2026.04.13 - v. 15.7 - add --wait-seconds prompt timeout control and print current interactive wait behavior
# 2026.04.13 - v. 15.6 - show SQLite warmup percentages together with row counts during startup
# 2026.04.13 - v. 15.5 - restore a nice startup banner before startup progress lines and keep downloadable filename aligned with script version
# 2026.04.13 - v. 15.4 - show explicit startup progress for exclude loading and SQLite cache warmup, and keep downloadable filename aligned with script version
# 2026.04.13 - v. 15.3 - fix CRLF-sensitive M3U entry replacement so prepared updates actually get written
# 2026.04.13 - v. 15.2 - fix protected internal files, make M3U single-entry replacement more robust, and count DB row operations in summary
# 2026.04.11 - v. 15.1 - skip immediately when an exception already exists and fix the E prompt text
# 2026.04.11 - v. 15.0 - fix .m3u CRLF updates, handle backslash paths in subtree matching, and avoid UnicodeEncodeError when printing odd playlist entries
# 2026.04.11 - v. 14.9 - skip final .m3u checks/fixes when interrupted with Ctrl-C and exit immediately after summary
# 2026.04.11 - v. 14.8 - make .m3u skip messages explicit: distinguish no match, identical replacement, and write failure
# 2026.04.11 - v. 14.7 - do not prompt to rename .par2 files whose basename starts with an underscore
# 2026.04.11 - v. 14.6 - treat both e and E as 'add exception' in the plain-entry prompt
# 2026.04.11 - v. 14.5 - preserve _-_ separators in transformed names and replace fragile sed-based m3u key normalization with a python implementation
# 2026.04.11 - v. 14.4 - search .m3u missing entries in the playlist subtree by similar name and show OLD/NEW before updating playlist references
# 2026.04.11 - v. 14.3 - add per-file choices for @ and Ŕ, add €->c and si@->sie, and lowercase extensions only for actual files
# 2026.04.11 - v. 14.1 - fix per-file ŕ/® choice prompts so only the selected mapping goes to stdout and prompt text no longer pollutes filenames
# 2026.04.11 - v. 14.0 - remove leftover startup mapping prompts so ŕ and ® choices are only asked per file
# 2026.04.11 - v. 13.9 - move ŕ and ® mapping choices from startup to per-file prompts so they can be chosen case by case
# 2026.04.11 - v. 13.8 - show ŕ and ® mapping choices reliably during startup before any file processing begins
# 2026.04.11 - v. 13.7 - make ŕ and ® mappings selectable at startup and keep si`/Ä/% and media-only @ normalization rules
# 2026.04.11 - v. 13.6 - lowercase file extensions and add more filename normalization rules including media-only @ -> a
# 2026.04.11 - v. 13.5 - undo backtick replacement and change ŕ mapping to 's ' instead of 'c '
# 2026.04.11 - v. 13.4 - add more mojibake fixes, zero-pad numeric media basenames, update/check .m3u playlists, limit affected list to last 100, and remove more ebook markers
# 2026.04.11 - v. 13.3 - strip leading underscores from final media basenames and update/add DB rows for renamed files so DB summary reflects renames
# 2026.04.11 - v. 13.2 - move summary after affected entries, remove leading underscores from media basenames, and support wildcard exclude masks like *.cpp and *.h
# 2026.04.11 - v. 13.1 - reuse cached DB file hashes instead of recalculating them unless --force-recheck is used
# 2026.04.11 - v. 13.0 - add start/finish timestamps and processed/hashed counters to summary, and always print summary on Ctrl-C
# 2026.04.11 - v. 12.9 - clean up checksum-group prompt layout and use rich collision dialog for checksum-group file collisions too
# 2026.04.11 - v. 12.8 - make recovery outcome explicit and add DB hash/cache accounting in logs and summary
# 2026.04.11 - v. 12.7 - store computed file MD5/SHA512 values in SQLite and use them first for subtree recovery lookups
# 2026.04.11 - v. 12.6 - add support for filenames starting with YYYY-MM-DD_HH-MM-SS...
# 2026.04.11 - v. 12.5 - add date normalization rules for YYMMDD_HHMMSS_-_* and YYYYMMDD-HHMMSS_-_* filenames
# 2026.04.11 - v. 12.4 - fix collision prompt so it displays immediately instead of being swallowed by command substitution
# 2026.04.11 - v. 12.3 - enrich plain-file collision dialog with size/timestamps and add rename-with-_OTHER option
# 2026.04.11 - v. 12.2 - on plain-file collision, compare MD5 of source and destination and ask what to do instead of auto-skipping
# 2026.04.11 - v. 12.1 - normalize IMG_/PXL_/received_ media filenames using embedded timestamps or older of creation/modification time
# 2026.04.11 - v. 12.0 - restore -v/--verbose as verbose mode and keep --version for version/help output
# 2026.04.11 - v. 11.9 - include DB filename and exclude file path in --version / -v output
# 2026.04.11 - v. 11.8 - make --version and -v print version plus usage/help and exit immediately
# 2026.04.11 - v. 11.7 - add support for signal-YYYY-MM-DD-HHMMSS.ext filenames without an extra suffix
# 2026.04.11 - v. 11.6 - collapse double dashes in basenames to a single dash
# 2026.04.11 - v. 11.5 - add support for signal-YYYY-MM-DD-HHMMSS_... filenames
# 2026.04.11 - v. 11.4 - rename filenames starting with YYYY-MM-DD-HH-MM-SS-... to YYYYMMDD_HHMMSS-...
# 2026.04.11 - v. 11.3 - generalize signal filename renaming so any suffix after the timestamp becomes YYYYMMDD_HHMMSS-signal-<suffix>
# 2026.04.11 - v. 11.2 - support signal filenames with extra numeric suffixes like signal-YYYY-MM-DD-HH-MM-SS-823-2.jpg
# 2026.04.11 - v. 11.1 - timestamp video*.mp4 from the older of file creation time and modification time
# 2026.04.11 - v. 11.0 - timestamp image*.jpg from the older of file creation time and modification time
# 2026.04.11 - v. 10.9 - prefix image*.jpg files with YYYYMMDD_HHMMSS_
# 2026.04.11 - v. 10.8 - rename .jpeg extensions to .jpg and keep header history updated with the current date
# 2026.04.07 - v. 10.7 - only initialize or migrate SQLite when --use-db is explicitly enabled
# 2026.04.09 - v. 10.6 - fix checksum-update/recovery verbose formatting and add extra basename cleanup/removal rules
# 2026.04.07 - v. 10.5 - on plain-file rename collision, allow overwrite when source and destination MD5 checksums are identical
# 2026.04.07 - v. 10.4 - remove leading exclamation marks from basenames and strip [Audiobook PL] from names
# 2026.04.07 - v. 10.3 - wrap long verbose rename lines, including the per-directory auto-yes variant, into two lines
# 2026.04.07 - v. 10.2 - add per-directory auto-yes option (d) for rename prompts and replace one-line prompt text with explained multi-line menus
# 2026.04.07 - v. 10.1 - keep wrapped checksum-update verbose messages as two-liners after the missing-ref helper fix
# 2026.04.07 - v. 10.0 - fix unbound $3 in wrapped checksum-update verbose helper during missing-ref recovery
# 2026.04.07 - v. 9.9 - add checksum-based subtree fallback for missing hash references after directory and filename renames
# 2026.04.07 - v. 9.8 - fix remaining wrapped verbose helper functions that still bypassed the VERBOSE flag
# 2026.04.07 - v. 9.7 - fix remaining wrapped 'no rename/update is needed' messages so they only print in verbose mode
# 2026.04.07 - v. 9.6 - fix wrapped verbose helper functions so they respect VERBOSE=0 unless -v/--verbose is used
# 2026.04.07 - v. 9.5 - wrap long protected-checksum, no-action checksum, and missing-ref verbose lines into cleaner two-line output
# 2026.04.07 - v. 9.4 - fix syntax error in handle_lnk_file() function header; preserve full script history
# 2026.04.03 - v. 9.3 - add more filename cleanups and search missing checksum refs in the hash-file directory subtree
# 2026.04.03 - v. 9.2 - wrap long verbose resolved-ref lines into two lines using MAX_LINE_LENGTH
# 2026.04.03 - v. 9.1 - add Å¼->z, remove ._osloskop.net, collapse double dots, and wrap long checksum-update verbose lines
# 2026.04.03 - v. 9.0 - fix long single-target checksum verbose lines by formatting directory, ref, and hash file separately
# 2026.04.03 - v. 8.9 - fix wrapped single-target verbose line split and make plain HTML+companion directory rename a single visible prompt/action
# 2026.04.03 - v. 8.8 - define MAX_LINE_LENGTH early so wrapped output helpers never hit an unbound variable
# 2026.04.03 - v. 8.7 - define MAX_LINE_LENGTH early so wrapped messages cannot fail with unbound variable
# 2026.04.03 - v. 8.6 - add --colors, --mode, and --scope command-line options to skip startup questions
# 2026.04.03 - v. 8.5 - cache checksum files with missing refs in DB and wrap long SKIP lines using MAX_LINE_LENGTH
# 2026.04.03 - v. 8.4 - print info when .htm/.html files are renamed together with companion _files/_pliki directories
# 2026.04.03 - v. 8.3 - wrap long single-target checksum verbose lines and remove _www.osiolek.com from filenames
# 2026.04.03 - v. 8.2 - rename DB file to _rename.sh-optional-db.sqlite3, migrate legacy DB automatically, and keep DB skip ahead of checksum parsing
# 2026.04.03 - v. 8.1 - suppress SQLite WAL startup output ('wal') during DB initialization
# 2026.04.03 - v. 8.0 - when a directory is renamed, update cached DB paths for files under that subtree
# 2026.04.03 - v. 7.9 - add robust checksum-file DB recognition using checksum-file signature
# 2026.04.03 - v. 7.8 - add optional --fast mode for path-only DB skips and update help/banner text
# 2026.04.03 - v. 7.7 - optimize --use-db with in-memory cache and batched SQLite writes
# 2026.04.03 - v. 7.2 - optional SQLite checked-file cache with --use-db and --force-recheck
# 2026.04.03 - v. 7.1 - treat _pliki companion directories the same as _files for .htm/.html pairs
# 2026.04.03 - v. 7.0 - add E option to append basename-based exclude entries into start-directory exclude file and print confirmation
# 2026.04.03 - v. 6.9 - add E option in per-entry rename prompt to append basename-based exclude entries
# 2026.04.03 - v. 6.8 - split long exclude-filter SKIP messages into two lines
# 2026.04.03 - v. 6.7 - show verbose main-loop progress in a dynamically sized two-line box
# 2026.04.03 - v. 6.6 - include exact hash file path directly in checksum-group prompt text
# 2026.04.03 - v. 6.5 - hide unchanged OLD/NEW pairs in checksum-group displays and prompts
# 2026.04.03 - v. 6.4 - do not rename checksum files whose basename starts with __
# 2026.04.03 - v. 6.3 - ask per .lnk file whether to remove it instead of using one global question
# 2026.04.03 - v. 6.2 - add extra mojibake fixes, remove rip.by.Crisp, prompt for .lnk removal, and pair .htm/.html with _files companion dirs
# 2026.04.03 - v. 6.1 - verify only changed references inside checksum groups instead of requiring whole hash file to be clean
# 2026.04.03 - v. 6.0 - make prompt input draining bounded and read a single key safely from repeated keypress bursts
# 2026.04.02 - v. 5.9 - skip plain entry renames when a local checksum file refers to them; let checksum branch handle the group
# 2026.04.02 - v. 5.8 - process checksum files before sibling plain entries to avoid stale local hash refs
# 2026.04.02 - v. 5.7 - remove _OSiOLEK.com and LEK.PL fragments from names
# 2026.04.02 - v. 5.6 - update only local hash files after plain file/directory renames and verify only changed checksum files
# 2026.04.02 - v. 5.5 - support comments in _exclude-rename.sh.txt with lines starting with #
# 2026.04.02 - v. 5.4 - added mojibake replacement Ĺ� -> L
# 2026.04.02 - v. 5.3 - normalize _exclude-rename.sh.txt from CRLF to LF before loading and expand mojibake fixes
# 2026.04.02 - v. 5.2 - expanded mojibake replacements and kept whole-script delivery
# 2026.04.02 - v. 5.1 - support local exclude filters from _exclude-rename.sh.txt
# 2026.04.01 - v. 5.0 - added mojibake replacements for selected broken Polish characters
# 2026.04.01 - v. 4.9 - process deeper paths first to avoid stale child paths after parent directory renames
# 2026.04.01 - v. 4.8 - ask before checking large hash files in real mode
# 2026.04.01 - v. 4.7 - nicer startup banner and flush terminal input buffer before interactive reads
# 2026.04.01 - v. 4.6 - sort processed entries alphabetically and print version info at startup
# 2026.04.01 - v. 4.5 - clarify recovery logging and always normalize hash files to Unix format before checks in real mode
# 2026.04.01 - v. 4.4 - add rollback of current checksum-group operation on Ctrl-C
# 2026.03.31 - v. 4.3 - fixed missing VERBOSE_MAIN_EVERY variable in verbose mode
# 2026.03.31 - v. 4.2 - removed whole-tree path discovery; use local directory processing only
# 2026.03.31 - v. 4.1 - verbose logs go to stderr so command substitutions are not corrupted
# 2026.03.31 - v. 4.0 - removed slow whole-tree recovery fallback; only fast same-directory recovery is used
# 2026.03.31 - v. 3.9 - fast same-directory recovery for normalized missing checksum refs
# 2026.03.31 - v. 3.8 - added ERR trap to show line number, exit code, and failed command
# 2026.03.31 - v. 3.7 - fixed silent exits caused by set -e with post-increment arithmetic
# 2026.03.31 - v. 3.6 - only do checksum verification when renames or checksum-file modifications are actually needed
# 2026.03.31 - v. 3.4 - added -v / --verbose logging
# 2026.03.31 - v. 3.3 - verify checksum files from their own directory
# 2026.03.31 - v. 3.1 - print clear info after Windows to Unix checksum file conversion was actually done
# 2026.03.31 - v. 3.0 - always normalize checksum files from CRLF to LF before any checks in real mode
# 2026.03.31 - v. 2.8 - treat .sha512 and .md5 with exactly the same logic
# 2026.03.31 - v. 2.7 - stop the whole script immediately when checksum verification fails
# 2026.03.31 - v. 2.6 - add .md5 support with before/after verification and content updates
# 2026.03.27 - v. 2.0 - preserve original top-level path style (with or without ./) in transform_name()
# 2026.03.27 - v. 1.8 - added Call_recording rule
# 2026.03.27 - v. 1.7 - made Sprache/Voice/Screen_Recording patterns tolerant to -/_ after normalization
# 2026.03.27 - v. 1.6 - in real mode, default answer is YES for rename prompts
# 2026.03.27 - v. 1.5 - added question: current directory only vs also subdirectories
# 2026.03.27 - v. 1.4 - apply special media renames after basic normalization
# 2026.03.27 - v. 1.3 - fixed top-level path handling: keep ./ prefix in transform_name()
# 2026.03.27 - v. 1.2 - added many changes about media files
# 2026.04.15 - v. 17.3 - escape control characters in logged paths and warn explicitly about filenames containing them
# SCRIPT_VERSION: first # YYYY.MM.DD line; use v. aa.bbb.HHMMSS there and on each history row (aa = month counter; bbb +1 per edit; HHMMSS = six-digit local time of that edit).
SCRIPT_VERSION="$(LC_ALL=C grep -m1 '^# [0-9]' "$0" | sed -E -n 's/^# [0-9]{4}\.[0-9]{2}\.[0-9]{2} - v\. ([0-9]+\.[0-9]+\.[0-9]{6}) - .*/\1/p')"
[[ "$SCRIPT_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]{6}$ ]] || SCRIPT_VERSION="0.0.000000"
# If a checksum list has more than this many lines, ask before checking it; default answer is No ([y/N/q]).
LARGE_HASHFILE_LINE_PROMPT_THRESHOLD="${LARGE_HASHFILE_LINE_PROMPT_THRESHOLD:-20}"
# With a “large” line count, still skip that prompt when the sum of sizes of existing regular-file targets is below this many bytes (default 30 GiB). Set to 0 to always prompt when over the line threshold.
LARGE_HASHFILE_PROMPT_MIN_TOTAL_BYTES="${LARGE_HASHFILE_PROMPT_MIN_TOTAL_BYTES:-32212254720}"
# Per-path state files for last successful full checksum-list verification (epoch + content digest). Default: ~/.local/state/rename.sh/checksum-verify/
RENAME_CHECKSUM_VERIFY_STATE_DIR="${RENAME_CHECKSUM_VERIFY_STATE_DIR:-}"
# exiftool for GoPro/Sony/Contour/LG camera raw filenames (GH010001.MP4, GOPR0123.JPG, GP010032.JPG).
# Default when neither RENAME_EXIFTOOL nor EXIFLOC is set: bundled copy on luks-buffalo2; then exiftool on PATH.
RENAME_EXIFTOOL_DEFAULT='/mnt/luks-buffalo2/worek/_video-JEDYNE_KOPIE/_katalog_roboczy/scripts/Image-ExifTool-12.41/exiftool'
RENAME_EXIFTOOL="${RENAME_EXIFTOOL:-${EXIFLOC:-$RENAME_EXIFTOOL_DEFAULT}}"
MAX_LINE_LENGTH="${MAX_LINE_LENGTH:-200}"
# Long vlog() bodies fold to at most this many columns (excluding WRAP_MSG_INDENT), so paths don’t appear as one endless line.
VERBOSE_LOG_BODY_WRAP_WIDTH="${VERBOSE_LOG_BODY_WRAP_WIDTH:-96}"
# NEF+XMP paired-file box: soft-wrap content to this width (fold -s); full paths span multiple rows instead of truncating.
NEF_XMP_BOX_WRAP_WIDTH="${NEF_XMP_BOX_WRAP_WIDTH:-108}"
# Plain-text width of "OLD (sidecar):" / "NEW (sidecar):" in NEF+XMP pair prompts (wider "OLD:" / "NEW:" use this when a sidecar exists).
NEF_XMP_PAIR_LABEL_WIDTH="${NEF_XMP_PAIR_LABEL_WIDTH:-15}"
# When there is no XMP sidecar, only "OLD:" / "NEW:" are shown — use this width so paths are not over-indented.
NEF_XMP_PAIR_LABEL_WIDTH_NO_SIDECAR="${NEF_XMP_PAIR_LABEL_WIDTH_NO_SIDECAR:-5}"
# Continuation indent for user-visible lines longer than MAX_LINE_LENGTH (checksum/HTML style).
WRAP_MSG_INDENT="${WRAP_MSG_INDENT:-          }"

# After a full stdout status line, skip the next main-loop progress dot (avoids lone "." between lines).
nonverbose_skip_next_main_loop_dot_after_stdout_status() {
    (( VERBOSE == 1 )) && return 0
    NONVERBOSE_SKIP_NEXT_MAIN_LOOP_DOT=yes
}

# plain_prefix + body == full visible line (no ANSI). fd 1=stdout, 2=stderr.
# Optional 5th arg full_line_color (green|red|cyan|yellow): when use_colors=yes, the entire
# visible line (prefix + body) uses that color — used for OLD/NEW suggested path lines.
emit_wrap_labeled_line() {
    local fd="$1"
    local plain_prefix="$2"
    local ansi_label="$3"
    local body="$4"
    local full_line_color="${5-}"
    local plain="${plain_prefix}${body}"
    local line_color=""
    if (( fd == 1 )); then
        nonverbose_progress_dot_endline_if_needed
    fi
    if [[ "$use_colors" == yes && -n "$full_line_color" ]]; then
        case "$full_line_color" in
            green)  line_color=$GREEN ;;
            red)    line_color=$RED ;;
            cyan)   line_color=$CYAN ;;
            yellow) line_color=$YELLOW ;;
        esac
    fi
    if [[ -n "$line_color" ]]; then
        if (( ${#plain} <= MAX_LINE_LENGTH )); then
            printf '%b%s%b\n' "$line_color" "$plain" "$RESET" >&"$fd"
        else
            printf '%b%s%b\n' "$line_color" "$plain_prefix" "$RESET" >&"$fd"
            printf '%b%s%s%b\n' "$line_color" "$WRAP_MSG_INDENT" "$body" "$RESET" >&"$fd"
        fi
        if (( fd == 1 )) && [[ "$plain_prefix" == *"[DRY-RUN]"* ]]; then
            nonverbose_skip_next_main_loop_dot_after_stdout_status
        fi
        return 0
    fi
    if (( ${#plain} <= MAX_LINE_LENGTH )); then
        printf '%b%s\n' "$ansi_label" "$body" >&"$fd"
    else
        printf '%b\n' "$ansi_label" >&"$fd"
        printf '%s%s\n' "$WRAP_MSG_INDENT" "$body" >&"$fd"
    fi
    if (( fd == 1 )) && [[ "$plain_prefix" == *"[DRY-RUN]"* ]]; then
        nonverbose_skip_next_main_loop_dot_after_stdout_status
    fi
}

# Optional 4th arg: full_line_color (see emit_wrap_labeled_line).
emit_wrap_labeled_stdout() {
    emit_wrap_labeled_line 1 "$@"
}
emit_wrap_labeled_stderr() { emit_wrap_labeled_line 2 "$@"; }

# Pad plain_tag to width; when colors are on, color the whole line (tag + path) per color_name.
emit_wrap_padded_label_stdout() {
    local plain_tag="$1"
    local color_name="$2"
    local body="$3"
    local width="$4"
    local padded ansi_pref
    printf -v padded '%-*s' "$width" "$plain_tag"
    case "$color_name" in
        red)    ansi_pref="${RED}${padded}${RESET}" ;;
        green)  ansi_pref="${GREEN}${padded}${RESET}" ;;
        cyan)   ansi_pref="${CYAN}${padded}${RESET}" ;;
        yellow) ansi_pref="${YELLOW}${padded}${RESET}" ;;
        *)      ansi_pref="$padded" ;;
    esac
    if [[ "$use_colors" == yes && "$color_name" =~ ^(green|red|cyan|yellow)$ ]]; then
        emit_wrap_labeled_line 1 "$padded" "" "$body" "$color_name"
    else
        emit_wrap_labeled_stdout "$padded" "$ansi_pref" "$body"
    fi
}

# NEF+XMP interactive rename: pad label to width (arg 4, default NEF_XMP_PAIR_LABEL_WIDTH) so OLD/NEW/sidecar paths align when sidecars exist.
emit_wrap_nef_xmp_pair_label_stdout() {
    local width="${4-}"
    [[ -z "$width" ]] && width=$NEF_XMP_PAIR_LABEL_WIDTH
    emit_wrap_padded_label_stdout "$1" "$2" "$3" "$width"
}

# "TAG: entry -> exclude file" with colored arrow when it fits on one line.
emit_wrap_exclude_append_message() {
    nonverbose_progress_dot_endline_if_needed
    local use_cyan_for_tag="$1"
    local tag="$2"
    local entry="$3"
    local plain="${tag}: ${entry} -> ${EXCLUDE_FILTERS_FILE}"
    if (( ${#plain} <= MAX_LINE_LENGTH )); then
        if [[ "$use_cyan_for_tag" == 1 ]]; then
            printf '%b %s %b %s\n' "${CYAN}${tag}:${RESET}" "$entry" "${CYAN}->${RESET}" "$EXCLUDE_FILTERS_FILE"
        else
            printf '%b %s %b %s\n' "${YELLOW}${tag}:${RESET}" "$entry" "${CYAN}->${RESET}" "$EXCLUDE_FILTERS_FILE"
        fi
    else
        if [[ "$use_cyan_for_tag" == 1 ]]; then
            printf '%b %s\n' "${CYAN}${tag}:${RESET}" "$entry"
        else
            printf '%b %s\n' "${YELLOW}${tag}:${RESET}" "$entry"
        fi
        printf '%s%b %s\n' "$WRAP_MSG_INDENT" "${CYAN}->${RESET}" "$EXCLUDE_FILTERS_FILE"
    fi
}

# Long OLD path ARROW NEW path (ARROW is set later at startup; expanded at call time).
# When colors are on, the suggested new path is printed in green.
# Wrapped layout: line 1 = prefix+old+arrow; line 2 = spaces (prefix width) + new so old/new paths share the same column.
emit_wrap_old_arrow_new_stdout() {
    nonverbose_progress_dot_endline_if_needed
    local plain_pfx="$1"
    local ansi_pfx="$2"
    local old_p="$3"
    local new_p="$4"
    local sep=" ${ARROW} "
    local plain="${plain_pfx}${old_p}${sep}${new_p}"
    local path_col_indent=""
    printf -v path_col_indent '%*s' "${#plain_pfx}" ''
    if (( ${#plain} <= MAX_LINE_LENGTH )); then
        if [[ "$use_colors" == yes ]]; then
            printf '%b%s%s%b%s%b\n' "$ansi_pfx" "$old_p" "$sep" "${GREEN}" "$new_p" "${RESET}"
        else
            printf '%b%s%s%s\n' "$ansi_pfx" "$old_p" "$sep" "$new_p"
        fi
    else
        if [[ "$use_colors" == yes ]]; then
            printf '%b%s%s\n' "$ansi_pfx" "$old_p" "$sep"
            printf '%s%b%s%b\n' "$path_col_indent" "${GREEN}" "$new_p" "${RESET}"
        else
            printf '%b%s%s\n' "$ansi_pfx" "$old_p" "$sep"
            printf '%s%s\n' "$path_col_indent" "$new_p"
        fi
    fi
    if [[ "$plain_pfx" == *"[DRY-RUN]"* ]] || [[ "$plain_pfx" == "Renamed: " ]]; then
        nonverbose_skip_next_main_loop_dot_after_stdout_status
    fi
}

RENAME_SH_INVOCATION_CWD="$(pwd -P)"
START_DIR="${START_DIR:-$RENAME_SH_INVOCATION_CWD}"
EXCLUDE_FILTERS_FILE="$START_DIR/_exclude-rename.sh.txt"
USE_DB=0
FORCE_RECHECK=0
FAST_DB=0
DB_FILE="$START_DIR/_rename.sh-optional-db.sqlite3"
LEGACY_DB_FILE="$START_DIR/rename.sh-optional-db.sqlite3"
# Set by db_init when host FS returns SQLITE_BUSY unless opened with sqlite3 -uri '...?nolock=1' (unsafe if two writers).
DB_SQLITE_USE_URI=""
DB_SQLITE_URI=""
# Probed on first URI open: some distros ship sqlite3 CLI without -uri (need 3.7.13+ for file:...?nolock=1).
RENAME_SQLITE3_URI_PROBED=""
RENAME_SQLITE3_HAS_URI_FLAG=""
RENAME_SQLITE3_URI_FALLBACK_WARNED=""
DB_HASHES_ADDED=0
DB_ROWS_NEW=0
DB_ROWS_UPDATED=0
DB_ROWS_REMOVED=0
DB_HASH_LOOKUP_HITS=0
DB_HASH_LOOKUP_MISSES=0
DB_HASH_RECORD_STATUS=""
DB_RECOVERY_RESULT=""
DB_STALE_ROWS_REMOVED=0
DB_MARK_CHECKED_RESULT=""
DB_MAINT_ROWS_CHECKED=0
DB_MAINT_ROWS_MISSING=0
DB_MAINT_ROWS_REMOVED=0
DB_MAINT_HASH_ROWS_SCANNED=0
DB_MAINT_HASH_ROWS_UPDATED=0
DB_MAINT_HASH_MD5_FILLED=0
DB_MAINT_HASH_SHA512_FILLED=0
DB_MAINT_HASH_JOBS_TOTAL=0
DB_MAINT_HASH_JOBS_REMAINING=0
DB_MAINT_HASH_MD5_JOBS=0
DB_MAINT_HASH_SHA512_JOBS=0
DB_MAINT_HASH_SKIPPED_NOT_FILE=0
DB_MAINT_HASH_JOBS_DONE=0
DB_MAINT_HASH_BACKFILL_TTY_BAR=no
DB_MAINT_HASH_BACKFILL_START_EPOCH=0
DB_MAINT_HASH_BACKFILL_LAST_DISPLAY_PCT=-1
DB_MAINT_HASH_BACKFILL_LAST_DISPLAY_EPOCH=0
DB_MAINT_HASH_BACKFILL_NEXT_PCT=5
DB_MAINT_HASH_BACKFILL_BAR_WIDTH=80
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
DEBUG_LOG_PATH="${DEBUG_LOG_PATH:-$WORKSPACE_ROOT/debug-8439cd.log}"
DEBUG_SESSION_ID="8439cd"
DEBUG_RUN_ID="${DEBUG_RUN_ID:-pre-fix}"

set -Eeuo pipefail
shopt -s nullglob

# Snapshot argv for terminal title (CLI loop below shifts through flags).
RENAME_SH_ORIGINAL_ARGV=( "$0" "$@" )
RENAME_SH_WINDOW_TITLE_PUSHED=0

VERBOSE=0
VERBOSE_MAIN_EVERY="${VERBOSE_MAIN_EVERY:-200}"
# Non-verbose main loop: after this many examined paths (files_examined), print a separate "k out of total" line (default 1000). Resume restores files_examined so progress continues from the checkpoint.
NONVERBOSE_MAIN_LOOP_PROGRESS_EVERY_N="${NONVERBOSE_MAIN_LOOP_PROGRESS_EVERY_N:-1000}"
# Non-verbose: '.' per main-loop entry; checksum ramp redraws in one terminal cell (backspace+char) until S/M/H commits and advances the column counter. Uses /dev/tty when writable. Same wrap at MAX_LINE_LENGTH; end line before prompts/other stdout.
NONVERBOSE_PROGRESS_DOT_LINE_OPEN=no
NONVERBOSE_PROGRESS_DOT_COL_COUNT=0
NONVERBOSE_CHECKSUM_LETTER_EVENT_N=0
# Ramp advances every this many checksum events; kind letter (S/M/H) every (stride * NONVERBOSE_CHECKSUM_LETTER_CYCLE_EVENTS) events. STRIDE must be >= 1.
NONVERBOSE_CHECKSUM_EVENT_STRIDE_N="${NONVERBOSE_CHECKSUM_EVENT_STRIDE_N:-1}"
# One S/M/H commit every (stride * this many) checksum events (ramp redraws for the other cycle-1 stride-aligned events). Must be >= 2.
NONVERBOSE_CHECKSUM_LETTER_CYCLE_EVENTS="${NONVERBOSE_CHECKSUM_LETTER_CYCLE_EVENTS:-100}"
# ASCII ramp (cycle-1 redraws between letters; positions map across this string). Default when unset; override with export or prefix assignment (quote metacharacters).
if [[ -z "${NONVERBOSE_CHECKSUM_RAMP_CHARS+x}" ]]; then
    NONVERBOSE_CHECKSUM_RAMP_CHARS='.,`^":;|!~-_=+*/\<>()[]{}#%&@?'
fi
# When yes, the next ramp update backspaces once before drawing (in-place on /dev/tty).
NONVERBOSE_CHECKSUM_RAMP_CELL_ACTIVE=no
# List-aware scaling for nonverbose_checksum_ref_verify_progress_letter (second arg = checksum file path).
NONVERBOSE_CHECKSUM_PROGRESS_SOURCE=""
NONVERBOSE_CHECKSUM_PROGRESS_NREFS=0
NONVERBOSE_CHECKSUM_PROGRESS_FPL=0
# Non-verbose checksum list (second arg to progress letter): below threshold → NO progress letters (a lone S/M/H is just noise for small/single-reference files); at or above → one letter every min(MAX_PER_CHAR, max(1,n/10)) events. Override: export VAR=value before running.
NONVERBOSE_CHECKSUM_LIST_PER_LETTER_THRESHOLD="${NONVERBOSE_CHECKSUM_LIST_PER_LETTER_THRESHOLD:-3000}"
NONVERBOSE_CHECKSUM_LIST_MAX_ENTRIES_PER_PROGRESS_CHAR="${NONVERBOSE_CHECKSUM_LIST_MAX_ENTRIES_PER_PROGRESS_CHAR:-50}"
# After auto-dir “Renamed:” (stdout), the next iteration’s lone progress dot looked odd; skip that one dot (see nonverbose_main_loop_progress_dot).
# Checksum files and checksum-group OK lines get the same treatment (status lines replace dots).
NONVERBOSE_SKIP_NEXT_MAIN_LOOP_DOT=no
CLI_COLORS=""
CLI_MODE=""
CLI_SCOPE=""
CLI_RESUME_STATE="resume"
CLI_DATE_PLACEMENT=""
CLI_DB_MAINTENANCE="full"
DATE_PLACEMENT="${DATE_PLACEMENT:-front}"
RUN_DB_MAINTENANCE=0
PROMPT_WAIT_SECONDS=0
MAP_R_ACUTE="${MAP_R_ACUTE:-c}"
MAP_REGISTERED="${MAP_REGISTERED:-z}"
MAP_AT_SIGN="${MAP_AT_SIGN:-a}"
MAP_R_GRAVE="${MAP_R_GRAVE:-c}"

CURRENT_OP_ACTIVE=0
CURRENT_OP_LABEL=""
CURRENT_OP_SUM_OLD=""
CURRENT_OP_SUM_NEW=""
CURRENT_OP_SUM_RENAMED=0
CURRENT_OP_CONTENT_FILE=""
CURRENT_OP_CONTENT_BACKUP=""
COLLISION_OTHER_PATH=""
COLLISION_RENAMED_TARGET=""
SCRIPT_START_TIME="$(date '+%Y-%m-%d %H:%M:%S')"
SCRIPT_FINISH_TIME=""
SUMMARY_PRINTED=0
stopped_by_user=no
FILES_HASHED=0
RESUME_STATE_FILE="$START_DIR/_rename.sh.resume-state.json"
RESUME_STATE_WAS_LOADED=0
RESUME_CHECKPOINT_PROCESSED_LINES_LOADED=0
EARLY_RESUME_DECISION=""
declare -a CURRENT_OP_FILE_OLDS=()
declare -a CURRENT_OP_FILE_NEWS=()

declare -a EXCLUDE_FILTERS=()
EXCLUDE_FILTERS_SIGNATURE=""

on_err() {
    local exit_code="$1"
    local line_no="$2"
    local cmd="$3"
    echo
    echo "ERROR: command failed at line $line_no with exit code $exit_code" >&2
    echo "FAILED COMMAND: $cmd" >&2
}
trap 'on_err "$?" "$LINENO" "$BASH_COMMAND"' ERR

debug_log() {
    local hypothesis_id="$1"
    local location="$2"
    local message="$3"
    local data="$4"
    local timestamp
    local log_id
    timestamp="$(date +%s%3N 2>/dev/null || printf '%s000' "$(date +%s)")"
    log_id="log_${timestamp}_$$"
    printf '{"sessionId":"%s","id":"%s","timestamp":%s,"location":"%s","message":"%s","data":%s,"runId":"%s","hypothesisId":"%s"}\n' \
        "$DEBUG_SESSION_ID" "$log_id" "$timestamp" "$location" "$message" "$data" "$DEBUG_RUN_ID" "$hypothesis_id" >> "$DEBUG_LOG_PATH"
}

usage() {
    cat <<'EOF'
Usage: rename.sh [-v|--verbose] [--use-db] [--fast] [--force-recheck] [--run-db-maintenance] [--db-maintenance auto|[full]] [--colors [yes]|no] [--mode real|[dry-run]] [--scope subdirs|[current]] [--date-placement front|[original]] [--resume-state [resume]|ask|fresh] [--wait-seconds [0]|N] [--version] [-h|--help]

Options:
  -v, --verbose          Show extra diagnostic output
  --version              Print a short version banner and exit
  --use-db               Use SQLite cache in the start directory (_rename.sh-optional-db.sqlite3). If that file or the legacy rename.sh-optional-db.sqlite3 already exists and you omit --use-db, you are prompted whether to use it (default: yes; [q] quits).
  --fast                 With --use-db, trust cached paths without checking current size/mtime
  --force-recheck        Ignore SQLite cache and recheck everything
  --run-db-maintenance   Run DB maintenance and exit (implies --use-db; uses --db-maintenance profile or default full)
  --db-maintenance auto|[full]
                         Run that maintenance profile and exit (implies --use-db; same exit path as --run-db-maintenance)
                         auto: lightweight optimize/checkpoint; full: optimize + analyze + reindex + WAL truncate
  --colors [yes]|no      Skip the startup colors question
  --mode real|[dry-run]  Skip the startup mode question
  --scope subdirs|[current]
                         Skip the startup scope question
  --date-placement front|[original]
                         BBC/iPlayer-style names with -date_YYYY-MM-DD_HH_MM_SS:
                         front = YYYYMMDD_HHMMSS_ at the start (default);
                         original = compact YYYYMMDD_HHMMSS stays in the title (not moved to the front)
  --resume-state [resume]|ask|fresh
                         [resume]: automatically resume from checkpoint if it exists (default)
                         ask: if checkpoint exists, ask to resume or restart
                         fresh: always start from beginning
  --wait-seconds [0]|N   Wait N seconds for each interactive answer; 0 means wait forever
  -h, --help             Show this help (offers to list environment tunables)

Optional exclude file in the start directory: _exclude-rename.sh.txt
  FILE=basename or FILE=wildcard — skip renaming that filename in every subdirectory (files and directories; not path-specific).
  SUBTREE=dir — skip that directory and every path under it (prompt [B] on a file uses the directory where that file lives).
  FLATTEN_EXACT=dir — skip flatten prompts for matching directories (prompt [E] uses exact path; [C] may use globs or /fragment/).
  [F] at the rename prompt appends FILE=<basename> for the current path (file or directory). At the checksum-group prompt, [F] uses the list file's basename. [C] lets you type any custom filter line (FILE=, SUBTREE=, =path, globs). See also /basename/.
  When a renamed path appears in this file (=path, SUBTREE=, FLATTEN_EXACT=, or a bare path line), the entry is rewritten to the new path automatically.
  thumbs.db / torrent .URL: if the suggested path equals the current path, you still get a prompt so you can delete the file ([K] / [O] all thumbs.db this run / [T]); there is no rename to apply.

Example:
  rename.sh -v --use-db --colors yes --mode real --scope subdirs
  rename.sh -v --use-db --fast --colors yes --mode real --scope subdirs
  rename.sh --use-db --db-maintenance full
  rename.sh --run-db-maintenance --db-maintenance auto
  rename.sh --resume-state ask --use-db --mode real --scope subdirs
  rename.sh --date-placement original --use-db --mode real --scope subdirs ./_ogladam
EOF
}

usage_environment_tunables() {
    cat <<'EOF'

Environment / tunables (read at startup; use export or prefix on the same line as rename.sh):
  DEBUG_LOG_PATH                      JSON debug log file (default under workspace root).
      export DEBUG_LOG_PATH=/tmp/rename-debug.log
  DEBUG_RUN_ID                        runId string inside each JSON log line.
      DEBUG_RUN_ID=batch1 rename.sh -v --use-db
  DATE_PLACEMENT                      BBC/iPlayer -date_ handling: front (default) or original (same as --date-placement).
      DATE_PLACEMENT=original rename.sh --use-db --scope subdirs ./_ogladam
  EXIFLOC                             Override exiftool path (same as RENAME_EXIFTOOL; zmien-nazwe script name)
      EXIFLOC=/opt/exiftool/exiftool rename.sh --scope current
  LARGE_HASHFILE_LINE_PROMPT_THRESHOLD  Checksum lists with more lines than this prompt before full check ([y/N/q]); default 20.
      LARGE_HASHFILE_LINE_PROMPT_THRESHOLD=50 rename.sh --use-db
  LARGE_HASHFILE_PROMPT_MIN_TOTAL_BYTES  With a large line count, skip the prompt if the sum of on-disk regular-file target sizes is below this many bytes (default 32212254720 ≈ 30 GiB). Use 0 to always prompt.
      LARGE_HASHFILE_PROMPT_MIN_TOTAL_BYTES=0 rename.sh --use-db
  MAP_AT_SIGN                         Replacement for @ in basename mapping prompts (default a).
      MAP_AT_SIGN=x rename.sh
  MAP_R_ACUTE                         Replacement for acute accent (default c).
      MAP_R_ACUTE=x rename.sh
  MAP_R_GRAVE                         Replacement for grave accent (default c).
      MAP_R_GRAVE=h rename.sh
  MAP_REGISTERED                      Replacement for ® (default z).
      MAP_REGISTERED=r rename.sh
  MAX_LINE_LENGTH                     Wrap width for many user-visible lines and non-verbose dot rows (default 200).
      MAX_LINE_LENGTH=120 rename.sh -v
  NEF_XMP_BOX_WRAP_WIDTH              fold -s width for NEF+XMP text box (default 108).
      NEF_XMP_BOX_WRAP_WIDTH=96 rename.sh
  NEF_XMP_PAIR_LABEL_WIDTH            Plain width for OLD/NEW (sidecar) labels when sidecar exists (default 15).
      NEF_XMP_PAIR_LABEL_WIDTH=12 rename.sh
  NEF_XMP_PAIR_LABEL_WIDTH_NO_SIDECAR  Label width when there is no sidecar (default 5).
      NEF_XMP_PAIR_LABEL_WIDTH_NO_SIDECAR=8 rename.sh
  NONVERBOSE_CHECKSUM_EVENT_STRIDE_N  Non-verbose checksum ramp: events per ramp step (default 1).
      NONVERBOSE_CHECKSUM_EVENT_STRIDE_N=2 rename.sh --use-db
  NONVERBOSE_CHECKSUM_LETTER_CYCLE_EVENTS  Events between S/M/H commits is stride × this (default 100; min 2 enforced in logic).
      NONVERBOSE_CHECKSUM_LETTER_CYCLE_EVENTS=50 rename.sh --use-db
  NONVERBOSE_CHECKSUM_LIST_MAX_ENTRIES_PER_PROGRESS_CHAR  Large checksum lists: max entries represented by one progress letter (default 50).
      NONVERBOSE_CHECKSUM_LIST_MAX_ENTRIES_PER_PROGRESS_CHAR=40 rename.sh --use-db
  NONVERBOSE_CHECKSUM_LIST_PER_LETTER_THRESHOLD  Below this many list lines, NO progress letters (small/single-reference lists stay quiet); at or above, batched S/M/H letters (default 3000).
      NONVERBOSE_CHECKSUM_LIST_PER_LETTER_THRESHOLD=5000 rename.sh --use-db
  NONVERBOSE_CHECKSUM_RAMP_CHARS        Non-verbose checksum ramp glyphs between S/M/H (maps to in-cell redraw order). Default is a long punctuation set; use single quotes when exporting.
      export NONVERBOSE_CHECKSUM_RAMP_CHARS='.:-=+*'
  NONVERBOSE_MAIN_LOOP_PROGRESS_EVERY_N  Non-verbose: print "k of total" every this many examined paths this session (after resume baseline; default 1000).
      NONVERBOSE_MAIN_LOOP_PROGRESS_EVERY_N=500 rename.sh --use-db
  RENAME_CHECKSUM_VERIFY_STATE_DIR      Directory for last-successful full-verify timestamps for checksum lists (large-list prompt). Default: $HOME/.local/state/rename.sh/checksum-verify
      RENAME_CHECKSUM_VERIFY_STATE_DIR=/var/tmp/rename-checksum-state rename.sh --use-db
  RENAME_EXIFTOOL                     exiftool for GoPro camera raw files; default: bundled luks-buffalo2 path, then PATH
      RENAME_EXIFTOOL=/opt/exiftool/exiftool rename.sh --scope current
  START_DIR                           Working tree root (default current directory). Use an absolute path.
      START_DIR=/data/photos rename.sh --use-db --scope subdirs
  TMPDIR                              Temp directory for SQLite bootstrap mktemp etc. (POSIX; default often /tmp).
      TMPDIR=/var/tmp rename.sh --use-db
  VERBOSE_LOG_BODY_WRAP_WIDTH         Max fold width for long [VERBOSE] bodies (default 96).
      VERBOSE_LOG_BODY_WRAP_WIDTH=80 rename.sh -v
  VERBOSE_MAIN_EVERY                  Verbose progress box cadence in main loop (default 200).
      VERBOSE_MAIN_EVERY=100 rename.sh -v --use-db
  WRAP_MSG_INDENT                     Spaces prefixing wrapped continuation lines (default 10 spaces).
      WRAP_MSG_INDENT='    ' rename.sh -v
EOF
}

print_prompt_wait_description() {
    if (( PROMPT_WAIT_SECONDS == 0 )); then
        printf '%s' 'infinite (wait until user enters a response)'
    else
        printf '%s' "${PROMPT_WAIT_SECONDS} second(s)"
    fi
}

print_startup_banner() {
    local detail="${1-}"
    local width=60
    local line1="rename.sh"
    local line2="safe media + checksum rename helper"
    local line3="Version     : $SCRIPT_VERSION"
    local line4="Start dir   : $START_DIR"
    local line5="DB file     : $DB_FILE"
    local line6="Exclude file: $EXCLUDE_FILTERS_FILE"
    local line7="Prompt wait : $(print_prompt_wait_description)"
    local charmap

    charmap="$(locale charmap 2>/dev/null || printf 'unknown')"
    #region agent log
    debug_log "H1" "rename.sh:print_startup_banner" "About to print banner characters" "{\"charmap\":\"${charmap}\",\"lang\":\"${LANG:-unset}\",\"lc_all\":\"${LC_ALL:-unset}\",\"term\":\"${TERM:-unset}\"}"
    #endregion

    printf '┌%*s┐
' "$width" '' | tr ' ' '─'
    printf '│ %-*.*s │
' $((width - 2)) $((width - 2)) "$line1"
    printf '│ %-*.*s │
' $((width - 2)) $((width - 2)) "$line2"
    printf '├%*s┤
' "$width" '' | tr ' ' '─'
    printf '│ %-*.*s │
' $((width - 2)) $((width - 2)) "$line3"
    printf '│ %-*.*s │
' $((width - 2)) $((width - 2)) "$line4"
    if [[ "$detail" == version ]]; then
        printf '│ %-*.*s │
' $((width - 2)) $((width - 2)) "$line5"
        printf '│ %-*.*s │
' $((width - 2)) $((width - 2)) "$line6"
    fi
    printf '│ %-*.*s │
' $((width - 2)) $((width - 2)) "$line7"
    printf '└%*s┘
' "$width" '' | tr ' ' '─'
}

print_version_banner() {
    local width=60
    local line1="rename.sh"
    local line2="Version: $SCRIPT_VERSION"

    printf '┌%*s┐\n' "$width" '' | tr ' ' '─'
    printf '│ %-*.*s │\n' $((width - 2)) $((width - 2)) "$line1"
    printf '│ %-*.*s │\n' $((width - 2)) $((width - 2)) "$line2"
    printf '└%*s┘\n' "$width" '' | tr ' ' '─'
}

startup_progress() {
    local ts
    ts="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[STARTUP ${ts}] $*"
}

flush_stdin() {
    local discard
    local drained=0
    local max_drain=256

    while (( drained < max_drain )) && IFS= read -r -t 0.02 -n 1 discard; do
        ((++drained))
    done
}

# Non-verbose progress stream: prefer controlling TTY so dots/M-S-H show immediately (stdout may be fully buffered when not a TTY).
nonverbose_progress_tty_put() {
    if [[ -w /dev/tty ]] 2>/dev/null; then
        printf '%s' "$1" >/dev/tty
    else
        printf '%s' "$1"
    fi
}

nonverbose_progress_tty_nl() {
    if [[ -w /dev/tty ]] 2>/dev/null; then
        printf '\n' >/dev/tty
    else
        printf '\n'
    fi
}

# xterm-style title stack: CSI 22 t push, CSI 23 t pop (OSC 0/2 set icon/window title). No-op if no TTY.
rename_sh_window_title_restore() {
    (( RENAME_SH_WINDOW_TITLE_PUSHED == 1 )) || return 0
    if [[ -w /dev/tty ]] 2>/dev/null; then
        printf '\033[23t' >/dev/tty 2>/dev/null || true
    fi
    RENAME_SH_WINDOW_TITLE_PUSHED=0
}

rename_sh_window_title_apply_from_saved_argv() {
    local title="" a i script0 max_len=400 cwd_bracket=""
    (( ${#RENAME_SH_ORIGINAL_ARGV[@]} > 0 )) || return 0
    script0="${RENAME_SH_ORIGINAL_ARGV[0]}"
    if [[ -e "$script0" ]]; then
        if command -v realpath >/dev/null 2>&1; then
            title="$(realpath "$script0" 2>/dev/null)" || title="$script0"
        else
            title="$(cd "$(dirname -- "$script0")" 2>/dev/null && pwd -P)/$(basename -- "$script0")" 2>/dev/null || title="$script0"
        fi
    else
        title="$script0"
    fi
    for (( i = 1; i < ${#RENAME_SH_ORIGINAL_ARGV[@]}; i++ )); do
        a="${RENAME_SH_ORIGINAL_ARGV[$i]}"
        a="${a//$'\r'/}"
        a="${a//$'\n'/ }"
        a="${a//$'\t'/ }"
        title+=" $a"
    done
    cwd_bracket="[ ${RENAME_SH_INVOCATION_CWD} ] "
    title="${cwd_bracket}${title}"
    if (( ${#title} > max_len )); then
        title="${title:0:$(( max_len - 3 ))}..."
    fi
    [[ -w /dev/tty ]] 2>/dev/null || return 0
    # GNU screen / tmux set the window name with ESC k <name> ESC backslash.
    if [[ -n "${STY:-}" || -n "${TMUX:-}" ]]; then
        printf '\033k%s\033\\' "$title" >/dev/tty 2>/dev/null || true
    fi
    # xterm/VTE: push current title (CSI 22 t), then set icon (OSC 0) and window (OSC 2) title.
    printf '\033[22t' >/dev/tty 2>/dev/null || true
    printf '\033]0;%s\033\\' "$title" >/dev/tty 2>/dev/null || printf '\033]0;%s\a' "$title" >/dev/tty 2>/dev/null || true
    printf '\033]2;%s\033\\' "$title" >/dev/tty 2>/dev/null || printf '\033]2;%s\a' "$title" >/dev/tty 2>/dev/null || true
    RENAME_SH_WINDOW_TITLE_PUSHED=1
}

# One non-verbose progress character (dot or checksum letter); wraps like dots (MAX_LINE_LENGTH).
nonverbose_progress_stdout_line_char() {
    local ch="$1"
    (( VERBOSE == 1 )) && return 0
    if [[ "$NONVERBOSE_PROGRESS_DOT_LINE_OPEN" == yes ]] && (( NONVERBOSE_PROGRESS_DOT_COL_COUNT >= MAX_LINE_LENGTH )); then
        nonverbose_progress_tty_nl
        NONVERBOSE_PROGRESS_DOT_COL_COUNT=0
    fi
    nonverbose_progress_tty_put "$ch"
    NONVERBOSE_PROGRESS_DOT_LINE_OPEN=yes
    ((++NONVERBOSE_PROGRESS_DOT_COL_COUNT))
}

nonverbose_main_loop_progress_dot() {
    (( VERBOSE == 1 )) && return 0
    if [[ "$NONVERBOSE_SKIP_NEXT_MAIN_LOOP_DOT" == yes ]]; then
        NONVERBOSE_SKIP_NEXT_MAIN_LOOP_DOT=no
        return 0
    fi
    NONVERBOSE_CHECKSUM_RAMP_CELL_ACTIVE=no
    nonverbose_progress_stdout_line_char '.'
}

# End the current dot row, then print "n out of total" (non-verbose only). n = paths examined this session (caller subtracts MAIN_LOOP_FILES_EXAMINED_MILESTONE_BASE from files_examined).
nonverbose_main_loop_progress_milestone() {
    local n="${1-0}"
    local total="${2-0}"
    local every="${NONVERBOSE_MAIN_LOOP_PROGRESS_EVERY_N:-1000}"
    (( VERBOSE == 1 )) && return 0
    (( every < 1 )) && every=1000
    (( total < 1 )) && return 0
    (( n < every )) && return 0
    (( n % every != 0 )) && return 0
    nonverbose_progress_dot_endline_if_needed
    if [[ -w /dev/tty ]] 2>/dev/null; then
        printf '%d out of %d\n' "$n" "$total" >/dev/tty
    else
        printf '%d out of %d\n' "$n" "$total"
    fi
}

# In-place ramp glyph on the controlling TTY (one display column; column counter unchanged).
nonverbose_checksum_ramp_cell_put() {
    local ch="$1"
    (( VERBOSE == 1 )) && return 0
    [[ -w /dev/tty ]] 2>/dev/null || return 0
    if [[ "$NONVERBOSE_CHECKSUM_RAMP_CELL_ACTIVE" != yes ]]; then
        if [[ "$NONVERBOSE_PROGRESS_DOT_LINE_OPEN" == yes ]] && (( NONVERBOSE_PROGRESS_DOT_COL_COUNT >= MAX_LINE_LENGTH )); then
            nonverbose_progress_tty_nl
            NONVERBOSE_PROGRESS_DOT_COL_COUNT=0
        fi
    fi
    if [[ "$NONVERBOSE_CHECKSUM_RAMP_CELL_ACTIVE" == yes ]]; then
        printf '\b' >/dev/tty
    fi
    printf '%s' "$ch" >/dev/tty
    NONVERBOSE_CHECKSUM_RAMP_CELL_ACTIVE=yes
    NONVERBOSE_PROGRESS_DOT_LINE_OPEN=yes
}

# Final S/M/H for this ramp cell: optional backspace over last ramp char, then letter; then advance column counter (with wrap).
nonverbose_checksum_commit_kind_letter() {
    local letter="$1"
    (( VERBOSE == 1 )) && return 0
    if [[ -w /dev/tty ]] 2>/dev/null; then
        if [[ "$NONVERBOSE_CHECKSUM_RAMP_CELL_ACTIVE" == yes ]]; then
            printf '\b' >/dev/tty
        fi
        if [[ "$NONVERBOSE_PROGRESS_DOT_LINE_OPEN" == yes ]] && (( NONVERBOSE_PROGRESS_DOT_COL_COUNT >= MAX_LINE_LENGTH )); then
            nonverbose_progress_tty_nl
            NONVERBOSE_PROGRESS_DOT_COL_COUNT=0
        fi
        printf '%s' "$letter" >/dev/tty
        NONVERBOSE_CHECKSUM_RAMP_CELL_ACTIVE=no
        NONVERBOSE_PROGRESS_DOT_LINE_OPEN=yes
        ((++NONVERBOSE_PROGRESS_DOT_COL_COUNT))
        return 0
    fi
    NONVERBOSE_CHECKSUM_RAMP_CELL_ACTIVE=no
    nonverbose_progress_stdout_line_char "$letter"
}

# M = MD5 list, S = SHA512 list, H = anything else (unknown extension / future kinds).
# With optional second arg (checksum file path): scale by line count — below NONVERBOSE_CHECKSUM_LIST_PER_LETTER_THRESHOLD → NO letters at all (small/single-reference lists stay quiet);
# at or above → one letter every min(NONVERBOSE_CHECKSUM_LIST_MAX_ENTRIES_PER_PROGRESS_CHAR, max(1, n/10)) events (ramp between). Without second arg, uses stride*cycle legacy behavior.
nonverbose_checksum_ref_verify_progress_letter() {
    local kind="${1-}"
    local sum_path="${2-}"
    local letter stride block e slot idx ramp_str len cycle denom fpl pos nline thr maxc
    (( VERBOSE == 1 )) && return 0

    if [[ -n "$sum_path" ]]; then
        if [[ "$sum_path" != "${NONVERBOSE_CHECKSUM_PROGRESS_SOURCE-}" ]]; then
            NONVERBOSE_CHECKSUM_PROGRESS_SOURCE="$sum_path"
            NONVERBOSE_CHECKSUM_LETTER_EVENT_N=0
            nline="$(extract_checksum_entries "$sum_path" | wc -l | tr -d ' \t')"
            [[ "$nline" =~ ^[0-9]+$ ]] || nline=0
            NONVERBOSE_CHECKSUM_PROGRESS_NREFS=$nline
            thr="${NONVERBOSE_CHECKSUM_LIST_PER_LETTER_THRESHOLD:-3000}"
            maxc="${NONVERBOSE_CHECKSUM_LIST_MAX_ENTRIES_PER_PROGRESS_CHAR:-50}"
            [[ "$thr" =~ ^[0-9]+$ ]] || thr=3000
            [[ "$maxc" =~ ^[0-9]+$ ]] || maxc=50
            (( thr < 1 )) && thr=1
            (( maxc < 1 )) && maxc=1
            if (( nline >= thr )); then
                fpl=$(( nline / 10 ))
                (( fpl < 1 )) && fpl=1
                (( fpl > maxc )) && fpl=$maxc
                NONVERBOSE_CHECKSUM_PROGRESS_FPL=$fpl
            else
                # Small lists (incl. single-reference .sha512/.md5 files): no progress
                # letters at all — a lone "S"/"M"/"H" between status lines is just noise.
                # Letters/ramp are only useful for very large lists (>= threshold).
                NONVERBOSE_CHECKSUM_PROGRESS_FPL=0
            fi
        fi
        fpl=${NONVERBOSE_CHECKSUM_PROGRESS_FPL:-0}
        if (( fpl > 0 )); then
            ((++NONVERBOSE_CHECKSUM_LETTER_EVENT_N))
            e=$NONVERBOSE_CHECKSUM_LETTER_EVENT_N
            pos=$(( (e - 1) % fpl + 1 ))
            if (( pos == fpl )); then
                case "$kind" in
                    md5) letter=M ;;
                    sha512) letter=S ;;
                    *) letter=H ;;
                esac
                nonverbose_checksum_commit_kind_letter "$letter"
                return 0
            fi
            (( fpl <= 2 )) && return 0
            ramp_str="${NONVERBOSE_CHECKSUM_RAMP_CHARS-}"
            [[ -n "$ramp_str" ]] || ramp_str='?'
            len=${#ramp_str}
            denom=$(( fpl - 2 ))
            (( denom < 1 )) && denom=1
            if (( len <= 1 )); then
                letter=${ramp_str:0:1}
            else
                idx=$(( (pos - 1) * (len - 1) / denom ))
                letter=${ramp_str:idx:1}
            fi
            nonverbose_checksum_ramp_cell_put "$letter"
            return 0
        fi
        # Size is known (sum_path was given): never fall through to the legacy stride/cycle
        # path below, which would print a glyph even for a small/single-reference list.
        return 0
    fi

    stride=${NONVERBOSE_CHECKSUM_EVENT_STRIDE_N:-1}
    (( stride < 1 )) && stride=1
    cycle=${NONVERBOSE_CHECKSUM_LETTER_CYCLE_EVENTS:-100}
    [[ "$cycle" =~ ^[0-9]+$ ]] || cycle=100
    (( cycle < 2 )) && cycle=2
    ((++NONVERBOSE_CHECKSUM_LETTER_EVENT_N))
    e=$NONVERBOSE_CHECKSUM_LETTER_EVENT_N
    block=$(( stride * cycle ))
    if (( e % block == 0 )); then
        case "$kind" in
            md5) letter=M ;;
            sha512) letter=S ;;
            *) letter=H ;;
        esac
        nonverbose_checksum_commit_kind_letter "$letter"
        return 0
    fi
    (( e % stride == 0 )) || return 0
    slot=$(( e / stride % cycle ))
    (( slot == 0 )) && return 0
    ramp_str="${NONVERBOSE_CHECKSUM_RAMP_CHARS-}"
    [[ -n "$ramp_str" ]] || ramp_str='?'
    len=${#ramp_str}
    if (( len <= 1 )); then
        letter=${ramp_str:0:1}
    else
        denom=$(( cycle - 2 ))
        (( denom < 1 )) && denom=1
        idx=$(( (slot - 1) * (len - 1) / denom ))
        letter=${ramp_str:idx:1}
    fi
    nonverbose_checksum_ramp_cell_put "$letter"
}


nonverbose_progress_dot_endline_if_needed() {
    [[ "$NONVERBOSE_PROGRESS_DOT_LINE_OPEN" == yes ]] || return 0
    nonverbose_progress_tty_nl
    NONVERBOSE_PROGRESS_DOT_LINE_OPEN=no
    NONVERBOSE_PROGRESS_DOT_COL_COUNT=0
    NONVERBOSE_CHECKSUM_RAMP_CELL_ACTIVE=no
}

# Erase a single lone '.' on the progress TTY row instead of leaving "." on its own line before a prompt.
nonverbose_progress_dot_retract_lone_if_needed() {
    (( VERBOSE == 1 )) && return 0
    [[ "$NONVERBOSE_PROGRESS_DOT_LINE_OPEN" == yes ]] || return 0
    (( NONVERBOSE_PROGRESS_DOT_COL_COUNT == 1 )) || return 0
    if [[ -w /dev/tty ]] 2>/dev/null; then
        printf '\b \b' >/dev/tty
    else
        printf '\b \b'
    fi
    NONVERBOSE_PROGRESS_DOT_LINE_OPEN=no
    NONVERBOSE_PROGRESS_DOT_COL_COUNT=0
    NONVERBOSE_CHECKSUM_RAMP_CELL_ACTIVE=no
}

nonverbose_progress_dot_prepare_for_prompt() {
    (( VERBOSE == 1 )) && return 0
    if [[ "$NONVERBOSE_PROGRESS_DOT_LINE_OPEN" == yes ]] && (( NONVERBOSE_PROGRESS_DOT_COL_COUNT == 1 )); then
        nonverbose_progress_dot_retract_lone_if_needed
    else
        nonverbose_progress_dot_endline_if_needed
    fi
}

read_single_key() {
    nonverbose_progress_dot_prepare_for_prompt
    local __var_name="$1"
    local __timeout="$2"
    local __char=""

    if [[ "$__timeout" =~ ^[0-9]+$ ]] && (( __timeout == 0 )); then
        IFS= read -r -n 1 __char || true
    else
        IFS= read -r -t "$__timeout" -n 1 __char || true
    fi
    printf -v "$__var_name" '%s' "$__char"

    # Discard any extra buffered keypresses from the same burst so they do not
    # affect the next prompt or keep the pre-read drain loop busy.
    flush_stdin
}

# After usage() on -h/--help: optional full environment-variable list (default no; 5 second timeout).
prompt_show_usage_environment_tunables() {
    local answer=""

    echo
    echo -n "$(user_prompt_ts_prefix)Show all environment variables? [y/N]: "
    flush_stdin
    read_single_key answer 5
    echo
    case "$answer" in
        y|Y)
            usage_environment_tunables
            ;;
    esac
}

read_line_editable() {
    nonverbose_progress_dot_endline_if_needed
    local __var_name="$1"
    local __timeout="$2"
    local __initial="${3-}"
    local __line=""

    if [[ "$__timeout" =~ ^[0-9]+$ ]] && (( __timeout == 0 )); then
        IFS= read -r -e -i "$__initial" __line || true
    else
        IFS= read -r -e -t "$__timeout" -i "$__initial" __line || true
    fi
    printf -v "$__var_name" '%s' "$__line"
}

# Local-time prefix for interactive prompts, e.g. "(2026.05.08 14:30:00) " — trailing space included.
user_prompt_ts_prefix() {
    printf '(%s) ' "$(date '+%Y.%m.%d %H:%M:%S')"
}

# Print one user-visible question line with (YYYY.MM.DD HH:MM:SS). Optional second arg "2" / "stderr" for helpers that must not write to stdout.
verbose_question_timestamp() {
    local question="$1"
    local dest="${2-}"
    local ts
    ts="$(date '+%Y.%m.%d %H:%M:%S')"
    if (( VERBOSE == 1 )); then
        echo "[VERBOSE] [${ts}] ${question}" >&2
    else
        nonverbose_progress_dot_endline_if_needed
    fi
    case "$dest" in
        2|stderr|err)
            echo "(${ts}) ${question}" >&2
            ;;
        *)
            echo "(${ts}) ${question}"
            ;;
    esac
}

verbose_status_timestamp() {
    (( VERBOSE == 1 )) || return 0
    local msg="$1"
    local ts
    ts="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[VERBOSE] [${ts}] ${msg}" >&2
}

confirm_db_hash_update_for_existing_entry() {
    local path="$1"
    local hash_kind="$2"
    local old_hash="$3"
    local new_hash="$4"
    local answer=""

    echo
    verbose_question_timestamp "Stored ${hash_kind} hash differs for this entry. Replace it?"
    echo "DB hash differs for existing entry:"
    echo "  path:     $path"
    echo "  kind:     $hash_kind"
    echo "  stored:   $old_hash"
    echo "  computed: $new_hash"
    while true; do
        echo "$(user_prompt_ts_prefix)Replace stored hash with computed value?"
        echo "  [Y] Yes (default)"
        echo "  [N] No (keep existing DB hash)"
        print_prompt_view_directory_menu_line
        echo "  [Q] Quit"
        echo -n "$(user_prompt_ts_prefix)Choice [Y/n/v/q]: "
        flush_stdin
        read_single_key answer "$PROMPT_WAIT_SECONDS"
        echo
        if handle_prompt_directory_listing_choice "$answer" "$path"; then
            continue
        fi
        case "$answer" in
            q|Q) return 2 ;;
            n|N) return 1 ;;
            *) return 0 ;;
        esac
    done
}

prompt_resume_choice_early() {
    local answer=""

    [[ "$CLI_RESUME_STATE" == "ask" ]] || return 0
    [[ -f "$RESUME_STATE_FILE" ]] || return 0

    echo
    echo "Checkpoint found from an interrupted run: $RESUME_STATE_FILE"
    verbose_question_timestamp "Resume from checkpoint?"
    echo "  [Y] Resume (default)"
    echo "  [N] Start from the beginning"
    echo "  [Q] Quit"
    echo -n "$(user_prompt_ts_prefix)Choice [Y/n/q]: "
    flush_stdin
    read_single_key answer "$PROMPT_WAIT_SECONDS"
    echo

    if [[ "$answer" =~ [Qq] ]]; then
        echo "Quitting."
        exit 0
    elif [[ "$answer" =~ [Nn] ]]; then
        EARLY_RESUME_DECISION="fresh"
    else
        EARLY_RESUME_DECISION="resume"
    fi
}

prompt_use_existing_sqlite_cache_if_present() {
    local answer="" shown_db=""

    (( USE_DB == 0 )) || return 0
    (( RUN_DB_MAINTENANCE == 0 )) || return 0
    [[ -f "$DB_FILE" || -f "$LEGACY_DB_FILE" ]] || return 0

    if [[ -f "$DB_FILE" ]]; then
        shown_db="$DB_FILE"
    else
        shown_db="$LEGACY_DB_FILE (legacy filename; will migrate to _rename.sh-optional-db.sqlite3 when enabled)"
    fi

    echo
    echo "SQLite cache file found in the start directory:"
    echo "  $shown_db"
    verbose_question_timestamp "Use this SQLite cache for this run (same as --use-db)?"
    echo "  [Y] Yes — enable SQLite cache (default)"
    echo "  [N] No — run without the cache"
    echo "  [Q] Quit"
    echo -n "$(user_prompt_ts_prefix)Choice [Y/n/q]: "
    flush_stdin
    read_single_key answer "$PROMPT_WAIT_SECONDS"
    echo

    if [[ "$answer" =~ [Qq] ]]; then
        echo "Quitting."
        exit 0
    fi
    if [[ "$answer" =~ [Nn] ]]; then
        startup_progress "SQLite cache file present but not used for this run (user chose no)."
        return 0
    fi

    USE_DB=1
    startup_progress "SQLite cache enabled: existing DB in start directory (user chose yes / default)."
    return 0
}

preserve_timestamps_inplace() {
    local file="$1"; shift
    local ref
    ref="$(mktemp)"
    touch -r "$file" "$ref"
    "$@"
    touch -r "$ref" "$file"
    rm -f "$ref"
}

get_file_oldest_timestamp_yyyymmdd_hhmmss() {
    local file="$1"
    local mtime epoch btime

    mtime="$(stat -c %Y -- "$file" 2>/dev/null || echo 0)"
    btime="$(stat -c %W -- "$file" 2>/dev/null || echo 0)"

    epoch="$mtime"
    if [[ "$btime" =~ ^[0-9]+$ ]] && (( btime > 0 )) && (( btime < epoch )); then
        epoch="$btime"
    fi

    date -d "@$epoch" +%Y%m%d_%H%M%S
}

get_file_oldest_timestamp_compact() {
    local file="$1"
    local ts
    ts="$(get_file_oldest_timestamp_yyyymmdd_hhmmss "$file")"
    printf '%s' "${ts:0:8}_${ts:9:6}"
}

get_file_atime_epoch() {
    local file="$1"
    stat -c %X -- "$file" 2>/dev/null || echo 0
}

get_file_ctime_epoch() {
    local file="$1"
    stat -c %Z -- "$file" 2>/dev/null || echo 0
}

# Olympus digital voice recorder: DM######.MP3 / .WMA / .WAV (case-insensitive).
olympus_voice_recorder_raw_basename_matches() {
    [[ "$1" =~ ^[Dd][Mm][0-9]{6}\.([mM][pP]3|[wW][mM][aA]|[wW][aA][vV])$ ]]
}

olympus_voice_recorder_already_renamed_basename_matches() {
    [[ "$1" =~ ^[0-9]{8}_[0-9]{6}_-_-_Olympus_voice_recorder-[Dd][Mm][0-9]{6}\.([mM][pP]3|[wW][mM][aA]|[wW][aA][vV])$ ]]
}

# Track minimum positive epoch among filesystem times and exiftool file/media dates.
olympus_voice_recorder_oldest_epoch_from_file() {
    local file="$1"
    local min_epoch=0 cand exifloc tag val
    local -a exif_tags=(
        FileModifyDate FileAccessDate FileInodeChangeDate
        CreateDate MediaCreateDate DateTimeOriginal
    )

    _olympus_consider_epoch() {
        cand="$1"
        [[ "$cand" =~ ^[0-9]+$ ]] || return 0
        (( cand > 0 )) || return 0
        if (( min_epoch == 0 || cand < min_epoch )); then
            min_epoch="$cand"
        fi
    }

    _olympus_consider_epoch "$(get_file_birth_epoch "$file")"
    _olympus_consider_epoch "$(get_file_mtime_epoch "$file")"
    _olympus_consider_epoch "$(get_file_atime_epoch "$file")"
    _olympus_consider_epoch "$(get_file_ctime_epoch "$file")"

    if exifloc="$(resolve_rename_exiftool 2>/dev/null)"; then
        for tag in "${exif_tags[@]}"; do
            val="$("$exifloc" -api largefilesupport=1 -s3 -d '%s' "-${tag}" "$file" 2>/dev/null)" || val=""
            val="${val//$'\r'/}"
            val="${val#"${val%%[![:space:]]*}"}"
            val="${val%"${val##*[![:space:]]}"}"
            _olympus_consider_epoch "$val"
        done
    fi

    (( min_epoch > 0 )) || return 1
    printf '%s' "$min_epoch"
}

olympus_voice_recorder_oldest_timestamp_yyyymmdd_hhmmss() {
    local file="$1"
    local epoch
    epoch="$(olympus_voice_recorder_oldest_epoch_from_file "$file")" || return 1
    date -d "@$epoch" +%Y%m%d_%H%M%S
}

# e.g. DM420018.MP3 → 20100311_190904_-_-_Olympus_voice_recorder-DM420018.MP3 (same for .WMA / .WAV)
transform_olympus_voice_recorder_basename() {
    local file="$1"
    local base="$2"
    local ts stem ext

    olympus_voice_recorder_raw_basename_matches "$base" || return 1
    olympus_voice_recorder_already_renamed_basename_matches "$base" && return 1
    ts="$(olympus_voice_recorder_oldest_timestamp_yyyymmdd_hhmmss "$file")" || return 1
    stem="${base%.*}"
    ext="${base##*.}"
    printf '%s_-_-_Olympus_voice_recorder-%s.%s' "$ts" "$stem" "$ext"
}

text_file_has_crlf() {
    local f="$1"
    LC_ALL=C grep -q $'\r' -- "$f"
}

normalize_text_file_to_unix() {
    local f="$1"

    if command -v dos2unix >/dev/null 2>&1; then
        preserve_timestamps_inplace "$f" dos2unix -q -- "$f"
    else
        preserve_timestamps_inplace "$f" sed -i 's/\r$//' -- "$f"
    fi
}

normalize_exclude_filters_file_if_needed() {
    [[ -f "$EXCLUDE_FILTERS_FILE" ]] || return 0

    if text_file_has_crlf "$EXCLUDE_FILTERS_FILE"; then
        echo "Exclude filter file normalize: converting CRLF to LF: $EXCLUDE_FILTERS_FILE"
        normalize_text_file_to_unix "$EXCLUDE_FILTERS_FILE"
        echo "Exclude filter file normalize done: converted from Windows format to Unix format: $EXCLUDE_FILTERS_FILE"
    fi
}

exclude_filters_file_signature() {
    if [[ -f "$EXCLUDE_FILTERS_FILE" ]]; then
        stat -c '%Y:%s' -- "$EXCLUDE_FILTERS_FILE" 2>/dev/null || printf 'unreadable'
    else
        printf 'missing'
    fi
}

load_exclude_filters() {
    local line
    EXCLUDE_FILTERS=()

    if [[ ! -f "$EXCLUDE_FILTERS_FILE" ]]; then
        EXCLUDE_FILTERS_SIGNATURE="$(exclude_filters_file_signature)"
        return 0
    fi

    normalize_exclude_filters_file_if_needed

    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%$'\r'}"
        [[ -n "$line" ]] || continue
        [[ "$line" =~ ^# ]] && continue
        EXCLUDE_FILTERS+=( "$line" )
    done < "$EXCLUDE_FILTERS_FILE"
    EXCLUDE_FILTERS_SIGNATURE="$(exclude_filters_file_signature)"
}

reload_exclude_filters_if_changed() {
    local current_signature
    current_signature="$(exclude_filters_file_signature)"
    if [[ "$current_signature" != "$EXCLUDE_FILTERS_SIGNATURE" ]]; then
        load_exclude_filters
        (( VERBOSE == 1 )) && echo "[VERBOSE] Exclude filters reloaded from disk: ${#EXCLUDE_FILTERS[@]} active line(s)" >&2
    fi
}

is_excluded_by_filter_file() {
    local p="$1"
    local filter
    local base
    local exact_target
    local fn_pat

    reload_exclude_filters_if_changed
    base="$(basename -- "$p")"

    for filter in "${EXCLUDE_FILTERS[@]}"; do
        if [[ "$filter" == FILE=* ]]; then
            fn_pat="${filter#FILE=}"
            if [[ "$fn_pat" == *'*'* || "$fn_pat" == *'?'* || "$fn_pat" == *'['* ]]; then
                [[ "$base" == $fn_pat ]] && return 0
            else
                [[ "$base" == "$fn_pat" ]] && return 0
            fi
            continue
        fi

        if [[ "$filter" == SUBTREE=* ]]; then
            if path_is_under_subtree_root "$p" "${filter#SUBTREE=}"; then
                return 0
            fi
            continue
        fi

        if [[ "$filter" == =* ]]; then
            exact_target="${filter#=}" 
            if [[ "$p" == "$exact_target" ]]; then
                return 0
            fi
            continue
        fi

        if [[ "$filter" == *'*'* || "$filter" == *'?'* || "$filter" == *'['* ]]; then
            if [[ "$base" == $filter || "$p" == $filter ]]; then
                return 0
            fi
        else
            if [[ "$p" == *"$filter"* ]]; then
                return 0
            fi
        fi
    done
    return 1
}

exception_entry_for_path() {
    local p="$1"
    local base

    base="$(basename -- "$p")"
    if [[ -d "$p" ]]; then
        printf '/%s/' "$base"
    else
        printf '/%s' "$base"
    fi
}

exact_exception_entry_for_path() {
    local p="$1"
    printf '=%s' "$p"
}

# Basename-only: exclude line FILE=basename matches basename in any directory (file or directory; optional glob after FILE=).
filename_only_exception_entry_for_path() {
    local p="$1"
    [[ -f "$p" || -d "$p" ]] || return 1
    printf 'FILE=%s' "$(basename -- "$p")"
}

flatten_exception_entry_for_path() {
    local p="$1"
    printf 'FLATTEN_EXACT=%s' "$p"
}

# Directory containing a file (or the directory itself) for SUBTREE= exceptions.
containing_directory_for_subtree_exception() {
    local p="$1"
    if [[ -d "$p" ]]; then
        printf '%s' "$p"
    else
        dirname -- "$p"
    fi
}

subtree_exception_entry_for_directory() {
    local d="$1"
    local abs

    [[ -n "$d" ]] || return 1
    abs="$(db_abs_path "$d" 2>/dev/null || true)"
    [[ -n "$abs" ]] && d="$abs"
    printf 'SUBTREE=%s' "$d"
}

# True when p is exactly root or a path under root/ (after db_abs_path when possible).
path_is_under_subtree_root() {
    local p="$1"
    local root="$2"
    local abs_p abs_root

    [[ -n "$p" && -n "$root" ]] || return 1
    abs_p="$(db_abs_path "$p" 2>/dev/null || true)"
    abs_root="$(db_abs_path "$root" 2>/dev/null || true)"
    [[ -n "$abs_p" ]] || abs_p="$p"
    [[ -n "$abs_root" ]] || abs_root="$root"
    abs_p="${abs_p%/}"
    abs_root="${abs_root%/}"
    [[ "$abs_p" == "$abs_root" || "$abs_p" == "$abs_root"/* ]]
}

subtree_exception_exists_for_directory() {
    local dir="$1"
    local entry existing

    reload_exclude_filters_if_changed
    entry="$(subtree_exception_entry_for_directory "$dir")" || return 1
    [[ -n "$entry" ]] || return 1

    for existing in "${EXCLUDE_FILTERS[@]}"; do
        [[ "$existing" == "$entry" ]] && return 0
    done
    return 1
}

append_subtree_directory_to_exclude_filters_file() {
    local dir="$1"
    local entry existing found=0

    [[ -n "$dir" ]] || return 1
    [[ -e "$dir" ]] || {
        emit_wrap_labeled_stderr "SKIP: " "${YELLOW}SKIP:${RESET} " "Subtree exceptions need an existing directory: '$dir'"
        return 1
    }

    entry="$(subtree_exception_entry_for_directory "$dir")" || return 1

    if [[ ! -e "$EXCLUDE_FILTERS_FILE" ]]; then
        : > "$EXCLUDE_FILTERS_FILE"
    fi

    load_exclude_filters

    for existing in "${EXCLUDE_FILTERS[@]}"; do
        [[ "$existing" == "$entry" ]] && { found=1; break; }
    done

    if (( found == 0 )); then
        printf '%s
' "$entry" >> "$EXCLUDE_FILTERS_FILE"
        emit_wrap_exclude_append_message 1 "SUBTREE EXCEPTION ADDED" "$entry"
    else
        emit_wrap_exclude_append_message 0 "SUBTREE EXCEPTION EXISTS" "$entry"
    fi

    load_exclude_filters
}

apply_containing_directory_subtree_exception() {
    local p="$1"
    local dir

    dir="$(containing_directory_for_subtree_exception "$p")"
    append_subtree_directory_to_exclude_filters_file "$dir"
}

path_matches_flatten_exclude_filter() {
    local p="$1"
    local filter="" target="" base=""

    [[ -n "$p" ]] || return 1
    base="$(basename -- "$p")"

    for filter in "${EXCLUDE_FILTERS[@]}"; do
        [[ "$filter" == FLATTEN_EXACT=* ]] || continue
        target="${filter#FLATTEN_EXACT=}"
        [[ -n "$target" ]] || continue
        if [[ "$p" == "$target" ]]; then
            return 0
        fi
        if [[ "$target" == *'*'* || "$target" == *'?'* || "$target" == *'['* ]]; then
            [[ "$p" == $target || "$base" == $target ]] && return 0
        elif [[ "$p" == *"$target"* ]]; then
            return 0
        fi
    done
    return 1
}

flatten_exception_exists_for_path() {
    local path="$1"
    local entry=""
    local existing

    reload_exclude_filters_if_changed
    entry="$(flatten_exception_entry_for_path "$path")"
    [[ -n "$entry" ]] || return 1

    for existing in "${EXCLUDE_FILTERS[@]}"; do
        [[ "$existing" == "$entry" ]] && return 0
    done
    path_matches_flatten_exclude_filter "$path"
}

exception_exists_for_path() {
    local path="$1"
    local entry=""
    local exact_entry=""
    local fn_entry=""
    local existing

    reload_exclude_filters_if_changed
    entry="$(path_to_exclude_entry "$path")"
    exact_entry="$(exact_exception_entry_for_path "$path")"
    fn_entry=""
    if [[ -f "$path" || -d "$path" ]]; then
        fn_entry="$(filename_only_exception_entry_for_path "$path")"
    fi
    [[ -n "$entry" || -n "$exact_entry" || -n "$fn_entry" ]] || return 1

    for existing in "${EXCLUDE_FILTERS[@]}"; do
        [[ -n "$entry" && "$existing" == "$entry" ]] && return 0
        [[ -n "$exact_entry" && "$existing" == "$exact_entry" ]] && return 0
        [[ -n "$fn_entry" && "$existing" == "$fn_entry" ]] && return 0
    done
    return 1
}

append_custom_exclude_pattern_to_exclude_filters_file() {
    local pattern="$1"
    local existing found=0

    [[ -n "$pattern" ]] || return 1
    [[ "$pattern" != \#* ]] || return 1

    if [[ ! -e "$EXCLUDE_FILTERS_FILE" ]]; then
        : > "$EXCLUDE_FILTERS_FILE"
    fi

    load_exclude_filters

    for existing in "${EXCLUDE_FILTERS[@]}"; do
        [[ "$existing" == "$pattern" ]] && { found=1; break; }
    done

    if (( found == 0 )); then
        printf '%s
' "$pattern" >> "$EXCLUDE_FILTERS_FILE"
        emit_wrap_exclude_append_message 1 "EXCEPTION ADDED" "$pattern"
    else
        emit_wrap_exclude_append_message 0 "EXCEPTION EXISTS" "$pattern"
    fi

    load_exclude_filters
}

prompt_custom_exclude_pattern_from_user() {
    local context="${1:-}"
    local pattern=""

    echo
    echo "$(user_prompt_ts_prefix)Custom exclude pattern (written to exclude file; active immediately):"
    echo "  Same syntax as _exclude-rename.sh.txt — FILE=name, SUBTREE=dir, =/exact/path, globs, /fragment/"
    if [[ "$context" == flatten ]]; then
        echo "  FLATTEN_EXACT=dir — skip flatten prompts (exact path, glob, or path fragment)"
    fi
    echo "  Leave empty and press Enter to cancel."
    echo -n "$(user_prompt_ts_prefix)Pattern: "
    read_line_editable pattern "$PROMPT_WAIT_SECONDS" ""
    echo
    pattern="${pattern%$'\r'}"
    pattern="${pattern#"${pattern%%[![:space:]]*}"}"
    pattern="${pattern%"${pattern##*[![:space:]]}"}"
    [[ -n "$pattern" ]] || return 1
    if [[ "$pattern" == \#* ]]; then
        emit_wrap_labeled_stdout "SKIP: " "${YELLOW}SKIP:${RESET} " "Pattern must not start with # (comments are ignored when loading)."
        return 1
    fi
    append_custom_exclude_pattern_to_exclude_filters_file "$pattern"
}

append_path_to_exclude_filters_file() {
    local p="$1"
    local entry existing found=0

    entry="$(exception_entry_for_path "$p")"

    if [[ ! -e "$EXCLUDE_FILTERS_FILE" ]]; then
        : > "$EXCLUDE_FILTERS_FILE"
    fi

    load_exclude_filters

    for existing in "${EXCLUDE_FILTERS[@]}"; do
        [[ "$existing" == "$entry" ]] && { found=1; break; }
    done

    if (( found == 0 )); then
        printf '%s
' "$entry" >> "$EXCLUDE_FILTERS_FILE"
        emit_wrap_exclude_append_message 1 "EXCEPTION ADDED" "$entry"
    else
        emit_wrap_exclude_append_message 0 "EXCEPTION EXISTS" "$entry"
    fi

    load_exclude_filters
}

append_exact_path_to_exclude_filters_file() {
    local p="$1"
    local entry existing found=0

    entry="$(exact_exception_entry_for_path "$p")"

    if [[ ! -e "$EXCLUDE_FILTERS_FILE" ]]; then
        : > "$EXCLUDE_FILTERS_FILE"
    fi

    load_exclude_filters

    for existing in "${EXCLUDE_FILTERS[@]}"; do
        [[ "$existing" == "$entry" ]] && { found=1; break; }
    done

    if (( found == 0 )); then
        printf '%s
' "$entry" >> "$EXCLUDE_FILTERS_FILE"
        emit_wrap_exclude_append_message 1 "EXACT EXCEPTION ADDED" "$entry"
    else
        emit_wrap_exclude_append_message 0 "EXACT EXCEPTION EXISTS" "$entry"
    fi

    load_exclude_filters
}

append_filename_only_exception_to_exclude_filters_file() {
    local p="$1"
    local entry existing found=0

    entry="$(filename_only_exception_entry_for_path "$p")" || {
        if [[ -e "$EXCLUDE_FILTERS_FILE" ]]; then
            load_exclude_filters
        fi
        emit_wrap_labeled_stderr "SKIP: " "${YELLOW}SKIP:${RESET} " "Filename-only exceptions need an existing file or directory path."
        return 1
    }

    if [[ ! -e "$EXCLUDE_FILTERS_FILE" ]]; then
        : > "$EXCLUDE_FILTERS_FILE"
    fi

    load_exclude_filters

    for existing in "${EXCLUDE_FILTERS[@]}"; do
        [[ "$existing" == "$entry" ]] && { found=1; break; }
    done

    if (( found == 0 )); then
        printf '%s
' "$entry" >> "$EXCLUDE_FILTERS_FILE"
        emit_wrap_exclude_append_message 1 "FILENAME-ONLY EXCEPTION ADDED" "$entry"
    else
        emit_wrap_exclude_append_message 0 "FILENAME-ONLY EXCEPTION EXISTS" "$entry"
    fi

    load_exclude_filters
}

append_flatten_exception_to_exclude_filters_file() {
    local p="$1"
    local entry existing found=0

    entry="$(flatten_exception_entry_for_path "$p")"

    if [[ ! -e "$EXCLUDE_FILTERS_FILE" ]]; then
        : > "$EXCLUDE_FILTERS_FILE"
    fi

    load_exclude_filters

    for existing in "${EXCLUDE_FILTERS[@]}"; do
        [[ "$existing" == "$entry" ]] && { found=1; break; }
    done

    if (( found == 0 )); then
        printf '%s
' "$entry" >> "$EXCLUDE_FILTERS_FILE"
        emit_wrap_exclude_append_message 1 "FLATTEN EXCEPTION ADDED" "$entry"
    else
        emit_wrap_exclude_append_message 0 "FLATTEN EXCEPTION EXISTS" "$entry"
    fi

    load_exclude_filters
}

# Canonical relative path for exclude-file rewrites (./foo; absolute unchanged).
exclude_filter_canonical_path() {
    local p="$1"
    while [[ "$p" == */ ]]; do
        p="${p%/}"
    done
    [[ -n "$p" ]] || return 1
    if [[ "$p" == /* ]]; then
        printf '%s' "$p"
        return 0
    fi
    if [[ "$p" == ./* ]]; then
        printf '%s' "$p"
        return 0
    fi
    printf './%s' "$p"
}

exclude_filter_paths_equivalent() {
    local a="$1" b="$2"
    a="$(exclude_filter_canonical_path "$a")"
    b="$(exclude_filter_canonical_path "$b")"
    [[ -n "$a" && -n "$b" && "$a" == "$b" ]] && return 0
    local abs_a abs_b
    abs_a="$(db_abs_path_if_deleted "$a" 2>/dev/null || db_abs_path "$a" 2>/dev/null || true)"
    abs_b="$(db_abs_path_if_deleted "$b" 2>/dev/null || db_abs_path "$b" 2>/dev/null || true)"
    [[ -n "$abs_a" && -n "$abs_b" && "$abs_a" == "$abs_b" ]]
}

exclude_filter_format_path_like() {
    local template="$1"
    local new_path="$2"
    new_path="$(exclude_filter_canonical_path "$new_path")"
    if [[ "$template" == ./* ]]; then
        if [[ "$new_path" == ./* ]]; then
            printf '%s' "$new_path"
        else
            printf './%s' "${new_path#./}"
        fi
    elif [[ "$template" == /* ]]; then
        local abs
        abs="$(db_abs_path "$new_path" 2>/dev/null || true)"
        if [[ -n "$abs" ]]; then
            printf '%s' "$abs"
        else
            printf '%s' "$new_path"
        fi
    else
        printf '%s' "${new_path#./}"
    fi
}

# Rewrite a path embedded in an exclude line after old -> new (exact or under old when old is a directory).
exclude_filter_rewrite_embedded_path() {
    local path_val="$1"
    local old="$2"
    local new="$3"
    local exact_only="${4:-no}"
    local suffix rel canon_path canon_old canon_new

    if exclude_filter_paths_equivalent "$path_val" "$old"; then
        exclude_filter_format_path_like "$path_val" "$new"
        return 0
    fi
    [[ "$exact_only" == yes ]] && return 1

    if exclude_filter_path_is_under_dir "$path_val" "$old"; then
        canon_path="$(exclude_filter_canonical_path "$path_val")"
        canon_old="$(exclude_filter_canonical_path "$old")"
        canon_new="$(exclude_filter_canonical_path "$new")"
        suffix="${canon_path#"${canon_old}/"}"
        [[ "$suffix" == "$canon_path" ]] && suffix=""
        if [[ -n "$suffix" ]]; then
            rel="${canon_new}/${suffix}"
        else
            rel="$canon_new"
        fi
        exclude_filter_format_path_like "$path_val" "$rel"
        return 0
    fi
    return 1
}

exclude_filter_path_is_under_dir() {
    local path_val="$1"
    local dir="$2"
    local canon_path canon_dir abs_p abs_d

    path_is_under_subtree_root "$path_val" "$dir" && return 0
    canon_path="$(exclude_filter_canonical_path "$path_val")"
    canon_dir="$(exclude_filter_canonical_path "$dir")"
    [[ -n "$canon_path" && -n "$canon_dir" && "$canon_path" == "$canon_dir"/* ]] && return 0
    abs_p="$(db_abs_path "$path_val" 2>/dev/null || true)"
    abs_d="$(db_abs_path_if_deleted "$dir" 2>/dev/null || db_abs_path "$dir" 2>/dev/null || true)"
    [[ -n "$abs_p" && -n "$abs_d" && ( "$abs_p" == "$abs_d" || "$abs_p" == "$abs_d"/* ) ]]
}

exclude_filter_line_rewrite_for_rename() {
    local line="$1"
    local old="$2"
    local new="$3"
    local path_val rewritten prefix

    [[ -n "$line" ]] || return 0
    [[ "$line" =~ ^# ]] && { printf '%s' "$line"; return 0; }

    if [[ "$line" == FILE=* ]]; then
        printf '%s' "$line"
        return 0
    fi

    if [[ "$line" == SUBTREE=* ]]; then
        path_val="${line#SUBTREE=}"
        if rewritten="$(exclude_filter_rewrite_embedded_path "$path_val" "$old" "$new" no)"; then
            printf 'SUBTREE=%s' "$rewritten"
        else
            printf '%s' "$line"
        fi
        return 0
    fi

    if [[ "$line" == FLATTEN_EXACT=* ]]; then
        path_val="${line#FLATTEN_EXACT=}"
        if rewritten="$(exclude_filter_rewrite_embedded_path "$path_val" "$old" "$new" no)"; then
            printf 'FLATTEN_EXACT=%s' "$rewritten"
        else
            printf '%s' "$line"
        fi
        return 0
    fi

    if [[ "$line" == =* ]]; then
        path_val="${line#=}"
        if rewritten="$(exclude_filter_rewrite_embedded_path "$path_val" "$old" "$new" yes)"; then
            printf '=%s' "$rewritten"
        else
            printf '%s' "$line"
        fi
        return 0
    fi

    if rewritten="$(exclude_filter_rewrite_embedded_path "$line" "$old" "$new" no)"; then
        printf '%s' "$rewritten"
        return 0
    fi

    old="$(exclude_filter_canonical_path "$old")"
    new="$(exclude_filter_canonical_path "$new")"
    if [[ -n "$old" && -n "$new" && "$old" != "$new" && "$line" == *"$old"* ]]; then
        printf '%s' "${line//"$old"/"$new"}"
        return 0
    fi

    printf '%s' "$line"
}

update_exclude_filters_file_after_rename() {
    local old="$1"
    local new="$2"
    local line new_line out_line
    local -a out_lines=()
    local changed=0
    local header_printed=0
    local tmp

    [[ -f "$EXCLUDE_FILTERS_FILE" ]] || return 0
    [[ -n "$old" && -n "$new" ]] || return 0
    exclude_filter_paths_equivalent "$old" "$new" && return 0

    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%$'\r'}"
        if [[ -n "$line" ]] && [[ ! "$line" =~ ^# ]]; then
            new_line="$(exclude_filter_line_rewrite_for_rename "$line" "$old" "$new")"
            if [[ "$new_line" != "$line" ]]; then
                changed=1
                if (( header_printed == 0 )); then
                    if [[ "$mode" == "dry-run" ]]; then
                        emit_wrap_labeled_stdout "[DRY-RUN] Would update exclude file: " "${CYAN}[DRY-RUN] Would update exclude file:${RESET} " "$EXCLUDE_FILTERS_FILE"
                    else
                        emit_wrap_labeled_stdout "EXCLUDE FILE UPDATED: " "${CYAN}EXCLUDE FILE UPDATED:${RESET} " "$EXCLUDE_FILTERS_FILE"
                    fi
                    header_printed=1
                fi
                emit_wrap_labeled_stdout "  OLD: " "  ${YELLOW}OLD:${RESET} " "$line" yellow
                emit_wrap_labeled_stdout "  NEW: " "  ${GREEN}NEW:${RESET} " "$new_line" green
            fi
            out_lines+=( "$new_line" )
        else
            out_lines+=( "$line" )
        fi
    done < "$EXCLUDE_FILTERS_FILE"

    (( changed == 1 )) || return 0

    if [[ "$mode" == "dry-run" ]]; then
        return 0
    fi

    tmp="$(mktemp)"
    {
        local i
        for i in "${!out_lines[@]}"; do
            printf '%s\n' "${out_lines[$i]}"
        done
    } > "$tmp"
    mv -f -- "$tmp" "$EXCLUDE_FILTERS_FILE"
    load_exclude_filters
    vlog "Exclude filter file updated after rename: '$old' -> '$new'"
}

sql_escape() {
    printf "%s" "$1" | sed "s/'/''/g"
}

db_require_sqlite() {
    if ! command -v sqlite3 >/dev/null 2>&1; then
        echo "ERROR: --use-db was requested but sqlite3 is not installed." >&2
        exit 1
    fi
}

db_abs_path() {
    local p="$1"
    if command -v realpath >/dev/null 2>&1; then
        realpath -e -- "$p"
    elif command -v readlink >/dev/null 2>&1; then
        readlink -f -- "$p"
    else
        local dir base
        dir="$(dirname -- "$p")"
        base="$(basename -- "$p")"
        ( cd "$dir" && printf '%s/%s\n' "$(pwd -P)" "$base" )
    fi
}

# After mv, the old path no longer exists; realpath -e fails. Reconstruct from parent (still on disk) + basename.
db_abs_path_if_deleted() {
    local p="$1" dir base parent_abs
    if [[ -e "$p" || -h "$p" ]]; then
        db_abs_path "$p" 2>/dev/null
        return $?
    fi
    dir="$(dirname -- "$p")"
    base="$(basename -- "$p")"
    parent_abs="$(db_abs_path "$dir" 2>/dev/null || true)"
    [[ -n "$parent_abs" ]] || return 1
    if [[ "$parent_abs" == "/" ]]; then
        printf '/%s\n' "$base"
    else
        printf '%s/%s\n' "$parent_abs" "$base"
    fi
}

db_delete_cached_row_for_path() {
    local path="$1"
    local abs
    (( USE_DB == 1 )) || return 0
    [[ -e "$path" ]] || return 0
    abs="$(db_abs_path "$path" 2>/dev/null || true)"
    [[ -n "$abs" ]] || return 0
    printf "DELETE FROM checked_paths WHERE path='%s';\n" "$(sql_escape "$abs")" >> "$DB_PENDING_SQL_FILE"
    unset 'DB_CACHE_META[$abs]'
    unset 'DB_CACHE_STATUS[$abs]'
    unset 'DB_CACHE_HASH_MD5[$abs]'
    unset 'DB_CACHE_HASH_SHA512[$abs]'
    unset 'DB_CACHE_ROW_EXISTS[$abs]'
    (( ++DB_PENDING_COUNT ))
    if (( DB_PENDING_COUNT >= DB_FLUSH_EVERY )); then
        db_flush_pending
    fi
}

db_get_size_mtime() {
    stat -Lc '%s|%Y' -- "$1"
}

db_compute_signature() {
    local path="$1"

    [[ -f "$path" ]] || return 1

    if command -v sha1sum >/dev/null 2>&1; then
        sha1sum -- "$path" | awk '{print $1}'
    elif command -v md5sum >/dev/null 2>&1; then
        md5sum -- "$path" | awk '{print $1}'
    else
        cksum -- "$path" | awk '{print $1 "-" $2}'
    fi
}

declare -A DB_CACHE_META=()
declare -A DB_CACHE_STATUS=()
declare -A DB_CACHE_SIG=()
declare -A DB_CACHE_SIG_STATUS=()
declare -A DB_CACHE_HASH_MD5=()
declare -A DB_CACHE_HASH_SHA512=()
declare -A DB_CACHE_ROW_EXISTS=()
DB_PENDING_SQL_FILE=""
DB_PENDING_COUNT=0
DB_FLUSH_EVERY=500

rename_sqlite3_probe_cli_uri_support() {
    [[ -n "$RENAME_SQLITE3_URI_PROBED" ]] && return 0
    RENAME_SQLITE3_URI_PROBED=1
    if sqlite3 -uri ':memory:' 'SELECT 1;' >/dev/null 2>&1; then
        RENAME_SQLITE3_HAS_URI_FLAG=1
    else
        RENAME_SQLITE3_HAS_URI_FLAG=0
    fi
}

# Central open path so optional URI+nolock applies to every sqlite3 use of the cache DB.
rename_sqlite3_db_run() {
    if [[ -n "$DB_SQLITE_USE_URI" ]]; then
        rename_sqlite3_probe_cli_uri_support
        if (( RENAME_SQLITE3_HAS_URI_FLAG == 1 )); then
            sqlite3 -uri "$DB_SQLITE_URI" "$@"
        else
            if [[ -z "$RENAME_SQLITE3_URI_FALLBACK_WARNED" ]]; then
                RENAME_SQLITE3_URI_FALLBACK_WARNED=1
                local sqlite_uri_warn_msg
                sqlite_uri_warn_msg="WARNING: this sqlite3 has no -uri option (need 3.7.13+ for file:...?nolock=1). Opening the cache by filesystem path instead; on CIFS/SMB you may see \"database is locked\" — install a newer sqlite3 or use a local cache directory."
                if (( ${#sqlite_uri_warn_msg} <= MAX_LINE_LENGTH )); then
                    echo "$sqlite_uri_warn_msg" >&2
                else
                    echo "WARNING: this sqlite3 has no -uri option (need 3.7.13+ for file:...?nolock=1). Opening the cache by filesystem path instead;" >&2
                    echo "          On CIFS/SMB you may see \"database is locked\" — install a newer sqlite3 or use a local cache directory." >&2
                fi
            fi
            sqlite3 "$DB_FILE" "$@"
        fi
    else
        sqlite3 "$DB_FILE" "$@"
    fi
}

db_flush_pending() {
    (( USE_DB == 1 )) || return 0
    [[ -n "$DB_PENDING_SQL_FILE" && -s "$DB_PENDING_SQL_FILE" ]] || return 0
    {
        printf 'BEGIN IMMEDIATE;\n'
        cat -- "$DB_PENDING_SQL_FILE"
        printf 'COMMIT;\n'
    } | rename_sqlite3_db_run >/dev/null 2>&1 || true
    : > "$DB_PENDING_SQL_FILE"
    DB_PENDING_COUNT=0
}

cleanup_on_exit() {
    local rc=$?
    rename_sh_window_title_restore || true
    if (( USE_DB == 1 )); then
        db_flush_pending || true
        if [[ -n "$DB_PENDING_SQL_FILE" && -e "$DB_PENDING_SQL_FILE" ]]; then
            rm -f -- "$DB_PENDING_SQL_FILE"
        fi
    fi
    [[ -n "${RENAME_SH_GOPRO_STATE_FILE:-}" && -f "$RENAME_SH_GOPRO_STATE_FILE" ]] && rm -f -- "$RENAME_SH_GOPRO_STATE_FILE"
    exit $rc
}
trap cleanup_on_exit EXIT

db_migrate_legacy_file() {
    if [[ -f "$LEGACY_DB_FILE" && ! -f "$DB_FILE" ]]; then
        mv -f -- "$LEGACY_DB_FILE" "$DB_FILE"
        [[ -f "${LEGACY_DB_FILE}-wal" ]] && mv -f -- "${LEGACY_DB_FILE}-wal" "${DB_FILE}-wal"
        [[ -f "${LEGACY_DB_FILE}-shm" ]] && mv -f -- "${LEGACY_DB_FILE}-shm" "${DB_FILE}-shm"
        echo "SQLite cache migrated: $LEGACY_DB_FILE -> $DB_FILE"
    fi
}

# Leftover -wal/-shm from a crash or copy, or a 0-byte DB file, often yields SQLITE_BUSY ("database is locked") on first open.
db_remove_stale_sqlite_lock_artifacts() {
    [[ -n "$DB_FILE" ]] || return 0
    if [[ ! -f "$DB_FILE" ]]; then
        rm -f -- "${DB_FILE}-wal" "${DB_FILE}-shm" "${DB_FILE}-journal" 2>/dev/null || true
        return 0
    fi
    if [[ ! -s "$DB_FILE" ]]; then
        rm -f -- "$DB_FILE" "${DB_FILE}-wal" "${DB_FILE}-shm" "${DB_FILE}-journal" 2>/dev/null || true
    fi
}

db_clear_sqlite_sidecar_files() {
    [[ -n "$DB_FILE" ]] || return 0
    rm -f -- "${DB_FILE}-wal" "${DB_FILE}-shm" "${DB_FILE}-journal" 2>/dev/null || true
}

db_sqlite_file_uri_nolock() {
    command -v python3 >/dev/null 2>&1 || return 1
    python3 -c 'import pathlib, urllib.parse, sys
p = pathlib.Path(sys.argv[1]).expanduser().resolve()
print("file:" + urllib.parse.quote(str(p), safe="/:") + "?nolock=1")
' "$DB_FILE"
}

db_init_create_checked_paths_schema_core() {
    # Avoid locking_mode=EXCLUSIVE / BEGIN IMMEDIATE: on SMB/CIFS they often yield SQLITE_BUSY even for a new file.
    # Include every column the script reads/writes so warmup does not depend on fragile per-invocation ALTERs on network FS.
    rename_sqlite3_db_run -batch >/dev/null 2>&1 <<'SQL'
PRAGMA busy_timeout=30000;
CREATE TABLE IF NOT EXISTS checked_paths (
    path TEXT PRIMARY KEY,
    kind TEXT NOT NULL,
    size INTEGER NOT NULL,
    mtime INTEGER NOT NULL,
    status TEXT NOT NULL,
    last_checked TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    signature TEXT,
    file_hash_kind TEXT,
    file_hash TEXT,
    file_md5 TEXT,
    file_sha512 TEXT
);
CREATE INDEX IF NOT EXISTS idx_checked_paths_kind ON checked_paths(kind);
CREATE INDEX IF NOT EXISTS idx_checked_paths_signature ON checked_paths(signature);
CREATE INDEX IF NOT EXISTS idx_checked_paths_file_hash ON checked_paths(file_hash_kind, file_hash);
CREATE INDEX IF NOT EXISTS idx_checked_paths_file_md5 ON checked_paths(file_md5);
CREATE INDEX IF NOT EXISTS idx_checked_paths_file_sha512 ON checked_paths(file_sha512);
CREATE INDEX IF NOT EXISTS idx_checked_paths_missing_hashes ON checked_paths(path) WHERE COALESCE(file_md5,'')='' OR COALESCE(file_sha512,'');
SQL
}

# Older caches only had the base columns; add the rest in one sqlite session (busy_timeout) before WAL/journal tweaks.
db_upgrade_checked_paths_schema() {
    rename_sqlite3_db_run -batch >/dev/null 2>&1 <<'SQL' || true
PRAGMA busy_timeout=30000;
ALTER TABLE checked_paths ADD COLUMN signature TEXT;
ALTER TABLE checked_paths ADD COLUMN file_hash_kind TEXT;
ALTER TABLE checked_paths ADD COLUMN file_hash TEXT;
ALTER TABLE checked_paths ADD COLUMN file_md5 TEXT;
ALTER TABLE checked_paths ADD COLUMN file_sha512 TEXT;
CREATE INDEX IF NOT EXISTS idx_checked_paths_signature ON checked_paths(signature);
CREATE INDEX IF NOT EXISTS idx_checked_paths_file_hash ON checked_paths(file_hash_kind, file_hash);
CREATE INDEX IF NOT EXISTS idx_checked_paths_file_md5 ON checked_paths(file_md5);
CREATE INDEX IF NOT EXISTS idx_checked_paths_file_sha512 ON checked_paths(file_sha512);
CREATE INDEX IF NOT EXISTS idx_checked_paths_missing_hashes ON checked_paths(path) WHERE COALESCE(file_md5,'')='' OR COALESCE(file_sha512,'');
SQL
}

# Last resort: build the DB on a local filesystem (TMPDIR), then move into place and use nolock for opens on flaky mounts.
db_init_create_checked_paths_schema_via_local_tmp() {
    local tmp="" uri
    tmp="$(mktemp "${TMPDIR:-/tmp}/rename.sh.sqlite-init.XXXXXX")" || return 1
    rm -f -- "$tmp"
    tmp="${tmp}.sqlite3"

    if ! sqlite3 -batch "$tmp" >/dev/null 2>&1 <<'SQL'
PRAGMA busy_timeout=30000;
CREATE TABLE IF NOT EXISTS checked_paths (
    path TEXT PRIMARY KEY,
    kind TEXT NOT NULL,
    size INTEGER NOT NULL,
    mtime INTEGER NOT NULL,
    status TEXT NOT NULL,
    last_checked TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    signature TEXT,
    file_hash_kind TEXT,
    file_hash TEXT,
    file_md5 TEXT,
    file_sha512 TEXT
);
CREATE INDEX IF NOT EXISTS idx_checked_paths_kind ON checked_paths(kind);
CREATE INDEX IF NOT EXISTS idx_checked_paths_signature ON checked_paths(signature);
CREATE INDEX IF NOT EXISTS idx_checked_paths_file_hash ON checked_paths(file_hash_kind, file_hash);
CREATE INDEX IF NOT EXISTS idx_checked_paths_file_md5 ON checked_paths(file_md5);
CREATE INDEX IF NOT EXISTS idx_checked_paths_file_sha512 ON checked_paths(file_sha512);
CREATE INDEX IF NOT EXISTS idx_checked_paths_missing_hashes ON checked_paths(path) WHERE COALESCE(file_md5,'')='' OR COALESCE(file_sha512,'');
SQL
    then
        rm -f -- "$tmp"
        return 1
    fi

    db_clear_sqlite_sidecar_files
    db_remove_stale_sqlite_lock_artifacts

    if ! mv -f -- "$tmp" "$DB_FILE" 2>/dev/null; then
        rm -f -- "$tmp"
        return 1
    fi

    if uri="$(db_sqlite_file_uri_nolock 2>/dev/null)"; then
        DB_SQLITE_USE_URI=1
        DB_SQLITE_URI="$uri"
        (( VERBOSE == 1 )) && echo "[VERBOSE] SQLite cache created under ${TMPDIR:-/tmp} then moved to start dir; further opens use ?nolock=1 on this volume." >&2
    else
        (( VERBOSE == 1 )) && echo "[VERBOSE] SQLite cache created under ${TMPDIR:-/tmp} then moved to start dir (nolock URI needs python3 — use one rename.sh per cache if the share still locks)." >&2
    fi
    return 0
}

db_init_create_checked_paths_schema_nolock() {
    local uri
    uri="$(db_sqlite_file_uri_nolock)" || return 1
    DB_SQLITE_USE_URI=1
    DB_SQLITE_URI="$uri"
    if db_init_create_checked_paths_schema_core; then
        return 0
    fi
    DB_SQLITE_USE_URI=""
    DB_SQLITE_URI=""
    return 1
}

db_init_create_checked_paths_schema() {
    DB_SQLITE_USE_URI=""
    DB_SQLITE_URI=""
    db_init_create_checked_paths_schema_core
}

db_run_maintenance() {
    local mode="$1"

    (( USE_DB == 1 )) || return 0
    case "$mode" in
        auto|full) ;;
        *) return 0 ;;
    esac

    if [[ -z "$DB_PENDING_SQL_FILE" || ! -e "$DB_PENDING_SQL_FILE" ]]; then
        DB_PENDING_SQL_FILE="$(mktemp)"
        DB_PENDING_COUNT=0
    fi

    if [[ "$mode" == "auto" ]]; then
        startup_progress "SQLite maintenance: running AUTO profile..."
        (( VERBOSE == 1 )) && echo "[VERBOSE] SQLite maintenance command: PRAGMA optimize;" >&2
        (( VERBOSE == 1 )) && echo "[VERBOSE] SQLite maintenance command: PRAGMA wal_checkpoint(PASSIVE);" >&2
        rename_sqlite3_db_run >/dev/null 2>&1 <<'SQL'
PRAGMA optimize;
PRAGMA wal_checkpoint(PASSIVE);
SQL
        db_prune_missing_paths
        [[ "$stopped_by_user" == yes ]] && return 0
        db_maintenance_backfill_missing_hashes
        startup_progress "SQLite maintenance: AUTO profile finished"
        return 0
    fi

    startup_progress "SQLite maintenance: running FULL profile..."
    (( VERBOSE == 1 )) && echo "[VERBOSE] SQLite maintenance command: PRAGMA optimize;" >&2
    (( VERBOSE == 1 )) && echo "[VERBOSE] SQLite maintenance command: ANALYZE;" >&2
    (( VERBOSE == 1 )) && echo "[VERBOSE] SQLite maintenance command: REINDEX checked_paths;" >&2
    (( VERBOSE == 1 )) && echo "[VERBOSE] SQLite maintenance command: PRAGMA wal_checkpoint(TRUNCATE);" >&2
    rename_sqlite3_db_run >/dev/null 2>&1 <<'SQL'
PRAGMA optimize;
ANALYZE;
REINDEX checked_paths;
PRAGMA wal_checkpoint(TRUNCATE);
SQL
    db_prune_missing_paths
    [[ "$stopped_by_user" == yes ]] && return 0
    db_maintenance_backfill_missing_hashes
    startup_progress "SQLite maintenance: FULL profile finished"
}

db_prune_missing_paths() {
    local path escaped_path
    local total_db_rows=0
    local progress_pct=0
    local next_progress_pct=5
    local next_progress_count=500
    local progress_printed_by_count=0
    local delete_total=0
    local delete_processed=0
    local delete_progress_pct=0
    local delete_next_progress_pct=5
    local delete_next_progress_count=500
    local delete_progress_printed_by_count=0
    local delete_chunk_size=500
    local start_idx=0
    local end_idx=0
    local i=0
    local -a missing_paths=()

    DB_MAINT_ROWS_CHECKED=0
    DB_MAINT_ROWS_MISSING=0
    DB_MAINT_ROWS_REMOVED=0

    startup_progress "SQLite maintenance: checking DB paths against filesystem..."
    total_db_rows="$(rename_sqlite3_db_run 'SELECT COUNT(*) FROM checked_paths;' 2>/dev/null || echo 0)"
    [[ "$total_db_rows" =~ ^[0-9]+$ ]] || total_db_rows=0

    if (( total_db_rows > 0 )); then
        startup_progress "SQLite maintenance: crosscheck progress 0% (0 / $total_db_rows checked, 0 missing)..."
    fi

    while IFS= read -r path; do
        [[ "$stopped_by_user" == yes ]] && break
        [[ -n "$path" ]] || continue
        (( ++DB_MAINT_ROWS_CHECKED ))
        if [[ ! -e "$path" ]]; then
            (( ++DB_MAINT_ROWS_MISSING ))
            missing_paths+=("$path")
            print_db_maintenance_missing_verbose "$path"
        fi

        if (( total_db_rows > 0 )); then
            progress_pct=$(( DB_MAINT_ROWS_CHECKED * 100 / total_db_rows ))
            progress_printed_by_count=0
            if (( DB_MAINT_ROWS_CHECKED >= next_progress_count )); then
                startup_progress "SQLite maintenance: crosscheck progress ${progress_pct}% ($DB_MAINT_ROWS_CHECKED / $total_db_rows checked, $DB_MAINT_ROWS_MISSING missing)..."
                next_progress_count=$((next_progress_count + 500))
                progress_printed_by_count=1
                while (( next_progress_pct <= progress_pct )) && (( next_progress_pct <= 100 )); do
                    next_progress_pct=$((next_progress_pct + 5))
                done
            fi
            if (( progress_printed_by_count == 0 )); then
                while (( progress_pct >= next_progress_pct )) && (( next_progress_pct <= 100 )); do
                    startup_progress "SQLite maintenance: crosscheck progress ${next_progress_pct}% ($DB_MAINT_ROWS_CHECKED / $total_db_rows checked, $DB_MAINT_ROWS_MISSING missing)..."
                    next_progress_pct=$((next_progress_pct + 5))
                done
            fi
        elif (( DB_MAINT_ROWS_CHECKED >= next_progress_count )); then
            startup_progress "SQLite maintenance: crosscheck progress ($DB_MAINT_ROWS_CHECKED checked, $DB_MAINT_ROWS_MISSING missing)..."
            next_progress_count=$((next_progress_count + 500))
        fi
    done < <(rename_sqlite3_db_run 'SELECT path FROM checked_paths;')

    if (( DB_MAINT_ROWS_MISSING > 0 )); then
        (( VERBOSE == 1 )) && echo "[VERBOSE] SQLite maintenance command: delete rows for missing filesystem paths" >&2
        delete_total="${#missing_paths[@]}"
        startup_progress "SQLite maintenance: delete progress 0% (0 / $delete_total removed from DB)..."
        for (( start_idx=0; start_idx<delete_total; start_idx+=delete_chunk_size )); do
            end_idx=$((start_idx + delete_chunk_size))
            if (( end_idx > delete_total )); then
                end_idx=$delete_total
            fi

            {
                printf 'BEGIN IMMEDIATE;\n'
                for (( i=start_idx; i<end_idx; i++ )); do
                    path="${missing_paths[$i]}"
                    escaped_path="$(sql_escape "$path")"
                    printf "DELETE FROM checked_paths WHERE path='%s';\n" "$escaped_path"
                done
                printf 'COMMIT;\n'
            } | rename_sqlite3_db_run >/dev/null 2>&1

            delete_processed=$end_idx
            delete_progress_pct=$(( delete_processed * 100 / delete_total ))
            delete_progress_printed_by_count=0
            if (( delete_processed >= delete_next_progress_count )); then
                startup_progress "SQLite maintenance: delete progress ${delete_progress_pct}% ($delete_processed / $delete_total removed from DB)..."
                delete_next_progress_count=$((delete_next_progress_count + 500))
                delete_progress_printed_by_count=1
                while (( delete_next_progress_pct <= delete_progress_pct )) && (( delete_next_progress_pct <= 100 )); do
                    delete_next_progress_pct=$((delete_next_progress_pct + 5))
                done
            fi
            if (( delete_progress_printed_by_count == 0 )); then
                while (( delete_progress_pct >= delete_next_progress_pct )) && (( delete_next_progress_pct <= 100 )); do
                    startup_progress "SQLite maintenance: delete progress ${delete_next_progress_pct}% ($delete_processed / $delete_total removed from DB)..."
                    delete_next_progress_pct=$((delete_next_progress_pct + 5))
                done
            fi
        done
        DB_MAINT_ROWS_REMOVED="$delete_processed"
    fi

    startup_progress "SQLite maintenance: filesystem check finished (checked: $DB_MAINT_ROWS_CHECKED, missing: $DB_MAINT_ROWS_MISSING, removed: $DB_MAINT_ROWS_REMOVED)"
}

# SQL WHERE for rows with at least one missing hash slot (honours file_hash_kind/file_hash like cache warmup).
_db_maintenance_hash_backfill_candidate_where() {
    printf "%s" "(path NOT LIKE '%%.md5' AND path NOT LIKE '%%.sha512') AND ((COALESCE(file_md5,'')='' AND NOT (COALESCE(file_hash_kind,'')='md5' AND COALESCE(file_hash,'')<>'')) OR (COALESCE(file_sha512,'')='' AND NOT (COALESCE(file_hash_kind,'')='sha512' AND COALESCE(file_hash,'')<>'')))"
}

_db_maintenance_row_has_effective_md5() {
    local md5_hash="$1" file_hash_kind="$2" file_hash="$3"
    [[ -n "$md5_hash" ]] && return 0
    [[ "$file_hash_kind" == md5 && -n "$file_hash" ]] && return 0
    return 1
}

_db_maintenance_row_has_effective_sha512() {
    local sha512_hash="$1" file_hash_kind="$2" file_hash="$3"
    [[ -n "$sha512_hash" ]] && return 0
    [[ "$file_hash_kind" == sha512 && -n "$file_hash" ]] && return 0
    return 1
}

print_db_maintenance_hash_job_verbose() {
    (( VERBOSE == 1 )) || return 0
    local path="$1"
    local hash_kind="$2"
    local ts
    local line
    ts="$(date '+%Y-%m-%d %H:%M:%S')"
    line="[VERBOSE ${ts}] SQLite maintenance hash backfill ($hash_kind): '${path}' ($DB_MAINT_HASH_JOBS_REMAINING remaining)"

    if (( ${#line} <= MAX_LINE_LENGTH )); then
        echo "$line" >&2
    else
        echo "[VERBOSE ${ts}] SQLite maintenance hash backfill ($hash_kind): ($DB_MAINT_HASH_JOBS_REMAINING remaining)" >&2
        echo "          '${path}'" >&2
    fi
}

_db_maintenance_hash_backfill_format_eta() {
    local secs="$1"

    (( secs < 0 )) && secs=0
    if (( secs < 60 )); then
        printf '~%ds left' "$secs"
    elif (( secs < 3600 )); then
        printf '~%dm left' $(( (secs + 59) / 60 ))
    else
        printf '~%dh %dm left' $(( secs / 3600 )) $(( (secs % 3600 + 59) / 60 ))
    fi
}

_db_maintenance_hash_backfill_progress_render() {
    local force="${1:-0}"
    local now progress_pct filled_n empty_n bar elapsed rate eta eta_str rate_str line

    (( VERBOSE == 1 )) && return 0
    (( DB_MAINT_HASH_JOBS_TOTAL > 0 )) || return 0

    progress_pct=$(( DB_MAINT_HASH_JOBS_DONE * 100 / DB_MAINT_HASH_JOBS_TOTAL ))
    now="$(date +%s)"

    if (( force != 1 )); then
        if [[ "$DB_MAINT_HASH_BACKFILL_TTY_BAR" == yes ]]; then
            if (( progress_pct < 100 )) && (( progress_pct < DB_MAINT_HASH_BACKFILL_LAST_DISPLAY_PCT + 1 )) && (( now - DB_MAINT_HASH_BACKFILL_LAST_DISPLAY_EPOCH < 1 )); then
                return 0
            fi
        elif (( progress_pct < DB_MAINT_HASH_BACKFILL_NEXT_PCT )) && (( progress_pct < 100 )); then
            return 0
        fi
    fi

    if [[ "$DB_MAINT_HASH_BACKFILL_TTY_BAR" == yes ]]; then
        filled_n=$(( progress_pct * DB_MAINT_HASH_BACKFILL_BAR_WIDTH / 100 ))
        empty_n=$(( DB_MAINT_HASH_BACKFILL_BAR_WIDTH - filled_n ))
        bar="$(printf '%*s' "$filled_n" '' | tr ' ' '#')$(printf '%*s' "$empty_n" '' | tr ' ' '-')"
        elapsed=$(( now - DB_MAINT_HASH_BACKFILL_START_EPOCH ))
        if (( DB_MAINT_HASH_JOBS_DONE > 0 )) && (( elapsed > 0 )); then
            rate=$(( DB_MAINT_HASH_JOBS_DONE / elapsed ))
            eta=$(( (elapsed * (DB_MAINT_HASH_JOBS_TOTAL - DB_MAINT_HASH_JOBS_DONE)) / DB_MAINT_HASH_JOBS_DONE ))
            eta_str="$(_db_maintenance_hash_backfill_format_eta "$eta")"
            rate_str="~${rate}/s"
            line="$(printf 'hash backfill: [%s] %3d%% %d/%d  %s  %s' "$bar" "$progress_pct" "$DB_MAINT_HASH_JOBS_DONE" "$DB_MAINT_HASH_JOBS_TOTAL" "$rate_str" "$eta_str")"
        else
            line="$(printf 'hash backfill: [%s] %3d%% %d/%d' "$bar" "$progress_pct" "$DB_MAINT_HASH_JOBS_DONE" "$DB_MAINT_HASH_JOBS_TOTAL")"
        fi
        printf '\r%s\033[K' "$line" >/dev/tty 2>/dev/null || true
        DB_MAINT_HASH_BACKFILL_LAST_DISPLAY_PCT=$progress_pct
        DB_MAINT_HASH_BACKFILL_LAST_DISPLAY_EPOCH=$now
        return 0
    fi

    if (( progress_pct >= DB_MAINT_HASH_BACKFILL_NEXT_PCT )) && (( DB_MAINT_HASH_BACKFILL_NEXT_PCT <= 100 )); then
        echo "hash backfill: ${DB_MAINT_HASH_BACKFILL_NEXT_PCT}% ($DB_MAINT_HASH_JOBS_DONE / $DB_MAINT_HASH_JOBS_TOTAL)"
        DB_MAINT_HASH_BACKFILL_NEXT_PCT=$(( DB_MAINT_HASH_BACKFILL_NEXT_PCT + 5 ))
        while (( progress_pct >= DB_MAINT_HASH_BACKFILL_NEXT_PCT )) && (( DB_MAINT_HASH_BACKFILL_NEXT_PCT <= 100 )); do
            DB_MAINT_HASH_BACKFILL_NEXT_PCT=$(( DB_MAINT_HASH_BACKFILL_NEXT_PCT + 5 ))
        done
    fi
    DB_MAINT_HASH_BACKFILL_LAST_DISPLAY_PCT=$progress_pct
}

_db_maintenance_hash_backfill_progress_update() {
    _db_maintenance_hash_backfill_progress_render 0
}

_db_maintenance_hash_backfill_progress_finish() {
    (( VERBOSE == 1 )) && return 0
    if [[ "$DB_MAINT_HASH_BACKFILL_TTY_BAR" == yes ]]; then
        _db_maintenance_hash_backfill_progress_render 1
        nonverbose_progress_tty_nl
        DB_MAINT_HASH_BACKFILL_TTY_BAR=no
        return 0
    fi
    if (( DB_MAINT_HASH_JOBS_TOTAL > 0 )) && (( DB_MAINT_HASH_JOBS_DONE >= DB_MAINT_HASH_JOBS_TOTAL )) && (( DB_MAINT_HASH_BACKFILL_NEXT_PCT <= 100 )); then
        echo "hash backfill: 100% ($DB_MAINT_HASH_JOBS_DONE / $DB_MAINT_HASH_JOBS_TOTAL)"
    fi
}

_db_maintenance_hash_job_completed() {
    local path="$1"
    local hash_kind="$2"
    if (( DB_MAINT_HASH_JOBS_REMAINING > 0 )); then
        DB_MAINT_HASH_JOBS_REMAINING=$(( DB_MAINT_HASH_JOBS_REMAINING - 1 ))
    fi
    if (( VERBOSE == 1 )); then
        print_db_maintenance_hash_job_verbose "$path" "$hash_kind"
    else
        (( ++DB_MAINT_HASH_JOBS_DONE ))
        _db_maintenance_hash_backfill_progress_update
    fi
}

db_maintenance_backfill_missing_hashes() {
    local path abs md5_hash sha512_hash file_hash_kind file_hash sql
    local new_md5 new_sha512
    local updated_this_row=0
    local md5_backend=""
    local sha512_backend=""
    local candidate_where=""
    local candidate_query=""
    local need_md5=0 need_sha512=0

    DB_MAINT_HASH_ROWS_SCANNED=0
    DB_MAINT_HASH_ROWS_UPDATED=0
    DB_MAINT_HASH_MD5_FILLED=0
    DB_MAINT_HASH_SHA512_FILLED=0
    DB_MAINT_HASH_JOBS_TOTAL=0
    DB_MAINT_HASH_JOBS_REMAINING=0
    DB_MAINT_HASH_MD5_JOBS=0
    DB_MAINT_HASH_SHA512_JOBS=0
    DB_MAINT_HASH_SKIPPED_NOT_FILE=0
    DB_MAINT_HASH_JOBS_DONE=0
    DB_MAINT_HASH_BACKFILL_TTY_BAR=no
    DB_MAINT_HASH_BACKFILL_START_EPOCH=0
    DB_MAINT_HASH_BACKFILL_LAST_DISPLAY_PCT=-1
    DB_MAINT_HASH_BACKFILL_LAST_DISPLAY_EPOCH=0
    DB_MAINT_HASH_BACKFILL_NEXT_PCT=5

    if command -v md5sum >/dev/null 2>&1; then
        md5_backend="md5sum"
    elif command -v md5 >/dev/null 2>&1; then
        md5_backend="md5"
    elif command -v openssl >/dev/null 2>&1; then
        md5_backend="openssl"
    else
        echo "ERROR: no md5 hash command available for maintenance backfill." >&2
        exit 1
    fi

    if command -v sha512sum >/dev/null 2>&1; then
        sha512_backend="sha512sum"
    elif command -v shasum >/dev/null 2>&1; then
        sha512_backend="shasum"
    elif command -v openssl >/dev/null 2>&1; then
        sha512_backend="openssl"
    else
        echo "ERROR: no sha512 hash command available for maintenance backfill." >&2
        exit 1
    fi

    candidate_where="$(_db_maintenance_hash_backfill_candidate_where)"
    candidate_query="SELECT path, COALESCE(file_md5,''), COALESCE(file_sha512,''), COALESCE(file_hash_kind,''), COALESCE(file_hash,'') FROM checked_paths WHERE ${candidate_where};"

    startup_progress "SQLite maintenance: counting missing hash slots on existing files..."
    while IFS='|' read -r path md5_hash sha512_hash file_hash_kind file_hash; do
        [[ "$stopped_by_user" == yes ]] && break
        [[ -n "$path" ]] || continue
        if [[ ! -f "$path" ]]; then
            (( ++DB_MAINT_HASH_SKIPPED_NOT_FILE ))
            continue
        fi
        if ! _db_maintenance_row_has_effective_md5 "$md5_hash" "$file_hash_kind" "$file_hash"; then
            (( ++DB_MAINT_HASH_MD5_JOBS ))
        fi
        if ! _db_maintenance_row_has_effective_sha512 "$sha512_hash" "$file_hash_kind" "$file_hash"; then
            (( ++DB_MAINT_HASH_SHA512_JOBS ))
        fi
    done < <(rename_sqlite3_db_run -separator '|' "$candidate_query")

    DB_MAINT_HASH_JOBS_TOTAL=$(( DB_MAINT_HASH_MD5_JOBS + DB_MAINT_HASH_SHA512_JOBS ))
    DB_MAINT_HASH_JOBS_REMAINING=$DB_MAINT_HASH_JOBS_TOTAL

    startup_progress "SQLite maintenance: hash inventory — md5 missing: $DB_MAINT_HASH_MD5_JOBS, sha512 missing: $DB_MAINT_HASH_SHA512_JOBS, total jobs: $DB_MAINT_HASH_JOBS_TOTAL (skipped not on disk: $DB_MAINT_HASH_SKIPPED_NOT_FILE)"

    if (( DB_MAINT_HASH_JOBS_TOTAL == 0 )); then
        startup_progress "SQLite maintenance: hash backfill skipped (no missing hashes on existing files)"
        return 0
    fi

    startup_progress "SQLite maintenance: hash backfill starting ($DB_MAINT_HASH_JOBS_REMAINING jobs remaining)..."
    if (( VERBOSE == 0 )); then
        DB_MAINT_HASH_BACKFILL_START_EPOCH="$(date +%s)"
        if [[ -w /dev/tty ]] 2>/dev/null; then
            DB_MAINT_HASH_BACKFILL_TTY_BAR=yes
            _db_maintenance_hash_backfill_progress_render 1
        fi
    fi

    while IFS='|' read -r path md5_hash sha512_hash file_hash_kind file_hash; do
        [[ "$stopped_by_user" == yes ]] && break
        [[ -n "$path" ]] || continue
        (( ++DB_MAINT_HASH_ROWS_SCANNED ))

        if [[ ! -f "$path" ]]; then
            continue
        fi

        abs="$(db_abs_path "$path" 2>/dev/null || true)"
        [[ -n "$abs" ]] || continue

        new_md5="$md5_hash"
        new_sha512="$sha512_hash"
        updated_this_row=0
        need_md5=0
        need_sha512=0

        if ! _db_maintenance_row_has_effective_md5 "$md5_hash" "$file_hash_kind" "$file_hash"; then
            need_md5=1
        fi
        if ! _db_maintenance_row_has_effective_sha512 "$sha512_hash" "$file_hash_kind" "$file_hash"; then
            need_sha512=1
        fi
        (( need_md5 == 0 && need_sha512 == 0 )) && continue

        if (( need_md5 == 1 )); then
            case "$md5_backend" in
                md5sum)  new_md5="$(md5sum -- "$path" | awk '{print tolower($1)}')" ;;
                md5)     new_md5="$(md5 -q -- "$path" | awk '{print tolower($1)}')" ;;
                openssl) new_md5="$(openssl dgst -md5 -- "$path" | awk '{print tolower($NF)}')" ;;
            esac
            DB_CACHE_HASH_MD5["$abs"]="$new_md5"
            (( ++DB_MAINT_HASH_MD5_FILLED ))
            updated_this_row=1
            _db_maintenance_hash_job_completed "$path" "md5"
        fi
        [[ "$stopped_by_user" == yes ]] && break
        if (( need_sha512 == 1 )); then
            case "$sha512_backend" in
                sha512sum) new_sha512="$(sha512sum -- "$path" | awk '{print tolower($1)}')" ;;
                shasum)    new_sha512="$(shasum -a 512 -- "$path" | awk '{print tolower($1)}')" ;;
                openssl)   new_sha512="$(openssl dgst -sha512 -- "$path" | awk '{print tolower($NF)}')" ;;
            esac
            DB_CACHE_HASH_SHA512["$abs"]="$new_sha512"
            (( ++DB_MAINT_HASH_SHA512_FILLED ))
            updated_this_row=1
            _db_maintenance_hash_job_completed "$path" "sha512"
        fi

        if (( updated_this_row == 1 )); then
            sql="UPDATE checked_paths SET file_md5='$(sql_escape "$new_md5")', file_sha512='$(sql_escape "$new_sha512")', last_checked=CURRENT_TIMESTAMP WHERE path='$(sql_escape "$abs")';"
            printf '%s\n' "$sql" >> "$DB_PENDING_SQL_FILE"
            (( ++DB_PENDING_COUNT ))
            (( ++DB_ROWS_UPDATED ))
            (( ++DB_MAINT_HASH_ROWS_UPDATED ))
            DB_CACHE_ROW_EXISTS["$abs"]=1
            if (( DB_PENDING_COUNT >= DB_FLUSH_EVERY )); then
                db_flush_pending
            fi
        fi
    done < <(rename_sqlite3_db_run -separator '|' "$candidate_query")

    _db_maintenance_hash_backfill_progress_finish
    db_flush_pending
    if [[ "$stopped_by_user" == yes ]]; then
        startup_progress "SQLite maintenance: hash backfill interrupted (remaining: $DB_MAINT_HASH_JOBS_REMAINING, md5 filled: $DB_MAINT_HASH_MD5_FILLED, sha512 filled: $DB_MAINT_HASH_SHA512_FILLED, rows updated: $DB_MAINT_HASH_ROWS_UPDATED, skipped not on disk: $DB_MAINT_HASH_SKIPPED_NOT_FILE)"
    else
        startup_progress "SQLite maintenance: hash backfill finished (remaining: $DB_MAINT_HASH_JOBS_REMAINING, md5 filled: $DB_MAINT_HASH_MD5_FILLED, sha512 filled: $DB_MAINT_HASH_SHA512_FILLED, rows updated: $DB_MAINT_HASH_ROWS_UPDATED, skipped not on disk: $DB_MAINT_HASH_SKIPPED_NOT_FILE)"
    fi
}

print_db_maintenance_summary() {
    local profile="${CLI_DB_MAINTENANCE:-full}"
    local status="finished"

    [[ "$stopped_by_user" == yes ]] && status="interrupted by user (Ctrl-C)"

    echo "========= SQLITE MAINTENANCE SUMMARY ($status) ========="
    echo "Profile:               $profile"
    echo "DB file:               $DB_FILE"
    echo "Script start time:     $SCRIPT_START_TIME"
    echo "Script finish time:    ${SCRIPT_FINISH_TIME:-$(date '+%Y-%m-%d %H:%M:%S')}"
    echo "Filesystem crosscheck:"
    echo "  DB rows checked:     $DB_MAINT_ROWS_CHECKED"
    echo "  missing on disk:     $DB_MAINT_ROWS_MISSING"
    echo "  removed from DB:     $DB_MAINT_ROWS_REMOVED"
    echo "Hash backfill:"
    echo "  hash jobs planned:   $DB_MAINT_HASH_JOBS_TOTAL"
    echo "  hash jobs done:      $DB_MAINT_HASH_JOBS_DONE"
    echo "  hash jobs remaining: $DB_MAINT_HASH_JOBS_REMAINING"
    echo "  md5 slots filled:    $DB_MAINT_HASH_MD5_FILLED"
    echo "  sha512 slots filled: $DB_MAINT_HASH_SHA512_FILLED"
    echo "  rows updated:        $DB_MAINT_HASH_ROWS_UPDATED"
    echo "  rows scanned:        $DB_MAINT_HASH_ROWS_SCANNED"
    echo "  skipped not on disk: $DB_MAINT_HASH_SKIPPED_NOT_FILE"
    echo "DB rows updated (all): $DB_ROWS_UPDATED"
    echo "======================================================="
}

on_interrupt_db_maintenance() {
    trap '' INT
    _db_maintenance_hash_backfill_progress_finish || true
    nonverbose_progress_dot_endline_if_needed || true
    stopped_by_user=yes
    SCRIPT_FINISH_TIME="$(date '+%Y-%m-%d %H:%M:%S')"
    printf '\n%s\n' "Interrupt received during SQLite maintenance — saving pending DB updates and printing summary..." >&2
    db_flush_pending || true
    echo
    print_db_maintenance_summary
    exit 130
}

print_db_maintenance_missing_verbose() {
    (( VERBOSE == 1 )) || return 0
    local path="$1"
    local line="[VERBOSE] SQLite maintenance: DB entry exists for '$path' but file is missing in filesystem; removing row from DB."

    if (( ${#line} <= MAX_LINE_LENGTH )); then
        echo "$line" >&2
    else
        echo "[VERBOSE] SQLite maintenance: DB entry exists for '$path'" >&2
        echo "          but file is missing in filesystem; removing row from DB." >&2
    fi
}

db_init() {
    local warmed_rows=0
    local md5_hash sha512_hash file_hash_kind file_hash

    (( USE_DB == 1 )) || return 0
    db_migrate_legacy_file
    startup_progress "Preparing SQLite cache: $DB_FILE"
    db_require_sqlite
    db_remove_stale_sqlite_lock_artifacts
    # Create schema first (default journal mode). WAL/synchronous pragmas can fail on some
    # mounts or with stale -wal/-shm; applying them only after open avoids a hard init failure.
    if ! db_init_create_checked_paths_schema; then
        db_clear_sqlite_sidecar_files
        db_remove_stale_sqlite_lock_artifacts
        if ! db_init_create_checked_paths_schema; then
            if db_init_create_checked_paths_schema_nolock; then
                (( VERBOSE == 1 )) && echo "[VERBOSE] SQLite cache opened with ?nolock=1 (host FS POSIX locking failed). Use only one rename.sh per directory; corruption risk if two writers." >&2
            elif db_init_create_checked_paths_schema_via_local_tmp; then
                :
            else
                echo "ERROR: could not create or open SQLite cache: $DB_FILE" >&2
                echo "If you see \"database is locked\", close other rename.sh (or sqlite3) using this file, then retry." >&2
                echo "Check write permissions on the start directory. Stale sidecar files from a crash or copy can also cause locks:" >&2
                echo "  rm -f -- \"${DB_FILE}-wal\" \"${DB_FILE}-shm\" \"${DB_FILE}-journal\"" >&2
                echo "sqlite3 diagnostic (first lines):" >&2
                rename_sqlite3_db_run -batch 2>&1 <<'SQL' | head -n 25 >&2 || true
PRAGMA busy_timeout=30000;
CREATE TABLE IF NOT EXISTS checked_paths (
    path TEXT PRIMARY KEY,
    kind TEXT NOT NULL,
    size INTEGER NOT NULL,
    mtime INTEGER NOT NULL,
    status TEXT NOT NULL,
    last_checked TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    signature TEXT,
    file_hash_kind TEXT,
    file_hash TEXT,
    file_md5 TEXT,
    file_sha512 TEXT
);
CREATE INDEX IF NOT EXISTS idx_checked_paths_kind ON checked_paths(kind);
CREATE INDEX IF NOT EXISTS idx_checked_paths_signature ON checked_paths(signature);
CREATE INDEX IF NOT EXISTS idx_checked_paths_file_hash ON checked_paths(file_hash_kind, file_hash);
CREATE INDEX IF NOT EXISTS idx_checked_paths_file_md5 ON checked_paths(file_md5);
CREATE INDEX IF NOT EXISTS idx_checked_paths_file_sha512 ON checked_paths(file_sha512);
CREATE INDEX IF NOT EXISTS idx_checked_paths_missing_hashes ON checked_paths(path) WHERE COALESCE(file_md5,'')='' OR COALESCE(file_sha512,'');
SQL
                exit 1
            fi
        fi
    fi
    db_upgrade_checked_paths_schema
    rename_sqlite3_db_run >/dev/null 2>&1 <<'SQL' || true
PRAGMA journal_mode=WAL;
PRAGMA synchronous=NORMAL;
PRAGMA temp_store=MEMORY;
PRAGMA cache_size=-20000;
SQL
    DB_PENDING_SQL_FILE="$(mktemp)"

    local total_cached_rows=0
    local progress_pct=0
    local next_progress_pct=10

    total_cached_rows="$(rename_sqlite3_db_run 'SELECT COUNT(*) FROM checked_paths;' 2>/dev/null || echo 0)"
    [[ "$total_cached_rows" =~ ^[0-9]+$ ]] || total_cached_rows=0

    if (( total_cached_rows > 0 )); then
        startup_progress "Loading cached rows from SQLite into memory: 0% (0 / $total_cached_rows rows loaded)..."
    else
        startup_progress "Loading cached rows from SQLite into memory..."
    fi

    while IFS='|' read -r path size mtime status signature md5_hash sha512_hash file_hash_kind file_hash; do
        [[ -n "$path" ]] || continue
        DB_CACHE_META["$path"]="$size|$mtime"
        DB_CACHE_STATUS["$path"]="$status"
        DB_CACHE_ROW_EXISTS["$path"]=1
        if [[ -n "$signature" ]]; then
            DB_CACHE_SIG["$signature"]=1
            DB_CACHE_SIG_STATUS["$signature"]="$status"
        fi
        if [[ -z "$md5_hash" && "$file_hash_kind" == "md5" ]]; then
            md5_hash="$file_hash"
        fi
        if [[ -z "$sha512_hash" && "$file_hash_kind" == "sha512" ]]; then
            sha512_hash="$file_hash"
        fi
        if [[ -n "$md5_hash" ]]; then
            DB_CACHE_HASH_MD5["$path"]="$md5_hash"
        fi
        if [[ -n "$sha512_hash" ]]; then
            DB_CACHE_HASH_SHA512["$path"]="$sha512_hash"
        fi
        ((++warmed_rows))
        if (( total_cached_rows > 0 )); then
            progress_pct=$(( warmed_rows * 100 / total_cached_rows ))
            while (( next_progress_pct <= 100 && progress_pct >= next_progress_pct )); do
                startup_progress "SQLite warmup progress: ${next_progress_pct}% ($warmed_rows / $total_cached_rows rows loaded)..."
                (( next_progress_pct += 10 ))
            done
        elif (( warmed_rows % 50000 == 0 )); then
            startup_progress "SQLite warmup progress: $warmed_rows rows loaded..."
        fi
    done < <(rename_sqlite3_db_run -separator '|' 'SELECT path, size, mtime, COALESCE(status, ""), COALESCE(signature, ""), COALESCE(file_md5, ""), COALESCE(file_sha512, ""), COALESCE(file_hash_kind, ""), COALESCE(file_hash, "") FROM checked_paths;')

    if (( total_cached_rows > 0 )); then
        startup_progress "SQLite cache warmup done: 100% ($warmed_rows / $total_cached_rows rows loaded)"
    else
        startup_progress "SQLite cache warmup done: $warmed_rows rows loaded"
    fi
}

db_has_valid_entry() {
    local path="$1"
    local abs meta cached status size mtime sig sig_status

    (( USE_DB == 1 )) || return 1
    (( FORCE_RECHECK == 0 )) || return 1
    [[ -e "$path" ]] || return 1

    abs="$(db_abs_path "$path")"
    cached="${DB_CACHE_META[$abs]-}"
    status="${DB_CACHE_STATUS[$abs]-}"

    if [[ -n "$cached" ]]; then
        if (( FAST_DB == 1 )); then
            return 0
        fi

        meta="$(db_get_size_mtime "$path" 2>/dev/null || true)"
        [[ -n "$meta" ]] || return 1
        size="${meta%%|*}"
        mtime="${meta##*|}"

        if [[ "$cached" == "$size|$mtime" ]]; then
            return 0
        fi
    fi

    if is_checksum_file "$path"; then
        sig="$(db_compute_signature "$path" 2>/dev/null || true)"
        sig_status="${DB_CACHE_SIG_STATUS[$sig]-}"
        if [[ -n "$sig" && -n "${DB_CACHE_SIG[$sig]-}" ]]; then
            if (( FAST_DB == 1 )); then
                return 0
            fi
            meta="$(db_get_size_mtime "$path" 2>/dev/null || true)"
            [[ -n "$meta" ]] || return 1
            size="${meta%%|*}"
            mtime="${meta##*|}"
            if [[ -n "$cached" && "$cached" == "$size|$mtime" ]]; then
                return 0
            fi
            if [[ "$sig_status" == "missing_refs" || "$sig_status" == "checked" ]]; then
                return 0
            fi
        fi
    fi

    return 1
}

db_record_file_hash() {
    local path="$1"
    local hash_kind="$2"
    local hash_value="$3"
    local abs sql specific_sql existing_hash="" write_hash_record=1 confirm_rc=0

    (( USE_DB == 1 )) || return 0
    [[ -e "$path" && -n "$hash_kind" && -n "$hash_value" ]] || return 0

    abs="$(db_abs_path "$path" 2>/dev/null || true)"
    [[ -n "$abs" ]] || return 0

    case "$hash_kind" in
        md5) existing_hash="${DB_CACHE_HASH_MD5[$abs]-}" ;;
        sha512) existing_hash="${DB_CACHE_HASH_SHA512[$abs]-}" ;;
        *) existing_hash="" ;;
    esac

    if [[ -n "${DB_CACHE_ROW_EXISTS[$abs]-}" ]]; then
        if [[ -z "$existing_hash" ]]; then
            DB_HASH_RECORD_STATUS="added_missing"
        elif [[ "$existing_hash" == "$hash_value" ]]; then
            DB_HASH_RECORD_STATUS="unchanged"
        else
            confirm_db_hash_update_for_existing_entry "$path" "$hash_kind" "$existing_hash" "$hash_value"
            confirm_rc=$?
            case "$confirm_rc" in
                0)
                    DB_HASH_RECORD_STATUS="updated"
                    ;;
                1)
                    DB_HASH_RECORD_STATUS="kept_existing"
                    write_hash_record=0
                    ;;
                2)
                    echo "Quitting."
                    exit 0
                    ;;
            esac
        fi
    else
        DB_HASH_RECORD_STATUS="new"
    fi
    if (( write_hash_record == 1 )); then
        if [[ -n "${DB_CACHE_ROW_EXISTS[$abs]-}" ]]; then
            ((++DB_ROWS_UPDATED))
        else
            ((++DB_ROWS_NEW))
        fi
        ((++DB_HASHES_ADDED))
    fi

    case "$hash_kind" in
        md5) specific_sql="file_md5='$(sql_escape "$hash_value")'" ;;
        sha512) specific_sql="file_sha512='$(sql_escape "$hash_value")'" ;;
        *) specific_sql="" ;;
    esac

    if (( write_hash_record == 1 )); then
        sql="INSERT INTO checked_paths(path, kind, size, mtime, status, last_checked, file_hash_kind, file_hash, file_md5, file_sha512) VALUES ('$(sql_escape "$abs")', 'file_hash_only', 0, 0, 'hashed', CURRENT_TIMESTAMP, '$(sql_escape "$hash_kind")', '$(sql_escape "$hash_value")', $( [[ "$hash_kind" == "md5" ]] && printf "'%s'" "$(sql_escape "$hash_value")" || printf "NULL" ), $( [[ "$hash_kind" == "sha512" ]] && printf "'%s'" "$(sql_escape "$hash_value")" || printf "NULL" )) ON CONFLICT(path) DO UPDATE SET file_hash_kind=excluded.file_hash_kind, file_hash=excluded.file_hash, last_checked=CURRENT_TIMESTAMP${specific_sql:+, $specific_sql};"
        printf '%s\n' "$sql" >> "$DB_PENDING_SQL_FILE"
        DB_CACHE_ROW_EXISTS["$abs"]=1
        if [[ "$hash_kind" == "md5" ]]; then
            DB_CACHE_HASH_MD5["$abs"]="$hash_value"
        elif [[ "$hash_kind" == "sha512" ]]; then
            DB_CACHE_HASH_SHA512["$abs"]="$hash_value"
        fi
        (( ++DB_PENDING_COUNT ))
        if (( DB_PENDING_COUNT >= DB_FLUSH_EVERY )); then
            db_flush_pending
        fi
    fi

    print_db_hash_record_verbose "$path" "$hash_kind" "$DB_HASH_RECORD_STATUS"
}

db_find_path_by_file_hash_in_subtree() {
    local search_root="$1"
    local hash_kind="$2"
    local hash_value="$3"
    local search_abs row_path query

    (( USE_DB == 1 )) || return 1
    db_flush_pending >/dev/null 2>&1 || true

    search_abs="$(db_abs_path "$search_root" 2>/dev/null || true)"
    [[ -n "$search_abs" ]] || return 1

    case "$hash_kind" in
        md5) query="SELECT path FROM checked_paths WHERE ((file_md5='$(sql_escape "$hash_value")') OR (file_hash_kind='md5' AND file_hash='$(sql_escape "$hash_value")')) AND path LIKE '$(sql_escape "${search_abs%/}")/%' ORDER BY LENGTH(path) LIMIT 1;" ;;
        sha512) query="SELECT path FROM checked_paths WHERE ((file_sha512='$(sql_escape "$hash_value")') OR (file_hash_kind='sha512' AND file_hash='$(sql_escape "$hash_value")')) AND path LIKE '$(sql_escape "${search_abs%/}")/%' ORDER BY LENGTH(path) LIMIT 1;" ;;
        *) return 1 ;;
    esac

    row_path="$(rename_sqlite3_db_run -separator $'\t' "$query" 2>/dev/null | head -n 1)"
    if [[ -n "$row_path" ]]; then
        if [[ -e "$row_path" ]]; then
            ((++DB_HASH_LOOKUP_HITS))
            print_db_hash_lookup_verbose "hit" "$search_root" "$hash_kind" "$hash_value" "$row_path"
            printf '%s' "$row_path"
            return 0
        fi

        printf "DELETE FROM checked_paths WHERE path='%s';\n" "$(sql_escape "$row_path")" >> "$DB_PENDING_SQL_FILE"
        unset 'DB_CACHE_META[$row_path]'
        unset 'DB_CACHE_STATUS[$row_path]'
        unset 'DB_CACHE_HASH_MD5[$row_path]'
        unset 'DB_CACHE_HASH_SHA512[$row_path]'
        unset 'DB_CACHE_ROW_EXISTS[$row_path]'
        (( ++DB_PENDING_COUNT ))
        (( ++DB_ROWS_REMOVED ))
        (( ++DB_STALE_ROWS_REMOVED ))
        if (( DB_PENDING_COUNT >= DB_FLUSH_EVERY )); then
            db_flush_pending
        fi
    fi

    ((++DB_HASH_LOOKUP_MISSES))
    print_db_hash_lookup_verbose "miss" "$search_root" "$hash_kind" "$hash_value"
    return 1
}

db_get_cached_file_hash() {
    local path="$1"
    local hash_kind="$2"
    local abs cached

    (( USE_DB == 1 )) || return 1
    (( FORCE_RECHECK == 0 )) || return 1
    [[ -e "$path" ]] || return 1

    abs="$(db_abs_path "$path" 2>/dev/null || true)"
    [[ -n "$abs" ]] || return 1

    [[ -n "${DB_CACHE_ROW_EXISTS[$abs]-}" ]] || return 1

    case "$hash_kind" in
        md5) cached="${DB_CACHE_HASH_MD5[$abs]-}" ;;
        sha512) cached="${DB_CACHE_HASH_SHA512[$abs]-}" ;;
        *) cached="" ;;
    esac
    [[ -n "$cached" ]] || return 1

    printf '%s' "$cached"
}


db_backfill_missing_hashes_for_existing_file() {
    local path="$1"
    local abs md5_hash sha512_hash sql

    (( USE_DB == 1 )) || return 0
    [[ -f "$path" ]] || return 0
    is_checksum_file "$path" && return 0

    abs="$(db_abs_path "$path" 2>/dev/null || true)"
    [[ -n "$abs" ]] || return 0

    [[ -n "${DB_CACHE_ROW_EXISTS[$abs]-}" ]] || return 0
    md5_hash="${DB_CACHE_HASH_MD5[$abs]-}"
    sha512_hash="${DB_CACHE_HASH_SHA512[$abs]-}"

    # Performance rule: when a file is skipped because the DB entry is already
    # valid, do not recompute hashes if at least one cached hash is already
    # present. Only backfill when both hashes are missing.
    if [[ -n "$md5_hash" || -n "$sha512_hash" ]]; then
        return 0
    fi

    md5_hash="$(md5_of_file "$path")"
    sha512_hash="$(checksum_of_file sha512 "$path")"
    DB_CACHE_HASH_MD5["$abs"]="$md5_hash"
    DB_CACHE_HASH_SHA512["$abs"]="$sha512_hash"

    sql="UPDATE checked_paths SET file_md5='$(sql_escape "$md5_hash")', file_sha512='$(sql_escape "$sha512_hash")', last_checked=CURRENT_TIMESTAMP WHERE path='$(sql_escape "$abs")';"
    printf '%s
' "$sql" >> "$DB_PENDING_SQL_FILE"
    (( ++DB_PENDING_COUNT ))
    (( ++DB_ROWS_UPDATED ))
    if (( DB_PENDING_COUNT >= DB_FLUSH_EVERY )); then
        db_flush_pending
    fi
}


db_mark_checked() {
    local path="$1"
    local kind="$2"
    local status="$3"
    local abs meta size mtime sig sql sig_sql existing_row=0

    (( USE_DB == 1 )) || return 0
    [[ -e "$path" ]] || return 0

    meta="$(db_get_size_mtime "$path" 2>/dev/null || true)"
    [[ -n "$meta" ]] || return 0
    abs="$(db_abs_path "$path")"
    size="${meta%%|*}"
    mtime="${meta##*|}"
    sig=""

    if [[ -n "${DB_CACHE_ROW_EXISTS[$abs]-}" || -n "${DB_CACHE_META[$abs]-}" || -n "${DB_CACHE_STATUS[$abs]-}" ]]; then
        existing_row=1
    fi

    if is_checksum_file "$path"; then
        sig="$(db_compute_signature "$path" 2>/dev/null || true)"
        if [[ -n "$sig" ]]; then
            DB_CACHE_SIG["$sig"]=1
            DB_CACHE_SIG_STATUS["$sig"]="$status"
        fi
    fi

    DB_CACHE_META["$abs"]="$size|$mtime"
    DB_CACHE_STATUS["$abs"]="$status"
    DB_CACHE_ROW_EXISTS["$abs"]=1

    if (( existing_row == 1 )); then
        ((++DB_ROWS_UPDATED))
        DB_MARK_CHECKED_RESULT="updated"
    else
        ((++DB_ROWS_NEW))
        DB_MARK_CHECKED_RESULT="inserted"
    fi

    if [[ -n "$sig" ]]; then
        sig_sql="'$(sql_escape "$sig")'"
    else
        sig_sql="NULL"
    fi

    sql="INSERT INTO checked_paths(path, kind, size, mtime, status, last_checked, signature) VALUES ('$(sql_escape "$abs")', '$(sql_escape "$kind")', $size, $mtime, '$(sql_escape "$status")', CURRENT_TIMESTAMP, $sig_sql) ON CONFLICT(path) DO UPDATE SET kind=excluded.kind, size=excluded.size, mtime=excluded.mtime, status=excluded.status, signature=excluded.signature, last_checked=CURRENT_TIMESTAMP, file_hash_kind=COALESCE(file_hash_kind, excluded.file_hash_kind), file_hash=COALESCE(file_hash, excluded.file_hash);"
    printf '%s\n' "$sql" >> "$DB_PENDING_SQL_FILE"
    (( ++DB_PENDING_COUNT ))
    if (( DB_PENDING_COUNT >= DB_FLUSH_EVERY )); then
        db_flush_pending
    fi
}

db_mark_many_checked() {
    local kind="$1"
    local status="$2"
    shift 2
    local path
    for path in "$@"; do
        db_mark_checked "$path" "$kind" "$status"
    done
}

db_rewrite_subtree() {
    local old_path="$1"
    local new_path="$2"
    local old_abs new_abs old_prefix new_prefix old_db_path new_db_path suffix sql
    local old_esc new_esc
    local rewritten_count=0
    local -a matched_paths=()

    (( USE_DB == 1 )) || return 0
    [[ -e "$new_path" ]] || return 0

    old_abs="$(db_abs_path_if_deleted "$old_path" 2>/dev/null || true)"
    new_abs="$(db_abs_path "$new_path" 2>/dev/null || true)"
    [[ -n "$old_abs" && -n "$new_abs" ]] || return 0

    old_prefix="${old_abs%/}/"
    new_prefix="${new_abs%/}/"

    old_esc="$(sql_escape "$old_abs")"
    new_esc="$(sql_escape "$new_abs")"
    # Rewrite every cached row under this directory prefix in SQLite (warm cache may omit most paths).
    sql="UPDATE checked_paths SET path = CASE WHEN path='${old_esc}' THEN '${new_esc}' ELSE '${new_esc}' || SUBSTR(path, LENGTH('${old_esc}') + 1) END WHERE path='${old_esc}' OR SUBSTR(path, 1, LENGTH('${old_esc}') + 1) = '${old_esc}' || '/';"
    printf '%s\n' "$sql" >> "$DB_PENDING_SQL_FILE"
    (( ++DB_PENDING_COUNT ))
    if (( DB_PENDING_COUNT >= DB_FLUSH_EVERY )); then
        db_flush_pending
    fi

    for old_db_path in "${!DB_CACHE_META[@]}"; do
        if [[ "$old_db_path" == "$old_abs" || "$old_db_path" == "$old_prefix"* ]]; then
            matched_paths+=( "$old_db_path" )
        fi
    done

    for old_db_path in "${matched_paths[@]}"; do
        if [[ "$old_db_path" == "$old_abs" ]]; then
            new_db_path="$new_abs"
        else
            suffix="${old_db_path#"$old_prefix"}"
            new_db_path="${new_prefix}${suffix}"
        fi

        DB_CACHE_META["$new_db_path"]="${DB_CACHE_META[$old_db_path]}"
        unset 'DB_CACHE_META[$old_db_path]'
        if [[ -n "${DB_CACHE_STATUS[$old_db_path]-}" ]]; then
            DB_CACHE_STATUS["$new_db_path"]="${DB_CACHE_STATUS[$old_db_path]}"
            unset 'DB_CACHE_STATUS[$old_db_path]'
        fi
        if [[ -n "${DB_CACHE_HASH_MD5[$old_db_path]-}" ]]; then
            DB_CACHE_HASH_MD5["$new_db_path"]="${DB_CACHE_HASH_MD5[$old_db_path]}"
            unset 'DB_CACHE_HASH_MD5[$old_db_path]'
        fi
        if [[ -n "${DB_CACHE_HASH_SHA512[$old_db_path]-}" ]]; then
            DB_CACHE_HASH_SHA512["$new_db_path"]="${DB_CACHE_HASH_SHA512[$old_db_path]}"
            unset 'DB_CACHE_HASH_SHA512[$old_db_path]'
        fi
        if [[ -n "${DB_CACHE_ROW_EXISTS[$old_db_path]-}" ]]; then
            DB_CACHE_ROW_EXISTS["$new_db_path"]=1
            unset 'DB_CACHE_ROW_EXISTS[$old_db_path]'
        fi
        (( ++rewritten_count ))
    done

    if (( rewritten_count == 0 )); then
        vlog "DB subtree rewrite: SQLite prefix '${old_abs}' -> '${new_abs}' (no in-memory cache keys to relabel)"
    else
        vlog "DB subtree rewrite: SQLite prefix '${old_abs}' -> '${new_abs}' (${rewritten_count} in-memory cache key(s) relabeled)"
    fi
}

db_rewrite_single_path() {
    local old_path="$1"
    local new_path="$2"
    local old_abs new_abs sql

    (( USE_DB == 1 )) || return 0

    old_abs="$(db_abs_path_if_deleted "$old_path" 2>/dev/null || true)"
    new_abs="$(db_abs_path "$new_path" 2>/dev/null || true)"
    [[ -n "$old_abs" && -n "$new_abs" ]] || return 0

    sql="INSERT INTO checked_paths(path, kind, size, mtime, status, last_checked, signature, file_hash_kind, file_hash, file_md5, file_sha512) SELECT '$(sql_escape "$new_abs")', kind, size, mtime, status, CURRENT_TIMESTAMP, signature, file_hash_kind, file_hash, file_md5, file_sha512 FROM checked_paths WHERE path='$(sql_escape "$old_abs")' ON CONFLICT(path) DO UPDATE SET kind=excluded.kind, size=excluded.size, mtime=excluded.mtime, status=excluded.status, signature=excluded.signature, last_checked=excluded.last_checked, file_hash_kind=COALESCE(excluded.file_hash_kind, checked_paths.file_hash_kind), file_hash=COALESCE(excluded.file_hash, checked_paths.file_hash), file_md5=COALESCE(excluded.file_md5, checked_paths.file_md5), file_sha512=COALESCE(excluded.file_sha512, checked_paths.file_sha512); DELETE FROM checked_paths WHERE path='$(sql_escape "$old_abs")';"
    printf '%s\n' "$sql" >> "$DB_PENDING_SQL_FILE"
    (( ++DB_PENDING_COUNT ))
    if (( DB_PENDING_COUNT >= DB_FLUSH_EVERY )); then
        db_flush_pending
    fi

    # Best-effort cache move for already loaded metadata/status
    if [[ -n "${DB_CACHE_META[$old_abs]-}" ]]; then
        DB_CACHE_META["$new_abs"]="${DB_CACHE_META[$old_abs]}"
        unset 'DB_CACHE_META[$old_abs]'
        ((++DB_ROWS_UPDATED))
    fi
    if [[ -n "${DB_CACHE_STATUS[$old_abs]-}" ]]; then
        DB_CACHE_STATUS["$new_abs"]="${DB_CACHE_STATUS[$old_abs]}"
        unset 'DB_CACHE_STATUS[$old_abs]'
    fi
    if [[ -n "${DB_CACHE_HASH_MD5[$old_abs]-}" ]]; then
        DB_CACHE_HASH_MD5["$new_abs"]="${DB_CACHE_HASH_MD5[$old_abs]}"
        unset 'DB_CACHE_HASH_MD5[$old_abs]'
    fi
    if [[ -n "${DB_CACHE_HASH_SHA512[$old_abs]-}" ]]; then
        DB_CACHE_HASH_SHA512["$new_abs"]="${DB_CACHE_HASH_SHA512[$old_abs]}"
        unset 'DB_CACHE_HASH_SHA512[$old_abs]'
    fi
    if [[ -n "${DB_CACHE_ROW_EXISTS[$old_abs]-}" ]]; then
        DB_CACHE_ROW_EXISTS["$new_abs"]=1
        unset 'DB_CACHE_ROW_EXISTS[$old_abs]'
    fi
}

db_mark_renamed_path_checked() {
    local path="$1"
    local kind="$2"
    (( USE_DB == 1 )) || return 0
    [[ -e "$path" ]] || return 0
    db_mark_checked "$path" "$kind" "checked"
}

checksum_file_has_renamable_refs() {
    local sum_file="$1"
    local ref_hash ref_raw resolved_ref transformed_ref
    # Caller disables ERR trap around this call: with set -E, Bash may invoke ERR on `return 1`
    # ("no renamable refs") even though that status is normal.
    set +e

    [[ -f "$sum_file" ]] || return 1
    is_checksum_file "$sum_file" || return 1

    while IFS=$'\t' read -r ref_hash ref_raw; do
        [[ -n "$ref_raw" ]] || continue
        resolved_ref="$(resolve_checksum_ref_path "$sum_file" "$ref_raw")"
        transformed_ref="$(transform_name "$resolved_ref")"
        tnr_rc=$?
        transformed_ref="$(collapse_stacked_other_suffix_in_path "$transformed_ref")"
        if (( tnr_rc == 2 )); then
            return 2
        fi
        if [[ "$resolved_ref" != "$transformed_ref" ]]; then
            return 0
        fi
    done < <(extract_checksum_entries "$sum_file")

    return 1
}

print_checksum_sibling_notice_verbose() {
    (( VERBOSE == 1 )) || return 0
    local file_path="$1"
    local sha_path="$2"
    local md5_path="$3"
    local has_any=0
    local line="[VERBOSE] Renaming '$file_path' now (checksum sibling(s) exist):"

    if (( ${#line} <= MAX_LINE_LENGTH )); then
        echo "$line" >&2
    else
        echo "[VERBOSE] Renaming '$file_path'" >&2
        echo "          now (checksum sibling(s) exist):" >&2
    fi
    if [[ -e "$sha_path" ]]; then
        echo "          sha512: '$sha_path'" >&2
        has_any=1
    fi
    if [[ -e "$md5_path" ]]; then
        echo "          md5:    '$md5_path'" >&2
        has_any=1
    fi
    if (( has_any == 1 )); then
        echo "          local checksum references will be updated during this rename." >&2
    fi
}

while (( $# > 0 )); do
    #region agent log
    debug_log "H4" "rename.sh:arg_parse" "Parsing CLI argument token" "{\"token\":\"$1\",\"remaining\":$#}"
    #endregion
    case "$1" in
        --version)
            print_version_banner
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        --use-db)
            USE_DB=1
            shift
            ;;
        --force-recheck)
            FORCE_RECHECK=1
            shift
            ;;
        --fast)
            FAST_DB=1
            shift
            ;;
        --run-db-maintenance)
            RUN_DB_MAINTENANCE=1
            USE_DB=1
            shift
            ;;
        --db-maintenance)
            [[ $# -ge 2 ]] || { echo "Missing value for --db-maintenance" >&2; usage >&2; exit 1; }
            case "$2" in
                auto|full) CLI_DB_MAINTENANCE="$2" ;;
                *) echo "Invalid value for --db-maintenance: $2 (use auto or full)" >&2; usage >&2; exit 1 ;;
            esac
            USE_DB=1
            RUN_DB_MAINTENANCE=1
            shift 2
            ;;
        --colors)
            [[ $# -ge 2 ]] || { echo "Missing value for --colors" >&2; usage >&2; exit 1; }
            case "$2" in
                yes|no) CLI_COLORS="$2" ;;
                *) echo "Invalid value for --colors: $2 (use yes or no)" >&2; usage >&2; exit 1 ;;
            esac
            shift 2
            ;;
        --mode)
            [[ $# -ge 2 ]] || { echo "Missing value for --mode" >&2; usage >&2; exit 1; }
            case "$2" in
                dry-run|real) CLI_MODE="$2" ;;
                *) echo "Invalid value for --mode: $2 (use real or dry-run)" >&2; usage >&2; exit 1 ;;
            esac
            shift 2
            ;;
        --scope)
            [[ $# -ge 2 ]] || { echo "Missing value for --scope" >&2; usage >&2; exit 1; }
            case "$2" in
                current|subdirs) CLI_SCOPE="$2" ;;
                *) echo "Invalid value for --scope: $2 (use subdirs or current)" >&2; usage >&2; exit 1 ;;
            esac
            shift 2
            ;;
        --resume-state)
            [[ $# -ge 2 ]] || { echo "Missing value for --resume-state" >&2; usage >&2; exit 1; }
            case "$2" in
                fresh|ask|resume) CLI_RESUME_STATE="$2" ;;
                *) echo "Invalid value for --resume-state: $2 (use fresh, ask, or resume)" >&2; usage >&2; exit 1 ;;
            esac
            shift 2
            ;;
        --date-placement)
            [[ $# -ge 2 ]] || { echo "Missing value for --date-placement" >&2; usage >&2; exit 1; }
            case "$2" in
                front|original) CLI_DATE_PLACEMENT="$2" ;;
                *) echo "Invalid value for --date-placement: $2 (use front or original)" >&2; usage >&2; exit 1 ;;
            esac
            shift 2
            ;;
        --wait-seconds)
            [[ $# -ge 2 ]] || { echo "Missing value for --wait-seconds" >&2; usage >&2; exit 1; }
            [[ "$2" =~ ^[0-9]+$ ]] || { echo "Invalid value for --wait-seconds: $2 (use 0 or a positive integer)" >&2; usage >&2; exit 1; }
            PROMPT_WAIT_SECONDS="$2"
            shift 2
            ;;
        -h|--help)
            #region agent log
            debug_log "H2" "rename.sh:arg_parse_help" "Help option selected; will print banner and usage" "{\"token\":\"$1\"}"
            #endregion
            print_startup_banner
            echo
            usage
            prompt_show_usage_environment_tunables
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

rename_sh_window_title_apply_from_saved_argv

if [[ -n "$CLI_DATE_PLACEMENT" ]]; then
    DATE_PLACEMENT="$CLI_DATE_PLACEMENT"
fi
case "$DATE_PLACEMENT" in
    front|original) ;;
    *)
        echo "Invalid DATE_PLACEMENT: $DATE_PLACEMENT (use front or original)" >&2
        exit 1
        ;;
esac

print_startup_banner

prompt_use_existing_sqlite_cache_if_present

if (( RUN_DB_MAINTENANCE == 0 )); then
    prompt_resume_choice_early
fi

startup_progress "Scanning startup directory: $START_DIR"
startup_progress "Loading exclude filters from: $EXCLUDE_FILTERS_FILE"
load_exclude_filters
startup_progress "Exclude filters loaded: ${#EXCLUDE_FILTERS[@]}"
if (( USE_DB == 1 )); then
    if (( RUN_DB_MAINTENANCE == 1 )); then
        startup_progress "Preparing SQLite maintenance support..."
        db_require_sqlite
        db_migrate_legacy_file
        if [[ ! -f "$DB_FILE" ]]; then
            echo "SQLite maintenance skipped: DB file not found: $DB_FILE"
            exit 0
        fi
        trap on_interrupt_db_maintenance INT
        startup_progress "Running manual SQLite maintenance profile: $CLI_DB_MAINTENANCE"
        db_run_maintenance "$CLI_DB_MAINTENANCE"
        db_flush_pending || true
        print_db_maintenance_summary
        exit 0
    fi

    startup_progress "Initializing SQLite support..."
    db_init
fi
startup_progress "Startup preparation finished"
startup_progress "Interactive prompt wait: $(print_prompt_wait_description)"


if (( USE_DB == 1 )); then
    echo
    echo "SQLite cache enabled: $DB_FILE"
    if (( FAST_DB == 1 )); then
        echo "SQLite cache mode: FAST (path-only skips; size/mtime checks disabled)"
    else
        echo "SQLite cache mode: SAFE (path + size + mtime must still match)"
    fi
    if (( FORCE_RECHECK == 1 )); then
        echo "SQLite cache mode override: force recheck enabled"
    fi
    case "$CLI_DB_MAINTENANCE" in
        auto) echo "SQLite maintenance profile: AUTO (optimize/checkpoint + prune + hash backfill) [only shown during interactive runs; maintenance via --db-maintenance or --run-db-maintenance]" ;;
        full) echo "SQLite maintenance profile: FULL (optimize + analyze + reindex + WAL truncate + prune + hash backfill) [only shown during interactive runs; maintenance via --db-maintenance or --run-db-maintenance]" ;;
    esac
fi

if [[ -f "$EXCLUDE_FILTERS_FILE" ]]; then
    echo
    echo "Exclude filter file detected: $EXCLUDE_FILTERS_FILE"
    echo "Loaded filters: ${#EXCLUDE_FILTERS[@]} (FILE= lines match basename in any directory)"
fi

use_colors=yes
input=""

if [[ -n "$CLI_COLORS" ]]; then
    case "$CLI_COLORS" in
        yes) use_colors=yes ;;
        no)  use_colors=no ;;
    esac
else
    echo
    verbose_question_timestamp "Use colors?"
    echo "  [Y] Yes (default)"
    echo "  [N] No"
    echo "  [Q] Quit"
    echo -n "$(user_prompt_ts_prefix)Choice [Y/n/q]: "

    flush_stdin
    read_single_key input "$PROMPT_WAIT_SECONDS"
    echo

    if [[ "$input" =~ [Qq] ]]; then
        echo "Quitting."
        exit 0
    elif [[ "$input" =~ [Nn] ]]; then
        use_colors=no
    fi
fi

if [[ "$use_colors" == "yes" ]]; then
    RED='\e[31m'
    GREEN='\e[32m'
    CYAN='\e[36m'
    YELLOW='\e[33m'
    BOLD='\e[1m'
    RESET='\e[0m'
else
    RED=''
    GREEN=''
    CYAN=''
    YELLOW=''
    BOLD=''
    RESET=''
fi

ARROW="→"

print_verbose_options_box() {
    (( VERBOSE == 1 )) || return 0

    local -a lines=()
    local box_width=0
    local line db_mode scope_text color_text prompt_text db_maintenance_text

    if (( USE_DB == 1 )); then
        if (( FAST_DB == 1 )); then
            db_mode="enabled, FAST - trust cached paths without current size/mtime checks"
        else
            db_mode="enabled, SAFE - require cached path, size, and mtime to still match"
        fi
        if (( FORCE_RECHECK == 1 )); then
            db_mode="${db_mode}; force recheck active"
        fi
        case "$CLI_DB_MAINTENANCE" in
            auto) db_maintenance_text="auto - optimize/checkpoint + prune missing paths + hash backfill (--db-maintenance / --run-db-maintenance)" ;;
            full) db_maintenance_text="full - optimize + analyze + reindex + WAL truncate + prune + hash backfill (--db-maintenance / --run-db-maintenance)" ;;
            *)    db_maintenance_text="$CLI_DB_MAINTENANCE" ;;
        esac
    else
        db_mode="disabled - always inspect files directly"
        db_maintenance_text="$CLI_DB_MAINTENANCE (available when --use-db is enabled)"
    fi

    if [[ "$use_colors" == "yes" ]]; then
        color_text="yes - colored output is enabled"
    else
        color_text="no - plain output without ANSI colors"
    fi

    if [[ "$process_scope" == "subdirs" ]]; then
        scope_text="subdirs - process the current directory and all subdirectories"
    else
        scope_text="current - immediate children only (find -maxdepth 1; does not descend into subfolders)"
    fi

    if (( PROMPT_WAIT_SECONDS == 0 )); then
        prompt_text="0 - wait forever for each interactive answer"
    else
        prompt_text="${PROMPT_WAIT_SECONDS} - timeout for each interactive answer in seconds"
    fi

    lines+=("Verbose        : on - print extra diagnostic information")
    lines+=("Colors         : ${color_text}")
    lines+=("Mode           : ${mode} - $( [[ "$mode" == "real" ]] && printf '%s' 'perform interactive real renames' || printf '%s' 'show planned changes only' )")
    lines+=("Scope          : ${scope_text}")
    lines+=("Date placement : ${DATE_PLACEMENT} - $( [[ "$DATE_PLACEMENT" == original ]] && printf '%s' 'BBC/iPlayer -date_ compact stamp stays in title' || printf '%s' 'BBC/iPlayer -date_ stamp moved to front' )")
    lines+=("SQLite cache   : ${db_mode}")
    lines+=("DB maintenance : ${db_maintenance_text}")
    lines+=("Resume state   : ${CLI_RESUME_STATE} - checkpoint behavior after Ctrl-C")
    lines+=("Prompt wait    : ${prompt_text}")
    lines+=("Start dir      : ${START_DIR} - root path used for this run")
    lines+=("Exclude file   : ${EXCLUDE_FILTERS_FILE} - local exception/filter definitions")

    for line in "${lines[@]}"; do
        (( ${#line} > box_width )) && box_width=${#line}
    done

    printf '┌%*s┐\n' $((box_width + 2)) '' | tr ' ' '─'
    printf '│ %-*s │\n' "$box_width" "Effective options (verbose mode)"
    printf '├%*s┤\n' $((box_width + 2)) '' | tr ' ' '─'
    for line in "${lines[@]}"; do
        printf '│ %-*s │\n' "$box_width" "$line"
    done
    printf '└%*s┘\n' $((box_width + 2)) '' | tr ' ' '─'
}

print_wrapped_two_path_verbose() {
    (( VERBOSE == 1 )) || return 0
    local prefix="$1"
    local first_path="$2"
    local suffix="$3"

    local line="${prefix}${first_path}${suffix}"
    local indent="          "

    if (( ${#line} <= MAX_LINE_LENGTH )); then
        echo "[VERBOSE] $line" >&2
    else
        echo "[VERBOSE] ${prefix}${first_path} " >&2
        echo "${indent}${suffix}" >&2
    fi
}

print_single_target_check_verbose() {
    (( VERBOSE == 1 )) || return 0
    local tool_name="$1"
    local sum_dir="$2"
    local target_ref="$3"
    local sum_base="$4"

    local line1="Running single-target ${tool_name} check in directory '${sum_dir}'"
    local line2="          for ref '${target_ref}' from file '${sum_base}'"

    if (( ${#line1} + 11 <= MAX_LINE_LENGTH )) && (( ${#line2} <= MAX_LINE_LENGTH )); then
        echo "[VERBOSE] ${line1}" >&2
        echo "${line2}" >&2
    else
        echo "[VERBOSE] ${line1}" >&2
        echo "          for ref '${target_ref}'" >&2
        echo "          from file '${sum_base}'" >&2
    fi
}

print_resolved_ref_verbose() {
    (( VERBOSE == 1 )) || return 0
    local ref="$1"
    local resolved="$2"

    local line="[VERBOSE] Resolved ref '${ref}' -> '${resolved}'"
    if (( ${#line} <= MAX_LINE_LENGTH )); then
        echo "$line" >&2
    else
        echo "[VERBOSE] Resolved ref '${ref}'" >&2
        echo "          -> '${resolved}'" >&2
    fi
}

print_same_inode_no_rename_verbose() {
    (( VERBOSE == 1 )) || return 0
    local src="$1"
    local dst="$2"
    local plain="[VERBOSE] Suggested target is the same inode as source (case-insensitive path spellings): '${src}' | '${dst}' — no rename."

    if (( ${#plain} <= MAX_LINE_LENGTH )); then
        echo -e "${CYAN}[VERBOSE]${RESET} Suggested target is the same inode as source (case-insensitive path spellings): '${src}' | '${dst}' — no rename." >&2
    else
        echo -e "${CYAN}[VERBOSE]${RESET} Suggested target is the same inode as source (case-insensitive path spellings) — no rename." >&2
        echo "${WRAP_MSG_INDENT}source: '${src}'" >&2
        echo "${WRAP_MSG_INDENT}target: '${dst}'" >&2
    fi
}

# Long checksum-file paths: split to two lines when plain length exceeds MAX_LINE_LENGTH (stdout, not stderr).
print_checksum_verify_progress_line() {
    local label="$1"
    local when="$2"
    local path="$3"
    local intro_plain

    if [[ "$when" == before ]]; then
        intro_plain="${label} check (before rename) in progress for reference(s)..."
    else
        intro_plain="${label} check (after rename) in progress for reference(s)..."
    fi
    emit_wrap_labeled_stdout "${intro_plain} " "${CYAN}${intro_plain}${RESET} " "$path"
    NONVERBOSE_CHECKSUM_LETTER_EVENT_N=0
    NONVERBOSE_CHECKSUM_PROGRESS_SOURCE=""
}

print_checksum_verified_refs_line() {
    local label="$1"
    local when="$2"
    local path="$3"

    if [[ "$when" == before ]]; then
        emit_wrap_labeled_stdout "${label} VERIFIED (before rename): reference(s) in " "${CYAN}${label} VERIFIED (before rename):${RESET} reference(s) in " "$path"
    else
        emit_wrap_labeled_stdout "${label} VERIFIED (after rename): reference(s) in " "${CYAN}${label} VERIFIED (after rename):${RESET} reference(s) in " "$path"
    fi
}

print_checksum_fail_no_matching_line() {
    local label="$1"
    local ref_raw="$2"
    local sum_file="$3"
    local tail="(won't rename pair)"

    emit_wrap_labeled_stdout "${label} FAIL: no checksum line matches reference '${ref_raw}' " "${YELLOW}${label} FAIL:${RESET} no checksum line matches reference '${ref_raw}' " "in '${sum_file}' ${tail}"
}

print_checksum_fail_mismatch_line() {
    local label="$1"
    local ref_raw="$2"
    local sum_file="$3"
    local tail="(won't rename pair)"

    emit_wrap_labeled_stdout "${label} FAIL: checksum mismatch for reference '${ref_raw}' " "${YELLOW}${label} FAIL:${RESET} checksum mismatch for reference '${ref_raw}' " "in '${sum_file}' ${tail}"
}

print_checksum_fail_after_no_line() {
    local label="$1"
    local new_ref="$2"
    local final_sum="$3"

    emit_wrap_labeled_stdout "${label} FAIL (after rename): no line for '${new_ref}' " "${YELLOW}${label} FAIL (after rename):${RESET} no line for '${new_ref}' " "in '${final_sum}'."
}

print_checksum_fail_after_validate_line() {
    local label="$1"
    local new_ref="$2"
    local final_sum="$3"

    emit_wrap_labeled_stdout "${label} FAIL (after rename): reference '${new_ref}' " "${YELLOW}${label} FAIL (after rename):${RESET} reference '${new_ref}' " "in '${final_sum}' does not validate."
}

print_checksum_group_ok_line() {
    local label="$1"
    local final_sum="$2"
    local llower="${label,,}"

    emit_wrap_labeled_stdout "${label} OK: changed reference(s) were updated inside " "${GREEN}${label} OK:${RESET} changed reference(s) were updated inside " "'${final_sum}' and ${llower} checksum(s) are correct."
    nonverbose_skip_next_main_loop_dot_after_stdout_status
}

print_checksum_update_verbose() {
    (( VERBOSE == 1 )) || return 0

    if (( $# == 3 )); then
        local sum_file="$1"
        local old_name="$2"
        local new_name="$3"
        local line1="[VERBOSE] Updating checksum content in '${sum_file}': '${old_name}'"
        local line2="          -> '${new_name}'"

        if (( ${#line1} <= MAX_LINE_LENGTH )) && (( ${#line2} <= MAX_LINE_LENGTH )); then
            echo "$line1" >&2
            echo "$line2" >&2
        else
            echo "[VERBOSE] Updating checksum content in '${sum_file}':" >&2
            echo "          '${old_name}'" >&2
            echo "$line2" >&2
        fi
        return 0
    fi

    local first_part="$1"
    local second_part="$2"
    local line="[VERBOSE] ${first_part}${second_part}"

    if (( ${#line} <= MAX_LINE_LENGTH )); then
        echo "$line" >&2
    else
        echo "[VERBOSE] ${first_part}" >&2
        echo "          ${second_part}" >&2
    fi
}

print_checksum_file_rename_verbose() {
    (( VERBOSE == 1 )) || return 0
    local old_sum="$1"
    local new_sum="$2"
    local line="[VERBOSE] Renaming checksum file '${old_sum}' -> '${new_sum}'"

    if (( ${#line} <= MAX_LINE_LENGTH )); then
        echo "$line" >&2
    else
        echo "[VERBOSE] Renaming checksum file '${old_sum}'" >&2
        echo "          -> '${new_sum}'" >&2
    fi
}




print_protected_checksum_verbose() {
    (( VERBOSE == 1 )) || return 0
    local sum_file="$1"
    local line1="Protected checksum manifest (_sumy_kontrolne.md5) — keeping filename unchanged:"
    local line2="          '${sum_file}'"

    if (( ${#line1} + 11 <= MAX_LINE_LENGTH )) && (( ${#line2} <= MAX_LINE_LENGTH )); then
        echo "[VERBOSE] ${line1}" >&2
        echo "${line2}" >&2
    else
        echo "[VERBOSE] ${line1}" >&2
        echo "${line2}" >&2
    fi
}

print_checksum_no_action_verbose() {
    (( VERBOSE == 1 )) || return 0
    local sum_file="$1"
    local fs_skipped="${2-no}"
    local msg="All referenced files exist and no rename/update is needed for '${sum_file}' - skipping without checksum verification"
    [[ "$fs_skipped" == yes ]] && msg+=" (no case-only rename on exfat/CIFS/Samba where applicable)"
    local plain="[VERBOSE] ${msg}"
    if (( ${#plain} <= MAX_LINE_LENGTH )); then
        echo -e "${CYAN}[VERBOSE]${RESET} ${msg}" >&2
    else
        echo -e "${CYAN}[VERBOSE]${RESET}" >&2
        printf '%s%s\n' "$WRAP_MSG_INDENT" "$msg" >&2
    fi
}

print_try_recover_missing_ref_verbose() {
    (( VERBOSE == 1 )) || return 0
    local missing_ref="$1"
    local expected_hash="$2"

    local line1="Trying to recover missing ref '${missing_ref}'"
    local line2="          (expected hash: ${expected_hash:-none})"

    if (( ${#line1} + 11 <= MAX_LINE_LENGTH )) && (( ${#line2} <= MAX_LINE_LENGTH )); then
        echo "[VERBOSE] ${line1}" >&2
        echo "${line2}" >&2
    else
        echo "[VERBOSE] ${line1}" >&2
        echo "${line2}" >&2
    fi
}

print_recovery_success_verbose() {
    (( VERBOSE == 1 )) || return 0
    local old_ref="$1"
    local found_ref="$2"
    local write_ref="$3"

    local line1="[VERBOSE] Recovery success: '${old_ref}' -> '${found_ref}'"
    local line2="          (write as '${write_ref}')"

    if (( ${#line1} <= MAX_LINE_LENGTH )) && (( ${#line2} <= MAX_LINE_LENGTH )); then
        echo "$line1" >&2
        echo "$line2" >&2
    else
        echo "$line1" >&2
        echo "$line2" >&2
    fi
}

print_scan_by_checksum_verbose() {
    (( VERBOSE == 1 )) || return 0
    local search_root="$1"
    local expected_hash="$2"

    local line1="[VERBOSE] Name-based subtree recovery failed under '${search_root}'"
    local line2="          scanning all files below by checksum (expected hash: ${expected_hash})"

    if (( ${#line1} <= MAX_LINE_LENGTH )) && (( ${#line2} <= MAX_LINE_LENGTH )); then
        echo "$line1" >&2
        echo "$line2" >&2
    else
        echo "$line1" >&2
        echo "$line2" >&2
    fi
}


print_recovery_final_status_verbose() {
    (( VERBOSE == 1 )) || return 0
    local missing_ref="$1"
    local status="$2"
    local line=""

    if [[ "$status" == "success" ]]; then
        line="[VERBOSE] Recovery FINAL STATUS: SUCCESS for '${missing_ref}'"
        if (( ${#line} <= MAX_LINE_LENGTH )); then
            echo "$line" >&2
        else
            echo "[VERBOSE] Recovery FINAL STATUS: SUCCESS" >&2
            echo "          for '${missing_ref}'" >&2
        fi
    else
        line="[VERBOSE] Recovery FINAL STATUS: FAILED for '${missing_ref}'"
        if (( ${#line} <= MAX_LINE_LENGTH )); then
            echo "$line" >&2
        else
            echo "[VERBOSE] Recovery FINAL STATUS: FAILED" >&2
            echo "          for '${missing_ref}'" >&2
        fi
    fi
}

# head_msg is the text after "[VERBOSE] " and before ": 'path'..." (same wording as one-line messages).
print_db_hash_record_verbose_wrapped() {
    local head_msg="$1"
    local path="$2"
    local hash_kind="$3"
    local full_line="[VERBOSE] ${head_msg}: '${path}' (${hash_kind})"
    local tail_quoted_kind="'${path}' (${hash_kind})"

    if (( ${#full_line} <= MAX_LINE_LENGTH )); then
        echo "$full_line" >&2
        return 0
    fi
    echo "[VERBOSE] ${head_msg}:" >&2
    if (( ${#tail_quoted_kind} <= MAX_LINE_LENGTH )); then
        echo "          ${tail_quoted_kind}" >&2
    else
        echo "          '${path}'" >&2
        echo "          (${hash_kind})" >&2
    fi
}

print_db_hash_record_verbose() {
    (( VERBOSE == 1 )) || return 0
    local path="$1"
    local hash_kind="$2"
    local status="$3"

    case "$status" in
        new)
            print_db_hash_record_verbose_wrapped "DB hash stored for NEW file entry" "$path" "$hash_kind"
            ;;
        added_missing)
            print_db_hash_record_verbose_wrapped "DB hash added for EXISTING file entry (missing before)" "$path" "$hash_kind"
            ;;
        unchanged)
            print_db_hash_record_verbose_wrapped "DB hash verified for EXISTING file entry (already present)" "$path" "$hash_kind"
            ;;
        updated)
            print_db_hash_record_verbose_wrapped "DB hash updated for EXISTING file entry" "$path" "$hash_kind"
            ;;
        kept_existing)
            print_db_hash_record_verbose_wrapped "DB hash kept for EXISTING file entry (user chose not to replace)" "$path" "$hash_kind"
            ;;
        *)
            print_db_hash_record_verbose_wrapped "DB hash recorded for file entry" "$path" "$hash_kind"
            ;;
    esac
}

print_db_hash_lookup_verbose() {
    (( VERBOSE == 1 )) || return 0
    local status="$1"
    local search_root="$2"
    local hash_kind="$3"
    local expected_hash="$4"
    local found_path="${5-}"
    local line=""

    if [[ "$status" == "hit" ]]; then
        line="[VERBOSE] DB hash lookup HIT under '${search_root}' for ${hash_kind}=${expected_hash}"
        if (( ${#line} <= MAX_LINE_LENGTH )); then
            echo "$line" >&2
        else
            echo "[VERBOSE] DB hash lookup HIT under '${search_root}'" >&2
            echo "          for ${hash_kind}=${expected_hash}" >&2
        fi
        echo "          matched path: '${found_path}'" >&2
    else
        line="[VERBOSE] DB hash lookup MISS under '${search_root}' for ${hash_kind}=${expected_hash}"
        if (( ${#line} <= MAX_LINE_LENGTH )); then
            echo "$line" >&2
        else
            echo "[VERBOSE] DB hash lookup MISS under '${search_root}'" >&2
            echo "          for ${hash_kind}=${expected_hash}" >&2
        fi
    fi
}


path_has_control_chars() {
    local s="$1"
    [[ "$s" == *$'\n'* || "$s" == *$'\r'* || "$s" == *$'\t'* ]] && return 0
    LC_ALL=C printf '%s' "$s" | grep -q '[[:cntrl:]]'
}

format_path_for_log() {
    local s="$1"
    s=${s//$'\\'/\\\\}
    s=${s//$'\n'/\\n}
    s=${s//$'\r'/\\r}
    s=${s//$'\t'/\\t}
    printf '%s' "$s"
}

sanitize_basename_control_chars() {
    local s="$1"
    printf '%s' "$s" | LC_ALL=C tr -d '\000-\037\177'
}

print_control_char_warning() {
    local path="$1"
    local shown
    shown="$(format_path_for_log "$path")"
    emit_wrap_labeled_stdout "WARNING: path contains control character(s): '" "${YELLOW}WARNING:${RESET} path contains control character(s): '" "${shown}'"
}

print_skip_path_reason() {
    (( VERBOSE == 1 )) || return 0
    local path="$1"
    local reason="$2"
    local shown
    shown="$(format_path_for_log "$path")"
    local line="SKIP: '$shown' $reason"

    if path_has_control_chars "$path"; then
        print_control_char_warning "$path"
    fi

    if (( ${#line} <= MAX_LINE_LENGTH )); then
        echo -e "${YELLOW}SKIP:${RESET} '$shown' $reason"
    else
        echo -e "${YELLOW}SKIP:${RESET} '$shown'"
        echo "${WRAP_MSG_INDENT}$reason"
    fi
}

# Colored [VERBOSE] prefix; many older call sites still use plain "echo '[VERBOSE] ...'" (e.g. wrapped SQLite/checksum lines).
vlog() {
    (( VERBOSE == 1 )) || return 0
    local msg="$*"
    local plain="[VERBOSE] ${msg}"
    local wrap_w=$(( MAX_LINE_LENGTH - ${#WRAP_MSG_INDENT} ))
    (( wrap_w > VERBOSE_LOG_BODY_WRAP_WIDTH )) && wrap_w=$VERBOSE_LOG_BODY_WRAP_WIDTH
    (( wrap_w < 48 )) && wrap_w=48

    if (( ${#plain} <= MAX_LINE_LENGTH )); then
        echo -e "${CYAN}[VERBOSE]${RESET} ${msg}" >&2
        return 0
    fi

    echo -e "${CYAN}[VERBOSE]${RESET}" >&2
    printf '%s\n' "$msg" | fold -s -w "$wrap_w" | sed "s/^/${WRAP_MSG_INDENT}/" >&2
}

# stderr; indent + single-quoted path. Wraps at '/' when possible so spaces inside a directory name stay on one line;
# if a segment between slashes is wider than the line budget, falls back to fold -s for that segment only.
verbose_emit_single_quoted_path_fold_slash() {
    local max_line="$1"
    local indent="$2"
    local path="$3"
    local shown full
    shown="$(format_path_for_log "$path")"
    full="'${shown}'"
    if (( ${#indent} + ${#full} <= max_line )); then
        printf '%s%s\n' "$indent" "$full" >&2
        return 0
    fi

    local remaining="$shown"
    local first_phys=1
    while [[ -n "$remaining" ]]; do
        local prefix avail chunk head folded

        if (( first_phys )); then
            prefix="${indent}'"
            first_phys=0
        else
            prefix="$indent"
        fi

        if (( ${#prefix} + ${#remaining} + 1 <= max_line )); then
            printf "%s%s'\n" "$prefix" "$remaining" >&2
            return 0
        fi

        avail=$(( max_line - ${#prefix} ))
        (( avail < 1 )) && avail=1

        if (( ${#remaining} <= avail )); then
            printf "%s%s'\n" "$prefix" "$remaining" >&2
            return 0
        fi

        head="${remaining:0:avail}"
        if [[ "$head" == */* ]]; then
            chunk="${head%/*}/"
        else
            folded="$(printf '%s\n' "$remaining" | fold -s -w "$avail" | head -n1)"
            chunk="${folded//$'\n'/}"
            if [[ -z "$chunk" ]]; then
                chunk="${remaining:0:avail}"
            fi
        fi
        if [[ -z "$chunk" ]]; then
            chunk="${remaining:0:avail}"
        fi

        printf '%s%s\n' "$prefix" "$chunk" >&2
        remaining="${remaining:${#chunk}}"
    done
}

# Long paths were one vlog() body → fold -s broke inside directory names (spaces). When the combined
# line is too long, print the pair header, each path (slash-aware wrap), then an optional trailing note.
vlog_nef_xmp_pair_no_rename_needed() {
    (( VERBOSE == 1 )) || return 0
    local note="${1-}"
    local p1="$2"
    local p2="$3"
    local s1 s2 comb plain hdr

    s1="$(format_path_for_log "$p1")"
    s2="$(format_path_for_log "$p2")"
    comb="No rename needed for NEF+XMP pair '${s1}' + '${s2}'${note}"
    plain="[VERBOSE] ${comb}"

    if (( ${#plain} <= MAX_LINE_LENGTH )); then
        echo -e "${CYAN}[VERBOSE]${RESET} ${comb}" >&2
        return 0
    fi

    hdr="No rename needed for NEF+XMP pair"
    plain="[VERBOSE] ${hdr}"
    if (( ${#plain} <= MAX_LINE_LENGTH )); then
        echo -e "${CYAN}[VERBOSE]${RESET} ${hdr}" >&2
    else
        echo -e "${CYAN}[VERBOSE]${RESET}" >&2
        printf '%s%s\n' "$WRAP_MSG_INDENT" "$hdr" >&2
    fi
    verbose_emit_single_quoted_path_fold_slash "$MAX_LINE_LENGTH" "$WRAP_MSG_INDENT" "$p1"
    verbose_emit_single_quoted_path_fold_slash "$MAX_LINE_LENGTH" "${WRAP_MSG_INDENT}+ " "$p2"
    if [[ -n "$note" ]]; then
        printf '%s%s\n' "$WRAP_MSG_INDENT" "${note# }" >&2
    fi
}

print_progress_box() {
    local progress="$1"
    local current="$2"
    local label1="Progress"
    local label2="Current"
    local label_width line1 line2 inner_width border_width border

    label_width=${#label1}
    (( ${#label2} > label_width )) && label_width=${#label2}

    printf -v line1 "%-*s | %s" "$label_width" "$label1" "$progress"
    printf -v line2 "%-*s | %s" "$label_width" "$label2" "$current"

    inner_width=${#line1}
    (( ${#line2} > inner_width )) && inner_width=${#line2}

    border_width=$((inner_width + 2))
    printf -v border '%*s' "$border_width" ''
    border=${border// /─}

    printf '┌%s┐
' "$border" >&2
    printf '│ %-*s │
' "$inner_width" "$line1" >&2
    printf '│ %-*s │
' "$inner_width" "$line2" >&2
    printf '└%s┘
' "$border" >&2
}

rollback_current_operation() {
    local idx old new

    (( CURRENT_OP_ACTIVE == 1 )) || return 0

    echo
    emit_wrap_labeled_stdout "INTERRUPT: Ctrl-C received. Reverting current " "${YELLOW}INTERRUPT:${RESET} Ctrl-C received. Reverting current " "${CURRENT_OP_LABEL,,} operation..."

    if [[ -n "$CURRENT_OP_CONTENT_FILE" && -n "$CURRENT_OP_CONTENT_BACKUP" && -e "$CURRENT_OP_CONTENT_BACKUP" ]]; then
        if [[ -e "$CURRENT_OP_CONTENT_FILE" ]]; then
            cp -p -- "$CURRENT_OP_CONTENT_BACKUP" "$CURRENT_OP_CONTENT_FILE"
            emit_wrap_labeled_stdout "ROLLBACK: restored content of: " "${CYAN}ROLLBACK:${RESET} restored content of: " "$CURRENT_OP_CONTENT_FILE"
        elif [[ "$CURRENT_OP_SUM_RENAMED" -eq 1 && -e "$CURRENT_OP_SUM_NEW" ]]; then
            cp -p -- "$CURRENT_OP_CONTENT_BACKUP" "$CURRENT_OP_SUM_NEW"
            emit_wrap_labeled_stdout "ROLLBACK: restored content of: " "${CYAN}ROLLBACK:${RESET} restored content of: " "$CURRENT_OP_SUM_NEW"
        fi
    fi

    if [[ "$CURRENT_OP_SUM_RENAMED" -eq 1 && -e "$CURRENT_OP_SUM_NEW" ]]; then
        mv -f -- "$CURRENT_OP_SUM_NEW" "$CURRENT_OP_SUM_OLD"
        emit_wrap_labeled_stdout "ROLLBACK: ${CURRENT_OP_LABEL} file renamed back: " "${CYAN}ROLLBACK:${RESET} ${CURRENT_OP_LABEL} file renamed back: " "${CURRENT_OP_SUM_NEW} -> ${CURRENT_OP_SUM_OLD}"
    fi

    for (( idx=${#CURRENT_OP_FILE_OLDS[@]}-1; idx>=0; idx-- )); do
        old="${CURRENT_OP_FILE_OLDS[$idx]}"
        new="${CURRENT_OP_FILE_NEWS[$idx]}"
        if [[ -e "$new" ]]; then
            mv -f -- "$new" "$old"
            emit_wrap_labeled_stdout "ROLLBACK: referenced file renamed back: " "${CYAN}ROLLBACK:${RESET} referenced file renamed back: " "${new} -> ${old}"
        fi
    done

    if [[ -n "$CURRENT_OP_CONTENT_BACKUP" && -e "$CURRENT_OP_CONTENT_BACKUP" ]]; then
        rm -f -- "$CURRENT_OP_CONTENT_BACKUP"
    fi

    CURRENT_OP_ACTIVE=0
    CURRENT_OP_LABEL=""
    CURRENT_OP_SUM_OLD=""
    CURRENT_OP_SUM_NEW=""
    CURRENT_OP_SUM_RENAMED=0
    CURRENT_OP_CONTENT_FILE=""
    CURRENT_OP_CONTENT_BACKUP=""
    CURRENT_OP_FILE_OLDS=()
    CURRENT_OP_FILE_NEWS=()

    echo -e "${GREEN}ROLLBACK DONE.${RESET}"
}

begin_current_operation() {
    local label="$1"
    local sum_old="$2"
    local sum_new="$3"

    CURRENT_OP_ACTIVE=1
    CURRENT_OP_LABEL="$label"
    CURRENT_OP_SUM_OLD="$sum_old"
    CURRENT_OP_SUM_NEW="$sum_new"
    CURRENT_OP_SUM_RENAMED=0
    CURRENT_OP_CONTENT_FILE="$sum_old"
    CURRENT_OP_CONTENT_BACKUP="$(mktemp)"
    cp -p -- "$sum_old" "$CURRENT_OP_CONTENT_BACKUP"
    CURRENT_OP_FILE_OLDS=()
    CURRENT_OP_FILE_NEWS=()
}

register_current_file_rename() {
    local old="$1"
    local new="$2"
    CURRENT_OP_FILE_OLDS+=( "$old" )
    CURRENT_OP_FILE_NEWS+=( "$new" )
}

mark_current_sum_renamed() {
    CURRENT_OP_SUM_RENAMED=1
    CURRENT_OP_CONTENT_FILE="$CURRENT_OP_SUM_NEW"
}

finish_current_operation() {
    if [[ -n "$CURRENT_OP_CONTENT_BACKUP" && -e "$CURRENT_OP_CONTENT_BACKUP" ]]; then
        rm -f -- "$CURRENT_OP_CONTENT_BACKUP"
    fi

    CURRENT_OP_ACTIVE=0
    CURRENT_OP_LABEL=""
    CURRENT_OP_SUM_OLD=""
    CURRENT_OP_SUM_NEW=""
    CURRENT_OP_SUM_RENAMED=0
    CURRENT_OP_CONTENT_FILE=""
    CURRENT_OP_CONTENT_BACKUP=""
    CURRENT_OP_FILE_OLDS=()
    CURRENT_OP_FILE_NEWS=()
}

mode="real"
input=""

if [[ -n "$CLI_MODE" ]]; then
    mode="$CLI_MODE"
else
    echo
    verbose_question_timestamp "Select mode:"
    echo "  [R] Real rename (default)"
    echo "  [D] Dry-run"
    echo "  [Q] Quit"
    echo -n "$(user_prompt_ts_prefix)Choice [R/d/q]: "

    flush_stdin
    read_single_key input "$PROMPT_WAIT_SECONDS"
    echo

    if [[ "$input" =~ [Qq] ]]; then
        echo "Quitting."
        exit 0
    elif [[ "$input" =~ [Dd] ]]; then
        mode="dry-run"
    fi
fi

echo -e "Mode selected: ${CYAN}$mode${RESET}"

process_scope="subdirs"
input=""

if [[ -n "$CLI_SCOPE" ]]; then
    process_scope="$CLI_SCOPE"
else
    echo
    verbose_question_timestamp "What should be processed?"
    echo "  [S] Also subdirectories (default)"
    echo "  [C] Current directory only"
    echo "  [Q] Quit"
    echo -n "$(user_prompt_ts_prefix)Choice [S/c/q]: "

    flush_stdin
    read_single_key input "$PROMPT_WAIT_SECONDS"
    echo

    if [[ "$input" =~ [Qq] ]]; then
        echo "Quitting."
        exit 0
    elif [[ "$input" =~ [Cc] ]]; then
        process_scope="current"
    fi
fi

echo -e "Scope selected: ${CYAN}$process_scope${RESET}"


sleep 1

vlog "Verbose mode enabled"
print_verbose_options_box

is_excluded_path() {
    local p="$1"
    [[ "$(basename -- "$p")" == "[Originals]" ]]
}

is_checksum_file() {
    local p="$1"
    [[ "$p" == *.sha512 || "$p" == *.md5 ]]
}

# Archive / compression containers and common split-volume suffixes (.r00, .001, …).
is_archive_compressed_file() {
    local bn lower
    bn="$1"
    [[ "$bn" != */* ]] || bn="$(basename -- "$bn")"
    lower="${bn,,}"
    case "$lower" in
        *.7z|*.ace|*.alz|*.apk|*.apm|*.ar|*.arc|*.arj|*.b1|*.bh|*.bz2|*.cab|*.cpio|*.deb|*.dmg|*.ear|*.egg|*.gz|*.iso|*.jar|*.lha|*.lrz|*.lz|*.lz4|*.lzh|*.lzma|*.lzo|*.pak|*.pea|*.pet|*.rar|*.rpm|*.sit|*.sfx|*.swm|*.tar|*.tbz|*.tbz2|*.tgz|*.txz|*.war|*.wim|*.xpi|*.xz|*.zip|*.zipx|*.z|*.zoo|*.zst)
            return 0
            ;;
        *.tar.*|*.cpio.*)
            return 0
            ;;
        *.r[0-9][0-9]|*.s[0-9][0-9][0-9]|*.[0-9][0-9][0-9])
            return 0
            ;;
    esac
    return 1
}

basename_preserve_leading_underscore_file() {
    local p="$1"
    is_checksum_file "$p" || is_archive_compressed_file "$p"
}

# Leading underscore run on stem (_ or __ etc.) — preserved through transform_basename.
checksum_file_leading_underscore_prefix() {
    local base="$1"
    local stem
    base="$(basename -- "$base")"
    stem="${base%.*}"
    [[ "$stem" =~ ^(_+) ]] || return 1
    printf '%s' "${BASH_REMATCH[1]}"
}

_transform_basename_restore_checksum_prefix() {
    local out="$1"
    local pfx="$2"
    local stem ext_body

    [[ -n "$pfx" ]] || { printf '%s' "$out"; return 0; }
    if [[ "$out" != *.* ]]; then
        while [[ "$out" == _* ]]; do
            out="${out#_}"
        done
        printf '%s%s' "$pfx" "$out"
        return 0
    fi
    stem="${out%.*}"
    ext_body="${out##*.}"
    while [[ "$stem" == _* ]]; do
        stem="${stem#_}"
    done
    printf '%s.%s' "${pfx}${stem}" "$ext_body"
}

is_checksum_manifest_never_rename() {
    local base
    base="$(basename -- "$1")"
    [[ "${base,,}" == "_sumy_kontrolne.md5" ]]
}

is_protected_checksum_name() {
    local p="$1"
    is_checksum_file "$p" || return 1
    is_checksum_manifest_never_rename "$p"
}

is_html_file() {
    local p="$1"
    local lower="${p,,}"
    [[ "$lower" == *.htm || "$lower" == *.html ]]
}

# Same-directory stem.nef <-> stem.xmp (Lightroom / Nikon sidecar). Used for paired plain renames.
nef_xmp_resolve_xmp_buddy() {
    local dir="$1" stem="$2"
    local p
    for p in "$dir/${stem}.xmp" "$dir/${stem}.XMP"; do
        [[ -f "$p" ]] || continue
        printf '%s\n' "$p"
        return 0
    done
    shopt -s nullglob
    local arr=( "$dir/${stem}".[xX][mM][pP] )
    shopt -u nullglob
    ((${#arr[@]} > 0)) || return 1
    printf '%s\n' "${arr[0]}"
    return 0
}

nef_xmp_resolve_nef_buddy() {
    local dir="$1" stem="$2"
    local p
    for p in "$dir/${stem}.nef" "$dir/${stem}.NEF"; do
        [[ -f "$p" ]] || continue
        printf '%s\n' "$p"
        return 0
    done
    shopt -s nullglob
    local arr=( "$dir/${stem}".[nN][eE][fF] )
    shopt -u nullglob
    ((${#arr[@]} > 0)) || return 1
    printf '%s\n' "${arr[0]}"
    return 0
}

# Prints sibling path if f is .nef or .xmp and the other exists.
nef_xmp_pair_other_path() {
    local f="$1" dir base stem ext
    [[ -f "$f" ]] || return 1
    dir="$(dirname -- "$f")"
    base="$(basename -- "$f")"
    [[ "$base" == *.* ]] || return 1
    ext="${base##*.}"
    stem="${base%.*}"
    case "${ext,,}" in
        nef) nef_xmp_resolve_xmp_buddy "$dir" "$stem" ;;
        xmp) nef_xmp_resolve_nef_buddy "$dir" "$stem" ;;
        *) return 1 ;;
    esac
}

nef_xmp_pairing_allowed() {
    local a="$1" b="$2"
    ! exception_exists_for_path "$a" && ! exception_exists_for_path "$b"
}

# Visit .nef first: defer .xmp until the .nef entry is processed.
nef_xmp_should_defer_sidecar() {
    local f="$1" other="$2"
    [[ "${f,,}" == *.xmp ]] && [[ "${other,,}" == *.nef ]] || return 1
    nef_xmp_pairing_allowed "$f" "$other"
}

nef_xmp_should_attach_buddy() {
    local f="$1" other="$2"
    [[ "${f,,}" == *.nef ]] && [[ "${other,,}" == *.xmp ]] || return 1
    nef_xmp_pairing_allowed "$f" "$other"
}

perform_nef_xmp_pair_plain_renames() {
    local primary_old="$1" primary_new="$2" buddy_old="$3" buddy_new="$4"
    perform_plain_entry_rename "$primary_old" "$primary_new" || return 1
    perform_plain_entry_rename "$buddy_old" "$buddy_new" || return 1
    if nef_xmp_pair_set_final_paths_from_primary_and_buddy_new "$primary_new" "$buddy_new"; then
        nef_xmp_sync_sidecar_raw_file_name_to_nef "$NEF_XMP_FINAL_NEF" "$NEF_XMP_FINAL_XMP" || true
        nef_xmp_verify_sidecar_raw_file_name_interactive "$NEF_XMP_FINAL_NEF" "$NEF_XMP_FINAL_XMP" || return $?
    fi
    processed["$buddy_old"]=1
    return 0
}

# Sets NEF_XMP_FINAL_NEF / NEF_XMP_FINAL_XMP from post-rename paths (primary may be .nef or .xmp).
nef_xmp_pair_set_final_paths_from_primary_and_buddy_new() {
    local p_new="$1" b_new="$2"
    NEF_XMP_FINAL_NEF=""
    NEF_XMP_FINAL_XMP=""
    if [[ "${p_new,,}" == *.nef ]]; then
        NEF_XMP_FINAL_NEF="$p_new"
        NEF_XMP_FINAL_XMP="$b_new"
        return 0
    fi
    if [[ "${p_new,,}" == *.xmp ]]; then
        NEF_XMP_FINAL_XMP="$p_new"
        NEF_XMP_FINAL_NEF="$b_new"
        return 0
    fi
    return 1
}

# Python helper: op = extract | replace | preview (preview prints current fragment vs proposed; extract prints inner value only).
nef_xmp_raw_file_name_tool() {
    local op="$1" xmp="$2"
    local extra="${3-}"
    python3 - "$xmp" "$op" "$extra" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
op = sys.argv[2]
extra = sys.argv[3] if len(sys.argv) > 3 else ""

data = path.read_bytes()

# Element form first (e.g. <crs:RawFileName>...</crs:RawFileName>), then attribute form.
ELEM_PATTERNS = (
    (
        rb"(<crs:RawFileName(?:\s[^>]*)?>)([^<]*)(</crs:RawFileName\s*>)",
        "elem_crs",
    ),
    (
        rb"(<RawFileName(?:\s[^>]*)?>)([^<]*)(</RawFileName\s*>)",
        "elem_plain",
    ),
)

ATTR_PATTERNS = (
    (rb'(\bcrs:RawFileName\s*=\s*")([^"]*)(")', "attr_dq_crs"),
    (rb'(\bRawFileName\s*=\s*")([^"]*)(")', "attr_dq_plain"),
    (rb"(\bcrs:RawFileName\s*=\s*')([^']*)(')", "attr_sq_crs"),
    (rb"(\bRawFileName\s*=\s*')([^']*)(')", "attr_sq_plain"),
)


def find_elem(data: bytes):
    for pat, kind in ELEM_PATTERNS:
        m = re.search(pat, data, flags=re.I)
        if m:
            return ("elem", kind, m)
    return None


def find_attr(data: bytes):
    for pat, kind in ATTR_PATTERNS:
        m = re.search(pat, data, flags=re.I)
        if m:
            return ("attr", kind, m)
    return None


def find_any(data: bytes):
    hit = find_elem(data)
    if hit:
        return hit
    hit = find_attr(data)
    if hit:
        return hit
    return None


def inner_value(hit):
    typ, _kind, m = hit
    return m.group(2).decode("utf-8", errors="surrogateescape")


def replace_inner(data: bytes, new_bn: bytes, hit):
    typ, _kind, m = hit
    return data[: m.start(2)] + new_bn + data[m.end(2) :]


if op == "extract":
    hit = find_any(data)
    if not hit:
        print("", end="")
        raise SystemExit(0)
    print(inner_value(hit), end="")
    raise SystemExit(0)

if op == "replace":
    new_bn = extra.encode("utf-8", errors="surrogateescape")
    hit = find_any(data)
    if not hit:
        raise SystemExit(2)
    data = replace_inner(data, new_bn, hit)
    path.write_bytes(data)
    raise SystemExit(0)

if op == "preview":
    new_bn = extra.encode("utf-8", errors="surrogateescape")
    hit = find_any(data)
    if not hit:
        raise SystemExit(2)
    typ, kind, m = hit
    cur_frag = m.group(0).decode("utf-8", errors="replace")
    new_frag = (m.group(1) + new_bn + m.group(3)).decode("utf-8", errors="replace")
    print("Format: %s / %s" % (typ, kind))
    print("--- Current RawFileName fragment in XMP ---")
    print(cur_frag)
    print("--- Would become ---")
    print(new_frag)
    raise SystemExit(0)

raise SystemExit(3)
PY
}

nef_xmp_extract_raw_file_name_value() {
    local xmp="$1"
    [[ -f "$xmp" ]] || return 1
    nef_xmp_raw_file_name_tool extract "$xmp" ""
}

# Rewrite RawFileName (element text or attribute value); restores mtime/access from before write.
nef_xmp_replace_raw_file_name_preserving_times() {
    local xmp="$1" new_bn="$2"
    local ref st=0
    [[ -f "$xmp" ]] || return 1
    ref="$(mktemp)"
    touch -r "$xmp" "$ref"
    nef_xmp_raw_file_name_tool replace "$xmp" "$new_bn" || st=$?
    touch -r "$ref" "$xmp"
    rm -f "$ref"
    return "$st"
}

nef_xmp_print_raw_file_name_preview() {
    local xmp="$1" proposed_bn="$2"
    [[ -f "$xmp" ]] || return 1
    nef_xmp_raw_file_name_tool preview "$xmp" "$proposed_bn" || return 1
    return 0
}

# Returns 0 if crs:RawFileName / RawFileName element or attribute exists (tool can preview/replace).
nef_xmp_sidecar_has_raw_file_name_markup() {
    local xmp="$1"
    [[ -f "$xmp" ]] || return 1
    nef_xmp_raw_file_name_tool preview "$xmp" "__probe__" >/dev/null 2>&1
}

# After a real rename, force sidecar metadata to match the NEF basename (no prompt).
nef_xmp_sync_sidecar_raw_file_name_to_nef() {
    local nef_path="$1" xmp_path="$2"
    local want cur
    [[ -f "$nef_path" && -f "$xmp_path" ]] || return 0
    [[ "${xmp_path,,}" == *.xmp ]] || return 0
    want="$(basename -- "$nef_path")"
    cur="$(nef_xmp_extract_raw_file_name_value "$xmp_path")"
    [[ "${cur,,}" == "${want,,}" ]] && return 0
    if ! nef_xmp_sidecar_has_raw_file_name_markup "$xmp_path"; then
        return 0
    fi
    if [[ "$mode" == "dry-run" ]]; then
        vlog "[DRY-RUN] Would set XMP RawFileName in '$xmp_path' to '${want}' (currently '${cur:-empty}')"
        return 0
    fi
    vlog "Updating XMP RawFileName in '$xmp_path' to '${want}' (was '${cur:-empty}')"
    if ! nef_xmp_replace_raw_file_name_preserving_times "$xmp_path" "$want"; then
        vlog "XMP RawFileName: no editable crs:RawFileName / RawFileName markup in '$xmp_path' — skipped sync after rename."
    fi
}

# Plain-text lines only (no ANSI). Long lines are folded with fold -s — nothing is truncated mid-path.
nef_xmp_emit_text_box() {
    nonverbose_progress_dot_endline_if_needed
    local title="$1"
    shift
    local -a in_lines=( "$@" )
    local wrap_w="${NEF_XMP_BOX_WRAP_WIDTH:-108}"
    (( wrap_w < 52 )) && wrap_w=52

    local -a title_rows=()
    local -a rows=()
    mapfile -t title_rows < <(printf '%s\n' "$title" | fold -s -w "$wrap_w")

    local line
    for line in "${in_lines[@]}"; do
        mapfile -t -O "${#rows[@]}" rows < <(printf '%s\n' "$line" | fold -s -w "$wrap_w")
    done

    local max_len=0
    local r
    for r in "${title_rows[@]}"; do
        (( ${#r} > max_len )) && max_len=${#r}
    done
    for r in "${rows[@]}"; do
        (( ${#r} > max_len )) && max_len=${#r}
    done
    (( max_len < 52 )) && max_len=52

    printf '┌%*s┐\n' "$((max_len + 2))" '' | tr ' ' '─'
    for r in "${title_rows[@]}"; do
        printf '│ %-*s │\n' "$max_len" "$r"
    done
    printf '├%*s┤\n' "$((max_len + 2))" '' | tr ' ' '─'
    for r in "${rows[@]}"; do
        printf '│ %-*s │\n' "$max_len" "$r"
    done
    printf '└%*s┘\n' "$((max_len + 2))" '' | tr ' ' '─'
    echo
}

# Canonical realpath of the directory containing the sidecar (for per-directory RawFileName batch mode).
nef_xmp_canonical_dir_for_pair() {
    local d p="${1:-}"
    [[ -n "$p" ]] || return 1
    d="$(dirname -- "$p")"
    ( cd "$d" && pwd -P ) 2>/dev/null || printf '%s\n' "$d"
}

# Stand-alone verification line so OK/WARN/NOTE is easy to spot (not buried in the Unicode box).
nef_xmp_print_verification_banner() {
    local kind="$1" msg="$2"
    if [[ "$use_colors" == "yes" ]]; then
        case "$kind" in
            ok)   echo -e "${GREEN}${BOLD}${msg}${RESET}" ;;
            warn) echo -e "${YELLOW}${BOLD}${msg}${RESET}" ;;
            note) echo -e "${YELLOW}${msg}${RESET}" ;;
            err)  echo -e "${RED}${BOLD}${msg}${RESET}" ;;
            *)    printf '%s\n' "$msg" ;;
        esac
    else
        printf '%s\n' "$msg"
    fi
}

# Show that proposed RawFileName basename exists as the paired NEF (ls/stat/md5); does not use rename.sh DB hash helpers.
nef_xmp_print_proposed_raw_file_proof() {
    local xmp_path="$1" nef_path="$2" proposed_bn="$3"
    local dir join ls_line md5_disp sz mt at verify_line verify_kind

    dir="$(dirname -- "$xmp_path")"
    join="$dir/$proposed_bn"

    if [[ ! -f "$nef_path" ]]; then
        nef_xmp_emit_text_box "Paired NEF (filesystem)" \
            "Suggested RawFileName basename: '${proposed_bn}'" \
            "Path beside sidecar would be: '${join}'" \
            "Paired NEF path: '${nef_path}'" \
            "ERROR: paired path is not a regular file — cannot verify."
        nef_xmp_print_verification_banner err "Verification: ERROR — paired NEF is missing or not a regular file."
        return 1
    fi

    if [[ -f "$join" ]] && paths_refer_to_same_file "$join" "$nef_path"; then
        verify_line="Verification: OK — sidecar-dir join matches paired NEF (same inode)."
        verify_kind=ok
    elif [[ -f "$join" ]]; then
        verify_line="Verification: WARNING — '${join}' exists but differs from paired NEF inode."
        verify_kind=warn
    else
        verify_line="Verification: NOTE — join path missing (case/spelling?); listing paired NEF below."
        verify_kind=note
    fi

    ls_line="$(ls -l -- "$nef_path" 2>/dev/null || true)"
    [[ -z "$ls_line" ]] && ls_line="(ls -l unavailable)"

    sz="$(stat -c %s -- "$nef_path" 2>/dev/null || printf '%s' '?')"
    mt="$(stat -c '%y' -- "$nef_path" 2>/dev/null || printf '%s' '?')"
    at="$(stat -c '%x' -- "$nef_path" 2>/dev/null || printf '%s' '?')"

    md5_disp=""
    if command -v md5sum >/dev/null 2>&1; then
        md5_disp="$(md5sum -- "$nef_path" 2>/dev/null | awk '{print tolower($1)}')"
    elif command -v md5 >/dev/null 2>&1; then
        md5_disp="$(md5 -q -- "$nef_path" 2>/dev/null | tr '[:upper:]' '[:lower:]')"
    fi

    nef_xmp_emit_text_box "Paired NEF (filesystem)" \
        "Suggested RawFileName basename: '${proposed_bn}'" \
        "Path beside sidecar: '${join}'" \
        "Paired NEF path: '${nef_path}'" \
        "ls -l: ${ls_line}" \
        "Size (bytes): ${sz}" \
        "Mtime: ${mt}" \
        "Atime: ${at}" \
        "MD5 (one-off, not DB): ${md5_disp:-install md5sum or md5 to show}"

    nef_xmp_print_verification_banner "$verify_kind" "$verify_line"

    return 0
}

# Compare XMP RawFileName to paired NEF; prompt to fix stale/wrong values (dry-run: message only).
nef_xmp_verify_sidecar_raw_file_name_interactive() {
    local nef_path="$1" xmp_path="$2"
    local want cur dir ans stem_same resolved proposed xdir

    [[ -f "$nef_path" && -f "$xmp_path" ]] || return 0
    [[ "${xmp_path,,}" == *.xmp ]] || return 0
    [[ "${nef_path,,}" == *.nef ]] || return 0

    want="$(basename -- "$nef_path")"
    cur="$(nef_xmp_extract_raw_file_name_value "$xmp_path")"

    if [[ "${cur,,}" == "${want,,}" ]]; then
        return 0
    fi

    dir="$(dirname -- "$xmp_path")"
    if [[ -n "$cur" && -f "$dir/$cur" ]] && paths_refer_to_same_file "$dir/$cur" "$nef_path"; then
        return 0
    fi

    stem_same=""
    resolved=""
    if resolved="$(nef_xmp_resolve_nef_buddy "$dir" "$(basename -- "${xmp_path%.*}")")"; then
        stem_same="$(basename -- "$resolved")"
    fi
    proposed="$want"

    xdir="$(nef_xmp_canonical_dir_for_pair "$xmp_path")"

    if ! nef_xmp_sidecar_has_raw_file_name_markup "$xmp_path"; then
        vlog "XMP RawFileName: no crs:RawFileName / RawFileName markup in '$xmp_path' — skip (paired NEF basename is '${want}')."
        return 0
    fi

    if [[ "$mode" == "dry-run" ]]; then
        emit_wrap_labeled_stdout "NOTE: " "${YELLOW}NOTE:${RESET} " "Would update XMP RawFileName from '${cur:-<empty>}' to '${want}' (paired NEF basename). Dry-run preview:"
        nef_xmp_print_proposed_raw_file_proof "$xmp_path" "$nef_path" "$want"
        nef_xmp_print_raw_file_name_preview "$xmp_path" "$want" || true
        return 0
    fi

    # Same canonical directory as a prior [d] choice: apply RawFileName fix without prompting.
    if [[ -n "$NEF_XMP_RAWFIX_AUTO_DIR" && -n "$xdir" && "$xdir" == "$NEF_XMP_RAWFIX_AUTO_DIR" ]]; then
        echo
        echo "XMP sidecar metadata check (auto, directory batch): '$xmp_path'"
        echo "  This step only edits RawFileName *inside* the .xmp (Lightroom crs:RawFileName / RawFileName). It does not rename the .xmp or .nef paths on disk."
        echo "  Applying update: RawFileName '${cur:-<empty>}' -> '${proposed}' (paired NEF basename)."
        echo "  Paired NEF: '$nef_path'"
        [[ -n "$stem_same" ]] && echo "  Same-stem .nef in directory: '$stem_same'"
        echo
        nef_xmp_print_proposed_raw_file_proof "$xmp_path" "$nef_path" "$proposed"
        nef_xmp_print_raw_file_name_preview "$xmp_path" "$proposed" || true
        echo
        if nef_xmp_replace_raw_file_name_preserving_times "$xmp_path" "$proposed"; then
            emit_wrap_labeled_stdout "OK: " "${GREEN}OK:${RESET} " "Updated RawFileName in '$xmp_path' (directory batch mode, dir '${NEF_XMP_RAWFIX_AUTO_DIR}')."
            vlog "RawFileName auto-updated (directory batch): '$xmp_path'"
        else
            emit_wrap_labeled_stdout "SKIP: " "${YELLOW}SKIP:${RESET} " "RawFileName patch failed in '$xmp_path' (directory batch)."
        fi
        return 0
    fi

    echo
    echo "XMP sidecar metadata check: '$xmp_path'"
    echo "  What this does: write the RawFileName string *inside* this .xmp (crs:RawFileName or RawFileName) so it matches the paired .nef basename."
    echo "  It does not rename the .xmp or .nef files on disk — only the XML field."
    echo "  Proposed RawFileName value inside the XMP: '${cur:-<empty>}' -> '${proposed}' (should match paired NEF basename)."
    echo "  Paired NEF: '$nef_path'"
    [[ -n "$stem_same" ]] && echo "  Same-stem .nef in directory: '$stem_same'"
    echo
    nef_xmp_print_proposed_raw_file_proof "$xmp_path" "$nef_path" "$proposed"
    if ! nef_xmp_print_raw_file_name_preview "$xmp_path" "$proposed"; then
        vlog "XMP RawFileName: preview failed for '$xmp_path' — skip interactive prompt."
        return 0
    fi
    while true; do
        echo "  Keys:"
        echo "    [Y] Yes / Enter - patch this .xmp only (default)"
        echo "    [d] Yes + auto-patch every RawFileName fix in this directory"
        echo "    [n] No"
        print_prompt_view_directory_menu_line
        echo "    [q] Quit run"
        if (( VERBOSE == 1 )); then
            echo "[VERBOSE] [$(date '+%Y.%m.%d %H:%M:%S')] Write RawFileName into this .xmp on disk? (metadata only) [Y/n/d/v/q]:" >&2
        else
            nonverbose_progress_dot_endline_if_needed
        fi
        printf '%s' "$(user_prompt_ts_prefix)Write RawFileName into this .xmp on disk? (metadata only) [Y/n/d/v/q]: "
        flush_stdin
        read_single_key ans "$PROMPT_WAIT_SECONDS"
        echo
        if handle_prompt_directory_listing_choice "$ans" "$xmp_path" "$nef_path"; then
            continue
        fi
        case "$ans" in
            q|Q)
                stopped_by_user=yes
                return 2
                ;;
            d|D)
                NEF_XMP_RAWFIX_AUTO_DIR="$xdir"
                if nef_xmp_replace_raw_file_name_preserving_times "$xmp_path" "$proposed"; then
                    emit_wrap_labeled_stdout "OK: " "${GREEN}OK:${RESET} " "Updated RawFileName in '$xmp_path'; further mismatches in '${NEF_XMP_RAWFIX_AUTO_DIR}' auto-apply."
                    vlog "RawFileName directory batch mode set to '${NEF_XMP_RAWFIX_AUTO_DIR}'; applied '$xmp_path'"
                else
                    emit_wrap_labeled_stdout "SKIP: " "${YELLOW}SKIP:${RESET} " "RawFileName patch failed in '$xmp_path'."
                fi
                return 0
                ;;
            n|N)
                return 0
                ;;
            *)
                if nef_xmp_replace_raw_file_name_preserving_times "$xmp_path" "$proposed"; then
                    emit_wrap_labeled_stdout "OK: " "${GREEN}OK:${RESET} " "Updated RawFileName in '$xmp_path' (same encoding as matched fragment)."
                else
                    emit_wrap_labeled_stdout "SKIP: " "${YELLOW}SKIP:${RESET} " "RawFileName patch failed in '$xmp_path'."
                fi
                return 0
                ;;
        esac
    done
}

nef_xmp_pair_run_sidecar_metadata_checks() {
    [[ -n "$nef_xmp_buddy" ]] || return 0
    [[ "$RENAME_SIDECAR_KIND" == sony_clip ]] && return 0
    nef_xmp_pair_set_final_paths_from_primary_and_buddy_new "$1" "$2" || return 0
    nef_xmp_verify_sidecar_raw_file_name_interactive "$NEF_XMP_FINAL_NEF" "$NEF_XMP_FINAL_XMP" || return $?
}

# Main loop: uses f, new, nef_xmp_buddy, nef_xmp_new, RENAME_SIDECAR_KIND
perform_plain_or_nef_xmp_pair() {
    local reason="$1"
    if [[ "$RENAME_SIDECAR_KIND" == sony_clip && -n "$nef_xmp_buddy" ]]; then
        print_rename_action_verbose "$f" "$new" "${reason} (Sony clip pair)"
        print_rename_action_verbose "$nef_xmp_buddy" "$nef_xmp_new" "${reason} (Sony clip pair)"
        perform_sony_clip_pair_plain_renames "$f" "$new" "$nef_xmp_buddy" "$nef_xmp_new" || return $?
    elif [[ -n "$nef_xmp_buddy" ]]; then
        print_rename_action_verbose "$f" "$new" "${reason} (NEF+XMP pair)"
        print_rename_action_verbose "$nef_xmp_buddy" "$nef_xmp_new" "${reason} (NEF+XMP pair)"
        perform_nef_xmp_pair_plain_renames "$f" "$new" "$nef_xmp_buddy" "$nef_xmp_new" || return $?
    else
        print_rename_action_verbose "$f" "$new" "$reason"
        perform_plain_entry_rename "$f" "$new"
    fi
}

is_media_file() {
    local p="$1"
    local lower="${p,,}"
    [[ "$lower" == *.mp3 || "$lower" == *.flac || "$lower" == *.wav || "$lower" == *.m4a || "$lower" == *.aac || "$lower" == *.ogg || "$lower" == *.wma || "$lower" == *.mp4 || "$lower" == *.mkv || "$lower" == *.avi || "$lower" == *.mov || "$lower" == *.wmv || "$lower" == *.mpeg || "$lower" == *.mpg || "$lower" == *.m4v || "$lower" == *.webm || "$lower" == *.ts || "$lower" == *.nef || "$lower" == *.xmp || "$lower" == *.psb || "$lower" == *.psd || "$lower" == *.psdt ]]
}

is_ms_office_file() {
    local p="$1"
    local lower="${p,,}"
    [[ "$lower" == *.doc || "$lower" == *.docx || "$lower" == *.docm || "$lower" == *.dot || "$lower" == *.dotx || "$lower" == *.dotm || "$lower" == *.xls || "$lower" == *.xlsx || "$lower" == *.xlsm || "$lower" == *.xlt || "$lower" == *.xltx || "$lower" == *.xltm || "$lower" == *.xlam || "$lower" == *.ppt || "$lower" == *.pptx || "$lower" == *.pptm || "$lower" == *.pot || "$lower" == *.potx || "$lower" == *.potm || "$lower" == *.pps || "$lower" == *.ppsx || "$lower" == *.ppsm || "$lower" == *.sldx || "$lower" == *.sldm ]]
}

eligible_for_media_office_extension_case_auto() {
    local p="$1"
    [[ -f "$p" ]] || return 1
    is_media_file "$p" || is_ms_office_file "$p"
}

is_m3u_file() {
    local p="$1"
    local lower="${p,,}"
    [[ "$lower" == *.m3u ]]
}

# Leading underscore is intentional on cover scans (okładka); pattern is case-insensitive on basename.
# Matches okladka and okladna spellings in the stem.
is_okladka_cover_keep_leading_underscore() {
    local bn lower
    bn="$1"
    [[ "$bn" != */* ]] || bn="$(basename -- "$bn")"
    lower="${bn,,}"
    [[ "$lower" == _*okladka*jpg || "$lower" == _*okladna*jpg ]]
}

# PAR2 repair sets often use a leading underscore on the volume/slice basename; keep those names untouched.
is_protected_par2_name() {
    local bn lower
    bn="$1"
    [[ "$bn" != */* ]] || bn="$(basename -- "$bn")"
    lower="${bn,,}"
    [[ "$bn" == _* && "$lower" == *.par2 ]]
}

# Internet shortcut: basename contains "torrent" and ends in .url (any case).
is_torrent_url_file() {
    local p="$1"
    local bn lower
    [[ -f "$p" ]] || return 1
    bn="$(basename -- "$p")"
    lower="${bn,,}"
    [[ "$lower" == *torrent*.url ]]
}

path_basename_is_thumbs_db() {
    local p="$1"
    local bn lower
    # Windows-style paths inside checksum lines use '\' ; basename(1) only splits on '/' so normalize first.
    p="${p//\\//}"
    bn="$(basename -- "$p")"
    lower="${bn,,}"
    [[ "$lower" == "thumbs.db" ]]
}

is_thumbs_db_file() {
    local p="$1"
    [[ -f "$p" ]] || return 1
    path_basename_is_thumbs_db "$p"
}

perform_thumbs_db_delete() {
    local path="$1"
    if ! is_thumbs_db_file "$path"; then
        return 1
    fi
    if [[ "$mode" == "dry-run" ]]; then
        collect_local_checksum_ref_summaries "$path" "file"
        emit_wrap_labeled_stdout "[DRY-RUN] Would delete thumbs.db: " "${CYAN}[DRY-RUN] Would delete thumbs.db:${RESET} " "$path"
        if (( ${#PLAIN_REF_SUM_FILES[@]} > 0 )); then
            echo -e "${CYAN}[DRY-RUN] Would update checksum file(s) for removed thumbs.db reference:${RESET}"
            for sum_file in "${PLAIN_REF_SUM_FILES[@]}"; do
                emit_wrap_labeled_stdout "    " "    " "$sum_file"
            done
        fi
    else
        update_local_checksums_after_deleted_file "$path"
        db_delete_cached_row_for_path "$path"
        rm -f -- "$path"
        emit_wrap_labeled_stdout "Deleted thumbs.db: " "${GREEN}Deleted thumbs.db:${RESET} " "$path"
    fi
    ((++files_affected))
    return 0
}

paths_refer_to_same_file() {
    local a="$1" b="$2" ida idb
    [[ -e "$a" && -e "$b" ]] || return 1
    ida="$(stat -c '%d:%i' -- "$a" 2>/dev/null)" || return 1
    idb="$(stat -c '%d:%i' -- "$b" 2>/dev/null)" || return 1
    [[ -n "$ida" && "$ida" == "$idb" ]]
}

# Same parent directory; basenames differ only by letter case (abc.JPG vs abc.jpg). On case-insensitive FS a single mv may fail or match the same inode.
is_case_only_rename_pair() {
    local old="$1" new="$2" d_o d_n b_o b_n
    [[ -e "$old" ]] || return 1
    d_o="$(dirname -- "$old")"
    d_n="$(dirname -- "$new")"
    b_o="$(basename -- "$old")"
    b_n="$(basename -- "$new")"
    [[ "${d_o%/}" == "${d_n%/}" ]] || return 1
    [[ "$b_o" != "$b_n" ]] || return 1
    [[ "${b_o,,}" == "${b_n,,}" ]] || return 1
    return 0
}

# One-time notice when util-linux findmnt is absent (case-only skip relies on it).
warn_findmnt_missing_once() {
    [[ -n "${FINDMNT_MISSING_WARNED-}" ]] && return 0
    FINDMNT_MISSING_WARNED=1
    echo -e "${YELLOW}rename.sh:${RESET} ${CYAN}findmnt${RESET} was not found. Install ${CYAN}util-linux${RESET} so exfat/CIFS/SMB/GVFS mounts are detected and case-only renames are skipped safely." >&2
    echo "  Debian/Ubuntu: sudo apt install util-linux    Fedora/RHEL: sudo dnf install util-linux    Alpine: apk add util-linux" >&2
}

# exfat and SMB/CIFS backends are usually case-insensitive or awkward for case-only renames.
# Also treat GNOME/KDE GVFS SMB (fuse.gvfsd-fuse) and rclone FUSE mounts that expose smb:// / UNC paths.
path_filesystem_skip_case_only_rename() {
    local path="$1" fs src opts lsrc lopts rp
    [[ -e "$path" ]] || return 1
    if ! command -v findmnt >/dev/null 2>&1; then
        warn_findmnt_missing_once
        return 1
    fi
    fs="$(findmnt -n -o FSTYPE --target "$path" 2>/dev/null)" || return 1
    fs="${fs,,}"

    case "$fs" in
        exfat|cifs|smb3|smbfs) return 0 ;;
    esac

    src="$(findmnt -n -o SOURCE --target "$path" 2>/dev/null)" || src=""
    opts="$(findmnt -n -o OPTIONS --target "$path" 2>/dev/null)" || opts=""
    lsrc="${src,,}"
    lopts="${opts,,}"

    rp="$(realpath -- "$path" 2>/dev/null || readlink -f -- "$path" 2>/dev/null || printf '%s' "$path")"
    rp="${rp,,}"

    case "$fs" in
        fuse.gvfsd-fuse)
            if [[ "$rp" == */gvfs/smb-share* ]]; then
                return 0
            fi
            if [[ "$lsrc" == *smb-share* || "$lsrc" == smb:* || "$lsrc" == //* ]]; then
                return 0
            fi
            ;;
        fuse.rclone)
            if [[ "$lsrc" == smb:* || "$lsrc" == *':smb'* || "$lsrc" == //* || "$lopts" == *type=smb* || "$lopts" == *fstype=smb* ]]; then
                return 0
            fi
            ;;
    esac

    return 1
}

should_skip_case_only_rename_on_fs() {
    local old="$1" new="$2"
    [[ "$old" != "$new" ]] || return 1
    is_case_only_rename_pair "$old" "$new" || return 1
    path_filesystem_skip_case_only_rename "$old" || return 1
    return 0
}

# Random unused path in the same directory as old/new (case-only: mv A→B→C, all in that dir).
case_only_random_intermediate_same_dir() {
    local target="$1" dir i=0 p
    dir="$(dirname -- "$target")"
    [[ -w "$dir" ]] || return 1
    while (( i < 500 )); do
        p="$dir/.___case_ren_$$_${RANDOM}_${i}.tmp"
        [[ ! -e "$p" ]] && { printf '%s\n' "$p"; return 0; }
        ((++i))
    done
    return 1
}

# Case-only: mv A→B→C — B is random name beside A/C (same directory only).
case_only_rename_safe() {
    local old="$1" new="$2" b
    [[ -f "$old" ]] || return 1
    b="$(case_only_random_intermediate_same_dir "$new")" || return 1
    mv -- "$old" "$b" || return 1
    sleep 1
    sync
    if mv -- "$b" "$new"; then
        [[ -f "$new" ]] || return 1
        return 0
    fi
    mv -- "$b" "$old" || return 1
    return 1
}

mv_with_case_only_filesystem_workaround() {
    local old="$1" new="$2"
    if is_case_only_rename_pair "$old" "$new"; then
        case_only_rename_safe "$old" "$new" || return 1
        [[ -f "$new" ]] || return 1
        return 0
    fi
    mv -i -- "$old" "$new" || return 1
    return 0
}

# Same case-only logic without -i on the non-case-only mv branch only.
mv_with_case_only_filesystem_workaround_force() {
    local old="$1" new="$2"
    if is_case_only_rename_pair "$old" "$new"; then
        case_only_rename_safe "$old" "$new" || return 1
        [[ -f "$new" ]] || return 1
        return 0
    fi
    mv -f -- "$old" "$new" || return 1
    return 0
}

# After [D] per-directory auto-yes or [S] similar-name auto-yes: show renames even when VERBOSE=0 (dirname match or same pwd -P).
plain_rename_emit_auto_dir_notice_if_active() {
    local old="$1" new="$2"
    local d_old want_emit=no
    d_old="$(dirname -- "$old")"
    if [[ -n "$AUTO_RENAME_DIR" ]]; then
        local d_auto="$AUTO_RENAME_DIR"
        if [[ "$d_old" == "$d_auto" ]]; then
            want_emit=yes
        else
            local r_old r_auto
            r_old="$(cd -- "$d_old" 2>/dev/null && pwd -P)" || r_old="$d_old"
            r_auto="$(cd -- "$d_auto" 2>/dev/null && pwd -P)" || r_auto="$AUTO_RENAME_DIR"
            [[ "$r_old" == "$r_auto" ]] && want_emit=yes
        fi
    fi
    if [[ "$want_emit" == no && -n "$AUTO_RENAME_SIMILAR_DIR" ]]; then
        if similar_rename_dir_matches_scope "$d_old" "$AUTO_RENAME_SIMILAR_DIR" \
            && similar_rename_entry_matches_anchor_pattern "$old"; then
            want_emit=yes
        fi
    fi
    [[ "$want_emit" == yes ]] || return 0
    emit_wrap_old_arrow_new_stdout "Renamed: " "${GREEN}Renamed:${RESET} " "$old" "$new"
}

# Same directory and basename stem; suggested path lowercases only the extension (any length, e.g. .MP4 -> .mp4, .JPEG -> .jpeg).
rename_suggested_only_extension_case_change() {
    local old_path="$1" new_path="$2"
    local dir_old dir_new ob nb stem_old stem_new oe ne

    [[ -f "$old_path" ]] || return 1
    dir_old="$(dirname -- "$old_path")"
    dir_new="$(dirname -- "$new_path")"
    [[ "$dir_old" == "$dir_new" ]] || return 1
    ob="$(basename -- "$old_path")"
    nb="$(basename -- "$new_path")"
    [[ "$ob" == *.* && "$nb" == *.* ]] || return 1
    stem_old="${ob%.*}"
    stem_new="${nb%.*}"
    [[ "$stem_old" == "$stem_new" ]] || return 1
    oe="${ob##*.}"
    ne="${nb##*.}"
    [[ -n "$oe" && -n "$ne" ]] || return 1
    [[ "$ne" == "${oe,,}" ]] || return 1
    [[ "$oe" != "${oe,,}" ]] || return 1
    return 0
}

path_to_exclude_entry() {
    exception_entry_for_path "$1"
}

is_internal_protected_path() {
    local p="$1"
    local abs start_abs resume_abs base

    [[ -n "$p" ]] || return 1
    base="$(basename -- "$p")"

    case "$base" in
        _rename.sh.resume-state.json|rename.sh.resume-state.json)
            return 0
            ;;
    esac

    abs="$(db_abs_path "$p" 2>/dev/null || true)"
    start_abs="$(db_abs_path "$START_DIR" 2>/dev/null || true)"

    if [[ -n "${RESUME_STATE_FILE:-}" ]]; then
        resume_abs="$(db_abs_path "$RESUME_STATE_FILE" 2>/dev/null || true)"
        [[ -n "$resume_abs" ]] || resume_abs="$RESUME_STATE_FILE"
        if [[ -n "$abs" && "$abs" == "$resume_abs" ]]; then
            return 0
        fi
    fi

    [[ -n "$abs" && -n "$start_abs" ]] || return 1

    if [[ "$abs" == "$start_abs/_exclude-rename.sh.txt" ]]; then
        return 0
    fi
    if [[ "$abs" == "$start_abs/_rename.sh.resume-state.json" ]]; then
        return 0
    fi
    if [[ "$abs" == "$start_abs/_rename.sh-optional-db.sqlite3" ]]; then
        return 0
    fi
    if [[ "$abs" == "$start_abs/rename.sh-optional-db.sqlite3" ]]; then
        return 0
    fi
    if [[ "$abs" == "$start_abs/_rename.sh-optional-db.sqlite3-wal" || "$abs" == "$start_abs/_rename.sh-optional-db.sqlite3-shm" ]]; then
        return 0
    fi
    if [[ "$abs" == "$start_abs/rename.sh-optional-db.sqlite3-wal" || "$abs" == "$start_abs/rename.sh-optional-db.sqlite3-shm" ]]; then
        return 0
    fi

    return 1
}

update_m3u_references_in_file() {
    local m3u_file="$1"
    local old_path="$2"
    local new_path="$3"
    local tmp old_base new_base old_norm new_norm old_base_norm new_base_norm

    [[ -f "$m3u_file" ]] || return 0
    old_base="$(basename -- "$old_path")"
    new_base="$(basename -- "$new_path")"
    old_norm="$(normalize_m3u_entry_for_compare "$old_path")"
    new_norm="$(normalize_m3u_entry_for_compare "$new_path")"
    old_base_norm="$(normalize_m3u_entry_for_compare "$old_base")"
    new_base_norm="$(normalize_m3u_entry_for_compare "$new_base")"

    if [[ "$old_norm" == "$new_norm" && "$old_base_norm" == "$new_base_norm" ]]; then
        return 1
    fi

    tmp="$(mktemp)"

    if python3 - "$m3u_file" "$tmp" "$old_path" "$new_path" "$old_base" "$new_base" <<'PY'
import sys

src, dst, old_path, new_path, old_base, new_base = sys.argv[1:]

with open(src, 'r', encoding='utf-8', errors='surrogateescape', newline='') as f:
    lines = f.readlines()

basename_change_needed = (old_base != new_base)

out = []
changed = False

for line in lines:
    nl = line
    if line.endswith('\r\n'):
        eol = '\r\n'
    elif line.endswith('\n'):
        eol = '\n'
    elif line.endswith('\r'):
        eol = '\r'
    else:
        eol = ''

    stripped = line.rstrip('\r\n')

    if stripped == old_path and old_path != new_path:
        nl = new_path + eol
        changed = True
    elif basename_change_needed and stripped == old_base:
        nl = new_base + eol
        changed = True

    out.append(nl)

with open(dst, 'w', encoding='utf-8', errors='surrogateescape', newline='') as f:
    f.writelines(out)

sys.exit(0 if changed else 3)
PY
    then
        rc=0
    else
        rc=$?
    fi
    if [[ $rc -eq 0 ]]; then
        mv -- "$tmp" "$m3u_file"
        emit_wrap_labeled_stdout "M3U UPDATED: " "${CYAN}M3U UPDATED:${RESET} " "$m3u_file"
    else
        rm -f -- "$tmp"
    fi
}

update_all_m3u_files_for_rename() {
    local old_path="$1"
    local new_path="$2"
    local start="${START_DIR:-.}"
    while IFS= read -r -d '' m3u; do
        update_m3u_references_in_file "$m3u" "$old_path" "$new_path"
    done < <(find "$start" -type f -iname '*.m3u' -print0 2>/dev/null)
}

normalize_m3u_candidate_key() {
    local s="$1"
    python3 - "$s" <<'PY'
import os, re, sys

s = sys.argv[1]
s = s.replace('\\', '/')
s = os.path.basename(s).lower()
s = re.sub(r'\.[^.]+$', '', s)
s = s.replace('&', 'and')
quote_chars = "'`\"´’‘"
remove_chars = " _.,;:()[]{}+-!\t\r\n" + quote_chars
translate_map = {ord(ch): None for ch in remove_chars}
s = s.translate(translate_map)

sys.stdout.buffer.write(s.encode('utf-8', 'surrogateescape'))
PY
}


find_best_m3u_subtree_match() {
    local m3u_file="$1"
    local missing_entry="$2"
    local playlist_dir candidate wanted_key candidate_key best=""
    playlist_dir="$(dirname -- "$m3u_file")"
    wanted_key="$(normalize_m3u_candidate_key "$missing_entry")"
    [[ -n "$wanted_key" ]] || return 1

    while IFS= read -r -d '' candidate; do
        candidate_key="$(normalize_m3u_candidate_key "$candidate")"
        if [[ "$candidate_key" == "$wanted_key" ]]; then
            best="$candidate"
            break
        fi
        if [[ -z "$best" && -n "$candidate_key" && ( "$candidate_key" == *"$wanted_key"* || "$wanted_key" == *"$candidate_key"* ) ]]; then
            best="$candidate"
        fi
    done < <(find "$playlist_dir" -type f -print0 2>/dev/null)

    [[ -n "$best" ]] || return 1
    printf '%s' "$best"
}



normalize_m3u_entry_for_compare() {
    local s="$1"
    s="${s%$'
'}"
    s="${s%$'
'}"
    s="${s//\//}"
    while [[ "$s" == ./* ]]; do
        s="${s#./}"
    done
    printf '%s' "$s"
}

replace_single_m3u_entry() {
    local m3u_file="$1"
    local old_entry="$2"
    local new_entry="$3"
    local tmp rc m3u_dir

    old_entry="${old_entry%$'\r'}"
    old_entry="${old_entry%$'\n'}"
    new_entry="${new_entry%$'\r'}"
    new_entry="${new_entry%$'\n'}"

    m3u_dir="$(dirname -- "$m3u_file")"
    tmp="$(mktemp --tmpdir="$m3u_dir" .m3u-update.XXXXXX)"
    if python3 - "$m3u_file" "$tmp" "$old_entry" "$new_entry" <<'PY'
import sys

src, dst, old_entry, new_entry = sys.argv[1:]

old_entry = old_entry.rstrip('\r\n')
new_entry = new_entry.rstrip('\r\n')

def norm(value: str) -> str:
    value = value.rstrip('\r\n')
    value = value.replace('\\', '/')
    while value.startswith('./'):
        value = value[2:]
    return value

with open(src, 'r', encoding='utf-8', errors='surrogateescape', newline='') as f:
    lines = f.readlines()

old_norm = norm(old_entry)
new_norm = norm(new_entry)
out = []
changed = False

for line in lines:
    if line.endswith('\r\n'):
        nl = '\r\n'
    elif line.endswith('\n'):
        nl = '\n'
    elif line.endswith('\r'):
        nl = '\r'
    else:
        nl = ''

    stripped = line.rstrip('\r\n')
    stripped_norm = norm(stripped)

    exact_match = (stripped == old_entry)
    normalized_match = (stripped_norm == old_norm)

    if exact_match or normalized_match:
        if stripped == new_entry or stripped_norm == new_norm:
            out.append(line)
        else:
            out.append(new_entry + nl)
            changed = True
    else:
        out.append(line)

with open(dst, 'w', encoding='utf-8', errors='surrogateescape', newline='') as f:
    f.writelines(out)

sys.exit(0 if changed else 3)
PY
    then
        rc=0
    else
        rc=$?
    fi
    if [[ $rc -eq 0 ]]; then
        if mv -- "$tmp" "$m3u_file"; then
            return 0
        fi
        rm -f -- "$tmp"
        return 1
    fi
    rm -f -- "$tmp"
    if [[ $rc -eq 3 ]]; then
        return 3
    fi
    return 1
}

print_m3u_no_update_needed() {
    local m3u_file="$1"
    printf '%s\n' "M3U CHECK: no update needed: $m3u_file"
}

check_m3u_targets() {
    local m3u_file="$1"
    local dir line target found replacement display_entry rc
    dir="$(dirname -- "$m3u_file")"
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        display_entry="$line"
        if [[ "$line" = /* ]]; then
            target="$line"
        else
            target="$dir/${line//\//}"
        fi
        if [[ ! -e "$target" ]]; then
            found="$(find_best_m3u_subtree_match "$m3u_file" "$line" || true)"
            if [[ -n "$found" ]]; then
                replacement="${found#$dir/}"
                [[ "$replacement" == "$found" ]] && replacement="$(basename -- "$found")"

                if [[ "$(normalize_m3u_entry_for_compare "$replacement")" == "$(normalize_m3u_entry_for_compare "$line")" ]]; then
                    print_m3u_no_update_needed "$m3u_file"
                    continue
                fi

                if replace_single_m3u_entry "$m3u_file" "$line" "$replacement"; then
                    rc=0
                else
                    rc=$?
                fi
                if [[ $rc -eq 0 ]]; then
                    echo
                    printf '%s
' "OLD: $display_entry"
                    printf '%s
' "NEW: $replacement"
                    emit_wrap_labeled_stdout "M3U UPDATED: " "${CYAN}M3U UPDATED:${RESET} " "$m3u_file"
                elif [[ $rc -eq 3 ]]; then
                    print_m3u_no_update_needed "$m3u_file"
                else
                    echo
                    printf '%s
' "OLD: $display_entry"
                    printf '%s
' "NEW: $replacement"
                    printf '%s
' "M3U SKIP: replacement was prepared but updating the playlist file failed."
                    printf '%s
' "  FILE:         $m3u_file"
                    printf '%s
' "  ENTRY:        $display_entry"
                    printf '%s
' "  REPLACEMENT:  $replacement"
                fi
            else
                printf '%s
' "M3U SKIP: no similar file was found in the playlist subtree."
                printf '%s
' "  FILE:         $m3u_file"
                printf '%s
' "  ENTRY:        $display_entry"
                printf '%s
' "  TARGET PATH:  $target"
            fi
        fi
    done < "$m3u_file"
}


check_all_m3u_files() {
    local start="${START_DIR:-.}"
    while IFS= read -r -d '' m3u; do
        check_m3u_targets "$m3u"
    done < <(find "$start" -type f -iname '*.m3u' -print0 2>/dev/null)
}


html_companion_dir_path_with_suffix() {
    local html_file="$1"
    local suffix="$2"
    local dir base stem
    dir="$(dirname -- "$html_file")"
    base="$(basename -- "$html_file")"
    stem="${base%.*}"
    printf '%s/%s%s' "$dir" "$stem" "$suffix"
}

find_html_companion_dir() {
    local html_file="$1"
    local candidate

    candidate="$(html_companion_dir_path_with_suffix "$html_file" "_files")"
    if [[ -d "$candidate" ]]; then
        printf '%s' "$candidate"
        return 0
    fi

    candidate="$(html_companion_dir_path_with_suffix "$html_file" "_pliki")"
    if [[ -d "$candidate" ]]; then
        printf '%s' "$candidate"
        return 0
    fi

    return 1
}

HTML_COMPANION_OLD_DIR=""
HTML_COMPANION_NEW_DIR=""
HTML_COMPANION_OLD_NAME=""
HTML_COMPANION_NEW_NAME=""
HTML_COMPANION_REFERENCE_UPDATE_ONLY=no

plan_html_companion_for_rename() {
    local old="$1"
    local new="$2"
    local old_html_stem="" companion_suffix="" candidate_companion_dir=""

    HTML_COMPANION_OLD_DIR=""
    HTML_COMPANION_NEW_DIR=""
    HTML_COMPANION_OLD_NAME=""
    HTML_COMPANION_NEW_NAME=""
    HTML_COMPANION_REFERENCE_UPDATE_ONLY=no

    is_html_file "$old" || return 0

    HTML_COMPANION_OLD_DIR="$(find_html_companion_dir "$old" || true)"
    if [[ -z "$HTML_COMPANION_OLD_DIR" ]]; then
        for companion_suffix in "_files" "_pliki"; do
            candidate_companion_dir="$(html_companion_dir_path_with_suffix "$new" "$companion_suffix")"
            if [[ -d "$candidate_companion_dir" ]]; then
                HTML_COMPANION_OLD_NAME="$(basename -- "$(html_companion_dir_path_with_suffix "$old" "$companion_suffix")")"
                HTML_COMPANION_NEW_DIR="$candidate_companion_dir"
                HTML_COMPANION_NEW_NAME="$(basename -- "$HTML_COMPANION_NEW_DIR")"
                HTML_COMPANION_REFERENCE_UPDATE_ONLY=yes
                vlog "HTML companion already exists at normalized target; will update references only: '$HTML_COMPANION_NEW_DIR'"
                break
            fi
        done
    else
        HTML_COMPANION_OLD_NAME="$(basename -- "$HTML_COMPANION_OLD_DIR")"
        old_html_stem="$(basename -- "${old%.*}")"
        companion_suffix="${HTML_COMPANION_OLD_NAME#${old_html_stem}}"
        HTML_COMPANION_NEW_DIR="$(html_companion_dir_path_with_suffix "$new" "$companion_suffix")"
        HTML_COMPANION_NEW_NAME="$(basename -- "$HTML_COMPANION_NEW_DIR")"
    fi
}

print_html_companion_plan_for_prompt() {
    local old="$1"
    local new="$2"

    plan_html_companion_for_rename "$old" "$new"

    if [[ -n "$HTML_COMPANION_OLD_DIR" && "$HTML_COMPANION_OLD_DIR" != "$HTML_COMPANION_NEW_DIR" ]]; then
        emit_wrap_labeled_stdout "HTML companion: " "${CYAN}HTML companion:${RESET} " "will rename directory and update references inside the HTML file."
        emit_wrap_labeled_stdout "  OLD DIR: " "  ${YELLOW}OLD DIR:${RESET} " "$HTML_COMPANION_OLD_DIR" yellow
        emit_wrap_labeled_stdout "  NEW DIR: " "  ${GREEN}NEW DIR:${RESET} " "$HTML_COMPANION_NEW_DIR" green
    elif [[ "$HTML_COMPANION_REFERENCE_UPDATE_ONLY" == "yes" ]]; then
        emit_wrap_labeled_stdout "HTML companion: " "${CYAN}HTML companion:${RESET} " "already exists with the new name; references inside the HTML file will be updated."
        emit_wrap_labeled_stdout "  OLD REF: " "  ${YELLOW}OLD REF:${RESET} " "$HTML_COMPANION_OLD_NAME" yellow
        emit_wrap_labeled_stdout "  NEW REF: " "  ${GREEN}NEW REF:${RESET} " "$HTML_COMPANION_NEW_NAME" green
    fi
}

directory_is_empty() {
    local dir="$1"
    [[ -d "$dir" ]] || return 1
    ! find "$dir" -mindepth 1 -print -quit 2>/dev/null | grep -q .
}

update_html_companion_reference() {
    local html_file="$1"
    local old_dir_name="$2"
    local new_dir_name="$3"

    [[ -f "$html_file" ]] || return 0

    vlog "Updating HTML companion directory reference in '$html_file': '$old_dir_name' -> '$new_dir_name'"
    preserve_timestamps_inplace "$html_file" \
        python3 - "$html_file" "$old_dir_name" "$new_dir_name" <<'PY'
import sys
from pathlib import Path
from urllib.parse import quote

path = Path(sys.argv[1])
old = sys.argv[2]
new = sys.argv[3]

data = path.read_bytes()
replacements = []

for encoding in ("utf-8", "cp1250", "iso-8859-2"):
    try:
        replacements.append((old.encode(encoding), new.encode(encoding)))
    except UnicodeEncodeError:
        pass

for safe in ("", "/"):
    old_q = quote(old, safe=safe)
    new_q = quote(new, safe=safe)
    replacements.append((old_q.encode("ascii"), new_q.encode("ascii")))
    replacements.append((old_q.lower().encode("ascii"), new_q.encode("ascii")))

seen = set()
for old_bytes, new_bytes in replacements:
    if not old_bytes or old_bytes in seen:
        continue
    seen.add(old_bytes)
    data = data.replace(old_bytes, new_bytes)

path.write_bytes(data)
PY
}

update_checksum_hash_for_ref() {
    local sum_file="$1"
    local target_ref="$2"
    local actual_file="$3"
    local kind new_hash

    kind="$(checksum_kind "$sum_file")"
    new_hash="$(checksum_of_file "$kind" "$actual_file")"

    vlog "Updating stored checksum hash in '$sum_file' for ref '$target_ref'"

    preserve_timestamps_inplace "$sum_file"         python3 - "$sum_file" "$target_ref" "$new_hash" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
target = sys.argv[2]
new_hash = sys.argv[3]

lines = path.read_text(encoding="utf-8", errors="surrogateescape").splitlines(True)
out = []
updated = False

for line in lines:
    m = re.match(r'^([0-9A-Fa-f]+)(\s+)(\*?)(.*?)(\r?\n?)$', line)
    if m and m.group(4) == target and not updated:
        out.append(new_hash + m.group(2) + m.group(3) + m.group(4) + m.group(5))
        updated = True
    else:
        out.append(line)

path.write_text(''.join(out), encoding="utf-8", errors="surrogateescape")
PY
}

checksum_kind() {
    local p="$1"
    if [[ "$p" == *.sha512 ]]; then
        printf 'sha512'
    elif [[ "$p" == *.md5 ]]; then
        printf 'md5'
    else
        return 1
    fi
}

checksum_label() {
    local p="$1"
    case "$(checksum_kind "$p")" in
        sha512) printf 'SHA512' ;;
        md5)    printf 'MD5' ;;
    esac
}

checksum_cmd() {
    local p="$1"
    case "$(checksum_kind "$p")" in
        sha512) printf 'sha512sum' ;;
        md5)    printf 'md5sum' ;;
    esac
}

count_checksum_entries() {
    local sum_file="$1"
    awk 'NF > 0 {count++} END {print count+0}' < <(extract_checksum_entries "$sum_file")
}

checksum_list_verify_state_abspath() {
    db_abs_path "$1" 2>/dev/null || printf '%s' "$1"
}

checksum_list_verify_state_filepath() {
    local sum_file="$1" abs key dir state_root
    state_root="${RENAME_CHECKSUM_VERIFY_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/rename.sh/checksum-verify}"
    abs="$(checksum_list_verify_state_abspath "$sum_file")"
    if command -v md5sum >/dev/null 2>&1; then
        key="$(printf '%s' "$abs" | md5sum | awk '{print $1}')"
    else
        key="$(printf '%s' "$abs" | cksum | awk '{print $1}')"
    fi
    [[ -n "$key" ]] || return 1
    printf '%s/%s' "$state_root" "$key"
}

# Print human-readable age like "2 days, 4h, 45 mins ago" (local wall clock).
format_epoch_relative_to_now() {
    local epoch="$1" now delta rem days hours mins
    now="$(date +%s)"
    delta=$((now - epoch))
    if (( delta < 0 )); then
        printf '%s' "in the future (clock skew?)"
        return 0
    fi
    if (( delta < 60 )); then
        printf '%s' "just now"
        return 0
    fi
    days=$((delta / 86400))
    rem=$((delta % 86400))
    hours=$((rem / 3600))
    rem=$((rem % 3600))
    mins=$((rem / 60))

    local out="" sep=""
    if (( days > 0 )); then
        if (( days == 1 )); then
            out+="${sep}1 day"
        else
            out+="${sep}${days} days"
        fi
        sep=", "
    fi
    if (( hours > 0 )); then
        out+="${sep}${hours}h"
        sep=", "
    fi
    if (( mins > 0 )); then
        if (( mins == 1 )); then
            out+="${sep}1 min"
        else
            out+="${sep}${mins} mins"
        fi
        sep=", "
    fi
    if [[ -z "$out" ]]; then
        out="${delta}s"
    fi
    printf '%s ago' "$out"
}

print_checksum_list_last_verify_for_prompt() {
    local sum_file="$1" state_path epoch stored_sig cur_sig rel

    state_path="$(checksum_list_verify_state_filepath "$sum_file" 2>/dev/null || true)"
    if [[ -z "$state_path" || ! -f "$state_path" ]]; then
        echo "Last time this list was fully verified (all entries passed): no saved record."
        return 0
    fi
    IFS=$'\t' read -r epoch stored_sig < "$state_path" || true
    if ! [[ "$epoch" =~ ^[0-9]+$ ]]; then
        echo "Last time this list was fully verified (all entries passed): no readable saved record."
        return 0
    fi
    rel="$(format_epoch_relative_to_now "$epoch")"
    echo "Last time this list was fully verified (all entries passed): $(format_epoch_human "$epoch") local time ($rel)."
    cur_sig="$(db_compute_signature "$sum_file" 2>/dev/null || true)"
    if [[ -n "$stored_sig" && -n "$cur_sig" && "$stored_sig" != "$cur_sig" ]]; then
        echo "Note: the checksum list file has changed since that verification — the time above may be stale."
    fi
}

record_checksum_list_full_verify_success() {
    local sum_file="$1" state_path dir sig epoch tmp

    [[ -f "$sum_file" ]] || return 0
    sig="$(db_compute_signature "$sum_file" 2>/dev/null)" || return 0
    [[ -n "$sig" ]] || return 0
    state_path="$(checksum_list_verify_state_filepath "$sum_file")" || return 0
    dir="$(dirname -- "$state_path")"
    mkdir -p -- "$dir" 2>/dev/null || return 0
    epoch="$(date +%s)"
    tmp="${state_path}.tmp.$$"
    printf '%s\t%s\n' "$epoch" "$sig" > "$tmp" 2>/dev/null || return 0
    mv -f -- "$tmp" "$state_path" 2>/dev/null || { rm -f -- "$tmp" 2>/dev/null || true; return 0; }
}

# Sum byte sizes of paths in a bash array (name ref) that exist as regular files (checksum targets).
sum_bytes_of_existing_regular_files_checksum_refs() {
    local -n _paths="$1"
    local p total=0 sz
    for p in "${_paths[@]}"; do
        [[ -f "$p" ]] || continue
        sz="$(get_file_size_bytes "$p")"
        if [[ "$sz" =~ ^[0-9]+$ ]]; then
            ((total += sz))
        fi
    done
    printf '%d' "$total"
}

confirm_large_hash_check() {
    local sum_file="$1"
    local label="$2"
    local line_count="$3"
    local ref_array_name="${4-}"
    local answer=""
    local total_bytes=0

    if (( line_count <= LARGE_HASHFILE_LINE_PROMPT_THRESHOLD )); then
        return 0
    fi

    if [[ -n "$ref_array_name" ]]; then
        total_bytes="$(sum_bytes_of_existing_regular_files_checksum_refs "$ref_array_name")"
    else
        total_bytes="$LARGE_HASHFILE_PROMPT_MIN_TOTAL_BYTES"
    fi

    if (( LARGE_HASHFILE_PROMPT_MIN_TOTAL_BYTES > 0 && total_bytes < LARGE_HASHFILE_PROMPT_MIN_TOTAL_BYTES )); then
        vlog "Large ${label,,} list (${line_count} lines) but total size of on-disk targets ($(format_bytes_human "$total_bytes")) is below LARGE_HASHFILE_PROMPT_MIN_TOTAL_BYTES ($(format_bytes_human "$LARGE_HASHFILE_PROMPT_MIN_TOTAL_BYTES")); verifying without prompt."
        return 0
    fi

    while true; do
        echo
        emit_wrap_labeled_stdout "${label} NOTICE: " "${YELLOW}${label} NOTICE:${RESET} " "'${sum_file}' contains ${line_count} checksum line(s)."
        echo "Checking it may take a long time."
        print_checksum_list_last_verify_for_prompt "$sum_file"
        print_prompt_view_directory_menu_line
        echo -n "$(user_prompt_ts_prefix)Check this file and continue? [y/N/v/q]: "

        flush_stdin
        read_single_key answer "$PROMPT_WAIT_SECONDS"
        echo

        if handle_prompt_directory_listing_choice "$answer" "$sum_file"; then
            continue
        fi
        case "$answer" in
            y|Y)
                return 0
                ;;
            q|Q)
                stopped_by_user=yes
                return 2
                ;;
            *)
                return 1
                ;;
        esac
    done
}

# Before [U]/[Q]: list file metadata, hash stored in the list for this ref, and on-disk file metadata + current hash.
print_checksum_mismatch_decision_context() {
    local sum_file="$1"
    local ref_in_file="$2"
    local path_on_disk="$3"
    local label="$4"
    local kind target_norm target_re matched_line stored_hash disk_hash

    kind="$(checksum_kind "$sum_file")" || kind="?"
    matched_line="$(find_checksum_line_for_ref "$sum_file" "$ref_in_file")"
    if [[ -n "$matched_line" ]]; then
        stored_hash="$(printf '%s' "$matched_line" | awk '{print tolower($1)}')"
    else
        stored_hash=""
    fi

    echo
    echo -e "${CYAN}${label} mismatch — details for your decision:${RESET}"
    emit_wrap_labeled_stdout "  Checksum list file: " "  ${CYAN}Checksum list file:${RESET} " "$sum_file"
    if [[ -f "$sum_file" ]]; then
        echo "    size:       $(format_bytes_human "$(get_file_size_bytes "$sum_file")")"
        echo "    created:    $(format_epoch_human "$(get_file_birth_epoch "$sum_file")")"
        echo "    modified:   $(format_epoch_human "$(get_file_mtime_epoch "$sum_file")")"
    else
        echo "    (not readable as a regular file here — cannot show size/times)"
    fi
    if [[ -n "$stored_hash" ]]; then
        emit_wrap_labeled_stdout "    Stored ${kind} in list for this reference: " "    ${CYAN}Stored ${kind} in list for this reference:${RESET} " "$stored_hash"
    else
        echo "    (No matching checksum line found for this reference in the list.)"
    fi

    echo
    emit_wrap_labeled_stdout "  File on disk: " "  ${CYAN}File on disk:${RESET} " "$path_on_disk"
    if [[ -f "$path_on_disk" ]]; then
        echo "    size:       $(format_bytes_human "$(get_file_size_bytes "$path_on_disk")")"
        echo "    created:    $(format_epoch_human "$(get_file_birth_epoch "$path_on_disk")")"
        echo "    modified:   $(format_epoch_human "$(get_file_mtime_epoch "$path_on_disk")")"
        disk_hash="$(checksum_of_file "$kind" "$path_on_disk" || true)"
        if [[ -n "$disk_hash" ]]; then
            emit_wrap_labeled_stdout "    Current ${kind} of file: " "    ${CYAN}Current ${kind} of file:${RESET} " "$disk_hash"
        else
            echo "    (Could not compute ${kind} for this path.)"
        fi
    else
        echo "    (not a regular file — cannot show size/times or compute ${kind})"
    fi
    echo
}

suggest_checksum_mismatch_recovery() {
    local sum_file="$1"
    local ref_in_file="$2"
    local path_on_disk="$3"
    local label="$4"
    local phase="$5"
    local sum_dir tool qdir qref

    sum_dir="$(dirname -- "$sum_file")"
    tool="$(checksum_cmd "$sum_file")"
    qdir="$(printf '%q' "$sum_dir")"
    qref="$(printf '%q' "$ref_in_file")"

    print_checksum_mismatch_decision_context "$sum_file" "$ref_in_file" "$path_on_disk" "$label"

    echo
    echo -e "${CYAN}${label} recovery hint (${phase}):${RESET}"
    echo "  The hash stored in the checksum file does not match the bytes on disk for this path."
    echo "  That usually means the file was edited, re-encoded, or replaced after the list was created,"
    echo "  or the checksum line is wrong (copy/paste, duplicate lines with different hashes)."
    if [[ -f "$path_on_disk" ]]; then
        echo "  To fix manually, re-hash from the checksum file's directory and replace that line:"
        echo "      ( cd $qdir && $tool -- $qref )"
        emit_wrap_labeled_stdout "  The path column in the list must stay exactly: " "  The path column in the list must stay exactly: " "$ref_in_file"
    else
        emit_wrap_labeled_stdout "  There is no regular file to hash at: " "  ${YELLOW}There is no regular file to hash at:${RESET} " "$path_on_disk"
    fi
    echo
}

# Return 0 if hash was updated and re-verification succeeded; 2 if user chose [I] (ignore, caller continues); 1 if user quit [Q] or invalid (caller exits).
prompt_refresh_checksum_hash_after_mismatch() {
    local sum_file="$1"
    local ref_in_file="$2"
    local path_on_disk="$3"
    local phase="$4"
    local label answer

    label="$(checksum_label "$sum_file")"
    suggest_checksum_mismatch_recovery "$sum_file" "$ref_in_file" "$path_on_disk" "$label" "$phase"

    while true; do
        emit_wrap_labeled_stdout "  [U] " "  ${GREEN}[U]${RESET} " "Update stored ${label,,} hash from the file on disk, then re-verify"
        emit_wrap_labeled_stdout "  [I] " "  ${GREEN}[I]${RESET} " "Ignore this mismatch and continue (checksum list unchanged; you fix it later)"
        print_prompt_view_directory_menu_line
        emit_wrap_labeled_stdout "  [Q] " "  ${GREEN}[Q]${RESET} " "Quit (abort script)"
        echo -n "$(user_prompt_ts_prefix)Choice [U/i/v/Q]: "
        flush_stdin
        read_single_key answer "$PROMPT_WAIT_SECONDS"
        echo
        if handle_prompt_directory_listing_choice "$answer" "$path_on_disk"; then
            continue
        fi
        case "$answer" in
            u|U)
                if [[ ! -f "$path_on_disk" ]]; then
                    emit_wrap_labeled_stdout "${label}: Cannot update - not a regular file: " "${YELLOW}${label}:${RESET} Cannot update - not a regular file: " "$path_on_disk"
                    continue
                fi
                emit_wrap_labeled_stdout "${label} FIX: Patching " "${CYAN}${label} FIX:${RESET} Patching " "'${sum_file}' (ref '${ref_in_file}') from file '${path_on_disk}'..."
                update_checksum_hash_for_ref "$sum_file" "$ref_in_file" "$path_on_disk"
                if verify_single_checksum_target "$sum_file" "$ref_in_file"; then
                    emit_wrap_labeled_stdout "${label} OK: " "${GREEN}${label} OK:${RESET} " "Stored hash now matches the file; continuing."
                    return 0
                fi
                emit_wrap_labeled_stdout "${label} WARN: " "${YELLOW}${label} WARN:${RESET} " "Still fails after patch (duplicate conflicting lines in the list, or I/O issue). Try editing the checksum file by hand."
                ;;
            i|I)
                emit_wrap_labeled_stdout "${label} IGNORE: " "${YELLOW}${label} IGNORE:${RESET} " "Continuing with stored hash for '${ref_in_file}' unchanged (${phase})."
                vlog "${label} mismatch ignored by user for ref '${ref_in_file}' (${phase})"
                return 2
                ;;
            q|Q|'')
                return 1
                ;;
            *)
                return 1
                ;;
        esac
    done
}

stop_on_checksum_failure() {
    local sum_file="$1"
    local phase="$2"
    local label
    label="$(checksum_label "$sum_file")"

    finish_current_operation
    emit_wrap_labeled_stdout "${label} ERROR: ${label} verification ${phase} failed for " "${RED}${label} ERROR:${RESET} ${label} verification ${phase} failed for " "'${sum_file}'."
    emit_wrap_labeled_stdout "STOPPING: " "${RED}STOPPING:${RESET} " "Script execution aborted because ${label} is incorrect."
    exit 1
}

# User chose [Q] (or left the mismatch menu without fixing): not the same as "hash algorithm / file is wrong".
stop_on_checksum_user_quit_after_mismatch() {
    local sum_file="$1"
    local phase="$2"
    local label
    label="$(checksum_label "$sum_file")"

    stopped_by_user=yes
    finish_current_operation
    echo
    emit_wrap_labeled_stdout "STOPPING: " "${YELLOW}STOPPING:${RESET} " "You quit ([Q]) from the ${label} mismatch prompt (${phase}). Exiting without [U] (refresh hash) or [I] (ignore)."
    emit_wrap_labeled_stdout "Note: " "${CYAN}Note:${RESET} " "This is not the same as '${label} being incorrect' — you pressed [Q] instead of [U] or [I]."
    emit_wrap_labeled_stdout "Hash list: " "${CYAN}Hash list:${RESET} " "$sum_file"
    SCRIPT_FINISH_TIME="$(date '+%Y-%m-%d %H:%M:%S')"
    print_summary
    exit 1
}

choose_r_acute_mapping_for_file() {
    local path="$1"
    local answer=""
    local repl=""
    local manual_name=""

    while true; do
        echo >&2
        echo "Filename contains ŕ:" >&2
        echo "  $path" >&2
        verbose_question_timestamp "Choose mapping for ŕ in this file:" 2
        echo "  [1] c (default)" >&2
        echo "  [2] s" >&2
        echo "  [3] c and space" >&2
        echo "  [4] s and space" >&2
        echo "  [o] Other (type replacement, Enter)" >&2
        echo "  [q] Quit" >&2
        echo "  [m] Manually edit basename" >&2
        print_prompt_view_directory_menu_line_stderr
        echo -n "$(user_prompt_ts_prefix)Choice [1/2/3/4/o/q/m/v]: " >&2
        flush_stdin
        read_single_key answer "$PROMPT_WAIT_SECONDS"
        echo >&2
        if handle_prompt_directory_listing_choice "$answer" "$path"; then
            continue
        fi
        case "$answer" in
            2) printf '%s' "s"; return 0 ;;
            3) printf '%s' "c "; return 0 ;;
            4) printf '%s' "s "; return 0 ;;
            o|O)
                echo -n "$(user_prompt_ts_prefix)Replacement for ŕ: " >&2
                read_line_editable repl "$PROMPT_WAIT_SECONDS" ""
                echo >&2
                [[ -n "$repl" ]] || continue
                printf '%s' "$repl"
                return 0
                ;;
            q|Q)
                stopped_by_user=yes
                return 0
                ;;
            m|M)
                echo "$(user_prompt_ts_prefix)New basename (filename only, including extension; empty = back to menu):" >&2
                read_line_editable manual_name "$PROMPT_WAIT_SECONDS" "$(basename -- "$path")"
                echo >&2
                if [[ -n "$manual_name" ]]; then
                    MANUAL_BASENAME_OVERRIDE="$manual_name"
                    return 0
                fi
                continue
                ;;
            1|'') printf '%s' "c"; return 0 ;;
            *) printf '%s' "c"; return 0 ;;
        esac
    done
}

choose_registered_mapping_for_file() {
    local path="$1"
    local answer=""
    local repl=""
    local manual_name=""

    while true; do
        echo >&2
        echo "Filename contains ®:" >&2
        echo "  $path" >&2
        verbose_question_timestamp "Choose mapping for ® in this file:" 2
        echo "  [1] z (default)" >&2
        echo "  [2] l" >&2
        echo "  [o] Other (type replacement, Enter)" >&2
        echo "  [q] Quit" >&2
        echo "  [m] Manually edit basename" >&2
        print_prompt_view_directory_menu_line_stderr
        echo -n "$(user_prompt_ts_prefix)Choice [1/2/o/q/m/v]: " >&2
        flush_stdin
        read_single_key answer "$PROMPT_WAIT_SECONDS"
        echo >&2
        if handle_prompt_directory_listing_choice "$answer" "$path"; then
            continue
        fi
        case "$answer" in
            2) printf '%s' "l"; return 0 ;;
            o|O)
                echo -n "$(user_prompt_ts_prefix)Replacement for ®: " >&2
                read_line_editable repl "$PROMPT_WAIT_SECONDS" ""
                echo >&2
                [[ -n "$repl" ]] || continue
                printf '%s' "$repl"
                return 0
                ;;
            q|Q)
                stopped_by_user=yes
                return 0
                ;;
            m|M)
                echo "$(user_prompt_ts_prefix)New basename (filename only, including extension; empty = back to menu):" >&2
                read_line_editable manual_name "$PROMPT_WAIT_SECONDS" "$(basename -- "$path")"
                echo >&2
                if [[ -n "$manual_name" ]]; then
                    MANUAL_BASENAME_OVERRIDE="$manual_name"
                    return 0
                fi
                continue
                ;;
            1|'') printf '%s' "z"; return 0 ;;
            *) printf '%s' "z"; return 0 ;;
        esac
    done
}

choose_at_sign_mapping_for_file() {
    local path="$1"
    local answer=""
    local repl=""
    local manual_name=""

    while true; do
        echo >&2
        echo "Filename contains @ (media file):" >&2
        echo "  $path" >&2
        verbose_question_timestamp "Choose mapping for @ in this file:" 2
        echo "  [1] a (default)" >&2
        echo "  [2] e" >&2
        echo "  [o] Other (type replacement, Enter)" >&2
        echo "  [q] Quit" >&2
        echo "  [m] Manually edit basename" >&2
        print_prompt_view_directory_menu_line_stderr
        echo -n "$(user_prompt_ts_prefix)Choice [1/2/o/q/m/v]: " >&2
        flush_stdin
        read_single_key answer "$PROMPT_WAIT_SECONDS"
        echo >&2
        if handle_prompt_directory_listing_choice "$answer" "$path"; then
            continue
        fi
        case "$answer" in
            2) printf '%s' "e"; return 0 ;;
            o|O)
                echo -n "$(user_prompt_ts_prefix)Replacement for @: " >&2
                read_line_editable repl "$PROMPT_WAIT_SECONDS" ""
                echo >&2
                [[ -n "$repl" ]] || continue
                printf '%s' "$repl"
                return 0
                ;;
            q|Q)
                stopped_by_user=yes
                return 0
                ;;
            m|M)
                echo "$(user_prompt_ts_prefix)New basename (filename only, including extension; empty = back to menu):" >&2
                read_line_editable manual_name "$PROMPT_WAIT_SECONDS" "$(basename -- "$path")"
                echo >&2
                if [[ -n "$manual_name" ]]; then
                    MANUAL_BASENAME_OVERRIDE="$manual_name"
                    return 0
                fi
                continue
                ;;
            1|'') printf '%s' "a"; return 0 ;;
            *) printf '%s' "a"; return 0 ;;
        esac
    done
}

choose_r_grave_mapping_for_file() {
    local path="$1"
    local answer=""
    local repl=""
    local manual_name=""

    while true; do
        echo >&2
        echo "Filename contains Ŕ:" >&2
        echo "  $path" >&2
        verbose_question_timestamp "Choose mapping for Ŕ in this file:" 2
        echo "  [1] c (default)" >&2
        echo "  [2] s" >&2
        echo "  [o] Other (type replacement, Enter)" >&2
        echo "  [q] Quit" >&2
        echo "  [m] Manually edit basename" >&2
        print_prompt_view_directory_menu_line_stderr
        echo -n "$(user_prompt_ts_prefix)Choice [1/2/o/q/m/v]: " >&2
        flush_stdin
        read_single_key answer "$PROMPT_WAIT_SECONDS"
        echo >&2
        if handle_prompt_directory_listing_choice "$answer" "$path"; then
            continue
        fi
        case "$answer" in
            2) printf '%s' "s"; return 0 ;;
            o|O)
                echo -n "$(user_prompt_ts_prefix)Replacement for Ŕ: " >&2
                read_line_editable repl "$PROMPT_WAIT_SECONDS" ""
                echo >&2
                [[ -n "$repl" ]] || continue
                printf '%s' "$repl"
                return 0
                ;;
            q|Q)
                stopped_by_user=yes
                return 0
                ;;
            m|M)
                echo "$(user_prompt_ts_prefix)New basename (filename only, including extension; empty = back to menu):" >&2
                read_line_editable manual_name "$PROMPT_WAIT_SECONDS" "$(basename -- "$path")"
                echo >&2
                if [[ -n "$manual_name" ]]; then
                    MANUAL_BASENAME_OVERRIDE="$manual_name"
                    return 0
                fi
                continue
                ;;
            1|'') printf '%s' "c"; return 0 ;;
            *) printf '%s' "c"; return 0 ;;
        esac
    done
}

# Spaces/brackets/punct → underscores for final basename (used on stem or whole name).
# Optional second arg preserve-leading-underscore: skip stripping leading underscores (okladka cover).
# 0 = (year >= 1980) AND (month 1-12) AND (day valid for that month, leap years honored).
# Args: YYYY MM DD (each may carry a leading zero; forced to base-10 to avoid octal parsing).
_rename_is_valid_ymd() {
    local y=$((10#$1)) m=$((10#$2)) d=$((10#$3)) dim
    (( y >= 1980 )) || return 1
    (( m >= 1 && m <= 12 )) || return 1
    case "$m" in
        1|3|5|7|8|10|12) dim=31 ;;
        4|6|9|11)        dim=30 ;;
        2) if (( (y % 4 == 0 && y % 100 != 0) || y % 400 == 0 )); then dim=29; else dim=28; fi ;;
        *) return 1 ;;
    esac
    (( d >= 1 && d <= dim )) || return 1
    return 0
}

# Anruf-aufnehmen recordings: YYMMDD in filename → YYYYMMDD (Sprache/Voice style); DDMMYY fallback if invalid.
_rename_anruf_aufnehmen_yyyymmdd_from_date6() {
    local date6="$1"
    local yy mm dd yyyy

    yy="${date6:0:2}"
    mm="${date6:2:2}"
    dd="${date6:4:2}"
    yyyy="20${yy}"
    if _rename_is_valid_ymd "$yyyy" "$mm" "$dd"; then
        printf '%s%s%s' "$yyyy" "$mm" "$dd"
        return 0
    fi
    dd="${date6:0:2}"
    mm="${date6:2:2}"
    yy="${date6:4:2}"
    yyyy="20${yy}"
    if _rename_is_valid_ymd "$yyyy" "$mm" "$dd"; then
        printf '%s%s%s' "$yyyy" "$mm" "$dd"
        return 0
    fi
    return 1
}

# Replace every validated YYYY.M(M).D(D) substring in NAME (anywhere, not only at the start).
# Boundaries: the character before and after the match must not be a digit (or start/end of string).
# Invalid calendar values (year < 1980, month/day out of range) are left unchanged.
_rename_compact_embedded_dotted_dates() {
    local s="$1"
    local -i i=0 len=${#s}
    local y m d match_len j compact

    while (( i < len )); do
        if [[ ${s:i} =~ ^([0-9]{4})\.([0-9]{1,2})\.([0-9]{1,2}) ]]; then
            y="${BASH_REMATCH[1]}"
            m="${BASH_REMATCH[2]}"
            d="${BASH_REMATCH[3]}"
            match_len=${#BASH_REMATCH[0]}
            if (( i > 0 )) && [[ ${s:i-1:1} =~ [0-9] ]]; then
                (( ++i ))
                continue
            fi
            j=$(( i + match_len ))
            if (( j < len )) && [[ ${s:j:1} =~ [0-9] ]]; then
                (( ++i ))
                continue
            fi
            if _rename_is_valid_ymd "$y" "$m" "$d"; then
                compact="$(printf '%04d%02d%02d' \
                    "$((10#${y}))" "$((10#${m}))" "$((10#${d}))")"
                s="${s:0:i}${compact}${s:j}"
                len=${#s}
                i=$(( i + 8 ))
                continue
            fi
        fi
        (( ++i ))
    done
    printf '%s' "$s"
}

# Replace every validated YYYY-M(M)-D(D) substring in NAME (anywhere, not only at the start).
_rename_compact_embedded_hyphen_dates() {
    local s="$1"
    local -i i=0 len=${#s}
    local y m d match_len j compact

    while (( i < len )); do
        if [[ ${s:i} =~ ^([0-9]{4})-([0-9]{1,2})-([0-9]{1,2}) ]]; then
            y="${BASH_REMATCH[1]}"
            m="${BASH_REMATCH[2]}"
            d="${BASH_REMATCH[3]}"
            match_len=${#BASH_REMATCH[0]}
            if (( i > 0 )) && [[ ${s:i-1:1} =~ [0-9] ]]; then
                (( ++i ))
                continue
            fi
            j=$(( i + match_len ))
            if (( j < len )) && [[ ${s:j:1} =~ [0-9] ]]; then
                (( ++i ))
                continue
            fi
            if _rename_is_valid_ymd "$y" "$m" "$d"; then
                compact="$(printf '%04d%02d%02d' \
                    "$((10#${y}))" "$((10#${m}))" "$((10#${d}))")"
                s="${s:0:i}${compact}${s:j}"
                len=${#s}
                i=$(( i + 8 ))
                continue
            fi
        fi
        (( ++i ))
    done
    printf '%s' "$s"
}

# Signal messenger exports: signal-YYYY-MM-DD-HH-MM-SS[-tail] → YYYYMMDD_HHMMSS-signal[-tail].ext
_rename_signal_timestamp_first() {
    local new="$1"
    local y m d hh mm ss ext tail ymd

    [[ "$new" =~ ^[0-9]{8}_[0-9]{6}-[Ss]ignal ]] && return 1

    # signal-YYYY-MM-DD-HH-MM-SS-tail.ext (e.g. signal-2026-06-06-12-00-47-325.jpg).
    if [[ "$new" =~ ^[Ss]ignal-([0-9]{4})-([0-9]{1,2})-([0-9]{1,2})-([0-9]{2})-([0-9]{2})-([0-9]{2})-(.+)(\.[^.]+)$ ]]; then
        y="${BASH_REMATCH[1]}"
        m="${BASH_REMATCH[2]}"
        d="${BASH_REMATCH[3]}"
        hh="${BASH_REMATCH[4]}"
        mm="${BASH_REMATCH[5]}"
        ss="${BASH_REMATCH[6]}"
        tail="${BASH_REMATCH[7]}"
        ext="${BASH_REMATCH[8]}"
        _rename_is_valid_ymd "$y" "$m" "$d" || return 1
        printf '%04d%02d%02d_%02d%02d%02d-signal-%s%s' \
            "$((10#${y}))" "$((10#${m}))" "$((10#${d}))" \
            "$((10#${hh}))" "$((10#${mm}))" "$((10#${ss}))" \
            "$tail" "$ext"
        return 0
    fi

    # signal-YYYY-MM-DD-HH-MM-SS.ext (no tail).
    if [[ "$new" =~ ^[Ss]ignal-([0-9]{4})-([0-9]{1,2})-([0-9]{1,2})-([0-9]{2})-([0-9]{2})-([0-9]{2})(\.[^.]+)$ ]]; then
        y="${BASH_REMATCH[1]}"
        m="${BASH_REMATCH[2]}"
        d="${BASH_REMATCH[3]}"
        hh="${BASH_REMATCH[4]}"
        mm="${BASH_REMATCH[5]}"
        ss="${BASH_REMATCH[6]}"
        ext="${BASH_REMATCH[7]}"
        _rename_is_valid_ymd "$y" "$m" "$d" || return 1
        printf '%04d%02d%02d_%02d%02d%02d-signal%s' \
            "$((10#${y}))" "$((10#${m}))" "$((10#${d}))" \
            "$((10#${hh}))" "$((10#${mm}))" "$((10#${ss}))" \
            "$ext"
        return 0
    fi

    # signal-YYYYMMDD-HH-MM-SS-tail.ext (date already compacted; time still hyphenated).
    if [[ "$new" =~ ^[Ss]ignal-([0-9]{8})-([0-9]{2})-([0-9]{2})-([0-9]{2})-(.+)(\.[^.]+)$ ]]; then
        ymd="${BASH_REMATCH[1]}"
        hh="${BASH_REMATCH[2]}"
        mm="${BASH_REMATCH[3]}"
        ss="${BASH_REMATCH[4]}"
        tail="${BASH_REMATCH[5]}"
        ext="${BASH_REMATCH[6]}"
        _rename_is_valid_ymd "${ymd:0:4}" "${ymd:4:2}" "${ymd:6:2}" || return 1
        printf '%s_%02d%02d%02d-signal-%s%s' \
            "$ymd" \
            "$((10#${hh}))" "$((10#${mm}))" "$((10#${ss}))" \
            "$tail" "$ext"
        return 0
    fi

    # signal-YYYY-MM-DD-HHMMSS.ext
    if [[ "$new" =~ ^[Ss]ignal-([0-9]{4})-([0-9]{1,2})-([0-9]{1,2})-([0-9]{6})(\.[^.]+)$ ]]; then
        y="${BASH_REMATCH[1]}"
        m="${BASH_REMATCH[2]}"
        d="${BASH_REMATCH[3]}"
        ext="${BASH_REMATCH[5]}"
        _rename_is_valid_ymd "$y" "$m" "$d" || return 1
        printf '%04d%02d%02d_%s-signal%s' \
            "$((10#${y}))" "$((10#${m}))" "$((10#${d}))" \
            "${BASH_REMATCH[4]}" "$ext"
        return 0
    fi

    # signal-YYYY-MM-DD-HHMMSS_tail.ext
    if [[ "$new" =~ ^[Ss]ignal-([0-9]{4})-([0-9]{1,2})-([0-9]{1,2})-([0-9]{6})_(.+)(\.[^.]+)$ ]]; then
        y="${BASH_REMATCH[1]}"
        m="${BASH_REMATCH[2]}"
        d="${BASH_REMATCH[3]}"
        ext="${BASH_REMATCH[6]}"
        _rename_is_valid_ymd "$y" "$m" "$d" || return 1
        printf '%04d%02d%02d_%s-signal-%s%s' \
            "$((10#${y}))" "$((10#${m}))" "$((10#${d}))" \
            "${BASH_REMATCH[4]}" "${BASH_REMATCH[5]}" "$ext"
        return 0
    fi

    return 1
}

# BBC / iPlayer style: ...-date_YYYY-MM-DD_HH_MM_SS[_id].ext
# DATE_PLACEMENT=front (default) → YYYYMMDD_HHMMSS_title; original → title_YYYYMMDD_HHMMSS[_tail] (before/after hyphen date compaction).
_rename_date_tag_place_output() {
    local prefix="$1"
    local tail="$2"
    local ext="$3"
    local ymd="$4"
    local hhmmss="$5"

    if [[ "$DATE_PLACEMENT" == original ]]; then
        if [[ -n "$tail" ]]; then
            printf '%s_%s_%s_%s%s' "$prefix" "$ymd" "$hhmmss" "$tail" "$ext"
        else
            printf '%s_%s_%s%s' "$prefix" "$ymd" "$hhmmss" "$ext"
        fi
        return 0
    fi

    if [[ -n "$tail" ]]; then
        printf '%s_%s_%s%s' "$ymd" "$hhmmss" "${prefix}${tail}" "$ext"
    else
        printf '%s_%s_%s%s' "$ymd" "$hhmmss" "$prefix" "$ext"
    fi
}

_rename_date_tag_timestamp_first() {
    local new="$1"
    local prefix y m d hh mm ss tail ext ymd ymd_out hhmmss_out

    [[ "$new" =~ ^[0-9]{8}_[0-9]{6}_ ]] && [[ "$new" != *-[Dd][Aa][Tt][Ee]_* ]] && return 1

    # ...-date_YYYY-MM-DD_HH_MM_SS_tail.ext
    if [[ "$new" =~ ^(.+)-[Dd][Aa][Tt][Ee]_([0-9]{4})-([0-9]{1,2})-([0-9]{1,2})_([0-9]{2})_([0-9]{2})_([0-9]{2})_(.+)(\.[^.]+)$ ]]; then
        prefix="${BASH_REMATCH[1]}"
        y="${BASH_REMATCH[2]}"
        m="${BASH_REMATCH[3]}"
        d="${BASH_REMATCH[4]}"
        hh="${BASH_REMATCH[5]}"
        mm="${BASH_REMATCH[6]}"
        ss="${BASH_REMATCH[7]}"
        tail="${BASH_REMATCH[8]}"
        ext="${BASH_REMATCH[9]}"
        _rename_is_valid_ymd "$y" "$m" "$d" || return 1
        ymd_out="$(printf '%04d%02d%02d' "$((10#${y}))" "$((10#${m}))" "$((10#${d}))")"
        hhmmss_out="$(printf '%02d%02d%02d' "$((10#${hh}))" "$((10#${mm}))" "$((10#${ss}))")"
        _rename_date_tag_place_output "$prefix" "$tail" "$ext" "$ymd_out" "$hhmmss_out"
        return 0
    fi

    # ...-date_YYYY-MM-DD_HH_MM_SS.ext (no tail after time)
    if [[ "$new" =~ ^(.+)-[Dd][Aa][Tt][Ee]_([0-9]{4})-([0-9]{1,2})-([0-9]{1,2})_([0-9]{2})_([0-9]{2})_([0-9]{2})(\.[^.]+)$ ]]; then
        prefix="${BASH_REMATCH[1]}"
        y="${BASH_REMATCH[2]}"
        m="${BASH_REMATCH[3]}"
        d="${BASH_REMATCH[4]}"
        hh="${BASH_REMATCH[5]}"
        mm="${BASH_REMATCH[6]}"
        ss="${BASH_REMATCH[7]}"
        ext="${BASH_REMATCH[8]}"
        _rename_is_valid_ymd "$y" "$m" "$d" || return 1
        ymd_out="$(printf '%04d%02d%02d' "$((10#${y}))" "$((10#${m}))" "$((10#${d}))")"
        hhmmss_out="$(printf '%02d%02d%02d' "$((10#${hh}))" "$((10#${mm}))" "$((10#${ss}))")"
        _rename_date_tag_place_output "$prefix" "" "$ext" "$ymd_out" "$hhmmss_out"
        return 0
    fi

    # ...-date_YYYYMMDD_HH_MM_SS_tail.ext (date part already compacted)
    if [[ "$new" =~ ^(.+)-[Dd][Aa][Tt][Ee]_([0-9]{8})_([0-9]{2})_([0-9]{2})_([0-9]{2})_(.+)(\.[^.]+)$ ]]; then
        prefix="${BASH_REMATCH[1]}"
        ymd="${BASH_REMATCH[2]}"
        hh="${BASH_REMATCH[3]}"
        mm="${BASH_REMATCH[4]}"
        ss="${BASH_REMATCH[5]}"
        tail="${BASH_REMATCH[6]}"
        ext="${BASH_REMATCH[7]}"
        _rename_is_valid_ymd "${ymd:0:4}" "${ymd:4:2}" "${ymd:6:2}" || return 1
        hhmmss_out="$(printf '%02d%02d%02d' "$((10#${hh}))" "$((10#${mm}))" "$((10#${ss}))")"
        _rename_date_tag_place_output "$prefix" "$tail" "$ext" "$ymd" "$hhmmss_out"
        return 0
    fi

    # ...-date_YYYYMMDD_HH_MM_SS.ext
    if [[ "$new" =~ ^(.+)-[Dd][Aa][Tt][Ee]_([0-9]{8})_([0-9]{2})_([0-9]{2})_([0-9]{2})(\.[^.]+)$ ]]; then
        prefix="${BASH_REMATCH[1]}"
        ymd="${BASH_REMATCH[2]}"
        hh="${BASH_REMATCH[3]}"
        mm="${BASH_REMATCH[4]}"
        ss="${BASH_REMATCH[5]}"
        ext="${BASH_REMATCH[6]}"
        _rename_is_valid_ymd "${ymd:0:4}" "${ymd:4:2}" "${ymd:6:2}" || return 1
        hhmmss_out="$(printf '%02d%02d%02d' "$((10#${hh}))" "$((10#${mm}))" "$((10#${ss}))")"
        _rename_date_tag_place_output "$prefix" "" "$ext" "$ymd" "$hhmmss_out"
        return 0
    fi

    return 1
}

# Title tail after Screenshot date/time (spaces → underscores; drop leading separators).
_rename_screenshot_normalize_title_tail() {
    local tail="$1"
    tail="$(_normalize_basename_separators "$tail")"
    while [[ "$tail" == _* ]]; do
        tail="${tail#_}"
    done
    printf '%s' "$tail"
}

# Screenshot_* with calendar date + clock time → YYYYMMDD_HHMMSS[-title]-screenshot.ext (timestamp first).
# Prints the new basename on stdout when matched; callers must capture once (never use as bare if-test).
_rename_screenshot_timestamp_first() {
    local new="$1"
    local y m d hh mm ss ext ymd tail_norm

    [[ "$new" =~ -[Ss]creenshot\.[^.]+$ ]] && return 1

    # Screenshot_YYYY-MM-DD-HH-MM-SS + title tail (e.g. ...-29 o prof. Miernowskim.jpg).
    if [[ "$new" =~ ^[Ss]creenshot_([0-9]{4})-([0-9]{1,2})-([0-9]{1,2})-([0-9]{2})-([0-9]{2})-([0-9]{2})([[:space:]_-].+)(\.[^.]+)$ ]]; then
        y="${BASH_REMATCH[1]}"
        m="${BASH_REMATCH[2]}"
        d="${BASH_REMATCH[3]}"
        hh="${BASH_REMATCH[4]}"
        mm="${BASH_REMATCH[5]}"
        ss="${BASH_REMATCH[6]}"
        ext="${BASH_REMATCH[8]}"
        _rename_is_valid_ymd "$y" "$m" "$d" || return 1
        tail_norm="$(_rename_screenshot_normalize_title_tail "${BASH_REMATCH[7]}")"
        printf '%04d%02d%02d_%02d%02d%02d_%s-screenshot%s' \
            "$((10#${y}))" "$((10#${m}))" "$((10#${d}))" \
            "$((10#${hh}))" "$((10#${mm}))" "$((10#${ss}))" \
            "$tail_norm" \
            "$ext"
        return 0
    fi

    # Screenshot_YYYYMMDD-HH-MM-SS + title tail.
    if [[ "$new" =~ ^[Ss]creenshot_([0-9]{8})-([0-9]{2})-([0-9]{2})-([0-9]{2})([[:space:]_-].+)(\.[^.]+)$ ]]; then
        ymd="${BASH_REMATCH[1]}"
        hh="${BASH_REMATCH[2]}"
        mm="${BASH_REMATCH[3]}"
        ss="${BASH_REMATCH[4]}"
        ext="${BASH_REMATCH[6]}"
        _rename_is_valid_ymd "${ymd:0:4}" "${ymd:4:2}" "${ymd:6:2}" || return 1
        tail_norm="$(_rename_screenshot_normalize_title_tail "${BASH_REMATCH[5]}")"
        printf '%s_%02d%02d%02d_%s-screenshot%s' \
            "$ymd" \
            "$((10#${hh}))" "$((10#${mm}))" "$((10#${ss}))" \
            "$tail_norm" \
            "$ext"
        return 0
    fi

    # Screenshot_YYYYMMDD_HHMMSS + title tail (underscore or space before title).
    if [[ "$new" =~ ^[Ss]creenshot_([0-9]{8})_([0-9]{6})[._[:space:]]+(.+)(\.[^.]+)$ ]]; then
        ymd="${BASH_REMATCH[1]}"
        _rename_is_valid_ymd "${ymd:0:4}" "${ymd:4:2}" "${ymd:6:2}" || return 1
        tail_norm="$(_rename_screenshot_normalize_title_tail "${BASH_REMATCH[3]}")"
        printf '%s_%s_%s-screenshot%s' \
            "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" \
            "$tail_norm" \
            "${BASH_REMATCH[4]}"
        return 0
    fi

    # Screenshot_YYYYMMDD-HH-MM-SS.ext (Galaxy etc.; 8-digit date before hyphenated time).
    if [[ "$new" =~ ^[Ss]creenshot_([0-9]{8})-([0-9]{2})-([0-9]{2})-([0-9]{2})(\.[^.]+)$ ]]; then
        ymd="${BASH_REMATCH[1]}"
        hh="${BASH_REMATCH[2]}"
        mm="${BASH_REMATCH[3]}"
        ss="${BASH_REMATCH[4]}"
        ext="${BASH_REMATCH[5]}"
        _rename_is_valid_ymd "${ymd:0:4}" "${ymd:4:2}" "${ymd:6:2}" || return 1
        printf '%s_%02d%02d%02d-screenshot%s' \
            "$ymd" \
            "$((10#${hh}))" "$((10#${mm}))" "$((10#${ss}))" \
            "$ext"
        return 0
    fi

    # Screenshot_YYYYMMDD_HHMMSS.ext (no extra title tail).
    if [[ "$new" =~ ^[Ss]creenshot_([0-9]{8})_([0-9]{6})(\.[^.]+)$ ]]; then
        ymd="${BASH_REMATCH[1]}"
        _rename_is_valid_ymd "${ymd:0:4}" "${ymd:4:2}" "${ymd:6:2}" || return 1
        printf '%s_%s-screenshot%s' \
            "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}"
        return 0
    fi

    # Screenshot_YYYY-MM-DD-HH-MM-SS.ext (e.g. Huawei Honor export).
    if [[ "$new" =~ ^[Ss]creenshot_([0-9]{4})-([0-9]{1,2})-([0-9]{1,2})-([0-9]{2})-([0-9]{2})-([0-9]{2})(\.[^.]+)$ ]]; then
        y="${BASH_REMATCH[1]}"
        m="${BASH_REMATCH[2]}"
        d="${BASH_REMATCH[3]}"
        hh="${BASH_REMATCH[4]}"
        mm="${BASH_REMATCH[5]}"
        ss="${BASH_REMATCH[6]}"
        ext="${BASH_REMATCH[7]}"
        _rename_is_valid_ymd "$y" "$m" "$d" || return 1
        printf '%04d%02d%02d_%02d%02d%02d-screenshot%s' \
            "$((10#${y}))" "$((10#${m}))" "$((10#${d}))" \
            "$((10#${hh}))" "$((10#${mm}))" "$((10#${ss}))" \
            "$ext"
        return 0
    fi

    # Screenshot_YYYY-MM-DD + sep + HH-MM-SS.ext or Screenshot_YYYY-MM-DD_HHMMSS.ext
    if [[ "$new" =~ ^[Ss]creenshot_([0-9]{4})-([0-9]{1,2})-([0-9]{1,2})[._-]+([0-9]{2})[._-]?([0-9]{2})[._-]?([0-9]{2})(\.[^.]+)$ ]]; then
        y="${BASH_REMATCH[1]}"
        m="${BASH_REMATCH[2]}"
        d="${BASH_REMATCH[3]}"
        hh="${BASH_REMATCH[4]}"
        mm="${BASH_REMATCH[5]}"
        ss="${BASH_REMATCH[6]}"
        ext="${BASH_REMATCH[7]}"
        _rename_is_valid_ymd "$y" "$m" "$d" || return 1
        printf '%04d%02d%02d_%02d%02d%02d-screenshot%s' \
            "$((10#${y}))" "$((10#${m}))" "$((10#${d}))" \
            "$((10#${hh}))" "$((10#${mm}))" "$((10#${ss}))" \
            "$ext"
        return 0
    fi
    if [[ "$new" =~ ^[Ss]creenshot_([0-9]{4})-([0-9]{1,2})-([0-9]{1,2})[._-]+([0-9]{6})(\.[^.]+)$ ]]; then
        y="${BASH_REMATCH[1]}"
        m="${BASH_REMATCH[2]}"
        d="${BASH_REMATCH[3]}"
        ext="${BASH_REMATCH[5]}"
        _rename_is_valid_ymd "$y" "$m" "$d" || return 1
        printf '%04d%02d%02d_%s-screenshot%s' \
            "$((10#${y}))" "$((10#${m}))" "$((10#${d}))" \
            "${BASH_REMATCH[4]}" \
            "$ext"
        return 0
    fi

    return 1
}

# After spaces/brackets -> underscores, optionally compact embedded hyphen dates (not Screenshot_* stems).
_rename_finish_basename_stem() {
    local stem="$1"
    local preserve="${2-}"
    local finished

    if [[ "$preserve" == preserve-leading-underscore ]]; then
        finished="$(_normalize_basename_separators "$stem" preserve-leading-underscore)"
    else
        finished="$(_normalize_basename_separators "$stem")"
    fi
    if [[ "$finished" =~ ^[Ss]creenshot_ ]]; then
        local _ss_fin=""
        _ss_fin="$(_rename_screenshot_timestamp_first "$finished" || true)"
        [[ -n "$_ss_fin" ]] && finished="$_ss_fin"
    elif [[ "$finished" =~ ^[Ss]ignal- ]]; then
        local _sig_fin=""
        _sig_fin="$(_rename_signal_timestamp_first "$finished" || true)"
        [[ -n "$_sig_fin" ]] && finished="$_sig_fin"
        if [[ "$finished" =~ ^[Ss]ignal- ]]; then
            finished="$(_rename_compact_embedded_hyphen_dates "$finished")"
            _sig_fin="$(_rename_signal_timestamp_first "$finished" || true)"
            [[ -n "$_sig_fin" ]] && finished="$_sig_fin"
        fi
    elif [[ "$finished" == *-[Dd][Aa][Tt][Ee]_* ]]; then
        local _dt_fin=""
        _dt_fin="$(_rename_date_tag_timestamp_first "$finished" || true)"
        [[ -n "$_dt_fin" ]] && finished="$_dt_fin"
        if [[ "$finished" == *-[Dd][Aa][Tt][Ee]_* ]]; then
            finished="$(_rename_compact_embedded_hyphen_dates "$finished")"
            _dt_fin="$(_rename_date_tag_timestamp_first "$finished" || true)"
            [[ -n "$_dt_fin" ]] && finished="$_dt_fin"
        fi
    else
        finished="$(_rename_compact_embedded_hyphen_dates "$finished")"
    fi
    printf '%s' "$finished"
}

_normalize_basename_separators() {
    local input="$1"
    local preserve="${2-}"
    if [[ "$preserve" == preserve-leading-underscore ]]; then
        printf '%s' "$input" | sed -E '
            s/[[:space:]]+/_/g;
            s/,+/_/g;
            s/;+/_/g;
            s/:+/_/g;
            s/\(+/_/g;
            s/\)+/_/g;
            s/\[+/_/g;
            s/\]+/_/g;
            s/\{+/_/g;
            s/\}+/_/g;
            s/"|'\''/_/g;
            s/_+/_/g;
            s/_+$//;
        '
    else
        printf '%s' "$input" | sed -E '
            s/[[:space:]]+/_/g;
            s/,+/_/g;
            s/;+/_/g;
            s/:+/_/g;
            s/\(+/_/g;
            s/\)+/_/g;
            s/\[+/_/g;
            s/\]+/_/g;
            s/\{+/_/g;
            s/\}+/_/g;
            s/"|'\''/_/g;
            s/_+/_/g;
            s/^_+//;
            s/_+$//;
        '
    fi
}

# "Title (N).ext" copy series: pad N using the largest index among same-directory siblings
# (still "Title (N).ext" or already "Title_N.ext" after an earlier rename in this run).
# Runs before _normalize_basename_separators (spaces/brackets → underscores).
_pad_copy_series_parenthetical_basename() {
    local new="$1"
    local original_path="$2"
    local dir stem ext_body ext_dot prefix num max_n width padded n f b
    local prefix_re title_part norm_prefix norm_prefix_re

    [[ "$new" == *.* ]] || { printf '%s' "$new"; return 0; }
    [[ -n "$original_path" && -f "$original_path" ]] || { printf '%s' "$new"; return 0; }
    is_media_file "$original_path" || { printf '%s' "$new"; return 0; }

    stem="${new%.*}"
    ext_body="${new##*.}"
    ext_dot=".$ext_body"

    [[ "$stem" =~ ^(.+[[:space:]]+)\(([0-9]+)\)$ ]] || { printf '%s' "$new"; return 0; }
    prefix="${BASH_REMATCH[1]}"
    num="${BASH_REMATCH[2]}"

    dir="$(dirname -- "$original_path")"
    max_n=$((10#$num))
    prefix_re="$(sed_escape_regex "$prefix")"
    title_part="${prefix%"${prefix##*[![:space:]]}"}"
    norm_prefix="$(_normalize_basename_separators "$title_part")"
    norm_prefix_re="$(sed_escape_regex "$norm_prefix")"

    for f in "$dir"/*; do
        [[ -e "$f" && -f "$f" ]] || continue
        b="$(basename -- "$f")"
        if [[ "$b" =~ ^${prefix_re}\(([0-9]+)\)(\.[^.]+)$ ]]; then
            [[ "${BASH_REMATCH[2],,}" == "${ext_dot,,}" ]] || continue
            n=$((10#${BASH_REMATCH[1]}))
            (( n > max_n )) && max_n=$n
        elif [[ "$b" =~ ^${norm_prefix_re}_([0-9]+)(\.[^.]+)$ ]]; then
            [[ "${BASH_REMATCH[2],,}" == "${ext_dot,,}" ]] || continue
            n=$((10#${BASH_REMATCH[1]}))
            (( n > max_n )) && max_n=$n
        fi
    done

    width=1
    if (( max_n >= 10 )); then
        width=${#max_n}
    fi
    padded="$(printf "%0${width}d" "$((10#$num))")"
    if [[ "$num" == "$padded" ]]; then
        printf '%s' "$new"
    else
        printf '%s(%s)%s' "$prefix" "$padded" "$ext_dot"
    fi
}

RENAME_EXIFTOOL_RESOLVED=""
RENAME_EXIFTOOL_MISSING_WARNED=""
# Per-run decision when exiftool is missing for GoPro/camera raw files: "" (ask) or "skip".
GOPRO_EXIFTOOL_MISSING_ACTION=""

# Resolve exiftool once: RENAME_EXIFTOOL (includes script default), then PATH. Prints path; exit 1 if unavailable.
resolve_rename_exiftool() {
    local cmd_path
    if [[ -n "$RENAME_EXIFTOOL_RESOLVED" ]]; then
        printf '%s' "$RENAME_EXIFTOOL_RESOLVED"
        return 0
    fi
    if [[ -n "$RENAME_EXIFTOOL" && -x "$RENAME_EXIFTOOL" ]]; then
        RENAME_EXIFTOOL_RESOLVED="$RENAME_EXIFTOOL"
        printf '%s' "$RENAME_EXIFTOOL_RESOLVED"
        return 0
    fi
    if cmd_path="$(command -v exiftool 2>/dev/null)" && [[ -n "$cmd_path" && -x "$cmd_path" ]]; then
        RENAME_EXIFTOOL_RESOLVED="$cmd_path"
        printf '%s' "$RENAME_EXIFTOOL_RESOLVED"
        return 0
    fi
    return 1
}

# One-time user-visible message when GoPro/camera raw files are skipped because exiftool is missing.
warn_gopro_exiftool_missing_once() {
    [[ -z "$RENAME_EXIFTOOL_MISSING_WARNED" ]] || return 0
    RENAME_EXIFTOOL_MISSING_WARNED=1
    emit_wrap_labeled_stderr "GOPRO/CAMERA: " "${YELLOW}GOPRO/CAMERA:${RESET} " "Would rename GoPro/camera raw files (GH/GX/GOPR/GP…) using exiftool metadata, but exiftool was not found — those files are left unchanged."
    emit_wrap_labeled_stderr "GOPRO/CAMERA: " "${YELLOW}GOPRO/CAMERA:${RESET} " "Tried, in order: ${RENAME_EXIFTOOL}, exiftool on PATH."
    emit_wrap_labeled_stderr "GOPRO/CAMERA: " "${YELLOW}GOPRO/CAMERA:${RESET} " "Install exiftool first, e.g. run as root: sudo bash video-pgm-install-exiftool.sh"
    emit_wrap_labeled_stderr "GOPRO/CAMERA: " "${YELLOW}GOPRO/CAMERA:${RESET} " "Override with RENAME_EXIFTOOL or EXIFLOC, e.g.: export RENAME_EXIFTOOL='/path/to/exiftool'"
    emit_wrap_labeled_stderr "GOPRO/CAMERA: " "${YELLOW}GOPRO/CAMERA:${RESET} " "Or run: EXIFLOC=/path/to/exiftool rename.sh --scope current"
    vlog "GoPro/camera rename skipped: exiftool not found (install via video-pgm-install-exiftool.sh, or set RENAME_EXIFTOOL/EXIFLOC, or install exiftool on PATH)"
}

# Ask once (per run) what to do for GoPro/camera raw files when exiftool is missing:
# install hint + [S] skip these files for the rest of this run (default) / [Q] quit.
# Writes only to stderr/tty so it never pollutes a $(transform_name ...) capture.
prompt_gopro_exiftool_missing_action() {
    local f="$1"
    local answer=""

    if [[ "$GOPRO_EXIFTOOL_MISSING_ACTION" == "skip" ]]; then
        emit_wrap_labeled_stderr "SKIP: " "${YELLOW}SKIP:${RESET} " "GoPro/camera raw file (exiftool not found): $(format_path_for_log "$f")"
        return 0
    fi

    warn_gopro_exiftool_missing_once

    while true; do
        nonverbose_progress_dot_prepare_for_prompt
        echo >&2
        echo -e "$(user_prompt_ts_prefix)${GREEN}exiftool is required to rename this GoPro/camera raw file:${RESET}" >&2
        echo "  $(format_path_for_log "$f")" >&2
        echo "  [S] Skip GoPro/camera raw files for the rest of this run (default)" >&2
        print_prompt_view_directory_menu_line_stderr
        echo "  [Q] Quit" >&2
        if (( VERBOSE == 1 )); then
            echo "[VERBOSE] [$(date '+%Y.%m.%d %H:%M:%S')] Choice [S/v/q]:" >&2
        fi
        printf '%s' "$(user_prompt_ts_prefix)Choice [S/v/q]: " >&2
        flush_stdin
        read_single_key answer "$PROMPT_WAIT_SECONDS"
        printf '\n' >&2
        if handle_prompt_directory_listing_choice "$answer" "$f"; then
            continue
        fi
        case "$answer" in
            q|Q)
                stopped_by_user=yes
                return 0
                ;;
            *)
                GOPRO_EXIFTOOL_MISSING_ACTION="skip"
                emit_wrap_labeled_stderr "SKIP: " "${YELLOW}SKIP:${RESET} " "GoPro/camera raw file (exiftool not found): $(format_path_for_log "$f")"
                return 0
                ;;
        esac
    done
}

# Print unchanged path for f (same shape as transform_name return values).
_transform_name_return_unchanged() {
    local f="$1"
    local dir base
    dir="$(dirname -- "$f")"
    base="$(basename -- "$f")"
    if [[ "$dir" == "." ]]; then
        if [[ "$f" == ./* ]]; then
            printf './%s' "$base"
        else
            printf '%s' "$base"
        fi
    else
        printf '%s/%s' "$dir" "$base"
    fi
}

# GoPro JPG raw names: legacy GOPR####.JPG and Mission 1 GP######.JPG.
gopro_camera_raw_jpg_basename_matches() {
    local base="$1"
    [[ "$base" =~ ^[gG][oO][pP][rR][0-9][0-9][0-9][0-9]\.[jJ][pP][gG]$ ]] && return 0
    [[ "$base" =~ ^[gG][pP][0-9][0-9][0-9][0-9][0-9][0-9]\.[jJ][pP][gG]$ ]] && return 0
    return 1
}

# GoPro Mission 1 (and MISSION 1 PRO metadata): readable GoPro_Mission1_Pro segment in output names.
gopro_set_mission1_pro_labels() {
    DeviceManufacturer=GoPro
    DeviceModelName=Mission1_Pro
}

# When firmware prefix is unknown, use Camera Model Name (e.g. MISSION 1 PRO -> GoPro / Mission1_Pro).
gopro_apply_camera_model_name_from_exif() {
    local exif="$1"
    local raw norm

    raw="$(printf '%s\n' "$exif" | grep 'Camera Model Name' | head -n 1 | sed 's/Camera Model Name[[:space:]]*: //' | tr -d $'\r\n')"
    [[ -n "$raw" ]] || return 1
    norm="$(printf '%s' "$raw" | tr '[:lower:]' '[:upper:]' | tr -d ' ')"
    case "$norm" in
        MISSION1PRO|MISSION1)
            gopro_set_mission1_pro_labels
            return 0
            ;;
    esac
    [[ -n "$norm" ]] || return 1
    DeviceManufacturer=GOPRO
    DeviceModelName="$norm"
    return 0
}

# GoPro-style raw names before exiftool rename (zmien-nazwe-CURRENT_DIRECTORY.sh patterns).
gopro_camera_raw_basename_matches() {
    local base="$1"
    [[ "$base" =~ ^[cCgG][hHxX][0-9][0-9][0-9][0-9][0-9][0-9](_Proxy)?\.[mM][pP]4$ ]] && return 0
    gopro_camera_raw_jpg_basename_matches "$base"
}

gopro_raw_stem_core_from_basename() {
    local bn="$1"
    local stem="${bn%.*}"

    stem="${stem%_Proxy}"
    stem="${stem%_proxy}"
    stem="${stem%_PROXY}"
    printf '%s' "$stem"
}

# GH010001.MP4 + GH020001.MP4 share GH0001 (camera prefix + segment id).
gopro_raw_basename_session_key() {
    local bn="$1"
    local stem

    stem="$(gopro_raw_stem_core_from_basename "$bn")"
    [[ "$stem" =~ ^[cCgG][hHxX][0-9]{6}$ ]] || return 1
    printf '%s%s' "${stem:0:2}" "${stem:4:4}"
}

gopro_raw_basename_chapter_id() {
    local bn="$1"
    local stem

    stem="$(gopro_raw_stem_core_from_basename "$bn")"
    [[ "$stem" =~ ^[cCgG][hHxX][0-9]{6}$ ]] || return 1
    printf '%s' "${stem:2:2}"
}

gopro_raw_session_chapter_count_in_dir() {
    local dir="$1"
    local session_key="$2"
    local -A chapters=()
    local f bn key ch
    local saved_nullglob

    [[ -n "$dir" && -n "$session_key" ]] || { printf '0'; return 0; }

    saved_nullglob="$(shopt -p nullglob || true)"
    shopt -s nullglob
    for f in "$dir"/*; do
        [[ -f "$f" ]] || continue
        bn="$(basename -- "$f")"
        gopro_camera_raw_basename_matches "$bn" || continue
        key="$(gopro_raw_basename_session_key "$bn")" || continue
        [[ "$key" == "$session_key" ]] || continue
        ch="$(gopro_raw_basename_chapter_id "$bn")"
        [[ -n "$ch" ]] || continue
        chapters["$ch"]=1
    done
    eval "$saved_nullglob"

    printf '%s' "${#chapters[@]}"
}

gopro_renamed_basename_has_part_segment() {
    [[ "$1" =~ ^[0-9]{8}_[0-9]{6}_(-__-_|-_-_)[^_]+_[^_]+_part_[0-9]{2}(_Proxy)?\.[mM][pP]4$ ]]
}

gopro_renamed_session_prefix_from_basename() {
    [[ "$1" =~ ^(.+)_part_[0-9]{2}(_Proxy)?\.[mM][pP]4$ ]] || return 1
    printf '%s' "${BASH_REMATCH[1]}"
}

gopro_renamed_basename_without_part_segment() {
    [[ "$1" =~ ^(.+)_part_[0-9]{2}(_Proxy)?(\.[mM][pP]4)$ ]] || return 1
    printf '%s%s%s' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}"
}

gopro_renamed_unique_part_count_in_dir() {
    local dir="$1"
    local prefix="$2"
    local -A part_nums=()
    local f bn p part
    local saved_nullglob

    [[ -n "$dir" && -n "$prefix" ]] || { printf '0'; return 0; }

    saved_nullglob="$(shopt -p nullglob || true)"
    shopt -s nullglob
    for f in "$dir"/*; do
        [[ -f "$f" ]] || continue
        bn="$(basename -- "$f")"
        gopro_renamed_basename_has_part_segment "$bn" || continue
        p="$(gopro_renamed_session_prefix_from_basename "$bn")" || continue
        [[ "$p" == "$prefix" ]] || continue
        [[ "$bn" =~ _part_([0-9]{2}) ]] || continue
        part_nums["${BASH_REMATCH[1]}"]=1
    done
    eval "$saved_nullglob"

    printf '%s' "${#part_nums[@]}"
}

gopro_format_camera_basename_output() {
    local ts="$1"
    local manuf="$2"
    local model="$3"
    local suffix="$4"
    local ext="$5"

    if [[ -n "$suffix" ]]; then
        printf '%s_-_-_%s_%s_%s.%s' "$ts" "$manuf" "$model" "$suffix" "$ext"
    else
        printf '%s_-_-_%s_%s.%s' "$ts" "$manuf" "$model" "$ext"
    fi
}

# Sony XAVC-S / professionalDisc: C0101.MP4 + C0101M01.XML (NonRealTimeMeta sidecar).
RENAME_SIDECAR_KIND=""

sony_clip_mp4_basename_matches() {
    local bn="$1"
    [[ "$bn" =~ ^[Cc][0-9]{4}\.[mM][pP]4$ ]]
}

sony_clip_xml_basename_matches() {
    local bn="$1"
    [[ "$bn" =~ ^[Cc][0-9]{4}[Mm]01\.[xX][mM][lL]$ ]]
}

sony_clip_media_basename_matches() {
    local bn="$1"
    sony_clip_mp4_basename_matches "$bn" || sony_clip_xml_basename_matches "$bn"
}

sony_clip_already_renamed_basename_matches() {
    local bn="$1"
    [[ "$bn" =~ ^[0-9]{8}_[0-9]{6}_(-__-_|-_-_)[A-Za-z0-9_]+_C[0-9]{4}(M01)?\.[mM][pP]4$ ]] && return 0
    [[ "$bn" =~ ^[0-9]{8}_[0-9]{6}_(-__-_|-_-_)[A-Za-z0-9_]+_C[0-9]{4}M01\.[xX][mM][lL]$ ]]
}

sony_clip_clip_stem_from_basename() {
    local bn="$1"
    local stem="${bn%.*}"
    if [[ "$stem" =~ ^([Cc][0-9]{4})[Mm]01$ ]]; then
        printf '%s' "${BASH_REMATCH[1]}"
        return 0
    fi
    if [[ "$stem" =~ ^([Cc][0-9]{4})$ ]]; then
        printf '%s' "${BASH_REMATCH[1]}"
        return 0
    fi
    return 1
}

sony_clip_resolve_xml_buddy() {
    local dir="$1" clip_stem="$2"
    local p
    for p in \
        "$dir/${clip_stem}M01.XML" "$dir/${clip_stem}M01.xml" \
        "$dir/${clip_stem}m01.XML" "$dir/${clip_stem}m01.xml"; do
        [[ -f "$p" ]] || continue
        printf '%s\n' "$p"
        return 0
    done
    return 1
}

sony_clip_resolve_mp4_buddy() {
    local dir="$1" clip_stem="$2"
    local p
    for p in \
        "$dir/${clip_stem}.MP4" "$dir/${clip_stem}.mp4" \
        "$dir/${clip_stem}.Mp4"; do
        [[ -f "$p" ]] || continue
        printf '%s\n' "$p"
        return 0
    done
    return 1
}

sony_clip_pair_other_path() {
    local f="$1" dir base clip_stem other
    [[ -f "$f" ]] || return 1
    dir="$(dirname -- "$f")"
    base="$(basename -- "$f")"
    clip_stem="$(sony_clip_clip_stem_from_basename "$base")" || return 1
    if sony_clip_mp4_basename_matches "$base"; then
        sony_clip_resolve_xml_buddy "$dir" "$clip_stem"
        return $?
    fi
    if sony_clip_xml_basename_matches "$base"; then
        sony_clip_resolve_mp4_buddy "$dir" "$clip_stem"
        return $?
    fi
    return 1
}

sony_clip_pairing_allowed() {
    local a="$1" b="$2"
    ! exception_exists_for_path "$a" && ! exception_exists_for_path "$b"
}

sony_clip_should_defer_xml() {
    local f="$1" other="$2"
    sony_clip_xml_basename_matches "$(basename -- "$f")" || return 1
    sony_clip_mp4_basename_matches "$(basename -- "$other")" || return 1
    sony_clip_pairing_allowed "$f" "$other"
}

sony_clip_should_attach_buddy() {
    local f="$1" other="$2"
    sony_clip_mp4_basename_matches "$(basename -- "$f")" || return 1
    sony_clip_xml_basename_matches "$(basename -- "$other")" || return 1
    sony_clip_pairing_allowed "$f" "$other"
}

# CreationDate value="YYYY-MM-DDTHH:MM:SS±HH:MM" → local wall-clock YYYYMMDD_HHMMSS (offset kept in XML only).
sony_clip_parse_creation_date_local_ts() {
    local iso="$1"
    if [[ "$iso" =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})[Tt]([0-9]{2}):([0-9]{2}):([0-9]{2}) ]]; then
        printf '%s%s%s_%s%s%s' \
            "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" \
            "${BASH_REMATCH[4]}" "${BASH_REMATCH[5]}" "${BASH_REMATCH[6]}"
        return 0
    fi
    return 1
}

sony_clip_normalize_device_token() {
    local t="$1"
    t="${t^^}"
    t="${t// /_}"
    t="${t//-/_}"
    t="${t//./_}"
    printf '%s' "$t"
}

# Read manufacturer, model, CreationDate from NonRealTimeMeta XML. Prints: MANUF<TAB>MODEL<TAB>TS
sony_clip_read_xml_metadata() {
    local xml="$1"
    local manuf="" model="" iso="" ts=""
    [[ -f "$xml" && -r "$xml" ]] || return 1
    iso="$(grep -E 'CreationDate[[:space:]]+value=' -- "$xml" 2>/dev/null | head -n 1 \
        | sed -E 's/.*value="([^"]+)".*/\1/')"
    [[ -n "$iso" ]] || return 1
    ts="$(sony_clip_parse_creation_date_local_ts "$iso")" || return 1
    manuf="$(grep -E '<Device[[:space:]]' -- "$xml" 2>/dev/null | head -n 1 \
        | sed -E 's/.*manufacturer="([^"]+)".*/\1/')"
    model="$(grep -E '<Device[[:space:]]' -- "$xml" 2>/dev/null | head -n 1 \
        | sed -E 's/.*modelName="([^"]+)".*/\1/')"
    manuf="$(sony_clip_normalize_device_token "${manuf:-SONY}")"
    model="$(sony_clip_normalize_device_token "${model:-UNKNOWN}")"
    printf '%s\t%s\t%s' "$manuf" "$model" "$ts"
}

sony_clip_metadata_from_mp4_exiftool() {
    local mp4="$1"
    local exifloc exif manuf="" model="" ts=""
    exifloc="$(resolve_rename_exiftool)" || return 1
    exif="$("$exifloc" -api largefilesupport=1 "$mp4" 2>/dev/null)" || return 1
    [[ -n "$exif" ]] || return 1
    if printf '%s\n' "$exif" | grep -q 'Device Manufacturer'; then
        manuf="$(printf '%s\n' "$exif" | grep 'Device Manufacturer' | head -n 1 \
            | sed 's/Device Manufacturer[[:space:]]*: //' | tr -d $'\r\n')"
        model="$(printf '%s\n' "$exif" | grep 'Device Model Name' | head -n 1 \
            | sed 's/Device Model Name[[:space:]]*: //' | tr -d $'\r\n')"
        ts="$("$exifloc" -api largefilesupport=1 -d '%Y%m%d_%H%M%S' "$mp4" 2>/dev/null \
            | grep -E '^Create Date' | head -n 1 | sed 's/^Create Date[[:space:]]*: //' | tr -d $'\r\n')"
    fi
    [[ -n "$ts" ]] || return 1
    manuf="$(sony_clip_normalize_device_token "${manuf:-SONY}")"
    model="$(sony_clip_normalize_device_token "${model:-UNKNOWN}")"
    printf '%s\t%s\t%s' "$manuf" "$model" "$ts"
}

# suffix_stem: C0101 or C0101M01; ext without dot.
transform_sony_clip_basename() {
    local file="$1"
    local base="$2"
    local dir clip_stem suffix_stem ext meta manuf model ts xml_path mp4_path
    local _sc_line _sc_manuf _sc_model _sc_ts

    sony_clip_media_basename_matches "$base" || return 1
    sony_clip_already_renamed_basename_matches "$base" && return 1

    dir="$(dirname -- "$file")"
    ext="${base##*.}"
    clip_stem="$(sony_clip_clip_stem_from_basename "$base")" || return 1
    if sony_clip_xml_basename_matches "$base"; then
        suffix_stem="${clip_stem}M01"
        xml_path="$file"
        mp4_path="$(sony_clip_resolve_mp4_buddy "$dir" "$clip_stem" || true)"
    else
        suffix_stem="$clip_stem"
        mp4_path="$file"
        xml_path="$(sony_clip_resolve_xml_buddy "$dir" "$clip_stem" || true)"
    fi

    meta=""
    if [[ -n "$xml_path" && -f "$xml_path" ]]; then
        meta="$(sony_clip_read_xml_metadata "$xml_path" || true)"
    fi
    if [[ -z "$meta" && -n "$mp4_path" && -f "$mp4_path" ]]; then
        meta="$(sony_clip_metadata_from_mp4_exiftool "$mp4_path" || true)"
    fi
    if [[ -z "$meta" && -n "$mp4_path" && -f "$mp4_path" ]]; then
        ts="$(get_file_oldest_timestamp_yyyymmdd_hhmmss "$mp4_path")"
        [[ -n "$ts" ]] || return 1
        meta="$(printf 'SONY\tUNKNOWN\t%s' "$ts")"
        vlog "Sony clip: no XML/exiftool metadata for '$(basename -- "$base")'; using oldest file timestamp"
    fi
    [[ -n "$meta" ]] || return 1

    IFS=$'\t' read -r _sc_manuf _sc_model _sc_ts <<< "$meta"
    gopro_format_camera_basename_output "$_sc_ts" "$_sc_manuf" "$_sc_model" "$suffix_stem" "$ext"
}

perform_sony_clip_pair_plain_renames() {
    local primary_old="$1" primary_new="$2" buddy_old="$3" buddy_new="$4"
    perform_plain_entry_rename "$primary_old" "$primary_new" || return 1
    perform_plain_entry_rename "$buddy_old" "$buddy_new" || return 1
    processed["$buddy_old"]=1
    return 0
}

gopro_strip_part_state_save() {
    local state_dir
    [[ -n "${RENAME_SH_GOPRO_STATE_FILE:-}" ]] || return 0
    state_dir="$(dirname -- "$RENAME_SH_GOPRO_STATE_FILE")"
    [[ -n "$state_dir" && "$state_dir" != "." ]] && mkdir -p -- "$state_dir" 2>/dev/null || true
    printf 'AUTO_GOPRO_STRIP_PART_DIR=%s\nAUTO_GOPRO_STRIP_PART_SESSION=%s\n' \
        "$AUTO_GOPRO_STRIP_PART_DIR" "$AUTO_GOPRO_STRIP_PART_SESSION" > "$RENAME_SH_GOPRO_STATE_FILE"
}

gopro_strip_part_state_load() {
    local line key val
    [[ -n "${RENAME_SH_GOPRO_STATE_FILE:-}" && -f "$RENAME_SH_GOPRO_STATE_FILE" ]] || return 0
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" == *=* ]] || continue
        key="${line%%=*}"
        val="${line#*=}"
        case "$key" in
            AUTO_GOPRO_STRIP_PART_DIR) AUTO_GOPRO_STRIP_PART_DIR="$val" ;;
            AUTO_GOPRO_STRIP_PART_SESSION) AUTO_GOPRO_STRIP_PART_SESSION="$val" ;;
        esac
    done < "$RENAME_SH_GOPRO_STATE_FILE"
}

gopro_auto_strip_lone_part_matches() {
    local f="$1"

    gopro_strip_part_state_load
    [[ "$AUTO_GOPRO_STRIP_PART_SESSION" == yes ]] && return 0
    [[ -n "$AUTO_GOPRO_STRIP_PART_DIR" ]] || return 1
    similar_rename_dir_matches_scope "$(dirname -- "$f")" "$AUTO_GOPRO_STRIP_PART_DIR"
}

gopro_lone_part_strip_rename_candidate() {
    local f="$1"
    local new="$2"
    local old_base new_base dir prefix part_count ts_prefix

    [[ -f "$f" ]] || return 1
    [[ "$f" != "$new" ]] || return 1

    old_base="$(basename -- "$f")"
    new_base="$(basename -- "$new")"
    gopro_renamed_basename_has_part_segment "$old_base" || return 1
    [[ "$new_base" == *"_part_"* ]] && return 1

    dir="$(dirname -- "$f")"
    [[ "$dir" == "$(dirname -- "$new")" ]] || return 1

    prefix="$(gopro_renamed_session_prefix_from_basename "$old_base")" || return 1
    part_count="$(gopro_renamed_unique_part_count_in_dir "$dir" "$prefix")"
    [[ "$part_count" =~ ^[0-9]+$ ]] || return 1
    (( part_count == 1 )) || return 1

    # Allow further basename normalization on the model segment; same capture timestamp is enough.
    [[ "$old_base" =~ ^([0-9]{8}_[0-9]{6})_ ]] || return 1
    ts_prefix="${BASH_REMATCH[1]}"
    [[ "$new_base" == "${ts_prefix}"_* ]] || return 1
    return 0
}

gopro_auto_rename_lone_part_strip_matches() {
    local f="$1"
    local new="$2"

    gopro_strip_part_state_load
    gopro_lone_part_strip_rename_candidate "$f" "$new" || return 1
    [[ "$AUTO_GOPRO_STRIP_PART_SESSION" == yes ]] && return 0
    [[ -n "$AUTO_GOPRO_STRIP_PART_DIR" ]] || return 1
    similar_rename_dir_matches_scope "$(dirname -- "$f")" "$AUTO_GOPRO_STRIP_PART_DIR"
}

# Already-renamed GoPro-style name with lone _part_XX in this directory → ask to drop the part segment.
maybe_prompt_gopro_remove_lone_part_basename() {
    local f="$1"
    local base="$2"
    local dir prefix part_count stripped answer confirm

    # Not applicable is success (return 0, no output) — return 1 aborts transform_name under set -E + ERR trap in $(...).
    [[ -f "$f" ]] || return 0
    gopro_renamed_basename_has_part_segment "$base" || return 0
    dir="$(dirname -- "$f")"
    prefix="$(gopro_renamed_session_prefix_from_basename "$base")" || return 0
    part_count="$(gopro_renamed_unique_part_count_in_dir "$dir" "$prefix")"
    [[ "$part_count" =~ ^[0-9]+$ ]] || return 0
    (( part_count > 1 )) && return 0

    stripped="$(gopro_renamed_basename_without_part_segment "$base")" || return 0
    [[ "$stripped" != "$base" ]] || return 0

    if gopro_auto_strip_lone_part_matches "$f"; then
        if [[ "$mode" == "dry-run" ]]; then
            emit_wrap_labeled_stderr "GOPRO: " "${CYAN}GOPRO:${RESET} " "Auto-remove lone _part_XX: '$(basename -- "$base")' → '$(basename -- "$stripped")'."
        else
            vlog "GoPro lone _part_XX removal auto-yes: $base -> $stripped"
        fi
        printf '%s' "$stripped"
        return 0
    fi

    if [[ "$mode" == "dry-run" ]]; then
        emit_wrap_labeled_stderr "GOPRO: " "${CYAN}GOPRO:${RESET} " "Single chapter in directory — would prompt to remove _part_XX from '$(basename -- "$base")' → '$(basename -- "$stripped")'."
        printf '%s' "$stripped"
        return 0
    fi

    while true; do
        nonverbose_progress_dot_prepare_for_prompt
        echo >&2
        echo -e "$(user_prompt_ts_prefix)${GREEN}This GoPro file is the only chapter here but its name still has _part_XX:${RESET}" >&2
        echo "  OLD: $(format_path_for_log "$f")" >&2
        echo "  NEW: $(format_path_for_log "$(dirname -- "$f")/$stripped")" >&2
        echo "  [Y] Remove _part_XX from this filename (default)" >&2
        echo "  [D] Remove _part_XX for all lone-chapter files in this directory (rest of run)" >&2
        echo "  [A] Remove _part_XX for all lone-chapter files in this run" >&2
        echo "  [N] Keep the current name" >&2
        print_prompt_view_directory_menu_line_stderr
        echo "  [Q] Quit" >&2
        if (( VERBOSE == 1 )); then
            echo "[VERBOSE] [$(date '+%Y.%m.%d %H:%M:%S')] Choice [Y/n/d/a/v/q]:" >&2
        fi
        printf '%s' "$(user_prompt_ts_prefix)Choice [Y/n/d/a/v/q]: " >&2
        flush_stdin
        read_single_key answer "$PROMPT_WAIT_SECONDS"
        printf '\n' >&2
        if handle_prompt_directory_listing_choice "$answer" "$f" "$(dirname -- "$f")/$stripped"; then
            continue
        fi
        case "$answer" in
            q|Q)
                stopped_by_user=yes
                return 2
                ;;
            n|N)
                return 0
                ;;
            d|D)
                AUTO_GOPRO_STRIP_PART_DIR="$(cd -- "$dir" 2>/dev/null && pwd -P)" || AUTO_GOPRO_STRIP_PART_DIR="$dir"
                gopro_strip_part_state_save
                vlog "Per-directory GoPro lone _part_XX strip + auto-rename enabled for '$AUTO_GOPRO_STRIP_PART_DIR'"
                printf '%s' "$stripped"
                return 0
                ;;
            a|A)
                echo "$(user_prompt_ts_prefix)⚠️  This will remove lone _part_XX from all qualifying GoPro files for the rest of this run." >&2
                if (( VERBOSE == 1 )); then
                    echo "[VERBOSE] [$(date '+%Y.%m.%d %H:%M:%S')] Are you sure? [y/N]:" >&2
                fi
                printf '%s' "$(user_prompt_ts_prefix)Are you sure? [y/N]: " >&2
                flush_stdin
                read_single_key confirm "$PROMPT_WAIT_SECONDS"
                printf '\n' >&2
                if [[ "$confirm" =~ [Yy] ]]; then
                    AUTO_GOPRO_STRIP_PART_SESSION=yes
                    gopro_strip_part_state_save
                    vlog "Session-wide GoPro lone _part_XX strip + auto-rename enabled"
                    printf '%s' "$stripped"
                    return 0
                fi
                ;;
            *)
                vlog "GoPro lone _part_XX removal accepted: $base -> $stripped"
                printf '%s' "$stripped"
                return 0
                ;;
        esac
    done
}

# Build YYYYMMDD_HHMMSS_-_-_MANUFACTURER_MODEL[_part_XX][_Proxy].ext from camera metadata (GoPro 4–12, Mission 1, Sony, Contour, LG v20).
transform_gopro_camera_basename() {
    local file="$1"
    local base="$2"
    local exifloc exif
    local czy_sony=0 czy_gopro=0 czy_contour=0 czy_LGv20=0
    local gopro4=0 DeviceManufacturer DeviceModelName
    local data_stworzenia_pliku_w_czasie_lokalnym Duration suffix_pliku ext
    local ktory_gopro TrackCreateDate CreationDateValue data

    DeviceManufacturer=xxx
    DeviceModelName=xxx
    suffix_pliku=""

    exifloc="$(resolve_rename_exiftool)" || return 1
    exif="$("$exifloc" -api largefilesupport=1 "$file" 2>/dev/null)" || return 1
    [[ -n "$exif" ]] || return 1

    ext="${base##*.}"

    if printf '%s\n' "$exif" | grep -q 'Device Manufacturer'; then
        czy_sony=1
        DeviceManufacturer="$(printf '%s\n' "$exif" | grep 'Device Manufacturer' | tr 'a-z' 'A-Z' | sed 's/DEVICE MANUFACTURER             : //' | tr -d $'\r\n')"
        DeviceModelName="$(printf '%s\n' "$exif" | grep 'Device Model Name' | tr 'a-z' 'A-Z' | sed 's/DEVICE MODEL NAME               : //' | tr -d $'\r\n')"
        CreationDateValue="$(printf '%s\n' "$exif" | grep 'Creation Date Value' | sed 's/Creation Date Value             : //' | sed 's/+.*//' | tr -d ':' | tr ' ' '_' | tr -d $'\r\n' | sed 's/-.*//')"
        data_stworzenia_pliku_w_czasie_lokalnym="$CreationDateValue"
    fi

    if printf '%s\n' "$exif" | egrep 'Compressor Name|Make   ' | grep -q GoPro; then
        czy_gopro=1
        gopro4=0
        ktory_gopro="$(printf '%s\n' "$exif" | grep 'Firmware Version' | sed 's/Firmware Version                : //' | tr -d $'\r\n' | sed 's/\..*//')"
        if [[ -z "$ktory_gopro" ]]; then
            ktory_gopro="$(printf '%s\n' "$exif" | grep 'Software                      ' | sed 's/Software                        : //' | tr -d $'\r\n' | sed 's/\..*//')"
        fi
        case "$ktory_gopro" in
            HD4) gopro4=1; DeviceManufacturer=GOPRO4; DeviceModelName=SILVER ;;
            HD6) DeviceManufacturer=GOPRO6; DeviceModelName=BLACK ;;
            HD7) DeviceManufacturer=GOPRO7; DeviceModelName=BLACK ;;
            H21) DeviceManufacturer=GOPRO10; DeviceModelName=BLACK ;;
            H23) DeviceManufacturer=GOPRO12; DeviceModelName=BLACK ;;
            H26) gopro_set_mission1_pro_labels ;;
        esac
        if [[ "$DeviceManufacturer" == xxx ]]; then
            gopro_apply_camera_model_name_from_exif "$exif" || true
        fi
        if gopro_camera_raw_jpg_basename_matches "$base"; then
            # GOPR/GP JPG often has several Create Date tags; head -n 1 must run before tr -d newline or two timestamps glue together.
            TrackCreateDate="$("$exifloc" -api largefilesupport=1 -d '%Y%m%d_%H%M%S' "$file" | egrep '^Create Date *:' | egrep -v '\.' | head -n 1 | tr 'a-z' 'A-Z' | sed 's/^CREATE DATE *: //' | tr -d ':' | tr ' ' '_' | tr -d $'\r')"
        else
            TrackCreateDate="$("$exifloc" -api largefilesupport=1 -d '%Y%m%d_%H%M%S' "$file" | grep '^Create Date' | head -n 1 | tr 'a-z' 'A-Z' | sed 's/^CREATE DATE *: //' | tr -d ':' | tr ' ' '_' | tr -d $'\r')"
        fi
        data_stworzenia_pliku_w_czasie_lokalnym="$TrackCreateDate"
    fi

    if printf '%s\n' "$exif" | grep "Compressor Name" | grep -q "Ambarella AVC encoder"; then
        czy_contour=1
        DeviceManufacturer=Contour
        DeviceModelName=2
        TrackCreateDate="$("$exifloc" -api largefilesupport=1 -d '%Y%m%d_%H%M%S' "$file" | grep 'Track Create Date' | head -n 1 | tr 'a-z' 'A-Z' | sed 's/TRACK CREATE DATE               : //' | tr -d ':' | tr ' ' '_' | tr -d $'\r')"
        data_stworzenia_pliku_w_czasie_lokalnym="$TrackCreateDate"
    fi

    if printf '%s\n' "$exif" | grep "Author" | grep -q "LG-H990ds/"; then
        czy_LGv20=1
        DeviceManufacturer=LG
        DeviceModelName=v20
        TrackCreateDate="$("$exifloc" -api largefilesupport=1 -d '%Y%m%d_%H%M%S' "$file" | grep 'Track Create Date' | head -n 1 | tr 'a-z' 'A-Z' | sed 's/TRACK CREATE DATE               : //' | tr -d ':' | tr ' ' '_' | tr -d $'\r')"
        Duration="$(printf '%s\n' "$exif" | grep 'Duration                        : ' | sed 's/Duration                        : //' | tr -d $'\r\n' | sed 's/ s$//g')"
        data="$TrackCreateDate"
        if [[ "$Duration" =~ ":" ]]; then
            Duration="$(date --utc --date "1970-01-01 $Duration" +'%s')"
        fi
        data_stworzenia_pliku_w_czasie_lokalnym="$(date --utc --date "${data:0:4}-${data:4:2}-${data:6:2} ${data:9:2}:${data:11:2}:${data:13:2} UTC - ${Duration} seconds" +"%Y%m%d_%H%M%S")"
    fi

    if (( czy_gopro == 0 && czy_sony == 0 && czy_contour == 0 && czy_LGv20 == 0 )); then
        return 1
    fi

    if [[ "$czy_gopro" == 1 && "$gopro4" == 0 && "$base" =~ ^[cCgG][hHxX][0-9][0-9][0-9][0-9][0-9][0-9] ]]; then
        local session_key chapter_count chapter_id
        session_key="$(gopro_raw_basename_session_key "$base")" || session_key=""
        if [[ -n "$session_key" ]]; then
            chapter_count="$(gopro_raw_session_chapter_count_in_dir "$(dirname -- "$file")" "$session_key")"
            if [[ "$chapter_count" =~ ^[0-9]+$ ]] && (( chapter_count > 1 )); then
                chapter_id="$(gopro_raw_basename_chapter_id "$base")"
                [[ -n "$chapter_id" ]] && suffix_pliku="part_${chapter_id}"
            fi
        fi
    fi
    if [[ "$base" == *"_Proxy"* ]]; then
        if [[ -n "$suffix_pliku" ]]; then
            suffix_pliku="${suffix_pliku}_Proxy"
        else
            # gopro_format_camera_basename_output joins model + suffix with a single '_'
            suffix_pliku="Proxy"
        fi
    fi

    [[ -n "$data_stworzenia_pliku_w_czasie_lokalnym" ]] || return 1
    [[ "$DeviceManufacturer" != xxx && "$DeviceModelName" != xxx ]] || return 1

    gopro_format_camera_basename_output \
        "$data_stworzenia_pliku_w_czasie_lokalnym" \
        "$DeviceManufacturer" \
        "$DeviceModelName" \
        "$suffix_pliku" \
        "$ext"
}

transform_basename() {
    local new="$1"
    local original_path="${2-}"
    local local_r_acute local_registered local_at_sign local_r_grave
    local _checksum_us_prefix=""

    _tb_emit() {
        _transform_basename_restore_checksum_prefix "$1" "$_checksum_us_prefix"
    }

    while true; do
        if [[ -n "${MANUAL_BASENAME_OVERRIDE-}" ]]; then
            new="$MANUAL_BASENAME_OVERRIDE"
            unset MANUAL_BASENAME_OVERRIDE
        fi

        local_r_acute="${MAP_R_ACUTE:-c}"
        local_registered="${MAP_REGISTERED:-z}"
        local_at_sign="${MAP_AT_SIGN:-a}"
        local_r_grave="${MAP_R_GRAVE:-c}"

        # choose_* must return 0 from $(...) paths: set -e treats non-zero as fatal before map_rc=$? runs.
        if [[ -n "$original_path" && "$new" == *"ŕ"* ]]; then
            local_r_acute="$(choose_r_acute_mapping_for_file "$original_path")"
            [[ "$stopped_by_user" != yes ]] || return 2
            [[ -z "${MANUAL_BASENAME_OVERRIDE-}" ]] || continue
        fi
        if [[ -n "$original_path" && "$new" == *"®"* ]]; then
            local_registered="$(choose_registered_mapping_for_file "$original_path")"
            [[ "$stopped_by_user" != yes ]] || return 2
            [[ -z "${MANUAL_BASENAME_OVERRIDE-}" ]] || continue
        fi
        if [[ -n "$original_path" && "$new" == *"Ŕ"* ]]; then
            local_r_grave="$(choose_r_grave_mapping_for_file "$original_path")"
            [[ "$stopped_by_user" != yes ]] || return 2
            [[ -z "${MANUAL_BASENAME_OVERRIDE-}" ]] || continue
        fi
        if [[ -n "$original_path" && "$new" == *"@"* ]]; then
            if is_media_file "$original_path"; then
                local_at_sign="$(choose_at_sign_mapping_for_file "$original_path")"
                [[ "$stopped_by_user" != yes ]] || return 2
                [[ -z "${MANUAL_BASENAME_OVERRIDE-}" ]] || continue
            fi
        fi

        break
    done

    while [[ "$new" == '!'* ]]; do
        new="${new#!}"
    done

    new="${new//Ä™/e}"
    new="${new//Ĺ„/n}"
    new="${new//Ä‡/c}"
    new="${new//ĹĽ/z}"
    new="${new//Ăl/o}"
    new="${new//Ĺ›/s}"
    new="${new//Ä…/a}"
    new="${new//Ĺş/z}"
    new="${new//Ĺ�/L}"
    new="${new//Ĺ»/Z}"
    new="${new//Ĺš/S}"
    new="${new//Å¼/z}"
    new="${new//ê/l}"
    new="${new//Ñ/a}"
    new="${new//¥/z}"
    new="${new//®/$local_registered}"
    new="${new//Ŕ/$local_r_grave}"
    new="${new//ŕ/$local_r_acute}"
    new="${new//ă/sc}"
    new="${new//si\`/sie_}"
    new="${new//si@/sie}"
    new="${new//Ä/s}"
    new="${new//€/c}"
    new="${new//%/ze}"
    if [[ -n "$original_path" ]]; then
        if is_media_file "$original_path"; then
            new="${new//@/$local_at_sign}"
        fi
    fi
    new="${new//Ă/s}"
    new="${new//Ăł/o}"
    new="${new//Ĺ‚/l}"

    new="${new//ą/a}"
    new="${new//ć/c}"
    new="${new//ę/e}"
    new="${new//ł/l}"
    new="${new//ń/n}"
    new="${new//ó/o}"
    new="${new//ś/s}"
    new="${new//ź/z}"
    new="${new//ż/z}"
    new="${new//Ą/A}"
    new="${new//Ć/C}"
    new="${new//Ę/E}"
    new="${new//Ł/L}"
    new="${new//Ń/N}"
    new="${new//Ó/O}"
    new="${new//Ś/S}"
    new="${new//Ź/Z}"
    new="${new//Ż/Z}"

    new="${new//•/-}"

    if [[ "$new" =~ \.jpeg$ ]]; then
        new="${new%.jpeg}.jpg"
    elif [[ "$new" =~ \.JPEG$ ]]; then
        new="${new%.JPEG}.jpg"
    fi

    new="${new//_OSiOLEK.com/}"
    new="${new//LEK.PL/}"
    new="${new//rip.by.Crisp/}"
    new="${new//._osloskop.net/}"
    new="${new//_eBook.PL/}"
    new="${new//eBook.PL/}"
    new=$(printf '%s' "$new" | sed -E 's/_ebook-pl//gI')
    new="${new//_www.osiolek.com/}"
    new="${new//www.osiolek.com/}"
    new="${new//.ebooksclub./.}"
    while [[ "$new" == *".WnA."* ]]; do
        new="${new//.WnA./.}"
    done
    new="${new//_M_and_T_Books/}"
    # [AudioBook PL], [Audiobook_PL], _AudioBook_PL, trailing "audiobook pl", any case (GNU sed).
    # _audiobook_pl must not match inside ...Player... (case-insensitive _Pl is prefix of Player).
    new=$(printf '%s' "$new" | sed -E \
        -e 's/\[audiobook[[:space:]_]+pl\]//gI' \
        -e 's/_audiobook_pl([^[:alpha:]]|$)/\1/gI' \
        -e 's/audiobook[[:space:]]+pl//gI')
    new="${new//\[eksiążki PL\]/}"
    new="${new//\[eksiazki PL\]/}"
    new="${new//_eksiazki PL_/}"
    new="${new//_eksiazki_PL_/}"

    new="${new//&/and}"

    if [[ -n "$original_path" ]] && basename_preserve_leading_underscore_file "$original_path"; then
        _checksum_us_prefix="$(checksum_file_leading_underscore_prefix "$original_path" || true)"
        if [[ -n "$_checksum_us_prefix" ]]; then
            new="${new#$_checksum_us_prefix}"
        fi
    elif basename_preserve_leading_underscore_file "$new"; then
        _checksum_us_prefix="$(checksum_file_leading_underscore_prefix "$new" || true)"
        if [[ -n "$_checksum_us_prefix" ]]; then
            new="${new#$_checksum_us_prefix}"
        fi
    fi

    # YYYY Mon DD HH-MM-SS.ext — English 3-letter month + spaces (common exports) → YYYY_Mon_DD_HH-MM-SS.ext
    local _ymd_y _ymd_mon _ymd_d _ymd_hh _ymd_mm _ymd_ss _ymd_ext _ymd_mlc _ymd_mout
    if [[ "$new" =~ ^([0-9]{4})[[:space:]]+([A-Za-z]{3})[[:space:]]+([0-9]{1,2})[[:space:]]+([0-9]{2})-([0-9]{2})-([0-9]{2})(\.[^.]+)$ ]]; then
        _ymd_y="${BASH_REMATCH[1]}"
        _ymd_mon="${BASH_REMATCH[2]}"
        _ymd_d="${BASH_REMATCH[3]}"
        _ymd_hh="${BASH_REMATCH[4]}"
        _ymd_mm="${BASH_REMATCH[5]}"
        _ymd_ss="${BASH_REMATCH[6]}"
        _ymd_ext="${BASH_REMATCH[7]}"
        _ymd_mlc="${_ymd_mon,,}"
        case "$_ymd_mlc" in
            jan) _ymd_mout="Jan" ;; feb) _ymd_mout="Feb" ;; mar) _ymd_mout="Mar" ;; apr) _ymd_mout="Apr" ;;
            may) _ymd_mout="May" ;; jun) _ymd_mout="Jun" ;; jul) _ymd_mout="Jul" ;; aug) _ymd_mout="Aug" ;;
            sep) _ymd_mout="Sep" ;; oct) _ymd_mout="Oct" ;; nov) _ymd_mout="Nov" ;; dec) _ymd_mout="Dec" ;;
            *) _ymd_mout="" ;;
        esac
        if [[ -n "$_ymd_mout" ]]; then
            _tb_emit "$(printf '%s_%s_%02d_%s-%s-%s%s' "$_ymd_y" "$_ymd_mout" "$((10#${_ymd_d}))" "$_ymd_hh" "$_ymd_mm" "$_ymd_ss" "$_ymd_ext")"
            return
        fi
    fi

    if [[ "$new" =~ ^([0-9]{2})([0-9]{2})([0-9]{2})_([0-9]{6})_-_(.+)(\.[^.]+)$ ]]; then
        _tb_emit "$(printf '20%s%s%s_%s_-_%s%s' \
            "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" \
            "${BASH_REMATCH[4]}" \
            "${BASH_REMATCH[5]}" \
            "${BASH_REMATCH[6]}")"
        return
    fi

    # YYYY.MM.DD-YYYY.MM.DD[_tail] — date range → YYYYMMDD-YYYYMMDD_tail (trip folders etc.; must run before single YYYY.MM.DD- rule).
    if [[ "$new" =~ ^([0-9]{4})\.([0-9]{2})\.([0-9]{2})-([0-9]{4})\.([0-9]{2})\.([0-9]{2})(.*)$ ]]; then
        _tb_emit "$(printf '%s%s%s-%s%s%s%s' \
            "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" \
            "${BASH_REMATCH[4]}" "${BASH_REMATCH[5]}" "${BASH_REMATCH[6]}" \
            "${BASH_REMATCH[7]}")"
        return
    fi

    # YYYY.MM.DD-YYYY.MM-DD[_tail] — mixed dotted/hyphen end date (e.g. ...13-...03-17-ZRH) → YYYYMMDD-YYYYMMDD_tail.
    if [[ "$new" =~ ^([0-9]{4})\.([0-9]{2})\.([0-9]{2})-([0-9]{4})\.([0-9]{2})-([0-9]{2})(.*)$ ]]; then
        _tb_emit "$(printf '%s%s%s-%s%s%s%s' \
            "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" \
            "${BASH_REMATCH[4]}" "${BASH_REMATCH[5]}" "${BASH_REMATCH[6]}" \
            "${BASH_REMATCH[7]}")"
        return
    fi

    # YYYY.MM.DD <sep> HH<sep>MM<sep>SS [<sep> tail].ext -> YYYYMMDD_HHMMSS[_tail].ext
    # Dotted calendar date + separated clock time (dots/underscores/hyphens/spaces between the
    # date and time and between H/M/S), any extension. Covers checksum sidecars and exports like
    # 2018.05.02__21_02_56__EdgeNY_etc_root.sha512 -> 20180502_210256_EdgeNY_etc_root.sha512.
    if [[ "$new" =~ ^([0-9]{4})\.([0-9]{2})\.([0-9]{2})[[:space:]_.-]+([0-9]{2})[._-]([0-9]{2})[._-]([0-9]{2})(.*)(\.[^.]+)$ ]]; then
        local _dotdate_time_out
        _dotdate_time_out="$(printf '%s%s%s_%s%s%s%s%s' \
            "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" \
            "${BASH_REMATCH[4]}" "${BASH_REMATCH[5]}" "${BASH_REMATCH[6]}" \
            "${BASH_REMATCH[7]}" \
            "${BASH_REMATCH[8]}")"
        _tb_emit "$(_normalize_basename_separators "$_dotdate_time_out")"
        return
    fi

    # YYYY.MM.DD-tail.ext -> YYYYMMDD_tail.ext (dotted calendar date before hyphen + title; any extension).
    if [[ "$new" =~ ^([0-9]{4})\.([0-9]{2})\.([0-9]{2})-(.+)(\.[^.]+)$ ]]; then
        _tb_emit "$(printf '%s%s%s_%s%s' \
            "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" \
            "${BASH_REMATCH[4]}" \
            "${BASH_REMATCH[5]}")"
        return
    fi

    # Leading dotted calendar date YYYY.M(M).D(D) followed by ANY non-digit separator (space, _, -, .)
    # or end of name. Month/day may be 1 or 2 digits; the date is validated (year >= 1980, month 1-12,
    # day valid for that month incl. leap years) so non-dates like 1.2.3 or 2018.13.40 are left alone.
    # -> YYYYMMDD + rest, then normalize (spaces/brackets -> underscores, collapse).
    # e.g. "2018.03.16 - LGUS996238c749 - offline backup LG Pawla.sha512"
    #   -> "20180316_-_LGUS996238c749_-_offline_backup_LG_Pawla.sha512"
    if [[ "$new" =~ ^([0-9]{4})\.([0-9]{1,2})\.([0-9]{1,2})([^0-9].*)?$ ]] \
        && _rename_is_valid_ymd "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}"; then
        local _lead_date_out
        _lead_date_out="$(printf '%04d%02d%02d%s' \
            "$((10#${BASH_REMATCH[1]}))" "$((10#${BASH_REMATCH[2]}))" "$((10#${BASH_REMATCH[3]}))" \
            "${BASH_REMATCH[4]}")"
        _tb_emit "$(_normalize_basename_separators "$_lead_date_out")"
        return
    fi

    # Windows Screenshot / Snip & Sketch: "Screenshot YYYY-MM-DD HHMMSS.ext" (spaces still present).
    if [[ "$new" =~ ^([Ss]creenshot)[[:space:]]+([0-9]{4})-([0-9]{1,2})-([0-9]{1,2})[[:space:]]+([0-9]{6})(\.[^.]+)$ ]]; then
        if _rename_is_valid_ymd "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" "${BASH_REMATCH[4]}"; then
            _tb_emit "$(printf '%04d%02d%02d_%s-screenshot%s' \
                "$((10#${BASH_REMATCH[2]}))" "$((10#${BASH_REMATCH[3]}))" "$((10#${BASH_REMATCH[4]}))" \
                "${BASH_REMATCH[5]}" "${BASH_REMATCH[6]}")"
            return
        fi
    fi

    # ...-date_YYYY-MM-DD_HH_MM_SS[_tail].ext → YYYYMMDD_HHMMSS_... (before hyphen date compaction).
    local _date_tag_out=""
    _date_tag_out="$(_rename_date_tag_timestamp_first "$new" || true)"
    if [[ -n "$_date_tag_out" ]]; then
        _tb_emit "$(_normalize_basename_separators "$_date_tag_out")"
        return
    fi

    # Signal signal-YYYY-MM-DD-HH-MM-SS[-tail] → YYYYMMDD_HHMMSS-signal[-tail].ext (before hyphen date compaction).
    local _sig_ts_out=""
    _sig_ts_out="$(_rename_signal_timestamp_first "$new" || true)"
    if [[ -n "$_sig_ts_out" ]]; then
        _tb_emit "$_sig_ts_out"
        return
    fi

    # Screenshot_* with embedded date+time → YYYYMMDD_HHMMSS-screenshot.ext (before hyphen date compaction).
    local _ss_ts_out=""
    _ss_ts_out="$(_rename_screenshot_timestamp_first "$new" || true)"
    if [[ -n "$_ss_ts_out" ]]; then
        _tb_emit "$_ss_ts_out"
        return
    fi

    # Embedded dotted calendar date anywhere in the stem (e.g. as_of_2021.11.01_040001 in a config backup name).
    # Runs after start-anchored dotted rules so YYYY.MM.DD + time at the beginning is still handled above.
    new="$(_rename_compact_embedded_dotted_dates "$new")"
    if [[ ! "$new" =~ ^[Ss]creenshot_ ]]; then
        new="$(_rename_compact_embedded_hyphen_dates "$new")"
    fi

    # Signal (again): catch signal-YYYYMMDD-HH-MM-SS-tail after hyphen date compaction, or names compaction ran on anyway.
    _sig_ts_out="$(_rename_signal_timestamp_first "$new" || true)"
    if [[ -n "$_sig_ts_out" ]]; then
        _tb_emit "$_sig_ts_out"
        return
    fi

    # ...-date_YYYYMMDD_HH_MM_SS (again, after hyphen date compaction).
    _date_tag_out="$(_rename_date_tag_timestamp_first "$new" || true)"
    if [[ -n "$_date_tag_out" ]]; then
        _tb_emit "$(_normalize_basename_separators "$_date_tag_out")"
        return
    fi

    # Underscore or whitespace between date and time (e.g. camera exports "2010-02-20 14-28-18  title.NEF").
    # Early return must still pass through _normalize_basename_separators (otherwise title tail spaces are left as-is).
    if [[ "$new" =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})[[:space:]_]+([0-9]{2})-([0-9]{2})-([0-9]{2})(.+)(\.[^.]+)$ ]]; then
        local _cam_date_time_out
        _cam_date_time_out="$(printf '%s%s%s_%s%s%s%s%s' \
            "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" \
            "${BASH_REMATCH[4]}" "${BASH_REMATCH[5]}" "${BASH_REMATCH[6]}" \
            "${BASH_REMATCH[7]}" \
            "${BASH_REMATCH[8]}")"
        _tb_emit "$(_normalize_basename_separators "$_cam_date_time_out")"
        return
    fi

    # WhatsApp / gallery-style "IMG-YYYYMMDD-rest.ext" or "VID-YYYYMMDD-rest.ext" → "YYYYMMDD_IMG-rest.ext" / "YYYYMMDD_VID-rest.ext" (then normalize).
    if [[ "$new" =~ ^([Ii][Mm][Gg]|[Vv][Ii][Dd])-([0-9]{8})-(.+)(\.[^.]+)$ ]]; then
        local _img_vid_date_out
        _img_vid_date_out="$(printf '%s_%s-%s%s' \
            "${BASH_REMATCH[2]}" \
            "${BASH_REMATCH[1]}" \
            "${BASH_REMATCH[3]}" \
            "${BASH_REMATCH[4]}")"
        _tb_emit "$(_normalize_basename_separators "$_img_vid_date_out")"
        return
    fi

    # Trailing "-YYYY-MM-DD-HH-MM-SS.ext" (export/screenshot style) → "YYYYMMDD_HHMMSS_title.ext" (timestamp first; then normalize).
    if [[ "$new" =~ ^(.+)-([0-9]{4})-([0-9]{2})-([0-9]{2})-([0-9]{2})-([0-9]{2})-([0-9]{2})(\.[^.]+)$ ]]; then
        local _tail_hy_dt_out
        _tail_hy_dt_out="$(printf '%s%s%s_%s%s%s_%s%s' \
            "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" "${BASH_REMATCH[4]}" \
            "${BASH_REMATCH[5]}" "${BASH_REMATCH[6]}" "${BASH_REMATCH[7]}" \
            "${BASH_REMATCH[1]}" \
            "${BASH_REMATCH[8]}")"
        _tb_emit "$(_normalize_basename_separators "$_tail_hy_dt_out")"
        return
    fi

    if [[ "$new" =~ ^([0-9]{8})-([0-9]{6})_-_(.+)(\.[^.]+)$ ]]; then
        _tb_emit "$(printf '%s_%s_-_%s%s' \
            "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" \
            "${BASH_REMATCH[3]}" \
            "${BASH_REMATCH[4]}")"
        return
    fi

    if [[ "$new" =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})-([0-9]{2})-([0-9]{2})-([0-9]{2})-(.+)(\.[^.]+)$ ]]; then
        _tb_emit "$(printf '%s%s%s_%s%s%s-%s%s' \
            "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" \
            "${BASH_REMATCH[4]}" "${BASH_REMATCH[5]}" "${BASH_REMATCH[6]}" \
            "${BASH_REMATCH[7]}" \
            "${BASH_REMATCH[8]}")"
        return
    fi

    new=$(printf '%s' "$new" | sed -E '
        s/--+/-/g;
        s/  +/ /g;
        s/^ +//;
        s/ +$//;
        s/\.\.+/./g;
        s/__+/_/g;
        s/_\././g;
        s/_$//;
        s/\.$//;
    ')

    if [[ -n "$original_path" && -f "$original_path" ]] && is_media_file "$original_path"; then
        new="$(_pad_copy_series_parenthetical_basename "$new" "$original_path")"
    fi

    # Directories do not use file extensions; dots in the name are part of the title (e.g. Foo.PL - bar).
    if [[ -n "$original_path" && -d "$original_path" ]]; then
        _tb_emit "$(_rename_finish_basename_stem "$new")"
    elif [[ "$new" == *.* ]]; then
        local stem ext ext_body
        stem="${new%.*}"
        ext_body="${new##*.}"
        # Suffix with spaces/brackets is not a real extension (site.PL - subtitle, tags); normalize whole basename.
        if [[ "$ext_body" == *[[:space:]]* || "$ext_body" == *'['* || "$ext_body" == *']'* ]]; then
            if is_okladka_cover_keep_leading_underscore "$new" \
                || { [[ -n "$original_path" ]] && basename_preserve_leading_underscore_file "$original_path"; } \
                || basename_preserve_leading_underscore_file "$new"; then
                _tb_emit "$(_rename_finish_basename_stem "$new" preserve-leading-underscore)"
            else
                _tb_emit "$(_rename_finish_basename_stem "$new")"
            fi
        else
            ext=".$ext_body"
            if is_okladka_cover_keep_leading_underscore "${stem}${ext}" \
                || { [[ -n "$original_path" ]] && basename_preserve_leading_underscore_file "$original_path"; } \
                || basename_preserve_leading_underscore_file "${stem}${ext}"; then
                stem="$(_rename_finish_basename_stem "$stem" preserve-leading-underscore)"
            else
                stem="$(_rename_finish_basename_stem "$stem")"
            fi
            _tb_emit "${stem}${ext}"
        fi
    else
        _tb_emit "$(_rename_finish_basename_stem "$new")"
    fi
}

transform_name() {
    local f="$1"
    local dir base newbase ts stem ext media_suffix media_date media_time media_kind yy
    local dup_stem dup_ext1 dup_ext2
    local audio_ext_re common_media_ext_re

    dir="$(dirname -- "$f")"
    base="$(basename -- "$f")"
    audio_ext_re='(mp3|aac|m4a|flac|ogg|oga|opus|wav|wma|alac|aiff|ape|mka|mp2|mp1|ac3)'
    common_media_ext_re='(mp3|aac|m4a|flac|ogg|oga|opus|wav|wma|alac|aiff|ape|mka|mp2|mp1|ac3|mp4|m4v|mov|mkv|webm|avi|jpg|jpeg|png|gif|webp|heic|heif|bmp|nef|psb|psd|psdt|tif|tiff|xmp)'

    if [[ -f "$f" ]] && is_protected_par2_name "$f"; then
        if [[ "$dir" == "." ]]; then
            if [[ "$f" == ./* ]]; then
                printf './%s' "$base"
            else
                printf '%s' "$base"
            fi
        else
            printf '%s/%s' "$dir" "$base"
        fi
        return 0
    fi

    if [[ -f "$f" ]] && is_protected_checksum_name "$f"; then
        if [[ "$dir" == "." ]]; then
            if [[ "$f" == ./* ]]; then
                printf './%s' "$base"
            else
                printf '%s' "$base"
            fi
        else
            printf '%s/%s' "$dir" "$base"
        fi
        return 0
    fi

    if path_has_control_chars "$base"; then
        base="$(sanitize_basename_control_chars "$base")"
    fi

    if is_media_file "$base" && ! is_okladka_cover_keep_leading_underscore "$base"; then
        while [[ "$base" == _* ]]; do
            base="${base#_}"
        done
    fi

    local _gopro_applied=0 _gopro_try="" _gopro_rc=0 _gopro_part_strip=""
    local _sony_applied=0 _sony_try="" _sony_rc=0
    if [[ -f "$f" ]] && sony_clip_media_basename_matches "$base"; then
        local _tn_save_e_sc=0
        [[ $- == *e* ]] && _tn_save_e_sc=1
        set +e
        _sony_try="$(transform_sony_clip_basename "$f" "$base")"
        _sony_rc=$?
        if ((_tn_save_e_sc)); then
            set -e
        else
            set +e
        fi
        if (( _sony_rc == 0 )) && [[ -n "$_sony_try" ]]; then
            newbase="$_sony_try"
            _sony_applied=1
            vlog "Sony clip rename: $base -> $_sony_try"
        else
            vlog "Sony clip rename: no usable metadata for $base (rc=$_sony_rc); falling back to normal rename"
        fi
    fi

    if [[ -f "$f" ]] && (( _sony_applied == 0 )) && gopro_camera_raw_basename_matches "$base"; then
        if ! resolve_rename_exiftool >/dev/null; then
            prompt_gopro_exiftool_missing_action "$f"
            [[ "$stopped_by_user" != yes ]] || return 2
            _transform_name_return_unchanged "$f"
            return 0
        fi
        # transform_gopro_camera_basename returns non-zero when no usable camera
        # metadata is found (e.g. empty/dummy file or unrecognized device); guard
        # it so set -e / the ERR trap don't treat that as a fatal error.
        local _tn_save_e_gp=0
        [[ $- == *e* ]] && _tn_save_e_gp=1
        set +e
        _gopro_try="$(transform_gopro_camera_basename "$f" "$base")"
        _gopro_rc=$?
        if ((_tn_save_e_gp)); then
            set -e
        fi
        if (( _gopro_rc == 0 )) && [[ -n "$_gopro_try" ]]; then
            newbase="$_gopro_try"
            _gopro_applied=1
            vlog "GoPro/camera exiftool rename: $base -> $_gopro_try"
        else
            vlog "GoPro/camera exiftool rename: no usable metadata for $base (rc=$_gopro_rc); falling back to normal rename"
        fi
    fi

    local _olympus_applied=0 _olympus_try="" _olympus_rc=0
    if [[ -f "$f" ]] && (( _gopro_applied == 0 && _sony_applied == 0 )) && olympus_voice_recorder_raw_basename_matches "$base"; then
        local _tn_save_e_oly=0
        [[ $- == *e* ]] && _tn_save_e_oly=1
        set +e
        _olympus_try="$(transform_olympus_voice_recorder_basename "$f" "$base")"
        _olympus_rc=$?
        if ((_tn_save_e_oly)); then
            set -e
        else
            set +e
        fi
        if (( _olympus_rc == 0 )) && [[ -n "$_olympus_try" ]]; then
            newbase="$_olympus_try"
            _olympus_applied=1
            vlog "Olympus voice recorder rename: $base -> $_olympus_try"
        else
            vlog "Olympus voice recorder rename: no usable timestamp for $base (rc=$_olympus_rc); falling back to normal rename"
        fi
    fi

    if [[ -f "$f" ]] && (( _gopro_applied == 0 && _sony_applied == 0 && _olympus_applied == 0 )) && [[ "$stopped_by_user" != yes ]]; then
        local _gopro_part_rc=0 _gopro_part_err_trap=""
        local _tn_save_e_part=0
        [[ $- == *e* ]] && _tn_save_e_part=1
        set +e
        _gopro_part_err_trap="$(trap -p ERR || true)"
        trap - ERR
        _gopro_part_strip="$(maybe_prompt_gopro_remove_lone_part_basename "$f" "$base")"
        _gopro_part_rc=$?
        eval "${_gopro_part_err_trap:-}"
        if ((_tn_save_e_part)); then
            set -e
        else
            set +e
        fi
        if (( _gopro_part_rc == 2 )) || [[ "$stopped_by_user" == yes ]]; then
            return 2
        fi
        if (( _gopro_part_rc == 0 )) && [[ -n "$_gopro_part_strip" ]]; then
            MANUAL_BASENAME_OVERRIDE="$_gopro_part_strip"
        fi
    fi

    local _tn_save_e=0
    [[ $- == *e* ]] && _tn_save_e=1
    set +e
    if (( _gopro_applied == 0 && _sony_applied == 0 && _olympus_applied == 0 )); then
        newbase="$(transform_basename "$base" "$f")"
        tb_rc=$?
    else
        tb_rc=0
    fi
    if ((_tn_save_e)); then
        set -e
    else
        set +e
    fi
    if (( tb_rc == 2 )); then
        return 2
    fi

    if [[ -e "$f" ]]; then
        if [[ ! -d "$f" ]]; then
            while [[ "$newbase" =~ ^(.+)\.([^.]+)\.([^.]+)$ ]]; do
                dup_stem="${BASH_REMATCH[1]}"
                dup_ext1="${BASH_REMATCH[2]}"
                dup_ext2="${BASH_REMATCH[3]}"
                if [[ "${dup_ext1,,}" == "${dup_ext2,,}" ]]; then
                    newbase="${dup_stem}.${dup_ext1}"
                else
                    break
                fi
            done
        fi

        if (( _gopro_applied == 0 && _sony_applied == 0 && _olympus_applied == 0 )); then
        # YYYYMMDD + whitespace + HH-MM-SS[_tail].media -> YYYYMMDD_HH-MM-SS[_tail].media
        # (e.g. 20190202 14-28-08_0001.jpg; not covered by YYYY-MM-DD... rules above.)
        if [[ "$newbase" =~ ^([0-9]{8})[[:space:]]+([0-9]{2})-([0-9]{2})-([0-9]{2})(_[^.]*)?(\.${common_media_ext_re})$ ]]; then
            newbase="${BASH_REMATCH[1]}_${BASH_REMATCH[2]}-${BASH_REMATCH[3]}-${BASH_REMATCH[4]}${BASH_REMATCH[5]-}${BASH_REMATCH[6]}"
        fi

        # Normalize date-time media names even when they originally had a space
        # between date and time (or leading spaces before the date), e.g.
        # " 2018-02-28 22-20-15-491.mp4", "2018-02-28_22.20.15.mp4",
        # "2020-04-24-14-40-29_o_prof._Miernowskim.jpg",
        # or "2025-07-23__09_07_46-Finished_signing.jpg"
        # -> "20180228_222015-491.mp4" / "20180228_222015.mp4".
        # Title tail may start with space (before stem separator normalize) or _/- .
        if [[ "$newbase" =~ ^[[:space:]]*([0-9]{4})-([0-9]{2})-([0-9]{2})[[:space:]_-]+([0-9]{2})[-._]([0-9]{2})[-._]([0-9]{2})([[:space:]_-].*)?(\.${common_media_ext_re})$ ]]; then
            y="${BASH_REMATCH[1]}"
            mo="${BASH_REMATCH[2]}"
            d="${BASH_REMATCH[3]}"
            hh="${BASH_REMATCH[4]}"
            mm="${BASH_REMATCH[5]}"
            ss="${BASH_REMATCH[6]}"
            tail_bit="${BASH_REMATCH[7]-}"
            newbase="${y}${mo}${d}_${hh}${mm}${ss}${tail_bit}${BASH_REMATCH[8]}"
        fi

        if [[ "$newbase" =~ ^image.*\.jpg$ ]] && [[ ! "$newbase" =~ ^[0-9]{8}_[0-9]{6}_image.*\.jpg$ ]]; then
            ts="$(get_file_oldest_timestamp_yyyymmdd_hhmmss "$f")"
            newbase="${ts}_${newbase}"
        fi

        if [[ "$newbase" =~ ^video.*\.mp4$ ]] && [[ ! "$newbase" =~ ^[0-9]{8}_[0-9]{6}_video.*\.mp4$ ]]; then
            ts="$(get_file_oldest_timestamp_yyyymmdd_hhmmss "$f")"
            newbase="${ts}_${newbase}"
        fi

        # Recording*.m4a (any case): YYYYMMDD_HHMMSS_-_Recording...m4a using oldest birth vs mtime (same helper as images).
        if [[ "${newbase,,}" == recording*.m4a ]] && [[ ! "${newbase,,}" =~ ^[0-9]{8}_[0-9]{6}_-_recording.*\.m4a$ ]]; then
            ts="$(get_file_oldest_timestamp_yyyymmdd_hhmmss "$f")"
            newbase="${ts}_-_${newbase}"
        fi

        if [[ "$newbase" =~ ^IMG_([0-9]{8})_([0-9]{6})(\..+)$ ]]; then
            newbase="${BASH_REMATCH[1]}_${BASH_REMATCH[2]}-IMG_${BASH_REMATCH[1]}_${BASH_REMATCH[2]}${BASH_REMATCH[3]}"
        elif [[ "$newbase" =~ ^PXL_([0-9]{8})_([0-9]{6})([0-9]*)(\..+)$ ]]; then
            newbase="${BASH_REMATCH[1]}_${BASH_REMATCH[2]}-PXL_${BASH_REMATCH[1]}_${BASH_REMATCH[2]}${BASH_REMATCH[3]}${BASH_REMATCH[4]}"
        elif [[ "$newbase" =~ ^received_[0-9]+(\..+)$ ]]; then
            ts="$(get_file_oldest_timestamp_compact "$f")"
            newbase="${ts}-received${BASH_REMATCH[1]}"
        elif [[ "$newbase" =~ ^(IMG_[0-9]+)(\..+)$ ]]; then
            ts="$(get_file_oldest_timestamp_compact "$f")"
            newbase="${ts}-${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
        elif [[ "$newbase" =~ ^(PXL_[0-9]+)(\..+)$ ]]; then
            ts="$(get_file_oldest_timestamp_compact "$f")"
            newbase="${ts}-${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
        elif [[ "$newbase" =~ ^Screen_Recording_([0-9]{8})_([0-9]{6})_(.+)(\..+)$ ]]; then
            local screen_suffix
            screen_suffix="${BASH_REMATCH[3]}"
            screen_suffix=$(printf '%s' "$screen_suffix" | sed -E 's/[^[:alnum:]]+/-/g; s/^-+//; s/-+$//; s/-+/-/g')
            if [[ -n "$screen_suffix" ]]; then
                newbase="${BASH_REMATCH[1]}_${BASH_REMATCH[2]}-screen_recording-${screen_suffix}${BASH_REMATCH[4]}"
            else
                newbase="${BASH_REMATCH[1]}_${BASH_REMATCH[2]}-screen_recording${BASH_REMATCH[4]}"
            fi
        # Anruf aufnehmen <callee>_YYMMDD_HHMMSS.ext → YYYYMMDD_HHMMSS_<callee>_Anruf_aufnehmen.ext
        # callee = phone digits or text; after transform_basename: Anruf_aufnehmen_<callee>_YYMMDD_HHMMSS.ext
        elif [[ "${newbase,,}" =~ ^anruf_aufnehmen_(.+)_([0-9]{6})_([0-9]{6})(\.${audio_ext_re})$ ]]; then
            local anruf_id anruf_date6 anruf_time6 anruf_ext anruf_ymd
            anruf_id="${BASH_REMATCH[1]}"
            anruf_date6="${BASH_REMATCH[2]}"
            anruf_time6="${BASH_REMATCH[3]}"
            anruf_ext="${BASH_REMATCH[4]}"
            anruf_ymd="$(_rename_anruf_aufnehmen_yyyymmdd_from_date6 "$anruf_date6" || true)"
            if [[ -n "$anruf_ymd" ]]; then
                newbase="${anruf_ymd}_${anruf_time6}_${anruf_id}_Anruf_aufnehmen${anruf_ext}"
            fi
        # Call recording <callee>_YYMMDD_HHMMSS.ext → YYYYMMDD_HHMMSS_<callee>_Call_recording.ext
        # after transform_basename: Call_recording_<callee>_YYMMDD_HHMMSS.ext
        elif [[ "${newbase,,}" =~ ^call_recording_(.+)_([0-9]{6})_([0-9]{6})(\.${audio_ext_re})$ ]]; then
            local call_rec_id call_rec_date6 call_rec_time6 call_rec_ext call_rec_ymd
            call_rec_id="${BASH_REMATCH[1]}"
            call_rec_date6="${BASH_REMATCH[2]}"
            call_rec_time6="${BASH_REMATCH[3]}"
            call_rec_ext="${BASH_REMATCH[4]}"
            call_rec_ymd="$(_rename_anruf_aufnehmen_yyyymmdd_from_date6 "$call_rec_date6" || true)"
            if [[ -n "$call_rec_ymd" ]]; then
                newbase="${call_rec_ymd}_${call_rec_time6}_${call_rec_id}_Call_recording${call_rec_ext}"
            fi
        # Sprache_/Voice_ + YYMMDD + HHMMSS + optional _tail + ext (tail was required before v. 19.13).
        elif [[ "$newbase" =~ ^(Sprache|Voice)_([0-9]{6})_([0-9]{6})(_(.+))?(\..+)$ ]]; then
            media_kind="${BASH_REMATCH[1]}"
            [[ "${media_kind,,}" == sprache ]] && media_kind=sprache
            media_date="20${BASH_REMATCH[2]}"
            media_time="${BASH_REMATCH[3]}"
            media_suffix="${BASH_REMATCH[5]-}"
            media_suffix=$(printf '%s' "$media_suffix" | sed -E 's/[^[:alnum:]]+/-/g; s/^-+//; s/-+$//; s/-+/-/g')
            if [[ -n "$media_suffix" ]]; then
                newbase="${media_date}_${media_time}-${media_kind}-${media_suffix}${BASH_REMATCH[6]}"
            else
                newbase="${media_date}_${media_time}-${media_kind}${BASH_REMATCH[6]}"
            fi
        elif [[ "$newbase" =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})_([0-9]{2})-([0-9]{2})-([0-9]{2})(\.${audio_ext_re})$ ]]; then
            newbase="${BASH_REMATCH[1]}${BASH_REMATCH[2]}${BASH_REMATCH[3]}_${BASH_REMATCH[4]}${BASH_REMATCH[5]}${BASH_REMATCH[6]}${BASH_REMATCH[7]}"
        elif [[ "$newbase" =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})_at_([0-9]{1,2})\.([0-9]{1,2})\.([0-9]{1,2})(_[^.]+)?(\..+)$ ]]; then
            # e.g. 2019-12-21_at_17.57.33_3.jpg -> 20191221_175733_3.jpg
            y="${BASH_REMATCH[1]}"
            mo="${BASH_REMATCH[2]}"
            d="${BASH_REMATCH[3]}"
            hh="$(printf '%02d' "$((10#${BASH_REMATCH[4]}))")"
            mm="$(printf '%02d' "$((10#${BASH_REMATCH[5]}))")"
            ss="$(printf '%02d' "$((10#${BASH_REMATCH[6]}))")"
            tail_bit="${BASH_REMATCH[7]-}"
            newbase="${y}${mo}${d}_${hh}${mm}${ss}${tail_bit}${BASH_REMATCH[8]}"
        elif [[ "$newbase" =~ ^([0-9]{8})_at_([0-9]{1,2})[.-]([0-9]{1,2})[.-]([0-9]{1,2})(_[^.]+)?(\..+)$ ]]; then
            # e.g. 20180527_at_19.31.29.jpg -> 20180527_193129.jpg
            # and  20180527_at_19-31-29.jpg -> 20180527_193129.jpg
            ymd="${BASH_REMATCH[1]}"
            hh="$(printf '%02d' "$((10#${BASH_REMATCH[2]}))")"
            mm="$(printf '%02d' "$((10#${BASH_REMATCH[3]}))")"
            ss="$(printf '%02d' "$((10#${BASH_REMATCH[4]}))")"
            tail_bit="${BASH_REMATCH[5]-}"
            newbase="${ymd}_${hh}${mm}${ss}${tail_bit}${BASH_REMATCH[6]}"
        elif [[ "$newbase" =~ ^([0-9]{8})-([0-9]{6})_(.+)(\.${common_media_ext_re})$ ]]; then
            media_suffix="${BASH_REMATCH[3]}"
            media_suffix=$(printf '%s' "$media_suffix" | sed -E 's/[^[:alnum:]]+/-/g; s/^-+//; s/-+$//; s/-+/-/g')
            if [[ -n "$media_suffix" ]]; then
                newbase="${BASH_REMATCH[1]}_${BASH_REMATCH[2]}-${media_suffix}${BASH_REMATCH[4]}"
            else
                newbase="${BASH_REMATCH[1]}_${BASH_REMATCH[2]}${BASH_REMATCH[4]}"
            fi
        fi
        fi
    fi

    if is_media_file "$newbase"; then
        if ! is_okladka_cover_keep_leading_underscore "$newbase"; then
            while [[ "$newbase" == _* ]]; do
                newbase="${newbase#_}"
            done
        fi
        if [[ "$newbase" =~ ^([0-9])\.(mp3|aac|m4a|flac|ogg|oga|opus|wav|wma|alac|aiff|ape|mka|mp2|mp1|ac3|mp4|m4v|mov|mkv|webm|avi)$ ]]; then
            newbase="0${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
        fi
    fi

    if [[ ! -d "$f" && "$newbase" == *.* ]]; then
        stem="${newbase%.*}"
        ext="${newbase##*.}"
        if (( _olympus_applied == 0 )) && [[ "$ext" != "${ext,,}" ]]; then
            newbase="${stem}.${ext,,}"
        fi
    fi

    if [[ "$dir" == "." ]]; then
        if [[ "$f" == ./* ]]; then
            printf './%s' "$newbase"
        else
            printf '%s' "$newbase"
        fi
    else
        printf '%s/%s' "$dir" "$newbase"
    fi
}


text_file_has_crlf() {
    local f="$1"
    LC_ALL=C grep -q $'\r' -- "$f"
}

normalize_text_file_to_unix() {
    local f="$1"

    if command -v dos2unix >/dev/null 2>&1; then
        preserve_timestamps_inplace "$f" dos2unix -q -- "$f"
    else
        preserve_timestamps_inplace "$f" sed -i 's/\r$//' -- "$f"
    fi
}

checksum_file_has_crlf() {
    local sum_file="$1"
    text_file_has_crlf "$sum_file"
}

normalize_checksum_file() {
    local sum_file="$1"
    normalize_text_file_to_unix "$sum_file"
}

ensure_checksum_file_unix_format() {
    local sum_file="$1"
    local label
    label="$(checksum_label "$sum_file")"

    if checksum_file_has_crlf "$sum_file"; then
        if [[ "$mode" == "dry-run" ]]; then
            emit_wrap_labeled_stdout "[DRY-RUN] Would convert ${label} file from CRLF to LF: " "${CYAN}[DRY-RUN] Would convert ${label} file from CRLF to LF:${RESET} " "$sum_file"
        else
            emit_wrap_labeled_stdout "${label} NORMALIZE: converting CRLF to LF: " "${CYAN}${label} NORMALIZE:${RESET} converting CRLF to LF: " "$sum_file"
            normalize_checksum_file "$sum_file"
            emit_wrap_labeled_stdout "${label} NORMALIZE DONE: converted from Windows format to Unix format: " "${CYAN}${label} NORMALIZE DONE:${RESET} converted from Windows format to Unix format: " "$sum_file"
        fi
    fi
}

extract_checksum_entries() {
    local sum_file="$1"
    sed -E 's/\r$//' -- "$sum_file" | while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        if [[ "$line" =~ ^([0-9a-fA-F]+)[[:space:]]+\*?(.*)$ ]]; then
            printf '%s\t%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
        fi
    done
}

checksum_check() {
    local sum_file="$1"
    local kind sum_dir sum_base
    kind="$(checksum_kind "$sum_file")"
    nonverbose_checksum_ref_verify_progress_letter "$kind"
    sum_dir="$(dirname -- "$sum_file")"
    sum_base="$(basename -- "$sum_file")"

    if [[ "$mode" == "real" ]]; then
        ensure_checksum_file_unix_format "$sum_file"
    fi

    vlog "Running $(checksum_cmd "$sum_file") check in directory '$sum_dir' for file '$sum_base'"

    if [[ "$mode" == "dry-run" ]]; then
        (
            cd "$sum_dir"
            case "$kind" in
                sha512) sha512sum -c --quiet -- <(sed 's/\r$//' -- "$sum_base") ;;
                md5)    md5sum    -c --quiet -- <(sed 's/\r$//' -- "$sum_base") ;;
            esac
        )
    else
        (
            cd "$sum_dir"
            case "$kind" in
                sha512) sha512sum -c --quiet -- "$sum_base" ;;
                md5)    md5sum    -c --quiet -- "$sum_base" ;;
            esac
        )
    fi
}

verify_single_checksum_target() {
    local sum_file="$1"
    local target_ref="$2"
    local kind sum_dir sum_base target_norm target_re matched_line

    kind="$(checksum_kind "$sum_file")" || kind=""
    nonverbose_checksum_ref_verify_progress_letter "$kind" "$sum_file"
    sum_dir="$(dirname -- "$sum_file")"
    sum_base="$(basename -- "$sum_file")"

    print_single_target_check_verbose "$(checksum_cmd "$sum_file")" "$sum_dir" "$target_ref" "$sum_base"

    matched_line="$(find_checksum_line_for_ref "$sum_file" "$target_ref")"

    if [[ -z "$matched_line" ]]; then
        return 2
    fi

    (
        cd "$sum_dir"
        case "$kind" in
            sha512) printf '%s\n' "$matched_line" | sha512sum -c --quiet --status ;;
            md5)    printf '%s\n' "$matched_line" | md5sum    -c --quiet --status ;;
        esac
    ) || return 1
    return 0
}

checksum_of_file() {
    local kind="$1"
    local file="$2"
    local out cached

    cached="$(db_get_cached_file_hash "$file" "$kind" || true)"
    if [[ -n "$cached" ]]; then
        printf '%s\n' "$cached"
        return 0
    fi

    case "$kind" in
        sha512) out="$(sha512sum -- "$file" | awk '{print tolower($1)}')" ;;
        md5)    out="$(md5sum    -- "$file" | awk '{print tolower($1)}')" ;;
        *) return 1 ;;
    esac

    ((++FILES_HASHED))
    db_record_file_hash "$file" "$kind" "$out"
    printf '%s\n' "$out"
}

md5_of_file() {
    local file="$1"
    local out cached

    cached="$(db_get_cached_file_hash "$file" "md5" || true)"
    if [[ -n "$cached" ]]; then
        printf '%s\n' "$cached"
        return 0
    fi

    out="$(md5sum -- "$file" | awk '{print tolower($1)}')"
    ((++FILES_HASHED))
    db_record_file_hash "$file" "md5" "$out"
    printf '%s\n' "$out"
}

format_bytes_human() {
    local bytes="$1"
    awk -v b="$bytes" 'BEGIN {
        kb = b / 1024.0;
        mb = b / 1048576.0;
        printf "%d bytes | %.2f kB | %.2f MB", b, kb, mb
    }'
}

get_file_birth_epoch() {
    local file="$1"
    stat -c %W -- "$file" 2>/dev/null || echo 0
}

get_file_mtime_epoch() {
    local file="$1"
    stat -c %Y -- "$file" 2>/dev/null || echo 0
}

get_file_size_bytes() {
    local file="$1"
    stat -c %s -- "$file" 2>/dev/null || echo 0
}

format_epoch_human() {
    local epoch="$1"
    if [[ "$epoch" =~ ^[0-9]+$ ]] && (( epoch > 0 )); then
        date -d "@$epoch" "+%Y-%m-%d %H:%M:%S"
    else
        printf '%s' "unavailable"
    fi
}

# If basename stem ends with repeated _OTHER segments (e.g. foo_OTHER_OTHER), collapse to a single trailing _OTHER so the name is offered for rename cleanup.
collapse_stacked_other_suffix_in_path() {
    local path="$1"
    local dir base stem ext
    [[ -n "$path" ]] || { printf '%s' "$path"; return; }
    dir="$(dirname -- "$path")"
    base="$(basename -- "$path")"
    if [[ "$base" == *.* ]]; then
        stem="${base%.*}"
        ext=".${base##*.}"
    else
        stem="$base"
        ext=""
    fi
    [[ "$stem" == *_OTHER_OTHER* ]] || { printf '%s' "$path"; return; }
    while [[ "$stem" == *_OTHER_OTHER ]]; do
        stem="${stem%_OTHER}"
    done
    if [[ "$dir" == "." ]]; then
        printf './%s%s' "$stem" "$ext"
    else
        printf '%s/%s%s' "$dir" "$stem" "$ext"
    fi
}

# Pick a non-existing path: one _OTHER before the extension; if taken, use _OTHER_2, _OTHER_3, … (never stack multiple _OTHER tokens).
make_other_suffix_path() {
    local path="$1"
    local dir base stem ext candidate n
    dir="$(dirname -- "$path")"
    base="$(basename -- "$path")"

    if [[ "$base" == *.* ]]; then
        stem="${base%.*}"
        ext=".${base##*.}"
    else
        stem="$base"
        ext=""
    fi

    while [[ "$stem" == *_OTHER ]]; do
        stem="${stem%_OTHER}"
    done

    candidate="${dir}/${stem}_OTHER${ext}"
    n=2
    while [[ -e "$candidate" ]]; do
        candidate="${dir}/${stem}_OTHER_${n}${ext}"
        ((++n))
    done
    printf '%s' "$candidate"
}

# When set: collision prompts skip [o/r/d/c/p/v/S/q] and apply _OTHER (like [R]) if the source file's directory matches this path (see similar_rename_dir_matches_scope).
collision_auto_other_dir_matches_source() {
    local old="$1"
    [[ -n "$AUTO_COLLISION_OTHER_DIR" ]] || return 1
    similar_rename_dir_matches_scope "$(dirname -- "$old")" "$AUTO_COLLISION_OTHER_DIR"
}

# When set: collision prompts skip [o/r/d/c/p/v/S/q] and overwrite destination (like [O]) for sources in this directory.
collision_auto_overwrite_dir_matches_source() {
    local old="$1"
    [[ -n "$AUTO_COLLISION_OVERWRITE_DIR" ]] || return 1
    similar_rename_dir_matches_scope "$(dirname -- "$old")" "$AUTO_COLLISION_OVERWRITE_DIR"
}

# True when a planned rename would hit an existing path (excluding case-only same inode).
checksum_rename_pair_has_target_collision() {
    local old="$1"
    local new="$2"

    [[ "$old" != "$new" && -e "$new" ]] || return 1
    if is_case_only_rename_pair "$old" "$new" && paths_refer_to_same_file "$old" "$new"; then
        return 1
    fi
    return 0
}

# Fill html_companion_* arrays for checksum-group HTML ref renames (no collision handling here).
build_checksum_group_html_companion_arrays() {
    local -n _refs="$1"
    local -n _new_refs="$2"
    local -n _html_old_dirs="$3"
    local -n _html_new_dirs="$4"
    local -n _html_old_names="$5"
    local -n _html_new_names="$6"
    local -n _html_apply="$7"

    local i old_companion_dir new_companion_dir old_companion_name old_html_stem companion_suffix companion_conflict j

    _html_old_dirs=()
    _html_new_dirs=()
    _html_old_names=()
    _html_new_names=()
    _html_apply=()

    for i in "${!_refs[@]}"; do
        _html_old_dirs+=( "" )
        _html_new_dirs+=( "" )
        _html_old_names+=( "" )
        _html_new_names+=( "" )
        _html_apply+=( "no" )

        [[ "${_new_refs[$i]}" != "${_refs[$i]}" ]] || continue
        is_html_file "${_refs[$i]}" || continue

        old_companion_dir="$(find_html_companion_dir "${_refs[$i]}" || true)"
        if [[ -z "$old_companion_dir" ]]; then
            continue
        fi

        old_companion_name="$(basename -- "$old_companion_dir")"
        old_html_stem="$(basename -- "${_refs[$i]%.*}")"
        companion_suffix="${old_companion_name#${old_html_stem}}"
        new_companion_dir="$(html_companion_dir_path_with_suffix "${_new_refs[$i]}" "$companion_suffix")"

        [[ "$old_companion_dir" != "$new_companion_dir" ]] || continue

        companion_conflict=no
        for j in "${!_refs[@]}"; do
            if [[ "${_refs[$j]}" == "$old_companion_dir" || "${_refs[$j]}" == "$old_companion_dir/"* ]]; then
                companion_conflict=yes
                break
            fi
        done
        [[ "$companion_conflict" == "no" ]] || continue

        _html_old_dirs[$i]="$old_companion_dir"
        _html_new_dirs[$i]="$new_companion_dir"
        _html_old_names[$i]="$(basename -- "$old_companion_dir")"
        _html_new_names[$i]="$(basename -- "$new_companion_dir")"
        _html_apply[$i]="yes"
    done
}

# Resolve checksum-group rename collisions using the same dialog as plain renames.
# Namerefs: new_sum, refs, new_refs, html_apply, html_old_dirs, html_new_dirs.
# Return 0 proceed, 1 skip whole group, 2 quit.
resolve_checksum_group_rename_collisions() {
    local sum_file="$1"
    local -n _new_sum="$2"
    local -n _refs="$3"
    local -n _new_refs="$4"
    local -n _html_apply="$5"
    local -n _html_old_dirs="$6"
    local -n _html_new_dirs="$7"

    local i dec old new companion_old companion_new resolved_any

    if [[ "$mode" == "dry-run" ]]; then
        if checksum_rename_pair_has_target_collision "$sum_file" "$_new_sum"; then
            handle_existing_target_collision "$sum_file" "$_new_sum" || true
        fi
        for i in "${!_refs[@]}"; do
            [[ "${_new_refs[$i]}" != "${_refs[$i]}" ]] || continue
            if checksum_rename_pair_has_target_collision "${_refs[$i]}" "${_new_refs[$i]}"; then
                handle_existing_target_collision "${_refs[$i]}" "${_new_refs[$i]}" || true
            fi
        done
        for i in "${!_html_apply[@]}"; do
            [[ "${_html_apply[$i]}" == "yes" ]] || continue
            companion_old="${_html_old_dirs[$i]}"
            companion_new="${_html_new_dirs[$i]}"
            if checksum_rename_pair_has_target_collision "$companion_old" "$companion_new"; then
                if [[ -f "$companion_old" && -f "$companion_new" ]]; then
                    handle_existing_target_collision "$companion_old" "$companion_new" || true
                else
                    emit_wrap_labeled_stdout "COLLISION: " "${YELLOW}COLLISION:${RESET} " "HTML companion directory target already exists."
                    emit_wrap_labeled_stdout "  SOURCE:      " "  ${RED}SOURCE:${RESET}      " "$companion_old"
                    emit_wrap_labeled_stdout "  DESTINATION: " "  ${GREEN}DESTINATION:${RESET} " "$companion_new" green
                fi
            fi
        done
        return 0
    fi

    while true; do
        resolved_any=no

        if checksum_rename_pair_has_target_collision "$sum_file" "$_new_sum"; then
            handle_existing_target_collision "$sum_file" "$_new_sum"
            dec=$?
            case "$dec" in
                0) resolved_any=yes ;;
                2) return 2 ;;
                3) _new_sum="$COLLISION_RENAMED_TARGET"; resolved_any=yes ;;
                4)
                    emit_wrap_labeled_stdout "SKIP: " "${YELLOW}SKIP:${RESET} " "Checksum group: hash file source removed; cannot continue this group."
                    return 1
                    ;;
                *) return 1 ;;
            esac
            continue
        fi

        for i in "${!_refs[@]}"; do
            [[ "${_new_refs[$i]}" != "${_refs[$i]}" ]] || continue
            if checksum_rename_pair_has_target_collision "${_refs[$i]}" "${_new_refs[$i]}"; then
                handle_existing_target_collision "${_refs[$i]}" "${_new_refs[$i]}"
                dec=$?
                case "$dec" in
                    0) resolved_any=yes ;;
                    2) return 2 ;;
                    3) _new_refs[$i]="$COLLISION_RENAMED_TARGET"; resolved_any=yes ;;
                    4) resolved_any=yes ;;
                    *) return 1 ;;
                esac
                break
            fi
        done
        [[ "$resolved_any" == "yes" ]] && continue

        for i in "${!_html_apply[@]}"; do
            [[ "${_html_apply[$i]}" == "yes" ]] || continue
            companion_old="${_html_old_dirs[$i]}"
            companion_new="${_html_new_dirs[$i]}"
            if ! checksum_rename_pair_has_target_collision "$companion_old" "$companion_new"; then
                continue
            fi
            if [[ -f "$companion_old" && -f "$companion_new" ]]; then
                handle_existing_target_collision "$companion_old" "$companion_new"
                dec=$?
                case "$dec" in
                    0) resolved_any=yes ;;
                    2) return 2 ;;
                    3) _html_new_dirs[$i]="$COLLISION_RENAMED_TARGET"; resolved_any=yes ;;
                    4) resolved_any=yes ;;
                    *) return 1 ;;
                esac
                break
            fi
            emit_wrap_labeled_stdout "SKIP: " "${YELLOW}SKIP:${RESET} " "Checksum group: HTML companion directory target already exists."
            vlog "Checksum group HTML companion directory collision: '$companion_old' -> '$companion_new'"
            return 1
        done
        [[ "$resolved_any" == "yes" ]] && continue

        break
    done

    return 0
}

handle_existing_target_collision() {
    local old="$1"
    local new="$2"

    COLLISION_RENAMED_TARGET=""

    if [[ "$mode" == "dry-run" ]]; then
        emit_wrap_labeled_stdout "COLLISION: " "${YELLOW}COLLISION:${RESET} " "Target file already exists."
        emit_wrap_old_arrow_new_stdout "[DRY-RUN] Would compare MD5, size, and timestamps of source/destination and ask what to do: " "${CYAN}[DRY-RUN] Would compare MD5, size, and timestamps of source/destination and ask what to do:${RESET} " "$old" "$new"
        emit_wrap_labeled_stdout "[DRY-RUN] Choices would include: " "${CYAN}[DRY-RUN] Choices would include:${RESET} " "[O] remove destination then rename; [C] overwrite all in this directory; [R]/[D] _OTHER; [P] remove source only; [V] list directory; [S] skip; [Q] quit."
        return 1
    fi

    can_overwrite_collision_with_identical_md5 "$old" "$new"
    collision_decision_rc=$?

    if [[ $collision_decision_rc -eq 0 ]]; then
        emit_wrap_labeled_stdout "OVERWRITE: removing destination and continuing rename: " "${CYAN}OVERWRITE:${RESET} removing destination and continuing rename: " "$new"
        rm -f -- "$new"
        return 0
    elif [[ $collision_decision_rc -eq 2 ]]; then
        return 2
    elif [[ $collision_decision_rc -eq 3 ]]; then
        emit_wrap_labeled_stdout "RENAME WITH _OTHER: source will be renamed to: " "${CYAN}RENAME WITH _OTHER:${RESET} source will be renamed to: " "$COLLISION_OTHER_PATH"
        COLLISION_RENAMED_TARGET="$COLLISION_OTHER_PATH"
        return 3
    elif [[ $collision_decision_rc -eq 4 ]]; then
        emit_wrap_labeled_stdout "DELETE SOURCE: removed duplicate source; destination unchanged: " "${CYAN}DELETE SOURCE:${RESET} removed duplicate source; destination unchanged: " "$old"
        db_delete_cached_row_for_path "$old"
        rm -f -- "$old" || return 1
        return 4
    else
        return 1
    fi
}

can_overwrite_collision_with_identical_md5() {
    local old="$1"
    local new="$2"
    local old_md5 new_md5 answer=""
    local old_size new_size old_btime new_btime old_mtime new_mtime
    local old_other_path

    COLLISION_OTHER_PATH=""
    [[ -f "$old" && -f "$new" ]] || return 1

    old_md5="$(md5_of_file "$old")"
    new_md5="$(md5_of_file "$new")"
    old_size="$(get_file_size_bytes "$old")"
    new_size="$(get_file_size_bytes "$new")"
    old_btime="$(get_file_birth_epoch "$old")"
    new_btime="$(get_file_birth_epoch "$new")"
    old_mtime="$(get_file_mtime_epoch "$old")"
    new_mtime="$(get_file_mtime_epoch "$new")"

    echo
    emit_wrap_labeled_stdout "COLLISION: " "${YELLOW}COLLISION:${RESET} " "target file already exists."
    emit_wrap_labeled_stdout "  SOURCE:      " "  ${RED}SOURCE:${RESET}      " "$old"
    emit_wrap_labeled_stdout "    size:       " "    size:       " "$(format_bytes_human "$old_size")"
    emit_wrap_labeled_stdout "    created:    " "    created:    " "$(format_epoch_human "$old_btime")"
    emit_wrap_labeled_stdout "    modified:   " "    modified:   " "$(format_epoch_human "$old_mtime")"
    emit_wrap_labeled_stdout "    md5:        " "    md5:        " "$old_md5"
    emit_wrap_labeled_stdout "  DESTINATION: " "  ${GREEN}DESTINATION:${RESET} " "$new" green
    emit_wrap_labeled_stdout "    size:       " "    size:       " "$(format_bytes_human "$new_size")"
    emit_wrap_labeled_stdout "    created:    " "    created:    " "$(format_epoch_human "$new_btime")"
    emit_wrap_labeled_stdout "    modified:   " "    modified:   " "$(format_epoch_human "$new_mtime")"
    emit_wrap_labeled_stdout "    md5:        " "    md5:        " "$new_md5"

    if [[ "$old_md5" == "$new_md5" ]]; then
        echo "Files are identical."
    else
        echo "Files are different."
    fi

    old_other_path="$(make_other_suffix_path "$new")"

    if collision_auto_overwrite_dir_matches_source "$old"; then
        emit_wrap_labeled_stdout "AUTO OVERWRITE (this directory): " "${CYAN}AUTO OVERWRITE (this directory):${RESET} " "session active — will delete destination and continue rename"
        vlog "Collision overwrite auto (directory session): '$old' -> '$new'"
        return 0
    fi

    if collision_auto_other_dir_matches_source "$old"; then
        COLLISION_OTHER_PATH="$old_other_path"
        emit_wrap_labeled_stdout "AUTO _OTHER (this directory): " "${CYAN}AUTO _OTHER (this directory):${RESET} " "session active — source -> '$(basename -- "$old_other_path")'"
        vlog "Collision _OTHER auto (directory session): '$old' -> '$old_other_path'"
        return 3
    fi

    while true; do
        verbose_question_timestamp "What should be done?"
        echo "  [O] Overwrite destination (delete destination file), then continue rename"
        echo "  [C] For this source directory only: overwrite destination for all further collisions (like [O])"
        echo "  [R] Rename source to alternate name (one _OTHER, or _OTHER_2, … if needed) -> $(basename -- "$old_other_path")"
        echo "  [D] For this source directory only: use _OTHER for all further collisions (like [R])"
        echo "  [P] Delete source file only (keep destination; skip this rename)"
        echo "  [S] Skip (default)"
        echo "  [V] List directory (parent; mark SOURCE/DESTINATION basenames)"
        echo "  [Q] Quit"
        echo -n "$(user_prompt_ts_prefix)Choice [o/c/r/d/p/S/v/q]: "

        flush_stdin
        read_single_key answer "$PROMPT_WAIT_SECONDS"
        echo

        if [[ "$answer" =~ [Vv] ]]; then
            print_rename_parent_directory_listing "$old" "$new"
            continue
        fi
        case "$answer" in
            q|Q)
                stopped_by_user=yes
                return 2
                ;;
            o|O)
                return 0
                ;;
            c|C)
                AUTO_COLLISION_OVERWRITE_DIR="$(cd -- "$(dirname -- "$old")" 2>/dev/null && pwd -P)" || AUTO_COLLISION_OVERWRITE_DIR="$(dirname -- "$old")"
                vlog "Collision overwrite per-directory session enabled for '$AUTO_COLLISION_OVERWRITE_DIR'"
                return 0
                ;;
            r|R)
                COLLISION_OTHER_PATH="$old_other_path"
                return 3
                ;;
            d|D)
                AUTO_COLLISION_OTHER_DIR="$(cd -- "$(dirname -- "$old")" 2>/dev/null && pwd -P)" || AUTO_COLLISION_OTHER_DIR="$(dirname -- "$old")"
                COLLISION_OTHER_PATH="$old_other_path"
                vlog "Collision _OTHER per-directory session enabled for '$AUTO_COLLISION_OTHER_DIR'"
                return 3
                ;;
            p|P)
                return 4
                ;;
            *)
                return 1
                ;;
        esac
    done
}

sed_escape_regex() {
    printf '%s' "$1" | sed -e 's/[.[\*^$()+?{}|\\/]/\\&/g'
}

sed_escape_repl() {
    printf '%s' "$1" | sed -e 's/[&\\/]/\\&/g'
}

strip_leading_dot_slash() {
    local p="$1"
    printf '%s' "${p#./}"
}

# sha512sum in cwd often writes "./file"; callers may pass ref with or without ./ — match either.
find_checksum_line_for_ref() {
    local sum_file="$1"
    local target_ref="$2"
    local target_norm target_re

    [[ -f "$sum_file" && -n "$target_ref" ]] || return 0

    target_norm="$(strip_leading_dot_slash "$target_ref")"
    target_re="$(sed_escape_regex "$target_norm")"

    sed -E 's/\r$//' -- "$sum_file" 2>/dev/null \
        | grep -E "^[0-9a-fA-F]+[[:space:]]+\*?(\./)?${target_re}$" \
        | tail -n 1 || true
}

relative_path() {
    local from_dir="$1"
    local target="$2"
    python3 - "$from_dir" "$target" <<'PY'
import os, sys
from_dir = sys.argv[1]
target = sys.argv[2]
print(os.path.relpath(target, from_dir))
PY
}

format_ref_for_checksum_file() {
    local sum_file="$1"
    local original_ref="$2"
    local actual_path="$3"
    local sum_dir rel

    sum_dir="$(dirname -- "$sum_file")"

    if [[ "$original_ref" == /* ]]; then
        python3 - "$actual_path" <<'PY'
import os, sys
print(os.path.abspath(sys.argv[1]))
PY
        return
    fi

    rel="$(relative_path "$sum_dir" "$actual_path")"

    if [[ "$original_ref" == ./* ]]; then
        printf './%s' "$rel"
    else
        printf '%s' "$rel"
    fi
}

update_checksum_content_refs() {
    local sum_file="$1"
    local old_name="$2"
    local new_name="$3"

    local old_re1 new_re1 old_re2 new_re2
    old_re1="$(sed_escape_regex "$old_name")"
    new_re1="$(sed_escape_repl "$new_name")"

    old_re2="$(sed_escape_regex "$(strip_leading_dot_slash "$old_name")")"
    new_re2="$(sed_escape_repl "$(strip_leading_dot_slash "$new_name")")"

    if (( VERBOSE == 1 )); then
        print_checksum_update_verbose "$sum_file" "$old_name" "$new_name"
    fi

    preserve_timestamps_inplace "$sum_file" \
        sed -i -E \
            -e "s|([[:space:]]\*?)${old_re1}\$|\1${new_re1}|g" \
            -e "s|([[:space:]]\*?)${old_re2}\$|\1${new_re2}|g" \
            -- "$sum_file"
}

remove_checksum_ref_entry() {
    local sum_file="$1"
    local target_ref="$2"

    preserve_timestamps_inplace "$sum_file" \
        python3 - "$sum_file" "$target_ref" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
target = sys.argv[2]
changed = False

lines = path.read_text(encoding="utf-8", errors="surrogateescape").splitlines(True)
out = []
for line in lines:
    m = re.match(r'^([0-9A-Fa-f]+)(\s+)(\*?)(.*?)(\r?\n?)$', line)
    if m and m.group(4) == target:
        changed = True
        continue
    out.append(line)

if changed:
    path.write_text(''.join(out), encoding="utf-8", errors="surrogateescape")
PY
}

update_local_checksums_after_deleted_file() {
    local deleted_file="$1"
    local sum_file hash ref resolved old_ref_for_write
    local -a verify_files=()
    local -A seen_verify=()
    local changed_any=no

    collect_local_checksum_ref_summaries "$deleted_file" "file"
    (( ${#PLAIN_REF_SUM_FILES[@]} > 0 )) || return 0

    for sum_file in "${PLAIN_REF_SUM_FILES[@]}"; do
        [[ -f "$sum_file" ]] || continue
        while IFS=$'\t' read -r hash ref; do
            [[ -n "$ref" ]] || continue
            resolved="$(resolve_checksum_ref_path "$sum_file" "$ref")"
            [[ "$resolved" == "$deleted_file" ]] || continue
            old_ref_for_write="$(format_ref_for_checksum_file "$sum_file" "$ref" "$resolved")"
            print_checksum_update_verbose "$sum_file" "$old_ref_for_write" "<removed: deleted target>"
            remove_checksum_ref_entry "$sum_file" "$old_ref_for_write"
            changed_any=yes
            if [[ -z "${seen_verify[$sum_file]+x}" ]]; then
                seen_verify["$sum_file"]=1
                verify_files+=( "$sum_file" )
            fi
        done < <(extract_checksum_entries "$sum_file")
    done

    [[ "$changed_any" == "yes" ]] || return 0

    for sum_file in "${verify_files[@]}"; do
        if ! checksum_check "$sum_file"; then
            emit_wrap_labeled_stdout "CHECKSUM WARNING: After removing deleted-file references, checksum file check failed: " "${YELLOW}CHECKSUM WARNING:${RESET} After removing deleted-file references, checksum file check failed: " "$sum_file"
            emit_wrap_labeled_stdout "NOTE: " "${YELLOW}NOTE:${RESET} " "failure may come from other missing/changed files already listed there."
        fi
    done
}

declare -a LOCAL_UPDATE_SUM_FILES=()
declare -a LOCAL_UPDATE_OLD_REFS=()
declare -a LOCAL_UPDATE_NEW_REFS=()
declare -a LOCAL_UPDATE_VERIFY_FILES=()

collect_local_checksum_ref_updates() {
    local target_old="$1"
    local target_new="$2"
    local target_kind="$3"

    local current_dir sum_file hash ref resolved suffix new_actual old_ref_for_write new_ref_for_write
    local -A seen_sum_files=()

    LOCAL_UPDATE_SUM_FILES=()
    LOCAL_UPDATE_OLD_REFS=()
    LOCAL_UPDATE_NEW_REFS=()
    LOCAL_UPDATE_VERIFY_FILES=()

    current_dir="$(dirname -- "$target_old")"

    for sum_file in "$current_dir"/*.sha512 "$current_dir"/*.md5; do
        [[ -f "$sum_file" ]] || continue
        is_checksum_file "$sum_file" || continue

        while IFS=$'	' read -r hash ref; do
            [[ -n "$ref" ]] || continue
            resolved="$(resolve_checksum_ref_path "$sum_file" "$ref")"

            case "$target_kind" in
                file)
                    [[ "$resolved" == "$target_old" ]] || continue
                    new_actual="$target_new"
                    ;;
                directory)
                    if [[ "$resolved" == "$target_old" ]]; then
                        new_actual="$target_new"
                    elif [[ "$resolved" == "$target_old/"* ]]; then
                        suffix="${resolved#"$target_old"}"
                        new_actual="${target_new}${suffix}"
                    else
                        continue
                    fi
                    ;;
                *)
                    continue
                    ;;
            esac

            old_ref_for_write="$(format_ref_for_checksum_file "$sum_file" "$ref" "$resolved")"
            new_ref_for_write="$(format_ref_for_checksum_file "$sum_file" "$ref" "$new_actual")"

            [[ "$old_ref_for_write" == "$new_ref_for_write" ]] && continue

            LOCAL_UPDATE_SUM_FILES+=( "$sum_file" )
            LOCAL_UPDATE_OLD_REFS+=( "$old_ref_for_write" )
            LOCAL_UPDATE_NEW_REFS+=( "$new_ref_for_write" )

            if [[ -z "${seen_sum_files[$sum_file]+x}" ]]; then
                seen_sum_files["$sum_file"]=1
                LOCAL_UPDATE_VERIFY_FILES+=( "$sum_file" )
            fi
        done < <(extract_checksum_entries "$sum_file")
    done
}

declare -a PLAIN_REF_SUM_FILES=()

collect_local_checksum_ref_summaries() {
    local target_old="$1"
    local target_kind="$2"

    local current_dir sum_file hash ref resolved
    local -A seen=()

    PLAIN_REF_SUM_FILES=()
    current_dir="$(dirname -- "$target_old")"

    for sum_file in "$current_dir"/*.sha512 "$current_dir"/*.md5; do
        [[ -f "$sum_file" ]] || continue
        is_checksum_file "$sum_file" || continue

        while IFS=$'	' read -r hash ref; do
            [[ -n "$ref" ]] || continue
            resolved="$(resolve_checksum_ref_path "$sum_file" "$ref")"

            case "$target_kind" in
                file)
                    [[ "$resolved" == "$target_old" ]] || continue
                    ;;
                directory)
                    [[ "$resolved" == "$target_old" || "$resolved" == "$target_old/"* ]] || continue
                    ;;
                *)
                    continue
                    ;;
            esac

            if [[ -z "${seen[$sum_file]+x}" ]]; then
                seen["$sum_file"]=1
                PLAIN_REF_SUM_FILES+=( "$sum_file" )
            fi
        done < <(extract_checksum_entries "$sum_file")
    done
}

apply_local_checksum_ref_updates_after_rename() {
    local target_old="$1"
    local target_new="$2"
    local target_kind="$3"
    local sum_file i changed_any=no

    collect_local_checksum_ref_updates "$target_old" "$target_new" "$target_kind"
    (( ${#LOCAL_UPDATE_SUM_FILES[@]} > 0 )) || return 0

    if [[ "$mode" == "dry-run" ]]; then
        emit_wrap_labeled_stdout "[DRY-RUN] Would update checksum reference(s) in local hash file(s) for rename: " "${CYAN}[DRY-RUN] Would update checksum reference(s) in local hash file(s) for rename:${RESET} " "$target_old"
        for sum_file in "${LOCAL_UPDATE_VERIFY_FILES[@]}"; do
            emit_wrap_labeled_stdout "    " "    " "$sum_file"
        done
        if (( VERBOSE == 1 )); then
            for i in "${!LOCAL_UPDATE_SUM_FILES[@]}"; do
                print_checksum_update_verbose "${LOCAL_UPDATE_SUM_FILES[$i]}" "${LOCAL_UPDATE_OLD_REFS[$i]}" "${LOCAL_UPDATE_NEW_REFS[$i]}"
            done
        fi
        return 0
    fi

    for i in "${!LOCAL_UPDATE_SUM_FILES[@]}"; do
        ensure_checksum_file_unix_format "${LOCAL_UPDATE_SUM_FILES[$i]}"
        update_checksum_content_refs "${LOCAL_UPDATE_SUM_FILES[$i]}" "${LOCAL_UPDATE_OLD_REFS[$i]}" "${LOCAL_UPDATE_NEW_REFS[$i]}"
        changed_any=yes
    done

    [[ "$changed_any" == "yes" ]] || return 0

    for sum_file in "${LOCAL_UPDATE_VERIFY_FILES[@]}"; do
        if ! checksum_check "$sum_file"; then
            emit_wrap_labeled_stdout "CHECKSUM WARNING: After plain rename, checksum file check failed: " "${YELLOW}CHECKSUM WARNING:${RESET} After plain rename, checksum file check failed: " "$sum_file"
            emit_wrap_labeled_stdout "NOTE: " "${YELLOW}NOTE:${RESET} " "failure may come from other missing/changed files already listed there."
        fi
        db_mark_checked "$sum_file" "checksum_group" "checked"
    done
}

perform_plain_entry_rename() {
    local old="$1"
    local new="$2"
    local old_companion_dir="" new_companion_dir="" old_companion_name="" new_companion_name=""
    local html_reference_update_only=no
    local target_kind=file

    if paths_refer_to_same_file "$old" "$new"; then
        if is_case_only_rename_pair "$old" "$new"; then
            :
        else
            vlog "Skipping rename: source and target are the same file (same device:inode): '$old' | '$new'"
            db_backfill_missing_hashes_for_existing_file "$old"
            ((++files_skipped))
            db_mark_checked "$old" "plain" "checked"
            return 0
        fi
    fi

    if should_skip_case_only_rename_on_fs "$old" "$new"; then
        vlog "Skipping case-only rename on exfat/CIFS/Samba (no mv): '$old'"
        db_backfill_missing_hashes_for_existing_file "$old"
        ((++files_skipped))
        db_mark_checked "$old" "plain" "checked"
        return 0
    fi

    if [[ -e "$new" ]]; then
        if is_case_only_rename_pair "$old" "$new" && paths_refer_to_same_file "$old" "$new"; then
            :
        else
            handle_existing_target_collision "$old" "$new"
            collision_decision_rc=$?

            if [[ $collision_decision_rc -eq 0 ]]; then
                :
            elif [[ $collision_decision_rc -eq 2 ]]; then
                return 1
            elif [[ $collision_decision_rc -eq 3 ]]; then
                new="$COLLISION_RENAMED_TARGET"
            elif [[ $collision_decision_rc -eq 4 ]]; then
                db_backfill_missing_hashes_for_existing_file "$new"
                db_mark_checked "$new" "plain" "checked"
                resume_checkpoint_register_processed_path "$old"
                vlog "Collision resolved by deleting source duplicate '$old'; kept destination '$new'"
                ((++files_affected))
                return 0
            else
                emit_wrap_labeled_stdout "SKIP: " "${YELLOW}SKIP:${RESET} " "Target file already exists."
                vlog "Collision detected for plain rename '$old' -> '$new'"
                ((++files_skipped))
                return 0
            fi
        fi
    fi

    if is_html_file "$old"; then
        plan_html_companion_for_rename "$old" "$new"
        old_companion_dir="$HTML_COMPANION_OLD_DIR"
        new_companion_dir="$HTML_COMPANION_NEW_DIR"
        old_companion_name="$HTML_COMPANION_OLD_NAME"
        new_companion_name="$HTML_COMPANION_NEW_NAME"
        html_reference_update_only="$HTML_COMPANION_REFERENCE_UPDATE_ONLY"

        if [[ -n "$old_companion_dir" && "$old_companion_dir" != "$new_companion_dir" && -e "$new_companion_dir" ]]; then
            if directory_is_empty "$new_companion_dir"; then
                vlog "Removing empty target companion directory before pair rename: '$new_companion_dir'"
                rmdir -- "$new_companion_dir"
            else
                emit_wrap_labeled_stdout "SKIP: Target companion directory already exists: " "${YELLOW}SKIP:${RESET} Target companion directory already exists: " "$new_companion_dir"
                vlog "Collision detected for companion directory '$old_companion_dir' -> '$new_companion_dir'"
                ((++files_skipped))
                return 0
            fi
        fi
    fi

    [[ -d "$old" ]] && target_kind=directory

    if [[ "$mode" == "dry-run" ]]; then
        emit_wrap_old_arrow_new_stdout "[DRY-RUN] Would rename: " "${CYAN}[DRY-RUN] Would rename:${RESET} " "$old" "$new"
        if [[ -n "$old_companion_dir" && "$old_companion_dir" != "$new_companion_dir" ]]; then
            emit_wrap_old_arrow_new_stdout "[DRY-RUN] Would rename companion directory: " "${CYAN}[DRY-RUN] Would rename companion directory:${RESET} " "$old_companion_dir" "$new_companion_dir"
            emit_wrap_labeled_stdout "[DRY-RUN] Would update HTML reference inside: " "${CYAN}[DRY-RUN] Would update HTML reference inside:${RESET} " "$new"
        elif [[ "$html_reference_update_only" == "yes" ]]; then
            emit_wrap_labeled_stdout "[DRY-RUN] Would update HTML reference inside: " "${CYAN}[DRY-RUN] Would update HTML reference inside:${RESET} " "$new"
        fi
        apply_local_checksum_ref_updates_after_rename "$old" "$new" "$target_kind"
        update_exclude_filters_file_after_rename "$old" "$new"
        ((++files_affected))
        record_rename "$old" "$new"
        if [[ -n "$old_companion_dir" && "$old_companion_dir" != "$new_companion_dir" ]]; then
            record_rename "$old_companion_dir" "$new_companion_dir"
            update_exclude_filters_file_after_rename "$old_companion_dir" "$new_companion_dir"
        fi
        return 0
    fi

    old_was_dir=no
    [[ -d "$old" ]] && old_was_dir=yes

    mv_with_case_only_filesystem_workaround "$old" "$new" || return 1
    ((++files_affected))
    record_rename "$old" "$new"
    if [[ "$old_was_dir" == "yes" ]]; then
        db_rewrite_subtree "$old" "$new"
    else
        db_rewrite_single_path "$old" "$new"
    fi
    db_mark_checked "$new" "plain" "checked"
    vlog "DB row ${DB_MARK_CHECKED_RESULT:-updated} after rename: '$new' (plain/checked)"
    plain_rename_emit_auto_dir_notice_if_active "$old" "$new"

    if [[ -n "$old_companion_dir" && "$old_companion_dir" != "$new_companion_dir" ]]; then
        emit_wrap_labeled_stdout "HTML PAIR RENAME: " "${CYAN}HTML PAIR RENAME:${RESET} " "HTML file and companion directory are being updated together."
        emit_wrap_labeled_stdout "  OLD HTML: " "  ${YELLOW}OLD HTML:${RESET} " "$old" yellow
        emit_wrap_labeled_stdout "  NEW HTML: " "  ${GREEN}NEW HTML:${RESET} " "$new" green
        emit_wrap_labeled_stdout "  OLD DIR:  " "  ${YELLOW}OLD DIR:${RESET}  " "$old_companion_dir" yellow
        emit_wrap_labeled_stdout "  NEW DIR:  " "  ${GREEN}NEW DIR:${RESET}  " "$new_companion_dir" green
        if should_skip_case_only_rename_on_fs "$old_companion_dir" "$new_companion_dir"; then
            vlog "Skipping case-only HTML companion directory rename on exfat/CIFS/Samba: '$old_companion_dir'"
            ((++files_skipped))
            db_mark_checked "$old_companion_dir" "html_companion" "checked"
            processed["$old_companion_dir"]=1
        elif mv_with_case_only_filesystem_workaround "$old_companion_dir" "$new_companion_dir"; then
            ((++files_affected))
            record_rename "$old_companion_dir" "$new_companion_dir"
            db_rewrite_subtree "$old_companion_dir" "$new_companion_dir"
            old_companion_name="$(basename -- "$old_companion_dir")"
            new_companion_name="$(basename -- "$new_companion_dir")"
            update_html_companion_reference "$new" "$old_companion_name" "$new_companion_name"
            emit_wrap_labeled_stdout "HTML PAIR UPDATED: companion reference inside HTML file was updated from " "${CYAN}HTML PAIR UPDATED:${RESET} companion reference inside HTML file was updated from " "'${old_companion_name}' to '${new_companion_name}'."
            db_mark_checked "$new_companion_dir" "html_companion" "checked"
            processed["$old_companion_dir"]=1
            processed["$new_companion_dir"]=1
            plain_rename_emit_auto_dir_notice_if_active "$old_companion_dir" "$new_companion_dir"
            update_exclude_filters_file_after_rename "$old_companion_dir" "$new_companion_dir"
        else
            mv_with_case_only_filesystem_workaround_force "$new" "$old" || true
            ((++files_skipped))
            return 0
        fi
    fi

    if [[ "$html_reference_update_only" == "yes" ]]; then
        update_html_companion_reference "$new" "$old_companion_name" "$new_companion_name"
        emit_wrap_labeled_stdout "HTML PAIR UPDATED: companion reference inside HTML file was updated from " "${CYAN}HTML PAIR UPDATED:${RESET} companion reference inside HTML file was updated from " "'${old_companion_name}' to '${new_companion_name}'."
        db_mark_checked "$new_companion_dir" "html_companion" "checked"
        processed["$new_companion_dir"]=1
    fi

    apply_local_checksum_ref_updates_after_rename "$old" "$new" "$target_kind"
    update_exclude_filters_file_after_rename "$old" "$new"

    return 0
}

resolve_checksum_ref_path() {
    local sum_file="$1"
    local ref="$2"
    local sum_dir candidate

    sum_dir="$(dirname -- "$sum_file")"

    if [[ "$ref" == /* ]]; then
        printf '%s' "$ref"
        return
    fi

    if [[ "$ref" == ./* ]]; then
        if [[ "$sum_dir" == "." ]]; then
            printf '%s' "$ref"
        else
            printf '%s/%s' "$sum_dir" "${ref#./}"
        fi
        return
    fi

    if [[ "$sum_dir" == "." ]]; then
        if [[ -e "./$ref" ]]; then
            printf './%s' "$ref"
        else
            printf '%s' "$ref"
        fi
    else
        candidate="$sum_dir/$ref"
        printf '%s' "$candidate"
    fi
}

variant_family_info() {
    local p="$1"
    local base stem variant ext

    base="$(basename -- "$p")"
    if [[ "$base" =~ ^(.+)_((ORG)|(OUTPUT)|(EXCLUDE))(\.[^.]+)$ ]]; then
        stem="${BASH_REMATCH[1]}"
        variant="${BASH_REMATCH[2]}"
        ext="${BASH_REMATCH[6]}"
        printf '%s|%s|%s' "$stem" "$variant" "$ext"
        return 0
    fi
    return 1
}

print_grouped_checksum_missing_warning() {
    local sum_file="$1"
    shift
    local -a refs=( "$@" )

    local ref info stem variant ext key rest
    local -A family_variants=()
    local found_group=no

    for ref in "${refs[@]}"; do
        if info="$(variant_family_info "$ref")"; then
            stem="${info%%|*}"
            rest="${info#*|}"
            variant="${rest%%|*}"
            ext="${rest##*|}"
            key="$stem"
            family_variants["$key"]+="${variant} "
            found_group=yes
        fi
    done

    [[ "$found_group" == "yes" ]] || return 0

    emit_wrap_labeled_stdout "CHECKSUM GROUP WARNING: " "${YELLOW}CHECKSUM GROUP WARNING:${RESET} " "'${sum_file}' contains grouped ORG/OUTPUT/EXCLUDE-style references."

    local family present_variants expected_variants expected_variant
    for family in "${!family_variants[@]}"; do
        present_variants="${family_variants[$family]}"
        expected_variants="ORG OUTPUT"

        for expected_variant in $expected_variants; do
            [[ "$present_variants" == *"${expected_variant} "* ]] && continue
            emit_wrap_labeled_stdout "  Missing reference in group: " "  ${YELLOW}Missing reference in group:${RESET} " "${family}_${expected_variant}.*"
        done
    done
}

declare -A RECOVERY_INDEX_READY=()
declare -A RECOVERY_INDEX_BY_BASENAME=()
declare -A RECOVERY_INDEX_ALL_FILES=()

build_recovery_file_index() {
    local search_root="$1"
    local candidate base key

    [[ -n "${RECOVERY_INDEX_READY[$search_root]-}" ]] && return 0

    while IFS= read -r -d '' candidate; do
        base="$(basename -- "$candidate")"
        key="${search_root}"$'\x1f'"${base}"
        if [[ -n "${RECOVERY_INDEX_BY_BASENAME[$key]-}" ]]; then
            RECOVERY_INDEX_BY_BASENAME["$key"]+=$'\n'"$candidate"
        else
            RECOVERY_INDEX_BY_BASENAME["$key"]="$candidate"
        fi
        if [[ -n "${RECOVERY_INDEX_ALL_FILES[$search_root]-}" ]]; then
            RECOVERY_INDEX_ALL_FILES["$search_root"]+=$'\n'"$candidate"
        else
            RECOVERY_INDEX_ALL_FILES["$search_root"]="$candidate"
        fi
    done < <(find "$search_root" -type f -print0 2>/dev/null)

    RECOVERY_INDEX_READY["$search_root"]=1
}

# Strip leading ./ then compare: print path of fullpath relative to root (no leading slash). Exit 1 if fullpath is not under root.
relative_path_under_dir_for_recovery() {
    local root="$1" fullpath="$2"
    fullpath="${fullpath#./}"
    root="${root#./}"
    root="${root%/}"
    if [[ "$root" == "." || -z "$root" ]]; then
        printf '%s' "$fullpath"
        return 0
    fi
    local pref="${root}/"
    if [[ "$fullpath" == "$pref"* ]]; then
        printf '%s' "${fullpath#"$pref"}"
        return 0
    fi
    if [[ "$fullpath" == "$root" ]]; then
        printf ''
        return 0
    fi
    return 1
}

# Apply transform_basename to each relative path segment (same rules as directory/file renames). Prints path starting at search_root. Exit 2 if transform_basename aborts (user); exit 1 if not under root or empty rel.
checksum_rebuilt_ref_path_by_segments() {
    local search_root="$1"
    local missing_ref="$2"
    local rel OIFS parts p t out tb_rc _cr_save_e=0

    rel="$(relative_path_under_dir_for_recovery "$search_root" "$missing_ref")" || return 1
    [[ -n "$rel" ]] || return 1

    out="$search_root"
    [[ $- == *e* ]] && _cr_save_e=1
    set +e
    OIFS="$IFS"
    IFS='/'
    read -ra parts <<< "$rel"
    IFS="$OIFS"
    for p in "${parts[@]}"; do
        [[ -n "$p" ]] || continue
        t="$(transform_basename "$p")"
        tb_rc=$?
        if (( tb_rc == 2 )); then
            ((_cr_save_e)) && set -e || set +e
            return 2
        fi
        out="${out%/}/$t"
    done
    ((_cr_save_e)) && set -e || set +e
    printf '%s' "$out"
    return 0
}

find_best_path_for_missing_ref() {
    local missing_ref="$1"
    local expected_hash="$2"
    local sum_file="$3"

    local kind wanted_base wanted_norm missing_dir search_root
    local fast_base fast_path fast_hash
    local candidate candidate_hash candidate_name indexed_candidates index_key all_candidates
    local -a candidate_names=()
    local rebuilt rebuilt_hash _wn_save_e _wn_rc _seg_save_e _seg_rc

    kind="$(checksum_kind "$sum_file")"
    wanted_base="$(basename -- "$missing_ref")"
    _wn_save_e=0
    [[ $- == *e* ]] && _wn_save_e=1
    set +e
    wanted_norm="$(transform_basename "$wanted_base" "$missing_ref")"
    _wn_rc=$?
    ((_wn_save_e)) && set -e || set +e
    if ((_wn_rc == 2)); then
        return 2
    fi
    missing_dir="$(dirname -- "$missing_ref")"
    search_root="$(dirname -- "$sum_file")"

    print_try_recover_missing_ref_verbose "$missing_ref" "${expected_hash:-none}"

    fast_base="$wanted_norm"
    fast_path="${missing_dir}/${fast_base}"

    if [[ -f "$fast_path" ]]; then
        vlog "Fast recovery candidate in same directory: '$fast_path'"
        if [[ -n "$expected_hash" ]]; then
            fast_hash="$(checksum_of_file "$kind" "$fast_path")"
            vlog "Fast recovery candidate has $kind=$fast_hash"
            if [[ "${fast_hash,,}" == "${expected_hash,,}" ]]; then
                vlog "Fast recovery candidate checksum matches"
                printf '%s' "$fast_path"
                return 0
            else
                vlog "Fast recovery candidate checksum does not match"
            fi
        else
            vlog "Fast recovery candidate accepted (no expected hash available)"
            printf '%s' "$fast_path"
            return 0
        fi
    fi

    if [[ "$wanted_base" == "$wanted_norm" ]]; then
        candidate_names=( "$wanted_base" )
    else
        candidate_names=( "$wanted_norm" "$wanted_base" )
    fi

    build_recovery_file_index "$search_root"

    for candidate_name in "${candidate_names[@]}"; do
        index_key="${search_root}"$'\x1f'"${candidate_name}"
        indexed_candidates="${RECOVERY_INDEX_BY_BASENAME[$index_key]-}"
        [[ -n "$indexed_candidates" ]] || continue
        while IFS= read -r candidate; do
            [[ -n "$candidate" ]] || continue
            vlog "Subtree recovery candidate by name: '$candidate'"
            if [[ -n "$expected_hash" ]]; then
                candidate_hash="$(checksum_of_file "$kind" "$candidate")"
                vlog "Subtree recovery candidate by name has $kind=$candidate_hash"
                if [[ "${candidate_hash,,}" == "${expected_hash,,}" ]]; then
                    vlog "Subtree recovery candidate by name checksum matches"
                    printf '%s' "$candidate"
                    return 0
                fi
            else
                vlog "Subtree recovery candidate by name accepted (no expected hash available)"
                printf '%s' "$candidate"
                return 0
            fi
        done <<< "$indexed_candidates"
    done

    _seg_save_e=0
    [[ $- == *e* ]] && _seg_save_e=1
    set +e
    rebuilt="$(checksum_rebuilt_ref_path_by_segments "$search_root" "$missing_ref")"
    _seg_rc=$?
    ((_seg_save_e)) && set -e || set +e
    if ((_seg_rc == 2)); then
        return 2
    fi
    if ((_seg_rc == 0)) && [[ -n "$rebuilt" ]] && [[ -f "$rebuilt" ]]; then
        vlog "Per-segment basename-transform recovery candidate: '$rebuilt'"
        if [[ -n "$expected_hash" ]]; then
            rebuilt_hash="$(checksum_of_file "$kind" "$rebuilt")"
            vlog "Per-segment candidate has $kind=$rebuilt_hash"
            if [[ "${rebuilt_hash,,}" == "${expected_hash,,}" ]]; then
                vlog "Per-segment basename-transform recovery checksum matches"
                printf '%s' "$rebuilt"
                return 0
            fi
            vlog "Per-segment basename-transform recovery checksum does not match"
        else
            vlog "Per-segment basename-transform recovery accepted (no expected hash available)"
            printf '%s' "$rebuilt"
            return 0
        fi
    fi

    if [[ -n "$expected_hash" ]]; then
        candidate="$(db_find_path_by_file_hash_in_subtree "$search_root" "$kind" "$expected_hash" || true)"
        if [[ -n "$candidate" ]]; then
            vlog "Subtree recovery candidate by DB hash matches: '$candidate'"
            printf '%s' "$candidate"
            return 0
        fi

        print_scan_by_checksum_verbose "$search_root" "$expected_hash"
        all_candidates="${RECOVERY_INDEX_ALL_FILES[$search_root]-}"
        while IFS= read -r candidate; do
            [[ -n "$candidate" ]] || continue
            candidate_hash="$(checksum_of_file "$kind" "$candidate")"
            if [[ "${candidate_hash,,}" == "${expected_hash,,}" ]]; then
                vlog "Subtree recovery candidate by checksum matches: '$candidate'"
                printf '%s' "$candidate"
                return 0
            fi
        done <<< "$all_candidates"
    fi

    vlog "Subtree recovery failed for '$missing_ref' under '$search_root'"
    return 1
}


handle_lnk_file() {
    local f="$1"
    local answer=""

    while true; do
        echo
        emit_wrap_labeled_stdout "LNK FILE: " "${YELLOW}LNK FILE:${RESET} " "$f"
        verbose_question_timestamp "Remove this .lnk file?"
        print_prompt_view_directory_menu_line
        echo -n "$(user_prompt_ts_prefix)Remove this .lnk file? [y/N/v/q]: "
        flush_stdin
        read_single_key answer "$PROMPT_WAIT_SECONDS"
        echo

        if handle_prompt_directory_listing_choice "$answer" "$f"; then
            continue
        fi
        case "$answer" in
            q|Q)
                stopped_by_user=yes
                return 1
                ;;
            y|Y)
                if [[ "$mode" == "dry-run" ]]; then
                    emit_wrap_labeled_stdout "[DRY-RUN] Would remove: " "${CYAN}[DRY-RUN] Would remove:${RESET} " "$f"
                else
                    emit_wrap_labeled_stdout "REMOVE: " "${CYAN}REMOVE:${RESET} " "$f"
                    rm -f -- "$f"
                fi
                ((++files_affected))
                return 0
                ;;
            *)
                ((++files_skipped))
                db_mark_checked "$f" "lnk" "kept"
                return 0
                ;;
        esac
    done
}

files_examined=0
# When resuming, load_resume_checkpoint sets this to the restored files_examined so milestone "n out of total" counts only this session.
MAIN_LOOP_FILES_EXAMINED_MILESTONE_BASE=0
# Added to the non-verbose "N out of total" numerator so a resumed run counts from the
# checkpoint position (= number of discovered paths already matched/skipped this run),
# not from 1. Stays 0 for fresh runs. Bounded: offset + remaining == total.
MAIN_LOOP_RESUME_PROGRESS_OFFSET=0
# Last milestone numerator actually shown, so a clamped value is never printed twice.
MAIN_LOOP_LAST_MILESTONE_VALUE=-1
files_affected=0
files_skipped=0
rename_all=no
AUTO_RENAME_DIR=""
AUTO_RENAME_SIMILAR_DIR=""
AUTO_RENAME_SIMILAR_NEED_USCORE=no
# When set to realpath of a directory: collision prompts auto-apply _OTHER (like [R]) for every source file in that directory until cleared.
AUTO_COLLISION_OTHER_DIR=""
# When set to realpath of a directory: collision prompts auto-overwrite destination (like [O]) for every source file in that directory until cleared.
AUTO_COLLISION_OVERWRITE_DIR=""
# When set to realpath of a directory: RawFileName mismatch prompts auto-apply without asking for every paired XMP in that dir.
NEF_XMP_RAWFIX_AUTO_DIR=""
AUTO_LOWERCASE_3_EXT_SESSION=no # [L] session: any extension case-only lowercasing (name kept for compatibility)
AUTO_LOWERCASE_MEDIA_OFFICE_EXT_SESSION=no # [U] session: only media + MS Office extension case-only lowercasing
AUTO_GOPRO_STRIP_PART_DIR="" # GoPro lone _part_XX prompt [D]: auto-strip for rest of run in this directory
AUTO_GOPRO_STRIP_PART_SESSION=no # GoPro lone _part_XX prompt [A]: auto-strip for all qualifying files this run
AUTO_DELETE_THUMBS_DB_SESSION=no # thumbs.db prompt [O]: delete all thumbs.db for the rest of this run
RENAME_SH_GOPRO_STATE_FILE="${RENAME_SH_GOPRO_STATE_FILE:-${XDG_STATE_HOME:-$HOME/.local/state}/rename.sh/gopro-strip.$$}"

declare -a renamed_list=()
declare -A recorded
declare -A processed
# Index into renamed_list where THIS run's renames begin. On resume it is set to the
# number of entries restored from the checkpoint, so the summary can list only the
# entries affected during the current run (0 for fresh runs).
RENAMED_LIST_SESSION_BASE=0

clear_resume_state_file() {
    [[ -f "$RESUME_STATE_FILE" ]] || return 0
    rm -f -- "$RESUME_STATE_FILE"
}

# Single relative form for resume JSON (./foo vs foo); absolute paths unchanged. Used to dedupe processed keys on save.
resume_path_canonical_for_storage() {
    local p="$1"
    [[ -n "$p" ]] || return 1
    while [[ "$p" == */ ]]; do
        p="${p%/}"
    done
    [[ -n "$p" ]] || return 1
    if [[ "$p" == /* ]]; then
        printf '%s' "$p"
        return 0
    fi
    if [[ "$p" == ./* ]]; then
        printf '%s' "$p"
        return 0
    fi
    printf './%s' "$p"
}

save_resume_checkpoint() {
    local tmp_renamed
    local p r

    if ! command -v python3 >/dev/null 2>&1; then
        return 0
    fi

    tmp_renamed="$(mktemp)"

    for r in "${renamed_list[@]}"; do
        printf '%s\0' "$r" >> "$tmp_renamed"
    done

    # Stream all processed map keys to Python (bash printf only); Python dedupes with same rules as
    # resume_path_canonical_for_storage and writes JSON in one pass — much faster than per-key bash work.
    if ! {
        for p in "${!processed[@]}"; do
            printf '%s\0' "$p"
        done
    } | python3 - "$RESUME_STATE_FILE" "$tmp_renamed" \
        "$SCRIPT_VERSION" "$START_DIR" "$mode" "$process_scope" \
        "$USE_DB" "$FAST_DB" "$FORCE_RECHECK" "$PROMPT_WAIT_SECONDS" "$DATE_PLACEMENT" \
        "$files_examined" "$files_affected" "$files_skipped" "$FILES_HASHED" \
        "$SCRIPT_START_TIME" <<'PY'
import json
import pathlib
import sys

# Mirrors resume_path_canonical_for_storage() in bash.
def canon(s):
    if not s:
        return None
    p = s
    while p.endswith("/"):
        p = p[:-1]
    if not p:
        return None
    if p.startswith("/"):
        return p
    if p.startswith("./"):
        return p
    return "./" + p

state_path = pathlib.Path(sys.argv[1])
renamed_path = pathlib.Path(sys.argv[2])

raw_parts = sys.stdin.buffer.read().split(b"\0")
seen = {}
for raw in raw_parts:
    if not raw:
        continue
    s = raw.decode("utf-8", "surrogateescape")
    c = canon(s)
    if c is None:
        continue
    seen.setdefault(c, None)
processed_list = list(seen.keys())

rdata = renamed_path.read_bytes()
if rdata:
    renamed_list = [x.decode("utf-8", "surrogateescape") for x in rdata.split(b"\0") if x]
else:
    renamed_list = []

payload = {
    "scriptVersion": sys.argv[3],
    "startDir": sys.argv[4],
    "mode": sys.argv[5],
    "scope": sys.argv[6],
    "useDb": int(sys.argv[7]),
    "fastDb": int(sys.argv[8]),
    "forceRecheck": int(sys.argv[9]),
    "promptWaitSeconds": int(sys.argv[10]),
    "datePlacement": sys.argv[11],
    "filesExamined": int(sys.argv[12]),
    "filesAffected": int(sys.argv[13]),
    "filesSkipped": int(sys.argv[14]),
    "filesHashed": int(sys.argv[15]),
    "scriptStartTime": sys.argv[16],
    "processed": processed_list,
    "renamedList": renamed_list,
}

state_path.write_text(json.dumps(payload, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
PY
    then
        rm -f -- "$tmp_renamed"
        return 0
    fi

    rm -f -- "$tmp_renamed"
}

# Register a path from resume JSON under the same key forms the main loop uses (find emits ./foo; older checkpoints may store foo).
resume_checkpoint_register_processed_path() {
    local p="$1"
    [[ -z "$p" ]] && return 0
    processed["$p"]=1
    if [[ "$p" == ./* ]]; then
        processed["${p#./}"]=1
    elif [[ "$p" != /* ]]; then
        processed["./$p"]=1
    fi
}

load_resume_checkpoint() {
    local tmp_processed tmp_renamed meta
    local prev_processed_count=0
    local prev_renamed_count=0
    local path entry

    [[ -f "$RESUME_STATE_FILE" ]] || return 1
    if ! command -v python3 >/dev/null 2>&1; then
        echo "Resume checkpoint found but python3 is unavailable; starting from scratch."
        return 1
    fi

    tmp_processed="$(mktemp)"
    tmp_renamed="$(mktemp)"
    verbose_status_timestamp "Loading resume checkpoint metadata from: $RESUME_STATE_FILE"
    if ! meta="$(python3 - "$RESUME_STATE_FILE" "$tmp_processed" "$tmp_renamed" "$START_DIR" "$mode" "$process_scope" "$USE_DB" "$FAST_DB" "$FORCE_RECHECK" "$PROMPT_WAIT_SECONDS" "$DATE_PLACEMENT" <<'PY'
import json
import pathlib
import sys

state_path = pathlib.Path(sys.argv[1])
processed_out = pathlib.Path(sys.argv[2])
renamed_out = pathlib.Path(sys.argv[3])

data = json.loads(state_path.read_text(encoding="utf-8"))

checks = [
    ("startDir", sys.argv[4]),
    ("mode", sys.argv[5]),
    ("scope", sys.argv[6]),
]
for key, expected in checks:
    if str(data.get(key, "")) != expected:
        print(f"mismatch:{key}")
        sys.exit(2)

numeric_checks = [
    ("useDb", int(sys.argv[7])),
    ("fastDb", int(sys.argv[8])),
    ("forceRecheck", int(sys.argv[9])),
    ("promptWaitSeconds", int(sys.argv[10])),
]
for key, expected in numeric_checks:
    if int(data.get(key, -1)) != expected:
        print(f"mismatch:{key}")
        sys.exit(2)

if str(data.get("datePlacement", "front")) != sys.argv[11]:
    print("mismatch:datePlacement")
    sys.exit(2)

processed = data.get("processed", [])
renamed = data.get("renamedList", [])
if not isinstance(processed, list) or not isinstance(renamed, list):
    print("invalid:lists")
    sys.exit(3)

processed_out.write_bytes(b"\0".join(s.encode("utf-8", "surrogateescape") for s in processed) + (b"\0" if processed else b""))
renamed_out.write_bytes(b"\0".join(s.encode("utf-8", "surrogateescape") for s in renamed) + (b"\0" if renamed else b""))

fields = [
    str(int(data.get("filesExamined", 0))),
    str(int(data.get("filesAffected", 0))),
    str(int(data.get("filesSkipped", 0))),
    str(int(data.get("filesHashed", 0))),
    str(data.get("scriptStartTime", "")),
]
print("\t".join(fields))
PY
)"; then
        rm -f -- "$tmp_processed" "$tmp_renamed"
        if [[ "$meta" == mismatch:* ]]; then
            echo "Resume checkpoint exists but options differ from the previous run; starting from scratch."
        else
            echo "Resume checkpoint is invalid; starting from scratch."
        fi
        return 1
    fi

    IFS=$'\t' read -r files_examined files_affected files_skipped FILES_HASHED SCRIPT_START_TIME <<< "$meta"
    MAIN_LOOP_FILES_EXAMINED_MILESTONE_BASE=$files_examined

    unset processed
    declare -gA processed=()
    verbose_status_timestamp "Restoring processed-entry state from checkpoint..."
    while IFS= read -r -d '' path; do
        resume_checkpoint_register_processed_path "$path"
        if c="$(resume_path_canonical_for_storage "$path" 2>/dev/null)"; then
            [[ "$c" != "$path" ]] && resume_checkpoint_register_processed_path "$c"
        fi
        ((++prev_processed_count))
        if (( VERBOSE == 1 && prev_processed_count % 100000 == 0 )); then
            verbose_status_timestamp "Resume restore progress: ${prev_processed_count} processed entries loaded..."
        fi
    done < "$tmp_processed"

    renamed_list=()
    unset recorded
    declare -gA recorded=()
    verbose_status_timestamp "Restoring renamed-entry history from checkpoint..."
    while IFS= read -r -d '' entry; do
        renamed_list+=( "$entry" )
        recorded["$entry"]=1
        ((++prev_renamed_count))
        if (( VERBOSE == 1 && prev_renamed_count % 50000 == 0 )); then
            verbose_status_timestamp "Resume restore progress: ${prev_renamed_count} renamed entries loaded..."
        fi
    done < "$tmp_renamed"

    # Everything restored above belongs to previous runs; the summary's "affected entries"
    # list should start counting from here so it only shows what THIS run renamed.
    RENAMED_LIST_SESSION_BASE=${#renamed_list[@]}

    rm -f -- "$tmp_processed" "$tmp_renamed"
    RESUME_STATE_WAS_LOADED=1
    RESUME_CHECKPOINT_PROCESSED_LINES_LOADED=$prev_processed_count
    verbose_status_timestamp "Resume checkpoint restore complete: processed=${prev_processed_count}, renamed=${prev_renamed_count}"
    echo "Resume checkpoint loaded: $prev_processed_count entries marked as already processed."
    echo "Note: Non-verbose 'n out of total' counts paths examined this session (numerator resets from the checkpoint baseline);"
    echo "${WRAP_MSG_INDENT}denominator is the current sorted list; skipping resume entries does not advance the numerator."
    return 0
}

maybe_resume_from_checkpoint() {
    local answer=""

    [[ -f "$RESUME_STATE_FILE" ]] || return 0

    case "$CLI_RESUME_STATE" in
        fresh)
            return 0
            ;;
        resume)
            load_resume_checkpoint || true
            return 0
            ;;
        ask)
            if [[ "$EARLY_RESUME_DECISION" == "quit" ]]; then
                echo "Quitting."
                exit 0
            elif [[ "$EARLY_RESUME_DECISION" == "resume" ]]; then
                load_resume_checkpoint || true
            elif [[ "$EARLY_RESUME_DECISION" != "fresh" ]]; then
                echo
                echo "Checkpoint found from an interrupted run: $RESUME_STATE_FILE"
                verbose_question_timestamp "Resume from checkpoint?"
                echo "  [Y] Resume (default)"
                echo "  [N] Start from the beginning"
                echo "  [Q] Quit"
                echo -n "$(user_prompt_ts_prefix)Choice [Y/n/q]: "
                flush_stdin
                read_single_key answer "$PROMPT_WAIT_SECONDS"
                echo
                if [[ "$answer" =~ [Qq] ]]; then
                    echo "Quitting."
                    exit 0
                elif [[ ! "$answer" =~ [Nn] ]]; then
                    load_resume_checkpoint || true
                fi
            fi
            ;;
    esac
}

record_rename() {
    local old="$1" new="$2"
    local key="$old|$new"
    [[ -n "${recorded[$key]+x}" ]] && return 0
    recorded["$key"]=1
    renamed_list+=("$key")
}

auto_yes_current_dir_matches() {
    local path="$1"
    local path_dir
    path_dir="$(dirname -- "$path")"
    [[ -n "$AUTO_RENAME_DIR" && "$path_dir" == "$AUTO_RENAME_DIR" ]]
}

similar_rename_dir_matches_scope() {
    local dir_path="$1" scope="$2"
    [[ -n "$scope" ]] || return 1
    [[ "$dir_path" == "$scope" ]] && return 0
    local p s
    p="$(cd -- "$dir_path" 2>/dev/null && pwd -P)" || p="$dir_path"
    s="$(cd -- "$scope" 2>/dev/null && pwd -P)" || s="$scope"
    [[ "$p" == "$s" ]]
}

similar_rename_entry_matches_anchor_pattern() {
    local path="$1" bn
    [[ -n "$AUTO_RENAME_SIMILAR_DIR" ]] || return 1
    similar_rename_dir_matches_scope "$(dirname -- "$path")" "$AUTO_RENAME_SIMILAR_DIR" || return 1
    bn="$(basename -- "$path")"
    if [[ "$AUTO_RENAME_SIMILAR_NEED_USCORE" == yes ]]; then
        [[ "$bn" == _* ]] || return 1
    fi
    return 0
}

similar_rename_set_anchor_from_prompt_path() {
    local path="$1" bn
    bn="$(basename -- "$path")"
    AUTO_RENAME_SIMILAR_DIR="$(cd -- "$(dirname -- "$path")" 2>/dev/null && pwd -P)" || AUTO_RENAME_SIMILAR_DIR="$(dirname -- "$path")"
    if [[ "$bn" == _* ]]; then
        AUTO_RENAME_SIMILAR_NEED_USCORE=yes
    else
        AUTO_RENAME_SIMILAR_NEED_USCORE=no
    fi
}

similar_rename_clear() {
    AUTO_RENAME_SIMILAR_DIR=""
    AUTO_RENAME_SIMILAR_NEED_USCORE=no
}

# One directory level for rename prompt [V]: mark OLD/NEW basenames when they appear as siblings.
# Always stderr: callers often run inside $(...) (e.g. GoPro _part_XX, transform_basename mapping) where stdout is captured.
print_rename_one_level_dir_listing() {
    local dir="$1"
    local mark_old="${2-}"
    local mark_new="${3-}"
    local -a entries=()
    local entry bn line suffix

    mapfile -t entries < <(find "$dir" -mindepth 1 -maxdepth 1 2>/dev/null | LC_ALL=C sort)

    if (( ${#entries[@]} == 0 )); then
        echo "  (empty)" >&2
        return 0
    fi

    for entry in "${entries[@]}"; do
        [[ -n "$entry" ]] || continue
        bn="$(basename -- "$entry")"
        suffix=""
        if [[ -n "$mark_old" && "$bn" == "$mark_old" ]]; then
            suffix="  ← OLD"
            line="  $bn$suffix"
            if [[ "$use_colors" == yes ]]; then
                printf '%b%s%b%s\n' "$YELLOW" "  $bn" "$RESET" "$suffix" >&2
            else
                printf '%s\n' "$line" >&2
            fi
            continue
        fi
        if [[ -n "$mark_new" && "$bn" == "$mark_new" ]]; then
            suffix="  ← NEW (on disk)"
            if [[ "$use_colors" == yes ]]; then
                printf '%b%s%b%s\n' "$GREEN" "  $bn" "$RESET" "$suffix" >&2
            else
                printf '  %s%s\n' "$bn" "$suffix" >&2
            fi
            continue
        fi
        if [[ -d "$entry" ]]; then
            printf '  %s/\n' "$bn" >&2
        else
            printf '  %s\n' "$bn" >&2
        fi
    done
}

# Parent of OLD path; when OLD is a directory, also list its immediate children.
print_rename_parent_directory_listing() {
    local path="$1"
    local suggested_new="${2-}"
    local parent old_base new_base

    [[ -n "$path" ]] || return 0
    parent="$(dirname -- "$path")"
    [[ -n "$parent" ]] || parent="."
    old_base="$(basename -- "$path")"
    new_base=""
    [[ -n "$suggested_new" ]] && new_base="$(basename -- "$suggested_new")"

    echo >&2
    emit_wrap_labeled_stderr "LISTING: " "${CYAN}LISTING:${RESET} " "Directory containing this path: $(format_path_for_log "$parent")"
    if [[ ! -d "$parent" ]]; then
        echo "  (not found or not a directory)" >&2
        return 0
    fi
    print_rename_one_level_dir_listing "$parent" "$old_base" "$new_base"

    if [[ -d "$path" ]]; then
        echo >&2
        emit_wrap_labeled_stderr "LISTING: " "${CYAN}LISTING:${RESET} " "Inside OLD directory: $(format_path_for_log "$path")"
        print_rename_one_level_dir_listing "$path" "" ""
    fi
}

# Shared [V] directory listing for interactive prompts (stdout menu line).
print_prompt_view_directory_menu_line() {
    echo "  [V] List directory where this path exists (parent; mark OLD/NEW basenames when given)"
}

# Shared [V] directory listing for stderr prompts (mapping helpers, GoPro, exiftool).
print_prompt_view_directory_menu_line_stderr() {
    echo "  [V] List directory where this path exists (parent; mark OLD/NEW basenames when given)" >&2
}

# Returns 0 when answer is [V] and a listing was printed (caller should re-prompt).
handle_prompt_directory_listing_choice() {
    local answer="$1"
    local path="$2"
    local suggested_new="${3-}"

    [[ "$answer" =~ [Vv] && -n "$path" ]] || return 1
    print_rename_parent_directory_listing "$path" "$suggested_new"
    return 0
}

print_rename_prompt_menu() {
    nonverbose_progress_dot_prepare_for_prompt
    local kind_label="$1"
    local path="${2-}"
    local suggested_new="${3-}"
    local menu_variant="${4-}"
    local choice_hint="Choice [Y/n/m/a/d"
    local entry_kind="$kind_label"

    if [[ "$menu_variant" == thumbs-noop ]]; then
        echo -e "$(user_prompt_ts_prefix)${GREEN}This thumbs.db does not need a rename (suggested path matches the current path).${RESET}"
        echo -e "${CYAN}  OLD and NEW below are the same on purpose — use [K] to delete this thumbs.db, [O] to delete all thumbs.db this run, or skip.${RESET}"
    elif [[ "$menu_variant" == torrent-noop ]]; then
        echo -e "$(user_prompt_ts_prefix)${GREEN}This torrent .URL shortcut does not need a rename (suggested path matches the current path).${RESET}"
        echo -e "${CYAN}  OLD and NEW below are the same on purpose — use [T] to delete the shortcut, or skip.${RESET}"
    else
        [[ -n "$path" && -d "$path" ]] && entry_kind="directory"
        if [[ "$entry_kind" == "directory" ]] && (( USE_DB == 1 )); then
            echo -e "$(user_prompt_ts_prefix)${GREEN}Rename this directory and update all entries in the database for that subtree?${RESET}"
        else
            echo -e "$(user_prompt_ts_prefix)${GREEN}Rename this ${entry_kind}?${RESET}"
        fi
    fi

    if [[ "$menu_variant" == thumbs-noop || "$menu_variant" == torrent-noop ]]; then
        echo "  [Y] or Enter — Skip (default; no rename to apply)"
        echo "  [N] Skip"
    else
        echo "  [Y] Yes (default)"
        echo "  [N] No"
    fi
    echo "  [M] Rename by editing target filename"
    echo "  [A] All remaining"
    echo "  [D] Yes for this directory"
    if [[ -n "$path" && -f "$path" ]]; then
        echo "  [S] Yes for similar names in this directory (all extensions here; leading _ only if this filename starts with _)"
        choice_hint+=/s
    fi
    if [[ -n "$path" && -n "$suggested_new" ]] && rename_suggested_only_extension_case_change "$path" "$suggested_new" \
        && ! path_filesystem_skip_case_only_rename "$path"; then
        echo "  [L] Yes, and auto-approve all extension case-only lowercasing for this run (no further prompts)"
        choice_hint+=/l
        if eligible_for_media_office_extension_case_auto "$path"; then
            echo "  [U] Yes, and auto-approve extension case-only lowercasing only for media + Microsoft Office files"
            choice_hint+=/u
        fi
    fi
    if [[ -n "$path" ]] && is_torrent_url_file "$path"; then
        echo "  [T] Delete this torrent .URL shortcut"
        choice_hint+=/t
    fi
    if [[ -n "$path" ]] && is_thumbs_db_file "$path"; then
        echo "  [K] Delete this thumbs.db file"
        echo "  [O] Delete this thumbs.db and all other thumbs.db files for the rest of this run"
        choice_hint+=/ko
    fi
    if [[ -n "$path" && ( -f "$path" || -d "$path" ) ]]; then
        echo "  [F] Filename-only exception — skip this basename everywhere (any file or directory with this name)"
        choice_hint+=/f
    fi
    if [[ -n "$path" && -f "$path" ]]; then
        echo "  [B] Skip the directory where this file lives and everything under it (subtree exception)"
        choice_hint+=/b
    elif [[ -n "$path" && -d "$path" ]]; then
        echo "  [B] Skip this directory and everything under it (subtree exception)"
        choice_hint+=/b
    fi
    if [[ -n "$path" ]]; then
        print_prompt_view_directory_menu_line
        choice_hint+=/v
    fi
    echo "  [E] Add exception (skip this path and its subtree by filter match)"
    echo "  [X] Exact exception (do not rename only this exact path; still check subtree)"
    echo "  [C] Custom exclude pattern — type any filter line (FILE=, SUBTREE=, glob, etc.)"
    choice_hint+=/c
    echo "  [Q] Quit"
    choice_hint+="/E/x/q]: "
    echo -n "$(user_prompt_ts_prefix)$choice_hint"
}

maybe_prompt_flatten_single_child_dir() {
    local parent_dir="$1"
    local -a immediate_entries=() child_dirs=() child_non_dirs=() child_items=()
    local child_dir="" child_base="" parent_base="" answer="" item="" item_base=""
    local name_choice="" edited_base="" target_base="" target_dir="" parent_parent_dir=""
    local saved_dotglob saved_nullglob

    [[ -d "$parent_dir" ]] || return 0
    if flatten_exception_exists_for_path "$parent_dir"; then
        vlog "Flatten prompt skipped due to flatten exception: '$parent_dir'"
        return 0
    fi

    saved_dotglob="$(shopt -p dotglob || true)"
    saved_nullglob="$(shopt -p nullglob || true)"
    shopt -s dotglob nullglob

    immediate_entries=( "$parent_dir"/* )
    eval "$saved_dotglob"
    eval "$saved_nullglob"

    for item in "${immediate_entries[@]}"; do
        [[ -e "$item" ]] || continue
        if [[ -d "$item" ]]; then
            child_dirs+=( "$item" )
        else
            child_non_dirs+=( "$item" )
        fi
    done

    (( ${#child_dirs[@]} == 1 )) || return 0
    (( ${#child_non_dirs[@]} == 0 )) || return 0

    child_dir="${child_dirs[0]}"
    [[ -d "$child_dir" ]] || return 0
    child_base="$(basename -- "$child_dir")"
    parent_base="$(basename -- "$parent_dir")"
    parent_parent_dir="$(dirname -- "$parent_dir")"

    # DVD VIDEO_TS folder: do not offer to flatten (standard single-subdir layout).
    if [[ "${child_base,,}" == "video_ts" ]]; then
        vlog "Flatten prompt skipped: sole subdirectory is VIDEO_TS (DVD layout): '$child_dir'"
        return 0
    fi

    if ! find "$child_dir" -type f -print -quit | grep -q .; then
        return 0
    fi

    while true; do
        echo
        emit_wrap_labeled_stdout "FLATTEN CANDIDATE: " "${CYAN}FLATTEN CANDIDATE:${RESET} " "$parent_dir"
        echo "Contains exactly one subdirectory with files:"
        echo "  $child_dir"
        echo -e "$(user_prompt_ts_prefix)${GREEN}Move child contents one level up and delete this subdirectory?${RESET}"
        echo "  [Y] Yes — flatten (move child contents up, remove subdirectory; then choose folder name)"
        echo "  [N] No (default) — keep current folder layout"
        echo "  [E] Add flatten exception — skip flatten prompts for this directory in the future"
        echo "  [C] Custom exclude pattern — type any filter line (FLATTEN_EXACT=, SUBTREE=, glob, etc.)"
        print_prompt_view_directory_menu_line
        echo "  [Q] Quit — stop the script"
        echo -n "$(user_prompt_ts_prefix)Choice [y/N/e/c/v/q]: "
        flush_stdin
        read_single_key answer "$PROMPT_WAIT_SECONDS"
        echo

        if handle_prompt_directory_listing_choice "$answer" "$parent_dir"; then
            continue
        fi
        if [[ "$answer" =~ [Qq] ]]; then
            stopped_by_user=yes
            return 2
        fi
        if [[ "$answer" =~ [Ee] ]]; then
            append_flatten_exception_to_exclude_filters_file "$parent_dir"
            return 0
        fi
        if [[ "$answer" =~ [Cc] ]]; then
            if prompt_custom_exclude_pattern_from_user flatten; then
                return 0
            fi
            continue
        fi
        [[ "$answer" =~ [Yy] ]] || return 0
        break
    done

    while true; do
        echo "$(user_prompt_ts_prefix)Which directory name should remain after flatten?"
        echo "  [P] Keep parent name: $parent_base (default)"
        echo "  [C] Keep child name:  $child_base"
        echo "  [M] Manually edit resulting basename"
        print_prompt_view_directory_menu_line
        echo "  [Q] Quit"
        echo -n "$(user_prompt_ts_prefix)Choice [P/c/m/v/q]: "
        flush_stdin
        read_single_key name_choice "$PROMPT_WAIT_SECONDS"
        echo

        if handle_prompt_directory_listing_choice "$name_choice" "$parent_dir"; then
            continue
        fi
        case "$name_choice" in
        q|Q)
            stopped_by_user=yes
            return 2
            ;;
        c|C)
            target_base="$child_base"
            ;;
        m|M)
            echo "$(user_prompt_ts_prefix)Manual basename edit (readline enabled):"
            echo "  Use arrows/Home/End for cursor movement and editing."
            echo -n "$(user_prompt_ts_prefix)New basename: "
            read_line_editable edited_base "$PROMPT_WAIT_SECONDS" "$parent_base"
            echo
            if [[ -z "$edited_base" ]]; then
                edited_base="$parent_base"
            fi
            if [[ "$edited_base" == *"/"* || "$edited_base" == "." || "$edited_base" == ".." ]]; then
                emit_wrap_labeled_stdout "SKIP FLATTEN: Invalid basename: " "${YELLOW}SKIP FLATTEN:${RESET} Invalid basename: " "'${edited_base}'"
                ((++files_skipped))
                return 0
            fi
            target_base="$edited_base"
            ;;
        *)
            target_base="$parent_base"
            ;;
        esac
        break
    done

    if [[ "$parent_parent_dir" == "." ]]; then
        target_dir="./$target_base"
    else
        target_dir="$parent_parent_dir/$target_base"
    fi

    if [[ "$target_dir" == "$parent_dir" ]]; then
        saved_dotglob="$(shopt -p dotglob || true)"
        saved_nullglob="$(shopt -p nullglob || true)"
        shopt -s dotglob nullglob
        child_items=( "$child_dir"/* )
        eval "$saved_dotglob"
        eval "$saved_nullglob"

        if (( ${#child_items[@]} == 0 )); then
            return 0
        fi

        for item in "${child_items[@]}"; do
            [[ -e "$item" ]] || continue
            item_base="$(basename -- "$item")"
            if [[ -e "$parent_dir/$item_base" ]]; then
                emit_wrap_labeled_stdout "SKIP FLATTEN: Target already exists: " "${YELLOW}SKIP FLATTEN:${RESET} Target already exists: " "$parent_dir/$item_base"
                ((++files_skipped))
                return 0
            fi
        done

        if [[ "$mode" == "dry-run" ]]; then
            emit_wrap_old_arrow_new_stdout "[DRY-RUN] Would flatten: " "${CYAN}[DRY-RUN] Would flatten:${RESET} " "$child_dir" "$parent_dir"
            ((++files_affected))
            record_rename "$child_dir" "$parent_dir"
            return 0
        fi

        for item in "${child_items[@]}"; do
            [[ -e "$item" ]] || continue
            mv -i -- "$item" "$parent_dir/"
        done

        if rmdir -- "$child_dir"; then
            ((++files_affected))
            record_rename "$child_dir" "$parent_dir"
            db_rewrite_subtree "$child_dir" "$parent_dir"
            processed["$child_dir"]=1
            db_mark_checked "$parent_dir" "plain" "checked"
            vlog "Flattened '$child_dir' into '$parent_dir' (kept parent name)"
        else
            emit_wrap_labeled_stdout "SKIP FLATTEN: Could not remove directory (not empty?): " "${YELLOW}SKIP FLATTEN:${RESET} Could not remove directory (not empty?): " "$child_dir"
            ((++files_skipped))
            return 0
        fi

        return 0
    fi

    if [[ -e "$target_dir" ]]; then
        emit_wrap_labeled_stdout "SKIP FLATTEN: Target directory already exists: " "${YELLOW}SKIP FLATTEN:${RESET} Target directory already exists: " "$target_dir"
        ((++files_skipped))
        return 0
    fi

    if [[ "$mode" == "dry-run" ]]; then
        emit_wrap_old_arrow_new_stdout "[DRY-RUN] Would flatten by promoting child directory: " "${CYAN}[DRY-RUN] Would flatten by promoting child directory:${RESET} " "$child_dir" "$target_dir"
        ((++files_affected))
        record_rename "$child_dir" "$target_dir"
        return 0
    fi

    if mv -i -- "$child_dir" "$target_dir"; then
        if rmdir -- "$parent_dir"; then
            ((++files_affected))
            record_rename "$child_dir" "$target_dir"
            db_rewrite_subtree "$child_dir" "$target_dir"
            processed["$child_dir"]=1
            processed["$parent_dir"]=1
            processed["$target_dir"]=1
            db_mark_checked "$target_dir" "plain" "checked"
            vlog "Flattened '$parent_dir' by keeping basename '$target_base' -> '$target_dir'"
        else
            if mv -i -- "$target_dir" "$child_dir"; then
                emit_wrap_labeled_stdout "SKIP FLATTEN: Could not remove parent directory after promote, reverted move: " "${YELLOW}SKIP FLATTEN:${RESET} Could not remove parent directory after promote, reverted move: " "$parent_dir"
            else
                emit_wrap_labeled_stdout "SKIP FLATTEN: Could not remove parent directory and failed to rollback move. Current location: " "${YELLOW}SKIP FLATTEN:${RESET} Could not remove parent directory and failed to rollback move. Current location: " "$target_dir"
            fi
            ((++files_skipped))
        fi
    else
        emit_wrap_labeled_stdout "SKIP FLATTEN: Could not promote " "${YELLOW}SKIP FLATTEN:${RESET} Could not promote " "'${child_dir}' to '${target_dir}'"
        ((++files_skipped))
    fi

    return 0
}

choose_custom_rename_target() {
    local old_path="$1"
    local suggested_path="$2"
    local dir suggested_base edited_base

    dir="$(dirname -- "$old_path")"
    suggested_base="$(basename -- "$suggested_path")"

    echo >&2
    echo -e "$(user_prompt_ts_prefix)${GREEN}Rename by editing target filename (basename only):${RESET}" >&2
    echo "  Use arrows/Home/End for cursor movement and editing." >&2
    echo "  Current suggestion: $suggested_base" >&2
    echo -n "$(user_prompt_ts_prefix)New basename: " >&2
    read_line_editable edited_base "$PROMPT_WAIT_SECONDS" "$suggested_base"
    echo >&2

    if [[ -z "$edited_base" ]]; then
        edited_base="$suggested_base"
    fi

    if [[ "$edited_base" == *"/"* ]]; then
        echo -e "${YELLOW}SKIP:${RESET} Edited name must be a basename only (no '/')."
        return 1
    fi
    if [[ "$edited_base" == "." || "$edited_base" == ".." ]]; then
        emit_wrap_labeled_stdout "SKIP: " "${YELLOW}SKIP:${RESET} " "Invalid edited basename: '$edited_base'"
        return 1
    fi

    if [[ "$dir" == "." ]]; then
        printf './%s' "$edited_base"
    else
        printf '%s/%s' "$dir" "$edited_base"
    fi
}

print_checksum_prompt_menu() {
    nonverbose_progress_dot_prepare_for_prompt
    local label_lower="$1"
    local hash_file="$2"
    local label_upper="${label_lower^^}"

    echo -e "$(user_prompt_ts_prefix)${GREEN}Apply this entire ${label_upper} checksum group?${RESET}"
    emit_wrap_labeled_stdout "  ${label_upper} file (contains hashes and paths): " "  ${label_upper} file (contains hashes and paths): " "$hash_file"
    echo "  One confirmation does everything together:"
    echo "    • Rename each referenced file where OLD referenced file → NEW referenced file was shown above"
    echo "    • Rename this ${label_upper} file only if OLD ${label_upper} → NEW ${label_upper} was shown above"
    echo "    • Rewrite path lines inside the ${label_upper} file, then verify checksums"
    echo "  [Y] Yes — do all of the above (default)"
    echo "  [N] No — skip this whole group"
    echo "  [A] All remaining checksum groups (same full treatment)"
    echo "  [D] Yes for checksum groups in this directory"
    echo "  [E] Add exception (skip paths matching this hash file basename via exclude filter)"
    echo "  [X] Exact exception (skip only this hash file path; still check other paths)"
    echo "  [F] Filename-only exception (skip this hash file basename in every directory)"
    echo "  [C] Custom exclude pattern — type any filter line (FILE=, SUBTREE=, glob, etc.)"
    print_prompt_view_directory_menu_line
    echo "  [Q] Quit"
    echo -n "$(user_prompt_ts_prefix)Choice [Y/n/a/d/E/x/f/c/v/q]: "
}

print_rename_action_verbose() {
    (( VERBOSE == 1 )) || return 0
    local old_path="$1"
    local new_path="$2"
    local reason="${3-}"

    local line="[VERBOSE] Renaming '${old_path}' -> '${new_path}'"
    local second=""
    if [[ -n "$reason" ]]; then
        second="due to ${reason}"
        line="${line} ${second}"
    fi
    if [[ -d "$old_path" ]]; then
        line+=" [directory]"
    fi

    if (( ${#line} <= MAX_LINE_LENGTH )); then
        echo "$line" >&2
    else
        echo "[VERBOSE] Renaming '${old_path}'" >&2
        echo "          -> '${new_path}'${second:+ ${second}}" >&2
    fi
}

print_checksum_group_preview() {
    nonverbose_progress_dot_endline_if_needed
    local label="$1"
    local sum_old="$2"
    local sum_new="$3"
    shift 3
    local refs_name="$1"
    shift
    local new_refs_name="$1"

    local -n _refs="$refs_name"
    local -n _new_refs="$new_refs_name"
    local i shown=0
    local label_colw l_hash l_ref

    l_hash="OLD ${label} (hash file on disk): "
    l_ref="OLD referenced file: "
    if (( ${#l_hash} >= ${#l_ref} )); then
        label_colw=${#l_hash}
    else
        label_colw=${#l_ref}
    fi

    echo
    emit_wrap_labeled_stdout "Checksum group preview (${label}): " "${CYAN}Checksum group preview (${label}):${RESET} " "the hash file lists paths to these files on disk."
    emit_wrap_labeled_stdout "If this hash file would be renamed, it appears as OLD/NEW ${label}; " "${CYAN}If this hash file would be renamed, it appears as OLD/NEW ${label};${RESET} " "otherwise only referenced files are shown."
    echo

    if [[ "$sum_old" != "$sum_new" ]]; then
        emit_wrap_padded_label_stdout "OLD ${label} (hash file on disk): " yellow "$sum_old" "$label_colw"
        emit_wrap_padded_label_stdout "NEW ${label} (hash file on disk): " green "$sum_new" "$label_colw"
        shown=1
    fi

    for i in "${!_refs[@]}"; do
        [[ "${_new_refs[$i]}" != "${_refs[$i]}" ]] || continue
        emit_wrap_padded_label_stdout "OLD referenced file: " yellow "${_refs[$i]}" "$label_colw"
        emit_wrap_padded_label_stdout "NEW referenced file: " green "${_new_refs[$i]}" "$label_colw"
        shown=1
    done

    if (( shown == 0 )); then
        emit_wrap_labeled_stdout "NO VISIBLE RENAME CHANGES: checksum content update only for " "${CYAN}NO VISIBLE RENAME CHANGES:${RESET} checksum content update only for " "$sum_old"
    fi
}


print_summary() {
    (( SUMMARY_PRINTED == 0 )) || return 0
    SUMMARY_PRINTED=1
    SCRIPT_FINISH_TIME="${SCRIPT_FINISH_TIME:-$(date '+%Y-%m-%d %H:%M:%S')}"

    nonverbose_progress_dot_endline_if_needed
    echo
    # Only list entries renamed during THIS run. On a resumed run, renamed_list also holds
    # entries from previous runs (restored from the checkpoint); skip those so we don't show
    # stale renames when the current run changed nothing.
    local _session_base=${RENAMED_LIST_SESSION_BASE:-0}
    total_renamed=${#renamed_list[@]}
    (( _session_base > total_renamed )) && _session_base=$total_renamed
    local _session_renamed=$(( total_renamed - _session_base ))
    if (( _session_renamed > 0 )); then
        if (( RESUME_STATE_WAS_LOADED == 1 )); then
            echo "Affected entries this run (last 100):"
        else
            echo "Affected entries (last 100):"
        fi
        start_idx=$_session_base
        if (( _session_renamed > 100 )); then
            start_idx=$(( total_renamed - 100 ))
        fi
        local _rsep=" ${ARROW} "
        local _rplain
        for (( idx=start_idx; idx<total_renamed; idx++ )); do
            r="${renamed_list[$idx]}"
            old=${r%%|*}
            new=${r#*|}
            _rplain="  ${old}${_rsep}${new}"
            if (( ${#_rplain} <= MAX_LINE_LENGTH )); then
                if [[ "$use_colors" == yes ]]; then
                    printf "  %s %b%s%b %b%s%b\n" \
                        "$old" \
                        "$RED" "$ARROW" "$RESET" \
                        "${GREEN}" "$new" "${RESET}"
                else
                    printf "  %s %s %s\n" "$old" "$ARROW" "$new"
                fi
            else
                printf "  %s\n" "$old"
                if [[ "$use_colors" == yes ]]; then
                    printf "%s%b%s%b %b%s%b\n" "$WRAP_MSG_INDENT" "$RED" "$ARROW" "$RESET" "${GREEN}" "$new" "${RESET}"
                else
                    printf "%s%s %s\n" "$WRAP_MSG_INDENT" "$ARROW" "$new"
                fi
            fi
        done
        echo
    elif (( RESUME_STATE_WAS_LOADED == 1 )); then
        echo "No entries affected this run (resumed run; ${_session_base} rename(s) from earlier runs are recorded in the checkpoint)."
        echo
    fi

    echo "========= SUMMARY ========="
    echo "Script start time:     $SCRIPT_START_TIME"
    echo "Script finish time:    $SCRIPT_FINISH_TIME"
    echo "Mode:                  $mode"
    echo "Colors enabled:        $use_colors"
    echo "Verbose:               $VERBOSE"
    echo "Scope:                 $process_scope"
    echo "Date placement:        $DATE_PLACEMENT"
    echo "Entries examined:      $files_examined"
    echo "Files processed:       $files_examined"
    echo "Files hashed:          $FILES_HASHED"
    echo "Entries affected:      $files_affected"
    echo "Entries skipped:       $files_skipped"
    echo "Stopped by user:       $stopped_by_user"
    if (( USE_DB == 1 )); then
        echo "DB used:               yes"
        echo "DB hashes added:       $DB_HASHES_ADDED"
        echo "DB rows new:           $DB_ROWS_NEW"
        echo "DB rows updated:       $DB_ROWS_UPDATED"
        echo "DB rows removed:       $DB_ROWS_REMOVED"
        echo "DB stale rows removed: $DB_STALE_ROWS_REMOVED"
        echo "DB hash lookup hits:   $DB_HASH_LOOKUP_HITS"
        echo "DB hash lookup misses: $DB_HASH_LOOKUP_MISSES"
        if (( DB_MAINT_HASH_JOBS_TOTAL > 0 || DB_MAINT_HASH_JOBS_DONE > 0 )); then
            echo "DB hash backfill (partial or maintenance):"
            echo "  hash jobs planned:   $DB_MAINT_HASH_JOBS_TOTAL"
            echo "  hash jobs done:      $DB_MAINT_HASH_JOBS_DONE"
            echo "  hash jobs remaining: $DB_MAINT_HASH_JOBS_REMAINING"
            echo "  md5 slots filled:    $DB_MAINT_HASH_MD5_FILLED"
            echo "  sha512 slots filled: $DB_MAINT_HASH_SHA512_FILLED"
        fi
    else
        echo "DB used:               no"
    fi
    echo "==========================="
}

# Single INT handler: rollback, save resume state, then summary. Ignore further SIGINT during cleanup so a second Ctrl-C cannot exit before print_summary.
on_interrupt() {
    trap '' INT
    nonverbose_progress_dot_endline_if_needed || true
    printf '\n%s\n' "Interrupt received — rolling back in-flight work if needed, then saving checkpoint (large trees: writing JSON can still take several seconds)..." >&2
    rollback_current_operation || true
    stopped_by_user=yes
    SCRIPT_FINISH_TIME="$(date '+%Y-%m-%d %H:%M:%S')"
    if (( USE_DB == 1 )); then
        db_flush_pending || true
    fi
    save_resume_checkpoint || true
    nonverbose_progress_dot_endline_if_needed || true
    echo
    echo "Interrupted by user (Ctrl-C)."
    echo "Checkpoint saved: $RESUME_STATE_FILE"
    print_summary || true
    exit 130
}

trap on_interrupt INT

if [[ "$process_scope" == "current" ]]; then
    startup_progress "Listing immediate children of the current directory (find -maxdepth 1; no recursion into subfolders)..."
else
    startup_progress "Discovering and sorting entries under this tree (can take time on very large directories)..."
fi
if [[ "$process_scope" == "current" ]]; then
    mapfile -d '' -t ordered_paths < <(
        find . -mindepth 1 -maxdepth 1 -depth -print0 |
        VERBOSE="${VERBOSE:-0}" python3 -c "$(cat <<'PY'
import os
import sys
from datetime import datetime

buf = sys.stdin.buffer.read()
items = [x for x in buf.split(b"\0") if x]
verbose = os.environ.get("VERBOSE", "0") == "1"
if verbose and items:
    ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    sys.stderr.write(
        "[STARTUP %s] Sorting %d immediate-child paths (current-directory scope)...\n" % (ts, len(items))
    )
    sys.stderr.flush()


def depth(p: bytes) -> int:
    return p.count(47)


def is_checksum(p: bytes) -> int:
    s = p.decode("utf-8", "surrogateescape")
    return 0 if (s.endswith(".sha512") or s.endswith(".md5")) else 1


items.sort(key=lambda p: (-depth(p), is_checksum(p), p))

if verbose and items:
    ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    sys.stderr.write("[STARTUP %s] Wrote sorted path list to shell.\n" % ts)
    sys.stderr.flush()

sys.stdout.buffer.write(b"\0".join(items) + (b"\0" if items else b""))
PY
)"
    )
else
    mapfile -d '' -t ordered_paths < <(
        find . -depth -mindepth 1 -print0 |
        python3 -c '
import sys
from datetime import datetime
import time
verbose = (len(sys.argv) > 1 and sys.argv[1] == "1")
buf = bytearray()
progress_every = 64 * 1024 * 1024
next_progress = progress_every
start = time.monotonic()
while True:
    chunk = sys.stdin.buffer.read(1024 * 1024)
    if not chunk:
        break
    buf.extend(chunk)
    if verbose and len(buf) >= next_progress:
        ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        mb = len(buf) / (1024.0 * 1024.0)
        elapsed = time.monotonic() - start
        sys.stderr.write(f"[STARTUP {ts}] Discovery buffered: {mb:.1f} MB in {elapsed:.1f}s...\n")
        sys.stderr.flush()
        while len(buf) >= next_progress:
            next_progress += progress_every
items = [x for x in bytes(buf).split(b"\0") if x]
if verbose:
    ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    mb = len(buf) / (1024.0 * 1024.0)
    elapsed = time.monotonic() - start
    sys.stderr.write(f"[STARTUP {ts}] Discovery done: {len(items)} entries buffered ({mb:.1f} MB) in {elapsed:.1f}s. Starting sort...\n")
    sys.stderr.flush()
def depth(p: bytes) -> int:
    s = p.decode("utf-8", "surrogateescape")
    return s.count("/")
def is_checksum(p: bytes) -> int:
    s = p.decode("utf-8", "surrogateescape")
    return 0 if (s.endswith(".sha512") or s.endswith(".md5")) else 1
sort_start = time.monotonic()
items.sort(key=lambda p: (-depth(p), is_checksum(p), p))
if verbose:
    ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    sort_elapsed = time.monotonic() - sort_start
    total_elapsed = time.monotonic() - start
    sys.stderr.write(f"[STARTUP {ts}] Sorting done in {sort_elapsed:.1f}s (total startup discovery/sort: {total_elapsed:.1f}s). Starting transfer to shell...\n")
    sys.stderr.flush()
total_items = len(items)
chunk_items = 50000
report_every = 200000
next_report = report_every
written = 0
for i in range(0, total_items, chunk_items):
    chunk_items_list = items[i:i + chunk_items]
    if not chunk_items_list:
        continue
    sys.stdout.buffer.write(b"\0".join(chunk_items_list) + b"\0")
    written += len(chunk_items_list)
    if verbose:
        while written >= next_report:
            ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            pct = (written * 100.0 / total_items) if total_items else 100.0
            sys.stderr.write(f"[STARTUP {ts}] Transfer progress: {written}/{total_items} entries ({pct:.1f}%)...\n")
            sys.stderr.flush()
            next_report += report_every
if verbose:
    ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    sys.stderr.write(f"[STARTUP {ts}] Transfer to shell complete: {written}/{total_items} entries.\n")
    sys.stderr.flush()
' "$VERBOSE"
    )
fi
startup_progress "Entry discovery and sort complete: ${#ordered_paths[@]} entries"
startup_progress "Entering main processing loop..."

vlog "Discovered entries to process: ${#ordered_paths[@]}"
vlog "Progress box updates every ${VERBOSE_MAIN_EVERY} slot index; non-verbose 'k out of total' = this-session examined + resume offset (continues from the checkpoint position, capped at total)."
maybe_resume_from_checkpoint

if (( RESUME_STATE_WAS_LOADED == 1 )); then
    resume_ordered_hits=0
    for _rp in "${ordered_paths[@]}"; do
        [[ -n "${processed[$_rp]+x}" ]] && ((++resume_ordered_hits))
    done
    _resume_tot=${#ordered_paths[@]}
    _resume_rem=$((_resume_tot - resume_ordered_hits))
    # Make the live "N out of total" counter continue from the resumed position instead of
    # restarting at 1: offset = paths already matched/skipped this run (bounded by total).
    MAIN_LOOP_RESUME_PROGRESS_OFFSET=$resume_ordered_hits
    echo "Resume: ${resume_ordered_hits} of ${_resume_tot} discovered paths match the checkpoint and will be skipped when reached (about ${_resume_rem} paths are not in the checkpoint yet)."
    echo "${WRAP_MSG_INDENT}Progress counter continues from ~${resume_ordered_hits}/${_resume_tot} so you can tell this is a resumed run."
    echo "${WRAP_MSG_INDENT}Traversal is depth/checksum sorted, not \"where you left off\" in walk order — early non-verbose dots are paths that still need handling, not a failed resume."
    vlog "Resume: ${resume_ordered_hits}/${_resume_tot} ordered_paths keys match processed checkpoint map"
    if (( RESUME_CHECKPOINT_PROCESSED_LINES_LOADED > 200 )) && (( resume_ordered_hits * 10 < RESUME_CHECKPOINT_PROCESSED_LINES_LOADED * 3 )); then
        echo "Warning: Checkpoint lists ${RESUME_CHECKPOINT_PROCESSED_LINES_LOADED} paths but only ${resume_ordered_hits} match this run's discovery (different cwd/START_DIR, tree changed, or path spelling)."
    fi
fi

main_index=0
for f in "${ordered_paths[@]}"; do
    precomputed_new=""
    nef_xmp_buddy=""
    RENAME_SIDECAR_KIND=""
    verbose_fs_skip_plain=no
    verbose_fs_skip_sidecar=no
    ((++main_index))
    if (( VERBOSE == 1 && main_index % VERBOSE_MAIN_EVERY == 0 )); then
        print_progress_box "$main_index / ${#ordered_paths[@]}" "$f"
    fi

    [[ -n "${processed[$f]+x}" ]] && continue
    ((++files_examined))
    _fe_mile=$((files_examined - MAIN_LOOP_FILES_EXAMINED_MILESTONE_BASE))
    (( _fe_mile < 0 )) && _fe_mile=0
    # Resume: count from the checkpoint position (offset + this-session examined), bounded by total.
    _fe_mile_display=$((_fe_mile + MAIN_LOOP_RESUME_PROGRESS_OFFSET))
    (( _fe_mile_display > ${#ordered_paths[@]} )) && _fe_mile_display=${#ordered_paths[@]}
    if (( _fe_mile_display != MAIN_LOOP_LAST_MILESTONE_VALUE )); then
        nonverbose_main_loop_progress_milestone "$_fe_mile_display" "${#ordered_paths[@]}"
        MAIN_LOOP_LAST_MILESTONE_VALUE=$_fe_mile_display
    fi
    if [[ -f "$f" ]] && is_checksum_file "$f"; then
        : # checksum groups print full status lines; a progress dot becomes a lone "." on the next emit_wrap line
    else
        nonverbose_main_loop_progress_dot
    fi

    if is_excluded_by_filter_file "$f"; then
        print_skip_path_reason "$f" "was ignored because part of its path matches a filter from $EXCLUDE_FILTERS_FILE."
        vlog "Excluded by filter file: '$f'"
        ((++files_skipped))
        processed["$f"]=1
        continue
    fi

    if is_excluded_path "$f"; then
        vlog "Skipping excluded path '$f'"
        ((++files_skipped))
        processed["$f"]=1
        continue
    fi

    if is_internal_protected_path "$f"; then
        vlog "Protected internal file, no rename needed for '$f'"
        db_backfill_missing_hashes_for_existing_file "$f"
        ((++files_skipped))
        db_mark_checked "$f" "plain" "checked"
        processed["$f"]=1
        continue
    fi

    if [[ -f "$f" && "$f" == *.lnk ]]; then
        if ! handle_lnk_file "$f"; then
            break
        fi
        processed["$f"]=1
        continue
    fi

    if [[ -d "$f" ]]; then
        maybe_prompt_flatten_single_child_dir "$f"
        flatten_rc=$?
        if (( flatten_rc == 2 )); then
            break
        fi
    fi

    if db_has_valid_entry "$f" && ! path_has_control_chars "$f"; then
        _rename_cap_save_e=0
        [[ $- == *e* ]] && _rename_cap_save_e=1
        set +e
        precomputed_new="$(transform_name "$f")"
        tnf_rc=$?
        precomputed_new="$(collapse_stacked_other_suffix_in_path "$precomputed_new")"
        if ((_rename_cap_save_e)); then
            set -e
        else
            set +e
        fi
        if (( tnf_rc == 2 )); then
            break
        fi
        crr=1
        if [[ -f "$f" ]] && is_checksum_file "$f"; then
            _rename_cap_save_e=0
            [[ $- == *e* ]] && _rename_cap_save_e=1
            set +e
            _db_cache_checksum_err_trap="$(trap -p ERR || true)"
            trap - ERR
            checksum_file_has_renamable_refs "$f"
            crr=$?
            eval "${_db_cache_checksum_err_trap:-}"
            if ((_rename_cap_save_e)); then
                set -e
            else
                set +e
            fi
            if (( crr == 2 )); then
                break
            fi
        fi
        if [[ "$f" != "$precomputed_new" ]]; then
            vlog "DB cache hit for '$f' but rename is still needed; processing entry."
        elif (( crr == 0 )); then
            vlog "DB cache hit for '$f' but referenced checksum entries still need rename; processing checksum file."
        else
            db_backfill_missing_hashes_for_existing_file "$f"
            if path_has_control_chars "$f"; then
                print_control_char_warning "$f"
            fi
            emit_wrap_labeled_stdout "DB SKIP: " "${CYAN}DB SKIP:${RESET} " "'$(format_path_for_log "$f")'"
            # DB SKIP already printed an explicit per-path line; suppress the next iteration's
            # lone progress dot so a run of cache hits reads as clean "DB SKIP" lines instead of
            # alternating "DB SKIP" / "." (mirrors the auto-dir "Renamed:" behavior).
            NONVERBOSE_SKIP_NEXT_MAIN_LOOP_DOT=yes
            ((++files_skipped))
            processed["$f"]=1
            continue
        fi
    fi

    if [[ -f "$f" ]] && is_checksum_file "$f"; then
        sum_file="$f"
        label="$(checksum_label "$sum_file")"
        sum_file_check_kind="$(checksum_kind "$sum_file")" || sum_file_check_kind=""

        vlog "Processing checksum file '$sum_file'"

        if [[ "$mode" == "real" ]]; then
            ensure_checksum_file_unix_format "$sum_file"
        fi

        refs_raw=()
        refs=()
        expected_hashes=()

        while IFS=$'\t' read -r hash ref; do
            [[ -n "$ref" ]] || continue
            expected_hashes+=( "$hash" )
            refs_raw+=( "$ref" )
            refs+=( "$(resolve_checksum_ref_path "$sum_file" "$ref")" )
            nonverbose_checksum_ref_verify_progress_letter "$sum_file_check_kind" "$sum_file"
            print_resolved_ref_verbose "$ref" "${refs[-1]}"
        done < <(extract_checksum_entries "$sum_file")

        if (( ${#refs[@]} == 0 )) || [[ -z "${refs[0]}" ]]; then
            vlog "Checksum file '$sum_file' has no valid refs"
            ((++files_skipped))
            processed["$sum_file"]=1
            continue
        fi

        declare -a recovered_old_refs=()
        declare -a recovered_new_real_refs=()
        declare -a recovered_new_written_refs=()
        checksum_content_modified=no

        for i in "${!refs[@]}"; do
            ref="${refs[$i]}"
            if [[ -e "$ref" ]]; then
                vlog "Ref exists already: '$ref'"
                continue
            fi

            vlog "Ref missing, trying recovery: '$ref'"
            _fbr_rc=0
            found_ref="$(find_best_path_for_missing_ref "$ref" "${expected_hashes[$i]}" "$sum_file")" || _fbr_rc=$?
            if ((_fbr_rc == 2)); then
                stopped_by_user=yes
                break
            fi
            if [[ -n "$found_ref" ]]; then
                replacement_ref="$(format_ref_for_checksum_file "$sum_file" "${refs_raw[$i]}" "$found_ref")"
                recovered_old_refs+=( "${refs_raw[$i]}" )
                recovered_new_real_refs+=( "$found_ref" )
                recovered_new_written_refs+=( "$replacement_ref" )
                refs_raw[$i]="$replacement_ref"
                refs[$i]="$found_ref"
                checksum_content_modified=yes
                print_recovery_success_verbose "$ref" "$found_ref" "$replacement_ref"
                print_recovery_final_status_verbose "$ref" "success"
                emit_wrap_labeled_stdout "${label} RECOVERY CANDIDATE VERIFIED: " "${CYAN}${label} RECOVERY CANDIDATE VERIFIED:${RESET} " "'$found_ref' matches the stored ${label,,}."
            else
                vlog "Recovery failed for '$ref'"
                print_recovery_final_status_verbose "$ref" "failed"
            fi
        done

        if [[ "$stopped_by_user" == yes ]]; then
            break
        fi

        if (( ${#recovered_old_refs[@]} > 0 )); then
            echo
            emit_wrap_labeled_stdout "${label} RECOVERY: " "${CYAN}${label} RECOVERY:${RESET} " "'$sum_file' references missing file(s), but replacement file(s) were found."
            for i in "${!recovered_old_refs[@]}"; do
                emit_wrap_labeled_stdout "  OLD REF: " "  ${YELLOW}OLD REF:${RESET} " "${recovered_old_refs[$i]}" yellow
                emit_wrap_labeled_stdout "  FOUND: " "  ${GREEN}FOUND:${RESET}   " "${recovered_new_real_refs[$i]}"
                emit_wrap_labeled_stdout "  WRITE: " "  ${GREEN}WRITE:${RESET}   " "${recovered_new_written_refs[$i]}"
            done

            if [[ "$mode" == "real" ]]; then
                ensure_checksum_file_unix_format "$sum_file"
                for i in "${!recovered_old_refs[@]}"; do
                    update_checksum_content_refs "$sum_file" "${recovered_old_refs[$i]}" "${recovered_new_written_refs[$i]}"
                done
                emit_wrap_labeled_stdout "${label} RECOVERY UPDATED: " "${CYAN}${label} RECOVERY UPDATED:${RESET} " "'$sum_file' was updated to point to the found file(s)."
                emit_wrap_labeled_stdout "${label} RECOVERY NOTE: " "${CYAN}${label} RECOVERY NOTE:${RESET} " "full ${label,,} file verification will follow in normal processing."
            else
                _dry_rec="[DRY-RUN] Would update ${label,,} content to use the found file(s) above."
                if (( ${#_dry_rec} <= MAX_LINE_LENGTH )); then
                    echo -e "${CYAN}${_dry_rec}${RESET}"
                else
                    echo -e "${CYAN}[DRY-RUN] Would update ${label,,} content to use the ${RESET}"
                    echo -e "${WRAP_MSG_INDENT}${CYAN}found file(s) above.${RESET}"
                fi
            fi
        fi

        missing=no
        declare -a missing_refs=()
        declare -a missing_thumb_refs=()
        declare -a missing_thumb_raw_refs=()
        declare -a missing_thumb_indexes=()
        thumbs_db_refs_removed=no
        for i in "${!refs[@]}"; do
            ref="${refs[$i]}"
            if [[ ! -e "$ref" ]]; then
                missing=yes
                missing_refs+=( "$ref" )
                if path_basename_is_thumbs_db "$ref"; then
                    missing_thumb_refs+=( "$ref" )
                    missing_thumb_raw_refs+=( "${refs_raw[$i]}" )
                    missing_thumb_indexes+=( "$i" )
                fi
            fi
        done

        if (( ${#missing_thumb_refs[@]} > 0 )); then
            echo
            emit_wrap_labeled_stdout "${label} THUMBS.DB MISSING: " "${CYAN}${label} THUMBS.DB MISSING:${RESET} " "'$sum_file' contains reference(s) to missing thumbs.db file(s)."
            emit_wrap_labeled_stdout "Hash file: " "${CYAN}Hash file:${RESET} " "$sum_file"
            for i in "${!missing_thumb_refs[@]}"; do
                emit_wrap_labeled_stdout "  MISSING THUMBS.DB: " "  ${YELLOW}MISSING THUMBS.DB:${RESET} " "${missing_thumb_refs[$i]}"
                emit_wrap_labeled_stdout "  HASH REF: " "  ${YELLOW}HASH REF:${RESET}          " "${missing_thumb_raw_refs[$i]}"
            done

            if [[ "$mode" == "dry-run" ]]; then
                _dry_th="[DRY-RUN] Would offer to remove the missing thumbs.db reference(s) from this ${label,,} file."
                if (( ${#_dry_th} <= MAX_LINE_LENGTH )); then
                    echo -e "${CYAN}${_dry_th}${RESET}"
                else
                    echo -e "${CYAN}[DRY-RUN] Would offer to remove the missing thumbs.db reference(s) from this ${RESET}"
                    echo -e "${WRAP_MSG_INDENT}${CYAN}${label,,} file.${RESET}"
                fi
            else
                while true; do
                    verbose_question_timestamp "Remove missing thumbs.db reference(s) from this hash file?"
                    echo "  [Y] Yes - remove only the thumbs.db line(s) shown above"
                    echo "  [N] No - keep the hash file unchanged (default)"
                    print_prompt_view_directory_menu_line
                    echo "  [Q] Quit"
                    echo -n "$(user_prompt_ts_prefix)Choice [y/N/v/q]: "
                    flush_stdin
                    read_single_key input "$PROMPT_WAIT_SECONDS"
                    echo

                    if handle_prompt_directory_listing_choice "$input" "$sum_file"; then
                        continue
                    fi
                    break
                done

                case "$input" in
                    q|Q)
                        stopped_by_user=yes
                        break
                        ;;
                    y|Y)
                        ensure_checksum_file_unix_format "$sum_file"
                        for i in "${!missing_thumb_raw_refs[@]}"; do
                            print_checksum_update_verbose "$sum_file" "${missing_thumb_raw_refs[$i]}" "<removed: missing thumbs.db>"
                            remove_checksum_ref_entry "$sum_file" "${missing_thumb_raw_refs[$i]}"
                            emit_wrap_labeled_stdout "${label} REF REMOVED: " "${GREEN}${label} REF REMOVED:${RESET} " "${missing_thumb_raw_refs[$i]}"
                        done
                        thumbs_db_refs_removed=yes
                        ((++files_affected))

                        unset removed_missing_thumb_indexes
                        declare -A removed_missing_thumb_indexes=()
                        for i in "${missing_thumb_indexes[@]}"; do
                            removed_missing_thumb_indexes["$i"]=1
                        done

                        declare -a kept_refs_raw=()
                        declare -a kept_refs=()
                        declare -a kept_expected_hashes=()
                        for i in "${!refs[@]}"; do
                            [[ -n "${removed_missing_thumb_indexes[$i]+x}" ]] && continue
                            kept_refs_raw+=( "${refs_raw[$i]}" )
                            kept_refs+=( "${refs[$i]}" )
                            kept_expected_hashes+=( "${expected_hashes[$i]}" )
                        done
                        refs_raw=( "${kept_refs_raw[@]}" )
                        refs=( "${kept_refs[@]}" )
                        expected_hashes=( "${kept_expected_hashes[@]}" )

                        missing=no
                        missing_refs=()
                        for ref in "${refs[@]}"; do
                            if [[ ! -e "$ref" ]]; then
                                missing=yes
                                missing_refs+=( "$ref" )
                            fi
                        done
                        ;;
                    *)
                        vlog "User kept missing thumbs.db reference(s) in '$sum_file'"
                        ;;
                esac
            fi
        fi

        if [[ "$thumbs_db_refs_removed" == "yes" ]] && (( ${#refs[@]} == 0 )); then
            emit_wrap_labeled_stdout "${label} CLEANUP: " "${CYAN}${label} CLEANUP:${RESET} " "'$sum_file' has no remaining referenced files after thumbs.db cleanup."
            db_mark_checked "$sum_file" "checksum_group" "checked"
            processed["$sum_file"]=1
            continue
        fi

        if [[ "$missing" == "yes" ]]; then
            echo
            emit_wrap_labeled_stdout "${label} SKIP: " "${YELLOW}${label} SKIP:${RESET} " "'$sum_file' still references missing file(s)."
            for i in "${!refs[@]}"; do
                ref="${refs[$i]}"
                [[ -e "$ref" ]] && continue
                emit_wrap_labeled_stdout "  MISSING: " "  ${YELLOW}MISSING:${RESET} " "$ref"
                _rh_save_e=0
                [[ $- == *e* ]] && _rh_save_e=1
                set +e
                _rebuilt_hint="$(checksum_rebuilt_ref_path_by_segments "$(dirname -- "$sum_file")" "$ref")"
                _rh_rc=$?
                ((_rh_save_e)) && set -e || set +e
                if ((_rh_rc == 2)); then
                    stopped_by_user=yes
                    break 2
                fi
                if ((_rh_rc == 0)) && [[ -n "$_rebuilt_hint" ]]; then
                    if [[ -f "$_rebuilt_hint" ]]; then
                        emit_wrap_labeled_stdout "  SAME RULES → ON DISK: " "  ${CYAN}SAME RULES → ON DISK:${RESET} " "$_rebuilt_hint"
                    else
                        emit_wrap_labeled_stdout "  SAME RULES → EXPECTED: " "  ${CYAN}SAME RULES → EXPECTED:${RESET} " "$_rebuilt_hint"
                    fi
                fi
            done
            print_grouped_checksum_missing_warning "$sum_file" "${refs[@]}"
            db_mark_checked "$sum_file" "checksum_group" "missing_refs"
            ((++files_skipped))
            processed["$sum_file"]=1
            continue
        fi

        _rename_cap_save_e=0
        [[ $- == *e* ]] && _rename_cap_save_e=1
        set +e
        new_sum="$(transform_name "$sum_file")"
        tns_rc=$?
        new_sum="$(collapse_stacked_other_suffix_in_path "$new_sum")"
        if ((_rename_cap_save_e)); then
            set -e
        else
            set +e
        fi
        if (( tns_rc == 2 )); then
            break
        fi
        declare -a new_refs=()
        for ref in "${refs[@]}"; do
            _rename_cap_save_e=0
            [[ $- == *e* ]] && _rename_cap_save_e=1
            set +e
            new_ref="$(transform_name "$ref")"
            tnr_rc=$?
            new_ref="$(collapse_stacked_other_suffix_in_path "$new_ref")"
            if ((_rename_cap_save_e)); then
                set -e
            else
                set +e
            fi
            if (( tnr_rc == 2 )); then
                break 2
            fi
            new_refs+=( "$new_ref" )
        done

        declare -a checksum_fs_dropped_refs=()
        for i in "${!new_refs[@]}"; do
            if [[ "${new_refs[$i]}" != "${refs[$i]}" ]] && should_skip_case_only_rename_on_fs "${refs[$i]}" "${new_refs[$i]}"; then
                checksum_fs_dropped_refs+=( "${refs[$i]}" )
                new_refs[$i]="${refs[$i]}"
            fi
        done

        refs_need_rename=no
        for i in "${!new_refs[@]}"; do
            [[ "${new_refs[$i]}" != "${refs[$i]}" ]] && refs_need_rename=yes
        done

        sum_file_needs_rename=no
        checksum_fs_sum_skipped=no
        if [[ "$new_sum" != "$sum_file" ]]; then
            if is_protected_checksum_name "$sum_file"; then
                print_protected_checksum_verbose "$sum_file"
                new_sum="$sum_file"
            elif should_skip_case_only_rename_on_fs "$sum_file" "$new_sum"; then
                checksum_fs_sum_skipped=yes
                new_sum="$sum_file"
            else
                sum_file_needs_rename=yes
            fi
        fi

        action_needed=no
        [[ "$refs_need_rename" == "yes" ]] && action_needed=yes
        [[ "$sum_file_needs_rename" == "yes" ]] && action_needed=yes
        [[ "$checksum_content_modified" == "yes" ]] && action_needed=yes

        if [[ "$action_needed" == "no" ]]; then
            checksum_no_action_fs_note=no
            if (( ${#checksum_fs_dropped_refs[@]} > 0 )) || [[ "$checksum_fs_sum_skipped" == yes ]]; then
                checksum_no_action_fs_note=yes
            fi
            print_checksum_no_action_verbose "$sum_file" "$checksum_no_action_fs_note"
            if [[ "$mode" == "real" ]] && (( ${#refs[@]} > 0 )); then
                local_line_count="$(count_checksum_entries "$sum_file")"
                if confirm_large_hash_check "$sum_file" "$label" "$local_line_count" refs; then
                    ensure_checksum_file_unix_format "$sum_file"
                    checksum_list_verify_ignored=no
                    for i in "${!refs[@]}"; do
                        vrc=0
                        verify_single_checksum_target "$sum_file" "${refs_raw[$i]}" || vrc=$?
                        if (( vrc == 0 )); then
                            continue
                        fi
                        if (( vrc == 2 )); then
                            print_checksum_fail_no_matching_line "$label" "${refs_raw[$i]}" "$sum_file"
                            echo "  Check that the path column in the list matches this reference exactly (including spaces and any * prefix)."
                            stop_on_checksum_failure "$sum_file" "checksum list check"
                        fi
                        print_checksum_fail_mismatch_line "$label" "${refs_raw[$i]}" "$sum_file"
                        mismatch_menu_rc=0
                        prompt_refresh_checksum_hash_after_mismatch "$sum_file" "${refs_raw[$i]}" "${refs[$i]}" "checksum list check" || mismatch_menu_rc=$?
                        if (( mismatch_menu_rc == 0 || mismatch_menu_rc == 2 )); then
                            (( mismatch_menu_rc == 2 )) && checksum_list_verify_ignored=yes
                            continue
                        fi
                        stop_on_checksum_user_quit_after_mismatch "$sum_file" "checksum list check"
                    done
                    if [[ "$checksum_list_verify_ignored" != yes ]]; then
                        record_checksum_list_full_verify_success "$sum_file"
                    fi
                else
                    rc=$?
                    if [[ $rc -eq 2 ]]; then
                        break
                    fi
                fi
            fi
            ((++files_skipped))
            db_mark_checked "$sum_file" "checksum_group" "checked"
            db_mark_many_checked "checksum_ref" "checked" "${refs[@]}"
            processed["$sum_file"]=1
            for ref in "${refs[@]}"; do processed["$ref"]=1; done
            continue
        fi

        for _cfs_ref in "${checksum_fs_dropped_refs[@]}"; do
            vlog "Dropping case-only ref rename on exfat/CIFS/Samba (checksum group): '$_cfs_ref'"
        done
        if [[ "$checksum_fs_sum_skipped" == yes ]]; then
            vlog "Dropping case-only checksum file rename on exfat/CIFS/Samba: '$sum_file'"
        fi

        if [[ "$mode" == "dry-run" ]]; then
            if [[ "$checksum_content_modified" == "yes" ]]; then
                emit_wrap_labeled_stdout "[DRY-RUN] Would check ${label} because checksum content would be modified: " "${CYAN}[DRY-RUN] Would check ${label} because checksum content would be modified:${RESET} " "$sum_file"
            else
                emit_wrap_labeled_stdout "[DRY-RUN] Would check ${label} because rename is needed: " "${CYAN}[DRY-RUN] Would check ${label} because rename is needed:${RESET} " "$sum_file"
            fi
            print_checksum_group_preview "$label" "$sum_file" "$new_sum" refs new_refs
            declare -a html_companion_old_dirs=()
            declare -a html_companion_new_dirs=()
            declare -a html_companion_old_names=()
            declare -a html_companion_new_names=()
            declare -a html_companion_apply=()
            build_checksum_group_html_companion_arrays refs new_refs \
                html_companion_old_dirs html_companion_new_dirs \
                html_companion_old_names html_companion_new_names html_companion_apply
            resolve_checksum_group_rename_collisions "$sum_file" new_sum refs new_refs \
                html_companion_apply html_companion_old_dirs html_companion_new_dirs || true
            emit_wrap_labeled_stdout "[DRY-RUN] Would update ${label,,} content references inside: " "${CYAN}[DRY-RUN] Would update ${label,,} content references inside:${RESET} " "$sum_file"
            emit_wrap_labeled_stdout "[DRY-RUN] Would check ${label} reference(s) after rename: " "${CYAN}[DRY-RUN] Would check ${label} reference(s) after rename:${RESET} " "$new_sum"
            echo "----------------------------------------"

            ((++files_affected))
            record_rename "$sum_file" "$new_sum"
            for i in "${!refs[@]}"; do
                record_rename "${refs[$i]}" "${new_refs[$i]}"
            done

            processed["$sum_file"]=1
            for ref in "${refs[@]}"; do processed["$ref"]=1; done
            continue
        fi

        local_line_count="$(count_checksum_entries "$sum_file")"
        if ! confirm_large_hash_check "$sum_file" "$label" "$local_line_count" refs; then
            rc=$?
            if [[ $rc -eq 2 ]]; then
                break
            fi
            emit_wrap_labeled_stdout "SKIP: User chose not to check large ${label,,} file " "${YELLOW}SKIP:${RESET} User chose not to check large ${label,,} file " "'$sum_file'."
            ((++files_skipped))
            processed["$sum_file"]=1
            for ref in "${refs[@]}"; do processed["$ref"]=1; done
            continue
        fi

        ensure_checksum_file_unix_format "$sum_file"

        print_checksum_group_preview "$label" "$sum_file" "$new_sum" refs new_refs

        do_rename=no
        if [[ "$rename_all" == "yes" ]]; then
            do_rename=yes
        elif auto_yes_current_dir_matches "$sum_file"; then
            do_rename=yes
        else
            while true; do
                print_checksum_prompt_menu "${label,,}" "$sum_file"
                flush_stdin
                read_single_key input "$PROMPT_WAIT_SECONDS"
                echo
                if handle_prompt_directory_listing_choice "$input" "$sum_file"; then
                    continue
                fi
                if [[ "$input" =~ [Cc] ]]; then
                    if prompt_custom_exclude_pattern_from_user; then
                        input='C'
                    else
                        continue
                    fi
                fi
                break
            done
            NONVERBOSE_SKIP_NEXT_MAIN_LOOP_DOT=yes

            case "$input" in
                q|Q)
                    stopped_by_user=yes
                    break
                    ;;
                n|N)
                    ((++files_skipped))
                    do_rename=no
                    ;;
                a|A)
                    echo "$(user_prompt_ts_prefix)⚠️  This will rename ALL remaining files/directories."
                    if (( VERBOSE == 1 )); then
                        echo "[VERBOSE] [$(date '+%Y.%m.%d %H:%M:%S')] Are you sure? [y/N]:" >&2
                    fi
                    echo -n "$(user_prompt_ts_prefix)Are you sure? [y/N]: "
                    flush_stdin
                    read_single_key confirm "$PROMPT_WAIT_SECONDS"
                    echo
                    if [[ "$confirm" =~ [Yy] ]]; then
                        rename_all=yes
                        do_rename=yes
                    else
                        ((++files_skipped))
                        do_rename=no
                    fi
                    ;;
                d|D)
                    AUTO_RENAME_DIR="$(dirname -- "$sum_file")"
                    do_rename=yes
                    ;;
                e|E)
                    append_path_to_exclude_filters_file "$sum_file"
                    ((++files_skipped))
                    do_rename=no
                    ;;
                x|X)
                    append_exact_path_to_exclude_filters_file "$sum_file"
                    ((++files_skipped))
                    do_rename=no
                    ;;
                f|F)
                    if append_filename_only_exception_to_exclude_filters_file "$sum_file"; then
                        ((++files_skipped))
                    else
                        ((++files_skipped))
                    fi
                    do_rename=no
                    ;;
                c|C)
                    ((++files_skipped))
                    do_rename=no
                    ;;
                *)
                    do_rename=yes
                    ;;
            esac
        fi

        if [[ "$do_rename" != "yes" ]]; then
            vlog "User skipped checksum group '$sum_file'"
            processed["$sum_file"]=1
            for ref in "${refs[@]}"; do processed["$ref"]=1; done
            continue
        fi

        begin_current_operation "$label" "$sum_file" "$new_sum"

        if (( ${#refs[@]} > 0 )); then
            print_checksum_verify_progress_line "$label" before "$sum_file"
            checksum_before_rename_ignored=no
            for i in "${!refs[@]}"; do
                vrc=0
                verify_single_checksum_target "$sum_file" "${refs_raw[$i]}" || vrc=$?
                if (( vrc == 0 )); then
                    continue
                fi
                if (( vrc == 2 )); then
                    print_checksum_fail_no_matching_line "$label" "${refs_raw[$i]}" "$sum_file"
                    echo "  Check that the path column in the list matches this reference exactly (including spaces and any * prefix)."
                    stop_on_checksum_failure "$sum_file" "before rename"
                fi
                print_checksum_fail_mismatch_line "$label" "${refs_raw[$i]}" "$sum_file"
                mismatch_menu_rc=0
                prompt_refresh_checksum_hash_after_mismatch "$sum_file" "${refs_raw[$i]}" "${refs[$i]}" "before rename" || mismatch_menu_rc=$?
                if (( mismatch_menu_rc == 0 || mismatch_menu_rc == 2 )); then
                    (( mismatch_menu_rc == 2 )) && checksum_before_rename_ignored=yes
                    continue
                fi
                stop_on_checksum_user_quit_after_mismatch "$sum_file" "before rename"
            done
            if [[ "$checksum_before_rename_ignored" == yes ]]; then
                emit_wrap_labeled_stdout "${label} NOTE: " "${YELLOW}${label} NOTE:${RESET} " "At least one reference had a checksum mismatch you chose [I] to ignore; not all references were verified before rename."
            else
                print_checksum_verified_refs_line "$label" before "$sum_file"
            fi
        fi

        declare -a html_companion_old_dirs=()
        declare -a html_companion_new_dirs=()
        declare -a html_companion_old_names=()
        declare -a html_companion_new_names=()
        declare -a html_companion_apply=()
        declare -a html_hash_needs_refresh=()

        build_checksum_group_html_companion_arrays refs new_refs \
            html_companion_old_dirs html_companion_new_dirs \
            html_companion_old_names html_companion_new_names html_companion_apply
        for i in "${!refs[@]}"; do
            html_hash_needs_refresh+=( "no" )
        done

        checksum_group_collision_rc=0
        resolve_checksum_group_rename_collisions "$sum_file" new_sum refs new_refs \
            html_companion_apply html_companion_old_dirs html_companion_new_dirs || checksum_group_collision_rc=$?
        if (( checksum_group_collision_rc == 2 )); then
            stopped_by_user=yes
            break
        fi
        if (( checksum_group_collision_rc == 1 )); then
            emit_wrap_labeled_stdout "SKIP: " "${YELLOW}SKIP:${RESET} " "Target file already exists."
            vlog "Collision detected in checksum group '$sum_file' (user skipped or unresolved)"
            finish_current_operation
            ((++files_skipped))
            processed["$sum_file"]=1
            for ref in "${refs[@]}"; do processed["$ref"]=1; done
            continue
        fi

        for i in "${!refs[@]}"; do
            if [[ "${new_refs[$i]}" != "${refs[$i]}" ]]; then
                if [[ ! -e "${refs[$i]}" ]]; then
                    vlog "Checksum group ref source already removed (collision delete-source): '${refs[$i]}'"
                    ((++files_skipped))
                    continue
                fi
                ref_was_dir=no
                [[ -d "${refs[$i]}" ]] && ref_was_dir=yes
                print_rename_action_verbose "${refs[$i]}" "${new_refs[$i]}" "checksum group rename"
                mv_with_case_only_filesystem_workaround "${refs[$i]}" "${new_refs[$i]}"
                if [[ "$ref_was_dir" == "yes" ]]; then
                    db_rewrite_subtree "${refs[$i]}" "${new_refs[$i]}"
                else
                    db_rewrite_single_path "${refs[$i]}" "${new_refs[$i]}"
                fi
                register_current_file_rename "${refs[$i]}" "${new_refs[$i]}"
                ((++files_affected))
                record_rename "${refs[$i]}" "${new_refs[$i]}"

                if [[ "${html_companion_apply[$i]}" == "yes" ]]; then
                    emit_wrap_labeled_stdout "HTML PAIR RENAME: " "${CYAN}HTML PAIR RENAME:${RESET} " "HTML file and companion directory are being updated together."
                    emit_wrap_labeled_stdout "  OLD HTML: " "  ${YELLOW}OLD HTML:${RESET} " "${refs[$i]}" yellow
                    emit_wrap_labeled_stdout "  NEW HTML: " "  ${GREEN}NEW HTML:${RESET} " "${new_refs[$i]}" green
                    emit_wrap_labeled_stdout "  OLD DIR: " "  ${YELLOW}OLD DIR:${RESET}  " "${html_companion_old_dirs[$i]}" yellow
                    emit_wrap_labeled_stdout "  NEW DIR: " "  ${GREEN}NEW DIR:${RESET}  " "${html_companion_new_dirs[$i]}" green
                    print_rename_action_verbose "${html_companion_old_dirs[$i]}" "${html_companion_new_dirs[$i]}" "html companion rename"
                    if should_skip_case_only_rename_on_fs "${html_companion_old_dirs[$i]}" "${html_companion_new_dirs[$i]}"; then
                        vlog "Skipping case-only HTML companion directory rename on exfat/CIFS/Samba (checksum group): '${html_companion_old_dirs[$i]}'"
                        ((++files_skipped))
                        db_mark_checked "${html_companion_old_dirs[$i]}" "html_companion" "checked"
                    else
                        mv_with_case_only_filesystem_workaround "${html_companion_old_dirs[$i]}" "${html_companion_new_dirs[$i]}"
                        db_rewrite_subtree "${html_companion_old_dirs[$i]}" "${html_companion_new_dirs[$i]}"
                        db_mark_renamed_path_checked "${html_companion_new_dirs[$i]}" "plain"
                        register_current_file_rename "${html_companion_old_dirs[$i]}" "${html_companion_new_dirs[$i]}"
                        ((++files_affected))
                        record_rename "${html_companion_old_dirs[$i]}" "${html_companion_new_dirs[$i]}"
                        update_html_companion_reference "${new_refs[$i]}" "${html_companion_old_names[$i]}" "${html_companion_new_names[$i]}"
                        emit_wrap_labeled_stdout "HTML PAIR UPDATED: companion reference inside HTML file was updated from " "${CYAN}HTML PAIR UPDATED:${RESET} companion reference inside HTML file was updated from " "'${html_companion_old_names[$i]}' to '${html_companion_new_names[$i]}'."
                        html_hash_needs_refresh[$i]="yes"
                    fi
                fi
            else
                ((++files_skipped))
            fi
        done

        for i in "${!refs[@]}"; do
            old_ref_for_write="$(format_ref_for_checksum_file "$sum_file" "${refs_raw[$i]}" "${refs[$i]}")"
            new_ref_for_write="$(format_ref_for_checksum_file "$sum_file" "${refs_raw[$i]}" "${new_refs[$i]}")"
            if [[ "$old_ref_for_write" != "$new_ref_for_write" ]]; then
                update_checksum_content_refs "$sum_file" "$old_ref_for_write" "$new_ref_for_write"
            fi

            if [[ "${html_hash_needs_refresh[$i]}" == "yes" ]]; then
                update_checksum_hash_for_ref "$sum_file" "$new_ref_for_write" "${new_refs[$i]}"
            fi
        done

        final_sum="$sum_file"
        if [[ "$new_sum" != "$sum_file" ]]; then
            print_checksum_file_rename_verbose "$sum_file" "$new_sum"
            mv_with_case_only_filesystem_workaround "$sum_file" "$new_sum"
            db_rewrite_single_path "$sum_file" "$new_sum"
            mark_current_sum_renamed
            ((++files_affected))
            record_rename "$sum_file" "$new_sum"
            final_sum="$new_sum"
        else
            ((++files_skipped))
        fi

        if (( ${#refs[@]} > 0 )); then
            print_checksum_verify_progress_line "$label" after "$final_sum"
            checksum_after_rename_ignored=no
            for i in "${!refs[@]}"; do
                new_ref_for_verify="$(format_ref_for_checksum_file "$final_sum" "${refs_raw[$i]}" "${new_refs[$i]}")"
                vrc=0
                verify_single_checksum_target "$final_sum" "$new_ref_for_verify" || vrc=$?
                if (( vrc == 0 )); then
                    continue
                fi
                if (( vrc == 2 )); then
                    print_checksum_fail_after_no_line "$label" "$new_ref_for_verify" "$final_sum"
                    emit_wrap_labeled_stdout "NOTE: " "${YELLOW}NOTE:${RESET} " "Files were renamed; checksum file may be inconsistent."
                    stop_on_checksum_failure "$final_sum" "after rename"
                fi
                print_checksum_fail_after_validate_line "$label" "$new_ref_for_verify" "$final_sum"
                emit_wrap_labeled_stdout "NOTE: " "${YELLOW}NOTE:${RESET} " "Files were renamed, but checksum verification after update failed."
                mismatch_menu_rc=0
                prompt_refresh_checksum_hash_after_mismatch "$final_sum" "$new_ref_for_verify" "${new_refs[$i]}" "after rename" || mismatch_menu_rc=$?
                if (( mismatch_menu_rc == 0 || mismatch_menu_rc == 2 )); then
                    (( mismatch_menu_rc == 2 )) && checksum_after_rename_ignored=yes
                    continue
                fi
                stop_on_checksum_user_quit_after_mismatch "$final_sum" "after rename"
            done
            if [[ "$checksum_after_rename_ignored" == yes ]]; then
                emit_wrap_labeled_stdout "${label} NOTE: " "${YELLOW}${label} NOTE:${RESET} " "At least one reference still does not match the list after rename ([I] ignore); checksum file may be wrong until you fix or [U]pdate."
            else
                print_checksum_verified_refs_line "$label" after "$final_sum"
                print_checksum_group_ok_line "$label" "$final_sum"
                record_checksum_list_full_verify_success "$final_sum"
            fi
        fi

        finish_current_operation
        vlog "Finished checksum group '$sum_file'"

        db_mark_checked "$final_sum" "checksum_group" "checked"
        db_mark_many_checked "checksum_ref" "checked" "${new_refs[@]}"
        for i in "${!html_companion_new_dirs[@]}"; do
            if [[ "${html_companion_apply[$i]}" == "yes" ]]; then
                db_mark_checked "${html_companion_new_dirs[$i]}" "html_companion" "checked"
            fi
        done

        processed["$sum_file"]=1
        processed["$final_sum"]=1
        for ref in "${refs[@]}"; do processed["$ref"]=1; done
        for ref in "${new_refs[@]}"; do processed["$ref"]=1; done

        continue
    fi

    if [[ -f "$f" ]]; then
        _nx_other=""
        if _nx_other="$(nef_xmp_pair_other_path "$f")"; then
            if nef_xmp_should_defer_sidecar "$f" "$_nx_other"; then
                vlog "Deferring XMP sidecar '$f' until NEF+XMP pair with '$_nx_other'"
                continue
            fi
            if nef_xmp_should_attach_buddy "$f" "$_nx_other"; then
                nef_xmp_buddy="$_nx_other"
                RENAME_SIDECAR_KIND=nef_xmp
            fi
        fi
        if [[ -z "$nef_xmp_buddy" ]]; then
            _sc_other=""
            if _sc_other="$(sony_clip_pair_other_path "$f")"; then
                if sony_clip_should_defer_xml "$f" "$_sc_other"; then
                    vlog "Deferring Sony XML sidecar '$f' until clip pair with '$_sc_other'"
                    continue
                fi
                if sony_clip_should_attach_buddy "$f" "$_sc_other"; then
                    nef_xmp_buddy="$_sc_other"
                    RENAME_SIDECAR_KIND=sony_clip
                fi
            fi
        fi
    fi

    if [[ -f "$f" ]]; then
        base="${f%.*}"
        if [[ -n "$precomputed_new" ]]; then
            new="$precomputed_new"
        else
            _rename_cap_save_e=0
            [[ $- == *e* ]] && _rename_cap_save_e=1
            set +e
            new="$(transform_name "$f")"
            tnf_rc=$?
            new="$(collapse_stacked_other_suffix_in_path "$new")"
            if ((_rename_cap_save_e)); then
                set -e
            else
                set +e
            fi
            if (( tnf_rc == 2 )); then
                break
            fi
            precomputed_new="$new"
        fi
        if [[ "$f" != "$new" && ( -e "$base.sha512" || -e "$base.md5" ) ]]; then
            print_checksum_sibling_notice_verbose "$f" "$base.sha512" "$base.md5"
        fi
    fi

    if [[ -n "$precomputed_new" ]]; then
        new="$precomputed_new"
    else
        _rename_cap_save_e=0
        [[ $- == *e* ]] && _rename_cap_save_e=1
        set +e
        new="$(transform_name "$f")"
        tnf_rc=$?
        new="$(collapse_stacked_other_suffix_in_path "$new")"
        if ((_rename_cap_save_e)); then
            set -e
        else
            set +e
        fi
        if (( tnf_rc == 2 )); then
            break
        fi
    fi

    nef_xmp_new=""
    if [[ -n "$nef_xmp_buddy" ]]; then
        _rename_cap_save_e=0
        [[ $- == *e* ]] && _rename_cap_save_e=1
        set +e
        nef_xmp_new="$(transform_name "$nef_xmp_buddy")"
        tnb=$?
        nef_xmp_new="$(collapse_stacked_other_suffix_in_path "$nef_xmp_new")"
        if ((_rename_cap_save_e)); then
            set -e
        else
            set +e
        fi
        if (( tnb == 2 )); then
            break
        fi
    fi

    if [[ "$f" != "$new" ]] && should_skip_case_only_rename_on_fs "$f" "$new"; then
        verbose_fs_skip_plain=yes
        new="$f"
        precomputed_new="$f"
    fi
    if [[ -n "$nef_xmp_buddy" ]] && [[ "$nef_xmp_buddy" != "$nef_xmp_new" ]] \
        && should_skip_case_only_rename_on_fs "$nef_xmp_buddy" "$nef_xmp_new"; then
        verbose_fs_skip_sidecar=yes
        nef_xmp_new="$nef_xmp_buddy"
    fi

    if [[ -z "$nef_xmp_buddy" ]]; then
        if [[ "$f" != "$new" ]] && paths_refer_to_same_file "$f" "$new"; then
            if ! is_case_only_rename_pair "$f" "$new"; then
                print_same_inode_no_rename_verbose "$f" "$new"
                db_backfill_missing_hashes_for_existing_file "$f"
                ((++files_skipped))
                db_mark_checked "$f" "plain" "checked"
                continue
            fi
        fi

        if [[ "$f" == "$new" ]]; then
            if ! is_torrent_url_file "$f" && ! is_thumbs_db_file "$f"; then
                if [[ "$verbose_fs_skip_plain" == yes ]]; then
                    vlog "No rename needed for '$f' (no case-only rename on exfat/CIFS/Samba)"
                else
                    vlog "No rename needed for '$f'"
                fi
                db_backfill_missing_hashes_for_existing_file "$f"
                ((++files_skipped))
                db_mark_checked "$f" "plain" "checked"
                continue
            fi
            if is_torrent_url_file "$f"; then
                vlog "No rename transform for torrent .URL '$f' (prompt offers delete [T])"
            elif is_thumbs_db_file "$f"; then
                vlog "No rename transform for thumbs.db '$f' (prompt offers delete [K])"
            fi
        fi
    else
        nx_pri_si=no
        nx_bud_si=no
        if [[ "$f" != "$new" ]] && paths_refer_to_same_file "$f" "$new"; then
            if ! is_case_only_rename_pair "$f" "$new"; then
                print_same_inode_no_rename_verbose "$f" "$new"
                nx_pri_si=yes
            fi
        fi
        if [[ "$nef_xmp_buddy" != "$nef_xmp_new" ]] && paths_refer_to_same_file "$nef_xmp_buddy" "$nef_xmp_new"; then
            if ! is_case_only_rename_pair "$nef_xmp_buddy" "$nef_xmp_new"; then
                print_same_inode_no_rename_verbose "$nef_xmp_buddy" "$nef_xmp_new"
                nx_bud_si=yes
            fi
        fi
        if [[ "$nx_pri_si" == yes && "$nx_bud_si" == yes ]]; then
            nef_xmp_pair_run_sidecar_metadata_checks "$new" "$nef_xmp_new" || break
            db_backfill_missing_hashes_for_existing_file "$f"
            db_backfill_missing_hashes_for_existing_file "$nef_xmp_buddy"
            ((files_skipped+=2))
            db_mark_checked "$f" "plain" "checked"
            db_mark_checked "$nef_xmp_buddy" "plain" "checked"
            processed["$nef_xmp_buddy"]=1
            continue
        fi
        if [[ "$f" == "$new" && "$nef_xmp_buddy" == "$nef_xmp_new" ]] && ! is_torrent_url_file "$f" && ! is_thumbs_db_file "$f"; then
            if [[ "$verbose_fs_skip_plain" == yes || "$verbose_fs_skip_sidecar" == yes ]]; then
                vlog_nef_xmp_pair_no_rename_needed " (no case-only rename on exfat/CIFS/Samba)" "$f" "$nef_xmp_buddy"
            else
                vlog_nef_xmp_pair_no_rename_needed "" "$f" "$nef_xmp_buddy"
            fi
            nef_xmp_pair_run_sidecar_metadata_checks "$new" "$nef_xmp_new" || break
            db_backfill_missing_hashes_for_existing_file "$f"
            db_backfill_missing_hashes_for_existing_file "$nef_xmp_buddy"
            ((files_skipped+=2))
            db_mark_checked "$f" "plain" "checked"
            db_mark_checked "$nef_xmp_buddy" "plain" "checked"
            processed["$nef_xmp_buddy"]=1
            continue
        fi
        if [[ "$f" == "$new" ]]; then
            if is_torrent_url_file "$f"; then
                vlog "No rename transform for torrent .URL '$f' (prompt offers delete [T])"
            elif is_thumbs_db_file "$f"; then
                vlog "No rename transform for thumbs.db '$f' (prompt offers delete [K])"
            fi
        fi
    fi

    if [[ "$rename_all" == "yes" ]]; then
        rename_all_do_work=no
        [[ "$f" != "$new" ]] && rename_all_do_work=yes
        [[ -n "$nef_xmp_buddy" && "$nef_xmp_buddy" != "$nef_xmp_new" ]] && rename_all_do_work=yes
        if [[ "$rename_all_do_work" == yes ]]; then
            perform_plain_or_nef_xmp_pair "rename_all" || break
        elif [[ -n "$nef_xmp_buddy" ]] && ! is_torrent_url_file "$f" && ! is_thumbs_db_file "$f"; then
            nef_xmp_pair_run_sidecar_metadata_checks "$new" "$nef_xmp_new" || break
            db_backfill_missing_hashes_for_existing_file "$f"
            db_backfill_missing_hashes_for_existing_file "$nef_xmp_buddy"
            ((files_skipped+=2))
            db_mark_checked "$f" "plain" "checked"
            db_mark_checked "$nef_xmp_buddy" "plain" "checked"
            processed["$nef_xmp_buddy"]=1
        elif ! is_torrent_url_file "$f" && ! is_thumbs_db_file "$f"; then
            ((++files_skipped))
        fi
        if [[ "$f" != "$new" ]] || [[ -n "$nef_xmp_buddy" && "$nef_xmp_buddy" != "$nef_xmp_new" ]] || ( ! is_torrent_url_file "$f" && ! is_thumbs_db_file "$f" ); then
            continue
        fi
    fi

    if auto_yes_current_dir_matches "$f"; then
        auto_yes_do_work=no
        [[ "$f" != "$new" ]] && auto_yes_do_work=yes
        [[ -n "$nef_xmp_buddy" && "$nef_xmp_buddy" != "$nef_xmp_new" ]] && auto_yes_do_work=yes
        if [[ "$auto_yes_do_work" == yes ]]; then
            perform_plain_or_nef_xmp_pair "per-directory auto-yes" || break
        elif [[ -n "$nef_xmp_buddy" ]] && ! is_torrent_url_file "$f" && ! is_thumbs_db_file "$f"; then
            nef_xmp_pair_run_sidecar_metadata_checks "$new" "$nef_xmp_new" || break
            db_backfill_missing_hashes_for_existing_file "$f"
            db_backfill_missing_hashes_for_existing_file "$nef_xmp_buddy"
            ((files_skipped+=2))
            db_mark_checked "$f" "plain" "checked"
            db_mark_checked "$nef_xmp_buddy" "plain" "checked"
            processed["$nef_xmp_buddy"]=1
        elif ! is_torrent_url_file "$f" && ! is_thumbs_db_file "$f"; then
            ((++files_skipped))
        fi
        if [[ "$f" != "$new" ]] || [[ -n "$nef_xmp_buddy" && "$nef_xmp_buddy" != "$nef_xmp_new" ]] || ( ! is_torrent_url_file "$f" && ! is_thumbs_db_file "$f" ); then
            continue
        fi
    fi

    if [[ -z "$nef_xmp_buddy" ]] && gopro_auto_rename_lone_part_strip_matches "$f" "$new"; then
        perform_plain_or_nef_xmp_pair "GoPro lone _part_XX auto-yes" || break
        continue
    fi

    if [[ -n "$AUTO_RENAME_SIMILAR_DIR" ]] && [[ -f "$f" ]] \
        && similar_rename_dir_matches_scope "$(dirname -- "$f")" "$AUTO_RENAME_SIMILAR_DIR" \
        && similar_rename_entry_matches_anchor_pattern "$f"; then
        auto_sim_do_work=no
        [[ "$f" != "$new" ]] && auto_sim_do_work=yes
        [[ -n "$nef_xmp_buddy" && "$nef_xmp_buddy" != "$nef_xmp_new" ]] && auto_sim_do_work=yes
        if [[ "$auto_sim_do_work" == yes ]]; then
            perform_plain_or_nef_xmp_pair "per-directory similar-name auto-yes" || break
        elif [[ -n "$nef_xmp_buddy" ]] && ! is_torrent_url_file "$f" && ! is_thumbs_db_file "$f"; then
            nef_xmp_pair_run_sidecar_metadata_checks "$new" "$nef_xmp_new" || break
            db_backfill_missing_hashes_for_existing_file "$f"
            db_backfill_missing_hashes_for_existing_file "$nef_xmp_buddy"
            ((files_skipped+=2))
            db_mark_checked "$f" "plain" "checked"
            db_mark_checked "$nef_xmp_buddy" "plain" "checked"
            processed["$nef_xmp_buddy"]=1
        elif ! is_torrent_url_file "$f" && ! is_thumbs_db_file "$f"; then
            ((++files_skipped))
        fi
        if [[ "$f" != "$new" ]] || [[ -n "$nef_xmp_buddy" && "$nef_xmp_buddy" != "$nef_xmp_new" ]] || ( ! is_torrent_url_file "$f" && ! is_thumbs_db_file "$f" ); then
            continue
        fi
    fi

    if exception_exists_for_path "$f"; then
        if grep -Fxq -- "$(exact_exception_entry_for_path "$f")" "$EXCLUDE_FILTERS_FILE" 2>/dev/null; then
            emit_wrap_exclude_append_message 0 "EXACT EXCEPTION EXISTS" "$(exact_exception_entry_for_path "$f")"
        elif [[ ( -f "$f" || -d "$f" ) ]] && grep -Fxq -- "$(filename_only_exception_entry_for_path "$f")" "$EXCLUDE_FILTERS_FILE" 2>/dev/null; then
            emit_wrap_exclude_append_message 0 "FILENAME-ONLY EXCEPTION EXISTS" "$(filename_only_exception_entry_for_path "$f")"
        else
            emit_wrap_exclude_append_message 0 "EXCEPTION EXISTS" "$(path_to_exclude_entry "$f")"
        fi
        ((++files_skipped))
        processed["$f"]=1
        db_mark_checked "$f" "plain" "checked"
        continue
    fi

    if [[ "$AUTO_LOWERCASE_3_EXT_SESSION" == "yes" ]] && [[ "$f" != "$new" ]] && rename_suggested_only_extension_case_change "$f" "$new" \
        && ! path_filesystem_skip_case_only_rename "$f"; then
        perform_plain_or_nef_xmp_pair "auto extension case-only lowercase (session)" || break
        continue
    fi
    if [[ "$AUTO_LOWERCASE_MEDIA_OFFICE_EXT_SESSION" == "yes" ]] && [[ "$f" != "$new" ]] && rename_suggested_only_extension_case_change "$f" "$new" \
        && eligible_for_media_office_extension_case_auto "$f" && ! path_filesystem_skip_case_only_rename "$f"; then
        perform_plain_or_nef_xmp_pair "auto extension case-only lowercase (media+office session)" || break
        continue
    fi

    if [[ "$AUTO_DELETE_THUMBS_DB_SESSION" == "yes" ]] && is_thumbs_db_file "$f"; then
        if perform_thumbs_db_delete "$f"; then
            processed["$f"]=1
        else
            ((++files_skipped))
        fi
        continue
    fi

    torrent_url_noop=
    thumbs_db_noop=
    if is_torrent_url_file "$f" && [[ "$f" == "$new" ]]; then
        torrent_url_noop=1
    fi
    if is_thumbs_db_file "$f" && [[ "$f" == "$new" ]]; then
        thumbs_db_noop=1
    fi

    nonverbose_progress_dot_prepare_for_prompt
    echo
    if [[ "$RENAME_SIDECAR_KIND" == sony_clip && -n "$nef_xmp_buddy" ]]; then
        echo -e "${CYAN}Sony clip pair (C####.MP4 + C####M01.XML; both renamed together):${RESET}"
    elif [[ -n "$nef_xmp_buddy" ]]; then
        echo -e "${CYAN}NEF+XMP pair (same stem; both renamed together):${RESET}"
    fi
    _nxmp_pw=$NEF_XMP_PAIR_LABEL_WIDTH_NO_SIDECAR
    [[ -n "$nef_xmp_buddy" ]] && _nxmp_pw=$NEF_XMP_PAIR_LABEL_WIDTH
    emit_wrap_nef_xmp_pair_label_stdout "OLD: " yellow "$f" "$_nxmp_pw"
    emit_wrap_nef_xmp_pair_label_stdout "NEW: " green "$new" "$_nxmp_pw"
    if [[ -d "$f" ]]; then
        echo -e "${CYAN}  (This path is a directory, not a regular file.)${RESET}"
    fi
    if [[ -n "$nef_xmp_buddy" ]]; then
        if [[ "$RENAME_SIDECAR_KIND" == sony_clip ]]; then
            emit_wrap_nef_xmp_pair_label_stdout "OLD (XML): " yellow "$nef_xmp_buddy" "$NEF_XMP_PAIR_LABEL_WIDTH"
            emit_wrap_nef_xmp_pair_label_stdout "NEW (XML): " green "$nef_xmp_new" "$NEF_XMP_PAIR_LABEL_WIDTH"
            echo
            echo -e "${CYAN}Sony NonRealTimeMeta XML is renamed with the clip; CreationDate local wall-clock is used for both names.${RESET}"
        else
            emit_wrap_nef_xmp_pair_label_stdout "OLD (sidecar): " yellow "$nef_xmp_buddy" "$NEF_XMP_PAIR_LABEL_WIDTH"
            emit_wrap_nef_xmp_pair_label_stdout "NEW (sidecar): " green "$nef_xmp_new" "$NEF_XMP_PAIR_LABEL_WIDTH"
            echo
            echo -e "${CYAN}Sidecar XMP metadata (after you confirm):${RESET}"
            if [[ "$mode" == "dry-run" ]]; then
                printf '%s\n' \
                    '[Dry-run] A Yes-style answer only simulates the two renames on disk.' \
                    'The script would then set XMP RawFileName (Lightroom crs:RawFileName or RawFileName) to the new NEF basename when that field exists.' \
                    'It would only describe mismatches. No files are modified in dry-run.'
            else
                printf '%s\n' \
                    'After a Yes-style answer, both paths are renamed on disk.' \
                    'The script then updates the sidecar XMP so RawFileName (Lightroom crs:RawFileName or RawFileName) matches the new NEF basename when that metadata is present.' \
                    "The XMP file's timestamps are preserved when that metadata is written." \
                    'A short follow-up prompt appears only if something still disagrees with the renamed NEF or if the field cannot be edited automatically.'
            fi
        fi
    fi
    if [[ "$f" != "$new" ]] && is_html_file "$f"; then
        print_html_companion_plan_for_prompt "$f" "$new"
    fi
    _rename_menu_variant=""
    [[ -n "$thumbs_db_noop" ]] && _rename_menu_variant=thumbs-noop
    [[ -n "$torrent_url_noop" ]] && _rename_menu_variant=torrent-noop
    while true; do
        print_rename_prompt_menu "entry" "$f" "$new" "$_rename_menu_variant"
        flush_stdin
        read_single_key input "$PROMPT_WAIT_SECONDS"
        echo
        if handle_prompt_directory_listing_choice "$input" "$f" "$new"; then
            continue
        fi
        if [[ "$input" =~ [Cc] ]]; then
            if prompt_custom_exclude_pattern_from_user; then
                input='C'
            else
                continue
            fi
        fi
        break
    done
    # User just answered an interactive prompt; next main-loop iteration must not print a lone "." on stdout/tty.
    NONVERBOSE_SKIP_NEXT_MAIN_LOOP_DOT=yes

    case "$input" in
        q|Q)
            stopped_by_user=yes
            break
            ;;
        n|N)
            if [[ -n "$nef_xmp_buddy" ]]; then
                ((files_skipped+=2))
                processed["$nef_xmp_buddy"]=1
            else
                ((++files_skipped))
                if [[ -n "$thumbs_db_noop" || -n "$torrent_url_noop" ]]; then
                    db_backfill_missing_hashes_for_existing_file "$f" || true
                    db_mark_checked "$f" "plain" "checked"
                    processed["$f"]=1
                fi
            fi
            ;;
        m|M)
            custom_new="$(choose_custom_rename_target "$f" "$new" || true)"
            if [[ -z "$custom_new" ]]; then
                ((++files_skipped))
            elif [[ "$custom_new" == "$f" ]]; then
                vlog "Edited rename target matches current name, skipping '$f'"
                ((++files_skipped))
            else
                if [[ -n "$nef_xmp_buddy" ]]; then
                    print_rename_action_verbose "$f" "$custom_new" "manual edit (NEF+XMP pair)"
                    print_rename_action_verbose "$nef_xmp_buddy" "$nef_xmp_new" "manual edit (NEF+XMP pair; sidecar keeps script suggestion)"
                    perform_plain_entry_rename "$f" "$custom_new" || break
                    perform_plain_entry_rename "$nef_xmp_buddy" "$nef_xmp_new" || break
                    if nef_xmp_pair_set_final_paths_from_primary_and_buddy_new "$custom_new" "$nef_xmp_new"; then
                        nef_xmp_sync_sidecar_raw_file_name_to_nef "$NEF_XMP_FINAL_NEF" "$NEF_XMP_FINAL_XMP" || true
                        nef_xmp_verify_sidecar_raw_file_name_interactive "$NEF_XMP_FINAL_NEF" "$NEF_XMP_FINAL_XMP" || break
                    fi
                    processed["$nef_xmp_buddy"]=1
                else
                    print_rename_action_verbose "$f" "$custom_new" "manual edit"
                    perform_plain_entry_rename "$f" "$custom_new" || break
                fi
            fi
            ;;
        f|F)
            if append_filename_only_exception_to_exclude_filters_file "$f"; then
                ((++files_skipped))
                processed["$f"]=1
            else
                ((++files_skipped))
            fi
            ;;
        b|B)
            if apply_containing_directory_subtree_exception "$f"; then
                ((++files_skipped))
                processed["$f"]=1
                if [[ -n "$nef_xmp_buddy" ]]; then
                    ((++files_skipped))
                    processed["$nef_xmp_buddy"]=1
                fi
            else
                if [[ -n "$nef_xmp_buddy" ]]; then
                    ((files_skipped+=2))
                    processed["$nef_xmp_buddy"]=1
                else
                    ((++files_skipped))
                fi
                processed["$f"]=1
            fi
            ;;
        e|E)
            append_path_to_exclude_filters_file "$f"
            ((++files_skipped))
            processed["$f"]=1
            ;;
        x|X)
            append_exact_path_to_exclude_filters_file "$f"
            ((++files_skipped))
            processed["$f"]=1
            ;;
        c|C)
            ((++files_skipped))
            processed["$f"]=1
            ;;
        a|A)
            echo
            echo "$(user_prompt_ts_prefix)⚠️  This will rename ALL remaining files/directories."
            if (( VERBOSE == 1 )); then
                echo "[VERBOSE] [$(date '+%Y.%m.%d %H:%M:%S')] Are you sure? [y/N]:" >&2
            else
                nonverbose_progress_dot_endline_if_needed
            fi
            echo -n "$(user_prompt_ts_prefix)Are you sure? [y/N]: "
            flush_stdin
            read_single_key confirm "$PROMPT_WAIT_SECONDS"
            echo

            if [[ "$confirm" =~ [Yy] ]]; then
                rename_all=yes
                similar_rename_clear
                AUTO_RENAME_DIR=""
                AUTO_COLLISION_OTHER_DIR=""
                AUTO_COLLISION_OVERWRITE_DIR=""
                vlog "rename_all enabled by user"
                if [[ -z "$torrent_url_noop" && -z "$thumbs_db_noop" ]]; then
                    perform_plain_or_nef_xmp_pair "rename_all" || break
                fi
            else
                if [[ -n "$nef_xmp_buddy" ]]; then
                    ((files_skipped+=2))
                    processed["$nef_xmp_buddy"]=1
                else
                    ((++files_skipped))
                fi
            fi
            ;;
        d|D)
            similar_rename_clear
            if [[ -n "$torrent_url_noop" || -n "$thumbs_db_noop" ]]; then
                AUTO_RENAME_DIR="$(dirname -- "$f")"
                vlog "Per-directory auto-yes enabled for '$AUTO_RENAME_DIR' (no rename for identical special file)"
                ((++files_skipped))
            else
                AUTO_RENAME_DIR="$(dirname -- "$f")"
                vlog "Per-directory auto-yes enabled for '$AUTO_RENAME_DIR'"
                perform_plain_or_nef_xmp_pair "per-directory auto-yes (prompt)" || break
            fi
            ;;
        s|S)
            if [[ ! -f "$f" ]]; then
                echo -e "${YELLOW}[S] applies only to regular files.${RESET}"
                if [[ -n "$nef_xmp_buddy" ]]; then
                    ((files_skipped+=2))
                    processed["$nef_xmp_buddy"]=1
                else
                    ((++files_skipped))
                fi
            else
                AUTO_RENAME_DIR=""
                AUTO_COLLISION_OTHER_DIR=""
                AUTO_COLLISION_OVERWRITE_DIR=""
                similar_rename_set_anchor_from_prompt_path "$f"
                vlog "Per-directory similar-name auto-yes: directory '$AUTO_RENAME_SIMILAR_DIR', all extensions, require leading underscore: ${AUTO_RENAME_SIMILAR_NEED_USCORE}"
                if [[ -n "$torrent_url_noop" || -n "$thumbs_db_noop" ]]; then
                    ((++files_skipped))
                else
                    perform_plain_or_nef_xmp_pair "per-directory similar-name auto-yes (prompt)" || break
                fi
            fi
            ;;
        t|T)
            if ! is_torrent_url_file "$f"; then
                echo -e "${YELLOW}[T] applies only to torrent *.URL shortcuts.${RESET}"
                ((++files_skipped))
            elif [[ "$mode" == "dry-run" ]]; then
                emit_wrap_labeled_stdout "[DRY-RUN] Would delete torrent .URL: " "${CYAN}[DRY-RUN] Would delete torrent .URL:${RESET} " "$f"
                ((++files_affected))
            else
                db_delete_cached_row_for_path "$f"
                rm -f -- "$f"
                emit_wrap_labeled_stdout "Deleted torrent .URL: " "${GREEN}Deleted torrent .URL:${RESET} " "$f"
                ((++files_affected))
            fi
            processed["$f"]=1
            ;;
        k|K)
            if perform_thumbs_db_delete "$f"; then
                processed["$f"]=1
            else
                echo -e "${YELLOW}[K] applies only to thumbs.db files.${RESET}"
                ((++files_skipped))
            fi
            ;;
        o|O)
            if ! is_thumbs_db_file "$f"; then
                echo -e "${YELLOW}[O] applies only to thumbs.db files.${RESET}"
                ((++files_skipped))
            else
                AUTO_DELETE_THUMBS_DB_SESSION=yes
                vlog "Session auto-delete enabled for all thumbs.db files this run"
                if perform_thumbs_db_delete "$f"; then
                    processed["$f"]=1
                fi
            fi
            ;;
        l|L)
            if ! rename_suggested_only_extension_case_change "$f" "$new"; then
                echo -e "${YELLOW}[L] applies only when the suggestion only lowercases the file extension (same stem).${RESET}"
                ((++files_skipped))
            else
                AUTO_LOWERCASE_3_EXT_SESSION=yes
                vlog "Session auto-yes enabled for extension case-only lowercasing renames"
                perform_plain_or_nef_xmp_pair "extension case lowercase + session auto" || break
            fi
            ;;
        u|U)
            if ! rename_suggested_only_extension_case_change "$f" "$new"; then
                echo -e "${YELLOW}[U] applies only when the suggestion only lowercases the file extension (same stem).${RESET}"
                ((++files_skipped))
            elif ! eligible_for_media_office_extension_case_auto "$f"; then
                echo -e "${YELLOW}[U] applies only to media and Microsoft Office files.${RESET}"
                ((++files_skipped))
            else
                AUTO_LOWERCASE_MEDIA_OFFICE_EXT_SESSION=yes
                vlog "Session auto-yes enabled for extension case-only lowercasing on media + Microsoft Office files"
                perform_plain_or_nef_xmp_pair "extension case lowercase + media/office session auto" || break
            fi
            ;;
        *)
            if [[ -n "$torrent_url_noop" ]]; then
                vlog "Skipped torrent .URL (no rename suggested; default or skip): '$f'"
                db_backfill_missing_hashes_for_existing_file "$f" || true
                db_mark_checked "$f" "plain" "checked"
                ((++files_skipped))
                processed["$f"]=1
            elif [[ -n "$thumbs_db_noop" ]]; then
                vlog "Skipped thumbs.db (no rename suggested; default or skip): '$f'"
                db_backfill_missing_hashes_for_existing_file "$f" || true
                db_mark_checked "$f" "plain" "checked"
                ((++files_skipped))
                processed["$f"]=1
            else
                perform_plain_or_nef_xmp_pair "interactive default" || break
            fi
            ;;
    esac
done

if [[ "$stopped_by_user" != "yes" ]]; then
    clear_resume_state_file
    check_all_m3u_files
fi
SCRIPT_FINISH_TIME="$(date '+%Y-%m-%d %H:%M:%S')"
print_summary

