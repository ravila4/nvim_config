local M = {}

-- Zen displays the same buffer in a new window; image placements are window-local.
function M.refresh()
	local image = package.loaded.image
	if not image then
		return
	end
	local win = vim.api.nvim_get_current_win()
	local buf = vim.api.nvim_get_current_buf()
	for _, img in ipairs(image.get_images()) do
		if img.buffer == buf then
			img:clear()
			img.window = win
			img:render()
		end
	end
end

return M
