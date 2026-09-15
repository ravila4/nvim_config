local M = { name = "document" }

function M.supports_buffer(buf)
	local format = require("config.document_outline").format(buf)
	return format == "markdown" or format == "quarto"
end

M.request_symbols = require("config.document_outline_provider").request_symbols

return M
