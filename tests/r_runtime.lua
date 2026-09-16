-- Run with: nvim --headless -u NONE -l tests/r_runtime.lua /path/to/R.nvim
vim.opt.rtp:prepend(vim.fn.getcwd())
vim.opt.rtp:append(assert(arg[1], "Pass the pinned R.nvim checkout path"))
vim.g.maplocalleader = " "
vim.cmd("filetype plugin on")

local config = require("r.config")
local initialized = {}
-- Starting the bundled server installs nvimcom. Keep that external operation
-- outside this routing test; execute the upstream ftplugins and maps unchanged.
config.real_setup = function()
	initialized[#initialized + 1] = vim.api.nvim_get_current_buf()
end
config.get_config().roxygen_hl = false

local spec = require("plugins.r-lang")[1]
spec.init()
local integration = require("config.r_integration")
integration.read_config = function()
	return { executable = "/test/R", library = "/test/library" }
end
-- Match Lazy's first matching FileType activation, including a hidden R buffer.
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "r", "rhelp" },
	once = true,
	callback = spec.config,
})

local function open(ft, listed, kind)
	local buf = vim.api.nvim_create_buf(listed, false)
	vim.bo[buf].buftype = kind or ""
	vim.api.nvim_buf_set_name(buf, "/tmp/r-routing-" .. buf .. "." .. ft)
	vim.api.nvim_set_current_buf(buf)
	vim.bo[buf].filetype = ft
	require("r.edit").buf_enter()
	return buf
end

if arg[2] == "script-first" then
	open("r", true)
	assert(#initialized == 1, "First R script did not initialize R.nvim")
else
	open("r", false, "nofile")
	assert(#initialized == 0, "First hidden R buffer initialized R.nvim")
end

for _, order in ipairs({ { "r", "quarto" }, { "quarto", "r" } }) do
	for _, ft in ipairs(order) do
		local before = #initialized
		local buf = open(ft, true)
		if ft == "r" then
			assert(#initialized == before + 1, "R ftplugin did not attach exactly once")
			assert(vim.fn.maparg(" rf", "n") ~= "", "R start mapping missing")
			assert(require("r.edit").get_rscript_buf() == buf, "R source tracking failed")
		else
			assert(#initialized == before, "R.nvim attached to Quarto")
			assert(vim.fn.maparg(" rf", "n") == "", "R mapping leaked to Quarto")
		end
	end
end
local before = #initialized
local source = require("r.edit").get_rscript_buf()
open("r", false, "nofile")
assert(#initialized == before, "R.nvim attached to hidden extracted R buffer")
assert(vim.fn.maparg(" rf", "n") == "", "R mapping leaked to extracted R buffer")
assert(require("r.edit").get_rscript_buf() == source, "Hidden buffer replaced active source")
open("rmd", true)
assert(#initialized == before, "R.nvim attached to RMarkdown")
open("rhelp", false, "nofile")
assert(#initialized == before + 1, "R help integration unavailable")
assert(vim.deep_equal(vim.g.R_filetypes, {}), "Automatic upstream attachment left enabled")
print("R.nvim upstream routing: both load orders, hidden buffers, source tracking and help passed")
