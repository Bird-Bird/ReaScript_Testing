-- @noindex

function p(msg) reaper.ShowConsoleMsg(tostring(msg) .. '\n') end
function reaper_do_file(file) local info = debug.getinfo(1,'S'); path = info.source:match[[^@?(.*[\/])[^\/]-$]]; dofile(path .. file); end

reaper_do_file('libraries/functions.lua')
reaper_do_file('libraries/razor.lua')
reaper_do_file('libraries/items.lua')
reaper_do_file('libraries/comping.lua')

local top_edit = get_first_track_with_edits()
if top_edit then
  local comp_track = get_previous_comp_track(top_edit)
  if comp_track then
    do_comp(true, comp_track)
  end
end




