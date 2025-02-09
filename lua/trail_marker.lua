-- This is the api of the plugin.
local marker = require("trail_marker.marker")
local trail = require("trail_marker.trail")

local M = {}

M.trail = trail.new("trail")

M.trail_map = function()
  M.trail:trail_map()
end

M.place_marker = function()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local path = vim.api.nvim_buf_get_name(0)

  local b = marker.new(row, col, path)

  M.trail:place_marker(b)
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

return M
