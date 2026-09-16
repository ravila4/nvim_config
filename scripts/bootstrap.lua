vim.o.shadafile = "NONE"
vim.o.swapfile = false
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.rtp:prepend(root)
local bootstrap = require("config.bootstrap")
local data = vim.fn.stdpath("data")
local target = arg[1]
local ok, err = pcall(function()
	if target == "check" then
		local report = bootstrap.check(data, root)
		for _, missing in ipairs(report.missing) do
			print("Missing: " .. missing)
		end
		for _, optional in ipairs(report.optional) do
			print("Optional, not configured: " .. optional)
		end
		if not report.ok then
			error("Setup checks failed; see missing components above", 0)
		end
		print("Setup checks passed (offline; no authentication or kernels started)")
	elseif target == "setup" then
		bootstrap.setup(data, root)
	elseif target == "notebooks" then
		bootstrap.notebooks(data)
	elseif target == "r" then
		bootstrap.r(data, root)
	elseif target == "r-prerequisite" then
		bootstrap.r_executable()
	elseif target == "databricks" then
		bootstrap.databricks(root)
	else
		error("Unknown bootstrap target: " .. tostring(target), 0)
	end
end)
if not ok then
	io.stderr:write("\n" .. tostring(err) .. "\n")
	vim.cmd("cquit 1")
end
