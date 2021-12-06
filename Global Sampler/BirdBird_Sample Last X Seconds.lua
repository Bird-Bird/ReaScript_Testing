-- @noindex

--LOAD LIBRARIES-------------------------------------------------
function p(msg) reaper.ShowConsoleMsg(tostring(msg) .. ' \n') end
function reaper_do_file(file) local info = debug.getinfo(1,'S'); path = info.source:match[[^@?(.*[\/])[^\/]-$]]; dofile(path .. file); end
reaper_do_file('global_sampler_libraries/global_resampler_lib.lua')

local success, input = reaper.GetUserInputs( "Resample Last X Seconds", "1", "Length", "")
if success then
    input = tonumber(input)
    if input and input > 0 then
        sample_seconds(input)
    end
end

