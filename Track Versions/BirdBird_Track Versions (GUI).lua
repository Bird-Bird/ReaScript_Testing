--@noindex

function p(msg) reaper.ShowConsoleMsg(tostring(msg)..'\n')end
function debug_print(msg) if settings.debug_mode then reaper.ShowConsoleMsg(tostring(msg)..'\n') end end
dofile(reaper.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/imgui.lua')('0.6')
function reaper_do_file(file) local info = debug.getinfo(1,'S'); local path = info.source:match[[^@?(.*[\/])[^\/]-$]]; dofile(path .. file); end
reaper_do_file('track_versions_libraries/functions.lua')
reaper_do_file('gui.lua')

local FLT_MIN, FLT_MAX = reaper.ImGui_NumericLimits_Float()
local window_resize_flag = reaper.ImGui_Cond_Appearing()
local calc_button_offs = 56

function settings_menu()
    reaper.ImGui_SetNextWindowSize(ctx, 154, 205, window_resize_flag)
    if reaper.ImGui_BeginPopupModal(ctx, 'Settings', nil) then
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgHovered(), 0x12BD993A)
        
        local save = false
        rv, settings.prefix_tracks = reaper.ImGui_Checkbox(ctx, 'Prefix tracks', settings.prefix_tracks)
        if rv then
            save = true
        end
        reaper.ImGui_Separator(ctx)
        
        rv, settings.use_full_height_versions = reaper.ImGui_Checkbox(ctx, 'Use full height', settings.use_full_height_versions)
        if rv then
            save = true
        end
        reaper.ImGui_Separator(ctx)

        rv, settings.slim_mode = reaper.ImGui_Checkbox(ctx, 'Slim mode', settings.slim_mode)
        if rv then
            save = true
        end
        reaper.ImGui_Separator(ctx)

        rv, settings.debug_mode = reaper.ImGui_Checkbox(ctx, 'Debug mode', settings.debug_mode)
        if rv then
            save = true
        end
        reaper.ImGui_Separator(ctx)

        if save then
            save_settings(settings)
        end
        if reaper.ImGui_Button(ctx, 'Close') then
            reaper.ImGui_CloseCurrentPopup(ctx)
        end
        reaper.ImGui_PopStyleColor(ctx)
        reaper.ImGui_EndPopup(ctx)
    end
end

function selection_indicator(sel_data)
    local t = '' 
    if not settings.slim_mode then
      if #sel_data == 0 then 
          t = 'No tracks selected.' 
      elseif #sel_data == 1 
      then 
          t = '1 track selected.' 
      else
          t = #sel_data .. ' tracks selected.'
      end
    else
        t = 'Sel - ' .. #sel_data
    end
    reaper.ImGui_Text(ctx, t)

    local show_checkmark = true
    if #sel_data > 1 then
        reaper.ImGui_BeginDisabled(ctx)
        show_checkmark = false
    end
    if #sel_data > 0 then
        right_align_padding(40)
        push_small_font()
        local sd = sel_data[1]
        r, sd.query.load_fx = reaper.ImGui_Checkbox(ctx, 'FX', sd.query.load_fx and show_checkmark)
        if r then
            reaper.Undo_BeginBlock()
            save_track_query(sd.track, sd.query) 
            reaper.Undo_EndBlock('Toggle loading FX for track.', -1)
        end
        reaper.ImGui_PopFont(ctx)
    end
    if #sel_data > 1 then
        reaper.ImGui_EndDisabled(ctx)
    end
end

function init_empty_tracks(sel_data)
    for i = 1, #sel_data do
        local track = sel_data[i].track
        local query = sel_data[i].query
        if query.num_versions == 1 and query.selected == 0 then
            local state = get_ext_state(track)
            add_new_version(track, state, false)
        end
    end
end

