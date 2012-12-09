" Vim syntax file
" Language:    Myghty (Python embedded in HTML)
" Maintainer:  Michal Salaban <michalREMOVETHIS@salaban.info>
" Last change: 2006 Jun 27
"
" This script is based on mason.vim by Andrew Smith.
"
" It was created simply by replacing all [Pp]erl occurences by [Pp]ython :)
" Then I just modified some of the regular expressions to match differences
" between Mason and Myghty syntax.
" Seems to work fine for me.
"

" Clear previous syntax settings unless this is v6 or above, in which case just
" exit without doing anything.
"
if version < 600
	syn clear
elseif exists("b:current_syntax")
	finish
endif

" The HTML syntax file included below uses this variable.
"
if !exists("main_syntax")
	let main_syntax = 'myghty'
endif

" First pull in the HTML syntax.
"
if version < 600
	so <sfile>:p:h/html.vim
else
	runtime! syntax/html.vim
	unlet b:current_syntax
endif

syn cluster htmlPreproc add=@myghtyTop

" Now pull in the python syntax.
"
if version < 600
	syn include @pythonTop <sfile>:p:h/python.vim
else
	syn include @pythonTop syntax/python.vim
endif

" It's hard to reduce down to the correct sub-set of python to highlight in some
" of these cases so I've taken the safe option of just using pythonTop in all of
" them. If you have any suggestions, please let me know.
"
syn region myghtyLine matchgroup=Delimiter start="^%" end="$" contains=@pythonTop
syn region myghtyExpr matchgroup=Delimiter start="<%" end="%>" contains=@pythonTop
syn region myghtypython matchgroup=Delimiter start="<%python[^>]*>" end="</%python>" contains=@pythonTop
syn region myghtyComp keepend matchgroup=Delimiter start="<&" end="&>" contains=@pythonTop

syn region myghtyArgs matchgroup=Delimiter start="<%args[^>]*>" end="</%args>" contains=@pythonTop

syn region myghtyInit matchgroup=Delimiter start="<%init>" end="</%init>" contains=@pythonTop
syn region myghtyCleanup matchgroup=Delimiter start="<%cleanup>" end="</%cleanup>" contains=@pythonTop
syn region myghtyOnce matchgroup=Delimiter start="<%once>" end="</%once>" contains=@pythonTop
syn region myghtyGlobal matchgroup=Delimiter start="<%global>" end="</%global>" contains=@pythonTop
syn region myghtyShared matchgroup=Delimiter start="<%shared>" end="</%shared>" contains=@pythonTop
syn region myghtyReqLocal matchgroup=Delimiter start="<%requestlocal>" end="</%requestlocal>" contains=@pythonTop
syn region myghtyReqOnce matchgroup=Delimiter start="<%requestonce>" end="</%requestonce>" contains=@pythonTop

syn region myghtyDef matchgroup=Delimiter start="<%def[^>]*>" end="</%def>" contains=@htmlTop
syn region myghtyMethod matchgroup=Delimiter start="<%method[^>]*>" end="</%method>" contains=@htmlTop

syn region myghtyFlags matchgroup=Delimiter start="<%flags>" end="</%flags>" contains=@pythonTop
syn region myghtyAttr matchgroup=Delimiter start="<%attr>" end="</%attr>" contains=@pythonTop

syn region myghtyFilter matchgroup=Delimiter start="<%filter>" end="</%filter>" contains=@pythonTop

syn region myghtyDoc matchgroup=Delimiter start="<%doc>" end="</%doc>"
syn region myghtyText matchgroup=Delimiter start="<%text>" end="</%text>"

syn cluster myghtyTop contains=myghtyLine,myghtyExpr,myghtypython,myghtyComp,myghtyArgs,myghtyInit,myghtyCleanup,myghtyOnce,myghtyGlobal,myghtyShared,myghtyReqLocal,myghtyReqOnce,myghtyDef,myghtyMethod,myghtyFlags,myghtyAttr,myghtyFilter,myghtyDoc,myghtyText

" Set up default highlighting. Almost all of this is done in the included
" syntax files.
"
if version >= 508 || !exists("did_myghty_syn_inits")
	if version < 508
		let did_myghty_syn_inits = 1
		com -nargs=+ HiLink hi link <args>
	else
		com -nargs=+ HiLink hi def link <args>
	endif

	HiLink myghtyDoc Comment

	delc HiLink
endif

let b:current_syntax = "myghty"

if main_syntax == 'myghty'
	unlet main_syntax
endif
