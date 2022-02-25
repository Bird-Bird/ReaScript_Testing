-- @noindex
-- @version 0.99.2

function p(msg) reaper.ShowConsoleMsg(tostring(msg)..'\n')end
function str_split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

function string.starts(String,Start)
    return string.sub(String,1,string.len(Start))==Start
end

function remove_whitespace(macro)
    local i = 1
    while i <= #macro do
        if macro[i] == '' then
            table.remove(macro, i)
            i = i - 1
        end
        i = i + 1
    end
    return macro
end

function build_str(cmd_buf)
    local s = cmd_buf[1]
    for i = 2, #cmd_buf do
        s = s .. ' ' .. cmd_buf[i]
    end
    return s
end

local info = debug.getinfo(1,'S')
local path = info.source:match[[^@?(.*[\/])[^\/]-$]];
local file_name = "user_macros.txt"
function check_macros()
    local default_macro = "pr=pr pr pr"
    local user_macros = io.open(path .. file_name, 'r')
    if not user_macros then
        user_macros = io.open(path .. file_name, 'w')
        user_macros:write(default_macro)
        user_macros:close()
    end

    local user_macros = {}
    for line in io.lines(path .. file_name) do 
        local dat = str_split(line, '=')
        local macro_name = dat[1]
        local macro_cmd = dat[2]
        if string.starts(macro_cmd, ' ') then macro_cmd = macro_cmd:sub(2) end
        macro_name = macro_name:gsub("%s+", "")
        user_macros[macro_name] = macro_cmd
    end
    return user_macros
end

function write_new_macro(macro_name, cmd)
    local user_macros = io.open(path .. file_name, 'a')
    user_macros:write('\n' .. macro_name .. ' = ' .. cmd)
    user_macros:close()
end

function is_loop_command(cmd)
    if string.starts(cmd, 'd') and tonumber(cmd:sub(2)) then
        return true
    else
        return false
    end
end

function validate_sel_arg(arg)
    local t = {}
    arg:gsub(".",function(c) table.insert(t,c) end)
    for i = 1, #t do
        if i % 2 == 1 and (t[i] ~= '1' and t[i] ~= '0') then
            return false
        elseif i % 2 == 0 and t[i] ~= '-' then return false end
    end
    return true
end

