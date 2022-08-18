-- @noindex

function button_display(p, p_dat, pins, pins_map)
  local remove = false
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(), 0xFFFFFF56)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameBorderSize(), 1)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(), 2, 2)
  reaper.ImGui_PushFont(ctx, icon_font)
  local but_size = 18
  local ww, wh = reaper.ImGui_GetWindowContentRegionMax(ctx)
  reaper.ImGui_SameLine(ctx, ww - but_size*2)
  if reaper.ImGui_Button(ctx, "a", but_size, but_size) then
    toggle_fx_envelope_visibility(p.track, p.fx_id, p.param_id)
  end
  
  reaper.ImGui_SameLine(ctx, 0, 3)
  local param_is_pinned, hover_col, active_col = pins_map[p.param_identifier]
  if param_is_pinned then
    local active_col = reaper.ImGui_GetStyleColor(ctx, reaper.ImGui_Col_ButtonActive())
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), active_col)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), active_col)
  end
  if reaper.ImGui_Button(ctx, "d", but_size, but_size) then
    if not param_is_pinned then
      insert_parameter_to_pins(pins, pins_map, p)
    else
      remove = true
    end
  end
  if param_is_pinned then
    reaper.ImGui_PopStyleColor(ctx, 2)  
  end
  reaper.ImGui_PopFont(ctx)
  reaper.ImGui_PopStyleColor(ctx)
  reaper.ImGui_PopStyleVar(ctx, 2)
  return remove
end

local last_tweaked_gui = ""
function display_history(history, pins, pins_map)
  local ww, wh = reaper.ImGui_GetWindowContentRegionMax(ctx)
  local removal = {}
  for i = 1, #history do
    local p = history[i]
    local p_dat = get_param_data(p)

    reaper.ImGui_PushID(ctx, i)
    track_display(p_dat)
    local remove = button_display(p, p_dat, pins, pins_map)
    if remove then table.insert(removal, p) end
    
    local is_visible = reaper.TrackFX_GetOpen(p.track, p.fx_id)
    if reaper.ImGui_Selectable(ctx, p.fx_name) then
      if not is_visible then
        reaper.TrackFX_Show(p.track, p.fx_id, 3)
      else
        reaper.TrackFX_Show(p.track, p.fx_id, 2)
      end
    end
    if is_visible then
      reaper.ImGui_PushFont(ctx, icon_font_small)
      reaper.ImGui_SameLine(ctx); reaper.ImGui_Text(ctx, "c")
      reaper.ImGui_PopFont(ctx)
    end

    reaper.ImGui_Text(ctx, p.param_name .. ': ' .. p_dat.format_val)
    
    local col = imgui_palette(i/15 + 0.8, 1)
    local rv, v = custom_slider_double(ctx, "##A", p_dat.v, p.min_v, p.max_v, p.disp_col)
    if rv then
      reaper.TrackFX_SetParam(p.track, p.fx_id, p.param_id, v)
      p.undo_count = reaper.GetProjectStateChangeCount(0)
      last_tweaked_gui = p.param_identifier
    end
    if reaper.ImGui_IsItemDeactivated(ctx) then
      reaper.TrackFX_EndParamEdit(p.track, p.fx_id, p.param_id)
    end

    reaper.ImGui_PopID(ctx)
  end
  for i = 1, #removal do
    remove_parameter_from_pins(pins, pins_map, removal[i])
  end
end

local history = {}
local history_map = {}
local pins, pins_map = load_pins()

local project_state = {}
local last_proj = reaper.EnumProjects(-1)
function frame(window_is_docked)

  --Handle project tabs
  local cur_proj = reaper.EnumProjects(-1)
  if last_proj ~= cur_proj then
    project_state[last_proj] = {
      history = deepcopy(history), 
      history_map = deepcopy(history_map)}
    if project_state[cur_proj] then
      local m = project_state[cur_proj]
      history = m.history
      history_map = m.history_map
    end
    pins, pins_map = load_pins()
  end
  last_proj = cur_proj

  --Get Parameter
  local p = {}
  p.r, p.track_id, p.fx_id, p.param_id = reaper.GetLastTouchedFX()
  if p.r then 
    p.track_id = p.track_id - 1
    local rmv = try_insert_parameter(history, history_map, p, last_tweaked_gui)
    if rmv then
      last_tweaked_gui = ''
    end
  end

  validate_fx_history(history, true, history_map)
  validate_fx_history(pins)

  if reaper.ImGui_BeginTabBar(ctx, 'Tabs', reaper.ImGui_TabBarFlags_None()) then
    if reaper.ImGui_BeginTabItem(ctx, 'History') then
      display_history(history, pins, pins_map)
      reaper.ImGui_EndTabItem(ctx)
    end
    if reaper.ImGui_BeginTabItem(ctx, 'Pins') then
      display_history(pins, pins, pins_map)
      reaper.ImGui_EndTabItem(ctx)
    end
    if reaper.ImGui_BeginTabItem(ctx, 'Settings') then
      local rv, v = reaper.ImGui_SliderInt(ctx, "History Size", settings.history_size, 5, 30)
      if rv then 
        settings.history_size = v 
        save_settings(settings)
      end
      
      local rv, v = reaper.ImGui_SliderInt(ctx, "Theme", settings.selected_theme, 1, 3)
      if rv then
        settings.selected_theme = v
        save_settings(settings)
      end
      
      local rv, v = reaper.ImGui_Checkbox(ctx, "Dock", window_is_docked)
      if rv then
        if v then 
          dock_window()
        else
          undock_window()
        end
      end
      reaper.ImGui_EndTabItem(ctx)
    end
    reaper.ImGui_EndTabBar(ctx)
  end
end