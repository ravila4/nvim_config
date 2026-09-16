local M = {}

function M.supports(buf)
	return vim.bo[buf].filetype == "rhelp"
		or (vim.bo[buf].filetype == "r" and vim.bo[buf].buflisted and vim.bo[buf].buftype == "")
end

function M.read_config(path)
	path = path or (vim.fn.stdpath("data") .. "/r-config.json")
	if vim.fn.filereadable(path) == 0 then
		return nil
	end
	local selected = vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
	assert(
		type(selected) == "table"
			and type(selected.executable) == "string"
			and selected.executable:sub(1, 1) == "/"
			and type(selected.library) == "string"
			and selected.library:sub(1, 1) == "/",
		"Invalid R configuration: " .. path .. ". Run make r."
	)
	return selected
end

local function with_filetype(ft, fn)
	vim.g.R_filetypes = { ft }
	local ok, err = pcall(fn)
	vim.g.R_filetypes = {}
	if not ok then
		error(err)
	end
end

function M.attach(buf)
	if not M.supports(buf) or vim.b[buf].rnvim_attached then
		return
	end
	vim.api.nvim_buf_call(buf, function()
		with_filetype(vim.bo.filetype, function()
			vim.cmd.runtime("ftplugin/" .. vim.bo.filetype .. "_rnvim.lua")
		end)
		vim.b.rnvim_attached = true
	end)
end

function M.setup(selected)
	vim.g.R_filetypes = {}
	local group = vim.api.nvim_create_augroup("RScriptIntegration", { clear = true })
	if not selected then
		local function warn(buf)
			if M.supports(buf) then
				vim.notify("R integration is not configured. Run make r, then restart Neovim.", vim.log.levels.WARN)
			end
		end
		vim.api.nvim_create_autocmd("FileType", {
			group = group,
			pattern = { "r", "rhelp" },
			callback = function(args)
				warn(args.buf)
			end,
		})
		warn(vim.api.nvim_get_current_buf())
		return
	end
	vim.env.R_LIBS_USER = selected.library
	require("r").setup({
		R_app = selected.executable,
		R_cmd = selected.executable,
		external_term = "",
		auto_start = "no",
		register_treesitter = false,
		-- The configured languageserver also serves Quarto's extracted R buffers.
		r_ls = {
			completion = false,
			hover = false,
			signature = false,
			implementation = false,
			definition = false,
			references = false,
			document_highlight = false,
			document_symbol = false,
			workspace_symbol = false,
			rename = false,
		},
	})
	-- Upstream's global BufEnter callback also processes Quarto parameters.
	-- Keep its active-source tracking confined to this integration's buffers.
	local edit = require("r.edit")
	local buf_enter = edit.buf_enter
	edit.buf_enter = function()
		if M.supports(vim.api.nvim_get_current_buf()) then
			with_filetype(vim.bo.filetype, buf_enter)
		end
	end
	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		pattern = { "r", "rhelp" },
		callback = function(args)
			M.attach(args.buf)
		end,
	})
	M.attach(vim.api.nvim_get_current_buf())
end

return M
