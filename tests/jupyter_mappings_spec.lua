describe("Molten mapping scope", function()
	local buffers = {}
	for _, spec in ipairs(require("plugins.jupyter")) do
		if spec[1] == "ravila4/molten-nvim" then
			spec.config()
		end
	end
	vim.g.mapleader = " "
	vim.keymap.set("n", "<leader>ms", "<cmd>Markview splitToggle<cr>", { desc = "Markview split view" })
	after_each(function()
		for _, buf in ipairs(buffers) do
			vim.api.nvim_buf_delete(buf, { force = true })
		end
		buffers = {}
	end)

	local function open(path, ft)
		local buf = vim.api.nvim_create_buf(true, false)
		table.insert(buffers, buf)
		vim.api.nvim_set_current_buf(buf)
		vim.api.nvim_buf_set_name(buf, path)
		vim.bo[buf].filetype = ft
		vim.api.nvim_exec_autocmds("FileType", { buffer = buf })
	end

	it("preserves Markview split view in ordinary Markdown", function()
		open("/tmp/README.md", "markdown")
		assert.equal("Markview split view", vim.fn.maparg(" ms", "n", false, true).desc)
		assert.equal("", vim.fn.maparg(" jr", "n"))
	end)

	it("keeps document image shortcuts in ordinary Markdown", function()
		open("/tmp/README.md", "markdown")
		assert.equal("Open image", vim.fn.maparg(" mi", "n", false, true).desc)
		assert.equal("Copy image to clipboard", vim.fn.maparg(" my", "n", false, true).desc)
	end)

	for _, case in ipairs({
		{ "notebook.ipynb", "markdown" },
		{ "analysis.qmd", "quarto" },
		{ "analysis.Rmd", "rmd" },
		{ "analysis.py", "python" },
		{ "analysis.jl", "julia" },
		{ "analysis.R", "r" },
	}) do
		it("keeps execution shortcuts in " .. case[1], function()
			open("/tmp/" .. case[1], case[2])
			assert.equal("[Molten] Show output", vim.fn.maparg(" ms", "n", false, true).desc)
			assert.equal("[Unified] Run cell (smart)", vim.fn.maparg(" jr", "n", false, true).desc)
		end)
	end
end)
