-- @noindex

function p(msg) reaper.ShowConsoleMsg(tostring(msg)..'\n')end
function reaper_do_file(file) local info = debug.getinfo(1,'S'); path = info.source:match[[^@?(.*[\/])[^\/]-$]]; dofile(path .. file); end

--CHECK DEPENDENCY
if not reaper.APIExists('ImGui_GetVersion') then
    local text = 'Reactive version of functional console requires the ReaImGui extension to run. You can install it through ReaPack.'
    local ret = reaper.ShowMessageBox(text, 'Functional Console - Missing Dependency', 0)
    return
end
dofile(reaper.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/imgui.lua')('0.6')
reaper_do_file('functional_console_libraries/base.lua')


local ctx = reaper.ImGui_CreateContext('My script')
local size = reaper.GetAppVersion():match('OSX') and 12 or 14
local font = reaper.ImGui_CreateFont('sans-serif', size)
local font_normal = reaper.ImGui_CreateFont('sans-serif', size)
local font_normal_bold = reaper.ImGui_CreateFont('sans-serif', size,  reaper.ImGui_FontFlags_Bold())
local font_normal_bold_title = reaper.ImGui_CreateFont('sans-serif', math.floor(size*1.5),  reaper.ImGui_FontFlags_Bold())
local italic_font = reaper.ImGui_CreateFont('sans-serif', math.floor(size*1.7))
local italic_font_small = reaper.ImGui_CreateFont('sans-serif', math.floor(size*1.2))

reaper.ImGui_AttachFont(ctx, font)
reaper.ImGui_AttachFont(ctx, font_normal)
reaper.ImGui_AttachFont(ctx, font_normal_bold)
reaper.ImGui_AttachFont(ctx, font_normal_bold_title)
reaper.ImGui_AttachFont(ctx, italic_font)
reaper.ImGui_AttachFont(ctx, italic_font_small)

local FLT_MIN, FLT_MAX = reaper.ImGui_NumericLimits_Float()
local button_color  = reaper.ImGui_ColorConvertHSVtoRGB(3 / 7.0, 0.0, 0.20, 1.0)
local button_color_dim  = reaper.ImGui_ColorConvertHSVtoRGB(3 / 7.0, 0.0, 0.80, 1.0)

local hovered_color = reaper.ImGui_ColorConvertHSVtoRGB(3 / 7.0, 0.0, 0.25, 1.0)
local hovered_color_dim = reaper.ImGui_ColorConvertHSVtoRGB(3 / 7.0, 0.0, 0.85, 1.0)

local active_color  = reaper.ImGui_ColorConvertHSVtoRGB(3 / 7.0, 1.0, 0.30, 1.0)
local active_color_dim  = reaper.ImGui_ColorConvertHSVtoRGB(3 / 7.0, 0.0, 0.90, 1.0)

local bg_color = 0xFAFAFAff

local input = ''
local macro_name = ''
local exec = false
local succes, err
local first_run = true
local last_input_modal = ''
function main_frame()
    --TITLE
    local exit_frame = false
    reaper.ImGui_PushFont(ctx, italic_font_small)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(),        button_color)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), hovered_color)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(),  active_color)
    if reaper.ImGui_Button(ctx, 'FUNCTIONAL CONSOLE', -FLT_MIN, 30) then
        full_reset()
        reset_seed()
        local ctrl = get_ctrl(ctx)
        if not ctrl then
            input = ''
        else
            --HOLDING CTRL
            exec = true
        end
        first_run = true
    end
    reaper.ImGui_PopStyleColor(ctx, 3)
    reaper.ImGui_PopFont(ctx)

    --INPUT TEXT
    reaper.ImGui_PushItemWidth( ctx, -1)
    if first_run then
        reaper.ImGui_SetKeyboardFocusHere(ctx)
        first_run = false
    end
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), button_color)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(), bg_color)
    rv, input = reaper.ImGui_InputText(ctx, '##label', input);
    if reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) and reaper.ImGui_IsKeyPressed(ctx, 0x0D) then
        exit_frame = true
    end
    if rv or exec then
        success, err = execute_command(input, true)
        if success then
            reaper.PreventUIRefresh(1)
            reaper.Undo_BeginBlock()
            init_console(true)
            execute_reactive_stack()
            reaper.Undo_EndBlock('Functional Console Command', -1)
            reaper.PreventUIRefresh(-1)
            reaper.UpdateArrange()
        end
        exec = false
    end
    reaper.ImGui_PopStyleColor(ctx, 2)
    reaper.ImGui_PopItemWidth(ctx);

    --INPUT TEXT BG
    local draw_list = reaper.ImGui_GetWindowDrawList(ctx)
    local text_min_x, text_min_y = reaper.ImGui_GetItemRectMin(ctx)
    local text_max_x, text_max_y = reaper.ImGui_GetItemRectMax(ctx)
    reaper.ImGui_DrawList_AddRect(draw_list, text_min_x, text_min_y, text_max_x, text_max_y, button_color)

    --BUTTONS AND TEXT
    reaper.ImGui_PushFont(ctx, font_normal)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(),        button_color)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), hovered_color)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(),  active_color)
    if reaper.ImGui_Button(ctx, 'Seed') then
        reset_seed()
        exec = true
    end
    
    --SAVE BUTTON
    reaper.ImGui_SameLine(ctx, 0, 3)
    if reaper.ImGui_Button(ctx, 'Save') then
        if err then
            macro_err = err
            reaper.ImGui_OpenPopup(ctx, 'Create Macro - Syntax Error')
        elseif input:match("%s+") == input or input == '' then
            macro_err = {description = "Cannot save empty command."}
            reaper.ImGui_OpenPopup(ctx, 'Create Macro - Syntax Error')
        else
            reaper.ImGui_OpenPopup(ctx, 'Create Macro')
        end
    end

    --ERROR MODAL
    reaper.ImGui_PushStyleColor(ctx,  reaper.ImGui_Col_PopupBg(), bg_color)
    reaper.ImGui_PushStyleColor(ctx,  reaper.ImGui_Col_TitleBgActive(), button_color)
    reaper.ImGui_PushStyleColor(ctx,  reaper.ImGui_Col_TitleBg(), button_color)
    reaper.ImGui_SetNextWindowSize(ctx, 255, 75)
    if reaper.ImGui_BeginPopupModal(ctx, 'Create Macro - Syntax Error', nil) then
        --ERROR
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), button_color)
        reaper.ImGui_TextWrapped(ctx, macro_err.description)
        reaper.ImGui_PopStyleColor(ctx)

        local esc = reaper.ImGui_IsKeyPressed(ctx, 0x1B) and reaper.ImGui_IsWindowFocused(ctx)
        if reaper.ImGui_Button(ctx, 'Ok') or esc then
            reaper.ImGui_CloseCurrentPopup(ctx)
        end
        reaper.ImGui_EndPopup(ctx)
    end
    reaper.ImGui_PopStyleColor(ctx, 3)
    
    --SAVE MODAL
    reaper.ImGui_PushStyleColor(ctx,  reaper.ImGui_Col_PopupBg(), bg_color)
    reaper.ImGui_PushStyleColor(ctx,  reaper.ImGui_Col_TitleBgActive(), button_color)
    reaper.ImGui_PushStyleColor(ctx,  reaper.ImGui_Col_TitleBg(), button_color)
    reaper.ImGui_SetNextWindowSize(ctx, 319, 99)
    if reaper.ImGui_BeginPopupModal(ctx, 'Create Macro', nil) then
        --NAME INPUT
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), button_color)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(), bg_color)        
        reaper.ImGui_PushItemWidth( ctx, -1)
        if reaper.ImGui_IsWindowAppearing(ctx) then
            reaper.ImGui_SetKeyboardFocusHere(ctx)
        end
        rv, macro_name = reaper.ImGui_InputText(ctx, '##Macro', macro_name);       
        reaper.ImGui_PopStyleColor(ctx, 2)

        local draw_list = reaper.ImGui_GetWindowDrawList(ctx)
        local text_min_x, text_min_y = reaper.ImGui_GetItemRectMin(ctx)
        local text_max_x, text_max_y = reaper.ImGui_GetItemRectMax(ctx)
        reaper.ImGui_DrawList_AddRect(draw_list, text_min_x, text_min_y, text_max_x, text_max_y, button_color)

        --ERROR CODE
        local macro_is_valid, m_err, macro_parsed_name = validate_macro_name(macro_name)
        if not macro_is_valid then
            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), button_color)
            reaper.ImGui_Text(ctx, m_err)
            reaper.ImGui_PopStyleColor(ctx)
            reaper.ImGui_BeginDisabled(ctx)
        end
        if reaper.ImGui_Button(ctx, 'Ok') then
            --SAVE MACRO
            save_macro_reactive(macro_parsed_name, input)
            macro_name = ''
            
            --RESET INPUT
            input = '*' .. macro_parsed_name
            first_run = true
            exec = true

            reaper.ImGui_CloseCurrentPopup(ctx)
        end
        reaper.ImGui_SameLine(ctx, 0, 3)
        if not macro_is_valid then
            reaper.ImGui_EndDisabled(ctx)                
        end
        local esc = reaper.ImGui_IsKeyPressed(ctx, 0x1B) and reaper.ImGui_IsWindowFocused(ctx)
        if reaper.ImGui_Button(ctx, 'Cancel') or esc then
            reaper.ImGui_CloseCurrentPopup(ctx)
        end
        
        reaper.ImGui_EndPopup(ctx)
    end
    reaper.ImGui_PopStyleColor(ctx, 3)
    
    --MACRO BUTTON
    reaper.ImGui_SameLine(ctx, 0, 3)
    if reaper.ImGui_Button(ctx, 'Macros') then
        reaper.ImGui_OpenPopup(ctx, 'Macros')
        last_input_modal = input
    end
    
    --MACRO POPUP
    reaper.ImGui_PushStyleColor(ctx,  reaper.ImGui_Col_PopupBg(), bg_color)
    reaper.ImGui_PushStyleColor(ctx,  reaper.ImGui_Col_TitleBgActive(), button_color)
    reaper.ImGui_PushStyleColor(ctx,  reaper.ImGui_Col_TitleBg(), button_color)
    reaper.ImGui_PushStyleColor(ctx,  reaper.ImGui_Col_MenuBarBg(), bg_color)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding(),  4, 4)
    reaper.ImGui_SetNextWindowSize(ctx, 272, 500, reaper.ImGui_Cond_FirstUseEver())
    if reaper.ImGui_BeginPopupModal(ctx, 'Macros', nil) then
        if reaper.ImGui_Button(ctx, 'Seed') then
            reset_seed()
            exec = true            
        end

        --MACRO SELECTABLES
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(), bg_color)
        local w, h = reaper.ImGui_GetWindowSize(ctx);
        local y = reaper.ImGui_GetCursorPosY( ctx )
        if reaper.ImGui_BeginListBox(ctx, '##listbox_1', -1, h - 29 - y) then
            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), button_color)
            for i = 1, #macro_display do
                local k,v = macro_display[i].macro, macro_display[i].cmd
                reaper.ImGui_PushID(ctx, i)
                if reaper.ImGui_Selectable(ctx, k, false,  
                reaper.ImGui_SelectableFlags_DontClosePopups()) then
                    input = v
                    exec = true
                end
                local draw_list = reaper.ImGui_GetWindowDrawList(ctx)
                local text_min_x, text_min_y = reaper.ImGui_GetItemRectMin(ctx)
                local text_max_x, text_max_y = reaper.ImGui_GetItemRectMax(ctx)
                reaper.ImGui_DrawList_AddRect(draw_list, text_min_x, text_min_y-1, text_max_x, text_max_y, button_color)
                reaper.ImGui_PopID(ctx)
            end
            reaper.ImGui_PopStyleColor(ctx)
            reaper.ImGui_EndListBox(ctx)

            local draw_list = reaper.ImGui_GetWindowDrawList(ctx)
            local text_min_x, text_min_y = reaper.ImGui_GetItemRectMin(ctx)
            local text_max_x, text_max_y = reaper.ImGui_GetItemRectMax(ctx)
            reaper.ImGui_DrawList_AddRect(draw_list, text_min_x+1, text_min_y, text_max_x-1, text_max_y, button_color)
        end
        reaper.ImGui_PopStyleColor(ctx)

        --BOTTOM BUTTONS
        if reaper.ImGui_Button(ctx, 'Ok') then
            reaper.ImGui_CloseCurrentPopup(ctx)
        end
        reaper.ImGui_SameLine(ctx, 0, 3)
        local esc = reaper.ImGui_IsKeyPressed(ctx, 0x1B) and reaper.ImGui_IsWindowFocused(ctx)
        if reaper.ImGui_Button(ctx, 'Cancel') or esc then
            input = last_input_modal
            exec = true
            reaper.ImGui_CloseCurrentPopup(ctx)
        end

        reaper.ImGui_EndPopup(ctx)
    end

    --HELP
    local window_width = reaper.ImGui_GetWindowWidth(ctx)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), button_color_dim)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), hovered_color_dim)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(),  active_color_dim)
    reaper.ImGui_SameLine(ctx, window_width - 39)
    if reaper.ImGui_Button(ctx, 'Help') then
        help_window_open = true
    end
    reaper.ImGui_PopStyleColor(ctx,3) 

    reaper.ImGui_PopStyleColor(ctx,4)
    reaper.ImGui_PopStyleColor(ctx,3)
    reaper.ImGui_PopStyleVar(ctx)


    --ERROR TEXT
    if err then
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), button_color)
        reaper.ImGui_Text(ctx, err.description)
        reaper.ImGui_PopStyleColor(ctx)
    end
    
    reaper.ImGui_PopFont(ctx)
    return exit_frame
