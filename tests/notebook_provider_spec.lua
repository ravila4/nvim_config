vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/outline.nvim")
vim.opt.clipboard = ""
local provider = require("outline.providers.notebook")
require("outline").setup({ providers = { priority = { "notebook" } }, symbol_folding = { autofold_depth = false } })

describe("Notebook outline provider", function()
	local buf
	before_each(function()
		buf = vim.api.nvim_create_buf(true, false)
		vim.api.nvim_set_current_buf(buf)
		vim.bo[buf].filetype = "markdown"
	end)
	after_each(function()
		require("outline").close()
		require("outline").sidebars = {}
		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("selects notebooks by filename rather than markdown filetype", function()
		vim.bo[buf].filetype = "markdown"
		vim.api.nvim_buf_set_name(buf, "/tmp/outline-spec.ipynb")
		assert.is_true(provider.supports_buffer(buf))
		vim.api.nvim_buf_set_name(buf, "/tmp/outline-spec.md")
		assert.is_false(provider.supports_buffer(buf))
	end)

	it("renders cells without an initialized kernel and follows the cursor", function()
		vim.api.nvim_buf_set_name(buf, "/tmp/outline-spec.ipynb")
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "# Title", "```python", "x = 1", "```" })
		require("outline").open()
		assert.is_true(vim.wait(500, function()
			return require("outline").is_open()
		end))
		require("outline").focus_code()
		vim.api.nvim_win_set_cursor(0, { 3, 0 })
		require("outline").follow_cursor()
		local sidebar = require("outline")._get_sidebar()
		assert.are.equal("Cell 1: x = 1", sidebar.items[1].children[1].name)
		assert.are.equal("not run", sidebar.items[1].children[1].detail)
		assert.is_true(sidebar.items[1].children[1].hovered)
	end)

	it("refreshes execution status while focused in the outline", function()
		vim.api.nvim_buf_set_name(buf, "/tmp/outline-spec.ipynb")
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "```python", "x = 1", "```" })
		vim.cmd("function! MoltenCellInfo(buf)\nreturn g:outline_test_info\nendfunction")
		vim.g.outline_test_info =
			{ { start_line = 1, end_line = 1, source = "x = 1", status = "running", old = false } }
		require("outline").open()
		local sidebar = require("outline")._get_sidebar()
		assert.is_true(vim.wait(500, function()
			return sidebar.items[1] ~= nil
		end))
		assert.are.equal("running", sidebar.items[1].detail)
		local outline_win = vim.api.nvim_get_current_win()
		vim.g.outline_test_info = { { start_line = 1, end_line = 1, source = "x = 1", status = "done", old = false } }
		vim.api.nvim_exec_autocmds("User", { pattern = "MoltenCellUpdate", data = { buffers = { buf } } })
		assert.is_true(vim.wait(500, function()
			return sidebar.items[1].detail == ""
		end))
		assert.are.equal(outline_win, vim.api.nvim_get_current_win())
		vim.cmd("delfunction MoltenCellInfo")
	end)
end)

