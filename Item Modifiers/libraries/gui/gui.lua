-- @noindex

--INIT
ctx = reaper.ImGui_CreateContext(window_data.ctx, reaper.ImGui_ConfigFlags_DockingEnable())
local size = reaper.GetAppVersion():match('OSX') and 12 or 14
local font = reaper.ImGui_CreateFont('sans-serif', size)
local small_size = math.floor(size*0.8)
local big_size = math.floor(size*3)
local small_font = reaper.ImGui_CreateFont('sans-serif', small_size)
local big_font = reaper.ImGui_CreateFont('Courier New', big_size, reaper.ImGui_FontFlags_Italic())
local listbox_offs = 29

reaper.ImGui_AttachFont(ctx, font)
reaper.ImGui_AttachFont(ctx, small_font)
reaper.ImGui_AttachFont(ctx, big_font)

FLT_MIN, FLT_MAX = reaper.ImGui_NumericLimits_Float()

function get_font_data()
  return {size = size, small_size = small_size}
end

function get_listbox_size(num_elements)
  if settings.use_full_height_versions then
    return listbox_offs*-1
  else
    local sel_size = size + 4
    local w, h = reaper.ImGui_GetWindowSize(ctx)
    local y = reaper.ImGui_GetCursorPosY(ctx)
    local max_size = h - y - 35
    local r_size = (num_elements * sel_size) + 2 
    local lim = (10 * sel_size) + 2
    if max_size > lim then
        r_size = lim
    else
        r_size = max_size
    end
    return r_size
  end
end

function custom_separator(y_offs)
  local w = get_window()
  local cx, cy = get_cur()
  cy = cy + y_offs
  local draw_list = reaper.ImGui_GetWindowDrawList(ctx)
  reaper.ImGui_DrawList_AddLine( draw_list,
  cx + w.x, cy + w.y,
  cx + w.w + w.x, cy + w.y, 0x14296FAFF, 2)
end

function push_listbox_theme()
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(), 0x42424200)
end

function pop_listbox_theme()
  reaper.ImGui_PopStyleColor(ctx)
end

function colored_frame(col)
  local draw_list = reaper.ImGui_GetWindowDrawList(ctx)
  local text_min_x, text_min_y = reaper.ImGui_GetItemRectMin(ctx)
  local text_max_x, text_max_y = reaper.ImGui_GetItemRectMax(ctx)
  reaper.ImGui_DrawList_AddRect(draw_list, text_min_x, text_min_y, text_max_x, text_max_y, col)
end

function draw_offset_frame(col, label, offs)
  local label = label and label or ''
  local text_w = reaper.ImGui_CalcTextSize(ctx, label)
  local draw_list = reaper.ImGui_GetWindowDrawList(ctx)
  local text_min_x, text_min_y = reaper.ImGui_GetItemRectMin(ctx)
  local text_max_x, text_max_y = reaper.ImGui_GetItemRectMax(ctx)
  reaper.ImGui_DrawList_AddRect(draw_list, text_min_x, text_min_y, text_max_x - text_w - 4, text_max_y, col)
end

function draw_offset_frame_checkbox(col)
  local draw_list = reaper.ImGui_GetWindowDrawList(ctx)
  local text_min_x, text_min_y = reaper.ImGui_GetItemRectMin(ctx)
  local text_max_x, text_max_y = reaper.ImGui_GetItemRectMax(ctx)
  reaper.ImGui_DrawList_AddRect(draw_list, 
  text_min_x, text_min_y,
  text_max_x, text_max_y, col)
end

function push_mod_stack_theme()
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(),          0x3333338A)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgHovered(),   0x39393966)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgActive(),    0x4B4B4B6E)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_GrabMinSize(), 20)
end

function pop_mod_stack_theme()
  reaper.ImGui_PopStyleColor(ctx, 3)
  reaper.ImGui_PopStyleVar(ctx)
end

function push_big_font()
  reaper.ImGui_PushFont(ctx, big_font)
