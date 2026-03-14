return {
  -- Auto pairs
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({})
      -- nvim-cmp integration disabled; blink.cmp has built-in bracket handling
    end,
  },

  -- Copilot moved to lua/plugins/ai.lua

  -- REPL integration
  {
    "jpalardy/vim-slime",
    ft = { "python", "r", "julia", "bash" },
    config = function()
      vim.g.slime_target = "tmux"
      vim.g.slime_paste_file = vim.fn.expand("$HOME/.slime_paste")
      vim.g.slime_default_config = { socket_name = "default", target_pane = "{last}" }
    end,
  },

  -- Modern formatting and linting with conform.nvim
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>f",
        function()
          require("conform").format({ async = true, lsp_fallback = true })
        end,
        mode = "",
        desc = "Format buffer",
      },
    },
    opts = {
      formatters_by_ft = {
        -- Python: ruff for both formatting and linting
        python = { "ruff_format", "ruff_organize_imports" },
        -- Web development
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        html = { "prettier" },
        css = { "prettier" },
        scss = { "prettier" },
        json = { "prettier" },
        jsonc = { "prettier" },
        yaml = { "prettier" },
        markdown = { "rumdl" },
        -- Other languages
        lua = { "stylua" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        r = { "styler" },
      },
      format_on_save = function(bufnr)
        -- Disable format on save for specific filetypes
        local disable_filetypes = { c = true, cpp = true }
        return {
          timeout_ms = 500,
          lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
        }
      end,
      formatters = {
        -- Custom ruff configuration for Python
        ruff_format = {
          command = "ruff",
          args = { "format", "--stdin-filename", "$FILENAME", "-" },
          stdin = true,
        },
        ruff_organize_imports = {
          command = "ruff",
          args = { "check", "--select", "I", "--fix", "--stdin-filename", "$FILENAME", "-" },
          stdin = true,
        },
        -- Prettier (using system installation)
        prettier = {
          command = "prettier",
          args = { "--stdin-filepath", "$FILENAME" },
          stdin = true,
        },
        -- rumdl for markdown formatting
        rumdl = {
          command = "rumdl",
          args = { "fmt", "-" },
          stdin = true,
        },
        -- Stylua with 2-space indentation
        stylua = {
          command = "stylua",
          args = { "--indent-type", "Spaces", "--indent-width", "2", "--stdin-filepath", "$FILENAME", "-" },
          stdin = true,
        },
      },
    },
  },

  -- Markdown preview
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = "cd app && yarn install",
    config = function()
      vim.g.mkdp_auto_start = 0
      vim.g.mkdp_auto_close = 1
    end,
  },
}
