-- @noindex

function p(msg) reaper.ShowConsoleMsg(tostring(msg) .. '\n') end
dofile(reaper.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/imgui.lua')('0.6')
function reaper_do_file(file) local info = debug.getinfo(1,'S'); path = info.source:match[[^@?(.*[\/])[^\/]-$]]; dofile(path .. file); end

reaper_do_file('libraries/functions.lua')
reaper_do_file('libraries/json.lua')
reaper_do_file('libraries/settings.lua')
reaper_do_file('libraries/razor.lua')
reaper_do_file('libraries/gmem.lua')

local settings = get_settings()
local sel_preset_id = gmem_get_selected_preset()
gm_write_selected_preset(sel_preset_id)

local self = ({reaper.get_action_context()})[4]
reaper.SetToggleCommandState(0, self, 1)
reaper.atexit(function()
  reaper.SetToggleCommandState(0, self, 0)
end)

function on_project_change(settings)
  local edits, min, max = get_razor_edits()
  if #edits == 0 then
    return
  end
  
  reaper.PreventUIRefresh(1)
  reaper.Undo_BeginBlock()

  --LOAD SETTINGS
  local select_folder_children = settings.select_children
  local folder_prefix_mode     = settings.folder_prefix_mode
  local select_prefixed_tracks = settings.folder_has_prefix
  local folder_is_empty        = settings.track_is_empty
  local folder_prefix          = settings.folder_prefix
  
  local move_time        = settings.move_time
  local move_loop        = settings.move_loop
  local move_edit_cursor = settings.move_cursor
  local seek_play        = settings.seek_play

  local select_tracks    = settings.select_tracks
  local solo_tracks      = settings.solo_tracks
  local exclude_folders  = settings.exclude_folders

  local select_items         = settings.select_items
  local exclude_larger_items = settings.exclude_out_bounds
  local add_to_selection     = false

  local actions = settings.actions
  
  --FOLDER SELECTION
  local prefix_mode, prefix = 0, "-F"
  if select_folder_children then
    extend_razor_edits(select_prefixed_tracks, folder_prefix_mode, folder_prefix, folder_is_empty)
    edits, min, max = get_razor_edits()
  end

  --TIME SELECTION
  if (move_loop or move_time) and max ~= 0 then
    if move_loop then
      reaper.GetSet_LoopTimeRange2(0, true, true, min, max, false)
    end
    if move_time then
      reaper.GetSet_LoopTimeRange2(0, true, false, min, max, false)
    end
  end

  --EDIT CURSOR
  if move_edit_cursor then
    reaper.SetEditCurPos2(0, min, false, seek_play)
  end
  
  --TRACKS
  --Solo
  if solo_tracks then 
    local solo = reaper.AnyTrackSolo(0)
    if solo then reaper.Main_OnCommand(40340, 0) end
    for i = 1, #edits do
      local track = edits[i].track
      reaper.SetMediaTrackInfo_Value(track, 'I_SOLO', 1)
    end
  end

  
  --Unselect
  if select_tracks then
    reaper.Main_OnCommand(40297, 0)
    
    --Select
    for i = 1, #edits do
      local track = edits[i].track
      local exclude, ch = false
      if exclude_folders then
        ch = get_child_tracks(track)
        if #ch > 0 then
          exclude = true
        end
      end
      if not exclude then
        reaper.SetTrackSelected(track, true)
      end
    end
  end


  --ITEMS
  if select_items then
    local all_items = {}
    for i = 1, #edits do
      local edit  = edits[i]
      local items = get_items_in_range(edit.track, edit.start_pos, edit.end_pos, exclude_larger_items)
      table.insert(all_items, items)
    end
    if not add_to_selection then
      for i = reaper.CountSelectedMediaItems(0) - 1, 1, -1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        reaper.SetMediaItemSelected(item, false)
      end
    end
    for i = 1, #all_items do
      local items = all_items[i]
      for j = 1, #items do
        local item = items[j]
        reaper.SetMediaItemSelected(item, true)
      end
    end
  end

  --CUSTOM ACTIONS
  for i = 1, #actions do
    local action = actions[i]
    if action.native == false then
      action.id = reaper.NamedCommandLookup(action.str_id)
    end
    reaper.Main_OnCommand(action.id, 0)
  end

  reaper.Undo_EndBlock("Razor Edit Utility", -1)
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
end

local l_proj_count = -1
local force_update = false
function main_defer()
  local proj_count = reaper.GetProjectStateChangeCount(0)
  if (l_proj_count < proj_count) or force_update then
    local action = reaper.Undo_CanUndo2(0)
    local redo = reaper.Undo_CanRedo2(0)
    if (action and string.find(string.lower(action), "razor") and 
    redo == nil) or force_update then
      on_project_change(settings[sel_preset_id])
      if force_update then force_update = false end
    end
  end
  l_proj_count = reaper.GetProjectStateChangeCount(0)

  --Update selected preset
  local st_gmem = gm_has_new_settings()
  if st_gmem > 0 then
    sel_preset_id = gm_get_settings_data()
    if st_gmem == 1 then
      settings = get_settings()
    end
    gm_flush()
  end
  
  gm_write_num_buttons(#settings)
  reaper.defer(main_defer)
end

main_defer()
