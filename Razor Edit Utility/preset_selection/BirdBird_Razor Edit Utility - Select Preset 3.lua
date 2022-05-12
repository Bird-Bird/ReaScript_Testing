-- @noindex

function reaper_do_file(file) local info = debug.getinfo(1,'S'); path = info.source:match[[^@?(.*[\/])[^\/]-$]]; dofile(path .. file); end
reaper_do_file('libraries/gmem.lua')
gm_write_selected_preset(3)
gm_reload_settings()