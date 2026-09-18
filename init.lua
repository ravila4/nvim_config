-- Configuration file for Neovim
-- =============================

-- Basic vim settings
require("config.settings")

-- Dependency installation is explicit: run make setup from this checkout.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
	vim.notify("Neovim dependencies are missing. Run make setup in the configuration checkout.", vim.log.levels.WARN)
	return
end
vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim
require("lazy").setup("plugins", {
	install = { missing = false },
	defaults = {
		lazy = true, -- Enable lazy loading by default
	},
	checker = {
		enabled = true, -- Enable automatic updates
		notify = false, -- Don't notify about updates
	},
	performance = {
		rtp = {
			disabled_plugins = {
				"gzip",
				"matchit",
				"matchparen",
				"netrwPlugin",
				"tarPlugin",
				"tohtml",
				"tutor",
				"zipPlugin",
			},
		},
	},
})

-- Load keymaps and abbreviations
require("config.keymaps")
require("config.abbreviations")
require("config.theme_sync")
