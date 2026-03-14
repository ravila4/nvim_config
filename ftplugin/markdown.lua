-- Activate quarto for markdown files to enable code block execution
require("quarto").activate()

-- Activate otter for syntax highlighting and LSP features in code blocks
require("otter").activate()

-- Line wrapping for prose
vim.opt_local.wrap = true
vim.opt_local.linebreak = true