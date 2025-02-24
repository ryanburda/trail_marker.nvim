--[[

Telescope integration

NOTES:
  - This should only be used if telescope is installed.
  - This should only be used after Trail Marker has been set up.

TODO: clean this up so it is handled more like fzf-lua

--]]
local M = {}

local telescope = require("telescope")
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

M.trail_map = function()
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

return M
