-- Inline LLM code editing and questions: select code, type instruction or question
-- Uses Snacks.input() for prompt, mini.diff for inline overlay, XML-structured responses

return {
  {
    "echasnovski/mini.diff",
    lazy = false,
    config = function()
      require("mini.diff").setup({
        source = require("mini.diff").gen_source.none(),
      })

      -- Quick Edit: inline LLM code editing and questions
      -- Default provider/model (change these to taste)
      local M = {
        provider = "lmstudio", -- "claude" or "lmstudio"
        claude_model = "haiku",
        lmstudio_model = "qwen2.5-coder-3b-instruct",
      }

      function M.select_model()
        -- Claude models are static
        local items = {}
        for _, m in ipairs({ "haiku", "sonnet", "opus" }) do
          table.insert(items, { label = "claude:" .. m, provider = "claude", model = m })
        end

        -- Query LM Studio asynchronously (/v1/models returns one JSON blob)
        local raw = {}
        vim.fn.jobstart({ "curl", "-s", "--max-time", "3", "http://localhost:1234/v1/models" }, {
          stdout_buffered = true,
          on_stdout = function(_, data)
            if data then
              vim.list_extend(raw, data)
            end
          end,
          on_exit = function(_, code)
            vim.schedule(function()
              if code == 0 then
                local ok, parsed = pcall(vim.fn.json_decode, table.concat(raw, "\n"))
                if ok and type(parsed) == "table" and type(parsed.data) == "table" then
                  for _, m in ipairs(parsed.data) do
                    if type(m.id) == "string" and not m.id:match("^text%-embedding") then
                      table.insert(items, { label = "lmstudio:" .. m.id, provider = "lmstudio", model = m.id })
                    end
                  end
                end
              else
                vim.notify("[Quick Edit] LM Studio not reachable; claude-only selector", vim.log.levels.WARN)
              end
              vim.ui.select(items, {
                prompt = "Quick Edit Model:",
                format_item = function(item)
                  local current = (item.provider == M.provider)
                    and (
                      (item.provider == "claude" and item.model == M.claude_model)
                      or (item.provider == "lmstudio" and item.model == M.lmstudio_model)
                    )
                  return (current and "* " or "  ") .. item.label
                end,
              }, function(choice)
                if not choice then
                  return
                end
                M.provider = choice.provider
                if choice.provider == "claude" then
                  M.claude_model = choice.model
                else
                  M.lmstudio_model = choice.model
                end
                vim.notify("[Quick Edit] Using " .. choice.label)
              end)
            end)
          end,
        })
      end

      vim.api.nvim_create_user_command("QuickEditModel", function()
        M.select_model()
      end, {})

      local edit_system_prompt = [[You are a code assistant. You receive a code snippet and an instruction.

Respond with:

<code>
[the complete modified code — raw code only, no markdown fences]
</code>
<summary>
[one-line description of changes]
</summary>]]

      local ask_system_prompt = [[You are a code assistant. You receive a code snippet and a question.

Respond in markdown. Be concise but thorough.
- Break it down step by step
- Use ASCII diagrams to illustrate data flow or logic where helpful
- Show example inputs and outputs when relevant]]

      -- Shorthands that should use ask mode (no code editing context)
      local ask_shorthands = { ["/explain"] = true, ["/review"] = true }

      -- Shorthand expansions
      local shorthands = {
        ["/explain"] = "Explain what this code does, step by step.",
        ["/simplify"] = "Simplify this code while preserving behavior.",
        ["/docstring"] = "Add a docstring to this function.",
        ["/types"] = "Add type annotations.",
        ["/review"] = "Review this code for bugs, edge cases, and improvements.",
        ["/test"] = "Write unit tests for this code.",
      }

      local function expand_instruction(instruction, buf, start_line, end_line)
        local cmd = instruction:match("^(/[%w_]+)")
        if cmd == "/fix" then
          local all_diags = vim.diagnostic.get(buf)
          local diags = {}
          for _, d in ipairs(all_diags) do
            if d.lnum >= start_line - 1 and d.lnum <= end_line - 1 then
              table.insert(diags, d)
            end
          end
          if #diags == 0 then
            diags = all_diags
          end
          local msgs = {}
          for _, d in ipairs(diags) do
            local severity = vim.diagnostic.severity[d.severity] or "UNKNOWN"
            local src = d.source and ("[" .. d.source .. "] ") or ""
            table.insert(msgs, string.format("- %s%s: %s (line %d)", src, severity, d.message, d.lnum + 1))
          end
          if #msgs == 0 then
            return "Review this code for potential issues and fix any problems."
          end
          local extra = instruction:sub(#cmd + 1):gsub("^%s+", "")
          local base = "Fix the following diagnostics:\n" .. table.concat(msgs, "\n")
          if extra ~= "" then
            base = base .. "\n\nAdditional context: " .. extra
          end
          return base
        end
        if cmd and shorthands[cmd] then
          local extra = instruction:sub(#cmd + 1):gsub("^%s+", "")
          if extra ~= "" then
            return shorthands[cmd] .. " " .. extra
          end
          return shorthands[cmd]
        end
        return instruction
      end

      local function parse_response(response)
        -- Check for question/explanation response first
        local text_response = response:match("<response>(.-)</response>")
        if text_response then
          text_response = text_response:gsub("^%s+", ""):gsub("%s+$", "")
          return { mode = "ask", text = text_response }
        end

        -- Check for code edit
        local code = response:match("<code>(.-)</code>")
        local summary = response:match("<summary>(.-)</summary>")

        if not code then
          code = response:match("```%w*\n(.-)\n```")
        end

        if code then
          -- Strip fenced code blocks that LLMs sometimes nest inside <code> tags
          local inner = code:match("```%w*\n(.-)\n```")
          if inner then
            code = inner
          end
          code = code:gsub("^%s*\n", ""):gsub("\n%s*$", "")
          if summary then
            summary = summary:gsub("^%s+", ""):gsub("%s+$", "")
          end
          return { mode = "edit", code = code, summary = summary or "Changes applied" }
        end

        -- No structured format: treat as a text response
        return { mode = "ask", text = response }
      end

      local function show_floating_response(text)
        local lines = vim.split(text, "\n")
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        vim.bo[buf].buftype = "nofile"
        vim.bo[buf].bufhidden = "wipe"
        vim.bo[buf].filetype = "markdown"
        vim.bo[buf].modifiable = false
        vim.diagnostic.enable(false, { bufnr = buf })

        local width = math.min(120, math.floor(vim.o.columns * 0.8))
        -- Estimate wrapped line count: each line may wrap across multiple rows
        local wrapped = 0
        for _, l in ipairs(lines) do
          wrapped = wrapped + math.max(1, math.ceil(#l / width))
        end
        local height = math.min(math.max(wrapped + 2, 15), math.floor(vim.o.lines * 0.8))

        local win = vim.api.nvim_open_win(buf, true, {
          relative = "editor",
          row = math.floor((vim.o.lines - height) / 2),
          col = math.floor((vim.o.columns - width) / 2),
          width = width,
          height = height,
          style = "minimal",
          border = "rounded",
          title = " LLM ",
          title_pos = "center",
        })

        vim.wo[win].wrap = true
        vim.wo[win].linebreak = true

        vim.keymap.set("n", "q", function()
          vim.api.nvim_win_close(win, true)
        end, { buffer = buf, nowait = true })
        vim.keymap.set("n", "<Esc>", function()
          vim.api.nvim_win_close(win, true)
        end, { buffer = buf, nowait = true })
      end

      -- Track active quickedit state per buffer
      local active_edits = {}

      local function cleanup_edit(buf)
        local state = active_edits[buf]
        if not state then
          return
        end
        active_edits[buf] = nil

        pcall(vim.keymap.del, "n", "<CR>", { buffer = buf })
        pcall(vim.keymap.del, "n", "<Esc>", { buffer = buf })
        pcall(vim.keymap.del, "n", "<Tab>", { buffer = buf })

        pcall(function()
          require("mini.diff").set_ref_text(buf, {})
        end)
      end

      local function accept(buf)
        cleanup_edit(buf)
        vim.notify("[Quick Edit] Accepted")
      end

      local function reject(buf)
        local state = active_edits[buf]
        if not state then
          return
        end
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, state.snapshot)
        cleanup_edit(buf)
        vim.notify("[Quick Edit] Rejected")
      end

      local function apply_inline_diff(new_code, buf, start_line, end_line)
        local snapshot = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

        local new_lines = vim.split(new_code, "\n")
        vim.api.nvim_buf_set_lines(buf, start_line - 1, end_line, false, new_lines)

        require("mini.diff").set_ref_text(buf, snapshot)

        pcall(function()
          require("mini.diff").toggle_overlay(buf)
        end)

        active_edits[buf] = { snapshot = snapshot }

        pcall(vim.api.nvim_win_set_cursor, 0, { start_line, 0 })
        vim.cmd("normal! zz")

        vim.keymap.set("n", "<CR>", function()
          accept(buf)
        end, { buffer = buf, nowait = true, desc = "Accept quick edit" })

        vim.keymap.set("n", "<Esc>", function()
          reject(buf)
        end, { buffer = buf, nowait = true, desc = "Reject quick edit" })

        vim.keymap.set("n", "<Tab>", function()
          require("mini.diff").toggle_overlay(buf)
        end, { buffer = buf, nowait = true, desc = "Toggle diff overlay" })

        vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
          buffer = buf,
          once = true,
          callback = function()
            cleanup_edit(buf)
          end,
        })

        vim.notify("[Quick Edit] <CR> accept | <Esc> reject | <Tab> toggle overlay")
      end

      -- nvim_create_namespace is idempotent: returns same ID for same name
      local ns = vim.api.nvim_create_namespace("quickedit_highlight")

      function M.quickedit()
        local s = vim.fn.getpos("v")[2]
        local e = vim.fn.getpos(".")[2]
        local start_line = math.min(s, e)
        local end_line = math.max(s, e)
        local buf = vim.api.nvim_get_current_buf()

        -- Clean up any active edit on this buffer before starting a new one
        if active_edits[buf] then
          reject(buf)
        end

        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)

        for i = start_line - 1, end_line - 1 do
          vim.api.nvim_buf_add_highlight(buf, ns, "Visual", i, 0, -1)
        end

        local lines = vim.api.nvim_buf_get_lines(buf, start_line - 1, end_line, false)
        local sel_text = table.concat(lines, "\n")
        local filepath = vim.fn.expand("%:p")
        local rel_path = vim.fn.fnamemodify(filepath, ":.")

        -- Build sorted shorthand list for completion
        local shorthand_keys = { "/fix" }
        for k in pairs(shorthands) do
          table.insert(shorthand_keys, k)
        end
        table.sort(shorthand_keys)

        Snacks.input({
          prompt = " Quick Edit: ",
          win = {
            relative = "cursor",
            row = -3,
          },
        }, function(instruction)
          if not instruction or instruction == "" then
            vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
            return
          end

          local instruction_raw = instruction
          instruction = expand_instruction(instruction, buf, start_line, end_line)

          -- Pick system prompt based on whether this is an ask or edit command
          local raw_cmd = instruction_raw:match("^(/[%w_]+)")
          local is_ask = raw_cmd and ask_shorthands[raw_cmd]
          local sys_prompt = is_ask and ask_system_prompt or edit_system_prompt

          local prompt = string.format(
            "%s\n\nFile: %s\nLines %d-%d:\n```\n%s\n```\n\n%s: %s",
            sys_prompt,
            rel_path,
            start_line,
            end_line,
            sel_text,
            is_ask and "Question" or "Instruction",
            instruction
          )

          local cmd
          local stdin_data = nil
          if M.provider == "claude" then
            cmd = { "claude", "-p", prompt, "--model", M.claude_model }
          else
            stdin_data = vim.fn.json_encode({
              model = M.lmstudio_model,
              messages = { { role = "user", content = prompt } },
              stream = false,
              max_tokens = 4096,
            })
            cmd = {
              "curl", "-s", "--max-time", "120",
              "-H", "Content-Type: application/json",
              "-X", "POST",
              "http://localhost:1234/v1/chat/completions",
              "-d", "@-",
            }
          end

          vim.notify("[Quick Edit] Waiting for " .. M.provider .. "...")

          -- Snapshot at dispatch time: user may switch providers while request is in-flight
          local provider_snapshot = M.provider

          local stdout = {}
          local stderr = {}
          local job_id = vim.fn.jobstart(cmd, {
            stdout_buffered = true,
            stderr_buffered = true,
            on_stdout = function(_, data)
              if data then
                vim.list_extend(stdout, data)
              end
            end,
            on_stderr = function(_, data)
              if data then
                vim.list_extend(stderr, data)
              end
            end,
            on_exit = function(_, exit_code)
              vim.schedule(function()
                vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

                if exit_code ~= 0 then
                  local err_msg = table.concat(stderr, "\n")
                  vim.notify("[Quick Edit] Failed (exit " .. exit_code .. "): " .. err_msg, vim.log.levels.ERROR)
                  return
                end

                if not vim.api.nvim_buf_is_valid(buf) then
                  vim.notify("[Quick Edit] Buffer no longer valid", vim.log.levels.ERROR)
                  return
                end

                local raw = table.concat(stdout, "\n")
                local response
                local degraded_to_ask = false
                if provider_snapshot == "lmstudio" then
                  local ok, parsed = pcall(vim.fn.json_decode, raw)
                  if not ok or type(parsed) ~= "table" or not parsed.choices or not parsed.choices[1] then
                    vim.notify("[Quick Edit] Invalid JSON: " .. raw:sub(1, 200), vim.log.levels.ERROR)
                    return
                  end
                  local msg = parsed.choices[1].message or {}
                  response = msg.content or ""
                  if response == "" and msg.reasoning_content and msg.reasoning_content ~= "" then
                    response = msg.reasoning_content
                    degraded_to_ask = not is_ask
                    local extra = degraded_to_ask and " (edit → ask)" or ""
                    vim.notify("[Quick Edit] Empty content; showing reasoning_content" .. extra, vim.log.levels.WARN)
                  end
                  if response == "" then
                    vim.notify(
                      "[Quick Edit] Empty response (finish=" .. (parsed.choices[1].finish_reason or "?") .. ")",
                      vim.log.levels.ERROR
                    )
                    return
                  end
                else
                  response = raw
                end
                local route_ask = is_ask or degraded_to_ask
                local result = route_ask and { mode = "ask", text = response } or parse_response(response)

                if result.mode == "ask" then
                  show_floating_response(result.text)
                else
                  apply_inline_diff(result.code, buf, start_line, end_line)
                  Snacks.notify(result.summary or "Done", { title = "Quick Edit", timeout = 5000 })
                end
              end)
            end,
          })

          -- Write JSON body to curl's stdin (-d @-), then close
          if job_id > 0 and stdin_data then
            vim.fn.chansend(job_id, stdin_data)
            vim.fn.chanclose(job_id, "stdin")
          elseif job_id <= 0 then
            vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
            vim.notify("[Quick Edit] Failed to start " .. M.provider, vim.log.levels.ERROR)
          end
        end)

        -- Set up Tab completion and syntax highlighting for /commands
        -- Snacks.input creates the buffer synchronously, so it's current now
        local input_buf = vim.api.nvim_get_current_buf()
        local input_ns = vim.api.nvim_create_namespace("quickedit_input_hl")

        -- Highlight recognized /commands as they're typed
        vim.api.nvim_create_autocmd({ "TextChangedI", "TextChanged" }, {
          buffer = input_buf,
          callback = function()
            vim.api.nvim_buf_clear_namespace(input_buf, input_ns, 0, -1)
            local line = vim.api.nvim_get_current_line()
            local cmd = line:match("^(/[%w_]+)")
            if cmd and (shorthands[cmd] or cmd == "/fix") then
              vim.api.nvim_set_hl(0, "QuickEditCommand", { fg = "#62a0ea", bold = true })
              vim.api.nvim_buf_add_highlight(input_buf, input_ns, "QuickEditCommand", 0, 0, #cmd)
            end
          end,
        })

        vim.keymap.set("i", "<Tab>", function()
          local line = vim.api.nvim_get_current_line()
          if line:match("^/") then
            local matches = {}
            for _, k in ipairs(shorthand_keys) do
              if k:find(line, 1, true) == 1 then
                table.insert(matches, k)
              end
            end
            if #matches > 0 then
              vim.fn.complete(1, matches)
            end
          end
        end, { buffer = input_buf })
      end

      -- Warm up LM Studio model by triggering JIT load (resets 1h TTL)
      function M.warmup()
        if M.provider == "lmstudio" then
          local body = vim.fn.json_encode({
            model = M.lmstudio_model,
            messages = { { role = "user", content = "hi" } },
            max_tokens = 1,
            stream = false,
          })
          vim.fn.jobstart({
            "curl", "-s", "--max-time", "30",
            "-H", "Content-Type: application/json",
            "-X", "POST",
            "http://localhost:1234/v1/chat/completions",
            "-d", body,
          }, {
            on_exit = function(_, code)
              -- curl 7 = connection refused (server down). 28 = timeout (may just be slow first-load; noisy).
              if code == 7 then
                vim.schedule(function()
                  vim.notify("[Quick Edit] Warmup failed — LM Studio server unreachable", vim.log.levels.WARN)
                end)
              end
            end,
          })
        end
      end

      vim.keymap.set("v", "<leader>k", function()
        M.warmup()
        M.quickedit()
      end, { desc = "Quick Edit with LLM" })

      vim.api.nvim_create_user_command("QuickEdit", function()
        M.quickedit()
      end, { range = true })

      -- Toggle inline git diff overlay for current buffer
      vim.keymap.set("n", "<leader>gi", function()
        local buf = vim.api.nvim_get_current_buf()
        local md = require("mini.diff")
        local buf_data = md.get_buf_data(buf)
        if buf_data and buf_data.ref_text then
          md.set_ref_text(buf, {})
        else
          local rel = vim.fn.expand("%:.")
          local ref = vim.fn.system({ "git", "show", "HEAD:./" .. rel })
          if vim.v.shell_error ~= 0 then
            vim.notify("[Diff] File not in git HEAD", vim.log.levels.WARN)
            return
          end
          md.set_ref_text(buf, ref)
          md.toggle_overlay(buf)
        end
      end, { desc = "Toggle inline git diff" })

      _G.quickedit = M
    end,
  },
}
