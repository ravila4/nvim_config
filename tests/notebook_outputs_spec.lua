local outputs = require("config.notebook_outputs")

local function notebook(kernel_name, cells)
	return {
		metadata = { kernelspec = { name = kernel_name } },
		cells = cells,
	}
end

describe("Saved notebook outputs", function()
	it("has outputs when any code cell carries one", function()
		local nb = notebook("python3", {
			{ cell_type = "markdown", source = "# title" },
			{ cell_type = "code", source = "x", outputs = {} },
			{ cell_type = "code", source = "y", outputs = { { output_type = "stream" } } },
		})
		assert.is_true(outputs.has_outputs(nb))
	end)

	it("has no outputs when every code cell is empty", function()
		local nb = notebook("python3", {
			{ cell_type = "code", source = "x", outputs = {} },
			{ cell_type = "code", source = "y" },
		})
		assert.is_false(outputs.has_outputs(nb))
	end)

	it("has no outputs for a notebook without cells", function()
		assert.is_false(outputs.has_outputs({ metadata = {} }))
	end)
end)

describe("Kernel for importing outputs", function()
	local available = { "python3", "empiroar", "venv" }

	it("uses the notebook kernelspec when it is installed", function()
		assert.are.equal("empiroar", outputs.pick_kernel(notebook("empiroar", {}), available, "/home/x/.venv"))
	end)

	it("falls back to the active venv name when the kernelspec is missing", function()
		assert.are.equal("venv", outputs.pick_kernel(notebook("unknown", {}), available, "/proj/venv"))
	end)

	it("falls back to the active venv when the notebook has no kernelspec", function()
		assert.are.equal("venv", outputs.pick_kernel({ metadata = {} }, available, "/proj/venv"))
	end)

	it("returns nil when neither the kernelspec nor the venv is installed", function()
		assert.is_nil(outputs.pick_kernel(notebook("unknown", {}), available, "/proj/other"))
	end)

	it("returns nil without a venv when the kernelspec is missing", function()
		assert.is_nil(outputs.pick_kernel(notebook("unknown", {}), available, nil))
	end)
end)
