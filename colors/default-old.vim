" Vim color file

hi clear
let g:colors_name="default"

"
" Support for 256-color terminal
"

if &t_Co > 255
   hi Boolean         ctermfg=135
   hi Character       ctermfg=144
   hi Number          ctermfg=135
   hi String          ctermfg=14
   hi Conditional     ctermfg=10               cterm=bold
   hi Constant        ctermfg=135              cterm=bold
   hi Cursor          ctermfg=16  ctermbg=None
   hi Debug           ctermfg=224              cterm=bold
   hi Define          ctermfg=39
   hi Delimiter       ctermfg=247

   hi DiffAdd                     ctermbg=24
   hi DiffChange      ctermfg=181 ctermbg=240
   hi DiffDelete      ctermfg=168 ctermbg=53
   hi DiffText                    ctermbg=102  cterm=bold

   hi Directory       ctermfg=118              cterm=bold
   hi Error           ctermfg=219 ctermbg=89
   hi ErrorMsg        ctermfg=199 ctermbg=16   cterm=bold
   hi Exception       ctermfg=10               cterm=bold
   hi Float           ctermfg=135
   hi FoldColumn      ctermfg=67  ctermbg=16
   hi Folded          ctermfg=67  ctermbg=16
   hi Function        ctermfg=39
   hi Identifier      ctermfg=208
   hi Ignore          ctermfg=244 ctermbg=16
   hi IncSearch       ctermfg=193 ctermbg=16

   hi Keyword         ctermfg=2                cterm=bold
   hi Label           ctermfg=220              cterm=none
   hi Macro           ctermfg=193
   hi SpecialKey      ctermfg=39

   hi MatchParen      ctermfg=208  ctermbg=0   cterm=bold
   hi ModeMsg         ctermfg=220
   hi MoreMsg         ctermfg=220
   hi Operator        ctermfg=10

   " complete menu
   hi Pmenu           ctermfg=7   ctermbg=0
   hi PmenuSel        ctermfg=15  ctermbg=33
   hi PmenuSbar                   ctermbg=241
   hi PmenuThumb      ctermfg=39

   hi PreCondit       ctermfg=118              cterm=bold
   hi PreProc         ctermfg=10
   hi Question        ctermfg=39
   hi Repeat          ctermfg=10               cterm=bold
   hi Search          ctermfg=253 ctermbg=66

   " marks column
   hi SignColumn      ctermfg=118 ctermbg=235
   hi SpecialChar     ctermfg=10               cterm=bold
   hi SpecialComment  ctermfg=245              cterm=bold
   hi Special         ctermfg=39
   hi SpecialKey      ctermfg=245

   hi Statement       ctermfg=10               cterm=bold
   hi StatusLine      ctermfg=238 ctermbg=0
   hi StatusLineNC    ctermfg=244 ctermbg=0
   hi StorageClass    ctermfg=208
   hi Structure       ctermfg=39
   hi Tag             ctermfg=161
   hi Title           ctermfg=166
   hi Todo            ctermfg=231 ctermbg=0    cterm=bold

   hi Typedef         ctermfg=39
   hi Type            ctermfg=39               cterm=none
   hi Underlined      ctermfg=244              cterm=underline

   hi VertSplit       ctermfg=236 ctermbg=236  cterm=bold
   hi VisualNOS                   ctermbg=235
   hi Visual                      ctermbg=24
   hi WarningMsg      ctermfg=231 ctermbg=238  cterm=bold
   hi WildMenu        ctermfg=238  ctermbg=8

   hi Comment         ctermfg=8
   hi CursorLine                  ctermbg=none    cterm=none
   hi CursorColumn                ctermbg=none
   hi LineNr          ctermfg=8   ctermbg=none
end
