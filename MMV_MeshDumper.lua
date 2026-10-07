-- Noir MMV Smart Dump
-- Run in MMV. Does NOT click hats. Hunts the weapon dictionary in memory.
-- Writes: mmv_meshes.lua  +  mmv_debug.txt

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local function notify(t)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Noir Smart Dump", Text = tostring(t), Duration = 7,
        })
    end)
    print("[Noir Smart]", t)
end

local function raw(t, k)
    local ok, v = pcall(rawget, t, k)
    return ok and v or nil
end

local WEAPON_KEYS = { "Harvester", "Batwing", "Luger", "Seer", "Icebreaker", "Gingerscythe", "Alienbeam", "Candleflame", "Corrupt" }

local function looksLikeWeaponDict(t)
    if type(t) ~= "table" then return 0 end
    local hits = 0
    for _, k in ipairs(WEAPON_KEYS) do
        local ok, v = pcall(function() return raw(t, k) or t[k] end)
        if ok and v ~= nil then hits += 1 end
    end
    return hits
end

local function toAsset(v)
    if type(v) == "number" and v > 1000 then return "rbxassetid://" .. tostring(v) end
    if type(v) ~= "string" or v == "" then return "" end
    if string.find(v, "rbxassetid://", 1, true) or string.find(v, "rbxasset://", 1, true) then return v end
    local id = string.match(v, "(%d%d%d%d%d+)")
    if id then return "rbxassetid://" .. id end
    return ""
end

local db = {}
local debugLines = { "=== NOIR SMART DUMP ===", "PlaceId=" .. tostring(game.PlaceId), "" }

local function add(name, mesh, tex, kind)
    if type(name) ~= "string" or #name < 2 or #name > 42 then return end
    local m = toAsset(mesh)
    if m == "" then return end
    if db[name] then return end
    db[name] = { mesh = m, tex = toAsset(tex), kind = kind or "Knife" }
end

local function harvestEntry(name, data)
    if type(data) ~= "table" then return end
    local mesh = raw(data, "MeshId") or raw(data, "MeshID") or raw(data, "meshId") or raw(data, "Mesh")
    local tex = raw(data, "TextureId") or raw(data, "TextureID") or raw(data, "Texture")
    local typ = tostring(raw(data, "ItemType") or raw(data, "Type") or "")
    local kind = "Knife"
    if string.find(string.lower(typ), "gun", 1, true) then kind = "Gun" end
    local n = name or raw(data, "ItemName") or raw(data, "Name")
    add(n, mesh, tex, kind)
    -- nested model instance
    local model = raw(data, "Model") or raw(data, "Tool")
    if typeof(model) == "Instance" then
        local sm = model:FindFirstChildOfClass("SpecialMesh") or model:FindFirstChildWhichIsA("MeshPart", true)
        if sm then
            if sm:IsA("SpecialMesh") then add(n, sm.MeshId, sm.TextureId, kind)
            else add(n, sm.MeshId, sm.TextureID, kind) end
        end
    end
end

