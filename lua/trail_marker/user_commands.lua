--[[
User Commands

Provide a convenient way to interface with TrailMarker with user commands.

```
:TrailMarker <command> <optional-args>
```
--]]
local api = require("trail_marker.api")
local utils = require("trail_marker.utils")
local serde = require("trail_marker.serde")

--[[
The table below shows how user commands on the left map to lua commands on the right.

For example:
```
:TrailMarker trail_map
```
calls
```lua
require("trail_marker.api").trail_map()
--]]
local function_map = {
  trail_map = api.trail_map,
  get_current_trail = function() print(api.get_current_trail()) end,
  get_current_position = function() print(api.get_current_position()) end,
  new_trail = api.new_trail,
  change_trail = api.change_trail,
  remove_trail = api.remove_trail,
  leave_trail = api.leave_trail,
  place_marker = api.place_marker,
  remove_marker = api.remove_marker,
  current_marker = api.current_marker,
  next_marker = api.next_marker,
  prev_marker = api.prev_marker,
  trail_head = api.trail_head,
  trail_end = api.trail_end,
  clear_trail = api.clear_trail,
  virtual_text_toggle = api.virtual_text_toggle,
}

local function complete_trail_names()
  local dir_path = serde.get_current_project_dir()
  local trails = {}

  if vim.fn.isdirectory(dir_path) == 1 then
    local handle = io.popen('ls ' .. dir_path)
    if handle then
      for filename in handle:lines() do
        table.insert(trails, filename)
      end
      handle:close()
    end
  end

  return trails
end

vim.api.nvim_create_user_command('TrailMarker', function(opts)
  local function_name = opts.fargs[1]
  local additional_arg = opts.fargs[2]

  local func = function_map[function_name]

  if func then
    if additional_arg == nil then
      func()
    else
      func(additional_arg)
    end
  else
    utils.warning("Invalid function name: " .. function_name)
  end
end, {
  nargs = '*',
  complete = function(_, cmd_line, _)
    local args = vim.split(cmd_line, '%s+')

    if #args == 2 then
      -- Second argument involves typing the function name
      return vim.tbl_keys(function_map)

    elseif #args == 3 and vim.tbl_contains({"change_trail", "remove_trail"}, args[2]) then
      -- Third argument requires trail name completion
      return complete_trail_names()
    end

    return {}
  end
})
