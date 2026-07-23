local M = {}

---@return boolean
function M.inRepo()
  local resp = vim.fn.system("git rev-parse --is-inside-work-tree")
  return resp == "true\n" -- <- had to add this stupid new line
end

---@return boolean 
function M.DirExist() -- purley just checks if the teleport dir is 
  local data_path = vim.fn.stdpath("data")
  local plugin_dir = vim.fs.joinpath(data_path, "teleport")

  if vim.fn.isdirectory(plugin_dir) == 0 then
    -- vim.fn.mkdir(plugin_dir, "p") dont create it in this function
    print("Dir does not exists")
    return false
  else
    print("Dir exists")
    return true
  end
end


return M
