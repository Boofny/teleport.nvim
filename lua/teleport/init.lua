local M = {}

local markers = require("teleport.markings")
local setup = require("teleport.setup")

local ui = require("teleport.ui")
local nav = require("teleport.navigate")

M.list_mark_files = ui.list_mark_files
M.find_marks = ui.find_marks
M.nav_mark = nav.nav_mark
M.current_mark = markers.current_mark

-- where functions will be created to be used in commands inside of teleport.lua

-- mapFull checks if the map that neovim has for marks A-D is all filled 
---@return boolean
local function mapFull(lookupTable)
  for i = 1, #markers.ORDEREDMARKS do
    local letter = markers.ORDEREDMARKS:sub(i, i)
    if not lookupTable["'" .. letter] then
      return false -- found a free slot, so it's not full
    end
  end
  return true -- all four are taken
end

-- addMark checks the order of the marks first then if there is an avalible spot ex: B then take the next spot for the mark
-- this also uses the logic for the mapFull in order to prompt user for the file they want to replace
function M:add_mark()
  local lookup = {}

  -- make the look up table based on the marks in the map of marks in neovim
  for _, mark in ipairs(vim.fn.getmarklist()) do
    lookup[mark.mark] = mark
  end

  -- auto adding to the next mark in the set
  for i = 1, #markers.ORDEREDMARKS do
    local letter = markers.ORDEREDMARKS:sub(i, i)

    if not lookup["'" .. letter]then -- has a mark and is empty
      vim.cmd("mark " .. letter)
      print("Teleport marked: " .. markers.markersList[letter])
      break
    end
  end

  -- when map of marks gets full prompt user to replace one
  if mapFull(lookup) then

    local marks = markers.get_teleport_marks()

    vim.ui.select(marks, {
      prompt = "All marks taken, replace?",
      format_item = function(item)
        return "" .. item.fileName
      end,
    }, function(choice)
      if choice then
        vim.cmd("mark " .. choice.markName)
      end
    end)

  end

end

-- addMarkBypass overrides the addMark function in order to have custom mark setting rather than auto
---@param markNum integer
function M:add_mark_override(markNum)
  vim.cmd("mark " .. markers.markings[markNum])
  vim.notify("Teleport marked: " .. markNum, vim.log.levels.INFO)
end

function M.testFunc()
  local m = nav.nvim_marks

  for _, l  in ipairs(m.marks) do
    print(l.file, "\n")
  end
  m:next()
end

-- Will have to be ran before anything else first
function M.Setup()

  -- first things first if the user is NOT in a git repo dont save the mappings
  if not setup.in_git_repo() then
    vim.notify("Teleport plugin can not save marks on non git repo projects!", vim.log.levels.INFO)
    return
  end


  if not setup.data_conf_exist() then
    vim.fn.mkdir(setup.plugin_dir, "p")
  end

  -- find the file that owns this repo's marks
  local origin = setup.get_repo_root()
  local file_name = vim.fn.sha256(origin)
  local path = vim.fs.joinpath(setup.plugin_dir, file_name .. ".json")

  -- LOAD MARKS ---

  local open_file = io.open(path, "r")

  if open_file then
    local content = open_file:read("*all")
    open_file:close()

    local ok, json_marks = pcall(vim.json.decode, content)

    if not ok or type(json_marks) ~= "table" then
      vim.notify(
        "Teleport: Failed to decode mark file",
        vim.log.levels.WARN
      )
      return
    end


    for _, mark in ipairs(json_marks) do
      local file = vim.fn.expand(mark.file)

      if vim.fn.filereadable(file) == 1 then

        -- Creates buffer without loading file contents
        local bufnr = vim.fn.bufadd(file)

        vim.fn.setpos(mark.mark, {
          bufnr,
          mark.pos[2],
          mark.pos[3],
          mark.pos[4],
        })

      end
    end
  end


  -- SAVE MARKS ON EXIT --- 

  local group = vim.api.nvim_create_augroup(
    "Teleport",
    { clear = true }
  )

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,

    callback = function()

      local saved = {}

      local marks = vim.fn.getmarklist()

      for _, m in ipairs(marks) do

        if m.mark:match("^'[A-D]$") then

          -- Save only what Teleport needs
          table.insert(saved, {
            mark = m.mark,
            file = m.file,
            pos = m.pos,
          })

        end

      end


      local json_string = vim.json.encode(saved)

      -- Atomic write/check ---

      local tmp_path = path .. ".tmp"

      local result = vim.fn.writefile(
        { json_string },
        tmp_path,
        "b"
      )

      if result ~= 0 then
        vim.notify(
          "Teleport: Failed writing marks",
          vim.log.levels.ERROR
        )
        return
      end


      vim.fn.rename(tmp_path, path)

    end,
  })
end

function M.clear_cache()
end

return M
