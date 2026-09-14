local M = {}
local states, clipboard = {}, {}
local namespace = vim.api.nvim_create_namespace("notebook_saved_cells")
local function molten(name, ...)
	local ok, result = pcall(vim.fn[name], ...)
	if ok then
		return result
	end
	if tostring(result):find("E117: Unknown function: " .. name, 1, true) then
		return nil
	end
	error(result, 0)
end

function M.live_info(buf)
	return molten("MoltenCellInfo", buf) or {}
end

function M.redraw()
	molten("MoltenUpdateInterface")
end
local function register_name(register)
	if register == '"' then
		if vim.o.clipboard:find("unnamedplus", 1, true) then
			return "+"
		end
		if vim.o.clipboard:find("unnamed", 1, true) then
			return "*"
		end
	end
	return register
end

local function sequence(buf)
	return vim.api.nvim_buf_call(buf, function()
		return vim.fn.undotree().seq_cur
	end)
end

local function virtuals(buf)
	local result = {}
	for _, item in ipairs(states[buf].marks) do
		local position = vim.api.nvim_buf_get_extmark_by_id(buf, namespace, item.mark, { details = true })
		if #position > 0 then
			local cell = vim.deepcopy(item.cell)
			cell.start_line, cell.end_line = position[1], position[3].end_row
			result[#result + 1] = cell
		end
	end
	return result
end

local function set_virtuals(buf, cells)
	vim.api.nvim_buf_clear_namespace(buf, namespace, 0, -1)
	states[buf].marks = {}
	for _, cell in ipairs(cells) do
		local mark = vim.api.nvim_buf_set_extmark(buf, namespace, cell.start_line, 0, {
			end_row = cell.end_line,
			end_col = 0,
			right_gravity = true,
			end_right_gravity = true,
		})
		table.insert(states[buf].marks, { mark = mark, cell = vim.deepcopy(cell) })
	end
end

function M.executions(buf, saved)
	if not states[buf] then
		states[buf] = { marks = {}, history = {}, seq = sequence(buf), records = {} }
		local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		local cells = {}
		local used = {}
		local function visit(nodes)
			for _, node in ipairs(nodes) do
				if node.kind == "Function" then
					local first, last = node.range.start.line + 1, node.range["end"].line - 1
					while first <= last and lines[first + 1]:match("^%s*$") do
						first = first + 1
					end
					while last >= first and lines[last + 1]:match("^%s*$") do
						last = last - 1
					end
					local text = vim.trim(table.concat(vim.list_slice(lines, first + 1, last + 1), "\n"))
					for id, record in ipairs(saved or {}) do
						local source = type(record.source) == "table" and table.concat(record.source) or record.source
						if not used[id] and record.cell_type == "code" and vim.trim(source) == text then
							used[id] = true
							local status = "not run"
							if type(record.execution_count) == "number" then
								status = "done"
								for _, output in ipairs(record.outputs or {}) do
									if output.output_type == "error" then
										status = "error"
									end
								end
							end
							cells[#cells + 1] = {
								id = id,
								start_line = first,
								end_line = math.max(first, last),
								source = text,
								status = status,
								old = true,
								execution_count = record.execution_count,
							}
							states[buf].records[id] = record
							break
						end
					end
				end
				visit(node.children)
			end
		end
		visit(require("config.notebook_outline").symbols(lines, {}, {}))
		set_virtuals(buf, cells)
	end
	return virtuals(buf)
end

local function snapshot(buf)
	M.executions(buf, {})
	return { saved = virtuals(buf), molten = molten("MoltenCellSnapshot", buf) or {} }
end

local function restore(buf, value)
	local result = vim.api.nvim_buf_call(buf, function()
		return molten("MoltenCellRestore", buf, value.molten)
	end)
	assert(result ~= false and result ~= 0, "Could not restore cell outputs")
	set_virtuals(buf, value.saved)
end

local function remember(buf, value)
	local state = states[buf]
	state.seq = sequence(buf)
	state.history[state.seq] = vim.deepcopy(value)
end

function M.sync(buf)
	local state = states[buf]
	if not state then
		return
	end
	local seq = sequence(buf)
	if seq ~= state.seq and state.history[seq] then
		local ok, err = pcall(restore, buf, state.history[seq])
		if not ok then
			vim.api.nvim_buf_call(buf, function()
				vim.cmd("undo " .. state.seq)
			end)
			restore(buf, state.history[state.seq])
			error(err, 0)
		end
	end
	remember(buf, snapshot(buf))
end

-- Relocate retained spans through a splice and collect removed spans separately.
local function splice(cells, first, last, size)
	local kept, removed = {}, {}
	for _, original in ipairs(cells) do
		local cell = vim.deepcopy(original)
		if cell.start_line >= last then
			cell.start_line = cell.start_line + size - (last - first)
			cell.end_line = cell.end_line + size - (last - first)
			kept[#kept + 1] = cell
		elseif cell.end_line < first then
			kept[#kept + 1] = cell
		else
			cell.start_line = cell.start_line - first
			cell.end_line = cell.end_line - first
			removed[#removed + 1] = cell
		end
	end
	return kept, removed
end

-- Half-open source ranges; heading rows already include their descendants.
function M.ranges(rows, first, last, lines)
	local result = {}
	for i = math.min(first, last), math.min(math.max(first, last), #rows) do
		local node = rows[i]
		local finish = node.range_end + 1
		while finish < #lines and lines[finish + 1]:match("^%s*$") do
			finish = finish + 1
		end
		local previous = result[#result]
		if previous and node.range_start <= previous[2] then
			previous[2] = math.max(previous[2], finish)
		else
			result[#result + 1] = { node.range_start, finish }
		end
	end
	return result
end

local function change(buf, before, after, fn)
	local seq = sequence(buf)
	vim.api.nvim_buf_call(buf, function()
		-- End the previous undo block even when multiple mappings run in one event.
		vim.cmd("let &undolevels = &undolevels")
		fn()
	end)
	local ok, err = pcall(restore, buf, after)
	if not ok then
		vim.api.nvim_buf_call(buf, function()
			vim.cmd("undo " .. seq)
		end)
		restore(buf, before)
		error(err, 0)
	end
	remember(buf, after)
	states[buf].changed = true
end

function M.changed(buf)
	return states[buf] and states[buf].changed or false
end

function M.records(buf)
	return virtuals(buf), states[buf].records
end

function M.accept_saved(buf, bindings)
	local state = states[buf]
	local cells = {}
	local next_id = 0
	for id in pairs(state.records) do
		next_id = math.max(next_id, id)
	end
	for _, binding in ipairs(bindings) do
		local id = binding.id
		if not id then
			next_id = next_id + 1
			id = next_id
		end
		state.records[id] = binding.record
		local cell = vim.deepcopy(binding)
		cell.record = nil
		cell.id = id
		cell.old = true
		cell.execution_count = binding.record.execution_count
		cell.status = "not run"
		if type(cell.execution_count) == "number" then
			cell.status = "done"
			for _, output in ipairs(binding.record.outputs or {}) do
				if output.output_type == "error" then
					cell.status = "error"
				end
			end
		end
		cells[#cells + 1] = cell
	end
	set_virtuals(buf, cells)
	remember(buf, snapshot(buf))
end

function M.yank(buf, ranges, register, cut)
	register = register_name(register)
	local before = snapshot(buf)
	if cut then
		for _, cell in ipairs(M.live_info(buf)) do
			for _, span in ipairs(ranges) do
				if cell.start_line < span[2] and cell.end_line >= span[1] then
					if cell.status == "running" or cell.status == "queued" then
						error("Cannot cut a queued or running cell", 0)
					end
					if cell.start_line < span[1] or cell.end_line >= span[2] then
						error("Selection cuts through an execution range", 0)
					end
				end
			end
		end
	end
	local contents = {}
	for _, span in ipairs(ranges) do
		vim.list_extend(contents, vim.api.nvim_buf_get_lines(buf, span[1], span[2], false))
	end
	vim.fn.setreg(register, contents, "V")
	clipboard[register] = { contents = vim.fn.getreg(register, 1, true), buf = buf, saved = {}, molten = {} }
	if cut then
		remember(buf, before)
		local after = vim.deepcopy(before)
		local offset = 0
		for _, span in ipairs(ranges) do
			for _, kind in ipairs({ "saved", "molten" }) do
				local _, removed = splice(before[kind], span[1], span[2], 0)
				for _, cell in ipairs(removed) do
					cell.start_line = cell.start_line + offset
					cell.end_line = cell.end_line + offset
					table.insert(clipboard[register][kind], cell)
				end
			end
			offset = offset + span[2] - span[1]
		end
		for i = #ranges, 1, -1 do
			for _, kind in ipairs({ "saved", "molten" }) do
				after[kind] = splice(after[kind], ranges[i][1], ranges[i][2], 0)
			end
		end
		change(buf, before, after, function()
			for i = #ranges, 1, -1 do
				if i < #ranges then
					vim.cmd("undojoin")
				end
				vim.api.nvim_buf_set_lines(buf, ranges[i][1], ranges[i][2], false, {})
			end
		end)
	end
end

function M.paste(buf, index, register, count)
	register = register_name(register)
	local contents = vim.fn.getreg(register, 1, true)
	if #contents == 0 then
		return
	end
	local insert = {}
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local empty = #lines == 1 and lines[1] == ""
	if index > 0 and lines[index]:match("%S") then
		insert[1] = ""
	end
	local prefix = #insert
	for _ = 1, count do
		vim.list_extend(insert, contents)
	end
	if not empty and index < #lines and insert[#insert]:match("%S") then
		insert[#insert + 1] = ""
	end
	local before = snapshot(buf)
	remember(buf, before)
	local after = {}
	for _, kind in ipairs({ "saved", "molten" }) do
		after[kind] = splice(before[kind], index, index, #insert)
	end
	local clip = clipboard[register]
	if clip and clip.buf == buf and vim.deep_equal(clip.contents, contents) then
		for _, kind in ipairs({ "saved", "molten" }) do
			local attached = {}
			for _, cell in ipairs(before[kind]) do
				if cell.id then
					attached[cell.id] = true
				end
			end
			for _, original in ipairs(clip[kind]) do
				if not original.id or not attached[original.id] then
					local cell = vim.deepcopy(original)
					cell.start_line = cell.start_line + index + prefix
					cell.end_line = cell.end_line + index + prefix
					after[kind][#after[kind] + 1] = cell
				end
			end
			clip[kind] = {}
		end
	end
	change(buf, before, after, function()
		vim.api.nvim_buf_set_lines(buf, index, empty and 1 or index, false, insert)
	end)
end

function M.undo(buf, redo)
	remember(buf, snapshot(buf))
	vim.api.nvim_buf_call(buf, function()
		vim.cmd(redo and "redo" or "undo")
	end)
	M.sync(buf)
end

function M.forget_kernel(kernel_id)
	local function prune(value)
		value.molten = vim.tbl_filter(function(cell)
			return cell.kernel_id ~= kernel_id
		end, value.molten)
	end
	for _, state in pairs(states) do
		for _, value in pairs(state.history) do
			prune(value)
		end
	end
	for _, clip in pairs(clipboard) do
		prune(clip)
	end
end

function M.reset(buf)
	states[buf] = nil
	if vim.api.nvim_buf_is_valid(buf) then
		vim.api.nvim_buf_clear_namespace(buf, namespace, 0, -1)
	end
	for register, clip in pairs(clipboard) do
		if clip.buf == buf then
			clipboard[register] = nil
		end
	end
end

return M
