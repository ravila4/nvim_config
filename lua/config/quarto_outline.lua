local M = {}
local document = require("config.document_outline")

local function runner_for(language)
	local config = assert(_G.QuartoConfig and QuartoConfig.codeRunner, "Quarto runner is not configured")
	return (config.ft_runners or {})[language] or config.default_method
end

function M.uses_molten(language)
	return _G.QuartoConfig and runner_for(language) == "molten"
end

function M.run(buf, selected, scope)
	assert(vim.api.nvim_get_current_buf() == buf, "Run Quarto cells from their source window")
	local runner = require("quarto.runner")
	local keeper = require("otter.keeper")
	keeper.sync_raft(buf)
	local raft = assert(keeper.rafts[buf], "Quarto runner is not initialized for this buffer")
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local targets, molten_languages = {}, {}
	for _, cell in ipairs(document.cells(document.parse(lines, "quarto"))) do
		local row, chosen = cell.range.start.line, selected.range.start.line
		if
			(scope == "Cell" and row == chosen)
			or (scope == "All Above" and row < chosen)
			or (scope == "All Below" and row > chosen)
		then
			assert(
				cell.closed and table.concat(vim.list_slice(lines, cell.body[1] + 1, cell.body[2]), "\n"):match("%S"),
				"Cell at line " .. (row + 1) .. " is empty or unfinished"
			)
			assert(
				not vim.tbl_contains(QuartoConfig.codeRunner.never_run or {}, cell.language),
				"Execution disabled for " .. cell.language
			)
			local matches, exact = 0, false
			for _, chunk in ipairs(raft.code_chunks[cell.language] or {}) do
				if chunk.range.from[1] <= cell.body[1] and chunk.range.to[1] >= cell.body[1] then
					matches = matches + 1
					exact = chunk.range.from[1] == cell.body[1]
						and chunk.range.to[1] == cell.body[2]
						and chunk.range.to[2] == 0
				end
			end
			assert(matches == 1 and exact, "Quarto extraction disagrees with cell at line " .. (row + 1))
			local method = runner_for(cell.language)
			if method == "molten" then
				molten_languages[cell.language] = true
			end
			targets[#targets + 1] = { cell = cell, method = method }
		end
	end
	local languages = vim.tbl_keys(molten_languages)
	table.sort(languages)
	assert(
		#languages <= 1,
		"Cannot run multiple languages through Molten in one batch: " .. table.concat(languages, ", ")
	)
	local cursor = vim.api.nvim_win_get_cursor(0)
	local tick = vim.api.nvim_buf_get_changedtick(buf)
	local ok, err = pcall(function()
		for _, target in ipairs(targets) do
			local method, cell = target.method, target.cell
			if type(method) == "string" then
				assert(type(require("quarto.runner." .. method).run) == "function", "Runner unavailable: " .. method)
			else
				assert(type(method) == "function", "Runner unavailable for " .. cell.language)
			end
			if method == "molten" then
				local available, kernels = pcall(vim.fn.MoltenRunningKernels, true)
				assert(available, "Could not query Molten kernels: " .. tostring(kernels))
				assert(type(kernels) == "table", "Molten returned an invalid kernel list")
				if #kernels == 0 then
					vim.notify(
						"No kernel selected for this document. In the .qmd source window, run :MoltenInit and choose a kernel, then run the cell again.",
						vim.log.levels.WARN
					)
					return
				end
			end
			vim.api.nvim_win_set_cursor(0, { cell.body[1] + 1, 0 })
			assert(
				keeper.get_current_language_context() == cell.language,
				"Quarto language context disagrees at line " .. (cell.body[1] + 1)
			)
		end
		for _, target in ipairs(targets) do
			assert(
				vim.api.nvim_get_current_buf() == buf and vim.api.nvim_buf_get_changedtick(buf) == tick,
				"Document changed during execution"
			)
			vim.api.nvim_win_set_cursor(0, { target.cell.body[1] + 1, 0 })
			runner.run_cell()
		end
	end)
	if vim.api.nvim_get_current_buf() == buf then
		vim.api.nvim_win_set_cursor(0, cursor)
	end
	if not ok then
		error(err, 0)
	end
end

function M.create(buf, selected, direction, language)
	language = language or (selected and selected.language)
	assert(language and language:match("^[%a][%w_+%-]*$"), "Choose a cell language")
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local first, frontmatter_closed = document.content_start(lines)
	assert(frontmatter_closed, "Close the YAML front matter at line 1 before creating a cell")
	local index = first - 1
	if selected then
		if selected.kind == "Function" then
			assert(
				selected.closed,
				"Close the code fence at line " .. (selected.range.start.line + 1) .. " before creating a cell"
			)
			index = direction == "above" and selected.range.start.line or selected.range["end"].line + 1
		else
			index = direction == "above" and selected.heading_end or selected.range["end"].line + 1
		end
	end
	local line = document.content_start(lines)
	while line <= #lines do
		local block = document.fence(lines, line)
		if block then
			assert(
				block.closed or index <= block.first,
				"Close the code fence at line " .. line .. " before creating a cell"
			)
			line = block.finish + 1
		else
			line = line + 1
		end
	end
	local insertion = { "```{" .. language .. "}", "", "```" }
	if index > 0 and lines[index]:match("%S") then
		table.insert(insertion, 1, "")
	end
	if index < #lines and lines[index + 1]:match("%S") then
		insertion[#insertion + 1] = ""
	end
	require("config.notebook_edit").insert(buf, index, insertion)
end

function M.paste(buf, index, register, count)
	local function labels()
		local counts = {}
		for _, cell in ipairs(document.cells(document.parse(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "quarto"))) do
			if cell.label then
				counts[cell.label] = (counts[cell.label] or 0) + 1
			end
		end
		return counts
	end
	local before = labels()
	require("config.notebook_edit").paste(buf, index, register, count)
	local duplicates = {}
	for label, total in pairs(labels()) do
		if total > 1 and total > (before[label] or 0) then
			duplicates[#duplicates + 1] = label
		end
	end
	if #duplicates > 0 then
		table.sort(duplicates)
		vim.notify(
			"Duplicate Quarto labels after paste: "
				.. table.concat(duplicates, ", ")
				.. ". Rename copied labels before rendering.",
			vim.log.levels.WARN
		)
	end
end

return M
