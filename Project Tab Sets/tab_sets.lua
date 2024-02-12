-- @noindex

local info = debug.getinfo(1,'S')
local path = info.source:match[[^@?(.*[\/])[^\/]-$]]
local sets_path = path .. 'tab_sets/'
local set_format = '.ptabset'

function load_tab_set_data_from_file() 
  local error_message, abort = "", false
  
  ::load_error::
  if abort then
    if error_message ~= "" then
      reaper.ShowMessageBox(error_message, "Project Tab Set", 0)
    end
    return false, nil
  end
  abort = true
  
  local success, file_name = reaper.GetUserFileNameForRead(sets_path, "Load Tab Set", "*" .. set_format)
  if success == false then --no files selected, abort
    goto load_error
  end

  local set_file = io.open(file_name, 'r')
  if not set_file then --read error
    error_message = "Cannot read file. This can happen if you do not have sufficient permissions to read this file."
    goto load_error
  end

  local set_json = set_file:read("*all")
  local status, set = pcall(json.decode, set_json)
  if status == false then --broken json
    error_message = "Selected file is not a set file."
    goto load_error
  end
  set_file:close()

  if not set["tab_set_version"] then --not a set
    error_message = "Selected file is not a set file."
    goto load_error
  end

  if not set["projects"] then --corrupted preset
    error_message = "It appears that the selected set file has been corrupted. If this happened as a result of an action from the GUI, feel free to drop a bug report. \nYou shouldn't edit these files directly unless you know what you are doing."
    goto load_error
  end

  return true, set, parse_project_path_crossplatform(file_name)
end

function save_tab_set_to_file(set, target_path) 
  local error_message, abort, target_path = "", false, target_path
  
  ::save_error::
  if abort then
    if error_message ~= "" then
      reaper.ShowMessageBox(error_message, "Project Tab Set", 0)
    end
    return false
  end
  abort = true

  local new_file
  if target_path then --save directly to path
    new_file = io.open(target_path, 'w')
    
    if not new_file then
      error = "Invalid tab set file... This might happen if the tab set file was relocated manually since last launch."
      goto save_error
    end
  else --prompt for file
    local success, file_name = reaper.JS_Dialog_BrowseForSaveFile("Save open tabs as a tab set...", sets_path, '', "Project Tab Set (" .. set_format .. ")\0*" .. set_format)
    
    if success ~= 1 then --user aborted selection
      goto save_error
    end
    
    local file_name = file_name .. set_format
    new_file = io.open(file_name, 'w')
    target_path = file_name
  end

  new_file:write(json.encode(set))
  new_file:close()    
  return true, parse_project_path_crossplatform(target_path)
end
