 
local __noirVisualContext = {
    tab = tab, players = Players, workspace = Workspace, runService = RunService,
    localPlayer = LocalPlayer, getPlayers = getPlayers, roleCache = roleCache, roleBus = getgenv().__NoirV4RoleBus,
    getMurderer = function() return murderer end, getSheriff = function() return sheriff end,
    getHero = function() return hero end, getRoundState = function() return roundState end,
     
    refreshRoles = function(force) refreshTarget(force == true) end,
    isRoleRevealActive = function()
        if murderer or sheriff or hero then return true end
        for _, role in pairs(roleCache) do
            if role == "murderer" or role == "sheriff" or role == "hero" then return true end
        end
        return false
    end,
    isRunning = function() return running end,
}
getgenv().__NoirV4VisualContext = __noirVisualContext
local __noirVisualSource = "-- Visuals run in a deferred satellite chunk.  Updates are event-driven so ESP does not rescan Workspace each fraction of a second.\nlocal V = getgenv().__NoirV4VisualContext\nif type(V) ~= \"table\" or not V.tab then return end\n\nlocal state = {\n    revision = 0, playersDirty = true,\n    feature = {\n        cham = {everyone=false,murderer=false,sheriff=false,hero=false,dead=false},\n        esp = {everyone=false,murderer=false,sheriff=false,hero=false,dead=false},\n        outline = {everyone=false,murderer=false,sheriff=false,hero=false,dead=false},\n        highlight = {everyone=false,murderer=false,sheriff=false,hero=false,dead=false},\n        tracer = {everyone=false,murderer=false,sheriff=false,hero=false,dead=false},\n        box = {everyone=false,murderer=false,sheriff=false,hero=false,dead=false},\n        avatar = {everyone=false,murderer=false,sheriff=false,hero=false,dead=false},\n        fire = {everyone=false,murderer=false,sheriff=false,hero=false,dead=false},\n    },\n    object = {gun=false,knife=false},\n}\nlocal entries, objectEntries, thumbnailCache, thumbnailPending = {}, {}, {}, {}\nlocal joinedLobby, roleRevealActive, drawingState, tracerCount = {}, false, nil, 0\nlocal prefix = \"NoirSatelliteVisual_\"\n\nlocal function safe(label, callback)\n    local ok, err = pcall(callback)\n    if not ok then warn(\"[Noir Visuals] \" .. tostring(label) .. \": \" .. tostring(err)) end\n    return ok\nend\nlocal function markPlayersDirty()\n    state.playersDirty = true\nend\nif V.roleBus and V.roleBus.Subscribe then V.roleBus:Subscribe(markPlayersDirty) end\n-- MM2 can finish assigning roles a moment after the UI appears. Requests are coalesced by the main scanner.\ntask.spawn(function()\n    for _, pause in ipairs({0, .7, 1.8}) do\n        if pause > 0 then task.wait(pause) end\n        if V.refreshRoles then V.refreshRoles(false) end\n    end\nend)\n\nlocal function color(role)\n    if role == \"murderer\" then return Color3.fromRGB(255,72,82) end\n    if role == \"sheriff\" then return Color3.fromRGB(72,158,255) end\n    if role == \"hero\" then return Color3.fromRGB(255,206,72) end\n    if role == \"dead\" then return Color3.fromRGB(150,150,158) end\n    return Color3.fromRGB(86,230,145)\nend\nlocal function isInactive(player, character, cached)\n    if cached == \"dead\" or joinedLobby[player] then return true end\n    local round = V.getRoundState and V.getRoundState() or \"waiting\"\n    if round == \"waiting\" and not (V.isRoleRevealActive and V.isRoleRevealActive()) then return true end\n    local teamName = player.Team and string.lower(tostring(player.Team.Name)) or \"\"\n    if string.find(teamName,\"lobby\",1,true) or string.find(teamName,\"spectat\",1,true) or string.find(teamName,\"waiting\",1,true) or string.find(teamName,\"observer\",1,true) then return true end\n    for _, container in ipairs({player, character}) do\n        if container then\n            for key, value in pairs(container:GetAttributes()) do\n                local name = string.lower(tostring(key))\n                if (string.find(name,\"inround\",1,true) or string.find(name,\"ingame\",1,true) or string.find(name,\"isplaying\",1,true) or string.find(name,\"alive\",1,true)) and value == false then return true end\n                if string.find(name,\"state\",1,true) or string.find(name,\"status\",1,true) or string.find(name,\"location\",1,true) then\n                    local text = string.lower(tostring(value))\n                    if string.find(text,\"lobby\",1,true) or string.find(text,\"spectat\",1,true) or string.find(text,\"dead\",1,true) or string.find(text,\"waiting\",1,true) then return true end\n                end\n            end\n            for _, name in ipairs({\"InLobby\",\"Spectating\",\"Dead\",\"IsDead\"}) do\n                local flag = container:FindFirstChild(name)\n                if flag and flag:IsA(\"BoolValue\") and flag.Value then return true end\n            end\n        end\n    end\n    return false\nend\nlocal function roleOf(player, character)\n    local humanoid = character and character:FindFirstChildWhichIsA(\"Humanoid\")\n    local cached = V.roleCache and V.roleCache[player.UserId]\n    if not humanoid or humanoid.Health <= 0 or isInactive(player, character, cached) then return \"dead\" end\n    if player == V.getMurderer() or cached == \"murderer\" then return \"murderer\" end\n    if player == V.getSheriff() or cached == \"sheriff\" then return \"sheriff\" end\n    if player == V.getHero() or cached == \"hero\" then return \"hero\" end\n    return \"innocent\"\nend\nlocal function wanted(kind, role)\n    local filters = state.feature[kind]\n    return filters and (filters.everyone or filters[role]) or false\nend\nlocal function anyPlayerVisual()\n    for _, filters in pairs(state.feature) do for _, enabled in pairs(filters) do if enabled then return true end end end\n    return false\nend\nlocal function clearPlayer(player)\n    local entry = entries[player]\n    if not entry then return end\n    if entry.line then tracerCount = math.max(0, tracerCount - 1); pcall(function() entry.line:Remove() end) end\n    for _, item in ipairs(entry.items) do pcall(function() item:Destroy() end) end\n    entries[player] = nil\nend\nlocal function addHighlight(character, suffix, tint, fill, outline, entry)\n    local h = Instance.new(\"Highlight\")\n    h.Name, h.Adornee, h.DepthMode = prefix .. suffix, character, Enum.HighlightDepthMode.AlwaysOnTop\n    h.FillColor, h.OutlineColor, h.FillTransparency, h.OutlineTransparency, h.Parent = tint, tint, fill, outline, character\n    table.insert(entry.items, h)\nend\nlocal function billboard(root, suffix, size, offset, entry)\n    local b = Instance.new(\"BillboardGui\")\n    b.Name, b.Adornee, b.AlwaysOnTop, b.Size, b.StudsOffset, b.Parent = prefix .. suffix, root, true, size, offset, root\n    table.insert(entry.items, b)\n    return b\nend\nlocal function loadAvatar(player, image)\n    local cached = thumbnailCache[player.UserId]\n    if cached then image.Image = cached; return end\n    if thumbnailPending[player.UserId] then return end\n    thumbnailPending[player.UserId] = true\n    task.spawn(function()\n        local ok, asset = pcall(function() return V.players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150) end)\n        thumbnailPending[player.UserId] = nil\n        if ok and asset then\n            thumbnailCache[player.UserId] = asset\n            if image.Parent then image.Image = asset end\n        end\n    end)\nend\nlocal function apply(player, enabled)\n    if player == V.localPlayer then return end\n    local character = player.Character\n    if not character then clearPlayer(player); return end\n    local root = character:FindFirstChild(\"HumanoidRootPart\") or character:FindFirstChild(\"UpperTorso\") or character:FindFirstChild(\"Torso\")\n    local role = roleOf(player, character)\n    local sign = tostring(state.revision) .. \":\" .. role .. \":\" .. tostring(root)\n    local old = entries[player]\n    if old and old.character == character and old.sign == sign then return end\n    clearPlayer(player)\n    if not enabled then return end\n    local tint = color(role)\n    local entry = {character=character, root=root, sign=sign, tint=tint, items={}, line=nil}\n    entries[player] = entry\n    if wanted(\"cham\",role) then addHighlight(character,\"Cham\",tint,.45,1,entry) end\n    if wanted(\"outline\",role) then addHighlight(character,\"Outline\",tint,1,0,entry) end\n    if wanted(\"highlight\",role) then addHighlight(character,\"Highlight\",tint,.68,.05,entry) end\n    if wanted(\"tracer\",role) then\n        if drawingState == nil then\n            local ok, api = pcall(function() return Drawing end)\n            drawingState = ok and type(api) == \"table\" and type(api.new) == \"function\" and api or false\n        end\n        if drawingState then\n            local line = drawingState.new(\"Line\")\n            line.Thickness, line.Transparency, line.Color, line.Visible = 1.5, 1, tint, false\n            entry.line, tracerCount = line, tracerCount + 1\n        end\n    end\n    if root and wanted(\"esp\",role) then\n        local b = billboard(root,\"ESP\",UDim2.fromOffset(156,42),Vector3.new(0,3.4,0),entry)\n        local l = Instance.new(\"TextLabel\")\n        l.Size, l.BackgroundTransparency, l.Font, l.TextSize = UDim2.fromScale(1,1), 1, Enum.Font.GothamSemibold, 14\n        l.TextColor3, l.TextStrokeTransparency, l.Text, l.Parent = Color3.new(1,1,1), .35, player.DisplayName .. \"\\n\" .. string.upper(role), b\n    end\n    if root and wanted(\"box\",role) then\n        local b = billboard(root,\"Box\",UDim2.fromOffset(86,122),Vector3.new(0,1.8,0),entry)\n        local f = Instance.new(\"Frame\")\n        f.Size, f.BackgroundTransparency, f.Parent = UDim2.fromScale(1,1), 1, b\n        local stroke = Instance.new(\"UIStroke\")\n        stroke.Color, stroke.Thickness, stroke.Parent = tint, 1.7, f\n    end\n    if root and wanted(\"avatar\",role) then\n        local b = billboard(root,\"Avatar\",UDim2.fromOffset(58,58),Vector3.new(0,4.8,0),entry)\n        local image = Instance.new(\"ImageLabel\")\n        image.Size, image.BackgroundColor3, image.BorderSizePixel, image.Parent = UDim2.fromScale(1,1), Color3.fromRGB(12,14,18), 0, b\n        local corner = Instance.new(\"UICorner\"); corner.CornerRadius, corner.Parent = UDim.new(1,0), image\n        local stroke = Instance.new(\"UIStroke\"); stroke.Color, stroke.Thickness, stroke.Parent = tint, 1.5, image\n        loadAvatar(player, image)\n    end\n    if root and wanted(\"fire\",role) then\n        local flame = Instance.new(\"Fire\")\n        flame.Name, flame.Color, flame.SecondaryColor, flame.Size, flame.Heat, flame.Parent = prefix..\"Fire\", tint, tint:Lerp(Color3.new(1,1,1),.35), 5, 7, root\n        table.insert(entry.items, flame)\n    end\nend\nlocal function refreshPlayers()\n    local enabled, seen = anyPlayerVisual(), {}\n    for _, player in ipairs(V.getPlayers()) do if player ~= V.localPlayer then seen[player] = true; apply(player, enabled) end end\n    for player in pairs(entries) do if not seen[player] then clearPlayer(player) end end\n    state.playersDirty = false\nend\n\nlocal function objectType(instance)\n    if not instance:IsA(\"BasePart\") then return nil end\n    local owner = instance:FindFirstAncestorOfClass(\"Model\")\n    if owner and V.players:GetPlayerFromCharacter(owner) then return nil end\n    local name = string.lower(instance.Name)\n    if name == \"gundrop\" or name == \"gun\" or string.find(name,\"droppedgun\",1,true) or string.find(name,\"gun_drop\",1,true) then return \"gun\" end\n    if string.find(name,\"throw\",1,true) and string.find(name,\"knife\",1,true) then return \"knife\" end\nend\nlocal function clearObject(instance)\n    local entry = objectEntries[instance]\n    if entry then for _, item in ipairs(entry) do pcall(function() item:Destroy() end) end; objectEntries[instance] = nil end\nend\nlocal function trackObject(instance)\n    local kind = objectType(instance)\n    if not kind or not state.object[kind] then\n        if objectEntries[instance] then clearObject(instance) end\n        return\n    end\n    if objectEntries[instance] then return end\n    local tint = kind == \"gun\" and Color3.fromRGB(72,158,255) or Color3.fromRGB(255,126,72)\n    local h = Instance.new(\"Highlight\")\n    h.Name, h.Adornee, h.DepthMode = prefix..\"Object\", instance, Enum.HighlightDepthMode.AlwaysOnTop\n    h.FillColor, h.OutlineColor, h.FillTransparency, h.OutlineTransparency, h.Parent = tint, tint, .72, 0, instance\n    local b = Instance.new(\"BillboardGui\")\n    b.Name, b.Adornee, b.AlwaysOnTop, b.Size, b.StudsOffset, b.Parent = prefix..\"ObjectLabel\", instance, true, UDim2.fromOffset(132,24), Vector3.new(0,1.5,0), instance\n    local l = Instance.new(\"TextLabel\")\n    l.Size, l.BackgroundTransparency, l.Font, l.TextSize, l.TextColor3, l.TextStrokeTransparency, l.Text, l.Parent = UDim2.fromScale(1,1),1,Enum.Font.GothamBold,12,tint,.35,(kind==\"gun\" and \"DROPPED GUN\" or \"THROWING KNIFE\"),b\n    objectEntries[instance] = {h,b}\nend\nlocal function refreshObjects(fullScan)\n    if fullScan and (state.object.gun or state.object.knife) then for _, instance in ipairs(V.workspace:GetDescendants()) do trackObject(instance) end end\n    for instance in pairs(objectEntries) do\n        local kind = instance.Parent and objectType(instance)\n        if not kind or not state.object[kind] then clearObject(instance) end\n    end\nend\nlocal function setFilter(kind, filter, enabled)\n    state.feature[kind][filter] = enabled == true\n    state.revision, state.playersDirty = state.revision + 1, true\n    safe(\"player refresh\", refreshPlayers)\nend\nlocal objectAddedConnection, objectRemovingConnection\nlocal function updateObjectConnections()\n    local enabled = state.object.gun or state.object.knife\n    if enabled then\n        if not objectAddedConnection then\n            objectAddedConnection = V.workspace.DescendantAdded:Connect(function(instance)\n                if state.object.gun or state.object.knife then task.defer(trackObject, instance) end\n            end)\n        end\n        if not objectRemovingConnection then\n            objectRemovingConnection = V.workspace.DescendantRemoving:Connect(function(instance)\n                if objectEntries[instance] then clearObject(instance) end\n            end)\n        end\n    else\n        if objectAddedConnection then objectAddedConnection:Disconnect(); objectAddedConnection = nil end\n        if objectRemovingConnection then objectRemovingConnection:Disconnect(); objectRemovingConnection = nil end\n    end\nend\nlocal function setObject(kind, enabled)\n    state.object[kind] = enabled == true\n    updateObjectConnections()\n    safe(\"object refresh\", function() refreshObjects(true) end)\nend\n\nlocal tracerElapsed = 0\nV.runService.RenderStepped:Connect(function(dt)\n    if tracerCount <= 0 then tracerElapsed = 0; return end\n    tracerElapsed += dt\n    if tracerElapsed < (1 / 30) then return end\n    tracerElapsed = 0\n    local camera = V.workspace.CurrentCamera\n    if not camera then return end\n    local viewport, origin = camera.ViewportSize, Vector2.new(camera.ViewportSize.X*.5,camera.ViewportSize.Y)\n    for _, entry in pairs(entries) do\n        local line, root = entry.line, entry.root\n        if line then\n            if root and root.Parent and root:IsDescendantOf(entry.character) then\n                local point, visible = camera:WorldToViewportPoint(root.Position)\n                line.From, line.To, line.Color, line.Visible = origin, Vector2.new(point.X,point.Y), entry.tint, visible and point.Z > 0\n            else line.Visible = false end\n        end\n    end\nend)\nlocal function watchCharacter(player, character)\n    markPlayersDirty()\n    task.defer(function()\n        local humanoid = character and character:FindFirstChildWhichIsA(\"Humanoid\")\n        if humanoid then humanoid.Died:Connect(markPlayersDirty) end\n    end)\nend\nfor _, player in ipairs(V.getPlayers()) do\n    if player.Character then watchCharacter(player, player.Character) end\n    player.CharacterAdded:Connect(function(character) watchCharacter(player, character) end)\nend\nV.players.PlayerAdded:Connect(function(player)\n    if V.isRoleRevealActive and V.isRoleRevealActive() then joinedLobby[player] = true end\n    player.CharacterAdded:Connect(function(character) watchCharacter(player, character) end)\n    markPlayersDirty()\nend)\nV.players.PlayerRemoving:Connect(function(player)\n    joinedLobby[player] = nil\n    clearPlayer(player)\nend)\ntask.spawn(function()\n    while V.isRunning() do\n        local revealing = V.isRoleRevealActive and V.isRoleRevealActive() or false\n        if revealing and not roleRevealActive then table.clear(joinedLobby); markPlayersDirty() end\n        if revealing ~= roleRevealActive then markPlayersDirty() end\n        roleRevealActive = revealing\n        -- Event changes refresh immediately; this slow fallback covers unusual maps that do not signal character state changes.\n        if state.playersDirty or anyPlayerVisual() then safe(\"player update\", refreshPlayers) end\n        if next(objectEntries) then safe(\"object cleanup\", function() refreshObjects(false) end) end\n        task.wait(1)\n    end\n    if objectAddedConnection then pcall(function() objectAddedConnection:Disconnect() end); objectAddedConnection = nil end\n    if objectRemovingConnection then pcall(function() objectRemovingConnection:Disconnect() end); objectRemovingConnection = nil end\n    for instance in pairs(objectEntries) do clearObject(instance) end\nend)\n\nlocal filters = {{\"Everyone\",\"everyone\"},{\"Murderer Only\",\"murderer\"},{\"Sheriff Only\",\"sheriff\"},{\"Hero Only\",\"hero\"},{\"Dead Only\",\"dead\"}}\nfor _, definition in ipairs({{\"CHAM\",\"cham\"},{\"ESP\",\"esp\"},{\"OUTLINE\",\"outline\"},{\"HIGHLIGHT\",\"highlight\"},{\"TRACER\",\"tracer\"},{\"ESP BOX\",\"box\"},{\"ESP AVATAR\",\"avatar\"},{\"ESP FIRE\",\"fire\"}}) do\n    local title, kind = definition[1], definition[2]\n    local section = V.tab:AddSection(\"VISUAL \\u{2022} \"..title,\"BY PLAYER\")\n    for _, filterDefinition in ipairs(filters) do\n        local label, filter = filterDefinition[1], filterDefinition[2]\n        section:AddToggle(label,function(enabled) safe(\"toggle\",function() setFilter(kind,filter,enabled) end) end)\n    end\nend\nlocal objects = V.tab:AddSection(\"VISUAL \\u{2022} BY OBJECT\",\"Object ESP\")\nobjects:AddToggle(\"Dropped Gun\",function(enabled) safe(\"object toggle\",function() setObject(\"gun\",enabled) end) end)\nobjects:AddToggle(\"Throwing Knives\",function(enabled) safe(\"object toggle\",function() setObject(\"knife\",enabled) end) end)\n\n"
task.defer(function()
    local compiler = loadstring
    if type(compiler) ~= "function" then
        warn("[Noir Visuals] loadstring is unavailable; main Noir loaded without the optional Visuals module.")
        return
    end
    local okCompile, module = pcall(compiler, __noirVisualSource)
    if not okCompile or type(module) ~= "function" then
        warn("[Noir Visuals] module compile failed: " .. tostring(module))
        return
    end
    local okRun, err = xpcall(module, function(message) return tostring(message) end)
    if not okRun then warn("[Noir Visuals] module startup failed: " .. tostring(err)) end
end)



 
getgenv().__NoirMovementContext = {
    tab = tab, players = Players, uis = UIS, runService = RunService, workspace = Workspace,
    localPlayer = LocalPlayer, persistence = NoirPersistence, guiParent = guiParent, coreGui = CoreGui,
    blackhole = __NOIR_GUARD.blackhole, isPrimaryPress = isPrimaryPress,
}
task.defer(function()
    local __noirMovementSource = "-- Noclip and Fly run in an isolated module to avoid the mobile Luau register limit in the main loader.\nlocal M = getgenv().__NoirMovementContext\nif type(M) ~= \"table\" or not M.tab or not M.persistence then return end\n\nlocal Players, UIS, RunService, Workspace = M.players, M.uis, M.runService, M.workspace\nlocal LocalPlayer, Persistence = M.localPlayer, M.persistence\nlocal Blackhole = M.blackhole\nlocal state = {\n    noclip = false, noclipOriginals = {},\n    fly = false, flyVelocity = nil, flyGyro = nil, flyConnection = nil,\n    flyHumanoid = nil, flyAutoRotate = true, flyPlatformStand = false,\n    flyStateEnabled = {}, flyAnimate = nil, flyAnimateDisabled = false,\n    flySpeed = 48,\n}\n-- Uses the supplied universal-fly method: PlatformStand plus BodyGyro/BodyVelocity\n-- on UpperTorso (R15) or Torso (R6), with Humanoid:TranslateBy movement.\nlocal FLY_STATES = {\n    Enum.HumanoidStateType.Climbing, Enum.HumanoidStateType.FallingDown,\n    Enum.HumanoidStateType.Flying, Enum.HumanoidStateType.Freefall,\n    Enum.HumanoidStateType.GettingUp, Enum.HumanoidStateType.Jumping,\n    Enum.HumanoidStateType.Landed, Enum.HumanoidStateType.Physics,\n    Enum.HumanoidStateType.PlatformStanding, Enum.HumanoidStateType.Ragdoll,\n    Enum.HumanoidStateType.Running, Enum.HumanoidStateType.RunningNoPhysics,\n    Enum.HumanoidStateType.Seated, Enum.HumanoidStateType.StrafingNoPhysics,\n    Enum.HumanoidStateType.Swimming,\n}\n\nlocal function applyNoclip()\n    if not state.noclip then return end\n    local character = LocalPlayer.Character\n    if not character then return end\n    for _, part in ipairs(character:GetDescendants()) do\n        if part:IsA(\"BasePart\") then\n            if state.noclipOriginals[part] == nil then state.noclipOriginals[part] = part.CanCollide end\n            if part.CanCollide then part.CanCollide = false end\n        end\n    end\nend\nlocal function restoreNoclip()\n    for part, original in pairs(state.noclipOriginals) do\n        if part and part.Parent then pcall(function() part.CanCollide = original end) end\n    end\n    table.clear(state.noclipOriginals)\nend\nlocal function setNoclip(enabled)\n    state.noclip = enabled == true\n    if state.noclip then applyNoclip() else restoreNoclip() end\nend\nRunService.Stepped:Connect(function() if state.noclip then applyNoclip() end end)\n\nlocal function restoreFlyCharacter()\n    local humanoid = state.flyHumanoid\n    if humanoid and humanoid.Parent then\n        humanoid.AutoRotate = state.flyAutoRotate\n        humanoid.PlatformStand = state.flyPlatformStand\n        for _, stateType in ipairs(FLY_STATES) do\n            local wasEnabled = state.flyStateEnabled[stateType.Name]\n            if wasEnabled ~= nil then pcall(function() humanoid:SetStateEnabled(stateType, wasEnabled) end) end\n        end\n        if not state.flyPlatformStand then\n            pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end)\n            task.delay(.08, function()\n                if humanoid.Parent and not state.fly then pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Running) end) end\n            end)\n        else\n            pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Running) end)\n        end\n    end\n    if state.flyAnimate and state.flyAnimate.Parent then state.flyAnimate.Disabled = state.flyAnimateDisabled end\n    state.flyHumanoid, state.flyAnimate = nil, nil\n    table.clear(state.flyStateEnabled)\nend\n\nlocal function stopFly()\n    if state.flyConnection then state.flyConnection:Disconnect(); state.flyConnection = nil end\n    if state.flyVelocity then state.flyVelocity:Destroy(); state.flyVelocity = nil end\n    if state.flyGyro then state.flyGyro:Destroy(); state.flyGyro = nil end\n    restoreFlyCharacter()\nend\n\nlocal function startFly()\n    stopFly()\n    if not state.fly then return end\n    local character = LocalPlayer.Character\n    local humanoid = character and character:FindFirstChildWhichIsA(\"Humanoid\")\n    local root = character and character:FindFirstChild(\"HumanoidRootPart\")\n    -- The linked script handles R15 UpperTorso and R6 Torso.  HumanoidRootPart is used here\n    -- for the constraints because it prevents the torso/root physics fight that causes shaking.\n    local sourceTorso = character and (character:FindFirstChild(\"UpperTorso\") or character:FindFirstChild(\"Torso\"))\n    if not (humanoid and root and (sourceTorso or root)) then return end\n\n    -- Keep the source's BodyVelocity flight core, but leave Roblox's humanoid states and animation system intact.\n    -- Disabling them (and forcing a BodyGyro at the camera angle) is what caused the visible body rocking.\n    state.flyHumanoid, state.flyAutoRotate, state.flyPlatformStand = humanoid, humanoid.AutoRotate, humanoid.PlatformStand\n    humanoid.AutoRotate = false\n    -- PlatformStand is needed for a Humanoid avatar to physically pitch with the camera.\n    humanoid.PlatformStand = true\n    pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Physics) end)\n\n    -- Full 3D camera orientation: use the linked Fly's high-response gyro settings for quick camera following.\n    local gyro = Instance.new(\"BodyGyro\")\n    gyro.Name, gyro.P, gyro.D, gyro.MaxTorque, gyro.CFrame = \"NoirFlyGyro\", 9e4, 800, Vector3.new(9e9,9e9,9e9), root.CFrame\n    gyro.Parent = root\n    local velocity = Instance.new(\"BodyVelocity\")\n    velocity.Name, velocity.P, velocity.Velocity, velocity.MaxForce = \"NoirFlyVelocity\", 12000, Vector3.zero, Vector3.new(9e9,9e9,9e9)\n    velocity.Parent = root\n    state.flyVelocity, state.flyGyro = velocity, gyro\n\n    state.flyConnection = RunService.Heartbeat:Connect(function()\n        if not state.fly or not (character.Parent and humanoid.Parent and root.Parent and velocity.Parent and gyro.Parent) then return end\n        local camera = Workspace.CurrentCamera\n        if not camera then return end\n        -- Mobile joystick flight: push forward/back while aiming the camera up or down to rise/descend.\n        -- MoveDirection supplies the joystick vector; projecting it on the camera's flat axes preserves its intent.\n        local look = camera.CFrame.LookVector\n        local right = camera.CFrame.RightVector\n        local flatLook = Vector3.new(look.X, 0, look.Z)\n        local flatRight = Vector3.new(right.X, 0, right.Z)\n        gyro.CFrame = CFrame.new(root.Position, root.Position + look)\n        local input = humanoid.MoveDirection\n        local desiredVelocity = Vector3.zero\n        if input.Magnitude > .001 then\n            local forwardInput = flatLook.Magnitude > .001 and input:Dot(flatLook.Unit) or 0\n            local sideInput = flatRight.Magnitude > .001 and input:Dot(flatRight.Unit) or 0\n            local flightDirection = look * forwardInput + right * sideInput\n            if flightDirection.Magnitude > .001 then desiredVelocity = flightDirection.Unit * state.flySpeed end\n        end\n        velocity.Velocity = desiredVelocity\n    end)\nend\n\nlocal function setFly(enabled)\n    state.fly = enabled == true\n    if state.fly then startFly() else stopFly() end\nend\n\nlocal binds = {\n    noclip = { text=\"Noclip\", key=\"noclip_bind_v1\", default=UDim2.new(.38,0,.88,0), size=.085, enabled=false, gui=nil, button=nil, connections={} },\n    fly = { text=\"Fly\", key=\"fly_bind_v1\", default=UDim2.new(.52,0,.88,0), size=.085, enabled=false, gui=nil, button=nil, connections={} },\n}\nlocal function disconnect(bind)\n    for _, connection in ipairs(bind.connections) do pcall(function() connection:Disconnect() end) end\n    table.clear(bind.connections)\nend\nlocal function updateSize(bind)\n    local camera = Workspace.CurrentCamera\n    if not (bind.button and camera) then return end\n    local screen = camera.ViewportSize\n    bind.button.Size = UDim2.new(bind.size * (screen.Y / math.max(screen.X,1)),0,bind.size,0)\nend\nlocal function updateText(bind, active)\n    local label = bind.button and bind.button:FindFirstChild(\"Text\")\n    if label then label.Text = string.upper(bind.text) .. \"  //  \" .. (active and \"ON\" or \"OFF\") end\nend\nlocal function removeBind(bind)\n    disconnect(bind)\n    if bind.gui then bind.gui:Destroy() end\n    bind.gui, bind.button = nil, nil\n    for _, parent in ipairs({M.guiParent, M.coreGui, LocalPlayer:FindFirstChildOfClass(\"PlayerGui\")}) do\n        if typeof(parent) == \"Instance\" then\n            local old = parent:FindFirstChild(\"Noir\" .. bind.text .. \"BindButton\")\n            if old then old:Destroy() end\n        end\n    end\nend\nlocal function createBind(bind, isActive, setActive)\n    if bind.button then return end\n    removeBind(bind)\n    local parent = M.guiParent\n    if typeof(parent) ~= \"Instance\" then parent = LocalPlayer:WaitForChild(\"PlayerGui\") end\n    local screenGui = Instance.new(\"ScreenGui\")\n    screenGui.Name, screenGui.ResetOnSpawn, screenGui.IgnoreGuiInset, screenGui.DisplayOrder = \"Noir\" .. bind.text .. \"BindButton\", false, true, 82\n    screenGui.Parent = parent\n    local button = Instance.new(\"ImageButton\")\n    button.Name, button.AnchorPoint = bind.text, Vector2.new(.5,.5)\n    button.Position = Persistence.GetPosition(bind.key,bind.default)\n    button.BackgroundColor3, button.BackgroundTransparency, button.BorderSizePixel, button.Image, button.AutoButtonColor, button.ZIndex = Color3.fromRGB(8,8,10),.42,0,\"\",false,5\n    button.Parent = screenGui\n    local circle = Instance.new(\"UICorner\"); circle.CornerRadius = UDim.new(1,0); circle.Parent = button\n    local aspect = Instance.new(\"UIAspectRatioConstraint\"); aspect.AspectRatio = 1; aspect.Parent = button\n    local outer = Instance.new(\"UIStroke\"); outer.Color,outer.Thickness,outer.ApplyStrokeMode,outer.Parent=Color3.fromRGB(255,255,255),2,Enum.ApplyStrokeMode.Border,button\n    local gradient = Instance.new(\"UIGradient\")\n    gradient.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(35,35,40)),ColorSequenceKeypoint.new(.22,Color3.fromRGB(250,250,252)),ColorSequenceKeypoint.new(.48,Color3.fromRGB(70,70,78)),ColorSequenceKeypoint.new(.72,Color3.fromRGB(255,255,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(45,45,52))})\n    gradient.Parent=outer\n    local inner=Instance.new(\"UIStroke\");inner.Color,inner.Transparency,inner.Thickness,inner.Parent=Color3.fromRGB(105,105,112),.5,1,button\n    local innerGradient=gradient:Clone();innerGradient.Rotation=180;innerGradient.Parent=inner\n    local viewport=Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize\n    local markPixels=math.max(22,math.floor(bind.size*(viewport and viewport.Y or 720)*.27))\n    if Blackhole and type(Blackhole.Create)==\"function\" then\n        local markRoot,mark=Blackhole.Create(button,UDim2.new(.5,0,.38,0),markPixels,Vector2.new(.5,.5),7,math.max(11,math.floor(markPixels*.5)),false)\n        markRoot.Size=UDim2.fromScale(.52,.52)\n        local markCorner=markRoot:FindFirstChildOfClass(\"UICorner\")\n        if markCorner then markCorner.CornerRadius=UDim.new(1,0) end\n        if mark.image then mark.image.ImageTransparency=.08 end\n    end\n    local label=Instance.new(\"TextLabel\")\n    label.Name,label.AnchorPoint,label.Position,label.Size=\"Text\",Vector2.new(.5,.5),UDim2.new(.5,0,.82,0),UDim2.new(.92,0,.22,0)\n    label.BackgroundTransparency,label.TextColor3,label.TextSize,label.TextScaled,label.TextWrapped,label.Font,label.ZIndex=1,Color3.fromRGB(245,245,248),11,true,true,Enum.Font.GothamBold,14\n    label.Parent=button\n    local dragging,moved,dragStart,startPosition,dragInput=false,false,nil,nil,nil\n    bind.connections[#bind.connections+1]=button.InputBegan:Connect(function(input)\n        if not M.isPrimaryPress(input) then return end\n        dragging,moved,dragStart,startPosition=true,false,input.Position,button.Position\n    end)\n    bind.connections[#bind.connections+1]=button.InputChanged:Connect(function(input)\n        if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then dragInput=input end\n    end)\n    bind.connections[#bind.connections+1]=UIS.InputChanged:Connect(function(input)\n        if not dragging or input~=dragInput then return end\n        local delta=input.Position-dragStart\n        if delta.Magnitude>7 then moved=true end\n        button.Position=UDim2.new(startPosition.X.Scale,startPosition.X.Offset+delta.X,startPosition.Y.Scale,startPosition.Y.Offset+delta.Y)\n    end)\n    bind.connections[#bind.connections+1]=UIS.InputEnded:Connect(function(input)\n        if not dragging or not M.isPrimaryPress(input) then return end\n        dragging=false\n        Persistence.SetPosition(bind.key,button.Position)\n    end)\n    bind.connections[#bind.connections+1]=button.Activated:Connect(function() if not moved then setActive(not isActive()) end end)\n    \n    bind.gui,bind.button=screenGui,button\n    updateSize(bind);updateText(bind,isActive())\nend\nlocal function setBind(bind, enabled, isActive, setActive)\n    bind.enabled=enabled==true\n    if bind.enabled then createBind(bind,isActive,setActive) else removeBind(bind) end\nend\nlocal function syncNoclipText() updateText(binds.noclip,state.noclip) end\nlocal function syncFlyText() updateText(binds.fly,state.fly) end\n\nlocal noclipSection=M.tab:AddSection(\"MAIN \\u{2022} NOCLIP\",\"Walk through local collision\")\nnoclipSection:AddToggle(\"Noclip\",function(enabled) setNoclip(enabled);syncNoclipText() end)\nnoclipSection:AddToggle(\"Enable Noclip Bind Button\",function(enabled)\n    setBind(binds.noclip,enabled,function() return state.noclip end,function(active) setNoclip(active);syncNoclipText() end)\nend)\nnoclipSection:AddSlider(\"Noclip Bind Button Size\",5,25,binds.noclip.size*100,function(value) binds.noclip.size=(tonumber(value) or 8.5)/100;updateSize(binds.noclip) end)\n\nlocal flySection=M.tab:AddSection(\"MAIN \\u{2022} FLY\",\"Camera-guided movement\")\nflySection:AddToggle(\"Fly\",function(enabled) setFly(enabled);syncFlyText() end)\nflySection:AddToggle(\"Enable Fly Bind Button\",function(enabled)\n    setBind(binds.fly,enabled,function() return state.fly end,function(active) setFly(active);syncFlyText() end)\nend)\nflySection:AddSlider(\"Fly Bind Button Size\",5,25,binds.fly.size*100,function(value) binds.fly.size=(tonumber(value) or 8.5)/100;updateSize(binds.fly) end)\n\nLocalPlayer.CharacterAdded:Connect(function()\n    task.wait(1)\n    if state.noclip then table.clear(state.noclipOriginals);applyNoclip() end\n    if state.fly then startFly() end\nend)\n\n"
    local compiler = loadstring
    if type(compiler) ~= "function" then
        warn("[Noir Movement] loadstring is unavailable; Noclip and Fly could not be started.")
        return
    end
    local okCompile, module = pcall(compiler, __noirMovementSource)
    if not okCompile or type(module) ~= "function" then
        warn("[Noir Movement] module compile failed: " .. tostring(module))
        return
    end
    local okRun, err = xpcall(module, function(message) return tostring(message) end)
    if not okRun then warn("[Noir Movement] module startup failed: " .. tostring(err)) end
end)




 
getgenv().__NoirAvatarCosmeticsContext = { tab = tab, localPlayer = LocalPlayer, runService = RunService }
task.defer(function()
    local __noirAvatarCosmeticsSource = "-- Persistent client-side avatar cosmetics for Noir's Main tab.\nlocal A = getgenv().__NoirAvatarCosmeticsContext\nif type(A) ~= \"table\" or not A.tab or not A.localPlayer then return end\n\nlocal LocalPlayer = A.localPlayer\nlocal RunService = A.runService\nlocal KORBLOX_RIGHT_LEG = 139607718\nlocal KORBLOX_PARTS = {\n    RightFoot = { mesh = \"rbxassetid://902942089\", transparency = 1 },\n    RightLowerLeg = { mesh = \"rbxassetid://902942093\", transparency = 1 },\n    RightUpperLeg = { mesh = \"rbxassetid://902942096\", texture = \"rbxassetid://902843398\", transparency = 0 },\n}\nlocal state = {\n    korblox = false,\n    headless = false,\n    korbloxOriginals = setmetatable({}, {__mode = \"k\"}),\n    korbloxPartOriginals = setmetatable({}, {__mode = \"k\"}),\n    headOriginals = setmetatable({}, {__mode = \"k\"}),\n    applyingKorblox = setmetatable({}, {__mode = \"k\"}),\n}\n\nlocal function getHumanoid(character)\n    return character and character:FindFirstChildWhichIsA(\"Humanoid\")\nend\n\nlocal function applyHeadless(character)\n    if not state.headless then return end\n    local head = character and character:FindFirstChild(\"Head\")\n    if not (head and head:IsA(\"BasePart\")) then return end\n    local original = state.headOriginals[head]\n    if not original then\n        original = { transparency = head.LocalTransparencyModifier, decals = {} }\n        state.headOriginals[head] = original\n        for _, descendant in ipairs(head:GetDescendants()) do\n            if descendant:IsA(\"Decal\") or descendant:IsA(\"Texture\") then original.decals[descendant] = descendant.Transparency end\n        end\n    end\n    head.LocalTransparencyModifier = 1\n    for decal in pairs(original.decals) do\n        if decal and decal.Parent then decal.Transparency = 1 end\n    end\n    local face = head:FindFirstChildWhichIsA(\"Decal\")\n    if face and original.decals[face] == nil then\n        original.decals[face] = face.Transparency\n        face.Transparency = 1\n    end\nend\n\nlocal function restoreHeadless(character)\n    local head = character and character:FindFirstChild(\"Head\")\n    local original = head and state.headOriginals[head]\n    if not original then return end\n    if head.Parent then head.LocalTransparencyModifier = original.transparency end\n    for decal, transparency in pairs(original.decals) do\n        if decal and decal.Parent then decal.Transparency = transparency end\n    end\n    state.headOriginals[head] = nil\nend\n\nlocal function applyKorbloxMesh(character)\n    if not state.korblox or not character then return end\n    for partName, appearance in pairs(KORBLOX_PARTS) do\n        local part = character:FindFirstChild(partName)\n        if part and part:IsA(\"MeshPart\") then\n            local original = state.korbloxPartOriginals[part]\n            if not original then\n                original = { mesh = part.MeshId, texture = part.TextureID, transparency = part.Transparency }\n                state.korbloxPartOriginals[part] = original\n            end\n            pcall(function() part.MeshId = appearance.mesh end)\n            if appearance.texture then pcall(function() part.TextureID = appearance.texture end) end\n            pcall(function() part.Transparency = appearance.transparency end)\n        end\n    end\nend\n\nlocal function restoreKorbloxMesh(character)\n    if not character then return end\n    for _, part in ipairs(character:GetDescendants()) do\n        local original = state.korbloxPartOriginals[part]\n        if original and part:IsA(\"MeshPart\") then\n            pcall(function()\n                part.MeshId, part.TextureID, part.Transparency = original.mesh, original.texture, original.transparency\n            end)\n            state.korbloxPartOriginals[part] = nil\n        end\n    end\nend\n\nlocal function applyKorblox(character)\n    if not state.korblox then return end\n    local humanoid = getHumanoid(character)\n    if not (humanoid and humanoid.RigType == Enum.HumanoidRigType.R15) or state.applyingKorblox[character] then return end\n    local ok, description = pcall(function() return humanoid:GetAppliedDescription() end)\n    if not ok or not description then return end\n    if state.korbloxOriginals[character] == nil then state.korbloxOriginals[character] = description.RightLeg end\n    if description.RightLeg ~= KORBLOX_RIGHT_LEG then\n        state.applyingKorblox[character] = true\n        description.RightLeg = KORBLOX_RIGHT_LEG\n        pcall(function() humanoid:ApplyDescription(description) end)\n        task.delay(.4, function()\n            state.applyingKorblox[character] = nil\n            if character.Parent then applyKorbloxMesh(character) end\n            if state.headless and character.Parent then applyHeadless(character) end\n        end)\n    end\n    -- HumanoidDescription can be rejected or overwritten in live games; direct R15 mesh fallback keeps the cosmetic visible.\n    applyKorbloxMesh(character)\n    applyHeadless(character)\nend\n\nlocal function restoreKorblox(character)\n    local originalRightLeg = character and state.korbloxOriginals[character]\n    local humanoid = getHumanoid(character)\n    if not (humanoid and originalRightLeg ~= nil) then return end\n    local ok, description = pcall(function() return humanoid:GetAppliedDescription() end)\n    if ok and description then\n        description.RightLeg = originalRightLeg\n        pcall(function() humanoid:ApplyDescription(description) end)\n    end\n    restoreKorbloxMesh(character)\n    state.korbloxOriginals[character] = nil\nend\n\nlocal function applyCurrentCharacter()\n    local character = LocalPlayer.Character\n    if state.korblox then applyKorblox(character) end\n    if state.headless then applyHeadless(character) end\nend\n\nlocal section = A.tab:AddSection(\"MAIN \\u{2022} FUN CLIENT\", \"Respawn-persistent local avatar cosmetics\")\nsection:AddToggle(\"Permanent Korblox (R15)\", function(enabled)\n    state.korblox = enabled == true\n    local character = LocalPlayer.Character\n    if state.korblox then applyKorblox(character) else restoreKorblox(character) end\nend)\nsection:AddToggle(\"Permanent Headless\", function(enabled)\n    state.headless = enabled == true\n    local character = LocalPlayer.Character\n    if state.headless then applyHeadless(character) else restoreHeadless(character) end\nend)\nsection:AddLabel(\"Both looks are reapplied after each respawn. Korblox requires an R15 character.\")\n\nLocalPlayer.CharacterAdded:Connect(function(character)\n    task.wait(.75)\n    applyKorblox(character)\n    applyHeadless(character)\nend)\nLocalPlayer.CharacterAppearanceLoaded:Connect(function(character)\n    task.wait(.2)\n    if state.korblox then applyKorblox(character) end\n    if state.headless then applyHeadless(character) end\nend)\n-- Games may refresh an avatar after it has spawned. Keep the two requested client cosmetics applied while enabled.\nif RunService then\n    -- Avatar refreshes only need to counter occasional game appearance writes; avoid doing mesh/head work every render frame.\n    local nextRefresh = 0\n    RunService.Heartbeat:Connect(function()\n        local now = os.clock()\n        if now < nextRefresh then return end\n        nextRefresh = now + .45\n        local character = LocalPlayer.Character\n        if state.korblox then applyKorbloxMesh(character) end\n        if state.headless then applyHeadless(character) end\n    end)\nend\ntask.defer(applyCurrentCharacter)\n\n"
    local compiler = loadstring
    if type(compiler) ~= "function" then
        warn("[Noir Avatar Cosmetics] loadstring is unavailable; cosmetic controls could not be started.")
        return
    end
    local okCompile, moduleFn = pcall(compiler, __noirAvatarCosmeticsSource)
    if not okCompile or type(moduleFn) ~= "function" then
        warn("[Noir Avatar Cosmetics] module compile failed: " .. tostring(moduleFn))
        return
    end
    local okRun, err = xpcall(moduleFn, function(message) return tostring(message) end)
    if not okRun then warn("[Noir Avatar Cosmetics] module startup failed: " .. tostring(err)) end
end)




 
getgenv().__NoirEmotesContext = {
    container = emotesContent,
    theme = { base = C.base, panel = C.panel, surface = C.surface, card = C.card, button = C.btn, accent = C.accent, text = C.text, dim = C.dim, border = C.border },
    SetCanvasHeight = function(height)
        emotesContent.CanvasSize = UDim2.fromOffset(0, math.max(200, tonumber(height) or 664))
    end,
    Notify = function(textValue, duration) notify("Emotes: " .. tostring(textValue), duration or 3) end,
}
task.defer(function()
    local __noirEmotesSource = "-- 7yd7 Emotes — Overdrive H plugin + responsive thumbnail card browser.\n-- Original: https://github.com/7yd7/Hub/blob/Branch/GUIS/Emotes.lua\n-- Catalog: 7yd7/sniper-Emote, EmoteSniper.json. No remote Lua execution.\n-- Separate card GUI; original animation bundles/themes/HUD editor are not included.\n-- R15 only. Asset permissions and replication remain controlled by Roblox/the game.\n-- Integrated into Noir's native Emotes tab. The catalog source stays data-only; no remote Lua is executed.\nlocal shared=getgenv().__NoirEmotesContext\nlocal container=shared and shared.container\nif not shared or not (container and typeof(container)==\"Instance\") then\n    warn(\"[Noir Emotes] native Emotes tab container unavailable.\")\n    return\nend\nlocal KEY=\"Noir_7yd7_EmotesRuntime_v1\"\nlocal previous=_G[KEY]\nif type(previous)==\"table\" and previous.alive and type(previous.Cleanup)==\"function\" then\n    pcall(previous.Cleanup)\nend\nlocal Players=game:GetService(\"Players\")\nlocal Player=Players.LocalPlayer\nif not Player then warn(\"[ODH Emotes] LocalPlayer unavailable.\");return end\nlocal HttpService=game:GetService(\"HttpService\")\nlocal RunService=game:GetService(\"RunService\")\nlocal UIS=game:GetService(\"UserInputService\")\nlocal runtime={version=7,alive=true,initializing=true,generation=0,filterGeneration=0,page=1,catalog={},filtered={},resolutions={},connections={}}\nlocal prefs={windowTransparency=22,thumbnailSize=68,thumbnailPresetVersion=2,playbackModeVersion=2,shortcuts={},browserOnLoad=false,loop=false,walk=false,speed=1,favoritesOnly=false,query=\"\",customId=\"\",customKind=\"Catalog emote ID\",favorites={}}\nlocal FILE=\"ODH_Emotes_settings.json\"\nlocal CACHE=\"ODH_Emotes_catalog.json\"\nlocal URL=\"https://raw.githubusercontent.com/7yd7/sniper-Emote/refs/heads/test/EmoteSniper.json\"\nlocal PAGE_SIZE=12\nlocal MAX_SHORTCUTS=12\nlocal warnings={}\nlocal function Notify(text)\n    if type(shared.Notify)==\"function\" then pcall(shared.Notify,\"Emotes: \"..text,5) end\nend\nlocal function WarnOnce(key,text)\n    if warnings[key] then return end\n    warnings[key]=true;warn(\"[ODH Emotes] \"..text);Notify(text)\nend\nlocal env={}\nif type(getgenv)==\"function\" then\n    local ok,value=pcall(getgenv)\n    if ok and type(value)==\"table\" then env=value end\nend\nlocal read=type(readfile)==\"function\" and readfile or env.readfile\nlocal write=type(writefile)==\"function\" and writefile or env.writefile\nlocal exists=type(isfile)==\"function\" and isfile or env.isfile\nlocal canSave=type(read)==\"function\" and type(write)==\"function\"\nruntime.settingsFile=FILE\nruntime.saveStatus=canSave and \"Not saved\" or \"Session only\"\nruntime.preferences=prefs\nlocal function AssetId(value)\n    if type(value)~=\"number\" and type(value)~=\"string\" then return nil end\n    local id=tonumber(value)\n    if id and id==id and id>0 and id<9007199254740992 and id==math.floor(id) then return id end\nend\nlocal function IdText(id) return string.format(\"%.0f\",id) end\nlocal function ParseId(text)\n    if type(text)~=\"string\" then return nil end\n    local digits=text:match(\"^%s*(%d+)%s*$\") or text:match(\"^rbxassetid://(%d+)$\")\n        or text:match(\"[?&]id=(%d+)\") or text:match(\"roblox%.com/catalog/(%d+)\")\n    return digits and AssetId(digits)\nend\nlocal function Item(value)\n    if type(value)~=\"table\" then return nil end\n    local id=AssetId(value.id)\n    if not id then return nil end\n    local name=type(value.name)==\"string\" and value.name:gsub(\"[%c]\",\" \") or (\"Emote \"..IdText(id))\n    if #name==0 or #name>2000 then name=\"Emote \"..IdText(id) end\n    return {id=id,name=name}\nend\nlocal function ReadJSON(path)\n    if type(read)~=\"function\" then return nil,\"unavailable\" end\n    if type(exists)==\"function\" then\n        local ok,found=pcall(exists,path)\n        if ok and not found then return nil,\"missing\" end\n    end\n    local ok,text=pcall(read,path)\n    if not ok then return nil,\"read error\" end\n    local decoded,data=pcall(function() return HttpService:JSONDecode(text) end)\n    if not decoded or type(data)~=\"table\" then return nil,\"invalid JSON\" end\n    return data\nend\nlocal function LoadSettings()\n    if not canSave then WarnOnce(\"files\",\"readfile/writefile unavailable; settings are session-only.\");return end\n    local data,err=ReadJSON(FILE)\n    if not data then\n        if err~=\"missing\" then WarnOnce(\"read\",\"Settings not loaded (\"..tostring(err)..\"). Existing file is kept until you change a setting.\") end\n        return\n    end\n    if data.version~=1 or type(data.values)~=\"table\" then\n        WarnOnce(\"read\",\"Invalid settings; existing file is kept until you change a setting.\");return\n    end\n    local values=data.values\n    -- Migrate the old forced/default Loop ON without discarding other settings.\n    if values.playbackModeVersion==2 and type(values.loop)==\"boolean\" then prefs.loop=values.loop end\n    if type(values.shortcuts)==\"table\" then\n        local count=0\n        for _,value in pairs(values.shortcuts) do\n            local item=Item(value)\n            if item then\n                local function position(number,default)\n                    if type(number)==\"number\" and number==number and number>-math.huge and number<math.huge then\n                        return math.clamp(number,0,1)\n                    end\n                    return default\n                end\n                item.x=position(value.x,.75);item.y=position(value.y,.45)\n                prefs.shortcuts[IdText(item.id)]=item;count=count+1\n                if count>=MAX_SHORTCUTS then break end\n            end\n        end\n    end\n    for key,limits in pairs({windowTransparency={0,50},thumbnailSize={50,100}}) do\n        local value=values[key]\n        if type(value)==\"number\" and value==value and value>-math.huge and value<math.huge then\n            prefs[key]=math.clamp(value,limits[1],limits[2])\n        end\n    end\n    if values.thumbnailPresetVersion~=2 and prefs.thumbnailSize==78 then prefs.thumbnailSize=68 end\n    for _,key in ipairs({\"walk\",\"favoritesOnly\",\"browserOnLoad\"}) do\n        if type(values[key])==\"boolean\" then prefs[key]=values[key] end\n    end\n    if type(values.speed)==\"number\" and values.speed==values.speed and values.speed>-math.huge and values.speed<math.huge then prefs.speed=math.clamp(values.speed,0,3) end\n    if type(values.query)==\"string\" then prefs.query=values.query:sub(1,200) end\n    if type(values.customId)==\"string\" and #values.customId<=200 then prefs.customId=values.customId end\n    if values.customKind==\"Animation ID\" then prefs.customKind=values.customKind end\n    prefs.selected=Item(values.selected)\n    if type(values.favorites)==\"table\" then\n        local count=0\n        for _,value in pairs(values.favorites) do\n            local item=Item(value)\n            if item then prefs.favorites[IdText(item.id)]=item;count=count+1 end\n            if count>=10000 then break end\n        end\n    end\n    runtime.saveStatus=\"Loaded\"\nend\nlocal function SaveSettings()\n    if runtime.initializing or not runtime.alive or not canSave then return false end\n    local ok,err=pcall(function() write(FILE,HttpService:JSONEncode({version=1,values=prefs})) end)\n    if not ok then runtime.saveStatus=\"Write error\";WarnOnce(\"write\",\"Cannot save settings: \"..tostring(err));return false end\n    runtime.saveStatus=\"Saved\";warnings.write=nil;return true\nend\nLoadSettings()\n\nlocal BUILTIN={\n    {id=3360689775,name=\"Salute\"},\n    {id=5915779043,name=\"Applaud\"},\n    {id=3360692915,name=\"Tilt\"},\n    {id=15610015346,name=\"Yungblud Happier Jump\"},\n    {id=14353423348,name=\"Baby Queen - Bouncy Twirl\"},\n    {id=14353421343,name=\"Baby Queen - Face Frame\"},\n    {id=3823158750,name=\"Godlike\"},\n    {id=139021427684680,name=\"KATSEYE - Touch\"},\n    {id=133596366979822,name=\"Biblically Accurate Emote\"},\n    {id=108128682361404,name=\"Rambunctious\"},\n    {id=79127989560307,name=\"Moon Walk\"},\n    {id=5230661597,name=\"Bored\"},\n    {id=14353425085,name=\"Baby Queen - Strut\"},\n    {id=15694504637,name=\"d4vd - Backflip\"},\n    {id=104142334418357,name=\"[Original] It's Gangnam Style!\"},\n    {id=16553249658,name=\"Mae Stephens - Piano Hands\"},\n    {id=12507097350,name=\"Alo Yoga Pose - Lotus Position\"},\n    {id=15698511500,name=\"Cuco - Levitate\"},\n    {id=4689362868,name=\"Sleep\"},\n    {id=111426928948833,name=\"Floating on clouds\"},\n    {id=130245358716273,name=\"The Weeknd Starboy Strut\"},\n    {id=120642514156293,name=\"Secret Handshake Dance\"},\n    {id=15506503658,name=\"Victory Dance\"},\n    {id=3576717965,name=\"Shy\"},\n    {id=73796726960568,name=\"Nyan Nyan! \"},\n    {id=78758922757947,name=\"Kicking Feet Sit\"},\n    {id=93511411593120,name=\"/e fly\"},\n    {id=114899970878842,name=\"R15 Death (Accurate)\"},\n    {id=5104377791,name=\"Hero Landing\"},\n    {id=5917570207,name=\"Floss Dance\"},\n    {id=131763631172236,name=\"Xaviersobased Emote\"},\n    {id=132074413582912,name=\"California Girl Dance\"},\n    {id=15554010118,name=\"Olivia Rodrigo Head Bop\"},\n    {id=112758073578333,name=\"Bubbly Sit\"},\n    {id=3716636630,name=\"Monkey\"},\n    {id=123015710605336,name=\"Onion\"},\n    {id=4646306583,name=\"Curtsy\"},\n    {id=85936805522788,name=\"Caramell\"},\n    {id=14900153406,name=\"TWICE Feel Special\"},\n    {id=102492229412911,name=\"Deltarune - Tenna Dance\"},\n    {id=133142324349281,name=\"Flopping Fish\"},\n    {id=10214406616,name=\"Frosty Flair - Tommy Hilfiger\"},\n    {id=120224229260879,name=\"Cute crouch \"},\n    {id=15679955281,name=\"Festive Dance\"},\n    {id=4849502101,name=\"Sad\"},\n    {id=10214418283,name=\"V Pose - Tommy Hilfiger\"},\n    {id=92853367837757,name=\"Garry's Dance\"},\n    {id=104485625389237,name=\"Make You Mine\"},\n    {id=139830733782518,name=\"Phut On\"},\n    {id=132382355371060,name=\"Tank Transformation\"},\n    {id=103046131635200,name=\"Scenario - LOVE SCENARIO\"},\n    {id=15123050663,name=\"Bone Chillin' Bop\"},\n    {id=124305244640379,name=\"Shattered\"},\n    {id=134311528115559,name=\"how did he hit every beat\"},\n    {id=17748346932,name=\"Elton John - Heart Shuffle\"},\n    {id=93105950995997,name=\"Caramelldansen\"},\n    {id=7466046574,name=\"Quiet Waves\"},\n    {id=96557878503341,name=\"Caramell Dansen\"},\n    {id=139859849852362,name=\"Dead\"},\n    {id=17360720445,name=\"HUGO Let's Drive!\"},\n    {id=103102322875221,name=\"Skibidi Toilet - Titan Speakerman Laser Spin\"},\n    {id=3576968026,name=\"Shrug\"},\n    {id=130998336536045,name=\"Gangnam Style\"},\n    {id=84555218084038,name=\"Helicopter Spin\"},\n    {id=71302743123422,name=\"Popular\"},\n    {id=133765015173412,name=\"DearALICE - Ariana\"},\n    {id=115319301809339,name=\"2 Phut Hon Dance\"},\n    {id=70635223083942,name=\"Be Not Afraid\"},\n    {id=17746270218,name=\"Sturdy Dance - Ice Spice\"},\n    {id=129149402922241,name=\"griddy\"},\n    {id=3576686446,name=\"Hello\"},\n    {id=113547795536875,name=\"Gangnam Style\"},\n    {id=126614732606871,name=\"Sit\"},\n    {id=3762654854,name=\"Greatest\"},\n    {id=16572756230,name=\"HIPMOTION - Amaarae\"},\n    {id=16276506814,name=\"Sol de Janeiro - Samba\"},\n    {id=3576823880,name=\"Point2\"},\n    {id=78459263478161,name=\"Family Man Death Pose\"},\n    {id=14900151704,name=\"TWICE LIKEY\"},\n    {id=3360686498,name=\"Stadium\"},\n    {id=15571540519,name=\"Nicki Minaj Starships\"},\n    {id=4940597758,name=\"Cower\"},\n    {id=11394056822,name=\"Elton John - Elevate\"},\n    {id=117734400993750,name=\"Virtual Singer Dance\"},\n    {id=97263450325496,name=\"Teto Territory\"},\n    {id=4102315500,name=\"Haha\"},\n    {id=79312439851071,name=\"Chappell Roan HOT TO GO!\"},\n    {id=105851216004006,name=\"Electro Swing\"},\n    {id=92707348383277,name=\"Mesmerizer\"},\n    {id=103139492736941,name=\"Deltarune - Tenna Swing Dance\"},\n    {id=15571538346,name=\"Nicki Minaj Boom Boom Boom\"},\n    {id=15554016057,name=\"Olivia Rodrigo Fall Back to Float\"},\n    {id=70615023659736,name=\"Floating\"},\n    {id=136740085081295,name=\"/e hidden animation\"},\n    {id=119431985170060,name=\"Helicopter\"},\n    {id=87141651594092,name=\"No-Clip/Speed Glitch\"},\n    {id=16303091119,name=\"Beauty Touchdown\"},\n    {id=3934986896,name=\"Dizzy\"},\n    {id=130726889233022,name=\"rolling crybaby\"},\n    {id=11309263077,name=\"Elton John - Heart Skip\"},\n    {id=84511772437190,name=\"Emote Loading. Please Wait... | spinning Robloxian\"},\n    {id=14353417553,name=\"Baby Queen - Air Guitar & Knee Slide\"},\n    {id=15392927897,name=\"Paris Hilton - Sliving For The Groove\"},\n    {id=94796833553521,name=\"TWICE Takedown pt 1 from Kpop Demon Hunters\"},\n    {id=120437019363089,name=\"peter griffin death pose\"},\n    {id=15506506103,name=\"Flex Walk\"},\n    {id=90608224567833,name=\"Proud to be Expendable - Pressure\"},\n    {id=18526338976,name=\"Team USA Breaking Emote\"},\n    {id=99818263438846,name=\"Default Dance\"},\n    {id=103197720369544,name=\"Dani's Gangnam Style\"},\n    {id=75017857395637,name=\"TV Time Dance\"},\n    {id=73683655527605,name=\"Fashion Roadkill\"},\n    {id=15392932768,name=\"Paris Hilton - Iconic IT-Grrrl\"},\n    {id=82217023310738,name=\"Thanos Happy Jump - Squid Game\"},\n    {id=102610758906338,name=\"Possessed\"},\n    {id=95323795166399,name=\"Rat Dance\"},\n    {id=127562607220778,name=\"Gangnam Style \"},\n    {id=129132611803602,name=\"Helicopter\"},\n    {id=82345302788133,name=\"Dia Delicia Dance\"},\n    {id=15392937495,name=\"Paris Hilton - Checking My Angles\"},\n    {id=4212496830,name=\"Zombie\"},\n    {id=113016438012253,name=\"⌛ Best Mates EMOTE [LIMITED]\"},\n    {id=110537281410647,name=\"[Aura Farm] Wall Lean Idle\"},\n    {id=92903522317071,name=\"ILLIT - Magnetic\"},\n    {id=122899100558551,name=\"It's TV Time!\"},\n    {id=75528418031928,name=\"Rambunctious\"},\n    {id=103040723950430,name=\"Gojo Floating\"},\n    {id=70788193750089,name=\"Kickn around\"},\n    {id=5915776835,name=\"High Wave\"},\n    {id=84195923658292,name=\"Jojo\"},\n    {id=110731335896907,name=\"[⌛ Limited]  HEADLESS EMOTE \"},\n    {id=139271706064778,name=\"Hip Bounce\"},\n    {id=4849499887,name=\"Happy\"},\n    {id=127271798262177,name=\"M3GAN's Dance\"},\n    {id=104304182344567,name=\"ONCE HOP HOP!\"},\n    {id=85623000473425,name=\"TWICE Takedown pt 2 from KPop Demon Hunters\"},\n    {id=84067050907557,name=\"Pickle Rick Dance\"},\n    {id=86982022610765,name=\"Caramelldansen\"},\n    {id=117301403779781,name=\"Im Talm Bout Innit\"},\n    {id=84822284410814,name=\"Maraschino Step\"},\n    {id=97847706148165,name=\"[NEW !] Caramelldansen Kawaii Dance\"},\n    {id=89174456614428,name=\"Laying Down - Daydreaming\"},\n    {id=91023138078288,name=\"OH WHO IS YOU\"},\n    {id=107978036345855,name=\"Prince Of Egypt Dance / What You Want\"},\n    {id=71363859760586,name=\"Golden Freddy Pose\"},\n    {id=80877772569772,name=\"Default Dance | OG\"},\n    {id=80436375269036,name=\"HEADLESS HOOPER\"},\n    {id=93262662842394,name=\"Sit\"},\n    {id=75703899901487,name=\"6 7 Transformation\"},\n    {id=100773414188482,name=\"Stray Kids Walkin On Water\"},\n    {id=131544122623505,name=\"Become A Car!\"},\n    {id=99005087791705,name=\"Death Pose\"},\n    {id=132384701706046,name=\"💀MM2 Fake Dead\"},\n    {id=129916107176034,name=\"Discombobulated\"},\n    {id=88598010609888,name=\"Angry Stomp \"},\n    {id=132508867759412,name=\"xavier so based emote\"},\n    {id=121167704249654,name=\"Hide\"},\n    {id=137873580964093,name=\"Floating Human Spinner (LIMITED) \"},\n    {id=76700167742736,name=\"Belly Dance\"},\n    {id=87826892596287,name=\"levitate\"},\n    {id=70972410468289,name=\"Fake Dead (Troll Emote)\"},\n    {id=134615135651900,name=\"Young-hee Head Spin - Squid Game\"},\n    {id=13823339506,name=\"Tommy - Archer\"},\n    {id=109755476052324,name=\"IShowSpeed Dance\"},\n    {id=124828909173982,name=\"Skibidi\"},\n    {id=4272351660,name=\"Fast Hands\"},\n    {id=137006085779408,name=\"Speed Glitch+\"},\n    {id=89633087256727,name=\"Weird Spin\"},\n    {id=125032357496729,name=\"Fake Death (BEST)\"},\n    {id=81177294287826,name=\"Hug\"},\n    {id=88721672617892,name=\"P.B.J.T.\"},\n    {id=121259524934987,name=\"Xaviersobased Jig\"},\n    {id=121067808279598,name=\"PARROT PARTY DANCE\"},\n    {id=7202898984,name=\"Show Dem Wrists - KSI\"},\n    {id=120377619472998,name=\"Macarena\"},\n    {id=4940602656,name=\"Jumping Wave\"},\n    {id=94663026124741,name=\"Torture Dance\"},\n    {id=120896030393583,name=\"Get Sturdy\"},\n    {id=137261874619072,name=\"Sponge Dance\"},\n    {id=119746055344304,name=\"Plane\"},\n    {id=78620443286892,name=\"Cute Laying Down\"},\n    {id=108922782921118,name=\"📸 Pose for the Pic \"},\n    {id=131221550165951,name=\"Heart Hands Pose 3.0\"},\n    {id=119454955259757,name=\"Caramel Hip Sway\"},\n    {id=7202900159,name=\"Wake Up Call - KSI\"},\n    {id=79752538807060,name=\"Griddy\"},\n    {id=140466682449054,name=\"head spin\"},\n    {id=107899954696611,name=\"Spongebob Shuffle Dance 🧽\"},\n    {id=96405718067779,name=\"Cute Sit\"},\n    {id=4849497510,name=\"Power Blast\"},\n    {id=89413575288931,name=\"Blue Shirt Guy Dancing\"},\n    {id=112924687333965,name=\"Aura Farm\"},\n    {id=100782362883099,name=\"Car Transformation\"},\n    {id=102323907950469,name=\"Space Dance\"},\n    {id=110521067391235,name=\"The Old Jitterbug\"},\n    {id=111304332281521,name=\"Druski Shuffle\"},\n    {id=133600250245899,name=\"🥤 Soda Pop - Saja Boys\"},\n    {id=133477296392756,name=\"Rasputin – Boney M.\"},\n    {id=122949892043249,name=\"[Aura Farm] Sit Idle\"},\n    {id=82739386299071,name=\"Jackpot Groove\"},\n    {id=80422524668416,name=\"Dreamer\"},\n    {id=97968838104258,name=\"Subject Three / AI Cat Chinese Dance\"},\n    {id=91274761264433,name=\"Macarena\"},\n    {id=3994130516,name=\"Bodybuilder\"},\n    {id=5938365243,name=\"Dolphin Dance\"},\n    {id=99563839802389,name=\"Jumpstyle\"},\n    {id=85361710130557,name=\"Caramelldansen\"},\n    {id=74646784680842,name=\"Ishowspeed shake \"},\n    {id=5230615437,name=\"Beckon\"},\n    {id=135489824748823,name=\"Magical Pose\"},\n    {id=98603994713783,name=\"Rat Dance\"},\n    {id=14353419229,name=\"Baby Queen - Dramatic Bow\"},\n    {id=84052327668385,name=\"Floating\"},\n    {id=97999370392804,name=\"Spin my Head\"},\n    {id=94319114655768,name=\"Rat Dance\"},\n    {id=86849720336961,name=\"Mr. Ant Tennas Dance - DELTARUNE\"},\n    {id=124754178569693,name=\"Die Lit!\"},\n    {id=80544397800234,name=\"Helicopter\"},\n    {id=100532972764499,name=\"MONSTER MASH\"},\n    {id=88922397617835,name=\"What You Want\"},\n    {id=115810068374896,name=\"Garry's Dance\"},\n    {id=75842745124834,name=\"Human Snake\"},\n    {id=94451497143711,name=\"Hakari Dance\"},\n    {id=128972617664804,name=\"Fortnite Default Dance\"},\n    {id=73556976257737,name=\"Saja Boy Pose - Jinu\"},\n    {id=81390693780805,name=\"PROXIMA\"},\n    {id=17000058939,name=\"Mini Kong\"},\n    {id=97629500912487,name=\"BlockyKick Dance\"},\n    {id=112949099442762,name=\"Griddy\"},\n    {id=130641944883645,name=\" Jinu Pose - Saja Boys\"},\n    {id=108474079699304,name=\"Dep\"},\n    {id=4049646104,name=\"Line Dance\"},\n    {id=91423783304464,name=\"criss cross sit\"},\n    {id=90524692306889,name=\"[⏳] Chill Sit\"},\n    {id=15506496093,name=\"Rock n Roll\"},\n    {id=134737246939931,name=\"GAG IT DEATH DROP\"},\n    {id=71787387963141,name=\"Worm Dance\"},\n    {id=128658037413893,name=\"I'm Going To Die Here - Pressure\"},\n    {id=99568437064777,name=\"Relaxed Sit\"},\n    {id=83018514370428,name=\"Stargazing\"},\n    {id=92859581691366,name=\"ALTÉGO - Couldn’t Care Less\"},\n    {id=94534169345613,name=\"Casual Sit\"},\n    {id=16126526506,name=\"Paris Hilton Sanasa\"},\n    {id=140037329261678,name=\"Caramel dance\"},\n    {id=94118707925458,name=\"Go Mufasa\"},\n    {id=105730788757021,name=\"Dani's BIRDBRAIN\"},\n    {id=91927498467600,name=\"Koto Nai Meme Dance\"},\n    {id=117450501566142,name=\"Hide Hidden Box Invisible Camo Emote Small tiny\"},\n    {id=4272484885,name=\"Baby Dance\"},\n    {id=88024974500195,name=\"Oppa Gangnam Style\"},\n    {id=7202896732,name=\"Boxing Punch - KSI\"},\n    {id=128792127841374,name=\"Watching silly videos (Or texting)\"},\n    {id=87756443172440,name=\"xavier so based dance\"},\n    {id=116770268279002,name=\"BirdBrain Teto\"},\n    {id=124935873390035,name=\"Hiding Human Box\"},\n    {id=94121796810251,name=\"Kicking Feet And Blushing\"},\n}\n\nlocal statusLabel,catalogLabel,selectedLabel,searchLabel,customLabel\nlocal function Label(control,text)\n    if control then pcall(function() control:SetValue(text) end) end\nend\nlocal function Status(text)\n    runtime.status=text;Label(statusLabel,text)\n    if runtime.UpdateCardStatus then runtime.UpdateCardStatus() end\nend\nlocal function Dispose(track,animation)\n    if track then\n        pcall(function() track:Stop(0) end)\n        pcall(function() track:Destroy() end)\n    end\n    if animation then pcall(function() animation:Destroy() end) end\nend\nlocal function StopCurrent(message)\n    runtime.generation=runtime.generation+1\n    if runtime.endedConnection then runtime.endedConnection:Disconnect();runtime.endedConnection=nil end\n    local track,animation=runtime.track,runtime.animation\n    runtime.track=nil;runtime.animation=nil;runtime.character=nil;runtime.playing=nil\n    Dispose(track,animation)\n    if message then Status(message) end\nend\nruntime.Stop=function() StopCurrent(\"Stopped\") end\nlocal function Current(ticket,character)\n    return runtime.alive and runtime.generation==ticket and Player.Character==character\nend\nlocal function ResolveCatalog(id)\n    if runtime.resolutions[id] then return runtime.resolutions[id] end\n    local ok,objects=pcall(function() return game:GetObjects(\"rbxassetid://\"..IdText(id)) end)\n    if not ok or type(objects)~=\"table\" then return nil end\n    local resolved\n    -- Loaded objects stay unparented. Scripts in an asset are never executed.\n    pcall(function()\n        for _,root in ipairs(objects) do\n            if root:IsA(\"Animation\") then resolved=ParseId(root.AnimationId) end\n            if not resolved then\n                local descendants=root:GetDescendants()\n                for i,obj in ipairs(descendants) do\n                    if i>4000 then break end\n                    if obj:IsA(\"Animation\") then resolved=ParseId(obj.AnimationId);if resolved then break end end\n                end\n            end\n            if resolved then break end\n        end\n    end)\n    for _,root in ipairs(objects) do pcall(function() root:Destroy() end) end\n    if resolved then runtime.resolutions[id]=resolved end\n    return resolved\nend\nlocal function Play(item,direct)\n    if not runtime.alive then return end\n    if not item or not AssetId(item.id) then Notify(\"Select an emote or enter a valid ID first.\");return end\n    StopCurrent()\n    local ticket=runtime.generation\n    local character=Player.Character\n    if not character then Status(\"Waiting for character — press Play after spawning\");return end\n    Status(\"Loading: \"..item.name)\n    task.spawn(function()\n        local track,animation\n        local ok,err=pcall(function()\n            if not Current(ticket,character) then return end\n            local humanoid=character:FindFirstChildOfClass(\"Humanoid\") or character:WaitForChild(\"Humanoid\",8)\n            if not Current(ticket,character) then return end\n            if not humanoid or humanoid.Health<=0 then error(\"Character is not ready\") end\n            if humanoid.RigType~=Enum.HumanoidRigType.R15 then error(\"R15 character required\") end\n            local animator=humanoid:FindFirstChildOfClass(\"Animator\") or humanoid:WaitForChild(\"Animator\",8)\n            if not Current(ticket,character) then return end\n            if not animator then error(\"Animator is not ready\") end\n            local animationId=direct and item.id or ResolveCatalog(item.id)\n            if not Current(ticket,character) then return end\n            if not animationId and not direct then\n                -- Roblox's native emote API is a fallback when GetObjects is unavailable.\n                local nativeOK,nativeTrack=pcall(function() return humanoid:PlayEmoteAndGetAnimTrackById(item.id) end)\n                if nativeOK and nativeTrack and typeof(nativeTrack)==\"Instance\" and nativeTrack:IsA(\"AnimationTrack\") then track=nativeTrack end\n                if not Current(ticket,character) then return end\n            end\n            if not track then\n                animation=Instance.new(\"Animation\")\n                animation.AnimationId=\"rbxassetid://\"..IdText(animationId or item.id)\n                track=animator:LoadAnimation(animation)\n            end\n            if not Current(ticket,character) then return end\n            if not track then error(\"Roblox did not return an animation track\") end\n            track.Priority=Enum.AnimationPriority.Action\n            track.Looped=prefs.loop\n            if not track.IsPlaying then track:Play(0.05,1,prefs.speed) else track:AdjustSpeed(prefs.speed) end\n            runtime.track=track;runtime.animation=animation;runtime.character=character\n            runtime.playing=item\n            runtime.endedConnection=track.Ended:Connect(function()\n                if runtime.track==track and Current(ticket,character) then StopCurrent(\"Finished: \"..item.name) end\n            end)\n            -- LoadAnimation may return a track even for an inaccessible/deleted asset.\n            local deadline=os.clock()+8\n            while Current(ticket,character) and runtime.track==track and track.Length<=0 and os.clock()<deadline do task.wait(0.1) end\n            if not Current(ticket,character) or runtime.track~=track then return end\n            if track.Length<=0 then error(\"Animation did not load. It may be restricted, deleted, or incompatible.\") end\n            Status(\"Playing: \"..item.name)\n        end)\n        if not Current(ticket,character) then\n            -- A newer click/Stop/respawn wins even if GetObjects/LoadAnimation yielded.\n            if runtime.track~=track then Dispose(track,animation) end\n            return\n        end\n        if not ok then\n            if runtime.track==track then StopCurrent() else Dispose(track,animation) end\n            Status(\"Cannot play this emote\")\n            Notify(tostring(err))\n        end\n    end)\nend\nruntime.Play=function(id,name,direct) Play({id=id,name=name or IdText(id)},direct==true) end\nruntime.SaveSettings=SaveSettings\nruntime.connections[#runtime.connections+1]=Player.CharacterAdded:Connect(function()\n    StopCurrent(\"Respawned — select an emote and press Play\")\nend)\nruntime.connections[#runtime.connections+1]=RunService.Heartbeat:Connect(function()\n    if not runtime.alive or not runtime.track then return end\n    local character=runtime.character\n    local humanoid=character and character:FindFirstChildOfClass(\"Humanoid\")\n    if Player.Character~=character or not humanoid or humanoid.Health<=0 then StopCurrent(\"Stopped\");return end\n    if not prefs.walk and humanoid.MoveDirection.Magnitude>0.05 then StopCurrent(\"Stopped on movement\") end\nend)\nfunction runtime.Cleanup()\n    runtime.alive=false;runtime.filterGeneration=runtime.filterGeneration+1\n    StopCurrent()\n    for _,connection in ipairs(runtime.connections) do connection:Disconnect() end\n    if runtime.DestroyBrowser then runtime.DestroyBrowser() end\nend\n\nlocal dropdown,pageLabel\nlocal displayed={}\nlocal syncing=false\nlocal SENTINEL=\"— Select an emote —\"\nlocal function NormalizeCatalog(data)\n    if type(data)~=\"table\" then return nil end\n    local source=type(data.data)==\"table\" and data.data or data\n    local items,seen={},{}\n    for i,value in ipairs(source) do\n        if i>100000 then break end\n        local item=Item(value)\n        if item and not seen[item.id] then\n            seen[item.id]=true;items[#items+1]=item\n        end\n    end\n    return #items>0 and items or nil\nend\nlocal function SelectionLabel()\n    local item=prefs.selected\n    Label(selectedLabel,item and (\"Selected: \"..item.name..\" [\"..IdText(item.id)..\"]\") or \"Selected: none\")\n    if runtime.UpdateCardStatus then runtime.UpdateCardStatus() end\nend\nlocal function RenderPage()\n    if not runtime.alive then return end\n    local pages=math.max(1,math.ceil(#runtime.filtered/PAGE_SIZE))\n    runtime.page=math.clamp(runtime.page,1,pages)\n    local names={SENTINEL}\n    displayed={}\n    local selectedText=SENTINEL\n    for i=(runtime.page-1)*PAGE_SIZE+1,math.min(runtime.page*PAGE_SIZE,#runtime.filtered) do\n        local item=runtime.filtered[i]\n        local text=item.name..\" [\"..IdText(item.id)..\"]\"\n        names[#names+1]=text;displayed[text]=item\n        if prefs.selected and prefs.selected.id==item.id then selectedText=text end\n    end\n    if dropdown then\n        syncing=true\n        local ok,err=pcall(function() dropdown:ChangeItems(names);dropdown:Select(selectedText) end)\n        syncing=false\n        if not ok then WarnOnce(\"dropdown\",\"Could not update the emote list: \"..tostring(err)) end\n    end\n    Label(pageLabel,\"Page \"..runtime.page..\" / \"..pages..\" • matches: \"..#runtime.filtered..\" • catalog: \"..#runtime.catalog)\n    SelectionLabel()\n    if runtime.RenderCards then runtime.RenderCards() end\nend\nlocal function Filter(resetPage)\n    runtime.filterGeneration=runtime.filterGeneration+1\n    local ticket=runtime.filterGeneration\n    local query=prefs.query:lower()\n    local favoritesOnly=prefs.favoritesOnly\n    local source=runtime.catalog\n    if favoritesOnly then\n        source={}\n        for _,item in pairs(prefs.favorites) do source[#source+1]=item end\n        table.sort(source,function(a,b) return a.name:lower()<b.name:lower() end)\n    end\n    local words={}\n    for word in query:gmatch(\"%S+\") do words[#words+1]=word end\n    runtime.filtering=true\n    if runtime.UpdateCardStatus then runtime.UpdateCardStatus() end\n    Label(searchLabel,\"Search: \"..(prefs.query==\"\" and \"(all)\" or prefs.query))\n    task.spawn(function()\n        local filtered={}\n        for i,item in ipairs(source) do\n            if not runtime.alive or runtime.filterGeneration~=ticket then return end\n            local haystack=item.name:lower()..\" \"..IdText(item.id)\n            local matches=true\n            for _,word in ipairs(words) do\n                if not haystack:find(word,1,true) then matches=false;break end\n            end\n            if matches then filtered[#filtered+1]=item end\n            if i%500==0 then task.wait() end\n        end\n        if not runtime.alive or runtime.filterGeneration~=ticket then return end\n        runtime.filtered=filtered;runtime.filtering=false\n        if resetPage then runtime.page=1 end\n        RenderPage()\n    end)\nend\nlocal function AdoptCatalog(items,source)\n    runtime.catalog=items\n    runtime.catalogSource=source\n    Label(catalogLabel,\"Catalog: \"..#items..\" emotes • \"..source)\n    -- A selected item need not be on the visible page or present in a newer catalog.\n    if not prefs.selected then prefs.selected=items[1] end\n    SelectionLabel()\n    Filter(true)\nend\nlocal function RefreshCatalog()\n    if not runtime.alive or runtime.catalogBusy then return end\n    runtime.catalogBusy=true\n    Label(catalogLabel,\"Updating catalog... current list remains available\")\n    task.spawn(function()\n        local ok,data=pcall(function() return HttpService:JSONDecode(game:HttpGet(URL)) end)\n        if not runtime.alive then return end\n        local items=ok and NormalizeCatalog(data) or nil\n        runtime.catalogBusy=false\n        if not items then\n            Label(catalogLabel,\"Catalog: \"..#runtime.catalog..\" • offline / update failed\")\n            WarnOnce(\"network\",\"Catalog update failed. The cached or built-in list remains available.\")\n            return\n        end\n        warnings.network=nil\n        AdoptCatalog(items,\"7yd7 online catalog\")\n        if type(write)==\"function\" then\n            local saved=pcall(function() write(CACHE,HttpService:JSONEncode({version=1,data=items})) end)\n            if not saved then WarnOnce(\"cache\",\"Could not save the catalog cache; the list still works this session.\") end\n        end\n    end)\nend\nruntime.RefreshCatalog=RefreshCatalog\n\n-- Native Noir-styled Emotes page. It uses the supplied script's catalog, persistence and playback core.\ndo\n    local UI = { connections = {}, cards = {}, settingsOpen = false, searchToken = 0 }\n    runtime.browser = UI\n    local theme = shared.theme or {}\n    local C = {\n        base = theme.base or Color3.fromRGB(9, 10, 13),\n        panel = theme.panel or Color3.fromRGB(16, 18, 22),\n        surface = theme.surface or Color3.fromRGB(24, 27, 32),\n        card = theme.card or Color3.fromRGB(20, 24, 28),\n        button = theme.button or Color3.fromRGB(34, 38, 44),\n        accent = theme.accent or Color3.fromRGB(216, 222, 232),\n        text = theme.text or Color3.fromRGB(240, 243, 246),\n        dim = theme.dim or Color3.fromRGB(147, 156, 166),\n        border = theme.border or Color3.fromRGB(68, 75, 84),\n        danger = Color3.fromRGB(190, 195, 203),\n    }\n    local function Make(class, properties, parent)\n        local instance = Instance.new(class)\n        for key, value in pairs(properties or {}) do instance[key] = value end\n        instance.Parent = parent\n        return instance\n    end\n    local function Round(instance, radius)\n        return Make(\"UICorner\", { CornerRadius = UDim.new(0, radius or 10) }, instance)\n    end\n    local function Stroke(instance, color, transparency, thickness)\n        return Make(\"UIStroke\", { Color = color or C.border, Transparency = transparency or .45, Thickness = thickness or 1 }, instance)\n    end\n    local function Text(parent, value, size, position, dimensions, color)\n        return Make(\"TextLabel\", {\n            BackgroundTransparency = 1, Text = value or \"\", TextColor3 = color or C.text,\n            Font = Enum.Font.Gotham, TextSize = size or 14, TextXAlignment = Enum.TextXAlignment.Left,\n            TextYAlignment = Enum.TextYAlignment.Center, Position = position or UDim2.new(), Size = dimensions or UDim2.new(1,0,1,0),\n        }, parent)\n    end\n    local function Button(parent, value, position, dimensions)\n        local button = Make(\"TextButton\", {\n            BackgroundColor3 = Color3.fromRGB(7,8,11), BackgroundTransparency = .32, BorderSizePixel = 0,\n            Text = value or \"\", TextColor3 = C.text, Font = Enum.Font.GothamBold,\n            TextSize = 13, AutoButtonColor = false, Position = position or UDim2.new(), Size = dimensions or UDim2.new(),\n        }, parent)\n        Round(button, 10)\n        local outline = Stroke(button, C.border, .24, 1.25)\n        Make(\"UIGradient\", { Rotation = 35, Color = ColorSequence.new({\n            ColorSequenceKeypoint.new(0,Color3.fromRGB(35,35,40)), ColorSequenceKeypoint.new(.22,Color3.fromRGB(250,250,252)),\n            ColorSequenceKeypoint.new(.48,Color3.fromRGB(70,70,78)), ColorSequenceKeypoint.new(.72,Color3.fromRGB(255,255,255)),\n            ColorSequenceKeypoint.new(1,Color3.fromRGB(45,45,52)),\n        }) }, outline)\n        local inner = Stroke(button, C.dim, .78, .65)\n        inner.ApplyStrokeMode = Enum.ApplyStrokeMode.Border\n        local press = Make(\"UIScale\", { Scale = 1 }, button)\n        button.MouseEnter:Connect(function()\n            if button.Parent then button.BackgroundColor3 = Color3.fromRGB(22,24,29); button.BackgroundTransparency = .18; outline.Transparency = .05 end\n        end)\n        button.MouseLeave:Connect(function()\n            if button.Parent then button.BackgroundColor3 = Color3.fromRGB(7,8,11); button.BackgroundTransparency = .32; outline.Transparency = .24; press.Scale = 1 end\n        end)\n        button.InputBegan:Connect(function(input)\n            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then press.Scale = .975 end\n        end)\n        button.InputEnded:Connect(function(input)\n            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then press.Scale = 1 end\n        end)\n        return button\n    end\n    local function Connect(signal, callback)\n        local connection = signal:Connect(callback)\n        UI.connections[#UI.connections + 1] = connection\n        return connection\n    end\n    local function Save()\n        SaveSettings()\n    end\n    local function SetSelected(item)\n        if not item then return end\n        prefs.selected = { id = item.id, name = item.name }\n        Save()\n        if runtime.UpdateCardStatus then runtime.UpdateCardStatus() end\n    end\n    local function ToggleFavorite(item)\n        local key = IdText(item.id)\n        if prefs.favorites[key] then prefs.favorites[key] = nil else prefs.favorites[key] = { id = item.id, name = item.name } end\n        Save()\n        if prefs.favoritesOnly then Filter(false) elseif runtime.UpdateCardStatus then runtime.UpdateCardStatus() end\n    end\n    local function SetLoop(value)\n        prefs.loop = value == true\n        Save()\n        if runtime.track then pcall(function() runtime.track.Looped = prefs.loop end) end\n        if runtime.UpdateCardStatus then runtime.UpdateCardStatus() end\n    end\n    local function SetMove(value)\n        prefs.walk = value == true\n        Save()\n        if runtime.UpdateCardStatus then runtime.UpdateCardStatus() end\n    end\n    local function SetSpeed(value)\n        prefs.speed = math.clamp(math.floor((tonumber(value) or prefs.speed) * 100 + .5) / 100, 0, 3)\n        Save()\n        if runtime.track then pcall(function() runtime.track:AdjustSpeed(prefs.speed) end) end\n        if runtime.UpdateCardStatus then runtime.UpdateCardStatus() end\n    end\n    -- Circular pin buttons create draggable on-screen photo shortcuts, matching the supplied card browser behavior.\n    local quickGui, quickRecords, quickConnections = nil, {}, {}\n    local function clearQuickConnections()\n        for _, connection in ipairs(quickConnections) do pcall(function() connection:Disconnect() end) end\n        table.clear(quickConnections)\n    end\n    local function destroyQuickGui()\n        clearQuickConnections()\n        if quickGui then quickGui:Destroy() end\n        quickGui, quickRecords = nil, {}\n    end\n    local function ensureQuickGui()\n        if quickGui and quickGui.Parent then return quickGui end\n        quickGui = Instance.new(\"ScreenGui\")\n        quickGui.Name, quickGui.ResetOnSpawn, quickGui.IgnoreGuiInset, quickGui.DisplayOrder = \"NoirEmoteQuickButtons\", false, true, 90\n        local parent\n        if type(gethui) == \"function\" then\n            local ok, value = pcall(gethui)\n            if ok and typeof(value) == \"Instance\" then parent = value end\n        end\n        quickGui.Parent = parent or Player:WaitForChild(\"PlayerGui\")\n        return quickGui\n    end\n    local function viewport()\n        return workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(900,600)\n    end\n    local function positionQuick(record)\n        local saved = prefs.shortcuts[record.key]\n        if not saved then return end\n        local screen = viewport()\n        record.button.Position = UDim2.fromOffset(math.clamp(saved.x * screen.X, 38, math.max(38, screen.X - 38)), math.clamp(saved.y * screen.Y, 38, math.max(38, screen.Y - 38)))\n    end\n    local function createQuick(key, saved)\n        -- Rounded-square photo control using the same dark body and metallic double border as Shoot Murder.\n        local button = Instance.new(\"TextButton\")\n        button.Name, button.AnchorPoint, button.Size = \"Emote_\" .. key, Vector2.new(.5,.5), UDim2.fromOffset(88,88)\n        button.BackgroundColor3, button.BackgroundTransparency, button.BorderSizePixel = Color3.fromRGB(8,8,10), .42, 0\n        button.Text, button.AutoButtonColor, button.ZIndex = \"\", false, 91\n        button.Parent = ensureQuickGui()\n        local corner = Instance.new(\"UICorner\"); corner.CornerRadius = UDim.new(0,16); corner.Parent = button\n        local outline = Instance.new(\"UIStroke\"); outline.Color, outline.Thickness, outline.ApplyStrokeMode, outline.Parent = Color3.fromRGB(255,255,255), 2, Enum.ApplyStrokeMode.Border, button\n        local shine = Instance.new(\"UIGradient\")\n        shine.Color = ColorSequence.new({\n            ColorSequenceKeypoint.new(0, Color3.fromRGB(35,35,40)), ColorSequenceKeypoint.new(.22, Color3.fromRGB(250,250,252)),\n            ColorSequenceKeypoint.new(.48, Color3.fromRGB(70,70,78)), ColorSequenceKeypoint.new(.72, Color3.fromRGB(255,255,255)),\n            ColorSequenceKeypoint.new(1, Color3.fromRGB(45,45,52)),\n        })\n        shine.Parent = outline\n        local inner = Instance.new(\"UIStroke\"); inner.Color, inner.Transparency, inner.Thickness, inner.Parent = Color3.fromRGB(105,105,112), .5, 1, button\n        local innerShine = shine:Clone(); innerShine.Rotation = 180; innerShine.Parent = inner\n        local image = Instance.new(\"ImageLabel\")\n        image.Name, image.AnchorPoint, image.Position, image.Size = \"Photo\", Vector2.new(.5,.5), UDim2.fromScale(.5,.5), UDim2.fromOffset(62,62)\n        image.BackgroundTransparency, image.Image, image.ScaleType, image.ZIndex = 1, \"rbxthumb://type=Asset&id=\" .. key .. \"&w=420&h=420\", Enum.ScaleType.Fit, 92\n        image.Parent = button\n        local imageCorner = Instance.new(\"UICorner\"); imageCorner.CornerRadius = UDim.new(0,11); imageCorner.Parent = image\n        local record = { key = key, item = { id = saved.id, name = saved.name }, button = button, dragging = false, moved = false }\n        quickRecords[key] = record\n        positionQuick(record)\n        local dragInput, start, startPosition\n        quickConnections[#quickConnections+1] = button.InputBegan:Connect(function(input)\n            if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end\n            record.dragging, record.moved, dragInput, start, startPosition = true, false, input, input.Position, button.Position\n        end)\n        quickConnections[#quickConnections+1] = UIS.InputChanged:Connect(function(input)\n            if not record.dragging then return end\n            if input ~= dragInput and not (dragInput.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement) then return end\n            local delta = input.Position - start\n            if delta.Magnitude > 7 then record.moved = true end\n            button.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)\n        end)\n        quickConnections[#quickConnections+1] = UIS.InputEnded:Connect(function(input)\n            if not record.dragging or input ~= dragInput then return end\n            record.dragging = false\n            if record.moved then\n                local screen = viewport()\n                prefs.shortcuts[key].x = math.clamp(button.Position.X.Offset / math.max(screen.X,1), 0, 1)\n                prefs.shortcuts[key].y = math.clamp(button.Position.Y.Offset / math.max(screen.Y,1), 0, 1)\n                record.blockUntil = os.clock() + .25\n                Save()\n            end\n        end)\n        quickConnections[#quickConnections+1] = button.Activated:Connect(function()\n            if record.moved or (record.blockUntil and os.clock() < record.blockUntil) then return end\n            SetSelected(record.item); Play(record.item, false)\n        end)\n    end\n    local function RefreshQuickButtons()\n        for key, record in pairs(quickRecords) do\n            if not prefs.shortcuts[key] then record.button:Destroy(); quickRecords[key] = nil end\n        end\n        for key, saved in pairs(prefs.shortcuts) do\n            if not quickRecords[key] then createQuick(key, saved) else positionQuick(quickRecords[key]) end\n        end\n        if not next(prefs.shortcuts) then destroyQuickGui() end\n    end\n    local function ToggleQuick(item)\n        local key = IdText(item.id)\n        if prefs.shortcuts[key] then\n            prefs.shortcuts[key] = nil\n        else\n            local count = 0\n            for _ in pairs(prefs.shortcuts) do count += 1 end\n            if count >= MAX_SHORTCUTS then Notify(\"Maximum \" .. MAX_SHORTCUTS .. \" on-screen emote buttons.\"); return end\n            local screen = viewport()\n            prefs.shortcuts[key] = { id = item.id, name = item.name, x = .86, y = math.clamp(.28 + count * .1, .18, .82) }\n        end\n        Save(); RefreshQuickButtons()\n        if runtime.UpdateCardStatus then runtime.UpdateCardStatus() end\n    end\n\n    local function Layout()\n        if not (UI.root and UI.cardsScroll) then return end\n        local size = UI.root.AbsoluteSize\n        if size.X < 1 or size.Y < 1 then return end\n        local narrow = size.X < 570\n        local veryNarrow = size.X < 410\n        UI.search.Position = UDim2.fromOffset(18, 68)\n        UI.search.Size = UDim2.new(1, narrow and -138 or -268, 0, 38)\n        UI.favoriteFilter.Position = UDim2.new(1, narrow and -112 or -242, 0, 68)\n        UI.favoriteFilter.Size = UDim2.fromOffset(narrow and 94 or 118, 38)\n        UI.settingsButton.Position = UDim2.new(1, narrow and -18 or -116, 0, 18)\n        UI.settingsButton.AnchorPoint = Vector2.new(1, 0)\n        UI.settingsButton.Size = UDim2.fromOffset(narrow and 86 or 98, 32)\n        UI.random.Position = UDim2.new(1, narrow and -18 or -18, 0, 110)\n        UI.random.AnchorPoint = Vector2.new(1, 0)\n        UI.random.Size = UDim2.fromOffset(narrow and 82 or 94, 30)\n        UI.stop.Position = UDim2.new(1, narrow and -108 or -122, 0, 110)\n        UI.stop.AnchorPoint = Vector2.new(1, 0)\n        UI.stop.Size = UDim2.fromOffset(narrow and 82 or 94, 30)\n        UI.summary.Position = UDim2.fromOffset(20, 112)\n        UI.summary.Size = UDim2.new(1, narrow and -200 or -260, 0, 28)\n        local top, footer = 148, 58\n        UI.cardsScroll.Position = UDim2.fromOffset(18, top)\n        UI.cardsScroll.Size = UDim2.new(1, -36, 1, -(top + footer + 10))\n        UI.footer.Position = UDim2.new(0, 18, 1, -54)\n        UI.footer.Size = UDim2.new(1, -36, 0, 40)\n        -- Use the full Noir tab width, matching the supplied menu's three-card gallery on wider screens.\n        local available = math.max(1, size.X - 48)\n        -- Scale-based cells fill the whole Noir page even when the mobile UI has a UIScale applied.\n        local columns, padding, cellHeight = 3, 12, 250\n        UI.grid.CellSize = UDim2.new(1 / columns, -10, 0, cellHeight)\n        UI.grid.FillDirectionMaxCells = columns\n        local rows = math.ceil(#UI.cards / columns)\n        UI.cardsScroll.CanvasSize = UDim2.fromOffset(0, math.max(0, rows * (cellHeight + padding) - padding + 8))\n        UI.settings.Size = UDim2.fromOffset(math.min(290, math.max(230, size.X - 36)), math.min(470, math.max(250, size.Y - 96)))\n        UI.settings.Position = UDim2.new(1, -18, 0, 58)\n        UI.settings.AnchorPoint = Vector2.new(1, 0)\n    end\n    runtime.ApplyBrowserAppearance = Layout\n    runtime.ResetBrowserPosition = function() Layout() end\n    local function UpdateStatus()\n        if not UI.root then return end\n        local pages = math.max(1, math.ceil(#runtime.filtered / PAGE_SIZE))\n        UI.page.Text = \"Page \" .. runtime.page .. \" / \" .. pages\n        UI.status.Text = runtime.status or \"Ready — select an emote and press Play\"\n        UI.summary.Text = runtime.filtering and \"Searching emotes...\" or (tostring(#runtime.filtered) .. \" emotes\")\n        UI.favoriteFilter.Text = prefs.favoritesOnly and \"★ Saved\" or \"☆ Saved\"\n        UI.favoriteFilter.TextColor3 = prefs.favoritesOnly and C.accent or C.text\n        UI.favoriteFilter.BackgroundColor3 = prefs.favoritesOnly and C.surface or C.button\n        UI.loop.Text = prefs.loop and \"Loop  ON\" or \"Loop  OFF\"\n        UI.loop.TextColor3 = prefs.loop and C.accent or C.text\n        UI.move.Text = prefs.walk and \"Move  ON\" or \"Move  OFF\"\n        UI.move.TextColor3 = prefs.walk and C.accent or C.text\n        UI.speedValue.Text = \"Speed \" .. tostring(prefs.speed)\n        for _, card in ipairs(UI.cards) do\n            local selected = prefs.selected and prefs.selected.id == card.item.id\n            local playing = runtime.track and runtime.playing and runtime.playing.id == card.item.id\n            card.stroke.Color = selected and C.accent or C.border\n            card.stroke.Transparency = selected and .08 or .62\n            card.star.Text = prefs.favorites[IdText(card.item.id)] and \"★\" or \"☆\"\n            card.star.TextColor3 = prefs.favorites[IdText(card.item.id)] and C.accent or C.text\n            card.pin.Text = prefs.shortcuts[IdText(card.item.id)] and \"●\" or \"○\"\n            card.pin.TextColor3 = prefs.shortcuts[IdText(card.item.id)] and C.accent or C.dim\n            card.play.Text = playing and \"■\" or \"▶\"\n            card.play.BackgroundColor3 = playing and C.accent or C.button\n            card.play.TextColor3 = playing and C.accent or C.text\n        end\n    end\n    runtime.UpdateCardStatus = UpdateStatus\n    local function BuildCard(item, order)\n        local card = Make(\"Frame\", { Name = \"Emote_\" .. IdText(item.id), LayoutOrder = order, BackgroundColor3 = C.card, BackgroundTransparency = .22, BorderSizePixel = 0, ClipsDescendants = true }, UI.cardsScroll)\n        local cardConnections = {}\n        local function CardConnect(signal, callback)\n            local connection = signal:Connect(callback)\n            cardConnections[#cardConnections + 1] = connection\n            return connection\n        end\n        Round(card, 14)\n        local outline = Stroke(card, C.border, .62, 1)\n        local title = Text(card, item.name, 15, UDim2.fromOffset(12, 10), UDim2.new(1, -70, 0, 36))\n        title.TextWrapped = true; title.TextTruncate = Enum.TextTruncate.AtEnd; title.Font = Enum.Font.GothamMedium; title.TextYAlignment = Enum.TextYAlignment.Top\n        local star = Button(card, \"☆\", UDim2.new(1, -50, 0, 8), UDim2.fromOffset(38, 36))\n        star.BackgroundTransparency = 1; star.TextSize = 27\n        local image = Make(\"ImageButton\", { BackgroundTransparency = 1, AutoButtonColor = false, AnchorPoint = Vector2.new(.5,.5), Position = UDim2.new(.5, 0, .55, 0), Size = UDim2.fromOffset(130,130), Image = \"rbxthumb://type=Asset&id=\" .. IdText(item.id) .. \"&w=420&h=420\", ScaleType = Enum.ScaleType.Fit }, card)\n        local pin = Button(card, \"○\", UDim2.new(1, -60, .48, 0), UDim2.fromOffset(46,46))\n        pin.BackgroundTransparency = 1; pin.TextSize = 30\n        local play = Button(card, \"▶\", UDim2.new(1, -62, 1, -62), UDim2.fromOffset(50,50)); play.TextSize = 20\n        local record = { frame = card, connections = cardConnections, item = item, stroke = outline, star = star, pin = pin, play = play }\n        UI.cards[#UI.cards + 1] = record\n        CardConnect(image.Activated, function() SetSelected(item) end)\n        CardConnect(star.Activated, function() ToggleFavorite(item) end)\n        CardConnect(pin.Activated, function() ToggleQuick(item) end)\n        CardConnect(play.Activated, function()\n            local playing = runtime.track and runtime.playing and runtime.playing.id == item.id\n            SetSelected(item)\n            if playing then StopCurrent(\"Stopped\") else Play(item, false) end\n            UpdateStatus()\n        end)\n    end\n    local function RenderCards()\n        if not UI.root then return end\n        -- Do not create thumbnail cards while this page is hidden. The visible-page handler performs one render on open.\n        if not container.Visible then UI.needsRender = true; return end\n        for _, record in ipairs(UI.cards) do\n            for _, connection in ipairs(record.connections or {}) do pcall(function() connection:Disconnect() end) end\n            if record.frame then record.frame:Destroy() end\n        end\n        UI.cards = {}\n        UI.needsRender = false\n        local first = (runtime.page - 1) * PAGE_SIZE + 1\n        local last = math.min(runtime.page * PAGE_SIZE, #runtime.filtered)\n        for index = first, last do BuildCard(runtime.filtered[index], index - first + 1) end\n        UI.empty.Visible = #runtime.filtered == 0\n        UI.empty.Text = runtime.filtering and \"Searching...\" or (prefs.favoritesOnly and \"No saved emotes yet.\" or \"No emotes match your search.\")\n        UI.cardsScroll.CanvasPosition = Vector2.zero\n        Layout(); UpdateStatus()\n    end\n    runtime.RenderCards = RenderCards\n    local function Build()\n        local old = container:FindFirstChild(\"NoirEmotesNative\")\n        if old then old:Destroy() end\n        UI.root = Make(\"Frame\", { Name = \"NoirEmotesNative\", Position = UDim2.fromOffset(12, 12), Size = UDim2.new(1, -24, 0, 640), BackgroundColor3 = C.base, BackgroundTransparency = .22, BorderSizePixel = 0, ClipsDescendants = true }, container)\n        if shared.SetCanvasHeight then shared.SetCanvasHeight(664) end\n        Round(UI.root, 18); Stroke(UI.root, C.border, .35, 1.2)\n        local gradient = Make(\"UIGradient\", { Color = ColorSequence.new(C.base, C.surface), Rotation = 20 }, UI.root)\n        Text(UI.root, \"EMOTES\", 21, UDim2.fromOffset(18, 14), UDim2.new(1,-150,0,24)).Font = Enum.Font.GothamBold\n        Text(UI.root, \"R15 ANIMATION LIBRARY\", 10, UDim2.fromOffset(19, 39), UDim2.new(1,-150,0,16), C.dim)\n        UI.settingsButton = Button(UI.root, \"Settings\", UDim2.new(1,-116,0,18), UDim2.fromOffset(98,32))\n        UI.search = Make(\"TextBox\", { BackgroundColor3 = C.surface, BackgroundTransparency = .20, BorderSizePixel = 0, Text = prefs.query, PlaceholderText = \"Search emote or ID...\", PlaceholderColor3 = C.dim, TextColor3 = C.text, Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false }, UI.root)\n        Round(UI.search, 10); Stroke(UI.search, C.border, .55); Make(\"UIPadding\", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 8) }, UI.search)\n        UI.favoriteFilter = Button(UI.root, \"☆ Saved\", UDim2.new(), UDim2.fromOffset(118,38))\n        UI.random = Button(UI.root, \"Random\", UDim2.new(), UDim2.fromOffset(94,30))\n        UI.stop = Button(UI.root, \"■ Stop\", UDim2.new(), UDim2.fromOffset(94,30)); UI.stop.TextColor3 = C.danger\n        UI.summary = Text(UI.root, \"Loading emotes...\", 12, UDim2.fromOffset(20,112), UDim2.new(1,-260,0,28), C.dim)\n        UI.cardsScroll = Make(\"ScrollingFrame\", { BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = C.accent, CanvasSize = UDim2.fromOffset(0,0), ScrollingDirection = Enum.ScrollingDirection.Y, ElasticBehavior = Enum.ElasticBehavior.Never }, UI.root)\n        Make(\"UIPadding\", { PaddingLeft = UDim.new(0,2), PaddingRight = UDim.new(0,8), PaddingTop = UDim.new(0,2), PaddingBottom = UDim.new(0,6) }, UI.cardsScroll)\n        UI.grid = Make(\"UIGridLayout\", { SortOrder = Enum.SortOrder.LayoutOrder, CellPadding = UDim2.fromOffset(12,12), CellSize = UDim2.fromOffset(240,170) }, UI.cardsScroll)\n        UI.empty = Text(UI.root, \"No emotes found\", 16, UDim2.fromOffset(26,185), UDim2.new(1,-52,0,200), C.dim)\n        UI.empty.TextXAlignment = Enum.TextXAlignment.Center; UI.empty.TextYAlignment = Enum.TextYAlignment.Center; UI.empty.Visible = false\n        UI.footer = Make(\"Frame\", { BackgroundTransparency = 1 }, UI.root)\n        UI.previous = Button(UI.footer, \"‹\", UDim2.fromOffset(0,0), UDim2.fromOffset(35,35)); UI.previous.TextSize = 26\n        UI.next = Button(UI.footer, \"›\", UDim2.new(1,-35,0,0), UDim2.fromOffset(35,35)); UI.next.TextSize = 26\n        UI.page = Text(UI.footer, \"Page 1 / 1\", 12, UDim2.fromOffset(42,0), UDim2.new(1,-84,0,35), C.dim); UI.page.TextXAlignment = Enum.TextXAlignment.Center\n        UI.status = Text(UI.footer, \"Ready\", 11, UDim2.fromOffset(2,37), UDim2.new(1,-4,0,14), C.dim)\n        -- Settings content is taller than a phone-sized drawer, so make the drawer itself vertically scrollable.\n        UI.settings = Make(\"ScrollingFrame\", { BackgroundColor3 = C.panel, BackgroundTransparency = .20, BorderSizePixel = 0, Visible = false, ZIndex = 20,\n            ClipsDescendants = true, Active = true, ScrollBarThickness = 4, ScrollBarImageColor3 = C.accent,\n            ScrollingDirection = Enum.ScrollingDirection.Y, ElasticBehavior = Enum.ElasticBehavior.Never,\n            CanvasSize = UDim2.fromOffset(0, 388) }, UI.root)\n        Round(UI.settings, 14); Stroke(UI.settings, C.border, .2, 1.2)\n        Text(UI.settings, \"EMOTE SETTINGS\", 15, UDim2.fromOffset(16,14), UDim2.new(1,-32,0,24)).Font = Enum.Font.GothamBold\n        local function SettingsButton(label, y)\n            local button = Button(UI.settings, label, UDim2.fromOffset(16,y), UDim2.new(1,-32,0,36)); button.ZIndex = 21; return button\n        end\n        UI.loop = SettingsButton(\"Loop  OFF\", 52)\n        UI.move = SettingsButton(\"Move  OFF\", 96)\n        UI.speedMinus = SettingsButton(\"−\", 140); UI.speedMinus.Size = UDim2.fromOffset(38,36)\n        UI.speedValue = SettingsButton(\"Speed 1\", 140); UI.speedValue.Position = UDim2.fromOffset(62,140); UI.speedValue.Size = UDim2.new(1,-124,0,36)\n        UI.speedPlus = SettingsButton(\"+\", 140); UI.speedPlus.Position = UDim2.new(1,-54,0,140); UI.speedPlus.Size = UDim2.fromOffset(38,36)\n        UI.custom = Make(\"TextBox\", { BackgroundColor3 = C.surface, BorderSizePixel = 0, Position = UDim2.fromOffset(16,188), Size = UDim2.new(1,-32,0,36), Text = prefs.customId, PlaceholderText = \"Custom animation ID\", PlaceholderColor3 = C.dim, TextColor3 = C.text, Font = Enum.Font.Gotham, TextSize = 13, ClearTextOnFocus = false, ZIndex = 21 }, UI.settings)\n        Round(UI.custom, 9); Stroke(UI.custom, C.border, .5); Make(\"UIPadding\", { PaddingLeft = UDim.new(0,10) }, UI.custom)\n        UI.playCustom = SettingsButton(\"Play custom animation\", 232)\n        UI.refresh = SettingsButton(\"Refresh catalog\", 276)\n        UI.closeSettings = SettingsButton(\"Close settings\", 320)\n        Connect(UI.settingsButton.Activated, function()\n            UI.settingsOpen = not UI.settingsOpen\n            UI.settings.Visible = UI.settingsOpen\n            if UI.settingsOpen then UI.settings.CanvasPosition = Vector2.zero end\n        end)\n        Connect(UI.closeSettings.Activated, function() UI.settingsOpen = false; UI.settings.Visible = false end)\n        Connect(UI.loop.Activated, function() SetLoop(not prefs.loop) end)\n        Connect(UI.move.Activated, function() SetMove(not prefs.walk) end)\n        Connect(UI.speedMinus.Activated, function() SetSpeed(prefs.speed - .25) end)\n        Connect(UI.speedPlus.Activated, function() SetSpeed(prefs.speed + .25) end)\n        Connect(UI.refresh.Activated, RefreshCatalog)\n        Connect(UI.playCustom.Activated, function()\n            prefs.customId = UI.custom.Text:sub(1,200); Save()\n            local id = ParseId(prefs.customId)\n            if not id then Notify(\"Enter a valid animation ID.\"); return end\n            Play({ id = id, name = \"Custom \" .. IdText(id) }, true)\n        end)\n        Connect(UI.custom.FocusLost, function() prefs.customId = UI.custom.Text:sub(1,200); Save() end)\n        Connect(UI.favoriteFilter.Activated, function() prefs.favoritesOnly = not prefs.favoritesOnly; Save(); Filter(true) end)\n        Connect(UI.random.Activated, function()\n            if runtime.filtering or #runtime.filtered == 0 then Notify(\"No emotes available yet.\"); return end\n            local item = runtime.filtered[math.random(1,#runtime.filtered)]; SetSelected(item); Play(item,false)\n        end)\n        Connect(UI.stop.Activated, function() StopCurrent(\"Stopped\") end)\n        Connect(UI.previous.Activated, function() runtime.page = math.max(1, runtime.page - 1); RenderPage() end)\n        Connect(UI.next.Activated, function() runtime.page = runtime.page + 1; RenderPage() end)\n        Connect(UI.search:GetPropertyChangedSignal(\"Text\"), function()\n            UI.searchToken = UI.searchToken + 1\n            local ticket = UI.searchToken\n            task.delay(.25, function()\n                if not runtime.alive or ticket ~= UI.searchToken then return end\n                prefs.query = UI.search.Text:sub(1,200); Save(); Filter(true)\n            end)\n        end)\n        Connect(UI.search.FocusLost, function() prefs.query = UI.search.Text:sub(1,200); Save(); Filter(true) end)\n        Connect(UI.root:GetPropertyChangedSignal(\"AbsoluteSize\"), function() task.defer(Layout) end)\n        Connect(UI.cardsScroll:GetPropertyChangedSignal(\"AbsoluteSize\"), function() task.defer(Layout) end)\n        Connect(container:GetPropertyChangedSignal(\"Visible\"), function()\n            if container.Visible then task.delay(.05, function() if runtime.alive and UI.root then Layout(); RenderCards() end end) end\n        end)\n        Layout(); RenderCards(); RefreshQuickButtons()\n    end\n    function runtime.OpenBrowser()\n        if not runtime.alive then return end\n        if UI.root and UI.root.Parent then UI.root.Visible = true; RenderCards(); return end\n        local ok, err = pcall(Build)\n        if not ok then WarnOnce(\"native_ui\", \"Could not build the Noir Emotes page: \" .. tostring(err)) end\n    end\n    function runtime.CloseBrowser() end\n    function runtime.RestoreQuickButtons() end\n    function runtime.SyncQuickButtons() end\n    function runtime.ClearQuickButtons() prefs.shortcuts = {}; Save() end\n    function runtime.DestroyBrowser()\n        for _, connection in ipairs(UI.connections) do pcall(function() connection:Disconnect() end) end\n        UI.connections = {}\n        destroyQuickGui()\n        if UI.root then UI.root:Destroy() end\n        UI.root = nil; UI.cards = {}\n    end\nend\n\n-- The supplied card browser is embedded directly in Noir's Emotes page; no duplicate native control sections.\nfunction runtime.SyncNative() end\nruntime.initializing=false\n_G[KEY]=runtime\nlocal cache=ReadJSON(CACHE)\nlocal cachedItems=NormalizeCatalog(cache)\nAdoptCatalog(cachedItems or BUILTIN,cachedItems and \"saved cache\" or \"built-in starter list\")\nStatus(\"Ready — select an emote and press Play\")\nRefreshCatalog()\ntask.defer(function()\n    if runtime.alive then runtime.OpenBrowser() end\nend)\n\n"
    local compiler = loadstring
    if type(compiler) ~= "function" then
        warn("[Noir Emotes] loadstring is unavailable; the Emotes tab could not be started.")
        return
    end
    local okCompile, moduleFn = pcall(compiler, __noirEmotesSource)
    if not okCompile or type(moduleFn) ~= "function" then
        warn("[Noir Emotes] module compile failed: " .. tostring(moduleFn))
        return
    end
    local okRun, err = xpcall(moduleFn, function(message) return tostring(message) end)
    if not okRun then warn("[Noir Emotes] module startup failed: " .. tostring(err)) end
end)



local selfMods = tab:AddSection("MAIN • SELF MODS", "Universal player controls")
selfMods:AddToggle("Enable WalkSpeed", function(v) utility.walkEnabled = v; applyCharacterMods() end)
selfMods:AddSlider("WalkSpeed", 8, 100, 16, function(v) utility.walkSpeed = v; applyCharacterMods() end)
selfMods:AddToggle("Enable JumpPower", function(v) utility.jumpEnabled = v; applyCharacterMods() end)
selfMods:AddSlider("JumpPower", 25, 150, 50, function(v) utility.jumpPower = v; applyCharacterMods() end)
selfMods:AddToggle("Anti AFK", function(v) utility.antiAfk = v end)

__NOIR_GUARD.SetupNoirSpeedGlitch = function()
    local speedGlitchSection = tab:AddSection("MAIN • SPEED GLITCH", "Better ODH movement timing with a Noir event-horizon control")
    do
        local previousSpeedRuntime
        pcall(function() previousSpeedRuntime = getgenv().__NoirSpeedGlitchRuntime end)
        if type(previousSpeedRuntime) == "table" and type(previousSpeedRuntime.Stop) == "function" then pcall(previousSpeedRuntime.Stop) end
    
        local speed = {
            alive = true, uiEnabled = false, enabled = false, onlyWorkSideways = false,
            sideSpeed = 150, toggleSize = 64, selectedEmote = "Moonwalk", selectedEmoteId = "79127989560307",
            customEmoteId = nil, character = nil, humanoid = nil, root = nil, isJumping = false,
            screenGui = nil, toggleButton = nil, mark = nil, heartbeat = nil, connections = {}, uiConnections = {}, characterConnections = {},
        }
        local emotes = {
            ["Moonwalk"] = "79127989560307",
            ["Happier Jump"] = "15610015346",
            ["Bouncy Twirl"] = "14353423348",
            ["Flex Walk"] = "15506506103",
        }
        local function disconnectList(list)
            for _, connection in ipairs(list) do pcall(function() connection:Disconnect() end) end
            table.clear(list)
        end
        local function bindCharacter(character)
            disconnectList(speed.characterConnections)
            speed.character, speed.humanoid, speed.root, speed.isJumping = character, nil, nil, false
            if not character then return end
            task.spawn(function()
                local humanoid = character:WaitForChild("Humanoid", 8)
                local root = character:WaitForChild("HumanoidRootPart", 8)
                if not speed.alive or LocalPlayer.Character ~= character or not (humanoid and root) then return end
                speed.humanoid, speed.root = humanoid, root
                speed.characterConnections[#speed.characterConnections + 1] = humanoid.Jumping:Connect(function()
                    speed.isJumping = true
                end)
                speed.characterConnections[#speed.characterConnections + 1] = humanoid.StateChanged:Connect(function(_, state)
                    if state == Enum.HumanoidStateType.Landed then speed.isJumping = false end
                end)
            end)
        end
        if LocalPlayer.Character then bindCharacter(LocalPlayer.Character) end
        speed.connections[#speed.connections + 1] = LocalPlayer.CharacterAdded:Connect(bindCharacter)
    
        local function playEmote(id)
            if not speed.character then return end
            local humanoid = speed.character:FindFirstChildOfClass("Humanoid")
            if not humanoid then return end
            local ok = pcall(function() humanoid:PlayEmoteAndGetAnimTrackById(id) end)
            if not ok then
                local animation = Instance.new("Animation")
                animation.AnimationId = "rbxassetid://" .. tostring(id)
                local loaded, track = pcall(function() return humanoid:LoadAnimation(animation) end)
                if loaded and track then pcall(function() track:Play() end) end
            end
        end
        local function updateButtonVisual()
            local button = speed.toggleButton
            if not button then return end
            TweenService:Create(button, TweenInfo.new(.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                BackgroundColor3 = speed.enabled and Color3.fromRGB(22,24,29) or Color3.fromRGB(7,8,11),
            }):Play()
            local label = button:FindFirstChild("SpeedStatus")
            if label then label.Text = speed.enabled and "GLITCH  //  ON" or "GLITCH  //  OFF" end
            local outline = button:FindFirstChild("SpeedOutline")
            if outline then
                TweenService:Create(outline, TweenInfo.new(.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                    Color = speed.enabled and C.accent2 or C.border,
                    Transparency = speed.enabled and .05 or .24,
                }):Play()
            end
            if speed.mark and speed.mark.image then
                TweenService:Create(speed.mark.image, TweenInfo.new(.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                    ImageTransparency = speed.enabled and 0 or .08,
                }):Play()
            end
        end
        local function toggleMovement(enabled)
            speed.enabled = enabled == true
            if speed.heartbeat then speed.heartbeat:Disconnect(); speed.heartbeat = nil end
            if speed.enabled then
                speed.heartbeat = RunService.Heartbeat:Connect(function()
                    if not speed.enabled or not speed.character or not speed.humanoid or not speed.root or not speed.isJumping then return end
                    local moveDirection = speed.humanoid.MoveDirection
                    if moveDirection.Magnitude <= 0 then return end
                    local directionToUse
                    if speed.onlyWorkSideways then
                        local camera = Workspace.CurrentCamera
                        if not camera then return end
                        local right = camera.CFrame.RightVector
                        local flatRight = Vector3.new(right.X, 0, right.Z)
                        if flatRight.Magnitude <= 0 then return end
                        flatRight = flatRight.Unit
                        local sidewaysAmount = flatRight:Dot(moveDirection)
                        if math.abs(sidewaysAmount) < .35 then return end
                        directionToUse = flatRight * (sidewaysAmount > 0 and 1 or -1)
                    else
                        directionToUse = moveDirection.Unit
                    end
                    speed.root.Velocity = directionToUse * speed.sideSpeed + Vector3.new(0, speed.root.Velocity.Y, 0)
                end)
            end
            updateButtonVisual()
        end
        local function toggleUi(enabled)
            speed.uiEnabled = enabled == true
            if not speed.uiEnabled then
                toggleMovement(false)
                disconnectList(speed.uiConnections)
                if speed.screenGui then speed.screenGui:Destroy() end
                speed.screenGui, speed.toggleButton, speed.mark = nil, nil, nil
                return
            end
            if speed.toggleButton and speed.toggleButton.Parent then return end
            disconnectList(speed.uiConnections)
            if speed.screenGui then speed.screenGui:Destroy(); speed.screenGui = nil end
            local parent = guiParent
            if typeof(parent) ~= "Instance" then parent = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui") end
            local screen = New("ScreenGui", { Parent = parent, Name = "NoirSpeedGlitchToggle", ResetOnSpawn = false,
                IgnoreGuiInset = true, DisplayOrder = 90, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
            local button = New("TextButton", { Parent = screen, Name = "SpeedGlitch", AnchorPoint = Vector2.new(.5,.5),
                Position = NoirPersistence.GetPosition("speed_glitch_toggle_v6", UDim2.new(.80,0,.72,0)),
                Size = UDim2.fromOffset(speed.toggleSize, speed.toggleSize), BackgroundColor3 = Color3.fromRGB(7,8,11), BackgroundTransparency = .42,
                BorderSizePixel = 0, Text = "", AutoButtonColor = false, Active = true, ZIndex = 90 })
            corner(button, 999)
            local outline = New("UIStroke", { Parent = button, Name = "SpeedOutline", Color = C.border, Transparency = .24, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
            local outlineGradient = New("UIGradient", { Parent = outline, Rotation = 35, Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0,C.dim), ColorSequenceKeypoint.new(.24,C.accent2),
                ColorSequenceKeypoint.new(.55,C.dim), ColorSequenceKeypoint.new(.78,C.accent2), ColorSequenceKeypoint.new(1,C.dim),
            }) })
            
            pcall(function() __NOIR_GUARD.blackhole.StyleFloat(button, nil) end)
            pcall(function() __NOIR_GUARD.floatIcon(button, "GLITCH") end)
            local label = New("TextLabel", { Parent = button, Name = "SpeedStatus", AnchorPoint = Vector2.new(.5,.5),
                Position = UDim2.new(.5,0,.82,0), Size = UDim2.new(.92,0,0,math.max(13,math.floor(speed.toggleSize*.18))),
                BackgroundTransparency = 1, Text = "GLITCH  //  OFF", TextColor3 = C.text,
                TextSize = math.clamp(math.floor(speed.toggleSize*.14),8,12), Font = Enum.Font.GothamBold,
                TextScaled = false, TextWrapped = true, ZIndex = 94 })
            speed.screenGui, speed.toggleButton, speed.mark = screen, button, nil
            updateButtonVisual()
            local dragging, moved, dragStart, startPosition, dragInput = false, false, nil, nil, nil
            speed.uiConnections[#speed.uiConnections + 1] = button.InputBegan:Connect(function(input)
                if not isPrimaryPress(input) then return end
                dragging, moved, dragStart, startPosition = true, false, input.Position, button.Position
            end)
            speed.uiConnections[#speed.uiConnections + 1] = button.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
            end)
            speed.uiConnections[#speed.uiConnections + 1] = UIS.InputChanged:Connect(function(input)
                if not dragging or input ~= dragInput then return end
                local delta = input.Position - dragStart
                if delta.Magnitude > 7 then moved = true end
                local camera = Workspace.CurrentCamera
                local view = camera and camera.ViewportSize or Vector2.new(1280,720)
                local x = math.clamp(startPosition.X.Scale * view.X + startPosition.X.Offset + delta.X, speed.toggleSize*.5, view.X-speed.toggleSize*.5)
                local y = math.clamp(startPosition.Y.Scale * view.Y + startPosition.Y.Offset + delta.Y, speed.toggleSize*.5, view.Y-speed.toggleSize*.5)
                button.Position = UDim2.fromOffset(x,y)
            end)
            speed.uiConnections[#speed.uiConnections + 1] = UIS.InputEnded:Connect(function(input)
                if not dragging or not isPrimaryPress(input) then return end
                dragging = false
                NoirPersistence.SetPosition("speed_glitch_toggle_v6", button.Position)
            end)
            speed.uiConnections[#speed.uiConnections + 1] = button.Activated:Connect(function()
                if moved then moved = false; return end
                toggleMovement(not speed.enabled)
                if speed.enabled and speed.selectedEmoteId then playEmote(speed.selectedEmoteId) end
            end)
        end
        local function resizeToggleButton(value)
            speed.toggleSize = math.clamp(math.floor(tonumber(value) or speed.toggleSize), 40, 150)
            local button = speed.toggleButton
            if not button then return end
            button.Size = UDim2.fromOffset(speed.toggleSize, speed.toggleSize)
            if speed.mark and speed.mark.root then
                local diameter = math.floor(speed.toggleSize * .52)
                speed.mark.root.Size = UDim2.fromOffset(diameter, diameter)
                speed.mark.root.Position = UDim2.new(.5,0,.38,0)
                local markCorner = speed.mark.root:FindFirstChildOfClass("UICorner")
                if markCorner then markCorner.CornerRadius = UDim.new(0, math.floor(diameter * .5)) end
            end
            local status = button:FindFirstChild("SpeedStatus")
            if status then
                status.Size = UDim2.new(.92,0,0,math.max(13,math.floor(speed.toggleSize*.18)))
                status.TextSize = math.clamp(math.floor(speed.toggleSize*.14),8,12)
            end
        end
        function speed.Stop()
            speed.alive = false
            toggleMovement(false)
            disconnectList(speed.connections)
            disconnectList(speed.uiConnections)
            disconnectList(speed.characterConnections)
            if speed.screenGui then speed.screenGui:Destroy() end
            speed.screenGui, speed.toggleButton, speed.mark = nil, nil, nil
        end
        pcall(function() getgenv().__NoirSpeedGlitchRuntime = speed end)
        task.spawn(function()
            while speed.alive and gui.Parent do
                task.wait(1)
                if not speed.alive or not gui.Parent then break end
                if speed.uiEnabled and not (speed.screenGui and speed.screenGui.Parent and speed.toggleButton and speed.toggleButton.Parent) then
                    disconnectList(speed.uiConnections)
                    if speed.screenGui then speed.screenGui:Destroy() end
                    speed.screenGui, speed.toggleButton, speed.mark = nil, nil, nil
                    toggleUi(true)
                end
            end
        end)
        speedGlitchSection:AddToggle("Enable Speed Glitch UI", toggleUi)
        speedGlitchSection:AddToggle("Only Work Sideways", function(value) speed.onlyWorkSideways = value == true end)
        speedGlitchSection:AddSlider("Side Speed", 10, 1000, speed.sideSpeed, function(value) speed.sideSpeed = tonumber(value) or speed.sideSpeed end)
        speedGlitchSection:AddSlider("Toggle Size", 40, 150, 64, resizeToggleButton)
        speedGlitchSection:AddDropdown("Select Emote", {"Moonwalk","Happier Jump","Bouncy Twirl","Flex Walk","Custom"}, function(choice)
            speed.selectedEmote = choice
            speed.selectedEmoteId = choice == "Custom" and speed.customEmoteId or emotes[choice]
        end)
        speedGlitchSection:AddTextBox("Custom Emote ID", function(value)
            if value and value ~= "" then
                speed.customEmoteId = tostring(value)
                if speed.selectedEmote == "Custom" then speed.selectedEmoteId = speed.customEmoteId end
            end
        end)
        speedGlitchSection:AddLabel("Tap the floating event-horizon button to toggle the glitch; drag to move it. Position is saved and the UI auto-recovers if removed.")
    end
end
__NOIR_GUARD.SetupNoirSpeedGlitch()
__NOIR_GUARD.SetupNoirSpeedGlitch = nil

local serverMods = tab:AddSection("MAIN • SERVER", "MM2 round information")
serverMods:AddToggle("Show Round Timer", setRoundTimerVisible)
serverMods:AddToggle("Instant Role Detection", function(v) instantRoleDetection = v; if v then task.spawn(refreshTarget) end end)
serverMods:AddToggle("Auto Notify Roles", function(v) autoNotifyRoles = v; if not v then table.clear(announcedRoles) else task.spawn(refreshTarget) end end)
serverMods:AddButton("Show Murderer Chance", showMurdererChance)
serverMods:AddButton("Refresh Roles", function() refreshTarget(true) end)
serverMods:AddLabel("Roles are sampled during the 10 second countdown.")

local gunUtilities = tab:AddSection("WORLD • GUN", "Auto GG, pickup, aura, notifications and bind button")
gunUtilities:AddToggle("Enable Auto GG", setAutoGG)
gunUtilities:AddLabel("Auto GG picks up GunDrop while you do not have a Gun.")
gunUtilities:AddButton("Grab Gun", requestGrabGun)
gunUtilities:AddToggle("Gun Aura", setGunAura)
gunUtilities:AddSlider("Gun Aura Range", 5, 250, gunUtilityState.auraRange, function(value)
    gunUtilityState.auraRange = tonumber(value) or gunUtilityState.auraRange
end)
gunUtilities:AddToggle("Auto Notify Dropped Gun", function(enabled)
    gunUtilityState.droppedGunNotify = enabled == true
    gunUtilityState.UpdateDropWatchers()
end)
gunUtilities:AddToggle("Gun Pickup Notify", function(enabled)
    gunUtilityState.gunPickupNotify = enabled == true
    gunUtilityState.wasHoldingGun = hasGunInInventory()
end)
gunUtilities:AddToggle("Enable Grab Gun Bind Button", setGrabGunBindButton)
gunUtilities:AddSlider("Grab Gun Bind Button Size", 5, 25, gunUtilityState.bindButtonSize * 100, function(value)
    gunUtilityState.bindButtonSize = (tonumber(value) or 8.5) / 100
    updateGrabGunBindButtonSize()
end)
gunUtilities:AddLabel("Round Grab Gun button: drag it to move; its size and position are saved.")

do
    local function buildCombatControls()
        local combatAim=tab:AddSection("SILENT AIM", "Server FireServer redirect")
        combatAim:AddToggle("Enabled", toggle)
        combatAim:AddToggle("Wall Check", function(v) config.wallCheck=v==true end)
        combatAim:AddToggle("Show Shoot Murder Button", setShootButtonVisible)
        combatAim:AddToggle("Lock Shoot Murder Button", function(v) config.lockShootButton=v==true end)

         
        do
            local priorOmega = getgenv().__NoirOmegaRuntime
            if type(priorOmega) == "table" and type(priorOmega.Stop) == "function" then pcall(priorOmega.Stop) end
            local omega = { enabled = false, adaptive = true, locked = false, upgrade = false, monitor = false, stopped = false,
                lastApply = -1e9, currentProfile = "--", classicIndex = nil, statusControl = nil,
                monitorGui = nil, monitorLabels = nil }
            local function pingMilliseconds()
                return math.clamp(math.floor(cachedPing * 1000 + .5), 5, 1000)
            end
            local function classicOmegaProfile(ping)
                local thresholds = { 50, 100, 150 }
                local index = omega.classicIndex or 1
                while index < 4 and ping > thresholds[index] + 4 do index += 1 end
                while index > 1 and ping <= thresholds[index - 1] - 4 do index -= 1 end
                omega.classicIndex = index
                local point = PingProfiles[index + 1] or PingProfiles[#PingProfiles]
                return { Sim = point.Sim, Interval = point.Interval, H = point.H, V = point.V, X = point.X, Y = point.Y, Z = point.Z }, "Classic " .. string.char(64 + index)
            end
            local function omegaConfig(ping)
                if omega.adaptive then
                    omega.classicIndex = nil
                    return interpolateProfile(ping), "Dynamic " .. tostring(ping) .. " ms"
                end
                return classicOmegaProfile(ping)
            end
            local function destroyOmegaMonitor()
                if omega.monitorGui then omega.monitorGui:Destroy() end
                omega.monitorGui, omega.monitorLabels = nil, nil
                for _, parent in ipairs({ guiParent, CoreGui, LocalPlayer:FindFirstChildOfClass("PlayerGui") }) do
                    if parent then
                        local stale = parent:FindFirstChild("NoirOmegaMonitor")
                        if stale then stale:Destroy() end
                    end
                end
            end
            local function createOmegaMonitor()
                if omega.monitorGui and omega.monitorGui.Parent then return end
                destroyOmegaMonitor()
                local parent = guiParent
                if typeof(parent) ~= "Instance" then parent = LocalPlayer:FindFirstChildOfClass("PlayerGui") end
                if typeof(parent) ~= "Instance" then return end
                local screen = New("ScreenGui", { Parent = parent, Name = "NoirOmegaMonitor", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 82, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
                 
                 
                local card = New("Frame", { Parent = screen, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 72), Size = UDim2.fromOffset(184, 78), BackgroundColor3 = Color3.fromRGB(10, 12, 16), BackgroundTransparency = .56, BorderSizePixel = 0, ClipsDescendants = true })
                corner(card, 12); stroke(card, C.accent, .55)
                local accent = New("Frame", { Parent = card, Position = UDim2.fromOffset(0, 11), Size = UDim2.fromOffset(2, 43), BackgroundColor3 = C.accent, BackgroundTransparency = .18, BorderSizePixel = 0 }); corner(accent, 2)
                local title = New("TextLabel", { Parent = card, Position = UDim2.fromOffset(13, 6), Size = UDim2.fromOffset(164, 15), BackgroundTransparency = 1, Text = "OMEGA • SILENT AIM", TextColor3 = C.text, TextSize = 10, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd })
                local function line(y)
                    return New("TextLabel", { Parent = card, Position = UDim2.fromOffset(13, y), Size = UDim2.fromOffset(164, 14), BackgroundTransparency = 1, Text = "", TextColor3 = C.dim, TextSize = 9, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd })
                end
                omega.monitorGui = screen
                omega.monitorLabels = { state = line(23), config = line(40), values = line(57) }
            end
            local function setText(label, value)
                if label and label.Text ~= value then label.Text = value end
            end
            local function syncOmegaControls()
                local values = {
                    maxSimulationMs = config.maxSimulationMs, predictionIntervalMs = config.predictionIntervalMs, manualPingMs = config.manualPingMs,
                    offsetX = config.offsetX, offsetY = config.offsetY, offsetZ = config.offsetZ,
                    horizontalMultiplier = config.horizontalMultiplier, verticalMultiplier = config.verticalMultiplier,
                }
                for key, value in pairs(values) do
                    local control = noirMirrorControls["pistol." .. key]
                    if type(control) == "table" and type(control.SetValue) == "function" then
                        local current = type(control.GetValue) == "function" and control:GetValue() or nil
                        if tonumber(current) ~= tonumber(value) then pcall(control.SetValue, control, value) end
                    end
                end
            end
            local function updateOmegaStatus()
                local state = not omega.enabled and "OFF" or omega.locked and "LOCKED" or "ON"
                local mode = omega.adaptive and "Adaptive" or "Classic"
                local summary = "Omega: " .. state .. "  |  " .. pingMilliseconds() .. " ms  |  " .. mode .. "  |  " .. omega.currentProfile .. (omega.upgrade and "  +Upgrade" or "")
                if omega.statusControl then omega.statusControl:SetValue(summary) end
                if omega.monitorLabels then
                    setText(omega.monitorLabels.state, state .. " • " .. mode .. (omega.upgrade and " • UPGRADE" or ""))
                    setText(omega.monitorLabels.config, tostring(pingMilliseconds()) .. " ms • " .. omega.currentProfile)
                    setText(omega.monitorLabels.values, "S:" .. tostring(config.maxSimulationMs) .. " I:" .. tostring(config.predictionIntervalMs) .. " H/V:" .. tostring(config.horizontalMultiplier) .. "/" .. tostring(config.verticalMultiplier))
                end
            end
            local function applyOmega(force)
                local now = os.clock()
                if not force and now - omega.lastApply < .4 then return end
                omega.lastApply = now
                if not omega.enabled or omega.locked then updateOmegaStatus(); return end
                local ping = pingMilliseconds()
                local profile, name = omegaConfig(ping)
                if omega.upgrade then profile.Sim += 1; profile.H += 2; profile.V += 2 end
                 
                config.maxSimulationMs = profile.Sim
                config.predictionIntervalMs = profile.Interval
                config.offsetX, config.offsetY, config.offsetZ = profile.X, profile.Y, profile.Z
                config.horizontalMultiplier, config.verticalMultiplier = profile.H, profile.V
                config.manualPingMs = ping
                omega.currentProfile = name
                 
                syncOmegaControls()
                updateOmegaStatus()
            end
            local function reconfigureOmega()
                omega.lastApply = -1e9
                applyOmega(true)
            end
            local function telemetryOmega()
                local text = "Omega • Ping " .. pingMilliseconds() .. " ms • " .. (omega.adaptive and "Adaptive" or "Classic") .. " • " .. omega.currentProfile
                notify(text, 4)
                print("[Noir Omega] " .. text)
            end

            combatAim:AddLabel("OMEGA AUTO REVERT • Noir prediction profile")
            combatAim:AddToggle("Omega Auto Revert", function(enabled)
                omega.enabled = enabled == true
                reconfigureOmega()
            end)
            combatAim:AddToggle("Omega Adaptive Engine", function(enabled)
                omega.adaptive = enabled == true
                omega.classicIndex = nil
                reconfigureOmega()
            end)
            combatAim:AddToggle("Omega Lock Config", function(enabled)
                omega.locked = enabled == true
                updateOmegaStatus()
            end)
            combatAim:AddToggle("Omega Upgrade Mode", function(enabled)
                omega.upgrade = enabled == true
                reconfigureOmega()
            end)
            combatAim:AddToggle("Omega Monitor", function(enabled)
                omega.monitor = enabled == true
                if omega.monitor then createOmegaMonitor() else destroyOmegaMonitor() end
                updateOmegaStatus()
            end)
            combatAim:AddButton("Omega Print Telemetry", telemetryOmega)
            omega.statusControl = combatAim:AddLabel("Omega: OFF  |  -- ms  |  Adaptive  |  --")
            combatAim:AddLabel("Omega changes pistol prediction only. Disable it to stop updates; the last applied values stay in place.")

            task.spawn(function()
                while running and not omega.stopped do
                    if omega.enabled or omega.monitor then applyOmega(false) end
                    task.wait(.4)
                end
            end)
            getgenv().__NoirOmegaRuntime = {
                Stop = function()
                    omega.stopped = true
                    destroyOmegaMonitor()
                end,
                Sync = function() syncOmegaControls(); updateOmegaStatus() end,
            }
        end

        combatAim:AddLabel("GUN UTILITIES • native Noir implementation")
        combatAim:AddParagraph("GUN TRIGGER BOT", "Shoots once when the centre cursor/crosshair points at the Murderer. Works with mobile Shift Lock; move off target and back to arm the next shot.")
        combatAim:AddToggle("Gun Trigger Bot", function(v) config.gunTriggerBot = v == true end)
        combatAim:AddToggle("Gun Trigger Bot Wall Check", function(v) config.gunTriggerBotWallCheck = v == true end)
        combatAim:AddToggle("Apply Prediction On Gun Trigger Bot", function(v) config.gunTriggerBotPrediction = v == true end)

        local combatGun=tab:AddSection("GUN", "Gun targeting controls")
            combatGun:AddToggle("Piercer Bullet", setPiercerBullet)
        combatGun:AddLabel("If a wall is between you and the target, the shot starts on their side of the wall. Turn this on with Silent Aim.")

        local combatKnife=tab:AddSection("KNIFE SILENT AIM", "Nearest player or Sheriff-only targeting")
        combatKnife:AddToggle("Knife Silent Aim", function(v)
            config.knifeEnabled=v==true
            if config.knifeEnabled then installHook() end
        end)
         
        local oldKnifeAuraKey = "KNIFE SILENT AIM::Knife Radius"
        local newKnifeAuraKey = "KNIFE SILENT AIM::Knife Throw Aura"
        if NoirPersistence.data.sliders[newKnifeAuraKey] == nil and NoirPersistence.data.sliders[oldKnifeAuraKey] ~= nil then
            NoirPersistence.data.sliders[newKnifeAuraKey] = NoirPersistence.data.sliders[oldKnifeAuraKey]
            NoirPersistence.Save()
        end
         
         
        local knifeAuraToggle = combatKnife:AddToggle("KnifeThrown Aura", function(v) config.knifeThrownAura=v==true end)
        if NoirPersistence.data.toggles["KNIFE SILENT AIM::KnifeThrown Aura"] == nil then
            knifeAuraToggle(true)
        end
        combatKnife:AddSlider("Knife Throw Aura", 1, 40, config.knifeRadius, function(v) config.knifeRadius = tonumber(v) or config.knifeRadius end)
        combatKnife:AddToggle("Knife Wall Check", function(v) config.knifeWallCheck=v==true end)
        combatKnife:AddToggle("Prioritize Sheriff", function(v)
            config.knifePrioritizeSheriff=v==true
        end)
        combatKnife:AddLabel("NATIVE KNIFE UTILITIES • equipped Knife only")
        local function refreshKnifeUtilities()
            local runtime = getgenv().__NoirKnifeUtilityRuntime
            if type(runtime) == "table" and type(runtime.Refresh) == "function" then pcall(runtime.Refresh, runtime) end
        end
        local function knifeRuntimeCall(method)
            local runtime = getgenv().__NoirKnifeUtilityRuntime
            if type(runtime) == "table" and type(runtime[method]) == "function" then return runtime[method](runtime) end
            notify("Knife utilities are starting", 2)
            return nil
        end
        combatKnife:AddToggle("Instant Throw", function(v)
            config.knifeInstantThrow = v == true
            if config.knifeInstantThrow then installHook() end
        end)
        combatKnife:AddToggle("Fast Throw", function(v)
            config.knifeFastThrow = v == true
            if config.knifeFastThrow then installHook() end
        end)
        combatKnife:AddToggle("Auto Kill Everyone", function(v) config.knifeAutoKillEveryone = v == true end)
        combatKnife:AddToggle("Auto Kill Sheriff", function(v) config.knifeAutoKillSheriff = v == true end)
        combatKnife:AddButton("Kill Everyone", function() knifeRuntimeCall("KillEveryone") end)
        combatKnife:AddButton("Kill Sheriff", function() knifeRuntimeCall("KillSheriff") end)
        combatKnife:AddToggle("Enable Kill Sheriff Bindable Button", function(v) config.knifeSheriffBind = v == true; refreshKnifeUtilities() end)
        local function knifePlayerChoices()
            local values = { "N/A" }
            for _, player in ipairs(getPlayers()) do if player ~= LocalPlayer then values[#values + 1] = player.Name end end
            table.sort(values, function(a, b) if a == "N/A" then return true elseif b == "N/A" then return false end return string.lower(a) < string.lower(b) end)
            return values
        end
        local selectedKnifePlayer = combatKnife:AddDropdown("Kill Player", knifePlayerChoices(), function(v) config.knifeKillPlayer = tostring(v or "N/A") end)
        combatKnife:AddButton("Kill Player", function() knifeRuntimeCall("KillSelected") end)
        combatKnife:AddButton("Refresh Kill Player List", function() selectedKnifePlayer:Refresh(knifePlayerChoices(), config.knifeKillPlayer) end)
        local function refreshKnifePlayerList()
            if selectedKnifePlayer and selectedKnifePlayer.Refresh then
                selectedKnifePlayer:Refresh(knifePlayerChoices(), config.knifeKillPlayer)
            end
        end
        Players.PlayerAdded:Connect(function() task.delay(.15, refreshKnifePlayerList) end)
        Players.PlayerRemoving:Connect(function() task.delay(.15, refreshKnifePlayerList) end)

        local function addPrediction(section,profile,prefix)
            local function addToggle(key,label)
                local control=section:AddToggle(label,function(v) profile[key]=v==true end)
                noirMirrorControls[prefix..key]=control
                revertToggleStates[prefix..key]=profile[key]==true
            end
            local function addSlider(key,label,min,max)
                local control=section:AddSlider(label,min,max,tonumber(profile[key]) or min,function(v) profile[key]=tonumber(v) or profile[key] end)
                noirMirrorControls[prefix..key]=control
                if key=="manualPingMs" then noirMirrorControls[prefix=="knife." and "knifeManualPingMs" or "manualPingMs"]=control end
            end
            addToggle("prioritizePing","Prioritize Your Ping")
            addToggle("predictJump","Predict Jump")
            addToggle("predictLag","Predict Lag")
            addSlider("maxSimulationMs","Prediction Max Simulation",20,300)
            addSlider("predictionIntervalMs","Prediction Interval",1,100)
            addSlider("manualPingMs","Prediction Ping",10,1000)
            addSlider("offsetX","X Position Offset",-100,100)
            addSlider("offsetY","Y Position Offset",-100,100)
            addSlider("offsetZ","Z Position Offset",-100,100)
            addSlider("horizontalMultiplier","Horizontal Multiplier",0,400)
            addSlider("verticalMultiplier","Vertical Multiplier",0,400)
        end

        local pistolPrediction=tab:AddSection("PISTOL PREDICTION", "Independent server-shot prediction")
        addPrediction(pistolPrediction,config,"pistol.")
        local knifePrediction=tab:AddSection("KNIFE PREDICTION", "Independent KnifeThrown prediction")
        addPrediction(knifePrediction,config.knifeAim,"knife.")

        local profileKeys={"adaptive","fixedLead","extraLead","prioritizePing","predictJump","predictLag","maxSimulationMs","predictionIntervalMs","manualPingMs","offsetX","offsetY","offsetZ","horizontalMultiplier","verticalMultiplier"}
        local function profileSnapshot(profile)
            local data={}
            for _,key in ipairs(profileKeys) do data[key]=profile[key] end
            return data
        end
        local function applyProfile(profile,data)
            if typeof(data)~="table" then return false end
            for _,key in ipairs(profileKeys) do
                if typeof(data[key])==typeof(profile[key]) then profile[key]=data[key] end
            end
            if type(syncRevertControls)=="function" then syncRevertControls() end
            return true
        end
        local function profilePresetNames(kind)
            local names={"default"}
            if type(listfiles)=="function" then
                ensurePresetFolder()
                local ok,files=pcall(listfiles,PRESET_FOLDER)
                if ok and typeof(files)=="table" then
                    local suffix="_"..string.lower(kind).."%.preset$"
                    for _,file in ipairs(files) do
                        local base=tostring(file):gsub("\\","/"):match("([^/]+)"..suffix)
                        if base and not table.find(names,base) then names[#names+1]=base end
                    end
                end
            end
            table.sort(names)
            return names
        end
        local function addProfileConfig(title,kind,profile)
            local section=tab:AddSection(title,"Independent "..kind.." preset storage")
            local selected="default"
            section:AddDropdown("Your Presets",profilePresetNames(kind),function(v) selected=cleanPresetName(v) end)
            section:AddTextBox("Preset Name",function(v) selected=cleanPresetName(v) end)
            section:AddButton("Save "..kind.." Preset",function()
                if type(writefile)~="function" then notify("Executor does not support writefile",4) return end
                ensurePresetFolder()
                local payload={version=4,kind=string.lower(kind),profile=profileSnapshot(profile)}
                local ok,encoded=pcall(function() return HttpService:JSONEncode(payload) end)
                local path=PRESET_FOLDER.."/"..selected.."_"..string.lower(kind)..".preset"
                if ok and pcall(writefile,path,xorPreset(encoded)) then notify(kind.." preset saved: "..selected,3) else notify(kind.." preset save failed",4) end
            end)
            section:AddButton("Load "..kind.." Preset",function()
                if type(readfile)~="function" then notify("Executor does not support readfile",4) return end
                local path=PRESET_FOLDER.."/"..selected.."_"..string.lower(kind)..".preset"
                local ok,data=pcall(function() return HttpService:JSONDecode(xorPreset(readfile(path))) end)
                if ok and typeof(data)=="table" and data.kind==string.lower(kind) and applyProfile(profile,data.profile) then notify(kind.." preset loaded: "..selected,3) else notify(kind.." preset not found or invalid",4) end
            end)
        end
        addProfileConfig("PISTOL NOIR CONFIG","Pistol",config)
        addProfileConfig("KNIFE NOIR CONFIG","Knife",config.knifeAim)

        syncRevertControls=function()
            for _,entry in ipairs({
                {"pistol.prioritizePing",config.prioritizePing},{"pistol.predictJump",config.predictJump},{"pistol.predictLag",config.predictLag},
                {"knife.prioritizePing",config.knifeAim.prioritizePing},{"knife.predictJump",config.knifeAim.predictJump},{"knife.predictLag",config.knifeAim.predictLag}
            }) do
                local control=noirMirrorControls[entry[1]]
                if type(control)=="function" then pcall(control,entry[2]) end
            end
            for _,entry in ipairs({
                {"pistol.maxSimulationMs",config.maxSimulationMs},{"pistol.predictionIntervalMs",config.predictionIntervalMs},{"pistol.manualPingMs",config.manualPingMs},
                {"pistol.offsetX",config.offsetX},{"pistol.offsetY",config.offsetY},{"pistol.offsetZ",config.offsetZ},{"pistol.horizontalMultiplier",config.horizontalMultiplier},{"pistol.verticalMultiplier",config.verticalMultiplier},
                {"knife.maxSimulationMs",config.knifeAim.maxSimulationMs},{"knife.predictionIntervalMs",config.knifeAim.predictionIntervalMs},{"knife.manualPingMs",config.knifeAim.manualPingMs},
                {"knife.offsetX",config.knifeAim.offsetX},{"knife.offsetY",config.knifeAim.offsetY},{"knife.offsetZ",config.knifeAim.offsetZ},{"knife.horizontalMultiplier",config.knifeAim.horizontalMultiplier},{"knife.verticalMultiplier",config.knifeAim.verticalMultiplier}
            }) do
                local control=noirMirrorControls[entry[1]]
                if type(control)=="table" and type(control.SetValue)=="function" then pcall(control.SetValue,control,entry[2]) end
            end
        local omegaRuntime = getgenv().__NoirOmegaRuntime
        if type(omegaRuntime) == "table" and type(omegaRuntime.Sync) == "function" then omegaRuntime.Sync() end
        end
    end
    buildCombatControls()
end

local remoteConnections = {}
function connectRemote(name, handler)
    local wanted = string.lower(tostring(name))
    local first
    for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
        if string.lower(remote.Name) == wanted then
            if remote:IsA("RemoteEvent") then
                first = first or remote
                table.insert(remoteConnections, remote.OnClientEvent:Connect(function(...) pcall(handler, ...) end))
            elseif remote:IsA("BindableEvent") then
                first = first or remote
                table.insert(remoteConnections, remote.Event:Connect(function(...) pcall(handler, ...) end))
            end
        end
    end
    return first
end

connectRemote("PlayerDataChanged", function(first, second)
    if typeof(second) == "table" and typeof(first) == "Instance" and first:IsA("Player") then
        consumeData({ [first.Name] = second }, false)
    else
        consumeData(first, false)
    end
end)
connectRemote("RoundStart", function(timerValue, roundData)
    beginRoundTimer(timerValue)
    murderer, sheriff, hero = nil, nil, nil
    table.clear(roleCache); table.clear(announcedRoles)
    if typeof(roundData) == "table" then consumeData(roundData, true) end
    refreshTarget(true)
end)
local function finishRound()
    resetRoundTimer()
    murderer, sheriff, hero = nil, nil, nil
    table.clear(roleCache); table.clear(announcedRoles)
end
connectRemote("RoundEndFade", finishRound)
connectRemote("RoundEnd", finishRound)
connectRemote("RoleSelect", function() task.spawn(refreshTarget) end)
connectRemote("ShowRoleSelect", function() task.spawn(refreshTarget) end)
connectRemote("ShowRoleSelectNew", function() task.spawn(refreshTarget) end)
connectRemote("ChangeTarget", function() task.spawn(refreshTarget) end)
connectRemote("GiveWeapon", function() task.spawn(refreshTarget) end)
connectRemote("KillEvent", function() task.spawn(refreshTarget) end)
connectRemote("GameOver", finishRound)
connectRemote("VictoryScreen", finishRound)
connectRemote("Stealth", function() notify("Stealth activated", 3) end)
task.spawn(function()
    while running do
        updatePing()
        autoTuneForPing()
        task.wait(0.5)
    end
end)

task.spawn(function()
    while running do
        refreshTarget()
        task.wait(instantRoleDetection and 0.5 or 2)
    end
end)

task.spawn(function()
    while running do
        local active = config.enabled or config.knifeEnabled
        if active then
            local part = targetPart()
            local settings = config.enabled and config or config.knifeAim
            if part then sampleMotion(part, settings) end
            task.wait(1 / 30)
        else
            task.wait(.2)
        end
    end
end)

aimHeld = (config.aimKey == "None")
UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local key = input.KeyCode.Name
        if key == config.aimKey then aimHeld = true end
        if key == config.autoFireKey then autoFireHeld = true end
        if key == config.toggleKey and config.toggleKey ~= "None" then toggle(not config.enabled) end
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        if config.aimKey == "MouseButton1" then aimHeld = true end
        if config.autoFireKey == "MouseButton1" then autoFireHeld = true end
    elseif input.UserInputType == Enum.UserInputType.Touch then
        if config.aimKey == "Touch" then aimHeld = true end
        if config.autoFireKey == "Touch" then autoFireHeld = true end
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local key = input.KeyCode.Name
        if key == config.aimKey then aimHeld = false end
        if key == config.autoFireKey then autoFireHeld = false end
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        if config.aimKey == "MouseButton1" then aimHeld = false end
        if config.autoFireKey == "MouseButton1" then autoFireHeld = false end
    elseif input.UserInputType == Enum.UserInputType.Touch then
        if config.aimKey == "Touch" then aimHeld = false end
        if config.autoFireKey == "Touch" then autoFireHeld = false end
    end
end)

refreshCanvas()

task.defer(function()
    RunService.RenderStepped:Wait()
    if not win.Parent then return end
    local targetPosition = win.Position
    __NOIR_GUARD.blackhole.LastWindowPosition = targetPosition
    local singularityPosition = __NOIR_GUARD.blackhole.CollapseTargetPosition()
    win.Position = singularityPosition
    win.BackgroundTransparency = 1
    win.Rotation = -4.2
    winScale.Scale = .06
    win.Visible = true
    TweenService:Create(win, TweenInfo.new(.52, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = targetPosition, BackgroundTransparency = .18, Rotation = 0,
    }):Play()
    TweenService:Create(winScale, TweenInfo.new(.54, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end)

notify("NOIR V6.4  •  EVENT HORIZON ONLINE  •  " .. tostring(#getPlayers()) .. " PLAYERS", 4)

do
    local function makeWorldPluginTab(base)
        local proxy = {}
        setmetatable(proxy, {
            __index = function(_, key)
                if key == "AddSection" then
                    return function(_, name, description)
                        name = tostring(name or "Plugin")
                        if string.sub(name, 1, 6) ~= "WORLD " then
                            name = "WORLD • " .. name
                        end
                        return base:AddSection(name, description or "")
                    end
                end
                local method = base[key]
                if type(method) == "function" then
                    return function(_, ...)
                        return method(base, ...)
                    end
                end
                return method
            end,
        })
        return proxy
    end
    local odh_shared_plugins = {
        game_name = "Murder Mystery 2",
        CreateTab = function(_, title, icon)
            return makeWorldPluginTab(host.CreateTab())
        end,
        Notify = function(textValue, duration)
            notify(tostring(textValue), duration or 3)
        end,
    }
    do
        local __pluginOk, __pluginError = xpcall(function()
local shared = odh_shared_plugins
if not shared or type(shared.CreateTab) ~= "function" then
    warn("[FE Animations] Load this file through the current Overdrive H plugin menu.")
    return
end
local KEY = "ODH_FEAnimationsRuntime_v2"
if type(_G[KEY]) == "table" and _G[KEY].alive then
    if type(shared.Notify)=="function" then
        pcall(shared.Notify,"FE Animations is already loaded. Use its existing tab.",4)
    end
    return
end
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then warn("[FE Animations] LocalPlayer unavailable."); return end
local HttpService = game:GetService("HttpService")
local runtime = {version=3,alive=true, initializing=true, enabled=false, generation=0,
    selections={all="Default",idle="Default",walk="Default",run="Default",jump="Default",climb="Default",fall="Default"}}
local FILE = "Noir Hub/configs/ODH_FEAnimations_settings.json"
runtime.settingsFile=FILE
local warnings={}
local function WarnOnce(key,text)
    if warnings[key] then return end
    warnings[key]=true
    warn("[FE Animations] "..text)
    if type(shared.Notify)=="function" then pcall(shared.Notify,"FE Animations: "..text,5) end
end
local environment={}
if type(getgenv)=="function" then
    local ok,result=pcall(getgenv)
    if ok and type(result)=="table" then environment=result end
end
local fileRead=type(readfile)=="function" and readfile or environment.readfile
local fileWrite=type(writefile)=="function" and writefile or environment.writefile
local fileExists=type(isfile)=="function" and isfile or environment.isfile
local canPersist=type(fileRead)=="function" and type(fileWrite)=="function"
runtime.saveStatus=canPersist and "Not saved" or "Unavailable"

local animPresets = {
    ["Default"] = nil,
    ["OG Rthro Run"] = {run = "http://www.roblox.com/asset/?id=9801814462"},
    ["Vampire"] = {
        idle1 = "http://www.roblox.com/asset/?id=1083445855",
        idle2 = "http://www.roblox.com/asset/?id=1083450166",
        walk  = "http://www.roblox.com/asset/?id=1083473930",
        run   = "http://www.roblox.com/asset/?id=1083462077",
        jump  = "http://www.roblox.com/asset/?id=1083455352",
        climb = "http://www.roblox.com/asset/?id=1083439238",
        fall  = "http://www.roblox.com/asset/?id=1083443587"
    },
    ["Hero"] = {
        idle1 = "http://www.roblox.com/asset/?id=616111295",
        idle2 = "http://www.roblox.com/asset/?id=616113536",
        walk  = "http://www.roblox.com/asset/?id=616122287",
        run   = "http://www.roblox.com/asset/?id=616117076",
        jump  = "http://www.roblox.com/asset/?id=616115533",
        climb = "http://www.roblox.com/asset/?id=616104706",
        fall  = "http://www.roblox.com/asset/?id=616108001"
    },
    ["Zombie Classic"] = {
        idle1 = "http://www.roblox.com/asset/?id=616158929",
        idle2 = "http://www.roblox.com/asset/?id=616160636",
        walk  = "http://www.roblox.com/asset/?id=616168032",
        run   = "http://www.roblox.com/asset/?id=616163682",
        jump  = "http://www.roblox.com/asset/?id=616161997",
        climb = "http://www.roblox.com/asset/?id=616156119",
        fall  = "http://www.roblox.com/asset/?id=616157476"
    },
    ["Mage"] = {
        idle1 = "http://www.roblox.com/asset/?id=707742142",
        idle2 = "http://www.roblox.com/asset/?id=707855907",
        walk  = "http://www.roblox.com/asset/?id=707897309",
        run   = "http://www.roblox.com/asset/?id=707861613",
        jump  = "http://www.roblox.com/asset/?id=707853694",
        climb = "http://www.roblox.com/asset/?id=707826056",
        fall  = "http://www.roblox.com/asset/?id=707829716"
    },
    ["Ghost"] = {
        idle1 = "http://www.roblox.com/asset/?id=616006778",
        idle2 = "http://www.roblox.com/asset/?id=616008087",
        walk  = "http://www.roblox.com/asset/?id=616010382",
        run   = "http://www.roblox.com/asset/?id=616013216",
        jump  = "http://www.roblox.com/asset/?id=616008936",
        climb = "http://www.roblox.com/asset/?id=616003713",
        fall  = "http://www.roblox.com/asset/?id=616005863"
    },
    ["Elder"] = {
        idle1 = "http://www.roblox.com/asset/?id=845397899",
        idle2 = "http://www.roblox.com/asset/?id=845400520",
        walk  = "http://www.roblox.com/asset/?id=845403856",
        run   = "http://www.roblox.com/asset/?id=845386501",
        jump  = "http://www.roblox.com/asset/?id=845398858",
        climb = "http://www.roblox.com/asset/?id=845392038",
        fall  = "http://www.roblox.com/asset/?id=845396048"
    },
    ["Levitation"] = {
        idle1 = "http://www.roblox.com/asset/?id=616006778",
        idle2 = "http://www.roblox.com/asset/?id=616008087",
        walk  = "http://www.roblox.com/asset/?id=616013216",
        run   = "http://www.roblox.com/asset/?id=616010382",
        jump  = "http://www.roblox.com/asset/?id=616008936",
        climb = "http://www.roblox.com/asset/?id=616003713",
        fall  = "http://www.roblox.com/asset/?id=616005863"
    },
    ["Astronaut"] = {
        idle1 = "http://www.roblox.com/asset/?id=891621366",
        idle2 = "http://www.roblox.com/asset/?id=891633237",
        walk  = "http://www.roblox.com/asset/?id=891667138",
        run   = "http://www.roblox.com/asset/?id=891636393",
        jump  = "http://www.roblox.com/asset/?id=891627522",
        climb = "http://www.roblox.com/asset/?id=891609353",
        fall  = "http://www.roblox.com/asset/?id=891617961"
    },
    ["Ninja"] = {
        idle1 = "http://www.roblox.com/asset/?id=656117400",
        idle2 = "http://www.roblox.com/asset/?id=656118341",
        walk  = "http://www.roblox.com/asset/?id=656121766",
        run   = "http://www.roblox.com/asset/?id=656118852",
        jump  = "http://www.roblox.com/asset/?id=656117878",
        climb = "http://www.roblox.com/asset/?id=656114359",
        fall  = "http://www.roblox.com/asset/?id=656115606"
    },
    ["Werewolf"] = {
        idle1 = "http://www.roblox.com/asset/?id=1083195517",
        idle2 = "http://www.roblox.com/asset/?id=1083214717",
        walk  = "http://www.roblox.com/asset/?id=1083178339",
        run   = "http://www.roblox.com/asset/?id=1083216690",
        jump  = "http://www.roblox.com/asset/?id=1083218792",
        climb = "http://www.roblox.com/asset/?id=1083182000",
        fall  = "http://www.roblox.com/asset/?id=1083189019"
    },
    ["Cartoon"] = {
        idle1 = "http://www.roblox.com/asset/?id=742637544",
        idle2 = "http://www.roblox.com/asset/?id=742638445",
        walk  = "http://www.roblox.com/asset/?id=742640026",
        run   = "http://www.roblox.com/asset/?id=742638842",
        jump  = "http://www.roblox.com/asset/?id=742637942",
        climb = "http://www.roblox.com/asset/?id=742636889",
        fall  = "http://www.roblox.com/asset/?id=742637151"
    },
    ["Pirate"] = {
        idle1 = "http://www.roblox.com/asset/?id=750781874",
        idle2 = "http://www.roblox.com/asset/?id=750782770",
        walk  = "http://www.roblox.com/asset/?id=750785693",
        run   = "http://www.roblox.com/asset/?id=750783738",
        jump  = "http://www.roblox.com/asset/?id=750782230",
        climb = "http://www.roblox.com/asset/?id=750779899",
        fall  = "http://www.roblox.com/asset/?id=750780242"
    },
    ["Sneaky"] = {
        idle1 = "http://www.roblox.com/asset/?id=1132473842",
        idle2 = "http://www.roblox.com/asset/?id=1132477671",
        walk  = "http://www.roblox.com/asset/?id=1132510133",
        run   = "http://www.roblox.com/asset/?id=1132494274",
        jump  = "http://www.roblox.com/asset/?id=1132489853",
        climb = "http://www.roblox.com/asset/?id=1132461372",
        fall  = "http://www.roblox.com/asset/?id=1132469004"
    },
    ["Toy"] = {
        idle1 = "http://www.roblox.com/asset/?id=782841498",
        idle2 = "http://www.roblox.com/asset/?id=782845736",
        walk  = "http://www.roblox.com/asset/?id=782843345",
        run   = "http://www.roblox.com/asset/?id=782842708",
        jump  = "http://www.roblox.com/asset/?id=782847020",
        climb = "http://www.roblox.com/asset/?id=782843869",
        fall  = "http://www.roblox.com/asset/?id=782846423"
    },
    ["Knight"] = {
        idle1 = "http://www.roblox.com/asset/?id=657595757",
        idle2 = "http://www.roblox.com/asset/?id=657568135",
        walk  = "http://www.roblox.com/asset/?id=657552124",
        run   = "http://www.roblox.com/asset/?id=657564596",
        jump  = "http://www.roblox.com/asset/?id=658409194",
        climb = "http://www.roblox.com/asset/?id=658360781",
        fall  = "http://www.roblox.com/asset/?id=657600338"
    },
    ["Confident"] = {
        idle1 = "http://www.roblox.com/asset/?id=1069977950",
        idle2 = "http://www.roblox.com/asset/?id=1069987858",
        walk  = "http://www.roblox.com/asset/?id=1070017263",
        run   = "http://www.roblox.com/asset/?id=1070001516",
        jump  = "http://www.roblox.com/asset/?id=1069984524",
        climb = "http://www.roblox.com/asset/?id=1069946257",
        fall  = "http://www.roblox.com/asset/?id=1069973677"
    },
    ["Popstar"] = {
        idle1 = "http://www.roblox.com/asset/?id=1212900985",
        idle2 = "http://www.roblox.com/asset/?id=1212900985",
        walk  = "http://www.roblox.com/asset/?id=1212980338",
        run   = "http://www.roblox.com/asset/?id=1212980348",
        jump  = "http://www.roblox.com/asset/?id=1212954642",
        climb = "http://www.roblox.com/asset/?id=1213044953",
        fall  = "http://www.roblox.com/asset/?id=1212900995"
    },
    ["Princess"] = {
        idle1 = "http://www.roblox.com/asset/?id=941003647",
        idle2 = "http://www.roblox.com/asset/?id=941013098",
        walk  = "http://www.roblox.com/asset/?id=941028902",
        run   = "http://www.roblox.com/asset/?id=941015281",
        jump  = "http://www.roblox.com/asset/?id=941008832",
        climb = "http://www.roblox.com/asset/?id=940996062",
        fall  = "http://www.roblox.com/asset/?id=941000007"
    },
    ["Cowboy"] = {
        idle1 = "http://www.roblox.com/asset/?id=1014390418",
        idle2 = "http://www.roblox.com/asset/?id=1014398616",
        walk  = "http://www.roblox.com/asset/?id=1014421541",
        run   = "http://www.roblox.com/asset/?id=1014401683",
        jump  = "http://www.roblox.com/asset/?id=1014394726",
        climb = "http://www.roblox.com/asset/?id=1014380606",
        fall  = "http://www.roblox.com/asset/?id=1014384571"
    },
    ["Patrol"] = {
        idle1 = "http://www.roblox.com/asset/?id=1149612882",
        idle2 = "http://www.roblox.com/asset/?id=1150842221",
        walk  = "http://www.roblox.com/asset/?id=1151231493",
        run   = "http://www.roblox.com/asset/?id=1150967949",
        jump  = "http://www.roblox.com/asset/?id=1150944216",
        climb = "http://www.roblox.com/asset/?id=1148811837",
        fall  = "http://www.roblox.com/asset/?id=1148863382"
    },
    ["Zombie FE"] = {
        idle1 = "http://www.roblox.com/asset/?id=3489171152",
        idle2 = "http://www.roblox.com/asset/?id=3489171152",
        walk  = "http://www.roblox.com/asset/?id=3489174223",
        run   = "http://www.roblox.com/asset/?id=3489173414",
        jump  = "http://www.roblox.com/asset/?id=616161997",
        climb = "http://www.roblox.com/asset/?id=616156119",
        fall  = "http://www.roblox.com/asset/?id=616157476"
    },
    ["Catwalk Glam"] = {
        idle1 = "http://www.roblox.com/asset/?id=133806214992291",
        idle2 = "http://www.roblox.com/asset/?id=133806214992291",
        walk  = "http://www.roblox.com/asset/?id=109168724482748",
        run   = "http://www.roblox.com/asset/?id=81024476153754",
        jump  = "http://www.roblox.com/asset/?id=116936326516985",
        climb = "http://www.roblox.com/asset/?id=119377220967554",
        fall  = "http://www.roblox.com/asset/?id=92294537340807"
    },
    ["Amazon Unboxed"] = {
        idle1 = "http://www.roblox.com/asset/?id=98281136301627",
        idle2 = "http://www.roblox.com/asset/?id=98281136301627",
        walk  = "http://www.roblox.com/asset/?id=90478085024465",
        run   = "http://www.roblox.com/asset/?id=134824450619865",
        jump  = "http://www.roblox.com/asset/?id=121454505477205",
        climb = "http://www.roblox.com/asset/?id=121145883950231",
        fall  = "http://www.roblox.com/asset/?id=94788218468396"
    },
    ["Glow Motion"] = {
        idle1 = "https://www.roblox.com/asset/?id=137764781910579",
        idle2 = "https://www.roblox.com/asset/?id=137764781910579",
        walk  = "http://www.roblox.com/asset/?id=85809016093530",
        run   = "http://www.roblox.com/asset/?id=101925097435036",
        jump  = "http://www.roblox.com/asset/?id=74159004634379",
        climb = "http://www.roblox.com/asset/?id=108236155509584",
        fall  = "https://www.roblox.com/asset/?id=98070939608691"
    },
    ["Bubbly"] = {
        idle1 = "https://www.roblox.com/asset/?id=10921054344",
        idle2 = "https://www.roblox.com/asset/?id=10921054344",
        walk  = "http://www.roblox.com/asset/?id=10980888364",
        run   = "http://www.roblox.com/asset/?id=10921057244",
        jump  = "http://www.roblox.com/asset/?id=10921062673",
        climb = "http://www.roblox.com/asset/?id=10921053544",
        fall  = "https://www.roblox.com/asset/?id=10921061530"
    },
    ["Adidas Comm"] = {
        idle1 = "https://www.roblox.com/asset/?id=122257458498464",
        idle2 = "https://www.roblox.com/asset/?id=122257458498464",
        walk  = "http://www.roblox.com/asset/?id=122150855457006",
        run   = "http://www.roblox.com/asset/?id=82598234841035",
        jump  = "http://www.roblox.com/asset/?id=75290611992385",
        climb = "http://www.roblox.com/asset/?id=88763136693023",
        fall  = "https://www.roblox.com/asset/?id=98600215928904"
    },
    ["KATSEYE"] = {
        idle1 = "https://www.roblox.com/asset/?id=108187809145790",
        idle2 = "https://www.roblox.com/asset/?id=108187809145790",
        walk  = "http://www.roblox.com/asset/?id=99182913548783",
        run   = "http://www.roblox.com/asset/?id=73117360545482",
        jump  = "http://www.roblox.com/asset/?id=103632305262747",
        climb = "http://www.roblox.com/asset/?id=106213237973858",
        fall  = "https://www.roblox.com/asset/?id=127802717128367"
    },
    ["Wicked Popular"] = {
        idle1 = "https://www.roblox.com/asset/?id=118832222982049",
        idle2 = "https://www.roblox.com/asset/?id=118832222982049",
        walk  = "http://www.roblox.com/asset/?id=92072849924640",
        run   = "http://www.roblox.com/asset/?id=72301599441680",
        jump  = "http://www.roblox.com/asset/?id=104325245285198",
        climb = "http://www.roblox.com/asset/?id=131326830509784",
        fall  = "https://www.roblox.com/asset/?id=121152442762481"
    },
    ["Dizzy"] = {
        idle1 = "http://www.roblox.com/asset/?id=132806359718468",
        idle2 = "http://www.roblox.com/asset/?id=132806359718468",
        walk  = "http://www.roblox.com/asset/?id=110106034100313",
        run   = "http://www.roblox.com/asset/?id=138305342272849",
        jump  = "http://www.roblox.com/asset/?id=108564434408211",
        climb = "http://www.roblox.com/asset/?id=93550710314258",
        fall  = "http://www.roblox.com/asset/?id=138967706335414"
    },
    ["WDTL"] = {
        idle1 = "http://www.roblox.com/asset/?id=92849173543269",
        idle2 = "http://www.roblox.com/asset/?id=92849173543269",
        walk  = "http://www.roblox.com/asset/?id=73718308412641",
        run   = "http://www.roblox.com/asset/?id=135515454877967",
        jump  = "http://www.roblox.com/asset/?id=78508480717326",
        climb = "http://www.roblox.com/asset/?id=129447497744818",
        fall  = "http://www.roblox.com/asset/?id=78147885297412"
    },
    ["Billie Eilish"] = {
        idle1 = "http://www.roblox.com/asset/?id=102934602884410",
        idle2 = "http://www.roblox.com/asset/?id=102934602884410",
        walk  = "http://www.roblox.com/asset/?id=81877886552514",
        run   = "http://www.roblox.com/asset/?id=100920560634123",
        jump  = "http://www.roblox.com/asset/?id=117602630922781",
        climb = "http://www.roblox.com/asset/?id=117873469361430",
        fall  = "http://www.roblox.com/asset/?id=81072141180299"
    },
    ["Cute Bouncy"] = {
        idle1 = "http://www.roblox.com/asset/?id=88464649697812",
        idle2 = "http://www.roblox.com/asset/?id=88464649697812",
        walk  = "http://www.roblox.com/asset/?id=98713727778027",
        run   = "http://www.roblox.com/asset/?id=133955346539948",
        jump  = "http://www.roblox.com/asset/?id=124147147418885",
        climb = "http://www.roblox.com/asset/?id=95542189442725",
        fall  = "http://www.roblox.com/asset/?id=128620818122982"
    },
    ["Cute"] = {
        idle1 = "http://www.roblox.com/asset/?id=85735421117197",
        idle2 = "http://www.roblox.com/asset/?id=85735421117197",
        walk  = "http://www.roblox.com/asset/?id=140409718187215",
        run   = "http://www.roblox.com/asset/?id=118375157537412",
        jump  = "http://www.roblox.com/asset/?id=132381016103721",
        climb = "http://www.roblox.com/asset/?id=86318575131600",
        fall  = "http://www.roblox.com/asset/?id=77496925287217"
    },
    ["Jolly"] = {
        idle1 = "http://www.roblox.com/asset/?id=136145727878709",
        idle2 = "http://www.roblox.com/asset/?id=136145727878709",
        walk  = "http://www.roblox.com/asset/?id=83277136078444",
        run   = "http://www.roblox.com/asset/?id=124419804298310",
        jump  = "http://www.roblox.com/asset/?id=122115816220842",
        climb = "http://www.roblox.com/asset/?id=107190574095036",
        fall  = "http://www.roblox.com/asset/?id=85263802503331"
    },
    ["Cute Kawaii"] = {
        idle1 = "http://www.roblox.com/asset/?id=72311682331639",
        idle2 = "http://www.roblox.com/asset/?id=72311682331639",
        walk  = "http://www.roblox.com/asset/?id=107212872423561",
        run   = "http://www.roblox.com/asset/?id=118582510545072",
        jump  = "http://www.roblox.com/asset/?id=112952548321695",
        climb = "http://www.roblox.com/asset/?id=126383408493776",
        fall  = "http://www.roblox.com/asset/?id=83307333809322"
    },
    ["Doll 3.0"] = {
        idle1 = "http://www.roblox.com/asset/?id=83032187271383",
        idle2 = "http://www.roblox.com/asset/?id=83032187271383",
        walk  = "http://www.roblox.com/asset/?id=78434960966537",
        run   = "http://www.roblox.com/asset/?id=129768396663808",
        jump  = "http://www.roblox.com/asset/?id=75369057994828",
        climb = "http://www.roblox.com/asset/?id=112371892133970",
        fall  = "http://www.roblox.com/asset/?id=81027444073311"
    },
    ["Victoria Model"] = {
        idle1 = "http://www.roblox.com/asset/?id=132069965396465",
        idle2 = "http://www.roblox.com/asset/?id=132069965396465",
        walk  = "http://www.roblox.com/asset/?id=84814915379579",
        run   = "http://www.roblox.com/asset/?id=84814915379579",
        jump  = "http://www.roblox.com/asset/?id=78163261581163",
        climb = "http://www.roblox.com/asset/?id=87772134905508",
        fall  = "http://www.roblox.com/asset/?id=110073924253388"
    },
    ["Bike/Bicyclist"] = {
        idle1 = "http://www.roblox.com/asset/?id=126390120399173",
        idle2 = "http://www.roblox.com/asset/?id=136791517336633",
        walk  = "http://www.roblox.com/asset/?id=98707881660541",
        run   = "http://www.roblox.com/asset/?id=102775737211919",
        jump  = "http://www.roblox.com/asset/?id=129144847881258",
        climb = "http://www.roblox.com/asset/?id=88267082364595",
        fall  = "http://www.roblox.com/asset/?id=110684787086498"
    },
    ["Animal"] = {
        idle1 = "http://www.roblox.com/asset/?id=128838183008466",
        idle2 = "http://www.roblox.com/asset/?id=99689776099970",
        walk  = "http://www.roblox.com/asset/?id=112238064449133",
        run   = "http://www.roblox.com/asset/?id=97412731442167",
        jump  = "http://www.roblox.com/asset/?id=123565665274439",
        climb = "http://www.roblox.com/asset/?id=75085836535654",
        fall  = "http://www.roblox.com/asset/?id=124705831982259"
    },
    ["It-Girl Essential Model"] = {
        idle1 = "http://www.roblox.com/asset/?id=132232079260125",
        idle2 = "http://www.roblox.com/asset/?id=102440789796215",
        walk  = "http://www.roblox.com/asset/?id=86579666661215",
        run   = "http://www.roblox.com/asset/?id=83336349930143",
        jump  = "http://www.roblox.com/asset/?id=103382156539106",
        climb = "http://www.roblox.com/asset/?id=77385815954046",
        fall  = "http://www.roblox.com/asset/?id=127262648208409"
    },
    ["Oldschool"] = {
        idle1 = "http://www.roblox.com/asset/?id=10921230744",
        idle2 = "http://www.roblox.com/asset/?id=10921232093",
        walk  = "http://www.roblox.com/asset/?id=10921244891",
        run   = "http://www.roblox.com/asset/?id=10921240218",
        jump  = "http://www.roblox.com/asset/?id=10921242013",
        climb = "http://www.roblox.com/asset/?id=10921229866",
        fall  = "http://www.roblox.com/asset/?id=10921241244"
    },
    ["Spider"] = {
        idle1 = "http://www.roblox.com/asset/?id=112316814377814",
        idle2 = "http://www.roblox.com/asset/?id=103439018552145",
        walk  = "http://www.roblox.com/asset/?id=109976439277879",
        run   = "http://www.roblox.com/asset/?id=119985832593347",
        jump  = "http://www.roblox.com/asset/?id=87979233462906",
        climb = "http://www.roblox.com/asset/?id=119278342251995",
        fall  = "http://www.roblox.com/asset/?id=71112238570777"
    },
    ["Joy"] = {
        idle1 = "http://www.roblox.com/asset/?id=119957475250242",
        idle2 = "http://www.roblox.com/asset/?id=101200477339169",
        walk  = "http://www.roblox.com/asset/?id=112597572150963",
        run   = "http://www.roblox.com/asset/?id=96521659811743",
        jump  = "http://www.roblox.com/asset/?id=82500357520736",
        climb = "http://www.roblox.com/asset/?id=110061716873830",
        fall  = "http://www.roblox.com/asset/?id=132095139090357"
    },
    ["Flying Aura"] = {
        idle1 = "http://www.roblox.com/asset/?id=122426844584505",
        idle2 = "http://www.roblox.com/asset/?id=122426844584505",
        walk  = "http://www.roblox.com/asset/?id=83077254246622",
        run   = "http://www.roblox.com/asset/?id=77053251062908",
        jump  = "http://www.roblox.com/asset/?id=125422018244301",
        climb = "http://www.roblox.com/asset/?id=95973965948476",
        fall  = "http://www.roblox.com/asset/?id=109790195947848"
    },

    ["FHA V2"] = {
        idle1 = "http://www.roblox.com/asset/?id=77320840005481",
        idle2 = "http://www.roblox.com/asset/?id=77320840005481",
        walk  = "http://www.roblox.com/asset/?id=134493251445479",
        run   = "http://www.roblox.com/asset/?id=122214533401932",
        jump  = "http://www.roblox.com/asset/?id=80078165493816",
        climb = "http://www.roblox.com/asset/?id=114562994724647",
        fall  = "http://www.roblox.com/asset/?id=98383265864436"
    },

    ["Silent Nurse"] = {
        idle1 = "http://www.roblox.com/asset/?id=111047244862844",
        idle2 = "http://www.roblox.com/asset/?id=111047244862844",
        walk  = "http://www.roblox.com/asset/?id=94196382152901",
        run   = "http://www.roblox.com/asset/?id=94196382152901",
        jump  = "http://www.roblox.com/asset/?id=106098057235980",
        climb = "http://www.roblox.com/asset/?id=108985375609705",
        fall  = "http://www.roblox.com/asset/?id=131579609334755"
    },

    ["Supermodel"] = {
        idle1 = "http://www.roblox.com/asset/?id=91917730726110",
        idle2 = "http://www.roblox.com/asset/?id=91917730726110",
        walk  = "http://www.roblox.com/asset/?id=90320132970213",
        run   = "http://www.roblox.com/asset/?id=112051258179255",
        jump  = "http://www.roblox.com/asset/?id=91931403363860",
        climb = "http://www.roblox.com/asset/?id=82728029306069",
        fall  = "http://www.roblox.com/asset/?id=119173466228299"
    },

    ["Enchanted Fairy"] = {
        idle1 = "http://www.roblox.com/asset/?id=73650178233095",
        idle2 = "http://www.roblox.com/asset/?id=73650178233095",
        walk  = "http://www.roblox.com/asset/?id=94547195663763",
        run   = "http://www.roblox.com/asset/?id=76909584337943",
        jump  = "http://www.roblox.com/asset/?id=120533712803667",
        climb = "http://www.roblox.com/asset/?id=140663406485180",
        fall  = "http://www.roblox.com/asset/?id=100947971756348"
    },

    ["Furry"] = {
        idle1 = "http://www.roblox.com/asset/?id=111821292044705",
        idle2 = "http://www.roblox.com/asset/?id=111821292044705",
        walk  = "http://www.roblox.com/asset/?id=104011441852459",
        run   = "http://www.roblox.com/asset/?id=87770060317862",
        jump  = "http://www.roblox.com/asset/?id=102635582722041",
        climb = "http://www.roblox.com/asset/?id=76660530164497",
        fall  = "http://www.roblox.com/asset/?id=137079985547592"
    },

    ["Vlada Model"] = {
        idle1 = "http://www.roblox.com/asset/?id=100139116433530",
        idle2 = "http://www.roblox.com/asset/?id=100139116433530",
        walk  = "http://www.roblox.com/asset/?id=77983757225444",
        run   = "http://www.roblox.com/asset/?id=116717848244930",
        jump  = "http://www.roblox.com/asset/?id=120751055172567",
        climb = "http://www.roblox.com/asset/?id=70966616077778",
        fall  = "http://www.roblox.com/asset/?id=136118518255777"
    },
    ["R6 Converter"] = {
        idle1 = "http://www.roblox.com/asset/?id=90040240627854",
        idle2 = "http://www.roblox.com/asset/?id=90040240627854",
        walk  = "http://www.roblox.com/asset/?id=92149852708428",
        run   = "http://www.roblox.com/asset/?id=72259383092959",
        jump  = "http://www.roblox.com/asset/?id=130519980521511",
        climb = "http://www.roblox.com/asset/?id=80369171706383",
        fall  = "http://www.roblox.com/asset/?id=130011792193300"
    },
}

local animMap = {
    idle  = { folder = "idle",  slots = { { child = "Animation1", origKey = "idle1" }, { child = "Animation2", origKey = "idle2" } } },
    walk  = { folder = "walk",  slots = { { child = "WalkAnim",   origKey = "walk"  } } },
    run   = { folder = "run",   slots = { { child = "RunAnim",    origKey = "run"   } } },
    jump  = { folder = "jump",  slots = { { child = "JumpAnim",   origKey = "jump"  } } },
    climb = { folder = "climb", slots = { { child = "ClimbAnim",  origKey = "climb" } } },
    fall  = { folder = "fall",  slots = { { child = "FallAnim",   origKey = "fall"  } } },
}

local allAnimOptions = {
    "Default", "Vampire", "Hero", "Zombie Classic", "Mage", "Ghost",
    "Elder", "Levitation", "Astronaut", "Ninja", "Werewolf", "Cartoon",
    "Pirate", "Sneaky", "Toy", "Knight", "Confident", "Popstar",
    "Princess", "Cowboy", "Patrol", "Zombie FE", "Catwalk Glam", "Amazon Unboxed",
    "Glow Motion", "Bubbly", "Adidas Comm", "KATSEYE", "Wicked Popular",
    "Dizzy", "WDTL", "Billie Eilish", "Cute Bouncy", "Cute",
    "Jolly", "Cute Kawaii", "Doll 3.0", "Victoria Model",
    "Bike/Bicyclist", "Animal", "It-Girl Essential Model",
    "Oldschool", "Spider", "Joy", "Flying Aura", "FHA V2", "Silent Nurse", "Supermodel", "Enchanted Fairy", "Furry", "Vlada Model", "R6 Converter"
}

local runAnimOptions = {
    "Default", "OG Rthro Run", "Vampire", "Hero", "Zombie Classic", "Mage", "Ghost",
    "Elder", "Levitation", "Astronaut", "Ninja", "Werewolf", "Cartoon",
    "Pirate", "Sneaky", "Toy", "Knight", "Confident", "Popstar",
    "Princess", "Cowboy", "Patrol", "Zombie FE", "Catwalk Glam", "Amazon Unboxed",
    "Glow Motion", "Bubbly", "Adidas Comm", "KATSEYE", "Wicked Popular",
    "Dizzy", "WDTL", "Billie Eilish", "Cute Bouncy", "Cute",
    "Jolly", "Cute Kawaii", "Doll 3.0", "Victoria Model",
    "Bike/Bicyclist", "Animal", "It-Girl Essential Model",
    "Oldschool", "Spider", "Joy", "Flying Aura", "FHA V2", "Silent Nurse", "Supermodel", "Enchanted Fairy", "Furry", "Vlada Model", "R6 Converter"
}

local allowed={}
for key in pairs(runtime.selections) do
    allowed[key]={}
    for _,name in ipairs(key=="run" and runAnimOptions or allAnimOptions) do allowed[key][name]=true end
end
local function LoadSettings()
    if not canPersist then
        WarnOnce("filesystem","readfile/writefile unavailable; settings are session-only.")
        return
    end
    if type(fileExists)=="function" then
        local ok,exists=pcall(fileExists,FILE)
        if ok and not exists then return end
    end
    local ok,text=pcall(fileRead,FILE)
    if not ok then
        if type(fileExists)=="function" then
            runtime.saveStatus="Read error"
            WarnOnce("read","Cannot read the settings file.")
        end
        return
    end
    local decoded,data=pcall(function() return HttpService:JSONDecode(text) end)
    if not decoded or type(data)~="table" or data.version~=1 or type(data.selections)~="table" then
        runtime.saveStatus="Invalid file"
        WarnOnce("read","Invalid settings file; kept unchanged until you edit a setting.")
        return
    end
    if type(data.enabled)=="boolean" then runtime.enabled=data.enabled end
    for key in pairs(runtime.selections) do
        local value=data.selections[key]
        if type(value)=="string" and allowed[key][value] then runtime.selections[key]=value end
    end
    runtime.saveStatus="Loaded"
end
local function SaveSettings()
    if not runtime.alive or runtime.initializing or not canPersist then return false end
    local ok,err=pcall(function()
        fileWrite(FILE,HttpService:JSONEncode({version=1,enabled=runtime.enabled,selections=runtime.selections}))
    end)
    if not ok then
        runtime.saveStatus="Write error"
        WarnOnce("write","Cannot save settings: "..tostring(err))
        return false
    end
    warnings.write=nil
    runtime.saveStatus="Saved"
    return true
end
LoadSettings()
local statusLabel
local function Status(text)
    runtime.status=text
    if statusLabel then pcall(function() statusLabel:SetValue(text) end) end
end
local changed={}
local touched={}
local restarts={}

local function StopTracks(animate)
    local character=animate.Parent
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return true end
    local animator=humanoid:FindFirstChildOfClass("Animator")
    local ok,tracks=pcall(function()
        return animator and animator:GetPlayingAnimationTracks() or humanoid:GetPlayingAnimationTracks()
    end)
    if not ok then
        WarnOnce("tracks","Cannot enumerate active animation tracks: "..tostring(tracks))
        return false
    end
    local stopped=true
    for _,track in ipairs(tracks) do
        pcall(function() track:AdjustWeight(0,0) end)
        local stopOK=pcall(function() track:Stop(0) end)
        if not stopOK then stopped=false end
    end
    if not stopped then WarnOnce("stop","Some animation tracks could not be stopped.") end
    return stopped
end
local function FinishRestart(animate,lease)
    if restarts[animate]~=lease then return true end
    local stopOK=StopTracks(animate)
    local ok,err=pcall(function() animate.Disabled=lease.wasDisabled end)
    if ok then
        restarts[animate]=nil
    else
        WarnOnce("restart","Could not restart Animate: "..tostring(err))
    end
    return ok and stopOK
end
local function WriteBatch(animate,entries,forceRestart)
    if #entries==0 and not forceRestart then return true end
    local pending=restarts[animate]
    local wasDisabled=animate.Disabled
    if pending then wasDisabled=pending.wasDisabled end
    local lease={wasDisabled=wasDisabled}
    restarts[animate]=lease
    local stopped=true
    local ok,err=pcall(function()
        animate.Disabled=true
        stopped=StopTracks(animate)
        for _,entry in ipairs(entries) do
            entry.anim.AnimationId=entry.value
            if entry.saved and entry.anim.AnimationId==entry.value then entry.saved.beforeWrite=nil end
        end
    end)
    if not ok then
        FinishRestart(animate,lease)
        WarnOnce("apply","Animation update failed: "..tostring(err))
        return false
    end
    task.spawn(function()
        task.wait(0.1)
        if restarts[animate]~=lease then return end
        local restarted=FinishRestart(animate,lease)
        if not restarted and runtime.alive then Status("Reset incomplete — press Reapply / Retry") end
    end)
    return stopped
end
local function RestoreOriginals()
    local batches={}
    local restored=true
    for animate in pairs(touched) do
        if animate.Parent then batches[animate]={} else touched[animate]=nil end
    end
    for anim,saved in pairs(changed) do
        local ok,current=pcall(function() return anim.Parent and anim.AnimationId end)
        if not ok or not current or not saved.animate.Parent then
            changed[anim]=nil
        elseif current==saved.original then
            changed[anim]=nil
        elseif current~=saved.last and (saved.beforeWrite==nil or current~=saved.beforeWrite) then
            WarnOnce("conflict","Another script changed an animation; its ID was left untouched.")
            changed[anim]=nil
        else
            batches[saved.animate]=batches[saved.animate] or {}
            table.insert(batches[saved.animate],{anim=anim,value=saved.original})
        end
    end
    for animate,entries in pairs(batches) do
        if WriteBatch(animate,entries,true) then touched[animate]=nil else restored=false end
        for _,entry in ipairs(entries) do
            if entry.anim.AnimationId==entry.value then changed[entry.anim]=nil else restored=false end
        end
    end
    return restored
end
local function Current(character,ticket)
    return runtime.alive and runtime.enabled and runtime.generation==ticket and LocalPlayer.Character==character
end
local function ReadySlots(character,ticket)
    local deadline=os.clock()+10
    repeat
        if not Current(character,ticket) then return nil,"Cancelled" end
        local humanoid=character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.RigType~=Enum.HumanoidRigType.R15 then
            return nil,"R15 required — settings retained"
        end
        if humanoid and humanoid.Health<=0 then return nil,"Waiting for respawn" end
        local animate=character:FindFirstChild("Animate")
        if humanoid and animate then
            local slots={}
            local complete=true
            for animType,info in pairs(animMap) do
                local folder=animate:FindFirstChild(info.folder)
                for _,slot in ipairs(info.slots) do
                    local anim=folder and folder:FindFirstChild(slot.child)
                    if not anim or not anim:IsA("Animation") or anim.AnimationId=="" then
                        complete=false
                    else
                        table.insert(slots,{anim=anim,kind=animType,key=slot.origKey})
                    end
                end
            end
            if complete then return {animate=animate,slots=slots} end
        end
        task.wait(0.1)
    until os.clock()>=deadline
    return nil,"Animate not ready — use Reapply / Retry"
end
local function ApplyReady(ready,forceRestart)
    local entries={}
    for _,slot in ipairs(ready.slots) do
        local anim=slot.anim
        local saved=changed[anim]
        if saved and anim.AnimationId~=saved.last and anim.AnimationId~=saved.original and anim.AnimationId~=saved.beforeWrite then
            changed[anim]=nil
            saved=nil
        end
        local original=saved and saved.original or anim.AnimationId
        local name=runtime.selections[slot.kind]
        if name=="Default" then name=runtime.selections.all end
        local preset=animPresets[name]
        local desired=preset and preset[slot.key] or original
        if anim.AnimationId~=desired then
            saved=saved or {original=original,animate=ready.animate}
            saved.beforeWrite=anim.AnimationId
            saved.last=desired
            changed[anim]=saved
            table.insert(entries,{anim=anim,value=desired,saved=saved})
        end
    end
    if #entries>0 or forceRestart then touched[ready.animate]=true end
    if not WriteBatch(ready.animate,entries,forceRestart) then return false end
    for _,entry in ipairs(entries) do
        if entry.anim.AnimationId~=entry.value then return false end
    end
    return true
end
local function RequestApply()
    runtime.generation=runtime.generation+1
    local ticket=runtime.generation
    if not runtime.alive then return end
    if not runtime.enabled then
        Status(RestoreOriginals() and "OFF — original animations restored" or "OFF — restoration pending; press Retry")
        return
    end
    local character=LocalPlayer.Character
    if not character then Status("Waiting for character"); return end
    Status("Applying saved selection...")
    task.spawn(function()
        local ok,err=pcall(function()
            local ready,reason=ReadySlots(character,ticket)
            if not Current(character,ticket) then return end
            if not ready then Status(reason); return end
            if ApplyReady(ready,true) then Status("ON — selection applied") else Status("Could not apply — press Retry") end
            task.wait(0.5)
            if not Current(character,ticket) then return end
            ready,reason=ReadySlots(character,ticket)
            if not Current(character,ticket) then return end
            if ready then
                if ApplyReady(ready) then Status("ON — selection applied") else Status("Could not apply — press Retry") end
            else Status(reason) end
        end)
        if not ok and Current(character,ticket) then
            Status("Animation error — press Retry")
            WarnOnce("worker",tostring(err))
        end
    end)
end
runtime.Reapply=RequestApply
runtime.SaveSettings=SaveSettings
local characterConnection
local appearanceConnection
function runtime.Cleanup()
    runtime.alive=false
    runtime.generation=runtime.generation+1
    if characterConnection then characterConnection:Disconnect() end
    if appearanceConnection then appearanceConnection:Disconnect() end
    local restored=RestoreOriginals()
    local pending={}
    for animate,lease in pairs(restarts) do pending[#pending+1]={animate=animate,lease=lease} end
    for _,item in ipairs(pending) do
        if not FinishRestart(item.animate,item.lease) then restored=false end
    end
    return restored
end

local tab=shared.CreateTab("FE Animations","/mellnikovden968-web/CFG_PM2/refs/heads/main/icon")
local section=tab:AddSection("FE Animations","aux0on presets • R15 • full track reset • auto-save")
statusLabel=section:AddLabel("Loading settings...",true)
section:AddParagraph("Saved settings","Toggle and all animation choices are saved automatically. Individual Default uses All Animations; All Animations = Default uses your avatar's originals. R15 only.")
local toggle=section:AddToggle("Enable FE Anims",function(value)
    if runtime.initializing or not runtime.alive then return end
    runtime.enabled=value==true
    SaveSettings()
    RequestApply()
end)
local dropdowns={
    {label="All Animations",key="all"},
    {label="Idle Animation",key="idle"},
    {label="Walk Animation",key="walk"},
    {label="Run Animation",key="run"},
    {label="Jump Animation",key="jump"},
    {label="Climb Animation",key="climb"},
    {label="Fall Animation",key="fall"},
}
for _,dd in ipairs(dropdowns) do
    local key=dd.key
    local control=section:AddDropdown(dd.label,key=="run" and runAnimOptions or allAnimOptions,function(value)
        if runtime.initializing or not runtime.alive or type(value)~="string" or not allowed[key][value] then return end
        runtime.selections[key]=value
        SaveSettings()
        if runtime.enabled then RequestApply() end
    end)
    if control then
        local ok=pcall(function() control:Select(runtime.selections[key]) end)
        if not ok then WarnOnce("ui","Could not display a saved selection; the backing setting is retained.") end
    end
end
section:AddParagraph("Full animation reset","Switching presets, toggling OFF or pressing Retry briefly stops ALL current animation tracks, including emotes/tool poses, then restarts Animate. Nothing is blocked permanently.")
section:AddButton("Reapply / Retry",function() if runtime.alive then RequestApply() end end)
if runtime.enabled and type(toggle)=="function" then
    local ok=pcall(toggle)
    if not ok then WarnOnce("toggle","Could not display the saved toggle state.") end
end
runtime.initializing=false
_G[KEY]=runtime
characterConnection=LocalPlayer.CharacterAdded:Connect(function()
    if not runtime.alive then return end
    RestoreOriginals()
    RequestApply()
end)
appearanceConnection=LocalPlayer.CharacterAppearanceLoaded:Connect(function(character)
    if runtime.alive and runtime.enabled and character==LocalPlayer.Character then RequestApply() end
end)
RequestApply()

        end, function(__error) return tostring(__error) end)
        if not __pluginOk then
            warn("[Noir embedded plugin: Anims.lua.txt] " .. tostring(__pluginError))
            notify("Anims.lua.txt failed to load: " .. tostring(__pluginError), 7)
        end
    end
    do
        local __pluginOk, __pluginError = xpcall(function()
local ODHX = (function()
    local X = { ready=false, silent=false, restoring=false, replay=true, records={}, byKey={}, data={version=1, controls={}}, external=false }
    X.id, X.title, X.file = "BJP", "Bomb Jump+", "Noir Hub/configs/ODH_BJP_settings.json"
    local host = odh_shared_plugins
    assert(host and type(host.CreateTab)=="function", X.title .. ": load through the current Overdrive H plugin menu")
    local env = {}
    if type(getgenv)=="function" then local ok,g=pcall(getgenv); if ok and type(g)=="table" then env=g end end
    local rd = type(readfile)=="function" and readfile or env.readfile
    local wr = type(writefile)=="function" and writefile or env.writefile
    local exists = type(isfile)=="function" and isfile or env.isfile
    local http = game:GetService("HttpService")
    local reported = {}
    local function report(message)
        if reported[message] then return end
        reported[message]=true
        warn("[" .. X.title .. "] " .. message)
        if type(host.Notify)=="function" then pcall(host.Notify, X.title .. ": " .. message, 5) end
    end
    X.Report = report
    local function finite(v) return type(v)=="number" and v==v and math.abs(v)<math.huge end
    local function encode(v, depth)
        depth=depth or 0
        if depth>20 then error("settings nesting too deep") end
        if typeof(v)=="Color3" then return {__odhColor={v.R,v.G,v.B}} end
        local t=type(v)
        if t=="boolean" or t=="string" then return v end
        if t=="number" then if finite(v) then return v end; return nil end
        if t=="table" then
            local result={}
            for k,item in pairs(v) do
                if type(k)=="string" or type(k)=="number" then result[k]=encode(item,depth+1) end
            end
            return result
        end
        return nil
    end
    local function decode(v, depth)
        depth=depth or 0
        if depth>20 then error("settings nesting too deep") end
        if type(v)~="table" then return v end
        if v.__odhColor then
            local c=v.__odhColor
            assert(type(c)=="table" and finite(c[1]) and finite(c[2]) and finite(c[3]),"invalid color")
            return Color3.new(math.clamp(c[1],0,1),math.clamp(c[2],0,1),math.clamp(c[3],0,1))
        end
        local result={}
        for k,item in pairs(v) do result[k]=decode(item,depth+1) end
        return result
    end
    X.Encode, X.Decode = encode, decode
    if not X.external then
        if type(rd)=="function" and type(wr)=="function" then
            local present=true
            if type(exists)=="function" then local ok,v=pcall(exists,X.file); if ok then present=v end end
            if present then
                local ok,text=pcall(rd,X.file)
                if ok then
                    local good,data=pcall(function() return decode(http:JSONDecode(text)) end)
                    if good and type(data)=="table" and data.version==1 and type(data.controls)=="table" then X.data=data
                    else X.badFile=true; report("Invalid settings file; defaults loaded. A manual change will replace it.") end
                elseif type(exists)=="function" then report("Could not read settings file: " .. tostring(text)); X.badFile=true end
            end
        else report("readfile/writefile unavailable; settings last only for this session.") end
    end
    local tab
    X.shared=setmetatable({}, {__index=host})
    X.shared.Notify=function(text,seconds)
        if X.restoring then return end
        if type(host.Notify)=="function" then return host.Notify(text,seconds or 3) end
    end
    local function key(section,name,kind) return section .. " / " .. kind .. " / " .. name end
    local function safeValue(r,v)
        if r.kind=="Toggle" then if type(v)=="boolean" then return v end
        elseif r.kind=="Slider" then if finite(v) then return math.clamp(v,r.min,r.max) end
        elseif r.kind=="Colorpicker" then if typeof(v)=="Color3" then return v end
        elseif r.kind=="Dropdown" then
            for _,item in ipairs(r.items) do if v==item then return v end end
        end
        return nil
    end
    local function show(r,v)
        if v==nil or r.shown==v then return end
        local prior=X.silent; X.silent=true
        local ok,err=pcall(function()
            if r.kind=="Toggle" then
                if r.visual~=v then assert(type(r.handle)=="function","AddToggle must return a closure"); r.handle() end
            elseif r.kind=="Slider" then r.handle:SetValue(v)
            elseif r.kind=="Colorpicker" then r.handle:SetRGBValue(v)
            elseif r.kind=="Dropdown" then r.handle:Select(v) end
        end)
        X.silent=prior
        if ok then r.shown=v else report("UI sync failed: " .. r.name .. ": " .. tostring(err)) end
    end
    function X.Bind(section,name,kind,getter)
        local r=X.byKey[key(section,name,kind)]
        assert(r,"Unknown binding " .. section .. " / " .. name)
        r.get=getter
    end
    function X.Sync()
        for _,r in ipairs(X.records) do
            if r.get then
                local ok,v=pcall(r.get)
                if ok then
                    v=safeValue(r,v)
                    if v~=nil then
                        r.value=v
                        if not r.exclude then X.data.controls[r.key]=v end
                        show(r,v)
                    end
                end
            end
        end
    end
    function X.Commit()
        if not X.ready or X.silent or X.restoring or X.stopped or X.committing then return end
        X.committing=true
        local ok,err=pcall(function()
            X.Sync()
            if X.capture then X.data.snapshot=X.capture() end
            if X.external then
                if not X.backend or not X.backend(X.data) then error("native settings file could not be saved") end
            elseif type(wr)=="function" then
                wr(X.file,http:JSONEncode(encode(X.data)))
            end
        end)
        X.committing=false
        if not ok then report("Settings save failed: " .. tostring(err)) end
    end
    function X.Restore()
        X.restoring=true
        for _,togglePass in ipairs({false,true}) do
            for _,r in ipairs(X.records) do
                if not r.exclude and ((r.kind=="Toggle")==togglePass) then
                    local v=safeValue(r,X.data.controls[r.key])
                    if v==nil and r.get then local ok,x=pcall(r.get); if ok then v=safeValue(r,x) end end
                    if v==nil then v=r.default end
                    if v~=nil then
                        show(r,v)
                        local ok,err=pcall(r.callback,v)
                        if not ok then report("Restore failed: " .. r.name .. ": " .. tostring(err)) end
                        r.value=v; X.data.controls[r.key]=v
                    end
                end
            end
        end
        X.restoring=false
    end
    function X.Finish()
        if X.replay then X.Restore() else X.Sync() end
        X.ready=true
        if not X.badFile then X.Commit() end
    end
    function X.Set(section,name,kind,v,apply)
        local r=X.byKey[key(section,name,kind)]
        if not r then return end
        v=safeValue(r,v); if v==nil then return end
        show(r,v); r.value=v; X.data.controls[r.key]=v
        if apply then r.callback(v) end
    end
    function X.ResetControls()
        X.data.controls={}
        for _,r in ipairs(X.records) do
            if r.kind=="Toggle" and not r.exclude then X.Set(r.section,r.name,r.kind,false,true) end
        end
    end
    function X.shared.AddSection(name,subtitle)
        if not tab then tab=host.CreateTab(X.title,"/mellnikovden968-web/CFG_PM2/refs/heads/main/icon") end
        local raw=tab:AddSection(name,subtitle or "")
        local section={Name=name,Raw=raw}
        local function register(kind,label,callback,default,min,max,items)
            local r={section=name,name=label,kind=kind,callback=callback,default=default,min=min,max=max,items=items,visual=false}
            r.key=key(name,label,kind)
            r.exclude=(name=="🔑 Keys")
            X.records[#X.records+1]=r; X.byKey[r.key]=r
            local function changed(v)
                if kind=="Toggle" then r.visual=(v==true) end
                if not X.ready or X.silent or X.restoring or X.stopped then return end
                v=safeValue(r,v); if v==nil then return end
                r.shown=v
                local ok,err=pcall(callback,v)
                if ok then
                    r.value=v
                    if not r.exclude then X.data.controls[r.key]=v end
                    X.Commit()
                else report("Callback failed: " .. label .. ": " .. tostring(err)) end
            end
            if kind=="Toggle" then r.handle=raw:AddToggle(label,changed)
            elseif kind=="Slider" then r.handle=raw:AddSlider(label,min,max,default,changed)
            elseif kind=="Colorpicker" then r.handle=raw:AddColorpicker(label,default,changed)
            elseif kind=="Dropdown" then r.handle=raw:AddDropdown(label,items,changed) end
            return r.handle
        end
        function section:AddToggle(label,cb) return register("Toggle",label,cb,false) end
        function section:AddSlider(label,min,max,default,cb) return register("Slider",label,cb,default,min,max) end
        function section:AddColorpicker(label,default,cb) return register("Colorpicker",label,cb,default) end
        function section:AddDropdown(label,items,cb) return register("Dropdown",label,cb,items[1],nil,nil,items) end
        local function action(cb)
            return function(...)
                if not X.ready or X.stopped then return end
                local ok,err=pcall(cb,...)
                if not ok then report("Action failed: " .. tostring(err)) end
                X.Commit()
            end
        end
        function section:AddButton(label,cb) return raw:AddButton(label,action(cb)) end
        function section:AddKeybind(label,default,cb) return raw:AddKeybind(label,default,action(cb)) end
        function section:AddPlayerDropdown(label,cb) return raw:AddPlayerDropdown(label,action(cb)) end
        function section:AddTextBox(label,cb) return raw:AddTextBox(label,action(cb)) end
        function section:AddLabel(...) return raw:AddLabel(...) end
        function section:AddParagraph(...) return raw:AddParagraph(...) end
        return section
    end
    function X.Path(object)
        local parts={}
        local player=game:GetService("Players").LocalPlayer
        while object and object~=game do
            table.insert(parts,1,object==player and "$LocalPlayer" or object.Name)
            object=object.Parent
            if #parts>32 then return nil end
        end
        if object~=game then return nil end
        return parts
    end
    function X.Resolve(parts)
        if type(parts)~="table" then return nil end
        local object=game
        for _,name in ipairs(parts) do
            if name=="$LocalPlayer" then object=game:GetService("Players").LocalPlayer
            elseif type(name)=="string" and object then object=object:FindFirstChild(name)
            else return nil end
        end
        return object
    end
    X.connections={}
    function X.Connect(signal,callback)
        local c=signal:Connect(function(...) if not X.stopped then return callback(...) end end)
        X.connections[#X.connections+1]=c
        return c
    end
    function X.Stop()
        if X.stopped then return end
        X.Commit()
        X.stopped=true
        for _,c in ipairs(X.connections) do pcall(function() c:Disconnect() end) end
        if X.cleanup then pcall(X.cleanup) end
    end
    local registry=rawget(_G,"ODH_2026_PluginRuntimes")
    if type(registry)~="table" then registry={}; rawset(_G,"ODH_2026_PluginRuntimes",registry) end
    local previous=registry[X.id]
    if previous and type(previous.Stop)=="function" then pcall(previous.Stop) end
    registry[X.id]=X
    return X
end)()

local table_insert = table.insert

local Maid = {}
Maid.__index = Maid

function Maid.new()
    return setmetatable({_tasks = {}, _destroyed = false}, Maid)
end

function Maid:GiveTask(task)
    if self._destroyed then
        self:_cleanupTask(task)
        return
    end
    table_insert(self._tasks, task)
    return task
end

function Maid:GiveTasks(...)
    for _, task in ipairs({...}) do
        self:GiveTask(task)
    end
end

function Maid:_cleanupTask(task)
    local taskType = typeof(task)
    if taskType == "RBXScriptConnection" then
        task:Disconnect()
    elseif taskType == "Instance" then
        task:Destroy()
    elseif taskType == "function" then
        task()
    elseif taskType == "table" and type(task.Destroy) == "function" then
        task:Destroy()
    end
end

function Maid:DoCleaning()
    if self._destroyed then return end
    self._destroyed = true
    for _, task in ipairs(self._tasks) do
        self:_cleanupTask(task)
    end
    self._tasks = {}
end

function Maid:Destroy()
    self:DoCleaning()
end

local RootMaid = Maid.new()

local shared = ODHX.shared

local Services = {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    StarterGui = game:GetService("StarterGui"),
    CoreGui = game:GetService("CoreGui"),
    Workspace = game:GetService("Workspace"),
    TweenService = game:GetService("TweenService"),
    SoundService = game:GetService("SoundService")
}

local LocalPlayer = Services.Players.LocalPlayer

local __PCLR = Color3.new
local __RGB = Color3.fromRGB
local __UD2 = UDim2.new
local __UD = UDim.new
local __V2 = Vector2.new

local function getfserv(s)
    local ok, svc = pcall(function() return game:GetService(s) end)
    if ok and svc then return svc end
    ok, svc = pcall(function() return game:FindService(s) end)
    if ok and svc then return svc end
    return game[s]
end

local __RS   = getfserv("RunService")
local __UIS  = getfserv("UserInputService")
local __PLRS = getfserv("Players")
local __TS   = getfserv("TweenService")

local BBSystem = {Buttons = {}, Connections = {}}

local function bb_safecallback(callback)
    if not callback then return end
    local ok, err = xpcall(callback, function(e) return debug.traceback(e) end)
    if not ok then warn("[BB ERROR] " .. tostring(err)) end
end

local function BB_GetStorage()
    local parent = gethui and gethui()
    if not parent or typeof(parent) ~= "Instance" then
        parent = getfserv("CoreGui")
    end
    if not parent or typeof(parent) ~= "Instance" then
        parent = __PLRS.LocalPlayer:WaitForChild("PlayerGui", 5)
    end
    if typeof(parent) ~= "Instance" then
        parent = __PLRS.LocalPlayer:WaitForChild("PlayerGui")
    end

    local sg = parent:FindFirstChild("@odh_bjp_bigstorage")
    if not sg then
        sg = Instance.new("ScreenGui")
        sg.Name = "@odh_bjp_bigstorage"
        sg.ResetOnSpawn = false
        sg.IgnoreGuiInset = true
        pcall(function() sg.ScreenInsets = Enum.ScreenInsets.None end)
        sg.Parent = parent
    end
    return sg
end

local __BB_GRAD_SEQ = ColorSequence.new({
    ColorSequenceKeypoint.new(0, __RGB(42,44,50)),
    ColorSequenceKeypoint.new(.22, __RGB(242,244,248)),
    ColorSequenceKeypoint.new(.50, __RGB(103,108,118)),
    ColorSequenceKeypoint.new(.78, __RGB(232,235,241)),
    ColorSequenceKeypoint.new(1, __RGB(45,47,53)),
})

local function BB_MakeDraggable(gui, func, ripple, sound)
    local dragging, dragInput, dragStart, startPos
    local hasMoved = false
    local tInfo = TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local normalSize = gui.Size
    local normalTxtSize = gui.TextSize
    local bigSize = __UD2(normalSize.X.Scale, normalSize.X.Offset * 1.045, normalSize.Y.Scale, normalSize.Y.Offset * 1.045)
    local bigTxtSize = normalTxtSize * 1.03

    ODHX.Connect(gui.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            hasMoved  = false
            dragStart = input.Position
            startPos  = gui.Position
            __TS:Create(gui, tInfo, {Size = bigSize, TextSize = bigTxtSize}):Play()
            local absPos = gui.AbsolutePosition
            ripple.Position = __UD2(0, input.Position.X - absPos.X, 0, input.Position.Y - absPos.Y)
            ripple.Size = __UD2(0, 0, 0, 0)
            ripple.BackgroundTransparency = 0.5
            ripple.Visible = true
            sound:Play()
            __TS:Create(ripple, TweenInfo.new(0.32, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Size = __UD2(0, 200, 0, 200),
                BackgroundTransparency = 1
            }):Play()
            local rel
            rel = ODHX.Connect(__UIS.InputEnded, function(endInput)
                if endInput.UserInputType == input.UserInputType then
                    dragging = false
                    __TS:Create(gui, tInfo, {Size = normalSize, TextSize = normalTxtSize}):Play()
                    if not hasMoved then bb_safecallback(func) end
                    rel:Disconnect()
                end
            end)
        end
    end)
    ODHX.Connect(gui.InputChanged, function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    ODHX.Connect(__UIS.InputChanged, function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            if delta.Magnitude > 7 then hasMoved = true end
            gui.Position = __UD2(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local BindableButtons
local muteButtonSounds = false

local function UpdateAllButtonSounds()
    local volume = muteButtonSounds and 0 or 0.5
    for id, btn in pairs(BBSystem.Buttons) do
        local sound = btn:FindFirstChild("Sound")
        if sound then
            sound.Volume = volume
        end
    end
    for id, btn in pairs(BindableButtons.Buttons) do
        local sound = btn:FindFirstChild("Sound")
        if sound then
            sound.Volume = volume
        end
    end
end

local function AddBigButton(id, text, func, isGold, customSize)
    if BBSystem.Buttons[id] then return end
    local storage = BB_GetStorage()
    local bb = Instance.new("TextButton")
    bb.Name = id
    bb.Size = customSize or __UD2(0, 168, 0, 60)
    bb.Position = __UD2(0.5, 0, 0.5, 0)
    bb.AnchorPoint = __V2(0.5, 0.5)
    bb.BackgroundColor3 = __RGB(9, 11, 14)
    bb.BackgroundTransparency = 0.32
    bb.BorderSizePixel = 0
    bb.Font = Enum.Font.GothamBold
    bb.Text = text
    bb.TextSize = 18
    bb.TextColor3 = __RGB(255, 255, 255)
    bb.TextWrapped = true
    bb.ClipsDescendants = true
    bb.AutoButtonColor = false
    bb.ZIndex = 5
    bb.Parent = storage

    Instance.new("UICorner", bb).CornerRadius = __UD(0, 13)
    local stroke = Instance.new("UIStroke")
    stroke.Color = __RGB(255, 255, 255)
    stroke.Thickness = 1.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = bb
    local gradient = Instance.new("UIGradient")

    gradient.Color = __BB_GRAD_SEQ
    gradient.Parent = stroke

    local ripple = Instance.new("Frame")
    ripple.Name = "@ripple"
    ripple.BackgroundColor3 = __RGB(222, 226, 234)
    ripple.BackgroundTransparency = 0.5
    ripple.ZIndex = 4
    ripple.Size = __UD2(0, 0, 0, 0)
    ripple.AnchorPoint = __V2(0.5, 0.5)
    ripple.Visible = false
    ripple.Parent = bb
    Instance.new("UICorner", ripple).CornerRadius = __UD(1, 0)

    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://3868133279"
    sound.Volume = muteButtonSounds and 0 or 0.5
    sound.Parent = bb

    BB_MakeDraggable(bb, func, ripple, sound)
    
    BBSystem.Buttons[id] = bb
    return bb
end

local function DeleteBigButton(id)
    if BBSystem.Buttons[id] then
        if BBSystem.Connections[id] then
            BBSystem.Connections[id]:Disconnect()
            BBSystem.Connections[id] = nil
        end
        BBSystem.Buttons[id]:Destroy()
        BBSystem.Buttons[id] = nil
    end
end

local savedBindButtonPositions = ODHX.data.bindButtonPositions
if type(savedBindButtonPositions) ~= "table" then
    savedBindButtonPositions = {}
    ODHX.data.bindButtonPositions = savedBindButtonPositions
end

BindableButtons = {Buttons = {}, Maids = {}, Count = 0, SavedPositions = savedBindButtonPositions}

function BindableButtons.GetSavedPosition(id)
    local value = BindableButtons.SavedPositions[id]
    if type(value) ~= "table" then return nil end
    local xScale, xOffset = tonumber(value.xScale), tonumber(value.xOffset)
    local yScale, yOffset = tonumber(value.yScale), tonumber(value.yOffset)
    if not xScale or not xOffset or not yScale or not yOffset then return nil end
    return __UD2(xScale, xOffset, yScale, yOffset)
end

function BindableButtons.SavePosition(id, position)
    if not id or typeof(position) ~= "UDim2" then return end
    BindableButtons.SavedPositions[id] = {
        xScale = position.X.Scale,
        xOffset = position.X.Offset,
        yScale = position.Y.Scale,
        yOffset = position.Y.Offset
    }
    ODHX.data.bindButtonPositions = BindableButtons.SavedPositions
    ODHX.Commit()
end

local __SHAPES = {
    [0] = "rbxassetid://86221076925479",
    [1] = "rbxassetid://96242665417546",
    [2] = "rbxassetid://97129189935336",
    [3] = "rbxassetid://76165862027868",
    [4] = "rbxassetid://125868092127496"
}

local __NORMAL_COLOR = ColorSequence.new({
    ColorSequenceKeypoint.new(0,    __RGB(35, 35, 40)),
    ColorSequenceKeypoint.new(0.22, __RGB(250, 250, 252)),
    ColorSequenceKeypoint.new(0.48, __RGB(70, 70, 78)),
    ColorSequenceKeypoint.new(0.72, __RGB(255, 255, 255)),
    ColorSequenceKeypoint.new(1,    __RGB(45, 45, 52)),
})

local __WAIT_COLOR = ColorSequence.new({
    ColorSequenceKeypoint.new(0, __RGB(24,26,31)),
    ColorSequenceKeypoint.new(.25, __RGB(150,154,162)),
    ColorSequenceKeypoint.new(.52, __RGB(58,61,69)),
    ColorSequenceKeypoint.new(.78, __RGB(188,191,198)),
    ColorSequenceKeypoint.new(1, __RGB(25,27,32)),
})
local __GOLD_NORMAL_COLOR = __NORMAL_COLOR
local __GOLD_WAIT_COLOR = __WAIT_COLOR

local function bind_safecallback(callback)
    if not callback then return end
    local ok, err = xpcall(callback, function(e) return debug.traceback(e) end)
    if not ok then warn("[BIND ERROR] " .. tostring(err)) end
end

local function Bind_GetStorage()
    local parent = gethui and gethui()
    if not parent or typeof(parent) ~= "Instance" then
        parent = getfserv("CoreGui")
    end
    if not parent or typeof(parent) ~= "Instance" then
        parent = __PLRS.LocalPlayer:WaitForChild("PlayerGui", 5)
    end
    if typeof(parent) ~= "Instance" then
        parent = __PLRS.LocalPlayer:WaitForChild("PlayerGui")
    end

    local sg = parent:FindFirstChild("@odh_bjp_bindstorage")
    if not sg then
        sg = Instance.new("ScreenGui")
        sg.Name = "@odh_bjp_bindstorage"
        sg.ResetOnSpawn = false
        sg.IgnoreGuiInset = true
        pcall(function() sg.ScreenInsets = Enum.ScreenInsets.None end)
        sg.Parent = parent
    end
    return sg
end

local function Bind_MakeDraggable(gui, maid, ripple, sound, clickFunc, onPositionChanged)
    local dragging, dragInput, dragStart, startPos
    local hasMoved = false
    local pressScale = Instance.new("UIScale")
    pressScale.Scale = 1
    pressScale.Parent = gui
    maid:GiveTask(pressScale)

    maid:GiveTask(ODHX.Connect(gui.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, input.Position, gui.Position
            hasMoved = false
            __TS:Create(pressScale, TweenInfo.new(.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = .95 }):Play()
            sound:Play()
            local absPos = gui.AbsolutePosition
            ripple.Position = __UD2(0, input.Position.X - absPos.X, 0, input.Position.Y - absPos.Y)
            ripple.Size = __UD2(0, 0, 0, 0)
            ripple.BackgroundTransparency = 0.5
            ripple.Visible = true
            __TS:Create(ripple, TweenInfo.new(0.24, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Size = __UD2(0, 45, 0, 45),
                BackgroundTransparency = 1
            }):Play()

            local rel
            rel = ODHX.Connect(__UIS.InputEnded, function(endInput)
                if endInput.UserInputType == input.UserInputType then
                    dragging = false
                    __TS:Create(pressScale, TweenInfo.new(.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Scale = 1 }):Play()
                    if hasMoved then
                        if onPositionChanged then pcall(onPositionChanged, gui.Position) end
                    else
                        bind_safecallback(clickFunc)
                    end
                    rel:Disconnect()
                end
            end)
        end
    end))

    maid:GiveTask(ODHX.Connect(gui.InputChanged, function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end))

    maid:GiveTask(ODHX.Connect(__UIS.InputChanged, function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            if delta.Magnitude > 7 then hasMoved = true end
            local screen = gui.Parent.AbsoluteSize
            gui.Position = __UD2(startPos.X.Scale + (delta.X / screen.X), 0, startPos.Y.Scale + (delta.Y / screen.Y), 0)
        end
    end))
end

function BindableButtons.AddBButton(id, text, clickFunc, isGold, customSize)
    if BindableButtons.Buttons[id] then return end

    local buttonMaid = Maid.new()
    local camera = workspace.CurrentCamera
    local screen = camera.ViewportSize
    local buttonSizeY = customSize or 0.085
    local widthScale = buttonSizeY * (screen.Y / screen.X)
    local xPos = 0.1 + ((BindableButtons.Count % 8) * (widthScale + 0.005))
    local yPos = 0.9 - (math.floor(BindableButtons.Count / 8) * (buttonSizeY + 0.015))

    local ImageButton = Instance.new("ImageButton")
    ImageButton.Name = id
    ImageButton.Size = __UD2(widthScale, 0, buttonSizeY, 0)
    ImageButton.Position = BindableButtons.GetSavedPosition(id) or __UD2(xPos, 0, yPos, 0)
    ImageButton.AnchorPoint = __V2(0.5, 0.5)
    ImageButton.Image = ""
    ImageButton.BackgroundColor3 = __RGB(8, 8, 10)
    ImageButton.BackgroundTransparency = 0.42
    ImageButton.BorderSizePixel = 0
    ImageButton.ClipsDescendants = false
    ImageButton.AutoButtonColor = false
    Instance.new("UICorner", ImageButton).CornerRadius = __UD(0, 1000)
    local outerButtonStroke = Instance.new("UIStroke", ImageButton)
    outerButtonStroke.Color = __PCLR(1, 1, 1)
    outerButtonStroke.Thickness = 2
    outerButtonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    local innerButtonStroke = Instance.new("UIStroke", ImageButton)
    innerButtonStroke.Color = __RGB(105, 105, 112)
    innerButtonStroke.Transparency = 0.5
    innerButtonStroke.Thickness = 1
    innerButtonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    ImageButton.Parent = Bind_GetStorage()
    buttonMaid:GiveTask(ImageButton)

    local TextLabel = Instance.new("TextLabel", ImageButton)
    TextLabel.Name = "@Text"
    TextLabel.Size = __UD2(0.92, 0, 0.22, 0)
    TextLabel.Position = __UD2(0.5, 0, 0.82, 0)
    TextLabel.AnchorPoint = __V2(0.5, 0.5)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Font = Enum.Font.GothamBold
    TextLabel.Text = text
    TextLabel.TextColor3 = __PCLR(1, 1, 1)
    TextLabel.TextSize = 12
    TextLabel.TextScaled = true
    TextLabel.TextWrapped = true
    TextLabel.ZIndex = 12
    local labelLimit = Instance.new("UITextSizeConstraint", TextLabel)
    labelLimit.MinTextSize = 8
    labelLimit.MaxTextSize = 14

    local Aspect = Instance.new("UIAspectRatioConstraint", ImageButton)
    Aspect.AspectRatio = 1
    Aspect.AspectType = Enum.AspectType.ScaleWithParentSize

    local Stroke = Instance.new("UIGradient", outerButtonStroke)
    Stroke.Name = "@Stroke"
    Stroke.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, __RGB(35, 35, 40)),
        ColorSequenceKeypoint.new(0.22, __RGB(250, 250, 252)),
        ColorSequenceKeypoint.new(0.48, __RGB(70, 70, 78)),
        ColorSequenceKeypoint.new(0.72, __RGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, __RGB(45, 45, 52)),
    })
    local innerButtonGradient = Stroke:Clone()
    innerButtonGradient.Rotation = 180
    innerButtonGradient.Parent = innerButtonStroke

    local ripple = Instance.new("Frame")
    ripple.Name = "@ripple"
    ripple.BackgroundColor3 = __RGB(222, 226, 234)
    ripple.BackgroundTransparency = 0.5
    ripple.Size = __UD2(0, 0, 0, 0)
    ripple.AnchorPoint = __V2(0.5, 0.5)
    ripple.Visible = false
    ripple.ZIndex = 2
    ripple.Parent = ImageButton
    Instance.new("UICorner", ripple).CornerRadius = __UD(1, 0)

    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://3868133279"
    sound.Volume = muteButtonSounds and 0 or 0.5
    sound.Parent = ImageButton
    pcall(function() __NOIR_GUARD.blackhole.StyleFloat(ImageButton, sound) end)
    pcall(function() __NOIR_GUARD.floatIcon(ImageButton, text) end)

    Bind_MakeDraggable(ImageButton, buttonMaid, ripple, sound, clickFunc, function(position)
        BindableButtons.SavePosition(id, position)
    end)
    

    BindableButtons.Buttons[id] = ImageButton
    BindableButtons.Maids[id] = buttonMaid
    BindableButtons.Count = BindableButtons.Count + 1
    return ImageButton
end

function BindableButtons.DeleteBButton(id)
     
    local button = BindableButtons.Buttons[id]
    local maid = BindableButtons.Maids[id]
    if maid then
        maid:Destroy()
    elseif button and button.Parent then
        button:Destroy()
    end
    BindableButtons.Maids[id] = nil
    BindableButtons.Buttons[id] = nil

    local ok, storage = pcall(Bind_GetStorage)
    if ok and storage then
        local orphan = storage:FindFirstChild(id)
        if orphan then orphan:Destroy() end
    end
end

 
BindableButtons.DeleteBButton("bombjump_bind")
BindableButtons.DeleteBButton("goldbombjump_bind")

function BindableButtons.UpdateBButtonText(id, text, isWaiting, isGold)
    local btn = BindableButtons.Buttons[id]
    if not btn then return end

    local textLabel = btn:FindFirstChild("@Text")
    if textLabel then
        textLabel.Text = text
    end

    local stroke = btn:FindFirstChild("@Stroke", true)
    if stroke then
        if isGold then
            stroke.Color = isWaiting and __GOLD_WAIT_COLOR or __GOLD_NORMAL_COLOR
        else
            stroke.Color = isWaiting and __WAIT_COLOR or __NORMAL_COLOR
        end
    end
end

local function GetSafeGuiRoot()
    local success, result = pcall(function()
        return gethui()
    end)
    if success and result and typeof(result) == "Instance" then
        return result
    end
    return Services.CoreGui
end

local hiddenGui = Instance.new("ScreenGui")
hiddenGui.Name = "HiddenGui"
hiddenGui.ResetOnSpawn = false
hiddenGui.IgnoreGuiInset = true
hiddenGui.Parent = GetSafeGuiRoot()
RootMaid:GiveTask(hiddenGui)

local _game = shared.game_name
if not _game and (game.PlaceId == 142823291 or game.GameId == 66654135) then _game = "Murder Mystery 2" end

if _game == "Murder Mystery 2" or _game == "Murder Mystery Modded" then

local aboutSection = shared.AddSection("About")

aboutSection:AddParagraph("Bomb Jump+", "Plugin Made by @lzzzx")

aboutSection:AddToggle("Mute Button SFX", function(bool)
    muteButtonSounds = bool
    UpdateAllButtonSounds()
end)

shared.Notify("Bomb Jump+ Successfully Loaded", 5)

local CONFIG = {
    CooldownTime = 22.0,
    LaunchPower = 58,
    MinSize = 50,
    MaxSize = 300,
    DefaultSize = 90,
    BindDefaultSize = 0.11
}

local BOMB_NAMES = {
    "FakeBomb",
    "Bomb",
    "GiftBomb",
    "PresentBomb",
    "Snowball",
    "CandyBomb"
}

local BOMB_CONFIGS = {
    FakeBomb = {
        Cooldown = 22,
        Power = 58,
        IsGold = false,
        RemotePath = "Remote",
        DisplayName = "Bomb Jump"
    },
    GoldBomb = {
        Cooldown = 4,
        Power = 65,
        IsGold = true,
        RemotePath = "Remote",
        DisplayName = "Gold Bomb Jump"
    }
}

local function CreateBombJumpSystem(config)

    local bombConfig = BOMB_CONFIGS[config.bombType]
    if not bombConfig then return nil end

    local isGold = bombConfig.IsGold
    local bombName = config.bombType
    local cooldownTime = bombConfig.Cooldown
    local launchPower = bombConfig.Power
    local displayName = config.displayName or bombConfig.DisplayName

    local state = {
        enabled = false,
        onCooldown = false,
        debounce = false,
        autoGetBomb = false,
        justRespawned = false,
        bigButtonSize = config.bigButtonSize or 168,
        bindButtonSize = config.bindButtonSize or 0.085,
        bigBtnExists = false,
        bindBtnExists = false,
        bindButton = nil,
        activeTouches = {}
    }

    local systemMaid = Maid.new()
    RootMaid:GiveTask(systemMaid)

    local Sounds = {
        Click = Instance.new("Sound"),
        Cooldown = Instance.new("Sound")
    }
    Sounds.Click.SoundId = "rbxassetid://6895079853"
    Sounds.Click.Volume = 1.0
    Sounds.Cooldown.SoundId = "rbxassetid://138090596"
    Sounds.Cooldown.Volume = 1.0

    local function PlaySound(snd)
        pcall(function()
            if snd then
                Services.SoundService:PlayLocalSound(snd)
            end
        end)
    end

    local function IsPlayerInAir()
        local character = LocalPlayer.Character
        if not character then return false end

        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid then return false end

        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return false end

        local state = humanoid:GetState()
        if state == Enum.HumanoidStateType.Jumping or
           state == Enum.HumanoidStateType.FallingDown or
           state == Enum.HumanoidStateType.Freefall then
            return true
        end

        local velocityY = rootPart.Velocity.Y
        return math.abs(velocityY) > 0.5
    end

    local function ResetCooldown()
        state.onCooldown = false
        local bigBtn = BBSystem.Buttons[config.bigButtonId]
        if bigBtn then bigBtn.Text = displayName end
        if state.bindButton then
            BindableButtons.UpdateBButtonText(config.bindButtonId,
                isGold and "GBJ" or "BJ", false, isGold)
        end
    end

    local function StartCooldown()
        state.onCooldown = true
        state.debounce = false
        local bigBtn = BBSystem.Buttons[config.bigButtonId]
        if bigBtn then bigBtn.Text = "Wait" end
        if state.bindButton then
            BindableButtons.UpdateBButtonText(config.bindButtonId,
                "Wait", true, isGold)
        end

        task.spawn(function()
            for i = cooldownTime, 1, -1 do
                if not state.onCooldown then break end
                local bigBtn = BBSystem.Buttons[config.bigButtonId]
                if bigBtn then bigBtn.Text = tostring(i) end
                if state.bindButton then
                    BindableButtons.UpdateBButtonText(config.bindButtonId,
                        tostring(i), true, isGold)
                end
                task.wait(1)
            end
            if state.onCooldown then ResetCooldown() end
        end)
    end

    local function GetCenterPosition()
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local root = character.HumanoidRootPart
            local lookDir = Services.Workspace.CurrentCamera.CFrame.LookVector
            return root.Position + (lookDir * 3) + Vector3.new(0, -2, 0)
        end
        return nil
    end

    local function MakeCharacterJump()
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end

    local function UnequipBomb(bombName)
        task.spawn(function()
            task.wait(0.5)
            local character = LocalPlayer.Character
            if character then
                local bomb = character:FindFirstChild(bombName)
                if bomb then
                    bomb.Parent = LocalPlayer.Backpack or character
                end
            end
        end)
    end

    local function GetAnyBomb(bombName)
        local character = LocalPlayer.Character
        if not character then return false, nil end

        local bombNamesToCheck = {bombName}
        if bombName == "FakeBomb" then
            bombNamesToCheck = BOMB_NAMES
        end

        for _, name in ipairs(bombNamesToCheck) do
            local bomb = character:FindFirstChild(name)
            if bomb then return true, bomb end
        end

        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            for _, name in ipairs(bombNamesToCheck) do
                local bomb = backpack:FindFirstChild(name)
                if bomb then
                    bomb.Parent = character
                    return true, bomb
                end
            end
        end

        local success = false
        local attempts = 0
        while not success and attempts < 3 do
            attempts = attempts + 1
            local ok = pcall(function()
                Services.ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer(bombName)
            end)
            if ok then
                success = true
                break
            end
            task.wait(0.1)
        end

        if success then
            for _ = 1, 5 do
                for _, name in ipairs(bombNamesToCheck) do
                    local bomb = character:FindFirstChild(name)
                    if bomb then return true, bomb end
                    if backpack then
                        bomb = backpack:FindFirstChild(name)
                        if bomb then
                            bomb.Parent = character
                            return true, bomb
                        end
                    end
                end
                task.wait(0.05)
            end
        end

        return false, nil
    end

    local function IsHoldingBomb(bombName)
        local character = LocalPlayer.Character
        if not character then return false end

        local bombNamesToCheck = {bombName}
        if bombName == "FakeBomb" then
            bombNamesToCheck = BOMB_NAMES
        end

        for _, name in ipairs(bombNamesToCheck) do
            if character:FindFirstChild(name) then
                return true
            end
        end
        return false
    end

    local function FastBombJump()
        if not IsPlayerInAir() then return end
        if state.onCooldown or state.debounce or state.justRespawned then return end
        state.debounce = true

        local success, bomb = GetAnyBomb(bombName)

        if success and bomb then
            local position = GetCenterPosition()
            if position then
                local remote = bomb:FindFirstChild("Remote")
                if remote then
                    PlaySound(Sounds.Click)
                    pcall(function()
                        remote:FireServer(CFrame.new(position), 50)
                    end)
                end

                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then
                    local currentVelocity = root.AssemblyLinearVelocity
                    root.AssemblyLinearVelocity = Vector3.new(
                        currentVelocity.X,
                        currentVelocity.Y + launchPower,
                        currentVelocity.Z
                    )
                end

                MakeCharacterJump()
                UnequipBomb(bomb.Name)

                task.spawn(function()
                    task.wait(0.1)
                    StartCooldown()
                end)
            end
        end

        task.spawn(function()
            task.wait(0.5)
            state.debounce = false
        end)
    end

    local section = config.section

    section:AddLabel(displayName .. " Options")
    section:AddToggle("Enable Auto " .. displayName, function(bool)
        state.enabled = bool
    end)

    section:AddToggle("Auto-Get " .. bombName, function(bool)
        state.autoGetBomb = bool
        if bool then
            pcall(function()
                Services.ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer(bombName)
            end)
        end
    end)

    section:AddToggle("Enable " .. displayName .. " Bind Button", function(e)
         
        local wantsBindButton = e == true
        state.bindBtnExists = wantsBindButton
        BindableButtons.DeleteBButton(config.bindButtonId)
        state.bindButton = nil
        if not wantsBindButton then return end

        local shortName = isGold and "GBJ" or "BJ"
        BindableButtons.AddBButton(config.bindButtonId, shortName, FastBombJump, isGold, state.bindButtonSize)
        state.bindButton = BindableButtons.Buttons[config.bindButtonId]
        if state.bindButton then
            local screen = Services.Workspace.CurrentCamera.ViewportSize
            state.bindButton.Size = __UD2(state.bindButtonSize * (screen.Y / screen.X), 0, state.bindButtonSize, 0)
            BindableButtons.UpdateBButtonText(config.bindButtonId,
                state.onCooldown and "Wait" or shortName, state.onCooldown, isGold)
        end
    end)

    section:AddSlider(displayName .. " Bind Button Size", 5, 25, state.bindButtonSize * 100, function(value)
        state.bindButtonSize = value / 100
        if state.bindButton then
            local screen = Services.Workspace.CurrentCamera.ViewportSize
            state.bindButton.Size = __UD2(state.bindButtonSize * (screen.Y / screen.X), 0, state.bindButtonSize, 0)
        end
    end)

    section:AddKeybind(displayName .. " Keybind", config.keybind, FastBombJump)

    local TAP_MOVEMENT_THRESHOLD = 10
    local TAP_TIME_THRESHOLD = 0.3

    systemMaid:GiveTasks(
        ODHX.Connect(Services.UserInputService.InputBegan, function(input, gp)
            if gp then return end
            if input.UserInputType == Enum.UserInputType.Touch or
               input.UserInputType == Enum.UserInputType.MouseButton1 then
                state.activeTouches[input] = {
                    startPosition = input.Position,
                    startTime = tick(),
                    moved = false
                }
            end
        end),
        ODHX.Connect(Services.UserInputService.InputChanged, function(input)
            local data = state.activeTouches[input]
            if data and (input.Position - data.startPosition).Magnitude > TAP_MOVEMENT_THRESHOLD then
                data.moved = true
            end
        end),
        ODHX.Connect(Services.UserInputService.InputEnded, function(input, gp)
            if gp then
                state.activeTouches[input] = nil
                return
            end
            local data = state.activeTouches[input]
            if data and not data.moved and tick() - data.startTime <= TAP_TIME_THRESHOLD then
                if state.enabled and not state.onCooldown and not state.debounce then
                    if IsHoldingBomb(bombName) and IsPlayerInAir() then
                        FastBombJump()
                    end
                end
            end
            state.activeTouches[input] = nil
        end),
        ODHX.Connect(LocalPlayer.CharacterAdded, function()
            ResetCooldown()
            state.activeTouches = {}
            state.justRespawned = true
            task.wait(1)
            state.justRespawned = false
            if state.autoGetBomb then
                task.wait(0.2)
                pcall(function()
                    Services.ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer(bombName)
                end)
            end
        end)
    )

    ODHX.Bind(section.Name, "Enable Auto " .. displayName, "Toggle", function() return state.enabled end)
    ODHX.Bind(section.Name, "Auto-Get " .. bombName, "Toggle", function() return state.autoGetBomb end)
    ODHX.Bind(section.Name, "Enable " .. displayName .. " Bind Button", "Toggle", function() return state.bindBtnExists end)
    ODHX.Bind(section.Name, displayName .. " Bind Button Size", "Slider", function() return state.bindButtonSize * 100 end)
    return {
        GetState = function() return state end,
        FastBombJump = FastBombJump,
        ResetCooldown = ResetCooldown,
        SetEnabled = function(bool) state.enabled = bool end,
        SetAutoGet = function(bool)
            state.autoGetBomb = bool
            if bool then
                pcall(function()
                    Services.ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer(bombName)
                end)
            end
        end
    }
end

local section = shared.AddSection("Bomb Jump+")

local bombJumpSystem = CreateBombJumpSystem({
    bombType = "FakeBomb",
    section = section,
    displayName = "Bomb Jump",
    defaultEnabled = false,
    defaultAutoGet = false,
    defaultBigButton = false,
    defaultBindButton = false,
    bigButtonSize = 90,
    bindButtonSize = 0.085,
    keybind = "E",
    bigButtonId = "bombjump_big",
    bindButtonId = "bombjump_bind"
})

if _game == "Murder Mystery Modded" then
    local gbjSection = shared.AddSection("Gold Bomb Jump+")

    local goldBombJumpSystem = CreateBombJumpSystem({
        bombType = "GoldBomb",
        section = gbjSection,
        displayName = "Gold Bomb Jump",
        defaultEnabled = false,
        defaultAutoGet = false,
        defaultBigButton = false,
        defaultBindButton = false,
        bigButtonSize = 168,
        bindButtonSize = 0.085,
        keybind = "G",
        bigButtonId = "goldbombjump_big",
        bindButtonId = "goldbombjump_bind"
    })
end

ODHX.Bind("About", "Mute Button SFX", "Toggle", function() return muteButtonSounds end)

end

ODHX.cleanup=function()
    RootMaid:DoCleaning()
    for id in pairs(BBSystem.Buttons) do DeleteBigButton(id) end
    for id in pairs(BindableButtons.Buttons) do BindableButtons.DeleteBButton(id) end
end
ODHX.Finish()

        end, function(__error) return tostring(__error) end)
        if not __pluginOk then
            warn("[Noir embedded plugin: BJP.lua.txt] " .. tostring(__pluginError))
            notify("BJP.lua.txt failed to load: " .. tostring(__pluginError), 7)
        end
    end
    do
        local __pluginOk, __pluginError = xpcall(function()
local shared = odh_shared_plugins
if not shared or type(shared.CreateTab) ~= "function" then
    warn("[Inventory Unlimiter] Load through the current Overdrive H plugin menu.")
    return
end

local KEY = "ODH_InventoryUnlimiterRuntime"
local previous = _G[KEY]
if type(previous) == "table" and type(previous.Cleanup) == "function" then
    local ok, restored = pcall(previous.Cleanup)
    if not ok or restored == false then
        warn("[Inventory Unlimiter] Could not restore the previous instance; reload cancelled.")
        return
    end
end

local runtime = { alive=true, initializing=true, values={enabled=false, maxItems=9999}, generation=0 }
local warnings = {}
local function Notify(text, duration)
    if type(shared.Notify) == "function" then pcall(shared.Notify, text, duration or 3) end
end
local function WarnOnce(key, text)
    if warnings[key] then return end
    warnings[key] = true
    warn("[Inventory Unlimiter] " .. text)
    Notify("Inventory Unlimiter: " .. text, 5)
end
local function Finite(value)
    return type(value)=="number" and value==value and value>-math.huge and value<math.huge
end
local function ClampItems(value)
    if not Finite(value) then return nil end
    return math.clamp(math.floor(value+0.5),2,9999)
end

local environment = {}
if type(getgenv)=="function" then
    local ok, result=pcall(getgenv)
    if ok and type(result)=="table" then environment=result end
end
local fileRead = type(readfile)=="function" and readfile or environment.readfile
local fileWrite = type(writefile)=="function" and writefile or environment.writefile
local fileExists = type(isfile)=="function" and isfile or environment.isfile
local FILE = "Noir Hub/configs/ODH_InventoryUnlimiter_settings.json"
local httpOK, HttpService = pcall(function() return game:GetService("HttpService") end)
local canPersist = type(fileRead)=="function" and type(fileWrite)=="function" and httpOK and HttpService~=nil
runtime.settingsFile=FILE
runtime.saveStatus="Not saved"

local function LoadSettings()
    if not canPersist then
        runtime.saveStatus="Unavailable"
        WarnOnce("filesystem","readfile/writefile unavailable; settings cannot survive a new session.")
        return
    end
    if type(fileExists)=="function" then
        local ok, exists=pcall(fileExists,FILE)
        if ok and not exists then return end
    end
    local ok,text=pcall(fileRead,FILE)
    if not ok then
        if type(fileExists)=="function" then
            runtime.saveStatus="Read error"
            WarnOnce("read","Cannot read settings: " .. tostring(text))
        end
        return
    end
    local decoded,data=pcall(function() return HttpService:JSONDecode(text) end)
    if not decoded or type(data)~="table" or data.version~=1 or type(data.values)~="table" then
        runtime.saveStatus="Invalid file"
        WarnOnce("read","Invalid settings file. Kept unchanged until you change a setting.")
        return
    end
    if type(data.values.enabled)=="boolean" then runtime.values.enabled=data.values.enabled end
    runtime.values.maxItems=ClampItems(data.values.maxItems) or 9999
    runtime.saveStatus="Loaded"
end
local function SaveSettings()
    if not runtime.alive or runtime.initializing or not canPersist then return false end
    local ok,err=pcall(function()
        fileWrite(FILE,HttpService:JSONEncode({version=1,values={
            enabled=runtime.values.enabled,maxItems=runtime.values.maxItems,
        }}))
    end)
    if not ok then
        runtime.saveStatus="Write error"
        WarnOnce("write","Cannot save settings: " .. tostring(err))
        return false
    end
    warnings.write=nil
    runtime.saveStatus="Saved"
    return true
end
LoadSettings()

local debugLibrary = type(debug)=="table" and debug or {}
local function Resolve(primary, fallback, external)
    if type(primary)=="function" then return primary end
    if type(fallback)=="function" then return fallback end
    if type(external)=="function" then return external end
end
local getGC = Resolve(getgc, environment.getgc)
local readUpvalues = Resolve(debugLibrary.getupvalues, getupvalues, environment.getupvalues)
local writeUpvalue = Resolve(debugLibrary.setupvalue, setupvalue, environment.setupvalue)
local readInfo = Resolve(debugLibrary.getinfo, getinfo, environment.getinfo)
local readConstants = Resolve(debugLibrary.getconstants, getconstants, environment.getconstants)
local readName = Resolve(debugLibrary.info)

local changed = {}
local connection
local statusLabel
local function Status(text)
    runtime.status=text
    if statusLabel then pcall(function() statusLabel:SetValue(text) end) end
end
local function IsTarget(fn)
    local name
    if readInfo then
        local ok,info=pcall(readInfo,fn)
        if ok and type(info)=="table" then name=info.name end
    elseif readName then
        local ok,value=pcall(readName,fn,"n")
        if ok then name=value end
    end
    if name=="updateItemFrame" or name=="onItemEquipped" then return true end
    if readConstants then
        local ok,constants=pcall(readConstants,fn)
        if ok and type(constants)=="table" then
            local touch,equip=false,false
            for _,value in pairs(constants) do
                if value=="TouchBinding" then touch=true end
                if value=="EquipButton" then equip=true end
            end
            return touch and equip
        end
    end
    return false
end
local function WriteAndVerify(fn,index,value)
    local ok,err=pcall(writeUpvalue,fn,index,value)
    if not ok then return false,tostring(err) end
    local readable,values=pcall(readUpvalues,fn)
    if not readable or type(values)~="table" or values[index]~=value then
        return false,"upvalue verification failed"
    end
    return true
end
local function RestoreOriginals()
    local allRestored=true
    for fn,slots in pairs(changed) do
        local readable,values=pcall(readUpvalues,fn)
        if not readable or type(values)~="table" then
            allRestored=false
            WarnOnce("restore-read","Could not inspect previously changed values; restoration is pending.")
        else
            for index,saved in pairs(slots) do
                local current=values[index]
                if current==saved.original then
                    slots[index]=nil
                elseif current~=saved.last then
                    WarnOnce("conflict","A value changed elsewhere; left it untouched.")
                    slots[index]=nil
                else
                    local ok,err=WriteAndVerify(fn,index,saved.original)
                    if ok then slots[index]=nil
                    else
                        allRestored=false
                        WarnOnce("restore-write","Cannot restore an original limit: " .. tostring(err))
                    end
                end
            end
        end
        if next(slots)==nil then changed[fn]=nil end
    end
    return allRestored
end
local function ApplyLimit()
    if not (getGC and readUpvalues and writeUpvalue and (readInfo or readName or readConstants)) then
        Status("UNSUPPORTED: required executor debug functions are missing")
        WarnOnce("debug","Required debug functions are unavailable (getgc/getupvalues/setupvalue and target identification).")
        return 0
    end
    local ok,objects=pcall(getGC)
    if not ok or type(objects)~="table" then
        Status("ERROR: getgc failed")
        WarnOnce("scan","getgc failed: " .. tostring(objects))
        return 0
    end
    local target=runtime.values.maxItems
    local count=0
    for _,fn in pairs(objects) do
        if type(fn)=="function" and (changed[fn] or IsTarget(fn)) then
            local readable,values=pcall(readUpvalues,fn)
            if readable and type(values)=="table" then
                for index,value in pairs(values) do
                    if type(index)=="number" and index>=1 and index%1==0 and type(value)=="number" then
                        local slots=changed[fn]
                        local saved=slots and slots[index]
                        if saved or value==10 or value==3 then
                            if not saved then
                                slots=slots or {};changed[fn]=slots
                                saved={original=value,last=value};slots[index]=saved
                            end
                            if value==target then
                                saved.last=target;count=count+1
                            elseif value==saved.last or value==saved.original then
                                saved.last=target
                                local applied,err=WriteAndVerify(fn,index,target)
                                if applied then count=count+1
                                else WarnOnce("apply","Cannot write/verify a target limit: " .. tostring(err)) end
                            else
                                WarnOnce("conflict","A value changed elsewhere; left it untouched.")
                            end
                        end
                    end
                end
            end
        end
    end
    if count>0 then Status("ON | Max Items: " .. target .. " | verified values: " .. count)
    else Status("WAITING | Inventory functions not found or not writable") end
    return count
end
local function RequestApply()
    runtime.generation=runtime.generation+1
    local token=runtime.generation
    if not runtime.values.enabled then
        local restored=RestoreOriginals()
        Status(restored and "OFF | Original values restored" or "OFF | Restoration pending; press Reapply / Retry")
        return
    end
    Status("Applying saved/current limit...")
    task.spawn(function()
        for _,delay in ipairs({0.2,0.8,2.0}) do
            task.wait(delay)
            if not runtime.alive or runtime.generation~=token or not runtime.values.enabled then return end
            ApplyLimit()
        end
    end)
end
runtime.Cleanup=function()
    runtime.alive=false
    runtime.generation=runtime.generation+1
    if connection then connection:Disconnect();connection=nil end
    return RestoreOriginals()
end
runtime.SaveSettings=SaveSettings

local UI_VERSION=5
local ui
if type(previous)=="table" and type(previous.ui)=="table"
    and previous.ui.owner==shared and previous.ui.version==UI_VERSION and previous.ui.complete then
    ui=previous.ui
else
    local ok,result=pcall(function()
        local tab=shared.CreateTab("Inventory Unlimiter", "/mellnikovden968-web/CFG_PM2/refs/heads/main/icon")
        return {owner=shared,version=UI_VERSION,tab=tab,
            section=tab:AddSection("Inventory Unlimiter V5","Client-side limit • Saved preferences"),visual=false}
    end)
    if not ok then warn("[Inventory Unlimiter] UI failed: " .. tostring(result));return end
    ui=result
end
runtime.ui=ui
ui.runtime=runtime
_G[KEY]=runtime
runtime.SetEnabled=function(state)
    runtime.values.enabled=state==true
    SaveSettings()
    RequestApply()
end
runtime.SetMaxItems=function(value)
    local number=ClampItems(value)
    if not number then return end
    runtime.values.maxItems=number
    SaveSettings()
    if runtime.values.enabled then RequestApply() end
end
runtime.Reapply=RequestApply

if not ui.complete then
    local ok,err=pcall(function()
        ui.section:AddParagraph("Persistence", "Toggle and Max Items are saved on change. Load this plugin again after joining; saved preferences restore automatically.")
        ui.toggle=ui.section:AddToggle("Unlimit Inventory",function(value)
            ui.visual=value==true
            local active=ui.runtime
            if active and active.alive and not active.initializing then active.SetEnabled(value) end
        end)
        assert(type(ui.toggle)=="function","AddToggle must return a closure")
        ui.slider=ui.section:AddSlider("Max Items",2,9999,runtime.values.maxItems,function(value)
            local active=ui.runtime
            if active and active.alive and not active.initializing then active.SetMaxItems(value) end
        end)
        ui.status=ui.section:AddLabel("Initializing...",true)
        ui.section:AddButton("Reapply / Retry",function()
            local active=ui.runtime
            if active and active.alive and not active.initializing then active.Reapply() end
        end)
    end)
    if not ok then runtime.Cleanup();warn("[Inventory Unlimiter] UI controls failed: " .. tostring(err));return end
    ui.complete=true
end
statusLabel=ui.status
local synced,err=pcall(function()
    ui.slider:SetValue(runtime.values.maxItems)
    if ui.visual~=runtime.values.enabled then ui.toggle() end
    assert(ui.visual==runtime.values.enabled,"toggle state mismatch")
end)
if not synced then runtime.Cleanup();warn("[Inventory Unlimiter] UI sync failed: " .. tostring(err));return end
runtime.initializing=false

local LocalPlayer=game:GetService("Players").LocalPlayer
if LocalPlayer then
    connection=LocalPlayer.CharacterAdded:Connect(function()
        if runtime.alive and runtime.values.enabled then RequestApply() end
    end)
end
RequestApply()
print("[Inventory Unlimiter V5] Loaded | Settings: " .. FILE .. " | " .. runtime.saveStatus)

        end, function(__error) return tostring(__error) end)
        if not __pluginOk then
            warn("[Noir embedded plugin: unlimit.lua.txt] " .. tostring(__pluginError))
            notify("unlimit.lua.txt failed to load: " .. tostring(__pluginError), 7)
        end
    end
    do
        local __pluginOk, __pluginError = xpcall(function()
local ODHX = (function()
    local X = { ready=false, silent=false, restoring=false, replay=true, records={}, byKey={}, data={version=1, controls={}}, external=false }
    X.id, X.title, X.file = "Pm-Wallhop", "Pm-WallHop", "Noir Hub/configs/ODH_Pm-Wallhop_settings.json"
    local host = odh_shared_plugins
    assert(host and type(host.CreateTab)=="function", X.title .. ": load through the current Overdrive H plugin menu")
    local env = {}
    if type(getgenv)=="function" then local ok,g=pcall(getgenv); if ok and type(g)=="table" then env=g end end
    local rd = type(readfile)=="function" and readfile or env.readfile
    local wr = type(writefile)=="function" and writefile or env.writefile
    local exists = type(isfile)=="function" and isfile or env.isfile
    local http = game:GetService("HttpService")
    local reported = {}
    local function report(message)
        if reported[message] then return end
        reported[message]=true
        warn("[" .. X.title .. "] " .. message)
        if type(host.Notify)=="function" then pcall(host.Notify, X.title .. ": " .. message, 5) end
    end
    X.Report = report
    local function finite(v) return type(v)=="number" and v==v and math.abs(v)<math.huge end
    local function encode(v, depth)
        depth=depth or 0
        if depth>20 then error("settings nesting too deep") end
        if typeof(v)=="Color3" then return {__odhColor={v.R,v.G,v.B}} end
        local t=type(v)
        if t=="boolean" or t=="string" then return v end
        if t=="number" then if finite(v) then return v end; return nil end
        if t=="table" then
            local result={}
            for k,item in pairs(v) do
                if type(k)=="string" or type(k)=="number" then result[k]=encode(item,depth+1) end
            end
            return result
        end
        return nil
    end
    local function decode(v, depth)
        depth=depth or 0
        if depth>20 then error("settings nesting too deep") end
        if type(v)~="table" then return v end
        if v.__odhColor then
            local c=v.__odhColor
            assert(type(c)=="table" and finite(c[1]) and finite(c[2]) and finite(c[3]),"invalid color")
            return Color3.new(math.clamp(c[1],0,1),math.clamp(c[2],0,1),math.clamp(c[3],0,1))
        end
        local result={}
        for k,item in pairs(v) do result[k]=decode(item,depth+1) end
        return result
    end
    X.Encode, X.Decode = encode, decode
    if not X.external then
        if type(rd)=="function" and type(wr)=="function" then
            local present=true
            if type(exists)=="function" then local ok,v=pcall(exists,X.file); if ok then present=v end end
            if present then
                local ok,text=pcall(rd,X.file)
                if ok then
                    local good,data=pcall(function() return decode(http:JSONDecode(text)) end)
                    if good and type(data)=="table" and data.version==1 and type(data.controls)=="table" then X.data=data
                    else X.badFile=true; report("Invalid settings file; defaults loaded. A manual change will replace it.") end
                elseif type(exists)=="function" then report("Could not read settings file: " .. tostring(text)); X.badFile=true end
            end
        else report("readfile/writefile unavailable; settings last only for this session.") end
    end
    local tab
    X.shared=setmetatable({}, {__index=host})
    X.shared.Notify=function(text,seconds)
        if X.restoring then return end
        if type(host.Notify)=="function" then return host.Notify(text,seconds or 3) end
    end
    local function key(section,name,kind) return section .. " / " .. kind .. " / " .. name end
    local function safeValue(r,v)
        if r.kind=="Toggle" then if type(v)=="boolean" then return v end
        elseif r.kind=="Slider" then if finite(v) then return math.clamp(v,r.min,r.max) end
        elseif r.kind=="Colorpicker" then if typeof(v)=="Color3" then return v end
        elseif r.kind=="Dropdown" then
            for _,item in ipairs(r.items) do if v==item then return v end end
        end
        return nil
    end
    local function show(r,v)
        if v==nil or r.shown==v then return end
        local prior=X.silent; X.silent=true
        local ok,err=pcall(function()
            if r.kind=="Toggle" then
                if r.visual~=v then assert(type(r.handle)=="function","AddToggle must return a closure"); r.handle() end
            elseif r.kind=="Slider" then r.handle:SetValue(v)
            elseif r.kind=="Colorpicker" then r.handle:SetRGBValue(v)
            elseif r.kind=="Dropdown" then r.handle:Select(v) end
        end)
        X.silent=prior
        if ok then r.shown=v else report("UI sync failed: " .. r.name .. ": " .. tostring(err)) end
    end
    function X.Bind(section,name,kind,getter)
        local r=X.byKey[key(section,name,kind)]
        assert(r,"Unknown binding " .. section .. " / " .. name)
        r.get=getter
    end
    function X.Sync()
        for _,r in ipairs(X.records) do
            if r.get then
                local ok,v=pcall(r.get)
                if ok then
                    v=safeValue(r,v)
                    if v~=nil then
                        r.value=v
                        if not r.exclude then X.data.controls[r.key]=v end
                        show(r,v)
                    end
                end
            end
        end
    end
    function X.Commit()
        if not X.ready or X.silent or X.restoring or X.stopped or X.committing then return end
        X.committing=true
        local ok,err=pcall(function()
            X.Sync()
            if X.capture then X.data.snapshot=X.capture() end
            if X.external then
                if not X.backend or not X.backend(X.data) then error("native settings file could not be saved") end
            elseif type(wr)=="function" then
                wr(X.file,http:JSONEncode(encode(X.data)))
            end
        end)
        X.committing=false
        if not ok then report("Settings save failed: " .. tostring(err)) end
    end
    function X.Restore()
        X.restoring=true
        for _,togglePass in ipairs({false,true}) do
            for _,r in ipairs(X.records) do
                if not r.exclude and ((r.kind=="Toggle")==togglePass) then
                    local v=safeValue(r,X.data.controls[r.key])
                    if v==nil and r.get then local ok,x=pcall(r.get); if ok then v=safeValue(r,x) end end
                    if v==nil then v=r.default end
                    if v~=nil then
                        show(r,v)
                        local ok,err=pcall(r.callback,v)
                        if not ok then report("Restore failed: " .. r.name .. ": " .. tostring(err)) end
                        r.value=v; X.data.controls[r.key]=v
                    end
                end
            end
        end
        X.restoring=false
    end
    function X.Finish()
        if X.replay then X.Restore() else X.Sync() end
        X.ready=true
        if not X.badFile then X.Commit() end
    end
    function X.Set(section,name,kind,v,apply)
        local r=X.byKey[key(section,name,kind)]
        if not r then return end
        v=safeValue(r,v); if v==nil then return end
        show(r,v); r.value=v; X.data.controls[r.key]=v
        if apply then r.callback(v) end
    end
    function X.ResetControls()
        X.data.controls={}
        for _,r in ipairs(X.records) do
            if r.kind=="Toggle" and not r.exclude then X.Set(r.section,r.name,r.kind,false,true) end
        end
    end
    function X.shared.AddSection(name,subtitle)
        if not tab then tab=host.CreateTab(X.title,"/mellnikovden968-web/CFG_PM2/refs/heads/main/icon") end
        local raw=tab:AddSection(name,subtitle or "")
        local section={Name=name,Raw=raw}
        local function register(kind,label,callback,default,min,max,items)
            local r={section=name,name=label,kind=kind,callback=callback,default=default,min=min,max=max,items=items,visual=false}
            r.key=key(name,label,kind)
            r.exclude=(name=="🔑 Keys")
            X.records[#X.records+1]=r; X.byKey[r.key]=r
            local function changed(v)
                if kind=="Toggle" then r.visual=(v==true) end
                if not X.ready or X.silent or X.restoring or X.stopped then return end
                v=safeValue(r,v); if v==nil then return end
                r.shown=v
                local ok,err=pcall(callback,v)
                if ok then
                    r.value=v
                    if not r.exclude then X.data.controls[r.key]=v end
                    X.Commit()
                else report("Callback failed: " .. label .. ": " .. tostring(err)) end
            end
            if kind=="Toggle" then r.handle=raw:AddToggle(label,changed)
            elseif kind=="Slider" then r.handle=raw:AddSlider(label,min,max,default,changed)
            elseif kind=="Colorpicker" then r.handle=raw:AddColorpicker(label,default,changed)
            elseif kind=="Dropdown" then r.handle=raw:AddDropdown(label,items,changed) end
            return r.handle
        end
        function section:AddToggle(label,cb) return register("Toggle",label,cb,false) end
        function section:AddSlider(label,min,max,default,cb) return register("Slider",label,cb,default,min,max) end
        function section:AddColorpicker(label,default,cb) return register("Colorpicker",label,cb,default) end
        function section:AddDropdown(label,items,cb) return register("Dropdown",label,cb,items[1],nil,nil,items) end
        local function action(cb)
            return function(...)
                if not X.ready or X.stopped then return end
                local ok,err=pcall(cb,...)
                if not ok then report("Action failed: " .. tostring(err)) end
                X.Commit()
            end
        end
        function section:AddButton(label,cb) return raw:AddButton(label,action(cb)) end
        function section:AddKeybind(label,default,cb) return raw:AddKeybind(label,default,action(cb)) end
        function section:AddPlayerDropdown(label,cb) return raw:AddPlayerDropdown(label,action(cb)) end
        function section:AddTextBox(label,cb) return raw:AddTextBox(label,action(cb)) end
        function section:AddLabel(...) return raw:AddLabel(...) end
        function section:AddParagraph(...) return raw:AddParagraph(...) end
        return section
    end
    function X.Path(object)
        local parts={}
        local player=game:GetService("Players").LocalPlayer
        while object and object~=game do
            table.insert(parts,1,object==player and "$LocalPlayer" or object.Name)
            object=object.Parent
            if #parts>32 then return nil end
        end
        if object~=game then return nil end
        return parts
    end
    function X.Resolve(parts)
        if type(parts)~="table" then return nil end
        local object=game
        for _,name in ipairs(parts) do
            if name=="$LocalPlayer" then object=game:GetService("Players").LocalPlayer
            elseif type(name)=="string" and object then object=object:FindFirstChild(name)
            else return nil end
        end
        return object
    end
    X.connections={}
    function X.Connect(signal,callback)
        local c=signal:Connect(function(...) if not X.stopped then return callback(...) end end)
        X.connections[#X.connections+1]=c
        return c
    end
    function X.Stop()
        if X.stopped then return end
        X.Commit()
        X.stopped=true
        for _,c in ipairs(X.connections) do pcall(function() c:Disconnect() end) end
        if X.cleanup then pcall(X.cleanup) end
    end
    local registry=rawget(_G,"ODH_2026_PluginRuntimes")
    if type(registry)~="table" then registry={}; rawset(_G,"ODH_2026_PluginRuntimes",registry) end
    local previous=registry[X.id]
    if previous and type(previous.Stop)=="function" then pcall(previous.Stop) end
    registry[X.id]=X
    return X
end)()

local shared = ODHX.shared
local UpdateWallhopButtonState, performVideoFlick, performWallhop

local wallhop_section = shared.AddSection("Pm-WallHop")

wallhop_section:AddLabel("Pm-WallHop Script by @Phemtom (Improved)")
wallhop_section:AddParagraph("Pm-WallHop", "Флинг при прыжке возле стыка стен")

local isWallHopEnabled = false
wallhop_section:AddToggle("Включить WallHop", function(bool)
    isWallHopEnabled = bool
    if bool then
        shared.Notify("Pm-WallHop включен", 2)
    else
        shared.Notify("Pm-WallHop выключен", 2)
    end
    UpdateWallhopButtonState()
end)

wallhop_section:AddButton("Вкл/Выкл WallHop", function()
    isWallHopEnabled = not isWallHopEnabled
    shared.Notify(isWallHopEnabled and "Pm-WallHop включен" or "Pm-WallHop выключен", 2)
    UpdateWallhopButtonState()
end)

local detectionDistance = 3
wallhop_section:AddSlider("Дистанция обнаружения", 1, 6, 3, function(int)
    detectionDistance = int
    shared.Notify("Дистанция: " .. int, 2)
end)

local flickPower = 50
wallhop_section:AddSlider("Сила флинга", 20, 100, 50, function(int)
    flickPower = int
    shared.Notify("Сила: " .. int, 2)
end)

wallhop_section:AddKeybind("Toggle Keybind", "F", function()
    isWallHopEnabled = not isWallHopEnabled
    shared.Notify(isWallHopEnabled and "Pm-WallHop включен" or "Pm-WallHop выключен", 2)
    UpdateWallhopButtonState()
end)

wallhop_section:AddKeybind("WallHop Jump Key", "J", function()
    if isWallHopEnabled then
        performWallhop()
    else
        shared.Notify("WallHop выключен! Нажмите F или кнопку в меню", 2)
    end
end)

local WallhopBindableButtons = {Buttons = {}, Maids = {}, Count = 0}

local __SHAPES = {
    [0] = "rbxassetid://86221076925479",
    [1] = "rbxassetid://96242665417546",
    [2] = "rbxassetid://97129189935336",
    [3] = "rbxassetid://76165862027868",
    [4] = "rbxassetid://125868092127496"
}

local __NORMAL_COLOR = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(35,37,43)),
    ColorSequenceKeypoint.new(.22, Color3.fromRGB(244,246,250)),
    ColorSequenceKeypoint.new(.5, Color3.fromRGB(86,91,101)),
    ColorSequenceKeypoint.new(.78, Color3.fromRGB(225,228,234)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(38,40,46)),
})
local __ACTIVE_COLOR = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(55,58,66)),
    ColorSequenceKeypoint.new(.24, Color3.fromRGB(255,255,255)),
    ColorSequenceKeypoint.new(.52, Color3.fromRGB(138,144,154)),
    ColorSequenceKeypoint.new(.78, Color3.fromRGB(255,255,255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(55,58,66)),
})

local function safecallback(callback)
    if not callback then return end
    local ok, err = xpcall(callback, function(e) return debug.traceback(e) end)
    if not ok then warn("[BIND ERROR] " .. tostring(err)) end
end

local function GetStorage()
    local parent = gethui and gethui()
    if not parent or typeof(parent) ~= "Instance" then parent = game:GetService("CoreGui") end
    if not parent or typeof(parent) ~= "Instance" then
        parent = game.Players.LocalPlayer:WaitForChild("PlayerGui", 5)
    end
    if typeof(parent) ~= "Instance" then
        parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    end
    local sg = parent:FindFirstChild("@wallhopstorage")
    if not sg then
        sg = Instance.new("ScreenGui")
        sg.Name = "@wallhopstorage"
        sg.ResetOnSpawn = false
        sg.IgnoreGuiInset = true
        pcall(function() sg.ScreenInsets = Enum.ScreenInsets.None end)
        sg.Parent = parent
    end
    return sg
end

local function MakeDraggable(gui, maid, ripple, sound, clickFunc)
    local dragging, dragInput, dragStart, startPos
    local hasMoved = false

    maid:GiveTask(ODHX.Connect(gui.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, input.Position, gui.Position
            hasMoved = false

            sound:Play()
            local absPos = gui.AbsolutePosition
            ripple.Position = UDim2.new(0, input.Position.X - absPos.X, 0, input.Position.Y - absPos.Y)
            ripple.Size = UDim2.new(0, 0, 0, 0)
            ripple.BackgroundTransparency = 0.5
            ripple.Visible = true

            game:GetService("TweenService"):Create(ripple, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 45, 0, 45),
                BackgroundTransparency = 1
            }):Play()

            local releaseConn
            releaseConn = ODHX.Connect(game:GetService("UserInputService").InputEnded, function(endInput)
                if endInput.UserInputType == input.UserInputType then
                    dragging = false
                    if not hasMoved then
                        clickFunc()
                    end
                    releaseConn:Disconnect()
                end
            end)
        end
    end))

    maid:GiveTask(ODHX.Connect(gui.InputChanged, function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end))

    maid:GiveTask(ODHX.Connect(game:GetService("UserInputService").InputChanged, function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then hasMoved = true end
            local screen = gui.Parent.AbsoluteSize
            gui.Position = UDim2.new(startPos.X.Scale + (delta.X / screen.X), 0, startPos.Y.Scale + (delta.Y / screen.Y), 0)
        end
    end))
end

function WallhopBindableButtons.AddBButton(id, text, onFunc, offFunc)
    if WallhopBindableButtons.Buttons[id] then return WallhopBindableButtons.Buttons[id]:FindFirstChild("BindValue") end

    local buttonMaid = {}
    function buttonMaid:GiveTask(task)
        table.insert(buttonMaid._tasks or {}, task)
        return task
    end
    function buttonMaid:Destroy()
        if buttonMaid._tasks then
            for _, t in pairs(buttonMaid._tasks) do
                if typeof(t) == "RBXScriptConnection" then t:Disconnect()
                elseif typeof(t) == "Instance" then t:Destroy()
                elseif type(t) == "function" then t()
                end
            end
        end
    end
    buttonMaid._tasks = {}

    local screen = workspace.CurrentCamera.ViewportSize
    local buttonSizeY = 0.085
    local widthScale = buttonSizeY * (screen.Y / screen.X)

    local xPos = 0.1 + ((WallhopBindableButtons.Count % 8) * (widthScale + 0.005))
    local yPos = 0.7 - (math.floor(WallhopBindableButtons.Count / 8) * (buttonSizeY + 0.015))

    local ImageButton = Instance.new("ImageButton")
    ImageButton.Name = id
    ImageButton.Size = UDim2.new(widthScale, 0, buttonSizeY, 0)
    ImageButton.Position = UDim2.new(xPos, 0, yPos, 0)
    ImageButton.AnchorPoint = Vector2.new(0.5, 0.5)
    ImageButton.Image = ""
    ImageButton.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
    ImageButton.BackgroundTransparency = 0.42
    ImageButton.BorderSizePixel = 0
    ImageButton.ClipsDescendants = false
    ImageButton.AutoButtonColor = false
    Instance.new("UICorner", ImageButton).CornerRadius = UDim.new(0, 1000)
    local outerButtonStroke = Instance.new("UIStroke", ImageButton)
    outerButtonStroke.Color = Color3.new(1, 1, 1)
    outerButtonStroke.Thickness = 2
    outerButtonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    local innerButtonStroke = Instance.new("UIStroke", ImageButton)
    innerButtonStroke.Color = Color3.fromRGB(105, 105, 112)
    innerButtonStroke.Transparency = 0.5
    innerButtonStroke.Thickness = 1
    innerButtonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    ImageButton.Parent = GetStorage()
    buttonMaid:GiveTask(ImageButton)

    local BindValue = Instance.new("BoolValue", ImageButton)
    BindValue.Name = "BindValue"

    local TextLabel = Instance.new("TextLabel", ImageButton)
    TextLabel.Name = "@Text"
    TextLabel.Size = UDim2.new(0.92, 0, 0.22, 0)
    TextLabel.Position = UDim2.new(0.5, 0, 0.82, 0)
    TextLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Font = Enum.Font.GothamBold
    TextLabel.Text = text .. "  //  OFF"
    TextLabel.TextColor3 = Color3.new(1, 1, 1)
    TextLabel.TextSize = 12
    TextLabel.TextScaled = true
    TextLabel.TextWrapped = true
    TextLabel.ZIndex = 12

    local Aspect = Instance.new("UIAspectRatioConstraint", ImageButton)
    Aspect.AspectRatio = 1
    Aspect.AspectType = Enum.AspectType.ScaleWithParentSize

    local Gradient = Instance.new("UIGradient", outerButtonStroke)
    Gradient.Name = "@Stroke"
    Gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 40)),
        ColorSequenceKeypoint.new(0.22, Color3.fromRGB(250, 250, 252)),
        ColorSequenceKeypoint.new(0.48, Color3.fromRGB(70, 70, 78)),
        ColorSequenceKeypoint.new(0.72, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(45, 45, 52)),
    })
    local innerButtonGradient = Gradient:Clone()
    innerButtonGradient.Rotation = 180
    innerButtonGradient.Parent = innerButtonStroke

    local ripple = Instance.new("Frame")
    ripple.Name = "@ripple"
    ripple.BackgroundColor3 = Color3.fromRGB(226, 230, 238)
    ripple.BackgroundTransparency = 0.5
    ripple.Size = UDim2.new(0, 0, 0, 0)
    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
    ripple.Visible = false
    ripple.ZIndex = 2
    ripple.Parent = ImageButton
    Instance.new("UICorner", ripple).CornerRadius = UDim.new(1, 0)

    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://3868133279"
    sound.Volume = 0.5
    sound.Parent = ImageButton
    pcall(function() __NOIR_GUARD.blackhole.StyleFloat(ImageButton, sound) end)
    pcall(function() __NOIR_GUARD.floatIcon(ImageButton, text, "WH") end)

    local debounce = false
    local tInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

    local function onClick()
        if debounce then return end
        debounce = true
        local fOut = game:GetService("TweenService"):Create(ImageButton, tInfo, {ImageTransparency = 1})
        fOut:Play()
        fOut.Completed:Wait()

        BindValue.Value = not BindValue.Value
        TextLabel.Text = text .. (BindValue.Value and "  //  ON" or "  //  OFF")
        Gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 40)),
            ColorSequenceKeypoint.new(0.22, Color3.fromRGB(250, 250, 252)),
            ColorSequenceKeypoint.new(0.48, Color3.fromRGB(70, 70, 78)),
            ColorSequenceKeypoint.new(0.72, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(45, 45, 52)),
        })
        if BindValue.Value then safecallback(onFunc) else safecallback(offFunc) end

        local fIn = game:GetService("TweenService"):Create(ImageButton, tInfo, {ImageTransparency = 0})
        fIn:Play()
        fIn.Completed:Wait()
        debounce = false
    end

    MakeDraggable(ImageButton, buttonMaid, ripple, sound, onClick)
    

    WallhopBindableButtons.Buttons[id] = ImageButton
    WallhopBindableButtons.Maids[id] = buttonMaid
    WallhopBindableButtons.Count = WallhopBindableButtons.Count + 1
    return BindValue
end

function WallhopBindableButtons.DeleteBButton(id)
    if WallhopBindableButtons.Maids[id] then
        WallhopBindableButtons.Maids[id]:Destroy()
        WallhopBindableButtons.Maids[id] = nil
    end
    if WallhopBindableButtons.Buttons[id] then
        WallhopBindableButtons.Buttons[id]:Destroy()
        WallhopBindableButtons.Buttons[id] = nil
    end
end

UpdateWallhopButtonState = function()
    ODHX.Commit()
    local btn = WallhopBindableButtons.Buttons["wallhop_toggle"]
    if not btn then return end
    local value=btn:FindFirstChild("BindValue")
    if value then value.Value=isWallHopEnabled end
    local textLabel = btn:FindFirstChild("@Text")
    if textLabel then
        textLabel.Text = isWallHopEnabled and "ON" or "OFF"
    end
    local gradient = btn:FindFirstChild("@Stroke")
    if gradient then
        gradient.Color = isWallHopEnabled and __ACTIVE_COLOR or __NORMAL_COLOR
    end
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local isFlicking = false
local lastFlickTime = 0
local isJumpKeyPressed = false
local Camera = workspace.CurrentCamera
local wallDetectionCooldown = 0
local lastWallhopAt = 0
local WALLHOP_COOLDOWN = 0.15

local wallRaycastParams = RaycastParams.new()
wallRaycastParams.FilterType = Enum.RaycastFilterType.Blacklist

local function isPlayerCharacter(instance)
    if not instance then return false end
    local current = instance
    while current do
        if current:IsA("Model") and current:FindFirstChildOfClass("Humanoid") then
            local players = Players:GetPlayers()
            for _, player in ipairs(players) do
                if player.Character == current then
                    return true
                end
            end
        end
        current = current.Parent
    end
    return false
end

local function isWall(instance)
    if not instance or not instance.IsA then return false end

    if instance:IsA("Part") and instance.Parent and instance.Parent:IsA("Model") and instance.Parent:FindFirstChild("Humanoid") then
        return false
    end

    local current = instance
    while current do
        if isPlayerCharacter(current) then
            return false
        end
        current = current.Parent
    end

    if not instance:IsA("BasePart") and not instance:IsA("Terrain") then
        return false
    end

    if instance:IsA("BasePart") and not instance.CanCollide then
        return false
    end

    return true
end

local function getWallRaycastResult()
    local character = LocalPlayer.Character
    if not character then return nil end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local players = Players:GetPlayers()
    local blacklist = {character}
    for _, player in ipairs(players) do
        if player ~= LocalPlayer and player.Character then
            table.insert(blacklist, player.Character)
        end
    end
    wallRaycastParams.FilterDescendantsInstances = blacklist

    local closestHit, minDistance = nil, detectionDistance
    local hrpCF = hrp.CFrame
    for i = 0,7 do
        local angle = math.rad(i*45)
        local dir = (hrpCF * CFrame.Angles(0, angle, 0)).LookVector
        local ray = workspace:Raycast(hrp.Position, dir * detectionDistance, wallRaycastParams)
        if ray and ray.Instance and ray.Distance < minDistance then
            local hitInstance = ray.Instance
            if isWall(hitInstance) then
                minDistance = ray.Distance
                closestHit = ray
            end
        end
    end
    return closestHit
end

performVideoFlick = function()
    if not isWallHopEnabled then return end
    if isFlicking then return end
    isFlicking = true

    local char = LocalPlayer.Character
    if not char then isFlicking = false return end

    local hum = char:FindFirstChild("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then isFlicking = false return end

    if hum.Health <= 0 then isFlicking = false return end

    local currentVel = hrp.Velocity

    hum:ChangeState(Enum.HumanoidStateType.Jumping)
    hrp.Velocity = Vector3.new(currentVel.X, flickPower, currentVel.Z)

    local startCFrame = Camera.CFrame
    Camera.CFrame = startCFrame * CFrame.Angles(0, math.rad(180), 0)

    task.wait(0.01)
    Camera.CFrame = startCFrame

    isFlicking = false
end

performWallhop = function()
    if not isWallHopEnabled then return end

    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not (humanoid and rootPart and humanoid:GetState() ~= Enum.HumanoidStateType.Dead) then return end
    local now = os.clock()
    if now - lastWallhopAt < WALLHOP_COOLDOWN then return end

    local wall = getWallRaycastResult()
    if not wall then return end
    lastWallhopAt = now

    rootPart.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + wall.Normal)
    RunService.Heartbeat:Wait()

    if humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        task.wait(0.1)
    end
end

local lastHitInstance = nil
local currentHitInstance = nil

ODHX.Connect(RunService.Heartbeat, function()
    if not isWallHopEnabled or isFlicking then return end

    local char = LocalPlayer.Character
    if not char then
        lastHitInstance = nil
        return
    end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then
        lastHitInstance = nil
        return
    end

    if not isJumpKeyPressed then
        lastHitInstance = nil
        return
    end

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {char}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.IgnoreWater = true

    local direction = Camera.CFrame.LookVector * detectionDistance
    local result = workspace:Raycast(hrp.Position, direction, raycastParams)

    currentHitInstance = nil

    if result then
        local hitInstance = result.Instance

        if isWall(hitInstance) then
            currentHitInstance = hitInstance

            if lastHitInstance and lastHitInstance ~= currentHitInstance then
                local currentTime = os.clock()
                if currentTime - lastFlickTime > 0.1 then
                    lastFlickTime = currentTime
                    performVideoFlick()
                end
            end
        end
    end

    lastHitInstance = currentHitInstance
end)

ODHX.Connect(UserInputService.JumpRequest, function()
    if isWallHopEnabled then
        performWallhop()
    end
end)

ODHX.Connect(UserInputService.InputBegan, function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.Space then
        isJumpKeyPressed = true
    end
end)

ODHX.Connect(UserInputService.InputEnded, function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.Space then
        isJumpKeyPressed = false
        lastHitInstance = nil
    end
end)

ODHX.Connect(LocalPlayer.CharacterAdded, function(character)
    lastHitInstance = nil
    currentHitInstance = nil
    isFlicking = false
    lastWallhopAt = 0
end)

ODHX.Connect(UserInputService.WindowFocused, function()
    isJumpKeyPressed = false
    lastHitInstance = nil
end)

ODHX.Bind("Pm-WallHop", "Включить WallHop", "Toggle", function() return isWallHopEnabled end)
ODHX.Bind("Pm-WallHop", "Дистанция обнаружения", "Slider", function() return detectionDistance end)
ODHX.Bind("Pm-WallHop", "Сила флинга", "Slider", function() return flickPower end)
ODHX.cleanup=function()
    for id in pairs(WallhopBindableButtons.Buttons) do WallhopBindableButtons.DeleteBButton(id) end
end
ODHX.Finish()

        end, function(__error) return tostring(__error) end)
        if not __pluginOk then
            warn("[Noir embedded plugin: Pm-Wallhop.lua.txt] " .. tostring(__pluginError))
            notify("Pm-Wallhop.lua.txt failed to load: " .. tostring(__pluginError), 7)
        end
    end
end


 
do
    local __pluginOk, __pluginError = xpcall(function()
 
local noirHost = host
assert(noirHost and type(noirHost.CreateTab) == "function", "Ultimate Fling: Noir host unavailable")
 
local ODHX = (function()
    local X = { ready=false, silent=false, restoring=false, replay=true, records={}, byKey={}, data={version=1, controls={}}, external=true }
    X.id, X.title, X.file = "FLING", "ULTIMATE FLING", "Noir Hub/configs/ODH_FLING_settings.json"
    local host = {
        CreateTab = function()
            return noirHost.CreateTab()
        end,
        Notify = function(textValue, duration)
            return notify(tostring(textValue), duration or 3)
        end,
    }
    local env = {}
    if type(getgenv)=="function" then local ok,g=pcall(getgenv); if ok and type(g)=="table" then env=g end end
    local rd = type(readfile)=="function" and readfile or env.readfile
    local wr = type(writefile)=="function" and writefile or env.writefile
    local exists = type(isfile)=="function" and isfile or env.isfile
    local http = game:GetService("HttpService")
    local reported = {}
    local function report(message)
        if reported[message] then return end
        reported[message]=true
        warn("[" .. X.title .. "] " .. message)
        if type(host.Notify)=="function" then pcall(host.Notify, X.title .. ": " .. message, 5) end
    end
    X.Report = report
    local function finite(v) return type(v)=="number" and v==v and math.abs(v)<math.huge end
    local function encode(v, depth)
        depth=depth or 0
        if depth>20 then error("settings nesting too deep") end
        if typeof(v)=="Color3" then return {__odhColor={v.R,v.G,v.B}} end
        local t=type(v)
        if t=="boolean" or t=="string" then return v end
        if t=="number" then if finite(v) then return v end; return nil end
        if t=="table" then
            local result={}
            for k,item in pairs(v) do
                if type(k)=="string" or type(k)=="number" then result[k]=encode(item,depth+1) end
            end
            return result
        end
        return nil  
    end
    local function decode(v, depth)
        depth=depth or 0
        if depth>20 then error("settings nesting too deep") end
        if type(v)~="table" then return v end
        if v.__odhColor then
            local c=v.__odhColor
            assert(type(c)=="table" and finite(c[1]) and finite(c[2]) and finite(c[3]),"invalid color")
            return Color3.new(math.clamp(c[1],0,1),math.clamp(c[2],0,1),math.clamp(c[3],0,1))
        end
        local result={}
        for k,item in pairs(v) do result[k]=decode(item,depth+1) end
        return result
    end
    X.Encode, X.Decode = encode, decode
    if not X.external then
        if type(rd)=="function" and type(wr)=="function" then
            local present=true
            if type(exists)=="function" then local ok,v=pcall(exists,X.file); if ok then present=v end end
            if present then
                local ok,text=pcall(rd,X.file)
                if ok then
                    local good,data=pcall(function() return decode(http:JSONDecode(text)) end)
                    if good and type(data)=="table" and data.version==1 and type(data.controls)=="table" then X.data=data
                    else X.badFile=true; report("Invalid settings file; defaults loaded. A manual change will replace it.") end
                elseif type(exists)=="function" then report("Could not read settings file: " .. tostring(text)); X.badFile=true end
            end
        else report("readfile/writefile unavailable; settings last only for this session.") end
    end
    local tab
    X.shared=setmetatable({}, {__index=host})  
    X.shared.Notify=function(text,seconds)
        if X.restoring then return end
        if type(host.Notify)=="function" then return host.Notify(text,seconds or 3) end
    end
    local function key(section,name,kind) return section .. " / " .. kind .. " / " .. name end
    local function safeValue(r,v)
        if r.kind=="Toggle" then if type(v)=="boolean" then return v end
        elseif r.kind=="Slider" then if finite(v) then return math.clamp(v,r.min,r.max) end
        elseif r.kind=="Colorpicker" then if typeof(v)=="Color3" then return v end
        elseif r.kind=="Dropdown" then
            for _,item in ipairs(r.items) do if v==item then return v end end
        end
        return nil
    end
    local function show(r,v)
        if v==nil or r.shown==v then return end
        local prior=X.silent; X.silent=true
        local ok,err=pcall(function()
            if r.kind=="Toggle" then
                if r.visual~=v then assert(type(r.handle)=="function","AddToggle must return a closure"); r.handle() end
            elseif r.kind=="Slider" then r.handle:SetValue(v)
            elseif r.kind=="Colorpicker" then r.handle:SetRGBValue(v)
            elseif r.kind=="Dropdown" then r.handle:Select(v) end
        end)
        X.silent=prior
        if ok then r.shown=v else report("UI sync failed: " .. r.name .. ": " .. tostring(err)) end
    end
    function X.Bind(section,name,kind,getter)
        local r=X.byKey[key(section,name,kind)]
        assert(r,"Unknown binding " .. section .. " / " .. name)
        r.get=getter
    end
    function X.Sync()
        for _,r in ipairs(X.records) do
            if r.get then
                local ok,v=pcall(r.get)
                if ok then
                    v=safeValue(r,v)
                    if v~=nil then
                        r.value=v
                        if not r.exclude then X.data.controls[r.key]=v end
                        show(r,v)
                    end
                end
            end
        end
    end
    function X.Commit()
        if not X.ready or X.silent or X.restoring or X.stopped or X.committing then return end
        X.committing=true
        local ok,err=pcall(function()
            X.Sync()
            if X.capture then X.data.snapshot=X.capture() end
            if X.external then
                if not X.backend or not X.backend(X.data) then error("native settings file could not be saved") end
            elseif type(wr)=="function" then
                wr(X.file,http:JSONEncode(encode(X.data)))
            end
        end)
        X.committing=false
        if not ok then report("Settings save failed: " .. tostring(err)) end
    end
    function X.Restore()
        X.restoring=true
         
        for _,togglePass in ipairs({false,true}) do
            for _,r in ipairs(X.records) do
                if not r.exclude and ((r.kind=="Toggle")==togglePass) then
                    local v=safeValue(r,X.data.controls[r.key])
                    if v==nil and r.get then local ok,x=pcall(r.get); if ok then v=safeValue(r,x) end end
                    if v==nil then v=r.default end
                    if v~=nil then
                        show(r,v)
                        local ok,err=pcall(r.callback,v)
                        if not ok then report("Restore failed: " .. r.name .. ": " .. tostring(err)) end
                        r.value=v; X.data.controls[r.key]=v
                    end
                end
            end
        end
        X.restoring=false
    end
    function X.Finish()
        if X.replay then X.Restore() else X.Sync() end
        X.ready=true
        if not X.badFile then X.Commit() end
    end
    function X.Set(section,name,kind,v,apply)
        local r=X.byKey[key(section,name,kind)]
        if not r then return end
        v=safeValue(r,v); if v==nil then return end
        show(r,v); r.value=v; X.data.controls[r.key]=v
        if apply then r.callback(v) end
    end
    function X.ResetControls()
        X.data.controls={}
        for _,r in ipairs(X.records) do
            if r.kind=="Toggle" and not r.exclude then X.Set(r.section,r.name,r.kind,false,true) end
        end
    end
    function X.shared.AddSection(name,subtitle)
        if not tab then tab=host.CreateTab() end
         
        local raw=tab:AddSection("WORLD • " .. name,subtitle or "")
        local section={Name=name,Raw=raw}
        local function register(kind,label,callback,default,min,max,items)
            local r={section=name,name=label,kind=kind,callback=callback,default=default,min=min,max=max,items=items,visual=false}
            r.key=key(name,label,kind)
            r.exclude=(name=="🔑 Keys")  
            X.records[#X.records+1]=r; X.byKey[r.key]=r
            local function changed(v)
                if kind=="Toggle" then r.visual=(v==true) end
                if not X.ready or X.silent or X.restoring or X.stopped then return end
                v=safeValue(r,v); if v==nil then return end
                r.shown=v
                local ok,err=pcall(callback,v)
                if ok then
                    r.value=v
                    if not r.exclude then X.data.controls[r.key]=v end
                    X.Commit()
                else report("Callback failed: " .. label .. ": " .. tostring(err)) end
            end
            if kind=="Toggle" then r.handle=raw:AddToggle(label,changed)
            elseif kind=="Slider" then r.handle=raw:AddSlider(label,min,max,default,changed)
            elseif kind=="Colorpicker" then r.handle=raw:AddColorpicker(label,default,changed)
            elseif kind=="Dropdown" then r.handle=raw:AddDropdown(label,items,changed) end
            return r.handle
        end
        function section:AddToggle(label,cb) return register("Toggle",label,cb,false) end
        function section:AddSlider(label,min,max,default,cb) return register("Slider",label,cb,default,min,max) end
        function section:AddColorpicker(label,default,cb) return register("Colorpicker",label,cb,default) end
        function section:AddDropdown(label,items,cb) return register("Dropdown",label,cb,items[1],nil,nil,items) end
        local function action(cb)
            return function(...)
                if not X.ready or X.stopped then return end
                local ok,err=pcall(cb,...)
                if not ok then report("Action failed: " .. tostring(err)) end
                X.Commit()
            end
        end
        function section:AddButton(label,cb) return raw:AddButton(label,action(cb)) end
        function section:AddKeybind(label,default,cb) return raw:AddKeybind(label,default,action(cb)) end
        function section:AddPlayerDropdown(label,cb)
             
            local playerService = game:GetService("Players")
            local names, lookup = { "None" }, {}
            for _, player in ipairs(playerService:GetPlayers()) do
                if player ~= playerService.LocalPlayer then
                    names[#names + 1] = player.Name
                    lookup[player.Name] = player
                end
            end
            table.sort(names, function(a, b)
                if a == "None" then return true end
                if b == "None" then return false end
                return a:lower() < b:lower()
            end)
            return raw:AddDropdown(label, names, function(name)
                local player = lookup[name] or playerService:FindFirstChild(name)
                if player then action(cb)(player) end
            end)
        end
        function section:AddTextBox(label,cb) return raw:AddTextBox(label,action(cb)) end
        function section:AddLabel(...) return raw:AddLabel(...) end
        function section:AddParagraph(...) return raw:AddParagraph(...) end
        return section
    end
     
    function X.Path(object)
        local parts={}
        local player=game:GetService("Players").LocalPlayer
        while object and object~=game do
            table.insert(parts,1,object==player and "$LocalPlayer" or object.Name)
            object=object.Parent
            if #parts>32 then return nil end
        end
        if object~=game then return nil end
        return parts
    end
    function X.Resolve(parts)
        if type(parts)~="table" then return nil end
        local object=game
        for _,name in ipairs(parts) do
            if name=="$LocalPlayer" then object=game:GetService("Players").LocalPlayer
            elseif type(name)=="string" and object then object=object:FindFirstChild(name)
            else return nil end
        end
        return object
    end
    X.connections={}
    function X.Connect(signal,callback)
        local c=signal:Connect(function(...) if not X.stopped then return callback(...) end end)
        X.connections[#X.connections+1]=c
        return c
    end
    function X.Stop()
        if X.stopped then return end
        X.Commit()
        X.stopped=true
        for _,c in ipairs(X.connections) do pcall(function() c:Disconnect() end) end
        if X.cleanup then pcall(X.cleanup) end
    end
    local registry=rawget(_G,"ODH_2026_PluginRuntimes")
    if type(registry)~="table" then registry={}; rawset(_G,"ODH_2026_PluginRuntimes",registry) end
    local previous=registry[X.id]
    if previous and type(previous.Stop)=="function" then pcall(previous.Stop) end
    registry[X.id]=X
    return X
end)()
 


























 
local AUTHOR            = "K1LAS1K"
local BRAND             = "ULTIMATE FLING"
local PLUGIN_ID         = "fling"
local PLUGIN_NAME       = BRAND .. " • FLING"
local VERSION           = "V1.2"
local VERSION_TAG       = "fling"
local MARKER_PREFIX     = "@fling_"
local CONFIG_PATH       = CONFIGS_FOLDER .. "/ODH_FLING_settings.json"
local STORAGE_NAME      = "@" .. PLUGIN_ID
local UNLOAD_GLOBAL     = "__FLING_UNLOAD"
local LEGACY_STORAGES   = { "@bindstorage_v6", "@bindstorage_v5", "@flingstorage_v1" }
local CLEAN_LEGACY_MENU = true

 
local StarterGui = nil

local function hostNotify(text, dur)
    if type(notify) == "function" then
        local ok = pcall(notify, tostring(text), dur or 3)
        if ok then return end
    end
    pcall(function()
        local sg = StarterGui or game:GetService("StarterGui")
        sg:SetCore("SendNotification", {
            Title = BRAND, Text = tostring(text), Duration = dur or 3,
        })
    end)
end

local shared = ODHX.shared
if not shared then
    hostNotify(BRAND .. " " .. VERSION .. ": Load through Overdrive H plugin menu", 3)
    return
end

 
pcall(function()
    if type(getgenv) ~= "function" then return end
    local g = getgenv()
    if type(g) ~= "table" then return end
    local prev = rawget(g, UNLOAD_GLOBAL)
    rawset(g, UNLOAD_GLOBAL, nil)
    if type(prev) == "function" then pcall(prev) end
end)

 
local Maid = {}
Maid.__index = Maid

function Maid._cleanup(item)
    local t = typeof(item)
    if t == "RBXScriptConnection" then
        pcall(function() item:Disconnect() end)
    elseif t == "Instance" then
        pcall(function() item:Destroy() end)
    elseif t == "function" then
        local ok, err = pcall(item)
        if not ok then warn("[" .. BRAND .. "][maid] " .. tostring(err)) end
    elseif t == "thread" then
        pcall(task.cancel, item)
    elseif t == "table" and type(item.Destroy) == "function" then
        pcall(item.Destroy, item)
    end
end

function Maid.new()
    return setmetatable({ _tasks = {}, _destroyed = false }, Maid)
end

function Maid:GiveTask(item)
    if item == nil then return nil end
    if self._destroyed then
        Maid._cleanup(item)
        return nil
    end
    local tasks = self._tasks
    tasks[#tasks + 1] = item
    return item
end

function Maid:DoCleaning()
    if self._destroyed then return end
    self._destroyed = true
    local tasks = self._tasks
    self._tasks = {}
    for i = #tasks, 1, -1 do
        Maid._cleanup(tasks[i])
        tasks[i] = nil
    end
end

function Maid:Destroy()
    self:DoCleaning()
end

local RootMaid = Maid.new()

 
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local LocalPlayer       = Players.LocalPlayer
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local TweenService      = game:GetService("TweenService")
local HttpService       = game:GetService("HttpService")
local CoreGui           = game:GetService("CoreGui")
StarterGui              = game:GetService("StarterGui")

 
local new      = Instance.new
local clamp    = math.clamp
local sin, cos, floor = math.sin, math.cos, math.floor
local now      = os.clock
local insert   = table.insert
local ud2      = UDim2.new
local ud       = UDim.new
local v2       = Vector2.new
local v3       = Vector3.new
local cfr      = CFrame.new
local rgb      = Color3.fromRGB
local pclr     = Color3.new
local cs       = ColorSequence.new
local csk      = ColorSequenceKeypoint.new
local tinfo    = TweenInfo.new
local V3_ZERO  = Vector3.zero
local UIT      = Enum.UserInputType
local MOUSE1   = UIT.MouseButton1
local TOUCH    = UIT.Touch
local MOUSEMOV = UIT.MouseMovement
local EASING   = Enum.EasingStyle
local EDIR     = Enum.EasingDirection
local FALLBACK_VIEWPORT = v2(1920, 1080)

local function clearTable(t)
    if table.clear then table.clear(t) else for k in pairs(t) do t[k] = nil end end
end

 
local state_whitelist_ref = nil
local loadedWhitelist = {}
local persistDisabled = false

local DEFAULTS = {
    flingDuration     = 2,
    flingPower        = 1,
    flingMethod       = "Auto",  
    predictionStuds   = 8,
    startStuds        = 5,
    autoReturn        = true,
    loopInterval      = 0.4,
    auraInterval      = 0.4,
    auraStuds         = 15,
    bindButtonSize    = 0.085,
    targetCooldown    = 0.8,
    autoSheriffDelay  = 0.25,
    autoMurdererDelay = 0.35,
    roleCacheTTL      = 0.8,
    muteSounds        = false,
    notifications     = true,
    keybinds          = {},
    bindPositions     = {},
    hudPos            = { x = 0.5, y = 6 },
    pluginUI          = {},
    whitelist         = {},
}

local config = {}
for key, value in pairs(DEFAULTS) do
    if type(value) == "table" then
        local copy = {}
        for kk, vv in pairs(value) do copy[kk] = vv end
        config[key] = copy
    else
        config[key] = value
    end
end

local canPersist = (type(writefile) == "function" and type(readfile) == "function")
local jsonBroken = false

local function jsonEncode(tbl)
    if jsonBroken then return nil end
    local ok, res = pcall(function() return HttpService:JSONEncode(tbl) end)
    if ok and type(res) == "string" then return res end
    jsonBroken = true
    return nil
end

local function jsonDecode(str)
    if jsonBroken then return nil end
    local ok, res = pcall(function() return HttpService:JSONDecode(str) end)
    if ok and type(res) == "table" then return res end
    return nil
end

local function packWhitelist(map)
    local out = {}
    for id, name in pairs(map) do
        insert(out, { id = id, name = tostring(name) })
    end
    return out
end

local function unpackWhitelist(list)
    local map = {}
    if type(list) == "table" then
        for _, row in ipairs(list) do
            if type(row) == "table" and type(row.id) == "number" then
                map[row.id] = tostring(row.name or row.id)
            end
        end
    end
    return map
end

local function serializeConfig()
    return {
        flingDuration = config.flingDuration, flingPower = config.flingPower,
        flingMethod = config.flingMethod, predictionStuds = config.predictionStuds, startStuds = config.startStuds,
        autoReturn = config.autoReturn,
        loopInterval = config.loopInterval, auraInterval = config.auraInterval,
        auraStuds = config.auraStuds, bindButtonSize = config.bindButtonSize,
        targetCooldown = config.targetCooldown,
        autoSheriffDelay = config.autoSheriffDelay, autoMurdererDelay = config.autoMurdererDelay,
        roleCacheTTL = config.roleCacheTTL,
        muteSounds = config.muteSounds,
        notifications = config.notifications, pluginUI = config.pluginUI,
        keybinds = config.keybinds, bindPositions = config.bindPositions,
        hudPos = config.hudPos, whitelist = packWhitelist(state_whitelist_ref or {}),
    }
end

local function applyLoaded(data)
    if type(data) ~= "table" then return false end
    local scalars = {
        "flingDuration", "flingPower", "flingMethod", "predictionStuds", "startStuds", "autoReturn",
        "loopInterval", "auraInterval", "auraStuds",
        "bindButtonSize", "targetCooldown",
        "autoSheriffDelay", "autoMurdererDelay", "roleCacheTTL",
        "muteSounds", "notifications",
    }
    for _, key in ipairs(scalars) do
        local v = data[key]
        if v ~= nil and type(v) == type(DEFAULTS[key]) then config[key] = v end
    end
     
    if type(config.flingDuration)=="number" then config.flingDuration=math.clamp(math.floor(config.flingDuration+0.5),1,5) end
    if type(config.flingPower)=="number" then config.flingPower=math.clamp(math.floor(config.flingPower+0.5),1,3) end
    if type(config.predictionStuds)=="number" then config.predictionStuds=math.clamp(config.predictionStuds,0,20) end
    if type(config.startStuds)=="number" then config.startStuds=math.clamp(config.startStuds,-5,20) end
    local METHODS = { Auto=true, Fling=true, Sweep=true }
    if type(config.flingMethod)~="string" or not METHODS[config.flingMethod] then config.flingMethod="Auto" end
    if type(data.keybinds) == "table" then config.keybinds = data.keybinds end
    if type(data.bindPositions) == "table" then config.bindPositions = data.bindPositions end
    if type(data.hudPos) == "table" and type(data.hudPos.x) == "number" and type(data.hudPos.y) == "number" then
        config.hudPos = { x = data.hudPos.x, y = data.hudPos.y }
    end
    if type(data.pluginUI)=="table" then config.pluginUI=data.pluginUI end
    loadedWhitelist = unpackWhitelist(data.whitelist)
    return true
end

local function loadConfig()
    if not canPersist or type(isfile) ~= "function" then return false end
    local applied = false
    pcall(function()
        if not isfile(CONFIG_PATH) then return end
        applied = applyLoaded(jsonDecode(readfile(CONFIG_PATH))) and true or false
    end)
    return applied
end

local saveQueued, saveThread = false, nil

local function saveConfig(force)
    if not canPersist or persistDisabled then return false end
    if force then
        if saveThread then pcall(task.cancel,saveThread) end
        saveThread,saveQueued=nil,false
        local ok,err=pcall(function()
            local payload=jsonEncode(serializeConfig())
            assert(payload,"JSON encode failed")
            writefile(CONFIG_PATH,payload)
        end)
        if not ok then ODHX.Report("Could not save " .. CONFIG_PATH .. ": " .. tostring(err)) end
        return ok
    end
    if saveQueued and not force then return true end
    saveQueued = true
    if saveThread then pcall(task.cancel, saveThread) end
    saveThread = task.delay(force and 0 or 0.35, function()
        saveQueued = false
        saveThread = nil
        pcall(function()
            local payload = jsonEncode(serializeConfig())
            if payload then writefile(CONFIG_PATH, payload) end
        end)
    end)
    return true
end

local configLoaded = loadConfig()
ODHX.data.controls=config.pluginUI or {}
ODHX.backend=function(data)
    config.pluginUI=data.controls
    return saveConfig(true)
end

 
local state = {
    whitelist       = loadedWhitelist,
    selectedPlayers = {},
    selectedSet     = {},
    resetSelPlr     = nil,
    lastResetAt     = {},
}
state_whitelist_ref = state.whitelist

local maids = {
    loopPlr = nil, clickFling = nil, aura = nil, touchFling = nil,
    autoSheriff = nil, autoMurderer = nil,
}

 
local lastNotify = { text = nil, at = 0 }
local function Notify(title, msg, dur)
    if not config.notifications then return end
    local text = msg and (title .. ": " .. msg) or title
    local t = now()
    if lastNotify.text == text and (t - lastNotify.at) < 0.35 then return end
    lastNotify.text, lastNotify.at = text, t
    hostNotify(text, dur or 3)
end

 
local LEGACY_TITLES = {
    ["⚡ Quick Actions"] = true,
    ["🤖 Automation"] = true,
    ["📋 Lists Management"] = true,
    ["⚙️ Reset Settings"] = true,
    ["⚙ Reset Settings"] = true,
    ["🔄 Bind Buttons (circles)"] = true,
    ["📊 Status"] = true,
    ["ℹ️ Info"] = true,
    ["⚡ Reset"] = true,
    ["🤖 Auto"] = true,
    ["📋 Lists"] = true,
    ["⚙️ Tuning"] = true,
    ["⚙ Tuning"] = true,
    ["🔘 Binds"] = true,
    ["ℹ️"] = true,
    ["Ultimate Fling V1"] = true,
    ["Ultimate Fling"] = true,
}
local EXTRA_LEGACY_TITLES = {}
for _title in pairs(EXTRA_LEGACY_TITLES) do LEGACY_TITLES[_title] = true end
local CUR_TITLES = {
    ["💀 " .. BRAND] = true,
    ["⚡ Fling"] = true,
    ["🤖 Auto"] = true,
    ["📋 Lists"] = true,
    ["⚙️ Tuning"] = true,
    ["⚙ Tuning"] = true,
    ["🔘 Binds"] = true,
    ["🔑 Keys"] = true,
    ["💾 Config"] = true,
    ["ℹ️"] = true,
}
local HOST_WORDS = {
    "Looking for a feature", "Plugins", "Overdrive", "Logged in as", "gg/overdrivehub",
}
local MAX_CARD_HEIGHT = 520

local RUN_ID = MARKER_PREFIX .. tostring(floor(now() * 1000) % 100000000)
    .. "_" .. tostring(math.random(1000, 9999))

 
local storageGui = nil
local function getStorage()
    if storageGui and storageGui.Parent then return storageGui end

    local parent
    local ok, res = pcall(function()
        if gethui then return gethui() end
        if getcore then return getcore() end
        return nil
    end)
    if ok and typeof(res) == "Instance" then parent = res else parent = CoreGui end
    if typeof(parent) ~= "Instance" then parent = LocalPlayer:FindFirstChildOfClass("PlayerGui") end
    if typeof(parent) ~= "Instance" then parent = LocalPlayer:WaitForChild("PlayerGui", 5) end
    if typeof(parent) ~= "Instance" then parent = CoreGui end

    pcall(function()
        for _, legacyName in ipairs(LEGACY_STORAGES) do
            local legacy = parent:FindFirstChild(legacyName)
            if legacy then legacy:Destroy() end
        end
    end)

    local sg = parent:FindFirstChild(STORAGE_NAME)
    if not sg then
        sg = new("ScreenGui")
        sg.Name = STORAGE_NAME
        sg.ResetOnSpawn = false
        sg.IgnoreGuiInset = true
        pcall(function() sg.ScreenInsets = Enum.ScreenInsets.None end)
        if syn and syn.protect_gui then pcall(syn.protect_gui, sg) end
        sg.Parent = parent
    end
    storageGui = sg
    return sg
end

 
local mySections = {}
local headlessMode = false

local function stubSection()
    return setmetatable({}, { __index = function() return function() end end })
end

local function protectSection(sec)
    if typeof(sec) ~= "table" then return stubSection() end
    local proxy = { _raw = sec }
    return setmetatable(proxy, {
        __index = function(p, key)
            local raw = p._raw
            local value = raw[key]
            if type(value) == "function" then
                return function(first, ...)
                    local ok, err
                    if first == p then
                        ok, err = pcall(value, raw, ...)
                    else
                        ok, err = pcall(value, raw, first, ...)
                    end
                    if not ok then warn("[" .. BRAND .. "][menu] " .. tostring(key) .. ": " .. tostring(err)) end
                    return ok and err or nil
                end
            end
            return value
        end,
    })
end

local function AddSection(name)
    local ok, sec = pcall(function() return shared.AddSection(name) end)
    local obj
    if ok and sec then
        obj = protectSection(sec)
    else
        headlessMode = true
        obj = stubSection()
    end
    insert(mySections, { name = name, obj = obj })
    return obj
end

 
local function guiRoots()
    local roots, seen = {}, {}
    local function add(r)
        if typeof(r) == "Instance" and not seen[r] then
            seen[r] = true
            roots[#roots + 1] = r
        end
    end
    pcall(function() add(gethui and gethui()) end)
    pcall(function() add(getcore and getcore()) end)
    add(CoreGui)
    pcall(function() add(LocalPlayer:FindFirstChildOfClass("PlayerGui")) end)
    return roots
end

local function hasHostWords(node, memo)
    local cached = memo[node]
    if cached ~= nil then return cached end
    local res = false
    local descendants = node:GetDescendants()
    for i = 1, #descendants do
        local d = descendants[i]
        if d:IsA("TextLabel") then
            local txt = d.Text
            for w = 1, #HOST_WORDS do
                if txt:find(HOST_WORDS[w], 1, true) then
                    res = true
                    break
                end
            end
            if res then break end
        end
    end
    memo[node] = res
    return res
end

local function findCard(node, memo)
    for _ = 1, 7 do
        if not node or typeof(node) ~= "Instance" or node == game then return nil end
        if node:IsA("Frame") or node:IsA("ScrollingFrame") then
            local framed = node:FindFirstChildOfClass("UIStroke") or node:FindFirstChildOfClass("UICorner")
            if framed then
                local sz = node.AbsoluteSize
                if sz.Y > 0 and sz.Y < MAX_CARD_HEIGHT and not hasHostWords(node, memo) then
                    return node
                end
            end
        end
        node = node.Parent
    end
    return nil
end

local function markerOf(card)
    if not card then return nil end
    local descendants = card:GetDescendants()
    for i = 1, #descendants do
        local d = descendants[i]
        if d.Name:sub(1, #MARKER_PREFIX) == MARKER_PREFIX then return d.Name end
    end
    return nil
end

local function attachMarker(card)
    if not card or markerOf(card) then return false end
    local ok = pcall(function()
        local sv = new("StringValue")
        sv.Name = RUN_ID
        sv.Value = VERSION
        sv.Parent = card
    end)
    return ok
end

local lastPurge = 0
local PURGE_COOLDOWN = 0.5

local function cardIsOurs(card)
    if markerOf(card) == RUN_ID then return true end
    local descendants = card:GetDescendants()
    for i = 1, #descendants do
        local d = descendants[i]
        if d:IsA("TextLabel") and d.Text:find(VERSION_TAG, 1, true) then return true end
    end
    return false
end

local function purgeForeign(force)
    local t = now()
    if not force and (t - lastPurge) < PURGE_COOLDOWN then return 0 end
    lastPurge = t
    local killed = 0
    for _, root in ipairs(guiRoots()) do
        local memo = {}
        local descendants = root:GetDescendants()
        for i = 1, #descendants do
            local d = descendants[i]
            if d.Parent and d:IsA("TextLabel") then
                local txt = d.Text
                if CUR_TITLES[txt] or (CLEAN_LEGACY_MENU and LEGACY_TITLES[txt]) then
                    local card = findCard(d, memo)
                    if card and not cardIsOurs(card) then
                        if pcall(function() card:Destroy() end) then killed = killed + 1 end
                    end
                end
            end
        end
    end
    return killed
end

local markedCount = 0
local function markOwnCards()
    local marked = 0
    for _, root in ipairs(guiRoots()) do
        local memo = {}
        local descendants = root:GetDescendants()
        for i = 1, #descendants do
            local d = descendants[i]
            if d.Parent and d:IsA("TextLabel") and CUR_TITLES[d.Text] then
                local card = findCard(d, memo)
                if card and markerOf(card) == nil and attachMarker(card) then
                    marked = marked + 1
                end
            end
        end
    end
    markedCount = markedCount + marked
    return marked
end

local function removeByTitles()
    local removed = 0
    for _, root in ipairs(guiRoots()) do
        local memo = {}
        local descendants = root:GetDescendants()
        for i = 1, #descendants do
            local d = descendants[i]
            if d.Parent and d:IsA("TextLabel") and CUR_TITLES[d.Text] then
                local card = findCard(d, memo)
                if card and not markerOf(card) then
                    if pcall(function() card:Destroy() end) then removed = removed + 1 end
                end
            end
        end
    end
    return removed
end

local function removeMySections()
    local removed = 0
    for _, root in ipairs(guiRoots()) do
        local descendants = root:GetDescendants()
        for i = 1, #descendants do
            local d = descendants[i]
            if d.Name == RUN_ID and d.Parent then
                local card = d.Parent
                pcall(function() d:Destroy() end)
                if pcall(function() card:Destroy() end) then removed = removed + 1 end
            end
        end
    end
    if removed == 0 and markedCount == 0 then removed = removeByTitles() end
    return removed
end

pcall(purgeForeign, true)

 
local Audio = { click = nil }
function Audio.init()
    local s = new("Sound")
    s.Name = "@click"
    s.SoundId = "rbxassetid://3868133279"
    s.Volume = config.muteSounds and 0 or 0.5
    s.Parent = getStorage()
    Audio.click = s
    RootMaid:GiveTask(s)
end
function Audio.play()
    local s = Audio.click
    if not s or s.Volume <= 0 then return end
    pcall(function() s:Play() end)
end
function Audio.setMuted(muted)
    config.muteSounds = muted and true or false
    if Audio.click then Audio.click.Volume = config.muteSounds and 0 or 0.5 end
    saveConfig()
end

 
local BindableButtons = {
    Buttons = {},
    Maids   = {},
    recs    = {},
    order   = {},
    Count   = 0,
    ResetActive = false,
    CurrentSize = clamp(config.bindButtonSize or 0.085, 0.05, 0.25),
}

local __SHAPES = {
    [0] = "rbxassetid://86221076925479",
    [1] = "rbxassetid://96242665417546",
    [2] = "rbxassetid://97129189935336",
    [3] = "rbxassetid://76165862027868",
    [4] = "rbxassetid://125868092127496",
}
local GLOW_IMG = "rbxassetid://131961136"

local __NORMAL_COLOR = cs({
    csk(0,    rgb(35, 35, 40)),
    csk(0.22, rgb(250, 250, 252)),
    csk(0.48, rgb(70, 70, 78)),
    csk(0.72, rgb(255, 255, 255)),
    csk(1,    rgb(45, 45, 52)),
})
local __WAIT_COLOR = cs({
    csk(0, rgb(24,26,31)), csk(.25, rgb(150,154,162)), csk(.52, rgb(58,61,69)),
    csk(.78, rgb(188,191,198)), csk(1, rgb(25,27,32)),
})
local __GOLD_NORMAL_COLOR = __NORMAL_COLOR
local __GOLD_WAIT_COLOR = __WAIT_COLOR

local function bind_safecallback(callback)
    if not callback then return end
    local ok, err = xpcall(callback, debug.traceback)
    if not ok then warn("[" .. BRAND .. "][bind] " .. tostring(err)) end
end

function BindableButtons.relayout()
    local camera = Workspace.CurrentCamera
    local screen = (camera and camera.ViewportSize) or FALLBACK_VIEWPORT
    if not screen or screen.X <= 1 or screen.Y <= 1 then
        screen = FALLBACK_VIEWPORT
    end
    local h = BindableButtons.CurrentSize or 0.085
    local w = h * (screen.Y / screen.X)
    if w ~= w or w <= 0 or w > 1 then w = h * (FALLBACK_VIEWPORT.Y / FALLBACK_VIEWPORT.X) end
    local perRow = math.max(1, floor(0.84 / (w + 0.008)))
    for i = 1, #BindableButtons.order do
        local id = BindableButtons.order[i]
        local rec = BindableButtons.recs[id]
        if rec then
            local saved = config.bindPositions[id]
            if saved and type(saved.x) == "number" and type(saved.y) == "number" then
                rec.x, rec.y = saved.x, saved.y
            else
                local row = floor((i - 1) / perRow)
                local col = (i - 1) % perRow
                rec.x = 0.08 + col * (w + 0.008)
                rec.y = 0.88 - row * (h + 0.02)
            end
            rec.btn.Position = ud2(rec.x, 0, rec.y, 0)
        end
    end
end

function BindableButtons.setSize(sizeScale)
    BindableButtons.CurrentSize = clamp(sizeScale or 0.085, 0.05, 0.25)
    config.bindButtonSize = BindableButtons.CurrentSize
    BindableButtons.relayout()
    saveConfig()
end
function BindableButtons.setResetActive(enabled)
    BindableButtons.ResetActive = enabled == true
    local color = BindableButtons.ResetActive and __WAIT_COLOR or __NORMAL_COLOR
    for _, rec in pairs(BindableButtons.recs) do
        if rec.stroke then rec.stroke.Color = color end
    end
end

local dragState = nil
local binderGlobalMaid = Maid.new()
RootMaid:GiveTask(binderGlobalMaid)

local function isDragInput(input)
    if not dragState then return false end
    if input == dragState.dragInput then return true end
    if input == dragState.input then return true end
    return false
end

binderGlobalMaid:GiveTask(UserInputService.InputChanged:Connect(function(input)
    if not dragState then return end
    if input.UserInputType ~= MOUSEMOV and input.UserInputType ~= TOUCH then return end
    if not isDragInput(input) then return end
    local rec = dragState.rec
    if not rec or not rec.btn then return end
    local delta = input.Position - dragState.startInput
    if delta.Magnitude > 7 then dragState.moved = true end
    local parentGui = rec.btn.Parent
    if not parentGui then return end
    local screen = parentGui.AbsoluteSize
    if screen.X <= 0 or screen.Y <= 0 then return end
    rec.x = clamp(dragState.startX + (delta.X / screen.X), 0.03, 0.97)
    rec.y = clamp(dragState.startY + (delta.Y / screen.Y), 0.05, 0.95)
    rec.btn.Position = ud2(rec.x, 0, rec.y, 0)
end))

binderGlobalMaid:GiveTask(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType ~= MOUSE1 and input.UserInputType ~= TOUCH then return end
    for _, rec in pairs(BindableButtons.recs) do
        if rec.targetPress ~= 0 then
            rec.targetPress = 0
            if rec.updateScale then rec.updateScale() end
        end
    end
    if not dragState then return end
    local mine = (input == dragState.input)
        or (input == dragState.dragInput)
        or (dragState.isMouse and input.UserInputType == MOUSE1)
    if not mine then return end
    local rec, moved = dragState.rec, dragState.moved
    dragState = nil
    if not rec then return end
    if not moved then
        Audio.play()
        bind_safecallback(rec.onClick)
    else
        config.bindPositions[rec.id] = { x = rec.x, y = rec.y }
        saveConfig(true)
    end
end))


function BindableButtons.AddBButton(id, text, clickFunc, isGold)
    if BindableButtons.Buttons[id] then return BindableButtons.Buttons[id] end

    local buttonMaid = Maid.new()
    local storage = getStorage()
    local camera = Workspace.CurrentCamera
    local screen = (camera and camera.ViewportSize) or FALLBACK_VIEWPORT
    local h0 = BindableButtons.CurrentSize or 0.085
    local w0 = h0 * (screen.Y / screen.X)

     
    local ImageButton = new("ImageButton")
    ImageButton.Name = id
     
    local diameter = h0 * screen.Y
    ImageButton.Size = ud2(0, diameter, 0, diameter)
    ImageButton.AnchorPoint = v2(0.5, 0.5)
    ImageButton.Image = ""
    ImageButton.BackgroundColor3 = rgb(8, 8, 10)
    ImageButton.BackgroundTransparency = 0.42
    ImageButton.BorderSizePixel = 0
    ImageButton.ClipsDescendants = false
    ImageButton.AutoButtonColor = false
    ImageButton.ZIndex = 2
    ImageButton.Parent = storage
    buttonMaid:GiveTask(ImageButton)
    new("UICorner", ImageButton).CornerRadius = ud(1, 0)
    local Aspect = new("UIAspectRatioConstraint", ImageButton)
    Aspect.AspectRatio = 1
    pcall(function() Aspect.AspectType = Enum.AspectType.ScaleWithParentSize end)

    local outerStroke = new("UIStroke", ImageButton)
    outerStroke.Color = rgb(255, 255, 255)
    outerStroke.Thickness = 2
    outerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    local Stroke = new("UIGradient", outerStroke)
    Stroke.Name = "@Stroke"
    Stroke.Color = BindableButtons.ResetActive and __WAIT_COLOR or __NORMAL_COLOR
    local innerStroke = new("UIStroke", ImageButton)
    innerStroke.Color = rgb(105, 105, 112)
    innerStroke.Transparency = 0.5
    innerStroke.Thickness = 1
    innerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    local innerGradient = Stroke:Clone()
    innerGradient.Name = "@InnerStroke"
    innerGradient.Rotation = 180
    innerGradient.Parent = innerStroke

    pcall(function() __NOIR_GUARD.blackhole.StyleFloat(ImageButton, nil, true) end)
    pcall(function() __NOIR_GUARD.floatIcon(ImageButton, text) end)
    local TextLabel = new("TextLabel", ImageButton)
    TextLabel.Name = "@Text"
    TextLabel.Size = ud2(0.92, 0, 0.22, 0)
    TextLabel.Position = ud2(0.5, 0, 0.82, 0)
    TextLabel.AnchorPoint = v2(0.5, 0.5)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Font = Enum.Font.GothamBold
    TextLabel.Text = text
    TextLabel.TextColor3 = pclr(1, 1, 1)
    TextLabel.TextSize = 12
    TextLabel.TextScaled = true
    TextLabel.TextWrapped = true
    TextLabel.ZIndex = 12
    local labelLimit = new("UITextSizeConstraint", TextLabel)
    labelLimit.MinTextSize = 8
    labelLimit.MaxTextSize = 13

    local ripple = new("Frame")
    ripple.Name = "@ripple"
    ripple.BackgroundColor3 = rgb(226, 230, 238)
    ripple.BackgroundTransparency = 0.45
    ripple.Size = ud2(0, 0, 0, 0)
    ripple.AnchorPoint = v2(0.5, 0.5)
    ripple.Visible = false
    ripple.ZIndex = 2
    ripple.Parent = ImageButton
    new("UICorner", ripple).CornerRadius = ud(1, 0)

    local buttonScale = new("UIScale", ImageButton)
    buttonScale.Scale = 1
    buttonMaid:GiveTask(buttonScale)
    local rec = {
        id = id, btn = ImageButton, stroke = Stroke, ripple = ripple, scale = buttonScale,
        onClick = clickFunc, isGold = isGold and true or false,
        targetHover = 0, targetPress = 0,
        x = 0.08, y = 0.88,
    }
    local function updateButtonScale()
        local target = rec.targetPress > 0 and .94 or (rec.targetHover > 0 and 1.055 or 1)
        TweenService:Create(buttonScale, tinfo(.15, EASING.Quart, EDIR.Out), { Scale = target }):Play()
    end
    rec.updateScale = updateButtonScale

    buttonMaid:GiveTask(ImageButton.InputBegan:Connect(function(input)
        if input.UserInputType ~= MOUSE1 and input.UserInputType ~= TOUCH then return end
        rec.targetPress = 1
        updateButtonScale()
        dragState = {
            rec = rec,
            input = input,
            dragInput = nil,
            isMouse = input.UserInputType == MOUSE1,
            startInput = input.Position,
            startX = rec.x, startY = rec.y,
            moved = false,
        }
        local absPos = ImageButton.AbsolutePosition
        ripple.Position = ud2(0, input.Position.X - absPos.X, 0, input.Position.Y - absPos.Y)
        ripple.Size = ud2(0, 0, 0, 0)
        ripple.BackgroundTransparency = 0.45
        ripple.Visible = true
        TweenService:Create(ripple, tinfo(.24, EASING.Sine, EDIR.Out), {
            Size = ud2(0, 45, 0, 45), BackgroundTransparency = 1,
        }):Play()
    end))

    buttonMaid:GiveTask(ImageButton.InputChanged:Connect(function(input)
        if input.UserInputType ~= MOUSEMOV and input.UserInputType ~= TOUCH then return end
        if dragState and dragState.rec == rec then dragState.dragInput = input end
    end))
    buttonMaid:GiveTask(ImageButton.MouseEnter:Connect(function()
        rec.targetHover = 1
        updateButtonScale()
    end))
    buttonMaid:GiveTask(ImageButton.MouseLeave:Connect(function()
        rec.targetHover = 0
        updateButtonScale()
    end))

    BindableButtons.Buttons[id] = ImageButton
    BindableButtons.Maids[id] = buttonMaid
    BindableButtons.recs[id] = rec
    insert(BindableButtons.order, id)
    BindableButtons.Count = #BindableButtons.order
    BindableButtons.relayout()
    return ImageButton
end

function BindableButtons.DeleteBButton(id)
    local maid = BindableButtons.Maids[id]
    if maid then maid:Destroy() end
    BindableButtons.Maids[id] = nil
    BindableButtons.Buttons[id] = nil
    BindableButtons.recs[id] = nil
    for i = 1, #BindableButtons.order do
        if BindableButtons.order[i] == id then
            table.remove(BindableButtons.order, i)
            break
        end
    end
    BindableButtons.Count = #BindableButtons.order
    if dragState and dragState.rec and dragState.rec.id == id then dragState = nil end
    BindableButtons.relayout()
end

function BindableButtons.UpdateBButtonText(id, text, isWaiting, isGold)
    local btn = BindableButtons.Buttons[id]
    if not btn then return end
    local textLabel = btn:FindFirstChild("@Text")
    if textLabel then textLabel.Text = text end
    local stroke = btn:FindFirstChild("@Stroke", true)
    if stroke then
        if isGold then
            stroke.Color = isWaiting and __GOLD_WAIT_COLOR or __GOLD_NORMAL_COLOR
        else
            stroke.Color = isWaiting and __WAIT_COLOR or __NORMAL_COLOR
        end
    end
end

function BindableButtons.resetLayout()
    clearTable(config.bindPositions)
    saveConfig()
    BindableButtons.relayout()
end

function BindableButtons.clearAll()
    local ids = {}
    for id in pairs(BindableButtons.Buttons) do insert(ids, id) end
    for _, id in ipairs(ids) do BindableButtons.DeleteBButton(id) end
end

 
 
local StatusHUD = { Set = function() end }
local function hudApplyPosition() end

 
local function isValidTarget(player)
    if not player or player == LocalPlayer or not player.Parent then return false end
    if state.whitelist[player.UserId] then return false end
    local char = player.Character
    if not char then return false end
    if not char:FindFirstChild("HumanoidRootPart") then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then return false end
    return true
end

local function getSelectedOrFirst()
    if isValidTarget(state.resetSelPlr) then return state.resetSelPlr end
    for _, player in ipairs(state.selectedPlayers) do
        if isValidTarget(player) then return player end
    end
    return nil
end

local function findNearest()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local best, bestDist = nil, math.huge
    local players = Players:GetPlayers()
    for i = 1, #players do
        local player = players[i]
        if isValidTarget(player) then
            local tr = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if tr then
                local d = (root.Position - tr.Position).Magnitude
                if d < bestDist then best, bestDist = player, d end
            end
        end
    end
    return best
end

 
local roleRemote = nil
local roleRemoteTried = -1e9
local function getRoleRemote()
    if roleRemote and roleRemote.Parent then return roleRemote end
    local t = now()
    if (t - roleRemoteTried) < 5 then return roleRemote end
    roleRemoteTried = t
    pcall(function()
        local remote = ReplicatedStorage:FindFirstChild("GetPlayerData", true)
        if remote and remote:IsA("RemoteFunction") then roleRemote = remote end
    end)
    return roleRemote
end

local roleCache = { data = nil, timestamp = 0 }
local function getCachedRoleData()
    local t = now()
    local ttl = config.roleCacheTTL or 0.8
    if roleCache.data and (t - roleCache.timestamp) < ttl then return roleCache.data end
    local remote = getRoleRemote()
    if remote then
        local ok, result = pcall(function() return remote:InvokeServer() end)
        if ok and type(result) == "table" then
            roleCache.data, roleCache.timestamp = result, t
            return result
        end
    end
    roleCache.timestamp = t
    return roleCache.data
end

local function invalidateRoleCache()
    roleCache.data = nil
    roleCache.timestamp = 0
end

local function hasGunModel(char)
    if not char then return false end
    if char:FindFirstChild("Gun") or char:FindFirstChild("Revolver") then return true end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        local name = tool.Name:lower()
        if name:find("gun", 1, true) or name:find("revolver", 1, true) then return true end
    end
    return false
end

local function quickScanSheriff()
    local players = Players:GetPlayers()
    for i = 1, #players do
        local player = players[i]
        if player ~= LocalPlayer and not state.whitelist[player.UserId] then
            if hasGunModel(player.Character) then return player end
            local bp = player:FindFirstChild("Backpack")
            if bp and (bp:FindFirstChild("Gun") or bp:FindFirstChild("Revolver")) then
                return player
            end
        end
    end
    return nil
end

local function findTargetByRole(roleName)
    local roleData = getCachedRoleData()
    if not roleData then return nil end
    for playerName, data in pairs(roleData) do
        if type(data) == "table" and data.Role == roleName and not data.Killed and not data.Dead then
            local p = Players:FindFirstChild(playerName)
            if p and p ~= LocalPlayer and not state.whitelist[p.UserId] then return p end
        end
    end
    return nil
end

local sheriffCache = { player = nil, at = 0 }
local function findSheriff()
    local t = now()
    if sheriffCache.player and (t - sheriffCache.at) < 0.35 and isValidTarget(sheriffCache.player) then
        return sheriffCache.player
    end
    local found = quickScanSheriff()
    if not found then found = findTargetByRole("Sheriff") end
    sheriffCache.player, sheriffCache.at = (isValidTarget(found) and found or nil), t
    return sheriffCache.player
end

local function findMurderer()
    local byRole = findTargetByRole("Murderer")
    if byRole then return byRole end
    local players = Players:GetPlayers()
    for i = 1, #players do
        local player = players[i]
        if player ~= LocalPlayer and not state.whitelist[player.UserId] then
            local char = player.Character
            if char then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    local name = tool.Name:lower()
                    if name:find("knife", 1, true) or name:find("murderer", 1, true) then
                        return player
                    end
                end
            end
        end
    end
    return nil
end

 
local flingBV = nil
local flingOldPos = nil
local flingFPDH = nil
pcall(function() flingFPDH = Workspace.FallenPartsDestroyHeight end)
if type(flingFPDH) ~= "number" or flingFPDH ~= flingFPDH then flingFPDH = -500 end
pcall(function() if getgenv then getgenv().FPDH = flingFPDH end end)

local currentFling = nil
local massFlingThread = nil

local function CleanupFlingPhysics()
    if flingBV then pcall(function() flingBV:Destroy() end) flingBV=nil end
    pcall(function() Workspace.FallenPartsDestroyHeight = flingFPDH end)
    pcall(function() if getgenv and getgenv().FPDH then Workspace.FallenPartsDestroyHeight=getgenv().FPDH end end)
    local char = LocalPlayer and LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true) end) end
    if hum and hum.RootPart then
        pcall(function() Workspace.CurrentCamera.CameraSubject = hum end)
    end
end

local function cancelCurrentFling()
    if massFlingThread then pcall(task.cancel, massFlingThread); massFlingThread=nil end
    if currentFling and currentFling.cancel then pcall(currentFling.cancel) end
    currentFling=nil
    CleanupFlingPhysics()
    BindableButtons.setResetActive(false)
    StatusHUD.Set("idle")
end

 
local function SkidFling(TargetPlayer)
    if not TargetPlayer or not TargetPlayer.Parent then return false end
    if TargetPlayer == LocalPlayer or state.whitelist[TargetPlayer.UserId] then return false end

    local last = state.lastResetAt[TargetPlayer.UserId]
    if last and (now()-last) < (config.targetCooldown or 0) then return false end
    state.lastResetAt[TargetPlayer.UserId]=now()

    cancelCurrentFling()

    local Character = LocalPlayer and LocalPlayer.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart
    local TCharacter = TargetPlayer.Character
    local THumanoid = TCharacter and TCharacter:FindFirstChildOfClass("Humanoid")
    local TRootPart = THumanoid and THumanoid.RootPart or nil
    local THead = TCharacter and TCharacter:FindFirstChild("Head")
    local Accessory = TCharacter and TCharacter:FindFirstChildOfClass("Accessory")
    local Handle = Accessory and Accessory:FindFirstChild("Handle") or nil

    if not (Character and Humanoid and RootPart and TCharacter) then return false end
    if not TCharacter:FindFirstChildWhichIsA("BasePart") then return false end

    if RootPart.Velocity.Magnitude < 50 then
        flingOldPos = RootPart.CFrame
        pcall(function() if getgenv then getgenv().OldPos = flingOldPos end end)
    end
    if THumanoid and THumanoid.Sit then
        Notify("Fling", TargetPlayer.Name.." is sitting",2)
        return false
    end

    if THead then pcall(function() Workspace.CurrentCamera.CameraSubject = THead end)
    elseif Handle then pcall(function() Workspace.CurrentCamera.CameraSubject = Handle end)
    elseif THumanoid and TRootPart then pcall(function() Workspace.CurrentCamera.CameraSubject = THumanoid end) end

    local power = config.flingPower or 1
    local velMult = power==1 and 1 or (power==2 and 1.5 or 2)
    local rotMult = velMult
    local duration = tonumber(config.flingDuration) or 2
    if duration < 0.5 then duration = 0.5 end
    local predStuds = tonumber(config.predictionStuds) or 8
    local startStuds = tonumber(config.startStuds) or 5
    local downForce = 50000 * velMult

    Humanoid.PlatformStand = true
    local savedDestroy = Workspace.FallenPartsDestroyHeight
    if type(savedDestroy) ~= "number" or savedDestroy ~= savedDestroy then savedDestroy = -500 end
    Workspace.FallenPartsDestroyHeight = 0/0  

    if flingBV and flingBV.Parent then pcall(function() flingBV:Destroy() end) end
    flingBV = new("BodyVelocity")
    flingBV.Name = "FlingVel"
    flingBV.Velocity = v3(0, -downForce, 0)
    flingBV.MaxForce = v3(math.huge, math.huge, math.huge)
    flingBV.Parent = RootPart
    local flingBG = new("BodyGyro")
    flingBG.MaxTorque = v3(math.huge, math.huge, math.huge)
    flingBG.P = 1000000
    flingBG.D = 500
    flingBG.CFrame = RootPart.CFrame
    flingBG.Parent = RootPart
    pcall(function() Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false) end)

    local startTime = now()
    local done=false
    local flingObj={ bv=flingBV, conn=nil, watchdog=nil }

    local function cleanup(success, manual)
        if done then return end
        done=true
        if currentFling==flingObj then currentFling=nil end
        if flingObj.conn then pcall(function() flingObj.conn:Disconnect() end) end
        if flingObj.watchdog then pcall(task.cancel, flingObj.watchdog) end
        if flingBV then pcall(function() flingBV:Destroy() end) flingBV=nil end
        if flingBG then pcall(function() flingBG:Destroy() end) flingBG=nil end
        local function snapHome()
            if not (RootPart and RootPart.Parent and flingOldPos) then return end
            RootPart.AssemblyLinearVelocity = V3_ZERO
            RootPart.AssemblyAngularVelocity = V3_ZERO
            RootPart.Velocity = V3_ZERO
            RootPart.RotVelocity = V3_ZERO
            RootPart.CFrame = flingOldPos * cfr(0, 0.5, 0)
            pcall(function() Character:SetPrimaryPartCFrame(flingOldPos * cfr(0, 0.5, 0)) end)
            pcall(function() Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        end
        snapHome()
        pcall(function() Humanoid.PlatformStand = false end)
        pcall(function() Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true) end)
        pcall(function() Workspace.CurrentCamera.CameraSubject = Humanoid end)
         
        local tries=0
        repeat
            snapHome()
            task.wait()
            tries=tries+1
            if tries>15 then break end
            if not RootPart or not RootPart.Parent or not flingOldPos then break end
        until (RootPart.Position - flingOldPos.Position).Magnitude < 20
        snapHome()
        pcall(function()
            local h = flingFPDH
            if type(h) ~= "number" or h ~= h then h = -500 end
            Workspace.FallenPartsDestroyHeight = h
        end)
        BindableButtons.setResetActive(false)
        StatusHUD.Set("idle")
    end
    flingObj.cancel=function() cleanup(true,true) end
    currentFling=flingObj
    BindableButtons.setResetActive(true)
    StatusHUD.Set("active", TargetPlayer.Name)
    flingObj.watchdog = task.delay(duration + 2, function() if not done then cleanup(false) end end)

    flingObj.conn = RunService.Heartbeat:Connect(function()
        if done then return end
        local elapsed = now() - startTime
        local liveChar = TargetPlayer.Character
        if elapsed > duration or not Character.Parent or not RootPart.Parent
            or not liveChar or liveChar ~= TCharacter then
            cleanup(true)
            return
        end
        local liveHum = liveChar:FindFirstChildOfClass("Humanoid")
        local liveRoot = liveChar:FindFirstChild("HumanoidRootPart") or TRootPart
        local liveHead = liveChar:FindFirstChild("Head")
        if not (liveRoot and liveRoot.Parent) then cleanup(true) return end

        local vel = liveRoot.AssemblyLinearVelocity
        local horiz = v3(vel.X, 0, vel.Z)
        local speed = horiz.Magnitude
        local ping = 0.08
        pcall(function()
            local p = LocalPlayer:GetNetworkPing()
            if type(p)=="number" and p==p then ping = math.max(p, 0.05) end
        end)
         
        local center = liveRoot.Position + horiz * (ping * 2 + 0.08)
        if liveHum then
            local md = liveHum.MoveDirection
            if md.Magnitude > 0.1 then
                center = center + md * ((liveHum.WalkSpeed or 16) * ping)
            end
        end

        local pass = 0.28
        local passN = math.floor(elapsed / pass)
        local dir
        if speed > 2 then
            dir = horiz.Unit
        elseif liveHum and liveHum.MoveDirection.Magnitude > 0.1 then
            dir = liveHum.MoveDirection.Unit
        else
            local yaw = passN * 1.047
            dir = v3(math.cos(yaw), 0, math.sin(yaw))
        end
        local t = (elapsed % pass) / pass
        local headY = (liveHead and liveHead.Parent) and liveHead.Position.Y or (center.Y + 1.5)
         
        local extent = (speed > 6) and 0.9 or 1.35
        local from = center + dir * extent + v3(0, (headY - center.Y) + startStuds, 0)
        local to = center - dir * extent + v3(0, -3, 0)
        local pos = from:Lerp(to, t)
         
        if speed > 4 then
            local stick = 0.55
            pos = v3(
                pos.X * (1 - stick) + center.X * stick,
                pos.Y,
                pos.Z * (1 - stick) + center.Z * stick
            )
        end
        local spin = elapsed * 90
        local cf = cfr(pos) * CFrame.Angles(math.pi / 2, spin, 0)
        RootPart.CFrame = cf
        pcall(function() Character:SetPrimaryPartCFrame(cf) end)
        RootPart.AssemblyLinearVelocity = v3(0, -downForce, 0)
        RootPart.AssemblyAngularVelocity = v3(7500 * velMult, 7500 * velMult, 7500 * velMult)
        local toT = center - RootPart.Position
        if flingBV then
            if toT.Magnitude > 0.05 then flingBV.Velocity = toT.Unit * downForce
            else flingBV.Velocity = v3(0, -downForce, 0) end
        end
        if flingBG then flingBG.CFrame = cf end
    end)

    local timeout = now() + duration + 1
    while not done and now() < timeout do task.wait() end
    if not done then cleanup(true) end
    return true
end

 
local function startAutoModule(maidKey, finderFunc, intervalFn)
    if maids[maidKey] then maids[maidKey]:Destroy(); maids[maidKey]=nil end
    local maid=Maid.new()
    maids[maidKey]=maid
    local thread=task.spawn(function()
        while not maid._destroyed do
            local target=nil
            pcall(function() target=finderFunc() if target then SkidFling(target) end end)
            local base=intervalFn()
            if target then task.wait(math.max(base, (config.flingDuration or 2)+0.08))
            else task.wait(base) end
        end
    end)
    maid:GiveTask(thread)
    return maid
end

local function stopAutoModule(maidKey)
    if maids[maidKey] then maids[maidKey]:Destroy(); maids[maidKey]=nil; cancelCurrentFling() end
end

 
local touchFlingOn = false
local function zeroTouchFlingSelf()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    pcall(function()
        hrp.Velocity = Vector3.zero
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end)
end
local function setTouchFling(enabled)
    enabled = enabled == true
    if maids.touchFling then maids.touchFling:Destroy(); maids.touchFling = nil end
    if not enabled then
        zeroTouchFlingSelf()
        touchFlingOn = false
        return
    end
    touchFlingOn = true
    maids.touchFling = Maid.new()
    local hidden = true
    maids.touchFling:GiveTask(function() hidden = false; zeroTouchFlingSelf() end)
    local movel = 0.1
    task.spawn(function()
        while hidden do
            RunService.Heartbeat:Wait()
            if not hidden then break end
            if currentFling then continue end
            local c = LocalPlayer.Character
            local hrp = c and c:FindFirstChild("HumanoidRootPart")
            if not (c and c.Parent and hrp and hrp.Parent) then continue end
            local dest = workspace.FallenPartsDestroyHeight
            if typeof(dest) == "number" and hrp.Position.Y < dest + 50 then zeroTouchFlingSelf(); continue end
            local saved = hrp.CFrame
            local vel = hrp.Velocity
            pcall(function() hrp.CanCollide = true end)
            hrp.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)
            RunService.RenderStepped:Wait()
            if not hidden or not hrp.Parent then break end
            hrp.Velocity = vel
            RunService.Stepped:Wait()
            if not hidden or not hrp.Parent then break end
            hrp.Velocity = vel + Vector3.new(0, movel, 0)
            movel = -movel
            if typeof(dest) == "number" and hrp.Position.Y < dest + 50 then
                hrp.CFrame = saved
                zeroTouchFlingSelf()
            end
        end
        zeroTouchFlingSelf()
    end)
end
local function toggleTouchFling()
    setTouchFling(not touchFlingOn)
    Notify("Touch Fling", touchFlingOn and "ON — walk into players" or "OFF", 2)
    pcall(function() ODHX.Set("⚡ Fling", "Touch Fling", "Toggle", touchFlingOn, false) end)
    local btn = BindableButtons.Buttons and BindableButtons.Buttons["bind_touchFling"]
    local lab = btn and btn:FindFirstChild("@Text")
    if lab then lab.Text = touchFlingOn and "TF ON" or "TF" end
end

local ACTIONS={}

ACTIONS.sheriff={
    name="Sheriff", short="Sh", label="🔫 Sheriff",
    run=function()
        local t=findSheriff()
        if t then SkidFling(t) else Notify("Fling","Sheriff not found",3) end
    end,
}
ACTIONS.murderer={
    name="Murderer", short="Mur", label="🔪 Murderer",
    run=function()
        local t=findMurderer()
        if t then SkidFling(t) else Notify("Fling","Murderer not found",3) end
    end,
}
ACTIONS.selected={
    name="Selected", short="Sel", label="🎯 Selected",
    run=function()
        local t=getSelectedOrFirst()
        if t then SkidFling(t) else Notify("Fling","No valid selected player",2) end
    end,
}
ACTIONS.all={
    name="All", short="All", label="👥 Everyone",
    run=function()
        if massFlingThread then Notify("Fling","Mass fling already running",2) return end
        massFlingThread=task.spawn(function()
            local players=Players:GetPlayers()
            for i=1,#players do
                local p=players[i]
                if isValidTarget(p) then
                    SkidFling(p)
                    task.wait((config.flingDuration or 2)+0.1)
                end
            end
            massFlingThread=nil
        end)
        Notify("Fling","Flinging all...",2)
    end,
}
ACTIONS.nearest={
    name="Nearest", short="Nrst", label="📍 Nearest",
    run=function()
        local t=findNearest()
        if t then SkidFling(t) else Notify("Fling","No valid target nearby",2) end
    end,
}
ACTIONS.start={
    name="Start", short="Go", label="▶ Start",
    run=function()
        if maids.loopPlr then Notify("Fling","Loop already active - stop it first",2) return end
        local count=#state.selectedPlayers
        if count==0 and not isValidTarget(state.resetSelPlr) then Notify("Fling","No targets for loop",2) return end
        Notify("Fling","Use 🤖 Auto → Loop toggle for continuous",3)
        for _,p in ipairs(state.selectedPlayers) do if isValidTarget(p) then SkidFling(p); task.wait(0.2) end end
        if isValidTarget(state.resetSelPlr) then SkidFling(state.resetSelPlr) end
    end,
}
ACTIONS.cancel={
    name="Cancel", short="Can", label="⏹ Cancel",
    run=function() cancelCurrentFling(); Notify("Fling","Cancelled",2) end,
}
ACTIONS.touchFling={
    name="Touch Fling", short="TF", label="👋 Touch Fling",
    run=toggleTouchFling,
}

local ACTION_ORDER={"sheriff","murderer","selected","all","nearest","start","cancel","touchFling"}

local function runAction(id)
    local a=ACTIONS[id]
    if not a then return end
    local ok,err=xpcall(a.run, debug.traceback)
    if not ok then warn("["..BRAND.."][action:"..id.."] "..tostring(err)); Notify("Error","Action failed: "..id,3) end
end

 
local Keybinds={ capture=nil }
local IGNORED_KEYS={
    LeftShift=true, RightShift=true, LeftControl=true, RightControl=true,
    LeftAlt=true, RightAlt=true, LeftMeta=true, RightMeta=true,
    CapsLock=true, Unknown=true, Escape=true,
}
local function keyName(id)
    local k=config.keybinds[id]
    return (k and k~="") and k or "—"
end

RootMaid:GiveTask(UserInputService.InputBegan:Connect(function(input, processed)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local name=input.KeyCode.Name
    if Keybinds.capture then
        if IGNORED_KEYS[name] then return end
        local id=Keybinds.capture
        Keybinds.capture=nil
        config.keybinds[id]=name
        saveConfig()
        Notify("Hotkey", ACTIONS[id].name.." → "..name,3)
        return
    end
    if processed then return end
    for _,id in ipairs(ACTION_ORDER) do
        if config.keybinds[id]==name then runAction(id); break end
    end
end))

 

 
local actionSection = AddSection("⚡ Fling")
actionSection:AddButton("🔫 Sheriff", function() runAction("sheriff") end)
actionSection:AddButton("🔪 Murderer", function() runAction("murderer") end)
actionSection:AddButton("🎯 Selected", function() runAction("selected") end)
actionSection:AddButton("👥 Everyone", function() runAction("all") end)
actionSection:AddButton("📍 Nearest", function() runAction("nearest") end)
actionSection:AddButton("▶ Start (list)", function() runAction("start") end)
actionSection:AddButton("⏹ Cancel", function() runAction("cancel") end)
actionSection:AddButton("👋 Touch Fling", function() runAction("touchFling") end)
actionSection:AddPlayerDropdown("▸ Fling player", function(p)
    if p and p ~= LocalPlayer then
        state.resetSelPlr = p
        if state.whitelist[p.UserId] then Notify("Whitelist", p.Name.." is whitelisted!",3)
        else SkidFling(p); Notify("Fling","Flinging "..p.Name,2) end
    end
end)
actionSection:AddToggle("Touch Fling", setTouchFling)
actionSection:AddToggle("Bind Touch Fling", function(enabled)
    local id = "bind_touchFling"
    if enabled then
        BindableButtons.AddBButton(id, "TF", function() runAction("touchFling") end)
        Notify("Binds", "TF button on screen", 2)
    else
        BindableButtons.DeleteBButton(id)
    end
end)

 
local autoSection = AddSection("🤖 Auto")
autoSection:AddToggle("Auto Sheriff", function(enabled)
    if enabled then
        startAutoModule("autoSheriff", findSheriff, function() return config.autoSheriffDelay end)
    else
        stopAutoModule("autoSheriff")
    end
end)
autoSection:AddToggle("Auto Murderer", function(enabled)
    if enabled then
        startAutoModule("autoMurderer", findMurderer, function() return config.autoMurdererDelay end)
    else
        stopAutoModule("autoMurderer")
    end
end)
autoSection:AddToggle("Loop", function(enabled)
    if not enabled then stopAutoModule("loopPlr") return end
    local idx=1
    startAutoModule("loopPlr", function()
        if isValidTarget(state.resetSelPlr) then return state.resetSelPlr end
        local list=state.selectedPlayers
        for _=1,#list do
            idx=((idx-1)%#list)+1
            local p=list[idx]
            if isValidTarget(p) then return p end
        end
        return nil
    end, function() return config.loopInterval end)
end)
autoSection:AddToggle("Aura", function(enabled)
    if not enabled then stopAutoModule("aura") return end
    startAutoModule("aura", function()
        local char=LocalPlayer.Character
        local root=char and char:FindFirstChild("HumanoidRootPart")
        if not root then return nil end
        local myPos=root.Position
        local maxSq=(config.auraStuds or 15)^2
        local best,bestDist=nil,maxSq
        local players=Players:GetPlayers()
        for i=1,#players do
            local player=players[i]
            if isValidTarget(player) then
                local tr=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if tr then
                    local d=(myPos-tr.Position).Magnitude
                    local dsq=d*d
                    if dsq<=bestDist then best,bestDist=player,dsq end
                end
            end
        end
        return best
    end, function() return config.auraInterval end)
end)
autoSection:AddToggle("Click", function(enabled)
    if maids.clickFling then maids.clickFling:Destroy(); maids.clickFling=nil end
    if not enabled then return end
    maids.clickFling=Maid.new()
    local camera=Workspace.CurrentCamera
    local rayParams=RaycastParams.new()
    rayParams.FilterType=Enum.RaycastFilterType.Exclude
    rayParams.IgnoreWater=true
    local function resolveTarget()
        local char=LocalPlayer.Character
        rayParams.FilterDescendantsInstances=char and {char} or {}
        local mouse=LocalPlayer:GetMouse()
        if camera and mouse then
            local unit=camera:ViewportPointToRay(mouse.X, mouse.Y, 1000)
            local hit=Workspace:Raycast(unit.Origin, unit.Direction*1000, rayParams)
            if hit and hit.Instance then
                local model=hit.Instance:FindFirstAncestorWhichIsA("Model")
                local player=model and Players:GetPlayerFromCharacter(model)
                if player then return player end
            end
        end
        local target=mouse and mouse.Target
        local model=target and target:FindFirstAncestorWhichIsA("Model")
        local player=model and Players:GetPlayerFromCharacter(model)
        return player or nil
    end
    local function onInput(input, processed)
        if processed then return end
        if input.UserInputType ~= MOUSE1 and input.UserInputType ~= TOUCH then return end
        local ok, player=pcall(resolveTarget)
        if not ok or not player or player==LocalPlayer then return end
        state.resetSelPlr=player
        if state.whitelist[player.UserId] then Notify("Click", player.Name.." is whitelisted!",3)
        else SkidFling(player); Notify("Click","Flinging "..player.Name,2) end
    end
    maids.clickFling:GiveTask(UserInputService.InputBegan:Connect(onInput))
end)

 
local listSection = AddSection("📋 Lists")
listSection:AddPlayerDropdown("🎯 Select", function(p)
    if p and p ~= LocalPlayer then state.resetSelPlr=p; Notify("Selected", p.Name.." set",3) end
end)
listSection:AddPlayerDropdown("➕ Loop", function(p)
    if p and p ~= LocalPlayer then
        state.resetSelPlr=p
        if not state.selectedSet[p.UserId] then
            state.selectedSet[p.UserId]=true
            insert(state.selectedPlayers,p)
            Notify("Selected", p.Name.." added",3)
        end
    end
end)
listSection:AddButton("🧹 Clear loop", function()
    clearTable(state.selectedPlayers); clearTable(state.selectedSet)
    Notify("Selected","Cleared",3)
end)
listSection:AddPlayerDropdown("🛡 Whitelist", function(p)
    if p and p ~= LocalPlayer then state.whitelist[p.UserId]=p.Name; Notify("Whitelist", p.Name.." added",3); saveConfig() end
end)
listSection:AddPlayerDropdown("🛡 Un-whitelist", function(p)
    if p and state.whitelist[p.UserId] then state.whitelist[p.UserId]=nil; Notify("Whitelist", p.Name.." removed",3); saveConfig()
    elseif p then Notify("Whitelist", p.Name.." is not whitelisted",3) end
end)
listSection:AddButton("🧹 Clear WL", function() clearTable(state.whitelist); Notify("Whitelist","Cleared",3); saveConfig() end)

 
local settingsSection = AddSection("⚙️ Tuning")
settingsSection:AddSlider("Fling Duration", 1, 5, config.flingDuration, function(v) config.flingDuration=v; saveConfig() end)
settingsSection:AddSlider("Fling Power", 1, 3, config.flingPower, function(v) config.flingPower=v; saveConfig() end)
settingsSection:AddSlider("Prediction", 0, 20, config.predictionStuds, function(v) config.predictionStuds=v; saveConfig() end)
settingsSection:AddSlider("Start Height", -5, 20, config.startStuds, function(v) config.startStuds=v; saveConfig() end)
settingsSection:AddSlider("Aura Radius", 5, 50, config.auraStuds, function(v) config.auraStuds=v; saveConfig() end)
settingsSection:AddSlider("Loop Interval", 0.1, 1.0, config.loopInterval, function(v) config.loopInterval=v; saveConfig() end)
settingsSection:AddSlider("Aura Interval", 0.1, 1.0, config.auraInterval, function(v) config.auraInterval=v; saveConfig() end)
settingsSection:AddSlider("Target Cooldown", 0, 3, config.targetCooldown, function(v) config.targetCooldown=v; saveConfig() end)
settingsSection:AddSlider("Auto Sheriff Delay", 0.1, 1.0, config.autoSheriffDelay, function(v) config.autoSheriffDelay=v; saveConfig() end)
settingsSection:AddSlider("Auto Murderer Delay", 0.1, 1.0, config.autoMurdererDelay, function(v) config.autoMurdererDelay=v; saveConfig() end)
settingsSection:AddSlider("Role Cache TTL", 0.2, 3.0, config.roleCacheTTL, function(v) config.roleCacheTTL=v; saveConfig() end)
settingsSection:AddToggle("Auto Return", function(enabled) config.autoReturn=enabled and true or false; saveConfig() end)
settingsSection:AddToggle("Notifications", function(enabled) config.notifications=enabled and true or false; saveConfig() end)

 
local floatSection = AddSection("🔘 Binds")
floatSection:AddToggle("SFX 🔇", function(bool) Audio.setMuted(bool) end)

local function toggleBindButton(actionId)
    return function(enabled)
        local id="bind_"..actionId
        if enabled then
            BindableButtons.AddBButton(id, ACTIONS[actionId].short, function() runAction(actionId) end, actionId=="selected")
        else
            BindableButtons.DeleteBButton(id)
        end
    end
end

for _,id in ipairs(ACTION_ORDER) do
    floatSection:AddToggle("Bind "..ACTIONS[id].name, toggleBindButton(id))
end
floatSection:AddSlider("Bind Size (%)", 5, 25, math.floor((config.bindButtonSize or 0.085)*100), function(value)
    BindableButtons.setSize(value/100)
end)
floatSection:AddButton("🧩 Reset bind layout", function() BindableButtons.resetLayout(); Notify("Binds","Layout reset",2) end)
floatSection:AddButton("🛑 Panic", function()
    cancelCurrentFling()
    setTouchFling(false)
    for _,key in ipairs({"loopPlr","clickFling","aura","autoSheriff","autoMurderer","touchFling"}) do stopAutoModule(key) end
    BindableButtons.clearAll()
    for _,r in ipairs(ODHX.records) do
        if r.kind=="Toggle" and (r.section=="🤖 Auto" or (r.section=="🔘 Binds" and r.name:sub(1,5)=="Bind ")) then
            ODHX.Set(r.section,r.name,r.kind,false,false)
        end
    end
    Notify("Panic","All modules stopped",3)
end)

 
local keySection = AddSection("🔑 Keys")
for _,id in ipairs(ACTION_ORDER) do
    keySection:AddToggle("Key "..ACTIONS[id].name.." ["..keyName(id).."]", function(enabled)
        if enabled then Keybinds.capture=id; Notify("Hotkey","Press a key for "..ACTIONS[id].name.."...",5)
        else config.keybinds[id]=nil; if Keybinds.capture==id then Keybinds.capture=nil end; saveConfig(); Notify("Hotkey", ACTIONS[id].name.." key cleared",3) end
    end)
end
keySection:AddButton("🧹 Clear keys", function() clearTable(config.keybinds); Keybinds.capture=nil; saveConfig(); Notify("Hotkey","All hotkeys cleared",3) end)

 
do
    local function nfind(s, p)
        return string.find(s, p, 1, true) ~= nil
    end
    local defs = {
        aim = {
            { "Silent Aim Gun", function(n) return nfind(n,"pistol") or nfind(n,"piercer") or nfind(n,"gun targeting") or (nfind(n,"silent aim") and not nfind(n,"knife")) or (string.sub(n,1,4)=="gun " and not nfind(n,"knife")) end },
            { "Silent Aim Knife", function(n) return nfind(n,"knife") end },
        },
        main = {
            { "Movement", function(n) return nfind(n,"universal") or nfind(n,"noclip") or nfind(n,"fly") end },
            { "Invisible", function(n) return nfind(n,"invisible") end },
            { "Fun", function(n) return nfind(n,"fun client") or nfind(n,"fun") end },
            { "Server", function(n) return nfind(n,"server") end },
        },
        world = {
            { "Gun", function(n) return nfind(n,"world") and nfind(n,"gun") end },
            { "Fling", function(n) return nfind(n,"fling") or nfind(n,"🤖") or nfind(n,"lists") or nfind(n,"tuning") or nfind(n,"binds") or nfind(n,"keys") or nfind(n,"auto") end },
            { "Bomb Jump", function(n) return nfind(n,"bomb") end },
            { "World", function(n) return nfind(n,"world") and not nfind(n,"gun") and not nfind(n,"bomb") and not nfind(n,"fling") end },
        },
        visual = {
            { "Objects", function(n) return nfind(n,"object") end },
            { "ESP", function(n) return nfind(n,"visual") end },
        },
        emotes = {
            { "Animations", function(n) return true end },
        },
        misc = {
            { "Aimlock", function(n) return nfind(n,"aimlock") end },
            { "Cursor", function(n) return nfind(n,"cursor") end },
            { "FPS", function(n) return nfind(n,"fps") and not nfind(n,"aimlock") end },
            { "Desync", function(n) return nfind(n,"desync") end },
        },
    }
    local pageFrames = {
        aim = content, main = mainContent, world = worldContent,
        visual = visualContent, emotes = emotesContent, misc = miscContent,
    }
    local function matchTab(list, n)
        for i = 1, #list do
            if list[i][2](n) then return list[i][1] end
        end
        return nil
    end
    local function attach(pageId, frame, tabs)
        if not frame or not tabs or #tabs == 0 then return end
        if #tabs == 1 then return end
        local bar = New("Frame", { Parent = frame, Name = "NoirSubBar", ZIndex = 6,
            Position = UDim2.fromOffset(0, 2), Size = UDim2.new(1, 0, 0, 42),
            BackgroundColor3 = C.surface, BackgroundTransparency = .2 })
        corner(bar, 12); stroke(bar, C.border, .45)
        New("UIListLayout", { Parent = bar, FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 4), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder })
        New("UIPadding", { Parent = bar, PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) })
        for _, child in ipairs(frame:GetChildren()) do
            if child:IsA("ScrollingFrame") then
                child.Position = UDim2.fromOffset(0, 50)
                child.Size = UDim2.new(1, -6, 1, -54)
            end
        end
        local groups, buttons, current = {}, {}, tabs[1][1]
        for _, rec in ipairs(sectionPanels) do
            if rec.page == pageId then
                local title = matchTab(tabs, rec.name)
                rec.sub = title
                groups[title] = groups[title] or {}
                groups[title][#groups[title] + 1] = rec.panel
            end
        end
        local function show(title)
            current = title
            pcall(function()
                getgenv().__NoirSubCurrent = getgenv().__NoirSubCurrent or {}
                getgenv().__NoirSubCurrent[pageId] = title
                getgenv().__NoirSubShow = getgenv().__NoirSubShow or {}
                getgenv().__NoirSubShow[pageId] = show
            end)
            for name, list in pairs(groups) do
                local vis = name == title
                for i = 1, #list do list[i].Visible = vis end
            end
            for name, btn in pairs(buttons) do
                local on = name == title
                btn.BackgroundTransparency = on and .28 or 1
                btn.TextColor3 = on and C.text or C.dim
                local line = btn:FindFirstChild("OnLine")
                if line then line.Visible = on end
            end
        end
        local w = 1 / math.max(#tabs, 1)
        for i, tab in ipairs(tabs) do
            local title = tab[1]
            local b = New("TextButton", { Parent = bar, LayoutOrder = i, Size = UDim2.new(w, -4, 0, 30),
                BackgroundColor3 = C.panel, BackgroundTransparency = 1, Text = title,
                TextColor3 = C.dim, TextSize = 12, Font = Enum.Font.GothamMedium, AutoButtonColor = false })
            corner(b, 8)
            New("Frame", { Parent = b, Name = "OnLine", AnchorPoint = Vector2.new(.5, 1),
                Position = UDim2.new(.5, 0, 1, 0), Size = UDim2.new(.5, 0, 0, 2),
                BackgroundColor3 = C.accent, Visible = false, BorderSizePixel = 0 })
            buttons[title] = b
            b.MouseButton1Click:Connect(function() show(title) end)
            b.Activated:Connect(function() show(title) end)
        end
        show(current)
    end
    for pageId, tabs in pairs(defs) do
        pcall(attach, pageId, pageFrames[pageId], tabs)
    end
end


 
markOwnCards()

RootMaid:GiveTask(task.spawn(function()
    for _,delay in ipairs({1.5,2.5,3.0,5.0}) do
        task.wait(delay)
        pcall(markOwnCards)
        pcall(purgeForeign, true)
    end
end))

 
Audio.init()
 
BindableButtons.setSize(config.bindButtonSize or 0.085)
hudApplyPosition()
if configLoaded then Notify(BRAND, VERSION.." loaded (config restored)",3)
else Notify(BRAND, VERSION.." loaded. Duplicates auto-cleaned.",3) end
if headlessMode then Notify(BRAND,"Menu API missing — headless mode (binds/hotkeys work)",5) end

RootMaid:GiveTask(Players.PlayerRemoving:Connect(function(player)
    if not player then return end
    state.lastResetAt[player.UserId]=nil
    state.selectedSet[player.UserId]=nil
    for i=#state.selectedPlayers,1,-1 do if state.selectedPlayers[i]==player then table.remove(state.selectedPlayers,i) end end
    if state.resetSelPlr==player then state.resetSelPlr=nil end
    if sheriffCache and sheriffCache.player==player then sheriffCache.player=nil end
    invalidateRoleCache()
end))
RootMaid:GiveTask(Players.PlayerAdded:Connect(function() invalidateRoleCache() end))

 
RootMaid:GiveTask(function()
    persistDisabled=true
    if saveThread then pcall(task.cancel, saveThread) end
    saveThread,saveQueued=nil,false
    cancelCurrentFling()
    for _,m in pairs(maids) do if m then m:Destroy() end end
    clearTable(maids)
    clearTable(state.whitelist)
    clearTable(state.selectedPlayers)
    clearTable(state.selectedSet)
    clearTable(state.lastResetAt)
    Keybinds.capture=nil
    BindableButtons.clearAll()
    pcall(removeMySections)
    pcall(function() if storageGui then storageGui:Destroy() end; storageGui=nil end)
end)

local function unload()
    RootMaid:DoCleaning()
    if __NOIR_SHARED[__NOIR_GUARD_KEY] == __NOIR_GUARD then
        __NOIR_SHARED[__NOIR_GUARD_KEY] = nil
    end
end

pcall(function()
    if type(getgenv) ~= "function" then return end
    local g=getgenv()
    if type(g)~="table" then return end
    rawset(g, UNLOAD_GLOBAL, ODHX.Stop)
end)

ODHX.Bind("⚙️ Tuning", "Auto Return", "Toggle", function() return config.autoReturn end)
ODHX.Bind("⚙️ Tuning", "Notifications", "Toggle", function() return config.notifications end)
ODHX.Bind("🔘 Binds", "SFX 🔇", "Toggle", function() return config.muteSounds end)
ODHX.Bind("⚙️ Tuning", "Fling Duration", "Slider", function() return config.flingDuration end)
ODHX.Bind("⚙️ Tuning", "Fling Power", "Slider", function() return config.flingPower end)
ODHX.Bind("⚙️ Tuning", "Prediction", "Slider", function() return config.predictionStuds end)
ODHX.Bind("⚙️ Tuning", "Start Height", "Slider", function() return config.startStuds end)
ODHX.Bind("⚙️ Tuning", "Aura Radius", "Slider", function() return config.auraStuds end)
ODHX.Bind("⚙️ Tuning", "Loop Interval", "Slider", function() return config.loopInterval end)
ODHX.Bind("⚙️ Tuning", "Aura Interval", "Slider", function() return config.auraInterval end)
ODHX.Bind("⚙️ Tuning", "Target Cooldown", "Slider", function() return config.targetCooldown end)
ODHX.Bind("⚙️ Tuning", "Auto Sheriff Delay", "Slider", function() return config.autoSheriffDelay end)
ODHX.Bind("⚙️ Tuning", "Auto Murderer Delay", "Slider", function() return config.autoMurdererDelay end)
ODHX.Bind("⚙️ Tuning", "Role Cache TTL", "Slider", function() return config.roleCacheTTL end)
ODHX.Bind("🔘 Binds", "Bind Size (%)", "Slider", function() return config.bindButtonSize*100 end)
ODHX.cleanup=unload
ODHX.Finish()

    end, function(__error) return tostring(__error) end)
    if not __pluginOk then
        warn("[Noir embedded plugin: fling_мой.lua.txt] " .. tostring(__pluginError))
        notify("fling_мой.lua.txt failed to load: " .. tostring(__pluginError), 7)
    end
end

