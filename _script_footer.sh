# 2020.09.15 - v. 0.1 - initial release

if [ ! -z $STY ]; then    # checking if we are running within screen
	  # I am setting the screen window title to the script name
	    echo -ne "${tcScrTitleStart}bash${tcScrTitleEnd}"
fi

