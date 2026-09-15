local M = {}

function M.select(saved, available, project, default)
	if saved then
		if vim.tbl_contains(available, saved) then
			return saved
		end
		return nil, "saved_missing"
	end
	for _, name in ipairs({ project or false, default or false }) do
		if name and vim.tbl_contains(available, name) then
			return name
		end
	end
end

local function choice_path(path, directory)
	directory = directory or (vim.fn.stdpath("state") .. "/notebook-kernels")
	return directory .. "/" .. vim.fn.sha256(vim.fn.fnamemodify(path, ":p")) .. ".json"
end

function M.load_choice(path, directory)
	local file = choice_path(path, directory)
	if vim.fn.filereadable(file) == 0 then
		return nil
	end
	local choice = vim.json.decode(table.concat(vim.fn.readfile(file), "\n"))
	assert(type(choice) == "table" and type(choice.name) == "string", "Invalid saved notebook kernel: " .. file)
	return choice
end

function M.save_choice(path, choice, directory)
	local file = choice_path(path, directory)
	vim.fn.mkdir(vim.fs.dirname(file), "p")
	local fd, temp = assert(vim.uv.fs_mkstemp(file .. ".XXXXXX"))
	assert(vim.uv.fs_write(fd, vim.json.encode(choice), 0))
	assert(vim.uv.fs_close(fd))
	assert(vim.uv.fs_rename(temp, file))
end

function M.project_python(path)
	local env = vim.fs.find(".venv", { path = vim.fs.dirname(path), upward = true, type = "directory" })[1]
	return env and (env .. "/bin/python") or nil
end

function M.prepare(candidate, callback)
	if not candidate or vim.fn.executable(candidate.python) == 0 then
		callback(nil)
		return
	end
	vim.system({
		candidate.python,
		"-m",
		"ipykernel",
		"install",
		"--user",
		"--name",
		candidate.name,
		"--display-name",
		candidate.label,
	}, { text = true, timeout = 10000 }, function(result)
		vim.schedule(function()
			callback(result.code == 0 and candidate or nil)
		end)
	end)
end

function M.start(buf, choice, persist, import_outputs)
	if not vim.api.nvim_buf_is_valid(buf) then
		return
	end
	vim.api.nvim_buf_call(buf, function()
		local running = vim.fn.MoltenRunningKernels(true)
		if #running > 0 then
			vim.cmd.MoltenSwitchKernel(choice.name)
		else
			vim.cmd.MoltenInit(choice.name)
		end
		if vim.fn.MoltenKernelName() ~= choice.name then
			return
		end
		if #running == 0 and import_outputs then
			vim.cmd.MoltenImportOutput()
		end
		if persist then
			M.save_choice(vim.api.nvim_buf_get_name(buf), choice)
		end
		vim.notify("Notebook kernel: " .. (choice.label or choice.name), vim.log.levels.INFO)
	end)
end

local requests = {}

local function collect(buf, saved, callback)
	requests[buf] = (requests[buf] or 0) + 1
	local request = requests[buf]
	local path = vim.api.nvim_buf_get_name(buf)
	local python = M.project_python(path)
	local project = python
			and {
				name = "nvim-project-" .. vim.fn.sha256(python):sub(1, 16),
				python = python,
				label = "Project (" .. vim.fs.dirname(vim.fs.dirname(python)) .. ")",
			}
		or nil
	local default = {
		name = "nvim-default",
		python = vim.g.notebook_default_python or (vim.fn.stdpath("data") .. "/notebook-venv/bin/python"),
		label = "Global notebook environment",
	}
	local candidates = { default }
	if project then
		table.insert(candidates, 1, project)
	end
	if saved and saved.python then
		candidates[#candidates + 1] = saved
	end
	local prepared, attempted = {}, {}
	local function next_candidate(index)
		if not vim.api.nvim_buf_is_valid(buf) or requests[buf] ~= request then
			return
		end
		local candidate = candidates[index]
		if candidate then
			attempted[candidate.name] = true
			M.prepare(candidate, function(result)
				prepared[candidate.name] = result
				next_candidate(index + 1)
			end)
			return
		end
		local choices, names = {}, {}
		for _, name in ipairs(vim.fn.MoltenAvailableKernels()) do
			if not attempted[name] then
				choices[name] = { name = name, label = name }
			end
		end
		for name, choice in pairs(prepared) do
			choices[name] = choice
		end
		for name in pairs(choices) do
			names[#names + 1] = name
		end
		table.sort(names)
		callback(
			choices,
			names,
			project and prepared[project.name] and project.name,
			prepared[default.name] and default.name
		)
	end
	next_candidate(1)
end

local function picker(buf, choices, names, import_outputs)
	if #names == 0 then
		vim.notify(
			"No usable notebook kernels. Install ipykernel in the project or global notebook environment.",
			vim.log.levels.ERROR
		)
		return
	end
	vim.ui.select(names, {
		prompt = "Select notebook kernel (remembered for this file):",
		format_item = function(name)
			return choices[name].label
		end,
	}, function(name)
		if name then
			M.start(buf, choices[name], true, import_outputs)
		end
	end)
end

function M.pick(buf)
	buf = buf or vim.api.nvim_get_current_buf()
	local saved = M.load_choice(vim.api.nvim_buf_get_name(buf))
	collect(buf, saved, function(choices, names)
		picker(buf, choices, names, vim.api.nvim_buf_get_name(buf):match("%.ipynb$") ~= nil)
	end)
end

function M.open(buf, metadata)
	local saved = M.load_choice(vim.api.nvim_buf_get_name(buf))
	local recorded = vim.tbl_get(metadata, "kernelspec", "name")
	if not saved and recorded and recorded:match("^databricks%-") then
		saved = { name = recorded, label = recorded }
	end
	collect(buf, saved, function(choices, names, project, default)
		local name, reason = M.select(saved and saved.name, names, project, default)
		if name then
			M.start(buf, choices[name], false, true)
		else
			if reason == "saved_missing" then
				vim.notify(
					"Saved notebook kernel unavailable: "
						.. saved.name
						.. ". Select a replacement (Databricks targets: :DatabricksTarget).",
					vim.log.levels.WARN
				)
			end
			picker(buf, choices, names, true)
		end
	end)
end

return M
