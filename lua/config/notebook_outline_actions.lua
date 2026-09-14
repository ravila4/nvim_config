local M = {}
local operation

local function sidebar()
	local view = require("outline")._get_sidebar()
	if
		view
		and view.provider
		and view.provider.name == "notebook"
		and vim.api.nvim_get_current_buf() == view.view.buf
	then
		return view
	end
end

local function refresh(view, row)
	vim.api.nvim_win_call(view.code.win, function()
		require("outline").refresh()
	end)
	vim.api.nvim_win_set_cursor(view.view.win, { math.max(1, math.min(row, #view.flats)), 0 })
end

local function run(fn)
	local view = sidebar()
	if not view then
		return
	end
	local ok, err = pcall(fn, view)
	if not ok then
		vim.notify(tostring(err), vim.log.levels.WARN)
	end
end

local function yank(first, last, register, cut)
	run(function(view)
		local edit = require("config.notebook_edit")
		local ranges = edit.ranges(view.flats, first, last, vim.api.nvim_buf_get_lines(view.code.buf, 0, -1, false))
		if #ranges == 0 then
			return
		end
		edit.yank(view.code.buf, ranges, register, cut)
		if cut then
			refresh(view, first)
		end
	end)
end

function M.operator()
	local op = operation
	if not op then
		return
	end
	operation = nil
	vim.go.operatorfunc = op.previous
	yank(vim.fn.line("'["), vim.fn.line("']"), op.register, op.cut)
end

function M.attach()
	local view = require("outline")._get_sidebar()
	if not view or not view.view.buf or not vim.api.nvim_buf_is_valid(view.view.buf) then
		return
	end
	local function map(mode, key, fn, desc, expr)
		vim.keymap.set(mode, key, fn, { buffer = view.view.buf, silent = true, desc = desc, expr = expr })
	end
	for _, key in ipairs({ "y", "d" }) do
		local cut = key == "d"
		map("n", key, function()
			operation = { cut = cut, register = vim.v.register, previous = vim.go.operatorfunc }
			vim.go.operatorfunc = "v:lua.require'config.notebook_outline_actions'.operator"
			return "g@"
		end, cut and "Cut notebook cells (motion)" or "Yank notebook cells (motion)", true)
		map("n", key .. key, function()
			local row = vim.fn.line(".")
			yank(row, row + vim.v.count1 - 1, vim.v.register, cut)
		end, cut and "Cut notebook cells" or "Yank notebook cells")
		map("x", key, function()
			local first, last, register = vim.fn.line("v"), vim.fn.line("."), vim.v.register
			vim.cmd.normal({ args = { "\27" }, bang = true })
			yank(first, last, register, cut)
		end, cut and "Cut selected notebook cells" or "Yank selected notebook cells")
	end
	map("n", "Y", function()
		local row = vim.fn.line(".")
		yank(row, row + vim.v.count1 - 1, vim.v.register, false)
	end, "Yank notebook cells")
	for _, key in ipairs({ "p", "P" }) do
		map("n", key, function()
			local register, count = vim.v.register, vim.v.count1
			run(function(current)
				local row = vim.fn.line(".")
				local node = current.flats[row]
				local ranges = require("config.notebook_edit").ranges(
					current.flats,
					row,
					row,
					vim.api.nvim_buf_get_lines(current.code.buf, 0, -1, false)
				)
				local index = node and (key == "P" and node.range_start or ranges[1][2]) or 0
				require("config.notebook_edit").paste(current.code.buf, index, register, count)
				refresh(current, row)
			end)
		end, key == "p" and "Paste cells after" or "Paste cells before")
	end
	for _, key in ipairs({ "u", "<C-r>" }) do
		map("n", key, function()
			local count = vim.v.count1
			run(function(current)
				local row = vim.fn.line(".")
				for _ = 1, count do
					require("config.notebook_edit").undo(current.code.buf, key ~= "u")
				end
				refresh(current, row)
			end)
		end, key == "u" and "Undo notebook edit" or "Redo notebook edit")
	end
end

return M
