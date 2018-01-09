" Installed system-wide so likely no need to tweak it
let g:completor_python_binary = '/usr/bin/python'

" Use Tab to select completion
"inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
"inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
"inoremap <expr> <cr> pumvisible() ? "\<C-y>\<cr>" : "\<cr>"

" Use Tab to trigger completion (disable auto trigger)
"let g:completor_auto_trigger = 0
"inoremap <expr> <Tab> pumvisible() ? "<C-N>" : "<C-R>=completor#do('complete')<CR>"

" Complete Options (completeopt)
" By default completor.vim set some options to the completeopt.
"
" The defaul options:
"   set completeopt-=longest
"   set completeopt+=menuone
"   set completeopt-=menu
"   if &completeopt !~# 'noinsert\|noselect'
"     set completeopt+=noselect
"   endif
"
" If you don't want these options you can use the following config to disable it:
" let g:completor_set_options = 0
