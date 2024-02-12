-- @description Track Tags
-- @version 0.6.1
-- @author BirdBird
-- @provides
--    [nomain]libraries/functions.lua
--    [nomain]libraries/json.lua
--@changelog
--  + Improve performance

function p(msg) reaper.ShowConsoleMsg(tostring(msg) .. '\n') end
dofile(reaper.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/imgui.lua')('0.6')
function reaper_do_file(file) local info = debug.getinfo(1,'S'); path = info.source:match[[^@?(.*[\/])[^\/]-$]]; dofile(path .. file); end
reaper_do_file('libraries/json.lua')
reaper_do_file('libraries/functions.lua')

--DEPENDENCY CHECK
if not reaper.APIExists('ImGui_GetVersion') then
    local text = 'Track Tags requires the ReaImGui extension to run. You can install it through ReaPack.'
    local ret = reaper.ShowMessageBox(text, 'Missing Dependency', 0)
    return
end

--GUI
ctx = reaper.ImGui_CreateContext('Track Tags', reaper.ImGui_ConfigFlags_DockingEnable())
local size = reaper.GetAppVersion():match('OSX') and 12 or 14
local size_big = math.floor(size*1.3)

local font = reaper.ImGui_CreateFont('sans-serif', size)
local font_big = reaper.ImGui_CreateFont('Courier New', size_big)
local window_resize_flag = reaper.ImGui_Cond_Appearing()

reaper.ImGui_AttachFont(ctx, font)
reaper.ImGui_AttachFont(ctx, font_big)

--SETTINGS
local settings = get_settings()
function settings_menu()
    reaper.ImGui_SetNextWindowSize(ctx, 542, 132, window_resize_flag)
    if reaper.ImGui_BeginPopupModal(ctx, 'Settings', nil) then
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgHovered(), 0x12BD993A)
        local save = false

        r, settings.auto_tag_tracks = reaper.ImGui_Checkbox(ctx, 
        '##s1',
        settings.auto_tag_tracks)
        reaper.ImGui_SameLine(ctx)
        reaper.ImGui_TextWrapped(ctx, 'Automatically tag tracks that are newly created or made visible when there is an active tag.')
        if r then 
            save = true
        end
        reaper.ImGui_Separator(ctx)

        r, settings.auto_load_tags_merge = reaper.ImGui_Checkbox(ctx, 
        '##s2',
        settings.auto_load_tags_merge)
        reaper.ImGui_SameLine(ctx)
        reaper.ImGui_TextWrapped(ctx, 'Automatically load tags after merging.')
        if r then 
            save = true
        end
        reaper.ImGui_Separator(ctx)

        r, settings.auto_hide_tracks_when_tag_active = reaper.ImGui_Checkbox(ctx, 
        '##3',
        settings.auto_hide_tracks_when_tag_active)
        reaper.ImGui_SameLine(ctx)
        reaper.ImGui_TextWrapped(ctx, 'Automatically hide tracks when they are removed from the active tag.')
        if r then 
            save = true
        end

        if reaper.ImGui_Button(ctx, 'Close') then
            reaper.ImGui_CloseCurrentPopup(ctx)
        end
        
        if save then
            save_settings(settings)
            settings = get_settings()
        end
        reaper.ImGui_PopStyleColor(ctx)
        reaper.ImGui_EndPopup(ctx)
    end
end

function colored_frame(col)
    local draw_list = reaper.ImGui_GetWindowDrawList(ctx)
    local text_min_x, text_min_y = reaper.ImGui_GetItemRectMin(ctx)
    local text_max_x, text_max_y = reaper.ImGui_GetItemRectMax(ctx)
    reaper.ImGui_DrawList_AddRect(draw_list, text_min_x, text_min_y, text_max_x, text_max_y, col)
end

local blacklist_text = ''
function blacklist_menu()
    reaper.ImGui_SetNextWindowSize(ctx, 299, 380, window_resize_flag)
    if reaper.ImGui_BeginPopupModal(ctx, 'Global Blacklist', nil) then
        local focus = false
        if reaper.ImGui_IsWindowAppearing(ctx) then
            focus = true
        end
        local save = false
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_SelectableTextAlign(), 0, 0)
        
        --LIST
        local pending_removal = {}
        if reaper.ImGui_BeginListBox(ctx, '##listbox_3', -1, 300) then
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
        local r, text = reaper.ImGui_InputText(ctx, '##blacklist', text)
        if r then blacklist_text = text end
        reaper.ImGui_SameLine(ctx)
        if reaper.ImGui_Button(ctx, 'Add') then
            table.insert(blacklist, blacklist_text)
            save = true
            blacklist_text = ''
        end
        if save then
            save_blacklist(blacklist)
        end
        if reaper.ImGui_Button(ctx, 'Close') then
            reaper.ImGui_CloseCurrentPopup(ctx)
        end
        reaper.ImGui_PopStyleVar(ctx)
        reaper.ImGui_EndPopup(ctx)
    end
