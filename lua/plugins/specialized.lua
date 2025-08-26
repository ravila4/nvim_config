return {
  -- Dependencies
  {
    "nvim-lua/plenary.nvim",
    lazy = true,
  },
  {
    "MunifTanjim/nui.nvim",
    lazy = true,
  },

  -- R language support
  {
    "jalvesaq/Nvim-R",
    ft = { "r", "rmd", "rnoweb" },
  },

  -- Jupyter notebook support
  {
    "goerz/jupytext.vim",
    ft = { "ipynb", "jupytext" },
  },

  -- Molten-nvim for VSCode-like inline Jupyter experience
  {
    "benlubas/molten-nvim",
    version = "^1.0.0", -- Use latest stable
    build = ":UpdateRemotePlugins",
    ft = { "python", "julia", "r" },
    dependencies = {
      "3rd/image.nvim", -- For inline image rendering
    },
    config = function()
      -- Global configuration
      vim.g.molten_image_provider = "image.nvim" -- Use image.nvim for inline images
      vim.g.molten_output_win_max_height = 20    -- Reasonable output window height
      vim.g.molten_auto_open_output = false      -- Manual control over output
      vim.g.molten_wrap_output = true            -- Wrap long outputs
      vim.g.molten_virt_text_output = true       -- Show outputs as virtual text
      vim.g.molten_virt_lines_off_by_1 = true    -- Better virtual line positioning

      -- Theme integration - use your teal accent
      vim.g.molten_output_crop_border = true
      vim.g.molten_output_show_more = true
      vim.g.molten_output_virt_lines = true

      -- Performance settings for bioinformatics (large outputs)
      vim.g.molten_limit_output_chars = 1000000  -- 1MB limit for large genomics outputs
      vim.g.molten_copy_output = false           -- Don't auto-copy to clipboard

      -- Molten keybindings (unified with other Jupyter tools)
      local function map(mode, key, cmd, desc)
        vim.keymap.set(mode, key, cmd, { desc = desc, buffer = true })
      end

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "python", "julia", "r" },
        callback = function()
          -- Molten-specific mappings (prefix: <leader>m)
          map("n", "<leader>mi", ":MoltenInit<CR>", "[Molten] Initialize kernel")
          map("n", "<leader>mr", ":MoltenEvaluateOperator<CR>", "[Molten] Run operator")
          map("n", "<leader>ml", ":MoltenEvaluateLine<CR>", "[Molten] Run line")
          map("n", "<leader>mc", ":MoltenReevaluateCell<CR>", "[Molten] Re-run cell")
          map("v", "<leader>mr", ":<C-u>MoltenEvaluateVisual<CR>gv", "[Molten] Run selection")
          map("n", "<leader>md", ":MoltenDelete<CR>", "[Molten] Delete cell")
          map("n", "<leader>mh", ":MoltenHideOutput<CR>", "[Molten] Hide output")
          map("n", "<leader>ms", ":MoltenShowOutput<CR>", "[Molten] Show output")
          map("n", "<leader>mq", ":MoltenDeinit<CR>", "[Molten] Quit kernel")

          -- Unified Jupyter mappings (work with any active tool)
          map("n", "<leader>jr", ":MoltenEvaluateLine<CR>", "[Unified] Run line/cell")
          map("v", "<leader>jr", ":<C-u>MoltenEvaluateVisual<CR>gv", "[Unified] Run selection")
          map("n", "<leader>ji", ":MoltenInit<CR>", "[Unified] Initialize")
        end,
      })
    end,
  },

  -- Image.nvim for inline image rendering (molten-nvim dependency)
  {
    "3rd/image.nvim",
    ft = { "python", "julia", "r", "markdown", "quarto" },
    config = function()
      require("image").setup({
        backend = "kitty", -- or "ueberzug" depending on your terminal
        integrations = {
          markdown = {
            enabled = true,
            clear_in_insert_mode = false,
            download_remote_images = true,
            only_render_image_at_cursor = false,
            filetypes = { "markdown", "vimwiki", "quarto" },
          },
        },
        max_width = nil,
        max_height = nil,
        max_width_window_percentage = nil,
        max_height_window_percentage = 50,
        window_overlap_clear_enabled = false,
        window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
      })
    end,
  },

  -- Vim-slime for terminal-based REPL workflow
  {
    "jpalardy/vim-slime",
    ft = { "python", "r", "julia", "sh", "bash" },
    dependencies = {
      "hanschen/vim-ipython-cell", -- Adds cell-based execution to vim-slime
    },
    config = function()
      -- Configure vim-slime for terminal integration
      vim.g.slime_target = "neovim" -- Use Neovim terminal
      vim.g.slime_python_ipython = 1 -- Use IPython when available
      vim.g.slime_cell_delimiter = "# %%" -- Standard Jupyter cell delimiter
      vim.g.slime_default_config = { jobid = "terminal" }

      -- Don't add newlines automatically
      vim.g.slime_bracketed_paste = 1

      -- Slime + IPython Cell keybindings
      local function map(mode, key, cmd, desc)
        vim.keymap.set(mode, key, cmd, { desc = desc, buffer = true })
      end

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "python", "r", "julia" },
        callback = function()
          -- Slime-specific mappings (prefix: <leader>s)
          map("n", "<leader>sc", ":SlimeSendCurrentLine<CR>", "[Slime] Send line")
          map("v", "<leader>sc", ":SlimeSend<CR>", "[Slime] Send selection")
          map("n", "<leader>ss", ":SlimeSend<CR>", "[Slime] Send operator")
          map("n", "<leader>st", ":SlimeConfig<CR>", "[Slime] Configure target")

          -- IPython cell mappings (unified across tools)
          map("n", "<leader>jr", ":IPythonCellExecuteCell<CR>", "[Unified] Run cell")
          map("n", "<leader>jR", ":IPythonCellExecuteCellJump<CR>", "[Unified] Run cell + jump")
          map("n", "<leader>ja", ":IPythonCellExecuteAll<CR>", "[Unified] Run all above")
          map("n", "<leader>jA", ":IPythonCellExecuteAllBelow<CR>", "[Unified] Run all below")
          map("n", "<leader>jc", ":IPythonCellClear<CR>", "[Unified] Clear terminal")
          map("n", "<leader>jn", ":IPythonCellNextCell<CR>", "[Unified] Next cell")
          map("n", "<leader>jp", ":IPythonCellPrevCell<CR>", "[Unified] Previous cell")

          -- Terminal shortcuts
          map("n", "<leader>js", ":IPythonCellRestart<CR>", "[Unified] Start/restart IPython")
          map("n", "<leader>jt", ":terminal ipython<CR>", "[Unified] Open IPython terminal")
        end,
      })
    end,
  },

  -- Jupynium for remote/secured server access
  {
    "kiyoon/jupynium.nvim",
    build = "pip3 install --user .",
    ft = { "ipynb", "python" },
    dependencies = {
      "stevearc/dressing.nvim",
    },
    config = function()
      require("jupynium").setup({
        python_host = vim.g.python3_host_prog or "python3",
        default_notebook_URL = "localhost:8888/lab", -- Use JupyterLab interface
    
        -- Auto start/attach configuration
        auto_start_server = {
          enable = false, -- Manual control for bioinformatics workflows
          file_pattern = { "*.ju.*" },
        },
        auto_attach_to_server = {
          enable = true,
          file_pattern = { "*.ju.*", "*.ipynb", "*.md" },
        },
        auto_download_ipynb = true,
     
        -- Sync configuration
        sync = {
          enable = true,
          mode = "full", -- Full sync for data analysis workflows
        },
        
        -- Performance settings
        shortsighted = false, -- Keep full notebook context for bioinformatics
        
        -- Exit handling to prevent freezing
        cleanup = {
          on_exit = true,
          timeout = 3000, -- 3 second timeout for cleanup
        },
      })

      -- Jupynium keybindings (remote server focus)
      local function map(mode, key, cmd, desc)
        vim.keymap.set(mode, key, cmd, { desc = desc, buffer = true })
      end

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "python", "ipynb" },
        callback = function(event)
          -- Only add jupynium mappings for .ju.* files or when explicitly needed
          local filename = vim.fn.expand("%:t")
          if filename:match("%.ju%.") or filename:match("%.ipynb$") then
            -- Jupynium-specific mappings (prefix: <leader>u for "UI/browser")
            map("n", "<leader>us", ":JupyniumStartAndAttachToServer<CR>", "[Jupynium] Start server")
            map("n", "<leader>ur", ":JupyniumStartSync<CR>", "[Jupynium] Start sync")
            map("n", "<leader>ud", ":JupyniumDownloadIpynb<CR>", "[Jupynium] Download notebook")
            map("n", "<leader>uc", ":JupyniumExecuteSelectedCells<CR>", "[Jupynium] Execute cells")
            map("n", "<leader>ua", ":JupyniumScrollToCell<CR>", "[Jupynium] Scroll to cell")
            map("n", "<leader>uk", ":JupyniumKernelHover<CR>", "[Jupynium] Kernel info")
            map("n", "<leader>uq", ":JupyniumStopSync<CR>", "[Jupynium] Stop sync")
 
            -- Override unified mappings for jupynium files
            map("n", "<leader>jr", ":JupyniumExecuteSelectedCells<CR>", "[Unified] Run cell (Jupynium)")
            map("n", "<leader>ji", ":JupyniumStartAndAttachToServer<CR>", "[Unified] Initialize (Jupynium)")

            -- Emergency quit mappings for jupynium files
            map("n", "<leader>qq", ":JupyniumStopSync<CR>:qa!<CR>", "[Jupynium] Force quit")
          end
        end,
      })

      -- Global emergency quit for when things freeze
      vim.keymap.set("n", "<leader>QQ", function()
        -- Force cleanup and quit
        vim.cmd("silent! MoltenDeinit")
        vim.cmd("silent! JupyniumStopSync")
        vim.cmd("qa!")
      end, { desc = "Emergency force quit" })
    end,
  },

  -- Firefox integration
  {
    "glacambre/firenvim",
    enabled = false,  -- Disabling it for now
    lazy = false,
    build = function()
      vim.fn["firenvim#install"](0)
    end,
    config = function()
      vim.g.firenvim_config = {
        globalSettings = {
          alt = "all",
        },
        localSettings = {
          [".*"] = {
            cmdline = "neovim",
            content = "text",
            priority = 0,
            selector = "textarea",
            takeover = "never",
          },
        },
      }

      -- UI adjustments for Firenvim
      local function on_ui_enter()
        vim.opt.guifont = "AndaleMono:h9"
        vim.keymap.set("n", "<space>", ":set lines=28 columns=110<CR>")

        local fontsize = 9
        local function adjust_font_size(amount)
          fontsize = fontsize + amount
          vim.opt.guifont = "AndaleMono:h" .. fontsize
          vim.fn.rpcnotify(0, "Gui", "WindowMaximized", 1)
        end
        -- Use Ctrl+= and Ctrl+- to adjust font size
        vim.keymap.set({ "n", "i" }, "<C-=>", function() adjust_font_size(1) end)
        vim.keymap.set({ "n", "i" }, "<C-->", function() adjust_font_size(-1) end)
      end

      vim.api.nvim_create_autocmd("UIEnter", {
        callback = on_ui_enter,
      })
    end,
  },

  -- Obsidian notes
  {
    "epwalsh/obsidian.nvim",
    event = {
      "BufReadPre " .. vim.fn.expand("~") .. "/Documents/Obsidian-Notes/**.md",
      "BufNewFile " .. vim.fn.expand("~") .. "/Documents/Obsidian-Notes/**.md",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "hrsh7th/nvim-cmp",
    },
    config = function()
      require("obsidian").setup({
        dir = "~/Documents/Obsidian-Notes",
        completion = {
          nvim_cmp = true,
        },
      })

      -- Obsidian keymap
      vim.keymap.set("n", "gf", function()
        if require("obsidian").util.cursor_on_markdown_link() then
          return "<cmd>ObsidianFollowLink<CR>"
        else
          return "gf"
        end
      end, { noremap = false, expr = true })
    end,
  },

  -- Otter for embedded code completion
  {
    "jmbuhr/otter.nvim",
    dependencies = {
      "hrsh7th/nvim-cmp",
      "neovim/nvim-lspconfig",
      "nvim-treesitter/nvim-treesitter",
    },
    ft = { "quarto", "markdown", "rmd" },
    config = function()
      require("otter").setup({
        lsp = {
          hover = {
            border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
          },
        },
        buffers = {
          set_filetype = true,
        },
        handle_leading_whitespace = true,
      })
    end,
  },

  -- Quarto support
  {
    "quarto-dev/quarto-nvim",
    dependencies = {
      "jmbuhr/otter.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    ft = { "quarto" },
    config = function()
      require("quarto").setup({
        debug = false,
        closePreviewOnExit = true,
        lspFeatures = {
          enabled = true,
          chunks = "curly",
          languages = { "r", "python", "julia", "bash", "html" },
          diagnostics = {
            enabled = true,
            triggers = { "BufWritePost" },
          },
          completion = {
            enabled = true,
          },
        },
        codeRunner = {
          enabled = true,
          default_method = "slime",
          ft_runners = {},
          never_run = { "yaml" },
        },
      })
    end,
  },

  -- Claude Code integration
  {
    "coder/claudecode.nvim",
    event = "VeryLazy",
    config = function()
      require("claudecode").setup({
        terminal = {
          split_side = "right",
          split_width_percentage = 0.4,
          provider = "auto",
          auto_close = true,
        },
      })
    end,
  },
}
