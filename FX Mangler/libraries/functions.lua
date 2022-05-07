-- @noindex

function pt(...) local m = {...}; for i = 1, #m do reaper.ShowConsoleMsg(tostring(m[i]) .. '\n') end end
function str_split(s, delimiter)
  result = {};
  for match in (s..delimiter):gmatch("(.-)"..delimiter) do
      table.insert(result, match);
  end
  return result;
end

function string.starts(String,Start)
  return string.sub(String,1,string.len(Start))==Start
end

function table.shallow_copy(t)
  local t2 = {}
  for k,v in pairs(t) do
      t2[k] = v
  end
  return t2
end

function table_has_value(t, val)
  for i = 1, #t do
    if t[i] == val then return true end
  end
  return false
end

function get_parsed_plugin_name(s)
  local t = str_split(s, ' ')
  table.remove(t, 1)
  local fs = table.concat(t, '_')
  return fs
end

function shuffle(tbl)
  for i = #tbl, 2, -1 do
    local j = math.random(i)
    tbl[i], tbl[j] = tbl[j], tbl[i]
  end
  return tbl
end

function get_shuffled_list(size)
  local ind = {}
  for i = 1, size do ind[i] = i end
  ind = shuffle(ind)
  return ind
end

function remove_whitespace(macro)
  local i = 1
  while i <= #macro do
    if macro[i] == '' or macro[i] == '\n' then
      table.remove(macro, i)
      i = i - 1
    end
    i = i + 1
  end
  return macro
end

function table.shallow_copy(t)
  local t2 = {}
  for k,v in pairs(t) do
      t2[k] = v
  end
  return t2
end

function shallow_table_equals_items(t1, t2, tr1, tr2)
  if #t1 ~= #t2 then return false end
  for i = 1, #t1 do
    if t1[i] ~= t2[i] then return false end
    if tr1[i] ~= tr2[i] then
      return false 
    end
  end
  return true
end

local timer_start = reaper.time_precise()
function tm_s()
  timer_start = reaper.time_precise()
end

function tm_e()
  local tn = (reaper.time_precise() - timer_start) * 1000
  reaper.ShowConsoleMsg(tn .. ' ms' .. '\n')
end

function deepcopy(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
      copy = {}
      for orig_key, orig_value in next, orig, nil do
          copy[deepcopy(orig_key)] = deepcopy(orig_value)
      end
      setmetatable(copy, deepcopy(getmetatable(orig)))
  else
      copy = orig
  end
  return copy
end

function print_table(node)
  local cache, stack, output = {},{},{}
  local depth = 1
  local output_str = "{\n"
  while true do
    local size = 0
    for k,v in pairs(node) do
      size = size + 1
    end
    local cur_index = 1
    for k,v in pairs(node) do
      if (cache[node] == nil) or (cur_index >= cache[node]) then
        if (string.find(output_str,"}",output_str:len())) then
          output_str = output_str .. ",\n"
        elseif not (string.find(output_str,"\n",output_str:len())) then
          output_str = output_str .. "\n"
        end
        table.insert(output,output_str)
        output_str = ""
        local key
        if (type(k) == "number" or type(k) == "boolean") then
          key = "["..tostring(k).."]"
        else
          key = "['"..tostring(k).."']"
        end
        if (type(v) == "number" or type(v) == "boolean") then
          output_str = output_str .. string.rep('\t',depth) .. key .. " = "..tostring(v)
        elseif (type(v) == "table") then
          output_str = output_str .. string.rep('\t',depth) .. key .. " = {\n"
          table.insert(stack,node)
          table.insert(stack,v)
          cache[node] = cur_index+1
          break
        else
          output_str = output_str .. string.rep('\t',depth) .. key .. " = '"..tostring(v).."'"
        end
        if (cur_index == size) then
          output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
        else
          output_str = output_str .. ","
        end
      else
        if (cur_index == size) then
          output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
        end
      end
      cur_index = cur_index + 1
    end
    if (size == 0) then
      output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
    end
    if (#stack > 0) then
      node = stack[#stack]
      stack[#stack] = nil
      depth = cache[node] == nil and depth + 1 or depth - 1
    else
      break
    end
  end
  table.insert(output,output_str)
  output_str = table.concat(output)
  p(output_str)
end

function random_seed(seed)
  math.randomseed(seed)
  math.random()
  math.random()
  math.random()
end
