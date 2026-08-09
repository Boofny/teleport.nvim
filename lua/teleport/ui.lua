local M = {}

local navs = require("teleport.navigate")
local markers = require("teleport.markings")
local config = require("teleport.config")
local setup = require("teleport.setup")

---@param file vim.fn.getmarklist.ret.item
local function preview_buffer(file)
  local path = vim.fn.expand(file.file) -- from /home/

  local width = math.floor((vim.o.columns) / 2) -- dynamic width for different screens
  local height = math.floor((vim.o.lines) / 2)
  -- local row = math.floor((vim.o.lines - height) / 3)

  local row = math.floor((vim.o.lines - height) / config.position_cases[config.options.position])
  local col = math.floor((vim.o.columns - width) / 2)

  local buf = vim.api.nvim_create_buf(false, true)

  local ok, lines = pcall(vim.fn.readfile, path, "", config.options.preview_length)
  if not ok then
    lines = { "[Could not read file: " .. file.file .. "]" }
  end

  vim.api.nvim_buf_set_lines(buf , 0, -1, false, lines)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    border = "rounded",
    style = "minimal",

    title = "Preview " .. vim.fn.fnamemodify(file.file, ":t"),
    title_pos = "center",
    focusable = false,
  })

  vim.bo[buf].filetype = vim.filetype.match({ filename = file.file}) or ""
  vim.wo[win].number = true

  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false

  vim.bo[buf].modifiable = false
  vim.bo[buf].readonly = true

  vim.keymap.set("n", "q", function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end

    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end, {buffer = buf})

end

local function help_buffer()

  local lines = {
    "   Keys   Command/Description",
    "  ---------------------------",
    "   1-4 => Select buffer number to move",
    "  <CR> => Select buffer that cursor is on",
    "    dd => Delete mark but not the file buffer",
    "     ? => Show help menu",
    "     J => Move mark down",
    "     K => Move mark up",
    "     q => Exit Teleport menu",
    "     t => Open in tab",
    "     P => Preview File content",
    "     h => Open horizontal split",
    "     v => Open vertical split",
    "     f => Find marks"
  }

  local width = math.floor((vim.o.columns) / 3) -- dynamic width for different screens
  -- local height = math.floor(vim.o.lines / 2)
  local height = #lines
  -- local row = math.floor((vim.o.lines - height) / 3)

  local row = math.floor((vim.o.lines - height) / config.position_cases[config.options.position])
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

    title = "Teleport Help",
    title_pos = "center",
  })

  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false

  vim.bo[buf].modifiable = false
  vim.bo[buf].readonly = true

  local ns = vim.api.nvim_create_namespace("teleport")
  vim.api.nvim_buf_set_extmark(buf, ns, 0, 0, {
    end_col = 29,
    hl_group = "Keyword",
  })

  vim.api.nvim_buf_set_extmark(buf, ns, 1, 0, {
    end_col = 29,
    hl_group = "Comment",
  })

  for line = 2, 13 do
    vim.api.nvim_buf_set_extmark(buf, ns, line, 2, {
      end_col = 6,
      hl_group = "String",
    })

    vim.api.nvim_buf_set_extmark(buf, ns, line, 7, {
      end_col = 9,
      hl_group = "Comment",
    })
  end

  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(win, true)
  end, {buffer = buf})
end


-- just for listing and chosing the files not to be stored elsewhere
function M.find_marks()
  vim.ui.select(markers.get_teleport_marks(), {
    prompt = "Find marks",
    format_item = function(item)
      return "" .. item.fileName
    end,
  }, function(choice)
    if choice then
      navs:nav_mark(markers.markersList[choice.markName])
    end
  end)
end

