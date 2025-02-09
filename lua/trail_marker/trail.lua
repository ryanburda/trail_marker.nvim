-- Multiple markers make a trail.
local marker = require("trail_marker.marker")

local Trail = {}
Trail.__index = Trail

function Trail.new(name)
  local self = setmetatable({}, Trail)

  self.name = name
  self.markers = {}
  self.trail_pos = 0

  return self
end

function Trail:trail_map()
  print(vim.inspect(self.markers))
end

function Trail:place_marker()
  self.trail_pos = self.trail_pos + 1
  local b = marker.new()

  table.insert(self.markers, self.trail_pos, b)
end

function Trail:remove_marker(pos)
  if 0 < pos and pos <= #self.markers then
    table.remove(self.markers, pos)
  end

  if not(pos == 1 and self.trail_pos == 1 and #self.markers > 1) then
    self.trail_pos = self.trail_pos - 1
  end
end

function Trail:goto_marker(pos)
  if 0 < pos and pos <= #self.markers then
    self.trail_pos = pos
    self.markers[self.trail_pos]:goto()
  end
end

function Trail:current_marker()
  self:goto_marker(self.trail_pos)
end

function Trail:next_marker()
  self:goto_marker(self.trail_pos + 1)
end

function Trail:prev_marker()
  self:goto_marker(self.trail_pos - 1)
end

function Trail:trail_head()
  self:goto_marker(1)
end

function Trail:trail_end()
  self:goto_marker(#self.markers)
end

function Trail:clear_trail()
  self.markers = {}
  self.trail_pos = 0
end

return Trail
