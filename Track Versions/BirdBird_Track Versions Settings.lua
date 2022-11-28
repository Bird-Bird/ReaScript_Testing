-- @noindex

function p(msg) reaper.ShowConsoleMsg(tostring(msg)..'\n')end
dofile(reaper.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/imgui.lua')('0.6')
function reaper_do_file(file) local info = debug.getinfo(1,'S'); path = info.source:match[[^@?(.*[\/])[^\/]-$]]; dofile(path .. file); end
reaper_do_file('track_versions_libraries/functions.lua')

--CHECK DEPENDENCY
if not reaper.APIExists('ImGui_GetVersion') then
    local text = 'Track Versions Settings requires the ReaImGui extension to run. You can install it through ReaPack.'
    local ret = reaper.ShowMessageBox(text, 'Track Versions - Missing Dependency', 0)
    return
end

local ctx = reaper.ImGui_CreateContext('Track Versions Settings')
local size = reaper.GetAppVersion():match('OSX') and 12 or 14
local font = reaper.ImGui_CreateFont('courier-new', size)
reaper.ImGui_AttachFont(ctx, font)

local settings = get_settings()
function frame()
    local save = false
    rv, settings.prefix_tracks = reaper.ImGui_Checkbox(ctx, 'Prefix tracks', settings.prefix_tracks)
    if rv then
        save = true
    end
    if save then
        save_settings(settings)
    end
end

function loop()
    reaper.ImGui_PushFont(ctx, font)
    reaper.ImGui_SetNextWindowSize(ctx, 200, 300, reaper.ImGui_Cond_FirstUseEver())
    local visible, open = reaper.ImGui_Begin(ctx, 'Track Versions Settings', true)
    if visible then
        frame()
        reaper.ImGui_End(ctx)
    end
    reaper.ImGui_PopFont(ctx)

    if open then
        reaper.defer(loop)
    else
        reaper.ImGui_DestroyContext(ctx)
    end
end

reaper.defer(loop)