local function is_modified(file)
  local bufnr = vim.fn.bufnr(file)

  if bufnr == -1 then
    return false
  end

  return vim.bo[bufnr].modified
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
      local modified_status = is_modified(mark.file) and "[+]" or ""
      local git_status = setup.git_status(mark.file)
      table.insert(lines,
        string.format("%s %s %s %s%s", markers.markersList[letter], vim.fn.fnamemodify(mark.file, ":."), modified_status, git_status["X"], git_status["Y"])
      )
    else
      table.insert(lines, string.format("%s [ EMPTY ]", markers.markersList[letter]))
    end
  end

  local width = math.floor((vim.o.columns) / 2) -- dynamic width for different screens
  local height = #lines

  -- position bellow
  local row = math.floor((vim.o.lines - height) / config.position_cases[config.options.position])
  local col = math.floor((vim.o.columns - width) / 2)

  local buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local pos = -1

  if config.options.preselect then
    pos = markers.current_mark()
  end

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    border = config.options.border,
    style = "minimal",

    title = "Teleport",
    title_pos = "center",
  })

  if pos ~= -1 then
    vim.api.nvim_win_set_cursor(win, {pos, 0}) -- just a nice thing to keep the cursor inline with what mark is on
  end


  vim.wo[win].cursorline = true

  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false

  -- allowing this for the movment of the buffer 
  vim.bo[buf].modifiable = true
  vim.bo[buf].readonly = false

  vim.keymap.set("n", "1", function()
    vim.api.nvim_win_close(win, true)
    navs:nav_mark(1)
  end, {buffer = buf})

  vim.keymap.set("n", "2", function()
    vim.api.nvim_win_close(win, true)
    navs:nav_mark(2)
  end, {buffer = buf})

  vim.keymap.set("n", "3", function()
    vim.api.nvim_win_close(win, true)
    navs:nav_mark(3)
  end, {buffer = buf})

  vim.keymap.set("n", "4", function()
    vim.api.nvim_win_close(win, true)
    navs:nav_mark(4)
  end, {buffer = buf})

  vim.keymap.set("n", "q", function()
    local buffer_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local nvim_marks = markers.get_nvim_api_marks_by_slot()
    local new_order = {}

    -- run checks to make sure buffer win is not changed
    for _, m in ipairs(buffer_lines) do
      if tonumber(m:sub(1,1)) then
        new_order[#new_order+1] = tonumber(m:sub(1,1))
      else
        print("Not a num, cause an error here")
        return
      end
    end

    -- checking mark order
    for index, num in ipairs(new_order) do
      if index ~= num then
        break -- end the loop and go to the next part of the func since its out of order
      end

      if index == #new_order then
        vim.api.nvim_win_close(win, true)
        return -- stop here if the order is not changed no need to do any more work
      end

    end

    local count = 1
    for _, num in ipairs(new_order) do
      local target_mark = markers.markings[count]
      if nvim_marks[num] then

        local file = vim.fn.expand(nvim_marks[num].file)

        if vim.fn.filereadable(file) == 1 then

          -- Creates buffer without loading file contents
          local bufnr = vim.fn.bufadd(file)

          vim.fn.setpos("'" .. target_mark, {
            bufnr,
            nvim_marks[num].pos[2],
            nvim_marks[num].pos[3],
            nvim_marks[num].pos[4],
          })
        end

        -- print("add mark", nvim_marks[num].mark:sub(2))
      else
        pcall(vim.api.nvim_del_mark, target_mark)
        -- print("ignore" .. count .. "num=" .. num)
      end
      count = count + 1
    end

    vim.api.nvim_win_close(win, true)
  end, {buffer = buf})

  -- version that just closes the buffer 
  vim.keymap.set("n", "dd", function()
    local cursor = vim.api.nvim_win_get_cursor(win)
    local line_num = cursor[1]
    vim.api.nvim_win_close(win, true)
    vim.cmd("delmark " .. markers.markings[line_num])
    print("Teleport mark removed:", line_num)
  end, {buffer = buf, nowait = true})

  vim.keymap.set("n", "<CR>", function()
    local cursor = vim.api.nvim_win_get_cursor(win)
    local line_num = cursor[1]
    local marks = markers.get_nvim_api_marks()

    for _, mark in ipairs(marks) do
      if mark.mark:sub(2) == markers.markings[line_num] then
        vim.api.nvim_win_close(win, true)
        navs:nav_mark(line_num)
        return
      end
    end

    vim.api.nvim_win_close(win, true)
    vim.notify("Teleport Mark " .. line_num .. " is not set", vim.log.levels.ERROR)
  end, {buffer = buf})

  vim.keymap.set("n", "f", function()
    vim.api.nvim_win_close(win, true)
    M.find_marks()
  end, {buffer = buf})

  vim.keymap.set("n", "J", function()
    local cursor = vim.api.nvim_win_get_cursor(win)
    local line = cursor[1]
    -- Don't move the last line down
    if line >= vim.api.nvim_buf_line_count(buf) then
      return
    end
    -- Read the current line and the one below it
    local buf_lines = vim.api.nvim_buf_get_lines(buf, line - 1, line + 1, false)
    -- Write them back in reverse order
    vim.api.nvim_buf_set_lines(buf, line - 1, line + 1, false, {
      buf_lines[2],
      buf_lines[1],
    })
    -- Keep the cursor on the moved item
    vim.api.nvim_win_set_cursor(win, { line + 1, cursor[2] })
  end, { buffer = buf })

  vim.keymap.set("n", "K", function()
    local cursor = vim.api.nvim_win_get_cursor(win)
    local line = cursor[1]
    -- Don't move the last line down
    if line <= 1 then -- correct
      return
    end

    -- Read the current line and the one below it
    local buf_lines = vim.api.nvim_buf_get_lines(buf, line - 2, line, false)
    -- Write them back in reverse order
    vim.api.nvim_buf_set_lines(buf, line - 2, line, false, {
      buf_lines[2],
      buf_lines[1],
    })
    -- Keep the cursor on the moved item
    vim.api.nvim_win_set_cursor(win, { line - 1, cursor[2] })
  end, {buffer = buf})

  vim.keymap.set("n", "t", function() -- tabbing 
    local cursor = vim.api.nvim_win_get_cursor(win)
    local line_num = cursor[1]
    local marks = markers.get_nvim_api_marks()

    for _, mark in ipairs(marks) do
      if mark.mark:sub(2) == markers.markings[line_num] then
        vim.api.nvim_win_close(win, true)
        vim.cmd("tabnew " .. mark.file)
        return
      end
    end

    vim.notify("Teleport Mark " .. line_num .. " is not set", vim.log.levels.ERROR)
  end, {buffer = buf})

  vim.keymap.set("n", "P", function() -- Preview
    local cursor = vim.api.nvim_win_get_cursor(win)
    local line_num = cursor[1]
    local marks = markers.get_nvim_api_marks()

    for _, mark in ipairs(marks) do
      if mark.mark:sub(2) == markers.markings[line_num] then
        preview_buffer(mark)
        return
      end
    end

    vim.notify("Teleport Mark " .. line_num .. " is not set", vim.log.levels.ERROR)
  end, {buffer = buf})

  vim.keymap.set("n", "v", function()
    local cursor = vim.api.nvim_win_get_cursor(win)
    local line_num = cursor[1]
    local marks = markers.get_nvim_api_marks()

    for _, mark in ipairs(marks) do
      if mark.mark:sub(2) == markers.markings[line_num] then
        vim.api.nvim_win_close(win, true)
        vim.cmd("rightbelow vsplit " .. vim.fn.fnamemodify(mark.file, ":."))
        return
      end
    end

    vim.notify("Teleport Mark " .. line_num .. " is not set", vim.log.levels.ERROR)
  end, {buffer = buf})

  vim.keymap.set("n", "h", function()
    local cursor = vim.api.nvim_win_get_cursor(win)
    local line_num = cursor[1]
    local marks = markers.get_nvim_api_marks()

    for _, mark in ipairs(marks) do
      if mark.mark:sub(2) == markers.markings[line_num] then
        vim.api.nvim_win_close(win, true)
        vim.cmd("rightbelow split " .. vim.fn.fnamemodify(mark.file, ":."))
        return
      end
    end

    vim.notify("Teleport Mark " .. line_num .. " is not set", vim.log.levels.ERROR)
  end, {buffer = buf})

  vim.keymap.set("n", "?", function()
    help_buffer()
  end, {buffer = buf})
end


return M
