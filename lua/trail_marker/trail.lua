--[[

Multiple markers make a trail.

--]]

local marker = require("trail_marker.marker")
local utils = require("trail_marker.utils")

--- @class Trail
--- @field name string
--- @field trail_pos number
--- @field marker_list table
--- @field ns_id number
--- @field is_virtual_text_on boolean
--- @field marker_map table
local Trail = {}
Trail.__index = Trail

--- Creates a new Trail instance.
--- @param name string: The name of the trail.
--- @return Trail: A new trail instance.
function Trail.new(name)
  local self = setmetatable({}, Trail)

  self.name = name
  self.trail_pos = 0
  self.marker_list = {}
  self:build_marker_map()

  -- virtual text
  self.ns_id = vim.api.nvim_create_namespace("trail_marker")
  self.is_virtual_text_on = true
  self:virtual_text_update_all_bufs()
  self:setup_autocmd()

  self:save_trail()

  return self
end

--- Creates a Trail instance from a table.
--- @param t table: The table representation of a trail.
--- @return Trail: A new trail instance created from the table.
function Trail.from_table(t)
  -- TODO: get rid of duplication with `Trail.new`.
  local self = setmetatable({}, Trail)

  self.name = t.name
  self.trail_pos = t.trail_pos
  self.is_virtual_text_on = t.is_virtual_text_on

  -- The marker_list and map need to be recreated since markers are objects.
  -- Assigning the table representation to the object will not work.
  local marker_list = {}

  for _, marker_dict in ipairs(t.marker_list) do
    table.insert(marker_list, marker.new(marker_dict.path, marker_dict.row, marker_dict.col))
  end

  self.marker_list = marker_list
  self:build_marker_map()

  self.ns_id = vim.api.nvim_create_namespace("trail_marker")
  self:setup_autocmd()
  self:virtual_text_update_all_bufs()

  return self
end

--- Sets up autocommands for the Trail instance.
function Trail:setup_autocmd()
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
end

