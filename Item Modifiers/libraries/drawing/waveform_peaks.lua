-- @noindex

peak_display_padding = 2
function get_item_color(item)
  local col = reaper.GetMediaItemInfo_Value(item, 'I_CUSTOMCOLOR')
  local r, g, b = reaper.ColorFromNative(col)
  if r == 0 and g == 0 and b == 0 then
    local track = reaper.GetMediaItem_Track(item)
    local t_col = reaper.GetTrackColor(track)
    r, g, b = reaper.ColorFromNative(t_col)
  end
  return r/255, g/255, b/255
end

function get_item_peaks(item, disp_w)
  local take = reaper.GetMediaItemTake(item, 0)
  local source = reaper.GetMediaItemTake_Source(take)
  local nch = reaper.GetMediaSourceNumChannels(source)  
  local pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
  local len = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
  local disp_w = disp_w < 1 and 1 or disp_w
  local ns = disp_w
  local pr = disp_w/len
  local buf = reaper.new_array(ns * nch * 3)
  local retval = reaper.GetMediaItemTake_Peaks(take, pr, pos, 1, ns, 0, buf)
  local spl_cnt  = (retval & 0xfffff)        
  local ext_type = (retval & 0x1000000)>>24  
  local out_mode = (retval & 0xf00000)>>20   
  return buf, spl_cnt
end

function get_note_data(item)
  local take = reaper.GetMediaItemTake(item, 0)
  local pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
  local len = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
  local r, note_cnt, _, _ = reaper.MIDI_CountEvts(take)
  local note_data = {notes = {}}
  if note_cnt == 0 then return note_data end
  local min_pitch = math.huge
  local max_pitch = 0
  for i = 0, note_cnt - 1 do
    local r, selected, muted, sppq, eppq, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
    local sp = reaper.MIDI_GetProjTimeFromPPQPos(take, sppq)
    local ep = reaper.MIDI_GetProjTimeFromPPQPos(take, eppq)
    max_pitch = math.max(pitch, max_pitch)
    min_pitch = math.min(pitch, min_pitch)
    if sp < pos + len and ep > pos then
      sp = sp < pos and pos or sp
      ep = ep > pos + len and pos + len or ep
      local np = (sp - pos)/len
      local nl = (ep - sp)/len
      local note = {sp = sp, ep = ep, pitch = pitch, np = np, nl = nl}
      table.insert(note_data.notes, note)
    end
  end
  table.sort(note_data.notes, function(a, b) return a.pitch < b.pitch end)
  note_data.max_pitch = max_pitch
  note_data.min_pitch = min_pitch
  note_data.range = max_pitch - min_pitch
  note_data.item_pos = pos
  note_data.item_len = len
  return note_data
end

