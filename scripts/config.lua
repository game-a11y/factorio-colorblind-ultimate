require("scripts.utils")

-- Get the startup config value for the specified name, or false if it does not
-- exist.
---@param name string
---@return int32 | double | boolean | string | Color
function config(name)
  local setting = settings.startup[config_name(name)]
  return setting and setting.value
end

-- Get the player specific runtime config value for the specified name, or false
-- if it does not exist.
---@param player LuaPlayer
---@param name string
---@return int32 | double | boolean | string | Color
function player_config(player, name)
  local setting = player.mod_settings[config_name(name)]
  return setting and setting.value
end

---@type double
---@diagnostic disable-next-line: assign-type-mismatch
IconScale = config("scale")
