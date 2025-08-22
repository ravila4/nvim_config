return {
  -- Dependencies
  {
    "nvim-lua/plenary.nvim",
    lazy = true,
  },
  {
    "MunifTanjim/nui.nvim",
    lazy = true,
  },

  -- R language support
  {
    "jalvesaq/Nvim-R",
    ft = { "r", "rmd", "rnoweb" },
  },

  -- Jupyter notebook support
  {
    "goerz/jupytext.vim",
    ft = { "ipynb", "jupytext" },
  },

  -- Firefox integration
  {
    "glacambre/firenvim",
    build = function()
      vim.fn["firenvim#install"](0)
    end,
    config = function()
      vim.g.firenvim_config = {
        globalSettings = {
          alt = "all",
        },
        localSettings = {
          [".*"] = {
            cmdline = "neovim",
            content = "text",
            priority = 0,
            selector = "textarea",
            takeover = "never",
          },
        },
      }

      -- UI adjustments for Firenvim
      local function on_ui_enter()
        vim.opt.guifont = "AndaleMono:h9"
        vim.keymap.set("n", "<space>", ":set lines=28 columns=110<CR>")
        
        local fontsize = 9
        local function adjust_font_size(amount)
          fontsize = fontsize + amount
          vim.opt.guifont = "AndaleMono:h" .. fontsize
          vim.fn.rpcnotify(0, "Gui", "WindowMaximized", 1)
        end

        vim.keymap.set({ "n", "i" }, "<C-=>", function() adjust_font_size(1) end)
        vim.keymap.set({ "n", "i" }, "<C-->", function() adjust_font_size(-1) end)
      end

      vim.api.nvim_create_autocmd("UIEnter", {
        callback = on_ui_enter,
      })
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

  -- Claude Code integration
  {
    "coder/claudecode.nvim",
    event = "VeryLazy",
    config = function()
      require("claudecode").setup({
        terminal = {
          split_side = "right",
          split_width_percentage = 0.4,
          provider = "auto",
          auto_close = true,
        },
      })
    end,
  },
}