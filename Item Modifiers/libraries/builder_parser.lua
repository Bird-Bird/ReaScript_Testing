-- @noindex

function purify_section_str(str)
  local str = str:gsub('^%s*(.-)%s*$', '%1')
  str = str:gsub('%s+', '|')
  str = str:gsub('|', ' ')
  return str
end

function purify_sections(sections)
  for i = 1, #sections do 
    sections[i] = purify_section_str(sections[i])
  end
end

local section_validator = {}
section_validator.si = {
  num_values = 3,
  has_label = true,
  value_types = {'i', 'i', 'i'},
  num_sections = 3
}
section_validator.sd = {
  num_values = 3,
  has_label = true,
  value_types = {'f', 'f', 'f'},
  num_sections = 3
}
section_validator.cb = {
  num_values = 1,
  has_label = true,
  value_types = {'i'},
  num_sections = 3
}
section_validator.inps = {
  num_values = 1,
  has_label = true,
  value_types = {'str'},
  num_sections = 3
}
section_validator.inpi = {
  num_values = 1,
  has_label = true,
  value_types = {'i'},
  num_sections = 3
}
section_validator.inpd = {
  num_values = 1,
  has_label = true,
  value_types = {'f'},
  num_sections = 3
}

local non_gen_delim = '='
function gen_selector_validator(section, ctrl_dat, ctrl_id)
  local spl = str_split(ctrl_id, non_gen_delim)
  local num = spl[2]
  if not num or not tonumber(num) then
    return false, nil, 'Missing data for special control: selp. '
  end
  local v = {}
  for i = 1, num do table.insert(v, 'i') end
  return true, {
    num_values = num,
    has_label = false,
    value_types = v,
    num_sections = 3
  }
end
local non_generic_validator = {
  selp = gen_selector_validator
}

local missing_data_error = 'Missing or extra data. '
local missing_label_error = 'Missing label. '
local extra_section_error = 'Too many sections. '
function get_section_data(section)
  if #section == 1 then
    return true, {type = 'str', cmd = section[1]}
  else
    --HEADER
    local type = 'gui'
    local cmd = section[1]

    --Sections
    local ctrl = section[2]
    if not cmd or not ctrl then
      return false, nil, 'Missing sections. '
    end
    
    --Validate controller type
    local ctrl_dat = str_split(ctrl, ' ')
    local ctrl_type = ctrl_dat[1]:gsub('%' .. non_gen_delim .. '.+', '')
    if not section_validator[ctrl_type] and not non_generic_validator[ctrl_type] then
      return false, nil, 'Invalid control at section 2. '
    end
    local validator
    
    --Get validator
    local success, err
    if non_generic_validator[ctrl_type] then
      success, validator, err = non_generic_validator[ctrl_type](section, ctrl_dat, ctrl_dat[1])
      if err then return false, nil, err end
    else
      validator = section_validator[ctrl_type]
    end

    --Validate section count
    if #section ~= validator.num_sections then
      return false, nil, 'Missing or extra sections.'
    end

    --Validate parameter count
    if #ctrl_dat ~= validator.num_values + 1 then
      return false, nil, 'Missing or extra parameters.'
    end

    --Validate parameter type
    for i = 1, #validator.value_types do
      local vtype = validator.value_types[i]
      local par = ctrl_dat[i + 1]
      local par_num = tonumber(par)
      if vtype == 'f' and not par_num then
        return false, nil, 'Wrong parameter at index ' .. i .. '. (Section 2) '
      elseif vtype == 'i' and (not par_num or math.floor(par_num) ~= par_num) then
        return false, nil, 'Wrong parameter at index ' .. i .. '. (Section 2) '
      end
    end

    --Validate label
    if validator.has_label then
      local lbl = section[validator.num_sections]
      if not lbl or lbl == '' then
        return false, nil, 'Missing label.'
      end
    end 

    if ctrl_type == 'sd' or ctrl_type == 'si' then
      local v =    ctrl_dat[2]
      local vmin = ctrl_dat[3]
      local vmax = ctrl_dat[4]
      local label = section[3]
      local control = ctrl_type == 'sd' and 
      get_slider_double(label, v, vmin, vmax) or 
      get_slider_int(label, v, vmin, vmax)
      return true, {
        type = 'gui',
        cmd = cmd,
        control = control
      }
    elseif ctrl_type == 'cb' then
      local v = tonumber(ctrl_dat[2]) == 1 and true or false
      local label = section[3]
      return true, {
        type = 'gui',
        cmd = cmd,
        control = get_checkbox(label, v)
      }
    elseif ctrl_type == 'selp' then
      local inputs = {}
      for i = 1, validator.num_values do
        local v = tonumber(ctrl_dat[i + 1])
        table.insert(inputs, v)
      end

      local label = section[3]
      return true, { 
        type = 'gui',
        cmd = '',
        label = label,
        control = get_selector_pattern(label, inputs)
      }
    elseif ctrl_type == 'inps' then
      local val = ctrl_dat[2]
      local label = section[3]
      return true, { 
        type = 'gui',
        cmd = cmd,
        label = label,
        control = get_string_input(label, val)
      }
    elseif ctrl_type == 'inpi' then
      local val = tonumber(ctrl_dat[2])
      local label = section[3]
      return true, { 
        type = 'gui',
        cmd = cmd,
        label = label,
        control = get_int_input(label, val)
      }
    elseif ctrl_type == 'inpd' then
      local val = tonumber(ctrl_dat[2])
      local label = section[3]
      return true, { 
        type = 'gui',
        cmd = cmd,
        label = label,
        control = get_double_input(label, val)
      }
    end
  end
end

function get_cmd_from_input(input)
  local t = {}
  --BUILD COMMAND
  local lines = remove_whitespace(str_split(input, '\n'))
  for i = 1, #lines do
    local line = lines[i]
    local sections = str_split(line, '>')
    purify_sections(sections)
    
    local success, dat, err = get_section_data(sections)
    if err then
      return false, nil, err .. '(Line ' .. i ..')'
    end
    table.insert(t, dat)
  end
  
  --CHECK COMPILATION
  local cmd = build_command(t)
  local cmd_split = str_split(cmd, ' ')
  local err = check_input_errors(cmd_split)
  if err then return
    false, nil, err.description
  end

  return true, t
end