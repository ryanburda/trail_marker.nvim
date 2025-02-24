--[[

Multiple markers make a trail.

--]]
local marker = require("trail_marker.marker")

local Trail = {}
Trail.__index = Trail

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
    table.insert(marker_list, marker.from_table(marker_dict))
  end

  self.marker_list = marker_list
  self:build_marker_map()

  self.ns_id = vim.api.nvim_create_namespace("trail_marker")
  self:setup_autocmd()
  self:virtual_text_update_all_bufs()

  return self
end

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

function Trail:build_marker_map()
  --[[
  `Trail.marker_list` -> `Trail.marker_map` conversion.

  This function builds more convenient lookup table for markers that is keyed based on file path and row.
  The list of markers will still be used to preserve the order of markings.
  This table will make it easier to remove markers and handle virtual text.

  The cost of maintaining two different representations of the same data should pay off by avoiding situations
  where we need to rip through the entire markers list to perform an operation.

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
  self:save_trail()

  vim.api.nvim_exec_autocmds('User', { pattern = 'TrailMarkerEvent' })
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

  self:save_trail()
  vim.api.nvim_exec_autocmds('User', { pattern = 'TrailMarkerEventPositionUpdate' })
end

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

function Trail:goto_marker(pos)
  if 0 < pos and pos <= #self.marker_list then
    self.trail_pos = pos
    self.marker_list[self.trail_pos]:goto()

    vim.api.nvim_exec_autocmds('User', { pattern = 'TrailMarkerEventPositionUpdate' })
  end

  self:save_trail()
end

function Trail:current_marker()
  self:goto_marker(self.trail_pos)
end

function Trail:next_marker()
  self:goto_marker(self.trail_pos + 1)
  self:save_trail()
end

function Trail:prev_marker()
  self:goto_marker(self.trail_pos - 1)
  self:save_trail()
end

function Trail:trail_head()
  self:goto_marker(1)
  self:save_trail()
end

function Trail:trail_end()
  self:goto_marker(#self.marker_list)
  self:save_trail()
end

function Trail:clear_trail()
  self.marker_list = {}
  self.trail_pos = 0

  self:build_marker_map()
  self:virtual_text_update_all_bufs()
  self:save_trail()
  vim.api.nvim_exec_autocmds('User', { pattern = 'TrailMarkerEventPositionUpdate' })
end

function Trail:trail_map()
  print(vim.inspect(self.marker_list))
end

-- Virtual Text
--
-- Provide indicators of where trail markers are as virtual text.
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

function Trail:virtual_text_update_all_bufs()
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

-- Serialize/Deserialize
--
-- To keep things simple a project will be determined by the the current working directory.
-- This means if your cwd is `~/project1` you will not see any of the trails associated with `~/project2`.
-- Note: This may change in the future to be aware of git repos.
--
-- The absolute path of each project will be hashed to produce a unique project directory name.
-- Inside each project directory will be a set of files for each trail.
--
-- ~/.local/share/nvim/trail_marker/trails/
--                                      -> 1234abcd/
--                                               -> trail1
--                                               -> trail2
--                                               -> trail3
--                                      -> 5678efgh/
--                                               -> debug
--                                               -> ticket123
--
-- Each trail file will contain the entire trail serialized.
-- ```
-- {
--   ["is_virtual_text_on"] = true,
--   ["marker_list"] = {
--     [1] = {
--       ["row"] = 334,
--       ["col"] = 3,
--       ["path"] = "path/to/file",
--     },
--   },
--   ["trail_pos"] = 1,
--   ["name"] = "trail",
--   ["ns_id"] = 25,
--   ["marker_map"] = {
--     ["path/to/file"] = {
--       [334] = {
--         ["markers"] = {
--           [1] = 1,
--         },
--         ["virtual_text"] = "trail 1",
--       },
--     },
--   },
-- }
-- ```
local serde = require("trail_marker.serde")

function Trail:get_save_file_path()
  return string.format(
    "%s/%s",
    serde.get_current_project_dir(),
    self.name
  )
end

function Trail:save_trail()
  serde.write_to_file(serde.serialize(self), self:get_save_file_path())
end

return Trail
