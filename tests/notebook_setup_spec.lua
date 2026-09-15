local stub = require("luassert.stub")

describe("Delayed notebook rendering", function()
	local buffers, deferred, scheduled, stubs, rendered, highlighted, autocmds
	before_each(function()
		buffers, deferred, scheduled, stubs, rendered, highlighted = {}, {}, {}, {}, {}, {}
		package.loaded.jupytext = { setup = function() end, write_notebook = function() end }
		package.loaded.markview = {}
		table.insert(
			stubs,
			stub(vim, "defer_fn", function(fn)
				table.insert(deferred, fn)
			end)
		)
		table.insert(
			stubs,
			stub(vim, "schedule", function(fn)
				table.insert(scheduled, fn)
			end)
		)
		table.insert(
			stubs,
			stub(vim.treesitter, "start", function(buf)
				table.insert(highlighted, buf or vim.api.nvim_get_current_buf())
			end)
		)
		vim.api.nvim_create_user_command("Markview", function()
			table.insert(rendered, vim.api.nvim_get_current_buf())
		end, { nargs = "+" })
		local before = {}
		for _, event in ipairs(vim.api.nvim_get_autocmds({})) do
			if event.id then
				before[event.id] = true
			end
		end
		for _, spec in ipairs(require("plugins.jupyter")) do
			if spec[1] == "goerz/jupytext.nvim" then
				spec.config()
			end
		end
		autocmds = {}
		for _, event in ipairs(vim.api.nvim_get_autocmds({})) do
			if event.id and not before[event.id] then
				autocmds[event.id] = true
			end
		end
	end)
	after_each(function()
		for _, s in ipairs(stubs) do
			s:revert()
		end
		for id in pairs(autocmds) do
			vim.api.nvim_del_autocmd(id)
		end
		for _, buf in ipairs(buffers) do
			if vim.api.nvim_buf_is_valid(buf) then
				vim.api.nvim_buf_delete(buf, { force = true })
			end
		end
		vim.api.nvim_del_user_command("Markview")
		package.loaded.jupytext, package.loaded.markview = nil, nil
	end)

	local function buffer(path)
		local buf = vim.api.nvim_create_buf(true, false)
		table.insert(buffers, buf)
		vim.api.nvim_set_current_buf(buf)
		vim.api.nvim_buf_set_name(buf, path)
		vim.bo[buf].filetype = "markdown"
		return buf
	end

	it("renders the notebook after focus moves to another Markdown buffer", function()
		local notebook = buffer("/tmp/delayed-notebook.ipynb")
		vim.api.nvim_exec_autocmds("BufRead", { buffer = notebook })
		local other = buffer("/tmp/delayed-other.md")
		deferred[1]()
		assert.same({ notebook }, highlighted)
		assert.same({ notebook }, rendered)
		assert.equal(other, vim.api.nvim_get_current_buf())
	end)

	it("ignores a deleted notebook in deferred rendering and output import", function()
		local notebook = buffer("/tmp/deleted-notebook.ipynb")
		vim.api.nvim_exec_autocmds("BufRead", { buffer = notebook })
		buffer("/tmp/delayed-other.md")
		vim.api.nvim_buf_delete(notebook, { force = true })
		deferred[1]()
		for _, fn in ipairs(scheduled) do
			fn()
		end
		assert.same({}, highlighted)
		assert.same({}, rendered)
	end)

	it("skips rendering if the notebook filetype changes before the callback", function()
		local notebook = buffer("/tmp/changed-notebook.ipynb")
		vim.api.nvim_exec_autocmds("BufRead", { buffer = notebook })
		vim.bo[notebook].filetype = "text"
		buffer("/tmp/delayed-other.md")
		deferred[1]()
		assert.same({}, highlighted)
		assert.same({}, rendered)
	end)
end)
