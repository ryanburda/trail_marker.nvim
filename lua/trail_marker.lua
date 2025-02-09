-- This is the api of the plugin.
local trail = require("trail_marker.trail")
local virtual_text = require("trail_marker.virtual_text")

local M = {}

M.trail = trail.new("trail")
M.virtual_text = virtual_text.new(M.trail)

M.trail_map = function()
  M.trail:trail_map()
end

M.place_marker = function()
  M.trail:place_marker()
  M.virtual_text:update_all()
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
  M.virtual_text:update_all()
end

M.virtual_text_toggle = function()
  M.virtual_text:toggle()
end

M.virtual_text_on = function()
  M.virtual_text:on()
end

M.virtual_text_off = function()
  M.virtual_text:off()
end

return M
