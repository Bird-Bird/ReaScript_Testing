-- @noindex

function push_theme(settings)
  local theme = settings.selected_theme
  if theme == 1 then
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0xDDE3FFFF)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding(),     8, 5)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowTitleAlign(),  0.5, 0.5)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(),       3, 4)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ScrollbarRounding(), 0)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(),             0x1E1A25F0)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_PopupBg(),              0x2A2A2AF0)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(),               0xFFFFFF80)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(),              0x5135548A)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBg(),              0x181818FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgActive(),        0x181818FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(),               0x42213DFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(),        0x64375DFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(),         0x87547FFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderHovered(),        0xBD12844B)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderActive(),         0xBD128487)  
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Separator(),            0xFFFFFF81)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGrip(),           0x12BD9933)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGripHovered(),    0x12BD99AB)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGripActive(),     0x12BD99F2)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TextSelectedBg(),       0x70C4C659)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_CheckMark(),            0x12BD99FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarBg(),          0x16121BF0)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrab(),        0xFFD7EC11)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrabHovered(), 0xFFFFFF19)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrabActive(),  0xFFFFFF32)    
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Header(),               0x12BD9959)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Tab(),                  0x3E2E3BFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabHovered(),           0x54344DFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabActive(),            0x553E50FF)
  elseif theme == 2 then
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0xDDE3FFFF)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding(),     8, 5)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowTitleAlign(),  0.5, 0.5)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(),       3, 4)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ScrollbarRounding(), 0)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_PopupBg(),              0x2A2A2AF0)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(),               0xFFFFFF80)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBg(),              0x181818FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgActive(),        0x181818FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Separator(),            0xFFFFFF81)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGrip(),           0x12BD9933)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGripHovered(),    0x12BD99AB)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGripActive(),     0x12BD99F2)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TextSelectedBg(),       0x70C4C659)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_CheckMark(),            0x12BD99FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarBg(),          0x16121BF0)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrab(),        0xFFD7EC11)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrabHovered(), 0xFFFFFF19)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrabActive(),  0xFFFFFF32)    
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Header(),               0x12BD9959)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(),      0x282828F0)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(),       0x4848548A)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(),        0x101010FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0x343434FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(),  0x414141FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderHovered(), 0x126CBD4B)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderActive(),  0x126CBDD0)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Tab(),           0x216A9B49)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabHovered(),    0x216A9BFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabActive(),     0x216A9BFF)
  elseif theme == 3 then
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding(),     8, 5)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowTitleAlign(),  0.5, 0.5)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(),       3, 4)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ScrollbarRounding(), 0)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_PopupBg(),              0x2A2A2AF0)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(),               0xFFFFFF80)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Separator(),            0xFFFFFF81)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGrip(),           0x12BD9933)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGripHovered(),    0x12BD99AB)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGripActive(),     0x12BD99F2)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TextSelectedBg(),       0x70C4C659)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_CheckMark(),            0x12BD99FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarBg(),          0x16121BF0)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrab(),        0xFFD7EC11)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrabHovered(), 0xFFFFFF19)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrabActive(),  0xFFFFFF32)    
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Header(),               0x12BD9959)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(),        0x42213D16)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0x42213D2F)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(),  0x42213D4F)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Tab(),           0xE6E6E6FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(),             0x2C2929FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(),         0xFCFCF1FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(),          0x51355428)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBg(),          0xFCFCF1FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgActive(),    0xFCFCF1FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderHovered(),    0x12A2BD27)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderActive(),     0x12A2BD53)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabHovered(),       0xB7B7B7A7)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabActive(),        0xB7B7B7A7)  
  end
end

function pop_theme()
  reaper.ImGui_PopStyleVar(ctx, 4)
  reaper.ImGui_PopStyleColor(ctx, 26)
end

function dl_rgba_to_col(r, g, b, a)
  local b = math.floor(b * 255) * 256
  local g = math.floor(g * 255) * 256 * 256
  local r = math.floor(r * 255) * 256 * 256 * 256
  local a = math.floor(a * 255)
  return r + g + b + a
end

