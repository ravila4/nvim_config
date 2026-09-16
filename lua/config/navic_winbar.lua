local M = {}
local document_cache = {}

M.expression = "%!v:lua.require'config.navic_winbar'.render()"

local function escape_statusline(text)
	return text:gsub("%%", "%%%%")
end

local function has_document_symbols(bufnr)
	for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
		if client.server_capabilities.documentSymbolProvider then
			return true
		end
	end
	return false
end

local function heading_chain(nodes, cursor_line, chain)
	for _, node in ipairs(nodes) do
		local range = node.range
		if range.start.line <= cursor_line and cursor_line <= range["end"].line then
			if node.kind == "Module" then
				chain[#chain + 1] = escape_statusline(node.name)
			end
			return heading_chain(node.children, cursor_line, chain)
		end
	end
	return chain
end

local function document_location(bufnr, winid)
	local document = require("config.document_outline")
	local mode = document.format(bufnr)
	if mode ~= "markdown" and mode ~= "quarto" then
		return nil
	end

	local changedtick = vim.api.nvim_buf_get_changedtick(bufnr)
	local cached = document_cache[bufnr]
	if not cached or cached.changedtick ~= changedtick or cached.mode ~= mode then
		cached = {
			changedtick = changedtick,
			mode = mode,
			tree = document.parse(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), mode),
		}
		document_cache[bufnr] = cached
	end

	local cursor_line = vim.api.nvim_win_get_cursor(winid)[1] - 1
	return table.concat(heading_chain(cached.tree, cursor_line, {}), " %#NavicSeparator#> %#NavicText#")
end

function M.render()
	local winid = vim.g.statusline_winid
	if type(winid) ~= "number" or not vim.api.nvim_win_is_valid(winid) then
		return ""
	end

	local bufnr = vim.api.nvim_win_get_buf(winid)
	local filepath = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":~:.")
	local prefix = string.format("%%#NavicText# %s", escape_statusline(filepath))
	local document_heading = document_location(bufnr, winid)
	if document_heading ~= nil then
		if document_heading == "" then
			return prefix
		end
		return string.format("%s %%#NavicSeparator#>%%#NavicText# %s", prefix, document_heading)
	end

	local ok, navic = pcall(require, "nvim-navic")
	if not ok or not navic.is_available(bufnr) then
		return ""
	end

	local location = navic.get_location(nil, bufnr)
	if location == "" then
		return prefix
	end
	return string.format("%s %%#NavicSeparator#>%%#NavicText# %s", prefix, location)
end

function M.enable(bufnr)
	for _, winid in ipairs(vim.fn.win_findbuf(bufnr)) do
		vim.wo[winid].winbar = M.expression
	end
end

function M.disable(bufnr)
	for _, winid in ipairs(vim.fn.win_findbuf(bufnr)) do
		if vim.wo[winid].winbar == M.expression then
			vim.wo[winid].winbar = ""
		end
	end
end

function M.setup()
	local group = vim.api.nvim_create_augroup("NavicWinbar", { clear = true })

	vim.api.nvim_create_autocmd("BufWinEnter", {
		group = group,
		callback = function(args)
			local mode = require("config.document_outline").format(args.buf)
			if mode == "markdown" or mode == "quarto" then
				M.enable(args.buf)
				return
			end
			local ok, navic = pcall(require, "nvim-navic")
			if ok and navic.is_available(args.buf) then
				M.enable(args.buf)
			end
		end,
	})

	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		pattern = { "markdown", "quarto" },
		callback = function(args)
			M.enable(args.buf)
		end,
	})

	vim.api.nvim_create_autocmd("BufWipeout", {
		group = group,
		callback = function(args)
			document_cache[args.buf] = nil
		end,
	})

	vim.api.nvim_create_autocmd("LspDetach", {
		group = group,
		callback = function(args)
			vim.schedule(function()
				if not vim.api.nvim_buf_is_valid(args.buf) then
					return
				end
				local mode = require("config.document_outline").format(args.buf)
				local has_document_breadcrumbs = mode == "markdown" or mode == "quarto"
				if not has_document_breadcrumbs and not has_document_symbols(args.buf) then
					M.disable(args.buf)
				end
			end)
		end,
	})
end

return M
