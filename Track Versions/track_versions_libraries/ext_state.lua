--@noindex

--EXT_STATE
local ext_name = 'P_EXT:BB_Track_Versions'
local ext_name_ver = 'P_EXT:BB_Track_Versions_Num'

function get_empty_state()
    return {versions = {}, data = {selected = 1}}
end

function get_empty_state_query()
    return {num_versions = 0, selected = 0, load_fx = false} 
end

function gen_query_state(state, query)
    return {
        num_versions = #state.versions,
        selected = state.data.selected,
        load_fx = query.load_fx
    }
end

function init_version_num(track, state)
    --FOR BACKWARDS COMPATIBITY WITH GUI
    local retval, ext_state = reaper.GetSetMediaTrackInfo_String(track, ext_name_ver, "", false)
    if ext_state == '' then
        local s = gen_query_state(state)
        reaper.GetSetMediaTrackInfo_String(track, ext_name_ver, s, true)    
    end
end

function get_ext_state(track)
    local retval, ext_state = reaper.GetSetMediaTrackInfo_String(track, ext_name, "", false)
    if ext_state == '' then
        return get_empty_state()
    else
        local s = json.decode(ext_state)
        init_version_num(track, s)
        return s
    end
end

function get_ext_state_query(track)
    local retval, ext_state = reaper.GetSetMediaTrackInfo_String(track, ext_name_ver, "", false)
    if ext_state == '' then
        return get_empty_state_query()
    else
        local s = json.decode(ext_state)
        return s
    end
end

function set_ext_state(track, state)
    local s = json.encode(state)
    
    local qs = get_ext_state_query(track)
    local sv = json.encode(gen_query_state(state, qs))
    
    reaper.GetSetMediaTrackInfo_String(track, ext_name, s, true)
    reaper.GetSetMediaTrackInfo_String(track, ext_name_ver, sv, true)
end

function save_track_query(track, query)
    local sv = json.encode(query)
    reaper.GetSetMediaTrackInfo_String(track, ext_name_ver, sv, true)
end