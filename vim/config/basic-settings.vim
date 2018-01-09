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
set clipboard=unnamed                   " Use X11 clipboard
set nofoldenable                        " No folding!

" Status / Command Line Options
set wildmenu                            " Better commandline completion
set wildmode=list:longest:full          " Expand match on first Tab complete
set showcmd                             " Show (partial) command in status line
set laststatus=2                        " Always show a status line
set cmdheight=2                         " Prevent "Press Enter" message after most commands

" Interface Options
set number                              " Display line numbers at left of screen
set cursorline                          " Highlight the current line
set visualbell                          " Flash the screen instead of beeping on errors
set t_vb=                               " And then disable even the flashing
"set mouse=a                             " Enable mouse usage (all modes) in terminals
set ttimeout ttimeoutlen=200            " Quickly time out on keycodes
set notimeout                           "   but never time out on mappings
set list                                " Show tabs and trailing whitespace
set listchars=tab:⇥\ ,trail:·           " with nicer looking chars
set shortmess=atI                       " Limit Vim's "hit-enter" messages
set encoding=utf-8                      " Necessary to show Unicode glyphs
set t_Co=256                            " Explicitly tell Vim that the terminal supports 256 colors

set showmatch                           " Show matching brackets
set noautoread                          " Warn me if the file is modified outside
set term=xterm-256color                 " Yes! I want xterm-256color

" Tell vim to backup files
set backup
if !isdirectory($HOME."/.vim/tmp")
  silent! execute "!mkdir ~/.vim/tmp"
endif
set backupdir=$HOME/.vim/tmp//
"set directory^=$HOME/.vim/tmp/
set noswapfile

" Let airline tell me my status
set noshowmode
filetype on
set tabstop=2 shiftwidth=2 expandtab
set conceallevel=0

" Configure backups
let undo_dir_path = expand($HOME."/.vim/tmp/undo")
if !isdirectory(undo_dir_path)
silent! execute "!mkdir " . undo_dir_path
endif
set undofile
set undodir=undo_dir_path
