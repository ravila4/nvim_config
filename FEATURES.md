# Neovim Bioinformatics IDE - Feature Documentation

## Overview

This Neovim configuration transforms your editor into a modern bioinformatics IDE that rivals RStudio, Spyder, and VSCode. Built with lazy.nvim and beautiful TUI elements.

## Layout System (edgy.nvim)

### Panel Organization
- **Left Panel**: File explorer (neo-tree) + Code outline/symbols
- **Bottom Panel**: Terminal/REPL (like RStudio console)
- **Right Panel**: Git status, database UI
- **Center**: Your code with beautiful syntax highlighting

### Panel Management
- Panels automatically resize and organize
- Persistent layout across sessions
- Professional IDE experience with Neovim's speed

## Beautiful TUI Elements (snacks.nvim)

### Visual Enhancements
- **Notifications**: Animated, elegant notifications
- **Zen Mode**: Distraction-free coding environment
- **Smooth Scrolling**: Buttery smooth animations
- **Indent Guides**: Beautiful code structure visualization
- **Word Highlighting**: Automatic highlighting of word under cursor
- **Status Column**: Enhanced line numbers and git signs

### Performance Features
- **Big File Handling**: Automatic optimization for files over 1.5MB
  - Disables syntax highlighting, treesitter, and other expensive features
  - Shows notification when big file mode is activated
  - Maintains fast editing for large datasets, logs, and genomic files
  - Perfect for bioinformatics work with large data files

## Session Persistence

### Session Management
- **Auto-save**: Sessions automatically saved on exit
- **Dashboard Integration**: Restore sessions directly from dashboard
  - `s` - Restore current directory session
  - `S` - Select from available sessions
  - `l` - Restore last session
- **Manual Control**: Use `<leader>q` + `s/S/l/d` for session operations
- **Smart Persistence**: Only saves when working on actual projects

### Session Commands
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>qs` | Restore session | Load current directory session |
| `<leader>qS` | Select session | Choose from available sessions |
| `<leader>ql` | Last session | Restore most recent session |
| `<leader>qd` | Don't save session | Skip saving current session |
| `<leader>qc` | Close session | Close all buffers except current |
| `<leader>qC` | Close all buffers | Nuclear option - close everything |
| `<leader>qn` | **Save named session** | Create session with custom name |
| `<leader>qr` | **Restore named session** | Select from named sessions |

### Dashboard Session Actions
- `s` - Restore current directory session
- `S` - Select from available sessions
- `l` - Restore last session
- `x` - Close current session (keep dashboard)
- `n` - **Save named session** (custom name)
- `R` - **Restore named session** (from list)

## Context Menu System (nvzone/menu)

### Comprehensive IDE Menus
- **Main Context Menu**: `Ctrl-t` or `<leader>m` - Access all functionality
- **Right-click Context Menu**: Smart context-aware menu with copy/paste + IDE functions
- **Mouse and Keyboard Navigation**: Full support for both interaction methods
- **Organized by Category**: File, Buffer, LSP, Git, Terminal, Layout, Debug

### Right-Click Menu Features
- **Copy/Paste Integration**: Standard copy (`📋`), paste (`📄`), paste before operations
- **Text Selection**: Select all, select line, with visual feedback
- **Context Awareness**: Copy option adapts based on whether text is selected
- **IDE Functionality**: Quick access to all IDE menus and operations
- **System Clipboard**: Uses `"+` register for system clipboard integration

All menu items are clickable with mouse and mapped to actual commands; items that call Ex-commands are executed reliably.

### Menu Categories
| Key | Menu | Actions |
|-----|------|---------|
| `<leader>mf` | **File Operations** | Find files, recent files, live grep, new file, explorer, outline |
| `<leader>mb` | **Buffer Actions** | Close buffers, split horizontal/vertical, pin tabs, pick buffer |
| `<leader>ml` | **LSP Actions** | Go to definition/references, rename, code actions, format, diagnostics |
| `<leader>mg` | **Git Operations** | Status, diffview, history, lazygit, blame, close diff |
| `<leader>mt` | **Terminal/REPL** | Python REPL, R console, IPython, split terminals |
| `<leader>mp` | **Layout Control** | Toggle panels, full IDE layout, zen mode, zoom |
| `<leader>md` | **Debug Tools** | Breakpoints, debugging controls (ready for nvim-dap) |

