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
    local j = state.data.selected + 1
    if j > version_count then j = j - version_count end
    local clear = 1
    add_new_version(track, state, clear)
    if settings.prefix_tracks then prefix_track_fast(track) end

end



        reaper.Undo_EndBlock('Track Versions - Add New Empty Version', -1)
        reaper.PreventUIRefresh(-1)
        reaper.UpdateArrange()      








local settings = get_settings()
if settings.prefix_tracks then 
    prefix_tracks(tracks, true)
end

reaper.Undo_EndBlock('Track Versions - Cycle to next version', -1)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()