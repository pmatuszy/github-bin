if [ `wget yt2podcast.com:8080 -qO - |grep .xml|wc -l` -eq 0 ];then 
   echo "!!! yt2podcast.com:8080 site is DOWN" | strings | aha | /usr/bin/mailx -r root@`hostname` -a 'Content-Type: text/html' -s "(`hostname --short`) PROBLEM - yt2podcast.com:8080 site is DOWN" matuszyk+`hostname`@matuszyk.com
fi
