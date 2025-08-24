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
      
      -- Enhanced transparency settings for better theme consistency
      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "adwaita",
        callback = function()
          -- Ensure consistent transparency across themes
          local is_dark = vim.o.background == "dark"
          
          -- Core transparency groups
          local transparent_groups = {
            "Normal", "NormalNC", "SignColumn", "EndOfBuffer",
            "NormalFloat", "FloatBorder", "FloatTitle",
            "StatusLine", "StatusLineNC", "TabLine", "TabLineFill",
          }
          
          for _, group in ipairs(transparent_groups) do
            vim.api.nvim_set_hl(0, group, { bg = "NONE" })
          end
          
          -- Theme-specific enhancements for better visibility
          if is_dark then
            -- Dark theme: subtle backgrounds for important elements
            vim.api.nvim_set_hl(0, "CursorLine", { bg = "#2a2a2a" })
            vim.api.nvim_set_hl(0, "Visual", { bg = "#404040" })
            vim.api.nvim_set_hl(0, "Search", { bg = "#3d5a80", fg = "#ffffff" })
            vim.api.nvim_set_hl(0, "IncSearch", { bg = "#228787", fg = "#ffffff" })
          else
            -- Light theme: subtle backgrounds for important elements
            vim.api.nvim_set_hl(0, "CursorLine", { bg = "#f8f8f8" })
            vim.api.nvim_set_hl(0, "Visual", { bg = "#e6e6e6" })
            vim.api.nvim_set_hl(0, "Search", { bg = "#b3d9ff", fg = "#000000" })
            vim.api.nvim_set_hl(0, "IncSearch", { bg = "#228787", fg = "#ffffff" })
          end
          
          -- Maintain teal accent consistency
          vim.api.nvim_set_hl(0, "Cursor", { bg = "#228787", fg = "#ffffff" })
          vim.api.nvim_set_hl(0, "lCursor", { bg = "#228787", fg = "#ffffff" })
        end,
      })
      
      -- Apply initial transparency settings
      vim.defer_fn(function()
        vim.cmd("doautocmd ColorScheme adwaita")
      end, 100)
    end,
  },
}
