local Velvet = loadstring(game:HttpGet("https://raw.githubusercontent.com/DexCodeSX/Velvet/main/Library.lua"))()

local __flagIndex = 0
local function nextFlag(prefix)
    __flagIndex = __flagIndex + 1
    return "Noir_" .. prefix:gsub("%W", "_") .. "_" .. __flagIndex
end

local Window = Velvet:CreateWindow({
    Title = "Noir Silent Aim",
    SubTitle = "Murder Mystery 2",
    ToggleKey = Enum.KeyCode.RightShift,
    ToggleIcon = "crosshair",
})
local NoirTab = Window:AddTab("Home", "home")
local host = {}
function host.Notify(title, duration)
    Velvet:Notify({Title = "Noir Silent Aim", Content = tostring(title), Duration = duration or 3, Type = "info"})
end
function host.CreateTab()
    local wrapper = {}
    function wrapper:AddSection(name, description)
        local section = NoirTab:AddSection(name)
        if description and description ~= "" and section.AddParagraph then
            section:AddParagraph({Title = name, Content = description})
        end
        local api = {}
        function api:AddToggle(text, callback)
            local state = false
            local control = section:AddToggle(nextFlag(text), {
                Text = text, Default = false,
                Callback = function(value) state = value == true; callback(state) end
            })
            return function(value)
                local wanted = value
                if wanted == nil then wanted = not state end
                if control and control.Set then control:Set(wanted) end
            end
        end
        function api:AddSlider(text, minimum, maximum, default, callback)
            local control = section:AddSlider(nextFlag(text), {
                Text = text, Min = minimum, Max = maximum, Default = default,
                Increment = 1, Callback = callback
            })
            return {SetValue = function(_, value) if control and control.Set then control:Set(value) end end}
        end
        function api:AddDropdown(text, values, callback)
            local control = section:AddDropdown(nextFlag(text), {
                Text = text, Values = values, Default = values[1], Callback = callback
            })
            return {SetValue = function(_, value) if control and control.Set then control:Set(value) end end}
        end
        function api:AddTextBox(text, callback)
            local control = section:AddInput(nextFlag(text), {
                Text = text, Default = "", Placeholder = text,
                Callback = callback
            })
            return {SetValue = function(_, value) if control and control.Set then control:Set(value) end end}
        end
        function api:AddButton(text, callback)
            return section:AddButton({Text = text, Callback = callback})
        end
        function api:AddLabel(text)
            if section.AddParagraph then return section:AddParagraph({Title = "", Content = text}) end
        end
        return api
    end
    return wrapper
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stats = game:GetService("Stats")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local config = {
    enabled = false,
    adaptive = true,
    fixedLead = 0.075,
    extraLead = 0.02,
    maxLead = 0.18,
    horizontalOnly = true,
    targetPart = "HumanoidRootPart",
    alignDirection = true,
    wallCheck = false,
    knifeEnabled = false,
    knifeWallCheck = false,
    knifePrioritizeSheriff = true,
    prioritizePing = true,
    predictJump = false,
    predictLag = true,
    maxSimulationMs = 180,
    predictionIntervalMs = 72,
    manualPingMs = 80,
    offsetX = 0,
    offsetY = 0,
    offsetZ = 0,
    horizontalMultiplier = 100,
    verticalMultiplier = 100,
    showShootButton = false,
    lockShootButton = false,
}

local murderer
local cachedPing = 0.05
local redirected = 0
local hooked = false
local running = true
local shootButton
local shootGui
local shootBusy = false
local presetName = "default"
local PRESET_FOLDER = "Ixry Shizuka/presets"
local revertControls = {}
local revertToggleStates = {}
local syncRevertControls
local motionPart
local motionPosition
local motionTime
local measuredVelocity = Vector3.zero
local motionSamples = {}
local previousEstimatedVelocity = Vector3.zero
local estimatedAcceleration = Vector3.zero
local lastAutoTune = 0

local function notify(text, time)
    if type(host.Notify) == "function" then
        pcall(host.Notify, "MM2 Silent Aim: " .. tostring(text), time or 3)
    end
end

local function validTarget(player)
    local character = player and player.Character
    local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
    return player ~= LocalPlayer and character ~= nil and humanoid ~= nil and humanoid.Health > 0
