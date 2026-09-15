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
					img = { file = "/tmp/figure.png" },
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

		assert.same({ "/tmp/figure.png" }, images.at_cursor())
	end)

	it("keeps image actions available while showing links", function()
		local buf = vim.api.nvim_get_current_buf()
		local line = vim.api.nvim_win_get_cursor(0)[1]
		local renderer = {
			imgs = {
				first = {
					img = { file = "/tmp/figure.png" },
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

		assert.same({ "/tmp/figure.png" }, images.at_cursor(buf))
	end)

	it("copies and opens the rendered image through the shared helpers", function()
		local buf = vim.api.nvim_get_current_buf()
		local line = vim.api.nvim_win_get_cursor(0)[1]
		local renderer = {
			imgs = {
				first = {
					img = { file = "/tmp/figure.png" },
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

	it("leaves the action unhandled when there is no document image", function()
		assert.is_false(images.copy_at_cursor())
		assert.is_false(images.open_at_cursor())
	end)
end)
