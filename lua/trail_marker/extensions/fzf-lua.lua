--[[

fzf-lua integration

NOTES:
  - This should only be used if you have fzf-lua installed.
  - This should only be used after Trail Marker has been set up.

```lua
vim.keymap.set(
  'n',
  '<leader>tc',
  require("trail_marker").fzf_lua_change_trail,
  { desc = "TrailMarker: Change trails with fzf-lua" }
)

vim.keymap.set(
  'n',
  '<leader>tm',
  require("trail_marker").fzf_lua_trail_map,
  { desc = "Trail Marker: List markers on current trail with fzf-lua" }
)
```

--]]
local trail_marker = require("trail_marker")
local utils = require("trail_marker.utils")

local M = {}

M.trail_map = function()
  -- TODO: add content of line so that it can be searched. (similar being done in telescope integration)
  if trail_marker.trail == nil or #trail_marker.trail.marker_list == 0 then
    print("No trail markers available")
    return
  end

  local entries = {}
  for _, marker in ipairs(trail_marker.trail.marker_list) do
    --local path = vim.fn.fnamemodify(marker.path, ':.')
    table.insert(entries, string.format("%s:%s:%s", marker.path, marker.row, marker.col))
  end

  require("fzf-lua").fzf_exec(entries, {
    prompt = "Trail Markers> ",
    previewer = "builtin",
    actions = {
      ["default"] = function(selected)
        -- TODO: update trail position on selection.
        --       might need to add position numbers to the picker.
        local marker_info = selected[1]
        local path, row, col = marker_info:match("([^:]+):([^:]+):([^:]+)")
        utils.switch_or_open(path, tonumber(row), tonumber(col))
      end,
      ["ctrl-d"] = function(selected)
        -- TODO: implement logic to remove the marker
        print("Delete marker:", selected[1])
      end,
    },
  })
end

M.change_trail = function()
  require("fzf-lua").files({
    cwd=require("trail_marker.serde").get_current_project_dir(),
    prompt="Trails",
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
      ["ctrl-d"] = {
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
  })
end

return M