end

local function setTarget(player)
    if not validTarget(player) then player = nil end
    if murderer ~= player then
        murderer = player
        if player then notify("Target: " .. player.Name, 2) end
    end
end

local function findByKnife()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            local backpack = player:FindFirstChildOfClass("Backpack")
            if (character and character:FindFirstChild("Knife")) or (backpack and backpack:FindFirstChild("Knife")) then
                return player
            end
        end
    end
end

local function consumeData(data)
    if typeof(data) ~= "table" then return false end
    for _, player in ipairs(Players:GetPlayers()) do
        local info = data[player.Name] or data[tostring(player.UserId)]
        local role = typeof(info) == "table" and (info.Role or info.role or info.CurrentRole) or info
        if role == "Murderer" then
            setTarget(player)
            return true
        end
    end
    return false
end

local function getPlayerDataRemote()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local extras = remotes and remotes:FindFirstChild("Extras")
    local remote = extras and extras:FindFirstChild("GetPlayerData")
    return remote and remote:IsA("RemoteFunction") and remote or nil
end

local function refreshTarget()
    local weaponTarget = findByKnife()
    if weaponTarget then
        setTarget(weaponTarget)
        return
    end
    local remote = getPlayerDataRemote()
    if remote then
        local ok, data = pcall(function() return remote:InvokeServer() end)
        if ok and consumeData(data) then return end
    end
    setTarget(nil)
end

local function updatePing()
    pcall(function()
        local network = Stats:FindFirstChild("Network")
        local items = network and network:FindFirstChild("ServerStatsItem")
        local pingItem = items and items:FindFirstChild("Data Ping")
        if pingItem then
            local measured = pingItem:GetValue() / 1000
            if measured > 0 and measured < 2 then
                cachedPing = cachedPing * 0.7 + measured * 0.3
            end
        end
    end)
end

local PingProfiles = {
    {Ping = 20, Sim = 48, Interval = 70, H = 154, V = 144, X = -5, Y = -14, Z = 0},
    {Ping = 50, Sim = 54, Interval = 66, H = 162, V = 152, X = -6, Y = -14, Z = 0},
    {Ping = 100, Sim = 68, Interval = 60, H = 176, V = 166, X = -8, Y = -15, Z = 0},
    {Ping = 150, Sim = 72, Interval = 64, H = 182, V = 170, X = -9, Y = -12, Z = 0},
    {Ping = 200, Sim = 76, Interval = 70, H = 188, V = 174, X = -10, Y = -11, Z = 0},
    {Ping = 300, Sim = 82, Interval = 76, H = 196, V = 180, X = -12, Y = -10, Z = 0},
}

