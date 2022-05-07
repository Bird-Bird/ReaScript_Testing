-- @noindex

function get_new_group(fx_data, max_param_count, override)
  if #fx_data == 1 and fx_data[1].name == "ReaLimit" then return end
  local group, attempts = {}, 0
  local num_fx, ind, ind_map = math.max(1, math.random(#fx_data)), {}, {}
  
  if not override then
    while #ind_map == 0 and attempts < 1000 do
      for i = 1, num_fx do
        local rnd = math.random(#fx_data)
        if not ind_map[rnd] and fx_data[rnd].name ~= "ReaLimit" then
          table.insert(ind, rnd) 
          ind_map[rnd] = true
        end
      end
      attempts = attempts + 1
    end
  else
    for i = 1, #fx_data do 
      table.insert(ind, i) 
    end
  end
  local fx_data_map = {}
  for i = 1, #ind do
    local fx = fx_data[ind[i]]
    if not fx_data_map[fx.name] then
      fx_data_map[fx.name] = get_focused_fx_data(fx)
    end
     
    local g, success = {}, false
    g.fx = fx
    success, g.params = get_random_parameters_2(fx_data_map[fx.name], fx, max_param_count)
    if success then
      table.insert(group, g)
    end
  end
  group.val    = 0
  group.mix    = 1
  group.random = 0
  group.seed   = math.random() * 100
  
  return group
end

function do_group(group_fx, offset)
  for i = 1, #group_fx do
    local group = group_fx[i]
    local fx, params = group.fx, group.params
    for i = 1, #params do
      local param = params[i]
      reaper.TrackFX_SetParamNormalized(fx.track, fx.id, param.id, param.norm_value + offset)
    end
  end
end

function validate_groups(track, mangler_groups)
  local GUID_map = get_FX_GUID_map(track)
  for i = #mangler_groups, 1, -1 do
    local group_fx = mangler_groups[i]
    for j = #group_fx, 1, -1 do
      local group = group_fx[j]
      local GUID = group.fx.GUID
      if not GUID_map[GUID] then
        table.remove(group_fx, j)
      else
        group.fx.id = GUID_map[GUID]
      end
    end
    if #group_fx == 0 then table.remove(mangler_groups, i) end
  end
end

function reset_groups(mangler_groups)
  for i = #mangler_groups, 1, -1 do
    local group_fx = mangler_groups[i]
    group_fx.val = 0
    group_fx.random = 0
    group_fx.mix = 1
    for j = #group_fx, 1, -1 do
      local group = group_fx[j]
      local fx = group.fx
      local params = group.params
      for i = 1, #params do
        local param_old = params[i]
        params[i] = get_parameter(fx.track_id, fx.id, param_old.id)
      end
    end
  end
end

function reset_groups_to_initial_state(mangler_groups)
  local param_map = {}
  
  for i = 1, #mangler_groups do
    local group_fx = mangler_groups[i]
    group_fx.val = 0
    group_fx.random = 0
    group_fx.mix = 1
    for j = 1, #group_fx do
      local group = group_fx[j]
      local fx = group.fx
      local params = group.params
      for i = 1, #params do
        local param = params[i]
        if not param_map[fx.id .. ' | ' .. param.id] then
          param_map[fx.id .. ' | ' .. param.id] = {fx = fx, param = param}
        end        
      end
    end
  end

  for k, dat in pairs(param_map) do 
    local fx, param = dat.fx, dat.param
    reaper.TrackFX_SetParamNormalized(fx.track, fx.id, param.id, param.norm_value)
  end
end

function build_parameter_map_from_groups(mangler_groups)
  local param_map = {}
  for i = 1, #mangler_groups do
    local group_fx = mangler_groups[i]
    for j = 1, #group_fx do
      local group = group_fx[j]
      local fx = group.fx
      for k = 1, #group.params do
        local param = group.params[k]
        local id = fx.id .. '|' .. param.id
        local map 
        if param_map[id] then
          map = param_map[id]
        else
          param_map[id] = {
            fx     = fx,
            param  = param,
            values = {},
          }
          map = param_map[id]
        end
        
        local raw_v = group_fx.val
        local seed = (((param.id+1.1) ^ 2.2)/((fx.id + 1) ^ 4)) * 1.3 + group_fx.seed
        random_seed(seed)
        local rnd_val = (math.random() - 0.5)*2*group_fx.random
        table.insert(map.values, (raw_v + rnd_val)*group_fx.mix)
      end
    end
  end
  return param_map
end

function lerp(a, b, t) 
  return a + (b - a)*t
end

function do_parameter_map(parameter_map)
  for k, tweak in pairs(parameter_map) do
    local fx, param, values, sum = tweak.fx, tweak.param, tweak.values, 0
    for i = 1, #values do
      sum = sum + values[i]
    end
    reaper.TrackFX_SetParamNormalized(fx.track, fx.id, param.id, param.norm_value + sum)
  end
end