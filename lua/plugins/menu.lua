-- Context menu system for enhanced IDE experience
return {
  -- Context menus for enhanced IDE experience
  {
    "nvzone/menu",
    lazy = false, -- Load immediately so _G.ide_menus is available for other plugins
    priority = 100, -- Load early but after core plugins
    dependencies = { "nvzone/volt" },
    config = function()
      local menu = require("menu")

      local function prepend_image_actions(items, images)
        table.insert(items, 1, { name = " Open Image", cmd = images.open_at_cursor, rtxt = "mi" })
        table.insert(items, 1, { name = "󰋩 Copy Image", cmd = images.copy_at_cursor, rtxt = "my" })
      end

      -- Set ExBlack3Bg immediately when plugin loads (for first menu)
      vim.api.nvim_set_hl(0, "ExBlack3Bg", { bg = "#3584e4", fg = "#ffffff" })

      -- Also use vim.schedule to ensure it's set after all plugins are loaded
      vim.schedule(function()
        vim.api.nvim_set_hl(0, "ExBlack3Bg", { bg = "#3584e4", fg = "#ffffff" })
      end)

      -- Also ensure it persists after colorscheme changes
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = function()
          vim.api.nvim_set_hl(0, "ExBlack3Bg", { bg = "#3584e4", fg = "#ffffff" })
        end,
      })

      local function normalize_menu(items)
        local normalized = {}
        for _, it in ipairs(items) do
          if it.name == "separator" then
            table.insert(normalized, it)
          else
            local action
            if type(it.cmd) == "function" then
              local fn = it.cmd
              action = function()
                vim.schedule(function()
                  pcall(fn)
                end)
              end
            elseif type(it.cmd) == "string" and it.cmd ~= "" then
              local cmdstr = it.cmd
              action = function()
                vim.schedule(function()
                  pcall(vim.cmd, cmdstr)
                end)
              end
            else
              action = function() end
            end
            table.insert(normalized, { name = it.name, cmd = action, rtxt = it.rtxt })
          end
        end
        return normalized
      end

      -- Helper: run a neo-tree command by refocusing the neo-tree window first.
      -- The menu steals focus, so we stash the neo-tree win ID before opening
      -- and restore it before invoking the command.
      local function neotree_cmd(cmd_name)
        return function()
          local nt_win = _G._neotree_menu_win
          if not nt_win or not vim.api.nvim_win_is_valid(nt_win) then
            return
          end
          vim.api.nvim_set_current_win(nt_win)
          local state = require("neo-tree.sources.manager").get_state("filesystem")
          require("neo-tree.sources.filesystem.commands")[cmd_name](state)
        end
      end

      -- Store menu configurations globally for access
      _G.ide_menus = {
        buffer_menu = {
          { name = " Close Buffer", cmd = "bdelete", rtxt = "" },
          { name = "  Close Others", cmd = "BufferLineCloseOthers", rtxt = "" },
          { name = "separator" },
          { name = "󰤻 Split Horizontal", cmd = "split", rtxt = "" },
          { name = "󰤼 Split Vertical", cmd = "vsplit", rtxt = "" },
          { name = "separator" },
          { name = "󰐃 Pin Tab", cmd = "BufferLineTogglePin", rtxt = "" },
          { name = "  Pick Buffer", cmd = "BufferLinePick", rtxt = "" },
        },

        lsp_menu = {
          { name = "󰊕 Go to Definition", cmd = "lua vim.lsp.buf.definition()", rtxt = "gd" },
          { name = "  Go to References", cmd = "lua vim.lsp.buf.references()", rtxt = "gr" },
          { name = "  Go to Implementation", cmd = "lua vim.lsp.buf.implementation()", rtxt = "gi" },
          { name = "  Go to Type Definition", cmd = "lua vim.lsp.buf.type_definition()", rtxt = "gt" },
          { name = "separator" },
          { name = " Rename Symbol", cmd = "lua vim.lsp.buf.rename()", rtxt = "rn" },
          { name = "  Code Action", cmd = "lua vim.lsp.buf.code_action()", rtxt = "cd" },
          { name = "  Format Document", cmd = "lua vim.lsp.buf.format()", rtxt = "fm" },
          { name = "separator" },
          { name = " Show Diagnostics", cmd = "lua vim.diagnostic.open_float()", rtxt = "df" },
          { name = "  Next Diagnostic", cmd = "lua vim.diagnostic.jump({ count = 1, float = true })", rtxt = "]d" },
          { name = "  Prev Diagnostic", cmd = "lua vim.diagnostic.jump({ count = -1, float = true })", rtxt = "[d" },
          { name = "  Toggle Diagnostic Lines", cmd = "lua require('lsp_lines').toggle()", rtxt = "ld" },
        },

        git_menu = {
          { name = "󰊢 Git Status", cmd = "Neotree float git_status git_base=main", rtxt = "gS" },
          {
            name = "  Toggle Inline Diff",
            cmd = function()
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
            end,
            rtxt = "gi",
          },
          { name = "separator" },
          { name = "  Open Diffview", cmd = "DiffviewOpen", rtxt = "gd" },
          { name = "  Diff Last Commit", cmd = "DiffviewOpen HEAD~1", rtxt = "gD" },
          { name = "  File History", cmd = "DiffviewFileHistory %", rtxt = "gh" },
          { name = " Close Diffview", cmd = "DiffviewClose", rtxt = "gc" },
          { name = "separator" },
          { name = "  Git Blame Line", cmd = "lua Snacks.git.blame_line()", rtxt = "gB" },
          { name = "separator" },
          { name = " Stage/Unstage Hunk", cmd = "lua require('gitsigns').stage_hunk()", rtxt = "gs" },
          { name = "  Review Staged", cmd = "DiffviewOpen --staged", rtxt = "" },
          { name = "󰕍 Unstage All", cmd = "!git reset", rtxt = "gu" },
          { name = "separator" },
          {
            name = "  Quick Commit",
            cmd = function()
              Snacks.input({ prompt = " Commit message: " }, function(msg)
                if not msg or msg == "" then
                  return
                end
                local out = vim.fn.system({ "git", "commit", "-m", msg })
                if vim.v.shell_error ~= 0 then
                  vim.notify("[Git] " .. out, vim.log.levels.ERROR)
                else
                  vim.notify("[Git] " .. out)
                end
              end)
            end,
            rtxt = "",
          },
          { name = "  Commit (editor)", cmd = "lua Snacks.terminal('git commit')", rtxt = "gC" },
        },

        terminal_menu = {
          { name = "󰆍 Toggle Terminal", cmd = "lua Snacks.terminal()", rtxt = "tt" },
          { name = "  Floating Terminal", cmd = "lua Snacks.terminal.toggle()", rtxt = "" },
          { name = "separator" },
          { name = " Python REPL", cmd = "lua Snacks.terminal.toggle('python3')", rtxt = "" },
          { name = "  R Console", cmd = "lua Snacks.terminal.toggle('R')", rtxt = "" },
          { name = "  IPython", cmd = "lua Snacks.terminal.toggle('ipython')", rtxt = "" },
        },

        file_menu = {
          { name = "󰈞 Find Files", cmd = "Telescope find_files", rtxt = "ff" },
          { name = "  Recent Files", cmd = "Telescope oldfiles", rtxt = "fr" },
          { name = "  Live Grep", cmd = "Telescope live_grep", rtxt = "fg" },
          { name = "separator" },
          { name = "󰝒 New File", cmd = "ene", rtxt = "" },
          { name = "󰙅 File Explorer", cmd = "Neotree toggle", rtxt = "e" },
          { name = "  Code Outline", cmd = "Outline", rtxt = "s" },
          { name = "separator" },
          { name = " Save", cmd = "w", rtxt = "" },
          { name = " Save All", cmd = "wa", rtxt = "" },
        },

        layout_menu = {
          { name = " Toggle Left Panel", cmd = "lua require('edgy').toggle('left')", rtxt = "ll" },
          { name = " Toggle Right Panel", cmd = "lua require('edgy').toggle('right')", rtxt = "lr" },
          { name = " Toggle Bottom Panel", cmd = "lua require('edgy').toggle('bottom')", rtxt = "lb" },
          { name = "separator" },
          { name = " Full IDE Layout", cmd = "lua require('edgy').open()", rtxt = "lL" },
          { name = " Close All Panels", cmd = "lua require('edgy').close()", rtxt = "lc" },
          { name = "separator" },
          { name = " Zen Mode", cmd = "lua Snacks.zen()", rtxt = "z" },
          { name = " Zoom Window", cmd = "lua Snacks.zen.zoom()", rtxt = "Z" },
        },

        debug_menu = {
          { name = " Add Breakpoint", cmd = "echo 'Debug: Breakpoint (nvim-dap needed)'", rtxt = "" },
          { name = " Start Debugging", cmd = "echo 'Debug: Start (nvim-dap needed)'", rtxt = "" },
          { name = " Step Over", cmd = "echo 'Debug: Step Over (nvim-dap needed)'", rtxt = "" },
          { name = " Step Into", cmd = "echo 'Debug: Step Into (nvim-dap needed)'", rtxt = "" },
          { name = " Step Out", cmd = "echo 'Debug: Step Out (nvim-dap needed)'", rtxt = "" },
          { name = " Stop Debugging", cmd = "echo 'Debug: Stop (nvim-dap needed)'", rtxt = "" },
        },

        test_menu = {
          { name = "  Run File Tests", cmd = "lua require('neotest').run.run(vim.fn.expand('%'))", rtxt = "tf" },
          { name = "  Run All Tests", cmd = "lua require('neotest').run.run(vim.fn.getcwd())", rtxt = "ta" },
          { name = "separator" },
          { name = "  Test Summary", cmd = "lua require('neotest').summary.toggle()", rtxt = "ts" },
          {
            name = " Show Output",
            cmd = "lua require('neotest').output.open({ enter = true, auto_close = true })",
            rtxt = "to",
          },
          { name = "  Toggle Output Panel", cmd = "lua require('neotest').output_panel.toggle()", rtxt = "tO" },
          { name = "separator" },
          { name = " Debug Test", cmd = "lua require('neotest').run.run({strategy = 'dap'})", rtxt = "td" },
          { name = "  Toggle Watch", cmd = "lua require('neotest').watch.toggle(vim.fn.expand('%'))", rtxt = "tw" },
          {
            name = "  Test Error Details",
            cmd = "lua require('neotest').output.open({ enter = false, auto_close = false, short = false })",
            rtxt = "te",
          },
          { name = " Stop Tests", cmd = "lua require('neotest').run.stop()", rtxt = "tS" },
        },

        claude_menu = {
          { name = "Toggle Claude Code", cmd = "ClaudeCode", rtxt = "cc" },
          { name = "Focus Claude Code", cmd = "ClaudeCodeFocus", rtxt = "cf" },
          { name = "separator" },
          { name = "Select Model", cmd = "ClaudeCodeSelectModel", rtxt = "cm" },
          { name = " Accept Diff", cmd = "ClaudeCodeDiffAccept", rtxt = "cd" },
          { name = "󰜺 Deny Diff", cmd = "ClaudeCodeDiffDeny", rtxt = "cr" },
        },

        jupyter_menu = {
          {
            name = " Select Kernel",
            cmd = function()
              require("config.notebook_kernels").pick()
            end,
            rtxt = "mK",
          },
          { name = "separator" },
          { name = "  Run Selection", cmd = "MoltenEvaluateVisual", rtxt = "mr" },
          { name = "separator" },
          { name = " Stop Kernel", cmd = "MoltenDeinit", rtxt = "mq" },
        },

        neotree_menu = {
          { name = "󰝒 Add File/Directory", cmd = neotree_cmd("add"), rtxt = "a" },
          { name = " Rename", cmd = neotree_cmd("rename"), rtxt = "r" },
          { name = " Move", cmd = neotree_cmd("move"), rtxt = "m" },
          { name = "󰆴 Delete", cmd = neotree_cmd("delete"), rtxt = "d" },
          { name = "separator" },
          { name = " Copy File", cmd = neotree_cmd("copy_to_clipboard"), rtxt = "c" },
          { name = " Paste", cmd = neotree_cmd("paste_from_clipboard"), rtxt = "p" },
          { name = "separator" },
          {
            name = " Copy Absolute Path",
            cmd = function()
              local state = require("neo-tree.sources.manager").get_state("filesystem")
              local node = state.tree:get_node()
              if node then
                local path = node:get_id()
                vim.fn.setreg("+", path)
                vim.notify("Copied: " .. path)
              end
            end,
            rtxt = "",
          },
          {
            name = " Copy Relative Path",
            cmd = function()
              local state = require("neo-tree.sources.manager").get_state("filesystem")
              local node = state.tree:get_node()
              if node then
                local path = vim.fn.fnamemodify(node:get_id(), ":.")
                vim.fn.setreg("+", path)
                vim.notify("Copied: " .. path)
              end
            end,
            rtxt = "",
          },
          { name = "separator" },
          {
            name = "󰤻 Open in Horizontal Split",
            cmd = function()
              local state = require("neo-tree.sources.manager").get_state("filesystem")
              local node = state.tree:get_node()
              if not node or node.type ~= "file" then
                return
              end
              local path = node:get_id()
              -- Find main editing window and split it
              for _, win in ipairs(vim.api.nvim_list_wins()) do
                local wbuf = vim.api.nvim_win_get_buf(win)
                local ft = vim.bo[wbuf].filetype
                local bt = vim.bo[wbuf].buftype
                if
                  ft ~= "neo-tree"
                  and ft ~= "Outline"
                  and ft ~= "neotest-summary"
                  and bt == ""
                  and vim.api.nvim_win_get_config(win).relative == ""
                then
                  vim.api.nvim_set_current_win(win)
                  vim.cmd("split " .. vim.fn.fnameescape(path))
                  return
                end
              end
            end,
            rtxt = "",
          },
          {
            name = "󰤼 Open in Vertical Split",
            cmd = function()
              local state = require("neo-tree.sources.manager").get_state("filesystem")
              local node = state.tree:get_node()
              if not node or node.type ~= "file" then
                return
              end
              local path = node:get_id()
              for _, win in ipairs(vim.api.nvim_list_wins()) do
                local wbuf = vim.api.nvim_win_get_buf(win)
                local ft = vim.bo[wbuf].filetype
                local bt = vim.bo[wbuf].buftype
                if
                  ft ~= "neo-tree"
                  and ft ~= "Outline"
                  and ft ~= "neotest-summary"
                  and bt == ""
                  and vim.api.nvim_win_get_config(win).relative == ""
                then
                  vim.api.nvim_set_current_win(win)
                  vim.cmd("vsplit " .. vim.fn.fnameescape(path))
                  return
                end
              end
            end,
            rtxt = "",
          },
          { name = "separator" },
          { name = " File Operations", cmd = "FileMenu", rtxt = "mf" },
          { name = " Layout Control", cmd = "LayoutMenu", rtxt = "mp" },
          { name = " Terminal/REPL", cmd = "TerminalMenu", rtxt = "mt" },
          { name = "󰊢 Git Operations", cmd = "GitMenu", rtxt = "mg" },
        },

        context_menu = {
          { name = " File Operations", cmd = "FileMenu", rtxt = "mf" },
          { name = "separator" },
          { name = " LSP Actions", cmd = "LspMenu", rtxt = "ml" },
          { name = " Debug Tools", cmd = "DebugMenu", rtxt = "md" },
          { name = "separator" },
          { name = "󰊢 Git Operations", cmd = "GitMenu", rtxt = "mg" },
          { name = " Layout Control", cmd = "LayoutMenu", rtxt = "mp" },
          { name = " Buffer Actions", cmd = "BufferMenu", rtxt = "mb" },
          { name = " Terminal/REPL", cmd = "TerminalMenu", rtxt = "mt" },
        },
      }

      -- Add test runner and Claude Code to context menu
      table.insert(_G.ide_menus.context_menu, { name = "󰙨 Test Runner", cmd = "TestMenu", rtxt = "mk" })
      table.insert(_G.ide_menus.context_menu, { name = "󰛄 Claude Code", cmd = "ClaudeMenu", rtxt = "mC" })

      -- Make menu utility functions globally available
      _G.ide_menus._normalize_menu = normalize_menu
      _G.ide_menus._menu_opts = function()
        -- Ensure proper menu highlighting for both light and dark themes
        local is_dark = vim.o.background == "dark"

        -- Set the nvzone/menu hover highlight group (fixes black menu selection)
        if is_dark then
          vim.api.nvim_set_hl(0, "ExBlack3Bg", { bg = "#3584e4", fg = "#ffffff" })
          -- Set menu-specific highlights for better contrast
          vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#2d2d2d", fg = "#ffffff" })
          vim.api.nvim_set_hl(0, "FloatBorder", { bg = "#2d2d2d", fg = "#666666" })
        else
          vim.api.nvim_set_hl(0, "ExBlack3Bg", { bg = "#3584e4", fg = "#ffffff" })
          -- Set menu-specific highlights for better contrast
          vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#ffffff", fg = "#2e3436" })
          vim.api.nvim_set_hl(0, "FloatBorder", { bg = "#ffffff", fg = "#999999" })
        end

        return {
          mouse = true,
          border = "rounded",
          winblend = 0, -- No transparency for menu windows to ensure readability
        }
      end

      -- Create user commands with theme-aware styling
      local function notebook_output_item()
        local buf, line = vim.api.nvim_get_current_buf(), vim.api.nvim_win_get_cursor(0)[1]
        return {
          name = "Open Output",
          rtxt = "<leader>jv",
          cmd = function()
            require("config.notebook_output_view").open(buf, line)
          end,
        }
      end

      local function prepend_kernel_actions(items)
        local kernels = require("config.notebook_kernel_menu").items(
          vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
        )
        if #kernels > 0 then
          table.insert(items, 1, { name = "separator" })
          for i = #kernels, 1, -1 do
            table.insert(items, 1, kernels[i])
          end
        end
      end

      local function notebook_outline_menu()
        if vim.bo.filetype ~= "Outline" then
          return false
        end
        local items = require("config.notebook_outline_actions").context_menu()
        if not items then
          return false
        end
        menu.open(normalize_menu(items), _G.ide_menus._menu_opts())
        return true
      end

      vim.api.nvim_create_user_command("BufferMenu", function()
        menu.open(normalize_menu(_G.ide_menus.buffer_menu), _G.ide_menus._menu_opts())
      end, {})
      vim.api.nvim_create_user_command("LspMenu", function()
        menu.open(normalize_menu(_G.ide_menus.lsp_menu), _G.ide_menus._menu_opts())
      end, {})
      vim.api.nvim_create_user_command("GitMenu", function()
        menu.open(normalize_menu(_G.ide_menus.git_menu), _G.ide_menus._menu_opts())
      end, {})
      vim.api.nvim_create_user_command("TerminalMenu", function()
        menu.open(normalize_menu(_G.ide_menus.terminal_menu), _G.ide_menus._menu_opts())
      end, {})
      vim.api.nvim_create_user_command("FileMenu", function()
        menu.open(normalize_menu(_G.ide_menus.file_menu), _G.ide_menus._menu_opts())
      end, {})
      vim.api.nvim_create_user_command("LayoutMenu", function()
        menu.open(normalize_menu(_G.ide_menus.layout_menu), _G.ide_menus._menu_opts())
      end, {})
      vim.api.nvim_create_user_command("DebugMenu", function()
        menu.open(normalize_menu(_G.ide_menus.debug_menu), _G.ide_menus._menu_opts())
      end, {})
      vim.api.nvim_create_user_command("TestMenu", function()
        menu.open(normalize_menu(_G.ide_menus.test_menu), _G.ide_menus._menu_opts())
      end, {})
      vim.api.nvim_create_user_command("ClaudeMenu", function()
        menu.open(normalize_menu(_G.ide_menus.claude_menu), _G.ide_menus._menu_opts())
      end, {})
      vim.api.nvim_create_user_command("JupyterMenu", function()
        menu.open(normalize_menu(_G.ide_menus.jupyter_menu), _G.ide_menus._menu_opts())
      end, {})
      vim.api.nvim_create_user_command("ContextMenu", function()
        if notebook_outline_menu() then
          return
        end
        local items = vim.deepcopy(_G.ide_menus.context_menu)
        local mode = require("config.document_outline").format(vim.api.nvim_get_current_buf())
        prepend_kernel_actions(items)
        if mode == "notebook" then
          table.insert(items, 1, notebook_output_item())
        end
        menu.open(normalize_menu(items), _G.ide_menus._menu_opts())
      end, {})

      -- Right-click context menu with copy/paste + IDE entries
      vim.api.nvim_create_user_command("NeotreeMenu", function()
        -- Stash the neo-tree window so commands can refocus it after the menu closes
        _G._neotree_menu_win = vim.api.nvim_get_current_win()
        menu.open(normalize_menu(_G.ide_menus.neotree_menu), _G.ide_menus._menu_opts())
      end, {})

      -- Diff context menu - shown when right-clicking in a claudecode diff buffer
      _G.ide_menus.diff_menu = {
        { name = " Accept Diff", cmd = "ClaudeCodeDiffAccept", rtxt = "cd" },
        { name = "󰜺 Deny Diff", cmd = "ClaudeCodeDiffDeny", rtxt = "cr" },
        { name = "separator" },
        { name = "󰛄 Focus Claude Code", cmd = "ClaudeCodeFocus", rtxt = "cf" },
      }

      vim.api.nvim_create_user_command("DiffMenu", function()
        menu.open(normalize_menu(_G.ide_menus.diff_menu), _G.ide_menus._menu_opts())
      end, {})

      vim.api.nvim_create_user_command("RightClickMenu", function()
        if notebook_outline_menu() then
          return
        end
        if vim.bo.filetype == "snacks_dashboard" or vim.bo.filetype == "dashboard" then
          return
        end

        if vim.bo.filetype == "neo-tree" then
          vim.cmd("NeotreeMenu")
          return
        end

        -- Show diff menu when in a claudecode diff buffer
        if vim.b.claudecode_diff_tab_name then
          vim.cmd("DiffMenu")
          return
        end

        -- Create dynamic context menu - add Jupyter submenu for .ipynb files
        local context_menu = vim.deepcopy(_G.ide_menus.context_menu)
        local filename = vim.fn.expand("%:t")

        prepend_kernel_actions(context_menu)
        if filename:match("%.ipynb$") then
          table.insert(context_menu, 1, notebook_output_item())
          -- Add Jupyter menu item to the context menu for notebook files
          table.insert(context_menu, { name = " Jupyter Notebook", cmd = "JupyterMenu", rtxt = "mj" })
          -- Right-clicking an output puts copying it first
          local copy = require("config.notebook_copy")
          local clicked_images = copy.clicked()
          local has_image = #clicked_images > 0
          local has_text = copy.output_text_clicked() ~= ""
          if has_image or has_text then
            table.insert(context_menu, 1, { name = "separator" })
          end
          if has_text then
            table.insert(context_menu, 1, { name = "󰆏 Copy Output", cmd = copy.copy_output_at_cursor, rtxt = "mo" })
          end
          if has_image then
            table.insert(context_menu, 1, {
              name = " Open Image",
              cmd = function()
                copy.open(clicked_images)
              end,
              rtxt = "mi",
            })
            table.insert(context_menu, 1, {
              name = "󰋩 Copy Image",
              cmd = function()
                copy.copy(clicked_images)
              end,
              rtxt = "my",
            })
          end
        end

        local ft = vim.bo.filetype
        if ft == "markdown" or ft == "quarto" or ft == "rmd" then
          table.insert(context_menu, { name = "󰍔 Toggle Markview", cmd = "Markview Toggle", rtxt = "mv" })
          if ft == "markdown" or ft == "quarto" then
            local images = require("config.document_images")
            if #images.at_cursor() > 0 then
              table.insert(context_menu, 1, { name = "separator" })
              prepend_image_actions(context_menu, images)
            end
            local path = vim.api.nvim_buf_get_name(0)
            for _, workspace in ipairs(_G.Obsidian and Obsidian.workspaces or {}) do
              if vim.startswith(path, tostring(workspace.path) .. "/") then
                table.insert(context_menu, {
                  name = "Paste Image (markdown)",
                  cmd = "Obsidian paste_img",
                })
                break
              end
            end
            table.insert(context_menu, {
              name = images.is_enabled(0) and "Show Image Links" or "Render Images Inline",
              cmd = images.toggle,
              rtxt = "mi",
            })
          end
          table.insert(context_menu, {
            name = (vim.wo.wrap and "󰖶 Disable" or "󰖶 Enable") .. " Line Wrap",
            cmd = require("config.prose_wrap").toggle,
            rtxt = "tw",
          })
        end

        menu.open(normalize_menu(context_menu), _G.ide_menus._menu_opts())
      end, {})
    end,
    keys = {
      {
        "<C-t>",
        function()
          if vim.bo.filetype == "snacks_dashboard" or vim.bo.filetype == "dashboard" then
            return
          end
          if vim.bo.filetype == "neo-tree" then
            vim.cmd("NeotreeMenu")
            return
          end
          vim.cmd("ContextMenu")
        end,
        desc = "Open Context Menu",
      },
      {
        "<leader>m",
        function()
          if vim.bo.filetype == "snacks_dashboard" or vim.bo.filetype == "dashboard" then
            return
          end
          if vim.bo.filetype == "neo-tree" then
            vim.cmd("NeotreeMenu")
            return
          end
          vim.cmd("ContextMenu")
        end,
        desc = "Open Context Menu",
      },
      { "<leader>mb", "<cmd>BufferMenu<cr>", desc = "Buffer Menu" },
      { "<leader>ml", "<cmd>LspMenu<cr>", desc = "LSP Menu" },
      { "<leader>mg", "<cmd>GitMenu<cr>", desc = "Git Menu" },
      { "<leader>mt", "<cmd>TerminalMenu<cr>", desc = "Terminal Menu" },
      { "<leader>mf", "<cmd>FileMenu<cr>", desc = "File Menu" },
      { "<leader>mp", "<cmd>LayoutMenu<cr>", desc = "Layout Menu" },
      { "<leader>md", "<cmd>DebugMenu<cr>", desc = "Debug Menu" },
      { "<leader>mk", "<cmd>TestMenu<cr>", desc = "Test Menu" },
      { "<leader>mC", "<cmd>ClaudeMenu<cr>", desc = "Claude Code Menu" },
      { "<leader>mj", "<cmd>JupyterMenu<cr>", desc = "Jupyter Menu" },

      -- Right-click context menu support
      {
        "<RightMouse>",
        function()
          -- Act where the click landed, like a right-click in any editor. In
          -- visual mode the selection is what the menu acts on, so keep it.
          local mouse = vim.fn.getmousepos()
          if vim.fn.mode() == "n" and mouse.winid > 0 and vim.api.nvim_win_is_valid(mouse.winid) then
            vim.api.nvim_set_current_win(mouse.winid)
          end
          if vim.fn.mode() == "n" and mouse.winid == vim.api.nvim_get_current_win() and mouse.line > 0 then
            vim.api.nvim_win_set_cursor(0, { mouse.line, math.max(0, mouse.column - 1) })
          end
          vim.cmd("RightClickMenu")
        end,
        desc = "Right-click Context Menu",
        mode = { "n", "v" },
      },
    },
  },
}
