" Use Vim not vi
" "----------------
set nocompatible

" Initialize Plugin Manager
call pathogen#infect()
call pathogen#helptags()

" Filetype & Syntax Highlighting
"--------------------------------
filetype plugin indent on
syntax on

" Options
"---------
" Use :help 'option (including the ' character) to learn more about each one.

" Buffer (File) Options
set hidden                              " Edit multiple unsaved files at the same time
set confirm                             " Prompt to save unsaved changes when exiting
set viminfo='1000,f1,<500,:100,/100,h   " Keep various histories between edits

" Search Options
set hlsearch                            " Highlight searches. See below for more
set ignorecase                          " Do case insensitive matching
set smartcase                           "   except when using capital letters
set incsearch                           " Incremental search

" Insert (Edit) Options
set backspace=indent,eol,start          " Better handling of backspace key
set autoindent                          " Sane indenting when filetype not recognised
set nostartofline                       " Emulate typical editor navigation behaviour
set nopaste                             " Start in normal (non-paste) mode
set showmode                            " Necessary to show paste state in insert mode
set pastetoggle=<f11>                   " Use <F11> to toggle between 'paste' and 'nopaste'


" Status / Command Line Options
set wildmenu                            " Better commandline completion
set wildmode=list:full                  " Expand match on first Tab complete
set showcmd                             " Show (partial) command in status line
set laststatus=2                        " Always show a status line
set cmdheight=2                         " Prevent "Press Enter" message after most commands
"set statusline=%f%m%r%h%w\ [%n:%{&ff}/%Y]%=[0x\%04.4B][%03v][%p%%\ line\ %l\ of\ %L]

" Interface Options
"set number                              " Display line numbers at left of screen
set visualbell                          " Flash the screen instead of beeping on errors
set t_vb=                               " And then disable even the flashing
set mouse=a                             " Enable mouse usage (all modes) in terminals
set ttimeout ttimeoutlen=200            " Quickly time out on keycodes
set notimeout                           "   but never time out on mappings
set list                                " Show tabs and trailing whitespace
set listchars=tab:⇥\ ,trail:·           " with nicer looking chars
set shortmess=atI                       " Limit Vim's "hit-enter" messages
set encoding=utf-8                      " Necessary to show Unicode glyphs
set t_Co=256                            " Explicitly tell Vim that the terminal supports 256 colors
set showmatch                           " Show matching brackets


" =============== Some defaults for certain file types =====================
":autocmd BufNewFile  *.py   0r ~/.vim/skeleton.py
":autocmd BufNewFile  *.html   0r ~/.vim/skeleton.html
:autocmd BufNewFile,BufRead *.html set sw=2 ts=2 fenc=utf-8 et
:autocmd BufNewFile,BufRead *.xml set sw=2 ts=2 fenc=utf-8 et
":autocmd BufNewFile,BufRead *.txt set sw=4 ts=4 fenc=utf-8 et linebreak wrap
:autocmd BufNewFile,BufRead svn-commit*.tmp set wrap linebreak textwidth=0 spell spelllang=en
:autocmd BufNewFile,BufRead hg-editor-*.txt set wrap linebreak textwidth=0 spell spelllang=en
:autocmd BufNewFile,BufRead .git/COMMIT_EDITMSG set wrap linebreak textwidth=0 spell spelllang=en
:autocmd BufNewFile,BufRead *.po set spell spelllang=pt
:autocmd FileType sh set sw=4 ts=4 fenc=utf-8
" ==========================================================================

" ========== python-mode settings =================
let g:pymode_folding = 0                    " Enable python folding
let g:pymode_lint_onfly = 1                 " Run linter on the fly
let g:pymode_rope_auto_project_open = 1     " auto open existing projects
let g:pymode_lint_signs_always_visible = 1  " always show the errors vertical ruller
" =================================================

" Add some mode filters for Nerdtree
let NERDTreeIgnore = ['\.pyc$', '\.pyo$', '*.egg-info']

