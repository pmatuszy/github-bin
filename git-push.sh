# 2020.10.20 - v. 0.1 - initial release

echo "Do you want to do git push? [y/N]"
read -t 5 -n 1 p     # read one character (-n) with timeout of 5 seconds
echo
echo
if [ "${p}" == 'y' -o  "${p}" == 'y' ]; then
  git add *
  git commit -m \""new push from `hostname` @ `date '+%Y.%m.%d %H:%M:%S'`"\"
  git push
fi  
