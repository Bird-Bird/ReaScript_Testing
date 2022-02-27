-- @description Track Versions
-- @version 0.99
-- @author BirdBird
-- @provides
--    [nomain]track_versions_libraries/json.lua

--@changelog
--  + Initial version

function reaper_do_file(file) local info = debug.getinfo(1,'S'); path = info.source:match[[^@?(.*[\/])[^\/]-$]]; dofile(path .. file); end
reaper_do_file('track_versions_libraries/json.lua')

--FUNCTIONS
function p(msg) reaper.ShowConsoleMsg(tostring(msg) .. '\n') end
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

local ext_name = 'P_EXT:BB_Track_Versions'
function get_ext_state(track)
    local retval, ext_state = reaper.GetSetMediaTrackInfo_String(track, ext_name, "", false)
    if ext_state == '' then
        return {versions = {}, data = {}}
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
    reaper.PreventUIRefresh(1)
    clear_items(track)
    
    --INSERT ITEMS FROM CHUNKS
    for i = 1, #item_chunks do
        local chunk = item_chunks[i]
        local item = reaper.AddMediaItemToTrack(track)
        reaper.SetItemStateChunk(item, chunk, false)
    end

    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
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

--INIT
local track = reaper.GetSelectedTrack(0, 0)
if not track then
    return
end
local state = get_ext_state(track)

--HIDE WINDOW
gfx.init("a", 0, 0, 0, 0, 0 )
local w = reaper.JS_Window_Find("a", true )
local offs = 10000
reaper.JS_Window_Move(w, offs*-1, offs*-1)

--SHOW MENU
gfx.x, gfx.y = gfx.mouse_x + offs, gfx.mouse_y + offs
local menu = "New version|New empty version||#Versions|"
for i = 1, #state.versions do
    local c = state.data.selected == i and '!' or ''
    menu = menu .. c .. 'v' .. i .. '|'
end

local option = gfx.showmenu(menu)
if option == 1 or option == 2 then
    --NEW VERSION
    local retval, chunk = reaper.GetTrackStateChunk(track, "", false)
    local chunk_lines = str_split(chunk, '\n')
    local item_chunks = get_item_chunks(chunk_lines)
    
    --INIT FIRST VERSION
    if #state.versions == 0 then
        state.versions[#state.versions+1] = item_chunks
    end
    
    --CREATE NEW VERSION
    state.versions[#state.versions+1] = item_chunks
    state.data.selected = #state.versions
    reaper.Undo_BeginBlock()
    create_new_version(track, state)

    --CLEAR ITEMS
    if option == 2 then
        clear_items(track)
        reaper.UpdateArrange()
    end
    reaper.Undo_EndBlock('Track Versions - New Version', -1)
elseif option > 3 then
    --SAVE CURRENT VERSION TO STATE
    local retval, chunk = reaper.GetTrackStateChunk(track, "", false)
    local chunk_lines = str_split(chunk, '\n')
    local item_chunks = get_item_chunks(chunk_lines)
    state.versions[state.data.selected] = item_chunks

    --SWITCH VERSION
    local i = option - 3
    local t_chunk = state.versions[i]
    state.data.selected = i
    
    reaper.Undo_BeginBlock()
    load_chunk(track, t_chunk)
    set_ext_state(track, state)
    reaper.Undo_EndBlock('Track Versions - Switch Version', -1)
end
gfx.quit()