-- @noindex

function p(msg) reaper.ShowConsoleMsg(tostring(msg) .. '\n') end
function reaper_do_file(file) local info = debug.getinfo(1,'S'); path = info.source:match[[^@?(.*[\/])[^\/]-$]]; dofile(path .. file); end

reaper_do_file('libraries/functions.lua')
reaper_do_file('libraries/razor.lua')
reaper_do_file('libraries/items.lua')

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
local new_edits = {}
for i = 0, reaper.CountTracks(0)-1 do 
  local track = reaper.GetTrack(0, i)
  local _, edits = reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", '', false)
  if edits ~= "" then
    local new_track = get_previous_visible_track(track)
    reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", '', true)
    table.insert(new_edits, {t = new_track, e = edits})
  end
end
for i = 1, #new_edits do
  local e = new_edits[i]
  reaper.GetSetMediaTrackInfo_String(e.t, "P_RAZOREDITS", e.e, true)
end
reaper.Undo_EndBlock("Move razor edits up one track", -1)
reaper.PreventUIRefresh(-1)

