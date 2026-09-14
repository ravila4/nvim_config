local notebook = require("config.notebook_outline")

describe("Notebook outline", function()
	it("keeps execution state visible for long cell titles", function()
		local tree = notebook.symbols({ "```python", string.rep("x", 100), "```" }, {})
		assert.is_true(vim.fn.strdisplaywidth(tree[1].name) < 40)
		assert.are.equal("○", tree[1].notebook_icon)
	end)

	it("does not label an unexecuted imported cell as saved execution", function()
		local tree = notebook.symbols({ "```python", "x = 1", "```" }, {
			{ start_line = 1, end_line = 1, source = "x = 1", status = "not run", old = true },
		})
		assert.are.equal("not run", tree[1].detail)
	end)
	it("nests numbered code cells under headings with full cursor ranges", function()
		local tree = notebook.symbols({
			"# Analysis",
			"",
			"```python",
			"# Load data",
			"df = load()",
			"```",
			"## QC",
			"```python",
			"qc(df)",
			"```",
		}, {})
		assert.are.equal("Analysis", tree[1].name)
		assert.are.equal("Cell 1: Load data", tree[1].children[1].name)
		assert.are.equal(2, tree[1].children[1].range.start.line)
		assert.are.equal(5, tree[1].children[1].range["end"].line)
		assert.are.equal("Cell 2: qc(df)", tree[1].children[2].children[1].name)
		assert.are.equal(9, tree[1].range["end"].line)
	end)

	it("ignores frontmatter and headings inside fences and accepts long tilde fences", function()
		local tree = notebook.symbols(
			{ "---", "# metadata", "---", "Title", "=====", "~~~~python", "# comment", "```", "~~~~", "# Next" },
			{}
		)
		assert.are.equal(2, #tree)
		assert.are.equal("Title", tree[1].name)
		assert.are.equal(1, #tree[1].children)
		assert.are.equal("Next", tree[2].name)
	end)

	it("includes empty and unfinished cells", function()
		local tree = notebook.symbols({ "```python", "```", "```python", "x = 1" }, {})
		assert.are.equal("Cell 1", tree[1].name)
		assert.are.equal("Cell 2: x = 1", tree[2].name)
		assert.are.equal(3, tree[2].range["end"].line)
	end)

	it("shows live execution and detects changed source", function()
		local lines = { "```python", "x = 1", "```" }
		local info =
			{ { start_line = 1, end_line = 1, source = "x = 1", status = "done", old = false, execution_count = 4 } }
		assert.are.equal("done [4]", notebook.symbols(lines, info)[1].detail)
		lines[2] = "x = 2"
		assert.are.equal("modified", notebook.symbols(lines, info)[1].detail)
		info[1].status = "running"
		assert.are.equal("running · modified", notebook.symbols(lines, info)[1].detail)
	end)

	it("does not call a partially executed cell successful", function()
		local tree = notebook.symbols({ "```python", "x = 1", "y = 2", "```" }, {
			{ start_line = 1, end_line = 1, source = "x = 1", status = "done", old = false },
		})
		assert.are.equal("partial", tree[1].detail)
	end)

	it("distinguishes imported error results", function()
		local tree = notebook.symbols({ "```python", "1 / 0", "```" }, {
			{ start_line = 1, end_line = 1, source = "1 / 0", status = "error", old = true, execution_count = 2 },
		})
		assert.are.equal("saved error [2]", tree[1].detail)
	end)

	it("shows saved execution without starting a kernel even for empty outputs", function()
		local tree = notebook.symbols({ "```python", "x = 1", "```" }, {}, {
			{ cell_type = "code", source = { "x = 1" }, execution_count = 3, outputs = {} },
		})
		assert.are.equal("saved done [3]", tree[1].detail)
	end)

	it("does not assign ambiguous saved results to duplicate source", function()
		local tree = notebook.symbols({ "```python", "x = 1", "```" }, {}, {
			{ cell_type = "code", source = "x = 1", execution_count = 1, outputs = {} },
			{ cell_type = "code", source = "x = 1", execution_count = 2, outputs = {} },
		})
		assert.are.equal("not run", tree[1].detail)
	end)
end)
