-- This is the api of the plugin.
local trail = require("trail_marker.trail")
local serde = require("trail_marker.serde")
local utils = require("trail_marker.utils")

local function warning(msg)
  vim.api.nvim_echo({ { msg, 'WarningMsg' } }, false, {})
end

local function no_current_trail_warning()
  warning("TrailMarker: No current trail. Use `:TrailMarker change_trail <trail_name>` or `:TrailMarker new_trail <trail_name>`")
end

local function no_markers_on_trail_warning()
  warning("TrailMarker: No markers on trail.")
end

local M = {}

M.place_marker = function()
  if M.trail ~= nil then
    M.trail:place_marker()
  else
    no_current_trail_warning()
  end
end

M.remove_marker = function()
  if M.trail ~= nil then
    M.trail:remove_marker_at_location()
  else
    no_current_trail_warning()
  end
end

M.current_marker = function()
  if M.trail ~= nil then
    if #M.trail.marker_list == 0 then
      no_markers_on_trail_warning()
    else
      M.trail:current_marker()
    end
  else
    no_current_trail_warning()
  end
end

M.next_marker = function()
  if M.trail ~= nil then
    if #M.trail.marker_list == 0 then
      no_markers_on_trail_warning()
    elseif M.trail.trail_pos == #M.trail.marker_list then
      warning("TrailMarker: no next marker")
    else
      M.trail:next_marker()
    end
  else
    no_current_trail_warning()
  end
end

M.prev_marker = function()
  if M.trail ~= nil then
    if #M.trail.marker_list == 0 then
      no_markers_on_trail_warning()
    elseif M.trail.trail_pos == 1 then
      warning("TrailMarker: no previous marker")
    else
      M.trail:prev_marker()
    end
  else
    no_current_trail_warning()
  end
end

M.trail_head = function()
  if M.trail ~= nil then
    if #M.trail.marker_list == 0 then
      no_markers_on_trail_warning()
    else
      M.trail:trail_head()
    end
  else
    no_current_trail_warning()
  end
end

M.trail_end = function()
  if M.trail ~= nil then
    if #M.trail.marker_list == 0 then
      no_markers_on_trail_warning()
    else
      M.trail:trail_end()
    end
  else
    no_current_trail_warning()
  end
end

M.clear_trail = function()
  if M.trail ~= nil then
    M.trail:clear_trail()
  else
    no_current_trail_warning()
  end
end

M.virtual_text_on = function()
  if M.trail ~= nil then
    M.trail:virtual_text_on()
  else
    no_current_trail_warning()
  end
end

M.virtual_text_off = function()
  if M.trail ~= nil then
    M.trail:virtual_text_off()
  else
    no_current_trail_warning()
  end
end

M.virtual_text_toggle = function()
  if M.trail ~= nil then
    M.trail:virtual_text_toggle()
  else
    no_current_trail_warning()
  end
end

M.new_trail = function(trail_name)
  local trail_file = string.format("%s/%s", serde.get_current_project_dir(), trail_name)
  local file, _ = io.open(trail_file, "r")

  if file then
    warning(string.format("TrailMarker: trail `%s` already exists. Use `:TrailMarker change_trail %s` to switch.", trail_name, trail_name))
  else
    M.trail = trail.new(trail_name)
    vim.api.nvim_exec_autocmds('User', { pattern = 'TrailMarkerEventTrailChanged' })
  end
end

M.change_trail = function(trail_name)
  local trail_file = string.format("%s/%s", serde.get_current_project_dir(), trail_name)
  local file, _ = io.open(trail_file, "r")

  if file then
    local content = file:read("*a")
    file:close()

    local deserialized_trail = serde.deserialize(content)
    M.trail = trail.from_table(deserialized_trail)
    vim.api.nvim_exec_autocmds('User', { pattern = 'TrailMarkerEventTrailChanged' })
  else
    warning(string.format("TrailMarker: trail `%s` does not exist.", trail_name))
  end
end

