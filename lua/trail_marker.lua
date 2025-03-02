--[[

Lua api of the plugin.

--]]
local trail = require("trail_marker.trail")
local utils = require("trail_marker.utils")

---@class TrailMarker
local M = {}

---Place a marker on the current trail.
M.place_marker = function()
  if M.trail ~= nil then
    M.trail:place_marker()
  else
    utils.no_current_trail_warning()
  end
end

---Remove marker at the current cursor location, if one exists.
M.remove_marker = function()
  if M.trail ~= nil then
    M.trail:remove_marker_at_location()
  else
    utils.no_current_trail_warning()
  end
end

---Move to the current marker.
M.current_marker = function()
  if M.trail ~= nil then
    if #M.trail.marker_list == 0 then
      utils.no_markers_on_trail_warning(M.trail.name)
    else
      M.trail:current_marker()
    end
  else
    utils.no_current_trail_warning()
  end
end

---Move to the next marker.
M.next_marker = function()
  if M.trail ~= nil then
    if #M.trail.marker_list == 0 then
      utils.no_markers_on_trail_warning(M.trail.name)
    elseif M.trail.trail_pos == #M.trail.marker_list then
      utils.warning("No next marker")
    else
      M.trail:next_marker()
    end
  else
    utils.no_current_trail_warning()
  end
end

---Move to the previous marker.
M.prev_marker = function()
  if M.trail ~= nil then
    if #M.trail.marker_list == 0 then
      utils.no_markers_on_trail_warning(M.trail.name)
    elseif M.trail.trail_pos == 1 then
      utils.warning("No previous marker")
    else
      M.trail:prev_marker()
    end
  else
    utils.no_current_trail_warning()
  end
end

---Move to the head of the trail.
M.trail_head = function()
  if M.trail ~= nil then
    if #M.trail.marker_list == 0 then
      utils.no_markers_on_trail_warning(M.trail.name)
    else
      M.trail:trail_head()
    end
  else
    utils.no_current_trail_warning()
  end
end

---Move to the end of the trail.
M.trail_end = function()
  if M.trail ~= nil then
    if #M.trail.marker_list == 0 then
      utils.no_markers_on_trail_warning(M.trail.name)
    else
      M.trail:trail_end()
    end
  else
    utils.no_current_trail_warning()
  end
end

---Clears the current trail.
M.clear_trail = function()
  if M.trail ~= nil then
    M.trail:clear_trail()
  else
    utils.no_current_trail_warning()
  end
end

---Turns virtual text on.
M.virtual_text_on = function()
  if M.trail ~= nil then
    M.trail:virtual_text_on()
  else
    utils.no_current_trail_warning()
  end
end

---Turns virtual text off.
M.virtual_text_off = function()
  if M.trail ~= nil then
    M.trail:virtual_text_off()
  else
    utils.no_current_trail_warning()
  end
end

---Toggles virtual text.
M.virtual_text_toggle = function()
  if M.trail ~= nil then
    M.trail:virtual_text_toggle()
  else
    utils.no_current_trail_warning()
  end
end

---Create a new trail.
---@param trail_name string
M.new_trail = function(trail_name)
  local trail_file = string.format("%s/%s", utils.get_current_project_dir(), trail_name)
  local file, _ = io.open(trail_file, "r")

  if file then
    utils.warning(string.format("Trail `%s` already exists. Use `:TrailMarker change_trail %s` to switch.", trail_name, trail_name))
  else
    M.trail = trail.new(trail_name)
    vim.api.nvim_exec_autocmds('User', { pattern = 'TrailMarkerEventTrailChanged' })
  end
end

---Changes the current trail.
---@param trail_name string
M.change_trail = function(trail_name)
  local trail_file = string.format("%s/%s", utils.get_current_project_dir(), trail_name)
  local file, _ = io.open(trail_file, "r")

  if file then
    local content = file:read("*a")
    file:close()

    local deserialized_trail = utils.deserialize(content)
    M.trail = trail.from_table(deserialized_trail)
    vim.api.nvim_exec_autocmds('User', { pattern = 'TrailMarkerEventTrailChanged' })
  else
    utils.warning(string.format("Trail `%s` does not exist.", trail_name))
  end
end

---Remove a trail.
---@param trail_name string
M.remove_trail = function(trail_name)
  local trail_file = string.format("%s/%s", utils.get_current_project_dir(), trail_name)
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
    utils.warning(string.format("Trail `%s` does not exist.", trail_name))
  end
end

---Get the name of the current trail.
---@return string|nil
M.get_current_trail = function()
  if M.trail ~= nil then
    return M.trail.name
  else
    return nil
  end
end

---Get the current trail position.
---@return integer|nil
M.get_current_position = function()
  if M.trail ~= nil then
    return M.trail.trail_pos
  else
    return nil
  end
end

---Leave the current trail.
M.leave_trail = function()
  M.trail = nil
  vim.api.nvim_exec_autocmds('User', { pattern = 'TrailMarkerEventTrailChanged' })
end

---Gets a list of all trails in the current project.
---@return string[]
M.get_trail_list = function()
  local trails = {}

  -- Use `ls` command to list files in the directory
  local p = io.popen('ls -p "' .. utils.get_current_project_dir() .. '"')  -- -p appends a / to directories
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
        pos_str = "-"
      elseif pos == #M.trail.marker_list then
        pos_str = pos_str .. "*"
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
}

---Gets the names of all trails in the current project.
---@return string[]
local function get_project_trail_names()
  local dir_path = utils.get_current_project_dir()
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
