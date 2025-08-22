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

-- Buffer navigation (safe keymaps that don't override system shortcuts)
map("n", "<leader>bn", ":bnext<CR>", { desc = "Next buffer" })
map("n", "<leader>bp", ":bprev<CR>", { desc = "Previous buffer" })
map("n", "<leader>bd", ":bdelete<CR>", { desc = "Delete buffer" })
map("n", "<leader>bb", ":buffers<CR>", { desc = "List buffers" })

-- Alternative: Use ] and [ for buffer navigation (common Vim convention)
map("n", "]b", ":bnext<CR>", { desc = "Next buffer" })
map("n", "[b", ":bprev<CR>", { desc = "Previous buffer" })

-- Telescope buffer picker
map("n", "<leader>fb", ":Telescope buffers<CR>", { desc = "Find buffers" })

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
