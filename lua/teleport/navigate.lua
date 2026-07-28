local M = {}

local markers = require("teleport.markings")

-- nav_mark is a function that what ever paramitor is passed to it will be moved to that mark 
---@param markNum integer
function M.nav_mark(markNum)
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

---@class NvimMarks
---@field marks vim.fn.getmarklist.ret.item[]

local nvim_marks = {
  marks = markers.get_nvim_api_marks()
}

---@param self NvimMarks
function nvim_marks:next()
  print("self =", vim.inspect(self))
end

---@param self NvimMarks
function nvim_marks:prev()
  print(self.marks[1].file)
end

M.nvim_marks = nvim_marks

return M
