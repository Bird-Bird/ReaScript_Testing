-- @description Track Versions
-- @version 0.99.9.8
-- @author BirdBird
-- @provides
--    [nomain]track_versions_libraries/json.lua
--    [nomain]track_versions_libraries/functions.lua
--    [nomain]track_versions_libraries/settings.lua
--    [nomain]track_versions_libraries/versions.lua
--    [nomain]track_versions_libraries/gui.lua
--    [nomain]track_versions_libraries/ext_state.lua
--    [nomain]track_versions_libraries/chunk_parsing.lua
--    [main]BirdBird_Track Versions - Cycle to next version.lua
--    [main]BirdBird_Track Versions - Cycle to previous version.lua
--    [main]BirdBird_Track Versions Settings.lua
--    [main]BirdBird_Track Versions (GUI).lua
-- @changelog
--  + Prepare for ReaImGui updates

function reaper_do_file(file) local info = debug.getinfo(1,'S'); path = info.source:match[[^@?(.*[\/])[^\/]-$]]; dofile(path .. file); end
reaper_do_file('track_versions_libraries/functions.lua')

--CHECK DEPENDENCIES
function open_url(url)
    local OS = reaper.GetOS()
    if (OS == "OSX32" or OS == "OSX64") or OS == 'macOS-arm64' then
        os.execute('open "" "' .. url .. '"')
    else
        os.execute('start "" "' .. url .. '"')
    end
end

if not reaper.APIExists('JS_ReaScriptAPI_Version') then
    local text = 'Track Versions requires the js_ReaScriptAPI to to run, however it is unable to find it. \nWould you like to be redirected to the extensions forum thread for installation?'
    local ret = reaper.ShowMessageBox(text, 'Track Versions - Dependency Error', 4)
    if ret == 6 then
        open_url('https://forum.cockos.com/showthread.php?t=212174')
    end
    return
end

--FUNCTIONS
function p(msg) reaper.ShowConsoleMsg(tostring(msg) .. '\n') end

--HIDE WINDOW
gfx.init("a", 0, 0, 0, 0, 0 )
local w = reaper.JS_Window_Find("a", true )
local OS = reaper.GetOS()
local offs = 10000
if (OS == "OSX32" or OS == "OSX64") or OS == 'macOS-arm64' then
    offs = 0
    reaper.JS_Window_Show(w, "HIDE" )
else
    reaper.JS_Window_Move(w, offs*-1, offs*-1)
end

--INIT
local settings = get_settings()
local tracks, min_versions, all_selected = get_selected_tracks()
if #tracks == 0 then return end
local init_version_counts = {}
if settings.prefix_tracks then
    --BACKWARDS COMPATIBILITY
    init_version_counts = prefix_tracks(tracks, true)
end

--SHOW MENU
gfx.x, gfx.y = gfx.mouse_x + offs, gfx.mouse_y + offs
local menu = "Create new version|Create new empty version|>Actions|Delete current version|<Clear other versions||#Versions|"
local menu_length = 5
for i = 1, min_versions do
    local c = ''
    if #tracks == 1 or all_selected ~= -1 then
        c = tracks[1].state.data.selected == i and '!' or ''
    end
    menu = menu .. c .. 'v' .. i .. '|'
end

--EXECUTE COMMAND
local option = gfx.showmenu(menu)
if option == 0 then return end
local partial_load = reaper.JS_Mouse_GetState(0|00000100)&4 == 4

--DELETE PROMPT
if option == 3 or option == 4 then
    local text = option == 4 and "Are you sure that you want to clear all other versions?" or 
    "Are you sure that you want to delete the selected version?"
    local ret = reaper.ShowMessageBox(text, 'Track Versions - Delete Version', 4)
    if ret ~= 6 then
        return
    end
end

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
local undo = ''
if option == 1 or option == 2 then
    local clear = option == 2
    for i = 1, #tracks do 
        local track = tracks[i].track
        local state = tracks[i].state
        add_new_version(track, state, clear)   
    end
    undo = 'Track Versions - Create New Version'
elseif option == 4 then
    for i = 1, #tracks do
        local track = tracks[i].track
        local state = tracks[i].state
        tracks[i].state = collapse_versions(track, state)
    end
    undo = 'Track Versions - Collapse Versions'
elseif option == 3 then
    for i = 1, #tracks do
        local track = tracks[i].track
        local state = tracks[i].state
        delete_current_version(track, state)
    end  
    undo = 'Track Versions - Delete Current Version'    
elseif option > menu_length then
    local selected_id = option - menu_length
    for i = 1, #tracks do 
        local track = tracks[i].track
        local state = tracks[i].state
        switch_versions(track, state, selected_id, false, partial_load)
    end
    undo = partial_load and 'Track Versions - Additive Load' or 
    'Track Versions - Switch Version'
end
--PREFIX TRACKS
if settings.prefix_tracks then
    prefix_tracks(tracks, false, init_version_counts)
end
reaper.Undo_EndBlock(undo, -1)
reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()
gfx.quit()