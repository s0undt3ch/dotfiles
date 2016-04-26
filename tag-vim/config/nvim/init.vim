" Setup NeoBundle  ----------------------------------------------------------{{{
" If neobundle is not installed, do it first
  let bundleExists = 1
  if (!isdirectory(expand("$HOME/.nvim/bundle/neobundle.vim")))
     call system(expand("mkdir -p $HOME/.nvim/bundle"))
     call system(expand("git clone https://github.com/Shougo/neobundle.vim ~/.nvim/bundle/neobundle.vim"))
     let bundleExists = 0
  endif
  if 0 | endif

  if has('vim_starting')
    if &compatible
      " Be iMproved
      set nocompatible
    endif

" Required:
    set runtimepath+=~/.nvim/bundle/neobundle.vim/
  endif

" Required:
  call neobundle#begin(expand('~/.nvim/bundle/'))
  let pluginsExist = 1
" Let NeoBundle manage NeoBundle
" Required:
  NeoBundleFetch 'Shougo/neobundle.vim'

" syntax
  NeoBundle 'saltstack/salt-vim'
  NeoBundle 'Rykka/riv.vim'
  NeoBundle 'tfnico/vim-gradle'
  NeoBundle 'elubow/cql-vim'
" colorscheme & syntax highlighting
  NeoBundle 'mhartington/oceanic-next'
  "NeoBundle 'altercation/vim-colors-solarized'
  NeoBundle 'frankier/neovim-colors-solarized-truecolor-only'
  NeoBundle 'Yggdroot/indentLine'
  NeoBundle 'Raimondi/delimitMate'
  NeoBundle 'valloric/MatchTagAlways'
  NeoBundle 'ekalinin/Dockerfile.vim'
  NeoBundle 'evanmiller/nginx-vim-syntax'
  NeoBundle 'mitsuhiko/fruity-vim-colorscheme'
  NeoBundle 'luochen1990/rainbow'
 " Git helpers
  NeoBundle 'gregsexton/gitv'
  NeoBundle 'tpope/vim-fugitive'
  NeoBundle 'jreybert/vimagit'
  NeoBundle 'airblade/vim-gitgutter'
  NeoBundle 'Xuyuanp/nerdtree-git-plugin'
  "NeoBundle 'jaxbot/github-issues.vim'
" untils
  NeoBundle 'benekastah/neomake', 'e06f85e1651f5fe8841df3c85df1c51a891ccac4'
  NeoBundle 'editorconfig/editorconfig-vim'
  NeoBundle 'scrooloose/nerdtree'
  NeoBundle 'bling/vim-airline', {'depends': 'vim-airline/vim-airline-themes'}
  NeoBundle 'tpope/vim-surround'
  NeoBundle 'tomtom/tcomment_vim'
  NeoBundle 'embear/vim-localvimrc'
  "NeoBundle 'Rykka/clickable.vim'
  NeoBundle 'lambdalisue/vim-pyenv'
  NeoBundle 'janko-m/vim-test'
  NeoBundle 'kassio/neoterm'
  NeoBundle 'tmux-plugins/vim-tmux'
  NeoBundle 'edkolev/tmuxline.vim'
  NeoBundle 'milkypostman/vim-togglelist'
" Shougo
  NeoBundle 'Shougo/unite.vim'
  NeoBundle 'Shougo/unite-outline'
  NeoBundle 'ujihisa/unite-colorscheme'
  NeoBundle 'Shougo/vimfiler.vim'
  NeoBundle 'Shougo/vimproc.vim', {
        \ 'build' : {
        \     'windows' : 'tools\\update-dll-mingw',
        \     'cygwin' : 'make -f make_cygwin.mak',
        \     'mac' : 'make -f make_mac.mak',
        \     'linux' : 'make',
        \     'unix' : 'gmake',
        \    },
        \ }
  NeoBundle 'Shougo/deoplete.nvim'
  NeoBundle 'zchee/deoplete-jedi'
  NeoBundle 'Shougo/neco-vim'
  NeoBundle 'Shougo/neoinclude.vim'
  NeoBundle 'Shougo/context_filetype.vim'
  NeoBundleLazy 'ujihisa/neco-look',{'autoload':{'filetypes':['markdown']}}
  NeoBundle 'Shougo/neosnippet.vim'
  NeoBundle 'Shougo/neosnippet-snippets'
  NeoBundle 'honza/vim-snippets', {'depends': 'SirVer/ultisnips'}

  NeoBundle 'mattn/gist-vim', {'depends': 'mattn/webapi-vim'}
  NeoBundle 'rhysd/github-complete.vim'
  NeoBundle 'junegunn/goyo.vim'
  NeoBundle 'junegunn/limelight.vim'
  NeoBundle 'ryanoasis/vim-devicons'
  call neobundle#end()

