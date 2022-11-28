-- @description FX Mangler
-- @version 0.1.9
-- @author BirdBird
-- @provides
--    [nomain]libraries/blacklist.lua
--    [nomain]libraries/functions.lua
--    [nomain]libraries/fx.lua
--    [nomain]libraries/groups.lua
--    [nomain]libraries/json.lua
--    [nomain]libraries/settings.lua
--    [nomain]libraries/user_files/plugin_params/plugin_params.txt
--    [nomain]libraries/gui/gui_common.lua
--    [nomain]libraries/gui/gui_main.lua
--    [nomain]libraries/gui/gui_param_blacklist.lua
--    [nomain]libraries/gui/gui.lua
-- @changelog
--  + Prepare for ReaImGui updates

--LOAD FILES
script_version = 0.13
window_data = {}
window_data.ctx = 'FX Mangler'
window_data.style = 'main'
window_data.title = 'FX Mangler'
function p(msg) reaper.ShowConsoleMsg(tostring(msg)..'\n')end
function debug_print(msg) if settings.debug_mode then reaper.ShowConsoleMsg(tostring(msg)..'\n') end end
dofile(reaper.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/imgui.lua')('0.6')
function reaper_do_file(file) local info = debug.getinfo(1,'S'); local path = info.source:match[[^@?(.*[\/])[^\/]-$]]; dofile(path .. file); end

reaper_do_file('libraries/functions.lua')
reaper_do_file('libraries/json.lua')
reaper_do_file('libraries/settings.lua')
reaper_do_file('libraries/fx.lua')
reaper_do_file('libraries/groups.lua')
reaper_do_file('libraries/blacklist.lua')

reaper_do_file('libraries/gui/gui.lua')
reaper_do_file('libraries/gui/gui_main.lua')
window_data.frame = main_frame

reaper_do_file('libraries/gui/gui_common.lua')
reaper_do_file('libraries/gui/gui_param_blacklist.lua')
loop()