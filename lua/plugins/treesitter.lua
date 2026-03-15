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
      local move = require("nvim-treesitter-textobjects.move")
      local select = require("nvim-treesitter-textobjects.select")

      -- Cell navigation: ]c / [c for code blocks, ]h / [h for headings
      vim.keymap.set({ "n", "x", "o" }, "]c", function() move.goto_next_start("@block.inner") end, { desc = "Next code block" })
      vim.keymap.set({ "n", "x", "o" }, "[c", function() move.goto_previous_start("@block.inner") end, { desc = "Prev code block" })
      vim.keymap.set({ "n", "x", "o" }, "]h", function() move.goto_next_start("@class.outer") end, { desc = "Next heading" })
      vim.keymap.set({ "n", "x", "o" }, "[h", function() move.goto_previous_start("@class.outer") end, { desc = "Prev heading" })

      -- Block text objects: ib / ab for inner/around block
      vim.keymap.set({ "x", "o" }, "ib", function() select.select_textobject("@block.inner") end, { desc = "inner block" })
      vim.keymap.set({ "x", "o" }, "ab", function() select.select_textobject("@block.outer") end, { desc = "around block" })

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
