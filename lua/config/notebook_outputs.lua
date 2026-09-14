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

local function has_kernels(venv)
	return venv and vim.uv.fs_stat(venv .. "/share/jupyter/kernels") ~= nil
end

function M.environment_venv(notebook_path, active_venv)
	if has_kernels(active_venv) then
		return active_venv
	end
	local found = vim.fs.find(".venv", { path = vim.fs.dirname(notebook_path), upward = true, type = "directory" })
	for _, venv in ipairs(found) do
		if has_kernels(venv) then
			return venv
		end
	end
end

function M.jupyter_path(current, venv)
	local path = venv .. "/share/jupyter"
	local separator = vim.fn.has("win32") == 1 and ";" or ":"
	for _, existing in ipairs(vim.split(current or "", separator, { plain = true, trimempty = true })) do
		if existing == path then
			return current
		end
	end
	return current and current ~= "" and path .. separator .. current or path
end

return M
