-- @noindex

local FLT_MIN, FLT_MAX = reaper.ImGui_NumericLimits_Float()

function filter_actions(actions, filter_text)
  local filter = reaper.ImGui_CreateTextFilter(filter_text)
  local t = {}
  for i = 1, #actions do 
    local action = actions[i]
    local found = true
    for word in filter_text:gmatch("%S+") do
      local an = action.name:lower()
      found = found and an:find(word:lower(), 1, true)
    end
    if found or reaper.ImGui_TextFilter_PassFilter(filter, action.name) then
      table.insert(t, action)
    end
  end
  return t
end

local actions = get_all_actions()
local filtered_actions = actions
local filter = ''
function action_listbox(ctx, height)
  local ret, sel_action = false, nil
  rv, filter = reaper.ImGui_InputText(ctx, 'Filter', filter)
  if rv then 
    filtered_actions = filter_actions(actions, filter) 
  end
  
  local cursor_y = reaper.ImGui_GetCursorPosY(ctx)
  local window_height = reaper.ImGui_GetWindowHeight(ctx)
  local list_height = height
  if window_height - cursor_y > height then
    list_height = -FLT_MIN
  end

  local clipper = reaper.ImGui_CreateListClipper(ctx)
  reaper.ImGui_ListClipper_Begin(clipper, #filtered_actions)
  if reaper.ImGui_BeginListBox(ctx, '##Act', -FLT_MIN, list_height) then
    while reaper.ImGui_ListClipper_Step(clipper) do
      local display_start, display_end = reaper.ImGui_ListClipper_GetDisplayRange(clipper)
      for i = display_start, display_end - 1 do
        local action = filtered_actions[i + 1]
        reaper.ImGui_PushID(ctx, i + 1)
        if reaper.ImGui_Selectable(ctx, action.name, false) then
          ret, sel_action = true, action
        end
        reaper.ImGui_PopID(ctx)
      end
    end
    reaper.ImGui_EndListBox(ctx)
  end
  return ret, sel_action
end

function set_action_list_filter(text)
  filter = text
  filtered_actions = filter_actions(actions, text)
end