### Bioinformatics Workflow Features
- **Python REPL**: Quick access to Python console for data analysis
- **R Console**: Direct R integration for statistical computing
- **IPython**: Enhanced interactive Python with rich output
- **Split Terminals**: Multiple terminals for complex workflows
- **Quick File Navigation**: Perfect for large bioinformatics projects

## VSCode-Style Tabs

### Tabline Features
- **Beautiful Styling**: Matches your teal theme (#228787)
- **Tab Management**: VSCode-like tab behavior
- **Diagnostic Indicators**: Show errors/warnings in tabs
- **Mouse Support**: Click to switch, right-click to close
- **Pin Tabs**: Keep important files always visible

### Tab Navigation
| Key | Action | Description |
|-----|--------|-------------|
| `Shift-h/l` | Previous/Next tab | **Primary navigation** - fastest! |
| `[b` / `]b` | Previous/Next buffer | Alternative navigation |
| `<leader>fb` | Fuzzy buffer picker | **Telescope picker** - jump to any buffer |
| `<leader>bp` | Pin tab | Keep tab always visible |
| `<leader>bl/br` | Close tabs left/right | Bulk close tabs |
| `<leader>bc` | Pick buffer to close | Interactive buffer closing |

### Buffer Management
- **Mouse Support**: Click tabs to switch, right-click to close
- **Smart Display**: Bufferline hidden on dashboard/single buffer
- **Visual Indicators**: Shows diagnostics (errors/warnings) in tabs

## Navigation & Workflow

### Core Navigation
| Key | Action | Description |
|-----|--------|-------------|
| `Ctrl-n` | Toggle file explorer | Persistent left panel |
| `<leader>s` | Toggle outline/symbols | See functions, classes |
| `<leader>tt` | Terminal in bottom panel | REPL workflow |
| `Ctrl-hjkl` | Navigate between panels | Seamless panel movement |
| `<leader>z` | Enter zen mode | Focused coding |

### Layout Management
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>ll` | Toggle left panel | File explorer + outline |
| `<leader>lr` | Toggle right panel | Git + database UI |
| `<leader>lb` | Toggle bottom panel | Terminal + diagnostics |
| `<leader>lL` | Open full IDE layout | All panels visible |
| `<leader>lc` | Close all panels | Minimal editor view |

### Buffer Management
| Key | Action | Description |
|-----|--------|-------------|
| `]b` / `[b` | Next/Previous buffer | Quick buffer cycling |
| `Space + f + b` | Fuzzy find buffers | Telescope buffer picker |
| `Space + b + n/p` | Next/Previous buffer | Alternative navigation |
| `Space + b + d` | Delete buffer | Close current buffer |
| `Space + b + b` | List all buffers | Show buffer list |

### Split Navigation
| Key | Action | Description |
|-----|--------|-------------|
| `Ctrl-h/j/k/l` | Move between splits | Works in normal & terminal mode |
| `:vs filename` | Vertical split | Open file in new split |
| `:sp filename` | Horizontal split | Open file in new split |
| `:close` | Close current split | Remove split window |

### Terminal Integration
- Multiple terminal options:
  - `<leader>tt` - Toggle terminal
  - `<leader>tf` - Floating terminal
  - `<leader>tr` - REPL terminal

### Code Analysis
- **Language Servers**: Python (pyright), R (r_language_server)
- **Enhanced Diagnostics**: lsp_lines.nvim shows full error messages below problematic lines
  - Perfect for Python's detailed type errors and long diagnostic messages
  - Shows multiple diagnostics per line (unlike default virtual text)
  - Toggle with `<leader>ld` between virtual lines and virtual text
  - **Visual Display**: Diagnostics appear as colored virtual lines beneath the code
    - Red lines for errors
    - Yellow/orange lines for warnings
    - Blue lines for information
    - Full message text visible without truncation
- **Completion**: Fast autocomplete with blink.cmp (LSP, path, snippets, buffer)
  - Selection: Tab/Shift-Tab; selection auto-inserts (no extra confirm)
  - Cancel: Esc; Enter remains a pure newline
  - Signature help and auto-brackets enabled; neutral gray borders
- **Syntax Highlighting**: Treesitter for all major languages
- **Code Outline**: Function and class navigation

### Jupyter Notebook Integration

Your IDE supports **three complementary Jupyter workflows** designed for different bioinformatics scenarios. Each tool excels in specific situations and they can work together seamlessly.

## 🎯 Three-Tool Strategy Overview

| Tool | Best For | Strengths | Use Case |
|------|----------|-----------|----------|
| **Molten** | Local analysis + visualization | Inline plots, VSCode-like experience | Daily data analysis, genomics plots |
| **Vim-Slime** | Reliable REPL workflow | Rock-solid, works everywhere | Remote servers, large datasets, terminal-focused |
| **Jupynium** | Secured remote servers | Browser-based, no server config needed | DNAnexus, AllOfUs, locked-down platforms |

## 🖼️ Molten-nvim (Local + Inline Images)

**Perfect for**: Local bioinformatics analysis with rich visualizations

### Key Features
- **Inline Images**: Plots and visualizations appear directly in Neovim
- **Real-time Output**: See results as code executes (like VSCode notebooks)
- **Multiple Kernels**: Python, R, Julia support
- **Performance Optimized**: 1MB output limit for large genomics datasets
- **Theme Integration**: Uses your teal accent colors

### Molten Commands
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>mi` | Initialize | Start kernel for current language |
| `<leader>mr` | Run selection | Execute highlighted code |
| `<leader>ml` | Run line | Execute current line |
| `<leader>mc` | Re-run cell | Re-execute cell at cursor |
| `<leader>md` | Delete cell | Remove cell and output |
| `<leader>mh` | Hide output | Hide cell output |
| `<leader>ms` | Show output | Show cell output |
| `<leader>mq` | Quit kernel | Stop kernel session |

### Setup Requirements
- **Terminal**: Kitty or compatible for image rendering
- **Dependencies**: image.nvim plugin (automatically installed)
- **Python**: Local Python environment with desired packages

## 📟 Vim-Slime (Terminal REPL)

**Perfect for**: Reliable terminal-based workflow, remote servers, large datasets

### Key Features
- **Rock Solid**: Minimal dependencies, always works
- **Terminal Integration**: Uses your existing edgy.nvim terminal layout
- **Cell-based Execution**: Standard `# %%` cell delimiters  
- **Remote Friendly**: Works perfectly over SSH with tmux
- **IPython Integration**: Enhanced with vim-ipython-cell plugin

### Slime Commands (Unified `<leader>j*`)
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>jr` | Run cell | Execute cell at cursor |
| `<leader>jR` | Run cell + jump | Execute and jump to next cell |
| `<leader>ja` | Run all above | Execute all cells above cursor |
| `<leader>jA` | Run all below | Execute all cells below cursor |
| `<leader>jn` | Next cell | Jump to next `# %%` delimiter |
| `<leader>jp` | Previous cell | Jump to previous `# %%` delimiter |
| `<leader>js` | Start IPython | Launch or restart IPython session |
| `<leader>jt` | Open terminal | Open IPython in bottom panel |
| `<leader>jc` | Clear terminal | Clear IPython output |

### Additional Slime Commands
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>sc` | Send line | Send current line to terminal |
| `<leader>ss` | Send operator | Send text object to terminal |
| `<leader>st` | Configure target | Set terminal target |

## 🌐 Jupynium (Remote/Secured Servers)

**Perfect for**: DNAnexus, AllOfUs, secured platforms where you can't configure the server

### Key Features
- **Browser Automation**: Controls Jupyter through Firefox (no server access needed)
- **Secured Servers**: Works with platforms that block direct kernel access
- **Real-time Sync**: Edit in Neovim, see changes in browser instantly
- **Full Context**: Maintains complete notebook state (not shortsighted)
- **Remote Friendly**: SSH port forwarding support

### Jupynium Commands (`.ju.*` and `.ipynb` files)
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>us` | Start server | Launch Jupyter and attach to server |
| `<leader>ur` | Start sync | Begin real-time syncing |
| `<leader>ud` | Download notebook | Save .ipynb copy locally |
| `<leader>uc` | Execute cells | Run selected cells in browser |
| `<leader>ua` | Scroll to cell | Navigate browser to current cell |
| `<leader>uk` | Kernel info | Show kernel status |
| `<leader>uq` | Stop sync | Disconnect from notebook |

### Setup Requirements
- **Browser**: Firefox with geckodriver installed  
- **Server**: Any Jupyter server (local or remote)
- **Files**: Works with `.ju.py`, `.ipynb`, and `.md` files

## 🔄 Unified Workflow Integration

### Smart Tool Selection
Choose your tool based on the scenario:
- **Molten**: Local work where you want to see plots inline
- **Vim-Slime**: When you need reliability or are on remote servers  
- **Jupynium**: Secured servers where you can't install/configure anything

### Unified Keybindings
Common commands work across all tools (context-sensitive):
- `<leader>jr` - Run cell (adapts to active tool)  
- `<leader>ji` - Initialize session (adapts to active tool)
- Standard `# %%` cell delimiters work with all tools

### Terminal Integration
- **Bottom Panel**: Seamless integration with your edgy.nvim layout
- **Multiple Terminals**: Can run IPython alongside Jupyter browser sessions
- **Session Persistence**: Terminal sessions survive across Neovim restarts

### Workflow Examples

#### Local Analysis Session
```bash
# 1. Start Molten for visualization
<leader>mi  # Initialize Python kernel

# 2. Run cells with inline plots  
<leader>mr  # See matplotlib plots directly in editor

# 3. Switch to terminal for debugging
<leader>jt  # Open IPython terminal
<leader>sc  # Send problematic code to terminal
```

#### Remote Server Session  
```bash
# 1. SSH to server, start tmux
# 2. Open Neovim with Python file
# 3. Use vim-slime for reliable execution
<leader>js  # Start IPython in terminal
<leader>jr  # Run cells via terminal
```

#### Secured Platform Session
```bash
# 1. Create .ju.py file (jupynium format)
# 2. Connect to secured Jupyter server
<leader>us  # Start jupynium server connection
<leader>ur  # Begin sync
<leader>uc  # Execute cells in browser
```

### Git Integration
- **Git Signs**: See added/modified/deleted lines
- **Git Status**: Right panel integration
- **Diffview**: Beautiful side-by-side diff viewer with file panel
- **Version Control**: Perfect for tracking analysis changes

#### Git Diff Commands
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>gd` | Open Diffview | Side-by-side diff view of changes |
| `<leader>gD` | Diff last commit | Compare against HEAD~1 |
| `<leader>gh` | File history | Git log for all files |
| `<leader>gH` | Current file history | Git log for current file only |
| `<leader>gc` | Close Diffview | Exit diff view |

#### Within Diffview
| Key | Action | Description |
|-----|--------|-------------|
| `Tab/Shift-Tab` | Next/Previous file | Navigate between changed files |
| `-` | Stage/unstage | Toggle staging for file |
| `S/U` | Stage/unstage all | Bulk operations |
| `X` | Restore file | Discard changes |
| `[x]/]x` | Conflict navigation | Jump between merge conflicts |
| `<leader>co/ct/cb/ca` | Conflict resolution | Choose ours/theirs/base/all |
| `g<C-x>` | Cycle layout | Switch between diff layouts |

## Customizations

### Theme
- **Colorscheme**: Adwaita with transparency
- **Accent Color**: Custom teal (`#228787`)
- **Dashboard**: Rotating bioinformatics-themed headers

