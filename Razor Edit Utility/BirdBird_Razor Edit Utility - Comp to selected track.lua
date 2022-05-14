-- @noindex

local sel_track_count = reaper.CountSelectedTracks(0)
if sel_track_count == 0 then return end

function p(msg) reaper.ShowConsoleMsg(tostring(msg) .. '\n') end
function reaper_do_file(file) local info = debug.getinfo(1,'S'); path = info.source:match[[^@?(.*[\/])[^\/]-$]]; dofile(path .. file); end

reaper_do_file('libraries/functions.lua')
reaper_do_file('libraries/razor.lua')
reaper_do_file('libraries/items.lua')
reaper_do_file('libraries/comping.lua')

do_comp(true)




