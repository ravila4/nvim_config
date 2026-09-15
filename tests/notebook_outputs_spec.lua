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
