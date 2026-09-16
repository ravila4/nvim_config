local lazy = vim.fn.stdpath("data") .. "/lazy/"
vim.opt.rtp:append(lazy .. "mini.diff")
vim.opt.rtp:append(lazy .. "jupytext.nvim")
require("jupytext").setup({ format = "md:markdown", autosync = false })

describe("Notebook Git reference", function()
	local dir, buf, diff, notebook
	local function run(args, input)
		local result = vim.system(args, { cwd = dir, stdin = input, text = true }):wait()
		assert.are.equal(0, result.code, result.stderr)
		return result.stdout
	end
	local function write()
		vim.fn.writefile({ vim.json.encode(notebook) }, dir .. "/example.ipynb")
	end
	local function data()
		return diff.get_buf_data(buf)
	end
	local function wait_for(predicate)
		assert.is_true(
			vim.wait(5000, function()
				return data() and data().ref_text ~= nil and predicate()
			end, 20),
			vim.inspect(data())
		)
	end
	before_each(function()
		dir = vim.fn.tempname()
		vim.fn.mkdir(dir, "p")
		run({ "git", "init", "-q" })
		notebook = {
			nbformat = 4,
			nbformat_minor = 5,
			metadata = vim.empty_dict(),
			cells = {
				{
					id = "code",
					cell_type = "code",
					metadata = vim.empty_dict(),
					source = "x = 1",
					outputs = {},
					execution_count = vim.NIL,
				},
			},
		}
		write()
		run({ "git", "add", "example.ipynb" })
		diff = require("mini.diff")
		require("plugins.quickedit")[1].config()
		vim.cmd.edit(vim.fn.fnameescape(dir .. "/example.ipynb"))
		buf = vim.api.nvim_get_current_buf()
		diff.enable(buf)
		wait_for(function()
			return data() and data().ref_text ~= nil
		end)
	end)
	after_each(function()
		if buf and vim.api.nvim_buf_is_valid(buf) then
			vim.api.nvim_buf_delete(buf, { force = true })
		end
		vim.fn.delete(dir, "rf")
	end)
	it("opens a staged notebook with no differences", function()
		wait_for(function()
			return #data().hunks == 0
		end)
		assert.are.equal(table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n") .. "\n", data().ref_text)
	end)
	it("marks only the edited source line", function()
		local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		local row
		for i, line in ipairs(lines) do
			if line == "x = 1" then
				row = i
			end
		end
		vim.api.nvim_buf_set_lines(buf, row - 1, row, false, { "x = 2" })
		vim.api.nvim_exec_autocmds("TextChanged", { buffer = buf })
		wait_for(function()
			return #data().hunks == 1
		end)
		assert.are.equal(row, data().hunks[1].buf_start)
		assert.are.equal(1, data().hunks[1].buf_count)
		assert.are.equal("change", data().hunks[1].type)
	end)
	it("keeps saved edits marked until the index changes", function()
		notebook.cells[1].source = "x = 2"
		write()
		vim.cmd("edit!")
		wait_for(function()
			return #data().hunks == 1
		end)
		vim.api.nvim_exec_autocmds("BufWritePost", { buffer = buf })
		assert.are.equal(1, #data().hunks)
		run({ "git", "add", "example.ipynb" })
		wait_for(function()
			return #data().hunks == 0
		end)
	end)
	it("ignores changes to execution counts and outputs", function()
		notebook.cells[1].execution_count = 9
		notebook.cells[1].outputs = { { output_type = "stream", name = "stdout", text = "hello\n" } }
		write()
		vim.cmd("edit!")
		wait_for(function()
			return #data().hunks == 0
		end)
		assert.are.equal(table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n") .. "\n", data().ref_text)
	end)
	it("shows a notebook removed from the index as entirely added", function()
		run({ "git", "rm", "--cached", "example.ipynb" })
		wait_for(function()
			return data().ref_text == "" and #data().hunks == 1
		end)
		assert.are.equal("add", data().hunks[1].type)
	end)
	it("does not attach the notebook source to ordinary files", function()
		local other = vim.api.nvim_create_buf(true, false)
		vim.api.nvim_buf_set_name(other, dir .. "/ordinary.py")
		diff.enable(other)
		assert.is_false(require("config.notebook_diff").source().attach(other))
		assert.is_nil(diff.get_buf_data(other).ref_text)
		vim.api.nvim_buf_delete(other, { force = true })
	end)
	it("removes misleading signs when conversion fails", function()
		local notify, warnings = vim.notify, {}
		vim.notify = function(message)
			table.insert(warnings, message)
		end
		vim.fn.writefile({ "not a notebook" }, dir .. "/example.ipynb")
		run({ "git", "add", "example.ipynb" })
		local cleared = vim.wait(5000, function()
			return data().ref_text == nil and #warnings > 0
		end, 20)
		vim.notify = notify
		assert.is_true(cleared)
		assert.is_truthy(warnings[1]:match("Notebook diff:"))
	end)
	it("discards conversion results after the buffer is disabled", function()
		require("config.notebook_diff").refresh(buf)
		diff.disable(buf)
		vim.wait(500, function()
			return false
		end)
		assert.is_nil(data())
	end)
	it("has no partial staging operation", function()
		local original = run({ "git", "show", ":example.ipynb" })
		vim.api.nvim_buf_set_lines(buf, 0, 1, false, { "changed header" })
		wait_for(function()
			return #data().hunks == 1
		end)
		assert.has_error(function()
			diff.do_hunks(buf, "apply")
		end)
		assert.are.equal(original, run({ "git", "show", ":example.ipynb" }))
	end)
	it("renders a gutter sign only beside the changed line", function()
		vim.wo.number = false
		vim.wo.signcolumn = "yes"
		vim.api.nvim_buf_set_lines(buf, 0, 1, false, { "changed header" })
		wait_for(function()
			return #data().hunks == 1
		end)
		vim.cmd("redraw!")
		assert.are.equal("┃", vim.fn.screenstring(1, 1))
		assert.are.equal(" ", vim.fn.screenstring(2, 1))
	end)
	it("keeps the Git reference when toggling the notebook overlay", function()
		local reference = data().ref_text
		local mapping = vim.fn.maparg("<leader>gi", "n", false, true)
		mapping.callback()
		assert.is_true(data().overlay)
		assert.are.equal(reference, data().ref_text)
		mapping.callback()
		assert.is_false(data().overlay)
		assert.are.equal(reference, data().ref_text)
	end)
	it("maintains independent references for two open notebooks", function()
		local first_reference = data().ref_text
		notebook.cells[1].source = "different = 3"
		vim.fn.writefile({ vim.json.encode(notebook) }, dir .. "/second.ipynb")
		run({ "git", "add", "second.ipynb" })
		vim.cmd("split " .. vim.fn.fnameescape(dir .. "/second.ipynb"))
		local other = vim.api.nvim_get_current_buf()
		assert.is_true(vim.wait(5000, function()
			local second = diff.get_buf_data(other)
			return second and second.ref_text and second.ref_text:find("different = 3", 1, true)
		end, 20))
		assert.are.equal(first_reference, data().ref_text)
		vim.api.nvim_buf_delete(other, { force = true })
	end)
	it("supports literal notebook names containing Git glob characters", function()
		vim.fn.writefile({ vim.json.encode(notebook) }, dir .. "/plot [1].ipynb")
		run({ "git", "--literal-pathspecs", "add", "plot [1].ipynb" })
		vim.cmd("edit " .. vim.fn.fnameescape(dir .. "/plot [1].ipynb"))
		local other = vim.api.nvim_get_current_buf()
		local ready = vim.wait(5000, function()
			local result = diff.get_buf_data(other)
			return result and result.ref_text ~= nil
		end, 20)
		local reference = diff.get_buf_data(other).ref_text
		vim.api.nvim_buf_delete(other, { force = true })
		assert.is_true(ready)
		assert.is_truthy(reference:find("x = 1", 1, true))
	end)
end)
