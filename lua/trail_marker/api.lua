--[[

Lua api of the plugin.

--]]
local trail = require("trail_marker.trail")
local serde = require("trail_marker.serde")
local utils = require("trail_marker.utils")

local function no_current_trail_warning()
  utils.warning("TrailMarker: No current trail. Use `:TrailMarker change_trail <trail_name>` or `:TrailMarker new_trail <trail_name>`")
end

local function no_markers_on_trail_warning()
  utils.warning("TrailMarker: No markers on trail.")
end

local M = {}

M.trail_map = function()
  -- TODO: fix
  if M.trail ~= nil then
    M.trail:trail_map()
  else
    no_current_trail_warning()
  end
end

M.place_marker = function()
  if M.trail ~= nil then
    M.trail:place_marker()
  else
    no_current_trail_warning()
  end
end

M.remove_marker = function()
  if M.trail ~= nil then
    M.trail:remove_marker_at_location()
  else
    no_current_trail_warning()
  end
end

M.current_marker = function()
  if M.trail ~= nil then
    if #M.trail.marker_list == 0 then
      no_markers_on_trail_warning()
    else
      M.trail:current_marker()
    end
  else
    no_current_trail_warning()
  end
end

M.next_marker = function()
  if M.trail ~= nil then
    if #M.trail.marker_list == 0 then
      no_markers_on_trail_warning()
    elseif M.trail.trail_pos == #M.trail.marker_list then
      utils.warning("TrailMarker: no next marker")
    else
      M.trail:next_marker()
    end
  else
    no_current_trail_warning()
  end
end

M.prev_marker = function()
  if M.trail ~= nil then
    if #M.trail.marker_list == 0 then
      no_markers_on_trail_warning()
    elseif M.trail.trail_pos == 1 then
      utils.warning("TrailMarker: no previous marker")
    else
      M.trail:prev_marker()
    end
  else
    no_current_trail_warning()
  end
end

M.trail_head = function()
  if M.trail ~= nil then
    if #M.trail.marker_list == 0 then
      no_markers_on_trail_warning()
    else
      M.trail:trail_head()
    end
  else
    no_current_trail_warning()
  end
end

M.trail_end = function()
  if M.trail ~= nil then
    if #M.trail.marker_list == 0 then
      no_markers_on_trail_warning()
    else
      M.trail:trail_end()
    end
  else
    no_current_trail_warning()
  end
end

M.clear_trail = function()
  if M.trail ~= nil then
    M.trail:clear_trail()
  else
    no_current_trail_warning()
  end
end

M.virtual_text_on = function()
  if M.trail ~= nil then
    M.trail:virtual_text_on()
  else
    no_current_trail_warning()
  end
end

M.virtual_text_off = function()
  if M.trail ~= nil then
    M.trail:virtual_text_off()
  else
    no_current_trail_warning()
  end
end

M.virtual_text_toggle = function()
  if M.trail ~= nil then
    M.trail:virtual_text_toggle()
  else
    no_current_trail_warning()
  end
end

M.new_trail = function(trail_name)
  local trail_file = string.format("%s/%s", serde.get_current_project_dir(), trail_name)
  local file, _ = io.open(trail_file, "r")

  if file then
    utils.warning(string.format("TrailMarker: trail `%s` already exists. Use `:TrailMarker change_trail %s` to switch.", trail_name, trail_name))
  else
    M.trail = trail.new(trail_name)
    vim.api.nvim_exec_autocmds('User', { pattern = 'TrailMarkerEventTrailChanged' })
  end
end

M.change_trail = function(trail_name)
  local trail_file = string.format("%s/%s", serde.get_current_project_dir(), trail_name)
  local file, _ = io.open(trail_file, "r")

  if file then
    local content = file:read("*a")
    file:close()

    local deserialized_trail = serde.deserialize(content)
    M.trail = trail.from_table(deserialized_trail)
    vim.api.nvim_exec_autocmds('User', { pattern = 'TrailMarkerEventTrailChanged' })
  else
    utils.warning(string.format("TrailMarker: trail `%s` does not exist.", trail_name))
  end
end

M.remove_trail = function(trail_name)
  local trail_file = string.format("%s/%s", serde.get_current_project_dir(), trail_name)
  local file, _ = io.open(trail_file, "r")

  if file then
    -- If the trail being removed is the current trail.
    if M.trail ~= nil and trail_name == M.trail.name then
      -- Clear the trail first so the virtual text goes away.
      M.trail:clear_trail()
      -- Set the trail to nil so it can't be modified by other functions unintentionally.
      M.trail = nil
      vim.api.nvim_exec_autocmds('User', { pattern = 'TrailMarkerEventTrailChanged' })
    end

    -- Remove the trail file
    os.execute(string.format("rm %s", trail_file))
  else
    utils.warning(string.format("TrailMarker: trail `%s` does not exist.", trail_name))
  end
end

M.get_current_trail = function()
  if M.trail ~= nil then
    return M.trail.name
  end
end

M.get_current_position = function()
  if M.trail ~= nil then
    return M.trail.trail_pos
  end
end

M.leave_trail = function()
  M.trail = nil
  vim.api.nvim_exec_autocmds('User', { pattern = 'TrailMarkerEventTrailChanged' })
end

return M
