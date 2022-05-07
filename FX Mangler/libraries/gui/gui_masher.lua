-- @noindex

local masher_filter = ""
function masher_gui()
  local rv, save_masher = false, false
  centered_text("All Plugins")
  rv, masher_filter = reaper.ImGui_InputText(ctx, "Filter", masher_filter)
  local filter = reaper.ImGui_CreateTextFilter(masher_filter)
  if reaper.ImGui_BeginListBox(ctx, '##listbox_4', -FLT_MIN, 100) then
    for i = 1, #fx_list do
      reaper.ImGui_PushID(ctx, i)
      local name = fx_list[i]
      if reaper.ImGui_TextFilter_PassFilter(filter, name) then
        if reaper.ImGui_Selectable(ctx, name, false) then
          if not table_has_value(masher_list, name) then
            table.insert(masher_list, name)
            save_masher = true
          end
        end
      end
      reaper.ImGui_PopID(ctx)
    end
    reaper.ImGui_EndListBox(ctx)
  end

  centered_text("Masher List")
  if reaper.ImGui_BeginListBox(ctx, '##listbox_5', -FLT_MIN, 100) then
    local pending_delete = {}
    for i = 1, #masher_list do
      reaper.ImGui_PushID(ctx, i)
      local name = masher_list[i]
      if reaper.ImGui_Selectable(ctx, name, false) then
        table.insert(pending_delete, i)
      end      
      reaper.ImGui_PopID(ctx)
    end
    for i = 1, #pending_delete do 
      table.remove(masher_list, pending_delete[i]) 
    end
    reaper.ImGui_EndListBox(ctx)
  end

  if save_masher then
    save_masher_list(masher_list)
  end

  local track = reaper.GetSelectedTrack(0, 0)
  if track then
    if reaper.ImGui_Button(ctx, "Add") then
      for i = 1, #masher_list do
        local plugin = masher_list[i]
        reaper.TrackFX_AddByName(track, plugin, false, -1)
      end
    end
  end
end