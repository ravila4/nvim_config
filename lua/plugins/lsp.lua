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
          File = ' ',
          Module = ' ',
          Namespace = ' ',
          Package = ' ',
          Class = ' ',
          Method = ' ',
          Property = ' ',
          Field = ' ',
          Constructor = ' ',
          Enum = ' ',
          Interface = ' ',
          Function = ' ',
          Variable = ' ',
          Constant = ' ',
          String = ' ',
          Number = ' ',
          Boolean = ' ',
          Array = ' ',
          Object = ' ',
          Key = ' ',
          Null = ' ',
          EnumMember = ' ',
          Struct = ' ',
          Event = ' ',
          Operator = ' ',
          TypeParameter = ' '
        },
        lsp = {
          auto_attach = true,
          preference = { "r_language_server", "pyright", "otter-ls" }, -- Prefer r_language_server for R, pyright for Python
        },
        highlight = true, -- Use LSP semantic tokens for syntax highlighting
        separator = " > ", -- Breadcrumb separator
        depth_limit = 0, -- No limit on breadcrumb depth
        depth_limit_indicator = "..", -- Indicator when depth is exceeded
        safe_output = true, -- Sanitize output
        lazy_update_context = false,
        click = false, -- Disable clicking
        format_text = function(text)
          return text -- Keep original text formatting
        end,
      })

      -- Set up highlight groups with your teal theme (solid backgrounds)
      local function setup_navic_highlights()
        local is_dark = vim.o.background == "dark"
        local bg_color = is_dark and "#1c1c1c" or "#ffffff"

        vim.api.nvim_set_hl(0, "NavicText", {
          fg = is_dark and "#cccccc" or "#2e3436",
          bg = bg_color
        })
        vim.api.nvim_set_hl(0, "NavicSeparator", {
          fg = "#228787",
          bg = bg_color
        })

        -- Set winbar background to match
        vim.api.nvim_set_hl(0, "WinBar", {
          bg = bg_color
        })
        vim.api.nvim_set_hl(0, "WinBarNC", {
          bg = bg_color
        })

        -- Set background for all NavicIcons* highlight groups
        local icon_types = {
          "File", "Module", "Namespace", "Package", "Class", "Method",
          "Property", "Field", "Constructor", "Enum", "Interface",
          "Function", "Variable", "Constant", "String", "Number",
          "Boolean", "Array", "Object", "Key", "Null", "EnumMember",
          "Struct", "Event", "Operator", "TypeParameter"
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

      -- Set initial highlight groups
      setup_navic_highlights()
    end,
  },

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      -- use blink.cmp to advertise capabilities instead of cmp-nvim-lsp
    },
    config = function()
      local lspconfig = require("lspconfig")
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      -- Prefer blink.cmp capabilities; fallback to cmp-nvim-lsp if present; otherwise defaults
      local ok_blink, blink = pcall(require, 'blink.cmp')
      if ok_blink and blink and blink.get_lsp_capabilities then
        capabilities = blink.get_lsp_capabilities(capabilities)
      else
        local ok_cmp, cmp_cap = pcall(require, 'cmp_nvim_lsp')
        if ok_cmp and cmp_cap and cmp_cap.default_capabilities then
          capabilities = cmp_cap.default_capabilities(capabilities)
        end
      end

      -- Python LSP: Pyright for types + LSP features
      lspconfig.pyright.setup({
        capabilities = capabilities,
        settings = {
          python = {
            analysis = {
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              typeCheckingMode = "basic", -- basic, strict, or off
              -- Auto-detect virtual environments (uv, conda, venv)
              extraPaths = vim.tbl_flatten({
                -- uv environments
                vim.fn.glob(vim.fn.expand("~/.local/share/uv/python/*/lib/python*/site-packages"), true, true),
                -- conda environments
                vim.env.CONDA_PREFIX and vim.fn.glob(vim.fn.expand(vim.env.CONDA_PREFIX .. "/lib/python*/site-packages"), true, true) or {},
                -- standard virtual environments
                vim.env.VIRTUAL_ENV and vim.fn.glob(vim.fn.expand(vim.env.VIRTUAL_ENV .. "/lib/python*/site-packages"), true, true) or {},
              }),
            },
          },
        },
        on_attach = function(client, bufnr)
          -- Disable pyright's formatting since we use ruff via conform
          client.server_capabilities.documentFormattingProvider = false
          client.server_capabilities.documentRangeFormattingProvider = false

          -- Attach navic if available
          local ok_navic, navic = pcall(require, "nvim-navic")
          if ok_navic and client.server_capabilities.documentSymbolProvider then
            navic.attach(client, bufnr)

            -- Set up winbar for this buffer
            local function update_winbar()
              vim.schedule(function()
                if navic.is_available(bufnr) then
                  local location = navic.get_location()
                  local filepath = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":~:.")
                  if location and location ~= "" then
                    vim.wo.winbar = string.format("%%#NavicText# %s %%#NavicSeparator#>%%#NavicText# %s", filepath, location)
                  else
                    vim.wo.winbar = string.format("%%#NavicText# %s", filepath)
                  end
                end
              end)
            end

            -- Update immediately and on cursor movement
            update_winbar()
            vim.api.nvim_create_autocmd({"CursorMoved", "CursorHold"}, {
              buffer = bufnr,
              callback = update_winbar,
            })
          end
        end,
      })

      -- Python Linting: Ruff LSP for fast linting
      lspconfig.ruff.setup({
        capabilities = capabilities,
        cmd = { vim.fn.expand("~/.local/share/nvim/mason/packages/ruff/venv/bin/ruff"), "server" },
        on_attach = function(client, bufnr)
          -- Disable hover in favor of pyright's more detailed hover
          client.server_capabilities.hoverProvider = false

          -- Attach navic if available (but ruff doesn't provide document symbols)
          local ok_navic, navic = pcall(require, "nvim-navic")
          if ok_navic and client.server_capabilities.documentSymbolProvider then
            navic.attach(client, bufnr)
          end
        end,
      })

      -- R Language Server
      lspconfig.r_language_server.setup({
        capabilities = capabilities,
        settings = {
          r = {
            linting = {
              enable = true,
              delay = 500,
              options = {
                linters = "default",
                exclude = {},
              },
            },
            diagnostics = {
              enable = true,
              delay = 500,
              options = {
                diagnostics = "default",
                exclude = {},
              },
            },
            formatting = {
              enable = true,
            },
          },
        },
        on_attach = function(client, bufnr)
          -- Attach navic if available
          local ok_navic, navic = pcall(require, "nvim-navic")
          if ok_navic and client.server_capabilities.documentSymbolProvider then
            navic.attach(client, bufnr)

            -- Set up winbar for this buffer
            local function update_winbar()
              vim.schedule(function()
                if navic.is_available(bufnr) then
                  local location = navic.get_location()
                  local filepath = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":~:.")
                  if location and location ~= "" then
                    vim.wo.winbar = string.format("%%#NavicText# %s %%#NavicSeparator#>%%#NavicText# %s", filepath, location)
                  else
                    vim.wo.winbar = string.format("%%#NavicText# %s", filepath)
                  end
                end
              end)
            end

            -- Update immediately and on cursor movement
            update_winbar()
            vim.api.nvim_create_autocmd({"CursorMoved", "CursorHold"}, {
              buffer = bufnr,
              callback = update_winbar,
            })
          end
        end,
      })

      -- Configure diagnostics to work well with lsp_lines
      vim.diagnostic.config({
        -- Disable virtual_text since we're using lsp_lines
        virtual_text = false,
        -- Keep other diagnostic features
        signs = true,
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

      -- LSP and diagnostic keymaps
      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(args)
          local bufnr = args.buf

          -- LSP hover
          vim.keymap.set('n', 'K', function()
            vim.lsp.buf.hover({ border = 'rounded', focusable = false })
          end, { desc = 'LSP Hover', buffer = bufnr })

          -- Diagnostic navigation and details
          vim.keymap.set('n', '<leader>df', function()
            vim.diagnostic.open_float({ border = 'rounded', focusable = true })
          end, { desc = 'Show diagnostic details', buffer = bufnr })

          vim.keymap.set('n', ']d', function()
            vim.diagnostic.goto_next()
          end, { desc = 'Next diagnostic', buffer = bufnr })

          vim.keymap.set('n', '[d', function()
            vim.diagnostic.goto_prev()
          end, { desc = 'Previous diagnostic', buffer = bufnr })

          vim.keymap.set('n', ']e', function()
            vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })
          end, { desc = 'Next error', buffer = bufnr })

          vim.keymap.set('n', '[e', function()
            vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })
          end, { desc = 'Previous error', buffer = bufnr })
        end,
      })

      -- Auto-command for Python LSP
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "python",
        callback = function()
          -- Additional Python-specific LSP setup can go here
        end,
      })
    end,
  },

  vim.diagnostic.config({
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = 'E',
        [vim.diagnostic.severity.WARN] =  'W',
        [vim.diagnostic.severity.INFO] = 'I',
        [vim.diagnostic.severity.HINT] = 'H',
      },
    }
  })

}