M.remove_trail = function(trail_name)
  local trail_file = string.format("%s/%s", serde.get_current_project_dir(), trail_name)
  local file, _ = io.open(trail_file, "r")

  if file then
    -- If the trail being removed is the current trail.
    if M.trail ~= nil and trail_name == M.trail.name then
      -- Clear the trail first so the virtual text goes away.
      M.trail:clear_trail()
      -- Set the trail to nil so it can't be modified by other functions unintentionally.
      M.trail = nil
      vim.api.nvim_exec_autocmds('User', { pattern = 'TrailMarkerEventTrailChanged' })
    end

    -- Remove the trail file
    os.execute(string.format("rm %s", trail_file))
  else
    warning(string.format("TrailMarker: trail `%s` does not exist.", trail_name))
  end
end

M.get_current_trail = function()
  if M.trail ~= nil then
    return M.trail.name
  end
end

M.get_current_position = function()
  if M.trail ~= nil then
    return M.trail.trail_pos
  end
end

M.leave_trail = function()
  M.trail = nil
  vim.api.nvim_exec_autocmds('User', { pattern = 'TrailMarkerEventTrailChanged' })
end

--[[
Global Variables

Update TrailMarker global variables when certain events fire.
These variables can be used to show TrailMarker information
in various locations like the status line or winbar.
--]]
vim.api.nvim_create_autocmd('User', {
  pattern = { 'TrailMarkerEventPositionUpdate', 'TrailMarkerEventTrailChanged' },
  callback = function(_)
    if M.trail ~= nil then
      vim.g.trail_marker_position = M.get_current_position()
    else
      vim.g.trail_marker_position = nil
    end
  end
})

vim.api.nvim_create_autocmd('User', {
  pattern = { 'TrailMarkerEventTrailChanged', },
  callback = function(_)
    if M.trail ~= nil then
      vim.g.trail_marker_name = M.get_current_trail()
    else
      vim.g.trail_marker_name = nil
    end
  end
})

vim.api.nvim_create_autocmd('User', {
  pattern = { 'TrailMarkerEvent*', },
  callback = function(_)
    -- Create a TrailMarker info string.
    if M.trail ~= nil then
      local name = M.get_current_trail()
      local pos = M.get_current_position()
      local pos_str = tostring(pos)

      if pos == 0 then
        pos_str = "*"
      elseif pos == 1 then
        pos_str = "HEAD"
      elseif pos == #M.trail.marker_list and pos ~= 1 then
        pos_str = "END"
      end

      vim.g.trail_marker_info = string.format("%s:%s", name, pos_str)
    else
      vim.g.trail_marker_info = nil
    end
  end
})

--[[

Telescope integration

TODO: clean this up so it is handled more like fzf-lua

--]]
local has_telescope, telescope = pcall(require, "telescope")

if has_telescope then
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local sorters = require("telescope.sorters")
  local previewers = require("telescope.previewers")
  local action_state = require("telescope.actions.state")

  local get_line_contents = function(path, row)
    -- TODO: See if there is a better way to do this.
    -- Read the contents of the specific line from the file
    local line_content = ""
    if path and row then
      local file = io.open(path, "r")
      if file then
        for _ = 1, row do
          line_content = file:read("*l")
          if not line_content then break end
        end
        file:close()
      end
    end

    return line_content
  end

  local generate_new_finder = function()
    return finders.new_table {
      results = M.trail.marker_list,
      entry_maker = function(marker)
        local line_content = get_line_contents(marker.path, marker.row)
        local relative_path = vim.fn.fnamemodify(marker.path, ':.')

        local str = string.format("%s:%s:%s:%s", relative_path, marker.row, marker.col, line_content)

        return {
          value = marker,
          display = str,
          ordinal = str,
          path = marker.path,
          lnum = marker.row,
          col = marker.col,
        }
      end
    }
  end

  local telescope_delete_mark = function(prompt_bufnr)
    local selection = action_state.get_selected_entry()
    M.trail:remove_marker(selection.index)

    local current_picker = action_state.get_current_picker(prompt_bufnr)
    current_picker:refresh(generate_new_finder(), { reset_prompt = true })
  end

  M.telescope_trail_map = function()
    if M.trail == nil then
      no_current_trail_warning()
      return
    elseif #M.trail.marker_list == 0 then
      no_markers_on_trail_warning()
      return
    end

    pickers.new({}, {
      prompt_title = string.format("Trail Markers - %s", M.trail.name),
      finder = generate_new_finder(),
      sorter = sorters.get_fzy_sorter(),
      previewer = previewers.vim_buffer_vimgrep.new({}),
      attach_mappings = function(_, map)
        map("i", "<c-d>", telescope_delete_mark)
        map("n", "<c-d>", telescope_delete_mark)
        return true
      end,
    }):find()
  end

  telescope.register_extension {
    exports = {
      list_trail_markers = M.list_trail_markers
    }
  }
