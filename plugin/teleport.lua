-- where the commands will be
vim.api.nvim_create_user_command("AddMark", function()
  require("teleport").addMark()
end, {})
-- so commands do work but also in a key binding can do function() require("teleport").greet()

vim.api.nvim_create_user_command("ClearMarks", function()
  require("teleport").clearMarks()
end, {})


vim.api.nvim_create_user_command("TestTele", function()
  require("teleport").testFunc()
end, {})
