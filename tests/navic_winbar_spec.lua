describe("Navic winbar", function()
	local navic
	local winbar

	before_each(function()
		package.loaded["config.navic_winbar"] = nil
		navic = {
			is_available = function()
				return true
			end,
			get_location = function()
				return "DataProcessor > validate_batch"
			end,
		}
		package.loaded["nvim-navic"] = navic
		winbar = require("config.navic_winbar")
	end)

	after_each(function()
		vim.g.statusline_winid = nil
		package.loaded["nvim-navic"] = nil
		package.loaded["config.navic_winbar"] = nil
	end)

	it("renders the buffer belonging to the evaluated window", function()
		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_name(bufnr, "percent%file.py")
		vim.api.nvim_win_set_buf(0, bufnr)
		vim.g.statusline_winid = vim.api.nvim_get_current_win()

		local requested_bufnr
		navic.get_location = function(_, requested)
			requested_bufnr = requested
			return "DataProcessor > validate_batch"
		end

		assert.are.equal(
			"%#NavicText# percent%%file.py %#NavicSeparator#>%#NavicText# DataProcessor > validate_batch",
			winbar.render()
		)
		assert.are.equal(bufnr, requested_bufnr)
	end)

	it("enables the expression only in windows showing the buffer", function()
		local target = vim.api.nvim_create_buf(false, true)
		local other = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_win_set_buf(0, target)
		vim.cmd("vsplit")
		local other_win = vim.api.nvim_get_current_win()
		vim.api.nvim_win_set_buf(other_win, other)

		winbar.enable(target)

		local target_win = vim.fn.win_findbuf(target)[1]
		assert.are.equal(winbar.expression, vim.wo[target_win].winbar)
		assert.are.equal("", vim.wo[other_win].winbar)
		vim.cmd("only")
	end)

	it("clears only winbars owned by the module", function()
		local bufnr = vim.api.nvim_get_current_buf()
		winbar.enable(bufnr)
		winbar.disable(bufnr)
		assert.are.equal("", vim.wo.winbar)

		vim.wo.winbar = "custom"
		winbar.disable(bufnr)
		assert.are.equal("custom", vim.wo.winbar)
	end)

	it("clears its winbar after the last document-symbol client detaches", function()
		local bufnr = vim.api.nvim_get_current_buf()
		local original_get_clients = vim.lsp.get_clients
		vim.lsp.get_clients = function()
			return {}
		end

		winbar.setup()
		winbar.enable(bufnr)
		vim.api.nvim_exec_autocmds("LspDetach", { buffer = bufnr })
		vim.wait(100, function()
			return vim.wo.winbar == ""
		end)
		vim.lsp.get_clients = original_get_clients

		assert.are.equal("", vim.wo.winbar)
	end)

	it("keeps Markdown breadcrumbs when an LSP detaches", function()
		local bufnr = vim.api.nvim_get_current_buf()
		vim.bo[bufnr].filetype = "markdown"
		local original_get_clients = vim.lsp.get_clients
		vim.lsp.get_clients = function()
			return {}
		end

		winbar.setup()
		winbar.enable(bufnr)
		vim.api.nvim_exec_autocmds("LspDetach", { buffer = bufnr })
		vim.wait(20)
		vim.lsp.get_clients = original_get_clients

		assert.are.equal(winbar.expression, vim.wo.winbar)
	end)

	it("renders the active Markdown heading hierarchy", function()
		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_name(bufnr, vim.fn.tempname() .. ".md")
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
			"# Parent",
			"intro",
			"## Child",
			"details",
		})
		vim.bo[bufnr].filetype = "markdown"
		vim.api.nvim_win_set_buf(0, bufnr)
		vim.api.nvim_win_set_cursor(0, { 4, 0 })
		vim.g.statusline_winid = vim.api.nvim_get_current_win()
		navic.is_available = function()
			return false
		end

		local filepath = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":~:.")
		assert.are.equal(
			"%#NavicText# " .. filepath .. " %#NavicSeparator#>%#NavicText# Parent %#NavicSeparator#> %#NavicText#Child",
			winbar.render()
		)
	end)

	it("shows only the filepath before the first Markdown heading", function()
		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_name(bufnr, vim.fn.tempname() .. ".md")
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "preamble", "# Heading" })
		vim.bo[bufnr].filetype = "markdown"
		vim.api.nvim_win_set_buf(0, bufnr)
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		vim.g.statusline_winid = vim.api.nvim_get_current_win()

		local filepath = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":~:.")
		assert.are.equal("%#NavicText# " .. filepath, winbar.render())
	end)

	it("keeps the enclosing Quarto heading inside a code cell", function()
		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_name(bufnr, vim.fn.tempname() .. ".qmd")
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
			"# Analysis",
			"",
			"```{python}",
			"value = 1",
			"```",
		})
		vim.bo[bufnr].filetype = "quarto"
		vim.api.nvim_win_set_buf(0, bufnr)
		vim.api.nvim_win_set_cursor(0, { 4, 0 })
		vim.g.statusline_winid = vim.api.nvim_get_current_win()

		local filepath = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":~:.")
		assert.are.equal("%#NavicText# " .. filepath .. " %#NavicSeparator#>%#NavicText# Analysis", winbar.render())
	end)

	it("escapes statusline syntax in Markdown headings", function()
		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_name(bufnr, vim.fn.tempname() .. ".md")
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "# Rate 100%" })
		vim.bo[bufnr].filetype = "markdown"
		vim.api.nvim_win_set_buf(0, bufnr)
		vim.g.statusline_winid = vim.api.nvim_get_current_win()

		assert.matches("Rate 100%%%%$", winbar.render())
	end)
end)
