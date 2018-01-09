" ----- Previous/Next Buffer ------------------------------------------------>
nnoremap <C-PageUp> :bnext<CR>
nnoremap <C-PageDown> :bprev<CR>
" <---- Previous/Next Buffer -------------------------------------------------

" Indends blocs of code without loosing the selection
vnoremap < <gv
vnoremap > >gv
" <---- Indent Sections of Code ----------------------------------------------

" No need for ex mode
  nnoremap Q <nop>
" recording macros is not my thing
  map q <Nop>
