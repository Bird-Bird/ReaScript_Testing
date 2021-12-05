-- @noindex

--LOAD LIBRARIES-------------------------------------------------
function p(msg) reaper.ShowConsoleMsg(tostring(msg) .. ' \n') end
function reaper_do_file(file) local info = debug.getinfo(1,'S'); path = info.source:match[[^@?(.*[\/])[^\/]-$]]; dofile(path .. file); end
reaper_do_file('global_sampler_libraries/global_resampler_lib.lua')

reaper.gmem_attach('BB_Resampler')
reaper.gmem_write(2, 1) --pause writer

local srate = 1 / reaper.parse_timestr_len( 1, 0, 4 )
local len_in_secs = reaper.gmem_read(0)
local buf_start_index = reaper.gmem_read(1)

local playback_start_index = reaper.gmem_read(4)
local playback_length_secs = reaper.gmem_read(5)

local start_index = buf_start_index + playback_start_index

sample(start_index, playback_length_secs)
reaper.gmem_write(2, 0) --release writer