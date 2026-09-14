local images = require("config.notebook_copy")

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
