-- @noindex
local modifier_filter = ''
local modifier_stack = {}
local focus_filter = true
local auto_focus_filter = false
local exec = false
local load_stack = false
local has_js_API = reaper.APIExists('JS_ReaScriptAPI_Version')

function filter_auto_focus()
  if auto_focus_filter then
    focus_filter = true
  end
end

function mod_context(mod)
  if reaper.ImGui_BeginPopupContextItem(ctx) then
    local is_tagged = mod_is_favourited(mod)
    if not is_tagged then
      if reaper.ImGui_MenuItem(ctx, 'Favourite') then
        add_modifier_to_favourites(mod)
      end
    else
      if reaper.ImGui_MenuItem(ctx, 'Remove from favourites') then
        remove_modifier_from_favourites(mod)
      end
    end
    reaper.ImGui_EndPopup(ctx)
  end
end

function copy_context()
  if reaper.ImGui_MenuItem(ctx, 'Copy as preset to clipboard') then
    local tbl = deepcopy(modifier_stack)
    local n_tbl = {stack = tbl, is_modstk = true}
    local tstr = json.encode(n_tbl)
    reaper.ImGui_SetClipboardText(ctx, tstr)
  end
  if reaper.ImGui_MenuItem(ctx, 'Copy as command to clipboard') then
    local compile_str = compile_modifier_stack(modifier_stack)
    reaper.ImGui_SetClipboardText(ctx, compile_str)
  end
  
  if not has_js_API then reaper.ImGui_BeginDisabled(ctx) end
  if reaper.ImGui_MenuItem(ctx, 'Generate lua script') then
    generate_lua_script_from_stack(modifier_stack)
  end
  if not has_js_API then reaper.ImGui_EndDisabled(ctx) end
end

function load_context()
  if reaper.ImGui_MenuItem(ctx, 'Load from file') then
    local r, stack = load_modifier_stack()
    if r then
      if #modifier_stack ~= 0 then
        unselect_all_items()
      end
      ext_clear()
      ext_reset()
      modifier_stack = stack
      exec = true
      focus_filter = true
    end    
  end
  if reaper.ImGui_MenuItem(ctx, 'Load from clipboard') then
    local ret, stack = get_modifier_stack_from_clipboard()
    if ret then
      if #modifier_stack ~= 0 then
        unselect_all_items()
      end
      ext_clear()
      ext_reset()
      modifier_stack = stack
      exec = true
    end
  end
end

local id = 0
function draw_mods(mods, filter)
  local exec = false
  id = 0
  for i = 1, #mods do 
    id = id + 1
    reaper.ImGui_PushID(ctx, id) 
    
    --Selectable
    local mod = mods[i]
    local show = filter and
    reaper.ImGui_TextFilter_PassFilter(filter, mod.name) or not filter
    if show then
      local r, v = reaper.ImGui_Selectable(ctx, mod.name, false) 
      if r then 
        local new_mod = deepcopy(mod)
        table.insert(modifier_stack, new_mod)
        --Set selection
        if #modifier_stack == 1 then
          ext_reset()
        end
        modifier_filter = ''
        filter_auto_focus()
        exec = true
      end
      --Context Menu
      mod_context(mod)
    end
    reaper.ImGui_PopID(ctx)
  end
  return exec
end

