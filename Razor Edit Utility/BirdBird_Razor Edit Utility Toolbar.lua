-- @noindex

function p(msg) reaper.ShowConsoleMsg(tostring(msg) .. '\n') end
dofile(reaper.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/imgui.lua')('0.6')
function reaper_do_file(file) local info = debug.getinfo(1,'S'); path = info.source:match[[^@?(.*[\/])[^\/]-$]]; dofile(path .. file); end

reaper_do_file('libraries/functions.lua')

ctx = reaper.ImGui_CreateContext('Razor Edit Utiliy Toolbar',  reaper.ImGui_ConfigFlags_DockingEnable())
flt_min, flt_max   = reaper.ImGui_NumericLimits_Float()
local font         = reaper.ImGui_CreateFont('sans-serif', 12)
reaper.ImGui_AttachFont(ctx, font)

reaper_do_file('libraries/json.lua')
reaper_do_file('libraries/gui.lua')
reaper_do_file('libraries/gui_toolbar.lua')
reaper_do_file('libraries/gmem.lua')
reaper_do_file('libraries/settings.lua')

function loop()
  reaper.ImGui_PushFont(ctx, font)
  push_theme()
  reaper.ImGui_SetNextWindowSize(ctx, 240, 63, reaper.ImGui_Cond_FirstUseEver())
  
  if dock then 
    reaper.ImGui_SetNextWindowDockID(ctx, dock)
    dock = nil 
  end
  local visible, open = reaper.ImGui_Begin(ctx, 'Toolbar', true,  reaper.ImGui_WindowFlags_NoScrollbar())
  window_is_docked = reaper.ImGui_IsWindowDocked(ctx)
  local dock_id = reaper.ImGui_GetWindowDockID(ctx)
  auto_save_dock(dock_id)
  if reaper.ImGui_IsKeyPressed(ctx,  reaper.ImGui_Key_D()) then
    if window_is_docked then
      dock = 0
    else
      dock = main_settings.dock_id
    end
  end
  
  if visible then
    local sel_preset_id = gmem_get_selected_preset()
    local num_buttons = gm_get_num_buttons()
    local reload = toolbar_frame(sel_preset_id, true, window_is_docked, num_buttons)
    if reload then
      gm_update_selected_only()
    end

    reaper.ImGui_End(ctx)
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