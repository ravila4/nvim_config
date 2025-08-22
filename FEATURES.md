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

## Navigation & Workflow

### Core Navigation
| Key | Action | Description |
|-----|--------|-------------|
| `Ctrl-n` | Toggle file explorer | Persistent left panel |
| `<leader>s` | Toggle outline/symbols | See functions, classes |
| `<leader>tt` | Terminal in bottom panel | REPL workflow |
| `Ctrl-hjkl` | Navigate between panels | Seamless panel movement |
| `<leader>z` | Enter zen mode | Focused coding |

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
- **Completion**: Intelligent autocomplete with nvim-cmp
- **Syntax Highlighting**: Treesitter for all major languages
- **Code Outline**: Function and class navigation

### Git Integration
- **Git Signs**: See added/modified/deleted lines
- **Git Status**: Right panel integration
- **Version Control**: Perfect for tracking analysis changes

## Customizations

### Theme
- **Colorscheme**: Adwaita with transparency
- **Accent Color**: Custom teal (`#228787`)
- **Dashboard**: Rotating bioinformatics-themed headers

### Trailing Whitespace
- Automatically highlights trailing spaces
- Excludes special buffers (dashboard, telescope, etc.)
- Prevents visual artifacts in floating windows

## Key Mappings Reference

### Leader Key
- **Leader**: `Space` (more comfortable than backslash)

### File Operations
| Key | Action |
|-----|--------|
| `Space + f + f` | Find files |
| `Space + f + g` | Find text |
| `Space + f + r` | Recent files |
| `Space + f + b` | Find buffers |

### Code Navigation
| Key | Action |
|-----|--------|
| `Space + s` | Toggle symbols/outline |
| `]]` / `[[` | Next/Previous reference |
| `gd` | Go to definition |
| `gr` | Go to references |

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

