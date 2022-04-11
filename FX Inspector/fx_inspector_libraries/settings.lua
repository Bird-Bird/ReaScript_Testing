-- @noindex

local info = debug.getinfo(1,'S')
local path = info.source:match[[^@?(.*[\/])[^\/]-$]]
local default_settings = {
  enable_preset_edits = false,
  hide_other_fx = false,
  show_random_button = true,
  show_parameter_capture = true,
  show_presets = true,
  show_fx_list = true,
  dock_id = -3
}
function get_settings()
    local file_name = 'settings.json'
    local settings = io.open(path .. file_name, 'r')
    if not settings then
      return table.shallow_copy(default_settings)
    else
      local st = settings:read("*all")
      st_json = json.decode(st)
      return st_json
    end
end

function save_settings(data)
  local settings = io.open(path .. 'settings.json', 'w')
  local d = json.encode(data)
  settings:write(d)
  settings:close()
end

function validate_old_settings(settings)
  local save = false
  if settings["show_fx_list"] == nil then
    settings.show_fx_list = true
    save = true
  end
  if settings["hide_other_fx"] == nil then
    settings.hide_other_fx = false
    save = true
  end
  if settings["dock_id"] == nil then
    settings.dock_id = -3
    save = true
  end
  save_settings(settings)
end

settings = get_settings()
validate_old_settings(settings)

local last_dock_id = settings.dock_id
function auto_save_dock(dock_id)
  if dock_id ~= last_dock_id and dock_id ~= 0 then
    settings.dock_id = dock_id
    save_settings(settings)
    last_dock_id = dock_id
  end
end