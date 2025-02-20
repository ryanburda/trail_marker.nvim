--[[
Global Variables

Update TrailMarker global variables when certain events fire.
These variables can be used to show TrailMarker information in various locations like the status line or winbar.
--]]
local api = require("trail_marker.api")

vim.api.nvim_create_autocmd('User', {
  pattern = { 'TrailMarkerEventPositionUpdate', 'TrailMarkerEventTrailChanged' },
  callback = function(_)
    if api.trail ~= nil then
      vim.g.trail_marker_position = api.get_current_position()
    else
      vim.g.trail_marker_position = nil
    end
  end
})

vim.api.nvim_create_autocmd('User', {
  pattern = { 'TrailMarkerEventTrailChanged', },
  callback = function(_)
    if api.trail ~= nil then
      vim.g.trail_marker_name = api.get_current_trail()
    else
      vim.g.trail_marker_name = nil
    end
  end
})

vim.api.nvim_create_autocmd('User', {
  pattern = { 'TrailMarkerEvent*', },
  callback = function(_)
    -- Create a TrailMarker info string.
    if api.trail ~= nil then
      local name = api.get_current_trail()
      local pos = api.get_current_position()
      local pos_str = tostring(pos)

      if pos == 0 then
        pos_str = "*"
      elseif pos == 1 then
        pos_str = "HEAD"
      elseif pos == #api.trail.marker_list and pos ~= 1 then
        pos_str = "END"
      end

      vim.g.trail_marker_info = string.format("%s:%s", name, pos_str)
    else
      vim.g.trail_marker_info = nil
    end
  end
})