function buttons()
    local button_spacing = 25
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(), 5, 4)
    if reaper.ImGui_Button(ctx, 'Apply') then
      ext_select_all()
      fc_clear_state(false, true)
      modifier_stack = {}
      focus_filter = true
    end
    colored_frame(0xFFFFFF20)
    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_Button(ctx, 'Reset') then
      reset_modifier_stack(modifier_stack)
      exec = true
    end
    colored_frame(0xFFFFFF20)
    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_Button(ctx, 'Clear') then
      ext_clear()
      modifier_stack = {}
      focus_filter = true
    end
    colored_frame(0xFFFFFF20)
    reaper.ImGui_SameLine(ctx, 0, button_spacing)
    if reaper.ImGui_Button(ctx, 'Seed') then
      ext_reset_seed()
      exec = true
    end
    colored_frame(0xFFFFFF20)
    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_Button(ctx, 'Select') then
      ext_clear(true)
      ext_reset()
      focus_filter = true
      exec = true
    end
    colored_frame(0xFFFFFF20)
    reaper.ImGui_SameLine(ctx, 0, button_spacing)
    if reaper.ImGui_Button(ctx, 'Save') then
      local r, nm = reaper.GetUserInputs( "Enter name", "1", ',extrawidth=200', '')
      if r then
        save_modifier_stack(modifier_stack, nm)
        focus_filter = true
      end
    end
    colored_frame(0xFFFFFF20)
    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_Button(ctx, 'Load') then
      reaper.ImGui_OpenPopup(ctx, 'Load Menu')
    end
    colored_frame(0xFFFFFF20)
    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_Button(ctx, 'Copy') then
      reaper.ImGui_OpenPopup(ctx, 'Copy Menu')
    end
    colored_frame(0xFFFFFF20)
    reaper.ImGui_Separator(ctx)
    reaper.ImGui_PopStyleVar(ctx)
end

