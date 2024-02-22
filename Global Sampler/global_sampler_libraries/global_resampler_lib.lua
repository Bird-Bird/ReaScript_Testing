-- @noindex

local debug_mode = false
function p(msg) reaper.ShowConsoleMsg(tostring(msg) .. ' \n') end
function p2(msg) if debug_mode then reaper.ShowConsoleMsg(tostring(msg) .. ' \n') end end
function reaper_do_file(file) local info = debug.getinfo(1,'S'); path = info.source:match[[^@?(.*[\/])[^\/]-$]]; dofile(path .. file); end
reaper_do_file('json.lua')
reaper.gmem_attach('BB_Sampler')

local function get_default_settings() 
  return  {theme = "theme_reaper_default", waveform_zoom = 1}
end

local error_strings = {
  corrupted_settings_on_load = "The settings file of Global Sampler appears to be corrupted. Global Sampler will generate a fresh set of settings instead.",
  invalid_settings = "Invalid set of settings, please make a bug report on the thread for the script with a description of the events that lead up to it.",
}

function load_settings()
    local settings_file = io.open(path .. "sampler_settings.json", 'r')
    if not settings_file then
        return get_default_settings()
    else
      local settings_str = settings_file:read("*all")
      settings_file:close(settings_file)
      
      local status, settings = pcall(json.decode, settings_str)
      if not status then
          reaper.ShowMessageBox(error_strings.corrupted_settings_on_load, 'Global Sampler - Error', 0)
          return get_default_settings()
      else
          return settings
      end
    end
end

function save_settings(set)
    settings_file = io.open(path .. "sampler_settings.json", 'w')
    local status, settings_str = pcall(json.encode, set)
    if status == false or type(set) ~= "table" then
        reaper.ShowMessageBox(error_strings.invalid_settings, 'Global Sampler - Error', 0)
        settings_file:write(json.encode(get_default_settings()))
    else
        settings_file:write(settings_str)
    end
    settings_file:close()
end

function instance_enabled(i)
    return not reaper.TrackFX_GetOffline(i.track, i.index)
end

function hide_instance(js)
    if reaper_version < 6.44 then
        reaper.TrackFX_Show(js.track, js.index, 3)
        local hwnd = reaper.TrackFX_GetFloatingWindow( js.track, js.index )
        reaper.JS_Window_Show( hwnd, "HIDE" )
    end
end

--ONLY USE WHEN THERE IS GUARANTEED TO BE A SINGLE INSTANCE ENABLED
local fx_name = 'Global Sampler'
function locate_JSFX(name)
    --check master
    local master = reaper.GetMasterTrack(0)
    local index = reaper.TrackFX_GetByName( master, name, false)
    if index ~= -1 then
        local dat = {track = master, index = index, type = 'MASTER'}
        if instance_enabled(dat) then
            return dat
        end
    end

    --check monitor fx
    index = reaper.TrackFX_AddByName( master, name, true, 0)
    if index ~= -1 then
        local dat = {track = master, index = index|0x1000000, type = 'MONITOR'}
        if instance_enabled(dat) then
            return dat
        end
    end    
    
    --check tracks
    local track_count = reaper.CountTracks(0)
    for i = 0, track_count - 1 do
        local track = reaper.GetTrack(0, i)
        local index = reaper.TrackFX_GetByName( track, name, false)
        if index ~= -1 then
            local dat = {track = track, index = index, type = 'TRACK'}
            if instance_enabled(dat) then
                return dat
            end
        end
    end
    return nil
end

function locate_all_JSFX(name)
    local instances = {}
    local num_enabled = 0
    local ext_dat = {}
    --check master
    local master = reaper.GetMasterTrack(0)
    local index = reaper.TrackFX_GetByName( master, name, false)
    if index ~= -1 then
        local i   = {track = master, index = index, type = 'MASTER', prio = 2}
        i.enabled = instance_enabled(i)
        if i.enabled then
            num_enabled = num_enabled + 1
        end
        table.insert(instances, i)
        
    end

    --check monitor fx
    index = reaper.TrackFX_AddByName( master, name, true, 0)
    if index ~= -1 then
        local i = {track = master, index = index|0x1000000, type = 'MONITOR', prio = 1}
        i.enabled = instance_enabled(i)
        if i.enabled then
            ext_dat.monitor_enabled = true
            num_enabled = num_enabled + 1
        end
        table.insert(instances, i)
    end    
    
    --check tracks
    local track_count = reaper.CountTracks(0)
    for i = 0, track_count - 1 do
        local track = reaper.GetTrack(0, i)
        local index = reaper.TrackFX_GetByName( track, name, false)
        if index ~= -1 then
            local i   = {track = track, index = index, type = 'TRACK', prio = 3}
            i.enabled = instance_enabled(i)
            if i.enabled then
                num_enabled = num_enabled + 1
            end
            table.insert(instances, i)
        end
    end
    ext_dat.num_enabled = num_enabled
    return instances, ext_dat
end

--no longer necessary for v6.44 and above
function ping_JSFX()
    if reaper_version < 6.44 then
        local js = locate_JSFX(fx_name)
        if js then
            hide_instance(js)
        else
            reaper.gmem_write(5, 0) --announce plugin not found
        end
    end
end

function validate_instances()
    local instances, dat = locate_all_JSFX(fx_name)
    if #instances == 0 then
        return
    end
    local num_enabled = dat.num_enabled
    table.sort(instances, function(a,b) return a.prio < b.prio end)
    
    local flush_display = 0
    if num_enabled == 0 then
        local ins = instances[#instances]
        reaper.TrackFX_SetOffline(ins.track, ins.index, false)
        hide_instance(ins)
        p2('enabled: ' .. ins.type)
        flush_display = 1
    elseif num_enabled > 1 then
        local cur_enabled = num_enabled
        local i = 1
        while i <= #instances and cur_enabled > 1 do
            local ins = instances[i]
            if ins.enabled then
                reaper.TrackFX_SetOffline(ins.track, ins.index, true)
                p2('disabled: ' .. ins.type)
                flush_display = 1

                cur_enabled = cur_enabled - 1
                i = i +1
            end 
        end
    else
        if not dat.monitor_enabled then
            flush_display = 1
        end
    end

    local js = locate_JSFX(fx_name)
    if js and flush_display > 0 then
        p2('FLUSH DISPLAY')
        reaper.gmem_write(14, 1)
    end
    hide_instance(js)
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
