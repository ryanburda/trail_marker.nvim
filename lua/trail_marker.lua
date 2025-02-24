--[[

Lua api of the plugin.

--]]
local trail = require("trail_marker.trail")
local serde = require("trail_marker.serde")
local utils = require("trail_marker.utils")

local M = {}

M.place_marker = function()
  if M.trail ~= nil then
    M.trail:place_marker()
  else
    utils.no_current_trail_warning()
  end
end

M.remove_marker = function()
  if M.trail ~= nil then
    M.trail:remove_marker_at_location()
  else
    utils.no_current_trail_warning()
  end
end

M.current_marker = function()
  if M.trail ~= nil then
    if #M.trail.marker_list == 0 then
      utils.no_markers_on_trail_warning()
    else
      M.trail:current_marker()
    end
  else
    utils.no_current_trail_warning()
  end
end

M.next_marker = function()
  if M.trail ~= nil then
    if #M.trail.marker_list == 0 then
      utils.no_markers_on_trail_warning()
    elseif M.trail.trail_pos == #M.trail.marker_list then
      utils.warning("TrailMarker: no next marker")
    else
      M.trail:next_marker()
    end
  else
    utils.no_current_trail_warning()
  end
end

M.prev_marker = function()
  if M.trail ~= nil then
    if #M.trail.marker_list == 0 then
      utils.no_markers_on_trail_warning()
    elseif M.trail.trail_pos == 1 then
      utils.warning("TrailMarker: no previous marker")
    else
      M.trail:prev_marker()
    end
  else
    utils.no_current_trail_warning()
  end
end

M.trail_head = function()
  if M.trail ~= nil then
    if #M.trail.marker_list == 0 then
      utils.no_markers_on_trail_warning()
    else
      M.trail:trail_head()
    end
  else
    utils.no_current_trail_warning()
  end
end

M.trail_end = function()
  if M.trail ~= nil then
    if #M.trail.marker_list == 0 then
      utils.no_markers_on_trail_warning()
    else
      M.trail:trail_end()
    end
  else
    utils.no_current_trail_warning()
  end
end

M.clear_trail = function()
  if M.trail ~= nil then
    M.trail:clear_trail()
  else
    utils.no_current_trail_warning()
  end
end

M.virtual_text_on = function()
  if M.trail ~= nil then
    M.trail:virtual_text_on()
  else
    utils.no_current_trail_warning()
  end
end

M.virtual_text_off = function()
  if M.trail ~= nil then
    M.trail:virtual_text_off()
  else
    utils.no_current_trail_warning()
  end
end

M.virtual_text_toggle = function()
  if M.trail ~= nil then
    M.trail:virtual_text_toggle()
  else
    utils.no_current_trail_warning()
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

M.get_trail_list = function()
  local trails = {}

  -- Use `ls` command to list files in the directory
  local p = io.popen('ls -p "' .. serde.get_current_project_dir() .. '"')  -- -p appends a / to directories
  for file in p:lines() do
    -- Check that the file does not end with `/` to exclude directories
    if not file:match("/$") then
      table.insert(trails, file)
    end
  end
  p:close()

  return trails
end

--[[
Global Variables

Update TrailMarker global variables when certain events fire.
These variables can be used to show TrailMarker information
in various locations like the status line or winbar.
--]]
vim.api.nvim_create_autocmd('User', {
  pattern = { 'TrailMarkerEventPositionUpdate', 'TrailMarkerEventTrailChanged' },
  callback = function(_)
    if M.trail ~= nil then
      vim.g.trail_marker_position = M.get_current_position()
    else
      vim.g.trail_marker_position = nil
    end
  end
})

vim.api.nvim_create_autocmd('User', {
  pattern = { 'TrailMarkerEventTrailChanged', },
  callback = function(_)
    if M.trail ~= nil then
      vim.g.trail_marker_name = M.get_current_trail()
    else
      vim.g.trail_marker_name = nil
    end
  end
})

vim.api.nvim_create_autocmd('User', {
  pattern = { 'TrailMarkerEvent*', },
  callback = function(_)
    -- Create a TrailMarker info string.
    if M.trail ~= nil then
      local name = M.get_current_trail()
      local pos = M.get_current_position()
      local pos_str = tostring(pos)

      if pos == 0 then
        pos_str = "*"
      elseif pos == 1 then
        pos_str = "HEAD"
      elseif pos == #M.trail.marker_list and pos ~= 1 then
        pos_str = "END"
      end

      vim.g.trail_marker_info = string.format("%s:%s", name, pos_str)
    else
      vim.g.trail_marker_info = nil
    end
  end
})

--[[
User Commands

Provide a convenient way to interface with TrailMarker.

```
:TrailMarker <command> <optional-args>
```
--]]
local function_map = {
  get_current_trail = function() print(M.get_current_trail()) end,
  get_current_position = function() print(M.get_current_position()) end,
  new_trail = M.new_trail,
  change_trail = M.change_trail,
  remove_trail = M.remove_trail,
  leave_trail = M.leave_trail,
  place_marker = M.place_marker,
  remove_marker = M.remove_marker,
  current_marker = M.current_marker,
  next_marker = M.next_marker,
  prev_marker = M.prev_marker,
  trail_head = M.trail_head,
  trail_end = M.trail_end,
  clear_trail = M.clear_trail,
  virtual_text_toggle = M.virtual_text_toggle,
  telescope_trail_map = M.telescope_trail_map,
}

local function get_project_trail_names()
  local dir_path = serde.get_current_project_dir()
  local trails = {}

  if vim.fn.isdirectory(dir_path) == 1 then
    local handle = io.popen('ls ' .. dir_path)
    if handle then
      for filename in handle:lines() do
        table.insert(trails, filename)
      end
      handle:close()
    end
  end

  return trails
end

vim.api.nvim_create_user_command('TrailMarker', function(opts)
  local function_name = opts.fargs[1]
  local additional_arg = opts.fargs[2]

  local func = function_map[function_name]

  if func then
    if additional_arg == nil then
      func()
    else
      func(additional_arg)
    end
  else
    utils.warning("Invalid function name: " .. function_name)
  end
end, {
  nargs = '*',
  complete = function(_, cmd_line, _)
    local args = vim.split(cmd_line, '%s+')

    if #args == 2 then
      -- Second argument involves typing the function name
      return vim.tbl_keys(function_map)

    elseif #args == 3 and vim.tbl_contains({"change_trail", "remove_trail"}, args[2]) then
      -- Third argument requires trail name completion
      return get_project_trail_names()
    end

    return {}
  end
})

return M
