-- This is the api of the plugin.
local trail = require("trail_marker.trail")
local serde = require("trail_marker.serde")

local function warning(msg)
  vim.api.nvim_echo({ { msg, 'WarningMsg' } }, false, {})
end

local function no_current_trail_warning()
  warning("TrailMarker: No current trail. Use `:TrailMarker change_trail <trail_name>` or `:TrailMarker new_trail <trail_name>`")
end

local function no_markers_on_trail_warning()
  warning("TrailMarker: No markers on trail.")
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
      warning("TrailMarker: no next marker")
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
      warning("TrailMarker: no previous marker")
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
    vim.api.nvim_exec_autocmds('User', { pattern = 'TrailMarkerEvent' })
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
    warning(string.format("TrailMarker: trail `%s` already exists. Use `:TrailMarker change_trail %s` to switch.", trail_name, trail_name))
  else
    M.trail = trail.new(trail_name)
    vim.api.nvim_exec_autocmds('User', { pattern = 'TrailMarkerEvent' })
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
    vim.api.nvim_exec_autocmds('User', { pattern = 'TrailMarkerEvent' })
  else
    warning(string.format("TrailMarker: trail `%s` does not exist.", trail_name))
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
      vim.api.nvim_exec_autocmds('User', { pattern = 'TrailMarkerEvent' })
    end

    -- Remove the trail file
    os.execute(string.format("rm %s", trail_file))
  else
    warning(string.format("TrailMarker: trail `%s` does not exist.", trail_name))
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
  vim.api.nvim_exec_autocmds('User', { pattern = 'TrailMarkerEvent' })
end

-------------------
-- User commands --
-------------------
local function_map = {
  trail_map = M.trail_map,
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

local function complete_trail_names()
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
    warning("Invalid function name: " .. function_name)
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
      return complete_trail_names()
    end

    return {}
  end
})

---------------------
-- global variable --
---------------------
vim.api.nvim_create_autocmd('User', {
  pattern = 'TrailMarkerEvent',
  callback = function(_)
    -- Update the trail information whenever it changes.
    if M.trail ~= nil then

      local pos = M.get_current_position()
      local pos_str = tostring(pos)

      if pos == 0 then
        pos_str = "*"
      elseif pos == 1 then
        pos_str = "HEAD"
      elseif pos == #M.trail.marker_list and pos ~= 1 then
        pos_str = "END"
      end

      vim.g.trail_marker_info = string.format("%s:%s", M.get_current_trail(), pos_str)
    else
      vim.g.trail_marker_info = nil
    end
  end
})

return M
