vim.o.shadafile = "NONE"
vim.o.swapfile = false
vim.o.loadplugins = true
local root = arg[1]
vim.opt.rtp:prepend(root)
local bootstrap = require("config.bootstrap")
local manifest = require("config.bootstrap_manifest")
local data = vim.fn.stdpath("data")
local lock = vim.json.decode(table.concat(vim.fn.readfile(root .. "/lazy-lock.json"), "\n"))
local temporary_lock = vim.fn.tempname()
local ok, err = pcall(function()
	local lazy_path = data .. "/lazy/lazy.nvim"
	if not vim.uv.fs_stat(lazy_path) then
		bootstrap.run({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", lazy_path })
		bootstrap.run({ "git", "-C", lazy_path, "checkout", lock["lazy.nvim"].commit })
	end
	vim.opt.rtp:prepend(lazy_path)
	vim.g.python3_host_prog = data .. "/python-host/bin/python"
	vim.fn.writefile({ vim.json.encode(lock) }, temporary_lock)
	local specs = {}
	for _, path in ipairs(vim.fn.glob(root .. "/lua/plugins/*.lua", false, true)) do
		for _, spec in ipairs(dofile(path)) do
			specs[#specs + 1] = bootstrap.install_spec(spec)
		end
	end
	require("lazy").setup(specs, {
		lockfile = temporary_lock,
		install = { missing = false },
		checker = { enabled = false },
		change_detection = { enabled = false },
	})
	local plugins = require("lazy.core.config").plugins
	for name, plugin in pairs(plugins) do
		if lock[name] and vim.uv.fs_stat(plugin.dir .. "/.git") then
			local head = bootstrap.run({ "git", "-C", plugin.dir, "rev-parse", "HEAD" })
			if head ~= lock[name].commit then
				error("Installed plugin differs from lock: " .. name .. "; restore it explicitly before setup", 0)
			end
		end
	end
	require("lazy").install({ wait = true, lockfile = true, show = false })
	bootstrap.plugin_errors(plugins)
	if plugins["markdown-preview.nvim"] then
		bootstrap.preview(plugins["markdown-preview.nvim"].dir)
	end
	for name, plugin in pairs(plugins) do
		if lock[name] and bootstrap.run({ "git", "-C", plugin.dir, "rev-parse", "HEAD" }) ~= lock[name].commit then
			error("Plugin did not install at locked revision: " .. name, 0)
		end
	end
	require("lazy").load({ plugins = { "mason.nvim", "nvim-treesitter", "molten-nvim" } })
	require("mason").setup()
	print("Checking Mason tools...")
	local registry = require("mason-registry")
	local refreshed, success = false, false
	registry.refresh(function(ok_refresh)
		success = ok_refresh
		refreshed = true
	end)
	bootstrap.await("Mason registry", function()
		return refreshed
	end)
	if success == false then
		error("Mason registry refresh failed", 0)
	end
	bootstrap.mason(registry, manifest.tools)
	local treesitter = require("nvim-treesitter")
	print("Checking Tree-sitter parsers...")
	treesitter.setup()
	treesitter.install(manifest.parsers):wait(600000)
	for _, parser in ipairs(manifest.parsers) do
		if not pcall(vim.treesitter.language.add, parser) then
			error("Parser did not install: " .. parser, 0)
		end
	end
	vim.cmd("runtime plugin/rplugin.vim")
	print("Registering Molten remote plugin...")
	vim.cmd("UpdateRemotePlugins")
	local remote = vim.fn.stdpath("data") .. "/rplugin.vim"
	if not table.concat(vim.fn.readfile(remote), "\n"):find("MoltenInit", 1, true) then
		error("Molten remote plugin registration failed", 0)
	end
end)
vim.fn.delete(temporary_lock)
if not ok then
	io.stderr:write(tostring(err) .. "\n")
	vim.cmd("cquit 1")
end
