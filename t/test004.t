Test in file settings

We insert the text first before loading the setup as we want to test the
settings getting applied as the plugin is loaded.

    > :SETTINGS:
    >     +DONEFILE: done2.txt
    >     +LOGDONE: 0
    >     +LOGDRAWER: ALTERNATE
    >     +STATES: TODO INPROGRESS | DONE
    >     +STATES: WAITING(w) FOO(f) | BAR(b)
    >     +STATECOLORS: TODO:green, DONE : blue
    >     +STATECOLORS: INPROGRESS: magenta , FOO:red
    >     +CHECKBOXSTATES: A B C
    >     +CHECKBOXSTATES: 1 2 3
    >     +TASKURL: http://www.google.com/%s
    >     +BROWSER: firefox
    >     +MYPROPERTY: somevalue
    >     +MYPROPLIST: A B C

Setup for tests:

    :let g:todo_property_vars = {
    \   'MYPROPERTY' : 'g:todo_myproperty',
    \   'MYPROPLIST' : 'g:todo_myproplist',
    \}
    :let g:todo_property_types = {'MYPROPLIST': 'nestedlist'}

    :so test_setup.vim

Compare variable values:

    ? g:todo_log_done == 0
    ? g:todo_log_into_drawer == 'ALTERNATE'
    ? g:todo_done_file == 'done2.txt'
    ? g:todo_states == [["TODO", "INPROGRESS", "|", "DONE"],
    \ ["WAITING(w)", "FOO(f)", "|", "BAR(b)"]]
    ? g:todo_state_colors == { "TODO" : "green", "DONE": "blue",
    \ "INPROGRESS": "magenta", "FOO": "red" }
    ? g:todo_checkbox_states == [["A", "B", "C"], ["1", "2", "3"]]
    ? g:todo_taskurl == "http://www.google.com/%s"
    ? g:todo_myproperty == "somevalue"
    ? g:todo_myproplist == [["A", "B", "C"]]

vim: ft=vimcram
