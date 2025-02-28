--[[

Mark specific locations in your code.

--]]
local utils = require("trail_marker.utils")

local Marker = {}
Marker.__index = Marker

function Marker.new()
  local self = setmetatable({}, Marker)

  self.row, self.col, self.path = utils.get_location()

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
  utils.switch_or_open(self.path, self.row, self.col)
end

return Marker
