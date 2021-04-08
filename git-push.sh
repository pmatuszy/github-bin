# 2021.02.18 - v. 0.7 - added exit code check after git push
# 2021.02.07 - v. 0.6 - git add --all * .[a-zA-Z]* , git remote set-url origin git+ssh: to not have
# 2021.02.07 - v. 0.6 - git add --all * .[a-zA-Z]* , git remote set-url origin git+ssh: to not have
#                       password prompts during pushes
# 2021.02.05 - v. 0.5 - git add --all * .[a-zA-Z]* 
# 2021.02.03 - v. 0.4 - added commit "-a" option so deleted files will be deleted from repo as well
# 2020.11.27 - v. 0.3 - changed rm to remove files from the directory not the whole directory
# 2020.11.26 - v. 0.2 - added second section with 'git pull'
# 2020.10.20 - v. 0.1 - initial release

github_project_name=`pwd`
github_project_name=`basename $github_project_name`

echo ; echo "github_project_name = $github_project_name"; echo

git remote set-url origin git+ssh://git@github.com/pmatuszy/${github_project_name}.git

echo "Do you want to do git push? [y/N]"
read -t 5 -n 1 p     # read one character (-n) with timeout of 5 seconds
echo
echo
if [ "${p}" == 'y' -o  "${p}" == 'y' ]; then
  git add --all * .[a-zA-Z]*
  git commit -a -m \""new push from `hostname` @ `date '+%Y.%m.%d %H:%M:%S'`"\"
  git push
  if (( $? != 0 )); then
    echo ; echo 'nie moge zrobic pusha - wychodze' ; echo
    exit 2
  fi
else
  echo "no means no - I am exiting..."
  exit 1
fi
echo
echo

./git-pull.sh