end

function help_frame()
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), button_color)
    for i = 1, #help_table do
        local line = help_table[i]
        if line.text then
            if line.bold then
                --TITLE
                reaper.ImGui_PushFont(ctx, font_normal_bold_title)
                local window_w = reaper.ImGui_GetWindowSize(ctx);
                local text_w = reaper.ImGui_CalcTextSize(ctx, line.text);
                reaper.ImGui_SetCursorPosX(ctx, (window_w - text_w) * 0.5);
                reaper.ImGui_TextWrapped(ctx, line.text)
                reaper.ImGui_PopFont(ctx)
            else
                --REGULAR TEXT
                reaper.ImGui_PushFont(ctx, font_normal)
                reaper.ImGui_TextWrapped(ctx, line.text)
                reaper.ImGui_PopFont(ctx)
            end
            if line.text ~= '' then
                reaper.ImGui_Separator(ctx)
            end
        else
            local cmd = line.name
            local desc = line.desc
            local args = line.args

            --CMD NAME
            reaper.ImGui_PushFont(ctx, font_normal_bold)
            reaper.ImGui_TextWrapped(ctx, cmd .. ':')
            reaper.ImGui_PopFont(ctx)

            --ARGS
            reaper.ImGui_PushFont(ctx, font_normal)
            reaper.ImGui_TextWrapped(ctx, desc)
            for j = 1, #args do
                reaper.ImGui_Bullet(ctx)
                reaper.ImGui_TextWrapped(ctx, args[j])
            end
            reaper.ImGui_PopFont(ctx)
            reaper.ImGui_Separator(ctx)
        end
    end
    reaper.ImGui_PopStyleColor(ctx)
    
    local esc = reaper.ImGui_IsKeyPressed(ctx, 0x1B) and reaper.ImGui_IsWindowFocused(ctx)
