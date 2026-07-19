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

-- Gets the neovim set file marks so anything that is in the list_mark_files files
---@class TeleportMark
---@field markName string
---@field fileName string
---@field filePath string

---@return TeleportMark[]
function M.get_file_marks()
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
return M
