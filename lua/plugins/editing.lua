return {
  -- Auto pairs
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({})
      -- nvim-cmp integration disabled; blink.cmp has built-in bracket handling
    end,
  },

  -- GitHub Copilot (inline AI suggestions) without stealing Tab/Enter
  {
    "zbirenbaum/copilot.lua",
    event = "InsertEnter",
    opts = {
      suggestion = {
        enabled = true,
        auto_trigger = true,
        debounce = 75,
        keymap = {
          accept = "<M-l>",
          accept_word = "<M-w>",
          accept_line = "<M-;>",
          next = "<M-]>",
          prev = "<M-[>",
          dismiss = "<C-]>",
        },
      },
      panel = { enabled = false },
      filetypes = {
        ["*"] = true,
      },
    },
    config = function(_, opts)
      require("copilot").setup(opts)
      local function set_copilot_hl()
        local is_dark = vim.o.background == "dark"
        vim.api.nvim_set_hl(0, "CopilotSuggestion", { fg = is_dark and "#858585" or "#9a9996", italic = true })
      end
      set_copilot_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = set_copilot_hl })
    end,
  },

  -- REPL integration
  {
    "jpalardy/vim-slime",
    ft = { "python", "r", "julia", "bash" },
    config = function()
      vim.g.slime_target = "tmux"
      vim.g.slime_paste_file = vim.fn.expand("$HOME/.slime_paste")
      vim.g.slime_default_config = { socket_name = "default", target_pane = "{last}" }
    end,
  },

  -- Python syntax checking
  {
    "nvie/vim-flake8",
    ft = "python",
    config = function()
      vim.g.flake8_show_in_gutter = 110
    end,
  },

  -- Markdown preview
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = "cd app && yarn install",
    config = function()
      vim.g.mkdp_auto_start = 0
      vim.g.mkdp_auto_close = 1
    end,
  },
}
