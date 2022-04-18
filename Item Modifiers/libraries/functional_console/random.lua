-- @noindex

local seed = reaper.time_precise()
function init_random()
    math.randomseed(seed)
    math.random()
    math.random()
    math.random()
end

function reset_seed()
  seed = reaper.time_precise()*100
  init_random()
end

function rand()
  return math.random()
end

function get_random_num(arg)
  local vals = arg:sub(2)
  local s,e = table.unpack(str_split(vals, '='))
  s = tonumber(s)
  e = tonumber(e)

  local val = rand()*(e-s) + s
  return val
end
