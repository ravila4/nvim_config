describe("Prose line wrapping", function()
  local prose_wrap

  before_each(function()
    prose_wrap = require("config.prose_wrap")
    vim.wo.wrap = false
    vim.wo.showbreak = "↳ "
  end)

  it("removes the generic continuation marker when enabling wrapping", function()
    prose_wrap.toggle()

    assert.is_true(vim.wo.wrap)
    assert.are.equal("NONE", vim.wo.showbreak)
  end)

  it("disables wrapping when it is already enabled", function()
    vim.wo.wrap = true

    prose_wrap.toggle()

    assert.is_false(vim.wo.wrap)
  end)
end)
