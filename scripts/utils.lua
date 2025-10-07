Mod = "colorblind_ultimate"
ModPath = "__" .. Mod .. "__"
SpritePath = ModPath .. "/graphics/entity/"

Options = {
  none = "none",
  tier = "tier-overlay",
  tier_icon = "tier-overlay-icon",
  tier_entity = "tier-overlay-entity",
  icon = "icon",
  entity = "entity",
  icon_and_entity = "icon-and-entity",
  icon_overlay = "icon-overlay",
  icon_overlay_icon = "icon-overlay-icon",
  icon_overlay_entity = "icon-overlay-entity",
  text_overlay = "text-overlay",
  text_overlay_icon = "text-overlay-icon",
  text_overlay_entity = "text-overlay-entity",
}

---@alias Offset table<int32, int32>

---@type { [string]: Offset }
-- stylua: ignore
Offsets = {
  ["upper-left"]  = { -8, -8 },
  ["upper-right"] = {  8, -8 },
  ["lower-left"]  = { -8,  8 },
  ["lower-right"] = {  8,  8 },
  ["upper"]       = {  0, -8 },
  ["right"]       = {  8,  0 },
  ["left"]        = { -8,  0 },
  ["lower"]       = {  0,  8 },
  ["center"]      = {  0,  0 },
}

Mods = {
  ["base"] = {
    data = true,
    updates = true,
    settings = true,
    order = "ba",
  },
  ["elevated-rails"] = {
    data = true,
  },
  ["quality"] = {
    data = true,
    settings = true,
    order = "bb",
  },
  ["space-age"] = {
    data = true,
    settings = true,
    control = true,
    order = "bc",
  },
  ["Ultracube"] = {
    data = true,
    updates = true,
    settings = true,
    order = "ultra",
  },
}

-- Merge two tables, with t2 overriding values from t1.
--- @param t1 table
--- @param t2 table
--- @return table
function table_merge(t1, t2)
  local t = {}
  for k, v in pairs(t1) do
    t[k] = v
  end
  for k, v in pairs(t2) do
    t[k] = v
  end
  return t
end

-- Transpose a table's keys into values in the returned table.
---@param table table
---@return table
function keys(table)
  local keys = {}
  for key, _ in pairs(table) do
    keys[#keys + 1] = key
  end
  return keys
end

if data then
  -- Get an entry from data, returning false and logging a warning if it does
  -- not exist.
  ---@param _type string
  ---@param name string
  ---@return table | false
  function data:get(_type, name)
    local types = self.raw[_type]
    if not types or not types[name] then
      log("Warning: prototype [" .. _type .. "][" .. name .. "] not found")
      return false
    end
    return types[name]
  end
end

-- Get the item object that corresponds to the entity object.
---@param obj data.EntityPrototype
---@return data.ItemPrototype | false
function get_item_from_entity(obj)
  return data:get("item", obj.minable.result) --[[@as data.ItemPrototype|false]]
end

-- Get the unique config ID corresponding to name.
---@param name string
---@return string
function config_name(name)
  return Mod .. "__" .. name
end

-- Normalize the different Color formats to string indexed (r, g, b, a) and
-- 0-255 values.
---@param color Color
---@return Color
function normalize_color(color)
  color = {
    r = color.r or color[1] or 0,
    g = color.g or color[2] or 0,
    b = color.b or color[3] or 0,
    a = color.a or color[4],
  }
  if color.r > 1 or color.g > 1 or color.b > 1 or (color.a and color.a > 1) then
    color.a = color.a or 255
    return color
  else
    return {
      r = color.r * 255,
      g = color.g * 255,
      b = color.b * 255,
      a = (color.a or 1) * 255,
    }
  end
end

-- Test the equality of two colors, using epsilon as an allowed variation value.
---@param color1 Color
---@param color2 Color
---@param epsilon? number default 1
---@return boolean
function color_equals(color1, color2, epsilon)
  color1 = normalize_color(color1)
  color2 = normalize_color(color2)
  epsilon = epsilon or 1
  return math.abs(color1.r - color2.r) < epsilon
    and math.abs(color1.g - color2.g) < epsilon
    and math.abs(color1.b - color2.b) < epsilon
    and math.abs(color1.a - color2.a) < epsilon
end
