local M = {}

function M.scroll(command, count)
	-- Virtual image rows can be wider than the cursor's buffer line.
	local virtualedit = vim.wo.virtualedit
	vim.wo.virtualedit = "all"
	vim.cmd.normal({ (count or 1) .. command, bang = true })
	vim.wo.virtualedit = virtualedit
end

return M
