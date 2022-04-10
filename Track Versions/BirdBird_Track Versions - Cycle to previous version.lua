-- @noindex

function p(msg) reaper.ShowConsoleMsg(tostring(msg) .. '\n') end
function reaper_do_file(file) local info = debug.getinfo(1,'S'); path = info.source:match[[^@?(.*[\/])[^\/]-$]]; dofile(path .. file); end
reaper_do_file('track_versions_libraries/functions.lua')

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

local tracks = get_selected_tracks()
for i = 1, #tracks do
    local track = tracks[i].track
    local state = tracks[i].state
    local version_count = #state.versions
    local j = state.data.selected - 1
    if j == 0 then j = j + version_count end
    switch_versions(track, state, j)
end
local settings = get_settings()
if settings.prefix_tracks then 
    prefix_tracks(tracks, true)
end

reaper.Undo_EndBlock('Track Versions - Cycle to previous version', -1)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()