" Required:
  filetype plugin indent on
  let pluginsExist=1
  NeoBundleCheck
" }}}

if pluginsExist
" System Settings  ----------------------------------------------------------{{{

"  source ~/.local.vim
" Neovim Settings
  let $NVIM_TUI_ENABLE_TRUE_COLOR=1
  let $NVIM_TUI_ENABLE_CURSOR_SHAPE=1
  let g:python_host_prog='/usr/bin/python'
  let g:python3_host_prog='/usr/bin/python3'
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
" Let airline tell me my status
  set noshowmode
  set noswapfile
  filetype on
  set tabstop=2 shiftwidth=2 expandtab
  set conceallevel=0
  set undofile
  set undodir="$HOME/.VIM_UNDO_FILES"

" Remember cursor position between vim sessions
  autocmd BufReadPost *
              \ if line("'\"") > 0 && line ("'\"") <= line("$") |
              \   exe "normal! g'\"" |
              \ endif
              " center buffer around cursor when opening files
  autocmd BufRead * normal zz

  set complete=.,w,b,u,t,k
  let g:gitgutter_max_signs = 1000  " default value
" }}}

" System mappings  ----------------------------------------------------------{{{

" No need for ex mode
  nnoremap Q <nop>
" recording macros is not my thing
  map q <Nop>
" Neovim terminal mapping
" terminal 'normal mode'
  tmap <esc> <c-\><c-n><esc><cr>
" Align blocks of text and keep them selected
  vmap < <gv
  vmap > >gv
  nnoremap <leader>d "_d
  vnoremap <leader>d "_d
  vnoremap <c-/> :TComment<cr>

" Previous/Next Buffer
  nnoremap <C-PageUp> :bnext<CR>
  nnoremap <C-PageDown> :bprev<CR>
"}}}"

" Themes, Commands, etc  ----------------------------------------------------{{{
" Theme
  let g:solarized_contrast="high"    "default value is normal
  let g:solarized_visibility="high"    "default value is normal
  let g:solarized_hitrail=1    "default value is 0
  " let g:solarized_termtrans=0
  " let g:solarized_degrade=0
  let g:solarized_bold=1
  let g:solarized_underline=1
  let g:solarized_italic=1
  let g:solarized_termcolors=256
  " let g:solarized_diffmode="normal"
  " let g:solarized_menu=1<Paste>
  syntax enable
  colorscheme solarized
  set background=dark
" highlightt the current line number
  hi CursorLineNR guifg=#ffffff
" no need to fold things in markdown all the time
  let g:vim_markdown_folding_disabled = 1
" turn on spelling for markdown files
  autocmd BufRead,BufNewFile *.md setlocal spell complete+=kspell
" highlight bad words in red
  hi SpellBad guibg=#ff2929 guifg=#ffffff" ctermbg=224
" enable deoplete
  let g:deoplete#enable_at_startup = 1
" disable markdown auto-preview. Gets annoying
  let g:instant_markdown_autostart = 0
" Keep my termo window open when I navigate away
  autocmd TermOpen * set bufhidden=hide
" Smart home
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
"}}}

" Fold, gets it's own section  ----------------------------------------------{{{

  function! MyFoldText() " {{{
      let line = getline(v:foldstart)

      let nucolwidth = &fdc + &number * &numberwidth
      let windowwidth = winwidth(0) - nucolwidth - 3
      let foldedlinecount = v:foldend - v:foldstart

      " expand tabs into spaces
      let onetab = strpart('          ', 0, &tabstop)
      let line = substitute(line, '\t', onetab, 'g')

      let line = strpart(line, 0, windowwidth - 2 -len(foldedlinecount))
      let fillcharcount = windowwidth - len(line) - len(foldedlinecount)
      return line . '…' . repeat(" ",fillcharcount) . foldedlinecount . '…' . ' '
  endfunction " }}}

  set foldtext=MyFoldText()
  autocmd InsertEnter * if !exists('w:last_fdm') | let w:last_fdm=&foldmethod | setlocal foldmethod=manual | endif
  autocmd InsertLeave,WinLeave * if exists('w:last_fdm') | let &l:foldmethod=w:last_fdm | unlet w:last_fdm | endif
  autocmd FileType vim setlocal fdc=1
  set foldlevel=99
" Space to toggle folds.
  nnoremap <Space> za
  vnoremap <Space> za
  autocmd FileType vim setlocal foldmethod=marker
  autocmd FileType vim setlocal foldlevel=0
  autocmd FileType html setlocal foldmethod=marker
  autocmd FileType html setlocal fdl=3
  autocmd FileType javascript,html,css,scss,typescript setlocal foldlevel=99
  autocmd FileType javascript,typescript,css,scss,json setlocal foldmethod=marker
  autocmd FileType javascript,typescript,css,scss,json setlocal foldmarker={,}
  au FileType html nnoremap <buffer> <leader>F zfat
