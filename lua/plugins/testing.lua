return {
  -- Neotest - Modern test runner for Neovim
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
      -- Python adapter
      "nvim-neotest/neotest-python",
    },
    keys = {
      { "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run Test File" },
      { "<leader>tn", function() require("neotest").run.run() end, desc = "Run Nearest Test" },
      { "<leader>ta", function() require("neotest").run.run(vim.fn.getcwd()) end, desc = "Run All Tests" },
      { "<leader>tl", function() require("neotest").run.run_last() end, desc = "Run Last Test" },
      { "<leader>ts", function() require("neotest").summary.toggle() end, desc = "Toggle Test Summary" },
      { "<leader>to", function() require("neotest").output.open({ enter = true, auto_close = true }) end, desc = "Show Test Output" },
      { "<leader>tO", function() require("neotest").output_panel.toggle() end, desc = "Toggle Test Output Panel" },
      { "<leader>tS", function() require("neotest").run.stop() end, desc = "Stop Tests" },
      { "<leader>tw", function() require("neotest").watch.toggle(vim.fn.expand("%")) end, desc = "Toggle Test Watch" },
      { "<leader>td", function() require("neotest").run.run({strategy = "dap"}) end, desc = "Debug Nearest Test" },
      -- Quick access to test output when in code
      { "<leader>te", function() 
        require("neotest").output.open({ enter = false, auto_close = false, short = false })
      end, desc = "Show Test Error Details" },
    },
    opts = {
      -- See all config options with :h neotest.Config
      discovery = {
        -- Enable discovery but with better performance and caching
        enabled = true, -- Keep discovery enabled but with caching
        -- Use more workers for faster parsing when needed
        concurrent = 4,
        -- Filter discovery to only test directories
        filter_dir = function(name, rel_path, root)
          -- Only scan directories that might contain tests
          return name ~= "node_modules" and 
                 name ~= ".git" and 
                 name ~= "__pycache__" and 
                 name ~= ".pytest_cache" and
                 name ~= ".venv" and
                 name ~= "venv"
        end,
      },
      -- Enable persistent state for caching
      state = {
        enabled = true,
      },
      -- Don't configure consumers - let neotest handle defaults
      -- consumers = {
      --   overseer = {
      --     enabled = false, -- Disable if not using overseer
      --   },
      -- },
      running = {
        -- Run tests concurrently when an adapter provides multiple commands
        concurrent = true,
      },
      summary = {
        -- Don't expand all by default for better performance
        expand_errors = false,
        follow = true,
        open = "botright vsplit | vertical resize 50",
        mappings = {
          -- Consistent with Files/Outline behavior
          expand = {"<CR>", "<2-LeftMouse>"}, -- Enter expands/collapses like Files panel
          expand_all = "E",
          jumpto = "o", -- 'o' opens/jumps to test (like vim quickfix)
          output = "O", -- 'O' shows test output
          short = "s",
          attach = "a",
          run = "r",
          debug = "d", 
          run_marked = "R",
          debug_marked = "D",
          clear_marked = "M",
          target = "t",
          clear_target = "T",
          next_failed = "J",
          prev_failed = "K",
          mark = "m",
          stop = "u"
        },
      },
      -- Enable status signs in the gutter
      status = {
        enabled = true,
        signs = true,
        virtual_text = false,
      },
      -- Configure diagnostic display
      diagnostic = {
        enabled = true,
        severity = vim.diagnostic.severity.ERROR,
      },
      -- Enable floating output for better readability
      output = {
        enabled = true,
        open_on_run = "short",
      },
      -- Configure floating output window with rounded borders
      floating = {
        border = "rounded",
        max_height = 0.6,
        max_width = 0.6,
      },
      -- Configure floating output window
      output_panel = {
        enabled = true,
        open = "botright split | resize 15",
      },
      -- Make sure jumping works properly
      jump = {
        enabled = true,
      },
      -- Enable quickfix integration
      quickfix = {
        enabled = true,
        open = false,
      },
    },
    config = function(_, opts)
      -- get neotest namespace (api call creates or returns namespace)
      local neotest_ns = vim.api.nvim_create_namespace("neotest")
      vim.diagnostic.config({
        virtual_text = {
          format = function(diagnostic)
            local message = diagnostic.message:gsub("\n", " "):gsub("\t", " "):gsub("%s+", " "):gsub("^%s+", "")
            return message
          end,
        },
      }, neotest_ns)

      opts.adapters = {
        require("neotest-python")({
          -- Extra arguments for nvim-dap configuration
          -- See https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for values
          dap = {
            justMyCode = false,
            console = "integratedTerminal",
          },
          args = {"--log-level", "DEBUG", "--quiet", "-v"},
          runner = "pytest",
          -- Custom python path (supports uv, conda, venv) - cached for performance
          python = function()
            -- Cache python path to avoid repeated system calls
            if _G._neotest_python_path then
              return _G._neotest_python_path
            end
            
            -- Check for uv first
            local uv_python = vim.fn.system("uv run which python 2>/dev/null"):gsub("\n", "")
            if vim.v.shell_error == 0 and uv_python ~= "" then
              _G._neotest_python_path = uv_python
              return uv_python
            end
            
            -- Fallback to conda/venv
            local venv = vim.env.CONDA_PREFIX or vim.env.VIRTUAL_ENV
            if venv then
              _G._neotest_python_path = venv .. "/bin/python"
              return _G._neotest_python_path
            end
            
            -- Default python
            _G._neotest_python_path = "python"
            return "python"
          end,
          -- Pytest configuration - automatically detect pyproject.toml
          pytest_discover_instances = true,
          -- Better project root detection
          root_files = { "pyproject.toml", "pytest.ini", "setup.cfg", ".pytest_cache" },
          is_test_file = function(file_path)
            -- Exclude non-test files
            if file_path:match("__init__%.py$") or 
               file_path:match("conftest%.py$") then
              return false
            end
            
            -- Include actual test files
            return file_path:match("test_.+%.py$") or 
                   file_path:match(".+_test%.py$") or
                   (file_path:match("tests/.+%.py$") and 
                    not file_path:match("__init__%.py$") and
                    not file_path:match("conftest%.py$"))
          end,
        }),
      }

      require("neotest").setup(opts)
      
      -- Debug function to check test discovery
      vim.api.nvim_create_user_command("NeotestDebug", function()
        local cwd = vim.fn.getcwd()
        print("Current working directory: " .. cwd)
        
        -- Check for test files
        local test_files = vim.fn.glob(cwd .. "/**/test_*.py", false, true)
        local test_files2 = vim.fn.glob(cwd .. "/**/*_test.py", false, true)
        local tests_dir = vim.fn.glob(cwd .. "/tests/*.py", false, true)
        
        print("Found test_*.py files: " .. vim.inspect(test_files))
        print("Found *_test.py files: " .. vim.inspect(test_files2))
        print("Found tests/*.py files: " .. vim.inspect(tests_dir))
        
        -- Check Python environment
        local python_cmd = require("neotest").adapters[1].python()
        print("Python executable: " .. python_cmd)
        
        -- Check if pytest is available
        local pytest_check = vim.fn.system(python_cmd .. " -c 'import pytest; print(pytest.__version__)'")
        print("Pytest version: " .. pytest_check:gsub("\n", ""))
      end, {})
      
      -- Clear neotest cache command
      vim.api.nvim_create_user_command("NeotestClearCache", function()
        -- Clear the neotest cache
        local neotest = require("neotest")
        if neotest.state then
          neotest.state.clear()
        end
        
        -- Clear Python path cache
        _G._neotest_python_path = nil
        
        -- Clear package cache to force reload
        package.loaded["neotest"] = nil
        package.loaded["neotest-python"] = nil
        
        vim.notify("Neotest cache cleared! Restart test discovery with :lua require('neotest').summary.toggle()")
      end, {})

      -- Configure custom test status signs
      vim.fn.sign_define("neotest_passed", {
        text = "✓",
        texthl = "NeotestPassed",
      })
      vim.fn.sign_define("neotest_failed", {
        text = "✗",
        texthl = "NeotestFailed",
      })
      vim.fn.sign_define("neotest_running", {
        text = "…",
        texthl = "NeotestRunning",
      })
      vim.fn.sign_define("neotest_skipped", {
        text = "⊖",
        texthl = "NeotestSkipped",
      })

      -- Set up test status highlights with teal theme
      local function setup_test_highlights()
        local is_dark = vim.o.background == "dark"
        
        vim.api.nvim_set_hl(0, "NeotestPassed", {
          fg = is_dark and "#4ec9b0" or "#26a269",
          bold = true,
        })
        vim.api.nvim_set_hl(0, "NeotestFailed", {
          fg = is_dark and "#f48771" or "#a51d2d",
          bold = true,
        })
        vim.api.nvim_set_hl(0, "NeotestRunning", {
          fg = "#228787", -- Always use teal accent
          bold = true,
        })
        vim.api.nvim_set_hl(0, "NeotestSkipped", {
          fg = is_dark and "#858585" or "#77767b",
          bold = true,
        })
        
        -- Fix unreadable cyan colors in test tree
        vim.api.nvim_set_hl(0, "NeotestNamespace", {
          fg = is_dark and "#dcdcaa" or "#795e26", -- Yellow/brown for namespaces
        })
        vim.api.nvim_set_hl(0, "NeotestFile", {
          fg = is_dark and "#9cdcfe" or "#4070a0", -- Blue for files
        })
        vim.api.nvim_set_hl(0, "NeotestDir", {
          fg = is_dark and "#cccccc" or "#2e3436", -- Normal text for directories
        })
        vim.api.nvim_set_hl(0, "NeotestTest", {
          fg = is_dark and "#cccccc" or "#2e3436", -- Normal text for test names
        })
      end
      
      setup_test_highlights()
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = setup_test_highlights,
      })
      
      -- Configure floating window highlights to match theme
      local function setup_neotest_float_highlights()
        local is_dark = vim.o.background == "dark"
        
        -- Set floating window colors to match Telescope
        vim.api.nvim_set_hl(0, "NeotestBorder", {
          fg = is_dark and "#404040" or "#d0d0d0",
          bg = "NONE",
        })
        vim.api.nvim_set_hl(0, "NeotestWinSelect", {
          fg = "#228787", -- Teal accent
          bold = true,
        })
      end
      
      setup_neotest_float_highlights()
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = setup_neotest_float_highlights,
      })
    end,
  },
}