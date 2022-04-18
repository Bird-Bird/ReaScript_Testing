-- @noindex

dl_color = 0xFAFAFAFF
function dl_rgba_to_col(r, g, b, a)
    local b = math.floor(b * 255) * 256
    local g = math.floor(g * 255) * 256 * 256
    local r = math.floor(r * 255) * 256 * 256 * 256
    local a = math.floor(a * 255)
    return r + g + b + a
end

function dl_set_color(r, g, b, a)
  dl_color = dl_rgba_to_col(r, g, b, a)
end

local dl_padding_x = 10
local dl_padding_y = 10
local dl_titlebar_offset = 21
function dl_get_window(ignore_titlebar)
  local titlebar_offset = ignore_titlebar and 0 or dl_titlebar_offset
  local w, h = reaper.ImGui_GetWindowSize(ctx)
  local x, y = reaper.ImGui_GetWindowPos(ctx)
  return {
    w = w - 2*dl_padding_x,
    h = h - 2*dl_padding_y - titlebar_offset,
    x = x + dl_padding_x,
    y = y + dl_padding_y + titlebar_offset
  }
end

function dl_get_cursor()
  local cx, cy = reaper.ImGui_GetCursorPos(ctx)
  return cx, cy
end

function dl_set_padding(x, y, titlebar_offset)
  dl_padding_x = x
  dl_padding_y = y
  if titlebar_offset then dl_titlebar_offset = titlebar_offset end
end

function dl_circle(x, y, r, segments, thickness)
  local segments, thickness = segments or 0, thickness or 1
  local w = dl_get_window()
  local draw_list = reaper.ImGui_GetWindowDrawList(ctx)
  reaper.ImGui_DrawList_AddCircle(draw_list, x + w.x, y + w.y, r, dl_color, segments, thickness)
end

function dl_line(p1x, p1y, p2x, p2y, thickness)
  local w = dl_get_window()
  local draw_list = reaper.ImGui_GetWindowDrawList(ctx)
  reaper.ImGui_DrawList_AddLine(draw_list, p1x + w.x, p1y + w.y, p2x + w.x, p2y + w.y, dl_color, thickness)
end

function dl_rect(x, y, wi, h, round, flags, thickness)
  local w = dl_get_window()
  local draw_list = reaper.ImGui_GetWindowDrawList(ctx)
  reaper.ImGui_DrawList_AddRect(draw_list, x + w.x, y + w.y, x + wi + w.x, y + h + w.y, dl_color, round, flags, thickness)
end

function dl_rect_filled(x, y, wi, h, round, flags, thickness)
  local w = dl_get_window()
  local draw_list = reaper.ImGui_GetWindowDrawList(ctx)
  reaper.ImGui_DrawList_AddRectFilled(draw_list, x + w.x, y + w.y, x + wi + w.x, y + h + w.y, dl_color, round, flags)
end

dl_set_padding(0, 0, 0)