" Vim filetype plugin for heirarchical TODO lists
" Maintainer:   Mark Harrison <mark@mivok.net>
" Last Change:  Aug 15, 2009
" License:      ISC - See LICENSE file for details

" Only load if we haven't already
if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1

" Make sure we aren't running in compatible mode
let s:save_cpo = &cpo
set cpo&vim

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Setup script variables
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function s:Set(varname, value)
    if !exists(a:varname)
        exec "let" a:varname "=" string(a:value)
    endif
endfunction

" Default variables
"let todo_states = [["TODO", "DONE"]]
call s:Set("g:todo_states",
    \[["TODO(t)", "|", "DONE(d)", "CANCELLED(c)"], ["WAITING(w)", "CLOSED(l)"]])
call s:Set("g:todo_state_colors", { "TODO" : "Blue", "DONE": "Green" })
call s:Set("g:todo_checkbox_states", [[" ", "X"], ["+", "-", "."],
    \["Y", "N", "?"]])
call s:Set("g:todo_log", 1)

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Folding support
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
setlocal foldmethod=indent
setlocal foldtext=getline(v:foldstart).\"\ ...\"
setlocal fillchars+=fold:\ 

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""" Todo entry macros
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Datestamp
iab ds <C-R>=strftime("%Y-%m-%d")<CR>
" New todo entry - both command and abbreviation
map \cn o[ ] ds 
" TODO - make the abbreviation run 'ds' instead
iab cn [ ] <C-R>=strftime("%Y-%m-%d")<CR>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""" Checkboxes
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Note: These macros make use of the 'z' mark
" TODO - ask on irc if there is an accepted way to do this in a macro

" Make a checkbox at the beginning of the line, removes any preceding bullet
" point dash
if !exists("*s:InsertCheckbox")
function! s:InsertCheckbox()
    echo "Insert checkbox"
    let oldpos=getpos(".")
    s/^\(\s*\)\?\(- \)\?/\1[ ] /
    call setpos(".", oldpos)
endfunction
endif

if !hasmapto('<Plug>TodoInsertCheckbox')
    map <buffer> <unique> <LocalLeader>cb <Plug>TodoInsertCheckbox
endif
noremap <unique> <script> <Plug>TodoInsertCheckbox <SID>InsertCheckbox
noremap <SID>InsertCheckbox :call <SID>InsertCheckbox()<CR>

" Toggle a checkbox
if !exists("*s:CheckboxToggle")
function s:CheckboxToggle()
    echo "Toggle checkbox"
    let line=getline(".")
    let idx=match(line, "\\[[^]]\\]")
    if idx != -1
        for group in g:todo_checkbox_states
            let stateidx = 0
            while stateidx < len(group)
                if group[stateidx] == line[idx+1]
                    let stateidx=stateidx + 1
                    if stateidx >= len(group)
                        let stateidx = 0
                    endif
                    let val=group[stateidx]
                    let parts=[line[0:idx],line[idx+2:]]
                    call setline(".", join(parts, val))
                    " Logging code - not used in checkboxes
                    "if g:todo_checkbox_log == 1
                    "    let log=g:todo_checkbox_states[val]["log"]
                    "    call append(line("."), matchstr(getline("."), "\\s\\+")."    ".
                    "            \log.": ".strftime("%Y-%m-%d %H:%M:%S"))
                    "endif
                    return
                endif
                let stateidx=stateidx + 1
            endwhile
        endfor
    endif
endfunction
endif

if !hasmapto('<Plug>TodoCheckboxToggle')
    map <buffer> <unique> <LocalLeader>cc <Plug>TodoCheckboxToggle
