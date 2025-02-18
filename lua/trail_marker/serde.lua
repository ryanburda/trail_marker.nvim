-- Serialize/Deserialize data for persistant storage of plugin data.
local M = {}

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
