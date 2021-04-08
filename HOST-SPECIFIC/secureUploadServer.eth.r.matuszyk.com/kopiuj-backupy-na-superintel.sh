

# 2021.02.05 - v. 0.1 - initial release




source_dropbox="/mnt/server/DyskN/_backupy/DropBox"
destination_dropbox="/mnt/superintel/DyskS/____z_DyskU/_backupy-1dyne_kopie/DropBox"

source_praca="/mnt/server/DyskN/_backupy/praca/"
destination_praca="/mnt/superintel/DyskS/____z_DyskU/_backupy-1dyne_kopie/praca/"

echo ; echo
co=$source_dropbox
if [ ! -d "$co" ] ; then
   echo ; echo "$co nie istnieje" ; echo "WYCHODZE ..."; echo
   exit 1
else
   echo "`date '+%Y.%m.%d %H:%M:%S'` - katalog $co istnieje - OK"
fi

co=$destination_dropbox
if [ ! -d "$co" ] ; then
   echo ; echo "$co nie istnieje" ; echo "WYCHODZE ..."; echo
   exit 1
else
   echo "`date '+%Y.%m.%d %H:%M:%S'` - katalog $co istnieje - OK"
fi

co=$source_praca
if [ ! -d "$co" ] ; then
   echo ; echo "$co nie istnieje" ; echo "WYCHODZE ..."; echo
   exit 1
else
   echo "`date '+%Y.%m.%d %H:%M:%S'` - katalog $co istnieje - OK"
fi

co=$destination_praca
if [ ! -d "$co" ] ; then
   echo ; echo "$co nie istnieje" ; echo "WYCHODZE ..."; echo
   exit 1
else
   echo "`date '+%Y.%m.%d %H:%M:%S'` - katalog $co istnieje - OK"
fi
echo

source=$source_dropbox
destination=$destination_dropbox
cd $source
plik=`/bin/ls -1tr *_Dropbox.rar | head -n 1`

####################################################################################
####################################################################################
kopiuj() {
####################################################################################
####################################################################################

echo "`date '+%Y.%m.%d %H:%M:%S'` - ******************************************"
echo "`date '+%Y.%m.%d %H:%M:%S'` - ****************** KOPIUJ ****************"
echo "`date '+%Y.%m.%d %H:%M:%S'` - \$1 = $1"
echo "`date '+%Y.%m.%d %H:%M:%S'` - \$2 = $2"
echo "`date '+%Y.%m.%d %H:%M:%S'` - \$3 = $3"
echo "`date '+%Y.%m.%d %H:%M:%S'` - ******************************************"

source=$1
destination=$2
cd $source
plik=$3


echo "`date '+%Y.%m.%d %H:%M:%S'` - Obrabiam plik $source/$plik, OK? [Y/n]"
read -t 10 -n 1 p     # read one character (-n) with timeout of 10 seconds
echo
echo
if [ "${p}" == 'N' -o  "${p}" == 'n' ]; then
  echo "no means no - I am exiting..."
  return
fi

echo "`date '+%Y.%m.%d %H:%M:%S'` - jestem w katalogu "`pwd`
echo "`date '+%Y.%m.%d %H:%M:%S'` - robie sume kontrolna nastepujaca komenda:"
echo "                      sha512sum ${plik} > ${plik}.sha512"
echo

sha512sum "${plik}" > "${plik}.sha512"

echo "`date '+%Y.%m.%d %H:%M:%S'` - zrobione, teraz robie sprawdzenie"
echo
echo -n "                      "
sha512sum --check "${plik}.sha512"
kod_powrotu=$?
echo "`date '+%Y.%m.%d %H:%M:%S'` - kod powrotu = $kod_powrotu"
echo

echo "`date '+%Y.%m.%d %H:%M:%S'` - zaczynam mv na zdalny serwer"
echo "                      rsync -ah --progress ${plik} ${plik}.sha512 ${destination}"
echo "*************************************"

rsync -ah --progress ${plik} ${plik}.sha512 ${destination}
echo "*************************************"
kod_powrotu=$?
echo "`date '+%Y.%m.%d %H:%M:%S'` - kod powrotu = $kod_powrotu"

echo "`date '+%Y.%m.%d %H:%M:%S'` - zrobione, teraz robie sprawdzenie plikow na zdalnym serwerze"
echo "                      sha512sum --check ${destination}/${plik}.sha512"
echo
echo -n "                      "
sha512sum --check "${destination}/${plik}.sha512"
kod_powrotu=$?
echo "`date '+%Y.%m.%d %H:%M:%S'` - kod powrotu = $kod_powrotu"
echo

if (( $kod_powrotu != 0 )); then
  echo ; echo BLAD ; echo
  exit 2
else
  echo "`date '+%Y.%m.%d %H:%M:%S'` - kasuje `pwd`/{plik}.sha512 `pwd`/${plik}"
  echo -n "                      "
  rm -v `pwd`/${plik}.sha512 `pwd`/${plik}
  echo ; echo 
fi
}
####################################################################################

source=$source_dropbox
destination=$destination_dropbox
cd $source
plik=`/bin/ls -1tr *_Dropbox.rar | head -n 1`

kopiuj $source $destination $plik

source=$source_praca
destination=$destination_praca
cd $source
plik=`/bin/ls -1tr *_praca.rar | head -n 1`

kopiuj $source $destination $plik

echo
