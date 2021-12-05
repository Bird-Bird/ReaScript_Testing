-- @noindex

function p(msg) reaper.ShowConsoleMsg(tostring(msg) .. ' \n') end
function reaper_do_file(file) local info = debug.getinfo(1,'S'); path = info.source:match[[^@?(.*[\/])[^\/]-$]]; dofile(path .. file); end
reaper_do_file('global_sampler_libraries/json.lua')

function load_settings()
    local settings_file = io.open(path .. "/global_sampler_libraries/sampler_settings.json", 'r')
    local settings_str = settings_file:read("*all")
    local settings = json.decode(settings_str)
    settings_file:close(settings_file)
    return settings
end

function save_settings(set)
    settings_file = io.open(path .. "/global_sampler_libraries/sampler_settings.json", 'w')
    local settings_str = json.encode(set)
    settings_file:write(settings_str)
    settings_file:close()
end

local settings = load_settings()
local retval, folder = reaper.JS_Dialog_BrowseForFolder('Select Recording Path', '')
if retval then 
    settings.path = folder .. '/'
    save_settings(settings)
    local ret = reaper.ShowMessageBox('Global Sampler recording path has been succesfully set.', 'Global Sampler - Success', 0)
else
    local ret = reaper.ShowMessageBox('No path has been selected. Global Sampler will keep using the same path.', 'Global Sampler - No path selected', 0)
end

