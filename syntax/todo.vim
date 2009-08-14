" Vim syntax file
" Language:     todo.txt
" Maintainer:   Mark Harrison <mark@mivok.net>
" Last Change:  Aug 9, 2009

" au BufRead,BufNewFile todo.txt,*.todo.txt,recur.txt,*.todo set filetype=todo

" Quit when a (custom) syntax file was already loaded
if exists("b:current_syntax")
  finish
endif

syn match       todoProject     /+\S\+/
syn match       todoContext     /\s@\S\+/
syn match       todoPriority    /([A-Z])/
"syn match       todoDone        /^\s*\[\?[xX]\]\?\s.*/
syn region      todoDone        start="^\z(\s*\)DONE\s"
                                \ end="^\%(\n*\z1\s\)\@!"
                                \ contains=todoLog
syn match       todoDate        /\w\?{[^}]\+}[+=-]\?/
syn match       todoDate        /\d\{4\}-\d\{2\}-\d\{2\}/
syn match       todoTasknum     /tid\d\+/

syn match       todoURI         /\w\+:\/\/\S\+/
syn match       todoEmail       /\S\+@\S\+\.\S\+/

syn match       todoBold        /\*[^*]\+\*/
syn match       todoUline       /_[^_]\{2,}_/
syn match       todoComment     /\s*#.*$/
syn match       todoLog         /\(^\s*\)\@<=[A-Z]\+:/

hi def link     todoProject     Statement
hi def link     todoContext     Identifier
hi def link     todoPriority    Special
hi def link     todoDone        Comment
hi def link     todoDate        Constant
hi def link     todoTasknum     Number

hi def link     todoBold        PreProc
hi def link     todoUline       PreProc
hi def link     todoComment     Comment
hi def link     todoLog         PreProc

hi def link     todoURI         String
hi def link     todoEmail       String

" Highlight state colors
function! HighlightStatus(name, color)
    " Sets the highlight for a particular status to the given color
    let name=toupper(a:name)
    exe "syn match todoState".name." /\\(^\\s*\\)\\@<=".name.
        \":\\?\\(\\s\\|$\\)\\@=/"
    exe "hi def todoState".name." guifg=".a:color." ctermfg=".a:color.
        \" gui=bold cterm=bold"
endfunction
for state in keys(g:todo_state_colors)
    call HighlightStatus(state, g:todo_state_colors[state])
endfor

let b:current_syntax = "todo"
