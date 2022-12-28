-- @description Functional Console
-- @version 0.99.7.4
-- @author BirdBird
-- @provides
--    [nomain]functional_console_libraries/functions.lua
--    [nomain]functional_console_libraries/base.lua
--    [nomain]functional_console_libraries/macro_library.lua
--    [main]BirdBird_Functional Console Reactive.lua
--@changelog
--  + Added new commands: pl, plm, sr, spe
--  pl: sets take playrate
--  plm: multiplies take playrate
--  sr: stretches items seperately
--  spe: splits item every given interval, optionally by beats with "b" suffix

function p(msg) reaper.ShowConsoleMsg(tostring(msg)..'\n')end
function reaper_do_file(file) local info = debug.getinfo(1,'S'); path = info.source:match[[^@?(.*[\/])[^\/]-$]]; dofile(path .. file); end
reaper_do_file('functional_console_libraries/base.lua')

function get_user_input(last_command)
    local retval, input_command = reaper.GetUserInputs( "Functional Console", "1", ',extrawidth=200', last_command)
    if retval then
        if input_command:sub(-1) == "?" then
            --PROMPT SAVE MACRO
            local success, command = save_macro(input_command)
            get_user_input(command)
        else
            --RUN COMMAND
            local success, command = execute_command(input_command)
            
            if not success then
                get_user_input(command)
            else
                reaper.PreventUIRefresh(1)
                reaper.Undo_BeginBlock()
                execute_reactive_stack()
                reaper.Undo_EndBlock('Functional Console Command', -1)
                reaper.PreventUIRefresh(-1)
                reaper.UpdateArrange()
            end
        end
    end
end

init_console()
get_user_input('')