end

local text_input
local text
local selected_tag = nil
local popup_dat = nil

local tags, lookup, new_tracks
local last_project, last_change_count = nil, 0
function frame()
    local open_rename_popup = false
    
    local project = reaper.EnumProjects(-1)
    local project_change_count = reaper.GetProjectStateChangeCount(project)
    if (last_project ~= project or project_change_count ~= last_change_count) then
      tags, lookup, new_tracks = get_tracks_tags()
    end
    last_project = project
    last_change_count = project_change_count
    
    local sel_tracks = get_selected_tracks()
    local multiple_tracks = #sel_tracks > 1
   
    --SELECTED TRACK DISPLAY
    local show_tracks = false
    if #sel_tracks == 0 then
        reaper.ImGui_Text(ctx, "No tracks selected.")
    else
        local t_text = #sel_tracks == 1 and " track " or " tracks "
        reaper.ImGui_Text(ctx, #sel_tracks .. t_text .. "selected.")
    end
    if show_tracks then
        if reaper.ImGui_BeginListBox(ctx, '##listbox_1', -1, 40) then --h - 29 - y) then
            for i = 1, #sel_tracks do 
                local track = sel_tracks[i]
                local t_id = math.floor(reaper.GetMediaTrackInfo_Value(track, 'IP_TRACKNUMBER'))
                local _, t_name = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', '', false)
                reaper.ImGui_PushID(ctx, i)
                local r, sel = reaper.ImGui_Selectable(ctx, t_id .. ': ' .. t_name)
                reaper.ImGui_PopID(ctx)
            end
            reaper.ImGui_EndListBox(ctx)
        end
    end

    --CREATE TAG
    local w = reaper.ImGui_GetWindowSize(ctx)
    local fp_x = reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding())
    reaper.ImGui_PushItemWidth(ctx, w - 12 - fp_x) --- 49)
    r, text_input = reaper.ImGui_InputText(ctx, '##name', text_input)
    if r then text = text_input end
    if reaper.ImGui_Button(ctx, 'Tag') and not validate_tag_name(lookup, text) and #sel_tracks > 0 then
        reaper.Undo_BeginBlock()
        for i = 1, #sel_tracks do
            local track = sel_tracks[i]
            local id = #tags > 0 and tags[#tags].id + 1 or 1
            local new_tag = {id = id, name = text}
            add_tag_to_track(track, new_tag)
        end
        reaper.Undo_EndBlock('Create new track tag', -1)

        table.insert(tags, new_tag)
        text_input = ''
        text = ''
    end
    --TAG RIGHT CLICK MENU
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding(), 4, 5)
    if reaper.ImGui_BeginPopupContextItem(ctx) then
        if reaper.ImGui_MenuItem(ctx, 'Clear all tags') then
            reaper.Undo_BeginBlock()
            clear_all_tags()
            reaper.Undo_EndBlock('Clear all track tags', -1)
        end
        reaper.ImGui_EndPopup(ctx)
    end
    reaper.ImGui_PopStyleVar(ctx)
    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_Button(ctx, "Add") and #sel_tracks > 0 then
        reaper.ImGui_OpenPopup(ctx, 'Add Menu')
    end
    local fp_x = reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding())
    local w, h = reaper.ImGui_GetWindowSize(ctx)
    reaper.ImGui_SameLine(ctx, w - 19 - fp_x)
    if reaper.ImGui_Button(ctx, "L") then
        reaper.ImGui_OpenPopup(ctx, 'Lock Menu')
    end
    --ERROR
    if lookup[text] then
        reaper.ImGui_TextWrapped(ctx, "A tag with the same name already exists.")
    end

    --LOCK AND ADD MENUS
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding(), 6, 5)
    if reaper.ImGui_BeginPopupContextItem(ctx, 'Lock Menu') then
        if #sel_tracks > 0 then
            local p = multiple_tracks and 's' or ''
            if reaper.ImGui_MenuItem(ctx, 'Lock track' .. p) then
                reaper.Undo_BeginBlock()
                for i = 1, #sel_tracks do
                    local t = sel_tracks[i]
                    lock_track(t)
                end
                reaper.Undo_EndBlock('Lock visibility for selected tracks', -1)
            end
            if reaper.ImGui_MenuItem(ctx, 'Unlock track' .. p) then
                reaper.Undo_BeginBlock()
                for i = 1, #sel_tracks do
                    local t = sel_tracks[i]
                    unlock_track(t)
                end        
                reaper.Undo_EndBlock('Unlock visibility for selected tracks', -1)
            end
        end
        if reaper.ImGui_MenuItem(ctx, 'Select locked tracks') then
            reaper.PreventUIRefresh(1)
            reaper.Undo_BeginBlock()
            select_locked_tracks()
            reaper.Undo_EndBlock('Select locked tracks', -1)
            reaper.PreventUIRefresh(-1)
        end
        reaper.ImGui_EndPopup(ctx)
    end
    if reaper.ImGui_BeginPopupContextItem(ctx, 'Add Menu') then
        if #tags == 0 then
            reaper.ImGui_Text(ctx, 'No tags found.')
        else
            if selected_tag then
                if reaper.ImGui_MenuItem(ctx, 'Add to active tag') then
                    reaper.Undo_BeginBlock()
                    for i = 1, #sel_tracks do
                        local tr = sel_tracks[i]
                        add_tag_to_track(tr, selected_tag)   
                    end
                    reaper.Undo_EndBlock('Add selected tracks to active tag', -1)  
                end
            end
            if reaper.ImGui_BeginMenu(ctx, 'Add tag') then
                for j = 1, #tags do
                    local t = tags[j]
                    if reaper.ImGui_MenuItem(ctx, t.name) then
                        reaper.Undo_BeginBlock()
                        for i = 1, #sel_tracks do
                            local tr = sel_tracks[i]
                            add_tag_to_track(tr, t)   
                        end
                        reaper.Undo_EndBlock('Add tag to selected tracks', -1)
                    end
                end
                reaper.ImGui_EndMenu(ctx)
            end
            if reaper.ImGui_BeginMenu(ctx, 'Remove tag') then
                for j = 1, #tags do
                    local t = tags[j]
                    if reaper.ImGui_MenuItem(ctx, t.name) then
                        reaper.PreventUIRefresh(1)
                        reaper.Undo_BeginBlock()
                        for i = 1, #sel_tracks do
                            local tr = sel_tracks[i]
                            remove_tag_from_track(tr, t)
                            if selected_tag and selected_tag.name == t.name and 
                            settings.auto_hide_tracks_when_tag_active then
                                set_track_visible(tr, nil, 0)
                            end
                        end
                        reaper.Undo_EndBlock('Remove tag from selected tracks', -1)
                        reaper.PreventUIRefresh(-1)
                        reaper.TrackList_AdjustWindows(false)
                    end
                end
                reaper.ImGui_EndMenu(ctx)
            end
        end
        reaper.ImGui_EndPopup(ctx)
    end
    reaper.ImGui_PopStyleVar(ctx)
    reaper.ImGui_Separator(ctx)

    --AUTO INSERT NEW TAGS
    local auto_insert = settings.auto_tag_tracks
    if selected_tag and #new_tracks > 0 and auto_insert then
        for i = 1, #new_tracks do
            local track = new_tracks[i]
            local ext = get_ext_state(track)
            if not ext.lock_visibility and not track_is_blacklisted(track) then
                reaper.Undo_BeginBlock()
                add_tag_to_track(track, selected_tag)
                reaper.Undo_EndBlock('Add new tag to tracks (Automatic tagging)', -1)
            end
        end
    end
    
    --DISPLAY TAGS
    local sel_size = size_big + 4
    local w, h = reaper.ImGui_GetWindowSize(ctx)
    local y, r = reaper.ImGui_GetCursorPosY(ctx), false
    local max_size = h - y - 10
    local r_size = #tags * (sel_size + 4) + 2; r_size = math.min(max_size, r_size)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(), 0x42424200)
    reaper.ImGui_PushFont(ctx, font_big)
    if reaper.ImGui_BeginListBox(ctx, '##listbox_2', -1, r_size) then
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Separator(), 0xFFFFFF00)
        for i = 1, #tags do
            local tag = tags[i]
            local tag_selected = selected_tag and selected_tag.name == tag.name or false

            local col = palette(i/6, 0.5)
            local h, hh, ha = palette(i/6, 0.5), palette(i/6, 0.03), palette(i/6, 0.5)
            local m_release = reaper.ImGui_IsMouseReleased( ctx, reaper.ImGui_MouseButton_Left())
            if tag_selected or m_release then hh = h end
            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Header(),        h )
            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderHovered(), hh)
            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderActive(),  ha)

            local r, p_selected = reaper.ImGui_Selectable(ctx, tag.name, tag_selected)
            if r then
                local shift = get_shift()
                if shift then
                    reaper.Undo_BeginBlock()
                    select_tag_only(tag)
                    reaper.Undo_EndBlock('Select tracks containing tag', -1)
                else
                    if not tag_selected then
                        reaper.Undo_BeginBlock()
                        selected_tag = tag
                        load_tag(tag)
                        reaper.Undo_EndBlock('Select tag', -1)
                    else
                        reaper.Undo_BeginBlock()
                        show_all_tracks()
                        selected_tag = nil
                        reaper.Undo_EndBlock('Unselect tag', -1)
                    end
                end
            end
            colored_frame(col)
            reaper.ImGui_PopStyleColor(ctx, 3)
            
            --RIGHT CLICK CONTEXT MENU
            reaper.ImGui_PushFont(ctx, font)
            reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding(), 4, 5)
            if reaper.ImGui_BeginPopupContextItem(ctx) then
                if reaper.ImGui_MenuItem(ctx, 'Rename') then
                    popup_dat = {tag = tag, name = tag.name}
                    open_rename_popup = true
                end
                if reaper.ImGui_MenuItem(ctx, 'Clear') then
                    reaper.Undo_BeginBlock()
                    clear_tag(tag)
                    reaper.Undo_EndBlock('Clear tag', -1)
                    if selected_tag and selected_tag.name == tag.name then selected_tag = nil end
                end
                if #tags > 1 then
                    if reaper.ImGui_BeginMenu(ctx, 'Merge') then
                        
                        for j = 1, #tags do
                            local t = tags[j]
                            if i ~= j then
                                if reaper.ImGui_MenuItem(ctx, t.name) then
                                    reaper.Undo_BeginBlock()
                                    merge_tag(tag, t)
                                    if settings.auto_load_tags_merge then
                                        load_tag(t)
                                        selected_tag = t
                                    end
                                    reaper.Undo_EndBlock('Merge tags', -1)
                                end
                            end
                        end
                        reaper.ImGui_EndMenu(ctx)
                    end
                end
                reaper.ImGui_EndPopup(ctx)
            end
            reaper.ImGui_PopStyleVar(ctx)
            reaper.ImGui_PopFont(ctx)
            reaper.ImGui_Separator(ctx)
        end
        reaper.ImGui_PopStyleColor(ctx)
        reaper.ImGui_EndListBox(ctx)
    end
    reaper.ImGui_PopFont(ctx)
    reaper.ImGui_PopStyleColor(ctx)

    --RENAME POPUP
    if open_rename_popup then
        reaper.ImGui_OpenPopup(ctx, 'Rename Tag')
    end
    reaper.ImGui_SetNextWindowSize(ctx, 248, 97, window_resize_flag)
    if reaper.ImGui_BeginPopupModal(ctx, 'Rename Tag', nil) then
        if reaper.ImGui_IsWindowAppearing(ctx) then
            reaper.ImGui_SetKeyboardFocusHere(ctx)
        end
        local r, s = reaper.ImGui_InputText(ctx, 'Name', popup_dat.name)
        if r then popup_dat.name = s end

        local disable, err = validate_tag_name(lookup, popup_dat.name)
        if err and popup_dat.name == popup_dat.tag.name then err = 'Enter a new name.' end
        if disable then
            reaper.ImGui_BeginDisabled(ctx)
        end

        local clear_popup = false
        if reaper.ImGui_Button(ctx, 'Ok') then
            if popup_dat.tag.name ~= popup_dat.name then
                reaper.Undo_BeginBlock()
                rename_tag(popup_dat.tag, popup_dat.name)
                reaper.Undo_EndBlock('Rename tag', -1)
            end
            clear_popup = true
            reaper.ImGui_CloseCurrentPopup(ctx)
        end
        if disable then
            reaper.ImGui_EndDisabled(ctx)
        end

        reaper.ImGui_SameLine(ctx)
        if reaper.ImGui_Button(ctx, 'Cancel') then
            clear_popup = true
            reaper.ImGui_CloseCurrentPopup(ctx)
        end
        if err then 
            reaper.ImGui_Text(ctx, err) 
        end
        if clear_popup then popup_dat = nil end
        reaper.ImGui_EndPopup(ctx)
    end
