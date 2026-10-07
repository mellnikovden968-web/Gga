-- Noir Hold Dump v2 — MMV/MM2
-- Возьми скин В РУКИ (чтобы модель была на персонаже), подожди 2 сек, жми DUMP.

local Players = game:GetService("Players")
local LP = Players.LocalPlayer

local BODY = {
    HumanoidRootPart=true, Head=true, Torso=true, ["Left Arm"]=true, ["Right Arm"]=true,
    ["Left Leg"]=true, ["Right Leg"]=true, UpperTorso=true, LowerTorso=true,
    LeftUpperArm=true, LeftLowerArm=true, LeftHand=true,
    RightUpperArm=true, RightLowerArm=true, RightHand=true,
    LeftUpperLeg=true, LeftLowerLeg=true, LeftFoot=true,
    RightUpperLeg=true, RightLowerLeg=true, RightFoot=true,
    Animate=true, Humanoid=true, Health=true, BodyColors=true, Pants=true, Shirt=true,
    ShirtGraphic=true, ["Body Colors"]=true, Accessory=true,
}

local function notify(msg)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Noir Dump", Text = tostring(msg), Duration = 6,
        })
    end)
    print("[NoirDump]", msg)
end

local function digits(s)
    return type(s) == "string" and string.match(s, "(%d%d%d%d%d+)") or nil
end

local function cf12(cf)
    if typeof(cf) ~= "CFrame" then return "nil" end
    local a = { cf:GetComponents() }
    local t = {}
    for i = 1, 12 do t[i] = string.format("%.6g", a[i]) end
    return "{" .. table.concat(t, ",") .. "}"
end

local function vec3(v)
    if typeof(v) ~= "Vector3" then return "nil" end
    return string.format("{%.6g,%.6g,%.6g}", v.X, v.Y, v.Z)
end

local SKIP_ANIM = {
    ["507766388"]=true, ["507766666"]=true, ["507766951"]=true,
    ["507767968"]=true, ["507768375"]=true, ["507770239"]=true,
    ["507770677"]=true, ["507771019"]=true, ["507771955"]=true,
    ["507776043"]=true, ["507777268"]=true, ["507770818"]=true,
    ["507770453"]=true, ["507768133"]=true,
    ["182393478"]=true, ["180435571"]=true, ["180435792"]=true,
    ["125750702"]=true, ["165590585"]=true,
    ["10921110146"]=true, ["10921100400"]=true, ["10921105765"]=true,
    ["10921107367"]=true, ["10921108971"]=true, ["913376220"]=true, ["913402848"]=true,
    ["522638767"]=true, ["522635514"]=true,
}

