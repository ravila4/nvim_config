return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      -- Beautiful animated notifications
      notifier = {
        enabled = true,
        timeout = 3000,
        width = { min = 40, max = 0.4 },
        height = { min = 1, max = 0.6 },
        margin = { top = 0, right = 1, bottom = 0 },
        padding = true,
        sort = { "level", "added" },
        level = vim.log.levels.TRACE,
        icons = {
          error = " ",
          warn = " ",
          info = " ",
          debug = " ",
          trace = " ",
        },
        style = "compact", -- "compact"|"fancy"|"minimal"
      },

      dashboard = {
        enabled = true,
        preset = {
          keys = {
            { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
            { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
            { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
            { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
            { icon = " ", key = "s", desc = "Restore Session", section = "session" },
            { icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
          header = [[

 ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
 ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
 ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
 ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
 ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
 ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝

  Your Next-Gen Bioinformatics IDE  

]],
        },
        sections = {
          { section = "header" },
          { section = "keys", gap = 1, padding = 1 },
          { pane = 2, icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = 1 , limit = 10 },
          { pane = 2, icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1, limit = 10 },
          { section = "startup" },
        },
      },

      -- Zen mode for focused coding
      zen = {
        enabled = true,
        toggles = {
          dim = true,
          git_signs = false,
          mini_diff_signs = false,
          diagnostics = false,
          inlay_hints = false,
        },
        show = {
          statusline = false,
          tabline = false,
        },
        win = {
          backdrop = 0.95,
          width = 120,
          height = 1,
        },
      },

      -- Improved quickfix with modern UI
      quickfile = {
        enabled = true,
      },

      -- Terminal integration
      terminal = {
        enabled = true,
        win = {
          position = "bottom",
          border = "rounded",
          height = 0.4,
          width = 0.8,
        },
      },

      -- Smooth scrolling
      scroll = {
        enabled = true,
        animate = {
          duration = { step = 15, total = 250 },
          easing = "linear",
        },
      },

      -- Indent guides
      indent = {
        enabled = true,
        char = "│",
        blank = " ",
        only_scope = false,
        only_current = false,
        hl = "SnacksIndent", -- highlight group for indent guides
        scope = {
          enabled = true,
          char = "│",
          underline = false, -- underline the scope
          only_current = false,
          hl = "SnacksIndentScope", -- highlight group for scopes
        },
        chunk = {
          enabled = true,
          char = {
            corner_top = "┌",
            corner_bottom = "└",
            horizontal = "─",
            vertical = "│",
            arrow = ">",
          },
          hl = "SnacksIndentChunk", -- highlight group for chunk
        },
      },

      -- Words highlighting
      words = {
        enabled = true,
        debounce = 200,
        notify_jump = false,
        notify_end = true,
        foldopen = true,
        jumplist = true,
        modes = { "n", "i", "c" },
      },

      -- Status column enhancements
      statuscolumn = {
        enabled = true,
        left = { "mark", "sign" },
        right = { "fold", "git" },
        folds = {
          open = false,
          git_hl = false,
        },
        git = {
          patterns = { "GitSign", "MiniDiffSign" },
        },
        refresh = 50,
      },

      -- Scope highlighting
      scope = {
        enabled = true,
        animate = {
          enabled = true,
          easing = "linear",
          duration = {
            step = 20,
            total = 500,
          },
        },
        char = "│",
        underline = false,
        only_current = false,
        hl = "SnacksScope",
      },
    },
    keys = {
      { "<leader>z", function() Snacks.zen() end, desc = "Toggle Zen Mode" },
      { "<leader>Z", function() Snacks.zen.zoom() end, desc = "Toggle Zoom" },
      { "<leader>.", function() Snacks.scratch() end, desc = "Toggle Scratch Buffer" },
      { "<leader>S", function() Snacks.scratch.select() end, desc = "Select Scratch Buffer" },
      { "<leader>n", function() Snacks.notifier.show_history() end, desc = "Notification History" },
      { "<leader>bd", function() Snacks.bufdelete() end, desc = "Delete Buffer" },
      { "<leader>cR", function() Snacks.rename.rename_file() end, desc = "Rename File" },
      { "<leader>gB", function() Snacks.git.blame_line() end, desc = "Git Blame Line" },
      { "<leader>gf", function() Snacks.lazygit.log_file() end, desc = "Lazygit Current File History" },
      { "<leader>gg", function() Snacks.lazygit() end, desc = "Lazygit" },
      { "<leader>gl", function() Snacks.lazygit.log() end, desc = "Lazygit Log (cwd)" },
      { "<leader>un", function() Snacks.notifier.hide() end, desc = "Dismiss All Notifications" },
      { "<c-/>", function() Snacks.terminal() end, desc = "Toggle Terminal" },
      { "<c-_>", function() Snacks.terminal() end, desc = "which_key_ignore" },
      { "]]", function() Snacks.words.jump(vim.v.count1) end, desc = "Next Reference", mode = { "n", "t" } },
      { "[[", function() Snacks.words.jump(-vim.v.count1) end, desc = "Prev Reference", mode = { "n", "t" } },
    },
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        callback = function()
          -- Setup some globals for debugging (lazy-loaded)
          _G.dd = function(...)
            Snacks.debug.inspect(...)
          end
          _G.bt = function()
            Snacks.debug.backtrace()
          end
          vim.print = _G.dd -- Override print to use snacks for `:=` command

          -- Create some toggle mappings
          Snacks.toggle.option("spell", { name = "spelling" }):map("<leader>us")
          Snacks.toggle.option("wrap", { name = "wrap" }):map("<leader>uw")
          Snacks.toggle.option("relativenumber", { name = "relative number" }):map("<leader>uL")
          Snacks.toggle.diagnostics():map("<leader>ud")
          Snacks.toggle.line_number():map("<leader>ul")
          Snacks.toggle.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map("<leader>uc")
          Snacks.toggle.treesitter():map("<leader>uT")
          Snacks.toggle.option("background", { off = "light", on = "dark", name = "dark background" }):map("<leader>ub")
          Snacks.toggle.inlay_hints():map("<leader>uh")

          -- Custom dashboard colors - match lualine teal #228787
          vim.api.nvim_set_hl(0, "SnacksDashboardHeader", { fg = "#228787" })  -- Your lualine teal
          vim.api.nvim_set_hl(0, "SnacksDashboardKey", { fg = "#228787" })     -- Your lualine teal
          vim.api.nvim_set_hl(0, "SnacksDashboardDesc", { fg = "#1a6b6b" })    -- Darker variant
          vim.api.nvim_set_hl(0, "SnacksDashboardIcon", { fg = "#228787" })    -- Your lualine teal
          vim.api.nvim_set_hl(0, "SnacksDashboardTitle", { fg = "#228787" })   -- Your lualine teal
          vim.api.nvim_set_hl(0, "SnacksDashboardFile", { fg = "#2aa3a3" })    -- Lighter variant
          vim.api.nvim_set_hl(0, "SnacksDashboardDir", { fg = "#1a6b6b" })     -- Darker variant
        end,
      })
    end,
  },
}
