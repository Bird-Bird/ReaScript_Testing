-- @noindex
function reaper_do_file(file) local info = debug.getinfo(1,'S'); local path = info.source:match[[^@?(.*[\/])[^\/]-$]]; dofile(path .. file); end
reaper_do_file('json.lua')

function open_url(url)
    local OS = reaper.GetOS()
    if (OS == "OSX32" or OS == "OSX64") or OS == 'macOS-arm64' then
        os.execute('open "" "' .. url .. '"')
    else
        os.execute('start "" "' .. url .. '"')
    end
end

--USER SETTINGS
function table.shallow_copy(t)
    local t2 = {}
    for k,v in pairs(t) do
        t2[k] = v
    end
    return t2
end

local info = debug.getinfo(1,'S')
local path = info.source:match[[^@?(.*[\/])[^\/]-$]]
local default_settings = {
    enable_preset_edits = false,
    show_random_button = true,
    show_parameter_capture = true,
    show_presets = true
}
function get_settings()
    local file_name = 'settings.json'
    local settings = io.open(path .. file_name, 'r')
    if not settings then
        return table.shallow_copy(default_settings)
    else
        local st = settings:read("*all")
        st_json = json.decode(st)
        return st_json
    end
end

function save_settings(data)
    local settings = io.open(path .. 'settings.json', 'w')
    local d = json.encode(data)
    settings:write(d)
    settings:close()
end


--UTILITY
function str_split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

function string.starts(String,Start)
    return string.sub(String,1,string.len(Start))==Start
end

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

function str_split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

function rgba2num(red, green, blue, alpha)
    local blue = blue * 256
    local green = green * 256 * 256
    local red = red * 256 * 256 * 256
    return red + green + blue + alpha
end

--https://stackoverflow.com/a/42062321
function print_table(node)
    local cache, stack, output = {},{},{}
    local depth = 1
    local output_str = "{\n"
    while true do
        local size = 0
        for k,v in pairs(node) do
            size = size + 1
        end
        local cur_index = 1
        for k,v in pairs(node) do
            if (cache[node] == nil) or (cur_index >= cache[node]) then
                if (string.find(output_str,"}",output_str:len())) then
                    output_str = output_str .. ",\n"
                elseif not (string.find(output_str,"\n",output_str:len())) then
                    output_str = output_str .. "\n"
                end
                table.insert(output,output_str)
                output_str = ""

                local key
                if (type(k) == "number" or type(k) == "boolean") then
                    key = "["..tostring(k).."]"
                else
                    key = "['"..tostring(k).."']"
                end

                if (type(v) == "number" or type(v) == "boolean") then
                    output_str = output_str .. string.rep('\t',depth) .. key .. " = "..tostring(v)
                elseif (type(v) == "table") then
                    output_str = output_str .. string.rep('\t',depth) .. key .. " = {\n"
                    table.insert(stack,node)
                    table.insert(stack,v)
                    cache[node] = cur_index+1
                    break
                else
                    output_str = output_str .. string.rep('\t',depth) .. key .. " = '"..tostring(v).."'"
                end

                if (cur_index == size) then
                    output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
                else
                    output_str = output_str .. ","
                end
            else
                -- close the table
                if (cur_index == size) then
                    output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
                end
            end
            cur_index = cur_index + 1
        end
        if (size == 0) then
            output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
        end
        if (#stack > 0) then
            node = stack[#stack]
            stack[#stack] = nil
            depth = cache[node] == nil and depth + 1 or depth - 1
        else
            break
        end
    end

    table.insert(output,output_str)
    output_str = table.concat(output)
    p(output_str)
end

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
        reaper.TrackFX_SetParamNormalized(fx.track, fx.id, i, math.random())
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

--PRESET PARSING
function parse_ini_file(name)
    local presets_file = io.open(name, 'r')
    if presets_file then
        --READ LINES
        local f = presets_file:read("*all")
        io.close(presets_file)
        local lines = str_split(f, '\n')
        
        --GRAB PRESET DATA
        local pd = {presets = {}, file_name = name, name_lookup = {}}
        for i = 3, #lines do
            local line = lines[i]
            if string.starts(line, '[Preset') then
                --NEW PRESET
                table.insert(pd.presets, {data = {}})
            elseif string.starts(line, 'Name') then
                --NAME
                local n = str_split(line, '=')[2]
                pd.presets[#pd.presets].name = n
                pd.name_lookup[n] = 1
            elseif string.starts(line, 'Len') then
                --LENGTH
                local len = str_split(line, '=')[2]
                pd.presets[#pd.presets].len = len
            elseif string.starts(line, "Ext") then
                --EXT DATA
                pd.ext = line:sub(5)
            elseif string.starts(line, 'Data') then
                --DATA BLOB
                table.insert(pd.presets[#pd.presets].data, line)
            end
            i = i+1
        end
        return pd
    else
        return nil
    end
end

function generate_preset_ini(pd)
    local s = ''
    local presets = pd.presets

    --HEADER
    s = s .. '[General]\n'
    if pd.ext then s = s .. 'Ext=' .. pd.ext .. '\n' end
    s = s .. 'NbPresets=' .. #presets .. '\n\n'
    
    --PRESETS
    for i = 1, #presets do
        local preset = presets[i]
        local dat = preset.data
        
        --PRESET HEADER
        s = s .. '[Preset' .. i - 1 .. ']\n'

        --DATA
        s = s .. table.concat(dat, '\n') .. '\n'
        s = s .. 'Len=' ..  preset.len .. '\n'
        s = s .. 'Name=' .. preset.name .. '\n\n'
    end
    preset_file = io.open(pd.file_name, 'w')
    preset_file:write(s)
    preset_file:close()
end

function validate_preset_name(pd, s)
    if pd.name_lookup[s] then
        return false, 'A preset with the same name already exists.'
    elseif s == '' then
        return false, 'Preset names cannot be empty.'
    else
        return true
    end
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
         --WHY, ALEKSEY
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

local record_len = 5
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
    offs = end_ts - start_ts
    local f = 0.000001
    
    reaper.Undo_BeginBlock()
    create_edge_points(env, pos - f, pos + offs + f)
    reaper.DeleteEnvelopePointRange(env, pos, pos + offs)
    reaper.Envelope_SortPoints(env)
    
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
            reaper.InsertEnvelopePoint(env, pos + t_offs, p_val, 0, 0, false, true)
        end
        l_val = p_val
    end
    reaper.Envelope_SortPoints(env)
    reaper.Undo_EndBlock('Insert retrospective parameter buffer', -1)
end