local function harvestDict(t, label)
    if type(t) ~= "table" then return 0 end
    local before = 0
    for _ in pairs(db) do before += 1 end
    pcall(function()
        for k, v in pairs(t) do
            if type(k) == "string" and type(v) == "table" then
                harvestEntry(k, v)
            elseif type(v) == "table" then
                harvestEntry(raw(v, "ItemName") or raw(v, "Name"), v)
            end
        end
    end)
    local after = 0
    for _ in pairs(db) do after += 1 end
    local gained = after - before
    if gained > 0 then
        debugLines[#debugLines + 1] = string.format("DICT %s  +%d items", tostring(label), gained)
    end
    return gained
end

-- 1) _G / shared
pcall(function()
    if type(getrenv) ~= "function" then return end
    local g = getrenv()._G
    debugLines[#debugLines + 1] = "_G type=" .. type(g)
    if type(g) == "table" then
        local keys = {}
        pcall(function()
            for k in pairs(g) do keys[#keys + 1] = tostring(k) end
        end)
        table.sort(keys)
        debugLines[#debugLines + 1] = "_G keys: " .. table.concat(keys, ", "):sub(1, 400)
        harvestDict(g.Database, "_G.Database")
        harvestDict(g.Database and g.Database.Item, "_G.Database.Item")
        harvestDict(g.Items, "_G.Items")
        harvestDict(g.Weapons, "_G.Weapons")
        harvestDict(g.ItemData, "_G.ItemData")
    end
end)

-- 2) ReplicatedStorage tree
debugLines[#debugLines + 1] = ""
debugLines[#debugLines + 1] = "--- ReplicatedStorage ---"
pcall(function()
    for _, ch in ipairs(ReplicatedStorage:GetChildren()) do
        debugLines[#debugLines + 1] = ch.ClassName .. "  " .. ch.Name
        harvestDict(nil, ch.Name)
        if ch:IsA("Folder") or ch:IsA("Model") then
            for _, sub in ipairs(ch:GetChildren()) do
                if sub:IsA("Tool") or sub:IsA("Model") then
                    local sm = sub:FindFirstChildOfClass("SpecialMesh", true) or sub:FindFirstChildWhichIsA("MeshPart", true)
                    if sm then
                        if sm:IsA("SpecialMesh") then add(sub.Name, sm.MeshId, sm.TextureId)
                        else add(sub.Name, sm.MeshId, sm.TextureID) end
                    end
                end
            end
        end
        if ch:IsA("ModuleScript") then
            local n = string.lower(ch.Name)
            if string.find(n, "item", 1, true) or string.find(n, "weapon", 1, true) or string.find(n, "data", 1, true) or n == "database" or string.find(n, "skin", 1, true) then
                local ok, mod = pcall(require, ch)
                debugLines[#debugLines + 1] = "require " .. ch.Name .. " ok=" .. tostring(ok) .. " type=" .. type(mod)
                if ok then
                    harvestDict(mod, "require " .. ch.Name)
                    if type(mod) == "table" then
                        harvestDict(mod.Item or mod.Items or mod.Weapons, "require " .. ch.Name .. ".Item")
                    end
                end
            end
        end
    end
end)

-- 3) getgc dictionaries with known weapon names
notify("Scanning memory...")
local bestHits, bestTable = 0, nil
pcall(function()
    if type(getgc) ~= "function" then return end
    local dumped = getgc(true)
    local n = 0
    for _, object in pairs(dumped) do
        n += 1
        if n > 100000 then break end
        if type(object) == "table" then
            local hits = looksLikeWeaponDict(object)
            if hits > bestHits then
                bestHits = hits
                bestTable = object
            end
            if hits >= 2 then
                harvestDict(object, "gc hits=" .. hits)
            end
            local typ = raw(object, "ItemType") or raw(object, "itemType")
            if type(typ) == "string" then
                harvestEntry(raw(object, "ItemName") or raw(object, "Name"), object)
            end
        end
        if n % 4000 == 0 then task.wait() end
    end
    debugLines[#debugLines + 1] = "getgc scanned=" .. tostring(n) .. " bestMarkerHits=" .. tostring(bestHits)
end)

if bestTable then
    harvestDict(bestTable, "bestMarkerDict")
    local item = raw(bestTable, "Item") or raw(bestTable, "Items")
    harvestDict(item, "bestMarkerDict.Item")
end

-- 4) serialize
local names = {}
for k in pairs(db) do names[#names + 1] = k end
table.sort(names)
debugLines[#debugLines + 1] = ""
debugLines[#debugLines + 1] = "WEAPON COUNT=" .. #names
debugLines[#debugLines + 1] = "names: " .. table.concat(names, ", "):sub(1, 800)

local lines = { "return {" }
for _, name in ipairs(names) do
    local e = db[name]
    lines[#lines + 1] = string.format(
        "    [%q] = { mesh = %q, tex = %q, sx = 1, sy = 1, sz = 1, kind = %q },",
        name, e.mesh, e.tex or "", e.kind or "Knife"
    )
end
lines[#lines + 1] = "}"
local source = table.concat(lines, "\n")
local dbg = table.concat(debugLines, "\n")

pcall(function() if writefile then writefile("mmv_meshes.lua", source) end end)
pcall(function() if writefile then writefile("mmv_debug.txt", dbg) end end)
pcall(function() if setclipboard then setclipboard(source) end end)

print(dbg)
print("===== MESHES =====")
print(source)
notify(string.format("Weapons in memory: %d  (send mmv_meshes.lua AND mmv_debug.txt)", #names))
