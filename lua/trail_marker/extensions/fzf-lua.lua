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
local devicons = require("nvim-web-devicons")  -- TODO: make this an optional dependency.

local M = {}

local keymap_header = function(key, purpose)
  return string.format("<%s> to %s", fzf_utils.ansi_codes.yellow(key), fzf_utils.ansi_codes.red(purpose))
end

M.trail_map = function()
  if not trail_marker.trail then
    utils.no_current_trail_warning()
    return
  end

  local function marker_to_string(marker, idx)
    -- Format the string that will be displayed in fzf using `--with-nth`.
    local icon, hl = devicons.get_icon_color(marker.path, nil, {default = true})
    local colored_icon = fzf_utils.ansi_from_rgb(hl, icon)
    local idx_colored = fzf_utils.ansi_codes.magenta(tostring(idx))
    local path = fzf_utils.ansi_codes.blue(vim.fn.fnamemodify(marker.path, ":."))
    local row = fzf_utils.ansi_codes.green(tostring(marker.row))
    local col = fzf_utils.ansi_codes.yellow(tostring(marker.col))
    local content = utils.get_line_contents(marker.path, marker.row)

    local picker_str = string.format("%s %s:%s:%s:%s:%s", colored_icon, idx_colored, path, row, col, content)

    -- The `picker_str` is only one piece that will be passed to fzf.
    -- We also need the information needed to reconstruct a marker
    -- without complicating it with all of the formatting above.
    --
    -- `picker_str` must go last since the line `content` within it may contain the pipe delimiter.
    -- Having delimiters where we don't expect them would cause issues in `marker_from_string`.
    --
    -- Update fzf_opts `--with-nth` below if the position of the `picker_str` changes.
    -- Update the `marker_from_string` function if values are added, removed, or reordered.
    return string.format("%s|%s|%s|%s|%s", idx, marker.path, marker.row, marker.col, picker_str)
  end

  local function marker_from_string(str)
    -- Deserialize the string created in `marker_to_string` above and return it as a table.
    if str then
      local idx, path, row, col, picker_str = str:match("([^:]+)|([^:]+)|([^:]+)|([^:]+)|([^:]+)")

      return {
        idx = idx,
        path = path,
        row = row,
        col = col,
        picker_str = picker_str,
      }
    end
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
  local ctrl_l = keymap_header("ctrl-l", "Leave Trail")
  local header = string.format(":: %s | %s | %s", ctrl_x, ctrl_c, ctrl_l)

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
          if selected[1] == nil then
            return
          end

          local marker_info = selected[1]
          if marker_info then
            local t = marker_from_string(marker_info)
            require("trail_marker").trail:goto_marker(tonumber(t.idx))
          end
        end,
        ["ctrl-x"] = function(selected)
          if selected[1] ~= nil then
            local marker_info = selected[1]
            local t = marker_from_string(marker_info)
            require("trail_marker").trail:remove_marker(tonumber(t.idx))
          end
          require("fzf-lua").resume()
        end,
        ["ctrl-c"] = function(_)
          require("trail_marker").clear_trail()
          require("fzf-lua").resume()
        end,
        ["ctrl-l"] = function(_)
          require("trail_marker").leave_trail()
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
  local ctrl_l = keymap_header("ctrl-l", "Leave Trail")
  local new_trail = "Type new trail name to create"
  local header = string.format(":: %s\n%s | %s", new_trail, ctrl_x, ctrl_l)

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
            local trail_name = selected[1]
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
          if selected[1] ~= nil then
            local trail_name = selected[1]
            if trail_name then
              trail_marker.remove_trail(trail_name)
            end
          end
          require("fzf-lua").resume()
        end,
        ["ctrl-l"] = function(_)
          require("trail_marker").leave_trail()
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
