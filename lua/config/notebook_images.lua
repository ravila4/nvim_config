-- Copy an inline image to the system clipboard. Molten writes every image
-- output to a PNG file and image.nvim places it on virtual lines below the
-- cell's anchor line, so the image is addressed through the cursor and copied
-- from that file.
local M = {}

-- Anchor row (0-indexed) of the image under the cursor line (1-indexed), or nil.
-- The output block hangs below its anchor line, and a mouse click on the block
-- lands the cursor on the line after the anchor. So an image counts as under the
-- cursor when its anchor is at most one line above it, nearest anchor first.
function M.anchor_at(anchors, line)
	local best
	for _, y in ipairs(anchors) do
		if y >= line - 2 and (best == nil or y < best) then
			best = y
		end
	end
	return best
end

-- Anchor row of the image whose output block, or anchor line, holds the cursor.
-- Unlike anchor_at this does not reach down to an image further below.
function M.anchor_clicked(anchors, line)
	local anchor = M.anchor_at(anchors, line)
	if anchor ~= nil and anchor <= line - 1 then
		return anchor
	end
	return nil
end

function M.clipboard_command(path)
	return {
		"osascript",
		"-e",
		('set the clipboard to (read (POSIX file "%s") as «class PNGf»)'):format(path),
	}
end

local function copy_file(image)
	if not vim.uv.fs_stat(image.original_path) then
		vim.notify("Image file is gone, re-run the cell", vim.log.levels.WARN)
		return
	end
	vim.system(M.clipboard_command(image.original_path), {}, function(result)
		vim.schedule(function()
			if result.code == 0 then
				vim.notify(("Copied image to clipboard (%dx%d)"):format(image.image_width, image.image_height))
			else
				vim.notify("Copying the image failed: " .. (result.stderr or ""), vim.log.levels.ERROR)
			end
		end)
	end)
end

local function images_by(pick)
	local images = require("image").get_images({ buffer = vim.api.nvim_get_current_buf() })
	local anchors = vim.tbl_map(function(image)
		return image.geometry.y
	end, images)
	local anchor = pick(anchors, vim.api.nvim_win_get_cursor(0)[1])
	local candidates = vim.tbl_filter(function(image)
		return image.geometry.y == anchor
	end, images)
	table.sort(candidates, function(a, b)
		return (a.render_offset_top or 0) < (b.render_offset_top or 0)
	end)
	return candidates
end

-- The images under the cursor, in output order. Empty when there is none.
function M.at_cursor()
	return images_by(M.anchor_at)
end

-- The images whose output block, or anchor line, the cursor is on.
function M.clicked()
	return images_by(M.anchor_clicked)
end

-- Copy the image under the cursor. A cell with several images asks which one.
function M.copy_at_cursor()
	local candidates = M.at_cursor()
	if #candidates == 0 then
		vim.notify("No image at or below the cursor", vim.log.levels.WARN)
		return
	end
	if #candidates == 1 then
		copy_file(candidates[1])
		return
	end
	vim.ui.select(candidates, {
		prompt = "Copy which image?",
		format_item = function(image)
			return ("%dx%d %s"):format(image.image_width, image.image_height, vim.fs.basename(image.original_path))
		end,
	}, function(choice)
		if choice then
			copy_file(choice)
		end
	end)
end

return M
