local M = {}
local states = {}

function M.is_notebook(buf)
	return vim.api.nvim_buf_get_name(buf):match("%.ipynb$") ~= nil
end

function M.refresh(buf)
	local state = states[buf]
	if not state then
		return
	end
	state.generation = state.generation + 1
	local generation = state.generation
	local function current()
		return states[buf] == state and state.generation == generation and vim.api.nvim_buf_is_valid(buf)
	end
	local function fail(message)
		require("mini.diff").set_ref_text(buf, nil)
		if state.error ~= message then
			vim.notify("Notebook diff: " .. message, vim.log.levels.WARN)
			state.error = message
		end
	end
	local function run(args, opts, callback)
		local ok, err = pcall(
			vim.system,
			args,
			opts,
			vim.schedule_wrap(function(result)
				if current() then
					callback(result)
				end
			end)
		)
		if not ok and current() then
			fail(tostring(err))
		end
	end
	local path = vim.api.nvim_buf_get_name(buf)
	local cwd, name = vim.fs.dirname(path), vim.fs.basename(path)
	local git_opts = { cwd = cwd, text = true }
	local function publish(text)
		state.error = nil
		require("mini.diff").set_ref_text(buf, text)
	end
	run({ "git", "rev-parse", "--absolute-git-dir" }, git_opts, function(repo)
		if repo.code ~= 0 then
			require("mini.diff").set_ref_text(buf, nil)
			return
		end
		local gitdir = vim.trim(repo.stdout)
		if not state.watcher then
			state.watcher = vim.uv.new_fs_event()
			state.watcher:start(
				gitdir,
				{},
				vim.schedule_wrap(function(_, filename)
					if states[buf] == state and filename == "index" then
						M.refresh(buf)
					end
				end)
			)
		end
		run({ "git", "ls-files", "--stage", "--", name }, git_opts, function(entry)
			if entry.code ~= 0 then
				return fail(entry.stderr)
			end
			if entry.stdout == "" then
				return publish("")
			end
			if not entry.stdout:match("^%d+ %x+ 0\t") then
				return fail("Resolve the notebook's index conflict before displaying source diffs.")
			end
			run({ "git", "show", ":./" .. name }, git_opts, function(blob)
				if blob.code ~= 0 then
					return fail(blob.stderr)
				end
				local jupytext = require("jupytext")
				local format = jupytext.get_option("format")
				if type(format) == "function" then
					format = format(path, jupytext.get_metadata(vim.split(blob.stdout, "\n")))
				end
				local command = jupytext.get_option("jupytext")
				if state.blob == blob.stdout and state.format == format and state.command == command then
					return publish(state.reference)
				end
				-- Match jupytext.nvim's stdin conversion, including its working directory.
				run(
					{ command, "--from", "ipynb", "--to", format, "--output", "-" },
					{ text = true, stdin = blob.stdout },
					function(converted)
						if converted.code ~= 0 then
							return fail(converted.stderr)
						end
						state.blob, state.format, state.command = blob.stdout, format, command
						state.reference = converted.stdout
						publish(state.reference)
					end
				)
			end)
		end)
	end)
end

function M.source()
	return {
		name = "notebook_git",
		attach = function(buf)
			if not M.is_notebook(buf) then
				return false
			end
			states[buf] = { generation = 0 }
			local group = vim.api.nvim_create_augroup("NotebookDiff" .. buf, { clear = true })
			states[buf].group = group
			vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
				group = group,
				buffer = buf,
				callback = function()
					M.refresh(buf)
				end,
			})
			vim.api.nvim_create_autocmd("FocusGained", {
				group = group,
				callback = function()
					M.refresh(buf)
				end,
			})
			vim.schedule(function()
				M.refresh(buf)
			end)
		end,
		detach = function(buf)
			local state = states[buf]
			states[buf] = nil
			if not state then
				return
			end
			if state.watcher then
				state.watcher:stop()
				state.watcher:close()
			end
			vim.api.nvim_del_augroup_by_id(state.group)
		end,
	}
end

return M
