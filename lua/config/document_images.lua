local M = {}

local states = {}
-- Marks the image links while inline rendering is off, so the text can move.
local ns = vim.api.nvim_create_namespace("document_inline_images_links")

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

-- Rows an image link spans now, tracking edits made since rendering stopped.
local function link_rows(buf, link)
	local mark = vim.api.nvim_buf_get_extmark_by_id(buf, ns, link.mark, { details = true })
	if not mark[1] then
		return nil
	end
	return mark[1] + 1, (mark[3] and mark[3].end_row or mark[1]) + 1
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
	if state.enabled then
		for _, placement in pairs(state.renderer.imgs) do
			local range = placement.opts and (placement.opts.range or placement.opts.pos)
			if range and line >= range[1] and line <= (range[3] or range[1]) then
				paths[#paths + 1] = placement.img and placement.img.src
			end
		end
	else
		for _, link in ipairs(state.links or {}) do
			local first, last = link_rows(buf, link)
			if first and line >= first and line <= last then
				paths[#paths + 1] = link.src
			end
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
		state.links = {}
		for _, placement in pairs(state.renderer.imgs) do
			local range = placement.opts and (placement.opts.range or placement.opts.pos)
			local src = placement.img and placement.img.src
			if range and src then
				local first = math.max(range[1] - 1, 0)
				state.links[#state.links + 1] = {
					src = src,
					mark = vim.api.nvim_buf_set_extmark(buf, ns, first, 0, {
						end_row = math.max((range[3] or range[1]) - 1, first),
						end_col = 0,
					}),
				}
			end
			placement:close()
		end
		state.renderer.imgs = {}
		state.renderer.idx = {}
	else
		state.enabled = true
		state.links = nil
		vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
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
