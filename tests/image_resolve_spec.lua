describe("Vault image resolution", function()
	local root, expand, resolve

	before_each(function()
		root = vim.fn.tempname()
		vim.fn.mkdir(root .. "/attachments", "p")
		expand = vim.fn.expand
		vim.fn.expand = function(path, ...)
			if path == "~/Documents/Obsidian-Notes" then
				return root
			end
			return expand(path, ...)
		end
		resolve = dofile("lua/plugins/snacks.lua")[1].opts.image.resolve
	end)

	after_each(function()
		vim.fn.expand = expand
		vim.fn.delete(root, "rf")
	end)

	it("resolves shell metacharacters as a literal filename", function()
		local name = 'image$(printf expanded)`printf expanded`".png'
		local path = root .. "/attachments/" .. name
		vim.fn.writefile({}, path)
		assert.are.equal(path, resolve(root .. "/note.md", name))
	end)

	it("does not interpret filename glob characters", function()
		vim.fn.writefile({}, root .. "/attachments/image1.png")
		assert.is_nil(resolve(root .. "/note.md", "image?.png"))
	end)

	it("leaves relative paths and files outside the vault to default resolution", function()
		vim.fn.writefile({}, root .. "/attachments/image.png")
		assert.is_nil(resolve(root .. "/note.md", "attachments/image.png"))
		assert.is_nil(resolve(root .. "-other/note.md", "image.png"))
	end)
end)
