local M = {}

local function saved_status(source, cells)
	local match
	for _, cell in ipairs(cells or {}) do
		local text = type(cell.source) == "table" and table.concat(cell.source) or cell.source
		if cell.cell_type == "code" and type(text) == "string" and vim.trim(text) == source then
			if match then
				return "not run"
			end
			match = cell
		end
	end
	if match and type(match.execution_count) == "number" then
		local state = "done"
		for _, output in ipairs(match.outputs or {}) do
			if output.output_type == "error" then
				state = "error"
			end
		end
		return "saved " .. state .. " [" .. match.execution_count .. "]"
	end
	return "not run"
end

local function status(lines, first, last, executions, saved)
	while first <= last and lines[first]:match("^%s*$") do
		first = first + 1
	end
	while last >= first and lines[last]:match("^%s*$") do
		last = last - 1
	end
	local source = vim.trim(table.concat(vim.list_slice(lines, first, last), "\n"))
	local partial = false
	for _, result in ipairs(executions) do
		if result.start_line <= last - 1 and result.end_line >= first - 1 then
			if result.start_line == first - 1 and result.end_line == last - 1 then
				local changed = vim.trim(result.source or "") ~= source
				local state = result.status
				if state == "not run" then
					return state
				end
				if changed then
					if state == "running" or state == "queued" then
						return state .. " · modified"
					end
					return "modified"
				end
				if result.old then
					state = "saved " .. state
				end
				if result.execution_count and result.execution_count > 0 then
					state = state .. " [" .. result.execution_count .. "]"
				end
				return state
			end
			partial = true
		end
	end
	return partial and "partial" or saved_status(source, saved)
end

function M.symbols(lines, executions, saved, mode)
	local tree = require("config.document_outline").parse(lines, mode)
	for _, cell in ipairs(require("config.document_outline").cells(tree)) do
		cell.detail = status(lines, cell.body[1] + 1, cell.body[2], executions or {}, saved)
		local icons = {
			["not"] = "○",
			queued = "◷",
			running = "◉",
			done = "✓",
			error = "✗",
			modified = "~",
			partial = "◐",
		}
		cell.notebook_icon = icons[cell.detail:gsub("^saved ", ""):match("^%S+")]
	end
	return tree
end

return M