endif
noremap <unique> <script> <Plug>TodoCheckboxToggle <SID>CheckboxToggle
noremap <SID>CheckboxToggle :call <SID>CheckboxToggle()<CR>


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""" Task status
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if !exists("*s:NextTaskState")
function s:NextTaskState()
    echo "Next task state"
    let [oldstate, idx] = s:GetState()
    if idx != -1
        for group in g:todo_states
            let stateidx = 0
            while stateidx < len(group)
                let teststate = TodoParseTaskState(group[stateidx])["state"]
                if teststate == oldstate
                    let stateidx=(stateidx + 1) % len(group)
                    " Skip | separator
                    if group[stateidx] == "|"
                        let stateidx=(stateidx + 1) % len(group)
                    endif
                    let val=TodoParseTaskState(group[stateidx])["state"]
                    call s:SetTaskState(val, oldstate, idx)
                    return
                endif
                let stateidx=stateidx + 1
            endwhile
        endfor
    endif
endfunction
endif

if !hasmapto('<Plug>TodoNextTaskState')
    map <buffer> <unique> <LocalLeader>cs <Plug>TodoNextTaskState
endif
noremap <unique> <script> <Plug>TodoNextTaskState <SID>NextTaskState
noremap <SID>NextTaskState :call <SID>NextTaskState()<CR>

" Parse a task state of the form TODO(s) into a state and shortcut
function TodoParseTaskState(state)
    let state=matchstr(a:state, '^[A-Z]\+')
    let key=matchstr(a:state, '\(^[A-Z]\+(\)\@<=[a-zA-Z0-9]\()\)\@=')
    return { "state": state, "key": key }
endfunction

function s:PromptTaskState()
    let [oldstate, idx] = s:GetState()
    call s:NewScratchBuffer("StateSelect")
    call append(0, "Pick the new task state")
    let statekeys = {}
    for group in g:todo_states
        let promptlist = []
        for statestr in group
            if statestr == "|"
                continue
            endif
            let state = TodoParseTaskState(statestr)
            if state["key"] != ""
                call add(promptlist, state["state"]." (".state["key"].")")
                let statekeys[state["key"]] = state["state"]
            endif
        endfor
        if len(promptlist)
            call append(line("$"), "    ".join(promptlist, ", "))
        endif
    endfor
    echo
    for key in keys(statekeys)
        exe "nnoremap <buffer> <silent> ".key.
                    \" :call <SID>SelectTaskState(\"".statekeys[key]."\"".
                    \",\"".oldstate."\",".idx.")<CR>"
    endfor
    call append(line("$"), "    Press SPACE to remove any existing state")
    exe "nnoremap <buffer> <silent> <Space> :call <SID>SelectTaskState(".
                \'"","'.oldstate.'", '.idx.')<CR>'
endfunction

function s:SelectTaskState(state, oldstate, idx)
    bdelete
    call s:SetTaskState(a:state, a:oldstate, a:idx)
endfunction

if !hasmapto('<Plug>TodoPromptTaskState')
    map <buffer> <unique> <LocalLeader>cv <Plug>TodoPromptTaskState
endif
noremap <unique> <script> <Plug>TodoPromptTaskState <SID>PromptTaskState
noremap <SID>PromptTaskState :call <SID>PromptTaskState()<CR>

function s:SetTaskState(state, oldstate, idx)
    let line = getline(".")
    if a:idx > 0
        let parts=[line[0:a:idx-1],line[a:idx+len(a:oldstate):]]
    elseif a:idx == -1
        let parts=["", " ".line]
    else
        let parts=["",line[len(a:oldstate):]]
    endif
    if a:state != ""
        call setline(".", join(parts, a:state))
    else
        " Remove the state
        call setline(".", join(parts, "")[1:])
    endif
    " Logging code
    if g:todo_log == 1
        let log=a:state " TODO allow alternate log msg
        if log != "" " Don't log removing a state
            call append(line("."),
                        \ matchstr(getline("."), "^\\s\\+")."    ".
                        \log.": ".strftime("%Y-%m-%d %H:%M:%S"))
        endif
    endif
endfunction

" Gets the state on the current line, and the index of it
function s:GetState()
    let line=getline(".")
    let regex="\\(^\\s*\\)\\@<=[A-Z]\\+\\(\\s\\|$\\)\\@="
    let idx=match(line, regex)
    let state=matchstr(line, regex)
    return [state, idx]
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Task link
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Provides a link to a web based task manager
" Need to set the todo_taskurl and todo_browser variables in .vimrc
" E.g.
" let todo_browser="gnome-open"
" let todo_taskurl="http://www.example.com/tasks/?id=%s"
" (The %s will be replaced with the task id)
if !exists("*s:LoadTaskLink")
function s:LoadTaskLink()
    let tid=matchstr(getline("."), "tid\\d\\+")
    if tid != ""
        let tid = matchstr(tid, "\\d\\+")
        let taskurl = substitute(g:todo_taskurl, "%s", tid, "")
        call system(g:todo_browser . " " . taskurl)
        echo "Loading Task"
    else
        echo "No Task ID found"
    endif
endfunction
endif

if !hasmapto('<Plug>TodoLoadTaskLink')
    map <buffer> <unique> <LocalLeader>ct <Plug>TodoLoadTaskLink
endif
noremap <unique> <script> <Plug>TodoLoadTaskLink <SID>LoadTaskLink
noremap <SID>LoadTaskLink :call <SID>LoadTaskLink()<CR>


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" URL opening
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Uses todo_browser
if !exists("*s:LoadLink")
function s:LoadLink()
    let url=matchstr(getline("."), "https\\?://\\S\\+")
    if url != ""
        call system(g:todo_browser . " " . url)
        echo "Loading URL"
    else
        echo "No URL Found"
    endif
endfunction
endif

if !hasmapto('<Plug>TodoLoadLink')
    map <buffer> <unique> <LocalLeader>cl <Plug>TodoLoadLink
endif
noremap <unique> <script> <Plug>TodoLoadLink <SID>LoadLink
noremap <SID>LoadLink :call <SID>LoadLink()<CR>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""" Task searching
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if !exists("*s:ShowDueTasks")
function s:ShowDueTasks(day, ...)
    " Based on the Todo function at
    " http://ifacethoughts.net/2008/05/11/task-management-using-vim/
    " Add the first day
    let _date = strftime("%Y-%m-%d", localtime() + a:day * 86400)
    try
        exec "lvimgrep /{" . _date . "}/j %"
    catch /^Vim(\a\+):E480:/
    endtry
    " Add any more in the day range
    if a:0 > 0
        for offset in range(a:day+1, a:1)
            let _date = strftime("%Y-%m-%d", localtime() + offset * 86400)
            try
                exec "lvimgrepadd /{" . _date . "}/j %"
            catch /^Vim(\a\+):E480:/
            endtry
        endfor
    endif
    exec "lw"