local display_id = 0
local active_item_peaks = {}
local last_sel_items = {}
local last_sel_tracks = {}
function item_modifiers_frame()
  load_stack = false
  exec = false 
  
  
  local modifier_menu_size = 154
  local w = get_window()
  local cx, cy = get_cur()
  local h = w.h - cy - w.pd_y - 1
  local stack_width = w.w - cx - w.pd_x - modifier_menu_size - 4

  
  
  --PEAKS
  if #modifier_stack == 0 then
    local items, total_len, tracks = get_selected_items_tracks()
    if not shallow_table_equals_items(items, last_sel_items, tracks, last_sel_tracks) then
      local peak_data = fetch_item_peak_data(items, stack_width, total_len, peak_display_padding)
      active_item_peaks = peak_data
    end
    last_sel_items = items
    last_sel_tracks = tracks
  end
  
  --Keyboard focus
  local ctrl = get_ctrl()
  if reaper.ImGui_IsKeyPressed(ctx, 0x46, false) then
    focus_filter = true
  end
  

  --Modifiers
  if reaper.ImGui_BeginChild(ctx, 'Modifier List', modifier_menu_size, h, true) then
    
    
    --Filter
    if focus_filter then
      focus_filter = false
      reaper.ImGui_SetKeyboardFocusHere(ctx)
    end
    local r, s = reaper.ImGui_InputText(ctx, 'Filter', modifier_filter, reaper.ImGui_InputTextFlags_AutoSelectAll())
    if s then modifier_filter = s end
    
    local filter = reaper.ImGui_CreateTextFilter(modifier_filter)
    local modifier_table = chunk_modifiers_by_tag(modifiers)
    
    
    --Modifier Listbox
    push_listbox_theme()
    local cx, cy = get_cur()
    if reaper.ImGui_BeginListBox(ctx, '##Mods', -FLT_MIN, h - cy - w.pd_y) then
      if modifier_filter == '' then
        --Draw tags
        for j = 1, #modifier_table do
          reaper.ImGui_PushID(ctx, j)
          local tag = modifier_table[j].tag
          local mods = modifier_table[j].mods
          if reaper.ImGui_CollapsingHeader(ctx, tag, false) then
            exec = draw_mods(mods)
          end
          reaper.ImGui_PopID(ctx)
        end
      else
        --Draw search query
        local mods = modifier_table[5].mods
        exec = draw_mods(mods, filter)
      end
      reaper.ImGui_EndListBox(ctx)
    end
    pop_listbox_theme()


    reaper.ImGui_EndChild(ctx)
  end
  reaper.ImGui_SameLine(ctx)


  --Stack
  if reaper.ImGui_BeginChild(ctx, 'Command Builder', stack_width, h, true) then
    
    
    --Title
    push_big_font()
    reaper.ImGui_Separator(ctx)
    centered_text('STACK')
    reaper.ImGui_Separator(ctx)
    pop_big_font()

    
    --Stack buttons
    buttons()

    
    --Button popups
    if reaper.ImGui_BeginPopupContextItem(ctx, 'Copy Menu') then
      copy_context()
      reaper.ImGui_EndPopup(ctx)
    end
    if reaper.ImGui_BeginPopupContextItem(ctx, 'Load Menu') then
      load_context()
      reaper.ImGui_EndPopup(ctx)
    end   
    

    --Item peaks
    local curx, cury = dl_get_cursor()
    local peak_h = 50
    draw_items_batch(active_item_peaks, curx, cury, stack_width - 2*w.pd_x, peak_h, peak_display_padding, false)
    reaper.ImGui_SetCursorPosY(ctx, cury + peak_h + 3)
    reaper.ImGui_Separator(ctx)
    
    
    --Stack
    local pending_removal = {}
    local pending_swap = {}
    local cx, cy = get_cur()
    push_listbox_theme()
    if reaper.ImGui_BeginListBox(ctx, '##Stack', -FLT_MIN, h - cy - w.pd_y) then
      push_mod_stack_theme()   
      for i = 1, #modifier_stack do
        local mod = modifier_stack[i]
        if not mod.display_id then
          mod.display_id = display_id
          display_id = display_id + 1
        end
        reaper.ImGui_PushID(ctx, mod.display_id)
        
        
        --Header
        reaper.ImGui_SetNextItemOpen(ctx, true,  reaper.ImGui_Cond_Appearing())       
        local hr, hb = reaper.ImGui_CollapsingHeader(ctx, mod.name, true) 

        
        --DRAG/DROP
        local flags = reaper.ImGui_DragDropFlags_AcceptBeforeDelivery() | 
        reaper.ImGui_DragDropFlags_SourceNoHoldToOpenOthers()
        if reaper.ImGui_BeginDragDropSource(ctx, flags) then
          reaper.ImGui_SetDragDropPayload(ctx, 'MODIFIER', i)
          reaper.ImGui_Text(ctx, mod.name)
          reaper.ImGui_EndDragDropSource(ctx)
        end
        if reaper.ImGui_BeginDragDropTarget(ctx) then
          local _, _, m_id = reaper.ImGui_GetDragDropPayload(ctx)
          
          local sp_offs = -24
          if tonumber(m_id) < i then
            sp_offs = -4
          end
          custom_separator(sp_offs)
          
          local r, payload = reaper.ImGui_AcceptDragDropPayload(ctx, 'MODIFIER')
          if r then
            table.insert(pending_swap, {tonumber(payload), i})
          end
          reaper.ImGui_EndDragDropTarget(ctx)
        end
        
        
        if hr then
          local r = draw_cmd(mod.map)
          exec = exec or r
        end
        if hb == false then 
          table.insert(pending_removal, i) 
          exec = true
        end
        
        
        reaper.ImGui_PopID(ctx)
      end
      pop_mod_stack_theme()
      reaper.ImGui_EndListBox(ctx)
    end
    pop_listbox_theme()

    
    --Delete and reorder
    for i = 1, #pending_removal do
      table.remove(modifier_stack, pending_removal[i])
      exec = true
      focus_filter = true
    end
    for i = 1, #pending_swap do
      local swap = pending_swap[i]
      local mod = table.remove(modifier_stack, swap[1])
      table.insert(modifier_stack, swap[2], mod)
      exec = true
      focus_filter = true
    end
    

    --Execute
    if exec then
      unselect_all_items()
      local cmd_str = compile_modifier_stack(modifier_stack)
      ext_execute(cmd_str, false, true)
    end
    reaper.ImGui_EndChild(ctx)
  end
end