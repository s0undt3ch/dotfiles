" ----- Local Vim Configuration File Settings ------------------------------->
"  Filename of local vimrc files
let g:localvimrc_name = '.lvimrc'

" Source the found local vimrc files in a sandbox for security reasons
" Value	Description
" 0	Don't load vimrc file in a sandbox.
" 1	Load vimrc file in a sandbox.
"
" Default: 1
let g:localvimrc_sandbox = 1


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
" <---- Local Vim Configuration File Settings --------------------------------
"
