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

M.save_trail = function()
  M.trail:save_trail()
end

M.new_trail = function()
  local function on_input(input)
    -- TODO: Check if trail name already exists.
    M.trail = trail.new(input)
  end

  vim.ui.input({ prompt = "Enter trail name: ", }, on_input)
end

M.change_trail = function(name)
  local function on_input(input)
    local trail_file = string.format("%s/%s", serde.get_current_project_dir(), input)
    local file, _ = io.open(trail_file, "r")

    if file then
      local content = file:read("*a")
      file:close()

      local deserialized_trail = serde.deserialize(content)
      M.trail = trail.from_table(deserialized_trail)
    end
  end

  if name == nil then
    vim.ui.input({ prompt = "Enter trail name: ", }, on_input)
  else
    on_input(name)
  end
end

-- Initialization
--
-- Check for the default trail
local default_trail_name = 'trail'
local default_trail_file = string.format("%s/%s", serde.get_current_project_dir(), default_trail_name)
local file = io.open(default_trail_file, "r")

if file then
  M.change_trail(default_trail_name)
  --M.trail:virtual_text_update_all_bufs()
else
  M.trail = trail.new(default_trail_name)
end

return M
