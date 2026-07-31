local config_opts = {}

---@class Config 
---@field preselect? boolean
---@field border? string
---@field position? string
---@field preview_length? integer
config_opts.default = {
  preselect = false, -- keeping cursor on current mark
  border = "single", -- border and position are just for the main list_marks func
  position = "center",
  preview_length = 50,
}

---@type Config
config_opts.options = {}

--@param opts Config
-- function config_opts.config_setup(opts)
--   print(opts.preselect, "This works")
-- end

return config_opts
