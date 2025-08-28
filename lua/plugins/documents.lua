-- Document authoring and note-taking tools
-- Quarto, Obsidian, and embedded code support

return {
  -- Markview.nvim for beautiful markdown rendering
  {
    "OXY2DEV/markview.nvim",
    lazy = false, -- Plugin handles its own lazy loading
    priority = 10000, -- Very high priority to load before treesitter
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("markview").setup({
        -- Experimental settings
        experimental = {
          check_rtp_message = false, -- Hide the runtime path warning message
        },

        -- Preview configuration
        preview = {
          filetypes = { "markdown", "quarto", "rmd" }, -- Moved from top level
          modes = { "n", "no", "c" }, -- Normal, operator-pending, command modes
          hybrid_modes = { "n" },     -- Partial rendering in normal mode
          ignore_buftypes = { "nofile", "terminal" }, -- Buffer types to ignore
          callbacks = {
            on_enable = function()
              -- Disable conflicting plugins temporarily
              vim.cmd("TSBufDisable highlight") -- Avoid conflicts
            end,
            on_disable = function()
              -- Re-enable when markview is disabled
              vim.cmd("TSBufEnable highlight")
            end,
          },
        },
      })

      -- Keybindings for markview
      vim.keymap.set("n", "<leader>mv", ":Markview toggleAll<CR>", { desc = "Toggle Markview" })
      vim.keymap.set("n", "<leader>ms", ":Markview splitToggle<CR>", { desc = "Markview split toggle" })
    end,
  },
  -- Obsidian notes (community fork)
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*", -- Use latest stable release
    event = {
      "BufReadPre " .. vim.fn.expand("~") .. "/Documents/Obsidian-Notes/**.md",
      "BufNewFile " .. vim.fn.expand("~") .. "/Documents/Obsidian-Notes/**.md",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "hrsh7th/nvim-cmp",
      "nvim-telescope/telescope.nvim", -- For picker functionality
    },
    config = function()
      require("obsidian").setup({
        workspaces = {
          {
            name = "notes",
            path = "~/Documents/Obsidian-Notes",
          },
        },
        
        -- Enhanced completion configuration
        completion = {
          nvim_cmp = true,
          min_chars = 2,
          new_notes_location = "current_dir",
        },
        
        -- Picker configuration (uses telescope by default)
        picker = {
          name = "telescope.nvim",
          mappings = {
            new = "<C-x>", -- Create new note
            insert_link = "<C-l>", -- Insert link to note
          },
        },
        
        -- Daily notes configuration (matches your existing structure)
        daily_notes = {
          folder = "Daily Log",
          date_format = "%Y-%m-%d",
          alias_format = "%B %d, %Y",
        },
        
        -- UI configuration - keep disabled for markview compatibility
        ui = {
          enable = false, -- Let markview handle rendering
          update_debounce = 200,
          checkboxes = {},
        },
        
        -- Attachment configuration (matches your _images pattern)
        attachments = {
          img_folder = "_images",
        },
        
        -- Note path and ID generation
        note_id_func = function(title)
          local suffix = ""
          if title ~= nil then
            suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
          else
            for _ = 1, 4 do
              suffix = suffix .. string.char(math.random(65, 90))
            end
          end
          return tostring(os.date("%Y-%m-%d")) .. "_" .. suffix
        end,
        
        -- Template configuration (matches your existing Templates folder)
        templates = {
          subdir = "Templates",
          date_format = "%Y-%m-%d",
          time_format = "%H:%M",
        },
      })

      -- Enhanced Obsidian keymaps
      vim.keymap.set("n", "gf", function()
        if require("obsidian").util.cursor_on_markdown_link() then
          return "<cmd>ObsidianFollowLink<CR>"
        else
          return "gf"
        end
      end, { noremap = false, expr = true, desc = "Follow Obsidian link" })
      
      -- Additional useful keymaps
      vim.keymap.set("n", "<leader>oc", "<cmd>ObsidianTOC<CR>", { desc = "Obsidian TOC" })
      vim.keymap.set("n", "<leader>ob", "<cmd>ObsidianBacklinks<CR>", { desc = "Obsidian backlinks" })
      vim.keymap.set("n", "<leader>ot", "<cmd>ObsidianTags<CR>", { desc = "Obsidian tags" })
      vim.keymap.set("n", "<leader>on", "<cmd>ObsidianNew<CR>", { desc = "New Obsidian note" })
      vim.keymap.set("n", "<leader>os", "<cmd>ObsidianSearch<CR>", { desc = "Search Obsidian notes" })
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
}
