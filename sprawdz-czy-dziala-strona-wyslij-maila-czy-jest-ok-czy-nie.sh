if [ `wget yt2podcast.com:8080 -qO - |grep .xml|wc -l` -gt 0 ];then 
   echo dziala strona yt2podcast.com:8080 | strings | /usr/bin/mailx -s "(`hostname`) OK - strona yt2podcast.com:8080 dziala" matuszyk+`hostname`@matuszyk.com
else 
   echo "!!! NIE dziala strona yt2podcast.com:8080" | strings | /usr/bin/mailx -s "(`hostname`) PROBLEM - strona yt2podcast.com:8080 NIE dziala" matuszyk+`hostname`@matuszyk.com
fi
