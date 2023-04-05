-- @noindex

--USER SETTINGS
local info = debug.getinfo(1,'S')
local path = info.source:match[[^@?(.*[\/])[^\/]-$]]
local default_settings = {
  dock_id = -3, 
  selected_theme = 1, 
  history_size = 10,
  show_extra_buttons = true,
  filter_pins_by_selected_track = false,
  filter_history_by_selected_track = false,
  slider_height = 20
}
function save_settings(data)
  local settings = io.open(path .. '/user_files/settings.json', 'w')
  local d = json.encode(data)
  settings:write(d)
  settings:close()
end
function get_settings()
  local file_name = '/user_files/settings.json'
  local settings = io.open(path .. file_name, 'r')
  if not settings then
    return default_settings
  else
    local st = settings:read("*all")
    st_json = json.decode(st)
    local mod = false
    for k, v in pairs(default_settings) do
      if default_settings[k] ~= nil and st_json[k] == nil then
        st_json[k] = default_settings[k]
        mod = true
      end
    end
    if mod then save_settings(st_json) end
    return st_json
  end
end
settings = get_settings()

