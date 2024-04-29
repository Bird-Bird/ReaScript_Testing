-- @description Razor Edit Utility
-- @version 0.7.4
-- @author BirdBird
-- @provides
--  [main]BirdBird_Razor Edit Utility Toolbar.lua
--  [main]BirdBird_Razor Edit Utility - Comp to selected track.lua
--  [main]BirdBird_Razor Edit Utility - Comp to nearest comp track (above).lua
--  [main]BirdBird_Razor Edit Utility.lua
--  [main]BirdBird_Razor Edit Utility - Select Preset 1.lua
--  [main]BirdBird_Razor Edit Utility - Select Preset 2.lua
--  [main]BirdBird_Razor Edit Utility - Select Preset 3.lua
--  [main]BirdBird_Razor Edit Utility - Select Preset 4.lua
--  [main]BirdBird_Razor Edit Utility - Select Preset 5.lua
--  [main]BirdBird_Razor Edit Utility - Move razor edits down by one track.lua
--  [main]BirdBird_Razor Edit Utility - Move razor edits up by one track.lua
--  [nomain]libraries/functions.lua
--  [nomain]libraries/gmem.lua
--  [nomain]libraries/gui_main.lua
--  [nomain]libraries/gui_toolbar.lua
--  [nomain]libraries/actions_list.lua
--  [nomain]libraries/comping.lua
--  [nomain]libraries/gui.lua
--  [nomain]libraries/items.lua
--  [nomain]libraries/json.lua
--  [nomain]libraries/razor.lua
--  [nomain]libraries/settings.lua
--  [nomain]libraries/user_files/user_files.txt
--@changelog
-- Fixed crash on launch.


function p(msg) reaper.ShowConsoleMsg(tostring(msg) .. '\n') end
dofile(reaper.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/imgui.lua')('0.6')
function reaper_do_file(file) local info = debug.getinfo(1,'S'); path = info.source:match[[^@?(.*[\/])[^\/]-$]]; dofile(path .. file); end
reaper_do_file('libraries/functions.lua')
if not reaper.APIExists('ImGui_GetVersion') then
  local text = 'Razor Edit Utiliy requires the ReaImGui extension to run. You can install it through ReaPack.'
  local ret = reaper.ShowMessageBox(text, 'Error - Missing Dependency', 0)
  return
end
reaper_do_file('libraries/json.lua')
reaper_do_file('libraries/settings.lua')
reaper_do_file('libraries/razor.lua')
reaper_do_file('libraries/actions_list.lua')

ctx = reaper.ImGui_CreateContext('Razor Edit Utiliy')
flt_min, flt_max   = reaper.ImGui_NumericLimits_Float()
local font         = reaper.ImGui_CreateFont('sans-serif', 12)
reaper.ImGui_AttachFont(ctx, font)

reaper_do_file('libraries/gui.lua')
reaper_do_file('libraries/gui_main.lua')
reaper_do_file('libraries/gui_toolbar.lua')
reaper_do_file('libraries/gmem.lua')

local show_style_editor = false
if show_style_editor then 
  demo = dofile(reaper.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/ReaImGui_Demo.lua')
end

function loop()
  reaper.ImGui_PushFont(ctx, font)
  push_theme()
  if show_style_editor then         
    demo.PushStyle(ctx)
    demo.ShowDemoWindow(ctx)
  end
  reaper.ImGui_SetNextWindowSize(ctx, 239, 589, reaper.ImGui_Cond_FirstUseEver())
  local visible, open = reaper.ImGui_Begin(ctx, 'Razor Edit Utility', true)
  if visible then
    frame()
    reaper.ImGui_End(ctx)
  end
  if show_style_editor then
    demo.PopStyle(ctx)
  end
  pop_theme()
  reaper.ImGui_PopFont(ctx)
  
  if open then
    reaper.defer(loop)
  else
    reaper.ImGui_DestroyContext(ctx)
  end
end
loop()