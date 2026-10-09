-- NOIR_EVENT_HORIZON_V6_1_PART_2
 
local __noirVisualContext = {
    tab = tab, players = Players, workspace = Workspace, runService = RunService,
    localPlayer = LocalPlayer, getPlayers = getPlayers, roleCache = roleCache, roleBus = getgenv().__NoirV4RoleBus,
    getMurderer = function() return murderer end, getSheriff = function() return sheriff end,
    getHero = function() return hero end, getRoundState = function() return roundState end,
     
    refreshRoles = function(force) refreshTarget(force == true) end,
    isRoleRevealActive = function()
        if murderer or sheriff or hero then return true end
        for _, role in pairs(roleCache) do
            if role == "\x6durderer" or role == "\x73heriff" or role == "\x68ero" then return true end
        end
        return false
    end,
    isRunning = function() return running end,
}
getgenv().__NoirV4VisualContext = __noirVisualContext
local __noirVisualSource = "\x2d- Visuals run in a deferred satellite chunk.  Updates are event\x2ddriven so ESP does not rescan Workspace each fraction of a seco\x6ed.\nlocal V = getgenv().__NoirV4VisualContext\nif type(V) ~= \"table\" \x6fr not V.tab then return end\n\nlocal state = {\n    revision = 0, pla\x79ersDirty = true,\n    feature = {\n        cham = {everyone=false,m\x75rderer=false,sheriff=false,hero=false,dead=false},\n        esp =\x20{everyone=false,murderer=false,sheriff=false,hero=false,dead=fa\x6cse},\n        outline = {everyone=false,murderer=false,sheriff=fa\x6cse,hero=false,dead=false},\n        highlight = {everyone=false,m\x75rderer=false,sheriff=false,hero=false,dead=false},\n        trace\x72 = {everyone=false,murderer=false,sheriff=false,hero=false,dead\x3dfalse},\n        box = {everyone=false,murderer=false,sheriff=fal\x73e,hero=false,dead=false},\n        avatar = {everyone=false,murde\x72er=false,sheriff=false,hero=false,dead=false},\n        fire = {e\x76eryone=false,murderer=false,sheriff=false,hero=false,dead=false\x7d,\n    },\n    object = {gun=false,knife=false},\n}\nlocal entries, obj\x65ctEntries, thumbnailCache, thumbnailPending = {}, {}, {}, {}\nloc\x61l joinedLobby, roleRevealActive, drawingState, tracerCount = {}\x2c false, nil, 0\nlocal prefix = \"NoirSatelliteVisual_\"\n\nlocal function\x20safe(label, callback)\n    local ok, err = pcall(callback)\n    if \x6eot ok then warn(\"[Noir Visuals] \" .. tostring(label) .. \": \" .. tos\x74ring(err)) end\n    return ok\nend\nlocal function markPlayersDirty()\n\x20   state.playersDirty = true\nend\nif V.roleBus and V.roleBus.Subsc\x72ibe then V.roleBus:Subscribe(markPlayersDirty) end\n-- MM2 can fi\x6eish assigning roles a moment after the UI appears. Requests are\x20coalesced by the main scanner.\ntask.spawn(function()\n    for _, p\x61use in ipairs({0, .7, 1.8}) do\n        if pause > 0 then task.wa\x69t(pause) end\n        if V.refreshRoles then V.refreshRoles(false\x29 end\n    end\nend)\n\nlocal function color(role)\n    if role == \"murdere\x72\" then return Color3.fromRGB(255,72,82) end\n    if role == \"sherif\x66\" then return Color3.fromRGB(72,158,255) end\n    if role == \"hero\" \x74hen return Color3.fromRGB(255,206,72) end\n    if role == \"dead\" th\x65n return Color3.fromRGB(150,150,158) end\n    return Color3.fromR\x47B(86,230,145)\nend\nlocal function isInactive(player, character, ca\x63hed)\n    if cached == \"dead\" or joinedLobby[player] then return tr\x75e end\n    local round = V.getRoundState and V.getRoundState() or\x20\"waiting\"\n    if round == \"waiting\" and not (V.isRoleRevealActive an\x64 V.isRoleRevealActive()) then return true end\n    local teamName\x20= player.Team and string.lower(tostring(player.Team.Name)) or \"\"\n \x20  if string.find(teamName,\"lobby\",1,true) or string.find(teamName\x2c\"spectat\",1,true) or string.find(teamName,\"waiting\",1,true) or stri\x6eg.find(teamName,\"observer\",1,true) then return true end\n    for _,\x20container in ipairs({player, character}) do\n        if container\x20then\n            for key, value in pairs(container:GetAttributes\x28)) do\n                local name = string.lower(tostring(key))\n  \x20             if (string.find(name,\"inround\",1,true) or string.fin\x64(name,\"ingame\",1,true) or string.find(name,\"isplaying\",1,true) or s\x74ring.find(name,\"alive\",1,true)) and value == false then return tr\x75e end\n                if string.find(name,\"state\",1,true) or strin\x67.find(name,\"status\",1,true) or string.find(name,\"location\",1,true) \x74hen\n                    local text = string.lower(tostring(value\x29)\n                    if string.find(text,\"lobby\",1,true) or strin\x67.find(text,\"spectat\",1,true) or string.find(text,\"dead\",1,true) or \x73tring.find(text,\"waiting\",1,true) then return true end\n           \x20    end\n            end\n            for _, name in ipairs({\"InLobb\x79\",\"Spectating\",\"Dead\",\"IsDead\"}) do\n                local flag = contai\x6eer:FindFirstChild(name)\n                if flag and flag:IsA(\"Boo\x6cValue\") and flag.Value then return true end\n            end\n      \x20 end\n    end\n    return false\nend\nlocal function roleOf(player, cha\x72acter)\n    local humanoid = character and character:FindFirstChi\x6cdWhichIsA(\"Humanoid\")\n    local cached = V.roleCache and V.roleCac\x68e[player.UserId]\n    if not humanoid or humanoid.Health <= 0 or \x69sInactive(player, character, cached) then return \"dead\" end\n    if\x20player == V.getMurderer() or cached == \"murderer\" then return \"mur\x64erer\" end\n    if player == V.getSheriff() or cached == \"sheriff\" th\x65n return \"sheriff\" end\n    if player == V.getHero() or cached == \"h\x65ro\" then return \"hero\" end\n    return \"innocent\"\nend\nlocal function wan\x74ed(kind, role)\n    local filters = state.feature[kind]\n    return\x20filters and (filters.everyone or filters[role]) or false\nend\nloca\x6c function anyPlayerVisual()\n    for _, filters in pairs(state.fe\x61ture) do for _, enabled in pairs(filters) do if enabled then re\x74urn true end end end\n    return false\nend\nlocal function clearPlay\x65r(player)\n    local entry = entries[player]\n    if not entry then\x20return end\n    if entry.line then tracerCount = math.max(0, trac\x65rCount - 1); pcall(function() entry.line:Remove() end) end\n    f\x6fr _, item in ipairs(entry.items) do pcall(function() item:Destr\x6fy() end) end\n    entries[player] = nil\nend\nlocal function addHighl\x69ght(character, suffix, tint, fill, outline, entry)\n    local h =\x20Instance.new(\"Highlight\")\n    h.Name, h.Adornee, h.DepthMode = pre\x66ix .. suffix, character, Enum.HighlightDepthMode.AlwaysOnTop\n   \x20h.FillColor, h.OutlineColor, h.FillTransparency, h.OutlineTrans\x70arency, h.Parent = tint, tint, fill, outline, character\n    tabl\x65.insert(entry.items, h)\nend\nlocal function billboard(root, suffix\x2c size, offset, entry)\n    local b = Instance.new(\"BillboardGui\")\n  \x20 b.Name, b.Adornee, b.AlwaysOnTop, b.Size, b.StudsOffset, b.Par\x65nt = prefix .. suffix, root, true, size, offset, root\n    table.\x69nsert(entry.items, b)\n    return b\nend\nlocal function loadAvatar(p\x6cayer, image)\n    local cached = thumbnailCache[player.UserId]\n   \x20if cached then image.Image = cached; return end\n    if thumbnail\x50ending[player.UserId] then return end\n    thumbnailPending[playe\x72.UserId] = true\n    task.spawn(function()\n        local ok, asset\x20= pcall(function() return V.players:GetUserThumbnailAsync(playe\x72.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size15\x30x150) end)\n        thumbnailPending[player.UserId] = nil\n        \x69f ok and asset then\n            thumbnailCache[player.UserId] = \x61sset\n            if image.Parent then image.Image = asset end\n   \x20    end\n    end)\nend\nlocal function apply(player, enabled)\n    if p\x6cayer == V.localPlayer then return end\n    local character = play\x65r.Character\n    if not character then clearPlayer(player); retur\x6e end\n    local root = character:FindFirstChild(\"HumanoidRootPart\")\x20or character:FindFirstChild(\"UpperTorso\") or character:FindFirstC\x68ild(\"Torso\")\n    local role = roleOf(player, character)\n    local s\x69gn = tostring(state.revision) .. \":\" .. role .. \":\" .. tostring(roo\x74)\n    local old = entries[player]\n    if old and old.character ==\x20character and old.sign == sign then return end\n    clearPlayer(p\x6cayer)\n    if not enabled then return end\n    local tint = color(r\x6fle)\n    local entry = {character=character, root=root, sign=sign\x2c tint=tint, items={}, line=nil}\n    entries[player] = entry\n    i\x66 wanted(\"cham\",role) then addHighlight(character,\"Cham\",tint,.45,1,\x65ntry) end\n    if wanted(\"outline\",role) then addHighlight(characte\x72,\"Outline\",tint,1,0,entry) end\n    if wanted(\"highlight\",role) then \x61ddHighlight(character,\"Highlight\",tint,.68,.05,entry) end\n    if w\x61nted(\"tracer\",role) then\n        if drawingState == nil then\n      \x20     local ok, api = pcall(function() return Drawing end)\n      \x20     drawingState = ok and type(api) == \"table\" and type(api.new)\x20== \"function\" and api or false\n        end\n        if drawingState \x74hen\n            local line = drawingState.new(\"Line\")\n            l\x69ne.Thickness, line.Transparency, line.Color, line.Visible = 1.5\x2c 1, tint, false\n            entry.line, tracerCount = line, trac\x65rCount + 1\n        end\n    end\n    if root and wanted(\"esp\",role) th\x65n\n        local b = billboard(root,\"ESP\",UDim2.fromOffset(156,42),\x56ector3.new(0,3.4,0),entry)\n        local l = Instance.new(\"TextLa\x62el\")\n        l.Size, l.BackgroundTransparency, l.Font, l.TextSize\x20= UDim2.fromScale(1,1), 1, Enum.Font.GothamSemibold, 14\n        \x6c.TextColor3, l.TextStrokeTransparency, l.Text, l.Parent = Color\x33.new(1,1,1), .35, player.DisplayName .. \"\\n\" .. string.upper(role)\x2c b\n    end\n    if root and wanted(\"box\",role) then\n        local b =\x20billboard(root,\"Box\",UDim2.fromOffset(86,122),Vector3.new(0,1.8,0\x29,entry)\n        local f = Instance.new(\"Frame\")\n        f.Size, f.B\x61ckgroundTransparency, f.Parent = UDim2.fromScale(1,1), 1, b\n    \x20   local stroke = Instance.new(\"UIStroke\")\n        stroke.Color, s\x74roke.Thickness, stroke.Parent = tint, 1.7, f\n    end\n    if root \x61nd wanted(\"avatar\",role) then\n        local b = billboard(root,\"Ava\x74ar\",UDim2.fromOffset(58,58),Vector3.new(0,4.8,0),entry)\n        l\x6fcal image = Instance.new(\"ImageLabel\")\n        image.Size, image.B\x61ckgroundColor3, image.BorderSizePixel, image.Parent = UDim2.fro\x6dScale(1,1), Color3.fromRGB(12,14,18), 0, b\n        local corner \x3d Instance.new(\"UICorner\"); corner.CornerRadius, corner.Parent = U\x44im.new(1,0), image\n        local stroke = Instance.new(\"UIStroke\")\x3b stroke.Color, stroke.Thickness, stroke.Parent = tint, 1.5, ima\x67e\n        loadAvatar(player, image)\n    end\n    if root and wanted\x28\"fire\",role) then\n        local flame = Instance.new(\"Fire\")\n        \x66lame.Name, flame.Color, flame.SecondaryColor, flame.Size, flame\x2eHeat, flame.Parent = prefix..\"Fire\", tint, tint:Lerp(Color3.new(1\x2c1,1),.35), 5, 7, root\n        table.insert(entry.items, flame)\n  \x20 end\nend\nlocal function refreshPlayers()\n    local enabled, seen =\x20anyPlayerVisual(), {}\n    for _, player in ipairs(V.getPlayers()\x29 do if player ~= V.localPlayer then seen[player] = true; apply(\x70layer, enabled) end end\n    for player in pairs(entries) do if n\x6ft seen[player] then clearPlayer(player) end end\n    state.player\x73Dirty = false\nend\n\nlocal function objectType(instance)\n    if not i\x6estance:IsA(\"BasePart\") then return nil end\n    local owner = insta\x6ece:FindFirstAncestorOfClass(\"Model\")\n    if owner and V.players:Ge\x74PlayerFromCharacter(owner) then return nil end\n    local name = \x73tring.lower(instance.Name)\n    if name == \"gundrop\" or name == \"gun\"\x20or string.find(name,\"droppedgun\",1,true) or string.find(name,\"gun_\x64rop\",1,true) then return \"gun\" end\n    if string.find(name,\"throw\",1,\x74rue) and string.find(name,\"knife\",1,true) then return \"knife\" end\nen\x64\nlocal function clearObject(instance)\n    local entry = objectEnt\x72ies[instance]\n    if entry then for _, item in ipairs(entry) do \x70call(function() item:Destroy() end) end; objectEntries[instance\x5d = nil end\nend\nlocal function trackObject(instance)\n    local kind\x20= objectType(instance)\n    if not kind or not state.object[kind]\x20then\n        if objectEntries[instance] then clearObject(instanc\x65) end\n        return\n    end\n    if objectEntries[instance] then r\x65turn end\n    local tint = kind == \"gun\" and Color3.fromRGB(72,158,\x3255) or Color3.fromRGB(255,126,72)\n    local h = Instance.new(\"Hig\x68light\")\n    h.Name, h.Adornee, h.DepthMode = prefix..\"Object\", inst\x61nce, Enum.HighlightDepthMode.AlwaysOnTop\n    h.FillColor, h.Outl\x69neColor, h.FillTransparency, h.OutlineTransparency, h.Parent = \x74int, tint, .72, 0, instance\n    local b = Instance.new(\"Billboard\x47ui\")\n    b.Name, b.Adornee, b.AlwaysOnTop, b.Size, b.StudsOffset,\x20b.Parent = prefix..\"ObjectLabel\", instance, true, UDim2.fromOffse\x74(132,24), Vector3.new(0,1.5,0), instance\n    local l = Instance.\x6eew(\"TextLabel\")\n    l.Size, l.BackgroundTransparency, l.Font, l.Te\x78tSize, l.TextColor3, l.TextStrokeTransparency, l.Text, l.Parent\x20= UDim2.fromScale(1,1),1,Enum.Font.GothamBold,12,tint,.35,(kind\x3d=\"gun\" and \"DROPPED GUN\" or \"THROWING KNIFE\"),b\n    objectEntries[inst\x61nce] = {h,b}\nend\nlocal function refreshObjects(fullScan)\n    if fu\x6clScan and (state.object.gun or state.object.knife) then for _, \x69nstance in ipairs(V.workspace:GetDescendants()) do trackObject(\x69nstance) end end\n    for instance in pairs(objectEntries) do\n    \x20   local kind = instance.Parent and objectType(instance)\n       \x20if not kind or not state.object[kind] then clearObject(instance\x29 end\n    end\nend\nlocal function setFilter(kind, filter, enabled)\n  \x20 state.feature[kind][filter] = enabled == true\n    state.revisio\x6e, state.playersDirty = state.revision + 1, true\n    safe(\"player \x72efresh\", refreshPlayers)\nend\nlocal objectAddedConnection, objectRe\x6dovingConnection\nlocal function updateObjectConnections()\n    loca\x6c enabled = state.object.gun or state.object.knife\n    if enabled\x20then\n        if not objectAddedConnection then\n            object\x41ddedConnection = V.workspace.DescendantAdded:Connect(function(i\x6estance)\n                if state.object.gun or state.object.knif\x65 then task.defer(trackObject, instance) end\n            end)\n    \x20   end\n        if not objectRemovingConnection then\n            o\x62jectRemovingConnection = V.workspace.DescendantRemoving:Connect\x28function(instance)\n                if objectEntries[instance] th\x65n clearObject(instance) end\n            end)\n        end\n    else\n \x20      if objectAddedConnection then objectAddedConnection:Disco\x6enect(); objectAddedConnection = nil end\n        if objectRemovin\x67Connection then objectRemovingConnection:Disconnect(); objectRe\x6dovingConnection = nil end\n    end\nend\nlocal function setObject(kin\x64, enabled)\n    state.object[kind] = enabled == true\n    updateObj\x65ctConnections()\n    safe(\"object refresh\", function() refreshObjec\x74s(true) end)\nend\n\nlocal tracerElapsed = 0\nV.runService.RenderSteppe\x64:Connect(function(dt)\n    if tracerCount <= 0 then tracerElapsed\x20= 0; return end\n    tracerElapsed += dt\n    if tracerElapsed < (1\x20/ 30) then return end\n    tracerElapsed = 0\n    local camera = V.\x77orkspace.CurrentCamera\n    if not camera then return end\n    loca\x6c viewport, origin = camera.ViewportSize, Vector2.new(camera.Vie\x77portSize.X*.5,camera.ViewportSize.Y)\n    for _, entry in pairs(e\x6etries) do\n        local line, root = entry.line, entry.root\n     \x20  if line then\n            if root and root.Parent and root:IsDe\x73cendantOf(entry.character) then\n                local point, vis\x69ble = camera:WorldToViewportPoint(root.Position)\n               \x20line.From, line.To, line.Color, line.Visible = origin, Vector2.\x6eew(point.X,point.Y), entry.tint, visible and point.Z > 0\n       \x20    else line.Visible = false end\n        end\n    end\nend)\nlocal fu\x6ection watchCharacter(player, character)\n    markPlayersDirty()\n  \x20 task.defer(function()\n        local humanoid = character and ch\x61racter:FindFirstChildWhichIsA(\"Humanoid\")\n        if humanoid then\x20humanoid.Died:Connect(markPlayersDirty) end\n    end)\nend\nfor _, pl\x61yer in ipairs(V.getPlayers()) do\n    if player.Character then wa\x74chCharacter(player, player.Character) end\n    player.CharacterAd\x64ed:Connect(function(character) watchCharacter(player, character\x29 end)\nend\nV.players.PlayerAdded:Connect(function(player)\n    if V.\x69sRoleRevealActive and V.isRoleRevealActive() then joinedLobby[p\x6cayer] = true end\n    player.CharacterAdded:Connect(function(char\x61cter) watchCharacter(player, character) end)\n    markPlayersDirt\x79()\nend)\nV.players.PlayerRemoving:Connect(function(player)\n    join\x65dLobby[player] = nil\n    clearPlayer(player)\nend)\ntask.spawn(funct\x69on()\n    while V.isRunning() do\n        local revealing = V.isRol\x65RevealActive and V.isRoleRevealActive() or false\n        if reve\x61ling and not roleRevealActive then table.clear(joinedLobby); ma\x72kPlayersDirty() end\n        if revealing ~= roleRevealActive the\x6e markPlayersDirty() end\n        roleRevealActive = revealing\n    \x20   -- Event changes refresh immediately; this slow fallback cov\x65rs unusual maps that do not signal character state changes.\n    \x20   if state.playersDirty or anyPlayerVisual() then safe(\"player \x75pdate\", refreshPlayers) end\n        if next(objectEntries) then s\x61fe(\"object cleanup\", function() refreshObjects(false) end) end\n   \x20    task.wait(1)\n    end\n    if objectAddedConnection then pcall(\x66unction() objectAddedConnection:Disconnect() end); objectAddedC\x6fnnection = nil end\n    if objectRemovingConnection then pcall(fu\x6ection() objectRemovingConnection:Disconnect() end); objectRemov\x69ngConnection = nil end\n    for instance in pairs(objectEntries) \x64o clearObject(instance) end\nend)\n\nlocal filters = {{\"Everyone\",\"every\x6fne\"},{\"Murderer Only\",\"murderer\"},{\"Sheriff Only\",\"sheriff\"},{\"Hero Only\",\"\x68ero\"},{\"Dead Only\",\"dead\"}}\nfor _, definition in ipairs({{\"CHAM\",\"cham\"},\x7b\"ESP\",\"esp\"},{\"OUTLINE\",\"outline\"},{\"HIGHLIGHT\",\"highlight\"},{\"TRACER\",\"tracer\"\x7d,{\"ESP BOX\",\"box\"},{\"ESP AVATAR\",\"avatar\"},{\"ESP FIRE\",\"fire\"}}) do\n    loca\x6c title, kind = definition[1], definition[2]\n    local section = \x56.tab:AddSection(\"VISUAL \\u{2022} \"..title,\"BY PLAYER\")\n    for _, fil\x74erDefinition in ipairs(filters) do\n        local label, filter =\x20filterDefinition[1], filterDefinition[2]\n        section:AddTogg\x6ce(label,function(enabled) safe(\"toggle\",function() setFilter(kind\x2cfilter,enabled) end) end)\n    end\nend\nlocal objects = V.tab:AddSec\x74ion(\"VISUAL \\u{2022} BY OBJECT\",\"Object ESP\")\nobjects:AddToggle(\"Dropp\x65d Gun\",function(enabled) safe(\"object toggle\",function() setObject\x28\"gun\",enabled) end) end)\nobjects:AddToggle(\"Throwing Knives\",functio\x6e(enabled) safe(\"object toggle\",function() setObject(\"knife\",enabled\x29 end) end)\n\n"
task.defer(function()
    local compiler = loadstring
    if type(compiler) ~= "\x66unction" then
        warn("\x5bNoir Visuals] loadstring is unavailable; main Noir loaded witho\x75t the optional Visuals module.")
        return
    end
    local okCompile, module = pcall(compiler, __noirVisualSource)
    if not okCompile or type(module) ~= "\x66unction" then
        warn("\x5bNoir Visuals] module compile failed: " .. tostring(module))
        return
    end
    local okRun, err = xpcall(module, function(message) return tostring(message) end)
    if not okRun then warn("\x5bNoir Visuals] module startup failed: " .. tostring(err)) end
end)



 
getgenv().__NoirMovementContext = {
    tab = tab, players = Players, uis = UIS, runService = RunService, workspace = Workspace,
    localPlayer = LocalPlayer, persistence = NoirPersistence, guiParent = guiParent, coreGui = CoreGui,
    isPrimaryPress = isPrimaryPress, gradientStrokes = gradientStrokes,
}
task.defer(function()
    local __noirMovementSource = "\x2d- Noclip and Fly run in an isolated module to avoid the mobile \x4cuau register limit in the main loader.\nlocal M = getgenv().__Noi\x72MovementContext\nif type(M) ~= \"table\" or not M.tab or not M.persis\x74ence then return end\n\nlocal Players, UIS, RunService, Workspace =\x20M.players, M.uis, M.runService, M.workspace\nlocal LocalPlayer, P\x65rsistence = M.localPlayer, M.persistence\nlocal state = {\n    nocl\x69p = false, noclipOriginals = {},\n    fly = false, flyVelocity = \x6eil, flyGyro = nil, flyConnection = nil,\n    flyHumanoid = nil, f\x6cyAutoRotate = true, flyPlatformStand = false,\n    flyStateEnable\x64 = {}, flyAnimate = nil, flyAnimateDisabled = false,\n    flySpee\x64 = 48,\n}\n-- Uses the supplied universal-fly method: PlatformStand\x20plus BodyGyro/BodyVelocity\n-- on UpperTorso (R15) or Torso (R6),\x20with Humanoid:TranslateBy movement.\nlocal FLY_STATES = {\n    Enum\x2eHumanoidStateType.Climbing, Enum.HumanoidStateType.FallingDown,\n\x20   Enum.HumanoidStateType.Flying, Enum.HumanoidStateType.Freefa\x6cl,\n    Enum.HumanoidStateType.GettingUp, Enum.HumanoidStateType.\x4aumping,\n    Enum.HumanoidStateType.Landed, Enum.HumanoidStateTyp\x65.Physics,\n    Enum.HumanoidStateType.PlatformStanding, Enum.Huma\x6eoidStateType.Ragdoll,\n    Enum.HumanoidStateType.Running, Enum.H\x75manoidStateType.RunningNoPhysics,\n    Enum.HumanoidStateType.Sea\x74ed, Enum.HumanoidStateType.StrafingNoPhysics,\n    Enum.HumanoidS\x74ateType.Swimming,\n}\n\nlocal function applyNoclip()\n    if not state.\x6eoclip then return end\n    local character = LocalPlayer.Characte\x72\n    if not character then return end\n    for _, part in ipairs(c\x68aracter:GetDescendants()) do\n        if part:IsA(\"BasePart\") then\n \x20          if state.noclipOriginals[part] == nil then state.nocl\x69pOriginals[part] = part.CanCollide end\n            if part.CanCo\x6clide then part.CanCollide = false end\n        end\n    end\nend\nlocal\x20function restoreNoclip()\n    for part, original in pairs(state.n\x6fclipOriginals) do\n        if part and part.Parent then pcall(fun\x63tion() part.CanCollide = original end) end\n    end\n    table.clea\x72(state.noclipOriginals)\nend\nlocal function setNoclip(enabled)\n    \x73tate.noclip = enabled == true\n    if state.noclip then applyNocl\x69p() else restoreNoclip() end\nend\nRunService.Stepped:Connect(funct\x69on() if state.noclip then applyNoclip() end end)\n\nlocal function \x72estoreFlyCharacter()\n    local humanoid = state.flyHumanoid\n    i\x66 humanoid and humanoid.Parent then\n        humanoid.AutoRotate =\x20state.flyAutoRotate\n        humanoid.PlatformStand = state.flyPl\x61tformStand\n        for _, stateType in ipairs(FLY_STATES) do\n    \x20       local wasEnabled = state.flyStateEnabled[stateType.Name]\n\x20           if wasEnabled ~= nil then pcall(function() humanoid:\x53etStateEnabled(stateType, wasEnabled) end) end\n        end\n      \x20 if not state.flyPlatformStand then\n            pcall(function()\x20humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end)\n    \x20       task.delay(.08, function()\n                if humanoid.Pa\x72ent and not state.fly then pcall(function() humanoid:ChangeStat\x65(Enum.HumanoidStateType.Running) end) end\n            end)\n      \x20 else\n            pcall(function() humanoid:ChangeState(Enum.Hum\x61noidStateType.Running) end)\n        end\n    end\n    if state.flyAn\x69mate and state.flyAnimate.Parent then state.flyAnimate.Disabled\x20= state.flyAnimateDisabled end\n    state.flyHumanoid, state.flyA\x6eimate = nil, nil\n    table.clear(state.flyStateEnabled)\nend\n\nlocal \x66unction stopFly()\n    if state.flyConnection then state.flyConne\x63tion:Disconnect(); state.flyConnection = nil end\n    if state.fl\x79Velocity then state.flyVelocity:Destroy(); state.flyVelocity = \x6eil end\n    if state.flyGyro then state.flyGyro:Destroy(); state.\x66lyGyro = nil end\n    restoreFlyCharacter()\nend\n\nlocal function star\x74Fly()\n    stopFly()\n    if not state.fly then return end\n    local\x20character = LocalPlayer.Character\n    local humanoid = character\x20and character:FindFirstChildWhichIsA(\"Humanoid\")\n    local root = \x63haracter and character:FindFirstChild(\"HumanoidRootPart\")\n    -- T\x68e linked script handles R15 UpperTorso and R6 Torso.  HumanoidR\x6fotPart is used here\n    -- for the constraints because it preven\x74s the torso/root physics fight that causes shaking.\n    local so\x75rceTorso = character and (character:FindFirstChild(\"UpperTorso\") \x6fr character:FindFirstChild(\"Torso\"))\n    if not (humanoid and root\x20and (sourceTorso or root)) then return end\n\n    -- Keep the sourc\x65's BodyVelocity flight core, but leave Roblox's humanoid states\x20and animation system intact.\n    -- Disabling them (and forcing \x61 BodyGyro at the camera angle) is what caused the visible body \x72ocking.\n    state.flyHumanoid, state.flyAutoRotate, state.flyPla\x74formStand = humanoid, humanoid.AutoRotate, humanoid.PlatformSta\x6ed\n    humanoid.AutoRotate = false\n    -- PlatformStand is needed \x66or a Humanoid avatar to physically pitch with the camera.\n    hu\x6danoid.PlatformStand = true\n    pcall(function() humanoid:ChangeS\x74ate(Enum.HumanoidStateType.Physics) end)\n\n    -- Full 3D camera o\x72ientation: use the linked Fly's high-response gyro settings for\x20quick camera following.\n    local gyro = Instance.new(\"BodyGyro\")\n \x20  gyro.Name, gyro.P, gyro.D, gyro.MaxTorque, gyro.CFrame = \"Noir\x46lyGyro\", 9e4, 800, Vector3.new(9e9,9e9,9e9), root.CFrame\n    gyro\x2eParent = root\n    local velocity = Instance.new(\"BodyVelocity\")\n   \x20velocity.Name, velocity.P, velocity.Velocity, velocity.MaxForce\x20= \"NoirFlyVelocity\", 12000, Vector3.zero, Vector3.new(9e9,9e9,9e9\x29\n    velocity.Parent = root\n    state.flyVelocity, state.flyGyro \x3d velocity, gyro\n\n    state.flyConnection = RunService.Heartbeat:C\x6fnnect(function()\n        if not state.fly or not (character.Pare\x6et and humanoid.Parent and root.Parent and velocity.Parent and g\x79ro.Parent) then return end\n        local camera = Workspace.Curr\x65ntCamera\n        if not camera then return end\n        -- Mobile \x6aoystick flight: push forward/back while aiming the camera up or\x20down to rise/descend.\n        -- MoveDirection supplies the joys\x74ick vector; projecting it on the camera's flat axes preserves i\x74s intent.\n        local look = camera.CFrame.LookVector\n        l\x6fcal right = camera.CFrame.RightVector\n        local flatLook = V\x65ctor3.new(look.X, 0, look.Z)\n        local flatRight = Vector3.n\x65w(right.X, 0, right.Z)\n        gyro.CFrame = CFrame.new(root.Pos\x69tion, root.Position + look)\n        local input = humanoid.MoveD\x69rection\n        local desiredVelocity = Vector3.zero\n        if i\x6eput.Magnitude > .001 then\n            local forwardInput = flatL\x6fok.Magnitude > .001 and input:Dot(flatLook.Unit) or 0\n          \x20 local sideInput = flatRight.Magnitude > .001 and input:Dot(fla\x74Right.Unit) or 0\n            local flightDirection = look * forw\x61rdInput + right * sideInput\n            if flightDirection.Magni\x74ude > .001 then desiredVelocity = flightDirection.Unit * state.\x66lySpeed end\n        end\n        velocity.Velocity = desiredVeloci\x74y\n    end)\nend\n\nlocal function setFly(enabled)\n    state.fly = enabl\x65d == true\n    if state.fly then startFly() else stopFly() end\nend\n\n\x6cocal binds = {\n    noclip = { text=\"Noclip\", key=\"noclip_bind_v1\", d\x65fault=UDim2.new(.38,0,.88,0), size=.105, enabled=false, gui=nil\x2c button=nil, connections={} },\n    fly = { text=\"Fly\", key=\"fly_bin\x64_v1\", default=UDim2.new(.52,0,.88,0), size=.105, enabled=false, \x67ui=nil, button=nil, connections={} },\n}\nlocal function disconnect\x28bind)\n    for _, connection in ipairs(bind.connections) do pcall\x28function() connection:Disconnect() end) end\n    table.clear(bind\x2econnections)\nend\nlocal function updateSize(bind)\n    local camera \x3d Workspace.CurrentCamera\n    if not (bind.button and camera) the\x6e return end\n    local screen = camera.ViewportSize\n    bind.butto\x6e.Size = UDim2.new(bind.size * (screen.Y / math.max(screen.X,1))\x2c0,bind.size,0)\nend\nlocal function updateText(bind, active)\n    loc\x61l label = bind.button and bind.button:FindFirstChild(\"Text\")\n    i\x66 label then label.Text = bind.text .. \"\\n\" .. (active and \"ON\" or \"OF\x46\") end\nend\nlocal function removeBind(bind)\n    disconnect(bind)\n    \x69f bind.gui then bind.gui:Destroy() end\n    bind.gui, bind.button\x20= nil, nil\n    for _, parent in ipairs({M.guiParent, M.coreGui, \x4cocalPlayer:FindFirstChildOfClass(\"PlayerGui\")}) do\n        if type\x6ff(parent) == \"Instance\" then\n            local old = parent:FindFi\x72stChild(\"Noir\" .. bind.text .. \"BindButton\")\n            if old then\x20old:Destroy() end\n        end\n    end\nend\nlocal function createBind\x28bind, isActive, setActive)\n    if bind.button then return end\n   \x20removeBind(bind)\n    local parent = M.guiParent\n    if typeof(par\x65nt) ~= \"Instance\" then parent = LocalPlayer:WaitForChild(\"PlayerGu\x69\") end\n    local screenGui = Instance.new(\"ScreenGui\")\n    screenGui\x2eName, screenGui.ResetOnSpawn, screenGui.IgnoreGuiInset, screenG\x75i.DisplayOrder = \"Noir\" .. bind.text .. \"BindButton\", false, true, \x382\n    screenGui.Parent = parent\n    local button = Instance.new(\"I\x6dageButton\")\n    button.Name, button.AnchorPoint = bind.text, Vect\x6fr2.new(.5,.5)\n    button.Position = Persistence.GetPosition(bind\x2ekey,bind.default)\n    button.BackgroundColor3, button.Background\x54ransparency, button.BorderSizePixel, button.Image, button.AutoB\x75ttonColor, button.ZIndex = Color3.fromRGB(8,8,10),.28,0,\"\",false,\x35\n    button.Parent = screenGui\n    local circle = Instance.new(\"UI\x43orner\"); circle.CornerRadius = UDim.new(1,0); circle.Parent = bu\x74ton\n    local aspect = Instance.new(\"UIAspectRatioConstraint\"); as\x70ect.AspectRatio = 1; aspect.Parent = button\n    local outer = In\x73tance.new(\"UIStroke\"); outer.Color,outer.Thickness,outer.ApplyStr\x6fkeMode,outer.Parent=Color3.fromRGB(255,255,255),2,Enum.ApplyStr\x6fkeMode.Border,button\n    local gradient = Instance.new(\"UIGradien\x74\")\n    gradient.Color=ColorSequence.new({ColorSequenceKeypoint.ne\x77(0,Color3.fromRGB(35,35,40)),ColorSequenceKeypoint.new(.22,Colo\x723.fromRGB(250,250,252)),ColorSequenceKeypoint.new(.48,Color3.fr\x6fmRGB(70,70,78)),ColorSequenceKeypoint.new(.72,Color3.fromRGB(25\x35,255,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(45,45,52)\x29})\n    gradient.Parent=outer\n    local inner=Instance.new(\"UIStrok\x65\");inner.Color,inner.Transparency,inner.Thickness,inner.Parent=C\x6flor3.fromRGB(105,105,112),.5,1,button\n    local innerGradient=gr\x61dient:Clone();innerGradient.Rotation=180;innerGradient.Parent=i\x6ener\n    local label=Instance.new(\"TextLabel\")\n    label.Name,label.\x41nchorPoint,label.Position,label.Size=\"Text\",Vector2.new(.5,.5),UD\x69m2.fromScale(.5,.5),UDim2.fromScale(.76,.76)\n    label.Backgroun\x64Transparency,label.TextColor3,label.TextSize,label.TextWrapped,\x6cabel.Font,label.ZIndex=1,Color3.fromRGB(245,245,248),14,true,En\x75m.Font.Gotham,6\n    label.Parent=button\n    local dragging,moved,\x64ragStart,startPosition,dragInput=false,false,nil,nil,nil\n    bin\x64.connections[#bind.connections+1]=button.InputBegan:Connect(fun\x63tion(input)\n        if not M.isPrimaryPress(input) then return e\x6ed\n        dragging,moved,dragStart,startPosition=true,false,inpu\x74.Position,button.Position\n    end)\n    bind.connections[#bind.con\x6eections+1]=button.InputChanged:Connect(function(input)\n        i\x66 input.UserInputType==Enum.UserInputType.MouseMovement or input\x2eUserInputType==Enum.UserInputType.Touch then dragInput=input en\x64\n    end)\n    bind.connections[#bind.connections+1]=UIS.InputChan\x67ed:Connect(function(input)\n        if not dragging or input~=dra\x67Input then return end\n        local delta=input.Position-dragSta\x72t\n        if delta.Magnitude>7 then moved=true end\n        button\x2ePosition=UDim2.new(startPosition.X.Scale,startPosition.X.Offset\x2bdelta.X,startPosition.Y.Scale,startPosition.Y.Offset+delta.Y)\n  \x20 end)\n    bind.connections[#bind.connections+1]=UIS.InputEnded:C\x6fnnect(function(input)\n        if not dragging or not M.isPrimary\x50ress(input) then return end\n        dragging=false\n        Persis\x74ence.SetPosition(bind.key,button.Position)\n    end)\n    bind.conn\x65ctions[#bind.connections+1]=button.Activated:Connect(function()\x20if not moved then setActive(not isActive()) end end)\n    table.i\x6esert(M.gradientStrokes.fast,gradient)\n    bind.gui,bind.button=s\x63reenGui,button\n    updateSize(bind);updateText(bind,isActive())\ne\x6ed\nlocal function setBind(bind, enabled, isActive, setActive)\n    \x62ind.enabled=enabled==true\n    if bind.enabled then createBind(bi\x6ed,isActive,setActive) else removeBind(bind) end\nend\nlocal functio\x6e syncNoclipText() updateText(binds.noclip,state.noclip) end\nloca\x6c function syncFlyText() updateText(binds.fly,state.fly) end\n\nloca\x6c noclipSection=M.tab:AddSection(\"MAIN \\u{2022} NOCLIP\",\"Walk throug\x68 local collision\")\nnoclipSection:AddToggle(\"Noclip\",function(enable\x64) setNoclip(enabled);syncNoclipText() end)\nnoclipSection:AddTogg\x6ce(\"Enable Noclip Bind Button\",function(enabled)\n    setBind(binds.\x6eoclip,enabled,function() return state.noclip end,function(activ\x65) setNoclip(active);syncNoclipText() end)\nend)\nnoclipSection:AddS\x6cider(\"Noclip Bind Button Size\",5,25,binds.noclip.size*100,functio\x6e(value) binds.noclip.size=(tonumber(value) or 10.5)/100;updateS\x69ze(binds.noclip) end)\n\nlocal flySection=M.tab:AddSection(\"MAIN \\u{2\x3022} FLY\",\"Camera-guided movement\")\nflySection:AddToggle(\"Fly\",functio\x6e(enabled) setFly(enabled);syncFlyText() end)\nflySection:AddToggl\x65(\"Enable Fly Bind Button\",function(enabled)\n    setBind(binds.fly,\x65nabled,function() return state.fly end,function(active) setFly(\x61ctive);syncFlyText() end)\nend)\nflySection:AddSlider(\"Fly Bind Butt\x6fn Size\",5,25,binds.fly.size*100,function(value) binds.fly.size=(\x74onumber(value) or 10.5)/100;updateSize(binds.fly) end)\n\nLocalPlay\x65r.CharacterAdded:Connect(function()\n    task.wait(1)\n    if state\x2enoclip then table.clear(state.noclipOriginals);applyNoclip() en\x64\n    if state.fly then startFly() end\nend)\n\n"
    local compiler = loadstring
    if type(compiler) ~= "\x66unction" then
        warn("\x5bNoir Movement] loadstring is unavailable; Noclip and Fly could \x6eot be started.")
        return
    end
    local okCompile, module = pcall(compiler, __noirMovementSource)
    if not okCompile or type(module) ~= "\x66unction" then
        warn("\x5bNoir Movement] module compile failed: " .. tostring(module))
        return
    end
    local okRun, err = xpcall(module, function(message) return tostring(message) end)
    if not okRun then warn("\x5bNoir Movement] module startup failed: " .. tostring(err)) end
end)




 
getgenv().__NoirAvatarCosmeticsContext = { tab = tab, localPlayer = LocalPlayer, runService = RunService }
task.defer(function()
    local __noirAvatarCosmeticsSource = "\x2d- Persistent client-side avatar cosmetics for Noir's Main tab.\nl\x6fcal A = getgenv().__NoirAvatarCosmeticsContext\nif type(A) ~= \"tab\x6ce\" or not A.tab or not A.localPlayer then return end\n\nlocal LocalP\x6cayer = A.localPlayer\nlocal RunService = A.runService\nlocal KORBLO\x58_RIGHT_LEG = 139607718\nlocal KORBLOX_PARTS = {\n    RightFoot = { \x6desh = \"rbxassetid://902942089\", transparency = 1 },\n    RightLower\x4ceg = { mesh = \"rbxassetid://902942093\", transparency = 1 },\n    Ri\x67htUpperLeg = { mesh = \"rbxassetid://902942096\", texture = \"rbxasse\x74id://902843398\", transparency = 0 },\n}\nlocal state = {\n    korblox \x3d false,\n    headless = false,\n    korbloxOriginals = setmetatable\x28{}, {__mode = \"k\"}),\n    korbloxPartOriginals = setmetatable({}, {\x5f_mode = \"k\"}),\n    headOriginals = setmetatable({}, {__mode = \"k\"}),\n\x20   applyingKorblox = setmetatable({}, {__mode = \"k\"}),\n}\n\nlocal func\x74ion getHumanoid(character)\n    return character and character:Fi\x6edFirstChildWhichIsA(\"Humanoid\")\nend\n\nlocal function applyHeadless(ch\x61racter)\n    if not state.headless then return end\n    local head \x3d character and character:FindFirstChild(\"Head\")\n    if not (head a\x6ed head:IsA(\"BasePart\")) then return end\n    local original = state\x2eheadOriginals[head]\n    if not original then\n        original = {\x20transparency = head.LocalTransparencyModifier, decals = {} }\n   \x20    state.headOriginals[head] = original\n        for _, descenda\x6et in ipairs(head:GetDescendants()) do\n            if descendant:\x49sA(\"Decal\") or descendant:IsA(\"Texture\") then original.decals[desce\x6edant] = descendant.Transparency end\n        end\n    end\n    head.L\x6fcalTransparencyModifier = 1\n    for decal in pairs(original.deca\x6cs) do\n        if decal and decal.Parent then decal.Transparency \x3d 1 end\n    end\n    local face = head:FindFirstChildWhichIsA(\"Decal\"\x29\n    if face and original.decals[face] == nil then\n        origin\x61l.decals[face] = face.Transparency\n        face.Transparency = 1\n\x20   end\nend\n\nlocal function restoreHeadless(character)\n    local hea\x64 = character and character:FindFirstChild(\"Head\")\n    local origin\x61l = head and state.headOriginals[head]\n    if not original then \x72eturn end\n    if head.Parent then head.LocalTransparencyModifier\x20= original.transparency end\n    for decal, transparency in pairs\x28original.decals) do\n        if decal and decal.Parent then decal\x2eTransparency = transparency end\n    end\n    state.headOriginals[h\x65ad] = nil\nend\n\nlocal function applyKorbloxMesh(character)\n    if no\x74 state.korblox or not character then return end\n    for partName\x2c appearance in pairs(KORBLOX_PARTS) do\n        local part = char\x61cter:FindFirstChild(partName)\n        if part and part:IsA(\"MeshP\x61rt\") then\n            local original = state.korbloxPartOriginals\x5bpart]\n            if not original then\n                original =\x20{ mesh = part.MeshId, texture = part.TextureID, transparency = \x70art.Transparency }\n                state.korbloxPartOriginals[pa\x72t] = original\n            end\n            pcall(function() part.M\x65shId = appearance.mesh end)\n            if appearance.texture th\x65n pcall(function() part.TextureID = appearance.texture end) end\n\x20           pcall(function() part.Transparency = appearance.tran\x73parency end)\n        end\n    end\nend\n\nlocal function restoreKorbloxM\x65sh(character)\n    if not character then return end\n    for _, par\x74 in ipairs(character:GetDescendants()) do\n        local original\x20= state.korbloxPartOriginals[part]\n        if original and part:\x49sA(\"MeshPart\") then\n            pcall(function()\n                pa\x72t.MeshId, part.TextureID, part.Transparency = original.mesh, or\x69ginal.texture, original.transparency\n            end)\n           \x20state.korbloxPartOriginals[part] = nil\n        end\n    end\nend\n\nloca\x6c function applyKorblox(character)\n    if not state.korblox then \x72eturn end\n    local humanoid = getHumanoid(character)\n    if not \x28humanoid and humanoid.RigType == Enum.HumanoidRigType.R15) or s\x74ate.applyingKorblox[character] then return end\n    local ok, des\x63ription = pcall(function() return humanoid:GetAppliedDescriptio\x6e() end)\n    if not ok or not description then return end\n    if s\x74ate.korbloxOriginals[character] == nil then state.korbloxOrigin\x61ls[character] = description.RightLeg end\n    if description.Righ\x74Leg ~= KORBLOX_RIGHT_LEG then\n        state.applyingKorblox[char\x61cter] = true\n        description.RightLeg = KORBLOX_RIGHT_LEG\n   \x20    pcall(function() humanoid:ApplyDescription(description) end\x29\n        task.delay(.4, function()\n            state.applyingKorb\x6cox[character] = nil\n            if character.Parent then applyKo\x72bloxMesh(character) end\n            if state.headless and charac\x74er.Parent then applyHeadless(character) end\n        end)\n    end\n \x20  -- HumanoidDescription can be rejected or overwritten in live\x20games; direct R15 mesh fallback keeps the cosmetic visible.\n    \x61pplyKorbloxMesh(character)\n    applyHeadless(character)\nend\n\nlocal \x66unction restoreKorblox(character)\n    local originalRightLeg = c\x68aracter and state.korbloxOriginals[character]\n    local humanoid\x20= getHumanoid(character)\n    if not (humanoid and originalRightL\x65g ~= nil) then return end\n    local ok, description = pcall(func\x74ion() return humanoid:GetAppliedDescription() end)\n    if ok and\x20description then\n        description.RightLeg = originalRightLeg\n\x20       pcall(function() humanoid:ApplyDescription(description) \x65nd)\n    end\n    restoreKorbloxMesh(character)\n    state.korbloxOri\x67inals[character] = nil\nend\n\nlocal function applyCurrentCharacter()\n\x20   local character = LocalPlayer.Character\n    if state.korblox \x74hen applyKorblox(character) end\n    if state.headless then apply\x48eadless(character) end\nend\n\nlocal section = A.tab:AddSection(\"MAIN \\\x75{2022} FUN CLIENT\", \"Respawn-persistent local avatar cosmetics\")\nse\x63tion:AddToggle(\"Permanent Korblox (R15)\", function(enabled)\n    st\x61te.korblox = enabled == true\n    local character = LocalPlayer.C\x68aracter\n    if state.korblox then applyKorblox(character) else r\x65storeKorblox(character) end\nend)\nsection:AddToggle(\"Permanent Head\x6cess\", function(enabled)\n    state.headless = enabled == true\n    l\x6fcal character = LocalPlayer.Character\n    if state.headless then\x20applyHeadless(character) else restoreHeadless(character) end\nend\x29\nsection:AddLabel(\"Both looks are reapplied after each respawn. K\x6frblox requires an R15 character.\")\n\nLocalPlayer.CharacterAdded:Con\x6eect(function(character)\n    task.wait(.75)\n    applyKorblox(chara\x63ter)\n    applyHeadless(character)\nend)\nLocalPlayer.CharacterAppear\x61nceLoaded:Connect(function(character)\n    task.wait(.2)\n    if st\x61te.korblox then applyKorblox(character) end\n    if state.headles\x73 then applyHeadless(character) end\nend)\n-- Games may refresh an a\x76atar after it has spawned. Keep the two requested client cosmet\x69cs applied while enabled.\nif RunService then\n    -- Avatar refres\x68es only need to counter occasional game appearance writes; avoi\x64 doing mesh/head work every render frame.\n    local nextRefresh \x3d 0\n    RunService.Heartbeat:Connect(function()\n        local now \x3d os.clock()\n        if now < nextRefresh then return end\n        \x6eextRefresh = now + .45\n        local character = LocalPlayer.Cha\x72acter\n        if state.korblox then applyKorbloxMesh(character) \x65nd\n        if state.headless then applyHeadless(character) end\n  \x20 end)\nend\ntask.defer(applyCurrentCharacter)\n\n"
    local compiler = loadstring
    if type(compiler) ~= "\x66unction" then
        warn("\x5bNoir Avatar Cosmetics] loadstring is unavailable; cosmetic cont\x72ols could not be started.")
        return
    end
    local okCompile, moduleFn = pcall(compiler, __noirAvatarCosmeticsSource)
    if not okCompile or type(moduleFn) ~= "\x66unction" then
        warn("\x5bNoir Avatar Cosmetics] module compile failed: " .. tostring(moduleFn))
        return
    end
    local okRun, err = xpcall(moduleFn, function(message) return tostring(message) end)
    if not okRun then warn("\x5bNoir Avatar Cosmetics] module startup failed: " .. tostring(err)) end
end)




 
getgenv().__NoirEmotesContext = {
    container = emotesContent,
    theme = { base = C.base, panel = C.panel, surface = C.surface, card = C.card, button = C.btn, accent = C.accent, text = C.text, dim = C.dim, border = C.border },
    SetCanvasHeight = function(height)
        emotesContent.CanvasSize = UDim2.fromOffset(0, math.max(200, tonumber(height) or 664))
    end,
    Notify = function(textValue, duration) notify("\x45motes: " .. tostring(textValue), duration or 3) end,
}
task.defer(function()
    local __noirEmotesSource = "\x2d- 7yd7 Emotes — Overdrive H plugin + responsive thumbnail card b\x72owser.\n-- Original: https://github.com/7yd7/Hub/blob/Branch/GUIS\x2fEmotes.lua\n-- Catalog: 7yd7/sniper-Emote, EmoteSniper.json. No r\x65mote Lua execution.\n-- Separate card GUI; original animation bun\x64les/themes/HUD editor are not included.\n-- R15 only. Asset permi\x73sions and replication remain controlled by Roblox/the game.\n-- I\x6etegrated into Noir's native Emotes tab. The catalog source stay\x73 data-only; no remote Lua is executed.\nlocal shared=getgenv().__\x4eoirEmotesContext\nlocal container=shared and shared.container\nif n\x6ft shared or not (container and typeof(container)==\"Instance\") the\x6e\n    warn(\"[Noir Emotes] native Emotes tab container unavailable.\"\x29\n    return\nend\nlocal KEY=\"Noir_7yd7_EmotesRuntime_v1\"\nlocal previous\x3d_G[KEY]\nif type(previous)==\"table\" and previous.alive and type(pre\x76ious.Cleanup)==\"function\" then\n    pcall(previous.Cleanup)\nend\nlocal\x20Players=game:GetService(\"Players\")\nlocal Player=Players.LocalPlaye\x72\nif not Player then warn(\"[ODH Emotes] LocalPlayer unavailable.\");\x72eturn end\nlocal HttpService=game:GetService(\"HttpService\")\nlocal Ru\x6eService=game:GetService(\"RunService\")\nlocal UIS=game:GetService(\"Us\x65rInputService\")\nlocal runtime={version=7,alive=true,initializing=\x74rue,generation=0,filterGeneration=0,page=1,catalog={},filtered=\x7b},resolutions={},connections={}}\nlocal prefs={windowTransparency\x3d22,thumbnailSize=68,thumbnailPresetVersion=2,playbackModeVersio\x6e=2,shortcuts={},browserOnLoad=false,loop=false,walk=false,speed\x3d1,favoritesOnly=false,query=\"\",customId=\"\",customKind=\"Catalog emote\x20ID\",favorites={}}\nlocal FILE=\"ODH_Emotes_settings.json\"\nlocal CACHE=\"\x4fDH_Emotes_catalog.json\"\nlocal URL=\"https://raw.githubusercontent.c\x6fm/7yd7/sniper-Emote/refs/heads/test/EmoteSniper.json\"\nlocal PAGE_\x53IZE=12\nlocal MAX_SHORTCUTS=12\nlocal warnings={}\nlocal function Not\x69fy(text)\n    if type(shared.Notify)==\"function\" then pcall(shared.\x4eotify,\"Emotes: \"..text,5) end\nend\nlocal function WarnOnce(key,text)\n\x20   if warnings[key] then return end\n    warnings[key]=true;warn(\"\x5bODH Emotes] \"..text);Notify(text)\nend\nlocal env={}\nif type(getgenv)\x3d=\"function\" then\n    local ok,value=pcall(getgenv)\n    if ok and ty\x70e(value)==\"table\" then env=value end\nend\nlocal read=type(readfile)=\x3d\"function\" and readfile or env.readfile\nlocal write=type(writefile\x29==\"function\" and writefile or env.writefile\nlocal exists=type(isfi\x6ce)==\"function\" and isfile or env.isfile\nlocal canSave=type(read)==\"\x66unction\" and type(write)==\"function\"\nruntime.settingsFile=FILE\nrunti\x6de.saveStatus=canSave and \"Not saved\" or \"Session only\"\nruntime.prefe\x72ences=prefs\nlocal function AssetId(value)\n    if type(value)~=\"num\x62er\" and type(value)~=\"string\" then return nil end\n    local id=tonu\x6dber(value)\n    if id and id==id and id>0 and id<9007199254740992\x20and id==math.floor(id) then return id end\nend\nlocal function IdTe\x78t(id) return string.format(\"%.0f\",id) end\nlocal function ParseId(t\x65xt)\n    if type(text)~=\"string\" then return nil end\n    local digit\x73=text:match(\"^%s*(%d+)%s*$\") or text:match(\"^rbxassetid://(%d+)$\")\n \x20      or text:match(\"[?&]id=(%d+)\") or text:match(\"roblox%.com/cat\x61log/(%d+)\")\n    return digits and AssetId(digits)\nend\nlocal functio\x6e Item(value)\n    if type(value)~=\"table\" then return nil end\n    lo\x63al id=AssetId(value.id)\n    if not id then return nil end\n    loc\x61l name=type(value.name)==\"string\" and value.name:gsub(\"[%c]\",\" \") or \x28\"Emote \"..IdText(id))\n    if #name==0 or #name>2000 then name=\"Emot\x65 \"..IdText(id) end\n    return {id=id,name=name}\nend\nlocal function \x52eadJSON(path)\n    if type(read)~=\"function\" then return nil,\"unavai\x6cable\" end\n    if type(exists)==\"function\" then\n        local ok,foun\x64=pcall(exists,path)\n        if ok and not found then return nil,\"\x6dissing\" end\n    end\n    local ok,text=pcall(read,path)\n    if not o\x6b then return nil,\"read error\" end\n    local decoded,data=pcall(fun\x63tion() return HttpService:JSONDecode(text) end)\n    if not decod\x65d or type(data)~=\"table\" then return nil,\"invalid JSON\" end\n    retu\x72n data\nend\nlocal function LoadSettings()\n    if not canSave then W\x61rnOnce(\"files\",\"readfile/writefile unavailable; settings are sessi\x6fn-only.\");return end\n    local data,err=ReadJSON(FILE)\n    if not \x64ata then\n        if err~=\"missing\" then WarnOnce(\"read\",\"Settings not\x20loaded (\"..tostring(err)..\"). Existing file is kept until you cha\x6ege a setting.\") end\n        return\n    end\n    if data.version~=1 o\x72 type(data.values)~=\"table\" then\n        WarnOnce(\"read\",\"Invalid set\x74ings; existing file is kept until you change a setting.\");return\n\x20   end\n    local values=data.values\n    -- Migrate the old forced\x2fdefault Loop ON without discarding other settings.\n    if values\x2eplaybackModeVersion==2 and type(values.loop)==\"boolean\" then pref\x73.loop=values.loop end\n    if type(values.shortcuts)==\"table\" then\n \x20      local count=0\n        for _,value in pairs(values.shortcut\x73) do\n            local item=Item(value)\n            if item then\n \x20              local function position(number,default)\n          \x20         if type(number)==\"number\" and number==number and number>\x2dmath.huge and number<math.huge then\n                        retu\x72n math.clamp(number,0,1)\n                    end\n                \x20   return default\n                end\n                item.x=posi\x74ion(value.x,.75);item.y=position(value.y,.45)\n                pr\x65fs.shortcuts[IdText(item.id)]=item;count=count+1\n               \x20if count>=MAX_SHORTCUTS then break end\n            end\n        en\x64\n    end\n    for key,limits in pairs({windowTransparency={0,50},t\x68umbnailSize={50,100}}) do\n        local value=values[key]\n       \x20if type(value)==\"number\" and value==value and value>-math.huge an\x64 value<math.huge then\n            prefs[key]=math.clamp(value,li\x6dits[1],limits[2])\n        end\n    end\n    if values.thumbnailPrese\x74Version~=2 and prefs.thumbnailSize==78 then prefs.thumbnailSize\x3d68 end\n    for _,key in ipairs({\"walk\",\"favoritesOnly\",\"browserOnLoad\"\x7d) do\n        if type(values[key])==\"boolean\" then prefs[key]=value\x73[key] end\n    end\n    if type(values.speed)==\"number\" and values.sp\x65ed==values.speed and values.speed>-math.huge and values.speed<m\x61th.huge then prefs.speed=math.clamp(values.speed,0,3) end\n    if\x20type(values.query)==\"string\" then prefs.query=values.query:sub(1,\x3200) end\n    if type(values.customId)==\"string\" and #values.customI\x64<=200 then prefs.customId=values.customId end\n    if values.cust\x6fmKind==\"Animation ID\" then prefs.customKind=values.customKind end\n\x20   prefs.selected=Item(values.selected)\n    if type(values.favor\x69tes)==\"table\" then\n        local count=0\n        for _,value in pai\x72s(values.favorites) do\n            local item=Item(value)\n       \x20    if item then prefs.favorites[IdText(item.id)]=item;count=co\x75nt+1 end\n            if count>=10000 then break end\n        end\n  \x20 end\n    runtime.saveStatus=\"Loaded\"\nend\nlocal function SaveSettings\x28)\n    if runtime.initializing or not runtime.alive or not canSav\x65 then return false end\n    local ok,err=pcall(function() write(F\x49LE,HttpService:JSONEncode({version=1,values=prefs})) end)\n    if\x20not ok then runtime.saveStatus=\"Write error\";WarnOnce(\"write\",\"Canno\x74 save settings: \"..tostring(err));return false end\n    runtime.sa\x76eStatus=\"Saved\";warnings.write=nil;return true\nend\nLoadSettings()\n\nlo\x63al BUILTIN={\n    {id=3360689775,name=\"Salute\"},\n    {id=5915779043,\x6eame=\"Applaud\"},\n    {id=3360692915,name=\"Tilt\"},\n    {id=15610015346,\x6eame=\"Yungblud Happier Jump\"},\n    {id=14353423348,name=\"Baby Queen \x2d Bouncy Twirl\"},\n    {id=14353421343,name=\"Baby Queen - Face Frame\"\x7d,\n    {id=3823158750,name=\"Godlike\"},\n    {id=139021427684680,name=\"\x4bATSEYE - Touch\"},\n    {id=133596366979822,name=\"Biblically Accurat\x65 Emote\"},\n    {id=108128682361404,name=\"Rambunctious\"},\n    {id=7912\x37989560307,name=\"Moon Walk\"},\n    {id=5230661597,name=\"Bored\"},\n    {i\x64=14353425085,name=\"Baby Queen - Strut\"},\n    {id=15694504637,name=\"\x644vd - Backflip\"},\n    {id=104142334418357,name=\"[Original] It's Ga\x6egnam Style!\"},\n    {id=16553249658,name=\"Mae Stephens - Piano Hand\x73\"},\n    {id=12507097350,name=\"Alo Yoga Pose - Lotus Position\"},\n    \x7bid=15698511500,name=\"Cuco - Levitate\"},\n    {id=4689362868,name=\"Sl\x65ep\"},\n    {id=111426928948833,name=\"Floating on clouds\"},\n    {id=13\x30245358716273,name=\"The Weeknd Starboy Strut\"},\n    {id=12064251415\x36293,name=\"Secret Handshake Dance\"},\n    {id=15506503658,name=\"Victo\x72y Dance\"},\n    {id=3576717965,name=\"Shy\"},\n    {id=73796726960568,na\x6de=\"Nyan Nyan! \"},\n    {id=78758922757947,name=\"Kicking Feet Sit\"},\n  \x20 {id=93511411593120,name=\"/e fly\"},\n    {id=114899970878842,name=\"R\x315 Death (Accurate)\"},\n    {id=5104377791,name=\"Hero Landing\"},\n    {\x69d=5917570207,name=\"Floss Dance\"},\n    {id=131763631172236,name=\"Xav\x69ersobased Emote\"},\n    {id=132074413582912,name=\"California Girl D\x61nce\"},\n    {id=15554010118,name=\"Olivia Rodrigo Head Bop\"},\n    {id=\x3112758073578333,name=\"Bubbly Sit\"},\n    {id=3716636630,name=\"Monkey\"}\x2c\n    {id=123015710605336,name=\"Onion\"},\n    {id=4646306583,name=\"Cur\x74sy\"},\n    {id=85936805522788,name=\"Caramell\"},\n    {id=14900153406,n\x61me=\"TWICE Feel Special\"},\n    {id=102492229412911,name=\"Deltarune -\x20Tenna Dance\"},\n    {id=133142324349281,name=\"Flopping Fish\"},\n    {i\x64=10214406616,name=\"Frosty Flair - Tommy Hilfiger\"},\n    {id=120224\x3229260879,name=\"Cute crouch \"},\n    {id=15679955281,name=\"Festive Da\x6ece\"},\n    {id=4849502101,name=\"Sad\"},\n    {id=10214418283,name=\"V Pos\x65 - Tommy Hilfiger\"},\n    {id=92853367837757,name=\"Garry's Dance\"},\n \x20  {id=104485625389237,name=\"Make You Mine\"},\n    {id=1398307337825\x318,name=\"Phut On\"},\n    {id=132382355371060,name=\"Tank Transformatio\x6e\"},\n    {id=103046131635200,name=\"Scenario - LOVE SCENARIO\"},\n    {i\x64=15123050663,name=\"Bone Chillin' Bop\"},\n    {id=124305244640379,na\x6de=\"Shattered\"},\n    {id=134311528115559,name=\"how did he hit every \x62eat\"},\n    {id=17748346932,name=\"Elton John - Heart Shuffle\"},\n    {\x69d=93105950995997,name=\"Caramelldansen\"},\n    {id=7466046574,name=\"Q\x75iet Waves\"},\n    {id=96557878503341,name=\"Caramell Dansen\"},\n    {id\x3d139859849852362,name=\"Dead\"},\n    {id=17360720445,name=\"HUGO Let's \x44rive!\"},\n    {id=103102322875221,name=\"Skibidi Toilet - Titan Spea\x6berman Laser Spin\"},\n    {id=3576968026,name=\"Shrug\"},\n    {id=130998\x3336536045,name=\"Gangnam Style\"},\n    {id=84555218084038,name=\"Helico\x70ter Spin\"},\n    {id=71302743123422,name=\"Popular\"},\n    {id=13376501\x35173412,name=\"DearALICE - Ariana\"},\n    {id=115319301809339,name=\"2 \x50hut Hon Dance\"},\n    {id=70635223083942,name=\"Be Not Afraid\"},\n    {\x69d=17746270218,name=\"Sturdy Dance - Ice Spice\"},\n    {id=1291494029\x322241,name=\"griddy\"},\n    {id=3576686446,name=\"Hello\"},\n    {id=113547\x3795536875,name=\"Gangnam Style\"},\n    {id=126614732606871,name=\"Sit\"},\n\x20   {id=3762654854,name=\"Greatest\"},\n    {id=16572756230,name=\"HIPMO\x54ION - Amaarae\"},\n    {id=16276506814,name=\"Sol de Janeiro - Samba\"}\x2c\n    {id=3576823880,name=\"Point2\"},\n    {id=78459263478161,name=\"Fam\x69ly Man Death Pose\"},\n    {id=14900151704,name=\"TWICE LIKEY\"},\n    {i\x64=3360686498,name=\"Stadium\"},\n    {id=15571540519,name=\"Nicki Minaj \x53tarships\"},\n    {id=4940597758,name=\"Cower\"},\n    {id=11394056822,na\x6de=\"Elton John - Elevate\"},\n    {id=117734400993750,name=\"Virtual Si\x6eger Dance\"},\n    {id=97263450325496,name=\"Teto Territory\"},\n    {id=\x34102315500,name=\"Haha\"},\n    {id=79312439851071,name=\"Chappell Roan \x48OT TO GO!\"},\n    {id=105851216004006,name=\"Electro Swing\"},\n    {id=\x392707348383277,name=\"Mesmerizer\"},\n    {id=103139492736941,name=\"Del\x74arune - Tenna Swing Dance\"},\n    {id=15571538346,name=\"Nicki Minaj\x20Boom Boom Boom\"},\n    {id=15554016057,name=\"Olivia Rodrigo Fall Ba\x63k to Float\"},\n    {id=70615023659736,name=\"Floating\"},\n    {id=13674\x30085081295,name=\"/e hidden animation\"},\n    {id=119431985170060,nam\x65=\"Helicopter\"},\n    {id=87141651594092,name=\"No-Clip/Speed Glitch\"},\n\x20   {id=16303091119,name=\"Beauty Touchdown\"},\n    {id=3934986896,na\x6de=\"Dizzy\"},\n    {id=130726889233022,name=\"rolling crybaby\"},\n    {id=\x311309263077,name=\"Elton John - Heart Skip\"},\n    {id=84511772437190\x2cname=\"Emote Loading. Please Wait... | spinning Robloxian\"},\n    {i\x64=14353417553,name=\"Baby Queen - Air Guitar & Knee Slide\"},\n    {id\x3d15392927897,name=\"Paris Hilton - Sliving For The Groove\"},\n    {id\x3d94796833553521,name=\"TWICE Takedown pt 1 from Kpop Demon Hunters\"\x7d,\n    {id=120437019363089,name=\"peter griffin death pose\"},\n    {id\x3d15506506103,name=\"Flex Walk\"},\n    {id=90608224567833,name=\"Proud t\x6f be Expendable - Pressure\"},\n    {id=18526338976,name=\"Team USA Br\x65aking Emote\"},\n    {id=99818263438846,name=\"Default Dance\"},\n    {id\x3d103197720369544,name=\"Dani's Gangnam Style\"},\n    {id=750178573956\x337,name=\"TV Time Dance\"},\n    {id=73683655527605,name=\"Fashion Roadk\x69ll\"},\n    {id=15392932768,name=\"Paris Hilton - Iconic IT-Grrrl\"},\n  \x20 {id=82217023310738,name=\"Thanos Happy Jump - Squid Game\"},\n    {i\x64=102610758906338,name=\"Possessed\"},\n    {id=95323795166399,name=\"Ra\x74 Dance\"},\n    {id=127562607220778,name=\"Gangnam Style \"},\n    {id=12\x39132611803602,name=\"Helicopter\"},\n    {id=82345302788133,name=\"Dia D\x65licia Dance\"},\n    {id=15392937495,name=\"Paris Hilton - Checking M\x79 Angles\"},\n    {id=4212496830,name=\"Zombie\"},\n    {id=11301643801225\x33,name=\"⌛ Best Mates EMOTE [LIMITED]\"},\n    {id=110537281410647,name\x3d\"[Aura Farm] Wall Lean Idle\"},\n    {id=92903522317071,name=\"ILLIT -\x20Magnetic\"},\n    {id=122899100558551,name=\"It's TV Time!\"},\n    {id=7\x35528418031928,name=\"Rambunctious\"},\n    {id=103040723950430,name=\"Go\x6ao Floating\"},\n    {id=70788193750089,name=\"Kickn around\"},\n    {id=5\x3915776835,name=\"High Wave\"},\n    {id=84195923658292,name=\"Jojo\"},\n    \x7bid=110731335896907,name=\"[⌛ Limited]  HEADLESS EMOTE \"},\n    {id=13\x39271706064778,name=\"Hip Bounce\"},\n    {id=4849499887,name=\"Happy\"},\n  \x20 {id=127271798262177,name=\"M3GAN's Dance\"},\n    {id=10430418234456\x37,name=\"ONCE HOP HOP!\"},\n    {id=85623000473425,name=\"TWICE Takedown\x20pt 2 from KPop Demon Hunters\"},\n    {id=84067050907557,name=\"Pickl\x65 Rick Dance\"},\n    {id=86982022610765,name=\"Caramelldansen\"},\n    {i\x64=117301403779781,name=\"Im Talm Bout Innit\"},\n    {id=8482228441081\x34,name=\"Maraschino Step\"},\n    {id=97847706148165,name=\"[NEW !] Cara\x6delldansen Kawaii Dance\"},\n    {id=89174456614428,name=\"Laying Down\x20- Daydreaming\"},\n    {id=91023138078288,name=\"OH WHO IS YOU\"},\n    {\x69d=107978036345855,name=\"Prince Of Egypt Dance / What You Want\"},\n \x20  {id=71363859760586,name=\"Golden Freddy Pose\"},\n    {id=808777725\x369772,name=\"Default Dance | OG\"},\n    {id=80436375269036,name=\"HEADL\x45SS HOOPER\"},\n    {id=93262662842394,name=\"Sit\"},\n    {id=75703899901\x3487,name=\"6 7 Transformation\"},\n    {id=100773414188482,name=\"Stray \x4bids Walkin On Water\"},\n    {id=131544122623505,name=\"Become A Car!\"\x7d,\n    {id=99005087791705,name=\"Death Pose\"},\n    {id=13238470170604\x36,name=\"💀MM2 Fake Dead\"},\n    {id=129916107176034,name=\"Discombobulat\x65d\"},\n    {id=88598010609888,name=\"Angry Stomp \"},\n    {id=1325088677\x359412,name=\"xavier so based emote\"},\n    {id=121167704249654,name=\"H\x69de\"},\n    {id=137873580964093,name=\"Floating Human Spinner (LIMITE\x44) \"},\n    {id=76700167742736,name=\"Belly Dance\"},\n    {id=8782689259\x36287,name=\"levitate\"},\n    {id=70972410468289,name=\"Fake Dead (Troll\x20Emote)\"},\n    {id=134615135651900,name=\"Young-hee Head Spin - Squi\x64 Game\"},\n    {id=13823339506,name=\"Tommy - Archer\"},\n    {id=1097554\x376052324,name=\"IShowSpeed Dance\"},\n    {id=124828909173982,name=\"Ski\x62idi\"},\n    {id=4272351660,name=\"Fast Hands\"},\n    {id=13700608577940\x38,name=\"Speed Glitch+\"},\n    {id=89633087256727,name=\"Weird Spin\"},\n  \x20 {id=125032357496729,name=\"Fake Death (BEST)\"},\n    {id=8117729428\x37826,name=\"Hug\"},\n    {id=88721672617892,name=\"P.B.J.T.\"},\n    {id=121\x3259524934987,name=\"Xaviersobased Jig\"},\n    {id=121067808279598,nam\x65=\"PARROT PARTY DANCE\"},\n    {id=7202898984,name=\"Show Dem Wrists - \x4bSI\"},\n    {id=120377619472998,name=\"Macarena\"},\n    {id=4940602656,n\x61me=\"Jumping Wave\"},\n    {id=94663026124741,name=\"Torture Dance\"},\n   \x20{id=120896030393583,name=\"Get Sturdy\"},\n    {id=137261874619072,na\x6de=\"Sponge Dance\"},\n    {id=119746055344304,name=\"Plane\"},\n    {id=786\x320443286892,name=\"Cute Laying Down\"},\n    {id=108922782921118,name=\"📸\x20Pose for the Pic \"},\n    {id=131221550165951,name=\"Heart Hands Pos\x65 3.0\"},\n    {id=119454955259757,name=\"Caramel Hip Sway\"},\n    {id=72\x302900159,name=\"Wake Up Call - KSI\"},\n    {id=79752538807060,name=\"Gr\x69ddy\"},\n    {id=140466682449054,name=\"head spin\"},\n    {id=1078999546\x396611,name=\"Spongebob Shuffle Dance 🧽\"},\n    {id=96405718067779,name\x3d\"Cute Sit\"},\n    {id=4849497510,name=\"Power Blast\"},\n    {id=89413575\x3288931,name=\"Blue Shirt Guy Dancing\"},\n    {id=112924687333965,name\x3d\"Aura Farm\"},\n    {id=100782362883099,name=\"Car Transformation\"},\n   \x20{id=102323907950469,name=\"Space Dance\"},\n    {id=110521067391235,n\x61me=\"The Old Jitterbug\"},\n    {id=111304332281521,name=\"Druski Shuff\x6ce\"},\n    {id=133600250245899,name=\"🥤 Soda Pop - Saja Boys\"},\n    {id=\x3133477296392756,name=\"Rasputin – Boney M.\"},\n    {id=122949892043249\x2cname=\"[Aura Farm] Sit Idle\"},\n    {id=82739386299071,name=\"Jackpot \x47roove\"},\n    {id=80422524668416,name=\"Dreamer\"},\n    {id=97968838104\x3258,name=\"Subject Three / AI Cat Chinese Dance\"},\n    {id=912747612\x364433,name=\"Macarena\"},\n    {id=3994130516,name=\"Bodybuilder\"},\n    {i\x64=5938365243,name=\"Dolphin Dance\"},\n    {id=99563839802389,name=\"Jum\x70style\"},\n    {id=85361710130557,name=\"Caramelldansen\"},\n    {id=7464\x36784680842,name=\"Ishowspeed shake \"},\n    {id=5230615437,name=\"Becko\x6e\"},\n    {id=135489824748823,name=\"Magical Pose\"},\n    {id=9860399471\x33783,name=\"Rat Dance\"},\n    {id=14353419229,name=\"Baby Queen - Drama\x74ic Bow\"},\n    {id=84052327668385,name=\"Floating\"},\n    {id=979993703\x392804,name=\"Spin my Head\"},\n    {id=94319114655768,name=\"Rat Dance\"},\n\x20   {id=86849720336961,name=\"Mr. Ant Tennas Dance - DELTARUNE\"},\n  \x20 {id=124754178569693,name=\"Die Lit!\"},\n    {id=80544397800234,name\x3d\"Helicopter\"},\n    {id=100532972764499,name=\"MONSTER MASH\"},\n    {id=\x388922397617835,name=\"What You Want\"},\n    {id=115810068374896,name=\"\x47arry's Dance\"},\n    {id=75842745124834,name=\"Human Snake\"},\n    {id=\x394451497143711,name=\"Hakari Dance\"},\n    {id=128972617664804,name=\"F\x6frtnite Default Dance\"},\n    {id=73556976257737,name=\"Saja Boy Pose\x20- Jinu\"},\n    {id=81390693780805,name=\"PROXIMA\"},\n    {id=1700005893\x39,name=\"Mini Kong\"},\n    {id=97629500912487,name=\"BlockyKick Dance\"},\n\x20   {id=112949099442762,name=\"Griddy\"},\n    {id=130641944883645,nam\x65=\" Jinu Pose - Saja Boys\"},\n    {id=108474079699304,name=\"Dep\"},\n    \x7bid=4049646104,name=\"Line Dance\"},\n    {id=91423783304464,name=\"cris\x73 cross sit\"},\n    {id=90524692306889,name=\"[⏳] Chill Sit\"},\n    {id=1\x35506496093,name=\"Rock n Roll\"},\n    {id=134737246939931,name=\"GAG IT\x20DEATH DROP\"},\n    {id=71787387963141,name=\"Worm Dance\"},\n    {id=128\x3658037413893,name=\"I'm Going To Die Here - Pressure\"},\n    {id=9956\x38437064777,name=\"Relaxed Sit\"},\n    {id=83018514370428,name=\"Stargaz\x69ng\"},\n    {id=92859581691366,name=\"ALTÉGO - Couldn’t Care Less\"},\n    \x7bid=94534169345613,name=\"Casual Sit\"},\n    {id=16126526506,name=\"Par\x69s Hilton Sanasa\"},\n    {id=140037329261678,name=\"Caramel dance\"},\n  \x20 {id=94118707925458,name=\"Go Mufasa\"},\n    {id=105730788757021,nam\x65=\"Dani's BIRDBRAIN\"},\n    {id=91927498467600,name=\"Koto Nai Meme Da\x6ece\"},\n    {id=117450501566142,name=\"Hide Hidden Box Invisible Camo\x20Emote Small tiny\"},\n    {id=4272484885,name=\"Baby Dance\"},\n    {id=8\x38024974500195,name=\"Oppa Gangnam Style\"},\n    {id=7202896732,name=\"B\x6fxing Punch - KSI\"},\n    {id=128792127841374,name=\"Watching silly v\x69deos (Or texting)\"},\n    {id=87756443172440,name=\"xavier so based \x64ance\"},\n    {id=116770268279002,name=\"BirdBrain Teto\"},\n    {id=1249\x335873390035,name=\"Hiding Human Box\"},\n    {id=94121796810251,name=\"K\x69cking Feet And Blushing\"},\n}\n\nlocal statusLabel,catalogLabel,select\x65dLabel,searchLabel,customLabel\nlocal function Label(control,text\x29\n    if control then pcall(function() control:SetValue(text) end\x29 end\nend\nlocal function Status(text)\n    runtime.status=text;Label\x28statusLabel,text)\n    if runtime.UpdateCardStatus then runtime.U\x70dateCardStatus() end\nend\nlocal function Dispose(track,animation)\n \x20  if track then\n        pcall(function() track:Stop(0) end)\n     \x20  pcall(function() track:Destroy() end)\n    end\n    if animation \x74hen pcall(function() animation:Destroy() end) end\nend\nlocal funct\x69on StopCurrent(message)\n    runtime.generation=runtime.generatio\x6e+1\n    if runtime.endedConnection then runtime.endedConnection:D\x69sconnect();runtime.endedConnection=nil end\n    local track,anima\x74ion=runtime.track,runtime.animation\n    runtime.track=nil;runtim\x65.animation=nil;runtime.character=nil;runtime.playing=nil\n    Dis\x70ose(track,animation)\n    if message then Status(message) end\nend\nr\x75ntime.Stop=function() StopCurrent(\"Stopped\") end\nlocal function Cu\x72rent(ticket,character)\n    return runtime.alive and runtime.gene\x72ation==ticket and Player.Character==character\nend\nlocal function \x52esolveCatalog(id)\n    if runtime.resolutions[id] then return run\x74ime.resolutions[id] end\n    local ok,objects=pcall(function() re\x74urn game:GetObjects(\"rbxassetid://\"..IdText(id)) end)\n    if not o\x6b or type(objects)~=\"table\" then return nil end\n    local resolved\n \x20  -- Loaded objects stay unparented. Scripts in an asset are ne\x76er executed.\n    pcall(function()\n        for _,root in ipairs(ob\x6aects) do\n            if root:IsA(\"Animation\") then resolved=ParseI\x64(root.AnimationId) end\n            if not resolved then\n         \x20      local descendants=root:GetDescendants()\n                fo\x72 i,obj in ipairs(descendants) do\n                    if i>4000 t\x68en break end\n                    if obj:IsA(\"Animation\") then reso\x6cved=ParseId(obj.AnimationId);if resolved then break end end\n    \x20           end\n            end\n            if resolved then break\x20end\n        end\n    end)\n    for _,root in ipairs(objects) do pcal\x6c(function() root:Destroy() end) end\n    if resolved then runtime\x2eresolutions[id]=resolved end\n    return resolved\nend\nlocal functio\x6e Play(item,direct)\n    if not runtime.alive then return end\n    i\x66 not item or not AssetId(item.id) then Notify(\"Select an emote o\x72 enter a valid ID first.\");return end\n    StopCurrent()\n    local \x74icket=runtime.generation\n    local character=Player.Character\n   \x20if not character then Status(\"Waiting for character — press Play \x61fter spawning\");return end\n    Status(\"Loading: \"..item.name)\n    ta\x73k.spawn(function()\n        local track,animation\n        local ok\x2cerr=pcall(function()\n            if not Current(ticket,character\x29 then return end\n            local humanoid=character:FindFirstC\x68ildOfClass(\"Humanoid\") or character:WaitForChild(\"Humanoid\",8)\n     \x20      if not Current(ticket,character) then return end\n         \x20  if not humanoid or humanoid.Health<=0 then error(\"Character is\x20not ready\") end\n            if humanoid.RigType~=Enum.HumanoidRig\x54ype.R15 then error(\"R15 character required\") end\n            local\x20animator=humanoid:FindFirstChildOfClass(\"Animator\") or humanoid:W\x61itForChild(\"Animator\",8)\n            if not Current(ticket,charact\x65r) then return end\n            if not animator then error(\"Animat\x6fr is not ready\") end\n            local animationId=direct and ite\x6d.id or ResolveCatalog(item.id)\n            if not Current(ticket\x2ccharacter) then return end\n            if not animationId and no\x74 direct then\n                -- Roblox's native emote API is a f\x61llback when GetObjects is unavailable.\n                local nat\x69veOK,nativeTrack=pcall(function() return humanoid:PlayEmoteAndG\x65tAnimTrackById(item.id) end)\n                if nativeOK and nat\x69veTrack and typeof(nativeTrack)==\"Instance\" and nativeTrack:IsA(\"A\x6eimationTrack\") then track=nativeTrack end\n                if not \x43urrent(ticket,character) then return end\n            end\n        \x20   if not track then\n                animation=Instance.new(\"Anim\x61tion\")\n                animation.AnimationId=\"rbxassetid://\"..IdTex\x74(animationId or item.id)\n                track=animator:LoadAnim\x61tion(animation)\n            end\n            if not Current(ticket\x2ccharacter) then return end\n            if not track then error(\"R\x6fblox did not return an animation track\") end\n            track.Pr\x69ority=Enum.AnimationPriority.Action\n            track.Looped=pre\x66s.loop\n            if not track.IsPlaying then track:Play(0.05,1\x2cprefs.speed) else track:AdjustSpeed(prefs.speed) end\n           \x20runtime.track=track;runtime.animation=animation;runtime.charact\x65r=character\n            runtime.playing=item\n            runtime.\x65ndedConnection=track.Ended:Connect(function()\n                if\x20runtime.track==track and Current(ticket,character) then StopCur\x72ent(\"Finished: \"..item.name) end\n            end)\n            -- Lo\x61dAnimation may return a track even for an inaccessible/deleted \x61sset.\n            local deadline=os.clock()+8\n            while C\x75rrent(ticket,character) and runtime.track==track and track.Leng\x74h<=0 and os.clock()<deadline do task.wait(0.1) end\n            i\x66 not Current(ticket,character) or runtime.track~=track then ret\x75rn end\n            if track.Length<=0 then error(\"Animation did n\x6ft load. It may be restricted, deleted, or incompatible.\") end\n   \x20        Status(\"Playing: \"..item.name)\n        end)\n        if not \x43urrent(ticket,character) then\n            -- A newer click/Stop/\x72espawn wins even if GetObjects/LoadAnimation yielded.\n          \x20 if runtime.track~=track then Dispose(track,animation) end\n     \x20      return\n        end\n        if not ok then\n            if run\x74ime.track==track then StopCurrent() else Dispose(track,animatio\x6e) end\n            Status(\"Cannot play this emote\")\n            Noti\x66y(tostring(err))\n        end\n    end)\nend\nruntime.Play=function(id,\x6eame,direct) Play({id=id,name=name or IdText(id)},direct==true) \x65nd\nruntime.SaveSettings=SaveSettings\nruntime.connections[#runtime\x2econnections+1]=Player.CharacterAdded:Connect(function()\n    Stop\x43urrent(\"Respawned — select an emote and press Play\")\nend)\nruntime.co\x6enections[#runtime.connections+1]=RunService.Heartbeat:Connect(f\x75nction()\n    if not runtime.alive or not runtime.track then retu\x72n end\n    local character=runtime.character\n    local humanoid=ch\x61racter and character:FindFirstChildOfClass(\"Humanoid\")\n    if Play\x65r.Character~=character or not humanoid or humanoid.Health<=0 th\x65n StopCurrent(\"Stopped\");return end\n    if not prefs.walk and huma\x6eoid.MoveDirection.Magnitude>0.05 then StopCurrent(\"Stopped on mo\x76ement\") end\nend)\nfunction runtime.Cleanup()\n    runtime.alive=false\x3bruntime.filterGeneration=runtime.filterGeneration+1\n    StopCurr\x65nt()\n    for _,connection in ipairs(runtime.connections) do conn\x65ction:Disconnect() end\n    if runtime.DestroyBrowser then runtim\x65.DestroyBrowser() end\nend\n\nlocal dropdown,pageLabel\nlocal displayed\x3d{}\nlocal syncing=false\nlocal SENTINEL=\"— Select an emote —\"\nlocal func\x74ion NormalizeCatalog(data)\n    if type(data)~=\"table\" then return \x6eil end\n    local source=type(data.data)==\"table\" and data.data or \x64ata\n    local items,seen={},{}\n    for i,value in ipairs(source) \x64o\n        if i>100000 then break end\n        local item=Item(valu\x65)\n        if item and not seen[item.id] then\n            seen[ite\x6d.id]=true;items[#items+1]=item\n        end\n    end\n    return #ite\x6ds>0 and items or nil\nend\nlocal function SelectionLabel()\n    local\x20item=prefs.selected\n    Label(selectedLabel,item and (\"Selected: \"\x2e.item.name..\" [\"..IdText(item.id)..\"]\") or \"Selected: none\")\n    if ru\x6etime.UpdateCardStatus then runtime.UpdateCardStatus() end\nend\nloc\x61l function RenderPage()\n    if not runtime.alive then return end\n\x20   local pages=math.max(1,math.ceil(#runtime.filtered/PAGE_SIZE\x29)\n    runtime.page=math.clamp(runtime.page,1,pages)\n    local nam\x65s={SENTINEL}\n    displayed={}\n    local selectedText=SENTINEL\n    \x66or i=(runtime.page-1)*PAGE_SIZE+1,math.min(runtime.page*PAGE_SI\x5aE,#runtime.filtered) do\n        local item=runtime.filtered[i]\n  \x20     local text=item.name..\" [\"..IdText(item.id)..\"]\"\n        names[\x23names+1]=text;displayed[text]=item\n        if prefs.selected and\x20prefs.selected.id==item.id then selectedText=text end\n    end\n   \x20if dropdown then\n        syncing=true\n        local ok,err=pcall(\x66unction() dropdown:ChangeItems(names);dropdown:Select(selectedT\x65xt) end)\n        syncing=false\n        if not ok then WarnOnce(\"dr\x6fpdown\",\"Could not update the emote list: \"..tostring(err)) end\n    \x65nd\n    Label(pageLabel,\"Page \"..runtime.page..\" / \"..pages..\" • matche\x73: \"..#runtime.filtered..\" • catalog: \"..#runtime.catalog)\n    Select\x69onLabel()\n    if runtime.RenderCards then runtime.RenderCards() \x65nd\nend\nlocal function Filter(resetPage)\n    runtime.filterGenerati\x6fn=runtime.filterGeneration+1\n    local ticket=runtime.filterGene\x72ation\n    local query=prefs.query:lower()\n    local favoritesOnly\x3dprefs.favoritesOnly\n    local source=runtime.catalog\n    if favor\x69tesOnly then\n        source={}\n        for _,item in pairs(prefs.\x66avorites) do source[#source+1]=item end\n        table.sort(sourc\x65,function(a,b) return a.name:lower()<b.name:lower() end)\n    end\n\x20   local words={}\n    for word in query:gmatch(\"%S+\") do words[#wo\x72ds+1]=word end\n    runtime.filtering=true\n    if runtime.UpdateCa\x72dStatus then runtime.UpdateCardStatus() end\n    Label(searchLabe\x6c,\"Search: \"..(prefs.query==\"\" and \"(all)\" or prefs.query))\n    task.sp\x61wn(function()\n        local filtered={}\n        for i,item in ipa\x69rs(source) do\n            if not runtime.alive or runtime.filter\x47eneration~=ticket then return end\n            local haystack=ite\x6d.name:lower()..\" \"..IdText(item.id)\n            local matches=true\n\x20           for _,word in ipairs(words) do\n                if not\x20haystack:find(word,1,true) then matches=false;break end\n        \x20   end\n            if matches then filtered[#filtered+1]=item en\x64\n            if i%500==0 then task.wait() end\n        end\n        \x69f not runtime.alive or runtime.filterGeneration~=ticket then re\x74urn end\n        runtime.filtered=filtered;runtime.filtering=fals\x65\n        if resetPage then runtime.page=1 end\n        RenderPage(\x29\n    end)\nend\nlocal function AdoptCatalog(items,source)\n    runtime\x2ecatalog=items\n    runtime.catalogSource=source\n    Label(catalogL\x61bel,\"Catalog: \"..#items..\" emotes • \"..source)\n    -- A selected item\x20need not be on the visible page or present in a newer catalog.\n \x20  if not prefs.selected then prefs.selected=items[1] end\n    Sel\x65ctionLabel()\n    Filter(true)\nend\nlocal function RefreshCatalog()\n \x20  if not runtime.alive or runtime.catalogBusy then return end\n  \x20 runtime.catalogBusy=true\n    Label(catalogLabel,\"Updating catalo\x67... current list remains available\")\n    task.spawn(function()\n   \x20    local ok,data=pcall(function() return HttpService:JSONDecod\x65(game:HttpGet(URL)) end)\n        if not runtime.alive then retur\x6e end\n        local items=ok and NormalizeCatalog(data) or nil\n   \x20    runtime.catalogBusy=false\n        if not items then\n         \x20  Label(catalogLabel,\"Catalog: \"..#runtime.catalog..\" • offline / u\x70date failed\")\n            WarnOnce(\"network\",\"Catalog update failed.\x20The cached or built-in list remains available.\")\n            retu\x72n\n        end\n        warnings.network=nil\n        AdoptCatalog(it\x65ms,\"7yd7 online catalog\")\n        if type(write)==\"function\" then\n   \x20        local saved=pcall(function() write(CACHE,HttpService:JS\x4fNEncode({version=1,data=items})) end)\n            if not saved t\x68en WarnOnce(\"cache\",\"Could not save the catalog cache; the list st\x69ll works this session.\") end\n        end\n    end)\nend\nruntime.Refres\x68Catalog=RefreshCatalog\n\n-- Native Noir-styled Emotes page. It use\x73 the supplied script's catalog, persistence and playback core.\nd\x6f\n    local UI = { connections = {}, cards = {}, settingsOpen = f\x61lse, searchToken = 0 }\n    runtime.browser = UI\n    local theme =\x20shared.theme or {}\n    local C = {\n        base = theme.base or C\x6flor3.fromRGB(9, 10, 13),\n        panel = theme.panel or Color3.f\x72omRGB(16, 18, 22),\n        surface = theme.surface or Color3.fro\x6dRGB(24, 27, 32),\n        card = theme.card or Color3.fromRGB(20,\x2024, 28),\n        button = theme.button or Color3.fromRGB(34, 38,\x2044),\n        accent = theme.accent or Color3.fromRGB(216, 222, 2\x332),\n        text = theme.text or Color3.fromRGB(240, 243, 246),\n \x20      dim = theme.dim or Color3.fromRGB(147, 156, 166),\n        \x62order = theme.border or Color3.fromRGB(68, 75, 84),\n        dang\x65r = Color3.fromRGB(190, 195, 203),\n    }\n    local function Make(\x63lass, properties, parent)\n        local instance = Instance.new(\x63lass)\n        for key, value in pairs(properties or {}) do insta\x6ece[key] = value end\n        instance.Parent = parent\n        retu\x72n instance\n    end\n    local function Round(instance, radius)\n    \x20   return Make(\"UICorner\", { CornerRadius = UDim.new(0, radius or\x2010) }, instance)\n    end\n    local function Stroke(instance, colo\x72, transparency, thickness)\n        return Make(\"UIStroke\", { Color\x20= color or C.border, Transparency = transparency or .45, Thickn\x65ss = thickness or 1 }, instance)\n    end\n    local function Text(\x70arent, value, size, position, dimensions, color)\n        return \x4dake(\"TextLabel\", {\n            BackgroundTransparency = 1, Text = \x76alue or \"\", TextColor3 = color or C.text,\n            Font = Enum.\x46ont.Gotham, TextSize = size or 14, TextXAlignment = Enum.TextXA\x6cignment.Left,\n            TextYAlignment = Enum.TextYAlignment.C\x65nter, Position = position or UDim2.new(), Size = dimensions or \x55Dim2.new(1,0,1,0),\n        }, parent)\n    end\n    local function B\x75tton(parent, value, position, dimensions)\n        local button =\x20Make(\"TextButton\", {\n            BackgroundColor3 = C.button, Back\x67roundTransparency = .06, BorderSizePixel = 0,\n            Text =\x20value or \"\", TextColor3 = C.text, Font = Enum.Font.GothamMedium,\n \x20          TextSize = 13, AutoButtonColor = false, Position = po\x73ition or UDim2.new(), Size = dimensions or UDim2.new(),\n        \x7d, parent)\n        Round(button, 10); Stroke(button, C.border, .5\x32)\n        button.MouseEnter:Connect(function() if button.Parent \x74hen button.BackgroundColor3 = C.surface end end)\n        button.\x4douseLeave:Connect(function() if button.Parent then button.Backg\x72oundColor3 = C.button end end)\n        return button\n    end\n    l\x6fcal function Connect(signal, callback)\n        local connection \x3d signal:Connect(callback)\n        UI.connections[#UI.connections\x20+ 1] = connection\n        return connection\n    end\n    local func\x74ion Save()\n        SaveSettings()\n    end\n    local function SetSe\x6cected(item)\n        if not item then return end\n        prefs.sel\x65cted = { id = item.id, name = item.name }\n        Save()\n        \x69f runtime.UpdateCardStatus then runtime.UpdateCardStatus() end\n \x20  end\n    local function ToggleFavorite(item)\n        local key =\x20IdText(item.id)\n        if prefs.favorites[key] then prefs.favor\x69tes[key] = nil else prefs.favorites[key] = { id = item.id, name\x20= item.name } end\n        Save()\n        if prefs.favoritesOnly t\x68en Filter(false) elseif runtime.UpdateCardStatus then runtime.U\x70dateCardStatus() end\n    end\n    local function SetLoop(value)\n   \x20    prefs.loop = value == true\n        Save()\n        if runtime.\x74rack then pcall(function() runtime.track.Looped = prefs.loop en\x64) end\n        if runtime.UpdateCardStatus then runtime.UpdateCar\x64Status() end\n    end\n    local function SetMove(value)\n        pre\x66s.walk = value == true\n        Save()\n        if runtime.UpdateCa\x72dStatus then runtime.UpdateCardStatus() end\n    end\n    local fun\x63tion SetSpeed(value)\n        prefs.speed = math.clamp(math.floor\x28(tonumber(value) or prefs.speed) * 100 + .5) / 100, 0, 3)\n      \x20 Save()\n        if runtime.track then pcall(function() runtime.t\x72ack:AdjustSpeed(prefs.speed) end) end\n        if runtime.UpdateC\x61rdStatus then runtime.UpdateCardStatus() end\n    end\n    -- Circu\x6car pin buttons create draggable on-screen photo shortcuts, matc\x68ing the supplied card browser behavior.\n    local quickGui, quic\x6bRecords, quickConnections = nil, {}, {}\n    local function clear\x51uickConnections()\n        for _, connection in ipairs(quickConne\x63tions) do pcall(function() connection:Disconnect() end) end\n    \x20   table.clear(quickConnections)\n    end\n    local function destr\x6fyQuickGui()\n        clearQuickConnections()\n        if quickGui t\x68en quickGui:Destroy() end\n        quickGui, quickRecords = nil, \x7b}\n    end\n    local function ensureQuickGui()\n        if quickGui \x61nd quickGui.Parent then return quickGui end\n        quickGui = I\x6estance.new(\"ScreenGui\")\n        quickGui.Name, quickGui.ResetOnSpa\x77n, quickGui.IgnoreGuiInset, quickGui.DisplayOrder = \"NoirEmoteQu\x69ckButtons\", false, true, 90\n        local parent\n        if type(g\x65thui) == \"function\" then\n            local ok, value = pcall(gethu\x69)\n            if ok and typeof(value) == \"Instance\" then parent = \x76alue end\n        end\n        quickGui.Parent = parent or Player:W\x61itForChild(\"PlayerGui\")\n        return quickGui\n    end\n    local fu\x6ection viewport()\n        return workspace.CurrentCamera and work\x73pace.CurrentCamera.ViewportSize or Vector2.new(900,600)\n    end\n \x20  local function positionQuick(record)\n        local saved = pre\x66s.shortcuts[record.key]\n        if not saved then return end\n    \x20   local screen = viewport()\n        record.button.Position = UD\x69m2.fromOffset(math.clamp(saved.x * screen.X, 38, math.max(38, s\x63reen.X - 38)), math.clamp(saved.y * screen.Y, 38, math.max(38, \x73creen.Y - 38)))\n    end\n    local function createQuick(key, saved\x29\n        -- Rounded-square photo control using the same dark bod\x79 and metallic double border as Shoot Murder.\n        local butto\x6e = Instance.new(\"TextButton\")\n        button.Name, button.AnchorPo\x69nt, button.Size = \"Emote_\" .. key, Vector2.new(.5,.5), UDim2.from\x4fffset(88,88)\n        button.BackgroundColor3, button.BackgroundT\x72ansparency, button.BorderSizePixel = Color3.fromRGB(8,8,10), .2\x38, 0\n        button.Text, button.AutoButtonColor, button.ZIndex =\x20\"\", false, 91\n        button.Parent = ensureQuickGui()\n        loca\x6c corner = Instance.new(\"UICorner\"); corner.CornerRadius = UDim.ne\x77(0,16); corner.Parent = button\n        local outline = Instance.\x6eew(\"UIStroke\"); outline.Color, outline.Thickness, outline.ApplySt\x72okeMode, outline.Parent = Color3.fromRGB(255,255,255), 2, Enum.\x41pplyStrokeMode.Border, button\n        local shine = Instance.new\x28\"UIGradient\")\n        shine.Color = ColorSequence.new({\n           \x20ColorSequenceKeypoint.new(0, Color3.fromRGB(35,35,40)), ColorSe\x71uenceKeypoint.new(.22, Color3.fromRGB(250,250,252)),\n           \x20ColorSequenceKeypoint.new(.48, Color3.fromRGB(70,70,78)), Color\x53equenceKeypoint.new(.72, Color3.fromRGB(255,255,255)),\n         \x20  ColorSequenceKeypoint.new(1, Color3.fromRGB(45,45,52)),\n      \x20 })\n        shine.Parent = outline\n        local inner = Instance\x2enew(\"UIStroke\"); inner.Color, inner.Transparency, inner.Thickness\x2c inner.Parent = Color3.fromRGB(105,105,112), .5, 1, button\n     \x20  local innerShine = shine:Clone(); innerShine.Rotation = 180; \x69nnerShine.Parent = inner\n        local image = Instance.new(\"Imag\x65Label\")\n        image.Name, image.AnchorPoint, image.Position, im\x61ge.Size = \"Photo\", Vector2.new(.5,.5), UDim2.fromScale(.5,.5), UD\x69m2.fromOffset(62,62)\n        image.BackgroundTransparency, image\x2eImage, image.ScaleType, image.ZIndex = 1, \"rbxthumb://type=Asset\x26id=\" .. key .. \"&w=420&h=420\", Enum.ScaleType.Fit, 92\n        image\x2eParent = button\n        local imageCorner = Instance.new(\"UICorne\x72\"); imageCorner.CornerRadius = UDim.new(0,11); imageCorner.Paren\x74 = image\n        local record = { key = key, item = { id = saved\x2eid, name = saved.name }, button = button, dragging = false, mov\x65d = false }\n        quickRecords[key] = record\n        positionQu\x69ck(record)\n        local dragInput, start, startPosition\n        \x71uickConnections[#quickConnections+1] = button.InputBegan:Connec\x74(function(input)\n            if input.UserInputType ~= Enum.User\x49nputType.Touch and input.UserInputType ~= Enum.UserInputType.Mo\x75seButton1 then return end\n            record.dragging, record.mo\x76ed, dragInput, start, startPosition = true, false, input, input\x2ePosition, button.Position\n        end)\n        quickConnections[#\x71uickConnections+1] = UIS.InputChanged:Connect(function(input)\n  \x20         if not record.dragging then return end\n            if i\x6eput ~= dragInput and not (dragInput.UserInputType == Enum.UserI\x6eputType.MouseButton1 and input.UserInputType == Enum.UserInputT\x79pe.MouseMovement) then return end\n            local delta = inpu\x74.Position - start\n            if delta.Magnitude > 7 then record\x2emoved = true end\n            button.Position = UDim2.new(startPo\x73ition.X.Scale, startPosition.X.Offset + delta.X, startPosition.\x59.Scale, startPosition.Y.Offset + delta.Y)\n        end)\n        qu\x69ckConnections[#quickConnections+1] = UIS.InputEnded:Connect(fun\x63tion(input)\n            if not record.dragging or input ~= dragI\x6eput then return end\n            record.dragging = false\n         \x20  if record.moved then\n                local screen = viewport()\n\x20               prefs.shortcuts[key].x = math.clamp(button.Posit\x69on.X.Offset / math.max(screen.X,1), 0, 1)\n                prefs.\x73hortcuts[key].y = math.clamp(button.Position.Y.Offset / math.ma\x78(screen.Y,1), 0, 1)\n                record.blockUntil = os.clock\x28) + .25\n                Save()\n            end\n        end)\n       \x20quickConnections[#quickConnections+1] = button.Activated:Connec\x74(function()\n            if record.moved or (record.blockUntil an\x64 os.clock() < record.blockUntil) then return end\n            Set\x53elected(record.item); Play(record.item, false)\n        end)\n    e\x6ed\n    local function RefreshQuickButtons()\n        for key, recor\x64 in pairs(quickRecords) do\n            if not prefs.shortcuts[ke\x79] then record.button:Destroy(); quickRecords[key] = nil end\n    \x20   end\n        for key, saved in pairs(prefs.shortcuts) do\n      \x20     if not quickRecords[key] then createQuick(key, saved) else\x20positionQuick(quickRecords[key]) end\n        end\n        if not n\x65xt(prefs.shortcuts) then destroyQuickGui() end\n    end\n    local \x66unction ToggleQuick(item)\n        local key = IdText(item.id)\n   \x20    if prefs.shortcuts[key] then\n            prefs.shortcuts[key\x5d = nil\n        else\n            local count = 0\n            for _ \x69n pairs(prefs.shortcuts) do count += 1 end\n            if count \x3e= MAX_SHORTCUTS then Notify(\"Maximum \" .. MAX_SHORTCUTS .. \" on-sc\x72een emote buttons.\"); return end\n            local screen = viewp\x6frt()\n            prefs.shortcuts[key] = { id = item.id, name = i\x74em.name, x = .86, y = math.clamp(.28 + count * .1, .18, .82) }\n \x20      end\n        Save(); RefreshQuickButtons()\n        if runtim\x65.UpdateCardStatus then runtime.UpdateCardStatus() end\n    end\n\n   \x20local function Layout()\n        if not (UI.root and UI.cardsScro\x6cl) then return end\n        local size = UI.root.AbsoluteSize\n    \x20   if size.X < 1 or size.Y < 1 then return end\n        local nar\x72ow = size.X < 570\n        local veryNarrow = size.X < 410\n       \x20UI.search.Position = UDim2.fromOffset(18, 68)\n        UI.search.\x53ize = UDim2.new(1, narrow and -138 or -268, 0, 38)\n        UI.fa\x76oriteFilter.Position = UDim2.new(1, narrow and -112 or -242, 0,\x2068)\n        UI.favoriteFilter.Size = UDim2.fromOffset(narrow and\x2094 or 118, 38)\n        UI.settingsButton.Position = UDim2.new(1,\x20narrow and -18 or -116, 0, 18)\n        UI.settingsButton.AnchorP\x6fint = Vector2.new(1, 0)\n        UI.settingsButton.Size = UDim2.f\x72omOffset(narrow and 86 or 98, 32)\n        UI.random.Position = U\x44im2.new(1, narrow and -18 or -18, 0, 110)\n        UI.random.Anch\x6frPoint = Vector2.new(1, 0)\n        UI.random.Size = UDim2.fromOf\x66set(narrow and 82 or 94, 30)\n        UI.stop.Position = UDim2.ne\x77(1, narrow and -108 or -122, 0, 110)\n        UI.stop.AnchorPoint\x20= Vector2.new(1, 0)\n        UI.stop.Size = UDim2.fromOffset(narr\x6fw and 82 or 94, 30)\n        UI.summary.Position = UDim2.fromOffs\x65t(20, 112)\n        UI.summary.Size = UDim2.new(1, narrow and -20\x30 or -260, 0, 28)\n        local top, footer = 148, 58\n        UI.c\x61rdsScroll.Position = UDim2.fromOffset(18, top)\n        UI.cardsS\x63roll.Size = UDim2.new(1, -36, 1, -(top + footer + 10))\n        U\x49.footer.Position = UDim2.new(0, 18, 1, -54)\n        UI.footer.Si\x7ae = UDim2.new(1, -36, 0, 40)\n        -- Use the full Noir tab wi\x64th, matching the supplied menu's three-card gallery on wider sc\x72eens.\n        local available = math.max(1, size.X - 48)\n        \x2d- Scale-based cells fill the whole Noir page even when the mobi\x6ce UI has a UIScale applied.\n        local columns, padding, cell\x48eight = 3, 12, 250\n        UI.grid.CellSize = UDim2.new(1 / colu\x6dns, -10, 0, cellHeight)\n        UI.grid.FillDirectionMaxCells = \x63olumns\n        local rows = math.ceil(#UI.cards / columns)\n      \x20 UI.cardsScroll.CanvasSize = UDim2.fromOffset(0, math.max(0, ro\x77s * (cellHeight + padding) - padding + 8))\n        UI.settings.S\x69ze = UDim2.fromOffset(math.min(290, math.max(230, size.X - 36))\x2c math.min(470, math.max(250, size.Y - 96)))\n        UI.settings.\x50osition = UDim2.new(1, -18, 0, 58)\n        UI.settings.AnchorPoi\x6et = Vector2.new(1, 0)\n    end\n    runtime.ApplyBrowserAppearance \x3d Layout\n    runtime.ResetBrowserPosition = function() Layout() e\x6ed\n    local function UpdateStatus()\n        if not UI.root then r\x65turn end\n        local pages = math.max(1, math.ceil(#runtime.fi\x6ctered / PAGE_SIZE))\n        UI.page.Text = \"Page \" .. runtime.page\x20.. \" / \" .. pages\n        UI.status.Text = runtime.status or \"Ready\x20— select an emote and press Play\"\n        UI.summary.Text = runtim\x65.filtering and \"Searching emotes...\" or (tostring(#runtime.filter\x65d) .. \" emotes\")\n        UI.favoriteFilter.Text = prefs.favoritesO\x6ely and \"★ Saved\" or \"☆ Saved\"\n        UI.favoriteFilter.TextColor3 = p\x72efs.favoritesOnly and C.accent or C.text\n        UI.favoriteFilt\x65r.BackgroundColor3 = prefs.favoritesOnly and C.surface or C.but\x74on\n        UI.loop.Text = prefs.loop and \"Loop  ON\" or \"Loop  OFF\"\n  \x20     UI.loop.TextColor3 = prefs.loop and C.accent or C.text\n    \x20   UI.move.Text = prefs.walk and \"Move  ON\" or \"Move  OFF\"\n        U\x49.move.TextColor3 = prefs.walk and C.accent or C.text\n        UI.\x73peedValue.Text = \"Speed \" .. tostring(prefs.speed)\n        for _, \x63ard in ipairs(UI.cards) do\n            local selected = prefs.se\x6cected and prefs.selected.id == card.item.id\n            local pl\x61ying = runtime.track and runtime.playing and runtime.playing.id\x20== card.item.id\n            card.stroke.Color = selected and C.a\x63cent or C.border\n            card.stroke.Transparency = selected\x20and .08 or .62\n            card.star.Text = prefs.favorites[IdTe\x78t(card.item.id)] and \"★\" or \"☆\"\n            card.star.TextColor3 = pre\x66s.favorites[IdText(card.item.id)] and C.accent or C.text\n       \x20    card.pin.Text = prefs.shortcuts[IdText(card.item.id)] and \"●\" \x6fr \"○\"\n            card.pin.TextColor3 = prefs.shortcuts[IdText(card\x2eitem.id)] and C.accent or C.dim\n            card.play.Text = pla\x79ing and \"■\" or \"▶\"\n            card.play.BackgroundColor3 = playing an\x64 C.accent or C.button\n            card.play.TextColor3 = playing\x20and C.accent or C.text\n        end\n    end\n    runtime.UpdateCardS\x74atus = UpdateStatus\n    local function BuildCard(item, order)\n   \x20    local card = Make(\"Frame\", { Name = \"Emote_\" .. IdText(item.id)\x2c LayoutOrder = order, BackgroundColor3 = C.card, BorderSizePixe\x6c = 0, ClipsDescendants = true }, UI.cardsScroll)\n        local c\x61rdConnections = {}\n        local function CardConnect(signal, ca\x6clback)\n            local connection = signal:Connect(callback)\n  \x20         cardConnections[#cardConnections + 1] = connection\n    \x20       return connection\n        end\n        Round(card, 14)\n     \x20  local outline = Stroke(card, C.border, .62, 1)\n        local t\x69tle = Text(card, item.name, 15, UDim2.fromOffset(12, 10), UDim2\x2enew(1, -70, 0, 36))\n        title.TextWrapped = true; title.Text\x54runcate = Enum.TextTruncate.AtEnd; title.Font = Enum.Font.Gotha\x6dMedium; title.TextYAlignment = Enum.TextYAlignment.Top\n        l\x6fcal star = Button(card, \"☆\", UDim2.new(1, -50, 0, 8), UDim2.fromOf\x66set(38, 36))\n        star.BackgroundTransparency = 1; star.TextS\x69ze = 27\n        local image = Make(\"ImageButton\", { BackgroundTran\x73parency = 1, AutoButtonColor = false, AnchorPoint = Vector2.new\x28.5,.5), Position = UDim2.new(.5, 0, .55, 0), Size = UDim2.fromO\x66fset(130,130), Image = \"rbxthumb://type=Asset&id=\" .. IdText(item\x2eid) .. \"&w=420&h=420\", ScaleType = Enum.ScaleType.Fit }, card)\n   \x20    local pin = Button(card, \"○\", UDim2.new(1, -60, .48, 0), UDim2\x2efromOffset(46,46))\n        pin.BackgroundTransparency = 1; pin.T\x65xtSize = 30\n        local play = Button(card, \"▶\", UDim2.new(1, -62\x2c 1, -62), UDim2.fromOffset(50,50)); play.TextSize = 20\n        l\x6fcal record = { frame = card, connections = cardConnections, ite\x6d = item, stroke = outline, star = star, pin = pin, play = play \x7d\n        UI.cards[#UI.cards + 1] = record\n        CardConnect(ima\x67e.Activated, function() SetSelected(item) end)\n        CardConne\x63t(star.Activated, function() ToggleFavorite(item) end)\n        C\x61rdConnect(pin.Activated, function() ToggleQuick(item) end)\n     \x20  CardConnect(play.Activated, function()\n            local playi\x6eg = runtime.track and runtime.playing and runtime.playing.id ==\x20item.id\n            SetSelected(item)\n            if playing then\x20StopCurrent(\"Stopped\") else Play(item, false) end\n            Upda\x74eStatus()\n        end)\n    end\n    local function RenderCards()\n   \x20    if not UI.root then return end\n        -- Do not create thum\x62nail cards while this page is hidden. The visible-page handler \x70erforms one render on open.\n        if not container.Visible the\x6e UI.needsRender = true; return end\n        for _, record in ipai\x72s(UI.cards) do\n            for _, connection in ipairs(record.co\x6enections or {}) do pcall(function() connection:Disconnect() end\x29 end\n            if record.frame then record.frame:Destroy() end\n\x20       end\n        UI.cards = {}\n        UI.needsRender = false\n  \x20     local first = (runtime.page - 1) * PAGE_SIZE + 1\n        lo\x63al last = math.min(runtime.page * PAGE_SIZE, #runtime.filtered)\n\x20       for index = first, last do BuildCard(runtime.filtered[in\x64ex], index - first + 1) end\n        UI.empty.Visible = #runtime.\x66iltered == 0\n        UI.empty.Text = runtime.filtering and \"Searc\x68ing...\" or (prefs.favoritesOnly and \"No saved emotes yet.\" or \"No e\x6dotes match your search.\")\n        UI.cardsScroll.CanvasPosition =\x20Vector2.zero\n        Layout(); UpdateStatus()\n    end\n    runtime.\x52enderCards = RenderCards\n    local function Build()\n        local\x20old = container:FindFirstChild(\"NoirEmotesNative\")\n        if old \x74hen old:Destroy() end\n        UI.root = Make(\"Frame\", { Name = \"Noi\x72EmotesNative\", Position = UDim2.fromOffset(12, 12), Size = UDim2\x2enew(1, -24, 0, 640), BackgroundColor3 = C.base, BorderSizePixel\x20= 0, ClipsDescendants = true }, container)\n        if shared.Set\x43anvasHeight then shared.SetCanvasHeight(664) end\n        Round(U\x49.root, 18); Stroke(UI.root, C.border, .35, 1.2)\n        local gr\x61dient = Make(\"UIGradient\", { Color = ColorSequence.new(C.base, C.\x73urface), Rotation = 20 }, UI.root)\n        Text(UI.root, \"EMOTES\",\x2021, UDim2.fromOffset(18, 14), UDim2.new(1,-150,0,24)).Font = En\x75m.Font.GothamBold\n        Text(UI.root, \"R15 ANIMATION LIBRARY\", 1\x30, UDim2.fromOffset(19, 39), UDim2.new(1,-150,0,16), C.dim)\n     \x20  UI.settingsButton = Button(UI.root, \"Settings\", UDim2.new(1,-11\x36,0,18), UDim2.fromOffset(98,32))\n        UI.search = Make(\"TextBo\x78\", { BackgroundColor3 = C.surface, BorderSizePixel = 0, Text = p\x72efs.query, PlaceholderText = \"Search emote or ID...\", Placeholder\x43olor3 = C.dim, TextColor3 = C.text, Font = Enum.Font.Gotham, Te\x78tSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ClearTex\x74OnFocus = false }, UI.root)\n        Round(UI.search, 10); Stroke\x28UI.search, C.border, .55); Make(\"UIPadding\", { PaddingLeft = UDim\x2enew(0, 12), PaddingRight = UDim.new(0, 8) }, UI.search)\n        \x55I.favoriteFilter = Button(UI.root, \"☆ Saved\", UDim2.new(), UDim2.f\x72omOffset(118,38))\n        UI.random = Button(UI.root, \"Random\", UD\x69m2.new(), UDim2.fromOffset(94,30))\n        UI.stop = Button(UI.r\x6fot, \"■ Stop\", UDim2.new(), UDim2.fromOffset(94,30)); UI.stop.TextC\x6flor3 = C.danger\n        UI.summary = Text(UI.root, \"Loading emote\x73...\", 12, UDim2.fromOffset(20,112), UDim2.new(1,-260,0,28), C.di\x6d)\n        UI.cardsScroll = Make(\"ScrollingFrame\", { BackgroundTran\x73parency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, Scrol\x6cBarImageColor3 = C.accent, CanvasSize = UDim2.fromOffset(0,0), \x53crollingDirection = Enum.ScrollingDirection.Y, ElasticBehavior \x3d Enum.ElasticBehavior.Never }, UI.root)\n        Make(\"UIPadding\", \x7b PaddingLeft = UDim.new(0,2), PaddingRight = UDim.new(0,8), Pad\x64ingTop = UDim.new(0,2), PaddingBottom = UDim.new(0,6) }, UI.car\x64sScroll)\n        UI.grid = Make(\"UIGridLayout\", { SortOrder = Enum\x2eSortOrder.LayoutOrder, CellPadding = UDim2.fromOffset(12,12), C\x65llSize = UDim2.fromOffset(240,170) }, UI.cardsScroll)\n        UI\x2eempty = Text(UI.root, \"No emotes found\", 16, UDim2.fromOffset(26,\x3185), UDim2.new(1,-52,0,200), C.dim)\n        UI.empty.TextXAlignm\x65nt = Enum.TextXAlignment.Center; UI.empty.TextYAlignment = Enum\x2eTextYAlignment.Center; UI.empty.Visible = false\n        UI.foote\x72 = Make(\"Frame\", { BackgroundTransparency = 1 }, UI.root)\n        \x55I.previous = Button(UI.footer, \"‹\", UDim2.fromOffset(0,0), UDim2.f\x72omOffset(35,35)); UI.previous.TextSize = 26\n        UI.next = Bu\x74ton(UI.footer, \"›\", UDim2.new(1,-35,0,0), UDim2.fromOffset(35,35))\x3b UI.next.TextSize = 26\n        UI.page = Text(UI.footer, \"Page 1 \x2f 1\", 12, UDim2.fromOffset(42,0), UDim2.new(1,-84,0,35), C.dim); \x55I.page.TextXAlignment = Enum.TextXAlignment.Center\n        UI.st\x61tus = Text(UI.footer, \"Ready\", 11, UDim2.fromOffset(2,37), UDim2.\x6eew(1,-4,0,14), C.dim)\n        -- Settings content is taller than\x20a phone-sized drawer, so make the drawer itself vertically scro\x6clable.\n        UI.settings = Make(\"ScrollingFrame\", { BackgroundCo\x6cor3 = C.panel, BorderSizePixel = 0, Visible = false, ZIndex = 2\x30,\n            ClipsDescendants = true, Active = true, ScrollBarT\x68ickness = 4, ScrollBarImageColor3 = C.accent,\n            Scroll\x69ngDirection = Enum.ScrollingDirection.Y, ElasticBehavior = Enum\x2eElasticBehavior.Never,\n            CanvasSize = UDim2.fromOffset\x280, 388) }, UI.root)\n        Round(UI.settings, 14); Stroke(UI.se\x74tings, C.border, .2, 1.2)\n        Text(UI.settings, \"EMOTE SETTIN\x47S\", 15, UDim2.fromOffset(16,14), UDim2.new(1,-32,0,24)).Font = E\x6eum.Font.GothamBold\n        local function SettingsButton(label, \x79)\n            local button = Button(UI.settings, label, UDim2.fr\x6fmOffset(16,y), UDim2.new(1,-32,0,36)); button.ZIndex = 21; retu\x72n button\n        end\n        UI.loop = SettingsButton(\"Loop  OFF\", \x352)\n        UI.move = SettingsButton(\"Move  OFF\", 96)\n        UI.spe\x65dMinus = SettingsButton(\"−\", 140); UI.speedMinus.Size = UDim2.from\x4fffset(38,36)\n        UI.speedValue = SettingsButton(\"Speed 1\", 140\x29; UI.speedValue.Position = UDim2.fromOffset(62,140); UI.speedVa\x6cue.Size = UDim2.new(1,-124,0,36)\n        UI.speedPlus = Settings\x42utton(\"+\", 140); UI.speedPlus.Position = UDim2.new(1,-54,0,140); \x55I.speedPlus.Size = UDim2.fromOffset(38,36)\n        UI.custom = M\x61ke(\"TextBox\", { BackgroundColor3 = C.surface, BorderSizePixel = 0\x2c Position = UDim2.fromOffset(16,188), Size = UDim2.new(1,-32,0,\x336), Text = prefs.customId, PlaceholderText = \"Custom animation I\x44\", PlaceholderColor3 = C.dim, TextColor3 = C.text, Font = Enum.F\x6fnt.Gotham, TextSize = 13, ClearTextOnFocus = false, ZIndex = 21\x20}, UI.settings)\n        Round(UI.custom, 9); Stroke(UI.custom, C\x2eborder, .5); Make(\"UIPadding\", { PaddingLeft = UDim.new(0,10) }, \x55I.custom)\n        UI.playCustom = SettingsButton(\"Play custom ani\x6dation\", 232)\n        UI.refresh = SettingsButton(\"Refresh catalog\",\x20276)\n        UI.closeSettings = SettingsButton(\"Close settings\", 3\x320)\n        Connect(UI.settingsButton.Activated, function()\n      \x20     UI.settingsOpen = not UI.settingsOpen\n            UI.settin\x67s.Visible = UI.settingsOpen\n            if UI.settingsOpen then \x55I.settings.CanvasPosition = Vector2.zero end\n        end)\n       \x20Connect(UI.closeSettings.Activated, function() UI.settingsOpen \x3d false; UI.settings.Visible = false end)\n        Connect(UI.loop\x2eActivated, function() SetLoop(not prefs.loop) end)\n        Conne\x63t(UI.move.Activated, function() SetMove(not prefs.walk) end)\n   \x20    Connect(UI.speedMinus.Activated, function() SetSpeed(prefs.\x73peed - .25) end)\n        Connect(UI.speedPlus.Activated, functio\x6e() SetSpeed(prefs.speed + .25) end)\n        Connect(UI.refresh.A\x63tivated, RefreshCatalog)\n        Connect(UI.playCustom.Activated\x2c function()\n            prefs.customId = UI.custom.Text:sub(1,20\x30); Save()\n            local id = ParseId(prefs.customId)\n        \x20   if not id then Notify(\"Enter a valid animation ID.\"); return e\x6ed\n            Play({ id = id, name = \"Custom \" .. IdText(id) }, tr\x75e)\n        end)\n        Connect(UI.custom.FocusLost, function() p\x72efs.customId = UI.custom.Text:sub(1,200); Save() end)\n        Co\x6enect(UI.favoriteFilter.Activated, function() prefs.favoritesOnl\x79 = not prefs.favoritesOnly; Save(); Filter(true) end)\n        Co\x6enect(UI.random.Activated, function()\n            if runtime.filt\x65ring or #runtime.filtered == 0 then Notify(\"No emotes available \x79et.\"); return end\n            local item = runtime.filtered[math.\x72andom(1,#runtime.filtered)]; SetSelected(item); Play(item,false\x29\n        end)\n        Connect(UI.stop.Activated, function() StopC\x75rrent(\"Stopped\") end)\n        Connect(UI.previous.Activated, funct\x69on() runtime.page = math.max(1, runtime.page - 1); RenderPage()\x20end)\n        Connect(UI.next.Activated, function() runtime.page \x3d runtime.page + 1; RenderPage() end)\n        Connect(UI.search:G\x65tPropertyChangedSignal(\"Text\"), function()\n            UI.searchTo\x6ben = UI.searchToken + 1\n            local ticket = UI.searchToke\x6e\n            task.delay(.25, function()\n                if not ru\x6etime.alive or ticket ~= UI.searchToken then return end\n         \x20      prefs.query = UI.search.Text:sub(1,200); Save(); Filter(t\x72ue)\n            end)\n        end)\n        Connect(UI.search.FocusL\x6fst, function() prefs.query = UI.search.Text:sub(1,200); Save();\x20Filter(true) end)\n        Connect(UI.root:GetPropertyChangedSign\x61l(\"AbsoluteSize\"), function() task.defer(Layout) end)\n        Conn\x65ct(UI.cardsScroll:GetPropertyChangedSignal(\"AbsoluteSize\"), funct\x69on() task.defer(Layout) end)\n        Connect(container:GetProper\x74yChangedSignal(\"Visible\"), function()\n            if container.Vis\x69ble then task.delay(.05, function() if runtime.alive and UI.roo\x74 then Layout(); RenderCards() end end) end\n        end)\n        L\x61yout(); RenderCards(); RefreshQuickButtons()\n    end\n    function\x20runtime.OpenBrowser()\n        if not runtime.alive then return e\x6ed\n        if UI.root and UI.root.Parent then UI.root.Visible = t\x72ue; RenderCards(); return end\n        local ok, err = pcall(Buil\x64)\n        if not ok then WarnOnce(\"native_ui\", \"Could not build the\x20Noir Emotes page: \" .. tostring(err)) end\n    end\n    function run\x74ime.CloseBrowser() end\n    function runtime.RestoreQuickButtons(\x29 end\n    function runtime.SyncQuickButtons() end\n    function run\x74ime.ClearQuickButtons() prefs.shortcuts = {}; Save() end\n    fun\x63tion runtime.DestroyBrowser()\n        for _, connection in ipair\x73(UI.connections) do pcall(function() connection:Disconnect() en\x64) end\n        UI.connections = {}\n        destroyQuickGui()\n      \x20 if UI.root then UI.root:Destroy() end\n        UI.root = nil; UI\x2ecards = {}\n    end\nend\n\n-- The supplied card browser is embedded di\x72ectly in Noir's Emotes page; no duplicate native control sectio\x6es.\nfunction runtime.SyncNative() end\nruntime.initializing=false\n_G\x5bKEY]=runtime\nlocal cache=ReadJSON(CACHE)\nlocal cachedItems=Normal\x69zeCatalog(cache)\nAdoptCatalog(cachedItems or BUILTIN,cachedItems\x20and \"saved cache\" or \"built-in starter list\")\nStatus(\"Ready — select a\x6e emote and press Play\")\nRefreshCatalog()\ntask.defer(function()\n    \x69f runtime.alive then runtime.OpenBrowser() end\nend)\n\n"
    local compiler = loadstring
    if type(compiler) ~= "\x66unction" then
        warn("\x5bNoir Emotes] loadstring is unavailable; the Emotes tab could no\x74 be started.")
        return
    end
    local okCompile, moduleFn = pcall(compiler, __noirEmotesSource)
    if not okCompile or type(moduleFn) ~= "\x66unction" then
        warn("\x5bNoir Emotes] module compile failed: " .. tostring(moduleFn))
        return
    end
    local okRun, err = xpcall(moduleFn, function(message) return tostring(message) end)
    if not okRun then warn("\x5bNoir Emotes] module startup failed: " .. tostring(err)) end
end)



local selfMods = tab:AddSection("\x4dAIN • SELF MODS", "\x55niversal player controls")
selfMods:AddToggle("\x45nable WalkSpeed", function(v) utility.walkEnabled = v; applyCharacterMods() end)
selfMods:AddSlider("\x57alkSpeed", 8, 100, 16, function(v) utility.walkSpeed = v; applyCharacterMods() end)
selfMods:AddToggle("\x45nable JumpPower", function(v) utility.jumpEnabled = v; applyCharacterMods() end)
selfMods:AddSlider("\x4aumpPower", 25, 150, 50, function(v) utility.jumpPower = v; applyCharacterMods() end)
selfMods:AddToggle("\x41nti AFK", function(v) utility.antiAfk = v end)

__NOIR_GUARD.SetupNoirSpeedGlitch = function()
    local speedGlitchSection = tab:AddSection("\x4dAIN • SPEED GLITCH", "\x42etter ODH movement timing with a Noir event-horizon control")
    do
        local previousSpeedRuntime
        pcall(function() previousSpeedRuntime = getgenv().__NoirSpeedGlitchRuntime end)
        if type(previousSpeedRuntime) == "\x74able" and type(previousSpeedRuntime.Stop) == "\x66unction" then pcall(previousSpeedRuntime.Stop) end
    
        local speed = {
            alive = true, uiEnabled = false, enabled = false, onlyWorkSideways = false,
            sideSpeed = 150, toggleSize = 80, selectedEmote = "\x4doonwalk", selectedEmoteId = "\x379127989560307",
            customEmoteId = nil, character = nil, humanoid = nil, root = nil, isJumping = false,
            screenGui = nil, toggleButton = nil, mark = nil, heartbeat = nil, connections = {}, uiConnections = {}, characterConnections = {},
        }
        local emotes = {
            ["\x4doonwalk"] = "\x379127989560307",
            ["\x48appier Jump"] = "\x315610015346",
            ["\x42ouncy Twirl"] = "\x314353423348",
            ["\x46lex Walk"] = "\x315506506103",
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
                local humanoid = character:WaitForChild("\x48umanoid", 8)
                local root = character:WaitForChild("\x48umanoidRootPart", 8)
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
            local humanoid = speed.character:FindFirstChildOfClass("\x48umanoid")
            if not humanoid then return end
            local ok = pcall(function() humanoid:PlayEmoteAndGetAnimTrackById(id) end)
            if not ok then
                local animation = Instance.new("\x41nimation")
                animation.AnimationId = "\x72bxassetid://" .. tostring(id)
                local loaded, track = pcall(function() return humanoid:LoadAnimation(animation) end)
                if loaded and track then pcall(function() track:Play() end) end
            end
        end
        local function updateButtonVisual()
            local button = speed.toggleButton
            if not button then return end
            button.BackgroundColor3 = speed.enabled and Color3.fromRGB(22,24,29) or Color3.fromRGB(7,8,11)
            local label = button:FindFirstChild("\x53peedStatus")
            if label then label.Text = speed.enabled and "\x47LITCH  //  ON" or "\x47LITCH  //  OFF" end
            local outline = button:FindFirstChild("\x53peedOutline")
            if outline then outline.Color = speed.enabled and C.accent2 or C.border; outline.Transparency = speed.enabled and .05 or .24 end
            if speed.mark and speed.mark.image then speed.mark.image.ImageTransparency = speed.enabled and 0 or .08 end
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
            if typeof(parent) ~= "\x49nstance" then parent = LocalPlayer:FindFirstChildOfClass("\x50layerGui") or LocalPlayer:WaitForChild("\x50layerGui") end
            local screen = New("\x53creenGui", { Parent = parent, Name = "\x4eoirSpeedGlitchToggle", ResetOnSpawn = false,
                IgnoreGuiInset = true, DisplayOrder = 90, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
            local button = New("\x54extButton", { Parent = screen, Name = "\x53peedGlitch", AnchorPoint = Vector2.new(.5,.5),
                Position = NoirPersistence.GetPosition("\x73peed_glitch_toggle_v6", UDim2.new(.80,0,.72,0)),
                Size = UDim2.fromOffset(speed.toggleSize, speed.toggleSize), BackgroundColor3 = Color3.fromRGB(7,8,11),
                BorderSizePixel = 0, Text = "", AutoButtonColor = false, Active = true, ZIndex = 90 })
            corner(button, 999)
            local outline = New("\x55IStroke", { Parent = button, Name = "\x53peedOutline", Color = C.border, Transparency = .24, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
            local outlineGradient = New("\x55IGradient", { Parent = outline, Rotation = 35, Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0,C.dim), ColorSequenceKeypoint.new(.24,C.accent2),
                ColorSequenceKeypoint.new(.55,C.dim), ColorSequenceKeypoint.new(.78,C.accent2), ColorSequenceKeypoint.new(1,C.dim),
            }) })
            table.insert(gradientStrokes, outlineGradient)
            local _, mark = __NOIR_GUARD.blackhole.Create(button, UDim2.new(.5,0,.38,0), math.floor(speed.toggleSize * .52), Vector2.new(.5,.5), 92, math.floor(speed.toggleSize * .26))
            local label = New("\x54extLabel", { Parent = button, Name = "\x53peedStatus", AnchorPoint = Vector2.new(.5,.5),
                Position = UDim2.new(.5,0,.82,0), Size = UDim2.new(.92,0,0,math.max(13,math.floor(speed.toggleSize*.18))),
                BackgroundTransparency = 1, Text = "\x47LITCH  //  OFF", TextColor3 = C.text,
                TextSize = math.clamp(math.floor(speed.toggleSize*.14),8,12), Font = Enum.Font.GothamBold,
                TextScaled = false, TextWrapped = true, ZIndex = 94 })
            speed.screenGui, speed.toggleButton, speed.mark = screen, button, mark
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
                NoirPersistence.SetPosition("\x73peed_glitch_toggle_v6", button.Position)
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
                local markCorner = speed.mark.root:FindFirstChildOfClass("\x55ICorner")
                if markCorner then markCorner.CornerRadius = UDim.new(0, math.floor(diameter * .5)) end
            end
            local status = button:FindFirstChild("\x53peedStatus")
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
        speedGlitchSection:AddToggle("\x45nable Speed Glitch UI", toggleUi)
        speedGlitchSection:AddToggle("\x4fnly Work Sideways", function(value) speed.onlyWorkSideways = value == true end)
        speedGlitchSection:AddSlider("\x53ide Speed", 10, 1000, speed.sideSpeed, function(value) speed.sideSpeed = tonumber(value) or speed.sideSpeed end)
        speedGlitchSection:AddSlider("\x54oggle Size", 40, 150, speed.toggleSize, resizeToggleButton)
        speedGlitchSection:AddDropdown("\x53elect Emote", {"\x4doonwalk","\x48appier Jump","\x42ouncy Twirl","\x46lex Walk","\x43ustom"}, function(choice)
            speed.selectedEmote = choice
            speed.selectedEmoteId = choice == "\x43ustom" and speed.customEmoteId or emotes[choice]
        end)
        speedGlitchSection:AddTextBox("\x43ustom Emote ID", function(value)
            if value and value ~= "" then
                speed.customEmoteId = tostring(value)
                if speed.selectedEmote == "\x43ustom" then speed.selectedEmoteId = speed.customEmoteId end
            end
        end)
        speedGlitchSection:AddLabel("\x54ap the floating event-horizon button to toggle the glitch; drag\x20to move it. Position is saved and the UI auto-recovers if remov\x65d.")
    end
end
__NOIR_GUARD.SetupNoirSpeedGlitch()
__NOIR_GUARD.SetupNoirSpeedGlitch = nil

local serverMods = tab:AddSection("\x4dAIN • SERVER", "\x4dM2 round information")
serverMods:AddToggle("\x53how Round Timer", setRoundTimerVisible)
serverMods:AddToggle("\x49nstant Role Detection", function(v) instantRoleDetection = v; if v then task.spawn(refreshTarget) end end)
serverMods:AddToggle("\x41uto Notify Roles", function(v) autoNotifyRoles = v; if not v then table.clear(announcedRoles) else task.spawn(refreshTarget) end end)
serverMods:AddButton("\x53how Murderer Chance", showMurdererChance)
serverMods:AddButton("\x52efresh Roles", function() refreshTarget(true) end)
serverMods:AddLabel("\x52oles are sampled during the 10 second countdown.")

local gunUtilities = tab:AddSection("\x57ORLD • GUN", "\x41uto GG, pickup, aura, notifications and bind button")
gunUtilities:AddToggle("\x45nable Auto GG", setAutoGG)
gunUtilities:AddLabel("\x41uto GG picks up GunDrop while you do not have a Gun.")
gunUtilities:AddButton("\x47rab Gun", requestGrabGun)
gunUtilities:AddToggle("\x47un Aura", setGunAura)
gunUtilities:AddSlider("\x47un Aura Range", 5, 250, gunUtilityState.auraRange, function(value)
    gunUtilityState.auraRange = tonumber(value) or gunUtilityState.auraRange
end)
gunUtilities:AddToggle("\x41uto Notify Dropped Gun", function(enabled)
    gunUtilityState.droppedGunNotify = enabled == true
    gunUtilityState.UpdateDropWatchers()
end)
gunUtilities:AddToggle("\x47un Pickup Notify", function(enabled)
    gunUtilityState.gunPickupNotify = enabled == true
    gunUtilityState.wasHoldingGun = hasGunInInventory()
end)
gunUtilities:AddToggle("\x45nable Grab Gun Bind Button", setGrabGunBindButton)
gunUtilities:AddSlider("\x47rab Gun Bind Button Size", 5, 25, gunUtilityState.bindButtonSize * 100, function(value)
    gunUtilityState.bindButtonSize = (tonumber(value) or 11) / 100
    updateGrabGunBindButtonSize()
end)
gunUtilities:AddLabel("\x52ound Grab Gun button: drag it to move; its size and position ar\x65 saved.")

do
    local function buildCombatControls()
        local combatAim=tab:AddSection("\x53ILENT AIM", "\x53erver FireServer redirect")
        combatAim:AddToggle("\x45nabled", toggle)
        combatAim:AddToggle("\x57all Check", function(v) config.wallCheck=v==true end)
        combatAim:AddToggle("\x53how Shoot Murder Button", setShootButtonVisible)
        combatAim:AddToggle("\x4cock Shoot Murder Button", function(v) config.lockShootButton=v==true end)

         
        do
            local priorOmega = getgenv().__NoirOmegaRuntime
            if type(priorOmega) == "\x74able" and type(priorOmega.Stop) == "\x66unction" then pcall(priorOmega.Stop) end
            local omega = { enabled = false, adaptive = true, locked = false, upgrade = false, monitor = false, stopped = false,
                lastApply = -1e9, currentProfile = "\x2d-", classicIndex = nil, statusControl = nil,
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
                return { Sim = point.Sim, Interval = point.Interval, H = point.H, V = point.V, X = point.X, Y = point.Y, Z = point.Z }, "\x43lassic " .. string.char(64 + index)
            end
            local function omegaConfig(ping)
                if omega.adaptive then
                    omega.classicIndex = nil
                    return interpolateProfile(ping), "\x44ynamic " .. tostring(ping) .. "\x20ms"
                end
                return classicOmegaProfile(ping)
            end
            local function destroyOmegaMonitor()
                if omega.monitorGui then omega.monitorGui:Destroy() end
                omega.monitorGui, omega.monitorLabels = nil, nil
                for _, parent in ipairs({ guiParent, CoreGui, LocalPlayer:FindFirstChildOfClass("\x50layerGui") }) do
                    if parent then
                        local stale = parent:FindFirstChild("\x4eoirOmegaMonitor")
                        if stale then stale:Destroy() end
                    end
                end
            end
            local function createOmegaMonitor()
                if omega.monitorGui and omega.monitorGui.Parent then return end
                destroyOmegaMonitor()
                local parent = guiParent
                if typeof(parent) ~= "\x49nstance" then parent = LocalPlayer:FindFirstChildOfClass("\x50layerGui") end
                if typeof(parent) ~= "\x49nstance" then return end
                local screen = New("\x53creenGui", { Parent = parent, Name = "\x4eoirOmegaMonitor", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 82, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
                 
                 
                local card = New("\x46rame", { Parent = screen, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 72), Size = UDim2.fromOffset(184, 78), BackgroundColor3 = Color3.fromRGB(10, 12, 16), BackgroundTransparency = .56, BorderSizePixel = 0, ClipsDescendants = true })
                corner(card, 12); stroke(card, C.accent, .55)
                local accent = New("\x46rame", { Parent = card, Position = UDim2.fromOffset(0, 11), Size = UDim2.fromOffset(2, 43), BackgroundColor3 = C.accent, BackgroundTransparency = .18, BorderSizePixel = 0 }); corner(accent, 2)
                local title = New("\x54extLabel", { Parent = card, Position = UDim2.fromOffset(13, 6), Size = UDim2.fromOffset(164, 15), BackgroundTransparency = 1, Text = "\x4fMEGA • SILENT AIM", TextColor3 = C.text, TextSize = 10, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd })
                local function line(y)
                    return New("\x54extLabel", { Parent = card, Position = UDim2.fromOffset(13, y), Size = UDim2.fromOffset(164, 14), BackgroundTransparency = 1, Text = "", TextColor3 = C.dim, TextSize = 9, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd })
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
                    local control = noirMirrorControls["\x70istol." .. key]
                    if type(control) == "\x74able" and type(control.SetValue) == "\x66unction" then
                        local current = type(control.GetValue) == "\x66unction" and control:GetValue() or nil
                        if tonumber(current) ~= tonumber(value) then pcall(control.SetValue, control, value) end
                    end
                end
            end
            local function updateOmegaStatus()
                local state = not omega.enabled and "\x4fFF" or omega.locked and "\x4cOCKED" or "\x4fN"
                local mode = omega.adaptive and "\x41daptive" or "\x43lassic"
                local summary = "\x4fmega: " .. state .. "\x20 |  " .. pingMilliseconds() .. "\x20ms  |  " .. mode .. "\x20 |  " .. omega.currentProfile .. (omega.upgrade and "\x20 +Upgrade" or "")
                if omega.statusControl then omega.statusControl:SetValue(summary) end
                if omega.monitorLabels then
                    setText(omega.monitorLabels.state, state .. "\x20• " .. mode .. (omega.upgrade and "\x20• UPGRADE" or ""))
                    setText(omega.monitorLabels.config, tostring(pingMilliseconds()) .. "\x20ms • " .. omega.currentProfile)
                    setText(omega.monitorLabels.values, "\x53:" .. tostring(config.maxSimulationMs) .. "\x20I:" .. tostring(config.predictionIntervalMs) .. "\x20H/V:" .. tostring(config.horizontalMultiplier) .. "\x2f" .. tostring(config.verticalMultiplier))
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
                local text = "\x4fmega • Ping " .. pingMilliseconds() .. "\x20ms • " .. (omega.adaptive and "\x41daptive" or "\x43lassic") .. "\x20• " .. omega.currentProfile
                notify(text, 4)
                print("\x5bNoir Omega] " .. text)
            end

            combatAim:AddLabel("\x4fMEGA AUTO REVERT • Noir prediction profile")
            combatAim:AddToggle("\x4fmega Auto Revert", function(enabled)
                omega.enabled = enabled == true
                reconfigureOmega()
            end)
            combatAim:AddToggle("\x4fmega Adaptive Engine", function(enabled)
                omega.adaptive = enabled == true
                omega.classicIndex = nil
                reconfigureOmega()
            end)
            combatAim:AddToggle("\x4fmega Lock Config", function(enabled)
                omega.locked = enabled == true
                updateOmegaStatus()
            end)
            combatAim:AddToggle("\x4fmega Upgrade Mode", function(enabled)
                omega.upgrade = enabled == true
                reconfigureOmega()
            end)
            combatAim:AddToggle("\x4fmega Monitor", function(enabled)
                omega.monitor = enabled == true
                if omega.monitor then createOmegaMonitor() else destroyOmegaMonitor() end
                updateOmegaStatus()
            end)
            combatAim:AddButton("\x4fmega Print Telemetry", telemetryOmega)
            omega.statusControl = combatAim:AddLabel("\x4fmega: OFF  |  -- ms  |  Adaptive  |  --")
            combatAim:AddLabel("\x4fmega changes pistol prediction only. Disable it to stop updates\x3b the last applied values stay in place.")

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

        combatAim:AddLabel("\x47UN UTILITIES • native Noir implementation")
        combatAim:AddParagraph("\x47UN TRIGGER BOT", "\x53hoots once when the centre cursor/crosshair points at the Murde\x72er. Works with mobile Shift Lock; move off target and back to a\x72m the next shot.")
        combatAim:AddToggle("\x47un Trigger Bot", function(v) config.gunTriggerBot = v == true end)
        combatAim:AddToggle("\x47un Trigger Bot Wall Check", function(v) config.gunTriggerBotWallCheck = v == true end)
        combatAim:AddToggle("\x41pply Prediction On Gun Trigger Bot", function(v) config.gunTriggerBotPrediction = v == true end)

        local combatGun=tab:AddSection("\x47UN", "\x47un targeting controls")
            combatGun:AddToggle("\x50iercer Bullet", setPiercerBullet)
        combatGun:AddLabel("\x49f a wall is between you and the target, the shot starts on thei\x72 side of the wall. Turn this on with Silent Aim.")

        local combatKnife=tab:AddSection("\x4bNIFE SILENT AIM", "\x4eearest player or Sheriff-only targeting")
        combatKnife:AddToggle("\x4bnife Silent Aim", function(v)
            config.knifeEnabled=v==true
            if config.knifeEnabled then installHook() end
        end)
         
        local oldKnifeAuraKey = "\x4bNIFE SILENT AIM::Knife Radius"
        local newKnifeAuraKey = "\x4bNIFE SILENT AIM::Knife Throw Aura"
        if NoirPersistence.data.sliders[newKnifeAuraKey] == nil and NoirPersistence.data.sliders[oldKnifeAuraKey] ~= nil then
            NoirPersistence.data.sliders[newKnifeAuraKey] = NoirPersistence.data.sliders[oldKnifeAuraKey]
            NoirPersistence.Save()
        end
         
         
        local knifeAuraToggle = combatKnife:AddToggle("\x4bnifeThrown Aura", function(v) config.knifeThrownAura=v==true end)
        if NoirPersistence.data.toggles["\x4bNIFE SILENT AIM::KnifeThrown Aura"] == nil then
            knifeAuraToggle(true)
        end
        combatKnife:AddSlider("\x4bnife Throw Aura", 1, 40, config.knifeRadius, function(v) config.knifeRadius = tonumber(v) or config.knifeRadius end)
        combatKnife:AddToggle("\x4bnife Wall Check", function(v) config.knifeWallCheck=v==true end)
        combatKnife:AddToggle("\x50rioritize Sheriff", function(v)
            config.knifePrioritizeSheriff=v==true
        end)
        combatKnife:AddLabel("\x4eATIVE KNIFE UTILITIES • equipped Knife only")
        local function refreshKnifeUtilities()
            local runtime = getgenv().__NoirKnifeUtilityRuntime
            if type(runtime) == "\x74able" and type(runtime.Refresh) == "\x66unction" then pcall(runtime.Refresh, runtime) end
        end
        local function knifeRuntimeCall(method)
            local runtime = getgenv().__NoirKnifeUtilityRuntime
            if type(runtime) == "\x74able" and type(runtime[method]) == "\x66unction" then return runtime[method](runtime) end
            notify("\x4bnife utilities are starting", 2)
            return nil
        end
        combatKnife:AddToggle("\x49nstant Throw", function(v)
            config.knifeInstantThrow = v == true
            if config.knifeInstantThrow then installHook() end
        end)
        combatKnife:AddToggle("\x46ast Throw", function(v)
            config.knifeFastThrow = v == true
            if config.knifeFastThrow then installHook() end
        end)
        combatKnife:AddToggle("\x41uto Kill Everyone", function(v) config.knifeAutoKillEveryone = v == true end)
        combatKnife:AddToggle("\x41uto Kill Sheriff", function(v) config.knifeAutoKillSheriff = v == true end)
        combatKnife:AddButton("\x4bill Everyone", function() knifeRuntimeCall("\x4billEveryone") end)
        combatKnife:AddButton("\x4bill Sheriff", function() knifeRuntimeCall("\x4billSheriff") end)
        combatKnife:AddToggle("\x45nable Kill Sheriff Bindable Button", function(v) config.knifeSheriffBind = v == true; refreshKnifeUtilities() end)
        local function knifePlayerChoices()
            local values = { "\x4e/A" }
            for _, player in ipairs(getPlayers()) do if player ~= LocalPlayer then values[#values + 1] = player.Name end end
            table.sort(values, function(a, b) if a == "\x4e/A" then return true elseif b == "\x4e/A" then return false end return string.lower(a) < string.lower(b) end)
            return values
        end
        local selectedKnifePlayer = combatKnife:AddDropdown("\x4bill Player", knifePlayerChoices(), function(v) config.knifeKillPlayer = tostring(v or "\x4e/A") end)
        combatKnife:AddButton("\x4bill Player", function() knifeRuntimeCall("\x4billSelected") end)
        combatKnife:AddButton("\x52efresh Kill Player List", function() selectedKnifePlayer:Refresh(knifePlayerChoices(), config.knifeKillPlayer) end)
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
                if key=="\x6danualPingMs" then noirMirrorControls[prefix=="\x6bnife." and "\x6bnifeManualPingMs" or "\x6danualPingMs"]=control end
            end
            addToggle("\x70rioritizePing","\x50rioritize Your Ping")
            addToggle("\x70redictJump","\x50redict Jump")
            addToggle("\x70redictLag","\x50redict Lag")
            addSlider("\x6daxSimulationMs","\x50rediction Max Simulation",20,300)
            addSlider("\x70redictionIntervalMs","\x50rediction Interval",1,100)
            addSlider("\x6danualPingMs","\x50rediction Ping",10,1000)
            addSlider("\x6fffsetX","\x58 Position Offset",-100,100)
            addSlider("\x6fffsetY","\x59 Position Offset",-100,100)
            addSlider("\x6fffsetZ","\x5a Position Offset",-100,100)
            addSlider("\x68orizontalMultiplier","\x48orizontal Multiplier",0,400)
            addSlider("\x76erticalMultiplier","\x56ertical Multiplier",0,400)
        end

        local pistolPrediction=tab:AddSection("\x50ISTOL PREDICTION", "\x49ndependent server-shot prediction")
        addPrediction(pistolPrediction,config,"\x70istol.")
        local knifePrediction=tab:AddSection("\x4bNIFE PREDICTION", "\x49ndependent KnifeThrown prediction")
        addPrediction(knifePrediction,config.knifeAim,"\x6bnife.")

        local profileKeys={"\x61daptive","\x66ixedLead","\x65xtraLead","\x70rioritizePing","\x70redictJump","\x70redictLag","\x6daxSimulationMs","\x70redictionIntervalMs","\x6danualPingMs","\x6fffsetX","\x6fffsetY","\x6fffsetZ","\x68orizontalMultiplier","\x76erticalMultiplier"}
        local function profileSnapshot(profile)
            local data={}
            for _,key in ipairs(profileKeys) do data[key]=profile[key] end
            return data
        end
        local function applyProfile(profile,data)
            if typeof(data)~="\x74able" then return false end
            for _,key in ipairs(profileKeys) do
                if typeof(data[key])==typeof(profile[key]) then profile[key]=data[key] end
            end
            if type(syncRevertControls)=="\x66unction" then syncRevertControls() end
            return true
        end
        local function profilePresetNames(kind)
            local names={"\x64efault"}
            if type(listfiles)=="\x66unction" then
                ensurePresetFolder()
                local ok,files=pcall(listfiles,PRESET_FOLDER)
                if ok and typeof(files)=="\x74able" then
                    local suffix="\x5f"..string.lower(kind).."\x25.preset$"
                    for _,file in ipairs(files) do
                        local base=tostring(file):gsub("\\","\x2f"):match("\x28[^/]+)"..suffix)
                        if base and not table.find(names,base) then names[#names+1]=base end
                    end
                end
            end
            table.sort(names)
            return names
        end
        local function addProfileConfig(title,kind,profile)
            local section=tab:AddSection(title,"\x49ndependent "..kind.."\x20preset storage")
            local selected="\x64efault"
            section:AddDropdown("\x59our Presets",profilePresetNames(kind),function(v) selected=cleanPresetName(v) end)
            section:AddTextBox("\x50reset Name",function(v) selected=cleanPresetName(v) end)
            section:AddButton("\x53ave "..kind.."\x20Preset",function()
                if type(writefile)~="\x66unction" then notify("\x45xecutor does not support writefile",4) return end
                ensurePresetFolder()
                local payload={version=4,kind=string.lower(kind),profile=profileSnapshot(profile)}
                local ok,encoded=pcall(function() return HttpService:JSONEncode(payload) end)
                local path=PRESET_FOLDER.."\x2f"..selected.."\x5f"..string.lower(kind).."\x2epreset"
                if ok and pcall(writefile,path,xorPreset(encoded)) then notify(kind.."\x20preset saved: "..selected,3) else notify(kind.."\x20preset save failed",4) end
            end)
            section:AddButton("\x4coad "..kind.."\x20Preset",function()
                if type(readfile)~="\x66unction" then notify("\x45xecutor does not support readfile",4) return end
                local path=PRESET_FOLDER.."\x2f"..selected.."\x5f"..string.lower(kind).."\x2epreset"
                local ok,data=pcall(function() return HttpService:JSONDecode(xorPreset(readfile(path))) end)
                if ok and typeof(data)=="\x74able" and data.kind==string.lower(kind) and applyProfile(profile,data.profile) then notify(kind.."\x20preset loaded: "..selected,3) else notify(kind.."\x20preset not found or invalid",4) end
            end)
        end
        addProfileConfig("\x50ISTOL NOIR CONFIG","\x50istol",config)
        addProfileConfig("\x4bNIFE NOIR CONFIG","\x4bnife",config.knifeAim)

        syncRevertControls=function()
            for _,entry in ipairs({
                {"\x70istol.prioritizePing",config.prioritizePing},{"\x70istol.predictJump",config.predictJump},{"\x70istol.predictLag",config.predictLag},
                {"\x6bnife.prioritizePing",config.knifeAim.prioritizePing},{"\x6bnife.predictJump",config.knifeAim.predictJump},{"\x6bnife.predictLag",config.knifeAim.predictLag}
            }) do
                local control=noirMirrorControls[entry[1]]
                if type(control)=="\x66unction" then pcall(control,entry[2]) end
            end
            for _,entry in ipairs({
                {"\x70istol.maxSimulationMs",config.maxSimulationMs},{"\x70istol.predictionIntervalMs",config.predictionIntervalMs},{"\x70istol.manualPingMs",config.manualPingMs},
                {"\x70istol.offsetX",config.offsetX},{"\x70istol.offsetY",config.offsetY},{"\x70istol.offsetZ",config.offsetZ},{"\x70istol.horizontalMultiplier",config.horizontalMultiplier},{"\x70istol.verticalMultiplier",config.verticalMultiplier},
                {"\x6bnife.maxSimulationMs",config.knifeAim.maxSimulationMs},{"\x6bnife.predictionIntervalMs",config.knifeAim.predictionIntervalMs},{"\x6bnife.manualPingMs",config.knifeAim.manualPingMs},
                {"\x6bnife.offsetX",config.knifeAim.offsetX},{"\x6bnife.offsetY",config.knifeAim.offsetY},{"\x6bnife.offsetZ",config.knifeAim.offsetZ},{"\x6bnife.horizontalMultiplier",config.knifeAim.horizontalMultiplier},{"\x6bnife.verticalMultiplier",config.knifeAim.verticalMultiplier}
            }) do
                local control=noirMirrorControls[entry[1]]
                if type(control)=="\x74able" and type(control.SetValue)=="\x66unction" then pcall(control.SetValue,control,entry[2]) end
            end
        local omegaRuntime = getgenv().__NoirOmegaRuntime
        if type(omegaRuntime) == "\x74able" and type(omegaRuntime.Sync) == "\x66unction" then omegaRuntime.Sync() end
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
            if remote:IsA("\x52emoteEvent") then
                first = first or remote
                table.insert(remoteConnections, remote.OnClientEvent:Connect(function(...) pcall(handler, ...) end))
            elseif remote:IsA("\x42indableEvent") then
                first = first or remote
                table.insert(remoteConnections, remote.Event:Connect(function(...) pcall(handler, ...) end))
            end
        end
    end
    return first
end

connectRemote("\x50layerDataChanged", function(first, second)
    if typeof(second) == "\x74able" and typeof(first) == "\x49nstance" and first:IsA("\x50layer") then
        consumeData({ [first.Name] = second }, false)
    else
        consumeData(first, false)
    end
end)
connectRemote("\x52oundStart", function(timerValue, roundData)
    beginRoundTimer(timerValue)
    murderer, sheriff, hero = nil, nil, nil
    table.clear(roleCache); table.clear(announcedRoles)
    if typeof(roundData) == "\x74able" then consumeData(roundData, true) end
    refreshTarget(true)
end)
local function finishRound()
    resetRoundTimer()
    murderer, sheriff, hero = nil, nil, nil
    table.clear(roleCache); table.clear(announcedRoles)
end
connectRemote("\x52oundEndFade", finishRound)
connectRemote("\x52oundEnd", finishRound)
connectRemote("\x52oleSelect", function() task.spawn(refreshTarget) end)
connectRemote("\x53howRoleSelect", function() task.spawn(refreshTarget) end)
connectRemote("\x53howRoleSelectNew", function() task.spawn(refreshTarget) end)
connectRemote("\x43hangeTarget", function() task.spawn(refreshTarget) end)
connectRemote("\x47iveWeapon", function() task.spawn(refreshTarget) end)
connectRemote("\x4billEvent", function() task.spawn(refreshTarget) end)
connectRemote("\x47ameOver", finishRound)
connectRemote("\x56ictoryScreen", finishRound)
connectRemote("\x53tealth", function() notify("\x53tealth activated", 3) end)
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
        if config.enabled or config.knifeEnabled then
            local part = targetPart()
            local settings = config.enabled and config or config.knifeAim
            if part then sampleMotion(part, settings) end
        end
        task.wait(1 / 30)
    end
end)

aimHeld = (config.aimKey == "\x4eone")
UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local key = input.KeyCode.Name
        if key == config.aimKey then aimHeld = true end
        if key == config.autoFireKey then autoFireHeld = true end
        if key == config.toggleKey and config.toggleKey ~= "\x4eone" then toggle(not config.enabled) end
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        if config.aimKey == "\x4douseButton1" then aimHeld = true end
        if config.autoFireKey == "\x4douseButton1" then autoFireHeld = true end
    elseif input.UserInputType == Enum.UserInputType.Touch then
        if config.aimKey == "\x54ouch" then aimHeld = true end
        if config.autoFireKey == "\x54ouch" then autoFireHeld = true end
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local key = input.KeyCode.Name
        if key == config.aimKey then aimHeld = false end
        if key == config.autoFireKey then autoFireHeld = false end
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        if config.aimKey == "\x4douseButton1" then aimHeld = false end
        if config.autoFireKey == "\x4douseButton1" then autoFireHeld = false end
    elseif input.UserInputType == Enum.UserInputType.Touch then
        if config.aimKey == "\x54ouch" then aimHeld = false end
        if config.autoFireKey == "\x54ouch" then autoFireHeld = false end
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
    winScale.Scale = .025
    win.Visible = true
    TweenService:Create(win, TweenInfo.new(.74, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = targetPosition, BackgroundTransparency = .04, Rotation = 0,
    }):Play()
    TweenService:Create(winScale, TweenInfo.new(.78, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end)

notify("\x4eOIR V6.1  •  EVENT HORIZON ONLINE  •  " .. tostring(#getPlayers()) .. "\x20PLAYERS", 4)

do
    local function makeWorldPluginTab(base)
        local proxy = {}
        setmetatable(proxy, {
            __index = function(_, key)
                if key == "\x41ddSection" then
                    return function(_, name, description)
                        name = tostring(name or "\x50lugin")
                        if string.sub(name, 1, 6) ~= "\x57ORLD " then
                            name = "\x57ORLD • " .. name
                        end
                        return base:AddSection(name, description or "")
                    end
                end
                local method = base[key]
                if type(method) == "\x66unction" then
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
        game_name = "\x4durder Mystery 2",
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
if not shared or type(shared.CreateTab) ~= "\x66unction" then
    warn("\x5bFE Animations] Load this file through the current Overdrive H p\x6cugin menu.")
    return
end
local KEY = "\x4fDH_FEAnimationsRuntime_v2"
if type(_G[KEY]) == "\x74able" and _G[KEY].alive then
    if type(shared.Notify)=="\x66unction" then
        pcall(shared.Notify,"\x46E Animations is already loaded. Use its existing tab.",4)
    end
    return
end
local Players = game:GetService("\x50layers")
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then warn("\x5bFE Animations] LocalPlayer unavailable."); return end
local HttpService = game:GetService("\x48ttpService")
local runtime = {version=3,alive=true, initializing=true, enabled=false, generation=0,
    selections={all="\x44efault",idle="\x44efault",walk="\x44efault",run="\x44efault",jump="\x44efault",climb="\x44efault",fall="\x44efault"}}
local FILE = "\x4eoir Hub/configs/ODH_FEAnimations_settings.json"
runtime.settingsFile=FILE
local warnings={}
local function WarnOnce(key,text)
    if warnings[key] then return end
    warnings[key]=true
    warn("\x5bFE Animations] "..text)
    if type(shared.Notify)=="\x66unction" then pcall(shared.Notify,"\x46E Animations: "..text,5) end
end
local environment={}
if type(getgenv)=="\x66unction" then
    local ok,result=pcall(getgenv)
    if ok and type(result)=="\x74able" then environment=result end
end
local fileRead=type(readfile)=="\x66unction" and readfile or environment.readfile
local fileWrite=type(writefile)=="\x66unction" and writefile or environment.writefile
local fileExists=type(isfile)=="\x66unction" and isfile or environment.isfile
local canPersist=type(fileRead)=="\x66unction" and type(fileWrite)=="\x66unction"
runtime.saveStatus=canPersist and "\x4eot saved" or "\x55navailable"

local animPresets = {
    ["\x44efault"] = nil,
    ["\x4fG Rthro Run"] = {run = "\x68ttp://www.roblox.com/asset/?id=9801814462"},
    ["\x56ampire"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=1083445855",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=1083450166",
        walk  = "\x68ttp://www.roblox.com/asset/?id=1083473930",
        run   = "\x68ttp://www.roblox.com/asset/?id=1083462077",
        jump  = "\x68ttp://www.roblox.com/asset/?id=1083455352",
        climb = "\x68ttp://www.roblox.com/asset/?id=1083439238",
        fall  = "\x68ttp://www.roblox.com/asset/?id=1083443587"
    },
    ["\x48ero"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=616111295",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=616113536",
        walk  = "\x68ttp://www.roblox.com/asset/?id=616122287",
        run   = "\x68ttp://www.roblox.com/asset/?id=616117076",
        jump  = "\x68ttp://www.roblox.com/asset/?id=616115533",
        climb = "\x68ttp://www.roblox.com/asset/?id=616104706",
        fall  = "\x68ttp://www.roblox.com/asset/?id=616108001"
    },
    ["\x5aombie Classic"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=616158929",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=616160636",
        walk  = "\x68ttp://www.roblox.com/asset/?id=616168032",
        run   = "\x68ttp://www.roblox.com/asset/?id=616163682",
        jump  = "\x68ttp://www.roblox.com/asset/?id=616161997",
        climb = "\x68ttp://www.roblox.com/asset/?id=616156119",
        fall  = "\x68ttp://www.roblox.com/asset/?id=616157476"
    },
    ["\x4dage"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=707742142",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=707855907",
        walk  = "\x68ttp://www.roblox.com/asset/?id=707897309",
        run   = "\x68ttp://www.roblox.com/asset/?id=707861613",
        jump  = "\x68ttp://www.roblox.com/asset/?id=707853694",
        climb = "\x68ttp://www.roblox.com/asset/?id=707826056",
        fall  = "\x68ttp://www.roblox.com/asset/?id=707829716"
    },
    ["\x47host"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=616006778",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=616008087",
        walk  = "\x68ttp://www.roblox.com/asset/?id=616010382",
        run   = "\x68ttp://www.roblox.com/asset/?id=616013216",
        jump  = "\x68ttp://www.roblox.com/asset/?id=616008936",
        climb = "\x68ttp://www.roblox.com/asset/?id=616003713",
        fall  = "\x68ttp://www.roblox.com/asset/?id=616005863"
    },
    ["\x45lder"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=845397899",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=845400520",
        walk  = "\x68ttp://www.roblox.com/asset/?id=845403856",
        run   = "\x68ttp://www.roblox.com/asset/?id=845386501",
        jump  = "\x68ttp://www.roblox.com/asset/?id=845398858",
        climb = "\x68ttp://www.roblox.com/asset/?id=845392038",
        fall  = "\x68ttp://www.roblox.com/asset/?id=845396048"
    },
    ["\x4cevitation"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=616006778",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=616008087",
        walk  = "\x68ttp://www.roblox.com/asset/?id=616013216",
        run   = "\x68ttp://www.roblox.com/asset/?id=616010382",
        jump  = "\x68ttp://www.roblox.com/asset/?id=616008936",
        climb = "\x68ttp://www.roblox.com/asset/?id=616003713",
        fall  = "\x68ttp://www.roblox.com/asset/?id=616005863"
    },
    ["\x41stronaut"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=891621366",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=891633237",
        walk  = "\x68ttp://www.roblox.com/asset/?id=891667138",
        run   = "\x68ttp://www.roblox.com/asset/?id=891636393",
        jump  = "\x68ttp://www.roblox.com/asset/?id=891627522",
        climb = "\x68ttp://www.roblox.com/asset/?id=891609353",
        fall  = "\x68ttp://www.roblox.com/asset/?id=891617961"
    },
    ["\x4einja"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=656117400",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=656118341",
        walk  = "\x68ttp://www.roblox.com/asset/?id=656121766",
        run   = "\x68ttp://www.roblox.com/asset/?id=656118852",
        jump  = "\x68ttp://www.roblox.com/asset/?id=656117878",
        climb = "\x68ttp://www.roblox.com/asset/?id=656114359",
        fall  = "\x68ttp://www.roblox.com/asset/?id=656115606"
    },
    ["\x57erewolf"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=1083195517",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=1083214717",
        walk  = "\x68ttp://www.roblox.com/asset/?id=1083178339",
        run   = "\x68ttp://www.roblox.com/asset/?id=1083216690",
        jump  = "\x68ttp://www.roblox.com/asset/?id=1083218792",
        climb = "\x68ttp://www.roblox.com/asset/?id=1083182000",
        fall  = "\x68ttp://www.roblox.com/asset/?id=1083189019"
    },
    ["\x43artoon"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=742637544",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=742638445",
        walk  = "\x68ttp://www.roblox.com/asset/?id=742640026",
        run   = "\x68ttp://www.roblox.com/asset/?id=742638842",
        jump  = "\x68ttp://www.roblox.com/asset/?id=742637942",
        climb = "\x68ttp://www.roblox.com/asset/?id=742636889",
        fall  = "\x68ttp://www.roblox.com/asset/?id=742637151"
    },
    ["\x50irate"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=750781874",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=750782770",
        walk  = "\x68ttp://www.roblox.com/asset/?id=750785693",
        run   = "\x68ttp://www.roblox.com/asset/?id=750783738",
        jump  = "\x68ttp://www.roblox.com/asset/?id=750782230",
        climb = "\x68ttp://www.roblox.com/asset/?id=750779899",
        fall  = "\x68ttp://www.roblox.com/asset/?id=750780242"
    },
    ["\x53neaky"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=1132473842",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=1132477671",
        walk  = "\x68ttp://www.roblox.com/asset/?id=1132510133",
        run   = "\x68ttp://www.roblox.com/asset/?id=1132494274",
        jump  = "\x68ttp://www.roblox.com/asset/?id=1132489853",
        climb = "\x68ttp://www.roblox.com/asset/?id=1132461372",
        fall  = "\x68ttp://www.roblox.com/asset/?id=1132469004"
    },
    ["\x54oy"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=782841498",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=782845736",
        walk  = "\x68ttp://www.roblox.com/asset/?id=782843345",
        run   = "\x68ttp://www.roblox.com/asset/?id=782842708",
        jump  = "\x68ttp://www.roblox.com/asset/?id=782847020",
        climb = "\x68ttp://www.roblox.com/asset/?id=782843869",
        fall  = "\x68ttp://www.roblox.com/asset/?id=782846423"
    },
    ["\x4bnight"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=657595757",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=657568135",
        walk  = "\x68ttp://www.roblox.com/asset/?id=657552124",
        run   = "\x68ttp://www.roblox.com/asset/?id=657564596",
        jump  = "\x68ttp://www.roblox.com/asset/?id=658409194",
        climb = "\x68ttp://www.roblox.com/asset/?id=658360781",
        fall  = "\x68ttp://www.roblox.com/asset/?id=657600338"
    },
    ["\x43onfident"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=1069977950",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=1069987858",
        walk  = "\x68ttp://www.roblox.com/asset/?id=1070017263",
        run   = "\x68ttp://www.roblox.com/asset/?id=1070001516",
        jump  = "\x68ttp://www.roblox.com/asset/?id=1069984524",
        climb = "\x68ttp://www.roblox.com/asset/?id=1069946257",
        fall  = "\x68ttp://www.roblox.com/asset/?id=1069973677"
    },
    ["\x50opstar"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=1212900985",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=1212900985",
        walk  = "\x68ttp://www.roblox.com/asset/?id=1212980338",
        run   = "\x68ttp://www.roblox.com/asset/?id=1212980348",
        jump  = "\x68ttp://www.roblox.com/asset/?id=1212954642",
        climb = "\x68ttp://www.roblox.com/asset/?id=1213044953",
        fall  = "\x68ttp://www.roblox.com/asset/?id=1212900995"
    },
    ["\x50rincess"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=941003647",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=941013098",
        walk  = "\x68ttp://www.roblox.com/asset/?id=941028902",
        run   = "\x68ttp://www.roblox.com/asset/?id=941015281",
        jump  = "\x68ttp://www.roblox.com/asset/?id=941008832",
        climb = "\x68ttp://www.roblox.com/asset/?id=940996062",
        fall  = "\x68ttp://www.roblox.com/asset/?id=941000007"
    },
    ["\x43owboy"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=1014390418",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=1014398616",
        walk  = "\x68ttp://www.roblox.com/asset/?id=1014421541",
        run   = "\x68ttp://www.roblox.com/asset/?id=1014401683",
        jump  = "\x68ttp://www.roblox.com/asset/?id=1014394726",
        climb = "\x68ttp://www.roblox.com/asset/?id=1014380606",
        fall  = "\x68ttp://www.roblox.com/asset/?id=1014384571"
    },
    ["\x50atrol"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=1149612882",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=1150842221",
        walk  = "\x68ttp://www.roblox.com/asset/?id=1151231493",
        run   = "\x68ttp://www.roblox.com/asset/?id=1150967949",
        jump  = "\x68ttp://www.roblox.com/asset/?id=1150944216",
        climb = "\x68ttp://www.roblox.com/asset/?id=1148811837",
        fall  = "\x68ttp://www.roblox.com/asset/?id=1148863382"
    },
    ["\x5aombie FE"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=3489171152",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=3489171152",
        walk  = "\x68ttp://www.roblox.com/asset/?id=3489174223",
        run   = "\x68ttp://www.roblox.com/asset/?id=3489173414",
        jump  = "\x68ttp://www.roblox.com/asset/?id=616161997",
        climb = "\x68ttp://www.roblox.com/asset/?id=616156119",
        fall  = "\x68ttp://www.roblox.com/asset/?id=616157476"
    },
    ["\x43atwalk Glam"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=133806214992291",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=133806214992291",
        walk  = "\x68ttp://www.roblox.com/asset/?id=109168724482748",
        run   = "\x68ttp://www.roblox.com/asset/?id=81024476153754",
        jump  = "\x68ttp://www.roblox.com/asset/?id=116936326516985",
        climb = "\x68ttp://www.roblox.com/asset/?id=119377220967554",
        fall  = "\x68ttp://www.roblox.com/asset/?id=92294537340807"
    },
    ["\x41mazon Unboxed"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=98281136301627",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=98281136301627",
        walk  = "\x68ttp://www.roblox.com/asset/?id=90478085024465",
        run   = "\x68ttp://www.roblox.com/asset/?id=134824450619865",
        jump  = "\x68ttp://www.roblox.com/asset/?id=121454505477205",
        climb = "\x68ttp://www.roblox.com/asset/?id=121145883950231",
        fall  = "\x68ttp://www.roblox.com/asset/?id=94788218468396"
    },
    ["\x47low Motion"] = {
        idle1 = "\x68ttps://www.roblox.com/asset/?id=137764781910579",
        idle2 = "\x68ttps://www.roblox.com/asset/?id=137764781910579",
        walk  = "\x68ttp://www.roblox.com/asset/?id=85809016093530",
        run   = "\x68ttp://www.roblox.com/asset/?id=101925097435036",
        jump  = "\x68ttp://www.roblox.com/asset/?id=74159004634379",
        climb = "\x68ttp://www.roblox.com/asset/?id=108236155509584",
        fall  = "\x68ttps://www.roblox.com/asset/?id=98070939608691"
    },
    ["\x42ubbly"] = {
        idle1 = "\x68ttps://www.roblox.com/asset/?id=10921054344",
        idle2 = "\x68ttps://www.roblox.com/asset/?id=10921054344",
        walk  = "\x68ttp://www.roblox.com/asset/?id=10980888364",
        run   = "\x68ttp://www.roblox.com/asset/?id=10921057244",
        jump  = "\x68ttp://www.roblox.com/asset/?id=10921062673",
        climb = "\x68ttp://www.roblox.com/asset/?id=10921053544",
        fall  = "\x68ttps://www.roblox.com/asset/?id=10921061530"
    },
    ["\x41didas Comm"] = {
        idle1 = "\x68ttps://www.roblox.com/asset/?id=122257458498464",
        idle2 = "\x68ttps://www.roblox.com/asset/?id=122257458498464",
        walk  = "\x68ttp://www.roblox.com/asset/?id=122150855457006",
        run   = "\x68ttp://www.roblox.com/asset/?id=82598234841035",
        jump  = "\x68ttp://www.roblox.com/asset/?id=75290611992385",
        climb = "\x68ttp://www.roblox.com/asset/?id=88763136693023",
        fall  = "\x68ttps://www.roblox.com/asset/?id=98600215928904"
    },
    ["\x4bATSEYE"] = {
        idle1 = "\x68ttps://www.roblox.com/asset/?id=108187809145790",
        idle2 = "\x68ttps://www.roblox.com/asset/?id=108187809145790",
        walk  = "\x68ttp://www.roblox.com/asset/?id=99182913548783",
        run   = "\x68ttp://www.roblox.com/asset/?id=73117360545482",
        jump  = "\x68ttp://www.roblox.com/asset/?id=103632305262747",
        climb = "\x68ttp://www.roblox.com/asset/?id=106213237973858",
        fall  = "\x68ttps://www.roblox.com/asset/?id=127802717128367"
    },
    ["\x57icked Popular"] = {
        idle1 = "\x68ttps://www.roblox.com/asset/?id=118832222982049",
        idle2 = "\x68ttps://www.roblox.com/asset/?id=118832222982049",
        walk  = "\x68ttp://www.roblox.com/asset/?id=92072849924640",
        run   = "\x68ttp://www.roblox.com/asset/?id=72301599441680",
        jump  = "\x68ttp://www.roblox.com/asset/?id=104325245285198",
        climb = "\x68ttp://www.roblox.com/asset/?id=131326830509784",
        fall  = "\x68ttps://www.roblox.com/asset/?id=121152442762481"
    },
    ["\x44izzy"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=132806359718468",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=132806359718468",
        walk  = "\x68ttp://www.roblox.com/asset/?id=110106034100313",
        run   = "\x68ttp://www.roblox.com/asset/?id=138305342272849",
        jump  = "\x68ttp://www.roblox.com/asset/?id=108564434408211",
        climb = "\x68ttp://www.roblox.com/asset/?id=93550710314258",
        fall  = "\x68ttp://www.roblox.com/asset/?id=138967706335414"
    },
    ["\x57DTL"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=92849173543269",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=92849173543269",
        walk  = "\x68ttp://www.roblox.com/asset/?id=73718308412641",
        run   = "\x68ttp://www.roblox.com/asset/?id=135515454877967",
        jump  = "\x68ttp://www.roblox.com/asset/?id=78508480717326",
        climb = "\x68ttp://www.roblox.com/asset/?id=129447497744818",
        fall  = "\x68ttp://www.roblox.com/asset/?id=78147885297412"
    },
    ["\x42illie Eilish"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=102934602884410",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=102934602884410",
        walk  = "\x68ttp://www.roblox.com/asset/?id=81877886552514",
        run   = "\x68ttp://www.roblox.com/asset/?id=100920560634123",
        jump  = "\x68ttp://www.roblox.com/asset/?id=117602630922781",
        climb = "\x68ttp://www.roblox.com/asset/?id=117873469361430",
        fall  = "\x68ttp://www.roblox.com/asset/?id=81072141180299"
    },
    ["\x43ute Bouncy"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=88464649697812",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=88464649697812",
        walk  = "\x68ttp://www.roblox.com/asset/?id=98713727778027",
        run   = "\x68ttp://www.roblox.com/asset/?id=133955346539948",
        jump  = "\x68ttp://www.roblox.com/asset/?id=124147147418885",
        climb = "\x68ttp://www.roblox.com/asset/?id=95542189442725",
        fall  = "\x68ttp://www.roblox.com/asset/?id=128620818122982"
    },
    ["\x43ute"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=85735421117197",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=85735421117197",
        walk  = "\x68ttp://www.roblox.com/asset/?id=140409718187215",
        run   = "\x68ttp://www.roblox.com/asset/?id=118375157537412",
        jump  = "\x68ttp://www.roblox.com/asset/?id=132381016103721",
        climb = "\x68ttp://www.roblox.com/asset/?id=86318575131600",
        fall  = "\x68ttp://www.roblox.com/asset/?id=77496925287217"
    },
    ["\x4aolly"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=136145727878709",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=136145727878709",
        walk  = "\x68ttp://www.roblox.com/asset/?id=83277136078444",
        run   = "\x68ttp://www.roblox.com/asset/?id=124419804298310",
        jump  = "\x68ttp://www.roblox.com/asset/?id=122115816220842",
        climb = "\x68ttp://www.roblox.com/asset/?id=107190574095036",
        fall  = "\x68ttp://www.roblox.com/asset/?id=85263802503331"
    },
    ["\x43ute Kawaii"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=72311682331639",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=72311682331639",
        walk  = "\x68ttp://www.roblox.com/asset/?id=107212872423561",
        run   = "\x68ttp://www.roblox.com/asset/?id=118582510545072",
        jump  = "\x68ttp://www.roblox.com/asset/?id=112952548321695",
        climb = "\x68ttp://www.roblox.com/asset/?id=126383408493776",
        fall  = "\x68ttp://www.roblox.com/asset/?id=83307333809322"
    },
    ["\x44oll 3.0"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=83032187271383",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=83032187271383",
        walk  = "\x68ttp://www.roblox.com/asset/?id=78434960966537",
        run   = "\x68ttp://www.roblox.com/asset/?id=129768396663808",
        jump  = "\x68ttp://www.roblox.com/asset/?id=75369057994828",
        climb = "\x68ttp://www.roblox.com/asset/?id=112371892133970",
        fall  = "\x68ttp://www.roblox.com/asset/?id=81027444073311"
    },
    ["\x56ictoria Model"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=132069965396465",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=132069965396465",
        walk  = "\x68ttp://www.roblox.com/asset/?id=84814915379579",
        run   = "\x68ttp://www.roblox.com/asset/?id=84814915379579",
        jump  = "\x68ttp://www.roblox.com/asset/?id=78163261581163",
        climb = "\x68ttp://www.roblox.com/asset/?id=87772134905508",
        fall  = "\x68ttp://www.roblox.com/asset/?id=110073924253388"
    },
    ["\x42ike/Bicyclist"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=126390120399173",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=136791517336633",
        walk  = "\x68ttp://www.roblox.com/asset/?id=98707881660541",
        run   = "\x68ttp://www.roblox.com/asset/?id=102775737211919",
        jump  = "\x68ttp://www.roblox.com/asset/?id=129144847881258",
        climb = "\x68ttp://www.roblox.com/asset/?id=88267082364595",
        fall  = "\x68ttp://www.roblox.com/asset/?id=110684787086498"
    },
    ["\x41nimal"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=128838183008466",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=99689776099970",
        walk  = "\x68ttp://www.roblox.com/asset/?id=112238064449133",
        run   = "\x68ttp://www.roblox.com/asset/?id=97412731442167",
        jump  = "\x68ttp://www.roblox.com/asset/?id=123565665274439",
        climb = "\x68ttp://www.roblox.com/asset/?id=75085836535654",
        fall  = "\x68ttp://www.roblox.com/asset/?id=124705831982259"
    },
    ["\x49t-Girl Essential Model"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=132232079260125",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=102440789796215",
        walk  = "\x68ttp://www.roblox.com/asset/?id=86579666661215",
        run   = "\x68ttp://www.roblox.com/asset/?id=83336349930143",
        jump  = "\x68ttp://www.roblox.com/asset/?id=103382156539106",
        climb = "\x68ttp://www.roblox.com/asset/?id=77385815954046",
        fall  = "\x68ttp://www.roblox.com/asset/?id=127262648208409"
    },
    ["\x4fldschool"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=10921230744",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=10921232093",
        walk  = "\x68ttp://www.roblox.com/asset/?id=10921244891",
        run   = "\x68ttp://www.roblox.com/asset/?id=10921240218",
        jump  = "\x68ttp://www.roblox.com/asset/?id=10921242013",
        climb = "\x68ttp://www.roblox.com/asset/?id=10921229866",
        fall  = "\x68ttp://www.roblox.com/asset/?id=10921241244"
    },
    ["\x53pider"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=112316814377814",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=103439018552145",
        walk  = "\x68ttp://www.roblox.com/asset/?id=109976439277879",
        run   = "\x68ttp://www.roblox.com/asset/?id=119985832593347",
        jump  = "\x68ttp://www.roblox.com/asset/?id=87979233462906",
        climb = "\x68ttp://www.roblox.com/asset/?id=119278342251995",
        fall  = "\x68ttp://www.roblox.com/asset/?id=71112238570777"
    },
    ["\x4aoy"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=119957475250242",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=101200477339169",
        walk  = "\x68ttp://www.roblox.com/asset/?id=112597572150963",
        run   = "\x68ttp://www.roblox.com/asset/?id=96521659811743",
        jump  = "\x68ttp://www.roblox.com/asset/?id=82500357520736",
        climb = "\x68ttp://www.roblox.com/asset/?id=110061716873830",
        fall  = "\x68ttp://www.roblox.com/asset/?id=132095139090357"
    },
    ["\x46lying Aura"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=122426844584505",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=122426844584505",
        walk  = "\x68ttp://www.roblox.com/asset/?id=83077254246622",
        run   = "\x68ttp://www.roblox.com/asset/?id=77053251062908",
        jump  = "\x68ttp://www.roblox.com/asset/?id=125422018244301",
        climb = "\x68ttp://www.roblox.com/asset/?id=95973965948476",
        fall  = "\x68ttp://www.roblox.com/asset/?id=109790195947848"
    },

    ["\x46HA V2"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=77320840005481",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=77320840005481",
        walk  = "\x68ttp://www.roblox.com/asset/?id=134493251445479",
        run   = "\x68ttp://www.roblox.com/asset/?id=122214533401932",
        jump  = "\x68ttp://www.roblox.com/asset/?id=80078165493816",
        climb = "\x68ttp://www.roblox.com/asset/?id=114562994724647",
        fall  = "\x68ttp://www.roblox.com/asset/?id=98383265864436"
    },

    ["\x53ilent Nurse"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=111047244862844",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=111047244862844",
        walk  = "\x68ttp://www.roblox.com/asset/?id=94196382152901",
        run   = "\x68ttp://www.roblox.com/asset/?id=94196382152901",
        jump  = "\x68ttp://www.roblox.com/asset/?id=106098057235980",
        climb = "\x68ttp://www.roblox.com/asset/?id=108985375609705",
        fall  = "\x68ttp://www.roblox.com/asset/?id=131579609334755"
    },

    ["\x53upermodel"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=91917730726110",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=91917730726110",
        walk  = "\x68ttp://www.roblox.com/asset/?id=90320132970213",
        run   = "\x68ttp://www.roblox.com/asset/?id=112051258179255",
        jump  = "\x68ttp://www.roblox.com/asset/?id=91931403363860",
        climb = "\x68ttp://www.roblox.com/asset/?id=82728029306069",
        fall  = "\x68ttp://www.roblox.com/asset/?id=119173466228299"
    },

    ["\x45nchanted Fairy"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=73650178233095",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=73650178233095",
        walk  = "\x68ttp://www.roblox.com/asset/?id=94547195663763",
        run   = "\x68ttp://www.roblox.com/asset/?id=76909584337943",
        jump  = "\x68ttp://www.roblox.com/asset/?id=120533712803667",
        climb = "\x68ttp://www.roblox.com/asset/?id=140663406485180",
        fall  = "\x68ttp://www.roblox.com/asset/?id=100947971756348"
    },

    ["\x46urry"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=111821292044705",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=111821292044705",
        walk  = "\x68ttp://www.roblox.com/asset/?id=104011441852459",
        run   = "\x68ttp://www.roblox.com/asset/?id=87770060317862",
        jump  = "\x68ttp://www.roblox.com/asset/?id=102635582722041",
        climb = "\x68ttp://www.roblox.com/asset/?id=76660530164497",
        fall  = "\x68ttp://www.roblox.com/asset/?id=137079985547592"
    },

    ["\x56lada Model"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=100139116433530",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=100139116433530",
        walk  = "\x68ttp://www.roblox.com/asset/?id=77983757225444",
        run   = "\x68ttp://www.roblox.com/asset/?id=116717848244930",
        jump  = "\x68ttp://www.roblox.com/asset/?id=120751055172567",
        climb = "\x68ttp://www.roblox.com/asset/?id=70966616077778",
        fall  = "\x68ttp://www.roblox.com/asset/?id=136118518255777"
    },
    ["\x526 Converter"] = {
        idle1 = "\x68ttp://www.roblox.com/asset/?id=90040240627854",
        idle2 = "\x68ttp://www.roblox.com/asset/?id=90040240627854",
        walk  = "\x68ttp://www.roblox.com/asset/?id=92149852708428",
        run   = "\x68ttp://www.roblox.com/asset/?id=72259383092959",
        jump  = "\x68ttp://www.roblox.com/asset/?id=130519980521511",
        climb = "\x68ttp://www.roblox.com/asset/?id=80369171706383",
        fall  = "\x68ttp://www.roblox.com/asset/?id=130011792193300"
    },
}

local animMap = {
    idle  = { folder = "\x69dle",  slots = { { child = "\x41nimation1", origKey = "\x69dle1" }, { child = "\x41nimation2", origKey = "\x69dle2" } } },
    walk  = { folder = "\x77alk",  slots = { { child = "\x57alkAnim",   origKey = "\x77alk"  } } },
    run   = { folder = "\x72un",   slots = { { child = "\x52unAnim",    origKey = "\x72un"   } } },
    jump  = { folder = "\x6aump",  slots = { { child = "\x4aumpAnim",   origKey = "\x6aump"  } } },
    climb = { folder = "\x63limb", slots = { { child = "\x43limbAnim",  origKey = "\x63limb" } } },
    fall  = { folder = "\x66all",  slots = { { child = "\x46allAnim",   origKey = "\x66all"  } } },
}

local allAnimOptions = {
    "\x44efault", "\x56ampire", "\x48ero", "\x5aombie Classic", "\x4dage", "\x47host",
    "\x45lder", "\x4cevitation", "\x41stronaut", "\x4einja", "\x57erewolf", "\x43artoon",
    "\x50irate", "\x53neaky", "\x54oy", "\x4bnight", "\x43onfident", "\x50opstar",
    "\x50rincess", "\x43owboy", "\x50atrol", "\x5aombie FE", "\x43atwalk Glam", "\x41mazon Unboxed",
    "\x47low Motion", "\x42ubbly", "\x41didas Comm", "\x4bATSEYE", "\x57icked Popular",
    "\x44izzy", "\x57DTL", "\x42illie Eilish", "\x43ute Bouncy", "\x43ute",
    "\x4aolly", "\x43ute Kawaii", "\x44oll 3.0", "\x56ictoria Model",
    "\x42ike/Bicyclist", "\x41nimal", "\x49t-Girl Essential Model",
    "\x4fldschool", "\x53pider", "\x4aoy", "\x46lying Aura", "\x46HA V2", "\x53ilent Nurse", "\x53upermodel", "\x45nchanted Fairy", "\x46urry", "\x56lada Model", "\x526 Converter"
}

local runAnimOptions = {
    "\x44efault", "\x4fG Rthro Run", "\x56ampire", "\x48ero", "\x5aombie Classic", "\x4dage", "\x47host",
    "\x45lder", "\x4cevitation", "\x41stronaut", "\x4einja", "\x57erewolf", "\x43artoon",
    "\x50irate", "\x53neaky", "\x54oy", "\x4bnight", "\x43onfident", "\x50opstar",
    "\x50rincess", "\x43owboy", "\x50atrol", "\x5aombie FE", "\x43atwalk Glam", "\x41mazon Unboxed",
    "\x47low Motion", "\x42ubbly", "\x41didas Comm", "\x4bATSEYE", "\x57icked Popular",
    "\x44izzy", "\x57DTL", "\x42illie Eilish", "\x43ute Bouncy", "\x43ute",
    "\x4aolly", "\x43ute Kawaii", "\x44oll 3.0", "\x56ictoria Model",
    "\x42ike/Bicyclist", "\x41nimal", "\x49t-Girl Essential Model",
    "\x4fldschool", "\x53pider", "\x4aoy", "\x46lying Aura", "\x46HA V2", "\x53ilent Nurse", "\x53upermodel", "\x45nchanted Fairy", "\x46urry", "\x56lada Model", "\x526 Converter"
}

local allowed={}
for key in pairs(runtime.selections) do
    allowed[key]={}
    for _,name in ipairs(key=="\x72un" and runAnimOptions or allAnimOptions) do allowed[key][name]=true end
end
local function LoadSettings()
    if not canPersist then
        WarnOnce("\x66ilesystem","\x72eadfile/writefile unavailable; settings are session-only.")
        return
    end
    if type(fileExists)=="\x66unction" then
        local ok,exists=pcall(fileExists,FILE)
        if ok and not exists then return end
    end
    local ok,text=pcall(fileRead,FILE)
    if not ok then
        if type(fileExists)=="\x66unction" then
            runtime.saveStatus="\x52ead error"
            WarnOnce("\x72ead","\x43annot read the settings file.")
        end
        return
    end
    local decoded,data=pcall(function() return HttpService:JSONDecode(text) end)
    if not decoded or type(data)~="\x74able" or data.version~=1 or type(data.selections)~="\x74able" then
        runtime.saveStatus="\x49nvalid file"
        WarnOnce("\x72ead","\x49nvalid settings file; kept unchanged until you edit a setting.")
        return
    end
    if type(data.enabled)=="\x62oolean" then runtime.enabled=data.enabled end
    for key in pairs(runtime.selections) do
        local value=data.selections[key]
        if type(value)=="\x73tring" and allowed[key][value] then runtime.selections[key]=value end
    end
    runtime.saveStatus="\x4coaded"
end
local function SaveSettings()
    if not runtime.alive or runtime.initializing or not canPersist then return false end
    local ok,err=pcall(function()
        fileWrite(FILE,HttpService:JSONEncode({version=1,enabled=runtime.enabled,selections=runtime.selections}))
    end)
    if not ok then
        runtime.saveStatus="\x57rite error"
        WarnOnce("\x77rite","\x43annot save settings: "..tostring(err))
        return false
    end
    warnings.write=nil
    runtime.saveStatus="\x53aved"
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
    local humanoid=character and character:FindFirstChildOfClass("\x48umanoid")
    if not humanoid then return true end
    local animator=humanoid:FindFirstChildOfClass("\x41nimator")
    local ok,tracks=pcall(function()
        return animator and animator:GetPlayingAnimationTracks() or humanoid:GetPlayingAnimationTracks()
    end)
    if not ok then
        WarnOnce("\x74racks","\x43annot enumerate active animation tracks: "..tostring(tracks))
        return false
    end
    local stopped=true
    for _,track in ipairs(tracks) do
        pcall(function() track:AdjustWeight(0,0) end)
        local stopOK=pcall(function() track:Stop(0) end)
        if not stopOK then stopped=false end
    end
    if not stopped then WarnOnce("\x73top","\x53ome animation tracks could not be stopped.") end
    return stopped
end
local function FinishRestart(animate,lease)
    if restarts[animate]~=lease then return true end
    local stopOK=StopTracks(animate)
    local ok,err=pcall(function() animate.Disabled=lease.wasDisabled end)
    if ok then
        restarts[animate]=nil
    else
        WarnOnce("\x72estart","\x43ould not restart Animate: "..tostring(err))
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
        WarnOnce("\x61pply","\x41nimation update failed: "..tostring(err))
        return false
    end
    task.spawn(function()
        task.wait(0.1)
        if restarts[animate]~=lease then return end
        local restarted=FinishRestart(animate,lease)
        if not restarted and runtime.alive then Status("\x52eset incomplete — press Reapply / Retry") end
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
            WarnOnce("\x63onflict","\x41nother script changed an animation; its ID was left untouched.")
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
        if not Current(character,ticket) then return nil,"\x43ancelled" end
        local humanoid=character:FindFirstChildOfClass("\x48umanoid")
        if humanoid and humanoid.RigType~=Enum.HumanoidRigType.R15 then
            return nil,"\x5215 required — settings retained"
        end
        if humanoid and humanoid.Health<=0 then return nil,"\x57aiting for respawn" end
        local animate=character:FindFirstChild("\x41nimate")
        if humanoid and animate then
            local slots={}
            local complete=true
            for animType,info in pairs(animMap) do
                local folder=animate:FindFirstChild(info.folder)
                for _,slot in ipairs(info.slots) do
                    local anim=folder and folder:FindFirstChild(slot.child)
                    if not anim or not anim:IsA("\x41nimation") or anim.AnimationId=="" then
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
    return nil,"\x41nimate not ready — use Reapply / Retry"
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
        if name=="\x44efault" then name=runtime.selections.all end
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
        Status(RestoreOriginals() and "\x4fFF — original animations restored" or "\x4fFF — restoration pending; press Retry")
        return
    end
    local character=LocalPlayer.Character
    if not character then Status("\x57aiting for character"); return end
    Status("\x41pplying saved selection...")
    task.spawn(function()
        local ok,err=pcall(function()
            local ready,reason=ReadySlots(character,ticket)
            if not Current(character,ticket) then return end
            if not ready then Status(reason); return end
            if ApplyReady(ready,true) then Status("\x4fN — selection applied") else Status("\x43ould not apply — press Retry") end
            task.wait(0.5)
            if not Current(character,ticket) then return end
            ready,reason=ReadySlots(character,ticket)
            if not Current(character,ticket) then return end
            if ready then
                if ApplyReady(ready) then Status("\x4fN — selection applied") else Status("\x43ould not apply — press Retry") end
            else Status(reason) end
        end)
        if not ok and Current(character,ticket) then
            Status("\x41nimation error — press Retry")
            WarnOnce("\x77orker",tostring(err))
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

local tab=shared.CreateTab("\x46E Animations","\x2fmellnikovden968-web/CFG_PM2/refs/heads/main/icon")
local section=tab:AddSection("\x46E Animations","\x61ux0on presets • R15 • full track reset • auto-save")
statusLabel=section:AddLabel("\x4coading settings...",true)
section:AddParagraph("\x53aved settings","\x54oggle and all animation choices are saved automatically. Indivi\x64ual Default uses All Animations; All Animations = Default uses \x79our avatar's originals. R15 only.")
local toggle=section:AddToggle("\x45nable FE Anims",function(value)
    if runtime.initializing or not runtime.alive then return end
    runtime.enabled=value==true
    SaveSettings()
    RequestApply()
end)
local dropdowns={
    {label="\x41ll Animations",key="\x61ll"},
    {label="\x49dle Animation",key="\x69dle"},
    {label="\x57alk Animation",key="\x77alk"},
    {label="\x52un Animation",key="\x72un"},
    {label="\x4aump Animation",key="\x6aump"},
    {label="\x43limb Animation",key="\x63limb"},
    {label="\x46all Animation",key="\x66all"},
}
for _,dd in ipairs(dropdowns) do
    local key=dd.key
    local control=section:AddDropdown(dd.label,key=="\x72un" and runAnimOptions or allAnimOptions,function(value)
        if runtime.initializing or not runtime.alive or type(value)~="\x73tring" or not allowed[key][value] then return end
        runtime.selections[key]=value
        SaveSettings()
        if runtime.enabled then RequestApply() end
    end)
    if control then
        local ok=pcall(function() control:Select(runtime.selections[key]) end)
        if not ok then WarnOnce("\x75i","\x43ould not display a saved selection; the backing setting is reta\x69ned.") end
    end
end
section:AddParagraph("\x46ull animation reset","\x53witching presets, toggling OFF or pressing Retry briefly stops \x41LL current animation tracks, including emotes/tool poses, then \x72estarts Animate. Nothing is blocked permanently.")
section:AddButton("\x52eapply / Retry",function() if runtime.alive then RequestApply() end end)
if runtime.enabled and type(toggle)=="\x66unction" then
    local ok=pcall(toggle)
    if not ok then WarnOnce("\x74oggle","\x43ould not display the saved toggle state.") end
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
            warn("\x5bNoir embedded plugin: Anims.lua.txt] " .. tostring(__pluginError))
            notify("\x41nims.lua.txt failed to load: " .. tostring(__pluginError), 7)
        end
    end
    do
        local __pluginOk, __pluginError = xpcall(function()
local ODHX = (function()
    local X = { ready=false, silent=false, restoring=false, replay=true, records={}, byKey={}, data={version=1, controls={}}, external=false }
    X.id, X.title, X.file = "\x42JP", "\x42omb Jump+", "\x4eoir Hub/configs/ODH_BJP_settings.json"
    local host = odh_shared_plugins
    assert(host and type(host.CreateTab)=="\x66unction", X.title .. "\x3a load through the current Overdrive H plugin menu")
    local env = {}
    if type(getgenv)=="\x66unction" then local ok,g=pcall(getgenv); if ok and type(g)=="\x74able" then env=g end end
    local rd = type(readfile)=="\x66unction" and readfile or env.readfile
    local wr = type(writefile)=="\x66unction" and writefile or env.writefile
    local exists = type(isfile)=="\x66unction" and isfile or env.isfile
    local http = game:GetService("\x48ttpService")
    local reported = {}
    local function report(message)
        if reported[message] then return end
        reported[message]=true
        warn("\x5b" .. X.title .. "\x5d " .. message)
        if type(host.Notify)=="\x66unction" then pcall(host.Notify, X.title .. "\x3a " .. message, 5) end
    end
    X.Report = report
    local function finite(v) return type(v)=="\x6eumber" and v==v and math.abs(v)<math.huge end
    local function encode(v, depth)
        depth=depth or 0
        if depth>20 then error("\x73ettings nesting too deep") end
        if typeof(v)=="\x43olor3" then return {__odhColor={v.R,v.G,v.B}} end
        local t=type(v)
        if t=="\x62oolean" or t=="\x73tring" then return v end
        if t=="\x6eumber" then if finite(v) then return v end; return nil end
        if t=="\x74able" then
            local result={}
            for k,item in pairs(v) do
                if type(k)=="\x73tring" or type(k)=="\x6eumber" then result[k]=encode(item,depth+1) end
            end
            return result
        end
        return nil
    end
    local function decode(v, depth)
        depth=depth or 0
        if depth>20 then error("\x73ettings nesting too deep") end
        if type(v)~="\x74able" then return v end
        if v.__odhColor then
            local c=v.__odhColor
            assert(type(c)=="\x74able" and finite(c[1]) and finite(c[2]) and finite(c[3]),"\x69nvalid color")
            return Color3.new(math.clamp(c[1],0,1),math.clamp(c[2],0,1),math.clamp(c[3],0,1))
        end
        local result={}
        for k,item in pairs(v) do result[k]=decode(item,depth+1) end
        return result
    end
    X.Encode, X.Decode = encode, decode
    if not X.external then
        if type(rd)=="\x66unction" and type(wr)=="\x66unction" then
            local present=true
            if type(exists)=="\x66unction" then local ok,v=pcall(exists,X.file); if ok then present=v end end
            if present then
                local ok,text=pcall(rd,X.file)
                if ok then
                    local good,data=pcall(function() return decode(http:JSONDecode(text)) end)
                    if good and type(data)=="\x74able" and data.version==1 and type(data.controls)=="\x74able" then X.data=data
                    else X.badFile=true; report("\x49nvalid settings file; defaults loaded. A manual change will rep\x6cace it.") end
                elseif type(exists)=="\x66unction" then report("\x43ould not read settings file: " .. tostring(text)); X.badFile=true end
            end
        else report("\x72eadfile/writefile unavailable; settings last only for this sess\x69on.") end
    end
    local tab
    X.shared=setmetatable({}, {__index=host})
    X.shared.Notify=function(text,seconds)
        if X.restoring then return end
        if type(host.Notify)=="\x66unction" then return host.Notify(text,seconds or 3) end
    end
    local function key(section,name,kind) return section .. "\x20/ " .. kind .. "\x20/ " .. name end
    local function safeValue(r,v)
        if r.kind=="\x54oggle" then if type(v)=="\x62oolean" then return v end
        elseif r.kind=="\x53lider" then if finite(v) then return math.clamp(v,r.min,r.max) end
        elseif r.kind=="\x43olorpicker" then if typeof(v)=="\x43olor3" then return v end
        elseif r.kind=="\x44ropdown" then
            for _,item in ipairs(r.items) do if v==item then return v end end
        end
        return nil
    end
    local function show(r,v)
        if v==nil or r.shown==v then return end
        local prior=X.silent; X.silent=true
        local ok,err=pcall(function()
            if r.kind=="\x54oggle" then
                if r.visual~=v then assert(type(r.handle)=="\x66unction","\x41ddToggle must return a closure"); r.handle() end
            elseif r.kind=="\x53lider" then r.handle:SetValue(v)
            elseif r.kind=="\x43olorpicker" then r.handle:SetRGBValue(v)
            elseif r.kind=="\x44ropdown" then r.handle:Select(v) end
        end)
        X.silent=prior
        if ok then r.shown=v else report("\x55I sync failed: " .. r.name .. "\x3a " .. tostring(err)) end
    end
    function X.Bind(section,name,kind,getter)
        local r=X.byKey[key(section,name,kind)]
        assert(r,"\x55nknown binding " .. section .. "\x20/ " .. name)
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
                if not X.backend or not X.backend(X.data) then error("\x6eative settings file could not be saved") end
            elseif type(wr)=="\x66unction" then
                wr(X.file,http:JSONEncode(encode(X.data)))
            end
        end)
        X.committing=false
        if not ok then report("\x53ettings save failed: " .. tostring(err)) end
    end
    function X.Restore()
        X.restoring=true
        for _,togglePass in ipairs({false,true}) do
            for _,r in ipairs(X.records) do
                if not r.exclude and ((r.kind=="\x54oggle")==togglePass) then
                    local v=safeValue(r,X.data.controls[r.key])
                    if v==nil and r.get then local ok,x=pcall(r.get); if ok then v=safeValue(r,x) end end
                    if v==nil then v=r.default end
                    if v~=nil then
                        show(r,v)
                        local ok,err=pcall(r.callback,v)
                        if not ok then report("\x52estore failed: " .. r.name .. "\x3a " .. tostring(err)) end
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
            if r.kind=="\x54oggle" and not r.exclude then X.Set(r.section,r.name,r.kind,false,true) end
        end
    end
    function X.shared.AddSection(name,subtitle)
        if not tab then tab=host.CreateTab(X.title,"\x2fmellnikovden968-web/CFG_PM2/refs/heads/main/icon") end
        local raw=tab:AddSection(name,subtitle or "")
        local section={Name=name,Raw=raw}
        local function register(kind,label,callback,default,min,max,items)
            local r={section=name,name=label,kind=kind,callback=callback,default=default,min=min,max=max,items=items,visual=false}
            r.key=key(name,label,kind)
            r.exclude=(name=="🔑\x20Keys")
            X.records[#X.records+1]=r; X.byKey[r.key]=r
            local function changed(v)
                if kind=="\x54oggle" then r.visual=(v==true) end
                if not X.ready or X.silent or X.restoring or X.stopped then return end
                v=safeValue(r,v); if v==nil then return end
                r.shown=v
                local ok,err=pcall(callback,v)
                if ok then
                    r.value=v
                    if not r.exclude then X.data.controls[r.key]=v end
                    X.Commit()
                else report("\x43allback failed: " .. label .. "\x3a " .. tostring(err)) end
            end
            if kind=="\x54oggle" then r.handle=raw:AddToggle(label,changed)
            elseif kind=="\x53lider" then r.handle=raw:AddSlider(label,min,max,default,changed)
            elseif kind=="\x43olorpicker" then r.handle=raw:AddColorpicker(label,default,changed)
            elseif kind=="\x44ropdown" then r.handle=raw:AddDropdown(label,items,changed) end
            return r.handle
        end
        function section:AddToggle(label,cb) return register("\x54oggle",label,cb,false) end
        function section:AddSlider(label,min,max,default,cb) return register("\x53lider",label,cb,default,min,max) end
        function section:AddColorpicker(label,default,cb) return register("\x43olorpicker",label,cb,default) end
        function section:AddDropdown(label,items,cb) return register("\x44ropdown",label,cb,items[1],nil,nil,items) end
        local function action(cb)
            return function(...)
                if not X.ready or X.stopped then return end
                local ok,err=pcall(cb,...)
                if not ok then report("\x41ction failed: " .. tostring(err)) end
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
        local player=game:GetService("\x50layers").LocalPlayer
        while object and object~=game do
            table.insert(parts,1,object==player and "\x24LocalPlayer" or object.Name)
            object=object.Parent
            if #parts>32 then return nil end
        end
        if object~=game then return nil end
        return parts
    end
    function X.Resolve(parts)
        if type(parts)~="\x74able" then return nil end
        local object=game
        for _,name in ipairs(parts) do
            if name=="\x24LocalPlayer" then object=game:GetService("\x50layers").LocalPlayer
            elseif type(name)=="\x73tring" and object then object=object:FindFirstChild(name)
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
    local registry=rawget(_G,"\x4fDH_2026_PluginRuntimes")
    if type(registry)~="\x74able" then registry={}; rawset(_G,"\x4fDH_2026_PluginRuntimes",registry) end
    local previous=registry[X.id]
    if previous and type(previous.Stop)=="\x66unction" then pcall(previous.Stop) end
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
    if taskType == "\x52BXScriptConnection" then
        task:Disconnect()
    elseif taskType == "\x49nstance" then
        task:Destroy()
    elseif taskType == "\x66unction" then
        task()
    elseif taskType == "\x74able" and type(task.Destroy) == "\x66unction" then
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
    Players = game:GetService("\x50layers"),
    ReplicatedStorage = game:GetService("\x52eplicatedStorage"),
    RunService = game:GetService("\x52unService"),
    UserInputService = game:GetService("\x55serInputService"),
    StarterGui = game:GetService("\x53tarterGui"),
    CoreGui = game:GetService("\x43oreGui"),
    Workspace = game:GetService("\x57orkspace"),
    TweenService = game:GetService("\x54weenService"),
    SoundService = game:GetService("\x53oundService")
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

local __RS   = getfserv("\x52unService")
local __UIS  = getfserv("\x55serInputService")
local __PLRS = getfserv("\x50layers")
local __TS   = getfserv("\x54weenService")

local BBSystem = {Buttons = {}, Connections = {}}

local function bb_safecallback(callback)
    if not callback then return end
    local ok, err = xpcall(callback, function(e) return debug.traceback(e) end)
    if not ok then warn("\x5bBB ERROR] " .. tostring(err)) end
end

local function BB_GetStorage()
    local parent = gethui and gethui()
    if not parent or typeof(parent) ~= "\x49nstance" then
        parent = getfserv("\x43oreGui")
    end
    if not parent or typeof(parent) ~= "\x49nstance" then
        parent = __PLRS.LocalPlayer:WaitForChild("\x50layerGui", 5)
    end
    if typeof(parent) ~= "\x49nstance" then
        parent = __PLRS.LocalPlayer:WaitForChild("\x50layerGui")
    end

    local sg = parent:FindFirstChild("\x40odh_bjp_bigstorage")
    if not sg then
        sg = Instance.new("\x53creenGui")
        sg.Name = "\x40odh_bjp_bigstorage"
        sg.ResetOnSpawn = false
        sg.IgnoreGuiInset = true
        pcall(function() sg.ScreenInsets = Enum.ScreenInsets.None end)
        sg.Parent = parent
    end
    return sg
end

local __BB_GRAD_SEQ = ColorSequence.new({
    ColorSequenceKeypoint.new(0,    __PCLR(0.0784314, 0.0784314, 0.0784314)),
    ColorSequenceKeypoint.new(0.75, __PCLR(0.0784314, 0.0784314, 0.54902)),
    ColorSequenceKeypoint.new(1,    __PCLR(0.470588,  0.156863,  0.470588))
})

local function BB_MakeDraggable(gui, func, ripple, sound)
    local dragging, dragInput, dragStart, startPos
    local hasMoved = false
    local tInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local normalSize    = __UD2(0, 200, 0, 75)
    local normalTxtSize = 24
    local bigSize       = __UD2(0, 220, 0, 82.5)
    local bigTxtSize    = 26.4

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
            __TS:Create(ripple, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Size = __UD2(0, 300, 0, 300),
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
        local sound = btn:FindFirstChild("\x53ound")
        if sound then
            sound.Volume = volume
        end
    end
    for id, btn in pairs(BindableButtons.Buttons) do
        local sound = btn:FindFirstChild("\x53ound")
        if sound then
            sound.Volume = volume
        end
    end
end

local function AddBigButton(id, text, func, isGold, customSize)
    if BBSystem.Buttons[id] then return end
    local storage = BB_GetStorage()
    local bb = Instance.new("\x54extButton")
    bb.Name = id
    bb.Size = customSize or __UD2(0, 200, 0, 75)
    bb.Position = __UD2(0.5, 0, 0.5, 0)
    bb.AnchorPoint = __V2(0.5, 0.5)
    bb.BackgroundColor3 = __RGB(255, 255, 255)
    bb.BackgroundTransparency = 0.9
    bb.BorderSizePixel = 0
    bb.Font = Enum.Font.Jura
    bb.Text = text
    bb.TextSize = 24
    bb.TextColor3 = __RGB(255, 255, 255)
    bb.TextWrapped = true
    bb.ClipsDescendants = true
    bb.AutoButtonColor = false
    bb.ZIndex = 5
    bb.Parent = storage

    Instance.new("\x55ICorner", bb).CornerRadius = __UD(0, 5)
    local stroke = Instance.new("\x55IStroke")
    stroke.Color = __RGB(255, 255, 255)
    stroke.Thickness = 1.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = bb
    local gradient = Instance.new("\x55IGradient")

    if isGold then
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0,    __RGB(255, 215, 0)),
            ColorSequenceKeypoint.new(0.5,  __RGB(255, 140, 0)),
            ColorSequenceKeypoint.new(1,    __RGB(184, 134, 11))
        })
    else
        gradient.Color = __BB_GRAD_SEQ
    end
    gradient.Parent = stroke

    local ripple = Instance.new("\x46rame")
    ripple.Name = "\x40ripple"
    ripple.BackgroundColor3 = isGold and __RGB(255, 215, 0) or __RGB(0, 155, 255)
    ripple.BackgroundTransparency = 0.5
    ripple.ZIndex = 4
    ripple.Size = __UD2(0, 0, 0, 0)
    ripple.AnchorPoint = __V2(0.5, 0.5)
    ripple.Visible = false
    ripple.Parent = bb
    Instance.new("\x55ICorner", ripple).CornerRadius = __UD(1, 0)

    local sound = Instance.new("\x53ound")
    sound.SoundId = "\x72bxassetid://3868133279"
    sound.Volume = muteButtonSounds and 0 or 0.5
    sound.Parent = bb

    BB_MakeDraggable(bb, func, ripple, sound)
    table.insert(gradientStrokes.fast, gradient)
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
if type(savedBindButtonPositions) ~= "\x74able" then
    savedBindButtonPositions = {}
    ODHX.data.bindButtonPositions = savedBindButtonPositions
end

BindableButtons = {Buttons = {}, Maids = {}, Count = 0, SavedPositions = savedBindButtonPositions}

function BindableButtons.GetSavedPosition(id)
    local value = BindableButtons.SavedPositions[id]
    if type(value) ~= "\x74able" then return nil end
    local xScale, xOffset = tonumber(value.xScale), tonumber(value.xOffset)
    local yScale, yOffset = tonumber(value.yScale), tonumber(value.yOffset)
    if not xScale or not xOffset or not yScale or not yOffset then return nil end
    return __UD2(xScale, xOffset, yScale, yOffset)
end

function BindableButtons.SavePosition(id, position)
    if not id or typeof(position) ~= "\x55Dim2" then return end
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
    [0] = "\x72bxassetid://86221076925479",
    [1] = "\x72bxassetid://96242665417546",
    [2] = "\x72bxassetid://97129189935336",
    [3] = "\x72bxassetid://76165862027868",
    [4] = "\x72bxassetid://125868092127496"
}

local __NORMAL_COLOR = ColorSequence.new({
    ColorSequenceKeypoint.new(0,    __RGB(35, 35, 40)),
    ColorSequenceKeypoint.new(0.22, __RGB(250, 250, 252)),
    ColorSequenceKeypoint.new(0.48, __RGB(70, 70, 78)),
    ColorSequenceKeypoint.new(0.72, __RGB(255, 255, 255)),
    ColorSequenceKeypoint.new(1,    __RGB(45, 45, 52)),
})

local __WAIT_COLOR = ColorSequence.new({
    ColorSequenceKeypoint.new(0,    __RGB(95, 30, 35)),
    ColorSequenceKeypoint.new(0.22, __RGB(255, 110, 120)),
    ColorSequenceKeypoint.new(0.48, __RGB(100, 35, 42)),
    ColorSequenceKeypoint.new(0.72, __RGB(255, 150, 155)),
    ColorSequenceKeypoint.new(1,    __RGB(70, 25, 30)),
})

local __GOLD_NORMAL_COLOR = ColorSequence.new({
    ColorSequenceKeypoint.new(0,    __RGB(75, 60, 25)),
    ColorSequenceKeypoint.new(0.22, __RGB(255, 225, 120)),
    ColorSequenceKeypoint.new(0.48, __RGB(110, 85, 30)),
    ColorSequenceKeypoint.new(0.72, __RGB(255, 240, 175)),
    ColorSequenceKeypoint.new(1,    __RGB(70, 55, 25)),
})

local __GOLD_WAIT_COLOR = __WAIT_COLOR

local function bind_safecallback(callback)
    if not callback then return end
    local ok, err = xpcall(callback, function(e) return debug.traceback(e) end)
    if not ok then warn("\x5bBIND ERROR] " .. tostring(err)) end
end

local function Bind_GetStorage()
    local parent = gethui and gethui()
    if not parent or typeof(parent) ~= "\x49nstance" then
        parent = getfserv("\x43oreGui")
    end
    if not parent or typeof(parent) ~= "\x49nstance" then
        parent = __PLRS.LocalPlayer:WaitForChild("\x50layerGui", 5)
    end
    if typeof(parent) ~= "\x49nstance" then
        parent = __PLRS.LocalPlayer:WaitForChild("\x50layerGui")
    end

    local sg = parent:FindFirstChild("\x40odh_bjp_bindstorage")
    if not sg then
        sg = Instance.new("\x53creenGui")
        sg.Name = "\x40odh_bjp_bindstorage"
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

    maid:GiveTask(ODHX.Connect(gui.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, input.Position, gui.Position
            hasMoved = false
            sound:Play()
            local absPos = gui.AbsolutePosition
            ripple.Position = __UD2(0, input.Position.X - absPos.X, 0, input.Position.Y - absPos.Y)
            ripple.Size = __UD2(0, 0, 0, 0)
            ripple.BackgroundTransparency = 0.5
            ripple.Visible = true
            __TS:Create(ripple, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Size = __UD2(0, 45, 0, 45),
                BackgroundTransparency = 1
            }):Play()

            local rel
            rel = ODHX.Connect(__UIS.InputEnded, function(endInput)
                if endInput.UserInputType == input.UserInputType then
                    dragging = false
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
    local buttonSizeY = customSize or 0.11
    local widthScale = buttonSizeY * (screen.Y / screen.X)
    local xPos = 0.1 + ((BindableButtons.Count % 8) * (widthScale + 0.005))
    local yPos = 0.9 - (math.floor(BindableButtons.Count / 8) * (buttonSizeY + 0.015))

    local ImageButton = Instance.new("\x49mageButton")
    ImageButton.Name = id
    ImageButton.Size = __UD2(widthScale, 0, buttonSizeY, 0)
    ImageButton.Position = BindableButtons.GetSavedPosition(id) or __UD2(xPos, 0, yPos, 0)
    ImageButton.AnchorPoint = __V2(0.5, 0.5)
    ImageButton.Image = ""
    ImageButton.BackgroundColor3 = __RGB(8, 8, 10)
    ImageButton.BackgroundTransparency = 0.28
    ImageButton.BorderSizePixel = 0
    ImageButton.ClipsDescendants = false
    ImageButton.AutoButtonColor = false
    Instance.new("\x55ICorner", ImageButton).CornerRadius = __UD(0, 1000)
    local outerButtonStroke = Instance.new("\x55IStroke", ImageButton)
    outerButtonStroke.Color = __PCLR(1, 1, 1)
    outerButtonStroke.Thickness = 2
    outerButtonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    local innerButtonStroke = Instance.new("\x55IStroke", ImageButton)
    innerButtonStroke.Color = __RGB(105, 105, 112)
    innerButtonStroke.Transparency = 0.5
    innerButtonStroke.Thickness = 1
    innerButtonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    ImageButton.Parent = Bind_GetStorage()
    buttonMaid:GiveTask(ImageButton)

    local TextLabel = Instance.new("\x54extLabel", ImageButton)
    TextLabel.Name = "\x40Text"
    TextLabel.Size = __UD2(0.8, 0, 0.8, 0)
    TextLabel.Position = __UD2(0.5, 0, 0.5, 0)
    TextLabel.AnchorPoint = __V2(0.5, 0.5)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Font = Enum.Font.Gotham
    TextLabel.Text = text
    TextLabel.TextColor3 = __PCLR(1, 1, 1)
    TextLabel.TextSize = 17
    TextLabel.TextWrapped = true
    TextLabel.ZIndex = 3

    local Aspect = Instance.new("\x55IAspectRatioConstraint", ImageButton)
    Aspect.AspectRatio = 1
    Aspect.AspectType = Enum.AspectType.ScaleWithParentSize

    local Stroke = Instance.new("\x55IGradient", outerButtonStroke)
    Stroke.Name = "\x40Stroke"
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

    local ripple = Instance.new("\x46rame")
    ripple.Name = "\x40ripple"
    ripple.BackgroundColor3 = isGold and __RGB(255, 215, 0) or __RGB(0, 155, 255)
    ripple.BackgroundTransparency = 0.5
    ripple.Size = __UD2(0, 0, 0, 0)
    ripple.AnchorPoint = __V2(0.5, 0.5)
    ripple.Visible = false
    ripple.ZIndex = 2
    ripple.Parent = ImageButton
    Instance.new("\x55ICorner", ripple).CornerRadius = __UD(1, 0)

    local sound = Instance.new("\x53ound")
    sound.SoundId = "\x72bxassetid://3868133279"
    sound.Volume = muteButtonSounds and 0 or 0.5
    sound.Parent = ImageButton

    Bind_MakeDraggable(ImageButton, buttonMaid, ripple, sound, clickFunc, function(position)
        BindableButtons.SavePosition(id, position)
    end)
    table.insert(gradientStrokes.fast, Stroke)

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

 
BindableButtons.DeleteBButton("\x62ombjump_bind")
BindableButtons.DeleteBButton("\x67oldbombjump_bind")

function BindableButtons.UpdateBButtonText(id, text, isWaiting, isGold)
    local btn = BindableButtons.Buttons[id]
    if not btn then return end

    local textLabel = btn:FindFirstChild("\x40Text")
    if textLabel then
        textLabel.Text = text
    end

    local stroke = btn:FindFirstChild("\x40Stroke", true)
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
    if success and result and typeof(result) == "\x49nstance" then
        return result
    end
    return Services.CoreGui
end

local hiddenGui = Instance.new("\x53creenGui")
hiddenGui.Name = "\x48iddenGui"
hiddenGui.ResetOnSpawn = false
hiddenGui.IgnoreGuiInset = true
hiddenGui.Parent = GetSafeGuiRoot()
RootMaid:GiveTask(hiddenGui)

local _game = shared.game_name
if not _game and (game.PlaceId == 142823291 or game.GameId == 66654135) then _game = "\x4durder Mystery 2" end

if _game == "\x4durder Mystery 2" or _game == "\x4durder Mystery Modded" then

local aboutSection = shared.AddSection("\x41bout")

aboutSection:AddParagraph("\x42omb Jump+", "\x50lugin Made by @lzzzx")

aboutSection:AddToggle("\x4dute Button SFX", function(bool)
    muteButtonSounds = bool
    UpdateAllButtonSounds()
end)

shared.Notify("\x42omb Jump+ Successfully Loaded", 5)

local CONFIG = {
    CooldownTime = 22.0,
    LaunchPower = 58,
    MinSize = 50,
    MaxSize = 300,
    DefaultSize = 90,
    BindDefaultSize = 0.11
}

local BOMB_NAMES = {
    "\x46akeBomb",
    "\x42omb",
    "\x47iftBomb",
    "\x50resentBomb",
    "\x53nowball",
    "\x43andyBomb"
}

local BOMB_CONFIGS = {
    FakeBomb = {
        Cooldown = 22,
        Power = 58,
        IsGold = false,
        RemotePath = "\x52emote",
        DisplayName = "\x42omb Jump"
    },
    GoldBomb = {
        Cooldown = 4,
        Power = 65,
        IsGold = true,
        RemotePath = "\x52emote",
        DisplayName = "\x47old Bomb Jump"
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
        bigButtonSize = config.bigButtonSize or 200,
        bindButtonSize = config.bindButtonSize or 0.11,
        bigBtnExists = false,
        bindBtnExists = false,
        bindButton = nil,
        activeTouches = {}
    }

    local systemMaid = Maid.new()
    RootMaid:GiveTask(systemMaid)

    local Sounds = {
        Click = Instance.new("\x53ound"),
        Cooldown = Instance.new("\x53ound")
    }
    Sounds.Click.SoundId = "\x72bxassetid://6895079853"
    Sounds.Click.Volume = 1.0
    Sounds.Cooldown.SoundId = "\x72bxassetid://138090596"
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

        local humanoid = character:FindFirstChild("\x48umanoid")
        if not humanoid then return false end

        local rootPart = character:FindFirstChild("\x48umanoidRootPart")
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
                isGold and "\x47BJ" or "\x42J", false, isGold)
        end
    end

    local function StartCooldown()
        state.onCooldown = true
        state.debounce = false
        local bigBtn = BBSystem.Buttons[config.bigButtonId]
        if bigBtn then bigBtn.Text = "\x57ait" end
        if state.bindButton then
            BindableButtons.UpdateBButtonText(config.bindButtonId,
                "\x57ait", true, isGold)
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
        if character and character:FindFirstChild("\x48umanoidRootPart") then
            local root = character.HumanoidRootPart
            local lookDir = Services.Workspace.CurrentCamera.CFrame.LookVector
            return root.Position + (lookDir * 3) + Vector3.new(0, -2, 0)
        end
        return nil
    end

    local function MakeCharacterJump()
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChild("\x48umanoid")
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
        if bombName == "\x46akeBomb" then
            bombNamesToCheck = BOMB_NAMES
        end

        for _, name in ipairs(bombNamesToCheck) do
            local bomb = character:FindFirstChild(name)
            if bomb then return true, bomb end
        end

        local backpack = LocalPlayer:FindFirstChild("\x42ackpack")
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
        if bombName == "\x46akeBomb" then
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
                local remote = bomb:FindFirstChild("\x52emote")
                if remote then
                    PlaySound(Sounds.Click)
                    pcall(function()
                        remote:FireServer(CFrame.new(position), 50)
                    end)
                end

                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("\x48umanoidRootPart")
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

    section:AddLabel(displayName .. "\x20Options")
    section:AddToggle("\x45nable Auto " .. displayName, function(bool)
        state.enabled = bool
    end)

    section:AddToggle("\x41uto-Get " .. bombName, function(bool)
        state.autoGetBomb = bool
        if bool then
            pcall(function()
                Services.ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer(bombName)
            end)
        end
    end)

    section:AddToggle("\x45nable " .. displayName .. "\x20Bind Button", function(e)
         
        local wantsBindButton = e == true
        state.bindBtnExists = wantsBindButton
        BindableButtons.DeleteBButton(config.bindButtonId)
        state.bindButton = nil
        if not wantsBindButton then return end

        local shortName = isGold and "\x47BJ" or "\x42J"
        BindableButtons.AddBButton(config.bindButtonId, shortName, FastBombJump, isGold, state.bindButtonSize)
        state.bindButton = BindableButtons.Buttons[config.bindButtonId]
        if state.bindButton then
            local screen = Services.Workspace.CurrentCamera.ViewportSize
            state.bindButton.Size = __UD2(state.bindButtonSize * (screen.Y / screen.X), 0, state.bindButtonSize, 0)
            BindableButtons.UpdateBButtonText(config.bindButtonId,
                state.onCooldown and "\x57ait" or shortName, state.onCooldown, isGold)
        end
    end)

    section:AddSlider(displayName .. "\x20Bind Button Size", 5, 25, state.bindButtonSize * 100, function(value)
        state.bindButtonSize = value / 100
        if state.bindButton then
            local screen = Services.Workspace.CurrentCamera.ViewportSize
            state.bindButton.Size = __UD2(state.bindButtonSize * (screen.Y / screen.X), 0, state.bindButtonSize, 0)
        end
    end)

    section:AddKeybind(displayName .. "\x20Keybind", config.keybind, FastBombJump)

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

    ODHX.Bind(section.Name, "\x45nable Auto " .. displayName, "\x54oggle", function() return state.enabled end)
    ODHX.Bind(section.Name, "\x41uto-Get " .. bombName, "\x54oggle", function() return state.autoGetBomb end)
    ODHX.Bind(section.Name, "\x45nable " .. displayName .. "\x20Bind Button", "\x54oggle", function() return state.bindBtnExists end)
    ODHX.Bind(section.Name, displayName .. "\x20Bind Button Size", "\x53lider", function() return state.bindButtonSize * 100 end)
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

local section = shared.AddSection("\x42omb Jump+")

local bombJumpSystem = CreateBombJumpSystem({
    bombType = "\x46akeBomb",
    section = section,
    displayName = "\x42omb Jump",
    defaultEnabled = false,
    defaultAutoGet = false,
    defaultBigButton = false,
    defaultBindButton = false,
    bigButtonSize = 90,
    bindButtonSize = 0.11,
    keybind = "\x45",
    bigButtonId = "\x62ombjump_big",
    bindButtonId = "\x62ombjump_bind"
})

if _game == "\x4durder Mystery Modded" then
    local gbjSection = shared.AddSection("\x47old Bomb Jump+")

    local goldBombJumpSystem = CreateBombJumpSystem({
        bombType = "\x47oldBomb",
        section = gbjSection,
        displayName = "\x47old Bomb Jump",
        defaultEnabled = false,
        defaultAutoGet = false,
        defaultBigButton = false,
        defaultBindButton = false,
        bigButtonSize = 200,
        bindButtonSize = 0.11,
        keybind = "\x47",
        bigButtonId = "\x67oldbombjump_big",
        bindButtonId = "\x67oldbombjump_bind"
    })
end

ODHX.Bind("\x41bout", "\x4dute Button SFX", "\x54oggle", function() return muteButtonSounds end)

end

ODHX.cleanup=function()
    RootMaid:DoCleaning()
    for id in pairs(BBSystem.Buttons) do DeleteBigButton(id) end
    for id in pairs(BindableButtons.Buttons) do BindableButtons.DeleteBButton(id) end
end
ODHX.Finish()

        end, function(__error) return tostring(__error) end)
        if not __pluginOk then
            warn("\x5bNoir embedded plugin: BJP.lua.txt] " .. tostring(__pluginError))
            notify("\x42JP.lua.txt failed to load: " .. tostring(__pluginError), 7)
        end
    end
    do
        local __pluginOk, __pluginError = xpcall(function()
local shared = odh_shared_plugins
if not shared or type(shared.CreateTab) ~= "\x66unction" then
    warn("\x5bInventory Unlimiter] Load through the current Overdrive H plugi\x6e menu.")
    return
end

local KEY = "\x4fDH_InventoryUnlimiterRuntime"
local previous = _G[KEY]
if type(previous) == "\x74able" and type(previous.Cleanup) == "\x66unction" then
    local ok, restored = pcall(previous.Cleanup)
    if not ok or restored == false then
        warn("\x5bInventory Unlimiter] Could not restore the previous instance; r\x65load cancelled.")
        return
    end
end

local runtime = { alive=true, initializing=true, values={enabled=false, maxItems=9999}, generation=0 }
local warnings = {}
local function Notify(text, duration)
    if type(shared.Notify) == "\x66unction" then pcall(shared.Notify, text, duration or 3) end
end
local function WarnOnce(key, text)
    if warnings[key] then return end
    warnings[key] = true
    warn("\x5bInventory Unlimiter] " .. text)
    Notify("\x49nventory Unlimiter: " .. text, 5)
end
local function Finite(value)
    return type(value)=="\x6eumber" and value==value and value>-math.huge and value<math.huge
end
local function ClampItems(value)
    if not Finite(value) then return nil end
    return math.clamp(math.floor(value+0.5),2,9999)
end

local environment = {}
if type(getgenv)=="\x66unction" then
    local ok, result=pcall(getgenv)
    if ok and type(result)=="\x74able" then environment=result end
end
local fileRead = type(readfile)=="\x66unction" and readfile or environment.readfile
local fileWrite = type(writefile)=="\x66unction" and writefile or environment.writefile
local fileExists = type(isfile)=="\x66unction" and isfile or environment.isfile
local FILE = "\x4eoir Hub/configs/ODH_InventoryUnlimiter_settings.json"
local httpOK, HttpService = pcall(function() return game:GetService("\x48ttpService") end)
local canPersist = type(fileRead)=="\x66unction" and type(fileWrite)=="\x66unction" and httpOK and HttpService~=nil
runtime.settingsFile=FILE
runtime.saveStatus="\x4eot saved"

local function LoadSettings()
    if not canPersist then
        runtime.saveStatus="\x55navailable"
        WarnOnce("\x66ilesystem","\x72eadfile/writefile unavailable; settings cannot survive a new se\x73sion.")
        return
    end
    if type(fileExists)=="\x66unction" then
        local ok, exists=pcall(fileExists,FILE)
        if ok and not exists then return end
    end
    local ok,text=pcall(fileRead,FILE)
    if not ok then
        if type(fileExists)=="\x66unction" then
            runtime.saveStatus="\x52ead error"
            WarnOnce("\x72ead","\x43annot read settings: " .. tostring(text))
        end
        return
    end
    local decoded,data=pcall(function() return HttpService:JSONDecode(text) end)
    if not decoded or type(data)~="\x74able" or data.version~=1 or type(data.values)~="\x74able" then
        runtime.saveStatus="\x49nvalid file"
        WarnOnce("\x72ead","\x49nvalid settings file. Kept unchanged until you change a setting\x2e")
        return
    end
    if type(data.values.enabled)=="\x62oolean" then runtime.values.enabled=data.values.enabled end
    runtime.values.maxItems=ClampItems(data.values.maxItems) or 9999
    runtime.saveStatus="\x4coaded"
end
local function SaveSettings()
    if not runtime.alive or runtime.initializing or not canPersist then return false end
    local ok,err=pcall(function()
        fileWrite(FILE,HttpService:JSONEncode({version=1,values={
            enabled=runtime.values.enabled,maxItems=runtime.values.maxItems,
        }}))
    end)
    if not ok then
        runtime.saveStatus="\x57rite error"
        WarnOnce("\x77rite","\x43annot save settings: " .. tostring(err))
        return false
    end
    warnings.write=nil
    runtime.saveStatus="\x53aved"
    return true
end
LoadSettings()

local debugLibrary = type(debug)=="\x74able" and debug or {}
local function Resolve(primary, fallback, external)
    if type(primary)=="\x66unction" then return primary end
    if type(fallback)=="\x66unction" then return fallback end
    if type(external)=="\x66unction" then return external end
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
        if ok and type(info)=="\x74able" then name=info.name end
    elseif readName then
        local ok,value=pcall(readName,fn,"\x6e")
        if ok then name=value end
    end
    if name=="\x75pdateItemFrame" or name=="\x6fnItemEquipped" then return true end
    if readConstants then
        local ok,constants=pcall(readConstants,fn)
        if ok and type(constants)=="\x74able" then
            local touch,equip=false,false
            for _,value in pairs(constants) do
                if value=="\x54ouchBinding" then touch=true end
                if value=="\x45quipButton" then equip=true end
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
    if not readable or type(values)~="\x74able" or values[index]~=value then
        return false,"\x75pvalue verification failed"
    end
    return true
end
local function RestoreOriginals()
    local allRestored=true
    for fn,slots in pairs(changed) do
        local readable,values=pcall(readUpvalues,fn)
        if not readable or type(values)~="\x74able" then
            allRestored=false
            WarnOnce("\x72estore-read","\x43ould not inspect previously changed values; restoration is pend\x69ng.")
        else
            for index,saved in pairs(slots) do
                local current=values[index]
                if current==saved.original then
                    slots[index]=nil
                elseif current~=saved.last then
                    WarnOnce("\x63onflict","\x41 value changed elsewhere; left it untouched.")
                    slots[index]=nil
                else
                    local ok,err=WriteAndVerify(fn,index,saved.original)
                    if ok then slots[index]=nil
                    else
                        allRestored=false
                        WarnOnce("\x72estore-write","\x43annot restore an original limit: " .. tostring(err))
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
        Status("\x55NSUPPORTED: required executor debug functions are missing")
        WarnOnce("\x64ebug","\x52equired debug functions are unavailable (getgc/getupvalues/setu\x70value and target identification).")
        return 0
    end
    local ok,objects=pcall(getGC)
    if not ok or type(objects)~="\x74able" then
        Status("\x45RROR: getgc failed")
        WarnOnce("\x73can","\x67etgc failed: " .. tostring(objects))
        return 0
    end
    local target=runtime.values.maxItems
    local count=0
    for _,fn in pairs(objects) do
        if type(fn)=="\x66unction" and (changed[fn] or IsTarget(fn)) then
            local readable,values=pcall(readUpvalues,fn)
            if readable and type(values)=="\x74able" then
                for index,value in pairs(values) do
                    if type(index)=="\x6eumber" and index>=1 and index%1==0 and type(value)=="\x6eumber" then
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
                                else WarnOnce("\x61pply","\x43annot write/verify a target limit: " .. tostring(err)) end
                            else
                                WarnOnce("\x63onflict","\x41 value changed elsewhere; left it untouched.")
                            end
                        end
                    end
                end
            end
        end
    end
    if count>0 then Status("\x4fN | Max Items: " .. target .. "\x20| verified values: " .. count)
    else Status("\x57AITING | Inventory functions not found or not writable") end
    return count
end
local function RequestApply()
    runtime.generation=runtime.generation+1
    local token=runtime.generation
    if not runtime.values.enabled then
        local restored=RestoreOriginals()
        Status(restored and "\x4fFF | Original values restored" or "\x4fFF | Restoration pending; press Reapply / Retry")
        return
    end
    Status("\x41pplying saved/current limit...")
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
if type(previous)=="\x74able" and type(previous.ui)=="\x74able"
    and previous.ui.owner==shared and previous.ui.version==UI_VERSION and previous.ui.complete then
    ui=previous.ui
else
    local ok,result=pcall(function()
        local tab=shared.CreateTab("\x49nventory Unlimiter", "\x2fmellnikovden968-web/CFG_PM2/refs/heads/main/icon")
        return {owner=shared,version=UI_VERSION,tab=tab,
            section=tab:AddSection("\x49nventory Unlimiter V5","\x43lient-side limit • Saved preferences"),visual=false}
    end)
    if not ok then warn("\x5bInventory Unlimiter] UI failed: " .. tostring(result));return end
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
        ui.section:AddParagraph("\x50ersistence", "\x54oggle and Max Items are saved on change. Load this plugin again\x20after joining; saved preferences restore automatically.")
        ui.toggle=ui.section:AddToggle("\x55nlimit Inventory",function(value)
            ui.visual=value==true
            local active=ui.runtime
            if active and active.alive and not active.initializing then active.SetEnabled(value) end
        end)
        assert(type(ui.toggle)=="\x66unction","\x41ddToggle must return a closure")
        ui.slider=ui.section:AddSlider("\x4dax Items",2,9999,runtime.values.maxItems,function(value)
            local active=ui.runtime
            if active and active.alive and not active.initializing then active.SetMaxItems(value) end
        end)
        ui.status=ui.section:AddLabel("\x49nitializing...",true)
        ui.section:AddButton("\x52eapply / Retry",function()
            local active=ui.runtime
            if active and active.alive and not active.initializing then active.Reapply() end
        end)
    end)
    if not ok then runtime.Cleanup();warn("\x5bInventory Unlimiter] UI controls failed: " .. tostring(err));return end
    ui.complete=true
end
statusLabel=ui.status
local synced,err=pcall(function()
    ui.slider:SetValue(runtime.values.maxItems)
    if ui.visual~=runtime.values.enabled then ui.toggle() end
    assert(ui.visual==runtime.values.enabled,"\x74oggle state mismatch")
end)
if not synced then runtime.Cleanup();warn("\x5bInventory Unlimiter] UI sync failed: " .. tostring(err));return end
runtime.initializing=false

local LocalPlayer=game:GetService("\x50layers").LocalPlayer
if LocalPlayer then
    connection=LocalPlayer.CharacterAdded:Connect(function()
        if runtime.alive and runtime.values.enabled then RequestApply() end
    end)
end
RequestApply()
print("\x5bInventory Unlimiter V5] Loaded | Settings: " .. FILE .. "\x20| " .. runtime.saveStatus)

        end, function(__error) return tostring(__error) end)
        if not __pluginOk then
            warn("\x5bNoir embedded plugin: unlimit.lua.txt] " .. tostring(__pluginError))
            notify("\x75nlimit.lua.txt failed to load: " .. tostring(__pluginError), 7)
        end
    end
    do
        local __pluginOk, __pluginError = xpcall(function()
local ODHX = (function()
    local X = { ready=false, silent=false, restoring=false, replay=true, records={}, byKey={}, data={version=1, controls={}}, external=false }
    X.id, X.title, X.file = "\x50m-Wallhop", "\x50m-WallHop", "\x4eoir Hub/configs/ODH_Pm-Wallhop_settings.json"
    local host = odh_shared_plugins
    assert(host and type(host.CreateTab)=="\x66unction", X.title .. "\x3a load through the current Overdrive H plugin menu")
    local env = {}
    if type(getgenv)=="\x66unction" then local ok,g=pcall(getgenv); if ok and type(g)=="\x74able" then env=g end end
    local rd = type(readfile)=="\x66unction" and readfile or env.readfile
    local wr = type(writefile)=="\x66unction" and writefile or env.writefile
    local exists = type(isfile)=="\x66unction" and isfile or env.isfile
    local http = game:GetService("\x48ttpService")
    local reported = {}
    local function report(message)
        if reported[message] then return end
        reported[message]=true
        warn("\x5b" .. X.title .. "\x5d " .. message)
        if type(host.Notify)=="\x66unction" then pcall(host.Notify, X.title .. "\x3a " .. message, 5) end
    end
    X.Report = report
    local function finite(v) return type(v)=="\x6eumber" and v==v and math.abs(v)<math.huge end
    local function encode(v, depth)
        depth=depth or 0
        if depth>20 then error("\x73ettings nesting too deep") end
        if typeof(v)=="\x43olor3" then return {__odhColor={v.R,v.G,v.B}} end
        local t=type(v)
        if t=="\x62oolean" or t=="\x73tring" then return v end
        if t=="\x6eumber" then if finite(v) then return v end; return nil end
        if t=="\x74able" then
            local result={}
            for k,item in pairs(v) do
                if type(k)=="\x73tring" or type(k)=="\x6eumber" then result[k]=encode(item,depth+1) end
            end
            return result
        end
        return nil
    end
    local function decode(v, depth)
        depth=depth or 0
        if depth>20 then error("\x73ettings nesting too deep") end
        if type(v)~="\x74able" then return v end
        if v.__odhColor then
            local c=v.__odhColor
            assert(type(c)=="\x74able" and finite(c[1]) and finite(c[2]) and finite(c[3]),"\x69nvalid color")
            return Color3.new(math.clamp(c[1],0,1),math.clamp(c[2],0,1),math.clamp(c[3],0,1))
        end
        local result={}
        for k,item in pairs(v) do result[k]=decode(item,depth+1) end
        return result
    end
    X.Encode, X.Decode = encode, decode
    if not X.external then
        if type(rd)=="\x66unction" and type(wr)=="\x66unction" then
            local present=true
            if type(exists)=="\x66unction" then local ok,v=pcall(exists,X.file); if ok then present=v end end
            if present then
                local ok,text=pcall(rd,X.file)
                if ok then
                    local good,data=pcall(function() return decode(http:JSONDecode(text)) end)
                    if good and type(data)=="\x74able" and data.version==1 and type(data.controls)=="\x74able" then X.data=data
                    else X.badFile=true; report("\x49nvalid settings file; defaults loaded. A manual change will rep\x6cace it.") end
                elseif type(exists)=="\x66unction" then report("\x43ould not read settings file: " .. tostring(text)); X.badFile=true end
            end
        else report("\x72eadfile/writefile unavailable; settings last only for this sess\x69on.") end
    end
    local tab
    X.shared=setmetatable({}, {__index=host})
    X.shared.Notify=function(text,seconds)
        if X.restoring then return end
        if type(host.Notify)=="\x66unction" then return host.Notify(text,seconds or 3) end
    end
    local function key(section,name,kind) return section .. "\x20/ " .. kind .. "\x20/ " .. name end
    local function safeValue(r,v)
        if r.kind=="\x54oggle" then if type(v)=="\x62oolean" then return v end
        elseif r.kind=="\x53lider" then if finite(v) then return math.clamp(v,r.min,r.max) end
        elseif r.kind=="\x43olorpicker" then if typeof(v)=="\x43olor3" then return v end
        elseif r.kind=="\x44ropdown" then
            for _,item in ipairs(r.items) do if v==item then return v end end
        end
        return nil
    end
    local function show(r,v)
        if v==nil or r.shown==v then return end
        local prior=X.silent; X.silent=true
        local ok,err=pcall(function()
            if r.kind=="\x54oggle" then
                if r.visual~=v then assert(type(r.handle)=="\x66unction","\x41ddToggle must return a closure"); r.handle() end
            elseif r.kind=="\x53lider" then r.handle:SetValue(v)
            elseif r.kind=="\x43olorpicker" then r.handle:SetRGBValue(v)
            elseif r.kind=="\x44ropdown" then r.handle:Select(v) end
        end)
        X.silent=prior
        if ok then r.shown=v else report("\x55I sync failed: " .. r.name .. "\x3a " .. tostring(err)) end
    end
    function X.Bind(section,name,kind,getter)
        local r=X.byKey[key(section,name,kind)]
        assert(r,"\x55nknown binding " .. section .. "\x20/ " .. name)
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
                if not X.backend or not X.backend(X.data) then error("\x6eative settings file could not be saved") end
            elseif type(wr)=="\x66unction" then
                wr(X.file,http:JSONEncode(encode(X.data)))
            end
        end)
        X.committing=false
        if not ok then report("\x53ettings save failed: " .. tostring(err)) end
    end
    function X.Restore()
        X.restoring=true
        for _,togglePass in ipairs({false,true}) do
            for _,r in ipairs(X.records) do
                if not r.exclude and ((r.kind=="\x54oggle")==togglePass) then
                    local v=safeValue(r,X.data.controls[r.key])
                    if v==nil and r.get then local ok,x=pcall(r.get); if ok then v=safeValue(r,x) end end
                    if v==nil then v=r.default end
                    if v~=nil then
                        show(r,v)
                        local ok,err=pcall(r.callback,v)
                        if not ok then report("\x52estore failed: " .. r.name .. "\x3a " .. tostring(err)) end
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
            if r.kind=="\x54oggle" and not r.exclude then X.Set(r.section,r.name,r.kind,false,true) end
        end
    end
    function X.shared.AddSection(name,subtitle)
        if not tab then tab=host.CreateTab(X.title,"\x2fmellnikovden968-web/CFG_PM2/refs/heads/main/icon") end
        local raw=tab:AddSection(name,subtitle or "")
        local section={Name=name,Raw=raw}
        local function register(kind,label,callback,default,min,max,items)
            local r={section=name,name=label,kind=kind,callback=callback,default=default,min=min,max=max,items=items,visual=false}
            r.key=key(name,label,kind)
            r.exclude=(name=="🔑\x20Keys")
            X.records[#X.records+1]=r; X.byKey[r.key]=r
            local function changed(v)
                if kind=="\x54oggle" then r.visual=(v==true) end
                if not X.ready or X.silent or X.restoring or X.stopped then return end
                v=safeValue(r,v); if v==nil then return end
                r.shown=v
                local ok,err=pcall(callback,v)
                if ok then
                    r.value=v
                    if not r.exclude then X.data.controls[r.key]=v end
                    X.Commit()
                else report("\x43allback failed: " .. label .. "\x3a " .. tostring(err)) end
            end
            if kind=="\x54oggle" then r.handle=raw:AddToggle(label,changed)
            elseif kind=="\x53lider" then r.handle=raw:AddSlider(label,min,max,default,changed)
            elseif kind=="\x43olorpicker" then r.handle=raw:AddColorpicker(label,default,changed)
            elseif kind=="\x44ropdown" then r.handle=raw:AddDropdown(label,items,changed) end
            return r.handle
        end
        function section:AddToggle(label,cb) return register("\x54oggle",label,cb,false) end
        function section:AddSlider(label,min,max,default,cb) return register("\x53lider",label,cb,default,min,max) end
        function section:AddColorpicker(label,default,cb) return register("\x43olorpicker",label,cb,default) end
        function section:AddDropdown(label,items,cb) return register("\x44ropdown",label,cb,items[1],nil,nil,items) end
        local function action(cb)
            return function(...)
                if not X.ready or X.stopped then return end
                local ok,err=pcall(cb,...)
                if not ok then report("\x41ction failed: " .. tostring(err)) end
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
        local player=game:GetService("\x50layers").LocalPlayer
        while object and object~=game do
            table.insert(parts,1,object==player and "\x24LocalPlayer" or object.Name)
            object=object.Parent
            if #parts>32 then return nil end
        end
        if object~=game then return nil end
        return parts
    end
    function X.Resolve(parts)
        if type(parts)~="\x74able" then return nil end
        local object=game
        for _,name in ipairs(parts) do
            if name=="\x24LocalPlayer" then object=game:GetService("\x50layers").LocalPlayer
            elseif type(name)=="\x73tring" and object then object=object:FindFirstChild(name)
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
    local registry=rawget(_G,"\x4fDH_2026_PluginRuntimes")
    if type(registry)~="\x74able" then registry={}; rawset(_G,"\x4fDH_2026_PluginRuntimes",registry) end
    local previous=registry[X.id]
    if previous and type(previous.Stop)=="\x66unction" then pcall(previous.Stop) end
    registry[X.id]=X
    return X
end)()

local shared = ODHX.shared
local UpdateWallhopButtonState, performVideoFlick, performWallhop

local wallhop_section = shared.AddSection("\x50m-WallHop")

wallhop_section:AddLabel("\x50m-WallHop Script by @Phemtom (Improved)")
wallhop_section:AddParagraph("\x50m-WallHop", "Флинг\x20при прыжке возле стыка стен")

local isWallHopEnabled = false
wallhop_section:AddToggle("Включить\x20WallHop", function(bool)
    isWallHopEnabled = bool
    if bool then
        shared.Notify("\x50m-WallHop включен", 2)
    else
        shared.Notify("\x50m-WallHop выключен", 2)
    end
    UpdateWallhopButtonState()
end)

wallhop_section:AddButton("Вкл\x2fВыкл WallHop", function()
    isWallHopEnabled = not isWallHopEnabled
    shared.Notify(isWallHopEnabled and "\x50m-WallHop включен" or "\x50m-WallHop выключен", 2)
    UpdateWallhopButtonState()
end)

local detectionDistance = 3
wallhop_section:AddSlider("Дистанция\x20обнаружения", 1, 6, 3, function(int)
    detectionDistance = int
    shared.Notify("Дистанция\x3a " .. int, 2)
end)

local flickPower = 50
wallhop_section:AddSlider("Сила\x20флинга", 20, 100, 50, function(int)
    flickPower = int
    shared.Notify("Сила\x3a " .. int, 2)
end)

wallhop_section:AddKeybind("\x54oggle Keybind", "\x46", function()
    isWallHopEnabled = not isWallHopEnabled
    shared.Notify(isWallHopEnabled and "\x50m-WallHop включен" or "\x50m-WallHop выключен", 2)
    UpdateWallhopButtonState()
end)

wallhop_section:AddKeybind("\x57allHop Jump Key", "\x4a", function()
    if isWallHopEnabled then
        performWallhop()
    else
        shared.Notify("\x57allHop выключен! Нажмите F или кнопку в меню", 2)
    end
end)

local WallhopBindableButtons = {Buttons = {}, Maids = {}, Count = 0}

local __SHAPES = {
    [0] = "\x72bxassetid://86221076925479",
    [1] = "\x72bxassetid://96242665417546",
    [2] = "\x72bxassetid://97129189935336",
    [3] = "\x72bxassetid://76165862027868",
    [4] = "\x72bxassetid://125868092127496"
}

local __NORMAL_COLOR = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.new(0.133333, 0.827451, 0.494118)),
    ColorSequenceKeypoint.new(0.6, Color3.new(0.231373, 0.509804, 0.498039)),
    ColorSequenceKeypoint.new(1, Color3.new(0.501961, 0.501961, 0.501961))
})

local __ACTIVE_COLOR = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.new(0.0, 0.8, 0.4)),
    ColorSequenceKeypoint.new(0.6, Color3.new(0.0, 0.5, 0.3)),
    ColorSequenceKeypoint.new(1, Color3.new(0.2, 0.8, 0.6))
})

local function safecallback(callback)
    if not callback then return end
    local ok, err = xpcall(callback, function(e) return debug.traceback(e) end)
    if not ok then warn("\x5bBIND ERROR] " .. tostring(err)) end
end

local function GetStorage()
    local parent = gethui and gethui()
    if not parent or typeof(parent) ~= "\x49nstance" then parent = game:GetService("\x43oreGui") end
    if not parent or typeof(parent) ~= "\x49nstance" then
        parent = game.Players.LocalPlayer:WaitForChild("\x50layerGui", 5)
    end
    if typeof(parent) ~= "\x49nstance" then
        parent = game.Players.LocalPlayer:WaitForChild("\x50layerGui")
    end
    local sg = parent:FindFirstChild("\x40wallhopstorage")
    if not sg then
        sg = Instance.new("\x53creenGui")
        sg.Name = "\x40wallhopstorage"
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

            game:GetService("\x54weenService"):Create(ripple, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 45, 0, 45),
                BackgroundTransparency = 1
            }):Play()

            local releaseConn
            releaseConn = ODHX.Connect(game:GetService("\x55serInputService").InputEnded, function(endInput)
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

    maid:GiveTask(ODHX.Connect(game:GetService("\x55serInputService").InputChanged, function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then hasMoved = true end
            local screen = gui.Parent.AbsoluteSize
            gui.Position = UDim2.new(startPos.X.Scale + (delta.X / screen.X), 0, startPos.Y.Scale + (delta.Y / screen.Y), 0)
        end
    end))
end

function WallhopBindableButtons.AddBButton(id, text, onFunc, offFunc)
    if WallhopBindableButtons.Buttons[id] then return WallhopBindableButtons.Buttons[id]:FindFirstChild("\x42indValue") end

    local buttonMaid = {}
    function buttonMaid:GiveTask(task)
        table.insert(buttonMaid._tasks or {}, task)
        return task
    end
    function buttonMaid:Destroy()
        if buttonMaid._tasks then
            for _, t in pairs(buttonMaid._tasks) do
                if typeof(t) == "\x52BXScriptConnection" then t:Disconnect()
                elseif typeof(t) == "\x49nstance" then t:Destroy()
                elseif type(t) == "\x66unction" then t()
                end
            end
        end
    end
    buttonMaid._tasks = {}

    local screen = workspace.CurrentCamera.ViewportSize
    local buttonSizeY = 0.11
    local widthScale = buttonSizeY * (screen.Y / screen.X)

    local xPos = 0.1 + ((WallhopBindableButtons.Count % 8) * (widthScale + 0.005))
    local yPos = 0.7 - (math.floor(WallhopBindableButtons.Count / 8) * (buttonSizeY + 0.015))

    local ImageButton = Instance.new("\x49mageButton")
    ImageButton.Name = id
    ImageButton.Size = UDim2.new(widthScale, 0, buttonSizeY, 0)
    ImageButton.Position = UDim2.new(xPos, 0, yPos, 0)
    ImageButton.AnchorPoint = Vector2.new(0.5, 0.5)
    ImageButton.Image = ""
    ImageButton.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
    ImageButton.BackgroundTransparency = 0.28
    ImageButton.BorderSizePixel = 0
    ImageButton.ClipsDescendants = false
    ImageButton.AutoButtonColor = false
    Instance.new("\x55ICorner", ImageButton).CornerRadius = UDim.new(0, 1000)
    local outerButtonStroke = Instance.new("\x55IStroke", ImageButton)
    outerButtonStroke.Color = Color3.new(1, 1, 1)
    outerButtonStroke.Thickness = 2
    outerButtonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    local innerButtonStroke = Instance.new("\x55IStroke", ImageButton)
    innerButtonStroke.Color = Color3.fromRGB(105, 105, 112)
    innerButtonStroke.Transparency = 0.5
    innerButtonStroke.Thickness = 1
    innerButtonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    ImageButton.Parent = GetStorage()
    buttonMaid:GiveTask(ImageButton)

    local BindValue = Instance.new("\x42oolValue", ImageButton)
    BindValue.Name = "\x42indValue"

    local TextLabel = Instance.new("\x54extLabel", ImageButton)
    TextLabel.Name = "\x40Text"
    TextLabel.Size = UDim2.new(0.8, 0, 0.8, 0)
    TextLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
    TextLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Font = Enum.Font.GothamBold
    TextLabel.Text = text
    TextLabel.TextColor3 = Color3.new(1, 1, 1)
    TextLabel.TextSize = 14
    TextLabel.TextWrapped = true
    TextLabel.ZIndex = 3

    local Aspect = Instance.new("\x55IAspectRatioConstraint", ImageButton)
    Aspect.AspectRatio = 1
    Aspect.AspectType = Enum.AspectType.ScaleWithParentSize

    local Gradient = Instance.new("\x55IGradient", outerButtonStroke)
    Gradient.Name = "\x40Stroke"
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

    local ripple = Instance.new("\x46rame")
    ripple.Name = "\x40ripple"
    ripple.BackgroundColor3 = Color3.fromRGB(0, 155, 255)
    ripple.BackgroundTransparency = 0.5
    ripple.Size = UDim2.new(0, 0, 0, 0)
    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
    ripple.Visible = false
    ripple.ZIndex = 2
    ripple.Parent = ImageButton
    Instance.new("\x55ICorner", ripple).CornerRadius = UDim.new(1, 0)

    local sound = Instance.new("\x53ound")
    sound.SoundId = "\x72bxassetid://3868133279"
    sound.Volume = 0.5
    sound.Parent = ImageButton

    local debounce = false
    local tInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

    local function onClick()
        if debounce then return end
        debounce = true
        local fOut = game:GetService("\x54weenService"):Create(ImageButton, tInfo, {ImageTransparency = 1})
        fOut:Play()
        fOut.Completed:Wait()

        BindValue.Value = not BindValue.Value
        Gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 40)),
            ColorSequenceKeypoint.new(0.22, Color3.fromRGB(250, 250, 252)),
            ColorSequenceKeypoint.new(0.48, Color3.fromRGB(70, 70, 78)),
            ColorSequenceKeypoint.new(0.72, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(45, 45, 52)),
        })
        if BindValue.Value then safecallback(onFunc) else safecallback(offFunc) end

        local fIn = game:GetService("\x54weenService"):Create(ImageButton, tInfo, {ImageTransparency = 0})
        fIn:Play()
        fIn.Completed:Wait()
        debounce = false
    end

    MakeDraggable(ImageButton, buttonMaid, ripple, sound, onClick)
    table.insert(gradientStrokes.fast, Gradient)

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
    local btn = WallhopBindableButtons.Buttons["\x77allhop_toggle"]
    if not btn then return end
    local value=btn:FindFirstChild("\x42indValue")
    if value then value.Value=isWallHopEnabled end
    local textLabel = btn:FindFirstChild("\x40Text")
    if textLabel then
        textLabel.Text = isWallHopEnabled and "\x4fN" or "\x4fFF"
    end
    local gradient = btn:FindFirstChild("\x40Stroke")
    if gradient then
        gradient.Color = isWallHopEnabled and __ACTIVE_COLOR or __NORMAL_COLOR
    end
end

local Players = game:GetService("\x50layers")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("\x52unService")
local UserInputService = game:GetService("\x55serInputService")

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
        if current:IsA("\x4dodel") and current:FindFirstChildOfClass("\x48umanoid") then
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

    if instance:IsA("\x50art") and instance.Parent and instance.Parent:IsA("\x4dodel") and instance.Parent:FindFirstChild("\x48umanoid") then
        return false
    end

    local current = instance
    while current do
        if isPlayerCharacter(current) then
            return false
        end
        current = current.Parent
    end

    if not instance:IsA("\x42asePart") and not instance:IsA("\x54errain") then
        return false
    end

    if instance:IsA("\x42asePart") and not instance.CanCollide then
        return false
    end

    return true
end

local function getWallRaycastResult()
    local character = LocalPlayer.Character
    if not character then return nil end
    local hrp = character:FindFirstChild("\x48umanoidRootPart")
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

    local hum = char:FindFirstChild("\x48umanoid")
    local hrp = char:FindFirstChild("\x48umanoidRootPart")
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
    local humanoid = character and character:FindFirstChildOfClass("\x48umanoid")
    local rootPart = character and character:FindFirstChild("\x48umanoidRootPart")
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

    local hrp = char:FindFirstChild("\x48umanoidRootPart")
    local hum = char:FindFirstChild("\x48umanoid")
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

ODHX.Bind("\x50m-WallHop", "Включить\x20WallHop", "\x54oggle", function() return isWallHopEnabled end)
ODHX.Bind("\x50m-WallHop", "Дистанция\x20обнаружения", "\x53lider", function() return detectionDistance end)
ODHX.Bind("\x50m-WallHop", "Сила\x20флинга", "\x53lider", function() return flickPower end)
ODHX.cleanup=function()
    for id in pairs(WallhopBindableButtons.Buttons) do WallhopBindableButtons.DeleteBButton(id) end
end
ODHX.Finish()

        end, function(__error) return tostring(__error) end)
        if not __pluginOk then
            warn("\x5bNoir embedded plugin: Pm-Wallhop.lua.txt] " .. tostring(__pluginError))
            notify("\x50m-Wallhop.lua.txt failed to load: " .. tostring(__pluginError), 7)
        end
    end
end


 
do
    local __pluginOk, __pluginError = xpcall(function()
 
local noirHost = host
assert(noirHost and type(noirHost.CreateTab) == "\x66unction", "\x55ltimate Fling: Noir host unavailable")
 
local ODHX = (function()
    local X = { ready=false, silent=false, restoring=false, replay=true, records={}, byKey={}, data={version=1, controls={}}, external=true }
    X.id, X.title, X.file = "\x46LING", "\x55LTIMATE FLING", "\x4eoir Hub/configs/ODH_FLING_settings.json"
    local host = {
        CreateTab = function()
            return noirHost.CreateTab()
        end,
        Notify = function(textValue, duration)
            return notify(tostring(textValue), duration or 3)
        end,
    }
    local env = {}
    if type(getgenv)=="\x66unction" then local ok,g=pcall(getgenv); if ok and type(g)=="\x74able" then env=g end end
    local rd = type(readfile)=="\x66unction" and readfile or env.readfile
    local wr = type(writefile)=="\x66unction" and writefile or env.writefile
    local exists = type(isfile)=="\x66unction" and isfile or env.isfile
    local http = game:GetService("\x48ttpService")
    local reported = {}
    local function report(message)
        if reported[message] then return end
        reported[message]=true
        warn("\x5b" .. X.title .. "\x5d " .. message)
        if type(host.Notify)=="\x66unction" then pcall(host.Notify, X.title .. "\x3a " .. message, 5) end
    end
    X.Report = report
    local function finite(v) return type(v)=="\x6eumber" and v==v and math.abs(v)<math.huge end
    local function encode(v, depth)
        depth=depth or 0
        if depth>20 then error("\x73ettings nesting too deep") end
        if typeof(v)=="\x43olor3" then return {__odhColor={v.R,v.G,v.B}} end
        local t=type(v)
        if t=="\x62oolean" or t=="\x73tring" then return v end
        if t=="\x6eumber" then if finite(v) then return v end; return nil end
        if t=="\x74able" then
            local result={}
            for k,item in pairs(v) do
                if type(k)=="\x73tring" or type(k)=="\x6eumber" then result[k]=encode(item,depth+1) end
            end
            return result
        end
        return nil  
    end
    local function decode(v, depth)
        depth=depth or 0
        if depth>20 then error("\x73ettings nesting too deep") end
        if type(v)~="\x74able" then return v end
        if v.__odhColor then
            local c=v.__odhColor
            assert(type(c)=="\x74able" and finite(c[1]) and finite(c[2]) and finite(c[3]),"\x69nvalid color")
            return Color3.new(math.clamp(c[1],0,1),math.clamp(c[2],0,1),math.clamp(c[3],0,1))
        end
        local result={}
        for k,item in pairs(v) do result[k]=decode(item,depth+1) end
        return result
    end
    X.Encode, X.Decode = encode, decode
    if not X.external then
        if type(rd)=="\x66unction" and type(wr)=="\x66unction" then
            local present=true
            if type(exists)=="\x66unction" then local ok,v=pcall(exists,X.file); if ok then present=v end end
            if present then
                local ok,text=pcall(rd,X.file)
                if ok then
                    local good,data=pcall(function() return decode(http:JSONDecode(text)) end)
                    if good and type(data)=="\x74able" and data.version==1 and type(data.controls)=="\x74able" then X.data=data
                    else X.badFile=true; report("\x49nvalid settings file; defaults loaded. A manual change will rep\x6cace it.") end
                elseif type(exists)=="\x66unction" then report("\x43ould not read settings file: " .. tostring(text)); X.badFile=true end
            end
        else report("\x72eadfile/writefile unavailable; settings last only for this sess\x69on.") end
    end
    local tab
    X.shared=setmetatable({}, {__index=host})  
    X.shared.Notify=function(text,seconds)
        if X.restoring then return end
        if type(host.Notify)=="\x66unction" then return host.Notify(text,seconds or 3) end
    end
    local function key(section,name,kind) return section .. "\x20/ " .. kind .. "\x20/ " .. name end
    local function safeValue(r,v)
        if r.kind=="\x54oggle" then if type(v)=="\x62oolean" then return v end
        elseif r.kind=="\x53lider" then if finite(v) then return math.clamp(v,r.min,r.max) end
        elseif r.kind=="\x43olorpicker" then if typeof(v)=="\x43olor3" then return v end
        elseif r.kind=="\x44ropdown" then
            for _,item in ipairs(r.items) do if v==item then return v end end
        end
        return nil
    end
    local function show(r,v)
        if v==nil or r.shown==v then return end
        local prior=X.silent; X.silent=true
        local ok,err=pcall(function()
            if r.kind=="\x54oggle" then
                if r.visual~=v then assert(type(r.handle)=="\x66unction","\x41ddToggle must return a closure"); r.handle() end
            elseif r.kind=="\x53lider" then r.handle:SetValue(v)
            elseif r.kind=="\x43olorpicker" then r.handle:SetRGBValue(v)
            elseif r.kind=="\x44ropdown" then r.handle:Select(v) end
        end)
        X.silent=prior
        if ok then r.shown=v else report("\x55I sync failed: " .. r.name .. "\x3a " .. tostring(err)) end
    end
    function X.Bind(section,name,kind,getter)
        local r=X.byKey[key(section,name,kind)]
        assert(r,"\x55nknown binding " .. section .. "\x20/ " .. name)
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
                if not X.backend or not X.backend(X.data) then error("\x6eative settings file could not be saved") end
            elseif type(wr)=="\x66unction" then
                wr(X.file,http:JSONEncode(encode(X.data)))
            end
        end)
        X.committing=false
        if not ok then report("\x53ettings save failed: " .. tostring(err)) end
    end
    function X.Restore()
        X.restoring=true
         
        for _,togglePass in ipairs({false,true}) do
            for _,r in ipairs(X.records) do
                if not r.exclude and ((r.kind=="\x54oggle")==togglePass) then
                    local v=safeValue(r,X.data.controls[r.key])
                    if v==nil and r.get then local ok,x=pcall(r.get); if ok then v=safeValue(r,x) end end
                    if v==nil then v=r.default end
                    if v~=nil then
                        show(r,v)
                        local ok,err=pcall(r.callback,v)
                        if not ok then report("\x52estore failed: " .. r.name .. "\x3a " .. tostring(err)) end
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
            if r.kind=="\x54oggle" and not r.exclude then X.Set(r.section,r.name,r.kind,false,true) end
        end
    end
    function X.shared.AddSection(name,subtitle)
        if not tab then tab=host.CreateTab() end
         
        local raw=tab:AddSection("\x57ORLD • " .. name,subtitle or "")
        local section={Name=name,Raw=raw}
        local function register(kind,label,callback,default,min,max,items)
            local r={section=name,name=label,kind=kind,callback=callback,default=default,min=min,max=max,items=items,visual=false}
            r.key=key(name,label,kind)
            r.exclude=(name=="🔑\x20Keys")  
            X.records[#X.records+1]=r; X.byKey[r.key]=r
            local function changed(v)
                if kind=="\x54oggle" then r.visual=(v==true) end
                if not X.ready or X.silent or X.restoring or X.stopped then return end
                v=safeValue(r,v); if v==nil then return end
                r.shown=v
                local ok,err=pcall(callback,v)
                if ok then
                    r.value=v
                    if not r.exclude then X.data.controls[r.key]=v end
                    X.Commit()
                else report("\x43allback failed: " .. label .. "\x3a " .. tostring(err)) end
            end
            if kind=="\x54oggle" then r.handle=raw:AddToggle(label,changed)
            elseif kind=="\x53lider" then r.handle=raw:AddSlider(label,min,max,default,changed)
            elseif kind=="\x43olorpicker" then r.handle=raw:AddColorpicker(label,default,changed)
            elseif kind=="\x44ropdown" then r.handle=raw:AddDropdown(label,items,changed) end
            return r.handle
        end
        function section:AddToggle(label,cb) return register("\x54oggle",label,cb,false) end
        function section:AddSlider(label,min,max,default,cb) return register("\x53lider",label,cb,default,min,max) end
        function section:AddColorpicker(label,default,cb) return register("\x43olorpicker",label,cb,default) end
        function section:AddDropdown(label,items,cb) return register("\x44ropdown",label,cb,items[1],nil,nil,items) end
        local function action(cb)
            return function(...)
                if not X.ready or X.stopped then return end
                local ok,err=pcall(cb,...)
                if not ok then report("\x41ction failed: " .. tostring(err)) end
                X.Commit()
            end
        end
        function section:AddButton(label,cb) return raw:AddButton(label,action(cb)) end
        function section:AddKeybind(label,default,cb) return raw:AddKeybind(label,default,action(cb)) end
        function section:AddPlayerDropdown(label,cb)
             
            local playerService = game:GetService("\x50layers")
            local names, lookup = { "\x4eone" }, {}
            for _, player in ipairs(playerService:GetPlayers()) do
                if player ~= playerService.LocalPlayer then
                    names[#names + 1] = player.Name
                    lookup[player.Name] = player
                end
            end
            table.sort(names, function(a, b)
                if a == "\x4eone" then return true end
                if b == "\x4eone" then return false end
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
        local player=game:GetService("\x50layers").LocalPlayer
        while object and object~=game do
            table.insert(parts,1,object==player and "\x24LocalPlayer" or object.Name)
            object=object.Parent
            if #parts>32 then return nil end
        end
        if object~=game then return nil end
        return parts
    end
    function X.Resolve(parts)
        if type(parts)~="\x74able" then return nil end
        local object=game
        for _,name in ipairs(parts) do
            if name=="\x24LocalPlayer" then object=game:GetService("\x50layers").LocalPlayer
            elseif type(name)=="\x73tring" and object then object=object:FindFirstChild(name)
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
    local registry=rawget(_G,"\x4fDH_2026_PluginRuntimes")
    if type(registry)~="\x74able" then registry={}; rawset(_G,"\x4fDH_2026_PluginRuntimes",registry) end
    local previous=registry[X.id]
    if previous and type(previous.Stop)=="\x66unction" then pcall(previous.Stop) end
    registry[X.id]=X
    return X
end)()
 


























 
local AUTHOR            = "\x4b1LAS1K"
local BRAND             = "\x55LTIMATE FLING"
local PLUGIN_ID         = "\x66ling"
local PLUGIN_NAME       = BRAND .. "\x20• FLING"
local VERSION           = "\x561.2"
local VERSION_TAG       = "\x66ling"
local MARKER_PREFIX     = "\x40fling_"
local CONFIG_PATH       = CONFIGS_FOLDER .. "\x2fODH_FLING_settings.json"
local STORAGE_NAME      = "\x40" .. PLUGIN_ID
local UNLOAD_GLOBAL     = "\x5f_FLING_UNLOAD"
local LEGACY_STORAGES   = { "\x40bindstorage_v6", "\x40bindstorage_v5", "\x40flingstorage_v1" }
local CLEAN_LEGACY_MENU = true

 
local StarterGui = nil

local function hostNotify(text, dur)
    if type(notify) == "\x66unction" then
        local ok = pcall(notify, tostring(text), dur or 3)
        if ok then return end
    end
    pcall(function()
        local sg = StarterGui or game:GetService("\x53tarterGui")
        sg:SetCore("\x53endNotification", {
            Title = BRAND, Text = tostring(text), Duration = dur or 3,
        })
    end)
end

local shared = ODHX.shared
if not shared then
    hostNotify(BRAND .. "\x20" .. VERSION .. "\x3a Load through Overdrive H plugin menu", 3)
    return
end

 
pcall(function()
    if type(getgenv) ~= "\x66unction" then return end
    local g = getgenv()
    if type(g) ~= "\x74able" then return end
    local prev = rawget(g, UNLOAD_GLOBAL)
    rawset(g, UNLOAD_GLOBAL, nil)
    if type(prev) == "\x66unction" then pcall(prev) end
end)

 
local Maid = {}
Maid.__index = Maid

function Maid._cleanup(item)
    local t = typeof(item)
    if t == "\x52BXScriptConnection" then
        pcall(function() item:Disconnect() end)
    elseif t == "\x49nstance" then
        pcall(function() item:Destroy() end)
    elseif t == "\x66unction" then
        local ok, err = pcall(item)
        if not ok then warn("\x5b" .. BRAND .. "\x5d[maid] " .. tostring(err)) end
    elseif t == "\x74hread" then
        pcall(task.cancel, item)
    elseif t == "\x74able" and type(item.Destroy) == "\x66unction" then
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

 
local ReplicatedStorage = game:GetService("\x52eplicatedStorage")
local Players           = game:GetService("\x50layers")
local LocalPlayer       = Players.LocalPlayer
local UserInputService  = game:GetService("\x55serInputService")
local RunService        = game:GetService("\x52unService")
local Workspace         = game:GetService("\x57orkspace")
local TweenService      = game:GetService("\x54weenService")
local HttpService       = game:GetService("\x48ttpService")
local CoreGui           = game:GetService("\x43oreGui")
StarterGui              = game:GetService("\x53tarterGui")

 
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
    flingMethod       = "\x41uto",  
    predictionStuds   = 8,
    startStuds        = 5,
    autoReturn        = true,
    loopInterval      = 0.4,
    auraInterval      = 0.4,
    auraStuds         = 15,
    bindButtonSize    = 0.11,
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
    if type(value) == "\x74able" then
        local copy = {}
        for kk, vv in pairs(value) do copy[kk] = vv end
        config[key] = copy
    else
        config[key] = value
    end
end

local canPersist = (type(writefile) == "\x66unction" and type(readfile) == "\x66unction")
local jsonBroken = false

local function jsonEncode(tbl)
    if jsonBroken then return nil end
    local ok, res = pcall(function() return HttpService:JSONEncode(tbl) end)
    if ok and type(res) == "\x73tring" then return res end
    jsonBroken = true
    return nil
end

local function jsonDecode(str)
    if jsonBroken then return nil end
    local ok, res = pcall(function() return HttpService:JSONDecode(str) end)
    if ok and type(res) == "\x74able" then return res end
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
    if type(list) == "\x74able" then
        for _, row in ipairs(list) do
            if type(row) == "\x74able" and type(row.id) == "\x6eumber" then
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
    if type(data) ~= "\x74able" then return false end
    local scalars = {
        "\x66lingDuration", "\x66lingPower", "\x66lingMethod", "\x70redictionStuds", "\x73tartStuds", "\x61utoReturn",
        "\x6coopInterval", "\x61uraInterval", "\x61uraStuds",
        "\x62indButtonSize", "\x74argetCooldown",
        "\x61utoSheriffDelay", "\x61utoMurdererDelay", "\x72oleCacheTTL",
        "\x6duteSounds", "\x6eotifications",
    }
    for _, key in ipairs(scalars) do
        local v = data[key]
        if v ~= nil and type(v) == type(DEFAULTS[key]) then config[key] = v end
    end
     
    if type(config.flingDuration)=="\x6eumber" then config.flingDuration=math.clamp(math.floor(config.flingDuration+0.5),1,5) end
    if type(config.flingPower)=="\x6eumber" then config.flingPower=math.clamp(math.floor(config.flingPower+0.5),1,3) end
    if type(config.predictionStuds)=="\x6eumber" then config.predictionStuds=math.clamp(config.predictionStuds,0,20) end
    if type(config.startStuds)=="\x6eumber" then config.startStuds=math.clamp(config.startStuds,-5,20) end
    local METHODS = { Auto=true, Fling=true, Sweep=true }
    if type(config.flingMethod)~="\x73tring" or not METHODS[config.flingMethod] then config.flingMethod="\x41uto" end
    if type(data.keybinds) == "\x74able" then config.keybinds = data.keybinds end
    if type(data.bindPositions) == "\x74able" then config.bindPositions = data.bindPositions end
    if type(data.hudPos) == "\x74able" and type(data.hudPos.x) == "\x6eumber" and type(data.hudPos.y) == "\x6eumber" then
        config.hudPos = { x = data.hudPos.x, y = data.hudPos.y }
    end
    if type(data.pluginUI)=="\x74able" then config.pluginUI=data.pluginUI end
    loadedWhitelist = unpackWhitelist(data.whitelist)
    return true
end

local function loadConfig()
    if not canPersist or type(isfile) ~= "\x66unction" then return false end
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
            assert(payload,"\x4aSON encode failed")
            writefile(CONFIG_PATH,payload)
        end)
        if not ok then ODHX.Report("\x43ould not save " .. CONFIG_PATH .. "\x3a " .. tostring(err)) end
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
    local text = msg and (title .. "\x3a " .. msg) or title
    local t = now()
    if lastNotify.text == text and (t - lastNotify.at) < 0.35 then return end
    lastNotify.text, lastNotify.at = text, t
    hostNotify(text, dur or 3)
end

 
local Ticker = { _fns = {}, _conn = nil, _acc = 0 }

function Ticker._start()
    if Ticker._conn then return end
    Ticker._conn = RunService.RenderStepped:Connect(function(dt)
        Ticker._acc += dt
        if Ticker._acc < (1 / 30) then return end
        local stepDt = Ticker._acc
        Ticker._acc = 0
        local fns = Ticker._fns
        local i = 1
        while i <= #fns do
            local fn = fns[i]
            if fn then
                local ok, err = xpcall(fn, debug.traceback, stepDt)
                if not ok then
                    warn("\x5b" .. BRAND .. "\x5d[ticker] " .. tostring(err))
                    table.remove(fns, i)
                    i = i - 1
                end
            end
            i = i + 1
        end
        if #fns == 0 and Ticker._conn then
            Ticker._conn:Disconnect()
            Ticker._conn = nil
            Ticker._acc = 0
        end
    end)
end

function Ticker.add(fn)
    if type(fn) ~= "\x66unction" then return function() end end
    local fns = Ticker._fns
    fns[#fns + 1] = fn
    Ticker._start()
    local removed = false
    return function()
        if removed then return end
        removed = true
        for i = 1, #fns do
            if fns[i] == fn then
                table.remove(fns, i)
                break
            end
        end
    end
end

RootMaid:GiveTask(function()
    if Ticker._conn then Ticker._conn:Disconnect(); Ticker._conn = nil end
    Ticker._acc = 0
    clearTable(Ticker._fns)
end)

 
local LEGACY_TITLES = {
    ["⚡\x20Quick Actions"] = true,
    ["🤖\x20Automation"] = true,
    ["📋\x20Lists Management"] = true,
    ["⚙️\x20Reset Settings"] = true,
    ["⚙\x20Reset Settings"] = true,
    ["🔄\x20Bind Buttons (circles)"] = true,
    ["📊\x20Status"] = true,
    ["ℹ️\x20Info"] = true,
    ["⚡\x20Reset"] = true,
    ["🤖\x20Auto"] = true,
    ["📋\x20Lists"] = true,
    ["⚙️\x20Tuning"] = true,
    ["⚙\x20Tuning"] = true,
    ["🔘\x20Binds"] = true,
    ["ℹ️"] = true,
    ["\x55ltimate Fling V1"] = true,
    ["\x55ltimate Fling"] = true,
}
local EXTRA_LEGACY_TITLES = {}
for _title in pairs(EXTRA_LEGACY_TITLES) do LEGACY_TITLES[_title] = true end
local CUR_TITLES = {
    ["💀\x20" .. BRAND] = true,
    ["⚡\x20Fling"] = true,
    ["🤖\x20Auto"] = true,
    ["📋\x20Lists"] = true,
    ["⚙️\x20Tuning"] = true,
    ["⚙\x20Tuning"] = true,
    ["🔘\x20Binds"] = true,
    ["🔑\x20Keys"] = true,
    ["💾\x20Config"] = true,
    ["ℹ️"] = true,
}
local HOST_WORDS = {
    "\x4cooking for a feature", "\x50lugins", "\x4fverdrive", "\x4cogged in as", "\x67g/overdrivehub",
}
local MAX_CARD_HEIGHT = 520

local RUN_ID = MARKER_PREFIX .. tostring(floor(now() * 1000) % 100000000)
    .. "\x5f" .. tostring(math.random(1000, 9999))

 
local storageGui = nil
local function getStorage()
    if storageGui and storageGui.Parent then return storageGui end

    local parent
    local ok, res = pcall(function()
        if gethui then return gethui() end
        if getcore then return getcore() end
        return nil
    end)
    if ok and typeof(res) == "\x49nstance" then parent = res else parent = CoreGui end
    if typeof(parent) ~= "\x49nstance" then parent = LocalPlayer:FindFirstChildOfClass("\x50layerGui") end
    if typeof(parent) ~= "\x49nstance" then parent = LocalPlayer:WaitForChild("\x50layerGui", 5) end
    if typeof(parent) ~= "\x49nstance" then parent = CoreGui end

    pcall(function()
        for _, legacyName in ipairs(LEGACY_STORAGES) do
            local legacy = parent:FindFirstChild(legacyName)
            if legacy then legacy:Destroy() end
        end
    end)

    local sg = parent:FindFirstChild(STORAGE_NAME)
    if not sg then
        sg = new("\x53creenGui")
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
    if typeof(sec) ~= "\x74able" then return stubSection() end
    local proxy = { _raw = sec }
    return setmetatable(proxy, {
        __index = function(p, key)
            local raw = p._raw
            local value = raw[key]
            if type(value) == "\x66unction" then
                return function(first, ...)
                    local ok, err
                    if first == p then
                        ok, err = pcall(value, raw, ...)
                    else
                        ok, err = pcall(value, raw, first, ...)
                    end
                    if not ok then warn("\x5b" .. BRAND .. "\x5d[menu] " .. tostring(key) .. "\x3a " .. tostring(err)) end
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
        if typeof(r) == "\x49nstance" and not seen[r] then
            seen[r] = true
            roots[#roots + 1] = r
        end
    end
    pcall(function() add(gethui and gethui()) end)
    pcall(function() add(getcore and getcore()) end)
    add(CoreGui)
    pcall(function() add(LocalPlayer:FindFirstChildOfClass("\x50layerGui")) end)
    return roots
end

local function hasHostWords(node, memo)
    local cached = memo[node]
    if cached ~= nil then return cached end
    local res = false
    local descendants = node:GetDescendants()
    for i = 1, #descendants do
        local d = descendants[i]
        if d:IsA("\x54extLabel") then
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
        if not node or typeof(node) ~= "\x49nstance" or node == game then return nil end
        if node:IsA("\x46rame") or node:IsA("\x53crollingFrame") then
            local framed = node:FindFirstChildOfClass("\x55IStroke") or node:FindFirstChildOfClass("\x55ICorner")
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
        local sv = new("\x53tringValue")
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
        if d:IsA("\x54extLabel") and d.Text:find(VERSION_TAG, 1, true) then return true end
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
            if d.Parent and d:IsA("\x54extLabel") then
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
            if d.Parent and d:IsA("\x54extLabel") and CUR_TITLES[d.Text] then
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
            if d.Parent and d:IsA("\x54extLabel") and CUR_TITLES[d.Text] then
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
    local s = new("\x53ound")
    s.Name = "\x40click"
    s.SoundId = "\x72bxassetid://3868133279"
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
    CurrentSize = config.bindButtonSize or 0.11,
}

local __SHAPES = {
    [0] = "\x72bxassetid://86221076925479",
    [1] = "\x72bxassetid://96242665417546",
    [2] = "\x72bxassetid://97129189935336",
    [3] = "\x72bxassetid://76165862027868",
    [4] = "\x72bxassetid://125868092127496",
}
local GLOW_IMG = "\x72bxassetid://131961136"

local __NORMAL_COLOR = cs({
    csk(0,    rgb(35, 35, 40)),
    csk(0.22, rgb(250, 250, 252)),
    csk(0.48, rgb(70, 70, 78)),
    csk(0.72, rgb(255, 255, 255)),
    csk(1,    rgb(45, 45, 52)),
})
local __WAIT_COLOR = cs({
    csk(0,    rgb(95, 30, 35)),
    csk(0.22, rgb(255, 110, 120)),
    csk(0.48, rgb(100, 35, 42)),
    csk(0.72, rgb(255, 150, 155)),
    csk(1,    rgb(70, 25, 30)),
})
local __GOLD_NORMAL_COLOR = cs({
    csk(0,    rgb(75, 60, 25)),
    csk(0.22, rgb(255, 225, 120)),
    csk(0.48, rgb(110, 85, 30)),
    csk(0.72, rgb(255, 240, 175)),
    csk(1,    rgb(70, 55, 25)),
})
local __GOLD_WAIT_COLOR = __WAIT_COLOR

local function bind_safecallback(callback)
    if not callback then return end
    local ok, err = xpcall(callback, debug.traceback)
    if not ok then warn("\x5b" .. BRAND .. "\x5d[bind] " .. tostring(err)) end
end

function BindableButtons.relayout()
    local camera = Workspace.CurrentCamera
    local screen = (camera and camera.ViewportSize) or FALLBACK_VIEWPORT
    if not screen or screen.X <= 1 or screen.Y <= 1 then
        screen = FALLBACK_VIEWPORT
    end
    local h = BindableButtons.CurrentSize or 0.11
    local w = h * (screen.Y / screen.X)
    if w ~= w or w <= 0 or w > 1 then w = h * (FALLBACK_VIEWPORT.Y / FALLBACK_VIEWPORT.X) end
    local perRow = math.max(1, floor(0.84 / (w + 0.008)))
    for i = 1, #BindableButtons.order do
        local id = BindableButtons.order[i]
        local rec = BindableButtons.recs[id]
        if rec then
            local saved = config.bindPositions[id]
            if saved and type(saved.x) == "\x6eumber" and type(saved.y) == "\x6eumber" then
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
    BindableButtons.CurrentSize = clamp(sizeScale or 0.11, 0.02, 0.4)
    config.bindButtonSize = BindableButtons.CurrentSize
    BindableButtons.relayout()
    saveConfig()
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
    for _, rec in pairs(BindableButtons.recs) do rec.targetPress = 0 end
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

local function binderStep(dt)
    local cam = Workspace.CurrentCamera
    local scr = (cam and cam.ViewportSize) or FALLBACK_VIEWPORT
    local bh = BindableButtons.CurrentSize or 0.11
    local bw = bh * (scr.Y / scr.X)
    local rotStep = BindableButtons.ResetActive and 3.5 or 1.1
    local kHover = clamp(dt * 12, 0, 1)
    local kPress = clamp(dt * 16, 0, 1)

    for _, rec in pairs(BindableButtons.recs) do
        local btn = rec.btn
        if btn and rec.stroke then
            rec.hover = rec.hover + (rec.targetHover - rec.hover) * kHover
            rec.press = rec.press + (rec.targetPress - rec.press) * kPress
            local scale = 1 + rec.hover * 0.12 - rec.press * 0.08
            local diameter = bh * scr.Y * scale
            btn.Size = ud2(0, diameter, 0, diameter)
            rec.rot = (rec.rot + rotStep) % 360
            rec.stroke.Rotation = rec.rot
            rec.stroke.Color = BindableButtons.ResetActive and __WAIT_COLOR
                or (rec.isGold and __GOLD_NORMAL_COLOR or __NORMAL_COLOR)
        end
    end
end

local binderTickerOff = nil
local function binderEnsureTicker()
    if binderTickerOff then return end
    binderTickerOff = Ticker.add(binderStep)
    RootMaid:GiveTask(function()
        if binderTickerOff then binderTickerOff(); binderTickerOff = nil end
    end)
end

function BindableButtons.AddBButton(id, text, clickFunc, isGold)
    if BindableButtons.Buttons[id] then return BindableButtons.Buttons[id] end
    binderEnsureTicker()

    local buttonMaid = Maid.new()
    local storage = getStorage()
    local camera = Workspace.CurrentCamera
    local screen = (camera and camera.ViewportSize) or FALLBACK_VIEWPORT
    local h0 = BindableButtons.CurrentSize or 0.11
    local w0 = h0 * (screen.Y / screen.X)

     
    local ImageButton = new("\x49mageButton")
    ImageButton.Name = id
     
    local diameter = h0 * screen.Y
    ImageButton.Size = ud2(0, diameter, 0, diameter)
    ImageButton.AnchorPoint = v2(0.5, 0.5)
    ImageButton.Image = ""
    ImageButton.BackgroundColor3 = rgb(8, 8, 10)
    ImageButton.BackgroundTransparency = 0.28
    ImageButton.BorderSizePixel = 0
    ImageButton.ClipsDescendants = false
    ImageButton.AutoButtonColor = false
    ImageButton.ZIndex = 2
    ImageButton.Parent = storage
    buttonMaid:GiveTask(ImageButton)
    new("\x55ICorner", ImageButton).CornerRadius = ud(1, 0)
    local Aspect = new("\x55IAspectRatioConstraint", ImageButton)
    Aspect.AspectRatio = 1
    pcall(function() Aspect.AspectType = Enum.AspectType.ScaleWithParentSize end)

    local outerStroke = new("\x55IStroke", ImageButton)
    outerStroke.Color = rgb(255, 255, 255)
    outerStroke.Thickness = 2
    outerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    local Stroke = new("\x55IGradient", outerStroke)
    Stroke.Name = "\x40Stroke"
    Stroke.Color = isGold and __GOLD_NORMAL_COLOR or __NORMAL_COLOR
    local innerStroke = new("\x55IStroke", ImageButton)
    innerStroke.Color = rgb(105, 105, 112)
    innerStroke.Transparency = 0.5
    innerStroke.Thickness = 1
    innerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    local innerGradient = Stroke:Clone()
    innerGradient.Name = "\x40InnerStroke"
    innerGradient.Rotation = 180
    innerGradient.Parent = innerStroke

    local TextLabel = new("\x54extLabel", ImageButton)
    TextLabel.Name = "\x40Text"
    TextLabel.Size = ud2(0.76, 0, 0.76, 0)
    TextLabel.Position = ud2(0.5, 0, 0.5, 0)
    TextLabel.AnchorPoint = v2(0.5, 0.5)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Font = Enum.Font.Gotham
    TextLabel.Text = text
    TextLabel.TextColor3 = pclr(1, 1, 1)
    TextLabel.TextSize = 13
    TextLabel.TextWrapped = true
    TextLabel.ZIndex = 3

    local ripple = new("\x46rame")
    ripple.Name = "\x40ripple"
    ripple.BackgroundColor3 = isGold and rgb(255, 215, 0) or rgb(0, 155, 255)
    ripple.BackgroundTransparency = 0.45
    ripple.Size = ud2(0, 0, 0, 0)
    ripple.AnchorPoint = v2(0.5, 0.5)
    ripple.Visible = false
    ripple.ZIndex = 2
    ripple.Parent = ImageButton
    new("\x55ICorner", ripple).CornerRadius = ud(1, 0)

    local rec = {
        id = id, btn = ImageButton, stroke = Stroke, ripple = ripple,
        onClick = clickFunc, isGold = isGold and true or false,
        hover = 0, press = 0, targetHover = 0, targetPress = 0,
        rot = 0, x = 0.08, y = 0.88,
    }

    buttonMaid:GiveTask(ImageButton.InputBegan:Connect(function(input)
        if input.UserInputType ~= MOUSE1 and input.UserInputType ~= TOUCH then return end
        rec.targetPress = 1
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
        TweenService:Create(ripple, tinfo(0.4, EASING.Sine, EDIR.Out), {
            Size = ud2(0, 45, 0, 45), BackgroundTransparency = 1,
        }):Play()
    end))

    buttonMaid:GiveTask(ImageButton.InputChanged:Connect(function(input)
        if input.UserInputType ~= MOUSEMOV and input.UserInputType ~= TOUCH then return end
        if dragState and dragState.rec == rec then dragState.dragInput = input end
    end))
    buttonMaid:GiveTask(ImageButton.MouseEnter:Connect(function() rec.targetHover = 1 end))
    buttonMaid:GiveTask(ImageButton.MouseLeave:Connect(function() rec.targetHover = 0 end))

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
    local textLabel = btn:FindFirstChild("\x40Text")
    if textLabel then textLabel.Text = text end
    local stroke = btn:FindFirstChild("\x40Stroke", true)
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
    if not char:FindFirstChild("\x48umanoidRootPart") then return false end
    local hum = char:FindFirstChildOfClass("\x48umanoid")
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
    local root = char and char:FindFirstChild("\x48umanoidRootPart")
    if not root then return nil end
    local best, bestDist = nil, math.huge
    local players = Players:GetPlayers()
    for i = 1, #players do
        local player = players[i]
        if isValidTarget(player) then
            local tr = player.Character and player.Character:FindFirstChild("\x48umanoidRootPart")
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
        local remote = ReplicatedStorage:FindFirstChild("\x47etPlayerData", true)
        if remote and remote:IsA("\x52emoteFunction") then roleRemote = remote end
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
        if ok and type(result) == "\x74able" then
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
    if char:FindFirstChild("\x47un") or char:FindFirstChild("\x52evolver") then return true end
    local tool = char:FindFirstChildOfClass("\x54ool")
    if tool then
        local name = tool.Name:lower()
        if name:find("\x67un", 1, true) or name:find("\x72evolver", 1, true) then return true end
    end
    return false
end

local function quickScanSheriff()
    local players = Players:GetPlayers()
    for i = 1, #players do
        local player = players[i]
        if player ~= LocalPlayer and not state.whitelist[player.UserId] then
            if hasGunModel(player.Character) then return player end
            local bp = player:FindFirstChild("\x42ackpack")
            if bp and (bp:FindFirstChild("\x47un") or bp:FindFirstChild("\x52evolver")) then
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
        if type(data) == "\x74able" and data.Role == roleName and not data.Killed and not data.Dead then
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
    if not found then found = findTargetByRole("\x53heriff") end
    sheriffCache.player, sheriffCache.at = (isValidTarget(found) and found or nil), t
    return sheriffCache.player
end

local function findMurderer()
    local byRole = findTargetByRole("\x4durderer")
    if byRole then return byRole end
    local players = Players:GetPlayers()
    for i = 1, #players do
        local player = players[i]
        if player ~= LocalPlayer and not state.whitelist[player.UserId] then
            local char = player.Character
            if char then
                local tool = char:FindFirstChildOfClass("\x54ool")
                if tool then
                    local name = tool.Name:lower()
                    if name:find("\x6bnife", 1, true) or name:find("\x6durderer", 1, true) then
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
if type(flingFPDH) ~= "\x6eumber" or flingFPDH ~= flingFPDH then flingFPDH = -500 end
pcall(function() if getgenv then getgenv().FPDH = flingFPDH end end)

local currentFling = nil
local massFlingThread = nil

local function CleanupFlingPhysics()
    if flingBV then pcall(function() flingBV:Destroy() end) flingBV=nil end
    pcall(function() Workspace.FallenPartsDestroyHeight = flingFPDH end)
    pcall(function() if getgenv and getgenv().FPDH then Workspace.FallenPartsDestroyHeight=getgenv().FPDH end end)
    local char = LocalPlayer and LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("\x48umanoid")
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
    BindableButtons.ResetActive=false
    StatusHUD.Set("\x69dle")
end

 
local function SkidFling(TargetPlayer)
    if not TargetPlayer or not TargetPlayer.Parent then return false end
    if TargetPlayer == LocalPlayer or state.whitelist[TargetPlayer.UserId] then return false end

    local last = state.lastResetAt[TargetPlayer.UserId]
    if last and (now()-last) < (config.targetCooldown or 0) then return false end
    state.lastResetAt[TargetPlayer.UserId]=now()

    cancelCurrentFling()

    local Character = LocalPlayer and LocalPlayer.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("\x48umanoid")
    local RootPart = Humanoid and Humanoid.RootPart
    local TCharacter = TargetPlayer.Character
    local THumanoid = TCharacter and TCharacter:FindFirstChildOfClass("\x48umanoid")
    local TRootPart = THumanoid and THumanoid.RootPart or nil
    local THead = TCharacter and TCharacter:FindFirstChild("\x48ead")
    local Accessory = TCharacter and TCharacter:FindFirstChildOfClass("\x41ccessory")
    local Handle = Accessory and Accessory:FindFirstChild("\x48andle") or nil

    if not (Character and Humanoid and RootPart and TCharacter) then return false end
    if not TCharacter:FindFirstChildWhichIsA("\x42asePart") then return false end

    if RootPart.Velocity.Magnitude < 50 then
        flingOldPos = RootPart.CFrame
        pcall(function() if getgenv then getgenv().OldPos = flingOldPos end end)
    end
    if THumanoid and THumanoid.Sit then
        Notify("\x46ling", TargetPlayer.Name.."\x20is sitting",2)
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
    if type(savedDestroy) ~= "\x6eumber" or savedDestroy ~= savedDestroy then savedDestroy = -500 end
    Workspace.FallenPartsDestroyHeight = 0/0  

    if flingBV and flingBV.Parent then pcall(function() flingBV:Destroy() end) end
    flingBV = new("\x42odyVelocity")
    flingBV.Name = "\x46lingVel"
    flingBV.Velocity = v3(0, -downForce, 0)
    flingBV.MaxForce = v3(math.huge, math.huge, math.huge)
    flingBV.Parent = RootPart
    local flingBG = new("\x42odyGyro")
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
            if type(h) ~= "\x6eumber" or h ~= h then h = -500 end
            Workspace.FallenPartsDestroyHeight = h
        end)
        BindableButtons.ResetActive=false
        StatusHUD.Set("\x69dle")
    end
    flingObj.cancel=function() cleanup(true,true) end
    currentFling=flingObj
    BindableButtons.ResetActive=true
    StatusHUD.Set("\x61ctive", TargetPlayer.Name)
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
        local liveHum = liveChar:FindFirstChildOfClass("\x48umanoid")
        local liveRoot = liveChar:FindFirstChild("\x48umanoidRootPart") or TRootPart
        local liveHead = liveChar:FindFirstChild("\x48ead")
        if not (liveRoot and liveRoot.Parent) then cleanup(true) return end

        local vel = liveRoot.AssemblyLinearVelocity
        local horiz = v3(vel.X, 0, vel.Z)
        local speed = horiz.Magnitude
        local ping = 0.08
        pcall(function()
            local p = LocalPlayer:GetNetworkPing()
            if type(p)=="\x6eumber" and p==p then ping = math.max(p, 0.05) end
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
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("\x48umanoidRootPart")
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
            local hrp = c and c:FindFirstChild("\x48umanoidRootPart")
            if not (c and c.Parent and hrp and hrp.Parent) then continue end
            local dest = workspace.FallenPartsDestroyHeight
            if typeof(dest) == "\x6eumber" and hrp.Position.Y < dest + 50 then zeroTouchFlingSelf(); continue end
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
            if typeof(dest) == "\x6eumber" and hrp.Position.Y < dest + 50 then
                hrp.CFrame = saved
                zeroTouchFlingSelf()
            end
        end
        zeroTouchFlingSelf()
    end)
end
local function toggleTouchFling()
    setTouchFling(not touchFlingOn)
    Notify("\x54ouch Fling", touchFlingOn and "\x4fN — walk into players" or "\x4fFF", 2)
    pcall(function() ODHX.Set("⚡\x20Fling", "\x54ouch Fling", "\x54oggle", touchFlingOn, false) end)
    local btn = BindableButtons.Buttons and BindableButtons.Buttons["\x62ind_touchFling"]
    local lab = btn and btn:FindFirstChild("\x40Text")
    if lab then lab.Text = touchFlingOn and "\x54F ON" or "\x54F" end
end

local ACTIONS={}

ACTIONS.sheriff={
    name="\x53heriff", short="\x53h", label="🔫\x20Sheriff",
    run=function()
        local t=findSheriff()
        if t then SkidFling(t) else Notify("\x46ling","\x53heriff not found",3) end
    end,
}
ACTIONS.murderer={
    name="\x4durderer", short="\x4dur", label="🔪\x20Murderer",
    run=function()
        local t=findMurderer()
        if t then SkidFling(t) else Notify("\x46ling","\x4durderer not found",3) end
    end,
}
ACTIONS.selected={
    name="\x53elected", short="\x53el", label="🎯\x20Selected",
    run=function()
        local t=getSelectedOrFirst()
        if t then SkidFling(t) else Notify("\x46ling","\x4eo valid selected player",2) end
    end,
}
ACTIONS.all={
    name="\x41ll", short="\x41ll", label="👥\x20Everyone",
    run=function()
        if massFlingThread then Notify("\x46ling","\x4dass fling already running",2) return end
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
        Notify("\x46ling","\x46linging all...",2)
    end,
}
ACTIONS.nearest={
    name="\x4eearest", short="\x4erst", label="📍\x20Nearest",
    run=function()
        local t=findNearest()
        if t then SkidFling(t) else Notify("\x46ling","\x4eo valid target nearby",2) end
    end,
}
ACTIONS.start={
    name="\x53tart", short="\x47o", label="▶\x20Start",
    run=function()
        if maids.loopPlr then Notify("\x46ling","\x4coop already active - stop it first",2) return end
        local count=#state.selectedPlayers
        if count==0 and not isValidTarget(state.resetSelPlr) then Notify("\x46ling","\x4eo targets for loop",2) return end
        Notify("\x46ling","\x55se 🤖 Auto → Loop toggle for continuous",3)
        for _,p in ipairs(state.selectedPlayers) do if isValidTarget(p) then SkidFling(p); task.wait(0.2) end end
        if isValidTarget(state.resetSelPlr) then SkidFling(state.resetSelPlr) end
    end,
}
ACTIONS.cancel={
    name="\x43ancel", short="\x43an", label="⏹\x20Cancel",
    run=function() cancelCurrentFling(); Notify("\x46ling","\x43ancelled",2) end,
}
ACTIONS.touchFling={
    name="\x54ouch Fling", short="\x54F", label="👋\x20Touch Fling",
    run=toggleTouchFling,
}

local ACTION_ORDER={"\x73heriff","\x6durderer","\x73elected","\x61ll","\x6eearest","\x73tart","\x63ancel","\x74ouchFling"}

local function runAction(id)
    local a=ACTIONS[id]
    if not a then return end
    local ok,err=xpcall(a.run, debug.traceback)
    if not ok then warn("\x5b"..BRAND.."\x5d[action:"..id.."\x5d "..tostring(err)); Notify("\x45rror","\x41ction failed: "..id,3) end
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
        Notify("\x48otkey", ACTIONS[id].name.."\x20→ "..name,3)
        return
    end
    if processed then return end
    for _,id in ipairs(ACTION_ORDER) do
        if config.keybinds[id]==name then runAction(id); break end
    end
end))

 

 
local actionSection = AddSection("⚡\x20Fling")
actionSection:AddButton("🔫\x20Sheriff", function() runAction("\x73heriff") end)
actionSection:AddButton("🔪\x20Murderer", function() runAction("\x6durderer") end)
actionSection:AddButton("🎯\x20Selected", function() runAction("\x73elected") end)
actionSection:AddButton("👥\x20Everyone", function() runAction("\x61ll") end)
actionSection:AddButton("📍\x20Nearest", function() runAction("\x6eearest") end)
actionSection:AddButton("▶\x20Start (list)", function() runAction("\x73tart") end)
actionSection:AddButton("⏹\x20Cancel", function() runAction("\x63ancel") end)
actionSection:AddButton("👋\x20Touch Fling", function() runAction("\x74ouchFling") end)
actionSection:AddPlayerDropdown("▸\x20Fling player", function(p)
    if p and p ~= LocalPlayer then
        state.resetSelPlr = p
        if state.whitelist[p.UserId] then Notify("\x57hitelist", p.Name.."\x20is whitelisted!",3)
        else SkidFling(p); Notify("\x46ling","\x46linging "..p.Name,2) end
    end
end)
actionSection:AddToggle("\x54ouch Fling", setTouchFling)
actionSection:AddToggle("\x42ind Touch Fling", function(enabled)
    local id = "\x62ind_touchFling"
    if enabled then
        BindableButtons.AddBButton(id, "\x54F", function() runAction("\x74ouchFling") end)
        Notify("\x42inds", "\x54F button on screen", 2)
    else
        BindableButtons.DeleteBButton(id)
    end
end)

 
local autoSection = AddSection("🤖\x20Auto")
autoSection:AddToggle("\x41uto Sheriff", function(enabled)
    if enabled then
        startAutoModule("\x61utoSheriff", findSheriff, function() return config.autoSheriffDelay end)
    else
        stopAutoModule("\x61utoSheriff")
    end
end)
autoSection:AddToggle("\x41uto Murderer", function(enabled)
    if enabled then
        startAutoModule("\x61utoMurderer", findMurderer, function() return config.autoMurdererDelay end)
    else
        stopAutoModule("\x61utoMurderer")
    end
end)
autoSection:AddToggle("\x4coop", function(enabled)
    if not enabled then stopAutoModule("\x6coopPlr") return end
    local idx=1
    startAutoModule("\x6coopPlr", function()
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
autoSection:AddToggle("\x41ura", function(enabled)
    if not enabled then stopAutoModule("\x61ura") return end
    startAutoModule("\x61ura", function()
        local char=LocalPlayer.Character
        local root=char and char:FindFirstChild("\x48umanoidRootPart")
        if not root then return nil end
        local myPos=root.Position
        local maxSq=(config.auraStuds or 15)^2
        local best,bestDist=nil,maxSq
        local players=Players:GetPlayers()
        for i=1,#players do
            local player=players[i]
            if isValidTarget(player) then
                local tr=player.Character and player.Character:FindFirstChild("\x48umanoidRootPart")
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
autoSection:AddToggle("\x43lick", function(enabled)
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
                local model=hit.Instance:FindFirstAncestorWhichIsA("\x4dodel")
                local player=model and Players:GetPlayerFromCharacter(model)
                if player then return player end
            end
        end
        local target=mouse and mouse.Target
        local model=target and target:FindFirstAncestorWhichIsA("\x4dodel")
        local player=model and Players:GetPlayerFromCharacter(model)
        return player or nil
    end
    local function onInput(input, processed)
        if processed then return end
        if input.UserInputType ~= MOUSE1 and input.UserInputType ~= TOUCH then return end
        local ok, player=pcall(resolveTarget)
        if not ok or not player or player==LocalPlayer then return end
        state.resetSelPlr=player
        if state.whitelist[player.UserId] then Notify("\x43lick", player.Name.."\x20is whitelisted!",3)
        else SkidFling(player); Notify("\x43lick","\x46linging "..player.Name,2) end
    end
    maids.clickFling:GiveTask(UserInputService.InputBegan:Connect(onInput))
end)

 
local listSection = AddSection("📋\x20Lists")
listSection:AddPlayerDropdown("🎯\x20Select", function(p)
    if p and p ~= LocalPlayer then state.resetSelPlr=p; Notify("\x53elected", p.Name.."\x20set",3) end
end)
listSection:AddPlayerDropdown("➕\x20Loop", function(p)
    if p and p ~= LocalPlayer then
        state.resetSelPlr=p
        if not state.selectedSet[p.UserId] then
            state.selectedSet[p.UserId]=true
            insert(state.selectedPlayers,p)
            Notify("\x53elected", p.Name.."\x20added",3)
        end
    end
end)
listSection:AddButton("🧹\x20Clear loop", function()
    clearTable(state.selectedPlayers); clearTable(state.selectedSet)
    Notify("\x53elected","\x43leared",3)
end)
listSection:AddPlayerDropdown("🛡\x20Whitelist", function(p)
    if p and p ~= LocalPlayer then state.whitelist[p.UserId]=p.Name; Notify("\x57hitelist", p.Name.."\x20added",3); saveConfig() end
end)
listSection:AddPlayerDropdown("🛡\x20Un-whitelist", function(p)
    if p and state.whitelist[p.UserId] then state.whitelist[p.UserId]=nil; Notify("\x57hitelist", p.Name.."\x20removed",3); saveConfig()
    elseif p then Notify("\x57hitelist", p.Name.."\x20is not whitelisted",3) end
end)
listSection:AddButton("🧹\x20Clear WL", function() clearTable(state.whitelist); Notify("\x57hitelist","\x43leared",3); saveConfig() end)

 
local settingsSection = AddSection("⚙️\x20Tuning")
settingsSection:AddSlider("\x46ling Duration", 1, 5, config.flingDuration, function(v) config.flingDuration=v; saveConfig() end)
settingsSection:AddSlider("\x46ling Power", 1, 3, config.flingPower, function(v) config.flingPower=v; saveConfig() end)
settingsSection:AddSlider("\x50rediction", 0, 20, config.predictionStuds, function(v) config.predictionStuds=v; saveConfig() end)
settingsSection:AddSlider("\x53tart Height", -5, 20, config.startStuds, function(v) config.startStuds=v; saveConfig() end)
settingsSection:AddSlider("\x41ura Radius", 5, 50, config.auraStuds, function(v) config.auraStuds=v; saveConfig() end)
settingsSection:AddSlider("\x4coop Interval", 0.1, 1.0, config.loopInterval, function(v) config.loopInterval=v; saveConfig() end)
settingsSection:AddSlider("\x41ura Interval", 0.1, 1.0, config.auraInterval, function(v) config.auraInterval=v; saveConfig() end)
settingsSection:AddSlider("\x54arget Cooldown", 0, 3, config.targetCooldown, function(v) config.targetCooldown=v; saveConfig() end)
settingsSection:AddSlider("\x41uto Sheriff Delay", 0.1, 1.0, config.autoSheriffDelay, function(v) config.autoSheriffDelay=v; saveConfig() end)
settingsSection:AddSlider("\x41uto Murderer Delay", 0.1, 1.0, config.autoMurdererDelay, function(v) config.autoMurdererDelay=v; saveConfig() end)
settingsSection:AddSlider("\x52ole Cache TTL", 0.2, 3.0, config.roleCacheTTL, function(v) config.roleCacheTTL=v; saveConfig() end)
settingsSection:AddToggle("\x41uto Return", function(enabled) config.autoReturn=enabled and true or false; saveConfig() end)
settingsSection:AddToggle("\x4eotifications", function(enabled) config.notifications=enabled and true or false; saveConfig() end)

 
local floatSection = AddSection("🔘\x20Binds")
floatSection:AddToggle("\x53FX 🔇", function(bool) Audio.setMuted(bool) end)

local function toggleBindButton(actionId)
    return function(enabled)
        local id="\x62ind_"..actionId
        if enabled then
            BindableButtons.AddBButton(id, ACTIONS[actionId].short, function() runAction(actionId) end, actionId=="\x73elected")
        else
            BindableButtons.DeleteBButton(id)
        end
    end
end

for _,id in ipairs(ACTION_ORDER) do
    floatSection:AddToggle("\x42ind "..ACTIONS[id].name, toggleBindButton(id))
end
floatSection:AddSlider("\x42ind Size (%)", 5, 25, math.floor((config.bindButtonSize or 0.11)*100), function(value)
    BindableButtons.setSize(value/100)
end)
floatSection:AddButton("🧩\x20Reset bind layout", function() BindableButtons.resetLayout(); Notify("\x42inds","\x4cayout reset",2) end)
floatSection:AddButton("🛑\x20Panic", function()
    cancelCurrentFling()
    setTouchFling(false)
    for _,key in ipairs({"\x6coopPlr","\x63lickFling","\x61ura","\x61utoSheriff","\x61utoMurderer","\x74ouchFling"}) do stopAutoModule(key) end
    BindableButtons.clearAll()
    for _,r in ipairs(ODHX.records) do
        if r.kind=="\x54oggle" and (r.section=="🤖\x20Auto" or (r.section=="🔘\x20Binds" and r.name:sub(1,5)=="\x42ind ")) then
            ODHX.Set(r.section,r.name,r.kind,false,false)
        end
    end
    Notify("\x50anic","\x41ll modules stopped",3)
end)

 
local keySection = AddSection("🔑\x20Keys")
for _,id in ipairs(ACTION_ORDER) do
    keySection:AddToggle("\x4bey "..ACTIONS[id].name.."\x20["..keyName(id).."\x5d", function(enabled)
        if enabled then Keybinds.capture=id; Notify("\x48otkey","\x50ress a key for "..ACTIONS[id].name.."\x2e..",5)
        else config.keybinds[id]=nil; if Keybinds.capture==id then Keybinds.capture=nil end; saveConfig(); Notify("\x48otkey", ACTIONS[id].name.."\x20key cleared",3) end
    end)
end
keySection:AddButton("🧹\x20Clear keys", function() clearTable(config.keybinds); Keybinds.capture=nil; saveConfig(); Notify("\x48otkey","\x41ll hotkeys cleared",3) end)

 
do
    local function nfind(s, p)
        return string.find(s, p, 1, true) ~= nil
    end
    local defs = {
        aim = {
            { "\x53ilent Aim Gun", function(n) return nfind(n,"\x70istol") or nfind(n,"\x70iercer") or nfind(n,"\x67un targeting") or (nfind(n,"\x73ilent aim") and not nfind(n,"\x6bnife")) or (string.sub(n,1,4)=="\x67un " and not nfind(n,"\x6bnife")) end },
            { "\x53ilent Aim Knife", function(n) return nfind(n,"\x6bnife") end },
        },
        main = {
            { "\x4dovement", function(n) return nfind(n,"\x75niversal") or nfind(n,"\x6eoclip") or nfind(n,"\x66ly") end },
            { "\x49nvisible", function(n) return nfind(n,"\x69nvisible") end },
            { "\x46un", function(n) return nfind(n,"\x66un client") or nfind(n,"\x66un") end },
            { "\x53erver", function(n) return nfind(n,"\x73erver") end },
        },
        world = {
            { "\x47un", function(n) return nfind(n,"\x77orld") and nfind(n,"\x67un") end },
            { "\x46ling", function(n) return nfind(n,"\x66ling") or nfind(n,"🤖") or nfind(n,"\x6cists") or nfind(n,"\x74uning") or nfind(n,"\x62inds") or nfind(n,"\x6beys") or nfind(n,"\x61uto") end },
            { "\x42omb Jump", function(n) return nfind(n,"\x62omb") end },
            { "\x57orld", function(n) return nfind(n,"\x77orld") and not nfind(n,"\x67un") and not nfind(n,"\x62omb") and not nfind(n,"\x66ling") end },
        },
        visual = {
            { "\x4fbjects", function(n) return nfind(n,"\x6fbject") end },
            { "\x45SP", function(n) return nfind(n,"\x76isual") end },
        },
        emotes = {
            { "\x41nimations", function(n) return true end },
        },
        misc = {
            { "\x41imlock", function(n) return nfind(n,"\x61imlock") end },
            { "\x43ursor", function(n) return nfind(n,"\x63ursor") end },
            { "\x46PS", function(n) return nfind(n,"\x66ps") and not nfind(n,"\x61imlock") end },
            { "\x44esync", function(n) return nfind(n,"\x64esync") end },
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
        local bar = New("\x46rame", { Parent = frame, Name = "\x4eoirSubBar", ZIndex = 6,
            Position = UDim2.fromOffset(0, 2), Size = UDim2.new(1, 0, 0, 42),
            BackgroundColor3 = C.surface, BackgroundTransparency = .2 })
        corner(bar, 12); stroke(bar, C.border, .45)
        New("\x55IListLayout", { Parent = bar, FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 4), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder })
        New("\x55IPadding", { Parent = bar, PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) })
        for _, child in ipairs(frame:GetChildren()) do
            if child:IsA("\x53crollingFrame") then
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
                btn.BackgroundTransparency = on and .15 or 1
                btn.TextColor3 = on and C.text or C.dim
                local line = btn:FindFirstChild("\x4fnLine")
                if line then line.Visible = on end
            end
        end
        local w = 1 / math.max(#tabs, 1)
        for i, tab in ipairs(tabs) do
            local title = tab[1]
            local b = New("\x54extButton", { Parent = bar, LayoutOrder = i, Size = UDim2.new(w, -4, 0, 30),
                BackgroundColor3 = C.panel, BackgroundTransparency = 1, Text = title,
                TextColor3 = C.dim, TextSize = 12, Font = Enum.Font.GothamMedium, AutoButtonColor = false })
            corner(b, 8)
            New("\x46rame", { Parent = b, Name = "\x4fnLine", AnchorPoint = Vector2.new(.5, 1),
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
 
BindableButtons.setSize(config.bindButtonSize or 0.11)
hudApplyPosition()
if configLoaded then Notify(BRAND, VERSION.."\x20loaded (config restored)",3)
else Notify(BRAND, VERSION.."\x20loaded. Duplicates auto-cleaned.",3) end
if headlessMode then Notify(BRAND,"\x4denu API missing — headless mode (binds/hotkeys work)",5) end

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
    if type(getgenv) ~= "\x66unction" then return end
    local g=getgenv()
    if type(g)~="\x74able" then return end
    rawset(g, UNLOAD_GLOBAL, ODHX.Stop)
end)

ODHX.Bind("⚙️\x20Tuning", "\x41uto Return", "\x54oggle", function() return config.autoReturn end)
ODHX.Bind("⚙️\x20Tuning", "\x4eotifications", "\x54oggle", function() return config.notifications end)
ODHX.Bind("🔘\x20Binds", "\x53FX 🔇", "\x54oggle", function() return config.muteSounds end)
ODHX.Bind("⚙️\x20Tuning", "\x46ling Duration", "\x53lider", function() return config.flingDuration end)
ODHX.Bind("⚙️\x20Tuning", "\x46ling Power", "\x53lider", function() return config.flingPower end)
ODHX.Bind("⚙️\x20Tuning", "\x50rediction", "\x53lider", function() return config.predictionStuds end)
ODHX.Bind("⚙️\x20Tuning", "\x53tart Height", "\x53lider", function() return config.startStuds end)
ODHX.Bind("⚙️\x20Tuning", "\x41ura Radius", "\x53lider", function() return config.auraStuds end)
ODHX.Bind("⚙️\x20Tuning", "\x4coop Interval", "\x53lider", function() return config.loopInterval end)
ODHX.Bind("⚙️\x20Tuning", "\x41ura Interval", "\x53lider", function() return config.auraInterval end)
ODHX.Bind("⚙️\x20Tuning", "\x54arget Cooldown", "\x53lider", function() return config.targetCooldown end)
ODHX.Bind("⚙️\x20Tuning", "\x41uto Sheriff Delay", "\x53lider", function() return config.autoSheriffDelay end)
ODHX.Bind("⚙️\x20Tuning", "\x41uto Murderer Delay", "\x53lider", function() return config.autoMurdererDelay end)
ODHX.Bind("⚙️\x20Tuning", "\x52ole Cache TTL", "\x53lider", function() return config.roleCacheTTL end)
ODHX.Bind("🔘\x20Binds", "\x42ind Size (%)", "\x53lider", function() return config.bindButtonSize*100 end)
ODHX.cleanup=unload
ODHX.Finish()

    end, function(__error) return tostring(__error) end)
    if not __pluginOk then
        warn("\x5bNoir embedded plugin: fling_мой.lua.txt] " .. tostring(__pluginError))
        notify("\x66ling_мой.lua.txt failed to load: " .. tostring(__pluginError), 7)
    end
end

