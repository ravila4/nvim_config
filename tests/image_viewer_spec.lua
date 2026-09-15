describe("Shared image lightbox", function()
	local old_snacks, old_system, origin, placement, old_copy, old_menu, source, displayed
	before_each(function()
		origin = vim.api.nvim_get_current_win()
		source = vim.fn.tempname() .. ".png"
		vim.fn.writefile({ "image source" }, source)
		old_copy = require("config.notebook_copy").copy_file
		old_menu = package.loaded.menu
		old_snacks, old_system = _G.Snacks, vim.fn.system
		vim.fn.system = function()
			return "800 600"
		end
		_G.Snacks = {
			image = {
				terminal = {
					size = function()
						return { cell_width = 10, cell_height = 20 }
					end,
				},
				buf = {
					attach = function(_, opts)
						displayed = opts.src
						placement = {
							img = { info = { size = { width = 1600, height = 800 } } },
							state = function()
								return { loc = { 1, 0, width = 5, height = 2 }, wins = { origin } }
							end,
						}
						if opts.on_update_pre then
							opts.on_update_pre(placement)
						end
					end,
				},
				placement = { clean = function() end },
			},
		}
	end)
	after_each(function()
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			if win ~= origin then
				vim.api.nvim_win_close(win, true)
			end
		end
		_G.Snacks, vim.fn.system = old_snacks, old_system
		require("config.notebook_copy").copy_file = old_copy
		package.loaded.menu = old_menu
		vim.fn.delete(source)
	end)
	it("copies the displayed source with the notebook copy binding", function()
		local copied
		require("config.notebook_copy").copy_file = function(path)
			copied = path
		end
		require("config.image_viewer").open(source)
		vim.fn.maparg("<leader>my", "n", false, true).callback()
		assert.equal(source, copied)
	end)
	it("keeps the image source when its copy menu takes focus", function()
		local copied, items
		require("config.notebook_copy").copy_file = function(path)
			copied = path
		end
		package.loaded.menu = {
			open = function(entries)
				items = entries
			end,
		}
		require("config.image_viewer").open(source)
		vim.fn.maparg("<RightMouse>", "n", false, true).callback()
		vim.api.nvim_set_current_win(origin)
		assert.equal("Copy Image", items[1].name)
		items[1].cmd()
		assert.equal(source, copied)
	end)
	it("uses the same maximized dimensions for the float and image", function()
		require("config.image_viewer").open(source)
		local config = vim.api.nvim_win_get_config(0)
		local loc = placement:state().loc
		assert.equal(config.width, loc.width)
		assert.equal(config.height, loc.height)
		assert.is_true(config.width > vim.o.columns * 0.85)
		assert.is_true(math.abs(config.width / config.height - 4) < 0.5)
	end)
	it("includes the source file size in its title", function()
		local path = vim.fn.tempname() .. ".png"
		vim.fn.writefile({ string.rep("x", 2047) }, path)
		require("config.image_viewer").open(path)
		vim.fn.delete(path)
		local title = vim.api.nvim_win_get_config(0).title[1][1]
		assert.is_truthy(title:find("2.0 KiB", 1, true))
	end)
	for _, key in ipairs({ "q", "<Esc>" }) do
		it("wipes the image buffer on " .. key, function()
			require("config.image_viewer").open(source)
			local buf = vim.api.nvim_get_current_buf()
			vim.fn.maparg(key, "n", false, true).callback()
			assert.is_false(vim.api.nvim_buf_is_valid(buf))
			assert.equal(origin, vim.api.nvim_get_current_win())
		end)
	end
	it("cleans its placement when the window is closed externally", function()
		local cleaned
		Snacks.image.placement.clean = function(buf)
			cleaned = buf
		end
		require("config.image_viewer").open(source)
		local buf = vim.api.nvim_get_current_buf()
		vim.api.nvim_win_close(0, true)
		assert.equal(buf, cleaned)
		assert.is_false(vim.api.nvim_buf_is_valid(buf))
	end)
	it("uses a distinct file identity pointing to the unchanged source", function()
		require("config.image_viewer").open(source)
		assert.is_not.equal(source, displayed)
		assert.equal(vim.uv.fs_realpath(source), vim.uv.fs_realpath(displayed))
		assert.same(vim.fn.readfile(source), vim.fn.readfile(displayed))
	end)
	it("reuses the lightbox identity after closing and reopening", function()
		require("config.image_viewer").open(source)
		local first = displayed
		vim.api.nvim_win_close(0, true)
		require("config.image_viewer").open(source)
		assert.equal(first, displayed)
		assert.equal(1, vim.fn.filereadable(displayed))
	end)
end)
