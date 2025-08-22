-- Keymaps
-- ========

local map = vim.keymap.set

-- Insert date string in format YYYY-MM-DD
map("n", "<F3>", ":r!date '+%F'<CR>", { desc = "Insert current date" })

-- WSL clipboard paste
if vim.fn.system("uname -r"):match("Microsoft") then
  map("n", "=", ":r !powershell.exe -Command \"& {Get-Clipboard}\"<CR>", { desc = "Paste from Windows clipboard" })
end

-- File explorer toggles (updated for Neo-tree)
map("n", "<C-n>", ":Neotree toggle<CR>", { desc = "Toggle file explorer" })
map("n", "<leader>e", ":Neotree toggle<CR>", { desc = "Toggle file explorer" })
map("n", "<leader>E", ":Neotree focus<CR>", { desc = "Focus file explorer" })

-- Buffer navigation (safe keymaps that don't override system shortcuts)
map("n", "<leader>bn", ":bnext<CR>", { desc = "Next buffer" })
map("n", "<leader>bp", ":bprev<CR>", { desc = "Previous buffer" })
map("n", "<leader>bd", ":bdelete<CR>", { desc = "Delete buffer" })
map("n", "<leader>bb", ":buffers<CR>", { desc = "List buffers" })

-- Alternative: Use ] and [ for buffer navigation (common Vim convention)
map("n", "]b", ":bnext<CR>", { desc = "Next buffer" })
map("n", "[b", ":bprev<CR>", { desc = "Previous buffer" })

-- Enhanced search with beautiful UI
map("n", "<leader>ff", ":Telescope find_files<CR>", { desc = "Find files" })
map("n", "<leader>fg", ":Telescope live_grep<CR>", { desc = "Live grep" })
map("n", "<leader>fw", ":Telescope grep_string<CR>", { desc = "Find word under cursor" })
map("n", "<leader>fb", ":Telescope buffers<CR>", { desc = "Find buffers" })
map("n", "<leader>fh", ":Telescope help_tags<CR>", { desc = "Help tags" })
map("n", "<leader>fc", ":Telescope commands<CR>", { desc = "Commands" })
map("n", "<leader>fr", ":Telescope oldfiles<CR>", { desc = "Recent files" })
map("n", "<leader>fs", ":Telescope lsp_document_symbols<CR>", { desc = "Document symbols" })
map("n", "<leader>fS", ":Telescope lsp_workspace_symbols<CR>", { desc = "Workspace symbols" })

-- Global search - nice alternative keybind
map("n", "<C-p>", ":Telescope find_files<CR>", { desc = "Find files (Ctrl-P style)" })
map("n", "<C-f>", ":Telescope live_grep<CR>", { desc = "Global search" })

-- Split navigation with Ctrl-hjkl (works in normal mode)
map("n", "<C-h>", ":wincmd h<CR>", { desc = "Move to left split", silent = true })
map("n", "<C-j>", ":wincmd j<CR>", { desc = "Move to bottom split", silent = true })
map("n", "<C-k>", ":wincmd k<CR>", { desc = "Move to top split", silent = true })
map("n", "<C-l>", ":wincmd l<CR>", { desc = "Move to right split", silent = true })

-- Split navigation in terminal mode (Ctrl-\ Ctrl-N enters normal mode first)
map("t", "<C-h>", "<C-\\><C-N>:wincmd h<CR>", { desc = "Move to left split from terminal", silent = true })
map("t", "<C-j>", "<C-\\><C-N>:wincmd j<CR>", { desc = "Move to bottom split from terminal", silent = true })
map("t", "<C-k>", "<C-\\><C-N>:wincmd k<CR>", { desc = "Move to top split from terminal", silent = true })
map("t", "<C-l>", "<C-\\><C-N>:wincmd l<CR>", { desc = "Move to right split from terminal", silent = true })

-- Easy terminal mode escape
map("t", "<Esc><Esc>", "<C-\\><C-N>", { desc = "Exit terminal mode", silent = true })

-- ClaudeCode keymaps
map("n", "<leader>cc", "<cmd>ClaudeCode<cr>", { desc = "Toggle Claude Code" })
map("n", "<leader>cf", "<cmd>ClaudeCodeFocus<cr>", { desc = "Focus Claude Code" })
map("v", "<leader>cs", "<cmd>ClaudeCodeSend<cr>", { desc = "Send selection to Claude" })
map("n", "<leader>ca", "<cmd>ClaudeCodeDiffAccept<cr>", { desc = "Accept diff" })
map("n", "<leader>cd", "<cmd>ClaudeCodeDiffDeny<cr>", { desc = "Deny diff" })

-- Layout management keymaps
map("n", "<leader>ll", function()
  require("edgy").toggle("left")
end, { desc = "Toggle left panel" })
map("n", "<leader>lr", function()
  require("edgy").toggle("right")
end, { desc = "Toggle right panel" })
map("n", "<leader>lb", function()
  require("edgy").toggle("bottom")
end, { desc = "Toggle bottom panel" })
map("n", "<leader>lL", function()
  require("edgy").open("left")
  require("edgy").open("right")
  require("edgy").open("bottom")
end, { desc = "Open full IDE layout" })
map("n", "<leader>lc", function()
  require("edgy").close()
end, { desc = "Close all panels" })

-- Session management keymaps
map("n", "<leader>qc", function()
  -- Close all buffers except current one
  local current = vim.api.nvim_get_current_buf()
  local buffers = vim.api.nvim_list_bufs()
  for _, buf in ipairs(buffers) do
    if buf ~= current and vim.api.nvim_buf_is_loaded(buf) then
      vim.api.nvim_buf_delete(buf, { force = false })
    end
  end
  vim.notify("Session closed - all buffers except current closed")
end, { desc = "Close session (close all buffers)" })

map("n", "<leader>qC", function()
  -- Close all buffers
  vim.cmd("bufdo bdelete")
  vim.notify("All buffers closed")
end, { desc = "Close all buffers" })
