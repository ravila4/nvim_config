local remote = require("config.notebook_remote")

describe("Remote kernel connection file", function()
	it("builds a loopback connection table over the five ports", function()
		local connection = remote.connection({ 41001, 41002, 41003, 41004, 41005 }, ("ab"):rep(16), "venv")
		assert.same({
			shell_port = 41001,
			iopub_port = 41002,
			stdin_port = 41003,
			control_port = 41004,
			hb_port = 41005,
			ip = "127.0.0.1",
			transport = "tcp",
			signature_scheme = "hmac-sha256",
			key = ("ab"):rep(16),
			kernel_name = "venv",
		}, connection)
	end)
	it("picks five distinct ports in the forwarding range", function()
		for _ = 1, 50 do
			local ports = remote.ports()
			assert.equals(5, #ports)
			local seen = {}
			for _, port in ipairs(ports) do
				assert.is_true(port >= 41000 and port <= 49000, tostring(port))
				assert.is_nil(seen[port], "duplicate port " .. port)
				seen[port] = true
			end
		end
	end)
	it("generates a 32 character hex key", function()
		local key = remote.key()
		assert.matches("^%x+$", key)
		assert.equals(32, #key)
		assert.are_not.equal(key, remote.key())
	end)
end)

describe("Remote kernel command assembly", function()
	it("substitutes the connection file placeholder in every argv element", function()
		assert.same(
			{ "/env/bin/python", "-f", "/run/k.json", "--x=/run/k.json" },
			remote.substitute({ "/env/bin/python", "-f", "{connection_file}", "--x={connection_file}" }, "/run/k.json")
		)
	end)
	it("single-quotes values for the remote shell", function()
		assert.equals("'plain'", remote.quote("plain"))
		assert.equals([['it'\''s"$HOME"']], remote.quote([[it's"$HOME"]]))
	end)
	it("wraps the kernel so it dies when the heartbeat stops", function()
		local command = remote.remote_command(
			{ cwd = "/home/j/repo", env = { JUPYTER_CONFIG_DIR = "/tmp/empty", B = "x y" } },
			{ "/env/bin/python", "-m", "ipykernel_launcher", "-f", "/run/k.json" },
			"/run/k.json"
		)
		local expected = {
			"cd '/home/j/repo' && ",
			"export B='x y'; export JUPYTER_CONFIG_DIR='/tmp/empty'; ",
			"'/env/bin/python' '-m' 'ipykernel_launcher' '-f' '/run/k.json' & pid=$!; ",
			"echo NVIM_KERNEL_PID=$pid; ",
			"while read -r -t 90 _; do :; done; ",
			"kill $pid; rm -f '/run/k.json'; echo NVIM_KERNEL_DONE",
		}
		assert.equals(table.concat(expected), command)
	end)
	it("runs in the login directory when no cwd is configured", function()
		local command = remote.remote_command({}, { "/bin/R" }, "/run/k.json")
		assert.is_nil(command:find("cd ", 1, true))
		assert.is_nil(command:find("export", 1, true))
		assert.matches("^'/bin/R' & pid=%$!;", command)
	end)
	it("forwards the five ports on one non-interactive ssh", function()
		local argv = remote.ssh_command("host", { 1, 2, 3, 4, 5 }, "true")
		assert.equals("ssh", argv[1])
		assert.equals("host", argv[#argv - 1])
		assert.equals("true", argv[#argv])
		local options, forwards = {}, {}
		for index, value in ipairs(argv) do
			if value == "-o" then
				options[#options + 1] = argv[index + 1]
			elseif value == "-L" then
				forwards[#forwards + 1] = argv[index + 1]
			end
		end
		assert.same({
			"BatchMode=yes",
			"ConnectTimeout=10",
			"ServerAliveInterval=15",
			"ServerAliveCountMax=2",
			"ExitOnForwardFailure=yes",
		}, options)
		assert.same({ "1:127.0.0.1:1", "2:127.0.0.1:2", "3:127.0.0.1:3", "4:127.0.0.1:4", "5:127.0.0.1:5" }, forwards)
	end)
	it("builds the listing command with the configured jupyter and environment", function()
		local command = remote.list_command({ jupyter = "/opt/j/bin/jupyter", env = { JUPYTER_CONFIG_DIR = "/tmp/e" } })
		assert.equals(
			"export JUPYTER_CONFIG_DIR='/tmp/e'; echo \"NVIM_HOME=$HOME\"; '/opt/j/bin/jupyter' kernelspec list --json",
			command
		)
		assert.equals("echo \"NVIM_HOME=$HOME\"; 'jupyter' kernelspec list --json", remote.list_command({}))
	end)
	it("finds the home marker and the JSON despite banner lines", function()
		local home, json = remote.split_listing('\nWelcome\nNVIM_HOME=/home/j\nnoise\n{\n "kernelspecs": {}\n}\n')
		assert.equals("/home/j", home)
		assert.equals('{\n "kernelspecs": {}\n}\n', json)
		assert.is_nil((remote.split_listing("no marker\n")))
	end)
end)

describe("Remote kernel output parsing", function()
	it("ignores the host's banner lines", function()
		local ignore = { "scheduled maintenance", "license expires" }
		assert.is_true(remote.noise("2026/09/18 22:12:56 Notice: scheduled maintenance on Sunday", ignore))
		assert.is_true(remote.noise("Your license expires in 3 days", ignore))
		assert.is_false(remote.noise("bash: /env/bin/python: No such file or directory", ignore))
		assert.is_false(remote.noise("Your license expires in 3 days"))
	end)
	it("reports the kernel pid once its line has fully arrived", function()
		local pid, buffer = remote.ready("", "NVIM_KERNEL_P")
		assert.is_nil(pid)
		pid, buffer = remote.ready(buffer, "ID=42")
		assert.is_nil(pid)
		pid = remote.ready(buffer, "\nmore")
		assert.equals(42, pid)
	end)
	it("finds the pid after banner lines", function()
		assert.equals(7, (remote.ready("", "Notice: scheduled maintenance\nNVIM_KERNEL_PID=7\n")))
	end)
end)

describe("Remote kernel picker entries", function()
	local config = {
		beta = { label = "Beta VM" },
		alpha = {},
	}
	it("lists the remembered pair first, then one entry per host", function()
		local saved = {
			name = "remote:beta/venv",
			label = "venv on beta",
			remote = { host = "beta", kernel = "venv", path = "~/repo/.venv" },
		}
		local choices = remote.choices(config, saved)
		assert.same(
			{ "remote:beta/venv", "remote:alpha", "remote:beta" },
			vim.tbl_map(function(c)
				return c.name
			end, choices)
		)
		assert.same(saved, choices[1])
		assert.same({ name = "remote:alpha", label = "alpha", remote = { host = "alpha" } }, choices[2])
		assert.same({ name = "remote:beta", label = "Beta VM", remote = { host = "beta" } }, choices[3])
	end)
	it("lists only hosts without a remembered remote kernel", function()
		assert.equals(2, #remote.choices(config, { name = "nvim-default" }))
		assert.equals(2, #remote.choices(config, nil))
		assert.same({}, remote.choices(nil, nil))
	end)
	it("shapes the choice saved for a picked kernel", function()
		local choice = remote.choice(
			"beta",
			{ name = "venv", label = "Venv", argv = { "/home/j/repo/.venv/bin/python3" } },
			"/home/j"
		)
		assert.same({
			name = "remote:beta/venv",
			label = "venv on beta",
			remote = { host = "beta", kernel = "venv", path = "~/repo/.venv" },
		}, choice)
	end)
end)

describe("Remote kernel display", function()
	local nerd
	before_each(function()
		nerd = vim.g.have_nerd_font
		vim.g.have_nerd_font = false
	end)
	after_each(function()
		vim.g.have_nerd_font = nerd
	end)
	it("reduces the kernel path like the local picker, relative to the remote home", function()
		assert.equals("~/repo/.venv", remote.reduce_path("/home/j/repo/.venv/bin/python3", "/home/j"))
		assert.equals("/opt/conda/envs/x", remote.reduce_path("/opt/conda/envs/x/bin/python", "/home/j"))
		assert.equals("/bin/bash", remote.reduce_path("/bin/bash", "/home/j"))
		assert.equals("/home/jane/x", remote.reduce_path("/home/jane/x", "/home/j"))
	end)
	it("renders each surface from one session", function()
		local session = { host = "beta", kernel = "venv", path = "~/repo/.venv" }
		assert.equals("(ssh) venv — beta:~/repo/.venv", remote.render(session, "picker"))
		assert.equals("(ssh) venv@beta", remote.render(session, "status"))
		assert.equals("venv on beta", remote.render(session, "sentence"))
		assert.equals("(ssh) Beta VM", remote.render({ host = "beta", label = "Beta VM" }, "picker"))
	end)
	it("uses a glyph when a Nerd Font is available", function()
		vim.g.have_nerd_font = nil
		local rendered = remote.render({ host = "beta", kernel = "venv" }, "status")
		assert.is_nil(rendered:find("(ssh)", 1, true))
		assert.matches(" venv@beta$", rendered)
	end)
	it("maps remote connection files in the status string and leaves local names alone", function()
		remote.paths["/state/beta/venv-1.json"] = { host = "beta", kernel = "venv" }
		assert.equals("nvim-default (ssh) venv@beta", remote.display("nvim-default /state/beta/venv-1.json"))
		assert.equals("", remote.display(""))
		remote.paths["/state/beta/venv-1.json"] = nil
	end)
end)

describe("Remote kernel sessions", function()
	local kernels = require("config.notebook_kernels")
	local system, notify, select, temp, buf, previous, procs, messages, timers, listing

	local function proc_for(pattern)
		for _, proc in ipairs(procs) do
			if proc.argv[#proc.argv]:find(pattern, 1, true) then
				return proc
			end
		end
	end
	local function launches()
		local found = {}
		for _, proc in ipairs(procs) do
			if proc.argv[#proc.argv]:find("NVIM_KERNEL_PID", 1, true) then
				found[#found + 1] = proc
			end
		end
		return found
	end
	local function forwarded(proc)
		local ports = {}
		for index, value in ipairs(proc.argv) do
			if value == "-L" then
				ports[#ports + 1] = tonumber(proc.argv[index + 1]:match("^(%d+):"))
			end
		end
		return ports
	end
	local function exit(proc, code, stderr)
		proc.opts.stderr(nil, stderr)
		proc.on_exit({ code = code })
	end
	local function ready(proc, pid)
		proc.opts.stdout(nil, "Notice: scheduled maintenance\nNVIM_KERNEL_PID=" .. pid .. "\n")
		vim.wait(500, function()
			return #vim.g.kernel_calls > 0
		end)
	end
	local function start(persist)
		kernels.start(buf, {
			name = "remote:beta/venv",
			label = "venv on beta",
			remote = { host = "beta", kernel = "venv", path = "~/repo/.venv" },
		}, persist or false, false)
		vim.wait(500, function()
			return #launches() > 0
		end)
	end

	before_each(function()
		system, notify, select = vim.system, vim.notify, vim.ui.select
		procs, messages, timers = {}, {}, {}
		temp = vim.fn.tempname()
		vim.fn.mkdir(temp, "p")
		previous = vim.api.nvim_get_current_buf()
		buf = vim.api.nvim_create_buf(true, false)
		vim.api.nvim_buf_set_name(buf, temp .. "/a.ipynb")
		vim.api.nvim_set_current_buf(buf)
		vim.g.notebook_remotes = {
			beta = {
				cwd = "/home/j/repo",
				jupyter = "/opt/j/bin/jupyter",
				env = { JUPYTER_CONFIG_DIR = "/tmp/e" },
				ignore = { "scheduled maintenance" },
			},
		}
		vim.g.kernel_calls, vim.g.test_running_kernels, vim.g.test_kernel_name = {}, {}, ""
		listing = "\nNVIM_HOME=/home/j\n"
			.. vim.json.encode({
				kernelspecs = {
					venv = {
						spec = {
							display_name = "Venv",
							argv = {
								"/home/j/repo/.venv/bin/python",
								"-m",
								"ipykernel_launcher",
								"-f",
								"{connection_file}",
							},
						},
					},
				},
			})
		vim.system = function(argv, opts, on_exit)
			local proc = { argv = argv, opts = opts or {}, on_exit = on_exit, written = {}, closed = false }
			function proc:write(data)
				if data == nil then
					self.closed = true
				else
					self.written[#self.written + 1] = data
				end
			end
			function proc:kill(signal)
				self.killed = signal
			end
			procs[#procs + 1] = proc
			local command = argv[#argv]
			if command:find("kernelspec list", 1, true) then
				on_exit({ code = 0, stdout = listing, stderr = "Notice: scheduled maintenance\n" })
			elseif command:find("cat >", 1, true) or command:find("kill -INT", 1, true) then
				on_exit({ code = 0, stdout = "", stderr = "" })
			end
			return proc
		end
		vim.notify = function(message, level)
			messages[#messages + 1] = { message = message, level = level }
		end
		remote.new_timer = function()
			local timer = { stopped = false }
			function timer:start(_, _, callback)
				self.callback = callback
			end
			function timer:stop()
				self.stopped = true
			end
			function timer:close() end
			timers[#timers + 1] = timer
			return timer
		end
		remote.state_dir = temp .. "/state"
		remote.reset()
		remote.setup()
		vim.cmd([[
function! MoltenRunningKernels(...) abort
  return g:test_running_kernels
endfunction
function! MoltenKernelName(...) abort
  return g:test_kernel_name
endfunction
command! -nargs=1 MoltenInit call add(g:kernel_calls, ['init', <q-args>]) | let g:test_kernel_name = <q-args> | let g:test_running_kernels = [<q-args>]
command! -nargs=1 MoltenSwitchKernel call add(g:kernel_calls, ['switch', <q-args>]) | let g:test_kernel_name = <q-args>
command! MoltenImportOutput call add(g:kernel_calls, ['import'])
]])
	end)
	after_each(function()
		vim.system, vim.notify, vim.ui.select = system, notify, select
		remote.new_timer = nil
		remote.state_dir = nil
		remote.reset()
		vim.g.notebook_remotes = nil
		vim.api.nvim_set_current_buf(previous)
		vim.api.nvim_buf_delete(buf, { force = true })
		vim.fn.delete(temp, "rf")
	end)

	it("lists kernels, pushes the connection file, and attaches once the kernel reports", function()
		start(true)
		local push = assert(proc_for("cat >"), "connection file was not pushed")
		local remote_path = push.argv[#push.argv]:match("cat > '([^']+)'")
		assert.equals("/home/j/.local/share/jupyter/runtime/nvim-venv-" .. vim.fn.getpid() .. "-1.json", remote_path)
		local pushed = vim.json.decode(push.opts.stdin)
		local launch = launches()[1]
		local ports = forwarded(launch)
		assert.same(
			ports,
			{ pushed.shell_port, pushed.iopub_port, pushed.stdin_port, pushed.control_port, pushed.hb_port }
		)
		local command = launch.argv[#launch.argv]
		assert.is_truthy(command:find("cd '/home/j/repo' && export JUPYTER_CONFIG_DIR='/tmp/e'; ", 1, true))
		assert.is_truthy(
			command:find(
				"'/home/j/repo/.venv/bin/python' '-m' 'ipykernel_launcher' '-f' '" .. remote_path .. "' & pid=$!",
				1,
				true
			)
		)
		assert.is_true(launch.opts.stdin)
		assert.same({}, vim.g.kernel_calls)

		ready(launch, 55)
		local path = temp .. "/state/beta/venv-" .. vim.fn.getpid() .. "-1.json"
		assert.same({ { "init", path } }, vim.g.kernel_calls)
		assert.same(pushed, vim.json.decode(table.concat(vim.fn.readfile(path), "\n")))
		local session = remote.sessions[path]
		assert.equals(55, session.pid)
		assert.equals("beta", session.host)
		assert.equals("~/repo/.venv", session.path)
		assert.equals(path, session.file)
		assert.equals(session, remote.paths[path])
		assert.equals("remote:beta/venv", kernels.load_choice(vim.api.nvim_buf_get_name(buf)).name)
		timers[#timers].callback()
		assert.same({ "\n" }, launch.written)
		assert.is_truthy(vim.iter(messages):any(function(m)
			return m.message:find("Starting venv on beta", 1, true) ~= nil
		end))
	end)

	it("retries once with fresh ports when ssh exits before the kernel reports", function()
		start()
		local first = launches()[1]
		exit(first, 255, "Notice: scheduled maintenance\nbind: Address already in use\n")
		vim.wait(500, function()
			return #launches() == 2
		end)
		local second = launches()[2]
		assert.are_not.same(forwarded(first), forwarded(second))
		assert.equals(2, #(vim.tbl_filter(function(p)
			return p.argv[#p.argv]:find("cat >", 1, true)
		end, procs)))
		exit(second, 255, "Notice: scheduled maintenance\nbind: Address already in use\n")
		vim.wait(500, function()
			return messages[#messages].level == vim.log.levels.ERROR
		end)
		assert.same({}, vim.g.kernel_calls)
		assert.equals(vim.log.levels.ERROR, messages[#messages].level)
		assert.is_truthy(messages[#messages].message:find("Address already in use", 1, true))
		assert.is_nil(messages[#messages].message:find("maintenance", 1, true))
		assert.same({}, remote.sessions)
		assert.same({}, vim.fn.glob(temp .. "/state/beta/*.json", false, true))
	end)

	it("stops the session when Molten deinitializes the kernel", function()
		start()
		local launch = launches()[1]
		ready(launch, 55)
		local path = vim.g.kernel_calls[1][2]
		vim.api.nvim_exec_autocmds("User", { pattern = "MoltenDeinitPost", data = { kernel_id = path } })
		assert.is_true(launch.closed)
		assert.is_true(timers[#timers].stopped)
		assert.is_nil(launch.killed)
		assert.same({}, remote.sessions)
		assert.same({}, remote.paths)
		assert.equals(0, vim.fn.filereadable(path))
	end)

	it("interrupts by signalling the remote kernel pid", function()
		start()
		ready(launches()[1], 55)
		assert.is_true(remote.interrupt(buf))
		local kill = assert(proc_for("kill -INT 55"))
		assert.equals("beta", kill.argv[#kill.argv - 1])
	end)

	it("does not claim interrupts for buffers without a remote kernel", function()
		vim.g.test_running_kernels = { "nvim-default" }
		assert.is_false(remote.interrupt(buf))
		assert.same({}, procs)
	end)

	it("restarts by switching Molten to a fresh session and stopping the old one", function()
		start()
		local old = launches()[1]
		ready(old, 55)
		local path = vim.g.kernel_calls[1][2]
		assert.is_true(remote.restart(buf))
		vim.wait(500, function()
			return #launches() == 2
		end)
		local fresh = launches()[2]
		assert.are_not.same(forwarded(old), forwarded(fresh))
		fresh.opts.stdout(nil, "NVIM_KERNEL_PID=77\n")
		vim.wait(500, function()
			return #vim.g.kernel_calls == 2
		end)
		local new_path = vim.g.kernel_calls[2][2]
		assert.equals("switch", vim.g.kernel_calls[2][1])
		assert.are_not.equal(path, new_path)
		assert.is_true(old.closed)
		assert.is_false(fresh.closed)
		assert.equals(77, remote.sessions[path].pid)
		assert.is_nil(remote.paths[path])
		assert.equals(77, remote.paths[new_path].pid)
		assert.equals(1, #(vim.tbl_filter(function(p)
			return p.argv[#p.argv]:find("kernelspec list", 1, true)
		end, procs)))
	end)

	it("warns when a session drops after it was attached", function()
		start()
		local launch = launches()[1]
		ready(launch, 55)
		exit(launch, 255, "Connection closed by remote host\n")
		vim.wait(500, function()
			return messages[#messages].level == vim.log.levels.WARN
		end)
		assert.equals(vim.log.levels.WARN, messages[#messages].level)
		assert.is_truthy(messages[#messages].message:find("venv on beta", 1, true))
		assert.is_true(timers[#timers].stopped)
	end)

	it("routes the kernel menu's interrupt and restart to the session", function()
		start()
		ready(launches()[1], 55)
		vim.api.nvim_create_user_command("MoltenInterrupt", function()
			error("local interrupt reached")
		end, { force = true })
		vim.api.nvim_create_user_command("MoltenRestart", function()
			error("local restart reached")
		end, { force = true })
		local items = {}
		for _, item in ipairs(require("config.notebook_kernel_menu").items(vim.api.nvim_get_current_win(), buf)) do
			items[item.name] = item.cmd
		end
		items["Interrupt Kernel"]()
		assert.is_truthy(proc_for("kill -INT 55"))
		items["Restart Kernel"]()
		vim.wait(500, function()
			return #launches() == 2
		end)
		assert.equals(2, #launches())
		vim.api.nvim_del_user_command("MoltenInterrupt")
		vim.api.nvim_del_user_command("MoltenRestart")
	end)

	it("offers the host's kernels when a host entry is chosen", function()
		local nerd = vim.g.have_nerd_font
		vim.g.have_nerd_font = false
		local shown
		vim.ui.select = function(items, opts, callback)
			shown = vim.tbl_map(opts.format_item, items)
			callback(items[1])
		end
		kernels.start(buf, { name = "remote:beta", label = "beta", remote = { host = "beta" } }, true, false)
		vim.wait(500, function()
			return #launches() > 0
		end)
		vim.g.have_nerd_font = nerd
		assert.same({ "(ssh) venv — beta:~/repo/.venv" }, shown)
		ready(launches()[1], 5)
		local saved = kernels.load_choice(vim.api.nvim_buf_get_name(buf))
		assert.same({ host = "beta", kernel = "venv", path = "~/repo/.venv" }, saved.remote)
	end)
end)
