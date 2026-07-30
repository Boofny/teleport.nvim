local M = {}

local navs = require("teleport.navigate")
local markers = require("teleport.markings")

---@param file vim.fn.getmarklist.ret.item
local function preview_buffer(file)
  local path = vim.fn.expand(file.file) -- from /home/

  local width = math.floor((vim.o.columns) / 2) -- dynamic width for different screens
  local height = math.floor((vim.o.lines) / 2)
  local row = math.floor((vim.o.lines - height) / 3)
  local col = math.floor((vim.o.columns - width) / 2)

  local buf = vim.api.nvim_create_buf(false, true)

  local ok, lines = pcall(vim.fn.readfile, path, "", 50) -- could make this with opts later
  if not ok then
    lines = { "[Could not read file: " .. file.file .. "]" }
  end

  vim.api.nvim_buf_set_lines(buf , 0, -1, false, lines)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    border = "rounded",
    style = "minimal",

    title = "Preview " .. vim.fn.fnamemodify(file.file, ":t"),
    title_pos = "center",
    focusable = false,
  })

  vim.bo[buf].filetype = vim.filetype.match({ filename = file.file}) or ""
  vim.wo[win].number = true

  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false

  vim.bo[buf].modifiable = false
  vim.bo[buf].readonly = true

  vim.keymap.set("n", "q", function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end

    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end, {buffer = buf})

end

local function help_buffer()
  -- NOTE: could add like a p for preview or P might be dumb idk and t for tabbing using the line for <CR> as a start
  local lines = {
    "   Keys   Command/Description",
    "  ---------------------------",
    "   1-4 => Select buffer number to move",
    "  <CR> => Select buffer that cursor is on",
    "    dd => Delete mark but not the file buffer",
    "     ? => Show help menu",
    "     q => Exit Teleport menu",
    "     T => Open in tab",
    "     P => Preview File content",
    "     f => Find marks"
  }

  local width = math.floor((vim.o.columns) / 3) -- dynamic width for different screens
  -- local height = math.floor(vim.o.lines / 2)
  local height = #lines
  local row = math.floor((vim.o.lines - height) / 3)
  local col = math.floor((vim.o.columns - width) / 2)

  local buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    border = "rounded",
    style = "minimal",

    title = "Teleport Help",
    title_pos = "center",
  })

  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false

  vim.bo[buf].modifiable = false
  vim.bo[buf].readonly = true

  local ns = vim.api.nvim_create_namespace("teleport")
  vim.api.nvim_buf_set_extmark(buf, ns, 0, 0, {
    end_col = 29,
    hl_group = "Keyword",
  })

  vim.api.nvim_buf_set_extmark(buf, ns, 1, 0, {
    end_col = 29,
    hl_group = "Comment",
  })

  for line = 2, 9 do
    vim.api.nvim_buf_set_extmark(buf, ns, line, 2, {
      end_col = 6,
      hl_group = "String",
    })

    vim.api.nvim_buf_set_extmark(buf, ns, line, 7, {
      end_col = 9,
      hl_group = "Comment",
    })
  end

  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(win, true)
  end, {buffer = buf})
end


-- just for listing and chosing the files not to be stored elsewhere
function M.find_marks()
  vim.ui.select(markers.get_teleport_marks(), {
    prompt = "Find marks",
    format_item = function(item)
      return "" .. item.fileName
    end,
  }, function(choice)
    if choice then
      navs.nav_mark(markers.markersList[choice.markName])
    end
  end)
end

