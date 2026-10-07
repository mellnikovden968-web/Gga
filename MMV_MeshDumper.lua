-- Noir MMV Mesh Dumper v2
-- Run in Murder Mystery V with INVENTORY OPEN.
-- Collects only Tools / weapon displays / inventory viewports — not map eggs.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

local SKIP = {
    knifedisplay=true, gundisplay=true, display=true, handle=true, blade=true,
    template=true, preview=true, camera=true, humanoid=true, part=true,
    mesh=true, model=true, weapon=true, default=true, classic=true,
    backpack=true, character=true, head=true, torso=true, humanoidrootpart=true,
    leftfoot=true, rightfoot=true, lefthand=true, righthand=true,
    leftlowerarm=true, rightlowerarm=true, leftupperarm=true, rightupperarm=true,
    leftlowerleg=true, rightlowerleg=true, leftupperleg=true, rightupperleg=true,
    uppertorso=true, lowertorso=true, meshpart=true, accessory=true,
    workspace=true, replicatedstorage=true, lighting=true, coin=true,
    coincontainer=true, lobby=true, sign=true, tree=true, rocks=true, leaves=true,
    body=true, base=true, parts=true, models=true, pets=true, outfits=true,
}

local function junk(name)
    if type(name) ~= "string" or #name < 2 or #name > 40 then return true end
    local l = string.lower(name)
    if SKIP[l] then return true end
    if string.sub(l, 1, 10) == "accessory " then return true end
    if string.find(l, "egg", 1, true) then return true end
    if string.find(l, "wheel", 1, true) then return true end
    if string.find(l, "meshes/", 1, true) then return true end
    if string.find(l, " ", 1, true) and string.find(l, "hair", 1, true) then return true end
    return false
end

local function notify(t)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", { Title = "Noir MMV Dump v2", Text = tostring(t), Duration = 6 })
    end)
    print("[Noir MMV]", t)
end

local function take(obj)
    if not obj then return end
    if obj:IsA("SpecialMesh") and obj.MeshId ~= "" then return obj.MeshId, obj.TextureId, obj.Scale end
    if obj:IsA("MeshPart") and obj.MeshId ~= "" then return obj.MeshId, obj.TextureID, nil end
end

local function extract(inst)
    local m, t, s = take(inst)
    if m then return m, t, s end
    m, t, s = take(inst:FindFirstChildOfClass("SpecialMesh"))
    if m then return m, t, s end
    local h = inst:FindFirstChild("Handle")
    if h then
        m, t, s = take(h)
        if m then return m, t, s end
        m, t, s = take(h:FindFirstChildOfClass("SpecialMesh"))
        if m then return m, t, s end
    end
    pcall(function()
        for _, d in ipairs(inst:GetDescendants()) do
            m, t, s = take(d)
            if m then return end
        end
    end)
    return m, t, s
end

local db = {}

local function record(name, inst)
    if junk(name) or not inst then return end
    if db[name] then return end
    local mesh, tex, scale = extract(inst)
    if type(mesh) ~= "string" or mesh == "" then return end
    local kind = "Knife"
    local n = string.lower(name)
    if string.find(n, "gun", 1, true) or string.find(n, "luger", 1, true) then kind = "Gun" end
    db[name] = {
        mesh = mesh, tex = tex or "",
        sx = (scale and scale.X) or 1, sy = (scale and scale.Y) or 1, sz = (scale and scale.Z) or 1,
        kind = kind,
    }
end

local function useful(inst)
    return inst and (inst:IsA("Tool") or inst:IsA("Accessory") or inst.Name == "Knife" or inst.Name == "Gun"
        or inst.Name == "KnifeDisplay" or inst.Name == "GunDisplay"
        or inst:IsA("Model") and inst:FindFirstChild("Handle"))
end

local function scan(root)
    if not root then return end
    pcall(function()
        if useful(root) then
            record(root.Name, root)
            local a = root:GetAttribute("ItemName") or root:GetAttribute("SkinName")
            if type(a) == "string" then record(a, root) end
        end
        for _, inst in ipairs(root:GetDescendants()) do
            if useful(inst) then
                record(inst.Name, inst)
                local a = inst:GetAttribute("ItemName") or inst:GetAttribute("SkinName")
                if type(a) == "string" then record(a, inst) end
            elseif inst:IsA("ViewportFrame") then
                local label
                local p = inst.Parent
                if p then
                    for _, ch in ipairs(p:GetDescendants()) do
                        if (ch:IsA("TextLabel") or ch:IsA("TextButton")) and ch.Text ~= "" and not junk(ch.Text) then
                            label = ch.Text
                            break
                        end
                    end
                end
                if label then record(label, inst) end
            end
        end
    end)
end

notify("Open inventory, dumping tools + viewports...")

scan(ReplicatedStorage)
scan(Lighting)
scan(game:GetService("StarterPack"))
if LocalPlayer then
    scan(LocalPlayer:FindFirstChild("Backpack"))
    scan(LocalPlayer.Character)
    scan(LocalPlayer:FindFirstChild("PlayerGui"))
end

-- Click inventory cards (name labels) and recapture equipped knife/gun
pcall(function()
    local gui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    if not gui then return end
    local clicked = 0
    for _, v in ipairs(gui:GetDescendants()) do
        if (v:IsA("TextButton") or v:IsA("ImageButton") or v:IsA("TextLabel")) and not junk(v.Text) then
            local btn = v
            if not btn:IsA("GuiButton") then
                btn = v.Parent
                if btn and not btn:IsA("GuiButton") then btn = nil end
            end
            if btn and btn:IsA("GuiButton") then
                pcall(function()
                    if firesignal then
                        firesignal(btn.MouseButton1Click)
                        firesignal(btn.Activated)
                    end
                end)
                clicked += 1
                task.wait(0.08)
                local char = LocalPlayer.Character
                if char then
                    local k = char:FindFirstChild("Knife") or char:FindFirstChild("KnifeDisplay")
                    local g = char:FindFirstChild("Gun") or char:FindFirstChild("GunDisplay")
                    if k then record(v.Text, k) end
                    if g then record(v.Text, g) end
                end
                local bp = LocalPlayer:FindFirstChild("Backpack")
                if bp then
                    local k = bp:FindFirstChild("Knife")
                    local g = bp:FindFirstChild("Gun")
                    if k then record(v.Text, k) end
                    if g then record(v.Text, g) end
                end
                if clicked >= 250 then break end
                if clicked % 20 == 0 then task.wait(0.15) end
            end
        end
    end
    notify("Clicked " .. clicked .. " inventory buttons")
end)

local names = {}
for n in pairs(db) do names[#names + 1] = n end
table.sort(names)
local lines = { "return {" }
for _, name in ipairs(names) do
    local e = db[name]
    lines[#lines + 1] = string.format(
        "    [%q] = { mesh = %q, tex = %q, sx = %s, sy = %s, sz = %s, kind = %q },",
        name, e.mesh, e.tex or "", tostring(e.sx), tostring(e.sy), tostring(e.sz), e.kind
    )
end
lines[#lines + 1] = "}"
local source = table.concat(lines, "\n")
pcall(function() if writefile then writefile("mmv_meshes.lua", source) end end)
pcall(function() if setclipboard then setclipboard(source) end end)
notify("Weapons: " .. #names .. "  -> mmv_meshes.lua")
print("===== NOIR MMV MESH DUMP v2 =====")
print(source)
print("===== END =====")
