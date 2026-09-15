describe("notebook cell borders", function()
	local buf, borders
	before_each(function()
		buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_name(buf, vim.fn.tempname() .. ".ipynb")
		borders = require("config.notebook_borders")
		vim.o.columns = 120
		vim.o.lines = 30
		vim.api.nvim_set_current_buf(buf)
		vim.wo.number = false
		vim.wo.signcolumn = "no"
		borders.setup()
	end)
	after_each(function()
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			if vim.api.nvim_win_get_config(win).relative ~= "" then
				vim.api.nvim_win_close(win, true)
			end
		end
		vim.cmd("only!")
		vim.api.nvim_buf_delete(buf, { force = true })
	end)
	it("encloses code without adding source or virtual rows", function()
		local lines = { "# Heading", "```python", "print('hello')", "```", "prose" }
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
		borders.refresh(buf)
		vim.cmd("redraw!")
		assert.equals("╭", vim.fn.screenstring(2, 1))
		assert.equals("│", vim.fn.screenstring(3, 1))
		assert.equals("╰", vim.fn.screenstring(4, 1))
		assert.equals("p", vim.fn.screenstring(5, 1))
		assert.same(lines, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
	end)
	it("removes borders when a cell is deleted", function()
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "```python", "x = 1", "```" })
		borders.refresh(buf)
		vim.cmd("redraw!")
		assert.equals("╭", vim.fn.screenstring(1, 1))
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "prose" })
		vim.api.nvim_exec_autocmds("TextChanged", { buffer = buf })
		vim.cmd("redraw!")
		assert.equals("p", vim.fn.screenstring(1, 1))
	end)
	it("fills the window excluding its gutter and follows resizing", function()
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "```python", "x = 1", "```" })
		vim.cmd("vsplit")
		local win = vim.api.nvim_get_current_win()
		vim.wo[win].number = true
		for _, size in ipairs({ 72, 45 }) do
			vim.api.nvim_win_set_width(win, size)
			borders.refresh(buf)
			vim.cmd("redraw!")
			local info = vim.fn.getwininfo(win)[1]
			assert.equals("╭", vim.fn.screenstring(info.winrow, info.wincol + info.textoff))
			assert.equals("╮", vim.fn.screenstring(info.winrow, info.wincol + size - 1))
		end
		vim.api.nvim_win_close(win, true)
	end)
	it("ignores ordinary markdown buffers", function()
		vim.api.nvim_buf_set_name(buf, vim.fn.tempname() .. ".md")
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "```python", "x = 1", "```" })
		borders.refresh(buf)
		vim.cmd("redraw!")
		assert.equals("`", vim.fn.screenstring(1, 1))
	end)
	it("renders independent borders in unequal splits", function()
		vim.o.columns = 120
		vim.o.lines = 30
		vim.api.nvim_set_current_buf(buf)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "```python", "x = 1", "```" })
		borders.setup()
		vim.cmd("vsplit")
		vim.api.nvim_win_set_width(0, 35)
		borders.refresh(buf)
		vim.cmd("redraw!")
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			local info = vim.fn.getwininfo(win)[1]
			assert.equals("╮", vim.fn.screenstring(info.winrow, info.wincol + info.width - 1))
		end
	end)
	it("resizes a non-current notebook without refreshing its buffer", function()
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "```python", "x = 1", "```" })
		borders.refresh(buf)
		local notebook_win = vim.api.nvim_get_current_win()
		vim.cmd("vnew")
		vim.api.nvim_win_set_width(notebook_win, 45)
		vim.cmd("redraw!")
		local info = vim.fn.getwininfo(notebook_win)[1]
		assert.equals("╮", vim.fn.screenstring(info.winrow, info.wincol + info.width - 1))
	end)
end)
