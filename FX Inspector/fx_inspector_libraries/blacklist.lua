-- @noindex

local info = debug.getinfo(1,'S')
local path = info.source:match[[^@?(.*[\/])[^\/]-$]]

local default_blacklist = {"bypass", "solo", "+Wet"}
function get_blacklist()
    local file_name = 'blacklist.json'
    local settings = io.open(path .. file_name, 'r')
    if not settings then
        return table.shallow_copy(default_blacklist)
    else
        local st = settings:read("*all")
        st_json = json.decode(st)
        return st_json
    end
end

function save_blacklist(data)
    local settings = io.open(path .. 'blacklist.json', 'w')
    local d = json.encode(data)
    settings:write(d)
    settings:close()
end
blacklist = get_blacklist()

function parameter_is_blacklisted(name)
  local name_low = name:lower()
  for i = 1, #blacklist do
    local word = blacklist[i]
    if string.starts(word, '+') then
      if word:sub(2) == name then
        return true
      end
    else
      word = word:lower()
      if name_low:match(word) then
        return true
      end
    end
  end
  return false
end