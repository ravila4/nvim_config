return {
  {
    "https://git.sr.ht/~whynothugo/lsp_lines.nvim",
    event = "LspAttach",
    config = function()
      require("lsp_lines").setup()
      vim.keymap.set("n", "<Leader>ld", require("lsp_lines").toggle, { desc = "Toggle lsp_lines" })
    end,
  },

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

        vim.api.nvim_set_hl(0, "WinBar", {
          bg = bg_color,
        })
        vim.api.nvim_set_hl(0, "WinBarNC", {
          bg = bg_color,
        })

        local icon_types = {
          "File",
          "Module",
          "Namespace",
          "Package",
          "Class",
          "Method",
          "Property",
          "Field",
          "Constructor",
          "Enum",
          "Interface",
          "Function",
          "Variable",
          "Constant",
          "String",
          "Number",
          "Boolean",
          "Array",
          "Object",
          "Key",
          "Null",
          "EnumMember",
          "Struct",
          "Event",
          "Operator",
          "TypeParameter",
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

      local function setup_winbar(client, bufnr)
        local ok_navic, navic = pcall(require, "nvim-navic")
        if ok_navic and client.server_capabilities.documentSymbolProvider then
          navic.attach(client, bufnr)

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
      end

      vim.lsp.config("*", {
        capabilities = capabilities,
      })

      vim.lsp.config.pyright = {
        cmd = { "pyright-langserver", "--stdio" },
        filetypes = { "python" },
        root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "Pipfile", ".git" },
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
        on_attach = function(client, bufnr)
          client.server_capabilities.documentFormattingProvider = false
          client.server_capabilities.documentRangeFormattingProvider = false
          setup_winbar(client, bufnr)
        end,
      }

      vim.lsp.config.ruff = {
        cmd = { vim.fn.expand("~/.local/share/nvim/mason/packages/ruff/venv/bin/ruff"), "server" },
        filetypes = { "python" },
        root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" },
        on_attach = function(client, bufnr)
          client.server_capabilities.hoverProvider = false
        end,
      }

      vim.lsp.config.r_language_server = {
        cmd = { "R", "--slave", "-e", "languageserver::run()" },
        filetypes = { "r", "rmd" },
        root_markers = { ".git", "DESCRIPTION" },
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
          setup_winbar(client, bufnr)
        end,
      }

      vim.lsp.config.copilot = {
        cmd = { "copilot-language-server", "--stdio" },
        filetypes = { "*" },
        single_file_support = true,
      }

      vim.lsp.enable("pyright")
      vim.lsp.enable("ruff")
      vim.lsp.enable("r_language_server")
      vim.lsp.enable("copilot")

      vim.diagnostic.config({
        virtual_text = false,
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

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local bufnr = args.buf

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

  vim.diagnostic.config({
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = "E",
        [vim.diagnostic.severity.WARN] = "W",
        [vim.diagnostic.severity.INFO] = "I",
        [vim.diagnostic.severity.HINT] = "H",
      },
    },
  }),
}
