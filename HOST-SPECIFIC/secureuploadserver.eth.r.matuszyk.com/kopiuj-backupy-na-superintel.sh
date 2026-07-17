# 2021.02.05 - v. 0.1 - initial release

source_dropbox="/mnt/server/DyskN/_backupy/DropBox"
destination_dropbox="/mnt/superintel/DyskS/____z_DyskU/_backupy-1dyne_kopie/DropBox"

source_praca="/mnt/server/DyskN/_backupy/praca/"
destination_praca="/mnt/superintel/DyskS/____z_DyskU/_backupy-1dyne_kopie/praca/"

echo ; echo
co=$source_dropbox
if [ ! -d "$co" ] ; then
   echo ; echo "$co does not exist" ; echo "EXITING ..."; echo
   exit 1
else
   echo "`date '+%Y.%m.%d %H:%M:%S'` - directory $co exists - OK"
fi

co=$destination_dropbox
if [ ! -d "$co" ] ; then
   echo ; echo "$co does not exist" ; echo "EXITING ..."; echo
   exit 1
else
   echo "`date '+%Y.%m.%d %H:%M:%S'` - directory $co exists - OK"
fi

co=$source_praca
if [ ! -d "$co" ] ; then
   echo ; echo "$co does not exist" ; echo "EXITING ..."; echo
   exit 1
else
   echo "`date '+%Y.%m.%d %H:%M:%S'` - directory $co exists - OK"
fi

co=$destination_praca
if [ ! -d "$co" ] ; then
   echo ; echo "$co does not exist" ; echo "EXITING ..."; echo
   exit 1
else
   echo "`date '+%Y.%m.%d %H:%M:%S'` - directory $co exists - OK"
fi
echo

source=$source_dropbox
destination=$destination_dropbox
cd $source
file=`/bin/ls -1tr *_Dropbox.rar | head -n 1`

####################################################################################
####################################################################################
copy_backup() {
####################################################################################
####################################################################################

echo "`date '+%Y.%m.%d %H:%M:%S'` - ******************************************"
echo "`date '+%Y.%m.%d %H:%M:%S'` - ****************** COPY ****************"
echo "`date '+%Y.%m.%d %H:%M:%S'` - \$1 = $1"
echo "`date '+%Y.%m.%d %H:%M:%S'` - \$2 = $2"
echo "`date '+%Y.%m.%d %H:%M:%S'` - \$3 = $3"
echo "`date '+%Y.%m.%d %H:%M:%S'` - ******************************************"

source=$1
destination=$2
cd $source
file=$3


echo "`date '+%Y.%m.%d %H:%M:%S'` - Processing file $source/$file, OK? [Y/n]"
read -t 10 -n 1 p     # read one character (-n) with timeout of 10 seconds
echo
echo
if [ "${p}" == 'N' -o  "${p}" == 'n' ]; then
  echo "no means no - I am exiting..."
  return
fi

echo "`date '+%Y.%m.%d %H:%M:%S'` - current directory is "`pwd`
echo "`date '+%Y.%m.%d %H:%M:%S'` - computing checksum with command:"
echo "                      sha512sum ${file} > ${file}.sha512"
echo

sha512sum "${file}" > "${file}.sha512"

echo "`date '+%Y.%m.%d %H:%M:%S'` - done, now running verification"
echo
echo -n "                      "
sha512sum --check "${file}.sha512"
return_code=$?
echo "`date '+%Y.%m.%d %H:%M:%S'` - exit code = $return_code"
echo

echo "`date '+%Y.%m.%d %H:%M:%S'` - starting rsync to remote server"
echo "                      rsync -ah --progress ${file} ${file}.sha512 ${destination}"
echo "*************************************"

rsync -ah --progress ${file} ${file}.sha512 ${destination}
echo "*************************************"
return_code=$?
echo "`date '+%Y.%m.%d %H:%M:%S'` - exit code = $return_code"

echo "`date '+%Y.%m.%d %H:%M:%S'` - done, now verifying files on remote server"
echo "                      sha512sum --check ${destination}/${file}.sha512"
echo
echo -n "                      "
sha512sum --check "${destination}/${file}.sha512"
return_code=$?
echo "`date '+%Y.%m.%d %H:%M:%S'` - exit code = $return_code"
echo

if (( $return_code != 0 )); then
  echo ; echo ERROR ; echo
  exit 2
else
  echo "`date '+%Y.%m.%d %H:%M:%S'` - deleting `pwd`/{file}.sha512 `pwd`/${file}"
  echo -n "                      "
  rm -v `pwd`/${file}.sha512 `pwd`/${file}
  echo ; echo 
fi
}
####################################################################################

source=$source_dropbox
destination=$destination_dropbox
cd $source
file=`/bin/ls -1tr *_Dropbox.rar | head -n 1`

copy_backup $source $destination $file

source=$source_praca
destination=$destination_praca
cd $source
file=`/bin/ls -1tr *_praca.rar | head -n 1`

copy_backup $source $destination $file

echo
