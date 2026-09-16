-- Basic Neovim Settings
-- =====================

-- Set leader key to space (more comfortable than backslash)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Stable Python provider for molten-nvim remote plugins
vim.g.python3_host_prog = vim.fn.stdpath("data") .. "/python-host/bin/python"

local opt = vim.opt

-- Line Numbers
opt.number = true
-- opt.relativenumber = true

-- Highlight current line
opt.cursorline = false

-- Tabbing
opt.tabstop = 8
opt.softtabstop = 0
opt.expandtab = true
opt.shiftwidth = 4
opt.smarttab = true

-- Search
opt.incsearch = true
opt.hlsearch = true
opt.ignorecase = true
opt.smartcase = true

-- Text wrapping
opt.wrap = true -- Enable line wrapping by default
opt.linebreak = true -- When wrapping is enabled, break at word boundaries
opt.showbreak = "↳ " -- Visual indicator for wrapped lines

-- Enable line wrapping for prose filetypes
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "markdown", "quarto", "rmd" },
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.linebreak = true
		-- Markview supplies continuation borders and indentation for wrapped prose.
		vim.opt_local.showbreak = "NONE"
	end,
})

-- Misc
opt.encoding = "utf8"
opt.scrolloff = 4
opt.wildmenu = true
opt.wildmode = "list"
opt.mouse = "a"

-- Leader key timeout (default is 1000ms)
opt.timeoutlen = 800 -- Slightly shorter than default for better responsiveness

-- GUI settings
opt.mousehide = false
opt.mousemodel = "popup"
opt.guioptions:remove("T") -- Remove toolbar
opt.guioptions:remove("r") -- Remove right scrollbar
opt.guioptions:remove("L") -- Remove left scrollbar

-- Code Folding
opt.foldmethod = "indent"
opt.foldlevel = 99

-- Conceal level for markdown
opt.conceallevel = 2

-- Clipboard (unnamedplus works on both macOS and Linux)
opt.clipboard = "unnamedplus"

-- Completion
opt.completeopt = { "menuone", "noinsert", "noselect" }
opt.shortmess:append("c")

-- Enable 24-bit colors
opt.termguicolors = true

require("config.trailing_spaces").setup()

-- [No Name] and directory buffers are hidden from bufferline via custom_filter in plugins/ui.lua
