-- @noindex

--CHUNK FUNCTIONS
function is_blacklisted(blacklist, str)
    for i = 1, #blacklist do 
        if string.starts(str, blacklist[i]) then
            return true
        end
    end
    return false
end

function get_chunk_section(chunk_lines, section, blacklist)
    local blacklist = blacklist or {}
    local section_chunks = {}
    local last_section_chunk = -1
    local current_scope = 0
    local i = 1
    while i <= #chunk_lines do
        local line = chunk_lines[i]
        
        --MANAGE SCOPE
        local scope_end = false
        if line == '<' .. section then       
            last_section_chunk = i
            current_scope = current_scope + 1
        elseif string.starts(line, '<') then
            current_scope = current_scope + 1
        elseif string.starts(line, '>') then
            current_scope = current_scope - 1
            scope_end = true
        end
        
        --GRAB CHUNK LINES
        if current_scope == 1 and last_section_chunk ~= -1 and scope_end then
            local s = ''
            for j = last_section_chunk, i do
                local new_line = chunk_lines[j]
                if blacklist and not is_blacklisted(blacklist, new_line) then
                    s = s .. new_line .. '\n'
                end
            end
            last_section_chunk = -1
            table.insert(section_chunks, s)
        end
        i = i + 1
    end
    return section_chunks
end

function remove_chunk_sections(chunk_lines, section)
    local removal_point = -1
    local last_section_chunk = -1
    local current_scope = 0
    local i = 1
    while i <= #chunk_lines do
        local line = chunk_lines[i]
        
        --MANAGE SCOPE
        local scope_end = false
        if line == '<' .. section then       
            last_section_chunk = i
            current_scope = current_scope + 1
        elseif string.starts(line, '<') then
            current_scope = current_scope + 1
        elseif string.starts(line, '>') then
            current_scope = current_scope - 1
            scope_end = true
        end
        
        --GRAB CHUNK LINES
        if current_scope == 1 and last_section_chunk ~= -1 and scope_end then
            local s = ''
            for j = last_section_chunk, i do
                table.remove(chunk_lines, last_section_chunk)
            end
            removal_point = last_section_chunk
            last_section_chunk = -1
        end
        i = i + 1
    end
    return removal_point
end

local item_chunk_blacklist = {'POOLEDEVTS', 'GUID', 'IGUID'}
local fx_chain_blacklist = {'FXID'}
function get_version_data(track)
    local retval, chunk = reaper.GetTrackStateChunk(track, "", false)
    local chunk_lines = str_split(chunk, '\n')
    local item_chunks = get_chunk_section(chunk_lines, 'ITEM', item_chunk_blacklist)
    local fx_chain = get_chunk_section(chunk_lines, 'FXCHAIN', fx_chain_blacklist)[1]
    local tempo = reaper.Master_GetTempo()
    if not fx_chain then fx_chain = '<FXCHAIN\n>' end
    return {items = item_chunks, fx_chain = fx_chain, tempo = tempo}
end

function replace_fx_chunk(track, new_chain)
    local retval, chunk = reaper.GetTrackStateChunk(track, "", false)
    local chunk_lines = str_split(chunk, '\n')
    local removal_index = remove_chunk_sections(chunk_lines, 'FXCHAIN')
    if removal_index ~= -1 then
        table.insert(chunk_lines, removal_index, new_chain)
        local chunk_str = table.concat(chunk_lines, '\n')
        local retval, chunk = reaper.SetTrackStateChunk(track, chunk_str, true)
    end
end