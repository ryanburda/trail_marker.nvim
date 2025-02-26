--[[

Mark specific locations in your code.

--]]
local utils = require("trail_marker.utils")

local Marker = {}
Marker.__index = Marker

function Marker.new()
  local self = setmetatable({}, Marker)

  self.row, self.col, self.path = Marker.get_location()

  return self
end

function Marker.from_table(t)
  local self = setmetatable({}, Marker)

  self.row = t.row
  self.col = t.col
  self.path = t.path

  return self
end

function Marker:goto()
  -- open the file
  utils.switch_or_open(self.path, self.row, self.col)
end

Marker.get_location = function()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local path = vim.api.nvim_buf_get_name(0)

  return row, col+1, path
end

return Marker
