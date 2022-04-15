-- @noindex

--UTILITY
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