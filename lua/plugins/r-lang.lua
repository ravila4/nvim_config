-- R language and statistical computing support

return {
  -- R language support
  {
    "jalvesaq/Nvim-R",
    ft = { "r", "rmd", "rnoweb", "quarto" },
    enabled = false, -- Temporarily disabled due to job_start error
    config = function()
      -- Ensure compatibility with Neovim
      vim.g.R_in_buffer = 0
      vim.g.R_tmux_split = 1
      vim.g.R_assign = 0
    end,
  },

}