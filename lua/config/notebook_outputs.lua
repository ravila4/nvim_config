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

-- Prefer the kernelspec recorded in the notebook, then a kernel named after
-- the active virtualenv. Returns nil when neither is installed.
function M.pick_kernel(notebook, available, venv_path)
	local candidates = { vim.tbl_get(notebook, "metadata", "kernelspec", "name") }
	if venv_path then
		table.insert(candidates, vim.fs.basename(venv_path))
	end
	for _, name in ipairs(candidates) do
		if vim.tbl_contains(available, name) then
			return name
		end
	end
	return nil
end

return M
