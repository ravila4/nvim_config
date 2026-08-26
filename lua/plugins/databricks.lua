return {
  {
    dir = vim.fn.expand("~/Projects/databricks.nvim"),
    name = "databricks.nvim",
    lazy = false,
    init = function()
      vim.g.databricks_nvim_health_command = {
        vim.fn.expand("~/Projects/databricks.nvim/.venv/bin/python"),
        "-m",
        "databricks_nvim.health",
      }
      vim.g.databricks_nvim_targets_command = {
        vim.fn.expand("~/Projects/databricks.nvim/.venv/bin/python"),
        "-m",
        "databricks_nvim.targets",
      }
    end,
    keys = {
      { "<leader>dk", "<cmd>DatabricksTarget<cr>", desc = "Select Databricks target" },
    },
  },
}
