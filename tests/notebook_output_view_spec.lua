describe("Notebook output viewer", function()
	local source, origin, ns
	before_each(function()
		source = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_set_current_buf(source)
		origin = vim.api.nvim_get_current_win()
		vim.api.nvim_buf_set_lines(
			source,
			0,
			-1,
			false,
			{ "# Group", "```python", "print(1)", "```", "", "```python", "print(2)", "```" }
		)
		ns = vim.api.nvim_create_namespace("molten-extmarks")
		vim.api.nvim_buf_set_extmark(source, ns, 2, 0, { id = 11, virt_lines = { { { "preview", "Normal" } } } })
		vim.api.nvim_buf_set_extmark(source, ns, 6, 0, { id = 12, virt_lines = { { { "preview", "Normal" } } } })
		vim.cmd(
			"function! MoltenOutputText(buf, id)\nreturn a:id == 11 ? repeat('wide ', 100) . \"\\nsecond\" : 'other'\nendfunction"
		)
	end)
	after_each(function()
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			if vim.api.nvim_win_get_config(win).relative ~= "" then
				vim.api.nvim_win_close(win, true)
			end
		end
		vim.api.nvim_buf_delete(source, { force = true })
		vim.cmd("delfunction MoltenOutputText")
	end)
	it("opens full text in an unwrapped scratch buffer", function()
		require("config.notebook_output_view").open(source, 2)
		assert.are.same({ string.rep("wide ", 100), "second" }, vim.api.nvim_buf_get_lines(0, 0, -1, false))
		assert.is_false(vim.wo.wrap)
		assert.is_false(vim.bo.modifiable)
		assert.are.equal("nofile", vim.bo.buftype)
		vim.cmd("normal! 20zl")
		assert.is_true(vim.fn.winsaveview().leftcol > 0)
	end)
	it("does not borrow the following cell output", function()
		vim.api.nvim_buf_del_extmark(source, ns, 11)
		require("config.notebook_output_view").open(source, 3)
		assert.are.equal(source, vim.api.nvim_get_current_buf())
	end)
	it("does not open output from a heading", function()
		require("config.notebook_output_view").open(source, 1)
		assert.are.equal(source, vim.api.nvim_get_current_buf())
	end)
	it("selects the requested cell", function()
		require("config.notebook_output_view").open(source, 7)
		assert.are.same({ "other" }, vim.api.nvim_buf_get_lines(0, 0, -1, false))
	end)
	for _, key in ipairs({ "q", "<Esc>" }) do
		it("closes with " .. key .. " and wipes the scratch buffer", function()
			require("config.notebook_output_view").open(source, 3)
			local buf = vim.api.nvim_get_current_buf()
			vim.fn.maparg(key, "n", false, true).callback()
			assert.are.equal(origin, vim.api.nvim_get_current_win())
			assert.is_false(vim.api.nvim_buf_is_valid(buf))
		end)
	end
end)
