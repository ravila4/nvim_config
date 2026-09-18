local M = {
	ns = vim.api.nvim_create_namespace("notebook-cell-borders"),
	status_highlights = { done = "NotebookCellDone", error = "NotebookCellError" },
}
local cells = {}
local runtime = require("config.notebook_runtime")
local indicator, timer, frame = "spinner", nil, 0

local function redraw_labels()
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		for _, cell in ipairs(cells[vim.api.nvim_win_get_buf(win)] or {}) do
			vim.api.nvim__redraw({ win = win, range = { cell[1], cell[1] + 1 } })
		end
	end
	vim.api.nvim__redraw({ flush = true })
end

local function visible_running()
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		local info = vim.fn.getwininfo(win)[1]
		for _, cell in ipairs(cells[info.bufnr] or {}) do
			if
				cell.execution
				and cell.execution.status == "running"
				and cell[1] < info.botline
				and cell[2] >= info.topline - 1
			then
				return true
			end
		end
	end
	return false
end

local function stop_timer()
	if timer then
		timer:stop()
		timer:close()
		timer = nil
	end
end

local function animate()
	if not visible_running() then
		stop_timer()
	elseif not timer then
		timer = vim.uv.new_timer()
		local active = timer
		timer:start(
			100,
			100,
			vim.schedule_wrap(function()
				if timer ~= active then
					return
				end
				if not visible_running() then
					stop_timer()
					return
				end
				frame = frame + 1
				redraw_labels()
			end)
		)
	end
end

local function update_executions(buf)
	if not cells[buf] then
		return
	end
	local executions = require("config.notebook_edit").live_info(buf)
	for _, cell in ipairs(cells[buf]) do
		cell.execution = nil
		for _, execution in ipairs(executions) do
			if
				execution.start_line == cell.code_first
				and execution.end_line == cell.code_last
				and vim.trim(execution.source or "") == cell.source
			then
				cell.execution = execution
				break
			end
		end
	end
	animate()
end

function M.refresh(buf)
	if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_get_name(buf):match("%.ipynb$") then
		return
	end
	vim.api.nvim_buf_clear_namespace(buf, M.ns, 0, -1)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	cells[buf] = {}
	local function collect(nodes)
		for _, node in ipairs(nodes) do
			local first, last = node.range.start.line, node.range["end"].line
			if node.kind == "Function" and last > first and lines[last + 1]:match("^%s*[`~]+%s*$") then
				local code_first, code_last = first + 1, last - 1
				while code_first <= code_last and lines[code_first + 1]:match("^%s*$") do
					code_first = code_first + 1
				end
				while code_last >= code_first and lines[code_last + 1]:match("^%s*$") do
					code_last = code_last - 1
				end
				table.insert(cells[buf], {
					first,
					last,
					code_first = code_first,
					code_last = code_last,
					source = vim.trim(table.concat(vim.list_slice(lines, code_first + 1, code_last + 1), "\n")),
				})
				for row = first + 1, last - 1 do
					vim.api.nvim_buf_set_extmark(buf, M.ns, row, 0, {
						virt_text = { { "│ ", "NotebookCellBorder" } },
						virt_text_pos = "inline",
						priority = 200,
					})
				end
			end
			collect(node.children)
		end
	end
	collect(require("config.notebook_outline").symbols(lines, {}, {}))
	update_executions(buf)
end

local function draw(win, buf, top, bottom)
	local width = math.max(2, vim.api.nvim_win_get_width(win) - vim.fn.getwininfo(win)[1].textoff)
	local function mark(row, col, text, position, screen_col)
		if row < top or row > bottom then
			return
		end
		vim.api.nvim_buf_set_extmark(buf, M.ns, row, col, {
			virt_text = type(text) == "table" and text or { { text, "NotebookCellBorder" } },
			virt_text_pos = position,
			virt_text_win_col = screen_col,
			priority = 200,
			ephemeral = true,
		})
	end
	for _, cell in ipairs(cells[buf] or {}) do
		local first, last = cell[1], cell[2]
		if not timer and cell.execution and cell.execution.status == "running" and first <= bottom and last >= top then
			vim.schedule(animate)
		end
		local seconds, micros = vim.uv.gettimeofday()
		local label = cell.execution and runtime.label(cell.execution, seconds + micros / 1e6, indicator, frame) or ""
		label = label ~= "" and " " .. label .. " " or ""
		if vim.fn.strdisplaywidth(label) > width - 2 then
			label = ""
		end
		local rule = string.rep("─", width - 2 - vim.fn.strdisplaywidth(label))
		local icon = label:match("^ (✓) ") or label:match("^ (✗) ")
		local header = { { "╭" .. label .. rule .. "╮", "NotebookCellBorder" } }
		if icon then
			header = {
				{ "╭ ", "NotebookCellBorder" },
				{ icon, M.status_highlights[cell.execution.status] },
				{ label:sub(#icon + 2) .. rule .. "╮", "NotebookCellBorder" },
			}
		end
		mark(first, 0, header, "overlay", 0)
		for row = math.max(first + 1, top), math.min(last - 1, bottom) do
			mark(row, 0, "│", "overlay", width - 1)
		end
		mark(last, 0, "╰" .. string.rep("─", width - 2) .. "╯", "overlay", 0)
	end
end

function M.setup(opts)
	indicator = (opts or {}).running_indicator or "spinner"
	assert(vim.tbl_contains({ "spinner", "blink", "none" }, indicator), "Invalid notebook running_indicator")
	stop_timer()
	vim.api.nvim_set_decoration_provider(M.ns, {
		on_win = function(_, win, buf, top, bottom)
			if cells[buf] then
				draw(win, buf, top, bottom)
			end
			return false
		end,
	})
	vim.api.nvim_set_hl(0, "NotebookCellBorder", { default = true, link = "Comment" })
	vim.api.nvim_set_hl(0, "NotebookCellDone", { default = true, link = "DiagnosticOk" })
	vim.api.nvim_set_hl(0, "NotebookCellError", { default = true, link = "DiagnosticError" })
	local group = vim.api.nvim_create_augroup("NotebookCellBorders", { clear = true })
	vim.api.nvim_create_autocmd("User", {
		group = group,
		pattern = { "MoltenCellUpdate", "MoltenDeinitPost" },
		callback = function(event)
			-- Defer RPC until Molten's notification has returned to Python.
			vim.schedule(function()
				for _, buf in ipairs(event.data and event.data.buffers or vim.tbl_keys(cells)) do
					update_executions(buf)
				end
				redraw_labels()
			end)
		end,
	})
	vim.api.nvim_create_autocmd({ "WinScrolled", "WinClosed", "BufWinEnter", "BufWinLeave", "TabEnter" }, {
		group = group,
		callback = function()
			vim.schedule(animate)
		end,
	})
	vim.api.nvim_create_autocmd({ "BufWinEnter", "TextChanged", "TextChangedI", "InsertLeave" }, {
		group = group,
		pattern = "*.ipynb",
		callback = function(event)
			M.refresh(event.buf)
		end,
	})
	vim.api.nvim_create_autocmd("BufWipeout", {
		group = group,
		callback = function(event)
			cells[event.buf] = nil
			animate()
		end,
	})
	vim.api.nvim_create_autocmd("VimLeavePre", { group = group, callback = stop_timer })
end

return M
