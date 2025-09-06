-- Firefox integration tools

return {
  -- Firefox integration
  {
    "glacambre/firenvim",
    enabled = true, -- Disabling it for now
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
        vim.keymap.set({ "n", "i" }, "<C-=>", function()
          adjust_font_size(1)
        end)
        vim.keymap.set({ "n", "i" }, "<C-->", function()
          adjust_font_size(-1)
        end)
      end

      vim.api.nvim_create_autocmd("UIEnter", {
        callback = on_ui_enter,
      })
    end,
  },
}
