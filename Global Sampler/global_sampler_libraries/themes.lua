-- @noindex

-- @noindex

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

local theme_sundial = {
  bg = {r = 70, g = 85, b = 100},
  
  border =  {r = 89, g = 94, b = 94},
  border_margin = 1,
  
  crop_region = {r = 182, g = 102, b = 103},
  crop_region_alpha = 0.2,
  
  waveform_line = {r = 223, g = 150, b = 116},
  waveform_fill_alpha = 0.3,
  wave_fade_len = 20,
  wave_fade_alpha_intensity = 1,
  rainbow_waveform_col = false,

  writer_col = {r = 247, g = 234, b = 223},
  
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

local default_themes = {}
default_themes['theme_classic'] =        theme_classic
default_themes['theme_carbon']  =        theme_carbon
default_themes['theme_violet']  =        theme_violet
default_themes['theme_sundial'] =        theme_sundial
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
    return st_json
  end
end

function save_themes(data)
  local settings = io.open(path .. 'themes.json', 'w')
  local d = json.encode(data)
  settings:write(d)
  settings:close()
end