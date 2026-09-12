local M = {}

local markers = require("teleport.markings")
local setup_file = require("teleport.setup")
local config = require("teleport.config")

local ui = require("teleport.ui")
local nav = require("teleport.navigate")

-- for add_mark and add_mark_override 
M.list_mark_files = ui.list_mark_files
M.find_marks = ui.find_marks
M.current_mark = markers.current_mark
M.nav = nav -- passing the nav object not just an func

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

-- add_mark checks the order of the marks first then if there is an avalible spot ex: B then take the next spot for the mark
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
      markers.set_mark(letter)
      -- vim.cmd("mark " .. letter)
      print("Teleport marked: " .. markers.markersList[letter])
      break
    end
  end

  -- when map of marks gets full prompt user to replace one
  if mapFull(lookup) then
    local current_file_mark = markers.current_mark()
    local marks = markers.get_teleport_marks()

    if current_file_mark ~= -1 then
      -- vim.notify("Some error overloading marks", vim.log.levels.ERROR)
      -- return
      for _, mark in ipairs(marks) do
        if markers.markersList[mark.markName] == current_file_mark then
          vim.notify("File is already marked at mark: " .. markers.markersList[mark.markName], vim.log.levels.WARN)
          return -- dont run the rest of the func
        end
      end

    end

    vim.ui.select(marks, {
      prompt = "All marks taken, replace?",
      format_item = function(item)
        return "" .. item.fileName
      end,
    }, function(choice)
      if choice then
        -- vim.cmd("mark " .. choice.markName)
        markers.set_mark(choice.markName)
      end
    end)

  end


end

-- add_mark_override overrides the addMark function in order to have custom mark setting rather than auto
---@param markNum integer
function M:add_mark_override(markNum)
  -- vim.cmd("mark " .. markers.markings[markNum])
  markers.set_mark(markers.markings[markNum])
  vim.notify("Teleport marked: " .. markNum, vim.log.levels.INFO)
end

function M.testFunc()
end

---@param opts? Config
function M.setup(opts)
  opts = opts or {}

  local user_opts = vim.tbl_deep_extend(
    "force",
    config.default,
    opts
  )

  config.options = user_opts

  local origin = setup_file.get_top_level()

  if config.options.exclude ~= nil and #config.options.exclude > 0 then
    for _, project_path in ipairs(config.options.exclude) do
      if project_path ==  origin then
        vim.notify_once("Project path excluded from teleport plugin.", vim.log.levels.WARN)
        return
      end
    end
  end

  -- first things first if the user is NOT in a git repo dont save the mappings

  if not origin then
    if user_opts.save_warning then
      vim.notify("Teleport plugin can not save marks on non git repo projects!", vim.log.levels.WARN)
    end
    return
  end


  if not setup_file.data_conf_exist() then
    vim.fn.mkdir(setup_file.plugin_dir, "p")
  end

  -- find the file that owns this repo's marks
  local file_name = vim.fn.sha256(origin)
  local path = vim.fs.joinpath(setup_file.plugin_dir, file_name .. ".json")

  -- LOAD MARKS ---

  local session_root = vim.fn.getcwd()

  local open_file = io.open(path, "r")

  if open_file then
    local content = open_file:read("*all")
    open_file:close()

    local ok, json_marks = pcall(vim.json.decode, content)
    -- json_marks is of type Origin_Saved but lsp wont allow me to define it but its just this
    -- origin_name string
    -- marks vim.fn.getmarklist.ret.item[]

    -- print(json_marks.origin_name) debug print for proof

    if not ok or type(json_marks) ~= "table" then -- if some fail to decode just have no marks
      vim.notify( "Teleport: Failed to decode mark file", vim.log.levels.WARN)
      json_marks = {}
    end

    for _, mark in ipairs(json_marks.marks) do

      local file = vim.fn.expand(vim.fs.joinpath(session_root, mark.file)) -- also one of the changes 

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

      ---@type vim.fn.getmarklist.ret.item[]
      local saved = {}


      local marks = vim.fn.getmarklist()

      for _, m in ipairs(marks) do
        if m.mark:match("^'[A-D]$") then

          local rel_file = vim.fn.fnamemodify(m.file, ":.") -- just save the relative path not the full one like m.file does
          -- Save only what Teleport needs
          table.insert(saved, { mark = m.mark, file = rel_file, pos = m.pos })
        end
      end

      ---@class Origin_Saved
      ---@field origin_name string
      ---@field marks vim.fn.getmarklist.ret.item[]

      ---@type Origin_Saved
      local origin_saved = {
        origin_name = origin,
        marks = saved
      }

      local json_string = vim.json.encode(origin_saved) -- this was saved before 

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

---@param path string
---@return boolean
local function file_path_exists(path)
  return vim.uv.fs_stat(path) ~= nil
end

---@param mark_info Info
local function user_delete_promt(mark_info)

  local choice = vim.fn.confirm("Are you sure you want to delete mark file for " .. "[" .. mark_info.origin .. "]", "&Yes\n&No", 0)

  if choice ~= 1 then
    vim.notify("Aborting action.", vim.log.levels.ERROR)
    return
  end

  local success, err = os.remove(mark_info.full_proj_path)

  if success then
      print("File deleted successfully!")
  else
      print("Failed to delete file: " .. tostring(err))
  end

end

-- This is the complete last resort do NOT use without reading docs
function M.manage_mark_projects()

  local file_count = 0 -- count used for later like if over 100 files are in here then do somthing

  ---@class Info 
  ---@field origin string
  ---@field full_proj_path string
  ---@field file_name string
  ---@field display_origin string
  local project_info = {}

  if not setup_file.data_conf_exist() then -- check if this even exists
    vim.notify_once("Data directory for teleport does not exits can't clear any cache.", vim.log.levels.INFO)
    return
  end

  local items = vim.fn.readdir(setup_file.plugin_dir)

  for _, file in ipairs(items) do
    file_count = file_count + 1

    if file_count > 100 then
      print("To many files have to manually clear cache or promt the nuclear option command")
      return
    end

    local full_path = vim.fs.joinpath(setup_file.plugin_dir, file)

    local open_file, err = io.open(full_path, "r")

    if not open_file then
      print("Error: " .. err)
      return
    end

    local content = open_file:read("*all")

    local ok, json_origin = pcall(vim.json.decode, content)

    if not ok or type(json_origin) ~= "table" then -- if some fail to decode just have no marks
      vim.notify( "Teleport: Failed to decode mark file", vim.log.levels.WARN)
      json_origin = {}
    end

    local name = vim.fn.fnamemodify(json_origin.origin_name, ":~")

    if file_path_exists(json_origin.origin_name) then
      table.insert(project_info, {display_origin = name, origin = name, full_proj_path = full_path, file_name = file})
    else
      table.insert(project_info, {display_origin = name .. " [path no longer exists]", origin = name, full_proj_path = full_path, file_name = file})
    end

    open_file:close()
  end

  vim.ui.select(project_info, {
    prompt = "Manage Teleport projects.",
    format_item = function(item)
      return item.display_origin
    end,
  }, function(choice)
    if choice then
      ui.manage_marks_buffer(choice, function(user_manage_option)

        if user_manage_option == nil then
          print("Quit")
          return
        end

        if user_manage_option == 2 then
          user_delete_promt(choice)
        end

        if user_manage_option == 1 then
          vim.cmd.edit(choice.full_proj_path)
        end

      end)
    end
  end)

end

return M
