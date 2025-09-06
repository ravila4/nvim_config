-- Filetype detection for Jupyter notebooks
-- Set to markdown for better syntax highlighting with jupytext.nvim
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  pattern = "*.ipynb",
  callback = function()
    vim.bo.filetype = "markdown"
    -- Ensure syntax highlighting is enabled
    vim.defer_fn(function()
      vim.cmd("syntax enable")
    end, 50)
  end,
})
