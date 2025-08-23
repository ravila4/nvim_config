# UI Theme and Styling Map

This document catalogs where key UI elements are configured, the highlight groups they use, and the colors applied for light/dark modes. Use it as a quick reference when adjusting visuals or keeping the theme consistent.

## Palette and rules
- Neutral gray borders: light `#d0d0d0`, dark `#404040`
- Selection row backgrounds: light `#f1f0ef`, dark `#37373d`
- Accent teal: `#228787`
- Adwaita blues: light `#1c71d8`, dark `#569cd6`
- Theme detection: `vim.o.background == "dark"`

## Where things are themed

| Component | File | Key location | What is set |
|---|---|---|---|
| Telescope popups | `lua/plugins/ui.lua` | Telescope `config` (autocmd ColorScheme + defer_fn) | Neutral gray `*Border`, selection row bg/caret highlights |
| Completion (nvim-cmp) | `lua/plugins/completion.lua` | `set_cmp_hl()` + `cmp.setup().window` | `Pmenu`, `PmenuSel`, `PmenuSbar`, `PmenuThumb`, `NormalFloat`; neutral `CmpBorder`/`FloatBorder`; rounded windows |
| Completion kinds/source | `lua/plugins/completion.lua` | `formatting.format` | Kind icons and source tags (LSP/Buf/Path/Snip); ghost_text off |
| ToggleTerm (float) | `lua/plugins/layout.lua` | `toggleterm.setup()` | Rounded border, neutral (by `FloatBorder`), `winblend = 0` |
| Neo-tree popups | `lua/plugins/layout.lua` | `neo-tree.setup()` | `popup_border_style = "rounded"` |
| Neo-tree names | `lua/plugins/layout.lua` | `set_neotree_highlights()` | Blue folders (`NeoTreeDirectoryName`), monochrome file names; updates on `ColorScheme` |
| Edgy panels | `lua/plugins/layout.lua` | `opts.wo.winhighlight` + `init()` of outline | `FloatBorder:EdgyBorder`, `EdgyNormal*`, `EdgyWinBar` neutral gray; light/dark aware |
| Lualine time | `lua/plugins/ui.lua` | `lualine_y` time component | Mode-aware fg: teal/orange/blue/red/green (theme-aware variants) |
| Bufferline | `lua/plugins/ui.lua` | `opts.highlights` function | Theme-aware buffer/tab colors; no bright borders; indicator uses Adwaita blue |
| Context menus (nvzone/menu) | `lua/plugins/ui.lua` | `menu_opts()` + user commands | Menus opened with rounded borders; disabled on dashboard filetypes |
| Snacks dashboard | `lua/plugins/snacks.lua` | `init()` + dashboard preset | Header/keys/descriptions use teal variants; dashboard kept clean (no context menu) |
| Diffview | `lua/plugins/layout.lua` | `hooks.diff_buf_win_enter` | Background-based diff colors; TODO T11 to soften light theme add/remove |

## Notes by element

### Borders (neutral gray)
- Telescope, nvim-cmp, ToggleTerm float, Edgy FloatBorder use neutral gray (`#d0d0d0` light / `#404040` dark).
- Neo-tree uses rounded popups and inherits border color from `FloatBorder`.
- Lazy popup currently uses its own material-like style (no border); consider overriding if we want full consistency.

### Selection rows
- Telescope `TelescopeSelection`: light `#f1f0ef`, dark `#37373d`.
- Completion `PmenuSel`: light `#f1f0ef`, dark `#37373d`.
- Neo-tree selection background is left to its defaults; file names stay monochrome.

### Accents
- Accent teal (`#228787`) appears in lualine, dashboard, and some indicators.
- Adwaita blue is retained for semantic indicators (e.g., bufferline indicator) and folder names.

## Light vs dark specifics
- All highlight functions branch on `vim.o.background`.
- Use neutral gray borders to keep visuals subtle and unified.
- Prefer background-only cues (selection rows, diffs) over bright foreground colors.

## Maintenance checklist
- Adding a new popup: set rounded border and neutral `FloatBorder` color; add a `ColorScheme` autocmd if needed.
- Adding a new selection UI: provide theme-aware selection backgrounds (light `#f1f0ef`, dark `#37373d`).
- When changing colors, verify in both themes and check: Telescope, completion, ToggleTerm float, Neo-tree popups, Edgy panels.

