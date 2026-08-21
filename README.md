<div align="center">

# Teleport.nvim
##### Straightforward file marking and buffer navigation plugin 


<img alt="Teleport logo" height="280" src="TeleportIconPT3Trans.png" />

[![Lua](https://img.shields.io/badge/Lua-blue.svg?style=for-the-badge&logo=lua)](http://www.lua.org)
[![Neovim](https://img.shields.io/badge/Neovim%200.8+-green.svg?style=for-the-badge&logo=neovim)](https://neovim.io)

</div>

### Install

##### Lazy
```lua
{"Boofny/teleport.nvim"},
```

### Some caveats
---
  1. File marks can be used on non git repo projects BUT will not be saved for later use
  2. If a git project is moved to a different directory the saved marks will reset and can be altered in ~/.local/share/nvim/teleport/
  3. the following code should be placed in your configs init.lua BEFORE the plugins require module in order to get this plugin working correctly
```lua
vim.cmd("delmark ABCD") 
```

### Here is the setup and keybindings i use
```lua
local tele = require("teleport")

vim.keymap.set("n", "<leader>a", tele.add_mark)
vim.keymap.set("n", "<leader>t", tele.list_mark_files)

vim.keymap.set("n", "<leader>1", function() tele.nav:nav_mark(1) end)
vim.keymap.set("n", "<leader>2", function() tele.nav:nav_mark(2) end)
vim.keymap.set("n", "<leader>3", function() tele.nav:nav_mark(3) end)
vim.keymap.set("n", "<leader>4", function() tele.nav:nav_mark(4) end)

-- optional select picker
vim.keymap.set("n", "<leader>gt", tele.find_marks) 

-- optional mark override
vim.keymap.set("n", "<leader>k1", function() tele.add_mark_override(1) end)
vim.keymap.set("n", "<leader>k2", function() tele.add_mark_override(2) end)
vim.keymap.set("n", "<leader>k3", function() tele.add_mark_override(3) end)
vim.keymap.set("n", "<leader>k4", function() tele.add_mark_override(4) end)

-- optional tab iteration
vim.keymap.set("n", "<A-n>", function() tele.nav:next() end)
vim.keymap.set("n", "<A-p>", function() tele.nav:prev() end)
```

### Customization
```lua
local tele = require("teleport")

-- defaults
tele.Setup({
  preselect = false, -- keeping cursor on current mark when opening menu
  border = "single", -- border for the main list 
  position = "center", -- top, center, bottom center being default
  preview_length = 50, -- previewing files length
  save_warning = true, -- get a reminder that marks are not saved in non git repos
  file_modify_status = true, -- show [+] modify status inline the list_mark_files menu
  file_git_status = true -- showing XY of git status inline the the list menu
})

```

