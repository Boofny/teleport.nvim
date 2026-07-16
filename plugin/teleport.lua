vim.api.nvim_create_user_command("Greeting", function()
  require("teleport").greet()
end, {})
