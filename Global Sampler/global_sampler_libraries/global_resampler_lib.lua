-- @noindex

function p(msg) reaper.ShowConsoleMsg(tostring(msg) .. ' \n') end
function reaper_do_file(file) local info = debug.getinfo(1,'S'); path = info.source:match[[^@?(.*[\/])[^\/]-$]]; dofile(path .. file); end
reaper_do_file('json.lua')
reaper.gmem_attach('BB_Sampler')

function load_settings()
    local settings_file = io.open(path .. "sampler_settings.json", 'r')
    if not settings_file then
        local default_settings = '{"theme":"theme_carbon", "waveform_zoom":1}'
        settings_file = io.open(path .. "sampler_settings.json", 'w')
        settings_file:write(default_settings)
        settings_file:close()
    end
    settings_file = io.open(path .. "sampler_settings.json", 'r')
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

local fx_name = 'Global Sampler'
function locate_JSFX(name)
    --check master
    local master = reaper.GetMasterTrack(0)
    local index = reaper.TrackFX_GetByName( master, name, false)
    if index ~= -1 then
        return {track = master, index = index, type = 'MASTER'}
    end

    --check monitor fx
    index = reaper.TrackFX_AddByName( master, name, true, 0)
    if index ~= -1 then
        return {track = master, index = index|0x1000000, type = 'MONITOR'}
    end    
    
    --check tracks
    local track_count = reaper.CountTracks(0)
    for i = 0, track_count - 1 do
        local track = reaper.GetTrack(0, i)
        local index = reaper.TrackFX_GetByName( track, name, false)
        if index ~= -1 then
            return {track = track, index = index, type = 'TRACK'}
        end
    end
    return nil
end

function ping_JSFX()
    local js = locate_JSFX(fx_name)
    if js then
        reaper.TrackFX_Show(js.track, js.index, 3)
        local hwnd = reaper.TrackFX_GetFloatingWindow( js.track, js.index )
        reaper.JS_Window_Show( hwnd, "HIDE" )
    else
        reaper.gmem_write(5, 0) --announce plugin not found
    end
end

function get_buffer_data()
    local b = {}
    b.disp_buf_index = reaper.gmem_read(8)
    return b
end

function get_track()
    local track_id
    local track = reaper.GetSelectedTrack(0, 0)
    if track then
        track_id = reaper.GetMediaTrackInfo_Value(track, 'IP_TRACKNUMBER')
    end
    return {track = track, track_id = track_id}
end

function sample_normalized(nx, nw)
    local t = get_track()
    if t.track then
        reaper.gmem_write(6, nx) --start
        reaper.gmem_write(7, nw) --width
        reaper.gmem_write(2, t.track_id) --track
        
        reaper.gmem_write(1, 3)  --type
        reaper.gmem_write(0, 1)  --dump switch

        ping_JSFX()
    end
end

function sample_playback()
    local t = get_track()
    if t.track then
        reaper.gmem_write(1, 1)  --type
        reaper.gmem_write(0, 1)  --dump switch
        reaper.gmem_write(2, t.track_id) --track
        ping_JSFX()
    end
end

function sample_seconds(seconds)
    local t = get_track()
    if t.track then
        reaper.gmem_write(1, 2) --last X secs
        reaper.gmem_write(3, seconds) --4 seconds
        reaper.gmem_write(0, 1) --dump values
        reaper.gmem_write(2, t.track_id) --track
        ping_JSFX()
    end
end
