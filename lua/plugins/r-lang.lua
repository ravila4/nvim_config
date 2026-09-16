return {
	{
		"R-nvim/R.nvim",
		ft = { "r", "rhelp" },
		init = function()
			-- Filetype alone cannot distinguish scripts from Otter's hidden R buffers.
			vim.g.R_filetypes = {}
		end,
		config = function()
			local integration = require("config.r_integration")
			integration.setup(integration.read_config())
		end,
	},
}
