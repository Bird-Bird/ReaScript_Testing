-- @noindex

function push_theme()
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding(),     8, 5)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowTitleAlign(),  0.5, 0.5)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(),       3, 4)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ScrollbarRounding(), 0)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(),          0x2A2A2AFF)
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
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_CheckMark(),         0x12BD99FF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarBg(),          0x0D0D0D87)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrab(),        0xFFFFFF1C)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrabHovered(), 0xFFFFFF2E)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrabActive(),  0xFFFFFF32)    
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Header(),               0x12BD9959)
end

function pop_theme()
  reaper.ImGui_PopStyleVar(ctx, 4)
  reaper.ImGui_PopStyleColor(ctx, 18)
  reaper.ImGui_PopStyleColor(ctx, 4)
end

function tooltip_at_mouse(text)
  local mx, my = reaper.GetMousePosition()
  mx, my = reaper.ImGui_PointConvertNative(ctx, mx, my)
  reaper.ImGui_SetNextWindowPos(ctx, mx + 13, my + 10, reaper.ImGui_Cond_Always())
  reaper.ImGui_BeginTooltip(ctx)
  reaper.ImGui_Text(ctx, text)
  reaper.ImGui_EndTooltip(ctx)
end

function centered_text(text)
  local ww = reaper.ImGui_GetWindowSize(ctx)
  local text_w = reaper.ImGui_CalcTextSize(ctx, text)
  local x = reaper.ImGui_GetCursorPosX(ctx)
  reaper.ImGui_SetCursorPosX(ctx, (ww - text_w) * 0.5)
  reaper.ImGui_Text(ctx, text)
end

function dl_rgba_to_col(r, g, b, a)
  local b = math.floor(b * 255) * 256
  local g = math.floor(g * 255) * 256 * 256
  local r = math.floor(r * 255) * 256 * 256 * 256
  local a = math.floor(a * 255)
  return r + g + b + a
end

--https://iquilezles.org/www/articles/palettes/palettes.htm
function palette(t)
  local a = {r = 0.5, g = 0.5, b = 0.5}
  local b = {r = 0.5, g = 0.5, b = 0.5}
  local c = {r = 1, g = 1, b = 1}
  local d = {r = 0, g = 0.33, b = 0.67}

  local brightness = 0.3
  
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

function custom_separator(y_offs)
  local draw_list = reaper.ImGui_GetWindowDrawList(ctx)
  local ww, wh = reaper.ImGui_GetWindowSize(ctx)
  local wx, wy = reaper.ImGui_GetWindowPos(ctx)
  local cx, cy = reaper.ImGui_GetCursorPos(ctx)
  cy = cy + y_offs
  reaper.ImGui_DrawList_AddLine( draw_list,
  cx + wx, cy + wy,
  cx + ww + wx, cy + wy, 0x14296FAFF, 2)
end
