-- @noindex

function get_child_tracks(folder_track)
	local all_tracks = {}
	if reaper.GetMediaTrackInfo_Value(folder_track, "I_FOLDERDEPTH") ~= 1 then
		return all_tracks
	end
	local tracks_count = reaper.CountTracks(0)
	local folder_track_depth = reaper.GetTrackDepth(folder_track)	
	local track_index = reaper.GetMediaTrackInfo_Value(folder_track, "IP_TRACKNUMBER")
	for i = track_index, tracks_count - 1 do
		local track = reaper.GetTrack(0, i)
		local track_depth = reaper.GetTrackDepth(track)
		if track_depth > folder_track_depth then			
			table.insert(all_tracks, track)
		else
			break
		end
	end
	return all_tracks
end

function track_has_prefix(track, prefix_mode, prefix)
  local rv, name = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', '', false)
  if prefix_mode == 0 then
    if string.starts(name, prefix) then
      return true
    end
  elseif prefix_mode == 1 then
    if ends_with(name, prefix) then
      return true
    end
  elseif prefix_mode == 2 then
    if string.find(name, prefix) then
      return true
    end
  end
  return false
end

function extend_razor_edits(select_prefix, prefix_mode, prefix, select_empty_folders)
  local t_tracks = {}
  local track_count = reaper.CountTracks(0)
  for i = 0, track_count - 1 do
    local track = reaper.GetTrack(0, i)
    local rv, edits = reaper.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS', '', false)
    if edits ~= "" and not edit_is_envelope(edits) then     
      local do_selection_pr = select_prefix and track_has_prefix(track, prefix_mode, prefix)
      if not select_prefix then do_selection_pr = true end

      local do_selection_empty = select_empty_folders and reaper.CountTrackMediaItems(track) == 0 or false
      if not select_empty_folders then do_selection_empty = true end

      if do_selection_pr and do_selection_empty then
        local child_tracks = get_child_tracks(track)
        if #child_tracks > 0 then
          for i = 1, #child_tracks do
            local c_track = child_tracks[i]
            table.insert(t_tracks, {track = c_track, edits = edits})
          end
        end
      end
    end
  end
  if #t_tracks > 0 then
    for i = 1, #t_tracks do
      local track = t_tracks[i].track
      local edits = t_tracks[i].edits
      if reaper.IsTrackVisible(track, false) then
        reaper.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS', edits, true)
      end
    end
  end
end

function edit_is_envelope(edit)
  local t = {}
  for match in (edit .. ' '):gmatch("(.-)" .. ' ') do
    table.insert(t, match);
  end
  local is_env = true
  for i = 1, #t/3 do
    is_env = is_env and t[i*3] ~= '""'
  end
  return is_env
end

function get_razor_edits()
  local razor_min, razor_max, r_edits = math.huge, 0, {}
  for i = 0, reaper.CountTracks(0) - 1 do
    local track = reaper.GetTrack(0, i)
    local _, edits = reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", false)
    if edits ~= "" then
      for start_pos, end_pos, GUID in string.gmatch(edits, '(%S+) (%S+) (%S+)') do
        local e = {
          track = track,
          start_pos = tonumber(start_pos),
          end_pos = tonumber(end_pos),
          GUID = GUID,
          is_envelope = GUID ~= '""',
          full_str = edits
        }
        table.insert(r_edits, e)
        razor_min = math.min(razor_min, e.start_pos)
        razor_max = math.max(razor_max, e.end_pos)
      end
    end
  end
  return r_edits, razor_min, razor_max
end

function get_items_in_range(track, area_start, area_end, exclude_out_bounds)
  local items = {}
  local item_count = reaper.CountTrackMediaItems(track)
  for k = 0, item_count - 1 do 
    local item = reaper.GetTrackMediaItem(track, k)
    local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local item_end_pos = pos+length
    if (item_end_pos > area_start and item_end_pos <= area_end) or
      (pos >= area_start and pos < area_end) or
      (pos <= area_start and item_end_pos >= area_end) then
        if not exclude_out_bounds then
          table.insert(items,item)
        else
          if pos >= area_start and item_end_pos <= area_end then
            table.insert(items,item)
          end
        end
    end
  end
  return items
end

function get_previous_visible_track(track)
  local track_id = reaper.GetMediaTrackInfo_Value(track, 'IP_TRACKNUMBER')
  for i = track_id - 2, 0, -1 do
    local new_track = reaper.GetTrack(0, i)
    if reaper.IsTrackVisible(new_track, false) then
      return new_track
    end
 end
end

function get_next_visible_track(track)
  local track_id = reaper.GetMediaTrackInfo_Value(track, 'IP_TRACKNUMBER')
  local track_count = reaper.CountTracks(0)
  for i = track_id, track_count - 1 do
    local new_track = reaper.GetTrack(0, i)
    if reaper.IsTrackVisible(new_track, false) then
      return new_track
    end
 end
end