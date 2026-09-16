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

function M.installed(callback)
	local function failed(message)
		vim.notify("Could not list notebook kernels: " .. message, vim.log.levels.ERROR)
		callback({})
	end
	local spawned, err = pcall(
		vim.system,
		{ vim.g.python3_host_prog or "python3", "-m", "jupyter", "kernelspec", "list", "--json" },
		{ text = true, timeout = 10000 },
		function(result)
			vim.schedule(function()
				local ok, data = pcall(vim.json.decode, result.stdout or "")
				if result.code ~= 0 or not ok or type(data) ~= "table" or type(data.kernelspecs) ~= "table" then
					failed(result.stderr and result.stderr ~= "" and result.stderr or "invalid Jupyter response")
					return
				end
				local choices = {}
				for name, entry in pairs(data.kernelspecs) do
					local spec = type(entry) == "table" and entry.spec
					if
						type(spec) == "table"
						and type(spec.argv) == "table"
						and type(spec.argv[1]) == "string"
						and spec.argv[1] ~= ""
					then
						choices[name] = {
							name = name,
							label = type(spec.display_name) == "string" and spec.display_name or name,
							executable = spec.argv[1],
						}
					end
				end
				callback(choices)
			end)
		end
	)
	if not spawned then
		vim.schedule(function()
			failed(tostring(err))
		end)
	end
end

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
		M.installed(function(choices)
			if not vim.api.nvim_buf_is_valid(buf) or requests[buf] ~= request then
				return
			end
			local names = {}
			for name in pairs(attempted) do
				choices[name] = nil
			end
			for name, choice in pairs(prepared) do
				choices[name] = choice
			end
			for name in pairs(choices) do
				names[#names + 1] = name
			end
			table.sort(names, function(a, b)
				if project and a == project.name then
					return true
				end
				if project and b == project.name then
					return false
				end
				return a < b
			end)
			callback(
				choices,
				names,
				project and prepared[project.name] and project.name,
				prepared[default.name] and default.name
			)
		end)
	end
	next_candidate(1)
end

local function picker(buf, choices, names, import_outputs, execution)
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
			local choice = choices[name]
			local path = choice.python or choice.executable or "unknown launch path"
			path = path:match("^(.*)/bin/python[^/]*$") or path
			local label = (choice.label or name):gsub("^Project %(.+%)$", "Project")
			return label .. " — " .. vim.fn.fnamemodify(path, ":~")
		end,
	}, function(name)
		if name then
			if execution then
				local event
				event = vim.api.nvim_create_autocmd("User", {
					pattern = "MoltenKernelReady",
					callback = function(e)
						if not e.data or e.data.kernel_id ~= name then
							return
						end
						vim.api.nvim_del_autocmd(event)
						vim.schedule(function()
							if not vim.api.nvim_buf_is_valid(buf) then
								return
							end
							if vim.api.nvim_buf_get_changedtick(buf) ~= execution.tick then
								vim.notify(
									"Document changed while selecting a kernel; run the cell again.",
									vim.log.levels.WARN
								)
								return
							end
							vim.api.nvim_buf_call(buf, function()
								if vim.fn.MoltenKernelName() ~= name then
									return
								end
								local cursor = vim.api.nvim_win_get_cursor(0)
								vim.api.nvim_win_set_cursor(0, execution.cursor)
								local ok, err = pcall(vim.cmd, (execution.command:gsub("%%k", function()
									return name
								end)))
								vim.api.nvim_win_set_cursor(0, cursor)
								if not ok then
									vim.notify(tostring(err), vim.log.levels.ERROR)
								end
							end)
						end)
					end,
				})
				vim.defer_fn(function()
					pcall(vim.api.nvim_del_autocmd, event)
				end, 60000)
			end
			M.start(buf, choices[name], true, import_outputs)
		end
	end)
end

function M.pick(buf, command)
	buf = buf or vim.api.nvim_get_current_buf()
	local execution = command
			and {
				command = command,
				tick = vim.api.nvim_buf_get_changedtick(buf),
				cursor = vim.api.nvim_win_get_cursor(0),
			}
		or nil
	local saved = M.load_choice(vim.api.nvim_buf_get_name(buf))
	collect(buf, saved, function(choices, names)
		picker(buf, choices, names, not command and vim.api.nvim_buf_get_name(buf):match("%.ipynb$") ~= nil, execution)
	end)
end

function M.setup_prompts()
	local prompt = require("prompt")
	prompt.prompt_init = function()
		local buf = vim.api.nvim_get_current_buf()
		vim.schedule(function()
			M.pick(buf)
		end)
	end
	prompt.prompt_init_and_run = function(_, _, command)
		local buf, cursor = vim.api.nvim_get_current_buf(), vim.api.nvim_win_get_cursor(0)
		vim.schedule(function()
			if not vim.api.nvim_buf_is_valid(buf) then
				return
			end
			vim.api.nvim_buf_call(buf, function()
				local current = vim.api.nvim_win_get_cursor(0)
				vim.api.nvim_win_set_cursor(0, cursor)
				M.pick(buf, command)
				vim.api.nvim_win_set_cursor(0, current)
			end)
		end)
	end
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
