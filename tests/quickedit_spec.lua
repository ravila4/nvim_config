local provider = require("config.quickedit.provider")
local response = require("config.quickedit.response")

describe("Quick Edit response handling", function()
	it("parses a structured code edit", function()
		assert.are.same(
			{
				mode = "edit",
				code = "local answer = 42",
				summary = "Use the answer",
			},
			response.parse([[<code>
local answer = 42
</code>
<summary> Use the answer </summary>]])
		)
	end)

	it("removes a nested Markdown fence from edited code", function()
		local result = response.parse([[<code>```lua
local answer = 42
```</code>]])
		assert.are.equal("edit", result.mode)
		assert.are.equal("local answer = 42", result.code)
	end)

	it("treats an unstructured response as an answer", function()
		assert.are.same({ mode = "ask", text = "This code returns 42." }, response.parse("This code returns 42."))
	end)

	it("expands a shorthand with additional context", function()
		assert.are.equal(
			"Simplify this code while preserving behavior. Keep the public name.",
			response.expand_instruction("/simplify Keep the public name.", {})
		)
	end)

	it("formats diagnostics selected for a fix", function()
		assert.are.equal(
			"Fix the following diagnostics:\n- [Lua LS] ERROR: Undefined global (line 7)",
			response.expand_instruction("/fix", {
				{ lnum = 6, severity = vim.diagnostic.severity.ERROR, source = "Lua LS", message = "Undefined global" },
			})
		)
	end)
end)

describe("Quick Edit providers", function()
	it("builds an LM Studio request whose body is sent over stdin", function()
		local request = provider.build_request("lmstudio", "qwen", "Change this")
		assert.are.same({
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
		}, request.cmd)
		assert.are.same({
			model = "qwen",
			messages = { { role = "user", content = "Change this" } },
			stream = false,
			max_tokens = 4096,
		}, vim.json.decode(request.stdin))
	end)

	it("builds a Claude CLI request", function()
		assert.are.same({
			cmd = { "claude", "-p", "Explain this", "--model", "haiku" },
		}, provider.build_request("claude", "haiku", "Explain this"))
	end)

	it("decodes LM Studio content", function()
		assert.are.same(
			{ content = "updated", degraded = false },
			provider.decode_lmstudio(vim.json.encode({
				choices = { { message = { content = "updated" }, finish_reason = "stop" } },
			}))
		)
	end)

	it("falls back to reasoning content", function()
		assert.are.same(
			{ content = "analysis", degraded = true },
			provider.decode_lmstudio(vim.json.encode({
				choices = { { message = { content = "", reasoning_content = "analysis" }, finish_reason = "length" } },
			}))
		)
	end)

	it("rejects a malformed LM Studio response", function()
		local result, err = provider.decode_lmstudio("not json")
		assert.is_nil(result)
		assert.are.equal("invalid_json", err)
	end)
end)
