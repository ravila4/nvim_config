describe("Obsidian inline images", function()
  local images

  before_each(function()
    package.loaded["config.obsidian_images"] = nil
    images = require("config.obsidian_images")
  end)

  it("recognizes files inside the vault", function()
    assert.is_true(images.is_vault_file(
      "/Users/ricardo/Documents/Obsidian-Notes/folder/note.md",
      "/Users/ricardo/Documents/Obsidian-Notes"
    ))
  end)

  it("rejects files that merely share the vault prefix", function()
    assert.is_false(images.is_vault_file(
      "/Users/ricardo/Documents/Obsidian-Notes-old/note.md",
      "/Users/ricardo/Documents/Obsidian-Notes"
    ))
  end)

  it("conceals image sources while leaving other rendered content visible", function()
    assert.is_true(images.conceal("markdown", "image"))
    assert.is_false(images.conceal("markdown", "math"))
  end)

  it("attaches the inline renderer only once per buffer", function()
    local buf = vim.api.nvim_create_buf(false, true)
    local calls = 0
    local attach = function()
      calls = calls + 1
    end

    images.attach(buf, attach)
    images.attach(buf, attach)

    assert.are.equal(1, calls)
    vim.api.nvim_buf_delete(buf, { force = true })
  end)
end)
