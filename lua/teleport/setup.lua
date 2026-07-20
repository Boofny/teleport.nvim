local M = {}

function M.DirExist()

  local data_path = vim.fn.stdpath("data")
  local plugin_dir = vim.fs.joinpath(data_path, "teleport")

  if vim.fn.isdirectory(plugin_dir) == 0 then
    vim.fn.mkdir(plugin_dir, "p")
    print("Dir does not exist now created")
  else
    print("Dir exist")
  end

end

return M
