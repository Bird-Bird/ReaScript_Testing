-- @noindex

function p(msg) reaper.ShowConsoleMsg(tostring(msg) .. ' \n') end
function reaper_do_file(file) local info = debug.getinfo(1,'S'); path = info.source:match[[^@?(.*[\/])[^\/]-$]]; dofile(path .. file); end
reaper_do_file('wav.lua')
reaper_do_file('json.lua')

function load_settings()
    local settings_file = io.open(path .. "sampler_settings.json", 'r')
    if not settings_file then
        local text = 'Cannot find sampler_settings.json in the installation directory, are you sure Global Sampler is installed correctly?'
        local ret = reaper.ShowMessageBox(text, 'Global Sampler - Dependency Error', 0)
        return nil
    end
    local settings_str = settings_file:read("*all")
    local settings = json.decode(settings_str)
    settings_file:close(settings_file)
    return settings
end

function save_settings(set)
    settings_file = io.open(path .. "sampler_settings.json", 'w')
    local settings_str = json.encode(set)
    settings_file:write(settings_str)
    settings_file:close()
end

local settings = load_settings()
if not settings then
    return
end
if not settings.path then
    local text = 'It seems that this is your first time running Global Sampler, would you like to set a recording path?' .. '\n\n' .. "You can always change this path later by running the action 'BirdBird_Set Global Sampler Recording Path'."
    local ret = reaper.ShowMessageBox(text, 'Global Sampler - First Time Setup', 4)
    if ret == 6 then
        local retval, folder = reaper.JS_Dialog_BrowseForFolder('Select Recording Path', '')
        if retval then 
            settings.path = folder .. '/'
            save_settings(settings)
        end
    end
end
local recording_path = settings.path -- <- set via script

reaper.gmem_attach('BB_Resampler')
function get_buffer_data()
    local b = {}

    b.srate = 1 / reaper.parse_timestr_len( 1, 0, 4 )
    b.len_in_secs = reaper.gmem_read(0)
    b.buf_start_index = reaper.gmem_read(1)
    b.num_channels = 2
    b.real_size = b.srate * b.len_in_secs
    b.disp_buf_index = reaper.gmem_read(8)
    return b
end

function sample(start_index, sample_len_in_secs)
    local srate = 1 / reaper.parse_timestr_len( 1, 0, 4 )
    local len_in_secs = reaper.gmem_read(0)
    local buf_start_index = reaper.gmem_read(1)
    local num_channels = 2
    
    local playback_start_index = reaper.gmem_read(4)
    local playback_length_secs = sample_len_in_secs
    
    local samples = {n = 0}
    local start_index = start_index
    local end_index = math.floor(start_index - 1 + playback_length_secs*srate)
    local arr_size = len_in_secs*srate
    local r = reaper
    for i = start_index, end_index do
        local j = i;
        if j >= arr_size + buf_start_index then
            j = (j % arr_size) + buf_start_index
        end
        for c = 1, 2 do
            samples.n = samples.n + 1
            if c == 1 then
                samples[samples.n] = r.gmem_read(j)
            else 
                samples[samples.n] = r.gmem_read(j + arr_size)
            end
        end
    end
    
    --WRITE TO FILE
    local proj_name = reaper.GetProjectName(0, '')
    if proj_name == '' then proj_name = 'Untitled' else
    proj_name = string.sub(proj_name, 1, #proj_name - 4) end 
    local file_name = recording_path .. proj_name .. ' - ' ..  reaper.time_precise() .. ".wav"
    local writer = wav.create_context(file_name, "w")
    writer.init(num_channels, srate, 32)
    writer.write_samples_interlaced(samples)
    writer.finish()
    
    reaper.gmem_write(2, 0) --release writer
    
    --INSERT MEDIA
    reaper.PreventUIRefresh(1)
    local edit_cursor_pos = reaper.GetCursorPosition()
    reaper.InsertMedia(file_name, 0)
    reaper.SetEditCurPos( edit_cursor_pos, false, false)
    reaper.PreventUIRefresh(-1)
end