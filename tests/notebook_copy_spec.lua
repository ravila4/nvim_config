local images = require("config.notebook_copy")

describe("Molten image sources", function()
	local buf, old_select, old_viewer
	before_each(function()
		buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_set_current_buf(buf)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "cell", "end", "text", "plot", "end" })
		local ns = vim.api.nvim_create_namespace("molten-extmarks")
		for _, row in ipairs({ 1, 4 }) do
			vim.api.nvim_buf_set_extmark(buf, ns, row, 0, { id = row, virt_lines = { { { "output" } } } })
		end
		vim.cmd([[function! MoltenOutputImages(buf, id)
return a:id == 4 ? ['/tmp/first.png', '/tmp/second.png'] : []
endfunction]])
		old_select = vim.ui.select
		old_viewer = package.loaded["config.image_viewer"]
	end)
	after_each(function()
		vim.ui.select = old_select
		package.loaded["config.image_viewer"] = old_viewer
		vim.cmd("delfunction MoltenOutputImages")
		vim.api.nvim_buf_delete(buf, { force = true })
	end)
	it("finds the next image output, skipping text-only outputs", function()
		assert.same({ "/tmp/first.png", "/tmp/second.png" }, images.at_cursor())
	end)
	it("does not offer a following image when text output is clicked", function()
		vim.api.nvim_win_set_cursor(0, { 2, 0 })
		assert.same({}, images.clicked())
	end)
	it("offers images in output order when their anchor is clicked", function()
		vim.api.nvim_win_set_cursor(0, { 5, 0 })
		assert.same({ "/tmp/first.png", "/tmp/second.png" }, images.clicked())
	end)
	it("opens the chosen source in the shared viewer", function()
		local opened
		package.loaded["config.image_viewer"] = {
			open = function(path)
				opened = path
			end,
		}
		vim.ui.select = function(items, _, callback)
			callback(items[2])
		end
		images.open_at_cursor()
		assert.equal("/tmp/second.png", opened)
	end)
end)

describe("Image under the cursor", function()
	-- anchors are 0-indexed buffer rows, the cursor line is 1-indexed
	it("is the one anchored on the cursor line", function()
		assert.are.equal(21, images.anchor_at({ 21, 40 }, 22))
	end)

	it("is the nearest one anchored below the cursor", function()
		assert.are.equal(21, images.anchor_at({ 40, 21 }, 10))
	end)

	it("is the one whose output block was clicked, which lands the cursor one line past the anchor", function()
		assert.are.equal(21, images.anchor_at({ 21, 40 }, 23))
	end)

	it("is not one more than a line above the cursor", function()
		assert.are.equal(40, images.anchor_at({ 21, 40 }, 24))
	end)

	it("is nil when every image is above the cursor", function()
		assert.is_nil(images.anchor_at({ 21 }, 30))
	end)

	it("is nil without images", function()
		assert.is_nil(images.anchor_at({}, 1))
	end)
end)

describe("Image clicked with the mouse", function()
	it("is the one whose anchor line was clicked", function()
		assert.are.equal(21, images.anchor_clicked({ 21, 40 }, 22))
	end)

	it("is the one whose output block was clicked", function()
		assert.are.equal(21, images.anchor_clicked({ 21, 40 }, 23))
	end)

	it("is nil when the click is on text above the image", function()
		assert.is_nil(images.anchor_clicked({ 21, 40 }, 10))
	end)

	it("is nil when the click is below every image", function()
		assert.is_nil(images.anchor_clicked({ 21 }, 30))
	end)
end)

describe("Output text for the clipboard", function()
	it("drops trailing newlines and counts the lines", function()
		local text, lines = images.clip_text("a\nb\n\n")
		assert.are.equal("a\nb", text)
		assert.are.equal(2, lines)
	end)

	it("counts a single line without a newline", function()
		local text, lines = images.clip_text("only")
		assert.are.equal("only", text)
		assert.are.equal(1, lines)
	end)

	it("is empty for whitespace-only newlines", function()
		local text, lines = images.clip_text("\n\n")
		assert.are.equal("", text)
		assert.are.equal(0, lines)
	end)
end)

describe("Clipboard command for an image file", function()
	it("reads the file onto the clipboard as PNG", function()
		local cmd = images.clipboard_command("/tmp/figure 1.png")
		assert.are.equal("osascript", cmd[1])
		assert.are.equal("-e", cmd[2])
		assert.are.equal('set the clipboard to (read (POSIX file "/tmp/figure 1.png") as «class PNGf»)', cmd[3])
	end)
end)
