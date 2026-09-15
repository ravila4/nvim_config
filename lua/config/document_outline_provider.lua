local M = {}
local sources = {}
local pending = false
local saved = {}

local function symbols(buf)
	local mode = require("config.document_outline").format(buf)
	if mode == "markdown" then
		return require("config.document_outline").parse(vim.api.nvim_buf_get_lines(buf, 0, -1, false), mode)
	end
	require("config.notebook_edit").sync(buf)
	local executions = require("config.notebook_edit").live_info(buf)
	local path = vim.api.nvim_buf_get_name(buf)
	if mode == "notebook" and not saved[path] then
		local ok, notebook = pcall(function()
			return vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
		end)
		saved[path] = ok and notebook.cells or {}
	end
	vim.list_extend(executions, require("config.notebook_edit").executions(buf, saved[path] or {}))
	return require("config.notebook_outline").symbols(
		vim.api.nvim_buf_get_lines(buf, 0, -1, false),
		executions,
		{},
		mode
	)
end

function M.request_symbols(callback, opts)
	local buf = vim.api.nvim_get_current_buf()
	local result = symbols(buf)
	sources[vim.api.nvim_get_current_tabpage()] = {
		buf = buf,
		win = vim.api.nvim_get_current_win(),
		symbols = result,
		tick = vim.api.nvim_buf_get_changedtick(buf),
	}
	callback(vim.deepcopy(result), opts)
	vim.schedule(function()
		require("config.notebook_outline_actions").attach()
	end)
end

function M.is_current(view)
	local source = sources[vim.api.nvim_win_get_tabpage(view.view.win)]
	return source ~= nil
		and source.buf == view.code.buf
		and source.win == view.code.win
		and source.tick == vim.api.nvim_buf_get_changedtick(view.code.buf)
end

local function refresh()
	if pending then
		return
	end
	pending = true
	vim.schedule(function()
		pending = false
		local mode = vim.api.nvim_get_mode().mode
		if mode:match("^[vV\22]") or mode:match("^no") then
			return
		end
		for tab, source in pairs(sources) do
			if not vim.api.nvim_tabpage_is_valid(tab) or not vim.api.nvim_win_is_valid(source.win) then
				sources[tab] = nil
			elseif vim.api.nvim_win_get_buf(source.win) == source.buf then
				vim.api.nvim_win_call(source.win, function()
					if source.redraw then
						source.redraw = nil
						require("config.notebook_edit").redraw()
					end
					if
						require("outline").is_open()
						and (
							source.tick ~= vim.api.nvim_buf_get_changedtick(source.buf)
							or not vim.deep_equal(source.symbols, symbols(source.buf))
						)
					then
						local sidebar = require("outline")._get_sidebar()
						local cursor = vim.api.nvim_win_get_cursor(sidebar.view.win)
						require("outline").refresh()
						vim.api.nvim_win_set_cursor(
							sidebar.view.win,
							{ math.min(cursor[1], math.max(1, #sidebar.flats)), cursor[2] }
						)
					end
				end)
			end
		end
	end)
end

local group = vim.api.nvim_create_augroup("NotebookOutline", { clear = true })
vim.api.nvim_create_autocmd("User", {
	group = group,
	pattern = { "MoltenCellUpdate", "MoltenDeinitPost" },
	callback = function(event)
		if event.match == "MoltenDeinitPost" and event.data then
			require("config.notebook_edit").forget_kernel(event.data.kernel_id)
		end
		if event.match == "MoltenCellUpdate" and vim.bo.filetype == "Outline" then
			for _, source in pairs(sources) do
				if
					vim.api.nvim_get_current_buf() ~= source.buf
					and event.data
					and vim.tbl_contains(event.data.buffers or {}, source.buf)
				then
					source.redraw = true
				end
			end
		end
		refresh()
	end,
})
vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
	group = group,
	callback = function(event)
		local mode = require("config.document_outline").format(event.buf)
		if mode then
			if mode ~= "markdown" then
				require("config.notebook_edit").sync(event.buf)
			end
			refresh()
		end
	end,
})
vim.api.nvim_create_autocmd("ModeChanged", { group = group, callback = refresh })
vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "BufWipeout" }, {
	group = group,
	pattern = { "*.ipynb", "*.qmd" },
	callback = function(event)
		saved[vim.api.nvim_buf_get_name(event.buf)] = nil
		if event.event ~= "BufWritePost" then
			require("config.notebook_edit").reset(event.buf)
		end
	end,
})

return M
