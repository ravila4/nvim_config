-- Jupyter kernels on a remote host, reached through one ssh process that
-- forwards the kernel's five ports and owns its lifetime. Molten attaches
-- through its external-kernel mode with a local copy of the connection file.
local M = {}

M.orphan_timeout = 90 -- seconds without a heartbeat before the remote wrapper kills the kernel
M.heartbeat_interval = 15 -- seconds between heartbeats written to the ssh stdin
M.paths = {} -- local connection file -> session, for display lookups

local function hosts()
	return vim.g.notebook_remotes or {}
end

function M.ports()
	local ports, seen = {}, {}
	while #ports < 5 do
		local port = math.random(41000, 49000)
		if not seen[port] then
			seen[port] = true
			ports[#ports + 1] = port
		end
	end
	return ports
end

function M.key()
	local hex = {}
	for _ = 1, 32 do
		hex[#hex + 1] = ("%x"):format(math.random(0, 15))
	end
	return table.concat(hex)
end

function M.connection(ports, key, kernel)
	return {
		shell_port = ports[1],
		iopub_port = ports[2],
		stdin_port = ports[3],
		control_port = ports[4],
		hb_port = ports[5],
		ip = "127.0.0.1",
		transport = "tcp",
		signature_scheme = "hmac-sha256",
		key = key,
		kernel_name = kernel,
	}
end

function M.substitute(argv, remote_path)
	return vim.tbl_map(function(element)
		return (element:gsub("{connection_file}", function()
			return remote_path
		end))
	end, argv)
end

function M.quote(value)
	return "'" .. tostring(value):gsub("'", [['\'']]) .. "'"
end

local function exports(env)
	local names = vim.tbl_keys(env or {})
	table.sort(names)
	local parts = {}
	for _, name in ipairs(names) do
		parts[#parts + 1] = "export " .. name .. "=" .. M.quote(env[name]) .. "; "
	end
	return table.concat(parts)
end

-- The wrapper prints the kernel pid, then blocks on stdin until the heartbeat
-- stops (ssh gone or Neovim closed the pipe) and kills the kernel.
function M.remote_command(entry, argv, remote_path)
	local parts = {}
	if entry.cwd then
		parts[#parts + 1] = "cd " .. M.quote(entry.cwd) .. " || exit 1; "
	end
	parts[#parts + 1] = exports(entry.env)
	parts[#parts + 1] = table.concat(vim.tbl_map(M.quote, argv), " ") .. " & pid=$!; "
	parts[#parts + 1] = "echo NVIM_KERNEL_PID=$pid; "
	parts[#parts + 1] = "while read -r -t " .. M.orphan_timeout .. " _; do :; done; "
	parts[#parts + 1] = "kill $pid; rm -f " .. M.quote(remote_path) .. "; echo NVIM_KERNEL_DONE"
	return table.concat(parts)
end

local ssh_options = { "BatchMode=yes", "ConnectTimeout=10" }

function M.ssh_command(host, ports, remote_command)
	local argv = { "ssh" }
	for _, option in ipairs(ssh_options) do
		vim.list_extend(argv, { "-o", option })
	end
	if ports then
		for _, option in ipairs({ "ServerAliveInterval=15", "ServerAliveCountMax=2", "ExitOnForwardFailure=yes" }) do
			vim.list_extend(argv, { "-o", option })
		end
		for _, port in ipairs(ports) do
			vim.list_extend(argv, { "-L", ("%d:127.0.0.1:%d"):format(port, port) })
		end
	end
	vim.list_extend(argv, { host, remote_command })
	return argv
end

function M.list_command(entry)
	return exports(entry.env)
		.. 'echo "NVIM_HOME=$HOME"; '
		.. M.quote(entry.jupyter or "jupyter")
		.. " kernelspec list --json"
end

-- Login banners may precede the marker, so locate it instead of assuming
-- line positions; the JSON starts at the first brace after it.
function M.split_listing(stdout)
	local home, rest = stdout:match("NVIM_HOME=([^\n]*)\n(.*)$")
	if not home then
		return nil, stdout
	end
	local brace = rest:find("{", 1, true)
	return home, brace and rest:sub(brace) or rest
end

-- Some hosts print banner lines on every connection; each host entry lists
-- substrings of the lines to drop from error messages in `ignore`.
function M.noise(line, ignore)
	for _, text in ipairs(ignore or {}) do
		if line:find(text, 1, true) then
			return true
		end
	end
	return false
end

function M.ready(buffer, chunk)
	buffer = buffer .. chunk
	local pid = buffer:match("NVIM_KERNEL_PID=(%d+)\n")
	return pid and tonumber(pid) or nil, buffer
end

function M.reduce_path(argv1, home)
	local path = argv1:match("^(.*)/bin/python[^/]*$") or argv1
	if home and home ~= "" and (path == home or path:sub(1, #home + 1) == home .. "/") then
		path = "~" .. path:sub(#home + 1)
	end
	return path
end

function M.choice(host, spec, home)
	return {
		name = "remote:" .. host .. "/" .. spec.name,
		label = spec.name .. " on " .. host,
		remote = { host = host, kernel = spec.name, path = M.reduce_path(spec.argv[1], home) },
	}
end

function M.choices(config, saved)
	local choices = {}
	if saved and saved.remote and saved.remote.kernel then
		choices[#choices + 1] = saved
	end
	local names = vim.tbl_keys(config or {})
	table.sort(names)
	for _, host in ipairs(names) do
		choices[#choices + 1] =
			{ name = "remote:" .. host, label = config[host].label or host, remote = { host = host } }
	end
	return choices
end

local function glyph()
	return vim.g.have_nerd_font == false and "(ssh)" or "󰒍"
end

function M.render(session, style)
	if style == "sentence" then
		return session.kernel .. " on " .. session.host
	end
	if style == "status" then
		return glyph() .. " " .. session.kernel .. "@" .. session.host
	end
	if not session.kernel then
		return glyph() .. " " .. (session.label or session.host)
	end
	local where = session.path and (session.host .. ":" .. session.path) or session.host
	return glyph() .. " " .. session.kernel .. " — " .. where
end

function M.display(names)
	local parts = {}
	for name in names:gmatch("%S+") do
		local session = M.paths[name]
		parts[#parts + 1] = session and M.render(session, "status") or name
	end
	return table.concat(parts, " ")
end

-- Sessions keyed by Molten's kernel id, which is the first connection file
-- attached; a restart swaps the session under the same id.
M.sessions = {}
local cache = {} -- host -> { specs = parsed kernelspecs, home = remote $HOME }
local counter = 0

local requests = {} -- buffer -> latest start request, so an older launch cannot win

function M.reset()
	M.sessions, M.paths, cache, counter, requests = {}, {}, {}, 0, {}
end

local function state_dir()
	return M.state_dir or (vim.fn.stdpath("state") .. "/notebook-remote")
end

local function run(host, ports, command, options, callback)
	local spawned, proc = pcall(vim.system, M.ssh_command(host, ports, command), options, callback)
	if not spawned then
		vim.schedule(function()
			callback({ code = -1, stderr = tostring(proc) })
		end)
		return nil
	end
	return proc
end

local function stderr_message(stderr, entry)
	local lines = {}
	for line in (stderr or ""):gmatch("[^\n]+") do
		if not M.noise(line, entry and entry.ignore) then
			lines[#lines + 1] = line
		end
	end
	return table.concat(lines, "\n")
end

local function new_timer()
	return (M.new_timer or vim.uv.new_timer)()
end

local frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

-- Show `message` with a spinner until the returned function is called with
-- the final text (or nothing to just dismiss it). Connections to a distant
-- host take seconds, and a silent wait looks like nothing happened.
local progress_count = 0

local function progress(message)
	progress_count = progress_count + 1
	local id, frame, timer = "notebook-remote-" .. progress_count, 0, new_timer()
	local function show()
		frame = frame + 1
		vim.notify(
			frames[(frame - 1) % #frames + 1] .. " " .. message,
			vim.log.levels.INFO,
			{ id = id, timeout = false }
		)
	end
	show()
	timer:start(100, 100, vim.schedule_wrap(show))
	return function(final, level)
		timer:stop()
		timer:close()
		if final then
			vim.notify(final, level or vim.log.levels.INFO, { id = id, timeout = 5000 })
		elseif package.loaded["snacks"] then
			require("snacks").notifier.hide(id)
		end
	end
end

function M.kernelspecs(host, callback)
	if cache[host] then
		callback(cache[host])
		return
	end
	local entry = hosts()[host] or {}
	local done = progress("Listing kernels on " .. host)
	run(host, nil, M.list_command(entry), { text = true, timeout = 60000 }, function(result)
		vim.schedule(function()
			local home, json = M.split_listing(result.stdout or "")
			local specs, err = require("config.kernelspecs").parse(json)
			if result.code ~= 0 or not specs then
				local detail = stderr_message(result.stderr, entry)
				if detail == "" then
					local head = vim.trim(result.stdout or ""):sub(1, 200)
					detail = err .. " (exit " .. tostring(result.code) .. ")" .. (head ~= "" and (": " .. head) or "")
				end
				done()
				callback(nil, "Could not list kernels on " .. host .. ": " .. detail)
				return
			end
			done()
			cache[host] = { specs = specs, home = home }
			callback(cache[host])
		end)
	end)
end

local function write_file(path, text)
	vim.fn.mkdir(vim.fs.dirname(path), "p")
	local fd, temp = assert(vim.uv.fs_mkstemp(path .. ".XXXXXX"))
	assert(vim.uv.fs_write(fd, text, 0))
	assert(vim.uv.fs_close(fd))
	assert(vim.uv.fs_rename(temp, path))
end

local function close_session(session)
	if session.timer then
		session.timer:stop()
		session.timer:close()
		session.timer = nil
	end
	M.paths[session.file] = nil
	vim.fn.delete(session.file)
end

-- Closing stdin tells the remote wrapper to kill the kernel; the ssh process
-- exits on its own after that, or is killed if it lingers.
function M.stop_session(session)
	close_session(session)
	if session.job and not session.exited then
		session.job:write(nil)
		vim.defer_fn(function()
			if not session.exited then
				session.job:kill(15)
			end
		end, 5000)
	end
end

function M.stop(kernel_id)
	local session = M.sessions[kernel_id]
	if session then
		M.sessions[kernel_id] = nil
		M.stop_session(session)
	end
end

local function spawn(host, kernel, listed, attempt, callback)
	local entry, spec = hosts()[host], listed.specs[kernel]
	counter = counter + 1
	local tag = kernel .. "-" .. vim.fn.getpid() .. "-" .. counter
	local session = {
		host = host,
		kernel = kernel,
		path = M.reduce_path(spec.argv[1], listed.home),
		ports = M.ports(),
		file = state_dir() .. "/" .. host .. "/" .. tag .. ".json",
		remote_path = listed.home .. "/.local/share/jupyter/runtime/nvim-" .. tag .. ".json",
	}
	local json = vim.json.encode(M.connection(session.ports, M.key(), kernel))
	write_file(session.file, json)
	local push = "mkdir -p "
		.. M.quote(vim.fs.dirname(session.remote_path))
		.. " && cat > "
		.. M.quote(session.remote_path)
	run(host, nil, push, { stdin = json, text = true, timeout = 30000 }, function(pushed)
		if pushed.code ~= 0 then
			vim.schedule(function()
				close_session(session)
				callback(
					nil,
					"Could not write the connection file on " .. host .. ": " .. stderr_message(pushed.stderr, entry)
				)
			end)
			return
		end
		local command = M.remote_command(entry, M.substitute(spec.argv, session.remote_path), session.remote_path)
		local buffer, stderr = "", {}
		session.job = run(host, session.ports, command, {
			stdin = true,
			text = true,
			stdout = function(_, chunk)
				if not chunk or session.pid then
					return
				end
				local pid
				pid, buffer = M.ready(buffer, chunk)
				if not pid then
					return
				end
				session.pid = pid
				vim.schedule(function()
					if session.exited then
						return
					end
					session.timer = new_timer()
					session.timer:start(M.heartbeat_interval * 1000, M.heartbeat_interval * 1000, function()
						session.job:write("\n")
					end)
					M.paths[session.file] = session
					callback(session)
				end)
			end,
			stderr = function(_, chunk)
				stderr[#stderr + 1] = chunk
			end,
		}, function(result)
			session.exited = true
			vim.schedule(function()
				local detail = stderr_message(table.concat(stderr), entry)
				if session.pid then
					if session.timer then
						vim.notify(
							"Remote kernel "
								.. M.render(session, "sentence")
								.. " disconnected"
								.. (detail ~= "" and (": " .. detail) or ""),
							vim.log.levels.WARN
						)
						close_session(session)
					end
					return
				end
				close_session(session)
				-- The wrapper never ran its own cleanup, so remove the pushed file.
				run(
					host,
					nil,
					"rm -f " .. M.quote(session.remote_path),
					{ text = true, timeout = 30000 },
					function() end
				)
				if attempt == 1 then
					spawn(host, kernel, listed, 2, callback)
				else
					callback(
						nil,
						"Could not start "
							.. M.render(session, "sentence")
							.. " (exit "
							.. result.code
							.. ")"
							.. (detail ~= "" and (": " .. detail) or "")
					)
				end
			end)
		end)
	end)
end

-- Start a kernel on `host`; `callback(session)` once it reports its pid, or
-- `callback(nil, message)` after the retry fails.
function M.launch(host, kernel, callback)
	M.kernelspecs(host, function(listed, err)
		if not listed then
			callback(nil, err)
		elseif not listed.specs[kernel] then
			callback(nil, "No kernel named " .. kernel .. " on " .. host)
		else
			spawn(host, kernel, listed, 1, callback)
		end
	end)
end

local function kernel_id(buf)
	if vim.fn.exists("*MoltenRunningKernels") == 0 or not vim.api.nvim_buf_is_valid(buf) then
		return nil
	end
	return vim.api.nvim_buf_call(buf, function()
		return vim.fn.MoltenRunningKernels(true)[1]
	end)
end

function M.session_for(buf)
	local id = kernel_id(buf)
	return id and M.sessions[id], id
end

local function pick_kernel(buf, host, attach)
	M.kernelspecs(host, function(listed, err)
		if not listed then
			vim.notify(err, vim.log.levels.ERROR)
			return
		end
		local names = vim.tbl_keys(listed.specs)
		table.sort(names)
		vim.ui.select(names, {
			prompt = "Select kernel on " .. host .. ":",
			format_item = function(name)
				return M.render(M.choice(host, listed.specs[name], listed.home).remote, "picker")
			end,
		}, function(name)
			if name then
				M.start(buf, M.choice(host, listed.specs[name], listed.home), attach)
			end
		end)
	end)
end

-- Start `choice.remote` for `buf`; `attach(file, choice)` connects Molten
-- to the connection file and returns whether it did. A host-only choice
-- first asks which of the host's kernels to run.
function M.start(buf, choice, attach)
	local target = choice.remote
	if not target.kernel then
		pick_kernel(buf, target.host, attach)
		return
	end
	requests[buf] = (requests[buf] or 0) + 1
	local request = requests[buf]
	local done = progress("Starting " .. M.render(target, "sentence"))
	M.launch(target.host, target.kernel, function(session, err)
		if not session then
			done(err, vim.log.levels.ERROR)
			return
		end
		done()
		if requests[buf] ~= request or not attach(session.file, choice) then
			M.stop_session(session)
			return
		end
		M.sessions[kernel_id(buf)] = session
	end)
end

function M.interrupt(buf)
	local session = M.session_for(buf)
	if not session then
		return false
	end
	run(session.host, nil, "kill -INT " .. session.pid, { text = true, timeout = 15000 }, function(result)
		if result.code ~= 0 then
			vim.schedule(function()
				vim.notify(
					"Could not interrupt "
						.. M.render(session, "sentence")
						.. ": "
						.. stderr_message(result.stderr, hosts()[session.host]),
					vim.log.levels.ERROR
				)
			end)
		end
	end)
	return true
end

function M.restart(buf)
	local old, id = M.session_for(buf)
	if not old then
		return false
	end
	local done = progress("Restarting " .. M.render(old, "sentence"))
	M.launch(old.host, old.kernel, function(fresh, err)
		if not fresh then
			done(err, vim.log.levels.ERROR)
			return
		end
		local switched = vim.api.nvim_buf_is_valid(buf)
			and vim.api.nvim_buf_call(buf, function()
				local ok, failure = pcall(vim.cmd.MoltenSwitchKernel, fresh.file)
				if not ok then
					vim.notify(tostring(failure), vim.log.levels.ERROR)
				end
				return ok and vim.fn.MoltenKernelName() == fresh.file
			end)
		if not switched then
			done()
			M.stop_session(fresh)
			return
		end
		M.sessions[id] = fresh
		M.stop_session(old)
		done("Restarted " .. M.render(fresh, "sentence"))
	end)
	return true
end

function M.setup()
	local group = vim.api.nvim_create_augroup("NotebookRemote", { clear = true })
	vim.api.nvim_create_autocmd("User", {
		group = group,
		pattern = "MoltenDeinitPost",
		callback = function(event)
			if event.data and event.data.kernel_id then
				M.stop(event.data.kernel_id)
			end
		end,
	})
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = group,
		callback = function()
			for id in pairs(M.sessions) do
				M.stop(id)
			end
		end,
	})
end

return M
