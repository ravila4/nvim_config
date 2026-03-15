return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      -- Beautiful animated notifications
      notifier = {
        enabled = true,
        timeout = 5000,
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
        disable_move = true,
        preset = {
          keys = {
            { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
            { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
            { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
          },
          header = [[

 ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
 ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
 ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
 ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
 ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
 ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
]],
        },
        sections = {
          { section = "header", hl = "SnacksDashboardHeader" },
          { section = "keys", gap = 0, padding = 1 },
          {
            pane = 2,
            icon = " ",
            title = "Recent Files",
            section = "recent_files",
            indent = 2,
            padding = 1,
            limit = 10,
          },
          { pane = 2, icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1, limit = 10 },
          { section = "startup" },
        },
      },

      -- Zen mode for focused coding
      zen = {
        enabled = true,
        toggles = {
          dim = false, -- Disable built-in dimming
          git_signs = false, -- Hide git signs
          diagnostics = false, -- Hide diagnostics
          inlay_hints = false, -- Hide inlay hints
          indent = false, -- Hide indent guides
          statuscolumn = false, -- Hide status column
        },
        show = {
          statusline = false, -- Hide statusline
          tabline = false, -- Hide tabline
        },
        win = {
          enter = true,
          fixbuf = false,
          minimal = false,
          width = 120,
          height = 0,
          backdrop = { transparent = true, blend = 40 },
          keys = { q = false },
          zindex = 40,
          wo = {
            winhighlight = "NormalFloat:Normal",
          },
          w = {
            snacks_main = true,
          },
        },
        on_open = function()
          vim.opt.wrap = true -- Enable word wrap in zen mode
        end,
        on_close = function()
          vim.opt.wrap = false -- Restore no wrap when exiting zen
        end,
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

      -- Image display for markdown/quarto (hover-only, no inline rendering)
      image = {
        enabled = true,
        backend = "kitty",
        doc = {
          inline = false, -- Don't render images inline (causes scroll jank)
          float = false, -- Don't auto-float either
        },
        max_width = 120,
        max_height_window_percentage = 50,
        -- Image scaling and conversion options
        convert = {
          magick = {
            default = { "{src}", "-scale", "1920x1080>", "-quality", "85" }, -- Scale down large images
            vector = { "-density", 300, "{src}[0]" }, -- Higher quality SVG rendering
          },
        },
        -- Auto-resize to handle window changes and scrolling
        auto_resize = true,
        -- LaTeX math rendering support
        math = {
          enabled = false, -- Disable to avoid conflicts with markview LaTeX rendering
        },
        -- Custom path resolution for Obsidian vault images
        resolve = function(file, src)
          local obsidian_vault = vim.fn.expand("~/Documents/Obsidian-Notes")
          -- Only apply custom resolution for files in Obsidian vault
          if file:match(vim.pesc(obsidian_vault)) then
            -- If src is just a filename, use find to locate it
            if not src:find("/") and not src:find("\\") then
              local handle =
                io.popen('find "' .. obsidian_vault .. '" -name "' .. src .. '" -type f 2>/dev/null | head -1')
              if handle then
                local found_path = handle:read("*l")
                handle:close()
                if found_path and found_path ~= "" and vim.fn.filereadable(found_path) == 1 then
                  return found_path
                end
              end
            end
          end
          -- Return nil to use default resolution
          return nil
        end,
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

      -- Big file handling for better performance
      bigfile = {
        enabled = true,
        notify = true, -- Show notification when big file detected
        size = 1.5 * 1024 * 1024, -- 1.5MB threshold
        -- Features to disable for big files
        setup = function(ctx)
          vim.cmd("syntax clear")
          vim.opt_local.foldmethod = "manual"
          vim.opt_local.spell = false
          vim.opt_local.swapfile = false
          vim.opt_local.undofile = false
          vim.opt_local.breakindent = false
          vim.opt_local.colorcolumn = ""
          vim.opt_local.statuscolumn = ""
          vim.opt_local.signcolumn = "no"
          vim.opt_local.foldcolumn = "0"
          vim.opt_local.winbar = ""
        end,
      },
    },
    keys = {
      {
        "<leader>z",
        function()
          Snacks.zen()
        end,
        desc = "Toggle Zen Mode",
      },
      {
        "<leader>Z",
        function()
          Snacks.zen.zoom()
        end,
        desc = "Toggle Zoom",
      },
      {
        "<leader>.",
        function()
          Snacks.scratch()
        end,
        desc = "Toggle Scratch Buffer",
      },
      {
        "<leader>S",
        function()
          Snacks.scratch.select()
        end,
        desc = "Select Scratch Buffer",
      },
      {
        "<leader>n",
        function()
          Snacks.notifier.show_history()
        end,
        desc = "Notification History",
      },
      {
        "<leader>bd",
        function()
          Snacks.bufdelete()
        end,
        desc = "Delete Buffer",
      },
      {
        "<leader>cR",
        function()
          Snacks.rename.rename_file()
        end,
        desc = "Rename File",
      },
      {
        "<leader>gB",
        function()
          Snacks.git.blame_line()
        end,
        desc = "Git Blame Line",
      },
      {
        "<leader>gf",
        function()
          Snacks.lazygit.log_file()
        end,
        desc = "Lazygit Current File History",
      },
      {
        "<leader>gg",
        function()
          Snacks.lazygit()
        end,
        desc = "Lazygit",
      },
      {
        "<leader>gl",
        function()
          Snacks.lazygit.log()
        end,
        desc = "Lazygit Log (cwd)",
      },
      {
        "<leader>un",
        function()
          Snacks.notifier.hide()
        end,
        desc = "Dismiss All Notifications",
      },
      {
        "<c-/>",
        function()
          Snacks.terminal()
        end,
        desc = "Toggle Terminal",
      },
      {
        "<c-_>",
        function()
          Snacks.terminal()
        end,
        desc = "which_key_ignore",
      },
      {
        "<leader>mi",
        function()
          Snacks.image.hover()
        end,
        desc = "Preview image at cursor",
        ft = { "markdown", "quarto", "rmd" },
      },
      {
        "]]",
        function()
          Snacks.words.jump(vim.v.count1)
        end,
        desc = "Next Reference",
        mode = { "n", "t" },
      },
      {
        "[[",
        function()
          Snacks.words.jump(-vim.v.count1)
        end,
        desc = "Prev Reference",
        mode = { "n", "t" },
      },
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
          Snacks.toggle
            .option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 })
            :map("<leader>uc")
          Snacks.toggle.treesitter():map("<leader>uT")
          Snacks.toggle.option("background", { off = "light", on = "dark", name = "dark background" }):map("<leader>ub")
          Snacks.toggle.inlay_hints():map("<leader>uh")

          -- Custom dashboard colors - match lualine teal #228787
          vim.api.nvim_set_hl(0, "SnacksDashboardHeader", { fg = "#228787" }) -- Your lualine teal
          vim.api.nvim_set_hl(0, "SnacksDashboardKey", { fg = "#228787" }) -- Your lualine teal
          vim.api.nvim_set_hl(0, "SnacksDashboardDesc", { fg = "#1a6b6b" }) -- Darker variant
          vim.api.nvim_set_hl(0, "SnacksDashboardIcon", { fg = "#228787" }) -- Your lualine teal
          vim.api.nvim_set_hl(0, "SnacksDashboardTitle", { fg = "#228787" }) -- Your lualine teal
          vim.api.nvim_set_hl(0, "SnacksDashboardFile", { fg = "#2aa3a3" }) -- Lighter variant
          vim.api.nvim_set_hl(0, "SnacksDashboardDir", { fg = "#1a6b6b" }) -- Darker variant

          -- Set zen mode backdrop to match theme
          local function set_zen_backdrop()
            local bg_color = vim.o.background == "light" and "#ffffff" or "#1e1e1e"
            vim.api.nvim_set_hl(0, "SnacksBackdrop", { bg = bg_color, fg = "NONE" })
          end

          -- Set highlights for indent guides
          local function set_indent_highlights()
            local is_dark = vim.o.background == "dark"
            -- Unfocused indent guides - much lighter/subtle
            vim.api.nvim_set_hl(0, "SnacksIndent", {
              fg = is_dark and "#404040" or "#e0e0e0",
            })
            -- Regular scope guide
            vim.api.nvim_set_hl(0, "SnacksIndentScope", {
              fg = is_dark and "#404040" or "#e0e0e0",
            })
            -- Focused scope with arrow - theme-appropriate accent color
            vim.api.nvim_set_hl(0, "SnacksIndentChunk", {
              -- fg = is_dark and "#df610e" or "#df610e",
              fg = is_dark and "#569cd6" or "#1c71d8",
            })
          end

          -- Fix word highlighting for both light and dark themes
          local function set_word_highlights()
            if vim.o.background == "light" then
              -- Light theme: very subtle light background with teal underline
              vim.api.nvim_set_hl(0, "SnacksWords", { bg = "#f0f8ff", fg = "NONE", underline = true, sp = "#228787" })
              -- Try other possible highlight groups that might be used
              vim.api.nvim_set_hl(
                0,
                "LspReferenceText",
                { bg = "#f0f8ff", fg = "NONE", underline = true, sp = "#228787" }
              )
              vim.api.nvim_set_hl(
                0,
                "LspReferenceRead",
                { bg = "#f0f8ff", fg = "NONE", underline = true, sp = "#228787" }
              )
              vim.api.nvim_set_hl(
                0,
                "LspReferenceWrite",
                { bg = "#f0f8ff", fg = "NONE", underline = true, sp = "#228787" }
              )
              vim.api.nvim_set_hl(0, "CursorWord", { bg = "#f0f8ff", fg = "NONE", underline = true, sp = "#228787" })
              vim.api.nvim_set_hl(0, "MatchParen", { bg = "#f0f8ff", fg = "NONE", underline = true, sp = "#228787" })
            else
              -- Dark theme: subtle dark background with teal underline
              vim.api.nvim_set_hl(0, "SnacksWords", { bg = "#1a3a3a", fg = "NONE", underline = true, sp = "#228787" })
              vim.api.nvim_set_hl(
                0,
                "LspReferenceText",
                { bg = "#1a3a3a", fg = "NONE", underline = true, sp = "#228787" }
              )
              vim.api.nvim_set_hl(
                0,
                "LspReferenceRead",
                { bg = "#1a3a3a", fg = "NONE", underline = true, sp = "#228787" }
              )
              vim.api.nvim_set_hl(
                0,
                "LspReferenceWrite",
                { bg = "#1a3a3a", fg = "NONE", underline = true, sp = "#228787" }
              )
              vim.api.nvim_set_hl(0, "CursorWord", { bg = "#1a3a3a", fg = "NONE", underline = true, sp = "#228787" })
              vim.api.nvim_set_hl(0, "MatchParen", { bg = "#1a3a3a", fg = "NONE", underline = true, sp = "#228787" })
            end
          end

          -- Set highlights initially
          set_word_highlights()
          set_zen_backdrop()
          set_indent_highlights()

          -- Update highlights when colorscheme changes
          vim.api.nvim_create_autocmd("ColorScheme", {
            callback = function()
              set_word_highlights()
              set_zen_backdrop()
              set_indent_highlights()
            end,
          })

        end,
      })
    end,
  },
}
