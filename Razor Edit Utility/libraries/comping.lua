-- @noindex

function do_comp(has_undo, track_override)
  local tracks = {}
  if not track_override then
    local sel_track_count = reaper.CountSelectedTracks(0)
    if sel_track_count == 0 then return end
    for i = 0, sel_track_count - 1 do
      local track = reaper.GetSelectedTrack(0, i)
      table.insert(tracks, track)
    end
  else
    table.insert(tracks, track_override)
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
  if has_undo then reaper.Undo_BeginBlock() end
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
  if has_undo then reaper.Undo_EndBlock("Comp razor edits to selected track", -1) end
  reaper.PreventUIRefresh(-1)
end

function get_previous_comp_track(track)
  local track_id = reaper.GetMediaTrackInfo_Value(track, 'IP_TRACKNUMBER')
  for i = track_id - 2, 0, -1 do
    local new_track = reaper.GetTrack(0, i)
    local _, new_track_name = reaper.GetSetMediaTrackInfo_String(new_track, 'P_NAME', '', false)
    if string.find(new_track_name:lower(), "comp") then
      return new_track
    end
 end
end

function get_first_track_with_edits()
  for i = 0, reaper.CountTracks(0)-1 do
    local track = reaper.GetTrack(0, i)
    local _, edits = reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", '', false)
    if edits ~= "" then
      return track
    end
  end
end