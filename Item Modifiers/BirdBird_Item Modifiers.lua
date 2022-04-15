-- @description Item Modifiers
-- @version 0.4.1
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
--    [nomain]libraries/user_files/generated_scripts/example.lua
--    [nomain]libraries/user_files/modifier_stacks/Beat Chopper Stutter.modstk
--    [main]BirdBird_Item Modifier Builder.lua


--CONSOLE
local console_path = reaper.GetResourcePath() .. '/Scripts/BirdBird ReaScript Testing/Functional Console/functional_console_libraries/base.lua'
if not reaper.file_exists(console_path) then
  reaper.ShowMessageBox('Unable to find Functional Console. Make sure it is installed through ReaPack.', 'Error - Missing File', 0)
  return
end
dofile(console_path)
if not console_is_item_modifiers_compatible then
  reaper.ShowMessageBox('Item Modifiers requires the latest version of Functional Console to run. You can update it through ReaPack', 'Error - Old Version', 0)
  return
end


--LOAD FILES
function p(msg) reaper.ShowConsoleMsg(tostring(msg)..'\n')end
function debug_print(msg) if settings.debug_mode then reaper.ShowConsoleMsg(tostring(msg)..'\n') end end
function reaper_do_file(file) local info = debug.getinfo(1,'S'); local path = info.source:match[[^@?(.*[\/])[^\/]-$]]; dofile(path .. file); end
window_data = {}


reaper_do_file('libraries/functions.lua')
reaper_do_file('libraries/json.lua')
reaper_do_file('libraries/settings.lua')
reaper_do_file('libraries/builder_parser.lua')
reaper_do_file('libraries/command_table.lua')
reaper_do_file('libraries/modifiers.lua')
reaper_do_file('libraries/modifier_stacks.lua')


window_data.ctx = 'Item Modifiers'
reaper_do_file('libraries/gui/gui_main.lua')
reaper_do_file('libraries/gui/gui.lua')
window_data.frame = item_modifiers_frame
window_data.style = 'main'
window_data.title = 'Item Modifiers'

reaper_do_file('libraries/gui/gui_common.lua')