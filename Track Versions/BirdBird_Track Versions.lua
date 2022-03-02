-- @description Track Versions
-- @version 0.99.3
-- @author BirdBird
-- @provides
--    [nomain]track_versions_libraries/json.lua
--    [nomain]track_versions_libraries/functions.lua
--    [main]BirdBird_Track Versions - Cycle to next version.lua
--    [main]BirdBird_Track Versions - Cycle to previous version.lua

--@changelog
--  + Initial version

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
local tracks, min_versions, all_selected = get_selected_tracks()

--SHOW MENU
gfx.x, gfx.y = gfx.mouse_x + offs, gfx.mouse_y + offs
local menu = "Create new version|Create new empty version|>Actions|<Clear other versions||#Versions|"
local menu_length = 4
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
elseif option == 3 then
    for i = 1, #tracks do
        local track = tracks[i].track
        local state = tracks[i].state
        collapse_versions(track, state)
    end
    undo = 'Track Versions - Collapse Versions'
elseif option == 4 then
    for i = 1, #tracks do
        local track = tracks[i].track
        local state = tracks[i].state
        explode_to_child_tracks(track, state)
    end  
    undo = 'Track Versions - Explode Versions'    
elseif option > menu_length then
    local selected_id = option - menu_length
    for i = 1, #tracks do 
        local track = tracks[i].track
        local state = tracks[i].state
        switch_versions(track, state, selected_id)
    end
    undo = 'Track Versions - Switch Version'
end
reaper.Undo_EndBlock(undo, -1)
reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()
gfx.quit()