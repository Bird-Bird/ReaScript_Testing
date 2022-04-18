-- @noindex

function p(msg) reaper.ShowConsoleMsg(tostring(msg)..'\n') end
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
offs arg1: Changes take offset in items.
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
