-- @noindex

local info = debug.getinfo(1,'S')
local data_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
local data_file_name = "_settings.json"
local data_file_path = data_path .. "/" .. data_file_name


function parse_project_path_crossplatform(path)
  return path:gsub("\\", "/")
end

function get_default_settings()
  return {
    version         = version,
    project_root    = "",
    most_recent_tab = ""
  }
end

function save_settings(settings_data)
  local settings_file = io.open(data_file_path, 'w')
  local settings_json = json.encode(settings_data)
  settings_file:write(settings_json)
  settings_file:close()
end

function get_settings()
  local settings_file = io.open(data_file_path, 'r')
  if not settings_file then
    return get_default_settings()
  else
    local settings_json = settings_file:read("*all")
    settings_file:close()
    local settings_data = json.decode(settings_json)
    return settings_data
  end
end
global_settings = get_settings()

function save_as_most_recent_tab_set(tab_set_path)
  global_settings.most_recent_tab = tab_set_path
  save_settings(global_settings)
end

function get_most_recent_tab_set()
  return global_settings.most_recent_tab ~= "", global_settings.most_recent_tab
end

function clear_most_recent_tab_set()
  global_settings.most_recent_tab = ""
  save_settings(global_settings)
end

function browse_for_project_root()
  local success, folder_path = reaper.JS_Dialog_BrowseForFolder("Select project root folder...", "")
  if success == 1 then
    global_settings.project_root = parse_project_path_crossplatform(folder_path)
    save_settings(global_settings)
    return true
  else
    return false
  end
end

function clear_project_root()
  global_settings.project_root = ""
  save_settings(global_settings)
end

function browse_for_sws_project_list_load()
  local success, file_name = reaper.GetUserFileNameForRead("", "Load Tab Set", '.rpl')
  if success == false then
    return false, nil
  end
  
  local list_file = io.open(file_name, 'r')
  if not list_file then
    return false, nil
  end
  
  local lines = {}
  for line in list_file:lines() do
    table.insert(lines, line)
  end
  list_file:close()
  return true, lines
end

function browse_for_sws_project_list_save()
  local success, file_name = reaper.JS_Dialog_BrowseForSaveFile("Save open tabs as SWS project list...", "", '', "REAPER Project List (.rpl)\0*.rpl")
  if success ~= 1 then
    return false
  end

  local project_names = {}
  for _, name in enum_projects() do
    if name ~= "" then
      table.insert(project_names, name)
    end
  end
  local list_string = table.concat(project_names, "\n")
  local list_file = io.open(file_name .. ".rpl", 'w')
  list_file:write(list_string)
  list_file:close()

  return true
end