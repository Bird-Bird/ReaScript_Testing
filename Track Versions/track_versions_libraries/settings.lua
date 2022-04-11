-- @noindex

--USER SETTINGS
local info = debug.getinfo(1,'S')
local path = info.source:match[[^@?(.*[\/])[^\/]-$]]
local default_settings = {
    prefix_tracks = false, 
    clear_selection_versions = true,
    debug_mode = false,
    use_full_height_versions = false,
    slim_mode = false
}

function get_settings()
    local file_name = 'settings.json'
    local settings = io.open(path .. file_name, 'r')
    if not settings then
        return default_settings
    else
        local st = settings:read("*all")
        st_json = json.decode(st)
        return st_json
    end
end
settings = get_settings()

function save_settings(data)
    local settings = io.open(path .. 'settings.json', 'w')
    local d = json.encode(data)
    settings:write(d)
    settings:close()
end