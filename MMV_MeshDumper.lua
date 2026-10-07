-- Noir Hold Dump: execute in MMV/MM2, take the sniper in your hands, press DUMP.
-- Cheap: only your character + equipped tool. No getgc, no ReplicatedStorage walk.

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local UIS = game:GetService("UserInputService")

local function notify(msg)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Noir Dump",
            Text = tostring(msg),
            Duration = 5,
        })
    end)
    print("[NoirDump]", msg)
end

local function digits(s)
    if type(s) ~= "string" then return nil end
    return string.match(s, "(%d%d%d%d%d+)")
end

local function esc(s)
    s = tostring(s or "")
    s = string.gsub(s, "\\", "\\\\")
    s = string.gsub(s, "\"", "\\\"")
    s = string.gsub(s, "\n", "\\n")
    return s
end

local function cf12(cf)
    if typeof(cf) ~= "CFrame" then return "nil" end
    local a = { cf:GetComponents() }
    local t = {}
    for i = 1, 12 do
        t[i] = string.format("%.6g", a[i])
    end
    return "{" .. table.concat(t, ",") .. "}"
end

local function vec3(v)
    if typeof(v) ~= "Vector3" then return "nil" end
    return string.format("{%.6g,%.6g,%.6g}", v.X, v.Y, v.Z)
end

local function col3(c)
    if typeof(c) ~= "Color3" then return "nil" end
    return string.format("{%.4g,%.4g,%.4g}", c.R, c.G, c.B)
end

local function dumpSound(s)
    return string.format(
        "{name=%q, id=%q, speed=%.4g, vol=%.4g, loop=%s}",
        s.Name, s.SoundId, s.PlaybackSpeed, s.Volume, tostring(s.Looped)
    )
end

local function dumpBeam(b)
    local c0 = "nil"
    pcall(function()
        local k = b.Color.Keypoints
        if k and k[1] then
            local c = k[1].Value
            c0 = col3(c)
        end
    end)
    return string.format(
        "{name=%q, tex=%q, w0=%.4g, w1=%.4g, color=%s}",
        b.Name, b.Texture, b.Width0, b.Width1, c0
    )
end

local function dumpMesh(inst)
    if inst:IsA("MeshPart") then
        return string.format(
            "{class=\"MeshPart\", name=%q, mesh=%q, tex=%q, size=%s}",
            inst.Name, inst.MeshId, inst.TextureID, vec3(inst.Size)
        )
    end
    if inst:IsA("SpecialMesh") then
        return string.format(
            "{class=\"SpecialMesh\", name=%q, mesh=%q, tex=%q, scale=%s, off=%s}",
            inst.Name, inst.MeshId, inst.TextureId, vec3(inst.Scale), vec3(inst.Offset)
        )
    end
end

