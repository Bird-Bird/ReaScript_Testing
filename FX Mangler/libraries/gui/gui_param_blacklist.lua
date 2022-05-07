-- @noindex

local armed = false
function plugin_blacklist_menu(focused_fx_data, param_update, param)
  reaper.ImGui_Separator(ctx)
  local save = false
  
  local bl_text = (focused_fx_data and focused_fx_data.is_whitelist) and "Whitelist" or "Blacklist"
  centered_text("Parameter " .. bl_text)
  if not focused_fx_data then
    reaper.ImGui_BeginDisabled(ctx)
  end

  reaper.ImGui_Separator(ctx)
  local text = focused_fx_data and focused_fx_data.fx.name or "No plugins focused."
  centered_text(text)

  if reaper.ImGui_Button(ctx, "Arm") then
    armed = not armed
  end
  if focused_fx_data then
    local w, h = reaper.ImGui_GetWindowSize( ctx )
    local text_size = reaper.ImGui_CalcTextSize(ctx, 'Is whitelist')
    reaper.ImGui_SameLine(ctx, w - 4 - text_size - 30)
    local whitelisted = focused_fx_data.is_whitelist
    rr, focused_fx_data.is_whitelist = reaper.ImGui_Checkbox(ctx, 'Is whitelist', whitelisted)
    save = true
  end

  if armed then 
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(), 0x6528288A)
    if param_update then
      if not table_has_value(focused_fx_data.list, param.name) then
        table.insert(focused_fx_data.list, param.name)
        save = true
      end
    end
  end
  if reaper.ImGui_BeginListBox(ctx, '##listbox_2', -1, 200) then
    if focused_fx_data then
      local pending_remove = {}
      for i = 1, #focused_fx_data.list do
        local l = focused_fx_data.list[i]
        reaper.ImGui_PushID(ctx, i)
        local rv, sel = reaper.ImGui_Selectable(ctx, l, false)
        if rv then
          table.insert(pending_remove, i)
        end
        reaper.ImGui_PopID(ctx)
      end
      for i = 1, #pending_remove do 
        table.remove(focused_fx_data.list, pending_remove[i])
        save = true
      end
    end
    reaper.ImGui_EndListBox(ctx)
  end
  
  if not focused_fx_data then
    reaper.ImGui_EndDisabled(ctx)
  end

  if armed then
    reaper.ImGui_PopStyleColor(ctx)
  end

  if save then
    save_focused_fx_data(focused_fx_data.fx, focused_fx_data)
  end
end

local blacklist_text = ''
function blacklist_menu()
  local save = false
  centered_text("Global Blacklist")
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_SelectableTextAlign(), 0, 0)
  
  --LIST
  local pending_removal = {}
  if reaper.ImGui_BeginListBox(ctx, '##listbox_3', -1, 100) then
    for i = 1, #blacklist do 
      local txt = blacklist[i]
      reaper.ImGui_PushID(ctx, i)
      reaper.ImGui_Selectable(ctx, txt, false)
      reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding(), 4, 5)
      if reaper.ImGui_BeginPopupContextItem(ctx) then
        if reaper.ImGui_MenuItem(ctx, 'Remove') then
          table.insert(pending_removal, i)
        end
        reaper.ImGui_EndPopup(ctx)
      end
      reaper.ImGui_PopStyleVar(ctx)
      reaper.ImGui_PopID(ctx)
    end
    reaper.ImGui_EndListBox(ctx)
  end

  --REMOVAL
  for i = #pending_removal, 1, -1 do
    table.remove(blacklist, pending_removal[i])
    save = true
  end
  
  --INPUT
  if focus then reaper.ImGui_SetKeyboardFocusHere(ctx) end
  local r, text = reaper.ImGui_InputText(ctx, '##blacklist', blacklist_text)
  if r then blacklist_text = text end
  reaper.ImGui_SameLine(ctx)
  if reaper.ImGui_Button(ctx, 'Add') and blacklist_text ~= "" then
    table.insert(blacklist, blacklist_text)
    save = true
    blacklist_text = ''
  end
  if save then
    save_blacklist(blacklist)
  end
  reaper.ImGui_PopStyleVar(ctx)
end