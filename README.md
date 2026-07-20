# Teleport.nvim

![Teleport logo](TeleportIcon.png)
Straightforward file marking and buffer navigation plugin 

### Install (don't know how to make this thing public yet :P)
```bash
Install is not avalible yet
```

### Here is the setup and keybindings i use
```lua
local tele = require("teleport")
local nav = require("teleport.navigate")
local ui = require("teleport.ui")

vim.keymap.set("n", "<leader>t", ui.list_mark_files)
vim.keymap.set("n", "<leader>a", tele.addMark)

vim.keymap.set("n", "<leader>1", function() nav.navMark(1) end)
vim.keymap.set("n", "<leader>2", function() nav.navMark(2) end)
vim.keymap.set("n", "<leader>3", function() nav.navMark(3) end)
vim.keymap.set("n", "<leader>4", function() nav.navMark(4) end)

vim.keymap.set("n", "<leader>k1", function() nav.addMarkBypass(1) end)
vim.keymap.set("n", "<leader>k2", function() nav.addMarkBypass(2) end)
vim.keymap.set("n", "<leader>k3", function() nav.addMarkBypass(3) end)
vim.keymap.set("n", "<leader>k4", function() nav.addMarkBypass(4) end)
```

### Customization
```bash
Customization is not avalible yet
```
