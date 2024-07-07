-- @description Note Puncher
-- @version 0.91
-- @author BirdBird
-- @changelog
--  + Initial release.

local cache           = nil
local settings        = {}
local needs_redraw    = true
local user_has_js_api = reaper.JS_ReaScriptAPI_Version ~= nil
local hwnd            = nil

function get_item_take()
  local editor = reaper.MIDIEditor_GetActive()
  
  if editor ~= nil then
    local take = reaper.MIDIEditor_GetTake(editor)
    local item = reaper.GetMediaItemTake_Item(take)
    return item, take, editor
  else
    if reaper.CountSelectedMediaItems(0) == 0 then
      return nil, nil, nil
    end
    
    local item = reaper.GetSelectedMediaItem(0, 0)
    local take = reaper.GetActiveTake(item)
    if reaper.TakeIsMIDI(take) == false then
      return nil, nil, nil
    end
    
    return item, take, nil
  end
end

function get_notes(take)
  local notes = {}

  local _, note_count = reaper.MIDI_CountEvts(take)
  for i = 0, note_count - 1 do
    local _, selected, muted, startppqpos, endppqpos, chan, pitch, velocity = reaper.MIDI_GetNote(take, i)
    table.insert(notes, 
    {
      selected    = selected,
      muted       = muted,
      startppqpos = startppqpos, 
      endppqpos   = endppqpos, 
      chan        = chan, 
      pitch       = pitch, 
      velocity    = velocity,
      id          = i
    })
  end
  
  table.sort(notes, function(note_1, note_2) return note_1.startppqpos < note_2.startppqpos end)
  
  return notes
end

function update_note_cache()
  if cache == nil then
    return
  end
  
  cache.active_notes = {}
  local edit_cursor_pos = reaper.GetCursorPosition()
  local edit_cursor_PPQ = reaper.MIDI_GetPPQPosFromProjTime(cache.take, edit_cursor_pos)
  local cluster_id = locate_cluster_id_by_ppq_position(cache, edit_cursor_PPQ)
  if cluster_id ~= nil then
    local cluster = cache.clusters[cluster_id]
    for i = 1, #cluster do
      cache.active_notes[cluster[i].pitch] = true
    end
  end

  needs_redraw = true
end

function get_clusters(notes)
  local function table_shallow_copy(t)
    local t2 = {}
    for i = 1, #t do
      table.insert(t2, t[i])
    end
    return t2
  end

  if #notes == 0 then
    return {}
  end
  
  local clusters        = {}
  local current_cluster = {}
  local last_position   = reaper.MIDI_GetProjTimeFromPPQPos(cache.take, notes[1].startppqpos)
  
  for i = 1, #notes do
    local note = notes[i]
    
    local position = reaper.MIDI_GetProjTimeFromPPQPos(cache.take, note.startppqpos)
    if i == 1 or position - last_position < (settings.cluster_threshold/1000.0) then
      table.insert(current_cluster, note)
    else
      table.insert(clusters, table_shallow_copy(current_cluster))
      last_position = position
      current_cluster = {note}
    end
  end
  
  if #current_cluster > 0 then
    table.insert(clusters, table_shallow_copy(current_cluster))
  end
  
  return clusters
end

function recalculate_note_cache()
  cache = nil
  
  local item, take, editor = get_item_take()
  if item == nil or take == nil then
    needs_redraw = true
    return
  end
  
  cache          = {}
  cache.editor   = editor
  cache.track    = reaper.GetMediaItemTrack(item)
  cache.item     = item
  cache.take     = take
  cache.notes    = get_notes(take)
  cache.clusters = get_clusters(cache.notes)
  
  update_note_cache(cache)
  needs_redraw = true
end

