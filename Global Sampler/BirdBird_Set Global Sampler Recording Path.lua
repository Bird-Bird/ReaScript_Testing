-- @noindex

function p(msg) reaper.ShowConsoleMsg(tostring(msg) .. ' \n') end
function reaper_do_file(file) local info = debug.getinfo(1,'S'); path = info.source:match[[^@?(.*[\/])[^\/]-$]]; dofile(path .. file); end
reaper_do_file('global_sampler_libraries/json.lua')
reaper_do_file('global_sampler_libraries/global_resampler_lib.lua')

local settings = load_settings()
local retval, folder = reaper.JS_Dialog_BrowseForFolder('Select Recording Path', '')
if retval then 
    settings.path = folder .. '/'
    save_settings(settings)
    local ret = reaper.ShowMessageBox('Global Sampler recording path has been succesfully set.', 'Global Sampler - Success', 0)
else
    local ret = reaper.ShowMessageBox('No path has been selected. Global Sampler will keep using the same path.', 'Global Sampler - No path selected', 0)
end

