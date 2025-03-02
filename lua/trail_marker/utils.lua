local M = {}

---Get the buffer number from a file path.
---@param path string: The full path of the file.
---@return number|nil: The buffer number or nil if not found.
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

---Get the length of a specific line in a file.
---@param path string: The full path of the file.
---@param row_number number: The line number (1-based).
---@return number|nil: The length of the line or nil if line doesn't exist.
M.get_line_length = function(path, row_number)
  local bufnr = M.get_bufnr_by_path(path)

  if bufnr ~= nil then
    local row_content = vim.api.nvim_buf_get_lines(bufnr, row_number - 1, row_number, false)[1]

    if row_content ~= nil then
      return #row_content
    end
  end

  -- Return nil if line not found
  return nil
end

---Get the contents of a specific line from a file.
---@param path string: The full path of the file.
---@param row number: The line number (1-based).
---@return string: The content of the line or an empty string if not found.
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

---Display a warning message.
---@param msg string: The warning message to display.
M.warning = function(msg)
  vim.api.nvim_echo({ { msg, 'WarningMsg' } }, false, {})
end

---Display a warning when there is no current trail.
M.no_current_trail_warning = function()
  M.warning("No current trail. Use `:TrailMarker change_trail <trail_name>` or `:TrailMarker new_trail <trail_name>`")
end

---Display a warning for no markers on a given trail.
---@param trail_name string: The name of the trail.
M.no_markers_on_trail_warning = function(trail_name)
  M.warning(string.format("No markers on trail %s", trail_name))
end

--[[

Saving data

--]]

M.data_dir_path = vim.fn.stdpath("data") .. "/trail_marker"
M.trail_dir_path = M.data_dir_path .. "/trails"

---Get a hash for a given string.
---@param str string: The string to hash.
---@return string: The SHA256 hash of the string.
M.get_hash = function(str)
  return vim.fn.sha256(str)
end

---Get the directory name from a file path.
---@param filePath string: The full path of the file.
---@return string|nil: The directory path or nil if not found.
M.get_dir_name = function(filePath)
  return filePath:match("(.*/)")
end

---Get the current project directory path.
---@return string: The path to the current project's trail directory.
M.get_current_project_dir = function()
  return string.format("%s/%s", M.trail_dir_path, M.get_hash(vim.fn.getcwd()))
end

---Create a directory at the specified path.
---@param dir_path string: The path of the directory to create.
M.create_dir = function(dir_path)
  os.execute("mkdir -p " .. dir_path)
end

---Write data to a file.
---@param o string: The data to write.
---@param path string: The file path to write the data to.
M.write_to_file = function(o, path)
  -- Create the directory the file exists in if necessary.
  local dir = M.get_dir_name(path)
  if dir then
    M.create_dir(dir)
  end

  local file, err = io.open(path, "w")
  if file then
    file:write(o)
    file:close()
  else
    print("Error: trail_marker - opening file:", err)
  end
end

---Serialize a table into a string representation.
---@param t table: The table to serialize.
--- @return string: The serialized table as a string.
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

---Deserialize a string representation into a table.
---@param serialized_tbl string: The serialized table string.
---@return table: The deserialized table.
M.deserialize = function(serialized_tbl)
  -- TODO: deserialize without using `load`.
  local func, err = load("return " .. serialized_tbl)
  if not func then
    error("Failed to deserialize: " .. err)
  end
  return func()
end

return M
