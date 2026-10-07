-- Noir MMV Mesh Dumper
-- Run this INSIDE Murder Mystery V (or any MM clone where every skin is in inventory).
-- It scans tools, displays, ReplicatedStorage, Lighting, getgc and writes a MeshId table.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local JUNK = {
    knifedisplay = true, gundisplay = true, display = true, handle = true, blade = true,
    template = true, preview = true, camera = true, humanoid = true, part = true,
    mesh = true, model = true, weapon = true, default = true, classic = true,
    backpack = true, character = true, head = true, torso = true, humanoidrootpart = true,
}

local db = {} -- name -> { mesh, tex, sx, sy, sz, kind }

local function notify(text)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Noir Mesh Dump",
            Text = tostring(text),
            Duration = 6,
        })
    end)
    print("[Noir Mesh Dump]", text)
end

local function okName(name)
    if type(name) ~= "string" then return false end
    if #name < 2 or #name > 48 then return false end
    if JUNK[string.lower(name)] then return false end
    if string.find(name, "MeshId", 1, true) then return false end
    return true
end

local function takeMesh(obj)
    if not obj then return nil end
    if obj:IsA("SpecialMesh") and obj.MeshId ~= "" then
        return obj.MeshId, obj.TextureId, obj.Scale
    end
    if obj:IsA("MeshPart") and obj.MeshId ~= "" then
        return obj.MeshId, obj.TextureID, nil
    end
    return nil
end

local function extract(inst)
    local mesh, tex, scale = takeMesh(inst)
    if mesh then return mesh, tex, scale end
    local sm = inst:FindFirstChildOfClass("SpecialMesh")
    mesh, tex, scale = takeMesh(sm)
    if mesh then return mesh, tex, scale end
    local handle = inst:FindFirstChild("Handle")
    if handle then
        mesh, tex, scale = takeMesh(handle)
        if mesh then return mesh, tex, scale end
        mesh, tex, scale = takeMesh(handle:FindFirstChildOfClass("SpecialMesh"))
        if mesh then return mesh, tex, scale end
    end
    local ok, desc = pcall(function() return inst:GetDescendants() end)
    if ok then
        for _, d in ipairs(desc) do
            mesh, tex, scale = takeMesh(d)
            if mesh then return mesh, tex, scale end
        end
    end
end

local function guessKind(name, inst)
    local n = string.lower(tostring(name or ""))
    if string.find(n, "gun", 1, true) or string.find(n, "luger", 1, true) or string.find(n, "revolver", 1, true) then
        return "Gun"
    end
    if inst then
        local t = string.lower(inst.Name)
        if t == "gun" or t == "gundisplay" then return "Gun" end
        if t == "knife" or t == "knifedisplay" then return "Knife" end
    end
    return "Knife"
end

local function record(name, inst)
    if not okName(name) then return end
    local mesh, tex, scale = extract(inst)
    if type(mesh) ~= "string" or mesh == "" then return end
    if not db[name] then
        db[name] = {
            mesh = mesh,
            tex = tex or "",
            sx = (scale and scale.X) or 1,
            sy = (scale and scale.Y) or 1,
            sz = (scale and scale.Z) or 1,
            kind = guessKind(name, inst),
        }
    end
end

local function consider(inst)
    if not inst then return end
    record(inst.Name, inst)
    pcall(function()
        local a = inst:GetAttribute("ItemName") or inst:GetAttribute("SkinName") or inst:GetAttribute("WeaponName")
        if type(a) == "string" then record(a, inst) end
    end)
    local sv = inst:FindFirstChild("ItemName") or inst:FindFirstChild("SkinName")
    if sv and sv:IsA("StringValue") then record(sv.Value, inst) end
end

local function scanRoot(root)
    pcall(function()
        consider(root)
        for _, inst in ipairs(root:GetDescendants()) do
            if inst:IsA("Tool") or inst:IsA("Model") or inst:IsA("MeshPart") or inst:IsA("Accessory") or inst:FindFirstChildOfClass("SpecialMesh") then
                consider(inst)
            end
        end
    end)
end

notify("Scanning...")

scanRoot(ReplicatedStorage)
scanRoot(Lighting)
scanRoot(Workspace)
pcall(function() scanRoot(game:GetService("StarterPack")) end)
pcall(function() scanRoot(game:GetService("ReplicatedFirst")) end)
pcall(function()
    if LocalPlayer then
        scanRoot(LocalPlayer:FindFirstChild("Backpack"))
        scanRoot(LocalPlayer.Character)
        scanRoot(LocalPlayer:FindFirstChild("PlayerGui"))
    end
end)
pcall(function()
    if type(getnilinstances) == "function" then
        for _, inst in ipairs(getnilinstances()) do
            if inst:IsA("Tool") or inst:IsA("Model") or inst:IsA("MeshPart") then consider(inst) end
        end
    end
end)

pcall(function()
    if type(getgc) ~= "function" then return end
    local dumped = getgc(true)
    local n = 0
    for _, object in pairs(dumped) do
        n += 1
        if n > 80000 then break end
        if type(object) == "table" then
            local ok, name = pcall(rawget, object, "ItemName")
            if not (ok and type(name) == "string") then
                ok, name = pcall(rawget, object, "Name")
            end
            if ok and type(name) == "string" and okName(name) then
                local mesh = select(1, pcall(rawget, object, "MeshId"))
                local tex = select(1, pcall(rawget, object, "TextureId"))
                if type(mesh) ~= "string" then mesh = nil end
                if type(mesh) == "string" and mesh ~= "" and not db[name] then
                    db[name] = {
                        mesh = mesh,
                        tex = type(tex) == "string" and tex or "",
                        sx = 1, sy = 1, sz = 1,
                        kind = guessKind(name),
                    }
                end
            end
        end
        if n % 5000 == 0 then task.wait() end
    end
end)

local names = {}
for name in pairs(db) do names[#names + 1] = name end
table.sort(names)

local lines = { "return {" }
for _, name in ipairs(names) do
    local e = db[name]
    local key = string.format("%q", name)
    lines[#lines + 1] = string.format(
        "    [%s] = { mesh = %q, tex = %q, sx = %s, sy = %s, sz = %s, kind = %q },",
        key, e.mesh, e.tex or "", tostring(e.sx), tostring(e.sy), tostring(e.sz), e.kind or "Knife"
    )
end
lines[#lines + 1] = "}"
local source = table.concat(lines, "\n")

local saved = false
pcall(function()
    if writefile then
        writefile("mmv_meshes.lua", source)
        saved = true
    end
end)
pcall(function()
    if setclipboard then setclipboard(source) end
end)

notify(string.format("Meshes: %d%s", #names, saved and "  -> mmv_meshes.lua" or "  (copy from console)"))
print("===== NOIR MMV MESH DUMP START =====")
print(source)
print("===== NOIR MMV MESH DUMP END =====")
print("[Noir] Count:", #names, saved and "saved mmv_meshes.lua" or "no writefile, copy the table above")
