local M = {}

M.warning = function(msg)
  vim.api.nvim_echo({ { msg, 'WarningMsg' } }, false, {})
end

return M
