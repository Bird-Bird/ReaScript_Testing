-- @noindex

if not reaper.APIExists('ImGui_GetVersion') then
  local text = 'Global Sampler Theme Editor requires the ReaImGui extension to run. You can install it through ReaPack.'
  local ret = reaper.ShowMessageBox(text, 'Error - Missing Dependency', 0)
  return
end
dofile(reaper.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/imgui.lua')('0.6')

function p(msg) reaper.ShowConsoleMsg(tostring(msg) .. ' \n') end
function reaper_do_file(file) local info = debug.getinfo(1,'S'); local path = info.source:match[[^@?(.*[\/])[^\/]-$]]; dofile(path .. file); end
reaper_do_file('global_sampler_libraries/json.lua')
reaper_do_file('global_sampler_libraries/themes.lua')
local themes = get_themes()

local ctx = reaper.ImGui_CreateContext('Global Sampler Theme Editor')
local font = reaper.ImGui_CreateFont('sans-serif', 12)
reaper.ImGui_AttachFont(ctx, font)
reaper.gmem_attach('BB_Sampler')

function dl_rgba_to_col(r, g, b, a)
  local b = b * 256
  local g = g * 256 * 256
  local r = r * 256 * 256 * 256
  return r + g + b + a
end

local function explode_rgba(rgba)
  return
    ((rgba >> 24) & 0xFF),
    ((rgba >> 16) & 0xFF),
    ((rgba >> 8 ) & 0xFF),
    (rgba         & 0xFF)
end

function push_theme()
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0xDDE3FFFF)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding(),     8, 5)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowTitleAlign(),  0.5, 0.5)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(),       3, 4)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ScrollbarRounding(), 0)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(),             0x1E1A25F0)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_PopupBg(),              0x2A2A2AF0)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(),               0xFFFFFF80)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(),              0x5135548A)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBg(),              0x181818FF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgActive(),        0x181818FF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(),               0x42213DFF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(),        0x64375DFF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(),         0x87547FFF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderHovered(),        0xBD12844B)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderActive(),         0xBD128487)  
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Separator(),            0xFFFFFF81)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGrip(),           0x12BD9933)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGripHovered(),    0x12BD99AB)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGripActive(),     0x12BD99F2)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TextSelectedBg(),       0x70C4C659)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_CheckMark(),            0x12BD99FF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarBg(),          0x16121BF0)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrab(),        0xFFD7EC11)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrabHovered(), 0xFFFFFF19)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrabActive(),  0xFFFFFF32)    
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Header(),               0xBD128487)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Tab(),                  0x3E2E3BFF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabHovered(),           0x54344DFF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabActive(),            0x553E50FF)
end

function pop_theme()
  reaper.ImGui_PopStyleVar(ctx, 4)
  reaper.ImGui_PopStyleColor(ctx, 26)
end

