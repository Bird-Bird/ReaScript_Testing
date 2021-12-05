-- @noindex

--LOAD LIBRARIES-------------------------------------------------
function p(msg) reaper.ShowConsoleMsg(tostring(msg) .. ' \n') end
function reaper_do_file(file) local info = debug.getinfo(1,'S'); path = info.source:match[[^@?(.*[\/])[^\/]-$]]; dofile(path .. file); end
reaper_do_file('global_sampler_libraries/global_resampler_lib.lua')

reaper.gmem_attach('BB_Resampler')
reaper.gmem_write(2, 1) --pause writer

local srate = 1 / reaper.parse_timestr_len( 1, 0, 4 )
local len_in_secs = reaper.gmem_read(0)

local success, input = reaper.GetUserInputs( "Resample Last X Seconds", "1", "Length", "")
if success then
    input = tonumber(input)
    if input then
        local dump_len_in_secs = input
        if dump_len_in_secs > len_in_secs then
            dump_len_in_secs = len_in_secs
        end

        local buf_start_index = reaper.gmem_read(1)
        local num_channels = 2

        local playback_start_index = reaper.gmem_read(4)
        local playback_length_secs = reaper.gmem_read(5)

        local end_index = reaper.gmem_read(6)
        local real_len = dump_len_in_secs*srate
        local start_index = end_index - real_len

        while start_index < buf_start_index do
            start_index = start_index + len_in_secs*srate
        end
        
        sample(start_index, dump_len_in_secs)
    end
end
reaper.gmem_write(2, 0) --release writer
