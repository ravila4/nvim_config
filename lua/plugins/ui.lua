-- Load UV environment support
require("config.uv-env")

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
          globalstatus = true, -- Enable global statusline for edgy.nvim
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = {
            "branch",
          },
          lualine_c = {
            "diff",
            {
              "diagnostics",
              sources = { "nvim_lsp", "nvim_diagnostic" },
              sections = { "error", "warn", "info", "hint" },
              symbols = {
                error ="",
                warn = "󱈸",
                info = "󰙎",
                hint = "",
              },
            },
            { "filename", path = 1 },
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
      require("gitsigns").setup({
        signs = {
          add          = { text = '┃' },
          change       = { text = '┃' },
          delete       = { text = '_' },
          topdelete    = { text = '‾' },
          changedelete = { text = '~' },
          untracked    = { text = '┆' },
        },
        signs_staged = {
          add          = { text = '┃' },
          change       = { text = '┃' },
          delete       = { text = '_' },
          topdelete    = { text = '‾' },
          changedelete = { text = '~' },
          untracked    = { text = '┆' },
        },
      })
      
      -- Set theme-aware git sign colors
      local function set_git_colors()
        local is_dark = vim.o.background == "dark"
        
        if is_dark then
          -- Dark theme - softer colors for better visibility
          vim.api.nvim_set_hl(0, "GitSignsAdd", { fg = "#4ec9b0" })          -- Teal green
          vim.api.nvim_set_hl(0, "GitSignsChange", { fg = "#dcdcaa" })       -- Light yellow
          vim.api.nvim_set_hl(0, "GitSignsDelete", { fg = "#f48771" })       -- Light red
          vim.api.nvim_set_hl(0, "GitSignsTopdelete", { fg = "#f48771" })    -- Light red
          vim.api.nvim_set_hl(0, "GitSignsChangedelete", { fg = "#d19a66" }) -- Orange
          vim.api.nvim_set_hl(0, "GitSignsUntracked", { fg = "#569cd6" })    -- Light blue
          
          -- Staged versions (50% opacity effect)
          vim.api.nvim_set_hl(0, "GitSignsStagedAdd", { fg = "#3a9688" })
          vim.api.nvim_set_hl(0, "GitSignsStagedChange", { fg = "#a6a677" })
          vim.api.nvim_set_hl(0, "GitSignsStagedDelete", { fg = "#c16a5a" })
          vim.api.nvim_set_hl(0, "GitSignsStagedTopdelete", { fg = "#c16a5a" })
          vim.api.nvim_set_hl(0, "GitSignsStagedChangedelete", { fg = "#a67350" })
        else
          -- Light theme - more vibrant colors for contrast with light background
          vim.api.nvim_set_hl(0, "GitSignsAdd", { fg = "#26a269" })          -- Adwaita green
          vim.api.nvim_set_hl(0, "GitSignsChange", { fg = "#f57c00" })       -- Adwaita orange
          vim.api.nvim_set_hl(0, "GitSignsDelete", { fg = "#a51d2d" })       -- Adwaita red
          vim.api.nvim_set_hl(0, "GitSignsTopdelete", { fg = "#a51d2d" })    -- Adwaita red
          vim.api.nvim_set_hl(0, "GitSignsChangedelete", { fg = "#c64600" }) -- Darker orange
          vim.api.nvim_set_hl(0, "GitSignsUntracked", { fg = "#1c71d8" })    -- Adwaita blue
          
          -- Staged versions (muted variants)
          vim.api.nvim_set_hl(0, "GitSignsStagedAdd", { fg = "#5aa65f" })
          vim.api.nvim_set_hl(0, "GitSignsStagedChange", { fg = "#b8860b" })
          vim.api.nvim_set_hl(0, "GitSignsStagedDelete", { fg = "#cd5c5c" })
          vim.api.nvim_set_hl(0, "GitSignsStagedTopdelete", { fg = "#cd5c5c" })
          vim.api.nvim_set_hl(0, "GitSignsStagedChangedelete", { fg = "#d2691e" })
        end
      end
      
      -- Set colors immediately
      set_git_colors()
      
      -- Update colors when colorscheme changes
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = set_git_colors,
      })
    end,
  },

  -- Color highlighter (fast): catgoose/nvim-colorizer.lua
  {
    "catgoose/nvim-colorizer.lua",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      lazy_load = true,
      filetypes = { "*", "!neo-tree", "!TelescopePrompt", "!snacks_dashboard" },
      user_default_options = {
        RGB = true,          -- #RGB hex
        RRGGBB = true,       -- #RRGGBB hex
        names = false,        -- Named CSS colors
        RRGGBBAA = true,     -- #RRGGBBAA hex
        AARRGGBB = true,     -- 0xAARRGGBB
        rgb_fn = true,       -- rgb()/rgba()
        hsl_fn = true,       -- hsl()/hsla()
        css = true,          -- Enable all CSS features: rgb_fn, hsl_fn, names, etc
        css_fn = true,       -- Enable all CSS functions: rgb_fn, hsl_fn
        mode = "background", -- Render mode: background|foreground|virtual
        tailwind = true,     -- Recognize Tailwind colors
        always_update = true,
      },
      buftypes = {},
    },
    config = function(_, opts)
      require("colorizer").setup(opts)
    end,
  },

  -- Color picker / palette utilities
  {
    "nvzone/minty",
    cmd = { "Minty", "Shades", "Huefy", "Tinty" },
    dependencies = { "nvzone/volt" },
    config = function()
      require("minty").setup()
    end,
  },

  -- Transparency management for consistent theming
  {
    "tribela/transparent.nvim",
    lazy = false,
    priority = 999,
    config = function()
      local transparent = require("transparent")
      transparent.setup({
        auto = true,
        extra_groups = {
          -- Floating windows and popups
          'NormalFloat', 'FloatBorder', 'FloatTitle',

          -- Window splits and separators
          'WinSeparator', 'VertSplit',

          -- Telescope
          'TelescopeNormal', 'TelescopeBorder', 'TelescopePromptNormal',
          'TelescopePromptBorder', 'TelescopeResultsNormal', 'TelescopeResultsBorder',
          'TelescopePreviewNormal', 'TelescopePreviewBorder',

          -- Neo-tree
          'NeoTreeNormal', 'NeoTreeNormalNC', 'NeoTreeEndOfBuffer',

          -- Bufferline (tabline)
          'TabLine', 'TabLineFill', 'TabLineSel',

          -- Diagnostic virtual text
          'DiagnosticVirtualTextError', 'DiagnosticVirtualTextWarn',
          'DiagnosticVirtualTextInfo', 'DiagnosticVirtualTextHint',

          -- Snacks dashboard
          'SnacksDashboardNormal', 'SnacksDashboardDesc', 'SnacksDashboardFile',
          'SnacksDashboardDir', 'SnacksDashboardFooter', 'SnacksDashboardHeader',
          'SnacksDashboardIcon', 'SnacksDashboardKey', 'SnacksDashboardTerminal',
          'SnacksDashboardTitle', 'SnacksDashboardSpecial',

          -- Git signs
          'GitSignsAdd', 'GitSignsChange', 'GitSignsDelete',

          -- LSP and completion (non-selection items only)
          'CmpItemAbbr', 'CmpItemAbbrMatch', 'CmpItemKind', 'CmpItemMenu',

          -- Outline
          'OutlineNormal', 'OutlineCurrent',

          -- Terminal
          'TerminalNormal',
        },
        excludes = {
          -- Keep cursorline opaque for better readability
          'CursorLine', 'CursorColumn', 'ColorColumn',

          -- Keep important UI elements opaque
          'Visual', 'VisualNOS',
          'Search', 'IncSearch', 'CurSearch',
          'MatchParen',
          'ErrorMsg', 'WarningMsg', 'ModeMsg', 'MoreMsg',
          'Question', 'Title',
          'DiffAdd', 'DiffChange', 'DiffDelete', 'DiffText',
          'SpellBad', 'SpellCap', 'SpellLocal', 'SpellRare',

          -- Keep statusline (lualine) opaque - StatusLine is the main highlight group
          'StatusLine', 'StatusLineNC',

          -- Window separators for better structure visibility
          'VertSplit', 'WinSeparator',

          -- Telescope selection for better visibility
          'TelescopeSelection', 'TelescopeSelectionCaret',
        },
      })

      -- transparent.nvim is now properly configured

      -- Ensure proper menu contrast after transparency is applied
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = function()
          vim.defer_fn(function()
            local is_dark = vim.o.background == "dark"

            -- Force window separators to be transparent with theme-appropriate colors
            local is_dark = vim.o.background == "dark"
            local separator_fg = is_dark and "#484a4a" or "#cacac9"

            vim.api.nvim_set_hl(0, "VertSplit", { bg = "NONE", fg = separator_fg })
            vim.api.nvim_set_hl(0, "WinSeparator", { bg = "NONE", fg = separator_fg })
            vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "NONE" })

            -- Fix dashboard directory icons
            vim.api.nvim_set_hl(0, "Directory", { bg = "NONE" })

          end, 100)
        end,
      })

      -- Additional fix for initial load timing in dark mode
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          vim.defer_fn(function()
            local is_dark = vim.o.background == "dark"
            local separator_fg = is_dark and "#484a4a" or "#cacac9"
            vim.api.nvim_set_hl(0, "VertSplit", { bg = "NONE", fg = separator_fg })
            vim.api.nvim_set_hl(0, "WinSeparator", { bg = "NONE", fg = separator_fg })

            -- Fix dashboard directory icons here too
            vim.api.nvim_set_hl(0, "Directory", { bg = "NONE", fg = is_dark and "#569cd6" or "#1c71d8" })
          end, 300) -- Even later for initial load
        end,
      })
    end,
  },

  -- Fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      -- Setup telescope borders & selection highlight
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = function()
          local is_dark = vim.o.background == "dark"
          local border = is_dark and "#404040" or "#d0d0d0"
          local sel_bg = is_dark and "#37373d" or "#f1f0ef"
          vim.api.nvim_set_hl(0, "TelescopeBorder", { fg = border, bg = "NONE" })
          vim.api.nvim_set_hl(0, "TelescopePromptBorder", { fg = border, bg = "NONE" })
          vim.api.nvim_set_hl(0, "TelescopeResultsBorder", { fg = border, bg = "NONE" })
          vim.api.nvim_set_hl(0, "TelescopePreviewBorder", { fg = border, bg = "NONE" })
          vim.api.nvim_set_hl(0, "TelescopeSelection", { bg = sel_bg, fg = "NONE" })
          vim.api.nvim_set_hl(0, "TelescopeSelectionCaret", { bg = sel_bg, fg = is_dark and "#cccccc" or "#2e3436" })
        end,
      })

      -- Apply highlights immediately
      vim.defer_fn(function()
        local is_dark = vim.o.background == "dark"
        local border = is_dark and "#404040" or "#d0d0d0"
        local sel_bg = is_dark and "#37373d" or "#f1f0ef"
        vim.api.nvim_set_hl(0, "TelescopeBorder", { fg = border, bg = "NONE" })
        vim.api.nvim_set_hl(0, "TelescopePromptBorder", { fg = border, bg = "NONE" })
        vim.api.nvim_set_hl(0, "TelescopeResultsBorder", { fg = border, bg = "NONE" })
        vim.api.nvim_set_hl(0, "TelescopePreviewBorder", { fg = border, bg = "NONE" })
        vim.api.nvim_set_hl(0, "TelescopeSelection", { bg = sel_bg, fg = "NONE" })
        vim.api.nvim_set_hl(0, "TelescopeSelectionCaret", { bg = sel_bg, fg = is_dark and "#cccccc" or "#2e3436" })
      end, 100)

      require("telescope").setup({
        defaults = {
          -- Beautiful borders and styling
          border = true,
          borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
          results_title = "",
          prompt_title = "",
          preview_title = "",
          -- Subtly darken header text for readability
          hl_result_eol = true,
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
        diagnostics = false, -- Disable diagnostic indicators
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
            fill = { bg = "NONE" },
            background = { bg = "#37373d", fg = "#cccccc" },
            buffer_visible = { bg = "#37373d", fg = "#cccccc" },
            buffer_selected = { bg = "#1c1c1c", fg = "#ffffff", bold = true },
          }
        else
          -- Light theme colors
          colors = {
            fill = { bg = "NONE" },
            background = { bg = "#d8d7d4", fg = "#5e5c64" },
            buffer_visible = { bg = "#d8d7d4", fg = "#5e5c64" },
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
    config = function(_, opts)
      require("bufferline").setup(opts)
      
      -- Override the builtin pinned group icon
      local groups = require("bufferline.groups")
      if groups.builtin and groups.builtin.pinned then
        groups.builtin.pinned.icon = "󰐃"
      end
      
      -- Force set indicator colors after setup
      vim.schedule(function()
        local is_dark = vim.o.background == "dark"
        vim.api.nvim_set_hl(0, "BufferLineIndicatorSelected", {
          fg = is_dark and "#569cd6" or "#1c71d8", -- Adwaita blue
          bg = is_dark and "#1e1e1e" or "#ffffff",
        })
      end)
    end,
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
      
      -- Set ExBlack3Bg immediately when plugin loads (for first menu)
      vim.api.nvim_set_hl(0, "ExBlack3Bg", { bg = "#3584e4", fg = "#ffffff" })
      
      -- Also use vim.schedule to ensure it's set after all plugins are loaded
      vim.schedule(function()
        vim.api.nvim_set_hl(0, "ExBlack3Bg", { bg = "#3584e4", fg = "#ffffff" })
      end)
      
      -- Also ensure it persists after colorscheme changes
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = function()
          vim.api.nvim_set_hl(0, "ExBlack3Bg", { bg = "#3584e4", fg = "#ffffff" })
        end
      })
      


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
          { name = " Close Buffer", cmd = "bdelete", rtxt = "" },
          { name = " Close Others", cmd = "BufferLineCloseOthers", rtxt = "" },
          { name = "separator" },
          { name = "󰤻 Split Horizontal", cmd = "split", rtxt = "" },
          { name = "󰤼 Split Vertical", cmd = "vsplit", rtxt = "" },
          { name = "separator" },
          { name = "󰐃 Pin Tab", cmd = "BufferLineTogglePin", rtxt = "" },
          { name = " Pick Buffer", cmd = "BufferLinePick", rtxt = "" },
        },

        lsp_menu = {
          { name = "󰊕 Go to Definition", cmd = "lua vim.lsp.buf.definition()", rtxt = "gd" },
          { name = " Go to References", cmd = "lua vim.lsp.buf.references()", rtxt = "gr" },
          { name = " Go to Implementation", cmd = "lua vim.lsp.buf.implementation()", rtxt = "gi" },
          { name = " Go to Type Definition", cmd = "lua vim.lsp.buf.type_definition()", rtxt = "gt" },
          { name = "separator" },
          { name = " Rename Symbol", cmd = "lua vim.lsp.buf.rename()", rtxt = "rn" },
          { name = " Code Action", cmd = "lua vim.lsp.buf.code_action()", rtxt = "ca" },
          { name = "󰊄 Format Document", cmd = "lua vim.lsp.buf.format()", rtxt = "fm" },
          { name = "separator" },
          { name = " Show Diagnostics", cmd = "lua vim.diagnostic.open_float()", rtxt = "df" },
          { name = " Toggle Diagnostic Lines", cmd = "lua require('lsp_lines').toggle()", rtxt = "ld" },
        },

        git_menu = {
          { name = "󰊢 Git Status", cmd = "Neotree float git_status git_base=main", rtxt = "gS" },
          { name = " Open Diffview", cmd = "DiffviewOpen", rtxt = "gd" },
          { name = " Diff Last Commit", cmd = "DiffviewOpen HEAD~1", rtxt = "gD" },
          { name = " File History", cmd = "DiffviewFileHistory %", rtxt = "gh" },
          { name = " Close Diffview", cmd = "DiffviewClose", rtxt = "gc" },
          { name = "separator" },
          { name = "󰊢 Git Blame Line", cmd = "lua Snacks.git.blame_line()", rtxt = "gB" },
        },

        terminal_menu = {
          { name = "󰆍 Toggle Terminal", cmd = "lua Snacks.terminal()", rtxt = "tt" },
          { name = "󰆍 Floating Terminal", cmd = "lua Snacks.terminal.toggle()", rtxt = "" },
          { name = "separator" },
          { name = " Python REPL", cmd = "lua Snacks.terminal.toggle('python3')", rtxt = "" },
          { name = " R Console", cmd = "lua Snacks.terminal.toggle('R')", rtxt = "" },
          { name = "📓 IPython", cmd = "lua Snacks.terminal.toggle('ipython')", rtxt = "" },
        },

        file_menu = {
          { name = "󰈞 Find Files", cmd = "Telescope find_files", rtxt = "ff" },
          { name = "󱋡 Recent Files", cmd = "Telescope oldfiles", rtxt = "fr" },
          { name = "󰈬 Live Grep", cmd = "Telescope live_grep", rtxt = "fg" },
          { name = "separator" },
          { name = "󰝒 New File", cmd = "ene", rtxt = "" },
          { name = "󰙅 File Explorer", cmd = "Neotree toggle", rtxt = "e" },
          { name = "󰘎 Code Outline", cmd = "Outline", rtxt = "s" },
          { name = "separator" },
          { name = " Save", cmd = "w", rtxt = "" },
          { name = " Save All", cmd = "wa", rtxt = "" },
        },

        layout_menu = {
          { name = " Toggle Left Panel", cmd = "lua require('edgy').toggle('left')", rtxt = "ll" },
          { name = " Toggle Right Panel", cmd = "lua require('edgy').toggle('right')", rtxt = "lr" },
          { name = " Toggle Bottom Panel", cmd = "lua require('edgy').toggle('bottom')", rtxt = "lb" },
          { name = "separator" },
          { name = " Full IDE Layout", cmd = "lua require('edgy').open()", rtxt = "lL" },
          { name = " Close All Panels", cmd = "lua require('edgy').close()", rtxt = "lc" },
          { name = "separator" },
          { name = " Zen Mode", cmd = "lua Snacks.zen()", rtxt = "z" },
          { name = " Zoom Window", cmd = "lua Snacks.zen.zoom()", rtxt = "Z" },
        },

        debug_menu = {
          { name = " Add Breakpoint", cmd = "echo 'Debug: Breakpoint (nvim-dap needed)'", rtxt = "" },
          { name = " Start Debugging", cmd = "echo 'Debug: Start (nvim-dap needed)'", rtxt = "" },
          { name = "  Step Over", cmd = "echo 'Debug: Step Over (nvim-dap needed)'", rtxt = "" },
          { name = " Step Into", cmd = "echo 'Debug: Step Into (nvim-dap needed)'", rtxt = "" },
          { name = " Step Out", cmd = "echo 'Debug: Step Out (nvim-dap needed)'", rtxt = "" },
          { name = " Stop Debugging", cmd = "echo 'Debug: Stop (nvim-dap needed)'", rtxt = "" },
          { name = "separator" },
        },

        test_menu = {
          { name = "󰙨 Run File Tests", cmd = "lua require('neotest').run.run(vim.fn.expand('%'))", rtxt = "tf" },
          { name = " Run Nearest Test", cmd = "lua require('neotest').run.run()", rtxt = "tn" },
          { name = "󰙨 Run All Tests", cmd = "lua require('neotest').run.run(vim.fn.getcwd())", rtxt = "ta" },
          { name = " Run Last Test", cmd = "lua require('neotest').run.run_last()", rtxt = "tl" },
          { name = "separator" },
          { name = " Test Summary", cmd = "lua require('neotest').summary.toggle()", rtxt = "ts" },
          { name = " Show Output", cmd = "lua require('neotest').output.open({ enter = true, auto_close = true })", rtxt = "to" },
          { name = " Toggle Output Panel", cmd = "lua require('neotest').output_panel.toggle()", rtxt = "tO" },
          { name = "separator" },
          { name = " Debug Test", cmd = "lua require('neotest').run.run({strategy = 'dap'})", rtxt = "td" },
          { name = " Toggle Watch", cmd = "lua require('neotest').watch.toggle(vim.fn.expand('%'))", rtxt = "tw" },
          { name = " Test Error Details", cmd = "lua require('neotest').output.open({ enter = false, auto_close = false, short = false })", rtxt = "te" },
          { name = " Stop Tests", cmd = "lua require('neotest').run.stop()", rtxt = "tS" },
        },

        context_menu = {
          { name = " File Operations", cmd = "FileMenu", rtxt = "mf" },
          { name = "separator" },
          { name = " LSP Actions", cmd = "LspMenu", rtxt = "ml" },
          { name = " Debug Tools", cmd = "DebugMenu", rtxt = "md" },
          { name = "separator" },
          { name = "󰊢 Git Operations", cmd = "GitMenu", rtxt = "mg" },
          { name = " Layout Control", cmd = "LayoutMenu", rtxt = "mp" },
          { name = " Buffer Actions", cmd = "BufferMenu", rtxt = "mb" },
          { name = " Terminal/REPL", cmd = "TerminalMenu", rtxt = "mt" },
        }
      }

      -- Add test runner to both context menu and right-click menu
      table.insert(_G.ide_menus.context_menu, #_G.ide_menus.context_menu, { name = "󰙨 Test Runner", cmd = "TestMenu", rtxt = "mk" })

      -- Create user commands with theme-aware styling
      local function menu_opts()
        -- Ensure proper menu highlighting for both light and dark themes
        local is_dark = vim.o.background == "dark"

        -- Set the nvzone/menu hover highlight group (fixes black menu selection)
        if is_dark then
          vim.api.nvim_set_hl(0, "ExBlack3Bg", { bg = "#3584e4", fg = "#ffffff" })
          -- Set menu-specific highlights for better contrast
          vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#2d2d2d", fg = "#ffffff" })
          vim.api.nvim_set_hl(0, "FloatBorder", { bg = "#2d2d2d", fg = "#666666" })
        else
          vim.api.nvim_set_hl(0, "ExBlack3Bg", { bg = "#3584e4", fg = "#ffffff" })
          -- Set menu-specific highlights for better contrast
          vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#ffffff", fg = "#2e3436" })
          vim.api.nvim_set_hl(0, "FloatBorder", { bg = "#ffffff", fg = "#999999" })
        end

        return {
          mouse = true,
          border = 'rounded',
          winblend = 0,  -- No transparency for menu windows to ensure readability
        }
      end
      vim.api.nvim_create_user_command("BufferMenu", function() menu.open(normalize_menu(_G.ide_menus.buffer_menu), menu_opts()) end, {})
      vim.api.nvim_create_user_command("LspMenu", function() menu.open(normalize_menu(_G.ide_menus.lsp_menu), menu_opts()) end, {})
      vim.api.nvim_create_user_command("GitMenu", function() menu.open(normalize_menu(_G.ide_menus.git_menu), menu_opts()) end, {})
      vim.api.nvim_create_user_command("TerminalMenu", function() menu.open(normalize_menu(_G.ide_menus.terminal_menu), menu_opts()) end, {})
      vim.api.nvim_create_user_command("FileMenu", function() menu.open(normalize_menu(_G.ide_menus.file_menu), menu_opts()) end, {})
      vim.api.nvim_create_user_command("LayoutMenu", function() menu.open(normalize_menu(_G.ide_menus.layout_menu), menu_opts()) end, {})
      vim.api.nvim_create_user_command("DebugMenu", function() menu.open(normalize_menu(_G.ide_menus.debug_menu), menu_opts()) end, {})
      vim.api.nvim_create_user_command("TestMenu", function() menu.open(normalize_menu(_G.ide_menus.test_menu), menu_opts()) end, {})
      vim.api.nvim_create_user_command("ContextMenu", function() menu.open(normalize_menu(_G.ide_menus.context_menu), menu_opts()) end, {})

      -- Right-click context menu with copy/paste + IDE entries
      vim.api.nvim_create_user_command("RightClickMenu", function()
        if vim.bo.filetype == 'snacks_dashboard' or vim.bo.filetype == 'dashboard' then
          return
        end
        -- Use the same context menu as Ctrl-t for consistency
        menu.open(normalize_menu(_G.ide_menus.context_menu), menu_opts())
      end, {})
    end,
    keys = {
      { "<C-t>", function()
          if vim.bo.filetype == 'snacks_dashboard' or vim.bo.filetype == 'dashboard' then return end
          vim.cmd('ContextMenu')
        end, desc = "Open Context Menu" },
      { "<leader>m", function()
          if vim.bo.filetype == 'snacks_dashboard' or vim.bo.filetype == 'dashboard' then return end
          vim.cmd('ContextMenu')
        end, desc = "Open Context Menu" },
      { "<leader>mb", "<cmd>BufferMenu<cr>", desc = "Buffer Menu" },
      { "<leader>ml", "<cmd>LspMenu<cr>", desc = "LSP Menu" },
      { "<leader>mg", "<cmd>GitMenu<cr>", desc = "Git Menu" },
      { "<leader>mt", "<cmd>TerminalMenu<cr>", desc = "Terminal Menu" },
      { "<leader>mf", "<cmd>FileMenu<cr>", desc = "File Menu" },
      { "<leader>mp", "<cmd>LayoutMenu<cr>", desc = "Layout Menu" },
      { "<leader>md", "<cmd>DebugMenu<cr>", desc = "Debug Menu" },

      -- Right-click context menu support
      { "<RightMouse>", function()
          if vim.bo.filetype == 'snacks_dashboard' or vim.bo.filetype == 'dashboard' then return end
          vim.cmd('RightClickMenu')
        end, desc = "Right-click Context Menu", mode = { "n", "v" } },
    },
  },
}
