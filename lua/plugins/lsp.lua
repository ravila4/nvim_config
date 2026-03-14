return {
  -- Enhanced diagnostic display with virtual lines
  {
    "https://git.sr.ht/~whynothugo/lsp_lines.nvim",
    event = "LspAttach",
    config = function()
      require("lsp_lines").setup()
      -- Toggle between virtual lines and virtual text
      vim.keymap.set("n", "<Leader>ld", require("lsp_lines").toggle, { desc = "Toggle lsp_lines" })
    end,
  },

  -- Navigation breadcrumbs
  {
    "SmiteshP/nvim-navic",
    event = "LspAttach",
    config = function()
      require("nvim-navic").setup({
        icons = {
          File = " ",
          Module = " ",
          Namespace = " ",
          Package = " ",
          Class = " ",
          Method = " ",
          Property = " ",
          Field = " ",
          Constructor = " ",
          Enum = " ",
          Interface = " ",
          Function = " ",
          Variable = " ",
          Constant = " ",
          String = " ",
          Number = " ",
          Boolean = " ",
          Array = " ",
          Object = " ",
          Key = " ",
          Null = " ",
          EnumMember = " ",
          Struct = " ",
          Event = " ",
          Operator = " ",
          TypeParameter = " ",
        },
        lsp = {
          auto_attach = true,
          preference = { "r_language_server", "pyright", "otter-ls" },
        },
        highlight = true,
        separator = " > ",
        depth_limit = 0,
        depth_limit_indicator = "..",
        safe_output = true,
        lazy_update_context = false,
        click = false,
        format_text = function(text)
          return text
        end,
      })

      -- Set up highlight groups with your teal theme (solid backgrounds)
      local function setup_navic_highlights()
        local is_dark = vim.o.background == "dark"
        local bg_color = is_dark and "#1c1c1c" or "#ffffff"

        vim.api.nvim_set_hl(0, "NavicText", {
          fg = is_dark and "#cccccc" or "#2e3436",
          bg = bg_color,
        })
        vim.api.nvim_set_hl(0, "NavicSeparator", {
          fg = "#228787",
          bg = bg_color,
        })

        vim.api.nvim_set_hl(0, "WinBar", { bg = bg_color })
        vim.api.nvim_set_hl(0, "WinBarNC", { bg = bg_color })

        local icon_types = {
          "File", "Module", "Namespace", "Package", "Class", "Method",
          "Property", "Field", "Constructor", "Enum", "Interface", "Function",
          "Variable", "Constant", "String", "Number", "Boolean", "Array",
          "Object", "Key", "Null", "EnumMember", "Struct", "Event",
          "Operator", "TypeParameter",
        }

        for _, icon_type in ipairs(icon_types) do
          local hl_group = "NavicIcons" .. icon_type
          local existing_hl = vim.api.nvim_get_hl(0, { name = hl_group })
          vim.api.nvim_set_hl(0, hl_group, vim.tbl_extend("force", existing_hl, { bg = bg_color }))
        end
      end

      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = setup_navic_highlights,
      })

      setup_navic_highlights()
    end,
  },

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      -- Build capabilities (blink.cmp > cmp-nvim-lsp > defaults)
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok_blink, blink = pcall(require, "blink.cmp")
      if ok_blink and blink and blink.get_lsp_capabilities then
        capabilities = blink.get_lsp_capabilities(capabilities)
      else
        local ok_cmp, cmp_cap = pcall(require, "cmp_nvim_lsp")
        if ok_cmp and cmp_cap and cmp_cap.default_capabilities then
          capabilities = cmp_cap.default_capabilities(capabilities)
        end
      end

      -- Shared capabilities for all servers
      vim.lsp.config("*", {
        capabilities = capabilities,
      })

      -- Python: Pyright for types + LSP features
      vim.lsp.config("pyright", {
        settings = {
          python = {
            analysis = {
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              typeCheckingMode = "basic",
              extraPaths = vim.tbl_flatten({
                vim.fn.glob(vim.fn.expand("~/.local/share/uv/python/*/lib/python*/site-packages"), true, true),
                vim.env.CONDA_PREFIX
                    and vim.fn.glob(vim.fn.expand(vim.env.CONDA_PREFIX .. "/lib/python*/site-packages"), true, true)
                  or {},
                vim.env.VIRTUAL_ENV
                    and vim.fn.glob(vim.fn.expand(vim.env.VIRTUAL_ENV .. "/lib/python*/site-packages"), true, true)
                  or {},
              }),
            },
          },
        },
        on_attach = function(client, _bufnr)
          -- Disable pyright's formatting since we use ruff via conform
          client.server_capabilities.documentFormattingProvider = false
          client.server_capabilities.documentRangeFormattingProvider = false
        end,
      })

      -- Python: Ruff for fast linting
      vim.lsp.config("ruff", {
        cmd = { vim.fn.expand("~/.local/share/nvim/mason/packages/ruff/venv/bin/ruff"), "server" },
        on_attach = function(client, _bufnr)
          -- Disable hover in favor of pyright's more detailed hover
          client.server_capabilities.hoverProvider = false
        end,
      })

      -- R Language Server
      vim.lsp.config("r_language_server", {
        settings = {
          r = {
            linting = {
              enable = true,
              delay = 500,
              options = { linters = "default", exclude = {} },
            },
            diagnostics = {
              enable = true,
              delay = 500,
              options = { diagnostics = "default", exclude = {} },
            },
            formatting = { enable = true },
          },
        },
      })

      vim.lsp.enable({ "pyright", "ruff", "r_language_server" })

      -- Diagnostics config (consolidated)
      vim.diagnostic.config({
        virtual_text = false, -- using lsp_lines instead
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = "E",
            [vim.diagnostic.severity.WARN] = "W",
            [vim.diagnostic.severity.INFO] = "I",
            [vim.diagnostic.severity.HINT] = "H",
          },
        },
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = {
          border = "rounded",
          source = "always",
          header = "",
          prefix = "",
        },
      })

      -- Consolidated LspAttach: keymaps + navic winbar
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local bufnr = args.buf
          local client = vim.lsp.get_client_by_id(args.data.client_id)

          -- Navic winbar (navic auto_attach handles the attach call)
          local ok_navic, navic = pcall(require, "nvim-navic")
          if ok_navic and client and client.server_capabilities.documentSymbolProvider then
            local function update_winbar()
              vim.schedule(function()
                if navic.is_available(bufnr) then
                  local location = navic.get_location()
                  local filepath = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":~:.")
                  if location and location ~= "" then
                    vim.wo.winbar =
                      string.format("%%#NavicText# %s %%#NavicSeparator#>%%#NavicText# %s", filepath, location)
                  else
                    vim.wo.winbar = string.format("%%#NavicText# %s", filepath)
                  end
                end
              end)
            end

            update_winbar()
            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorHold" }, {
              buffer = bufnr,
              callback = update_winbar,
            })
          end

          -- LSP keymaps
          vim.keymap.set("n", "K", function()
            vim.lsp.buf.hover({ border = "rounded", focusable = false })
          end, { desc = "LSP Hover", buffer = bufnr })

          vim.keymap.set("n", "<leader>df", function()
            vim.diagnostic.open_float({ border = "rounded", focusable = true })
          end, { desc = "Show diagnostic details", buffer = bufnr })

          vim.keymap.set("n", "]d", function()
            vim.diagnostic.goto_next()
          end, { desc = "Next diagnostic", buffer = bufnr })

          vim.keymap.set("n", "[d", function()
            vim.diagnostic.goto_prev()
          end, { desc = "Previous diagnostic", buffer = bufnr })

          vim.keymap.set("n", "]e", function()
            vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })
          end, { desc = "Next error", buffer = bufnr })

          vim.keymap.set("n", "[e", function()
            vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })
          end, { desc = "Previous error", buffer = bufnr })
        end,
      })
    end,
  },
}
