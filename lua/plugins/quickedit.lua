-- Inline LLM code editing: select code, type instruction, get inline diff
-- Uses Snacks.input() for prompt, mini.diff for inline overlay, XML-structured responses

return {
  {
    "echasnovski/mini.diff",
    lazy = false,
    config = function()
      require("mini.diff").setup({
        source = require("mini.diff").gen_source.none(),
      })

      -- Quick Edit: inline LLM code editing
      local M = {
        provider = "claude", -- "claude" or "ollama"
        claude_model = "haiku", -- fast model for quick edits
        ollama_model = "qwen2.5-coder:14b",
      }

      local system_prompt = [[You are a code editing assistant. Apply the user's instruction to the provided code.
Return ONLY the modified code region (the lines shown below), not the entire file.
Respond with EXACTLY this format, nothing else:

<code>
[the complete modified code for the specified region]
</code>
<summary>
[one-line description of changes]
</summary>]]

      local function parse_response(response)
        local code = response:match("<code>\n?(.-)\n?</code>")
        local summary = response:match("<summary>\n?(.-)\n?</summary>")

        if not code then
          code = response:match("```%w*\n(.-)\n```")
        end

        if not code then
          code = response
          summary = "Raw response (no structured format detected)"
        end

        code = code:gsub("^%s*\n", ""):gsub("\n%s*$", "")
        return code, summary or "Changes applied"
      end

      -- Track active quickedit state per buffer
      local active_edits = {}

      local function cleanup_edit(buf)
        local state = active_edits[buf]
        if not state then
          return
        end
        active_edits[buf] = nil

        -- Remove buffer-local keymaps
        pcall(vim.keymap.del, "n", "<CR>", { buffer = buf })
        pcall(vim.keymap.del, "n", "<Esc>", { buffer = buf })
        pcall(vim.keymap.del, "n", "<Tab>", { buffer = buf })

        -- Clear mini.diff overlay
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
        -- Undo the LLM replacement
        vim.cmd("silent undo")
        cleanup_edit(buf)
        vim.notify("[Quick Edit] Rejected")
      end

      local function apply_inline_diff(new_code, buf, start_line, end_line)
        -- Snapshot the entire buffer as reference for mini.diff
        local snapshot = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

        -- Replace the selected region with LLM output
        local new_lines = vim.split(new_code, "\n")
        vim.api.nvim_buf_set_lines(buf, start_line - 1, end_line, false, new_lines)

        -- Tell mini.diff to use the snapshot as reference
        require("mini.diff").set_ref_text(buf, snapshot)

        -- Enable overlay to show the inline diff
        -- toggle_overlay shows virtual text for deleted lines and highlights for added
        pcall(function()
          require("mini.diff").toggle_overlay(buf)
        end)

        -- Track state
        active_edits[buf] = { snapshot = snapshot }

        -- Jump cursor to the start of the changed region so it's visible
        pcall(vim.api.nvim_win_set_cursor, 0, { start_line, 0 })
        vim.cmd("normal! zz") -- center the changes on screen

        -- Buffer-local keymaps
        vim.keymap.set("n", "<CR>", function()
          accept(buf)
        end, { buffer = buf, nowait = true, desc = "Accept quick edit" })

        vim.keymap.set("n", "<Esc>", function()
          reject(buf)
        end, { buffer = buf, nowait = true, desc = "Reject quick edit" })

        vim.keymap.set("n", "<Tab>", function()
          require("mini.diff").toggle_overlay(buf)
        end, { buffer = buf, nowait = true, desc = "Toggle diff overlay" })

        -- Clean up if buffer is deleted
        vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
          buffer = buf,
          once = true,
          callback = function()
            active_edits[buf] = nil
          end,
        })

        vim.notify("[Quick Edit] <CR> accept | <Esc> reject | <Tab> toggle overlay")
      end

      function M.quickedit()
        -- Capture visual bounds while still in visual mode
        -- "v" mark = start of visual selection, "." = cursor (end)
        local s = vim.fn.getpos("v")[2]
        local e = vim.fn.getpos(".")[2]
        local start_line = math.min(s, e)
        local end_line = math.max(s, e)
        local buf = vim.api.nvim_get_current_buf()

        -- Exit visual mode first, then read lines
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)

        local lines = vim.api.nvim_buf_get_lines(buf, start_line - 1, end_line, false)
        local sel_text = table.concat(lines, "\n")
        local filepath = vim.fn.expand("%:p")
        local rel_path = vim.fn.fnamemodify(filepath, ":.")

        Snacks.input({
          prompt = " Quick Edit: ",
          win = {
            relative = "cursor",
            row = -3,
          },
        }, function(instruction)
          if not instruction or instruction == "" then
            return
          end

          local prompt = string.format(
            "%s\n\nFile: %s\nLines %d-%d:\n```\n%s\n```\n\nInstruction: %s",
            system_prompt,
            rel_path,
            start_line,
            end_line,
            sel_text,
            instruction
          )

          local cmd
          if M.provider == "claude" then
            cmd = { "claude", "-p", prompt, "--model", M.claude_model }
          else
            cmd = { "ollama", "run", M.ollama_model, prompt }
          end

          vim.notify("[Quick Edit] Waiting for LLM...")

          local stdout = {}
          local stderr = {}
          vim.fn.jobstart(cmd, {
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
                if exit_code ~= 0 then
                  local err_msg = table.concat(stderr, "\n")
                  vim.notify(
                    "[Quick Edit] Failed (exit " .. exit_code .. "): " .. err_msg,
                    vim.log.levels.ERROR
                  )
                  return
                end

                local response = table.concat(stdout, "\n")
                local code, summary = parse_response(response)

                if not vim.api.nvim_buf_is_valid(buf) then
                  vim.notify("[Quick Edit] Buffer no longer valid", vim.log.levels.ERROR)
                  return
                end

                apply_inline_diff(code, buf, start_line, end_line)
                vim.notify("[Quick Edit] " .. (summary or "Done"))
              end)
            end,
          })
        end)
      end

      vim.keymap.set("v", "<leader>k", function()
        M.quickedit()
      end, { desc = "Quick Edit with LLM" })

      vim.api.nvim_create_user_command("QuickEdit", function()
        M.quickedit()
      end, { range = true })

      _G.quickedit = M
    end,
  },
}
