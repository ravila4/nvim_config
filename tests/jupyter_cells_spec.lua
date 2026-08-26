local cells = require("config.jupyter_cells")

describe("Python percent cells", function()
	local lines = {
		"# %% bootstrap",
		"from package import value",
		"",
		"result = value()",
		"",
		"# %% next",
		"x = 41",
		"",
		"# %% final",
		"x + 1",
	}

	it("finds the current cell without its marker or trailing blanks", function()
		assert.are.same({ 2, 4 }, cells.bounds(lines, 3))
	end)

	it("treats a marker as the start of its following cell", function()
		assert.are.same({ 7, 7 }, cells.bounds(lines, 6))
	end)

	it("uses the whole buffer when no markers exist", function()
		assert.are.same({ 1, 2 }, cells.bounds({ "x = 1", "x + 1" }, 2))
	end)

	it("moves to the first line of the next cell", function()
		assert.are.equal(7, cells.next_line(lines, 3))
	end)

	it("moves to the first line of the previous cell", function()
		assert.are.equal(2, cells.previous_line(lines, 7))
	end)
end)

describe("cell insertion", function()
	it("finds the minimal changed buffer region", function()
		local change = cells.changed_region({ "a", "d" }, { "a", "b", "c", "d" })

		assert.are.same({
			start_line = 1,
			end_line = 1,
			replacement = { "b", "c" },
		}, change)
	end)

	it("creates a percent cell below the current cell", function()
		local result = cells.insert({ "# %%", "x = 1", "# %%", "x + 1" }, 2, "below", "percent", "python")

		assert.are.same({ "# %%", "x = 1", "# %%", "", "# %%", "x + 1" }, result.lines)
		assert.are.equal(4, result.cursor_line)
	end)

	it("creates a percent cell above the current cell", function()
		local result = cells.insert({ "# %%", "x = 1", "# %%", "x + 1" }, 4, "above", "percent", "python")

		assert.are.same({ "# %%", "x = 1", "# %%", "", "# %%", "x + 1" }, result.lines)
		assert.are.equal(4, result.cursor_line)
	end)

	it("turns an unmarked Python buffer into percent cells", function()
		local result = cells.insert({ "x = 1" }, 1, "below", "percent", "python")

		assert.are.same({ "# %%", "x = 1", "# %%", "" }, result.lines)
		assert.are.equal(4, result.cursor_line)
	end)

	it("creates the first percent cell in an empty buffer", function()
		local result = cells.insert({ "" }, 1, "below", "percent", "python")

		assert.are.same({ "# %%", "" }, result.lines)
		assert.are.equal(2, result.cursor_line)
	end)

	it("creates a fenced cell below the enclosing code block", function()
		local result =
			cells.insert({ "notes", "```python", "x = 1", "```", "more notes" }, 3, "below", "fenced", "python")

		assert.are.same({
			"notes",
			"```python",
			"x = 1",
			"```",
			"",
			"```python",
			"",
			"```",
			"",
			"more notes",
		}, result.lines)
		assert.are.equal(7, result.cursor_line)
	end)

	it("creates a Quarto cell above the enclosing code block", function()
		local result = cells.insert({ "notes", "```{python}", "x = 1", "```" }, 3, "above", "fenced", "{python}")

		assert.are.same({
			"notes",
			"",
			"```{python}",
			"",
			"```",
			"",
			"```{python}",
			"x = 1",
			"```",
		}, result.lines)
		assert.are.equal(4, result.cursor_line)
	end)
end)