end

--[[

fzf-lua integration

--]]
M.fzf_lua_trail_map = function()
  -- TODO: add content of line so that it can be searched. (similar being done in telescope integration)
  local has_fzf_lua, fzf_lua = pcall(require, "fzf-lua")

  if has_fzf_lua then
    if M.trail == nil or #M.trail.marker_list == 0 then
      print("No trail markers available")
      return
    end

    local entries = {}
    for _, marker in ipairs(M.trail.marker_list) do
      --local path = vim.fn.fnamemodify(marker.path, ':.')
      table.insert(entries, string.format("%s:%s:%s", marker.path, marker.row, marker.col))
    end

    fzf_lua.fzf_exec(entries, {
      prompt = "Trail Markers> ",
      previewer = "builtin",
      actions = {
        ["default"] = function(selected)
          -- You can define what happens on default action
          local marker_info = selected[1]
          local path, row, col = marker_info:match("([^:]+):([^:]+):([^:]+)")
          utils.switch_or_open(path, tonumber(row), tonumber(col))
        end,
        ["ctrl-d"] = function(selected)
          -- TODO: fix deleting marker from fzf-lua
          -- Action for deleting the marker will be defined here
          -- For example: remove the selected marker from the list
          print("Delete marker:", selected[1])
          -- implement your logic to remove the marker
        end,
      },
    })
  end
end

M.fzf_lua_change_trail = function()
  local has_fzf_lua, fzf_lua = pcall(require, "fzf-lua")

  if has_fzf_lua then
    fzf_lua.files({
      cwd=require("trail_marker.serde").get_current_project_dir(),
      prompt="Trails",
      previewer = false,
      actions = {
        ["default"] = function(selected)
          local trail_name = selected[1]:match("%w+")
          if trail_name then
            M.change_trail(trail_name)
          else
            vim.notify("No trail selected!", vim.log.levels.WARN)
          end
        end,
        ["ctrl-d"] = function(selected)
          -- TODO: don't quit after deleting trail.
          local trail_name = selected[1]:match("%w+")
          if trail_name then
            M.remove_trail(trail_name)
          else
            vim.notify("No trail selected!", vim.log.levels.WARN)
          end
        end,
      },
    })
  end
end

--[[
User Commands

Provide a convenient way to interface with TrailMarker using Ex commands.

```
:TrailMarker <command> <optional-args>
```
--]]
local function_map = {
  get_current_trail = function() print(M.get_current_trail()) end,
  get_current_position = function() print(M.get_current_position()) end,
  new_trail = M.new_trail,
  change_trail = M.change_trail,
  remove_trail = M.remove_trail,
  leave_trail = M.leave_trail,
  place_marker = M.place_marker,
  remove_marker = M.remove_marker,
  current_marker = M.current_marker,
  next_marker = M.next_marker,
  prev_marker = M.prev_marker,
  trail_head = M.trail_head,
  trail_end = M.trail_end,
  clear_trail = M.clear_trail,
  virtual_text_toggle = M.virtual_text_toggle,
  telescope_trail_map = M.telescope_trail_map,
  fzf_lua_trail_map = M.fzf_lua_trail_map,
  fzf_lua_change_trail = M.fzf_lua_change_trail,
}

local function get_project_trail_names()
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
    warning("Invalid function name: " .. function_name)
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
      return get_project_trail_names()
    end

    return {}
  end
})

return M
