-- Copy cell output to the system clipboard. Molten shows output on virtual
-- lines below the cell's anchor line, which cannot be selected: images are
-- placed there by image.nvim from the PNG files Molten writes, and text is
-- kept by Molten itself. Both are addressed through the cursor.
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

-- Molten's output extmark under the cursor as { row, id }, or nil.
local function output_by(pick)
	local buf = vim.api.nvim_get_current_buf()
	local ns = vim.api.nvim_get_namespaces()["molten-extmarks"]
	if not ns then
		return nil
	end
	local marks = {}
	for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })) do
		if mark[4].virt_lines then
			marks[#marks + 1] = { row = mark[2], id = mark[1] }
		end
	end
	local anchor = pick(
		vim.tbl_map(function(mark)
			return mark.row
		end, marks),
		vim.api.nvim_win_get_cursor(0)[1]
	)
	for _, mark in ipairs(marks) do
		if mark.row == anchor then
			return mark
		end
	end
	return nil
end

-- Output text as it goes on the clipboard, and its line count. Trailing
-- newlines are dropped so pasting does not add blank lines.
function M.clip_text(text)
	text = text:gsub("\n+$", "")
	if text == "" then
		return "", 0
	end
	return text, select(2, text:gsub("\n", "")) + 1
end

local function output_text(mark)
	local ok, text = pcall(vim.fn.MoltenOutputText, vim.api.nvim_get_current_buf(), mark.id)
	if ok and type(text) == "string" then
		return text
	end
	return ""
end

-- The text of the output whose block, or anchor line, the cursor is on.
function M.output_text_clicked()
	local mark = output_by(M.anchor_clicked)
	return mark and output_text(mark) or ""
end

-- Copy the text of the output under the cursor.
function M.copy_output_at_cursor()
	local mark = output_by(M.anchor_at)
	if not mark then
		vim.notify("No output at or below the cursor", vim.log.levels.WARN)
		return
	end
	local text, lines = M.clip_text(output_text(mark))
	if text == "" then
		vim.notify("This output has no text", vim.log.levels.WARN)
		return
	end
	vim.fn.setreg("+", text)
	vim.notify(("Copied %d line%s of output"):format(lines, lines == 1 and "" or "s"))
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
