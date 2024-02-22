-- @description Global Sampler
-- @version 0.99.8.4
-- @author BirdBird
-- @provides
--    [nomain]global_sampler_libraries/global_resampler_lib.lua
--    [nomain]global_sampler_libraries/json.lua
--    [nomain]global_sampler_libraries/themes.lua
--    [main]BirdBird_Sample Last Playthrough.lua
--    [main]BirdBird_Sample Last X Seconds.lua
--    [main]BirdBird_Global Sampler Theme Editor.lua
--    [effect] BirdBird_Global Sampler.jsfx
--@changelog
-- + Add text to indicate whether the sampler has been paused
-- + Fix stereo channels getting swapped in some cases when the display has been offset
-- + Fix some bugs that happen at high samplerates
-- + Fix the JSFX window showing up in some cases (requires REAPER v6.44 and above)
-- + Fix the JSFX not initializing correctly in some cases

reaper_version = tonumber((reaper.GetAppVersion()):match("^[0-9]+%.?[0-9]*"))

--CHECK DEPENDENCIES
function open_url(url)
    local OS = reaper.GetOS()
    if (OS == "OSX32" or OS == "OSX64") or OS == 'macOS-arm64' then
        os.execute('open "" "' .. url .. '"')
    else
        os.execute('start "" "' .. url .. '"')
    end
end

if not reaper.APIExists('CF_GetSWSVersion') then
    local text = 'Global Sampler requires the SWS Extension to run, however it is unable to find it. \nWould you like to be redirected to the SWS Extension website to install it?'
    local ret = reaper.ShowMessageBox(text, 'Global Sampler - Dependency Error', 4)
    if ret == 6 then
        open_url('https://www.sws-extension.org/')
    end
    return
end

if not reaper.APIExists('JS_ReaScriptAPI_Version') then
    local text = 'Global Sampler requires the js_ReaScriptAPI to to run, however it is unable to find it. \nWould you like to be redirected to the extensions forum thread for installation?'
    local ret = reaper.ShowMessageBox(text, 'Global Sampler - Dependency Error', 4)
    if ret == 6 then
        open_url('https://forum.cockos.com/showthread.php?t=212174')
    end
    return
end

--LOAD LIBRARIES-------------------------------------------------
function p(msg) reaper.ShowConsoleMsg(tostring(msg) .. ' \n') end
function reaper_do_file(file) local info = debug.getinfo(1,'S'); path = info.source:match[[^@?(.*[\/])[^\/]-$]]; dofile(path .. file); end
reaper_do_file('global_sampler_libraries/global_resampler_lib.lua')
reaper_do_file('json.lua')
reaper_do_file('themes.lua')
reaper.gmem_write(16, 0)

local settings = load_settings()
if not settings then 
    reaper.ShowMessageBox("Cannot locate settings.", 'Global Sampler - Error', 0)
    return
end
if not settings.waveform_zoom then
    settings.waveform_zoom = 1
    save_settings(st)
end

--THEMES
local themes = get_themes()
local theme = themes[settings.theme]
function swap_theme(theme_name)
    local new_theme = themes[theme_name]
    settings.theme = theme_name
    save_settings(settings)

    theme = new_theme
    gfx.clear = rgb2num(theme.bg.r, theme.bg.g, theme.bg.b)
end

--https://iquilezles.org/www/articles/palettes/palettes.htm
function palette(t)
    local a = {r = 0.5, g = 0.5, b = 0.5}
    local b = {r = 0.5, g = 0.5, b = 0.5}
    local c = {r = 1, g = 1, b = 1}
    local d = {r = 0, g = 0.33, b = 0.67}

    local brightness = 0.2
    
    local col = {}
    col.r = a.r + brightness + math.cos((c.r*t + d.r)*6.28318)*b.r
    col.g = a.g + brightness + math.cos((c.g*t + d.g)*6.28318)*b.g
    col.b = a.b + brightness + math.cos((c.b*t + d.b)*6.28318)*b.b
    return col
