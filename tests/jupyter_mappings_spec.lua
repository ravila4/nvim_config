describe("Molten mapping scope", function()
	local buffers = {}
	local prompt = package.loaded.prompt
	package.loaded.prompt = {}
	for _, spec in ipairs(require("plugins.jupyter")) do
		if spec[1] == "ravila4/molten-nvim" then
			spec.config()
		end
	end
	package.loaded.prompt = prompt
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

	it("jumps to a numbered notebook cell", function()
		open("/tmp/notebook.ipynb", "markdown")
		vim.api.nvim_buf_set_lines(0, 0, -1, false, {
			"# First",
			"```python",
			"a = 1",
			"```",
			"# Second",
			"```python",
			"b = 2",
			"```",
		})
		local input = vim.ui.input
		vim.ui.input = function(_, callback)
			callback("2")
		end
		vim.fn.maparg(" jg", "n", false, true).callback()
		vim.ui.input = input
		assert.equal(6, vim.api.nvim_win_get_cursor(0)[1])
	end)

	it("reports a notebook cell number that does not exist", function()
		open("/tmp/notebook.ipynb", "markdown")
		vim.api.nvim_buf_set_lines(0, 0, -1, false, { "```python", "a = 1", "```" })
		local input, notify = vim.ui.input, vim.notify
		local message
		vim.ui.input = function(_, callback)
			callback("5")
		end
		vim.notify = function(value)
			message = value
		end
		vim.fn.maparg(" jg", "n", false, true).callback()
		vim.ui.input, vim.notify = input, notify
		assert.equal("Cell 5 does not exist; this document has 1 cell", message)
	end)

	it("does not map numbered outline navigation in percent-cell scripts", function()
		open("/tmp/analysis.py", "python")
		assert.equal("", vim.fn.maparg(" jg", "n"))
	end)

	for _, case in ipairs({
		{ "notebook.ipynb", "markdown" },
		{ "analysis.qmd", "quarto" },
		{ "analysis.Rmd", "rmd" },
		{ "analysis.py", "python" },
		{ "analysis.jl", "julia" },
	}) do
		it("keeps execution shortcuts in " .. case[1], function()
			open("/tmp/" .. case[1], case[2])
			assert.equal("[Molten] Show output", vim.fn.maparg(" ms", "n", false, true).desc)
			assert.equal("[Unified] Run cell (smart)", vim.fn.maparg(" jr", "n", false, true).desc)
		end)
	end

	it("leaves R script execution to R.nvim", function()
		open("/tmp/analysis.R", "r")
		assert.equal("", vim.fn.maparg(" jr", "n"))
		assert.equal("", vim.fn.maparg("<C-CR>", "n"))
	end)
end)
