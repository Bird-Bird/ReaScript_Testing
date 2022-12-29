-- @noindex

function p(msg) reaper.ShowConsoleMsg(tostring(msg)..'\n')end
function reaper_do_file(file) local info = debug.getinfo(1,'S'); local path = info.source:match[[^@?(.*[\/])[^\/]-$]]; dofile(path .. file); end
reaper_do_file('functions.lua')
reaper_do_file('macro_library.lua')
console_is_item_modifiers_compatible = true

function load_macros()
    --LOAD USER MACROS INTO MACROS
    user_macros = check_macros()
    for k,v in pairs(user_macros) do 
        macros[k] = v 
    end
    
    --MOVE MACROS INTO DISPLAY BUFFER
    macro_display = {}
    for k,v in pairs(macros) do 
        table.insert(macro_display, {macro = k, cmd = v})
    end
    table.sort(macro_display, function(a, b) return a.macro < b.macro end)
end
load_macros()

local grammar_table = {
    --SYNTAX
    ["d"]   = "do_times",
    [">"]   = "exit scope",
    ["example"] = {func = print_example},

    --ITEM -> IMMEDIATE
    ["del"] = {func = delete_item},
    ["dei"] = {func = delete_item_at_index, args = {"num"}},
    ["sfo"] = {func = small_fade_out},
    ["fo"]  = {func = fade_out, args = {"num"}},
 
    ["m"]   = {func = mute},
    ["st"]  = {func = stutter},
    ["stt"]  = {func = stutter_div, args = {"num"}},
    ["shf"]  = {func = shuffle_item_positions},
    ["p"]   = {func = pan,  args = {"num"}},
    ["pr"]   = {func = pan_ramp, args = {"num"}},
    ["par"]   = {func = pan_ramp_max, args = {"num"}},
    ["is"]  = {func = invert_selection},
    ["pir"] = {func = pitch_ramp, args = {"num"}},
    ["pirm"] = {func = pitch_ramp_max, args = {"num"}},
    ["tr"]  = {func = transpose, args = {"num"}},
    ["len"] = {func = set_length, args = {"str"}},
    ["lenb"] = {func = set_length_beats, args = {"num"}},
    ["lenr"] = {func = set_length_ratio, args = {"num"}},
    ["ofs"] = {func = offset, args = {"str"}},
    ["rep"] = {func = repeat_item, args = {"num"}},
    ["col"] = {func = random_col_grad},
    ["nud"] = {func = nudge, args = {"str"}},
    ["nudb"] = {func = nudge_beats, args = {"num"}},
    ["fxo"] = {func = fix_overlaps},
    ["fxe"] = {func = fix_overlaps_extend},
    ["sel"] = {func = select_pattern, args = {"str"}},
    ["sl"]  = {func = select_last},
    ["sf"]  = {func = select_first},
    ["ten"] = {func = tension, args = {"num"}},
    ["v"]   = {func = volume, args = {"num"}},
    ["vr"]   = {func = volume_ramp, args = {"num"}},
    ["vor"]   = {func = volume_ramp_max, args = {"num"}},
    ["si"]  = {func = select_index, args = {"num"}},
    ["sai"]  = {func = select_at_index, args = {"num"}},
    ["di"]  = {func = deselect_index, args = {"num"}},
    ["spl"]  = {func = split, args = {"num"}},
    ["rev"] = {func = reverse},
    ["bs"] =  {func = bake_selection},
    ["plm"]  = {func = multiply_playrate, args = {"num"}},
    ["pl"]  = {func = set_playrate, args = {"num"}},
    ["sr"]  = {func = stretch, args = {"num"}},
    ["spe"] = {func = split_items_every, args = {"str"}},

    --ITEM -> RANDOM
    ["rs"]  = {func = random_select},
    ["rss"]  = {func = random_select_chance, args = {"num"}},
    ["rm"]  = {func = random_mute},
    ["rd"]  = {func = random_delete},
    ["rst"] = {func = random_stutter},
    ["rp"]  = {func = random_pan},
    ["rr"]  = {func = random_reverse},
 
    --ITEM -> SELECTION
    ["sm"]  = {func = select_muted},
    ["sa"]  = {func = restore_selection},
    ["osa"]  = {func = override_select_all},
    ["tag"] = {func = tag_items, args = {"str"}},
    ["get"] = {func = select_tag, args = {"str"}}
}