end

--To convert RBG to the GFX variable
function rgb2num(red, green, blue) 
    green = green * 256
    blue = blue * 256 * 256
    return red + green + blue 
end

--https://forum.cockos.com/showpost.php?p=2157010&postcount=22
function set_font(font, size, flagStr)
    if not string.match( reaper.GetOS(), "Win") then
        size = math.floor(size * 0.8)
    end
    local flags = 0
    if flagStr then
        for i = 1, flagStr:len() do
            flags = flags * 256 + string.byte(flagStr, i)
        end
    end

    gfx.setfont(1, font, size, flags)
end

function table.shallow_copy(t)
    local t2 = {}
    for k,v in pairs(t) do
        t2[k] = v
    end
    return t2
end

function wmod(num, mod)
    return num < 0 and mod - (num*-1 % mod) or num % mod
end

local draw_state = {cs = 0, cw = 0, bw = 0, bh = 0, offset = 0, start_offset = 0, start_cs = 0}
draw_state.waveform_zoom = settings.waveform_zoom
local simulations = {}
function draw(m, mouse_state, drag_info)
    local w = gfx.w
    local h = gfx.h
    local margin = theme.border_margin
    local bw = w - 2*margin
    local bh = h - 2*margin    
    
    --BORDER--   
    gfx.set(theme.border.r/256, theme.border.g/256, theme.border.b/256)
    gfx.line(margin, margin, margin + bw, margin)
    gfx.line(margin, margin, margin, margin + bh)
    gfx.line(margin, margin + bh, margin + bw, margin + bh)
    gfx.line(margin + bw, margin, margin + bw, margin + bh)


    --OFFSET
    local norm_offset = draw_state.offset
    norm_offset = norm_offset < 0 and 1 - (norm_offset*-1 - math.floor(norm_offset*-1)) or norm_offset - math.floor(norm_offset)
    local buf = get_buffer_data()
    
    --WRITEHEAD
    local writer_pos_n = reaper.gmem_read(4)
    writer_pos_n = writer_pos_n + norm_offset
    if writer_pos_n < 0 then writer_pos_n = writer_pos_n + 1 elseif writer_pos_n > 1 then writer_pos_n = writer_pos_n - 1 end
    local wxp = math.floor((writer_pos_n * bw) + 0.5) + margin   
    

    --FIRST TIME TEXT
    local jsfx_existed = reaper.gmem_read(5)
    local width_str, height_str
    local t_start, t_end
    if jsfx_existed == 0 then
        local t_str = "~ Insert the Global Sampler JSFX plugin to start recording ~"
        local font_size = 22
        if bh < font_size then
            font_size = bh/2
        end
        
        set_font('Courier New', font_size, "i")
        width_str, height_str = gfx.measurestr(t_str)
        gfx.x = w/2 - width_str/2
        gfx.y = h/2 - font_size/2
        t_start = gfx.x
        t_end   = gfx.y

        gfx.set(theme.writer_col.r/256, theme.writer_col.g/256, theme.writer_col.b/256)
        gfx.drawstr(t_str, 9)
    end


    --WAVEFORM
    local wave_fade_len = theme.wave_fade_len
    local wave_fade_alpha_intensity = theme.wave_fade_alpha_intensity
    local draw_len = bw - 2
    reaper.gmem_write(8, draw_len)
    local disp_buf_index = reaper.gmem_read(9)

    local lx,ly
    for i = 0, draw_len do
        local t = i/draw_len
        t = t - norm_offset
        if t < 0 then t = t + 1 elseif t > 1 then t = t - 1 end
        local t2 = t

        local t2 = math.floor(t2*draw_len)
        local f_val = math.abs(reaper.gmem_read(t2 + disp_buf_index))*-1*draw_state.waveform_zoom
        --CLIP
        if math.abs(f_val) > 1 then
            f_val = f_val / math.abs(f_val)
        end

        local alpha_mul_starter = 1
        if buf.len_in_secs == 0 then
            f_val = 0
            alpha_mul_starter = 0
        end
        
        local x = margin + i + 1
        local height = math.floor( ((f_val/2) * bh) + 0.5 )
        
        local x1 = x
        local y1 = h/2 + height
        local y2 = h/2 - height
        
        local alpha_mul_writehead = 1
        local dist_to_writehead = x - wxp
        if dist_to_writehead < 0 then
            dist_to_writehead = x + draw_len - wxp
        end
        
        --FADE
        if dist_to_writehead > 0 and dist_to_writehead <= wave_fade_len then
            local n_fade = dist_to_writehead/wave_fade_len
            n_fade = (n_fade * wave_fade_alpha_intensity) + 1 - wave_fade_alpha_intensity
            alpha_mul_writehead = n_fade
        end

        local waveform_line_col = {r = theme.waveform_line.r/256,
        g = theme.waveform_line.g/256,
        b = theme.waveform_line.b/256}

        if theme.rainbow_waveform_col then
            waveform_line_col = palette(i/draw_len + reaper.time_precise()/10)
        end
        
        if jsfx_existed > 0 then
            gfx.set(waveform_line_col.r, waveform_line_col.g, waveform_line_col.b,
            theme.waveform_fill_alpha*alpha_mul_writehead*alpha_mul_starter)
            if math.abs(height) >= 1 then
                gfx.line(x, h/2, x1, y1)
                gfx.line(x, h/2 + 1, x1, y2)
            end
            
            if i > 0 then 
                gfx.set(waveform_line_col.r, waveform_line_col.g, waveform_line_col.b,
                1*alpha_mul_writehead*alpha_mul_starter)            
                
                gfx.line(lx, ly, x1, y1) 
                gfx.line(lx2, ly2, x1, y2) 
            end
        end
        lx = x1
        ly = y1
        lx2 = x1
        ly2 = y2
    end

    --WRITEHEAD DRAWING
    if jsfx_existed > 0 then
        gfx.set(theme.writer_col.r/256, theme.writer_col.g/256, theme.writer_col.b/256)
        gfx.line(wxp, margin, wxp, bh + margin)

        --TRAIL
        local trail_len   = theme.trail_len   
        local trail_pow   = theme.trail_pow   
        local trail_alpha = theme.trail_alpha 
        for i = math.max(wxp - trail_len, margin), wxp - 1 do 
            local alpha = 1 - ((wxp - 1) - i)/trail_len
            alpha = alpha ^ trail_pow
            alpha = alpha * trail_alpha
            gfx.set(theme.writer_col.r/256, theme.writer_col.g/256, theme.writer_col.b/256, alpha)
            gfx.line(i, margin, i, bh + margin)
        end
    end

    --CROP REGION
    if jsfx_existed > 0 then
        if mouse_state == 'DOWN' then
            if drag_info.type == 'L' then
                if m.ctrl and m.shift then
                    draw_state.tweak_waveform_zoom = true
                    local cursor = reaper.JS_Mouse_LoadCursor(32645)
                    reaper.JS_Mouse_SetCursor(cursor)
                elseif m.ctrl then
                    local pause_state = reaper.gmem_read(13)
                    reaper.gmem_write(13, 1 - pause_state)
                    
                    local col
                    if pause_state == 0 then
                        --PAUSING
                        col = {r = 219/256, g = 13/256, b = 68/256}
                    else 
                        col = {r = 154/256, g = 227/256, b = 82/256}
                    end
                    local pause_sim = {center = m.x, width = 0, age = 0,
                    type = 'PAUSE', lifetime = 10, col = col}
                    table.insert(simulations, pause_sim)
                elseif m.alt then
                    draw_state.preview = true
                    
                    --NORMALIZED MOUSE
                    local nmx = ((m.x - margin)/bw) - norm_offset
                    nmx = wmod(nmx, 1)
                    reaper.gmem_write(10,1)
                    reaper.gmem_write(11,nmx)

                    --CURSOR
                    local cursor = reaper.JS_Mouse_LoadCursor(32515) --CROSSHAIR
                    reaper.JS_Mouse_SetCursor(cursor)
                else
                    draw_state.hit_time = reaper.time_precise()
                    local aax = m.x >= draw_state.cs and m.x <= draw_state.cs + draw_state.cw
                    local aay = m.y >= margin and m.y <= margin + bh
                    local mouse_in_crop_region = aax and aay
                    if mouse_in_crop_region then
                        draw_state.drag_sample = true
                    else
                        draw_state.draw_crop_region = true
                        draw_state.cs = -1
                        draw_state.cw = -1
                    end
                end
            elseif drag_info.type == 'MMB' then
                draw_state.start_offset = draw_state.offset
                draw_state.offset_buffer = true
                draw_state.start_cs = draw_state.cs
                
                local cursor = reaper.JS_Mouse_LoadCursor(32644)
                reaper.JS_Mouse_SetCursor( cursor )
            elseif drag_info.type == 'R' then
                local aax = m.x >= draw_state.cs and m.x <= draw_state.cs + draw_state.cw
                local aay = m.y >= margin and m.y <= margin + bh
                local mouse_in_crop_region = aax and aay
                if mouse_in_crop_region then
                    gfx.x = m.x 
                    gfx.y = m.y
                    local menu = "Insert at edit cursor"
                    local option = gfx.showmenu(menu)
                    if option == 1 then
                        --UNSELECT ALL ITEMS - FOCUS ARRANGE
                        local sel_item_count = reaper.CountSelectedMediaItems(0)
                        for i = 0, sel_item_count - 1 do
                            local item = reaper.GetSelectedMediaItem(0, sel_item_count - (i+1))
                            reaper.SetMediaItemSelected(item, false)
                        end
                        reaper.SetCursorContext(1)
                        
                        --INSERT MEDIA
                        local start_time, end_time = reaper.GetSet_ArrangeView2(0, false, 0, 0)
                        pos =  reaper.GetCursorPosition()

                        local nx = (draw_state.cs - margin)/draw_state.bw
                        nx = nx - norm_offset
                        if nx < 0 then nx = nx + 1 elseif nx > 1 then nx = nx - 1 end

                        local nw = (draw_state.cw)/draw_state.bw

                        sample_normalized(nx, nw)
                        reaper.GetSet_ArrangeView2(0, true, 0,0, start_time, end_time)
                    end
                else
                    gfx.x = m.x 
                    gfx.y = m.y
                    local menu = "Dock Window||#- Themes -||Carbon|REAPER Default|Rainbow|Violet|BirdBird Classic"
                    local option = gfx.showmenu(menu)
                    if option > 0 then
                        if option == 1 then
                            gfx.dock(513)
                        elseif option == 3 then
                            swap_theme('theme_carbon')
                        elseif option == 4 then
                            swap_theme('theme_reaper_default')
                        elseif option == 5 then
                            swap_theme('theme_rainbow')
                        elseif option == 6 then
                            swap_theme('theme_violet')
                        elseif option == 7 then
                            swap_theme('theme_classic')
                        end
                    end
                end
            end
        end
        if mouse_state == 'RELEASE' then
            if draw_state.draw_crop_region then
                draw_state.draw_crop_region = false
            elseif draw_state.drag_sample then
                draw_state.drag_sample = false
                --ADD LENGTH CHECK
                local dist = math.sqrt((m.x - drag_info.start_x)*(m.x - drag_info.start_x) + (m.y - drag_info.start_y)*(m.y - drag_info.start_y))
                if reaper.time_precise() - draw_state.hit_time < 0.19 and dist < 60 then
                    draw_state.cs = -1
                    draw_state.cw = -1
                else
                    local window, segment, details = reaper.BR_GetMouseCursorContext()
                    if window == 'arrange' then
                        --UNSELECT ALL ITEMS - FOCUS ARRANGE
                        local sel_item_count = reaper.CountSelectedMediaItems(0)
                        for i = 0, sel_item_count - 1 do
                            local item = reaper.GetSelectedMediaItem(0, sel_item_count - (i+1))
                            reaper.SetMediaItemSelected(item, false)
                        end
                        reaper.SetCursorContext(1)
                        
                        --INSERT MEDIA
                        local start_time, end_time = reaper.GetSet_ArrangeView2(0, false, 0, 0)
                        local pos = reaper.BR_GetMouseCursorContext_Position()
                        pos = reaper.SnapToGrid(0, pos)
                        reaper.SetEditCurPos(pos, false, false)

                        local nx = (draw_state.cs - margin)/draw_state.bw
                        nx = nx - norm_offset
                        if nx < 0 then nx = nx + 1 elseif nx > 1 then nx = nx - 1 end

                        local nw = (draw_state.cw)/draw_state.bw

                        sample_normalized(nx, nw)
                        reaper.GetSet_ArrangeView2(0, true, 0,0, start_time, end_time)

                        draw_state.cs = -1
                        draw_state.cw = -1
                    end
                end
            elseif draw_state.offset_buffer then
                --IDLE
                draw_state.offset_buffer = false
                draw_state.start_offset = 0
                draw_state.start_cs = -1
            elseif draw_state.tweak_waveform_zoom then
                draw_state.tweak_waveform_zoom = false
                settings.waveform_zoom = draw_state.waveform_zoom
                save_settings(settings)
            elseif draw_state.preview then
                draw_state.preview = false
                reaper.gmem_write(10, 0)
            end
        end
    end
    
    --MOUSE DRAG
    if draw_state.draw_crop_region then
        local ds = drag_info.start_x
        if math.abs(ds - m.x) >= 1 then
            local cs = math.min(ds, m.x)
            local ce = math.max(ds, m.x)
            if cs <= margin then cs = margin end
            if ce >= bw + margin then ce = margin + bw end
            local cw = ce - cs
            
            draw_state.cs = cs
            draw_state.cw = cw
        end
    elseif draw_state.drag_sample then
        local window, segment, details = reaper.BR_GetMouseCursorContext()
        if window == 'arrange' then
            local pos = reaper.BR_GetMouseCursorContext_Position()
            pos = reaper.SnapToGrid(0, pos)
            reaper.SetEditCurPos(pos, false, false)

            local mmx, mmy = reaper.GetMousePosition()
            local tr, info = reaper.GetTrackFromPoint(mmx, mmy)
            if tr then reaper.SetOnlyTrackSelected(tr) end
        end
    elseif draw_state.offset_buffer then
        draw_state.offset = draw_state.offset + m.dx/bw
        
        --OFFSET CROP REGION
        draw_state.cs = draw_state.cs + m.dx
        local ce = draw_state.cs + draw_state.cw
        if draw_state.cs <= margin then
            local d_margin = draw_state.cs - margin
            draw_state.cs = margin
            draw_state.cw = draw_state.cw + d_margin
        end
        if ce >= bw + margin then ce = margin + bw end
        draw_state.cw = ce - draw_state.cs
    elseif draw_state.tweak_waveform_zoom then
        draw_state.waveform_zoom = draw_state.waveform_zoom - m.dy * 0.025
        if draw_state.waveform_zoom < 0 then
            draw_state.waveform_zoom = 0
        end
    elseif draw_state.preview then
        local preview_pos = reaper.gmem_read(12)
        if preview_pos > 0 then
            preview_pos = wmod(preview_pos + norm_offset, 1)
            
            local col = {r = theme.waveform_line.r/256, g = theme.waveform_line.g/256, b = theme.waveform_line.b/256}
            if theme.rainbow_waveform_col then
                col = palette(preview_pos*3)
            end

            local xp = preview_pos*bw + margin
            gfx.set(col.r, col.g, col.b, 0.8)
            gfx.line(xp, margin, xp, margin + bh)
        end
    else --IDLE 
        local aax = m.x >= draw_state.cs and m.x <= draw_state.cs + draw_state.cw
        local aay = m.y >= margin and m.y <= margin + bh
        local mouse_in_crop_region = aax and aay
        if m.ctrl and m.shift then
            gfx.setcursor(32645) --ARROW UP/DOWN
        elseif m.alt then
            gfx.setcursor(32515) --CROSSHAIR
        elseif m.ctrl then
            gfx.setcursor(32648) --STOP SIGN
        else
            if mouse_in_crop_region then
                gfx.setcursor(32649) --HAND
            else
                gfx.setcursor(32513) --IBEAM
            end
        end
    end

    local sim_count = #simulations
    for i = sim_count, 1, -1 do
        sim = simulations[i]
        if sim.type == 'PAUSE' then
            if sim.age == sim.lifetime then
                table.remove(simulations, i)
                goto continue
            end
            
            sim.width = sim.width + 3
            local a = (1 - (sim.age/sim.lifetime)) ^ 2
            local x1 = math.max(sim.center - sim.width, margin)
            local x2 = math.min(sim.center + sim.width, margin + bw)
            local y1, y2 = margin, margin + bh

            local col = sim.col
            gfx.set(col.r, col.g, col.b, a) 

            gfx.line(x1, y1, x1, y2)
            gfx.line(x2, y1, x2, y2)
            
            gfx.set(col.r, col.g, col.b, a/3) 
            gfx.rect(x1 + 1, margin, sim.width*2, bh)

            sim.age = sim.age + 1
        end
        ::continue::
    end

    gfx.set(theme.crop_region.r/256,
    theme.crop_region.g/256,theme.crop_region.b/256, theme.crop_region_alpha)
    if jsfx_existed > 0 then
        gfx.rect(draw_state.cs, margin, draw_state.cw, bh)
    end

    --PAUSED TEXT
    local pause_state = reaper.gmem_read(13)
    if pause_state == 1 then
      gfx.setfont(0)
      gfx.set(theme.writer_col.r/256, theme.writer_col.g/256, theme.writer_col.b/256)
      gfx.x = 10
      gfx.y = 10
      gfx.drawstr("Paused")
    end


    --STORE STATE--
    draw_state.bw = bw
    draw_state.bh = bh
