#!/usr/bin/env lua
-- Gnosis polyglot execution harness for Lua.
--
-- Protocol: reads JSON request from stdin, loads the target file,
-- calls the named function, writes JSON response to stdout.
--
-- Requires: lua-cjson or dkjson (falls back to basic parsing).

local ok, cjson = pcall(require, "cjson")
if not ok then
  ok, cjson = pcall(require, "dkjson")
end

-- Minimal JSON encode/decode fallback if no library available.
local json_encode, json_decode
if ok and cjson then
  json_encode = cjson.encode or cjson.new().encode
  json_decode = cjson.decode or cjson.new().decode
else
  -- Minimal JSON encoder for simple values.
  json_encode = function(val)
    if type(val) == "nil" then return "null"
    elseif type(val) == "boolean" then return tostring(val)
    elseif type(val) == "number" then return tostring(val)
    elseif type(val) == "string" then
      return '"' .. val:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n') .. '"'
    elseif type(val) == "table" then
      -- Check if array or object.
      if #val > 0 then
        local items = {}
        for _, v in ipairs(val) do items[#items+1] = json_encode(v) end
        return "[" .. table.concat(items, ",") .. "]"
      else
        local items = {}
        for k, v in pairs(val) do
          items[#items+1] = json_encode(tostring(k)) .. ":" .. json_encode(v)
        end
        return "{" .. table.concat(items, ",") .. "}"
      end
    else
      return '"' .. tostring(val) .. '"'
    end
  end

  -- Minimal JSON string extraction (not a full parser).
  json_decode = function(str)
    -- Use Lua's load for simple cases (security: only for trusted input).
    local fn = load("return " .. str:gsub("%[", "{"):gsub("%]", "}"):gsub('"(%w+)":', '["%1"]='))
    if fn then return fn() end
    return nil
  end
end

local function write_response(resp)
  io.stdout:write(json_encode(resp))
end

-- Read stdin.
local raw_input = io.stdin:read("*a")
if not raw_input or raw_input:match("^%s*$") then
  write_response({ status = "error", value = "empty input", stdout = "", stderr = "" })
  return
end

local request = json_decode(raw_input)
if not request then
  write_response({ status = "error", value = "invalid JSON input", stdout = "", stderr = "" })
  return
end

if request.action == "ping" then
  write_response({ status = "ok", value = "pong", stdout = "", stderr = "" })
  return
end

local file_path = request.filePath or ""
local function_name = request.functionName or "main"
local args = request.args or {}

-- Load and execute.
local load_ok, load_err = pcall(dofile, file_path)
if not load_ok then
  write_response({
    status = "error",
    value = "failed to load " .. file_path .. ": " .. tostring(load_err),
    stdout = "",
    stderr = ""
  })
  return
end

local fn = _G[function_name]
if not fn or type(fn) ~= "function" then
  write_response({
    status = "error",
    value = "function '" .. function_name .. "' not found",
    stdout = "",
    stderr = ""
  })
  return
end

local call_ok, result = pcall(fn, table.unpack(args))
if not call_ok then
  write_response({
    status = "error",
    value = tostring(result),
    stdout = "",
    stderr = ""
  })
  return
end

write_response({
  status = "ok",
  value = result,
  stdout = "",
  stderr = ""
})
