local M = {}

local navs = require("teleport.navigate")
local markers = require("teleport.markings")
local config = require("teleport.config")
-- local setup = require("teleport.setup")

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
    "     H => Open horizontal split",
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

---@param git_sign string
---@return string
local function get_hl_group(git_sign)
  -- if git_sign:sub(1, 1) == " " or git_sign:sub(2, 2) == " " then
  -- end

  if git_sign == "??" then return "Keyword" end
  if git_sign == "!!" then return "Function" end

  local find_m = string.find(git_sign, "M", 1, true)
  if find_m then
    return "Error"
  end

  return "String" -- dont know what to add as the default in case there is a case that is not handled
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
  local status_marks = markers.marks_git_status()

  ---@class Git_status
  ---@field mark integer
  ---@field mark_line string
  ---@field git_status string

  ---@type Git_status[]
  local git_status_line = {}

  if not status_marks then
    status_marks = {}
  end

  for _, letter in ipairs({ "A", "B", "C", "D" }) do
    local mark = existing[letter]

    if mark then
      local formated_file_name = vim.fn.fnamemodify(mark.file, ":.")
      local entry = status_marks[formated_file_name]

      local modified_status = is_modified(mark.file) and "[+]" or ""

      local line = string.format("%s %s", markers.markersList[letter], formated_file_name)

      if config.options.file_modify_status then
        line = line .. " " .. modified_status .. (modified_status ~= "" and " " or "")
      end

      if config.options.file_git_status and entry then
        local x = entry.X ~= " " and entry.X or ""
        local y = entry.Y ~= " " and entry.Y or ""
        line = line .. x .. y

        table.insert(git_status_line, {
          mark = markers.markersList[letter],
          mark_line = line,
          git_status = entry.X .. entry.Y
        })

      end

      table.insert(lines, line)
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

  if git_status_line[1] ~= nil and config.options.file_git_status_color then -- check that atleast the first mark does exist

    for _, val in pairs(git_status_line) do
      local line_len = #val.mark_line
      local git_status_len

      if val.git_status:sub(1,1) == " " or val.git_status:sub(1, 2) == " " then
        git_status_len = 1
      else
        git_status_len = 2
      end

      local ns = vim.api.nvim_create_namespace("teleportGitStatus")

      vim.api.nvim_buf_set_extmark(buf, ns, val.mark - 1, line_len - git_status_len, {
        end_col = #val.mark_line,
        hl_group = get_hl_group(val.git_status),
      })
    end

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
    local success = vim.api.nvim_del_mark(markers.markings[line_num])
    if not success then
      vim.schedule(function()
        vim.notify("Error removing mark: ", vim.log.levels.ERROR)
      end)
    end
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

  vim.keymap.set("n", "H", function()
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

function M.manage_marks_buffer(project_info, on_result)
  local lines = {
    "Project: " .. project_info.display_origin,
    "",
    "Manage options: [E] Edit, [D] Delete, [q] Quit",
  }

  local width = math.floor((vim.o.columns) / 3) -- dynamic width for different screens
  local height = #lines

  local row = math.floor((vim.o.lines - height) / config.position_cases[config.options.position])
  local col = math.floor((vim.o.columns - width) / 2)

  local buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local ns = vim.api.nvim_create_namespace("teleport")

  -- Line 0: "Project: <origin>"
  vim.api.nvim_buf_set_extmark(buf, ns, 0, 0, {
    end_col = #"Project:",
    hl_group = "Normal",
  })
  vim.api.nvim_buf_set_extmark(buf, ns, 0, #"Project: ", {
    end_col = #lines[1],
    hl_group = "Directory",
  })

  -- Line 2: "Manage options: [E] Edit, [X] Delete, [q] Quit"
  local opts_line = lines[3]
  vim.api.nvim_buf_set_extmark(buf, ns, 2, 0, {
    end_col = #"Manage options:",
    hl_group = "Normal",
  })

for key_start, key, label_start, label in
  opts_line:gmatch("()%[(%a)%]%s()(%a+)")
do
  vim.api.nvim_buf_set_extmark(buf, ns, 2, key_start - 1, {
    end_col = key_start - 1 + #("[" .. key .. "]"),
    hl_group = "String", -- Special
  })
  vim.api.nvim_buf_set_extmark(buf, ns, 2, label_start - 1, {
    end_col = label_start - 1 + #label,
    hl_group = "String",
  })
end

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    border = "rounded",
    style = "minimal",

    title = "Manage Center",
    title_pos = "center",
  })

  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false

  vim.bo[buf].modifiable = false
  vim.bo[buf].readonly = true

  vim.keymap.set("n", "E", function()
    vim.api.nvim_win_close(win, true)
    if on_result then on_result(1) end
  end, {buffer = buf})

  vim.keymap.set("n", "D", function()
    vim.api.nvim_win_close(win, true)
    if on_result then on_result(2) end
  end, {buffer = buf})

  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(win, true)
    if on_result then on_result(nil) end
  end, {buffer = buf})

end


return M
