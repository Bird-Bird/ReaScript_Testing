-- @noindex

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

function get_ctrl(ctx)
  local key_mods = reaper.ImGui_GetKeyMods(ctx)
  local mod = reaper.ImGui_KeyModFlags_Ctrl and reaper.ImGui_KeyModFlags_Ctrl() or reaper.ImGui_ModFlags_Ctrl()
  return (key_mods & mod) ~= 0 
end

function table.shallow_copy(t)
    local t2 = {}
    for k,v in pairs(t) do
        t2[k] = v
    end
    return t2
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

--HELP MENU
local help_text = 
[[[b]COMMANDS
m: Mutes selected items
st: Stutters selected items
stt arg1: Stutters selected items
- arg1: Number of repeats
pir arg1: Creates a pitch ramp offsetting the pitch every item.
- arg1: Pitch offset per item
tr arg1: Transposes selected items by incrementing/decrementing take pitch
- arg1: Pitch offset in semitones
len arg1: Sets the length of the selected items
- arg1: Length in seconds by default. However using the suffix "b" will set the item length in beats instead. (ie. "len 4b")
lenb arg1: Sets the length of the selected items in beats
- arg1: Length in beats
lenr arg1: Sets the length of the selected items by ratio
- arg1: A value in the range [0, 1], ie. passing in 1 will not change the item length, 0.5 will set it to half length, 0.25 will set it to quarter...
rep arg1: Duplicates items to repeat selection
- arg1: Number of repeats
col: Creates a color gradient on selected items
nud arg1: Nudges items
- arg1: Nudge distance in seconds. However using the suffix "b" will set the item nudge in beats instead. (ie. "nud 1b")
nudb arg1: Nudges items in beats
- arg1: Nudge distance in beats
fxo: Fixes overlaps on selected items
fxe: Fixes overlaps on selected items, extends items to fill empty space
sfo: Applies a small fade out (10ms) to selected items.
fo arg1: Adds a fade out to items.
- arg1: Fade duration in milliseconds.
ten arg1: Squashes item positions towards their start or end position. May require running "fxe" or "fxo" afterwards to fix overlaps.
- arg1: The tension amount in a range between [-10,10], negative values will squash item positions towards their start position while positive values will squash them towards their end point.
v arg1: Offsets item volume in dBs.
- arg1: Offset in dBs.
vr arg1: Creates a volume ramp offsetting volume every item.
- arg1: Offset in dBs.
rev: Reverses selected items, will also reverse envelopes and fades.
spl arg1: Splits items.
- arg1: Number of splits
ofs arg1: Changes take offset in items.
- arg1: Offset amount in seconds. However using the suffix "b" will offset the take in beats instead. (ie. "offs 1b")

[b]SELECTION COMMANDS
Selection commands are very important as they are the backbone of a lot of cool macros.
sf: Keeps the first item in the selection selected.
sl: Keeps the last item in the selection selected.
sa: Selects all initial items and the items that were created during the execution of commands. Useful to restore selection after running other commands in series that filter the selection.
bs: Bakes selection to initial selection, running the command "sa" after this will only return the baked items
osa: Selects all items, ignoring bakes.
is: Inverts selection
rs: Keeps random items selected, with approximately 50% chance.
rss arg1: Keeps random items selected, based on probability.
- arg1: A value between [0,1] that determines what percentage of items get randomly selected. As an example, "rss 0" will deselect all items, "rss 0.5" will approximately keep half the items selected, "rss 1" will keep all items selected.
sel arg1: Uses a custom pattern to filter the selection.
- arg1: Selection pattern. The selection pattern has a format of sequence of 1 and 0s seperated by a '-'. For example the command "sel 1-0" will select every other item, "sel 0-0-1" will select every third item, "sel 0-1-1-0" will select every second and third item out of every four items...
tag arg1: Tags a selection of items with the specified name. You can later restore this selection by calling the "get" command.
- arg1: Name for the tag.
get arg1: Restores the item selection to a specific tag, deselecting all other items. If the tag isn't found no items will be selected.
- arg1: Name for the tag.
si arg1: Keeps item at a specific index selected while deselecting others.
-arg1: Target item. As an example, if you have 4 items selected and run the command "si 3" only the third item will remain selected.
di arg1: Deselects an item a specific index.
- arg1: Target item.
]]
help_table = {}
function build_help_table()
    local t = {}
    local lines = str_split(help_text, '\n')
    local i = 1
    while i <= #lines do
        local line = lines[i]
        if not string.starts(line, '-') and string.find(line, '%:') then
            local cmd_spl = str_split(line, ':')
            
            local cmd = cmd_spl[1]
            local cmd_desc = cmd_spl[2]:sub(2)

            local o = {
                name = cmd,
                desc = cmd_desc,
                args ={}
            }
            table.insert(t, o)
        elseif string.starts(line, '-') then
            table.insert(t[#t].args, line:sub(3))
        else
            local text = line
            local bold = string.starts(line, '[b]')
            if bold then text = text:sub(4) end
            table.insert(t, {text = text, bold = bold})
        end
        i = i +1
    end
    help_table = t
end
build_help_table()


--HANDLING MACROS
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

function validate_macro_name(macro_name)
    local s = str_split(macro_name, ' ')
    s = remove_whitespace(s)
    if #s == 0 then
        return false, 'Enter a name for the macro!'
    elseif #s > 1 then
        return false, 'Macro name must be a single word.'
    elseif s[1]:match("%W") then
        return false, 'Only numbers and letters allowed in macro names.'
    elseif macros[s[1]] then
        return false, 'A macro with the same name already exists.'
    else
        return true, '', s[1]
    end
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
function rand()
    return math.random()
end

--ALSO PURIFY TABLE
function get_selected_items()
    local items = {}
    local sel_item_count = reaper.CountSelectedMediaItems(0)
    for i = 0, sel_item_count - 1 do 
        local item = reaper.GetSelectedMediaItem(0, i)
        table.insert(items, item)
    end
    return items
end

function get_initial_item_data()
    local d = {items = {}, chunks = {}, tracks = {}}
    local items = get_selected_items()
    for i = 1, #items do
        local item = items[i]
        local track = reaper.GetMediaItem_Track(item)
        local ret, chunk = reaper.GetItemStateChunk(item, '', false)

        table.insert(d.items, item)
        table.insert(d.tracks, track)
        table.insert(d.chunks, chunk)
    end
    return d
end

function clear_items(t)
    for i = 1, #t do
        local item = t[i]
        if reaper.ValidatePtr(item, 'MediaItem*') then
            local track = reaper.GetMediaItem_Track(item)
            reaper.DeleteTrackMediaItem(track, item)
        end
    end
end

function restore_items(t)
    for i = 1, #t.items do
        local item = t.items[i]
        local track = t.tracks[i]
        local chunk = t.chunks[i]

        local new_item = reaper.AddMediaItemToTrack(track)
        chunk = chunk:gsub("{.-}", "") -- Reaper auto-generates all GUIDs
        reaper.SetItemStateChunk( new_item, chunk, false )
    end
end

local seed = reaper.time_precise()
function init_random()
    math.randomseed(seed)
    math.random()
    math.random()
    math.random()
end

local initial_item_sel
local reactive_items
local clear_batch = {}
local tags ={}
function init_console(reactive)
  tags = {}  
  init_random()
    if reactive then
        --CLEAR LINGERING ITEMS
        if #clear_batch > 0 then
            for i = 1, #clear_batch do
                clear_items(clear_batch[i])
            end
            clear_batch = {}
        end

        --CONSECUTIVE RUNS
        if reactive_items then
            clear_items(initial_item_sel)
            restore_items(reactive_items)
        end

        reactive_items = get_initial_item_data()
        initial_item_sel = table.shallow_copy(reactive_items.items)
    else
        initial_item_sel = get_selected_items()
    end
end

function tag_items(tag)
  local items = get_selected_items()
  tags[tag] = items
end

function select_tag(tag)
  local items = get_selected_items()
  for i = 1, #items do
    reaper.SetMediaItemSelected(items[i], false)
  end
  local tag_items = tags[tag]
  if tag_items then
    for i = 1, #tag_items do
      local item = tag_items[i]
      if reaper.ValidatePtr2(0, item, 'MediaItem*') then
        reaper.SetMediaItemSelected(item, true)
      end
    end
  end
end

function override_select_all()
  if initial_item_sel then
    for i = 1, #clear_batch do
      local batch = clear_batch[i]
      for j = 1, #batch do
        local item = batch[j]
        if reaper.ValidatePtr(item, 'MediaItem*') then
          table.insert(initial_item_sel, item)
        end
      end
    end
    clear_batch = {}
    restore_selection()
  end
end

function select_at_index(index)
  local tbl = {}
  if initial_item_sel then
    for i = 1, #clear_batch do
      local batch = clear_batch[i]
      for j = 1, #batch do
        local item = batch[j]
        if reaper.ValidatePtr(item, 'MediaItem*') then
          table.insert(tbl, item)
        end
      end
    end
    for i = 1, #initial_item_sel do 
      local item = initial_item_sel[i]
      if reaper.ValidatePtr(item, 'MediaItem*') then
        table.insert(tbl, item)
      end
    end
  end
  if #tbl > 0 then
    local i = index
    if index > #tbl then i = #tbl 
    elseif index < 1 then i = 1 end
    local item = tbl[i]
    reaper.SetMediaItemSelected(item, true)
  end
end

function reset_seed()
    seed = reaper.time_precise()*100
    init_random()
end

function full_reset(no_reset)
    initial_item_sel = nil
    reactive_items = nil
    clear_batch = {}
    tags = {}

    if not no_reset then
      init_console(true)
    end
end

function get_random_num(arg)
    local vals = arg:sub(2)
    local s,e = table.unpack(str_split(vals, '='))
    s = tonumber(s)
    e = tonumber(e)

    local val = rand()*(e-s) + s
    return val
end

function validate_random_arg(arg)
    local vals = arg:sub(2)
    local values = str_split(vals, '=')
    print_table(values)
    if not values or #values ~= 2 then
        return false
    end
    local s,e = table.unpack(values)
    s = tonumber(s)
    e = tonumber(e)
    if not e or not s then
        return false
    end
    
    return true
end

function print_example()
  local ex = [[
dofile(reaper.GetResourcePath() .. '/Scripts/BirdBird ReaScript Testing/Functional Console/functional_console_libraries/base.lua')
local ret, err = ext_execute("*p1", true)]]
  reaper.ShowConsoleMsg(ex)
end

--ADD ITEMS TO A CLEAR BATCH
function bake_selection()
    table.insert(clear_batch, initial_item_sel)
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

function shuffle(t)
  local tbl = {}
  for i = 1, #t do
    tbl[i] = t[i]
  end
  for i = #tbl, 2, -1 do
    local j = math.random(i)
    tbl[i], tbl[j] = tbl[j], tbl[i]
  end
  return tbl
end

function shuffle_item_positions()
  local items = get_selected_items()
  local items_shuffled = shuffle(items)
  local pos = {}
  for i = 1, #items do
    local item_s = items_shuffled[i]
    local item_pos = reaper.GetMediaItemInfo_Value(item_s, 'D_POSITION')
    table.insert(pos, item_pos)
  end
  for i = 1, #pos do
    local pos_sh = pos[i]
    reaper.SetMediaItemInfo_Value(items[i], 'D_POSITION', pos_sh)
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

function stutter_item_div(item, div)
    local track = reaper.GetMediaItem_Track(item)
    local item_pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
    local item_len = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')

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

function stutter_div(div)
    local div = math.floor(div + 0.5)
    local items = get_selected_items()
    for i = 1, #items do 
        local item = items[i]
        stutter_item_div(item, div)
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

function delete_item_at_index(i)
  local items = get_selected_items()
  if i >= 1 and i <= #items then
    local item = items[i]
    local track = reaper.GetMediaItem_Track(item)
    reaper.DeleteTrackMediaItem(track, item)
  end
end

function sanitize_initial_selection()
    for i = #initial_item_sel, 1, -1 do
        local item = initial_item_sel[i]
        if not reaper.ValidatePtr( item, 'MediaItem*') then
            table.remove(initial_item_sel, i)
        end
    end
end

function restore_selection()
    sanitize_initial_selection()
    for i = 1, #initial_item_sel do
        local item = initial_item_sel[i]
        if  reaper.ValidatePtr( item, 'MediaItem*') then
            reaper.SetMediaItemSelected(item, true)
        end
    end
end

function invert_selection()
    sanitize_initial_selection()
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

function multiply_playrate(amount)
    local items = get_selected_items()
    for i = 1, #items do
        local item = items[i]
        local take = reaper.GetActiveTake(item)    
        local playrate = reaper.GetMediaItemTakeInfo_Value( take, "D_PLAYRATE")
        reaper.SetMediaItemTakeInfo_Value( take, "D_PLAYRATE", playrate*amount)
    end
end

function set_playrate(amount)
    local items = get_selected_items()
    for i = 1, #items do
        local item = items[i]
        local take = reaper.GetActiveTake(item)    
        reaper.SetMediaItemTakeInfo_Value( take, "D_PLAYRATE", amount)
    end
end

function stretch(amount)
    local items = get_selected_items()
    for i = 1, #items do
        local item = items[i]
        local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        local take = reaper.GetActiveTake(item)    
        local playrate = reaper.GetMediaItemTakeInfo_Value( take, "D_PLAYRATE")
        reaper.SetMediaItemTakeInfo_Value( take, "D_PLAYRATE", playrate/amount)
        reaper.SetMediaItemInfo_Value(item, "D_LENGTH", length*amount)
    end
end

function split_items_every(interval)
    local value
    if interval:sub(-1) == 'b' then
        local len_beat =  reaper.TimeMap2_beatsToTime(0, 1)
        value = tonumber(interval:sub(1, -2)) * len_beat
    else
        value = tonumber(interval)
    end
    if value == 0 then
      return
    end

    local items = get_selected_items()
    local div = value
    for i = 1, #items do
        local item = items[i]
        local pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
        local length = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
        local new_item, t_pos = item, pos + div
        while t_pos < pos + length do 
            new_item = reaper.SplitMediaItem(new_item, t_pos)
            table.insert(initial_item_sel, new_item)
            t_pos = t_pos + div
        end
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

function pitch_ramp_max(offset)
    local items = get_selected_items()
    local offset = offset/(#items - 1)
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

function set_length_beats(length)
  local len_beat =  reaper.TimeMap2_beatsToTime(0, 1)
  local items = get_selected_items()
  for i = 1, #items do 
      local item = items[i]
      reaper.SetMediaItemInfo_Value(item, 'D_LENGTH', len_beat * length)
  end
end

function set_length_ratio(ratio)
  local items = get_selected_items()
  for i = 1, #items do 
      local item = items[i]
      local len = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
      reaper.SetMediaItemInfo_Value(item, 'D_LENGTH', len*ratio)
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

function nudge_beats(value)
  local len_beat =  reaper.TimeMap2_beatsToTime(0, 1)
  local items = get_selected_items()
  for i = 1, #items do
      local item = items[i]
      local pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
      reaper.SetMediaItemInfo_Value(item, 'D_POSITION', pos + value*len_beat)
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

function volume_ramp(nudge)
  local items = get_selected_items()
  for i = 1, #items do
      local item = items[i]
      local item_vol = reaper.GetMediaItemInfo_Value(item, 'D_VOL')
      reaper.SetMediaItemInfo_Value(item, 'D_VOL', item_vol*10^(0.05*nudge*(i-1)))
  end
end

function volume_ramp_max(n)
  local items = get_selected_items()
  local nudge = n/(#items - 1)
  for i = 1, #items do
      local item = items[i]
      local item_vol = reaper.GetMediaItemInfo_Value(item, 'D_VOL')
      reaper.SetMediaItemInfo_Value(item, 'D_VOL', item_vol*10^(0.05*nudge*(i-1)))
  end
end

function pan(amount)
  local amount = math.min(math.max(-1, amount), 1)
  local items = get_selected_items()
  for i = 1, #items do
    local item = items[i]
    local take = reaper.GetMediaItemTake(item, 0)
    reaper.SetMediaItemTakeInfo_Value(take, 'D_PAN', amount)
  end
end

function pan_ramp(offset)
  local offset = math.min(math.max(-1, offset), 1)
  local items = get_selected_items()
  for i = 1, #items do
    local item = items[i]
    local take = reaper.GetMediaItemTake(item, 0)
    local pan = reaper.GetMediaItemTakeInfo_Value(take, 'D_PAN')
    reaper.SetMediaItemTakeInfo_Value(take, 'D_PAN', pan + offset*(i - 1))
  end
end

function pan_ramp_max(o)
  local offset = math.min(math.max(-1, o), 1)
  local items = get_selected_items()
  local offset = o/(#items - 1)
  for i = 1, #items do
    local item = items[i]
    local take = reaper.GetMediaItemTake(item, 0)
    local pan = reaper.GetMediaItemTakeInfo_Value(take, 'D_PAN')
    reaper.SetMediaItemTakeInfo_Value(take, 'D_PAN', pan + offset*(i - 1))
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

function split(times)
    local items = get_selected_items()
    for i = 1, #items do
        local item = items[i]
        local pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
        local length = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
        local div = length/times
        local new_item = item
        for i = 1, times - 1 do
            new_item = reaper.SplitMediaItem(new_item, pos + div*i)
            table.insert(initial_item_sel, new_item)
        end
    end
end

function offset(length)
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
        local take = reaper.GetMediaItemTake(item, 0)
        reaper.SetMediaItemTakeInfo_Value(take, 'D_STARTOFFS', value)
    end
end