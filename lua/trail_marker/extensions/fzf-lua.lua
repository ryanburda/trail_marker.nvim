--[[

fzf-lua integration - provide a fuzzy finding interface for Trail Marker commands.

NOTES:
  - This should only be used if fzf-lua is installed.
  - This should only be used after Trail Marker has been set up.

TODO: Break this up into more reusable pieces. A default fzf-lua integration
      should exist but it should also be easily possible to customize.

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
local devicons = require("nvim-web-devicons")

local M = {}

local keymap_header = function(key, purpose)
  return string.format("<%s> to %s", fzf_utils.ansi_codes.yellow(key), fzf_utils.ansi_codes.red(purpose))
end

M.trail_map = function()
  if not trail_marker.trail or #trail_marker.trail.marker_list == 0 then
    print("No trail markers available")
    return
  end

  local function marker_to_string(marker, idx)
    local icon, hl = devicons.get_icon_color(marker.path, nil, {default = true})
    local colored_icon = fzf_utils.ansi_from_rgb(hl, icon)
    local idx_colored = fzf_utils.ansi_codes.magenta(tostring(idx))
    local path = fzf_utils.ansi_codes.blue(vim.fn.fnamemodify(marker.path, ":."))
    local row = fzf_utils.ansi_codes.green(tostring(marker.row))
    local col = fzf_utils.ansi_codes.yellow(tostring(marker.col))
    local content = utils.get_line_contents(marker.path, marker.row)

    local picker_str = string.format("%s %s:%s:%s:%s:%s", colored_icon, idx_colored, path, row, col, content)

    return string.format("%s|%s|%s|%s|%s", idx, marker.path, marker.row, marker.col, picker_str)
  end

  local function marker_from_string(str)
    local idx, path, row, col, picker_str = str:match("([^:]+)|([^:]+)|([^:]+)|([^:]+)|([^:]+)")

    return {
      idx = idx,
      path = path,
      row = row,
      col = col,
      picker_str = picker_str,
    }
  end

  local builtin = require("fzf-lua.previewer.builtin")

  local previewer = builtin.buffer_or_file:extend()

  function previewer:new(o, opts, fzf_win)
    previewer.super.new(self, o, opts, fzf_win)
    setmetatable(self, previewer)
    return self
  end

  function previewer:parse_entry(entry_str)
    local t = marker_from_string(entry_str)
    return {
      idx = tonumber(t.idx),
      path = t.path,
      line = tonumber(t.row),
      col = tonumber(t.col),
    }
  end

  local ctrl_x = keymap_header("ctrl-x", "Remove Marker")
  local ctrl_c = keymap_header("ctrl-c", "Clear Trail")
  local header = string.format(":: %s | %s", ctrl_x, ctrl_c)

  require("fzf-lua").fzf_exec(
    function(cb)
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
          local t = marker_from_string(marker_info)
          utils.switch_or_open(t.path, tonumber(t.row), tonumber(t.col))
          require("trail_marker").trail:goto_marker(tonumber(t.idx))
        end,
        ["ctrl-x"] = function(selected)
          local marker_info = selected[1]
          local t = marker_from_string(marker_info)
          require("trail_marker").trail:remove_marker(tonumber(t.idx))
          require("fzf-lua").resume()
        end,
        ["ctrl-c"] = function(_)
          require("trail_marker").clear_trail()
          require("fzf-lua").resume()
        end,
      },
      fzf_opts = {
        ["--delimiter"] = "|",
        ["--with-nth"] = "5",
        ["--header"] = header,
      },
    }
  )
end

M.change_trail = function()
  -- Header string
  local ctrl_x = keymap_header("ctrl-x", "Remove Trail")
  local new_trail = "Type new trail name to create"
  local header = string.format(":: %s | %s", ctrl_x, new_trail)

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
          local input

          if selected and #selected > 0 then
            -- If something is selected, fetch the trail name
            local trail_name = selected[1]:match("%w+")
            if trail_name then
              trail_marker.change_trail(trail_name)
            else
              vim.notify("Invalid selection!", vim.log.levels.WARN)
            end
          else
            -- No selection (use current query to create a new trail)
            input = require("fzf-lua").get_last_query()
            if input then
              trail_marker.new_trail(input)
            else
              vim.notify("No valid input to create a new trail!", vim.log.levels.WARN)
            end
          end
        end,
        ["ctrl-x"] = function(selected)
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
        width = 0.4,
        height = 0.4,
        col = 0.5,  -- Center horizontally
        row = 0.5,  -- Center vertically
      },
      fzf_opts = {
        ["--header"] = header,
      },
    }
  )
end

return M