-- list_mark_files shows a pop up window of avalible teleport marks and there names 
-- user is able to delete and pick marks eithor using the numbers or <CR> for said mark
function M.list_mark_files()
  -- TODO: maybe try out somthing like if there is git changes in a mark display the changes in the menu
  local existing = {}

  for _, mark in ipairs(vim.fn.getmarklist()) do
    if mark.mark:match("^'[A-D]$") then
      existing[mark.mark:sub(2)] = mark
    end
  end

  local lines = {}

  for _, letter in ipairs({ "A", "B", "C", "D" }) do
    local mark = existing[letter]

    if mark then
      table.insert(lines,
        string.format("%s %s", markers.markersList[letter], vim.fn.fnamemodify(mark.file, ":."))
      )
    else
      table.insert(lines, string.format("%s [ EMPTY ]", markers.markersList[letter]))
    end
  end

  local width = math.floor((vim.o.columns) / 2) -- dynamic width for different screens
  local height = #lines
  local row = math.floor((vim.o.lines - height) / 3)
  local col = math.floor((vim.o.columns - width) / 2)

  local buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- local pos = markers.current_mark()

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    border = "rounded",
    style = "minimal",

    title = "Teleport",
    title_pos = "center",
  })

  -- vim.api.nvim_win_set_cursor(win, {pos, 0}) -- just a nice thing to keep the cursor inline with what mark is on

  vim.wo[win].cursorline = true

  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false

  vim.bo[buf].modifiable = false
  vim.bo[buf].readonly = true

  vim.keymap.set("n", "1", function()
    vim.api.nvim_win_close(win, true)
    navs.nav_mark(1)
  end, {buffer = buf})

  vim.keymap.set("n", "2", function()
    vim.api.nvim_win_close(win, true)
    navs.nav_mark(2)
  end, {buffer = buf})

  vim.keymap.set("n", "3", function()
    vim.api.nvim_win_close(win, true)
    navs.nav_mark(3)
  end, {buffer = buf})

  vim.keymap.set("n", "4", function()
    vim.api.nvim_win_close(win, true)
    navs.nav_mark(4)
  end, {buffer = buf})

  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(win, true)
  end, {buffer = buf})

  vim.keymap.set("n", "dd", function()
    local cursor = vim.api.nvim_win_get_cursor(win)
    local line_num = cursor[1]
    vim.api.nvim_win_close(win, true)
    vim.cmd("delmark " .. markers.markings[line_num])
    print("Teleport mark removed:", line_num)
  end, {buffer = buf, nowait = true})

  vim.keymap.set("n", "<CR>", function()
    local cursor = vim.api.nvim_win_get_cursor(win)
    local line_num = cursor[1]
    local marks = markers.get_nvim_api_marks()

    for _, mark in ipairs(marks) do
      if mark.mark:sub(2) == markers.markings[line_num] then
        vim.api.nvim_win_close(win, true)
        navs.nav_mark(line_num)
        return
      end
    end

    vim.api.nvim_win_close(win, true)
    vim.notify("Teleport Mark " .. line_num .. " is not set", vim.log.levels.ERROR)
  end, {buffer = buf})

  vim.keymap.set("n", "f", function()
    vim.api.nvim_win_close(win, true)
    M.find_marks()
  end, {buffer = buf})

  vim.keymap.set("n", "T", function() -- tabbing 
    local cursor = vim.api.nvim_win_get_cursor(win)
    local line_num = cursor[1]
    local marks = markers.get_nvim_api_marks()

    for _, mark in ipairs(marks) do
      if mark.mark:sub(2) == markers.markings[line_num] then
        vim.api.nvim_win_close(win, true)
        vim.cmd("tabnew " .. mark.file)
        return
      end
    end

    vim.api.nvim_win_close(win, true)
    vim.notify("Teleport Mark " .. line_num .. " is not set", vim.log.levels.ERROR)
  end, {buffer = buf})

  vim.keymap.set("n", "P", function() -- Preview
    local cursor = vim.api.nvim_win_get_cursor(win)
    local line_num = cursor[1]
    local marks = markers.get_nvim_api_marks()
    if line_num > #marks then
      vim.api.nvim_win_close(win, true)
      vim.notify("Teleport Mark " .. line_num .. " is not set", vim.log.levels.ERROR)
      return
    end
    preview_buffer(marks[line_num])
  end, {buffer = buf})


  vim.keymap.set("n", "?", function()
    help_buffer()
  end, {buffer = buf})
end


return M
