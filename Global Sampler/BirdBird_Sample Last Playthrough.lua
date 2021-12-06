-- @noindex

--LOAD LIBRARIES-------------------------------------------------
function p(msg) reaper.ShowConsoleMsg(tostring(msg) .. ' \n') end
function reaper_do_file(file) local info = debug.getinfo(1,'S'); path = info.source:match[[^@?(.*[\/])[^\/]-$]]; dofile(path .. file); end
reaper_do_file('global_sampler_libraries/global_resampler_lib.lua')
sample_playback()
