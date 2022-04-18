-- @noindex

--UTILITY
function pt(...) local m = {...}; for i = 1, #m do reaper.ShowConsoleMsg(tostring(m[i]) .. '\n') end end
function str_split(s, delimiter)
  result = {};
  for match in (s..delimiter):gmatch("(.-)"..delimiter) do
      table.insert(result, match);
  end
  return result;
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

function unselect_all_items()
  local sc = reaper.CountSelectedMediaItems(0)
  for i = sc - 1, 0, -1 do
    reaper.SetMediaItemSelected(reaper.GetSelectedMediaItem(0, i),false)
  end
end