end

function pop_big_font()
  reaper.ImGui_PopFont(ctx)
end

function push_builder_theme()
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding(), 5, 5)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(), 0xFFFFFF4E)
end

function pop_builder_theme()
  reaper.ImGui_PopStyleVar(ctx)
  reaper.ImGui_PopStyleColor(ctx)
end

function get_window()
  local w, h = reaper.ImGui_GetWindowSize(ctx)
  local x, y = reaper.ImGui_GetWindowPos(ctx)
  local pd_x, pd_y = reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding())
  return {w = w, h = h, x = x, y = y, pd_x = pd_x, pd_y = pd_y}
end

function get_cur()
  local x = reaper.ImGui_GetCursorPosX(ctx)
  local y = reaper.ImGui_GetCursorPosY(ctx)
  return x, y
end

function top_frame()
    local ww = reaper.ImGui_GetWindowSize(ctx)
    local wx, wy = reaper.ImGui_GetWindowPos(ctx)
    local draw_list = reaper.ImGui_GetWindowDrawList(ctx)
    reaper.ImGui_DrawList_AddRectFilled(draw_list, wx, wy, ww + wx, wy + 20, 0x181818FF)
    
    local text = 'Item Modifiers'
    local text_w = reaper.ImGui_CalcTextSize(ctx, text)
    local x = reaper.ImGui_GetCursorPosX(ctx)
    local y = reaper.ImGui_GetCursorPosY(ctx)
    reaper.ImGui_SetCursorPosX(ctx, (ww - text_w) * 0.5)
    reaper.ImGui_SetCursorPosY(ctx, y - 3)
    reaper.ImGui_Text(ctx, text)
    reaper.ImGui_Separator(ctx)
end

function get_ctrl()
  local key_mods = reaper.ImGui_GetKeyMods(ctx)
  local mod = reaper.ImGui_KeyModFlags_Ctrl and reaper.ImGui_KeyModFlags_Ctrl() or reaper.ImGui_ModFlags_Ctrl()
  return (key_mods & mod) ~= 0 
end

function get_shift()
  local key_mods = reaper.ImGui_GetKeyMods(ctx)
  local mod = reaper.ImGui_KeyModFlags_Shift and reaper.ImGui_KeyModFlags_Shift() or reaper.ImGui_ModFlags_Shift()
  return (key_mods & mod) ~= 0 
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
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBg(),       0x1E1E1EFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgActive(), 0x1E1E1EFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(),        0x1B1B1BFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0x272727FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(),      0x3D3D3DFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Header(), 0x12BD992B)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderHovered(),     0x12BD994B)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderActive(),      0x12BD999E)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Separator(), 0xFFFFFF20)  
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGrip(),        0x12BD9933)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGripHovered(), 0x12BD99AB)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGripActive(),  0x12BD99F2)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TextSelectedBg(),    0x70C4C659)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_CheckMark(),         0x12BD99FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarBg(), 0x1C1C1C87)   
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrab(),        0xFFFFFF1C)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrabHovered(), 0xFFFFFF2E)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrabActive(),  0xFFFFFF32)   
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgHovered(),   0x6F6F6F66)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgActive(),    0x8787876E)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SliderGrab(),       0xE8367DFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SliderGrabActive(), 0xE8367DFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_DragDropTarget(), 0xFFFF0000)
   
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_GrabMinSize(), 17)
end

function pop_theme()
    reaper.ImGui_PopStyleVar(ctx, 5)
    reaper.ImGui_PopStyleColor(ctx, 23)
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

function centered_text(text)
  local ww = reaper.ImGui_GetWindowSize(ctx)
  local text_w = reaper.ImGui_CalcTextSize(ctx, text)
  local x = reaper.ImGui_GetCursorPosX(ctx)
  reaper.ImGui_SetCursorPosX(ctx, (ww - text_w) * 0.5)
  reaper.ImGui_Text(ctx, text)
end