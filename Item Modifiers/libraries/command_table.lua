-- @noindex

function get_slider_double(label, val, vmin, vmax)
  return {
    type = 'slider_double', 
    label = label,
    val = val, vmin = vmin, vmax = vmax,
    default_value = val
  }
end

function get_slider_int(label, val, vmin, vmax)
  return {
    type = 'slider_int', 
    label = label,
    val = val, vmin = vmin, vmax = vmax,
    default_value = val
  }
end

function get_checkbox(label, val)
  return {
    type = 'checkbox', 
    label = label,
    val = val,
    default_value = val
  }
end

function get_selector_pattern(label, inputs)
  return {
    type = 'selector',
    label = label,
    values = inputs,
    default_values = table.shallow_copy(inputs)
  }
end

function get_string_input(label, val)
  return {
    type = 'string_input', 
    label = label,
    val = val,
    default_value = val
  }
end

function get_int_input(label, val)
  return {
    type = 'int_input', 
    label = label,
    val = val,
    default_value = val
  }
end

function get_double_input(label, val)
  return {
    type = 'double_input', 
    label = label,
    val = val,
    default_value = val
  }
end

function get_empty_command()
  return {type = 'str', cmd = ''}
end

function command_is_empty(cmd)
  if cmd == nil then return true end
end

function build_command(tb)
  local t = {}
  for i = 1, #tb do
    local c = tb[i]
    if c.type == 'str' then
      table.insert(t, c.cmd)
    elseif c.type == 'gui' then
      local ctype = c.control.type
      if ctype == 'checkbox' then
        if c.control.val == true then
          table.insert(t, c.cmd)
        end
      elseif ctype == 'selector' then
        local vals = c.control.values
        local str = 'sel ' .. table.concat(vals, '-')
        table.insert(t, str)
      elseif ctype == 'string_input' or ctype == 'int_input' or ctype == 'double_input' then
        table.insert(t, c.cmd .. ' ' .. c.control.val)
      else
        table.insert(t, c.cmd .. ' ' .. c.control.val)
      end
    end
  end
  return table.concat(t, ' ')
end

function reset_command(cmd)
  for i = 1, #cmd do
    local c = cmd[i]
    if c.type == 'gui' then
      if c.control.type ~= 'selector' then
        c.control.val = c.control.default_value
      else
        c.control.values = c.control.default_values
      end
    end
  end
end

local input_flags =  reaper.ImGui_InputTextFlags_CharsNoBlank()
local num_flag = reaper.ImGui_InputTextFlags_CharsDecimal()
local border_color = 0xFFFFFF18
function draw_gui_from_command(c)
  local ct = c.control
  local ctype = ct.type
  if ctype == 'slider_int' then
    rv, ct.val = reaper.ImGui_SliderInt(ctx, ct.label, ct.val, ct.vmin, ct.vmax)
    draw_offset_frame(border_color, ct.label)
  elseif ctype == 'slider_double' then
    rv, ct.val = reaper.ImGui_SliderDouble(ctx, ct.label, ct.val, ct.vmin, ct.vmax)
    draw_offset_frame(border_color, ct.label)
  elseif ctype == 'checkbox' then
    rv, ct.val = reaper.ImGui_Checkbox(ctx, ct.label, ct.val)
    draw_offset_frame(border_color, ct.label)
  elseif ctype == 'selector' then
    local ex = false
    
    
    --NUM INPUTS
    local r, num_inputs = reaper.ImGui_SliderInt(ctx, 'Steps', #ct.values, 1, 10)
    draw_offset_frame(border_color, ct.label)
    if r then
      if num_inputs < #ct.values then
        for i = num_inputs + 1, #ct.values do
          table.remove(ct.values, num_inputs + 1)
        end
      else
        for i = 1, num_inputs - #ct.values do
          table.insert(ct.values, 1)
        end
      end
      ex = true
    end

    
    --TOGGLES
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(), 0x3A3A3A8A)
    for i = 1, #ct.values do
      if i > 1 then reaper.ImGui_SameLine(ctx) end
      reaper.ImGui_PushID(ctx, i)
      local bool = ct.values[i] == 1 and true or false
      rv, bool = reaper.ImGui_Checkbox(ctx, '##sel', bool)
      draw_offset_frame_checkbox(border_color, ct.label)
      if rv then ct.values[i] = bool == true and 1 or 0 end
      ex = ex or rv
      reaper.ImGui_PopID(ctx)
    end
    reaper.ImGui_PopStyleColor(ctx)
    rv = ex
  elseif ctype == 'string_input' then
    rv, txt_inp = reaper.ImGui_InputText(ctx, ct.label, ct.val, input_flags)
    if rv then ct.val = txt_inp end
    draw_offset_frame(border_color, ct.label)
  elseif ctype == 'int_input' then
    rv, txt_inp = reaper.ImGui_InputInt(ctx, ct.label, ct.val)
    if rv then ct.val = txt_inp end
    draw_offset_frame(border_color, ct.label)
  elseif ctype == 'double_input' then
    rv, txt_inp = reaper.ImGui_InputDouble(ctx, ct.label, ct.val, 0, 0, "%.2f")
    if rv then ct.val = txt_inp end
    draw_offset_frame(border_color, ct.label)
  end
  return rv
end

function draw_cmd(cmd)
  local exec = false
  for i = 1, #cmd do
    local c = cmd[i]
    if c.type == 'gui' then
      reaper.ImGui_PushID(ctx, i)
      local r = draw_gui_from_command(c, i)
      exec = exec or r
      reaper.ImGui_PopID(ctx)
    end
  end
  return exec
end