local bt_labels = {
  add = 'Add',
  del = 'Delete',
  col = 'Collapse'
}
local bt_labels_slim = {
  add = '+',
  del = '-',
  col = 'c'
}
function buttons(sel_data, switch)
    local lb = settings.slim_mode and bt_labels_slim or bt_labels

    --ADD NEW VERSION
    if theme_button(ctx, lb.add) then
        init_empty_tracks(sel_data)
        reaper.PreventUIRefresh(1)
        reaper.Undo_BeginBlock()
        local clear = get_ctrl()
        for i = 1, #sel_data do 
            local track = sel_data[i].track
            local state = get_ext_state(track)
            add_new_version(track, state, clear)
            if settings.prefix_tracks then prefix_track_fast(track) end
        end
        reaper.Undo_EndBlock('Track Versions - Add New Version', -1)
        reaper.PreventUIRefresh(-1)
        reaper.UpdateArrange()        
    end

    --DELETE VERSION
    reaper.ImGui_SameLine(ctx)
    if theme_button(ctx, lb.del) then
        init_empty_tracks(sel_data)
        reaper.PreventUIRefresh(1)
        reaper.Undo_BeginBlock()
        for i = 1, #sel_data do 
            local track = sel_data[i].track
            local state = get_ext_state(track)
            delete_current_version(track, state)
            if settings.prefix_tracks then prefix_track_fast(track) end
        end
        reaper.Undo_EndBlock('Track Versions - Delete Version', -1)
        reaper.PreventUIRefresh(-1)
        reaper.UpdateArrange()        
    end

    if settings.debug_mode then
        reaper.ImGui_SameLine(ctx)
        if reaper.ImGui_Button(ctx, 'P') then
            for i = 1, #sel_data do 
                local track = sel_data[i].track
                local state = get_ext_state(track)
                print_table(state)
            end
        end
    end

    --COLLAPSE VERSIONS
    local bt_offs = settings.slim_mode and 14 or calc_button_offs
    right_align_padding(bt_offs)
    if theme_button(ctx, lb.col) then
        init_empty_tracks(sel_data)
        reaper.PreventUIRefresh(1)
        reaper.Undo_BeginBlock()
        for i = 1, #sel_data do 
            local track = sel_data[i].track
            local state = get_ext_state(track)
            collapse_versions(track, state)
            if settings.prefix_tracks then prefix_track_fast(track) end
        end
        reaper.Undo_EndBlock('Track Versions - Collapse Versions', -1)
        reaper.PreventUIRefresh(-1)
        reaper.UpdateArrange()        
    end

    --SWITCH VERSIONS
    if switch then
        init_empty_tracks(sel_data)
        local partial_load = get_shift()
        reaper.PreventUIRefresh(1)
        reaper.Undo_BeginBlock()
        for i = 1, #sel_data do 
            local track = sel_data[i].track
            local state = get_ext_state(track)
            switch_versions(track, state, switch, false, partial_load)
            if settings.prefix_tracks then prefix_track_fast(track) end
        end
        reaper.Undo_EndBlock('Track Versions - Switch Versions', -1)
        reaper.PreventUIRefresh(-1)
        reaper.UpdateArrange()
    end
end

function frame()
    local switch = nil
    local prefix = false
    local sel_data, min_versions, common_sel, no_versions = get_selected_tracks_fast()
    
    --SELECTED TRACKS
    selection_indicator(sel_data)
    
    --DISPLAY VERSIONS
    local r_size = get_listbox_size(min_versions)
    if reaper.ImGui_BeginListBox(ctx, '##listbox_1', -FLT_MIN, r_size) then
        for i = 1, min_versions do
            reaper.ImGui_PushID(ctx, i)
            
            local is_selected = common_sel ~= -1 and common_sel == i
            r, p_selected = reaper.ImGui_Selectable(ctx, 'v' .. i, is_selected)
            if r then
                switch = i
            end

            reaper.ImGui_PopID(ctx)
        end
        reaper.ImGui_EndListBox(ctx)
    end

    buttons(sel_data, switch)
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
                dock = -3
            end
        end
        reaper.ImGui_EndPopup(ctx)
    end
    if open_settings then
        open_settings = false
        reaper.ImGui_OpenPopup(ctx, 'Settings')
    end
end

local show_style_editor = false
if show_style_editor then 
    demo = dofile(reaper.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/ReaImGui_Demo.lua')
end

function loop()
    --GUI
    --THEME
    reaper.ImGui_PushFont(ctx, font)
    push_theme()
    if show_style_editor then         
        demo.PushStyle(ctx)
        demo.ShowDemoWindow(ctx)
    end
    
    --FRAME
    if dock then reaper.ImGui_SetNextWindowDockID(ctx, dock); dock = nil end
    reaper.ImGui_SetNextWindowSize(ctx, 173, 245, reaper.ImGui_Cond_FirstUseEver())
    visible, open = reaper.ImGui_Begin(ctx, 'Track Versions', false)
    window_is_docked = reaper.ImGui_IsWindowDocked(ctx)

    reset_scroll()
    if window_is_docked then top_frame() end
    custom_close_button()
    close_context(window_is_docked)
    settings_menu()

    reaper.ImGui_PopStyleVar(ctx)
    if visible then
        frame()
        reaper.ImGui_End(ctx)
    end
    
    --THEME
    if show_style_editor then
        demo.PopStyle(ctx)
    end
    pop_theme()
    reaper.ImGui_PopFont(ctx)
    
    if open then
        reaper.defer(loop)
    else
        reaper.ImGui_DestroyContext(ctx)
    end
end
loop()