-- @noindex

function locate_fx_in_history(history, param_identifier)
  for i = 1, #history do
    local param = history[i]
    if param.param_identifier == param_identifier then
      return i
    end
  end
  return -1
end

function get_FX_by_GUID(track, s_fx_GUID, fx_id)
  if fx_id then
    local fx_GUID = reaper.TrackFX_GetFXGUID(track, fx_id)
    if fx_GUID and fx_GUID == s_fx_GUID then
      return fx_id
    end
  end
  
  local fx_count = reaper.TrackFX_GetCount(track)
  for i = 0, fx_count - 1 do
    local fx_GUID = reaper.TrackFX_GetFXGUID(track, i)
    if fx_GUID and fx_GUID == s_fx_GUID then
      return i
    end
  end
  return -1
end

--Remove entries for tracks that have been removed
--Remove entries for FX plugins that have been removed
--Fix IDs for FX plugins that have been moved
--Remove extra entries
function validate_fx_history(history, do_size, history_map)
  local removal = {}
  for i = 1, #history do
    local p = history[i]
    local track = p.track
    if reaper.ValidatePtr(track, "MediaTrack*") then
      local id = get_FX_by_GUID(track, p.fx_GUID, p.fx_id)
      if id == -1 then
        table.insert(removal, i)
      else
        p.fx_id = id
      end
    else
      table.insert(removal, i)
    end
  end

  for i = #removal, 1, -1 do 
    local ind = removal[i]
    local par = history[ind]
    table.remove(history, ind)
    if history_map then
      history_map[par.param_identifier] = nil
    end
  end

  if do_size then
    local history_size = settings.history_size
    while #history > history_size do
      local par = history[#history]
      table.remove(history, #history)
      if history_map then
        history_map[par.param_identifier] = nil
      end
    end
  end
end

function get_param_identifier(track, fx_id, param_id)
  local track_GUID = reaper.GetTrackGUID(track)
  local fx_GUID = reaper.TrackFX_GetFXGUID(track, fx_id)
  local param_identifier = track_GUID .. '|' .. fx_GUID .. '|' .. param_id
  return track_GUID, fx_GUID, param_identifier
end

function get_param_data(p)
  local r, format_val   = reaper.TrackFX_GetFormattedParamValue(p.track, p.fx_id, p.param_id)
  local v, _, _ = reaper.TrackFX_GetParam(p.track, p.fx_id, p.param_id)
  local _, track_name     = reaper.GetSetMediaTrackInfo_String(p.track, 'P_NAME', '', false)
  local track_id = reaper.GetMediaTrackInfo_Value(p.track, "IP_TRACKNUMBER")
  local dat = {
    format_val = format_val,
    track_name = track_name,
    track_id = math.floor(track_id),
    track_color = reaper.GetTrackColor(p.track),
    v = v,
  }
  return dat
end

function try_insert_parameter(history, history_map, p, last_tweaked_gui)
  local history_size = settings.history_size
  local track = reaper.GetTrack(0, p.track_id)
  if reaper.ValidatePtr(track, "MediaTrack*") then
    local track_GUID, fx_GUID, param_identifier = get_param_identifier(track, p.fx_id, p.param_id)
    if param_identifier == last_removed_param_identifier then
      return false
    end
    if not history_map[param_identifier] then
      --Insert FX to history
      local _, fx_name        = reaper.TrackFX_GetFXName(track, p.fx_id)
      local _, param_name     = reaper.TrackFX_GetParamName(track, p.fx_id, p.param_id)
      local _, min_v, max_v = reaper.TrackFX_GetParam(track, p.fx_id, p.param_id)
      local param_dat = {
        track      = track,
        track_GUID = track_GUID,
        
        fx_name    = fx_name,
        fx_GUID    = fx_GUID,
        fx_id      = p.fx_id,
        
        param_name = param_name,
        param_id   = p.param_id,
        param_identifier = param_identifier,
        min_v = min_v,
        max_v = max_v,

        disp_col = get_display_color(),
        undo_count = reaper.GetProjectStateChangeCount(0),
      }
      
      table.insert(history, 1, param_dat)
      history_map[param_identifier] = param_dat
      return true
    else
      --Move FX to top of history
      local map = history_map[param_identifier]
      if last_tweaked_gui ~= map.param_identifier then
        local undo_count = reaper.GetProjectStateChangeCount(0)
        local action = reaper.Undo_CanUndo2(0)
        if undo_count > map.undo_count and string.starts(action, "Edit FX parameter:") then
          local i = locate_fx_in_history(history, param_identifier)
          if i ~= -1 then
            table.remove(history, i)
            table.insert(history, 1, map)
            map.undo_count = undo_count
          end
        end
        return true
      end
      return false
    end
  end
end