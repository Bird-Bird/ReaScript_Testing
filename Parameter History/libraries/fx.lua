-- @noindex

--https://forum.cockos.com/showpost.php?p=1631978&postcount=10
function toggle_fx_envelope_visibility(tr, fx_index, par_index)
  local fx_env = reaper.GetFXEnvelope(tr, fx_index, par_index, false)
  local valid_env_pointer = reaper.ValidatePtr2(0, fx_env, "TrackEnvelope*")
  if not valid_env_pointer then
    fx_env = reaper.GetFXEnvelope(tr, fx_index, par_index, true)
    reaper.TrackList_AdjustWindows(false)
    return
  end
  if fx_env ~= nil then
    local br_env = reaper.BR_EnvAlloc(fx_env, true)
    local active, visible, armed, in_lane, lane_height, default_shape, min_val, max_val, center_val, env_type, fader_scale = reaper.BR_EnvGetProperties(br_env)
    reaper.BR_EnvSetProperties(br_env, active, not visible, armed, in_lane, lane_height, default_shape, fader_scale)
    reaper.BR_EnvFree(br_env, true)
  end
  reaper.TrackList_AdjustWindows(false)
end