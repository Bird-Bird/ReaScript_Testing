-- @noindex

local initial_selection = {}
local new_items = {}
local tags = {}
function fc_grab_initial_state()
  initial_selection = get_initial_item_data()
end

function fc_push_items()
  new_items = table.shallow_copy(initial_selection.items)
end

function fc_reset_to_initial_state()
  reaper.PreventUIRefresh(1)
  clear_items(new_items)
  initial_selection.items = restore_items(initial_selection)
  reaper.PreventUIRefresh(-1)
  init_random()
  new_items = {}
  tags = {}
end

function fc_clear_state(clear_selection, no_reset)
  if initial_selection.items and not no_reset then
    fc_reset_to_initial_state()
    if clear_selection then
      for i = 1, #initial_selection.items do
        reaper.SetMediaItemSelected(initial_selection.items[i], false)
      end
      reaper.UpdateArrange()
    end
  end
  initial_selection = {}
  new_items = {}
  tags = {}
end

function fc_run(input)
  local no_reset = false
  if not initial_selection.items then
    fc_grab_initial_state()
    no_reset = true
  end
  local success, err = execute_command(input, true)
  if success then
    reaper.PreventUIRefresh(1)
    if not no_reset then fc_reset_to_initial_state() end
    fc_push_items()
    
    reaper.Undo_BeginBlock()
    execute_reactive_stack()
    reaper.Undo_EndBlock('Functional Console Command', -1)
    
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
    return true, nil
  else
    return false, err
  end
end

function sanitize_items()
  for i = #new_items, 1, -1 do
    local item = new_items[i]
    if not reaper.ValidatePtr(item, 'MediaItem*') then
      table.remove(new_items, i)
    end
  end
end

--FUNC
function split(times)
  local items = get_selected_items()
  for i = 1, #items do
    local item = items[i]
    local pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
    local length = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
    local div = length/times
    local new_item = item
    for i = 1, times - 1 do
      new_item = reaper.SplitMediaItem(new_item, pos + div*i)
      table.insert(new_items, new_item)
    end
  end
end

--https://forums.cockos.com/showpost.php?p=2456585&postcount=24
function copy_media_item_to_track( item, track, position )
  local _, chunk = reaper.GetItemStateChunk( item, "", false )
  chunk = chunk:gsub("{.-}", "")
  local new_item = reaper.AddMediaItemToTrack( track )
  reaper.SetItemStateChunk( new_item, chunk, false )
  reaper.SetMediaItemInfo_Value( new_item, "D_POSITION" , position )
  table.insert(new_items, new_item)
  return new_item
end

--SELECTION
function tag_items(tag)
  local items = get_selected_items()
  tags[tag] = items
end

function select_tag(tag)
  local items = get_selected_items()
  for i = 1, #items do
    reaper.SetMediaItemSelected(items[i], false)
  end
  local tag_items = tags[tag]
  if tag_items then
    for i = 1, #tag_items do
      local item = tag_items[i]
      if reaper.ValidatePtr2(0, item, 'MediaItem*') then
        reaper.SetMediaItemSelected(item, true)
      end
    end
  end
end

function select_at_index(i)
  i = i > #new_items and #new_items or i
  reaper.SetMediaItemSelected(new_items[i], true)
end

function override_select_all()
  for i = 1, #new_items do
    reaper.SetMediaItemSelected(new_items[i], true)
  end
end

function bake_selection()
  tag_items('rsv_bake')
end

function restore_selection()
  if not tags['rsv_bake'] then
    override_select_all()
  else
    select_tag('rsv_bake')
  end
end

function invert_selection()
  for i = 1, #new_items do
    local item = new_items[i]
    if  reaper.ValidatePtr( item, 'MediaItem*') then
      local sel_state = reaper.IsMediaItemSelected(item)
      reaper.SetMediaItemSelected(item, sel_state and 0 or 1)
    end
  end
end