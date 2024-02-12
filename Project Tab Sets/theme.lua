-- @noindex

local font_size = 16
local text_font

function load_resources(ctx)
  local info = debug.getinfo(1,'S')
  local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
  text_font = reaper.ImGui_CreateFont(script_path .. "/resources/JetBrainsMono-Medium.ttf", font_size)
  reaper.ImGui_Attach(ctx, text_font)
end

function push_theme(ctx)
  reaper.ImGui_PushFont(ctx, text_font)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(),   15, 8)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(),   8, 8)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowTitleAlign(), 0.5, 0.5)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameBorderSize(), 1)

  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(),             0x231B55FF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(),         0xF5DDC4FF)--0xF5D3B3FF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_PopupBg(),          0xF0F0F0F0)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBg(),          0x3D2764FF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgActive(),    0x3D2764FF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgCollapsed(), 0x3D2764FF)

  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(),            0xA96BE27E)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(),     0xBC6BE2E0)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(),      0x8747A4FF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Header(),            0xBC6BE255)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderHovered(),     0xBC6BE2BB)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderActive(),      0x8747A4FF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGrip(),        0xBC6BE27E)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGripHovered(), 0xBC6BE28E)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGripActive(),  0x8747A4FF)

  reaper.ImGui_PushStyleVar(ctx,   reaper.ImGui_StyleVar_ScrollbarSize(),     18)
  reaper.ImGui_PushStyleVar(ctx,   reaper.ImGui_StyleVar_ScrollbarRounding(), 0)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarBg(),          0x3D27643A)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrab(),        0x3D2764A1)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrabHovered(), 0x3D2764A1)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrabActive(),  0x633DA6A1)

  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(), 0x6E6E801D)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_DragDropTarget(), 0xFFFF0000)
end

function pop_theme(ctx)
  reaper.ImGui_PopFont(ctx)
  reaper.ImGui_PopStyleVar(ctx,   6)
  reaper.ImGui_PopStyleColor(ctx, 21) 
end

function get_button_height(ctx)
  local pad_w, pad_h = reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding())
  local item_spacing_w, item_spacing_h = reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding())
  local button_height = font_size + pad_h*2
  return button_height, button_height + item_spacing_h
end

function get_selectable_height(ctx)
  local item_spacing_w, item_spacing_h = reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing())
  return font_size + item_spacing_h
end

function draw_custom_separator(ctx)
  local window_w, window_h = reaper.ImGui_GetWindowSize(ctx)
  local window_x, window_y = reaper.ImGui_GetWindowPos(ctx)
  local cursor_x = reaper.ImGui_GetCursorPosX(ctx)
  local cursor_y = reaper.ImGui_GetCursorPosY(ctx)
  local pad_w, pad_h = reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding())
  local item_spacing_w, item_spacing_h = reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding())
  local color = reaper.ImGui_GetColor(ctx, reaper.ImGui_Col_TitleBg(), 0.05)
  local draw_list =  reaper.ImGui_GetWindowDrawList(ctx)
  local x, y =  window_x + cursor_x, window_y + cursor_y - item_spacing_h - 1 --tfw
  reaper.ImGui_DrawList_AddLine(draw_list, x, y, x + window_w - 2*pad_w, y, color, 1)
end

function draw_upwards_grad_rect(ctx, height)
  local window_w, window_h = reaper.ImGui_GetWindowSize(ctx)
  local window_x, window_y = reaper.ImGui_GetWindowPos(ctx)
  local cursor_x = reaper.ImGui_GetCursorPosX(ctx)
  local cursor_y = reaper.ImGui_GetCursorPosY(ctx)
  local pad_w, pad_h = reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding())
  local item_spacing_w, item_spacing_h = reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding())
  local draw_list =  reaper.ImGui_GetWindowDrawList(ctx)
  local color = reaper.ImGui_GetColor(ctx, reaper.ImGui_Col_TitleBg(), 0.1)
  local zero  = 0x00000000
  local x, y = window_x + cursor_x, window_y + cursor_y - height - item_spacing_h
  reaper.ImGui_DrawList_AddRectFilledMultiColor(draw_list, x, y, x + window_w - 2*pad_w, y + height, zero, zero, color, color)
end

function draw_drag_highlight(ctx, y_offset, alpha)
  local window_w, window_h = reaper.ImGui_GetWindowSize(ctx)
  local window_x, window_y = reaper.ImGui_GetWindowPos(ctx)
  local cursor_x = reaper.ImGui_GetCursorPosX(ctx)
  local cursor_y = reaper.ImGui_GetCursorPosY(ctx)
  local pad_w, pad_h = reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding())
  local item_spacing_w, item_spacing_h = reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding())
  local color = reaper.ImGui_GetColor(ctx, reaper.ImGui_Col_TitleBg(), alpha)
  local draw_list =  reaper.ImGui_GetWindowDrawList(ctx)
  local x, y =  window_x + cursor_x, window_y + cursor_y - item_spacing_h - 1 + y_offset
  reaper.ImGui_DrawList_AddLine(draw_list, x, y, x + window_w - 2*pad_w, y, color, 1)
end

function draw_drag_grad_rect(ctx, height, alpha, flip)
  if flip == nil then
    flip = false
  end
  local window_w, window_h = reaper.ImGui_GetWindowSize(ctx)
  local window_x, window_y = reaper.ImGui_GetWindowPos(ctx)
  local cursor_x = reaper.ImGui_GetCursorPosX(ctx)
  local cursor_y = reaper.ImGui_GetCursorPosY(ctx)
  local pad_w, pad_h = reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding())
  local item_spacing_w, item_spacing_h = reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding())
  local draw_list =  reaper.ImGui_GetWindowDrawList(ctx)
  local zero  = 0x00000000
  local color = reaper.ImGui_GetColor(ctx, reaper.ImGui_Col_TitleBg(), alpha)
  local color_1 = flip and color or zero
  local color_2 = flip and zero  or color
  local x, y = window_x + cursor_x, window_y + cursor_y - height - item_spacing_h
  reaper.ImGui_DrawList_AddRectFilledMultiColor(draw_list, x, y, x + window_w - 2*pad_w, y + height, color_1, color_1, color_2, color_2)
end