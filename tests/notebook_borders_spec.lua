describe("notebook cell borders", function()
	local buf, borders, live_info, executions
	before_each(function()
		buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_name(buf, vim.fn.tempname() .. ".ipynb")
		borders = require("config.notebook_borders")
		live_info = require("config.notebook_edit").live_info
		executions = {}
		require("config.notebook_edit").live_info = function()
			return executions
		end
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
		require("config.notebook_edit").live_info = live_info
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

	local function header(no_redraw)
		if not no_redraw then
			vim.cmd("redraw!")
		end
		local text = ""
		for col = 1, 25 do
			text = text .. vim.fn.screenstring(1, col)
		end
		return text
	end
	local function update()
		vim.api.nvim_exec_autocmds("User", { pattern = "MoltenCellUpdate", data = { buffers = { buf } } })
		vim.wait(20, function()
			return false
		end)
	end
	local function timed_cell(status)
		return {
			start_line = 1,
			end_line = 1,
			source = "x = 1",
			status = status,
			started_at = 100,
			finished_at = 102.8,
		}
	end
	it("updates the border from execution events and clears the duration on rerun", function()
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "```python", "x = 1", "```" })
		borders.refresh(buf)
		executions = { timed_cell("done") }
		update()
		assert.truthy(header(true):find("✓ 2.8s", 1, true))
		executions = { timed_cell("queued") }
		update()
		assert.truthy(header(true):find("queued", 1, true))
		assert.falsy(header(true):find("2.8s", 1, true))
		executions = { timed_cell("error") }
		update()
		assert.truthy(header(true):find("✗ 2.8s", 1, true))
	end)
	it("colors the success and failure icons apart from the border", function()
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "```python", "x = 1", "```" })
		borders.refresh(buf)
		local function icon_attr()
			local text = header(true)
			local byte = text:find("✓", 1, true) or text:find("✗", 1, true)
			return vim.fn.screenattr(1, vim.fn.strchars(text:sub(1, byte - 1)) + 1)
		end
		executions = { timed_cell("done") }
		update()
		local done = icon_attr()
		executions = { timed_cell("error") }
		update()
		local failed = icon_attr()
		assert.are_not.equals(done, vim.fn.screenattr(1, 1))
		assert.are_not.equals(failed, vim.fn.screenattr(1, 1))
		assert.are_not.equals(done, failed)
		assert.equals(vim.fn.screenattr(1, 1), vim.fn.screenattr(1, 24))
	end)
	it("does not assign a partial or modified execution to the full cell", function()
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "```python", "x = 2", "```" })
		executions = { timed_cell("done") }
		borders.refresh(buf)
		assert.falsy(header():find("2.8s", 1, true))
	end)
	it("animates a visible running cell and closes its timer when finished", function()
		local initial = {}
		vim.uv.walk(function(handle)
			initial[handle] = true
		end)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "```python", "x = 1", "```" })
		executions = { timed_cell("running") }
		executions[1].started_at = vim.uv.gettimeofday()
		borders.refresh(buf)
		local timer
		vim.uv.walk(function(handle)
			if not initial[handle] and handle:get_type() == "timer" then
				timer = handle
			end
		end)
		assert.truthy(timer)
		local first = header()
		assert.truthy(vim.wait(500, function()
			return header(true) ~= first
		end, 20))
		executions = { timed_cell("done") }
		update()
		assert.truthy(timer:is_closing())
	end)
	it("closes the animation timer when its notebook is wiped", function()
		local initial = {}
		vim.uv.walk(function(handle)
			initial[handle] = true
		end)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "```python", "x = 1", "```" })
		executions = { timed_cell("running") }
		borders.refresh(buf)
		local timer
		vim.uv.walk(function(handle)
			if not initial[handle] and handle:get_type() == "timer" then
				timer = handle
			end
		end)
		assert.truthy(timer)
		vim.api.nvim_buf_delete(buf, { force = true })
		assert.truthy(timer:is_closing())
		buf = vim.api.nvim_create_buf(false, true)
	end)
	it("pauses animation offscreen and resumes when the cell returns", function()
		local initial = {}
		vim.uv.walk(function(handle)
			initial[handle] = true
		end)
		local lines = { "```python", "x = 1", "```" }
		for _ = 1, 100 do
			table.insert(lines, "prose")
		end
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
		executions = { timed_cell("running") }
		borders.refresh(buf)
		local timer
		vim.uv.walk(function(handle)
			if not initial[handle] and handle:get_type() == "timer" then
				timer = handle
			end
		end)
		assert.truthy(timer)
		vim.api.nvim_win_set_cursor(0, { 100, 0 })
		vim.cmd("normal! zt")
		vim.cmd("redraw!")
		assert.truthy(vim.wait(500, function()
			return timer:is_closing()
		end, 20))
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		vim.cmd("normal! zt")
		vim.cmd("redraw!")
		local first = header()
		assert.truthy(vim.wait(500, function()
			return header(true) ~= first
		end, 20))
	end)
end)
