let g:UltiSnipsSnippetsDir        =  $HOME . '/.vim/UltiSnips/'

" better key bindings for UltiSnipsExpandTrigger
let g:UltiSnipsExpandTrigger = "<tab>"
let g:UltiSnipsJumpForwardTrigger = "<tab>"
let g:UltiSnipsJumpBackwardTrigger = "<s-tab>"

"let g:UltiSnipsDontReverseSearchPath="1"
"let g:UltiSnipsJumpForwardTrigger = '<Tab>'
"let g:UltiSnipsJumpBackwardTrigger = '<S-Tab>'
let g:ultisnips_python_style = 'sphinx'
let g:ultisnips_python_quoting_style = 'double'
let g:ultisnips_python_project_team = 'UfSoft.org'
let g:ultisnips_python_project_license = 'BSD'
let g:ultisnips_python_code_author = ':email:`Pedro Algarvio (pedro@algarvio.me)`'

" Make sure scratch is automaticaly closed
autocmd InsertLeave,CompleteDone * if pumvisible() == 0 | pclose | endif
