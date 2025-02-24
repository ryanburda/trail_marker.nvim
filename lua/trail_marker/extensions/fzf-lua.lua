--[[

fzf-lua integration - provide a fuzzy finding interface for Trail Marker commands.

NOTES:
  - This should only be used if fzf-lua is installed.
  - This should only be used after Trail Marker has been set up.

Example usage:
```lua
vim.keymap.set(
  'n',
  '<leader>tm',
  require("trail_marker.extensions.fzf-lua").trail_map,
  { desc = "Trail Marker: List markers on current trail with fzf-lua" }
)

vim.keymap.set(
  'n',
  '<leader>tc',
  require("trail_marker.extensions.fzf-lua").change_trail,
  { desc = "TrailMarker: Change trails with fzf-lua" }
)
```

--]]
local trail_marker = require("trail_marker")
local utils = require("trail_marker.utils")

local M = {}

M.trail_map = function()
  if trail_marker.trail == nil or #trail_marker.trail.marker_list == 0 then
    print("No trail markers available")
    return
  end

  -- Make a custom previewer since the entries will not be in the normal path:row:col format
  local builtin = require("fzf-lua.previewer.builtin")

  -- Inherit from the "buffer_or_file" previewer
  local MyPreviewer = builtin.buffer_or_file:extend()

  function MyPreviewer:new(o, opts, fzf_win)
    MyPreviewer.super.new(self, o, opts, fzf_win)
    setmetatable(self, MyPreviewer)
    return self
  end

  function MyPreviewer:parse_entry(entry_str)
    local _, path, row, col = entry_str:match("([^:]+):([^:]+):([^:]+):([^:]+)")
    return {
      path = path,
      line = tonumber(row) or 1,
      col = col,
    }
  end

  require("fzf-lua").fzf_exec(
    function(cb)
      for idx, marker in ipairs(trail_marker.trail.marker_list) do
        -- TODO: show relative path in picker without breaking preview.
        -- TODO: add content of line so that it can be searched. (similar being done in telescope integration)
        -- local path = vim.fn.fnamemodify(marker.path, ':.')
        cb(string.format("%s:%s:%s:%s", idx, marker.path, marker.row, marker.col))
      end
      cb()
    end,
    {
      prompt = "Trail Markers> ",
      previewer = MyPreviewer,
      actions = {
        ["default"] = function(selected)
          local marker_info = selected[1]
          local idx, path, row, col = marker_info:match("([^:]+):([^:]+):([^:]+):([^:]+)")
          utils.switch_or_open(path, tonumber(row), tonumber(col))
          require("trail_marker").trail:goto_marker(tonumber(idx))
        end,
        ["ctrl-k"] = {
          fn = function(selected)
            local marker_info = selected[1]
            local idx, _, _, _ = marker_info:match("([^:]+):([^:]+):([^:]+):([^:]+)")
            require("trail_marker").trail:remove_marker(tonumber(idx))
          end,
          reload = true,
        },
      },
    }
  )
end

M.change_trail = function()
  require("fzf-lua").fzf_exec(
    function(cb)
      -- use a function to support reloads.
      local trails = require("trail_marker").get_trail_list()
      for _, trail in ipairs(trails) do
        cb(trail)
      end
      cb()
    end,
    {
      prompt = "Change Trail> ",
      previewer = false,
      actions = {
        ["default"] = function(selected)
          local trail_name = selected[1]:match("%w+")
          if trail_name then
            trail_marker.change_trail(trail_name)
          else
            vim.notify("No trail selected!", vim.log.levels.WARN)
          end
        end,
        ["ctrl-k"] = {
          fn = function(selected)
            local trail_name = selected[1]:match("%w+")
            if trail_name then
              trail_marker.remove_trail(trail_name)
            else
              vim.notify("No trail selected!", vim.log.levels.WARN)
            end
          end,
          reload = true,
        },
      },
      winopts = {
        width = 0.3,
        height = 0.3,
        col = 0.5,  -- Center horizontally
        row = 0.5,  -- Center vertically
      },
    }
  )
end

return M