end

function window_resize()
    local w = gfx.w
    local h = gfx.h
    local margin = theme.border_margin   
    local bw = w - 2*margin
    local bh = h - 2*margin    

    local nx = (draw_state.cs - margin)/draw_state.bw
    local nw = (draw_state.cs + draw_state.cw - margin)/draw_state.bw
    local new_cs = margin + bw*nx
    local new_cw = margin + (bw*nw) - new_cs
    draw_state.cs = new_cs
    draw_state.cw = new_cw
end

local lm = {x = gfx.mouse_x, y = gfx.mouse_y}
local drag_info = {}
local m_lock = ''
local last_project = reaper.EnumProjects(-1)
function main()
    --PROJECT HANDLING
    local current_project = reaper.EnumProjects(-1)
    if last_project ~= current_project then
        validate_instances()
    end
    last_project = current_project
    
    --WINDOW RESIZE--
    local ww = gfx.w
    local hh = gfx.h
    if ww ~= last_w or hh ~= last_h then
        window_resize()
    end
    last_w = ww
    last_h = hh
    
    --MOUSE STUFF
    local m = {}
    m.x = gfx.mouse_x
    m.y = gfx.mouse_y
    m.l = gfx.mouse_cap&1 == 1 
    m.r = gfx.mouse_cap&2 == 2
    m.ctrl =  reaper.JS_Mouse_GetState(0|00000100)&4  == 4
    m.shift = reaper.JS_Mouse_GetState(0|00001000)&8 == 8
    m.alt =  reaper.JS_Mouse_GetState(0|00010000)&16 == 16
    m.mmb = gfx.mouse_cap&64 == 64 
    m.dx = m.x - lm.x
    m.dy = m.y - lm.y
    
    --Down/Drag
    local draw_count = 0
    if m_lock == '' or m_lock == 'L' then
        if not lm.l and m.l then --down
            drag_info.start_x = m.x
            drag_info.start_y = m.y
            drag_info.type = 'L'
            m_lock = 'L'
            draw(m, 'DOWN', drag_info)
            draw_count = draw_count + 1
        elseif m.l and lm.l then --drag
            draw(m, 'DRAG', drag_info)
            draw_count = draw_count + 1
        elseif lm.l and not m.l then --release
            draw(m, 'RELEASE', drag_info)
            draw_count = draw_count + 1
            drag_info = {}
            m_lock = ''
        end
    end

    if m_lock == '' or m_lock == 'MMB' then
        if not lm.mmb and m.mmb then --down
            drag_info.start_x = m.x
            drag_info.start_y = m.y
            drag_info.type = 'MMB'
            m_lock = 'MMB'
            draw(m, 'DOWN', drag_info)
            draw_count = draw_count + 1
        elseif m.mmb and lm.mmb then --drag
            draw(m, 'DRAG', drag_info)
            draw_count = draw_count + 1
        elseif lm.mmb and not m.mmb then --release
            draw(m, 'RELEASE', drag_info)
            draw_count = draw_count + 1
            drag_info = {}
            m_lock = ''
        end
    end

    if m_lock == '' or m_lock == 'R' then
        if not lm.r and m.r then --down
            m_lock = 'R'
            drag_info.type = 'R'
            drag_info.start_x = m.x
            drag_info.start_y = m.y
            draw(m, 'DOWN', drag_info)
            draw_count = draw_count + 1
        elseif m.r and lm.r then --drag
            
        elseif lm.r and not m.r then --release
            drag_info = {}
            m_lock = ''
        end
    end

    if draw_count == 0 then
        m.lock = ''
        draw(m, 'IDLE', drag_info)
    end

    --THEME SWITCHING
    local sel_id = reaper.gmem_read(16)
    if sel_id ~= 0 then
      themes = get_themes()
      local sel_name = theme_index_name[sel_id]
      if sel_name then
        swap_theme(sel_name)
      end
      reaper.gmem_write(16, 0)
    end
    
    char = gfx.getchar()
    if char == 49 then 
        swap_theme('theme_carbon')
    elseif char == 50 then
        swap_theme('theme_reaper_default')
    elseif char == 51 then
        swap_theme('theme_rainbow')
    elseif char == 52 then
        swap_theme('theme_violet')
    elseif char == 53 then
        swap_theme('theme_classic')
    end
    
    --DEFER/EXIT
    if char ~= -1 and char ~= 27 then
        gfx.update()
        reaper.defer(main)
    end

    lm = table.shallow_copy(m)
end

function exit()
    local window_state = gfx.dock(-1)
    settings.window_state = window_state
    save_settings(settings)
end

--WINDOW STUFF---------------------------
gfx.clear = rgb2num(theme.bg.r, theme.bg.g, theme.bg.b)
local w = 1000 local h = 100
local _, _, sw, sh = reaper.my_getViewport(0, 0, 0, 0, 0, 0, 0, 0, 1)
last_w = gfx.w --window width
last_h = gfx.h --window width
gfx.init("Global Sampler", w, h, 0, sw/2 - w/2, sh/2 - h/2)
if settings.window_state then
    gfx.dock(settings.window_state)
end

reaper.atexit(exit)
validate_instances()
main()
