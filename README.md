# Feature Documentation

Leader key is `Space`.

## External Dependencies

| Dependency | Install | Required by |
|-----------|---------|-------------|
| `lua` | `brew install lua` | Luarocks / plugin builds |
| `luarocks` | `brew install luarocks` | Some Neovim plugins |
| `yarn` | `brew install yarn` | `markdown-preview.nvim` |
| Kitty graphics protocol | Ghostty / Kitty terminal | Image rendering (`snacks.image`, `image.nvim`) |
| `jupytext` | `uv tool install jupytext` | Notebook `.ipynb` conversion |
| `pynvim` | `uv tool install pynvim` | Neovim Python provider (Molten) |
| `jupyter_client` | `pip install --user jupyter_client` | Molten kernel communication |
| `ipykernel` | `pip install --user ipykernel` | Molten kernel execution |

### Molten setup

Molten requires the Neovim Python provider. After installing the pip dependencies above:

```bash
# 1. Install Python deps
uv tool install pynvim
pip install --user jupyter_client ipykernel

# 2. Register the remote plugin (run inside Neovim)
:UpdateRemotePlugins

# 3. Restart Neovim, then initialize a kernel
#    <leader>mK  or  :MoltenInit
```

## General

| Key | Action |
|-----|--------|
| `Ctrl-t` / `<leader>m` | Context menu (all functionality) |
| `<leader>n` | Notification history |
| `<leader>un` | Dismiss all notifications |
| `F3` | Insert current date |
| `<leader>rr` | Force screen redraw |
| `<leader>z` | Zen mode |
| `<leader>.` | Scratch buffer |

## Navigation

| Key | Action |
|-----|--------|
| `Ctrl-n` | Toggle file explorer (neo-tree) |
| `<leader>e` / `<leader>E` | Toggle / focus file explorer |
| `<leader>s` | Toggle symbols/outline |
| `Ctrl-h/j/k/l` | Navigate between splits (normal + terminal mode) |
| `]b` / `[b` | Next / previous buffer |
| `<leader>bd` | Delete buffer |

### Within Neo-tree

| Key | Action |
|-----|--------|
| `/` | Fuzzy finder |
| `f` | Filter by filename |
| `H` | Toggle hidden files |
| `.` | Set root to current dir |
| `<bs>` | Navigate up |

## File Search (Telescope)

| Key | Action |
|-----|--------|
| `Ctrl-P` / `<leader>ff` | Find files |
| `Ctrl-F` / `<leader>fg` | Live grep |
| `<leader>fw` | Grep word under cursor |
| `<leader>fb` | Find buffers |
| `<leader>fr` | Recent files |
| `<leader>fc` | Commands |
| `<leader>fh` | Help tags |
| `<leader>fs` / `<leader>fS` | Document / workspace symbols |

## Layout (edgy.nvim)

| Key | Action |
|-----|--------|
| `<leader>ll` | Toggle left panel (explorer + outline) |
| `<leader>lr` | Toggle right panel (git + database) |
| `<leader>lb` | Toggle bottom panel (terminal + diagnostics) |
| `<leader>lL` | Open full IDE layout |
| `<leader>lc` | Close all panels |

## Terminal

| Key | Action |
|-----|--------|
| `<leader>tt` | Toggle terminal (bottom panel) |
| `<leader>tf` | Floating terminal |
| `<leader>tr` | REPL terminal |
| `Esc Esc` | Exit terminal mode |

## Code Analysis

- **LSP**: Python (pyright), R (r_language_server)
- **Diagnostics**: lsp_lines.nvim shows full messages as virtual lines below code
  - Toggle between virtual lines and virtual text: `<leader>ld`
- **Completion**: blink.cmp (LSP, path, snippets, buffer)
  - Tab/Shift-Tab to select (auto-inserts); Esc to cancel; Enter is always newline
  - Signature help and auto-brackets enabled
- **Syntax**: Treesitter for all major languages

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gr` | Go to references |
| `]]` / `[[` | Next / previous reference |
| `<leader>ld` | Toggle lsp_lines diagnostics |

## AI Assistance

### Copilot (inline ghost text)

| Key | Action |
|-----|--------|
| `Ctrl-l` | Accept suggestion |
| `Ctrl-j` / `Ctrl-k` | Accept word / accept line |
| `Ctrl-n` / `Ctrl-p` | Next / previous suggestion |
| `Ctrl-]` | Dismiss |

### Claude Code

| Key | Action |
|-----|--------|
| `<leader>cc` | Toggle Claude Code terminal |
| `<leader>cf` | Focus Claude Code window |
| `<leader>cs` | Smart context (visual selection > diagnostic > symbol > picker) |
| `<leader>cp` | Context picker |
| `<leader>cm` | Select model |
| `<leader>ca` / `<leader>cd` | Accept / deny diff |
| `<leader>mc` | Claude menu |

## Markdown / Documents

| Key | Action |
|-----|--------|
| `<leader>mi` | Preview image at cursor (float) |
| `<leader>mv` | Toggle Markview rendering |
| `<leader>ms` | Markview split toggle |

## Jupyter Notebooks

Opening `.ipynb` files auto-converts them to markdown via jupytext.
Changes save back to `.ipynb` format. Full LSP support in the converted view.

### Molten (inline execution)

Inline plots and output display, similar to VSCode notebooks.

| Key | Action |
|-----|--------|
| `<leader>mK` | Initialize kernel |
| `<leader>mk` | Select kernel (Telescope) |
| `<leader>mr` | Run selection |
| `<leader>ml` | Run line |
| `<leader>mc` | Re-run cell |
| `<leader>ms` / `<leader>mh` | Show / hide output |
| `<leader>md` | Delete cell output |
| `<leader>mq` | Quit kernel |

### Vim-Slime (terminal REPL)

Sends code to a terminal. Works over SSH, minimal dependencies.

| Key | Action |
|-----|--------|
| `<leader>jr` | Run cell |
| `<leader>jR` | Run cell + jump to next |
| `<leader>ja` / `<leader>jA` | Run all above / below cursor |
| `<leader>jn` / `<leader>jp` | Next / previous cell |
| `<leader>js` | Start/restart IPython |
| `<leader>jt` | Open IPython terminal |
| `<leader>jc` | Clear terminal |
| `<leader>sc` | Send current line |
| `<leader>ss` | Send text object |

## Git

| Key | Action |
|-----|--------|
| `<leader>gd` | Diffview (side-by-side) |
| `<leader>gD` | Diff against HEAD~1 |
| `<leader>gh` | File history (all files) |
| `<leader>gH` | File history (current file) |
| `<leader>gc` | Close Diffview |

### Within Diffview

| Key | Action |
|-----|--------|
| `Tab` / `Shift-Tab` | Next / previous file |
| `-` | Stage/unstage file |
| `S` / `U` | Stage / unstage all |
| `X` | Restore (discard changes) |
| `[x` / `]x` | Previous / next conflict |
| `<leader>co/ct/cb/ca` | Choose ours / theirs / base / all |

## Trailing Whitespace

- Auto-highlighted in code buffers (excluded from dashboard, telescope, etc.)
- `<leader>dw` to delete trailing spaces
