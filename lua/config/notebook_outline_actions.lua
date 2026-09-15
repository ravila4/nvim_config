local M = {}
local operation

local function sidebar()
	local view = require("outline")._get_sidebar()
	if
		view
		and view.provider
		and (view.provider.name == "notebook" or view.provider.name == "document")
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
	local ok, err = pcall(function()
		assert(
			vim.api.nvim_win_is_valid(view.code.win) and vim.api.nvim_win_get_buf(view.code.win) == view.code.buf,
			"Outline source window changed"
		)
		assert(
			require("config.document_outline_provider").is_current(view),
			"Document changed; refresh the outline before editing"
		)
		fn(view)
	end)
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

function M.context_menu()
	local view = sidebar()
	if not view then
		return
	end
	local items = {}
	local selected = view.flats[vim.api.nvim_win_get_cursor(view.view.win)[1]]
	local mode = require("config.document_outline").format(view.code.buf)
	local source, source_tick = view.code.buf, vim.api.nvim_buf_get_changedtick(view.code.buf)
	local function action(name, fn)
		items[#items + 1] = {
			name = name,
			cmd = function()
				if not vim.api.nvim_win_is_valid(view.view.win) then
					return
				end
				vim.api.nvim_set_current_win(view.view.win)
				run(function(current)
					assert(
						current.code.buf == source and vim.api.nvim_buf_get_changedtick(source) == source_tick,
						"Notebook changed; reopen the Outline menu before running cells or editing"
					)
					fn(current)
				end)
			end,
		}
	end
	if mode == "quarto" then
		local document = require("config.document_outline")
		local tree = document.parse(vim.api.nvim_buf_get_lines(source, 0, -1, false), mode)
		local node
		local function find(nodes)
			for _, item in ipairs(nodes) do
				if selected and item.range.start.line == selected.range_start then
					node = item
				end
				find(item.children)
			end
		end
		find(tree)
		local quarto = require("config.quarto_outline")
		if node and node.kind == "Function" then
			for _, scope in ipairs({ "Cell", "All Above", "All Below" }) do
				action("Run " .. scope, function(current)
					vim.api.nvim_win_call(current.code.win, function()
						quarto.run(source, node, scope)
					end)
				end)
			end
			items[#items + 1] = { name = "separator" }
		end
		for _, direction in ipairs({ "Above", "Below" }) do
			action("Create Cell " .. direction, function(current)
				local function create(language)
					if not language then
						return
					end
					local ok, err = pcall(function()
						assert(
							vim.api.nvim_buf_is_valid(source)
								and vim.api.nvim_buf_get_changedtick(source) == source_tick,
							"Document changed; reopen the Outline menu"
						)
						quarto.create(source, node, direction:lower(), language)
						refresh(current, vim.api.nvim_win_get_cursor(current.view.win)[1])
					end)
					if not ok then
						vim.notify(tostring(err), vim.log.levels.WARN)
					end
				end
				if node and node.language then
					create(node.language)
				else
					vim.ui.select({ "python", "r", "julia", "bash" }, { prompt = "New cell language:" }, create)
				end
			end)
		end
		if node and node.kind == "Function" and quarto.uses_molten(node.language) then
			action("Open Output", function()
				require("config.notebook_output_view").open(source, node.range.start.line + 1)
			end)
		end
	elseif mode == "notebook" and selected and selected.kind == vim.lsp.protocol.SymbolKind.Function then
		local buf = view.code.buf
		local tick = vim.api.nvim_buf_get_changedtick(buf)
		local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		local cells = {}
		local function visit(nodes)
			for _, node in ipairs(nodes) do
				if node.kind == vim.lsp.protocol.SymbolKind.Function then
					cells[#cells + 1] = node
				end
				visit(node.children or {})
			end
		end
		visit(view.items)
		for _, scope in ipairs({ "Cell", "All Above", "All Below" }) do
			action("Run " .. scope, function(current)
				assert(
					current.code.buf == buf
						and vim.api.nvim_win_get_buf(current.code.win) == buf
						and vim.api.nvim_buf_get_changedtick(buf) == tick,
					"Notebook changed; reopen the Outline menu before running cells"
				)
				vim.api.nvim_win_call(current.code.win, function()
					for _, cell in ipairs(cells) do
						if
							(scope == "Cell" and cell == selected)
							or (scope == "All Above" and cell.range_start < selected.range_start)
							or (scope == "All Below" and cell.range_start > selected.range_start)
						then
							local first, last = cell.range_start + 2, cell.range_end
							local opening = lines[first - 1]:match("^%s*([`~]+)")
							local closing = lines[last + 1]:match("^%s*([`~]+)%s*$")
							if not closing or #closing < #opening or closing ~= opening:sub(1, 1):rep(#closing) then
								last = last + 1
							end
							while first <= last and lines[first]:match("^%s*$") do
								first = first + 1
							end
							while last >= first and lines[last]:match("^%s*$") do
								last = last - 1
							end
							if first <= last then
								vim.fn.MoltenEvaluateRange(first, last)
							end
						end
					end
				end)
			end)
		end
		items[#items + 1] = { name = "separator" }
		for _, direction in ipairs({ "Above", "Below" }) do
			action("Create Cell " .. direction, function(current)
				local previous = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
				local result = require("config.jupyter_cells").insert(
					previous,
					selected.range_start + 1,
					direction:lower(),
					"fenced",
					"python"
				)
				local changed = require("config.jupyter_cells").changed_region(previous, result.lines)
				assert(changed.start_line == changed.end_line, "Creating a cell must only insert lines")
				require("config.notebook_edit").insert(buf, changed.start_line, changed.replacement)
				refresh(current, vim.api.nvim_win_get_cursor(current.view.win)[1] + (direction == "Below" and 1 or 0))
			end)
		end
		action("Open Output", function()
			require("config.notebook_output_view").open(buf, selected.range_start + 1)
		end)
	end
	local kernel_actions = mode == "notebook"
		or (mode == "quarto" and #require("config.notebook_edit").live_info(source) > 0)
	if kernel_actions then
		action("Interrupt Kernel", function(current)
			vim.api.nvim_win_call(current.code.win, function()
				vim.cmd("MoltenInterrupt")
			end)
		end)
		action("Restart Kernel", function(current)
			vim.api.nvim_win_call(current.code.win, function()
				vim.cmd("MoltenRestart")
			end)
		end)
	end
	if #items > 0 then
		items[#items + 1] = { name = "separator" }
	end
	action("Expand All", function(current)
		current:_set_all_folded(false)
	end)
	action("Collapse All", function(current)
		current:_set_all_folded(true)
	end)
	return items
end

function M.attach()
	local view = require("outline")._get_sidebar()
	if not view or not view.view.buf or not vim.api.nvim_buf_is_valid(view.view.buf) then
		return
	end
	local function map(mode, key, fn, desc, expr)
		vim.keymap.set(mode, key, fn, { buffer = view.view.buf, silent = true, desc = desc, expr = expr })
	end
	map("n", "<Space>", function()
		run(function(current)
			current:_toggle_fold()
		end)
	end, "Expand or collapse notebook group")
	local editable = require("config.document_outline").format(view.code.buf) ~= "markdown"
	if not editable then
		for _, key in ipairs({ "y", "d", "yy", "dd", "Y", "p", "P", "u", "<C-r>" }) do
			pcall(vim.keymap.del, "n", key, { buffer = view.view.buf })
		end
		for _, key in ipairs({ "y", "d" }) do
			pcall(vim.keymap.del, "x", key, { buffer = view.view.buf })
		end
		return
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
				local module = require("config.document_outline").format(current.code.buf) == "quarto"
						and "config.quarto_outline"
					or "config.notebook_edit"
				require(module).paste(current.code.buf, index, register, count)
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
