local M = {}

local function range(first, last)
	return { start = { line = first - 1, character = 0 }, ["end"] = { line = last - 1, character = 0 } }
end

local function entry(name, kind, first, last)
	return { name = name, kind = kind, range = range(first, last), selectionRange = range(first, first), children = {} }
end

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

function M.symbols(lines, executions, saved)
	local root = { children = {} }
	local stack = { root }
	local number, line = 0, 1
	if lines[1] == "---" then
		for i = 2, #lines do
			if lines[i]:match("^%-%-%-%s*$") or lines[i]:match("^%.%.%.%s*$") then
				line = i + 1
				break
			end
		end
	end
	while line <= #lines do
		local text = lines[line]
		local fence, info = text:match("^%s*(```+)(.*)$")
		if not fence then
			fence, info = text:match("^%s*(~~~+)(.*)$")
		end
		if fence then
			local closing = #lines + 1
			for i = line + 1, #lines do
				local candidate = lines[i]:match("^%s*([`~]+)%s*$")
				if candidate and #candidate >= #fence and candidate == fence:sub(1, 1):rep(#candidate) then
					closing = i
					break
				end
			end
			if vim.trim(info) ~= "" then
				number = number + 1
				local title = ""
				for i = line + 1, closing - 1 do
					if not lines[i]:match("^%s*$") then
						title = vim.trim(lines[i]):gsub("^#+%s*", "")
						break
					end
				end
				local name = "Cell " .. number
				if vim.fn.strchars(title) > 24 then
					title = vim.fn.strcharpart(title, 0, 24) .. "…"
				end
				if title ~= "" then
					name = name .. ": " .. title
				end
				local cell = entry(name, "Function", line, math.min(closing, #lines))
				cell.detail = status(lines, line + 1, closing - 1, executions, saved)
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
				table.insert(stack[#stack].children, cell)
			end
			line = closing + 1
		else
			local hashes, title = text:match("^%s*(#+)%s+(.+)$")
			local underline = lines[line + 1] or ""
			if not hashes and text:match("%S") then
				if underline:match("^=+%s*$") then
					hashes, title = "#", text
				elseif underline:match("^%-+%s*$") then
					hashes, title = "##", text
				end
			end
			if hashes and #hashes <= 6 then
				while #stack > 1 and stack[#stack].level >= #hashes do
					stack[#stack].range["end"].line = line - 2
					table.remove(stack)
				end
				local heading = entry(title:gsub("%s+#+%s*$", ""), "Module", line, #lines)
				heading.level = #hashes
				table.insert(stack[#stack].children, heading)
				table.insert(stack, heading)
			end
			line = line + 1
		end
	end
	return root.children
end

return M
