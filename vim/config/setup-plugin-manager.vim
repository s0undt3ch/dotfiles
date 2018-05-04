" If dein is not installed, do it first
let s:dein_dir = expand("$HOME/.cache/dein-vim")
let s:dein_repo_dir = s:dein_dir . '/repos/github.com/Shougo/dein.vim'
if has('vim_starting')
  execute 'set runtimepath^=' . fnamemodify(s:dein_repo_dir, ':p')
endif
if (!isdirectory(s:dein_repo_dir))
   call system("mkdir -p " . s:dein_dir)
   call system("git clone https://github.com/Shougo/dein.vim " . s:dein_repo_dir)
endif

if dein#load_state(s:dein_dir)
  let s:toml      = expand('~/.vim/plugins.toml')
  let s:lazy_toml = expand('~/.vim/lazy-plugins.toml')

  "call dein#begin(s:dein_dir,[$MYVIMRC,s:toml,s:lazy_toml])
  call dein#begin(s:dein_dir)

  call dein#add(s:dein_repo_dir)

  call dein#load_toml(s:toml,      {'lazy': 0})
  call dein#load_toml(s:lazy_toml, {'lazy': 1})

  call dein#end()
  call dein#save_state()
endif

if dein#check_install(['vimproc.vim'])
  call dein#install(['vimproc.vim'])
endif

if dein#check_install()
  call dein#install()
endif
let g:pluginsExist=1

filetype plugin indent on
