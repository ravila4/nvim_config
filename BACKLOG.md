## Backlog

### Board

| ID | Item | Priority | Status |
|----|------|----------|--------|
| T1 | Lualine time color by mode/theme | High | DONE |
| T2 | Completion menu border/background mismatch | High | TODO |
| T3 | nvzone/menu clicks not executing | High | DONE |
| T4 | Neo-tree folder/file colors (blue folders, monochrome files) | Medium | DONE |
| T5 | Shortcut + menu: Neo-tree float git_status (git_base=main) | Medium | DONE |
| T6 | Colorscheme parity light/dark: cursorline, floats, transparency | High | TODO |
| T7 | Consistent borders across Telescope/Lazy/Neo-tree/term/cmp | Medium | IN_PROGRESS |
| T12 | Evaluate completions: nvim-cmp vs blink.cmp; IDE-like kinds | High | TODO |
| T11 | Diffview colors: pastel add/remove for light theme | Medium | TODO |
| T8 | Edgy controls: collapse/pin/toggle both left panels | Medium | TODO |
| T9 | Neo-tree preview/floating preview mode | Low | TODO |
| T10| Custom diagnostic icons | Medium | TODO |
| T11| Disable move in dashboard | Low | TODO |

---

### T1 — Lualine time color by mode/theme
- Where: `lua/plugins/ui.lua` (lualine `lualine_y` time component)
- Problem: In light mode, time fg is blue (`#9cdcfe`); expected teal `#228787` in Normal, orange in Insert, etc. Match the branch/mode accent.
- Acceptance:
  - Time color matches mode accent in both light/dark.
  - Uses theme-aware palette; no hardcoded mismatched blue.
- Approach: Replace static `color = { fg = ... }` with a function returning fg by `vim.fn.mode()` and `vim.o.background`. Reuse existing teal `#228787` and insert orange from palette.
- Docs: Update `FEATURES.md` statusline section to describe time color behavior.

### T2 — Completion menu border/background mismatch
- Where: `lua/plugins/completion.lua` (nvim-cmp) — not present yet; create/configure.
- Problem: cmp popup border/background slightly darker than light buffer (`#f6f5f4`).
- Acceptance:
  - `Pmenu`, `PmenuSel`, `CmpBorder`, `FloatBorder`, `NormalFloat` look consistent with Adwaita light/dark.
  - Borders match Telescope style from `ui.lua`.
- Approach: Configure `cmp.setup.window` with `border = 'rounded'` and custom highlights; define autocmd to set highlight groups theme-aware, aligning with Telescope border colors already set in `ui.lua`.
- Docs: Note popup styling consistency in `FEATURES.md`.

### T3 — nvzone/menu clicks not executing
- Where: `lua/plugins/ui.lua` (nvzone/menu config, context and sub-menus)
- Problem: Right-click opens, but most items do nothing when clicked; terminal submenu works.
- Acceptance:
  - Clicking each menu item triggers its command reliably.
  - Keyboard invocations continue to work.
- Approach:
  - Verify `menu.open` expects `cmd` as lua function vs Ex command string. Wrap strings with a function calling `vim.cmd(cmd)`.
  - Ensure dependent commands (BufferLine, Diffview, Neo-tree) are loaded before execution (use `cmd`-based lazy triggers or `pcall` + `vim.schedule`).
  - Fix incorrect commands in menu definitions:
    - Use `BufferLineTogglePin` (not `BufferPin`).
    - Use `BufferLinePick` / `BufferLinePickClose` as appropriate (not `BufferPick`).
    - Prefer existing bufferline commands: `BufferLineCloseLeft/Right`, `BufferLineGroupClose ungrouped`.
- Docs: Mention right-click context menu and working submenus in `FEATURES.md`.

### T4 — Neo-tree folder/file colors
- Where: `lua/plugins/layout.lua` (`neo-tree` setup)
- Problem: Folders/files tinted with warn/yellow; prefer blue folders (like `ls`) and monochrome files. Diagnostics already have icons.
- Acceptance:
  - Folder names rendered blue; file names monochrome.
  - Diagnostic coloring does not change filename fg; only icons/signs show status.
