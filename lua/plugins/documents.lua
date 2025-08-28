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
      require("markview").setup({
        -- Experimental settings
        experimental = {
          check_rtp_message = false, -- Hide the runtime path warning message
        },

        -- Preview configuration
        preview = {
          filetypes = { "markdown", "quarto", "rmd" }, -- Moved from top level
          modes = { "n", "no", "c" }, -- Normal, operator-pending, command modes
          hybrid_modes = { "n" },     -- Partial rendering in normal mode
          ignore_buftypes = { "nofile", "terminal" }, -- Buffer types to ignore
          callbacks = {
            on_enable = function()
              -- Disable conflicting plugins temporarily
              vim.cmd("TSBufDisable highlight") -- Avoid conflicts
            end,
            on_disable = function()
              -- Re-enable when markview is disabled
              vim.cmd("TSBufEnable highlight")
            end,
          },
        },
      })

      -- Keybindings for markview
      vim.keymap.set("n", "<leader>mv", ":Markview toggleAll<CR>", { desc = "Toggle Markview" })
      vim.keymap.set("n", "<leader>ms", ":Markview splitToggle<CR>", { desc = "Markview split toggle" })
    end,
  },
  -- Obsidian notes
  {
    "epwalsh/obsidian.nvim",
    event = {
      "BufReadPre " .. vim.fn.expand("~") .. "/Documents/Obsidian-Notes/**.md",
      "BufNewFile " .. vim.fn.expand("~") .. "/Documents/Obsidian-Notes/**.md",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "hrsh7th/nvim-cmp",
    },
    config = function()
      require("obsidian").setup({
        dir = "~/Documents/Obsidian-Notes",
        completion = {
          nvim_cmp = true,
        },
        ui = {
          enable = false, -- Disable UI features since markview.nvim handles rendering
        },
      })

      -- Obsidian keymap
      vim.keymap.set("n", "gf", function()
        if require("obsidian").util.cursor_on_markdown_link() then
          return "<cmd>ObsidianFollowLink<CR>"
        else
          return "gf"
        end
      end, { noremap = false, expr = true })
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
          set_filetype = true,
        },
        handle_leading_whitespace = true,
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
    ft = { "quarto" },
    config = function()
      require("quarto").setup({
        debug = false,
        closePreviewOnExit = true,
        lspFeatures = {
          enabled = true,
          chunks = "curly",
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
          default_method = "slime",
          ft_runners = {},
          never_run = { "yaml" },
        },
      })
    end,
  },
}
