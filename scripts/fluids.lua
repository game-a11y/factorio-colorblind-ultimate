require("scripts.config")
require("scripts.icons")

-- Shift fluid icons for overlaying on a recipe icon.
---@param fluid string
---@param shift? Offset
---@param scale? double
---@return data.IconData ...
function get_and_shift_fluid_icons(fluid, shift, scale)
  return table.unpack(create_overlay_from_icons(icons_from_obj(data.raw.fluid[fluid]), shift, scale))
end

---@param fluid string
function replace_solid_fuel_recipe(fluid)
  local recipe = data:get("recipe", "solid-fuel-from-" .. fluid)
  if recipe then
    local obj = data:get(recipe.results[1].type, recipe.results[1].name)
    if obj then
      replace_icons(recipe, icons_from_obj(obj))
      overlay_icon(recipe, get_and_shift_fluid_icons(fluid, Offsets["upper-left"], 0.5))
    end
  end
end

---@param result string
function replace_casting_recipe(result)
  local recipe = data:get("recipe", "casting-" .. result)
  if recipe then
    local result_obj = data:get(recipe.results[1].type, recipe.results[1].name)
    local ingredient = data:get(recipe.ingredients[1].type, recipe.ingredients[1].name)
    if result_obj and ingredient then
      replace_icon(recipe, EmptyIcon)
      overlay_icon(recipe, table.unpack(create_overlay_from_icons(icons_from_obj(result_obj), { -5, 6 }, 0.8)))
      overlay_icon(recipe, table.unpack(create_overlay_from_icons(icons_from_obj(ingredient), { 5, -4 }, 0.8)))
    end
  end
end
