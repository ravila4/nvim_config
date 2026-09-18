-- Parsing of `jupyter kernelspec list --json`, shared by the local and the
-- remote kernel modules.
local M = {}

-- Returns picker choices keyed by kernelspec name, or nil and a message.
-- Entries without a usable argv are dropped.
function M.parse(stdout)
	local ok, data = pcall(vim.json.decode, stdout or "")
	if not ok or type(data) ~= "table" or type(data.kernelspecs) ~= "table" then
		return nil, "invalid Jupyter response"
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
				argv = spec.argv,
			}
		end
	end
	return choices
end

return M
