return {
	{
		"echasnovski/mini.diff",
		lazy = false,
		config = function()
			require("mini.diff").setup({
				source = { require("config.notebook_diff").source(), require("mini.diff").gen_source.none() },
				view = { style = "sign", signs = { add = "┃", change = "┃", delete = "_" } },
			})
			require("config.quickedit").setup()
		end,
	},
}
