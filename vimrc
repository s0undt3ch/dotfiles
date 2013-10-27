" Use Vim not vi
" "----------------
set nocompatible

" Inject the powerline vim plugin into the pathogen search
set rtp+=~/.vim/bundle/powerline/powerline/bindings/vim

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
set viminfo='1000,f1,<500,:100,/100,h,! " Keep various histories between edits

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
set clipboard=unnamedplus               " Use X11 clipboard


" Status / Command Line Options
set wildmenu                            " Better commandline completion
set wildmode=list:longest:full          " Expand match on first Tab complete
set showcmd                             " Show (partial) command in status line
set laststatus=2                        " Always show a status line
set cmdheight=2                         " Prevent "Press Enter" message after most commands

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

if has("gui_running")
  colorscheme fruity
else
  colorscheme fruity-term
  highlight ColorColumn ctermbg=233       " Visible color column in terminals
endif

" ----- Include and Source any *.vim files in ~/.vimrc.d/ ------------------->
for fpath in split(globpath('~/.vimrc.d/', '*.vim'), '\n')
  exe 'source' fpath
endfor
" <---- Include and Source any *.vim files in ~/.vimrc.d/ --------------------