colorscheme fruity

" ========= Powerline settings ===================
"set guifont=Ubuntu\ Mono\ for\ Powerline\ 11
set guifont=Droid\ Sans\ Mono\ Slashed\ for\ Powerline\ 10
let g:Powerline_symbols = 'fancy'
"call Pl#Theme#InsertSegment('spell:lang', 'before', 'fileencoding')
"call Pl#Theme#InsertSegment('spell:lang', 'after', 'fileinfo')
" ================================================

" Auto Commands
"---------------
" (:help :autocmd)
if has("autocmd")
  augroup vimrc
    au!

    " Jump to last-known-position when editing files
    autocmd BufReadPost *
          \ if line("'\"") > 1 && line("'\"") <= line("$") |
          \   exe "normal! g'\"" |
          \ endif

    " Default omni completion based on syntax
    if exists("+omnifunc")
      autocmd Filetype *
            \ if &omnifunc == "" |
            \   setlocal omnifunc=syntaxcomplete#Complete |
            \ endif
    endif
  augroup END
endif

" ========== Smart Home =============
function! SmartHome()
  let first_nonblank = match(getline('.'), '\S') + 1
  if first_nonblank == 0
    return col('.') + 1 >= col('$') ? '0' : '^'
  endif
  if col('.') == first_nonblank
    return '0'  " if at first nonblank, go to start line
  endif
  return &wrap && wincol() > 1 ? 'g^' : '^'
endfunction
noremap <expr> <silent> <Home> SmartHome()
imap <silent> <Home> <C-O><Home>


" ======== Some key-bindings  =========================
" == Prev/Next Buffer
nnoremap <silent> <C-o><PAGEUP> :bn<CR>
nnoremap <silent> <C-o><PAGEDOWN> :bp<CR>
" =====================================================

" =================== UtilSnips Settings ============================
"let g:UltiSnipsDontReverseSearchPath="1"
let g:UltiSnipsJumpForwardTrigger = '<Tab>'
let g:UltiSnipsJumpBackwardTrigger = '<S-Tab>'
let g:ultisnips_python_style = 'sphinx'
let g:ultisnips_python_quoting_style = 'double'
let g:ultisnips_python_project_team = 'UfSoft.org'
let g:ultisnips_python_project_license = 'BSD'
let g:ultisnips_python_code_author = ':email:`Pedro Algarvio (pedro@algarvio.me)`'

" ----- Syntastic Global Settings ------------------------------------------->
"  All packages installation lines(apt-get install) are for debian/ubuntu
    " ----- CSS Tidy -------------------------------------------------------->
    " In order to have csstidy, remember to link:
    "  	sudo apt-get install libcroco-tools
    "  	sudo ln -sf /usr/bin/csslint-0.6 /usr/bin/csslint
    "
    " Specify additional options to csslint with this option. e.g. to disable warnings:
    "	let g:syntastic_csslint_options = "--warnings=none"
    " <---- CSS Tidy ---------------------------------------------------------

    " ----- HTML Tidy ------------------------------------------------------->
    " In order to have HTML tidy:
    " 	sudo apt-get install tidy
    "
    "
    " <---- HTML Tidy --------------------------------------------------------

    " ----- LESS ------------------------------------------------------------>
    " In order to have less support:
    " 	sudo apt-get install node-less
    "
    " To send additional options to less use the variable g:syntastic_less_options.
    " The default is:
    " 	let g:syntastic_less_options = "--no-color"
    "
    " To use less-lint instead of less set the variable g:syntastic_less_use_less_lint.
    " 	let g:syntastic_less_use_less_lint = 0
    " <---- LESS -------------------------------------------------------------

    " ----- SASS ------------------------------------------------------------>
    " In order to have sass:
    " 	sudo gem install sass
    "
    " By default do not check partials as unknown variables are a syntax error
    " let g:syntastic_sass_check_partials = 0
    " <---- SASS -------------------------------------------------------------
" <---- Syntastic Global Settings --------------------------------------------
