-- Basic Neovim Settings
-- =====================

-- Set leader key to space (more comfortable than backslash)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Stable Python provider for molten-nvim remote plugins
vim.g.python3_host_prog = vim.fn.expand("~/.local/share/nvim/python-host/bin/python")

local opt = vim.opt

-- Line Numbers
opt.number = true
-- opt.relativenumber = true

-- Highlight current line
opt.cursorline = false

-- Tabbing
opt.tabstop = 8
opt.softtabstop = 0
opt.expandtab = true
opt.shiftwidth = 4
opt.smarttab = true

-- Search
opt.incsearch = true
opt.hlsearch = true
opt.ignorecase = true
opt.smartcase = true

-- Text wrapping
opt.wrap = false -- Disable line wrapping by default (enabled for prose via autocmd)
opt.linebreak = true -- When wrapping is enabled, break at word boundaries
opt.showbreak = "↳ " -- Visual indicator for wrapped lines

-- Enable line wrapping for prose filetypes
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "quarto", "rmd" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
  end,
})

-- Misc
opt.encoding = "utf8"
opt.scrolloff = 4
opt.wildmenu = true
opt.wildmode = "list"
opt.mouse = "a"

-- Leader key timeout (default is 1000ms)
opt.timeoutlen = 800 -- Slightly shorter than default for better responsiveness

-- GUI settings
opt.mousehide = false
opt.mousemodel = "popup"
opt.guioptions:remove("T") -- Remove toolbar
opt.guioptions:remove("r") -- Remove right scrollbar
opt.guioptions:remove("L") -- Remove left scrollbar

-- Code Folding
opt.foldmethod = "indent"
opt.foldlevel = 99

-- Conceal level for markdown
opt.conceallevel = 2

-- Clipboard (unnamedplus works on both macOS and Linux)
opt.clipboard = "unnamedplus"

-- Completion
opt.completeopt = { "menuone", "noinsert", "noselect" }
opt.shortmess:append("c")

-- Enable 24-bit colors
opt.termguicolors = true

-- Filetypes to skip for trailing space highlighting/deletion
local trailing_skip_filetypes = {
  "lazy",
  "mason",
  "neo-tree",
  "telescope",
  "dashboard",
  "snacks_dashboard",
  "help",
  "terminal",
  "qf",
  "trouble",
  "fugitive",
  "defx",
  "",
}

-- Highlight trailing spaces (theme-aware and startup-safe)
vim.api.nvim_create_augroup("TrailingSpace", { clear = true })

-- Define a custom highlight group that works in both light and dark modes
vim.api.nvim_create_autocmd("ColorScheme", {
  group = "TrailingSpace",
  callback = function()
    -- Use a subtle red that works in both light and dark modes
    vim.api.nvim_set_hl(0, "TrailingSpaces", {
      bg = vim.o.background == "dark" and "#3c1e1e" or "#ffe6e6",
      fg = vim.o.background == "dark" and "#ff6b6b" or "#cc0000",
    })
  end,
})

local function update_trailing_spaces(win)
  if not vim.api.nvim_win_is_valid(win) then
    return
  end
  local match_id = vim.w[win].trailing_space_match
  if match_id then
    pcall(vim.fn.matchdelete, match_id, win)
    vim.w[win].trailing_space_match = nil
  end
  local buf = vim.api.nvim_win_get_buf(win)
  if vim.bo[buf].buftype == "" and not vim.tbl_contains(trailing_skip_filetypes, vim.bo[buf].filetype) then
    vim.w[win].trailing_space_match = vim.fn.matchadd("TrailingSpaces", "\\s\\+$", 10, -1, { window = win })
  end
end

-- Apply trailing space highlighting with delay to avoid startup artifacts
vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
  group = "TrailingSpace",
  callback = function()
    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_win_get_buf(win)
    vim.defer_fn(function()
      if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
        update_trailing_spaces(win)
      end
    end, 100)
  end,
})

-- Filetype detection can finish after a buffer is displayed.
vim.api.nvim_create_autocmd("FileType", {
  group = "TrailingSpace",
  callback = function(args)
    for _, win in ipairs(vim.fn.win_findbuf(args.buf)) do
      update_trailing_spaces(win)
    end
  end,
})

-- Ensure highlight is set on startup
vim.defer_fn(function()
  vim.api.nvim_set_hl(0, "TrailingSpaces", {
    bg = vim.o.background == "dark" and "#3c1e1e" or "#ffe6e6",
    fg = vim.o.background == "dark" and "#ff6b6b" or "#cc0000",
  })
end, 200)

-- Command to delete trailing spaces (reuses same buffer filtering logic)
vim.api.nvim_create_user_command("DeleteTrailingSpaces", function()
  local win = vim.api.nvim_get_current_win()
  local buftype = vim.bo.buftype
  local filetype = vim.bo.filetype

  if buftype ~= "" or vim.tbl_contains(trailing_skip_filetypes, filetype) or filetype == "" then
    print("DeleteTrailingSpaces: Skipping special buffer")
    return
  end

  -- Save cursor position
  local cursor_pos = vim.api.nvim_win_get_cursor(0)

  -- Count trailing spaces before deletion
  local lines_with_trailing = 0
  local total_trailing_chars = 0

  for line_num = 1, vim.fn.line("$") do
    local line = vim.fn.getline(line_num)
    local trailing = line:match("%s+$")
    if trailing then
      lines_with_trailing = lines_with_trailing + 1
      total_trailing_chars = total_trailing_chars + #trailing
    end
  end

  if total_trailing_chars == 0 then
    print("No trailing spaces found")
    return
  end

  -- Delete trailing spaces
  vim.cmd([[silent! %s/\s\+$//e]])

  -- Restore cursor position
  pcall(vim.api.nvim_win_set_cursor, 0, cursor_pos)

  -- Update trailing space highlighting after deletion
  vim.defer_fn(function()
    update_trailing_spaces(win)
  end, 50)

  print(string.format("Removed %d trailing characters from %d lines", total_trailing_chars, lines_with_trailing))
end, {
  desc = "Delete all trailing spaces in current buffer",
})

-- Add a mapping for convenience
vim.keymap.set("n", "<leader>dw", "<cmd>DeleteTrailingSpaces<cr>", { desc = "Delete trailing spaces" })

-- [No Name] and directory buffers are hidden from bufferline via custom_filter in plugins/ui.lua
