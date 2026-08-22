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

-- function get_teleport_marks only gets the marks from the ranges of A-D or to be change later NOTE: it does return a custom table
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
        file = mark.file, -- file path from ~/
        pos = mark.pos, -- full file path
      })
    end
  end

  return marks
end

function M.get_nvim_api_marks_by_slot()
  ---@type table<integer, vim.fn.getmarklist.ret.item>
  local marks = {}
  for _, mark in ipairs(vim.fn.getmarklist()) do
    if mark.mark:match("^'[A-D]$") and mark.file then
      local letter = mark.mark:sub(2) -- "A", "B", "C", or "D"
      local index = string.byte(letter) - string.byte("A") + 1 -- A=1, B=2, C=3, D=4
      marks[index] = {
        mark = mark.mark,
        file = mark.file,
        pos = mark.pos,
      }
    end
  end
  return marks
end

---@return integer
function M.current_mark()
  local nvim_marks = M.get_nvim_api_marks()
  local current_file_name = vim.fn.expand('%')

  for _, m in ipairs(nvim_marks) do
    if vim.fn.fnamemodify(m.file, ":.") == vim.fn.fnamemodify(current_file_name, ":.") then
      return M.markersList[m.mark:sub(2)]
    end
  end

  return -1 -- indicating an error or non mark
end

---@param input_string string
---@return table<string>
local function split_by_line(input_string)
  local paths = {}

  for val in input_string:gmatch("[^\n]+") do
    table.insert(paths, val)
  end
  return paths
end

---@param marks_table string[]
local function extract_file_status(marks_table)

  ---@type table<string, Status_table>
  local git_status_table = {}

  for _, i in pairs(marks_table) do
    git_status_table[i:sub(4)] = {
      X = i:sub(1,1), ---@type string
      Y = i:sub(2,2), ---@type string
    }
  end

  return git_status_table
end

function M.dont_use_yet()
  local command_string = ""
  local marks = M.get_teleport_marks()

  for _, val in pairs(marks) do
    command_string = command_string .. " " .. val.fileName
  end

  local resp = vim.fn.system(string.format("git status %s --porcelain", command_string))

  local printers = split_by_line(resp)

  if #printers == 0 then
    print("no marks have git changes")
    return
  end

  local extraction = extract_file_status(printers)

  for filename, e in pairs(extraction) do
    print(filename, e["X"], e["Y"])
  end

end

return M
