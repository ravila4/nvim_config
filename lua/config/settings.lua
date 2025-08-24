-- Basic Neovim Settings
-- =====================

-- Set leader key to space (more comfortable than backslash)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt

-- Line Numbers
opt.number = true
-- opt.relativenumber = true

-- Highlight current line
opt.cursorline = true

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

-- Misc
opt.encoding = "utf8"
opt.scrolloff = 4
opt.wildmenu = true
opt.wildmode = "list"
opt.mouse = "a"

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

-- Clipboard
opt.clipboard = "unnamed"

-- Completion
opt.completeopt = { "menuone", "noinsert", "noselect" }
opt.shortmess:append("c")

-- Enable 24-bit colors
opt.termguicolors = true

-- WSL clipboard support
if vim.fn.system("uname -r"):match("Microsoft") then
  vim.api.nvim_create_autocmd("TextYankPost", {
    group = vim.api.nvim_create_augroup("Yank", { clear = true }),
    callback = function()
      vim.fn.system("clip.exe", vim.fn.getreg('"'))
    end,
  })
end

-- Highlight trailing spaces (theme-aware and startup-safe)
vim.api.nvim_create_augroup("TrailingSpace", { clear = true })

-- Define a custom highlight group that works in both light and dark modes
vim.api.nvim_create_autocmd("ColorScheme", {
  group = "TrailingSpace",
  callback = function()
    -- Use a subtle red that works in both light and dark modes
    vim.api.nvim_set_hl(0, "TrailingSpaces", {
      bg = vim.o.background == "dark" and "#3c1e1e" or "#ffe6e6",
      fg = vim.o.background == "dark" and "#ff6b6b" or "#cc0000"
    })
  end,
})

-- Apply trailing space highlighting with delay to avoid startup artifacts
vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
  group = "TrailingSpace",
  callback = function()
    -- Small delay to ensure UI is fully loaded
    vim.defer_fn(function()
      local buftype = vim.bo.buftype
      local filetype = vim.bo.filetype

      -- Skip special buffers and floating windows
      local skip_filetypes = {
        "lazy", "mason", "neo-tree", "telescope", "dashboard", "snacks_dashboard",
        "help", "terminal", "qf", "trouble", "fugitive", "defx", ""
      }

      if buftype == "" and not vim.tbl_contains(skip_filetypes, filetype) and filetype ~= "" then
        -- Clear any existing matches first
        vim.fn.clearmatches()
        -- Add the trailing space match
        vim.fn.matchadd("TrailingSpaces", "\\s\\+$")
      end
    end, 100) -- 100ms delay
  end,
})

-- Clear trailing space highlighting for special filetypes
vim.api.nvim_create_autocmd("FileType", {
  group = "TrailingSpace",
  pattern = { "lazy", "mason", "neo-tree", "telescope", "dashboard", "snacks_dashboard", "help", "terminal", "qf", "trouble", "fugitive", "defx" },
  callback = function()
    vim.fn.clearmatches()
  end,
})

-- Ensure highlight is set on startup
vim.defer_fn(function()
  vim.api.nvim_set_hl(0, "TrailingSpaces", {
    bg = vim.o.background == "dark" and "#3c1e1e" or "#ffe6e6",
    fg = vim.o.background == "dark" and "#ff6b6b" or "#cc0000"
  })
end, 200)

-- Session persistence and layout management
vim.api.nvim_create_augroup("SessionLayout", { clear = true })

-- Auto-save session before exit
vim.api.nvim_create_autocmd("VimLeavePre", {
  group = "SessionLayout",
  callback = function()
    if vim.fn.argc() == 0 and not vim.bo.readonly then
      -- Close special buffers before saving
      local bufs = vim.api.nvim_list_bufs()
      for _, buf in ipairs(bufs) do
        local bufname = vim.api.nvim_buf_get_name(buf)
        local buftype = vim.bo[buf].buftype
        if buftype ~= "" or
           bufname:match("OUTLINE") or
           bufname:match("neo%-tree") or
           bufname:match("snacks_explorer") or
           bufname:match("Outline") then
          pcall(vim.api.nvim_buf_delete, buf, {force = true})
        end
      end
      require("persistence").save()
    end
  end,
})

-- Clean up outline buffers after session restore
vim.api.nvim_create_autocmd("User", {
  pattern = "PersistenceLoadPost",
  group = "SessionLayout",
  callback = function()
    -- Clean up any outline buffers that might have been restored
    vim.defer_fn(function()
      local bufs = vim.api.nvim_list_bufs()
      for _, buf in ipairs(bufs) do
        local bufname = vim.api.nvim_buf_get_name(buf)
        if bufname:match("OUTLINE") or bufname:match("Outline") then
          pcall(vim.api.nvim_buf_delete, buf, {force = true})
        end
      end
    end, 100)
  end,
})

