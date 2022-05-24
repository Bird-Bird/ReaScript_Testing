-- @noindex

function p(msg) reaper.ShowConsoleMsg(tostring(msg) .. '\n') end
function reaper_do_file(file) local info = debug.getinfo(1,'S'); path = info.source:match[[^@?(.*[\/])[^\/]-$]]; dofile(path .. file); end

--UTILITY
function table.shallow_copy(t)
    local t2 = {}
    for k,v in pairs(t) do
        t2[k] = v
    end
    return t2
end

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

function rgba2num(red, green, blue, alpha)
    local blue = blue * 256
    local green = green * 256 * 256
    local red = red * 256 * 256 * 256
    return red + green + blue + alpha
end

function palette(t, alpha)
    local t = t + 0.4
    local a = {r = 0.5, g = 0.5, b = 0.5}
    local b = {r = 0.5, g = 0.5, b = 0.5}
    local c = {r = 1, g = 1, b = 1}
    local d = {r = 0, g = 0.33, b = 0.67}

    local brightness = 0.2
    
    local r = math.floor(math.min(a.r + brightness + math.cos((c.r*t + d.r)*6.28318)*b.r,1)*255)
    local g = math.floor(math.min(a.g + brightness + math.cos((c.g*t + d.g)*6.28318)*b.g,1)*255)
    local b = math.floor(math.min(a.b + brightness + math.cos((c.b*t + d.b)*6.28318)*b.b,1)*255)
    local im_col = rgba2num(r, g, b, math.floor(255*alpha))
    return im_col
end

function get_shift()
  local key_mods = reaper.ImGui_GetKeyMods(ctx)
  local mod = reaper.ImGui_KeyModFlags_Shift and reaper.ImGui_KeyModFlags_Shift() or reaper.ImGui_ModFlags_Shift()
  return (key_mods & mod) ~= 0 
end

--BLACKLIST
local info = debug.getinfo(1,'S')
local path = info.source:match[[^@?(.*[\/])[^\/]-$]]

local default_blacklist = {}
function get_blacklist()
    local file_name = 'blacklist.json'
    local settings = io.open(path .. file_name, 'r')
    if not settings then
        return table.shallow_copy(default_blacklist)
    else
        local st = settings:read("*all")
        st_json = json.decode(st)
        return st_json
    end
end

function save_blacklist(data)
    local settings = io.open(path .. 'blacklist.json', 'w')
    local d = json.encode(data)
    settings:write(d)
    settings:close()
end
blacklist = get_blacklist()

