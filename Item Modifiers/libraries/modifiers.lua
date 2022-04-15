-- @noindex

--MODIFIERS
local info = debug.getinfo(1,'S')
local path = info.source:match[[^@?(.*[\/])[^\/]-$]]
local default_modifiers = {}
factory_modifiers = {}

function update_factory_modifiers(modifiers)
  factory_modifiers = {}
  for i = 1, #modifiers do
    local mod = modifiers[i]
    factory_modifiers[mod.name] = true
  end
end

local user_modifiers_path = '/user_files/user_modifiers.json'
function get_user_modifiers()
  local file_name = user_modifiers_path
  local settings = io.open(path .. file_name, 'r')
  if not settings then
    return {}
  else
    local st = settings:read("*all")
    st_json = json.decode(st)
    update_factory_modifiers(st_json)
    return st_json
  end
end

function save_user_modifiers(data)
  local settings = io.open(path .. user_modifiers_path, 'w')
  local d = json.encode(data)
  settings:write(d)
  settings:close()
end
user_modifiers = get_user_modifiers()

function get_modifiers()
  local file_name = 'modifiers.json'
  local settings = io.open(path .. file_name, 'r')
  if not settings then
    return default_modifiers
  else
    local st = settings:read("*all")
    st_json = json.decode(st)
    update_factory_modifiers(st_json)

    for i = 1, #user_modifiers do
      table.insert(st_json, user_modifiers[i])
    end

    return st_json
  end
end
modifiers = get_modifiers()

function save_modifiers(data)
  local settings = io.open(path .. 'modifiers.json', 'w')
  local d = json.encode(data)
  settings:write(d)
  settings:close()
end

function save_to_file(file_path, data)
  local settings = io.open(file_path, 'w')
  local d = json.encode(data)
  settings:write(d)
  settings:close() 
end

function save_to_user_modifiers(mod)
  table.insert(user_modifiers, mod)
  save_user_modifiers(user_modifiers)
end

function load_modifier_library()
  local r, file_name = reaper.GetUserFileNameForRead(stack_path, "Load Modifier Library", format)
  if r then
    return true, 'blah'
  else
    return false, nil
  end
end

--FAVOURITES
local favourites_file = '/user_files/favourites.json'
function get_favourites()
  local file_name = favourites_file
  local settings = io.open(path .. file_name, 'r')
  if not settings then
    return {}
  else
    local st = settings:read("*all")
    st_json = json.decode(st)
    return st_json
  end
end

function save_favourites(data)
  local settings = io.open(path .. favourites_file, 'w')
  local d = json.encode(data)
  settings:write(d)
  settings:close()
end
local favourites = get_favourites()

function add_modifier_to_favourites(mod)
  favourites[mod.name] = true
  save_favourites(favourites)
end

function remove_modifier_from_favourites(mod)
  favourites[mod.name] = nil
  save_favourites(favourites)
end

function mod_is_favourited(mod)
  return favourites[mod.name]
end




--MODS
function find_colliding_name(name)
  for i = 1, #modifiers do
    local m = modifiers[i]
    if m.name == name then
      return i
    end
  end
  return nil
end

function find_colliding_name(modifiers, name)
  for i = 1, #modifiers do
    local m = modifiers[i]
    if m.name == name then
      return i
    end
  end
  return nil
end

function get_empty_modifier()
  return {map = {}, tags = {}, name = '', lines = ''}
end

function save_modifier(data)
  local mod = deepcopy(data)
  reset_command(mod.map)
  local name_collision = find_colliding_name(mod.name)
  if name_collision then
    modifiers[name_collision] = mod
  else
    table.insert(modifiers, mod)
  end
  save_modifiers(modifiers)
end

function append_modifier(modifiers, data)
  local mod = deepcopy(data)
  reset_command(mod.map)
  local name_collision = find_colliding_name(modifiers, mod.name)
  if name_collision then
    modifiers[name_collision] = mod
  else
    table.insert(modifiers, mod)
  end
end




--TAGGING
function add_modifier_to_tag(tbl, mod, tag)
  for i = 1, #tbl do
    local t = tbl[i].tag
    local mods = tbl[i].mods
    if tag == t then
      table.insert(mods, mod)
      return
    end
  end
  table.insert(tbl, {tag = tag, mods = {mod}})
end

function sort_mods_alphabetically(tag_tbl)
  local mods = tag_tbl.mods
  table.sort(mods, function(a, b) return a.name < b.name end)
end

function chunk_modifiers_by_tag(modifiers)
  local tbl = {
    {tag = 'Favourites', mods = {}},
    {tag = 'Special', mods = {}},
    {tag = 'Basic', mods = {}},
    {tag = 'Selection', mods = {}},
    {tag = 'All', mods = {}},
  }
  for i = 1, #modifiers do 
    local m = modifiers[i]
    local is_favourited = false
    if m.tags then
      for j = 1, #m.tags do 
        local tag = m.tags[j]
        is_favourited = is_favourited or tag == 'Favourites'
        add_modifier_to_tag(tbl, m, tag)
      end
    end
    if not is_favourited and favourites[m.name] then
      table.insert(tbl[1].mods, m)
    end
    table.insert(tbl[5].mods, m)
  end
  for i = 1, #tbl do
    sort_mods_alphabetically(tbl[i])
  end
  return tbl
end

function tag_modifier(mod, tag)
  if not mod.tags then
    mod.tags = {tag}
  else
    local has_tag = false
    for i = 1, #mod.tags do
      local t = mod.tags[i]
      has_tag = has_tag or t == tag
    end
    if not has_tag then
      table.insert(mod.tags, tag)
    end
  end
  save_modifiers(modifiers)
end

function remove_tag_from_modifier(mod, tag)
  if mod.tags then
    for i = #mod.tags, 1, -1 do
      if mod.tags[i] == tag then 
        table.remove(mod.tags, i)
      end
    end
  end
  save_modifiers(modifiers)
end

function modifier_contains_tag(mod, tag)
  if mod.tags then
    for i = #mod.tags, 1, -1 do
      if mod.tags[i] == tag then 
        return true
      end
    end
  end
  return false
end