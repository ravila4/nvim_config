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
