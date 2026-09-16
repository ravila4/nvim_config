local M = {}

function M.format(buf)
	local name = vim.api.nvim_buf_get_name(buf)
	if name:match("%.ipynb$") then
		return "notebook"
	elseif name:match("%.qmd$") or vim.bo[buf].filetype == "quarto" then
		return "quarto"
	elseif vim.bo[buf].filetype == "markdown" or name:match("%.md$") then
		return "markdown"
	end
end

local function entry(name, kind, first, last)
	local start = { line = first - 1, character = 0 }
	return {
		name = name,
		kind = kind,
		range = { start = start, ["end"] = { line = last - 1, character = 0 } },
		selectionRange = { start = start, ["end"] = start },
		children = {},
	}
end

function M.content_start(lines)
	if lines[1] and lines[1]:match("^%-%-%-%s*$") then
		for i = 2, #lines do
			if lines[i]:match("^%-%-%-%s*$") or lines[i]:match("^%.%.%.%s*$") then
				return i + 1, true
			end
		end
		return #lines + 1, false
	end
	return 1, true
end

-- Source body spans are zero-based and half-open; symbol endpoints are inclusive.
function M.fence(lines, line)
	local text = lines[line]
	if not text or text:match("^    ") or text:match("^\t") then
		return
	end
	local fence, info = text:match("^ *(```+)(.*)$")
	if not fence then
		fence, info = text:match("^ *(~~~+)(.*)$")
	end
	if not fence or (fence:sub(1, 1) == "`" and info:find("`", 1, true)) then
		return
	end
	local closing = #lines + 1
	for i = line + 1, #lines do
		local candidate = lines[i]:match("^ ? ? ?([`~]+)%s*$")
		if candidate and #candidate >= #fence and candidate == fence:sub(1, 1):rep(#candidate) then
			closing = i
			break
		end
	end
	return {
		info = vim.trim(info),
		first = line - 1,
		finish = math.min(closing, #lines),
		body = { line, closing - 1 },
		closed = closing <= #lines,
	}
end

local function title(lines, block, mode)
	local preview, label
	for i = block.body[1] + 1, block.body[2] do
		local text = vim.trim(lines[i])
		local option = text:match("^#|%s*(.*)") or text:match("^//|%s*(.*)") or text:match("^%%%%|%s*(.*)")
		if mode == "quarto" and option then
			local value = option:match("^label:%s*(.-)%s*$")
			if value and value ~= "" then
				label = value:match('^"([%w_.%-]+)"$') or value:match("^'([%w_.%-]+)'$") or value:match("^([%w_.%-]+)$")
			end
		elseif not preview and text ~= "" then
			preview = text:gsub("^#+%s*", "")
		end
	end
	local result = label or preview or ""
	if vim.fn.strchars(result) > 24 then
		result = vim.fn.strcharpart(result, 0, 24) .. "…"
	end
	return result, label
end

local function div_kind(text)
	local info = text:match("^ ? ? ?:::+(.-)%s*$")
	if not info then
		return
	end
	info = vim.trim(info):gsub("%s+:::+$", "")
	if info == "" then
		return "close"
	end
	if info:match("^{.*}$") or info:match("^[%w_%-]+$") then
		return "open"
	end
end

function M.parse(lines, mode)
	mode = mode or "notebook"
	local root = { children = {} }
	local stack, number, line = { root }, 0, M.content_start(lines)
	local containers = {}
	local comment = false
	while line <= #lines do
		local text = lines[line]
		if comment or text:match("^%s*<!%-%-") then
			comment = not text:find("-->", 1, true)
			line = line + 1
		else
			local block = M.fence(lines, line)
			local div = mode == "quarto" and div_kind(text)
			if block then
				local language = block.info:match("^{([%a][%w_+%-]*)}%s*$")
				if (mode == "notebook" and block.info ~= "") or (mode == "quarto" and language) then
					number = number + 1
					local preview, label = title(lines, block, mode)
					local cell = entry(
						"Cell " .. number .. (preview ~= "" and ": " .. preview or ""),
						"Function",
						line,
						block.finish
					)
					cell.language, cell.label, cell.body, cell.closed =
						language or block.info, label, block.body, block.closed
					table.insert(stack[#stack].children, cell)
				end
				line = block.finish + 1
			elseif div then
				if div == "open" then
					containers[#containers + 1] = #stack
				elseif #containers > 0 then
					local parent_depth = table.remove(containers)
					while #stack > parent_depth do
						stack[#stack].range["end"].line = line - 2
						table.remove(stack)
					end
				end
				line = line + 1
			else
				local hashes, heading = text:match("^ ? ? ?(#+)%s+(.-)%s*$")
				local heading_end = line
				if not hashes and text:match("%S") and not text:match("^    ") and not text:match("^\t") then
					local underline = lines[line + 1] or ""
					if underline:match("^ ? ? ?=+%s*$") then
						hashes, heading = "#", vim.trim(text)
					elseif underline:match("^ ? ? ?%-+%s*$") then
						hashes, heading = "##", vim.trim(text)
					end
					if hashes then
						heading_end = line + 1
					end
				end
				if hashes and #hashes <= 6 then
					local parent_depth = containers[#containers] or 1
					while #stack > parent_depth and stack[#stack].level >= #hashes do
						stack[#stack].range["end"].line = line - 2
						table.remove(stack)
					end
					heading = heading:gsub("%s+#+%s*$", "")
					if mode == "quarto" then
						heading = heading:gsub("%s+{[^}]*}%s*$", "")
					end
					local node = entry(heading, "Module", line, #lines)
					node.level, node.heading_end = #hashes, heading_end
					table.insert(stack[#stack].children, node)
					table.insert(stack, node)
				end
				line = heading_end + 1
			end
		end
	end
	return root.children
end

function M.cells(tree)
	local cells = {}
	local function visit(nodes)
		for _, node in ipairs(nodes) do
			if node.kind == "Function" then
				cells[#cells + 1] = node
			end
			visit(node.children)
		end
	end
	visit(tree)
	return cells
end

return M
