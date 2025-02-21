local M = {}

M.get_bufnr_by_path = function(path)
  -- Get the list of all buffer numbers
  local buffers = vim.api.nvim_list_bufs()

  -- Iterate through each buffer
  for _, buf in ipairs(buffers) do
    -- Check if the buffer has a name and compare it to the file_name
    if vim.api.nvim_buf_is_loaded(buf) then
      -- Get the buffer name (full path)
      local buf_name = vim.api.nvim_buf_get_name(buf)
      if buf_name == path then
        return buf
      end
    end
  end

  -- Return nil if no matching buffer is found
  return nil
end

M.get_line_length = function(path, row_number)
  -- Access the current buffer
  local buf = M.get_bufnr_by_path(path)

  -- Retrieve the specific line's content
  local row_content = vim.api.nvim_buf_get_lines(buf, row_number - 1, row_number, false)[1]

  if row_content then
    return #row_content
  else
    return 0
  end
end

return M
