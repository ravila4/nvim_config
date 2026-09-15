describe("notebook horizontal scrolling", function()
	local buf, wrap, virtualedit
	before_each(function()
		buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_set_current_buf(buf)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "x", "y" })
		wrap, virtualedit = vim.wo.wrap, vim.wo.virtualedit
		vim.wo.wrap = false
	end)
	after_each(function()
		vim.wo.wrap, vim.wo.virtualedit = wrap, virtualedit
		vim.api.nvim_buf_delete(buf, { force = true })
	end)
	it("pans past a short anchor through a redraw without changing editing options", function()
		require("config.notebook_images").scroll("zl", 30)
		vim.cmd.redraw()
		assert.equal(30, vim.fn.winsaveview().leftcol)
		assert.equal(virtualedit, vim.wo.virtualedit)
		assert.same({ "x", "y" }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
	end)
	it("pans back without passing the start of the image", function()
		require("config.notebook_images").scroll("zl", 30)
		require("config.notebook_images").scroll("zh", 40)
		vim.cmd.redraw()
		assert.equal(0, vim.fn.winsaveview().leftcol)
	end)
end)

describe("notebook image window transfer", function()
	local source, floating, previous_image
	before_each(function()
		source = vim.api.nvim_get_current_win()
		floating = vim.api.nvim_open_win(vim.api.nvim_get_current_buf(), true, {
			relative = "editor",
			row = 1,
			col = 1,
			width = 40,
			height = 10,
		})
		previous_image = package.loaded.image
	end)
	after_each(function()
		package.loaded.image = previous_image
		if vim.api.nvim_win_is_valid(floating) then
			vim.api.nvim_win_close(floating, true)
		end
		package.loaded["config.notebook_images"] = nil
	end)

	it("moves buffer images into the active window and back", function()
		local rendered_in = {}
		local img = {
			buffer = vim.api.nvim_get_current_buf(),
			window = source,
			clear = function() end,
			render = function(self)
				table.insert(rendered_in, self.window)
			end,
		}
		package.loaded.image = {
			get_images = function()
				return { img }
			end,
		}
		require("config.notebook_images").refresh()
		assert.equals(floating, img.window)
		vim.api.nvim_win_close(floating, true)
		require("config.notebook_images").refresh()
		assert.equals(source, img.window)
		assert.same({ floating, source }, rendered_in)
	end)

	it("leaves other buffers' images untouched", function()
		local img = { buffer = -1, window = source }
		package.loaded.image = {
			get_images = function()
				return { img }
			end,
		}
		require("config.notebook_images").refresh()
		assert.equals(source, img.window)
	end)

	it("does not load the image plugin when unused", function()
		package.loaded.image = nil
		require("config.notebook_images").refresh()
		assert.is_nil(package.loaded.image)
	end)
end)
