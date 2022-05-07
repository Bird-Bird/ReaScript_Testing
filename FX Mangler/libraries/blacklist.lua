-- @noindex

local info = debug.getinfo(1,'S')
local path = info.source:match[[^@?(.*[\/])[^\/]-$]]

local default_blacklist = {"bypass", "solo", "+Wet", "+Delta", "record", "pause", "cancel"}
local global_blacklist_path = '/user_files/blacklist.json'
local plugin_blacklist_path = '/user_files/plugin_params/'
function get_blacklist(bl_path)
  local file_name = bl_path
  local settings = io.open(path .. file_name, 'r')
  if not settings then
      return table.shallow_copy(default_blacklist)
  else
    local st = settings:read("*all")
    st_json = json.decode(st)
    return st_json
  end
end

local default_param_json = {is_whitelist = false, list ={}}
function get_file_param_json(file_name)
  local settings = io.open(path .. plugin_blacklist_path .. file_name .. '.json', 'r')
  if not settings then
      return deepcopy(default_param_json)
  else
    local st = settings:read("*all")
    st_json = json.decode(st)
    return st_json
  end
end

function save_custom_blacklist(bl_path, data)
  local settings = io.open(path .. bl_path, 'w')
  local d = json.encode(data)
  settings:write(d)
  settings:close()
end

function save_param_json(file_name, data)
  local settings = io.open(path .. plugin_blacklist_path .. file_name .. '.json', 'w')
  local d = json.encode(data)
  settings:write(d)
  settings:close()
end

function save_blacklist(data)
  local settings = io.open(path .. global_blacklist_path, 'w')
  local d = json.encode(data)
  settings:write(d)
  settings:close()
end
blacklist = get_blacklist(global_blacklist_path)

function parameter_is_blacklisted(blacklist, name)
  local name_low = name:lower()
  for i = 1, #blacklist do
    local word = blacklist[i]
    if string.starts(word, '+') then
      if word:sub(2) == name then
        return true
      end
    else
      word = word:lower()
      if name_low:match(word) then
        return true
      end
    end
  end
  return false
end

function get_focused_fx_data(fx)
  local file_name = get_parsed_plugin_name(fx.full_name)
  local dat = get_file_param_json(file_name)
  dat.fx = fx
  return dat
end

function save_focused_fx_data(fx, data)
  local data_c = deepcopy(data)
  data_c.fx = nil
  local file_name = get_parsed_plugin_name(fx.full_name)
  save_param_json(file_name, data_c)
end