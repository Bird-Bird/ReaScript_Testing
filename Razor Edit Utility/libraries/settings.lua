-- @noindex

--USER SETTINGS
local info = debug.getinfo(1,'S')
local path = info.source:match[[^@?(.*[\/])[^\/]-$]]


function get_default_setting()
  return {
    --FOLDER
    select_children = true,
    select_children_only_if = false,
      folder_has_prefix = false,
      folder_prefix_mode = 0,  --(0 -> prefix,    1 -> suffix, 2 --> match)
      folder_prefix = "-F",
      track_is_empty    = false,   --(0 -> is empty,  1 -> has items)

    --TIME
    move_time = false,
    move_loop = false,
    move_cursor = false,
      seek_play = false,

    --SELECTION
    select_tracks = false,
      exclude_folders = false,

    select_items = false,
      add_to_selection = false,
      exclude_out_bounds = false,

    solo_tracks = false,
    actions = {}
  }
end

function get_default_settings()
  local t = {}
  for i = 1, 5 do 
    table.insert(t, get_default_setting()) 
  end
  return t
end

function validate_old_settings(all_settings)
  local action_map = get_all_actions_map()
  for i = 1, #all_settings do
    local settings = all_settings[i]
    if not settings["actions"] then
      settings.actions = {}
    else
      local actions = settings.actions
      for i = 1, #actions do
        local action = actions[i]
        if action_map[action.name] and action_map[action.name].native == false then
          local new_action = deepcopy(action_map[action.name])
          actions[i] = new_action
        end
      end
    end
  end
end

function get_settings()
  local file_name = '/user_files/presets.json'
  local settings = io.open(path .. file_name, 'r')
  if not settings then
    return get_default_settings()
  else
    local st = settings:read("*all")
    st_json = json.decode(st)
    validate_old_settings(st_json)
    return st_json
  end
end

function save_settings(data)
  local settings = io.open(path .. '/user_files/presets.json', 'w')
  local d = json.encode(data)
  settings:write(d)
  settings:close()
end

function get_main_settings()
  local file_name = '/user_files/settings.json'
  local settings = io.open(path .. file_name, 'r')
  if not settings then
    return {dock_id = -3}
  else
    local st = settings:read("*all")
    st_json = json.decode(st)
    return st_json
  end
end

function save_main_settings(data)
  local settings = io.open(path .. '/user_files/settings.json', 'w')
  local d = json.encode(data)
  settings:write(d)
  settings:close()
end

main_settings = get_main_settings()
local last_dock_id
function auto_save_dock(dock_id)
  if dock_id ~= last_dock_id and dock_id ~= 0 then
    main_settings.dock_id = dock_id
    save_main_settings(main_settings)
    last_dock_id = dock_id
  end
end