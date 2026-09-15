-- Init for each spec process. Mirrors CI: no user config, and no swap or
-- shada files, which parallel unnamed buffers would otherwise race for.
vim.o.swapfile = false
vim.o.shadafile = "NONE"
