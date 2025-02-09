-- Mark specific locations in your code.
local Marker = {}
Marker.__index = Marker

function Marker.new(row, col, path)
  local self = setmetatable({}, Marker)

  self.row = row
  self.col = col
  self.path = path

  return self
end

function Marker:goto()
  -- open the file
  vim.cmd('edit ' .. self.path)
  -- set the cursor to the specified line and column
  vim.api.nvim_win_set_cursor(0, {self.row, self.col})
end

return Marker