end

--Thank you cfillion!
function custom_close_button()
    local frame_padding_x, frame_padding_y = reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding())
    local min_x, min_y = reaper.ImGui_GetWindowPos(ctx)
    min_x, min_y = min_x + frame_padding_x, min_y + frame_padding_y
    local max_x = min_x + reaper.ImGui_GetWindowSize(ctx) - frame_padding_x * 2
    local max_y = min_y + reaper.ImGui_GetFontSize(ctx)
    reaper.ImGui_PushClipRect(ctx, min_x, min_y, max_x, max_y, false)
    local pos_x, pos_y = reaper.ImGui_GetCursorPos(ctx)
    reaper.ImGui_SetCursorScreenPos(ctx, max_x - 14, min_y)
    if reaper.ImGui_SmallButton(ctx, 'x') then open = false end
    reaper.ImGui_SetCursorPos(ctx, pos_x, pos_y)
    reaper.ImGui_PopClipRect(ctx)
end

function push_theme()
    reaper.ImGui_PushFont(ctx, font)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding(),     8, 5)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowTitleAlign(),  0.5, 0.5)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(),       3, 4)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ScrollbarRounding(), 0)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(),          0x2A2A2AF0)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_PopupBg(),           0x2A2A2AF0)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(),            0xFFFFFF80)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(),           0x4242428A)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBg(),           0x181818FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgActive(),     0x181818FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(),            0x1C1C1CFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(),     0x2C2C2CFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(),      0x3D3D3DFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderHovered(),     0x12BD994B)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderActive(),      0x12BD999E)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Separator(),         0xFFFFFF81)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGrip(),        0x12BD9933)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGripHovered(), 0x12BD99AB)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGripActive(),  0x12BD99F2)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TextSelectedBg(),    0x70C4C659)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Header(),            0x12BD9914)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_CheckMark(),         0x12BD99FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarBg(),          0x0D0D0D87)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrab(),        0xFFFFFF1C)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrabHovered(), 0xFFFFFF2E)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrabActive(),  0xFFFFFF32) 
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Separator(),            0xFFFFFF2D)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_SelectableTextAlign(), 0.5, 0)
end