--- Builds a marker map for fast lookup.
function Trail:build_marker_map()
  --[[
  `Trail.marker_list` -> `Trail.marker_map` conversion.

  This function builds more convenient lookup table for markers that is keyed based on file path and row.
  The list of markers will still be used to preserve the order of markings.
  This table will make it easier to remove markers and handle virtual text.

  The cost of maintaining two different representations of the same data should pay off since we'll only
  be calling this function whenever the marker_list changes. If we didn't have this secondary representation
  we'd need to write similar code that that is called far more frequently, like every buf open or virtual text toggle.

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

--- Gets markers at current location.
--- @return table | nil: Returns a table of markers at current location or nil if none exist.
function Trail:get_markers_at_location()
  local path, row, _ = utils.get_location()

  if self.marker_map[path] ~= nil and self.marker_map[path][row] ~= nil then
    return self.marker_map[path][row].markers
  end
end

--- Places a new marker at the current cursor position.
function Trail:place_marker()
  self.trail_pos = self.trail_pos + 1
  local b = marker.from_cursor_location()

  table.insert(self.marker_list, self.trail_pos, b)
  self:build_marker_map()
  self:virtual_text_update_all_bufs()
  self:save_trail()

  vim.api.nvim_exec_autocmds('User', { pattern = 'TrailMarkerEvent' })
end

--- Removes a marker at a given position.
--- @param pos number: The position of the marker to remove.
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
  if self.trail_pos < 1 and #self.marker_list > 0 then
    self.trail_pos = 1
  end

  self:save_trail()
  vim.api.nvim_exec_autocmds('User', { pattern = 'TrailMarkerEventPositionUpdate' })
end

--- Removes a marker at the current cursor location.
function Trail:remove_marker_at_location()
  local marker_positions = self:get_markers_at_location()

  if marker_positions ~= nil then
    if #marker_positions > 1 then
      -- ask user which mark should be removed if there are multiple.
      local opts = {
        prompt = string.format(
          "Which mark should be removed? Current Position-%s Options-(%s): ",
          self.trail_pos,
          table.concat(marker_positions, ',')
        ),
      }

      local function on_input(input)
        for _, marker_position in ipairs(marker_positions) do
          if marker_position == tonumber(input) then
            self:remove_marker(marker_position)
          end
        end
      end

      vim.ui.input(opts, on_input)
    else
      self:remove_marker(marker_positions[1])
    end
  end
end

--- Goes to a specific marker position.
--- @param pos number: The position of the marker to go to.
function Trail:goto_marker(pos)
  if 0 < pos and pos <= #self.marker_list then
    self.trail_pos = pos
    self.marker_list[self.trail_pos]:goto()

    vim.api.nvim_exec_autocmds('User', { pattern = 'TrailMarkerEventPositionUpdate' })
  end

  self:save_trail()
end

--- Jumps to the current marker in the trail.
function Trail:current_marker()
  self:goto_marker(self.trail_pos)
end

--- Jumps to the next marker in the trail.
function Trail:next_marker()
  self:goto_marker(self.trail_pos + 1)
  self:save_trail()
end

--- Jumps to the previous marker in the trail.
function Trail:prev_marker()
  self:goto_marker(self.trail_pos - 1)
  self:save_trail()
end

--- Jumps to the first marker in the trail.
function Trail:trail_head()
  self:goto_marker(1)
  self:save_trail()
end

--- Jumps to the last marker in the trail.
function Trail:trail_end()
  self:goto_marker(#self.marker_list)
  self:save_trail()
end

--- Clears all markers from the trail.
function Trail:clear_trail()
  self.marker_list = {}
  self.trail_pos = 0

  self:build_marker_map()
  self:virtual_text_update_all_bufs()
  self:save_trail()
  vim.api.nvim_exec_autocmds('User', { pattern = 'TrailMarkerEventPositionUpdate' })
end

--- Prints the trail map.
function Trail:trail_map()
  print(vim.inspect(self.marker_list))
end

--- Updates virtual text for a specific buffer number.
--- @param bufnr number: The buffer number to update virtual text for.
function Trail:virtual_text_update_bufnr(bufnr)
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
          { virt_text = {{dict.virtual_text, "WinBar"}}, virt_text_pos = 'right_align', }
        )
      end
    end
  end
end

--- Updates virtual text for all buffers.
function Trail:virtual_text_update_all_bufs()
  local bufnrs = vim.api.nvim_list_bufs()

  for _, bufnr in ipairs(bufnrs) do
    self:virtual_text_update_bufnr(bufnr)
  end
end

--- Turns virtual text on.
function Trail:virtual_text_on()
  self.is_virtual_text_on = true
  self:virtual_text_update_all_bufs()
end

--- Turns virtual text off.
function Trail:virtual_text_off()
  self.is_virtual_text_on = false
  local bufnrs = vim.api.nvim_list_bufs()

  for _, bufnr in ipairs(bufnrs) do
    vim.api.nvim_buf_clear_namespace(bufnr, self.ns_id, 0, -1)
  end
end

--- Toggles virtual text on and off.
function Trail:virtual_text_toggle()
  if self.is_virtual_text_on then
    self:virtual_text_off()
  else
    self:virtual_text_on()
  end
end

--- Saves the trail to a file.
---
--- To keep things simple a project will be determined by the the current working directory.
--- This means if your cwd is `~/project1` you will not see any of the trails associated with `~/project2`.
--- NOTE: This may change in the future to be aware of git repos.
---
--- The absolute path of each project will be hashed to produce a unique project directory name.
--- Inside each project directory will be a set of files for each trail.
---
--- ~/.local/share/nvim/trail_marker/trails/
---                                      -> 1234abcd/
---                                               -> trail1
---                                               -> trail2
---                                               -> trail3
---                                      -> 5678efgh/
---                                               -> debug
---                                               -> ticket123
---
--- Each trail file will contain the entire trail serialized.
function Trail:save_trail()
  local save_file = string.format("%s/%s", utils.get_current_project_dir(), self.name)
  utils.write_to_file(utils.serialize(self), save_file)
end

return Trail
