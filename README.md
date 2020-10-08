cd $HOME ; rm -rf $HOME/github-bin;


git clone git+ssh://git@github.com/pmatuszy/github-bin.git ;


cp -v github-bin/* $HOME/bin ;


git status ; git commit -m "`date`"

