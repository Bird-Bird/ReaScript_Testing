-- @noindex
local FLT_MIN, FLT_MAX = reaper.ImGui_NumericLimits_Float()
local settings = get_settings()
function disable(cond)
  if cond then
    reaper.ImGui_BeginDisabled(ctx)
  end
end
function end_disable(cond)
  if cond then
    reaper.ImGui_EndDisabled(ctx)
  end
end

function actions(settings)
  local save = false
  if reaper.ImGui_BeginListBox(ctx, '##AA', -FLT_MIN, 100) then
    local removal, swap = {}, {}
    for i = 1, #settings.actions do
      local action = settings.actions[i]
      reaper.ImGui_PushID(ctx, i)
      if reaper.ImGui_Selectable(ctx, action.name, false) then
        table.insert(removal, i)
      end
      
      --DRAG/DROP
      if reaper.ImGui_BeginDragDropSource(ctx,  
      reaper.ImGui_DragDropFlags_AcceptBeforeDelivery() |  
      reaper.ImGui_DragDropFlags_AcceptNoDrawDefaultRect() | 
      reaper.ImGui_DragDropFlags_SourceNoPreviewTooltip()) then
        reaper.ImGui_SetDragDropPayload(ctx, 'ACTION_SWAP', i)
        reaper.ImGui_EndDragDropSource(ctx)
      end
      if reaper.ImGui_BeginDragDropTarget(ctx) then
        local _, _, pa = reaper.ImGui_GetDragDropPayload( ctx )
        local sp_offs = -17
        if tonumber(pa) < i then
          sp_offs = -2
        end
        custom_separator(sp_offs)
        local r, payload = reaper.ImGui_AcceptDragDropPayload(ctx, 'ACTION_SWAP')
        if r then
          local payload = tonumber(payload)
          table.insert(swap, {s = payload, e = i})
        end
        reaper.ImGui_EndDragDropTarget(ctx)
      end
      reaper.ImGui_PopID(ctx)
    end
    for i = 1, #removal do
      table.remove(settings.actions, removal[i])
      save = true
    end
    for i = 1, #swap do
      local s = swap[i]
      local action = settings.actions[s.s]
      local offset = s.e < s.s and 1 or 0
      table.insert(settings.actions, s.e + 1 - offset, action)
      table.remove(settings.actions, s.s + offset)
      save = true
    end
    reaper.ImGui_EndListBox(ctx)
  end
  reaper.ImGui_Text(ctx, "From:")
  local rv, action = action_listbox(ctx, 100)
  if rv then table.insert(settings.actions, action); save = true end
  return save
end

