local M = {}

local markers = require("teleport.markings")

-- navMark is a function that what ever paramitor is passed to it will be moved to that mark 
---@param markNum integer
function M.navMark(markNum)
  local mark = markers.markings[markNum]

  for _, m in ipairs(vim.fn.getmarklist()) do
    if m.mark == "'" .. mark then
      vim.cmd("'" .. mark)
      vim.notify("Teleported to Mark: " .. markers.markersList[mark], vim.log.levels.INFO)
      return
    end
  end

  vim.notify("Teleport Mark: " .. markers.markersList[mark] .. " is not set", vim.log.levels.ERROR)
end

return M
