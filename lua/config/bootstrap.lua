local M = {}
local manifest = require("config.bootstrap_manifest")

function M.run(argv, opts)
	opts = vim.tbl_extend("force", { text = true, timeout = 600000 }, opts or {})
	local result = vim.system(argv, opts):wait()
	if result.code ~= 0 then
		local diagnostic = vim.trim((result.stderr or "") .. "\n" .. (result.stdout or ""))
		error(("%s failed (%s): %s"):format(argv[1], result.code, diagnostic), 0)
	end
	return vim.trim(result.stdout or "")
end

function M.databricks_revision(path)
	local lock = vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
	local revision = lock["databricks.nvim"] and lock["databricks.nvim"].commit or ""
	if #revision ~= 40 or revision:find("[^a-fA-F0-9]") then
		error("Databricks requires a full commit in lazy-lock.json", 0)
	end
	return revision
end

function M.environment(path, version, packages)
	if not vim.uv.fs_stat(path .. "/bin/python") then
		local marker = path .. ".nvim-bootstrap"
		local owned = vim.fn.filereadable(marker) == 1 and vim.fn.readfile(marker)[1] == path
		if vim.uv.fs_stat(path) and not owned then
			error("Refusing to replace existing directory without Python: " .. path, 0)
		end
		vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
		vim.fn.writefile({ path }, marker)
		M.run({ "uv", "venv", "--allow-existing", "--python", version, path })
	end
	local cmd = { "uv", "pip", "install", "--python", path .. "/bin/python" }
	vim.list_extend(cmd, packages)
	M.run(cmd)
end

function M.await(label, ready, timeout)
	if not vim.wait(timeout or 600000, ready, 50) then
		error("Timed out waiting for " .. label, 0)
	end
end

function M.check_r_kernel(path)
	if vim.uv.fs_stat(path) then
		local ok, spec = pcall(function()
			return vim.json.decode(table.concat(vim.fn.readfile(path .. "/kernel.json"), "\n"))
		end)
		if not ok or not spec.metadata or spec.metadata.nvim_config ~= true then
			error("Refusing to replace unrelated kernelspec: " .. path, 0)
		end
	end
end

