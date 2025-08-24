return {
  {
    "Mofiqul/adwaita.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.g.adwaita_darker = false
      vim.g.adwaita_disable_cursorline = false
      vim.g.adwaita_transparent = true
      vim.cmd.colorscheme("adwaita")
    end,
  },
}
