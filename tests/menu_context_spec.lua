local stub = require("luassert.stub")

describe("Editor context menu", function()
	local spec, opened, buffers, stubs, old_obsidian
	before_each(function()
		buffers, stubs = {}, {}
		old_obsidian = _G.Obsidian
		_G.Obsidian = nil
		package.loaded.menu = {
			open = function(items)
				opened = items
			end,
		}
		spec = require("plugins.menu")[1]
		spec.config()
	end)
	after_each(function()
		for _, s in ipairs(stubs) do
			s:revert()
		end
		vim.cmd("only!")
		for _, buf in ipairs(buffers) do
			vim.api.nvim_buf_delete(buf, { force = true })
		end
		_G.Obsidian = old_obsidian
		package.loaded.menu = nil
	end)

	local function document(path, ft)
		local buf = vim.api.nvim_create_buf(true, false)
		table.insert(buffers, buf)
		vim.api.nvim_set_current_buf(buf)
		vim.api.nvim_buf_set_name(buf, path)
		vim.bo[buf].filetype = ft
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "first", "second", "third" })
		return buf
	end

	local function right_click(win, mode)
		table.insert(
			stubs,
			stub(vim.fn, "getmousepos", function()
				return { winid = win, line = 2, column = 3 }
			end)
		)
		table.insert(
			stubs,
			stub(vim.fn, "mode", function()
				return mode or "n"
			end)
		)
		for _, key in ipairs(spec.keys) do
			if key[1] == "<RightMouse>" then
				key[2]()
			end
		end
	end

	local function has_item(name)
		return vim.iter(opened):any(function(item)
			return item.name:find(name, 1, true) ~= nil
		end)
	end
	for _, case in ipairs({ { "ipynb", "markdown" }, { "qmd", "quarto" } }) do
		it("offers kernel controls for " .. case[1], function()
			local buf = document("/tmp/kernel-menu." .. case[1], case[2])
			vim.cmd("RightClickMenu")
			assert.is_true(has_item("Select Kernel"))
			assert.is_true(has_item("Interrupt Kernel"))
			assert.is_true(has_item("Restart Kernel"))
			local called
			local kernels = require("config.notebook_kernels")
			local pick = kernels.pick
			kernels.pick = function(source)
				vim.schedule(function()
					called = source
				end)
			end
			vim.cmd("vsplit")
			document("/tmp/kernel-other.txt", "text")
			for _, item in ipairs(opened) do
				if item.name == "Select Kernel" then
					item.cmd()
				end
			end
			vim.wait(100, function()
				return called ~= nil
			end)
			kernels.pick = pick
			assert.equal(buf, called)
		end)
	end

	for _, ft in ipairs({ "markdown", "quarto", "python" }) do
		it("targets an inactive " .. ft .. " split before constructing its menu", function()
			local buf = document("/tmp/context-target." .. ft, ft)
			local target = vim.api.nvim_get_current_win()
			vim.cmd("vsplit")
			document("/tmp/context-active.txt", "text")
			right_click(target)
			assert.equal(buf, vim.api.nvim_get_current_buf())
			assert.same({ 2, 2 }, vim.api.nvim_win_get_cursor(target))
			assert.equal(ft ~= "python", has_item("Toggle Markview"))
		end)
	end

	it("preserves the active split and cursor in visual mode", function()
		document("/tmp/context-target.md", "markdown")
		local target = vim.api.nvim_get_current_win()
		vim.cmd("vsplit")
		local active = document("/tmp/context-active.txt", "text")
		right_click(target, "v")
		assert.equal(active, vim.api.nvim_get_current_buf())
		assert.same({ 1, 0 }, vim.api.nvim_win_get_cursor(0))
	end)

	for _, case in ipairs({
		{ "/tmp/notes/note.md", "markdown", true },
		{ "/tmp/notes/sub/note.md", "markdown", true },
		{ "/tmp/notes-other/note.md", "markdown", false },
		{ "/tmp/outside.md", "markdown", false },
		{ "/tmp/outside.qmd", "quarto", false },
		{ "/tmp/outside.ipynb", "markdown", false },
	}) do
		it("scopes image paste for " .. case[1], function()
			_G.Obsidian = { workspaces = { { path = "/tmp/notes" } } }
			document(case[1], case[2])
			vim.cmd("RightClickMenu")
			assert.equal(case[3], has_item("Paste Image (markdown)"))
		end)
	end

	it("omits image paste before Obsidian is loaded", function()
		document("/tmp/outside.md", "markdown")
		vim.cmd("RightClickMenu")
		assert.is_false(has_item("Paste Image (markdown)"))
	end)
end)
