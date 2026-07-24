local M = {}

local markers = require("teleport.markings")
local setup = require("teleport.setup")

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
function M.add_mark()
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
function M.add_mark_override(markNum)
  vim.cmd("mark " .. markers.markings[markNum])
  vim.notify("Teleport marked: " .. markNum, vim.log.levels.INFO)
end

-- not being used just testing things
function M.testFunc()
  ---@type TeleportMark[]
  local mapper = markers.get_teleport_marks()
  for _, m in ipairs(mapper) do
    print(m.markName, m.fileName)
  end

  ---@class Wanted
  ---@field filename string
  ---@type Wanted[]
  local wanted = {}

  local marks = vim.fn.getmarklist()

  for _, m in ipairs(marks) do
    if m.mark:match("^'[A-D]$") then
      table.insert(wanted, {filename = vim.fn.fnamemodify(m.file, ":.")})
    end
  end

  for _, w in pairs(wanted) do
    print("Here: ", w.filename)
  end

  local list = markers.get_teleport_marks()
  local json_string = vim.json.encode(list)
  print(json_string)

  local jsonsting = vim.json.encode(wanted)
  print("This is just getting the ones i want", jsonsting)

end

-- Will have to be ran before anything else first
function M.Setup() --TODO:
  -- first things first if the user is NOT in a git repo dont save the mappings 
  if not setup.in_git_repo() then
    print("Stop here dont save the config or anything")
    return -- stop here and dont do any more set up
  end

  print("continue to the rest of the config")

  if not setup.data_conf_exist() then
    print("create it")
    local saved = {}

    local mar = vim.fn.getmarklist()
    for _, m in ipairs(mar) do
      if m.mark:match("^'[A-D]$") then
        table.insert(saved, m)
      end
    end

    -- will be used upon exiting the project in order to save the bindings
    local json_stringer = vim.json.encode(saved)
    local hashed = vim.fn.sha256(json_stringer) -- how the hash is made for the file name maybe use the git head
    print(hashed)

  else
    print("found it read it to find the file config")
  end

  -- on exit save think it uses async function

end

return M
