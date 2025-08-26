-- Python development tools
-- UV virtual environment management and Python-specific utilities

return {
  -- UV virtual environment manager
  {
    "benomahony/uv.nvim",
    ft = "python",
    config = function()
      require("uv").setup({
        picker_integration = true, -- Enable Snacks/Telescope integration
        auto_activate = true,      -- Automatically activate virtual environments
        notifications = {
          enabled = true,          -- Show activation notifications
          provider = "snacks",     -- Use snacks.nvim for notifications
        },
        keymaps = {
          prefix = "<leader>uv",   -- UV commands prefix
        },
      })
    end,
  },
}