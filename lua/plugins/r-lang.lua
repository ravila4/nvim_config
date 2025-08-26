-- R language and statistical computing support

return {
  -- R language support
  {
    "jalvesaq/Nvim-R",
    ft = { "r", "rmd", "rnoweb" },
  },

  -- Jupyter notebook support (including R notebooks)
  {
    "goerz/jupytext.vim",
    ft = { "ipynb", "jupytext" },
  },
}