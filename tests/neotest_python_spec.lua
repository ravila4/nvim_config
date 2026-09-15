describe("Neotest Python selection", function()
	local python, system, fn_system, adapter, neotest, conda, venv
	local uv_available, uv_success

	before_each(function()
		system, fn_system = vim.system, vim.fn.system
		adapter, neotest = package.loaded["neotest-python"], package.loaded.neotest
		conda, venv = vim.env.CONDA_PREFIX, vim.env.VIRTUAL_ENV
		vim.env.CONDA_PREFIX, vim.env.VIRTUAL_ENV = nil, nil
		_G._neotest_python_path = nil
		uv_available, uv_success = true, true
		-- The process boundary returns an interpreter from the requested working directory.
		vim.system = function(_, opts)
			if not uv_available then
				error("uv is not executable")
			end
			return {
				wait = function()
					return {
						code = uv_success and 0 or 1,
						stdout = uv_success and (opts.cwd .. "/.venv/bin/python\n") or "",
					}
				end,
			}
		end
		vim.fn.system = function()
			fn_system({ uv_success and "/usr/bin/true" or "/usr/bin/false" })
			return uv_success and (vim.fn.getcwd() .. "/.venv/bin/python\n") or ""
		end
		package.loaded["neotest-python"] = function(opts)
			python = opts.python
			return {}
		end
		package.loaded.neotest = { setup = function() end }
		dofile("lua/plugins/testing.lua")[1].config(nil, {})
	end)

	after_each(function()
		vim.system, vim.fn.system = system, fn_system
		package.loaded["neotest-python"], package.loaded.neotest = adapter, neotest
		vim.env.CONDA_PREFIX, vim.env.VIRTUAL_ENV = conda, venv
		_G._neotest_python_path = nil
	end)

	it("resolves each project independently of the editor working directory", function()
		assert.are.equal("/project-a/.venv/bin/python", python("/project-a"))
		assert.are.equal("/project-b/.venv/bin/python", python("/project-b"))
	end)

	it("does not retain an environment after the project changes", function()
		python(vim.fn.getcwd())
		uv_success = false
		vim.env.VIRTUAL_ENV = "/replacement"
		assert.are.equal("/replacement/bin/python", python(vim.fn.getcwd()))
	end)

	it("falls back to an active environment when uv is missing", function()
		uv_available, uv_success = false, false
		vim.env.CONDA_PREFIX = "/conda"
		assert.are.equal("/conda/bin/python", python("/project"))
	end)

	it("falls back to PATH when no environment is available", function()
		uv_success = false
		assert.are.equal("python", python("/project"))
	end)
end)