local function interpolateProfile(ping)
    local a, b = PingProfiles[1], PingProfiles[1]
    if ping >= PingProfiles[#PingProfiles].Ping then
        a, b = PingProfiles[#PingProfiles], PingProfiles[#PingProfiles]
    else
        for index = 1, #PingProfiles - 1 do
            if ping >= PingProfiles[index].Ping and ping <= PingProfiles[index + 1].Ping then
                a, b = PingProfiles[index], PingProfiles[index + 1]
                break
            end
        end
    end
    local span = b.Ping - a.Ping
    local alpha = span > 0 and math.clamp((ping - a.Ping) / span, 0, 1) or 0
    alpha = alpha * alpha * (3 - 2 * alpha)
    local function mix(key) return a[key] + (b[key] - a[key]) * alpha end
    return {
        Sim = math.floor(mix("Sim") + 0.5),
        Interval = math.floor(mix("Interval") + 0.5),
        H = math.floor(mix("H") + 0.5),
        V = math.floor(mix("V") + 0.5),
        X = math.floor(mix("X") + 0.5),
        Y = math.floor(mix("Y") + 0.5),
        Z = math.floor(mix("Z") + 0.5),
    }
end

local function autoTuneForPing()
    if not config.prioritizePing then return end
    local now = os.clock()
    if now - lastAutoTune < 0.4 then return end
    lastAutoTune = now
    local pingMs = math.clamp(math.floor(cachedPing * 1000 + 0.5), 5, 350)
    if config.manualPingMs ~= pingMs then
        config.manualPingMs = pingMs
        local control = revertControls.manualPingMs
        if type(control) == "table" and type(control.SetValue) == "function" then
            pcall(control.SetValue, control, pingMs)
        elseif type(control) == "function" then
            pcall(control, pingMs)
        end
    end
end

local function leadTime()
    local prediction
    if config.adaptive then
        local ping = config.prioritizePing and cachedPing or (config.manualPingMs / 1000)
        prediction = ping + config.extraLead
        if config.predictLag then
            local samplingDelay = math.clamp(config.predictionIntervalMs / 2000, 0, 0.05)
            prediction = prediction + samplingDelay + math.max(0, ping - 0.10) * 0.15
        end
    else
        prediction = config.fixedLead
    end
    return math.clamp(prediction, 0.02, math.min(config.maxLead, config.maxSimulationMs / 1000))
end

local function sampleMotion(part)
    local now = os.clock()
    if motionPart ~= part then
        motionPart = part
        motionSamples = {}
        measuredVelocity = part.AssemblyLinearVelocity
        previousEstimatedVelocity = measuredVelocity
        estimatedAcceleration = Vector3.zero
    end

    local last = motionSamples[#motionSamples]
    if not last or now - last.time >= math.max(0.016, config.predictionIntervalMs / 1000) then
        motionSamples[#motionSamples + 1] = {position = part.Position, time = now}
        while #motionSamples > 8 or (#motionSamples > 2 and now - motionSamples[1].time > 0.35) do
            table.remove(motionSamples, 1)
        end

        if #motionSamples >= 2 then
            local first = motionSamples[1]
            local newest = motionSamples[#motionSamples]
            local delta = newest.time - first.time
            if delta > 0.015 then
                local sampled = (newest.position - first.position) / delta
                if sampled.Magnitude < 150 then
                    local oldVelocity = measuredVelocity
                    measuredVelocity = measuredVelocity:Lerp(sampled, 0.55)
                    local sampleDelta = last and math.max(now - last.time, 0.016) or delta
                    local acceleration = (measuredVelocity - oldVelocity) / sampleDelta
                    if acceleration.Magnitude < 120 then
                        estimatedAcceleration = estimatedAcceleration:Lerp(acceleration, 0.25)
                    else
                        estimatedAcceleration = Vector3.zero
                    end
                    previousEstimatedVelocity = oldVelocity
                end
            end
        end
    end

    motionPosition = part.Position
    motionTime = now
end

local function calculateAim(part)
    sampleMotion(part)
    local assembly = part.AssemblyLinearVelocity
    local velocity = assembly
    local acceleration = Vector3.zero

    if config.predictLag and motionPart == part and #motionSamples >= 2 then
        local disagreement = (assembly - measuredVelocity).Magnitude
        local measuredWeight = math.clamp(0.75 - disagreement / 120, 0.35, 0.75)
        velocity = assembly:Lerp(measuredVelocity, measuredWeight)
        acceleration = estimatedAcceleration
    end

    local horizontal = config.horizontalMultiplier / 100
    local vertical = config.verticalMultiplier / 100
    local yVelocity = config.predictJump and velocity.Y * vertical or 0
    local predictedVelocity = Vector3.new(
        velocity.X * horizontal,
        yVelocity,
        velocity.Z * horizontal
    )

    local time = leadTime()
    local displacement = predictedVelocity * time

    if config.predictLag then
        local horizontalAcceleration = Vector3.new(acceleration.X, 0, acceleration.Z)
        displacement = displacement + horizontalAcceleration * (0.5 * time * time)
    end

    if config.predictJump then
        local humanoid = part.Parent and part.Parent:FindFirstChildWhichIsA("Humanoid")
        if humanoid and humanoid.FloorMaterial == Enum.Material.Air then
            displacement = displacement + Vector3.new(0, -0.5 * Workspace.Gravity * time * time, 0)
        end
    end

    if displacement.Magnitude > 18 then
        displacement = displacement.Unit * 18
    end

    local offset = Vector3.new(
        part.Size.X * config.offsetX / 100,
        part.Size.Y * config.offsetY / 100,
        part.Size.Z * config.offsetZ / 100
    )
    return part.Position + displacement + offset
end

local function targetPart()
    if not validTarget(murderer) then
        setTarget(findByKnife())
    end
    local character = murderer and murderer.Character
    return character and (
        character:FindFirstChild(config.targetPart)
        or character:FindFirstChild("HumanoidRootPart")
        or character.PrimaryPart
    )
end

local function playerHasTool(player, toolName)
    local character = player and player.Character
    local backpack = player and player:FindFirstChildOfClass("Backpack")
    return (character and character:FindFirstChild(toolName)) or (backpack and backpack:FindFirstChild(toolName))
end

local function findSheriff()
    for _, player in ipairs(Players:GetPlayers()) do
        if validTarget(player) and playerHasTool(player, "Gun") then return player end
    end
end

local function findNearestKnifeTarget()
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local closest, closestDistance
    for _, player in ipairs(Players:GetPlayers()) do
        if validTarget(player) then
            local targetCharacter = player.Character
            local targetRoot = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local distance = (targetRoot.Position - root.Position).Magnitude
                if not closestDistance or distance < closestDistance then
                    closest, closestDistance = player, distance
                end
            end
        end
    end
    return closest
end

local function knifeTargetPart()
    local player
    if config.knifePrioritizeSheriff then
        player = findSheriff()
    else
        player = findNearestKnifeTarget()
    end
    local character = player and player.Character
    return character and (
        character:FindFirstChild(config.targetPart)
        or character:FindFirstChild("HumanoidRootPart")
        or character.PrimaryPart
    )
end

local function knifeRemote(remote, args)
    if not config.knifeEnabled or args.n < 2 then return false end
    if typeof(remote) ~= "Instance" or not remote:IsA("RemoteEvent") then return false end
    if remote.Name ~= "KnifeThrown" then return false end
    if typeof(args[1]) ~= "CFrame" or typeof(args[2]) ~= "CFrame" then return false end
    local character = LocalPlayer.Character
    local knife = character and character:FindFirstChild("Knife")
    return knife ~= nil and remote:IsDescendantOf(knife)
end

local function shotRemote(remote, args)
    if not config.enabled or args.n < 2 then return false end
    if typeof(remote) ~= "Instance" or not remote:IsA("RemoteEvent") then return false end
    if typeof(args[1]) ~= "CFrame" or typeof(args[2]) ~= "CFrame" then return false end
    local character = LocalPlayer.Character
    local gun = character and character:FindFirstChild("Gun")
    return gun ~= nil and remote:IsDescendantOf(gun)
end

local function targetVisible(part)
    if not config.wallCheck then return true end
    local character = LocalPlayer.Character
    local originPart = character and (character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart"))
    if not originPart or not part then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {character}
    params.IgnoreWater = true
    local result = Workspace:Raycast(originPart.Position, part.Position - originPart.Position, params)
    return result == nil or result.Instance:IsDescendantOf(part.Parent)
end

local function calculateKnifeAim(part, origin)
    sampleMotion(part)
    local assembly = part.AssemblyLinearVelocity
    local velocity = assembly
    if config.predictLag and motionPart == part and #motionSamples >= 2 then
        velocity = assembly:Lerp(measuredVelocity, 0.65)
    end
    local horizontal = config.horizontalMultiplier / 100
    local vertical = config.verticalMultiplier / 100
    local predictedVelocity = Vector3.new(
        velocity.X * horizontal,
        config.predictJump and velocity.Y * vertical or 0,
        velocity.Z * horizontal
    )
    local distance = (part.Position - origin).Magnitude
    local travelTime = math.clamp(distance / 125, 0, 0.55)
    local time = math.clamp(leadTime() + travelTime, 0.03, 0.7)
    local offset = Vector3.new(
        part.Size.X * config.offsetX / 100,
        part.Size.Y * config.offsetY / 100,
        part.Size.Z * config.offsetZ / 100
    )
    return part.Position + predictedVelocity * time + offset
end

local function redirect(remote, args)
    local part
    local useWallCheck = false
    local isKnife = false

    if shotRemote(remote, args) then
        part = targetPart()
        useWallCheck = config.wallCheck
    elseif knifeRemote(remote, args) then
        part = knifeTargetPart()
        useWallCheck = config.knifeWallCheck
        isKnife = true
    else
        return
    end

    if not part then return end
    if useWallCheck and not targetVisible(part) then return end

    local origin = args[1].Position
    local aim = isKnife and calculateKnifeAim(part, origin) or calculateAim(part)
    if config.alignDirection and (aim - origin).Magnitude > 0.01 then
        args[1] = CFrame.lookAt(origin, aim)
    end
    args[2] = CFrame.new(aim)
    redirected = redirected + 1
end

local function findGunRemote()
    local character = LocalPlayer.Character
    local gun = character and character:FindFirstChild("Gun")
    if not gun then return nil end
    for _, object in ipairs(gun:GetDescendants()) do
        if object:IsA("RemoteEvent") then return object end
    end
end

local function shootMurderer()
    if shootBusy then return false end
    shootBusy = true
    local success = false
    pcall(function()
        if not validTarget(murderer) then refreshTarget() end
        local part = targetPart()
        local camera = Workspace.CurrentCamera
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
        if not part or not camera or not character or not humanoid then return end
        if not targetVisible(part) then return end

        local autoEquipped = false
        local gun = character:FindFirstChild("Gun")
        if not gun and backpack then
            gun = backpack:FindFirstChild("Gun")
            if gun then
                humanoid:EquipTool(gun)
                autoEquipped = true
                task.wait(0.08)
            end
        end

        local remote = findGunRemote()
        if not remote then
            if autoEquipped then humanoid:UnequipTools() end
            return
        end

        if not config.enabled then
            sampleMotion(part)
            task.wait(math.clamp(config.predictionIntervalMs / 1000, 0.025, 0.07))
            sampleMotion(part)
        end
        local aim = calculateAim(part)
        local handle = gun and gun:FindFirstChild("Handle")
        local origin = handle and handle.Position or camera.CFrame.Position
        remote:FireServer(CFrame.lookAt(origin, aim), CFrame.new(aim))
        success = true

        if autoEquipped then
            task.wait(0.12)
            if humanoid.Parent then humanoid:UnequipTools() end
        end
    end)
    shootBusy = false
    return success
end

local function removeShootButton()
    if shootGui then shootGui:Destroy() shootGui = nil shootButton = nil end
end

local function createShootButton()
    if shootButton then return end
    local parent = CoreGui
    if type(gethui) == "function" then
        local ok, result = pcall(gethui)
        if ok and typeof(result) == "Instance" then parent = result end
    end
    if typeof(parent) ~= "Instance" then
        parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    shootGui = Instance.new("ScreenGui")
    shootGui.Name = "MM2ShootMurdererButton"
    shootGui.ResetOnSpawn = false
    shootGui.IgnoreGuiInset = true
    shootGui.Parent = parent

    local button = Instance.new("TextButton")
    button.Name = "ShootMurderer"
    button.AnchorPoint = Vector2.new(0.5, 0.5)
    button.Position = UDim2.new(0.5, 0, 0.5, 0)
    button.Size = UDim2.new(0, 200, 0, 75)
    button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    button.BackgroundTransparency = 0.9
    button.BorderSizePixel = 0
    button.Text = "Shoot Murderer"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 24
    button.TextWrapped = true
    button.Font = Enum.Font.Jura
    button.ClipsDescendants = true
    button.AutoButtonColor = false
    button.ZIndex = 5
    button.Parent = shootGui
    shootButton = button

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = button
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 1.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = button
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 20)),
        ColorSequenceKeypoint.new(0.75, Color3.fromRGB(20, 20, 140)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 40, 120))
    })
    gradient.Parent = stroke
    task.spawn(function()
        while button.Parent do
            gradient.Rotation = (gradient.Rotation + 1) % 360
            RunService.RenderStepped:Wait()
        end
    end)

    local ripple = Instance.new("Frame")
    ripple.Name = "@ripple"
    ripple.BackgroundColor3 = Color3.fromRGB(0, 155, 255)
    ripple.BackgroundTransparency = 1
    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
    ripple.Size = UDim2.new(0, 0, 0, 0)
    ripple.Visible = false
    ripple.ZIndex = 4
    ripple.Parent = button
    local rippleCorner = Instance.new("UICorner")
    rippleCorner.CornerRadius = UDim.new(1, 0)
    rippleCorner.Parent = ripple

    local sound = Instance.new("Sound")
    sound.Name = "Sound"
    sound.SoundId = "rbxassetid://3868133279"
    sound.Volume = 0.5
    sound.Parent = button

    local normalSize = UDim2.new(0, 200, 0, 75)
    local pressedSize = UDim2.new(0, 220, 0, 82)
    local pressTween = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    local dragging = false
    local moved = false
    local dragStart
    local startPosition
    local dragInput

    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = not config.lockShootButton
            moved = false
            dragStart = input.Position
            startPosition = button.Position

            TweenService:Create(button, pressTween, {Size = pressedSize, TextSize = 26}):Play()
            sound:Play()
            local absolute = button.AbsolutePosition
            ripple.Position = UDim2.new(0, input.Position.X - absolute.X, 0, input.Position.Y - absolute.Y)
            ripple.Size = UDim2.new(0, 0, 0, 0)
            ripple.BackgroundTransparency = 0.45
            ripple.Visible = true
            TweenService:Create(ripple, TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 300, 0, 300),
                BackgroundTransparency = 1
            }):Play()
        end
    end)
    button.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput and not config.lockShootButton then
            local delta = input.Position - dragStart
            if delta.Magnitude > 8 then moved = true end
            button.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            TweenService:Create(button, pressTween, {Size = normalSize, TextSize = 24}):Play()
        end
    end)
    button.Activated:Connect(function()
        if not moved then shootMurderer() end
    end)