local FLT_MIN, FLT_MAX = reaper.ImGui_NumericLimits_Float()
local selected_theme = "theme_carbon"
function frame()
  local save = false
  
  local themes_flat = {}
  for name, dat in pairs(themes) do
    table.insert(themes_flat, name)
  end
  table.sort(themes_flat, function(a,b) return a < b end)
  
  if reaper.ImGui_BeginListBox(ctx, "Themes", -FLT_MIN) then
    for i = 1, #themes_flat do 
      local name = themes_flat[i]
      local selected = selected_theme == name
      local rv, v = reaper.ImGui_Selectable(ctx, name, selected) 
      if rv then
        if not selected then
          selected_theme = name
          save = true
        end
      end
    end
    reaper.ImGui_EndListBox(ctx)
  end
  
  for name, dat in pairs(themes) do
    if name == selected_theme then
      reaper.ImGui_Text(ctx, "Theme: " .. name)
      reaper.ImGui_SameLine(ctx)
      if reaper.ImGui_Button(ctx, "Reset") then
        themes[name] = deepcopy(default_themes[name])
        save = true
      end
      
      --Background, border
      reaper.ImGui_Text(ctx, "")
      reaper.ImGui_Text(ctx, "Background")
      local bg = dat.bg
      local bg_rgba = dl_rgba_to_col(bg.r, bg.g, bg.b, 255)
      local rv, col_rgba = reaper.ImGui_ColorEdit4(ctx, "Background", bg_rgba)
      if rv then
        local r, g, b = explode_rgba(col_rgba)
        dat.bg = {r = r, g = g, b = b}
      end
      if reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) then save = true end

      local br = dat.border
      local br_rgba = dl_rgba_to_col(br.r, br.g, br.b, 255)
      local rv, col_rgba = reaper.ImGui_ColorEdit4(ctx, "Border", br_rgba)
      if rv then
        local r, g, b = explode_rgba(col_rgba)
        dat.border = {r = r, g = g, b = b}
      end
      if reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) then save = true end
      
      rv, dat.border_margin = reaper.ImGui_SliderInt(ctx, "Border Margin", dat.border_margin, 0, 10)
      if reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) then save = true end
      
      
      --Waveform
      reaper.ImGui_Text(ctx, "")
      reaper.ImGui_Text(ctx, "Waveform")

      local wf = dat.waveform_line
      local wf_rgba = dl_rgba_to_col(wf.r, wf.g, wf.b, math.floor(dat.waveform_fill_alpha*255))
      local rv, col_rgba = reaper.ImGui_ColorEdit4(ctx, "Waveform", wf_rgba)
      if rv then
        local r, g, b, a = explode_rgba(col_rgba)
        dat.waveform_line = {r = r, g = g, b = b}
        dat.waveform_fill_alpha = a/255
      end
      if reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) then save = true end

      rv, dat.wave_fade_alpha_intensity = reaper.ImGui_SliderDouble(ctx, "Fade", dat.wave_fade_alpha_intensity, 0, 1)
      if reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) then save = true end
      rv, dat.wave_fade_len = reaper.ImGui_SliderInt(ctx, "Fade Length", dat.wave_fade_len, 0, 100)
      if reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) then save = true end

      rb, dat.rainbow_waveform_col = reaper.ImGui_Checkbox(ctx, "Rainbow", dat.rainbow_waveform_col)
      if reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) then save = true end


      --Writer Color
      reaper.ImGui_Text(ctx, "")
      reaper.ImGui_Text(ctx, "Writer")
      local wr = dat.writer_col
      local wr_rgba = dl_rgba_to_col(wr.r, wr.g, wr.b, 255)
      local rv, col_rgba = reaper.ImGui_ColorEdit4(ctx, "Writer Color", wr_rgba)
      if rv then
        local r, g, b = explode_rgba(col_rgba)
        dat.writer_col = {r = r, g = g, b = b}
      end
      if reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) then save = true end

      --Trail
      rv, dat.trail_len = reaper.ImGui_SliderInt(ctx, "Trail Length", dat.trail_len, 0, 100)
      if reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) then save = true end

      rv, dat.trail_alpha = reaper.ImGui_SliderDouble(ctx, "Trail Alpha", dat.trail_alpha, 0, 1)
      if reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) then save = true end

      rv, dat.trail_pow = reaper.ImGui_SliderDouble(ctx, "Trail Fade", dat.trail_pow, 0.1, 10)
      if reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) then save = true end


      --Selection
      reaper.ImGui_Text(ctx, "")
      reaper.ImGui_Text(ctx, "Selection")
      local cr = dat.crop_region
      local cr_rgba = dl_rgba_to_col(cr.r, cr.g, cr.b, math.floor(dat.crop_region_alpha*255))
      local rv, col_rgba = reaper.ImGui_ColorEdit4(ctx, "Selection", cr_rgba)
      if rv then
        local r, g, b, a = explode_rgba(col_rgba)
        dat.crop_region = {r = r, g = g, b = b}
        dat.crop_region_alpha = a/255
      end
      if reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) then save = true end
    end
  end
  
  if save then
    save_themes(themes)
    local sel_id = theme_index[selected_theme]
    reaper.gmem_write(16, sel_id) --reload
  end
end

function loop()
  push_theme()
  reaper.ImGui_PushFont(ctx, font)
  reaper.ImGui_SetNextWindowSize(ctx, 257, 641, reaper.ImGui_Cond_FirstUseEver())
  local visible, open = reaper.ImGui_Begin(ctx, 'Global Sampler Theme Editor', true)
  if visible then
    frame()
    reaper.ImGui_End(ctx)
  end
  reaper.ImGui_PopFont(ctx)
  pop_theme()
  if open then
    reaper.defer(loop)
  else
    reaper.ImGui_DestroyContext(ctx)
  end
end

reaper.defer(loop)