--https://stackoverflow.com/a/42062321
function print_table(node)
    local cache, stack, output = {},{},{}
    local depth = 1
    local output_str = "{\n"

    while true do
        local size = 0
        for k,v in pairs(node) do
            size = size + 1
        end

        local cur_index = 1
        for k,v in pairs(node) do
            if (cache[node] == nil) or (cur_index >= cache[node]) then

                if (string.find(output_str,"}",output_str:len())) then
                    output_str = output_str .. ",\n"
                elseif not (string.find(output_str,"\n",output_str:len())) then
                    output_str = output_str .. "\n"
                end

                -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
                table.insert(output,output_str)
                output_str = ""

                local key
                if (type(k) == "number" or type(k) == "boolean") then
                    key = "["..tostring(k).."]"
                else
                    key = "['"..tostring(k).."']"
                end

                if (type(v) == "number" or type(v) == "boolean") then
                    output_str = output_str .. string.rep('\t',depth) .. key .. " = "..tostring(v)
                elseif (type(v) == "table") then
                    output_str = output_str .. string.rep('\t',depth) .. key .. " = {\n"
                    table.insert(stack,node)
                    table.insert(stack,v)
                    cache[node] = cur_index+1
                    break
                else
                    output_str = output_str .. string.rep('\t',depth) .. key .. " = '"..tostring(v).."'"
                end

                if (cur_index == size) then
                    output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
                else
                    output_str = output_str .. ","
                end
            else
                -- close the table
                if (cur_index == size) then
                    output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
                end
            end

            cur_index = cur_index + 1
        end

        if (size == 0) then
            output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
        end

        if (#stack > 0) then
            node = stack[#stack]
            stack[#stack] = nil
            depth = cache[node] == nil and depth + 1 or depth - 1
        else
            break
        end
    end

    table.insert(output,output_str)
    output_str = table.concat(output)
    p(output_str)
end

function bind(f, ...)
    local args = {...}
    return function()
        return f(table.unpack(args))
    end
end

--=====UTILITY=====--
--INITIALIZE RANDOM
math.randomseed(os.clock())
math.random()
math.random()
math.random()
function rand()
    return math.random()
end

function get_selected_items()
    local items = {}
    local sel_item_count = reaper.CountSelectedMediaItems(0)
    for i = 0, sel_item_count - 1 do 
        local item = reaper.GetSelectedMediaItem(0, i)
        table.insert(items, item)
    end
    return items
end

local initial_item_sel = get_selected_items()
function bake_selection()
    local items = get_selected_items()
    initial_item_sel = items
end

function grid_is_triplet()
    local ret, division, swingmode, swingamt = reaper.GetSetProjectGrid( 0, false)
    local r_div = 1/division
    if r_div % 3 == 0 then
        return true
    elseif r_div % 2 == 0 then
        return false
    else
        return false
    end
end

--https://forums.cockos.com/showpost.php?p=2456585&postcount=24
function copy_media_item_to_track( item, track, position )
    local _, chunk = reaper.GetItemStateChunk( item, "", false )
    chunk = chunk:gsub("{.-}", "") -- Reaper auto-generates all GUIDs
    local new_item = reaper.AddMediaItemToTrack( track )
    reaper.SetItemStateChunk( new_item, chunk, false )
    reaper.SetMediaItemInfo_Value( new_item, "D_POSITION" , position )
    table.insert(initial_item_sel, new_item)
    return new_item
end

function stutter_item(item)
    local track = reaper.GetMediaItem_Track(item)
    local item_pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
    local item_len = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')

    local div = grid_is_triplet() and 3 or 2
    local start_pos = item_pos
    local r_item_len = item_len/div

    reaper.SetMediaItemInfo_Value(item, 'D_LENGTH', r_item_len)
    for i = 1, div-1 do
        local p = start_pos + r_item_len*i
        copy_media_item_to_track(item, track, p)
    end
end

--https://iquilezles.org/www/articles/palettes/palettes.htm
function palette(t)
    local a = {r = 0.5, g = 0.5, b = 0.5}
    local b = {r = 0.5, g = 0.5, b = 0.5}
    local c = {r = 1, g = 1, b = 1}
    local d = {r = 0, g = 0.33, b = 0.67}

    local brightness = 0.2
    
    local col = {}
    col.r = math.min(a.r + brightness + math.cos((c.r*t + d.r)*6.28318)*b.r,1)
    col.g = math.min(a.g + brightness + math.cos((c.g*t + d.g)*6.28318)*b.g,1)
    col.b = math.min(a.b + brightness + math.cos((c.b*t + d.b)*6.28318)*b.b,1)
    return col
end

--=====COMMAND IMPLEMENTATIONS=====--
function print_random_number()
    p(rand())
end

function random_stutter()
    local items = get_selected_items()
    for i = 1, #items do 
        local item = items[i]
        local r = rand()
        if rand() >= 0.5 then
            stutter_item(item)
        end
    end
end

function stutter()
    local items = get_selected_items()
    for i = 1, #items do 
        local item = items[i]
        stutter_item(item)
    end
end

function random_select()
    local items = get_selected_items()
    for i = 1, #items do 
        local item = items[i]
        local r = rand()
        if rand() >= 0.5 then
            reaper.SetMediaItemSelected(item, false)
        end
    end
end

function random_select_chance(prob)
    local items = get_selected_items()
    for i = 1, #items do 
        local item = items[i]
        local r = rand()
        if rand() >= prob then
            reaper.SetMediaItemSelected(item, false)
        end
    end
end

function select_muted()
    local items = get_selected_items()
    for i = 1, #items do 
        local item = items[i]
        local muted = reaper.GetMediaItemInfo_Value( item, 'B_MUTE')        
        if muted == 0 then
            reaper.SetMediaItemSelected(item, false)
        end
    end
end

function mute()
    local items = get_selected_items()
    for i = 1, #items do 
        local item = items[i]
        local muted = reaper.SetMediaItemInfo_Value( item, 'B_MUTE', 1)        
    end
end

function delete_item()
    local items = get_selected_items()
    for i = 1, #items do 
        local item = items[i]
        local track = reaper.GetMediaItem_Track(item)
        reaper.DeleteTrackMediaItem(track, item)
    end    
end

function restore_selection()
    for i = 1, #initial_item_sel do
        local item = initial_item_sel[i]
        if  reaper.ValidatePtr( item, 'MediaItem*') then
            reaper.SetMediaItemSelected(item, true)
        end
    end
end

function invert_selection()
    for i = 1, #initial_item_sel do
        local item = initial_item_sel[i]
        if  reaper.ValidatePtr( item, 'MediaItem*') then
            local sel_state = reaper.IsMediaItemSelected(item)
            reaper.SetMediaItemSelected(item, sel_state and 0 or 1)
        end
    end
end

function small_fade_out()
    local items = get_selected_items()
    for i = 1, #items do 
        local item = items[i]
        reaper.SetMediaItemInfo_Value(item, 'D_FADEOUTLEN', 10/1000)
    end  
end

function fade_out(len)
    local items = get_selected_items()
    for i = 1, #items do 
        local item = items[i]
        reaper.SetMediaItemInfo_Value(item, 'D_FADEOUTLEN', len/1000)
    end  
end

function transpose(offset)
    local items = get_selected_items()
    for i = 1, #items do 
        local item = items[i]
        local take = reaper.GetMediaItemTake(item, 0)

        local pitch = reaper.GetMediaItemTakeInfo_Value(take, 'D_PITCH')    
        reaper.SetMediaItemTakeInfo_Value(take, 'D_PITCH', pitch + offset)
    end
end

function pitch_ramp(offset)
    local items = get_selected_items()
    for i = 1, #items do 
        local item = items[i]
        local take = reaper.GetMediaItemTake(item, 0)
        reaper.SetMediaItemTakeInfo_Value(take,'B_PPITCH', 0)
        local po = 2 ^ ((offset * (i-1))/12)
        local playrate = reaper.GetMediaItemTakeInfo_Value(take, 'D_PLAYRATE')    
        reaper.SetMediaItemTakeInfo_Value(take, 'D_PLAYRATE', playrate*po)
    end
end

function set_length(length) 
    local value
    if length:sub(-1) == 'b' then
        local len_beat =  reaper.TimeMap2_beatsToTime(0, 1)
        value = tonumber(length:sub(1, -2)) * len_beat
    else
        value = tonumber(length)
    end

    local items = get_selected_items()
    for i = 1, #items do 
        local item = items[i]
        reaper.SetMediaItemInfo_Value(item, 'D_LENGTH', value)
    end
end

function validate_len_arg(arg)
    if arg:sub(-1) == 'b' then
        local value = tonumber(arg:sub(1, -2))
        if value then return true end
    else
        local value = tonumber(arg)
        if value then return true end
    end
    return false
end

function get_item_bounds(items)
    local min_start = 1000000000
    local max_end = 0
    for i = 1, #items do 
        local item = items[i]
        local pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
        local length = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
        min_start = math.min(min_start, pos)
        max_end   = math.max(max_end, pos + length)
    end

    return min_start, max_end
end

function repeat_item(times)
    local items = get_selected_items()
    local min_start, max_end = get_item_bounds(items)
    local duration = max_end - min_start
    for j = 1, times do
        for i = 1, #items do 
            local item = items[i]
            local track = reaper.GetMediaItem_Track(item)
            
            local pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
            
            copy_media_item_to_track(item, track, pos + duration*j)
        end
    end
end

function select_pattern(pattern)
    local pattern = str_split(pattern, '-')
    local items = get_selected_items()
    for i = 1, #items do
        local item = items[i]
        local m = ((i-1) % #pattern) + 1
        if pattern[m] == '1' then
            reaper.SetMediaItemSelected(item, true)
        else 
            reaper.SetMediaItemSelected(item, false)
        end
    end
end

function random_col_grad()
    local start_grad = rand()
    local items = get_selected_items()
    for i = 1, #items do
        local item = items[i]
        local take = reaper.GetMediaItemTake(item, 0)
        local t = (i - 1)/(#items-1)
        if t ~= t then t = 0 end
        
        local col = palette(start_grad + t/3)
        local col_native = reaper.ColorToNative(
            math.floor(col.r*255 + 0.5),
            math.floor(col.g*255 + 0.5),
            math.floor(col.b*255 + 0.5))|0x1000000

        reaper.SetMediaItemInfo_Value(item, 'I_CUSTOMCOLOR', col_native)
    end
end

function nudge(length)
    local value
    if length:sub(-1) == 'b' then
        local len_beat =  reaper.TimeMap2_beatsToTime(0, 1)
        value = tonumber(length:sub(1, -2)) * len_beat
    else
        value = tonumber(length)
    end

    local items = get_selected_items()
    for i = 1, #items do
        local item = items[i]
        local pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
        reaper.SetMediaItemInfo_Value(item, 'D_POSITION', pos + value)
    end
end

function fix_overlaps()
    local items = get_selected_items()
    for i = 1, #items do
        local item = items[i]
        if i < #items then
            local next_item = items[i+1]
            local next_pos = reaper.GetMediaItemInfo_Value(next_item, 'D_POSITION')

            local pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
            local length = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
            if pos + length > next_pos then
                reaper.SetMediaItemInfo_Value(item, 'D_LENGTH', next_pos - pos)
            end
        end
    end
end

function fix_overlaps_extend()
    local items = get_selected_items()
    local min_start, max_end = get_item_bounds(items)
    local last_len = 0
    for i = 1, #items do
        local item = items[i]
        if i < #items then
            local next_item = items[i+1]
            local next_pos = reaper.GetMediaItemInfo_Value(next_item, 'D_POSITION')

            local pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
            local length = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
            last_len = next_pos - pos
            reaper.SetMediaItemInfo_Value(item, 'D_LENGTH', last_len)
        else
            local pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
            reaper.SetMediaItemInfo_Value(item, 'D_LENGTH', max_end - pos)
        end
    end
end

function select_last()
    local items = get_selected_items()
    for i = 1, #items do
        local item = items[i]
        if i < #items then
            reaper.SetMediaItemSelected(item, false)
        else
            reaper.SetMediaItemSelected(item, true)
        end
    end
end

function select_first()
    local items = get_selected_items()
    for i = 1, #items do
        local item = items[i]
        if i == 1 then
            reaper.SetMediaItemSelected(item, true)
        else
            reaper.SetMediaItemSelected(item, false)
        end
    end
end

function tension(amt)
    local rt = (amt/10)*-1
    if math.abs(rt) > 1 then
        rt = rt > 0 and 1 or -1
    end
    local items = get_selected_items()
    
    local min_start, max_end = get_item_bounds(items)
    table.sort(items, function(a,b) return
        reaper.GetMediaItemInfo_Value(a, 'D_POSITION') < 
        reaper.GetMediaItemInfo_Value(b, 'D_POSITION')
    end)
    local duration = max_end - min_start

    local pos_list = {}
    for i = 1, #items do
        local item = items[i]
        local pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
        
        local x = (pos - min_start)/duration
        local new_norm = (rt*x-x)/(2*rt*x-rt-1)
        local new_pos = min_start + duration*new_norm
        local pos = reaper.SetMediaItemInfo_Value(item, 'D_POSITION', new_pos)
    end
end

function volume(nudge)
    local items = get_selected_items()
    for i = 1, #items do
        local item = items[i]
        local item_vol = reaper.GetMediaItemInfo_Value(item, 'D_VOL')
        reaper.SetMediaItemInfo_Value(item, 'D_VOL', item_vol*10^(0.05*nudge))
    end
end

function select_index(index)
    local items = get_selected_items()
    for i = 1, #items do
        local item = items[i]
        if index == i then
            reaper.SetMediaItemSelected(item, true)
        else
            reaper.SetMediaItemSelected(item, false)
        end
    end
end

function deselect_index(index)
    local items = get_selected_items()
    for i = 1, #items do
        local item = items[i]
        if index == i then
            reaper.SetMediaItemSelected(item, false)
        end
    end
end

function reverse()
    --REVERSE ENVELOPES
    local items = get_selected_items()
    for i = 1, #items do
        local item = items[i]
        reaper.SetMediaItemSelected(item, true)

        local take = reaper.GetMediaItemTake(item, 0)
        
        --DATA
        local item_pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
        local item_length = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
        local play_rate = reaper.GetMediaItemTakeInfo_Value(take, 'D_PLAYRATE')
        local item_end = item_pos + item_length
        
        --FADE
        local fade_in_length =  reaper.GetMediaItemInfo_Value(item, 'D_FADEINLEN')
        local fade_in_dir =     reaper.GetMediaItemInfo_Value(item, 'D_FADEINDIR')
        local fade_in_shape =   reaper.GetMediaItemInfo_Value(item, 'C_FADEINSHAPE')
        local fade_out_length = reaper.GetMediaItemInfo_Value(item, 'D_FADEOUTLEN')
        local fade_out_dir =    reaper.GetMediaItemInfo_Value(item, 'D_FADEOUTDIR')
        local fade_out_shape =  reaper.GetMediaItemInfo_Value(item, 'C_FADEOUTSHAPE')

        reaper.SetMediaItemInfo_Value(item, 'D_FADEINLEN', fade_out_length)
        reaper.SetMediaItemInfo_Value(item, 'D_FADEINDIR', fade_out_dir)
        reaper.SetMediaItemInfo_Value(item, 'C_FADEINSHAPE', fade_out_shape)
        reaper.SetMediaItemInfo_Value(item, 'D_FADEOUTLEN', fade_in_length)
        reaper.SetMediaItemInfo_Value(item, 'D_FADEOUTDIR', fade_in_dir)
        reaper.SetMediaItemInfo_Value(item, 'C_FADEOUTSHAPE', fade_in_shape)

        --ENVELOPES
        local takeEnvelopeCount =  reaper.CountTakeEnvelopes(take)
        for j = 0, takeEnvelopeCount - 1 do
            local env =  reaper.GetTakeEnvelope(take, j)
            local point_count =  reaper.CountEnvelopePoints(env)
            local point_buffer = {}
            
            --FILL, CLEAR
            for k = point_count - 1, 0, -1 do 
                local e_retval, e_time, e_value, e_shape, e_tension, e_selected = reaper.GetEnvelopePoint(env, k)
                local e = {time = e_time, tension = e_tension, value = e_value, shape = e_shape, tension = e_tension, selected = e_selected}
                table.insert( point_buffer, e)
                reaper.DeleteEnvelopePointEx( env, -1, k)
            end

            --INSERT
            for k = 1, #point_buffer do
                local p = point_buffer[k]
                local tension = k < #point_buffer and point_buffer[k+1].tension or p.tension
                local shape = k < #point_buffer and point_buffer[k+1].shape or p.shape
                reaper.InsertEnvelopePoint( env, item_length*play_rate - p.time, p.value, shape, tension*-1, p.selected, true )
            end
            reaper.Envelope_SortPoints(env)
        end
    end
    
    --REVERSE TAKE
    reaper.Main_OnCommand(41051, -1)
end