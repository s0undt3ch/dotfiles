" no need to fold things in markdown all the time
let g:vim_markdown_folding_disabled = 1
" turn on spelling for markdown files
autocmd BufRead,BufNewFile *.md setlocal spell complete+=kspell
" disable markdown auto-preview. Gets annoying
let g:instant_markdown_autostart = 0
