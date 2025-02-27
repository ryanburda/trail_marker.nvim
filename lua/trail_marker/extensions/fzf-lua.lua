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
local fzf_utils = require("fzf-lua.utils")

local M = {}

M.trail_map = function()
  if trail_marker.trail == nil or #trail_marker.trail.marker_list == 0 then
    print("No trail markers available")
    return
  end

  local function marker_to_string(marker, idx)
    -- This function acts as an fzf-lua specific serializer.
    -- The string representation of a marker that is passed to fzf will be as follows.
    -- `:` is used as a delimiter to allow some of these fields to be hidden with `--with-nth`.
    local rel_path = vim.fn.fnamemodify(marker.path, ':.')
    local line_content = utils.get_line_contents(marker.path, marker.row)

    return string.format("%s:%s:%s:%s:%s:%s", idx, marker.path, rel_path, marker.row, marker.col, line_content)
  end

  local function marker_from_string(str)
    -- This function acts as an fzf-lua specific deserializer.
    local idx, path, rel_path, row, col, content = str:match("([^:]+):([^:]+):([^:]+):([^:]+):([^:]+):([^:]*)")
    return idx, path, rel_path, row, col, content
  end

  -- Make a custom previewer since the entries will not be in the normal path:row:col format
  local builtin = require("fzf-lua.previewer.builtin")

  local previewer = builtin.buffer_or_file:extend()

  function previewer:new(o, opts, fzf_win)
    previewer.super.new(self, o, opts, fzf_win)
    setmetatable(self, previewer)
    return self
  end

  function previewer:parse_entry(entry_str)
    local _, path, _, row, col, _ = marker_from_string(entry_str)
    return {
      path = path,
      line = tonumber(row),
      col = tonumber(col),
    }
  end

  local ctrl_k = string.format("<%s> to %s", fzf_utils.ansi_codes.yellow("ctrl-k"), fzf_utils.ansi_codes.red("Remove Marker"))
  local ctrl_x = string.format("<%s> to %s", fzf_utils.ansi_codes.yellow("ctrl-x"), fzf_utils.ansi_codes.red("Clear Trail"))
  local header = string.format(":: %s | %s", ctrl_k, ctrl_x)

  require("fzf-lua").fzf_exec(
    function(cb)
      -- use a function to support reloads.
      for idx, marker in ipairs(trail_marker.trail.marker_list) do
        cb(marker_to_string(marker, idx))
      end
      cb()
    end,
    {
      prompt = string.format("Trail Markers - %s> ", require("trail_marker").trail.name),
      previewer = previewer,
      actions = {
        ["default"] = function(selected)
          local marker_info = selected[1]
          local idx, path, _, row, col, _ = marker_from_string(marker_info)
          utils.switch_or_open(path, tonumber(row), tonumber(col))
          require("trail_marker").trail:goto_marker(tonumber(idx))
        end,
        ["ctrl-k"] = function(selected)
          local marker_info = selected[1]
          local idx, _, _, _, _, _ = marker_from_string(marker_info)
          require("trail_marker").trail:remove_marker(tonumber(idx))
          require("fzf-lua").resume()
        end,
        ["ctrl-x"] = function(_)
          require("trail_marker").clear_trail()
          require("fzf-lua").resume()
        end,
      },
      fzf_opts = {
        ["--delimiter"] = ":",
        ["--with-nth"] = "1,3,4,5,6",
        ["--header"] = header,
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
        ["ctrl-k"] = function(selected)
          local trail_name = selected[1]:match("%w+")
          if trail_name then
            trail_marker.remove_trail(trail_name)
            require("fzf-lua").resume()
          else
            vim.notify("No trail selected!", vim.log.levels.WARN)
          end
        end,
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
