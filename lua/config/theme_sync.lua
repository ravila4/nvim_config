-- Keep 'background' in sync with the terminal after startup.
--
-- Nvim asks the terminal for its background color (OSC 11) once at startup
-- and sets 'background' from the reply. Ghostty follows the macOS appearance,
-- so a running session goes stale when the system switches between light and
-- dark. Nvim keeps its OSC 11 reply handler installed for the whole session,
-- so re-sending the query is enough: a changed reply updates 'background',
-- which reloads the colorscheme; an unchanged reply is a no-op.
--
-- Ghostty can push theme changes (DEC mode 2031), but nvim 0.12 does not
-- surface those reports to Lua, so the query is repeated on focus and idle.

local function query_terminal_background()
	vim.api.nvim_ui_send("\27]11;?\7")
end

local function attached_to_tty()
	for _, ui in ipairs(vim.api.nvim_list_uis()) do
		if ui.stdout_tty then
			return true
		end
	end
	return false
end

vim.api.nvim_create_autocmd("UIEnter", {
	once = true,
	callback = function()
		if not attached_to_tty() then
			return
		end
		vim.api.nvim_create_autocmd({ "FocusGained", "CursorHold" }, {
			group = vim.api.nvim_create_augroup("ThemeSync", { clear = true }),
			callback = query_terminal_background,
		})
	end,
})
