-- @noindex

--INIT
ctx = reaper.ImGui_CreateContext(window_data.ctx, reaper.ImGui_ConfigFlags_DockingEnable())
local size = 14
local font = reaper.ImGui_CreateFont('sans-serif', size)
local small_size = math.floor(size*0.8)
local big_size = math.floor(size*3)
local small_font = reaper.ImGui_CreateFont('sans-serif', 12)
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

--https://iquilezles.org/www/articles/palettes/palettes.htm
function palette(t)
  local a = {r = 0.5, g = 0.5, b = 0.5}
  local b = {r = 0.5, g = 0.5, b = 0.5}
  local c = {r = 1, g = 1, b = 1}
  local d = {r = 0, g = 0.33, b = 0.67}

  local brightness = 0
  
  local col = {}
  col.r = math.min(a.r + brightness + math.cos((c.r*t + d.r)*6.28318)*b.r,1)
  col.g = math.min(a.g + brightness + math.cos((c.g*t + d.g)*6.28318)*b.g,1)
  col.b = math.min(a.b + brightness + math.cos((c.b*t + d.b)*6.28318)*b.b,1)
  return col
end

function dl_rgba_to_col(r, g, b, a)
  local b = math.floor(b * 255) * 256
  local g = math.floor(g * 255) * 256 * 256
  local r = math.floor(r * 255) * 256 * 256 * 256
  local a = math.floor(a * 255)
  return r + g + b + a
end

function get_random_circles(num_circles, max_rad)
  local c = {}
  for i = 1, num_circles do
    local rad = math.max(2, math.random(max_rad))
    local pos = math.random() --> 0.5 and math.random()^16 or math.random()^(1/16)
    local phase = math.random() * math.pi * 2
    local cr = palette(math.random())
    local speed = math.max(0.2, math.random()/1.2)
    local color = dl_rgba_to_col(cr.r, cr.g, cr.b, 0.8)
    local filled = math.random() > 0.8
    table.insert(c, {
      rad = rad, 
      pos = pos, 
      phase = phase, 
      color = color, 
      speed = speed, 
      filled = filled})
  end
  return c
end

function title(text, disp_circles)
  if reaper.ImGui_BeginChild(ctx, "Title", -FLT_MIN, 58, false) then
    local x, y = reaper.ImGui_GetWindowPos(ctx)
    local w, h = reaper.ImGui_GetWindowSize(ctx)
    local draw_list = reaper.ImGui_GetWindowDrawList(ctx)
    for i = 1, #disp_circles do
      local c = disp_circles[i]
      local ny = 0.5 + math.sin(c.phase + reaper.time_precise()*c.speed*0.3)/2
      local ry = y + ny*(h+2.3*c.rad) - c.rad
      local rx = x + w*c.pos
      if not c.filled then
      reaper.ImGui_DrawList_AddCircle( 
        draw_list, 
        rx, 
        ry, 
        c.rad, 
        c.color, 0, 1)
      else
        reaper.ImGui_DrawList_AddCircleFilled( 
          draw_list, 
          rx, 
          ry, 
          c.rad, 
          c.color)
      end
    end
    offset_cursor_y(6)
    push_big_font()
    centered_text(text)
    pop_big_font()
    reaper.ImGui_EndChild(ctx)
  end
end

