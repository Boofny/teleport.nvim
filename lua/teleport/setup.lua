local M = {}

local data_path = vim.fn.stdpath("data")
M.plugin_dir = vim.fs.joinpath(data_path, "teleport")

--@return boolean
-- function M.in_git_repo()
--   local resp = vim.fn.system("git rev-parse --is-inside-work-tree")
--   return resp == "true\n" -- <- had to add this stupid new line
-- end

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

return M