local function walk(inst, out, depth)
    if depth > 6 then return end
    local line = dumpMesh(inst)
    if line then out[#out + 1] = "    mesh = " .. line .. "," end
    if inst:IsA("Sound") then out[#out + 1] = "    sound = " .. dumpSound(inst) .. "," end
    if inst:IsA("Beam") then out[#out + 1] = "    beam = " .. dumpBeam(inst) .. "," end
    if inst:IsA("Animation") then
        out[#out + 1] = string.format("    animation = {name=%q, id=%q},", inst.Name, inst.AnimationId)
    end
    if inst:IsA("Motor6D") then
        out[#out + 1] = string.format(
            "    motor = {name=%q, p0=%q, p1=%q, c0=%s, c1=%s},",
            inst.Name,
            inst.Part0 and inst.Part0.Name or "",
            inst.Part1 and inst.Part1.Name or "",
            cf12(inst.C0),
            cf12(inst.C1)
        )
    end
    if inst:IsA("Attachment") then
        out[#out + 1] = string.format("    att = {name=%q, cf=%s},", inst.Name, cf12(inst.CFrame))
    end
    for _, c in ipairs(inst:GetChildren()) do
        walk(c, out, depth + 1)
    end
end

local SKIP_ANIM = {
    ["507766388"] = true, ["507766666"] = true, ["507766951"] = true,
    ["507767968"] = true, ["507768375"] = true, ["507770239"] = true,
    ["507770677"] = true, ["507771019"] = true, ["507771955"] = true,
    ["182393478"] = true, ["180435571"] = true, ["180435792"] = true,
    ["125750702"] = true, ["165590585"] = true,
}

local function dumpTracks(hum, out)
    local animator = hum and (hum:FindFirstChildOfClass("Animator") or hum)
    if not animator or not animator.GetPlayingAnimationTracks then return end
    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        local a = track.Animation
        local aid = a and a.AnimationId or ""
        local num = digits(aid) or ""
        out[#out + 1] = string.format(
            "    {name=%q, id=%q, pri=%q, loop=%s, speed=%.4g, len=%.4g, weight=%.4g, skip=%s},",
            track.Name, aid, tostring(track.Priority), tostring(track.Looped),
            track.Speed, track.Length, track.WeightCurrent, tostring(SKIP_ANIM[num] == true)
        )
    end
end

local function dumpNow()
    local char = LP.Character
    if not char then
        notify("Нет персонажа")
        return
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local lines = {}
    lines[#lines + 1] = "-- Noir hold dump " .. os.date("%Y-%m-%d %H:%M:%S")
    lines[#lines + 1] = "-- placeId=" .. tostring(game.PlaceId) .. " player=" .. LP.Name
    lines[#lines + 1] = "return {"
    lines[#lines + 1] = "  tracks = {"
    dumpTracks(hum, lines)
    lines[#lines + 1] = "  },"

    local animate = char:FindFirstChild("Animate")
    if animate then
        lines[#lines + 1] = "  animate = {"
        for _, folder in ipairs(animate:GetChildren()) do
            local a = folder:FindFirstChildWhichIsA("Animation")
            if a then
                lines[#lines + 1] = string.format("    [%q] = %q,", folder.Name, a.AnimationId)
            end
        end
        lines[#lines + 1] = "  },"
    end

    lines[#lines + 1] = "  tools = {"
    local function dumpTool(tool)
        lines[#lines + 1] = string.format("    [%q] = {", tool.Name)
        lines[#lines + 1] = string.format("      class=%q, texture=%q,", tool.ClassName, tool:IsA("Tool") and tool.TextureId or "")
        if tool:IsA("Tool") then
            lines[#lines + 1] = "      grip = " .. cf12(tool.Grip) .. ","
        end
        walk(tool, lines, 0)
        lines[#lines + 1] = "    },"
    end
    for _, t in ipairs(char:GetChildren()) do
        if t:IsA("Tool") then dumpTool(t) end
    end
    local bp = LP:FindFirstChildOfClass("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") then dumpTool(t) end
        end
    end
    lines[#lines + 1] = "  },"

    lines[#lines + 1] = "  displays = {"
    for _, name in ipairs({ "GunDisplay", "KnifeDisplay", "Gun", "Knife" }) do
        local d = char:FindFirstChild(name)
        if d then
            lines[#lines + 1] = string.format("    [%q] = {", name)
            walk(d, lines, 0)
            lines[#lines + 1] = "    },"
        end
    end
    lines[#lines + 1] = "  },"

    lines[#lines + 1] = "  motors = {"
    for _, n in ipairs({ "Right Shoulder", "Left Shoulder", "Right Hip", "Left Hip",
        "RightShoulder", "LeftShoulder", "RightWrist", "LeftWrist",
        "RightElbow", "LeftElbow" }) do
        local m = char:FindFirstChild(n, true)
        if m and m:IsA("Motor6D") then
            lines[#lines + 1] = string.format(
                "    [%q] = {c0=%s, c1=%s},",
                n, cf12(m.C0), cf12(m.C1)
            )
        end
    end
    lines[#lines + 1] = "  },"
    lines[#lines + 1] = "}"

    local text = table.concat(lines, "\n")
    local fname = "NoirHoldDump.lua"
    local saved = false
    pcall(function()
        if writefile then
            writefile(fname, text)
            saved = true
        end
    end)
    pcall(function()
        if setclipboard then setclipboard(text) end
    end)

    local ids = {}
    for _, track in ipairs((hum and hum:FindFirstChildOfClass("Animator") or hum):GetPlayingAnimationTracks()) do
        local num = digits(track.Animation and track.Animation.AnimationId or "")
        if num and not SKIP_ANIM[num] then
            ids[#ids + 1] = num
        end
    end
    if saved then
        notify("Записано в " .. fname .. ( #ids > 0 and (" | anim " .. table.concat(ids, ",")) or " | своих anim нет" ))
    else
        notify((#ids > 0) and ("anim " .. table.concat(ids, ",")) or "Своих anim нет, текст в консоли")
    end
    print(text)
    return text
end

-- tiny button
local gui = Instance.new("ScreenGui")
gui.Name = "NoirHoldDump"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

local btn = Instance.new("TextButton")
btn.Size = UDim2.fromOffset(160, 44)
btn.Position = UDim2.new(0, 12, 0.5, -22)
btn.BackgroundColor3 = Color3.fromRGB(20, 180, 90)
btn.TextColor3 = Color3.new(1, 1, 1)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 16
btn.Text = "DUMP HANDS"
btn.Parent = gui
local c = Instance.new("UICorner")
c.CornerRadius = UDim.new(0, 10)
c.Parent = btn

btn.MouseButton1Click:Connect(function()
    dumpNow()
end)
btn.Activated:Connect(function()
    dumpNow()
end)

LP.CharacterAdded:Connect(function()
    -- keep gui
end)

notify("Возьми снайперку в руки и жми DUMP HANDS")
