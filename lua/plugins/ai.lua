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
          accept = "<M-l>",
          accept_word = "<M-w>",
          accept_line = "<M-;>",
          next = "<M-]>",
          prev = "<M-[>",
          dismiss = "<C-]>",
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
