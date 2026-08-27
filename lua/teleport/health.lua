local M = {}

M.check = function ()
  vim.health.start("Teleport report")

  if vim.fn.executable("git") == 1 then
    vim.health.ok("git binary found.")
  else
    vim.health.error("git binary not found, install in order to use this plugin")
  end
end

return M
