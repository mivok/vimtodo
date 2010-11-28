"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Test task time totals
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
source setup_tests.inc
call vimtap#Plan(7)

" Basic test
normal icn TODO test entry
normal o    Some Subtask [0.5h]
normal o    Some other subtask [1.5h]

normal \ce
call vimtap#Is(getline(2), "    :INFO:",
    \ "INFO drawer created")
call vimtap#Is(getline(3), "        +TOTALTIME: 2.00",
    \ "TOTALTIME property added")

normal ggdG

" Try with two entries instead of 1
normal icn TODO test entry [2.5h]
normal o    Some subtask [1.5h]
normal o    Some subtask [13.25h]
normal ocn TODO another entry
normal o    Subtask 1 [1.00h]
normal o    Subtask 2 [4.75h]

normal \ce
call vimtap#Is(getline(2), "    :INFO:",
    \ "First INFO drawer created (2 entries)")
call vimtap#Is(getline(3), "        +TOTALTIME: 17.25",
    \ "First total time correct (2 entries)")
call vimtap#Is(getline(7), "    :INFO:",
    \ "Second INFO drawer created (2 entries)")
call vimtap#Is(getline(8), "        +TOTALTIME: 5.75",
    \ "Second total time correct (2 entries)")

" Change one time entry
" Open all folds first
normal zR
normal 4Gc$Some subtask [1.75h]
normal \ce
call vimtap#Is(getline(3), "        +TOTALTIME: 17.50",
    \ "Total time changed correctly")

call vimtest#Quit()
