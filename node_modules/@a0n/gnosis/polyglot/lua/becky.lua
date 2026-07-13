#!/usr/bin/env lua
--- becky.lua -- GG compiler in Lua.
---
--- Lua tables are hash maps. That's the whole standard library.
--- The question: can the simplest language beat the complex ones?
---
--- Usage:
---   lua becky.lua betti.gg
---   lua becky.lua --beta1 betti.gg
---   lua becky.lua --summary betti.gg
---   lua becky.lua --bench 100000 betti.gg

local function strip_comments(source)
    local lines = {}
    for line in source:gmatch("[^\n]+") do
        local idx = line:find("//")
        if idx then line = line:sub(1, idx - 1) end
        line = line:match("^%s*(.-)%s*$")
        if #line > 0 then lines[#lines + 1] = line end
    end
    return table.concat(lines, "\n")
end

local function parse_properties(raw)
    local props = {}
    if not raw or #raw == 0 then return props end
    for segment in raw:gmatch("[^,]+") do
        local key, value = segment:match("^%s*(%w+)%s*:%s*(.-)%s*$")
        if key and value then
            value = value:gsub("^['\"]", ""):gsub("['\"]$", "")
            if #key > 0 and #value > 0 then props[key] = value end
        end
    end
    return props
end

local function split_pipe(raw)
    local ids = {}
    for part in raw:gmatch("[^|]+") do
        part = part:match("^%s*(.-)%s*$")
        part = part:gsub("^%(", ""):gsub("%)$", "")
        -- Take ID before : or {
        local colon = part:find(":")
        if colon then part = part:sub(1, colon - 1) end
        local brace = part:find("{")
        if brace then part = part:sub(1, brace - 1) end
        part = part:match("^%s*(.-)%s*$")
        if #part > 0 then ids[#ids + 1] = part end
    end
    return ids
end

local edge_pattern = "%(([^)]+)%)%s*%-[[]%:([A-Z]+)[^]]*]%->%s*%(([^)]+)%)"

local function parse_gg(source)
    local cleaned = strip_comments(source)
    local nodes = {}
    local edges = {}

    -- Sweep 1: edges
    for source_raw, edge_type, target_raw in cleaned:gmatch(edge_pattern) do
        local source_ids = split_pipe(source_raw)
        local target_ids = split_pipe(target_raw)

        edges[#edges + 1] = {
            sourceIds = source_ids,
            targetIds = target_ids,
            type = edge_type,
        }

        for _, id in ipairs(source_ids) do
            if not nodes[id] then nodes[id] = { id = id, labels = {}, properties = {} } end
        end
        for _, id in ipairs(target_ids) do
            if not nodes[id] then nodes[id] = { id = id, labels = {}, properties = {} } end
        end
    end

    -- Sweep 2: standalone nodes
    for line in cleaned:gmatch("[^\n]+") do
        if line:find("%-[%[]:") then goto continue end
        for id, label, props_raw in line:gmatch("%(([^:%)%s|]+)%s*:%s*([^)}{%s]+)%s*{?([^}]*)}?%)") do
            id = id:match("^%s*(.-)%s*$")
            if #id > 0 and not id:find("|") then
                if not nodes[id] then
                    local labels = {}
                    if label and #label > 0 then labels[1] = label end
                    nodes[id] = { id = id, labels = labels, properties = parse_properties(props_raw or "") }
                end
            end
        end
        -- Also match bare nodes: (id)
        for id in line:gmatch("%(([^:%)%s|{]+)%)") do
            id = id:match("^%s*(.-)%s*$")
            if #id > 0 and not nodes[id] then
                nodes[id] = { id = id, labels = {}, properties = {} }
            end
        end
        ::continue::
    end

    return { nodes = nodes, edges = edges }
end

local function compute_beta1(prog)
    local b1 = 0
    for _, edge in ipairs(prog.edges) do
        local sources = #edge.sourceIds
        local targets = #edge.targetIds
        local t = edge.type
        if t == "FORK" then
            b1 = b1 + targets - 1
        elseif t == "FOLD" or t == "COLLAPSE" or t == "OBSERVE" then
            b1 = math.max(0, b1 - (sources - 1))
        elseif t == "RACE" or t == "SLIVER" then
            b1 = math.max(0, b1 - math.max(0, sources - targets))
        elseif t == "VENT" then
            b1 = math.max(0, b1 - 1)
        end
    end
    return b1
end

local function count_nodes(nodes)
    local n = 0
    for _ in pairs(nodes) do n = n + 1 end
    return n
end

local function compile_gg(source)
    local prog = parse_gg(source)
    local b1 = compute_beta1(prog)
    local void_dims = 0
    local heat = 0.0
    for _, e in ipairs(prog.edges) do
        if e.type == "FORK" then void_dims = void_dims + #e.targetIds end
        if (e.type == "FOLD" or e.type == "COLLAPSE" or e.type == "OBSERVE") and #e.sourceIds > 1 then
            heat = heat + math.log(#e.sourceIds) / math.log(2)
        end
    end
    return {
        program = prog,
        beta1 = b1,
        void_dimensions = void_dims,
        landauer_heat = heat,
    }
end

-- CLI
local args = {...} or arg
local filepath, beta1_only, summary, bench_iters = nil, false, false, 0

local i = 1
while i <= #arg do
    if arg[i] == "--beta1" then beta1_only = true
    elseif arg[i] == "--summary" then summary = true
    elseif arg[i] == "--bench" then i = i + 1; bench_iters = tonumber(arg[i]) or 0
    else filepath = arg[i]
    end
    i = i + 1
end

if not filepath then
    io.stderr:write("usage: becky.lua [--beta1|--summary|--bench N] <file.gg>\n")
    os.exit(1)
end

local f = io.open(filepath, "r")
if not f then io.stderr:write("becky.lua: cannot read " .. filepath .. "\n"); os.exit(1) end
local source = f:read("*a")
f:close()

if bench_iters > 0 then
    -- Warmup
    for _ = 1, 10 do compile_gg(source) end
    local clock = os.clock
    local start = clock()
    for _ = 1, bench_iters do compile_gg(source) end
    local elapsed = clock() - start
    local us_per_iter = elapsed * 1e6 / bench_iters

    local r = compile_gg(source)
    local nc = count_nodes(r.program.nodes)
    local ec = #r.program.edges
    print(string.format("%.1fus/iter | %d iterations | %d nodes %d edges | b1=%d | void=%d heat=%.3f",
        us_per_iter, bench_iters, nc, ec, r.beta1, r.void_dimensions, r.landauer_heat))
    return
end

local r = compile_gg(source)
local nc = count_nodes(r.program.nodes)
local ec = #r.program.edges

if beta1_only then
    print(r.beta1)
elseif summary then
    print(string.format("%s: %d nodes, %d edges, b1=%d, void=%d, heat=%.3f",
        filepath, nc, ec, r.beta1, r.void_dimensions, r.landauer_heat))
else
    print(string.format('{"nodes":%d,"edges":%d,"beta1":%d,"void_dimensions":%d,"landauer_heat":%.3f}',
        nc, ec, r.beta1, r.void_dimensions, r.landauer_heat))
end
