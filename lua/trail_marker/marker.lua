local utils = require("trail_marker.utils")

---Mark locations in your code.
---@class Marker
---@field path string The file path where the marker is located.
---@field row number The row position of the marker.
---@field col number The column position of the marker.
local Marker = {}
Marker.__index = Marker

---Creates a Marker instance.
---@param path string The file path where the marker is located.
---@param row number The row position of the marker.
---@param col number The column position of the marker.
---@return Marker
function Marker.new(path, row, col)
  local self = setmetatable({}, Marker)

  self.path = path
  self.row = row
  self.col = col

  return self
end

---Creates a new Marker instance based of the cursors current position.
---@return Marker
function Marker.from_cursor_location()
  return Marker.new(utils.get_location())
end

---Navigates to the marker's location.
function Marker:goto()
  utils.switch_or_open(self.path, self.row, self.col)
end

return Marker
