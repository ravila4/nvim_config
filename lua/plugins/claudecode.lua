-- Claude Code integration for seamless AI assistance
-- Provides simple context sending and floating panel support

return {
  -- Claude Code Neovim integration
  {
    "coder/claudecode.nvim",
    lazy = false, -- Load immediately so commands and menu are available
    dependencies = {
      { "nvzone/menu", lazy = false }, -- Ensure menu system loads first
    },
    config = function()
      require("claudecode").setup({
        diff_opts = {
          open_in_new_tab = true,
        },
      })

      -- Enhanced keybindings
      vim.keymap.set("n", "<leader>cc", "<cmd>ClaudeCode<CR>", { desc = "Toggle Claude Code" })
      vim.keymap.set("n", "<leader>cf", "<cmd>ClaudeCodeFocus<CR>", { desc = "Focus Claude Code" })
      vim.keymap.set("n", "<leader>cm", "<cmd>ClaudeCodeSelectModel<CR>", { desc = "Select Claude Model" })

      -- Visual mode: send selection
      vim.keymap.set("v", "<leader>cs", "<cmd>ClaudeCodeSend<CR>", { desc = "Send Selection to Claude" })
      vim.keymap.set("v", "<leader>cc", "<cmd>ClaudeCodeSend<CR>", { desc = "Send Selection to Claude" })

      -- Diff management
      vim.keymap.set("n", "<leader>cd", "<cmd>ClaudeCodeDiffAccept<CR>", { desc = "Accept Claude Diff" })
      vim.keymap.set("n", "<leader>cr", "<cmd>ClaudeCodeDiffDeny<CR>", { desc = "Deny Claude Diff" })
    end,
    keys = {
      { "<leader>cc", "<cmd>ClaudeCode<CR>", desc = "Toggle Claude Code" },
      { "<leader>cf", "<cmd>ClaudeCodeFocus<CR>", desc = "Focus Claude Code" },
      { "<leader>cm", "<cmd>ClaudeCodeSelectModel<CR>", desc = "Select Claude Model" },
      { "<leader>cd", "<cmd>ClaudeCodeDiffAccept<CR>", desc = "Accept Claude Diff" },
      { "<leader>cr", "<cmd>ClaudeCodeDiffDeny<CR>", desc = "Deny Claude Diff" },
    },
  },
}
