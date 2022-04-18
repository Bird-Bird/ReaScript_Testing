-- @noindex

function get_selected_items()
  local items = {}
  local sel_item_count = reaper.CountSelectedMediaItems(0)
  for i = 0, sel_item_count - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    table.insert(items, item)
  end
  return items
end

function get_initial_item_data()
  local d = {items = {}, chunks = {}, tracks = {}}
  local items = get_selected_items()
  for i = 1, #items do
    local item = items[i]
    local track = reaper.GetMediaItem_Track(item)
    local ret, chunk = reaper.GetItemStateChunk(item, '', false)

    table.insert(d.items, item)
    table.insert(d.tracks, track)
    table.insert(d.chunks, chunk)
  end
  return d
end

function clear_items(t)
  local k = 0
  for i = 1, #t do
    local item = t[i]
    if reaper.ValidatePtr(item, 'MediaItem*') then
      local track = reaper.GetMediaItem_Track(item)
      reaper.DeleteTrackMediaItem(track, item)
      k = k + 1
    end
  end
end

function restore_items(t)
  local it_new = {}
  for i = 1, #t.items do
    local item = t.items[i]
    local track = t.tracks[i]
    local chunk = t.chunks[i]
    local new_item = reaper.AddMediaItemToTrack(track)
    chunk = chunk:gsub("{.-}", "")
    reaper.SetItemStateChunk(new_item, chunk, false )
    table.insert(it_new, new_item)
  end
  return it_new
end