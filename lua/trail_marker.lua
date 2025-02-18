-- This is the api of the plugin.
local trail = require("trail_marker.trail")
local serde = require("trail_marker.serde")

local M = {}

M.trail_map = function()
  M.trail:trail_map()
end

M.place_marker = function()
  M.trail:place_marker()
end

M.remove_marker = function()
  M.trail:remove_marker_at_location()
end

M.current_marker = function()
  M.trail:current_marker()
end

M.next_marker = function()
  -- TODO: print warning if no next marker
  M.trail:next_marker()
end

M.prev_marker = function()
  -- TODO: print warning if no previous marker
  M.trail:prev_marker()
end

M.trail_head = function()
  M.trail:trail_head()
end

M.trail_end = function()
  M.trail:trail_end()
end

M.clear_trail = function()
  M.trail:clear_trail()
end

M.virtual_text_on = function()
  M.trail:virtual_text_on()
end

M.virtual_text_off = function()
  M.trail:virtual_text_off()
end

M.virtual_text_toggle = function()
  M.trail:virtual_text_toggle()
end

M.new_trail = function(trail_name)
  -- TODO: Check if trail name already exists.
  if trail_name ~= nil then
    M.trail = trail.new(trail_name)
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
  end
end

M.remove_trail = function(trail_name)
  -- TODO: handle case where removing current trail. Virtual text stays up.
  local trail_file = string.format("%s/%s", serde.get_current_project_dir(), trail_name)
  local file, _ = io.open(trail_file, "r")

  if file then
    os.execute(string.format("rm %s", trail_file))
  end
end

-------------------
-- User commands --
-------------------
local function_map = {
  trail_map = M.trail_map,
  new_trail = M.new_trail,
  change_trail = M.change_trail,
  remove_trail = M.remove_trail,
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
    print("Invalid function name: " .. function_name)
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

--------------------
-- Initialization --
--------------------
local default_trail_name = 'trail'
local default_trail_file = string.format("%s/%s", serde.get_current_project_dir(), default_trail_name)
local file = io.open(default_trail_file, "r")

if file then
  M.change_trail(default_trail_name)
else
  M.new_trail(default_trail_name)
end

return M