endfunction
endif

command -buffer Today :call s:ShowDueTasks(0)
command -buffer Tomorrow :call s:ShowDueTasks(1)
command -buffer Week :call s:ShowDueTasks(0,7)
command -buffer Overdue :call s:ShowDueTasks(-7,-1)

if !hasmapto(':Today')
    map <buffer> <unique> <LocalLeader>cd :Today<CR>
endif
if !hasmapto(':Tomorrow')
    map <buffer> <unique> <LocalLeader>cf :Tomorrow<CR>
endif
if !hasmapto(':Week')
    map <buffer> <unique> <LocalLeader>cw :Week<CR>
endif
if !hasmapto(':Overdue')
    map <buffer> <unique> <LocalLeader>cx :Overdue<CR>
endif

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""" Create a new buffer
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function s:NewScratchBuffer(name)
    " Set the buffer name
    let name="[".a:name."]"
    if !has("win32")
        let name = escape(name, "[]")
    endif
    " Switch buffers
    if has("gui")
        exec "drop" name
    else
        exec "hide edit" name
    endif
    " Set the new buffer properties to be a scrach buffer
    setlocal bufhidden=delete
    setlocal buftype=nofile
    setlocal modifiable " This needs to be changed once the buffer has stuff in
    setlocal noswapfile
    setlocal nowrap     " This can be changed if needed
endfunction

" Restore the old compatible mode setting
let &cpo = s:save_cpo