describe("Notebook outline navigation and execution", function()
	local buf, sidebar
	local actions = require("config.notebook_outline_actions")
	local function choose(name)
		for _, item in ipairs(actions.context_menu()) do
			if item.name == name then
				return item.cmd
			end
		end
		error("Missing menu action: " .. name)
	end
	before_each(function()
		buf = vim.api.nvim_create_buf(true, false)
		vim.api.nvim_set_current_buf(buf)
		vim.api.nvim_buf_set_name(buf, "/tmp/outline-actions.ipynb")
		vim.bo[buf].filetype = "markdown"
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
			"# First",
			"```python",
			"a = 1",
			"```",
			"# Second",
			"```python",
			"",
			"b = 2",
			"",
			"```",
			"## Nested",
			"```python",
			"c = 3",
			"```",
			"# Last",
			"```python",
			"d = 4",
			"```",
		})
		require("outline").open()
		sidebar = require("outline")._get_sidebar()
		vim.wait(100)
		vim.g.outline_runs = {}
		vim.g.interrupted_buf = 0
		vim.api.nvim_create_user_command("MoltenInterrupt", function()
			vim.g.interrupted_buf = vim.api.nvim_get_current_buf()
		end, {})
		vim.cmd([[function! MoltenEvaluateRange(first, last)
call add(g:outline_runs, [bufnr(), a:first, a:last])
endfunction]])
	end)
	after_each(function()
		vim.cmd("delfunction MoltenEvaluateRange")
		vim.api.nvim_del_user_command("MoltenInterrupt")
		require("outline").close()
		require("outline").sidebars = {}
		vim.api.nvim_buf_delete(buf, { force = true })
	end)
	it("toggles a group with Space without leaving the outline", function()
		vim.api.nvim_win_set_cursor(sidebar.view.win, { 1, 0 })
		vim.api.nvim_feedkeys(" ", "xt", false)
		assert.are.equal(7, #sidebar.flats)
		assert.are.equal(sidebar.view.win, vim.api.nvim_get_current_win())
		vim.api.nvim_feedkeys(" ", "xt", false)
		assert.are.equal(8, #sidebar.flats)
	end)
	it("jumps to a cell with Enter", function()
		vim.api.nvim_win_set_cursor(sidebar.view.win, { 4, 0 })
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "xt", false)
		assert.are.equal(buf, vim.api.nvim_get_current_buf())
		assert.are.equal(6, vim.api.nvim_win_get_cursor(0)[1])
	end)
	it("expands and collapses every group from the menu", function()
		choose("Collapse All")()
		assert.are.equal(3, #sidebar.flats)
		choose("Expand All")()
		assert.are.equal(8, #sidebar.flats)
	end)
	it("does not offer execution actions for headings", function()
		vim.api.nvim_win_set_cursor(sidebar.view.win, { 1, 0 })
		local names = vim.tbl_map(function(item)
			return item.name
		end, actions.context_menu())
		assert.are.same(
			{ "Select Kernel", "Interrupt Kernel", "Restart Kernel", "separator", "Expand All", "Collapse All" },
			names
		)
	end)
	it("creates a code cell above the selected cell from the menu", function()
		vim.api.nvim_win_set_cursor(sidebar.view.win, { 4, 0 })
		choose("Create Cell Above")()
		assert.are.same({
			"# First",
			"```python",
			"a = 1",
			"```",
			"# Second",
			"",
			"```python",
			"",
			"```",
			"",
			"```python",
			"",
			"b = 2",
			"",
			"```",
			"## Nested",
			"```python",
			"c = 3",
			"```",
			"# Last",
			"```python",
			"d = 4",
			"```",
		}, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
	end)
	it("creates a code cell below the selected cell from the menu", function()
		vim.api.nvim_win_set_cursor(sidebar.view.win, { 4, 0 })
		choose("Create Cell Below")()
		assert.are.same({
			"# First",
			"```python",
			"a = 1",
			"```",
			"# Second",
			"```python",
			"",
			"b = 2",
			"",
			"```",
			"",
			"```python",
			"",
			"```",
			"",
			"## Nested",
			"```python",
			"c = 3",
			"```",
			"# Last",
			"```python",
			"d = 4",
			"```",
		}, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
	end)
	it("separates cell creation actions below the run actions", function()
		vim.api.nvim_win_set_cursor(sidebar.view.win, { 4, 0 })
		local names = vim.tbl_map(function(item)
			return item.name
		end, actions.context_menu())
		assert.are.same({
			"Run Cell",
			"Run All Above",
			"Run All Below",
			"separator",
			"Create Cell Above",
			"Create Cell Below",
			"Open Output",
			"Select Kernel",
			"Interrupt Kernel",
			"Restart Kernel",
			"separator",
			"Expand All",
			"Collapse All",
		}, names)
	end)
	it("interrupts the notebook kernel from a heading while retaining outline focus", function()
		choose("Interrupt Kernel")()
		assert.are.equal(buf, vim.g.interrupted_buf)
		assert.are.equal(sidebar.view.win, vim.api.nvim_get_current_win())
	end)
	it("runs the selected cell in its source buffer with trimmed bounds", function()
		vim.api.nvim_win_set_cursor(sidebar.view.win, { 4, 0 })
		local execute = choose("Run Cell")
		vim.api.nvim_win_set_cursor(sidebar.view.win, { 8, 0 })
		execute()
		assert.are.same({ { buf, 8, 8 } }, vim.g.outline_runs)
		assert.are.equal(sidebar.view.win, vim.api.nvim_get_current_win())
	end)
	it("includes the final line of an unfinished cell", function()
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "```python", "a = 1", "b = 2" })
		vim.api.nvim_win_call(sidebar.code.win, function()
			require("outline").refresh()
		end)
		vim.api.nvim_win_set_cursor(sidebar.view.win, { 1, 0 })
		choose("Run Cell")()
		assert.are.same({ { buf, 2, 3 } }, vim.g.outline_runs)
	end)
	it("skips an empty cell", function()
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "```python", "", "```" })
		vim.api.nvim_win_call(sidebar.code.win, function()
			require("outline").refresh()
		end)
		vim.api.nvim_win_set_cursor(sidebar.view.win, { 1, 0 })
		choose("Run Cell")()
		assert.are.same({}, vim.g.outline_runs)
	end)
	it("runs all above in notebook order including folded groups", function()
		vim.api.nvim_win_set_cursor(sidebar.view.win, { 1, 0 })
		sidebar:_toggle_fold()
		vim.api.nvim_win_set_cursor(sidebar.view.win, { 7, 0 })
		choose("Run All Above")()
		assert.are.same({ { buf, 3, 3 }, { buf, 8, 8 }, { buf, 13, 13 } }, vim.g.outline_runs)
	end)
	it("runs all below in notebook order including folded groups", function()
		vim.api.nvim_win_set_cursor(sidebar.view.win, { 3, 0 })
		sidebar:_toggle_fold()
		vim.api.nvim_win_set_cursor(sidebar.view.win, { 2, 0 })
		choose("Run All Below")()
		assert.are.same({ { buf, 8, 8 }, { buf, 13, 13 }, { buf, 17, 17 } }, vim.g.outline_runs)
	end)
	it("does nothing above the first cell or below the last", function()
		vim.api.nvim_win_set_cursor(sidebar.view.win, { 2, 0 })
		choose("Run All Above")()
		vim.api.nvim_win_set_cursor(sidebar.view.win, { 8, 0 })
		choose("Run All Below")()
		assert.are.same({}, vim.g.outline_runs)
	end)
	it("rejects execution if the source changes after opening the menu", function()
		vim.api.nvim_win_set_cursor(sidebar.view.win, { 2, 0 })
		local execute = choose("Run Cell")
		vim.api.nvim_buf_set_lines(buf, 0, 0, false, { "new text" })
		execute()
		assert.are.same({}, vim.g.outline_runs)
	end)
	it("opens the selected cell output from the outline menu", function()
		local ns = vim.api.nvim_create_namespace("molten-extmarks")
		vim.api.nvim_buf_set_extmark(buf, ns, 2, 0, { virt_lines = { { { "result", "Normal" } } } })
		vim.cmd("function! MoltenOutputText(buf, id)\nreturn 'result'\nendfunction")
		vim.api.nvim_win_set_cursor(sidebar.view.win, { 2, 0 })
		local open = choose("Open Output")
		vim.api.nvim_win_set_cursor(sidebar.view.win, { 4, 0 })
		open()
		assert.are.same({ "result" }, vim.api.nvim_buf_get_lines(0, 0, -1, false))
		vim.fn.maparg("q", "n", false, true).callback()
		assert.are.equal(sidebar.view.win, vim.api.nvim_get_current_win())
		vim.cmd("delfunction MoltenOutputText")
	end)
	it("does not provide a notebook menu in the source buffer", function()
		require("outline").focus_code()
		assert.is_nil(actions.context_menu())
	end)
	for _, command in ipairs({ "RightClickMenu", "ContextMenu" }) do
		it("offers Interrupt Kernel directly in the notebook " .. command, function()
			vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/menu")
			vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/volt")
			require("plugins.menu")[1].config()
			local copy = require("config.notebook_copy")
			local stub = require("luassert.stub")
			local images = stub(copy, "clicked", function()
				return {}
			end)
			local output = stub(copy, "output_text_clicked", function()
				return ""
			end)
			local opened
			local open = stub(require("menu"), "open", function(items)
				opened = items
			end)
			require("outline").focus_code()
			vim.cmd(command)
			open:revert()
			images:revert()
			output:revert()
			local interrupt
			for _, item in ipairs(opened) do
				if item.name == "Interrupt Kernel" then
					interrupt = item.cmd
				end
			end
			assert.is_function(interrupt)
			assert.are.equal("Select Kernel", opened[2].name)
			assert.are.equal("Restart Kernel", opened[4].name)
			assert.are.equal("separator", opened[5].name)
			vim.api.nvim_create_user_command("MoltenRestart", function()
				vim.g.restarted_buf = vim.api.nvim_get_current_buf()
			end, { force = true })
			require("outline").focus_outline()
			opened[4].cmd()
			vim.wait(100)
			assert.are.equal(buf, vim.g.restarted_buf)
			vim.api.nvim_del_user_command("MoltenRestart")
			require("outline").focus_outline()
			interrupt()
			vim.wait(100)
			assert.are.equal(buf, vim.g.interrupted_buf)
		end)
		it("opens the notebook actions through " .. command, function()
			vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/menu")
			vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/volt")
			require("plugins.menu")[1].config()
			local menu = require("menu")
			local opened
			local open = require("luassert.stub")(menu, "open", function(items)
				opened = items
			end)
			vim.api.nvim_win_set_cursor(sidebar.view.win, { 4, 0 })
			vim.cmd(command)
			open:revert()
			local run = vim.iter(opened):find(function(item)
				return item.name == "Run Cell"
			end)
			assert.is_table(run)
			run.cmd()
			vim.wait(100)
			assert.are.same({ { buf, 8, 8 } }, vim.g.outline_runs)
		end)
	end
	it("right-clicks a cell in the outline while the notebook has focus", function()
		local spec = require("plugins.menu")[1]
		spec.config()
		local mouse = require("luassert.stub")(vim.fn, "getmousepos", function()
			return { winid = sidebar.view.win, line = 4, column = 1 }
		end)
		local opened
		local open = require("luassert.stub")(require("menu"), "open", function(items)
			opened = items
		end)
		require("outline").focus_code()
		for _, key in ipairs(spec.keys) do
			if key[1] == "<RightMouse>" then
				key[2]()
			end
		end
		mouse:revert()
		open:revert()
		local run = vim.iter(opened):find(function(item)
			return item.name == "Run Cell"
		end)
		assert.is_table(run)
		run.cmd()
		vim.wait(100)
		assert.are.same({ { buf, 8, 8 } }, vim.g.outline_runs)
	end)
end)

