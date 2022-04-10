-- @noindex

function reaper_do_file(file) local info = debug.getinfo(1,'S'); local path = info.source:match[[^@?(.*[\/])[^\/]-$]]; dofile(path .. file); end
reaper_do_file('json.lua')
reaper_do_file('chunk_parsing.lua')
reaper_do_file('settings.lua')
reaper_do_file('ext_state.lua')
reaper_do_file('versions.lua')

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

--TRACKS
local pattern = "v%d+%s%-%s"
local pattern_2 = "v%d+%s%-"
function prefix_track(track, id)
    local r, name = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', '', false)
    local name = name:gsub(pattern, "")
    name = name:gsub(pattern_2, "")
    name = "v" .. tostring(id) .. " - " .. name
    reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', name, true)
end

--DEPRECATE
function prefix_tracks(tracks, init, init_version_data)
    local init_data = {}
    for i = 1, #tracks do 
        local track = tracks[i].track
        local state = tracks[i].state
        if #state.versions > 1 then
            prefix_track(track, math.floor(state.data.selected))
        elseif not init and init_version_data[track] - #state.versions > 0 then
            prefix_track(track, math.floor(state.data.selected))
        end
        if init then
            init_data[track] = #state.versions
        end
    end
    return init_data
end

function prefix_track_fast(track)
    local q = get_ext_state_query(track)
    prefix_track(track, q.selected)
end

--DEPRECATE
function get_selected_tracks()
    local all_selected = true
    local last_selected = -1

    local tracks = {}
    local min_versions = math.huge
    local selected_track_count = reaper.CountSelectedTracks(0)
    for i = 0, selected_track_count - 1 do
        local track = reaper.GetSelectedTrack(0, i)
        local state = get_ext_state(track)

        --INIT EMPTY TRACKS
        if #state.versions == 0 then
            add_new_version(track, state, false)
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

function get_selected_tracks_fast()
    local track_count = reaper.CountSelectedTracks(0)
    if track_count == 0 then return {}, 0, -1 end

    local t = {}
    local min_versions = math.huge
    local max_versions = 0
    local common_sel = -1
    for i = 0, track_count - 1 do
        local track = reaper.GetSelectedTrack(0, i)
        local query = get_ext_state_query(track)
        if query.num_versions == 0 then query.num_versions = 1 end
        table.insert(t, {track = track, query = query})
        
        min_versions = math.min(min_versions, query.num_versions)
        max_versions = math.max(max_versions, query.num_versions)

        if common_sel == -1 then 
            common_sel = query.selected 
        elseif common_sel ~= -1 and query.selected ~= common_sel then
            common_sel = 0
        end
    end
    local no_versions = max_versions == 0
    return t, min_versions, common_sel, no_versions
end


--ITEMS
function get_track_media_items(track)
    local items = {}
    local item_count = reaper.CountTrackMediaItems(track)
    for i = 0, item_count - 1 do 
        local item = reaper.GetTrackMediaItem(track, i)
        table.insert(items, item)
    end
    return items
end

function delete_item_range(track, sp, ep)
    --SPLIT RANGE
    local items = get_track_media_items(track)
    for i = 1, #items do
        local item = items[i]
        local new_item = reaper.SplitMediaItem(item, sp)
        if new_item then
            reaper.SplitMediaItem(new_item, ep)
        else
            reaper.SplitMediaItem(item, ep)
        end
    end

    --CLEAR RANGE
    items = get_track_media_items(track)
    for i = 1, #items do 
        local item = items[i]
        local pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
        if pos >= sp and pos < ep then
            reaper.DeleteTrackMediaItem(track, item)
        end
    end
end

function clear_items(track)
    local item_count = reaper.CountTrackMediaItems(track)
    for i = 1, item_count do
        local item = reaper.GetTrackMediaItem(track, 0)
        reaper.DeleteTrackMediaItem(track, item)
    end
end

function trim_item_right_edge(track, item, pos)
    local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local item_end = item_pos + item_len
    
    local edge = item_end - pos
    if edge > 0 then
        reaper.SetMediaItemInfo_Value(item, "D_LENGTH", item_len - edge)
    end
end

function trim_item_left_edge(track, item, pos)
    local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local item_end = item_pos + item_len
    if item_pos < pos then
        local new_item = reaper.SplitMediaItem(item, pos)
        reaper.DeleteTrackMediaItem(track, item)
        return new_item
    else
        return item
    end
end

function delete_out_of_bounds_item(track, item, s, e)
    local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local item_end = item_pos + item_len
    if item_pos >= e then
        reaper.DeleteTrackMediaItem(track, item)
        return true
    elseif item_end <= s then
        reaper.DeleteTrackMediaItem(track, item)
        return true
    end
    return false
end

function get_razor_edits(track)
    local razor_edits = {}
    local retval, re = reaper.GetSetMediaTrackInfo_String( track, 'P_RAZOREDITS', '', false)
    local re_buf = str_split(re, ' ')
    local i = 1
    while i < #re_buf do
        local razor_start = tonumber(re_buf[i])
        local razor_end = tonumber(re_buf[i+1])
        table.insert(razor_edits, {s = razor_start, e = razor_end})
        i = i + 3
    end
    return razor_edits
end
