" Clear existing highlights and reset syntax
hi clear
syntax reset
let g:colors_name = "default"

" Inherit terminal's background (critical for dynamic themes)
hi Normal       ctermfg=NONE ctermbg=NONE guibg=NONE
hi LineNr       ctermbg=NONE guibg=NONE
hi CursorLine   ctermfg=NONE ctermbg=NONE guibg=NONE
hi SignColumn   ctermbg=NONE guibg=NONE
hi VertSplit    ctermbg=NONE guibg=NONE ctermfg=242 guifg=#6c6c6c

" Universal foreground colors (visible in light/dark)
hi Comment      ctermfg=242  guifg=#6c6c6c   " Medium gray
hi Constant     ctermfg=172  guifg=#b57614   " Warm orange
hi Identifier   ctermfg=12   guifg=#4070a0   " Muted blue
hi Statement    ctermfg=136  guifg=#b58900   " Gold/yellow
hi PreProc      ctermfg=133  guifg=#8c46ae   " Purple
hi Type         ctermfg=72   guifg=#4d9375   " Teal
hi Special      ctermfg=166  guifg=#d65d0e   " Bright orange
hi String       ctermfg=108  guifg=#6c782c   " Olive green

" Improved contrast for diffs (use foreground instead of background)
hi DiffAdd      ctermfg=22   guifg=#006800 cterm=bold
hi DiffDelete   ctermfg=52   guifg=#800000 cterm=bold
hi DiffChange   ctermfg=17   guifg=#00005f cterm=bold
hi DiffText     ctermfg=21   guifg=#0000ff cterm=bold

" Adaptive popup menu
hi Pmenu        ctermbg=254  guibg=#e4e4e4 ctermfg=238  guifg=#444444
hi PmenuSel     ctermbg=33   guibg=#268bd2 ctermfg=255  guifg=#ffffff

" Status line (works in both themes)
hi StatusLine   ctermbg=242  guibg=#6c6c6c ctermfg=255  guifg=#ffffff cterm=bold
hi StatusLineNC ctermbg=242  guibg=#6c6c6c ctermfg=244  guifg=#808080

" Syntax group adjustments
hi MatchParen   ctermbg=228  guibg=#ffff87 ctermfg=16   guifg=#000000
hi Search       ctermbg=228  guibg=#ffff87 ctermfg=16   guifg=#000000
