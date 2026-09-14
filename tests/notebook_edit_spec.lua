describe("Notebook structural edits", function()
	vim.opt.clipboard = ""
	local edit, buf
	local lines = { "```python", "a = 1", "```", "", "```python", "b = 2", "```" }
	before_each(function()
		package.loaded["config.notebook_edit"] = nil
		edit = require("config.notebook_edit")
		buf = vim.api.nvim_create_buf(true, false)
		vim.api.nvim_set_current_buf(buf)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
		vim.cmd("let &undolevels = &undolevels")
	end)
	after_each(function()
		vim.api.nvim_buf_delete(buf, { force = true })
	end)
	it("copies complete cells into a Vim linewise register", function()
		edit.yank(buf, { { 0, 4 } }, "a", false)
		assert.are.same(vim.list_slice(lines, 1, 4), vim.fn.getreg("a", 1, true))
		assert.are.equal("V", vim.fn.getregtype("a"))
	end)
	it("cuts and pastes a cell after its sibling", function()
		edit.yank(buf, { { 0, 4 } }, '"', true)
		assert.are.same(vim.list_slice(lines, 5), vim.api.nvim_buf_get_lines(buf, 0, -1, false))
		edit.paste(buf, 3, '"', 1)
		assert.are.same(
			{ "```python", "b = 2", "```", "", "```python", "a = 1", "```", "" },
			vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		)
	end)
	it("undoes and redoes one structural edit at a time", function()
		edit.yank(buf, { { 0, 4 } }, '"', true)
		edit.paste(buf, 3, '"', 1)
		edit.undo(buf, false)
		assert.are.same(vim.list_slice(lines, 5), vim.api.nvim_buf_get_lines(buf, 0, -1, false))
		edit.undo(buf, false)
		assert.are.same(lines, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
		edit.undo(buf, true)
		assert.are.same(vim.list_slice(lines, 5), vim.api.nvim_buf_get_lines(buf, 0, -1, false))
	end)
	it("deduplicates section and child selections", function()
		assert.are.same(
			{ { 0, 7 } },
			edit.ranges({
				{ range_start = 0, range_end = 6 },
				{ range_start = 0, range_end = 2 },
				{ range_start = 4, range_end = 6 },
			}, 1, 3, lines)
		)
	end)
	it("keeps unselected prose when selecting neighboring cell rows", function()
		local source = { "```python", "a", "```", "Explanation", "```python", "b", "```" }
		assert.are.same(
			{ { 0, 3 }, { 4, 7 } },
			edit.ranges({ { range_start = 0, range_end = 2 }, { range_start = 4, range_end = 6 } }, 1, 2, source)
		)
	end)
	it("preserves saved status on moves but not copies", function()
		local saved = { { cell_type = "code", source = "a = 1", execution_count = 2, outputs = {} } }
		edit.executions(buf, saved)
		edit.yank(buf, { { 0, 4 } }, '"', true)
		edit.paste(buf, 3, '"', 1)
		local moved = edit.executions(buf, saved)
		assert.are.equal(5, moved[1].start_line)
		edit.paste(buf, 8, '"', 1)
		assert.are.equal(1, #edit.executions(buf, saved))
		edit.undo(buf, false)
		edit.undo(buf, false)
		edit.undo(buf, false)
		assert.are.equal(1, edit.executions(buf, saved)[1].start_line)
	end)
	it("tracks saved source locations through ordinary text edits", function()
		edit.executions(buf, { { cell_type = "code", source = "b = 2", execution_count = 1, outputs = {} } })
		vim.api.nvim_buf_set_lines(buf, 0, 0, false, { "# New heading" })
		assert.are.equal(6, edit.executions(buf, {})[1].start_line)
	end)
	it("replaces the empty placeholder when pasting into an empty notebook", function()
		edit.yank(buf, { { 0, 7 } }, '"', true)
		edit.paste(buf, 0, '"', 1)
		assert.are.same(lines, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
	end)
	it("restores saved cell status when undo is issued in the source buffer", function()
		edit.executions(buf, { { cell_type = "code", source = "a = 1", execution_count = 2, outputs = {} } })
		edit.yank(buf, { { 0, 4 } }, '"', true)
		vim.cmd("undo")
		edit.sync(buf)
		assert.are.equal(1, edit.executions(buf, {})[1].start_line)
	end)
	it("does not duplicate saved status after undoing a cut", function()
		edit.executions(buf, { { cell_type = "code", source = "a = 1", execution_count = 2, outputs = {} } })
		edit.yank(buf, { { 0, 4 } }, '"', true)
		edit.undo(buf, false)
		edit.paste(buf, 7, '"', 1)
		assert.are.equal(1, #edit.executions(buf, {}))
	end)
	describe("Molten boundary", function()
		before_each(function()
			vim.cmd([[function! MoltenCellSnapshot(buf)
return deepcopy(g:edit_snapshot)
endfunction
function! MoltenCellRestore(buf, cells)
let g:edit_snapshot = deepcopy(a:cells)
return v:true
endfunction
function! MoltenCellInfo(buf)
return g:edit_info
endfunction]])
			vim.g.edit_snapshot = { { id = 42, start_line = 1, end_line = 1, start_col = 0, end_col = 5 } }
			vim.g.edit_info = {}
		end)
		after_each(function()
			vim.cmd("delfunction! MoltenCellSnapshot\ndelfunction! MoltenCellRestore\ndelfunction! MoltenCellInfo")
		end)
		it("reattaches an executed cut cell only on the first paste", function()
			edit.yank(buf, { { 0, 4 } }, '"', true)
			assert.are.same({}, vim.g.edit_snapshot)
			edit.paste(buf, 3, '"', 1)
			assert.are.same(
				{ { id = 42, start_line = 5, end_line = 5, start_col = 0, end_col = 5 } },
				vim.g.edit_snapshot
			)
			edit.paste(buf, 8, '"', 1)
			assert.are.equal(1, #vim.g.edit_snapshot)
			edit.undo(buf, false)
			edit.undo(buf, false)
			edit.undo(buf, false)
			assert.are.equal(1, vim.g.edit_snapshot[1].start_line)
		end)
		it("rejects cutting a running cell before editing text or registers", function()
			vim.g.edit_info = { { start_line = 1, end_line = 1, status = "running" } }
			vim.fn.setreg("a", "keep")
			assert.has_error(function()
				edit.yank(buf, { { 0, 4 } }, "a", true)
			end, "Cannot cut a queued or running cell")
			assert.are.same(lines, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
			assert.are.equal("keep", vim.fn.getreg("a"))
		end)
		it("does not duplicate an output after undoing its cut", function()
			edit.yank(buf, { { 0, 4 } }, '"', true)
			edit.undo(buf, false)
			edit.paste(buf, 7, '"', 1)
			assert.are.equal(1, #vim.g.edit_snapshot)
		end)
		it("rolls back the text edit when output restoration fails", function()
			vim.cmd([[function! MoltenCellRestore(buf, cells)
if empty(a:cells)
throw 'restore failed'
endif
let g:edit_snapshot=deepcopy(a:cells)
return v:true
endfunction]])
			assert.has_error(function()
				edit.yank(buf, { { 0, 4 } }, '"', true)
			end)
			assert.are.same(lines, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
		end)
		it("loads remote snapshot functions on their first use", function()
			vim.cmd("delfunction MoltenCellSnapshot\ndelfunction MoltenCellRestore")
			local group = vim.api.nvim_create_augroup("NotebookEditLazyRemoteTest", { clear = true })
			vim.api.nvim_create_autocmd("FuncUndefined", {
				group = group,
				pattern = "MoltenCell*",
				callback = function()
					vim.cmd([[function! MoltenCellSnapshot(buf)
return deepcopy(g:edit_snapshot)
endfunction
function! MoltenCellRestore(buf, cells)
let g:edit_snapshot=deepcopy(a:cells)
return v:true
endfunction]])
				end,
			})
			edit.yank(buf, { { 0, 4 } }, '"', true)
			vim.api.nvim_del_augroup_by_id(group)
			assert.are.same({}, vim.g.edit_snapshot)
		end)
		it("forgets detached outputs when their kernel shuts down", function()
			vim.g.edit_snapshot =
				{ { id = 42, kernel_id = "python", start_line = 1, end_line = 1, start_col = 0, end_col = 5 } }
			edit.yank(buf, { { 0, 4 } }, '"', true)
			edit.forget_kernel("python")
			edit.paste(buf, 3, '"', 1)
			assert.are.same({}, vim.g.edit_snapshot)
			edit.undo(buf, false)
			edit.undo(buf, false)
			assert.are.same({}, vim.g.edit_snapshot)
		end)
		it("restores outputs in the notebook window while keeping sidebar focus", function()
			local source_win = vim.api.nvim_get_current_win()
			vim.cmd.vnew()
			local other_win = vim.api.nvim_get_current_win()
			vim.cmd([[function! MoltenCellRestore(buf, cells)
if bufnr() != a:buf
throw 'wrong display buffer'
endif
let g:edit_snapshot=deepcopy(a:cells)
return v:true
endfunction]])
			local ok, err = pcall(edit.yank, buf, { { 0, 4 } }, '"', true)
			local focused = vim.api.nvim_get_current_win()
			vim.api.nvim_win_close(other_win, true)
			vim.api.nvim_set_current_win(source_win)
			assert.is_true(ok, tostring(err))
			assert.are.equal(other_win, focused)
		end)
	end)
end)
