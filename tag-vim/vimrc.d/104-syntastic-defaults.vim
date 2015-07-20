" ----- Syntastic Global Settings ------------------------------------------->
let g:syntastic_error_symbol = '✗'
let g:syntastic_warning_symbol = '!'
let g:syntastic_python_checkers = []

if has('clientserver')
  let g:syntastic_enable_async = 1
  let g:syntastic_async_tmux_if_possible = 1
  let g:syntastic_async_tmux_new_window = 1
endif

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

