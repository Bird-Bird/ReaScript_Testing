-- @noindex

function p(msg) reaper.ShowConsoleMsg(tostring(msg)..'\n')end
function debug_print(msg) if settings.debug_mode then reaper.ShowConsoleMsg(tostring(msg)..'\n') end end
dofile(reaper.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/imgui.lua')('0.6')
function reaper_do_file(file) local info = debug.getinfo(1,'S'); local path = info.source:match[[^@?(.*[\/])[^\/]-$]]; dofile(path .. file); end
reaper_do_file('libraries/json.lua')


--LIBRARY FILE
window_data = {}
window_data.ctx = 'Item Modifiers Builder'
window_data.style = 'builder'
window_data.title = 'Item Modifier Builder'
local info = debug.getinfo(1,'S')
local path = info.source:match[[^@?(.*[\/])[^\/]-$]] .. '/libraries/user_files/'

local user_mod_path = path .. 'user_modifiers.json'
local user_mods = io.open(user_mod_path, 'r')
if not user_mods then 
  local u_mods = io.open(user_mod_path, 'w');
  u_mods:write("{}"); u_mods:close()
end

local r, file_name = reaper.GetUserFileNameForRead(path, "Load Modifier Library", '.json')
if r then
  if file_name:match("modifiers.json") or file_name:match("user_modifiers.json") then
    local mods = io.open(file_name, 'r')
    if mods then
      local library = mods:read("*all")
      local mods_json = json.decode(library)
      window_data.builder_data = {path = file_name, mods = mods_json}
    else
      reaper.ShowMessageBox('Cannot load library file.', 'Error - Library cannot be loaded.',  0)
      return
    end
  else
    reaper.ShowMessageBox('Invalid library file selected.', 'Error - Library file not found.',  0)
    return
  end
else
  reaper.ShowMessageBox('You need to select a library file to run the modifier builder.', 'Error - Library file not found',  0)
  return
end


--LOAD FILES
reaper_do_file('libraries/functions.lua')
reaper_do_file('libraries/json.lua')
reaper_do_file('libraries/settings.lua')
reaper_do_file('libraries/builder_parser.lua')
reaper_do_file('libraries/command_table.lua')
reaper_do_file('libraries/modifiers.lua')

reaper_do_file('libraries/gui/gui_builder.lua')
reaper_do_file('libraries/gui/gui.lua')
window_data.frame = builder_frame

reaper_do_file('libraries/gui/gui_common.lua')
reaper_do_file('libraries/functional_console/base.lua')
loop()