### Statusline (Lualine)
- Time segment adapts to mode with theme-aware colors:
  - Normal: teal `#228787`
  - Insert: orange `#f57c00`
  - Visual/Command: blue (Adwaita) — dark `#569cd6`, light `#1c71d8`
  - Replace: red — dark `#f48771`, light `#a51d2d`
  - Terminal: green — dark `#4ec9b0`, light `#26a269`

### Trailing Whitespace
- Automatically highlights trailing spaces
- Excludes special buffers (dashboard, telescope, etc.)
- Prevents visual artifacts in floating windows

## AI Assistance

- **Inline suggestions (Copilot)**: inline ghost text with safe keymaps that do not conflict with completion
  - Accept: Ctrl-l; Accept word: Ctrl-j; Accept line: Ctrl-k
  - Next/Prev: Ctrl-n/Ctrl-p; Dismiss: Ctrl-]
  - Auto-trigger enabled; subtle neutral gray suggestion color
- **Completion engine**: blink.cmp (fast, LSP-backed)
  - Sources: LSP, path, snippets, buffer
  - Selection: Tab/Shift-Tab; Enter inserts newline

## Key Mappings Reference

### Leader Key
- **Leader**: `Space` (more comfortable than backslash)

### File Operations
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>ff` | Find files | Telescope file finder with ivy theme |
| `<leader>fg` | Live grep | Search text across all files |
| `<leader>fw` | Find word under cursor | Search current word in project |
| `<leader>fb` | Find buffers | Telescope buffer picker - jump to any buffer |
| `<leader>fr` | Recent files | Recently opened files |
| `<leader>fc` | Commands | Telescope command picker |
| `<leader>fh` | Help tags | Search Neovim help |
| `<leader>fs` | Document symbols | Current file symbols/functions |
| `<leader>fS` | Workspace symbols | Project-wide symbols/functions |

### Quick Search Shortcuts
| Key | Action | Description |
|-----|--------|-------------|
| `Ctrl-P` | Find files | VSCode-style file picker |
| `Ctrl-F` | Global search | IDE-style text search |

### File Explorer (Neo-tree)
| Key | Action | Description |
|-----|--------|-------------|
| `Ctrl-N` | Toggle explorer | Show/hide file tree |
| `<leader>e` | Toggle explorer | Alternative toggle |
| `<leader>E` | Focus explorer | Jump to file tree |

Visual styling:
- Folders use Adwaita blue (theme-aware).
- Files are monochrome; diagnostics are conveyed via icons, not filename color.

#### Within Neo-tree
| Key | Action | Description |
|-----|--------|-------------|
| `/` | Fuzzy finder | Search within current directory |
| `f` | Filter files | Filter by filename |
| `H` | Toggle hidden | Show/hide dotfiles |
| `R` | Refresh | Reload file tree |
| `.` | Set root | Change root to current directory |
| `<bs>` | Navigate up | Go to parent directory |

### Code Navigation
| Key | Action |
|-----|--------|
| `Space + s` | Toggle symbols/outline |
| `]]` / `[[` | Next/Previous reference |
| `gd` | Go to definition |
| `gr` | Go to references |
| `Space + l + d` | Toggle lsp_lines diagnostics |

### Utilities
| Key | Action |
|-----|--------|
| `F3` | Insert current date |
| `Space + r + r` | Force screen redraw |
| `Space + z` | Toggle zen mode |
| `Space + .` | Scratch buffer |

### Terminal Mode
| Key | Action |
|-----|--------|
| `Esc Esc` | Exit terminal mode |
| `Ctrl-hjkl` | Navigate splits from terminal |

## Configuration Structure

```
~/.config/nvim/
├── init.lua                    # Main entry point
├── lua/
│   ├── config/
│   │   ├── settings.lua        # Vim settings
│   │   ├── keymaps.lua         # Key mappings
│   │   └── abbreviations.lua   # Text abbreviations
│   └── plugins/
│       ├── colorscheme.lua     # Adwaita theme
│       ├── treesitter.lua      # Syntax highlighting
│       ├── lsp.lua            # Language servers
│       ├── completion.lua      # Autocompletion
│       ├── ui.lua             # Status line, git signs
│       ├── editing.lua        # Autopairs, snippets
│       ├── layout.lua         # Edgy layout + neo-tree
│       ├── snacks.lua         # Beautiful TUI elements
│       └── specialized.lua    # R, Python, Obsidian, Quarto
└── FEATURES.md                # This documentation
```

## Getting Started

1. **Start Neovim** → Beautiful dashboard with recent projects
2. **Press `f`** → Find and open a file
3. **Press `Ctrl-n`** → Open file explorer
4. **Press `Space + s`** → View code outline
5. **Press `Space + tt`** → Open terminal for commands
6. **Use `Ctrl-hjkl`** → Navigate between all panels

