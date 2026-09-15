-- Decisions for importing saved outputs from an .ipynb file into Molten.
-- Molten can only attach imported outputs to a running kernel, so a kernel
-- has to be chosen and started before the import.
local M = {}

function M.has_outputs(notebook)
	for _, cell in ipairs(notebook.cells or {}) do
		if cell.cell_type == "code" and cell.outputs and #cell.outputs > 0 then
			return true
		end
	end
	return false
end

return M
