local M = {}
-- NOTE: another thing is to have a telescope type search for march like in the overflow case
-- NOTE: also harpoon uses the full file path but idk how i like that
-- TODO: have to use more anotation for any function that returns things 
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
---@class TeleportMark
---@field markName string
---@field fileName string
---@field filePath string

---@return TeleportMark[]
local function get_file_marks()
  local marks = {}

  for _, mark in ipairs(vim.fn.getmarklist()) do
    if mark.mark:match("^'[A-D]$") then
      table.insert(marks, {
        markName = mark.mark:sub(2),
        fileName = vim.fn.fnamemodify(mark.file, ":t"),
        filePath = mark.file,
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

    -- WARN: old version using a search bar, cleaner but to big 
    vim.ui.select(marks, {
      prompt = "All marks taken, replace?",
      format_item = function(item)
        return "" .. item.fileName
      end,
    }, function(choice)
      if choice then
        vim.cmd("mark " .. choice.markName)
      end
    end)

  end

end

-- clearMarks BCD
function M.clearMarks()
  vim.cmd("delmarks BCD")
end

function M.testFunc()
  ---@type TeleportMark[]
  local mapper = get_file_marks()
  for _, m in ipairs(mapper) do
    print(m.markName, m.fileName)
  end
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
        string.format("%s %s", markersList[letter], vim.fn.fnamemodify(mark.file, ":t"))
      )
    else
      table.insert(lines, string.format("%s *EMPTY", markersList[letter]))
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

  --TODO: NEED to make these all moduler functions not doing this, this is bad and can be way better
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
    local marks = get_file_marks()

    for _, mark in ipairs(marks) do
      if mark.markName == markings[line_num] then
        vim.api.nvim_win_close(win, true)
        vim.cmd("'" .. markings[line_num])
        return
      end
    end

    vim.api.nvim_win_close(win, true)
    vim.notify("Teleport Mark " .. line_num .. " is not set", vim.log.levels.ERROR)
  end, {buffer = buf})
end

return M



