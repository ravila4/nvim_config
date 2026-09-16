local M = {}

function M.open(source, line)
	source = source or vim.api.nvim_get_current_buf()
	line = line or vim.api.nvim_win_get_cursor(0)[1]
	local lines = vim.api.nvim_buf_get_lines(source, 0, -1, false)
	local selected
	local function visit(nodes)
		for _, node in ipairs(nodes) do
			if node.kind == "Function" and node.range.start.line <= line - 1 and node.range["end"].line >= line - 1 then
				selected = node.range
			end
			visit(node.children or {})
		end
	end
	visit(require("config.document_outline").parse(lines, require("config.document_outline").format(source)))
	local texts = {}
	local ns = vim.api.nvim_get_namespaces()["molten-extmarks"]
	if selected and ns then
		for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(source, ns, 0, -1, { details = true })) do
			if mark[4].virt_lines and mark[2] >= selected.start.line and mark[2] <= selected["end"].line then
				local ok, text = pcall(vim.fn.MoltenOutputText, source, mark[1])
				if ok and type(text) == "string" and text ~= "" then
					texts[#texts + 1] = text
				end
			end
		end
	end
	if #texts == 0 then
		vim.notify("This cell has no text output", vim.log.levels.INFO)
		return
	end
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(table.concat(texts, "\n"), "\n", { plain = true }))
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].modifiable = false
	local width = math.max(1, math.floor(vim.o.columns * 0.9) - 2)
	local height = math.max(1, math.floor((vim.o.lines - vim.o.cmdheight) * 0.8) - 2)
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		style = "minimal",
		border = "rounded",
		width = width,
		height = height,
		col = math.floor((vim.o.columns - width - 2) / 2),
		row = math.floor((vim.o.lines - height - 2) / 2),
		title = " Cell Output ",
		title_pos = "center",
	})
	-- Markdown outputs (pipe tables, Markdown objects) get rendered by markview, which
	-- ignores scratch buffers unless they opt in. Plain output is left without a
	-- filetype so stray `#` or `*` in stdout are not styled.
	if vim.g.molten_output_format == "markdown" then
		vim.b[buf].markview_attach = true
		vim.bo[buf].filetype = "markdown"
	end
	local function no_wrap()
		if vim.api.nvim_win_is_valid(win) then
			vim.wo[win].wrap = false
			vim.wo[win].sidescrolloff = 0
		end
	end
	-- Markview turns wrap on when it attaches; wide tables need horizontal scrolling.
	no_wrap()
	vim.schedule(no_wrap)
	for _, key in ipairs({ "q", "<Esc>" }) do
		vim.keymap.set("n", key, function()
			vim.api.nvim_win_close(win, true)
		end, { buffer = buf, silent = true, desc = "Close output" })
	end
	vim.keymap.set("n", "<leader>jm", function()
		vim.api.nvim_win_close(win, true)
		vim.cmd("MoltenToggleOutputFormat")
		M.open(source, line)
	end, { buffer = buf, silent = true, desc = "[Output] Toggle markdown output" })
	return win
end

-- Expand or collapse the ghost-text output whose "More Lines" / "Show Less" footer
-- is under the mouse. Returns true when a footer was clicked.
function M.click_footer()
	local mouse = vim.fn.getmousepos()
	local ok, virt_lines = pcall(require, "molten.virt_lines")
	if not ok or mouse.winid == 0 then
		return false
	end
	local buf = vim.api.nvim_win_get_buf(mouse.winid)
	local hit = virt_lines.at(buf, mouse.winid, mouse.screenrow)
	if not hit or not virt_lines.is_footer(hit.text) then
		return false
	end
	return vim.fn.MoltenToggleVirtExpandAt(buf, hit.id) == true
end

return M
