-- Noir MM2 Data Dump — run IN Murder Mystery 2
-- Explores Database / Resources / GetSyncData (not hats).

local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local function notify(t)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Noir MM2 Dump", Text = tostring(t), Duration = 6,
        })
    end)
    print("[Noir MM2]", t)
end

local lines = { "=== MM2 DATA DUMP ===", "PlaceId=" .. tostring(game.PlaceId), "" }
local function L(...)
    local s = table.concat({ ... }, " ")
    lines[#lines + 1] = s
    print(s)
end

local function dumpTree(inst, depth, maxDepth)
    if not inst or depth > maxDepth then return end
    local pad = string.rep("  ", depth)
    L(pad .. inst.ClassName .. "  " .. inst.Name)
    pcall(function()
        for _, ch in ipairs(inst:GetChildren()) do
            dumpTree(ch, depth + 1, maxDepth)
        end
    end)
end

L("--- Database ---")
local db = RS:FindFirstChild("Database")
if db then dumpTree(db, 0, 3) else L("NO Database folder") end

L("")
L("--- Resources ---")
local res = RS:FindFirstChild("Resources")
if res then dumpTree(res, 0, 2) else L("NO Resources") end

L("")
L("--- Modules ---")
local mods = RS:FindFirstChild("Modules")
if mods then
    for _, ch in ipairs(mods:GetChildren()) do
        L(ch.ClassName .. "  " .. ch.Name)
    end
end

local function tryInvoke(obj, args, label)
    if not obj then return end
    for _, a in ipairs(args) do
        local ok, result = pcall(function()
            if obj:IsA("RemoteFunction") then
                if a == "__none" then return obj:InvokeServer() end
                return obj:InvokeServer(a)
            elseif obj:IsA("BindableFunction") then
                if a == "__none" then return obj:Invoke() end
                return obj:Invoke(a)
            end
        end)
        local rtype = type(result)
        local extra = ""
        if ok and rtype == "table" then
            local n, sample = 0, {}
            pcall(function()
                for k in pairs(result) do
                    n += 1
                    if #sample < 8 then sample[#sample + 1] = tostring(k) end
                    if n > 400 then break end
                end
            end)
            extra = " n=" .. n .. " keys=" .. table.concat(sample, ",")
        elseif ok then
            extra = " " .. tostring(result):sub(1, 80)
        else
            extra = " ERR " .. tostring(result):sub(1, 80)
        end
        L(label, tostring(a), "ok=" .. tostring(ok), rtype, extra)
    end
end

local args = { "__none", "Item", "Items", "Weapons", "Database", "Knife", "Gun", "Skins", "Shop" }

L("")
L("--- GetSyncData RemoteFunction ---")
tryInvoke(RS:FindFirstChild("GetSyncData"), args, "GetSyncData")

L("")
L("--- GetSyncDataServer Bindable ---")
tryInvoke(RS:FindFirstChild("GetSyncDataServer"), args, "GetSyncDataServer")

L("")
L("--- GetDataServer Bindable ---")
tryInvoke(RS:FindFirstChild("GetDataServer"), args, "GetDataServer")

L("")
L("--- GetPlayerData_REMOTE ---")
tryInvoke(RS:FindFirstChild("GetPlayerData_REMOTE"), args, "GetPlayerData")

local text = table.concat(lines, "\n")
pcall(function() if writefile then writefile("mm2_debug.txt", text) end end)
pcall(function() if setclipboard then setclipboard(text) end end)
notify("Saved mm2_debug.txt — send this file")
