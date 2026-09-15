local M = { ns = vim.api.nvim_create_namespace("notebook-cell-borders") }

function M.refresh(buf)
	if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_get_name(buf):match("%.ipynb$") then
		return
	end
	vim.api.nvim_buf_clear_namespace(buf, M.ns, 0, -1)
	local win = vim.fn.bufwinid(buf)
	if win == -1 then
		win = vim.api.nvim_get_current_win()
	end
	local width = math.max(2, vim.api.nvim_win_get_width(win) - vim.fn.getwininfo(win)[1].textoff)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local function mark(row, col, text, position, screen_col)
		vim.api.nvim_buf_set_extmark(buf, M.ns, row, col, {
			virt_text = { { text, "NotebookCellBorder" } },
			virt_text_pos = position,
			virt_text_win_col = screen_col,
			priority = 200,
		})
	end
	local function draw(nodes)
		for _, node in ipairs(nodes) do
			if node.kind == "Function" then
				local first, last = node.range.start.line, node.range["end"].line
				-- An unfinished fence is still being edited; leave its source visible.
				if last > first and lines[last + 1]:match("^%s*[`~]+%s*$") then
					mark(first, 0, "╭" .. string.rep("─", width - 2) .. "╮", "overlay", 0)
					for row = first + 1, last - 1 do
						mark(row, 0, "│ ", "inline")
						mark(row, 0, "│", "overlay", width - 1)
					end
					mark(last, 0, "╰" .. string.rep("─", width - 2) .. "╯", "overlay", 0)
				end
			end
			draw(node.children)
		end
	end
	draw(require("config.notebook_outline").symbols(lines, {}, {}))
end

function M.setup()
	vim.api.nvim_set_hl(0, "NotebookCellBorder", { default = true, link = "Comment" })
	local group = vim.api.nvim_create_augroup("NotebookCellBorders", { clear = true })
	vim.api.nvim_create_autocmd({ "BufWinEnter", "TextChanged", "TextChangedI", "InsertLeave" }, {
		group = group,
		pattern = "*.ipynb",
		callback = function(event)
			M.refresh(event.buf)
		end,
	})
	vim.api.nvim_create_autocmd({ "WinResized", "VimResized", "WinEnter" }, {
		group = group,
		callback = function()
			M.refresh(vim.api.nvim_get_current_buf())
		end,
	})
end

return M
