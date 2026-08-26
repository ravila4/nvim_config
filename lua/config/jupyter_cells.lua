local M = {}

local function is_marker(line)
	return line:match("^%s*#%s*%%%%") ~= nil
end

local function first_content_line(lines, marker_line)
	local line = marker_line + 1
	while line <= #lines and not is_marker(lines[line]) and lines[line]:match("^%s*$") do
		line = line + 1
	end
	return math.min(line, #lines)
end

local function copy_lines(lines)
	local copied = {}
	for index, line in ipairs(lines) do
		copied[index] = line
	end
	return copied
end

local function insert_lines(lines, position, additions)
	local result = copy_lines(lines)
	for offset, line in ipairs(additions) do
		table.insert(result, position + offset - 1, line)
	end
	return result
end

local function has_markers(lines)
	for _, line in ipairs(lines) do
		if is_marker(line) then
			return true
		end
	end
	return false
end

local function insert_percent(lines, cursor_line, direction)
	if #lines == 0 or (#lines == 1 and lines[1] == "") then
		return { lines = { "# %%", "" }, cursor_line = 2 }
	end

	if not has_markers(lines) then
		if direction == "above" then
			return {
				lines = insert_lines(lines, 1, { "# %%", "", "# %%" }),
				cursor_line = 2,
			}
		end
		local marked = insert_lines(lines, 1, { "# %%" })
		return {
			lines = insert_lines(marked, #marked + 1, { "# %%", "" }),
			cursor_line = #marked + 2,
		}
	end

	local position
	if direction == "above" then
		position = 1
		for line = math.min(cursor_line, #lines), 1, -1 do
			if is_marker(lines[line]) then
				position = line
				break
			end
		end
	else
		position = #lines + 1
		for line = cursor_line + 1, #lines do
			if is_marker(lines[line]) then
				position = line
				break
			end
		end
	end

	return {
		lines = insert_lines(lines, position, { "# %%", "" }),
		cursor_line = position + 1,
	}
end

local function is_fence_open(line)
	return line:match("^%s*```%s*[^%s].*$") ~= nil
end

local function is_fence_close(line)
	return line:match("^%s*```%s*$") ~= nil
end

local function enclosing_fence(lines, cursor_line)
	local opening
	for line, text in ipairs(lines) do
		if not opening and is_fence_open(text) then
			opening = line
		elseif opening and is_fence_close(text) then
			if cursor_line >= opening and cursor_line <= line then
				return opening, line
			end
			opening = nil
		end
	end
	if opening and cursor_line >= opening then
		return opening, #lines
	end
	return nil, nil
end

local function insert_fenced(lines, cursor_line, direction, language)
	if #lines == 0 or (#lines == 1 and lines[1] == "") then
		return {
			lines = { "```" .. language, "", "```" },
			cursor_line = 2,
		}
	end

	local opening, closing = enclosing_fence(lines, cursor_line)
	local position
	if direction == "above" then
		position = opening or math.max(cursor_line, 1)
	else
		position = closing and closing + 1 or math.min(cursor_line + 1, #lines + 1)
	end
	local additions = { "", "```" .. language, "", "```", "" }
	return {
		lines = insert_lines(lines, position, additions),
		cursor_line = position + 2,
	}
end

function M.bounds(lines, cursor_line)
	local start_line = 1
	local end_line = #lines

	for line = math.min(cursor_line, #lines), 1, -1 do
		if is_marker(lines[line]) then
			start_line = line + 1
			break
		end
	end

	for line = cursor_line + 1, #lines do
		if is_marker(lines[line]) then
			end_line = line - 1
			break
		end
	end

	while start_line <= end_line and lines[start_line]:match("^%s*$") do
		start_line = start_line + 1
	end
	while end_line >= start_line and lines[end_line]:match("^%s*$") do
		end_line = end_line - 1
	end

	return { start_line, end_line }
end

function M.next_line(lines, cursor_line)
	for line = cursor_line + 1, #lines do
		if is_marker(lines[line]) then
			return first_content_line(lines, line)
		end
	end
	return cursor_line
end

function M.previous_line(lines, cursor_line)
	local current_marker
	for line = math.min(cursor_line, #lines), 1, -1 do
		if is_marker(lines[line]) then
			current_marker = line
			break
		end
	end

	if current_marker then
		for line = current_marker - 1, 1, -1 do
			if is_marker(lines[line]) then
				return first_content_line(lines, line)
			end
		end
		return first_content_line(lines, current_marker)
	end

	return 1
end

function M.insert(lines, cursor_line, direction, representation, language)
	if representation == "percent" then
		return insert_percent(lines, cursor_line, direction)
	end
	return insert_fenced(lines, cursor_line, direction, language)
end

function M.changed_region(previous, updated)
	local prefix = 0
	while prefix < #previous and prefix < #updated and previous[prefix + 1] == updated[prefix + 1] do
		prefix = prefix + 1
	end

	local suffix = 0
	while
		suffix < #previous - prefix
		and suffix < #updated - prefix
		and previous[#previous - suffix] == updated[#updated - suffix]
	do
		suffix = suffix + 1
	end

	local replacement = {}
	for line = prefix + 1, #updated - suffix do
		table.insert(replacement, updated[line])
	end
	return {
		start_line = prefix,
		end_line = #previous - suffix,
		replacement = replacement,
	}
end

return M
