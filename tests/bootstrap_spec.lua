local bootstrap
describe("bootstrap", function()
	before_each(function()
		package.loaded["config.bootstrap"] = nil
		bootstrap = require("config.bootstrap")
	end)

	it("rejects failed subprocesses with their diagnostic", function()
		assert.has_error(function()
			bootstrap.run({ "sh", "-c", "echo broken >&2; exit 7" })
		end, "sh failed (7): broken")
	end)

	it("reads the Databricks revision from the existing lock", function()
		local path = vim.fn.tempname()
		vim.fn.writefile({ vim.json.encode({ ["databricks.nvim"] = { commit = string.rep("a", 40) } }) }, path)
		assert.equals(string.rep("a", 40), bootstrap.databricks_revision(path))
		vim.fn.delete(path)
	end)

	it("rejects an invalid locked revision before installing", function()
		local path = vim.fn.tempname()
		vim.fn.writefile({ '{"databricks.nvim":{"commit":"main"}}' }, path)
		assert.has_error(function()
			bootstrap.databricks_revision(path)
		end, "Databricks requires a full commit in lazy-lock.json")
		vim.fn.delete(path)
	end)

	it("repairs packages without recreating an existing environment", function()
		local path = vim.fn.tempname()
		vim.fn.mkdir(path .. "/bin", "p")
		vim.fn.writefile({}, path .. "/bin/python")
		local calls = {}
		bootstrap.run = function(argv)
			calls[#calls + 1] = argv
			return ""
		end
		bootstrap.environment(path, "3.13", { "ipykernel" })
		assert.same({ "uv", "pip", "install", "--python", path .. "/bin/python", "ipykernel" }, calls[1])
		assert.equals(1, #calls)
		vim.fn.delete(path, "rf")
	end)

	it("refuses an occupied environment directory without Python", function()
		local path = vim.fn.tempname()
		vim.fn.mkdir(path)
		assert.has_error(function()
			bootstrap.environment(path, "3.13", {})
		end, "Refusing to replace existing directory without Python: " .. path)
		vim.fn.delete(path, "d")
	end)

	it("keeps optional R tools out of the core install", function()
		local manifest = require("config.bootstrap_manifest")
		assert.is_false(vim.tbl_contains(manifest.tools, "r-languageserver"))
		assert.is_nil(manifest.r_tools)
	end)

	it("checks an empty data directory without creating it", function()
		local path = vim.fn.tempname()
		local report = bootstrap.check(path)
		assert.is_false(report.ok)
		assert.is_nil(vim.uv.fs_stat(path))
		assert.is_true(vim.tbl_contains(report.missing, "Python host"))
	end)

	it("rejects an unrelated R kernelspec without replacing it", function()
		local path = vim.fn.tempname()
		vim.fn.mkdir(path)
		vim.fn.writefile({ '{"argv":["R"],"metadata":{}}' }, path .. "/kernel.json")
		assert.has_error(function()
			bootstrap.check_r_kernel(path)
		end, "Refusing to replace unrelated kernelspec: " .. path)
		assert.equals('{"argv":["R"],"metadata":{}}', vim.fn.readfile(path .. "/kernel.json")[1])
		vim.fn.delete(path, "rf")
	end)

	it("accepts its owned R kernel for repair", function()
		local path = vim.fn.tempname()
		vim.fn.mkdir(path)
		vim.fn.writefile({ '{"metadata":{"nvim_config":true}}' }, path .. "/kernel.json")
		assert.has_no.errors(function()
			bootstrap.check_r_kernel(path)
		end)
		vim.fn.delete(path, "rf")
	end)

	it("waits for asynchronous work and reports timeout", function()
		assert.has_error(function()
			bootstrap.await("Mason", function()
				return false
			end, 1)
		end, "Timed out waiting for Mason")
	end)

	it("sets up the host before plugin registration", function()
		local events = {}
		bootstrap.prerequisites = function() end
		bootstrap.environment = function()
			events[#events + 1] = "host"
		end
		bootstrap.plugins = function()
			events[#events + 1] = "plugins"
		end
		bootstrap.setup("/unused", "/repo")
		assert.same({ "host", "plugins" }, events)
	end)

	it("installs Databricks at the locked revision in Python 3.12", function()
		local commands = {}
		bootstrap.run = function(cmd)
			commands[#commands + 1] = cmd
			return ""
		end
		bootstrap.databricks_revision = function()
			return string.rep("b", 40)
		end
		bootstrap.databricks("/repo")
		assert.same({
			"uv",
			"tool",
			"install",
			"--python",
			"3.12",
			"git+https://github.com/ravila4/databricks.nvim@" .. string.rep("b", 40),
		}, commands[1])
	end)

	it("does not replace a global notebook kernel owned by someone else", function()
		bootstrap.environment = function() end
		bootstrap.run = function(cmd)
			if cmd[2] == "-B" then
				return vim.json.encode({
					kernelspecs = {
						["nvim-default"] = { spec = { argv = { "/other/python" } } },
					},
				})
			end
			return ""
		end
		assert.has_error(function()
			bootstrap.notebooks("/data")
		end, "nvim-default belongs to another interpreter; refusing to replace it")
	end)

	it("refuses R setup before touching anything if R is absent", function()
		assert.has_error(function()
			bootstrap.r("/data", "/repo", "/missing/R")
		end, "R executable not found: /missing/R")
	end)

	it("installs only missing Mason packages and observes completion", function()
		local installed = { pyright = true }
		bootstrap.mason_ready = function(path)
			return installed[path] == true
		end
		local registry = {
			get_package = function(name)
				return {
					get_install_path = function()
						return name
					end,
					get_installed_version = function()
						return nil
					end,
					install = function(_, _, callback)
						installed[name] = true
						callback(true)
					end,
				}
			end,
		}
		bootstrap.mason(registry, { "pyright", "ruff" }, 50)
		assert.same({ pyright = true, ruff = true }, installed)
	end)

	it("does not execute plugin runtime callbacks in bootstrap specs", function()
		local spec = bootstrap.install_spec({
			"plugin",
			lazy = false,
			init = function()
				error("runtime")
			end,
			config = function() end,
			opts = {},
			dependencies = { { "dep", init = function() end } },
		})
		assert.is_nil(spec.init)
		assert.is_nil(spec.config)
		assert.is_nil(spec.opts)
		assert.is_nil(spec.dependencies[1].init)
		assert.is_true(spec.lazy)
	end)

	it("reports failed plugin build tasks", function()
		assert.has_error(function()
			bootstrap.plugin_errors({
				example = { _ = { tasks = { {
					has_errors = function()
						return true
					end,
				} } } },
			})
		end, "Plugin install/build failed: example")
	end)

	it("reports an incomplete optional notebook environment as broken", function()
		local path = vim.fn.tempname()
		vim.fn.mkdir(path .. "/notebook-venv", "p")
		local report = bootstrap.check(path)
		assert.is_true(vim.tbl_contains(report.missing, "Notebook interpreter"))
		vim.fn.delete(path, "rf")
	end)

	it("reports locked plugin revision mismatches", function()
		local path = vim.fn.tempname()
		vim.fn.mkdir(path .. "/lazy/example", "p")
		bootstrap.run = function()
			return "different"
		end
		assert.same(
			{ "Plugin revision: example" },
			bootstrap.check_plugins(path, { example = { commit = "expected" } })
		)
		vim.fn.delete(path, "rf")
	end)

	it("keeps setup from running for missing R in the Makefile prerequisite", function()
		local result = vim.system({
			vim.v.progpath,
			"--headless",
			"-u",
			"NONE",
			"-i",
			"NONE",
			"-l",
			"scripts/bootstrap.lua",
			"r-prerequisite",
		}, { text = true, env = { R_EXECUTABLE = "/missing/R" } }):wait()
		assert.equals(1, result.code)
		assert.is_truthy(result.stderr:find("R executable not found", 1, true))
	end)

	it("publishes R ownership together with its staged kernelspec", function()
		local path = vim.fn.tempname()
		vim.fn.mkdir(path, "p")
		local saved_path, r_env
		bootstrap.run = function(cmd, opts)
			if cmd[1] == "/bin/sh" then
				r_env = opts.env
				local stage = r_env.JUPYTER_DATA_DIR .. "/kernels/nvim-r"
				vim.fn.mkdir(stage, "p")
				vim.fn.writefile({ '{"argv":["R","--slave"]}' }, stage .. "/kernel.json")
			else
				return path .. "/jupyter"
			end
			return ""
		end
		bootstrap.r(path, "/repo", "/bin/sh", path .. "/r-library")
		local spec = vim.json.decode(vim.fn.readfile(path .. "/jupyter/kernels/nvim-r/kernel.json")[1])
		assert.is_true(spec.metadata.nvim_config)
		assert.equals("/bin/sh", spec.argv[1])
		assert.equals(path .. "/r-library", spec.env.R_LIBS_USER)
		assert.is_nil(vim.uv.fs_stat(r_env.JUPYTER_DATA_DIR))
		vim.fn.delete(path, "rf")
	end)

	it("supports a single dependency string in plugin specs", function()
		assert.equals("dependency", bootstrap.install_spec({ "plugin", dependencies = "dependency" }).dependencies)
	end)

	it("normalizes every current plugin spec without loading it", function()
		for _, path in ipairs(vim.fn.glob("lua/plugins/*.lua", false, true)) do
			for _, spec in ipairs(dofile(path)) do
				assert.has_no.errors(function()
					bootstrap.install_spec(spec)
				end)
			end
		end
	end)

	it("does not clone plugins on normal startup before setup", function()
		local stat, system, notify = vim.uv.fs_stat, vim.fn.system, vim.notify
		local settings = package.loaded["config.settings"]
		local called = false
		package.loaded["config.settings"] = {}
		vim.uv.fs_stat = function()
			return nil
		end
		vim.fn.system = function()
			called = true
			error("unexpected installation")
		end
		vim.notify = function() end
		local ok = pcall(dofile, "init.lua")
		vim.uv.fs_stat, vim.fn.system, vim.notify = stat, system, notify
		package.loaded["config.settings"] = settings
		assert.is_true(ok)
		assert.is_false(called)
	end)

	it("includes stdout from a failing installer", function()
		assert.has_error(function()
			bootstrap.run({ "sh", "-c", "echo build-broken; exit 1" })
		end, "sh failed (1): build-broken")
	end)

	it("rejects a Mason directory without a receipt", function()
		local path = vim.fn.tempname()
		vim.fn.mkdir(path)
		assert.is_false(bootstrap.mason_ready(path))
		vim.fn.delete(path, "d")
	end)

	it("reports Mason installation failure immediately", function()
		bootstrap.mason_ready = function()
			return false
		end
		local registry = {
			get_package = function()
				return {
					get_install_path = function()
						return "/missing"
					end,
					get_installed_version = function()
						return nil
					end,
					install = function(_, _, callback)
						callback(false, "network unavailable")
					end,
				}
			end,
		}
		assert.has_error(function()
			bootstrap.mason(registry, { "pyright" }, 100)
		end, "Mason install failed: pyright: network unavailable")
	end)

	it("rebuilds missing markdown preview dependencies", function()
		local built = false
		bootstrap.run = function(cmd)
			if cmd[1] == "yarn" then
				built = true
				return ""
			end
			if not built then
				error("missing node module")
			end
			return ""
		end
		bootstrap.preview("/plugin")
		assert.is_true(built)
	end)

	it("does not rebuild healthy markdown preview dependencies", function()
		local builds = 0
		bootstrap.run = function(cmd)
			if cmd[1] == "yarn" then
				builds = builds + 1
			end
			return ""
		end
		bootstrap.preview("/plugin")
		assert.equals(0, builds)
	end)

	it("checks Databricks installed metadata against the requested revision", function()
		bootstrap.run = function()
			return '{"vcs_info":{"commit_id":"old"}}'
		end
		assert.is_false(bootstrap.databricks_matches("/env/bin/python", "new"))
	end)

	it("repairs an interrupted environment only with its ownership marker", function()
		local path = vim.fn.tempname()
		vim.fn.mkdir(path)
		vim.fn.writefile({ path }, path .. ".nvim-bootstrap")
		local calls = {}
		bootstrap.run = function(cmd)
			calls[#calls + 1] = cmd
			return ""
		end
		bootstrap.environment(path, "3.13", { "ipykernel" })
		assert.same({ "uv", "venv", "--allow-existing", "--python", "3.13", path }, calls[1])
		vim.fn.delete(path, "d")
		vim.fn.delete(path .. ".nvim-bootstrap")
	end)

	it("requires explicit R interpreter paths to be absolute", function()
		assert.has_error(function()
			bootstrap.r_executable("sh")
		end, "R_EXECUTABLE must be an absolute path")
	end)

	it("reports missing packages in the configured R library", function()
		local path = vim.fn.tempname()
		vim.fn.mkdir(path, "p")
		vim.fn.writefile({ vim.json.encode({ executable = "/bin/sh", library = path }) }, path .. "/r-config.json")
		local report = bootstrap.check(path)
		assert.is_true(vim.tbl_contains(report.missing, "R package: IRkernel"))
		vim.fn.delete(path, "rf")
	end)
end)
