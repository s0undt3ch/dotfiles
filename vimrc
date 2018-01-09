let g:pluginsExist=0
source $HOME/.vim/config/setup-plugin-manager.vim

if g:pluginsExist
  source $HOME/.vim/config/basic-settings.vim
  source $HOME/.vim/config/smart-home.vim
  source $HOME/.vim/config/auto-commands.vim
  source $HOME/.vim/config/virtualenv-support.vim
  source $HOME/.vim/config/completor-support.vim
  source $HOME/.vim/config/ultisnips-defaults.vim
  source $HOME/.vim/config/rainbow-parenteses-defaults.vim
  source $HOME/.vim/config/key-bindings.vim
  source $HOME/.vim/config/gitgutter-defaults.vim
  source $HOME/.vim/config/markdown-settings.vim
  source $HOME/.vim/config/theme-settings.vim
  source $HOME/.vim/config/airline-settings.vim
  source $HOME/.vim/config/ale-settings.vim
  if has("gui_running")
    source $HOME/.vim/config/gui-settings.vim
  endif
  " Lastly, localvimrc to allow overriding configs
  source $HOME/.vim/config/localvimrc-defaults.vim
endif

" Current left overs
"  set complete=.,w,b,u,t,k

