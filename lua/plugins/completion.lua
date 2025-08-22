return {
  {
    "hrsh7th/nvim-cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local ok, cmp = pcall(require, "cmp")
      if not ok then return end

      local has_luasnip, luasnip = pcall(require, "luasnip")

      local function set_cmp_hl()
        local is_dark = vim.o.background == "dark"
        if is_dark then
          vim.api.nvim_set_hl(0, "Pmenu", { bg = "#2d2d30", fg = "#cccccc" })
          vim.api.nvim_set_hl(0, "PmenuSel", { bg = "#37373d", fg = "#ffffff" })
          vim.api.nvim_set_hl(0, "CmpBorder", { fg = "#569cd6", bg = "NONE" })
          vim.api.nvim_set_hl(0, "FloatBorder", { fg = "#569cd6", bg = "NONE" })
          vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#2d2d30" })
        else
          vim.api.nvim_set_hl(0, "Pmenu", { bg = "#ffffff", fg = "#2e3436" })
          vim.api.nvim_set_hl(0, "PmenuSel", { bg = "#f1f0ef", fg = "#2e3436" })
          vim.api.nvim_set_hl(0, "CmpBorder", { fg = "#1c71d8", bg = "NONE" })
          vim.api.nvim_set_hl(0, "FloatBorder", { fg = "#1c71d8", bg = "NONE" })
          vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#ffffff" })
        end
      end

      set_cmp_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = set_cmp_hl })

      cmp.setup({
        snippet = {
          expand = function(args)
            if has_luasnip then luasnip.lsp_expand(args.body) end
          end,
        },
        window = {
          completion = cmp.config.window.bordered({
            border = "rounded",
            winhighlight = "Normal:Pmenu,FloatBorder:CmpBorder,CursorLine:PmenuSel,Search:None",
          }),
          documentation = cmp.config.window.bordered({
            border = "rounded",
            winhighlight = "Normal:NormalFloat,FloatBorder:CmpBorder,Search:None",
          }),
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
          ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<C-e>"] = cmp.mapping.abort(),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "path" },
        }, {
          { name = "buffer" },
        }),
        formatting = {
          fields = { "abbr", "menu" },
        },
      })
    end,
  },
}
