-- UV Virtual Environment Auto-Activation
local M = {}

-- Cache for virtual environment detection
local venv_cache = {}
local cache_timeout = 5000 -- 5 seconds

function M.find_uv_venv()
  local cwd = vim.fn.getcwd()
  local cache_key = cwd
  local current_time = vim.loop.hrtime() / 1000000 -- Convert to milliseconds
  
  -- Check cache first
  if venv_cache[cache_key] and (current_time - venv_cache[cache_key].time) < cache_timeout then
    return venv_cache[cache_key].venv
  end
  
  local venv_path = nil
  local project_root = cwd
  
  -- Look for .python-version file (uv project indicator)
  local python_version_file = project_root .. "/.python-version"
  if vim.fn.filereadable(python_version_file) == 1 then
    -- Try to find uv venv
    local uv_venv_cmd = "cd " .. vim.fn.shellescape(project_root) .. " && uv venv --quiet --show-path 2>/dev/null"
    local handle = io.popen(uv_venv_cmd)
    if handle then
      local result = handle:read("*a")
      handle:close()
      if result and result:match("%S") then
        venv_path = result:gsub("%s+", "")
      end
    end
  end
  
  -- Fallback: check for pyproject.toml and try uv venv
  if not venv_path then
    local pyproject_file = project_root .. "/pyproject.toml"
    if vim.fn.filereadable(pyproject_file) == 1 then
      local uv_venv_cmd = "cd " .. vim.fn.shellescape(project_root) .. " && uv venv --quiet --show-path 2>/dev/null"
      local handle = io.popen(uv_venv_cmd)
      if handle then
        local result = handle:read("*a")
        handle:close()
        if result and result:match("%S") then
          venv_path = result:gsub("%s+", "")
        end
      end
    end
  end
  
  -- Cache the result
  venv_cache[cache_key] = {
    venv = venv_path,
    time = current_time
  }
  
  return venv_path
end

function M.get_python_venv()
  -- Priority order: UV_VENV -> uv project venv -> VIRTUAL_ENV -> CONDA_PREFIX
  local venv = os.getenv("UV_VENV")
  if venv then
    return venv, "uv"
  end
  
  venv = M.find_uv_venv()
  if venv then
    return venv, "uv-project"
  end
  
  venv = os.getenv("VIRTUAL_ENV")
  if venv then
    return venv, "venv"
  end
  
  venv = os.getenv("CONDA_PREFIX")
  if venv then
    return venv, "conda"
  end
  
  return nil, nil
end

function M.get_venv_name()
  local venv_path, venv_type = M.get_python_venv()
  if not venv_path then
    return nil
  end
  
  local venv_name = vim.fn.fnamemodify(venv_path, ":t")
  
  -- Special handling for uv managed environments
  if venv_type == "uv-project" then
    -- For uv project venvs, show project name instead of hash
    local project_root = vim.fn.getcwd()
    local project_name = vim.fn.fnamemodify(project_root, ":t")
    return project_name .. " (uv)"
  elseif venv_type == "uv" then
    return venv_name .. " (uv)"
  elseif venv_type == "conda" then
    return venv_name .. " (conda)"
  else
    return venv_name
  end
end

function M.activate_venv()
  local venv_path, venv_type = M.get_python_venv()
  if not venv_path then
    return
  end
  
  -- Set environment variables for LSP and tools
  vim.env.VIRTUAL_ENV = venv_path
  vim.env.PATH = venv_path .. "/bin:" .. vim.env.PATH
  
  -- Update pyright to recognize the venv
  local clients = vim.lsp.get_clients({ name = "pyright" })
  for _, client in ipairs(clients) do
    if client.config.settings and client.config.settings.python then
      client.config.settings.python.pythonPath = venv_path .. "/bin/python"
      client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })
    end
  end
end

-- Auto-activate on Python file open
vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  pattern = "*.py",
  callback = function()
    M.activate_venv()
  end,
})

-- Auto-activate when entering Python projects
vim.api.nvim_create_autocmd("DirChanged", {
  callback = function()
    -- Clear cache when directory changes
    venv_cache = {}
    if vim.bo.filetype == "python" then
      M.activate_venv()
    end
  end,
})

return M