end

local open = true
function loop()
    --GUI
    local window_flags = reaper.ImGui_WindowFlags_None()    
    local esc = false
    if open then
        --INIT
        reaper.ImGui_PushFont(ctx, font)
        reaper.ImGui_SetNextWindowSize(ctx, 693, 133, reaper.ImGui_Cond_FirstUseEver())
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(), bg_color)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgActive(), button_color)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBg(), button_color)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding(),  4, 4)
        visible, open = reaper.ImGui_Begin(ctx, 'Functional Console', true, window_flags)
        reaper.ImGui_PopStyleColor(ctx, 3)
        reaper.ImGui_PopStyleVar(ctx)
        
        --WINDOW
        if visible then
            reaper.ImGui_PushFont(ctx, italic_font)
            local ex = main_frame()
            esc = reaper.ImGui_IsKeyPressed(ctx, 0x1B) and reaper.ImGui_IsWindowHovered(ctx)
            esc = esc or ex
            reaper.ImGui_PopFont(ctx)    
            reaper.ImGui_End(ctx)
        end
        reaper.ImGui_PopFont(ctx)
    end

    --HELP WINDOW
    if help_window_open then
        reaper.ImGui_PushFont(ctx, font)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(), bg_color)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgActive(), button_color)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBg(), button_color)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarBg(), active_color_dim)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding(),  4, 4)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ScrollbarRounding(),  0)
        reaper.ImGui_SetNextWindowSize(ctx, 300, 600, reaper.ImGui_Cond_FirstUseEver())
        visible_help, help_window_open = reaper.ImGui_Begin(ctx, 'Functional Console - Help', true, window_flags)
        reaper.ImGui_PopStyleColor(ctx, 4)
        reaper.ImGui_PopStyleVar(ctx, 2)
        if visible_help then
            help_frame()
            reaper.ImGui_End(ctx)
        end
        reaper.ImGui_PopFont(ctx)
    end

    --RUN
    if (open or help_window_open) and not esc then
        reaper.defer(loop)
    else
        reaper.ImGui_DestroyContext(ctx)
    end
end

reaper.defer(loop)

