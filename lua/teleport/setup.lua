local M = {}

local data_path = vim.fn.stdpath("data")
M.plugin_dir = vim.fs.joinpath(data_path, "teleport")

---@return boolean
function M.in_git_repo()
  local resp = vim.fn.system("git rev-parse --show-toplevel"):gsub("\n", "")
  return resp == "true\n" -- <- had to add this stupid new line
end

---@return string headHash
function M.get_repo_head()
  local hash = vim.fn.system("git rev-parse HEAD")
  return hash
end

function M.save_marks()

end

---@return boolean 
function M.data_conf_exist() -- purely just checks if the teleport dir is 
  if vim.fn.isdirectory(M.plugin_dir) == 0 then
    print("Dir does not exists")
    return false
  else
    print("Dir exists")
    return true
  end
end


return M
