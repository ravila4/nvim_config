local M = {}
local installed = false

local function source(cell)
	return vim.trim(type(cell.source) == "table" and table.concat(cell.source) or cell.source)
end

function M.reconcile(buf, notebook, previous)
	local spans, records = require("config.notebook_edit").records(buf)
	local by_id = {}
	for _, cell in ipairs(previous.cells or {}) do
		if cell.id then
			by_id[cell.id] = cell
		end
	end
	local symbols = {}
	local function visit(nodes)
		for _, node in ipairs(nodes) do
			if node.kind == "Function" then
				symbols[#symbols + 1] = node
			end
			visit(node.children)
		end
	end
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	visit(require("config.notebook_outline").symbols(lines, {}, {}))
	local index = 0
	local bindings = {}
	for _, cell in ipairs(notebook.cells) do
		if cell.cell_type == "code" then
			index = index + 1
			local symbol = symbols[index]
			assert(symbol, "Notebook conversion produced unexpected code cells")
			local text = vim.trim(
				table.concat(vim.list_slice(lines, symbol.range.start.line + 2, symbol.range["end"].line), "\n")
			)
			assert(text == source(cell), "Notebook conversion disagrees with the selected code cells")
			cell.outputs = {}
			cell.execution_count = vim.NIL
			local binding = {
				start_line = symbol.range.start.line + 1,
				end_line = symbol.range["end"].line - 1,
				source = source(cell),
				record = cell,
			}
			while binding.start_line < binding.end_line and lines[binding.start_line + 1]:match("^%s*$") do
				binding.start_line = binding.start_line + 1
			end
			while binding.end_line > binding.start_line and lines[binding.end_line + 1]:match("^%s*$") do
				binding.end_line = binding.end_line - 1
			end
			binding.end_line = math.max(binding.start_line, binding.end_line)
			for _, span in ipairs(spans) do
				if span.start_line > symbol.range.start.line and span.end_line < symbol.range["end"].line then
					local record = records[span.id]
					record = record and (by_id[record.id] or record)
					if record then
						binding.id = span.id
						cell.id = record.id or cell.id
						cell.metadata =
							vim.tbl_deep_extend("force", vim.deepcopy(record.metadata or {}), cell.metadata or {})
						if source(record) == source(cell) then
							cell.outputs = vim.deepcopy(record.outputs or {})
							cell.execution_count = record.execution_count or vim.NIL
						end
					end
					break
				end
			end
			bindings[#bindings + 1] = binding
			if not binding.id then
				cell.id = vim.fn.sha256(tostring(vim.uv.hrtime()) .. ":" .. index):sub(1, 16)
			end
		else
			for _, old in ipairs(previous.cells or {}) do
				for name, attachment in pairs(old.attachments or {}) do
					if source(cell):find("attachment:" .. name, 1, true) then
						cell.attachments = cell.attachments or {}
						assert(
							not cell.attachments[name] or vim.deep_equal(cell.attachments[name], attachment),
							"Ambiguous Markdown attachment: " .. name
						)
						cell.attachments[name] = vim.deepcopy(attachment)
					end
				end
			end
		end
	end
	assert(index == #symbols, "Notebook conversion omitted code cells")
	return notebook, bindings
end

function M.write(buf, path)
	local jupytext = require("jupytext")
	local destination = vim.uv.fs_realpath(path) or vim.fn.fnamemodify(path, ":p")
	local current = vim.uv.fs_realpath(vim.api.nvim_buf_get_name(buf)) or vim.api.nvim_buf_get_name(buf)
	local stat = vim.uv.fs_stat(destination)
	local mtime = vim.b[buf].mtime
	if destination == current and stat and mtime and not vim.deep_equal(stat.mtime, mtime) then
		error("Notebook changed on disk; reload it before saving", 0)
	end
	local previous = { cells = {}, metadata = {} }
	if vim.uv.fs_stat(path) then
		previous = vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
	end
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local result = vim.system(
		{ jupytext.get_option("jupytext"), "--from", "md:markdown", "--to", "ipynb", "--output", "-", "-" },
		{ stdin = table.concat(lines, "\n") .. "\n", text = true }
	):wait()
	assert(result.code == 0, result.stderr)
	local notebook, bindings = M.reconcile(buf, vim.json.decode(result.stdout), previous)
	notebook.metadata = vim.tbl_deep_extend("force", previous.metadata or {}, notebook.metadata or {})
	local fd, temp = assert(vim.uv.fs_mkstemp(destination .. ".XXXXXX"))
	local ok, err = pcall(function()
		if stat then
			assert(vim.uv.fs_fchmod(fd, stat.mode))
		end
		assert(vim.uv.fs_write(fd, vim.json.encode(notebook) .. "\n", 0))
		assert(vim.uv.fs_close(fd))
		fd = nil
		assert(vim.uv.fs_rename(temp, destination))
	end)
	if not ok then
		if fd then
			vim.uv.fs_close(fd)
		end
		vim.uv.fs_unlink(temp)
		error(err, 0)
	end
	if destination == current then
		require("config.notebook_edit").accept_saved(buf, bindings)
		vim.bo[buf].modified = false
		vim.b[buf].mtime = vim.uv.fs_stat(destination).mtime
	end
end

function M.setup()
	if installed then
		return
	end
	installed = true
	local jupytext = require("jupytext")
	local original = jupytext.write_notebook
	jupytext.write_notebook = function(path, metadata, buf)
		buf = buf and buf ~= 0 and buf or vim.api.nvim_get_current_buf()
		if require("config.notebook_edit").changed(buf) then
			M.write(buf, path)
		else
			original(path, metadata, buf)
		end
	end
end

return M
