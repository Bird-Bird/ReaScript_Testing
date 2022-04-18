-- @noindex

local info = debug.getinfo(1,'S')
local path = info.source:match[[^@?(.*[\/])[^\/]-$]]
local stack_path = path .. 'user_files/modifier_stacks/'
local scripts_path = path .. 'user_files/generated_scripts/'
local format = '.modstk'
function get_files_in_path(path, filter) 
  local files = {}
  local count = 1
  local str = ""
  if path:sub(-1,-1) ~= "/" and path:sub(-1,-1) ~= "\\" then path = path.."/" end
  reaper.EnumerateFiles(path, -1)
  local filename = ""
  while str ~= nil do
    str = reaper.EnumerateFiles(path, count-1)
    if str ~= nil and filter ~= nil then
      if str:match(filter) then
        filename = str
      end
    else
      filename = str
    end
    if filename ~= nil then files[#files+1] = filename end
    filename = nil
    count = count+1
  end
  if files[1] == '' then
    table.remove(files, 1)
  end
  return files
end

function strip_display_id_from_stack(stack)
  for i = 1, #stack do
    if stack[i].display_id then
      stack[i].display_id = nil
    end
  end
end

function save_modifier_stack(stack, name)
  local stack_new = deepcopy(stack)
  strip_display_id_from_stack(stack_new)
  
  local full_path = stack_path .. name .. format
  local new_file = io.open(full_path, 'w')
  local d = json.encode(stack_new)
  new_file:write(d)
  new_file:close()
end

function get_modifier_stacks()
  local t = {}
  local files = get_files_in_path(stack_path, format)
  for i = 1, #files do
    local f = files[i]
    local full_path = path .. f
    local trimmed_name = f:gsub('%..+', '')
    table.insert(t, {
      full_path = full_path,
      file_name = f,
      trimmed_name = trimmed_name}
    )
  end
  return t
end

function reload_stacks()
  modifier_stacks = get_modifier_stacks()
end

function reset_modifier_stack(stack)
  for i = 1, #stack do
    local mod = stack[i]
    local map = mod.map
    reset_command(map)
  end
end

function compile_modifier_stack(modifier_stack)
  local cmd_buf = {}
  for i = 1, #modifier_stack do
    local mod = modifier_stack[i].map
    local cmd_str = build_command(mod)
    table.insert(cmd_buf, cmd_str)
  end
  local cmd_str = table.concat(cmd_buf, ' bs ')
  return cmd_str
end

function load_modifier_stack()
  local r, file_name = reaper.GetUserFileNameForRead(stack_path, "Load Modifier Stack", format)
  if r then
    local stack = io.open(file_name, 'r')
    if not stack then
      return false, nil
    else
      local st = stack:read("*all")
      st_json = json.decode(st)
      return true, st_json
    end
  else
    return false, nil
  end
end

local preset_invalid_error = 'No valid modifier stack preset found in clipboard.'
function get_modifier_stack_from_clipboard()
  local str = reaper.ImGui_GetClipboardText(ctx)
  local status, ret = pcall(json.decode, str)
  if not status then
    reaper.ShowMessageBox(preset_invalid_error, 'Item Modifiers - Error', 0)
  else
    if not ret.is_modstk then
      reaper.ShowMessageBox(preset_invalid_error, 'Item Modifiers - Error', 0)
    else
      return true, ret.stack
    end
  end
  return false, nil
end

local script_lines = [[dofile(reaper.GetResourcePath() .. '/Scripts/BirdBird ReaScript Testing/Item Modifiers/libraries/functional_console/base.lua')
local ret, err = ext_execute("CMDCMD", true)]]
function generate_lua_script_from_stack(stack)
  local cmd_str = compile_modifier_stack(stack)
  local script_str = script_lines:gsub("%C%M%D%C%M%D", cmd_str)
  local r, file_name = reaper.JS_Dialog_BrowseForSaveFile('Save generated script file', scripts_path, '', '.lua')
  if r == 1 then
    file_name = file_name .. '.lua'
    local new_file = io.open(file_name, 'w')
    new_file:write(script_str)
    new_file:close()
  end
end

