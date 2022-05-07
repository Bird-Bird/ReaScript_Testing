-- @noindex

local FLT_MIN, FLT_MAX = reaper.ImGui_NumericLimits_Float()
local window_resize_flag = reaper.ImGui_Cond_Appearing()
local show_style_editor = false

settings = get_settings()
function settings_menu()
  reaper.ImGui_SetNextWindowSize(ctx, 154, 205, window_resize_flag)
  if reaper.ImGui_BeginPopupModal(ctx, 'Settings', nil) then
    if reaper.ImGui_Button(ctx, 'Close') then
      reaper.ImGui_CloseCurrentPopup(ctx)
    end
    reaper.ImGui_EndPopup(ctx)
  end
end

function close_context(window_is_docked)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding(), 4, 5)
  if reaper.ImGui_BeginPopupContextItem(ctx) then
    if reaper.ImGui_MenuItem(ctx, 'Settings') then
      open_settings = true
    end
    if reaper.ImGui_MenuItem(ctx, window_is_docked and 'Undock' or 'Dock') then
      if window_is_docked then
        dock = 0
      else
        dock = settings.dock_id
      end
    end
    reaper.ImGui_EndPopup(ctx)
  end
  if open_settings then
    open_settings = false
    reaper.ImGui_OpenPopup(ctx, 'Settings')
  end
  reaper.ImGui_PopStyleVar(ctx)
end


if show_style_editor then 
  demo = dofile(reaper.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/ReaImGui_Demo.lua')
end

function push_themes_common()
  reaper.ImGui_PushFont(ctx, font)
  push_theme()
  if show_style_editor then         
    demo.PushStyle(ctx)
    demo.ShowDemoWindow(ctx)
  end
end

function pop_themes_common()
  if show_style_editor then
    demo.PopStyle(ctx)
  end
  pop_theme()
  reaper.ImGui_PopFont(ctx)
end

function loop()
  push_themes_common()
    
  --WINDOW
  if dock then 
    reaper.ImGui_SetNextWindowDockID(ctx, dock)
    dock = nil 
  end
  reaper.ImGui_SetNextWindowSize(ctx, 261, 534, reaper.ImGui_Cond_FirstUseEver())
  visible, open = reaper.ImGui_Begin(ctx, window_data.title, false,  reaper.ImGui_WindowFlags_NoCollapse())
  window_is_docked = reaper.ImGui_IsWindowDocked(ctx)
  local dock_id = reaper.ImGui_GetWindowDockID(ctx)
  
  reset_scroll()
  auto_save_dock(dock_id)
  if window_is_docked then top_frame() end
  custom_close_button()
  close_context(window_is_docked)
  settings_menu()

  if visible then
    window_data.frame()
    reaper.ImGui_End(ctx)
  end
  
  pop_themes_common()
  
  if open then
    reaper.defer(loop)
  else
    reaper.ImGui_DestroyContext(ctx)
  end
end