- Approach: Set `NeoTreeDirectoryName` to Adwaita blue, keep `NeoTreeFileName` default; disable severity-based name highlights via `enable_diagnostics = true` but override highlights. Optionally tweak `default_component_configs` `name` component `use_git_status_colors = false`.
- Docs: Document the blue folder/monochrome file styling.

### T5 — Shortcut/menu for Neo-tree float git_status
- Where: `lua/config/keymaps.lua`, `lua/plugins/ui.lua` (Git menu)
- Acceptance:
  - Key: `<leader>gS` opens `:Neotree float git_status git_base=main`.
  - Menu item under Git opens same.
- Approach: Add keymap + add entry to Git menu (`cmd = "Neotree float git_status git_base=main"`).
- Docs: Add `<leader>gS` to Git keymap table in `FEATURES.md`.

### T6 — Colorscheme parity light/dark
- Where: global highlights (autocmd), `lua/plugins/snacks.lua`, `lua/config/settings.lua`
- Problems observed:
  - Dark: transparent buffer bg, but cursorline is opaque black; floating windows non-transparent.
  - Light: no transparency; cursorline highlight not prominent; only number highlighted.
- Acceptance:
  - Cursorline subtle in both modes (bg-only, theme-aware).
  - `NormalFloat`/`FloatBorder` consistent with Telescope borders; dark uses slight transparency, light uses solid for contrast.
  - No jarring mismatches across panels/floats.
- Approach: Add a single function to set `CursorLine`, `NormalFloat`, `FloatBorder`, and reuse it on `ColorScheme`/startup. Keep light mode non-transparent to preserve contrast; use slight transparency/darker bg in dark.
- Docs: Describe cursorline/floats behavior for both modes.

### T7 — Border consistency across popups
- Where: `ui.lua` (Telescope already handled), `completion.lua`, `layout.lua` (neo-tree popups), toggleterm floats
- Acceptance:
  - Borders are rounded and share the same blue fg across all popups.
- Approach: Apply same border chars and neutral gray (`#d0d0d0` light / `#404040` dark) to `FloatBorder`/`CmpBorder`/neo-tree popups; set toggleterm float to rounded gray border.
- Docs: State unified border style in `FEATURES.md`.

### T8 — Edgy collapse/pin/toggle both left panels
- Where: `lua/config/keymaps.lua`, `lua/plugins/layout.lua`
- Acceptance:
  - Single key toggles both left panels (Files + Outline), e.g. `<leader>le`.
  - Document limitation: fully collapsing windows needs global statusline (known edgy restriction).
- Approach: Add a helper that toggles both left entries; consider `require('edgy').close/open()` targeting left; add mention in docs.
- Docs: Add the new toggle to layout keys in `FEATURES.md`.

### T9 — Neo-tree preview/floating preview
- Where: `lua/plugins/layout.lua` (neo-tree `filesystem.window`)
- Acceptance:
  - Enable/Document preview mode mapping and/or floating preview for files.
- Approach: Explore `filesystem.window` `preview` config and mappings; enable a key (e.g., `P`) to toggle preview; optionally provide floating `position = 'float'` preview window.
- Docs: Add preview key to Neo-tree section in `FEATURES.md`.

### T10 — Custom diagnostic icons
- Where: LSP setup (add to `lua/plugins/lsp.lua` or `ui.lua` if centralizing)
- Acceptance:
  - Diagnostic signs display the configured icons below in both modes.
- Snippet:
```lua
vim.diagnostic.config({
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '',
      [vim.diagnostic.severity.WARN]  = '',
      [vim.diagnostic.severity.INFO]  = '',
      [vim.diagnostic.severity.HINT]  = '󰌵',
    },
  },
})
```
- Docs: Mention custom diagnostic icons in diagnostics section.

Notes: Neo-tree configuration details are in `:h neo-tree-configuration` (online: `neo-tree.txt`).

### T11 - Disable move in dashboard
Use option:
> disable_move       -- default is false disable move keymap for hyper

---

