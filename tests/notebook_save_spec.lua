describe("Notebook saving after structural edits", function()
	local edit, save, buf, original
	before_each(function()
		vim.opt.clipboard = ""
		package.loaded["config.notebook_edit"] = nil
		edit = require("config.notebook_edit")
		save = require("config.notebook_save")
		buf = vim.api.nvim_create_buf(true, false)
		vim.api.nvim_set_current_buf(buf)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "```python", "a = 1", "```" })
		original = {
			id = "original",
			cell_type = "code",
			source = "a = 1",
			metadata = { tags = { "keep" } },
			execution_count = 3,
			outputs = { { output_type = "stream", name = "stdout", text = "saved\n" } },
		}
		edit.executions(buf, { original })
	end)
	after_each(function()
		vim.api.nvim_buf_delete(buf, { force = true })
	end)
	local function converted()
		return {
			cells = {
				{ cell_type = "code", source = "a = 1", metadata = {}, id = "new1" },
				{ cell_type = "code", source = "a = 1", metadata = {}, id = "new2" },
			},
			metadata = {},
			nbformat = 4,
			nbformat_minor = 5,
		}
	end
	it("keeps a copy before the original unexecuted when saving", function()
		edit.yank(buf, { { 0, 3 } }, '"', false)
		edit.paste(buf, 0, '"', 1)
		local notebook = save.reconcile(buf, converted(), { cells = { original } })
		assert.are.same({}, notebook.cells[1].outputs)
		assert.are.equal(vim.NIL, notebook.cells[1].execution_count)
		assert.are.equal("original", notebook.cells[2].id)
		assert.are.same(original.outputs, notebook.cells[2].outputs)
		assert.are.same(original.metadata, notebook.cells[2].metadata)
	end)
	it("uses the latest saved outputs for the original identity", function()
		edit.yank(buf, { { 0, 3 } }, '"', false)
		edit.paste(buf, 0, '"', 1)
		local latest = vim.deepcopy(original)
		latest.execution_count = 9
		local notebook = save.reconcile(buf, converted(), { cells = { latest } })
		assert.are.equal(9, notebook.cells[2].execution_count)
	end)
	it("refuses to save if Markdown conversion disagrees about code cells", function()
		assert.has_error(function()
			save.reconcile(buf, { cells = {} }, { cells = { original } })
		end)
	end)
	it("retains separate identities for originally identical cells", function()
		edit.reset(buf)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "```python", "a = 1", "```", "", "```python", "a = 1", "```" })
		local second = vim.deepcopy(original)
		second.id = "second"
		second.execution_count = 4
		edit.executions(buf, { original, second })
		local notebook = save.reconcile(buf, converted(), { cells = { original, second } })
		assert.are.equal(3, notebook.cells[1].execution_count)
		assert.are.equal(4, notebook.cells[2].execution_count)
	end)
	it("preserves metadata for an original unexecuted cell", function()
		edit.reset(buf)
		original.execution_count = vim.NIL
		original.outputs = {}
		edit.executions(buf, { original })
		local notebook = converted()
		table.remove(notebook.cells)
		notebook = save.reconcile(buf, notebook, { cells = { original } })
		assert.are.equal("original", notebook.cells[1].id)
		assert.are.same(original.metadata, notebook.cells[1].metadata)
	end)
	it("preserves embedded Markdown attachments when a section changes", function()
		local markdown = {
			cell_type = "markdown",
			source = "![plot](attachment:plot.png)",
			metadata = {},
			attachments = { ["plot.png"] = { ["image/png"] = "aGVsbG8=" } },
		}
		local notebook = converted()
		table.remove(notebook.cells)
		table.insert(
			notebook.cells,
			1,
			{ cell_type = "markdown", source = "# New title\n\n![plot](attachment:plot.png)", metadata = {} }
		)
		local result = save.reconcile(buf, notebook, { cells = { markdown, original } })
		assert.are.same(markdown.attachments, result.cells[1].attachments)
	end)
	it("rejects ambiguous embedded attachments instead of replacing an image", function()
		local one = {
			cell_type = "markdown",
			source = "![plot](attachment:plot.png)",
			attachments = { ["plot.png"] = { ["image/png"] = "first" } },
		}
		local two = vim.deepcopy(one)
		two.attachments["plot.png"]["image/png"] = "second"
		local notebook = converted()
		table.remove(notebook.cells)
		table.insert(notebook.cells, 1, { cell_type = "markdown", source = one.source, metadata = {} })
		assert.has_error(function()
			save.reconcile(buf, notebook, { cells = { one, two, original } })
		end)
	end)
	it("assigns a fresh identity when copied text contains the original ID", function()
		edit.yank(buf, { { 0, 3 } }, '"', false)
		edit.paste(buf, 0, '"', 1)
		local notebook = converted()
		notebook.cells[1].id = "original"
		notebook.cells[2].id = "original"
		local result = save.reconcile(buf, notebook, { cells = { original } })
		assert.are_not.equal(result.cells[1].id, result.cells[2].id)
	end)
	it("saves through Jupytext without assigning results to the copy", function()
		vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/jupytext.nvim")
		local jupytext = require("jupytext")
		jupytext.setup({ format = "md:markdown", async_write = false })
		save.setup()
		local path = vim.fn.tempname() .. ".ipynb"
		vim.fn.writefile({
			vim.json.encode({
				cells = { original },
				metadata = {
					custom = "keep",
					kernelspec = {
						name = "python3",
						display_name = "Python 3",
						language = "python",
					},
				},
				nbformat = 4,
				nbformat_minor = 5,
			}),
		}, path)
		vim.cmd.edit(path)
		local notebook_buf = vim.api.nvim_get_current_buf()
		edit.executions(notebook_buf, { original })
		local source = vim.api.nvim_buf_get_lines(notebook_buf, 0, -1, false)
		local first
		for index, line in ipairs(source) do
			if line:match("^```python") then
				first = index - 1
			end
		end
		assert.is_not_nil(first)
		edit.yank(notebook_buf, { { first, first + 3 } }, '"', false)
		edit.paste(notebook_buf, first, '"', 1)
		vim.cmd.write()
		local result = vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
		vim.api.nvim_buf_delete(notebook_buf, { force = true })
		vim.fn.delete(path)
		assert.are.equal(vim.NIL, result.cells[1].execution_count)
		assert.are.equal("original", result.cells[2].id)
		assert.are.equal(3, result.cells[2].execution_count)
		assert.are.equal("keep", result.metadata.custom)
	end)
	it("tracks newly saved copies by their own identity on later saves", function()
		edit.yank(buf, { { 0, 3 } }, '"', false)
		edit.paste(buf, 0, '"', 1)
		local notebook, bindings = save.reconcile(buf, converted(), { cells = { original } })
		edit.accept_saved(buf, bindings)
		notebook.cells[1].execution_count = 8
		notebook.cells[1].outputs = { { output_type = "stream", name = "stdout", text = "copy output" } }
		local later = save.reconcile(buf, converted(), notebook)
		assert.are.equal(8, later.cells[1].execution_count)
		assert.are.equal(3, later.cells[2].execution_count)
	end)
	it("refuses to overwrite a notebook changed on disk", function()
		vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/jupytext.nvim")
		local path = vim.fn.tempname() .. ".ipynb"
		local json = vim.json.encode({ cells = { original }, metadata = {}, nbformat = 4, nbformat_minor = 5 })
		vim.fn.writefile({ json }, path)
		vim.api.nvim_buf_set_name(buf, path)
		vim.b[buf].mtime = { sec = 0, nsec = 0 }
		assert.has_error(function()
			save.write(buf, path)
		end, "Notebook changed on disk; reload it before saving")
		assert.are.same({ json }, vim.fn.readfile(path))
		vim.fn.delete(path)
	end)
end)
