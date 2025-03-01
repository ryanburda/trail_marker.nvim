local utils = require("trail_marker.utils")

---Mark locations in code.
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
  local bufnr = utils.get_bufnr_by_path(self.path)

  if bufnr then
    -- If the buffer exists, switch to it
    vim.api.nvim_set_current_buf(bufnr)
  else
    -- Otherwise, open the file in a new buffer
    vim.cmd('edit ' .. vim.fn.fnameescape(self.path))
  end

  -- Handle the case where the content of the line has changed.
  -- Go to the end of the row if the column number exceeds the length of the row.
  local line_length = utils.get_line_length(self.path, self.row)
  local col_adjusted = math.min(self.col, line_length)

  -- set the cursor to the specified line and column
  vim.api.nvim_win_set_cursor(0, {self.row, col_adjusted})
end

return Marker