local help_menu = {

}

function execute_stack(stack)
    for i = 1, #stack do
        local func = stack[i]
        func()
    end
end

--ADD RANDOM ARG
function get_function_from_command(cmd, c, i)
    local cm = grammar_table[c]
    if cm then
        local c_func = cm.func
        if cm.args then 
            local args = {}
            for j = 1, #cm.args do
                local arg_type = cm.args[j]
                local arg_cmd = cmd[i + j]
                if arg_type == "num" then arg_cmd = tonumber(arg_cmd) end
                table.insert(args, arg_cmd)
            end
            local func = bind(c_func, table.unpack(args))
            return func, #cm.args
        else
            return c_func, 0
        end
    else
        return nil, 0
    end
end

--ERROR HANDLING--
--INCONSISTENT NUMBER OF SCOPE START/ENDS
--COMMANDS THAT DO NOT EXIST
--MACROS THAT DO NOT EXIST
--UNEXPECTED TOKEN >
--MISSING ARGS ERROR
--HALT IF COMPILATION TAKES TOO LONG
--CIRCULAR MACRO REFERENCE
--MISSING LOOP COUNTER
function check_input_errors(macro)
    --INVALID COMMAND
    local i = 1
    while i <= #macro do 
        local cmd = macro[i]
        local func, offs = get_function_from_command(macro, cmd, i)
        
        --CHECK INVALID COMMANDS
        if not grammar_table[cmd] and
        not macros[cmd:sub(2)] and 
        cmd:match("d%d+") ~= cmd then
            return {description = "Invalid command: " .. cmd}           
        end

        --LOOP
        if cmd == 'd' then
            return {description = "Missing loop counter: " .. cmd}           
        end
        
        --CHECK MISSING ARGS
        if offs > 0 then 
            for j = 1, offs do
                if i + j > #macro then
                    return {description = "Missing argument for command: " .. cmd}
                else
                    local arg = macro[i + j]
                    local cm = grammar_table[cmd]
                    local type = cm.args[j]
                    if type == "num" and not tonumber(arg) then
                        return {description = "Missing or invalid argument for command: " .. cmd}
                    elseif type == "str" then
                        if cmd == "sel" and not validate_sel_arg(arg) then
                            return {description = "Invalid argument for command: " .. cmd}
                        end
                        if cmd == "len" and not validate_len_arg(arg) then
                            return {description = "Invalid argument for command: " .. cmd}
                        end
                        if cmd == "ofs" and not validate_len_arg(arg) then
                            return {description = "Invalid argument for command: " .. cmd}
                        end
                        if cmd == "nud" and not validate_len_arg(arg) then
                            return {description = "Invalid argument for command: " .. cmd}
                        end
                        if cmd == "spe" and not validate_len_arg(arg) then
                          return {description = "Invalid argument for command: " .. cmd}
                        end
                    end
                end
            end
        end
        
        i = i + offs + 1
    end

    --SCOPE ERRORS
    local scope_count = 0
    i = 1
    while i <= #macro do 
        local c = macro[i]
        if string.starts(c, 'd') and c ~= "del" and c ~= 'di' and c ~= 'dei' then
            scope_count = scope_count + 1
        elseif c == ">" then
            scope_count = scope_count - 1
        end
        if scope_count < 0 then
            return {description = "Unexpected scope end: >"}
        end
        i = i + 1
    end
    if scope_count > 0 then
        return {description = "Missing a '>' somewhere."}
    end

    return nil
end

