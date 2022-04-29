--@noindex

function load_chunk(track, chunk_data, partial_load)
    local item_chunks = chunk_data.items
        
    --GET RAZOR EDITS
    local razor_edits = {}
    if partial_load then
        razor_edits = get_razor_edits(track)
    end
    local edit = razor_edits[1]

    if not partial_load then
        clear_items(track)
    elseif partial_load and edit then
        delete_item_range(track, edit.s, edit.e)
    end

    --SET TEMPO
    local cur_tempo, tempo = reaper.Master_GetTempo(), chunk_data.tempo
    local do_tempo = tempo and cur_tempo ~= tempo
    if do_tempo then 
        reaper.SetCurrentBPM(0, tempo, false)
    end

    --INSERT ITEMS FROM CHUNKS
    for i = 1, #item_chunks do
        local chunk = item_chunks[i]
        local item = reaper.AddMediaItemToTrack(track)
        reaper.SetItemStateChunk(item, chunk, false)
        
        --PARTIAL LOADING
        local del
        if partial_load then
            if edit then
                del = delete_out_of_bounds_item(track, item, edit.s, edit.e)
                if not del then
                    trim_item_right_edge(track, item, edit.e)
                    item = trim_item_left_edge(track, item, edit.s)
                end
            end
        end
    end

    local q = get_ext_state_query(track)
    if chunk_data.fx_chain and q.load_fx and not partial_load then
        replace_fx_chunk(track, chunk_data.fx_chain)
    end

    if do_tempo then
        reaper.SetCurrentBPM(0, cur_tempo, false)
    end
end

function validate_state(state)
    local ver_count = #state.versions
    local selected = state.data.selected
    if selected > ver_count then
        selected = ver_count
    elseif selected == 0 then
        selected = 1
    end
    state.data.selected = selected
    return state
end

function create_new_version(track, state)
    state = validate_state(state)
    set_ext_state(track, state)
end

function switch_versions(track, state, selected_id, no_save, partial_load)
    --GET CHUNK DATA
    local chunk_data = get_version_data(track)
    
    --SAVE CURRENT VERSION TO STATE
    if not no_save and #state.versions > 0 then
        state.versions[state.data.selected].items = chunk_data.items
        local q = get_ext_state_query(track)
        if q.load_fx then
            state.versions[state.data.selected].fx_chain = chunk_data.fx_chain
        end
        state.versions[state.data.selected].tempo = chunk_data.tempo
    end

    --SWITCH VERSION
    local target_version = state.versions[selected_id]
    if not partial_load then 
        state.data.selected = selected_id
    end
    
    load_chunk(track, target_version, partial_load)
    set_ext_state(track, state)
end

function delete_current_version(track, state)
    if #state.versions > 1 then
        table.remove(state.versions, state.data.selected)
        state = validate_state(state)
        switch_versions(track, state, state.data.selected, true)
    end
end

function collapse_versions(track, state)
    local new_state = get_empty_state()
    add_new_version(track, new_state)
    return new_state
end

function add_new_version(track, state, clear)
    --GET CHUNK DATA
    local chunk_data = get_version_data(track)
    
    --SAVE CURRENT VERSION
    if #state.versions > 0 then
        state.versions[state.data.selected] = chunk_data
    end
    
    --CREATE NEW VERSION
    state.versions[#state.versions+1] = chunk_data
    state.data.selected = #state.versions
    create_new_version(track, state)

    --CLEAR ITEMS
    if clear then clear_items(track) end
end