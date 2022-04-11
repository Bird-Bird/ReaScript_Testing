-- @noindex

--PRESET PARSING
function parse_ini_file(name)
  local presets_file = io.open(name, 'r')
  if presets_file then
    --READ LINES
    local f = presets_file:read("*all")
    io.close(presets_file)
    local lines = str_split(f, '\n')
    
    --GRAB PRESET DATA
    local pd = {presets = {}, file_name = name, name_lookup = {}}
    for i = 3, #lines do
      local line = lines[i]
      if string.starts(line, '[Preset') then
        --NEW PRESET
        table.insert(pd.presets, {data = {}})
      elseif string.starts(line, 'Name') then
        --NAME
        local n = str_split(line, '=')[2]
        pd.presets[#pd.presets].name = n
        pd.name_lookup[n] = 1
      elseif string.starts(line, 'Len') then
        --LENGTH
        local len = str_split(line, '=')[2]
        pd.presets[#pd.presets].len = len
      elseif string.starts(line, "Ext") then
        --EXT DATA
        pd.ext = line:sub(5)
      elseif string.starts(line, 'Data') then
        --DATA BLOB
        table.insert(pd.presets[#pd.presets].data, line)
      end
      i = i+1
    end
    return pd
  else
      return nil
  end
end

function generate_preset_ini(pd)
  local s = ''
  local presets = pd.presets

  --HEADER
  s = s .. '[General]\n'
  if pd.ext then s = s .. 'Ext=' .. pd.ext .. '\n' end
  s = s .. 'NbPresets=' .. #presets .. '\n\n'
  
  --PRESETS
  for i = 1, #presets do
    local preset = presets[i]
    local dat = preset.data
    
    --PRESET HEADER
    s = s .. '[Preset' .. i - 1 .. ']\n'

    --DATA
    s = s .. table.concat(dat, '\n') .. '\n'
    s = s .. 'Len=' ..  preset.len .. '\n'
    s = s .. 'Name=' .. preset.name .. '\n\n'
  end
  preset_file = io.open(pd.file_name, 'w')
  preset_file:write(s)
  preset_file:close()
end

function validate_preset_name(pd, s)
  if pd.name_lookup[s] then
      return false, 'A preset with the same name already exists.'
  elseif s == '' then
      return false, 'Preset names cannot be empty.'
  else
      return true
  end
end