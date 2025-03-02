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

M.warning = function(msg)
  vim.api.nvim_echo({ { msg, 'WarningMsg' } }, false, {})
end

M.no_current_trail_warning = function()
  M.warning("No current trail. Use `:TrailMarker change_trail <trail_name>` or `:TrailMarker new_trail <trail_name>`")
end

M.no_markers_on_trail_warning = function(trail_name)
  M.warning(string.format("No markers on trail %s", trail_name))
end

--[[

Saving data

--]]
M.data_dir_path = vim.fn.stdpath("data") .. "/trail_marker"
M.trail_dir_path = M.data_dir_path .. "/trails"

M.get_hash = function(str)
  -- useful for hashing directory paths.
  return vim.fn.sha256(str)
end

M.get_dir_name = function(filePath)
  return filePath:match("(.*/)")
end

M.get_current_project_dir = function()
  return string.format("%s/%s", M.trail_dir_path, M.get_hash(vim.fn.getcwd()))
end

M.create_dir = function(dir_path)
  os.execute("mkdir -p " .. dir_path)
end

M.write_to_file = function(o, path)
  M.create_dir(M.get_dir_name(path))

  local file, err = io.open(path, "w")
  if file then
    file:write(o)
    file:close()
  else
    print("Error: trail_marker - opening file:", err)
  end
end

M.serialize = function(t)
  local function serializeHelper(tbl, result, indent)
    indent = indent or ""
    result = result or {}
    table.insert(result, "{\n")

    for k, v in pairs(tbl) do
      local key, value
      local newIndent = indent .. "  "

      -- Serialize the key
      if type(k) == "string" then
        key = string.format("%q", k)
      else
        key = k
      end

      -- Serialize the value
      if type(v) == "table" then
        table.insert(result, newIndent .. "[" .. key .. "] = ")
        serializeHelper(v, result, newIndent)
      elseif type(v) == "string" then
        value = string.format("%q", v)
        table.insert(result, newIndent .. "[" .. key .. "] = " .. value)
      else
        value = tostring(v)
        table.insert(result, newIndent .. "[" .. key .. "] = " .. value)
      end

      table.insert(result, ",\n")
    end

    table.insert(result, indent .. "}")
  end

  local result = {}
  serializeHelper(t, result)
  return table.concat(result)
end

M.deserialize = function(serialized_tbl)
  -- TODO: deserialize without using `load`.
  local func, err = load("return " .. serialized_tbl)
  if not func then
    error("Failed to deserialize: " .. err)
  end
  return func()
end

return M
