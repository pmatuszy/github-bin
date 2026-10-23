#!/bin/bash
# v. 20261023.071420 - ask output date/time before the merge; apply after (same metadata rewrite when possible)
# v. 20261023.070920 - post-merge exiftool: one rewrite for tags+title; progress from *_exiftool_tmp size
# v. 20261022.212800 - chapter plan shows progress (CreateDate / link checks) so a large folder does not look hung
# v. 20261022.212200 - chapter start time: filename by default; media CreateDate when it disagrees by >2 min (hybrid; size-split too)
# v. 20261022.211235 - within a day, sort _part_XX by start time (not only part number) so two sessions do not interleave
# v. 20261022.210520 - every _part_XX link (also from part_01) must chain by filename time + ffprobe duration; wider stop gap
# v. 20261022.205958 - _part_XX groups include the calendar day so multi-day folders do not interleave part numbers
# v. 20261022.205426 - Ctrl-C during post-merge metadata/GPX still removes the incomplete merge output
# v. 20261021.085230 - after mp4_merge, say metadata/GPX/dates are still running; "Group finished" only at the end
# v. 20261020.163100 - parse exiftool CreateDate with hyphens so GNU date can read media tags
# v. 20261020.162300 - when name and mtime match and CreateDate is missing, default is apply that date (not Keep)
# v. 20261020.150700 - date menu always lists File name, Filesystem, and Media tags (n/a when unusable)
# v. 20261020.145200 - chosen output date is also written as media CreateDate (and related tags)
# v. 20261020.145000 - after merge, ask which date to use when name/FS/media disagree (oldest usable; ignore before 1990)
# v. 20261020.102500 - print every seam time in the output again before asking to delete inputs
# v. 20261020.101700 - refuse mp4_merge when video/audio tracks do not match (ffprobe table)
# v. 20261020.095800 - FILE +N force-merges that file and the next N alphabetically in its folder
# v. 20261020.093200 - seam prompts and the end summary show the join time as H:MM:SS
# v. 20261020.091800 - files named on the command line are merged in that order (forced merge)
# v. 20261014.193952 - the run summary has no clock on each line, and a short clip is marked at its end
# v. 20261014.164220 - the GPS log line names a GPSData file when several logs are in the folder
# v. 20261014.075855 - a short clip keeps only its real length in the GPX, and the merge asks before continuing
# v. 20261013.102747 - every GPSData*.txt is read; the date in the name does not choose the log
# v. 20261013.102039 - a merged file with no clips left can still get a GPX from the GPS log
# v. 20261013.101339 - merged files with no GPX can be given only the GPX
# v. 20261013.095703 - the script is video-pgm-merge-and-make-gpx.sh
# v. 20261013.095124 - a GPS directory can be named, and no GPS log quits before the merge
# v. 20261012.082500 - size-split chapters: next clip must start at prev time + duration (±2s)
# v. 20261012.081800 - 12G chapter: full split ≥ ~9.8 GiB; wall-clock link only for a large remainder
# v. 20261009.181600 - 12G chapter: size decides a full split (Mission 1 ~10 GB can be <<18 min); 8–13 GiB band
# v. 20261009.180500 - size-split chapter link: wall-clock gap when duration end-time mismatch (Mission 1 two-chapter pairs)
# v. 20261009.174500 - 12 GB chapter band min 10000 MiB (Mission 1 ~10–11 GB splits below old 11000 MiB floor)
# v. 20261007.143052 - summary and file lengths are whole seconds
# v. 20261007.084310 - an EV clip with the next sequence number stays in the 70mai journey, front and back
# v. 20261006.230553 - a merged file with no location gets the first point of its .gpx
# v. 20261006.225133 - merged file and its .gpx get the first chapter's creation time and file time
# v. 20261006.124500 - temp directory question on an SSD: the default No is the capital N
# v. 20261006.081500 - 70mai journey name is date_time-date_time_-_-_70mai-A510_camera_concat
# v. 20261005.143200 - the temp line says not used, writing in this directory
# v. 20261005.110900 - GPS logs are GPSData??????.txt here and one or two levels above
# v. 20261005.110800 - GPS logs are GPSData??????.txt here and up to three levels above
# v. 20261005.110200 - merge-all asks once about the temp directory; clocks sit in brackets
# v. 20261005.083400 - 70mai journeys follow filename time, not the sequence number alone
# v. 20261005.082600 - 70mai merged names are matched to the NO* chapters still in the folder
# v. 20261005.081217 - every question starts with the date and time
# v. 20261005.080400 - run summary sizes also show GB, GiB, and MiB
# v. 20261005.074400 - run summary lists processed and deleted files and their sizes
# v. 20261005.073800 - already-merged groups can be skipped for the rest of the run; delete asks twice
# v. 20261005.073000 - temp prompt names the directory of the input files
# v. 20261005.071900 - say when a temp dir is in use for this merge
# v. 20261005.071200 - delete question can keep input files for the rest of the run
# v. 20261004.152334 - Ctrl-C during the move back removes the temp merge file
# v. 20261004.151844 - s turns seam preview off for the rest of the run
# v. 20261004.144348 - ask to build a missing GPX instead of treating the merge as done
# v. 20261004.143910 - GPX build works with mawk (no gawk asort/strftime)
# v. 20261004.143006 - rest-of-run write-here hotkey is r
# v. 20261004.142834 - h writes later merges in this directory
# v. 20261004.142643 - rest-of-run temp dir hotkey is d
# v. 20261004.142415 - temp dir can be kept for the rest of the run
# v. 20261004.142217 - seam preview defaults: 1s before and 1s after each join
# v. 20261004.142009 - q quits on the temp-directory questions
# v. 20261004.141841 - temp-merge prompt says move the file back, not copy
# v. 20261004.141633 - box the merge-group summary before the merge question
# v. 20261004.140923 - free-space check always calls /bin/df
# v. 20261004.140859 - free-space check calls command df, not the shell df function
# v. 20261004.140553 - say why the temp dir was skipped, and ask for another path
# v. 20261004.135736 - --temp-dir, SSD default, space and permission checks, copy-back progress
# v. 20261004.135247 - offer merge via another disk when /tmp has room, then move the file back
# v. 20261004.134138 - merge prompt: group file count, first/last file, start/finish time
# v. 20261004.131846 - before merge prompt, sort files and groups oldest to newest
# v. 20261001.221000 - ffmpeg probe shows the real error, not "version unknown"
# v. 20261001.220200 - startup box: ffmpeg version and GPU encoders in this build
# v. 20260930.221200 - drop --no_startup_delay; this script is interactive
# v. 20260930.221000 - seam preview: [a] skips the rest of the seams in this file
# v. 20260930.214500 - INPUT lines: name, size, and duration on one line when they fit
# v. 20260930.213000 - 70mai merge name: start_end_70mai-A510_camera_concat
# v. 20260930.180600 - 70mai journeys: write a .gpx beside the merged file
# v. 20260916.133341 - print === Run settings === at startup, with Equivalent CLI
# v. 20260811.095711 - add --history (paged changelog via _script_header.sh print_script_history)
# v. 20260805.154826 - after merge: copy GPS/dates from first chapter; FS times via touch -r

# 2026.10.23 - v. 0.15.96 - ask which output date/time to use (name / filesystem / media / keep) before mp4_merge starts, using the planned output name and the first chapter; apply that choice after merge (folded into the metadata exiftool rewrite when a date is chosen) so the long merge does not sit in front of the question
# 2026.10.23 - v. 0.15.95 - post-merge: copy GPS/dates/camera and title in one exiftool rewrite (was two full rewrites of the concat); show a % bar from the growing *_exiftool_tmp vs output size; same progress wrapper for GPS embed and CreateDate writes on large outputs
# 2026.10.22 - v. 0.15.94 - chapter plan progress on one rewriting status line while reading CreateDate and checking chapter links (large folders on /mnt/* used to sit silent after Prompt timeout); batch CreateDate via exiftool; cache ffprobe durations; keep hybrid cache across part + size-split passes
# 2026.10.22 - v. 0.15.93 - hybrid clip start for sort and chain: filename YYYYMMDD_HHMMSS by default; if media CreateDate (exiftool) disagrees by more than PGM_PART_CHAPTER_MEDIA_TIME_DISAGREE_SEC (default 120), use CreateDate; length stays ffprobe duration; results cached per file for the chapter plan
# 2026.10.22 - v. 0.15.92 - within one day+camera key, order _part_XX by filename start time then part number (not part number alone). Two recordings the same day (morning part_01… and evening part_01…) were interleaved and became standalones; size-split session key also includes the day; groups that are all _part_XX are labeled as part chapters, not size-split
# 2026.10.22 - v. 0.15.91 - every consecutive _part_XX link (including runs that start at part_01) must pass filename start + ffprobe duration (±180s), or timelapse / wall-clock gap; default max stop gap for that wall-clock fallback is 1 hour (PGM_PART_CHAPTER_TIME_MAX_GAP_SEC) so a long pause does not always split the day
# 2026.10.22 - v. 0.15.90 - _part_XX group key includes YYYYMMDD: a folder with 20210226 and 20210228 clips used to share one camera bucket, sort by part number only, and pair day-B part_01 with day-A part_02 (so a same-day part_01…24 run looked like “only 2 chapters”)
# 2026.10.22 - v. 0.15.89 - Ctrl-C during post-merge (exiftool metadata, GPX, GPS embed) still deletes the merge output and any *_exiftool_tmp / .meta.tmp beside it; the incomplete-output trap stays until those steps finish, then clears before the interactive date/seam/delete prompts; run-summary bookkeeping runs only when the group finishes
# 2026.10.21 - v. 0.15.88 - after mp4_merge, log that post-merge work is still running (exiftool metadata, GPX, GPS embed, dates); say "Group finished" only when the group is fully done — not while *_exiftool_tmp is growing
# 2026.10.20 - v. 0.15.87 - reading CreateDate used exiftool's YYYY:MM:DD form, which GNU date rejects, so media tags looked missing even when present; parse as YYYY-MM-DD instead
# 2026.10.20 - v. 0.15.86 - when name and mtime already match and only CreateDate is missing, default is to apply that date (media + filesystem), not Keep
# 2026.10.20 - v. 0.15.84 - the output-date menu always lists File name, Filesystem, and Media tags (n/a when missing or before 1990)
# 2026.10.20 - v. 0.15.83 - the date chosen for the output (or the oldest usable under -y) is written into the media CreateDate / ModifyDate tags as well as the filesystem times
# 2026.10.20 - v. 0.15.82 - after a merge, if the file name, filesystem time, and media CreateDate disagree, ask which to use (1/2/3…); default is the oldest usable date; stamps before 1990 are ignored; -y applies the oldest without asking
# 2026.10.20 - v. 0.15.81 - before asking to delete input chapters, print every seam time in the merged file as H:MM:SS (also when deleting inputs for an already-merged group)
# 2026.10.20 - v. 0.15.80 - before mp4_merge, ffprobe checks video/audio fingerprints; mismatched tracks are refused with a short table (forced/+N exits; scan mode skips that group). No automatic re-encode
# 2026.10.20 - v. 0.15.79 - FILE +N force-merges that file and the next N MP4 names in alphabetical order in the same folder (e.g. clip.mp4 +2). The plan lists every filename. Explicit FILE FILE … still works
# 2026.10.20 - v. 0.15.78 - when asking to play a seam, and in a short summary after the seams, show the join time as H:MM:SS so it is easy to seek to in another player
# 2026.10.20 - v. 0.15.77 - name two or more MP4 files on the command line to force a merge in that order (skip chapter detection). The usual merge prompts stay. Output is next to the first file as …_concat_parts_01-NN.mp4
# 2026.10.14 - v. 0.15.76 - the run summary is plain lines, like the other scripts; a short clip's "look around" time is the end of that clip (start plus its length), where the picture jumps
# 2026.10.14 - v. 0.15.75 - the group line names a GPSData file when several logs are in the folder; closing the pipe after the first name is not "no log"
# 2026.10.14 - v. 0.15.74 - a clip shorter than the gap to the next file keeps only that length in the GPX; the merge warns and the run summary lists those clips
# 2026.10.13 - v. 0.15.73 - every GPSData*.txt is read; the date in the name does not choose the log
# 2026.10.13 - v. 0.15.72 - a merged 70mai file whose clips are gone can still get a GPX from GPSData*.txt beside it
# 2026.10.13 - v. 0.15.71 - when merged files have no GPX, one question can create only those GPX files
# 2026.10.13 - v. 0.15.70 - renamed to video-pgm-merge-and-make-gpx.sh
# 2026.10.13 - v. 0.15.69 - GPSData*.txt is also read from --gps-dir, or from [tracks-location] in the geotag conf; that directory and everything inside it are searched; when no log is found the script quits unless you continue
# 2026.10.07 - v. 0.15.68 - summary times are whole seconds (5m 04s), and a file length is whole seconds (409 s), not a fraction
# 2026.10.07 - v. 0.15.67 - an EV clip (event) whose sequence number is the next one stays in the same 70mai journey as the NO clips, on the front camera and on the back camera, even when it starts closer than a minute to the clips around it
# 2026.10.06 - v. 0.15.66 - a merged file with no location gets the first point of its .gpx stored in the video; a file that already has a fix is left as it is
# 2026.10.06 - v. 0.15.65 - the merged file and the .gpx beside it get the first chapter's creation time and file time; on a Windows drive the creation time is copied as well as the file time
# 2026.10.06 - v. 0.15.64 - "Merge via ... for the remaining groups?" on an SSD showed [y/n/q] and [n] No (default); now [y/N/q] and [N], so only the default key is a capital letter
# 2026.10.06 - v. 0.15.63 - 70mai journey name: YYYYMMDD_HHMMSS-YYYYMMDD_HHMMSS_-_-_70mai-A510_FrontCam_concat.mp4 and the same stem .gpx
# 2026.10.05 - v. 0.15.62 - temp line uses plain text: not used, writing in this directory
# 2026.10.05 - v. 0.15.61 - GPS logs are GPSData??????.txt in this directory and one or two levels above
# 2026.10.05 - v. 0.15.60 - GPS logs are GPSData??????.txt in this directory and up to three levels above
# 2026.10.05 - v. 0.15.59 - [m] asks once whether the remaining merges use the temp directory; status lines put the clock in brackets
# 2026.10.05 - v. 0.15.58 - 70mai clips are ordered by filename time so a restarted sequence does not split a journey
# 2026.10.05 - v. 0.15.57 - 70mai concat names are not listed as missing chapters when the NO* files are still there
# 2026.10.05 - v. 0.15.56 - every question starts with the date and time
# 2026.10.05 - v. 0.15.55 - run summary sizes also show decimal GB and binary GiB and MiB
# 2026.10.05 - v. 0.15.54 - run summary: processed groups, deleted files, input and output size
# 2026.10.05 - v. 0.15.53 - already-merged: don't ask again this run; delete confirms with default No
# 2026.10.05 - v. 0.15.52 - temp prompt and merge lines name the directory of the input files
# 2026.10.05 - v. 0.15.51 - the group summary and the merge line say whether a temp dir is in use
# 2026.10.05 - v. 0.15.50 - delete question: [k] never deletes input files for the rest of this run
# 2026.10.04 - v. 0.15.49 - Ctrl-C while moving the merge back deletes the temp file and any partial copy
# 2026.10.04 - v. 0.15.48 - seam preview: [s] never plays seams again in this run
# 2026.10.04 - v. 0.15.47 - already-merged skip only when the 70mai GPX is present; otherwise ask to generate it
# 2026.10.04 - v. 0.15.46 - 70mai GPX: sort and UTC timestamps without gawk (mawk has no asort/strftime)
# 2026.10.04 - v. 0.15.45 - temp-merge prompt: [r] writes in this directory for the rest of this run
# 2026.10.04 - v. 0.15.44 - temp-merge prompt: [h] writes in this directory for the rest of this run
# 2026.10.04 - v. 0.15.43 - temp-merge prompt: [d] keeps that directory for the rest of this run
# 2026.10.04 - v. 0.15.42 - temp-merge prompt: [r] keeps that directory for the rest of this run
# 2026.10.04 - v. 0.15.41 - seam preview defaults: 1s before and 1s after each join
# 2026.10.04 - v. 0.15.40 - [q] on the temp-directory questions quits (does not start the merge)
# 2026.10.04 - v. 0.15.39 - temp-merge prompt: move the finished file back (wording)
# 2026.10.04 - v. 0.15.38 - merge prompt: boxed summary with file count, first/last file, start/finish/length
# 2026.10.04 - v. 0.15.37 - free-space check always calls /bin/df
# 2026.10.04 - v. 0.15.36 - free-space check uses command df so a shell df function cannot hide the byte count
# 2026.10.04 - v. 0.15.35 - when the temp dir cannot be used, say why and ask for another path
# 2026.10.04 - v. 0.15.34 - --temp-dir; default the off-disk merge to yes when the source is not an SSD; copy back with a progress bar
# 2026.10.04 - v. 0.15.33 - when /tmp (or TMPDIR) is another disk with room, offer to merge there and move the file back
# 2026.10.01 - v. 0.15.32 - ffmpeg startup probe keeps the real error instead of "version unknown"
# 2026.10.01 - v. 0.15.31 - startup: print the ffmpeg version and whether this build has a GPU encoder
# 2026.09.30 - v. 0.15.30 - drop --no_startup_delay; this script is interactive
# 2026.09.30 - v. 0.15.29 - seam preview: [a] skips every remaining seam in this merged file
# 2026.09.30 - v. 0.15.28 - merge INPUT: filename, size, and duration on one line when they fit the terminal (else name, then size)
# 2026.09.30 - v. 0.15.27 - 70mai journey output: YYYYMMDD-HHMMSS_YYYYMMDD-HHMMSS_70mai-A510_FrontCam_concat.mp4 and the same stem .gpx
# 2026.09.30 - v. 0.15.26 - 70mai NOYYYYMMDD-HHMMSS-NNNNNNX clips: group a continuous journey (sequence +1 and ~60s start gap) and write a .gpx beside the merged file (same name)
# 2026.09.16 - v. 0.15.25 - startup: print "=== Run settings ===" (like rename.sh) with -u/-y/--read-timeout/--seam-before/--seam-after as given, env, or default, the seam preview size, and an "Equivalent CLI:" line that repeats the run
# 2026.08.05 - v. 0.15.24 - post-merge: copy GPS/CreateDate/Make/Model from first chapter (exiftool); FS mtime via touch -r; title via exiftool not ffmpeg
# 2026.08.05 - v. 0.15.23 - bare _Timelapse (Hero7 rename): parse camera; size-split use timelapse wall gaps; orphan _part_XX joins size-split
# 2026.07.25 - v. 0.15.22 - size summary INPUT lines show full basenames instead of 52-char ellipsis
# 2026.07.18 - v. 0.15.21 - timelapse detect: ignore Rate …sec when clip has audio
# 2026.07.18 - v. 0.15.19 - seam preview: play default Y; repeat default N (continue)
# 2026.07.18 - v. 0.15.17 - seam preview: default Y for play and repeat prompts
# 2026.07.18 - v. 0.15.15 - _part_XX: consecutive parts from part_01 merge without timestamp chain; GoPro Rate 1_5sec timelapse detection
# 2026.07.18 - v. 0.15.14 - _part_XX timelapse: exiftool Rate or _Timelapse_ basename; wall gap vs playback ratio (~5x for 8min→40-45min)
# 2026.07.18 - v. 0.15.13 - _part_XX: after duration chain, accept filename wall-clock gap (timelapse ≠ playback length)
# 2026.07.18 - v. 0.15.12 - _part_XX: group by camera+middle (not full stem); consecutive parts merge when filename times chain (prev+duration≈next)
# 2026.07.15 - v. 0.15.10 - merge outputs: …_concat_parts_01-NN.mp4 (concat before parts)
# 2026.07.15 - v. 0.15.9 - size-split output: …_parts_01-NN_concat.mp4 (chapter count), fix middle/camera join
# 2026.07.15 - v. 0.15.8 - letter chapters (…BLACKa/b/c or …200322a/b): merge without ~4 GB size gate
# 2026.07.15 - v. 0.15.7 - size-split: ~6:49 (409s) chapter duration for all GOPRO* (not only GOPRO7)
# 2026.07.15 - v. 0.15.6 - size-split: accept chapter letter on camera token (GOPRO10_BLACKa)
# 2026.07.15 - v. 0.15.5 - size-split: accept YYYYMMDD_HHMMSSa letter suffixes (rename disambiguation)
# 2026.06.24 - v. 0.15.4 - _part_XX from part_01: merge without ~4 GB check; size rules only for orphan tails (part_02+)
# 2026.06.23 - v. 0.15.3 - fix rest_out circular nameref: pass caller array name into nested helpers
# 2026.06.23 - v. 0.15.2 - parse rename.sh *_parts_NN-NN_concat for orphan listing; clearer orphan output
# 2026.06.23 - v. 0.15.1 - fix _rest nameref loop; multiline skip message for invalid _part_XX groups
# 2026.06.23 - v. 0.15.0 - _part_XX groups: consecutive parts only; require ~4 GB / ~12 GB chapters (same as size-split)
# 2026.06.23 - v. 0.14.2 - seam preview: ask per seam with clearer play message; repeat then next seam
# 2026.06.23 - v. 0.14.1 - seam preview: pass --start/--length as separate args; fix repeat prompt arithmetic
# 2026.06.23 - v. 0.14.0 - post-merge: merge boundary times in output; optional terminal seam preview
# 2026.06.13 - v. 0.13.4 - size-split: recognize ~12 GB chapters (in addition to ~4 GB); same tier per group
# 2026.06.13 - v. 0.13.3 - size-split: group rename.sh-style names (same session label, different per-chapter timestamps)
# 2026.06.02 - v. 0.13.2 - rename NO_STARTUP_DELAY to --no_startup_delay
# 2026.06.01 - v. 0.13.1 - fix: _part_NN chapter grouping mixed proxy with normal parts; group by stem+variant (key-based) so originals and proxies never merge together
# 2026.05.31 - v. 0.13.0 - detect/group raw GoPro chapter files (GXccnnnn[_Proxy].MP4); merge originals & proxies separately
# 2026.05.31 - v. 0.12.3 - -v/--version print a short version banner; also show the banner at startup
# 2026.05.31 - v. 0.12.2 - merge mode: when mp4_merge is missing, show install info then offer to install it (Y/n/q)
# 2026.05.27 - v. 0.12.1 - prompt timeout: wait forever by default; --read-timeout or PGM_READ_TIMEOUT
# 2026.05.27 - v. 0.12.0 - group same-timestamp GoPro clips (_GOPRO*_GX chapter suffix, ~4GB)
# 2026.05.27 - v. 0.11.10 - [q] on delete-inputs prompt quits script (no next merge group)
# 2026.05.27 - v. 0.11.9 - size-split output name: timestamp from first file only (not last)
# 2026.05.27 - v. 0.11.8 - show ffprobe duration per input file in merge group display
# 2026.05.27 - v. 0.11.7 - size-split groups: next chapter time ≈ prev time + prev duration
# 2026.05.27 - v. 0.11.6 - size-split output: copy middle label verbatim from first input name
# 2026.05.27 - v. 0.11.5 - robust S29_-_dermatolog slug in size-split output filenames
# 2026.05.27 - v. 0.11.4 - size-split output: session label (dermatolog) in name + MP4 metadata
# 2026.05.27 - v. 0.11.3 - size-split: flexible GoPro names (_-_ labels, GOPRO7 suffix)
# 2026.05.27 - v. 0.11.2 - GoPro7 size-split: ~4GB and/or ~6:49 (409s) chapter duration
# 2026.05.27 - v. 0.11.1 - size-split: trust ~4GB size; ffprobe only rejects clearly short clips
# 2026.05.27 - v. 0.11.0 - detect size-split GoPro clips (~4GB, ~8:30-9:00) without _part_XX names
# 2026.05.27 - v. 0.10.9 - install mp4_merge to /usr/local/bin; remove PATH/cwd/script copies
# 2026.05.27 - v. 0.10.8 - default mp4_merge install /usr/local/bin; prompt to move from cwd
# 2026.05.27 - v. 0.10.7 - list *_concat outputs with no (or incomplete) input chapters in folder
# 2026.05.27 - v. 0.10.6.1 - fix invalid "local blob action -a" in do_merge (bash nounset)
# 2026.05.27 - v. 0.10.6 - INPUT block then OUTPUT block (stacked, not side by side)
# 2026.05.27 - v. 0.10.5 - one line per chapter; align size columns at '|' (fixed-width bytes/kB/MB)
# 2026.05.27 - v. 0.10.4 - fixed INPUT/OUTPUT columns: basename and size on separate lines
# 2026.05.27 - v. 0.10.3 - merge group detail: INPUT/OUTPUT columns, totals side by side
# 2026.05.27 - v. 0.10.2 - fix json_tmp unbound on RETURN trap under set -o nounset
# 2026.05.27 - v. 0.10.1 - align labelled status lines after timestamp (pgm_log_kv)
# 2026.05.27 - v. 0.10.0 - -u: show installed hash/version, compare GitHub SHA-256, prompt install/replace
# 2026.05.27 - v. 0.9.1 - log prefix: YYYY.MM.DD HH:MM:SS instead of (PGM)
# 2026.05.27 - v. 0.9.0 - print start/finish, processing time, and other/wait time at end
# 2026.05.27 - v. 0.8.9 - already-merged menu: [d] delete input chapters (non-default)
# 2026.05.27 - v. 0.8.8 - output stem timestamp from first chapter file (not last)
# 2026.05.27 - v. 0.8.7 - output name: …_parts_01-04_concat.mp4 from chapter range
# 2026.05.27 - v. 0.8.6 - menu keys: default uppercase, other options lowercase in brackets
# 2026.05.27 - v. 0.8.5 - menu options one per line; default key uppercase in prompt (rename.sh style)
# 2026.05.27 - v. 0.8.4 - already-merged groups: only skip/redo prompt (not Y-merge then N/r)
# 2026.05.27 - v. 0.8.3 - prompt skip (default) or redo when _concat output already exists
# 2026.05.27 - v. 0.8.2 - one line per input file (name + size together)
# 2026.05.27 - v. 0.8.1 - size difference: positive value + which side is larger (input vs output)
# 2026.05.27 - v. 0.8 - single-key prompts, per-file sizes, post-merge summary, optional delete inputs
# 2026.05.27 - v. 0.7 - interactive GoPro chapter groups (part_01→02→…); -y merges all without prompts
# 2026.05.26 - v. 0.6 - on Ctrl-C remove incomplete _concat.mp4 output during merge
# 2026.05.26 - v. 0.5 - source _script_header.sh / _script_footer.sh like other bin scripts
# 2026.05.26 - v. 0.4 - enforce owner-only mode 700 on this script when run on Linux
# 2026.05.26 - v. 0.3 - add -h/--help and -u/--update (install mp4_merge from gyroflow/mp4-merge)
# 2026.05.26 - v. 0.2 - renamed from gopro-mp4-merge.sh
# 2026.05.26 - v. 0.1 - merge GoPro chapter MP4s (Windows merge-gopro batch port)
#
# video-pgm-merge-and-make-gpx.sh
#
# Merge GoPro chapter MP4s in the current directory via mp4_merge (gyroflow/mp4-merge).
#

MP4_MERGE_REPO="${MP4_MERGE_REPO:-gyroflow/mp4-merge}"

show_help() {
  cat <<EOF
Usage: $(script_live_basename) [-h|--help] [-u|--update] [-v|--version] [-y|--yes]
       [--read-timeout SEC] [--seam-before SEC] [--seam-after SEC] [--temp-dir DIR]
       [--gps-dir DIR]
       [FILE FILE ...]
       [FILE +N]
       [-- FILE FILE ...]
       [-- FILE +N]

Merge chapter MP4 files in the current directory (e.g. GoPro splits) into one
file using mp4_merge from https://github.com/gyroflow/mp4-merge

With two or more FILE arguments, those files are merged in the order given
(forced merge). Or pass FILE +N (for example clip.mp4 +2): that file and the
next N MP4 names in alphabetical order in the same folder are merged. Concat
outputs (*_concat*.mp4) are skipped when counting the next names. Chapter
detection is skipped. The plan prints every filename that will be joined.
The usual prompts still ask about the merge, temp directory, seam preview,
and deleting inputs. A Windows path such as P:\\video\\clip.mp4 is read as
/mnt/p/video/clip.mp4. All files must be MP4s in the same directory. The
output is written next to the first file as <first_stem>_concat_parts_01-<N>.mp4.

Options:
  -h, --help           Show this help and exit.
  -u, --update         Check installed mp4_merge (SHA-256 vs GitHub releases), show
                       version if known, then prompt to install or replace (or use -y).
  -v, --version        Print script version and exit.
  --history            Print script changelog from the header and exit.
  -y, --yes            Merge every detected multi-part group without prompts (for cron).
  --read-timeout SEC   Single-key prompt timeout in seconds (0 = wait forever).
                       Default: wait forever. Env: PGM_READ_TIMEOUT (e.g. 300).
  --seam-before SEC    Terminal seam preview: seconds before each join (default 1).
                       Env: PGM_SEAM_PREVIEW_BEFORE.
  --seam-after SEC     Terminal seam preview: seconds after each join (default 1).
                       Env: PGM_SEAM_PREVIEW_AFTER.
  --gps-dir DIR        Also search DIR, and every directory inside it, for GPSData*.txt.
                       Repeat for more than one. A Windows path such as
                       P:\\video\\gps is read as /mnt/p/video/gps. Without this,
                       [tracks-location] in video-pgm-geotag-missing-media.conf
                       is used, from /etc, \$HOME, \$HOME/etc, \$HOME/conf, and
                       profile_location_dir when that is set.
  --temp-dir DIR       Write the temporary merge file in DIR when that directory
                       is on another disk, you can create files there, and it has
                       room for the output plus spare space. Then move the finished
                       file back here with a progress bar.
                       Env: PGM_MERGE_TEMP. If omitted, TMPDIR, then /tmp.

Merge behaviour:
  - With two or more FILE arguments: merge those files in that order (forced).
  - With FILE +N: merge that file and the next N alphabetically in its folder.
  - Before merging, ffprobe compares video/audio tracks to the first file
    (codec, size, fps, pixel format, time base, audio rate/channels). A mismatch
    is refused with a table: forced/+N exits; directory scan skips that group.
    mp4_merge is not run on mixed families (e.g. HandBrake/mp3 with NVenc/aac).
  - With no FILE arguments: collects *.mp4 in the current working directory
    (case-insensitive), except existing *_concat.mp4 outputs.
  - Detects GoPro-style chapter sequences (_part_01, _part_02, …). Same calendar
    day + camera + session label groups together; within that, files are ordered by
    hybrid start time then part number. Start time is the filename stamp by default;
    if media CreateDate disagrees by more than 2 minutes (PGM_PART_CHAPTER_MEDIA_TIME_DISAGREE_SEC),
    CreateDate is used. Consecutive parts must chain: next start ≈ previous start
    + ffprobe duration (±180s), or timelapse / wall-clock gap (default 5 min–1 h).
    Orphan tails (first part > 01) also need full ~4 GB / ~12 GB chapters.
  - Also groups clips without _part_XX names when they look like fixed-size splits:
    same session label, ~4 GB or ~12 GB chapters (~6:49 or longer per chapter); filename times
    that chain, or the same YYYYMMDD_HHMMSS with GX chapter suffixes
    (e.g. …_GOPRO10_BLACK_GX013496.MP4). After rename.sh, consecutive chapters may differ
    only in the leading timestamp and share the same middle label, or share one start time with
    a trailing chapter letter on the time (…_200322a_…) or camera token (…_GOPRO10_BLACKa.MP4).
    Letter runs a,b,c… on the same timestamp merge like part_01 chapters (any file size).
  - Also groups 70mai-style clips NOYYYYMMDD-HHMMSS-NNNNNNX.MP4 and the same
    name starting with EV (same camera letter) into a continuous journey: ordered
    by filename time, sequence number increases by 1, and the filename start times
    are about one minute apart (default gap 50–90s; PGM_DASHCAM_MAX_GAP_SEC).
    An EV clip is an event in that same recording. When its sequence number is the
    next one, it stays in the journey, on the front camera and on the back camera,
    even though it starts closer than a minute to the clips around it.
    The sequence number restarts each day, so it is not used as the sort key.
    A longer gap starts the next journey. The merged file is named from the first
    and last clip times plus the dashcam label (default 70mai-A510) and camera
    letter, for example 20260926_110627-20260926_130427_-_-_70mai-A510_FrontCam_concat.mp4.
    Date and time are joined with _, the start and the end with -, then _-_-_ before the dashcam name.
    An older name 20260926-110627_20260926-130427_70mai-A510_FrontCam_concat.mp4 is still recognized.
    A GPS track with the same stem and a .gpx extension is written beside it,
    from GPSData*.txt in this directory and one or two directories above it.
    Each clip keeps only as many seconds of GPS as the video lasts. A clip that
    is clearly shorter than the gap to the next file is named before the merge,
    the GPX has a gap there, and the run summary lists that stretch to check.
    --gps-dir DIR also searches that directory and everything inside it.
    Without --gps-dir, [tracks-location] in video-pgm-geotag-missing-media.conf
    is used the same way. When no GPSData*.txt is found, the script quits
    unless you choose to merge anyway, and then no GPX is written.
    The merged file and that .gpx get the first chapter's creation time and file time.
    If the merged file has no location, the first point of that .gpx is stored in it.
  - Shows each multi-part group (with file sizes) and asks whether to merge
    (single-key Y/N/A/M/Q, no Enter — like rename.sh). Files in a group, and the
    groups themselves, are ordered oldest to newest (filename YYYYMMDD_HHMMSS when
    present, otherwise filesystem mtime) before that prompt. After the input and
    output lists, a boxed summary shows how many files are in that group, the first
    and last file, and the start time, finish time, and total length.
  - After you choose to merge: if the temp directory (--temp-dir, else
    PGM_MERGE_TEMP, else TMPDIR, else /tmp) is on another disk, you can create
    files there, and it has room for the output plus spare space, asks whether to
    write the merge there and move the finished file back here (progress bar).
    [Y] uses that directory for this file only. [d] keeps it for every later merge
    in this run. [n] writes this file in this directory. [r] writes every later
    merge in this directory. Default is yes (this file only) when the source disk
    is not an SSD, or when that cannot be checked. Default is no when the source
    disk is an SSD. [m] Merge all remaining groups asks this once before the first
    of those merges: yes uses that directory for every group still left and moves
    each finished file back; no writes those outputs in this directory. -y and
    non-interactive runs write in this directory. Status lines start with the
    clock in brackets, [ YYYY.MM.DD HH:MM:SS ].
  - Before each merge: if the planned output name, first-chapter filesystem time, and
    first-chapter media CreateDate disagree by more than two minutes, ask which date to
    use after the merge (1/2/3…); default is the oldest usable stamp (before 1990 ignored).
    -y picks the oldest without asking. After a successful merge: copy GPS / dates /
    Make/Model and title from the first chapter in one exiftool rewrite (progress from
    *_exiftool_tmp on large files), applying the date chosen earlier in that same rewrite
    when needed. Then merge-boundary times, size summary, optional per-seam terminal
    preview (asked one seam at a time; [a] skips the remaining seams in this file, [s]
    never plays seams again in this run), then every seam time in the output as H:MM:SS
    again, and optional deletion of the source chapter files (single-key Y/N/K/Q). [k]
    keeps input files for every later group in this run.
  - If the expected _concat output already exists: skip (default), redo merge [r],
    preview merge seams [p], or delete input chapters [d] (keeps merged output).
    A 70mai journey is finished only when a valid .gpx sits beside that file.
    If the GPX is missing and a GPSData*.txt log is available, the prompt asks
    to generate it. When more than one merged file has no GPX, one question
    offers to create only those GPX files. [G] is the default. [e] asks about
    each file. [n] skips them. [q] quits. The merged videos are not replaced.
    A merged file is included when its clips are no longer in the folder, as
    long as a GPSData*.txt log is in the places searched.
  - Output file per group: <first_chapter_stem>_concat_parts_<first>-<last>.mp4
    (timestamp from the first part; size-split/letter groups use 01-<N> for chapter count,
    e.g. …_GOPRO10_BLACK_concat_parts_01-06.mp4). Legacy …_parts_*-*_concat.mp4 still recognized.
  - Other single files are listed as standalone; probable size-split sets are merge candidates.
  - Lists merged *_concat files when matching input chapters are not in the folder.
    A 70mai journey name is matched to NO* and EV* clips of that camera whose
    filename times fall from the journey start through the journey end.

mp4_merge lookup (merge mode):
  1. MP4_MERGE_BIN if set and executable
  2. /usr/local/bin (or MP4_MERGE_INSTALL_DIR): mp4_merge-linux64, …, mp4_merge
  3. ./mp4_merge-linux64, … in the current directory (interactive: install to /usr/local/bin,
     remove other copies on PATH and in the script directory)
  4. Same names in the script directory

Environment:
  MP4_MERGE_BIN           Path to mp4_merge binary (overrides search paths).
  MP4_MERGE_INSTALL_DIR   Target directory for -u/--update (default: /usr/local/bin).
  MP4_MERGE_REPO          GitHub repo for releases (default: gyroflow/mp4-merge).
  PGM_READ_TIMEOUT        Seconds per single-key prompt; unset or 0 = wait forever.
                          Overridden by --read-timeout.
  PGM_SEAM_PREVIEW_BEFORE Seconds before each merge point in terminal preview (default: 1).
  PGM_SEAM_PREVIEW_AFTER  Seconds after each merge point in terminal preview (default: 1).
  PGM_SEAM_PREVIEW_WIDTH  Terminal tct width for seam preview (default: 100; empty = autodetect).
  PGM_SEAM_PREVIEW_HEIGHT Terminal tct height for seam preview (default: 40; empty = autodetect).
  RENAME_EXIFTOOL / EXIFLOC / PGM_EXIFTOOL
                          exiftool for GoPro timelapse detection on _part_XX chains (same
                          default path as rename.sh when unset).
  PGM_PART_TIMELAPSE_GAP_RATIO_MIN / _MAX
                          Timelapse wall-clock gap ÷ playback duration (default 4.5–6.5;
                          ~8 min playback → ~40–45 min between chapter filename times).
  PGM_GOPRO_TIMELAPSE_FPS   Assumed output fps for Rate-interval ratio (default: 30).
  PGM_PART_TIMELAPSE_GAP_RATIO_TOLERANCE
                          Slack around interval×fps expected ratio (default: 0.35).
  PGM_PART_CHAPTER_TIME_MIN_GAP_SEC / PGM_PART_CHAPTER_TIME_MAX_GAP_SEC
                          When prev start + duration does not match next start, allow
                          a plain wall-clock gap between chapter start times
                          (default 300–3600s). PGM_PART_CHAPTER_12G_TIME_MAX_GAP_SEC
                          for ~12 GB chapters (default: same 3600, or size-split 12G max).
  PGM_PART_CHAPTER_MEDIA_TIME_DISAGREE_SEC
                          If media CreateDate and the filename start disagree by more
                          than this many seconds, sort/chain use CreateDate (default: 120).
  PGM_PART_CHAPTER_TIME_TOLERANCE_SEC
                          For _part_XX chains: slack when matching next start to
                          prev start + ffprobe duration (default: 180).
  PGM_SIZE_SPLIT_TIME_TOLERANCE_SEC
                          For size-split (no _part_XX) chains: same check (default: 2).
  PGM_DASHCAM_MAX_GAP_SEC Max seconds between 70mai clip start times to stay in one
                          journey (default: 90). Gaps above this start a new group.
  PGM_DASHCAM_SHORT_HOLE_SEC
                          A clip is short when the next filename starts this many
                          seconds after the video ends (default: 8). The last clip
                          of a journey is not treated as short.
  PGM_DASHCAM_GPX_SEG_GAP_SEC
                          GPS points this far apart become a new GPX segment
                          (default: 8), so a hole in the video is a gap on the map.
  PGM_DASHCAM_LABEL       Make and model in 70mai journey filenames (default: 70mai-A510).
                          Spaces become hyphens.
  PGM_MERGE_TEMP          Temp directory for an off-disk merge (same as --temp-dir).
                          If unset: TMPDIR, then /tmp. Used only when it is another
                          disk, writable by you, and large enough for the output.
  TMPDIR                  Fallback temp directory when --temp-dir and PGM_MERGE_TEMP
                          are unset.
  MAX_LINE_LENGTH         Longest status line kept on one row (default: 200). The
                          real limit is the smaller of this and the terminal width.
  PGM_EXIFTOOL_PROGRESS_MIN_BYTES
                          Minimum output size before post-merge exiftool shows a
                          *_exiftool_tmp progress bar (default: 52428800 = 50 MiB).

Examples:
  $(script_live_basename) -u
      Download mp4_merge into /usr/local/bin (recommended system location).

  cd /path/to/chapters && $(script_live_basename)
      Merge all chapter MP4s in that folder.

  $(script_live_basename) -- a.mp4 b.mp4
      Force-merge a.mp4 then b.mp4 in that order (skip chapter detection).

  $(script_live_basename) -- a.mp4 +2
      Force-merge a.mp4 and the next 2 MP4 names alphabetically in that folder.

  $(script_live_basename) --temp-dir /mnt/scratch
      Offer /mnt/scratch as the temporary merge disk when it has room.

  $(script_live_basename) --gps-dir /mnt/p/video/gps
      Also read GPSData*.txt from that directory and everything inside it.

  $(script_live_basename) -y
      Merge all chapter groups without prompts.

Upstream: https://github.com/gyroflow/mp4-merge
EOF
}

script_version() {
  local ver=unknown date=
  while IFS= read -r line; do
    if [[ "$line" =~ ^#\ ([0-9]{4}\.[0-9]{2}\.[0-9]{2})\ -\ v\.\ ([0-9]+(\.[0-9]+)*) ]]; then
      date="${BASH_REMATCH[1]}"
      ver="${BASH_REMATCH[2]}"
      break
    fi
  done < "$0"
  if [[ -n "$date" ]]; then
    printf '%s version %s (%s)\n' "$(script_live_basename)" "$ver" "$date"
  else
    printf '%s version %s\n' "$(script_live_basename)" "$ver"
  fi
}

# Print gyroflow/mp4-merge asset basename for this host (stdout) or return 1.
detect_mp4_merge_asset() {
  local os arch
  os=$(uname -s)
  arch=$(uname -m)
  case "$os" in
    Linux)
      case "$arch" in
        x86_64|amd64)     printf '%s\n' mp4_merge-linux64 ;;
        aarch64|arm64)    printf '%s\n' mp4_merge-linux-arm64 ;;
        i686|i386)        printf '%s\n' mp4_merge-linux32 ;;
        *) return 1 ;;
      esac
      ;;
    Darwin)
      case "$arch" in
        arm64)            printf '%s\n' mp4_merge-mac-arm64 ;;
        x86_64)           printf '%s\n' mp4_merge-mac64 ;;
        *) return 1 ;;
      esac
      ;;
    *)
      return 1
      ;;
  esac
}

mp4_merge_github_curl() {
  local url="$1"
  pgm_processing_begin
  /usr/bin/curl -fsSL --max-time 120 "${url}" 2>/dev/null
  pgm_processing_end
}

fetch_mp4_merge_latest_release_json() {
  mp4_merge_github_curl "https://api.github.com/repos/${MP4_MERGE_REPO}/releases/latest"
}

fetch_mp4_merge_all_releases_json() {
  mp4_merge_github_curl "https://api.github.com/repos/${MP4_MERGE_REPO}/releases?per_page=100"
}

release_tag_from_json() {
  printf '%s\n' "$1" | grep -m1 '"tag_name"' | sed 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/'
}

# Requires python3. Args: releases_json_file asset_name -> stdout digest hex (no sha256: prefix).
release_asset_digest_from_json() {
  local json_file="$1" asset="$2"
  python3 - "$asset" "$json_file" <<'PY'
import json, sys
asset, path = sys.argv[1], sys.argv[2]
with open(path, encoding="utf-8") as f:
    data = json.load(f)
for a in data.get("assets") or []:
    if a.get("name") == asset:
        d = (a.get("digest") or "").strip()
        if d.startswith("sha256:"):
            d = d[7:]
        print(d.lower())
        break
PY
}

# Requires python3. Args: releases_json_file asset_name sha256_hex -> stdout tag_name or nothing.
find_release_tag_for_asset_digest() {
  local json_file="$1" asset="$2" digest="$3"
  python3 - "$asset" "$digest" "$json_file" <<'PY'
import json, sys
asset, want, path = sys.argv[1], sys.argv[2].lower(), sys.argv[3]
with open(path, encoding="utf-8") as f:
    releases = json.load(f)
if isinstance(releases, dict):
    releases = [releases]
for rel in releases:
    tag = rel.get("tag_name") or ""
    for a in rel.get("assets") or []:
        if a.get("name") != asset:
            continue
        d = (a.get("digest") or "").strip().lower()
        if d.startswith("sha256:"):
            d = d[7:]
        if d == want:
            print(tag)
            raise SystemExit(0)
PY
}

file_sha256_hex() {
  local f="$1"
  sha256sum -- "$f" 2>/dev/null | awk '{print tolower($1)}'
}

resolve_mp4_merge_install_path() {
  local asset="$1"
  local dest="${MP4_MERGE_INSTALL_DIR}/${asset}"
  if [[ -f "$dest" ]]; then
    printf '%s\n' "$dest"
    return 0
  fi
    return 1
}

install_mp4_merge_asset() {
  local asset="$1" tag="$2"
  local dest tmp url
  mkdir -p "${MP4_MERGE_INSTALL_DIR}"
  dest="${MP4_MERGE_INSTALL_DIR}/${asset}"
  tmp="${dest}.tmp.$$"
  url="https://github.com/${MP4_MERGE_REPO}/releases/download/${tag}/${asset}"

  pgm_log_kv "Installing" "${asset} (${tag}) ..."
  pgm_log_kv "From" "${url}"
  pgm_log_kv "To" "${dest}"
  echo

  pgm_processing_begin
  if ! /usr/bin/curl -fsSL --max-time 600 -o "${tmp}" "${url}"; then
    pgm_processing_end
    rm -f "${tmp}"
    echo "$(pgm_ts) Download failed." >&2
    return 1
  fi
  pgm_processing_end
  chmod 755 "${tmp}"
  mv -f "${tmp}" "${dest}"

  if [[ "${asset}" != mp4_merge ]]; then
    ln -sf "${asset}" "${MP4_MERGE_INSTALL_DIR}/mp4_merge"
  fi

  local new_hash
  new_hash=$(file_sha256_hex "$dest")
  pgm_log_kv "Installed path" "${dest}"
  pgm_log_kv "SHA-256" "${new_hash}  (${tag})"
  if [[ -x "${dest}" ]]; then
    echo "$(pgm_ts) $(file -b "${dest}" 2>/dev/null || echo 'binary ready')"
  fi
  mp4_merge_collect_extras "$(mp4_merge_abs_path "$dest" 2>/dev/null || printf '%s' "$dest")"
  mp4_merge_remove_extras "$(mp4_merge_abs_path "$dest" 2>/dev/null || printf '%s' "$dest")"
  return 0
}

MP4_MERGE_ASSET_NAMES=(
  mp4_merge-linux64
  mp4_merge-linux-arm64
  mp4_merge-linux32
  mp4_merge-linux
  mp4_merge
)
MP4_MERGE_EXTRA_PATHS=()

mp4_merge_abs_path() {
  local p="$1"
  [[ -e "$p" || -L "$p" ]] || return 1
  if readlink -f -- "$p" &>/dev/null; then
    readlink -f -- "$p"
    return 0
  fi
  if command -v realpath >/dev/null 2>&1 && realpath -- "$p" &>/dev/null; then
    realpath -- "$p"
    return 0
  fi
  local dir base
  base=$(basename -- "$p")
  dir=$(cd "$(dirname -- "$p")" 2>/dev/null && pwd -P) || return 1
  printf '%s/%s\n' "$dir" "$base"
}

mp4_merge_dir_is_system_install() {
  local dir="$1" abs
  [[ -n "$dir" ]] || return 1
  if abs=$(mp4_merge_abs_path "${dir%/}/." 2>/dev/null); then
    dir="$abs"
  else
    dir="${dir%/}"
  fi
  [[ "$dir" == "${MP4_MERGE_INSTALL_DIR}" || "$dir" == "${MP4_MERGE_SYSTEM_DIR}" ]]
}

mp4_merge_path_in_system_dir() {
  local path="$1" dir abs
  abs=$(mp4_merge_abs_path "$path") || return 1
  dir=$(dirname -- "$abs")
  mp4_merge_dir_is_system_install "$dir"
}

mp4_merge_extra_already_listed() {
  local candidate="$1" existing
  for existing in "${MP4_MERGE_EXTRA_PATHS[@]}"; do
    [[ "$existing" == "$candidate" ]] && return 0
  done
  return 1
}

mp4_merge_extra_add() {
  local f="$1" skip_abs="${2:-}"
  local abs
  [[ -e "$f" || -L "$f" ]] || return 0
  abs=$(mp4_merge_abs_path "$f") || return 0
  mp4_merge_path_in_system_dir "$abs" && return 0
  [[ -n "$skip_abs" && "$abs" == "$skip_abs" ]] && return 0
  mp4_merge_extra_already_listed "$abs" && return 0
  MP4_MERGE_EXTRA_PATHS+=("$abs")
}

# Collect mp4_merge binaries outside MP4_MERGE_INSTALL_DIR (PATH, cwd, script dir).
mp4_merge_collect_extras() {
  local skip_abs="${1:-}"
  local dir name p path_dirs
  MP4_MERGE_EXTRA_PATHS=()
  if [[ -n "${PATH:-}" ]]; then
    IFS=':' read -r -a path_dirs <<< "$PATH"
    for dir in "${path_dirs[@]}"; do
      [[ -n "$dir" ]] || continue
      [[ -d "$dir" ]] || continue
      mp4_merge_dir_is_system_install "$dir" && continue
      for name in "${MP4_MERGE_ASSET_NAMES[@]}"; do
        mp4_merge_extra_add "${dir}/${name}" "$skip_abs"
      done
    done
  fi
  if [[ -n "${SCRIPT_DIR:-}" ]] && ! mp4_merge_dir_is_system_install "${SCRIPT_DIR}"; then
    for name in "${MP4_MERGE_ASSET_NAMES[@]}"; do
      mp4_merge_extra_add "${SCRIPT_DIR}/${name}" "$skip_abs"
    done
  fi
  for name in "${MP4_MERGE_ASSET_NAMES[@]}"; do
    mp4_merge_extra_add "./${name}" "$skip_abs"
  done
}

mp4_merge_print_extra_locations() {
  local p
  (( ${#MP4_MERGE_EXTRA_PATHS[@]} > 0 )) || return 0
  echo "  Other copies (will be removed when installed to ${MP4_MERGE_INSTALL_DIR}):"
  for p in "${MP4_MERGE_EXTRA_PATHS[@]}"; do
    printf '    %s\n' "$p"
  done
}

mp4_merge_remove_extras() {
  local keep_abs="${1:-}"
  local p dir d removed=0
  local -a rm_dirs=()
  for p in "${MP4_MERGE_EXTRA_PATHS[@]}"; do
    [[ -n "$keep_abs" && "$p" == "$keep_abs" ]] && continue
    [[ -e "$p" || -L "$p" ]] || continue
    dir=$(dirname -- "$p")
    if rm -f -- "$p"; then
      pgm_log_kv "Removed" "$p"
      (( removed++ )) || true
      rm_dirs+=("$dir")
    else
      echo "$(pgm_ts) Could not remove: ${p}" >&2
    fi
  done
  for dir in "${rm_dirs[@]}"; do
    mp4_merge_dir_is_system_install "$dir" && continue
    for name in "${MP4_MERGE_ASSET_NAMES[@]}"; do
      [[ -e "${dir}/${name}" || -L "${dir}/${name}" ]] && continue 2
    done
    if [[ -e "${dir}/mp4_merge" || -L "${dir}/mp4_merge" ]]; then
      if rm -f -- "${dir}/mp4_merge"; then
        pgm_log_kv "Removed" "${dir}/mp4_merge"
        (( removed++ )) || true
      fi
    fi
  done
  (( removed > 0 )) || true
}

mp4_merge_install_dir_writable() {
  local dir="${1:-${MP4_MERGE_INSTALL_DIR}}"
  [[ -n "$dir" ]] || return 1
  if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir" 2>/dev/null || return 1
  fi
  [[ -w "$dir" ]]
}

# Move or copy a local mp4_merge binary into MP4_MERGE_INSTALL_DIR (and symlink mp4_merge).
mp4_merge_install_local_binary() {
  local src="$1"
  local base dest dir
  base=$(basename "$src")
  dest="${MP4_MERGE_INSTALL_DIR}/${base}"
  dir="${MP4_MERGE_INSTALL_DIR}"
  if ! mp4_merge_install_dir_writable "$dir"; then
    echo "$(pgm_ts) Cannot write to ${dir} (try: sudo $(script_live_basename) -u)." >&2
    return 1
  fi
  if ! mv -f -- "$src" "$dest" 2>/dev/null; then
    if ! cp -f -- "$src" "$dest"; then
      echo "$(pgm_ts) Failed to install ${base} into ${dir}." >&2
      return 1
    fi
    rm -f -- "$src"
  fi
  chmod 755 "$dest"
  if [[ "$base" != mp4_merge ]]; then
    ln -sf "$base" "${dir}/mp4_merge"
  fi
  pgm_log_kv "Installed path" "${dest}"
  printf '%s\n' "$dest"
  return 0
}

mp4_merge_print_not_found_help() {
  echo "$(pgm_ts) mp4_merge not found." >&2
  echo "$(pgm_ts) Install to ${MP4_MERGE_INSTALL_DIR} (recommended):" >&2
  echo "$(pgm_ts)   $(script_live_basename) -u" >&2
  if ! mp4_merge_install_dir_writable "${MP4_MERGE_INSTALL_DIR}" 2>/dev/null; then
    echo "$(pgm_ts)   (directory not writable — use sudo for -u)" >&2
  fi
  echo "$(pgm_ts) Or set MP4_MERGE_BIN=/path/to/mp4_merge" >&2
}

# When mp4_merge is missing, ask whether to download/install it now (reuses update_mp4_merge).
# Returns 0 if the user agreed and the install ran, 1 if declined / quit.
prompt_install_mp4_merge_now() {
  local rc prev_yes

  if (( ! DO_YES )) && (( script_is_run_interactively )); then
    echo
    echo "  [Y] Yes — download and install mp4_merge to ${MP4_MERGE_INSTALL_DIR} (default)"
    echo "  [n] No — do not install"
    echo "  [q] Quit"
    pgm_read_key "Install mp4_merge now? [Y/n/q]: " y
    case "${REPLY,,}" in
      ''|y) ;;
      n) echo "$(pgm_ts) Not installing mp4_merge."; return 1 ;;
      q) echo "$(pgm_ts) Quit."; return 1 ;;
      *) echo "$(pgm_ts) Not installing mp4_merge."; return 1 ;;
    esac
  fi

  # Auto-confirm the update prompt for the missing case (we already asked above).
  prev_yes=$DO_YES
  DO_YES=1
  update_mp4_merge
  rc=$?
  DO_YES=$prev_yes
  return $rc
}

# If merger is outside /usr/local/bin, offer install there and remove PATH/script/cwd copies.
resolve_merger_path_for_merge() {
  local merger="$1"
  local base choice dest dest_abs
  if mp4_merge_path_in_system_dir "$merger"; then
    printf '%s\n' "$merger"
    return 0
  fi
  if (( DO_YES )) || (( ! script_is_run_interactively )); then
    printf '%s\n' "$merger"
    return 0
  fi
  if [[ "$merger" == ./* ]]; then
    base="${merger#./}"
    pgm_log_kv "mp4_merge in current directory" "$(pwd)/${base}"
  else
    pgm_log_kv "mp4_merge found outside" "${MP4_MERGE_INSTALL_DIR}" "$merger"
  fi
  echo "  Recommended location: ${MP4_MERGE_INSTALL_DIR}/"
  mp4_merge_collect_extras ""
  mp4_merge_print_extra_locations
  if ! mp4_merge_install_dir_writable "${MP4_MERGE_INSTALL_DIR}"; then
    echo "  (${MP4_MERGE_INSTALL_DIR} is not writable — use sudo $(script_live_basename) -u)"
  fi
  while true; do
    echo "  [Y] Install to ${MP4_MERGE_INSTALL_DIR} and remove other copies (default)"
    echo "  [n] Keep using: ${merger}"
    echo "  [q] Quit"
    pgm_read_key "Install mp4_merge to ${MP4_MERGE_INSTALL_DIR}? [Y/n/q]: " y
    choice="${REPLY,,}"
    case "$choice" in
      ''|y)
        dest=$(mp4_merge_install_local_binary "$merger") || return 1
        dest_abs=$(mp4_merge_abs_path "$dest" 2>/dev/null || printf '%s' "$dest")
        mp4_merge_collect_extras "$dest_abs"
        mp4_merge_remove_extras "$dest_abs"
        echo "$(pgm_ts) mp4_merge is now at ${dest}"
        printf '%s\n' "$dest"
        return 0
        ;;
      n)
        printf '%s\n' "$merger"
        return 0
        ;;
      q)
        echo "$(pgm_ts) Quit."
        return 2
        ;;
      *)
        echo "$(pgm_ts) Unknown choice: ${REPLY}"
        ;;
    esac
  done
}

# Sets REPLY to: install | keep | quit
prompt_mp4_merge_update_action() {
  local state="$1"
  REPLY=keep
  if (( DO_YES )); then
    case "$state" in
      missing|outdated|unknown) REPLY=install ;;
      latest) REPLY=keep ;;
    esac
    return 0
  fi
  if (( ! script_is_run_interactively )); then
    case "$state" in
      missing|outdated|unknown) REPLY=install ;;
      latest)
        echo "$(pgm_ts) Already on latest release; skipping download (use -y only for merge mode)."
        REPLY=keep
        ;;
    esac
    return 0
  fi
  local choice
  while true; do
    case "$state" in
      missing)
        echo "  [Y] Download and install to ${MP4_MERGE_INSTALL_DIR} (default)"
        echo "  [n] Cancel"
        echo "  [q] Quit"
        pgm_read_key "mp4_merge not installed — [Y/n/q]: " y
        ;;
      latest)
        echo "  [N] Keep current install (default)"
        echo "  [y] Re-download and replace anyway"
        echo "  [q] Quit"
        pgm_read_key "Already on latest release — [N/y/q]: " n
        ;;
      outdated)
        echo "  [Y] Replace with latest release (default)"
        echo "  [n] Keep current install"
        echo "  [q] Quit"
        pgm_read_key "Update available — [Y/n/q]: " y
        ;;
      unknown)
        echo "  [Y] Replace with latest release from GitHub (default)"
        echo "  [n] Keep current file"
        echo "  [q] Quit"
        pgm_read_key "Installed hash unknown on GitHub — [Y/n/q]: " y
        ;;
    esac
    choice="${REPLY,,}"
    case "$state:$choice" in
      missing:''|missing:y) REPLY=install; return 0 ;;
      missing:n)           REPLY=keep; echo "$(pgm_ts) Install cancelled."; return 0 ;;
      latest:''|latest:n)  REPLY=keep; return 0 ;;
      latest:y)            REPLY=install; return 0 ;;
      outdated:''|outdated:y) REPLY=install; return 0 ;;
      outdated:n)          REPLY=keep; echo "$(pgm_ts) Keeping current install."; return 0 ;;
      unknown:''|unknown:y) REPLY=install; return 0 ;;
      unknown:n)           REPLY=keep; echo "$(pgm_ts) Keeping current file."; return 0 ;;
      *:q)                 REPLY=quit; return 0 ;;
      *)                   echo "$(pgm_ts) Unknown choice: ${REPLY}" ;;
    esac
  done
}

update_mp4_merge() {
  local asset tag dest install_path local_hash local_tag latest_json releases_json
  local latest_tag latest_digest json_tmp releases_tmp state

  check_if_installed curl
  if ! command -v python3 >/dev/null 2>&1; then
    echo "$(pgm_ts) python3 is required for release hash lookup (install python3)." >&2
    return 1
  fi
  if ! command -v sha256sum >/dev/null 2>&1; then
    echo "$(pgm_ts) sha256sum is required to verify mp4_merge binaries." >&2
    return 1
  fi

  if ! asset=$(detect_mp4_merge_asset); then
    echo "$(pgm_ts) Unsupported OS/arch for mp4_merge: $(uname -s) $(uname -m)" >&2
    return 1
  fi

  json_tmp=$(mktemp)
  releases_tmp=$(mktemp)
  # Embed paths when trap is set: on RETURN, locals are gone under nounset.
  trap "rm -f -- $(printf '%q' "$json_tmp") $(printf '%q' "$releases_tmp")" RETURN

  latest_json=$(fetch_mp4_merge_latest_release_json) || {
    echo "$(pgm_ts) Failed to fetch latest release from GitHub." >&2
    return 1
  }
  printf '%s' "$latest_json" >"${json_tmp}"
  latest_tag=$(release_tag_from_json "$latest_json")
  latest_digest=$(release_asset_digest_from_json "${json_tmp}" "${asset}")
  if [[ -z "$latest_tag" || -z "$latest_digest" ]]; then
    echo "$(pgm_ts) Could not read latest release metadata for ${asset}." >&2
    return 1
  fi

  releases_json=$(fetch_mp4_merge_all_releases_json) || {
    echo "$(pgm_ts) Failed to fetch release list from GitHub." >&2
    return 1
  }
  printf '%s' "$releases_json" >"${releases_tmp}"

  pgm_log_kv "Machine asset" "${asset}"
  pgm_log_kv "Install directory" "${MP4_MERGE_INSTALL_DIR}  (recommended: ${MP4_MERGE_SYSTEM_DIR})"
  if ! mp4_merge_install_dir_writable "${MP4_MERGE_INSTALL_DIR}"; then
    echo "$(pgm_ts) Install directory is not writable — run with sudo or set MP4_MERGE_INSTALL_DIR." >&2
  fi
  pgm_log_kv "Latest on GitHub" "${latest_tag}"
  pgm_log_kv "Latest SHA-256" "${latest_digest}"
  echo

  if install_path=$(resolve_mp4_merge_install_path "$asset"); then
    local_hash=$(file_sha256_hex "$install_path")
    local_tag=$(find_release_tag_for_asset_digest "${releases_tmp}" "${asset}" "${local_hash}" 2>/dev/null || true)
    pgm_log_kv "Installed file" "${install_path}"
    pgm_log_kv "Installed SHA-256" "${local_hash}"
    if [[ -n "$local_tag" ]]; then
      pgm_log_kv "Installed version" "${local_tag}  (matched GitHub release by hash)"
    else
      pgm_log_kv "Installed version" "unknown  (hash not found in GitHub releases)"
    fi
    pgm_log_kv "Installed size" "$(format_bytes_human "$(file_size_bytes "$install_path")")"
    echo
    if [[ "$local_hash" == "$latest_digest" ]]; then
      state=latest
    elif [[ -n "$local_tag" ]]; then
      state=outdated
    else
      state=unknown
    fi
  else
    pgm_log_kv "Installed file" "not found"
    echo
    state=missing
  fi

  prompt_mp4_merge_update_action "$state"
  case "$REPLY" in
    install)
      install_mp4_merge_asset "$asset" "$latest_tag"
      return $?
      ;;
    keep)
      pgm_log_kv "Action" "Keeping current install."
      return 0
      ;;
    quit)
      echo "$(pgm_ts) Quit."
      return 0
      ;;
  esac
}

find_merger_in_dir() {
  local dir="$1" name
  [[ -n "$dir" ]] || return 1
  for name in "${MP4_MERGE_ASSET_NAMES[@]}"; do
    if [[ -x "${dir}/${name}" ]]; then
      printf '%s\n' "${dir}/${name}"
      return 0
    fi
  done
  return 1
}

find_merger() {
  local name
  if [[ -n "${MP4_MERGE_BIN:-}" && -x "${MP4_MERGE_BIN}" ]]; then
    printf '%s\n' "${MP4_MERGE_BIN}"
    return 0
  fi
  find_merger_in_dir "${MP4_MERGE_INSTALL_DIR}" && return 0
  if [[ "${MP4_MERGE_SYSTEM_DIR}" != "${MP4_MERGE_INSTALL_DIR}" ]]; then
    find_merger_in_dir "${MP4_MERGE_SYSTEM_DIR}" && return 0
  fi
  for name in "${MP4_MERGE_ASSET_NAMES[@]}"; do
    if [[ -x "./${name}" ]]; then
      printf '%s\n' "./${name}"
      return 0
    fi
  done
  find_merger_in_dir "${SCRIPT_DIR}" && return 0
  return 1
}

# Set by do_merge; used by trap on Ctrl-C to drop a partial output file.
VIDEO_MERGE_OUT_FILE=""
# Temp directory holding an in-progress off-disk merge (empty when writing in place).
MERGE_TMP_DIR=""
# Set when the user keeps one temp directory for every later merge in this run.
MERGE_TEMP_FOR_RUN=""
# 1 when later merges in this run write in the current directory.
MERGE_IN_PLACE_FOR_RUN=0
# 1 when seam preview stays off for the rest of this run.
SEAM_PREVIEW_SKIP_RUN=0
# 1 when input chapter files stay for the rest of this run.
KEEP_INPUTS_FOR_RUN=0
# 1 when groups that are already merged are not asked about again this run.
SKIP_MERGED_PROMPTS=0
# Hybrid start-time cache: path → epoch; path → name|media (which source won).
declare -A PGM_HYBRID_START_EPOCH=()
declare -A PGM_HYBRID_START_SRC=()
PGM_HYBRID_START_MEDIA_N=0
# CreateDate / ffprobe caches for the chapter-plan pass (path → value; empty = known miss).
declare -A PGM_MEDIA_CREATEDATE_EPOCH=()
declare -A PGM_FFPROBE_DUR_CACHE=()
# 1 while a \r progress line is active on stdout (tty).
PGM_PROGRESS_ACTIVE=0
PGM_READ_TIMEOUT_CLI=0
PGM_SCRIPT_START_NS=""
PGM_PROCESSING_SEC=0
PGM_PROCESSING_SLICE_START=""

pgm_ts() {
  date '+[ %Y.%m.%d %H:%M:%S ]'
}

# Timestamp + fixed-width label + value (labels align in status blocks).
pgm_log_kv() {
  local label="$1"
  shift
  pgm_progress_end
  printf '%s %-*s  %s\n' "$(pgm_ts)" 26 "${label}:" "$*"
}

# Finish a rewriting progress line (newline) if one is open.
pgm_progress_end() {
  if (( PGM_PROGRESS_ACTIVE )); then
    PGM_PROGRESS_ACTIVE=0
    printf '\n'
  fi
}

# One-line progress that rewrites on a tty: "phase  i/n  basename".
# Non-tty: a new line about every 8 steps (or on the last).
pgm_progress_update() {
  local phase="$1" i="$2" n="$3" name="${4:-}"
  local width line msg room base
  [[ "$i" =~ ^[0-9]+$ && "$n" =~ ^[0-9]+$ ]] || return 0
  (( n > 0 )) || return 0
  base="${name##*/}"
  if [[ -t 1 ]]; then
    width="$(pgm_effective_line_width)"
    printf -v msg '%s %s  %s/%s' "$(pgm_ts)" "$phase" "$i" "$n"
    if [[ -n "$base" ]]; then
      room=$(( width - ${#msg} - 2 ))
      if (( room < 12 )); then
        room=12
      fi
      if (( ${#base} > room )); then
        base="…${base: -$(( room - 1 ))}"
      fi
      msg+="  ${base}"
    fi
    if (( ${#msg} > width )); then
      msg="${msg:0:width}"
    fi
    printf '\r%s\033[K' "$msg"
    PGM_PROGRESS_ACTIVE=1
    if (( i >= n )); then
      pgm_progress_end
    fi
  else
    if (( i == 1 || i == n || i % 8 == 0 )); then
      if [[ -n "$base" ]]; then
        printf '%s %s  %s/%s  %s\n' "$(pgm_ts)" "$phase" "$i" "$n" "$base"
      else
        printf '%s %s  %s/%s\n' "$(pgm_ts)" "$phase" "$i" "$n"
      fi
    fi
  fi
}

# Fixed-width label + value for the run summary. No clock on these lines.
pgm_summary_kv() {
  local label="$1"
  shift
  printf '  %-*s  %s\n' 18 "${label}:" "$*"
}

# Command line that reproduces this run (flags given plus resolved seam-preview values).
pgm_print_run_settings_equivalent_cli() {
  local cmd="" out="" p q_dir
  local -a parts=()

  if declare -F script_live_basename >/dev/null 2>&1; then
    cmd="$(script_live_basename)"
  elif [[ -n "${SCRIPT_SELF_LIVE_PATH:-}" ]]; then
    cmd="$(basename -- "${SCRIPT_SELF_LIVE_PATH}")"
  else
    cmd="$(basename -- "${BASH_SOURCE[0]:-$0}")"
  fi
  [[ -n "$cmd" ]] || cmd="video-pgm-merge-and-make-gpx.sh"

  (( DO_UPDATE )) && parts+=("--update")
  (( DO_YES )) && parts+=("--yes")
  pgm_read_timeout_is_limited && parts+=("--read-timeout" "$PGM_READ_TIMEOUT")
  parts+=("--seam-before" "$PGM_SEAM_PREVIEW_BEFORE")
  parts+=("--seam-after" "$PGM_SEAM_PREVIEW_AFTER")
  if [[ -n "${PGM_MERGE_TEMP:-}" ]]; then
    parts+=("--temp-dir" "$PGM_MERGE_TEMP")
  fi
  for p in "${GPS_DIRS[@]}"; do
    parts+=("--gps-dir" "$p")
  done
  if (( FORCE_MERGE )) && (( ${#FORCE_MERGE_FILES[@]} > 0 )); then
    parts+=("--")
    if (( FORCE_MERGE_PLUS_N > 0 )); then
      parts+=("${FORCE_MERGE_FILES[0]}" "+${FORCE_MERGE_PLUS_N}")
    else
      for p in "${FORCE_MERGE_FILES[@]}"; do
        parts+=("$p")
      done
    fi
  fi

  out="$(printf '%q' "$cmd")"
  for p in "${parts[@]}"; do
    out+=" $(printf '%q' "$p")"
  done

  q_dir="$(printf '%q' "$PWD")"
  printf '  %-21s%s\n' "Equivalent CLI:" "cd $q_dir && $out"
}

# Always-on startup summary (same idea as rename.sh / par2-pgm-check.sh).
pgm_print_run_settings() {
  echo
  echo "=== Run settings ==="

  if (( DO_UPDATE )); then
    echo "  -u/--update:         given (install or update mp4_merge, then exit)"
  else
    echo "  -u/--update:         not given"
  fi

  if (( DO_YES )); then
    echo "  -y/--yes:            given (accept defaults; merge without per-group prompts)"
  else
    echo "  -y/--yes:            not given (prompt per mergeable group)"
  fi

  if (( FORCE_MERGE )); then
    if (( FORCE_MERGE_PLUS_N > 0 )); then
      printf '  %-21s%s\n' "Files:" \
        "given (${FORCE_MERGE_FILES[0]##*/} +${FORCE_MERGE_PLUS_N} → ${#FORCE_MERGE_FILES[@]} files, alphabetical next)"
    else
      printf '  %-21s%s\n' "Files:" "given (${#FORCE_MERGE_FILES[@]} — forced merge in this order)"
    fi
  else
    printf '  %-21s%s\n' "Files:" "not given (scan *.mp4 in this directory)"
  fi

  if (( PGM_READ_TIMEOUT_CLI )); then
    if pgm_read_timeout_is_limited; then
      printf '  %-21s%s\n' "--read-timeout:" "given (${PGM_READ_TIMEOUT}s per key, then default choice)"
    else
      printf '  %-21s%s\n' "--read-timeout:" "given (${PGM_READ_TIMEOUT} — wait for keypress)"
    fi
  elif pgm_read_timeout_is_limited; then
    printf '  %-21s%s\n' "--read-timeout:" "not given (env PGM_READ_TIMEOUT=${PGM_READ_TIMEOUT}s)"
  else
    printf '  %-21s%s\n' "--read-timeout:" "not given (wait for keypress)"
  fi

  if (( PGM_SEAM_BEFORE_CLI )); then
    printf '  %-21s%s\n' "--seam-before:" "given (${PGM_SEAM_PREVIEW_BEFORE}s before each seam)"
  elif (( PGM_SEAM_BEFORE_FROM_ENV )); then
    printf '  %-21s%s\n' "--seam-before:" "${PGM_SEAM_PREVIEW_BEFORE}s (env PGM_SEAM_PREVIEW_BEFORE)"
  else
    printf '  %-21s%s\n' "--seam-before:" "${PGM_SEAM_PREVIEW_BEFORE}s (default)"
  fi

  if (( PGM_SEAM_AFTER_CLI )); then
    printf '  %-21s%s\n' "--seam-after:" "given (${PGM_SEAM_PREVIEW_AFTER}s after each seam)"
  elif (( PGM_SEAM_AFTER_FROM_ENV )); then
    printf '  %-21s%s\n' "--seam-after:" "${PGM_SEAM_PREVIEW_AFTER}s (env PGM_SEAM_PREVIEW_AFTER)"
  else
    printf '  %-21s%s\n' "--seam-after:" "${PGM_SEAM_PREVIEW_AFTER}s (default)"
  fi

  if (( PGM_MERGE_TEMP_CLI )); then
    printf '  %-21s%s\n' "--temp-dir:" "given (${PGM_MERGE_TEMP})"
  elif (( PGM_MERGE_TEMP_FROM_ENV )); then
    printf '  %-21s%s\n' "--temp-dir:" "${PGM_MERGE_TEMP} (env PGM_MERGE_TEMP)"
  elif [[ -n "${TMPDIR:-}" ]]; then
    printf '  %-21s%s\n' "--temp-dir:" "${TMPDIR} (env TMPDIR)"
  else
    printf '  %-21s%s\n' "--temp-dir:" "/tmp (default)"
  fi

  printf '  %-21s%sx%s (env PGM_SEAM_PREVIEW_WIDTH/HEIGHT)\n' \
    "Seam preview size:" "${PGM_SEAM_PREVIEW_WIDTH:-auto}" "${PGM_SEAM_PREVIEW_HEIGHT:-auto}"
  printf '  %-21s%s\n' "Work dir:" "$PWD"
  pgm_print_run_settings_equivalent_cli
  pgm_print_ffmpeg_box
  echo
}

# Draw lines in an ada box when boxes is installed, otherwise a plain frame.
pgm_print_box_lines() {
  local -a lines=("$@")
  local line width=0 bar
  if (( ${#lines[@]} == 0 )); then
    return 0
  fi
  if type -fP boxes >/dev/null 2>&1; then
    printf '%s\n' "${lines[@]}" | boxes -a c -d ada-box
    return 0
  fi
  for line in "${lines[@]}"; do
    (( ${#line} > width )) && width=${#line}
  done
  bar="$(printf '%*s' "$((width + 2))" '' | tr ' ' '-')"
  echo "+${bar}+"
  for line in "${lines[@]}"; do
    printf '| %-*s |\n' "$width" "$line"
  done
  echo "+${bar}+"
}

# Encoders this ffmpeg binary can run on a GPU. Empty means the build has none.
pgm_ffmpeg_capture() {
  ffmpeg "$@" 2>&1 || true
}

pgm_ffmpeg_gpu_encoder_line() {
  local list name out=""
  local -a want=(
    hevc_nvenc h264_nvenc
    hevc_vaapi h264_vaapi
    hevc_qsv h264_qsv
    hevc_amf h264_amf
  )
  list="$(pgm_ffmpeg_capture -hide_banner -encoders)"
  for name in "${want[@]}"; do
    grep -Eq "(^|[[:space:]])${name}([[:space:]]|$)" <<<"$list" || continue
    if [[ -n "$out" ]]; then
      out+=", ${name}"
    else
      out="$name"
    fi
  done
  if [[ -n "$out" ]]; then
    printf 'GPU encoders: %s\n' "$out"
  else
    printf '%s\n' "GPU encoders: none"
  fi
}

pgm_print_ffmpeg_box() {
  local ver out bin
  local -a lines=()
  echo
  if ! command -v ffmpeg >/dev/null 2>&1; then
    lines=("ffmpeg: not found")
  else
    bin="$(command -v ffmpeg)"
    out="$(pgm_ffmpeg_capture -version)"
    ver="$(printf '%s\n' "$out" | awk '/^ffmpeg version / { print; exit }')"
    if [[ -z "$ver" ]]; then
      ver="$(printf '%s\n' "$out" | awk 'NF { print; exit }')"
      if [[ -n "$ver" ]]; then
        ver="ffmpeg (${bin}): ${ver}"
      else
        ver="ffmpeg version unknown (${bin})"
      fi
    fi
    lines=("$ver" "$(pgm_ffmpeg_gpu_encoder_line)")
  fi
  pgm_print_box_lines "${lines[@]}"
}

pgm_time_now_ns() {
  date +%s.%N 2>/dev/null || date +%s
}

pgm_record_script_start() {
  PGM_SCRIPT_START_NS=$(pgm_time_now_ns)
  PGM_PROCESSING_SEC=0
  PGM_RUN_GROUPS=0
  PGM_RUN_INPUT_FILES=0
  PGM_RUN_INPUT_BYTES=0
  PGM_RUN_OUTPUT_BYTES=0
  PGM_RUN_DELETED=0
  PGM_SHORT_CLIP_NOTES=()
}

pgm_processing_begin() {
  PGM_PROCESSING_SLICE_START=$(pgm_time_now_ns)
}

pgm_processing_end() {
  local t_end
  t_end=$(pgm_time_now_ns)
  PGM_PROCESSING_SEC=$(awk -v acc="${PGM_PROCESSING_SEC:-0}" -v t0="${PGM_PROCESSING_SLICE_START}" -v t1="${t_end}" \
    'BEGIN { printf "%.6f", acc + (t1 - t0) }')
}

pgm_format_wall_clock() {
  local ns="$1"
  date -d "@${ns%.*}" '+%Y.%m.%d %H:%M:%S' 2>/dev/null \
    || date -r "${ns%.*}" '+%Y.%m.%d %H:%M:%S' 2>/dev/null \
    || printf '%s\n' "${ns%.*}"
}

format_duration_sec() {
  local sec="$1"
  awk -v s="${sec}" 'BEGIN {
    if (s < 0) s = 0
    t = int(s + 0.5)
    if (t < 1) { printf "0s"; exit }
    h = int(t / 3600)
    m = int((t % 3600) / 60)
    x = t % 60
    if (h > 0) printf "%dh %02dm %02ds", h, m, x
    else if (m > 0) printf "%dm %02ds", m, x
    else printf "%ds", x
  }'
}

print_pgm_timing_summary() {
  local end_ns total_sec wait_sec
  [[ -n "${PGM_SCRIPT_START_NS}" ]] || return 0
  end_ns=$(pgm_time_now_ns)
  total_sec=$(awk -v s0="${PGM_SCRIPT_START_NS}" -v s1="${end_ns}" 'BEGIN { printf "%.6f", s1 - s0 }')
  wait_sec=$(awk -v t="${total_sec}" -v p="${PGM_PROCESSING_SEC:-0}" \
    'BEGIN { w = t - p; if (w < 0) w = 0; printf "%.6f", w }')
  echo
  echo "--- Run summary ---"
  pgm_summary_kv "Processed" "${PGM_RUN_GROUPS:-0} group(s), ${PGM_RUN_INPUT_FILES:-0} input file(s)"
  pgm_summary_kv "Deleted" "${PGM_RUN_DELETED:-0} input file(s)"
  pgm_summary_kv "Input size" "$(format_bytes_run_summary "${PGM_RUN_INPUT_BYTES:-0}")"
  pgm_summary_kv "Output size" "$(format_bytes_run_summary "${PGM_RUN_OUTPUT_BYTES:-0}")"
  echo
  dashcam_print_short_clip_run_summary
  echo "--- Timing ---"
  pgm_summary_kv "Started" "$(pgm_format_wall_clock "${PGM_SCRIPT_START_NS}")"
  pgm_summary_kv "Finished" "$(date '+%Y.%m.%d %H:%M:%S')"
  pgm_summary_kv "Total wall time" "$(format_duration_sec "${total_sec}")"
  pgm_summary_kv "Processing time" "$(format_duration_sec "${PGM_PROCESSING_SEC:-0}")  (merges, downloads)"
  pgm_summary_kv "Other/wait time" "$(format_duration_sec "${wait_sec}")  (prompts, startup delay, overhead)"
  echo
}

# One finished merge: chapter files that went into it, and the merged file written.
pgm_note_processed_group() {
  local output="$1"
  shift
  local f sz
  PGM_RUN_GROUPS=$(( ${PGM_RUN_GROUPS:-0} + 1 ))
  PGM_RUN_INPUT_FILES=$(( ${PGM_RUN_INPUT_FILES:-0} + $# ))
  for f in "$@"; do
    sz=$(file_size_bytes "$f")
    PGM_RUN_INPUT_BYTES=$(( ${PGM_RUN_INPUT_BYTES:-0} + sz ))
  done
  if [[ -f "$output" ]]; then
    sz=$(file_size_bytes "$output")
    PGM_RUN_OUTPUT_BYTES=$(( ${PGM_RUN_OUTPUT_BYTES:-0} + sz ))
  fi
}

flush_stdin() {
  local discard drained=0 max_drain=256
  while (( drained < max_drain )) && IFS= read -r -t 0.02 -n 1 discard; do
    ((++drained))
  done
}

# Apply PGM_READ_TIMEOUT from env (unless --read-timeout set); 0 or unset = wait forever.
pgm_init_read_timeout() {
  if (( PGM_READ_TIMEOUT_CLI )); then
    return 0
  fi
  PGM_READ_TIMEOUT="${PGM_READ_TIMEOUT:--1}"
}

pgm_read_timeout_is_limited() {
  [[ "$PGM_READ_TIMEOUT" =~ ^[0-9]+$ ]] && (( PGM_READ_TIMEOUT > 0 ))
}

# Read one key (no Enter). Sets REPLY; uses default when empty and default is set.
pgm_read_key() {
  local prompt="$1" default="${2:-}" timeout="${3:-$PGM_READ_TIMEOUT}"
  local answer=
  if (( ! script_is_run_interactively )); then
    REPLY="$default"
    return 0
  fi
  printf '%s %s' "$(pgm_ts)" "$prompt"
  flush_stdin
  if pgm_read_timeout_is_limited && [[ "$timeout" =~ ^[0-9]+$ ]] && (( timeout > 0 )); then
    read -t "$timeout" -n 1 answer || answer=
  else
    read -n 1 answer || answer=
  fi
  echo
  if [[ -z "$answer" ]]; then
    REPLY="$default"
  else
    REPLY="$answer"
  fi
}

file_size_bytes() {
  local f="$1"
  if [[ ! -f "$f" ]]; then
    printf '0\n'
    return 0
  fi
  stat -c %s -- "$f" 2>/dev/null || stat -f %z -- "$f" 2>/dev/null || printf '0\n'
}

# bytes | kB | MB on one line (kB/MB = 1024-based).
format_bytes_human() {
  local bytes="$1"
  awk -v b="$bytes" 'BEGIN {
    printf "%d bytes | %.2f kB | %.2f MB", b, b/1024.0, b/1048576.0
  }'
}

# Run summary: the usual line, plus decimal GB and binary GiB and MiB.
format_bytes_run_summary() {
  local bytes="$1"
  awk -v b="$bytes" 'BEGIN {
    printf "%d bytes | %.2f kB | %.2f MB | %.2f GB | %.2f GiB | %.2f MiB", \
      b, b/1024.0, b/1048576.0, b/1e9, b/1073741824.0, b/1048576.0
  }'
}

# Same as format_bytes_human but fixed field widths so '|' columns line up in the terminal.
format_bytes_human_aligned() {
  local bytes="$1"
  awk -v b="$bytes" 'BEGIN {
    printf "%12d bytes | %10.2f kB | %8.2f MB", b, b/1024.0, b/1048576.0
  }'
}

# Seconds from ffprobe as "409 s (6:49)" for display.
format_duration_display() {
  local dur="$1"
  [[ -n "$dur" ]] || return 1
  awk -v d="$dur" 'BEGIN {
    t = int(d + 0.5)
    if (t < 0) t = 0
    m = int(t / 60)
    s = t % 60
    printf "%d s (%d:%02d)", t, m, s
  }'
}

# Seconds as "5090 s (1h 24min 50s)" for the merge-prompt summary.
format_duration_hms_display() {
  local dur="$1" hms
  [[ -n "$dur" ]] || return 1
  hms=$(format_output_timeline_pos "$dur") || return 1
  awk -v d="$dur" -v hms="$hms" 'BEGIN {
    t = int(d + 0.5)
    if (t < 0) t = 0
    printf "%d s (%s)", t, hms
  }'
}

# Position in merged output as "8min 15s" / "1h 2min 3s".
format_output_timeline_pos() {
  local sec="$1"
  awk -v s="$sec" 'BEGIN {
    if (s < 0) s = 0
    h = int(s / 3600)
    m = int((s - h * 3600) / 60)
    x = int(s + 0.5) % 60
    if (h > 0) printf "%dh %dmin %ds", h, m, x
    else if (m > 0) printf "%dmin %ds", m, x
    else printf "%ds", int(s+0.5)
  }'
}

# Same position as H:MM:SS for seeking in a player (e.g. 0:55:17 or 1:02:03).
format_output_timeline_clock() {
  local sec="$1"
  awk -v s="$sec" 'BEGIN {
    if (s < 0) s = 0
    t = int(s + 0.5)
    h = int(t / 3600)
    m = int((t % 3600) / 60)
    x = t % 60
    printf "%d:%02d:%02d", h, m, x
  }'
}

pgm_valid_seam_seconds() {
  [[ "${1:-}" =~ ^[0-9]+([.][0-9]+)?$ ]]
}

pgm_invalid_seam_seconds() {
  echo "$(pgm_ts) invalid $1: ${2:-<empty>} (use 0 or a non-negative number)" >&2
  exit 1
}

# Fill namerefs: boundary_times[], boundary_left[], boundary_right[] (one entry per join).
merge_compute_boundaries() {
  local -n _out_times=$1
  local -n _out_left=$2
  local -n _out_right=$3
  shift 3
  local -a files=("$@")
  local f dur cumulative=0 i

  _out_times=()
  _out_left=()
  _out_right=()
  (( ${#files[@]} >= 2 )) || return 1

  for (( i = 0; i < ${#files[@]} - 1; i++ )); do
    dur=$(ffprobe_duration_seconds "${files[$i]}") || return 1
    cumulative=$(awk -v c="$cumulative" -v d="$dur" 'BEGIN { printf "%.6f", c + d }')
    _out_times+=( "$cumulative" )
    _out_left+=( "${files[$i]##*/}" )
    _out_right+=( "${files[$i + 1]##*/}" )
  done
  return 0
}

# Preview window around boundary T: [max(0,T-before), T+after].
merge_seam_preview_start_length() {
  local boundary="$1"
  local before="$2"
  local after="$3"
  awk -v t="$boundary" -v b="$before" -v a="$after" 'BEGIN {
    s = t - b; if (s < 0) s = 0
    e = t + a
    printf "%.3f %.3f\n", s, e - s
  }'
}

# Sum of before+after window (e.g. 2 + 0 → 2).
merge_seam_clip_total_seconds() {
  local before="$1" after="$2"
  awk -v b="$before" -v a="$after" 'BEGIN {
    t = b + a
    if (t == int(t)) print int(t)
    else printf "%g", t
  }'
}

pgm_ordinal_seam_label() {
  local n="$1" d u
  case "$n" in
    1) printf '1st' ;;
    2) printf '2nd' ;;
    3) printf '3rd' ;;
    *)
      d=$(( n % 10 ))
      u=$(( (n / 10) % 10 ))
      if (( u == 1 )); then printf '%dth' "$n"
      elif (( d == 1 )); then printf '%dst' "$n"
      elif (( d == 2 )); then printf '%dnd' "$n"
      elif (( d == 3 )); then printf '%drd' "$n"
      else printf '%dth' "$n"
      fi
      ;;
  esac
}

print_merge_boundaries_report() {
  local output_file="$1"
  shift
  local -a files=("$@")
  local -a boundary_times=() boundary_left=() boundary_right=()
  local i boundary pos clock start length preview_from preview_to

  if ! merge_compute_boundaries boundary_times boundary_left boundary_right "${files[@]}"; then
    echo "=== Merge boundaries ==="
    echo "  $(pgm_ts) Could not compute boundaries (ffprobe duration missing for one or more inputs)."
    echo
    return 1
  fi

  echo "=== Merge boundaries in output (${output_file##*/}) ==="
  for (( i = 0; i < ${#boundary_times[@]}; i++ )); do
    boundary="${boundary_times[$i]}"
    pos="$(format_output_timeline_pos "$boundary")"
    clock="$(format_output_timeline_clock "$boundary")"
    read -r start length < <(merge_seam_preview_start_length "$boundary" \
      "$PGM_SEAM_PREVIEW_BEFORE" "$PGM_SEAM_PREVIEW_AFTER")
    preview_from="$(format_output_timeline_clock "$start")"
    preview_to="$(format_output_timeline_clock "$(awk -v s="$start" -v l="$length" 'BEGIN { printf "%.6f", s + l }')")"
    printf '  %s | %s  at  %s  (%s)  (preview %s – %s)\n' \
      "${boundary_left[$i]}" "${boundary_right[$i]}" "$clock" "$pos" "$preview_from" "$preview_to"
  done
  echo
  return 0
}

find_video_pgm_play_terminal() {
  local candidate
  if [[ -n "${VIDEO_PGM_PLAY_TERMINAL_BIN:-}" && -x "${VIDEO_PGM_PLAY_TERMINAL_BIN}" ]]; then
    printf '%s\n' "${VIDEO_PGM_PLAY_TERMINAL_BIN}"
    return 0
  fi
  if candidate=$(command -v video-pgm-play-terminal.sh 2>/dev/null); then
    printf '%s\n' "$candidate"
    return 0
  fi
  for candidate in \
    "${SCRIPT_DIR:-}/video-pgm-play-terminal.sh" \
    "/root/bin/video-pgm-play-terminal.sh"; do
    [[ -n "$candidate" && -x "$candidate" ]] || continue
    printf '%s\n' "$candidate"
    return 0
  done
  return 1
}

play_merge_seam_preview_once() {
  local player="$1" output_file="$2" boundary="$3" left="$4" right="$5"
  local seam_num="$6" total_seams="$7" ord="$8"
  local start length pos clock clip_total preview_w preview_h
  local -a player_args=()

  read -r start length < <(merge_seam_preview_start_length "$boundary" \
    "$PGM_SEAM_PREVIEW_BEFORE" "$PGM_SEAM_PREVIEW_AFTER")
  pos="$(format_output_timeline_pos "$boundary")"
  clock="$(format_output_timeline_clock "$boundary")"
  clip_total="$(merge_seam_clip_total_seconds "$PGM_SEAM_PREVIEW_BEFORE" "$PGM_SEAM_PREVIEW_AFTER")"
  [[ -n "$ord" ]] || ord="$(pgm_ordinal_seam_label "$seam_num")"
  preview_w="${PGM_SEAM_PREVIEW_WIDTH-100}"
  preview_h="${PGM_SEAM_PREVIEW_HEIGHT-40}"
  player_args=( --no-countdown )
  if [[ -n "$preview_w" && -n "$preview_h" ]]; then
    player_args+=( --no-autodetect -w "$preview_w" -H "$preview_h" )
  fi
  player_args+=( --start "$start" --length "$length" )

  echo
  echo "Playing output file at ${ord} seam (${seam_num} of ${total_seams}): ${output_file##*/}"
  echo "  Join: ${left} | ${right}  at  ${clock}  (${pos})"
  echo "  Starts ${PGM_SEAM_PREVIEW_BEFORE}s before the seam; clip length ${clip_total}s (${PGM_SEAM_PREVIEW_BEFORE}s before + ${PGM_SEAM_PREVIEW_AFTER}s after)."
  if [[ -n "$preview_w" && -n "$preview_h" ]]; then
    echo "  Preview size: ${preview_w} x ${preview_h} terminal cells."
  fi
  "${player}" "${player_args[@]}" "$output_file"
}

# List every join time as H:MM:SS (for seeking in another player).
print_merge_seam_times_summary() {
  local output_file="$1"
  shift
  local -a files=("$@")
  local -a boundary_times=() boundary_left=() boundary_right=()
  local i seam_num ord clock pos

  if ! merge_compute_boundaries boundary_times boundary_left boundary_right "${files[@]}"; then
    return 1
  fi
  (( ${#boundary_times[@]} > 0 )) || return 0

  echo "=== Seam times in output (${output_file##*/}) ==="
  for (( i = 0; i < ${#boundary_times[@]}; i++ )); do
    seam_num=$(( i + 1 ))
    ord="$(pgm_ordinal_seam_label "$seam_num")"
    clock="$(format_output_timeline_clock "${boundary_times[$i]}")"
    pos="$(format_output_timeline_pos "${boundary_times[$i]}")"
    printf '  %s seam:  %s  (%s)  %s | %s\n' \
      "$ord" "$clock" "$pos" "${boundary_left[$i]}" "${boundary_right[$i]}"
  done
  echo
  return 0
}

# Return 2 if user quits from a prompt.
# Optional leading --force plays even when seam preview was turned off for this run.
prompt_seam_terminal_previews() {
  local force=0
  if [[ "${1:-}" == --force ]]; then
    force=1
    shift
  fi
  local output_file="$1"
  shift
  local -a files=("$@")
  local -a boundary_times=() boundary_left=() boundary_right=()
  local player i choice seam_num total_seams ord pos clock clip_total skip_rest=0

  if (( SEAM_PREVIEW_SKIP_RUN && ! force )); then
    return 0
  fi
  if (( DO_YES )) || (( ! script_is_run_interactively )); then
    return 0
  fi
  if ! merge_compute_boundaries boundary_times boundary_left boundary_right "${files[@]}"; then
    return 0
  fi
  if [[ ! -f "$output_file" ]]; then
    return 0
  fi
  if ! player=$(find_video_pgm_play_terminal); then
    echo "$(pgm_ts) video-pgm-play-terminal.sh not found — seam preview skipped."
    echo "$(pgm_ts) Install it to /root/bin or set VIDEO_PGM_PLAY_TERMINAL_BIN."
    print_merge_seam_times_summary "$output_file" "${files[@]}" || true
    return 0
  fi

  total_seams=${#boundary_times[@]}
  clip_total="$(merge_seam_clip_total_seconds "$PGM_SEAM_PREVIEW_BEFORE" "$PGM_SEAM_PREVIEW_AFTER")"
  echo
  echo "Terminal seam preview: ${player}"
  echo "Each clip starts ${PGM_SEAM_PREVIEW_BEFORE}s before the join, ${PGM_SEAM_PREVIEW_AFTER}s after (${clip_total}s total)."
  echo

  for (( i = 0; i < total_seams; i++ )); do
    seam_num=$(( i + 1 ))
    ord="$(pgm_ordinal_seam_label "$seam_num")"
    pos="$(format_output_timeline_pos "${boundary_times[$i]}")"
    clock="$(format_output_timeline_clock "${boundary_times[$i]}")"

    echo "--- ${ord} seam (${seam_num} of ${total_seams}) ---"
    echo "  ${boundary_left[$i]} | ${boundary_right[$i]}  at  ${clock}  (${pos})"
    echo "  [Y] Play output at this seam (${PGM_SEAM_PREVIEW_BEFORE}s before join, ${clip_total}s clip) (default)"
    echo "  [n] Skip this seam"
    echo "  [a] Skip all remaining seams"
    echo "  [s] Never play seams for the rest of this run"
    echo "  [q] Quit"
    pgm_read_key "Play ${ord} seam in terminal (at ${clock})? [Y/n/a/s/q]: " y
    choice="${REPLY,,}"
    case "$choice" in
      y)
        while true; do
          play_merge_seam_preview_once "$player" "$output_file" \
            "${boundary_times[$i]}" "${boundary_left[$i]}" "${boundary_right[$i]}" \
            "$seam_num" "$total_seams" "$ord"
          echo "  [y] Repeat ${ord} seam preview (at ${clock})"
          echo "  [N] Continue (default)"
          echo "  [a] Skip all remaining seams"
          echo "  [s] Never play seams for the rest of this run"
          echo "  [q] Quit"
          pgm_read_key "Repeat ${ord} seam preview (at ${clock})? [y/N/a/s/q]: " n
          choice="${REPLY,,}"
          case "$choice" in
            y) continue ;;
            a)
              echo "$(pgm_ts) Skipping remaining seams."
              skip_rest=1
              break
              ;;
            s)
              SEAM_PREVIEW_SKIP_RUN=1
              echo "$(pgm_ts) Seam preview off for the rest of this run."
              skip_rest=1
              break
              ;;
            q) return 2 ;;
            *) break ;;
          esac
        done
        ;;
      a)
        echo "$(pgm_ts) Skipping remaining seams."
        skip_rest=1
        ;;
      s)
        SEAM_PREVIEW_SKIP_RUN=1
        echo "$(pgm_ts) Seam preview off for the rest of this run."
        skip_rest=1
        ;;
      q)
        return 2
        ;;
      *)
        ;;
    esac
    (( skip_rest )) && break
  done
  echo
  print_merge_seam_times_summary "$output_file" "${files[@]}" || true
  return 0
}

# One line: part label (if any), basename, size (no trailing newline).
chapter_file_summary_line() {
  local f="$1"
  local base="${f##*/}" part sz dur dur_s
  sz=$(file_size_bytes "$f")
  if part=$(chapter_part_from_basename "$base" 2>/dev/null); then
    printf 'part %02d  %s  %s' "$part" "$base" "$(format_bytes_human "$sz")"
  else
    printf '%s  %s' "$base" "$(format_bytes_human "$sz")"
  fi
  if dur=$(ffprobe_duration_seconds "$f" 2>/dev/null) && [[ -n "$dur" ]]; then
    dur_s=$(format_duration_display "$dur")
    printf '  %s' "$dur_s"
  fi
}

# One line: part label (if any), basename, size, duration.
print_chapter_file_line() {
  local indent="$1" f="$2"
  printf '%s%s\n' "$indent" "$(chapter_file_summary_line "$f")"
}

# Print full basename (never truncate — long GoPro names must stay readable).
# One line when name + size + duration fit the terminal (and MAX_LINE_LENGTH).
# Otherwise: name on line 1, size + duration indented on line 2 so '|' columns still align.
PGM_IO_PART_W=8
MAX_LINE_LENGTH="${MAX_LINE_LENGTH:-200}"

# Usable width: the terminal, but never more than MAX_LINE_LENGTH.
pgm_terminal_columns() {
  local cols=""
  if [[ -t 1 ]]; then
    cols="$(tput cols 2>/dev/null || true)"
  fi
  if [[ -w /dev/tty ]] 2>/dev/null && [[ ! "$cols" =~ ^[0-9]+$ ]]; then
    cols="$(tput cols </dev/tty 2>/dev/null || true)"
  fi
  if [[ ! "$cols" =~ ^[0-9]+$ || "$cols" -lt 1 ]]; then
    cols="${COLUMNS:-}"
  fi
  if [[ ! "$cols" =~ ^[0-9]+$ || "$cols" -lt 1 ]]; then
    cols=80
  fi
  printf '%s' "$cols"
}

pgm_effective_line_width() {
  local cols max="${MAX_LINE_LENGTH:-200}"
  cols="$(pgm_terminal_columns)"
  if (( cols < max )); then
    printf '%s' "$cols"
  else
    printf '%s' "$max"
  fi
}

pgm_io_input_line() {
  local part_lbl="$1" f="$2"
  local base="${f##*/}" sz dur dur_disp size_s line width
  sz=$(file_size_bytes "$f")
  size_s="$(format_bytes_human_aligned "$sz")"
  if dur=$(ffprobe_duration_seconds "$f" 2>/dev/null) && [[ -n "$dur" ]]; then
    dur_disp=$(format_duration_display "$dur")
  else
    dur_disp="—"
  fi
  printf -v line '  %-*s %s  %s  %s' "$PGM_IO_PART_W" "$part_lbl" "$base" "$size_s" "$dur_disp"
  width="$(pgm_effective_line_width)"
  if (( ${#line} <= width )); then
    printf '%s\n' "$line"
    return 0
  fi
  printf '  %-*s %s\n' "$PGM_IO_PART_W" "$part_lbl" "$base"
  printf '  %-*s %s  %s\n' "$PGM_IO_PART_W" "" "$size_s" "$dur_disp"
}

# INPUT section, then OUTPUT section (narrower than side-by-side layout).
print_merge_group_io_block() {
  local output_file="$1"
  shift
  local -a files=("$@")
  local f input_total=0 out_sz=0 input_dur_total=0
  local base part_lbl dur
  local input_total_s output_total_s output_note input_dur_s sep line width

  for f in "${files[@]}"; do
    sz=$(file_size_bytes "$f")
    (( input_total += sz ))
    if dur=$(ffprobe_duration_seconds "$f" 2>/dev/null) && [[ -n "$dur" ]]; then
      input_dur_total=$(awk -v a="$input_dur_total" -v b="$dur" 'BEGIN{printf "%.3f", a+b}')
    fi
  done

  if [[ -e "$output_file" ]]; then
    out_sz=$(file_size_bytes "$output_file")
    output_total_s="$(format_bytes_human_aligned "$out_sz")"
    output_note="(on disk)"
    if dur=$(ffprobe_duration_seconds "$output_file" 2>/dev/null) && [[ -n "$dur" ]]; then
      output_note+="  $(format_duration_display "$dur")"
    fi
  else
    output_total_s="—"
    output_note="(not created yet)"
  fi
  input_total_s="$(format_bytes_human_aligned "$input_total")"
  sep=$(printf '%*s' 72 '' | tr ' ' '-')

  echo "  INPUT (${#files[@]} parts)"
  printf '  %s\n' "$sep"
  for f in "${files[@]}"; do
    base="${f##*/}"
    if part_lbl=$(chapter_part_from_basename "$base" 2>/dev/null); then
      part_lbl=$(printf 'part %02d' "$part_lbl")
    else
      part_lbl=""
    fi
    pgm_io_input_line "$part_lbl" "$f"
  done
  if [[ -n "$input_dur_total" ]] && awk -v d="$input_dur_total" 'BEGIN{exit !(d>0)}'; then
    input_dur_s=$(format_duration_display "$input_dur_total")
  else
    input_dur_s="—"
  fi
  printf '  %-*s %s  %s\n' "$PGM_IO_PART_W" "Total:" \
    "$input_total_s" "$input_dur_s"
  echo
  echo "  OUTPUT"
  printf '  %s\n' "$sep"
  printf -v line '  %s  Total: %s  %s' "${output_file}" "$output_total_s" "$output_note"
  width="$(pgm_effective_line_width)"
  if (( ${#line} <= width )); then
    printf '%s\n' "$line"
  else
    printf '  %s\n' "${output_file}"
    printf '  %-*s Total: %s  %s\n' "$PGM_IO_PART_W" "" \
      "$output_total_s" "$output_note"
  fi
}

# Absolute size difference (always non-negative).
format_bytes_abs_human() {
  local bytes="$1"
  if (( bytes < 0 )); then
    bytes=$(( -bytes ))
  fi
  format_bytes_human "$bytes"
}

# Describe which side is larger: input parts vs merged output (positive difference only).
format_size_comparison_line() {
  local input_total="$1" output_bytes="$2"
  local diff=0
  if (( input_total > output_bytes )); then
    diff=$(( input_total - output_bytes ))
    printf '  Difference: %s — input files are larger than output\n' "$(format_bytes_abs_human "$diff")"
  elif (( output_bytes > input_total )); then
    diff=$(( output_bytes - input_total ))
    printf '  Difference: %s — output is larger than input files\n' "$(format_bytes_abs_human "$diff")"
  else
    printf '  Difference: 0 bytes | 0.00 kB | 0.00 MB — input total and output are the same size\n'
  fi
}

# Background exiftool PID while rewriting a merge output (for Ctrl-C / progress).
PGM_EXIFTOOL_REWRITE_PID=""
# Show *_exiftool_tmp progress when the target is at least this large (default 50 MiB).
PGM_EXIFTOOL_PROGRESS_MIN_BYTES="${PGM_EXIFTOOL_PROGRESS_MIN_BYTES:-52428800}"

pgm_exiftool_rewrite_kill_child() {
  local pid="${PGM_EXIFTOOL_REWRITE_PID:-}"
  [[ -n "$pid" ]] || return 0
  kill "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
  PGM_EXIFTOOL_REWRITE_PID=""
}

# INT while an exiftool rewrite is running: stop the child, then the usual cleanup.
_pgm_exiftool_rewrite_on_int() {
  pgm_exiftool_rewrite_kill_child
  if [[ -n "${VIDEO_MERGE_OUT_FILE:-}" ]]; then
    video_merge_ctrl_c
  else
    ctrl_c
  fi
}

pgm_exiftool_rewrite_restore_int_trap() {
  if [[ -n "${VIDEO_MERGE_OUT_FILE:-}" ]]; then
    trap video_merge_ctrl_c INT
  else
    trap ctrl_c INT
  fi
}

format_bytes_short() {
  local bytes="${1:-0}"
  [[ "$bytes" =~ ^[0-9]+$ ]] || bytes=0
  awk -v b="$bytes" 'BEGIN {
    if (b >= 1073741824) printf "%.2f GiB", b / 1073741824.0
    else if (b >= 1048576) printf "%.1f MiB", b / 1048576.0
    else if (b >= 1024) printf "%.1f KiB", b / 1024.0
    else printf "%d B", b
  }'
}

# Rewrite one file with exiftool; for large targets, show % from growing *_exiftool_tmp.
# Usage: pgm_run_exiftool_rewrite_with_progress DEST PHASE exiftool [args…]
pgm_run_exiftool_rewrite_with_progress() {
  local dest="$1" phase="$2"
  shift 2
  local expected=0 cur=0 pct=0 pid rc=0 tmp min_b
  local width bar_w=20 filled empty msg room base
  local bar="" i

  [[ -f "$dest" ]] || return 1
  (( $# >= 1 )) || return 1
  expected="$(file_size_bytes "$dest")"
  [[ "$expected" =~ ^[0-9]+$ ]] || expected=0
  tmp="${dest}_exiftool_tmp"
  min_b="${PGM_EXIFTOOL_PROGRESS_MIN_BYTES:-52428800}"
  [[ "$min_b" =~ ^[0-9]+$ ]] || min_b=52428800

  trap _pgm_exiftool_rewrite_on_int INT
  "$@" >/dev/null 2>&1 &
  pid=$!
  PGM_EXIFTOOL_REWRITE_PID=$pid

  if (( expected < min_b )) || [[ ! -t 1 ]]; then
    wait "$pid"
    rc=$?
    PGM_EXIFTOOL_REWRITE_PID=""
    pgm_exiftool_rewrite_restore_int_trap
    return "$rc"
  fi

  while kill -0 "$pid" 2>/dev/null; do
    cur=0
    if [[ -f "$tmp" ]]; then
      cur="$(file_size_bytes "$tmp")"
      [[ "$cur" =~ ^[0-9]+$ ]] || cur=0
    fi
    if (( expected > 0 )); then
      pct=$(( cur * 100 / expected ))
      (( pct > 99 )) && pct=99
    else
      pct=0
    fi
    filled=$(( pct * bar_w / 100 ))
    empty=$(( bar_w - filled ))
    bar=""
    for (( i = 0; i < filled; i++ )); do bar+="#"; done
    for (( i = 0; i < empty; i++ )); do bar+="-"; done
    base="${dest##*/}"
    printf -v msg '%s %s  %3d%% [%s]  %s / %s' \
      "$(pgm_ts)" "$phase" "$pct" "$bar" \
      "$(format_bytes_short "$cur")" "$(format_bytes_short "$expected")"
    width="$(pgm_effective_line_width)"
    room=$(( width - ${#msg} - 2 ))
    if (( room >= 8 )) && [[ -n "$base" ]]; then
      if (( ${#base} > room )); then
        base="…${base: -$(( room - 1 ))}"
      fi
      msg+="  ${base}"
    fi
    if (( ${#msg} > width )); then
      msg="${msg:0:width}"
    fi
    printf '\r%s\033[K' "$msg"
    PGM_PROGRESS_ACTIVE=1
    sleep 0.5
  done

  wait "$pid"
  rc=$?
  PGM_EXIFTOOL_REWRITE_PID=""
  pgm_exiftool_rewrite_restore_int_trap
  if (( rc == 0 && expected > 0 )); then
    bar=""
    for (( i = 0; i < bar_w; i++ )); do bar+="#"; done
    printf -v msg '%s %s  %3d%% [%s]  %s / %s  %s' \
      "$(pgm_ts)" "$phase" 100 "$bar" \
      "$(format_bytes_short "$expected")" "$(format_bytes_short "$expected")" "${dest##*/}"
    width="$(pgm_effective_line_width)"
    if (( ${#msg} > width )); then
      msg="${msg:0:width}"
    fi
    printf '\r%s\033[K' "$msg"
    PGM_PROGRESS_ACTIVE=1
  fi
  pgm_progress_end
  return "$rc"
}

video_merge_ctrl_c() {
  local out="${VIDEO_MERGE_OUT_FILE:-}"
  pgm_exiftool_rewrite_kill_child
  if [[ -n "$out" ]]; then
    # Merge and post-merge (exiftool) may leave a partial final name or sidecar temps.
    rm -f -- "$out" "${out}_exiftool_tmp" "${out}.meta.tmp."* 2>/dev/null || true
    echo "$(pgm_ts) Removed incomplete output: ${out}"
    VIDEO_MERGE_OUT_FILE=""
  fi
  if [[ -n "${MERGE_TMP_DIR}" && -d "${MERGE_TMP_DIR}" ]]; then
    rm -rf -- "${MERGE_TMP_DIR}"
    echo "$(pgm_ts) Removed temp merge directory: ${MERGE_TMP_DIR}"
    MERGE_TMP_DIR=""
  fi
  ctrl_c
}

# True if basename is an existing merge output (skip as input).
is_concat_output_basename() {
  local base="${1%.*}"
  # …_concat.mp4 (legacy) or …_concat_parts_01-06[_Proxy].mp4
  [[ "${base}" == *_concat ]] && return 0
  [[ "${base}" =~ _concat_parts_[0-9]{2}-[0-9]{2}(_Proxy)?$ ]] && return 0
  return 1
}

# Set by concat_parse_cam_part_range: stem/camera token and part range from output name.
CONCAT_PARSE_CAM=""
CONCAT_PARSE_STEM=""
CONCAT_PARSE_PROXY=""
CONCAT_PARSE_FIRST=0
CONCAT_PARSE_LAST=0
CONCAT_DASH_START=""
CONCAT_DASH_END=""
CONCAT_DASH_LETTER=""
PGM_ORPHAN_CONCAT_COUNT=0

# Parse <stem>_concat_parts_01-04[_Proxy], legacy <stem>_parts_01-04[_Proxy]_concat,
# or legacy *_part_04_concat basename.
concat_parse_cam_part_range() {
  local base="$1"
  CONCAT_PARSE_CAM=""
  CONCAT_PARSE_STEM=""
  CONCAT_PARSE_PROXY=""
  CONCAT_PARSE_FIRST=0
  CONCAT_PARSE_LAST=0
  if [[ "$base" =~ ^(.+)_concat_parts_([0-9]{2})-([0-9]{2})(_Proxy)?\.[mM][pP]4$ ]]; then
    CONCAT_PARSE_STEM="${BASH_REMATCH[1]}"
    CONCAT_PARSE_PROXY="${BASH_REMATCH[4]}"
    CONCAT_PARSE_FIRST=$((10#${BASH_REMATCH[2]}))
    CONCAT_PARSE_LAST=$((10#${BASH_REMATCH[3]}))
    CONCAT_PARSE_CAM="$(gopro_camera_suffix_from_basename "$base" 2>/dev/null || true)"
    return 0
  fi
  if [[ "$base" =~ ^(.+)_parts_([0-9]{2})-([0-9]{2})(_Proxy)?_concat\.[mM][pP]4$ ]]; then
    CONCAT_PARSE_STEM="${BASH_REMATCH[1]}"
    CONCAT_PARSE_PROXY="${BASH_REMATCH[4]}"
    CONCAT_PARSE_FIRST=$((10#${BASH_REMATCH[2]}))
    CONCAT_PARSE_LAST=$((10#${BASH_REMATCH[3]}))
    CONCAT_PARSE_CAM="$(gopro_camera_suffix_from_basename "$base" 2>/dev/null || true)"
    return 0
  fi
  if [[ "$base" =~ _-__-_([^/]+)_part_([0-9]{2})_concat\.[mM][pP]4$ ]]; then
    CONCAT_PARSE_CAM="${BASH_REMATCH[1]}"
    CONCAT_PARSE_FIRST=$((10#${BASH_REMATCH[2]}))
    CONCAT_PARSE_LAST=$CONCAT_PARSE_FIRST
    return 0
  fi
  return 1
}

# 20260926_110627-20260926_130427_-_-_70mai-A510_FrontCam_concat.mp4
# Older files use 20260926-110627_20260926-130427_70mai-A510_FrontCam_concat.mp4.
# Start and end are the first and last NO* filename times. Camera is FrontCam/BackCam.
concat_parse_dashcam_output() {
  local base="$1"
  CONCAT_PARSE_CAM=""
  CONCAT_PARSE_STEM=""
  CONCAT_PARSE_PROXY=""
  CONCAT_PARSE_FIRST=0
  CONCAT_PARSE_LAST=0
  CONCAT_DASH_START=""
  CONCAT_DASH_END=""
  CONCAT_DASH_LETTER=""
  if [[ "$base" =~ ^([0-9]{8})_([0-9]{6})-([0-9]{8})_([0-9]{6})_-_-_(.+)_(FrontCam|BackCam|[A-Za-z])_concat\.[mM][pP]4$ ]] \
    || [[ "$base" =~ ^([0-9]{8})-([0-9]{6})_([0-9]{8})-([0-9]{6})_(.+)_(FrontCam|BackCam|[A-Za-z])_concat\.[mM][pP]4$ ]]; then
    CONCAT_DASH_START="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
    CONCAT_DASH_END="${BASH_REMATCH[3]}${BASH_REMATCH[4]}"
    CONCAT_PARSE_STEM="${BASH_REMATCH[5]}"
    CONCAT_PARSE_CAM="${BASH_REMATCH[6]}"
    case "$CONCAT_PARSE_CAM" in
      FrontCam) CONCAT_DASH_LETTER=F ;;
      BackCam)  CONCAT_DASH_LETTER=B ;;
      *) CONCAT_DASH_LETTER=$(printf '%s' "$CONCAT_PARSE_CAM" | tr '[:lower:]' '[:upper:]') ;;
    esac
    return 0
  fi
  return 1
}

# YYYYMMDDHHMMSS from a 70mai filename clock → 2026-09-26 11:06:27
dashcam_key_display() {
  local k="$1"
  printf '%s-%s-%s %s:%s:%s\n' \
    "${k:0:4}" "${k:4:2}" "${k:6:2}" \
    "${k:8:2}" "${k:10:2}" "${k:12:2}"
}

# How many NO* clips of this camera have a filename start from start_key through end_key.
count_dashcam_chapters_in_window() {
  local start_key="$1" end_key="$2" letter="$3"
  shift 3
  local -a all_mp4=("$@")
  local f base key found=0
  letter=$(printf '%s' "$letter" | tr '[:lower:]' '[:upper:]')
  for f in "${all_mp4[@]}"; do
    base="${f##*/}"
    is_concat_output_basename "$base" && continue
    dashcam_parse_basename "$base" || continue
    [[ "$DASHCAM_CAM" == "$letter" ]] || continue
    key="${DASHCAM_DATE}${DASHCAM_TIME}"
    [[ "$key" < "$start_key" ]] && continue
    [[ "$key" > "$end_key" ]] && continue
    (( found++ )) || true
  done
  printf '%d\n' "$found"
}

chapter_input_matches_stem_part() {
  local base="$1" stem="$2" part="$3" proxy_suffix="${4:-}"
  local pp want want_uc
  pp=$(printf '%02d' "$part")
  want="${stem}_part_${pp}${proxy_suffix}.mp4"
  want_uc="${stem}_part_${pp}${proxy_suffix}.MP4"
  [[ "$base" == "$want" || "$base" == "$want_uc" ]]
}

chapter_input_matches_cam_part() {
  local base="$1" cam="$2" part="$3"
  local pp
  pp=$(printf '%02d' "$part")
  [[ "$base" =~ _-__-_${cam}_part_${pp}(_Proxy)?\.[mM][pP]4$ ]]
}

# How many distinct parts exist as chapter inputs for a concat output's range.
count_chapter_inputs_for_concat_range() {
  local first="$1" last="$2" stem="$3" proxy_suffix="${4:-}" cam="${5:-}"
  shift 5
  local -a all_mp4=("$@")
  local f base p found=0
  for (( p = first; p <= last; p++ )); do
    for f in "${all_mp4[@]}"; do
      base="${f##*/}"
      is_concat_output_basename "$base" && continue
      if [[ -n "$stem" ]]; then
        chapter_input_matches_stem_part "$base" "$stem" "$p" "$proxy_suffix" || continue
      elif [[ -n "$cam" ]]; then
        chapter_input_matches_cam_part "$base" "$cam" "$p" || continue
      else
        continue
      fi
      (( found++ ))
      break
    done
  done
  printf '%d\n' "$found"
}

print_orphan_concat_section() {
  local -a all_mp4=("$@")
  local f base cam stem proxy first last expected found note sep sz
  local kind start_key end_key
  local -a orphans=()
  PGM_ORPHAN_CONCAT_COUNT=0

  for f in "${all_mp4[@]}"; do
    base="${f##*/}"
    is_concat_output_basename "$base" || continue
    if concat_parse_dashcam_output "$base"; then
      found=$(count_dashcam_chapters_in_window \
        "$CONCAT_DASH_START" "$CONCAT_DASH_END" "$CONCAT_DASH_LETTER" "${all_mp4[@]}")
      if (( found > 0 )); then
        continue
      fi
      orphans+=( "${f}|no input chapters in this folder|${CONCAT_PARSE_STEM}|${CONCAT_PARSE_CAM}|0|0|0|0|dashcam|${CONCAT_DASH_START}|${CONCAT_DASH_END}" )
      continue
    fi
    if ! concat_parse_cam_part_range "$base"; then
      orphans+=( "${f}|unparseable concat name||||0|0|0|0|other|" )
      continue
    fi
    cam="$CONCAT_PARSE_CAM"
    stem="$CONCAT_PARSE_STEM"
    proxy="$CONCAT_PARSE_PROXY"
    first="$CONCAT_PARSE_FIRST"
    last="$CONCAT_PARSE_LAST"
    expected=$(( last - first + 1 ))
    found=$(count_chapter_inputs_for_concat_range "$first" "$last" "$stem" "$proxy" "$cam" "${all_mp4[@]}")
    if (( found >= expected )); then
      continue
    fi
    if (( found == 0 )); then
      note="no input chapters in this folder"
    else
      note="only ${found} of ${expected} input chapter(s) present"
    fi
    orphans+=( "${f}|${note}|${stem}|${cam}|${first}|${last}|${expected}|${found}|gopro|" )
  done

  PGM_ORPHAN_CONCAT_COUNT=${#orphans[@]}
  (( PGM_ORPHAN_CONCAT_COUNT > 0 )) || return 0

  sep=$(printf '%*s' 72 '' | tr ' ' '-')
  echo "Merged outputs without input chapters in this folder:"
  printf '  %s\n' "$sep"
  for entry in "${orphans[@]}"; do
    IFS='|' read -r f note stem cam first last expected found kind start_key end_key <<< "$entry"
    base="${f##*/}"
    sz=$(file_size_bytes "$f")
    printf '  %s\n' "$base"
    printf '    %s\n' "$(format_bytes_human_aligned "$sz")"
    if [[ "$kind" == dashcam ]]; then
      printf '    Journey: %s – %s\n' \
        "$(dashcam_key_display "$start_key")" "$(dashcam_key_display "$end_key")"
      printf '    Camera: %s\n' "$cam"
    elif [[ -n "$stem" ]]; then
      printf '    Stem: %s  parts %02d-%02d\n' "$stem" "$first" "$last"
      [[ -n "$cam" ]] && printf '    Camera: %s\n' "$cam"
    elif [[ -n "$cam" ]]; then
      printf '    Camera: %s  parts %02d-%02d\n' "$cam" "$first" "$last"
    fi
    printf '    Status: %s\n' "$note"
    echo
  done
}

# Print decimal part number to stdout, or return 1 if not a _part_XX chapter name.
chapter_part_from_basename() {
  local base="$1"
  if [[ "$base" =~ _part_([0-9]{2})(_Proxy)?\.[mM][pP]4$ ]]; then
    printf '%d\n' "$((10#${BASH_REMATCH[1]}))"
    return 0
  fi
  return 1
}

chapter_camera_from_basename() {
  local base="$1"
  if gopro_camera_suffix_from_basename "$base"; then
    return 0
  fi
  if [[ "$base" =~ _-__-_([^/]+)_part_[0-9]{2} ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
    return 0
  fi
  return 1
}

# rename.sh capture-mode token on stem (Timelapse_2_1sec or bare Timelapse); rate may contain underscores.
gopro_capture_mode_token_from_stem() {
  local stem="$1"
  if [[ "$stem" =~ ^(.+)_(Timewarp|Timelapse)$ ]]; then
    printf '%s\n' "${BASH_REMATCH[2]}"
    return 0
  fi
  if [[ "$stem" =~ ^(.+)_(Timewarp|Timelapse)_(.+)$ ]]; then
    printf '%s_%s\n' "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}"
    return 0
  fi
  return 1
}

gopro_stem_without_capture_mode() {
  local stem="$1"
  if [[ "$stem" =~ ^(.+)_(Timewarp|Timelapse)$ ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
    return 0
  fi
  if [[ "$stem" =~ ^(.+)_(Timewarp|Timelapse)_.+$ ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
    return 0
  fi
  printf '%s\n' "$stem"
}

# GoPro clip without _part_XX: YYYYMMDD_HHMMSS[a]_…_GOPRO7_BLACK.MP4 or …_GOPRO10_BLACK_GX013496.MP4
# Optional single letter after HHMMSS (…_200322a_…) or after the camera token (…_GOPRO10_BLACKa.MP4)
# is rename-style chapter disambiguation when several chapters share one start time.
# Sets GOPRO_CAM_LETTER when the letter is on the camera token (empty otherwise).
# Sets GOPRO_PARSED_CAM and optional GOPRO_CAM_LETTER; also prints camera on stdout
# (for legacy cam=$(…) callers). Prefer reading GOPRO_PARSED_CAM when letter is needed.
gopro_camera_suffix_from_basename() {
  local base="$1"
  GOPRO_CAM_LETTER=""
  GOPRO_PARSED_CAM=""
  if [[ "$base" =~ _(GOPRO[0-9]+_[A-Z0-9]+)_([A-Z]{2}[0-9]{4,6})\.[mM][pP]4$ ]]; then
    GOPRO_PARSED_CAM="${BASH_REMATCH[1]}"
    printf '%s\n' "$GOPRO_PARSED_CAM"
    return 0
  fi
  # Trailing letter after UPPERCASE model: GOPRO10_BLACKa.MP4 → cam BLACK, letter a
  if [[ "$base" =~ (GOPRO[0-9]+_[A-Z0-9]+)([a-zA-Z])?\.[mM][pP]4$ ]]; then
    GOPRO_PARSED_CAM="${BASH_REMATCH[1]}"
    GOPRO_CAM_LETTER="${BASH_REMATCH[2]}"
    printf '%s\n' "$GOPRO_PARSED_CAM"
    return 0
  fi
  # rename.sh Timewarp/Timelapse before .mp4 (bare, with rate, and/or _part_XX):
  # …_GOPRO7_BLACK_Timelapse.mp4 / …_Timelapse_2_1sec.mp4 / …_Timelapse_part_01.mp4
  if [[ "$base" =~ (GOPRO[0-9]+_[A-Z0-9]+)_(Timewarp|Timelapse)(_part_[0-9]{2})?(_Proxy)?\.[mM][pP]4$ ]]; then
    GOPRO_PARSED_CAM="${BASH_REMATCH[1]}"
    printf '%s\n' "$GOPRO_PARSED_CAM"
    return 0
  fi
  if [[ "$base" =~ (GOPRO[0-9]+_[A-Z0-9]+)_(Timewarp|Timelapse)_[^./]+(_part_[0-9]{2})?(_Proxy)?\.[mM][pP]4$ ]]; then
    GOPRO_PARSED_CAM="${BASH_REMATCH[1]}"
    printf '%s\n' "$GOPRO_PARSED_CAM"
    return 0
  fi
  if [[ "$base" =~ (GoPro_[A-Za-z0-9_]+)_(Timewarp|Timelapse)(_part_[0-9]{2})?(_Proxy)?\.[mM][pP]4$ ]]; then
    GOPRO_PARSED_CAM="${BASH_REMATCH[1]}"
    printf '%s\n' "$GOPRO_PARSED_CAM"
    return 0
  fi
  if [[ "$base" =~ (GoPro_[A-Za-z0-9_]+)_(Timewarp|Timelapse)_[^./]+(_part_[0-9]{2})?(_Proxy)?\.[mM][pP]4$ ]]; then
    GOPRO_PARSED_CAM="${BASH_REMATCH[1]}"
    printf '%s\n' "$GOPRO_PARSED_CAM"
    return 0
  fi
  # Plain rename.sh camera token: …_GoPro_Hero7_Black.mp4 / …_GoPro_Hero7_Black_part_01.mp4
  if [[ "$base" =~ (GoPro_[A-Za-z0-9_]+)(_part_[0-9]{2})?(_Proxy)?\.[mM][pP]4$ ]]; then
    GOPRO_PARSED_CAM="${BASH_REMATCH[1]}"
    # Reject if the "camera" still ends with Timewarp/Timelapse (should have matched above).
    if [[ ! "$GOPRO_PARSED_CAM" =~ _(Timewarp|Timelapse)$ ]]; then
      printf '%s\n' "$GOPRO_PARSED_CAM"
      return 0
    fi
  fi
  return 1
}

# Optional GX-style chapter token (GX013496) before .MP4.
gopro_chapter_suffix_from_basename() {
  local base="$1"
  if [[ "$base" =~ _([A-Z]{2}[0-9]{4,6})\.[mM][pP]4$ ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
    return 0
  fi
  return 1
}

gopro_timestamp_cam_from_basename() {
  local base="$1"
  GOPRO_TS_DATE=""
  GOPRO_TS_TIME=""
  GOPRO_TS_LETTER=""
  GOPRO_TS_CAM=""
  GOPRO_TS_CHAPTER=""
  GOPRO_CAM_LETTER=""
  GOPRO_PARSED_CAM=""
  # With GX chapter token: date_time[letter]_middle_CAMERA_GXnnnnnn.ext
  if [[ "$base" =~ ^([0-9]{8})_([0-9]{6})([a-zA-Z])?_(.*)_((GOPRO[0-9]+_[A-Z0-9]+))_([A-Z]{2}[0-9]{4,6})\.[mM][pP]4$ ]]; then
    GOPRO_TS_DATE="${BASH_REMATCH[1]}"
    GOPRO_TS_TIME="${BASH_REMATCH[2]}"
    GOPRO_TS_LETTER="${BASH_REMATCH[3]}"
    GOPRO_TS_CAM="${BASH_REMATCH[5]}"
    GOPRO_TS_CHAPTER="${BASH_REMATCH[7]}"
    return 0
  fi
  # date_time[letter]_… — call camera parser without $() so GOPRO_CAM_LETTER is not lost in a subshell
  if [[ "$base" =~ ^([0-9]{8})_([0-9]{6})([a-zA-Z])?_ ]]; then
    GOPRO_TS_DATE="${BASH_REMATCH[1]}"
    GOPRO_TS_TIME="${BASH_REMATCH[2]}"
    GOPRO_TS_LETTER="${BASH_REMATCH[3]}"
  else
    return 1
  fi
  if ! gopro_camera_suffix_from_basename "$base" >/dev/null; then
    return 1
  fi
  GOPRO_TS_CAM="$GOPRO_PARSED_CAM"
  # Prefer time-letter; else use camera-letter (…_GOPRO10_BLACKa).
  if [[ -z "${GOPRO_TS_LETTER}" && -n "${GOPRO_CAM_LETTER:-}" ]]; then
    GOPRO_TS_LETTER="$GOPRO_CAM_LETTER"
  fi
  GOPRO_TS_CHAPTER=""
  return 0
}

# Middle part of GoPro basename (between timestamp[+letter] and camera suffix[+letter]).
gopro_middle_from_basename() {
  local base="$1" mid
  gopro_timestamp_cam_from_basename "$base" || return 1
  if [[ "$base" =~ ^[0-9]{8}_[0-9]{6}[a-zA-Z]?_(.*)_((GOPRO[0-9]+_[A-Z0-9]+))_([A-Z]{2}[0-9]{4,6})\.[mM][pP]4$ ]]; then
    mid="${BASH_REMATCH[1]}"
  elif [[ "$base" =~ ^[0-9]{8}_[0-9]{6}[a-zA-Z]?_(.*)_(GOPRO[0-9]+_[A-Z0-9]+)_(Timewarp|Timelapse)(_[^./]+)?(_part_[0-9]{2})?(_Proxy)?\.[mM][pP]4$ ]]; then
    mid="${BASH_REMATCH[1]}"
  elif [[ "$base" =~ ^[0-9]{8}_[0-9]{6}[a-zA-Z]?_(.*)_(GOPRO[0-9]+_[A-Z0-9]+)[a-zA-Z]?(_part_[0-9]{2})?(_Proxy)?\.[mM][pP]4$ ]]; then
    mid="${BASH_REMATCH[1]}"
  elif [[ "$base" =~ ^[0-9]{8}_[0-9]{6}[a-zA-Z]?_(.*)_(GoPro_[A-Za-z0-9_]+)_(Timewarp|Timelapse)(_[^./]+)?(_part_[0-9]{2})?(_Proxy)?\.[mM][pP]4$ ]]; then
    mid="${BASH_REMATCH[1]}"
  elif [[ "$base" =~ ^[0-9]{8}_[0-9]{6}[a-zA-Z]?_(.*)_(GoPro_[A-Za-z0-9_]+)(_part_[0-9]{2})?(_Proxy)?\.[mM][pP]4$ ]]; then
    mid="${BASH_REMATCH[1]}"
  else
    return 1
  fi
  printf '%s\n' "$mid"
}

# Grouping key: same date, time, camera, and middle (ignores per-file GX chapter / letter suffix).
gopro_recording_group_key_from_basename() {
  local base="$1" mid
  gopro_timestamp_cam_from_basename "$base" || return 1
  mid=$(gopro_middle_from_basename "$base" 2>/dev/null) || mid=""
  printf '%s_%s|%s|%s\n' "$GOPRO_TS_DATE" "$GOPRO_TS_TIME" "$GOPRO_TS_CAM" "$mid"
}

# Size-split session key: same calendar day + camera + middle; leading HHMMSS may differ.
gopro_size_split_session_key_from_basename() {
  local base="$1" mid
  gopro_timestamp_cam_from_basename "$base" || return 1
  mid=$(gopro_middle_from_basename "$base" 2>/dev/null) || mid=""
  printf '%s|%s|%s\n' "$GOPRO_TS_DATE" "$GOPRO_TS_CAM" "$mid"
}

# Next lowercase letter after $1 (a→b); empty if not a–y.
gopro_next_chapter_letter() {
  local letter="${1,,}" alphabet=abcdefghijklmnopqrstuvwxyz idx
  [[ "$letter" =~ ^[a-y]$ ]] || { printf ''; return 1; }
  idx=${alphabet%%"${letter}"*}
  idx=${#idx}
  printf '%s\n' "${alphabet:$((idx + 1)):1}"
}

# True when files share one recording stamp/camera/middle and chapter letters are a,b,c… consecutive.
# Rename-style disambiguation (…_200322a_… or …_GOPRO10_BLACKa.MP4) — merge at any size, like part_01.
gopro_letter_chapter_run_ok() {
  local -a files=("$@")
  local f base key0="" key letter prev="" expected
  (( ${#files[@]} >= 2 )) || return 1
  for f in "${files[@]}"; do
    base="${f##*/}"
    if chapter_part_from_basename "$base" >/dev/null 2>&1; then
      return 1
    fi
    gopro_timestamp_cam_from_basename "$base" || return 1
    letter="${GOPRO_TS_LETTER,,}"
    [[ "$letter" =~ ^[a-z]$ ]] || return 1
    key=$(gopro_recording_group_key_from_basename "$base") || return 1
    if [[ -z "$key0" ]]; then
      [[ "$letter" == a ]] || return 1
      key0="$key"
      prev="$letter"
      continue
    fi
    [[ "$key" == "$key0" ]] || return 1
    expected=$(gopro_next_chapter_letter "$prev") || return 1
    [[ "$letter" == "$expected" ]] || return 1
    prev="$letter"
  done
  return 0
}

# Sort key for size-split singles (time order, then letter a/b/c…, then GX chapter number).
gopro_size_split_sort_key() {
  local f="$1" base ch sort_num letter_key
  base="${f##*/}"
  gopro_timestamp_cam_from_basename "$base" || { printf '%s\n' "$base"; return 0; }
  sort_num=0
  if [[ -n "${GOPRO_TS_CHAPTER:-}" && "$GOPRO_TS_CHAPTER" =~ ^[A-Z]{2}([0-9]+)$ ]]; then
    sort_num=$((10#${BASH_REMATCH[1]}))
  fi
  # Empty letter sorts before 'a' (use '_' so plain HHMMSS comes first within same second).
  letter_key="${GOPRO_TS_LETTER:-_}"
  printf '%s_%s_%s_%06d_%s\n' "$GOPRO_TS_DATE" "$GOPRO_TS_TIME" "$letter_key" "$sort_num" "$base"
}

# Seconds since midnight from HHMMSS (for same-day checks without date(1)).
gopro_hhmmss_to_seconds() {
  local t="$1"
  awk -v t="$t" 'BEGIN {
    h=int(substr(t,1,2)); m=int(substr(t,3,2)); s=int(substr(t,5,2));
    printf "%d\n", h*3600+m*60+s
  }'
}

# Epoch seconds for YYYYMMDD + HHMMSS (uses date(1) when available).
gopro_datetime_to_epoch() {
  local d="$1" t="$2" iso
  iso="${d:0:4}-${d:4:2}-${d:6:2} ${t:0:2}:${t:2:2}:${t:4:2}"
  if date -d "$iso" +%s 2>/dev/null; then
    return 0
  fi
  return 1
}

# 0 = next clip follows previous by hybrid start + duration (± tolerance).
size_split_chapter_timestamps_follow() {
  local prev_f="$1" next_f="$2"
  local pb prev_epoch next_epoch dur expected delta tol gap
  pb="${prev_f##*/}"
  prev_epoch="$(pgm_hybrid_start_epoch "$prev_f" 2>/dev/null)" || return 1
  next_epoch="$(pgm_hybrid_start_epoch "$next_f" 2>/dev/null)" || return 1

  if (( prev_epoch == next_epoch )); then
    return 0
  fi
  delta=$(( next_epoch - prev_epoch ))
  if (( delta >= -2 && delta <= 2 )); then
    return 0
  fi
  (( next_epoch >= prev_epoch )) || return 1

  # Next realtime chapter must start at prev start + duration. GoPro: ±2s.
  tol="${PGM_SIZE_SPLIT_TIME_TOLERANCE_SEC:-2}"
  [[ "$tol" =~ ^[0-9]+$ ]] || tol=2
  dur=$(ffprobe_duration_seconds "$prev_f" 2>/dev/null) || dur=""

  if [[ -n "$dur" ]]; then
    expected=$(awk -v p="$prev_epoch" -v d="$dur" 'BEGIN{printf "%d", p+d+0.5}')
    delta=$(( next_epoch - expected ))
    if (( delta >= -tol && delta <= tol )); then
      return 0
    fi
  fi
  gap=$(( next_epoch - prev_epoch ))
  part_chapter_timelapse_wall_clock_ok "$prev_f" "$gap" "$dur" && return 0
  # Without duration: bare _Timelapse chapters often sit ~20–80 min apart (Hero7 ~4 GB).
  if [[ -z "$dur" ]] && gopro_basename_is_timelapse "$pb" \
    && (( gap >= 1200 && gap <= 4800 )); then
    return 0
  fi
  return 1
}

gopro_token_is_noise() {
  local t="${1,,}"
  [[ "$t" =~ ^s[0-9]+$ ]] && return 0
  case "$t" in
    niecaly|film|proxy|black|gopro|niecalyfilm) return 0 ;;
  esac
  return 1
}

# Human session label for grouping (dermatolog-s29 vs farma-s29, order-independent).
gopro_session_key_from_basename() {
  local base="$1" mid
  local -a tokens=()
  mid=$(gopro_middle_from_basename "$base") || return 1
  mapfile -t tokens < <(
    printf '%s\n' "$mid" | tr '_-( )' '\n' | tr '[:upper:]' '[:lower:]' |
      grep -E '^[a-z0-9]{2,}$' | grep -Ev '^(niecaly|film|proxy|black|gopro)$' | LC_ALL=C sort -u
  )
  ((${#tokens[@]} > 0)) || return 1
  local IFS='-'
  printf '%s\n' "${tokens[*]}"
}

# Primary description token (dermatolog, farma).
gopro_description_from_basename() {
  local base="$1" mid
  mid=$(gopro_middle_from_basename "$base") || return 1
  printf '%s\n' "$mid" | tr '_-( )' '\n' | tr '[:upper:]' '[:lower:]' |
    grep -E '^[a-z]{4,}$' | grep -Ev '^(s[0-9]+|niecaly|film|proxy|black|gopro)$' | head -1
}

# S29-style tag from basename, if present.
gopro_s_tag_from_basename() {
  local base="$1" mid raw
  mid=$(gopro_middle_from_basename "$base") || return 1
  raw=$(printf '%s\n' "$mid" | grep -oiE 's[0-9]{1,3}' | head -1) || return 1
  raw="${raw,,}"
  printf 'S%s\n' "${raw#s}"
}

# Session label for output names: S29_-_dermatolog
gopro_session_label_slug_from_basename() {
  local base="$1" s_tag="" desc="" key part
  s_tag=$(gopro_s_tag_from_basename "$base" 2>/dev/null) || s_tag=""
  desc=$(gopro_description_from_basename "$base" 2>/dev/null) || desc=""
  if [[ -z "$s_tag" || -z "$desc" ]]; then
    key=$(gopro_session_key_from_basename "$base" 2>/dev/null) || key=""
    if [[ -n "$key" ]]; then
      IFS='-' read -r -a parts <<< "$key"
      for part in "${parts[@]}"; do
        [[ -z "$part" ]] && continue
        if [[ "$part" =~ ^s[0-9]+$ ]]; then
          s_tag="S${part#s}"
        elif [[ -z "$desc" ]]; then
          desc="$part"
        fi
      done
    fi
  fi
  if [[ -n "$s_tag" && -n "$desc" ]]; then
    printf '%s_-_-%s' "$s_tag" "$desc"
    return 0
  fi
  [[ -n "$desc" ]] && printf '%s\n' "$desc" && return 0
  [[ -n "$s_tag" ]] && printf '%s\n' "$s_tag" && return 0
  return 1
}

gopro_camera_from_basename() {
  local base="$1"
  if gopro_camera_suffix_from_basename "$base"; then
    return 0
  fi
  chapter_camera_from_basename "$base"
}

# GoPro fixed-size chapter splits: ~4 GB (classic FAT32 cap) and ~12 GB (exFAT / high-bitrate cap).
# Decimal literals: $(( 10000 * 1024 * 1024 )) overflows 32-bit bash arithmetic.
PGM_SIZE_SPLIT_4G_MIN_BYTES=3670016000
PGM_SIZE_SPLIT_4G_MAX_BYTES=4718592000
# ~9.77–13 GiB: Mission 1 Pro size-cap splits ~10–11 GiB. An 8.1 GiB complete clip is not a full split.
PGM_SIZE_SPLIT_12G_MIN_BYTES=10485760000
PGM_SIZE_SPLIT_12G_MAX_BYTES=13958643712
# Legacy names used by near-miss hints (4 GB band).
PGM_SIZE_SPLIT_MIN_BYTES=$PGM_SIZE_SPLIT_4G_MIN_BYTES
PGM_SIZE_SPLIT_MAX_BYTES=$PGM_SIZE_SPLIT_4G_MAX_BYTES
# With ffprobe: reject a full chapter only if duration is clearly too short for its size tier.
PGM_SIZE_SPLIT_DURATION_REJECT_BELOW_SEC="${PGM_SIZE_SPLIT_DURATION_REJECT_BELOW_SEC:-420}"
# High-bitrate Mission 1 ~10 GB chapters are often ~10–16 min; do not require Hero-like ~18 min.
PGM_SIZE_SPLIT_12G_DURATION_REJECT_BELOW_SEC="${PGM_SIZE_SPLIT_12G_DURATION_REJECT_BELOW_SEC:-120}"
PGM_SIZE_SPLIT_12G_TIME_MAX_GAP_SEC="${PGM_SIZE_SPLIT_12G_TIME_MAX_GAP_SEC:-2400}"
# GoPro cameras (7, 10, …): ~4 GB chapters often ~6:49 (409s).
PGM_GOPRO7_SIZE_MIN_BYTES=$PGM_SIZE_SPLIT_4G_MIN_BYTES
PGM_GOPRO7_SIZE_MAX_BYTES=$PGM_SIZE_SPLIT_4G_MAX_BYTES
PGM_GOPRO7_DURATION_MIN_SEC="${PGM_GOPRO7_DURATION_MIN_SEC:-380}"
PGM_GOPRO7_DURATION_MAX_SEC="${PGM_GOPRO7_DURATION_MAX_SEC:-450}"

pgm_size_bytes_in_closed_range() {
  awk -v sz="$1" -v lo="$2" -v hi="$3" 'BEGIN { exit !(sz+0 >= lo+0 && sz+0 <= hi+0) }'
}

pgm_size_bytes_lt() {
  awk -v sz="$1" -v lim="$2" 'BEGIN { exit !(sz+0 < lim+0) }'
}

# stdout: 4 | 12 | empty
size_split_tier_for_bytes() {
  local sz="$1"
  pgm_size_bytes_in_closed_range "$sz" "$PGM_SIZE_SPLIT_12G_MIN_BYTES" "$PGM_SIZE_SPLIT_12G_MAX_BYTES" \
    && { printf '12'; return 0; }
  pgm_size_bytes_in_closed_range "$sz" "$PGM_SIZE_SPLIT_4G_MIN_BYTES" "$PGM_SIZE_SPLIT_4G_MAX_BYTES" \
    && { printf '4'; return 0; }
  return 1
}

size_split_tier_for_file() {
  local f="$1"
  size_split_tier_for_bytes "$(file_size_bytes "$f")"
}

gopro_camera_is_gopro7() {
  local c="${1^^}"
  [[ "$c" == *GOPRO7* || "$c" == *HERO7* ]]
}

gopro_camera_uses_4gb_chapter_duration() {
  local c="${1^^}"
  [[ "$c" == *GOPRO* ]]
}

gopro7_size_in_chapter_range() {
  local sz="$1"
  pgm_size_bytes_in_closed_range "$sz" "$PGM_GOPRO7_SIZE_MIN_BYTES" "$PGM_GOPRO7_SIZE_MAX_BYTES"
}

duration_in_gopro7_chapter_range() {
  local dur="$1"
  awk -v d="$dur" -v lo="$PGM_GOPRO7_DURATION_MIN_SEC" -v hi="$PGM_GOPRO7_DURATION_MAX_SEC" \
    'BEGIN { exit !(d+0 >= lo && d+0 <= hi) }'
}

ffprobe_duration_seconds() {
  local f="$1" key d
  command -v ffprobe >/dev/null 2>&1 || return 1
  [[ -n "$f" && -f "$f" ]] || return 1
  key="$(readlink -f -- "$f" 2>/dev/null || printf '%s' "$f")"
  if [[ -n "${PGM_FFPROBE_DUR_CACHE[$key]+x}" ]]; then
    d="${PGM_FFPROBE_DUR_CACHE[$key]}"
    [[ -n "$d" ]] || return 1
    printf '%s\n' "$d"
    return 0
  fi
  d=$(ffprobe -v error -show_entries format=duration \
    -of default=noprint_wrappers=1:nokey=1 -- "$f" 2>/dev/null) || {
    PGM_FFPROBE_DUR_CACHE[$key]=""
    return 1
  }
  [[ -n "$d" ]] || {
    PGM_FFPROBE_DUR_CACHE[$key]=""
    return 1
  }
  d=$(awk -v d="$d" 'BEGIN { if (d+0 >= 0) printf "%.3f\n", d+0; else exit 1 }') || {
    PGM_FFPROBE_DUR_CACHE[$key]=""
    return 1
  }
  PGM_FFPROBE_DUR_CACHE[$key]="$d"
  printf '%s\n' "$d"
}

# Compact track fingerprint for mp4_merge compatibility (video|audio CSV fields).
# Video: codec,profile,width,height,pix_fmt,avg_frame_rate,time_base
# Audio: codec,profile,sample_rate,channels  (or "none")
ffprobe_merge_fingerprint() {
  local f="$1" v a
  command -v ffprobe >/dev/null 2>&1 || return 1
  v=$(ffprobe -v error -select_streams v:0 \
    -show_entries stream=codec_name,profile,width,height,pix_fmt,avg_frame_rate,time_base \
    -of csv=p=0 -- "$f" 2>/dev/null) || return 1
  [[ -n "$v" ]] || return 1
  a=$(ffprobe -v error -select_streams a:0 \
    -show_entries stream=codec_name,profile,sample_rate,channels \
    -of csv=p=0 -- "$f" 2>/dev/null) || a=""
  [[ -n "$a" ]] || a="none"
  printf '%s|%s\n' "$v" "$a"
}

# Human one-liner from a fingerprint (for the refusal table).
merge_fingerprint_label() {
  local fp="$1" v a
  local vc vp vw vh pix fps tb ac ap ar ach
  v="${fp%%|*}"
  a="${fp#*|}"
  IFS=',' read -r vc vp vw vh pix fps tb <<<"$v"
  if [[ "$a" == "none" ]]; then
    printf 'V %s %s %sx%s %s %s tb=%s | A (none)' \
      "${vc:-?}" "${vp:-?}" "${vw:-?}" "${vh:-?}" "${pix:-?}" "${fps:-?}" "${tb:-?}"
    return 0
  fi
  IFS=',' read -r ac ap ar ach <<<"$a"
  printf 'V %s %s %sx%s %s %s tb=%s | A %s %s %sHz %sch' \
    "${vc:-?}" "${vp:-?}" "${vw:-?}" "${vh:-?}" "${pix:-?}" "${fps:-?}" "${tb:-?}" \
    "${ac:-?}" "${ap:-?}" "${ar:-?}" "${ach:-?}"
}

# 0 = all files match the first; 1 = mismatch or probe failure (prints a table).
# Used before mp4_merge: refuse mixed families (e.g. mp3 vs aac, different time bases).
merge_group_assert_codecs() {
  local -a files=("$@")
  local f fp0 fp i
  local -a fps=()
  local mismatch=0 probe_fail=0
  local -a diff_notes=()

  (( ${#files[@]} >= 2 )) || return 0
  if ! command -v ffprobe >/dev/null 2>&1; then
    echo "$(pgm_ts) ffprobe not found — cannot verify that tracks match before mp4_merge." >&2
    return 0
  fi

  for f in "${files[@]}"; do
    if ! fp=$(ffprobe_merge_fingerprint "$f"); then
      echo "$(pgm_ts) Cannot read tracks with ffprobe: ${f##*/}" >&2
      probe_fail=1
      fps+=("")
      continue
    fi
    fps+=("$fp")
  done
  if (( probe_fail )); then
    echo "$(pgm_ts) Refusing merge: ffprobe could not read every input." >&2
    return 1
  fi

  fp0="${fps[0]}"
  for i in "${!files[@]}"; do
    [[ "${fps[i]}" == "$fp0" ]] && continue
    mismatch=1
    break
  done
  (( mismatch )) || return 0

  echo "$(pgm_ts) Refusing merge: video/audio tracks do not match (mp4_merge needs the same codecs and layout)." >&2
  echo >&2
  printf '  %-52s %s\n' "file" "tracks" >&2
  for i in "${!files[@]}"; do
    f="${files[i]}"
    fp="${fps[i]}"
    if [[ "$fp" == "$fp0" ]]; then
      printf '  %-52s %s\n' "${f##*/}" "$(merge_fingerprint_label "$fp")" >&2
    else
      printf '  %-52s %s  ← differs\n' "${f##*/}" "$(merge_fingerprint_label "$fp")" >&2
    fi
  done
  echo >&2
  echo "$(pgm_ts) Merge only matching families (e.g. all *_NVenc_* or all HandBrake). Mixed pairs need ffmpeg, not mp4_merge." >&2
  return 1
}

PGM_EXIFTOOL_DEFAULT="${PGM_EXIFTOOL_DEFAULT:-/mnt/luks-buffalo2/worek/_video-JEDYNE_KOPIE/_katalog_roboczy/scripts/Image-ExifTool-12.41/exiftool}"
PGM_EXIFTOOL="${PGM_EXIFTOOL:-${RENAME_EXIFTOOL:-${EXIFLOC:-$PGM_EXIFTOOL_DEFAULT}}}"
PGM_EXIFTOOL_RESOLVED=""

resolve_pgm_exiftool() {
  local cmd_path
  if [[ -n "$PGM_EXIFTOOL_RESOLVED" ]]; then
    printf '%s' "$PGM_EXIFTOOL_RESOLVED"
    return 0
  fi
  if [[ -n "$PGM_EXIFTOOL" && -x "$PGM_EXIFTOOL" ]]; then
    PGM_EXIFTOOL_RESOLVED="$PGM_EXIFTOOL"
    printf '%s' "$PGM_EXIFTOOL_RESOLVED"
    return 0
  fi
  if cmd_path=$(command -v exiftool 2>/dev/null); then
    PGM_EXIFTOOL_RESOLVED="$cmd_path"
    printf '%s' "$PGM_EXIFTOOL_RESOLVED"
    return 0
  fi
  return 1
}

gopro_fetch_rate_tag() {
  local file="$1" exifloc rate
  exifloc="$(resolve_pgm_exiftool)" || return 1
  rate="$("$exifloc" -api largefilesupport=1 -Rate -s3 "$file" 2>/dev/null | head -n 1)"
  rate="${rate//$'\r'/}"
  rate="${rate//$'\n'/}"
  [[ -n "$rate" ]] || return 1
  printf '%s' "$rate"
}

gopro_file_has_audio_track() {
  local file="$1" exifloc fmt ch
  exifloc="$(resolve_pgm_exiftool)" || return 1
  fmt="$("$exifloc" -api largefilesupport=1 -AudioFormat -s3 "$file" 2>/dev/null | head -n 1)"
  fmt="${fmt//$'\r'/}"
  fmt="${fmt//$'\n'/}"
  fmt="${fmt,,}"
  if [[ -n "$fmt" && "$fmt" != n/a && "$fmt" != off ]]; then
    return 0
  fi
  ch="$("$exifloc" -api largefilesupport=1 -AudioChannels -s3 "$file" 2>/dev/null | head -n 1)"
  ch="${ch//$'\r'/}"
  ch="${ch//$'\n'/}"
  [[ "$ch" =~ ^[1-9][0-9]*$ ]]
}

# GoPro Rate timelapse interval (1_5sec → 1.5). Same rules as rename.sh (*[0-9]sec, not *x).
gopro_rate_tag_is_timelapse() {
  local rate="${1,,}"
  [[ -n "$rate" ]] || return 1
  case "$rate" in
    off|n/a) return 1 ;;
    auto|[0-9]*x) return 1 ;;
    *[0-9]sec) return 0 ;;
  esac
  return 1
}

gopro_rate_tag_timelapse_interval_seconds() {
  local rate="${1,,}" interval=""
  gopro_rate_tag_is_timelapse "$rate" || return 1
  if [[ "$rate" =~ ^([0-9]+)_([0-9]+)sec$ ]]; then
    interval="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
  elif [[ "$rate" =~ ^([0-9]+(\.[0-9]+)?)sec$ ]]; then
    interval="${BASH_REMATCH[1]}"
  else
    return 1
  fi
  printf '%s\n' "$interval"
}

gopro_basename_is_timelapse() {
  # rename.sh Hero7: bare _Timelapse.mp4; others: _Timelapse_2_1sec; with parts: _Timelapse_part_01
  [[ "$1" =~ _Timelapse(_|\.) ]]
}

# True when file is GoPro timelapse (_Timelapse_ in name, or exiftool Rate …sec without audio).
gopro_file_is_timelapse() {
  local f="$1" base="${f##*/}" rate=""
  if gopro_basename_is_timelapse "$base"; then
    gopro_file_has_audio_track "$f" && return 1
    return 0
  fi
  rate=$(gopro_fetch_rate_tag "$f" 2>/dev/null) || return 1
  gopro_rate_tag_is_timelapse "$rate" || return 1
  gopro_file_has_audio_track "$f" && return 1
}

# True when wall-clock gap between chapter filename times fits timelapse (gap >> playback).
part_chapter_timelapse_wall_clock_ok() {
  local prev_f="$1" gap="$2" dur="$3"
  local rate="" interval="" fps ratio_tol ratio_min ratio_max

  gopro_file_is_timelapse "$prev_f" || return 1
  [[ -n "$dur" && -n "$gap" ]] || return 1
  awk -v g="$gap" -v d="$dur" 'BEGIN { exit !(g+0 > 0 && d+0 > 0) }' || return 1

  ratio_min="${PGM_PART_TIMELAPSE_GAP_RATIO_MIN:-4.5}"
  ratio_max="${PGM_PART_TIMELAPSE_GAP_RATIO_MAX:-6.5}"
  if awk -v g="$gap" -v d="$dur" -v lo="$ratio_min" -v hi="$ratio_max" \
    'BEGIN { r = g/d; exit !(r+0 >= lo && r+0 <= hi) }'; then
    return 0
  fi

  rate=$(gopro_fetch_rate_tag "$prev_f" 2>/dev/null) || return 1
  interval=$(gopro_rate_tag_timelapse_interval_seconds "$rate" 2>/dev/null) || return 1
  fps="${PGM_GOPRO_TIMELAPSE_FPS:-30}"
  ratio_tol="${PGM_PART_TIMELAPSE_GAP_RATIO_TOLERANCE:-0.35}"
  awk -v g="$gap" -v d="$dur" -v i="$interval" -v fps="$fps" -v tol="$ratio_tol" \
    'BEGIN {
      if (d+0 <= 0 || i+0 <= 0) exit 1
      exp = i * fps
      if (exp+0 <= 0) exit 1
      r = g / d
      lo = exp * (1 - tol)
      hi = exp * (1 + tol)
      exit !(r+0 >= lo && r+0 <= hi)
    }'
}

# Wall-clock fallback when prev start + duration does not match next start
# (pause / stop between chapters). Wider than size-split defaults so a lunch
# stop does not always break a part_01…NN day.
part_chapter_realtime_wall_clock_gap_ok() {
  local prev_f="$1" gap="$2"
  local min_gap max_gap
  min_gap="${PGM_PART_CHAPTER_TIME_MIN_GAP_SEC:-${PGM_SIZE_SPLIT_TIME_MIN_GAP_SEC:-300}}"
  max_gap="${PGM_PART_CHAPTER_TIME_MAX_GAP_SEC:-3600}"
  if size_split_tier_for_file "$prev_f" | grep -qx 12; then
    max_gap="${PGM_PART_CHAPTER_12G_TIME_MAX_GAP_SEC:-${PGM_SIZE_SPLIT_12G_TIME_MAX_GAP_SEC:-3600}}"
  fi
  (( gap >= min_gap && gap <= max_gap ))
}

duration_too_short_for_full_size_split() {
  local dur="$1" tier="${2:-4}"
  local rej="$PGM_SIZE_SPLIT_DURATION_REJECT_BELOW_SEC"
  [[ "$tier" == 12 ]] && rej="$PGM_SIZE_SPLIT_12G_DURATION_REJECT_BELOW_SEC"
  awk -v d="$dur" -v rej="$rej" \
    'BEGIN { exit !(d+0 > 0 && d+0 < rej) }'
}

# Full segment at a size tier (4 or 12); reject only clearly invalid durations.
is_full_size_split_segment_at_tier() {
  local f="$1" tier="$2" sz dur base cam="" gopro_chap=0
  base="${f##*/}"
  sz=$(file_size_bytes "$f")
  dur=$(ffprobe_duration_seconds "$f" 2>/dev/null) || dur=""

  case "$tier" in
    12)
      # Size is the split cap. Mission 1 5.3K fills ~10 GB in well under 18 min.
      pgm_size_bytes_in_closed_range "$sz" "$PGM_SIZE_SPLIT_12G_MIN_BYTES" "$PGM_SIZE_SPLIT_12G_MAX_BYTES" || return 1
      if [[ -n "$dur" ]]; then
        duration_too_short_for_full_size_split "$dur" 12 && return 1
      fi
      return 0
      ;;
    4)
      cam=$(gopro_camera_from_basename "$base" 2>/dev/null) || cam=
      gopro_camera_uses_4gb_chapter_duration "$cam" && gopro_chap=1
      if (( gopro_chap )); then
        if gopro7_size_in_chapter_range "$sz"; then
          if [[ -n "$dur" ]]; then
            duration_in_gopro7_chapter_range "$dur" && return 0
            duration_too_short_for_full_size_split "$dur" 4 && return 1
          fi
          return 0
        fi
        if [[ -n "$dur" ]] && duration_in_gopro7_chapter_range "$dur" \
          && ! pgm_size_bytes_lt "$sz" "$PGM_GOPRO7_SIZE_MIN_BYTES"; then
          return 0
        fi
      fi
      pgm_size_bytes_in_closed_range "$sz" "$PGM_SIZE_SPLIT_4G_MIN_BYTES" "$PGM_SIZE_SPLIT_4G_MAX_BYTES" || return 1
      if [[ -n "$dur" ]]; then
        duration_too_short_for_full_size_split "$dur" 4 && return 1
      fi
      return 0
      ;;
  esac
  return 1
}

# Full segment: auto-detect 12 GB band first, then 4 GB / GoPro7.
is_full_size_split_segment() {
  local f="$1" tier
  tier=$(size_split_tier_for_file "$f") || return 1
  is_full_size_split_segment_at_tier "$f" "$tier"
}

is_partial_size_split_segment_at_tier() {
  local f="$1" tier="$2" sz dur base cam="" gopro_chap=0
  base="${f##*/}"
  sz=$(file_size_bytes "$f")
  dur=$(ffprobe_duration_seconds "$f" 2>/dev/null) || dur=""

  case "$tier" in
    12)
      pgm_size_bytes_lt "$sz" "$PGM_SIZE_SPLIT_12G_MIN_BYTES" && return 0
      return 1
      ;;
    4)
      cam=$(gopro_camera_from_basename "$base" 2>/dev/null) || cam=
      gopro_camera_uses_4gb_chapter_duration "$cam" && gopro_chap=1
      if (( gopro_chap )); then
        pgm_size_bytes_lt "$sz" "$PGM_GOPRO7_SIZE_MIN_BYTES" && return 0
        if [[ -n "$dur" ]] && ! duration_in_gopro7_chapter_range "$dur" \
          && duration_too_short_for_full_size_split "$dur" 4; then
          return 0
        fi
        return 1
      fi
      pgm_size_bytes_lt "$sz" "$PGM_SIZE_SPLIT_4G_MIN_BYTES" && return 0
      if [[ -n "$dur" ]]; then
        duration_too_short_for_full_size_split "$dur" 4 && return 0
      fi
      return 1
      ;;
  esac
  return 1
}

is_partial_size_split_segment() {
  local f="$1" tier="${2:-}"
  [[ -n "$tier" ]] || tier=$(size_split_tier_for_file "$f" 2>/dev/null) || tier=4
  is_partial_size_split_segment_at_tier "$f" "$tier"
}


size_split_run_valid() {
  local -a run=("$@")
  local i n=${#run[@]} f tier next_tier
  (( n >= 2 )) || return 1
  tier=$(size_split_tier_for_file "${run[0]}") || return 1
  for (( i = 0; i < n - 1; i++ )); do
    next_tier=$(size_split_tier_for_file "${run[i]}") || return 1
    [[ "$next_tier" == "$tier" ]] || return 1
    is_full_size_split_segment_at_tier "${run[i]}" "$tier" || return 1
  done
  f="${run[n - 1]}"
  next_tier=$(size_split_tier_for_file "$f") || next_tier=""
  if [[ -n "$next_tier" && "$next_tier" == "$tier" ]] && is_full_size_split_segment_at_tier "$f" "$tier"; then
    return 0
  fi
  is_partial_size_split_segment_at_tier "$f" "$tier"
}

size_split_group_output_file() {
  local -a files=("$@")
  local fb date1 t1 cam1 middle="" n
  fb="${files[0]##*/}"
  gopro_timestamp_cam_from_basename "$fb" || return 1
  date1="$GOPRO_TS_DATE" t1="$GOPRO_TS_TIME" cam1="$GOPRO_TS_CAM"
  middle=$(gopro_middle_from_basename "$fb") || return 1
  n=${#files[@]}
  (( n >= 1 )) || return 1
  # e.g. 20220115_200322_-__-_GOPRO10_BLACK_concat_parts_01-06.mp4
  printf '%s_%s_%s_%s_concat_parts_01-%02d.mp4\n' "$date1" "$t1" "$middle" "$cam1" "$n"
}

# Label for merged output metadata (title/description).
group_merge_description_label() {
  local -a files=("$@")
  local fb middle
  fb="${files[0]##*/}"
  middle=$(gopro_middle_from_basename "$fb") || return 1
  middle="${middle#_}"
  middle="${middle%_}"
  middle="${middle//_-/ }"
  middle="${middle//_/ }"
  printf '%s\n' "$middle"
}

# Copy GPS / create&modify dates / camera tags from the first chapter onto the merge
# output (selective — not -All:All, which would overwrite Duration etc.), and set
# optional title/description in the same exiftool rewrite. If the user already chose
# an output epoch (pgm_decide_output_times), override media dates in that same pass.
# Finally set filesystem times (chosen epoch, or touch -r from the first chapter).
# On a Windows drive (/mnt/p and the like) the creation time is copied too.
apply_merge_output_metadata() {
  local output_file="$1" source_file="$2" label="${3-}"
  local exifloc="" rc=0 iso=""
  local -a et_cmd=()
  local use_pending=0

  [[ -f "$output_file" && -f "$source_file" ]] || return 0

  if [[ "${PGM_PENDING_OUTPUT_TIMES_MODE:-}" == epoch \
    && "${PGM_PENDING_OUTPUT_TIMES_EPOCH:-}" =~ ^[0-9]+$ ]]; then
    use_pending=1
    iso="$(date -d "@${PGM_PENDING_OUTPUT_TIMES_EPOCH}" '+%Y:%m:%d %H:%M:%S' 2>/dev/null)" || {
      use_pending=0
      iso=""
    }
  fi

  if exifloc="$(resolve_pgm_exiftool 2>/dev/null)"; then
    # -P: do not bump FS mtime during tag write; we re-apply times afterward.
    # Title (+ optional date override) in the same pass so a large concat is not rewritten twice.
    et_cmd=(
      "$exifloc" -overwrite_original -P
      -api largefilesupport=1 -api QuickTimeUTC=1
      -TagsFromFile "$source_file"
      -time:all -gps:all
      -Make -Model -Software -Artist -Copyright
      -Keys:Make -Keys:Model -Keys:GPSCoordinates
      -ItemList:Make -ItemList:Model
      -QuickTime:GPSCoordinates
      -FileCreateDate -FileModifyDate
    )
    if [[ -n "$label" ]]; then
      et_cmd+=(
        -QuickTime:Title="$label"
        -QuickTime:Description="$label"
        -QuickTime:Comment="$label"
        -ItemList:Title="$label"
      )
    fi
    if (( use_pending )) && [[ -n "$iso" ]]; then
      # After TagsFromFile so these win over the chapter's CreateDate.
      et_cmd+=(
        -AllDates="$iso"
        -CreateDate="$iso" -ModifyDate="$iso"
        -TrackCreateDate="$iso" -TrackModifyDate="$iso"
        -MediaCreateDate="$iso" -MediaModifyDate="$iso"
        -FileCreateDate="$iso" -FileModifyDate="$iso"
      )
    fi
    et_cmd+=( -- "$output_file" )
    if pgm_run_exiftool_rewrite_with_progress "$output_file" "exiftool metadata" \
      "${et_cmd[@]}"; then
      pgm_log_kv "Metadata" "copied GPS/dates/camera from ${source_file##*/}"
      if [[ -n "$label" ]]; then
        pgm_log_kv "Metadata title" "$label"
      fi
      if (( use_pending )); then
        pgm_log_kv "Output times" "media tags from ${PGM_PENDING_OUTPUT_TIMES_LABEL} (chosen before merge)"
        PGM_PENDING_OUTPUT_TIMES_MEDIA_DONE=1
      fi
    else
      pgm_log_kv "Metadata" "exiftool TagsFromFile failed (GPS/dates may be incomplete)"
      rc=1
      if [[ -n "$label" ]]; then
        pgm_log_kv "Metadata title" "could not write via exiftool"
      fi
    fi
  else
    pgm_log_kv "Metadata" "exiftool not found — skipped GPS/date copy from first chapter"
    if [[ -n "$label" ]] && command -v ffmpeg >/dev/null 2>&1; then
      local tmp="${output_file}.meta.tmp.$$"
      if ffmpeg -y -v error -i "$output_file" -codec copy \
        -metadata "title=${label}" -metadata "description=${label}" \
        -metadata "comment=${label}" "$tmp" 2>/dev/null \
        && mv -f -- "$tmp" "$output_file"; then
        pgm_log_kv "Metadata title" "$label (ffmpeg fallback; may strip some tags)"
      else
        rm -f -- "$tmp"
        pgm_log_kv "Metadata" "could not write title (ffmpeg fallback failed)"
        rc=1
      fi
    fi
  fi

  if (( use_pending )); then
    if pgm_set_fs_times_epoch "$output_file" "$PGM_PENDING_OUTPUT_TIMES_EPOCH"; then
      pgm_log_kv "Filesystem times" "$(pgm_format_epoch_display "$PGM_PENDING_OUTPUT_TIMES_EPOCH") (${PGM_PENDING_OUTPUT_TIMES_LABEL})"
      PGM_PENDING_OUTPUT_TIMES_FS_DONE=1
    else
      pgm_log_kv "Filesystem times" "could not set chosen time"
      rc=1
    fi
    local gpx_side=""
    gpx_side="$(dashcam_gpx_beside_output "$output_file" 2>/dev/null || true)"
    if [[ -n "$gpx_side" && -f "$gpx_side" ]]; then
      pgm_set_fs_times_epoch "$gpx_side" "$PGM_PENDING_OUTPUT_TIMES_EPOCH" || true
    fi
  else
    if touch -r "$source_file" -- "$output_file" 2>/dev/null; then
      pgm_log_kv "Filesystem times" "mtime/atime from ${source_file##*/}"
    else
      pgm_log_kv "Filesystem times" "touch -r failed"
      rc=1
    fi
    pgm_copy_creation "$source_file" "$output_file" || true
  fi
  return "$rc"
}

# Windows creation time. touch -r copies the file time, not this one.
pgm_copy_creation() {
  local src="$1" dest="$2" src_w dest_w
  [[ -f "$src" && -f "$dest" && "$src" != "$dest" ]] || return 0
  [[ "$src" == /mnt/?/* && "$dest" == /mnt/?/* ]] || return 0
  command -v powershell.exe >/dev/null 2>&1 || return 0
  command -v wslpath >/dev/null 2>&1 || return 0
  src_w=$(wslpath -w "$src") || return 0
  dest_w=$(wslpath -w "$dest") || return 0
  src_w=${src_w//\'/\'\'}
  dest_w=${dest_w//\'/\'\'}
  powershell.exe -NoProfile -Command "\$s = Get-Item -LiteralPath '${src_w}'; \$d = Get-Item -LiteralPath '${dest_w}'; \$d.CreationTime = \$s.CreationTime" >/dev/null 2>&1
}

# Same name, or the same name without a trailing speed such as _x5 or -x5.
pgm_find_gpx() {
  local mp4="$1" dir stem cand
  dir="$(dirname -- "$mp4")"
  stem="$(basename -- "$mp4")"
  stem="${stem%.*}"
  for cand in "$stem" "$(sed -E 's/[-_][xX][0-9]+([-_][0-9]{8}-[0-9]{6})?$//' <<<"$stem")"; do
    if [[ -f "${dir}/${cand}.gpx" ]]; then
      printf '%s\n' "${dir}/${cand}.gpx"
      return 0
    fi
  done
  return 1
}

# "lat lon ele" of the first track point. ele may be empty.
pgm_gpx_first() {
  awk '
    function attr(line, key,    re, s, n) {
      re = key "=\"[-+0-9.eE]+\""
      if (match(line, re)) {
        n = length(key) + 2
        s = substr(line, RSTART + n, RLENGTH - n - 1)
        return s
      }
      return ""
    }
    {
      if (!inpt && index($0, "<trkpt") > 0) {
        lat = attr($0, "lat")
        lon = attr($0, "lon")
        if (lat != "" && lon != "") inpt = 1
      }
      if (inpt) {
        if (match($0, /<ele>[-+0-9.eE]+<\/ele>/)) {
          ele = substr($0, RSTART + 5, RLENGTH - 11)
        }
        if (index($0, "</trkpt>") > 0 || index($0, "/>") > 0) {
          print lat, lon, ele
          printed = 1
          exit
        }
      }
    }
    END {
      if (!printed && inpt && lat != "") print lat, lon, ele
    }
  ' "$1"
}

pgm_video_has_gps() {
  local exif="$1" dest="$2" got
  got=$("$exif" -s3 -m -GPSCoordinates -Keys:GPSCoordinates -UserData:GPSCoordinates -ItemList:GPSCoordinates -- "$dest" 2>/dev/null | tr -d '[:space:]')
  [[ -n "$got" ]]
}

# Store the first point of a .gpx in $1 when $1 has no location.
# The .gpx beside $1 is used, otherwise the one beside $2.
pgm_put_gps() {
  local dest="$1" src="$2" gpx="" exif lat lon ele coord
  [[ -f "$dest" ]] || return 0
  case "${dest##*.}" in
    mp4|MP4|mov|MOV) ;;
    *) return 0 ;;
  esac
  exif="$(resolve_pgm_exiftool 2>/dev/null)" || return 0
  pgm_video_has_gps "$exif" "$dest" && return 0
  gpx="$(dashcam_gpx_beside_output "$dest")"
  [[ -f "$gpx" ]] || gpx=""
  if [[ -z "$gpx" && -n "$src" ]]; then
    gpx="$(pgm_find_gpx "$src" || true)"
  fi
  [[ -f "$gpx" ]] || return 0
  read -r lat lon ele < <(pgm_gpx_first "$gpx") || return 0
  [[ "$lat" =~ ^[-+0-9.eE]+$ && "$lon" =~ ^[-+0-9.eE]+$ ]] || return 0
  awk -v lat="$lat" -v lon="$lon" 'BEGIN { if ((lat+0)^2 + (lon+0)^2 < 1e-12) exit 1 }' || return 0
  if [[ "$ele" =~ ^[-+0-9.eE]+$ ]]; then
    coord=$(awk -v a="$lat" -v b="$lon" -v c="$ele" 'BEGIN { printf "%.7f, %.7f, %.3f", a, b, c }')
  else
    coord=$(awk -v a="$lat" -v b="$lon" 'BEGIN { printf "%.7f, %.7f", a, b }')
  fi
  if pgm_run_exiftool_rewrite_with_progress "$dest" "exiftool GPS" \
    "$exif" -overwrite_original -P -api largefilesupport=1 \
      -Keys:GPSCoordinates="$coord" \
      -UserData:GPSCoordinates="$coord" \
      -ItemList:GPSCoordinates="$coord" \
      -- "$dest"; then
    pgm_log_kv "Location" "${lat}, ${lon} from ${gpx##*/}"
    # Prefer the date chosen before merge; otherwise match the first chapter.
    if [[ "${PGM_PENDING_OUTPUT_TIMES_MODE:-}" == epoch \
      && "${PGM_PENDING_OUTPUT_TIMES_EPOCH:-}" =~ ^[0-9]+$ ]]; then
      pgm_set_fs_times_epoch "$dest" "$PGM_PENDING_OUTPUT_TIMES_EPOCH" || true
    elif [[ -n "$src" && -f "$src" ]]; then
      touch -r "$src" -- "$dest" 2>/dev/null || true
      pgm_copy_creation "$src" "$dest" || true
    fi
  else
    pgm_log_kv "Location" "could not store a point from ${gpx##*/}"
  fi
}

# File time and Windows creation time of $2, taken from $1. No video tags.
pgm_stamp_file_time() {
  local src="$1" dest="$2"
  [[ -f "$src" && -f "$dest" && "$src" != "$dest" ]] || return 0
  if touch -r "$src" -- "$dest" 2>/dev/null; then
    pgm_copy_creation "$src" "$dest" || true
    pgm_log_kv "Filesystem times" "mtime/atime from ${src##*/}"
  else
    pgm_log_kv "Filesystem times" "touch -r failed for ${dest##*/}"
  fi
}

# Epoch seconds for 1990-01-01 local (dates before this are treated as unusable).
PGM_TIME_MIN_EPOCH=""
pgm_time_min_epoch() {
  if [[ -z "$PGM_TIME_MIN_EPOCH" ]]; then
    PGM_TIME_MIN_EPOCH="$(date -d '1990-01-01 00:00:00' +%s 2>/dev/null || printf '631152000')"
  fi
  printf '%s\n' "$PGM_TIME_MIN_EPOCH"
}

pgm_epoch_usable() {
  local e="${1:-}"
  [[ "$e" =~ ^[0-9]+$ ]] || return 1
  (( e >= $(pgm_time_min_epoch) )) || return 1
  return 0
}

pgm_format_epoch_display() {
  local e="$1"
  date -d "@${e}" '+%Y.%m.%d %H:%M:%S' 2>/dev/null \
    || date -r "$e" '+%Y.%m.%d %H:%M:%S' 2>/dev/null \
    || printf '%s\n' "$e"
}

# Leading YYYYMMDD_HHMMSS or YYYYMMDD-HHMMSS in a basename → Unix epoch (local).
pgm_filename_epoch_from_basename() {
  local base="$1" d t iso e
  base="${base##*/}"
  if [[ "$base" =~ ^([0-9]{8})[_-]([0-9]{6}) ]]; then
    d="${BASH_REMATCH[1]}"
    t="${BASH_REMATCH[2]}"
  elif [[ "$base" =~ ^[Nn][Oo]([0-9]{8})-([0-9]{6}) ]]; then
    d="${BASH_REMATCH[1]}"
    t="${BASH_REMATCH[2]}"
  elif [[ "$base" =~ ^[Ee][Vv]([0-9]{8})-([0-9]{6}) ]]; then
    d="${BASH_REMATCH[1]}"
    t="${BASH_REMATCH[2]}"
  else
    return 1
  fi
  iso="${d:0:4}-${d:4:2}-${d:6:2} ${t:0:2}:${t:2:2}:${t:4:2}"
  e="$(date -d "$iso" +%s 2>/dev/null)" || return 1
  pgm_epoch_usable "$e" || return 1
  printf '%s\n' "$e"
}

pgm_fs_mtime_epoch() {
  local f="$1" e
  e="$(stat -c %Y -- "$f" 2>/dev/null || stat -f %m -- "$f" 2>/dev/null)" || return 1
  pgm_epoch_usable "$e" || return 1
  printf '%s\n' "$e"
}

# Parse an exiftool CreateDate string into a usable Unix epoch (stdout), or fail.
pgm_createdate_raw_to_epoch() {
  local raw="$1" iso e
  raw="${raw//$'\r'/}"
  raw="${raw#"${raw%%[![:space:]]*}"}"
  raw="${raw%"${raw##*[![:space:]]}"}"
  [[ -n "$raw" && "$raw" != "-" && "$raw" != "0000:00:00 00:00:00" \
    && "$raw" != "0000-00-00 00:00:00" ]] || return 1
  iso="$raw"
  if [[ "$iso" =~ ^([0-9]{4}):([0-9]{2}):([0-9]{2})(.*)$ ]]; then
    iso="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]}${BASH_REMATCH[4]}"
  fi
  e="$(date -d "$iso" +%s 2>/dev/null)" || return 1
  pgm_epoch_usable "$e" || return 1
  printf '%s\n' "$e"
}

pgm_media_createdate_epoch() {
  local f="$1" key exif raw e
  [[ -n "$f" && -f "$f" ]] || return 1
  key="$(readlink -f -- "$f" 2>/dev/null || printf '%s' "$f")"
  if [[ -n "${PGM_MEDIA_CREATEDATE_EPOCH[$key]+x}" ]]; then
    e="${PGM_MEDIA_CREATEDATE_EPOCH[$key]}"
    [[ -n "$e" ]] || return 1
    printf '%s\n' "$e"
    return 0
  fi
  exif="$(resolve_pgm_exiftool 2>/dev/null)" || return 1
  # Hyphens: GNU date rejects exiftool's default YYYY:MM:DD form.
  raw="$("$exif" -api largefilesupport=1 -api QuickTimeUTC=1 -s3 -CreateDate \
    -d '%Y-%m-%d %H:%M:%S' -- "$f" 2>/dev/null | head -n1 | tr -d '\r')"
  if e="$(pgm_createdate_raw_to_epoch "$raw" 2>/dev/null)"; then
    PGM_MEDIA_CREATEDATE_EPOCH[$key]="$e"
    printf '%s\n' "$e"
    return 0
  fi
  PGM_MEDIA_CREATEDATE_EPOCH[$key]=""
  return 1
}

# Batch-fill PGM_MEDIA_CREATEDATE_EPOCH for many files (chunked exiftool + progress).
pgm_media_createdate_batch_fill() {
  local -a files=("$@")
  local exif n i chunk_end f key path raw e line
  local chunk_size=12
  local -a chunk=()
  n=${#files[@]}
  (( n > 0 )) || return 0
  exif="$(resolve_pgm_exiftool 2>/dev/null)" || return 1
  i=0
  while (( i < n )); do
    chunk=()
    chunk_end=$(( i + chunk_size ))
    (( chunk_end > n )) && chunk_end=$n
    while (( i < chunk_end )); do
      f="${files[i]}"
      (( i++ )) || true
      [[ -f "$f" ]] || continue
      key="$(readlink -f -- "$f" 2>/dev/null || printf '%s' "$f")"
      if [[ -n "${PGM_MEDIA_CREATEDATE_EPOCH[$key]+x}" ]]; then
        continue
      fi
      chunk+=( "$f" )
    done
    (( ${#chunk[@]} )) || {
      pgm_progress_update "CreateDate" "$chunk_end" "$n" ""
      continue
    }
    pgm_progress_update "CreateDate" "$chunk_end" "$n" "${chunk[-1]}"
    while IFS= read -r line; do
      line="${line//$'\r'/}"
      [[ "$line" == *$'\t'* ]] || continue
      path="${line%%$'\t'*}"
      raw="${line#*$'\t'}"
      [[ -n "$path" ]] || continue
      key="$(readlink -f -- "$path" 2>/dev/null || printf '%s' "$path")"
      if e="$(pgm_createdate_raw_to_epoch "$raw" 2>/dev/null)"; then
        PGM_MEDIA_CREATEDATE_EPOCH[$key]="$e"
      else
        PGM_MEDIA_CREATEDATE_EPOCH[$key]=""
      fi
    done < <(
      "$exif" -api largefilesupport=1 -api QuickTimeUTC=1 -q -q -f \
        -d '%Y-%m-%d %H:%M:%S' -p '$FilePath${tab}$CreateDate' -- "${chunk[@]}" 2>/dev/null
    )
    # Mark any chunk files exiftool omitted as known misses.
    for f in "${chunk[@]}"; do
      key="$(readlink -f -- "$f" 2>/dev/null || printf '%s' "$f")"
      if [[ -z "${PGM_MEDIA_CREATEDATE_EPOCH[$key]+x}" ]]; then
        PGM_MEDIA_CREATEDATE_EPOCH[$key]=""
      fi
    done
  done
  pgm_progress_end
}

pgm_hybrid_start_cache_clear() {
  PGM_HYBRID_START_EPOCH=()
  PGM_HYBRID_START_SRC=()
  PGM_HYBRID_START_MEDIA_N=0
  PGM_MEDIA_CREATEDATE_EPOCH=()
}

# Warm hybrid starts for chapter planning (batch CreateDate, then per-file resolve).
pgm_hybrid_preload_files() {
  local -a files=("$@")
  local n i f
  n=${#files[@]}
  (( n > 0 )) || return 0
  echo "$(pgm_ts) Reading clip start times (${n} file(s); filename + CreateDate when needed)…"
  pgm_media_createdate_batch_fill "${files[@]}" || true
  i=0
  for f in "${files[@]}"; do
    (( i++ )) || true
    pgm_progress_update "Hybrid start" "$i" "$n" "$f"
    pgm_hybrid_start_epoch "$f" >/dev/null 2>&1 || true
  done
  pgm_progress_end
}

# Clip start for chapter sort/chain: filename time by default; media CreateDate when
# it disagrees with the name by more than PGM_PART_CHAPTER_MEDIA_TIME_DISAGREE_SEC.
# Cached per real path for the chapter-plan pass.
pgm_hybrid_start_epoch() {
  local f="$1" key name_e="" media_e="" chosen="" diff thresh
  [[ -n "$f" && -f "$f" ]] || return 1
  key="$(readlink -f -- "$f" 2>/dev/null || printf '%s' "$f")"
  if [[ -n "${PGM_HYBRID_START_EPOCH[$key]+x}" ]]; then
    printf '%s\n' "${PGM_HYBRID_START_EPOCH[$key]}"
    return 0
  fi
  name_e="$(pgm_filename_epoch_from_basename "${f##*/}" 2>/dev/null)" || name_e=""
  media_e="$(pgm_media_createdate_epoch "$f" 2>/dev/null)" || media_e=""
  thresh="${PGM_PART_CHAPTER_MEDIA_TIME_DISAGREE_SEC:-120}"
  [[ "$thresh" =~ ^[0-9]+$ ]] || thresh=120
  if [[ -n "$name_e" && -n "$media_e" ]]; then
    if (( name_e > media_e )); then
      diff=$(( name_e - media_e ))
    else
      diff=$(( media_e - name_e ))
    fi
    if (( diff > thresh )); then
      chosen="$media_e"
      PGM_HYBRID_START_SRC[$key]=media
      PGM_HYBRID_START_MEDIA_N=$(( PGM_HYBRID_START_MEDIA_N + 1 ))
    else
      chosen="$name_e"
      PGM_HYBRID_START_SRC[$key]=name
    fi
  elif [[ -n "$name_e" ]]; then
    chosen="$name_e"
    PGM_HYBRID_START_SRC[$key]=name
  elif [[ -n "$media_e" ]]; then
    chosen="$media_e"
    PGM_HYBRID_START_SRC[$key]=media
    PGM_HYBRID_START_MEDIA_N=$(( PGM_HYBRID_START_MEDIA_N + 1 ))
  else
    return 1
  fi
  PGM_HYBRID_START_EPOCH[$key]="$chosen"
  printf '%s\n' "$chosen"
}

pgm_hybrid_start_media_note() {
  local thresh="${PGM_PART_CHAPTER_MEDIA_TIME_DISAGREE_SEC:-120}"
  (( PGM_HYBRID_START_MEDIA_N > 0 )) || return 0
  echo "$(pgm_ts) Chapter times: used media CreateDate for ${PGM_HYBRID_START_MEDIA_N} file(s) (disagreed with the filename by more than ${thresh}s)."
}

# Set filesystem mtime/atime (and Windows creation on /mnt/?/) from a Unix epoch.
pgm_set_fs_times_epoch() {
  local dest="$1" epoch="$2" touch_fmt dest_w
  [[ -f "$dest" && "$epoch" =~ ^[0-9]+$ ]] || return 1
  touch_fmt="$(date -d "@${epoch}" +%Y%m%d%H%M.%S 2>/dev/null)" || return 1
  touch -t "$touch_fmt" -- "$dest" 2>/dev/null || return 1
  if [[ "$dest" == /mnt/?/* ]] \
    && command -v powershell.exe >/dev/null 2>&1 \
    && command -v wslpath >/dev/null 2>&1; then
    dest_w=$(wslpath -w "$dest") || return 0
    dest_w=${dest_w//\'/\'\'}
    powershell.exe -NoProfile -Command \
      "\$d = Get-Item -LiteralPath '${dest_w}'; \$t = [DateTimeOffset]::FromUnixTimeSeconds(${epoch}).LocalDateTime; \$d.CreationTime = \$t; \$d.LastWriteTime = \$t" \
      >/dev/null 2>&1 || true
  fi
  return 0
}

# Write media CreateDate / ModifyDate (and QuickTime track/media peers) from a Unix epoch.
# FileCreateDate/FileModifyDate go in the same rewrite when possible so a large concat
# is not rewritten three times; FS tags alone are a best-effort fallback.
pgm_set_media_dates_epoch() {
  local dest="$1" epoch="$2" exif iso ok=0
  [[ -f "$dest" && "$epoch" =~ ^[0-9]+$ ]] || return 1
  exif="$(resolve_pgm_exiftool 2>/dev/null)" || return 1
  iso="$(date -d "@${epoch}" '+%Y:%m:%d %H:%M:%S' 2>/dev/null)" || return 1
  if pgm_run_exiftool_rewrite_with_progress "$dest" "exiftool dates" \
    "$exif" -overwrite_original -P -api largefilesupport=1 -api QuickTimeUTC=1 \
    -AllDates="$iso" \
    -CreateDate="$iso" -ModifyDate="$iso" \
    -TrackCreateDate="$iso" -TrackModifyDate="$iso" \
    -MediaCreateDate="$iso" -MediaModifyDate="$iso" \
    -FileCreateDate="$iso" -FileModifyDate="$iso" \
    -- "$dest"; then
    return 0
  fi
  if pgm_run_exiftool_rewrite_with_progress "$dest" "exiftool dates" \
    "$exif" -overwrite_original -P -api largefilesupport=1 -api QuickTimeUTC=1 \
    -CreateDate="$iso" -ModifyDate="$iso" \
    -TrackCreateDate="$iso" -TrackModifyDate="$iso" \
    -MediaCreateDate="$iso" -MediaModifyDate="$iso" \
    -FileCreateDate="$iso" -FileModifyDate="$iso" \
    -- "$dest"; then
    return 0
  fi
  if pgm_run_exiftool_rewrite_with_progress "$dest" "exiftool dates" \
    "$exif" -overwrite_original -P -api largefilesupport=1 -api QuickTimeUTC=1 \
    -CreateDate="$iso" -ModifyDate="$iso" \
    -TrackCreateDate="$iso" -TrackModifyDate="$iso" \
    -MediaCreateDate="$iso" -MediaModifyDate="$iso" \
    -- "$dest"; then
    ok=1
  fi
  pgm_run_exiftool_rewrite_with_progress "$dest" "exiftool FS dates" \
    "$exif" -overwrite_original -P -api largefilesupport=1 -api QuickTimeUTC=1 \
    -FileCreateDate="$iso" -FileModifyDate="$iso" \
    -- "$dest" || true
  (( ok ))
}

pgm_apply_epoch_to_output() {
  local dest="$1" epoch="$2" gpx="" disp
  disp="$(pgm_format_epoch_display "$epoch")"
  if pgm_set_media_dates_epoch "$dest" "$epoch"; then
    pgm_log_kv "Media CreateDate" "$disp"
  else
    pgm_log_kv "Media CreateDate" "could not write ${disp}"
  fi
  if pgm_set_fs_times_epoch "$dest" "$epoch"; then
    pgm_log_kv "Filesystem times" "$disp"
  else
    pgm_log_kv "Filesystem times" "could not set ${disp}"
  fi
  gpx="$(dashcam_gpx_beside_output "$dest" 2>/dev/null || true)"
  if [[ -n "$gpx" && -f "$gpx" ]]; then
    pgm_set_fs_times_epoch "$gpx" "$epoch" || true
  fi
}

# Pending output-time choice for the next merge (set by pgm_decide_output_times).
# MODE: none | keep | epoch
PGM_PENDING_OUTPUT_TIMES_MODE=""
PGM_PENDING_OUTPUT_TIMES_EPOCH=""
PGM_PENDING_OUTPUT_TIMES_LABEL=""
PGM_PENDING_OUTPUT_TIMES_MEDIA_DONE=0
PGM_PENDING_OUTPUT_TIMES_FS_DONE=0

pgm_clear_pending_output_times() {
  PGM_PENDING_OUTPUT_TIMES_MODE=""
  PGM_PENDING_OUTPUT_TIMES_EPOCH=""
  PGM_PENDING_OUTPUT_TIMES_LABEL=""
  PGM_PENDING_OUTPUT_TIMES_MEDIA_DONE=0
  PGM_PENDING_OUTPUT_TIMES_FS_DONE=0
}

# Before merge: if planned name / first-chapter FS / first-chapter media disagree,
# ask which date to apply after the merge. Return 2 on quit.
pgm_decide_output_times() {
  local planned_output="$1" source_file="${2:-}"
  local name_e="" src_e="" media_e=""
  local -a labels=() epochs=() notes=()
  local i n def=1 oldest_i=0 oldest_e="" choice keys="" disp note
  local abs_diff need_ask=0

  pgm_clear_pending_output_times

  name_e="$(pgm_filename_epoch_from_basename "${planned_output##*/}" 2>/dev/null || true)"
  if [[ -z "$name_e" && -n "$source_file" ]]; then
    name_e="$(pgm_filename_epoch_from_basename "${source_file##*/}" 2>/dev/null || true)"
  fi
  [[ -n "$source_file" && -f "$source_file" ]] \
    && src_e="$(pgm_fs_mtime_epoch "$source_file" 2>/dev/null || true)"
  [[ -n "$source_file" && -f "$source_file" ]] \
    && media_e="$(pgm_media_createdate_epoch "$source_file" 2>/dev/null || true)"

  # Need a usable file-name stamp to bother comparing.
  if [[ -z "$name_e" ]]; then
    PGM_PENDING_OUTPUT_TIMES_MODE=none
    return 0
  fi

  if [[ -n "$src_e" ]]; then
    if (( name_e > src_e )); then abs_diff=$((name_e - src_e)); else abs_diff=$((src_e - name_e)); fi
    (( abs_diff > 120 )) && need_ask=1
  else
    need_ask=1
  fi
  if [[ -n "$media_e" ]]; then
    if (( name_e > media_e )); then abs_diff=$((name_e - media_e)); else abs_diff=$((media_e - name_e)); fi
    (( abs_diff > 120 )) && need_ask=1
  else
    # Missing CreateDate is worth fixing when a name stamp exists.
    need_ask=1
  fi
  if (( ! need_ask )); then
    PGM_PENDING_OUTPUT_TIMES_MODE=none
    return 0
  fi

  labels+=("File name")
  epochs+=("$name_e")
  notes+=("(planned output name)")
  labels+=("Filesystem")
  epochs+=("$src_e")
  if [[ -n "$src_e" ]]; then
    notes+=("(mtime / first chapter)")
  else
    notes+=("(mtime missing or before 1990)")
  fi
  labels+=("Media tags")
  epochs+=("$media_e")
  if [[ -n "$media_e" ]]; then
    notes+=("(CreateDate in first chapter)")
  else
    notes+=("(CreateDate missing or before 1990)")
  fi
  labels+=("Keep as written")
  epochs+=("")
  notes+=("(leave merge/metadata result; do not force a date)")

  n=${#labels[@]}
  oldest_e=""
  oldest_i=0
  for (( i = 0; i < n; i++ )); do
    [[ -n "${epochs[i]}" ]] || continue
    if [[ -z "$oldest_e" ]] || (( epochs[i] < oldest_e )); then
      oldest_e="${epochs[i]}"
      oldest_i=$i
    fi
  done
  def=$((oldest_i + 1))

  if (( DO_YES )) || (( ! script_is_run_interactively )); then
    if [[ -n "$oldest_e" ]]; then
      PGM_PENDING_OUTPUT_TIMES_MODE=epoch
      PGM_PENDING_OUTPUT_TIMES_EPOCH="$oldest_e"
      PGM_PENDING_OUTPUT_TIMES_LABEL="oldest usable"
      echo "$(pgm_ts) Output times after merge: $(pgm_format_epoch_display "$oldest_e") (oldest usable; no prompt)."
    else
      PGM_PENDING_OUTPUT_TIMES_MODE=none
    fi
    return 0
  fi

  echo
  echo "$(pgm_ts) Output times do not match the planned file name."
  echo "$(pgm_ts) Choose now — this is applied after the merge (no second question)."
  echo
  printf '  Planned:  %s\n' "${planned_output##*/}"
  echo
  echo "  Sources (oldest usable is the default; applying it sets media CreateDate and filesystem times):"
  echo
  keys=""
  for (( i = 0; i < n; i++ )); do
    note="${notes[i]}"
    if [[ -n "${epochs[i]}" ]]; then
      disp="$(pgm_format_epoch_display "${epochs[i]}")"
    else
      disp="n/a"
    fi
    if (( i + 1 == def )); then
      if [[ -n "$note" ]]; then
        note="${note} (oldest - default)"
      else
        note="(oldest - default)"
      fi
    fi
    # ASCII-only date column so %-19s matches terminal columns (UTF-8 "—" broke alignment).
    printf '  [%d] %-18s %-19s  %s\n' \
      "$((i + 1))" "${labels[i]}" "$disp" "$note"
    keys+="$((i + 1))"
    (( i + 1 < n )) && keys+="/"
  done
  echo "  [q] Quit"
  keys+="/q"
  while true; do
    pgm_read_key "Output times [${keys}] (default ${def}): " "$def"
    choice="${REPLY,,}"
    case "$choice" in
      q) pgm_clear_pending_output_times; return 2 ;;
    esac
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= n )); then
      i=$((choice - 1))
      if (( i == n - 1 )); then
        PGM_PENDING_OUTPUT_TIMES_MODE=keep
        PGM_PENDING_OUTPUT_TIMES_LABEL="keep as written"
        echo "$(pgm_ts) Will leave output times as written after merge."
        return 0
      fi
      if [[ -z "${epochs[i]}" ]]; then
        echo "$(pgm_ts) ${labels[i]} is n/a (not usable). Pick another."
        continue
      fi
      PGM_PENDING_OUTPUT_TIMES_MODE=epoch
      PGM_PENDING_OUTPUT_TIMES_EPOCH="${epochs[i]}"
      PGM_PENDING_OUTPUT_TIMES_LABEL="${labels[i]}"
      echo "$(pgm_ts) Will set output times from ${labels[i]} after merge: $(pgm_format_epoch_display "${epochs[i]}")"
      return 0
    fi
    echo "$(pgm_ts) Unknown choice: ${REPLY}."
  done
}

# After post-merge metadata: finish any pending date choice not already applied.
pgm_finish_pending_output_times() {
  local dest="$1"
  local mode="${PGM_PENDING_OUTPUT_TIMES_MODE:-}"

  [[ -f "$dest" ]] || {
    pgm_clear_pending_output_times
    return 0
  }

  case "$mode" in
    none|'')
      pgm_clear_pending_output_times
      return 0
      ;;
    keep)
      echo "$(pgm_ts) Output times kept as written (chosen before merge)."
      pgm_clear_pending_output_times
      return 0
      ;;
    epoch)
      if (( ${PGM_PENDING_OUTPUT_TIMES_MEDIA_DONE:-0} )) \
        && (( ${PGM_PENDING_OUTPUT_TIMES_FS_DONE:-0} )); then
        echo "$(pgm_ts) Output times applied: $(pgm_format_epoch_display "$PGM_PENDING_OUTPUT_TIMES_EPOCH") (${PGM_PENDING_OUTPUT_TIMES_LABEL})."
        pgm_clear_pending_output_times
        return 0
      fi
      # Metadata pass missed media and/or FS — finish with a dedicated apply.
      echo "$(pgm_ts) Applying output times chosen before merge …"
      pgm_apply_epoch_to_output "$dest" "$PGM_PENDING_OUTPUT_TIMES_EPOCH"
      echo "$(pgm_ts) Output times set from ${PGM_PENDING_OUTPUT_TIMES_LABEL}: $(pgm_format_epoch_display "$PGM_PENDING_OUTPUT_TIMES_EPOCH")"
      pgm_clear_pending_output_times
      return 0
      ;;
  esac
  pgm_clear_pending_output_times
  return 0
}

group_is_size_split() {
  local -a files=("$@")
  local f base all_part=1
  (( ${#files[@]} >= 2 )) || return 1
  for f in "${files[@]}"; do
    base="${f##*/}"
    chapter_part_from_basename "$base" >/dev/null 2>&1 || all_part=0
    gopro_timestamp_cam_from_basename "$base" || return 1
  done
  # Named _part_XX runs are part-chapter groups (even when they also look ~4 GB).
  (( all_part )) && return 1
  # Letter a,b,c… on one start time is enough (any size); else require ~4 GB / ~12 GB chapters.
  gopro_letter_chapter_run_ok "${files[@]}" && return 0
  size_split_run_valid "${files[@]}"
}

# Flush a letter-chapter run into dest arrays: multi-file merge blob, else singles back to kept.
letter_chapter_flush_run() {
  local -n _kept_ref=$1
  local -n _new_ref=$2
  shift 2
  local -a run=("$@")
  local rf
  if (( ${#run[@]} >= 2 )) && gopro_letter_chapter_run_ok "${run[@]}"; then
    _new_ref+=("$(printf '%s\n' "${run[@]}")")
  else
    for rf in "${run[@]}"; do
      _kept_ref+=("$rf")
    done
  fi
}

# Group rename-style chapter letters (…BLACKa/b/c or …HHMMSSa/b/c) without a ~4 GB size check.
# Runs before size-split so small lettered chapters still merge.
build_letter_chapter_groups() {
  local -a kept=() new_groups=() run=() keys_seen=()
  local -A by_key=()
  local blob f base key letter
  local -a files=() key_files=()

  for blob in "${GROUP_BLOBS[@]}"; do
    group_files_to_array "$blob" files
    if (( ${#files[@]} >= 2 )); then
      kept+=("$blob")
      continue
    fi
    f="${files[0]}"
    base="${f##*/}"
    if chapter_part_from_basename "$base" >/dev/null 2>&1 \
      || ! gopro_timestamp_cam_from_basename "$base"; then
      kept+=("$f")
      continue
    fi
    letter="${GOPRO_TS_LETTER,,}"
    if [[ ! "$letter" =~ ^[a-z]$ ]]; then
      kept+=("$f")
      continue
    fi
    key=$(gopro_recording_group_key_from_basename "$base" 2>/dev/null) || {
      kept+=("$f")
      continue
    }
    if [[ -z "${by_key[$key]+x}" ]]; then
      by_key["$key"]="$f"
      keys_seen+=("$key")
    else
      by_key["$key"]+=$'\n'"$f"
    fi
  done

  for key in "${keys_seen[@]}"; do
    key_files=()
    mapfile -t key_files <<< "${by_key[$key]}"
    if ((${#key_files[@]})) && [[ -z "${key_files[-1]}" ]]; then
      unset 'key_files[-1]'
    fi
    mapfile -t key_files < <(
      for f in "${key_files[@]}"; do
        printf '%s\t%s\n' "$(gopro_size_split_sort_key "$f")" "$f"
      done | LC_ALL=C sort -t $'\t' -k1,1 | cut -f2-
    )
    run=()
    for f in "${key_files[@]}"; do
      base="${f##*/}"
      gopro_timestamp_cam_from_basename "$base" || {
        letter_chapter_flush_run kept new_groups "${run[@]}"
        run=()
        kept+=("$f")
        continue
      }
      letter="${GOPRO_TS_LETTER,,}"
      if (( ${#run[@]} == 0 )); then
        if [[ "$letter" == a ]]; then
          run=( "$f" )
        else
          kept+=("$f")
        fi
        continue
      fi
      if gopro_letter_chapter_run_ok "${run[@]}" "$f"; then
        run+=( "$f" )
        continue
      fi
      letter_chapter_flush_run kept new_groups "${run[@]}"
      if [[ "$letter" == a ]]; then
        run=( "$f" )
      else
        run=()
        kept+=("$f")
      fi
    done
    letter_chapter_flush_run kept new_groups "${run[@]}"
  done

  GROUP_BLOBS=( "${kept[@]}" "${new_groups[@]}" )
}

# Combine single-file blobs that look like sequential ~4 GB or ~12 GB splits (no _part_XX).
build_size_split_groups() {
  local -a kept=() singles=() run=()
  local blob files f base i n run_len
  local -a new_groups=()
  local warned_ffprobe=0
  local run_tier="" next_tier=""

  for blob in "${GROUP_BLOBS[@]}"; do
    group_files_to_array "$blob" files
    if (( ${#files[@]} >= 2 )); then
      kept+=("$blob")
      continue
    fi
    base="${files[0]##*/}"
    # Orphan single _part_XX (e.g. only part_01 kept the suffix) may still chain with
    # bare-Timelapse / size-split siblings that share camera + session timestamps.
    if ! gopro_timestamp_cam_from_basename "$base"; then
      kept+=("$blob")
      continue
    fi
    singles+=("${files[0]}")
  done

  (( ${#singles[@]} >= 2 )) || {
    GROUP_BLOBS=( "${kept[@]}" )
    return 0
  }

  if ! command -v ffprobe >/dev/null 2>&1; then
    echo "$(pgm_ts) ffprobe not found — size-split uses file size; timestamp chain uses ~5–12 min gaps (~4 GB) or up to ~40 min (~12 GB)." >&2
    warned_ffprobe=1
  fi

  mapfile -t singles < <(
    for f in "${singles[@]}"; do
      e="$(pgm_hybrid_start_epoch "$f" 2>/dev/null)" || e=0
      printf '%020d\t%s\t%s\n' "$e" "$(gopro_size_split_sort_key "$f")" "$f"
    done | LC_ALL=C sort -t $'\t' -k1,1n -k2,2 | cut -f3-
  )
  n=${#singles[@]}
  i=0
  while (( i < n )); do
    pgm_progress_update "Size-split links" "$((i + 1))" "$n" "${singles[i]}"
    if is_full_size_split_segment "${singles[i]}"; then
      run=("${singles[i]}")
      run_tier=$(size_split_tier_for_file "${singles[i]}")
    else
      kept+=("${singles[i]}")
      (( i++ )) || true
      continue
    fi
    local run_cam run_group_key
    run_cam=$(gopro_camera_from_basename "${singles[i]##*/}")
    run_group_key=$(gopro_size_split_session_key_from_basename "${singles[i]##*/}" 2>/dev/null) || run_group_key=""
    (( i++ )) || true
    while (( i < n )); do
      f="${singles[i]}"
      base="${f##*/}"
      pgm_progress_update "Size-split links" "$((i + 1))" "$n" "$f"
      if [[ "$(gopro_camera_from_basename "$base")" != "$run_cam" ]]; then
        break
      fi
      if [[ -n "$run_group_key" ]]; then
        [[ "$(gopro_size_split_session_key_from_basename "$base" 2>/dev/null)" == "$run_group_key" ]] || break
      fi
      if ! size_split_chapter_timestamps_follow "${run[-1]}" "$f"; then
        break
      fi
      if is_full_size_split_segment "$f"; then
        next_tier=$(size_split_tier_for_file "$f") || break
        [[ "$next_tier" == "$run_tier" ]] || break
        run+=("$f")
        (( i++ )) || true
        continue
      fi
      if is_partial_size_split_segment_at_tier "$f" "$run_tier"; then
        run+=("$f")
        (( i++ )) || true
      fi
      break
    done
    if size_split_run_valid "${run[@]}"; then
      new_groups+=("$(printf '%s\n' "${run[@]}")")
    else
      local part_path
      for part_path in "${run[@]}"; do
        kept+=("$part_path")
      done
    fi
  done
  pgm_progress_end

  GROUP_BLOBS=( "${kept[@]}" "${new_groups[@]}" )
  (( warned_ffprobe )) || true
  print_size_split_near_miss_hint
}

# Explain when same-camera ~4GB/~12GB singles were not grouped (after a failed strict check).
print_size_split_near_miss_hint() {
  local -a cand=() files=()
  local blob f base cam sz dur n_full=0
  local first_cam="" first_fail="" first_dur=""
  for blob in "${GROUP_BLOBS[@]}"; do
    group_files_to_array "$blob" files
    (( ${#files[@]} == 1 )) || continue
    f="${files[0]}"
    base="${f##*/}"
    gopro_timestamp_cam_from_basename "$base" || continue
    sz=$(file_size_bytes "$f")
    if [[ -z "$first_cam" ]]; then
      first_cam="$GOPRO_TS_CAM"
    fi
    [[ "$GOPRO_TS_CAM" == "$first_cam" ]] || continue
    cand+=("$f")
    if size_split_tier_for_bytes "$sz" >/dev/null; then
      (( n_full++ )) || true
      if [[ -z "$first_fail" ]] && ! is_full_size_split_segment "$f"; then
        first_fail="${base}"
        first_dur=$(ffprobe_duration_seconds "$f" 2>/dev/null) || first_dur="?"
      fi
    fi
  done
  (( ${#cand[@]} >= 2 && n_full >= 2 )) || return 0
  for blob in "${GROUP_BLOBS[@]}"; do
    group_files_to_array "$blob" files
    (( ${#files[@]} >= 2 )) && group_is_size_split "${files[@]}" && return 0
  done
  echo "$(pgm_ts) Note: ${#cand[@]} same-camera clips look like size-splits but were not grouped."
  if [[ -n "$first_fail" ]]; then
    if [[ "$first_cam" == *GOPRO* ]]; then
      echo "$(pgm_ts)       Example: ${first_fail} duration ${first_dur}s (GoPro ~4 GB: ~6:49, ${PGM_GOPRO7_DURATION_MIN_SEC}-${PGM_GOPRO7_DURATION_MAX_SEC}s)."
    else
      echo "$(pgm_ts)       Example: ${first_fail} duration ${first_dur}s (full ~4 GB chapter: duration not below ${PGM_SIZE_SPLIT_DURATION_REJECT_BELOW_SEC}s; ~12 GB: not below ${PGM_SIZE_SPLIT_12G_DURATION_REJECT_BELOW_SEC}s)."
    fi
  fi
}

# Raw GoPro camera chapter name (HERO6+ / MAX): G[HX] + 2-digit chapter + 4-digit
# recording number, optional _Proxy. Sets RAW_GP_PREFIX / RAW_GP_CHAPTER /
# RAW_GP_NUMBER / RAW_GP_PROXY. e.g. GX010393.MP4 -> GX 01 0393 ; GX020393_Proxy.MP4.
gopro_raw_chapter_parse() {
  local base="$1"
  RAW_GP_PREFIX="" RAW_GP_CHAPTER="" RAW_GP_NUMBER="" RAW_GP_PROXY=""
  if [[ "$base" =~ ^(G[HX])([0-9]{2})([0-9]{4})(_Proxy)?\.[mM][pP]4$ ]]; then
    RAW_GP_PREFIX="${BASH_REMATCH[1]}"
    RAW_GP_CHAPTER="${BASH_REMATCH[2]}"
    RAW_GP_NUMBER="${BASH_REMATCH[3]}"
    RAW_GP_PROXY="${BASH_REMATCH[4]}"
    return 0
  fi
  return 1
}

# Group key for a raw GoPro chapter file: prefix + recording number + variant (orig vs proxy).
# Chapters of one recording share this key; originals and proxies get different keys.
gopro_raw_group_key() {
  gopro_raw_chapter_parse "$1" || return 1
  printf '%s_%s%s\n' "$RAW_GP_PREFIX" "$RAW_GP_NUMBER" "$RAW_GP_PROXY"
}

# True if every file is a raw GoPro chapter sharing the same group key.
group_is_raw_gopro() {
  local -a files=("$@")
  local f base key first_key=
  (( ${#files[@]} >= 1 )) || return 1
  for f in "${files[@]}"; do
    base="${f##*/}"
    key=$(gopro_raw_group_key "$base") || return 1
    if [[ -z "$first_key" ]]; then
      first_key="$key"
    elif [[ "$key" != "$first_key" ]]; then
      return 1
    fi
  done
  return 0
}

# Output name for a raw GoPro chapter group: e.g. GX0393_concat_parts_01-04.mp4
# (proxies: GX0393_Proxy_concat_parts_01-04.mp4).
raw_gopro_group_output_file() {
  local -a files=("$@")
  local f base prefix="" num="" proxy="" min="" max="" ch
  for f in "${files[@]}"; do
    base="${f##*/}"
    gopro_raw_chapter_parse "$base" || return 1
    prefix="$RAW_GP_PREFIX"
    num="$RAW_GP_NUMBER"
    proxy="$RAW_GP_PROXY"
    ch=$((10#$RAW_GP_CHAPTER))
    if [[ -z "$min" ]] || (( ch < min )); then min=$ch; fi
    if [[ -z "$max" ]] || (( ch > max )); then max=$ch; fi
  done
  printf '%s%s%s_concat_parts_%02d-%02d.mp4\n' "$prefix" "$num" "$proxy" "$min" "$max"
}

# Pull raw GoPro chapter files (GXccnnnn[_Proxy].MP4) out of the sorted list into
# key-based groups (one per recording+variant, ordered by chapter). Remaining files
# are returned via the nameref _rest for the legacy sequential/size-split logic.
build_raw_gopro_groups() {
  local -n _rest=$1
  shift
  local -a sorted=("$@")
  local f base key
  local -a keys_seen=()
  local -A group_map=()
  _rest=()
  for f in "${sorted[@]}"; do
    base="${f##*/}"
    if is_concat_output_basename "$base"; then
      _rest+=("$f")
      continue
    fi
    if gopro_raw_chapter_parse "$base"; then
      key="${RAW_GP_PREFIX}_${RAW_GP_NUMBER}${RAW_GP_PROXY}"
      if [[ -z "${group_map[$key]+x}" ]]; then
        group_map["$key"]="$f"
        keys_seen+=("$key")
      else
        group_map["$key"]+=$'\n'"$f"
      fi
    else
      _rest+=("$f")
    fi
  done
  # Input was LC_ALL=C sorted; within one key only the 2 chapter digits vary, so
  # the entries are already in ascending chapter order.
  local k
  for k in "${keys_seen[@]}"; do
    GROUP_BLOBS+=("${group_map[$k]}")
  done
}

# Parse an already-renamed chapter name: <stem>_part_NN[_Proxy].<ext>.
# Sets PART_STEM / PART_NUM / PART_PROXY / PART_EXT. Returns 0 on match.
part_chapter_parse() {
  local base="$1"
  PART_STEM="" PART_NUM="" PART_PROXY="" PART_EXT=""
  if [[ "$base" =~ ^(.*)_part_([0-9]{2})(_Proxy)?\.([mM][pP]4)$ ]]; then
    PART_STEM="${BASH_REMATCH[1]}"
    PART_NUM="${BASH_REMATCH[2]}"
    PART_PROXY="${BASH_REMATCH[3]}"
    PART_EXT="${BASH_REMATCH[4]}"
    return 0
  fi
  return 1
}

# Virtual basename without _part_NN (and without _Timewarp_/_Timelapse_) for GoPro parsing.
part_chapter_gopro_parse_base() {
  local base="$1"
  part_chapter_parse "$base" || return 1
  printf '%s.%s\n' "$(gopro_stem_without_capture_mode "$PART_STEM")" "$PART_EXT"
}

# Group key: same calendar day + camera + middle + capture mode + proxy.
# Leading HHMMSS may differ per part (rename.sh chapters). The day must be in the
# key: a multi-day folder (e.g. 20210226 + 20210228) otherwise put every
# GoPro_Hero7_Black_part_XX in one bucket, sort by part number only, and pair
# day-B part_01 with day-A part_02 — splitting a real same-day 01…24 run.
part_chapter_group_key_from_basename() {
  local base="$1" parse_base cam mid capture_mode="" day=""
  part_chapter_parse "$base" || return 1
  capture_mode="$(gopro_capture_mode_token_from_stem "$PART_STEM" 2>/dev/null)" || capture_mode=""
  parse_base="$(gopro_stem_without_capture_mode "$PART_STEM").${PART_EXT}"
  if gopro_timestamp_cam_from_basename "$parse_base"; then
    day="$GOPRO_TS_DATE"
    mid=$(gopro_middle_from_basename "$parse_base" 2>/dev/null) || mid=""
    printf '%s|%s|%s|%s%s\n' "$day" "$GOPRO_TS_CAM" "$mid" "$capture_mode" "${PART_PROXY}"
    return 0
  fi
  if cam=$(chapter_camera_from_basename "$base" 2>/dev/null); then
    printf '%s|%s|%s|%s%s\n' "" "$cam" "" "$capture_mode" "${PART_PROXY}"
    return 0
  fi
  printf '%s|%s|%s%s\n' "" "$(gopro_stem_without_capture_mode "$PART_STEM")" "$capture_mode" "${PART_PROXY}"
}

# True when next clip follows prev: hybrid start times (name / CreateDate) plus
# ffprobe duration, or timelapse / wall-clock gap.
part_chapter_timestamps_follow() {
  local prev_f="$1" next_f="$2"
  local prev_epoch next_epoch dur expected delta tol gap same_tol
  prev_epoch="$(pgm_hybrid_start_epoch "$prev_f" 2>/dev/null)" || return 1
  next_epoch="$(pgm_hybrid_start_epoch "$next_f" 2>/dev/null)" || return 1

  same_tol=2
  if (( prev_epoch == next_epoch )); then
    return 0
  fi
  delta=$(( next_epoch - prev_epoch ))
  if (( delta >= -same_tol && delta <= same_tol )); then
    return 0
  fi
  (( next_epoch >= prev_epoch )) || return 1

  tol="${PGM_PART_CHAPTER_TIME_TOLERANCE_SEC:-180}"
  [[ "$tol" =~ ^[0-9]+$ ]] || tol=180
  dur=$(ffprobe_duration_seconds "$prev_f" 2>/dev/null) || dur=""

  if [[ -n "$dur" ]]; then
    expected=$(awk -v p="$prev_epoch" -v d="$dur" 'BEGIN{printf "%d", p+d+0.5}')
    delta=$(( next_epoch - expected ))
    if (( delta >= -tol && delta <= tol )); then
      return 0
    fi
  fi
  gap=$(( next_epoch - prev_epoch ))
  part_chapter_timelapse_wall_clock_ok "$prev_f" "$gap" "$dur" && return 0
  part_chapter_realtime_wall_clock_gap_ok "$prev_f" "$gap"
}

# True when cur_part follows prev_part in a run (hybrid start + duration / gap).
part_chapter_consecutive_link_ok() {
  local prev_f="$1" next_f="$2"
  # $3 was run_first_part (unused; kept so callers can still pass it).
  part_chapter_timestamps_follow "$prev_f" "$next_f"
}

# Lowest _part_XX number in a run (after numeric sort).
part_chapter_first_part_number() {
  local -a sorted=()
  part_chapter_sorted_files sorted "$@"
  (( ${#sorted[@]} > 0 )) || return 1
  chapter_part_from_basename "${sorted[0]##*/}"
}

# True when every file is _part_XX and the run is mergeable.
# Runs from part_01 are trusted rename.sh chapters (any size). Later orphan tails
# (e.g. part_04–06 left after parts 01–03 merged) still need size-split rules.
part_chapter_run_valid() {
  local -a files=("$@")
  local f first_part
  (( ${#files[@]} >= 2 )) || return 1
  for f in "${files[@]}"; do
    part_chapter_parse "${f##*/}" || return 1
  done
  first_part=$(part_chapter_first_part_number "${files[@]}") || return 1
  (( first_part == 1 )) && return 0
  size_split_run_valid "${files[@]}"
}

# Sort _part_XX by hybrid start epoch, then part number.
part_chapter_sorted_files() {
  local -n _out=$1
  shift
  local -a files=("$@")
  local f p base e
  mapfile -t _out < <(
    for f in "${files[@]}"; do
      base="${f##*/}"
      p=$(chapter_part_from_basename "$base") || continue
      e="$(pgm_hybrid_start_epoch "$f" 2>/dev/null)" || e=0
      printf '%020d\t%02d\t%s\n' "$e" "$p" "$f"
    done | LC_ALL=C sort -t $'\t' -k1,1n -k2,2n | cut -f3-
  )
}

part_chapter_append_run_to_groups_or_rest() {
  local _rest_name=$1
  shift
  local -n rest_arr=$_rest_name
  local -a run=("$@")
  local f blob first_part skip_reason

  if (( ${#run[@]} < 2 )); then
    rest_arr+=( "${run[@]}" )
    return 0
  fi
  if part_chapter_run_valid "${run[@]}"; then
    blob=$(printf '%s\n' "${run[@]}")
    GROUP_BLOBS+=( "$blob" )
    return 0
  fi
  first_part=$(part_chapter_first_part_number "${run[@]}") || first_part=0
  if (( first_part > 1 )); then
    skip_reason="orphan tail from part_$(printf '%02d' "$first_part") and not full ~4 GB / ~12 GB chapters"
  else
    skip_reason="not full ~4 GB / ~12 GB chapters"
  fi
  pgm_progress_end
  echo "$(pgm_ts) Skipping _part_XX merge (${#run[@]} consecutive parts):"
  echo "$(pgm_ts)   Reason: ${skip_reason}"
  for f in "${run[@]}"; do
    echo "$(pgm_ts)     ${f##*/}"
  done
  rest_arr+=( "${run[@]}" )
}

# Optional globals for cross-key progress: PGM_PART_LINK_PROG_I / PGM_PART_LINK_PROG_N
part_chapter_split_key_into_runs() {
  local _rest_name=$1
  shift
  local -a key_files=("$@")
  local -a sorted=() run=()
  local f cur_part prev_part run_first_part
  local prog_n="${PGM_PART_LINK_PROG_N:-0}"

  part_chapter_sorted_files sorted "${key_files[@]}"
  (( ${#sorted[@]} > 0 )) || return 0
  if (( prog_n < 1 )); then
    prog_n=${#sorted[@]}
  fi

  run=()
  prev_part=""
  run_first_part=""
  for f in "${sorted[@]}"; do
    PGM_PART_LINK_PROG_I=$(( ${PGM_PART_LINK_PROG_I:-0} + 1 ))
    pgm_progress_update "Part links" "$PGM_PART_LINK_PROG_I" "$prog_n" "$f"
    cur_part=$(chapter_part_from_basename "${f##*/}") || continue
    if (( ${#run[@]} == 0 )); then
      run=( "$f" )
      run_first_part=$cur_part
      prev_part=$cur_part
      continue
    fi
    if (( cur_part == prev_part + 1 )) \
      && part_chapter_consecutive_link_ok "${run[-1]}" "$f" "$run_first_part"; then
      run+=( "$f" )
      prev_part=$cur_part
    else
      part_chapter_append_run_to_groups_or_rest "$_rest_name" "${run[@]}"
      run=( "$f" )
      run_first_part=$cur_part
      prev_part=$cur_part
    fi
  done
  (( ${#run[@]} > 0 )) && part_chapter_append_run_to_groups_or_rest "$_rest_name" "${run[@]}"
}

# Pull _part_NN chapter files out of the list into key-based groups. The key is
# calendar day + camera + middle label + proxy variant (or full stem when not
# GoPro-shaped), so originals (_part_NN) and proxies (_part_NN_Proxy) go into
# separate groups and are NEVER mixed, and two days in one folder do not share a
# part-number sequence. Within each key, consecutive part numbers are kept together
# only when filename times chain (start + duration, or wall-clock / timelapse gap).
# Orphan tails (first part > 01) also need ~4 GB / ~12 GB full segments.
# return via the array named in $1 (e.g. rest2 from build_chapter_groups).
build_part_chapter_groups() {
  local _rest_name=$1
  shift
  local -n rest_arr=$_rest_name
  local -a sorted=("$@")
  local f base key
  local -a keys_seen=() key_files=()
  local -A group_map=()
  local k part_total=0
  rest_arr=()
  for f in "${sorted[@]}"; do
    base="${f##*/}"
    if is_concat_output_basename "$base"; then
      rest_arr+=( "$f" )
      continue
    fi
    if part_chapter_parse "$base"; then
      key=$(part_chapter_group_key_from_basename "$base") || {
        rest_arr+=( "$f" )
        continue
      }
      if [[ -z "${group_map[$key]+x}" ]]; then
        group_map["$key"]="$f"
        keys_seen+=( "$key" )
      else
        group_map["$key"]+=$'\n'"$f"
      fi
    else
      rest_arr+=( "$f" )
    fi
  done
  for k in "${keys_seen[@]}"; do
    key_files=()
    mapfile -t key_files <<< "${group_map[$k]}"
    if ((${#key_files[@]})) && [[ -z "${key_files[-1]}" ]]; then
      unset 'key_files[-1]'
    fi
    part_total=$(( part_total + ${#key_files[@]} ))
  done
  PGM_PART_LINK_PROG_I=0
  PGM_PART_LINK_PROG_N=$part_total
  for k in "${keys_seen[@]}"; do
    key_files=()
    mapfile -t key_files <<< "${group_map[$k]}"
    if ((${#key_files[@]})) && [[ -z "${key_files[-1]}" ]]; then
      unset 'key_files[-1]'
    fi
    part_chapter_split_key_into_runs "$_rest_name" "${key_files[@]}"
  done
  pgm_progress_end
  unset PGM_PART_LINK_PROG_I PGM_PART_LINK_PROG_N
}

# 70mai dashcam: NO20260926-110627-000678F.MP4 or EV20260814-190447-006784B.MP4
# → kind, date, start time, sequence, camera letter. EV is an event clip in the same run.
dashcam_parse_basename() {
  local base="$1"
  DASHCAM_KIND=""
  DASHCAM_DATE=""
  DASHCAM_TIME=""
  DASHCAM_SEQ=""
  DASHCAM_CAM=""
  if [[ "$base" =~ ^(NO|EV)([0-9]{8})-([0-9]{6})-([0-9]{6})([A-Za-z])\.[mM][pP]4$ ]]; then
    DASHCAM_KIND="${BASH_REMATCH[1]}"
    DASHCAM_DATE="${BASH_REMATCH[2]}"
    DASHCAM_TIME="${BASH_REMATCH[3]}"
    DASHCAM_SEQ=$((10#${BASH_REMATCH[4]}))
    DASHCAM_CAM=$(printf '%s' "${BASH_REMATCH[5]}" | tr '[:lower:]' '[:upper:]')
    return 0
  fi
  return 1
}

# True when every file is a 70mai NO* or EV* clip from the same camera letter.
group_is_dashcam() {
  local -a files=("$@")
  local f cam=""
  (( ${#files[@]} >= 2 )) || return 1
  for f in "${files[@]}"; do
    dashcam_parse_basename "${f##*/}" || return 1
    if [[ -z "$cam" ]]; then
      cam="$DASHCAM_CAM"
    elif [[ "$cam" != "$DASHCAM_CAM" ]]; then
      return 1
    fi
  done
  return 0
}

# Merged MP4 path → GPX path (same stem, .gpx), written beside the merged file.
dashcam_gpx_beside_output() {
  local output_file="$1"
  printf '%s.gpx\n' "${output_file%.*}"
}

# Filename token for the dashcam. Default is the 70mai A510. Override with PGM_DASHCAM_LABEL.
dashcam_label() {
  local label="${PGM_DASHCAM_LABEL:-70mai-A510}"
  label=$(printf '%s' "$label" | tr ' ' '-' | tr -cd 'A-Za-z0-9._-')
  [[ -n "$label" ]] || label="70mai-A510"
  printf '%s\n' "$label"
}

# Filename token for the camera letter on a 70mai clip. F and B are the usual pair.
dashcam_camera_place() {
  local letter="$1"
  case "$letter" in
    F) printf '%s\n' FrontCam ;;
    B) printf '%s\n' BackCam ;;
    *) printf '%s\n' "$letter" ;;
  esac
}

# 20260926_110627-20260926_130427_-_-_70mai-A510_FrontCam_concat.mp4
dashcam_group_output_file() {
  local -a files=("$@")
  local start_date start_time end_date end_time cam label place
  group_is_dashcam "${files[@]}" || return 1
  dashcam_parse_basename "${files[0]##*/}" || return 1
  start_date="$DASHCAM_DATE"
  start_time="$DASHCAM_TIME"
  cam="$DASHCAM_CAM"
  dashcam_parse_basename "${files[-1]##*/}" || return 1
  end_date="$DASHCAM_DATE"
  end_time="$DASHCAM_TIME"
  label=$(dashcam_label)
  place=$(dashcam_camera_place "$cam")
  printf '%s_%s-%s_%s_-_-_%s_%s_concat.mp4\n' \
    "$start_date" "$start_time" "$end_date" "$end_time" "$label" "$place"
}

# Same journey written by an older script: date-time_date-time_label_camera_concat.mp4.
dashcam_group_output_file_legacy() {
  local -a files=("$@")
  local start_date start_time end_date end_time cam label place
  group_is_dashcam "${files[@]}" || return 1
  dashcam_parse_basename "${files[0]##*/}" || return 1
  start_date="$DASHCAM_DATE"
  start_time="$DASHCAM_TIME"
  cam="$DASHCAM_CAM"
  dashcam_parse_basename "${files[-1]##*/}" || return 1
  end_date="$DASHCAM_DATE"
  end_time="$DASHCAM_TIME"
  label=$(dashcam_label)
  place=$(dashcam_camera_place "$cam")
  printf '%s-%s_%s-%s_%s_%s_concat.mp4\n' \
    "$start_date" "$start_time" "$end_date" "$end_time" "$label" "$place"
}

# New name when nothing is saved yet. An existing new or older file for this journey is kept.
dashcam_resolved_output_file() {
  local new_name legacy f base saved=""
  local start_key end_key letter nullglob_was=0
  new_name=$(dashcam_group_output_file "$@") || return 1
  if [[ -e "$new_name" ]]; then
    printf '%s\n' "$new_name"
    return 0
  fi
  legacy=$(dashcam_group_output_file_legacy "$@") || legacy=""
  if [[ -n "$legacy" && -e "$legacy" ]]; then
    printf '%s\n' "$legacy"
    return 0
  fi
  concat_parse_dashcam_output "$new_name" || {
    printf '%s\n' "$new_name"
    return 0
  }
  start_key="$CONCAT_DASH_START"
  end_key="$CONCAT_DASH_END"
  letter="$CONCAT_DASH_LETTER"
  shopt -q nullglob && nullglob_was=1
  shopt -s nullglob
  for f in ./*; do
    base="${f##*/}"
    [[ "$base" == "$new_name" ]] && continue
    concat_parse_dashcam_output "$base" || continue
    [[ "$CONCAT_DASH_START" == "$start_key" && "$CONCAT_DASH_END" == "$end_key" && "$CONCAT_DASH_LETTER" == "$letter" ]] || continue
    saved="$base"
    break
  done
  if (( nullglob_was )); then
    shopt -s nullglob
  else
    shopt -u nullglob
  fi
  if [[ -n "$saved" ]]; then
    printf '%s\n' "$saved"
  else
    printf '%s\n' "$new_name"
  fi
}

# A Windows path P:\video\gps is /mnt/p/video/gps when that drive is mounted.
pgm_unix_path() {
  local p="$1" re='^([A-Za-z]):[\\/](.*)$' drive rest
  if [[ "$p" =~ $re ]]; then
    drive="${BASH_REMATCH[1],,}"
    rest="${BASH_REMATCH[2]//\\//}"
    if [[ -d "/mnt/${drive}" ]]; then
      printf '/mnt/%s/%s\n' "$drive" "$rest"
      return 0
    fi
  fi
  printf '%s\n' "$p"
}

# Absolute path for an existing file (Windows drive letters via pgm_unix_path).
pgm_abs_path() {
  local p="$1" d b
  p="$(pgm_unix_path "$p")"
  [[ -e "$p" ]] || return 1
  d="$(cd -- "$(dirname -- "$p")" && pwd -P)" || return 1
  b="$(basename -- "$p")"
  printf '%s/%s\n' "$d" "$b"
}

# Non-concat *.mp4 basenames in dir, sorted with LC_ALL=C (case-insensitive glob).
pgm_list_mp4_basenames_sorted() {
  local dir="$1"
  local f base
  (
    cd -- "$dir" || exit 1
    shopt -s nullglob nocaseglob
    for f in *.mp4; do
      base="${f##*/}"
      is_concat_output_basename "$base" && continue
      printf '%s\n' "$base"
    done
  ) | LC_ALL=C sort -u
}

# Resolve FILE +N: start file plus the next N MP4 names alphabetically in its folder.
pgm_resolve_force_merge_plus_n() {
  local start_arg="$1" plus_arg="$2"
  local n path abs dir start_base need available i idx=-1 ext
  local -a names=() chosen=() out=()

  if [[ ! "$plus_arg" =~ ^\+([1-9][0-9]*)$ ]]; then
    echo "$(pgm_ts) Second argument must be +N with N ≥ 1 (e.g. +1, +2, +7), got: ${plus_arg}" >&2
    return 1
  fi
  n="${BASH_REMATCH[1]}"

  path="$(pgm_unix_path "$start_arg")"
  if [[ ! -e "$path" ]]; then
    echo "$(pgm_ts) Not found: ${start_arg}" >&2
    return 1
  fi
  if [[ ! -f "$path" ]]; then
    echo "$(pgm_ts) Not a regular file: ${start_arg}" >&2
    return 1
  fi
  ext="${path##*.}"
  if [[ "${ext,,}" != mp4 ]]; then
    echo "$(pgm_ts) Not an MP4 file: ${start_arg}" >&2
    return 1
  fi
  abs="$(pgm_abs_path "$path")" || {
    echo "$(pgm_ts) Cannot resolve path: ${start_arg}" >&2
    return 1
  }
  if is_concat_output_basename "${abs##*/}"; then
    echo "$(pgm_ts) Already a concat output (cannot use as a forced-merge input): ${abs##*/}" >&2
    return 1
  fi

  dir="$(dirname -- "$abs")"
  start_base="${abs##*/}"
  mapfile -t names < <(pgm_list_mp4_basenames_sorted "$dir")
  if (( ${#names[@]} == 0 )); then
    echo "$(pgm_ts) No MP4 files found in ${dir}" >&2
    return 1
  fi

  for i in "${!names[@]}"; do
    if [[ "${names[i]}" == "$start_base" ]]; then
      idx=$i
      break
    fi
  done
  if (( idx < 0 )); then
    for i in "${!names[@]}"; do
      if [[ "${names[i],,}" == "${start_base,,}" ]]; then
        idx=$i
        start_base="${names[i]}"
        break
      fi
    done
  fi
  if (( idx < 0 )); then
    echo "$(pgm_ts) Starting file not in the alphabetical MP4 list: ${start_base}" >&2
    return 1
  fi

  need=$((n + 1))
  available=$((${#names[@]} - idx))
  if (( available < need )); then
    echo "$(pgm_ts) Not enough MP4 files after ${start_base}: need +${n} (join ${need} total), only ${available} from that name onward." >&2
    echo "$(pgm_ts) Alphabetical MP4s from ${start_base}:" >&2
    for ((i = idx; i < ${#names[@]}; i++)); do
      printf '  %s\n' "${names[i]}" >&2
    done
    return 1
  fi

  for ((i = idx; i < idx + need; i++)); do
    chosen+=("${names[i]}")
    out+=("${dir}/${names[i]}")
  done

  echo "$(pgm_ts) Forced merge +${n}: join these ${#chosen[@]} files (start at ${start_base}, next ${n} alphabetically):"
  for i in "${!chosen[@]}"; do
    printf '  %2d. %s\n' "$((i + 1))" "${chosen[i]}"
  done
  echo

  FORCE_MERGE_FILES=( "${out[@]}" )
  FORCE_MERGE=1
  FORCE_MERGE_PLUS_N=$n
  return 0
}

# Resolve CLI force-merge operands: existing MP4s, same directory, keep order.
pgm_resolve_force_merge_files() {
  local arg path abs dir0="" ext
  local -a out=()
  (( $# >= 2 )) || {
    echo "$(pgm_ts) Forced merge needs at least two MP4 files." >&2
    return 1
  }
  for arg in "$@"; do
    path="$(pgm_unix_path "$arg")"
    if [[ ! -e "$path" ]]; then
      echo "$(pgm_ts) Not found: ${arg}" >&2
      return 1
    fi
    if [[ ! -f "$path" ]]; then
      echo "$(pgm_ts) Not a regular file: ${arg}" >&2
      return 1
    fi
    ext="${path##*.}"
    if [[ "${ext,,}" != mp4 ]]; then
      echo "$(pgm_ts) Not an MP4 file: ${arg}" >&2
      return 1
    fi
    abs="$(pgm_abs_path "$path")" || {
      echo "$(pgm_ts) Cannot resolve path: ${arg}" >&2
      return 1
    }
    if [[ -z "$dir0" ]]; then
      dir0="$(dirname -- "$abs")"
    elif [[ "$(dirname -- "$abs")" != "$dir0" ]]; then
      echo "$(pgm_ts) Forced merge files must be in the same directory." >&2
      echo "$(pgm_ts)   ${dir0}" >&2
      echo "$(pgm_ts)   $(dirname -- "$abs")" >&2
      return 1
    fi
    if is_concat_output_basename "${abs##*/}"; then
      echo "$(pgm_ts) Already a concat output (cannot use as a forced-merge input): ${abs##*/}" >&2
      return 1
    fi
    out+=("$abs")
  done
  FORCE_MERGE_FILES=( "${out[@]}" )
  FORCE_MERGE=1
  FORCE_MERGE_PLUS_N=0
  return 0
}

# path, label, kind. kind is nearby, given, or conf.
dashcam_gps_place_rows() {
  local rel real seen="" i=0 raw text conf name line in_section
  local -a dirs=(. .. ../..)
  local -a labels=("" "one up" "two up")
  for rel in "${dirs[@]}"; do
    [[ -d "$rel" ]] || break
    real=$(cd -- "$rel" && pwd -P) || break
    if printf '%s\n' "$seen" | grep -Fxq -- "$real"; then
      break
    fi
    seen+=$'\n'"$real"
    printf '%s\t%s\tnearby\n' "$real" "${labels[$i]}"
    i=$(( i + 1 ))
  done
  if (( ${#GPS_DIRS[@]} )); then
    for raw in "${GPS_DIRS[@]}"; do
      text=$(pgm_unix_path "$raw")
      if [[ -d "$text" ]]; then
        real=$(cd -- "$text" && pwd -P) || real="$text"
      else
        real="$text"
      fi
      if printf '%s\n' "$seen" | grep -Fxq -- "$real"; then
        continue
      fi
      seen+=$'\n'"$real"
      printf '%s\tgiven with --gps-dir, and the folders inside it\tgiven\n' "$real"
    done
    return 0
  fi
  local -a confs=()
  for rel in /etc "${HOME:-}" "${HOME:-}/etc" "${HOME:-}/conf" \
      "${profile_location_dir:-}/etc" "${profile_location_dir:-}/conf" "${profile_location_dir:-}"; do
    [[ -n "$rel" && -f "${rel}/video-pgm-geotag-missing-media.conf" ]] || continue
    confs+=("${rel}/video-pgm-geotag-missing-media.conf")
  done
  for conf in "${confs[@]}"; do
    in_section=0
    while IFS= read -r line || [[ -n "$line" ]]; do
      line="${line%%$'\r'}"
      line="${line#"${line%%[![:space:]]*}"}"
      line="${line%"${line##*[![:space:]]}"}"
      [[ -z "$line" || "$line" == \#* ]] && continue
      if [[ "$line" == \[*\] ]]; then
        name="${line#\[}"
        name="${name%\]}"
        name="${name,,}"
        name="${name#"${name%%[![:space:]]*}"}"
        name="${name%"${name##*[![:space:]]}"}"
        if [[ "$name" == "tracks-location" ]]; then
          in_section=1
        else
          in_section=0
        fi
        continue
      fi
      (( in_section )) || continue
      text="${line#\"}"
      text="${text%\"}"
      text="${text#\'}"
      text="${text%\'}"
      text=$(pgm_unix_path "$text")
      if [[ "$text" != /* ]]; then
        text="$(cd -- "$(dirname -- "$conf")" && pwd)/${text}"
      fi
      if [[ -d "$text" ]]; then
        real=$(cd -- "$text" && pwd -P) || real="$text"
      else
        real="$text"
      fi
      if printf '%s\n' "$seen" | grep -Fxq -- "$real"; then
        continue
      fi
      seen+=$'\n'"$real"
      printf '%s\ttracks folder from video-pgm-geotag-missing-media.conf, and the folders inside it\tconf\n' "$real"
    done < "$conf"
  done
}

# Every GPSData*.txt in this directory, one and two levels above, and in each
# GPS directory (that directory and everything inside it). The date in the
# file name does not decide which log is used. Points inside the journey
# window are kept when the GPX is written.
dashcam_gps_logs() {
  local path label kind f found=0
  local -a depth=()
  declare -A seen_dir=()
  while IFS=$'\t' read -r path label kind; do
    [[ -n "$path" && -d "$path" ]] || continue
    [[ -n "${seen_dir[$path]:-}" ]] && continue
    seen_dir[$path]=1
    depth=()
    if [[ "$kind" == nearby ]]; then
      depth=(-maxdepth 1)
    fi
    while IFS= read -r -d '' f; do
      printf '%s\n' "$f"
      found=1
    done < <(find "$path" "${depth[@]}" \( -type d -name '.*' -prune \) -o -type f -iname 'GPSData*.txt' -print0)
  done < <(dashcam_gps_place_rows)
  (( found )) || return 1
  return 0
}

# First GPSData*.txt in the places searched, if any.
# head stops after one name. With pipefail that closed pipe is exit 141, which
# used to print "no GPSData*.txt" whenever more than one log was found.
dashcam_gps_log_hint() {
  local log=""
  log=$(dashcam_gps_logs | head -n 1 || true)
  [[ -n "$log" ]] || return 1
  printf '%s\n' "$log"
}

# No GPS log. Quit unless the user continues, and then no GPX is written.
dashcam_warn_no_gps() {
  local path label kind
  echo
  echo "No GPSData*.txt was found. GPX files will not be created."
  echo
  echo "Looked in:"
  while IFS=$'\t' read -r path label kind; do
    [[ -n "$path" ]] || continue
    if [[ -n "$label" ]]; then
      printf '  %s  (%s)\n' "$path" "$label"
    else
      printf '  %s\n' "$path"
    fi
  done < <(dashcam_gps_place_rows)
  echo
  echo "You can name the directory that holds the GPS logs. That directory and everything inside it will be searched."
  echo
  printf '  %s --gps-dir /mnt/p/video/gps\n' "$(script_live_basename)"
  echo
  echo "  [Q] Quit (default)"
  if (( DO_YES )) || (( ! script_is_run_interactively )); then
    echo "$(pgm_ts) Quit."
    return 1
  fi
  echo "  [c] Continue anyway. Merge the videos, and do not write a GPX"
  while true; do
    pgm_read_key "Quit? [Q/c]: " q
    case "${REPLY,,}" in
      q) echo "$(pgm_ts) Quit."; return 1 ;;
      c) echo "$(pgm_ts) Continue anyway. GPX files will not be created."; return 0 ;;
      *) echo "That is not a choice." ;;
    esac
  done
}

# 0 when $1 is a non-empty GPX track (at least one point).
dashcam_gpx_is_valid() {
  local gpx="$1"
  [[ -s "$gpx" ]] || return 1
  grep -q '<trkpt' -- "$gpx"
}

# 0 when the merged file is enough to treat the group as done.
# A 70mai journey also needs a valid GPX beside the MP4.
group_output_is_complete() {
  local output_file="$1"
  shift
  [[ -e "$output_file" ]] || return 1
  if group_is_dashcam "$@"; then
    dashcam_gpx_is_valid "$(dashcam_gpx_beside_output "$output_file")"
    return
  fi
  return 0
}

print_dashcam_gpx_suggestion() {
  local output_file="$1" indent="${2:-      }"
  local gpx log
  gpx=$(dashcam_gpx_beside_output "$output_file")
  if dashcam_gpx_is_valid "$gpx"; then
    printf '%sGPS: %s (present)\n' "$indent" "$gpx"
  elif [[ -e "$gpx" ]]; then
    printf '%sGPS: %s (not a valid track)\n' "$indent" "$gpx"
  elif [[ -e "$output_file" ]]; then
    printf '%sGPS: %s (missing)\n' "$indent" "$gpx"
  else
    printf '%sGPS: %s will be written beside the merged file (same name, .gpx)\n' \
      "$indent" "$gpx"
  fi
  if log=$(dashcam_gps_log_hint 2>/dev/null) && [[ -n "$log" ]]; then
    printf '%sGPS log: %s\n' "$indent" "$log"
  else
    printf '%sGPS log: no GPSData*.txt in the places searched\n' "$indent"
  fi
}

# Clock fields → Unix time in the machine's local timezone (same reading as date -d).
# tz_corr = local epoch of a civil time minus that civil time read as UTC.
dashcam_local_epoch_tz_corr() {
  local local_noon utc_noon
  local_noon=$(date -d "2026-09-26 12:00:00" +%s) || return 1
  utc_noon=$(date -u -d "2026-09-26 12:00:00" +%s) || return 1
  printf '%s\n' "$(( local_noon - utc_noon ))"
}

# A hole of this many seconds between a clip's real length and the next filename
# is a short clip. A last file that is simply shorter than a minute is not.
PGM_DASHCAM_SHORT_HOLE_SEC="${PGM_DASHCAM_SHORT_HOLE_SEC:-8}"
# GPS points this far apart (UTC) start a new <trkseg> so a hole is a gap, not a line.
PGM_DASHCAM_GPX_SEG_GAP_SEC="${PGM_DASHCAM_GPX_SEG_GAP_SEC:-8}"

dashcam_hhmmss_display() {
  local t="$1"
  printf '%s:%s:%s' "${t:0:2}" "${t:2:2}" "${t:4:2}"
}

# HH:MM:SS plus whole seconds. This is where a short clip ends and the picture jumps.
dashcam_clock_plus() {
  awk -v t="$1" -v a="$2" 'BEGIN {
    n = split(t, p, ":")
    if (n != 3) { printf "%s", t; exit }
    s = p[1] * 3600 + p[2] * 60 + p[3] + a
    s = int(s) % 86400
    if (s < 0) s += 86400
    printf "%02d:%02d:%02d", int(s / 3600), int((s % 3600) / 60), s % 60
  }'
}

# One line per clip whose video is clearly shorter than the gap to the next file:
# path, basename, start HH:MM:SS, duration seconds, next HH:MM:SS, gap seconds, hole seconds.
dashcam_short_clip_rows() {
  local -a files=("$@")
  local i f next_f dur gap hole this_epoch next_epoch this_time next_time hole_min this_date
  hole_min="${PGM_DASHCAM_SHORT_HOLE_SEC:-8}"
  [[ "$hole_min" =~ ^[0-9]+$ ]] || hole_min=8
  (( ${#files[@]} >= 2 )) || return 0
  for (( i = 0; i < ${#files[@]} - 1; i++ )); do
    f="${files[$i]}"
    next_f="${files[$((i + 1))]}"
    dashcam_parse_basename "${f##*/}" || continue
    this_date=$DASHCAM_DATE
    this_time=$DASHCAM_TIME
    this_epoch=$(gopro_datetime_to_epoch "$this_date" "$this_time" 2>/dev/null) || continue
    dashcam_parse_basename "${next_f##*/}" || continue
    next_time=$DASHCAM_TIME
    next_epoch=$(gopro_datetime_to_epoch "$DASHCAM_DATE" "$DASHCAM_TIME" 2>/dev/null) || continue
    gap=$(( next_epoch - this_epoch ))
    (( gap > 0 )) || continue
    dur=$(ffprobe_duration_seconds "$f" 2>/dev/null) || continue
    hole=$(awk -v g="$gap" -v d="$dur" 'BEGIN { printf "%d", int(g - d + 0.5) }')
    (( hole >= hole_min )) || continue
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$f" "${f##*/}" "$(dashcam_hhmmss_display "$this_time")" \
      "$(awk -v d="$dur" 'BEGIN { printf "%d", int(d + 0.5) }')" \
      "$(dashcam_hhmmss_display "$next_time")" "$gap" "$hole"
  done
}

dashcam_print_short_clip_notice() {
  local -a files=("$@")
  local n row f base start_disp dur_s next_disp gap hole end_disp
  local -a rows=()
  mapfile -t rows < <(dashcam_short_clip_rows "${files[@]}" || true)
  n=${#rows[@]}
  (( n )) || return 0
  echo
  if (( n == 1 )); then
    echo "  Short clip in this group. The camera recorded less than the gap to the next file."
  else
    echo "  Short clips in this group. The camera recorded less than the gap to the next file."
  fi
  echo
  for row in "${rows[@]}"; do
    IFS=$'\t' read -r f base start_disp dur_s next_disp gap hole <<< "$row"
    end_disp=$(dashcam_clock_plus "$start_disp" "$dur_s")
    printf '    %s\n' "$base"
    printf '    %s s of video, ending about %s. Next file starts %s s later (%s). About %s s was not recorded.\n' \
      "$dur_s" "$end_disp" "$gap" "$next_disp" "$hole"
    echo
  done
  IFS=$'\t' read -r f base start_disp dur_s next_disp gap hole <<< "${rows[0]}"
  end_disp=$(dashcam_clock_plus "$start_disp" "$dur_s")
  echo "  The clips will still be merged in this order. The GPX will keep only those seconds"
  echo "  for each short file, then a gap, then the next clip. The map will not draw the"
  printf '  missing stretch. Worth a look at %s in the merged file, where that clip ends.\n' "$end_disp"
}

dashcam_print_short_clip_after_gpx() {
  local -a files=("$@")
  local row f base start_disp dur_s next_disp gap hole end_disp
  local -a rows=()
  mapfile -t rows < <(dashcam_short_clip_rows "${files[@]}" || true)
  (( ${#rows[@]} )) || return 0
  for row in "${rows[@]}"; do
    IFS=$'\t' read -r f base start_disp dur_s next_disp gap hole <<< "$row"
    end_disp=$(dashcam_clock_plus "$start_disp" "$dur_s")
    echo "$(pgm_ts) Short clip: ${base}  (ends about ${end_disp}, ${dur_s} s). Check that stretch in the video and on the map."
  done
}

dashcam_note_short_clips_for_run() {
  local output_file="$1"
  shift
  local -a files=("$@")
  local row f base start_disp dur_s next_disp gap hole
  local -a rows=()
  mapfile -t rows < <(dashcam_short_clip_rows "${files[@]}" || true)
  (( ${#rows[@]} )) || return 0
  for row in "${rows[@]}"; do
    IFS=$'\t' read -r f base start_disp dur_s next_disp gap hole <<< "$row"
    PGM_SHORT_CLIP_NOTES+=("${output_file}"$'\t'"${base}"$'\t'"${start_disp}"$'\t'"${dur_s}"$'\t'"${next_disp}"$'\t'"${gap}"$'\t'"${hole}")
  done
}

dashcam_print_short_clip_run_summary() {
  local n i row out base start_disp dur_s next_disp gap hole end_disp
  local -a notes=("${PGM_SHORT_CLIP_NOTES[@]+"${PGM_SHORT_CLIP_NOTES[@]}"}")
  n=${#notes[@]}
  (( n )) || return 0
  if (( n == 1 )); then
    echo "  Short clips this run (video shorter than the gap to the next file):"
  else
    echo "  Short clips this run (video shorter than the gap to the next file):"
  fi
  for (( i = 0; i < n; i++ )); do
    row="${notes[$i]}"
    IFS=$'\t' read -r out base start_disp dur_s next_disp gap hole <<< "$row"
    end_disp=$(dashcam_clock_plus "$start_disp" "$dur_s")
    printf '    %s  %s s, next at %s\n' "$base" "$dur_s" "$next_disp"
    printf '              %s\n' "${out##*/}"
    printf '              Look around %s, where this clip ends. The GPX has a gap there on purpose.\n' "$end_disp"
  done
  echo
}

# Windows file for awk: one "start_epoch duration" line per clip. Duration 0 means
# the last-clip fallback (start through start+75 s).
dashcam_write_clip_windows_file() {
  local dest="$1"
  shift
  local -a files=("$@")
  local f epoch dur
  : > "$dest"
  for f in "${files[@]}"; do
    dashcam_parse_basename "${f##*/}" || continue
    epoch=$(gopro_datetime_to_epoch "$DASHCAM_DATE" "$DASHCAM_TIME" 2>/dev/null) || continue
    dur=$(ffprobe_duration_seconds "$f" 2>/dev/null) || dur="0"
    printf '%s %s\n' "$epoch" "$dur" >> "$dest"
  done
  [[ -s "$dest" ]]
}

# Write one GPX for this journey next to the merged MP4.
# Points come from GPSData*.txt. The log clock is aligned to the NO* filename
# times (the camera clock), then stored in the GPX as UTC.
# Write a GPX for one journey. first/last are YYYYMMDD and HHMMSS from the clips
# or from the merged file name. stamp_src supplies the file time.
# $7, when set, is a windows file: start_epoch duration per clip.
dashcam_write_gpx_span() {
  local output_mp4="$1" first_date="$2" first_time="$3" last_date="$4" last_time="$5" stamp_src="$6"
  local windows_file="${7:-}"
  local gpx tmp first_epoch last_epoch tz_corr nlog
  local -a logs=()
  gpx=$(dashcam_gpx_beside_output "$output_mp4")
  mapfile -t logs < <(dashcam_gps_logs || true)
  if (( ${#logs[@]} == 0 )); then
    echo "$(pgm_ts) GPS: no GPSData*.txt in the places searched — did not write ${gpx##*/}"
    return 0
  fi
  first_epoch=$(gopro_datetime_to_epoch "$first_date" "$first_time") || return 1
  last_epoch=$(gopro_datetime_to_epoch "$last_date" "$last_time") || return 1
  tz_corr=$(dashcam_local_epoch_tz_corr) || return 1
  tmp="${gpx}.tmp.$$"
  if ! nlog=$(awk -v first_epoch="$first_epoch" -v last_epoch="$last_epoch" -v tz_corr="$tz_corr" \
      -v track_name="${gpx##*/}" -v out="$tmp" \
      -v windows_file="$windows_file" \
      -v seg_gap="${PGM_DASHCAM_GPX_SEG_GAP_SEC:-8}" '
    function civil_as_utc(y, mo, d, H, M, S,    a, yy, mm, jd) {
      a = int((14 - mo) / 12)
      yy = y + 4800 - a
      mm = mo + 12 * a - 3
      jd = d + int((153 * mm + 2) / 5) + 365 * yy + int(yy / 4) - int(yy / 100) + int(yy / 400) - 32045
      return (jd - 2440588) * 86400 + H * 3600 + M * 60 + S
    }
    function abs(x) { return x < 0 ? -x : x }
    function is_leap(y) { return (y % 4 == 0 && y % 100 != 0) || (y % 400 == 0) }
    function utc_iso(epoch,    days, sod, y, diy, mo, dim, d, H, M, S) {
      if (epoch < 0) epoch = 0
      days = int(epoch / 86400)
      sod = epoch % 86400
      H = int(sod / 3600)
      M = int((sod % 3600) / 60)
      S = sod % 60
      y = 1970
      while (1) {
        diy = is_leap(y) ? 366 : 365
        if (days < diy) break
        days -= diy
        y++
      }
      mo = 1
      while (mo <= 12) {
        if (mo == 2) dim = is_leap(y) ? 29 : 28
        else if (mo == 4 || mo == 6 || mo == 9 || mo == 11) dim = 30
        else dim = 31
        if (days < dim) break
        days -= dim
        mo++
      }
      d = days + 1
      return sprintf("%04d-%02d-%02dT%02d:%02d:%02dZ", y, mo, d, H, M, S)
    }
    # 1-based heapsort. num=1 compares numbers; otherwise the whole string.
    function sift(a, n, i, num,    l, r, best, tmp) {
      while (1) {
        l = i * 2
        r = l + 1
        best = i
        if (l <= n && (num ? (a[l] + 0) > (a[best] + 0) : a[l] > a[best])) best = l
        if (r <= n && (num ? (a[r] + 0) > (a[best] + 0) : a[r] > a[best])) best = r
        if (best == i) return
        tmp = a[i]; a[i] = a[best]; a[best] = tmp
        i = best
      }
    }
    function sort_n(a, n, num,    i, tmp) {
      if (n < 2) return
      for (i = int(n / 2); i >= 1; i--) sift(a, n, i, num)
      for (i = n; i > 1; i--) {
        tmp = a[1]; a[1] = a[i]; a[i] = tmp
        sift(a, i - 1, 1, num)
      }
    }
    {
      sub(/\r$/, "")
      if ($0 !~ /^[0-9]+,A,/) next
      n = split($0, f, ",")
      ts = f[1] + 0
      lat = f[3] + 0
      lon = f[4] + 0
      fn = ""
      for (i = 5; i <= n; i++) {
        if (f[i] ~ /^(NO|EV)[0-9]{8}-[0-9]{6}-[0-9]{6}[A-Za-z]\.[Mm][Pp]4$/) {
          fn = f[i]
          break
        }
      }
      if (fn == "") next
      if (ts in pts) next
      y = substr(fn, 3, 4) + 0
      mo = substr(fn, 7, 2) + 0
      d = substr(fn, 9, 2) + 0
      H = substr(fn, 12, 2) + 0
      M = substr(fn, 14, 2) + 0
      S = substr(fn, 16, 2) + 0
      file_epoch = civil_as_utc(y, mo, d, H, M, S) + tz_corr
      delta = ts - file_epoch
      pts[ts] = lat SUBSEP lon
      deltas[++nd] = delta
    }
    END {
      if (nd < 1) {
        print "0"
        exit 0
      }
      # Median of (log time − filename start). Samples sit 0–60s into a clip.
      for (i = 1; i <= nd; i++) ord[i] = deltas[i]
      sort_n(ord, nd, 1)
      mid = int((nd + 1) / 2)
      median = ord[mid]
      nb = 0
      for (i = 1; i <= nd; i++) {
        if (abs(deltas[i] - median) <= 180) near[++nb] = deltas[i]
      }
      if (nb < 1) {
        print "0"
        exit 0
      }
      sort_n(near, nb, 1)
      # Low end of the in-clip spread ≈ the constant log-clock bias.
      bias = near[int(nb * 0.05) + 1]
      nw = 0
      if (windows_file != "") {
        while ((getline wline < windows_file) > 0) {
          nwf = split(wline, wf, " ")
          if (nwf < 2) continue
          nw++
          wstart[nw] = wf[1] + 0
          wdur[nw] = wf[2] + 0
        }
        close(windows_file)
      }
      m = 0
      for (ts in pts) {
        keep = 0
        if (nw > 0) {
          for (w = 1; w <= nw; w++) {
            lo = wstart[w] + bias - 3
            if (wdur[w] > 0) hi = wstart[w] + wdur[w] + bias + 2
            else hi = wstart[w] + bias + 75
            if (ts + 0 >= lo && ts + 0 <= hi) { keep = 1; break }
          }
        } else {
          lo = first_epoch + bias - 3
          hi = last_epoch + bias + 75
          if (ts + 0 >= lo && ts + 0 <= hi) keep = 1
        }
        if (!keep) continue
        split(pts[ts], ll, SUBSEP)
        utc = ts - bias
        m++
        rows[m] = sprintf("%010d\t%.6f\t%.6f\t%s", utc, ll[1], ll[2], utc_iso(utc))
      }
      if (m < 1) {
        print "0"
        exit 0
      }
      sort_n(rows, m, 0)
      if (seg_gap + 0 <= 0) seg_gap = 8
      print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" > out
      print "<gpx version=\"1.1\" creator=\"video-pgm-merge-and-make-gpx.sh\" xmlns=\"http://www.topografix.com/GPX/1/1\">" > out
      print "  <trk>" > out
      print "    <name>" track_name "</name>" > out
      print "    <trkseg>" > out
      prev_utc = -1
      for (i = 1; i <= m; i++) {
        split(rows[i], c, "\t")
        utc = c[1] + 0
        if (prev_utc >= 0 && utc - prev_utc > seg_gap) {
          print "    </trkseg>" > out
          print "    <trkseg>" > out
        }
        printf "      <trkpt lat=\"%s\" lon=\"%s\"><time>%s</time></trkpt>\n", c[2], c[3], c[4] > out
        prev_utc = utc
      }
      print "    </trkseg>" > out
      print "  </trk>" > out
      print "</gpx>" > out
      close(out)
      print m
    }
  ' "${logs[@]}"); then
    rm -f -- "$tmp"
    echo "$(pgm_ts) GPS: could not build ${gpx##*/}" >&2
    return 1
  fi
  if [[ ! "$nlog" =~ ^[0-9]+$ ]] || (( nlog < 1 )) || [[ ! -s "$tmp" ]]; then
    rm -f -- "$tmp"
    echo "$(pgm_ts) GPS: no points in this journey — did not write ${gpx##*/}"
    return 0
  fi
  if mv -f -- "$tmp" "$gpx"; then
    echo "$(pgm_ts) GPS: wrote ${nlog} points → ${gpx}"
    pgm_stamp_file_time "$stamp_src" "$gpx"
  else
    rm -f -- "$tmp"
    echo "$(pgm_ts) GPS: could not write ${gpx}" >&2
    return 1
  fi
}

# Clips still in the folder: each clip keeps only its measured length.
dashcam_write_gpx_for_group() {
  local output_mp4="$1"
  shift
  local -a files=("$@")
  local fd ft ld lt win rc=0
  dashcam_parse_basename "${files[0]##*/}" || return 1
  fd=$DASHCAM_DATE
  ft=$DASHCAM_TIME
  dashcam_parse_basename "${files[-1]##*/}" || return 1
  ld=$DASHCAM_DATE
  lt=$DASHCAM_TIME
  win="${output_mp4}.gpx.windows.$$"
  if dashcam_write_clip_windows_file "$win" "${files[@]}"; then
    dashcam_write_gpx_span "$output_mp4" "$fd" "$ft" "$ld" "$lt" "${files[0]}" "$win" || rc=$?
  else
    dashcam_write_gpx_span "$output_mp4" "$fd" "$ft" "$ld" "$lt" "${files[0]}" || rc=$?
  fi
  rm -f -- "$win"
  dashcam_print_short_clip_after_gpx "${files[@]}"
  dashcam_note_short_clips_for_run "$output_mp4" "${files[@]}"
  return "$rc"
}

# Merged file only: the window is the start and end written in its name.
dashcam_write_gpx_from_concat() {
  local output_mp4="$1"
  concat_parse_dashcam_output "${output_mp4##*/}" || return 1
  dashcam_write_gpx_span "$output_mp4" \
    "${CONCAT_DASH_START:0:8}" "${CONCAT_DASH_START:8:6}" \
    "${CONCAT_DASH_END:0:8}" "${CONCAT_DASH_END:8:6}" \
    "$output_mp4"
}

# Write the journey GPX once the merged MP4 is on disk.
dashcam_write_gpx_if_merged() {
  local output_file="$1"
  shift
  group_is_dashcam "$@" || return 0
  [[ -f "$output_file" ]] || return 0
  dashcam_write_gpx_for_group "$output_file" "$@" || true
}

# Group 70mai NO* and EV* singles into continuous journeys.
# Same camera letter, ordered by filename time (the sequence number restarts each day).
# Sequence +1 and a start gap of about one clip (default 50–90s) stay in one journey.
# An EV clip with the next sequence number stays in that journey even when the gap
# is shorter than a minute. A longer gap starts a new journey. Front and rear stay apart.
build_dashcam_journey_groups() {
  local -a kept=() new_groups=() keys_seen=() files=() key_files=() run=()
  local -A by_key=()
  local blob f base key prev_seq prev_kind prev_epoch cur_seq cur_kind cur_epoch gap min_gap max_gap

  max_gap="${PGM_DASHCAM_MAX_GAP_SEC:-90}"
  [[ "$max_gap" =~ ^[0-9]+$ ]] || max_gap=90

  for blob in "${GROUP_BLOBS[@]}"; do
    group_files_to_array "$blob" files
    if (( ${#files[@]} >= 2 )); then
      kept+=("$blob")
      continue
    fi
    f="${files[0]}"
    base="${f##*/}"
    if ! dashcam_parse_basename "$base"; then
      kept+=("$f")
      continue
    fi
    key="$DASHCAM_CAM"
    if [[ -z "${by_key[$key]+x}" ]]; then
      by_key["$key"]="$f"
      keys_seen+=("$key")
    else
      by_key["$key"]+=$'\n'"$f"
    fi
  done

  for key in "${keys_seen[@]}"; do
    key_files=()
    mapfile -t key_files < <(
      while IFS= read -r f || [[ -n "$f" ]]; do
        [[ -z "$f" ]] && continue
        dashcam_parse_basename "${f##*/}" || continue
        printf '%s%s\t%06d\t%s\n' "$DASHCAM_DATE" "$DASHCAM_TIME" "$DASHCAM_SEQ" "$f"
      done <<< "${by_key[$key]}" | LC_ALL=C sort -t $'\t' -k1,1 -k2,2n | cut -f3-
    )
    run=()
    prev_seq=""
    prev_kind=""
    prev_epoch=""
    for f in "${key_files[@]}"; do
      [[ -z "$f" ]] && continue
      dashcam_parse_basename "${f##*/}" || {
        kept+=("$f")
        continue
      }
      cur_seq=$DASHCAM_SEQ
      cur_kind=$DASHCAM_KIND
      cur_epoch=$(gopro_datetime_to_epoch "$DASHCAM_DATE" "$DASHCAM_TIME" 2>/dev/null) || cur_epoch=""
      if (( ${#run[@]} == 0 )); then
        run=( "$f" )
        prev_seq=$cur_seq
        prev_kind=$cur_kind
        prev_epoch=$cur_epoch
        continue
      fi
      gap=""
      if [[ -n "$prev_epoch" && -n "$cur_epoch" ]]; then
        gap=$(( cur_epoch - prev_epoch ))
      fi
      min_gap=50
      if [[ "$prev_kind" == EV || "$cur_kind" == EV ]]; then
        min_gap=1
      fi
      if [[ -n "$gap" ]] && (( cur_seq == prev_seq + 1 && gap >= min_gap && gap <= max_gap )); then
        run+=( "$f" )
        prev_seq=$cur_seq
        prev_kind=$cur_kind
        prev_epoch=$cur_epoch
      else
        if (( ${#run[@]} >= 2 )); then
          new_groups+=("$(printf '%s\n' "${run[@]}")")
        else
          kept+=( "${run[@]}" )
        fi
        run=( "$f" )
        prev_seq=$cur_seq
        prev_kind=$cur_kind
        prev_epoch=$cur_epoch
      fi
    done
    if (( ${#run[@]} >= 2 )); then
      new_groups+=("$(printf '%s\n' "${run[@]}")")
    elif (( ${#run[@]} == 1 )); then
      kept+=( "${run[0]}" )
    fi
  done

  GROUP_BLOBS=( "${kept[@]}" "${new_groups[@]}" )
}

# Build merge groups: each element of GROUP_BLOBS is a newline-separated file list (sorted).
build_chapter_groups() {
  local -a sorted=("$@")
  GROUP_BLOBS=()
  local f base
  local -a rest1=() rest2=() preload=()
  local n=${#sorted[@]}

  echo "$(pgm_ts) Building chapter plan (${n} file(s))…"
  pgm_hybrid_start_cache_clear
  PGM_FFPROBE_DUR_CACHE=()
  for f in "${sorted[@]}"; do
    base="${f##*/}"
    is_concat_output_basename "$base" && continue
    preload+=( "$f" )
  done
  pgm_hybrid_preload_files "${preload[@]}"

  # 1) raw GoPro chapter files (GXccnnnn[_Proxy].MP4) -> key-based groups
  build_raw_gopro_groups rest1 "${sorted[@]}"
  # 2) already-renamed _part_NN chapters -> key-based groups (originals vs proxies kept apart)
  build_part_chapter_groups rest2 "${rest1[@]}"
  # 3) everything else becomes a single-file blob; letter chapters then size-splits
  for f in "${rest2[@]}"; do
    base="${f##*/}"
    if is_concat_output_basename "$base"; then
      continue
    fi
    GROUP_BLOBS+=("$f")
  done
  # 4) rename-style a/b/c chapter letters on the same timestamp (any size)
  build_letter_chapter_groups
  # 5) ~4 GB / ~12 GB size-split chapters without letter / _part_XX names
  build_size_split_groups
  # 6) 70mai NO* and EV* continuous journeys (sequence +1; EV may start sooner than a minute)
  build_dashcam_journey_groups
  pgm_progress_end
  pgm_hybrid_start_media_note
  echo "$(pgm_ts) Chapter plan ready."
}

group_files_to_array() {
  local blob="$1"
  local -n _out=$2
  mapfile -t _out <<< "$blob"
  if ((${#_out[@]})) && [[ -z "${_out[-1]}" ]]; then
    unset '_out[-1]'
  fi
}

print_size_split_group_hint() {
  local cam_sample="$1"
  if [[ "$cam_sample" == *GOPRO* ]]; then
    echo "Probable size-split / letter-chapter recordings (no _part_XX; same camera + session label; ~4 GB / ~6:49 or ~12 GB chapters, or a/b/c letters on one start time; leading timestamp may differ per file):"
  else
    echo "Probable size-split / letter-chapter recordings (no _part_XX; same camera + session label; sequential ~4 GB or ~12 GB chapters, or a/b/c letters on one start time; leading timestamp may differ per file):"
  fi
}

print_group_plan() {
  local -a all_mp4=("$@")
  local gidx=0 mergeable=0 size_split_groups=0 part_groups=0 raw_gopro_groups=0 dashcam_groups=0 standalone=0
  local -a files=()
  local f base part cam blob out_name is_ss
  local group_bytes=0 sz
  if (( FORCE_MERGE )); then
    if (( FORCE_MERGE_PLUS_N > 0 )); then
      echo "$(pgm_ts) Forced merge from the command line (alphabetical +${FORCE_MERGE_PLUS_N} from first file):"
    else
      echo "$(pgm_ts) Forced merge from the command line (this order):"
    fi
    echo
    echo "Join these files:"
    for f in "${all_mp4[@]}"; do
      printf '  %s\n' "${f##*/}"
    done
    echo
    for blob in "${GROUP_BLOBS[@]}"; do
      group_files_to_array "$blob" files
      (( ${#files[@]} >= 2 )) || continue
      out_name=$(group_output_file "${files[@]}")
      if [[ -e "$out_name" ]]; then
        printf '  [forced] %d files → %s  (already merged)\n' "${#files[@]}" "${out_name##*/}"
      else
        printf '  [forced] %d files → %s\n' "${#files[@]}" "${out_name##*/}"
      fi
      group_bytes=0
      for f in "${files[@]}"; do
        print_chapter_file_line '      ' "$f"
        sz=$(file_size_bytes "$f")
        (( group_bytes += sz ))
      done
      printf '      input total (%d files): %s\n' "${#files[@]}" "$(format_bytes_human "$group_bytes")"
      echo
    done
    return 0
  fi
  echo "$(pgm_ts) Chapter plan in $(pwd):"
  echo
  for blob in "${GROUP_BLOBS[@]}"; do
    group_files_to_array "$blob" files
    (( ${#files[@]} >= 2 )) || continue
    (( mergeable++ )) || true
    if group_is_raw_gopro "${files[@]}"; then
      (( raw_gopro_groups++ )) || true
    elif group_is_dashcam "${files[@]}"; then
      (( dashcam_groups++ )) || true
    elif group_is_size_split "${files[@]}"; then
      (( size_split_groups++ )) || true
    else
      (( part_groups++ )) || true
    fi
  done
  if (( part_groups > 0 )); then
    echo "Merge candidates (_part_XX chapters; consecutive parts from part_01; orphan tails need chaining times):"
    gidx=0
    for blob in "${GROUP_BLOBS[@]}"; do
      group_files_to_array "$blob" files
      (( ${#files[@]} < 2 )) && continue
      group_is_raw_gopro "${files[@]}" && continue
      group_is_dashcam "${files[@]}" && continue
      group_is_size_split "${files[@]}" && continue
      (( gidx++ )) || true
      out_name=$(group_output_file "${files[@]}")
      if [[ -e "$out_name" ]]; then
        printf '  [group %d/%d] %d parts → %s  (already merged)\n' \
          "$gidx" "$part_groups" "${#files[@]}" "$out_name"
      else
        printf '  [group %d/%d] %d parts → %s\n' \
          "$gidx" "$part_groups" "${#files[@]}" "$out_name"
      fi
      group_bytes=0
      for f in "${files[@]}"; do
        print_chapter_file_line '      ' "$f"
        sz=$(file_size_bytes "$f")
        (( group_bytes += sz ))
      done
      printf '      input total (%d files): %s\n' "${#files[@]}" "$(format_bytes_human "$group_bytes")"
      echo
    done
  fi
  if (( size_split_groups > 0 )); then
    cam=""
    for blob in "${GROUP_BLOBS[@]}"; do
      group_files_to_array "$blob" files
      (( ${#files[@]} < 2 )) && continue
      group_is_size_split "${files[@]}" || continue
      cam=$(gopro_camera_from_basename "${files[0]##*/}" 2>/dev/null) || cam=
      break
    done
    print_size_split_group_hint "$cam"
    gidx=0
    for blob in "${GROUP_BLOBS[@]}"; do
      group_files_to_array "$blob" files
      (( ${#files[@]} < 2 )) && continue
      group_is_size_split "${files[@]}" || continue
      (( gidx++ )) || true
      out_name=$(group_output_file "${files[@]}")
      local grp_desc
      grp_desc=$(gopro_middle_from_basename "${files[0]##*/}" 2>/dev/null) || grp_desc=
      grp_desc="${grp_desc//_-/ }"
      grp_desc="${grp_desc//_/ }"
      grp_desc="${grp_desc# }"
      grp_desc="${grp_desc% }"
      # Skip empty separator-only middles (e.g. -__- → "-").
      [[ "$grp_desc" =~ ^[[:space:]-]*$ ]] && grp_desc=
      if [[ -e "$out_name" ]]; then
        if [[ -n "$grp_desc" ]]; then
          printf '  [group %d/%d] %d clips (%s) → %s  (already merged)\n' \
            "$gidx" "$size_split_groups" "${#files[@]}" "$grp_desc" "$out_name"
        else
          printf '  [group %d/%d] %d clips → %s  (already merged)\n' \
            "$gidx" "$size_split_groups" "${#files[@]}" "$out_name"
        fi
      else
        if [[ -n "$grp_desc" ]]; then
          printf '  [group %d/%d] %d clips (%s) → %s\n' \
            "$gidx" "$size_split_groups" "${#files[@]}" "$grp_desc" "$out_name"
        else
          printf '  [group %d/%d] %d clips → %s\n' \
            "$gidx" "$size_split_groups" "${#files[@]}" "$out_name"
        fi
      fi
      group_bytes=0
      for f in "${files[@]}"; do
        print_chapter_file_line '      ' "$f"
        sz=$(file_size_bytes "$f")
        (( group_bytes += sz ))
      done
      printf '      input total (%d files): %s\n' "${#files[@]}" "$(format_bytes_human "$group_bytes")"
      echo
    done
  fi
  if (( raw_gopro_groups > 0 )); then
    echo "Merge candidates (GoPro chapter files GXccnnnn — originals and proxies separately):"
    gidx=0
    for blob in "${GROUP_BLOBS[@]}"; do
      group_files_to_array "$blob" files
      (( ${#files[@]} < 2 )) && continue
      group_is_raw_gopro "${files[@]}" || continue
      (( gidx++ )) || true
      out_name=$(group_output_file "${files[@]}")
      if [[ -e "$out_name" ]]; then
        printf '  [group %d/%d] %d chapters → %s  (already merged)\n' \
          "$gidx" "$raw_gopro_groups" "${#files[@]}" "$out_name"
      else
        printf '  [group %d/%d] %d chapters → %s\n' \
          "$gidx" "$raw_gopro_groups" "${#files[@]}" "$out_name"
      fi
      group_bytes=0
      for f in "${files[@]}"; do
        printf '      %s\n' "${f##*/}"
        sz=$(file_size_bytes "$f")
        (( group_bytes += sz ))
      done
      printf '      input total (%d files): %s\n' "${#files[@]}" "$(format_bytes_human "$group_bytes")"
      echo
    done
  fi
  if (( dashcam_groups > 0 )); then
    echo "Merge candidates (70mai NO* and EV* continuous journey; sequence +1, about a minute between normal starts, an event clip may start sooner; a longer gap starts a new journey):"
    gidx=0
    for blob in "${GROUP_BLOBS[@]}"; do
      group_files_to_array "$blob" files
      (( ${#files[@]} < 2 )) && continue
      group_is_dashcam "${files[@]}" || continue
      (( gidx++ )) || true
      out_name=$(group_output_file "${files[@]}")
      dashcam_parse_basename "${files[0]##*/}" || true
      if [[ -e "$out_name" ]] && dashcam_gpx_is_valid "$(dashcam_gpx_beside_output "$out_name")"; then
        printf '  [group %d/%d] camera %s, %d clips → %s  (already merged)\n' \
          "$gidx" "$dashcam_groups" "$DASHCAM_CAM" "${#files[@]}" "$out_name"
      elif [[ -e "$out_name" ]]; then
        printf '  [group %d/%d] camera %s, %d clips → %s  (merged, GPX missing)\n' \
          "$gidx" "$dashcam_groups" "$DASHCAM_CAM" "${#files[@]}" "$out_name"
      else
        printf '  [group %d/%d] camera %s, %d clips → %s\n' \
          "$gidx" "$dashcam_groups" "$DASHCAM_CAM" "${#files[@]}" "$out_name"
      fi
      print_dashcam_gpx_suggestion "$out_name" '      '
      group_bytes=0
      for f in "${files[@]}"; do
        print_chapter_file_line '      ' "$f"
        sz=$(file_size_bytes "$f")
        (( group_bytes += sz ))
      done
      printf '      input total (%d files): %s\n' "${#files[@]}" "$(format_bytes_human "$group_bytes")"
      echo
    done
  fi
  for blob in "${GROUP_BLOBS[@]}"; do
    group_files_to_array "$blob" files
    (( ${#files[@]} < 2 )) && (( standalone++ )) || true
  done
  if (( standalone > 0 )); then
    echo "Standalone (single chapter, will not merge):"
    for blob in "${GROUP_BLOBS[@]}"; do
      group_files_to_array "$blob" files
      (( ${#files[@]} >= 2 )) && continue
      base="${files[0]##*/}"
      part=$(chapter_part_from_basename "$base" 2>/dev/null) || part=
      cam=$(chapter_camera_from_basename "$base" 2>/dev/null) || cam=
      printf '      '
      [[ -n "$part" ]] && printf 'part %02d  ' "$part"
      [[ -n "$cam" ]] && printf '%s  ' "$cam"
      printf '%s\n' "$base"
    done
    echo
  fi
  print_orphan_concat_section "${all_mp4[@]}"
  local breakdown=""
  (( part_groups > 0 )) && breakdown+="${breakdown:+, }${part_groups} _part_XX"
  (( raw_gopro_groups > 0 )) && breakdown+="${breakdown:+, }${raw_gopro_groups} GoPro chapter"
  (( size_split_groups > 0 )) && breakdown+="${breakdown:+, }${size_split_groups} size-split"
  (( dashcam_groups > 0 )) && breakdown+="${breakdown:+, }${dashcam_groups} 70mai journey"
  if [[ -n "$breakdown" ]]; then
    echo "$(pgm_ts) Summary: ${mergeable} merge group(s) (${breakdown}), ${standalone} standalone file(s), ${PGM_ORPHAN_CONCAT_COUNT} merged output(s) without input chapters."
  else
    echo "$(pgm_ts) Summary: ${mergeable} merge group(s), ${standalone} standalone file(s), ${PGM_ORPHAN_CONCAT_COUNT} merged output(s) without input chapters."
  fi
  echo
}

# Forced CLI merge: keep command-line order; write next to the first file.
force_merge_group_output_file() {
  local -a files=("$@")
  local base stem dir n
  (( ${#files[@]} >= 2 )) || return 1
  base="${files[0]##*/}"
  stem="${base%.*}"
  dir="$(dirname -- "${files[0]}")"
  n=${#files[@]}
  if [[ "$dir" == . ]]; then
    printf '%s_concat_parts_01-%02d.mp4\n' "$stem" "$n"
  else
    printf '%s/%s_concat_parts_01-%02d.mp4\n' "$dir" "$stem" "$n"
  fi
}

group_output_file() {
  local -a files=("$@")
  local f base stem part min_part= max_part= got_part=0 suffix_proxy=
  if (( FORCE_MERGE )); then
    force_merge_group_output_file "${files[@]}" && return 0
  fi
  if (( ${#files[@]} >= 2 )) && group_is_dashcam "${files[@]}"; then
    dashcam_resolved_output_file "${files[@]}" && return 0
  fi
  if (( ${#files[@]} >= 2 )) && group_is_size_split "${files[@]}"; then
    size_split_group_output_file "${files[@]}" && return 0
  fi
  if group_is_raw_gopro "${files[@]}"; then
    raw_gopro_group_output_file "${files[@]}" && return 0
  fi
  for f in "${files[@]}"; do
    base="${f##*/}"
    if part=$(chapter_part_from_basename "$base" 2>/dev/null); then
      got_part=1
      if [[ -z "$min_part" ]] || (( part < min_part )); then
        min_part=$part
      fi
      if [[ -z "$max_part" ]] || (( part > max_part )); then
        max_part=$part
      fi
    fi
  done
  base="${files[0]##*/}"
  stem="${base%.*}"
  if (( got_part )) && [[ "$stem" =~ ^(.*)_part_[0-9]{2}(_Proxy)?$ ]]; then
    suffix_proxy="${BASH_REMATCH[2]}"
    printf '%s_concat_parts_%02d-%02d%s.mp4\n' \
      "${BASH_REMATCH[1]}" "$min_part" "$max_part" "$suffix_proxy"
    return 0
  fi
  printf '%s_concat.mp4\n' "$stem"
}

print_merge_size_summary() {
  local output_file="$1"
  shift
  local -a files=("$@")
  local f input_total=0 out_sz=0
  for f in "${files[@]}"; do
    sz=$(file_size_bytes "$f")
    (( input_total += sz ))
  done
  echo "=== Size summary ==="
  print_merge_group_io_block "$output_file" "${files[@]}"
  if [[ -f "$output_file" ]]; then
    out_sz=$(file_size_bytes "$output_file")
    format_size_comparison_line "$input_total" "$out_sz"
  else
    echo "  $(pgm_ts) Output file missing — merge may have failed."
  fi
  echo
}

# $1 = after_merge|already_merged, $2 = merged output path, remaining = input chapters.
prompt_delete_merged_inputs() {
  local context="${1:-after_merge}"
  local output_file="${2:-}"
  shift 2
  local -a files=("$@")
  local f choice
  if (( DO_YES )) || (( ! script_is_run_interactively )); then
    return 0
  fi
  if (( KEEP_INPUTS_FOR_RUN )); then
    echo "$(pgm_ts) Input files kept (for the rest of this run)."
    return 0
  fi
  if [[ -n "$output_file" && -e "$output_file" ]]; then
    print_merge_seam_times_summary "$output_file" "${files[@]}" || true
  fi
  if [[ "$context" == already_merged ]]; then
    echo "$(pgm_ts) Delete ${#files[@]} input chapter file(s)? (merged output will be kept)"
  else
    echo "$(pgm_ts) Delete the ${#files[@]} merged input chapter file(s)?"
  fi
  for f in "${files[@]}"; do
    printf '    %s\n' "${f##*/}"
  done
  echo "  Choosing yes asks once more before anything is deleted."
  echo "  [y] Yes — go on to the confirmation"
  echo "  [N] No — keep input files (default)"
  echo "  [k] Never delete input files for the rest of this run"
  echo "  [q] Quit"
  pgm_read_key "Delete inputs? [y/N/k/q]: " n
  choice="${REPLY,,}"
  case "$choice" in
    y)
      prompt_confirm_delete_inputs "${files[@]}"
      case $? in
        0) ;;
        2) return 2 ;;
        *) return 0 ;;
      esac
      for f in "${files[@]}"; do
        if rm -f -- "$f"; then
          PGM_RUN_DELETED=$(( ${PGM_RUN_DELETED:-0} + 1 ))
          echo "$(pgm_ts) Deleted: ${f##*/}"
        else
          echo "$(pgm_ts) Could not delete: $f" >&2
        fi
      done
      return 0
      ;;
    k)
      KEEP_INPUTS_FOR_RUN=1
      echo "$(pgm_ts) Input files kept for the rest of this run."
      return 0
      ;;
    q)
      echo "$(pgm_ts) Quit."
      return 2
      ;;
    *)
      echo "$(pgm_ts) Input files kept."
      return 0
      ;;
  esac
}

# Second question before input files are removed. Default is keep. Return 2 to quit.
prompt_confirm_delete_inputs() {
  local -a files=("$@")
  local f choice
  echo
  echo "$(pgm_ts) Delete these ${#files[@]} input file(s)? The merged file stays. This cannot be undone."
  for f in "${files[@]}"; do
    printf '    %s\n' "${f##*/}"
  done
  echo "  [y] Yes — delete these input files"
  echo "  [N] No — keep input files (default)"
  echo "  [q] Quit"
  pgm_read_key "Delete these input files? [y/N/q]: " n
  choice="${REPLY,,}"
  case "$choice" in
    y) return 0 ;;
    q)
      echo "$(pgm_ts) Quit."
      return 2
      ;;
    *)
      echo "$(pgm_ts) Input files kept."
      return 1
      ;;
  esac
}

# Candidate directory for an off-disk merge: --temp-dir / PGM_MERGE_TEMP, else TMPDIR, else /tmp.
merge_temp_dir_candidate() {
  local d=""
  if [[ -n "${PGM_MERGE_TEMP:-}" ]]; then
    d="$PGM_MERGE_TEMP"
  elif [[ -n "${TMPDIR:-}" ]]; then
    d="$TMPDIR"
  else
    d=/tmp
  fi
  d="${d%/}"
  printf '%s\n' "$d"
}

# 0 when this user can create a file in $1 (a real create, not only the write bit).
merge_dir_writable() {
  local d="$1" probe
  [[ -n "$d" && -d "$d" ]] || return 1
  probe=$(mktemp "${d}/.pgm-merge-write.XXXXXX" 2>/dev/null) || return 1
  rm -f -- "$probe"
  return 0
}

# Filesystem device id (Linux stat -c, else BSD stat -f).
fs_device_id() {
  local p="$1" id
  id=$(command stat -c %d -- "$p" 2>/dev/null || command stat -f %d -- "$p" 2>/dev/null) || return 1
  [[ "$id" =~ ^[0-9]+$ ]] || return 1
  printf '%s\n' "$id"
}

# Free bytes on the filesystem that holds $1.
fs_avail_bytes() {
  local p="$1" n
  n=$(/bin/df -B1 --output=avail -- "$p" 2>/dev/null | awk 'NR==2 {print $1}')
  if [[ ! "$n" =~ ^[0-9]+$ ]]; then
    n=$(/bin/df -P -k -- "$p" 2>/dev/null | awk 'NR==2 {printf "%.0f", $4 * 1024}')
  fi
  [[ "$n" =~ ^[0-9]+$ ]] || return 1
  printf '%s\n' "$n"
}

# rotational flag for a /sys/block name: 0 SSD, 1 spinning, unreadable, or missing.
# Device-mapper and md devices follow their slaves. 1 wins if any slave spins.
disk_rotational_flag() {
  local name="$1" depth="${2:-0}" rota slave hdd=0 ssd=0
  name="${name##*/}"
  (( depth > 4 )) && { printf '%s\n' missing; return 0; }
  if [[ ! -d "/sys/block/${name}" ]]; then
    if [[ "$name" =~ ^(nvme[0-9]+n[0-9]+)p[0-9]+$ ]]; then
      name="${BASH_REMATCH[1]}"
    elif [[ "$name" =~ ^(mmcblk[0-9]+)p[0-9]+$ ]]; then
      name="${BASH_REMATCH[1]}"
    elif [[ "$name" =~ ^([a-z]+)[0-9]+$ ]]; then
      name="${BASH_REMATCH[1]}"
    fi
  fi
  if [[ -d "/sys/block/${name}/slaves" ]]; then
    for slave in "/sys/block/${name}/slaves"/*; do
      [[ -e "$slave" ]] || continue
      saw=1
      rota=$(disk_rotational_flag "$(basename -- "$slave")" $(( depth + 1 )))
      case "$rota" in
        1) hdd=1 ;;
        0) ssd=1 ;;
        unreadable)
          printf '%s\n' unreadable
          return 0
          ;;
      esac
    done
    if (( hdd )); then
      printf '1\n'
      return 0
    fi
    if (( ssd )); then
      printf '0\n'
      return 0
    fi
  fi
  if [[ -r "/sys/block/${name}/queue/rotational" ]]; then
    rota=$(tr -d '[:space:]' < "/sys/block/${name}/queue/rotational")
    if [[ "$rota" == 0 || "$rota" == 1 ]]; then
      printf '%s\n' "$rota"
      return 0
    fi
  elif [[ -e "/sys/block/${name}/queue/rotational" ]]; then
    printf '%s\n' unreadable
    return 0
  fi
  printf '%s\n' missing
}

# Sets SOURCE_DISK_KIND to ssd, hdd, or unknown, and SOURCE_DISK_KIND_WHY to a sentence.
refresh_source_disk_kind() {
  local src="" real="" name="" flag=""
  SOURCE_DISK_KIND=unknown
  SOURCE_DISK_KIND_WHY="Cannot tell whether the source disk is an SSD."
  src=$(findmnt -n -o SOURCE -T . 2>/dev/null || true)
  [[ -n "$src" ]] || src=$(/bin/df -P . 2>/dev/null | awk 'NR==2 {print $1}')
  src="${src%%\[*}"
  if [[ -z "$src" ]]; then
    SOURCE_DISK_KIND_WHY="Cannot tell whether the source disk is an SSD (mount source unknown)."
    return 0
  fi
  if [[ "$src" != /dev/* ]]; then
    SOURCE_DISK_KIND_WHY="Cannot tell whether the source disk is an SSD (${src} is not a local block device)."
    return 0
  fi
  real=$(readlink -f -- "$src" 2>/dev/null || printf '%s' "$src")
  name="${real##*/}"
  flag=$(disk_rotational_flag "$name")
  case "$flag" in
    0)
      SOURCE_DISK_KIND=ssd
      SOURCE_DISK_KIND_WHY="Source disk is an SSD."
      ;;
    1)
      SOURCE_DISK_KIND=hdd
      SOURCE_DISK_KIND_WHY="Source disk is not an SSD."
      ;;
    unreadable)
      SOURCE_DISK_KIND=unknown
      SOURCE_DISK_KIND_WHY="Cannot tell whether the source disk is an SSD (no permission to read the rotational flag)."
      ;;
    *)
      SOURCE_DISK_KIND=unknown
      SOURCE_DISK_KIND_WHY="Cannot tell whether the source disk is an SSD (no rotational flag for ${name})."
      ;;
  esac
}

# Prints a reason and returns 1 when $1 bytes will not fit in the temp dir with spare room.
# $2 is the directory to test; omitted means the configured candidate.
# Spare is 10% of the file or 1 GiB, whichever is larger. Returns 0 when the dir is usable.
merge_temp_unfit_reason() {
  local need="$1" tdir="${2:-}" dest_dev tmp_dev avail spare
  [[ "$need" =~ ^[0-9]+$ ]] && (( need > 0 )) || {
    printf '%s\n' "merge size is unknown"
    return 1
  }
  if [[ -z "$tdir" ]]; then
    tdir=$(merge_temp_dir_candidate)
  fi
  tdir="${tdir%/}"
  if [[ ! -d "$tdir" ]]; then
    printf '%s\n' "${tdir} is not a directory"
    return 1
  fi
  if ! merge_dir_writable "$tdir"; then
    printf '%s\n' "cannot create files in ${tdir}"
    return 1
  fi
  dest_dev=$(fs_device_id .) || {
    printf '%s\n' "cannot tell which disk holds the source files"
    return 1
  }
  tmp_dev=$(fs_device_id "$tdir") || {
    printf '%s\n' "cannot tell which disk holds ${tdir}"
    return 1
  }
  if [[ "$dest_dev" == "$tmp_dev" ]]; then
    printf '%s\n' "${tdir} is on the same disk as the source files"
    return 1
  fi
  avail=$(fs_avail_bytes "$tdir") || {
    printf '%s\n' "cannot read free space on ${tdir}"
    return 1
  }
  spare=$(( need / 10 ))
  (( spare < 1073741824 )) && spare=1073741824
  if (( avail < need + spare )); then
    printf '%s\n' "${tdir} has $(format_bytes_human "$avail") free; this merge needs about $(format_bytes_human $(( need + spare )))"
    return 1
  fi
  return 0
}

merge_clear_temp_work() {
  if [[ -n "${MERGE_TMP_DIR}" && -d "${MERGE_TMP_DIR}" ]]; then
    rm -rf -- "${MERGE_TMP_DIR}"
  fi
  MERGE_TMP_DIR=""
}

# Copy $1 to $2 with a progress bar, then remove $1.
merge_copy_back_with_progress() {
  local src="$1" dst="$2"
  echo "$(pgm_ts) Moving merged file back to ${dst}"
  if command -v rsync >/dev/null 2>&1; then
    if rsync --info=help >/dev/null 2>&1; then
      rsync -a --info=progress2 -- "$src" "$dst"
    else
      rsync -a --progress -- "$src" "$dst"
    fi
  elif command -v pv >/dev/null 2>&1; then
    pv -f -p -t -e -r -b -- "$src" > "$dst"
  else
    echo "$(pgm_ts) No rsync or pv — copying without a progress bar."
    cp -f -- "$src" "$dst"
  fi || return 1
  rm -f -- "$src"
  return 0
}

# Directory that holds the chapter files. A bare name uses the current directory.
merge_inputs_dir() {
  local f="${1:-}" d
  if [[ -z "$f" || "$f" != */* ]]; then
    pwd
    return 0
  fi
  d="$(dirname -- "$f")"
  (cd -- "$d" && pwd) 2>/dev/null || printf '%s\n' "$d"
}

# Create pgm-merge.XXXXXX under $1 and point MERGE_WRITE_PATH at the output name.
merge_open_temp_work() {
  local tdir="$1" final="$2" work base
  tdir="${tdir%/}"
  work=$(mktemp -d "${tdir}/pgm-merge.XXXXXX") || return 1
  base="${final##*/}"
  MERGE_TMP_DIR="$work"
  MERGE_WRITE_PATH="${work}/${base}"
  return 0
}

# Asks once how every remaining group in this run is written. Returns 2 on quit.
# MERGE_WRITE_PATH is already the final path. Yes also opens the temp work dir.
prompt_merge_all_temp_dir() {
  local sz="$1" final="$2" first="$3"
  local tdir reason avail default_key prompt_key choice alt
  tdir=$(merge_temp_dir_candidate)
  if ! reason=$(merge_temp_unfit_reason "$sz" "$tdir"); then
    echo "$(pgm_ts) Input files: $(merge_inputs_dir "$first")"
    echo "$(pgm_ts) Not using ${tdir} for these merges: ${reason}."
    echo "  [p] Type another temp directory"
    echo "  [N] Write the outputs in this directory (default)"
    echo "  [q] Quit"
    pgm_read_key "Temp directory for the remaining groups? [p/N/q]: " n
    case "${REPLY,,}" in
      q)
        echo "$(pgm_ts) Quit."
        return 2
        ;;
      p) ;;
      *)
        MERGE_IN_PLACE_FOR_RUN=1
        echo "$(pgm_ts) Writing in this directory for this merge and the rest of this run."
        return 0
        ;;
    esac
    flush_stdin
    printf '%s %s' "$(pgm_ts)" "Temp directory: "
    IFS= read -r alt || alt=""
    alt="${alt%/}"
    if [[ -z "$alt" ]]; then
      MERGE_IN_PLACE_FOR_RUN=1
      echo "$(pgm_ts) Writing in this directory for this merge and the rest of this run."
      return 0
    fi
    if ! reason=$(merge_temp_unfit_reason "$sz" "$alt"); then
      echo "$(pgm_ts) Not using ${alt}: ${reason}."
      MERGE_IN_PLACE_FOR_RUN=1
      echo "$(pgm_ts) Writing in this directory for this merge and the rest of this run."
      return 0
    fi
    MERGE_TEMP_FOR_RUN="$alt"
    echo "$(pgm_ts) Using ${alt} for this merge and the rest of this run."
    if ! merge_open_temp_work "$alt" "$final"; then
      echo "$(pgm_ts) Could not create a temp directory in ${alt}; writing here." >&2
      MERGE_TEMP_FOR_RUN=""
      MERGE_IN_PLACE_FOR_RUN=1
    fi
    return 0
  fi
  avail=$(fs_avail_bytes "$tdir") || {
    MERGE_IN_PLACE_FOR_RUN=1
    echo "$(pgm_ts) Writing in this directory for this merge and the rest of this run."
    return 0
  }
  refresh_source_disk_kind
  echo "$(pgm_ts) Input files: $(merge_inputs_dir "$first")"
  echo "$(pgm_ts) ${SOURCE_DISK_KIND_WHY}"
  echo "$(pgm_ts) ${tdir} is on another disk ($(format_bytes_human "$avail") free)."
  echo "$(pgm_ts) This merge is about $(format_bytes_human "$sz"). Writing it there keeps reading and writing off the same disk."
  echo "$(pgm_ts) The same choice is used for every remaining group in this run."
  if [[ "$SOURCE_DISK_KIND" == ssd ]]; then
    default_key=n
    prompt_key="y/N/q"
    echo "  [y] Yes — merge in ${tdir}, then move each finished file back here"
    echo "  [N] No — write the outputs in this directory (default)"
  else
    default_key=y
    prompt_key="Y/n/q"
    echo "  [Y] Yes — merge in ${tdir}, then move each finished file back here (default)"
    echo "  [n] No — write the outputs in this directory"
  fi
  echo "  [q] Quit"
  while true; do
    pgm_read_key "Merge via ${tdir} for the remaining groups? [${prompt_key}]: " "$default_key"
    choice="${REPLY,,}"
    case "$choice" in
      q)
        echo "$(pgm_ts) Quit."
        return 2
        ;;
      y) break ;;
      n|'')
        MERGE_IN_PLACE_FOR_RUN=1
        echo "$(pgm_ts) Writing in this directory for this merge and the rest of this run."
        return 0
        ;;
      *) echo "$(pgm_ts) Unknown choice: ${REPLY}" ;;
    esac
  done
  MERGE_TEMP_FOR_RUN="$tdir"
  echo "$(pgm_ts) Using ${tdir} for this merge and the rest of this run."
  if ! merge_open_temp_work "$tdir" "$final"; then
    echo "$(pgm_ts) Could not create a temp directory in ${tdir}; writing here." >&2
    MERGE_TEMP_FOR_RUN=""
    MERGE_IN_PLACE_FOR_RUN=1
  fi
  return 0
}

# Sets MERGE_WRITE_PATH to the path mp4_merge should write.
# A single interactive merge asks per group. [m] asks once for the groups still left.
choose_merge_output_path() {
  local final="$1"
  shift
  local -a files=("$@")
  local tdir avail sz=0 n f choice work base reason="" default_key prompt_key alt
  MERGE_WRITE_PATH="$final"
  MERGE_TMP_DIR=""
  if (( MERGE_IN_PLACE_FOR_RUN )); then
    echo "$(pgm_ts) Input files: $(merge_inputs_dir "${files[0]}")"
    echo "$(pgm_ts) Writing in this directory (chosen for the rest of this run)."
    return 0
  fi
  for f in "${files[@]}"; do
    n=$(file_size_bytes "$f")
    sz=$(( sz + n ))
  done
  if [[ -n "$MERGE_TEMP_FOR_RUN" ]]; then
    tdir="$MERGE_TEMP_FOR_RUN"
    if ! reason=$(merge_temp_unfit_reason "$sz" "$tdir"); then
      echo "$(pgm_ts) Input files: $(merge_inputs_dir "${files[0]}")"
      echo "$(pgm_ts) Not using ${tdir} for this merge: ${reason}."
      echo "$(pgm_ts) Writing the output in this directory."
      return 0
    fi
    if ! merge_open_temp_work "$tdir" "$final"; then
      echo "$(pgm_ts) Could not create a temp directory in ${tdir}; writing here." >&2
      return 0
    fi
    echo "$(pgm_ts) Input files: $(merge_inputs_dir "${files[0]}")"
    echo "$(pgm_ts) Merging in ${tdir} (chosen for the rest of this run)."
    return 0
  fi
  if (( DO_YES )) || (( ! script_is_run_interactively )); then
    return 0
  fi
  if (( MERGE_ALL_REMAINING )); then
    prompt_merge_all_temp_dir "$sz" "$final" "${files[0]}"
    return $?
  fi
  tdir=$(merge_temp_dir_candidate)
  if ! reason=$(merge_temp_unfit_reason "$sz" "$tdir"); then
    echo "$(pgm_ts) Input files: $(merge_inputs_dir "${files[0]}")"
    echo "$(pgm_ts) Not using ${tdir} for this merge: ${reason}."
    echo "  [p] Type another temp directory"
    echo "  [N] Write the output in this directory (default)"
    echo "  [r] Write in this directory for the rest of this run"
    echo "  [q] Quit"
    pgm_read_key "Temp directory? [p/N/r/q]: " n
    case "${REPLY,,}" in
      q)
        echo "$(pgm_ts) Quit."
        return 2
        ;;
      r)
        MERGE_IN_PLACE_FOR_RUN=1
        echo "$(pgm_ts) Writing in this directory for this merge and the rest of this run."
        return 0
        ;;
      p) ;;
      *)
        echo "$(pgm_ts) Writing the output in this directory."
        return 0
        ;;
    esac
    flush_stdin
    printf '%s %s' "$(pgm_ts)" "Temp directory: "
    IFS= read -r alt || alt=""
    alt="${alt%/}"
    if [[ -z "$alt" ]]; then
      echo "$(pgm_ts) Writing the output in this directory."
      return 0
    fi
    if ! reason=$(merge_temp_unfit_reason "$sz" "$alt"); then
      echo "$(pgm_ts) Not using ${alt}: ${reason}."
      echo "$(pgm_ts) Writing the output in this directory."
      return 0
    fi
    if ! merge_open_temp_work "$alt" "$final"; then
      echo "$(pgm_ts) Could not create a temp directory in ${alt}; writing here." >&2
      return 0
    fi
    return 0
  fi
  avail=$(fs_avail_bytes "$tdir") || return 0
  refresh_source_disk_kind
  echo "$(pgm_ts) Input files: $(merge_inputs_dir "${files[0]}")"
  echo "$(pgm_ts) ${SOURCE_DISK_KIND_WHY}"
  echo "$(pgm_ts) ${tdir} is on another disk ($(format_bytes_human "$avail") free)."
  echo "$(pgm_ts) This merge is about $(format_bytes_human "$sz"). Writing it there keeps reading and writing off the same disk."
  if [[ "$SOURCE_DISK_KIND" == ssd ]]; then
    default_key=n
    prompt_key="y/d/N/r/q"
    echo "  [y] Yes — merge this file in ${tdir}, then move it back here"
    echo "  [d] Yes — use ${tdir} for the rest of this run as well"
    echo "  [N] No — write the output in this directory (default)"
    echo "  [r] No — write in this directory for the rest of this run as well"
  else
    default_key=y
    prompt_key="Y/d/n/r/q"
    echo "  [Y] Yes — merge this file in ${tdir}, then move it back here (default)"
    echo "  [d] Yes — use ${tdir} for the rest of this run as well"
    echo "  [n] No — write the output in this directory"
    echo "  [r] No — write in this directory for the rest of this run as well"
  fi
  echo "  [q] Quit"
  while true; do
    pgm_read_key "Merge via ${tdir}? [${prompt_key}]: " "$default_key"
    choice="${REPLY,,}"
    case "$choice" in
      q)
        echo "$(pgm_ts) Quit."
        return 2
        ;;
      d)
        MERGE_TEMP_FOR_RUN="$tdir"
        echo "$(pgm_ts) Using ${tdir} for this merge and the rest of this run."
        break
        ;;
      r)
        MERGE_IN_PLACE_FOR_RUN=1
        echo "$(pgm_ts) Writing in this directory for this merge and the rest of this run."
        return 0
        ;;
      y) break ;;
      n|'') return 0 ;;
      *) echo "$(pgm_ts) Unknown choice: ${REPLY}" ;;
    esac
  done
  if ! merge_open_temp_work "$tdir" "$final"; then
    echo "$(pgm_ts) Could not create a temp directory in ${tdir}; writing here." >&2
    return 0
  fi
}

run_merge_group() {
  local merger="$1" redo="${2:-0}"
  shift 2
  local -a files=("$@")
  local output_file rc
  merge_group_assert_codecs "${files[@]}" || return 1
  output_file=$(group_output_file "${files[@]}")
  if [[ -e "$output_file" ]]; then
    if (( ! redo )); then
      dashcam_write_gpx_if_merged "$output_file" "${files[@]}"
      return 0
    fi
    if ! rm -f -- "$output_file"; then
      echo "$(pgm_ts) Could not remove existing output: ${output_file}" >&2
      return 1
    fi
    echo "$(pgm_ts) Removed existing output for redo merge."
  fi
  # Ask date/time before the long merge + exiftool work; apply after.
  pgm_decide_output_times "$output_file" "${files[0]}" || return $?
  local write_path choose_rc
  choose_merge_output_path "$output_file" "${files[@]}"
  choose_rc=$?
  if (( choose_rc != 0 )); then
    pgm_clear_pending_output_times
    return "$choose_rc"
  fi
  write_path="$MERGE_WRITE_PATH"
  VIDEO_MERGE_OUT_FILE="${write_path}"
  if [[ -n "$MERGE_TMP_DIR" ]]; then
    echo "$(pgm_ts) Input files: $(merge_inputs_dir "${files[0]}")"
    echo "$(pgm_ts) Temp dir: ${MERGE_TMP_DIR}"
    echo "$(pgm_ts) Merging ${#files[@]} chapter(s) → ${write_path}"
    echo "$(pgm_ts) Finished file will be moved back to ${output_file}"
  else
    echo "$(pgm_ts) Input files: $(merge_inputs_dir "${files[0]}")"
    echo "$(pgm_ts) Temp dir: not used, writing in this directory"
    echo "$(pgm_ts) Merging ${#files[@]} chapter(s) → ${output_file}"
  fi
  trap video_merge_ctrl_c INT
  pgm_processing_begin
  "${merger}" "${files[@]}" --out "${write_path}"
  rc=$?
  pgm_processing_end
  if (( rc == 0 )); then
    if [[ -n "$MERGE_TMP_DIR" ]]; then
      # Stay on video_merge_ctrl_c: Ctrl-C during the move must drop the temp
      # directory and the partial file at the final name.
      VIDEO_MERGE_OUT_FILE="$output_file"
      if ! merge_copy_back_with_progress "$write_path" "$output_file"; then
        rm -f -- "$output_file"
        trap ctrl_c INT
        VIDEO_MERGE_OUT_FILE=""
        echo "$(pgm_ts) Merge finished, but could not copy ${write_path} to ${output_file}" >&2
        echo "$(pgm_ts) Merged file left at ${write_path}" >&2
        MERGE_TMP_DIR=""
        return 1
      fi
      rmdir -- "$MERGE_TMP_DIR" 2>/dev/null || rm -rf -- "$MERGE_TMP_DIR"
      MERGE_TMP_DIR=""
      echo "$(pgm_ts) Moved merged file to ${output_file}"
    fi
    # Keep incomplete-output cleanup through automated post-merge. Clear before
    # interactive prompts so Ctrl-C on a date/seam question does not wipe a finished merge.
    VIDEO_MERGE_OUT_FILE="$output_file"
    trap video_merge_ctrl_c INT
    echo "$(pgm_ts) mp4_merge finished: ${output_file}"
    echo "$(pgm_ts) Post-merge still running (metadata / GPX / dates) — not finished yet."
    echo "$(pgm_ts) Ctrl-C now removes this merge output (group not finished)."
    local meta_label=""
    meta_label=$(group_merge_description_label "${files[@]}" 2>/dev/null) || meta_label=""
    echo "$(pgm_ts) Copying GPS, dates, camera tags, and title from first chapter (one exiftool rewrite) …"
    echo "$(pgm_ts)   Large files: progress tracks the growing *_exiftool_tmp beside the merge output."
    apply_merge_output_metadata "$output_file" "${files[0]}" "$meta_label" || true
    if group_is_dashcam "${files[@]}"; then
      echo "$(pgm_ts) Writing GPX beside the merge (if needed) …"
    fi
    dashcam_write_gpx_if_merged "$output_file" "${files[@]}"
    echo "$(pgm_ts) Embedding a GPS point in the video if missing …"
    pgm_put_gps "$output_file" "${files[0]}"
    trap ctrl_c INT
    VIDEO_MERGE_OUT_FILE=""
    pgm_finish_pending_output_times "$output_file"
    echo
    print_merge_size_summary "$output_file" "${files[@]}"
    print_merge_boundaries_report "$output_file" "${files[@]}"
    prompt_seam_terminal_previews "$output_file" "${files[@]}"
    rc=$?
    if (( rc == 2 )); then
      return 2
    fi
    prompt_delete_merged_inputs after_merge "$output_file" "${files[@]}"
    rc=$?
    if (( rc == 2 )); then
      return 2
    fi
    pgm_note_processed_group "$output_file" "${files[@]}"
    echo "$(pgm_ts) Group finished: ${output_file}"
    rc=0
  else
    merge_clear_temp_work
    trap ctrl_c INT
    VIDEO_MERGE_OUT_FILE=""
    pgm_clear_pending_output_times
    echo "$(pgm_ts) Merge failed (exit ${rc})." >&2
  fi
  return "${rc}"
}

# Sets REPLY to: merge | redo | skip | skip_all | merge_all | delete_inputs | write_gpx | quit
# $3 = expected output file (may already exist). Remaining args are the chapter files.
# A 70mai group is "already merged" only when the MP4 and a valid GPX are both there.
prompt_merge_group_action() {
  local group_num="$1" group_total="$2" output_file="${3:-}"
  shift 3
  local -a files=("$@")
  local output_exists=0 gpx_ok=1 can_gpx=0 complete=0 choice gps_log="" short_n=0
  local -a short_rows=()
  REPLY=skip
  if group_is_dashcam "${files[@]}"; then
    mapfile -t short_rows < <(dashcam_short_clip_rows "${files[@]}" || true)
    short_n=${#short_rows[@]}
  fi
  if [[ -n "$output_file" && -e "$output_file" ]]; then
    output_exists=1
  fi
  if (( output_exists )) && group_is_dashcam "${files[@]}"; then
    if dashcam_gpx_is_valid "$(dashcam_gpx_beside_output "$output_file")"; then
      gpx_ok=1
    else
      gpx_ok=0
      gps_log=$(dashcam_gps_log_hint 2>/dev/null || true)
      [[ -n "$gps_log" ]] && can_gpx=1
    fi
  fi
  if group_output_is_complete "$output_file" "${files[@]}"; then
    complete=1
  fi
  if (( DO_YES )); then
    if (( complete )); then
      echo "$(pgm_ts) Output already exists, skipping: ${output_file}"
      REPLY=skip
    elif (( output_exists && can_gpx )); then
      (( short_n )) && echo "$(pgm_ts) Short clip in this group. Creating the GPX with a gap there."
      REPLY=write_gpx
    elif (( output_exists )); then
      echo "$(pgm_ts) Output already exists, skipping: ${output_file}"
      REPLY=skip
    else
      (( short_n )) && echo "$(pgm_ts) Short clip in this group. Merging anyway."
      REPLY=merge
    fi
    return 0
  fi
  if (( MERGE_ALL_REMAINING )); then
    if (( complete )); then
      REPLY=skip
    elif (( output_exists && can_gpx )); then
      (( short_n )) && echo "$(pgm_ts) Short clip in this group. Creating the GPX with a gap there."
      REPLY=write_gpx
    elif (( output_exists )); then
      REPLY=skip
    else
      (( short_n )) && echo "$(pgm_ts) Short clip in this group. Merging anyway."
      REPLY=merge
    fi
    return 0
  fi
  if (( SKIP_ALL_REMAINING )); then
    REPLY=skip
    return 0
  fi
  if (( SKIP_MERGED_PROMPTS && complete )); then
    echo "$(pgm_ts) Already merged — not asking again this run: ${output_file##*/}"
    REPLY=skip
    return 0
  fi
  if (( ! script_is_run_interactively )); then
    if (( output_exists )); then
      echo "$(pgm_ts) Output already exists, skipping: ${output_file}"
    else
      echo "$(pgm_ts) Non-interactive: skipping group ${group_num} (use -y to merge all)."
    fi
    REPLY=skip
    return 0
  fi
  while true; do
    if (( complete )); then
      echo "  [N] Skip — keep output and input files (default)"
      echo "  [a] Already merged — don't ask again this run"
      echo "  [r] Redo merge — replace output file"
      echo "  [p] Preview merge seams in terminal"
      echo "  [d] Delete input chapter files — keep merged output; you confirm before delete"
      echo "  [q] Quit"
      pgm_read_key "Already merged — group ${group_num}/${group_total} [N/a/r/p/d/q]: " n
      choice="${REPLY,,}"
      case "$choice" in
        ''|n)  REPLY=skip; pgm_log_kv "Action" "Keeping existing output and inputs."; return 0 ;;
        a)
          SKIP_MERGED_PROMPTS=1
          echo "$(pgm_ts) Already-merged groups will not be asked about again this run."
          REPLY=skip
          pgm_log_kv "Action" "Keeping existing output and inputs."
          return 0
          ;;
        r)     REPLY=redo; return 0 ;;
        p)     REPLY=preview_seams; return 0 ;;
        d)     REPLY=delete_inputs; return 0 ;;
        q)     REPLY=quit; return 0 ;;
        *)     echo "$(pgm_ts) Unknown choice: ${REPLY}" ;;
      esac
    elif (( output_exists && can_gpx )); then
      echo "  [Y] Generate the GPX beside the merged file (default)"
      echo "  [n] Skip — leave the merged file without a GPX"
      echo "  [r] Redo merge — replace output file"
      echo "  [p] Preview merge seams in terminal"
      echo "  [d] Delete input chapter files — keep merged output; you confirm before delete"
      echo "  [a] Skip all remaining groups"
      echo "  [q] Quit"
      if (( short_n )); then
        pgm_read_key "Short clip in this group. Generate the GPX anyway? [Y/n/r/p/d/a/q]: " y
      else
        pgm_read_key "No GPX beside the merged file — group ${group_num}/${group_total} [Y/n/r/p/d/a/q]: " y
      fi
      choice="${REPLY,,}"
      case "$choice" in
        ''|y)  REPLY=write_gpx; return 0 ;;
        n)     REPLY=skip; pgm_log_kv "Action" "Leaving the merged file without a GPX."; return 0 ;;
        r)     REPLY=redo; return 0 ;;
        p)     REPLY=preview_seams; return 0 ;;
        d)     REPLY=delete_inputs; return 0 ;;
        a)     REPLY=skip_all; return 0 ;;
        q)     REPLY=quit; return 0 ;;
        *)     echo "$(pgm_ts) Unknown choice: ${REPLY}" ;;
      esac
    elif (( output_exists )); then
      if (( ! gpx_ok )); then
        echo "$(pgm_ts) Merged file is here, but the GPX is missing and there is no GPSData*.txt to build it."
      fi
      echo "  [N] Skip — keep output and input files (default)"
      echo "  [a] Already merged — don't ask again this run"
      echo "  [r] Redo merge — replace output file"
      echo "  [p] Preview merge seams in terminal"
      echo "  [d] Delete input chapter files — keep merged output; you confirm before delete"
      echo "  [q] Quit"
      pgm_read_key "Already merged — group ${group_num}/${group_total} [N/a/r/p/d/q]: " n
      choice="${REPLY,,}"
      case "$choice" in
        ''|n)  REPLY=skip; pgm_log_kv "Action" "Keeping existing output and inputs."; return 0 ;;
        a)
          SKIP_MERGED_PROMPTS=1
          echo "$(pgm_ts) Already-merged groups will not be asked about again this run."
          REPLY=skip
          pgm_log_kv "Action" "Keeping existing output and inputs."
          return 0
          ;;
        r)     REPLY=redo; return 0 ;;
        p)     REPLY=preview_seams; return 0 ;;
        d)     REPLY=delete_inputs; return 0 ;;
        q)     REPLY=quit; return 0 ;;
        *)     echo "$(pgm_ts) Unknown choice: ${REPLY}" ;;
      esac
    else
      echo "  [Y] Merge this group (default)"
      echo "  [n] Skip this group"
      echo "  [a] Skip all remaining groups"
      echo "  [m] Merge all remaining groups"
      echo "  [q] Quit"
      if (( short_n )); then
        pgm_read_key "Short clip in this group. Merge anyway? [Y/n/a/m/q]: " y
      else
        pgm_read_key "Choice for group ${group_num}/${group_total} [Y/n/a/m/q]: " y
      fi
      choice="${REPLY,,}"
      case "$choice" in
        ''|y)  REPLY=merge; return 0 ;;
        n)     REPLY=skip; return 0 ;;
        a)     REPLY=skip_all; return 0 ;;
        m)     REPLY=merge_all; return 0 ;;
        q)     REPLY=quit; return 0 ;;
        *)     echo "$(pgm_ts) Unknown choice: ${REPLY}" ;;
      esac
    fi
  done
}

# Recording-time sort key: filename YYYYMMDD_HHMMSS when present, else filesystem mtime.
# Tie-break: chapter letter, numeric part / raw chapter, then basename (oldest first).
file_age_sort_key() {
  local f="$1" base parse_base date="" time="" letter="_" part=0 p epoch stamp
  base="${f##*/}"
  if gopro_timestamp_cam_from_basename "$base"; then
    date="$GOPRO_TS_DATE"
    time="$GOPRO_TS_TIME"
    [[ -n "${GOPRO_TS_LETTER}" ]] && letter="${GOPRO_TS_LETTER,,}"
  elif part_chapter_parse "$base"; then
    parse_base="$(part_chapter_gopro_parse_base "$base" 2>/dev/null || true)"
    if [[ -n "$parse_base" ]] && gopro_timestamp_cam_from_basename "$parse_base"; then
      date="$GOPRO_TS_DATE"
      time="$GOPRO_TS_TIME"
      [[ -n "${GOPRO_TS_LETTER}" ]] && letter="${GOPRO_TS_LETTER,,}"
    fi
  elif dashcam_parse_basename "$base"; then
    date="$DASHCAM_DATE"
    time="$DASHCAM_TIME"
    part="$DASHCAM_SEQ"
  fi
  if [[ -z "$date" || -z "$time" ]]; then
    epoch="$(stat -c %Y -- "$f" 2>/dev/null || stat -f %m -- "$f" 2>/dev/null || printf '0')"
    stamp="$(date -d "@${epoch}" +%Y%m%d_%H%M%S 2>/dev/null \
      || date -r "${epoch}" +%Y%m%d_%H%M%S 2>/dev/null \
      || printf '00000000_000000')"
    date="${stamp%%_*}"
    time="${stamp##*_}"
    letter="_"
  fi
  if p="$(chapter_part_from_basename "$base" 2>/dev/null)"; then
    part="$p"
  elif gopro_raw_chapter_parse "$base"; then
    part=$((10#$RAW_GP_CHAPTER))
  fi
  printf '%s_%s_%s_%06d_%s\n' "$date" "$time" "$letter" "$part" "$base"
}

# Rewrite _out as paths from oldest to newest.
sort_paths_oldest_to_newest() {
  local -n _out=$1
  shift
  local -a files=("$@")
  local f
  if (( ${#files[@]} < 2 )); then
    _out=("${files[@]}")
    return 0
  fi
  mapfile -t _out < <(
    for f in "${files[@]}"; do
      printf '%s\t%s\n' "$(file_age_sort_key "$f")" "$f"
    done | LC_ALL=C sort -t $'\t' -k1,1 | cut -f2-
  )
}

# Each blob's files oldest→newest, then blobs by their oldest file.
# Chapter plan and merge prompts both use this order.
sort_group_blobs_oldest_to_newest() {
  local -a sorted_store=() order_lines=() files=() sorted_files=()
  local blob i=0 idx oldest_key
  (( ${#GROUP_BLOBS[@]} )) || return 0
  for blob in "${GROUP_BLOBS[@]}"; do
    group_files_to_array "$blob" files
    sort_paths_oldest_to_newest sorted_files "${files[@]}"
    if (( ${#sorted_files[@]} )); then
      sorted_store+=("$(printf '%s\n' "${sorted_files[@]}")")
      oldest_key="$(file_age_sort_key "${sorted_files[0]}")"
    else
      sorted_store+=("$blob")
      oldest_key="~"
    fi
    order_lines+=("${oldest_key}"$'\t'"${i}")
    (( i++ )) || true
  done
  GROUP_BLOBS=()
  while IFS=$'\t' read -r _ idx; do
    [[ "$idx" =~ ^[0-9]+$ ]] || continue
    GROUP_BLOBS+=("${sorted_store[$idx]}")
  done < <(printf '%s\n' "${order_lines[@]}" | LC_ALL=C sort -t $'\t' -k1,1)
}

# Human date and time: filename YYYYMMDD_HHMMSS when present, else filesystem mtime.
file_recording_timestamp_display() {
  local f="$1" base parse_base date="" time="" epoch stamp
  base="${f##*/}"
  if gopro_timestamp_cam_from_basename "$base"; then
    date="$GOPRO_TS_DATE"
    time="$GOPRO_TS_TIME"
  elif part_chapter_parse "$base"; then
    parse_base="$(part_chapter_gopro_parse_base "$base" 2>/dev/null || true)"
    if [[ -n "$parse_base" ]] && gopro_timestamp_cam_from_basename "$parse_base"; then
      date="$GOPRO_TS_DATE"
      time="$GOPRO_TS_TIME"
    fi
  elif dashcam_parse_basename "$base"; then
    date="$DASHCAM_DATE"
    time="$DASHCAM_TIME"
  fi
  if [[ ${#date} -eq 8 && ${#time} -eq 6 ]]; then
    printf '%s-%s-%s %s:%s:%s\n' \
      "${date:0:4}" "${date:4:2}" "${date:6:2}" \
      "${time:0:2}" "${time:2:2}" "${time:4:2}"
    return 0
  fi
  epoch="$(stat -c %Y -- "$f" 2>/dev/null || stat -f %m -- "$f" 2>/dev/null || printf '0')"
  stamp="$(date -d "@${epoch}" +%Y-%m-%d_%H:%M:%S 2>/dev/null \
    || date -r "${epoch}" +%Y-%m-%d_%H:%M:%S 2>/dev/null \
    || printf '0000-00-00_00:00:00')"
  printf '%s %s\n' "${stamp%%_*}" "${stamp##*_}"
}

# After the input/output lists: boxed file count, first/last name, start/finish/length.
# Values share one column. Title is centered when boxes is not installed.
print_merge_summary_box() {
  local title="$1"
  shift
  local -a rows=("$@")
  local line width=0 pad title_line bar
  (( ${#rows[@]} > 0 )) || return 0
  for line in "$title" "${rows[@]}"; do
    (( ${#line} > width )) && width=${#line}
  done
  if type -fP boxes >/dev/null 2>&1; then
    printf '%s\n' "$title" "${rows[@]}" | boxes -a l -d ada-box
    return 0
  fi
  pad=$(( (width - ${#title}) / 2 ))
  (( pad < 0 )) && pad=0
  title_line="$(printf '%*s%s' "$pad" '' "$title")"
  bar="$(printf '%*s' "$((width + 2))" '' | tr ' ' '-')"
  echo "+${bar}+"
  printf '| %-*s |\n' "$width" "$title_line"
  for line in "${rows[@]}"; do
    printf '| %-*s |\n' "$width" "$line"
  done
  echo "+${bar}+"
}

print_merge_group_sequence_summary() {
  local group_num="$1" group_total="$2"
  shift 2
  local -a files=("$@")
  local n first last start_ts finish_ts total=0 len_disp f d
  local -a rows=()
  n=${#files[@]}
  (( n > 0 )) || return 0
  first="${files[0]##*/}"
  last="${files[-1]##*/}"
  start_ts=$(file_recording_timestamp_display "${files[0]}")
  finish_ts=$(file_recording_timestamp_display "${files[-1]}")
  for f in "${files[@]}"; do
    if d=$(ffprobe_duration_seconds "$f" 2>/dev/null) && [[ -n "$d" ]]; then
      total=$(awk -v a="$total" -v b="$d" 'BEGIN{printf "%.3f", a+b}')
    fi
  done
  if awk -v d="$total" 'BEGIN{exit !(d>0)}'; then
    len_disp=$(format_duration_hms_display "$total")
  else
    len_disp="—"
  fi
  rows+=("$(printf '%-8s%s' "Files:" "$n")")
  rows+=("$(printf '%-8s%s' "First:" "$first")")
  rows+=("$(printf '%-8s%s' "Last:" "$last")")
  rows+=("$(printf '%-8s%s' "Start:" "$start_ts")")
  rows+=("$(printf '%-8s%s' "Finish:" "$finish_ts")")
  rows+=("$(printf '%-8s%s' "Length:" "$len_disp")")
  rows+=("$(printf '%-8s%s' "Inputs:" "$(merge_inputs_dir "${files[0]}")")")
  if [[ -n "${MERGE_TEMP_FOR_RUN:-}" ]]; then
    rows+=("$(printf '%-8s%s' "Temp:" "${MERGE_TEMP_FOR_RUN} (for the rest of this run)")")
  elif (( ${MERGE_IN_PLACE_FOR_RUN:-0} )); then
    rows+=("$(printf '%-8s%s' "Temp:" "not used, writing in this directory")")
  fi
  print_merge_summary_box "Merge group ${group_num} of ${group_total}" "${rows[@]}"
}

show_merge_group_detail() {
  local group_num="$1" group_total="$2"
  shift 2
  local -a files=("$@")
  local output_file
  output_file=$(group_output_file "${files[@]}")
  echo
  echo "=== Merge group ${group_num} of ${group_total} (${#files[@]} parts) ==="
  print_merge_group_io_block "$output_file" "${files[@]}"
  if group_is_dashcam "${files[@]}"; then
    print_dashcam_gpx_suggestion "$output_file" '  '
  fi
  echo
  print_merge_group_sequence_summary "$group_num" "$group_total" "${files[@]}"
  if group_is_dashcam "${files[@]}"; then
    dashcam_print_short_clip_notice "${files[@]}"
  fi
  echo
}

# When merged 70mai files have no GPX, offer to write only those GPX files.
# $1 is the skip map. The rest are the MP4s in this directory.
# A merged file is included even when its clips are no longer here.
# Returns 1 when the user quits.
dashcam_offer_gpx_only() {
  local -n _skip=$1
  shift
  local -a all=("$@")
  local f base gpx found n i choice have_logs any_clips
  local -a gpx_outs=() has_clips=() uncovered=()
  DASHCAM_OFFER_SAID=0
  have_logs=0
  dashcam_gps_logs >/dev/null && have_logs=1
  for f in "${all[@]}"; do
    base="${f##*/}"
    is_concat_output_basename "$base" || continue
    concat_parse_dashcam_output "$base" || continue
    gpx=$(dashcam_gpx_beside_output "$f")
    dashcam_gpx_is_valid "$gpx" && continue
    if (( ! have_logs )); then
      uncovered+=("$f")
      continue
    fi
    gpx_outs+=("$f")
    found=$(count_dashcam_chapters_in_window \
      "$CONCAT_DASH_START" "$CONCAT_DASH_END" "$CONCAT_DASH_LETTER" "${all[@]}")
    if (( found > 0 )); then
      has_clips+=(1)
    else
      has_clips+=(0)
    fi
  done
  n=${#gpx_outs[@]}
  if (( n == 0 )); then
    if (( ${#uncovered[@]} )); then
      DASHCAM_OFFER_SAID=1
      dashcam_warn_no_gps || return 1
    fi
    return 0
  fi
  DASHCAM_OFFER_SAID=1
  echo
  if (( n == 1 )); then
    echo "1 merged file has no GPX. The video will not be merged again."
  else
    echo "${n} merged files have no GPX. The videos will not be merged again."
  fi
  echo
  for i in "${!gpx_outs[@]}"; do
    gpx=$(dashcam_gpx_beside_output "${gpx_outs[$i]}")
    printf '  %s\n' "${gpx_outs[$i]##*/}"
    printf '      %s\n' "${gpx##*/}"
  done
  echo
  echo "  [G] Create only these GPX files (default)"
  echo "  [e] Ask about each file"
  echo "  [n] Skip these files"
  echo "  [q] Quit"
  if (( DO_YES )) || (( ! script_is_run_interactively )); then
    choice=g
    echo "$(pgm_ts) Create only these GPX files."
  else
    while true; do
      pgm_read_key "Create only these GPX files? [G/e/n/q]: " g
      choice="${REPLY,,}"
      case "$choice" in
        g|e|n|q) break ;;
        *) echo "That is not a choice." ;;
      esac
    done
  fi
  case "$choice" in
    g)
      for i in "${!gpx_outs[@]}"; do
        dashcam_write_gpx_from_concat "${gpx_outs[$i]}"
        _skip["${gpx_outs[$i]##*/}"]=1
      done
      echo "$(pgm_ts) Created only the GPX files. The merged videos were kept."
      ;;
    e)
      any_clips=0
      for i in "${!gpx_outs[@]}"; do
        if (( has_clips[i] )); then
          any_clips=1
          continue
        fi
        echo
        printf '  %s\n' "${gpx_outs[$i]##*/}"
        echo "  [Y] Create this GPX (default)"
        echo "  [n] Skip this file"
        echo "  [q] Quit"
        while true; do
          pgm_read_key "Create this GPX? [Y/n/q]: " y
          case "${REPLY,,}" in
            y)
              dashcam_write_gpx_from_concat "${gpx_outs[$i]}"
              _skip["${gpx_outs[$i]##*/}"]=1
              break
              ;;
            n)
              _skip["${gpx_outs[$i]##*/}"]=1
              echo "$(pgm_ts) Skipped ${gpx_outs[$i]##*/}."
              break
              ;;
            q)
              echo "$(pgm_ts) Quit."
              return 1
              ;;
            *) echo "That is not a choice." ;;
          esac
        done
      done
      if (( any_clips )); then
        echo "$(pgm_ts) Each file that still has its clips will be asked about."
      fi
      ;;
    n)
      for f in "${gpx_outs[@]}"; do
        _skip["${f##*/}"]=1
      done
      echo "$(pgm_ts) Skipped these files. No GPX was written."
      ;;
    q)
      echo "$(pgm_ts) Quit."
      return 1
      ;;
  esac
  return 0
}

do_merge() {
  local merger rc=0 group_num=0 mergeable_total=0
  local blob action
  local -a files=() mergeable_blobs=()
  merger=$(find_merger) || {
    mp4_merge_print_not_found_help
    if ! prompt_install_mp4_merge_now; then
      return 1
    fi
    merger=$(find_merger) || {
      echo "$(pgm_ts) mp4_merge is still not available after the install attempt — cannot merge." >&2
      return 1
    }
  }
  merger=$(resolve_merger_path_for_merge "$merger") || {
    local resolve_rc=$?
    if (( resolve_rc == 2 )); then
      return 0
    fi
    return 1
  }

  local sorted_mp4=()
  local codec_skip=0
  if (( FORCE_MERGE )); then
    GROUP_BLOBS=( "$(printf '%s\n' "${FORCE_MERGE_FILES[@]}")" )
    sorted_mp4=( "${FORCE_MERGE_FILES[@]}" )
  else
    shopt -s nullglob nocaseglob
    local mp4_files=( *.mp4 )
    shopt -u nocaseglob

    if (( ${#mp4_files[@]} == 0 )); then
      echo "$(pgm_ts) No *.mp4 files in $(pwd)" >&2
      return 1
    fi

    mapfile -t sorted_mp4 < <(printf '%s\n' "${mp4_files[@]}" | LC_ALL=C sort)

    build_chapter_groups "${sorted_mp4[@]}"
    sort_group_blobs_oldest_to_newest
  fi

  MERGE_ALL_REMAINING=0
  SKIP_ALL_REMAINING=0
  MERGE_TEMP_FOR_RUN=""
  MERGE_IN_PLACE_FOR_RUN=0
  SEAM_PREVIEW_SKIP_RUN=0
  KEEP_INPUTS_FOR_RUN=0
  SKIP_MERGED_PROMPTS=0

  print_group_plan "${sorted_mp4[@]}"

  local -A GPX_BATCH_SKIP=()
  if (( ! FORCE_MERGE )); then
    dashcam_offer_gpx_only GPX_BATCH_SKIP "${sorted_mp4[@]}" || return 1
  fi

  if (( ${#GROUP_BLOBS[@]} == 0 )); then
    if (( ! DASHCAM_OFFER_SAID )); then
      echo "$(pgm_ts) No chapter input MP4s in $(pwd)."
    fi
    return 0
  fi

  for blob in "${GROUP_BLOBS[@]}"; do
    group_files_to_array "$blob" files
    if (( ${#files[@]} >= 2 )); then
      if merge_group_assert_codecs "${files[@]}"; then
        mergeable_blobs+=("$blob")
      else
        (( codec_skip++ )) || true
        if (( FORCE_MERGE )); then
          return 1
        fi
        echo "$(pgm_ts) Skipping this group (incompatible tracks)."
        echo
      fi
    fi
  done
  mergeable_total=${#mergeable_blobs[@]}

  if (( mergeable_total == 0 )); then
    if (( codec_skip > 0 )); then
      echo "$(pgm_ts) No mergeable groups left after the track-compatibility check (${codec_skip} skipped)."
      return 1
    fi
    if (( ! DASHCAM_OFFER_SAID )); then
      echo "$(pgm_ts) No multi-part chapter groups to merge."
      echo "$(pgm_ts) Tip: sequential GoPro clips (_part_01… with chaining timestamps, bare _Timelapse chapters without _part_XX, YYYYMMDD_HHMMSS_… ~4 GB / ~12 GB, a/b/c letter suffixes, or 70mai NOYYYYMMDD-HHMMSS-NNNNNNX journeys) may be mergeable chapters."
      echo "$(pgm_ts) Or name the files on the command line to force a merge in that order."
    fi
    return 0
  fi

  local need_gps=0
  for blob in "${mergeable_blobs[@]}"; do
    group_files_to_array "$blob" files
    group_is_dashcam "${files[@]}" || continue
    output_file=$(group_output_file "${files[@]}")
    if ! dashcam_gpx_is_valid "$(dashcam_gpx_beside_output "$output_file")"; then
      need_gps=1
      break
    fi
  done
  if (( need_gps )) && ! dashcam_gps_logs >/dev/null; then
    dashcam_warn_no_gps || return 1
  fi

  mergeable_total=0
  for blob in "${mergeable_blobs[@]}"; do
    group_files_to_array "$blob" files
    output_file=$(group_output_file "${files[@]}")
    [[ -n "${GPX_BATCH_SKIP[$output_file]:-}" ]] && continue
    (( mergeable_total++ )) || true
  done
  if (( mergeable_total == 0 )); then
    return 0
  fi

  for blob in "${mergeable_blobs[@]}"; do
    group_files_to_array "$blob" files
    output_file=$(group_output_file "${files[@]}")
    if [[ -n "${GPX_BATCH_SKIP[$output_file]:-}" ]]; then
      continue
    fi
    (( group_num++ )) || true
    show_merge_group_detail "$group_num" "$mergeable_total" "${files[@]}"
    prompt_merge_group_action "$group_num" "$mergeable_total" "$output_file" "${files[@]}"
    action=$REPLY
    case "$action" in
      merge)
        run_merge_group "$merger" 0 "${files[@]}" || rc=$?
        if (( rc == 2 )); then
          echo "$(pgm_ts) Quit at group ${group_num}."
          return "${rc}"
        fi
        ;;
      redo)
        run_merge_group "$merger" 1 "${files[@]}" || rc=$?
        if (( rc == 2 )); then
          echo "$(pgm_ts) Quit at group ${group_num}."
          return "${rc}"
        fi
        ;;
      delete_inputs)
        if [[ -e "$output_file" ]]; then
          dashcam_write_gpx_if_merged "$output_file" "${files[@]}"
          prompt_delete_merged_inputs already_merged "$output_file" "${files[@]}" || rc=$?
          if (( rc == 2 )); then
            echo "$(pgm_ts) Quit at group ${group_num}."
            return "${rc}"
          fi
        else
          echo "$(pgm_ts) No merged output for group ${group_num}; cannot delete inputs here." >&2
        fi
        ;;
      skip)
        if [[ -e "$output_file" ]]; then
          print_merge_boundaries_report "$output_file" "${files[@]}"
        else
          echo "$(pgm_ts) Skipped group ${group_num}."
        fi
        ;;
      preview_seams)
        if [[ -e "$output_file" ]]; then
          dashcam_write_gpx_if_merged "$output_file" "${files[@]}"
          print_merge_boundaries_report "$output_file" "${files[@]}"
          prompt_seam_terminal_previews --force "$output_file" "${files[@]}" || rc=$?
          if (( rc == 2 )); then
            echo "$(pgm_ts) Quit at group ${group_num}."
            return "${rc}"
          fi
        else
          echo "$(pgm_ts) No merged output for group ${group_num}; cannot preview seams." >&2
        fi
        ;;
      skip_all)
        SKIP_ALL_REMAINING=1
        echo "$(pgm_ts) Skipping remaining groups."
        ;;
      merge_all)
        MERGE_ALL_REMAINING=1
        if [[ -e "$output_file" ]]; then
          dashcam_write_gpx_if_merged "$output_file" "${files[@]}"
          echo "$(pgm_ts) Keeping existing output for group ${group_num}."
        else
          run_merge_group "$merger" 0 "${files[@]}" || rc=$?
          if (( rc == 2 )); then
            echo "$(pgm_ts) Quit at group ${group_num}."
            return "${rc}"
          fi
        fi
        ;;
      write_gpx)
        dashcam_write_gpx_if_merged "$output_file" "${files[@]}"
        ;;
      quit)
        echo "$(pgm_ts) Quit at group ${group_num}."
        return "${rc}"
        ;;
    esac
    echo
  done

  return "${rc}"
}

# --- parse options (header sourced first so -v can call print_version_banner) ---
DO_UPDATE=0
DO_YES=0
FORCE_MERGE=0
FORCE_MERGE_FILES=()
FORCE_MERGE_PLUS_N=0
MERGE_ALL_REMAINING=0
SKIP_ALL_REMAINING=0
GROUP_BLOBS=()
. "${profile_location_dir:-$HOME}/bin/_script_header.sh"

# Remember where the seam-preview values came from, so "=== Run settings ===" can tell
# env/default apart from an explicit flag (set below in the --seam-* branches).
PGM_SEAM_BEFORE_FROM_ENV=0
PGM_SEAM_AFTER_FROM_ENV=0
[[ -n "${PGM_SEAM_PREVIEW_BEFORE:-}" ]] && PGM_SEAM_BEFORE_FROM_ENV=1
[[ -n "${PGM_SEAM_PREVIEW_AFTER:-}" ]] && PGM_SEAM_AFTER_FROM_ENV=1
PGM_SEAM_BEFORE_CLI=0
PGM_SEAM_AFTER_CLI=0
PGM_MERGE_TEMP_FROM_ENV=0
PGM_MERGE_TEMP_CLI=0
[[ -n "${PGM_MERGE_TEMP:-}" ]] && PGM_MERGE_TEMP_FROM_ENV=1
GPS_DIRS=()
FORCE_MERGE_ARGS=()

PGM_SEAM_PREVIEW_BEFORE="${PGM_SEAM_PREVIEW_BEFORE:-1}"
PGM_SEAM_PREVIEW_AFTER="${PGM_SEAM_PREVIEW_AFTER:-1}"
PGM_SEAM_PREVIEW_WIDTH="${PGM_SEAM_PREVIEW_WIDTH-100}"
PGM_SEAM_PREVIEW_HEIGHT="${PGM_SEAM_PREVIEW_HEIGHT-40}"
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
    --history)
      print_script_history
      exit 0
      ;;
    -u|--update)
      DO_UPDATE=1
      shift
      ;;
    -y|--yes)
      DO_YES=1
      shift
      ;;
    --read-timeout)
      if [[ -z "${2:-}" || ! "$2" =~ ^[0-9]+$ ]]; then
        echo "$(pgm_ts) --read-timeout requires a non-negative integer (seconds)." >&2
        exit 1
      fi
      PGM_READ_TIMEOUT="$2"
      PGM_READ_TIMEOUT_CLI=1
      shift 2
      ;;
    --read-timeout=*)
      PGM_READ_TIMEOUT="${1#*=}"
      if [[ ! "$PGM_READ_TIMEOUT" =~ ^[0-9]+$ ]]; then
        echo "$(pgm_ts) --read-timeout requires a non-negative integer (seconds)." >&2
        exit 1
      fi
      PGM_READ_TIMEOUT_CLI=1
      shift
      ;;
    --seam-before)
      [[ $# -ge 2 ]] || pgm_invalid_seam_seconds "seam-before" ""
      pgm_valid_seam_seconds "$2" || pgm_invalid_seam_seconds "seam-before" "$2"
      PGM_SEAM_PREVIEW_BEFORE="$2"
      PGM_SEAM_BEFORE_CLI=1
      shift 2
      ;;
    --seam-before=*)
      PGM_SEAM_PREVIEW_BEFORE="${1#*=}"
      pgm_valid_seam_seconds "$PGM_SEAM_PREVIEW_BEFORE" \
        || pgm_invalid_seam_seconds "seam-before" "$PGM_SEAM_PREVIEW_BEFORE"
      PGM_SEAM_BEFORE_CLI=1
      shift
      ;;
    --seam-after)
      [[ $# -ge 2 ]] || pgm_invalid_seam_seconds "seam-after" ""
      pgm_valid_seam_seconds "$2" || pgm_invalid_seam_seconds "seam-after" "$2"
      PGM_SEAM_PREVIEW_AFTER="$2"
      PGM_SEAM_AFTER_CLI=1
      shift 2
      ;;
    --seam-after=*)
      PGM_SEAM_PREVIEW_AFTER="${1#*=}"
      pgm_valid_seam_seconds "$PGM_SEAM_PREVIEW_AFTER" \
        || pgm_invalid_seam_seconds "seam-after" "$PGM_SEAM_PREVIEW_AFTER"
      PGM_SEAM_AFTER_CLI=1
      shift
      ;;
    --gps-dir)
      if [[ -z "${2:-}" ]]; then
        echo "$(pgm_ts) --gps-dir requires a directory path." >&2
        exit 1
      fi
      GPS_DIRS+=("$2")
      shift 2
      ;;
    --gps-dir=*)
      if [[ -z "${1#*=}" ]]; then
        echo "$(pgm_ts) --gps-dir requires a directory path." >&2
        exit 1
      fi
      GPS_DIRS+=("${1#*=}")
      shift
      ;;
    --temp-dir)
      if [[ -z "${2:-}" ]]; then
        echo "$(pgm_ts) --temp-dir requires a directory path." >&2
        exit 1
      fi
      PGM_MERGE_TEMP="$2"
      PGM_MERGE_TEMP_CLI=1
      shift 2
      ;;
    --temp-dir=*)
      PGM_MERGE_TEMP="${1#*=}"
      if [[ -z "$PGM_MERGE_TEMP" ]]; then
        echo "$(pgm_ts) --temp-dir requires a directory path." >&2
        exit 1
      fi
      PGM_MERGE_TEMP_CLI=1
      shift
      ;;
    --)
      shift
      FORCE_MERGE_ARGS+=("$@")
      break
      ;;
    -*)
      echo "$(pgm_ts) Unknown argument: $1" >&2
      echo "Try: $(script_live_basename) --help" >&2
      exit 1
      ;;
    *)
      FORCE_MERGE_ARGS+=("$1")
      shift
      ;;
  esac
done

if (( ${#FORCE_MERGE_ARGS[@]} > 0 )); then
  if (( DO_UPDATE )); then
    echo "$(pgm_ts) Do not pass video files with -u/--update." >&2
    exit 1
  fi
  if (( ${#FORCE_MERGE_ARGS[@]} == 2 )) && [[ "${FORCE_MERGE_ARGS[1]}" =~ ^\+[1-9][0-9]*$ ]]; then
    pgm_resolve_force_merge_plus_n "${FORCE_MERGE_ARGS[0]}" "${FORCE_MERGE_ARGS[1]}" || exit 1
  elif (( ${#FORCE_MERGE_ARGS[@]} == 1 )); then
    echo "$(pgm_ts) Forced merge needs two or more MP4 files, or FILE +N (e.g. clip.mp4 +2)." >&2
    exit 1
  else
    pgm_resolve_force_merge_files "${FORCE_MERGE_ARGS[@]}" || exit 1
  fi
fi

pgm_init_read_timeout

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MP4_MERGE_SYSTEM_DIR="${MP4_MERGE_SYSTEM_DIR:-/usr/local/bin}"
MP4_MERGE_INSTALL_DIR="${MP4_MERGE_INSTALL_DIR:-${MP4_MERGE_SYSTEM_DIR}}"

if [[ -f "${BASH_SOURCE[0]}" ]]; then
  chmod 700 "${BASH_SOURCE[0]}" 2>/dev/null || true
fi

pgm_record_script_start

print_version_banner

pgm_print_run_settings

if (( script_is_run_interactively )) && ! (( DO_YES )); then
  if pgm_read_timeout_is_limited; then
    pgm_log_kv "Prompt timeout" "${PGM_READ_TIMEOUT} s per key (then default choice)"
  else
    pgm_log_kv "Prompt timeout" "none (wait for keypress)"
  fi
fi

if (( DO_UPDATE )); then
  update_mp4_merge
  return_code=$?
  print_pgm_timing_summary
  . "${profile_location_dir:-$HOME}/bin/_script_footer.sh"
  exit "${return_code}"
fi

do_merge
return_code=$?

print_pgm_timing_summary

. "${profile_location_dir:-$HOME}/bin/_script_footer.sh"

exit "${return_code}"
