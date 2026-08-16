local M = {}

local data_path = vim.fn.stdpath("data")
M.plugin_dir = vim.fs.joinpath(data_path, "teleport")

---@return boolean
function M.in_git_repo()
  local resp = vim.fn.system("git rev-parse --is-inside-work-tree")
  return resp == "true\n" -- <- had to add this stupid new line
end

---@return string headHash
function M.get_repo_url()
  local resp = vim.fn.system("git config --get remote.origin.url"):gsub("\n", "") -- try to find url first

  if resp == "" then -- if for some reason a url is not avalible for the repo then try top level aka the pwd of the repo the old way
    resp = vim.fn.system("git rev-parse --show-toplevel"):gsub("\n", "")
  end

  return resp
end

---@return string resp
function M.get_top_level()
  local resp = vim.fn.system("git rev-parse --show-toplevel"):gsub("\n", "")
  return resp
end

function M.get_repo_origin()
  local url = vim.fn.system("git config --get remote.origin.url"):gsub("\n", "")
  if vim.v.shell_error == 0 and url ~= "" then
    return url
  end
  -- either no remote configured, or not in a repo at all — check toplevel
  local toplevel = vim.fn.system("git rev-parse --show-toplevel"):gsub("\n", "")
  if vim.v.shell_error == 0 and toplevel ~= "" then
    return toplevel  -- valid repo, just no remote (e.g. local-only project)
  end
  return nil  -- not in a git repo at all
end

---@return boolean 
function M.data_conf_exist() -- purely just checks if the teleport dir is 
  if vim.fn.isdirectory(M.plugin_dir) == 0 then
    return false
  else
    return true
  end
end

---@class Options
function M.parse_opts(opts)
  print(opts)
end

---@param file_name string
---@return table
function M.git_status(file_name)
  ---@class Status_table
  ---@field X string
  ---@field Y string
  local status_table = {}

  local command = string.format("git status --porcelain %s", file_name)
  local resp = vim.fn.system(command)

  status_table["X"] = resp:sub(1,1)
  status_table["Y"] = resp:sub(2,2)

  return status_table
end

return M
