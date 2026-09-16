describe("Editor-owned executable paths", function()
	local data_dir

	before_each(function()
		data_dir = vim.fn.tempname() .. " isolated data"
	end)

	after_each(function()
		vim.fn.delete(data_dir, "rf")
	end)

	local function evaluate(expression)
		local output = vim.fn.system({
			"env",
			"XDG_DATA_HOME=" .. data_dir,
			"NVIM_APPNAME=nvim",
			"NVIM_LOG_FILE=/dev/null",
			vim.v.progpath,
			"--headless",
			"-u",
			"NONE",
			"-i",
			"NONE",
			"-n",
			"--cmd",
			"set rtp^=" .. vim.fn.fnameescape(vim.fn.getcwd()),
			"-c",
			"lua " .. expression,
			"-c",
			"qa!",
		})
		assert.equal(0, vim.v.shell_error, output)
		return vim.trim(output):match("[^\n]+$")
	end

	it("uses the active data directory for the Python host", function()
		assert.equal(
			data_dir .. "/nvim/python-host/bin/python",
			evaluate('require("config.settings"); print(vim.g.python3_host_prog)')
		)
	end)

	it("uses Mason's executable in the active data directory for Ruff", function()
		assert.equal(
			data_dir .. "/nvim/mason/bin/ruff",
			evaluate([[
      vim.lsp.enable = function() end
      for _, spec in ipairs(require("plugins.lsp")) do
        if spec[1] == "neovim/nvim-lspconfig" then spec.config() end
      end
      print(vim.lsp.config.ruff.cmd[1])
    ]])
		)
	end)

	it("configures Python paths without deprecated table helpers", function()
		assert.equal(
			"configured",
			evaluate([[
        vim.tbl_flatten = function() error("vim.tbl_flatten is deprecated") end
        vim.lsp.enable = function() end
        for _, spec in ipairs(require("plugins.lsp")) do
          if spec[1] == "neovim/nvim-lspconfig" then spec.config() end
        end
        print("configured")
      ]])
		)
	end)

	it("does not enable the R language server before R setup", function()
		local enabled = vim.json.decode(evaluate([[
      local enabled
      vim.lsp.enable = function(names) enabled = names end
      for _, spec in ipairs(require("plugins.lsp")) do
        if spec[1] == "neovim/nvim-lspconfig" then spec.config() end
      end
      print(vim.json.encode(enabled))
    ]]))
		assert.is_false(vim.tbl_contains(enabled, "r_language_server"))
		assert.is_true(vim.tbl_contains(enabled, "pyright"))
	end)

	it("runs the R language server with the selected R installation and library", function()
		vim.fn.mkdir(data_dir .. "/nvim", "p")
		vim.fn.writefile(
			{ vim.json.encode({
				executable = "/selected/R",
				library = "/selected/library",
			}) },
			data_dir .. "/nvim/r-config.json"
		)
		local selected = vim.json.decode(evaluate([[
      local enabled
      vim.lsp.enable = function(names) enabled = names end
      for _, spec in ipairs(require("plugins.lsp")) do
        if spec[1] == "neovim/nvim-lspconfig" then spec.config() end
      end
      print(vim.json.encode({
        enabled = enabled,
        cmd = vim.lsp.config.r_language_server.cmd,
        env = vim.lsp.config.r_language_server.cmd_env,
      }))
    ]]))
		assert.same({ "/selected/R", "--no-echo", "--no-restore", "-e", "languageserver::run()" }, selected.cmd)
		assert.equal("/selected/library", selected.env.R_LIBS_USER)
		assert.is_true(vim.tbl_contains(selected.enabled, "r_language_server"))
	end)
end)
