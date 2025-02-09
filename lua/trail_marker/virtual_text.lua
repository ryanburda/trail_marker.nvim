-- Virtual Text is managed at the level of an entire trail.
-- This makes it easier to have the following in the virtual text:
--   - marker numbers
--   - current, previous, next position indicators
local VirtualText = {}
VirtualText.__index = VirtualText

function VirtualText.new(trail)
  local self = setmetatable({}, VirtualText)

  self.trail = trail
  self.buf_vtext_map = self:build_vtext_map()
  self.ns_id = vim.api.nvim_create_namespace("trail_marker_" .. trail.name)
  self.is_on = true

  -- add autocommand on buf open to add virtual text to newly opened buffers.
  vim.api.nvim_create_augroup('trail_marker', { clear = true })
  vim.api.nvim_create_autocmd('BufEnter', {
    group = 'trail_marker',
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()

      if self.buf_vtext_map == nil then
        self:build_vtext_map()
      end

      self:update_bufnr(bufnr)
    end
  })

  return self
end

function VirtualText:build_vtext_map()
  --[[
  This function builds a table that manages all of the virtual text strings for all markers.

  Transform the `Trail.markers` table that looks like this (list of dictionaries):
  ```lua
  local markers = {
    {                          -- marker 1
      ["row"] = 5,
      ["col"] = 0,
      ["path"] = "file/path1"
    },
    {                          -- marker 2
      ["row"] = 11,
      ["col"] = 4,
      ["path"] = "file/path1"
    },
    {                          -- marker 3
      ["row"] = 14,
      ["col"] = 0,
      ["path"] = "file/path1"
    },
    {                          -- marker 4
      ["row"] = 1,
      ["col"] = 0,
      ["path"] = "file/path2"
    },
  ```

  into a table that looks like this (dictionary of dictionary of dictionaries):
  ```lua
  local map = {
    ["file/path1"] = {                         -- file path
      [5] = {                                  -- row number
        ["markers"] = {1, 4},                  -- markers numbers on this row
        ["virtual_text"] = "trail_name 1, 4",  -- virtual text to be displayed on this row
      },
      [14] = {
        ["markers"] = {3},
        ["virtual_text"] = "trail_name 3",
    },
    ["file/path2"] = {
      [1] = {
        ["markers"] = {2},
        ["virtual_text"] = "trail_name 2",
    },
  }
  ```
  --]]
  local buf_vtext_map = {}

  for idx, marker in ipairs(self.trail.markers) do
    -- first time seeing this path
    if buf_vtext_map[marker.path] == nil then
      buf_vtext_map[marker.path] = {}
    end

    -- first time seeing this row
    if buf_vtext_map[marker.path][marker.row] == nil then
      buf_vtext_map[marker.path][marker.row] = { markers = {}, virtual_text = "" }
    end

    -- create an array of marker numbers first
    table.insert(buf_vtext_map[marker.path][marker.row].markers, idx)
  end

  for buf_path, file_dict in pairs(buf_vtext_map) do
    for row, row_dict in pairs(file_dict) do
      -- flatten the marker number array into a string
      row_dict.virtual_text = self.trail.name .. " " .. table.concat(buf_vtext_map[buf_path][row].markers, ", ")
    end
  end

  self.buf_vtext_map = buf_vtext_map
end

function VirtualText:update_bufnr(bufnr)
  -- Update the virtual text for a specific buffer WITHOUT rebuilding the vtext map.
  -- Useful for running in autocommands like BufEnter where the map has not changed.
  vim.api.nvim_buf_clear_namespace(bufnr, self.ns_id, 0, -1)

  local buffer_path = vim.api.nvim_buf_get_name(bufnr)
  local buf_map = self.buf_vtext_map[buffer_path]

  if buf_map then
    for row, dict in pairs(self.buf_vtext_map[buffer_path]) do
      vim.api.nvim_buf_set_extmark(
        bufnr,
        self.ns_id,
        row-1,
        0,
        { virt_text = {{dict.virtual_text, "StatusLine"}}, virt_text_pos = 'right_align', }
      )
    end
  end
end

function VirtualText:update_all()
  -- Rebuild the vtext map and update virtual text for all buffers.
  self:build_vtext_map()

  local bufnrs = vim.api.nvim_list_bufs()

  for _, bufnr in ipairs(bufnrs) do
    self:update_bufnr(bufnr)
  end
end

function VirtualText:on()
  self.is_on = true
  self:update_all()
end

function VirtualText:off()
  self.is_on = false
  local bufnrs = vim.api.nvim_list_bufs()

  for _, bufnr in ipairs(bufnrs) do
    vim.api.nvim_buf_clear_namespace(bufnr, self.ns_id, 0, -1)
  end
end

function VirtualText:toggle()
  if self.is_on then
    self:off()
  else
    self:on()
  end
end

return VirtualText
