" ----- python-mode settings ------------------------------------------------>
let g:pymode_rope = 0                       " Disable Rope, we'll be using Jedi
let g:pymode_folding = 0                    " Enable python folding
let g:pymode_virtualenv = 0                 " Add virtualenv paths
let g:pymode_lint = 1                       " Enable code lint
let g:pymode_lint_onfly = 0                 " Run linter on the fly
let g:pymode_lint_checker = "pylint,mccabe"
let g:pymode_lint_config = fnamemodify(expand(":h"), ":p:h") . '/.pylintrc'
let g:pymode_rope_auto_project_open = 1     " auto open existing projects
let g:pymode_lint_signs_always_visible = 1  " always show the errors vertical ruller

" syntax highlighting
let g:pymode_syntax = 1
let g:pymode_syntax_all = 1
let g:pymode_syntax_indent_errors = g:pymode_syntax_all
let g:pymode_syntax_space_errors = g:pymode_syntax_all
" <---- python-mode settings -------------------------------------------------
