-- @noindex

macros = {
    ["f"]   = "sf bs",
    ["gr"] = "*f len 0.25b rep 15 sel 0-1 nud 0.05b sa fxo",
    ["md"] = "sm del sa",
    
    ["st1"] = "*f len 4b d3 st > d5 rs st sa > rs del sa sfo col",
    ["st2"] = "*f len 8b d3 st > col d4 rss 0.8 st pir 0.5 is tr 7 sa > rss 0.01 rev col sa",
    ["st3"] = "*f *st2 ten -5 pir -2 fxe sfo",
    ["st4"] = "*f len 8b st st st sfo col d8 rs st pir -0.05 col rs rev sa > rss 0.2 del sa ten -7 fxe rss 0.2 del sa",

    ["r1"] = "*f len 0.25b rep 15 sel 0-1 nud 0.05b sa sel 1-0-1 is m del sa fxo si 5 st st col is col sa pir 1 sa sl rev sa fxe sl len 0.20b sa",
    ["r2"] = "*f len 0.25b rep 15 sel 0-1 nud 0.07b sa fxo sfo pir 1 col sl len 0.18b sa",
    ["r3"] = "*f *gr sel 1-0-1-1-1-1 col is sfo rev v -10 col sa sl len 0.20b sa sel 0-0-0-0-0-1 tr 12 col sa",
    ["r4"] = "*f *r6 rs st st sa rs rs rev col sa sfo",
    ["r5"] = "*f len 4b d5 st > sel 1-0-0 d3 st > col sa pir 1",
    ["r6"] = "*f len 0.25b rep 15 st ten -7 pir 1 fxe col",

    ["p1"] = "*f len 32b d4 d4 rss 0.4 st osa > > rss 0.1 rev osa sfo col",
}

--HANDLING MACROS
local info = debug.getinfo(1,'S')
local path = info.source:match[[^@?(.*[\/])[^\/]-$]];
local file_name = "user_files/user_macros.txt"
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