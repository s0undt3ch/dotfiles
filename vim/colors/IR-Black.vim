" Vim color file
" Converted from Textmate theme IR_Black using Coloration v0.3.2 (http://github.com/sickill/coloration)

set background=dark
highlight clear

if exists("syntax_on")
  syntax reset
endif

let g:colors_name = "IR-Black"

hi Cursor ctermfg=0 ctermbg=15 cterm=NONE guifg=#000000 guibg=#ffffff gui=NONE
hi Visual ctermfg=NONE ctermbg=236 cterm=NONE guifg=NONE guibg=#333333 gui=NONE
hi CursorLine ctermfg=NONE ctermbg=233 cterm=NONE guifg=NONE guibg=#181818 gui=NONE
hi CursorColumn ctermfg=NONE ctermbg=233 cterm=NONE guifg=NONE guibg=#181818 gui=NONE
hi ColorColumn ctermfg=NONE ctermbg=233 cterm=NONE guifg=NONE guibg=#181818 gui=NONE
hi LineNr ctermfg=243 ctermbg=233 cterm=NONE guifg=#777777 guibg=#181818 gui=NONE
hi VertSplit ctermfg=238 ctermbg=238 cterm=NONE guifg=#454545 guibg=#454545 gui=NONE
hi MatchParen ctermfg=117 ctermbg=NONE cterm=underline guifg=#96cbfe guibg=NONE gui=underline
hi StatusLine ctermfg=231 ctermbg=238 cterm=bold guifg=#ededed guibg=#454545 gui=bold
hi StatusLineNC ctermfg=231 ctermbg=238 cterm=NONE guifg=#ededed guibg=#454545 gui=NONE
hi Pmenu ctermfg=223 ctermbg=NONE cterm=NONE guifg=#ffd2a7 guibg=NONE gui=NONE
hi PmenuSel ctermfg=NONE ctermbg=236 cterm=NONE guifg=NONE guibg=#333333 gui=NONE
hi IncSearch ctermfg=0 ctermbg=155 cterm=NONE guifg=#000000 guibg=#a8ff60 gui=NONE
hi Search ctermfg=NONE ctermbg=NONE cterm=underline guifg=NONE guibg=NONE gui=underline
hi Directory ctermfg=114 ctermbg=NONE cterm=NONE guifg=#99cc99 guibg=NONE gui=NONE
hi Folded ctermfg=244 ctermbg=0 cterm=NONE guifg=#7c7c7c guibg=#000000 gui=NONE

