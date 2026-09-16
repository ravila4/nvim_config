vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/outline.nvim")
local outline = require("outline")
outline.setup({ providers = { priority = { "notebook", "document" } }, symbol_folding = { autofold_depth = false } })

describe("Document outline provider", function()
	local buf
	before_each(function()
		buf = vim.api.nvim_create_buf(true, false)
		vim.api.nvim_set_current_buf(buf)
	end)
	after_each(function()
		outline.close()
		outline.sidebars = {}
		vim.api.nvim_buf_delete(buf, { force = true })
	end)
	local function open(ext, ft, lines)
		vim.api.nvim_buf_set_name(buf, "/tmp/document-outline." .. ext)
		vim.bo[buf].filetype = ft
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
		outline.open()
		vim.wait(100)
		return outline._get_sidebar()
	end
	it("renders Markdown headings only", function()
		local view = open("md", "markdown", { "# Title", "```python", "x=1", "```", "## Child" })
		assert.are.equal("document", view.provider.name)
		assert.are.equal(2, #view.flats)
		assert.are.equal("Child", view.flats[2].name)
	end)
	for _, case in ipairs({ { "ipynb", "markdown" }, { "qmd", "quarto" } }) do
		it("offers kernel controls before execution in a " .. case[1] .. " outline", function()
			open(case[1], case[2], { "# Title" })
			local items = require("config.notebook_outline_actions").context_menu()
			local actions = {}
			for _, item in ipairs(items) do
				actions[item.name] = item.cmd
			end
			assert.is_function(actions["Select Kernel"])
			assert.is_function(actions["Interrupt Kernel"])
			assert.is_function(actions["Restart Kernel"])
			local called
			local kernels = require("config.notebook_kernels")
			local pick = kernels.pick
			kernels.pick = function(source)
				vim.schedule(function()
					called = source
				end)
			end
			actions["Select Kernel"]()
			vim.wait(100, function()
				return called ~= nil
			end)
			kernels.pick = pick
			assert.equal(buf, called)
		end)
	end
	it("highlights failed cell markers without duplicating window matches", function()
		local view = open("qmd", "quarto", { "```{python}", "1/0", "```" })
		require("config.notebook_outline_actions").attach()
		require("config.notebook_outline_actions").attach()
		local matches = vim.api.nvim_win_call(view.view.win, vim.fn.getmatches)
		local errors = vim.tbl_filter(function(match)
			return match.group == "DiagnosticError"
		end, matches)
		assert.are.equal(1, #errors)
		assert.are.equal("✗", vim.fn.matchstr("  ✗ Cell 1: 1/0", errors[1].pattern))
		assert.are.equal("", vim.fn.matchstr("  ✓ Cell 1: ok", errors[1].pattern))
	end)
	it("refreshes notebooks after the document provider has loaded", function()
		vim.api.nvim_buf_set_name(buf, "/tmp/document-transition.ipynb")
		vim.bo[buf].filetype = "markdown"
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "# Before" })
		outline.open()
		vim.wait(100)
		local view = outline._get_sidebar()
		vim.api.nvim_buf_set_lines(buf, 0, 1, false, { "# After" })
		vim.api.nvim_exec_autocmds("TextChanged", { buffer = buf })
		assert.is_true(vim.wait(500, function()
			return view.flats[1].name == "After"
		end))
	end)
	it("renders Quarto cells then refreshes while outline has focus", function()
		local view = open("qmd", "quarto", { "# Title", "```{python}", "x=1", "```" })
		assert.are.equal("Cell 1: x=1", view.flats[2].name)
		vim.api.nvim_buf_set_lines(buf, 2, 3, false, { "x=2" })
		vim.api.nvim_exec_autocmds("TextChanged", { buffer = buf })
		assert.is_true(vim.wait(500, function()
			return view.flats[2].name == "Cell 1: x=2"
		end))
		assert.are.equal(view.view.win, vim.api.nvim_get_current_win())
	end)
	it("offers Quarto creation and edits cells through outline mappings", function()
		local view = open("qmd", "quarto", { "# Title", "```{r}", "plot(x)", "```" })
		vim.api.nvim_win_set_cursor(view.view.win, { 2, 0 })
		local menu = require("config.notebook_outline_actions").context_menu()
		assert.is_not_nil(menu)
		local create
		for _, item in ipairs(menu) do
			if item.name == "Create Cell Below" then
				create = item.cmd
			end
		end
		assert.is_not_nil(create)
		create()
		assert.are.equal(3, #view.flats)
		assert.are.equal("```{r}", vim.api.nvim_buf_get_lines(buf, 5, 6, false)[1])
		vim.api.nvim_win_set_cursor(view.view.win, { 2, 0 })
		vim.api.nvim_feedkeys("dd", "xt", false)
		assert.are.equal(2, #view.flats)
		vim.api.nvim_feedkeys("u", "xt", false)
		assert.are.equal(3, #view.flats)
	end)
	it("does not expose cell editing in Markdown", function()
		local view = open("md", "markdown", { "# Title", "text" })
		local items = require("config.notebook_outline_actions").context_menu()
		assert.are.same(
			{ "Expand All", "Collapse All" },
			vim.tbl_map(function(item)
				return item.name
			end, items)
		)
		for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(view.view.buf, "n")) do
			assert.is_not.equal("dd", mapping.lhs)
		end
	end)
	it("rejects a captured creation menu after source changes", function()
		local view = open("qmd", "quarto", { "```{python}", "x=1", "```" })
		local items = require("config.notebook_outline_actions").context_menu()
		local create
		for _, item in ipairs(items or {}) do
			if item.name == "Create Cell Below" then
				create = item.cmd
			end
		end
		assert.is_not_nil(create)
		vim.api.nvim_buf_set_lines(buf, 0, 0, false, { "# New" })
		create()
		assert.are.equal(4, vim.api.nvim_buf_line_count(buf))
		assert.are.equal(view.view.win, vim.api.nvim_get_current_win())
	end)
	it("rejects edits from stale outline rows", function()
		local view = open("qmd", "quarto", { "```{python}", "x=1", "```" })
		vim.api.nvim_buf_set_lines(buf, 0, 0, false, { "# New" })
		vim.api.nvim_feedkeys("dd", "xt", false)
		assert.are.equal(4, vim.api.nvim_buf_line_count(buf))
		assert.are.equal(view.view.win, vim.api.nvim_get_current_win())
	end)
	it("does not let one tab refresh validate another tab's old cell ranges", function()
		local first = open("qmd", "quarto", { "```{python}", "first()", "```", "```{python}", "second()", "```" })
		vim.cmd("tabnew")
		vim.api.nvim_set_current_buf(buf)
		outline.open()
		vim.wait(100)
		local second = outline._get_sidebar()
		vim.api.nvim_buf_set_lines(buf, 0, 0, false, { "# New heading", "" })
		local expected = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		vim.api.nvim_win_call(first.code.win, function()
			outline.refresh()
		end)
		vim.api.nvim_set_current_win(second.view.win)
		vim.api.nvim_win_set_cursor(second.view.win, { 1, 0 })
		vim.fn.setreg('"', "untouched")
		for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(second.view.buf, "n")) do
			if mapping.lhs == "dd" then
				mapping.callback()
				break
			end
		end
		local result, register = vim.api.nvim_buf_get_lines(buf, 0, -1, false), vim.fn.getreg('"')
		outline.close()
		-- Drain outline.nvim's debounced refresh before destroying its tab.
		vim.wait(150)
		vim.cmd("tabclose!")
		assert.are.same(expected, result)
		assert.are.equal("untouched", register)
	end)
	it("cuts a callout heading without taking its enclosing delimiters", function()
		local source = { "::: {.callout-note}", "## Note", "Keep this note", ":::", "# Next", "Next content" }
		local view = open("qmd", "quarto", source)
		vim.api.nvim_win_set_cursor(view.view.win, { 1, 0 })
		vim.api.nvim_feedkeys('"add', "xt", false)
		assert.are.same({ "## Note", "Keep this note" }, vim.fn.getreg("a", 1, true))
		assert.are.same(
			{ "::: {.callout-note}", ":::", "# Next", "Next content" },
			vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		)
		vim.api.nvim_feedkeys("u", "xt", false)
		assert.are.same(source, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
	end)
	it("copies and pastes callout contents before the closing delimiter", function()
		local view = open("qmd", "quarto", { "::: {.callout-note}", "## Note", "text", ":::" })
		vim.api.nvim_win_set_cursor(view.view.win, { 1, 0 })
		vim.api.nvim_feedkeys('"ayy"ap', "xt", false)
		assert.are.same(
			{ "::: {.callout-note}", "## Note", "text", "", "## Note", "text", "", ":::" },
			vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		)
	end)
	it("restores live outputs on native undo after closing the Quarto outline", function()
		vim.cmd([[function! MoltenCellSnapshot(buf)
return deepcopy(g:qmd_snapshot)
endfunction
function! MoltenCellRestore(buf, cells)
let g:qmd_snapshot = deepcopy(a:cells)
return v:true
endfunction]])
		vim.g.qmd_snapshot = { { id = 42, start_line = 1, end_line = 1 } }
		local ok, err = pcall(function()
			open("qmd", "quarto", { "```{python}", "x=1", "```" })
			vim.api.nvim_feedkeys("dd", "xt", false)
			assert.are.same({}, vim.g.qmd_snapshot)
			outline.close()
			vim.api.nvim_set_current_buf(buf)
			vim.cmd("undo")
			vim.api.nvim_exec_autocmds("TextChanged", { buffer = buf })
			assert.is_true(vim.wait(500, function()
				return #vim.g.qmd_snapshot == 1
			end))
			assert.are.equal(1, vim.g.qmd_snapshot[1].start_line)
		end)
		vim.cmd("delfunction! MoltenCellSnapshot\ndelfunction! MoltenCellRestore")
		assert.is_true(ok, tostring(err))
	end)
end)
