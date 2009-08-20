" Vim filetype plugin for heirarchical TODO lists
" Maintainer:   Mark Harrison <mark@mivok.net>
" Last Change:  Aug 15, 2009
" License:      ISC - See LICENSE file for details

" Only load if we haven't already {{{1
if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1
"1}}}
" Make sure we aren't running in compatible mode {{{1
let s:save_cpo = &cpo
set cpo&vim
"1}}}

" Utility Functions
" s:Set - setup script variables {{{1
function s:Set(varname, value)
    if !exists(a:varname)
        exec "let" a:varname "=" string(a:value)
    endif
endfunction
"1}}}
" s:NewScratchBuffer - Create a new buffer {{{1
function s:NewScratchBuffer(name, split)
    if a:split
        split
    endif
    " Set the buffer name
    let name="[".a:name."]"
    if !has("win32")
        let name = escape(name, "[]")
    endif
    " Switch buffers
    if has("gui")
        exec "silent keepjumps drop" name
    else
        exec "silent keepjumps hide edit" name
    endif
    " Set the new buffer properties to be a scrach buffer
    setlocal bufhidden=delete
    setlocal buftype=nofile
    setlocal modifiable " This needs to be changed once the buffer has stuff in
    setlocal noswapfile
    setlocal nowrap     " This can be changed if needed
endfunction
"1}}}
" TodoParseTaskState {{{1
" Parse a task state of the form TODO(t) into state and shortcut key
function TodoParseTaskState(state)
    let state=matchstr(a:state, '^[A-Z]\+')
    let key=matchstr(a:state, '\(^[A-Z]\+(\)\@<=[a-zA-Z0-9]\()\)\@=')
    return { "state": state, "key": key }
endfunction
"1}}}
""" Drawer Support
" s:FindDrawer {{{1
function s:FindDrawer(name)
    let line = line(".")
    let topindent = indent(line)
    let line=line + 1
    let indent = indent(line)
    while indent(line) > topindent
        if indent(line) == indent &&
                    \ match(getline(line), '^\s\+:'.toupper(a:name).':') != -1
            return line
        endif
        let line = line + 1
    endwhile
    return -1
endfunction
"1}}}
" s:FindOrMakeDrawer {{{1
function s:FindOrMakeDrawer(name)
    let line = s:FindDrawer(a:name)
    if line != -1
        return line
    endif
    let topindent = indent(".")
    let indent = indent(line(".") + 1)
    if indent <= topindent
        let indent = topindent + 4 " TODO - set this to shiftwidth
    endif
    let indentstr=printf("%".indent."s", "") " generate indent spaces
    call append(line("."), indentstr.":".toupper(a:name).":")
    return line(".")+1
endfunction
"1}}}

" Default variables {{{1
"let todo_states = [["TODO", "DONE"]]
call s:Set("g:todo_states",
    \[["TODO(t)", "|", "DONE(d)", "CANCELLED(c)"], ["WAITING(w)", "CLOSED(l)"]])
call s:Set("g:todo_state_colors", { "TODO" : "Blue", "DONE": "Green",
    \ "CANCELLED" : "Red", "WAITING": "Yellow", "CLOSED": "Grey" })
call s:Set("g:todo_checkbox_states", [[" ", "X"], ["+", "-", "."],
    \["Y", "N", "?"]])
call s:Set("g:todo_log", 1)
call s:Set("g:todo_log_drawer", "LOGBOOK")
"1}}}
" Folding support {{{1
setlocal foldmethod=indent
setlocal foldtext=getline(v:foldstart).\"\ ...\"
setlocal fillchars+=fold:\ 
" 1}}}

" Todo entry macros
" ds- Datestamp {{{1
iab ds <C-R>=strftime("%Y-%m-%d")<CR>
" cn, \cn - New todo entry {{{1
exe 'map \cn o'.TodoParseTaskState(g:todo_states[0][0])["state"].' ds '
exe 'iab cn '.TodoParseTaskState(g:todo_states[0][0])["state"].
            \' <C-R>=strftime("%Y-%m-%d")<CR>'
"1}}}

" Checkboxes
" InsertCheckbox {{{1
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
"1}}}
" CheckboxToggle {{{1
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
"1}}}

" Task status
" s:NextTaskState {{{1
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
"1}}}
" s:PromptTaskState {{{1
function s:PromptTaskState()
    let [oldstate, idx] = s:GetState()
    call s:NewScratchBuffer("StateSelect", 1)
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
    call append(line("$"), "    Press Space to remove any existing state")
    exe "nnoremap <buffer> <silent> <Space> :call <SID>SelectTaskState(".
                \'"","'.oldstate.'", '.idx.')<CR>'
    call append(line("$"), "    Press Escape to cancel")
    nnoremap <buffer> <silent> <Esc> :bd<CR>
    setlocal nomodifiable " Make the buffer read only
endfunction

if !hasmapto('<Plug>TodoPromptTaskState')
    map <buffer> <unique> <LocalLeader>cv <Plug>TodoPromptTaskState
endif
noremap <unique> <script> <Plug>TodoPromptTaskState <SID>PromptTaskState
noremap <SID>PromptTaskState :call <SID>PromptTaskState()<CR>
"1}}}
" s:SelectTaskState {{{1
function s:SelectTaskState(state, oldstate, idx)
    bdelete
    call s:SetTaskState(a:state, a:oldstate, a:idx)
endfunction
"1}}}
" s:SetTaskState {{{1
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
    " TODO - separate logging of all state changes from logging open/closed
    " Only log all state changes to the drawer
    " Others go on the first line
    if g:todo_log == 1
        let log=a:state
        if log != "" " Don't log removing a state
            let drawerline = s:FindOrMakeDrawer(g:todo_log_drawer)
            call append(drawerline,
                        \ matchstr(getline(drawerline), "^\\s\\+")."    ".
                        \log.": ".strftime("%Y-%m-%d %H:%M:%S"))
        endif
    endif
endfunction
"1}}}
" s:GetState {{{1
" Gets the state on the current line, and the index of it
function s:GetState()
    let line=getline(".")
    let regex="\\(^\\s*\\)\\@<=[A-Z]\\+\\(\\s\\|$\\)\\@="
    let idx=match(line, regex)
    let state=matchstr(line, regex)
    return [state, idx]
endfunction
"1}}}

" Task Links
" s:LoadTaskLink {{{1
"   Provides a link to a web based task manager
"   Need to set the todo_taskurl and todo_browser variables in .vimrc
"   E.g.
"   let todo_browser="gnome-open"
"   let todo_taskurl="http://www.example.com/tasks/?id=%s"
"   (The %s will be replaced with the task id)
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
"1}}}
" s:LoadLink - URL Opening {{{1
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
"1}}}

" Task searching
" s:ShowDueTasks {{{1
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
"1}}}
" ShowDueTasks Commands {{{1
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
"1}}}

" Restore the old compatible mode setting {{{1
let &cpo = s:save_cpo
"1}}}
" vim:foldmethod=marker
