return {
  {
    "saghen/blink.cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = { "L3MON4D3/LuaSnip" },
    version = "*",
    opts = {
      enabled = function()
        local bt = vim.bo.buftype
        if bt == 'prompt' or bt == 'nofile' then return false end
        local ft = vim.bo.filetype
        if ft == 'neo-tree' or ft == 'neo-tree-popup' or ft == 'TelescopePrompt' or ft == 'snacks_dashboard' then
          return false
        end
        return true
      end,
      keymap = {
        preset = "default",
        ['<Tab>'] = { 'select_next', 'fallback' },
        ['<S-Tab>'] = { 'select_prev', 'fallback' },
        ['<CR>'] = { 'fallback' },
        ['<C-y>'] = { 'accept', 'fallback' },
      },
      appearance = {
        nerd_font_variant = "normal",
        kind_icons = {
          Text = "", Method = "", Function = "", Constructor = "",
          Field = "ﰠ", Variable = "", Class = "", Interface = "",
          Module = "", Property = "", Unit = "塞", Value = "",
          Enum = "", Keyword = "", Snippet = "", Color = "",
          File = "", Reference = "", Folder = "", EnumMember = "",
          Constant = "", Struct = "פּ", Event = "", Operator = "",
          TypeParameter = "",
        },
      },
      completion = {
        keyword = { range = "full" },
        menu = { border = "rounded" },
        documentation = { window = { border = "rounded" } },
        list = {
            selection = {
                preselect =  false,
                auto_insert = true,
            },
        },
        trigger = { show_on_insert = true },
      },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
        per_filetype = {
          ['neo-tree'] = {},
          ['neo-tree-popup'] = {},
          TelescopePrompt = {},
          snacks_dashboard = {},
        }
      },
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
        local menu_bg = is_dark and '#2d2d30' or '#f1f0ef'   -- uniform light gray in light mode
        local sel_bg = '#228787'                              -- brand teal
        local sel_fg = '#ffffff'
        vim.api.nvim_set_hl(0, 'BlinkCmpBorder', { fg = border, bg = 'NONE' })
        vim.api.nvim_set_hl(0, 'BlinkCmpMenu', { bg = menu_bg, fg = is_dark and '#cccccc' or '#2e3436' })
        vim.api.nvim_set_hl(0, 'BlinkCmpMenuSelection', { bg = sel_bg, fg = sel_fg })
      end
      set_blink_hl()
      vim.api.nvim_create_autocmd('ColorScheme', { callback = set_blink_hl })

      vim.g.blink_cmp_enable_auto_brackets = true
    end,
  },
}
