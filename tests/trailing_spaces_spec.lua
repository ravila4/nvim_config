describe("Trailing space matches", function()
	local deferred, defer_fn, first

	local function flush()
		local pending = deferred
		deferred = {}
		for _, callback in ipairs(pending) do
			callback()
		end
	end

	local function groups(win)
		local result = {}
		for _, match in ipairs(vim.fn.getmatches(win)) do
			result[#result + 1] = match.group
		end
		table.sort(result)
		return result
	end

	before_each(function()
		deferred = {}
		defer_fn = vim.defer_fn
		vim.defer_fn = function(callback)
			deferred[#deferred + 1] = callback
		end
		dofile("lua/config/settings.lua")
		vim.cmd("enew!")
		vim.bo.filetype = "lua"
		first = vim.api.nvim_get_current_win()
		flush()
	end)

	after_each(function()
		vim.defer_fn = defer_fn
		vim.api.nvim_del_augroup_by_name("TrailingSpace")
		vim.cmd("only!")
		vim.fn.clearmatches()
	end)

	it("updates the originating window after focus moves", function()
		vim.fn.clearmatches()
		vim.fn.matchadd("ErrorMsg", "keep")
		vim.api.nvim_exec_autocmds("BufEnter", {})
		vim.cmd("vnew")
		vim.bo.filetype = "lua"
		local second = vim.api.nvim_get_current_win()
		vim.fn.matchadd("Search", "keep")
		flush()
		assert.are.same({ "ErrorMsg", "TrailingSpaces" }, groups(first))
		assert.are.same({ "Search", "TrailingSpaces" }, groups(second))
	end)

	it("removes only its own match when a window shows an excluded buffer", function()
		vim.fn.matchadd("ErrorMsg", "keep")
		vim.bo.filetype = "help"
		vim.api.nvim_exec_autocmds("FileType", { pattern = "help" })
		flush()
		assert.are.same({ "ErrorMsg" }, groups(first))
	end)

	it("clears its match when entering an untyped buffer", function()
		vim.cmd("enew!")
		flush()
		assert.are.same({}, groups(first))
	end)

	it("ignores deferred work for closed windows", function()
		vim.cmd("vnew")
		vim.bo.filetype = "lua"
		vim.cmd("close!")
		flush()
		assert.are.same({ "TrailingSpaces" }, groups(first))
	end)

	it("keeps the window match ID synchronized after deleting trailing spaces", function()
		vim.fn.matchadd("ErrorMsg", "keep")
		vim.api.nvim_buf_set_lines(0, 0, -1, false, { "local value = true  " })

		vim.cmd("DeleteTrailingSpaces")
		flush()

		local trailing_match = vim.w[first].trailing_space_match
		local live_ids = {}
		for _, match in ipairs(vim.fn.getmatches(first)) do
			live_ids[match.id] = true
		end
		assert.are.same({ "ErrorMsg", "TrailingSpaces" }, groups(first))
		assert.is_true(live_ids[trailing_match])
	end)
end)
