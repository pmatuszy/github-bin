# 2026.04.21 - v. 0.2 - document purpose; indentation aligned with _script_header.sh
# 2020.09.15 - v. 0.1 - initial release

# Reset the GNU Screen window title to the neutral label "bash" after the calling
# script finishes. Runs only when STY is set. Uses tcScrTitleStart/End from _script_header.sh.

if [ ! -z ${STY:-} ]; then    # checking if we are running within screen
  # I am setting the screen window title to bash
  echo -ne "${tcScrTitleStart}bash${tcScrTitleEnd}"
fi
