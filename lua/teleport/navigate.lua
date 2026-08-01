local markers = require("teleport.markings")

local nvim_marks = {
  name = "test",
}

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

function nvim_marks:next()
  local marks = markers.get_nvim_api_marks()

  for _, m in ipairs(marks) do
    print(markers.markersList[m.mark:sub(2)], m.file)
  end

  local current_mark = markers.current_mark()

  if current_mark ~= -1 then
    print(current_mark)
  else
    vim.notify("not in a marked file", vim.log.levels.ERROR)
    return
  end
end

function nvim_marks:prev()
  print("prev =", vim.inspect(self.name))
end

return nvim_marks
