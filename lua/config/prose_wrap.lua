local M = {}

function M.toggle()
	vim.wo.wrap = not vim.wo.wrap
	if vim.wo.wrap then
		vim.wo.showbreak = "NONE"
	end
end

return M
