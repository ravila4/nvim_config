local kernels = require("config.notebook_kernels")

describe("Notebook kernel selection", function()
	it("prefers the saved choice over project and global kernels", function()
		assert.are.equal("chosen", kernels.select("chosen", { "chosen", "project", "global" }, "project", "global"))
	end)
	it("does not silently replace an unavailable saved choice", function()
		local selected, reason = kernels.select("missing", { "project", "global" }, "project", "global")
		assert.is_nil(selected)
		assert.are.equal("saved_missing", reason)
	end)
	it("prefers the project kernel without an explicit choice", function()
		assert.are.equal("project", kernels.select(nil, { "project", "global" }, "project", "global"))
	end)
	it("falls back to the global kernel when the project is unusable", function()
		assert.are.equal("global", kernels.select(nil, { "global" }, nil, "global"))
	end)
	it("requests the picker when no default is usable", function()
		assert.is_nil(kernels.select(nil, { "other" }, nil, nil))
	end)
end)

describe("Preparing an environment kernel", function()
	it("ignores a missing interpreter", function()
		local called, result = false, true
		kernels.prepare({ name = "missing", python = "/nonexistent/notebook/python" }, function(value)
			called, result = true, value
		end)
		assert.is_true(called)
		assert.is_nil(result)
	end)
	it("rejects an interpreter that cannot install ipykernel", function()
		local called, result = false, true
		kernels.prepare({ name = "invalid", python = "/usr/bin/false", label = "Invalid" }, function(value)
			called, result = true, value
		end)
		assert.is_true(vim.wait(5000, function()
			return called
		end))
		assert.is_nil(result)
	end)
	it("registers an absolute interpreter without changing the Python host", function()
		local system = vim.system
		local host, argv = vim.g.python3_host_prog, nil
		vim.system = function(command, _, callback)
			argv = command
			callback({ code = 0 })
		end
		local candidate = { name = "project", python = "/usr/bin/true", label = "Project" }
		local result
		kernels.prepare(candidate, function(value)
			result = value
		end)
		vim.wait(1000, function()
			return result ~= nil
		end)
		vim.system = system
		assert.are.same({
			"/usr/bin/true",
			"-m",
			"ipykernel",
			"install",
			"--user",
			"--name",
			"project",
			"--display-name",
			"Project",
		}, argv)
		assert.are.same(candidate, result)
		assert.are.equal(host, vim.g.python3_host_prog)
	end)
end)

