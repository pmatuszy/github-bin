#!/usr/bin/env python3
"""Translate Polish changelog comments and rename Polish identifiers (scoped)."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

IDENTIFIER_REPLACEMENTS: list[tuple[str, str]] = [
    ("zrob_fsck", "run_fsck"),
    ("nazwa_pliku", "luks_file_path"),
    ("maska_plikow", "file_glob"),
    ("ile_plikow", "file_count"),
    ("jak_nowe_pliki_min", "fresh_files_minutes"),
    ("MAX_DOPUSZCZALNA_ZAJETOSC_SWAP", "MAX_ALLOWED_SWAP_MB"),
    ("ile_wolnego_RAM", "free_ram_mb"),
    ("ile_zajetego_SWAP", "swap_used_mb"),
    ("czy_jest_wolny_ram", "effective_free_ram_mb"),
    ("zamontuj_fs_MASTER", "mount_fs_master"),
    ("odmontuj_fs_MASTER", "umount_fs_master"),
    ("zamontuj_via_nfs", "mount_via_nfs"),
    ("opoznienie_miedzy_wywolaniami", "delay_between_runs"),
    ("opoznienie_1szy_raz", "delay_first_run"),
    ("sleep_1dyncze_opoznienie", "sleep_dynamic_delay"),
    ("ile_sek_przed_polnoca_nie_nagrywamy_juz", "seconds_before_midnight_stop"),
    ("ile_wiecej_sek_nagrywac", "extra_record_seconds"),
    ("wlasciciel_pliku", "file_owner"),
    ("plik_bez_cropa", "file_without_crop"),
    ("plik_po_cropie", "file_after_crop"),
    ("max_liczba_linii", "max_error_lines"),
    ("liczba_iteracji", "iteration_count"),
    ("czy_wysylac_maile", "send_email"),
    ("secs_nagrywania", "record_seconds"),
    ("dzien_wywolania", "invocation_day"),
    ("aktualny_dzien", "current_day"),
    ("bylo_zajete", "was_used_kb"),
    ("jest_zajete", "is_used_kb"),
    ("jest_wolne_kb", "free_kb"),
    ("jest_wolne_pc", "free_pct"),
    ("plik_template", "template_file"),
    ("DOKAD_PREFIX", "DEST_PREFIX"),
    ("SKAD_HOST", "SOURCE_HOST"),
    ("SKAD_DIR", "SOURCE_DIR"),
    ("DOKAD", "DEST"),
    ("SKAD", "SOURCE"),
    ("pierwszy_raz", "first_run"),
    ("maska_logow", "log_glob"),
    ("opoznienie", "delay_sec"),
    ("roznica", "delta_kb"),
    ("plik", "file"),
    ("katalog", "directory"),
    ("kopiuj", "copy_backup"),
]

IDENTIFIER_FILES = {
    p
    for p in ROOT.rglob("*.sh")
    if any(
        token in p.name
        for token in (
            "mount-encrypted",
            "umount-encrypted",
            "mount-nfs-lublin",
            "nagrywaj",
            "kopiuj",
            "sciagnij",
            "monitoruj-youtube",
            "spr-",
            "rotate-backups-nuci7b",
            "check-forever-for-lighttpd",
            "signal-daemon-log",
            "mount-cifs",
            "_oldy/mount-cifs",
        )
    )
    or p.name in {
        "smr-disks-timeout.sh",
        "mount-encrypted.sh",
        "healthchecks-swap-usage.sh",
    }
}

# Paths where `katalog` is a filesystem path fragment, not a variable name.
KATALOG_SKIP_FILES = {
    ROOT / "rename.sh",
}

CHANGELOG_PHRASES: list[tuple[str, str]] = [
    ("zmiana limitu MAX_ALLOWED_SWAP_MB", "changed MAX_ALLOWED_SWAP_MB limit"),
    ("zmiana limitu MAX_DOPUSZCZALNA_ZAJETOSC_SWAP", "changed MAX_ALLOWED_SWAP_MB limit"),
    ("zmiana w fsck, added function run_fsck", "fsck changes and added run_fsck helper"),
    ("zmiana w fsck, dodana funkcja zrob_fsck", "fsck changes and added run_fsck helper"),
    ("zmieniona zrob_fsck na nowsza - i wymuszenie fsck -y", "updated run_fsck and forced fsck -y"),
    ("added wywolanie healthchecka at the end", "added healthcheck call at the end"),
    ("added sprawdzenie czy dziala server vpn", "added VPN server check"),
    ("buffalo2 ma SMR dyski, wiec inaczej je montujemy", "buffalo2 has SMR disks so we mount them differently"),
    ("jesli scheduler = none to ponizsza linia zwraca blad", "if scheduler is none the line below returns an error"),
    ("dodalem wywolanie", "added call to"),
    ("dodalem obsluge healthcheckow", "added healthchecks support"),
    ("dodalem obsluge", "added support for"),
    ("dodalem wypisywanie aktualnej daty", "added printing of current date"),
    ("dodalem pbzip2 do monitorowanych komend", "added pbzip2 to monitored commands"),
    ("dodalem mc do monitorowanych komend", "added mc to monitored commands"),
    ("dodalem par2 do monitorowanych komend", "added par2 to monitored commands"),
    ("dodalem funkcje zamontuj_via_nfs", "added mount_via_nfs function"),
    ("dodalem funkcje", "added function"),
    ("dodalem trimowanie swapa", "added swap trimming"),
    ("dodalem", "added"),
    ("dodano random delay jesli skrypt jest wywolywany nieinteraktywnie", "added random delay when script runs non-interactively"),
    ("dodano random delay", "added random delay"),
    ("dodano montowanie", "added mounting of"),
    ("dodano czekanie jesli apt-get update jest wykonywany w tym samym czasie przez inny proces", "added wait when apt-get update runs concurrently in another process"),
    ("dodane 2>/dev/null po wywolaniu curl by nie dostawac maili z crona o timeoucie", "added 2>/dev/null after curl so cron does not mail about timeout"),
    ("dodane wyswietlanie numeru seryjnego dyskow", "added display of disk serial numbers"),
    ("dodane", "added"),
    ("dodana funkcja fsck, czytanie hasla do zmiennej", "added fsck function and password read into variable"),
    ("dodana funkcja", "added function"),
    ("dodana", "added"),
    ("zmiana formatu linii dla grep bo podnioslem wersje podsynca i zmienil sie message", "changed grep line format after podsync upgrade changed the message"),
    ("zmiana na krotsze nazwy skrypow bo screen sobie z dlugimi nie radzi, skrocony czas miedzy wywolaniami screena z 4m do 45s", "shorter script names for screen; reduced delay between screen invocations from 4m to 45s"),
    ("zmiana sprawdzania czy dzialamy interaktywnie", "changed interactive-run detection"),
    ("zmiana cutycapt na firefoxa bo nie generowala sie strona ladnie", "switched cutycapt to Firefox because page render was poor"),
    ("zmiana, by bylo jedno tylko pytanie o haslo", "single password prompt only"),
    ("zmiana watch na \"progress -M\"", "switched watch to progress -M"),
    ("zmiana schedulera z mq-deadline na none", "changed scheduler from mq-deadline to none"),
    ("zmiana nazwy komputera i dodano mkdir -p", "renamed host and added mkdir -p"),
    ("zmiana w fsck, dodana funkcja zrob_fsck", "fsck changes and added run_fsck helper"),
    ("exportfs po zamontowaniu obu duzych volumentow, dodano montowanie dla minidlna i restart tego serwisu", "exportfs after both large volumes mounted; added minidlna mount and service restart"),
    ("bug fix: nie montowane byly backup2 i replication2 w jailu", "bug fix: backup2 and replication2 were not mounted in jail"),
    ("bugfix: nie montowane", "bugfix: not mounted"),
    ("nie ograniczamy szybkosci bo uplink w CHE jest duzy", "no speed limit because CHE uplink is fast"),
    ("eliminacja curla by nie startowac", "removed curl so we do not start"),
    ("poprawne badanie kodu powrotu ffmpeg przez dodanie exit $?", "check ffmpeg exit code correctly via exit $?"),
    ("jak ffmpeg skonczy sie przedwczesnie to wprowadzilem opoznienie 60s", "if ffmpeg ends early, added 60s delay"),
    ("jak ffmpeg sie skonczy wczesniej to restartujemy nagrywanie do polnocy + 1 minuta", "if ffmpeg ends early, restart recording until midnight + 1 minute"),
    ("na poczatku petli", "at loop start"),
    ("na koncu petli", "at loop end"),
    ("opoznienie w sekundach po ktorych dopiero odwracamy zmiane pliku", "delay in seconds before reverting file change"),
    ("program nie generuje zadnego output na ekran", "program produces no screen output"),
    ("najpierw jest przeliczana md5 suma pliku plik_template", "md5 of template file is computed first"),
    ("ost sed zostawia tylko", "final sed keeps only"),
    ("w MB by zrobic trim ale zwrocic status ok a nie fail", "MB threshold to trim but return ok not fail"),
    ("w ten sposob swap jest zwalniany ale nie jest generowany alert do healthchecka", "swap is trimmed without triggering healthcheck alert"),
    ("mimo, ze nie przekracza limitu, ale jest mimo wszystko troche juz jego zaalokowanego", "even when under limit but partially allocated"),
    ("przed zmianami", "before changes"),
    ("po zmianach", "after changes"),
    ("wylaczam unifi server", "stopping unifi server"),
    ("wylaczone - dzialaja, ale nie sa montowane (kabel USB jest wyjety z huba USB", "disabled - present but not mounted (USB cable removed from hub"),
    ("na koncu", "at the end"),
    ("initial release, program nie generuje", "initial release, program produces no"),
]

POLISH_COMMENT_RE = re.compile(
    r"#.*(?:[ąćęłńóśźżĄĆĘŁŃÓŚŹŻ]|"
    r"\b(?:dodalem|dodano|dodane|dodana|zmiana|zmienil|jesli|wywol|haslo|obslug|"
    r"montow|opoznien|kosmetycz|przedwczes|polnoc|petli|katalog:|skad|dokad|"
    r"liczba|wylacz|demont|nie mont|nie ogranicz|eliminacja|poprawne badanie|"
    r"program nie|najpierw jest|ost sed|w MB by|w ten sposob|mimo, ze|przed zmian|"
    r"po zmian|exportfs po|bug fix: nie|redirecion|bez kropek|maska_logow|"
    r"dobre zroda|wylaczone - dzialaja))",
    re.IGNORECASE,
)


def rename_identifiers(text: str, path: Path) -> str:
    skip_katalog = path.resolve() in KATALOG_SKIP_FILES
    if "nagrywaj" in path.name:
        text = re.sub(r"\bnazwa_pliku\b", "output_filename", text)
    for old, new in IDENTIFIER_REPLACEMENTS:
        if skip_katalog and old == "katalog":
            continue
        if old == "nazwa_pliku" and "nagrywaj" in path.name:
            continue
        text = re.sub(rf"\b{re.escape(old)}\b", new, text)
    return text


def translate_comment_line(line: str) -> str:
    if not line.lstrip().startswith("#"):
        return line
    if not POLISH_COMMENT_RE.search(line):
        return line
    new_line = line
    for old, new in CHANGELOG_PHRASES:
        if old in new_line:
            new_line = new_line.replace(old, new)
    return new_line


def process_file(path: Path) -> bool:
    original = path.read_text(encoding="utf-8", errors="replace")
    newline = "\n"
    if "\r\n" in original:
        newline = "\r\n"
    lines = original.splitlines()
    changed = False
    out: list[str] = []
    do_identifiers = path.resolve() in {p.resolve() for p in IDENTIFIER_FILES}

    for line in lines:
        new_line = translate_comment_line(line)
        if do_identifiers:
            new_line = rename_identifiers(new_line, path)
        if new_line != line:
            changed = True
        out.append(new_line)

    if not changed:
        return False

    text = newline.join(out)
    if original.endswith(("\n", "\r\n")) and not text.endswith(newline):
        text += newline
    path.write_text(text, encoding="utf-8")
    return True


def main() -> None:
    changed: list[str] = []
    for path in sorted(ROOT.rglob("*.sh")):
        if ".git" in path.parts:
            continue
        if process_file(path):
            changed.append(str(path.relative_to(ROOT)))
    print(f"Updated {len(changed)} file(s)")
    for name in changed:
        print(name)


if __name__ == "__main__":
    main()
