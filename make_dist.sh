#!/bin/bash
cd ..
tar cvz --exclude={.gitignore,.git,make_dist.sh,vimball.vim,*.swp} \
    --exclude=vimtodo/test/*.{msgout,out,tap} \
    --exclude=vimtodo/doc/tags \
    --exclude=vimtodo.vba \
    -f vimtodo.tgz vimtodo