function pop_theme()
    reaper.ImGui_PopStyleVar(ctx, 5)
    reaper.ImGui_PopStyleColor(ctx, 19)
    reaper.ImGui_PopStyleColor(ctx, 4)
    reaper.ImGui_PopFont(ctx)
end

local show_style_editor = false
if show_style_editor then 
    demo = dofile(reaper.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/ReaImGui_Demo.lua')
end

local dock = nil
function loop()    
    --GUI
    reaper.ImGui_PushFont(ctx, font)
    push_theme()
    if show_style_editor then
        demo.PushStyle(ctx)
        demo.ShowDemoWindow(ctx)
    end
    
    reaper.ImGui_SetNextWindowSize(ctx, 175, 349, reaper.ImGui_Cond_FirstUseEver())
    if dock then 
        reaper.ImGui_SetNextWindowDockID(ctx, dock)
        dock = nil 
    end
    visible, open = reaper.ImGui_Begin(ctx, 'Track Tags', false, reaper.ImGui_WindowFlags_NoCollapse())
    local window_is_docked = reaper.ImGui_IsWindowDocked(ctx)
    custom_close_button()
    local open_blacklist, open_settings = false, false
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
        if reaper.ImGui_MenuItem(ctx, 'Blacklist') then
            open_blacklist = true
        end
        reaper.ImGui_EndPopup(ctx)
    end
    reaper.ImGui_PopStyleVar(ctx)
    
    if open_blacklist then
        open_blacklist = false
        reaper.ImGui_OpenPopup(ctx, 'Global Blacklist')
    end
    if open_settings then
        open_settings = false
        reaper.ImGui_OpenPopup(ctx, 'Settings')
    end
    blacklist_menu()
    settings_menu()
    if visible then
        frame()
        reaper.ImGui_End(ctx)
    end
    
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

reaper.defer(loop)