local function dumpNow()
    local char = LP.Character
    if not char then notify("Нет персонажа") return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local lines = {}
    lines[#lines+1] = "-- Noir hold dump v2 " .. os.date("%Y-%m-%d %H:%M:%S")
    lines[#lines+1] = "-- placeId=" .. tostring(game.PlaceId) .. " player=" .. LP.Name
    lines[#lines+1] = "return {"

    -- animations playing
    local custom = {}
    lines[#lines+1] = "  tracks = {"
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    if animator then
        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
            local a = track.Animation
            local aid = a and a.AnimationId or ""
            local num = digits(aid) or ""
            local skip = SKIP_ANIM[num] == true
            if not skip and num ~= "" then custom[#custom+1] = num end
            lines[#lines+1] = string.format(
                "    {name=%q, id=%q, pri=%q, loop=%s, speed=%.4g, len=%.4g, weight=%.4g, skip=%s},",
                track.Name, aid, tostring(track.Priority), tostring(track.Looped),
                track.Speed, track.Length, track.WeightCurrent, tostring(skip)
            )
        end
    end
    lines[#lines+1] = "  },"

    lines[#lines+1] = "  animate = {"
    local animate = char:FindFirstChild("Animate")
    if animate then
        for _, folder in ipairs(animate:GetChildren()) do
            local a = folder:FindFirstChildWhichIsA("Animation")
            if a then
                lines[#lines+1] = string.format("    [%q] = %q,", folder.Name, a.AnimationId)
            end
        end
    end
    lines[#lines+1] = "  },"

    -- every Motor6D
    lines[#lines+1] = "  motors = {"
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("Motor6D") then
            lines[#lines+1] = string.format(
                "    {name=%q, p0=%q, p1=%q, c0=%s, c1=%s},",
                d.Name, d.Part0 and d.Part0.Name or "", d.Part1 and d.Part1.Name or "",
                cf12(d.C0), cf12(d.C1)
            )
        end
    end
    lines[#lines+1] = "  },"

    -- tools anywhere
    lines[#lines+1] = "  tools = {"
    local function dumpInst(inst, indent)
        local pad = string.rep(" ", indent)
        if inst:IsA("MeshPart") then
            lines[#lines+1] = pad .. string.format("{class=\"MeshPart\", name=%q, mesh=%q, tex=%q, size=%s},",
                inst.Name, inst.MeshId, inst.TextureID, vec3(inst.Size))
        elseif inst:IsA("SpecialMesh") then
            lines[#lines+1] = pad .. string.format("{class=\"SpecialMesh\", name=%q, mesh=%q, tex=%q, scale=%s},",
                inst.Name, inst.MeshId, inst.TextureId, vec3(inst.Scale))
        elseif inst:IsA("Sound") then
            lines[#lines+1] = pad .. string.format("{class=\"Sound\", name=%q, id=%q, speed=%.4g},",
                inst.Name, inst.SoundId, inst.PlaybackSpeed)
        elseif inst:IsA("Beam") then
            lines[#lines+1] = pad .. string.format("{class=\"Beam\", name=%q, tex=%q},", inst.Name, inst.Texture)
        elseif inst:IsA("Animation") then
            lines[#lines+1] = pad .. string.format("{class=\"Animation\", name=%q, id=%q},", inst.Name, inst.AnimationId)
        elseif inst:IsA("Tool") then
            lines[#lines+1] = pad .. string.format("{class=\"Tool\", name=%q, texture=%q, grip=%s},",
                inst.Name, inst.TextureId, cf12(inst.Grip))
        end
        for _, c in ipairs(inst:GetChildren()) do
            dumpInst(c, indent)
        end
    end
    local function consider(inst)
        if inst:IsA("Tool") then
            lines[#lines+1] = string.format("    [%q] = {", inst.Name)
            dumpInst(inst, 6)
            lines[#lines+1] = "    },"
        end
    end
    for _, t in ipairs(char:GetChildren()) do consider(t) end
    local bp = LP:FindFirstChildOfClass("Backpack")
    if bp then for _, t in ipairs(bp:GetChildren()) do consider(t) end end
    lines[#lines+1] = "  },"

    -- extra models/parts on character that are NOT body
    lines[#lines+1] = "  extras = {"
    for _, ch in ipairs(char:GetChildren()) do
        if not BODY[ch.Name] and not ch:IsA("Accoutrement") and not ch:IsA("Tool")
            and not ch:IsA("LocalScript") and not ch:IsA("Script")
            and not ch:IsA("Humanoid") and not ch:IsA("BodyColors") then
            lines[#lines+1] = string.format("    [%q] = {class=%q,", ch.Name, ch.ClassName)
            dumpInst(ch, 6)
            lines[#lines+1] = "    },"
        end
    end
    -- accessories named gun/knife/sniper
    for _, acc in ipairs(char:GetChildren()) do
        if acc:IsA("Accoutrement") then
            local n = string.lower(acc.Name)
            if string.find(n, "gun") or string.find(n, "knife") or string.find(n, "sniper")
                or string.find(n, "ginger") or string.find(n, "harvest") or string.find(n, "scope") then
                lines[#lines+1] = string.format("    accessory_%s = {class=%q,", acc.Name, acc.ClassName)
                dumpInst(acc, 6)
                lines[#lines+1] = "    },"
            end
        end
    end
    lines[#lines+1] = "  },"

    -- all mesh ids on character that aren't typical body
    lines[#lines+1] = "  meshes = {"
    local seen = {}
    for _, d in ipairs(char:GetDescendants()) do
        local mid, tex, nm
        if d:IsA("MeshPart") then mid, tex, nm = d.MeshId, d.TextureID, d.Name
        elseif d:IsA("SpecialMesh") then mid, tex, nm = d.MeshId, d.TextureId, d.Name end
        local id = digits(mid)
        if id and not seen[id] then
            seen[id] = true
            lines[#lines+1] = string.format("    {name=%q, mesh=%q, tex=%q, parent=%q},",
                nm, mid, tex or "", d.Parent and d.Parent.Name or "")
        end
    end
    lines[#lines+1] = "  },"
    lines[#lines+1] = "}"

    local text = table.concat(lines, "\n")
    pcall(function()
        if writefile then writefile("NoirHoldDump.lua", text) end
    end)
    pcall(function()
        if setclipboard then setclipboard(text) end
    end)
    print(text)

    local nMesh = 0
    for _ in pairs(seen) do nMesh += 1 end
    if #custom > 0 then
        notify("anim " .. table.concat(custom, ",") .. " | mesh " .. tostring(nMesh) .. " | файл NoirHoldDump.lua")
    else
        notify("Своей анимации нет (оружие не в руках?). mesh=" .. tostring(nMesh))
    end
end

local gui = Instance.new("ScreenGui")
gui.Name = "NoirHoldDump"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

local btn = Instance.new("TextButton")
btn.Size = UDim2.fromOffset(170, 48)
btn.Position = UDim2.new(0, 12, 0.5, -24)
btn.BackgroundColor3 = Color3.fromRGB(20, 180, 90)
btn.TextColor3 = Color3.new(1, 1, 1)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 16
btn.Text = "DUMP HANDS"
btn.Parent = gui
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
btn.MouseButton1Click:Connect(dumpNow)
btn.Activated:Connect(dumpNow)

notify("Возьми снайперку в руки, подожди 2 сек, DUMP HANDS")
