describe("notebook runtime labels", function()
	local runtime
	before_each(function()
		runtime = require("config.notebook_runtime")
	end)
	it("does not time queued or unexecuted cells", function()
		assert.equals("queued", runtime.label({ status = "queued" }, 100, "spinner"))
		assert.equals("", runtime.label({ status = "not run" }, 100, "spinner"))
	end)
	it("animates running time from the execution start", function()
		local cell = { status = "running", started_at = 100 }
		assert.equals("⠋ 2.3s", runtime.label(cell, 102.3, "spinner", 0))
		assert.equals("⠙ 2.4s", runtime.label(cell, 102.4, "spinner", 1))
	end)
	it("freezes final success and error durations", function()
		for status, icon in pairs({ done = "✓", error = "✗" }) do
			local cell = { status = status, started_at = 100, finished_at = 102.8 }
			assert.equals(icon .. " 2.8s", runtime.label(cell, 200, "spinner"))
		end
	end)
	it("never invents a duration for imported output", function()
		assert.equals("✓", runtime.label({ status = "done", old = true, started_at = vim.NIL }, 100, "spinner"))
	end)
	it("supports blink and no indicator without hiding elapsed time", function()
		local cell = { status = "running", started_at = 100 }
		assert.equals("● 2.3s", runtime.label(cell, 102.3, "blink", 0))
		assert.equals("  2.3s", runtime.label(cell, 102.3, "blink", 5))
		assert.equals("2.3s", runtime.label(cell, 102.3, "none", 0))
	end)
end)
