return {
  -- Modern layout management for IDE-like experience
  {
    "folke/edgy.nvim",
    event = "VeryLazy",
    opts = {
      -- Auto-open layout on startup
      animate = {
        enabled = true,
        fps = 100,
        cps = 120,
      },
      wo = {
        winhighlight = "Normal:EdgyNormal,NormalNC:EdgyNormalNC,WinBar:EdgyWinBar,WinBarNC:EdgyWinBar,FloatBorder:EdgyBorder",
        signcolumn = "no",
        fillchars = "eob: ", -- Remove ugly ~ markers at end of buffer
      },
      keys = {
        -- Close all edgy windows
        ["q"] = function(win)
          win:close()
        end,
        -- Hide (close) all edgy windows
        ["<c-q>"] = function()
          require("edgy").close()
        end,
        -- Go to main window
        ["Q"] = function()
          require("edgy").goto_main()
        end,
        -- Increase width
        ["<c-Right>"] = function(win)
          win:resize("width", 2)
        end,
        -- Decrease width
        ["<c-Left>"] = function(win)
          win:resize("width", -2)
        end,
        -- Increase height
        ["<c-Up>"] = function(win)
          win:resize("height", 2)
        end,
        -- Decrease height
        ["<c-Down>"] = function(win)
          win:resize("height", -2)
        end,
      },
      bottom = {
        -- Terminal at bottom (like RStudio console)
        {
          ft = "toggleterm",
          size = { height = 0.25 },
          filter = function(buf, win)
            return vim.api.nvim_win_get_config(win).relative == ""
          end,
        },
        -- Trouble diagnostics
        {
          ft = "trouble",
          size = { height = 10 },
        },
        -- QuickFix
        { ft = "qf", title = "QuickFix" },
        -- Help
        {
          ft = "help",
          size = { height = 20 },
          filter = function(buf)
            return vim.bo[buf].buftype == "help"
          end,
        },
      },
      left = {
        -- File explorer (like RStudio files panel)
        {
          title = "Files",
          ft = "neo-tree",
          filter = function(buf)
            return vim.b[buf].neo_tree_source == "filesystem"
          end,
          size = { height = 0.4, width = 40 },
          wo = {
            fillchars = "eob: ", -- Clean appearance
          },
        },
        -- Outline/symbols (like RStudio environment panel)
        {
          title = "Outline",
          ft = "Outline",
          size = { height = 0.3 },
          filter = function(buf, win)
            return vim.bo[buf].filetype == "Outline"
          end,
          wo = {
            fillchars = "eob: ", -- Clean appearance
          },
        },
        -- Test runner panel (like RStudio test panel)
        {
          title = "Tests",
          ft = "neotest-summary",
          size = { height = 0.3 },
          wo = {
            fillchars = "eob: ", -- Clean appearance
          },
        },
      },
      right = {
        -- Git status
        {
          title = "Git",
          ft = "fugitive",
          size = { width = 0.3 },
        },
        -- Diffview file panel
        {
          title = "Diff Files",
          ft = "DiffviewFiles",
          size = { width = 0.2 },
        },
        -- Database UI (if using)
        {
          title = "DB",
          ft = "dbui",
          size = { width = 0.2 },
        },
      },
    },
  },

  -- Better terminal integration (like RStudio console)
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    keys = {
      { "<leader>tt", "<cmd>ToggleTerm<cr>", desc = "Toggle terminal" },
      { "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", desc = "Floating terminal" },
      { "<leader>tr", "<cmd>ToggleTerm direction=horizontal size=15<cr>", desc = "REPL terminal" },
    },
    config = function()
      require("toggleterm").setup({
        size = function(term)
          if term.direction == "horizontal" then
            return 15
          elseif term.direction == "vertical" then
            return vim.o.columns * 0.4
          end
        end,
        open_mapping = [[<c-\>]],
        direction = "horizontal",
        persist_size = true,
        start_in_insert = true,
        shell = vim.o.shell,
        float_opts = {
          border = "rounded",
          winblend = 0,
        },
      })
    end,
  },

  -- File tree with better integration
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cmd = "Neotree",
    keys = {
      { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Toggle file explorer" },
      { "<leader>E", "<cmd>Neotree focus<cr>", desc = "Focus file explorer" },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    config = function()
      local image_exts = { png = true, jpg = true, jpeg = true, gif = true, bmp = true, webp = true, svg = true, ico = true, tiff = true, tif = true }

      local function is_image(path)
        local ext = path:match("%.(%w+)$")
        return ext and image_exts[ext:lower()] or false
      end

      local function open_image_float(path)
        -- Read image dimensions to size the float proportionally
        local max_cols = math.floor(vim.o.columns * 0.8)
        local max_rows = math.floor(vim.o.lines * 0.8)
        local width, height = max_cols, max_rows

        local out = vim.fn.system({ "magick", "identify", "-format", "%w %h", path })
        if vim.v.shell_error == 0 then
          local img_w, img_h = out:match("(%d+) (%d+)")
          if img_w and img_h then
            img_w, img_h = tonumber(img_w), tonumber(img_h)
            -- Query actual terminal cell dimensions from snacks
            local term = Snacks.image.terminal.size()
            local cell_ratio = term.cell_height / term.cell_width
            local aspect = (img_w / img_h) * cell_ratio
            if aspect > max_cols / max_rows then
              -- Image is wider than available space
              width = max_cols
              height = math.floor(max_cols / aspect)
            else
              -- Image is taller than available space
              height = max_rows
              width = math.floor(max_rows * aspect)
            end
          end
        end

        local buf = vim.api.nvim_create_buf(false, true)
        local win = vim.api.nvim_open_win(buf, true, {
          relative = "editor",
          width = width,
          height = height,
          row = math.floor((vim.o.lines - height) / 2),
          col = math.floor((vim.o.columns - width) / 2),
          style = "minimal",
          border = "rounded",
          title = " " .. vim.fn.fnamemodify(path, ":t") .. " ",
          title_pos = "center",
        })
        Snacks.image.buf.attach(buf, { src = path })
        local function close()
          if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
          end
        end
        vim.keymap.set("n", "q", close, { buffer = buf, nowait = true })
        vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true })
      end

      -- Open file in the main editing window, not in neo-tree's window
      local function open_in_main_window(state)
        local node = state.tree:get_node()
        if node.type == "directory" then
          require("neo-tree.sources.filesystem.commands").toggle_node(state)
          return
        end
        if node.type ~= "file" then
          return
        end
        local path = node:get_id()
        if is_image(path) then
          open_image_float(path)
          return
        end
        -- Load the buffer, then directly assign it to the main window
        -- using nvim_win_set_buf to avoid edgy's autocmd-based layout restoration
        local buf = vim.fn.bufadd(path)
        vim.fn.bufload(buf)
        vim.schedule(function()
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
              vim.api.nvim_win_set_buf(win, buf)
              vim.api.nvim_set_current_win(win)
              vim.bo[buf].buflisted = true
              vim.cmd("doautocmd BufWinEnter")
              return
            end
          end
        end)
      end

      require("neo-tree").setup({
        close_if_last_window = false,
        popup_border_style = "rounded",
        enable_git_status = true,
        enable_diagnostics = true,
        use_popups_for_input = false,
        open_files_in_last_window = true,
        open_files_do_not_replace_types = { "terminal", "Trouble", "trouble", "qf", "edgy", "Outline" },
        window = {
          position = "left",
          width = 30,
          mapping_options = {
            noremap = true,
            nowait = true,
          },
        },
        default_component_configs = {
          name = {
            use_git_status_colors = false,
            highlight = "NeoTreeFileName",
          },
          container = {
            enable_character_fade = true,
          },
          indent = {
            indent_size = 2,
            padding = 1,
            with_markers = true,
            indent_marker = "│",
            last_indent_marker = "└",
            highlight = "NeoTreeIndentMarker",
          },
          icon = {
            folder_closed = "",
            folder_open = "",
            folder_empty = "󰜌",
            default = "*",
          },
          git_status = {
            symbols = {
              added = "A",
              modified = "M",
              deleted = "D",
              renamed = "R",
              untracked = "U",
              ignored = "I",
              unstaged = "",
              staged = "",
              conflict = "~",
            },
          },
        },
        filesystem = {
          follow_current_file = { enabled = true, leave_dirs_open = true },
          use_libuv_file_watcher = true,
          filtered_items = {
            visible = false,
            hide_dotfiles = true,
            hide_gitignored = true,
          },
          window = {
            mappings = {
              ["<cr>"] = open_in_main_window,
              ["<2-LeftMouse>"] = open_in_main_window,
              ["o"] = open_in_main_window,
              ["<bs>"] = "navigate_up",
              ["."] = "set_root",
              ["H"] = function(state)
                local filters = state.filtered_items or {}
                local show = filters.hide_dotfiles or filters.hide_gitignored
                filters.hide_dotfiles = not show
                filters.hide_gitignored = not show
                filters.visible = show
                require("neo-tree.sources.manager").refresh(state.name)
              end,
              ["/"] = "fuzzy_finder",
              ["f"] = "filter_on_submit",
              ["<c-x>"] = "clear_filter",
              ["<c-r>"] = "refresh",
            },
          },
        },
      })

      -- Swap neo-tree CursorLine: Adwaita blue when unfocused (marks current file),
      -- subtle when focused (normal navigation)
      local neotree_augroup = vim.api.nvim_create_augroup("NeoTreeCursorHighlight", { clear = true })
      vim.api.nvim_create_autocmd("WinLeave", {
        group = neotree_augroup,
        callback = function()
          if vim.bo.filetype == "neo-tree" then
            local is_dark = vim.o.background == "dark"
            vim.api.nvim_set_option_value(
              "winhighlight",
              "CursorLine:NeoTreeCursorLineUnfocused",
              { win = 0 }
            )
            vim.api.nvim_set_hl(0, "NeoTreeCursorLineUnfocused", {
              bg = is_dark and "#1c71d8" or "#99c1f1",
              bold = true,
            })
          end
        end,
      })
      vim.api.nvim_create_autocmd("WinEnter", {
        group = neotree_augroup,
        callback = function()
          if vim.bo.filetype == "neo-tree" then
            vim.api.nvim_set_option_value("winhighlight", "", { win = 0 })
          end
        end,
      })

      -- Theme-aware folder/file name colors
      local function set_neotree_highlights()
        local is_dark = vim.o.background == "dark"
        vim.api.nvim_set_hl(0, "NeoTreeDirectoryName", {
          fg = is_dark and "#569cd6" or "#1c71d8",
          bg = "NONE",
        })
        vim.api.nvim_set_hl(0, "NeoTreeFileName", {
          fg = is_dark and "#ffffff" or "#2e3436",
          bg = "NONE",
        })
        vim.api.nvim_set_hl(0, "NeoTreeFileNameOpened", {
          fg = is_dark and "#ffffff" or "#2e3436",
          bg = "NONE",
        })
      end

      set_neotree_highlights()
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = function()
          set_neotree_highlights()
        end,
      })
    end,
  },

  -- Code outline/symbols (like RStudio environment)
  {
    "hedyhli/outline.nvim",
    cmd = { "Outline", "OutlineOpen" },
    keys = {
      { "<leader>s", "<cmd>Outline<CR>", desc = "Toggle outline" },
    },
    config = function()
      require("outline").setup({
        outline_window = {
          position = "right",
          width = 25,
          relative_width = true,
          auto_close = false,
          -- Prevent buffer conflicts
          auto_jump = false,
          jump_highlight_duration = 300,
        },
        outline_items = {
          highlight_hovered_item = true,
          show_symbol_details = true,
          auto_set_cursor = true,
        },
        -- Better buffer handling
        provider_selector = nil,
        symbols = {
          filter = {
            "Class",
            "Constructor",
            "Enum",
            "Field",
            "Function",
            "Interface",
            "Method",
            "Module",
            "Namespace",
            "Package",
            "Property",
            "Struct",
            "Trait",
          },
        },
        preview_window = {
          border = "rounded",
        },
      })
    end,
    init = function()
      -- Custom highlight groups for subtle edgy panel styling
      local function setup_edgy_highlights()
        local is_dark = vim.o.background == "dark"

        -- Remove background highlighting - use same as normal
        vim.api.nvim_set_hl(0, "EdgyNormal", {
          bg = "NONE",
          fg = "NONE",
        })
        vim.api.nvim_set_hl(0, "EdgyNormalNC", {
          bg = "NONE",
          fg = "NONE",
        })

        -- Subtle title bar styling instead of full background
        vim.api.nvim_set_hl(0, "EdgyWinBar", {
          bg = "NONE",
          fg = is_dark and "#569cd6" or "#1c71d8", -- Adwaita blue
          bold = true,
        })
        vim.api.nvim_set_hl(0, "EdgyTitle", {
          bg = "NONE",
          fg = is_dark and "#569cd6" or "#1c71d8", -- Adwaita blue
          bold = true,
        })

        -- Optional: subtle border for active panels
        vim.api.nvim_set_hl(0, "EdgyBorder", {
          bg = "NONE",
          fg = is_dark and "#404040" or "#d0d0d0",
        })
      end

      -- Setup highlights after colorscheme loads
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = setup_edgy_highlights,
      })

      -- Setup highlights on startup
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          vim.defer_fn(setup_edgy_highlights, 100)
        end,
      })
    end,
  },

  -- Beautiful Git diff viewer
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles", "DiffviewRefresh" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Open Diffview" },
      { "<leader>gD", "<cmd>DiffviewOpen HEAD~1<cr>", desc = "Diff against last commit" },
      { "<leader>gh", "<cmd>DiffviewFileHistory<cr>", desc = "File history" },
      { "<leader>gH", "<cmd>DiffviewFileHistory %<cr>", desc = "Current file history" },
      { "<leader>gc", "<cmd>DiffviewClose<cr>", desc = "Close Diffview" },
    },
    config = function()
      require("diffview").setup({
        diff_binaries = false,
        enhanced_diff_hl = true,
        git_cmd = { "git" },
        hg_cmd = { "hg" },
        use_icons = true,
        show_help_hints = true,
        watch_index = true,
        icons = {
          folder_closed = "",
          folder_open = "",
        },
        signs = {
          fold_closed = "",
          fold_open = "",
          done = "✓",
        },
        view = {
          default = {
            layout = "diff2_horizontal",
            disable_diagnostics = true,
            winbar_info = false,
          },
          merge_tool = {
            layout = "diff3_horizontal",
            disable_diagnostics = true,
            winbar_info = true,
          },
          file_history = {
            layout = "diff2_horizontal",
            disable_diagnostics = true,
            winbar_info = false,
          },
        },
        file_panel = {
          listing_style = "tree",
          tree_options = {
            flatten_dirs = true,
            folder_statuses = "only_folded",
          },
          win_config = {
            position = "left",
            width = 35,
            win_opts = {},
          },
        },
        file_history_panel = {
          log_options = {
            git = {
              single_file = {
                diff_merges = "combined",
              },
              multi_file = {
                diff_merges = "first-parent",
              },
            },
          },
          win_config = {
            position = "bottom",
            height = 16,
            win_opts = {},
          },
        },
        commit_log_panel = {
          win_config = {
            win_opts = {},
          },
        },
        default_args = {
          DiffviewOpen = {},
          DiffviewFileHistory = {},
        },
        hooks = {
          diff_buf_win_enter = function(bufnr, winid, ctx)
            -- Theme-aware background-based diff colors that preserve syntax highlighting
            local is_dark = vim.o.background == "dark"
            local colors
            if is_dark then
              colors = {
                add = "#144212", -- dark green bg
                del = "#441414", -- dark red bg
                change = "#1a3a5c", -- dark blue bg
                text = "#2a4a7c", -- medium blue bg
              }
            else
              colors = {
                add = "#e7f6e7", -- light pastel green
                del = "#fde8e8", -- light pastel red
                change = "#e6f0fa", -- light pastel blue
                text = "#d6e6ff", -- slightly stronger blue for changed text
              }
            end

            vim.api.nvim_set_hl(0, "DiffAdd", { bg = colors.add, fg = "NONE" })
            vim.api.nvim_set_hl(0, "DiffDelete", { bg = colors.del, fg = "NONE" })
            vim.api.nvim_set_hl(0, "DiffChange", { bg = colors.change, fg = "NONE" })
            vim.api.nvim_set_hl(0, "DiffText", { bg = colors.text, fg = "NONE" })
          end,
          diff_buf_read = function(bufnr)
            -- Change local options in diff buffers
            vim.opt_local.wrap = false
            vim.opt_local.list = false
            vim.opt_local.colorcolumn = { 80 }
          end,
          view_opened = function(view)
            vim.notify(string.format("Opened %s", view.class:name()), vim.log.levels.INFO)
          end,
        },
        keymaps = {
          disable_defaults = false,
          view = {
            -- Custom keymaps for diff view
            {
              "n",
              "<tab>",
              require("diffview.actions").select_next_entry,
              { desc = "Open the diff for the next file" },
            },
            {
              "n",
              "<s-tab>",
              require("diffview.actions").select_prev_entry,
              { desc = "Open the diff for the previous file" },
            },
            { "n", "gf", require("diffview.actions").goto_file, { desc = "Open the file in the previous tabpage" } },
            {
              "n",
              "<C-w><C-f>",
              require("diffview.actions").goto_file_split,
              { desc = "Open the file in a new split" },
            },
            { "n", "<C-w>gf", require("diffview.actions").goto_file_tab, { desc = "Open the file in a new tabpage" } },
            { "n", "<leader>e", require("diffview.actions").focus_files, { desc = "Bring focus to the file panel" } },
            { "n", "<leader>b", require("diffview.actions").toggle_files, { desc = "Toggle the file panel." } },
            { "n", "g<C-x>", require("diffview.actions").cycle_layout, { desc = "Cycle through available layouts." } },
            {
              "n",
              "[x",
              require("diffview.actions").prev_conflict,
              { desc = "In the merge-tool: jump to the previous conflict" },
            },
            {
              "n",
              "]x",
              require("diffview.actions").next_conflict,
              { desc = "In the merge-tool: jump to the next conflict" },
            },
            {
              "n",
              "<leader>co",
              require("diffview.actions").conflict_choose("ours"),
              { desc = "Choose the OURS version of a conflict" },
            },
            {
              "n",
              "<leader>ct",
              require("diffview.actions").conflict_choose("theirs"),
              { desc = "Choose the THEIRS version of a conflict" },
            },
            {
              "n",
              "<leader>cb",
              require("diffview.actions").conflict_choose("base"),
              { desc = "Choose the BASE version of a conflict" },
            },
            {
              "n",
              "<leader>ca",
              require("diffview.actions").conflict_choose("all"),
              { desc = "Choose all the versions of a conflict" },
            },
            { "n", "dx", require("diffview.actions").conflict_choose("none"), { desc = "Delete the conflict region" } },
          },
          diff1 = {
            -- Mappings in single pane diff layouts
            { "n", "g?", require("diffview.actions").help({ "view", "diff1" }), { desc = "Open the help panel" } },
          },
          diff2 = {
            -- Mappings in 2-way diff layouts
            { "n", "g?", require("diffview.actions").help({ "view", "diff2" }), { desc = "Open the help panel" } },
          },
          diff3 = {
            -- Mappings in 3-way diff layouts
            { "n", "g?", require("diffview.actions").help({ "view", "diff3" }), { desc = "Open the help panel" } },
          },
          diff4 = {
            -- Mappings in 4-way diff layouts
            { "n", "g?", require("diffview.actions").help({ "view", "diff4" }), { desc = "Open the help panel" } },
          },
          file_panel = {
            { "n", "j", require("diffview.actions").next_entry, { desc = "Bring the cursor to the next file entry" } },
            {
              "n",
              "<down>",
              require("diffview.actions").next_entry,
              { desc = "Bring the cursor to the next file entry" },
            },
            {
              "n",
              "k",
              require("diffview.actions").prev_entry,
              { desc = "Bring the cursor to the previous file entry" },
            },
            {
              "n",
              "<up>",
              require("diffview.actions").prev_entry,
              { desc = "Bring the cursor to the previous file entry" },
            },
            {
              "n",
              "<cr>",
              require("diffview.actions").select_entry,
              { desc = "Open the diff for the selected entry" },
            },
            { "n", "o", require("diffview.actions").select_entry, { desc = "Open the diff for the selected entry" } },
            { "n", "l", require("diffview.actions").select_entry, { desc = "Open the diff for the selected entry" } },
            {
              "n",
              "<2-LeftMouse>",
              require("diffview.actions").select_entry,
              { desc = "Open the diff for the selected entry" },
            },
            {
              "n",
              "-",
              require("diffview.actions").toggle_stage_entry,
              { desc = "Stage / unstage the selected entry" },
            },
            { "n", "S", require("diffview.actions").stage_all, { desc = "Stage all entries" } },
            { "n", "U", require("diffview.actions").unstage_all, { desc = "Unstage all entries" } },
            {
              "n",
              "X",
              require("diffview.actions").restore_entry,
              { desc = "Restore entry to the state on the left side" },
            },
            { "n", "L", require("diffview.actions").open_commit_log, { desc = "Open the commit log panel" } },
            { "n", "zo", require("diffview.actions").open_fold, { desc = "Expand fold" } },
            { "n", "h", require("diffview.actions").close_fold, { desc = "Collapse fold" } },
            { "n", "zc", require("diffview.actions").close_fold, { desc = "Collapse fold" } },
            { "n", "za", require("diffview.actions").toggle_fold, { desc = "Toggle fold" } },
            { "n", "zR", require("diffview.actions").open_all_folds, { desc = "Expand all folds" } },
            { "n", "zM", require("diffview.actions").close_all_folds, { desc = "Collapse all folds" } },
            { "n", "<c-b>", require("diffview.actions").scroll_view(-0.25), { desc = "Scroll the view up" } },
            { "n", "<c-f>", require("diffview.actions").scroll_view(0.25), { desc = "Scroll the view down" } },
            {
              "n",
              "<tab>",
              require("diffview.actions").select_next_entry,
              { desc = "Open the diff for the next file" },
            },
            {
              "n",
              "<s-tab>",
              require("diffview.actions").select_prev_entry,
              { desc = "Open the diff for the previous file" },
            },
            { "n", "gf", require("diffview.actions").goto_file, { desc = "Open the file in the previous tabpage" } },
            {
              "n",
              "<C-w><C-f>",
              require("diffview.actions").goto_file_split,
              { desc = "Open the file in a new split" },
            },
            { "n", "<C-w>gf", require("diffview.actions").goto_file_tab, { desc = "Open the file in a new tabpage" } },
            {
              "n",
              "i",
              require("diffview.actions").listing_style,
              { desc = "Toggle between 'list' and 'tree' views" },
            },
            {
              "n",
              "f",
              require("diffview.actions").toggle_flatten_dirs,
              { desc = "Flatten empty subdirectories in tree listing style" },
            },
            {
              "n",
              "R",
              require("diffview.actions").refresh_files,
              { desc = "Update stats and entries in the file list" },
            },
            { "n", "<leader>e", require("diffview.actions").focus_files, { desc = "Bring focus to the file panel" } },
            { "n", "<leader>b", require("diffview.actions").toggle_files, { desc = "Toggle the file panel" } },
            { "n", "g<C-x>", require("diffview.actions").cycle_layout, { desc = "Cycle through available layouts" } },
            { "n", "[x", require("diffview.actions").prev_conflict, { desc = "Go to the previous conflict" } },
            { "n", "]x", require("diffview.actions").next_conflict, { desc = "Go to the next conflict" } },
            { "n", "g?", require("diffview.actions").help("file_panel"), { desc = "Open the help panel" } },
            { "n", "<esc>", require("diffview.actions").close, { desc = "Close diffview" } },
          },
          file_history_panel = {
            { "n", "g!", require("diffview.actions").options, { desc = "Open the option panel" } },
            {
              "n",
              "<C-A-d>",
              require("diffview.actions").open_in_diffview,
              { desc = "Open the entry under the cursor in a diffview" },
            },
            {
              "n",
              "y",
              require("diffview.actions").copy_hash,
              { desc = "Copy the commit hash of the entry under the cursor" },
            },
            { "n", "L", require("diffview.actions").open_commit_log, { desc = "Show commit details" } },
            { "n", "zR", require("diffview.actions").open_all_folds, { desc = "Expand all folds" } },
            { "n", "zM", require("diffview.actions").close_all_folds, { desc = "Collapse all folds" } },
            { "n", "j", require("diffview.actions").next_entry, { desc = "Bring the cursor to the next file entry" } },
            {
              "n",
              "<down>",
              require("diffview.actions").next_entry,
              { desc = "Bring the cursor to the next file entry" },
            },
            {
              "n",
              "k",
              require("diffview.actions").prev_entry,
              { desc = "Bring the cursor to the previous file entry" },
            },
            {
              "n",
              "<up>",
              require("diffview.actions").prev_entry,
              { desc = "Bring the cursor to the previous file entry" },
            },
            {
              "n",
              "<cr>",
              require("diffview.actions").select_entry,
              { desc = "Open the diff for the selected entry" },
            },
            { "n", "o", require("diffview.actions").select_entry, { desc = "Open the diff for the selected entry" } },
            {
              "n",
              "<2-LeftMouse>",
              require("diffview.actions").select_entry,
              { desc = "Open the diff for the selected entry" },
            },
            { "n", "<c-b>", require("diffview.actions").scroll_view(-0.25), { desc = "Scroll the view up" } },
            { "n", "<c-f>", require("diffview.actions").scroll_view(0.25), { desc = "Scroll the view down" } },
            {
              "n",
              "<tab>",
              require("diffview.actions").select_next_entry,
              { desc = "Open the diff for the next file" },
            },
            {
              "n",
              "<s-tab>",
              require("diffview.actions").select_prev_entry,
              { desc = "Open the diff for the previous file" },
            },
            { "n", "gf", require("diffview.actions").goto_file, { desc = "Open the file in the previous tabpage" } },
            {
              "n",
              "<C-w><C-f>",
              require("diffview.actions").goto_file_split,
              { desc = "Open the file in a new split" },
            },
            { "n", "<C-w>gf", require("diffview.actions").goto_file_tab, { desc = "Open the file in a new tabpage" } },
            { "n", "<leader>e", require("diffview.actions").focus_files, { desc = "Bring focus to the file panel" } },
            { "n", "<leader>b", require("diffview.actions").toggle_files, { desc = "Toggle the file panel" } },
            { "n", "g<C-x>", require("diffview.actions").cycle_layout, { desc = "Cycle through available layouts" } },
            { "n", "g?", require("diffview.actions").help("file_history_panel"), { desc = "Open the help panel" } },
            { "n", "<esc>", require("diffview.actions").close, { desc = "Close diffview" } },
          },
          option_panel = {
            { "n", "<tab>", require("diffview.actions").select_entry, { desc = "Change the current option" } },
            { "n", "q", require("diffview.actions").close, { desc = "Close the option panel" } },
            { "n", "<esc>", require("diffview.actions").close, { desc = "Close diffview" } },
          },
        },
      })
    end,
  },
}