local indent = 8
function settings_gui(settings, all_settings, selected_preset)
  if not settings then
    gm_write_selected_preset(1)
    return false
  end
  local rv, save = false, false

  reaper.ImGui_Text(ctx, "After Razor Edits:")

  local ww, wh = reaper.ImGui_GetWindowContentRegionMax(ctx)
  local but_size = 16
  local b_offs = but_size*2 + 2
  reaper.ImGui_SameLine(ctx, ww - b_offs)
  if reaper.ImGui_Button(ctx, "-", but_size, but_size) then
    local message = "This will remove the selected preset. This action can't be undone.\n\nWould you like to proceed?"
    local result = reaper.ShowMessageBox(message, "Razor Edit Utility - Warning", 4)
    if result == 6 then
      if #all_settings > 1 then 
        local num_presets = #all_settings
        table.remove(all_settings, selected_preset)
        if selected_preset > #all_settings then
          gm_write_selected_preset(#all_settings)
        end
        save = true
      end
    end
  end
  reaper.ImGui_SameLine(ctx, ww - b_offs + 18)
  if reaper.ImGui_Button(ctx, "+", but_size, but_size) then
    table.insert(all_settings, get_default_setting())
    save = true
  end

  reaper.ImGui_Separator(ctx)

  --SELECT CHILD TRACKS
  centered_text("Folders")
  rv, settings.select_children = reaper.ImGui_Checkbox(ctx, "Select child tracks", settings.select_children)
  if rv then save = true end

  --If
  disable(not settings.select_children)
  reaper.ImGui_Indent(ctx, indent)
    rv, settings.folder_has_prefix = reaper.ImGui_Checkbox(ctx, "If folder contains", settings.folder_has_prefix)
    if rv then save = true end
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_SetNextItemWidth(ctx, 70)
    rv, settings.folder_prefix_mode = reaper.ImGui_Combo(ctx, "##E", settings.folder_prefix_mode, "Prefix\31Suffix\31Word\31")
    if rv then save = true end

    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_SetNextItemWidth(ctx, 40)
    rv, settings.folder_prefix = reaper.ImGui_InputText(ctx, "##I", settings.folder_prefix)
    if rv then save = true end

    rv, settings.track_is_empty = reaper.ImGui_Checkbox(ctx, "If folder is empty", settings.track_is_empty)
    if rv then save = true end
  reaper.ImGui_Unindent(ctx, indent)
  end_disable(not settings.select_children)
  reaper.ImGui_Separator(ctx)

  --TIME SELECTION
  centered_text("Time Selection")
  reaper.ImGui_Text(ctx, "Move:")
  reaper.ImGui_Indent(ctx, indent)
    rv, settings.move_time = reaper.ImGui_Checkbox(ctx, "Time Selection", settings.move_time)
    if rv then save = true end
    rv, settings.move_loop = reaper.ImGui_Checkbox(ctx, "Loop Range", settings.move_loop)
    if rv then save = true end
    rv, settings.move_cursor = reaper.ImGui_Checkbox(ctx, "Edit Cursor", settings.move_cursor)
    if rv then save = true end
    reaper.ImGui_Indent(ctx, indent)
      disable(not settings.move_cursor)  
      rv, settings.seek_play = reaper.ImGui_Checkbox(ctx, "Seek Play", settings.seek_play)
      if rv then save = true end
      end_disable(not settings.move_cursor)
    reaper.ImGui_Unindent(ctx, indent)
  reaper.ImGui_Unindent(ctx, indent)
  reaper.ImGui_Separator(ctx)

  --SELECTION
  centered_text("Selection")
  reaper.ImGui_Text(ctx, "Select:")
  reaper.ImGui_Indent(ctx, indent)
    
    --Tracks
    rv, settings.select_tracks = reaper.ImGui_Checkbox(ctx, "Tracks", settings.select_tracks)
    if rv then save = true end
    reaper.ImGui_Indent(ctx, indent)
      disable(not settings.select_tracks)
      rv, settings.exclude_folders = reaper.ImGui_Checkbox(ctx, "Exclude folders", settings.exclude_folders)
      if rv then save = true end
      end_disable(not settings.select_tracks)
      rv, settings.solo_tracks = reaper.ImGui_Checkbox(ctx, "Solo tracks", settings.solo_tracks)
      if rv then save = true end
    reaper.ImGui_Unindent(ctx, indent)
    
    --Items
    rv, settings.select_items = reaper.ImGui_Checkbox(ctx, "Items", settings.select_items)
    if rv then save = true end
    reaper.ImGui_Indent(ctx, indent)
      disable(not settings.select_items)
      --rv, settings.add_to_selection = reaper.ImGui_Checkbox(ctx, "Add to selection", settings.add_to_selection)
      --if rv then save = true end
      rv, settings.exclude_out_bounds = reaper.ImGui_Checkbox(ctx, "Only include fully contained items", settings.exclude_out_bounds)
      if rv then save = true end
      end_disable(not settings.select_items)
    reaper.ImGui_Unindent(ctx, indent)
  reaper.ImGui_Unindent(ctx, indent)
  reaper.ImGui_Separator(ctx)

  --Actions
  centered_text("Actions")
  reaper.ImGui_Text(ctx, "Run:")
  local rv = actions(settings)
  if rv then save = true end

  return save
end

function frame()
  local preset_id = gmem_get_selected_preset()
  local num_buttons = gm_get_num_buttons()
  local save_1, save_2 = toolbar_frame(preset_id, false, false, num_buttons)
  if reaper.ImGui_BeginChild(ctx, "##st", -FLT_MIN, -FLT_MIN, false) then
    save_2 = settings_gui(settings[preset_id], settings, preset_id)
    reaper.ImGui_EndChild(ctx)
  end
  if save_1 or save_2 then
    save_settings(settings)
    gm_reload_settings()
  end
end