--Thank you Sexan!
function custom_knob(label, radius_outer, p_value, v_min, v_max)
  local pos = { reaper.ImGui_GetCursorScreenPos(ctx) }
  local center = { pos[1] + radius_outer, pos[2] + radius_outer }
  local line_height = reaper.ImGui_GetTextLineHeight(ctx)
  local draw_list = reaper.ImGui_GetWindowDrawList(ctx)
  local item_inner_spacing = { reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_ItemInnerSpacing()) }
  local mouse_delta = { reaper.ImGui_GetMouseDelta(ctx) }

  local ANGLE_MIN = 3.141592 * 0.75
  local ANGLE_MAX = 3.141592 * 2.25

  reaper.ImGui_InvisibleButton(ctx, label, radius_outer * 2, radius_outer * 2 + line_height + item_inner_spacing[2])
  local value_changed = false
  local is_active = reaper.ImGui_IsItemActive(ctx)
  local is_hovered = reaper.ImGui_IsItemHovered(ctx)
  if is_active and (mouse_delta[2] ~= 0.0 or mouse_delta[1] ~= 0.0) then
      local step = (v_max - v_min) / 300
      p_value = p_value - (mouse_delta[2] * step - mouse_delta[1] * step)
      if p_value < v_min then p_value = v_min end
      if p_value > v_max then p_value = v_max end
      value_changed = true
  end

  local t = (p_value - v_min) / (v_max - v_min)
  local angle = ANGLE_MIN + (ANGLE_MAX - ANGLE_MIN) * t
  local angle_cos, angle_sin = math.cos(angle), math.sin(angle)
  local radius_inner = radius_outer * 0.40
  reaper.ImGui_DrawList_AddCircleFilled(draw_list, center[1], center[2], radius_outer, reaper.ImGui_GetColor(ctx, reaper.ImGui_Col_FrameBg()), 16)
  reaper.ImGui_DrawList_AddLine(draw_list, center[1] + angle_cos * radius_inner, center[2] + angle_sin * radius_inner, center[1] + angle_cos * (radius_outer - 2), center[2] + angle_sin * (radius_outer - 2), reaper.ImGui_GetColor(ctx, reaper.ImGui_Col_SliderGrabActive()), 2.0)
  reaper.ImGui_DrawList_AddCircleFilled(draw_list, center[1], center[2], radius_inner, reaper.ImGui_GetColor(ctx, is_active and reaper.ImGui_Col_FrameBgActive() or is_hovered and reaper.ImGui_Col_FrameBgHovered() or reaper.ImGui_Col_FrameBg()), 16)
  local txt_size = reaper.ImGui_CalcTextSize(ctx, label)
  reaper.ImGui_DrawList_AddText(draw_list, pos[1] + radius_outer - txt_size/2, pos[2] + radius_outer * 2 + item_inner_spacing[2], reaper.ImGui_GetColor(ctx, reaper.ImGui_Col_Text()), label)

  if is_active or is_hovered then
      local tooltip_txt = ('%.2f'):format(p_value)
      local txt_size = reaper.ImGui_CalcTextSize(ctx, tooltip_txt)
      local window_padding = { reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding()) }
      reaper.ImGui_SetNextWindowPos(ctx, pos[1] - window_padding[1] + radius_outer - txt_size/2, pos[2] - line_height - item_inner_spacing[2] - window_padding[2] + 82)
      reaper.ImGui_BeginTooltip(ctx)
      reaper.ImGui_Text(ctx, tooltip_txt)
      reaper.ImGui_EndTooltip(ctx)
  end

  return value_changed, p_value
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
    
    local text = 'FX Mangler'
    local text_w = reaper.ImGui_CalcTextSize(ctx, text)
    local x = reaper.ImGui_GetCursorPosX(ctx)
    local y = reaper.ImGui_GetCursorPosY(ctx)
    reaper.ImGui_SetCursorPosX(ctx, (ww - text_w) * 0.5)
    reaper.ImGui_SetCursorPosY(ctx, y - 3)
    reaper.ImGui_Text(ctx, text)
    reaper.ImGui_Separator(ctx)
end

function right_align_padding(offs)
    local w, h = reaper.ImGui_GetWindowSize(ctx)
    local pd_x, pd_y = reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding())
    reaper.ImGui_SameLine(ctx, w - 2*pd_x - offs)
end

function push_small_font()
    reaper.ImGui_PushFont(ctx, small_font)
end

function pop_small_font()
  reaper.ImGui_PopFont(ctx)
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
    --reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(),           0x4242428A)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(), 0x3C3C3C8A)

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

    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Tab(),        0x3B3B3BDC)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabHovered(), 0xAB2A42DC)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabActive(),  0xAB2A42DC)


    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_TabRounding(), 2)  
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_GrabMinSize(), 17)
end

function pop_theme()
    reaper.ImGui_PopStyleVar(ctx, 6)
    reaper.ImGui_PopStyleColor(ctx, 30)
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

function offset_cursor_y(offset)
  local pos_x, pos_y = reaper.ImGui_GetCursorPos(ctx)
  reaper.ImGui_SetCursorPos(ctx, pos_x, pos_y + offset)
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

function get_alt()
  local key_mods = reaper.ImGui_GetKeyMods(ctx)
  local mod = reaper.ImGui_KeyModFlags_Alt and reaper.ImGui_KeyModFlags_Alt() or reaper.ImGui_ModFlags_Alt()
  return (key_mods & mod) ~= 0 
end