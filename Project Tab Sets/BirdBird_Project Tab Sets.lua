-- @description Project Tab Sets
-- @version 0.1
-- @author BirdBird
-- @provides
--  [nomain]gui.lua
--  [nomain]json.lua
--  [nomain]projects.lua
--  [nomain]settings.lua
--  [nomain]tab_sets.lua
--  [nomain]theme.lua
--  [nomain]resources/JetBrainsMono-Medium.ttf
--  [nomain]tab_sets/_tab_sets.txt
--@changelog
--  + Alpha release.

version = 0.1

user_has_SWS = reaper.APIExists('CF_GetSWSVersion')

if not reaper.JS_Dialog_BrowseForSaveFile then
  reaper.ShowMessageBox("Project Tab Sets requires the js_ReaScriptAPI extension to run. You can install it through ReaPack.", "Project Tab Sets - Error", 0)
  return
end

if not reaper.APIExists('ImGui_GetVersion') then
  reaper.ShowMessageBox("Project Tab Sets requires the ReaImGui extension to run. You can install it through ReaPack.", "Project Tab Sets - Error", 0)
  return
end

dofile(reaper.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/imgui.lua')('0.8')
function reaper_do_file(file) local info = debug.getinfo(1,'S'); local path = info.source:match[[^@?(.*[\/])[^\/]-$]]; dofile(path .. file); end

reaper_do_file("json.lua")
reaper_do_file("settings.lua")
reaper_do_file("projects.lua")
reaper_do_file("tab_sets.lua")
reaper_do_file("theme.lua")
reaper_do_file("gui.lua")

local ctx = reaper.ImGui_CreateContext('Project Tab Sets')
load_resources(ctx)

local show_style_editor = false
if show_style_editor then 
  demo = dofile(reaper.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/ReaImGui_Demo.lua')
end

local frame = frame
local function loop()
  if show_style_editor then         
    demo.PushStyle(ctx)
    demo.ShowDemoWindow(ctx)
  end

  push_theme(ctx)
  
  reaper.ImGui_SetNextWindowSize(ctx, 355, 456, reaper.ImGui_Cond_FirstUseEver())
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0xF5D3B3FF) --title text
  local visible, open = reaper.ImGui_Begin(ctx, 'Project Tab Sets', true)
  reaper.ImGui_PopStyleColor(ctx)
  
  if visible then
    frame(ctx)
    reaper.ImGui_End(ctx)
  end

  pop_theme(ctx)
  
  if show_style_editor then
    demo.PopStyle(ctx)
  end
  
  if open then
    reaper.defer(loop)
  end
end
reaper.defer(loop)