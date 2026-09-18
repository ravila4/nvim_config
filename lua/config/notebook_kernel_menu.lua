local M = {}

function M.items(win, buf)
	local mode = require("config.document_outline").format(buf)
	if mode ~= "notebook" and mode ~= "quarto" then
		return {}
	end
	local items = {}
	for _, entry in ipairs({
		{ "Select Kernel", "MoltenInit" },
		{ "Interrupt Kernel", "MoltenInterrupt" },
		{ "Restart Kernel", "MoltenRestart" },
	}) do
		local name, command = unpack(entry)
		items[#items + 1] = {
			name = name,
			cmd = function()
				if not vim.api.nvim_win_is_valid(win) or vim.api.nvim_win_get_buf(win) ~= buf then
					vim.notify("Document window changed; reopen the context menu.", vim.log.levels.WARN)
					return
				end
				local remote = require("config.notebook_remote")
				if command == "MoltenInit" then
					vim.api.nvim_set_current_win(win)
					require("config.notebook_kernels").pick(buf)
				elseif command == "MoltenInterrupt" and remote.interrupt(buf) then
					return
				elseif command == "MoltenRestart" and remote.restart(buf) then
					return
				else
					vim.api.nvim_win_call(win, function()
						vim.cmd(command)
					end)
				end
			end,
		}
	end
	return items
end

return M