" }}}

" NERDTree ------------------------------------------------------------------{{{

  map <C-\> :NERDTreeToggle<CR>
  autocmd StdinReadPre * let s:std_in=1
  " autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
  let NERDTreeShowHidden=1
  let g:NERDTreeWinSize=45
  let g:NERDTreeAutoDeleteBuffer=1
" NERDTress File highlighting
  function! NERDTreeHighlightFile(extension, fg, bg, guifg, guibg)
  exec 'autocmd FileType nerdtree highlight ' . a:extension .' ctermbg='. a:bg .' ctermfg='. a:fg .' guibg='. a:guibg .' guifg='. a:guifg
  exec 'autocmd FileType nerdtree syn match ' . a:extension .' #^\s\+.*'. a:extension .'$#'
  endfunction

  call NERDTreeHighlightFile('jade', 'green', 'none', 'green', 'none')
  call NERDTreeHighlightFile('md', 'blue', 'none', '#6699CC', 'none')
  call NERDTreeHighlightFile('config', 'yellow', 'none', '#d8a235', 'none')
  call NERDTreeHighlightFile('conf', 'yellow', 'none', '#d8a235', 'none')
  call NERDTreeHighlightFile('json', 'green', 'none', '#d8a235', 'none')
  call NERDTreeHighlightFile('html', 'yellow', 'none', '#d8a235', 'none')
  call NERDTreeHighlightFile('css', 'cyan', 'none', '#5486C0', 'none')
  call NERDTreeHighlightFile('scss', 'cyan', 'none', '#5486C0', 'none')
  call NERDTreeHighlightFile('coffee', 'Red', 'none', 'red', 'none')
  call NERDTreeHighlightFile('js', 'Red', 'none', '#ffa500', 'none')
  call NERDTreeHighlightFile('ts', 'Blue', 'none', '#6699cc', 'none')
  call NERDTreeHighlightFile('ds_store', 'Gray', 'none', '#686868', 'none')
  call NERDTreeHighlightFile('gitconfig', 'black', 'none', '#686868', 'none')
  call NERDTreeHighlightFile('gitignore', 'Gray', 'none', '#7F7F7F', 'none')
"}}}

" Snipppets -----------------------------------------------------------------{{{

  "let g:deoplete#disable_auto_complete = 1

  let g:UltiSnipsSnippetsDir        = '/home/vampas/.nvim/UltiSnips/'

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

  "inoremap <silent><expr><C-@> deoplete#mappings#manual_complete()
  "inoremap <silent><expr> <c-@>
  "  \ pumvisible() ? "\<C-n>" :
  "  \ deoplete#mappings#manual_complete()

  "au BufEnter * exec "inoremap <silent> " . g:UltiSnipsExpandTrigger . " <C-R>=g:UltiSnips_Complete()<cr>"
  "au BufEnter * exec "inoremap <silent> " . g:UltiSnipsJumpBackwardTrigger . " <C-R>=g:UltiSnips_Reverse()<cr>"
  " this mapping Enter key to <C-y> to chose the current highlight item 
  " and close the selection list, same as other IDEs.
  " CONFLICT with some plugins like tpope/Endwise
  "inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
  "inoremap <silent><tab> <c-r>=CleverTab#Complete('start')<cr>
  ""                    \<c-r>=CleverTab#Complete('tab')<cr>
  ""                    \<c-r>=CleverTab#Complete('ultisnips')<cr>
  ""                    \<c-r>=CleverTab#Complete('keyword')<cr>
  ""                    \<c-r>=CleverTab#Complete('neocomplete')<cr>
  ""                    \<c-r>=CleverTab#Complete('omni')<cr>
  ""                    \<c-r>=CleverTab#Complete('stop')<cr>
  "inoremap <silent><s-tab> <c-r>=CleverTab#Complete('prev')<cr>
"}}}

" vim-airline ---------------------------------------------------------------{{{
  let g:airline#extensions#bufferline#enabled = 1
  let g:airline#extensions#hunks#enabled = 1
  let g:airline#extensions#spellcheck#enabled = 1
  let g:airline#extensions#syntastic#enabled = 0
  let g:airline#extensions#tabline#buffer_idx_mode = 1
  let g:airline#extensions#tabline#enabled = 1
  let g:airline#extensions#tabline#fnamemod = ':t'
  let g:airline#extensions#tabline#show_tab_nr = 1
  let g:airline#extensions#tmuxline#enabled = 0
  let g:airline#extensions#virtualenv#enabled = 1
  let g:airline#extensions#whitespace#enabled = 1
  let g:airline_powerline_fonts = 1
  let g:airline_theme = 'solarized'
"}}}

