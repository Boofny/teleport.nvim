local config_opts = {}

---@class Config 
---@field preselect? boolean
---@field border? string
---@field position? string
---@field preview_length? integer
config_opts.default = {
  preselect = false, -- keeping cursor on current mark
  border = "single", -- border and position are just for the main list_marks func
  position = "center", -- top, center, bottom these three options with center being default
  preview_length = 50, -- how long and how much memory is used for previewing files
  -- show_file_status = true,
}

config_opts.position_cases = {
  center = 3,
  top = 20,
  bottom = 1
}

---@type Config
config_opts.options = {}

return config_opts
