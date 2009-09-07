"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Test TODO state changes
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Use TAP
call vimtest#StartTap()
call vimtap#Plan(4)

" Load the todo plugin
" This should have the same effect as set ft=todo
source ../ftplugin/todo.vim
source ../syntax/todo.vim
" Whitespace settings
setlocal sw=4 sts=4 et

" Regular expression to match a status timestamp
let timestampre='\d\{4\}-\d\{2\}-\d\{2\} \d\{2\}:\d\{2\}:\d\{2\}'

insert
TODO 2009-09-06 Test entry
.

" Single state change
normal \cs
let line=line('.')
call vimtap#Is(getline('.'), 'DONE 2009-09-06 Test entry',
            \"State changed to DONE")
call vimtap#Like(getline(line+1), '^    CLOSED: '.timestampre,
            \"Added CLOSED: tag")
call vimtap#Like(getline(line+2), '^    :LOGBOOK:',
            \"Logbook drawer created")
call vimtap#Like(getline(line+3), '^        DONE: '.timestampre,
            \"Log entry added")

call vimtest#Quit()
