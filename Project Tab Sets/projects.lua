-- @noindex

function enum_projects(i)
  local i = -1
  return function()
    i = i + 1
    return reaper.EnumProjects(i)
  end
end

function file_exists(path)
  local file = io.open(path, "r")
  if file then
    file:close()
    return true
  end
  return false
end

function get_default_set()
  local project_root = global_settings.project_root

  return {
    project_root = (project_root ~= "") and project_root or "",
    tab_set_version = version,
    projects = {},
  }
end

--this turns into the saved tab set
function generate_set_data()
  local project_root = global_settings.project_root
  local has_project_root = project_root ~= ""

  local set = get_default_set()

  for _, name in enum_projects() do
    if name == "" then
      goto skip_project
    end

    local normalized_name = parse_project_path_crossplatform(name)
    local project = {
      path_type = "Absolute", 
      path = normalized_name
    }

    --if file is under project root, use relative path
    if has_project_root == true and normalized_name:sub(1, #project_root) == project_root then 
      project.path_type = "Relative"
      project.path = normalized_name:sub(#project_root + 1)
    end
    
    table.insert(set.projects, project)
    ::skip_project::
  end

  return set
end

function generate_set_data_from_table(projects)
  local set = get_default_set()
  for i = 1, #projects do
    table.insert(set.projects, {path_type = "Absolute", path = projects[i]})
  end
  return set
end

function close_all_projects_no_prompt()
  local prompt_preferences
  if user_has_SWS == true then
    prompt_preferences = reaper.SNM_GetIntConfigVar("newprojdo", -999)
    reaper.SNM_SetIntConfigVar("newprojdo", 0)
  end
  reaper.Main_OnCommand(40886, -1) -- close all projects
  if user_has_SWS == true then
    reaper.SNM_SetIntConfigVar("newprojdo", prompt_preferences)
  end
end

function load_tabs_from_set_data(set, additive_load)
  local project_root = global_settings.project_root
  local has_project_root = project_root ~= ""

  local set_has_projects_with_relative_path = false
  for i = 1, #set.projects do 
    if set.projects[i].path_type == "Relative" then
      set_has_projects_with_relative_path = true
      break
    end
  end

  --user doesnt have a project root set, but the tab set requires it
  if set_has_projects_with_relative_path == true and project_root == "" then 
    local message = "The tab set contains projects that use a relative path, however you don't seem to have a project root set.\n\nWould you like to set one now?"
    local result = reaper.ShowMessageBox(message, "Project Tab Sets - Warning", 3) --6 yes, 7 no, 2 cancel
    if result == 2 then
      return
    elseif result == 6 then
      local success = browse_for_project_root()
      if success == false then 
        reaper.ShowMessageBox("Proceeding without a project root, this might cause some projects to skip loading.", "Project Tab Sets - Warning", 0)
      else
        project_root = global_settings.project_root
        has_project_root = project_root ~= ""
      end
    end
  end

  --the tab set requires a project root, however the user configured project root differs from the one inside the tab set
  if set_has_projects_with_relative_path == true and project_root ~= set.project_root and project_root ~= "" then
    local message = "The tab set was saved with a project root that differs from the configured one. Would you still like to proceed?\n\n" 
                    .. "This might cause some projects to skip loading."
    local result = reaper.ShowMessageBox(message, "Project Tab Sets - Warning", 4) 
    if result == 7 then 
      return 
    end
  end

  --load projects now
  local faulty_projects = {}
  local open_projects = {}
  for _, name in enum_projects() do
    open_projects[parse_project_path_crossplatform(name)] = true
  end
  
  for i = 1, #set.projects do 
    local project = set.projects[i]
    
    local path = ""
    if has_project_root and project.path_type == "Relative" then
      path = project_root .. project.path
    else
      path = project.path
    end

    if file_exists(path) then
      if open_projects[path] ~= true then --skip open projects
        reaper.Main_OnCommand(41929, -1) --open new project tab
        reaper.Main_openProject(path)
      end
    else
      table.insert(faulty_projects, path)
    end
  end

  if #faulty_projects > 0 then
    local message = "The following projects couldn't be loaded because they weren't found:\n" .. table.concat(faulty_projects, "\n") .. 
                    "\n\nThis might happen if the projects have moved, or you haved moved to a different setup and forgot to update the project root folder."
    reaper.ShowMessageBox(message, "Project Tab Sets - Error", 0)
  end
end