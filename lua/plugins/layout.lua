return {
  -- Modern layout management for IDE-like experience
  {
    "folke/edgy.nvim",
    event = "VeryLazy",
    opts = {
      bottom = {
        -- Terminal at bottom (like RStudio console)
        {
          ft = "toggleterm",
          size = { height = 0.25 },
          filter = function(buf, win)
            return vim.api.nvim_win_get_config(win).relative == ""
          end,
        },
        -- Trouble diagnostics
        {
          ft = "trouble",
          size = { height = 10 },
        },
        -- QuickFix
        { ft = "qf", title = "QuickFix" },
        -- Help
        {
          ft = "help",
          size = { height = 20 },
          filter = function(buf)
            return vim.bo[buf].buftype == "help"
          end,
        },
      },
      left = {
        -- File explorer (like RStudio files panel)
        {
          title = "Files",
          ft = "neo-tree",
          filter = function(buf)
            return vim.b[buf].neo_tree_source == "filesystem"
          end,
          size = { width = 0.25 },
        },
        -- Outline/symbols (like RStudio environment panel)
        {
          title = "Outline",
          ft = "Outline",
          size = { width = 0.25 },
        },
      },
      right = {
        -- Git status
        {
          title = "Git",
          ft = "fugitive",
          size = { width = 0.3 },
        },
        -- Database UI (if using)
        {
          title = "DB",
          ft = "dbui",
          size = { width = 0.3 },
        },
      },
      keys = {
        -- Increase width
        ["<c-Right>"] = function(win)
          win:resize("width", 2)
        end,
        -- Decrease width
        ["<c-Left>"] = function(win)
          win:resize("width", -2)
        end,
        -- Increase height
        ["<c-Up>"] = function(win)
          win:resize("height", 2)
        end,
        -- Decrease height
        ["<c-Down>"] = function(win)
          win:resize("height", -2)
        end,
      },
    },
  },

  -- Better terminal integration (like RStudio console)
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    keys = {
      { "<leader>tt", "<cmd>ToggleTerm<cr>", desc = "Toggle terminal" },
      { "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", desc = "Floating terminal" },
      { "<leader>tr", "<cmd>ToggleTerm direction=horizontal size=15<cr>", desc = "REPL terminal" },
    },
    config = function()
      require("toggleterm").setup({
        size = function(term)
          if term.direction == "horizontal" then
            return 15
          elseif term.direction == "vertical" then
            return vim.o.columns * 0.4
          end
        end,
        open_mapping = [[<c-\>]],
        direction = "horizontal",
        persist_size = true,
        start_in_insert = true,
        shell = vim.o.shell,
        float_opts = {
          border = "curved",
          winblend = 10,
        },
      })
    end,
  },

  -- File tree with better integration
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cmd = "Neotree",
    keys = {
      { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Toggle file explorer" },
      { "<leader>E", "<cmd>Neotree focus<cr>", desc = "Focus file explorer" },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require("neo-tree").setup({
        close_if_last_window = false,
        popup_border_style = "rounded",
        enable_git_status = true,
        enable_diagnostics = true,
        default_component_configs = {
          container = {
            enable_character_fade = true,
          },
          indent = {
            indent_size = 2,
            padding = 1,
            with_markers = true,
            indent_marker = "│",
            last_indent_marker = "└",
            highlight = "NeoTreeIndentMarker",
          },
          icon = {
            folder_closed = "",
            folder_open = "",
            folder_empty = "󰜌",
            default = "*",
          },
          git_status = {
            symbols = {
              added = "",
              modified = "",
              deleted = "✖",
              renamed = "󰁕",
              untracked = "",
              ignored = "",
              unstaged = "󰄱",
              staged = "",
              conflict = "",
            },
          },
        },
        window = {
          position = "left",
          width = 40,
          mapping_options = {
            noremap = true,
            nowait = true,
          },
        },
        filesystem = {
          window = {
            mappings = {
              ["<bs>"] = "navigate_up",
              ["."] = "set_root",
              ["H"] = "toggle_hidden",
              ["/"] = "fuzzy_finder",
              ["f"] = "filter_on_submit",
              ["<c-x>"] = "clear_filter",
            },
          },
        },
      })
    end,
  },

  -- Code outline/symbols (like RStudio environment)
  {
    "hedyhli/outline.nvim",
    cmd = { "Outline", "OutlineOpen" },
    keys = {
      { "<leader>s", "<cmd>Outline<CR>", desc = "Toggle outline" },
    },
    config = function()
      require("outline").setup({
        outline_window = {
          position = "right",
          width = 25,
          relative_width = true,
          auto_close = false,
        },
        outline_items = {
          highlight_hovered_item = true,
          show_symbol_details = true,
        },
        symbols = {
          filter = {
            "Class",
            "Constructor",
            "Enum",
            "Field",
            "Function",
            "Interface",
            "Method",
            "Module",
            "Namespace",
            "Package",
            "Property",
            "Struct",
            "Trait",
          },
        },
      })
    end,
  },
}