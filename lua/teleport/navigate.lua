local markers = require("teleport.markings")

local nvim_marks = {}

-- nav_mark is a function that what ever paramitor is passed to it will be moved to that mark 
---@param markNum integer
function nvim_marks:nav_mark(markNum)
  local mark = markers.markings[markNum]

  for _, m in ipairs(vim.fn.getmarklist()) do
    if m.mark == "'" .. mark then
      vim.cmd("'" .. mark)
      vim.notify("Teleported to Mark: " .. markers.markersList[mark] .. " " .. vim.fn.fnamemodify(m.file, ":."), vim.log.levels.INFO)
      return
    end
  end

  vim.notify("Teleport Mark: " .. markers.markersList[mark] .. " is not set", vim.log.levels.ERROR)
end

-- BUG: if a file is added to the list then its not counted in the next and prev listing option
---@return boolean
---@param mark_num integer
local function is_file_marked(mark_num)
  local file_mark = vim.api.nvim_get_mark(markers.markings[mark_num], {})
  return file_mark[1] ~= 0
end

function nvim_marks:next()
  local current_mark = markers.current_mark()

  if current_mark == -1 then
    vim.notify("not in a marked file", vim.log.levels.ERROR)
    return
  end

  local start = current_mark

  repeat
    current_mark = current_mark + 1

    if current_mark > 4 then -- this is just when it reaches the end
      current_mark = 1
    end

    if is_file_marked(current_mark) then
      self:nav_mark(current_mark)
      return
    end
  until current_mark == start

  vim.notify("No other marks found", vim.log.levels.WARN)
end

function nvim_marks:prev()
  local current_mark = markers.current_mark()

  if current_mark == -1 then
    vim.notify("not in a marked file", vim.log.levels.ERROR)
    return
  end

  local start = current_mark

  repeat
    current_mark = current_mark - 1

    if current_mark < 1 then -- this is just when it reaches the end
      current_mark = 4
    end

    if is_file_marked(current_mark) then
      self:nav_mark(current_mark)
      return
    end
  until current_mark == start

  vim.notify("No other marks found", vim.log.levels.WARN)
end

return nvim_marks
