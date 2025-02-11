-- This is the api of the plugin.
local trail = require("trail_marker.trail")

local M = {}

M.trail = trail.new("trail")

local serde = require("trail_marker.serde")
local file, _ = io.open(M.trail:get_save_file_path(), "r")

if file then
  local content = file:read("*a")
  file:close()

  local deserialized_trail = serde.deserialize(content)
  M.trail = trail.from_table(deserialized_trail)
end

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
  M.trail:next_marker()
end

M.prev_marker = function()
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

return M