hi Normal ctermfg=231 ctermbg=0 cterm=NONE guifg=#ededed guibg=#000000 gui=NONE
hi Boolean ctermfg=114 ctermbg=NONE cterm=NONE guifg=#99cc99 guibg=NONE gui=NONE
hi Character ctermfg=114 ctermbg=NONE cterm=NONE guifg=#99cc99 guibg=NONE gui=NONE
hi Comment ctermfg=244 ctermbg=NONE cterm=NONE guifg=#7c7c7c guibg=NONE gui=NONE
hi Conditional ctermfg=117 ctermbg=NONE cterm=NONE guifg=#96cbfe guibg=NONE gui=NONE
hi Constant ctermfg=114 ctermbg=NONE cterm=NONE guifg=#99cc99 guibg=NONE gui=NONE
hi Define ctermfg=117 ctermbg=NONE cterm=NONE guifg=#96cbfe guibg=NONE gui=NONE
hi DiffAdd ctermfg=231 ctermbg=64 cterm=bold guifg=#ededed guibg=#3e7b05 gui=bold
hi DiffDelete ctermfg=88 ctermbg=NONE cterm=NONE guifg=#830000 guibg=NONE gui=NONE
hi DiffChange ctermfg=231 ctermbg=17 cterm=NONE guifg=#ededed guibg=#102544 gui=NONE
hi DiffText ctermfg=231 ctermbg=24 cterm=bold guifg=#ededed guibg=#204a87 gui=bold
hi ErrorMsg ctermfg=NONE ctermbg=NONE cterm=NONE guifg=NONE guibg=NONE gui=NONE
hi WarningMsg ctermfg=NONE ctermbg=NONE cterm=NONE guifg=NONE guibg=NONE gui=NONE
hi Float ctermfg=207 ctermbg=NONE cterm=bold guifg=#ff73fd guibg=NONE gui=bold
hi Function ctermfg=223 ctermbg=NONE cterm=NONE guifg=#ffd2a7 guibg=NONE gui=NONE
hi Identifier ctermfg=186 ctermbg=NONE cterm=NONE guifg=#cfcb90 guibg=NONE gui=NONE
hi Keyword ctermfg=117 ctermbg=NONE cterm=NONE guifg=#96cbfe guibg=NONE gui=NONE
hi Label ctermfg=155 ctermbg=NONE cterm=bold guifg=#a8ff60 guibg=NONE gui=bold
hi NonText ctermfg=23 ctermbg=232 cterm=NONE guifg=#2e343a guibg=#0c0c0c gui=NONE
hi Number ctermfg=207 ctermbg=NONE cterm=bold guifg=#ff73fd guibg=NONE gui=bold
hi Operator ctermfg=231 ctermbg=NONE cterm=NONE guifg=#ededed guibg=NONE gui=NONE
hi PreProc ctermfg=117 ctermbg=NONE cterm=NONE guifg=#96cbfe guibg=NONE gui=NONE
hi Special ctermfg=231 ctermbg=NONE cterm=NONE guifg=#ededed guibg=NONE gui=NONE
hi SpecialKey ctermfg=23 ctermbg=233 cterm=NONE guifg=#2e343a guibg=#181818 gui=NONE
hi Statement ctermfg=117 ctermbg=NONE cterm=NONE guifg=#96cbfe guibg=NONE gui=NONE
hi StorageClass ctermfg=186 ctermbg=NONE cterm=NONE guifg=#cfcb90 guibg=NONE gui=NONE
hi String ctermfg=155 ctermbg=NONE cterm=bold guifg=#a8ff60 guibg=NONE gui=bold
hi Tag ctermfg=223 ctermbg=NONE cterm=NONE guifg=#ffd2a7 guibg=NONE gui=NONE
hi Title ctermfg=231 ctermbg=NONE cterm=bold guifg=#ededed guibg=NONE gui=bold
hi Todo ctermfg=244 ctermbg=NONE cterm=inverse,bold guifg=#7c7c7c guibg=NONE gui=inverse,bold
hi Type ctermfg=229 ctermbg=NONE cterm=underline guifg=#ffffb6 guibg=NONE gui=underline
hi Underlined ctermfg=NONE ctermbg=NONE cterm=underline guifg=NONE guibg=NONE gui=underline
hi rubyClass ctermfg=117 ctermbg=NONE cterm=NONE guifg=#96cbfe guibg=NONE gui=NONE
hi rubyFunction ctermfg=223 ctermbg=NONE cterm=NONE guifg=#ffd2a7 guibg=NONE gui=NONE
hi rubyInterpolationDelimiter ctermfg=NONE ctermbg=NONE cterm=NONE guifg=NONE guibg=NONE gui=NONE
hi rubySymbol ctermfg=114 ctermbg=NONE cterm=NONE guifg=#99cc99 guibg=NONE gui=NONE
hi rubyConstant ctermfg=229 ctermbg=NONE cterm=NONE guifg=#ffffb6 guibg=NONE gui=NONE
hi rubyStringDelimiter ctermfg=155 ctermbg=NONE cterm=bold guifg=#a8ff60 guibg=NONE gui=bold
hi rubyBlockParameter ctermfg=189 ctermbg=NONE cterm=NONE guifg=#c6c5fe guibg=NONE gui=NONE
hi rubyInstanceVariable ctermfg=189 ctermbg=NONE cterm=NONE guifg=#c6c5fe guibg=NONE gui=NONE
hi rubyInclude ctermfg=117 ctermbg=NONE cterm=NONE guifg=#96cbfe guibg=NONE gui=NONE
hi rubyGlobalVariable ctermfg=189 ctermbg=NONE cterm=NONE guifg=#c6c5fe guibg=NONE gui=NONE
hi rubyRegexp ctermfg=179 ctermbg=NONE cterm=NONE guifg=#e9c062 guibg=NONE gui=NONE
hi rubyRegexpDelimiter ctermfg=179 ctermbg=NONE cterm=NONE guifg=#e9c062 guibg=NONE gui=NONE
hi rubyEscape ctermfg=114 ctermbg=NONE cterm=NONE guifg=#99cc99 guibg=NONE gui=NONE
hi rubyControl ctermfg=117 ctermbg=NONE cterm=NONE guifg=#96cbfe guibg=NONE gui=NONE
hi rubyClassVariable ctermfg=189 ctermbg=NONE cterm=NONE guifg=#c6c5fe guibg=NONE gui=NONE
hi rubyOperator ctermfg=231 ctermbg=NONE cterm=NONE guifg=#ededed guibg=NONE gui=NONE
hi rubyException ctermfg=117 ctermbg=NONE cterm=NONE guifg=#96cbfe guibg=NONE gui=NONE
hi rubyPseudoVariable ctermfg=189 ctermbg=NONE cterm=NONE guifg=#c6c5fe guibg=NONE gui=NONE
hi rubyRailsUserClass ctermfg=229 ctermbg=NONE cterm=NONE guifg=#ffffb6 guibg=NONE gui=NONE
hi rubyRailsARAssociationMethod ctermfg=186 ctermbg=NONE cterm=NONE guifg=#dad085 guibg=NONE gui=NONE
hi rubyRailsARMethod ctermfg=186 ctermbg=NONE cterm=NONE guifg=#dad085 guibg=NONE gui=NONE
hi rubyRailsRenderMethod ctermfg=186 ctermbg=NONE cterm=NONE guifg=#dad085 guibg=NONE gui=NONE
hi rubyRailsMethod ctermfg=186 ctermbg=NONE cterm=NONE guifg=#dad085 guibg=NONE gui=NONE
hi erubyDelimiter ctermfg=NONE ctermbg=NONE cterm=NONE guifg=NONE guibg=NONE gui=NONE
hi erubyComment ctermfg=244 ctermbg=NONE cterm=NONE guifg=#7c7c7c guibg=NONE gui=NONE
hi erubyRailsMethod ctermfg=186 ctermbg=NONE cterm=NONE guifg=#dad085 guibg=NONE gui=NONE
hi htmlTag ctermfg=117 ctermbg=NONE cterm=bold guifg=#96cbfe guibg=NONE gui=bold
hi htmlEndTag ctermfg=117 ctermbg=NONE cterm=bold guifg=#96cbfe guibg=NONE gui=bold
hi htmlTagName ctermfg=117 ctermbg=NONE cterm=bold guifg=#96cbfe guibg=NONE gui=bold
hi htmlArg ctermfg=117 ctermbg=NONE cterm=bold guifg=#96cbfe guibg=NONE gui=bold
hi htmlSpecialChar ctermfg=114 ctermbg=NONE cterm=NONE guifg=#99cc99 guibg=NONE gui=NONE
hi javaScriptFunction ctermfg=186 ctermbg=NONE cterm=NONE guifg=#cfcb90 guibg=NONE gui=NONE
hi javaScriptRailsFunction ctermfg=186 ctermbg=NONE cterm=NONE guifg=#dad085 guibg=NONE gui=NONE
hi javaScriptBraces ctermfg=NONE ctermbg=NONE cterm=NONE guifg=NONE guibg=NONE gui=NONE
hi yamlKey ctermfg=223 ctermbg=NONE cterm=NONE guifg=#ffd2a7 guibg=NONE gui=NONE
hi yamlAnchor ctermfg=189 ctermbg=NONE cterm=NONE guifg=#c6c5fe guibg=NONE gui=NONE
hi yamlAlias ctermfg=189 ctermbg=NONE cterm=NONE guifg=#c6c5fe guibg=NONE gui=NONE
hi yamlDocumentHeader ctermfg=155 ctermbg=NONE cterm=bold guifg=#a8ff60 guibg=NONE gui=bold
hi cssURL ctermfg=189 ctermbg=NONE cterm=NONE guifg=#c6c5fe guibg=NONE gui=NONE
hi cssFunctionName ctermfg=186 ctermbg=NONE cterm=NONE guifg=#dad085 guibg=NONE gui=NONE
hi cssColor ctermfg=114 ctermbg=NONE cterm=NONE guifg=#99cc99 guibg=NONE gui=NONE
hi cssPseudoClassId ctermfg=223 ctermbg=NONE cterm=NONE guifg=#ffd7b1 guibg=NONE gui=NONE
hi cssClassName ctermfg=223 ctermbg=NONE cterm=NONE guifg=#ffd7b1 guibg=NONE gui=NONE
hi cssValueLength ctermfg=207 ctermbg=NONE cterm=bold guifg=#ff73fd guibg=NONE gui=bold
hi cssCommonAttr ctermfg=223 ctermbg=NONE cterm=NONE guifg=#ffd2a7 guibg=NONE gui=NONE
hi cssBraces ctermfg=NONE ctermbg=NONE cterm=NONE guifg=NONE guibg=NONE gui=NONE
