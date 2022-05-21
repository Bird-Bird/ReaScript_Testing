-- @noindex

function get_track_by_GUID(GUID)
  for i = 0, reaper.CountTracks(proj) - 1 do
    local track = reaper.GetTrack(0, i)
    local track_GUID = reaper.GetTrackGUID(track)
    if GUID == track_GUID then
      return track
    end
  end
end

function save_pins(pins)
  local t = deepcopy(pins)
  for i = 1, #t do t[i].track = "" end
  local t_json = json.encode(t)
  reaper.SetProjExtState(0, "BB_Param_History", "pins", t_json)
end

function load_pins()
  local pins, pins_map = {}, {}
  local r, val = reaper.GetProjExtState(0, "BB_Param_History", "pins")
  if r and val ~= "" then
    local pins_load = json.decode(val)
    local f_pins = {}
    for i = 1, #pins_load do
      local pin = pins_load[i]
      local track = get_track_by_GUID(pin.track_GUID)
      if track then 
        pin.track = track
        table.insert(f_pins, pin)
        pins_map[pin.param_identifier] = pin
      end
    end
    pins = f_pins
  end
  return pins, pins_map
end

function remove_parameter_from_pins(pins, pins_map, p)
  pins_map[p.param_identifier] = nil
  for i = #pins, 1, -1 do
    local par = pins[i]
    if p.param_identifier == par.param_identifier then
      pins_map[p.param_identifier] = nil
      table.remove(pins, i)
    end
  end
  save_pins(pins)
end

function insert_parameter_to_pins(pins, pins_map, p)
  table.insert(pins, 1, p)
  pins_map[p.param_identifier] = p
  save_pins(pins, pins_map)
end