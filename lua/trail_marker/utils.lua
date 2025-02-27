local M = {}

M.get_location = function()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local path = vim.api.nvim_buf_get_name(0)

  return row, col, path
end

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
  local length = 0

  -- Access the current buffer
  local bufnr = M.get_bufnr_by_path(path)

  if bufnr ~= nil then
    -- Retrieve the specific line's content
    local row_content = vim.api.nvim_buf_get_lines(bufnr, row_number - 1, row_number, false)[1]

    if row_content ~= nil then
      length = #row_content
    end
  end

  return length
end

M.get_line_contents = function(path, row)
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

M.switch_or_open = function(path, row, col)
  local bufnr = M.get_bufnr_by_path(path)

  if bufnr then
    -- If the buffer exists, switch to it
    vim.api.nvim_set_current_buf(bufnr)
  else
    -- Otherwise, open the file in a new buffer
    vim.cmd('edit ' .. vim.fn.fnameescape(path))
  end

  -- Handle the case where the content of the line has changed.
  -- Go to the end of the row if the column number exceeds the length of the row.
  local line_length = M.get_line_length(path, row)
  local col_adjusted = math.max(0, math.min(col, line_length))

  -- set the cursor to the specified line and column
  vim.api.nvim_win_set_cursor(0, {row, col_adjusted})
end

M.warning = function(msg)
  vim.api.nvim_echo({ { msg, 'WarningMsg' } }, false, {})
end

M.no_current_trail_warning = function()
  M.warning("TrailMarker: No current trail. Use `:TrailMarker change_trail <trail_name>` or `:TrailMarker new_trail <trail_name>`")
end

M.no_markers_on_trail_warning = function()
  M.warning("TrailMarker: No markers on trail.")
end

return M
