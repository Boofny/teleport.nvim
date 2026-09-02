local config_opts = {}

---@class Config 
---@field preselect? boolean
---@field border? string
---@field position? string
---@field preview_length? integer
---@field save_warning? boolean
---@field file_modify_status? boolean
---@field file_git_status? boolean
---@field file_git_status_color? boolean
---@field exclude? string[]

---@type Config
config_opts.default = {
  preselect = false, -- keeping cursor on current mark
  border = "single", -- border and position are just for the main list_marks func
  position = "center", -- top, center, bottom these three options with center being default
  preview_length = 50, -- how long and how much memory is used for previewing files
  save_warning = true, -- get a reminder that marks are not saved in non git repos
  file_modify_status = true, -- show [+] modify status inline the list_mark_files menu
  file_git_status = true, -- showing XY of git status inline the the list menu
  file_git_status_color = true, -- XY git status symbols being colored in
  exclude = {} -- by default no files or dir's are exluded from saving marks
}

config_opts.position_cases = {
  center = 3,
  top = 20,
  bottom = 1
}

---@type Config
config_opts.options = {}

return config_opts
