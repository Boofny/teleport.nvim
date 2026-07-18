local M = {}

--NOTE: should move things to other files

-- where functions will be created to be used in commands inside of teleport.lua
local markings = {
  [1] = "A",
  [2] = "B",
  [3] = "C",
  [4] = "D"
}

local markersList = {
  A = 1,
  B = 2,
  C = 3,
  D = 4
}

local ORDEREDMARKS = "ABCD"

-- Gets the neovim set file marks so anything that is in the list_mark_files files
local function get_file_marks()
  local marks = {}

  for _, mark in ipairs(vim.fn.getmarklist()) do
    if mark.mark:match("^'[A-D]$") then
      table.insert(marks, {
        name = mark.mark:sub(2),
        file = vim.fn.fnamemodify(mark.file, ":t"),
        path = mark.file,
      })
    end
  end

  return marks
end

-- mapFull checks if the map that neovim has for marks A-D is all filled 
local function mapFull(lookupTable)
  for i = 1, #ORDEREDMARKS do
    local letter = ORDEREDMARKS:sub(i, i)
    if not lookupTable["'" .. letter] then
      return false -- found a free slot, so it's not full
    end
  end
  return true -- all four are taken
end

-- addMark checks the order of the marks first then if there is an avalible spot ex: B then take the next spot for the mark
-- this also uses the logic for the mapFull in order to prompt user for the file they want to replace
function M.addMark()
  local lookup = {}

  -- make the look up table based on the marks in the map of marks in neovim
  for _, mark in ipairs(vim.fn.getmarklist()) do
    lookup[mark.mark] = mark
  end

  -- auto adding to the next mark in the set
  for i = 1, #ORDEREDMARKS do
    local letter = ORDEREDMARKS:sub(i, i)

    if not lookup["'" .. letter]then -- has a mark and is empty
      vim.cmd("mark " .. letter)
      print("Teleport marked: " .. markersList[letter])
      break
    end
  end

  -- when map of marks gets full prompt user to replace one
  if mapFull(lookup) then

    local marks = get_file_marks()

    -- local width = 30
    -- local height = 4
    --
    -- local buf = vim.api.nvim_create_buf(false, true)
    --
    -- local lines = {}
    --
    -- for _, mark in ipairs(marks) do
    --   table.insert(lines, string.format("%s %s", markersList[mark.name], mark.file))
    -- end
    --
    -- vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    --
    -- local row = math.floor((vim.o.lines - height) / 2)
    -- local col = math.floor((vim.o.columns - width) / 2)
    --
    -- local win = vim.api.nvim_open_win(buf, true, {
    --   relative = "editor",
    --   width = width,
    --   height = height,
    --   row = row,
    --   col = col,
    --   border = "rounded",
    --   style = "minimal",
    --
    --   title = "All marks taken, replace?",
    --   title_pos = "center",
    -- })
    --
    -- vim.keymap.set("n", "1", function()
    --   vim.api.nvim_win_close(win, true)
    --   vim.cmd("mark " .. markings[1])
    -- end, {buffer = buf})
    --
    -- vim.keymap.set("n", "2", function()
    --   vim.api.nvim_win_close(win, true)
    --   vim.cmd("mark " .. markings[2])
    -- end, {buffer = buf})
    --
    -- vim.keymap.set("n", "3", function()
    --   vim.api.nvim_win_close(win, true)
    --   vim.cmd("mark " .. markings[3])
    -- end, {buffer = buf})
    --
    -- vim.keymap.set("n", "4", function()
    --   vim.api.nvim_win_close(win, true)
    --   vim.cmd("mark " .. markings[4])
    -- end, {buffer = buf})
    --
    -- vim.keymap.set("n", "q", function()
    --   vim.api.nvim_win_close(win, true)
    -- end, {buffer = buf})
    --
    -- vim.keymap.set("n", "<CR>", function()
    --   local cursor = vim.api.nvim_win_get_cursor(win)
    --   local line_num = cursor[1]
    --   vim.api.nvim_win_close(win, true)
    --   vim.cmd("mark " .. markings[line_num])
    -- end, {buffer = buf})

    -- WARN: old version using a search bar, cleaner but to big 
    vim.ui.select(marks, {
      prompt = "All marks taken, replace?",
      format_item = function(item)
        return "" .. item.file
      end,
    }, function(choice)
      if choice then
        vim.cmd("mark " .. choice.name)
      end
    end)

  end

end

-- clearMarks BCD
function M.clearMarks()
  vim.cmd("delmarks BCD")
end

-- addMarkBypass overrides the addMark function in order to have custom mark setting rather than auto
function M.addMarkBypass(markNum)
  vim.cmd("mark " .. markings[markNum])
  print("Teleport marked: " .. markNum)
end

-- navMark is a function that what ever paramitor is passed to it will be moved to that mark 
function M.navMark(markNum)
  local mark = markings[markNum]

  for _, m in ipairs(vim.fn.getmarklist()) do
    if m.mark == "'" .. mark then
      vim.cmd("'" .. mark)
      return
    end
  end

  vim.notify("Teleport Mark " .. markersList[mark] .. " is not set", vim.log.levels.ERROR)
end

-- list_mark_files shows a pop up window of avalible teleport marks and there names 
-- user is able to delete and pick marks eithor using the numbers or <CR> for said mark
function M.list_mark_files()
  local lines = {}
  local found = false

  for _, mark in ipairs(vim.fn.getmarklist()) do
    if mark.mark:match("^'[A-D]$") then
      found = true
      table.insert(
        lines,
        string.format(
          "%s %s",
          markersList[mark.mark:sub(2)],
          vim.fn.fnamemodify(mark.file, ":t")
        )
      )
    end

    if not found then
      vim.notify("No marks set!", vim.log.levels.ERROR)
      return
    end

  end

  local width = 30
  local height = #lines
  local row = math.floor((vim.o.lines - height) / 6)
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

    title = "Teleport",
    title_pos = "center",
  })

  vim.keymap.set("n", "1", function()
    vim.api.nvim_win_close(win, true)
    vim.cmd("'" .. markings[1])
  end, {buffer = buf})

  vim.keymap.set("n", "2", function()
    vim.api.nvim_win_close(win, true)
    vim.cmd("'" .. markings[2])
  end, {buffer = buf})

  vim.keymap.set("n", "3", function()
    vim.api.nvim_win_close(win, true)
    vim.cmd("'" .. markings[3])
  end, {buffer = buf})

  vim.keymap.set("n", "4", function()
    vim.api.nvim_win_close(win, true)
    vim.cmd("'" .. markings[4])
  end, {buffer = buf})

  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(win, true)
  end, {buffer = buf})

  --TODO: the issue with this is that is uses line count rather than table count so if something like 1 is removed 2 is now in the possitoin of 1
  vim.keymap.set("n", "d", function()
    local cursor = vim.api.nvim_win_get_cursor(win)
    local line_num = cursor[1]
    vim.api.nvim_win_close(win, true)
    vim.cmd("delmark " .. markings[line_num])
    print("Teleport mark removed:", line_num)
  end, {buffer = buf, nowait = true})

  vim.keymap.set("n", "<CR>", function()
    local cursor = vim.api.nvim_win_get_cursor(win)
    local line_num = cursor[1]
    vim.api.nvim_win_close(win, true)
    vim.cmd("'" .. markings[line_num])
  end, {buffer = buf})
end

return M



