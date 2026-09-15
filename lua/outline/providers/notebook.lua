local M = { name = "notebook" }

function M.supports_buffer(bufnr)
	return vim.api.nvim_buf_get_name(bufnr):match("%.ipynb$") ~= nil
end

M.request_symbols = require("config.document_outline_provider").request_symbols

return M