--CALL STACK COMPILATION
function get_stack(macro)
    local macro = str_split(macro, ' ')
    macro = remove_whitespace(macro)
    local scope_start = {}
    
    local err = check_input_errors(macro)
    if err then return macro, err end

    --DETECT SCOPES
    local start_compilation_time = reaper.time_precise()
    local loop_scopes = {}
    local i = 1
    while i <= #macro do
        local c = macro[i]
        if string.starts(c, 'd') and c ~= "del" and c ~= 'di' and c ~= 'dei' then
            table.insert(scope_start, i)
        elseif c == ">" then
            --COMPILE SCOPE
            --CUT OUT
            local start_pos = scope_start[#scope_start]
            local end_pos = i
            local temp_buf = {}
            for j = start_pos, end_pos do
                table.insert(temp_buf, macro[start_pos])
                table.remove(macro, start_pos)
            end
            
            --SPLICE
            local id = temp_buf[1]
            local loop = math.floor(tonumber(id:sub(2)))
            for j = 1, loop do 
                for k = #temp_buf-1, 2, -1 do
                    local cmd = temp_buf[k]
                    table.insert(macro, start_pos, cmd)
                end
            end
            scope_start = {}
            i = 0
        elseif string.starts(c, '*') then
            --HANDLE MACROS, SPLICE OUT, ASSEMBLE, PLACE BACK IN
            local index = i
            table.remove(macro, index)
            local macro_str = macros[c:sub(2)]
            if macro_str then
                local cmds = str_split(macro_str, ' ')
                for k = #cmds, 1, -1 do
                    local cmd = cmds[k]
                    table.insert(macro, index, cmd)
                end
            end
            i = 0
        end
        
        --HALT COMPILATION
        if reaper.time_precise() - start_compilation_time > 4 then
            return macro, {description = "Compilation halted because it was taking too long. This is likely because of circular references. (ie. a macro that contains itself)"}
        end
        
        i = i + 1
    end
    
    --CHECK ERRORS AFTER COMPILATION
    err = check_input_errors(macro)
    if err then return macro, err end

    return macro, err
end

local command_stack = {}
function execute_command(input_command, reactive)
    --COMPILE USER INPUT INTO PRIMITIVES
    local cmd_buffer, err = get_stack(input_command)   
    if not err then
        --TURN COMMAND BUFFER INTO FUNCTIONS
        local stack = {}
        local i = 1
        while i <= #cmd_buffer do
            local c = cmd_buffer[i]
            local func, index_offs, is_macro = get_function_from_command(cmd_buffer, c, i)
            table.insert(stack, func)
            i = i + index_offs + 1
        end

        --RUN
        reactive_stack = stack
        return true
    else
        if not reactive then
            reaper.ShowMessageBox(err.description, "Functional Console - Syntax Error", 0)
            return false, input_command
        else
            return false, err
        end
    end
end

function execute_reactive_stack()
    execute_stack(reactive_stack)
end

function save_macro_reactive(macro_name, input)
    local cmd_buf = str_split(input, ' ')
    cmd_buf = remove_whitespace(cmd_buf)
    write_new_macro(macro_name, build_str(cmd_buf))
    load_macros()
end

function save_macro(macro, reactive)
    --PREPARE BUFFER
    local cmd = macro:sub(1, -2)
    local cmd_buf = str_split(cmd, ' ')
    cmd_buf = remove_whitespace(cmd_buf)
    
    --CHECK ERRORS
    local err = check_input_errors(cmd_buf)
    if err then
        if not reactive then
            reaper.ShowMessageBox(err.description, "Functional Console - Syntax Error", 0)
            return false, macro
        else
            return false, err
        end
    else
        --PROMPT SAVE
        local retval, macro_name = reaper.GetUserInputs( "Save Macro", "1", 'Name,extrawidth=100', '')
        if retval then 
            --SAVE MACRO, RELOAD
            write_new_macro(macro_name, build_str(cmd_buf))
            load_macros()
            
            reaper.ShowMessageBox('Macro "' .. macro_name .. '" saved succesfully!', "Macro - Success", 0)
            return true, '*' .. macro_name
        else
            return false, macro
        end
    end
end

--ExTERNAL HOOKS
function ext_execute(input, has_undo, clear_items)
  if not clear_items then full_reset() end
  local success, err = execute_command(input, true)
  if success then
    reaper.PreventUIRefresh(1)
    if has_undo then
        reaper.Undo_BeginBlock()
    end
    init_console(clear_items)
    execute_reactive_stack()
    if has_undo then
        reaper.Undo_EndBlock('Functional Console Command', -1)
    end
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
    return true, nil
  else
    return false, err.description
  end
end

function ext_reset(no_reset)
  full_reset(no_reset)
end

function ext_select_all()
  override_select_all()
end

function ext_reset_seed()
  reset_seed()
end
