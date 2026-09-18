-- Jupyter notebook and REPL integration tools
-- Molten provides inline Jupyter execution; R scripts use R.nvim.

return {
	-- Dependencies
	{
		"nvim-lua/plenary.nvim",
		lazy = true,
	},
	{
		"MunifTanjim/nui.nvim",
		lazy = true,
	},

	-- Molten-nvim for VSCode-like inline Jupyter experience.
	{
		"ravila4/molten-nvim",
		branch = "fix/virt-image-layout",
		build = ":UpdateRemotePlugins",
		lazy = false, -- Load immediately so commands are always available
		dependencies = {
			"folke/snacks.nvim",
		},
		config = function()
			require("config.notebook_kernels").setup_prompts()
			-- Global configuration
			vim.g.molten_image_provider = "snacks.nvim"
			vim.g.molten_output_win_max_height = 20 -- Reasonable output window height
			vim.g.molten_auto_open_output = false -- Manual control over output
			vim.g.molten_wrap_output = true -- Wrap long outputs
			vim.g.molten_virt_text_output = true -- Show outputs as virtual text
			vim.g.molten_virt_lines_off_by_1 = true -- Better virtual line positioning
			vim.g.molten_output_format = "markdown" -- DataFrame HTML as pipe tables, text/markdown verbatim

			-- Molten paints the cell under the cursor with MoltenCell (CursorLine by
			-- default), which is a solid gray in the light theme. The cell borders
			-- already show the active cell, so drop the fill and keep it dropped when
			-- the colorscheme reloads.
			local function clear_cell_highlight()
				vim.api.nvim_set_hl(0, "MoltenCell", {})
			end
			clear_cell_highlight()
			vim.api.nvim_create_autocmd("ColorScheme", {
				group = vim.api.nvim_create_augroup("MoltenCellHighlight", { clear = true }),
				callback = clear_cell_highlight,
			})

			-- Theme integration - use your teal accent
			vim.g.molten_output_crop_border = true
			vim.g.molten_output_show_more = true
			vim.g.molten_output_show_status = false
			vim.g.molten_output_show_exec_time = false
			vim.g.molten_output_virt_lines = true

			-- Performance settings for bioinformatics (large outputs)
			vim.g.molten_limit_output_chars = 1000000 -- 1MB limit for large genomics outputs
			vim.g.molten_copy_output = false -- Don't auto-copy to clipboard

			-- Molten keybindings (unified with other Jupyter tools)
			local function map(mode, key, cmd, desc)
				vim.keymap.set(mode, key, cmd, { desc = desc, buffer = true })
			end

			local python_cells = require("config.jupyter_cells")

			local function buffer_lines()
				return vim.api.nvim_buf_get_lines(0, 0, -1, false)
			end

			local function move_python_cell(direction)
				local lines = buffer_lines()
				local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
				local target_line = python_cells[direction .. "_line"](lines, cursor_line)
				vim.api.nvim_win_set_cursor(0, { target_line, 0 })
			end

			local function run_current_cell()
				if vim.bo.filetype == "python" then
					local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
					local bounds = python_cells.bounds(buffer_lines(), cursor_line)
					if bounds[1] <= bounds[2] then
						vim.fn.MoltenEvaluateRange(bounds[1], bounds[2])
					end
					return
				end

				if vim.tbl_contains({ "markdown", "quarto", "rmd" }, vim.bo.filetype) then
					require("quarto.runner").run_cell()
					return
				end

				vim.cmd("MoltenEvaluateLine")
			end

			local function move_to_next_cell()
				if vim.bo.filetype == "python" then
					move_python_cell("next")
					return
				end

				local ok, move = pcall(require, "nvim-treesitter-textobjects.move")
				if ok then
					move.goto_next_start("@block.inner")
				end
			end

			local function move_to_previous_cell()
				if vim.bo.filetype == "python" then
					move_python_cell("previous")
					return
				end

				local ok, move = pcall(require, "nvim-treesitter-textobjects.move")
				if ok then
					move.goto_previous_start("@block.inner")
				end
			end

			local function run_cell_and_advance()
				run_current_cell()
				move_to_next_cell()
			end

			local function go_to_cell()
				vim.ui.input({ prompt = "Cell number: " }, function(value)
					local number = tonumber(value)
					local document = require("config.document_outline")
					local cells = document.cells(document.parse(buffer_lines(), document.format(0)))
					local cell = number and number % 1 == 0 and cells[number]
					if not cell then
						if value ~= nil then
							vim.notify(
								("Cell %s does not exist; this document has %d cell%s"):format(
									value,
									#cells,
									#cells == 1 and "" or "s"
								),
								vim.log.levels.WARN
							)
						end
						return
					end
					vim.api.nvim_win_set_cursor(0, { cell.range.start.line + 1, 0 })
					vim.cmd("normal! zz")
				end)
			end

			local function cell_representation()
				if vim.tbl_contains({ "python", "julia", "r" }, vim.bo.filetype) then
					return "percent", vim.bo.filetype
				end
				if vim.tbl_contains({ "quarto", "rmd" }, vim.bo.filetype) then
					return "fenced", "{python}"
				end
				return "fenced", "python"
			end

			local function replace_changed_lines(previous, updated)
				local change = python_cells.changed_region(previous, updated)
				vim.api.nvim_buf_set_lines(0, change.start_line, change.end_line, false, change.replacement)
			end

			local function create_cell(direction)
				local previous = buffer_lines()
				local representation, language = cell_representation()
				local result = python_cells.insert(
					previous,
					vim.api.nvim_win_get_cursor(0)[1],
					direction,
					representation,
					language
				)
				replace_changed_lines(previous, result.lines)
				vim.api.nvim_win_set_cursor(0, { result.cursor_line, 0 })
				vim.cmd("startinsert")
			end

			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "python", "julia", "ipynb", "markdown", "quarto", "rmd" },
				callback = function()
					map("n", "<leader>my", function()
						if not require("config.document_images").copy_at_cursor() then
							require("config.notebook_copy").copy_at_cursor()
						end
					end, "Copy image to clipboard")
					if
						vim.fn.expand("%:e") == "ipynb"
						or vim.bo.filetype == "markdown"
						or vim.bo.filetype == "quarto"
					then
						map("n", "<leader>mi", function()
							if not require("config.document_images").open_at_cursor() then
								require("config.notebook_copy").open_at_cursor()
							end
						end, "Open image")
					end
					if vim.bo.filetype == "markdown" and vim.fn.expand("%:e") ~= "ipynb" then
						return
					end
					-- Molten-specific mappings (prefix: <leader>m)
					map("n", "<leader>mK", function()
						require("config.notebook_kernels").pick()
					end, "[Molten] Select kernel")
					map("n", "<leader>mr", ":MoltenEvaluateOperator<CR>", "[Molten] Run operator")
					map("n", "<leader>ml", ":MoltenEvaluateLine<CR>", "[Molten] Run line")
					map("n", "<leader>mc", ":MoltenReevaluateCell<CR>", "[Molten] Re-run cell")
					map("v", "<leader>mr", ":<C-u>MoltenEvaluateVisual<CR>gv", "[Molten] Run selection")
					map("n", "<leader>mh", ":MoltenHideOutput<CR>", "[Molten] Hide output")
					map("n", "<leader>ms", ":MoltenShowOutput<CR>", "[Molten] Show output")
					if vim.fn.expand("%:e") == "ipynb" then
						for _, key in ipairs({ "zh", "zl", "zH", "zL" }) do
							map("n", key, function()
								require("config.notebook_images").scroll(key, vim.v.count1)
							end, "[Molten] Scroll horizontally")
						end
					end
					map("n", "<leader>mo", function()
						require("config.notebook_copy").copy_output_at_cursor()
					end, "[Molten] Copy output text to clipboard")
					map("n", "<leader>x", ":MoltenInterrupt<CR>", "[Molten] Interrupt execution")
					map("n", "<leader>mq", ":MoltenDeinit<CR>", "[Molten] Quit kernel")

					-- Smart cell execution - detects markdown code blocks
					map("n", "<S-CR>", run_cell_and_advance, "[Molten] Run cell + advance")
					map("n", "<C-CR>", run_cell_and_advance, "[Molten] Run cell + advance")
					map("n", "<leader><CR>", run_current_cell, "[Molten] Run cell")
					map("n", "<leader>jr", run_current_cell, "[Unified] Run cell (smart)")
					map("v", "<leader>jr", ":<C-u>MoltenEvaluateVisual<CR>gv", "[Unified] Run selection")
					map("n", "<leader>jK", function()
						require("config.notebook_kernels").pick()
					end, "[Unified] Select kernel")
					if require("config.document_outline").format(0) ~= nil then
						map("n", "<leader>jg", go_to_cell, "[Cell] Go to numbered cell")
					end
					map("n", "<leader>jo", function()
						create_cell("below")
					end, "[Cell] Create below")
					map("n", "<leader>jO", function()
						create_cell("above")
					end, "[Cell] Create above")
					map("n", "<leader>]", move_to_next_cell, "[Unified] Next cell")
					map("n", "<leader>[", move_to_previous_cell, "[Unified] Previous cell")

					if vim.bo.filetype == "python" then
						map("n", "]c", function()
							move_python_cell("next")
						end, "Next Python cell")
						map("n", "[c", function()
							move_python_cell("previous")
						end, "Previous Python cell")
					end

					-- Full output viewing
					map("n", "<leader>jv", function()
						require("config.notebook_output_view").open()
					end, "[Output] Open output buffer")
					map("n", "<leader>jh", ":MoltenHideOutput<CR>", "[Output] Hide output")
					map("n", "<leader>jm", ":MoltenToggleOutputFormat<CR>", "[Output] Toggle markdown output")
					map("n", "<leader>je", ":MoltenToggleVirtExpand<CR>", "[Output] Expand/collapse ghost text")
					-- A click on the "More Lines" / "Show Less" footer toggles that output;
					-- any other click stays a normal click.
					vim.keymap.set("n", "<LeftMouse>", function()
						if require("config.notebook_output_view").click_footer() then
							return ""
						end
						return "<LeftMouse>"
					end, { buffer = true, expr = true, desc = "[Output] Click footer to expand" })
				end,
			})
		end,
	},

	-- Jupytext.nvim for .ipynb file conversion to readable text format
	{
		"goerz/jupytext.nvim",
		lazy = false, -- Must load immediately to handle .ipynb file conversion
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		config = function()
			require("jupytext").setup({
				-- Use markdown format with python code blocks instead of %% cells
				format = "md:markdown",
				-- Set filetype to markdown so LSP doesn't try to parse as pure Python
				filetype = function(path, format, metadata)
					return "markdown"
				end,
			})
			require("config.notebook_save").setup()
			require("config.notebook_borders").setup({
				running_indicator = "spinner", -- "spinner", "blink", or "none"; elapsed time stays visible
			})

			-- Show the outputs already saved in the .ipynb without re-executing it.
			-- Molten attaches imported outputs to a kernel, so one is started first
			-- when the buffer has none.
			local function import_saved_outputs(path)
				local ok, notebook = pcall(function()
					return vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
				end)
				local has_outputs = false
				if ok then
					for _, cell in ipairs(notebook.cells or {}) do
						if cell.cell_type == "code" and cell.outputs and #cell.outputs > 0 then
							has_outputs = true
							break
						end
					end
				end
				if not has_outputs then
					return
				end
				if #vim.fn.MoltenRunningKernels(true) == 0 then
					require("config.notebook_kernels").open(vim.api.nvim_get_current_buf(), notebook.metadata or {})
				else
					vim.cmd.MoltenImportOutput()
				end
			end

			-- Ensure proper markdown detection and syntax highlighting for converted notebooks
			vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
				pattern = "*.ipynb",
				callback = function(args)
					-- Force markdown filetype and enable syntax highlighting
					vim.bo[args.buf].filetype = "markdown"
					-- Enable treesitter highlighting
					vim.defer_fn(function()
						if vim.api.nvim_buf_is_loaded(args.buf) and vim.bo[args.buf].filetype == "markdown" then
							vim.treesitter.start(args.buf)
							-- Trigger markview if available
							if pcall(require, "markview") then
								vim.api.nvim_buf_call(args.buf, function()
									vim.cmd("Markview enable")
								end)
							end
						end
					end, 100)
					-- jupytext has replaced the buffer contents by now. Molten commands act
					-- on the current window, so the import runs in the notebook's window.
					-- Neo-tree's open_in_main_window loads the buffer before showing it,
					-- so the import waits for the first window that displays it.
					vim.schedule(function()
						if not vim.api.nvim_buf_is_loaded(args.buf) then
							return
						end
						local path = vim.api.nvim_buf_get_name(args.buf)
						local win = vim.fn.bufwinid(args.buf)
						if win ~= -1 then
							vim.api.nvim_win_call(win, function()
								import_saved_outputs(path)
							end)
							return
						end
						vim.api.nvim_create_autocmd("BufWinEnter", {
							buffer = args.buf,
							once = true,
							callback = function()
								import_saved_outputs(path)
							end,
						})
					end)
				end,
			})
		end,
	},
}
