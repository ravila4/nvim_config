local M = { ns = vim.api.nvim_create_namespace("notebook-cell-borders") }
local cells = {}

function M.refresh(buf)
	if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_get_name(buf):match("%.ipynb$") then
		return
	end
	vim.api.nvim_buf_clear_namespace(buf, M.ns, 0, -1)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	cells[buf] = {}
	local function collect(nodes)
		for _, node in ipairs(nodes) do
			local first, last = node.range.start.line, node.range["end"].line
			if node.kind == "Function" and last > first and lines[last + 1]:match("^%s*[`~]+%s*$") then
				table.insert(cells[buf], { first, last })
				for row = first + 1, last - 1 do
					vim.api.nvim_buf_set_extmark(buf, M.ns, row, 0, {
						virt_text = { { "│ ", "NotebookCellBorder" } },
						virt_text_pos = "inline",
						priority = 200,
					})
				end
			end
			collect(node.children)
		end
	end
	collect(require("config.notebook_outline").symbols(lines, {}, {}))
end

local function draw(win, buf, top, bottom)
	local width = math.max(2, vim.api.nvim_win_get_width(win) - vim.fn.getwininfo(win)[1].textoff)
	local function mark(row, col, text, position, screen_col)
		if row < top or row > bottom then
			return
		end
		vim.api.nvim_buf_set_extmark(buf, M.ns, row, col, {
			virt_text = { { text, "NotebookCellBorder" } },
			virt_text_pos = position,
			virt_text_win_col = screen_col,
			priority = 200,
			ephemeral = true,
		})
	end
	for _, cell in ipairs(cells[buf] or {}) do
		local first, last = cell[1], cell[2]
		mark(first, 0, "╭" .. string.rep("─", width - 2) .. "╮", "overlay", 0)
		for row = math.max(first + 1, top), math.min(last - 1, bottom) do
			mark(row, 0, "│", "overlay", width - 1)
		end
		mark(last, 0, "╰" .. string.rep("─", width - 2) .. "╯", "overlay", 0)
	end
end

function M.setup()
	vim.api.nvim_set_decoration_provider(M.ns, {
		on_win = function(_, win, buf, top, bottom)
			if cells[buf] then
				draw(win, buf, top, bottom)
			end
			return false
		end,
	})
	vim.api.nvim_set_hl(0, "NotebookCellBorder", { default = true, link = "Comment" })
	local group = vim.api.nvim_create_augroup("NotebookCellBorders", { clear = true })
	vim.api.nvim_create_autocmd({ "BufWinEnter", "TextChanged", "TextChangedI", "InsertLeave" }, {
		group = group,
		pattern = "*.ipynb",
		callback = function(event)
			M.refresh(event.buf)
		end,
	})
	vim.api.nvim_create_autocmd("BufWipeout", {
		group = group,
		callback = function(event)
			cells[event.buf] = nil
		end,
	})
end

return M
