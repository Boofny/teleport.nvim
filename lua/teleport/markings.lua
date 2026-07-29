local M = {}

---@class Marking
M.markings = {
  [1] = "A",
  [2] = "B",
  [3] = "C",
  [4] = "D"
}

M.markersList = {
  A = 1,
  B = 2,
  C = 3,
  D = 4
}

-- clearMarks BCD
function M.clearMarks()
  vim.cmd("delmarks BCD")
end

M.ORDEREDMARKS = "ABCD"

-- function get_teleport_marks only gets the marks from the ranges of A-D or to be change later NOTE: it does return a custom table that will be subject to change later
---@class TeleportMark
---@field markName string
---@field fileName string
---@field filePath string

---@return TeleportMark[]
function M.get_teleport_marks() -- just to be used for ui and visual things does not return full file paths
  local marks = {}

  for _, mark in ipairs(vim.fn.getmarklist()) do
    if mark.mark:match("^'[A-D]$") then
      table.insert(marks, {
        markName = mark.mark:sub(2), -- mark name like A or Bk
        fileName = vim.fn.fnamemodify(mark.file, ":."), -- file path from the cwd like lua/teleport/init.lua
        filePath = mark.file, -- full file path
      })
    end
  end

  return marks
end

function M.get_nvim_api_marks()
  ---@type vim.fn.getmarklist.ret.item[]
  local marks = {}

  for _, mark in ipairs(vim.fn.getmarklist()) do
    if mark.mark:match("^'[A-D]$") and mark.file then
      table.insert(marks, {
        mark = mark.mark, -- mark name like A or Bk
        file = mark.file, -- file path from the cwd like lua/teleport/init.lua
        pos = mark.pos, -- full file path
      })
    end
  end

  return marks
end

---@return string
function M.current_mark()
  local nvim_marks = M.get_nvim_api_marks()
  local current_file_name = vim.fn.expand('%')

  for _, m in ipairs(nvim_marks) do
    if vim.fn.fnamemodify(m.file, ":.") == current_file_name then
      return tostring(M.markersList[m.mark:sub(2)])
    end
  end

  return "" -- indicating an error or non mark
end

return M
