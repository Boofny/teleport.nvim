-- where the commands will be
vim.api.nvim_create_user_command("Greeting", function()
  require("teleport").greet()
end, {})
-- so commands do work but also in a key binding can do function() require("teleport").greet()

vim.api.nvim_create_user_command("ClearMarks", function()
  require("teleport").clearMarks()
end, {})
