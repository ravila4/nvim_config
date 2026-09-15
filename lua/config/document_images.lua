local M = {}

local states = {}

function M.conceal(_, image_type)
	return image_type == "image"
end

function M.attach(buf, factory)
	if states[buf] then
		return
	end

	local renderer = factory(buf)
	states[buf] = {
		enabled = true,
		renderer = renderer,
		update = renderer.update,
	}
	vim.b[buf].snacks_image_attached = true
end

function M.is_enabled(buf)
	buf = buf == 0 and vim.api.nvim_get_current_buf() or buf
	return states[buf] ~= nil and states[buf].enabled
end

function M.at_cursor(buf)
	if buf == nil or buf == 0 then
		buf = vim.api.nvim_get_current_buf()
	end
	local state = states[buf]
	if not state then
		return {}
	end
	local line = vim.api.nvim_win_get_cursor(0)[1]
	local paths = {}
	local placements = state.enabled and state.renderer.imgs or state.links or {}
	for _, placement in pairs(placements) do
		local range = placement.opts and (placement.opts.range or placement.opts.pos)
		if range and line >= range[1] and line <= (range[3] or range[1]) and placement.img and placement.img.file then
			paths[#paths + 1] = placement.img.file
		end
	end
	table.sort(paths)
	return paths
end

local function with_image(action, prompt)
	local paths = M.at_cursor()
	if #paths == 0 then
		return false
	end
	if #paths == 1 then
		action(paths[1])
		return true
	end
	vim.ui.select(paths, { prompt = prompt, format_item = vim.fs.basename }, function(path)
		if path then
			action(path)
		end
	end)
	return true
end

function M.copy_at_cursor()
	return with_image(require("config.notebook_copy").copy_file, "Copy which image?")
end

function M.open_at_cursor()
	return with_image(require("config.image_viewer").open, "Open which image?")
end

function M.toggle(buf)
	if buf == nil or buf == 0 then
		buf = vim.api.nvim_get_current_buf()
	end
	local state = states[buf]
	if not state then
		return
	end

	if state.enabled then
		state.enabled = false
		state.renderer.update = function() end
		state.links = vim.tbl_values(state.renderer.imgs)
		for _, image in pairs(state.renderer.imgs) do
			image:close()
		end
		state.renderer.imgs = {}
		state.renderer.idx = {}
	else
		state.enabled = true
		state.links = nil
		state.renderer.update = state.update
		state.renderer:update()
	end
end

function M.setup()
	local group = vim.api.nvim_create_augroup("document_inline_images", { clear = true })

	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		pattern = { "markdown", "quarto" },
		callback = function(event)
			M.attach(event.buf, require("snacks.image.inline").new)
		end,
	})

	vim.api.nvim_create_autocmd("BufDelete", {
		group = group,
		callback = function(event)
			states[event.buf] = nil
		end,
	})
end

return M
