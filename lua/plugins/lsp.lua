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

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      local lspconfig = require("lspconfig")
      local cmp_nvim_lsp = require("cmp_nvim_lsp")

      -- Capabilities
      local capabilities = cmp_nvim_lsp.default_capabilities()

      -- Python LSP
      lspconfig.pyright.setup({
        capabilities = capabilities,
        settings = {
          python = {
            analysis = {
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              extraPaths = (vim.env.CONDA_PREFIX ~= nil or vim.env.VIRTUAL_ENV ~= nil)
                and vim.tbl_map(function(path)
                  return vim.fn.expand(path)
                end, vim.fn.glob(vim.fn.expand((vim.env.CONDA_PREFIX or vim.env.VIRTUAL_ENV) .. "/lib/python*/site-packages"), true, true))
                or {},
            },
          },
        },
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

      -- Auto-command for Python LSP
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "python",
        callback = function()
          -- Additional Python-specific LSP setup can go here
        end,
      })
    end,
  },
}