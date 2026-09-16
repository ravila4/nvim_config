describe("R integration", function()
	local buffers = {}
	local function buffer(ft, listed, kind, name)
		local buf = vim.api.nvim_create_buf(listed, false)
		buffers[#buffers + 1] = buf
		vim.bo[buf].buftype = kind or ""
		vim.api.nvim_buf_set_name(buf, name or ("/tmp/integration-" .. buf .. ".R"))
		vim.bo[buf].filetype = ft
		return buf
	end
	after_each(function()
		for _, buf in ipairs(buffers) do
			vim.api.nvim_buf_delete(buf, { force = true })
		end
		buffers = {}
	end)

	it("accepts ordinary R scripts and R help", function()
		local integration = require("config.r_integration")
		assert.is_true(integration.supports(buffer("r", true)))
		assert.is_true(integration.supports(buffer("rhelp", false, "nofile")))
	end)

	it("rejects document and hidden extraction buffers", function()
		local integration = require("config.r_integration")
		assert.is_false(integration.supports(buffer("quarto", true)))
		assert.is_false(integration.supports(buffer("rmd", true)))
		assert.is_false(integration.supports(buffer("r", false, "nofile")))
		assert.is_false(integration.supports(buffer("r", false)))
		assert.is_false(integration.supports(buffer("r", true, "nofile")))
	end)

	it("uses the interpreter and library selected by setup", function()
		local path = vim.fn.tempname()
		vim.fn.writefile({ vim.json.encode({ executable = "/selected/bin/R", library = "/selected/library" }) }, path)
		local selected = require("config.r_integration").read_config(path)
		vim.fn.delete(path)
		assert.same({ executable = "/selected/bin/R", library = "/selected/library" }, selected)
	end)

	it("rejects incomplete setup configuration", function()
		local path = vim.fn.tempname()
		vim.fn.writefile({ '{"executable":"R"}' }, path)
		assert.has_error(function()
			require("config.r_integration").read_config(path)
		end)
		vim.fn.delete(path)
	end)

	it("does not require optional R setup for other languages", function()
		assert.is_nil(require("config.r_integration").read_config(vim.fn.tempname()))
	end)

	for _, order in ipairs({ { "r", "quarto" }, { "quarto", "r" } }) do
		it("sources R ftplugin only for scripts in " .. table.concat(order, "/") .. " order", function()
			local integration = require("config.r_integration")
			local runtime = vim.cmd.runtime
			local sourced = {}
			vim.cmd.runtime = function(path)
				sourced[#sourced + 1] = { path, vim.bo.filetype }
			end
			local ok, err = pcall(function()
				for _, ft in ipairs(order) do
					local buf = buffer(ft, true)
					integration.attach(buf)
					integration.attach(buf)
				end
				integration.attach(buffer("r", false, "nofile"))
			end)
			vim.cmd.runtime = runtime
			assert.is_true(ok, err)
			assert.same({ { "ftplugin/r_rnvim.lua", "r" } }, sourced)
			assert.same({}, vim.g.R_filetypes)
		end)
	end

	it("restores disabled automatic attachment after a plugin error", function()
		local runtime = vim.cmd.runtime
		vim.cmd.runtime = function()
			error("plugin failed")
		end
		local ok = pcall(require("config.r_integration").attach, buffer("r", true))
		vim.cmd.runtime = runtime
		assert.is_false(ok)
		assert.same({}, vim.g.R_filetypes)
	end)

	it("keeps source tracking on R scripts when visiting Quarto", function()
		local original_r, original_edit = package.loaded.r, package.loaded["r.edit"]
		local original_library = vim.env.R_LIBS_USER
		local current, options
		package.loaded.r = {
			setup = function(opts)
				options = opts
			end,
		}
		package.loaded["r.edit"] = {
			buf_enter = function()
				current = vim.api.nvim_get_current_buf()
			end,
		}
		local ok, err = pcall(function()
			require("config.r_integration").setup({ executable = "/selected/bin/R", library = "/selected/library" })
			local script = buffer("r", true)
			vim.api.nvim_set_current_buf(script)
			require("r.edit").buf_enter()
			vim.api.nvim_set_current_buf(buffer("quarto", true))
			require("r.edit").buf_enter()
			vim.api.nvim_set_current_buf(buffer("r", false, "nofile"))
			require("r.edit").buf_enter()
			assert.equal(script, current)
			assert.equal("/selected/bin/R", options.R_app)
			assert.equal(options.R_app, options.R_cmd)
			assert.equal("/selected/library", vim.env.R_LIBS_USER)
			for _, enabled in pairs(options.r_ls) do
				assert.is_false(enabled)
			end
		end)
		package.loaded.r, package.loaded["r.edit"] = original_r, original_edit
		vim.env.R_LIBS_USER = original_library
		pcall(vim.api.nvim_del_augroup_by_name, "RScriptIntegration")
		assert.is_true(ok, err)
	end)

	it("reports missing setup only when opening a user R buffer", function()
		vim.api.nvim_set_current_buf(buffer("r", false, "nofile"))
		local notify, messages = vim.notify, {}
		vim.notify = function(message)
			messages[#messages + 1] = message
		end
		local ok, err = pcall(function()
			require("config.r_integration").setup(nil)
			assert.same({}, messages)
			buffer("r", true)
			assert.equal(1, #messages)
			assert.matches("Run make r", messages[1])
		end)
		vim.notify = notify
		pcall(vim.api.nvim_del_augroup_by_name, "RScriptIntegration")
		assert.is_true(ok, err)
	end)
end)
