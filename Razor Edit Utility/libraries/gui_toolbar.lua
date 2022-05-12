-- @noindex

local toolbar_font_size = 22
local toolbar_font = reaper.ImGui_CreateFont('Courier New', toolbar_font_size,  reaper.ImGui_FontFlags_Bold() |  reaper.ImGui_FontFlags_Italic())
reaper.ImGui_AttachFont(ctx, toolbar_font)

function toolbar_frame(selected_button, adapt_to_window, window_is_docked)
  local save_settings = false
  
  local num_buttons = 5
  local draw_list = reaper.ImGui_GetWindowDrawList(ctx)
  local ww, wh = reaper.ImGui_GetWindowSize(ctx)
  local wx, wy = reaper.ImGui_GetWindowPos(ctx)
  local button_padding = 4
  local title_offset = 17
  if window_is_docked then title_offset = 0 end
  
  local bw = (ww - (button_padding * (num_buttons + 1))) /num_buttons
  
  local bh = math.min(40, wh - 17 - 8)
  if adapt_to_window then
    bh = wh - 17 - 8
  end
  
  local xp = button_padding
  reaper.ImGui_PushFont(ctx, toolbar_font)
  for i = 1, num_buttons do
    reaper.ImGui_PushID(ctx, i)
    local button_selected = selected_button == i
    
    local lxs, lys = xp, button_padding + title_offset
    local lxe, lye = xp + bw, button_padding + bh + title_offset

    local fxs = wx + lxs 
    local fys = wy + lys 
    local fxe = wx + lxe 
    local fye = wy + lye 
    
    --Rect
    local a = button_selected and 1 or 0.3
    local t = (i - 1)/(num_buttons)
    local col, col_p = imgui_palette(t + reaper.time_precise()/20, a)
    
    local rainbow_mode = true
    if not rainbow_mode then
      col = dl_rgba_to_col(0.3, 0.3, 0.3, 1)
      if button_selected then col = dl_rgba_to_col(0.8, 0.8, 0.8, 1) end
    end
    
    reaper.ImGui_DrawList_AddRect(draw_list, 
    fxs, fys, fxe, fye, col)
    
    --Hover
    reaper.ImGui_SetCursorPos(ctx, lxs, lys)
    reaper.ImGui_InvisibleButton(ctx, tostring(i), bw, bh)
    if reaper.ImGui_IsItemHovered(ctx) and not button_selected then
      local col = dl_rgba_to_col(col_p.r, col_p.g, col_p.b, 0.03)
      reaper.ImGui_DrawList_AddRectFilled(draw_list, 
      fxs, fys, fxe, fye, col)
    end
    if reaper.ImGui_IsItemClicked(ctx) then
      gm_write_selected_preset(i)
      save_settings = true
    end
    
    --Label
    local cx = (lxs + lxe)/2
    local cy = (lys + lye)/2
    
    local text = tostring(i)
    local tw = reaper.ImGui_CalcTextSize(ctx, text)
    reaper.ImGui_SetCursorPos(ctx, cx - tw/2, cy - toolbar_font_size/2)
    
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), col)
    reaper.ImGui_Text(ctx, text)
    reaper.ImGui_PopStyleColor(ctx)

    --Loop
    xp = xp + bw + button_padding
    reaper.ImGui_PopID(ctx)
  end
  reaper.ImGui_PopFont(ctx)
  reaper.ImGui_SetCursorPosY(ctx, button_padding + bh + title_offset + 6)
  return save_settings
end