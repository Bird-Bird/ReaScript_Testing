-- @noindex

--https://forums.cockos.com/showpost.php?p=2456585&postcount=24
function copy_media_item_to_track(track, item, position )
  local _, chunk = reaper.GetItemStateChunk( item, "", false )
  chunk = chunk:gsub("{.-}", "")
  local new_item = reaper.AddMediaItemToTrack( track )
  reaper.SetItemStateChunk( new_item, chunk, false )
  return new_item
end

function get_track_media_items(track)
  local items = {}
  local item_count = reaper.CountTrackMediaItems(track)
  for i = 0, item_count - 1 do 
    local item = reaper.GetTrackMediaItem(track, i)
    table.insert(items, item)
  end
  return items
end

function delete_item_range(track, sp, ep)
  --SPLIT RANGE
  local items = get_track_media_items(track)
  for i = 1, #items do
    local item = items[i]
    local new_item = reaper.SplitMediaItem(item, sp)
    if new_item then
      reaper.SplitMediaItem(new_item, ep)
    else
      reaper.SplitMediaItem(item, ep)
    end
  end

  --CLEAR RANGE
  items = get_track_media_items(track)
  for i = 1, #items do 
      local item = items[i]
      local pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
      if pos >= sp and pos < ep then
        reaper.DeleteTrackMediaItem(track, item)
      end
  end
end

function clear_items(track)
  local item_count = reaper.CountTrackMediaItems(track)
  for i = 1, item_count do
    local item = reaper.GetTrackMediaItem(track, 0)
    reaper.DeleteTrackMediaItem(track, item)
  end
end

function trim_item_right_edge(track, item, pos)
  local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  local item_end = item_pos + item_len
  
  local edge = item_end - pos
  if edge > 0 then
    reaper.SetMediaItemInfo_Value(item, "D_LENGTH", item_len - edge)
  end
end

function trim_item_left_edge(track, item, pos)
  local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  local item_end = item_pos + item_len
  if item_pos < pos then
    local new_item = reaper.SplitMediaItem(item, pos)
    reaper.DeleteTrackMediaItem(track, item)
    return new_item
  else
    return item
  end
end

function delete_out_of_bounds_item(track, item, s, e)
  local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  local item_end = item_pos + item_len
  if item_pos >= e then
    reaper.DeleteTrackMediaItem(track, item)
    return true
  elseif item_end <= s then
    reaper.DeleteTrackMediaItem(track, item)
    return true
  end
  return false
end

function bound_item_to_range(track, item, sp, ep)
  local del = delete_out_of_bounds_item(track, item, sp, ep)
  if not del then
    trim_item_right_edge(track, item, ep)
    item = trim_item_left_edge(track, item, sp)
  end
end