describe("Notebook outline editing keys", function()
	local buf, sidebar
	local function keys(value)
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(value, true, false, true), "xt", false)
		vim.wait(40)
	end
	before_each(function()
		buf = vim.api.nvim_create_buf(true, false)
		vim.api.nvim_set_current_buf(buf)
		vim.api.nvim_buf_set_name(buf, "/tmp/outline-keys.ipynb")
		vim.bo[buf].filetype = "markdown"
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "```python", "a = 1", "```", "", "```python", "b = 2", "```" })
		require("outline").open()
		sidebar = require("outline")._get_sidebar()
		vim.wait(100, function()
			return vim.fn.maparg("p", "n") ~= ""
		end)
	end)
	after_each(function()
		require("outline").close()
		require("outline").sidebars = {}
		vim.api.nvim_buf_delete(buf, { force = true })
	end)
	it("copies and pastes a cell with yy and p", function()
		vim.api.nvim_win_set_cursor(sidebar.view.win, { 1, 0 })
		keys("yy")
		assert.are.same({ "```python", "a = 1", "```", "" }, vim.fn.getreg('"', 1, true))
		keys("p")
		assert.are.same(
			{ "```python", "a = 1", "```", "", "```python", "a = 1", "```", "", "```python", "b = 2", "```" },
			vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		)
		assert.are.equal(sidebar.view.win, vim.api.nvim_get_current_win())
	end)
	it("cuts visual rows and pastes into the empty outline", function()
		keys("ggVjd")
		assert.are.same({ "" }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
		keys("p")
		assert.are.equal(7, vim.api.nvim_buf_line_count(buf))
		keys("u")
		assert.are.same({ "" }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
		keys("<C-r>")
		assert.are.equal(7, vim.api.nvim_buf_line_count(buf))
	end)
	it("supports operator motions", function()
		keys("ggdj")
		assert.are.same({ "" }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
	end)
	it("supports a named register with Y and paste before", function()
		keys('gg"aYj"aP')
		local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		assert.are.same(
			{ "```python", "a = 1", "```", "", "```python", "a = 1", "```", "", "```python", "b = 2", "```" },
			lines
		)
	end)
	it("supports counts for cutting and pasting", function()
		keys("gg2dd")
		assert.are.same({ "" }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
		keys("2p")
		assert.are.equal(14, vim.api.nvim_buf_line_count(buf))
	end)
	it("redraws source outputs once when execution updates from the sidebar", function()
		vim.g.outline_redraws = 0
		vim.g.outline_redraw_buf = 0
		vim.cmd([[function! MoltenUpdateInterface()
let g:outline_redraws+=1
let g:outline_redraw_buf=bufnr()
doautocmd User MoltenCellUpdate
endfunction]])
		vim.api.nvim_exec_autocmds("User", { pattern = "MoltenCellUpdate", data = { buffers = { buf } } })
		vim.wait(100)
		vim.cmd("delfunction MoltenUpdateInterface")
		assert.are.equal(1, vim.g.outline_redraws)
		assert.are.equal(buf, vim.g.outline_redraw_buf)
		assert.are.equal(sidebar.view.win, vim.api.nvim_get_current_win())
	end)
	it("preserves the outline cursor during an execution update", function()
		vim.api.nvim_win_set_cursor(sidebar.view.win, { 2, 0 })
		vim.cmd("function! MoltenCellInfo(buf)\nreturn g:outline_test_info\nendfunction")
		vim.g.outline_test_info = { { start_line = 1, end_line = 1, source = "a = 1", status = "done" } }
		vim.api.nvim_exec_autocmds("User", { pattern = "MoltenCellUpdate" })
		vim.wait(100)
		assert.are.equal(2, vim.api.nvim_win_get_cursor(sidebar.view.win)[1])
		vim.cmd("delfunction MoltenCellInfo")
	end)
	it("defers execution refresh until visual selection ends", function()
		vim.cmd("function! MoltenCellInfo(buf)\nreturn g:outline_test_info\nendfunction")
		vim.g.outline_test_info = { { start_line = 1, end_line = 1, source = "a = 1", status = "done" } }
		vim.cmd.normal({ args = { "V" }, bang = true })
		vim.api.nvim_exec_autocmds("User", { pattern = "MoltenCellUpdate" })
		vim.wait(100)
		assert.are.equal("not run", sidebar.items[1].detail)
		keys("<Esc>")
		assert.is_true(vim.wait(200, function()
			return sidebar.items[1].detail == ""
		end))
		vim.cmd("delfunction MoltenCellInfo")
	end)
end)
