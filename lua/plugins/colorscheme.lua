return {
  {
    "Mofiqul/adwaita.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.g.adwaita_darker = false
      vim.g.adwaita_disable_cursorline = false
      vim.g.adwaita_transparent = false
      vim.cmd.colorscheme("adwaita")
      
      -- Let transparent.nvim handle excludes - no custom autocmd needed
      -- The excludes list will preserve the original adwaita theme backgrounds
      
      -- No need to apply initial enhancements - transparent.nvim preserves excluded elements
    end,
  },
}
