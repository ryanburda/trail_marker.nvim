--[[

Info functions - provides general trail marker info that can be integrated into various plugins.

Example lualine integration:
```lua
require('lualine').setup {
  sections = {
    lualine_z = { require('trail_marker.extensions.info').info, 'location', 'progress', },
  },
}
```

--]]
local M = {}

M.info = function()
  if vim.g.trail_marker_info then
    return vim.g.trail_marker_info
  else
    return ""
  end
end

return M
