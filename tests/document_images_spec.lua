describe("Document inline images", function()
	local images

	before_each(function()
		package.loaded["config.document_images"] = nil
		images = require("config.document_images")
	end)

	it("conceals image sources while leaving other rendered content visible", function()
		assert.is_true(images.conceal("markdown", "image"))
		assert.is_false(images.conceal("markdown", "math"))
	end)

	it("attaches the inline renderer only once per buffer", function()
		local buf = vim.api.nvim_create_buf(false, true)
		local calls = 0
		local attach = function()
			calls = calls + 1
			return { imgs = {}, idx = {}, update = function() end }
		end

		images.attach(buf, attach)
		images.attach(buf, attach)

		assert.are.equal(1, calls)
		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("stops updates and closes placements when showing links", function()
		local buf = vim.api.nvim_create_buf(false, true)
		local closed = false
		local updates = 0
		local renderer = {
			imgs = { image = {
				close = function()
					closed = true
				end,
			} },
			idx = { image = true },
			update = function()
				updates = updates + 1
			end,
		}
		images.attach(buf, function()
			return renderer
		end)

		images.toggle(buf)
		renderer:update()

		assert.is_true(closed)
		assert.are.equal(0, updates)
		assert.is_false(images.is_enabled(buf))
		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("resumes updates when rendering images again", function()
		local buf = vim.api.nvim_create_buf(false, true)
		local updates = 0
		local renderer = {
			imgs = {},
			idx = {},
			update = function()
				updates = updates + 1
			end,
		}
		images.attach(buf, function()
			return renderer
		end)
		images.toggle(buf)

		images.toggle(buf)

		assert.are.equal(1, updates)
		assert.is_true(images.is_enabled(buf))
		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("toggles the current buffer when called from a menu", function()
		local buf = vim.api.nvim_get_current_buf()
		local renderer = {
			imgs = {},
			idx = {},
			update = function() end,
		}
		images.attach(buf, function()
			return renderer
		end)

		images.toggle()

		assert.is_false(images.is_enabled(buf))
	end)

	it("finds the rendered image on the cursor line", function()
		local buf = vim.api.nvim_get_current_buf()
		local line = vim.api.nvim_win_get_cursor(0)[1]
		local renderer = {
			imgs = {
				first = {
					img = { src = "/tmp/figure.png", file = "/tmp/cache/figure.conv.png" },
					opts = { range = { line, 0, line, 20 } },
				},
			},
			idx = {},
			update = function() end,
			get = function()
				return {}
			end,
		}
		images.attach(buf, function()
			return renderer
		end)

		assert.same({ { src = "/tmp/figure.png", file = "/tmp/cache/figure.conv.png" } }, images.at_cursor())
	end)

	it("keeps image actions available while showing links", function()
		local buf = vim.api.nvim_get_current_buf()
		local line = vim.api.nvim_win_get_cursor(0)[1]
		local renderer = {
			imgs = {
				first = {
					img = { src = "/tmp/figure.png", file = "/tmp/cache/figure.conv.png" },
					opts = { range = { line, 0, line, 20 } },
					close = function() end,
				},
			},
			idx = {},
			update = function() end,
		}
		images.attach(buf, function()
			return renderer
		end)

		images.toggle(buf)

		assert.same({ { src = "/tmp/figure.png", file = "/tmp/cache/figure.conv.png" } }, images.at_cursor(buf))
	end)

	it("copies and opens the rendered image through the shared helpers", function()
		local buf = vim.api.nvim_get_current_buf()
		local line = vim.api.nvim_win_get_cursor(0)[1]
		local renderer = {
			imgs = {
				first = {
					img = { src = "/tmp/figure.png", file = "/tmp/cache/figure.conv.png" },
					opts = { range = { line, 0, line, 20 } },
				},
			},
			idx = {},
			update = function() end,
			get = function()
				return {}
			end,
		}
		local copied, opened
		local notebook_copy = require("config.notebook_copy")
		local image_viewer = require("config.image_viewer")
		local old_copy, old_open = notebook_copy.copy_file, image_viewer.open
		notebook_copy.copy_file = function(path)
			copied = path
		end
		image_viewer.open = function(path)
			opened = path
		end
		images.attach(buf, function()
			return renderer
		end)

		images.copy_at_cursor()
		images.open_at_cursor()

		notebook_copy.copy_file, image_viewer.open = old_copy, old_open
		assert.are.equal("/tmp/figure.png", copied)
		assert.are.equal("/tmp/figure.png", opened)
	end)

	it("acts on the original image, not the downscaled cache copy", function()
		local buf = vim.api.nvim_get_current_buf()
		local line = vim.api.nvim_win_get_cursor(0)[1]
		local renderer = {
			imgs = {
				first = {
					img = { src = "/tmp/photo.jpg", file = "/tmp/cache/photo.conv.png" },
					opts = { range = { line, 0, line, 20 } },
				},
			},
			idx = {},
			update = function() end,
		}
		images.attach(buf, function()
			return renderer
		end)

		assert.same({ { src = "/tmp/photo.jpg", file = "/tmp/cache/photo.conv.png" } }, images.at_cursor())
	end)

	it("follows the image through edits made while showing links", function()
		local buf = vim.api.nvim_create_buf(false, true)
		local previous = vim.api.nvim_get_current_buf()
		vim.api.nvim_set_current_buf(buf)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "intro", "![fig](fig.png)", "outro" })
		local renderer = {
			imgs = {
				first = {
					img = { src = "/tmp/fig.png" },
					opts = { range = { 2, 0, 2, 15 } },
					close = function() end,
				},
			},
			idx = {},
			update = function() end,
		}
		images.attach(buf, function()
			return renderer
		end)
		images.toggle(buf)

		vim.api.nvim_buf_set_lines(buf, 0, 0, false, { "a", "b", "c" })

		vim.api.nvim_win_set_cursor(0, { 5, 0 })
		assert.same({ { src = "/tmp/fig.png" } }, images.at_cursor(buf))
		vim.api.nvim_win_set_cursor(0, { 2, 0 })
		assert.same({}, images.at_cursor(buf))

		vim.api.nvim_set_current_buf(previous)
		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("leaves the action unhandled when there is no document image", function()
		assert.is_false(images.copy_at_cursor())
		assert.is_false(images.open_at_cursor())
	end)
end)

describe("Remote document images", function()
	local images, copy, open, select
	before_each(function()
		package.loaded["config.document_images"] = nil
		images = require("config.document_images")
		local stub = require("luassert.stub")
		copy = stub(require("config.notebook_copy"), "copy_file")
		open = stub(require("config.image_viewer"), "open")
	end)
	after_each(function()
		copy:revert()
		open:revert()
		if select then
			select:revert()
			select = nil
		end
	end)

	for _, links in ipairs({ false, true }) do
		it("uses the cached remote file with links " .. tostring(links), function()
			local buf = vim.api.nvim_get_current_buf()
			local line = vim.api.nvim_win_get_cursor(0)[1]
			images.attach(buf, function()
				return {
					imgs = {
						{
							img = { src = "https://example.com/photo.jpg", file = "/tmp/cache/photo.png" },
							opts = { range = { line, 0, line, 20 } },
							close = function() end,
						},
					},
					idx = {},
					update = function() end,
				}
			end)
			if links then
				images.toggle(buf)
			end
			images.copy_at_cursor()
			images.open_at_cursor()
			assert.stub(copy).was_called_with("/tmp/cache/photo.png")
			assert.stub(open).was_called_with("/tmp/cache/photo.png")
		end)
	end

	it("labels remote choices with their original names", function()
		local buf = vim.api.nvim_get_current_buf()
		local line = vim.api.nvim_win_get_cursor(0)[1]
		images.attach(buf, function()
			local imgs = {}
			for i, name in ipairs({ "first.jpg", "second.jpg" }) do
				imgs[i] = {
					img = { src = "https://example.com/" .. name, file = "/tmp/cache/" .. i .. ".png" },
					opts = { pos = { line, 0 } },
				}
			end
			return { imgs = imgs, idx = {}, update = function() end }
		end)
		local labels = {}
		select = require("luassert.stub")(vim.ui, "select", function(items, opts, callback)
			for _, item in ipairs(items) do
				table.insert(labels, opts.format_item(item))
			end
			callback(items[2])
		end)
		images.copy_at_cursor()
		assert.same({ "first.jpg", "second.jpg" }, labels)
		assert.stub(copy).was_called_with("/tmp/cache/2.png")
	end)
end)
