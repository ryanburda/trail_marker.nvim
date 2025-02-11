-- Multiple markers make a trail.
local marker = require("trail_marker.marker")

local Trail = {}
Trail.__index = Trail

function Trail.new(name)
  local self = setmetatable({}, Trail)

  self.name = name
  self.trail_pos = 0
  self.marker_list = {}
  self.marker_map = self:build_marker_map()

  -- virtual text
  self.ns_id = vim.api.nvim_create_namespace("trail_marker_" .. name)
  self.is_virtual_text_on = true

  -- autocommand to add virtual text to newly opened buffers.
  vim.api.nvim_create_augroup('trail_marker', { clear = true })
  vim.api.nvim_create_autocmd('BufEnter', {
    group = 'trail_marker',
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()

      if self.marker_map == nil then
        self:build_marker_map()
      end

      self:virtual_text_update_bufnr(bufnr)
    end
  })

  return self
end

function Trail:build_marker_map()
  --[[
  `Trail.marker_list` -> `Trail.marker_map` conversion.

  This function builds more convenient lookup table for markers that is keyed based on file path and row.
  The list of markers will still be used to preserve the order of markings.
  This table will make it easier to remove markers and handle virtual text.

  NOTE: it is important to call this function whenever the set of markers changes to keep the list and map in sync.

  Transform the `Trail.marker_list` table that looks like this (list of dictionaries):
  ```lua
  local marker_list = {
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
  }
  ```

  into the `Trail.marker_map` table that looks like this (dictionaries all the way down):
  ```lua
  local marker_map = {
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
  local marker_map = {}

  for idx, mark in ipairs(self.marker_list) do
    -- first time seeing this path.
    if marker_map[mark.path] == nil then
      marker_map[mark.path] = {}
    end

    -- first time seeing this row.
    if marker_map[mark.path][mark.row] == nil then
      marker_map[mark.path][mark.row] = { markers = {}, virtual_text = "" }
    end

    -- create an array of marker numbers first.
    table.insert(marker_map[mark.path][mark.row].markers, idx)
  end

  for buf_path, file_dict in pairs(marker_map) do
    for row, row_dict in pairs(file_dict) do
      -- flatten the marker number array into a virtual text string.
      row_dict.virtual_text = self.name .. " " .. table.concat(marker_map[buf_path][row].markers, ",")
    end
  end

  self.marker_map = marker_map
end

function Trail:get_markers_at_location()
  local row, _, path = marker.get_location();

  if self.marker_map[path] ~= nil and self.marker_map[path][row] ~= nil then  -- Is there a better way to avoid nil?
    return self.marker_map[path][row].markers
  end
end

function Trail:place_marker()
  self.trail_pos = self.trail_pos + 1
  local b = marker.new()

  table.insert(self.marker_list, self.trail_pos, b)

  self:build_marker_map()
  self:virtual_text_update_all_bufs()
end

function Trail:remove_marker(pos)
  table.remove(self.marker_list, pos)

  self:build_marker_map()
  self:virtual_text_update_all_bufs()

  -- Trail position should be moved one closer to the beginning of the trail when:
  --    - the current marker is being removed.
  --    - or if the marker being removed is between the beginning of the trail and the current position.
  if pos <= self.trail_pos then
    self.trail_pos = self.trail_pos - 1
  end

  -- Make sure we didn't fall off the trail.
  if self.trail_pos < 1 and self.trail ~= nil and #self.trail > 0 then
    self.trail_pos = 1
  end
end

function Trail:remove_marker_at_location()
  local markers = self:get_markers_at_location()
  if markers ~= nil then
    self:remove_marker(markers[1])  -- TODO: prompt for user selection when more than one marker on line
  end
end

function Trail:goto_marker(pos)
  if 0 < pos and pos <= #self.marker_list then
    self.trail_pos = pos
    self.marker_list[self.trail_pos]:goto()
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
  self:goto_marker(#self.marker_list)
end

function Trail:clear_trail()
  self.marker_list = {}
  self.trail_pos = 0

  self:build_marker_map()
  self:virtual_text_update_all_bufs()
end

function Trail:trail_map()
  print(vim.inspect(self.marker_list))
end

-- Virtual Text
function Trail:virtual_text_update_bufnr(bufnr)
  -- Update the virtual text for a specific buffer.
  if self.is_virtual_text_on then
    vim.api.nvim_buf_clear_namespace(bufnr, self.ns_id, 0, -1)

    local buffer_path = vim.api.nvim_buf_get_name(bufnr)
    local buf_map = self.marker_map[buffer_path]

    if buf_map then
      for row, dict in pairs(self.marker_map[buffer_path]) do
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
end

function Trail:virtual_text_update_all_bufs()
  -- Update virtual text for all buffers.
  local bufnrs = vim.api.nvim_list_bufs()

  for _, bufnr in ipairs(bufnrs) do
    self:virtual_text_update_bufnr(bufnr)
  end
end

function Trail:virtual_text_on()
  self.is_virtual_text_on = true
  self:virtual_text_update_all_bufs()
end

function Trail:virtual_text_off()
  self.is_virtual_text_on = false
  local bufnrs = vim.api.nvim_list_bufs()

  for _, bufnr in ipairs(bufnrs) do
    vim.api.nvim_buf_clear_namespace(bufnr, self.ns_id, 0, -1)
  end
end

function Trail:virtual_text_toggle()
  if self.is_virtual_text_on then
    self:virtual_text_off()
  else
    self:virtual_text_on()
  end
end

return Trail
