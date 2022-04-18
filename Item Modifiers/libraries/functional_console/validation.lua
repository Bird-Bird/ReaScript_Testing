-- @noindex

function validate_macro_name(macro_name)
  local s = str_split(macro_name, ' ')
  s = remove_whitespace(s)
  if #s == 0 then
    return false, 'Enter a name for the macro!'
  elseif #s > 1 then
    return false, 'Macro name must be a single word.'
  elseif s[1]:match("%W") then
    return false, 'Only numbers and letters allowed in macro names.'
  elseif macros[s[1]] then
    return false, 'A macro with the same name already exists.'
  else
    return true, '', s[1]
  end
end

function validate_sel_arg(arg)
  local t = {}
  arg:gsub(".",function(c) table.insert(t,c) end)
  for i = 1, #t do
    if i % 2 == 1 and (t[i] ~= '1' and t[i] ~= '0') then
      return false
    elseif i % 2 == 0 and t[i] ~= '-' then return false end
  end
  return true
end

function validate_random_arg(arg)
  local vals = arg:sub(2)
  local values = str_split(vals, '=')
  print_table(values)
  if not values or #values ~= 2 then
    return false
  end
  local s,e = table.unpack(values)
  s = tonumber(s)
  e = tonumber(e)
  if not e or not s then
    return false
  end
  
  return true
end

function validate_len_arg(arg)
  if arg:sub(-1) == 'b' then
    local value = tonumber(arg:sub(1, -2))
    if value then return true end
  else
    local value = tonumber(arg)
    if value then return true end
  end
  return false
end

function is_loop_command(cmd)
  if string.starts(cmd, 'd') and tonumber(cmd:sub(2)) then
    return true
  else
    return false
  end
end
