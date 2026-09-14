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

describe("Environment kernels", function()
	local temp
	before_each(function()
		temp = vim.fn.tempname()
		vim.fn.mkdir(temp .. "/project/.venv/share/jupyter/kernels/python3", "p")
		vim.fn.mkdir(temp .. "/project/notebooks", "p")
	end)
	after_each(function()
		vim.fn.delete(temp, "rf")
	end)

	it("uses the active environment when it contains Jupyter kernels", function()
		assert.are.equal(
			temp .. "/project/.venv",
			outputs.environment_venv(temp .. "/other.ipynb", temp .. "/project/.venv")
		)
	end)

	it("finds the closest project environment for a notebook", function()
		assert.are.equal(
			temp .. "/project/.venv",
			outputs.environment_venv(temp .. "/project/notebooks/analysis.ipynb", nil)
		)
	end)

	it("does not add a missing environment to Jupyter's search path", function()
		assert.is_nil(outputs.environment_venv(temp .. "/missing.ipynb", nil))
	end)

	it("adds the environment's Jupyter directory once", function()
		local path = temp .. "/project/.venv/share/jupyter"
		assert.are.equal(path .. ":/existing", outputs.jupyter_path("/existing", temp .. "/project/.venv"))
		assert.are.equal(path .. ":/existing", outputs.jupyter_path(path .. ":/existing", temp .. "/project/.venv"))
	end)
end)
