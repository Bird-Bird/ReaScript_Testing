-- @noindex


function display_group(group, id)
  local delete = false
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding(), 8, 5)
  if reaper.ImGui_BeginChild(ctx, tostring(id), -FLT_MIN, 94, true) then
    reaper.ImGui_SetNextItemOpen(ctx, true,  reaper.ImGui_Cond_Appearing())
    
    --Title
    centered_text("Group " .. id)
    local ww = reaper.ImGui_GetWindowWidth(ctx)
    reaper.ImGui_SameLine(ctx, ww - 19)
    if reaper.ImGui_SmallButton(ctx, "x") then
      delete = true
    end

    local knob_size = 20.0
    reaper.ImGui_Separator(ctx)
    offset_cursor_y(2)
    rv,  group.val = custom_knob("Offset", knob_size, group.val, -1, 1)
    reaper.ImGui_SameLine(ctx, 0, 6)
    rv3, group.random = custom_knob("RND", knob_size, group.random, 0, 1)
    reaper.ImGui_SameLine(ctx, 0, 6)
    rv2, group.mix = custom_knob("Mix", knob_size, group.mix, 0, 1)
    rv = rv or rv2 or rv3
    
    --Plugins
    reaper.ImGui_SameLine(ctx, 0, 6)
    local pending_delete = {}
    if reaper.ImGui_BeginListBox(ctx, "##A", -FLT_MIN, -FLT_MIN) then
      for i = 1, #group do
        local g = group[i]
        reaper.ImGui_PushID(ctx, i)
        local rv, val = reaper.ImGui_Selectable(ctx, g.fx.name  .. ' - ' .. #g.params .. 'P', false)
        if rv and val then
          if get_alt() then
            table.insert(pending_delete, i)
          else
            reaper.TrackFX_Show(g.fx.track, g.fx.id, 3)
          end
        end
        reaper.ImGui_PopID(ctx)
      end
      for i = 1, #pending_delete do 
        table.remove(group, pending_delete[i]) 
      end
      if #group == 0 then delete = true end
      reaper.ImGui_EndListBox(ctx)
    end

    --Buttons
    reaper.ImGui_SameLine(ctx, 0, 6)

    reaper.ImGui_EndChild(ctx)
  end
  reaper.ImGui_PopStyleVar(ctx)
  return rv, delete
end

local app_str = str_split(reaper.GetAppVersion(), '/')[1]
if string.find(app_str, "+dev") then app_str = app_str:gsub("%+dev.+", "") end
local app_version = tonumber(app_str)
local has_realimit = false
if app_version and app_version >= 6.37 then has_realimit = true end

realimit = false
function top_display(gs, list, mangler_groups, fx_selected_map, track)
  
  --Plugin list
  if reaper.ImGui_BeginListBox(ctx, "##A", -FLT_MIN, 75) then
    for i = 1, #list do
      reaper.ImGui_PushID(ctx, i)
      local fx = list[i]
      if fx.name ~= "ReaLimit" then
        local selected_map = fx_selected_map[fx.track]
        if not fx_selected_map[fx.track] then 
          fx_selected_map[fx.track] = {}
          selected_map = fx_selected_map[fx.track]
        end
        local selected = selected_map[fx.GUID] and selected_map[fx.GUID] == true
        rv, sel = reaper.ImGui_Selectable(ctx, fx.name, selected)
        if rv then 
          selected_map[fx.GUID] = sel 
        end
      end
      reaper.ImGui_PopID(ctx)
    end
    reaper.ImGui_EndListBox(ctx)
  end
  
  --Insert group
  rv, gs.num_params = reaper.ImGui_InputInt(ctx, 'Params', gs.num_params)
  if rv then if gs.num_params < 1 then gs.num_params = 1 end end

  if reaper.ImGui_Button(ctx, "+RND") then
    local group = get_new_group(list, gs.num_params)
    table.insert(mangler_groups, group)
    --state
  end
  reaper.ImGui_SameLine(ctx)
  if reaper.ImGui_Button(ctx, "+") then
    local map = fx_selected_map[track]
    if map then
      local selected_fx = {}
      for i = 1, #list do
        local fx = list[i]
        if map[fx.GUID] then
          table.insert(selected_fx, fx)
        end
      end
      if #selected_fx > 0 then
        local group = get_new_group(selected_fx, gs.num_params, true)
        table.insert(mangler_groups, group)
      end
    end
    --state
  end
  reaper.ImGui_SameLine(ctx)
  if reaper.ImGui_Button(ctx, "Apply") then
    reset_groups(mangler_groups)
  end
  reaper.ImGui_SameLine(ctx)
  
  local clear_groups = false
  if reaper.ImGui_Button(ctx, "Clear") then
    reset_groups_to_initial_state(mangler_groups)
    clear_groups = true
  end

  reaper.ImGui_SameLine(ctx)
  if not has_realimit then
    reaper.ImGui_BeginDisabled(ctx)
  end
  rv, realimit = reaper.ImGui_Checkbox(ctx, "ReaLimit", realimit)
  if rv and realimit then
    reaper.TrackFX_AddByName(track, "ReaLimit", false, 1)
  end
  if not has_realimit then
    reaper.ImGui_EndDisabled(ctx)
  end

  return clear_groups
end



local mangler_groups_db = {}
local mangler_groups    = {}
local fx_selected_map   = {}
local gs                = {num_params = 30}
local l_track
local l_fx
local l_param
local focused_fx_data
local focused_param
local disp_circles = get_random_circles(18, 30)
function main_frame()

  --Track Selection
  local track = reaper.GetSelectedTrack(0, 0)
  if l_track and l_track ~= track then
    mangler_groups_db[l_track] = mangler_groups
    local gr = mangler_groups_db[track]
    if gr then mangler_groups = gr else mangler_groups = {} end
  end
  l_track = track


  --Focused FX
  local fx = get_focused_fx()
  if not l_fx or l_fx.name ~= fx.name and fx.valid  then
    if fx.valid then
      focused_fx_data = get_focused_fx_data(fx)
    end
  end
  if not fx.valid then focused_fx_data = nil end
  l_fx = fx


  --Last Touched Parameter
  local param, param_change = get_last_touched_parameter(), false
  if (l_param and l_param.name ~= param.name) and fx.valid then
    if fx.name == param.fx_name then
      param_change = true
    end
  end
  if not param.valid then focused_param = nil end
  l_param = param
  


  if reaper.ImGui_BeginTabBar(ctx, 'TabBar', reaper.ImGui_TabBarFlags_None()) then
    if reaper.ImGui_BeginTabItem(ctx, 'Mangler') then
      title("MANGLER", disp_circles)
            
      if track then
                
        reaper.ImGui_Separator(ctx)
        if realimit then push_realimit(track) end
        local list = get_fx_data(track)
        if #list > 0 then
          centered_text("FX List")
          local clear_groups = top_display(gs, list, mangler_groups, fx_selected_map, track)
          if clear_groups then mangler_groups = {} end
          
          --Groups
          local pending_delete = {}
          local do_groups, pop = false, true
          reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(), 0x2A2A2AF0)
          if reaper.ImGui_BeginListBox(ctx, "##Groups", -FLT_MIN, -FLT_MIN) then
            reaper.ImGui_PopStyleColor(ctx, 1)
            pop = false
            
            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(), 0xFFFFFF46)
            for i = 1, #mangler_groups do
              reaper.ImGui_PushID(ctx, i)
              local group = mangler_groups[i]
              local do_g, delete = display_group(group, i)
              if delete then table.insert(pending_delete, i) end
              do_groups = do_groups or do_g
              reaper.ImGui_PopID(ctx)
            end
            reaper.ImGui_PopStyleColor(ctx)
            reaper.ImGui_EndListBox(ctx)
          end
          if pop then reaper.ImGui_PopStyleColor(ctx, 1) end
          
    
          --Delete
          for i = 1, #pending_delete do
            table.remove(mangler_groups, pending_delete[i])
            --state
          end
    
          --Run
          validate_groups(track, mangler_groups)
          if do_groups then
            local param_map = build_parameter_map_from_groups(mangler_groups)
            do_parameter_map(param_map)
          end
        end
      else
        reaper.ImGui_Text(ctx, "No tracks selected.")
      end
      reaper.ImGui_EndTabItem(ctx)
    end
    if reaper.ImGui_BeginTabItem(ctx, 'Parameters') then
      title("FILTER", disp_circles)
      plugin_blacklist_menu(focused_fx_data, param_change, param)
      blacklist_menu()
      reaper.ImGui_EndTabItem(ctx)
    end
    --if reaper.ImGui_BeginTabItem(ctx, 'Masher') then
    --  title("MASHER", disp_circles)
    --  masher_gui()
    --  reaper.ImGui_EndTabItem(ctx)
    --end
    reaper.ImGui_EndTabBar(ctx)
  end
end