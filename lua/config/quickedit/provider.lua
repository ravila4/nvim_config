local M = {}

function M.build_request(provider, model, prompt)
	if provider == "claude" then
		return { cmd = { "claude", "-p", prompt, "--model", model } }
	end

	return {
		cmd = {
			"curl",
			"-s",
			"--max-time",
			"120",
			"-H",
			"Content-Type: application/json",
			"-X",
			"POST",
			"http://localhost:1234/v1/chat/completions",
			"-d",
			"@-",
		},
		stdin = vim.json.encode({
			model = model,
			messages = { { role = "user", content = prompt } },
			stream = false,
			max_tokens = 4096,
		}),
	}
end

function M.decode_lmstudio(raw)
	local ok, parsed = pcall(vim.json.decode, raw)
	if not ok or type(parsed) ~= "table" or type(parsed.choices) ~= "table" or not parsed.choices[1] then
		return nil, "invalid_json"
	end

	local choice = parsed.choices[1]
	local message = choice.message or {}
	if message.content and message.content ~= "" then
		return { content = message.content, degraded = false }
	end
	if message.reasoning_content and message.reasoning_content ~= "" then
		return { content = message.reasoning_content, degraded = true }
	end
	return nil, "empty_response", choice.finish_reason
end

return M
