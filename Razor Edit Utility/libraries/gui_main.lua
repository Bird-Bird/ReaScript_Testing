-- @noindex
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

local indent = 8
function settings_gui(settings)
  local rv, save = false, false

  reaper.ImGui_Text(ctx, "After Razor Edits:")
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

  return save
end

function frame()
  local preset_id = gmem_get_selected_preset()
  local save_1 = toolbar_frame(preset_id)
  local save_2 = settings_gui(settings[preset_id])
  if save_1 or save_2 then
    save_settings(settings)
    gm_reload_settings()
  end
end