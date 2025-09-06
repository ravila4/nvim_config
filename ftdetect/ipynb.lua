-- Filetype detection for Jupyter notebooks
vim.api.nvim_create_autocmd({"BufNewFile", "BufRead"}, {
  pattern = "*.ipynb",
  callback = function()
    vim.bo.filetype = "ipynb"
  end,
})