" Linting -------------------------------------------------------------------{{{

  autocmd! BufWritePost * Neomake
  let g:neomake_python_enabled_makers = ['pylint', 'python']

"}}}

" Autocommands --------------------------------------------------------------{{{
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
  :autocmd BufRead *.cql set syntax=cql
"}}}

" Python Virtualenvs Support ------------------------------------------------{{{
" Add the virtualenv's site-packages to vim path
  if has('python')
    py << EOF
import os
import os.path
import sys
import vim
if 'VIRTUAL_ENV' in os.environ:
    project_base_dir = os.environ['VIRTUAL_ENV']
    sys.path.insert(0, project_base_dir)
    activate_this = os.path.join(project_base_dir, 'bin/activate_this.py')
    if os.path.exists(activate_this):
        execfile(activate_this, dict(__file__=activate_this))
    else:
       old_os_path = os.environ['PATH']
       os.environ['PATH'] = project_base_dir + os.pathsep + old_os_path
       if sys.platform == 'win32':
           site_packages = os.path.join(project_base_dir, 'Lib', 'site-packages')
       else:
           site_packages = os.path.join(project_base_dir, 'lib', 'python%s' % sys.version[:3], 'site-packages')
       prev_sys_path = list(sys.path)
       import site
       site.addsitedir(site_packages)
       sys.real_prefix = sys.prefix
       sys.prefix = project_base_dir
       # Move the added items to the front of the path:
       new_sys_path = []
       for item in list(sys.path):
           if item not in prev_sys_path:
               new_sys_path.append(item)
               sys.path.remove(item)
       sys.path[:0] = new_sys_path
EOF
  endif
  if has('python3')
    py3 << EOF
import os
import os.path
import sys
import vim
if 'VIRTUAL_ENV' in os.environ:
    project_base_dir = os.environ['VIRTUAL_ENV']
    sys.path.insert(0, project_base_dir)
    activate_this = os.path.join(project_base_dir, 'bin/activate_this.py')
    if os.path.exists(activate_this):
        with open(activate_this) as rfh:
          code = compile(rfh.read(), activate_this, 'exec')
          exec(code, dict(__file__=activate_this))
    else:
       old_os_path = os.environ['PATH']
       os.environ['PATH'] = project_base_dir + os.pathsep + old_os_path
       if sys.platform == 'win32':
           site_packages = os.path.join(project_base_dir, 'Lib', 'site-packages')
       else:
           site_packages = os.path.join(project_base_dir, 'lib', 'python%s' % sys.version[:3], 'site-packages')
       prev_sys_path = list(sys.path)
       import site
       site.addsitedir(site_packages)
       sys.real_prefix = sys.prefix
       sys.prefix = project_base_dir
       # Move the added items to the front of the path:
       new_sys_path = []
       for item in list(sys.path):
           if item not in prev_sys_path:
               new_sys_path.append(item)
               sys.path.remove(item)
       sys.path[:0] = new_sys_path
EOF
  endif
"}}}

" Local Vim Configuration File Settings -------------------------------------{{{
"  Filename of local vimrc files
  let g:localvimrc_name = '.lvimrc'

  " Source the found local vimrc files in a sandbox for security reasons
  " Value	Description
  " 0	Don't load vimrc file in a sandbox.
  " 1	Load vimrc file in a sandbox.
  "
  " Default: 1
  let g:localvimrc_sandbox = 0


  " Ask before sourcing any local vimrc file.
  " In a vim session the question is only asked once as long as the local vimrc
  " file has not been changed.
  "
  " Value	Description
  " 0	Don't ask before loading a vimrc file.
  " 1	Ask before loading a vimrc file.
  let g:localvimrc_ask = 1

  " Make the decisions given when asked before sourcing local vimrc files
  " persistent over multiple vim runs. This is done by storing the decisions in
  " viminfo. Therefore it is required to include the |viminfo-!| flag in your
  " viminfo setting.
  "
  " Value	Description
  " 0	Don't store and restore any decisions.
  " 1	Store and restore decisions only if the answer was given in upper
  "       case (Y/N/A).
  " 2	Store and restore all decisions.
  "
  " Default: 0
  let g:localvimrc_persistent = 1
"}}}

" Rainbow Parentheses Settings ----------------------------------------------{{{
  let g:rainbow_active = 1 "0 if you want to enable it later via :RainbowToggle
"}}}

" GitHub Complete Settings --------------------------------------------------{{{
  let g:github_complete_api_token = join(readfile(expand('~/.github_token'), ''))
  let g:github_complete_enable_neocomplete = 1
  let g:github_complete_enable_emoji_completion = 1
  let g:github_complete_enable_issue_completion = 1
  let g:github_complete_enable_user_completion = 1
  augroup config-github-complete
        autocmd!
        autocmd FileType gitcommit setl omnifunc=github_complete#complete
  augroup END
"}}}

endif