local note_max_h = 6
function draw_item_peaks(dat, x, y, w, h, fast_mode)
  local w = w <= 1 and 2 or w
  local is_midi = dat.is_midi
  dl_set_color(dat.ir, dat.ig, dat.ib, fast_mode and 0.8 or 1)
  dl_rect_filled(x, y, w, h)
  if not is_midi then
    local spl_cnt = dat.spl_cnt
    
    local wi = dl_get_window()
    local draw_list = reaper.ImGui_GetWindowDrawList(ctx)

    local points_top = {}
    local points_bottom = {}

    local vc = y + h/2
    local lxt, lyt = x, vc
    local lxb, lyb = x, vc
    for i = 1, w - 1 do
      local t = i/w
      t = math.floor(t * spl_cnt) + 1
      local val = dat.peaks[t]
      local offs = val*110 
      offs = offs < 0 and 0 or offs
      offs = offs > (h/2) and h/2 or offs
      if fast_mode then offs = offs*0.8 end
      local nxt, nyt = x + i, vc  - offs
      local nxb, nyb = x + i, vc  + offs - 1
      
      if fast_mode then
        table.insert(points_top, nxt + wi.x)
        table.insert(points_top, nyt + wi.y)
        table.insert(points_bottom, nxb + wi.x)
        table.insert(points_bottom, nyb + wi.y)
      else
        dl_set_color(1,1,1,1)
        dl_line(lxt, lyt, nxt, nyt)
        dl_line(lxb, lyb, nxb, nyb)
        
        dl_set_color(1,1,1,0.3)
        dl_line(x + i, vc, x + i, nyt)
        dl_line(x + i, vc, x + i, nyb)
      end
      
      lxt, lyt = nxt, nyt
      lxb, lyb = nxb, nyb
    end
    
    if fast_mode then
      dl_set_color(1,1,1,1)
      local arr = reaper.new_array(points_top)
      local arr2 = reaper.new_array(points_bottom)
      reaper.ImGui_DrawList_AddPolyline(draw_list, arr, dl_color, reaper.ImGui_DrawFlags_None(), 1)
      reaper.ImGui_DrawList_AddPolyline(draw_list, arr2, dl_color, reaper.ImGui_DrawFlags_None(), 1)
    end
  else
    local note_dat = dat.note_dat
    local notes = note_dat.notes
    if #notes > 0 then
      local pad_h = h*0.50
      local note_h = math.floor(pad_h/note_dat.range + 0.5)
      note_h = note_h > 6 and 6 or note_h
      local vc = y + h/2
      local mid_i = math.floor(#notes/2)
      mid_i = mid_i == 0 and 1 or mid_i
      local mid_p = notes[mid_i].pitch
      for i = 1, #notes do
        local note = notes[i]
        local offs = mid_p - note.pitch
        local len = math.floor(w*note.nl + 0.5)
        local px = x + math.floor(w*note.np + 0.5)
        local py = vc + offs*note_h
        if py >= y and py <= y + h then
          dl_set_color(1,1,1,0.7)
          dl_rect_filled(px, py, len, note_h)
        end
      end
    end
  end
  dl_set_color(1, 1, 1, 0.7)
  dl_rect(x, y, w, h)
end

function draw_items_batch(peak_dat, x, y, w, h, padding, fast_mode)
  local total_len = 0
  local items = {}
  for i = 1, #peak_dat do
    local len = peak_dat[i].len
    total_len = total_len + len
    table.insert(items, {len = len})
  end
  
  local xs = x
  for i = 1, #items do
    local it = peak_dat[i]
    local pd_offs = i == #items and 0 or padding
    local disp_size = math.floor((w * it.n_l) + 0.5) - pd_offs
    draw_item_peaks(it, xs, y, disp_size, h, fast_mode)
    xs = xs + disp_size + padding
  end
end

function get_selected_items_tracks()
  local items = {}
  local tracks = {}
  local total_len = 0
  local sel_item_count = reaper.CountSelectedMediaItems(0)
  for i = 0, sel_item_count - 1 do 
    local item = reaper.GetSelectedMediaItem(0, i)
    local track = reaper.GetMediaItem_Track(item)
    local len = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
    total_len = total_len + len
    table.insert(items, item)
    table.insert(tracks, track)
  end
  return items, total_len, tracks
end

function fetch_item_peak_data(items, disp_w, total_len, padding)
  local peak_dat = {}
  for i = 1, #items do
    local item = items[i]
    local len = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
    local n_l = len/total_len
    local real_disp_w = math.floor(disp_w*n_l - padding)
    local take = reaper.GetMediaItemTake(item, 0)
    local is_midi = reaper.TakeIsMIDI(take)
    local dat = {is_midi = is_midi, len = len, n_l = n_l}
    if is_midi then
      local note_dat = get_note_data(item)
      dat.note_dat = note_dat
    else
      local peaks, spl_cnt = get_item_peaks(item, real_disp_w)
      dat.peaks = peaks
      dat.spl_cnt = spl_cnt
    end
    dat.ir, dat.ig, dat.ib = get_item_color(item)
    table.insert(peak_dat, dat)
  end
  return peak_dat
end