return {
  -- Status line
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          theme = "adwaita",
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = {
            "branch",
            "diff",
            {
              "diagnostics",
              sources = { "nvim_lsp", "nvim_diagnostic" },
              sections = { "error", "warn", "info", "hint" },
              diagnostics_color = {
                error = "DiagnosticError",
                warn = "DiagnosticWarn",
                info = "DiagnosticInfo",
                hint = "DiagnosticHint",
              },
              symbols = { error = " ", warn = " ", info = " ", hint = " " },
            }
          },
          lualine_c = { 
            { "filename", path = 1 },
            {
              function()
                -- Show Python virtual environment
                local venv = os.getenv("VIRTUAL_ENV")
                if venv then
                  local venv_name = vim.fn.fnamemodify(venv, ":t")
                  return " " .. venv_name
                end
                return ""
              end,
              color = { fg = "#4ec9b0", gui = "bold" },
            }
          },
          lualine_x = {
            "encoding",
            "fileformat",
            "filetype"
          },
          lualine_y = {
            {
              function()
                return os.date("%H:%M")
              end,
              icon = "",
              color = function()
                local mode = vim.fn.mode()
                local is_dark = vim.o.background == "dark"
                local palette = {
                  teal = "#228787",
                  orange = "#f57c00",
                  blue = is_dark and "#569cd6" or "#1c71d8",
                  red = is_dark and "#f48771" or "#a51d2d",
                  green = is_dark and "#4ec9b0" or "#26a269",
                }

                if mode:match("i") then
                  return { fg = palette.orange }
                elseif mode == "v" or mode == "V" or mode == "\22" then
                  return { fg = palette.blue }
                elseif mode:match("R") or mode:match("r") then
                  return { fg = palette.red }
                elseif mode == "t" then
                  return { fg = palette.green }
                elseif mode == "c" then
                  return { fg = palette.blue }
                else
                  return { fg = palette.teal }
                end
              end,
            }
          },
          lualine_z = { "location", "progress" }
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { "filename" },
          lualine_x = { "location" },
          lualine_y = {},
          lualine_z = {}
        },
      })
    end,
  },

  -- Note: File explorer moved to layout.lua (neo-tree with edgy integration)

  -- Icons
  {
    "nvim-tree/nvim-web-devicons",
    lazy = true,
  },

  -- Git signs
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("gitsigns").setup()
    end,
  },

  -- Color highlighter
  {
    "chrisbra/Colorizer",
    cmd = { "ColorHighlight", "ColorClear", "ColorToggle" },
  },

  -- Fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      -- Setup telescope borders highlight
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = function()
          local is_dark = vim.o.background == "dark"
          vim.api.nvim_set_hl(0, "TelescopeBorder", {
            fg = is_dark and "#569cd6" or "#1c71d8",
            bg = "NONE"
          })
          vim.api.nvim_set_hl(0, "TelescopePromptBorder", {
            fg = is_dark and "#569cd6" or "#1c71d8",
            bg = "NONE"
          })
          vim.api.nvim_set_hl(0, "TelescopeResultsBorder", {
            fg = is_dark and "#569cd6" or "#1c71d8",
            bg = "NONE"
          })
          vim.api.nvim_set_hl(0, "TelescopePreviewBorder", {
            fg = is_dark and "#569cd6" or "#1c71d8",
            bg = "NONE"
          })
        end,
      })

      -- Apply highlights immediately
      vim.defer_fn(function()
        local is_dark = vim.o.background == "dark"
        vim.api.nvim_set_hl(0, "TelescopeBorder", {
          fg = is_dark and "#569cd6" or "#1c71d8",
          bg = "NONE"
        })
        vim.api.nvim_set_hl(0, "TelescopePromptBorder", {
          fg = is_dark and "#569cd6" or "#1c71d8",
          bg = "NONE"
        })
        vim.api.nvim_set_hl(0, "TelescopeResultsBorder", {
          fg = is_dark and "#569cd6" or "#1c71d8",
          bg = "NONE"
        })
        vim.api.nvim_set_hl(0, "TelescopePreviewBorder", {
          fg = is_dark and "#569cd6" or "#1c71d8",
          bg = "NONE"
        })
      end, 100)

      require("telescope").setup({
        defaults = {
          -- Beautiful borders and styling
          border = true,
          borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
          results_title = "",
          prompt_title = "",
          preview_title = "",
          layout_config = {
            horizontal = {
              prompt_position = "top",
              preview_width = 0.55,
              results_width = 0.8,
            },
            vertical = {
              mirror = false,
            },
            width = 0.87,
            height = 0.80,
            preview_cutoff = 120,
          },
          prompt_prefix = "  ",
          selection_caret = "  ",
          entry_prefix = "  ",
          initial_mode = "insert",
          selection_strategy = "reset",
          sorting_strategy = "ascending",
          layout_strategy = "horizontal",
          file_sorter = require("telescope.sorters").get_fuzzy_file,
          file_ignore_patterns = { "node_modules" },
          generic_sorter = require("telescope.sorters").get_generic_fuzzy_sorter,
          path_display = { "truncate" },
          winblend = 0,
          color_devicons = true,
          use_less = true,
          set_env = { ["COLORTERM"] = "truecolor" },
          file_previewer = require("telescope.previewers").vim_buffer_cat.new,
          grep_previewer = require("telescope.previewers").vim_buffer_vimgrep.new,
          qflist_previewer = require("telescope.previewers").vim_buffer_qflist.new,
          mappings = {
            i = {
              ["<C-h>"] = "which_key",
            },
          },
        },
        pickers = {
          find_files = {
            theme = "ivy",
            layout_config = {
              height = 0.4,
            },
          },
          live_grep = {
            theme = "ivy", 
            layout_config = {
              height = 0.4,
            },
          },
          grep_string = {
            theme = "ivy",
            layout_config = {
              height = 0.4,
            },
          },
          buffers = {
            theme = "dropdown",
            previewer = false,
            initial_mode = "normal",
            mappings = {
              i = {
                ["<C-d>"] = "delete_buffer",
              },
              n = {
                ["dd"] = "delete_buffer",
              },
            },
          },
          help_tags = {
            theme = "ivy",
          },
          commands = {
            theme = "ivy",
          },
        },
      })
    end,
  },

  -- Session persistence
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {
      -- Add any custom options here if needed
      dir = vim.fn.expand(vim.fn.stdpath("state") .. "/sessions/"),
      options = { "buffers", "curdir", "tabpages", "winsize" },
      pre_save = function()
        -- Close special buffers before saving session
        local bufs = vim.api.nvim_list_bufs()
        for _, buf in ipairs(bufs) do
          local bufname = vim.api.nvim_buf_get_name(buf)
          local buftype = vim.api.nvim_get_option_value("buftype", {buf = buf})
          -- Skip special buffers like outline, neo-tree, etc.
          if buftype ~= "" or 
             string.match(bufname, "OUTLINE") or 
             string.match(bufname, "neo%-tree") or
             string.match(bufname, "snacks_explorer") or
             string.match(bufname, "Outline") then
            vim.api.nvim_buf_delete(buf, {force = true})
          end
        end
      end,
      save_empty = false,
    },
    keys = {
      {
        "<leader>qs",
        function() require("persistence").load() end,
        desc = "Restore Session",
      },
      {
        "<leader>qS",
        function() require("persistence").select() end,
        desc = "Select Session",
      },
      {
        "<leader>ql",
        function() require("persistence").load({ last = true }) end,
        desc = "Restore Last Session",
      },
      {
        "<leader>qd",
        function() require("persistence").stop() end,
        desc = "Don't Save Current Session",
      },
      -- Named session functionality
      {
        "<leader>qn",
        function() 
          vim.ui.input({ prompt = "Session name: " }, function(name)
            if name and name ~= "" then
              -- Save current session with custom name
              local session_dir = vim.fn.expand(vim.fn.stdpath("state") .. "/sessions/")
              local session_file = session_dir .. name .. ".vim"
              vim.cmd("mksession! " .. vim.fn.fnameescape(session_file))
              vim.notify("Session '" .. name .. "' saved!")
            end
          end)
        end,
        desc = "Save Named Session",
      },
      {
        "<leader>qr",
        function()
          local session_dir = vim.fn.expand(vim.fn.stdpath("state") .. "/sessions/")
          local sessions = {}

          -- Get all .vim session files
          for name, type in vim.fs.dir(session_dir) do
            if type == "file" and name:match("%.vim$") then
              local session_name = name:gsub("%.vim$", "")
              -- Skip default persistence sessions
              if not session_name:match("^[a-f0-9-]+$") then
                table.insert(sessions, session_name)
              end
            end
          end

          if #sessions == 0 then
            vim.notify("No named sessions found")
            return
          end

          vim.ui.select(sessions, { prompt = "Select session to restore:" }, function(choice)
            if choice then
              local session_file = session_dir .. choice .. ".vim"
              vim.cmd("source " .. vim.fn.fnameescape(session_file))
              vim.notify("Session '" .. choice .. "' restored!")
            end
          end)
        end,
        desc = "Restore Named Session",
      },
    },
  },

  -- VSCode-style tabline
  {
    "akinsho/bufferline.nvim",
    version = "*",
    event = "VeryLazy",
    dependencies = "nvim-tree/nvim-web-devicons",
    opts = {
      options = {
        mode = "buffers", -- Show all buffers, not just tabs
        themable = true,
        numbers = "none",
        close_command = "bdelete! %d",
        right_mouse_command = "bdelete! %d",
        left_mouse_command = "buffer %d",
        middle_mouse_command = nil,
        indicator = {
          icon = "▎",
          style = "icon",
        },
        buffer_close_icon = "󰅖",
        modified_icon = "●",
        close_icon = "",
        left_trunc_marker = "",
        right_trunc_marker = "",
        max_name_length = 30,
        max_prefix_length = 30,
        truncate_names = true,
        tab_size = 21,
        diagnostics = "nvim_lsp",
        diagnostics_update_in_insert = false,
        diagnostics_indicator = function(count, level, diagnostics_dict, context)
          if level:match("error") then
            return " " .. count
          elseif level:match("warn") then
            return " " .. count
          elseif level:match("info") then
            return " " .. count
          elseif level:match("hint") then
            return " " .. count
          else
            return ""
          end
        end,
        color_icons = true,
        show_buffer_icons = true,
        show_buffer_close_icons = true,
        show_close_icon = true,
        show_tab_indicators = true,
        show_duplicate_prefix = true,
        persist_buffer_sort = true,
        move_wraps_at_ends = false,
        separator_style = "thick",
        enforce_regular_tabs = false,
        always_show_bufferline = false, -- Hide on single buffer/dashboard
        hover = {
          enabled = true,
          delay = 200,
          reveal = {'close'}
        },
        sort_by = "insert_at_end",
      },
      highlights = function()
        local colors = {}
        -- Detect if we're in dark mode
        local is_dark = vim.o.background == "dark"

        if is_dark then
          -- Dark theme colors
          colors = {
            fill = { bg = "#242424" },
            background = { bg = "#2d2d30", fg = "#cccccc" },
            buffer_visible = { bg = "#37373d", fg = "#cccccc" },
            buffer_selected = { bg = "#1e1e1e", fg = "#ffffff", bold = true },
          }
        else
          -- Light theme colors
          colors = {
            fill = { bg = "#f6f5f4" },
            background = { bg = "#f1f0ef", fg = "#3d3846" },
            buffer_visible = { bg = "#e5e4e2", fg = "#5e5c64" },
            buffer_selected = { bg = "#ffffff", fg = "#2e3436", bold = true },
          }
        end

        return {
          fill = colors.fill,
          background = colors.background,
          buffer_visible = colors.buffer_visible,
          buffer_selected = colors.buffer_selected,
          indicator_selected = {
            bg = colors.buffer_selected.bg,
            fg = is_dark and "#569cd6" or "#1c71d8", -- Blue indicator
          },
          indicator_visible = {
            bg = colors.buffer_visible.bg,
            fg = "NONE",
          },
          close_button = {
            bg = colors.background.bg,
            fg = is_dark and "#858585" or "#9a9996",
          },
          close_button_visible = {
            bg = colors.buffer_visible.bg,
            fg = is_dark and "#858585" or "#77767b",
          },
          close_button_selected = {
            bg = colors.buffer_selected.bg,
            fg = is_dark and "#569cd6" or "#613583",
          },
          modified = {
            bg = colors.background.bg,
            fg = is_dark and "#f48771" or "#a51d2d",
          },
          modified_visible = {
            bg = colors.buffer_visible.bg,
            fg = is_dark and "#f48771" or "#a51d2d",
          },
          modified_selected = {
            bg = colors.buffer_selected.bg,
            fg = is_dark and "#f48771" or "#a51d2d",
          },
          duplicate = {
            bg = colors.background.bg,
            fg = is_dark and "#858585" or "#77767b",
            italic = true,
          },
          duplicate_visible = {
            bg = colors.buffer_visible.bg,
            fg = is_dark and "#858585" or "#77767b",
            italic = true,
          },
          duplicate_selected = {
            bg = colors.buffer_selected.bg,
            fg = is_dark and "#cccccc" or "#5e5c64",
            italic = true,
          },
          separator = {
            bg = colors.background.bg,
            fg = colors.background.bg, -- Same color as background for square effect
          },
          separator_visible = {
            bg = colors.buffer_visible.bg,
            fg = colors.buffer_visible.bg, -- Same color as background for square effect
          },
          separator_selected = {
            bg = colors.buffer_selected.bg,
            fg = colors.buffer_selected.bg, -- Same color as background for square effect
          },
          -- Diagnostic colors - theme aware
          error = {
            bg = colors.background.bg,
            fg = is_dark and "#f48771" or "#e01b24",
          },
          error_visible = {
            bg = colors.buffer_visible.bg,
            fg = is_dark and "#f48771" or "#e01b24",
          },
          error_selected = {
            bg = colors.buffer_selected.bg,
            fg = is_dark and "#f48771" or "#e01b24",
          },
          warning = {
            bg = colors.background.bg,
            fg = is_dark and "#dcdcaa" or "#f57c00",
          },
          warning_visible = {
            bg = colors.buffer_visible.bg,
            fg = is_dark and "#dcdcaa" or "#f57c00",
          },
          warning_selected = {
            bg = colors.buffer_selected.bg,
            fg = is_dark and "#dcdcaa" or "#f57c00",
          },
          info = {
            bg = colors.background.bg,
            fg = is_dark and "#9cdcfe" or "#1c71d8",
          },
          info_visible = {
            bg = colors.buffer_visible.bg,
            fg = is_dark and "#9cdcfe" or "#1c71d8",
          },
          info_selected = {
            bg = colors.buffer_selected.bg,
            fg = is_dark and "#9cdcfe" or "#1c71d8",
          },
          hint = {
            bg = colors.background.bg,
            fg = is_dark and "#4ec9b0" or "#26a269",
          },
          hint_visible = {
            bg = colors.buffer_visible.bg,
            fg = is_dark and "#4ec9b0" or "#26a269",
          },
          hint_selected = {
            bg = colors.buffer_selected.bg,
            fg = is_dark and "#4ec9b0" or "#26a269",
          },
          -- Tab-specific styles (for when in tab mode)
          tab = {
            bg = colors.background.bg,
            fg = colors.background.fg,
          },
          tab_selected = {
            bg = colors.buffer_selected.bg,
            fg = colors.buffer_selected.fg,
          },
          tab_close = {
            bg = colors.background.bg,
          },
          tab_separator = {
            bg = colors.background.bg,
            fg = colors.background.bg, -- Square effect
          },
          tab_separator_selected = {
            bg = colors.buffer_selected.bg,
            fg = colors.buffer_selected.bg, -- Square effect
          },
        }
      end,
    },
    keys = {
      { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle Pin" },
      { "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete Non-Pinned Buffers" },
      { "<leader>br", "<Cmd>BufferLineCloseRight<CR>", desc = "Delete Buffers to the Right" },
      { "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", desc = "Delete Buffers to the Left" },
      { "<leader>bc", "<Cmd>BufferLinePickClose<CR>", desc = "Pick Buffer to Close" },
      { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
      { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
      { "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
      { "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
      { "[B", "<cmd>BufferLineMovePrev<cr>", desc = "Move buffer prev" },
      { "]B", "<cmd>BufferLineMoveNext<cr>", desc = "Move buffer next" },
    },
  },

  -- Context menus for enhanced IDE experience
  {
    "nvzone/menu",
    lazy = true,
    dependencies = { "nvzone/volt" },
    config = function()
      local menu = require("menu")

      local function normalize_menu(items)
        local normalized = {}
        for _, it in ipairs(items) do
          if it.name == "separator" then
            table.insert(normalized, it)
          else
            local action
            if type(it.cmd) == "function" then
              local fn = it.cmd
              action = function()
                vim.schedule(function()
                  pcall(fn)
                end)
              end
            elseif type(it.cmd) == "string" and it.cmd ~= "" then
              local cmdstr = it.cmd
              action = function()
                vim.schedule(function()
                  pcall(vim.cmd, cmdstr)
                end)
              end
            else
              action = function() end
            end
            table.insert(normalized, { name = it.name, cmd = action, rtxt = it.rtxt })
          end
        end
        return normalized
      end
      
      -- Store menu configurations globally for access
      _G.ide_menus = {
        buffer_menu = {
          { name = "󰍉 Close Buffer", cmd = "bdelete", rtxt = "" },
          { name = "󰓦 Close Others", cmd = "BufferLineCloseOthers", rtxt = "" },
          { name = "󰪥 Close Left", cmd = "BufferLineCloseLeft", rtxt = "" },
          { name = "󰪦 Close Right", cmd = "BufferLineCloseRight", rtxt = "" },
          { name = "separator" },
          { name = "󰤼 Split Horizontal", cmd = "split", rtxt = "" },
          { name = "󰤻 Split Vertical", cmd = "vsplit", rtxt = "" },
          { name = "separator" },
          { name = "󰌪 Pin Tab", cmd = "BufferLineTogglePin", rtxt = "" },
          { name = "󰘬 Pick Buffer", cmd = "BufferLinePick", rtxt = "" },
        },

        lsp_menu = {
          { name = "󰊕 Go to Definition", cmd = "lua vim.lsp.buf.definition()", rtxt = "gd" },
          { name = "󰁨 Go to References", cmd = "lua vim.lsp.buf.references()", rtxt = "gr" },
          { name = "󰊗 Go to Implementation", cmd = "lua vim.lsp.buf.implementation()", rtxt = "gi" },
          { name = "󰊘 Go to Type Definition", cmd = "lua vim.lsp.buf.type_definition()", rtxt = "gt" },
          { name = "separator" },
          { name = "󰒕 Rename Symbol", cmd = "lua vim.lsp.buf.rename()", rtxt = "rn" },
          { name = "󰬔 Code Action", cmd = "lua vim.lsp.buf.code_action()", rtxt = "ca" },
          { name = "󰐦 Format Document", cmd = "lua vim.lsp.buf.format()", rtxt = "fm" },
          { name = "separator" },
          { name = "󰠠 Show Diagnostics", cmd = "lua vim.diagnostic.open_float()", rtxt = "df" },
          { name = "󰒧 Toggle Diagnostics", cmd = "lua require('lsp_lines').toggle()", rtxt = "ld" },
        },

        git_menu = {
          { name = "󰊢 Git Status", cmd = "Neotree git_status", rtxt = "" },
          { name = "󰊢 Git Status (float, main)", cmd = "Neotree float git_status git_base=main", rtxt = "gS" },
          { name = "󰊢 Open Diffview", cmd = "DiffviewOpen", rtxt = "gd" },
          { name = "󰊢 File History", cmd = "DiffviewFileHistory %", rtxt = "gh" },
          { name = "󰊢 Diff Last Commit", cmd = "DiffviewOpen HEAD~1", rtxt = "gD" },
          { name = "separator" },
          { name = "󰊢 Lazygit", cmd = "lua Snacks.lazygit()", rtxt = "gg" },
          { name = "󰊢 Git Blame Line", cmd = "lua Snacks.git.blame_line()", rtxt = "gB" },
          { name = "separator" },
          { name = "󰊢 Close Diffview", cmd = "DiffviewClose", rtxt = "gc" },
        },

        terminal_menu = {
          { name = "󰆍 Toggle Terminal", cmd = "lua Snacks.terminal()", rtxt = "tt" },
          { name = "󰆍 Floating Terminal", cmd = "lua Snacks.terminal.toggle()", rtxt = "" },
          { name = "separator" },
          { name = "🐍 Python REPL", cmd = "lua Snacks.terminal.toggle('python3')", rtxt = "" },
          { name = "📊 R Console", cmd = "lua Snacks.terminal.toggle('R')", rtxt = "" },
          { name = "📓 IPython", cmd = "lua Snacks.terminal.toggle('ipython')", rtxt = "" },
          { name = "separator" },
          { name = "󰌪 Split Terminal H", cmd = "split | terminal", rtxt = "" },
          { name = "󰤻 Split Terminal V", cmd = "vsplit | terminal", rtxt = "" },
        },

        file_menu = {
          { name = "󰈔 Find Files", cmd = "Telescope find_files", rtxt = "ff" },
          { name = "󰈞 Recent Files", cmd = "Telescope oldfiles", rtxt = "fr" },
          { name = "󰈬 Live Grep", cmd = "Telescope live_grep", rtxt = "fg" },
          { name = "separator" },
          { name = "󰙅 New File", cmd = "ene", rtxt = "" },
          { name = "󰈔 File Explorer", cmd = "Neotree toggle", rtxt = "e" },
          { name = "󰘎 Code Outline", cmd = "Outline", rtxt = "s" },
          { name = "separator" },
          { name = "💾 Save", cmd = "w", rtxt = "" },
          { name = "💾 Save All", cmd = "wa", rtxt = "" },
        },

        layout_menu = {
          { name = "󰹑 Toggle Left Panel", cmd = "lua require('edgy').toggle('left')", rtxt = "ll" },
          { name = "󰹐 Toggle Right Panel", cmd = "lua require('edgy').toggle('right')", rtxt = "lr" },
          { name = "󰹏 Toggle Bottom Panel", cmd = "lua require('edgy').toggle('bottom')", rtxt = "lb" },
          { name = "separator" },
          { name = "󰹊 Full IDE Layout", cmd = "lua require('edgy').open()", rtxt = "lL" },
          { name = "󰹎 Close All Panels", cmd = "lua require('edgy').close()", rtxt = "lc" },
          { name = "separator" },
          { name = "󰹔 Zen Mode", cmd = "lua Snacks.zen()", rtxt = "z" },
          { name = "󰹕 Zoom Window", cmd = "lua Snacks.zen.zoom()", rtxt = "Z" },
        },

        debug_menu = {
          { name = "🔴 Add Breakpoint", cmd = "echo 'Debug: Breakpoint (nvim-dap needed)'", rtxt = "" },
          { name = "🟢 Start Debugging", cmd = "echo 'Debug: Start (nvim-dap needed)'", rtxt = "" },
          { name = "⏸️  Step Over", cmd = "echo 'Debug: Step Over (nvim-dap needed)'", rtxt = "" },
          { name = "⏬ Step Into", cmd = "echo 'Debug: Step Into (nvim-dap needed)'", rtxt = "" },
          { name = "⏫ Step Out", cmd = "echo 'Debug: Step Out (nvim-dap needed)'", rtxt = "" },
          { name = "separator" },
          { name = "📊 Evaluate Expression", cmd = "echo 'Debug: Evaluate (nvim-dap needed)'", rtxt = "" },
          { name = "🛑 Stop Debugging", cmd = "echo 'Debug: Stop (nvim-dap needed)'", rtxt = "" },
        },

        context_menu = {
          { name = "📁 File Operations", cmd = "FileMenu", rtxt = "mf" },
          { name = "📋 Buffer Actions", cmd = "BufferMenu", rtxt = "mb" },
          { name = "🔧 LSP Actions", cmd = "LspMenu", rtxt = "ml" },
          { name = "󰊢 Git Operations", cmd = "GitMenu", rtxt = "mg" },
          { name = "📟 Terminal/REPL", cmd = "TerminalMenu", rtxt = "mt" },
          { name = "📐 Layout Control", cmd = "LayoutMenu", rtxt = "mp" },
          { name = "🔍 Debug Tools", cmd = "DebugMenu", rtxt = "md" },
        }
      }

      -- Create user commands  
      local function menu_opts()
        return { mouse = true, border = 'rounded', winblend = 0 }
      end
      vim.api.nvim_create_user_command("BufferMenu", function() menu.open(normalize_menu(_G.ide_menus.buffer_menu), menu_opts()) end, {})
      vim.api.nvim_create_user_command("LspMenu", function() menu.open(normalize_menu(_G.ide_menus.lsp_menu), menu_opts()) end, {})
      vim.api.nvim_create_user_command("GitMenu", function() menu.open(normalize_menu(_G.ide_menus.git_menu), menu_opts()) end, {})
      vim.api.nvim_create_user_command("TerminalMenu", function() menu.open(normalize_menu(_G.ide_menus.terminal_menu), menu_opts()) end, {})
      vim.api.nvim_create_user_command("FileMenu", function() menu.open(normalize_menu(_G.ide_menus.file_menu), menu_opts()) end, {})
      vim.api.nvim_create_user_command("LayoutMenu", function() menu.open(normalize_menu(_G.ide_menus.layout_menu), menu_opts()) end, {})
      vim.api.nvim_create_user_command("DebugMenu", function() menu.open(normalize_menu(_G.ide_menus.debug_menu), menu_opts()) end, {})
      vim.api.nvim_create_user_command("ContextMenu", function() menu.open(normalize_menu(_G.ide_menus.context_menu), menu_opts()) end, {})

      -- Right-click context menu with copy/paste + IDE entries
      vim.api.nvim_create_user_command("RightClickMenu", function()
        local mode = vim.fn.mode()
        local has_selection = mode == 'v' or mode == 'V' or mode == '\22'
        local right_click_menu = {
          { name = "📋 Copy", cmd = has_selection and '"+y' or 'echo "No text selected"', rtxt = "y" },
          { name = "📄 Paste", cmd = '"+p', rtxt = "p" },
          { name = "📄 Paste Before", cmd = '"+P', rtxt = "P" },
          { name = "separator" },
          { name = "🔤 Select All", cmd = "normal! ggVG", rtxt = "ggVG" },
          { name = "🔤 Select Line", cmd = "normal! V", rtxt = "V" },
          { name = "separator" },
          { name = "📁 File Operations", cmd = "FileMenu", rtxt = "mf" },
          { name = "📋 Buffer Actions", cmd = "BufferMenu", rtxt = "mb" },
          { name = "🔧 LSP Actions", cmd = "LspMenu", rtxt = "ml" },
          { name = "separator" },
          { name = "📟 Terminal/REPL", cmd = "TerminalMenu", rtxt = "mt" },
          { name = "󰊢 Git Operations", cmd = "GitMenu", rtxt = "mg" },
          { name = "📐 Layout Control", cmd = "LayoutMenu", rtxt = "mp" },
          { name = "🔍 Debug Tools", cmd = "DebugMenu", rtxt = "md" },
        }
        menu.open(normalize_menu(right_click_menu), menu_opts())
      end, {})
    end,
    keys = {
      { "<C-t>", "<cmd>ContextMenu<cr>", desc = "Open Context Menu" },
      { "<leader>m", "<cmd>ContextMenu<cr>", desc = "Open Context Menu" },
      { "<leader>mb", "<cmd>BufferMenu<cr>", desc = "Buffer Menu" },
      { "<leader>ml", "<cmd>LspMenu<cr>", desc = "LSP Menu" },
      { "<leader>mg", "<cmd>GitMenu<cr>", desc = "Git Menu" },
      { "<leader>mt", "<cmd>TerminalMenu<cr>", desc = "Terminal Menu" },
      { "<leader>mf", "<cmd>FileMenu<cr>", desc = "File Menu" },
      { "<leader>mp", "<cmd>LayoutMenu<cr>", desc = "Layout Menu" },
      { "<leader>md", "<cmd>DebugMenu<cr>", desc = "Debug Menu" },
      
      -- Right-click context menu support
      { "<RightMouse>", "<cmd>RightClickMenu<cr>", desc = "Right-click Context Menu", mode = { "n", "v" } },
    },
  },
}
