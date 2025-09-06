-- Jupyter notebook and REPL integration tools
-- Dual strategy: Molten for VSCode-like experience, vim-slime for flexible REPL workflow

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

  -- Molten-nvim for VSCode-like inline Jupyter experience
  {
    "benlubas/molten-nvim",
    version = "^1.0.0", -- Use latest stable
    build = ":UpdateRemotePlugins",
    lazy = false, -- Load immediately so commands are always available
    dependencies = {
      "3rd/image.nvim", -- For inline image rendering
    },
    config = function()
      -- Global configuration
      vim.g.molten_image_provider = "image.nvim" -- Use image.nvim for inline images
      vim.g.molten_output_win_max_height = 20 -- Reasonable output window height
      vim.g.molten_auto_open_output = false -- Manual control over output
      vim.g.molten_wrap_output = true -- Wrap long outputs
      vim.g.molten_virt_text_output = true -- Show outputs as virtual text
      vim.g.molten_virt_lines_off_by_1 = true -- Better virtual line positioning

      -- Theme integration - use your teal accent
      vim.g.molten_output_crop_border = true
      vim.g.molten_output_show_more = true
      vim.g.molten_output_virt_lines = true

      -- Performance settings for bioinformatics (large outputs)
      vim.g.molten_limit_output_chars = 1000000 -- 1MB limit for large genomics outputs
      vim.g.molten_copy_output = false -- Don't auto-copy to clipboard
      
      -- Kernel selection with Telescope integration
      local function select_kernel()
        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local conf = require("telescope.config").values
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")
        
        -- Get available kernels
        local handle = io.popen("jupyter kernelspec list --json 2>/dev/null")
        if not handle then
          vim.notify("Failed to get kernel list", vim.log.levels.ERROR)
          return
        end
        
        local result = handle:read("*all")
        handle:close()
        
        if result == "" then
          vim.notify("No kernels found. Install with: python -m ipykernel install --user", vim.log.levels.WARN)
          return
        end
        
        local ok, kernels_data = pcall(vim.json.decode, result)
        if not ok or not kernels_data.kernelspecs then
          vim.notify("Failed to parse kernel list", vim.log.levels.ERROR)
          return
        end
        
        local kernels = {}
        for name, spec in pairs(kernels_data.kernelspecs) do
          table.insert(kernels, {
            name = name,
            display_name = spec.spec.display_name or name,
            language = spec.spec.language or "unknown"
          })
        end
        
        if #kernels == 0 then
          vim.notify("No kernels available", vim.log.levels.WARN)
          return
        end
        
        pickers.new({}, {
          prompt_title = "Select Jupyter Kernel",
          finder = finders.new_table({
            results = kernels,
            entry_maker = function(entry)
              return {
                value = entry.name,
                display = string.format("%s (%s)", entry.display_name, entry.language),
                ordinal = entry.display_name
              }
            end
          }),
          sorter = conf.generic_sorter({}),
          attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
              local selection = action_state.get_selected_entry()
              actions.close(prompt_bufnr)
              if selection then
                vim.cmd("MoltenInit " .. selection.value)
                vim.notify("Initialized kernel: " .. selection.display, vim.log.levels.INFO)
              end
            end)
            return true
          end,
        }):find()
      end
      
      -- Create user command for kernel selection
      vim.api.nvim_create_user_command("MoltenSelectKernel", select_kernel, { 
        desc = "Select Jupyter kernel with Telescope" 
      })

      -- Molten keybindings (unified with other Jupyter tools)
      local function map(mode, key, cmd, desc)
        vim.keymap.set(mode, key, cmd, { desc = desc, buffer = true })
      end

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "python", "julia", "r", "ipynb" },
        callback = function()
          -- Molten-specific mappings (prefix: <leader>m)
          map("n", "<leader>mi", ":MoltenInit<CR>", "[Molten] Initialize kernel")
          map("n", "<leader>mk", ":MoltenSelectKernel<CR>", "[Molten] Select kernel")
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
        backend = "kitty", -- Ghostty supports kitty graphics protocol
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

  -- Jupytext.vim for .ipynb file conversion to readable text format
  {
    "goerz/jupytext.vim",
    lazy = false, -- Must load immediately to handle .ipynb file conversion
    config = function()
      -- Basic configuration for jupytext.vim
      vim.g.jupytext_enable = 1
      vim.g.jupytext_fmt = "py:percent" -- Convert to Python with %% cell markers
      vim.g.jupytext_command = "jupytext"
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
}
