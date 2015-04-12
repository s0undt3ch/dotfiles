" ----- Auto-commands ------------------------------------------------------->
if has("autocmd")
  augroup vimrc
    au!

    " Jump to last-known-position when editing files
    autocmd BufReadPost *
          \ if line("'\"") > 1 && line("'\"") <= line("$") |
          \   exe "normal! g'\"" |
          \ endif

    " Default omni completion based on syntax
    "if exists("+omnifunc")
    "  autocmd Filetype *
    "        \ if &omnifunc == "" |
    "        \   setlocal omnifunc=syntaxcomplete#Complete |
    "        \ endif
    "endif
  augroup END
endif

:autocmd BufNewFile,BufRead *.html set sw=2 ts=2 fenc=utf-8 et
:autocmd BufNewFile,BufRead *.xml set sw=2 ts=2 fenc=utf-8 et
:autocmd BufNewFile,BufRead *.json set sw=2 ts=2 fenc=utf-8 et
":autocmd BufNewFile,BufRead *.txt set sw=4 ts=4 fenc=utf-8 et linebreak wrap
:autocmd BufNewFile,BufRead svn-commit*.tmp set wrap linebreak textwidth=0 spell spelllang=en
:autocmd BufNewFile,BufRead hg-editor-*.txt set wrap linebreak textwidth=0 spell spelllang=en
:autocmd BufNewFile,BufRead .git/*_EDITMSG set wrap linebreak textwidth=0 spell spelllang=en ft=gitcommit
:autocmd Filetype gitcommit setlocal spell spelllang=en
:autocmd BufNewFile,BufRead *.po set spell spelllang=pt
:autocmd FileType sh set sw=4 ts=4 fenc=utf-8 number
:autocmd FileType groovy set sw=4 ts=4 fenc=utf-8 number et
:autocmd Filetype rst set sw=2 ts=2 et fenc=utf-8 spell spelllang=en nofoldenable
" <---- Auto-commands --------------------------------------------------------
