local M = {}

-- where functions will be created to be used in commands inside of teleport.lua
function M.greet()
  print("Hello from my plugin!")
end

function M.addMark() -- should be the command C-a
  -- some things could be like have a list of ABCD and list of the current mappings if the next one is missing then add a mark if all marks are full promt user to replace the marks if they want
  print(markings[markNum])
end

function M.clearMarks()
  vim.cmd("delmarks BCD")
end

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

function M.list_mark_files()
  local lines = {}

  for _, mark in ipairs(vim.fn.getmarklist()) do
    if mark.mark:match("^'[A-D]$") then
      table.insert(
        lines,
        string.format(
          "%s %s",
          markersList[mark.mark:sub(2)],
          vim.fn.fnamemodify(mark.file, ":t")
        )
      )
    end
  end

  local width = 30
  local height = #lines
  -- local row = math.floor((vim.o.lines - height) / 2)
  -- local col = math.floor((vim.o.columns - width) / 2)

  local buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = 3,
    col = 112,
    border = "rounded",
    style = "minimal",

    title = "Teleport",
    title_pos = "center",
  })

  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(win, true)
  end, {buffer = buf})
end

return M



