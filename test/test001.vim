"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Test TODO entry creation macros
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Use TAP
call vimtest#StartTap()
call vimtap#Plan(2)

" Load the todo plugin
" This should have the same effect as set ft=todo
source ../ftplugin/todo.vim
source ../syntax/todo.vim

" Get Today's date for matching with the auto-generated dates
let today=strftime("%Y-%m-%d")

call vimtap#Diag('TODO entry creation')
normal icn Test Entry
call vimtap#Is(getline('.'), 'TODO '.today.' Test Entry',
            \"TODO entry generated with cn abbreviation")

normal \cn
call vimtap#Is(getline('.'), 'TODO '.today.' ',
            \"TODO entry generated with \cn macro")
"normal \cs
"call vimtap#Is(getline('.'), 'DONE '.today.' Test Entry',
"            \"State changed to DONE")

call vimtest#Quit()
