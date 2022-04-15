-- @noindex

--USER SETTINGS
local info = debug.getinfo(1,'S')
local path = info.source:match[[^@?(.*[\/])[^\/]-$]]
local default_settings = {dock_id = -3}
function get_settings()
  local file_name = '/user_files/settings.json'
  local settings = io.open(path .. file_name, 'r')
  if not settings then
    return default_settings
  else
    local st = settings:read("*all")
    st_json = json.decode(st)
    return st_json
  end
end
settings = get_settings()

function save_settings(data)
  local settings = io.open(path .. '/user_files/settings.json', 'w')
  local d = json.encode(data)
  settings:write(d)
  settings:close()
end

local last_dock_id = settings.dock_id
function auto_save_dock(dock_id)
  if dock_id ~= last_dock_id and dock_id ~= 0 then
    settings.dock_id = dock_id
    save_settings(settings)
    last_dock_id = dock_id
  end
end