function palette(t)
  local a = {r = 0.5, g = 0.5, b = 0.5}
  local b = {r = 0.5, g = 0.5, b = 0.5}
  local c = {r = 1, g = 1, b = 1}
  local d = {r = 0, g = 0.33, b = 0.67}

  local brightness = 0.1
  
  local col = {}
  col.r = math.min(a.r + brightness + math.cos((c.r*t + d.r)*6.28318)*b.r,1)
  col.g = math.min(a.g + brightness + math.cos((c.g*t + d.g)*6.28318)*b.g,1)
  col.b = math.min(a.b + brightness + math.cos((c.b*t + d.b)*6.28318)*b.b,1)
  return col
end

function imgui_palette(t, a)
  local c = palette(t)
  return dl_rgba_to_col(c.r, c.g, c.b, a), c
end

local col_t = 0.8 + 1/15
function get_display_color()
  local col = imgui_palette(col_t, 1)
  col_t = col_t + 1/15
  return col
end

function centered_text(text)
  local ww = reaper.ImGui_GetWindowSize(ctx)
  local text_w = reaper.ImGui_CalcTextSize(ctx, text)
  local x = reaper.ImGui_GetCursorPosX(ctx)
  reaper.ImGui_SetCursorPosX(ctx, (ww - text_w) * 0.5)
  reaper.ImGui_Text(ctx, text)
end

function track_display(p_dat)
  local cx, cy    = reaper.ImGui_GetCursorPos(ctx)
  local wx, wy    = reaper.ImGui_GetWindowPos(ctx)
  local ww, wh    = reaper.ImGui_GetContentRegionMax(ctx)
  local draw_list = reaper.ImGui_GetWindowDrawList(ctx)
  local pdx, pdy  = reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding())  
  local frame_col = reaper.ImGui_GetStyleColor(ctx, reaper.ImGui_Col_FrameBg())
  local scroll    = reaper.ImGui_GetScrollY(ctx)

  local sx, sy = cx + wx + 6, cy + wy + 6 - scroll 
  
  local r, g, b = reaper.ColorFromNative(p_dat.track_color)
  local f_col = dl_rgba_to_col(r/255, g/255, b/255, 1)

  reaper.ImGui_DrawList_AddCircleFilled(draw_list, sx, sy, 6, f_col)

  reaper.ImGui_SetCursorPosX(ctx, cx + 12 + 3)
  reaper.ImGui_Text(ctx, "Track " .. p_dat.track_id .. ": " .. p_dat.track_name)
end

local FLT_MIN, FLT_MAX = reaper.ImGui_NumericLimits_Float()
function custom_slider_double(ctx, label, v, min, max, color)
  local rv, val = false, nil
  
  local t = (v - min)/(max - min)
  local cx, cy    = reaper.ImGui_GetCursorPos(ctx)
  local wx, wy    = reaper.ImGui_GetWindowPos(ctx)
  local ww, wh    = reaper.ImGui_GetContentRegionMax(ctx)
  local draw_list = reaper.ImGui_GetWindowDrawList(ctx)
  local pdx, pdy  = reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding())  
  local frame_col = reaper.ImGui_GetStyleColor(ctx, reaper.ImGui_Col_FrameBg())
  local scroll    = reaper.ImGui_GetScrollY(ctx)

  local sx, sy = cx + wx, cy + wy - scroll
  local w_full, h = ww - pdx, settings.slider_height

  local button = reaper.ImGui_InvisibleButton(ctx, label, w_full, h)
  if reaper.ImGui_IsItemActive(ctx) then
    local mx, my = reaper.GetMousePosition()
    mx, my = reaper.ImGui_PointConvertNative(ctx, mx, my)
    t = (mx - sx)/w_full
    if t < 0 then t = 0 end
    if t > 1 then t = 1 end
    rv, val = true, min + (max - min)*t
  end
  local w = w_full * t
  
  reaper.ImGui_DrawList_AddRectFilled(draw_list, sx, sy, sx + w_full, sy + h, frame_col)
  reaper.ImGui_DrawList_AddRectFilled(draw_list, sx, sy, sx + w, sy + h, color)
  reaper.ImGui_DrawList_AddLine(draw_list, sx, sy + h + 5, sx + w_full, sy + h + 5, 0xFFFFFF81)
  
  reaper.ImGui_SetCursorPosY(ctx, cy + h + 10)

  return rv, val
end

function get_alt()
  local key_mods = reaper.ImGui_GetKeyMods(ctx)
  local mod = reaper.ImGui_KeyModFlags_Alt and reaper.ImGui_KeyModFlags_Alt() or reaper.ImGui_ModFlags_Alt()
  return (key_mods & mod) ~= 0 
end