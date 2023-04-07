-- @description Parameter History
-- @version 0.4.92
-- @author BirdBird
-- @provides
--    [nomain]libraries/functions.lua
--    [nomain]libraries/fx.lua
--    [nomain]libraries/gui_main.lua
--    [nomain]libraries/gui.lua
--    [nomain]libraries/json.lua
--    [nomain]libraries/parameters.lua
--    [nomain]libraries/pins.lua
--    [nomain]libraries/settings.lua
--    [nomain]libraries/user_files/user_files.txt
--    [nomain]libraries/resources/Icons.ttf
--@changelog
--  + Fix parameters not showing up after removing them from history


function pr(msg) reaper.ShowConsoleMsg(tostring(msg) .. '\n') end
function reaper_do_file(file) local info = debug.getinfo(1,'S'); path = info.source:match[[^@?(.*[\/])[^\/]-$]]; dofile(path .. file); end
function reaper_get_path(relative_path) local info = debug.getinfo(1,'S'); path = info.source:match[[^@?(.*[\/])[^\/]-$]]; return path .. relative_path end
reaper_do_file('libraries/functions.lua')
if not reaper.APIExists('CF_GetSWSVersion') then
  local text = 'Parameter History requires the SWS Extension to run, however it is unable to find it. \nWould you like to be redirected to the SWS Extension website to install it?'
  local ret = reaper.ShowMessageBox(text, 'Error - Missing Dependency', 4)
  if ret == 6 then
    open_url('https://www.sws-extension.org/')
  end
  return
end
if not reaper.APIExists('ImGui_GetVersion') then
  local text = 'Parameter History requires the ReaImGui extension to run. You can install it through ReaPack.'
  local ret = reaper.ShowMessageBox(text, 'Error - Missing Dependency', 0)
  return
end
dofile(reaper.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/imgui.lua')('0.6')
reaper_do_file('libraries/functions.lua')
reaper_do_file('libraries/json.lua')
reaper_do_file('libraries/pins.lua')
reaper_do_file('libraries/gui.lua')
reaper_do_file('libraries/gui_main.lua')
reaper_do_file('libraries/fx.lua')
reaper_do_file('libraries/parameters.lua')
reaper_do_file('libraries/settings.lua')

ctx = reaper.ImGui_CreateContext('Parameter History', reaper.ImGui_ConfigFlags_DockingEnable())
icon_font = reaper.ImGui_CreateFont(reaper_get_path('libraries/resources/Icons.ttf'), 15)
icon_font_small = reaper.ImGui_CreateFont(reaper_get_path('libraries/resources/Icons.ttf'), 12)
reaper.ImGui_AttachFont(ctx, icon_font)
reaper.ImGui_AttachFont(ctx, icon_font_small)
flt_min, flt_max = reaper.ImGui_NumericLimits_Float()
local font = reaper.ImGui_CreateFont('sans-serif', 12)
reaper.ImGui_AttachFont(ctx, font)

local show_style_editor = false
if show_style_editor then 
  demo = dofile(reaper.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/ReaImGui_Demo.lua')
end

function dock_window()
  dock = settings.dock_id
end

function undock_window()
  local dock_id = reaper.ImGui_GetWindowDockID(ctx)
  settings.dock_id = dock_id
  save_settings(settings)
  dock = 0
end

function loop()
  reaper.ImGui_PushFont(ctx, font)
  push_theme(settings)
  if show_style_editor then         
    demo.PushStyle(ctx)
    demo.ShowDemoWindow(ctx)
  end
  
  if dock then reaper.ImGui_SetNextWindowDockID(ctx, dock); dock = nil end
  reaper.ImGui_SetNextWindowSize(ctx, 164, 217, reaper.ImGui_Cond_FirstUseEver())
  local visible, open = reaper.ImGui_Begin(ctx, 'Parameter History', true)
  local window_is_docked = reaper.ImGui_IsWindowDocked(ctx)
  if visible then
    frame(window_is_docked)
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