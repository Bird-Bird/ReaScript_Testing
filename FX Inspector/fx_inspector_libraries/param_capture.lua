-- @noindex

--RETROSPECTIVE PARAMETER CAPTURE
function create_edge_points(env, s, e)
  local r, sv = reaper.Envelope_Evaluate(env, s, 0, 0)
  local r, ev = reaper.Envelope_Evaluate(env, e, 0, 0)
  reaper.InsertEnvelopePoint(env, s, sv, 0, 0, false, true)
  reaper.InsertEnvelopePoint(env, e, ev, 0, 0, false, true)
end

function get_new_retro_parameter(par)
  return {par = par, values = {}, writer = 1, timestamps = {}}
end

local record_len = 10
local record_sr  = 30
local buf_len = record_len * record_sr
function write_parameter_value(pb)
  local par = pb.par
  local buf = pb.values
  local ts = pb.timestamps
  local w = pb.writer

  buf[w] = par.norm_value
  ts[w] = reaper.time_precise()

  w = w + 1
  if w > buf_len then
      w = 1
  end
  pb.writer = w
end

function write_buffer_to_envelope(track, env, pb, pos)
  local par = pb.par
  local buf = pb.values
  local ts = pb.timestamps
  local w = pb.writer

  --CLEAR ENVELOPE RANGE
  local start_ts, end_ts, offs
  if #buf == buf_len then
    start_ts = ts[w]
    end_ts = ts[w-1]
  else
    start_ts = ts[1]
    end_ts = ts[#ts]
    w = 1
  end
  if not end_ts then return end
  offs = end_ts - start_ts
  local f = 0.000001
  
  reaper.Undo_BeginBlock()
  create_edge_points(env, pos - f, pos + offs + f)
  reaper.DeleteEnvelopePointRange(env, pos, pos + offs)
  reaper.Envelope_SortPoints(env)

  --GET MIN/MAX VALUES FOR ENVELOPE
  local br_env = reaper.BR_EnvAlloc(env, true)
  local _, _, _, _, _, _,
  min, max, _, _, fader_scaling, _ = reaper.BR_EnvGetProperties(br_env)
  reaper.BR_EnvFree(br_env, false)
  
  --INSERT POINTS
  local l_val = -1
  for i = w, w + (#buf-1) do
    local t = i > buf_len and i - buf_len or i
    local p_ts = ts[t]
    local p_val = buf[t]
    local t_offs = p_ts - start_ts

    --FILTER IDENTICAL POINTS
    local n_val = buf[t+1] and buf[t+1] or nil
    if not (l_val == p_val and p_val == n_val) or i == w + (#buf-1) then
      local r_val = min + ((max - min)*p_val)
      if fader_scaling then
        r_val = reaper.ScaleToEnvelopeMode(1, r_val)
      end
      reaper.InsertEnvelopePoint(env, pos + t_offs, r_val, 0, 0, false, true)
    end
    l_val = p_val
  end
  reaper.Envelope_SortPoints(env)
  reaper.Undo_EndBlock('Insert retrospective parameter buffer', -1)
end

function write_buffer_at_edit_cursor(param)
  local par = param.par
  local env = toggle_fx_envelope_visibility(par.track, par.fx_id, par.id)
  local cur_pos =  reaper.GetCursorPosition()
  write_buffer_to_envelope(par.track, env, param, cur_pos) 
end