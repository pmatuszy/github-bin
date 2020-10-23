```
cd $HOME ; rm -rf $HOME/github-bin;
git clone git+ssh://git@github.com/pmatuszy/github-bin.git ;
cp -v github-bin/* $HOME/bin ; cd github-bin ; 
git status ; git commit -m \""new push from `hostname` @ `date '+%Y.%m.%d %H:%M:%S'`"\"
```

## jedna linia: 
```
cd $HOME ; rm -rf $HOME/github-bin; git clone git+ssh://git@github.com/pmatuszy/github-bin.git ; cp -v github-bin/* $HOME/bin ; cd github-bin ; git status ; git commit -m \""new push from `hostname` @ `date '+%Y.%m.%d %H:%M:%S'`"\"
```