function locate_cluster_id_by_ppq_position(cache, position)
  if cache == nil then
    return
  end

  local best_cluster_id = nil
  local min_distance = math.huge

  for cluster_id, cluster in ipairs(cache.clusters) do
    local minppqpos, maxppqpos = get_cluster_stats(cluster)
    local distance = math.abs(position - minppqpos)

    if distance < min_distance and position >= minppqpos and position < maxppqpos then
      best_cluster_id = cluster_id
      min_distance = distance
    end
  end

  return best_cluster_id
end

function get_cluster_stats(cluster)
  if not cluster or #cluster == 0 then
    return nil, nil
  end

  local min_ppq = math.huge
  local max_ppq = -math.huge
  local avg_vel = 0

  for _, note in ipairs(cluster) do
    min_ppq = math.min(min_ppq, note.startppqpos)
    max_ppq = math.max(max_ppq, note.endppqpos)
    avg_vel = avg_vel + note.velocity
  end
  avg_vel = math.floor(avg_vel/#cluster + 0.5)

  return min_ppq, max_ppq, avg_vel
end

function axis_aligned_bounding_box(x, y, w, h, px, py)
  return px >= x and px <= x + w and py >= y and py <= y + h
end

local black_display_offset = {}
black_display_offset[1]    = 0.7
black_display_offset[3]    = 1 - black_display_offset[1]
black_display_offset[6]    = 0.75
black_display_offset[8]    = 0.5
black_display_offset[10]   = 1 - black_display_offset[6]

white_notes     = {}
white_notes[0]  = true
white_notes[2]  = true
white_notes[4]  = true
white_notes[5]  = true
white_notes[7]  = true
white_notes[9]  = true
white_notes[11] = true

local GUI_WHITE_NOTE_WIDTH = 26
local GUI_BLACK_NOTE_WIDTH = 16
local GUI_NOTE_SEPARATOR   = 1
local GUI_FULL_NOTE_WIDTH  = GUI_WHITE_NOTE_WIDTH + GUI_NOTE_SEPARATOR

local viewport_scroll = 0

function draw_or_hit_test(cache, x, y, w, h, draw, hit_test, mouse_x, mouse_y)
  if cache == nil then
    gfx.set(0.9, 0.9, 0.9)
    gfx.rect(0, 0, gfx.w, gfx.h)
    gfx.x = 10
    gfx.y = 10
    gfx.set(0.1, 0.1, 0.1)
    gfx.drawstr("No active/selected MIDI take.")
    return
  end

  if draw == true then
    gfx.clear = 0x000000
  end
  
  local out_hit_note = -1

  local gui_white_note_width = GUI_WHITE_NOTE_WIDTH*settings.gui_scale
  local gui_full_note_width  = gui_white_note_width + math.floor(math.max(GUI_NOTE_SEPARATOR*settings.gui_scale, 1) + 0.5)
  local gui_black_note_width = GUI_BLACK_NOTE_WIDTH*settings.gui_scale
  
  --white notes
  local cursor = 0
  for i = 0, 127 do
    local degree = i % 12
    if white_notes[degree] == nil then
      goto continue
    end
    
    local note_x = math.floor(cursor*gui_full_note_width - viewport_scroll*gui_full_note_width + 0.5)
    local note_w = gui_white_note_width
    if note_x + note_w < 0 or note_x > x + w then
      cursor = cursor + 1
      goto continue
    end
    local note_y = y + 1
    local note_h = h - 2
    
    cursor = cursor + 1
    
    if draw == true then
      if cache.active_notes[i] == true then
        gfx.set(0.5, 0.5, 1, 1)
      else
        gfx.set(1, 1, 1, 1)
      end
      gfx.rect(note_x, note_y, note_w, note_h)
      
      if settings.hide_cosmetics == 0 then
        gfx.set(0.0, 0.0, 0.0, 0.12)
        gfx.line(note_x, note_y, note_x, note_y + note_h)
      end
    end
    
    if hit_test == true and axis_aligned_bounding_box(note_x, note_y, note_w, note_h, mouse_x, mouse_y) then
      out_hit_note = i
    end

    ::continue::
  end
  
  --black notes
  cursor = 0
  for i = 0, 127 do
    local degree = i % 12
    
    if white_notes[degree] ~= nil then
      cursor = cursor + 1
      goto continue
    end
      
    local x = cursor*gui_full_note_width - viewport_scroll*gui_full_note_width

    local note_x = math.floor(x - gui_black_note_width*black_display_offset[degree] + 0.5)
    local note_w = gui_black_note_width
    if note_x + note_w < 0 or note_x > x + w then
      goto continue
    end
    local note_y = y + 1
    local note_h = h - 21
    
    if draw == true then
      if cache.active_notes[i] == true then
        gfx.set(0, 0, 0, 1)
        gfx.rect(note_x, note_y, note_w, note_h)
        gfx.set(0.5, 0.5, 1, 1)
        gfx.rect(note_x + 1, note_y, note_w - 2, note_h - 1)
      else
        if settings.hide_cosmetics == 0 then
          gfx.set(0, 0, 0, 0.1)
          gfx.rect(note_x - 4, note_y, note_w, note_h)
        end
        gfx.set(0.1, 0.1, 0.1, 1)
        gfx.rect(note_x, note_y, note_w, note_h)
      end
      if settings.hide_cosmetics == 0 then
        gfx.set(1.0, 1.0, 1.0, 0.2)
        gfx.line(note_x + note_w - 2, note_y + 1, note_x + note_w - 2, note_y + note_h - 2)
      end
    end
    
    if hit_test == true and axis_aligned_bounding_box(note_x, note_y, note_w, note_h, mouse_x, mouse_y) then
      out_hit_note = i
    end
    
    ::continue::
  end
  
  if draw == true then
    needs_redraw = true
  end
  
  return out_hit_note
end

local GUI_SETTINGS_BUTTON_SIZE   = 16
local GUI_SETTINGS_BUTTON_OFFSET = 2
local GUI_SETTINGS_BUTTON_RANGE  = GUI_SETTINGS_BUTTON_SIZE + GUI_SETTINGS_BUTTON_OFFSET

function draw_settings_button()
  local button_size = GUI_SETTINGS_BUTTON_SIZE
  local offset      = GUI_SETTINGS_BUTTON_OFFSET
  
  local x = gfx.w - button_size - offset + 1
  local y = offset
  local w = button_size
  local h = button_size
  
  gfx.set(1.0, 1.0, 1.0, 0.85)
  gfx.rect(x, y, w, h, 1)
  gfx.set(0.2, 0.2, 0.2)
  gfx.rect(x, y, w, h, 0)
  
  local center_x = x + w/2
  local center_y = y + h/2 + 2
  gfx.set(0.0, 0.0, 0.0, 1.0)
  gfx.line(center_x, center_y, center_x - 2, center_y - 5)
  gfx.line(center_x, center_y, center_x + 2, center_y - 5)
end

function show_settings()
  local dock_status = gfx.dock(-1)
  local is_docked = dock_status & 0x0F > 0
  local menu = is_docked and "!Undock" or "Dock"
  menu = menu .. "|>GUI Scale"
  menu = menu .. "|"  .. (settings.gui_scale == 0.5 and "!0.5x" or "0.5x")
  menu = menu .. "|"  .. (settings.gui_scale == 1   and "!1x" or "1x")
  menu = menu .. "|"  .. (settings.gui_scale == 1.5 and "!1.5x" or "1.5x")
  menu = menu .. "|"  .. (settings.gui_scale == 2   and "!2x" or "2x")
  menu = menu .. "|<" .. (settings.gui_scale == 4   and "!4x" or "4x")
  menu = menu .. "|"  .. (settings.hide_cosmetics  == 1 and "!Hide Cosmetics" or "Hide Cosmetics")
  menu = menu .. "|"  .. "Set Chord Threshold (" .. settings.cluster_threshold .. 'ms)'
  if user_has_js_api == true then
    menu = menu .. "||" ..  (settings.auto_focus      == 1 and "!Mouse Auto-Focus" or "Mouse Auto-Focus")
  end

  gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
  local result = gfx.showmenu(menu)

  if result == 1 then
    if is_docked == true then
      gfx.dock(0)
    else
      gfx.dock(513)
    end
  elseif result == 2 then
    settings.gui_scale = 0.5
    needs_redraw = true
  elseif result == 3 then
    settings.gui_scale = 1.0
    needs_redraw = true
  elseif result == 4 then
    settings.gui_scale = 1.5
    needs_redraw = true
  elseif result == 5 then
    settings.gui_scale = 2.0
    needs_redraw = true
  elseif result == 6 then
    settings.gui_scale = 4.0
    needs_redraw = true
  elseif result == 7 then
    settings.hide_cosmetics = settings.hide_cosmetics  == 1 and 0 or 1
    needs_redraw = true
  elseif result == 8 then
    --threshold
    local retval, values = reaper.GetUserInputs("Chord Threshold:", 1, "Value (ms):", "")
    if retval == false then
      return
    end
    values = values:gsub("ms", "")
    values = tonumber(values)
    if values then
      settings.cluster_threshold = tonumber(values)
      recalculate_note_cache()
    else
      reaper.ShowMessageBox("Please enter a valid number.", "Invalid Input", 0)
    end
  elseif result == 9 then
    settings.auto_focus      = settings.auto_focus == 1 and 0 or 1
  end
end

local SHIFT_MAP = {4}
local CTRL_MAP  = {7}
local ALT_MAP   = {12}

function do_left_click(pitch)
  if pitch == -1 or cache == nil then
    return
  end
  
  local enable_modifiers = true
  local extra_notes      = nil
  if enable_modifiers == true then
    local ctrl  = gfx.mouse_cap & 4  == 4
    local shift = gfx.mouse_cap & 8  == 8
    local alt   = gfx.mouse_cap & 16 == 16
    
    if shift == true then
      extra_notes = SHIFT_MAP
    elseif ctrl == true then
      extra_notes = CTRL_MAP
    elseif alt == true then
      extra_notes = ALT_MAP
    end
  end
  
  local edit_cursor_pos = reaper.GetCursorPosition()
  local edit_cursor_PPQ = reaper.MIDI_GetPPQPosFromProjTime(cache.take, edit_cursor_pos)
  
  local undo_string = "Note Puncher: "

  if cache.active_notes[pitch] == true then
    local function note_overlaps_cursor(note)
      return edit_cursor_PPQ >= note.startppqpos and edit_cursor_PPQ <= note.endppqpos
    end

    undo_string = undo_string .. "Remove Note" .. (extra_notes == nil and "" or "s")
    reaper.Undo_BeginBlock()

    local notes_to_delete = {}

    local cluster_id = locate_cluster_id_by_ppq_position(cache, edit_cursor_PPQ)
    local cluster = cache.clusters[cluster_id]
    table.sort(cluster, function(note_1, note_2) return note_1.id < note_2.id end)

    for i = #cluster, 1, -1 do 
      local note = cluster[i]
      if note.pitch == pitch then 
        reaper.MIDI_DeleteNote(cache.take, note.id)
      end

      if extra_notes == nil then
        goto continue
      end
      
      for j = 1, #extra_notes do
        if note.pitch == pitch + extra_notes[j] then
          reaper.MIDI_DeleteNote(cache.take, note.id)
        end
      end
      
      ::continue::
    end

    reaper.MIDI_Sort(cache.take)
    reaper.MarkTrackItemsDirty(cache.track, cache.item)
    reaper.Undo_EndBlock(undo_string, -1)
  else
    local cluster_id = locate_cluster_id_by_ppq_position(cache, edit_cursor_PPQ)
    if cluster_id == nil then
      return
    end
    local cluster = cache.clusters[cluster_id]
  
    undo_string = undo_string .. "Insert Note" .. (extra_notes == nil and "" or "s")
    reaper.Undo_BeginBlock()

    local minppq, maxppq, average_velocity = get_cluster_stats(cluster)
    reaper.MIDI_InsertNote(cache.take, false, false, minppq, maxppq, 1, pitch, average_velocity, true)
    if extra_notes ~= nil then
      for i = 1, #extra_notes do
        reaper.MIDI_InsertNote(cache.take, false, false, minppq, maxppq, 1, pitch + extra_notes[i], average_velocity, true)
      end
    end
    reaper.MIDI_Sort(cache.take)
    reaper.MarkTrackItemsDirty(cache.track, cache.item)
    reaper.Undo_EndBlock(undo_string, -1)
  end
end

local PPQ_NUDGE = 1

function get_previous_ppq_position(position, nudge)
  if cache == nil then
    return 
  end

  local ppq_nudge = nudge == true and PPQ_NUDGE or 0
    
  local cluster_id = locate_cluster_id_by_ppq_position(cache, position)
  if cluster_id == nil then
    local found_cluster = false
    
    --wrap back to start if at the end of the item
    local time = reaper.GetMediaItemInfo_Value(cache.item, "D_POSITION") + reaper.GetMediaItemInfo_Value(cache.item, "D_LENGTH")
    local end_ppq = reaper.MIDI_GetPPQPosFromProjTime(cache.take, time)
    if position == end_ppq then
      return 0
    end

    --find next best cluster
    for i = #cache.clusters, 1, -1 do
      local cluster = cache.clusters[i]
      local minppqpos, maxppqpos = get_cluster_stats(cluster)
      if maxppqpos < position then
        return minppqpos + ppq_nudge
      end
    end
      
    --move to start
    return 0
  else
    if cluster_id == 1 then
      return 0
    end

    for i = #cache.clusters, 1, -1 do
      local minppqpos, maxppqpos = get_cluster_stats(cache.clusters[i])  
      if position > minppqpos and i < cluster_id then
        return minppqpos + ppq_nudge
      end
    end

    return 0
  end
end

function get_next_ppq_position(position, nudge)
  if cache == nil then
    return 
  end
    
  local ppq_nudge = nudge == true and PPQ_NUDGE or 0

  local cluster_id = locate_cluster_id_by_ppq_position(cache, position)
  if cluster_id == nil then
    local found_cluster = false
    
    for i = 1, #cache.clusters do
      local cluster = cache.clusters[i]
      local minppqpos, maxppqpos = get_cluster_stats(cluster)
      if minppqpos > position then
        return minppqpos + ppq_nudge
      end
    end

    local time = reaper.GetMediaItemInfo_Value(cache.item, "D_POSITION") + 
                 reaper.GetMediaItemInfo_Value(cache.item, "D_LENGTH")
    return reaper.MIDI_GetPPQPosFromProjTime(cache.take, time)
  else
    if cluster_id == #cache.clusters then
      goto skip
    end

    for i = 1, #cache.clusters do
      local minppqpos, maxppqpos = get_cluster_stats(cache.clusters[i])  
      if minppqpos > position and i > cluster_id then
        return minppqpos + ppq_nudge
      end
    end

    ::skip::
    local time = reaper.GetMediaItemInfo_Value(cache.item, "D_POSITION") + 
                 reaper.GetMediaItemInfo_Value(cache.item, "D_LENGTH")
    return reaper.MIDI_GetPPQPosFromProjTime(cache.take, time)
  end
end

local NUDGE_BACK    = 0
local NUDGE_FORWARD = 1
function nudge_cursor(nudge_type)
  if cache == nil then
    return
  end

  local edit_cursor_pos = reaper.GetCursorPosition()
  local edit_cursor_PPQ = reaper.MIDI_GetPPQPosFromProjTime(cache.take, edit_cursor_pos)
  local position = nudge_type == NUDGE_BACK and get_previous_ppq_position(edit_cursor_PPQ, true) or
                                                get_next_ppq_position(edit_cursor_PPQ, true)

  if not position then
    return
  end

  local time = reaper.MIDI_GetProjTimeFromPPQPos(cache.take, position)
  reaper.SetEditCurPos(time, false, false)
end

function nudge_cursor_grid(nudge_type)
  if cache == nil then
    goto arrange
  end

  --send the command to the active midi editor
  if cache.editor ~= nil then
    if nudge_type == NUDGE_BACK then
      reaper.MIDIEditor_OnCommand(cache.editor, 40047)
    else
      reaper.MIDIEditor_OnCommand(cache.editor, 40048)
    end    
  end

  --send it to arrange
  ::arrange::
  if nudge_type == NUDGE_BACK then
    reaper.Main_OnCommand(40646, -1)
  else
    reaper.Main_OnCommand(40647, -1)
  end  
  return
end

function try_mouse_autofocus()
  if user_has_js_api == false then
    return
  end

  local focused_window = reaper.JS_Window_GetFocus()
  if axis_aligned_bounding_box(0, 0, gfx.w, gfx.h, gfx.mouse_x, gfx.mouse_y) and focused_window ~= hwnd then
    reaper.JS_Window_SetFocus(hwnd)
  end
end

local last_edit_cursor_position = reaper.GetCursorPosition()
local last_active_project       = reaper.EnumProjects(-1)
local last_change_count         = reaper.GetProjectStateChangeCount(last_active_project)
local last_gfx_w                = gfx.w
local last_gfx_h                = gfx.h
function try_invalidate_cache()
  local invalidated = false
  
  --project tab changed
  local active_project = reaper.EnumProjects(-1)
  if last_active_project ~= active_project then
    recalculate_note_cache()
    invalidated = true
  end
  last_active_project = active_project

  if invalidated == true then 
    return 
  end

  --undo history changed
  local change_count = reaper.GetProjectStateChangeCount(active_project)
  if last_change_count ~= change_count then
    recalculate_note_cache()
    invalidated = true
  end
  last_change_count = change_count

  if invalidated == true then 
    return 
  end

  --cursor moved
  local cursor_position = reaper.GetCursorPosition()
  if last_edit_cursor_position ~= cursor_position then
    update_note_cache()
  end
  last_edit_cursor_position = cursor_position

  --window resized
  if last_gfx_w ~= gfx.w or last_gfx_h ~= gfx.h then
    needs_redraw = true
  end
  last_gfx_w = gfx.w
  last_gfx_h = gfx.h
end

local last_LMB = gfx.mouse_cap&1   == 1
local last_RMB = gfx.mouse_cap&2   == 2
local last_MMB = gfx.mouse_cap&64  == 64
local last_mouse_x = gfx.mouse_x
local last_mouse_y = gfx.mouse_y

function main()
  local mouse_x = gfx.mouse_x
  local mouse_y = gfx.mouse_y
  local LMB = gfx.mouse_cap&1  == 1 
  local RMB = gfx.mouse_cap&2  == 2
  local MMB = gfx.mouse_cap&64 == 64
  
  local delta_x = mouse_x - last_mouse_x
  local delta_y = mouse_y - last_mouse_y
  last_mouse_x = mouse_x
  last_mouse_y = mouse_y

  --left click
  if last_LMB == false and LMB == true then
    if mouse_x >= gfx.w - GUI_SETTINGS_BUTTON_RANGE and mouse_y <= GUI_SETTINGS_BUTTON_RANGE then
      show_settings(menu)
    else
      local hit = draw_or_hit_test(cache, 0, 0, gfx.w, gfx.h, false, true, mouse_x, mouse_y)
      do_left_click(hit)
    end
  end
  last_LMB = LMB
  
  --middle drag
  if last_MMB == true and MMB == true then
    viewport_scroll = math.max(0, viewport_scroll - delta_x/(GUI_FULL_NOTE_WIDTH*settings.gui_scale))
    if cache ~= nil and math.abs(delta_x) > 0 then
      needs_redraw = true
    end
    gfx.setcursor(429, 'arrange_handscroll')
  elseif last_MMB == true and MMB == false then
    gfx.setcursor(0)
  end
  last_MMB = MMB

  try_invalidate_cache()
  
  if settings.auto_focus == 1 then
    try_mouse_autofocus(mouse_x, mouse_y)
  end
  
  --hotkeys
  local char = gfx.getchar()
  if char == 32 then
    reaper.Main_OnCommand(40044, -1) --transport
  elseif char == 49 then
    nudge_cursor(0)
  elseif char == 50 then
    nudge_cursor(1)
  elseif char == 33 then
    nudge_cursor_grid(0)
  elseif char == 39 then
    nudge_cursor_grid(1)
  end

  if char ~= -1 and char ~= 27 then
    if needs_redraw == true then
      draw_or_hit_test(cache, 0, 0, gfx.w, gfx.h, true, false)
      draw_settings_button()
      needs_redraw = false
      gfx.update()
    end
    reaper.defer(main)
  end
end

local EXT_STATE_NAME = "birdbird_notepuncher"
function save_settings()
  reaper.SetExtState(EXT_STATE_NAME, "gui_scale",          tostring(settings.gui_scale),       true)
  reaper.SetExtState(EXT_STATE_NAME, "auto_focus",         tostring(settings.auto_focus),      true)
  reaper.SetExtState(EXT_STATE_NAME, "hide_cosmetics",     tostring(settings.hide_cosmetics),  true)
  reaper.SetExtState(EXT_STATE_NAME, "cluster_threshold",  tostring(settings.cluster_threshold),  true)
  
  local dock, x, y, w, h = gfx.dock(-1, 0, 0, 0, 0)
  reaper.SetExtState(EXT_STATE_NAME, "dock",            tostring(dock),                     true)
  reaper.SetExtState(EXT_STATE_NAME, "window_x",        tostring(x),                        true)
  reaper.SetExtState(EXT_STATE_NAME, "window_y",        tostring(y),                        true)
  reaper.SetExtState(EXT_STATE_NAME, "window_w",        tostring(w),                        true)
  reaper.SetExtState(EXT_STATE_NAME, "window_h",        tostring(h),                        true)
end

function load_settings()
  settings.gui_scale         = tonumber(reaper.GetExtState(EXT_STATE_NAME, "gui_scale"))         or 1
  settings.auto_focus        = tonumber(reaper.GetExtState(EXT_STATE_NAME, "auto_focus"))        or 0
  settings.hide_cosmetics    = tonumber(reaper.GetExtState(EXT_STATE_NAME, "hide_cosmetics"))    or 0
  settings.cluster_threshold = tonumber(reaper.GetExtState(EXT_STATE_NAME, "cluster_threshold")) or 175
  settings.dock              = tonumber(reaper.GetExtState(EXT_STATE_NAME, "dock"))              or 0
  settings.window_x          = tonumber(reaper.GetExtState(EXT_STATE_NAME, "window_x"))          or 20
  settings.window_y          = tonumber(reaper.GetExtState(EXT_STATE_NAME, "window_y"))          or 20
  settings.window_w          = tonumber(reaper.GetExtState(EXT_STATE_NAME, "window_w"))          or 1000
  settings.window_h          = tonumber(reaper.GetExtState(EXT_STATE_NAME, "window_h"))          or 106
end

load_settings()
reaper.atexit(save_settings)

gfx.init("Note Puncher", settings.window_w, settings.window_h, settings.dock, settings.window_x, settings.window_y)
if user_has_js_api == true then
  hwnd = reaper.JS_Window_Find("Note Puncher", true)
end

recalculate_note_cache()
main()