-- @noindex

--FX
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
    name = name, 
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

local seed = reaper.time_precise()
function init_random()
  math.randomseed(seed)
  math.random()
  math.random()
  math.random()
end
init_random()

function randomize_parameters(fx)
  local num_params = reaper.TrackFX_GetNumParams(fx.track, fx.id)
  for i = 0, num_params - 1 do
    local _, par_name = reaper.TrackFX_GetParamName(fx.track, fx.id, i)
    if not parameter_is_blacklisted(par_name) then
      reaper.TrackFX_SetParamNormalized(fx.track, fx.id, i, math.random())
    end
  end
end

--https://forum.cockos.com/showpost.php?p=1631978&postcount=10
function toggle_fx_envelope_visibility(tr, fx_index, par_index)
  local fx_env = reaper.GetFXEnvelope(tr, fx_index, par_index, true)
  if fx_env ~= nil or true then
    local br_env = reaper.BR_EnvAlloc(fx_env, true)
    local active, visible, armed, in_lane, lane_height, default_shape, min_val, max_val, center_val, env_type, fader_scale = reaper.BR_EnvGetProperties(br_env)
    reaper.BR_EnvSetProperties(br_env, true, true, armed, in_lane, lane_height, default_shape, fader_scale)
    reaper.BR_EnvFree(br_env, true)
  end
  reaper.TrackList_AdjustWindows(false)
  return fx_env
end

function get_hovered_envelope_name()
  local x, y = reaper.GetMousePosition()
  local track, info = reaper.GetThingFromPoint(x, y)
  if info:match("envelope") then
    local envidx = tonumber(info:match("%d+"))
    if envidx then
      return ({reaper.GetEnvelopeName( reaper.GetTrackEnvelope( track, envidx ) )})[2]
    end
  end
  return nil
end

--SIDECHAIN HANDLING
function get_tracklist()
  local tracks = {}
  local track_count = reaper.CountTracks(0)
  for i = 0, track_count - 1 do 
    local track = reaper.GetTrack(0, i)
    local r, name = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', '', false)
    local to = {track = track, name = name, id = i, selected = false}
    table.insert(tracks, to)
  end
  return tracks
end

function bits(num,bits)
  bits = bits or math.max(1, select(2, math.frexp(num)))
  local t = {}       
  for b = bits, 1, -1 do
    t[b] = math.fmod(num, 2)
    num = math.floor((num - t[b]) / 2)
  end
  return t
end

function create_sidechain(source_tracks, fx, chs)
  local channels = channels or {3,4}
  local is_melda = string.find(fx.name, "Melda")
  
  --INSERT NEW TRACK CHANNEL
  local num_channels = reaper.GetMediaTrackInfo_Value(fx.track, 'I_NCHAN')
  num_channels = num_channels + 2
  reaper.SetMediaTrackInfo_Value(fx.track, 'I_NCHAN', num_channels)
  if is_melda then
    channels = {num_channels + 1, num_channels + 2}
  end
  
  --CREATE SENDS
  for i = 1, #source_tracks do
    local t = source_tracks[i]
    local send_id = reaper.CreateTrackSend(t.track, fx.track)
    reaper.SetTrackSendInfo_Value(t.track, 0, send_id, 'I_DSTCHAN', num_channels-2)
  end

  --SET PINS
  for i = 1, #channels do
    local chan = channels[i] - 1
    if is_melda then 
      --CLEAR MAPPINGS
      reaper.TrackFX_SetPinMappings(fx.track, fx.id, 0, chan, 0, 0)
    end    
    local mask, high32 = reaper.TrackFX_GetPinMappings(fx.track, fx.id, 0, chan)
    local new_mask = mask | 2^(num_channels+i-3)
    reaper.TrackFX_SetPinMappings(fx.track, fx.id, 0, chan, new_mask, high32)
  end
end

function get_empty_sidechain()
  return {selected_tracks = {}, tracklist = {}}
end

function get_fx_data(track)
  local fx_data = {}
  if track then
    local fx_count = reaper.TrackFX_GetCount(track)
    for i = 0, fx_count - 1 do
      local r, name = reaper.TrackFX_GetFXName(track, i)
      local trimmed_name = trim_fx_name(name)
      local visible = reaper.TrackFX_GetOpen(track, i)
      local enabled = reaper.TrackFX_GetEnabled(track, i)
      local fd = {
        name = trimmed_name,
        full_name = name,
        visible = visible,
        id = i,
        enabled = enabled
      }
      table.insert(fx_data, fd)
    end
  end
  return fx_data
end

local dev_pattern = '%s%(.+%)'
local plug_prefix = '.+%:%s'
function trim_fx_name(name)
  local n = name:gsub(plug_prefix, '')
  n = n:gsub(dev_pattern, '')
  return n
end
