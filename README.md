# Feature Documentation

Leader key is `Space`.

## Table of Contents

- [External Dependencies](#external-dependencies)
  - [Set up a new machine](#set-up-a-new-machine)
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
- [R scripts and notebooks](#r-scripts-and-notebooks)
- [Git](#git)
  - [Within Diffview](#within-diffview)
- [Trailing Whitespace](#trailing-whitespace)

## External Dependencies

### Set up a new machine

From this checkout:

```sh
make help
make system-deps  # Optional: install system prerequisites with Homebrew on macOS
make setup
make notebooks    # Optional: global Python notebook environment and Jupytext
make r            # Optional: R notebook kernel and editor tooling; requires R
make databricks   # Optional: Databricks helper commands; requires Databricks CLI
make check
```

Setup requires Neovim 0.12+, Git, uv, Node/npm, Yarn, a C compiler, make, curl, tar,
and tree-sitter CLI 0.26.1+ (not the npm package). Linux users install system
prerequisites with their distribution's package manager. Use Ghostty or Kitty
for inline image display.

On macOS, optional system packages can be installed separately:

```sh
brew install r                         # Only if you need a new R installation
brew install quarto                    # For rendering Quarto documents
brew install databricks/tap/databricks  # For Databricks CLI authentication/targets
```

| Target | Scope |
|--------|-------|
| `help` (default) | List targets without installing anything |
| `system-deps` | Explicit system prerequisite installation on macOS; prerequisite checks on Linux |
| `setup` | Python remote-plugin host, locked plugins, core Mason tools including Pyright, parsers, Molten registration |
| `notebooks` | Jupytext as a uv tool and a separate Python 3.13 environment with ipykernel, pandas, matplotlib |
| `r` | IRkernel in a user R library, Jupyter registration, R language tooling |
| `databricks` | Python 3.12 uv tool at the same revision as the locked Databricks Lua plugin |
| `check` | Local checks without installing packages, authenticating, starting kernels, or contacting compute |

Rerun setup targets to repair missing components. Setup does not request package
upgrades; plugin revisions come from `lazy-lock.json`. Project `.venv` and `renv`
environments, credentials, and unrelated kernels remain outside its scope.
Pyright stays managed by Mason.

Run `make setup` to install missing plugins, Mason packages, and parsers after
adding dependencies. If an installed plugin differs from
the lockfile, review the change and run `:Lazy restore` before retrying setup.
Use the managers' explicit update commands when you intend to upgrade packages.

```text
System prerequisites
        |
Python host -> locked plugins -> tools/parsers -> remote-plugin registration
                                                        |
                                      optional notebooks / R / Databricks
```

Molten's Python host lives under Neovim's data directory at
`python-host/bin/python`. Kernel environments are separate: their dependencies
can change without changing Neovim's Python provider. Setup and the editor
both honor Neovim's XDG data directory.

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

## Markdown and Quarto outline

`<leader>s` opens a heading hierarchy for Markdown documents. Quarto (`.qmd`) also lists numbered executable chunks such as ` ```{python} ` and ` ```{r} `, nested under their headings. Ordinary fenced examples and raw output blocks are excluded. Chunk labels supply titles when present; otherwise the first code line is used, skipping cell options. Enter jumps to an entry and Space folds or unfolds a section.

The Quarto outline supports the same copy/cut/paste and undo keys described below for Jupyter. Headings inside callouts or other fenced divs stay within their enclosing container: copying or cutting them leaves that container's delimiters in place. Its context menu provides:

| Action | Behavior |
|--------|----------|
| Run Cell | Run the selected chunk through the configured Quarto runner |
| Run All Above / Below | Dispatch chunks strictly before / after the selection, in document order |
| Create Cell Above / Below | Inherit the selected chunk's language; from a heading, insert at the start / end of its section and choose a language |
| Open Output | View text output for a chunk configured to use Molten |
| Interrupt / Restart Kernel | Available when the document has live Molten cells |

Creating a document's first cell inserts it after YAML front matter. Creation preserves labels and options on existing chunks and gives the new chunk only its language. The outline recognizes bare curly language headers (`{python}`, `{r}`, etc.); place chunk labels and options in the chunk body. Navigation works without a kernel; running requires matching Quarto/Otter language support and, for Molten, a kernel initialized in the source buffer.

Bulk execution validates every target before sending code and honors Quarto's `never_run` list. A batch containing multiple languages routed to Molten is refused because that runner does not choose kernels by language. Individual execution uses the current kernel; configure per-language runners for other execution targets. Interactive actions follow Quarto's runner semantics, including execution of chunks marked `eval: false`; rendering settings are not an interactive execution policy. Separate runners may finish in a different order, and runtime failures can leave a batch partially executed.

Moves retain live Molten outputs; copies start unexecuted. Undo/redo restores output positions, including from the source buffer after closing the outline. Other runners manage their own output state. Pasting preserves source verbatim and warns when it introduces duplicate scalar chunk labels; rename copied labels before rendering. Cross-document pastes transfer source text without execution identity or format conversion.

## Jupyter Notebooks

Opening `.ipynb` files auto-converts them to markdown via jupytext.
Changes save back to `.ipynb` format. Full LSP support in the converted view.
Outputs saved in the notebook are shown on open without re-running it: Molten starts the notebook's kernel (or one named after the active venv) and imports them. If neither kernel is installed, run `:MoltenInit` then `:MoltenImportOutput`.

Molten comes from the `ravila4/molten-nvim` fork (branch `fix/snacks-mixed-output-clicks`) and uses Snacks to render plots with Kitty Unicode placeholders.

`<leader>s` opens the notebook outline: Markdown headings contain numbered code cells, titled from their first nonblank line. Enter jumps to an entry, and the outline highlights the cell containing the editor cursor. Headings represent document sections rather than original Markdown-cell boundaries.

`<leader>jg` prompts for a cell number and jumps to that code cell. For example, enter `5` to jump to `Cell 5` in the outline.

Cell details show `not run`, `queued`, `running`, `done`, or `error`, with the execution count when available. `saved` identifies results from the notebook or loaded output state; it does not imply that the current kernel contains those variables. Editing executed code shows `modified`; executing only a portion of a cell shows `partial`. Live status requires the fork's `MoltenCellInfo` function and `MoltenCellUpdate` event. The kernel continues processing results while the outline is focused.

The notebook outline supports editing whole cells:

| Key | Action |
|-----|--------|
| `=` | Expand or collapse every outline section |
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
make notebooks
```

`vim.g.notebook_default_python` can override the default interpreter path. Project and global kernels are registered with absolute interpreter paths. Databricks kernels remain separate from this fallback.

### Databricks

Lazy installs the Lua plugin from [ravila4/databricks.nvim](https://github.com/ravila4/databricks.nvim). Install its Python commands at the matching locked revision:

```sh
make databricks
```

The tool owns an isolated Python 3.12 environment for the integration's Databricks
Connect 16.4 dependency and adds the target, health, and kernelspec commands to
`PATH`. Python 3.12 is a requirement of this integration version, not of every
Databricks runtime. The Databricks CLI is a separate prerequisite.

Authenticate a Databricks CLI profile and generate a managed kernelspec as
described in the plugin README. The kernelspec command's `--python` option
selects a target-specific environment; setup does not create
compute targets or change those environments. `make check` does not run the
profile/compute checks below.

| Command | Key | Action |
|---------|-----|--------|
| `:DatabricksTarget` | `<leader>dk` | Select an installed managed target |
| `:checkhealth databricks` | n/a | Validate profiles, compute targets, kernelspecs, and Python dependencies |

The target picker shows the compute name, profile, and DBR version. It attaches an already-running target as a shared Molten kernel. If the current buffer uses a different kernel, run `:MoltenDeinit` before selecting another target.

## R scripts and notebooks

| File | Execution | Session |
|------|-----------|---------|
| `.R` | R.nvim's built-in terminal | Interactive R console |
| `.qmd` / `.ipynb` with R cells | Molten using IRkernel | Jupyter R kernel |

Run `make r` after installing R. IRkernel is an R package installed in a user
R library, not a package in the Python notebook environment. The registered
`nvim-r` kernel appears in the notebook and outline **Select Kernel** menus.
Choose it before running R cells; the selection is remembered for that file.

To select a specific R installation or user library:

```sh
make r R_EXECUTABLE=/absolute/path/to/R R_LIBRARY=/absolute/path/to/user-library
```

By default setup uses `R` from `PATH` and `r-library` under Neovim's data
directory. It records that selection in `r-config.json` beside the library so
R.nvim uses the same R installation. It does not edit `.Rprofile` or project
`renv` settings.

In an `.R` buffer, R.nvim uses `Space` as the local leader:

| Key | Action |
|-----|--------|
| `<Space>rf` | Start R or reopen its terminal |
| `<Space>l` | Send the current line |
| `<Space>rq` | Quit R without saving the workspace |

R.nvim builds its bundled `nvimcom` support package when initializing R support.

R.nvim is restricted to R scripts and R help buffers. Quarto execution is
owned by Molten, including its embedded R buffers. The R console and notebook
kernel do not share variables. Selecting an R kernel does not create a mixed
Python/R kernel; use a kernel appropriate for the cells you intend to execute.

### Verify execution

`make check` does not execute code. To test the optional notebook environments,
open a disposable notebook, choose the appropriate kernel, and run:

| Python | R |
|--------|---|
| `1 + 1` | `1 + 1` |
| `import pandas as pd; pd.DataFrame({"x": [1, 2]})` | `data.frame(x = c(1, 2))` |
| `import matplotlib.pyplot as plt; plt.plot([1, 2]); plt.show()` | `plot(c(1, 2))` |

Check table and plot output, interrupt/restart from the context menu, and reopen
the file to verify its remembered kernel. Open an `.R` file before and after a
Quarto file to check that each keeps its own execution commands.

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
