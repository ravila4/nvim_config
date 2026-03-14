return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    lazy = false, -- nvim-treesitter does not support lazy-loading
    dependencies = {
      "OXY2DEV/markview.nvim", -- Ensure markview loads before treesitter
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    config = function()
      require("nvim-treesitter").setup()

      -- Install parsers
      require("nvim-treesitter").install({
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
      })

      -- Configure textobjects
      require("nvim-treesitter").setup({
        textobjects = {
          select = {
            enable = true,
            keymaps = {
              ["ib"] = "@code_cell.inner",
              ["ab"] = "@code_cell.outer",
            },
          },
          move = {
            enable = true,
            goto_next_start = {
              ["]b"] = "@code_cell.inner",
            },
            goto_previous_start = {
              ["[b"] = "@code_cell.inner",
            },
          },
        },
      })

      -- Enable highlighting and indentation for all filetypes with parsers
      vim.api.nvim_create_autocmd("FileType", {
        callback = function()
          local ok = pcall(vim.treesitter.start)
          if ok then
            vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },
}