end

local function setShootButtonVisible(value)
    config.showShootButton = value == true
    if config.showShootButton then createShootButton() else removeShootButton() end
end

local function installHook()
    if hooked then return true end
    if type(hookfunction) ~= "function" then
        notify("hookfunction is unavailable", 6)
        return false
    end
    local wrap = type(newcclosure) == "function" and newcclosure or function(callback) return callback end
    local probe = Instance.new("RemoteEvent")
    local original
    local ok, err = pcall(function()
        original = hookfunction(probe.FireServer, wrap(function(self, ...)
            local args = table.pack(...)
            pcall(redirect, self, args)
            return original(self, table.unpack(args, 1, args.n))
        end))
    end)
    probe:Destroy()
    if not ok then
        notify("Hook failed: " .. tostring(err), 6)
        return false
    end
    hooked = true
    return true
end

local function toggle(value)
    config.enabled = value == true
    if config.enabled then
        if not installHook() then config.enabled = false return end
        task.spawn(refreshTarget)
        notify("Enabled", 2)
    else
        notify("Disabled", 2)
    end
end

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
local gameplay = remotes and remotes:FindFirstChild("Gameplay")
if gameplay then
    local roundEnd = gameplay:FindFirstChild("RoundEndFade")
    if roundEnd and roundEnd:IsA("RemoteEvent") then
        roundEnd.OnClientEvent:Connect(function() murderer = nil end)
    end
    for _, name in ipairs({"Fade", "PlayerDataChanged", "RoleSelect", "RoundStart"}) do
        local event = gameplay:FindFirstChild(name)
        if event and event:IsA("RemoteEvent") then
            event.OnClientEvent:Connect(function(...)
                local found = false
                for index = 1, select("#", ...) do
                    local value = select(index, ...)
                    if typeof(value) == "table" and consumeData(value) then found = true break end
                end
                if not found then task.delay(0.35, refreshTarget) end
            end)
        end
    end
