-- @noindex

function get_fx_data_at_index(track, i)
  local r, name = reaper.TrackFX_GetFXName(track, i)
  local trimmed_name = trim_fx_name(name)
  local visible = reaper.TrackFX_GetOpen(track, i)
  local enabled = reaper.TrackFX_GetEnabled(track, i)
  return {
    name = trimmed_name,
    full_name = name,
    visible = visible,
    id = i,
    enabled = enabled,
    track = track,
    track_id = reaper.GetMediaTrackInfo_Value(track, 'IP_TRACKNUMBER'),
    GUID =  reaper.TrackFX_GetFXGUID(track, i),
    selected = false
  }
end

function get_focused_fx()
  local name = ''
  local valid = false
  local retval, track_id, item_id, id = reaper.GetFocusedFX2()
  if retval == 2 then return {valid = false} end
  local track = reaper.GetTrack(0, track_id - 1)
  local num_presets = -1
  local auto_mode = -1
  if track then
    _, name = reaper.TrackFX_GetNamedConfigParm(track, id, 'fx_name')
    valid = true
    _, num_presets = reaper.TrackFX_GetPresetIndex(track, id)
    auto_mode = reaper.GetTrackAutomationMode(track)
  end
  return {
    name = trim_fx_name(name),
    full_name = name, 
    track = track, 
    item_id = item_id, 
    id = id, 
    valid = valid,
    num_presets = num_presets,
    auto_mode = auto_mode
  }
end

function get_last_touched_parameter()
  local valid = false
  local par_fx_name = ''
  local par_name = ''
  
  local retval, param_track_id, param_fx_id, param_id = reaper.GetLastTouchedFX()
  local param_track = reaper.GetTrack(0, param_track_id - 1)
  local param_norm_value = 0
  local format_value = ''
  if param_track then
    _, par_fx_name = reaper.TrackFX_GetNamedConfigParm( param_track, param_fx_id, 'fx_name')
    _, par_name = reaper.TrackFX_GetParamName(param_track, param_fx_id, param_id)    
    param_norm_value = reaper.TrackFX_GetParamNormalized(param_track, param_fx_id, param_id)
    _, format_value = reaper.TrackFX_GetFormattedParamValue(param_track, param_fx_id, param_id)
    valid = true
  end
  return {
    track_id = param_track_id,
    fx_id = param_fx_id,
    id = param_id,
    track = param_track,
    fx_name = trim_fx_name(par_fx_name),
    name = par_name,
    valid = valid,
    norm_value = param_norm_value,
    format_value = format_value
  }
end

function get_parameter(param_track_id, param_fx_id, param_id)
  local valid = false
  local par_fx_name = ''
  local par_name = ''
  local param_track = reaper.GetTrack(0, param_track_id - 1)
  local param_norm_value = 0
  local format_value = ''
  if param_track then
    _, par_fx_name = reaper.TrackFX_GetFXName( param_track, param_fx_id)
    _, par_name = reaper.TrackFX_GetParamName(param_track, param_fx_id, param_id)    
    param_norm_value = reaper.TrackFX_GetParamNormalized(param_track, param_fx_id, param_id)
    _, format_value = reaper.TrackFX_GetFormattedParamValue(param_track, param_fx_id, param_id)
    valid = true
  end
  return {
    track_id = param_track_id,
    fx_id = param_fx_id,
    id = param_id,
    track = param_track,
    fx_name = par_fx_name,
    name = par_name,
    valid = valid,
    norm_value = param_norm_value,
    format_value = format_value
  }
end

function get_fx_data(track)
  local fx_data = {}
  if track then
    local fx_count = reaper.TrackFX_GetCount(track)
    for i = 0, fx_count - 1 do
      local fd = get_fx_data_at_index(track, i)
      table.insert(fx_data, fd)
    end
  end
  return fx_data
end

function get_FX_GUID_map(track)
  local GUID_map = {}
  local fx_count = reaper.TrackFX_GetCount(track)
  for i = 0, fx_count - 1 do
    local GUID = reaper.TrackFX_GetFXGUID(track, i)
    GUID_map[GUID] = i
  end
  return GUID_map
end

function get_random_parameters_2(focused_fx_data, fx, num)
  local list = focused_fx_data.list
  local num_params = reaper.TrackFX_GetNumParams(fx.track, fx.id)
  local allowed_params = {}
  local final_params = {}
  for i = 0, num_params - 1 do
    local par = get_parameter(fx.track_id, fx.id, i)
    if focused_fx_data.is_whitelist then
      for j = 1, #list do
        if par.name == list[j] then
          table.insert(allowed_params, par)
          break
        end
      end
    else
      if not table_has_value(list, par.name) and
      not parameter_is_blacklisted(blacklist, par.name) then
        table.insert(allowed_params, par)
      end
    end
  end
  if #allowed_params == 0 then return false, nil end
  local par_count = math.random(math.min(#allowed_params, num))
  while #final_params < par_count do
    local ind = math.random(#allowed_params)
    table.insert(final_params, allowed_params[ind])
    table.remove(allowed_params, ind)
  end
  return true, final_params
end

function push_realimit(track)
  local ind = reaper.TrackFX_AddByName(track, "ReaLimit", false, 0)
  if realimit and ind == -1 then realimit = false return end
  local fx_count = reaper.TrackFX_GetCount(track)
  if ind ~= -1 and ind ~= fx_count - 1 then
    local ret, name = reaper.TrackFX_GetFXName(track, fx_count - 1)
    name = trim_fx_name(name)
    if name ~= "ReaLimit" then
      reaper.TrackFX_CopyToTrack(track, ind, track, fx_count, true)
    end
  end
end

local dev_pattern = '%s%(.+%)'
local plug_prefix = '.+%:%s'
function trim_fx_name(name)
  local n = name:gsub(plug_prefix, '')
  n = n:gsub(dev_pattern, '')
  return n
end

function get_parsed_plugin_name(s)
  local t = str_split(s, ' ')
  table.remove(t, 1)
  local fs = table.concat(t, '_')
  return fs
end