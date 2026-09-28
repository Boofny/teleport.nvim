-- where the commands will be
vim.api.nvim_create_user_command("AddMark", function()
  require("teleport").addMark()
end, {})

vim.api.nvim_create_user_command("ClearMarks", function()
  require("teleport.markings").clearMarks()
end, {})

vim.api.nvim_create_user_command("ListMarkFiles", function()
  require("teleport").list_mark_files()
end, {})

vim.api.nvim_create_user_command("FindMarks", function()
  require("teleport.ui").find_marks()
end, {})

vim.api.nvim_create_user_command("ManageTeleport", function()
  require("teleport").manage_mark_projects()
end, {})

-- vim.api.nvim_create_user_command("TestTele", function()
--   require("teleport").testFunc()
-- end, {})
