-- @noindex

reaper.gmem_attach("BB_REU")
function gm_reload_settings()
  reaper.gmem_write(1, 1)
end
function gm_update_selected_only()
  return reaper.gmem_write(1, 2)
end

function gm_flush()
  reaper.gmem_write(1, 0)
end

function gm_has_new_settings()
  return reaper.gmem_read(1) 
end

function gm_get_settings_data(flush)
  local preset_id = reaper.gmem_read(2)
  return preset_id
end

function gm_write_selected_preset(selected_preset_id)
  reaper.gmem_write(2, selected_preset_id)
end

function gmem_get_selected_preset()
  local id = reaper.gmem_read(2)
  if id == 0 then 
    gm_write_selected_preset(1)
    return 1 
  else
    return id
  end
end