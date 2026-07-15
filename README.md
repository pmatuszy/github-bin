
## jedna linia: 
```
mkdir -p ${profile_location_dir}/github ; rm -rf ${profile_location_dir}/github/github-bin; git clone git+ssh://git@github.com/pmatuszy/github-bin.git ${profile_location_dir}/github/github-bin ; cp -v ${profile_location_dir}/github/github-bin/* $HOME/bin ; cd ${profile_location_dir}/github/github-bin ; git status 

'''


```
git add * ; git commit -m \""new push from `hostname` @ `date '+%Y.%m.%d %H:%M:%S'`"\" ; git push
```

