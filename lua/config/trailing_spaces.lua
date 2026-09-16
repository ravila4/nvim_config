local M = {}

local skip_filetypes = {
	"lazy",
	"mason",
	"neo-tree",
	"telescope",
	"dashboard",
	"snacks_dashboard",
	"help",
	"terminal",
	"qf",
	"trouble",
	"fugitive",
	"defx",
	"",
}

local function eligible(buf)
	return vim.bo[buf].buftype == "" and not vim.tbl_contains(skip_filetypes, vim.bo[buf].filetype)
end

local function set_highlight()
	vim.api.nvim_set_hl(0, "TrailingSpaces", {
		bg = vim.o.background == "dark" and "#3c1e1e" or "#ffe6e6",
		fg = vim.o.background == "dark" and "#ff6b6b" or "#cc0000",
	})
end

local function update(win)
	if not vim.api.nvim_win_is_valid(win) then
		return
	end

	local match_id = vim.w[win].trailing_space_match
	if match_id then
		pcall(vim.fn.matchdelete, match_id, win)
		vim.w[win].trailing_space_match = nil
	end

	local buf = vim.api.nvim_win_get_buf(win)
	if eligible(buf) then
		vim.w[win].trailing_space_match = vim.fn.matchadd("TrailingSpaces", "\\s\\+$", 10, -1, { window = win })
	end
end

local function delete_current_buffer()
	local win = vim.api.nvim_get_current_win()
	local buf = vim.api.nvim_get_current_buf()
	if not eligible(buf) then
		vim.notify("DeleteTrailingSpaces: Skipping special buffer")
		return
	end

	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local lines_with_trailing = 0
	local total_trailing_chars = 0

	for line_num = 1, vim.fn.line("$") do
		local trailing = vim.fn.getline(line_num):match("%s+$")
		if trailing then
			lines_with_trailing = lines_with_trailing + 1
			total_trailing_chars = total_trailing_chars + #trailing
		end
	end

	if total_trailing_chars == 0 then
		vim.notify("No trailing spaces found")
		return
	end

	vim.cmd([[silent! %s/\s\+$//e]])
	pcall(vim.api.nvim_win_set_cursor, 0, cursor_pos)
	vim.defer_fn(function()
		update(win)
	end, 50)

	vim.notify(string.format("Removed %d trailing characters from %d lines", total_trailing_chars, lines_with_trailing))
end

function M.setup()
	local group = vim.api.nvim_create_augroup("TrailingSpace", { clear = true })

	vim.api.nvim_create_autocmd("ColorScheme", {
		group = group,
		callback = set_highlight,
	})

	vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
		group = group,
		callback = function()
			local win = vim.api.nvim_get_current_win()
			local buf = vim.api.nvim_win_get_buf(win)
			vim.defer_fn(function()
				if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
					update(win)
				end
			end, 100)
		end,
	})

	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		callback = function(args)
			for _, win in ipairs(vim.fn.win_findbuf(args.buf)) do
				update(win)
			end
		end,
	})

	vim.defer_fn(set_highlight, 200)

	vim.api.nvim_create_user_command("DeleteTrailingSpaces", delete_current_buffer, {
		desc = "Delete all trailing spaces in current buffer",
		force = true,
	})
	vim.keymap.set("n", "<leader>dw", "<cmd>DeleteTrailingSpaces<cr>", { desc = "Delete trailing spaces" })
end

return M
