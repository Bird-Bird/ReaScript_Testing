-- @noindex
-- @version 0.99.3

function reaper_do_file(file) local info = debug.getinfo(1,'S'); local path = info.source:match[[^@?(.*[\/])[^\/]-$]]; dofile(path .. file); end
reaper_do_file('json.lua')

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

function get_empty_state()
    return {versions = {}, data = {}}
end

local ext_name = 'P_EXT:BB_Track_Versions'
function get_ext_state(track)
    local retval, ext_state = reaper.GetSetMediaTrackInfo_String(track, ext_name, "", false)
    if ext_state == '' then
        return get_empty_state()
    else
        return json.decode(ext_state)
    end
end

function set_ext_state(track, state)
    local s = json.encode(state)
    reaper.GetSetMediaTrackInfo_String(track, ext_name, s, true)
end

function create_new_version(track, state)
    set_ext_state(track, state)
end

function clear_items(track)
    local item_count = reaper.CountTrackMediaItems(track)
    for i = 1, item_count do
        local item = reaper.GetTrackMediaItem(track, 0)
        reaper.DeleteTrackMediaItem(track, item)
    end
end

function load_chunk(track, item_chunks)
    clear_items(track)
    
    --INSERT ITEMS FROM CHUNKS
    for i = 1, #item_chunks do
        local chunk = item_chunks[i]
        local item = reaper.AddMediaItemToTrack(track)
        reaper.SetItemStateChunk(item, chunk, false)
    end
end

function get_item_chunks(chunk_lines)
    --GET ITEM CHUNKS
    local item_chunks = {}
    local last_item_chunk = -1
    local current_scope = 0
    local i = 1
    while i <= #chunk_lines do
        local line = chunk_lines[i]
        
        --MANAGE SCOPE
        local scope_end = false
        if string.starts(line, '<ITEM') then       
            last_item_chunk = i
            current_scope = current_scope + 1
        elseif string.starts(line, '<') then
            current_scope = current_scope + 1
        elseif string.starts(line, '>') then
            current_scope = current_scope - 1
            scope_end = true
        end
        
        --GRAB ITEM CHUNKS
        if current_scope == 1 and last_item_chunk ~= -1 and scope_end then
            local s = ''
            for j = last_item_chunk, i do
                s = s .. chunk_lines[j] .. '\n'
            end
            last_item_chunk = -1
            table.insert(item_chunks, s)
        end
        i = i + 1
    end

    return item_chunks
end

--FUNCTIONS
function switch_versions(track, state, selected_id)
    --SAVE CURRENT VERSION TO STATE
    local retval, chunk = reaper.GetTrackStateChunk(track, "", false)
    local chunk_lines = str_split(chunk, '\n')
    local item_chunks = get_item_chunks(chunk_lines)
    state.versions[state.data.selected] = item_chunks

    --SWITCH VERSION
    local i = selected_id
    local t_chunk = state.versions[i]
    state.data.selected = i
    
    load_chunk(track, t_chunk)
    set_ext_state(track, state)
end

function add_new_version(track, state, clear)
    --NEW VERSION
    local retval, chunk = reaper.GetTrackStateChunk(track, "", false)
    local chunk_lines = str_split(chunk, '\n')
    local item_chunks = get_item_chunks(chunk_lines)
    if #state.versions > 0 then
        state.versions[state.data.selected] = item_chunks
    end
    
    --CREATE NEW VERSION
    state.versions[#state.versions+1] = item_chunks
    state.data.selected = #state.versions
    create_new_version(track, state)

    --CLEAR ITEMS
    if clear then
        clear_items(track)
    end
end

function collapse_versions(track, state)
    local new_state = get_empty_state()
    add_new_version(track, new_state)
end

function get_selected_tracks()
    local all_selected = true
    local last_selected = -1

    local tracks = {}
    local min_versions = 65532
    local selected_track_count = reaper.CountSelectedTracks(0)
    for i = 0, selected_track_count - 1 do
        local track = reaper.GetSelectedTrack(0, i)
        local state = get_ext_state(track)

        --INIT EMPTY TRACKS
        if #state.versions == 0 then
            local retval, chunk = reaper.GetTrackStateChunk(track, "", false)
            local chunk_lines = str_split(chunk, '\n')
            local item_chunks = get_item_chunks(chunk_lines)
            state.versions[#state.versions+1] = item_chunks
            state.data.selected = #state.versions
            create_new_version(track, state)
        end
        
        min_versions = math.min(#state.versions, min_versions)
        if i > 0 then
            all_selected = all_selected and (state.data.selected == last_selected)
        end
        
        tracks[i+1] = {}
        tracks[i+1].track = track
        tracks[i+1].state = state

        last_selected = state.data.selected
    end

    return tracks, min_versions, all_selected and last_selected or -1
end