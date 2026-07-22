local GnosisClient = {}
GnosisClient.__index = GnosisClient

local function shell_quote(value)
  local escaped = tostring(value):gsub("'", "'\\''")
  return "'" .. escaped .. "'"
end

function GnosisClient.new(binary)
  local resolved = binary
  if resolved == nil or resolved == "" then
    resolved = "gnosis"
  end
  return setmetatable({ binary = resolved }, GnosisClient)
end

function GnosisClient:run(args)
  local parts = { shell_quote(self.binary) }
  for _, arg in ipairs(args) do
    parts[#parts + 1] = shell_quote(arg)
  end

  local command = table.concat(parts, " ") .. " 2>&1"
  local handle = assert(io.popen(command, "r"))
  local output = handle:read("*a")
  local ok, _, status_code = handle:close()

  local exit_code = 0
  if not ok then
    exit_code = tonumber(status_code) or 1
  end

  return {
    exit_code = exit_code,
    stdout = output,
    stderr = "",
  }
end

function GnosisClient:lint(topology_path, target, as_json)
  local args = { "lint", topology_path }
  if target and target ~= "" then
    args[#args + 1] = "--target"
    args[#args + 1] = target
  end
  if as_json then
    args[#args + 1] = "--json"
  end
  return self:run(args)
end

function GnosisClient:analyze(target_path, as_json)
  local args = { "analyze", target_path }
  if as_json then
    args[#args + 1] = "--json"
  end
  return self:run(args)
end

function GnosisClient:verify(topology_path, tla_out)
  local args = { "verify", topology_path }
  if tla_out and tla_out ~= "" then
    args[#args + 1] = "--tla-out"
    args[#args + 1] = tla_out
  end
  return self:run(args)
end

function GnosisClient:run_topology(topology_path, native)
  local args = { "run", topology_path }
  if native then
    args[#args + 1] = "--native"
  end
  return self:run(args)
end

function GnosisClient:test_topology(test_path)
  return self:run({ "test", test_path })
end

return GnosisClient
