local M = {}

function M.is_vault_file(file, vault)
  return file == vault or vim.startswith(file, vault .. "/")
end

function M.conceal(_, image_type)
  return image_type == "image"
end

function M.attach(buf, attach)
  if vim.b[buf].snacks_image_attached then
    return
  end
  vim.b[buf].snacks_image_attached = true
  attach(buf)
end

function M.setup()
  local vault = vim.fs.normalize(vim.fn.expand("~/Documents/Obsidian-Notes"))
  local group = vim.api.nvim_create_augroup("obsidian_inline_images", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "markdown",
    callback = function(event)
      local file = vim.fs.normalize(vim.api.nvim_buf_get_name(event.buf))
      if M.is_vault_file(file, vault) then
        M.attach(event.buf, require("snacks.image.inline").new)
      end
    end,
  })
end

return M
