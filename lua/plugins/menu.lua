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

      -- Store menu configurations globally for access
      _G.ide_menus = {
        buffer_menu = {
          { name = " Close Buffer", cmd = "bdelete", rtxt = "" },
          { name = " Close Others", cmd = "BufferLineCloseOthers", rtxt = "" },
          { name = "separator" },
          { name = "󰤻 Split Horizontal", cmd = "split", rtxt = "" },
          { name = "󰤼 Split Vertical", cmd = "vsplit", rtxt = "" },
          { name = "separator" },
          { name = "󰐃 Pin Tab", cmd = "BufferLineTogglePin", rtxt = "" },
          { name = " Pick Buffer", cmd = "BufferLinePick", rtxt = "" },
        },

        lsp_menu = {
          { name = "󰊕 Go to Definition", cmd = "lua vim.lsp.buf.definition()", rtxt = "gd" },
          { name = " Go to References", cmd = "lua vim.lsp.buf.references()", rtxt = "gr" },
          { name = " Go to Implementation", cmd = "lua vim.lsp.buf.implementation()", rtxt = "gi" },
          { name = " Go to Type Definition", cmd = "lua vim.lsp.buf.type_definition()", rtxt = "gt" },
          { name = "separator" },
          { name = " Rename Symbol", cmd = "lua vim.lsp.buf.rename()", rtxt = "rn" },
          { name = " Code Action", cmd = "lua vim.lsp.buf.code_action()", rtxt = "cd" },
          { name = "󰊄 Format Document", cmd = "lua vim.lsp.buf.format()", rtxt = "fm" },
          { name = "separator" },
          { name = " Show Diagnostics", cmd = "lua vim.diagnostic.open_float()", rtxt = "df" },
          { name = " Toggle Diagnostic Lines", cmd = "lua require('lsp_lines').toggle()", rtxt = "ld" },
        },

        git_menu = {
          { name = "󰊢 Git Status", cmd = "Neotree float git_status git_base=main", rtxt = "gS" },
          { name = " Open Diffview", cmd = "DiffviewOpen", rtxt = "gd" },
          { name = " Diff Last Commit", cmd = "DiffviewOpen HEAD~1", rtxt = "gD" },
          { name = " File History", cmd = "DiffviewFileHistory %", rtxt = "gh" },
          { name = " Close Diffview", cmd = "DiffviewClose", rtxt = "gc" },
          { name = "separator" },
          { name = "󰊢 Git Blame Line", cmd = "lua Snacks.git.blame_line()", rtxt = "gB" },
        },

        terminal_menu = {
          { name = "󰆍 Toggle Terminal", cmd = "lua Snacks.terminal()", rtxt = "tt" },
          { name = "󰆍 Floating Terminal", cmd = "lua Snacks.terminal.toggle()", rtxt = "" },
          { name = "separator" },
          { name = " Python REPL", cmd = "lua Snacks.terminal.toggle('python3')", rtxt = "" },
          { name = " R Console", cmd = "lua Snacks.terminal.toggle('R')", rtxt = "" },
          { name = "📓 IPython", cmd = "lua Snacks.terminal.toggle('ipython')", rtxt = "" },
        },

        file_menu = {
          { name = "󰈞 Find Files", cmd = "Telescope find_files", rtxt = "ff" },
          { name = "󱋡 Recent Files", cmd = "Telescope oldfiles", rtxt = "fr" },
          { name = "󰈬 Live Grep", cmd = "Telescope live_grep", rtxt = "fg" },
          { name = "separator" },
          { name = "󰝒 New File", cmd = "ene", rtxt = "" },
          { name = "󰙅 File Explorer", cmd = "Neotree toggle", rtxt = "e" },
          { name = "󰘎 Code Outline", cmd = "Outline", rtxt = "s" },
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
          { name = "separator" },
        },

        test_menu = {
          { name = " Run File Tests", cmd = "lua require('neotest').run.run(vim.fn.expand('%'))", rtxt = "tf" },
          { name = " Run All Tests", cmd = "lua require('neotest').run.run(vim.fn.getcwd())", rtxt = "ta" },
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
          { name = "󰛄 Toggle Claude Code", cmd = "ClaudeCode", rtxt = "cc" },
          { name = "󰛄 Focus Claude Code", cmd = "ClaudeCodeFocus", rtxt = "cf" },
          { name = "separator" },
          { name = "󰛸 Select Model", cmd = "ClaudeCodeSelectModel", rtxt = "cm" },
          { name = " Accept Diff", cmd = "ClaudeCodeDiffAccept", rtxt = "cd" },
          { name = "󰜺 Deny Diff", cmd = "ClaudeCodeDiffDeny", rtxt = "cr" },
        },

        jupyter_menu = {
          { name = "🚀 Initialize Kernel", cmd = "MoltenInit", rtxt = "mi" },
          { name = "▶️ Run Cell", cmd = "MoltenEvaluateLine", rtxt = "jr" },
          { name = "🔄 Re-run Cell", cmd = "MoltenReevaluateCell", rtxt = "mc" },
          { name = "📊 Run Selection", cmd = "MoltenEvaluateVisual", rtxt = "mr" },
          { name = "separator" },
          { name = "👁 Show Output", cmd = "MoltenShowOutput", rtxt = "ms" },
          { name = "🙈 Hide Output", cmd = "MoltenHideOutput", rtxt = "mh" },
          { name = "🗑️ Delete Cell", cmd = "MoltenDelete", rtxt = "md" },
          { name = "separator" },
          { name = "🛑 Quit Kernel", cmd = "MoltenDeinit", rtxt = "mq" },
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
      table.insert(
        _G.ide_menus.context_menu,
        #_G.ide_menus.context_menu,
        { name = "󰙨 Test Runner", cmd = "TestMenu", rtxt = "mk" }
      )
      table.insert(
        _G.ide_menus.context_menu,
        #_G.ide_menus.context_menu,
        { name = "󰛄 Claude Code", cmd = "ClaudeMenu", rtxt = "mC" }
      )

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
        menu.open(normalize_menu(_G.ide_menus.context_menu), _G.ide_menus._menu_opts())
      end, {})

      -- Right-click context menu with copy/paste + IDE entries
      vim.api.nvim_create_user_command("RightClickMenu", function()
        if vim.bo.filetype == "snacks_dashboard" or vim.bo.filetype == "dashboard" then
          return
        end

        -- Create dynamic context menu - add Jupyter submenu for .ipynb files
        local context_menu = vim.deepcopy(_G.ide_menus.context_menu)
        local filename = vim.fn.expand("%:t")

        if filename:match("%.ipynb$") then
          -- Add Jupyter menu item to the context menu for notebook files
          table.insert(
            context_menu,
            #context_menu,
            { name = "📓 Jupyter Notebook", cmd = "JupyterMenu", rtxt = "mj" }
          )
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
          if vim.bo.filetype == "snacks_dashboard" or vim.bo.filetype == "dashboard" then
            return
          end
          vim.cmd("RightClickMenu")
        end,
        desc = "Right-click Context Menu",
        mode = { "n", "v" },
      },
    },
  },
}
