-- Multiple markers make a trail.
local Trail = {}
Trail.__index = Trail

function Trail.new(name)
  local self = setmetatable({}, Trail)

  self.name = name
  self.trail = {}
  self.trail_pos = 0

  return self
end

function Trail:trail_map()
  print(vim.inspect(self.trail))
end

function Trail:place_marker(b)
  self.trail_pos = self.trail_pos + 1
  table.insert(self.trail, self.trail_pos, b)
end

function Trail:remove_marker(pos)
  if 0 < pos and pos <= #self.trail then
    table.remove(self.trail, pos)
  end

  if not(pos == 1 and self.trail_pos == 1 and #self.trail > 1) then
    self.trail_pos = self.trail_pos - 1
  end
end

function Trail:update_position(pos)
  if 0 < pos and pos <= #self.trail then
    self.trail_pos = pos
    self.trail[self.trail_pos]:goto()
  end
end

function Trail:current_marker()
  self:update_position(self.trail_pos)
end

function Trail:next_marker()
  self:update_position(self.trail_pos + 1)
end

function Trail:prev_marker()
  self:update_position(self.trail_pos - 1)
end

function Trail:trail_head()
  self:update_position(1)
end

function Trail:trail_end()
  self:update_position(#self.trail)
end

return Trail