function M.check_plugins(data, lock)
	local missing = {}
	for name, entry in pairs(lock) do
		local path = data .. "/lazy/" .. name
		if not vim.uv.fs_stat(path) then
			missing[#missing + 1] = "Plugin: " .. name
		else
			local ok, head = pcall(M.run, { "git", "-C", path, "rev-parse", "HEAD" })
			if not ok or head ~= entry.commit then
				missing[#missing + 1] = "Plugin revision: " .. name
			end
		end
	end
	table.sort(missing)
	return missing
end

function M.check(data, root)
	local report = { ok = true, missing = {}, optional = {} }
	local function need(label, present)
		if not present then
			report.missing[#report.missing + 1] = label
		end
	end
	need("Neovim >= 0.12", vim.fn.has("nvim-0.12") == 1)
	for _, executable in ipairs(manifest.prerequisites) do
		need(executable, vim.fn.executable(executable) == 1)
	end
	local host = data .. "/python-host/bin/python"
	need("Python host", vim.fn.executable(host) == 1)
	if vim.fn.executable(host) == 1 then
		need("Python host packages", pcall(M.run, { host, "-B", "-c", "import pynvim, jupyter_client, nbformat" }))
	end
	if root then
		local lock = vim.json.decode(table.concat(vim.fn.readfile(root .. "/lazy-lock.json"), "\n"))
		vim.list_extend(report.missing, M.check_plugins(data, lock))
	end
	local remote = data .. "/rplugin.vim"
	need(
		"Molten remote registration",
		vim.fn.filereadable(remote) == 1
			and table.concat(vim.fn.readfile(remote), "\n"):find("MoltenInit", 1, true) ~= nil
	)
	for _, tool in ipairs(manifest.tools) do
		need("Mason: " .. tool, M.mason_ready(data .. "/mason/packages/" .. tool))
	end
	for _, parser in ipairs(manifest.parsers) do
		local path = data .. "/site/parser/" .. parser .. ".so"
		need(
			"Parser: " .. parser,
			vim.uv.fs_stat(path) ~= nil and pcall(vim.treesitter.language.add, parser, { path = path })
		)
	end
	local notebook = data .. "/notebook-venv"
	if vim.uv.fs_stat(notebook) then
		need("Notebook interpreter", vim.fn.executable(notebook .. "/bin/python") == 1)
		if vim.fn.executable(notebook .. "/bin/python") == 1 then
			need(
				"Notebook packages",
				pcall(M.run, {
					notebook .. "/bin/python",
					"-B",
					"-c",
					"from importlib.util import find_spec; assert all(find_spec(p) for p in ('ipykernel', 'pandas', 'matplotlib'))",
				})
			)
		end
		need("Jupytext", vim.fn.executable("jupytext") == 1)
	else
		report.optional[#report.optional + 1] = "notebooks"
	end
	local r_config = data .. "/r-config.json"
	if vim.fn.filereadable(r_config) == 1 then
		local ok, config = pcall(vim.json.decode, table.concat(vim.fn.readfile(r_config), "\n"))
		need(
			"R configuration",
			ok and type(config) == "table" and type(config.executable) == "string" and type(config.library) == "string"
		)
		if
			ok
			and type(config) == "table"
			and type(config.executable) == "string"
			and type(config.library) == "string"
		then
			need("Selected R", vim.fn.executable(config.executable) == 1)
			need("R library", vim.fn.isdirectory(config.library) == 1)
			for _, package in ipairs({ "IRkernel", "languageserver" }) do
				need(
					"R package: " .. package,
					vim.fn.filereadable(config.library .. "/" .. package .. "/DESCRIPTION") == 1
				)
			end
		end
	else
		report.optional[#report.optional + 1] = "R"
	end
	if vim.fn.executable(host) == 1 and (vim.uv.fs_stat(notebook) or vim.fn.filereadable(r_config) == 1) then
		local ok, result = pcall(M.run, {
			host,
			"-B",
			"-c",
			"import json; from jupyter_client.kernelspec import KernelSpecManager; print(json.dumps(KernelSpecManager(ensure_native_kernel=False).get_all_specs()))",
		})
		need("Kernel discovery", ok)
		if ok then
			local specs = vim.json.decode(result)
			if vim.uv.fs_stat(notebook) then
				need(
					"Global Python kernelspec",
					specs["nvim-default"] and specs["nvim-default"].spec.argv[1] == notebook .. "/bin/python"
				)
			end
			if vim.fn.filereadable(r_config) == 1 then
				need("R kernelspec", specs["nvim-r"] and vim.fn.executable(specs["nvim-r"].spec.argv[1]) == 1)
			end
		end
	end
	local tool_dir = (vim.env.UV_TOOL_DIR or (vim.fn.fnamemodify(data, ":h") .. "/uv/tools")) .. "/databricks-nvim"
	local command = vim.fn.exepath("databricks-nvim-health")
	if command ~= "" or vim.uv.fs_stat(tool_dir) then
		for _, executable in ipairs({
			"databricks-nvim-health",
			"databricks-nvim-targets",
			"databricks-nvim-kernelspec",
			"databricks",
		}) do
			need(executable, vim.fn.executable(executable) == 1)
		end
		if root then
			local python = command ~= ""
					and (vim.fn.fnamemodify(vim.uv.fs_realpath(command) or command, ":h") .. "/python")
				or (tool_dir .. "/bin/python")
			need(
				"Databricks helper revision",
				M.databricks_matches(python, M.databricks_revision(root .. "/lazy-lock.json"))
			)
		end
	else
		report.optional[#report.optional + 1] = "Databricks"
	end
	if vim.uv.fs_stat(data .. "/lazy/markdown-preview.nvim") then
		need("Markdown preview build", M.preview_ready(data .. "/lazy/markdown-preview.nvim"))
	end
	report.ok = #report.missing == 0
	return report
end

function M.prerequisites()
	if vim.fn.has("nvim-0.12") == 0 then
		error("Neovim >= 0.12 is required", 0)
	end
	for _, executable in ipairs(manifest.prerequisites) do
		if vim.fn.executable(executable) == 0 then
			error("Missing prerequisite: " .. executable .. " (see make system-deps)", 0)
		end
	end
	local version = M.run({ "tree-sitter", "--version" }):match("(%d+%.%d+%.%d+)")
	if not version or vim.version.lt(version, "0.26.1") then
		error("tree-sitter >= 0.26.1 is required", 0)
	end
end

function M.plugins(root)
	print("Installing locked plugins, tools, parsers and remote registration...")
	M.run({
		vim.v.progpath,
		"--headless",
		"-u",
		"NONE",
		"-i",
		"NONE",
		"-l",
		root .. "/scripts/bootstrap-plugins.lua",
		root,
	}, { timeout = 900000 })
end

function M.install_spec(spec)
	if type(spec) == "string" then
		return spec
	end
	spec = vim.deepcopy(spec)
	spec.init, spec.config, spec.opts = nil, nil, nil
	spec.event, spec.ft, spec.cmd, spec.keys = nil, nil, nil, nil
	spec.lazy = true
	if
		spec[1] == "nvim-treesitter/nvim-treesitter"
		or spec[1] == "williamboman/mason.nvim"
		or spec[1] == "ravila4/molten-nvim"
	then
		spec.build = false
	end
	if type(spec.dependencies) == "table" then
		for i, dependency in ipairs(spec.dependencies) do
			spec.dependencies[i] = M.install_spec(dependency)
		end
	end
	return spec
end

function M.plugin_errors(plugins)
	for name, plugin in pairs(plugins) do
		for _, task in ipairs(plugin._.tasks or {}) do
			if task:has_errors() then
				error("Plugin install/build failed: " .. name, 0)
			end
		end
	end
end

function M.mason(registry, names, timeout)
	local pending, failure = 0, nil
	for _, name in ipairs(names) do
		local package = registry.get_package(name)
		if not M.mason_ready(package:get_install_path()) then
			pending = pending + 1
			package:install({ version = package:get_installed_version() }, function(ok, err)
				if not ok then
					failure = "Mason install failed: " .. name .. ": " .. tostring(err)
				end
				pending = pending - 1
			end)
		end
	end
	M.await("Mason", function()
		return failure ~= nil or pending == 0
	end, timeout)
	if failure then
		error(failure, 0)
	end
	for _, name in ipairs(names) do
		if not M.mason_ready(registry.get_package(name):get_install_path()) then
			error("Mason artifacts missing after installation: " .. name, 0)
		end
	end
end

function M.mason_ready(path)
	local receipt = path .. "/mason-receipt.json"
	if vim.fn.filereadable(receipt) ~= 1 then
		return false
	end
	local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(receipt), "\n"))
	if not ok or not data.links or not data.links.bin then
		return false
	end
	local bin = vim.fn.fnamemodify(path, ":h:h") .. "/bin/"
	for name, _ in pairs(data.links.bin) do
		if vim.fn.executable(bin .. name) ~= 1 then
			return false
		end
	end
	return true
end

function M.preview_ready(path)
	return pcall(M.run, {
		"node",
		"-e",
		"for (const name of Object.keys(require('./package.json').dependencies)) require.resolve(name)",
	}, { cwd = path .. "/app" })
end

function M.preview(path)
	if not M.preview_ready(path) then
		M.run({ "yarn", "install", "--frozen-lockfile" }, { cwd = path .. "/app" })
	end
	if not M.preview_ready(path) then
		error("Markdown preview dependencies are missing after build", 0)
	end
end

function M.databricks_matches(python, revision)
	local ok, result = pcall(M.run, {
		python,
		"-B",
		"-c",
		"import sys; from importlib.metadata import distribution; assert sys.version_info[:2] == (3, 12); print(distribution('databricks-nvim').read_text('direct_url.json'))",
	})
	if not ok then
		return false
	end
	local parsed, metadata = pcall(vim.json.decode, result)
	return parsed and type(metadata) == "table" and metadata.vcs_info ~= nil and metadata.vcs_info.commit_id == revision
end

function M.setup(data, root)
	M.prerequisites()
	print("Preparing stable Python host...")
	M.environment(data .. "/python-host", "3.13", manifest.host_packages)
	M.plugins(root)
end

function M.notebooks(data)
	print("Preparing Python notebook environment and Jupytext...")
	local python = data .. "/notebook-venv/bin/python"
	M.environment(data .. "/notebook-venv", "3.13", manifest.notebook_packages)
	local specs = vim.json.decode(
		M.run({ data .. "/python-host/bin/python", "-B", "-m", "jupyter", "kernelspec", "list", "--json" })
	).kernelspecs
	local existing = specs["nvim-default"]
	if existing and existing.spec.argv[1] ~= python then
		error("nvim-default belongs to another interpreter; refusing to replace it", 0)
	end
	M.run({
		python,
		"-m",
		"ipykernel",
		"install",
		"--user",
		"--name",
		"nvim-default",
		"--display-name",
		"Global notebook environment",
	})
	M.run({ "uv", "tool", "install", "jupytext" })
end

function M.databricks(root)
	print("Installing locked Databricks helpers in Python 3.12...")
	local revision = M.databricks_revision(root .. "/lazy-lock.json")
	M.run({
		"uv",
		"tool",
		"install",
		"--python",
		"3.12",
		"git+https://github.com/ravila4/databricks.nvim@" .. revision,
	})
	if vim.fn.executable("databricks") == 0 then
		print("Databricks helpers installed; install the Databricks CLI separately before authenticating.")
	end
end

function M.r(data, root, executable, library)
	executable = M.r_executable(executable)
	executable = vim.fn.fnamemodify(executable, ":p")
	library = library or vim.env.R_LIBRARY or (data .. "/r-library")
	if library:sub(1, 1) ~= "/" then
		error("R_LIBRARY must be an absolute path", 0)
	end
	local host = data .. "/python-host/bin/python"
	local jupyter_data =
		M.run({ host, "-B", "-c", "from jupyter_core.paths import jupyter_data_dir; print(jupyter_data_dir())" })
	local kernel = jupyter_data .. "/kernels/nvim-r"
	M.check_r_kernel(kernel)
	vim.fn.mkdir(library, "p")
	vim.fn.mkdir(jupyter_data .. "/kernels", "p")
	local stage = assert(vim.uv.fs_mkdtemp(jupyter_data .. "/kernels/.nvim-r-XXXXXX"))
	local ok, err = pcall(function()
		local env =
			{ R_LIBS_USER = library, PATH = data .. "/python-host/bin:" .. vim.env.PATH, JUPYTER_DATA_DIR = stage }
		M.run(
			{ executable, "--vanilla", "--slave", "-f", root .. "/scripts/bootstrap-r.R", "--args", library },
			{ env = env }
		)
		local staged_kernel = stage .. "/kernels/nvim-r"
		local spec = vim.json.decode(table.concat(vim.fn.readfile(staged_kernel .. "/kernel.json"), "\n"))
		spec.argv[1] = executable
		spec.env = vim.tbl_extend("force", spec.env or {}, { R_LIBS_USER = library })
		spec.metadata = vim.tbl_extend("force", spec.metadata or {}, { nvim_config = true })
		vim.fn.writefile({ vim.json.encode(spec) }, staged_kernel .. "/kernel.json")
		M.check_r_kernel(kernel)
		if vim.uv.fs_stat(kernel) then
			assert(vim.uv.fs_rename(staged_kernel .. "/kernel.json", kernel .. "/kernel.json"))
		else
			assert(vim.uv.fs_rename(staged_kernel, kernel))
		end
	end)
	vim.fn.delete(stage, "rf")
	if not ok then
		error(err, 0)
	end
	local config = data .. "/r-config.json"
	vim.fn.writefile({ vim.json.encode({ executable = executable, library = library }) }, config .. ".tmp")
	assert(vim.uv.fs_rename(config .. ".tmp", config))
end

function M.r_executable(executable)
	executable = executable or vim.env.R_EXECUTABLE or vim.fn.exepath("R")
	if executable ~= "" and executable:sub(1, 1) ~= "/" then
		error("R_EXECUTABLE must be an absolute path", 0)
	end
	if executable == "" or vim.fn.executable(executable) == 0 then
		error("R executable not found: " .. (executable == "" and "R (set R_EXECUTABLE or install R)" or executable), 0)
	end
	return executable
end

return M
