-- @noindex

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

local theme_classic = {
  bg = {r = 255,g = 249,b = 232},
  
  border =  {r = 50, g = 90, b = 50},
  border_margin = 5,
  
  crop_region = {r = 240, g = 68, b = 126},
  crop_region_alpha = 0.2,
  
  waveform_line = {r = 10, g = 10, b = 10},
  waveform_fill_alpha = 0.3,
  wave_fade_len = 20,
  wave_fade_alpha_intensity = 0.5,
  rainbow_waveform_col = false,

  writer_col = {r = 240, g = 68, b = 126},

  trail_len = 0,
  trail_pow = 4,
  trail_alpha = 0.22
}

local theme_carbon = {
  bg = {r = 40,g = 40,b = 40},
  
  border =  {r = 80, g = 80, b = 80},
  border_margin = 5,
  
  crop_region = {r = 80, g = 150, b = 240},
  crop_region_alpha = 0.2,
  
  waveform_line = {r = 200, g = 200, b = 200},
  waveform_fill_alpha = 0.3,
  wave_fade_len = 20,
  wave_fade_alpha_intensity = 0.5,
  rainbow_waveform_col = false,

  writer_col = {r = 80, g = 150, b = 240},
  
  trail_len = 50,
  trail_pow = 4,
  trail_alpha = 0.22
}

local theme_violet = {
  bg = {r = 32, g = 32, b = 32},
  
  border =  {r = 58, g = 42, b = 61},
  border_margin = 5,
  
  crop_region = {r = 250, g = 217, b = 27},
  crop_region_alpha = 0.2,
  
  waveform_line = {r = 202, g = 4, b = 98},
  waveform_fill_alpha = 0.3,
  wave_fade_len = 20,
  wave_fade_alpha_intensity = 0.8,
  rainbow_waveform_col = false,

  writer_col = {r = 231, g = 197, b = 5},
  
  trail_len = 50,
  trail_pow = 4,
  trail_alpha = 0.3
}

local theme_rainbow = {
  bg = {r = 32, g = 32, b = 32},
  
  border =  {r = 58, g = 42, b = 61},
  border_margin = 5,
  
  crop_region = {r = 250, g = 217, b = 27},
  crop_region_alpha = 0.2,
  
  waveform_line = {r = 202, g = 4, b = 98},
  waveform_fill_alpha = 0.3,
  wave_fade_len = 20,
  wave_fade_alpha_intensity = 0.6,
  rainbow_waveform_col = true,

  writer_col = {r = 231, g = 197, b = 5},
  
  trail_len = 50,
  trail_pow = 4,
  trail_alpha = 0.3
}

local theme_reaper_default = {
  bg = {r = 129, g = 137, b = 137},
  
  border =  {r = 51, g = 51, b = 51},
  border_margin = 5,
  
  crop_region = {r = 31, g = 233, b = 192},
  crop_region_alpha = 0.13,
  
  waveform_line = {r = 26, g = 26, b = 26},
  waveform_fill_alpha = 0.5,
  wave_fade_len = 20,
  wave_fade_alpha_intensity = 0.6,
  rainbow_waveform_col = false,

  writer_col = {r = 239, g = 200, b = 82},
  
  trail_len = 0,
  trail_pow = 4,
  trail_alpha = 0.3
}

default_themes = {}
default_themes['theme_classic'] =        theme_classic
default_themes['theme_carbon']  =        theme_carbon
default_themes['theme_violet']  =        theme_violet
default_themes['theme_rainbow'] =        theme_rainbow
default_themes['theme_reaper_default'] = theme_reaper_default

--USER SETTINGS
local info = debug.getinfo(1,'S')
local path = info.source:match[[^@?(.*[\/])[^\/]-$]]
function get_themes()
  local file_name = '/themes.json'
  local settings = io.open(path .. file_name, 'r')
  if not settings then
    save_themes(default_themes)
    return default_themes
  else
    local st = settings:read("*all")
    st_json = json.decode(st)
    if st_json["theme_sundial"] then
      st_json["theme_sundial"] = nil
      save_themes(st_json)
    end
    return st_json
  end
end

function save_themes(data)
  local settings = io.open(path .. 'themes.json', 'w')
  local d = json.encode(data)
  settings:write(d)
  settings:close()
end

theme_index = {
  theme_carbon = 1,
  theme_reaper_default = 2,
  theme_rainbow = 3,
  theme_violet = 4,
  theme_classic = 5
}
theme_index_name = {}
theme_index_name[1] = "theme_carbon"
theme_index_name[2] = "theme_reaper_default"
theme_index_name[3] = "theme_rainbow"
theme_index_name[4] = "theme_violet"
theme_index_name[5] = "theme_classic"