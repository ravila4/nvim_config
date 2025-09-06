return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "OXY2DEV/markview.nvim", -- Ensure markview loads before treesitter
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "javascript",
          "typescript",
          "python",
          "vim",
          "vimdoc",
          "json",
          "html",
          "bash",
          "css",
          "r",
          "lua",
          "markdown",
          "markdown_inline",
          "latex", -- For LaTeX math rendering in markview
        },
        sync_install = false,
        auto_install = true,
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        indent = {
          enable = true,
        },
      })
    end,
  },
}
