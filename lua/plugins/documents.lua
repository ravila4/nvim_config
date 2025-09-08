-- Document authoring and note-taking tools
-- Quarto, Obsidian, and embedded code support

return {
  -- Markview.nvim for beautiful markdown rendering
  {
    "OXY2DEV/markview.nvim",
    lazy = false, -- Plugin handles its own lazy loading
    priority = 10000, -- Very high priority to load before treesitter
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      local markview = require("markview")
      local presets = require("markview.presets")

      markview.setup({
        markdown = {
          headings = {
            enable = true,
            heading_1 = {
              style = "icon",
              icon = "# ",
              sign = "",
              hl = "MarkviewPalette1Bg", -- Full line background
            },
            heading_2 = {
              style = "icon",
              icon = "## ",
              sign = "",
              hl = "MarkviewPalette2Bg", -- Full line background
            },
            heading_3 = {
              style = "icon",
              icon = "### ",
              sign = "",
              hl = "MarkviewPalette3Bg", -- Full line background
            },
            heading_4 = {
              style = "icon",
              icon = "#### ",
              sign = "",
              hl = "MarkviewPalette4Bg", -- Full line background
            },
            heading_5 = {
              style = "icon",
              icon = "##### ",
              sign = "",
              hl = "MarkviewPalette5Bg", -- Full line background
            },
            heading_6 = {
              style = "icon",
              icon = "###### ",
              sign = "",
              hl = "MarkviewPalette6Bg", -- Full line background
            },
          },
          code_blocks = {
            enable = true,
            sign = false,
          },
          horizontal_rules = presets.horizontal_rules.thin,
        },
        -- Disable markview's image handling - let snacks.image handle it
        markdown_inline = {
          images = {
            enable = false,
          },
        },
        -- Enable LaTeX math rendering
        latex = {
          enable = true,
          blocks = {
            enable = true, -- Enable display math ($$...$$)
            hl = "MarkviewCode", -- Highlight group for display math blocks
            text = "  LaTeX ", -- Text shown for display math blocks
          },
          inlines = {
            enable = true, -- Enable inline math ($...$)
            hl = "MarkviewInlineCode", -- Highlight group for inline math
          },
          fonts = { enable = true }, -- Font styling (\mathbb, \mathcal, etc.)
          commands = { enable = true }, -- LaTeX commands (\frac, \sum, etc.)
          symbols = { enable = true }, -- Mathematical symbols
        },
        -- Experimental settings
        experimental = {
          check_rtp_message = false, -- Hide the runtime path warning message
        },

        preview = {
          filetypes = { "markdown", "quarto", "rmd" }, -- Moved from top level
          modes = { "n", "no", "c" }, -- Normal, operator-pending, command modes
          hybrid_modes = { "n" }, -- Partial rendering in normal mode
          ignore_buftypes = { "nofile", "terminal" }, -- Buffer types to ignore
          callbacks = {
            on_enable = function()
              -- Keep treesitter highlight enabled for code block syntax highlighting
              -- Only disable additional_vim_regex_highlighting to avoid conflicts
              vim.opt_local.additional_vim_regex_highlighting = false
              -- Enable line wrapping for markdown
              vim.opt_local.wrap = true
              vim.opt_local.linebreak = true
            end,
            on_disable = function()
              -- Restore original highlighting settings
              vim.opt_local.additional_vim_regex_highlighting = false
            end,
          },
        },
      })

      -- Keybindings for markview
      vim.keymap.set("n", "<leader>mv", ":Markview toggleAll<CR>", { desc = "Toggle Markview" })
      vim.keymap.set("n", "<leader>ms", ":Markview splitToggle<CR>", { desc = "Markview split toggle" })
    end,
  },
  -- Obsidian notes (community fork)
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*", -- Use latest stable release
    event = {
      "BufReadPre " .. vim.fn.expand("~") .. "/Documents/Obsidian-Notes/**.md",
      "BufNewFile " .. vim.fn.expand("~") .. "/Documents/Obsidian-Notes/**.md",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "hrsh7th/nvim-cmp",
      "nvim-telescope/telescope.nvim", -- For picker functionality
    },
    config = function()
      require("obsidian").setup({
        workspaces = {
          {
            name = "notes",
            path = "~/Documents/Obsidian-Notes",
          },
        },

        -- Enhanced completion configuration
        completion = {
          nvim_cmp = true,
          min_chars = 2,
        },

        -- Note creation location
        new_notes_location = "current_dir",

        -- Picker configuration (uses telescope by default)
        picker = {
          name = "telescope.nvim",
          mappings = {
            new = "<C-x>", -- Create new note
            insert_link = "<C-l>", -- Insert link to note
          },
        },

        -- Daily notes configuration (matches your existing structure)
        daily_notes = {
          folder = "Daily Log",
          date_format = "%Y-%m-%d",
          alias_format = "%B %d, %Y",
        },

        -- UI configuration - keep disabled for markview compatibility
        ui = {
          enable = false, -- Let markview handle rendering
          update_debounce = 200,
        },

        -- Disable legacy commands to avoid deprecation warnings
        legacy_commands = false,

        -- Attachment configuration (matches your _images pattern)
        attachments = {
          img_folder = "_images",
        },

        -- Note path and ID generation
        note_id_func = function(title)
          local suffix = ""
          if title ~= nil then
            suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
          else
            for _ = 1, 4 do
              suffix = suffix .. string.char(math.random(65, 90))
            end
          end
          return tostring(os.date("%Y-%m-%d")) .. "_" .. suffix
        end,

        -- Template configuration (matches your existing Templates folder)
        templates = {
          subdir = "Templates",
          date_format = "%Y-%m-%d",
          time_format = "%H:%M",
        },
      })

      -- Enhanced Obsidian keymaps
      vim.keymap.set("n", "gf", function()
        if require("obsidian").util.cursor_on_markdown_link() then
          return "<cmd>ObsidianFollowLink<CR>"
        else
          return "gf"
        end
      end, { noremap = false, expr = true, desc = "Follow Obsidian link" })

      -- Additional useful keymaps
      vim.keymap.set("n", "<leader>oc", "<cmd>ObsidianTOC<CR>", { desc = "Obsidian TOC" })
      vim.keymap.set("n", "<leader>ob", "<cmd>ObsidianBacklinks<CR>", { desc = "Obsidian backlinks" })
      vim.keymap.set("n", "<leader>ot", "<cmd>ObsidianTags<CR>", { desc = "Obsidian tags" })
      vim.keymap.set("n", "<leader>on", "<cmd>ObsidianNew<CR>", { desc = "New Obsidian note" })
      vim.keymap.set("n", "<leader>os", "<cmd>ObsidianSearch<CR>", { desc = "Search Obsidian notes" })
    end,
  },

  -- Otter for embedded code completion
  {
    "jmbuhr/otter.nvim",
    dependencies = {
      "hrsh7th/nvim-cmp",
      "neovim/nvim-lspconfig",
      "nvim-treesitter/nvim-treesitter",
    },
    ft = { "quarto", "markdown", "rmd" },
    config = function()
      require("otter").setup({
        lsp = {
          hover = {
            border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
          },
        },
        buffers = {
          set_filetype = true, -- Essential for LSP features and syntax highlighting
        },
        handle_leading_whitespace = true,
        verbose = {
          no_code_found = true, -- Debug: notify if no code blocks found
        },
      })

      -- Automatically activate otter for markdown and quarto files
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "markdown", "quarto" },
        callback = function()
          -- Activate otter for all detected languages (python, r, julia, etc.)
          require("otter").activate()
        end,
      })
    end,
  },

  -- Quarto support
  {
    "quarto-dev/quarto-nvim",
    dependencies = {
      "jmbuhr/otter.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    ft = { "quarto", "markdown" }, -- Add markdown support
    config = function()
      require("quarto").setup({
        debug = false,
        closePreviewOnExit = true,
        lspFeatures = {
          enabled = true,
          chunks = "all", -- Changed from "curly" to "all" to support markdown
          languages = { "r", "python", "julia", "bash", "html" },
          diagnostics = {
            enabled = true,
            triggers = { "BufWritePost" },
          },
          completion = {
            enabled = true,
          },
        },
        codeRunner = {
          enabled = true,
          default_method = "molten", -- Changed from "slime" to "molten"
          ft_runners = {},
          never_run = { "yaml" },
        },
      })
    end,
  },
}
