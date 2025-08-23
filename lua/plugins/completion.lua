return {
  {
    "hrsh7th/nvim-cmp",
    enabled = false,
  },

  {
    "hrsh7th/cmp-nvim-lsp",
    enabled = false,
  },

  {
    "saghen/blink.cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = { "L3MON4D3/LuaSnip" },
    version = "*",
    opts = {
      keymap = {
        preset = "default",
        ['<CR>'] = { 'accept', 'fallback' },
        ['<C-e>'] = { 'hide', 'fallback' },
      },
      appearance = {
        use_nvim_cmp_as_default = false,
        nerd_font_variant = "normal",
        kind_icons = true,
      },
      completion = {
        keyword = { range = "full" },
        menu = { border = "rounded" },
        documentation = { window = { border = "rounded" } },
        list = { selection = { auto_insert = false }, max_height = 15 },
        trigger = { show_on_insert = true },
      },
      sources = { default = { 'lsp', 'path', 'snippets', 'buffer' } },
      signature = { enabled = true },
      snippets = { preset = 'luasnip' },
      performance = { filter_on_keystroke = true, debounce = 0, throttle = 0 },
    },
    config = function(_, opts)
      local ok, blink = pcall(require, 'blink.cmp')
      if not ok then return end
      blink.setup(opts)

      local function set_blink_hl()
        local is_dark = vim.o.background == 'dark'
        local border = is_dark and '#404040' or '#d0d0d0'
        local sel_bg = is_dark and '#37373d' or '#f1f0ef'
        vim.api.nvim_set_hl(0, 'BlinkCmpBorder', { fg = border, bg = 'NONE' })
        vim.api.nvim_set_hl(0, 'BlinkCmpMenu', { bg = is_dark and '#2d2d30' or '#ffffff', fg = is_dark and '#cccccc' or '#2e3436' })
        vim.api.nvim_set_hl(0, 'BlinkCmpMenuSelection', { bg = sel_bg, fg = 'NONE' })
      end
      set_blink_hl()
      vim.api.nvim_create_autocmd('ColorScheme', { callback = set_blink_hl })

      vim.g.blink_cmp_enable_auto_brackets = true
    end,
  },
}
