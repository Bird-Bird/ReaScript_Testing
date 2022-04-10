--@noindex

--INIT
ctx = reaper.ImGui_CreateContext('Track Versions', reaper.ImGui_ConfigFlags_DockingEnable())
local size = reaper.GetAppVersion():match('OSX') and 12 or 14
local font = reaper.ImGui_CreateFont('sans-serif', size)
local small_size = math.floor(size*0.8)
local small_font = reaper.ImGui_CreateFont('sans-serif', small_size)

reaper.ImGui_AttachFont(ctx, font)
reaper.ImGui_AttachFont(ctx, small_font)

function get_ctrl()
    local key_mods = reaper.ImGui_GetKeyMods(ctx)
    local ctrl = reaper.ImGui_KeyModFlags_Ctrl()
    return key_mods & ctrl > 0 
end

function get_shift()
    local key_mods = reaper.ImGui_GetKeyMods(ctx)
    local shift = reaper.ImGui_KeyModFlags_Shift()
    return key_mods & shift > 0 
end

function right_align_padding(offs)
    local w, h = reaper.ImGui_GetWindowSize(ctx)
    local pd_x, pd_y = reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding())
    reaper.ImGui_SameLine(ctx, w - 2*pd_x - offs)
end

function push_small_font()
    reaper.ImGui_PushFont(ctx, small_font)
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
    
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Header(), 0x12BD992B)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderHovered(),     0x12BD994B)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderActive(),      0x12BD999E)

    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Separator(),         0xFFFFFF81)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGrip(),        0x12BD9933)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGripHovered(), 0x12BD99AB)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGripActive(),  0x12BD99F2)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TextSelectedBg(),    0x70C4C659)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_CheckMark(),         0x12BD99FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarBg(),          0x0D0D0D87)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrab(),        0xFFFFFF1C)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrabHovered(), 0xFFFFFF2E)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrabActive(),  0xFFFFFF32)    
end

function pop_theme()
    reaper.ImGui_PopStyleVar(ctx, 4)
    reaper.ImGui_PopStyleColor(ctx, 18)
    reaper.ImGui_PopStyleColor(ctx, 4)
    reaper.ImGui_PopFont(ctx)
end

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

function reset_scroll()
    local sx = reaper.ImGui_GetScrollX( ctx )
    if sx > 0 then reaper.ImGui_SetScrollX(ctx, 0) end
end