end

Players.PlayerRemoving:Connect(function(player)
    if player == murderer then murderer = nil end
end)

task.spawn(function()
    while running do
        updatePing()
        autoTuneForPing()
        if config.enabled then
            if not validTarget(murderer) then setTarget(findByKnife()) end
            local part = targetPart()
            if part then sampleMotion(part) end
        end
        task.wait(math.clamp(config.predictionIntervalMs / 1000, 0.016, 2))
    end
end)

local function cleanPresetName(name)
    name = tostring(name or "default"):gsub("%.preset$", ""):gsub("[^%w_%- ]", "_")
    return name ~= "" and name or "default"
end

local function ensurePresetFolder()
    if type(makefolder) ~= "function" then return end
    pcall(makefolder, "Ixry Shizuka")
    pcall(makefolder, PRESET_FOLDER)
end

local function xorPreset(data)
    local output = table.create(#data)
    for index = 1, #data do
        output[index] = string.char(bit32.bxor(string.byte(data, index), 40))
    end
    return table.concat(output)
end

local function exportRevertConfig()
    return {
        cfg = {
            predict_jump = config.predictJump,
            prediction_ping = config.manualPingMs,
            y_pos_offset = config.offsetY / 100,
            prioritize_your_ping = config.prioritizePing,
            horizontal_multiplier = config.horizontalMultiplier / 100,
            vertical_multiplier = config.verticalMultiplier / 100,
            max_simulation_time = config.maxSimulationMs,
            interval = config.predictionIntervalMs / 10000,
            z_pos_offset = config.offsetZ / 100,
            predict_lag = config.predictLag,
            x_pos_offset = config.offsetX / 100,
        },
        author = LocalPlayer.Name,
        game = "Murder Mystery 2",
        category = "gun",
    }
end

local function applyRevertConfig(data)
    local cfg = typeof(data) == "table" and data.cfg
    if typeof(cfg) ~= "table" then return false end
    if typeof(cfg.predict_jump) == "boolean" then
        config.predictJump = cfg.predict_jump
        if cfg.predict_jump then config.horizontalOnly = false end
    end
    if typeof(cfg.prediction_ping) == "number" then config.manualPingMs = cfg.prediction_ping end
    if typeof(cfg.prioritize_your_ping) == "boolean" then config.prioritizePing = cfg.prioritize_your_ping end
    if typeof(cfg.horizontal_multiplier) == "number" then config.horizontalMultiplier = cfg.horizontal_multiplier * 100 end
    if typeof(cfg.vertical_multiplier) == "number" then config.verticalMultiplier = cfg.vertical_multiplier * 100 end
    if typeof(cfg.max_simulation_time) == "number" then config.maxSimulationMs = cfg.max_simulation_time end
    if typeof(cfg.interval) == "number" then config.predictionIntervalMs = cfg.interval * 10000 end
    if typeof(cfg.x_pos_offset) == "number" then config.offsetX = cfg.x_pos_offset * 100 end
    if typeof(cfg.y_pos_offset) == "number" then config.offsetY = cfg.y_pos_offset * 100 end
    if typeof(cfg.z_pos_offset) == "number" then config.offsetZ = cfg.z_pos_offset * 100 end
    if typeof(cfg.predict_lag) == "boolean" then config.predictLag = cfg.predict_lag end
    return true
end

local function savePreset()
    if type(writefile) ~= "function" then return end
    ensurePresetFolder()
    local ok, encoded = pcall(function() return HttpService:JSONEncode(exportRevertConfig()) end)
    if ok then
        pcall(writefile, PRESET_FOLDER .. "/" .. cleanPresetName(presetName) .. ".preset", xorPreset(encoded))
    end
end

local function loadPreset()
    if type(readfile) ~= "function" then return end
    local path = PRESET_FOLDER .. "/" .. cleanPresetName(presetName) .. ".preset"
    local ok, decoded = pcall(function()
        local raw = readfile(path)
        return HttpService:JSONDecode(xorPreset(raw))
    end)
    if ok and applyRevertConfig(decoded) then
        if type(syncRevertControls) == "function" then syncRevertControls() end
    end
end

local function presetNames()
    local names = {"default"}
    if type(listfiles) == "function" then
        ensurePresetFolder()
        local ok, files = pcall(listfiles, PRESET_FOLDER)
        if ok and typeof(files) == "table" then
            for _, file in ipairs(files) do
                local name = tostring(file):match("([^/\\]+)%.preset$")
                if name and not table.find(names, name) then names[#names + 1] = name end
            end
        end
    end
    table.sort(names)
    return names
end

local tab = host.CreateTab("Noir slient aim", "/mellnikovden968-web/CFG_PM2/refs/heads/main/icon")
local main = tab:AddSection("Noir slient aim", "")
main:AddToggle("Enabled", toggle)
main:AddToggle("Wall Check", function(value) config.wallCheck = value == true end)
local knifeSection = tab:AddSection("Knife Silent Aim", "")
knifeSection:AddToggle("Knife Silent Aim", function(value) config.knifeEnabled = value == true; if config.knifeEnabled then installHook() end end)
knifeSection:AddToggle("Knife Wall Check", function(value) config.knifeWallCheck = value == true end)
knifeSection:AddToggle("Prioritize Sheriff", function(value) config.knifePrioritizeSheriff = value == true end)

local shootSection = tab:AddSection("Shoot Murderer", "Mobile shoot button")
shootSection:AddToggle("Show Shoot Murderer Button", setShootButtonVisible)
shootSection:AddToggle("Lock Shoot Murderer Button", function(value)
    config.lockShootButton = value == true
    notify(config.lockShootButton and "Shoot button locked" or "Shoot button unlocked", 2)
end)
shootSection:AddButton("Shoot Murderer Now", shootMurderer)

local revert = tab:AddSection("NOIR CONFIG", "Standalone Silent Aim settings; .preset-compatible")
revert:AddDropdown("Your Presets", presetNames(), function(value) presetName = cleanPresetName(value) end)
if type(revert.AddTextBox) == "function" then
    revert:AddTextBox("Preset Name", function(value) presetName = cleanPresetName(value) end)
else
    revert:AddDropdown("Preset Name", {"default", "best", "mobile", "custom1", "custom2"}, function(value) presetName = value end)
end
revert:AddButton("Save Preset", savePreset)
revert:AddButton("Load Preset", loadPreset)
local function addTrackedToggle(key, label, callback)
    revertToggleStates[key] = false
    local toggle = revert:AddToggle(label, function(value)
        local state = value == true
        revertToggleStates[key] = state
        callback(state)
    end)
    revertControls[key] = toggle
end

local function addTrackedSlider(key, label, minimum, maximum, default, callback)
    local slider = revert:AddSlider(label, minimum, maximum, default, function(value)
        callback(tonumber(value) or default)
    end)
    revertControls[key] = slider
end

addTrackedToggle("prioritizePing", "Prioritize Your Ping", function(value) config.prioritizePing = value end)
addTrackedToggle("predictJump", "Predict Jump", function(value) config.predictJump = value end)
addTrackedToggle("predictLag", "Predict Lag", function(value) config.predictLag = value end)
addTrackedSlider("maxSimulationMs", "Prediction Max Simulation Time", 20, 300, 180, function(value) config.maxSimulationMs = value end)
addTrackedSlider("predictionIntervalMs", "Prediction Interval", 1, 100, 72, function(value) config.predictionIntervalMs = value end)
addTrackedSlider("manualPingMs", "Prediction Ping", 10, 350, 80, function(value) config.manualPingMs = value end)
addTrackedSlider("offsetX", "X Position Offset (%)", -100, 100, 0, function(value) config.offsetX = value end)
addTrackedSlider("offsetY", "Y Position Offset (%)", -100, 100, 0, function(value) config.offsetY = value end)
addTrackedSlider("offsetZ", "Z Position Offset (%)", -100, 100, 0, function(value) config.offsetZ = value end)
addTrackedSlider("horizontalMultiplier", "Prediction Horizontal Multiplier (%)", 0, 400, 100, function(value) config.horizontalMultiplier = value end)
addTrackedSlider("verticalMultiplier", "Prediction Vertical Multiplier (%)", 0, 400, 100, function(value) config.verticalMultiplier = value end)

syncRevertControls = function(syncToggles)
    if syncToggles ~= false then
        for _, key in ipairs({"prioritizePing", "predictJump", "predictLag"}) do
            local desired = config[key] == true
            local toggle = revertControls[key]
            if type(toggle) == "function" and revertToggleStates[key] ~= desired then
                pcall(toggle)
            end
        end
    end
    for _, key in ipairs({
        "maxSimulationMs", "predictionIntervalMs", "manualPingMs",
        "offsetX", "offsetY", "offsetZ", "horizontalMultiplier", "verticalMultiplier"
    }) do
        local control = revertControls[key]
        if type(control) == "table" and type(control.SetValue) == "function" then
            pcall(control.SetValue, control, config[key])
        elseif type(control) == "function" then
            pcall(control, config[key])
        end
    end
end



notify("Lite V3 ready; feature is OFF", 4)
