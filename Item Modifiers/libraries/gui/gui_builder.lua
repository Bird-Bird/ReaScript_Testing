-- @noindex

local input = ''
local name = ''
local tag_name = ''

local cur_modifier = get_empty_modifier()
local last_err
local editor_compile = false

local loaded_file = window_data.builder_data
local modifiers = loaded_file.mods
function save_menu(cur_modifier)
  reaper.ImGui_SameLine(ctx)
  if reaper.ImGui_Button(ctx, 'Save') then
    append_modifier(modifiers, cur_modifier)
    save_to_file(loaded_file.path, modifiers)
  end
end

function builder_frame()
  local exec = false

  local modifier_menu_size = 150
  local w = get_window()
  local cx, cy = get_cur()
  local h = w.h - cy - w.pd_y - 1
  
  --MODIFIER LIST
  if reaper.ImGui_BeginChild(ctx, 'Modifier List', modifier_menu_size, h, true) then
    local pending_removal = {}
    for i = 1, #modifiers do
      local modifier = modifiers[i]
      if not modifier.name or modifier.name == '' then modifier.name = 'Empty Modifier' end
      local r, v = reaper.ImGui_Selectable(ctx, modifier.name, false)
      if r then
        cur_modifier = deepcopy(modifier)
        if not cur_modifier.tags then cur_modifier.tags = {} end
        editor_compile = true
      end
      if reaper.ImGui_BeginPopupContextItem(ctx) then
        if reaper.ImGui_MenuItem(ctx, 'Delete') then
          table.insert(pending_removal, i)
        end
        reaper.ImGui_EndPopup(ctx)
      end
    end
    for i = 1, #pending_removal do
      table.remove(modifiers, pending_removal[i])
      save_to_file(loaded_file.path, modifiers)
    end
    reaper.ImGui_EndChild(ctx)
  end

  --EDITOR
  reaper.ImGui_SameLine(ctx)
  if reaper.ImGui_BeginChild(ctx, 'Command Builder', w.w - cx - w.pd_x - modifier_menu_size - 4, h, true) then
  
    --Name
    local rv, txt = reaper.ImGui_InputText(ctx, 'Name', cur_modifier.name)
    if rv then cur_modifier.name = txt end
    if reaper.ImGui_Button(ctx, 'Select') then
      ext_reset()
      exec = true
    end
    local enabled = (not last_err) and (not command_is_empty(cur_modifier.map))
    and (cur_modifier.name ~= '' and cur_modifier.name ~= nil)
    if not enabled then
      reaper.ImGui_BeginDisabled(ctx)
    end
    save_menu(cur_modifier)
    if not enabled then
      reaper.ImGui_EndDisabled(ctx)
    end
    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_Button(ctx, 'New') then
      cur_modifier = get_empty_modifier()
      exec = true
    end
    reaper.ImGui_Separator(ctx)

    --Tags
    if reaper.ImGui_BeginListBox(ctx, '##listbox_1', -1, 50) then
      if cur_modifier.tags then
        local pending_removal = {}
        for i = 1, #cur_modifier.tags do
          local t = cur_modifier.tags[i]
          reaper.ImGui_PushID(ctx, i)
          local r, v = reaper.ImGui_Selectable(ctx, t, false) 
          if reaper.ImGui_BeginPopupContextItem(ctx) then
            if reaper.ImGui_MenuItem(ctx, 'Delete') then
              table.insert(pending_removal, i)
            end
            reaper.ImGui_EndPopup(ctx)
          end         
          reaper.ImGui_PopID(ctx)
        end
        for i = 1, #pending_removal do
          table.remove(cur_modifier.tags, pending_removal[i])
        end
      end
      reaper.ImGui_EndListBox(ctx)
    end
    
    local rv, txt = reaper.ImGui_InputText(ctx, '##Tag', tag_name)
    if rv then tag_name = txt end
    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_Button(ctx, 'Tag') and cur_modifier.tags then
      table.insert(cur_modifier.tags, tag_name)
      tag_name = ''
    end
    reaper.ImGui_Separator(ctx)


    --Command input
    local success, cmd
    r, rtxt = reaper.ImGui_InputTextMultiline(ctx, '##Command Builder', cur_modifier.lines, -1, 200)
    if r or editor_compile then
      if r then cur_modifier.lines = rtxt end
      editor_compile = false
      if cur_modifier.lines == '' then
        --CLEAR
        ext_execute('', false, true)
        local name = cur_modifier.name
        cur_modifier = get_empty_modifier()
        cur_modifier.name = name
      else
        success, cmd, last_err = get_cmd_from_input(cur_modifier.lines)
        if success then 
          cur_modifier.map = cmd
          exec = true
        end
      end
    end
    reaper.ImGui_Separator(ctx)
    
    
    --Command GUI
    if last_err then
      reaper.ImGui_Text(ctx, last_err)
    else
      if cur_modifier.map then
        local r = draw_cmd(cur_modifier.map)
        exec = exec or r
      end
    end
    reaper.ImGui_EndChild(ctx)
  end

  
  --Command execution
  if exec then 
    local cmd_str = ''
    if cur_modifier.map then
      cmd_str = build_command(cur_modifier.map)
    end
    ext_execute(cmd_str, false, true)
  end
end

