return {
  -- Auto pairs
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({})
      
      -- Integration with nvim-cmp
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      local cmp = require("cmp")
      cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
    end,
  },

  -- GitHub Copilot
  {
    "github/copilot.vim",
    event = "InsertEnter",
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