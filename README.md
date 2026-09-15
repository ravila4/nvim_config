# Feature Documentation

Leader key is `Space`.

## Table of Contents

- [External Dependencies](#external-dependencies)
  - [Molten setup](#molten-setup)
- [General](#general)
- [Navigation](#navigation)
  - [Within Neo-tree](#within-neo-tree)
- [File Search (Telescope)](#file-search-telescope)
- [Layout (edgy.nvim)](#layout-edgynvim)
- [Terminal](#terminal)
- [Code Analysis](#code-analysis)
- [AI Assistance](#ai-assistance)
  - [Copilot](#copilot-inline-ghost-text)
  - [Claude Code](#claude-code)
  - [Quick Edit](#quick-edit-inline-llm)
- [Markdown / Documents](#markdown--documents)
- [Jupyter Notebooks](#jupyter-notebooks)
  - [Molten](#molten-inline-execution)
  - [Set up the global notebook environment](#set-up-the-global-notebook-environment)
  - [Databricks](#databricks)
  - [Vim-Slime](#vim-slime-terminal-repl)
- [Git](#git)
  - [Within Diffview](#within-diffview)
- [Trailing Whitespace](#trailing-whitespace)

## External Dependencies

| Dependency | Install | Required by |
|-----------|---------|-------------|
| `lua` | `brew install lua` | Luarocks / plugin builds |
| `luarocks` | `brew install luarocks` | Some Neovim plugins |
| `yarn` | `brew install yarn` | `markdown-preview.nvim` |
| Kitty graphics protocol | Ghostty / Kitty terminal | Image rendering with `snacks.image` |
| `jupytext` | `uv tool install jupytext` | Notebook `.ipynb` conversion |
| `databricks-nvim` | See [Databricks](#databricks) | Managed Databricks notebook kernels |
| Stable Python host | See Molten setup below | Neovim Python provider and Molten kernel communication |
| `ipykernel` | Install in each kernel environment | Molten kernel execution |

### Molten setup

Molten uses a stable, editor-owned Python environment so project dependency changes cannot break Neovim's remote-plugin host:

```bash
# 1. Create the host configured by lua/config/settings.lua
uv venv ~/.local/share/nvim/python-host
uv pip install \
  --python ~/.local/share/nvim/python-host/bin/python \
  pynvim jupyter_client nbformat

# 2. Register the remote plugin (run inside Neovim)
:UpdateRemotePlugins
```

Install `ipykernel` and workload-specific packages in separate project environments, then register those environments as Jupyter kernelspecs.

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
| `<leader>s` | Toggle outline (headings and cells in notebooks; code symbols elsewhere) |
| `Ctrl-h/j/k/l` | Navigate between splits (normal + terminal mode) |
| `]b` / `[b` | Next / previous buffer |
| `<leader>bd` | Delete buffer |

### Within Neo-tree

| Key | Action |
|-----|--------|
| `/` | Fuzzy finder |
| `f` | Filter by filename |
| `H` | Toggle hidden files (dotfiles + gitignored) |
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
| `Ctrl-Right` / `Ctrl-Left` | Resize panel width |
| `Ctrl-Up` / `Ctrl-Down` | Resize panel height |

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

### Quick Edit (inline LLM)

Select code in visual mode, type an instruction or question, and get an inline diff overlay (edit mode) or a floating markdown response (ask mode). Default provider is `lmstudio` with `qwen2.5-coder-3b-instruct`; `claude` (haiku/sonnet/opus) also supported.

| Key | Action |
|-----|--------|
| `<leader>k` (visual) | Open Quick Edit prompt for selection |
| `:QuickEdit` | Same, from a range |
| `:QuickEditModel` | Switch provider / model |
| `<CR>` | Accept edit |
| `<Esc>` | Reject edit (restore snapshot) |
| `<Tab>` | Toggle diff overlay |

Shorthands (tab-complete in the prompt, extra text appended as context):

| Shorthand | Mode | Behavior |
|-----------|------|----------|
| `/explain` | ask | Step-by-step explanation |
| `/review` | ask | Flag bugs, edge cases, improvements |
| `/simplify` | edit | Simplify while preserving behavior |
| `/docstring` | edit | Add a docstring |
| `/types` | edit | Add type annotations |
| `/test` | edit | Write unit tests |
| `/fix` | edit | Fix diagnostics overlapping the selection |

## Markdown / Documents

| Key | Action |
|-----|--------|
| `<leader>mi` | Preview image at cursor (float) |
| `<leader>mv` | Toggle Markview rendering |
| `<leader>ms` | Markview split toggle |

## Jupyter Notebooks

Opening `.ipynb` files auto-converts them to markdown via jupytext.
Changes save back to `.ipynb` format. Full LSP support in the converted view.
Outputs saved in the notebook are shown on open without re-running it: Molten starts the notebook's kernel (or one named after the active venv) and imports them. If neither kernel is installed, run `:MoltenInit` then `:MoltenImportOutput`.

Molten comes from the `ravila4/molten-nvim` fork (branch `fix/virt-image-layout`) and uses Snacks to render plots with Kitty Unicode placeholders.

`<leader>s` opens the notebook outline: Markdown headings contain numbered code cells, titled from their first nonblank line. Enter jumps to an entry, and the outline highlights the cell containing the editor cursor. Headings represent document sections rather than original Markdown-cell boundaries.

Cell details show `not run`, `queued`, `running`, `done`, or `error`, with the execution count when available. `saved` identifies results from the notebook or loaded output state; it does not imply that the current kernel contains those variables. Editing executed code shows `modified`; executing only a portion of a cell shows `partial`. Live status requires the fork's `MoltenCellInfo` function and `MoltenCellUpdate` event. The kernel continues processing results while the outline is focused.

The notebook outline supports editing whole cells:

| Key | Action |
|-----|--------|
| `yy` / `Y` | Copy the current cell or section |
| `dd` | Cut the current cell or section |
| `V`, then `j` / `k` | Select outline rows |
| `y` / `d` | Copy / cut selected rows, or use a motion such as `dj` |
| `p` / `P` | Paste after / before the current cell or section |
| `u` / `<C-r>` | Undo / redo the notebook edit |

Counts work (`2dd`, `3p`), as do explicit registers (`"ayy`, `"ap`). A heading includes its entire section, even when folded. Selecting code rows leaves intervening prose in place. Cell fences and trailing blank lines travel with the cell.

Cut/paste within one notebook preserves execution outputs through the fork's `MoltenCellSnapshot` and `MoltenCellRestore` functions. Copies start unexecuted; queued or running cells cannot be cut. After an outline edit, saving tracks cell identity so pasting a copy before its original does not give the copy the original's saved results. Source edits and output locations also follow undo/redo from the notebook buffer.

### Molten (inline execution)

Inline plots and output display, similar to VSCode notebooks.

| Key | Action |
|-----|--------|
| `<leader>mK` / `<leader>jK` | Select kernel and remember it for this notebook |
| `<leader>jo` / `<leader>jO` | Create code cell below / above |
| `<leader>mr` | Run selection |
| `<leader>ml` | Run line |
| `<leader>mc` | Re-run cell |
| `<S-CR>` / `<C-CR>` | Run cell + move to next cell |
| `<leader><CR>` / `<leader>jr` | Run cell without moving |
| `<leader>]` / `<leader>[` or `]c` / `[c` | Next / previous cell |
| `<leader>ms` / `<leader>mh` | Show / hide output |
| `<leader>my` | Copy the image under the cursor to the clipboard (also in the right-click menu on an image) |
| `<leader>mo` | Copy the output text under the cursor to the clipboard (also in the right-click menu on an output) |
| `<leader>jv` | Enter full output view |
| `<leader>x` | Interrupt the running cell |
| `<leader>md` | Delete cell output |
| `<leader>mq` | Quit kernel |

Opening a notebook with saved outputs uses its remembered kernel choice, then the nearest project's `.venv`, then the global notebook environment. The picker opens if no suitable kernel exists. An unavailable remembered choice or recorded Databricks kernel prompts for a replacement instead of falling back automatically. Choices are stored locally under Neovim's state directory, keyed by notebook path.

Switching kernels preserves displayed outputs and starts a fresh execution session. Interrupt running work before switching. Local kernel startup checks do not block input and stop after a failure or a 30-second timeout.

#### Set up the global notebook environment

```sh
uv venv --python 3.13 ~/.local/share/nvim/notebook-venv
uv pip install --python ~/.local/share/nvim/notebook-venv/bin/python pandas matplotlib ipykernel
```

`vim.g.notebook_default_python` can override the default interpreter path. Project and global kernels are registered with absolute interpreter paths. Databricks kernels remain separate from this fallback.

### Databricks

Lazy installs the Lua plugin from [ravila4/databricks.nvim](https://github.com/ravila4/databricks.nvim). Install its Python commands as a uv tool:

```sh
uv tool install --python 3.12 \
  git+https://github.com/ravila4/databricks.nvim
```

The tool owns an isolated Python 3.12 environment for Databricks Connect and adds the target, health, and kernelspec commands to `PATH`. Authenticate a Databricks CLI profile and generate a managed kernelspec as described in the plugin README.

| Command | Key | Action |
|---------|-----|--------|
| `:DatabricksTarget` | `<leader>dk` | Select an installed managed target |
| `:checkhealth databricks` | n/a | Validate profiles, compute targets, kernelspecs, and Python dependencies |

The target picker shows the compute name, profile, and DBR version. It attaches an already-running target as a shared Molten kernel. If the current buffer uses a different kernel, run `:MoltenDeinit` before selecting another target.

### Vim-Slime (terminal REPL)

Sends code to a terminal. Works over SSH, minimal dependencies.

| Key | Action |
|-----|--------|
| `<leader>se` | Run cell |
| `<leader>sE` | Run cell + jump to next |
| `<leader>ja` / `<leader>jA` | Run all above / below cursor |
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
