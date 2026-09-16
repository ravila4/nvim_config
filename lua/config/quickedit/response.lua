local M = {}

local shorthands = {
	["/explain"] = "Explain what this code does, step by step.",
	["/simplify"] = "Simplify this code while preserving behavior.",
	["/docstring"] = "Add a docstring to this function.",
	["/types"] = "Add type annotations.",
	["/review"] = "Review this code for bugs, edge cases, and improvements.",
	["/test"] = "Write unit tests for this code.",
}

M.ask_shorthands = { ["/explain"] = true, ["/review"] = true }

function M.shorthand_keys()
	local keys = { "/fix" }
	for shorthand in pairs(shorthands) do
		table.insert(keys, shorthand)
	end
	table.sort(keys)
	return keys
end

function M.is_shorthand(command)
	return command == "/fix" or shorthands[command] ~= nil
end

function M.expand_instruction(instruction, diagnostics)
	local command = instruction:match("^(/[%w_]+)")
	if command == "/fix" then
		local messages = {}
		for _, diagnostic in ipairs(diagnostics) do
			local severity = vim.diagnostic.severity[diagnostic.severity] or "UNKNOWN"
			local source = diagnostic.source and ("[" .. diagnostic.source .. "] ") or ""
			table.insert(
				messages,
				string.format("- %s%s: %s (line %d)", source, severity, diagnostic.message, diagnostic.lnum + 1)
			)
		end

		if #messages == 0 then
			return "Review this code for potential issues and fix any problems."
		end

		local expanded = "Fix the following diagnostics:\n" .. table.concat(messages, "\n")
		local extra = instruction:sub(#command + 1):gsub("^%s+", "")
		if extra ~= "" then
			expanded = expanded .. "\n\nAdditional context: " .. extra
		end
		return expanded
	end

	if command and shorthands[command] then
		local extra = instruction:sub(#command + 1):gsub("^%s+", "")
		if extra ~= "" then
			return shorthands[command] .. " " .. extra
		end
		return shorthands[command]
	end

	return instruction
end

function M.parse(value)
	local text_response = value:match("<response>(.-)</response>")
	if text_response then
		return { mode = "ask", text = text_response:gsub("^%s+", ""):gsub("%s+$", "") }
	end

	local code = value:match("<code>(.-)</code>")
	local summary = value:match("<summary>(.-)</summary>")
	if not code then
		code = value:match("```%w*\n(.-)\n```")
	end

	if code then
		code = code:match("```%w*\n(.-)\n```") or code
		code = code:gsub("^%s*\n", ""):gsub("\n%s*$", "")
		if summary then
			summary = summary:gsub("^%s+", ""):gsub("%s+$", "")
		end
		return { mode = "edit", code = code, summary = summary or "Changes applied" }
	end

	return { mode = "ask", text = value }
end

return M