--SETTINGS
local default_settings = {
    auto_load_tags_merge = true,
    auto_hide_tracks_when_tag_active = true,
    auto_tag_tracks = false,
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

function is_in_blacklist(name)
    for i = 1, #blacklist do
        if blacklist[i] == name then
            return true
        end
    end
    return false
end

function track_is_blacklisted(track)
    local r, name = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', '', false)
    return is_in_blacklist(name)
end


--EXTSTATE
function get_empty_state()
    return {tags = {}, lock_visibility = false}
end

local ext_name = 'P_EXT:BB_Track_Tags'
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

--TRACK
function get_selected_tracks()
    local tracks = {}
    local track_count = reaper.CountSelectedTracks(0)
    for i = 0, track_count - 1 do
        local track = reaper.GetSelectedTrack(0, i)
        table.insert(tracks, track)
    end
    return tracks
end

function get_all_tracks()
    local tracks = {}
    local track_count = reaper.CountTracks(0)
    for i = 0, track_count - 1 do
        local track = reaper.GetTrack(0, i)
        table.insert(tracks, track)
    end
    return tracks
end

function count_table(t)
    n = 0
    for k,v in pairs(t) do
        n = n + 1
    end
    return n
end

function is_track_visible(track)
    local track_visible = reaper.GetMediaTrackInfo_Value(track, 'B_SHOWINTCP')
    return track_visible == 1
end

--BLACKLIST/LOCK
function set_track_visible(track, ext, state, override)
    local ext = ext and ext or get_ext_state(track)
    if override or not (ext.lock_visibility or track_is_blacklisted(track)) then
        reaper.SetMediaTrackInfo_Value(track, 'B_SHOWINTCP', state)
        reaper.SetMediaTrackInfo_Value(track, 'B_SHOWINMIXER', state)
    end
end

function get_visible_tracks()
    local tracks = {}
    local track_count = reaper.CountTracks(0)
    for i = 0, track_count - 1 do
        local track = reaper.GetTrack(0, i)
        if is_track_visible(track) then
            table.insert(tracks, track)
        end
    end
    return tracks
end

--TAGS
function get_tracks_tags()
    local t = {}
    local tracks = get_all_tracks()
    local new_tracks = {}
    for i = 1, #tracks do
        local track = tracks[i]
        local ext = get_ext_state(track)
        
        --COLLECT TAGS
        for _, tag in pairs(ext.tags) do
            t[tag.name] = tag
        end

        --CHECK NEW TRACKS
        if is_track_visible(track) and count_table(ext.tags) == 0 then
            table.insert(new_tracks, track)
        end
    end
    
    local tags = {}
    for _, tag in pairs(t) do
        table.insert(tags, tag)
    end
    table.sort(tags, function(a,b) return a.id < b.id end)
    return tags, t, new_tracks
end

--BLACKLIST/LOCK
function add_tag_to_track(track, tag)
    local ext = get_ext_state(track)
    if not ext.lock_visibility and not track_is_blacklisted(track) then
        ext.tags[tag.name] = tag
        set_ext_state(track, ext)
    end
end

function remove_tag_from_track(track, tag)
    local ext = get_ext_state(track)
    if not ext.lock_visibility then
        ext.tags[tag.name] = nil
        set_ext_state(track, ext)
    end
end

function show_all_tracks()
    reaper.PreventUIRefresh(1)
    local tracks = get_all_tracks()
    for i = 1, #tracks do
        local track = tracks[i]
        set_track_visible(track, nil, 1)
    end
    reaper.PreventUIRefresh(-1)
    reaper.TrackList_AdjustWindows(false)
end

function lock_track(track)
    local ext = get_ext_state(track)
    ext.lock_visibility = true
    set_ext_state(track, ext)
end

function unlock_track(track)
    local ext = get_ext_state(track)
    ext.lock_visibility = false
    set_ext_state(track, ext)
end

function load_tag(tag)
    reaper.PreventUIRefresh(1)
    local tracks = get_all_tracks()
    for i = 1, #tracks do
        local track = tracks[i]
        local ext = get_ext_state(track)
        if not ext.tags[tag.name] then
            set_track_visible(track, ext, 0)
        else
            set_track_visible(track, ext, 1)
        end
        reaper.SetTrackSelected(track, false)
    end
    reaper.PreventUIRefresh(-1)
    reaper.TrackList_AdjustWindows(false)
end

function clear_tag_from_track(track, tag)
    local ext = get_ext_state(track)
    if ext.tags[tag.name] then
        ext.tags[tag.name] = nil
        set_ext_state(track, ext)
    end
end

function clear_tag(tag)
    local tracks = get_all_tracks()
    for i = 1, #tracks do
        local track = tracks[i]
        clear_tag_from_track(track, tag)
    end
end

function clear_all_tags()
    local tracks = get_all_tracks()
    for i = 1, #tracks do
        local track = tracks[i]
        local ext = get_ext_state(track)
        ext.tags = {}
        set_ext_state(track, ext)
    end
end

function rename_tag(tag, new_name, auto_adjust_id)
    local tracks = get_all_tracks()
    for i = 1, #tracks do
        local track = tracks[i]
        local ext = get_ext_state(track)
        if ext.tags[tag.name] then
            ext.tags[tag.name] = nil
            local new_tag = table.shallow_copy(tag)
            new_tag.name = new_name
            ext.tags[new_name] = new_tag
            set_ext_state(track, ext)
        end
    end
end

function merge_tag(tag, into)
    local tracks = get_all_tracks()
    for i = 1, #tracks do
        local track = tracks[i]
        local ext = get_ext_state(track)
        if ext.tags[tag.name] then
            ext.tags[tag.name] = nil
            ext.tags[into.name] = into
            set_ext_state(track, ext)
        end
    end
end

function select_tag_only(tag)
    reaper.PreventUIRefresh(1)
    local tracks = get_visible_tracks()
    for i = 1, #tracks do
        local track = tracks[i]
        local ext = get_ext_state(track)
        if ext.tags[tag.name] then
            reaper.SetTrackSelected(track, true)
        else
            reaper.SetTrackSelected(track, false)
        end
    end
    reaper.PreventUIRefresh(-1)
end

function select_locked_tracks()
    local tracks = get_all_tracks()
    local tracks = get_visible_tracks()
    for i = 1, #tracks do
        local track = tracks[i]
        local ext = get_ext_state(track)
        if ext.lock_visibility then
            reaper.SetTrackSelected(track, true)
        else
            reaper.SetTrackSelected(track, false)
        end
    end
end

function validate_tag_name(lookup, name)
    if lookup[name] then
        return true, "A tag with the same name already exists."
    elseif name == '' or name == nil then
        return true, 'Tag name cannot be empty.'
    else
        return false
    end
end