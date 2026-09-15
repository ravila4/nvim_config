local M = {}
local sources = {}

function M.open(path)
	path = vim.fn.fnamemodify(path, ":p")
	if not sources[path] then
		local alias = vim.fn.tempname() .. "." .. vim.fn.fnamemodify(path, ":e")
		assert(vim.uv.fs_symlink(path, alias))
		sources[path] = alias
	end
	local stat = vim.uv.fs_stat(path)
	local title = vim.fs.basename(path)
	if stat then
		title = title .. (" · %.1f KiB"):format(stat.size / 1024)
	end
	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].bufhidden = "wipe"
	vim.api.nvim_create_autocmd("BufWipeout", {
		buffer = buf,
		once = true,
		callback = function()
			Snacks.image.placement.clean(buf)
		end,
	})
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = 1,
		height = 1,
		row = 1,
		col = 1,
		style = "minimal",
		border = "rounded",
		title = " " .. title .. " ",
		title_pos = "center",
	})
	local width, height, original_state, previous_geometry
	Snacks.image.buf.attach(buf, {
		-- A separate image ID avoids relying on underline color for placement IDs.
		src = sources[path],
		on_update_pre = function(placement)
			if not vim.api.nvim_win_is_valid(win) then
				return
			end
			local term = Snacks.image.terminal.size()
			local pixels = placement.img.info.size
			local aspect = (pixels.width / pixels.height) * term.cell_height / term.cell_width
			local max_width = math.max(1, math.floor((vim.o.columns - 2) * 0.95))
			local max_height = math.max(1, math.floor((vim.o.lines - vim.o.cmdheight - 2) * 0.95))
			width = math.max(1, math.min(max_width, math.floor(max_height * aspect)))
			height = math.max(1, math.min(max_height, math.floor(width / aspect + 0.5)))

			-- Override only this placement's DPI-limited size, not the shared image.
			if not original_state then
				original_state = placement.state
				placement.state = function(self)
					local state = original_state(self)
					state.loc.width, state.loc.height = width, height
					return state
				end
			end
			local geometry = {
				relative = "editor",
				width = width,
				height = height,
				row = math.floor((vim.o.lines - vim.o.cmdheight - height - 2) / 2),
				col = math.floor((vim.o.columns - width - 2) / 2),
			}
			if not vim.deep_equal(geometry, previous_geometry) then
				vim.api.nvim_win_set_config(win, geometry)
				previous_geometry = geometry
			end
		end,
	})
	local function close()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end
	vim.keymap.set("n", "q", close, { buffer = buf, nowait = true })
	vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true })
	local function copy()
		require("config.notebook_copy").copy_file(path)
	end
	vim.keymap.set("n", "<leader>my", copy, { buffer = buf, desc = "Copy image to clipboard" })
	vim.keymap.set("n", "<RightMouse>", function()
		require("menu").open({
			{ name = "Copy Image", cmd = copy, rtxt = "my" },
			{ name = "Close Image", cmd = close, rtxt = "q" },
		}, { mouse = true, border = "rounded", winblend = 0 })
	end, { buffer = buf, desc = "Image menu" })
end

return M
