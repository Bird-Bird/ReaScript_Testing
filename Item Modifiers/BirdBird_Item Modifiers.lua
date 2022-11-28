-- @description Item Modifiers
-- @version 0.4.4
-- @author BirdBird
-- @provides
--    [nomain]libraries/functions.lua
--    [nomain]libraries/json.lua
--    [nomain]libraries/modifiers.json
--    [nomain]libraries/settings.lua
--    [nomain]libraries/builder_parser.lua
--    [nomain]libraries/command_table.lua
--    [nomain]libraries/modifiers.lua
--    [nomain]libraries/modifier_stacks.lua
--    [nomain]libraries/gui/gui_main.lua
--    [nomain]libraries/gui/gui.lua
--    [nomain]libraries/gui/gui_common.lua
--    [nomain]libraries/gui/gui_builder.lua
--    [nomain]libraries/drawing/drawlist_API.lua
--    [nomain]libraries/drawing/waveform_peaks.lua
--    [nomain]libraries/user_files/generated_scripts/example.lua
--    [nomain]libraries/user_files/modifier_stacks/Beat Chopper Stutter.modstk
--    [main]BirdBird_Item Modifier Builder.lua
--    [nomain]libraries/functional_console/base.lua
--    [nomain]libraries/functional_console/basic_commands.lua
--    [nomain]libraries/functional_console/functions.lua
--    [nomain]libraries/functional_console/item_data.lua
--    [nomain]libraries/functional_console/macro_library.lua
--    [nomain]libraries/functional_console/random.lua
--    [nomain]libraries/functional_console/state.lua
--    [nomain]libraries/functional_console/validation.lua
--    [nomain]libraries/functional_console/user_files/user_files.txt
-- @changelog
--  + Prepare for ReaImGui updates

--LOAD FILES
window_data = {}
window_data.ctx = 'Item Modifiers'
window_data.style = 'main'
window_data.title = 'Item Modifiers'
function p(msg) reaper.ShowConsoleMsg(tostring(msg)..'\n')end
dofile(reaper.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/imgui.lua')('0.6')
function debug_print(msg) if settings.debug_mode then reaper.ShowConsoleMsg(tostring(msg)..'\n') end end
function reaper_do_file(file) local info = debug.getinfo(1,'S'); local path = info.source:match[[^@?(.*[\/])[^\/]-$]]; dofile(path .. file); end

reaper_do_file('libraries/functions.lua')
reaper_do_file('libraries/json.lua')
reaper_do_file('libraries/settings.lua')
reaper_do_file('libraries/builder_parser.lua')
reaper_do_file('libraries/command_table.lua')
reaper_do_file('libraries/modifiers.lua')
reaper_do_file('libraries/modifier_stacks.lua')
reaper_do_file('libraries/drawing/drawlist_API.lua')
reaper_do_file('libraries/drawing/waveform_peaks.lua')


reaper_do_file('libraries/gui/gui_main.lua')
reaper_do_file('libraries/gui/gui.lua')
window_data.frame = item_modifiers_frame


reaper_do_file('libraries/gui/gui_common.lua')
reaper_do_file('libraries/functional_console/base.lua')
loop()