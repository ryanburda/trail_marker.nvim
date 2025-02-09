-- Mark specific locations in your code.
local Marker = {}
Marker.__index = Marker

function Marker.new()
  local self = setmetatable({}, Marker)

  self.row, self.col = unpack(vim.api.nvim_win_get_cursor(0))
  self.path = vim.api.nvim_buf_get_name(0)

  return self
end

function Marker:goto()
  -- open the file
  vim.cmd('edit ' .. self.path)
  -- set the cursor to the specified line and column
  vim.api.nvim_win_set_cursor(0, {self.row, self.col})
end

return Marker
