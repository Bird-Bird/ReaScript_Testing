-- @noindex

function save_menu(ctx)
  if reaper.ImGui_BeginPopupContextItem(ctx, "Save Menu") then
    if reaper.ImGui_MenuItem(ctx, "Save tab set as...") then
      local set = generate_set_data()
      local success, set_file = save_tab_set_to_file(set)
      if success then
        save_as_most_recent_tab_set(set_file)
      end
    end

    local recent_set_exists = global_settings.most_recent_tab ~= ""
    if recent_set_exists == false then
      reaper.ImGui_BeginDisabled(ctx)
    end
    if reaper.ImGui_MenuItem(ctx, "Save into most recent tab set...") then
      local has_last_set, last_set_file = get_most_recent_tab_set()
      if has_last_set == true then
        local result = reaper.ShowMessageBox("This action will overwrite the following tab set with currently open tabs:\n" .. last_set_file .. "\n\nDo you want to proceed?" , "Project Tab Set - Warning", 1)
        if result == 1 then
          local set = generate_set_data()
          save_tab_set_to_file(set, last_set_file)
        end
      else
        reaper.ShowMessageBox("No valid tab set file found in history.", "Project Tab Set - Error", 0)
      end
    end
    if recent_set_exists == false then
      reaper.ImGui_EndDisabled(ctx)
    end

    reaper.ImGui_Separator(ctx)
    if reaper.ImGui_BeginMenu(ctx, "Project root folder") then
      if reaper.ImGui_MenuItem(ctx, "Set project root folder...") then
        browse_for_project_root()
      end

      local user_has_project_root = global_settings.project_root ~= ""
      if user_has_project_root == false then 
        reaper.ImGui_BeginDisabled(ctx)
      end
      if reaper.ImGui_MenuItem(ctx, "Unset project root folder") then
        clear_project_root()
      end
      if user_has_SWS then
        reaper.ImGui_Separator(ctx)
        if reaper.ImGui_MenuItem(ctx, "Open project root folder in explorer/finder") then
          reaper.CF_ShellExecute(global_settings.project_root)
        end
      end
      if user_has_project_root == false then 
        reaper.ImGui_EndDisabled(ctx)
      end
      reaper.ImGui_EndMenu(ctx)
    end

    reaper.ImGui_Separator(ctx)
    if reaper.ImGui_MenuItem(ctx, "Save as SWS project list...") then
      browse_for_sws_project_list_save()
    end

    reaper.ImGui_EndPopup(ctx)
  end
end

function load_menu(ctx)
  if reaper.ImGui_BeginPopupContextItem(ctx, "Load Menu") then
    local load_set, additive_load = false, false
    if reaper.ImGui_MenuItem(ctx, "Load tab set...") then
      load_set = true
      additive_load = false
    end
    if reaper.ImGui_MenuItem(ctx, "Append projects from tab set...") then
      load_set = true
      additive_load = true
    end

    reaper.ImGui_Separator(ctx)
    if reaper.ImGui_MenuItem(ctx, "Load SWS project list...") then
      local success, lines = browse_for_sws_project_list_load()
      if success then
        local set = generate_set_data_from_table(lines)
        load_tabs_from_set_data(set, false)
        clear_most_recent_tab_set()
      end
    end

    if load_set then
      local success, set, set_file = load_tab_set_data_from_file()
      if success then
        if additive_load == false then
          close_all_projects_no_prompt()
          save_as_most_recent_tab_set(set_file)
        end
        load_tabs_from_set_data(set, false)
      end 
    end

    reaper.ImGui_EndPopup(ctx)
  end
end

function frame(ctx)
  local current_project, current_project_name = reaper.EnumProjects(-1)

  --tab display
  local button_height, button_height_offset = get_button_height(ctx)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding(), 0, 8)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(), 0x6E6E8000)
  if reaper.ImGui_BeginChild(ctx, "Tab Display", 0, -button_height_offset, true) then
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(), 8, 16)
    local project_id = 0
    for project, name in enum_projects(nil) do
      local new_name = parse_project_path_crossplatform(name == "" and "Unsaved" or name)
      local rv, value = reaper.ImGui_Selectable(ctx, " " .. new_name:match("([^/]+)$") .. 
                                                      ((reaper.IsProjectDirty(project) == 1) and " *" or ""), current_project == project)
      if rv then 
        reaper.SelectProjectInstance(project)
        if user_has_SWS then
          local focus_arrange = reaper.NamedCommandLookup("_BR_FOCUS_ARRANGE_WND")
          reaper.Main_OnCommand(focus_arrange, -1)
        end
      end

      --drag and drop to reorder
      if reaper.ImGui_BeginDragDropSource(ctx,  reaper.ImGui_DragDropFlags_AcceptBeforeDelivery()) then
        reaper.ImGui_SetDragDropPayload(ctx, 'TAB', project_id)
        reaper.ImGui_EndDragDropSource(ctx)
      end
      if reaper.ImGui_BeginDragDropTarget(ctx) then
        --separator
        local _, _, original_tab_id_early = reaper.ImGui_GetDragDropPayload( ctx )
        local direction = project_id - original_tab_id_early > 0 and 0 or -1
        local selectable_size = get_selectable_height(ctx)
        local y_offset = direction*selectable_size + (project_id == 0 and 2 or 0)
        draw_drag_highlight(ctx, y_offset - 1, 0.05)
        draw_drag_highlight(ctx, y_offset, 0.45)
        draw_drag_highlight(ctx, y_offset + 1, 0.05)
        draw_drag_grad_rect(ctx, selectable_size, 0.06, direction == -1)
  
        local success, original_tab_id = reaper.ImGui_AcceptDragDropPayload(ctx, 'TAB')
        if success then
          --nudge project tab
          local drag_source_project = reaper.EnumProjects(original_tab_id)
          reaper.PreventUIRefresh(1)
          reaper.SelectProjectInstance(drag_source_project)

          local distance = original_tab_id - project_id
          local nudge_command = distance < 0 and 3243 or 3242
          for i = 1, math.abs(distance) do 
            reaper.Main_OnCommand(nudge_command, -1)
          end

          reaper.SelectProjectInstance(current_project)
          reaper.PreventUIRefresh(-1)
        end
        reaper.ImGui_EndDragDropTarget(ctx)
      end
      project_id = project_id + 1

    end

    reaper.ImGui_PopStyleVar(ctx, 1)
    reaper.ImGui_EndChild(ctx)
  end
  reaper.ImGui_PopStyleVar(ctx, 1)
  reaper.ImGui_PopStyleColor(ctx)

  --cosmetics
  draw_custom_separator(ctx)
  draw_upwards_grad_rect(ctx, 220)
  
  --buttons
  save_menu(ctx)
  load_menu(ctx)
  
  if reaper.ImGui_Button(ctx, "Save") then
    reaper.ImGui_OpenPopup(ctx, "Save Menu")
  end
  reaper.ImGui_SameLine(ctx)
  if reaper.ImGui_Button(ctx, "Open") then
    reaper.ImGui_OpenPopup(ctx, "Load Menu")
  end
  reaper.ImGui_SameLine(ctx)

  --this button was red, seemed too attention grabbing so its no longer red
  --reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(),        0xFA427C66)
  --reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0xFA427CB8)
  --reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(),  0xC93B68FF)
  if reaper.ImGui_Button(ctx, "Close Tabs") then
    local result = reaper.ShowMessageBox("Are you sure you want to close all open project tabs?", "Project Tab Set - Close Tabs", 1)
    if result == 1 then
      close_all_projects_no_prompt()
    end
  end
  --reaper.ImGui_PopStyleColor(ctx, 3)
end