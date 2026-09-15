local document = require("config.document_outline")

describe("Quarto outline actions", function()
	it("refuses to create cells inside unfinished YAML", function()
		local docbuf = vim.api.nvim_create_buf(true, false)
		vim.api.nvim_buf_set_lines(docbuf, 0, -1, false, { "---", "title: Test" })
		local ok, err = pcall(require("config.quarto_outline").create, docbuf, nil, "below", "python")
		local result = vim.api.nvim_buf_get_lines(docbuf, 0, -1, false)
		vim.api.nvim_buf_delete(docbuf, { force = true })
		assert.is_false(ok)
		assert.is_truthy(tostring(err):find("front matter", 1, true))
		assert.are.same({ "---", "title: Test" }, result)
	end)
	local buf, sent, chunks, old_keeper, old_runner, old_config
	local lines = {
		"# Title",
		"```{python}",
		"first()",
		"last_line()",
		"```",
		"```json",
		"{}",
		"```",
		"```{r}",
		"plot(x)",
		"```",
		"```{python}",
		"final()",
		"```",
	}
	local function cells()
		return document.cells(document.parse(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "quarto"))
	end
	local function run(index, scope)
		return require("config.quarto_outline").run(buf, cells()[index], scope)
	end
	before_each(function()
		buf = vim.api.nvim_create_buf(true, false)
		vim.api.nvim_set_current_buf(buf)
		vim.api.nvim_buf_set_name(buf, "/tmp/quarto-outline-action.qmd")
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
		sent = {}
		chunks = {
			python = {
				{ lang = "python", range = { from = { 2, 0 }, to = { 4, 0 } } },
				{ lang = "python", range = { from = { 12, 0 }, to = { 13, 0 } } },
			},
			r = { { lang = "r", range = { from = { 9, 0 }, to = { 10, 0 } } } },
		}
		old_keeper, old_runner, old_config =
			package.loaded["otter.keeper"], package.loaded["quarto.runner"], _G.QuartoConfig
		package.loaded["otter.keeper"] = {
			sync_raft = function() end,
			rafts = { [buf] = { code_chunks = chunks } },
			get_current_language_context = function()
				local row = vim.api.nvim_win_get_cursor(0)[1] - 1
				for lang, group in pairs(chunks) do
					for _, chunk in ipairs(group) do
						if row >= chunk.range.from[1] and row < chunk.range.to[1] then
							return lang
						end
					end
				end
			end,
		}
		package.loaded["quarto.runner"] = {
			run_cell = function()
				sent[#sent + 1] = { vim.api.nvim_get_current_buf(), vim.api.nvim_win_get_cursor(0)[1] }
			end,
		}
		_G.QuartoConfig = { codeRunner = { default_method = function() end, ft_runners = {}, never_run = { "yaml" } } }
	end)
	after_each(function()
		package.loaded["otter.keeper"], package.loaded["quarto.runner"], _G.QuartoConfig =
			old_keeper, old_runner, old_config
		require("config.notebook_edit").reset(buf)
		vim.api.nvim_buf_delete(buf, { force = true })
	end)
	it("dispatches above in source order excluding selected cell and examples", function()
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		run(3, "All Above")
		assert.are.same({ { buf, 3 }, { buf, 10 } }, sent)
		assert.are.same({ 1, 0 }, vim.api.nvim_win_get_cursor(0))
	end)
	it("refuses all targets before dispatch when a later range disagrees", function()
		chunks.r[1].range.to[1] = 11
		assert.has_error(function()
			run(3, "All Above")
		end)
		assert.are.same({}, sent)
	end)
	it("enforces never_run on individual cells", function()
		QuartoConfig.codeRunner.never_run = { "python" }
		assert.has_error(function()
			run(1, "Cell")
		end)
		assert.are.same({}, sent)
	end)
	it("reports empty cells before attempting extraction or dispatch", function()
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "```{python}", "", "```" })
		local ok, err = pcall(run, 1, "Cell")
		assert.is_false(ok)
		assert.is_truthy(tostring(err):find("empty", 1, true))
		assert.are.same({}, sent)
	end)
	it("refuses mixed Molten bulk before dispatch", function()
		QuartoConfig.codeRunner.default_method = "molten"
		assert.has_error(function()
			run(3, "All Above")
		end)
		assert.are.same({}, sent)
	end)
	it("refuses ambiguous overlapping extracted chunks", function()
		table.insert(chunks.python, { lang = "python", range = { from = { 2, 0 }, to = { 3, 0 } } })
		assert.has_error(function()
			run(1, "Cell")
		end)
		assert.are.same({}, sent)
	end)
	it("creates a cell inheriting the selected language", function()
		require("config.quarto_outline").create(buf, cells()[2], "below")
		local result = cells()
		assert.are.equal("r", result[3].language)
		assert.are.equal(4, #result)
		require("config.notebook_edit").undo(buf, false)
		assert.are.same(lines, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
	end)
	it("creates after the complete Setext heading", function()
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "Title", "=====", "paragraph" })
		local heading = document.parse(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "quarto")[1]
		require("config.quarto_outline").create(buf, heading, "above", "python")
		assert.are.same(
			{ "Title", "=====", "", "```{python}", "", "```", "", "paragraph" },
			vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		)
	end)
	it("creates the first cell after YAML frontmatter", function()
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "---", "title: Test", "---" })
		require("config.quarto_outline").create(buf, nil, "below", "python")
		assert.are.equal(4, cells()[1].range.start.line)
	end)
	it("refuses creation inside an unfinished cell", function()
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "```{python}", "x=1" })
		assert.has_error(function()
			require("config.quarto_outline").create(buf, cells()[1], "below")
		end)
	end)
	it("warns about new duplicate labels without changing pasted source", function()
		local source = { "```{python}", "#| label: example", "x=1", "```" }
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, source)
		vim.fn.setreg("a", source, "V")
		local original, messages = vim.notify, {}
		vim.notify = function(message)
			messages[#messages + 1] = message
		end
		local ok, err = pcall(function()
			require("config.quarto_outline").paste(buf, 4, "a", 1)
		end)
		vim.notify = original
		assert.is_true(ok, tostring(err))
		assert.are.equal(1, #messages)
		assert.is_truthy(messages[1]:find("example", 1, true))
		assert.are.equal("example", cells()[2].label)
	end)
	it("loads lazy Molten functions before checking the buffer kernel", function()
		QuartoConfig.codeRunner.default_method = "molten"
		local old = package.loaded["quarto.runner.molten"]
		package.loaded["quarto.runner.molten"] = { run = function() end }
		local group = vim.api.nvim_create_augroup("QuartoLazyMoltenTest", { clear = true })
		vim.api.nvim_create_autocmd("FuncUndefined", {
			group = group,
			pattern = "MoltenRunningKernels",
			callback = function()
				vim.cmd("function! MoltenRunningKernels(local)\nreturn ['test-python']\nendfunction")
			end,
		})
		local ok, err = pcall(run, 1, "Cell")
		vim.api.nvim_del_augroup_by_id(group)
		vim.cmd("delfunction! MoltenRunningKernels")
		package.loaded["quarto.runner.molten"] = old
		assert.is_true(ok, tostring(err))
		assert.are.same({ { buf, 3 } }, sent)
	end)
end)