describe("Kernel startup commands", function()
	local buf, previous, prepare, temp, picker
	before_each(function()
		previous = vim.api.nvim_get_current_buf()
		buf = vim.api.nvim_create_buf(true, false)
		vim.api.nvim_buf_set_name(buf, vim.fn.tempname() .. ".ipynb")
		vim.api.nvim_set_current_buf(buf)
		vim.g.kernel_calls = {}
		vim.g.test_running_kernels = {}
		vim.g.test_kernel_name = ""
		vim.g.test_available_kernels = { "nvim-default" }
		temp = vim.fn.tempname()
		vim.fn.mkdir(temp .. "/.venv", "p")
		vim.api.nvim_buf_set_name(buf, temp .. "/a.ipynb")
		prepare = kernels.prepare
		picker = vim.ui.select
		kernels.prepare = function(candidate, callback)
			callback(candidate)
		end
		vim.cmd([[
function! MoltenAvailableKernels(...) abort
  return g:test_available_kernels
endfunction
function! MoltenRunningKernels(...) abort
  return g:test_running_kernels
endfunction
function! MoltenKernelName(...) abort
  return g:test_kernel_name
endfunction
command! -nargs=1 MoltenInit call add(g:kernel_calls, ['init', <q-args>]) | let g:test_kernel_name = <q-args>
command! -nargs=1 MoltenSwitchKernel call add(g:kernel_calls, ['switch', <q-args>]) | let g:test_kernel_name = <q-args>
command! MoltenImportOutput call add(g:kernel_calls, ['import'])
]])
	end)
	after_each(function()
		kernels.prepare = prepare
		vim.ui.select = picker
		vim.fn.delete(temp, "rf")
		vim.api.nvim_set_current_buf(previous)
		vim.api.nvim_buf_delete(buf, { force = true })
	end)
	it("imports saved outputs after initializing a kernel", function()
		kernels.start(buf, { name = "global", label = "Global" }, false, true)
		assert.are.same({ { "init", "global" }, { "import" } }, vim.g.kernel_calls)
	end)
	it("switches existing kernels without reimporting stale disk outputs", function()
		vim.g.test_running_kernels = { "old" }
		kernels.start(buf, { name = "project", label = "Project" }, false, true)
		assert.are.same({ { "switch", "project" } }, vim.g.kernel_calls)
	end)
	it("opens with the prepared project environment", function()
		kernels.open(buf, {})
		assert.are.equal("init", vim.g.kernel_calls[1][1])
		assert.matches("^nvim%-project%-", vim.g.kernel_calls[1][2])
	end)
	it("opens with the global default when the project cannot run a kernel", function()
		kernels.prepare = function(candidate, callback)
			callback(candidate.name == "nvim-default" and candidate or nil)
		end
		kernels.open(buf, {})
		assert.are.equal("nvim-default", vim.g.kernel_calls[1][2])
	end)
	it("prompts for a missing recorded Databricks kernel without launching locally", function()
		local prompted = false
		vim.ui.select = function()
			prompted = true
		end
		kernels.open(buf, { kernelspec = { name = "databricks-work-cluster" } })
		assert.is_true(prompted)
		assert.are.same({}, vim.g.kernel_calls)
	end)
	it("retains an available recorded Databricks kernel", function()
		vim.g.test_available_kernels = { "databricks-work-cluster" }
		kernels.open(buf, { kernelspec = { name = "databricks-work-cluster" } })
		assert.are.equal("databricks-work-cluster", vim.g.kernel_calls[1][2])
	end)
	it("cancelling the picker does not launch or save a kernel", function()
		vim.ui.select = function(_, _, callback)
			callback(nil)
		end
		kernels.pick(buf)
		assert.are.same({}, vim.g.kernel_calls)
		assert.is_nil(kernels.load_choice(vim.api.nvim_buf_get_name(buf)))
	end)
	it("does not persist a refused switch", function()
		vim.g.test_running_kernels = { "old" }
		vim.g.test_kernel_name = "old"
		vim.cmd("command! -nargs=1 MoltenSwitchKernel echo ''")
		kernels.start(buf, { name = "new" }, true, false)
		assert.is_nil(kernels.load_choice(vim.api.nvim_buf_get_name(buf)))
	end)
end)

describe("Notebook kernel persistence", function()
	local temp
	before_each(function()
		temp = vim.fn.tempname()
		vim.fn.mkdir(temp, "p")
	end)
	after_each(function()
		vim.fn.delete(temp, "rf")
	end)
	it("restores an explicit choice in a new module instance", function()
		local choice = { name = "chosen", python = "/project/.venv/bin/python", label = "Project" }
		kernels.save_choice("/project/a.ipynb", choice, temp)
		package.loaded["config.notebook_kernels"] = nil
		assert.are.same(choice, require("config.notebook_kernels").load_choice("/project/a.ipynb", temp))
	end)
	it("keeps choices separate for notebooks with the same basename", function()
		kernels.save_choice("/one/a.ipynb", { name = "chosen" }, temp)
		assert.is_nil(kernels.load_choice("/two/a.ipynb", temp))
	end)
	it("finds a project environment without changing the provider environment", function()
		vim.fn.mkdir(temp .. "/project/.venv/bin", "p")
		vim.fn.mkdir(temp .. "/project/notebooks", "p")
		assert.are.equal(
			temp .. "/project/.venv/bin/python",
			kernels.project_python(temp .. "/project/notebooks/a.ipynb")
		)
	end)
end)
