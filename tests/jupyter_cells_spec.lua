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
