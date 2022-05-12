-- @noindex

local sel_track_count = reaper.CountSelectedTracks(0)
if sel_track_count == 0 then return end

function p(msg) reaper.ShowConsoleMsg(tostring(msg) .. '\n') end
function reaper_do_file(file) local info = debug.getinfo(1,'S'); path = info.source:match[[^@?(.*[\/])[^\/]-$]]; dofile(path .. file); end

reaper_do_file('libraries/functions.lua')
reaper_do_file('libraries/json.lua')
reaper_do_file('libraries/settings.lua')
reaper_do_file('libraries/razor.lua')
reaper_do_file('libraries/items.lua')

local tracks = {}
for i = 0, sel_track_count - 1 do
  local track = reaper.GetSelectedTrack(0, i)
  table.insert(tracks, track)
end

local comps = {}
local edits = get_razor_edits()
for i = 1, #edits do
  local edit = edits[i]
  if not edit.is_envelope then
    local it = get_items_in_range(edit.track, edit.start_pos, edit.end_pos)
    table.insert(comps, {items = it, edit = edit})
  end
end
if #comps == 0 then return end

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
local cleared_tracks = {}
for i = 1, #comps do
  local comp = comps[i]
  local edit, items = comp.edit, comp.items

  --Clear range
  local track_index = math.min(i, #tracks)
  local track       = tracks[track_index]
  local track_id    = reaper.GetMediaTrackInfo_Value(track, 'IP_TRACKNUMBER')
  if track ~= edit.track then
    if not cleared_tracks[track_id .. '|' .. edit.start_pos] then
      delete_item_range(track, edit.start_pos, edit.end_pos)
      cleared_tracks[track_id .. '|' .. edit.start_pos] = true
    end

    --Create items
    local new_items = {}
    for i = 1, #items do
      local new_item = copy_media_item_to_track(track, items[i])
      bound_item_to_range(track, new_item, edit.start_pos, edit.end_pos)
    end
  end
end
reaper.Undo_EndBlock("Comp razor edits to selected track", -1)
reaper.PreventUIRefresh(-1)




