require("scripts.config")
require("scripts.icon_overlays")
require("scripts.icons")
require("scripts.sprites")

-- Update the color of a data.ResourceEntityPrototype.
---@param name string
function update_resource_color(name)
  local setting = config(name .. "-map-color") --[[@as Color]]
  if setting then
    local prototype = data:get("resource", name) --[[@as data.ResourceEntityPrototype]]
    if prototype and not color_equals(setting, prototype.map_color) then
      prototype.map_color = setting
    end
  end
end

-- Update the color of a prototype with a radius_visualisation_picture.
---@param _type string
---@param name string
---@param color Color
function update_radius_visualization_color(_type, name, color)
  local prototype = data:get(_type, name)
  if prototype then
    local sprite = prototype.radius_visualisation_picture
    sprite.filename = ModPath .. "/graphics/visualization-radius.png"
    sprite.tint = color
  end
end

-- Overlay all the icons on the object.
---@param obj IconObj
---@param icon data.IconData
---@param icon2? data.IconData
local function overlay_all_icons(obj, icon, icon2)
  overlay_icon(obj, icon, icon2)
  if obj.dark_background_icons or obj.dark_background_icon then
    overlay_dark_icon(obj, icon, icon2)
  end
  if obj.pictures then
    overlay_sprite_variation(obj.pictures, icon_to_sprite(icon), icon2 and icon_to_sprite(icon2))
  end
end

-- Replace the icon on a prototype if the setting is enabled.
---@param name string
---@param proto Prototype
---@param config_name string
---@param obj IconObj
---@return boolean changed if any change was made
function do_replace_icon(name, proto, config_name, obj)
  config_name = config_name or name
  local setting = config(config_name .. "-icon-replacement")
  if not setting then
    return false
  end

  local icon = create_custom_icon(config_name, proto.icon_replacement)
  replace_icon(obj, icon)
  if proto.is_entity or proto.sprite_replacement then
    local item = get_item_from_entity(obj --[[@as data.EntityPrototype]])
    if item then
      replace_icon(item, icon)
    end
  end
  return true
end

-- Replace the sprite/animation on a prototype if the setting is enabled.
---@param name string
---@param proto Prototype
---@param config_name string
---@param obj SpriteObj
---@return boolean changed if any change was made
function do_replace_sprite(name, proto, config_name, obj)
  config_name = config_name or name
  local setting = config(config_name .. "-sprite-replacement")
  if not (proto.is_entity or proto.sprite_replacement) or not setting then
    return false
  end

  replace_sprite(obj, proto.sprite_replacement)
  return true
end

-- Create the overlays for a prototype based on the setting.
---@param setting string
---@param proto Prototype
---@return data.IconData, data.IconData?
function create_overlays(setting, proto)
  local icon, icon2
  if setting == Options.text_overlay then
    icon = TextOverlays[proto.text_overlay]
    icon2 = proto.text_overlay2 and table_merge(TextOverlays[proto.text_overlay2], BaseOverlays.shifted)
  elseif proto.icon_overlay_from then
    local from_obj = data:get(proto.icon_overlay_from[1], proto.icon_overlay_from[2])
    if from_obj then
      icon, icon2 = table.unpack(
        create_overlay_from_icons(icons_from_obj(from_obj), proto.icon_overlay_from[3], proto.icon_overlay_from[4])
      )
    end
  else
    icon = Overlays[proto.icon_overlay]
    icon2 = proto.icon_overlay2 and table_merge(Overlays[proto.icon_overlay2], BaseOverlays.shifted)
  end
  return icon, icon2
end

-- Overlay the icon on a prototype if the setting is enabled.
---@param name string
---@param proto Prototype
---@param config_name string
---@param obj IconObj
---@return boolean changed if any change was made
function do_overlay_icon(name, proto, config_name, obj)
  config_name = config_name or name

  local setting = config(config_name .. "-icon-overlay") --[[@as string|false]]
  local is_entity = proto.is_entity or proto.sprite_replacement
  if not setting or setting == Options.none then
    return false
  end

  local icon, icon2 = create_overlays(setting, proto)
  overlay_all_icons(obj, icon, icon2)
  if is_entity then
    local item = get_item_from_entity(obj --[[@as data.EntityPrototype]])
    if item then
      overlay_all_icons(item, icon, icon2)
    end
  end
  return true
end

-- Overlay the sprite/animation on a prototype if the setting is enabled.
---@param name string
---@param proto Prototype
---@param config_name string
---@param obj SpriteObj
---@return boolean changed if any change was made
function do_overlay_sprite(name, proto, config_name, obj)
  config_name = config_name or name

  local setting = config(config_name .. "-sprite-overlay") --[[@as string|false]]
  local is_entity = proto.is_entity or proto.sprite_replacement
  if not is_entity or not setting or setting == Options.none then
    return false
  end

  local icon, icon2 = create_overlays(setting, proto)
  overlay_sprites(obj, icon_to_sprite(icon), icon2 and icon_to_sprite(icon2))
  return true
end

-- Do all replacements and overlays for a prototype based on the setting.
---@param name string
---@param proto Prototype
---@param config_name string
---@return boolean changed if any change was made
function do_replace_and_overlay(name, proto, config_name)
  local obj = data:get(proto.type, name)
  if not obj then
    return false
  end

  local changed = do_replace_icon(name, proto, config_name, obj)
  changed = do_replace_sprite(name, proto, config_name, obj) or changed
  changed = do_overlay_icon(name, proto, config_name, obj) or changed
  changed = do_overlay_sprite(name, proto, config_name, obj) or changed

  return changed
end

---@class (exact) Prototype
---@field type string Factorio prototype type.
---@field localised_name? data.LocalisedString Defaults to {"<is_entity and "entity" or "item">-name.<name>"}.
---@field config_from? string Config setting to check for enabling instead of own key.
---@field order? data.Order Used to sort settings.
---@field is_entity? boolean Defaults to (bool)sprite_replacement.
---@field sprite_replacement? data.FileName
---@field icon_replacement? string|boolean
---@field icon_overlay? string
---@field icon_overlay2? string
---@field icon_overlay_from? table<string, string, Offset?, double?> prototype {type, name, <shift>, <scale>} to copy icon from as an overlay.
---@field text_overlay? string
---@field text_overlay2? string
---@field nested_prototypes? table<string, string>[]: prototype {type, name}s that should be modified if the base prototype is enabled.
---@field hooks? function[]
---@field enabled? boolean

---@alias Prototypes { [string]: Prototype }

-- Apply all changes requested by the Prototypes.
-- This can handle items, fluids, entities, and signals.
---@param prototypes Prototypes
function apply_prototypes(prototypes)
  for name, proto in pairs(prototypes) do
    if do_replace_and_overlay(name, proto, proto.config_from) then
      if proto.nested_prototypes then
        for _, nested_proto in pairs(proto.nested_prototypes) do
          do_replace_and_overlay(
            nested_proto[2],
            table_merge(proto, { type = nested_proto[1] }),
            proto.config_from or name
          )
        end
      end
      if proto.hooks then
        for _, hook in pairs(proto.hooks) do
          hook(name, proto)
        end
      end
      proto.enabled = true
    end
  end
end
