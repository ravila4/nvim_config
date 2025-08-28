-- GitHub Copilot integration for AI-powered code suggestions
return {
  -- GitHub Copilot (inline AI suggestions) without stealing Tab/Enter
  {
    "zbirenbaum/copilot.lua",
    event = "InsertEnter",
    opts = {
      suggestion = {
        enabled = true,
        auto_trigger = true,
        debounce = 75,
        keymap = {
          accept = "<C-l>",
          accept_word = "<C-j>",
          next = "<C-n>",
          prev = "<C-p>",
          dismiss = "<C-e>",
        },
      },
      panel = { enabled = false },
      filetypes = {
        ["*"] = true,
      },
    },
    config = function(_, opts)
      require("copilot").setup(opts)
      local function set_copilot_hl()
        local is_dark = vim.o.background == "dark"
        vim.api.nvim_set_hl(0, "CopilotSuggestion", { fg = is_dark and "#858585" or "#9a9996", italic = true })
      end
      set_copilot_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = set_copilot_hl })
    end,
  },
}