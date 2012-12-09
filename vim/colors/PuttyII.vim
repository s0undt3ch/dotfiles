" Vim color file - PuttyII
" Generated by http://bytefluent.com/vivify 2012-09-05
set background=dark
if version > 580
	hi clear
	if exists("syntax_on")
		syntax reset
	endif
endif

set t_Co=256
let g:colors_name = "PuttyII"

hi IncSearch guifg=#242322 guibg=#7ab8d7 guisp=#7ab8d7 gui=NONE ctermfg=235 ctermbg=110 cterm=NONE
"hi WildMenu -- no settings --
"hi SignColumn -- no settings --
hi SpecialComment guifg=#e5e1dc guibg=NONE guisp=NONE gui=NONE ctermfg=254 ctermbg=NONE cterm=NONE
hi Typedef guifg=#ffffff guibg=NONE guisp=NONE gui=NONE ctermfg=15 ctermbg=NONE cterm=NONE
hi Title guifg=#e5e1dc guibg=NONE guisp=NONE gui=bold ctermfg=254 ctermbg=NONE cterm=bold
hi Folded guifg=#747676 guibg=#242322 guisp=#242322 gui=NONE ctermfg=243 ctermbg=235 cterm=NONE
hi PreCondit guifg=#e9eec2 guibg=NONE guisp=NONE gui=NONE ctermfg=230 ctermbg=NONE cterm=NONE
hi Include guifg=#e9eec2 guibg=NONE guisp=NONE gui=NONE ctermfg=230 ctermbg=NONE cterm=NONE
hi Float guifg=#fda35e guibg=NONE guisp=NONE gui=NONE ctermfg=215 ctermbg=NONE cterm=NONE
hi StatusLineNC guifg=#e5e1dc guibg=#5c5a58 guisp=#5c5a58 gui=NONE ctermfg=254 ctermbg=59 cterm=NONE
"hi CTagsMember -- no settings --
hi NonText guifg=#404040 guibg=#2e2d2b guisp=#2e2d2b gui=NONE ctermfg=238 ctermbg=236 cterm=NONE
"hi CTagsGlobalConstant -- no settings --
hi DiffText guifg=#e5e1dc guibg=#204a87 guisp=#204a87 gui=bold ctermfg=254 ctermbg=24 cterm=bold
hi ErrorMsg guifg=#ffffff guibg=#990000 guisp=#990000 gui=NONE ctermfg=15 ctermbg=88 cterm=NONE
"hi Ignore -- no settings --
hi Debug guifg=#e5e1dc guibg=NONE guisp=NONE gui=NONE ctermfg=254 ctermbg=NONE cterm=NONE
hi PMenuSbar guifg=NONE guibg=#373635 guisp=#373635 gui=NONE ctermfg=NONE ctermbg=237 cterm=NONE
hi Identifier guifg=#e9eec2 guibg=NONE guisp=NONE gui=NONE ctermfg=230 ctermbg=NONE cterm=NONE
hi SpecialChar guifg=#e5e1dc guibg=NONE guisp=NONE gui=NONE ctermfg=254 ctermbg=NONE cterm=NONE
hi Conditional guifg=#e9eec2 guibg=NONE guisp=NONE gui=NONE ctermfg=230 ctermbg=NONE cterm=NONE
hi StorageClass guifg=#e9eec2 guibg=NONE guisp=NONE gui=NONE ctermfg=230 ctermbg=NONE cterm=NONE
hi Todo guifg=#747676 guibg=NONE guisp=NONE gui=bold,italic ctermfg=243 ctermbg=NONE cterm=bold
hi Special guifg=#e5e1dc guibg=NONE guisp=NONE gui=NONE ctermfg=254 ctermbg=NONE cterm=NONE
hi LineNr guifg=#85827f guibg=#373635 guisp=#373635 gui=NONE ctermfg=102 ctermbg=237 cterm=NONE
hi StatusLine guifg=#e5e1dc guibg=#5c5a58 guisp=#5c5a58 gui=bold ctermfg=254 ctermbg=59 cterm=bold
hi Normal guifg=#e5e1dc guibg=#242322 guisp=#242322 gui=NONE ctermfg=254 ctermbg=235 cterm=NONE
hi Label guifg=#7ab8d7 guibg=NONE guisp=NONE gui=NONE ctermfg=110 ctermbg=NONE cterm=NONE
"hi CTagsImport -- no settings --
hi PMenuSel guifg=NONE guibg=#535c72 guisp=#535c72 gui=NONE ctermfg=NONE ctermbg=60 cterm=NONE
hi Search guifg=NONE guibg=NONE guisp=NONE gui=underline ctermfg=NONE ctermbg=NONE cterm=underline
"hi CTagsGlobalVariable -- no settings --
hi Delimiter guifg=#e5e1dc guibg=NONE guisp=NONE gui=NONE ctermfg=254 ctermbg=NONE cterm=NONE
hi Statement guifg=#dbdb3d guibg=NONE guisp=NONE gui=NONE ctermfg=185 ctermbg=NONE cterm=NONE
"hi SpellRare -- no settings --
"hi EnumerationValue -- no settings --
hi Comment guifg=#747676 guibg=NONE guisp=NONE gui=italic ctermfg=243 ctermbg=NONE cterm=NONE
hi Character guifg=#7ab8d7 guibg=NONE guisp=NONE gui=NONE ctermfg=110 ctermbg=NONE cterm=NONE
"hi TabLineSel -- no settings --
hi Number guifg=#fda35e guibg=NONE guisp=NONE gui=NONE ctermfg=215 ctermbg=NONE cterm=NONE
hi Boolean guifg=#6e9cbe guibg=NONE guisp=NONE gui=NONE ctermfg=67 ctermbg=NONE cterm=NONE
hi Operator guifg=#e9eec2 guibg=NONE guisp=NONE gui=NONE ctermfg=230 ctermbg=NONE cterm=NONE
hi CursorLine guifg=NONE guibg=#373635 guisp=#373635 gui=NONE ctermfg=NONE ctermbg=237 cterm=NONE
"hi Union -- no settings --
"hi TabLineFill -- no settings --
"hi Question -- no settings --
hi WarningMsg guifg=#ffffff guibg=#990000 guisp=#990000 gui=NONE ctermfg=15 ctermbg=88 cterm=NONE
"hi VisualNOS -- no settings --
hi DiffDelete guifg=#8a0707 guibg=NONE guisp=NONE gui=NONE ctermfg=88 ctermbg=NONE cterm=NONE
"hi ModeMsg -- no settings --
hi CursorColumn guifg=NONE guibg=#373635 guisp=#373635 gui=NONE ctermfg=NONE ctermbg=237 cterm=NONE
hi Define guifg=#e9eec2 guibg=NONE guisp=NONE gui=NONE ctermfg=230 ctermbg=NONE cterm=NONE
hi Function guifg=#d5584b guibg=NONE guisp=NONE gui=NONE ctermfg=167 ctermbg=NONE cterm=NONE
"hi FoldColumn -- no settings --
hi PreProc guifg=#e9eec2 guibg=NONE guisp=NONE gui=NONE ctermfg=230 ctermbg=NONE cterm=NONE
"hi EnumerationName -- no settings --
hi Visual guifg=NONE guibg=#535c72 guisp=#535c72 gui=NONE ctermfg=NONE ctermbg=60 cterm=NONE
"hi MoreMsg -- no settings --
"hi SpellCap -- no settings --
hi VertSplit guifg=#5c5a58 guibg=#5c5a58 guisp=#5c5a58 gui=NONE ctermfg=59 ctermbg=59 cterm=NONE
hi Exception guifg=#bf372e guibg=NONE guisp=NONE gui=NONE ctermfg=1 ctermbg=NONE cterm=NONE
hi Keyword guifg=#e9eec2 guibg=NONE guisp=NONE gui=NONE ctermfg=230 ctermbg=NONE cterm=NONE
hi Type guifg=#ffffff guibg=NONE guisp=NONE gui=NONE ctermfg=15 ctermbg=NONE cterm=NONE
hi DiffChange guifg=#e5e1dc guibg=#223755 guisp=#223755 gui=NONE ctermfg=254 ctermbg=17 cterm=NONE
hi Cursor guifg=#242322 guibg=#ffffff guisp=#ffffff gui=NONE ctermfg=235 ctermbg=15 cterm=NONE
"hi SpellLocal -- no settings --
hi Error guifg=#00aaff guibg=NONE guisp=NONE gui=NONE ctermfg=39 ctermbg=NONE cterm=NONE
hi PMenu guifg=#ffffff guibg=NONE guisp=NONE gui=NONE ctermfg=15 ctermbg=NONE cterm=NONE
hi SpecialKey guifg=#404040 guibg=#373635 guisp=#373635 gui=NONE ctermfg=238 ctermbg=237 cterm=NONE
hi Constant guifg=#7ab8d7 guibg=NONE guisp=NONE gui=NONE ctermfg=110 ctermbg=NONE cterm=NONE
"hi DefinedName -- no settings --
hi Tag guifg=#e87658 guibg=NONE guisp=NONE gui=NONE ctermfg=209 ctermbg=NONE cterm=NONE
hi String guifg=#57c757 guibg=NONE guisp=NONE gui=NONE ctermfg=77 ctermbg=NONE cterm=NONE
hi PMenuThumb guifg=NONE guibg=#85827f guisp=#85827f gui=NONE ctermfg=NONE ctermbg=102 cterm=NONE
hi MatchParen guifg=#e9eec2 guibg=NONE guisp=NONE gui=underline ctermfg=230 ctermbg=NONE cterm=underline
"hi LocalVariable -- no settings --
hi Repeat guifg=#ffffff guibg=NONE guisp=NONE gui=NONE ctermfg=15 ctermbg=NONE cterm=NONE
"hi SpellBad -- no settings --
"hi CTagsClass -- no settings --
hi Directory guifg=#7ab8d7 guibg=NONE guisp=NONE gui=NONE ctermfg=110 ctermbg=NONE cterm=NONE
hi Structure guifg=#ffffff guibg=NONE guisp=NONE gui=NONE ctermfg=15 ctermbg=NONE cterm=NONE
hi Macro guifg=#e9eec2 guibg=NONE guisp=NONE gui=NONE ctermfg=230 ctermbg=NONE cterm=NONE
hi Underlined guifg=NONE guibg=NONE guisp=NONE gui=underline ctermfg=NONE ctermbg=NONE cterm=underline
hi DiffAdd guifg=#e5e1dc guibg=#46820c guisp=#46820c gui=bold ctermfg=254 ctermbg=64 cterm=bold
"hi TabLine -- no settings --
hi htmlarg guifg=#e87658 guibg=NONE guisp=NONE gui=NONE ctermfg=209 ctermbg=NONE cterm=NONE
hi javascriptfunction guifg=#e9eec2 guibg=NONE guisp=NONE gui=NONE ctermfg=230 ctermbg=NONE cterm=NONE
hi cssfunctionname guifg=#d4584b guibg=NONE guisp=NONE gui=NONE ctermfg=167 ctermbg=NONE cterm=NONE
hi erubycomment guifg=#747676 guibg=NONE guisp=NONE gui=italic ctermfg=243 ctermbg=NONE cterm=NONE
hi rubyclass guifg=#e9eec2 guibg=NONE guisp=NONE gui=NONE ctermfg=230 ctermbg=NONE cterm=NONE
hi rubyrailsarmethod guifg=#d4584b guibg=NONE guisp=NONE gui=NONE ctermfg=167 ctermbg=NONE cterm=NONE
hi htmlspecialchar guifg=#7ab8d7 guibg=NONE guisp=NONE gui=NONE ctermfg=110 ctermbg=NONE cterm=NONE
hi rubyexception guifg=#e9eec2 guibg=NONE guisp=NONE gui=NONE ctermfg=230 ctermbg=NONE cterm=NONE
hi csscommonattr guifg=#fda35e guibg=NONE guisp=NONE gui=NONE ctermfg=215 ctermbg=NONE cterm=NONE
hi rubyescape guifg=#fda35e guibg=NONE guisp=NONE gui=NONE ctermfg=215 ctermbg=NONE cterm=NONE
hi rubyfunction guifg=#d5584b guibg=NONE guisp=NONE gui=NONE ctermfg=167 ctermbg=NONE cterm=NONE
"hi rubyrailsuserclass -- no settings --
"hi cssbraces -- no settings --
hi rubyglobalvariable guifg=#7ab8d7 guibg=NONE guisp=NONE gui=NONE ctermfg=110 ctermbg=NONE cterm=NONE
hi htmltagname guifg=#e87658 guibg=NONE guisp=NONE gui=NONE ctermfg=209 ctermbg=NONE cterm=NONE
"hi rubyblockparameter -- no settings --
hi erubyrailsmethod guifg=#d4584b guibg=NONE guisp=NONE gui=NONE ctermfg=167 ctermbg=NONE cterm=NONE
hi javascriptrailsfunction guifg=#d4584b guibg=NONE guisp=NONE gui=NONE ctermfg=167 ctermbg=NONE cterm=NONE
"hi javascriptbraces -- no settings --
hi rubyregexpdelimiter guifg=#7ab8d7 guibg=NONE guisp=NONE gui=NONE ctermfg=110 ctermbg=NONE cterm=NONE
hi csscolor guifg=#7ab8d7 guibg=NONE guisp=NONE gui=NONE ctermfg=110 ctermbg=NONE cterm=NONE
"hi rubyconstant -- no settings --
hi rubyrailsmethod guifg=#d4584b guibg=NONE guisp=NONE gui=NONE ctermfg=167 ctermbg=NONE cterm=NONE
"hi erubydelimiter -- no settings --
hi rubypseudovariable guifg=#7ab8d7 guibg=NONE guisp=NONE gui=NONE ctermfg=110 ctermbg=NONE cterm=NONE
hi rubyrailsarassociationmethod guifg=#d4584b guibg=NONE guisp=NONE gui=NONE ctermfg=167 ctermbg=NONE cterm=NONE
hi rubyrailsrendermethod guifg=#d4584b guibg=NONE guisp=NONE gui=NONE ctermfg=167 ctermbg=NONE cterm=NONE
hi rubyinstancevariable guifg=#7ab8d7 guibg=NONE guisp=NONE gui=NONE ctermfg=110 ctermbg=NONE cterm=NONE
"hi rubyinterpolationdelimiter -- no settings --
"hi rubyclassvariable -- no settings --
hi htmltag guifg=#e87658 guibg=NONE guisp=NONE gui=NONE ctermfg=209 ctermbg=NONE cterm=NONE
hi rubycontrol guifg=#e9eec2 guibg=NONE guisp=NONE gui=NONE ctermfg=230 ctermbg=NONE cterm=NONE
hi yamlalias guifg=#7ab8d7 guibg=NONE guisp=NONE gui=NONE ctermfg=110 ctermbg=NONE cterm=NONE
hi csspseudoclassid guifg=#e87658 guibg=NONE guisp=NONE gui=NONE ctermfg=209 ctermbg=NONE cterm=NONE
hi colorcolumn guifg=NONE guibg=#373635 guisp=#373635 gui=NONE ctermfg=NONE ctermbg=237 cterm=NONE
hi cssvaluelength guifg=#fda35e guibg=NONE guisp=NONE gui=NONE ctermfg=215 ctermbg=NONE cterm=NONE
hi rubystringdelimiter guifg=#7ab8d7 guibg=NONE guisp=NONE gui=NONE ctermfg=110 ctermbg=NONE cterm=NONE
hi yamldocumentheader guifg=#7ab8d7 guibg=NONE guisp=NONE gui=NONE ctermfg=110 ctermbg=NONE cterm=NONE
hi yamlanchor guifg=#7ab8d7 guibg=NONE guisp=NONE gui=NONE ctermfg=110 ctermbg=NONE cterm=NONE
hi rubyregexp guifg=#7ab8d7 guibg=NONE guisp=NONE gui=NONE ctermfg=110 ctermbg=NONE cterm=NONE
hi rubysymbol guifg=#7ab8d7 guibg=NONE guisp=NONE gui=NONE ctermfg=110 ctermbg=NONE cterm=NONE
"hi cssurl -- no settings --
hi rubyinclude guifg=#e9eec2 guibg=NONE guisp=NONE gui=NONE ctermfg=230 ctermbg=NONE cterm=NONE
hi cssclassname guifg=#e87658 guibg=NONE guisp=NONE gui=NONE ctermfg=209 ctermbg=NONE cterm=NONE
hi yamlkey guifg=#e87658 guibg=NONE guisp=NONE gui=NONE ctermfg=209 ctermbg=NONE cterm=NONE
hi rubyoperator guifg=#e9eec2 guibg=NONE guisp=NONE gui=NONE ctermfg=230 ctermbg=NONE cterm=NONE
"hi clear -- no settings --
hi htmlendtag guifg=#e87658 guibg=NONE guisp=NONE gui=NONE ctermfg=209 ctermbg=NONE cterm=NONE
