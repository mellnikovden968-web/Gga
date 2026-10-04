local Players           = game:GetService("Players")
local UIS               = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local Stats             = game:GetService("Stats")
local Workspace         = game:GetService("Workspace")
local CoreGui           = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService       = game:GetService("HttpService")
local Lighting          = game:GetService("Lighting")
local LocalPlayer       = Players.LocalPlayer

local IS_TOUCH = UIS.TouchEnabled == true
local IS_KEYBOARD = UIS.KeyboardEnabled == true
local IS_MOUSE = UIS.MouseEnabled == true
local INPUT_DEVICE = (IS_TOUCH and not IS_MOUSE and not IS_KEYBOARD) and "Touch"
    or (IS_TOUCH and "Hybrid")
    or "Desktop"

local function isPrimaryPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

local STORAGE_ROOT = "Noir Hub"
local ASSETS_FOLDER = STORAGE_ROOT .. "/assets"
local CONFIGS_FOLDER = STORAGE_ROOT .. "/configs"
local PRESETS_FOLDER = STORAGE_ROOT .. "/presets"
local LEGACY_STORAGE_ROOT = "NOIR.CONFIG"

local function ensureFolder(path)
    if type(makefolder) ~= "function" then return end
    if type(isfolder) == "function" then
        local ok, exists = pcall(isfolder, path)
        if ok and exists then return end
    end
    pcall(makefolder, path)
end

local function ensureStorageFolders()
    ensureFolder(STORAGE_ROOT)
    ensureFolder(ASSETS_FOLDER)
    ensureFolder(CONFIGS_FOLDER)
    ensureFolder(PRESETS_FOLDER)
end

local function fileExists(path)
    if type(isfile) ~= "function" then return false end
    local ok, exists = pcall(isfile, path)
    return ok and exists == true
end

local function copyLegacyFile(source, destination)
    if type(readfile) ~= "function" or type(writefile) ~= "function" then return end
    if not fileExists(source) or fileExists(destination) then return end
    local ok, contents = pcall(readfile, source)
    if ok then pcall(writefile, destination, contents) end
end

local function migrateLegacyStorage()
    copyLegacyFile(LEGACY_STORAGE_ROOT .. "/autosave.json", CONFIGS_FOLDER .. "/autosave.json")
    for _, name in ipairs({
        "ODH_FEAnimations_settings.json",
        "ODH_BJP_settings.json",
        "ODH_InventoryUnlimiter_settings.json",
        "ODH_Pm-Wallhop_settings.json",
    }) do
        copyLegacyFile(name, CONFIGS_FOLDER .. "/" .. name)
    end
    if type(listfiles) ~= "function" or type(readfile) ~= "function" or type(writefile) ~= "function" then return end
    local ok, files = pcall(listfiles, LEGACY_STORAGE_ROOT)
    if not ok or type(files) ~= "table" then return end
    for _, source in ipairs(files) do
        local normalized = tostring(source):gsub("\\", "/")
        local name = normalized:match("([^/]+%.preset)$")
        if name then copyLegacyFile(source, PRESETS_FOLDER .. "/" .. name) end
    end
end

ensureStorageFolders()
migrateLegacyStorage()

local guiParent = CoreGui
if type(gethui) == "function" then local ok,v=pcall(gethui); if ok and typeof(v)=="Instance" then guiParent=v end end
pcall(function() local old=guiParent:FindFirstChild("NoirSilentAimUI"); if old then old:Destroy() end end)

local NoirPersistence = {
    data = { toggles = {}, sliders = {}, dropdowns = {}, textboxes = {}, keybinds = {}, positions = {}, colors = {} },
    token = 0,
    path = CONFIGS_FOLDER .. "/autosave.json",
    safeLegacy = {
        Enabled=true, ["Wall Check"]=true, ["Show Shoot Murder Button"]=true,
        ["Lock Shoot Murder Button"]=true, ["Knife Silent Aim"]=true, ["Knife Wall Check"]=true,
        ["Prioritize Sheriff"]=true, ["Enable WalkSpeed"]=true, ["Enable JumpPower"]=true,
        ["Show Round Timer"]=true, ["Instant Role Detection"]=true, ["Auto Notify Roles"]=true,
        ["Auto Fire"]=true, ["Show FOV"]=true, ["Ignore Dead"]=true,
        ["Ignore Friends"]=true, ["Anti AFK"]=true,
    },
}
do
    if type(readfile) == "function" then
        pcall(function()
            local loaded = HttpService:JSONDecode(readfile(NoirPersistence.path))
            if typeof(loaded) == "table" then NoirPersistence.data = loaded end
        end)
    end
    for _, key in ipairs({"toggles","sliders","dropdowns","textboxes","keybinds","positions","colors"}) do
        if typeof(NoirPersistence.data[key]) ~= "table" then NoirPersistence.data[key] = {} end
    end
end
function NoirPersistence.Save()
    if type(writefile) ~= "function" then return end
    NoirPersistence.token += 1
    local token = NoirPersistence.token
    task.delay(.35, function()
        if token ~= NoirPersistence.token then return end
        pcall(function()
            ensureStorageFolders()
            writefile(NoirPersistence.path, HttpService:JSONEncode(NoirPersistence.data))
        end)
    end)
end
function NoirPersistence.GetPosition(key, fallback)
    local p = NoirPersistence.data.positions[key]
    if typeof(p) == "table" and #p == 4 then return UDim2.new(p[1], p[2], p[3], p[4]) end
    return fallback
end
function NoirPersistence.SetPosition(key, p)
    NoirPersistence.data.positions[key] = { p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset }
    NoirPersistence.Save()
end

local C = {
    base = Color3.fromRGB(7,8,10), surface = Color3.fromRGB(15,17,20), panel = Color3.fromRGB(13,15,18),
    card = Color3.fromRGB(17,19,23), border = Color3.fromRGB(120,126,134), accent = Color3.fromRGB(93,168,94),
    accent2 = Color3.fromRGB(122,201,122), text = Color3.fromRGB(233,235,238), dim = Color3.fromRGB(124,130,138),
    off = Color3.fromRGB(42,45,50), btn = Color3.fromRGB(35,38,41),
}
function New(class, props)
    local x = Instance.new(class)
    for k, v in pairs(props or {}) do if k ~= "Parent" then x[k] = v end end
    x.Parent = props and props.Parent
    return x
end
function corner(x, r) New("UICorner", { CornerRadius = UDim.new(0, r or 12), Parent = x }) end
local gradientStrokes = {}
function stroke(x, col, tr)
    local s = New("UIStroke", { Color = col or C.border, Transparency = tr or .55, Thickness = 1, Parent = x })
    local g = New("UIGradient", { Parent = s, Rotation = 35, Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(70,74,80)),
        ColorSequenceKeypoint.new(.22, Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(.5, Color3.fromRGB(96,101,108)),
        ColorSequenceKeypoint.new(.78, Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(70,74,80)),
    }) })
    table.insert(gradientStrokes, g)
    return s
end
local gradientAccum = 0
RunService.RenderStepped:Connect(function(dt)
    if #gradientStrokes == 0 then return end
    gradientAccum += dt
    if gradientAccum < 0.04 then return end
    local step = gradientAccum * 30
    gradientAccum = 0
    for i = #gradientStrokes, 1, -1 do
        local g = gradientStrokes[i]
        if g.Parent then
            g.Rotation = (g.Rotation + step) % 360
        else
            table.remove(gradientStrokes, i)
        end
    end
end)
function text(parent, value, size, pos, dim)
    return New("TextLabel", { Parent = parent, BackgroundTransparency = 1, Text = value, TextColor3 = dim and C.dim or C.text,
        TextSize = size, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left,
        Position = pos or UDim2.new(), Size = UDim2.new(1, 0, 0, size + 8) })
end

local gui = New("ScreenGui", { Name = "NoirSilentAimUI", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = guiParent })
local scale = New("UIScale", { Parent = gui, Scale = 1 })
function rescale()
    local v = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
    scale.Scale = math.min(v.X / 1450, v.Y / 850, 0.68)
end
rescale()
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale) end

local win = New("Frame", { Parent = gui, Name = "Window", AnchorPoint = Vector2.new(.5, .5),
    Position = NoirPersistence.GetPosition("window", UDim2.fromScale(.5, .5)), Size = UDim2.fromOffset(1180, 700),
    BackgroundColor3 = C.base, BackgroundTransparency = .04, ClipsDescendants = true, Visible = false })
local winScale = New("UIScale", { Parent = win, Scale = .68 })
corner(win, 22)
local winStroke = stroke(win, C.border, .5); winStroke.Thickness = 1.5
New("UIGradient", { Parent = win, Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(20,22,26)),
    ColorSequenceKeypoint.new(.45, Color3.fromRGB(9,10,13)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(3,4,6)) }), Rotation = 25 })

local navButtons, navIcons = {}, {}
local sidebar = New("Frame", { Parent = win, Size = UDim2.fromOffset(240, 700), BackgroundColor3 = C.surface, BackgroundTransparency = .28 })
corner(sidebar, 22); stroke(sidebar, C.border, .68)
local logo = New("TextLabel", { Parent = sidebar, Position = UDim2.fromOffset(26, 32), Size = UDim2.fromOffset(190, 42),
    BackgroundTransparency = 1, Text = "NOIR", TextColor3 = C.text, TextSize = 34, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left })
New("UIGradient", { Parent = logo, Color = ColorSequence.new(C.text, C.accent2), Rotation = 0 })
text(sidebar, "R O B L O X   H U B", 10, UDim2.fromOffset(28, 76), true)
do
    local navDefs = {
        { "home",   16898613509, Vector2.new(820, 147), "Home" },
        { "main",   16898613509, Vector2.new(820, 147), "Main" },
        { "aim",    16898613777, Vector2.new(967, 759), "Combat" },
        { "world",  16898613509, Vector2.new(771, 563), "World" },
        { "visual", 16898613353, Vector2.new(771, 563), "Visuals" },
        { "emotes", 16898613777, Vector2.new(967, 759), "Emotes" },
        { "misc",   16898613509, Vector2.new(820, 147), "Misc" },
    }
    for i, d in ipairs(navDefs) do
        local b = New("TextButton", { Parent = sidebar, Position = UDim2.fromOffset(16, 116 + (i - 1) * 52), Size = UDim2.fromOffset(208, 46),
            BackgroundColor3 = C.surface, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Name = d[4] })
        corner(b, 12)
        local ic = New("ImageLabel", { Parent = b, Position = UDim2.fromOffset(14, 11), Size = UDim2.fromOffset(24, 24),
            BackgroundTransparency = 1, Image = "rbxassetid://" .. d[2], ImageRectSize = Vector2.new(48, 48), ImageRectOffset = d[3],
            ImageColor3 = C.dim })
        local lbl = New("TextLabel", { Parent = b, Position = UDim2.fromOffset(50, 0), Size = UDim2.new(1, -60, 1, 0),
            BackgroundTransparency = 1, Text = d[4], TextColor3 = C.dim, TextSize = 15, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left })
        local bar = New("Frame", { Parent = b, Position = UDim2.fromOffset(0, 12), Size = UDim2.fromOffset(3, 22), BackgroundColor3 = C.accent, BackgroundTransparency = 1 })
        corner(bar, 2)
        local glyphs = nil
        local rings = nil
        if d[1] == "emotes" then
            -- A clear person-shaped icon for Emotes instead of the Combat crossed-swords sprite.
            ic.Visible = false
            glyphs = {}
            local function glyphPart(position, size, rounded)
                local part = New("Frame", { Parent = b, Position = position, Size = size, BackgroundColor3 = C.dim, BorderSizePixel = 0 })
                if rounded then corner(part, rounded) end
                glyphs[#glyphs + 1] = part
            end
            glyphPart(UDim2.fromOffset(20, 8), UDim2.fromOffset(10, 10), 5)
            glyphPart(UDim2.fromOffset(21, 18), UDim2.fromOffset(8, 10), 3)
            glyphPart(UDim2.fromOffset(15, 20), UDim2.fromOffset(20, 4), 2)
            glyphPart(UDim2.fromOffset(19, 27), UDim2.fromOffset(4, 8), 2)
            glyphPart(UDim2.fromOffset(27, 27), UDim2.fromOffset(4, 8), 2)
        elseif d[1] == "misc" then
            -- Requested Misc mark: a circular outline containing three dots.
            ic.Visible = false
            glyphs, rings = {}, {}
            local ring = New("Frame", { Parent = b, Position = UDim2.fromOffset(14, 10), Size = UDim2.fromOffset(26, 26), BackgroundTransparency = 1, BorderSizePixel = 0 })
            corner(ring, 13)
            local ringStroke = New("UIStroke", { Parent = ring, Color = C.dim, Thickness = 1.5, Transparency = .08 })
            rings[#rings + 1] = ringStroke
            for index = 0, 2 do
                local dot = New("Frame", { Parent = ring, Position = UDim2.fromOffset(5 + index * 6, 11), Size = UDim2.fromOffset(4, 4), BackgroundColor3 = C.dim, BorderSizePixel = 0 })
                corner(dot, 2); glyphs[#glyphs + 1] = dot
            end
        end
        navButtons[d[1]] = b; navIcons[d[1]] = { icon = ic, label = lbl, bar = bar, glyphs = glyphs, rings = rings }
    end
end
local status = New("Frame", { Parent = sidebar, Position = UDim2.fromOffset(16, 596), Size = UDim2.fromOffset(208, 84), BackgroundColor3 = C.panel, BackgroundTransparency = .18 })
corner(status, 16); stroke(status, C.border, .6)
local statusDot = New("Frame", { Parent = status, Position = UDim2.fromOffset(16, 21), Size = UDim2.fromOffset(8, 8), BackgroundColor3 = C.accent })
corner(statusDot, 4)
text(status, "Connected", 13, UDim2.fromOffset(30, 15))
text(status, "Noir Client \u{2022} v4", 15, UDim2.fromOffset(16, 45))

local header = New("Frame", { Parent = win, Position = UDim2.fromOffset(240, 0), Size = UDim2.new(1, -240, 0, 96), BackgroundTransparency = 1 })
text(header, "NOIR HUB", 24, UDim2.fromOffset(28, 24))
text(header, "Silent Aim \u{2022} ESP \u{2022} Prediction", 13, UDim2.fromOffset(29, 56), true)
local creatorImage = ""
do
    local customAsset = (type(getcustomasset) == "function" and getcustomasset) or (type(getsynasset) == "function" and getsynasset)
    if type(writefile) == "function" and customAsset then
        local encoded = "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"
        local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        local decoded = encoded:gsub("[^" .. alphabet .. "=]", ""):gsub(".", function(x)
            if x == "=" then return "" end
            local r, f = "", alphabet:find(x, 1, true) - 1
            for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and "1" or "0") end
            return r
        end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
            if #x ~= 8 then return "" end
            local c = 0
            for i = 1, 8 do c = c + (x:sub(i, i) == "1" and 2 ^ (8 - i) or 0) end
            return string.char(c)
        end)
        local imagePath = ASSETS_FOLDER .. "/NOIR_CREATOR.jpg"
        pcall(writefile, imagePath, decoded)
        local ok, asset = pcall(customAsset, imagePath)
        if ok then creatorImage = asset end
    end
end
local search = New("TextBox", { Parent = header, Position = UDim2.new(1, -470, 0, 26), Size = UDim2.fromOffset(300, 44),
    BackgroundColor3 = C.panel, PlaceholderText = "   Search features...", Text = "", TextColor3 = C.text,
    PlaceholderColor3 = C.dim, TextSize = 14, Font = Enum.Font.Gotham, ClearTextOnFocus = false })
corner(search, 12); stroke(search)
local icon = New("ImageLabel", { Parent = header, Position = UDim2.new(1, -152, 0, 26), Size = UDim2.fromOffset(44, 44),
    BackgroundColor3 = C.panel, Image = creatorImage, ScaleType = Enum.ScaleType.Crop })
corner(icon, 13); stroke(icon, C.border, .45)
if creatorImage == "" then local fb = text(icon, "N", 22, UDim2.fromOffset(0, 8)); fb.TextXAlignment = Enum.TextXAlignment.Center end
function styleCircularButton(b, diameter)
    b.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
    b.BackgroundTransparency = .28
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.ClipsDescendants = false
    b.ZIndex = 20
    corner(b, math.floor(diameter / 2))
    local outer = New("UIStroke", { Parent = b, Color = Color3.fromRGB(255, 255, 255), Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
    local gradient = New("UIGradient", { Parent = outer, Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 40)),
        ColorSequenceKeypoint.new(.22, Color3.fromRGB(250, 250, 252)),
        ColorSequenceKeypoint.new(.48, Color3.fromRGB(70, 70, 78)),
        ColorSequenceKeypoint.new(.72, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(45, 45, 52)),
    }) })
    table.insert(gradientStrokes, gradient)
    local inner = New("UIStroke", { Parent = b, Color = Color3.fromRGB(105, 105, 112), Transparency = .5, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
    local innerGradient = gradient:Clone(); innerGradient.Rotation = 180; innerGradient.Parent = inner
    table.insert(gradientStrokes, innerGradient)
    local sound = Instance.new("Sound")
    sound.Name = "NoirButtonSound"; sound.SoundId = "rbxassetid://3868133279"; sound.Volume = .35; sound.Parent = b
    local baseTextSize = b.TextSize
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(.18), { BackgroundTransparency = .12, TextSize = baseTextSize + 1 }):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(.22), { BackgroundTransparency = .28, TextSize = baseTextSize }):Play()
    end)
    b.MouseButton1Down:Connect(function()
        sound:Play()
        TweenService:Create(b, TweenInfo.new(.14, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { BackgroundColor3 = Color3.fromRGB(27, 27, 31), Size = UDim2.fromOffset(diameter + 6, diameter + 6) }):Play()
    end)
    b.MouseButton1Up:Connect(function()
        TweenService:Create(b, TweenInfo.new(.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { BackgroundColor3 = Color3.fromRGB(8, 8, 10), Size = UDim2.fromOffset(diameter, diameter) }):Play()
    end)
    return b
end
function topButton(txt, x, color)
    local b = New("TextButton", { Parent = header, Position = UDim2.new(1, x, 0, 26), Size = UDim2.fromOffset(44, 44),
        BackgroundColor3 = color or C.btn, Text = txt, TextColor3 = C.text, TextSize = 22, Font = Enum.Font.GothamBold })
    return styleCircularButton(b, 44)
end
local mini = topButton("\u{2212}", -98, C.btn)
local close = topButton("\u{00d7}", -48, C.btn)
close.MouseButton1Click:Connect(function()
    TweenService:Create(winScale, TweenInfo.new(.28, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { Scale = .78 }):Play()
    TweenService:Create(win, TweenInfo.new(.28), { BackgroundTransparency = 1 }):Play()
    task.delay(.29, function() if gui.Parent then gui:Destroy() end end)
end)

local dragging, dragStart, startPos
header.Active = true
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = input.Position; startPos = win.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        local view = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
        local half = win.AbsoluteSize / 2
        local desired = Vector2.new(startPos.X.Scale * view.X + startPos.X.Offset * scale.Scale + delta.X,
            startPos.Y.Scale * view.Y + startPos.Y.Offset * scale.Scale + delta.Y)
        desired = Vector2.new(math.clamp(desired.X, half.X, view.X - half.X), math.clamp(desired.Y, half.Y, view.Y - half.Y))
        win.Position = UDim2.fromOffset(desired.X / scale.Scale, desired.Y / scale.Scale)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        if dragging then NoirPersistence.SetPosition("window", win.Position) end
        dragging = false
    end
end)

local restore = New("TextButton", { Parent = gui, AnchorPoint = Vector2.new(1, .5), Position = NoirPersistence.GetPosition("restore", UDim2.new(1, -22, .5, 0)),
    Size = UDim2.fromOffset(62, 62), BackgroundColor3 = C.panel, Text = "N", TextColor3 = C.text, TextSize = 30,
    Font = Enum.Font.GothamBold, Visible = false, AutoButtonColor = false })
styleCircularButton(restore, 62)
local restoreDragging, restoreMoved, restoreStart, restorePos = false, false, nil, nil
restore.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        restoreDragging = true; restoreMoved = false; restoreStart = input.Position; restorePos = restore.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if restoreDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - restoreStart
        if delta.Magnitude > 7 then restoreMoved = true end
        local view = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
        local x = math.clamp(restorePos.X.Offset * scale.Scale + delta.X, 34, view.X - 34)
        local y = math.clamp(restorePos.Y.Scale * view.Y + restorePos.Y.Offset * scale.Scale + delta.Y, 34, view.Y - 34)
        restore.Position = UDim2.fromOffset(x / scale.Scale, y / scale.Scale)
    end
end)
UIS.InputEnded:Connect(function(input)
    if restoreDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
        restoreDragging = false; NoirPersistence.SetPosition("restore", restore.Position)
    end
end)
mini.MouseButton1Click:Connect(function()
    TweenService:Create(winScale, TweenInfo.new(.28, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { Scale = .72 }):Play()
    task.delay(.28, function() if win.Parent then win.Visible = false; restore.Visible = true end end)
end)
restore.MouseButton1Click:Connect(function()
    if restoreMoved then restoreMoved = false return end
    restore.Visible = false; win.Visible = true; winScale.Scale = .72
    TweenService:Create(winScale, TweenInfo.new(.46, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end)

local content = New("ScrollingFrame", { Parent = win, Position = UDim2.fromOffset(275, 110), Size = UDim2.new(1, -300, 1, -130),
    BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 7, ScrollBarImageColor3 = C.accent,
    CanvasSize = UDim2.fromOffset(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
    ScrollingEnabled = true, Active = true, ElasticBehavior = Enum.ElasticBehavior.WhenScrollable, VerticalScrollBarInset = Enum.ScrollBarInset.Always })
local cols = {}
for i = 1, 2 do
    cols[i] = New("Frame", { Parent = content, Position = UDim2.new((i - 1) * .5, (i - 1) * 10, 0, 0), Size = UDim2.new(.5, -10, 0, 0),
        BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y })
    New("UIListLayout", { Parent = cols[i], Padding = UDim.new(0, 16), SortOrder = Enum.SortOrder.LayoutOrder })
end
local configContent = content:Clone(); configContent.Name = "ConfigContent"; configContent.Parent = win; configContent.Visible = false; configContent:ClearAllChildren()
local configCols = {}
for i = 1, 2 do
    configCols[i] = New("Frame", { Parent = configContent, Position = UDim2.new((i - 1) * .5, (i - 1) * 10, 0, 0), Size = UDim2.new(.5, -10, 0, 0),
        BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y })
    New("UIListLayout", { Parent = configCols[i], Padding = UDim.new(0, 16), SortOrder = Enum.SortOrder.LayoutOrder })
end
content.Position = UDim2.fromOffset(282, 104); content.Size = UDim2.new(1, -306, 1, -128); content.Visible = false
configContent.Position = content.Position; configContent.Size = content.Size
local visualContent = content:Clone(); visualContent.Name = "VisualContent"; visualContent.Parent = win; visualContent.Visible = false; visualContent:ClearAllChildren()
local visualCols = {}
for i = 1, 2 do
    visualCols[i] = New("Frame", { Parent = visualContent, Position = UDim2.new((i - 1) * .5, (i - 1) * 10, 0, 0), Size = UDim2.new(.5, -10, 0, 0),
        BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y })
    New("UIListLayout", { Parent = visualCols[i], Padding = UDim.new(0, 16), SortOrder = Enum.SortOrder.LayoutOrder })
end
local mainContent = content:Clone(); mainContent.Name = "MainContent"; mainContent.Parent = win; mainContent.Visible = false; mainContent:ClearAllChildren()
local mainCols = {}
for i = 1, 2 do
    mainCols[i] = New("Frame", { Parent = mainContent, Position = UDim2.new((i - 1) * .5, (i - 1) * 10, 0, 0), Size = UDim2.new(.5, -10, 0, 0),
        BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y })
    New("UIListLayout", { Parent = mainCols[i], Padding = UDim.new(0, 16), SortOrder = Enum.SortOrder.LayoutOrder })
end
local worldContent = content:Clone(); worldContent.Name = "WorldContent"; worldContent.Parent = win; worldContent.Visible = false; worldContent:ClearAllChildren()
local worldCols = {}
for i = 1, 2 do
    worldCols[i] = New("Frame", { Parent = worldContent, Position = UDim2.new((i - 1) * .5, (i - 1) * 10, 0, 0), Size = UDim2.new(.5, -10, 0, 0),
        BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y })
    New("UIListLayout", { Parent = worldCols[i], Padding = UDim.new(0, 16), SortOrder = Enum.SortOrder.LayoutOrder })
end
local emotesContent = content:Clone(); emotesContent.Name = "EmotesContent"; emotesContent.Parent = win; emotesContent.Visible = false; emotesContent:ClearAllChildren()
local emotesCols = {}
for i = 1, 2 do
    emotesCols[i] = New("Frame", { Parent = emotesContent, Position = UDim2.new((i - 1) * .5, (i - 1) * 10, 0, 0), Size = UDim2.new(.5, -10, 0, 0),
        BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y })
    New("UIListLayout", { Parent = emotesCols[i], Padding = UDim.new(0, 16), SortOrder = Enum.SortOrder.LayoutOrder })
end
local miscContent = content:Clone(); miscContent.Name = "MiscContent"; miscContent.Parent = win; miscContent.Visible = false; miscContent:ClearAllChildren()
local miscCols = {}
for i = 1, 2 do
    miscCols[i] = New("Frame", { Parent = miscContent, Position = UDim2.new((i - 1) * .5, (i - 1) * 10, 0, 0), Size = UDim2.new(.5, -10, 0, 0),
        BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y })
    New("UIListLayout", { Parent = miscCols[i], Padding = UDim.new(0, 16), SortOrder = Enum.SortOrder.LayoutOrder })
end

local dashboard = New("Frame", { Parent = win, Position = content.Position, Size = content.Size, BackgroundTransparency = 1 })
local profile = New("Frame", { Parent = dashboard, Position = UDim2.fromOffset(0, 0), Size = UDim2.fromOffset(430, 168), BackgroundColor3 = C.panel, BackgroundTransparency = .25 })
corner(profile, 18); stroke(profile, C.border, .5)
local avatar = New("ImageLabel", { Parent = profile, Position = UDim2.fromOffset(22, 24), Size = UDim2.fromOffset(120, 120), BackgroundColor3 = C.surface })
corner(avatar, 20); stroke(avatar, C.border, .45)
task.spawn(function()
    local ok, img = pcall(function() return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size180x180) end)
    if ok then avatar.Image = img end
end)
text(profile, LocalPlayer.DisplayName, 24, UDim2.fromOffset(162, 32))
text(profile, "@" .. LocalPlayer.Name, 15, UDim2.fromOffset(163, 70), true)
local pill = New("Frame", { Parent = profile, Position = UDim2.fromOffset(162, 104), Size = UDim2.fromOffset(158, 30), BackgroundColor3 = C.accent, BackgroundTransparency = .8 })
corner(pill, 15); stroke(pill, C.accent, .35)
local pillDot = New("Frame", { Parent = pill, Position = UDim2.fromOffset(12, 11), Size = UDim2.fromOffset(8, 8), BackgroundColor3 = C.accent }); corner(pillDot, 4)
text(pill, "Connected", 13, UDim2.fromOffset(26, 7))
local heroCard = New("Frame", { Parent = dashboard, Position = UDim2.fromOffset(446, 0), Size = UDim2.new(1, -446, 0, 168), BackgroundColor3 = C.card, BackgroundTransparency = .15 })
corner(heroCard, 18); stroke(heroCard, C.border, .45)
New("UIGradient", { Parent = heroCard, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(23,28,25)), ColorSequenceKeypoint.new(1, Color3.fromRGB(10,12,14)) }), Rotation = 25 })
text(heroCard, "NOIR SILENT AIM", 26, UDim2.fromOffset(26, 24))
text(heroCard, "v4 \u{2022} gun & knife prediction, player and object ESP, presets", 14, UDim2.fromOffset(27, 62), true)
local statText = text(heroCard, "", 14, UDim2.fromOffset(27, 96), true)
local fpsCard = New("Frame", { Parent = dashboard, Position = UDim2.fromOffset(0, 184), Size = UDim2.fromOffset(286, 132), BackgroundColor3 = C.panel, BackgroundTransparency = .25 })
corner(fpsCard, 18); stroke(fpsCard, C.border, .5)
text(fpsCard, "FPS", 14, UDim2.fromOffset(22, 20), true)
local fpsText = text(fpsCard, "60", 42, UDim2.fromOffset(22, 50)); fpsText.TextColor3 = C.text
local pingCard = New("Frame", { Parent = dashboard, Position = UDim2.fromOffset(303, 184), Size = UDim2.fromOffset(286, 132), BackgroundColor3 = C.panel, BackgroundTransparency = .25 })
corner(pingCard, 18); stroke(pingCard, C.border, .5)
text(pingCard, "NETWORK LATENCY", 14, UDim2.fromOffset(22, 20), true)
local pingText = text(pingCard, "-- ms", 42, UDim2.fromOffset(22, 50)); pingText.TextColor3 = C.text
local playerCard = New("Frame", { Parent = dashboard, Position = UDim2.fromOffset(606, 184), Size = UDim2.fromOffset(286, 132), BackgroundColor3 = C.panel, BackgroundTransparency = .25 })
corner(playerCard, 18); stroke(playerCard, C.border, .5)
text(playerCard, "PLAYERS", 14, UDim2.fromOffset(22, 20), true)
local playerText = text(playerCard, "0", 42, UDim2.fromOffset(22, 50)); playerText.TextColor3 = C.text
local infoCard = New("Frame", { Parent = dashboard, Position = UDim2.fromOffset(0, 332), Size = UDim2.new(1, 0, 1, -348), BackgroundColor3 = C.panel, BackgroundTransparency = .3 })
corner(infoCard, 18); stroke(infoCard, C.border, .5)
text(infoCard, "QUICK START", 18, UDim2.fromOffset(24, 22))
text(infoCard, "Open Main for player tools, World for gun & fling tools, Visuals for ESP.", 14, UDim2.fromOffset(25, 54), true)
text(infoCard, "Settings are saved automatically to Noir Hub/configs.", 14, UDim2.fromOffset(25, 78), true)
local frameCounter, lastFps = 0, os.clock()
RunService.RenderStepped:Connect(function()
    frameCounter += 1
    local now = os.clock()
    if now - lastFps >= 1 then
        fpsText.Text = tostring(math.floor(frameCounter / (now - lastFps) + .5))
        frameCounter = 0; lastFps = now
        local ok, v = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
        pingText.Text = ok and (tostring(math.floor(v + .5)) .. " ms") or "-- ms"
        local pl = #Players:GetPlayers()
        playerText.Text = tostring(pl)
        statText.Text = "Loaded \u{2022} " .. tostring(pl) .. " players in server"
    end
end)

local activePage = "home"
local selectPage
do
    local pageObjects = { home = dashboard, main = mainContent, aim = content, world = worldContent, visual = visualContent, emotes = emotesContent, misc = miscContent }
    local pageBasePosition = content.Position
    local pageTransitionId = 0
    local function pageScaleFor(object)
        local scaler = object:FindFirstChild("NoirPageScale")
        if not scaler then scaler = New("UIScale", { Name = "NoirPageScale", Scale = 1, Parent = object }) end
        return scaler
    end
    function selectPage(page)
        if not pageObjects[page] then page = "home" end
        pageTransitionId += 1
        local transitionId = pageTransitionId
        local oldPage = activePage
        local oldObject = pageObjects[oldPage]
        local newObject = pageObjects[page]
        activePage = page

        for _, object in pairs(pageObjects) do
            if object ~= oldObject and object ~= newObject then
                object.Visible = false
                object.Position = pageBasePosition
                pageScaleFor(object).Scale = 1
            end
        end
        if oldObject and oldObject ~= newObject and oldObject.Visible then
            local oldScale = pageScaleFor(oldObject)
            oldObject.Position = pageBasePosition
            TweenService:Create(oldScale, TweenInfo.new(.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = .96 }):Play()
            task.delay(.18, function()
                if transitionId == pageTransitionId and oldObject ~= pageObjects[activePage] then
                    oldObject.Visible = false
                    oldObject.Position = pageBasePosition
                    oldScale.Scale = 1
                end
            end)
        end
        if newObject then
            local newScale = pageScaleFor(newObject)
            newObject.Position = pageBasePosition
            if newObject:IsA("ScrollingFrame") then
                newObject.CanvasPosition = Vector2.new(0, newObject.CanvasPosition.Y)
            end
            newScale.Scale = .94
            newObject.Visible = true
            TweenService:Create(newScale, TweenInfo.new(.62, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
        end
        configContent.Visible = false
        for name, b in pairs(navButtons) do
            local active = name == page
            TweenService:Create(b, TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { BackgroundColor3 = active and C.card or C.surface, BackgroundTransparency = active and 0 or 1 }):Play()
            local data = navIcons[name]
            if data then
                TweenService:Create(data.icon, TweenInfo.new(.2), { ImageColor3 = active and C.accent or C.dim }):Play()
                if data.glyphs then
                    for _, glyph in ipairs(data.glyphs) do TweenService:Create(glyph, TweenInfo.new(.2), { BackgroundColor3 = active and C.accent or C.dim }):Play() end
                end
                if data.rings then
                    for _, ring in ipairs(data.rings) do TweenService:Create(ring, TweenInfo.new(.2), { Color = active and C.accent or C.dim }):Play() end
                end
                TweenService:Create(data.label, TweenInfo.new(.2), { TextColor3 = active and C.text or C.dim }):Play()
                TweenService:Create(data.bar, TweenInfo.new(.2), { BackgroundTransparency = active and 0 or 1 }):Play()
            end
        end
    end
end
for name, b in pairs(navButtons) do b.MouseButton1Click:Connect(function() if activePage == name then selectPage("home") else selectPage(name) end end) end
selectPage("home")

local sectionCount, mainSectionCount, worldSectionCount, visualSectionCount, emotesSectionCount, miscSectionCount, configSectionCount = 0, 0, 0, 0, 0, 0, 0
local sectionPanels, controls = {}, {}
function refreshCanvas()
    task.defer(function()
        content.CanvasSize = UDim2.fromOffset(0, math.max(cols[1].AbsoluteSize.Y, cols[2].AbsoluteSize.Y) + 165)
        configContent.CanvasSize = UDim2.fromOffset(0, math.max(configCols[1].AbsoluteSize.Y, configCols[2].AbsoluteSize.Y) + 165)
        visualContent.CanvasSize = UDim2.fromOffset(0, math.max(visualCols[1].AbsoluteSize.Y, visualCols[2].AbsoluteSize.Y) + 165)
        mainContent.CanvasSize = UDim2.fromOffset(0, math.max(mainCols[1].AbsoluteSize.Y, mainCols[2].AbsoluteSize.Y) + 165)
        worldContent.CanvasSize = UDim2.fromOffset(0, math.max(worldCols[1].AbsoluteSize.Y, worldCols[2].AbsoluteSize.Y) + 130)
        miscContent.CanvasSize = UDim2.fromOffset(0, math.max(miscCols[1].AbsoluteSize.Y, miscCols[2].AbsoluteSize.Y) + 165)
        local embeddedEmotes = emotesContent:FindFirstChild("NoirEmotesNative") or emotesContent:FindFirstChild("NoirEmbeddedEmotesCanvas")
        if embeddedEmotes then
            emotesContent.CanvasSize = UDim2.fromOffset(0, embeddedEmotes.Position.Y.Offset + embeddedEmotes.Size.Y.Offset + 16)
        else
            emotesContent.CanvasSize = UDim2.fromOffset(0, math.max(emotesCols[1].AbsoluteSize.Y, emotesCols[2].AbsoluteSize.Y) + 165)
        end
    end)
end
search:GetPropertyChangedSignal("Text"):Connect(function()
    local q = string.lower(search.Text or "")
    local counts = { main = 0, aim = 0, world = 0, visual = 0, emotes = 0, misc = 0 }
    for _, entry in ipairs(sectionPanels) do
        local hay = entry.name
        for _, d in ipairs(entry.panel:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("TextButton") then hay = hay .. " " .. string.lower(d.Text or "") end
        end
        local match = q == "" or string.find(hay, q, 1, true) ~= nil
        entry.panel.Visible = match
        if match then counts[entry.page] = (counts[entry.page] or 0) + 1 end
    end
    if q ~= "" and activePage ~= "home" and (counts[activePage] or 0) == 0 then
        for _, page in ipairs({ "main", "aim", "world", "visual", "emotes", "misc" }) do if counts[page] > 0 then selectPage(page) break end end
    end
    refreshCanvas()
end)

local host = {}

local notificationHolder = New("Frame", {
    Parent = gui, Name = "NotificationRail", AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -20, 0, 82), Size = UDim2.new(0, 360, 0, 270),
    BackgroundTransparency = 1, ClipsDescendants = false, ZIndex = 1000,
})
local notificationLayout = New("UIListLayout", {
    Parent = notificationHolder, Padding = UDim.new(0, 9),
    FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Right,
    VerticalAlignment = Enum.VerticalAlignment.Top, SortOrder = Enum.SortOrder.LayoutOrder,
})
local notificationSerial = 0
local activeNotifications = {}
local function trimNotifications()
    while #activeNotifications > 3 do
        local oldest = table.remove(activeNotifications, 1)
        if oldest and oldest.Parent then oldest:Destroy() end
    end
end
function host.Notify(title, duration)
    notificationSerial += 1
    local life = math.max(1.5, tonumber(duration) or 3)
    local card = New("Frame", {
        Parent = notificationHolder, Name = "Toast_" .. tostring(notificationSerial),
        Size = UDim2.new(1, 0, 0, 76), BackgroundColor3 = C.panel,
        BackgroundTransparency = .04, BorderSizePixel = 0, LayoutOrder = notificationSerial,
        ZIndex = 1000,
    })
    corner(card, 14); stroke(card, C.accent, .18)
    New("Frame", { Parent = card, Position = UDim2.fromOffset(0, 13), Size = UDim2.fromOffset(3, 50),
        BackgroundColor3 = C.accent, BorderSizePixel = 0, ZIndex = 1001 })
    local badge = New("TextLabel", { Parent = card, Position = UDim2.fromOffset(18, 9), Size = UDim2.new(1, -30, 0, 17),
        BackgroundTransparency = 1, Text = "NOIR  •  NOTIFICATION", TextColor3 = C.accent2,
        TextSize = 10, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 1001 })
    local message = New("TextLabel", { Parent = card, Position = UDim2.fromOffset(18, 29), Size = UDim2.new(1, -30, 0, 30),
        BackgroundTransparency = 1, Text = tostring(title), TextColor3 = C.text,
        TextSize = 14, Font = Enum.Font.Gotham, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 1001 })
    local progress = New("Frame", { Parent = card, Position = UDim2.fromOffset(18, 69), Size = UDim2.new(1, -30, 0, 2),
        BackgroundColor3 = C.accent, BorderSizePixel = 0, ZIndex = 1001 })
    table.insert(activeNotifications, card); trimNotifications()
    TweenService:Create(progress, TweenInfo.new(life, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) }):Play()
    task.delay(life, function()
        for i = #activeNotifications, 1, -1 do
            if activeNotifications[i] == card then table.remove(activeNotifications, i) break end
        end
        if card.Parent then
            local out = TweenService:Create(card, TweenInfo.new(.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(1, 24, 0, 0), BackgroundTransparency = 1,
            })
            out:Play(); out.Completed:Connect(function() if card.Parent then card:Destroy() end end)
        end
    end)
end
function host.CreateTab()
    local tab = {}
    function tab:AddSection(name, description)
        local isVisual = name == "Visuals" or name == "Object ESP" or string.find(name, "VISUAL", 1, true) == 1
        local isMain = string.sub(name, 1, 5) == "MAIN "
        local isWorld = string.sub(name, 1, 6) == "WORLD "
        local isEmotes = string.sub(name, 1, 7) == "EMOTES "
        local isMisc = string.sub(name, 1, 5) == "MISC "
        local col, page = nil, "aim"
        if isVisual then visualSectionCount += 1; col = visualCols[(visualSectionCount - 1) % 2 + 1]; page = "visual"
        elseif isMain then mainSectionCount += 1; col = mainCols[(mainSectionCount - 1) % 2 + 1]; page = "main"
        elseif isWorld then worldSectionCount += 1; col = worldCols[(worldSectionCount - 1) % 2 + 1]; page = "world"
        elseif isEmotes then emotesSectionCount += 1; col = emotesCols[(emotesSectionCount - 1) % 2 + 1]; page = "emotes"
        elseif isMisc then miscSectionCount += 1; col = miscCols[(miscSectionCount - 1) % 2 + 1]; page = "misc"
        else sectionCount += 1; col = cols[(sectionCount - 1) % 2 + 1] end
        local panel = New("Frame", { Parent = col, Size = UDim2.new(1, 0, 0, 90), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = C.panel, BackgroundTransparency = .25, ClipsDescendants = true })
        corner(panel, 18); stroke(panel, C.border, .5)
        local tick = New("Frame", { Parent = panel, Position = UDim2.fromOffset(0, 16), Size = UDim2.fromOffset(3, 20), BackgroundColor3 = C.accent })
        corner(tick, 2)
        table.insert(sectionPanels, { panel = panel, page = page, name = string.lower(name .. " " .. (description or "")) })
        local shownName = name:gsub("^MAIN \u{2022} ", ""):gsub("^WORLD \u{2022} ", ""):gsub("^VISUAL \u{2022} ", ""):gsub("^EMOTES \u{2022} ", ""):gsub("^MISC \u{2022} ", "")
        text(panel, shownName, 18, UDim2.fromOffset(24, 16))
        if description and description ~= "" then text(panel, description, 12, UDim2.fromOffset(24, 44), true) end
        local holder = New("Frame", { Parent = panel, Position = UDim2.fromOffset(20, description ~= "" and 74 or 57), Size = UDim2.new(1, -40, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 })
        New("UIListLayout", { Parent = holder, Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder })
        New("UIPadding", { Parent = holder, PaddingBottom = UDim.new(0, 12) })
        holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(refreshCanvas); refreshCanvas()
        local api = { Name = name }
        local storagePrefix = name .. "::"
        local function row(label, h)
            local r = New("Frame", { Parent = holder, Size = UDim2.new(1, 0, 0, h or 62), BackgroundTransparency = 1 })
            text(r, label, 16, UDim2.fromOffset(0, 10))
            return r
        end
        function api:AddToggle(label, callback)
            local savedToggle = NoirPersistence.data.toggles[storagePrefix .. label]
            if savedToggle == nil and NoirPersistence.safeLegacy[label] then
                savedToggle = NoirPersistence.data.toggles[label]
                if savedToggle ~= nil then NoirPersistence.data.toggles[storagePrefix .. label] = savedToggle; NoirPersistence.Save() end
            end
            local state = savedToggle == true
            local r = row(label, 52)
            local pill = New("TextButton", { Parent = r, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 8), Size = UDim2.fromOffset(64, 34),
                BackgroundColor3 = C.off, Text = "", AutoButtonColor = false })
            corner(pill, 17); stroke(pill, C.border, .55)
            local dot = New("Frame", { Parent = pill, Position = UDim2.fromOffset(4, 4), Size = UDim2.fromOffset(26, 26), BackgroundColor3 = Color3.fromRGB(150,155,162) })
            corner(dot, 13)
            local function set(v, persist)
                state = v == true
                TweenService:Create(pill, TweenInfo.new(.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { BackgroundColor3 = state and C.accent or C.off }):Play()
                TweenService:Create(dot, TweenInfo.new(.34, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = state and UDim2.fromOffset(34, 4) or UDim2.fromOffset(4, 4), BackgroundColor3 = state and Color3.new(1, 1, 1) or Color3.fromRGB(150,155,162), Size = UDim2.fromOffset(30, 30) }):Play()
                task.delay(.20, function() if dot.Parent then TweenService:Create(dot, TweenInfo.new(.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(26, 26) }):Play() end end)
                callback(state)
                if persist ~= false then NoirPersistence.data.toggles[storagePrefix .. label] = state; NoirPersistence.Save() end
            end
            pill.MouseButton1Click:Connect(function() set(not state, true) end)
            set(state, false)
            return function(v) set(v == nil and not state or v, true) end
        end
        function api:AddButton(label, callback)
            local b = New("TextButton", { Parent = holder, Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = C.btn,
                Text = label, TextColor3 = C.text, TextSize = 15, Font = Enum.Font.Gotham, AutoButtonColor = false })
            corner(b, 12); stroke(b, C.border, .5)
            b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(.18), { BackgroundColor3 = Color3.fromRGB(48,52,56) }):Play() end)
            b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(.18), { BackgroundColor3 = C.btn }):Play() end)
            b.MouseButton1Click:Connect(callback)
            return b
        end
        function api:AddSlider(label, min, max, default, callback)
            local savedSlider = NoirPersistence.data.sliders[storagePrefix .. label]
            if savedSlider == nil then
                savedSlider = NoirPersistence.data.sliders[label]
                if savedSlider ~= nil then NoirPersistence.data.sliders[storagePrefix .. label] = savedSlider; NoirPersistence.Save() end
            end
            default = tonumber(savedSlider) or default
            local r = row(label, 68)
            local value = New("TextBox", { Parent = r, Position = UDim2.new(1, -72, 0, 5), Size = UDim2.fromOffset(72, 30), BackgroundColor3 = C.surface,
                BackgroundTransparency = .12, Text = tostring(default), TextColor3 = C.text, TextSize = 14, Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Center, ClearTextOnFocus = false })
            corner(value, 9); stroke(value, C.border, .4)
            local track = New("Frame", { Parent = r, Position = UDim2.new(0, 0, 1, -18), Size = UDim2.new(1, 0, 0, 6), BackgroundColor3 = C.off })
            corner(track, 3)
            local fill = New("Frame", { Parent = track, Size = UDim2.fromScale((default - min) / (max - min), 1), BackgroundColor3 = C.accent })
            corner(fill, 3)
            local knob = New("Frame", { Parent = track, AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new((default - min) / (max - min), 0, .5, 0), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = C.text })
            corner(knob, 7); stroke(knob, C.border, .3)
            local current = default
            local function set(v, persist)
                current = math.clamp(math.floor((tonumber(v) or current or default) + .5), min, max)
                fill.Size = UDim2.fromScale((current - min) / (max - min), 1)
                knob.Position = UDim2.new((current - min) / (max - min), 0, .5, 0)
                value.Text = tostring(current)
                callback(current)
                if persist ~= false then NoirPersistence.data.sliders[storagePrefix .. label] = current; NoirPersistence.Save() end
            end
            set(default, false)
            value.FocusLost:Connect(function() set(value.Text) end)
            local drag = false
            track.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
                    drag = true; set(min + (max - min) * math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1))
                end
            end)
            UIS.InputChanged:Connect(function(i)
                if drag and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
                    set(min + (max - min) * math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1))
                end
            end)
            UIS.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
            end)
            return { SetValue = function(_, v) set(v) end, GetValue = function() return current end }
        end
        function api:AddDropdown(label, values, callback)
            local r = row(label, 56)
            local idx = table.find(values, NoirPersistence.data.dropdowns[storagePrefix .. label]) or 1
            local b = New("TextButton", { Parent = r, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 4), Size = UDim2.fromOffset(190, 42),
                BackgroundColor3 = C.surface, Text = tostring(values[1] or "None") .. "  \u{2304}", TextColor3 = C.text, TextSize = 14, Font = Enum.Font.Gotham, ZIndex = 5 })
            corner(b, 10); stroke(b)
            local popup
            local function close() if popup then popup:Destroy(); popup = nil end end
            local function set(v)
                local found = table.find(values, v)
                if found then idx = found end
                b.Text = tostring(values[idx] or "None") .. "  \u{2304}"
                if values[idx] ~= nil then callback(values[idx]); NoirPersistence.data.dropdowns[storagePrefix .. label] = values[idx]; NoirPersistence.Save() end
            end
            local function open()
                close()
                popup = New("ScrollingFrame", { Parent = gui, Position = UDim2.fromOffset(b.AbsolutePosition.X / scale.Scale, (b.AbsolutePosition.Y + b.AbsoluteSize.Y + 4) / scale.Scale),
                    Size = UDim2.fromOffset(b.AbsoluteSize.X / scale.Scale, math.min(#values * 38, 190)), CanvasSize = UDim2.fromOffset(0, #values * 38),
                    BackgroundColor3 = C.surface, BorderSizePixel = 0, ScrollBarThickness = 4, ZIndex = 50 })
                corner(popup, 10); stroke(popup, C.accent, .2)
                New("UIListLayout", { Parent = popup, SortOrder = Enum.SortOrder.LayoutOrder })
                for _, v in ipairs(values) do
                    local item = New("TextButton", { Parent = popup, Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, Text = tostring(v),
                        TextColor3 = C.text, TextSize = 14, Font = Enum.Font.Gotham, ZIndex = 51 })
                    item.MouseButton1Click:Connect(function() set(v); close() end)
                end
            end
            b.MouseButton1Click:Connect(function() if popup then close() else open() end end)
            local ctl = {}
            function ctl:SetValue(v) set(v) end
            function ctl:Select(v) set(v) end
            function ctl:Refresh(newValues, selected) values = newValues or {}; idx = 1; set(selected or values[1]) end
            function ctl:ChangeItems(newValues) values = newValues or {}; idx = 1; set(values[1]) end
            return ctl
        end
        function api:AddTextBox(label, callback)
            local r = row(label, 64)
            local box = New("TextBox", { Parent = r, Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = C.surface,
                Text = "", PlaceholderText = label, TextColor3 = C.text, PlaceholderColor3 = C.dim, TextSize = 14, Font = Enum.Font.Gotham, ClearTextOnFocus = false })
            corner(box, 9); stroke(box)
            box.FocusLost:Connect(function() callback(box.Text) end)
            return { SetValue = function(_, v) box.Text = tostring(v) end }
        end
        function api:AddLabel(label)
            local r = row(label, 44)
            local labelObject = r:FindFirstChildWhichIsA("TextLabel")
            return { SetValue = function(_, value) if labelObject and labelObject.Parent then labelObject.Text = tostring(value) end end,
                GetValue = function() return labelObject and labelObject.Text or "" end,
                Instance = r }
        end
        function api:AddParagraph(title, body)
            local r = row(tostring(title or ""), 68)
            if body and tostring(body) ~= "" then
                local detail = text(r, tostring(body), 12, UDim2.fromOffset(0, 32), true)
                detail.TextWrapped = true
                detail.Size = UDim2.new(1, 0, 0, 30)
            end
            return r
        end
        function api:AddColorpicker(label, default, callback)
            local r = row(label, 52)
            local colorKey = storagePrefix .. label
            local colour = default or C.accent
            local savedColor = NoirPersistence.data.colors[colorKey]
            if typeof(savedColor) == "table" then
                local red, green, blue = tonumber(savedColor[1]), tonumber(savedColor[2]), tonumber(savedColor[3])
                if red and green and blue then colour = Color3.new(math.clamp(red, 0, 1), math.clamp(green, 0, 1), math.clamp(blue, 0, 1)) end
            end
            local swatch = New("TextButton", { Parent = r, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 8), Size = UDim2.fromOffset(112, 34),
                BackgroundColor3 = colour, Text = "EDIT COLOR", TextColor3 = C.text, TextSize = 11, Font = Enum.Font.GothamBold, AutoButtonColor = false })
            corner(swatch, 10); stroke(swatch)
            local popup, inputChanged, inputEnded, colorDirty = nil, nil, nil, false
            local function storeColor()
                NoirPersistence.data.colors[colorKey] = { colour.R, colour.G, colour.B }
            end
            local function commitColor()
                if colorDirty then colorDirty = false; NoirPersistence.Save() end
            end
            local function setColor(value, mode)
                if typeof(value) ~= "Color3" then return end
                colour = value
                swatch.BackgroundColor3 = colour
                if callback then callback(colour) end
                if mode == "defer" then
                    storeColor(); colorDirty = true
                elseif mode == true then
                    storeColor(); NoirPersistence.Save()
                end
            end
            local function closePicker()
                commitColor()
                if inputChanged then inputChanged:Disconnect(); inputChanged = nil end
                if inputEnded then inputEnded:Disconnect(); inputEnded = nil end
                if popup then popup:Destroy(); popup = nil end
            end
            local function openPicker()
                closePicker()
                local hue, saturation, value = colour:ToHSV()
                popup = New("Frame", { Parent = gui, Name = "NoirColorPicker", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0),
                    BackgroundTransparency = .42, BorderSizePixel = 0, Active = true, ZIndex = 70 })
                local dialog = New("Frame", { Parent = popup, AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(640, 450),
                    BackgroundColor3 = C.panel, BorderSizePixel = 0, Active = true, ZIndex = 71 })
                corner(dialog, 18); stroke(dialog, C.border, .18)
                New("TextLabel", { Parent = dialog, Position = UDim2.fromOffset(22, 17), Size = UDim2.fromOffset(250, 27), BackgroundTransparency = 1,
                    Text = label, TextColor3 = C.text, TextSize = 20, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 72 })
                New("TextLabel", { Parent = dialog, Position = UDim2.fromOffset(22, 43), Size = UDim2.fromOffset(370, 17), BackgroundTransparency = 1,
                    Text = "Choose with the color box, HEX, or RGB values", TextColor3 = C.dim, TextSize = 12, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 72 })
                local closeButton = New("TextButton", { Parent = dialog, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -17, 0, 15), Size = UDim2.fromOffset(38, 34),
                    BackgroundColor3 = C.surface, Text = "×", TextColor3 = C.text, TextSize = 24, Font = Enum.Font.GothamBold, AutoButtonColor = false, ZIndex = 73 })
                corner(closeButton, 10); stroke(closeButton, C.border, .45)
                local currentCard = New("Frame", { Parent = dialog, Position = UDim2.fromOffset(20, 80), Size = UDim2.fromOffset(220, 346), BackgroundColor3 = C.surface, BorderSizePixel = 0, ZIndex = 72 })
                corner(currentCard, 14); stroke(currentCard, C.border, .35)
                New("TextLabel", { Parent = currentCard, Position = UDim2.fromOffset(17, 16), Size = UDim2.fromOffset(170, 22), BackgroundTransparency = 1,
                    Text = "CURRENT COLOR", TextColor3 = C.text, TextSize = 14, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 73 })
                local preview = New("Frame", { Parent = currentCard, Position = UDim2.fromOffset(17, 49), Size = UDim2.fromOffset(186, 204), BackgroundColor3 = colour, BorderSizePixel = 0, ZIndex = 73 })
                corner(preview, 11); stroke(preview, C.border, .2)
                local previewHex = New("TextLabel", { Parent = preview, AnchorPoint = Vector2.new(.5, 1), Position = UDim2.new(.5, 0, 1, -14), Size = UDim2.fromOffset(118, 32),
                    BackgroundColor3 = Color3.fromRGB(24, 26, 30), BackgroundTransparency = .15, Text = "", TextColor3 = C.text, TextSize = 12, Font = Enum.Font.GothamBold, ZIndex = 74 })
                corner(previewHex, 8)
                New("TextLabel", { Parent = currentCard, Position = UDim2.fromOffset(17, 273), Size = UDim2.fromOffset(186, 18), BackgroundTransparency = 1,
                    Text = "LIVE PREVIEW", TextColor3 = C.dim, TextSize = 11, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 73 })
                New("TextLabel", { Parent = currentCard, Position = UDim2.fromOffset(17, 298), Size = UDim2.fromOffset(186, 27), BackgroundTransparency = 1,
                    Text = "The Shift Lock cursor updates instantly.", TextColor3 = C.dim, TextSize = 12, Font = Enum.Font.Gotham, TextWrapped = true, ZIndex = 73 })
                local valueCard = New("Frame", { Parent = dialog, Position = UDim2.fromOffset(258, 80), Size = UDim2.fromOffset(362, 346), BackgroundColor3 = C.surface, BorderSizePixel = 0, ZIndex = 72 })
                corner(valueCard, 14); stroke(valueCard, C.border, .35)
                New("TextLabel", { Parent = valueCard, Position = UDim2.fromOffset(17, 15), Size = UDim2.fromOffset(180, 22), BackgroundTransparency = 1,
                    Text = "COLOR VALUE", TextColor3 = C.text, TextSize = 14, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 73 })
                local hueReadout = New("TextLabel", { Parent = valueCard, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -17, 0, 16), Size = UDim2.fromOffset(82, 20), BackgroundTransparency = 1,
                    Text = "Hue 0°", TextColor3 = C.dim, TextSize = 12, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 73 })
                local spectrum = New("Frame", { Parent = valueCard, Position = UDim2.fromOffset(17, 48), Size = UDim2.fromOffset(328, 160),
                    BackgroundColor3 = Color3.fromHSV(hue, 1, 1), BorderSizePixel = 0, Active = true, ZIndex = 73 })
                corner(spectrum, 10); stroke(spectrum, C.border, .25)
                local whiteBlend = New("Frame", { Parent = spectrum, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 74 })
                corner(whiteBlend, 10)
                New("UIGradient", { Parent = whiteBlend, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }) })
                local darkBlend = New("Frame", { Parent = spectrum, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 75 })
                corner(darkBlend, 10)
                New("UIGradient", { Parent = darkBlend, Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }) })
                local spectrumKnob = New("Frame", { Parent = spectrum, AnchorPoint = Vector2.new(.5, .5), Size = UDim2.fromOffset(17, 17), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 76 })
                corner(spectrumKnob, 9); New("UIStroke", { Parent = spectrumKnob, Color = C.text, Thickness = 2 })
                -- Use explicit rainbow segments rather than a long UIGradient: this renders reliably in mobile executors.
                local hueBar = New("Frame", { Parent = valueCard, Position = UDim2.fromOffset(17, 223), Size = UDim2.fromOffset(328, 16), BackgroundTransparency = 1, BorderSizePixel = 0, Active = true, ZIndex = 73 })
                local rainbowTrack = New("Frame", { Parent = hueBar, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 73 })
                corner(rainbowTrack, 8); stroke(rainbowTrack, C.border, .25)
                local rainbow = {
                    Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 72, 0), Color3.fromRGB(255, 150, 0), Color3.fromRGB(255, 225, 0),
                    Color3.fromRGB(170, 255, 0), Color3.fromRGB(65, 255, 0), Color3.fromRGB(0, 255, 90), Color3.fromRGB(0, 255, 180),
                    Color3.fromRGB(0, 235, 255), Color3.fromRGB(0, 155, 255), Color3.fromRGB(0, 65, 255), Color3.fromRGB(75, 0, 255),
                    Color3.fromRGB(150, 0, 255), Color3.fromRGB(220, 0, 255), Color3.fromRGB(255, 0, 190), Color3.fromRGB(255, 0, 105),
                    Color3.fromRGB(255, 0, 42), Color3.fromRGB(255, 0, 0),
                }
                for index, rainbowColor in ipairs(rainbow) do
                    New("Frame", { Parent = rainbowTrack, Position = UDim2.new((index - 1) / #rainbow, 0, 0, 0), Size = UDim2.new(1 / #rainbow, 0, 1, 0),
                        BackgroundColor3 = rainbowColor, BorderSizePixel = 0, ZIndex = 74 })
                end
                local hueKnob = New("Frame", { Parent = hueBar, AnchorPoint = Vector2.new(.5, .5), Size = UDim2.fromOffset(11, 24), BackgroundColor3 = C.text, BorderSizePixel = 0, ZIndex = 76 })
                corner(hueKnob, 5); New("UIStroke", { Parent = hueKnob, Color = Color3.new(0, 0, 0), Thickness = 1 })
                New("TextLabel", { Parent = valueCard, Position = UDim2.fromOffset(17, 252), Size = UDim2.fromOffset(44, 16), BackgroundTransparency = 1, Text = "HEX", TextColor3 = C.dim, TextSize = 11, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 73 })
                local hexInput = New("TextBox", { Parent = valueCard, Position = UDim2.fromOffset(64, 246), Size = UDim2.fromOffset(281, 30), BackgroundColor3 = C.card, Text = "", PlaceholderText = "#FFFFFF", TextColor3 = C.text, TextSize = 13, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center, ClearTextOnFocus = false, ZIndex = 73 })
                corner(hexInput, 8); stroke(hexInput, C.border, .4)
                New("TextLabel", { Parent = valueCard, Position = UDim2.fromOffset(17, 287), Size = UDim2.fromOffset(120, 15), BackgroundTransparency = 1, Text = "RGB", TextColor3 = C.dim, TextSize = 11, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 73 })
                local channelInputs = {}
                local channelLabels = { "R", "G", "B" }
                local channelColors = { Color3.fromRGB(239, 72, 72), Color3.fromRGB(82, 204, 112), Color3.fromRGB(84, 150, 255) }
                for index = 1, 3 do
                    local x = 17 + (index - 1) * 110
                    New("TextLabel", { Parent = valueCard, Position = UDim2.fromOffset(x, 309), Size = UDim2.fromOffset(18, 22), BackgroundTransparency = 1, Text = channelLabels[index], TextColor3 = channelColors[index], TextSize = 13, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 73 })
                    local field = New("TextBox", { Parent = valueCard, Position = UDim2.fromOffset(x + 22, 303), Size = UDim2.fromOffset(86, 32), BackgroundColor3 = C.card, Text = "0", PlaceholderText = "0", TextColor3 = C.text, TextSize = 14, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center, ClearTextOnFocus = false, ZIndex = 73 })
                    corner(field, 8); stroke(field, channelColors[index], .5)
                    channelInputs[index] = field
                end
                local function setHSV(nextHue, nextSaturation, nextValue, mode)
                    hue = math.clamp(nextHue, 0, 1)
                    saturation = math.clamp(nextSaturation, 0, 1)
                    value = math.clamp(nextValue, 0, 1)
                    local selected = Color3.fromHSV(hue, saturation, value)
                    spectrum.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
                    spectrumKnob.Position = UDim2.fromScale(saturation, 1 - value)
                    hueKnob.Position = UDim2.fromScale(hue, .5)
                    preview.BackgroundColor3 = selected
                    local hex = string.format("#%02X%02X%02X", math.floor(selected.R * 255 + .5), math.floor(selected.G * 255 + .5), math.floor(selected.B * 255 + .5))
                    previewHex.Text = hex .. "  •  100%"
                    hexInput.Text = hex
                    channelInputs[1].Text = tostring(math.floor(selected.R * 255 + .5))
                    channelInputs[2].Text = tostring(math.floor(selected.G * 255 + .5))
                    channelInputs[3].Text = tostring(math.floor(selected.B * 255 + .5))
                    hueReadout.Text = "Hue " .. tostring(math.floor(hue * 360 + .5)) .. "°"
                    setColor(selected, mode)
                end
                local function setRGB(red, green, blue, mode)
                    local selected = Color3.fromRGB(math.clamp(math.floor((tonumber(red) or 0) + .5), 0, 255), math.clamp(math.floor((tonumber(green) or 0) + .5), 0, 255), math.clamp(math.floor((tonumber(blue) or 0) + .5), 0, 255))
                    local nextHue, nextSaturation, nextValue = selected:ToHSV()
                    setHSV(nextHue, nextSaturation, nextValue, mode)
                end
                local function updateSpectrum(position)
                    local size, origin = spectrum.AbsoluteSize, spectrum.AbsolutePosition
                    setHSV(hue, math.clamp((position.X - origin.X) / math.max(1, size.X), 0, 1), 1 - math.clamp((position.Y - origin.Y) / math.max(1, size.Y), 0, 1), "defer")
                end
                local function updateHue(position)
                    local size, origin = hueBar.AbsoluteSize, hueBar.AbsolutePosition
                    setHSV(math.clamp((position.X - origin.X) / math.max(1, size.X), 0, 1), saturation, value, "defer")
                end
                local dragMode = nil
                spectrum.InputBegan:Connect(function(input) if isPrimaryPress(input) then dragMode = "spectrum"; updateSpectrum(input.Position) end end)
                hueBar.InputBegan:Connect(function(input) if isPrimaryPress(input) then dragMode = "hue"; updateHue(input.Position) end end)
                hexInput.FocusLost:Connect(function()
                    local raw = tostring(hexInput.Text or ""):gsub("%s", ""):gsub("#", "")
                    local redHex, greenHex, blueHex = raw:match("^(%x%x)(%x%x)(%x%x)$")
                    if redHex and greenHex and blueHex then setRGB(tonumber(redHex, 16), tonumber(greenHex, 16), tonumber(blueHex, 16), true) else setHSV(hue, saturation, value, false) end
                end)
                for _, field in ipairs(channelInputs) do
                    field.FocusLost:Connect(function()
                        setRGB(tonumber(channelInputs[1].Text) or math.floor(colour.R * 255 + .5), tonumber(channelInputs[2].Text) or math.floor(colour.G * 255 + .5), tonumber(channelInputs[3].Text) or math.floor(colour.B * 255 + .5), true)
                    end)
                end
                inputChanged = UIS.InputChanged:Connect(function(input)
                    if dragMode and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
                        if dragMode == "spectrum" then updateSpectrum(input.Position) else updateHue(input.Position) end
                    end
                end)
                inputEnded = UIS.InputEnded:Connect(function(input)
                    if isPrimaryPress(input) then dragMode = nil; commitColor() end
                end)
                closeButton.Activated:Connect(closePicker)
                setHSV(hue, saturation, value, false)
            end
            swatch.Activated:Connect(openPicker)
            setColor(colour, false)
            return { SetRGBValue = function(_, value) setColor(value, true) end, GetValue = function() return colour end }
        end
        function api:AddKeybind(label, default, callback)
            local savedKey = NoirPersistence.data.keybinds[storagePrefix .. label] or default
            local r = row(label, 52)
            local btn = New("TextButton", { Parent = r, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 8), Size = UDim2.fromOffset(130, 34),
                BackgroundColor3 = C.surface, Text = tostring(savedKey), TextColor3 = C.text, TextSize = 14, Font = Enum.Font.Gotham, AutoButtonColor = false })
            corner(btn, 10); stroke(btn)
            local listening, currentKey, conn = false, savedKey, nil
            btn.MouseButton1Click:Connect(function()
                listening = true; btn.Text = "Press a key..."
                if conn then conn:Disconnect() end
                conn = UIS.InputBegan:Connect(function(input)
                    if not listening then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        currentKey = input.KeyCode.Name; btn.Text = currentKey; listening = false
                        NoirPersistence.data.keybinds[storagePrefix .. label] = currentKey; NoirPersistence.Save()
                        callback(currentKey); conn:Disconnect()
                    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                        currentKey = "MouseButton1"; btn.Text = currentKey; listening = false
                        NoirPersistence.data.keybinds[storagePrefix .. label] = currentKey; NoirPersistence.Save()
                        callback(currentKey); conn:Disconnect()
                    end
                end)
            end)
            return { SetValue = function(_, v) currentKey = v; btn.Text = tostring(v) end, GetValue = function() return currentKey end }
        end
        return api
    end
    return tab
end

local config = {
    enabled = false,
    targetMode = "Murderer",
    hitPart = "HumanoidRootPart",
    fovSize = 0,
    showFov = false,
    aimKey = "None",
    toggleKey = "None",
    autoFire = false,
    autoFireKey = "None",
    shotMethod = "Remote",
    wallCheck = false,
    piercerBullet = false,
    ignoreDead = true,
    ignoreFriends = false,
    maxDistance = 0,
    adaptive = true,
    fixedLead = 0.075,
    extraLead = 0.02,
    targetPart = "HumanoidRootPart",
    alignDirection = true,
    prioritizePing = true,
    predictJump = false,
    predictLag = true,
    maxSimulationMs = 180,
    predictionIntervalMs = 72,
    manualPingMs = 80,
    offsetX = 0, offsetY = 0, offsetZ = 0,
    horizontalMultiplier = 100, verticalMultiplier = 100,
    knifeAim = {
        adaptive = true,
        fixedLead = 0.075,
        extraLead = 0.02,
        prioritizePing = true,
        predictJump = false,
        predictLag = true,
        maxSimulationMs = 180,
        predictionIntervalMs = 72,
        manualPingMs = 80,
        offsetX = 0, offsetY = 0, offsetZ = 0,
        horizontalMultiplier = 100, verticalMultiplier = 100,
    },
    knifeEnabled = false,
    knifeWallCheck = false,
    knifePrioritizeSheriff = false,
    knifeAutoThrow = false,
    -- Preserve the prior always-on behavior while allowing the thrown-knife touch aura to be disabled independently.
    knifeThrownAura = true,
    knifeRadius = 15,
    showShootButton = false,
    lockShootButton = false,
    selectedPlayer = nil,
}

local murderer, sheriff, hero
local cachedPing = 0.05
local redirected = 0
local hooked = false
local running = true
local shootButton, shootGui, shootBusy = nil, nil, false
local buttonShotActive, buttonShotTarget = false, nil
local presetName = "default"
local PRESET_FOLDER = PRESETS_FOLDER
local revertControls, revertToggleStates, syncRevertControls = {}, {}, nil
local noirMirrorControls = {}
local presetDropdown
local motionPart, motionPosition, motionTime
local measuredVelocity = Vector3.zero
local motionSamples = {}
local previousEstimatedVelocity = Vector3.zero
local estimatedAcceleration = Vector3.zero
local lastAutoTune = 0
local roundTimerEndsAt, roundPendingStart
local roundState = "waiting"
local roundResetToken = 0
local lastRoundResetAt = os.clock()
local instantRoleDetection = false
local autoNotifyRoles = false
local announcedRoles = {}
local roleCache = {}
local playerData = {}
local aimHeld = true
local autoFireHeld = false

local cachedPlayers = {}
local function refreshPlayerCache() cachedPlayers = Players:GetPlayers() end
refreshPlayerCache()
local function getPlayers() return cachedPlayers end
Players.PlayerAdded:Connect(refreshPlayerCache)
Players.PlayerRemoving:Connect(refreshPlayerCache)

function notify(msg, time)
    if type(host.Notify) == "function" then pcall(host.Notify, "MM2 Silent Aim: " .. tostring(msg), time or 3) end
end
function validTarget(player)
    local character = player and player.Character
    local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
    return player ~= nil and player ~= LocalPlayer and character ~= nil and humanoid ~= nil and humanoid.Health > 0
end
function localCharacter() return LocalPlayer.Character end
local localHumCache, localHumChar
function localHumanoid()
    local c = LocalPlayer.Character
    -- A newly spawned character can exist a moment before its Humanoid. Never cache that nil result forever.
    if c ~= localHumChar or not localHumCache or not localHumCache.Parent then
        localHumChar = c
        localHumCache = c and c:FindFirstChildWhichIsA("Humanoid") or nil
    end
    return localHumCache
end
local localRootCache, localRootChar
function localRoot()
    local c = LocalPlayer.Character
    -- Same respawn-safe rule for the root part, used by movement and Infinite Jump helpers.
    if c ~= localRootChar or not localRootCache or not localRootCache.Parent then
        localRootChar = c
        localRootCache = c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso")) or nil
    end
    return localRootCache
end
function playerHasTool(player, toolName)
    local character = player and player.Character
    local backpack = player and player:FindFirstChildOfClass("Backpack")
    return (character and character:FindFirstChild(toolName)) or (backpack and backpack:FindFirstChild(toolName))
end
local friendCache = {}
Players.PlayerRemoving:Connect(function(p) friendCache[p] = nil end)
function isFriend(player)
    if not config.ignoreFriends or player == nil then return false end
    local cached = friendCache[player]
    if cached ~= nil then return cached end
    local ok, res = pcall(function() return player:IsFriendsWith(LocalPlayer.UserId) end)
    local value = (ok and res == true)
    friendCache[player] = value
    return value
end
function distanceTo(player)
    local root = localRoot()
    local t = player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if root and t then return (t.Position - root.Position).Magnitude end
    return math.huge
end

local function playerIsInLobby(player)
    if not player then return true end
    local teamName = player.Team and string.lower(tostring(player.Team.Name)) or ""
    if string.find(teamName, "lobby", 1, true)
        or string.find(teamName, "spectat", 1, true)
        or string.find(teamName, "observer", 1, true)
        or string.find(teamName, "waiting", 1, true) then
        return true
    end

    local containers = { player, player.Character }
    for _, container in ipairs(containers) do
        if container then
            for key, value in pairs(container:GetAttributes()) do
                local k = string.lower(tostring(key))
                if (string.find(k, "inround", 1, true) or string.find(k, "ingame", 1, true)
                    or string.find(k, "isplaying", 1, true) or string.find(k, "alive", 1, true))
                    and value == false then
                    return true
                end
                if string.find(k, "state", 1, true) or string.find(k, "status", 1, true)
                    or string.find(k, "location", 1, true) or string.find(k, "place", 1, true) then
                    local textValue = string.lower(tostring(value))
                    if string.find(textValue, "lobby", 1, true)
                        or string.find(textValue, "spectat", 1, true)
                        or string.find(textValue, "dead", 1, true)
                        or string.find(textValue, "waiting", 1, true) then
                        return true
                    end
                end
            end
            for _, name in ipairs({ "InLobby", "Spectating", "Dead", "IsDead" }) do
                local flag = container:FindFirstChild(name)
                if flag and flag:IsA("BoolValue") and flag.Value then return true end
            end
            for _, name in ipairs({ "InRound", "InGame", "IsPlaying", "Alive", "IsAlive" }) do
                local flag = container:FindFirstChild(name)
                if flag and flag:IsA("BoolValue") and not flag.Value then return true end
            end
        end
    end
    return false
end
function setTarget(player)
    if not validTarget(player) then player = nil end
    if murderer ~= player then
        murderer = player
        if player then notify("Target: " .. player.Name, 2) end
    end
end
function findByKnife()
    for _, player in ipairs(getPlayers()) do
        if player ~= LocalPlayer and playerHasTool(player, "Knife") then return player end
    end
end
function findByGun()
    for _, player in ipairs(getPlayers()) do
        if player ~= LocalPlayer and playerHasTool(player, "Gun") then return player end
    end
end
function consumeData(data)
    if typeof(data) ~= "table" then return false end
    local foundMurderer, foundSheriff, foundHero
    for _, player in ipairs(getPlayers()) do
        local info = data[player.Name] or data[tostring(player.UserId)]
        if typeof(info) == "table" then
            playerData[player.UserId] = info
            local role = info.Role or info.role or info.CurrentRole
            local normalized = string.lower(tostring(role or "innocent"))
            local resolved
            if normalized == "murderer" then resolved = "murderer"; foundMurderer = player
            elseif normalized == "sheriff" then resolved = "sheriff"; foundSheriff = player
            elseif normalized == "hero" then resolved = "hero"; foundHero = player
            else resolved = "innocent" end
            if roleCache[player.UserId] ~= resolved then
                roleCache[player.UserId] = resolved
                if autoNotifyRoles and resolved ~= "innocent" and announcedRoles[player.UserId] ~= resolved then
                    announcedRoles[player.UserId] = resolved
                    notify(player.Name .. " is " .. string.upper(resolved), 5)
                end
            end
        elseif typeof(info) == "string" then
            local normalized = string.lower(info)
            local resolved = normalized == "murderer" and "murderer" or normalized == "sheriff" and "sheriff" or normalized == "hero" and "hero" or "innocent"
            if normalized == "murderer" then foundMurderer = player
            elseif normalized == "sheriff" then foundSheriff = player
            elseif normalized == "hero" then foundHero = player end
            if roleCache[player.UserId] ~= resolved then roleCache[player.UserId] = resolved end
        end
    end
    sheriff = foundSheriff or sheriff
    hero = foundHero or hero
    if foundMurderer then
        setTarget(foundMurderer)
    end
    return foundMurderer ~= nil
end
local playerDataRemote
function getPlayerDataRemote()
    if playerDataRemote and playerDataRemote.Parent then return playerDataRemote end
    local remote = ReplicatedStorage:FindFirstChild("GetPlayerData", true)
    playerDataRemote = (remote and remote:IsA("RemoteFunction")) and remote or nil
    return playerDataRemote
end
function refreshTarget()
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
function updatePing()
    pcall(function()
        local network = Stats:FindFirstChild("Network")
        local items = network and network:FindFirstChild("ServerStatsItem")
        local pingItem = items and items:FindFirstChild("Data Ping")
        if pingItem then
            local measured = pingItem:GetValue() / 1000
            if measured > 0 and measured < 2 then cachedPing = cachedPing * 0.7 + measured * 0.3 end
        end
    end)
end

function getAimPart(player)
    local char = player and player.Character
    if not char then return nil end
    local partName = config.hitPart
    if partName == "Random" then
        local opts = { "Head", "UpperTorso", "LowerTorso", "HumanoidRootPart" }
        partName = opts[math.random(#opts)]
    end
    local part = char:FindFirstChild(partName)
    if not part then part = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart end
    return part
end
function inFOV(player)
    if config.fovSize <= 0 then return true end
    local cam = Workspace.CurrentCamera
    local part = getAimPart(player)
    if not cam or not part then return false end
    local screen = cam:WorldToViewportPoint(part.Position)
    local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    return (Vector2.new(screen.X, screen.Y) - center).Magnitude <= config.fovSize / 2
end
function passesFilters(player, trusted)
    if player == nil or player == LocalPlayer then return false end
    if not validTarget(player) then return false end
    if not trusted and playerIsInLobby(player) then return false end
    if isFriend(player) then return false end
    if config.maxDistance > 0 and distanceTo(player) > config.maxDistance then return false end
    return true
end
function selectTarget(mode)
    mode = mode or config.targetMode
    if mode == "Murderer" then return passesFilters(murderer, true) and murderer or nil end
    if mode == "Sheriff" then return passesFilters(sheriff, true) and sheriff or nil end
    if mode == "Hero" then return passesFilters(hero, true) and hero or nil end
    if mode == "Selected" then
        local p = config.selectedPlayer and Players:FindFirstChild(config.selectedPlayer)
        return passesFilters(p, true) and p or nil
    end
    if mode == "Nearest" then
        local best, bd
        for _, p in ipairs(getPlayers()) do
            if passesFilters(p) then local d = distanceTo(p); if not bd or d < bd then best, bd = p, d end end
        end
        return best
    end
    if mode == "Crosshair" then
        local cam = Workspace.CurrentCamera
        local best, bd
        if cam then
            local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
            for _, p in ipairs(getPlayers()) do
                if passesFilters(p) then
                    local part = getAimPart(p)
                    if part then
                        local screen = cam:WorldToViewportPoint(part.Position)
                        if screen.Z > 0 then
                            local d = (Vector2.new(screen.X, screen.Y) - center).Magnitude
                            if not bd or d < bd then best, bd = p, d end
                        end
                    end
                end
            end
        end
        return best
    end
    if mode == "Lowest Health" then
        local best, bh
        for _, p in ipairs(getPlayers()) do
            if passesFilters(p) then
                local hum = p.Character and p.Character:FindFirstChildWhichIsA("Humanoid")
                local h = hum and hum.Health or math.huge
                if not bh or h < bh then best, bh = p, h end
            end
        end
        return best
    end
    if mode == "Random" then
        local list = {}
        for _, p in ipairs(getPlayers()) do if passesFilters(p) then list[#list + 1] = p end end
        if #list > 0 then return list[math.random(#list)] end
        return nil
    end
    return passesFilters(murderer, true) and murderer or nil
end
function targetPart()
    local player = selectTarget()
    if not player then player = findByKnife() end
    local character = player and player.Character
    if not character then return nil end
    return getAimPart(player) or character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
end
function findNearestKnifeTarget()
    local root = localRoot()
    if not root then return nil end
    local closest, closestDistance
    for _, player in ipairs(getPlayers()) do
        if passesFilters(player) then
            local targetRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local d = (targetRoot.Position - root.Position).Magnitude
                if not closestDistance or d < closestDistance then closest, closestDistance = player, d end
            end
        end
    end
    return closest
end
function knifeTargetPlayer()
    if not config.knifeEnabled then return nil end
    if config.knifePrioritizeSheriff == true then
        local sheriffPlayer=findSheriff()
        return passesFilters(sheriffPlayer, true) and sheriffPlayer or nil
    end
    return findNearestKnifeTarget()
end
function knifeTargetPart()
    local player = knifeTargetPlayer()
    local character = player and player.Character
    if not character then return nil end
    return getAimPart(player) or character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
end

local PingProfiles = {
    { Ping = 20, Sim = 48, Interval = 70, H = 154, V = 144, X = -5, Y = -14, Z = 0 },
    { Ping = 50, Sim = 54, Interval = 66, H = 162, V = 152, X = -6, Y = -14, Z = 0 },
    { Ping = 100, Sim = 68, Interval = 60, H = 176, V = 166, X = -8, Y = -15, Z = 0 },
    { Ping = 150, Sim = 72, Interval = 64, H = 182, V = 170, X = -9, Y = -12, Z = 0 },
    { Ping = 200, Sim = 76, Interval = 70, H = 188, V = 174, X = -10, Y = -11, Z = 0 },
    { Ping = 300, Sim = 82, Interval = 76, H = 196, V = 180, X = -12, Y = -10, Z = 0 },
}
function interpolateProfile(ping)
    local a, b = PingProfiles[1], PingProfiles[1]
    if ping >= PingProfiles[#PingProfiles].Ping then
        a, b = PingProfiles[#PingProfiles], PingProfiles[#PingProfiles]
    else
        for index = 1, #PingProfiles - 1 do
            if ping >= PingProfiles[index].Ping and ping <= PingProfiles[index + 1].Ping then a, b = PingProfiles[index], PingProfiles[index + 1]; break end
        end
    end
    local span = b.Ping - a.Ping
    local alpha = span > 0 and math.clamp((ping - a.Ping) / span, 0, 1) or 0
    alpha = alpha * alpha * (3 - 2 * alpha)
    local function mix(key) return a[key] + (b[key] - a[key]) * alpha end
    return { Sim = math.floor(mix("Sim") + 0.5), Interval = math.floor(mix("Interval") + 0.5),
        H = math.floor(mix("H") + 0.5), V = math.floor(mix("V") + 0.5),
        X = math.floor(mix("X") + 0.5), Y = math.floor(mix("Y") + 0.5), Z = math.floor(mix("Z") + 0.5) }
end
local function syncAutoPing(settings, controlKey, pingMs)
    if not settings or not settings.prioritizePing then return end
    if settings.manualPingMs ~= pingMs then
        settings.manualPingMs = pingMs
        local control = revertControls[controlKey]
        if type(control) == "table" and type(control.SetValue) == "function" then pcall(control.SetValue, control, pingMs)
        elseif type(control) == "function" then pcall(control, pingMs) end
        local mirror = noirMirrorControls[controlKey]
        if type(mirror) == "table" and type(mirror.SetValue) == "function" then pcall(mirror.SetValue, mirror, pingMs)
        elseif type(mirror) == "function" then pcall(mirror, pingMs) end
    end
end
function autoTuneForPing()
    local now = os.clock()
    if now - lastAutoTune < 0.4 then return end
    lastAutoTune = now
    local pingMs = math.clamp(math.floor(cachedPing * 1000 + 0.5), 5, 1000)
    syncAutoPing(config, "manualPingMs", pingMs)
    syncAutoPing(config.knifeAim, "knifeManualPingMs", pingMs)
end
function leadTime(profile)
    local settings = profile == "knife" and config.knifeAim or config
    local prediction
    if settings.adaptive then
        local ping = settings.prioritizePing and cachedPing or (settings.manualPingMs / 1000)
        prediction = ping + settings.extraLead
        if settings.predictLag then
            local samplingDelay = math.clamp(settings.predictionIntervalMs / 2000, 0, 0.05)
            prediction = prediction + samplingDelay + math.max(0, ping - 0.10) * 0.15
        end
    else
        prediction = settings.fixedLead
    end
    return math.clamp(prediction, 0.02, settings.maxSimulationMs / 1000)
end
function sampleMotion(part, settings)
    settings = settings or config
    local now = os.clock()
    if motionPart ~= part then
        motionPart = part; motionSamples = {}; measuredVelocity = part.AssemblyLinearVelocity
        previousEstimatedVelocity = measuredVelocity; estimatedAcceleration = Vector3.zero
    end
    local last = motionSamples[#motionSamples]
    if not last or now - last.time >= math.max(0.016, settings.predictionIntervalMs / 1000) then
        motionSamples[#motionSamples + 1] = { position = part.Position, time = now }
        while #motionSamples > 8 or (#motionSamples > 2 and now - motionSamples[1].time > 0.35) do table.remove(motionSamples, 1) end
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
                    if acceleration.Magnitude < 120 then estimatedAcceleration = estimatedAcceleration:Lerp(acceleration, 0.25)
                    else estimatedAcceleration = Vector3.zero end
                    previousEstimatedVelocity = oldVelocity
                end
            end
        end
    end
    motionPosition = part.Position; motionTime = now
end
function calculateAim(part)
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
    local predictedVelocity = Vector3.new(velocity.X * horizontal, yVelocity, velocity.Z * horizontal)
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
    if displacement.Magnitude > 18 then displacement = displacement.Unit * 18 end
    local offset = Vector3.new(part.Size.X * config.offsetX / 100, part.Size.Y * config.offsetY / 100, part.Size.Z * config.offsetZ / 100)
    return part.Position + displacement + offset
end
function calculateKnifeAim(part, origin)
    local settings = config.knifeAim
    sampleMotion(part, settings)
    local assembly = part.AssemblyLinearVelocity
    local velocity = assembly
    if settings.predictLag and motionPart == part and #motionSamples >= 2 then velocity = assembly:Lerp(measuredVelocity, 0.65) end
    local horizontal = settings.horizontalMultiplier / 100
    local vertical = settings.verticalMultiplier / 100
    local predictedVelocity = Vector3.new(velocity.X * horizontal, settings.predictJump and velocity.Y * vertical or 0, velocity.Z * horizontal)
    local distance = (part.Position - origin).Magnitude
    local travelTime = math.clamp(distance / 125, 0, 0.55)
    local time = math.clamp(leadTime("knife") + travelTime, 0.03, 0.7)
    local offset = Vector3.new(part.Size.X * settings.offsetX / 100, part.Size.Y * settings.offsetY / 100, part.Size.Z * settings.offsetZ / 100)
    return part.Position + predictedVelocity * time + offset
end
local wallCheckParams = RaycastParams.new()
wallCheckParams.FilterType = Enum.RaycastFilterType.Exclude
wallCheckParams.IgnoreWater = true
function targetVisible(part, forceWallCheck)
    if not (forceWallCheck or config.wallCheck) then return true end
    local character = LocalPlayer.Character
    local originPart = character and (character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart"))
    if not originPart or not part then return false end
    wallCheckParams.FilterDescendantsInstances = { character }
    local result = Workspace:Raycast(originPart.Position, part.Position - originPart.Position, wallCheckParams)
    return result == nil or result.Instance:IsDescendantOf(part.Parent)
end

-- The ranged Gun and KnifeThrown remotes validate the outgoing ray. When a world part
-- is between the source and selected player, a Piercer toggle sends only that ray from
-- the target side of the obstruction; unobstructed shots retain the normal source.
local function piercerShotOrigin(origin, aim, part, enabled)
    if not enabled or not origin or not aim or not part then return origin end
    local direction = aim - origin
    if direction.Magnitude <= 0.01 then return origin end
    local character = LocalPlayer.Character
    wallCheckParams.FilterDescendantsInstances = character and { character } or {}
    local result = Workspace:Raycast(origin, direction, wallCheckParams)
    if not result or result.Instance:IsDescendantOf(part.Parent) then return origin end
    local spacing = math.clamp(part.Size.Magnitude * 0.75, 2.5, 4.5)
    return aim - direction.Unit * spacing
end

function knifeRemote(remote, args)
    if not config.knifeEnabled or args.n < 2 then return false end
    if typeof(remote) ~= "Instance" or not remote:IsA("RemoteEvent") then return false end
    if remote.Name ~= "KnifeThrown" then return false end
    if typeof(args[1]) ~= "CFrame" or typeof(args[2]) ~= "CFrame" then return false end
    local character = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    local knife = character and character:FindFirstChild("Knife")
    if knife and remote:IsDescendantOf(knife) then return true end
    if character and remote:IsDescendantOf(character) then return true end
    if backpack and remote:IsDescendantOf(backpack) then return true end
    return false
end
local function localGunTool()
    local character = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    return (character and character:FindFirstChild("Gun")) or (backpack and backpack:FindFirstChild("Gun"))
end
local function remoteBelongsToLocalGun(remote)
    local character=LocalPlayer.Character
    local backpack=LocalPlayer:FindFirstChildOfClass("Backpack")
    local tool=remote and remote:FindFirstAncestorOfClass("Tool")
    if tool and tool.Name=="Gun" and ((character and tool:IsDescendantOf(character)) or (backpack and tool:IsDescendantOf(backpack))) then return true end
    local characterGun=character and character:FindFirstChild("Gun")
    local backpackGun=backpack and backpack:FindFirstChild("Gun")
    return (characterGun and remote:IsDescendantOf(characterGun)) or (backpackGun and remote:IsDescendantOf(backpackGun))
end
function shotRemote(remote, args)
    if not (config.enabled or config.piercerBullet or buttonShotActive) or args.n < 2 then return false end
    if typeof(remote) ~= "Instance" or not remote:IsA("RemoteEvent") then return false end
    if not remoteBelongsToLocalGun(remote) then return false end
    local first, second = args[1], args[2]
    local firstIsPos = typeof(first) == "Vector3" or typeof(first) == "CFrame"
    local secondIsPos = typeof(second) == "Vector3" or typeof(second) == "CFrame"
    return firstIsPos and secondIsPos
end
local function fallbackGunOrigin()
    local gun = localGunTool()
    local handle = gun and gun:FindFirstChild("Handle", true)
    if handle and handle:IsA("BasePart") then return handle.Position end
    local character = LocalPlayer.Character
    local root = character and (character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart"))
    return root and root.Position or nil
end
local function vectorOrCFramePosition(value)
    if typeof(value) == "CFrame" then return value.Position end
    if typeof(value) == "Vector3" then return value end
    return nil
end
local function hasCFrameArgument(args)
    for index = 1, args.n do
        if typeof(args[index]) == "CFrame" then return true end
    end
    return false
end
function redirect(remote, args)
    local part, useWallCheck, isKnife = nil, false, false
    if shotRemote(remote, args) then
        if not buttonShotActive and config.aimKey ~= "None" and not aimHeld then return end
        if config.shotMethod == "CFrame" and not hasCFrameArgument(args) then return end
        part = (buttonShotActive and buttonShotTarget and getAimPart(buttonShotTarget)) or targetPart()
        -- Piercer Bullet keeps the gun redirect active and deliberately bypasses only the local gun wall gate.
        useWallCheck = config.wallCheck and not config.piercerBullet
    elseif knifeRemote(remote, args) then
        part = knifeTargetPart(); useWallCheck = config.knifeWallCheck; isKnife = true
    else
        return
    end
    if not part or typeof(part) ~= "Instance" or not part:IsA("BasePart") then return end
    if useWallCheck and not targetVisible(part, true) then return end

    if isKnife then
        local origin = args[1].Position
        local aim = calculateKnifeAim(part, origin)
        if config.alignDirection and (aim - origin).Magnitude > 0.01 then
            args[1] = CFrame.lookAt(origin, aim)
        end
        args[2] = CFrame.new(aim)
        redirected = redirected + 1
        return
    end

    local aim = calculateAim(part)
    local firstType, secondType = typeof(args[1]), typeof(args[2])
    if firstType == "CFrame" then
        local origin = args[1].Position
        local shotOrigin = piercerShotOrigin(origin, aim, part, config.piercerBullet)
        if (config.alignDirection or shotOrigin ~= origin) and (aim - shotOrigin).Magnitude > 0.01 then
            args[1] = CFrame.lookAt(shotOrigin, aim)
        end
        if secondType == "CFrame" then
            args[2] = CFrame.new(aim)
        elseif secondType == "Vector3" then
            args[2] = aim
        else
            return
        end
    elseif firstType == "Vector3" then
        local origin = args[1]
        local shotOrigin = piercerShotOrigin(origin, aim, part, config.piercerBullet)
        args[1] = shotOrigin
        if secondType == "Vector3" then
            if args[2].Magnitude <= 1.5 and (aim - shotOrigin).Magnitude > 0.01 then
                args[2] = (aim - shotOrigin).Unit
            else
                args[2] = aim
            end
        elseif secondType == "CFrame" then
            args[2] = CFrame.new(aim)
        else
            return
        end
    else
        return
    end
    redirected = redirected + 1
end

function installHook()
    if hooked then return true end
    local wrap = type(newcclosure) == "function" and newcclosure or function(callback) return callback end
    local isOwnCall = type(checkcaller) == "function" and checkcaller or function() return false end
    if type(hookmetamethod) == "function" and type(getnamecallmethod) == "function" then
        local old
        local ok, err = pcall(function()
            old = hookmetamethod(game, "__namecall", wrap(function(self, ...)
                local method = getnamecallmethod()
                if method == "FireServer" and typeof(self) == "Instance" and self.ClassName == "RemoteEvent" and not isOwnCall() then
                    local args = table.pack(...)
                    pcall(redirect, self, args)
                    if type(setnamecallmethod) == "function" then setnamecallmethod(method) end
                    return old(self, table.unpack(args, 1, args.n))
                end
                return old(self, ...)
            end))
        end)
        if ok and type(old) == "function" then
            hooked = true
            return true
        end
        notify("Namecall hook failed: " .. tostring(err), 5)
    end
    if type(hookfunction) ~= "function" then notify("No hook support in this executor", 6) return false end
    local probe = Instance.new("RemoteEvent")
    local original
    local ok, err = pcall(function()
        original = hookfunction(probe.FireServer, wrap(function(self, ...)
            local args = table.pack(...)
            if typeof(self) == "Instance" and self.ClassName == "RemoteEvent" and not isOwnCall() then pcall(redirect, self, args) end
            return original(self, table.unpack(args, 1, args.n))
        end))
    end)
    probe:Destroy()
    if not ok or type(original) ~= "function" then notify("Hook failed: " .. tostring(err), 6) return false end
    hooked = true
    return true
end
function toggle(value)
    config.enabled = value == true
    if config.enabled then
        if not installHook() then config.enabled = false return end
        task.spawn(refreshTarget)
        notify("Enabled", 2)
    else
        notify("Disabled", 2)
    end
end

function setPiercerBullet(value)
    config.piercerBullet = value == true
    if config.piercerBullet and not installHook() then
        config.piercerBullet = false
        notify("Piercer Bullet requires hook support", 4)
    end
end

do
    local CollectionService = game:GetService("CollectionService")
    local touch = type(firetouchinterest) == "function" and firetouchinterest or nil
    local active = {}
    local stepConnection

    local function ownKnifeTool()
        local character = LocalPlayer.Character
        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
        return (character and character:FindFirstChild("Knife")) or (backpack and backpack:FindFirstChild("Knife"))
    end

    local function knifePosition(knife)
        if not knife or not knife.Parent then return nil end
        local blade = knife:FindFirstChild("BladePosition")
        if blade and blade:IsA("BasePart") then return blade.Position end
        if blade and blade:IsA("Attachment") then return blade.WorldPosition end
        local visual = knife:FindFirstChild("KnifeVisual")
        if visual and visual:IsA("BasePart") then return visual.Position end
        if knife:IsA("BasePart") then return knife.Position end
        local part = knife:FindFirstChildWhichIsA("BasePart", true)
        if part then return part.Position end
        return nil
    end

    local function isOwnKnife(knife)
        local link = knife:FindFirstChild("HandleLink")
        local character = LocalPlayer.Character
        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
        if link and link:IsA("ObjectValue") and link.Value then
            if character and link.Value:IsDescendantOf(character) then return true end
            if backpack and link.Value:IsDescendantOf(backpack) then return true end
        end
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local position = knifePosition(knife)
        return root ~= nil and position ~= nil and ownKnifeTool() ~= nil and (position - root.Position).Magnitude <= 35
    end

    local function touchPair(first, second)
        if not touch or not first or not second then return end
        pcall(touch, first, second, true)
        task.defer(function()
            if first.Parent and second.Parent then pcall(touch, first, second, false) end
        end)
    end

    local function strike(knife, part)
        local tool = ownKnifeTool()
        local handle = tool and tool:FindFirstChild("Handle", true)
        local blade = knife:FindFirstChild("BladePosition")
        if not (blade and blade:IsA("BasePart")) then
            blade = knife:IsA("BasePart") and knife or knife:FindFirstChildWhichIsA("BasePart", true)
        end
        touchPair(blade, part)
        if handle and handle:IsA("BasePart") and handle ~= blade then touchPair(handle, part) end
        if not tool then return end
        local touched = tool:FindFirstChild("HandleTouched", true)
        if touched and touched:IsA("RemoteEvent") then pcall(touched.FireServer, touched, part) end
        local stabbed = tool:FindFirstChild("KnifeStabbed", true)
        if stabbed and stabbed:IsA("RemoteEvent") then pcall(stabbed.FireServer, stabbed) end
    end

    local function stopStep()
        if stepConnection then
            stepConnection:Disconnect()
            stepConnection = nil
        end
    end

    local function step()
        if not config.knifeEnabled or not config.knifeThrownAura or next(active) == nil then stopStep() return end
        local now = os.clock()
        local radius = config.knifeRadius
        for knife, data in pairs(active) do
            if not knife.Parent or now - data.started > 3.5 then
                active[knife] = nil
            else
                local position = knifePosition(knife)
                if position then
                    for _, player in ipairs(getPlayers()) do
                        local character = player ~= LocalPlayer and player.Character
                        local root = character and character:FindFirstChild("HumanoidRootPart")
                        if root and validTarget(player) and (root.Position - position).Magnitude <= radius and now - (data.hit[player] or 0) >= 0.08 then
                            data.hit[player] = now
                            strike(knife, root)
                        end
                    end
                end
            end
        end
        if next(active) == nil then stopStep() end
    end

    local function track(knife)
        if active[knife] or not config.knifeEnabled or not config.knifeThrownAura then return end
        local isKnife = knife.Name == "ThrowingKnife" or knife:HasTag("ThrowingKnife")
            or knife:FindFirstChild("HandleLink") ~= nil or knife:FindFirstChild("BladePosition") ~= nil
        if not isKnife then return end
        if not isOwnKnife(knife) then
            knife:WaitForChild("HandleLink", 0.1)
            if not isOwnKnife(knife) then return end
        end
        active[knife] = { started = os.clock(), hit = {} }
        if not stepConnection then stepConnection = RunService.Heartbeat:Connect(step) end
    end

    CollectionService:GetInstanceAddedSignal("ThrowingKnife"):Connect(function(knife) task.defer(track, knife) end)
    Workspace.ChildAdded:Connect(function(child)
        if child.Name == "ThrowingKnife" or child:HasTag("ThrowingKnife") then task.defer(track, child) end
    end)
end

function findGunRemote()
    local gun=localGunTool()
    if not gun then return nil end
    local best,bestScore
    for _,object in ipairs(gun:GetDescendants()) do
        if object:IsA("RemoteEvent") then
            local name=object.Name
            local score=#name
            if name=="Shoot" then score+=50 end
            if name=="GunFired" or name=="KnifeThrown" then score=-1 end
            if score>=(bestScore or 0) then best,bestScore=object,score end
        end
    end
    return best
end
function fireGunAt(player)
    if shootBusy then return false end
    shootBusy = true
    local success = false
    pcall(function()
        if not validTarget(player) then return end
        local part = getAimPart(player)
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
        if not part or not character or not humanoid then return end
        if config.wallCheck and not config.piercerBullet and not targetVisible(part) then return end
        local autoEquipped = false
        local gun = character:FindFirstChild("Gun")
        if not gun and backpack then
            gun = backpack:FindFirstChild("Gun")
            if gun then humanoid:EquipTool(gun); autoEquipped = true; task.wait(0.10) end
        end
        if not gun or not gun:IsA("Tool") then
            if autoEquipped and humanoid.Parent then humanoid:UnequipTools() end
            return
        end
        local remote=findGunRemote()
        local handle=gun:FindFirstChild("Handle",true)
        if not remote or not handle or not handle:IsA("BasePart") then
            if autoEquipped and humanoid.Parent then humanoid:UnequipTools() end
            return
        end
        local aim=calculateAim(part)
        local origin=handle.Position
        local shotOrigin=piercerShotOrigin(origin,aim,part,config.piercerBullet)
        buttonShotActive = true
        buttonShotTarget = player
        success=pcall(function() remote:FireServer(CFrame.lookAt(shotOrigin,aim),CFrame.new(aim)) end)
        task.wait(0.10)
        if autoEquipped and humanoid.Parent then
            task.wait(0.05)
            humanoid:UnequipTools()
        end
    end)
    buttonShotActive = false
    buttonShotTarget = nil
    shootBusy = false
    return success
end
function shootTarget()
    local player = selectTarget()
    if not player then refreshTarget(); player = selectTarget() end
    if player then return fireGunAt(player) end
    return false
end
task.spawn(function()
    while running do
        if config.autoFire and config.enabled and (config.autoFireKey == "None" or autoFireHeld) then
            local player = selectTarget()
            if player and inFOV(player) then
                local part = getAimPart(player)
                if part and (config.piercerBullet or not config.wallCheck or targetVisible(part)) then fireGunAt(player) end
            end
        end
        task.wait(0.03)
    end
end)

function removeShootButton()
    if shootGui then shootGui:Destroy(); shootGui = nil; shootButton = nil end
end
function createShootButton()
    if shootButton then return end
    local parent = CoreGui
    if type(gethui) == "function" then local ok, result = pcall(gethui); if ok and typeof(result) == "Instance" then parent = result end end
    if typeof(parent) ~= "Instance" then parent = LocalPlayer:WaitForChild("PlayerGui") end
    shootGui = Instance.new("ScreenGui")
    shootGui.Name = "MM2ShootMurdererButton"; shootGui.ResetOnSpawn = false; shootGui.IgnoreGuiInset = true
    shootGui.DisplayOrder = 80; shootGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; shootGui.Parent = parent
    local button = Instance.new("TextButton")
    button.Name = "ShootMurderer"
    button.AnchorPoint = Vector2.new(0.5, 0.5)
    button.Position = NoirPersistence.GetPosition("shoot_v2", UDim2.new(1, -132, 1, -124))
    button.Size = UDim2.new(0, 194, 0, 66)
    button.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
    button.BackgroundTransparency = 0.28
    button.BorderSizePixel = 0
    button.Text = "Shoot Murder"
    button.TextColor3 = Color3.fromRGB(245, 245, 248)
    button.TextSize = 17
    button.TextWrapped = true
    button.Font = Enum.Font.Gotham
    button.ClipsDescendants = false
    button.AutoButtonColor = false
    button.ZIndex = 5
    button.Parent = shootGui
    shootButton = button
    local corner2 = Instance.new("UICorner"); corner2.CornerRadius = UDim.new(0, 16); corner2.Parent = button
    local stroke2 = Instance.new("UIStroke")
    stroke2.Color = Color3.fromRGB(255, 255, 255); stroke2.Thickness = 2; stroke2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; stroke2.Parent = button
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 40)),
        ColorSequenceKeypoint.new(0.22, Color3.fromRGB(250, 250, 252)),
        ColorSequenceKeypoint.new(0.48, Color3.fromRGB(70, 70, 78)),
        ColorSequenceKeypoint.new(0.72, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(45, 45, 52)),
    })
    gradient.Parent = stroke2
    table.insert(gradientStrokes, gradient)
    local innerStroke = Instance.new("UIStroke")
    innerStroke.Color = Color3.fromRGB(105, 105, 112); innerStroke.Transparency = 0.5; innerStroke.Thickness = 1
    innerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; innerStroke.Parent = button
    local innerGradient = gradient:Clone(); innerGradient.Rotation = 180; innerGradient.Parent = innerStroke
    table.insert(gradientStrokes, innerGradient)
    local traceA = Instance.new("Frame"); traceA.AnchorPoint = Vector2.new(.5, .5); traceA.Position = UDim2.fromScale(0, .08)
    traceA.Size = UDim2.fromOffset(8, 8); traceA.BackgroundColor3 = Color3.new(1, 1, 1); traceA.BorderSizePixel = 0; traceA.ZIndex = 10; traceA.Parent = button
    local traceB = traceA:Clone(); traceB.Position = UDim2.fromScale(1, .92); traceB.Parent = button
    Instance.new("UICorner", traceA).CornerRadius = UDim.new(1, 0)
    Instance.new("UICorner", traceB).CornerRadius = UDim.new(1, 0)
    traceA.Visible = false; traceB.Visible = false
    local sound = Instance.new("Sound"); sound.Name = "Sound"; sound.SoundId = "rbxassetid://3868133279"; sound.Volume = 0.5; sound.Parent = button
    local normalSize = UDim2.new(0, 194, 0, 66)
    local pressedSize = UDim2.new(0, 206, 0, 72)
    local pressTween = TweenInfo.new(0.30, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local dragging, moved, dragStart, startPosition, dragInput = false, false, nil, nil, nil
    button.InputBegan:Connect(function(input)
        if isPrimaryPress(input) then
            dragging = not config.lockShootButton; moved = false; dragStart = input.Position; startPosition = button.Position
            TweenService:Create(button, pressTween, { Size = pressedSize, TextSize = 18, BackgroundColor3 = Color3.fromRGB(27,27,31) }):Play()
            button.Text = "T A R G E T   L O C K"
            traceA.Visible = true; traceB.Visible = true
            traceA.Position = UDim2.fromScale(0, .08); traceB.Position = UDim2.fromScale(1, .92)
            TweenService:Create(traceA, TweenInfo.new(.68, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = UDim2.fromScale(1, .08) }):Play()
            TweenService:Create(traceB, TweenInfo.new(.68, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = UDim2.fromScale(0, .92) }):Play()
            sound:Play()
        end
    end)
    button.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and input == dragInput and not config.lockShootButton then
            local delta = input.Position - dragStart
            if delta.Magnitude > 8 then moved = true end
            button.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X,
                startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if isPrimaryPress(input) then
            dragging = false
            NoirPersistence.SetPosition("shoot_v2", button.Position)
            TweenService:Create(button, TweenInfo.new(.62, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = normalSize, TextSize = 17, BackgroundColor3 = Color3.fromRGB(8,8,10), BackgroundTransparency = .28 }):Play()
            button.Text = "Shoot Murder"
            traceA.Visible = false; traceB.Visible = false
        end
    end)
    button.Activated:Connect(function() if not moved then task.spawn(shootTarget) end end)
end
function setShootButtonVisible(value)
    config.showShootButton = value == true
    if config.showShootButton then createShootButton() else removeShootButton() end
end

local fovCircle = New("Frame", { Parent = gui, AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5),
    BackgroundTransparency = 1, Size = UDim2.fromOffset(200, 200), Visible = false, ZIndex = 2 })
New("UICorner", { Parent = fovCircle, CornerRadius = UDim.new(.5, 0) })
local fovStroke = New("UIStroke", { Parent = fovCircle, Color = Color3.fromRGB(232,232,236), Thickness = 1.5, Transparency = .35 })
function updateFovCircle()
    fovCircle.Visible = false
end

local roundTimerGui
local function formatRoundTime(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    return string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
end
local function roundLengthFromEvent(value)
    local direct = tonumber(value)
    if direct and direct > 0 then return math.clamp(math.floor(direct + 0.5), 1, 600) end
    if typeof(value) == "table" then
        for _, key in ipairs({ "Time", "time", "Timer", "timer", "TimeLeft", "timeLeft", "Remaining", "remaining", "Seconds", "seconds", "Value", "value" }) do
            local nested = tonumber(value[key])
            if nested and nested > 0 then return math.clamp(math.floor(nested + 0.5), 1, 600) end
        end
    end
    return 180
end
local function resetRoundTimer()
    roundResetToken += 1
    roundState = "waiting"
    lastRoundResetAt = os.clock()
    roundTimerEndsAt = nil
    roundPendingStart = nil
    if roundTimerGui and roundTimerGui.Parent then roundTimerGui.Text = "WAITING" end
end
local function beginRoundTimer(roundLength)
    roundResetToken += 1
    roundState = "playing"
    roundPendingStart = nil
    roundLength = roundLengthFromEvent(roundLength)
    roundTimerEndsAt = os.clock() + roundLength
    if roundTimerGui and roundTimerGui.Parent then roundTimerGui.Text = formatRoundTime(roundLength) end
end
function setRoundTimerVisible(value)
    if not value then
        if roundTimerGui then roundTimerGui:Destroy(); roundTimerGui = nil end
        return
    end
    if roundTimerGui then return end
    roundTimerGui = Instance.new("TextLabel")
    roundTimerGui.Name = "NoirRoundTimer"
    roundTimerGui.Parent = gui
    roundTimerGui.AnchorPoint = Vector2.new(.5, 0)
    roundTimerGui.Position = UDim2.new(.5, 0, 0, 18)
    roundTimerGui.Size = UDim2.fromOffset(220, 50)
    roundTimerGui.BackgroundColor3 = C.panel
    roundTimerGui.BackgroundTransparency = .12
    roundTimerGui.TextColor3 = C.text
    roundTimerGui.Text = "WAITING"
    roundTimerGui.TextSize = 20
    roundTimerGui.Font = Enum.Font.GothamBold
    roundTimerGui.ZIndex = 900
    corner(roundTimerGui, 15); stroke(roundTimerGui, C.border, .15)
    local thisGui = roundTimerGui
    task.spawn(function()
        while roundTimerGui == thisGui and thisGui.Parent do
            if roundState == "playing" and roundTimerEndsAt then
                local left = math.ceil(roundTimerEndsAt - os.clock())
                if left > 0 then
                    thisGui.Text = formatRoundTime(left)
                else
                    resetRoundTimer()
                    thisGui.Text = "WAITING"
                end
            else
                thisGui.Text = "WAITING"
            end
            task.wait(.25)
        end
    end)
end

local utility = {
    walkEnabled = false, walkSpeed = 16, jumpEnabled = false, jumpPower = 50,
    antiAfk = false,
}

function applyCharacterMods()
    local humanoid = localHumanoid()
    if not humanoid then return end
    if utility.walkEnabled then humanoid.WalkSpeed = utility.walkSpeed end
    if utility.jumpEnabled then humanoid.UseJumpPower = true; humanoid.JumpPower = utility.jumpPower end
end
LocalPlayer.CharacterAdded:Connect(function(character)
    -- Apply immediately once the new rig is assembled, rather than relying on a stale pre-respawn Humanoid cache.
    localHumChar, localHumCache, localRootChar, localRootCache = nil, nil, nil, nil
    task.spawn(function()
        character:WaitForChild("Humanoid", 10)
        character:WaitForChild("HumanoidRootPart", 10)
        if LocalPlayer.Character == character then applyCharacterMods() end
    end)
end)
applyCharacterMods()

function findSheriff()
    if validTarget(sheriff) then return sheriff end
    return findByGun()
end

function showMurdererChance()
    local chance = ReplicatedStorage:FindFirstChild("GetChance", true)
    if chance and chance:IsA("RemoteFunction") then
        local ok, value = pcall(function() return chance:InvokeServer() end)
        notify(ok and ("Murderer chance: " .. tostring(value) .. "%") or "Chance unavailable", 4)
    else
        notify("GetChance remote not found", 4)
    end
end

do
    local virtualUser = game:GetService("VirtualUser")
    LocalPlayer.Idled:Connect(function()
        if not utility.antiAfk then return end
        pcall(function()
            virtualUser:CaptureController()
            virtualUser:ClickButton2(Vector2.new())
        end)
    end)
end

task.spawn(function()
    while running do
        if utility.walkEnabled or utility.jumpEnabled then applyCharacterMods() end
        task.wait(.15)
    end
end)

function cleanPresetName(name)
    name = tostring(name or "default"):gsub("%.preset$", ""):gsub("[^%w_%- ]", "_")
    return name ~= "" and name or "default"
end
function ensurePresetFolder()
    ensureStorageFolders()
end
function xorPreset(data)
    local output = table.create(#data)
    for index = 1, #data do
        output[index] = string.char(bit32.bxor(string.byte(data, index), 40))
    end
    return table.concat(output)
end
function exportRevertConfig()
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
        noir = {
            targetMode = config.targetMode, hitPart = config.hitPart, fovSize = config.fovSize,
            shotMethod = config.shotMethod, autoFire = config.autoFire, wallCheck = config.wallCheck, piercerBullet = config.piercerBullet, ignoreDead = config.ignoreDead,
            ignoreFriends = config.ignoreFriends, maxDistance = config.maxDistance,
            adaptive = config.adaptive, fixedLead = config.fixedLead, extraLead = config.extraLead,
            alignDirection = config.alignDirection,
            knifeWallCheck = config.knifeWallCheck,
            knifePrioritizeSheriff = config.knifePrioritizeSheriff, knifeAutoThrow = config.knifeAutoThrow,
            knifeThrownAura = config.knifeThrownAura,
            knifeAim = {
                adaptive = config.knifeAim.adaptive,
                fixedLead = config.knifeAim.fixedLead,
                extraLead = config.knifeAim.extraLead,
                prioritizePing = config.knifeAim.prioritizePing,
                predictJump = config.knifeAim.predictJump,
                predictLag = config.knifeAim.predictLag,
                maxSimulationMs = config.knifeAim.maxSimulationMs,
                predictionIntervalMs = config.knifeAim.predictionIntervalMs,
                manualPingMs = config.knifeAim.manualPingMs,
                offsetX = config.knifeAim.offsetX,
                offsetY = config.knifeAim.offsetY,
                offsetZ = config.knifeAim.offsetZ,
                horizontalMultiplier = config.knifeAim.horizontalMultiplier,
                verticalMultiplier = config.knifeAim.verticalMultiplier,
            },
        },
        author = LocalPlayer.Name,
        game = "Murder Mystery 2",
        category = "gun",
    }
end
function applyRevertConfig(data)
    if typeof(data) ~= "table" then return false end
    local cfg = data.cfg
    if typeof(cfg) == "table" then
        if typeof(cfg.predict_jump) == "boolean" then config.predictJump = cfg.predict_jump end
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
    end
    local noir = data.noir
    if typeof(noir) == "table" then
        for _, key in ipairs({ "targetMode", "hitPart" }) do
            if typeof(noir[key]) == "string" then config[key] = noir[key] end
        end
        if noir.shotMethod == "Remote" or noir.shotMethod == "CFrame" then
            config.shotMethod = noir.shotMethod
        end
        for _, key in ipairs({ "fovSize", "maxDistance", "fixedLead", "extraLead" }) do
            if typeof(noir[key]) == "number" then config[key] = noir[key] end
        end
        for _, key in ipairs({ "autoFire", "wallCheck", "piercerBullet", "ignoreDead", "ignoreFriends", "adaptive", "alignDirection",
                               "knifeWallCheck", "knifePrioritizeSheriff", "knifeAutoThrow", "knifeThrownAura" }) do
            if typeof(noir[key]) == "boolean" then config[key] = noir[key] end
        end
        if config.piercerBullet then task.defer(installHook) end
        local knifeAim = noir.knifeAim
        if typeof(knifeAim) == "table" then
            for _, key in ipairs({ "fixedLead", "extraLead", "maxSimulationMs", "predictionIntervalMs", "manualPingMs", "offsetX", "offsetY", "offsetZ", "horizontalMultiplier", "verticalMultiplier" }) do
                if typeof(knifeAim[key]) == "number" then config.knifeAim[key] = knifeAim[key] end
            end
            for _, key in ipairs({ "adaptive", "prioritizePing", "predictJump", "predictLag" }) do
                if typeof(knifeAim[key]) == "boolean" then config.knifeAim[key] = knifeAim[key] end
            end
        end
    end
    return true
end
local presetNames
function savePreset()
    if type(writefile) ~= "function" then notify("Executor does not support writefile", 4) return end
    ensurePresetFolder()
    local ok, encoded = pcall(function() return HttpService:JSONEncode(exportRevertConfig()) end)
    if ok then
        local wrote, err = pcall(writefile, PRESET_FOLDER .. "/" .. cleanPresetName(presetName) .. ".preset", xorPreset(encoded))
        if wrote then
            notify("Preset saved: " .. cleanPresetName(presetName), 3)
            if presetDropdown and presetDropdown.Refresh then presetDropdown:Refresh(presetNames(), cleanPresetName(presetName)) end
        else notify("Preset save failed: " .. tostring(err), 4) end
    else notify("Preset encode failed", 4) end
end
function loadPreset()
    if type(readfile) ~= "function" then notify("Executor does not support readfile", 4) return end
    local path = PRESET_FOLDER .. "/" .. cleanPresetName(presetName) .. ".preset"
    local ok, decoded = pcall(function()
        local raw = readfile(path)
        return HttpService:JSONDecode(xorPreset(raw))
    end)
    if ok and applyRevertConfig(decoded) then
        if type(syncRevertControls) == "function" then syncRevertControls() end
        notify("Preset loaded: " .. cleanPresetName(presetName), 3)
    else notify("Preset not found or invalid: " .. cleanPresetName(presetName), 4) end
end
presetNames = function()
    local names = { "default" }
    if type(listfiles) == "function" then
        ensurePresetFolder()
        local ok, files = pcall(listfiles, PRESET_FOLDER)
        if ok and typeof(files) == "table" then
            for _, file in ipairs(files) do
                local normalized = tostring(file):gsub("\\", "/")
                local name = normalized:match("([^/]+)%.preset$")
                if name and not table.find(names, name) then names[#names + 1] = name end
            end
        end
    end
    table.sort(names)
    return names
end

-- Fresh installs use the false state below; explicit user choices are restored from autosave.
local autoGGState = { enabled = false, token = 0 }
local gunUtilityState = {
    auraEnabled = false,
    auraRange = 25,
    droppedGunNotify = false,
    gunPickupNotify = false,
    bindEnabled = false,
    bindButtonSize = 0.11,
    touchNoticeAt = 0,
    bindGui = nil,
    bindButton = nil,
    bindConnections = {}
}

local function hasGunInInventory()
    return playerHasTool(LocalPlayer, "Gun") ~= nil
end

-- A dropped MM2 gun is not always a single part named GunDrop. Scan every GunDrop
-- container and rank the physical touch receiver before Handle/decorative fallbacks.
local function getDroppedGunParts()
    local candidates, seen = {}, {}
    local function add(part, priority)
        if not part or not part:IsA("BasePart") or seen[part] then return end
        seen[part] = true
        candidates[#candidates + 1] = { part = part, priority = priority }
    end
    local function scan(drop)
        if drop:IsA("BasePart") then
            local ownTouch = drop:FindFirstChildWhichIsA("TouchTransmitter")
            add(drop, ownTouch and 1 or (drop.Name == "Handle" and 2 or 3))
        end
        for _, child in ipairs(drop:GetDescendants()) do
            if child:IsA("TouchTransmitter") and child.Parent and child.Parent:IsA("BasePart") then
                add(child.Parent, 1)
            elseif child:IsA("BasePart") and child.Name == "Handle" then
                add(child, 2)
            elseif child:IsA("BasePart") and child.Name == "GunDrop" then
                add(child, 3)
            elseif child:IsA("BasePart") then
                add(child, 4)
            end
        end
    end
    -- Descendant scanning covers models, folders and reparented GunDrop instances.
    for _, instance in ipairs(Workspace:GetDescendants()) do
        if instance.Name == "GunDrop" then scan(instance) end
    end
    table.sort(candidates, function(a, b) return a.priority < b.priority end)
    local parts = table.create(#candidates)
    for index, candidate in ipairs(candidates) do parts[index] = candidate.part end
    return parts
end

local function getDroppedGunPart()
    return getDroppedGunParts()[1]
end

local function touchDroppedGun()
    local root = localRoot()
    local drops = getDroppedGunParts()
    if not root or #drops == 0 or type(firetouchinterest) ~= "function" then return false end
    local touched = false
    local ok = pcall(function()
        -- Do not move the player. Send three real begin/end touch pairs to every likely
        -- GunDrop hitbox, with a short yield between pulses for Delta/client touch handling.
        for attempt = 1, 3 do
            for _, drop in ipairs(drops) do
                if root.Parent and drop.Parent then
                    firetouchinterest(root, drop, 0)
                    task.wait(.035)
                    firetouchinterest(root, drop, 1)
                    task.wait(.045)
                    if hasGunInInventory() then touched = true; break end
                end
            end
            if touched then break end
            task.wait(.075)
        end
    end)
    return ok and (touched or hasGunInInventory())
end

local function grabDroppedGun()
    if hasGunInInventory() then return true end
    if gunUtilityState.pickupBusy then return false end
    gunUtilityState.pickupBusy = true
    local success = touchDroppedGun()
    -- Replication of a picked-up tool may arrive shortly after the touch connection fires.
    local deadline = os.clock() + .9
    while not success and os.clock() < deadline do
        task.wait(.06)
        success = hasGunInInventory()
    end
    gunUtilityState.pickupBusy = false
    return success
end

local function requestGrabGun()
    task.spawn(function()
        if hasGunInInventory() then
            notify("You already have the Gun", 3)
        elseif not getDroppedGunPart() then
            notify("No dropped Gun found", 3)
        elseif grabDroppedGun() then
            notify("Gun picked up", 3)
        else
            notify("Gun pickup failed", 3)
        end
    end)
end

local function setGunAura(enabled)
    gunUtilityState.auraEnabled = enabled == true
    gunUtilityState.auraToken = (gunUtilityState.auraToken or 0) + 1
    local token = gunUtilityState.auraToken
    if not gunUtilityState.auraEnabled then return end
    task.spawn(function()
        while running and gunUtilityState.auraEnabled and gunUtilityState.auraToken == token do
            if not hasGunInInventory() then
                local root, drop = localRoot(), getDroppedGunPart()
                if root and drop and not gunUtilityState.pickupBusy and (root.Position - drop.Position).Magnitude <= gunUtilityState.auraRange then
                    -- Aura uses the same verified pickup path as the Grab Gun button, not a one-shot touch pulse.
                    grabDroppedGun()
                end
            end
            task.wait(0.18)
        end
    end)
end

local function disconnectGrabGunBind()
    for _, connection in ipairs(gunUtilityState.bindConnections) do
        pcall(function() connection:Disconnect() end)
    end
    table.clear(gunUtilityState.bindConnections)
end

local function removeGrabGunBindButton()
    disconnectGrabGunBind()
    if gunUtilityState.bindGui then gunUtilityState.bindGui:Destroy() end
    gunUtilityState.bindGui, gunUtilityState.bindButton = nil, nil
    for _, parent in ipairs({guiParent, CoreGui, LocalPlayer:FindFirstChildOfClass("PlayerGui")}) do
        if typeof(parent) == "Instance" then
            local stale = parent:FindFirstChild("NoirGrabGunBindButton")
            if stale then stale:Destroy() end
        end
    end
end

local function updateGrabGunBindButtonSize()
    local button = gunUtilityState.bindButton
    local camera = Workspace.CurrentCamera
    if not button or not camera then return end
    local screen = camera.ViewportSize
    local heightScale = gunUtilityState.bindButtonSize
    button.Size = UDim2.new(heightScale * (screen.Y / math.max(screen.X, 1)), 0, heightScale, 0)
end

local function createGrabGunBindButton()
    if gunUtilityState.bindButton then return end
    removeGrabGunBindButton()
    local parent = guiParent
    if typeof(parent) ~= "Instance" then parent = LocalPlayer:WaitForChild("PlayerGui") end
    local bindGui = Instance.new("ScreenGui")
    bindGui.Name = "NoirGrabGunBindButton"
    bindGui.ResetOnSpawn = false
    bindGui.IgnoreGuiInset = true
    bindGui.DisplayOrder = 81
    bindGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    bindGui.Parent = parent

    local button = Instance.new("ImageButton")
    button.Name = "GrabGun"
    button.AnchorPoint = Vector2.new(.5, .5)
    button.Position = NoirPersistence.GetPosition("grab_gun_bind_v1", UDim2.new(.10, 0, .88, 0))
    button.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
    button.BackgroundTransparency = .28
    button.BorderSizePixel = 0
    button.Image = ""
    button.AutoButtonColor = false
    button.ClipsDescendants = false
    button.ZIndex = 5
    button.Parent = bindGui
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(1, 0)
    buttonCorner.Parent = button
    local aspect = Instance.new("UIAspectRatioConstraint")
    aspect.AspectRatio = 1
    aspect.AspectType = Enum.AspectType.ScaleWithParentSize
    aspect.Parent = button
    local outerStroke = Instance.new("UIStroke")
    outerStroke.Color = Color3.fromRGB(255, 255, 255)
    outerStroke.Thickness = 2
    outerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    outerStroke.Parent = button
    local outerGradient = Instance.new("UIGradient")
    outerGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 40)),
        ColorSequenceKeypoint.new(.22, Color3.fromRGB(250, 250, 252)),
        ColorSequenceKeypoint.new(.48, Color3.fromRGB(70, 70, 78)),
        ColorSequenceKeypoint.new(.72, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(45, 45, 52))
    })
    outerGradient.Parent = outerStroke
    local innerStroke = Instance.new("UIStroke")
    innerStroke.Color = Color3.fromRGB(105, 105, 112)
    innerStroke.Transparency = .5
    innerStroke.Thickness = 1
    innerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    innerStroke.Parent = button
    local innerGradient = outerGradient:Clone()
    innerGradient.Rotation = 180
    innerGradient.Parent = innerStroke
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Text"
    textLabel.AnchorPoint = Vector2.new(.5, .5)
    textLabel.Position = UDim2.fromScale(.5, .5)
    textLabel.Size = UDim2.fromScale(.76, .76)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "Grab Gun"
    textLabel.TextColor3 = Color3.fromRGB(245, 245, 248)
    textLabel.TextSize = 17
    textLabel.TextWrapped = true
    textLabel.Font = Enum.Font.Gotham
    textLabel.ZIndex = 6
    textLabel.Parent = button

    local dragging, moved, dragStart, startPosition, dragInput = false, false, nil, nil, nil
    gunUtilityState.bindConnections[#gunUtilityState.bindConnections + 1] = button.InputBegan:Connect(function(input)
        if not isPrimaryPress(input) then return end
        dragging, moved = true, false
        dragStart, startPosition = input.Position, button.Position
    end)
    gunUtilityState.bindConnections[#gunUtilityState.bindConnections + 1] = button.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    gunUtilityState.bindConnections[#gunUtilityState.bindConnections + 1] = UIS.InputChanged:Connect(function(input)
        if not dragging or input ~= dragInput then return end
        local delta = input.Position - dragStart
        if delta.Magnitude > 7 then moved = true end
        button.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X,
            startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
    end)
    gunUtilityState.bindConnections[#gunUtilityState.bindConnections + 1] = UIS.InputEnded:Connect(function(input)
        if not dragging or not isPrimaryPress(input) then return end
        dragging = false
        NoirPersistence.SetPosition("grab_gun_bind_v1", button.Position)
    end)
    gunUtilityState.bindConnections[#gunUtilityState.bindConnections + 1] = button.Activated:Connect(function()
        if not moved then requestGrabGun() end
    end)
    gunUtilityState.bindConnections[#gunUtilityState.bindConnections + 1] = RunService.RenderStepped:Connect(function()
        if outerGradient.Parent then outerGradient.Rotation = (outerGradient.Rotation + 1) % 360 end
    end)
    gunUtilityState.bindGui, gunUtilityState.bindButton = bindGui, button
    updateGrabGunBindButtonSize()
end

local function setGrabGunBindButton(enabled)
    gunUtilityState.bindEnabled = enabled == true
    if gunUtilityState.bindEnabled then createGrabGunBindButton() else removeGrabGunBindButton() end
end

removeGrabGunBindButton()

task.spawn(function()
    local previousDrop, previouslyHadGun = nil, hasGunInInventory()
    while running do
        local drop = getDroppedGunPart()
        if drop ~= previousDrop then
            if drop and gunUtilityState.droppedGunNotify then
                notify("Dropped Gun detected", 4)
            end
            previousDrop = drop
        end
        local hasGun = hasGunInInventory()
        if hasGun and not previouslyHadGun and gunUtilityState.gunPickupNotify then
            notify("Gun picked up", 3)
        end
        previouslyHadGun = hasGun
        task.wait(.25)
    end
end)

local function setAutoGG(enabled)
    autoGGState.enabled = enabled == true
    autoGGState.token += 1
    local token = autoGGState.token
    if not autoGGState.enabled then return end
    task.spawn(function()
        while running and autoGGState.enabled and autoGGState.token == token do
            if LocalPlayer.Character and not hasGunInInventory() and getDroppedGunPart() then
                grabDroppedGun()
            end
            task.wait(0.5)
        end
    end)
end

local tab = host.CreateTab()

-- Misc cursor controls replace the image inside Roblox's existing Shift Lock/crosshair ImageLabel.
-- The target lookup happens only on enable/spawn; color dragging updates the cached target instead of rescanning CoreGui.
do
    local cursorState = { enabled = false, colorEnabled = false, template = "Default", customId = "", color = C.accent, artworkScale = 1.35, originalMouseIcon = nil, originalVisuals = {} }
    cursorState.templates = {
        "Default", "Gothic Spear", "Gothic Wings", "Shadow Sigil",
        "Dark Seraph", "Thorn Gun", "Crimson Halo", "Radiant Halo", "Moonblade", "Void Slash", "Script Blade", "Light Seraph", "Infinity", "Azure Glow", "Pink Spark",
        "Custom",
    }
    cursorState.templateImages = {
        ["Gothic Spear"] = "rbxassetid://77559278786615",
        ["Gothic Wings"] = "rbxassetid://73847458193538",
        ["Shadow Sigil"] = "rbxassetid://130499812243487",
    }
    -- Supplied artwork is written once to Noir Hub/assets and loaded through Delta's getcustomasset.
    cursorState.bundles = {
        ["Dark Seraph"] = { file = "noir_cursor_01_dark_seraph.png", data = [=[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]=] },
        ["Thorn Gun"] = { file = "noir_cursor_02_thorn_gun.png", data = [=[iVBORw0KGgoAAAANSUhEUgAAAKAAAACgCAYAAACLz2ctAABFFUlEQVR42u29eXxU9b3///6cdfZkMpPJOtnZskBIWMIaUBYFQVyCItjitWrdWkvRb6+3GqJUa723tmK1oBZRREysUkFAWcMihCwQIEA2si+zZPbtzFk+vz+cyS9StLTqvbY9z8djHgyT5MxZXue9fd6fzwGQkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGR+TcByadARhbmvzikfAr+GowxmZCQEPvJJ5+EriI+LJ+hbw/iX1xIf5e1KisrIwEAHn744ZsGBgZGAwCUl5cTI7aF77333rjo731L+4H+3v38txVg9GJ8V66orq6OHvm+paWFvUIAf5+vRGjYWm3cuJEuLy/XRbaDAACVlpZS0dfI4xkcHNRfunSpCwBQRUUFBgACIYQXLVo0nef5x5cuXWo6dOgQVVlZSV7rfnzN/uOR+ykL8GvOY0VFhfSzn/1MGT1x37K1InQ6HfHaa6+N2rhxo6q4uFgAAFi3bh2BMaYQQnikQP8WlZWV5KZNmzI3btxIY4yVNpttAsuyJQBAlZeXIwDA1dXVQvQ18nhEUewJBoMlkc9IjDG6ePGiVq1WL/vhD3+4/cYbb4xNTEwcV1BQkFNfX5/8xhtvaEecSyr6uv/++1Xl5eW6P/3pT0UIIRyxnFEhoo0bN9KVlZWJb7/9dv5VbnA5oB5p+SoqKqQbb7zxRgAoUSqVDq1Wu2XLli0eAJC+LVcZsRTUnj17SJqmNbm5uWjHjh1Kn8/3k/Hjx78RCAT89fX1iQzDjFOr1R8eOHBA2Lt3rxjZjAAAqLi4mJo+fTqxYcMG/o033rhRoVB0I4R6aZrmS0pKxLS0tFBdXR31pz/9Kbmzs3M5z/OC3+/vz8zMPPLuu+8OAACBMaYXLlz43G233fbW/fff7zx9+nSS0+nUv/rqqz9+88033+vr61MolcpwbGxsUK/XOwHAAgADCCHvFcfFWK3WtM8++yzXZrOdX7NmzeWRseTu3bvjRVFk/H6/8Y477riIEAp/n8VSXl5OXLhwAVVVVUFpaSkymUy4qqpK+ibGCF2jlZSWLVs2zePxzJ41a9aLVqt1jNPpdGzfvt3ybQXmGGP61VdfHccwjEKSpPMtLS2/ysjICCsUCuvQ0BCXn59fm5aW5i4oKOgFgABC6EvCP3TokILjuNT29vYxDz/88CcY4xgACCGEuEOHDhnnzp1r//zzz5XHjh1LfuKJJ9rLyspm7tu376jP5wONRgO33npr0Ztvvtl4+fLl1KysLPWHH35YtGXLlrvXrFnzYVFRESCElDNmzHhiwoQJzY8//nj9xYsXtQMDA5zdbqe6u7tpr9dr+cUvfvHnhx9+eI7P50tlWVZF03QiQRBDa9asuYwQ6hk9evQhnU7nq6+v9y1fvlx87bXXRhkMhoG0tLTYvr6+cHd3tyE7O7tLq9WG586dK3wPjRX+G55U+k4EiDHGixcv/i+9Xv/yu+++6/k2D+jnP/+52mAw3D579uwPjxw5kmAymfLj4+Mb29raZmi1Wj1CaEilUvEURaGampp7Ojo6zvT39w+Gw2EiHA6THMeJDMMQb7311q5169aVsSzr7+rqMgNAyYIFC349ZswYOjU19RzHcYLX6+V7e3uJlJSU0Msvv3xvXV1dhSAIAsuy1N13333vz372s87u7u7RAKA3Go1MW1vbqA0bNlw/bty4zry8PPHs2bOmt956a1xqamrI6/Uq/H4/iKIIGGOgKApiYmJCHo9HwfM8IISGP3/wwQeffPTRRz9/+OGHf5uamvrq5s2b38QYk9u3b5+uVCrDGGNLcnJyqLa2tqiqquqz6upq8XuWbSMAwLfccstkr9c7qaWlxVNcXGwKBoOdWq32XFVVVRsAQGlpKfX37ju6li9etGhRoiRJq/bu3fvfZWVlZMTsfuM4EGNMbNu2Laanp2fMsmXL2g4ePEjodLoEtVrtcjqd0wmCSI6LizvZ29s7DgBSfv7znz/FcRxNkiRgjAFjHA3ywWw2X7RareMwxhAKhUCSJFAoFGGj0UgKgsBLkiRIkoQwxoAQQoFAQBUIBKLHgLRaLWZZNiiKIgEAIEkSOXny5IF58+YFnnzyybFKpRKee+65S5WVlYnHjx+PHXHseMR7EgCGLwBBEJIkSdTixYsPGI1G2LJly3yj0Wirr68vPH36tNblcsWEw2FNWlramY6OjpIHH3xw96effpq5cOHCDowxulpycujQIcXhw4fDEVcoftehWVlZGVFVVSUtXbp0jiiKS0iS3Nbf3+/Izs5OcTgcCQAwDmOsp2l62549e+q+kyQkFArF2Ww264gdw9/SHYpzcnKI//f//t/5gYEBlyAI12OMY1UqFRUTE3MpFAp1CYIgmkym5sHBQZAkyS5JksjzPC8IgiCKoiCKoiAIgtDR0THO7/dLgUBAlCRJRAhJoVCI6e3tJQcHBxVWq1Vjt9vVQ0NDarvdrgoEAoBQNPRE4PV6kd1uVzmdToXT6VS43W56//79aTt37kx69NFHLX6/H/7whz9k3H333e6YmBgMAIgkSRTJkEmEEEkQBCa+gIq8SIIgkCAIJr1en5WSkhLOzc0919LSMgtjrAmHwxmxsbE2URRTCIKwnT59OqWpqWnm5s2bY0eID0VLNRhjEgCgoqJCioqvvLyc+DsqBGhk3B19XcUQRa8vjnwP1mg0XRMnTnz9448/rqurq7v8/vvvH923b98H+/btezYpKel3Pp/vvtmzZ7/84IMPjgMA4loTqmuygLNnzx43NDQ0uamp6e0Rd/k3Dmjz8vJQZ2fno0aj8WJhYWGD3+9XCoLg6erqMgiCUBoMBiemp6dXXLp06TaM8YWnnnpqC8/zGVHhRKwZRCwWRKzOsGXEX7z5kiW58mJFXWVubq5YVFTEHT16lO3u7iYwxkitVkspKSnC4sWLvQ6Hg96yZYtu5syZweXLlwd/8Ytf6AOBACJJEkTx60/H4sWLL993331bBgcH0wsKCv544sSJpWaz+UIgEKDmzJmzr6ura5RGozk7MDCgWbJkSd9f/vKXhIaGBn9NTQ2/d+9eLlpGGjduXGxcXJz7ueeeSwoEAmPWr19/OD8/PzyinnjV71+3bh26cOECVVVVFf5bBXgAIO12O8txHENRFCWKIksQBJGYmCiGQiGyu7tbiRAKMwwjuVwu2u1281ardXx/f7/rxRdfPDx+/Pif7t69++VIJUD4tlxwOkJo5SeffPJcxAWL31R8FRUV0htvvHGbKIqa+++//4OXXnqpEADi4uLiuliWTWlvb78RIdT05JNPfnz69GnTmjVrSo8dO/Z7Qbj6MSUkJITsdjsliiIV/YymaSgsLAzW1dUpIycYNBqNcP311/t9Pp/i6NGjTDgcRqmpqfDCCy+ICQkJ8OSTT6JTp04RKpUKP/PMM76CggJpYGBAMJlMeNOmTeo9e/YobrjhhtC8efPCL730kvry5cuU0WgEgiAElmUliqJ4tVqNYmJikFarDRAEEZg6depQcnLyGYVCEaQoytDU1JTAMEwwPT29oaamZtr48eP/dMcdd+x69913xxAEYUMISQRBpKrVahPDMJ8lJyejmTNnejs6OhS1tbVST0+P5sCBAy8VFhb+gef5xNjY2LZwONxSUVFx1ZPz+9//nu3p6bnD4XDU/OlPf2ru6OhQaDQa2ul0KiiKUgGAAiGkFARBFQ6HVSRJ0pIkKTHGtCiKNEmSSBAEQpIkkaIoniRJnmGYkMvl0vA8z1gsltScnJzuRx999KehUEiaM2fOfc8///z5a0lQqb/lIgEAxowZYz158mTSoUOHqG8jO6uoqMBlZWVkQkLCWYvFErN169ZUAODUajXS6/Wqvr4+89ixY/cODg5qioqKHpEkaU4gEMiKi4ur0Wg0eoqizBhjhud5QqlU8hRFkf/xH//hu3jxoookSa62tlbZ3t5OzJgxQzQYDHRtbS1ELdUNN9wQXr16NREMBon58+djSZKQ2WyGgYEB8te//jWcO3cOCIIASZLA4/GwFEURRqNR4DgOPfDAA/yKFSsCe/bsYS5evAhPPvlkaPv27YzJZII77rjDFQ6HKYqighzHIUEQfHq93qlQKLyfffaZORgMTnU6nUIoFGL9fn/YbDYPcBw3z2w2k/n5+daTJ09ORQiF+vr6fvbTn/705fj4+Jb169dnPvHEEzlut9v/1FNPzV69evWnL7zwgrm1tXUqy7LczJkzfa2traGf/OQnHgCARx55JLm9vd03MDBAGI1G5Pf70YwZMyiNRiM88MAD8SUlJVN/97vfGTs7O00+n08jiqJaEAQtACgkSVJJksSIoshgjGmMMRPxHqIkSZiiKA4AOJIkQyRJ+kOhkN/hcMSQJMmmpaX5PR7PKLVazWo0GvGTTz55E2N8F0KoM5IZ429chpkwYUKVRqNZf/z48bORv5P+wcQDIYTwli1b5mVkZDS3tLToVSqV76677urcv39/ht1uT6RpmvV6vTFVVVXPZGZmdpaWlv5u2rRpOBgMpvT398/2eDwTg8Fgps1m04iiKCgUCqanp4dOSUmRMMYgCALR0NAANpsNt7W1oebmZogmLg888ABMnjwZgsEgNDU1gdvtBqvVCkeOHAGO44CiKJAkCTDGEBcXB8uWLQuPHTuW0Ov1BEEQeHBwUCooKCB7e3vFlpYWacqUKXxra6vQ19dHIoRUSUlJvnHjxrkvXbqkMZvNnY2NjeaWlhaF3+/36nQ60efzmUOhEKSkpFxOT09XKZVK+7Rp0zYqFArlpEmTLlmtVn7z5s2zduzYcUdfX1/2qFGjTt12222vTZw4scBut18+d+5cfnd399Tp06efKCkpuXTq1KnRJ06cYPPy8lrHjx8fnjJlSofRaMSCIJAURRENDQ2xr7zyyqLMzEzNLbfccsbhcJhFUdSJoqjFGCtEUVSKoshijKlITEgghMRIeMKTJMkpFAqO4zg/RVE+giD8JEn6DQaDR6fTSS+//PISh8MxdPvtt5977bXXZiYnJ/PvvPPOhEceeWTLb37zm/uWL18ufV2t8FoESAGAkJ+f/xsAQOfPn3/8Wv37V7n0lStXJqnV6utTUlI6MjIyAjzPK8xm89kFCxYwFRUVLwuCsC8pKWmwp6cnYcqUKaGhoSH9xIkTqYGBgdn9/f2TVCqVYWBgQBfJhAkAgGAwCA6HA1JTU0EQBDh06BDYbDbo6+sDu90+vAMLFizAkyZNgrfeeguNGzcODAYDNDU1QSgUAowxXL58+Us7TNM0zJ49G0iSxIIg4JycHDRz5kzEMAwwDCMGAgFBEISQWq0OnDp1SpWQkEBaLJZgTU2NZnBwkExMTAwlJiayBoOBcLlcNMMwYb1ejxsaGti0tLShOXPmeEiSDHq93nB3d/e5AwcOXHf69OmUER4IqVQqmDRpUoPZbNbyPK+YOXNmQ05Ojmf//v1Zb775Zrbb7U4kSRK0Wm04Pj7ekZmZOTh69OjBy5cvG3p6ejKWLFkSXLZs2WBvb2+SIAixoigqJEmiUCSApigKEEKAEAKCIKLvMU3TAsdxQavVyuXm5roQQm6NRuN0uVzCL37xi2JRFIP9/f1Gh8PBGo1GnyAIVCgUklwul7agoODQ2bNnH+/s7LyQmZkZ+octYDRemz59+qS+vr5PXnzxxezly5cH8BemDP8jsd+NN974RGJi4oWCggK3wWDoEkURZ2dnQ3d3t8pkMvUeOXLkp+np6S0nTpzInzBhAhkfHz8qMTGRHRgYyDtz5kyG0WgkGxsbiZSUFHC5XBAIBGBoaAhCoRBoNBpob2+Hjo4O4DgOTCYTROtykydPFmtqagiGYeDee+9FOTk5wDAMeDweePzxxwEA4Oabb4bk5GTwer1w5swZaGxshJkzZ8KCBQsgJSUFlEolCIIAJEkCy7LAcZzQ39+PtFptOBAIhDdv3szU1dUpNRoN3H///eLYsWP5YDBIuVwuac+ePXRKSgpSqVS4p6cHKRQKmD59erCzs1O02WxMfHw8qVarwWQyud966y1dR0cH9UV+JREmkwnuvvtuT0lJiaW+vj7e4/HghIQEcDgc1NmzZ6G5uZmxWq1sNEbW6/Uwd+7c0IoVKzwJCQmwd+/euMLCQiqauLW2toLf74fs7Gxst9uH65mSJIEoiijiduHy5cv8J598wqxevdotCAIniiJfU1OjrKmpifs6RxcTEyM8//zzPyVJcuDo0aP7tm7d6v+Hh+KibjglJaVVqVTuaGtr+0etIAIAfOONNz67e/fupwGAvHTpkrK2tlapUCgIi8Uyq7i4+MBbb711e1tbW47JZLru/vvvP3H69Ok7lUql32g0xp8/f14ZDodRX18fvP/++xAOf3ViN378eFi+fDk4nU7YtGkTxMfH487OTlRaWirdeeediKZpbLFYiC1btkBnZyc8/vjjUFBQAD6fDxQKBVAUBTt27IBt27YBwzBQUlICRUVFoNFogOd5iJZyCgoKcCgUEl9//XXi7NmzRFZWFl65ciXU1NSg+Ph4YBgGWltbweFwQHx8PBAEAYFAACRJgnA4DCzLQk5ODpjNZt7n85EAALW1tchut6Pu7m5ITEyE4uJiLiYmhmppaQGPx4PGjh0bNhqNEsY4HA6H0dDQENHV1cW0t7czoVAIT548mc/Ozua9Xq8iEAhQNTU1kJ+fjymKAoIgUEdHB8yZMwfGjx8PTz31FPA8PyzAaxIEQeBoYndlsoExBrVaDc8+++zdeXl5PZ2dnY0PPPCA+x9JQr4kQL1ev66/v3/r8uXLt1ZWVjaWl5cr1q1bx12rJSwtLSWrq6sFnud9CxYsmDJ9+vRas9mcrFAoEg4dOnTutddeq1q4cOGTJSUlxNixY7tee+21CY2NjaH4+HjB4/GkHTx4UDp79iwghCAzMxPi4uJgcHAQCIIYPnCMMZhMJvjBD34AWVlZcPDgQdi3bx/4fD7wer0IACApKSkUFxdHnDhxgtywYQMhiiI8/fTT4by8PMbv9wNBEHDs2DE4ceIEkCQJDMNAOByGI0eOwJEjR4aPJycnB7RaLbz33nuI53mKoiiIi4uD4uJi5Pf74bPPPruyKwYuXrwIGOPhRCfq5k+dOgUAQF9xkQFjDH19fdDb28uO/NmFCxcUkbeqq3TfoJqaGrampuZLf3Py5MkvGRyn0wkEQUAoFBrev5H/XrnvI0UmSRL6GmMmEQRB2O32tIULF75bWVnJ/KNZ8HCDCACgc+fOVRoMhmcOHTr08dDQ0GKVShU4c+aMNDAwYEtKSvL/rY3MmTNHqq6uBkmSDgWDwVUVFRU1a9asCWRkZFhfffVVV0tLy09Ylo3LyMjwZWZmFtxyyy1nXn755RlGo5HLycnBjY2NxIULFxAAgE6ng9GjR4PFYhlOMGiahlmzZsENN9wAPp8PNmzYABcvXhy+mFlZWcJDDz0ULCoq4v/4xz8qP/jgAyohIQF+/OMfu6dNm8Z4PB6xp6cHffbZZ8TRo0e/dPJJkhwWy/jx4yEhIQHOnj0LDocDbDYbAACUlJSAKIpgt9shPT0dFAoFhMPhkXXJ4TgrKkIAAEEQht+PFMDIOmf0+6MJUsQCoUg71/DNF61zRmO5aC1UkqTh76UoCouiiPx+P6jValAoFDgcDgNC6EsWcETNFF9ZsB65j1cIVcIYE0VFRTVr1649t2jRojEzZ85s/qYCjPbE8StWrHh++/btr0+fPv3tEydOrMvOznY1NTXpPv300/aFCxcGAACVlZUhq9WKTCYTBgCoqqqKll8gNzeXmTVrVt2uXbvWXHfddXN/+9vfHsIYx+bm5m40mUxp27Zte/ns2bOzrVbrhAULFqgFQeBqa2vZHTt2gCRJw1lqc3PzcNzC8zwAAJhMJjCZTLB7926orq4GnueHLQ1FUfj666/3cxxHPfbYY5rGxkZm7Nix4WXLlvlcLhc5NDTk+fzzz3UbN25UcBwHBEEMXzBRFEEURWAYBrKzs8HtdkMgEIDu7m7AGAPLskBRFNA0DSaTCfbv3z8srJEXNLovIwU50m19HSO3gxACURTR14VRI7aHoqKXJAlomgae5xEAYEEQkFar5QVBoP+G60XR8xG9ETiO+yuXPNIdt7S0jK2trRUXLFjQ/XX1wGtu8sQYo/r6+qzi4uKM6667bv2hQ4dKcnNzO37zm9+8unjx4hMAcBkhNHCt23vttddGvfPOO781GAyHa2tr16akpHR8/PHHGzo7Owt8Pt+EYDA4wWKxJNjtdkhLS6M2btwIZ86cGY6d8vLyoLu7G0KhEMyYMQN0Oh20t7dDU1PTl76HYRhM0zSiKAqHQiF05YlLTEwUXC4XRVGU5PP5iJGuL3oRjUYj5Ofng9PpBEEQ4OLFi8OCQAiBUqmEzMxMEEURxo8fD52dnVBfXw8kSYJCoQCGYYDjOPB6vaDVaiE2NhYkSQKGYcDr9UJMTAwoFAro6+sDtVoNer0eYmNjh4VnMBgAYwxutxvX1taiUCgEOTk5PEmSwPM8uXz5ch/HcYQgCIQoinDw4EFFXl6efc6cOQ6O48IIIWVcXJzy3XffNej1epyZmRl48cUXjdddd53rP//zP607duwgXS6XSa1WByL7pNDr9U5JkpgDBw7o77zzTqtGowkKgkBijA0IIfb1119XWCwWgud5FAqFrhwNksxms/2xxx57aM2aNR9e6b7/IQF2dXUlBwKBSV6vdyJCKP2RRx5ZUFNTk2IwGIKTJ0/el5+fvzccDp/q7u4mVSqVDmOs8fl8RGSMVQoEAsAwjEKr1cYaDAaTzWZLb2lpWe71etXjx4+/2NjYuL69vX2S1Wqd4Pf7cwRBSOjp6WEJgoD29nZ49dVXwe12D9/Jo0aNAo1GA7NmzYKkpCQ4ceIEHD58GAKBwLBLMxgM8NBDD/EZGRnk3r174ejRo9Df30/MmzdPyMnJ8XEcF/z444/jh4aGqCtjH4wxFBYWSrfeeivS6XS4ubmZ+POf/wxWq3W4ZDFShLNmzYLGxkZQKBQQFxcHbrcbSJKEwsJCIEkSNBoN7Nu3D4qLi8FoNIJCoQCbzQYcx4HZbIaUlBQ4ceIEsCwL119/PXg8HoiPjweWZYEkSex2uyWv18u/8cYbiq6uLigvLw/GxMQMWiwWRUxMDBUbG+tJSkpyI4Rwf38/8DxvysvL6w+Hw1ipVLoBgHU4HKQkSeG8vDxu5cqVU0mS9GzZsuWI1+tFBEHQbW1tyS0tLQW5ubn9SqXSevbs2VS73a5dunTpMZqmaZfLpbdYLBk0TWt9Pp+aYRjc09NDSJIUPH78OBYEQWpra0NdXV361atX/8/mzZvLEULBr6sZX4sLRhhjdX9/f4HD4ZgRDAbzBUFI+vWvfz302muvsZWVlca9e/cuPXDgwFKSJKUvDAgxLJSomxyZYUXfK5VKIT09vae5uTlrypQpz0+dOtUfHx+voSgqMRgM0v39/bi1tRVqa2tRpOMFent7AQBArVbD6tWrob+/H1544QVwuVzDO6xUKoGiKHjmmWek1NRUavfu3fDRRx8hlUoFP/jBD8SbbrrJZbFYQn/84x8NbrebvDKJAQBYsWKFsGrVKtzQ0EBu2rSJuHDhAkRrZqIo/tXY86VLlyAjIwN6enogPT19ONkYNWoU0DQNsbGxoFAosNlsBo7jEM/zEAwGIScnBzQajRgOh9HNN98MHMdJCQkJksfjCQcCATryM4/D4dC6XC40YcKEAEEQbEZGRq9CobCnp6fjQCAQliSJBQC/3+8nTCaT0+v19vf09GCTyeQaHBzUWK1WNGHChGaCIASGYYamTZuGz5w5k5GYmHgq0shBnDlzZjTHcd6BgQExJSVlKCcnp3HatGkOjuMoSZJUNE0nGI1GRpIktUqlio00YJAqlSpw8803t/7hD39I7+zsTFCr1eFbb711DwDwEfF9pQum/kbNDgBAmj179pttbW0zRFGMu+eee8LTpk1T8jxPjBo1KpCVlSUODg5CIBBAPM8TIzspvsqbI4QwQgjp9XopKSkJO51Osra2Nq23txeMRqMUKRVgmqbB6/WiUCgEjzzyCAwMDEBPTw9Ek5Dz58/Dxx9/DC6Xazg2WbJkCSxcuBC2b98OW7duJeLj42HHjh1QVFQE9957rzB69OjA4cOHiV/96lepV8ZmJEkCRVFwxx13cNdff72wb98+uqamRrxw4cJwhnDlWHRUiFarFYaGhkCpVMLevXshPj4elErlcIE7WuymaRoPDAyIGGNpxYoVnv7+fjXDMF61Wi0KghCOj49HoigG8vLyBJ/PR2GMvQgh1fjx48/rdLpgRUXF9ZmZmaHs7OxLJ0+e1MXFxdlomlZ0dnaSc+bMaT5//ny+wWDgMzMzL3McB52dnRlqtdqTmpp6FiHkYVl20Gg0+rRaraDVasf19vbyarX6sEKhoBYuXFgXGxtrdbvdjFarRb29vdnx8fHnSZLEHMcxwWAwhyAIHgAYnuc1Pp8vPi0tzc5xnKjT6ZrOnz9vbG9v10+bNm3LkiVLqkc0Df/jQ3EY46TCwsL9jY2NuQCAf/jDH6Jbb70VPB4P/Pa3vwWFQhGsr69XRi4MvtpY8sjvigz3AACAwWCApKQku8FgEOvq6uIxxjBmzBiIiYkBhBBYrVbU1NSEbrzxRrj77rvhiSeegN7eXkAIAU3Tw0H+iEQD0tLSQBAEWLp0KRw+fBjOnz8PBoMB8vLyMEJI6ujogKGhISIQCKBoxV8URaTVaqUlS5a4HQ6HoqCgAPr7+4XExESpr69Ps3PnTkRRlMSyLIkQQizLQl9fH5AkCfHx8cOum6IoCIfDQBAEpKWlgU6ng9jYWEGv10sul4vjeV5pMBgGsrOzBafTqQUAKT09vS0jI6NLoVAMAUAQIUSKosgRBKGMjY3t83q9JM/zsXa7Pc3n8yXV1dUFVCqVevLkyUFJkqTe3l69UqmkYmJiDpjNZigqKtr91ltv3SyK4qixY8c2chzXazQaLSaTKWiz2ViEkHXatGld9957723BYNC0bt2690+ePJk5Z86c5t7e3hSPx6NkWdalUqlUNputV6/Xq5OSkga0Wi0xNDSUyfN8iiAI8ZIkqR0OR6JarUYsy7ZNmDDhclJSUiUA2Pbu3Tt10qRJQ9fSM/qVFvCXv/zlhNjYWDXP82GGYfhIrU/ieZ7s7++H119/HZ8+fRqRJKkcEYCiaxH4/Pnz+0tLSy9JkmTyeDypHR0daqPRiLq6ulBPTw/QNA0qlQp3d3dDQUEB3HHHHeB2u2Hu3LlQVVUFoVBouAA9MhYTBGF4KG3jxo1AEASkpKREXSJyuVxkNGOOZIZYEARUVFTkX7hwobOuri62o6ND4fV6g88//7x73bp1+oSEhNCmTZvcHMexWq2WCYVCrCAITE1NDTQ1NYHBYICxY8eCx+MBrVYLHo8HnE4nlJSUAMuyIZ1O53U4HFaKogYdDkdqWlpaX2pqal1jY2O6xWLRTZ48+S8EQVgoigpqNBpOEASOIAiB53ngOE4XExMT8Hg8FMY4PRAIJI0bNy7c0dFRNjAw0DNmzJg6nU7nJUnSJkmSJhQKMSdPnmRTU1MP2my2Zrvd3pGVleWYPn365ffee2++Vqv10jQNH3/88eSurq7R2dnZb48ZM+biX/7yl1BdXZ3/1ltvPfbKK6/kxMbGolWrVtUjhIQrjJG9p6fnEs/zRgCI0Wg0rNvtJoqLi2tnzJjxPE3TUFZWdvOkSZPs0VGvaxnnvSomk2kJTdM1NpvNpFaro00E6MiRI7B7925wuVxIo9EAAADLsqBUKkMAwDEMI9A0LdA0LbAsG6Jp2qpSqQyRkQXmyJEjyaNGjRKmTZumczqdSo1GE+Y4TrVw4ULYsWMH7N69Ozp2izQaDeTn54MgCJCcnAwZGRnDw2AURYFCoQCPxwMMwwzHYlEXGRVaX18f9PX1famEERWtIAho3LhxfrPZLJWWlvK///3vNYFAADQaDd3W1qZZuXJlyGg0IkEQyJiYGG9HR0esXq/3IIRi8/PzKaPRCDt37oTz588Dx3EgiiLwPA/z588HlmVxIBAQh4aGRIZhbFqtdsBoNDodDkeP3+9vKCgoaPrBD35wWq/Xt/f09Cg8Ho8PAAiKoiAjIyNcX19PUhTFKJVKsqCgIIgQOoox1q1du3aRKIphvV7fe+HCBUmr1fazLDuOYZgLKpXK4/f7vZIkGXie51atWnX25MmTxMWLF6nLly8nT548efuePXvi3W73bIxxa05Ojvvpp59+3Wq1vhATE+M9fPiw6tFHH20BAFi1ahUxMnYrLS2lIk0KrsrKynBZWVlbtOY3efLkp9xu9+zZs2dPevnll1sAgKyoqLimlr2vFODtt9++sa2tTX/u3LlFDMNoogPjvb29cN9990F6enq0+Iv1ej3GGHtGjx59iuM4IRwOw6xZsz766KOP5up0OjIlJaXB6/VmdHZ2ji0tLe0jSVLJcVwcQRCGvr4+rSAIhNfrhRUrVgBCCD755BOgaRoCgQDs378fxo0bB0ePHoWDBw9iAECiKMKCBQugqKgInnvuOVi4cCEUFBRAMBgEv98PTU1NcPz4caBpelisAICDwSCKTLsEg8EgFRcXCykpKcLx48fVzz77bBLHcUCSJDQ3N9O7du3SLFmyJOR2u0WfzxdmGEZwOp0Bj8cTI4qiiDEmBwcHEQBAW1vb8HkjSRJiY2NxKBQSKYrqMZvNnWazuS4UCjVfvnw5FgBCWVlZZwmCGNi8ebNaq9UmzJo1y56Xl8dXVVURubm5ZCR2kiJBPGCMid27d7MAENRoNL02m+1NmqbP5OTkkBaLJc3pdIZjY2P7PB6PCQBcAFCn1WptR48ejQ+FQrqhoaFOjUbTt2DBgtAbb7yhBoCzb7zxxtEPPvggNSUlZdOPfvSjjvr6etbpdMYdOnRIOHz4cPjw4cMEAAgPPfRQnt/v79uyZctwlrd8+XLf4sWL9TNnzry+pKRkqSAI/S0tLVMRQvzf2y/6lQLcvn27trCwUKvX6wm1Wp0StR6xsbHQ0NAAer0eGIaB5ORkpNFoREEQkMFgYJxOZ197eztls9nSEELJCCE3x3GB9vb2rJ6enqSsrCxXfHx8qKqqynTmzBnV6tWrCY/HAw6HAwYGBmDmzJlgt9uhpqYGEELgcDhg/fr1UFhYKOXl5YFCocB6vZ7o6emB/Px8wBhDUlIS6HQ60Gq14HK5gOd5WLt2LahUKtBoNMAwDMTHx+OdO3fi7du3E+PHj8ePPvooJCYmwmOPPaa7fPkyamlpoaKxpSRJkJOTw/f19UknT55UsyyrpCgqDmMcSktLcyYlJcX39PQghBDo9frhkRiCICAuLg7i4uKAYRhiYGBAm5mZ6RIEYUgQBCtFUbcTBPHG/Pnz21pbW4lwOMy73W5q7Nix/kiII16t2xwhJFVWVgoIIfGJJ54IS5LUPm7cuL7a2tq5DMO4WJZ93+12xz/66KPHEEJ8ZNSiraamRulwOKYwDBOYOHHiqR07dhB33nlnv1qt9uzfv5944oknjmOMNS+99JIpNjY2iWXZ7uTkZCHiOgkAQDabjXC5XI/cdtttToIgnBRFxTocDrXP58umKKpDr9eX79y5syMSBxN/b7PyVwqQpukEkiS5np6e8SqVaggAUiRJwjRNw+XLl6GxsXHkcBNpMBhUiYmJOZcvXx7b3t6euHXrVpcgCGIoFMKCIFB+v19ECCl4njdJkoSsViuJMYYLFy6ASqWCRYsWgUKhgP7+fpgyZQo4nU5oaWkZHulwuVwoOzsb1q5dK2i1Wnj66aeJ7u5uiIuLA4fDAXl5eRAOh2H//v0wceJEyMnJAYIgQKFQgFarBavVihoaGmDp0qWwcuVK5HK50Nq1a5n29vZh952Wlibl5OTwp0+fZg8ePMj09vYqfvKTn9iNRiPf0dHB6vV6kiAIZXNzsxS9AbOzs6Grqws6OjqApmlYvnw5qFQqFAgE8IQJE5wGg2EwHA77aJp2sCz7WGdnp2vPnj1KQRCEJUuWBCNVARRd7uOrLmBTUxOOlJ9Yr9cbmjhxouv3v/99LcY4hWEY8brrrrtcVVUllZeXExELypeXl4tms1mv0+m0Pp8v5HQ6/cFgcKYkSQaXy8VcvHhx+549e8Jjx44V7HZ781133cVF475od3VVVdW5srKyZpqmc202m1qr1fbqdLr+vXv3to/oASAjFvvv7hH9SgEmJyfHNTU1JdA0neT1eploLMCyLNx5553DsRTGGD788EN08uRJNQBkjRj4Nv2tiVAkSQLHcZCamgoZGRmgUqnAYrEATdNw0003waZNm8Dv/2KI2e12o+uvvx43NzfTPM/jWbNmwSeffALBYBB27doFNpsNent7IT09HYqKioDjOFAqlRAOh+HChQtSdXU1uuWWW9CkSZOgoaEBNm/ePNzIIEkSLF68WEQIwYkTJxiHwwFKpZK89dZbw5MmTQo0NzdrdTodOn/+vE6n04larZZQKpUwMDAAQ0NDURcPPM/DuXPngGVZnJubiwwGA8WyLJmfn2/V6XQeAOiKHvoVAT6uqqqC3bt365KTkx+MjY19qaKigh+ZQUbHwGNiYhQAIEVi8l4A6P2aznMJY/zB4cOHyblz5wqbNm3K8/v9tddff30wHA6zPM9TOp0OZs6caQMAuPvuu9FVZuOhyFySM1c2J4yYhvkPT9H4SgG2t7enuVyuRUlJSYkURQWjn0dKC8CyLMTGxkJqairo9frw+++/L+l0OgIhVH/+/PlxgUAgJho3XtG286ViNEIIBEGA9vZ2mDJlCpjNZmAYBnbs2AE0TQNFUcDzPCxduhQ6OzsRQRCgUqlQXFwcLFiwAMLhMDQ0NMDx48fh9ttvhylTpgDGGHQ6HVAUhbu6uoJ+v59avnw5rdVqYffu3bBt27bhsUxJkuChhx7C8+fPx+Xl5cTQ0BBSKBSwatWqMEKI2Lx5c8qYMWNcCCEyIyMjoFKpsMlkUh0/fhysViswDDPcTRIdtQmHw8jr9UoejydGrVaPra2tdVksFrXD4Ug/cuRInyRJwtSpUzHLsiAIAmE2m1O9Xq/h1VdfzVKpVGdjY2OFK4u3lZWVEkIIxo4de4nneQkhhCOZ5tfOUIyIScAYo/379/dijGMEQQjU19cviY+PP7Bq1aquM2fOqAVBwAihwFVm2OFoXXjklAqILG3yTadnfKUAVSpVikaj6UtKSnL5/f7bo587HA7w+Xyg0+lAEATw+/3hgYEBITU1dSAcDptmz5792eDgINXZ2Tk5YiHRCCHiK0ZYgCAI6Orqgvj4eJg1axb09fXBgQMHwOv14rS0NLDb7eB0OlFxcTH09PQAwzDDos3IyACFQgEqlQpiYmKgq6sL0tLShgVeUlLiLSwsDEmSpOc4DrZt2wYfffTRcOdJYmIi3HfffWAwGNDjjz9OtbW1AUVROBwOI4/HAx6PB5KSkrwIIdWlS5cEhBDl9XpZgiCQVqsdvgnVavWwmAcHB6G3txdOnDhBAEBSZmamQa/Xp9I03RcOh5tpmvabTCasUCg8fX19XX6/n5MkiQaAy0ql8tPKykr31wgJbrjhhp6RFu5a5l5Hi/8YYy8A+ABAmjFjxmYAIFauXImamprYCRMmOEd+z9Ws6XcxAfkrBWgwGNyiKOqVSqVbp9MNWy9BEMBkMoFGowGSJHF/fz988sknLACkaTSa0M6dO2/t6urKi7hoMWIZKEmSRJZlyUj540vDcwRBwLlz5+CZZ54Bh8MRHZxHLMuCx+PBKSkpwHGcGB8fT9rtdnC73WAwGMDhcES7UPCqVavg0qVL6OjRo7iwsJDLysoKsixrQQiJNE3jP/zhD4ZPP/2Uirrc4uJiuOGGG4DjOHj66afB4/EASZIgCAIym83hzMxMv9vtJu12O7ZYLGGfz6cqLi62xcfHk11dXWqv16thWRap1ephFxwtRufl5eHk5GQYP358//z58w9nZWVVZ2ZmHgeAlitrawAA586d+6uu8b8xp+aaFwUYuYTJlcuZAIBYV1enmjRpkuP/aom4rxSg1WqNdzqdiSzLDup0uhMIobkAgH0+H9qwYQPwPA9KpRJsNhsdCATQFyEdSYuiWBC5i3BeXt65W2+99WOr1ToUExNToFQqfaIomh0Oh/mdd96Z5Ha7EUIISZKEOI4Di8UCAPClORwAgEpKSriEhATC5XKRJpMJVCoViKIojRo1ihAEATiOA5/PBwUFBTg/Px+Hw2HIyMgYUCgUHoZhgmvXrk0/deoUFR2jvvnmm6G0tBQYhoEXXngBPB4PUBQFgiBAUVFRcPny5T6lUsmdPHlSr9Vqg2PGjOFIkgzm5+e3YowTVCqVsq+vDw8NDSG1Wv2lXj2z2QyFhYWosLAQjxo1imIYRvR6veFz586pLBZLTKRMAmVlZV8637m5ubiiogL/LUvzbS/lVlxcHPoutvuNBTg4OKhPTk5umDJlSvWnn366hKKouYIgiHq9HpWVlQmVlZVMV1dXtPlRwhgToihG4xERY0wGAgF62bJl+wRB4M+ePYt8Pl9SSkqKPTEx8fNt27YlAUBapIlMQl/4CHFkV0okOyW6u7ul2NjYoUAgYBAEgY2UPwilUgk0TYuSJEEgEJDsdjtSKBRCXFycjaIon8Ph8G3bti1Hr9d7Jk6cSLa0tCj/4z/+A7KysuDMmTPQ3Nw83EwqCALMmDHD/9xzz/WuX78+CyEUvO+++7oTEhJ6g8GgwmKxYAAIBwIBESHEq1QqwefzMdG/H9H+BePGjYOhoSGsUCjojIwMUa/XSxRF4Xnz5oWjAXu0R/L/mqtYxe+HAM1m84HI1EderVaPi7hMKhgMwrx586yFhYXq6upqeteuXYzNZiMBQFKpVARN0ygQCBAURUFBQcGnhYWFZ5qampBareY8Hs/cjo4Of1NT0yWCINKUSmWIpmlFOBxGkYF6KloojnbSAAA0Nzcrn376aXzPPfc4BUHQmc1mnmVZluO4sFKpDAaDQZAkSRkOhzmbzYYYhkEmk0moqqrKmDhx4vmHH37Yt379+jkZGRnKyZMn45deegmdPn16+FiTkpLwI4884s/JybGsWbMmo76+nl62bBlvt9vVfr8/k+M4b15e3mmfz6cCAJrjOAVFUbHRdqloDAgAEBsbCxRFgVKpFEwmk1uv13tTUlJcer3e9fnnnysxxv7/64v+feIrV/i86667tDabrdjhcIzq7e31NTc3T5g/f/6JRYsWubRarVeSJL6kpMRz0003tbndbt/Q0FD8fffd99zatWt/dObMGd/UqVP/NGfOnM0Oh0NTU1OzLDY21nfnnXce6+rqcldWVoYZhjEvXrx48ZQpU7a4XC6BIIjsuXPn/lSlUh0kSfJAdnb2ZYPB0JWYmKhKTk522Gw23NjYGDc0NBQOBoO8x+MBr9c7ZLVaRQBwtre3mxwOhzRhwgQfSZKu48ePk2PGjGkeO3asr7W1NSkvLy8uPj5eu379enTx4sXhqYhjx47F69evF5VKZbC8vNxw4cIFFiEEGRkZ3kWLFjWTJOnlOC6IEJI0Gg3n8Xgkv99vomlawTAMGwgE4Ny5czA4ODjcCjZp0iTMsmxYFEXS4/H0nD9/3rt169aSxsbGMYsWLTpZUVFBgLzW9NdbQEmSMrKysjZPmzatr6GhYWxCQsIjDzzwwCaPxzNvcHDQMHXq1P5wOMzq9Xr/22+/3f7KK69ojh07lt7W1pZ87ty5J8+dOwcffvghbNu2LYHn+Y7bb7+9FiEUAoD+6BTdaPC9cePGczab7Ve//OUvhzuqu7u7o0H3aABIGhgYGHv27NlpFouFDIVCtNfrpQYGBpRGo1HweDxBtVpN5uXlucaPH9925MiRxKGhofTnn3/+g/r6+kkKhYLu6enJ/s1vfgMdHR0YAJAgCGA2m+Gee+6BCxcu4FdeeUXndrtJmqZxpMuXt1gsRoZhOgsKCs5bLJYElUrVBwATSJIUYmNjvf39/cpgMEjRND1cG+vu7oZXXnkFEELsmDFjvElJSVPi4uKGFArFkTvuuKOutbWVsdlsjNFolC3h1wmQ47jRJpPptNFoZNRqtVsURdfFixc7AWBg4sSJO+Li4gRJkkySJPFdXV328vLyMy+++CIcPnz47gULFtwiSVJ1VlaW7/Dhw4c2bdp0YMqUKdSIDG44qy4vL4cHHniAB4CByFrNUF1dPZz0zZkz5/Jzzz3Htba2zjcYDKcnTpzYT5Ikq1KpfDExMZIgCAqEUJim6T/X1NQU9/f365uamlQrV67c1NraSqtUqraurq7R//3f/x1TWFiITSYT6ujoAJZlASEEp06dQn/+85/paElIEAQEANDZ2amhKOqCxWIJOxyOkvz8/Lrm5uZxQ0NDtMfj8UmSZAgEAigtLQ0rFIrhiUChUAg8Hg9avHhxeMaMGX3FxcX7iouL//Lee+9ltLa25rAsO0DTtIll2TAAcLIAvwK1Wl25ZMmSjsbGRio2NtaHMbadPHmyd+HChR9dunSpb968ef7W1lYjRVECQsj9wAMP+Ddt2sQDwIs//OEPE51O55xAIJCRnZ2Ny8rKyKusKYOjE5Xg/1/p6q9KFNXV1RAOhy08z7+l1+txe3t7stPpLCgsLDzX39/PIIScKpVKS9N0Is/zDZ9//vkChmGcpaWljadOnYorLi62r1+/Pv2mm27icnNz1S+88AK1bNkyaGhogLq6Oujq6vpSW1e0xMFxHOX3+x2FhYXdGONeQRDU+fn5xxoaGm6oq6vLjo2N9WKMwyzLKhmGGc6CNRoN/vGPfwx6vT5EUZQgiiJXV1eXS1EUHxcXF6Aoynj+/HnFY489xkVKH9FRkX/LR0Bc08oI69atw6NGjarW6/Vramtr675q8cTIjDjiu1o4cdu2bQmBQIDEGIeWLl0abm1tRTNmzPC3trZqenp69Nddd53z6aefXiuKYtuiRYuIxMREy7PPPvuf6enpgXnz5pkaGxsnDgwMYLvdjs6cOQOnTp360vzcqBAxxmA0Gv0lJSXW5OTk3uzsbEtmZmZnS0uLcu/evT9ctGjRruLiYn1bW9tsiqIUH3zwAdq3b99wo+yzzz4rqtVqp8fjsSxcuPAvBEFcBICOmJiY3lAo5MvNzR2KLk/X1NSELly4gL/DxSb/OS1gVGQVFRVERUWFkJ+f30NRVCYA1M+ZM4eEq6+KED2RqKysjPi6wfV/hLvuussSfX/ffffBoUOHqEgc5QEAD8aYcLlcxwwGwwS9Xr+/paVF7fV6Hbfffvu5rq6u20mSlIxGI6HRaODTTz8dnjs7YpY/HjE5W+FwOMytra2affv2FYdCIVU4HIYVK1Y8v3LlSt+pU6cm6fX6QCAQUH6psiuKGCGEkpOTpaysLEtvb6+J47iASqUK22w2LjEx0TMwMKBOTEwUIzExAABs2LDB0NLS4tuwYQMnC3BEYbK0tBSqq6uBZdlGnufTr9FNfCd39IjV9AEA8JVu/fDhw8SGDRs+++1vfyt0dnYmVlZWGrOzs9s1Go2XIAghLi4O2Ww20Gg0kJmZOex+R3iC4ekCNpsNvF4vUBQVr1KpwvHx8TsmTpx44Ve/+tUnly5dGu1wOGi73R5OSkoSFAoFCZG5s6IoIovFAomJiQqtVmuKi4vzA0DH1KlTm06dOmUYGBhIr6mp6e7q6kq4++67xXA4bAyFQhm1tbUJSUlJfwKA8MgQ5d9WgFGiqxmoVKpjwWDwtiuShP/tounXXpSIIFFHR8fxFStWUK+88sqKsWPHOjHGPEEQIYAvVjYIhUIwfvx48Hg8mKIojqZpDiHkEkXRQtM0iTEO+ny+NL1ef0av1zdNmzZNffPNN2/PycmpffvttycvXrz4lNfrzTWZTPpAIBBDkqRqpAv/4IMP0K5du3TJycnjKIoyDA4OZgcCgUcSExMDJEnalUplB0KoAyHUp1arrRRFXXz77be3w7fwyIt/uRgwyqOPPsrW19f/9/z5839+ZavQ9/S48E9/+tOpKSkpcxcvXhzo6+tb7Ha7ZweDQcXg4CC2WCzQ2toKgiD4/H5/MBgMYp7nXcFgUBkMBrFCoRAYhuEUCoUtEAjU6/V6KSMjo/7pp58+BgCs0+m83ePxTPX7/aXvvfee/v33379yuV4MAMhoNPomTpx4NikpqYeiqG2BQKBm7dq1jkmTJvFyFfAal+YoKysjN2zYwM2ZM6f3+PHj0wCg+ttYqvc7BAMA+t3vfneqq6vLq1KpJoRCoQH4onfObLFYqD/+8Y9EpNdQG3kBACSo1Wpu2bJlNbm5uX8wm821Op3OrFarG48dO8afOXPmwYqKCti6davl4sWLTcFgMNtgMDgRQnoY0XpGkiSYTCZYvHhx3+LFi8/dcMMNH2KMW5RK5UWEkHX79u0wMk6OjANLsgC/gqqqKhw5sR+JovgQAFT/ExwbRggRGOOOp59+etk777yzlOd5BcaYGBgYIEeON3/RDyEho9HYp9Ppmp966qk1DQ0NeTExMXRra2uySqXypKamDlRUVPwPAMDWrVsZhBDPcRzV1dWlDIfDHAAoRop/6dKlwfvuu6/TarX69+zZk93X1zc1Pj7+jcrKyqHly5dL31Wc/M/GtT71EZeVlZG7du2yZ2ZmTho1apS4c+fOrvLycqK6uvr76oopjDEUFRU9uWvXrmcwxgGdTsd7vV6N2WyG4uLiIZVK5bRarVpJklBycrKnqqpq7sKFC49dunTJ0t3dPY1l2d78/PwGv98f53A4ylasWIHGjRsXIEkyGBcXl8BxXDLDMGnNzc1xZ8+epUiSxJIkoYyMDPHBBx8MDA0NhVmW9cfHx3dPnDhxb15eXmdxcbHn39XaXY1rfjheZJ1fgmXZjTzP/7CsrIypqKiIdsp+nx43iiLHJYwbN+5Id3f3L2fMmPGLjo6OFR999NGGd95554OVK1cekySJTk5OltRqNU9RFJo0adJvZ82aZWUYpjkcDs+IiYmpSUlJOa9QKEiGYUJ6vf7DwcHBToZhvAAAPM9jhJCYkJDgoygKj8jOwWg0gtvtpnp6elQKhYKQJIkOh8Mqt9uthGtfkUwW4FXiKti7d68NIbS9r6/vlwAgRe5m/D07JmnChAmrvF5v3HXXXTf2s88+e6G7u7sfIdSo1+trb7vtturi4uLPSJJUJCYmutRq9eDHH3/8TFVVlWfu3Lmu+fPnf6xSqQIOhyOuublZT1GUnyRJKisrK0ar1d4yd+5cIS4uLih8gRjNzqMlnEAggAwGAzF69OggSZIhiqIQz/MsQRAk/Is/o/m7FCAAgFRWVkYeOnTooE6nOztjxoxf/PjHP77xRz/6UQnA9+JxowgApKVLlyaHw+Gf5+XlzYg8x4xKSkrqZVm2JyYmphkh1Pjggw++43K5glar1aRUKn11dXVJy5cvD2OM0cDAgEqpVPqCwWBCa2trvkqlsuXm5vYEg8F+lmU/W7hwYd67775bnJGR0U9RVICiqC/Fcj6fjxBFESiKInieZ0VRZAGAkSSJsdvtsgX8BgKEqqoqsaysjNy7d+8HGo1mp9vtLiIIwgYAsG7duv9TS1haWkoCAHa73f8RHx///GeffeaINDgIcXFxboVC0ckwTI9Wq+3s7OwMtbe3az0eD/Z4PDmPPPLI69HnEnMcFy4pKeletWrVOZVKdf7YsWPTA4EAc/nyZe+jjz46hBDChw8fnn/ixAkDQRBujDE/0gL6fD5REIRAZFoCQgjRkiSxkiTRkiTJbVh/bxZ8NRFG5i40AUDTtRaKv2uqq6sFjDGaN2+edubMmR8fOXIEjZy5lZKS4ujp6cFDQ0O62bNndyuVyvMAMEulUvUzDPM/kUIwmjt3rq+8vJyorKxUNjU1EU6ns2f27Nm2SOmErKqqurBq1aq/PPLII+8ghHwcxykRQji6bjLHcQTHcVJsbKwYWRGVwBhTkiSRJEnKLvjbtKBXPAX8e3FTFRQUPH7o0KGr3lzl5eXE7t272erq6iStVtunUqnEm2666YGrVQW+IqSIPjyQnTt37nvw5eXoMABgmqbxxo0b2w4ePFi/b9++3Z9//vkrZ86c+XFra+t0h8MRI8vmG1rAkTHh92Vuw4iQQkhPT/e//fbbMwCg+spZZpFuZK6goODHHMcljx8//rFdu3ZthC9WqP/S6ERkYjcaad0jbWO4u7tb9eabb7736aefBgKBQF4wGIx/6aWX0oaGhiie58Hv9/MMw3g4jgsAgIAQEkiSFGUX/O0K8PuGBACwa9euV6NW+YqaGwEA0iuvvJL4X//1X08YjcZ9dXV1v49YvqtOsr4yrIj+32azcVqt1rlgwYLzLpcLI4RS33rrrYTocr9er1dQq9W2cDgcfcQVJ0mSKIqiXAP8JknIPwlf1dxJAID061//+mWMMVq9evU9AIDKy8v/7ucfe73esFKpdHo8HpvX63WSJNmr1+uHH1VhtVqdGo2mn2EYO03TbpIk/TRNB202W1iW3b++AP9KTMXFxTQACCUlJSvdbndZTk7OT5577rk++GItu7/bKkU6b5wKhcJmMpla0tLSLsXFxUXnu4DT6QSGYQYFQbCHw2EXSZIeURR9eXl5giy7f30B/pX46uvr+TvvvHPq+fPnt6rV6v0NDQ2b4Js9fBuZzWbba6+9Nm/nzp1Jfr+/Ky4uriP6w6GhoWBaWtrJ0tLSs1OmTGlSq9V2jLELISR9D0ePZL5DV0xHRDhFq9WGEhISmtasWWOO3HzEN9w2PPHEE3krV658avTo0U1KpZIjCCIMADgtLa110aJFbxYVFb1XVFS0bevWrQUbN26koxOvZP7FGVkemjhx4t1ms9k+ZsyYX2KMlSMF9G3xs5/9bEpCQkJ3xP3zI8syDMPgBx54YEr0d1evXl20evXqUV9T6pH5J7JwXxJS5IIO1/NGjx79x5ycnM9vuOGG3Cut17dtZTdt2pSakJBQr9FosEKhwDRNY4qiME3TOCEhoW3hwoWrb7jhhnuXLFnyhx/96EepV9v/f8cL+K9i7b40AWratGnXdXV1bdJoNB3Nzc0LI5OXqEjM913U4kgAEHfs2KGtqqqadunSJbBYLIROp9MqFAqGoqhYAAgmJiZaWJY9WFVVFYR/06mY//wpbqQ4fM899+SWlZUVRj8/dOgQNW/evNLi4uKtY8aMOZCbm/tU9HejIv0eJXVyEvJPfBIQAMAtt9yS4vF4HoyLi7NyHMd4PB49xpjHGJ88cuTInit+/3/L0oyckjq8r6WlpTDi6aHftxY2WYD/4L7j+++/X9XZ2TlOrVZzDoejrbq6OjTi5+R36HJlZP76BiorKyP/l9ytjJyEfHEM5eXlVxv3lZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZH53+b/A3bjrHo04Qk1AAAAAElFTkSuQmCC]=] },
        ["Crimson Halo"] = { file = "noir_cursor_03_crimson_halo.png", data = [=[iVBORw0KGgoAAAANSUhEUgAAAKAAAACgCAYAAACLz2ctAACS2UlEQVR42uy9d5hd13Ufusre+5TbpmIwKARBkCAJVpGiSBWS6lSjumVbtuUWy07cXuL4i+M858Upz3mxHZe4xrFjx5YtWbYlS1YnVSiJkihSFAvYQAIEUWYATL3ltL33Wu+POwOCFCU3SaYTbn73u3c4OHfO2ed3fquvBfDMemY9s55Zz6xn1jPrmfXMemY9s55Zz6xn1jPrmfW3XfTMFvztFz6zBV+XfcONl278rGd8fmY9A8Cv+57RV9nHM0GnACDPbNfXXuaZLfhbgw/PABz+NQB8hgn/msXPbMHfWs/bZEDeAcAtAB4C0DwADZ/RA58Rwd8M8O0C4AqAAwAFAN6Wpr31qhoqQMkbjHf0cREcN96fYcJnRPDfS+Rugo8KABMAuAuADOC2Z52dAHDkRFX5zQPnAKIFwA0g4hn64DNi+RnXwd9KOmyKXAIA2mA+zgBMA21jIcm3cWvbNKc9B+1kBtoubuxrfNKxz0icZwD4d9mfTT0Zd218EABMoGXaEBMCtTPqpifF5R6G1oNyDwBl43UGgPEZ9nsGgH9bVwudqf81AOQ3DI8IShGUyTnTEWw5ZSuQsgExHtocHz8Wn2T0PWP4/W8IQPwbijd8itdfe8yODSu3AeAcwFjIrQNlSQGtiiM2zmh06cb3CShF6LEH4LnxHuuTRPFfd15/l2t7xg3zNDUe6Kt8Bnhqv95XvPoA0AKgsegFMuAIUjFWE+4pp0TEJ7U6ucZUpDagOhTrSRrIlaGSSQDojr9nUwTLV9E1v0LnPEN0/10enmcA+DRwL/1dbtiZvj5qAVAEoBb0jAdrTAsIVI0DtqzoGK1ZoXqVo2hEiTWAhoDqAQWg3txo7QLgJACuP64HbuqY9KTz5KcwXM78/f82euT/CTog/jWvM5eeCcAdZ+yPAGAEpayl5ETYqpKqIgGKAYDgQwMAIKqYAFCSC3e6SgKT5AHYb3zX4fHf4KdgOnri/9vBfwPG/vuqJM8A8Ouot+EZSj7B2Mdp/pp/j19545/IPBHmxxbt5CTFtpACYAEAAClYAIyA4iFKiRQCojiAMTALVELUMaonT5/Drq99HZt/W2E+4jzM01e5bt64Nrvxfiag+W/4sD0DwL/j+T5ZVJ35+mp6Hz9JrNFX8c+d+TOOwSdPeeN04xgEUESjTnUDsAkBAEiuKKooPcFOTyhMT5MfGzK064liduMcd9FT6IPwpGugp9gDetI18lNcLz5dmdE8TRnvyUF9fNLnMzNSzrwZp5X7HTt2MABAjBEXFhbO9L/hDtiBsOP07+SM74qbotfDHAVY2ADVFIlEREQFVUgB0IByiRQSBUuqJACIAOIBBRFVVMnFaDrMwTBHVUU/NcWIqGIMzp8gWoCFjRDdLoAdEefjPPEC61E4qjsWWMeMuQsOw2F8in34aiTyVGE/fYrjngHgVzEczgTTU4mPrxVROA1K7/3pGzM3N4dEpCJjNvPggSI91U0iAEA/N0chBAKYHv9iWbAHgH6D5QAAjCoFxIiIShvn4wEFAVQ1xRwr8Bs6YRRBJQIRQSLSEALQLOn8qXlYAIC5uQpDGSgQaZgNMC3TWGgxZlhEnaVZBQAgotPvzKxHjx7Vp9BdAR53/eAZ1/VkID75GH0GgF9db/lq+hKcyWZN0/Am0Jqm+RupF7OzsxEAwBgjCwsLMg/z1ITxsSGEsZeg94ST1E3xqwDooVEDGROAIoAKABkVEMwkKDFAHRUAuyKgAIgiMEDEEALFqUiTqlhV4wdj89yl1eK2Ko5GLIikRIOvyCtERJ2enlYiUmOMMLPC0bF+eBSOypMkBj0JdPIkcJ4JVv0/FYBPFidP0s12bYjWiDFGFBEUESxiQVAA6AY7iQggoop0cYwJAID1J2zqJpNsANVsgE2np6clUFCNinoG2/UAUFQxU6WoSqiKETF6xEiaKCkZ01D0KYlROQ3OTBXXVSmIwKZBQogQYySACQDQJzwk0gHsjFlaRQS6XQAAwcGgQ2deAzPLxvlTCC1qGlSivuIU6iZjjh8oVoBNltwFAIf1KVQdfYp7IP8nAfBrRQAAAHB+fp5EKhQRLEtBEaFNAG1AZINBxkwRY6ReT0+DFKD1BPBtAvDM7xgMBiIizMyiqtgRIVFFGutzKKoYVUkBcJMBGVAQGkVok4JioNqbaHmTKZ8ALlVUbWMAxQ6ZOEBVAIBOZ3yOqorgx0roJvhVx/8mzyMA5IAbIDbGIADA+vomKBVFOtjpCA4G42sLYSBTU6jMs0JEeuJEc6YDnJ5C/dCvoYf/bwXAJ3v24SkMCtgQr+TnPDVNQxvicBNwoPq4dYoIpxmt1+vhBrOddrLneY6qY0ASkRZFoZs3U1WRiKTVaqH3vg4hsGyATzZZVceMqACoqmg1IQ8gnupAkjKCEjo1FaK0ECUkytoAysY9HB/bxrw1PucCA+eIWlWVF8lMkiTm8YdpzGybYnbzPM9kv6qqYAzejooEVFUcsz5Ar0e6vg4gMmbNMdsCTE2xMM/KhqrxZL0Rn8R6+r8zA+pf41rBeZgnmRMsQ0nSCI1vTg97vTHI+n2BdnvMGmeKynZ7FjbYDNM0pc3fhRA2bmxCIqTOOQAoTutSzIyj0QgAoDbGxKSu+YnMNQbfaR0vcQxNaI4X5OesIqoaq8YWIx/TvGlSsGlUJUaMLk3NGEQRogAQomaqWBKJMSZaazNmNsx8JvPhmboeAEBVoRLVAgCQJMkYyEWhaZoSAEBZkiIWKiLUapEQkQ4GjyuwMQLHuE4hBJ2fn/cbngH5Gtb0N6WkwPwDit0nO4ABYAfOztZchYrRP/7k93o9DCFQCOObk+eKIgBZltGZzFHXNQEAdLvdTcajTdYTSTDLzvTp5RvHkBI1Ym1Xi2KZV1e79bZtNklCMCWRAADkqliORpJqRiWW0tSoDRvPPYlaADIrcxzrc6HghifQVcSeUyEmkgJRkxiZiUQ0w+CsccNmNOQhGWMsIlpVh7h5dokiNo9fP2Kj7TZJXbeVqNZNZux0OlAUYwZ3DoAoEURUIqKiKDTLMiUK8rj60dHBYCBN0/D09DQ45+LCwkJ8EgD1m2kZ/0OJ4K/Q++ZhnprpkpsmMEAPiQayCa4QAsWY8iY7bAIphLDBchmk6ZipYnTkPYCqYJLQWGRaS+Nj6fTfU7UIAJBlXgEcJAmqyGw1Pz/w1roYG+Ow8BFgAGHMYrEAgFRTGtqij0PUvK1sgNDEsW4IbQAYAgxEBg5LI+pMFKF0DAqpCo6tnk2VmzjkYYyxzZ1OJw0hsLUW61rRuTHrefIaAgmiVwADiEjGoCKynima223FpmEZA9NSXZOo1pKmqW4wI43BV8qY0DskMlJE1KZpeHZ2lk6dOhXOsIyfrAN+Q/VB/gdivifofPPz89wkDY/1vLFB0W5bMsawMYZFMpI0UkKRjRHaEKWcJEyIOSMCixAZAyZN2ViLbC0yERFiwszjyIC1LUNkjbVpYq01Wcau251OkyS3j+w/UJR+PYxvkoachRWtS1JWIlLfJGBsXcehekgRsEaIVniO3ESPki2DWJ0aGB1ggzqsSVxOQmtYNew1pqmSCLc6zqh6XBlQqeooxsZUVd+eddZZrTzPc2PQEJFRNSZJDKkSGYNsjCERQ0kCoGqJSIkDY4CAqo6YPTIzMjOqNmSMQWamsbHSoDFC1lr03qFzNXrvdUPMo4hQp9PBoiieivHwf2cR/Dj4msfB12oFEhGyNiNmRhGhJCESSSnBAkUVKyAY+8cMI5bonMNNhmNm8h4VkdRak4xFtkERIVWDiMhpmrgkSWyjvrnj85/v53mv94bv/+5ta8urhz7+ob88kee5WSmKut12JhQJS7NWV5ZjWHWxgcZMx2gCGC+q1PgCJ0yrvQiWxzYsQK83dtsMwERITYx1TZbaNkqkYYy1KqK1ZXrZVVf39py/e8/HPvDRfqzr0bnnnsutXqtdjxofY+WN8SHGVAMGVY0CYMAYqSiAcMIOETdY0mwwGqoxBoi8bBom1tq4Yf2LSC2ITlVzJCqFmWUwIG2adZyamqKVlRUPT0wXw68RXflHx4D4VDHMJElMCC0DkGKnIxhCMGmasoiQc85sPMkGMXIkYmWmNDXGOSQiIaKUjEFCRN5kO+cyF0JRMAN2Ot0JAGZrnU3TNO1OTbSaEOOhxx7zJstn/vlP/NRVP/ZT//L7z997wfMfuu+uWx47dGgwMTHRCiEMyzKLja77E2vtuqpO+h70kGFJCu+lC9auJiN5CW3Ze2179nVFogc/vnbiyPZOAmv9vqe69gAdcMVJoXJCy7SMJst8CKGe2Do5kXCez2zp5f/yX/+b//odb/vul+7afa6//8H7ysWTJwMbqWZmt3RBkJWVjDJZa6zHEEb9lX6r22opWQZgtHbMZESEAIREtOFpoo0H2BKiZSIl1ZSMAUQM4JzDpmkwy1CbJgPVkrrdrhZFEb9K3PgfLQDP1Cv4zPe5uTlumsZ0Oo6sjRRj5LFLImFr0TCzGbu9WgbRMJElIkvGIFtrjTFmQ7w6do7ZObZEiUkSdJGZjh9ZXut220ne7Ux0Wt1WCL4eLK+7Hbt37fy+H/zBa3/4R3/kn+3dt+8VBw888sXf/W+/8bsfeP97DszNzXEInJjBam1XbbNYLsr509a0nXPOcMY2TzsmTVPLdq0o44vbW69eKev1x+JgRSkurxQovazTQte2xmoSU2abBY7WRlUNMUbqZL3JTqfNt37m9pMmSY6cd/75F17zgud/3w2vefU1F1x4gV1eWqmPHXrMC8X+xMR0VxGdhBiOnlw84dLUtbvdniED1gKPgQdsjGFEYWOQjDE0Vl0MGcNs7XjPmGVD9UnRe0BrEUIImqYITdNs6IzTCtD/plnD34zMCHoqy3cH7MDR5Mi1Wi0GAPDemSQJHKPjJBFK09QxM4/FR2pEhE5HGYxFtYpGNvWcsfOZUyYWIrTIQiTHjx8/rqXihZdcuCNLs3kiMq964xuvft71L3zz9OTEtkMHH/7Ub/7ar/3yH/zmr92Zz87Wc+22Li973+1mWVHoYApWoEhT26oobaK3VmX8wPphzc6Z4XoTXtOduJ5Kmy7aYvGR6O8bIQWjwh5JOLHGZxQTVawkrWIdG5/5eiKdmC21rAFyeOyxBxAAkp/7lV970Wve8OYf3bZ97vKV5f7SPXd+6aN/8c53fGRpea10bIpHHn3w4OqJ/nB+z7bZNrmuiDQxRo0kQjGKBwAMqESkAcMYLP5xV06MEuu6Dohem4bqGEehaThaG0JVVXEsjgdijInLy1mAcThPzhC/3xAQ8jdZ7J5+JbOJCSGYJElQRDDLmGN03G6zJSJSVXGu3XatNHdsmZkNWctkLTMTkxJba3lsHbJxzhpkNC51NklaLkuyjAnCqPZ4x+c/Xbz2Ld955Y//5E/+q6uf/5xXDAfl4gfe997/9MaXv/gX7rr9tkOXXX21SW0nMVUwEYtYVYPSGC9OeuSNZy6iuhycC4pEHJoANEkmHUBlX5ptuyAVmgnI1SFZO2Ihcx7VW6QIzOwsajAmluC9WCERCWtDCYgNTubt9tzuc/Ozdp/Hf/g7v3Hfb/7Sr3xoy/xZh+a3b9+z75JLXnrtdddfK8BLv/JLv3JrWdV+57az0one5EzqjEVEYFVidoTIRIykxAREnJBhQ4bVGE6MYU7IokG7ZfuOGRKs19ZOlHmeW4Ag3nvw3gFiUO9zAKih10MdjWYUYP2v8+H+oxDBX5E2tQN2kM88j40NSzGmTBTZOWIAMM6104mJqcnOlpl2UzWYt1o5GUBkw2QMkwF2xhoiYmudYWZrjLEudTZNW3mS50n0vnnwgcPykpfdcNYP/ouf+pYDR441O3bu2nL3Xfs/8JbX3/hv//x//d4d11zz0tb2s3dNQBM6FpHrGL1zhFVVVW7ZRZ1Rp33FoaubNEZLghaoiRJQt9hkMirnl0hrbqux5wXjlvc3g4W5NO2VwZeSo6AygwEYDYcjdQ6TmHAttSfymmXTKScmS5jTxFDvvH0XT+zYucf+j1//+Xvf/1cf/mTa6iy1JqYm77pn/8GXvPzle66++urue97z7hPnnLUrzzsta8ikQJbQKikqobVkCcgYYjLEyGicTaxNEpsmWdqZnpk+Z+9FlwzLteOxqiQEUiLVpmFxLmiMUb1nVR1HWaanWfv9vnyj9UD+Jhofm0BkM2VcjB0GSNC5Mftt6HSGKLV5bpzL29257bvPzSYnzJGDB1e2z2+bdgkTCSDbxDpjrDHGkLPWOmeMc0ma5hZFSonYnt+5a/ebv/Wtzz+5Pmy97Xu/60dnZ6fiP/mu7/6l//Ubv3zTZfv20b5LL98qEJJY1xpCrMpY1nXRH4qIZFlmjqwdqSeTpJWRtcYokyTMEs3QYzVjsN1iNzlJ1E6iJGcndu86xMOHo/TbiJkQy7ofFTlZFwxgSgRsTMKcUBnKemJiInUO86rSkTFkmZkJlJPMtS+65Irp6amuf9/73vvlWz79+fuuueaqc972PW/7iUePLJ44+5xzu1MzE1vWT61EY0whJCY1uVNEMshs2FrD1jKlzjnrWnmW9rrdjiZ5Z/vOPecun1o8dOrw8YG1qCHUIYQgzKIxRo0x0xBWhIh0w5mtw+EQnpQp83VX2+ibCMDTeuDYB3U6e+V0NGMzBjp2qfh6cOrYYjvvzl77shv3ffH2e05E4GR6y9bpdprnJskTl2epc2nqXJZaa6jdbrXLGCauet5zL/mXP/3TP/Gq17/uuwXB7b/33k8tHjl0YLh27PDLXvmKCZtlaTkYRF9WVQhl4X1opALfNE1wzjE3bCcnJ11jTCgBwEZnnAo1xlWea1+SD/1QnPIaB2t+FDOxrqoq6eOg7kNzqiCpCFEaHytCFO+cEVUkqqUTOwQAqRVLqopNE2rvg2+aoh4Mh8PBYOhB1Vx58WUTD3zhCw9Mdtv12vLyibu+fM/im978Ld/ykz/9r3/mupe97Ir1smhPTk930SClJnVp2so2X61Wnk1NznS7k93OscUVPee8i84rq2rxkYceOJ60EhtjFFWLY+njaOzcj9RqtWgzMeLMCNNTZCf9o2PA08bH3Nwcee8ZoIZWy3CMKRsjREQMkBjnwCRJYg2RydLMnDhxcnjlNc+98od/9Ede8cG/fP9nF44cLc89f89sYmyiSGQc2yxPs7qOwyo2nW//ru959Zu//dvfHhDiB/7qw+89fvjwI7/xK7/87vtv/9KByZktZT0cNkEbObW6vEwmYQ1NaJoYEZsAkDoi0TrWqqolnTjRkO1CkIEvYx0wlNCLLs1YCSNk55r2WRe4ifMOF/3DQxI/ybkZsIxqwIY9ECLH9VBWGvK6qSWaWJZlokE1TclGthaMMcDMgCEQWiIe9vsrRdPU4AU5s+XBhx9ZuuljH/nQ1PR0d+HEqdWzdu+aev61z3/V1vl5vutLX16QGFZaeZ5bxwlb5nbeyruTvc76YM0/8uiJ+sd/6qe/ZcvcHP/ur/3Cx84977zJYrQ+QNXYNOJFvHov4hxtsGDUGGNEREBEmC1mdX2sB+o/VhF8Jvhgx44d3DQNbzKdtZbTlFhEOM9zNuZxl0okZ5HYzG2dar/v/R+4/7VvfONLf+CHf+gHbafzwO/+9u8+MLN1a2frtm2ziFqnSZbOzM3uevsP/8hbnvu8591434GDt/32b/3uu+654/a7lxcXj85OTcixk48drftl4ynEjFMXG/FVKGoGwLqO0jQqMYr3viiHZlgnmoSF4VDaru0yK3kLMcnAtZ0z7ZZCN1PX26W8/QrXe/Zdo7X7t+ftecWIJ6MOHZKxQC5mxliwxKZmdAAjoto5J8OhCoD1qiyIwTAzAjCKaNU03rfSJCvCqK76Rb20urqWWlKDBE0T9ZOf/dyDNk3Xr33B82+85NJL5g8efHSFjbNRuepNTs9EQHPfgw+sXPKc5+74mZ/9t/98fsuWrf/yx/7pf9y7Z/dMqBvvy1EjtYigj2M90KuqiohICEHzPNe6rkFESHsK86N5XYGVb5i3hL8JBshpAHa73Y1UdzgdoyUiTpKEAMAgIltLhpnZsTXGkWG0dvtZ29s3f/SjX7zhNa9+5fOe+9y3vuIVr5o9urhw/6c+fcvCycWVZnbr/NYf+uEf+Z7d5+y54iM3f+rP//gdf/oZbcrFVoJEMfgQ6sBkoS7WCjDGdFvtHvPYXxtj41V9WVXDYjiEOk0BO03HevC2NRxG103yNFor6pGVDBGZRJVJyc2jTl1DE9cebUaHzsu756340Ykj4JcZQ4hCIUgMgVAEo3KS0KhpvHPO5TklIlXkwUpTIzZEJNYSIZoky5LcGHYCLCuD5eHWia3t2bm5aUDQqanJqdnpLd0779q/+OhjR+977tVXX3v5ZZdfvP++Bw48cujg8qlTK+X0lq359//QD73m9W94w9sn2u0tv/Grv/zjhx89WM/MzrbLol/4iOJ9CCI+xjjGmaqXGKOmaapN00DTNKqqBABqSiPrT7SG9R8bA542Qlqt1um8vjMAaIiIEZGdcwYxISJjjGFDhhiQsdubmlhbWfdKZvGiiy9+7szc7L5rr7/2da9+zWvOu/zZV0yiS5PFpeVTN3/8c5/50h23P1oMB49QU0VGNaP1/urxo8cW2932RNrqZP2l/iBJHNZSa12GYQjVYDgcRuecsTYmiGi0UWRhkm7GFCM7ZRYIxEImQWedgmOF9Gww264w3ecMQn1qe5LvXPDlsVOKqxGxUaMiqoKIkdFqtKgpEYBzRlUxA7BNkjhmJgCI3vtKxAuRswAAxbBYn56ZnJiamt26vHJqKSFAZ13LYBS2rhoOR/SZz91+R+PrJZMm+rxrr937bd/5ba96zetf+7Zz9px9eWKN+8Lnbv/9n/gXP/bxl1x7/dmrK8sD7yVI0wSKMQYJkUiVSLRpWGJEQNy0hnNVdaiaItWNDGH45AwZfboDEJ/CAuYkSUyMkVUVO50OxRiZmQkRmShja5EAmJmZjWHDyIatsQqKZ+3cMf3JT9zyyDXXXntup9uZ3L//vk9PTk1fcNEle6+/9LLLn7/33HPOa2euuOUTN32+Hg0WfTWsUYHrqqmGw0E/scYJBI4Y65MLR5cZoKnrkWdmS0SJiJyurwAPgFgCi3CiKTdaEgFQqmhbxJZVrFF0ezk7+xLIrthCNNu12dTDUh04Kv6kktYeNaCINERRADVaBO8tYCgVrMWwkVw6Br5NiMjFGKP3VbFWF4NYC0xOd2dYFWLjG+cSaywmZTkaHjt67NDU9OTM1c97znkvfemLX33VVVe/+NJLz7vaJu3Zhx9+5HZjDcRa/M/81L/5z1deetGc9z40TVPHWAcJEgRQvNcIEEVV1RiQplFBDOC9Q5967ThF7wfKEyyj0SScER35ugKQvknsh3NzcxvWb28TfDROGk0RIDt9kLWKxmwkZG6kSkhsAkTv57ZMtW+55dM3WcOtAwcOP/Zv/+//+Cu/8z/e9Vt3373/5rI/LB+5f/+dRw8/8pizloqiLBsfaq9e8m67p6rYeF81w1BVVeVjjD7P8w4AQCrSGGOiMSaWZSk11/HxyyghAwCrY2uxAUBUw6KeWmzbFsTOK+3oBOm1EDNkJVRmBkvNmZtRVYpYKiEqlnja1dE0TYwxhhBCtLaVMbPpnzhReu+jL8PAex+zLG0T2cyH6JvSl6yMD91778Nlf/1gmrgtxxeO3/+uP/nA//qFn//VX/7DP3rnTYlNZx85cOCDjz5yv+9Mdnve137sWWBseLy3zHw6YbcoBNNUUSShJAmchcRsZIpvAO3omZEQ+nrixnwDgfeVqdAbFzwuTUxRtcE0VWQWZMYnZDcrK6ryuDSRLBVF0UxPTthbb7nl4Te/+Q2nrnr2lc/5wuduO/zYo0eW79u//8hZ87P3PPrQ/Qc7nY7GZqRFvz90zjpqRBNlO6xGy2srg37bmRRnZrQoilKca1yFWtBYFBRFoU91vnWFmlhFC4AWABwoIbCdEO5aRauqkRW5B7ZHIRA7Y0iRLDj0IEBYqwKeTu8HKIArFGi1gJmlrmt0zqG1GpoGmvn5+TRJOhNra4N+mibl1FRvXlXQV74qimpIzlKnncePfOCDDzz7mmse/tCHPvaxQw8fXjOp5Rdff/2FrVbW+uQnPnHr2efs6YyGxWh8LWO3ilFG5LCRTW4RoIYkUYxRcawZpQgQNgq7NmtqduAGCJ8s2fTpzoCbfU4ohEBnJphmWSTV7HRa/ThwbihGHmdy6Di/zfCGULaWGTCOBuuwcPzEga3zs7tb7bbpDwY+yVLnkszOTm/p+DJE7yHWqgFCCCIiK0snF+p6WExN9abHRkCed1233fJeoouciFCMkXJVzFUxG2vmpx+GBMbgU7BIqmRV2QTlLnHXABgCYCvoJtH0FCISACkoKigaVZLHK/Zo83qjpBRjpM2ajXHafQUmxiw3eS9BNNPd1kxKaE6ePH6sCs0oQoSmGTXELEePHylf89pXn+uMdUePLfQnpifzEydODc4/f+8Fo1G1dtf++6rJielURAMxGSbeyJRhUjVorUFrx/t+5nkBlKAqp8kgxkhzc54AdnxDOizQN0P8zs/H0yfe6Tzu6FQVjDGSiCXnHhfBY/ofAxHQsJRlUZal373nvIve+tbvesmRYwvHpzq2/Za3vPbFL3j+NefMTE6lzmZ0wSWX7Dl2+HCTWRcyZqqqenhqdeE4pamZaLVm0BfqvVdTCSWELgTDWI0zi7FEHQNDTgNmkwVjoqSgyKoUVRiByYC6nLiFoBiRhTVyT3TCgLUYjG52S2AVVgC04ihRpTOLoZKhUCLjl4uRnCoSs1GtkWIQFpE0N72pqalef+HEYn917aRzCWWpgeW1NbziqqteuN4fHLFscevcbPeffN93XHvO7u0Xr6ytH9+37+ILLr7k4ksJIW+apsCNTC3mx2tpxBgap3MlYK0lxErHOW4sGyn/px/EHX8DCfd0FcH6uDjrQb8vkOd6xu8zcG68IcYYYmZiZiJCMsawTdM0NYl6wNYr3/iG15JJzM03f+qTx46tLjy0f/+D3Ynpyde++oYbZ6anpkQVPvzha2+uV5cG49Sisulm3Y5BSMumqCwAiBGSABLIC0QPkAXQaiz+BRRUMzxdsFSiggBoAqgKyKDEHlE5YI9c3hbuoaqOK85BU+JWWzFbA2WAAFYZPY71x4BVBCBQVRzXhlRYSUqJjtlHVNEDQI6oxhgiYCYi0lpi2sYs2zrbGlb1oI5RTRPT5z/3ugva3cmLJntKL73umtWDjz56pBwMmui9HD9+/MiVV12178I9Z+/7uf9473/N0paN4q0XL1KTZyZSZbKhwfqMwq4sy6Cu69N3ZlziKU/uUyNfT0PEfAMZ8Cn1qTN/3tT/xrXeDmNk4g3dDxFZJJKo9vvD4fwP//N/8cat27df+Gfv+cAfPHj//cfuvuO2n7rjts89BsHjvsueNf3W73zrc02rdd7UzJazv3zg4CMocqrVclmiSVZXtSci0kBitDq96dY54iGRZx/HGcSgAAWMAaIoKvSVbgNFUOAJNu22cg8gbF4QpMStCbL5UIUJlAwA1mMRTEQYCFE206NAFXPYzKEeL7dRSAUNgNrx32c2CAHAtcnNdmamb775Eyf+2//8/VesrQ/nb/3Cbe+lujj6znf80f6yaopTp07FL37htZ/MOhN7Rk1VX/Gsi6/5vh/4gdf9t5//uXel7ewUKflWkthStBFpSGScypYkJYSgG1njqq0WwEblJwD0UKT8R+WIfnJ3Kmy1Wux9izsdIWsFRTLaDL+NXTBEAGScs25MgtaYNE263U5eDkf06te97jkvecWrvuMLt3/5Y+/7i7/4bN1fO9oUw2ZqYoInJ6bccH1t9K4//uP777vr7qNve9vbXv/il7/ksne+809umepNaaKQUgwEIiohAEYAH6OgeJUG1YSICAEwIoRxAh0CIqQilLIYNkokYh2QceKTnCmzQbO9rn3Wsyi7KonRCgEQKoox8KjUDx3TapkDSkG+iURByEcB0IgICaL6seVNMWUSEUo0ISYxwIyAyC1Ft1HgQYk1lmxi0yRNmqYYmXyq++M/+RM/E+tm9B/+1U/92Ze/dPuhVjuXdqudzm+Zzfpra3Fmy5b2qeUVf3xx+ciLXvzCG5PMLt126+cPTXYmTB2DSgg+BBEA1XEnCdEQgqiqxBiViDTGKDGOIpEf1xKPFuKT8gLl6QhAhKdoB9ZutykEw0myUWOrhs6M/yIyx6gNJsipzZIkSVpJmpoqeNh38WUXf+8P/MCPnVxZP/w7v/O770NtTq6fWDzRH6wsjdZW11b7a+uhKosd27ZqXdSr7W7rsfMvuvCSTrtX/9Hv//cHLtyzZ6L2I7RRKXovIAIEHsQjAAcUEo0xQowAFixEDKojRfaKxMobrTg4VTKJqk2REyfaflbSuWCvukswBEVEQFBQJD4B/tGHm/IYoYYSpVbE2KCNEQXCmP3AqKIAkDCTFaGozA6NAYycgrUJUeqYrUFrnbHO2SSxCibk3fSaF95wbbedLP3Ve//iXeD9ssvyUKytFKP+en9UlcO6boqjC0dP7j7r7PmDhw6tdycm/HUveMFrDh169MCJxRNrEHxFZGwAVRCJdT0YhkBoDELTsKo2sgnAEIJsxoU3PARf92GM35RsmHH4bQ37/U3RG2mcBTMusDbGUJomdu3kcPnUqYUTRVEu141UdVDzLd/x1tdzmmV/8u4/+0Bd9k8ZEJraOjU3NTMxPznZnm0nSZ4kiRsOR6JNUf/af/3Fe6674sqf6Y/K5P/5xV99WVbU6bNM+3xXFBltiFQUNgmTySrDRoSMtWydkFOhRJXSjUydOLZ4yW604xAwxMEgk+V54XmUSICoCIqiKomCnYN0q2MyYlAVLEZQMrWSU4duQxwbESOqZEWIxZrMBMMinEY2SRTetKBTByaL2t0jfPbc9Nz2t37/279zsHrykde+5AX/36dvvvngaNQf1cO1Jk1T22638l6nPbtlZmrbztmZraFaK7dv25K9+91/8YXVYbH07W/7nm9jZ5IYMQyqYm3l5NKJ48cPLxCRpikZAADnIqmmeGZGzOb7DtiB34hs+m+UCD79eRfswiZvNlLrvVpriZlZNaUsA7YWGdFwkri81craS8P1omjKuqqaIGx6rtU19+1/+P4vf/FLd/nByinLCsV6vwg+eAlNQCSKFGHh6MmT3U7e3bN7d++CXXvaIVRrl119xcWnTiwdP3exvOgs09n6cDla6jRiQEOMIhqpVowGsIngURQCQMQIjpUpKEVWTtSxUWILylYgabHNJpEmr+fWtROCk4oICICAAISWKoJmfxjeWxIVVqIKNj4aowCARolZmQIYzJUpBITAAZnIWHGWMJrMSJKLSVPjnKnWui/jqRfM7z1ndtsbXrX1+NHF/Q989hP7LzjvnPZEu9NiJre6vrScJMbmLu1tNKTRRuooMTYoFIRQjy6cPHlqefXkpz/z2f0Lx48cK/uD/lKxWm6dnp90Lu2JBO89qmoQ5scTEzYZEACAJk7nBz55LC0+HQF42gc4ARMY2psF5ICbAEySsf4H4IxzYJgdp+12a8vEVG+4tlzOzO/a8p9+/r/8i61zWya+eOvnv3jn7bd+Oc8zOxz0l9f7K0tVHUoQRe99XDqxsjgxkbYs27Z6jxoEekujqeYzd+KIfHN8ZfHUZZpcdkXgvQ+W64shSbxpAoqoUiSKsUECJggBjZCxSoYYxzU/IpYB2KiaXE0mUdLLTGvPFdx6XiaaCOjGHSBAVSRkcxjqA8dUl1G8jki8AQJSIFUlC0oESmqtMeTZAaBzzllQmzIbZptMCHWwqjrfOnH+K7AaQnXDC/s88NXCr//eACZzXq2bJsaoihHypJ0sLyyfStLEIrMZFuVwfW1wajQcFb6qQn9UrBubJBfuu3Dnt7zxjS88tbr88Jdvu+3Evn0XbUnSZFIwNKHWSBTEe1IRryIiSZJoWZanU7OISEejkT5FoRI+3UTwExoPRYhfMyoy9kM5cA6ZCKndm5y68srn7AVMtiwsnly78Py9L5yeSO3C0QOr5drgZFM3EiMRS00hhLC62j+ZAIBRkwcfKl/4uiqr6mTZX5+0pnvlidHV0pT0qZVDt85xuuNtra03bhsMtyWGsw5AlnJwybiEjBNrbMcamwjbbqS0EynLlJNM2Rllmym5FDC9mPKLOlHaHjTQ+Fp07A+U2FLoXMbdizRUBsBAqqm1amym7LomTTJOk5w5aUu0qRjjIjsTyRkhm4DJEkhS68veD+Tbvm2y1umPcfm5e//w3Y/KO9/XnZ2f3nJ8ZXEF69pLXfuqDFUtteTtvH1y9eSJpikajFENixURaXy18smPvvehbVum6XWvetFb0yybvP+hh/jSKy7bMTs9tcMYAyxMm77XsbM8wSd7LDbXU4jhp7UVTACAXeiizzzDRhW+tZZp7GVmxIyZ1RiDljm1eZrY9cG6XPuSl179T/+v/+vtH/7wRz7zZ+/8499/4N6792dZOzz82ENLnXbX5VnakyBQVXUxGIzWpya70zHGCMEDihfwDTIJPLq6eOISaJ37bNN91sGy/+jDCI88F7IX7BU++3ATFuumbjIlA3FsivgG4WQcYt00XLDhqGpyUJMpuQTEGJBkq2vNvcD1rp8UnVKVSGAIkICAxv17kTgkDh6R4v41aQYWAMEwBSFakiirUsuaVFBFwDa6xDC4BMD0IGsDsNvii/nvbp31FqvRvGN48L1dwfRlrdmXDPxo6UPri5+NmStCEPUxxogxBFVBg67SqpJGSpO6tjFpSkJw4NGHjm6f3Z4M+6PBqaXV/R+5+RMPvf3t//TVW7bMTnzpi7cftM7EqF6qgCJeI3OQphFV9ZGItCxL2XCcIzMLj1j70H8qAwSfjgBkAIAudDHkT8wB5LGnmTdqfW2SZNY5m7bbLXdsYTH+0I/98+/Yd9H5z//SF+94z+/80n+9tTc11ayeWBqmJsP11fWhZQIRgX5/eSVNWxmpUowxaAgq4IGiRxuVCgPDw2tLJy+1+flXmc5V960uPHQowsHnZFPPvcTm5x3xtLisg75Rr7U0ug/T7TeY2Wc9J+3tuRqTPReg2Z6oaS9FHwHYOLVsNeC6VsspMc1BskNBhUAwAmhg0oexufuTzdrHl0CWBY1ojGkaY+cchPnrbLb3Bba39yrsnbvPdrZHiDoMg2KC8laEkO+L9TlvS7Z8Ww6u/af18C860edvyXa/ZYn10DtGh2+yabuqfRkCahODRokgEhtBEe9s5gaDwYjRoa9rf/LkyZOmidCIxH6xXH3q4x8/Mj033/32b/+275rbOjv9p+96x8dnexMhNAFRxkpxCCohxCjSCI7bx8XNyM1TAPDr0j/mGwHAJ/QjnoTJ0zogIoIxhonIjNOwLBORNRnbTqtjB0XpXvOmb3neq177mu9+8P6Hb/q+t9z4Wy96+SuylFwnaTOleavdydPWaFStnTixvKxqpO04E5GoWitGBAyqPqqICLYakwRn4mPr/ROXJVP7rjTtK+4vTz28IKNHL4tyzQVJZ/dyDUvr0ZcJJTDDdnoW7La2upldzlx0GecvuJo711zu8rM7hMmKhCIg+CWV1cOxXNxist4s4LyqiBLAoxgf+pNm9f0LCIuNxJirtJ+fTl322mzLy6/Lpl++mzsXp2SzKsYGjTF9qtejYtDQpNdgcvGb8rPenKDJ3zM69ZdtleT17dnXL2s49sej4x+QxJbiUQqVKgrE6EMIRqL3PoqY6MUDM4ejR5dWC62Kqc5Er7tleiprJ2ZmasvkWTt38hc+f9uJc/aen11x5eUvU5HD995396Il62OMUWqRICGEEKOqEWNUNnRA3XSem8KcCUB5CiA+rYwQBACcgAmss5pVlUTkdBY0M1OKlm2WGuPYpXnbPPrww/W/+Df/5vsmJ6d2/uIv/PxPHjt0ZHHn9h1b14tBf3243jfsHERkIqDRaHk0GHiftSmgoEOI0WtQEQ+WFEGjgkQwAbGyWj486h+5mFsXPNd0rzlU1oceavoPXuo6l18CyaWjWPcX/Gh1XXD9vqZ/5F5YPXBX0+xfD+FYi9Gdx9mzLoHkWbttOj9SGK6LL5RSf0pGS3ts65y2UHvANLjJr33kKMFxF0NyGWcXvimdfd1VlF+XInYeDtWdH6xW3v/B4YnPfEmKBx/w64c4kCbKUy/KJp/9Bp76NsPG/EW1+h4XB+61rZnXLaNb+K3y6J/FLClqr8Mh+BoQg8cQfIQIEaKgBBGEJjblykozLIpKts1u6Zk06URRqQbVoPRF1e10t1iTlHfe/eVDN9544w1b57dOveMP33HTRLtdh+C5rEsvosGYGL1XYZYnANAYI27k5IwaEf1HYQWvwzpmWWbGdSA9NCayMYaIiAUtJwlwkueuror05a989eU3vObV33vHF7/0jn/9I2//kytecM1MrGorPmistYRYCiLT+vqwnyS5mZxsd2NsgjaqDUYgEQ2lKCqCetFaNPhYR4UoDUF9pH/82KWud9GltnfFoxIePhKaIxcQXnSuyfYoYbHY+EGbKSZAjJiEExrXbi9OHgDCtbO5dc6OQGefbZLdCFAcjOVCgxR2cjI7h7zzUagfuFmq21pA7hrXvfKFrvuSHZHPHqKsftivffBPqoWPLjEuZ2yp5ZjzxLJrQu816ex1L+LeK1W9fLA89sGJmOevbG+9cR3iyu9VC39SuWS5rGNR2MZHjU2F6lVVJGL0KQYMIYp4FSLNc9Pq9XpZXfcLy85piLGq6qI70Z4gNKbda9tbPvS+h1/4shu6F1588evWV9buf/TAIytgTBMaH0MIAeCJACQiQUSw1srR4VH5Wgbn0w2Ap5XTdrtN7XabnZMnJB0gGrY2ta1uy9x26+2Df/f//Zfvtdbl/+R7vvtnZie7ZZ5lvTpIEB8aIm9iNNI0Q+/Xy4JTl6mqhFCDsqoZd68UIRHUIBJRIUZEQjJCmAjZVZDBiWZtcZ/rXXAxt654bLhwaBXMyfMw27ebk/OI4vBBLU/mYlihEIQQp7jjDjb1coRmdLZp7Z4INDFv07ORZPSFZvXATs562zg998t+8Om7pP/YS6l99XWm9dKub9praFc/5Nc+fFtYumvGdCypSgSKGWCW12H6lUnv2ueZ7ottbOznmrVPWTvBL0u33DgAXfmj8ug7jjAd9RqaCqHQGGNUDqqkUTlGDjHWdYgxaqkqG1IFY1RTVVqpqlACLrFJCgwcQuMZ1aTtdnP77V966I1vecsbJicmk//xG7/20Zm5aS9BoGkaX9dFAAihrusYQoibLhh30kkf+vIUbhh6ujLg6c+9Xg+Hw3EoDgDAe4dpykQklCSGq6ZJLnv2s7e/+nVv+M6PfuiDv/env/87n95+zoWZCiShrKqyrHzTRB9jQBE/9GDRmGDYQ0SLEatK5fGyQgiqMRpE1oAqQVFAQojqyNJiiAPfNMPz0J13vskvekzqQwvBHzub3Tl7ML1wVjl9oBktJCYnRyZpxCf7TL7rUtvatzXCdlUvicRkB2XnlIYWTjXN2h6Tn/PlOLpzH+Vnvcj0XtULkotiFCRtyA8EjX9U6iXHGecRW86H7pvyLa94rpm4HkHhs83aLZZafD13Xr4mK0t/Xp98935LB5g4jHxReZQ6qMZSIYKqCGCIGmIMIYhzOu5kooKIoBpEU8ZYDSvHmYsxigQVsqSqCt3uNN36iY8eu+ZFL072nnf+K/ffe88t/eW10vvgRapGVb2ISIxRRCRuGiBJkcg6rMuTCpP+3iG5bwQA9cmumE6nQyIFVlWCTQPQ6xE3TYMijicmprK7v3xH+R/+35/7VkBNf+j7v/s353fvHuYkLfEKTdOE8aZA8D42IZTDVNlVAYNXFeNLrIkkEqndeFoRUW0I0MQ4ntsQAYMGIQBqc8qH4miZo1Tnm95Fu8juOhqKo6ekWdiByY5t6nbNJFm+JH6FBZJXuenrrnO9F58lZg8rEDPaBsQTUCImq+5p+ge2p63ZR2J9aF9r4uJZ4W2gKg4xsRrNVuaz9piJc+cwa51sysE88+zrWlteeUlMnh2Z/G2h/4WEEnuNaV071FH/A1L85RfI38sQfRGgalgboeiVIPoIwQMElDIGgFgTSYxRbbCAETVSBBGn6ktsmqZGFGUGQhQFMaxRUUMgorS++aMfOPAtb/nW1521c0f4g9/97c9t2bKVvK+aOF6qqrFpGt0wHOXY6NiTewR+XXTAb0qDyoUFJ7OzQWIERmRZWVmpW60WE1VSFBVSqxXLojz6mb94zye1aU5hSTogbLAp6rKsa8RKmVuWqKlEBEsogTb6NzfAYKpq/PnMRNLokK0I1wBkvDYeGsWYVhggRdd8SsovtWSt/WLKX3m16T73i7H8/J2xueMyyq94luA12xi3e0dxG9id7IUIoukzrh9RPPAw+wMn+qeOre/ctba8DitHEI73MV378PrKh+5kvmMnpdt3u+T87ep2dUNsT0mYvIaSl5yVTO1OwWSzAXYoQbizWbo9AWuutK2rG4jho9J//+ci3JNZI8EXpgZpPIgXIYmE4qkRaUwoWo0gtpQqEsgBaq3HXcMaVQADSWIIEbkoihIxdSLeF8WwcM6kaZqaXq+L99xz++KnPv7xX9wyOz2/Wpb9GCtb13UzHGqdJOg3yxM2a1ee5G75umXDfKPyvJ7AgDDuiMBN0xiRDhkzCsvLyx5gB8JUYeeTGbew8JAAAG3dei6ORoVMT/fazI0MBtI4Z4ymisNTfpjnjXHBGSaWAkkziVSO+x9Dtjk/RBVdjCyqxCLGqDKK2B3QmbmmPXv13f0j9yJ3yVajzpvaW1/5XMxfpNL4LzWjOzKTpPsou8RGb1UlEhL2WYtHY7zvdoe33ZvQoc8fv+vIt/27X9x35ZtufNt7f/4Xf2vuk1/uPLK0dnh5Ohmltaa8fDLRuIpXQHv3iyfPffnZ4s9PNVgQQqupLa0U+2V0dyKaXED5Pm9M/Dj2P/SxauXWUmWlZ13n7Hxmz2dXT966msX1mtgLhRCIonjjo/E+SkqIpQLksNkNldqlbs5E2Uj1r5xzLWY2o5H4NFW0tp0Nh+WoaXw4ceIgjAvGztGqWvbOOZ8kSazrmrMss5vt2pIkiUePHn1yOlb8+/oAv54i+KvNczvdDUvGYxVApMQsZLYz03GTxGzYS10P4Nxzz23Pz893QxBmrv1otFbEmEKa2pa1ETAE3zR9nwMkTFEKDArQgAMPHhFwOFQ7btWLCoABEQwAgjqTKREq2rOYZ66xU9edaIbHjkGzlBLA0aZZ6Tpntqru3IHJ9hOxWVwQf3zapDMsZBeNWfyYDj/4+/2jf3V4aurgc773O86WTr543rOu2JpumXruyYXFO973qQ99+rqf+JE959/w4guLU8uPrjSj4Qv+7393+b5/9aMX/fx//8/v6CSTzRyk2xONacl+9FAo7k8pSS+A1sWAwndi87m/KFZu8tasrav3F2K2c6/NLt5frj5QKg+j+KgRFaWJilECoiJuJMKCB8QAhEHBA0hjUFg26zwCIoL33jqXJgAhnjgxWivLSmY7Wfvsc8+bmp2dN0VRl6q1FxEi6mZEwW7MWjndDH00Gj2V/vf3JrGvJwCfiv1oFwAp9FHabYwxEiJCBg1Ea8m0jBPJDIBviqIoy5IDEYFIHYmosRZq7MegiSKsrVU5IiiRJUQNY7GAJMIOAL1PwDaA4AHRI6RGKKpyKsQIQAwAnajTV5jes1ZDeXxRfT8ByxHZH47Fqd22vWVLDPMTnE0dBT18Quvj3rX8nw8W//yjzfC2C974uuzhL9yxOABc7ElKf/Trv3rfne+79f0Pfeimh6FJIQZZ/+K7/+qBlYcP+iYzxQu/6ztewpmFhXseuvcQxsUBwmpPk/bDsXgYgWgfu4sVVB8w4cvvr1Y+HhBGUeswRBPOR7t9J/DZn/HDOxChaUiDImqJIowooUQACzg2OvT0w4+IIGooYSGjimUI6kajWpwjxFivr68PnNOQpmRManh9vSyXlo6uilTBOZfkkCcBC02qJLBnraGGzVrpieEE9qGP8JUjvp52ADxz/gfnAKQAGPP8dEZMoopa1xiZNZOabKvlzMhoMEWl2lQiEgAA6ro2iZY4PBHqhXq17lZVVGtRiayD8cRKUSVC1OBHasCOJxyBEvtxOpWtAgMRJ1ZZi5C/MJ+8WkHCg1W9mJCqBaKGXExjMLs5Py/3kvaSbOZzMvzsB+u1m/e75sGX/pf/dMWOZ19x3i3v/+Adq4ceLe559O71+e48DldWRy7NFRjg0KEHqkRALbR0tD7UW971R1/8vf/125/dN3Fe4gcjOR5l6bMrx/bvcu0tz0061zpfUWG5urkZfPxRwkeNNqgQYSk29YvTySumTTb7vmb11gxdEOQQUMSgSERUNkpmXEOCOQD6J+y/x+AtEHjvAUawlIZmvWliFjmta6xUIcYYq6qqAXwZY6Rut5ubxpAzTQxEis0AFCoMPC5OYj6pNOxDFwD7T8OE1KcankwAQPMAGAAozM6ebvvVFcEwrjwjAICq4ChDIXSY0AlSWRAkooyIsg5zLsbk3S2cz8Gc4cnJZHNyURh7wlhVMY6ryzhI5KiRnQqbRIwtldU5tKDIYKmP1EDQeCHlV06Ab4HJgUE5iZLsde3zjEbrCcMy+MUjWeuxe8EfnNtzEZYr6yd/8Xt+/A8c2sb0JuPUxLwOPFY4les6kgzJhlY6LRW6ZpVCoYltWsnWeOX0xclDDzzUn3/2FenS2uqavfCCpRO7544vxeokYEKJQHKxyfcmIWaBjSfI8FxJ5vdw5/Kh9+tWxQAACNTjUk5VcuNEVo6qnGwMT0xUyYmwiFAi48lJxQi1qirnwVNnK+YZQG7yvDPlXNKmdiuEYOwJK2maWhuCqbmOxYgkE6HNysDOuHUeNc0017Oz7OfmaP6ph2H/gzmi8Uknc+bJQQcABQDjeJzUeOQCABKOJ/WlzIaMsDMa6rIfF5rleqZnEs9sTFHEGIKkmCcBgxrbKGPeYbIJqWdSZVYlFGE2ShmzMSzGsFr0yhzUOLXGsppEjXVBrCDZ89BtvdC2rmwkLj8Wm2UC5efbicuvwvT6LAZ3KkmW37l26I/2/M4vnv+CH3n7t975sS/c/Ht/8qt3nWNmsAaNjZAfRdIIqCHgafYPiBCxVkGRBhNREPVNqWiSuLxwtHqsOFS88sd++Pz1VlIc+/ztC7vb03vz2GQ9sjMjlaVj0pzsxyq83HWuupDzZ98W1j/9oFSHLWgQL0gMymCwhggCQKyKZjz+lUmV4kbLXqfEUYUNgc0ym0RA8A2qS9HEEHysa48sJuWOCUVoWq7WEbNmIgzkx+qN98pjdxZUquN8wOVl1dEIx/F9gP5T1P78QwDwqZ4C3agjHU8PgjnQUjG6yJ2NaZObWbbrMQZqEhho7cM6yQxUYicmclNj5lgNh6BkgIVIXOOQMGYOaiVNiNUjqVKizhglHrfDCEgAlATHAMQGlJHEWA2cSkgTTayAj1dQ66o9Lt9TxXrgY6CXpdMvmfN+rjK2+SzFmz5QLH0+nT1rdXJ+jj/8++/4/A47i7U0fkguRGBVUCwBwQNAhFoDRPVgwUHcEEsGI6IyshAEkMZCwha27t7devC9Ny0eic1wHri1nZKzM4mJMYz3+rXDz0t6+24w3dcNGdY+2PQ/0le/TAgozIJKJChAymSByCqTHWdYG6dMpEwKgRwwaaJEXpi8UuaiNFIGI+KwqoImiSVjEhcQqvJ43ZRdbVyjYC1hVXnXOAw4BiAAQA0bE0bbbTVFIZuoO0Mc41cLQHyjAYhPRcG7AKgDQHGD/QKkJCCkqVKDCAkAxnGBNlhVytRw01dvwcYAI8qSpMUWLTETi7PWovMjaKIKd1AzBSZUYatkWcg4FTaqbMYt0wwrsSUxyGIyEpuANU7RAhBZUD6pw+JcyracA8m+HeS2zZi0u1txT6KaHiNz6H+tL/7FSN3S/ts/evz33vUHn56oUCripkAWBASAAkswiFArbpZkAgBCgICoARE8BLBgMACCRxs91ppqmx/+4hfXuPQYY/B1K/F7MdnT0dh1SOlWynvP5t7VHdCpz+nwplvq4i6LUQkMIRAJqo5jHmgYIsp47hghKCEoiQI5YERVgqDIAJgCUNQAjWqTAmSOmTlaawJAQMBBNQwOupFKUsKREW1TA4AADWzUqGJzhh8QyxIQAI6PGfCpRrz+rY0S/jqAj880PHIA8gDsAdj3eqabCpGLxoqQA8AgYnJV2hCfpqIg0phg4JQEAGq7bltjjVEksnr0hfqK62baaMtFyAgUyRpjaTzWyiBajsSsxE6DTVWdATW5xNaEuI4BazwYJBWXgVoAG1ehHuzl7Nz5QNu2UDpng7hAFm6vB5+ofuBNxYXf+6a98WS5mFZpCOJ8RRgQKkCIWkCG40s1WIJBf/rFZMCggkEAgx7GUxIsKDokJRBqpdZWrSCv+jf/8rJyttekX7qHdqTtvUkQswVpWwug8wjLg+8tT31YWasoGCMoO/U2M8AcxZEKWyB2QMyKjIaYiEzCRMjIhogxEBuIFECRlQ1CqJoYo2U2CmMHFaqwWvTQrHiEEdgsYxPRGVUiNdxog4ioKQBaGRdrjdKUYp1TBzrQgQJHX2l4Avwtm5qbv6fRwXPj3ijjeb1jo2Os90GPO6roVTGRDWVaBA0Ako4HD1ooZW3IVdauUzfs+XF3jgpMjdGDogeSBJQwujQFyNBQ4lRRI6IFBFElAiArHsgYst44MkARjBIrkUoCwdN5Jp3s2FZy2BfHssC8prj22Ti46dXc+5aWrzNAgjWCtdvrlbs7vYlq5ZFjy8ePPNYfjoq6IOdxY09HkG5srmL5FBtTwrjBT7bxvvn/K0C16MNKGNXnbT93cnD8+PJ9n/jMWgfD5JVRhjl4xwK8ktiVTzYrH18TWUuRbQSv+9J0e+EpHm38Cps0tAAjQICIGGoUHwRCBFQClIigHgAcBxEksR6FHIpWNnUA6OsqiKYEsA4mSUBUycOUSdqNG6yTn2wVgtEl4ytM0UCFJaJsFtS3VIm6qoO+IMOUzMEKbN53Go9/14VxpT7B33C2CP8d9Uaz8Y5tANro14AegAWA2tBj0xn74TbG3HNUZadqDACqGgQAbCiNlY/BNeM+KrEt3KEszQgSjBFalrPcpj3wjW+jaTtkm6hJcjVJIpg4JZeqJEScgEKCFFJQTbuCvSmEqfPZ7brBTr7gFWbiVWeZ/OwvlysPs7GioM1jWK9Y0LDDpGdnSK37wui2T1+y9579t+8/9KcfeseBSd/GhkwdkbQAAA92A2QlBDAIUAtAVACzOTAaNkEXANBugNYCgIJigyxOUx6dXJM7b//QUrl+ItipebxUYd+M2q1D40afaPof+nxcvzcjix5UJtXMfWe287uexxPPn2PTTiFar40pVVRUmYAI2ZgEyeVCzjKP84yQTEpqCJCNgq1sqDJI2i10rWhJk5ASMpOIDc4HwQahBkDyAIlllgzIBoAAAUiEzbg8FY0qNQDgGsAMACqoTwNwgwZ1+JUMqF/PUBwCAJ4LYEcAvAAgswAmg551EM0IQDNQCvnYRTA+JNvg6FIFMhRVMlUVB2BqAyQBxuGzGRBeAooeou0lpjXJSaeXQJs1xb4frrbBbQkQIIKyKmMrSJIwuQ5hOhWoM4mmvSVJJ+ckme2ynZkitzVXaXejdo0IFYzVrTL8+Ifj6FavcdghkwxjFV/IvSuvySZv+PJw8Int+2+6omqq7s/+4I++vbjtoRN1lmlV1VoCKsBm+zKhEgAQScpx0Pn0Q5whyWZBDyJJtgHZDFJEQO1qZGchSbdtSV/5k//shi3tbH7n2392eodtXXZLWP7Qp5v1L7XUco0+AJn0dTjz4ms4uy6VkDSG/RBCv6/N8oriiRMgp45rs7gaq0E/SNHHUJWoTYVaFSCeEATBaKrMAwgnUpM4g9QbaLO2VJfLFfsqFNzk0KICRpKDUgU0zn7Jg7OamhpKGWcyACaqVG2ACUtUBpQKMDIMJYc2FUBSQt8bAOkAhIfHobq/to+M+buI3ocf/8LkFAADrJspADcDPQsAYCNowHGTR6xKhQxgCIBNWQUGaobACjDAHMANIcdWDnB3UTSTAK2rsy3bjQJaQ2FQNWFVV61A6F7iJs/fgXbrJJt2W6BtjSQtoG7KaatrYy9X7SXoUoNgQTRSjKgKEjCGAApZAHcdd18+xcnM7XHtzntj8WiJtn5vNfj8g8yHT+Bo8TuHo51lDHHl6LEKoVJEUoRKEVqqIFBCpYAqeFoUP0kEq2KGqKdBCJUCIJSA0IJKm3xCDq3cU3zX89+4e/f5e6//zR/7yZ9/QQh7o1/+wv64/JhjMrnG9i6bT10N7Ssup+TqJAYbMDauITOFND2N2ewO1PMiUQiYeQ89Xxrt9zGulSqjAWo/KFQjhdEpqteXpV6/s+439/i15XNMB3uYSMp2Um2OJ7ujtf39xeVWC1wfQWAIDNDWbsG+hiZaABsh5TQDlFJRADXLxpxSqJoMAPtV7ldgqG0AbQBwGcCfAND5MUF5gDMstb8lAz5htseVAFgC4CqAyQBsyPN8D7S27LT5VKpofRQ5LHVfMUbvg68B42Y2hd0IlkdVSsGwNZQYZWNgnChQh0qvyrfsaiFvu6NZfSRj4852rR09cq1c1BRRq8ficGkbJFu2GDOznXnnbnEXZFFSVRiPoVYBBIMRIYqGSKBMgAjICCqgGhWAQNjAEGN/UZtDy6CnTiGdWAh68nC1emzwptclDeHgtnf+/l293vlYNCvNuE/WeLp6sdE1CyCh8rSOpwin556gbgIQkQSg0hwAFFJsQaUAObDWti2aNQ3AtfvOPbs68Eh3mqg1Z3RqG/O2OTQ7zsLk3AnhKZUoFtDguCXS4wWtGoB0LNo3oY7IqAQYgOIRkoOHo394ITYnjkp1ctokbotJO4VVWYtN8+Bo8Niq+P4+7u7YlkzQzdVj9wJgEGRfhBA8RN8ghXGdewPYgIYERdVh0zTqnKIBR8Om0XnLWcckaYOxieC18Q5WqVkf1usrJYDf0An9V2NB8zfQD3kOwDwK09SGwADRaEu5NbJuSy+b2Zm4c3qCnRGIYOBTXpsyuiyORKsYJSAwqQY0TAwRwDJZq2KMYsLKlgCwQo1doXO2pvnZJ+OgcGTtduEdKUKi4z0eGJHlGIsiQlYEwYIIIwJEAY1RmRAMKkVFRUSwRBvO8AgaFRkMoAkqnsTTJNjp1GatadBRj+m4lfBQs3O3/uiv/qd//9Dhx973vnf+1u1n9ZKkXBp3sVIQHDPi4+z2xEcVdSMHQksgzbA441eooBUopIhQaJ51dHH1Yfnx3/7vr93+8MLO4jePNDuSzs4tQtsnVWe6ENs2RPIaGiAEHSMOIogCEBAgEFqMiKqAOs7BUiVVoghKEJWjD4B1xSg+AYCO0HSqOpMEhSlJNLeYLkq5clHSuQCVYBbMgMgiAqp3JnrAIKhNQG0UUkQDKgAKDOCSjnEZMYZATjndkbW3JQBZIWEYEcUjN4/J8PA9IzmQeVNl3NTro7RchuXB100H3LBy3BkvuxMg3Wpb6WZf5IgYEVAVFCNgjE0TIAFAAK0RtaXOWFUCsDaxxiz6onl2kk1tN52zu5yniTb+6Gi9PiUSc6v2hnz+pdvAbesqTrYVu0bQGFC2IpYACRUQQUQVREQVAYEQUMZ8pKCAjGDWDawdFn/gS2H5zqXo11aARhOUtIp8avmF7/3Na2+79QsP/Pm//bm/TNMJkGbkK0AdW7/lRrfoMQCfwICPb49mQLrZXzA/rYkr5pBBmqVYFEfxdd/+nefsveaq573zx/75525MZp/rG48DbVa3WjuzHc22czA5fyuaXVlU4wE9AbFCEEQGVQVARUZmAAJFwU0vSIPQBAQfScUz+XWi1ZXQLN/SLH38QT9YmFXrtrgWd12rXUCE9VAef+/aoYNztucsAHggb9DHEjBGbCJAChGUMhXj1Bp1gKyG/MYYzhYY0/gijDD42ECMgDEChArqagBQdACaw2MGjF+NAfHv6nieBUgiAG2FriGIdgQAIwBwmZiO6mlmFVVkRAHIQEERAXWAFHxZewKU0Bq7aFoAcGg08hlA6gDSbflM72yTzWSgtOzL5bM43U0SUwNqOsTJDLrOBLlejpxPCU/2hKbalidbSL1coOUEEgIFFYyiPhIiHzf26Cfi8s1fqJbvS1wXORJfw9klz83bL33Yh7vetnbXr1/e2yd1OapKNKFGqCtERUAtvqoR8ngPwew0E57Zdh1OgzFRoZZIVjbrXMIKP8vt3PP27pa37Ih0zifqUx/+nF9/CNjFWTWTz0myfVdT77oJH6ciBE9oCIkdAFKDUhYEgxHE9SFAvw+6vgp+dQRxsKpxOIihqGIoCmhq5BSPqT/k2NlI6A6FwfKjg9FSA3VTAZRn5blVVfTMHgEUhgA2FyuaUgqATpVqKFU3O12oUgoAsaawBmVs5blygVICCgPJAPpiAOIyQLNhhISvZYTg39ENgwDA82O3C3oAjgDUgx427WhUFdORkmRKCWTkxq1tCcZ0SUEtm4xi2YSmKkMRQLg9FpeUJXmnbdmxKqkhBypmUJfLW1x7zhHkmTJVADAOxIoRQLEqLlNMZgz1tkkyOW9aW2asnZ5B3L4l4LaewuQy4vF3Vot/dgTwqGOJZVPzDenU85/H+UvbkfJ7Se78bRj9/sn1ZrHOsRgGLBrUekg2jAF4Wgfb8AFWG2B7nBGzjc+qCeVIglBpBikqKGYA0Gm79P5TB5t/+wu//vyJmYkL3vk9b/rCf5m6/CfPaeSCdePWPimDD34yjm63kEjRrONzXOei19npN7cktkfEgyWtjy1q/dhx1ZOLvlw+RXGtL00xQq1rkCaiCYYNAGKQiBpMHTy6eCoOF9ux00oYE41NJWTqEXoRKdfXRuwjCNkeRw7BpdGmMVGC6nFplQFAA5UgotYA0hAFGo0Bx4ACsA59ADUAkQD0xJjxwt/ECua/hyOaOhs+wE0nZA01ZFkGhkiaGjBJEBSjNBjEk0TGqDVYIIiqVkQjymrQptvKbJWG2G/Ydzpiq9qHNY11EWNhAjYFYW0tcBSVBmKtEDxGbgybAICRkBsgrAul0XFolvZLcfgev/rwgTB8aFGbQ97YwSLCws3Nqc9mNoWBr+U5aX7Jdbb3slYjKSsBouHHoDywvnNmqVkZeQUGBtKCMBDUasFjgKjjLoKAASwAMI09fRYsGNw0+HK0gFDr2A849nmyClkl2wayppPgxddf84KJB4/hsxbrZzsAa6PnraazazkOjz0a1o6nSRKPxOHKTNptn2R97KZm/SMf8Su3flqKew7o6NGT6E8MEFfF2iKALaOlCsHUEbAKEGtB8Q1IE1RC5aEfLITCV/2hxEaclwpFasn80EOT5y5ZH8bQMy7RZNw2tYmogCQB6xBIAhBFQIw1UbTM0aQkw7ovEeroAcQACAPo4lcOuP66O6Lh8c5XgMcBdASgBUDsAmBd11rXOaRdgICoShTDuDuoIgBEcMqIUkSKDhCMq7lfUKnNeoi9lHrq2pZTm+RqOGEsTKwHUjeMlsAANATeo4aGSQpS71G8JwkVNXWF0AhqYwAjIDVDxMEjWi/eVa8/dFAGByMnZePrcJZLt9+YzN4418DWYExADWgV0qrbWbngP/zEzODYqeVjjz1SxWjE8Di7BcBCgADj+K/dgB1CGIvmDV0wagtJN8NxAAYNKCYqZDVSFthOZln+6Jc+5pulZvH6df/C3UuDvUQEggS5ajZpkpkDcfTQipE1AvL3N4NHbvUrdx/C+khEVxhk36BUkaguCeoRaONRaw/YVAi+puBrgqZkrEuKDZL1feW+xKiYODY5GSZiptSEMCyj79eFTyRrB8sJOa1JqlgHIIlIEixRrIliRBQhEkMkwz5LqNciA8gpgFgAyAgAhk/smPA3GnD494kFf0Vy4ggASgCdhErquq2+Qa1rAJ+RZogaESVi0HHaclDfcuCYTZFqQ1VHuV4RzhNHDtgAAKhjAsqYISqrVxQrpIG8Rq8hBglRlWScFYgag8ZGwXtrmiKEWlQ8q8YasQhKAdjASIfwZrvllfswvWIF4cSjWh/sEU8mqilF4He/70OfvP3QF49N7tjFna1zsLa+FjJQaJDFANNmRGTsHwxgToMR0EHUcUQkQAZMFsYRgwiRJtvddHl4FHZccMHMhXsum42fuHXihoG+fIJkekQwehCbexNLbk7dNnDp8I5y7SBzUq9L3QcwtXAMRYx1aWJVo/U1ceMj+8aIjwS+DhqialRD0Y/ZSiJpbAI0XrHppWYCmIyM+7OqokghMgp1LQQdTXs2NapYO1QT01hTeALoBogQ+iy+XhMDlVgAOTEGW3wKxvsbFy39XQH4teoCdAIAAbqAGwq5porJhp+CiSQiimu3samqIMawDUHyHACrKmTttvOIto6uBmrKGBCQJGjTNFGdYUFBABBEVUQNoIIq0YsRQFRFikHqWKH6gBACikQ0HlGjj2L2cfusV9ip1zcQqg/5/vs/5dfv2OPa81OKszlhRygOd/zA9+PlN7783KNHDh4fHF2OqowJRq2R1AGCAcUAiY7dW3w6EI+QaA4ezTjyARkAigr12r1k//Ld4YaXvX7ba/7Vj3zbLX/6p/vfit1Xnod0CYDoIYaH/mdx/D2ecG0XJ+d2KO0e8sVDJ6hZrgDLgN5XAFVJWAaF2iuFWhsvFL2oxko0KkGoUYMXjdGKRNLoPYdgQhMDKiVqGvGjqDaocSgour4CI53KsO0CA7OpmqZJfAIFjICJhImUEHV9MyWrIrFQCo79d9p9PCvmyUv+phnTX4+E1Cf8vON0lvUIBFqoU4q907HS06hFYy0hs1FVDCHV0LJkh8MGu11bx0RCGJRl6pVtaoykUmrjgRJLgOqR1CCJACgRxRGiEGloUCOhxoo4RGxEICqBUQZixQBr4PFGM331OaZ32c310vs/JYMvRZOWmaA5y2Tn5sEn0+hmTzZFf/8jjz1476duXk4iQTedsCF6YIjKSBpgU/PzaMDgBgOCg+p0PmCiQkaD6VmXHV3bH7/t+/7pLnfWzp3n7dt73vwHb+k+b4Av6UBoDYwZfSoWH1uEcPRBqY451GoPty9ZUTjyubj2YAcZK1TfIIWIGD1RFIQQiENNxnvyQUhCQRoCSbQkUawVQVQwAPU4jI3EzA1iE0NZKoPUwSmUUHbTyHWWWYqR2VpCBxBCqoheERH6iDoBAA2RcrmiZ+j8cPQrQSZfy+XyjcgHfDLt4iQAHjmdDd1CUxpJ8nGKd9xISI15zlYVK2aRkqXVpdQRmSLP6yKEmHFm2Cg7zlIj1kQbQb1vbLQxiEYwHgmtApFU2EQgiYEkBtJYoghBVB1ncaiiVQuRrLIpILo3plteNoQwend1/IPAaWVEuR9DPeeyiRnguVyhlS+utO45cM/+fT/4gxM7r7t69gu3fPj4JE0kklhwAUFBNnTasVGCp/8L4LTLOSBbFZtYzqrharjghjft+d7/8P/87lSnNfjkq17y2W8182+b8zLdkMo97L/46ar4UkQpA0p5KNSrl9ve+c4w3uRP3JFgBjVyCKQhIsaIFGvyEcYjfuKGJBBCVBqrORqtBR9jDYiNNFmTkbFA0QAzEbNCq4VQQEWz5BnbuSOXovpQlyaSEU4ShM2saE+kDZHyyopsGpsOQI48tcj9W9eK/H1qQp7qBOKm43EBQAhOKcwBrBPJgEhGG8XkLQAQzTCJke2ktQAZeGPCZhem9bBerodQFqplADMKo9HAr+f1aIgjz843RHFATWiQhDbSheqNd0YUJhJPJA2mSgAaAaRxSZzTxDG71oE4+vIphFUAgAZDfdzSqUd8/5EIUVRimM46W8/Nps498vk7477nX3Xl86978VaCmmFwHOp62U0It3qiaS65S1QoSYVcarmj1qRaOyOSipbUyhL7CCzBK77zTVfnnSz5y5/5z597XueC50zFOBmhjiVC+UA9OlAiVMKsBIwntFl6SEZ3Wea86zmNKF4wRATQiBQjNiESBUJUpwkRoiDiRvlkBoQtISIhRB2IFD739RIUA0EckmoZqsSvra1VdVo3zKxVUUXESkOSsMucqYik3Dh+M5KDiEoACnMACwB6+HGm23Qy/52H13yjyjIBAHByxw7YnA+nqthVJYAu+BTVg0dOUyIiFV4pqgrKJElcLnnCDYMmGowxDRSAMJGm0AGkLhlIIMPgAMBDxKCRSIVIaOM9ImqNqGOxGCAqsQGE0gDuEpjca3r7vhTWv3CcZLmjxkUQmFe79Qbbe/HWCPONTeOX6tUvztt86/PWw7P233PXfUcWF1de9V9/9sbdr3rlxaOFxUcHiwuIGhkbYUfONKNVxmqVMZDrxxFMkHVgMfved/zGD/+zn/rp7//Uh//qk3NfuGv9RbcduJbq0pwEODFjW3NJbBLHFh/ScGigsW8Baci+nkCmSZPN3+NHd40SKiqFxiPFQCSBNBKiKKIIRmmIJIwjT2pzN7aGEAGJ2IowVRXYTqdVicRatYwmxtznJukmmXPOjsKoLr2vsywzkSKnMUokEkxTwKaBhkittULdkZpF0P5Xst3fa47w17M1x5PrReXo0aOwA3ZAPVtvAL0H0g4oItQCgEakLsvSixCdtffsWWogq6p+GKisi5Q+xthqbW21tVSMSbR+aWkIvZ5orgjFONDFVAueTgAYv4sqQnRUY6EZonioMfpWVAQ/YBz1tRq2VC1yoKnIM6933VeeLeaCitXfJ8N72pS29pG7mNW77ODSpJWRnTv3rL3nbdl+3tqnPnfbyds/d+zsvVd1yqouFh+7X6655NkzcX6i6LQm05f9+Pd+36+/9Ud+fc5w6/Krr3xpt5XlV3zq3ovOvePBfdt6E+dWtlU8UJf7H9DyvotscukFqs96rTPlO6rj70ebD53UVIrEwlDBhjEgCGKiiF4JUBRzaag+nehx+u5rhptbX20UfUXm6CYm0lSTNGknWVWRG41ODW3HYs/0Wq7TarVaU+WpU0dXhsPhqGkaMzU1lcSiYACIBD0FGAIR6cLCE0AnfxtD4x+qOdGGq6YPRVFot9uFSitwztFoNIroXHn8uIayPEnd+fns4L33yuLisaLV2tKsyyBOZFO9JCFT17UXSsg5pAaxMcaQqiIlpGABwNuN8qDNwmwlVUVWTzqOQhAoY+KInZCZtOnUsVAcI3QEoc5fn2996bOUr/GA9X2xuTcFSPfa9HwnMYEI0ibunM/Jxf4jnz35xQ986H37b7llvQmg26+6shfbLnZXj/RueOu3v+Hqf/q91//nX/6PH5mYmV3as2/P/Opn7sTJx44Okv/+p/Gyew49a6aVboNIasXbaaaZFcGl4+qPbaV0bo5ke8Y23CXNYeboGZnRGni4WD0cbD7yRlRMVHUkElEtWAhgATFsACBHbCHIRpOm8RRSJlUfmFs5WmNCoECE3OtNTsTYBK++ue++e8vFxaNNmk7TqWao9XrerK1pnechVlWKgYeCiOqck36//2T3ijydWnN8zWKlXbt2YdM0LCI0HoY3Ac6Jm5lJs927d3eOLSyYP/rjP/ueS5/9rN57/+o9R3bNzBjnkkwdk68wOhfVinV1JGgaDFnGVkQEAFCNkjSGRA0BeBARSjUjUWLrhKxXMgmQFTQKyqtVsaYORaJmNyZbX/g8bb2ENMLtfu02Q4YuwfbloIongI+tMq7kTJ08hGx2WGw7Z2V970Wmfc7ZJpl0xxcTe3w5n896U1tVdx44eeozZ33ijsnLiub8s5b6F1y/uH71RXfed8WOQ4d3psamnpN4GMPDI4PDCYGpacLpx6Q5vKywtJ2T7Vsx2QUc+4cUT42Y+481S8eGTAMEZEGNhEY9iloL4I2itQAxONXMEDp8/AEUIWvBqJpojGKa5i2sfQBjYpYlzjnnTDujh+473PzCr/76K77ze77nmj/6g9/ef9kFl7eSBEyrVVHTtABxHcatOsYi+AwA4tOxNQd8tb4wAIB5nnPTNBt1IW2enKRENU2cy/KJicneqYVj9G3f9d2vvuTyy970wb987ydS5wbtdreTpK2WM+yYnRX0QGTZ+36VZRk1TYMAgKkqslEyRtEYg8TMwkKGhI1YQ4SWBI01xtiACVgIGJrui7n7rFeYiTciqH5eqs86tPYym14hEvB+DHf9ZbX2gTti/67UJtjitMustiWazanZvhvo/Is4vyo3JjnRX1o772Sx+yOf+siX3zp99rdedXz48l2HFnfPk9nVM52uuFxPkpy8Q8rPfrhZ/8QBCQ93XZLMqtm+zeTb7tfB/kXR4zuN3T1P9qwByKkFbZZLi6NgnQoZCSZEjoCKViOOXd+sTGgDxI0u9jkANqqYJAkxsymKULfbSWZM4shZm+dZO0lcu9XKksHqaJj13ORP/7t//9/6g/7Kh9//l1+en9/WqusKnSM0xhtmVu+9jnGNutEbRp/CF/y0A+CZBeuwC3ZRmZQmxkiqXcpzbxBza601SeIMUeCpLdu7R44cPvnq173hzdt37S7+8Hd/58tnnXWOYdDMGI1jO4bBGGbvKYRQKlGeGAMIxiAGC6oenSSEgpxYNIjIBMamCNZSwobBtilmEmJ6Nc9e+jo38Waj0X4+FJ8G9ni1aV2joHgH+Vv/vFz58DqZlQqhvK8eHjyh5RFLqhNCM6geDIIZsunfXK/cNG2zzj6bX7lCdGQdmqXzuX1xR00rgPerAKt3SvP5T4bhLZ9o1m9vrOmvYxw8FMujXctmK/P2neB2PRKqA49i+fBebl24w2Xbj8d6cSA4tKAajQ3jJn+kkRnRCBArBQMQowOjBg0Y1NRglmWmrpGtRSCKIUmSrghSmqbGGOYsSxOT5XrHFz+z/D/f/d5/Nr9jxzU//7P/4VdtmsXQ+IDY+BBCjDFqkiSwOahGVWF6elr7/f4mwXxd9L+vV2uOv6Y122HY7A/dagVKkoRFhMZzycYW8vR0Vz/2gQ8fOHrk2O0ve9kNP/D8l9xwzsLCQp12UmvSNLfWOGNMwszcaiVtY0y01jBzy4Rg2CVCzjnylo1xljkaTqMxuQolJmNmdDlmKaNJL3WdC16TTb2GkflDUrwfIOrzuXddTTZ8Mpbvf1e98IEB+xNrPFgpqByZRJu7fX3okRiPBKZASLRu3OCTfvWmu/3qke1gtk5GnJkRmPxsNXrotjj69NBAbTRYIMCDWjx2j64/0mXWRqpQSawKaJbfU5266daw9gkloee22td6Bf+pavDRDpqJN2XbbpwxrTljkryFnCXRJWjYpMwmi2xEhIxYZssm2MCSjFtohGA4z8mWZVmnaZo617au7axz1qYpu6TVyhYWTxTXvPBl51x22WXf8djBR279/Gc/faTVbjfG8Onv2LyRvV7vNLt57+mreTvgaTonZNwdFXZgyAOpOnJO8MwxXeNGV4bJONftdTtZ0qJrX3T9a/defJH59V/8zzefvXdvy5LLFSM01Wg9RgDnXOZ91aiyZBmmiDEqM6oxmDqypJ6EhGySWstkAci2lZ3T2DnL687vznd8VypN9v6qeF+ulL4gzV5SAhUfapbfc1MzvF3ZDIOGSADUgOjIj+g61770NWbqxo5Qb9Xy2ueawcc/HZe+OMetqeeY7Ko5NduHLCsPxvLQiTBarNH3p1w+O620Zauxs6Xq+sOhOTliKhxqDApRHJcPVKMjarPhWbaz5xw259zVLN37ALr7LnLJpXs53fWANgdLV40MA3hw6kgZnEUAQSWHjhmtScGiMBoDzM6oEnpfNRMTE5NExtRFM2y1so7NWu2k1aLPf+qmUz/3S//9+845d/f17/7D3/+d4Wh9zRjSclQ14/Fw4zkhzCwiIpst2s4Y1fXkRAOEp9mckCf0CmnNt2gsfh1ZG0+PaEDcHFKI1hlnOr0e3/7F24+99IaXXbTnvHNfuD6KX7jl5o88dvZZZ0+Xg2LU768Nk06vZYksZ47L4dqg348FgJE8t22rShx5I3yJnJKxJJLkFl3KtjVVDrd8Z3f3GzuQTvxlufhetogvM+3XjEjX/twvvvu2UOwHTspBU4n3NdSx1gtdvvNNbserXsDtl1kC9xA093wwrvzVPbF4CJjgAszPupLS5ycibAnyE1odXTS6eDzo0oI0R1ukNE/JObtd57x5Nm4YR+snQ12tq6/7MVSZzfQAVAtNrFZ2m9a5e/LZc+9uRncfqE4euMzmz97dmtny5bo+KM54YEGwBhARIhl1zAjMaFOkaAwDgF9ZKYZFUTa92Ymu404HLHETyxoYdWZqbnZ1eX19YueuLT/8Yz/8kyunTj74C//vv//jqe5U6WuvMVZNCHXwXkXVCJHo2tpa3OhEi9ZaGQ6HT/b/PS3dME8wQDqdzhkAFHp8SM0YgONO+ZadYSsg1rrEX37lldfPzc23fvuXfvmWbeecE63h1KaOAciiCIz6a+unTlVlu53bTiebsEqEKKSkhGpNatARGk5ATaZJ5gQnvq+19c1tocl3FQ+/26Ga1+bb37gO/tSfjk7+2b1iDgBJPZFg75ps8rJnpZ0Lb+jsfNFVPHP9JOn0cY0HPhr7H7qpWbl1QXWxwRhng5l7aTp7/RaBeVEJOXLLmoQP1f1jyxSWVyGs3R/qg8sIj2VMsN2kF17spp61N5/YsSeZ2Lo76c0tS7lSgvYPYFzsN8Ol3Uln974ku+jLsb57P9u7L0jzy85j2XqfXz8iSa8hg+glBbQIapXEEsXIwBAxyfMMgHF1tV+hoLYmktxZlxiT2KmJ2SkFrB48eFB//Cd+8k2XXbrv+e/6oz/4vaUTp04yYijLqlGNwXsfxwB8wpgGBQBIkiT2+/2v1qTy6WsFdzodCiGwagrWRmJm8t7g5phWYwwZw4wIZmpiwn7utjuOvuC668/fe+H5L3Kt7sH3vOvPH5iZmdJTy6fW6qYqVk6tr09MTLW2bp2eVK18q5UmBsWKGkrZucwYEgboqstTtin5Yfu7si2vmQxm7k+KU+8yxpo35dvfOFBZ/oP1Q3/yKMMxNKZaxWrUJmu6kVMV8f0Qlh/yg7s/WB376Ieb5duPhXqhZhr1iFuXmtb5r3KzN5wtdD5KVEQgq2gmyM3Mpu1ORC3XAdcH0a/dI8WhW+ulex/15f41DAfXwZ8cSdMvpamXtF47wXG1Qz14zIS1hap/dG/aOXdfMrHv7qZ/9/6wcs+l2ZYrd6Sd3j1h/ZBzGUSWANYiWcbEGAKyaP7/9t48Ss6zuhO+9z7P8y61dFcvUndLLcuyLK94IRhjjFnMDBAgMOQEkgyThSUwzJmQTIDzTeD7kpzvfMnMJEMCZ2ZIwjIhCQzgsAYmQMDGYMALsi0j21iyZUuyJXW3Wr1UV9W7Pc+99/ujqqSWkMxwDsZ2ontOn66uru56631/711/916LRM5hUYRq8+aN483xerN9rNPOulnXa+mDR13prsKVVz/38je96Tfe2jm2+Mj7/vS9n2o2GoUvK2YufNlf+cDGqHivUpbKIeSiqkhESkTa7XbXA+8puynpDACMceADUn+imMEoikhVyFoxzhkCG5ngAzQbDd04fc6We+69bx85m4W8KOI4xsPzh7ubZ7eMj7bqk2jAKRvMV7prtUZzJCYiY40lQmsYrHORi9iPviqdfEHd563P6drfO0H7i+nka9eqavkj3Uc/+VijediQlquS94Ix1aLXtTt9tv+20H7kNl5+6H5bHKw46lq0BYFVUZYNJpl6TbzhtVt9OA+kFEJDBIgMoFaUNkF0bsOlzZ3SuafH2hXkHDEqDiMs3srtA7tCb//3Q3Xw+6H7SGawTcZAKQqxc7JIvLqvWHnkgmh868X1xsV3hcV798fj+y409pIZ1PpuY/dbQ6SoKmSR0aK1ii6KXF6WHWtjUx9tTkUuro20RuvH2oudRtSIRybHRq581tXng40nt27dNnHHLbd886G99x9ARO/L0nPuqzKUARFDWSKr5ixSSAhBBlsHwForg33BP0RAeUprwFarhd57oxpRkvS3o4sYMsZQHCv2fbaYiJTEkhkbGW8uzc0d/do3br39GVc+Y/t7fved74ldWnzmMzd8/5LzdtTrzaQRvPcAIJF1CVgJeSllrZ42IlUy1lhjIodaRdePbrq6EZLmP2L5rZQi96+i2quXgOc+Vh35wrG4Nqdqq0y5KFEqZhPAFCUJ+A3O2iZFEAXLBkU9AgdkQSDMQyXb0W3cZOBcHPQjKQBQnw0gqgz3aW/nriLbKw6zSgEqlErQlzFRSDHmmEzpEhcAAIgNckrMYiCO6lTW0mxvWD54XtzafEFjesftxf57jk63jmyZ2HreaGTdAvBKMOTJWqQBzYoRy3ZZ5pOtsU3SZ7sxWGOmJzfWb/vurd1//x/e8fLfedd/+LOpDdPhPe9+918sHtn/0Gh9pFZURenLqqq4CCLCZQmiWkh/T0gqIWTHTTAR6VhvDNZgDZ7qADwJhCMjIwMAxliWivV6SSIpOeeH61vJWjSIEQGQQwz+kX3797e77eKNv/Hm12dZvrr73h/sObY4d3jj9KYpDiG0O1knJgtxbNIoqtU6neW1xCXOprYWG2cgAjuV1iZ6+ZpfueKSNYpUn9+NrmsDHPlwfuR/QzTaCeCLQnzhRauKez5QCCWiREFsF3yRq/GqgQRVCAwGRIlAgC1QamJ3EcSXxUqRDq0PEgACLUf22Je5e2Obw/IqVJ2CKGfiypMtcyQOBCHHXNQAlhSFfuUalRQ4kKCAhsz47t5i+eB5tclN26J0c3XVz3S2vfZV5z24+/uHctaObThAg4TGkBqjy8vLyxvHp6ZMHNVJjPdlnsXGUnOktWHrBZdNmvrIxnqz4VsjzfE9u3fffPst334wbdZVVQ37UHqvHoCFuWREDH0A5sc3piMiGGP06bQr7iQAhhBINR6QUmvkXIX9da1oAACJCK1FF5R58ciRuYwrJiC5e/f9Dx1b7eQujhtkE+d9lTcbjVYjjZtxGtctOQRjTC1tpO2l+aV6vV6LkjRu1hq0WmL18ne940oTJVHzBwdahS97X+ge/AbEUV55n3UhFILqK5VQaGAkYu9JPPkgiCooaoGBUVgByAKRU3F1TBIWMZea+IJRteMKINQfTQBIZOdJD363XLszM9wuVEpF9gUZz+g5IEtFyoooEAx6JxKh0+BUQCOCCFUtawQNW4zUij29I/u3jsyeQ90190DV3fusX/7li+YXVw712suFTRskAtheah9rjLZajcbopHUxJLW03hptTbYmJsZHWuONxobp2drIyOTc3NzCn733T/7m0X37H0uaJiweObaC1oIBcKpl5b1n1X4AMtiU9EMAtD2rTz8ArvX3BSOWgFiCcw0iCsZai8YYJCISsQTA/ujc6rECGaZbG5rjkxN1FUl/57f//RteeP0LX3rvA3v2+FBKI40jF0UGQEnVUOWrAlXVxDWrmOjiylJ24y3fWHnuS19x2Y5LLtyx76Zv7aqOLtk7i4V7fGwyUQwZgUdmCaqMToWD4UAqZFEhWKzQSYysvs+uIQFWB0BWMbaEJnhvL44a506B3UyAgNi3v2ws7FP/gztk7T4mLArwuUcKJVIIyCJEnomCAwBJnfRvSAtk+sPbCRwa55DFKFiLReqKYz5fdGnNHtz/2KGLXnjd5h7w2Mf/5q93L6+2O5NjG1ES56KkXgckdc5F9XqtWWs26xunZ2Za05vOOTK/XL3tLW98zQXbz5m987bbdtbipHTgUJX94sKxtSiK2BgwIsIiokMAioh472W4K46I9HDv8KlBCDwVo+CTRrWu3xfczycpGWMohAAiMfWjYTHMXDUazcb4xOTk+PjIRJrWUmMQu51eds1zr3ne1q1bW9++9Y69sXH+2NGji+3O2mqv22kX3SrPsjKv1eoGAOzFl13WfO//+MAbFSn6zTe87eOT9QQO22wuA+rZKmCbJLOKWqr6EnzwbENQ5UDKWpIokngquUKUZGBYBQCcGiJA69BEKuy2ROnkdogvNCqkSIAAWFryu7R7294qPyCqRY80FyRfELFBJ6VR9kRcEQlxpOwADLJ6ERWLwDYSQFSwVtUYqGMSdWoumwvdxdp4y/ztB/7y9rFzt6Z//L73vWHHxRev3XvP7mNpPaFsrZ0XQapQlEXFoVwrct6ybce5jx1e7P3cq15xxSUXnf/Mj//Vhz/aXlk6RoHZJqbuYorrozUHXJb9Gr1onufivWVrVZhZmFkQUZ1zAgAw8AH16QLA4/uCfd2vA2B/Y3qfaRFTf8ZkirWaTSi2UUzWCIgag25stFV/4L77Dk9MbAhXX/PsV1IUr957396l1sS4IUKuxUnUaDYaI62RkdWVZSKXTr3+TW94w/YdO/7lJz7+yf9hxGeN0aYNZcletKxEPEuoJFQSUIMHYFbLQftrSb1UrEbYGiPDBnOAgBYAEAw5IOvIGkC10+DGL6D40kjRKYAggFkzsPodv3rrPMmCt5jnaioh8EIUAhJrXwuKNUYCBOA4ViJSBgC0FsDGiIhGLSlhqeyMqLHgjCOxgDNbt8JNN331wFv+3W/+681btv7LvQf2H35074OdmdktzYnxyWZjpFarN1u15z7vRVc8Or8YNs1uGf/5V7/itbfc+LXPfOUfvnRbPU05cIDKF73A7A0TqrIdBiCIzMykA1YRD02wMUbdgpNDcOgprwHXl+EAAKANbWw2m+R9zTUajlQVvY/QWiFrlYwBNCb0/UCMCADJkjNoHFXCWnNRsffBvZ3zzt8xdvXVV71kYWlpX3s1i4ssy/Y9vG9pfu5wZy3vVb/yq7++48U/9+qfvfv79+y767bbb7zxS5///ubN03GAioA1SJ+/FTioll44kAqoiqoXYVZEVGbuL79BVBEhBwEsAKJGZFQNKfYzb2rdOEvrIle/OGFOpD8ii5YtLnw7dHZ2Qdo5ccHAVUCUnEIIJEyIGvrjSggRAUME1vbzbOwcOHTGERH1p+0asZastUjWoDHOsKgsL7e7y6trj+3bt3/hqmuef/HzX/j8DXv37jn4vbu/t7q2uhYuuOyK7Wij6dKLf9tb3/Arhw/u/8FH/vIDXx5tNFZW2+2CmaUs8xILZs9FVZYamCsGCBxCgBAQEGMNgSBJDBRFjERe5rN5/nEazp8MRjScgZo9GHKNJzms1KfRS1UZrNVQvUcFCKqqSoRsrWEhlHhkpIUIqx/54Ac/8e7f//0tP/vSl7z0850v/u//+K63/+Htd9x68/LSWu+Zz7ziis2bNu2I03R85x23vf273/72Q5u2bnV53smNMRwDRcIsAYMOTAqycH8E/BluQUTUwehTrbBSBKsJgJaAkgLoMQ3dHuraOJpxVVVAgEyk10MuEKwCMARA9YDD2W3HeyzWv8fJ71qCx1T7dGSSiIxUIkAiVIQQitBtb9kymx56bP+hhx9+xL/5LW95fWukseXSZ1z26ocffmSPAofnPvc5L/nWd3d+hZDOrXq94m/+50c+W0/j5cBcd9ZmedHNEFExJoX8xHEYY8QYI/0F1bkSeRlMYVm/rFB/0mB5IulYx33BbrdLtRqZskywqgCiqMQoirCqDBERRRERkaI6othGpFYRyBpngQQNKUtVFHnoZVnbV+xbY5P1q5910bVKEXZyXz7w4L59c4uLh5LYdf7L7//eDVs2b9Zee6W0NqKVlWMrIKTkwKkqA3sRQQgaBAIwA4OIKCJqCAGIaDiIB8OQV6aKFsiQkkVhGnUm8SLmcmrs2AB2RgCY0NjD6h/5DrfvRnRlxaH0CBUTMpB67jf3gAw2kCMiEAatrEWjShERkakRojeDbStIjlAtGUMQVrpri8YYYy1FtVpTdt+3O7v+X7xkbLnd9Z//h6/848SGqYmp6Y3Tm2Y3bXdRit+48aZbH3pg9/1H547MZdnashfQqiwrZh9CwUGVuSiEET2XZSlVZaSqZBB09APhbtcoUUeTJAmDMtxPbE/wE0nHOo0mnF2nWUiJSHo9AMRCAXKoqkpDCMI5s0jJxCwiKpUa4aoKLrH1kWYz3XP/3vs/8YlP3LR12+ymlW4oP/nJz3/5xpu+sWvX3bsPN5Mk2bVz5219Vjq6UqsQx1Fz48ZNm7tVt9ddK5dFDIlJKRCJsA2BDFdEglgbaKe6DtsbEVGTU2YBEqJYZ5FRQgfLogDJGFFRBQSBl0lXPJIPwFw6FIAIEFBZY4o0pqI/6w/7vSz9DkEikhxSyCEFQlJhGzyiWltDVeu8h/xYu73SarXGx8Y2TIeAWnS92XHueemN//jl21GVlo4tZTfffMvu973/L/7+4KNzD4y1RjftuX/3g/v2PrQHScs4TVvAARBZRUT6NxsqURDvvSL2J5/21+JWXJYld7vHtR4wM/4wze4ns2n1iQTgOjmkw/2+P6SCB/vITjJ9iErCQoOTxSKBvTCqqghn09Mbdxw9urR/eWU1b7VGa3Fsqdvr+Lu/d8fDmzadE3tVjDGypha5OI6TDRtmZrXhorV87VipGthwkUvesQ1r4jg+cSJr/XFysg54Mlyus27qfckUPKPvaugIgAAoFMDFMalWrDHgUSoEUI0U/TpNcaJ9st8lCPU6qComiWIUMbFjKqEs8zzvVQCwlq8te5+VExNTm+K43qLIuSiK4gBgxjZMxnd9786Fssr9ppnpBgSBqY1T9Qf3PvSDej0Zv/zyyxuLx5a6AGQqL0FFRaR/DRCDhsDi/YnjqapKhrSrvhkmBWgDEcnc3Jw8UcigJ1D7naQJrbVC1BGAtg63miOiliVJWeLxn733ykwaIAAjKwsrM0BSryW9bhef/exnTzcajY133n33944cme+kSWJ+7pUvv/KFL7juRdded+321dUOptZS0mykqUvr/VXBIqNpc7xeb423293ugQNL7RAiAxBFQy1UGcN97VSDflOP4nAmXoUoHkAZvDCgCCiCxbACflVV1ABatsg98L0AyAH7w5jYBx50rp1irvodfZhlqppiFEWD6xBFiEm0uFj01taOrdRqo0mrNTlFRCQO1VnnWhPjI7ExuLS0pK9+zasuvOQZF//My152/XO2bd8yWhSlv/Gmm+/N8zK/7gXXXT03P1816vWGipe+JiuVGZWZlCgMpx8MANc//1mWneTzWWvPxH5+SgchP9QzvLBAOj6OOgQ9YqaIsQLkkCT1gYbwShQrYlDESNc7qpEx9MDeh+bf/ru/+2sI6sfGRpL/8sd/8KaNGzdenKbGBK9wwSVXPGf7xRc9xFV+KHYujZyNgy3zTqfXbjbroyaO6s1mPSuKlUwTwbLsdIwx1ltrI6tcVRVr2o89IEuhxEzcYEEg9rcgicPACk4CWOmCrAVCbjMvBLSQK/a8SKXELGB48OH75j1FhQqg3/Cdg6QpGmM0QmuqSl0UGQxBcoDSj487pxpjHEct55zp9bI1dJGahm0RQNyruLzymddcsvGcbVe4yOKFF+14wSWX7njBscW1I/ffd/9tvbx3aMcFF7x8evPmz6x1siyxtaRbdqr+5T5lfDAAFAUAM6oxJzRisynY6YAuuIVTtZ/8pFIwTxQAz9C0YvRUU0tEysxQlqTOeUmS5CTwkhAZZzBpNmr7Hn7k6C/9m9dfvHXb1mvQGHf9i573iysra489tGfvl/cfOHBkdWWlOPjoQndsw8xskWdSS2oVWbFZt+ioKqJzxjKFoij9xtnZqRgju7a2tNput3u1Wg2NcbbfUTcY+52ihsoEUiWF2EaD9oEA/SlfzlrtqORdA507i96tU2C3lMKVDBbGAAAMza+nSrhEqZwLVhU5SUiYyTlnRRSxKMue98G5pq2PtVpObdQuOu1StEyMaahqxzlrXJKk42MbRqei2haX1Ftf//otDxydO7oURUY3z54zev72bZdfe83VP0/GkCro77zzna9965ve8NEXv+hF53S6ax1jhiskwrDh6GRzeELzARGpMUZmYRYG+T98IiJh8wQ7fwNn9XwCCFirBRIRiuMYVRWdc6iqaC0gIhoRaxAtOUeGwBrjnItrtSQmZw8fWyr+4+/9P++e3jAy/ejBw7u++Pkvvf+P//A/fezTn/30zqKzVv3S637h1S992YtfvLiycmD/Y3M8OjKaECMFkTyyxnbzrLe4unBUSWi8PjrGxGggctaiBQDOsqwAgFAwCziHnKNm4LsNRAdCVgFQFRANUaIUKVU0A258m6mdf1e+dleURNEcF3OHsFpQwkoQJTgIpUNB1QAA0GXOMI4BEa2rHGeegvcchNCM1RvNxmhz1DgTR7GLI3Dm6PzicuwSMzk9OR5HUTS1acuWyZnZ2WNrGbJy+K3ffOsvb5me3vTFz372lk/87d9++3N/9/mbjxyev2XDhkk30ho5d/Ps9OVrq2u37Np569zGjRvSPM8KCMAiIYQQQlmqhACiCqLaZ74wsxCRrq2tqXOO5+fnT41+5ScJwicagAMQLiPAGrRaLWBmKssSoijCsrTknKIx/XSMMYADZoyx1lgXx/HY+Fjjjp27V/74fe9747nbtlz1ta9+80/f+fZ/+5eH9j7cvfiC8zdvmBiTNIrd4tGjK1u2bpl+7vOe87KRsbHsnnsfmPc+lL1OuyvE1eLh+bm1rOPraeqMSyIuQrcoiorIWQDjrMXIWkshBE8d8l3slulSGgpDlBI4VDWoSobI1JQcM5vNEE9scOnG+7PO3irCakVDewnCaklQIRJ7UmYiBhH2xgS1tpifR9/CrlYxQtPGsWtFjcjYNIlcFEQ590WW2tSpKnvv/XKvW4w0m0lzYuP0aGtqat9jh9rPvOrKzW9986+/MV9b6/yvv/3o34Uy74xPjJXbzj1nZv6xg70P/PkHvgpEd++4YPuFl1/5M8/7uxs+96WRehIHRZUqK5mZvffCDIJYBUQOqsp5TkrE0u12dbgpfV07Jv6kk9A/LQ0I6/KBWq/XSURMVSUn5QP7uUAia60hctalNm40mvVjy8vhNb/0+msuvPDCy/77n77/PR/67396z/OuuXZ2bLxV63Q6XQ4BOIg89NDeB2/55i33bdw45Z57zbNfeeUzL5+dP3r0mArobbfdfoAc1VsTLbSIxtrItldWeyMjzSaRQYBKQjACwBYRrbPO5iEvIV8Aipu21G5F6itmw8YYBhYIFriFcYKElgOHRfXHjhg+koXQCaBZXvqsdJh1iyIT1QqlGUooNc8jGdmYNBu2kXJk49gCGBNZ4yLjamnCgkGJNa01k6zyfuPU9OYicLx1+yU7TJTUfvXX/vX1L7j22S+75867vvWhD/z5pxcOP7ZXJARfeVfknSxOYnPB+eeN3XX7dw996K8//qVrr7tu2+VXPXvHDZ/81O1bpmfqRdbJylKCSOB+BQQ4z4GJWEVKzjInAGV/2YVzvK4P5GmViD4dN5AAAEbyEQxJMIgpxLGCtZbimKiqDDmHRsSSc9ZGNorjer0+vWXHuUmS4J+//88+1lk+JpddeeV0p93Jer0s67ewVr4sq4qIdKRVp2984+bdndX2/quuetYLnnHpZZfedMt3dr3r/3rn66677gUX3vA//+qOHRdc2iIE1xhpjBAoqapYSyDiOc/zrFarmQABiSjUa7XYxFCLNLFCEsUW6FgoMmMsGdWQAft2r11d35i5boGrfd8qVx5MnC1WDRcFhCyEoPUksbbRcGhDYpPETlBXbKORqolcgVVJbE2SJLUoci4y5JojzYlGvRmlabN29647iz/4oz963Zv/7dt+69u33XHf6173mhefd97sJZ/5X5/48Mf+6qNfGx2p+6oMwfsqeM8snn1elGXW6ZSTGzY2Jsaa7iMf+subxiYnzcymzePzc3PHDAAWRVmqcmBmLgpk1YyNMRJCUO+NApRojOHoaCQDAuqpud2nlQk+SROOwAhyjWlI0ffeg6qSc4CqStaicS6xaTOpT27evs3Eie787k27pjZONOtpQqurK+1QVFyFIgj3fRlRYQUwPgRG4ZUDDz+4sv/AY3tYuH3wsSPHXvdLr3sDEMrXb77lgX0PPnR08+YpW6+PjQowonrppyVAswxKxABlSeJ93iNJEiI2xCQ2QmvVpeyLqgGmMWbc9KjasUk1tZk42bZEsP9IVXVGbdyorOE8lHktimKVyEpE2p9Xo7TKXCScIMYSS1n6RmO0FtVtFCUuSuvNerPRiC06ODw335vcfO72Zz77WZde+7znvPTo/OIPdu+66+7v3Pz1b+7auXNfnCQrRbdXoiiyZ1+Fsup/D0E0hLybZcyBZ7fMNh78/n1zzdb46OjEaHNtda0LUhQhhCrPJQAUrKpcFEayTBlxTQfjOHhAQP2JVz+eBB/wRNa8C12q1+sokqP3NYgiwSiKwHsPIhEliTXgxUxMzY5bZ/jAngceHRltRmWWZ51ut1DvmdkHCRzY+wAi7JlFhL0yM1oTJ7UaHNr/yGN/98kb7ti2fTarN0bdF77w5Vt/4y1vftmVz37OzIc++KEfPHT/9+c3b9lmotRRkGBMBQrGo6r6Tmd5LY5jdlpFIUTKYS0nVYukxgCQrzS0KInnfV5eFY9tjiCeOGbCYw/41YORq5kVyNaIIwUTWYOldvI8r5xjjCKoqsrnnDPV69SIm41azbq+rh+NENHf9r2diz848Cj+8q+98fo3vPmNr9658549hw48uqt3bH73f/3Pf/jtRrPRjSITxIco+BDKkBdVKL33ZWDvgzJ7DsEzh1Bx4bNeXtSadbu2sthN40ZsXYRH5+aXRHw1NMH9YkchInkgIo2iiBcWFrgN7VMJCPJEaaafhhk+bopnZmZMURROpEn1eiBmNkmSkDEmIkrdkLIV19NR56xVCD+08M6qWU9sICFDRNjvCY6NJRPj0vLK0eWVVf/wA9+H33rP/3v923/z7X8wuXFs8uEDh+7++le+9lfvfvubbwSA3nXXXVerqsp2u92q1+t1Dx48uDYzMwPOudiWZX8qeUVJwiFipEBlqS0TNx/rdfEdE+e+rFtW8YOQ7bmrWttdiyKzEiRLAVQSpRJRTb3OnRCqBgCseF+EEEySTERjY41Ws9l0Jk3p9ltuXAOA9Lf/7z96/qtf+wu/et65W68KeW/105/53Iff81tvvWF8equec84WHG+NTFmjtqzEq3pm7pfXSE5UmgLyoNpiEAePrUkcYjA+D93l5faKMWirKhQhdH1ZlmyM4V6vx9ZaXlpaWr/jQ/5JArCqKhNCMAAAtVrNJklivPc2iiIjEmPctEmMsYMIwLChfrrG0LCMZa1dB0Dud9pZg9YoWmstAMCRRxeOVJWX7RddPNOaaG3bNDPdetnLX/G8S6644iVj46OThw/N77zhYx993x/93nu+DQDV1q2X0Opqt2y1MM6yrJumqTNFEdkosuS9o4wdIUpRhSqJbFSWa/Cv4umXZCX7/SZ7bJHDwwvki6bGtkxRrUQm1IhFFZW5rKwNMAdZbfv4RFjrek1TfPTRPQAA5j+9/4P/4mdf9fLf2Di54dqiKJbvvvOuf/j0pz5+c97LCwVd2rPnvgO9LPNbZ7dNptY0qqqqmETAAzCxYEBl6tPKiIdg9FBVQ7YLi0dUzpm97xVVZSSETnDOhaIo2BgjnU5HoigKi4uL1WmIB08IAH/qJhgAqNvtQqvVAlUFRIQh8dFai8ys1iqRqgKwhFIF0bNqCCFA8N4zYmDmKoSg7H1gERQiZgkqICgErJ087x2dW17dtGljq95IJ9hX1f4H9x786le/cu+e++6/08Vmbnpm4yVXP/faX3n1L/ziBZXose9+85b5LVs2RWlqa51OJ7PWVnkIAfNc1BiNIGiAAJYBWbBcLjrh2nTmYgMadUzVPcw6n1soarGxishKsQiGKuQu72FVWmtLqQvW683x2saR5PDBfcWvv+23n/PfPvzh/+95L7jut1W87Lrzjs995IN/8defu+GTd2RldjhxTss8p9RGtLCytOKEJCaKgqpnz8Fj8FaVyzJ45SoocyjLELwPHEIZVEMQ8VyqBimK4H3hvbfiXAiqymVZ8jDaNcbIugkI+ET4fE8WAId30nEmRbfb1ZGRERQRQkRIkgS99xBCrERhWBRXEa/WWmFmEPGqGtbRxUVVg4p4rioQ51RDKFXEaLedtxuNWtJo1Fqey8qHqqolNTuxYTqanzsy96kbPrFr53dv/55N4gfPP2/7zzzn6ue8kiJz666d3zlWr49HZZmtlWVpAQDmV+rVam+ukKLus5LydpCqnng9VFX6LDsydlVt/JVLKru/2pvftymK8Oia7VW5Kcp8vpDeSEnlEe/T1IwyU2WMJkkzKXoFPeOZz5p8x7ve8V5rrf36V7/ykff+yZ984u+/8MU7V5dWDk1t3JRICFqWvaoo88KgoXqUmqWl1W6UoGNGYeYQymxwUwqrqgCAMFeiGkRVj8/uDiXKgHTK1sKAglVxFEXcbvfr827ZyXx3nh+H2wlPVxN8qikekiBoZmaGhsMrT/iEiUkSJlVF5sgkSb8+y+wojk8wVZxzQ6o/9NM3Qw4pKjNzHDdr1gqpWjTGkDGC6JwFcLaRxDb3gXfffffa+PiGiVf8ws9vWD66sPeLn/3UoU2bNsHKykqRatocWLIib+eegLSCyqbNYKmD6utsLy5p2wuTzdfvKhZvvDld2t/sNIEAlUZRpd0uGACj0dFI3WgqiRARZSKCWaa1i654Rv2ii847/2tfubHDZbe79fyLbbNRb5Rl5b2vWCrPNCDnlWUVAADKssoASiBKLDMzoj+J6DpoJNKqMqIqiEhqTJ/pUpb9ccZFYYTIiLUF93o97tMgorCwsMCn1HvliQbjTxuAp05PJQDAmZkZKsvSMjfM6ChACP2SnWoNh0DsfyWoqpimfT9w4AuaPggTiCLB/t85tFYIPapYoRMlP0vGGGImAwBgrR0MdBS59da7V6wNvSiKiiRJfF21DsbEvqpCaQzbLONszYYWKGYNH2EXVKBLV6Tj505q8/xHeO3eA7Gfz7smjI72SQjdtuX6aLAJ10yZBpskCYkqHu10eqpN4tRbWxT1Sy+9ctQYE1VVxcNaLTNLCDTQ9F5DIEH06n2fx9cHGQ6axr1UlZETFLdKigKVBvOzhwAtCiOImeZ5Hob0uAFDnJOFhA/CwVN9vZ84Bf/JBuB6CthJBMepqal1U1SbNGRkiPRBJZJSmp6YuD/UfHEcH9eCzBHFseAJwCo652idxjzpdydz9GLI89XlXq/XK4rC1ev1hvfeU4/EJd5ZYxirKg5l6R0R97qgCoCXpvG5W6l+wX2+u+uxqDrqun0WjIwoptamXDqv9f57FcZwnSiREFerfrUItZo9d3xmUiQfHGPcv+oqOKRK9Tl7pAAleE9C5GWo5avKCFGpRCRFUZxE9hi0PJzgMJZlvx7dJUXsyJCHaa2VgeY7dQA5/DRMsX0SAChwmtH+CwsLYWpqCrz3BgbJz04HdDDYEohKKcv+LIxarYbMTEOTMwSTaoXM8fFImTkiY2RgooXCumyOajQAYKlVRWJMT8LgBWNRFIeCJEEhqikCkOS9njQ4kgjUkDdJWg/ZUs96CCFUkXABFEy3r1VcQg0fygDWQoaoNQRgEUqYjQ9R4LhyXDQrm3VCN1oqrLWmP8Tz5Gvcn/rPSFQMWMy5EtUUoAAikhBUicKQWX3cDJtBV1+e5+u0otFOpyOI/d8bY8RaeyrZVJ8I2v1TDYDrA5KTADm4E2Vqaor64zwURdrY68HQN+E+j9Nivd4HoEh6XAPW6wBVVZ1gHEPFWQagmqCIUJKc0HoAxbBFQEQyVUXt9XpBVS3EsQB5iQLY4eoHlyQOegJOE+NByEjsFELIwPgK1TNWLKDo62yTYC1IDFVhfIpCAKhlnnNaq5EzJeeVaJqSQ4x7zFxVVWVUE0yS4iSL1G9VQc0yEoAM+r5t57jWNgYgz83ADOfHzW2v1wfgyIiBTqevBZsqCNinWcXLcZiDuTPNfP6pge/JBOB6ZsX6NI0MgKgzMKNhQ6BBqyQMQSUigEiQZcSqgiMjlQw0HBaFoogoQB1qtWFwIghQgTHA3gutd9iH2qKqnBLlYq2VuIijdtYOowBYcQ0QuzpgRwug2AJSTVUMCru4FpiDFQYKBKhxnW0kYgBAEVEVFHPMGXv9z1nmeSBEtY2GqCpWVWUQ0YcQa5p69P7kHpShqTUGlchplq3nU2baN6HD5wh6PTvw6/rPdDrHy2iQWcMWrUZRxAPw/VhrVf8pasD1FB885bHOgVFYNDwzw2KMUWbGEAIxMzG3B0AC7XSGc4yP+zvcbFbo/VCLCJ4w0XUcFgSHIAwhaFFYAXBA1LEFFGqMkY4q1rXX3wU87JsAgFhyU2EkTVXT0sQgVCqcaMCSWYkYUlJULgHUDFoyDZGIKg4bnqhnVVQwYN2mqai1ZfB+qLVPPs715tiY9T6eHbgpdBrgtI+bYuccAwCcprF8fZ5P4Cc09f7pAsBTwcjrouPBc/2TNTd30glhAKCpqSnqDzxSVO2gyMjgNf0LePJFWf94cfB99PhFGvx8/D2stcfzYAZRVvuvHqxjBSVENVgyaGRYM8OaGsJ+Z6eokmhGw/11ffp9/1/3Bn3QfTPaptHWKEAboNPpyKnHMDpagYhgpxPpcJB7PxA5WZpNGfwNKtGanoh47SC4cAIng+5Uc3u6KFf/OQFQTwGhWXd3ymnKeAAA6hacOHDCM32tKNI9KbLtm93hBW0fn2+HaPSEZjHrzFx3EBFGMtxtBwC6pooGUdv9gAdrAxAigPawDE6VIhArYDUqE/IJmRgUPZSAAFogsjP9qHgUADoDTWat5W63i33zaWF4Iw0B1O0OtaEgIpxyo7SPNw31egDG9JvKrU1OCjgOHTqkZ7A6eoZr8KTIU0EDrvcJ5dSy3WnACIfgUP/EzfVr70MTPjU1ZYhI+6Ds4fqPOKysnADoKT0QC6Qw039u3e9laMqGUTcAQIXIRtUAJKDgkAClBFCAHDwilwDiEAUAoH18MsSJ1Mj6Y1kvIQQ6EYAIrl+y3AdnDwAsRFHEw9csLCzIKeCiM2g3fRxXSP+5A/BMvsmpc+j4NKW9469bWFgAAMBZmOVDJ/37Q6ebZbf+pONW2AoH5w4CAMAszCIDowUrAoIyIf3UBjMoAJoBuDyWkoCjACwQ9xvXh2DJENUSCbVJCUgISAkW+2tPYQYiiKSaqSiKIjl48CCvy4uuOw+zx493dhbg0KGTPg/Mzs7iKf4bnQKoU5cK6im5WHkqaJ6nquAp2vFUYsOZuvPxx/ycekqOEgCAZgGMhykiWNAKJgxtIA2LwdRH2AQR0+AoFlXazGZywqWTu/jog44oIIAGolAShaLjvAHT35s8TIYDyKEzN/bgGWroeprn4DTnB04DQD3D3zzp5veppAF/lFY8HVjWm2c8A0Af7ySfbuneiVWzAACwoFsBAGAJYBFAALCDo6hEEEnBESigqysAAJelj9IUAlEoexR6QBzBstgBqKPB94Mnl7nOdHx0GkDK41SWTlc+e7zPrk+Vi/xUBuCPk87R02jNx9N8eJqLtP4iHk8LHVznAkwBoLbbqDCmFphLUNRRh8bEUGQgBlH9AHwW2jwsbZj+/+FTwKQ/4liHgdmZqkn/p2B7SsvTGYDyI8CEZzBR8CMqAKdLUxAA0AIATwFAgBWqYCQEQA1Zpr04ZAR1qQi5hI6PAMQCyNwP79I4HXDoxzymM7kNT0sQEjz95fHMjAy0iDzO15kiwdMV5WUBgCMANoAyD10fuUjHXdQsoOdNl8QASAzAcyf//1Mf62neZ/0Xr/v6Ucf5pEey/9wB+NM282oAtANtAQBOEWXc1jYoABrA9YyC0wUGePZ0/tPyAX/a4CMA0EMAMjXwz3LP1VrwRQMAD0K7PEP+bX25kZ7OGussAJ+8SPykwCEZAGqNOF/2YWGuXyqWx8m/IfxwBPzPXszZU/Bja0MAgP66FgBtBGtCrHykyhe3AlD79Gzis6A7qwGfELOMPej2qL+vi/t1lOOpk7Nm9qz8dKzILMymZwO6s/JkZxPORrhn5ayclbNyVs7KWTkrZ+WsnJWzclbOylk5K2flrJyVs3JWzspZOStnZZ38/3i1ElwLFdVfAAAAAElFTkSuQmCC]=] },
        ["Radiant Halo"] = { file = "noir_cursor_04_radiant_halo.png", data = [=[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]=] },
        ["Moonblade"] = { file = "noir_cursor_05_moonblade.png", data = [=[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]=] },
        ["Void Slash"] = { file = "noir_cursor_06_void_slash.png", data = [=[iVBORw0KGgoAAAANSUhEUgAAAKAAAACgCAYAAACLz2ctAAAw80lEQVR42u29e3Qd1ZXnv885VXWr6r7fkvW4siRbsvx+G9sgkp8NpqEJyWq7YbozqzPJ0I88SWYSemVmjDPzS/dKZxa9Vqf5dVjrRxpIwsOEQDpOgwdj3MYYA7ZBlh+yZUlX9+pK961b91HvOvOH6xqFJt0JGIxFfdZiGWxZKqq+97vP3rXPPgAODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg5XC+LcAoffEmT/c1k7fX19HkopHwgESK1WAwCgv+s3ZZz76vBbCG+uuNjVq1dHGYaJqara4Hm+SCk1AMByBOhwRYVHKQWEEAUAiMfj7v7+/g6O48KUUqZer0vZbDafyWRqAGC8F/HBOyzVweFfCS+RSARWr17dw3HcAoSQWK1Wpy9cuJAuFArFcrlctZ3vfdurgwNQSlFTeCtXrgz09/cv53m+U9d1rVqtVguFQvrUqVMzLMvq5XJZeq+u54Rgh3cVni0+/q677lodDAaXAQBTq9WKqVQqOTU1NVMsFqVAIIDT6bRyJcTnOKDD3HBLPvvZz64Ih8NrAcCdz+fH0+l0TpKkxuzsbFaSpEYwGORHR0erAKBeKQE6DvgxFd7u3bvRnj17LIQQ/PEf/3FvPB7fwnFca6PRqExMTAyPjY3leJ4njUZDUlXV8Hg8bo7jSgCgfRAptsPHcJ135513xjs6Om5kWbYbY2zVarVKLpcrptPptKIojVqtVi6VSrIoiigYDJaPHz+uX+nrcRzwYxhu29vbhT/4gz/YIoriatM0LUVRJIZhWEVRNFmWGwghWiqVioqiNBiGgbGxMckutVz5i3KeyxW9f/QjfJ0UAOALX/jCUr/fvwUA+EqlMsuyLGFZ1qUoSi2bzZYkSZrN5XKparVaU1VVy2azjQ/y/8sR4Pz/gFAAgO3bt8cSicQGl8u1oFKp5FRVtTiO4zVNq+u6blFK0ezsbOnixYspy7IUjHEjnU5r8B7fcDgCvLL3CAEAaW9vZziO43ieJxzHEcuyEAAAxphqmmYSQqgsy6bf7zcAQD9+/LgJ77NQ+36F19vb61q6dOmSYDA4YFmWlsvl8oIg+AFAGx8fn45Go/5wOByuVCq506dPjyGE5GQyKdvJBv0wLtTh3e+Lq7+/3+1yubwul0vEGPMIIR5jzCGEGIwxYlmWAADoum4ahmGoqqoriqICgKbruqppmowxlgFAjcVimsvl0g8dOmR8SOLD27dvT7jd7kUcx3l1XVdUVW1wHOfWNK00PDw8s2rVqkQgEGiZnp4eO3v2bJoQUk8mk1UAMK/WGubjLjp22bJlwVAoFLIsKyQIgi8YDPpbWlpCoVDIGw6HfR6Px+fxeASXy+ViGIYFADAMw9A0TVMURa5Wq9VSqVTK5/Ol6enp0sTERK5UKlVlWa4DgIwxbtguo1/hB33Z9Xbs2BG1LGshy7IRURQZTdPURqNRk2XZwBhr4+Pj2aVLly6KRqOxiYmJixcvXszzPC/ZyQb9sG/6x1548XhcTCQSMbfb3RoMBlvj8Xi8q6urpaOjI97e3t4WCARiPM8LLMvyhBCCEEKUUmo/LAQA1DAMi1JKTdM0dV1XVVWVJUmqlEqlbDKZHB8fH09euHAhfe7cuWyj0ZAQQnXTNOVoNKqdOXNGvxIPfnBw0MPzfEKW5VAoFPL4fD53tVqVK5WKVCqVipqm1SRJMhctWpRwu93s1NRUrlQqyY1Go5DP52sfhSzu4wQOhUKevr6+BaFQqD0SibT39fUlFi9e3N3R0ZGIRCItgiCIAIAsyzJst0KmaZqUUgsAwDRNi1JqUUqpZVlg65KapkntPzdN07RM0zQajUajWCzOpFKpidHR0QunT58ePXfu3IxhGBVN09RSqaQBwG9yRfTvZNmurVu3tlFKY8Fg0N3W1hZjWdZTrVar+Xx+tlwuT4yMjGR4nme7uro6MMakXC43MMaqJEmZZDKpfFTKCB+b9d3mzZvbwuFwd0tLS/eyZcu6ly1bNtDR0bHQ7XZ7MMbYNE2zKTo70UCWZYEtPmpZFrXeBmzzsy5p0aKUUjAMQ9N1XbMsyzIMw6SUWoZhmOVyebZQKGQzmczk+fPnRy9cuJDMZrOSx+Np5PP5Wj6f1+yf/W9loGwoFBISiUTQ6/WGBEHwt7W1hX0+X9TtdvsMw9DHxsYmxsbGho4fPz6ZSCTcPp8vTgghpmmalmU1IpHI9KFDh8yrWT5CHzPhocWLF4cWLly4qKWlpW/p0qWL161bt6yrq6tPFEV307QAAC5F2LdDbPP3MMZAKW2GYLDdj1JKTV3XDdv1dF3XDV3XDVVVVTsh0Q3D0A3j0peoqqqoqqrUarVqLpfL53K56YmJialcLlcyDKOmKIoqiuLlBAdjTCVJgmAwKLrdbq/L5eIRQgQAmHA47AmHwxGMMR+Px4Nerzc2NjY29Oyzz+6fnp4u9fb2hgVBCNnXixiGKb755pv5ORm+5Qjwg4dbt25deyKRWN7d3b14cHBwTX9//wqfzxew3cvAGDMAYBmGcfmBIIQQIQRjjIm9/rv8De03C8gOu81wbBmGYeg2iqKokiRVyuXybKlUKkuSNGtZlo4xJpqmmaZpGrqu66ZpqvV6vVEul8uSJJVnZ2driqIoAACappmUUsRxHOF5nscYswzDmDzPk0AgEKaUcrVardHV1dUSDAY7ksnk6w888MD/aW1t1UVRDLvdbr9hGJZpmo16vZ5Np9MyAGD7g0WvtivM+7UeAHDbtm1b1N7evmbFihVLNm/evKmzs7ObYRhkmmZTbNSyLMsOt5gQwjAMw2CMEQBghmEIugS2f6W2PgEAoBl357qhpmmGruuapmmaqqqq3VOXm5iYGJ+YmJiqVquVS3rCrKqqpi1ECyFE7cxaadqpruvNdadqmiZ1u92iIAhMtVpteDye4Lp161YwDON5/fXX/8+jjz76yuLFixmGYQIIIRZjbKmqWjx//nzxna7+UQhL81184vbt25cuXLhw5Q033LB+3bp1G4PBYJBSaiGEkL2WMwEAsSzLNJ2OYRhCCGGaWe8cgVlzQjK1XRAwxhjmKtJ2SMuyDE3TdFVVtUaj0ajX641Go9Eol8v58fHxi8PDw2fPnj07gTGWWZYluq6rhmFQhmFYQRBEW/i00WgoqqpqpmlSwzB0y7KUoaGh6i233LJ0y5Ytn2RZlnnppZd++fTTT7/V19fHcxzntSwL67quVCqVXDabrf8WyYwjwCssPvdtt922MpFIrL7ppps2rVixYoPP5xN1Xb9cDDZNkxJCEMdxHMuyDEIIsyzL2QKyTNO0DMMwLMsyqN1KYmvvcjWGUmpaltUUIcIYI4wxwZdACCFsWZalaZquaZoiSVK1Vqs1arVavVKplJPJ5Nj58+fPjYyMnJ+amspPT09LxWJRc7vdWBRFLIoimKZJCCGsrutmJBIRstmstnr16sRNN910q2EY8nPPPbfvxRdfHOnr63OLougHAGg0GpWRkZG8nV1/ZBfm8xX3zTffvKKvr2/tbbfdtm1gYGAVz/OsaZoGACDDMExCCGYYhiOEEI7jGEIIY4vF0DRNN01TRwgBwzAcxtiFEOIQQtg2QgsAmoJElFIEABalVLXDpG6vJVHTIe3Qjey3Jmq9Xq/ZYlQURann8/l8Op1OpdPpidnZ2ez09PSspmkmwzBI0zTTXgOyo6Oj0saNG9s2bNiwTZKk7FNPPfX8qVOnUgMDAz5RFH2qquqVSiU3OTlZvhYyw/mY7fI7duxYuWjRovW33HLL4OrVq9cTQrBlWRZCCJmmaWKMGdv1MMuyrqYwdF3X7SSB5TjOQylldF2XarXaRUmSJnO53IQkSVlJkioAYDEMw3g8Hl8wGIwGg8FOt9vd7fV6u1iW9VFKdVVVK6Zp6qZpgl1DbEby5hIAZFmuV6vVmmEYuizL2uzs7Gw2m83ncrnpbDY7XSwWZw3DUAghpFgsNlavXt22aNGiDWNjY0NPPPHEoWq1Wuzu7g5jjAXTNJWpqanpq1VY/l2Zj/2A7NatWxe1tbUtu/nmm7csX758LSEE2Y6FTNM0GYZhOY5zMQyD7ddpVFEU1TAMjWEYhuf5iGmaai6Xe+PChQsH9+/f//ojjzwykc1mZbs+N7fJwJrz74zL5eK//vWvd23btm1Dd3f3Nq/Xu8btdrt0XS/Jsmzpum4piqI2sT8MGCEEqqqqlmWZbrfb1draGna73WxznaqqKjc7OysPDg4uD4fDPUNDQ4cffvjh17q6unSfzxfWdZ0xDKNw7ty5wkc55M53B2Q2bNjQsWjRoi233nrrjdddd92gIAhcM/MzTdPieZ7DGLMsyzIcx7G6rhuKoigIIUsQhJBhGHoqlXpx//79T37ta197EwDqLpcLdXd3U7fbbWGMKcaYXjJKC2GMKQAAwzCWqqpWrVaD0dFRCy41cLp+9KMfrdm8efNnY7HY7QzDYFVVi/V6XZEkqTIzM5OXJKms67oVCoX8CCEmn89nFUVRGIYhxWKxODk5mZJlWbEsy+zu7u4CAO748eMv7du3b7inp4coisJhjC1FUWaTyWQFPro9ifPeAVF/f78/Go0u2bRp0/I1a9Zs8Hg8vGmaFsaYMU3TYFmWJYQwHMexGGNsF4l1hmEIwzDhfD5/bO/evf/fN77xjdcAwFy7di0mhJgAAG632+VyuVwcx4HX6wU7XFOXywX1eh2rqgoMw1i1Wk0OBoOy3++HTCZjfO5zn/sXADj41FNPXb927dpv+ny+LTzPFxVFkS3LMkulUtntdouGYZi1Wm22Wq1KkiRVNU3Tpqenpw3DMEOhkC8ajXbWarXS4cOHnz5y5Eiqq6uLNwwD1ev1SiaTka4l15uvDugaHBxcfd1112399Kc//anOzs7O5uLfNE2TvQTHcRwLAEjTNM0wDI3nebdpmuT48eN/f/PNNz+iaZq6efNmqFQqWiwWw/F43GOaJtU0rWoYRm1mZka190Y0yzFo7dq1OBQKcW63m0cICQghgRBi5HK5sqqqaiQSQb/85S8bAMAcPXr0ix0dHd8CAK1YLM6oqqpRSvHY2NhoKpWawhhbMzMzM9PT01mMMdff39/rdrvDmUzmzWeeeealTCZT6+joEBuNhtpoNGr5fL65LABHgFeR1atXJ5YsWXLDXXfddduaNWs2YowBIUQopSYhhOU4juU4jiOEYFVVNV3XVUEQfKqq1vbu3fvf7r777heuu+46QdO0hiiKNBKJ+BmGUbxeb/ahhx6qw6+/rvr36mno9ttv9yCEAhzHMblcLg8Ayo033gh79uwxfv7zn9+4ZMmS/40x9jQajcr4+Pjom2++OaQoSj2bzebK5XKjs7MzvnDhwl5ZlpXz588ffvjhh4daWlogHA7zlUqlnk6nG/CbmxccAX6Y9PX1eROJxKbbb7/9/9m+ffvv+3w+N8aY2GUSzDAM63K5GEIIp6qqYhiGKgiCv16vlx544IGv7969+8QnPvEJLp1O13p6evx+v5+yLDv54x//uP4u94n+Fvf08tcMDg56wuFwTFVVdd++fZmDBw+ST3ziE8a3v/3tnq1bt/6/U1NTs6+88soR+7UbBgCrp6enIx6Pd5XL5fS+ffv++dVXX53q7u5mTNPEkiTJ5XK5bv+MD7Rd3hHgb1lw3rhxY9+aNWuuv+uuuz7T3d3dhxCiDMMwAIBZlmUYhmE4juMMw9BkWVZEUfSqqlr77ne/+xff//73T23evBkVi0W5v78/hjHO/vznP59+NzG9x/t7uUnUNE1PqVRKf+tb37J27dpl3nnnnXFRFLfW63UaDocDgiCIXV1dnYQQfnh4+PWf/exnhwGgEY1GkaIoVrVabWSz2eamcHM+mAeaD+7X1dW1edeuXbfccMMNO0RRbHYqU5ZlWYwx4jjOBQBIluU6wzAsxpj90Y9+9JWvfOUrh6+//nrI5/PKqlWrWgqFwtgLL7xQgUtzE694t/Lg4KAHYxxOpVIzFy5c0BBCdHBwMLBx48b/GA6HI6FQKFStVmtHjx596cCBA8N+v183TRMTQixFUarT09PafBIf2JZ/TX+AfD5fa3d3d6Knp6ff4/EIhBBEKTXtJgKw36ViVVVVW5T+V1555W+/8pWvvDQ4OEiKxaK8ZMmSmGma52zxoQ/gAVMAQIcOHapFIpHp1tbWBevWrWOefPJJcujQoVmE0GFBEEKpVCr53HPPPX/kyJHT4XCYchxHEELy+Ph4eT6K75ovw7S2tgper7dtyZIl3bFYbAFCiGKMCaUUCCEMxhgRQljDMDTDMBS32x2Zmpp66eabb/7x5s2bhVQqVV63bl0rpfTi3r17my1KH1RvHAUAtHfvXm3t2rVZURRbdu3alQIAUi6XA5IkDZ0+ffrUzMzMjNfrJbquq7IsV9PpdLPQfVUbRx0BvguxWCwYj8fj3d3d3V6vV4RL710RwzAEAIBlWYZSCnatz2WapvrQQw894Pf7zVKpVF+6dGmUUprZu3dvDT6cxkwKAOj48eMNADC2bdvWuWjRojWmabaMjo6eKZfLJZZljVwuV87n82oikSD2NRkwT7mWBUhEUYz19PR02O6HmgK0HRAhhIjdFGB4PJ7YuXPnfvJXf/VXJ7du3UoIIcTj8WiPPfZY/gNY8/3GJUOzfesLX/hCmyAIOzRNs9Lp9Egmk8mXy+VCJpORent7sSiKJJlManM+FGg+OuA1uwYcGBgQ3G53KJFILPD5fH67PwojhJr9eQQudb3oLMtymqZVHn300Sfj8TiamZmphkKhwPnz56fsb/eBi2/37t3YLgvRL33pS1uCweAuy7LMVCr15unTp8+WSqVkJpOpxONxbnR0FOyNQha83WlDYR4Olb9mBWiapi8ajUZbWloWuFwuzu5ixgCA7TDMWJZl6rqusyzry2azR++///6Rjo4Os6OjQ0QIVe1Q+EFXAtDu3bvxnj17rA0bNvj+8i//8j+EQqEdtVpt6rXXXnvpV7/61VAymSwAAIRCIdEus6jvFO3OnTs7v/3tb/+neDzunkcltGs2BGO/3x+IRqOBQCAQspON5sOCZtu8rut6MzQPDw8fBACVEGKGQqGIqqrjH3RYs50LEELWn//5ny9pb2//NAD4RkdHX967d++xWq1Wam1tdbnd7mClUpFLpVK1eT1N0QIAe//99//J+Ph4PRqNdu7YsaP/4YcfPt4M5Y4ArwK9vb0sz/P+WCwWFgTBC5e6kIktNgwAmFJKdV3XXS4XryhK7qmnnnpDEARELu0wUu13s/iDEuDu3bsxQsgCALRnz55PRSKRWwuFwuTRo0efeO65584AgNXd3R02DIMAQCmfz6tz//6ePXusz372s519fX2fSSQSN09NTf0EAOo9PT0rAeB4c8afI8Crg4vneU84HA66XC5Xc+OQvV6yGIZh7R1qJiGEz+VyQ4899thMf3+/5Xa7eQCozclKP4hEAyGErE9/+tOtO3bs+M8sy/Ynk8mXHn744ecnJibSK1as4HVdj+i63picnJx5x3UgAED33nvvxp6env/IsiwrCIJh7/WVA4FANwAIACDPh8TkWlsDIgAAURR5t9vtEUXRy3EcixBqbgiiAIAIIdgwDMPeRM6WSqVzAFD3er2UYRg2l8t9IAKcs2azdu/efcNdd911P8uyXUePHn1oz549j05MTEwtW7YsUq/XQyzLFkZHR/Nzr+HJJ58kAED/7u/+bvuqVavujcfjIY/Hw3IcJ7jdbo+u63I4HG4LBoMRpwxzFWFZ1iuKIi+KIn9514+9YRwAwLIsMAzDxBhjSikUi8VJO9NtJirKB+V6AOB56KGH/iwWi906NTX1yj/8wz/86OTJk6MDAwMeXddDhmEoFy9ezL9bzXHnzp0UAIDjOBwIBNw8z3OyLLOiKPKCIIjFYrHo9XpDy5cvj/zLv/xLaj6sA681B6QAABhjnuM41h6b1lzoo7lbIu39tWBZlpHP5zPNvysIgnElR6S9w/XWPPvssz+MRqPbT5w48f//6Z/+6f88efLkxVWrVkUVRREppYVz584V3018K1ascN93330YAKDRaEyLoij4/f6A1+v12DMJRU3TqMfj8XZ0dETnOL7jgB8yxOVyNQXI2snH5e2S9q9W8+gBSqleLpdrTQHKsnzFprw/+eSTZNeuXSYAsE899dSf+v3+O7PZ7NAjjzzyvf3797+1adMmoVwut0qSVB8bG6v8G8sKyvN8cGJiogCX3nqo9jKDtSzLtJcZDEKIFUVR9Pl8fvjwiueOAN+RATMYYw4AoLlp3A6B1A7FmFLadMDmACENAEyGYTDHcWjug3+vrnffffdRhJC5e/fu/uuvv/6/I4QWHj9+/NFvfvObjwHA7Pr168PZbJYRBKEwMjLy74re5/NZxWIRAwDwPG+wLEtcLpfLMAw3xpixm2pdPM8LXq/XM0eA13Qics0J0O/3E4QQsSyL2tluc0IBtYcHUTsSNzeNN2uEpj3pgF4J19uzZw8888wznwuHw3+ez+fH9u7d+83HHnvsSG9vL8fzfLxYLCrj4+PF3/pBMAwWBKG5xCAul4sjhBCXy8VZlkUQQkgURTfHcS6Xy+UCpxB9VTJgWqvViM/nw/ZinZ2z7MOWZRmWZSF7xAsFAIoxxjzPE/u/DU3T3tO6105wkO16nTfeeONujPHKEydOPP7Vr371JwAwvX79+nCxWCQul6s0PDz8O20SIoRQURQpAIDX6+Xs2YQmwzCsaZrUNE0rEAj4OY5jCSEE5slruWvOAQkhl8fiNkVpj0qzLMsyKaUY3h6dYWGMmWg0GoJLw4cMe7D479R29eSTTxKEkAkA9Omnn97V0tLy1Xw+P/XEE0/815/+9Kcv9/X18TzPt5XL5erY2Fjxd9U2ACBd13Gj0bAAAFwuVxfLsm6McRUhxOi6LhuGQcPhsJ9hGKJpmuk44FWC4zhii8tECFHTNC1CCDZN09J13cAYM5ZlNZMRbJomBIPBTgCgoVDIopSag4OD3KFDh5TfxfW+/OUvR3ft2nUfxnjza6+99tjXvva1RwCgtHr16mitVkO6rudHR0ffU4Jz9913M4VCAQ8MDFgAAOFwuJdhGJdhGBLDMJxhGHVZlrVQKNQKAKherytwFWf6fawF6PF4wE4sKAAQe2qVRSm1VFXVWJZ1WZZlsSxL7Mmlut/v7wYAXK1WdcuydDu8Kf/WAn6u6z377LO3xWKx/5LP5/M//elPv/H4448f7e3tZb1eb2ulUpl9v8O9x8bGRI7j1OnpaQSXBk4uZVkWW5aFWJZlDMPQLMuisViszTAMpVKp1B0BXr0QTOy13eXBP5ZlQXP6FKXUBADKMAyrqqplGEZDFMXedevWBQ4dOjSzY8eOOgD4AKD0m1xv7969eNeuXeY999wTuv322/8HIWTzq6+++uN77rnnKQCobNy40VetVhHGODM2NvZ+NoQjAKAul8tTqVQaDz74IOnr6wv5fL6VCCGNEMJQSmmtVqvyPM8HAoFoqVSazWQys3MESB0BfsjXPOfAveasF2RZFqPrumYYhjG3OVXTtDohZMHdd9+96I033kht3LiRHjlyJLBz506yd+9e8ze4nvn000/fFI1Gv1EsFguPPPLIf3n66adPrF+/3jU7OxsoFovV0dFR6f2WcwCArl27lhVFUZiZmSkDAPqLv/iLZR6Pp9uyLIUQwqiqakiSJPn9fjfP8/5SqTQyOTlZgnnSJX3NCRBjTEzTBMuyKCEE7IHbBCEEmqZpuq7rzTF+pmlamqZpgiAEly1bth0AXtyzZ49x00031SqVit92QUQphbmud+utt95jmuZ1R44c+cW99977MwBobNy4MVKv1+ULFy7MvKMATN+P+0Wj0YCmaSohhAEAfcuWLTdzHCcqilLjOE5QVbVeLpelzs7ONpZluUwmk8pkMhWYJ93R1+IakNU0jdjhEtvHIJiUUmqP2zDsAZGg67pmR+0Gy7Ibtm7dGnz55ZfLfr+/UqlUFgDA7JNPPomarvfUU09tC4VCX8lms6WHH374fz733HNDGzZscCuKEpBlOTc8PFy/Aq73ayLked43NDRU0DSN2bBhQ7i9vX0HADQQQgQhhGu1WkXXdbOjo6NTURR5ZGRkVJIk6Qpfx9UzlGvtgnme5wgh6NL4Znx5zwcAoFqt1qjX63V7Ur3JMAxLCCGSJFXy+bw1ODi4BABg7969pmmajZ07d8Z27dpl3nvvveGXXnrpu16v91tHjhz557vuuuu+EydOnNu0aVO4VqsZQ0NDyaGhoeaI2yvx0BEA0DvvvDPWaDS0WCxG0um0/p3vfOdWURR7dV1vsCzL6rquFwqFot/v9wSDwWixWMyeOXNmHAAkmCdcMw7Y7Pzw+/2CoijI5XJRjuN4XdfrGGNkGIZerVYrHMcRl8s17fF4vJZl0Ww2m5uamkpOTk7OsCy7HgBet+dDFwEg9Pjjj/9+OBz+XCqVmnnwwQe/ffjw4bGVK1d6MMbecrmcHRkZqc75sNIrJb7t27e7KaWhsbGxKVEU+U2bNoVWrVr1Z4QQ1TRNgjHGkiSVK5WK1N3d3ckwjDAxMTFy8uTJCXj71HKnGeHD4r777kMAQEVRFCzLssLhsItlWZcsy7N24oFVVVUZhiG5XK4wPj4+rihKbWJiYqrRaMgej0dYsmTJDY8++ug0QujJv/mbv4kNDAx8XVGUpQcOHHj6r//6r/+5vb2dbNiwIaaqauXkyZOTdqY5t3B9RcIuAKBAIJAYGRnJt7W1iYcOHaodPnz4616vt1/TtBmGYQTDMIxisVgghJB4PL6g0WhUT5w4cXx0dHRmznU5AvwQBUj37NkDGGO+XC7PLliwIEwI4ewTiGBmZiarKErDnkRfO3bs2AlN03S/3++Nx+PxhQsXdra3t3eKovjt/fv3x+r1+sZUKpX/yU9+svvw4cPTN9xwQ1TTNMjlcpN25wqCS6+7ruQ0AgQA1s6dO/tyuZykaZp56NAhuP/++z+5YsWKu3VdLyGEWACgkiRJMzMzuba2thav1xs4derUG4cOHXorkUiUk8nkvHC/a0qAzXe+iqKQkZGRWiwWa6WUGpRSahiGmc/nC5qmGadOnToNAOD1ekWO44Surq72np6enng8HmdZ1iVJUk2SpMGDBw/+7O///u8Pr1+/3r1t27ZEo9HIv/rqqxO22Bi4stOnmmtH+MxnPtOraVpjYmKiFgwG2c2bN4d27dr1v1iW5RRFkV0ul6CqqpbJZKYYhiELFy7sbjQa8muvvXb07NmzY+l0WoF5tEf4WsqC6dq1a1kAYHVdNwKBQI+iKJJlWWh2drY0Ojp6HgAsXddNt9vt7ejoSHR3dyc6Ozs7BUFwK4qinT9//vzLL7+8/6GHHnquWCwWb7nlli7LsqxCoXDm+PHjzaFEDPz63Of3KzyAS4OJXLFYrLtarUrnz5+vhkIh98mTJ/G5c+e+HwqF+hVFKXIcx5umaRUKhXyxWCwvWbKkl+d571tvvXXs+eeff6XRaORgnnGtCBABAF25cmW0Vqs1br311qjf709IklQghLimpqYmkslkJhKJhNrb29sWL17c09XV1e3xeNyGYZipVCo1PDx8ct++ffsPHjw4vGzZMnd/f/9iVVUn9+/ff9F2E9YWoPYu4vtdHefXBlju3LmzBSEUSaVSuXK5bLIs6z558iQZGhr6XiKRuEVV1TwhhEUIoWq1KiWTyVQsFossWLCgY3Z2tnzgwIEDw8PD5+1tm/Mm/F4zAty9ezfas2cP9fl8C/ft21f8zne+czvDMHy9XpdrtVp2cnKy0NXV1bZkyZK+3t7ePvvAaaNQKOQvXryYPHHixLHnn3/+FUVRamvWrGk1DEMpFouvv/LKK1VbdKwdeuceU483bdrkevXVV2X417vWfqNLz/kV3XHHHWFBEKKGYRjHjh1L9/T0uI4ePYp7e3uFM2fO/O+FCxfepqpqgRDCEkJIvV6XJyYmkhhj3Nvb221ZFn7zzTdf+cUvfvGyoihpmIejOa6Zlp577rlHKJVKg8lksvy9733vbwzDMCRJqlWrVYnjOKatra0jEonEKaWWJEmz09PTM2NjY2MnTpx4/dSpU+c8Hg9HCEGlUin1xhtvpAAA2tvbBXv6lAmXDpmhdp0Qnz59mh4+fDjKsqwgimJjcnKydvz4cfnfEQG5/fbbRVEUvZqmuS3LQqlUqiTLssWyrPDWW281vvnNby750pe+9P1oNLpeVdWCffAgoyiKnEqlkvl8vjwwMNAXiUTi58+fP/23f/u3Dzz//PP7U6nUNDjTsa5e+M1mswO//OUvRx966KHPEULcqVTqnCAI7mXLli33+/0B0zTNUqlUyOVyuUwmMzM2Njb65ptvnsxms+VAICBKkpQ/evToGABog4ODzPnz5zlCiAUA+u7du2HPnj3W3D1Ndu0x9yd/8ieuYrHo6ezsDMXjccKybHO/MWUYhhqGgWRZJizLsjzPE0VRYHZ2Vsnn82VZli0A4M6cOaMBAH7hhRf+8+rVq78qCEJQVdUCADCEECzLspLJZNIzMzP5vr6+ReFwOJrNZnPPPPPMzw8ePPh6LBbLp1KpeSe+a8EBEQDQnTt3dg4NDQl/9Ed/1LNq1aovNhqNXCgUikQikbDb7fbU6/X6zMzMTDabzebz+dLU1NT4xYsXx2RZNhFCtXw+P/rWW2/NAgBubW3lOY6zksmkDgCWHd6tbdu2+bds2fL7iUSiS5blw1/84hdfnlt+oZSiBx98kHnhhRdcjUaDlWWZAwAGY0zr9brBcdzlMWr5fB6fOXOmWTt0P/HEE4PXXXfdn4XD4U0AIBmGoTfPkpNlWU6n0+lsNlvo6elJtLW1ddTr9cY//dM/PfHAAw88Ua/XT505c6YG8xT0URff9u3bY6ZpRiil9dtvv/3PXC6X0NraGmtvb++ilML09PTUxMTEuCRJNVVV5Uwmk8pms2WEkFGv1ycOHjyYBACjt7fXVa1WmWw2qwGAYb9ZoXZ439DS0rIjGo0ubG9vX+D1eiOU0vOFQuFXr7766ovf/e53p94lcrBzyitoTiJjAYDw+c9/PvGHf/iHN/T3998RDAbXEkKopmkVuHT0KwsAUK1Wq6lUarJSqVR7enoWtrW1tdXrde3AgQO/+MEPfvDT8fHx45OTk7PzLfG4FgSIAICuX7++RRAEb6lUktauXfuJ3t7exZ2dnQtaWlo6TNPUk8nk2fHx8Wm49KbCmJqaytXr9YamaaVUKnX21KlTZQDAiUSCSyaTCC5Nnbqc4X7+85+P9/f373S73cv8fj8fiUT8Xq/X5/P5fIIghAghbsMwCpqmnZYk6fXJycnhdDpdeP311ysXLlxQyuUyuN1uZsmSJfyyZcuivb297YsWLVoeiURWeb3eZYIgxCmlmmEYNQAAQgiHEEKqqmqVSqU8OTmZNk3TXLx4cU88Hm+pVquNAwcO/PKHP/zhEzMzM28ODw83JydQxwE/ROEBAGzZsqVT13Wi67ra1dW1uqOjo23RokWLRVH0lcvl6QsXLlyklJJwOByq1+vVfD5fnJ2dlUql0sSxY8fG7XDYLK382nkaX/7yl12mafZalrWuv79/lcfjcYmiKPh8vkAwGAwEg8Ewz/MMz/Mcx3ECwzBehJDLNE0NAGTTNOsAINvnDGOWZUVCiJ8QIiCEWEqpTilt2F+PMMZM88AcWZYb+Xw+b4/i9fZcOhciWC6XKy+++OKzP/zhD58plUonh4aG8vPZ+T6KSQgCADowMMC1tLT05vN5xeVyQSKRWOPxeNyWZdGpqanJcrlcnJ2drUUikZDH4wkUCoVcPp8v5HK5fC6XS9rzVrAtPnhHXQ8BAC2VSq5Vq1bdRQiBM2fOvB4MBsMtLS3tuq6bqqpqmqZpoVAoSAgJYIx10zRLCCF0abAWZliW9WCMA83N8AAAlmUZuq7PwqVN8YQQwrAs66KUgmEYRqPRaBQKhXw+ny8ghKC7u7urtbV1AcaYm5ycnHj++ed/8Y//+I//rKrquY+L+D5KDnj5GANK6SJVVRWMMUkkEv08z3O6rmuKoij1el0Lh8PucDgctSyL5vP5XCaTmS4UCtmzZ8/m7BDbbDH7TW8zEADQbdu2+W+55Za7W1paVuRyuaHh4eFpURS9vb29XeFwOB4KhQLBYDDg9/t9giCIHMfxLpfr8jbQOYdTN7tkUHNOTVN0mqbpsizXK5XKbKlUKuu6bsXj8VB7e3uH1+v1ybJsjIyMvPn4448/9atf/eqopmkX/40JCo4AP+C3HAFRFBfah8ywra2tHV6v15PP57P1el3hOA6HQqEQz/PeRqMhzczMpNPpdD6fz5fK5XIDfr1DxPxtfiYA4G9961ufWrNmzV3BYFDI5XJnT548OSrLMrHXmvFgMBgKBAI+r9frd7vdgr0xnLMPt778jrd5CLCu67qqqo1Go9GQJKlWq9XqGGMUj8cjra2tbX6/P0gphWw2O3306NEXn3766RfeeOONoXg8nnr11VeVj4vzfaQccMWKFTGv19vNMAxwHEdEUfS4XC6hVCoV6vW66vf7feFwOEgIAUmSZi5evJiZnJwsR6PRxujoqA5vt0wZv8PDuxw+b7755r5PfepT/2HJkiWfCAQCQqVSmUilUqlsNltXVZX6/X6v1+v18Dwv+P1+b/PcOXssMEMpNRVF0ewTNE37cETG6/W6I5FIJBqNRnie9yGEUKlUKgwPDx9/8cUXX3r22WePUUonMcZFu1b4seNqCxCtXr26MxgMdgqC4KKUmqZpUkEQhGw2W2AYBrW0tLTwPO9RVXX67NmzF06dOlW113U6vN0karxX15izwYm/4447Vv/e7/3eLUuXLr0xHo+3MwxjybJckiSpXC6XK7VaTbY3tl++fvsARIbjOMbn87k9Ho/X7/f7vF5vgOd5N0KI0TRNy+VyUyMjI0NHjhw5dvjw4aHJycmx1tbW7MfR9T4SAhwYGOB0XW/v6OhIdHV1xWu1Wn1ycnLKPqm8nkgkoq2trR0IoWoqlRo5cuRIHgCgt7fXsg+E/lfZ7XtljggBANybNm3q27Fjx8Y1a9Zs6OrqWu73++OCIAgsyzK22C17+OWlTI5hWIZhWIQQAQBsGIauqqpSLpezmUxm/OzZsyMnTpwYPnr06EihUMgYhlHK5/P1uZcAH1PQVRKfp1qtxpcvX965ZMmSpdlsNn3y5MmRer3ecLlcqLOzs83lcvGyLI8fOHAgAwAoGo0SjDFlWday399qV/jBobnFaQDgACC6bdu2hStXruzp7+/vbW1tbQsEAjFRFP2CIIgYY8bOgHVVVVVZlmvVarWcyWSmJicnMxcuXJg8efJkulQqFS3LKrtcruqcsz/Qx1l4V02Aa9eujZRKpdDAwMCC5cuXr8rlcmMHDx48F4lEWIwxLwgCr+v67JEjR8YBQOvu7naXy2XgeV53u92mveazPuR7xAGAFwDc8Xjc29HR4QuHwyLHcQwhBMmyrNdqNUOSJKVUKsmSJDUMw2hwHNcIBALyxMSEOl+Gil/LAsQbNmxIWJYV6ejoCC9cuHBRoVBIHjp06HxnZ6fPMAxqmmY9k8nMpNPpemdnp6hpGqOqqlYul1U79BlX4f7QuaEaAAAhxMz588vzBgcGBqylS5eaAwMD1D5iweGjIMCBgQFOFMWF4XC4IxaLBQEAl8vlQjabrbhcLlKr1UrJZDJXLpeV9vZ2N0KI53ke5XK5eqVSaZ4MTj8C98lxsSvMB/omxF7cE9M0Fy5dunS1KIpCNpvNpFKprH28Ak2lUslkMlnt7u52t7e3h1VVpbquN2RZliqVigofjSE8jvCuUQfEW7duXfbJT37yZlVVteHh4dPpdHpaFEURAORTp05lY7EYCofDUQBg7Xe5+WKx2IB5di6uw4cowGZZ44477lh7/fXX3ynLsvTGG28cSyaTM5RSuVaryZRS1NbWFuE4zletVsuTk5OZ6elpCd7edO3ghODfnZ07dxKEkLlz585Vmzdv/qNSqTSxb9++I7IsSwCgsSzrWrhwYRvDMD5N02rpdPr8uXPnynDlz+5w+Jg5IAa7OHzbbbf1X3/99Z9TFGXqBz/4wa8AoNbd3R0MBoMxhJCoadpspVJJv/HGGzN2guHgCPB9QRKJBJtMJpWVK1e2rVq16ka3263u3bv3ZGtrK4nFYiGEkKiqqlyv16eOHz8+MyfUOgVZR4DvC7a3txePjo6q69evbxFFsbdYLBYqlYre09MT4ThOVFVVLpfLpWw2O5XNZuuO8ByulACx/T2sDRs2dHEct0BRlEogEPAQQjyNS5Sy2WwunU5LME+mejp8NAR4+S3AunXruvx+f6fL5UIMw4gIIWViYuJiOp0uOiUVhw8iC77cdbxixYqFfr+/0+PxuBBCtNFojOzfv3/CcTuHD0qAjC1Arbu7248x9tXrdalWq1WPHTs2BQCNd7irs85zuGICbO6HVeHSITCoVCpNTk5ONuzfm5tcOMJzuOLrRQ7ePqOMa21tFeEaPfTa4dpzQARv1+5IMBgUDMMwYZ6c2ONwjQm3t7d33hwZ6uDg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODgcJX5v2ezjy1SmYkLAAAAAElFTkSuQmCC]=] },
        ["Script Blade"] = { file = "noir_cursor_07_script_blade.png", data = [=[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]=] },
        ["Light Seraph"] = { file = "noir_cursor_08_light_seraph.png", data = [=[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]=] },
        ["Infinity"] = { file = "noir_cursor_09_infinity.png", data = [=[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]=] },
        ["Azure Glow"] = { file = "noir_cursor_10_azure_glow.png", data = [=[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]=] },
        ["Pink Spark"] = { file = "noir_cursor_11_pink_spark.png", data = [=[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]=] },
    }
    cursorState.bundleCache = {}

    local function assetId(value)
        local digits = tostring(value or ""):match("(%d+)")
        return digits and ("rbxassetid://" .. digits) or ""
    end
    local function isShiftLockVisual(instance)
        if not (instance and (instance:IsA("ImageLabel") or instance:IsA("ImageButton"))) then return false end
        local name = string.lower(instance.Name)
        for _, keyword in ipairs({ "mouselock", "shiftlock", "crosshair", "reticle", "aim", "target", "cursor" }) do if string.find(name, keyword, 1, true) then return true end end
        return false
    end
    local function restoreShiftLockVisuals()
        for instance, original in pairs(cursorState.originalVisuals) do
            if instance and instance.Parent then pcall(function()
                instance.Image = original.image
                instance.ImageColor3 = original.color
                instance.ImageTransparency = original.transparency
                instance.Size = original.size
                instance.ScaleType = original.scaleType
            end) end
        end
        table.clear(cursorState.originalVisuals)
        pcall(function()
            if cursorState.originalMouseIcon ~= nil then LocalPlayer:GetMouse().Icon = cursorState.originalMouseIcon end
            cursorState.originalMouseIcon = nil
        end)
    end
    local function selectedCursorImage()
        if cursorState.template == "Custom" then return assetId(cursorState.customId) end
        local direct = cursorState.templateImages[cursorState.template]
        if direct then return direct end
        local cached = cursorState.bundleCache[cursorState.template]
        if cached ~= nil then return cached end
        local bundle = cursorState.bundles[cursorState.template]
        if not bundle then return "" end
        local loader = type(getcustomasset) == "function" and getcustomasset or (type(getsynasset) == "function" and getsynasset or nil)
        if not loader or type(writefile) ~= "function" then cursorState.bundleCache[cursorState.template] = ""; return "" end
        local path = ASSETS_FOLDER .. "/" .. bundle.file
        if not fileExists(path) then
            local decoded
            local ok = pcall(function() decoded = HttpService:Base64Decode(bundle.data) end)
            if not ok or type(decoded) ~= "string" then cursorState.bundleCache[cursorState.template] = ""; return "" end
            ensureStorageFolders()
            if not pcall(writefile, path, decoded) then cursorState.bundleCache[cursorState.template] = ""; return "" end
        end
        local ok, asset = pcall(loader, path)
        cursorState.bundleCache[cursorState.template] = (ok and type(asset) == "string") and asset or ""
        return cursorState.bundleCache[cursorState.template]
    end
    local function applyToShiftLockVisual(instance)
        if not cursorState.enabled or not isShiftLockVisual(instance) then return end
        if cursorState.originalVisuals[instance] == nil then
            cursorState.originalVisuals[instance] = { image = instance.Image, color = instance.ImageColor3, transparency = instance.ImageTransparency, size = instance.Size, scaleType = instance.ScaleType }
        end
        local original, selectedImage = cursorState.originalVisuals[instance], selectedCursorImage()
        pcall(function()
            if selectedImage ~= "" then
                instance.Image = selectedImage
                instance.ImageColor3 = cursorState.colorEnabled and cursorState.color or Color3.new(1, 1, 1)
                instance.ImageTransparency = 0
                instance.ScaleType = Enum.ScaleType.Stretch
                if math.abs(instance.AnchorPoint.X - .5) < .01 and math.abs(instance.AnchorPoint.Y - .5) < .01 then
                    local amount = math.clamp(tonumber(cursorState.artworkScale) or 1.35, .75, 2)
                    instance.Size = UDim2.new(original.size.X.Scale * amount, math.floor(original.size.X.Offset * amount + .5), original.size.Y.Scale * amount, math.floor(original.size.Y.Offset * amount + .5))
                else instance.Size = original.size end
            else
                instance.Image, instance.ImageColor3, instance.ImageTransparency = original.image, (cursorState.colorEnabled and cursorState.color or original.color), original.transparency
                instance.Size, instance.ScaleType = original.size, original.scaleType
            end
        end)
    end
    local function refreshCachedVisuals()
        for instance in pairs(cursorState.originalVisuals) do
            if instance and instance.Parent then applyToShiftLockVisual(instance) else cursorState.originalVisuals[instance] = nil end
        end
    end
    local function scanForShiftLockVisuals()
        for _, parent in ipairs({ CoreGui, LocalPlayer:FindFirstChildOfClass("PlayerGui") }) do
            if parent then for _, instance in ipairs(parent:GetDescendants()) do applyToShiftLockVisual(instance) end end
        end
    end
    local function applyCursor(scan)
        if not cursorState.enabled then restoreShiftLockVisuals(); return end
        local selectedImage = selectedCursorImage()
        pcall(function()
            local mouse = LocalPlayer:GetMouse()
            if cursorState.originalMouseIcon == nil then cursorState.originalMouseIcon = mouse.Icon end
            mouse.Icon = selectedImage ~= "" and selectedImage or cursorState.originalMouseIcon
        end)
        if scan then scanForShiftLockVisuals() else refreshCachedVisuals() end
    end
    local function setCursorEnabled(enabled)
        cursorState.enabled = enabled == true
        applyCursor(cursorState.enabled)
    end
    local function watchShiftLock(parent)
        if not parent then return end
        parent.DescendantAdded:Connect(function(instance)
            if cursorState.enabled and isShiftLockVisual(instance) then task.defer(function() applyToShiftLockVisual(instance) end) end
        end)
    end
    watchShiftLock(CoreGui)
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 5)
    watchShiftLock(playerGui)

    local cursorSection = tab:AddSection("MISC \u{2022} CUSTOMIZE CURSOR", "Replaces the existing Shift Lock/crosshair image; no second cursor is added")
    cursorSection:AddToggle("Enable Custom Cursor", setCursorEnabled)
    local savedTemplate = NoirPersistence.data.dropdowns["MISC \u{2022} CUSTOMIZE CURSOR::Cursor Design"] or NoirPersistence.data.dropdowns["MISC \u{2022} CUSTOMIZE CURSOR::Template Cursor"]
    if savedTemplate == "Custom Image" then savedTemplate = "Custom" end
    cursorState.template = table.find(cursorState.templates, savedTemplate) and savedTemplate or "Default"
    local templateControl = cursorSection:AddDropdown("Cursor Design", cursorState.templates, function(value) cursorState.template = value; applyCursor(false) end)
    templateControl:SetValue(cursorState.template)
    cursorSection:AddToggle("Enable Cursor Color", function(enabled) cursorState.colorEnabled = enabled == true; applyCursor(false) end)
    cursorSection:AddColorpicker("Cursor Color", C.accent, function(color) cursorState.color = color; applyCursor(false) end)
    cursorSection:AddSlider("Cursor Artwork Scale", 75, 200, 135, function(value) cursorState.artworkScale = (tonumber(value) or 135) / 100; applyCursor(false) end)
    cursorState.customId = tostring(NoirPersistence.data.textboxes["MISC \u{2022} CUSTOMIZE CURSOR::Custom Cursor ID"] or "")
    local customIdControl = cursorSection:AddTextBox("Custom Cursor ID", function(value)
        cursorState.customId = tostring(value or ""):sub(1, 100)
        NoirPersistence.data.textboxes["MISC \u{2022} CUSTOMIZE CURSOR::Custom Cursor ID"] = cursorState.customId
        NoirPersistence.Save(); applyCursor(false)
    end)
    customIdControl:SetValue(cursorState.customId)
end

-- Main universal utilities: all state stays in this scope while the connections retain only what they need.
do
    local universalState = {
        infiniteJump = false,
        invisible = false,
        invisibleOriginals = {},
        invisibleCharacter = nil,
        invisibleHumanoid = nil,
        invisibleRoot = nil,
        invisibleBindEnabled = false,
        invisibleBindGui = nil,
        invisibleBindButton = nil,
        invisibleBindSize = .105,
        invisibleBindConnections = {},
    }

    local function disconnectAll(list)
        for _, connection in ipairs(list) do pcall(function() connection:Disconnect() end) end
        table.clear(list)
    end

    -- Integrated from the supplied invisibility method: a short down-frame desync while the toggle is active.
    local function restoreInvisible()
        for instance, transparency in pairs(universalState.invisibleOriginals) do
            if instance and instance.Parent then pcall(function() instance.Transparency = transparency end) end
        end
        table.clear(universalState.invisibleOriginals)
    end

    local function setupInvisibleCharacter(character)
        universalState.invisibleCharacter = character or LocalPlayer.Character
        local current = universalState.invisibleCharacter
        universalState.invisibleHumanoid = current and current:FindFirstChildWhichIsA("Humanoid") or nil
        universalState.invisibleRoot = current and current:FindFirstChild("HumanoidRootPart") or nil
        table.clear(universalState.invisibleOriginals)
        if not current then return end
        for _, instance in ipairs(current:GetDescendants()) do
            -- Keep already-hidden parts such as HumanoidRootPart hidden; only fade visible body/accessory parts.
            if instance:IsA("BasePart") and instance.Transparency == 0 then
                universalState.invisibleOriginals[instance] = instance.Transparency
            end
        end
    end

    local function setInvisibleTransparency(value)
        for instance in pairs(universalState.invisibleOriginals) do
            if instance and instance.Parent then pcall(function() instance.Transparency = value end) end
        end
    end

    local function applyInvisible()
        restoreInvisible()
        if not universalState.invisible then return end
        setupInvisibleCharacter(LocalPlayer.Character)
        -- The supplied script uses half-transparency before the desync pass.
        setInvisibleTransparency(.5)
    end

    local function setInvisible(enabled)
        universalState.invisible = enabled == true
        applyInvisible()
        updateInvisibleBindText()
    end

    RunService.Heartbeat:Connect(function()
        if not universalState.invisible then return end
        local root, humanoid = universalState.invisibleRoot, universalState.invisibleHumanoid
        if not (root and root.Parent and humanoid and humanoid.Parent) then
            setupInvisibleCharacter(LocalPlayer.Character)
            root, humanoid = universalState.invisibleRoot, universalState.invisibleHumanoid
        end
        if not (root and humanoid) then return end
        local originalCFrame, originalOffset = root.CFrame, humanoid.CameraOffset
        local downCFrame = originalCFrame * CFrame.new(0, -200000, 0)
        local ok = pcall(function()
            root.CFrame = downCFrame
            humanoid.CameraOffset = downCFrame:ToObjectSpace(CFrame.new(originalCFrame.Position)).Position
        end)
        if not ok then return end
        RunService.RenderStepped:Wait()
        pcall(function()
            if root.Parent then root.CFrame = originalCFrame end
            if humanoid.Parent then humanoid.CameraOffset = originalOffset end
        end)
    end)

    local function updateInvisibleBindText()
        local button = universalState.invisibleBindButton
        if not button then return end
        local label = button:FindFirstChild("Text")
        if label then label.Text = universalState.invisible and "Invisible\nON" or "Invisible\nOFF" end
    end

    local function setInvisible(enabled)
        universalState.invisible = enabled == true
        applyInvisible()
        updateInvisibleBindText()
    end

    local function removeInvisibleBindButton()
        disconnectAll(universalState.invisibleBindConnections)
        if universalState.invisibleBindGui then universalState.invisibleBindGui:Destroy() end
        universalState.invisibleBindGui, universalState.invisibleBindButton = nil, nil
        for _, parent in ipairs({ guiParent, CoreGui, LocalPlayer:FindFirstChildOfClass("PlayerGui") }) do
            if typeof(parent) == "Instance" then
                local stale = parent:FindFirstChild("NoirInvisibleBindButton")
                if stale then stale:Destroy() end
            end
        end
    end

    local function updateInvisibleBindButtonSize()
        local button, camera = universalState.invisibleBindButton, Workspace.CurrentCamera
        if not button or not camera then return end
        local screen = camera.ViewportSize
        local heightScale = universalState.invisibleBindSize
        button.Size = UDim2.new(heightScale * (screen.Y / math.max(screen.X, 1)), 0, heightScale, 0)
    end

    local function createInvisibleBindButton()
        if universalState.invisibleBindButton then return end
        removeInvisibleBindButton()
        local parent = guiParent
        if typeof(parent) ~= "Instance" then parent = LocalPlayer:WaitForChild("PlayerGui") end
        local bindGui = Instance.new("ScreenGui")
        bindGui.Name, bindGui.ResetOnSpawn, bindGui.IgnoreGuiInset, bindGui.DisplayOrder = "NoirInvisibleBindButton", false, true, 82
        bindGui.Parent = parent

        local button = Instance.new("ImageButton")
        button.Name = "Invisible"
        button.AnchorPoint = Vector2.new(.5, .5)
        button.Position = NoirPersistence.GetPosition("invisible_bind_v1", UDim2.new(.24, 0, .88, 0))
        button.Size = UDim2.new(universalState.invisibleBindSize, 0, universalState.invisibleBindSize, 0)
        button.BackgroundColor3, button.BackgroundTransparency, button.BorderSizePixel = Color3.fromRGB(8, 8, 10), .28, 0
        button.Image, button.AutoButtonColor, button.ZIndex = "", false, 5
        button.Parent = bindGui
        local round = Instance.new("UICorner"); round.CornerRadius = UDim.new(1, 0); round.Parent = button
        local aspect = Instance.new("UIAspectRatioConstraint"); aspect.AspectRatio = 1; aspect.Parent = button
        local outerStroke = Instance.new("UIStroke")
        outerStroke.Color, outerStroke.Thickness, outerStroke.ApplyStrokeMode, outerStroke.Parent = Color3.fromRGB(255, 255, 255), 2, Enum.ApplyStrokeMode.Border, button
        local outerGradient = Instance.new("UIGradient")
        outerGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(35,35,40)), ColorSequenceKeypoint.new(.22, Color3.fromRGB(250,250,252)),
            ColorSequenceKeypoint.new(.48, Color3.fromRGB(70,70,78)), ColorSequenceKeypoint.new(.72, Color3.fromRGB(255,255,255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(45,45,52)),
        })
        outerGradient.Parent = outerStroke
        local innerStroke = Instance.new("UIStroke")
        innerStroke.Color, innerStroke.Transparency, innerStroke.Thickness, innerStroke.Parent = Color3.fromRGB(105,105,112), .5, 1, button
        local innerGradient = outerGradient:Clone(); innerGradient.Rotation = 180; innerGradient.Parent = innerStroke
        local label = Instance.new("TextLabel")
        label.Name, label.AnchorPoint, label.Position, label.Size = "Text", Vector2.new(.5,.5), UDim2.fromScale(.5,.5), UDim2.fromScale(.76,.76)
        label.BackgroundTransparency, label.TextColor3, label.TextSize, label.TextWrapped, label.Font, label.ZIndex = 1, Color3.fromRGB(245,245,248), 14, true, Enum.Font.Gotham, 6
        label.Parent = button

        local dragging, moved, dragStart, startPosition, dragInput = false, false, nil, nil, nil
        universalState.invisibleBindConnections[#universalState.invisibleBindConnections + 1] = button.InputBegan:Connect(function(input)
            if not isPrimaryPress(input) then return end
            dragging, moved, dragStart, startPosition = true, false, input.Position, button.Position
        end)
        universalState.invisibleBindConnections[#universalState.invisibleBindConnections + 1] = button.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
        end)
        universalState.invisibleBindConnections[#universalState.invisibleBindConnections + 1] = UIS.InputChanged:Connect(function(input)
            if not dragging or input ~= dragInput then return end
            local delta = input.Position - dragStart
            if delta.Magnitude > 7 then moved = true end
            button.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end)
        universalState.invisibleBindConnections[#universalState.invisibleBindConnections + 1] = UIS.InputEnded:Connect(function(input)
            if not dragging or not isPrimaryPress(input) then return end
            dragging = false
            NoirPersistence.SetPosition("invisible_bind_v1", button.Position)
        end)
        universalState.invisibleBindConnections[#universalState.invisibleBindConnections + 1] = button.Activated:Connect(function()
            if not moved then setInvisible(not universalState.invisible) end
        end)
        universalState.invisibleBindConnections[#universalState.invisibleBindConnections + 1] = RunService.RenderStepped:Connect(function()
            if outerGradient.Parent then outerGradient.Rotation = (outerGradient.Rotation + 1) % 360 end
        end)
        universalState.invisibleBindGui, universalState.invisibleBindButton = bindGui, button
        updateInvisibleBindButtonSize()
        updateInvisibleBindText()
    end

    local function setInvisibleBindButton(enabled)
        universalState.invisibleBindEnabled = enabled == true
        if universalState.invisibleBindEnabled then createInvisibleBindButton() else removeInvisibleBindButton() end
    end


    -- Adapted AntiFling core from the supplied FlingGui: other characters' collision parts are locally disabled while active.
    universalState.antiFling = false
    universalState.antiFlingTracked = {}
    universalState.antiFlingPartSignals = {}
    universalState.antiFlingNextPart = nil

    local function antiFlingClearPart(part)
        local signal = universalState.antiFlingPartSignals[part]
        if signal then pcall(function() signal:Disconnect() end) end
        universalState.antiFlingPartSignals[part] = nil
        universalState.antiFlingTracked[part] = nil
    end

    local function antiFlingTrackPart(part)
        if not (part and part:IsA("BasePart")) or universalState.antiFlingTracked[part] ~= nil then return end
        universalState.antiFlingTracked[part] = part.CanCollide
        universalState.antiFlingPartSignals[part] = part:GetPropertyChangedSignal("CanCollide"):Connect(function()
            if universalState.antiFling and part.Parent and part.CanCollide then part.CanCollide = false end
        end)
        if universalState.antiFling and part.CanCollide then part.CanCollide = false end
    end

    local function antiFlingSeedCharacter(character)
        if not character then return end
        for _, instance in ipairs(character:GetDescendants()) do
            if instance:IsA("BasePart") then antiFlingTrackPart(instance) end
        end
        character.DescendantAdded:Connect(function(instance)
            if instance:IsA("BasePart") then antiFlingTrackPart(instance) end
        end)
        character.DescendantRemoving:Connect(function(instance)
            if instance:IsA("BasePart") then antiFlingClearPart(instance) end
        end)
    end

    local function antiFlingHookPlayer(player)
        if player == LocalPlayer then return end
        if player.Character then antiFlingSeedCharacter(player.Character) end
        player.CharacterAdded:Connect(antiFlingSeedCharacter)
        player.CharacterRemoving:Connect(function(character)
            for _, instance in ipairs(character:GetDescendants()) do antiFlingClearPart(instance) end
        end)
    end

    local function setAntiFling(enabled)
        universalState.antiFling = enabled == true
        if universalState.antiFling then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then antiFlingSeedCharacter(player.Character) end
            end
            for part in pairs(universalState.antiFlingTracked) do
                if part and part.Parent and part.CanCollide then part.CanCollide = false end
            end
        else
            -- Restore the CanCollide values that were present before AntiFling was enabled.
            for part, originalCanCollide in pairs(universalState.antiFlingTracked) do
                if part and part.Parent then pcall(function() part.CanCollide = originalCanCollide end) end
            end
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do antiFlingHookPlayer(player) end
    Players.PlayerAdded:Connect(antiFlingHookPlayer)
    Players.PlayerRemoving:Connect(function(player)
        if player.Character then
            for _, instance in ipairs(player.Character:GetDescendants()) do antiFlingClearPart(instance) end
        end
    end)
    local antiFlingStep = RunService.PreSimulation or RunService.Stepped
    antiFlingStep:Connect(function()
        if not universalState.antiFling then return end
        local quota, cursor = 256, universalState.antiFlingNextPart
        if cursor and universalState.antiFlingTracked[cursor] == nil then cursor = nil end
        while quota > 0 do
            cursor = next(universalState.antiFlingTracked, cursor)
            if not cursor then universalState.antiFlingNextPart = nil; break end
            if cursor.Parent then
                if cursor.CanCollide then cursor.CanCollide = false end
                universalState.antiFlingNextPart = cursor
            else
                antiFlingClearPart(cursor)
                universalState.antiFlingNextPart = nil
            end
            quota = quota - 1
        end
    end)


    UIS.JumpRequest:Connect(function()
        if not universalState.infiniteJump then return end
        local humanoid = localHumanoid()
        if humanoid and humanoid.Health > 0 then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
    LocalPlayer.CharacterAdded:Connect(function(character)
        task.wait(1)
        setupInvisibleCharacter(character)
        if universalState.invisible then setInvisibleTransparency(.5) end
    end)

    local universalMods = tab:AddSection("MAIN \u{2022} UNIVERSAL", "Movement and survival utilities")
    universalMods:AddToggle("Infinite Jump", function(enabled) universalState.infiniteJump = enabled == true end)
    universalMods:AddToggle("AntiFling", setAntiFling)

    local invisibleMods = tab:AddSection("MAIN \u{2022} INVISIBLE", "Desync invisibility and floating bind button")
    invisibleMods:AddToggle("Invisible", setInvisible)
    invisibleMods:AddToggle("Enable Invisible Bind Button", setInvisibleBindButton)
    invisibleMods:AddSlider("Invisible Bind Button Size", 5, 25, universalState.invisibleBindSize * 100, function(value)
        universalState.invisibleBindSize = (tonumber(value) or 10.5) / 100
        updateInvisibleBindButtonSize()
    end)
    invisibleMods:AddLabel("Round Invisible button: tap to toggle; drag it to move. Its size and position are saved.")
    if not universalState.invisibleBindEnabled then removeInvisibleBindButton() end

end


task.defer(function()
    -- then restores the local movement CFrame. This keeps local movement responsive while sending
    -- the saved location to the server on the desync frame.
    local desyncState = {
        enabled = false,
        anchorCFrame = nil,
        bindEnabled = false,
        bindGui = nil,
        bindButton = nil,
        bindSize = .105,
        bindConnections = {},
        bindOuterGradient = nil,
        bindInnerGradient = nil,
    }
    local desyncToggleControl, syncingDesyncToggle = nil, false
    local monochromeGradient = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 40)), ColorSequenceKeypoint.new(.22, Color3.fromRGB(250, 250, 252)),
        ColorSequenceKeypoint.new(.48, Color3.fromRGB(70, 70, 78)), ColorSequenceKeypoint.new(.72, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(45, 45, 52)),
    })
    local rubyGradient = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(104, 18, 32)), ColorSequenceKeypoint.new(.24, Color3.fromRGB(255, 126, 145)),
        ColorSequenceKeypoint.new(.5, Color3.fromRGB(185, 38, 62)), ColorSequenceKeypoint.new(.76, Color3.fromRGB(255, 170, 183)), ColorSequenceKeypoint.new(1, Color3.fromRGB(112, 18, 35)),
    })
    local function updateDesyncBindText()
        local button = desyncState.bindButton
        local label = button and button:FindFirstChild("Text")
        if label then label.Text = "Desync" end
        if desyncState.bindOuterGradient then desyncState.bindOuterGradient.Color = desyncState.enabled and rubyGradient or monochromeGradient end
        if desyncState.bindInnerGradient then desyncState.bindInnerGradient.Color = desyncState.enabled and rubyGradient or monochromeGradient end
    end
    local function setDesync(enabled)
        desyncState.enabled = enabled == true
        if desyncState.enabled then
            local root = localRoot()
            desyncState.anchorCFrame = root and root.CFrame or nil
            if not desyncState.anchorCFrame then desyncState.enabled = false end
        else
            desyncState.anchorCFrame = nil
            local pendingRoot, pendingCFrame = desyncState.pendingRoot, desyncState.pendingCFrame
            desyncState.pendingRoot, desyncState.pendingCFrame = nil, nil
            if pendingRoot and pendingRoot.Parent and pendingCFrame then pcall(function() pendingRoot.CFrame = pendingCFrame end) end
        end
        updateDesyncBindText()
        if desyncToggleControl and not syncingDesyncToggle then
            syncingDesyncToggle = true
            desyncToggleControl(desyncState.enabled)
            syncingDesyncToggle = false
        end
    end
    local function disconnectDesyncBind()
        for _, connection in ipairs(desyncState.bindConnections) do pcall(function() connection:Disconnect() end) end
        table.clear(desyncState.bindConnections)
    end
    local function removeDesyncBindButton()
        disconnectDesyncBind()
        if desyncState.bindGui then desyncState.bindGui:Destroy() end
        desyncState.bindGui, desyncState.bindButton = nil, nil
        for _, parent in ipairs({ guiParent, CoreGui, LocalPlayer:FindFirstChildOfClass("PlayerGui") }) do
            if parent then
                local stale = parent:FindFirstChild("NoirDesyncBindButton")
                if stale then stale:Destroy() end
            end
        end
    end
    local function updateDesyncBindSize()
        local button, camera = desyncState.bindButton, Workspace.CurrentCamera
        if not button or not camera then return end
        local viewport = camera.ViewportSize
        local h = desyncState.bindSize
        button.Size = UDim2.new(h * (viewport.Y / math.max(viewport.X, 1)), 0, h, 0)
    end
    local function createDesyncBindButton()
        if desyncState.bindButton then return end
        removeDesyncBindButton()
        local parent = guiParent
        if typeof(parent) ~= "Instance" then parent = LocalPlayer:WaitForChild("PlayerGui") end
        local bindGui = New("ScreenGui", { Parent = parent, Name = "NoirDesyncBindButton", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 83, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
        local button = New("ImageButton", { Parent = bindGui, Name = "Desync", AnchorPoint = Vector2.new(.5, .5),
            Position = NoirPersistence.GetPosition("desync_bind_v1", UDim2.new(.35, 0, .88, 0)), Size = UDim2.fromScale(desyncState.bindSize, desyncState.bindSize),
            BackgroundColor3 = Color3.fromRGB(8, 8, 10), BackgroundTransparency = .28, BorderSizePixel = 0,
            Image = "", AutoButtonColor = false, ClipsDescendants = false, ZIndex = 7 })
        -- Same circular body, double metallic stroke and centered label as Grab Gun.
        corner(button, 999)
        local aspect = New("UIAspectRatioConstraint", { Parent = button, AspectRatio = 1, AspectType = Enum.AspectType.ScaleWithParentSize })
        local outer = New("UIStroke", { Parent = button, Color = Color3.fromRGB(255, 255, 255), Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
        local outerGradient = New("UIGradient", { Parent = outer, Color = monochromeGradient })
        table.insert(gradientStrokes, outerGradient)
        local inner = New("UIStroke", { Parent = button, Color = Color3.fromRGB(105, 105, 112), Transparency = .5, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
        local innerGradient = outerGradient:Clone(); innerGradient.Rotation = 180; innerGradient.Parent = inner; table.insert(gradientStrokes, innerGradient)
        desyncState.bindOuterGradient, desyncState.bindInnerGradient = outerGradient, innerGradient
        local label = New("TextLabel", { Parent = button, Name = "Text", AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromScale(.76, .76),
            BackgroundTransparency = 1, Text = "Desync\nOFF", TextColor3 = Color3.fromRGB(245, 245, 248), TextSize = 14, TextWrapped = true, Font = Enum.Font.Gotham, ZIndex = 8 })
        local pressScale = New("UIScale", { Parent = button, Scale = 1 })
        local dragging, moved, startInput, startPosition, dragInput = false, false, nil, nil, nil
        desyncState.bindConnections[#desyncState.bindConnections + 1] = RunService.RenderStepped:Connect(function()
            if outerGradient.Parent then outerGradient.Rotation = (outerGradient.Rotation + 1) % 360 end
        end)
        desyncState.bindConnections[#desyncState.bindConnections + 1] = button.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging, moved, startInput, startPosition = true, false, input.Position, button.Position
                TweenService:Create(pressScale, TweenInfo.new(.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Scale = 1.035 }):Play()
            end
        end)
        desyncState.bindConnections[#desyncState.bindConnections + 1] = button.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
        end)
        desyncState.bindConnections[#desyncState.bindConnections + 1] = UIS.InputChanged:Connect(function(input)
            if not dragging or input ~= dragInput then return end
            local delta = input.Position - startInput
            if delta.Magnitude > 7 then moved = true end
            button.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end)
        desyncState.bindConnections[#desyncState.bindConnections + 1] = UIS.InputEnded:Connect(function(input)
            if not dragging or not (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then return end
            dragging = false
            TweenService:Create(pressScale, TweenInfo.new(.20, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
            if moved then
                NoirPersistence.SetPosition("desync_bind_v1", button.Position)
            else
                -- Touch InputEnded is reliable on mobile; use it directly instead of a second Activated callback.
                setDesync(not desyncState.enabled)
            end
        end)
        desyncState.bindGui, desyncState.bindButton = bindGui, button
        updateDesyncBindSize(); updateDesyncBindText()
    end
    local function setDesyncBindButton(enabled)
        desyncState.bindEnabled = enabled == true
        if desyncState.bindEnabled then createDesyncBindButton() else removeDesyncBindButton() end
    end
    -- Restore before Roblox's camera step. CameraOffset is deliberately untouched, avoiding the camera jump from the first version.
    desyncState.pendingRoot, desyncState.pendingCFrame = nil, nil
    RunService:BindToRenderStep("NoirDesyncRestore_" .. tostring(LocalPlayer.UserId), Enum.RenderPriority.Camera.Value - 1, function()
        local root, cframe = desyncState.pendingRoot, desyncState.pendingCFrame
        desyncState.pendingRoot, desyncState.pendingCFrame = nil, nil
        if root and root.Parent and cframe then pcall(function() root.CFrame = cframe end) end
    end)
    RunService.Heartbeat:Connect(function()
        if not desyncState.enabled then return end
        local root = localRoot()
        if not root or not root.Parent then return end
        if not desyncState.anchorCFrame then desyncState.anchorCFrame = root.CFrame end
        local localCFrame = root.CFrame
        desyncState.pendingRoot, desyncState.pendingCFrame = root, localCFrame
        pcall(function() root.CFrame = desyncState.anchorCFrame end)
    end)
    LocalPlayer.CharacterAdded:Connect(function(character)
        if desyncState.enabled then
            task.wait(.35)
            local root = character:FindFirstChild("HumanoidRootPart")
            if root then desyncState.anchorCFrame = root.CFrame end
        end
    end)

    local desyncMods = tab:AddSection("MISC \u{2022} DESYNC", "Keeps the server-facing character position at the activation point")
    desyncToggleControl = desyncMods:AddToggle("Desync", function(enabled)
        if not syncingDesyncToggle then setDesync(enabled) end
    end)
    desyncMods:AddToggle("Enable Desync Bind Button", setDesyncBindButton)
    desyncMods:AddSlider("Desync Bind Button Size", 5, 25, desyncState.bindSize * 100, function(value)
        desyncState.bindSize = (tonumber(value) or 10.5) / 100
        updateDesyncBindSize()
    end)
    desyncMods:AddLabel("Enable Desync to save the current position; you can then move locally while its saved position is sent on desync frames.")
    if not desyncState.bindEnabled then removeDesyncBindButton() end
end)

-- Visuals are compiled in a separate deferred chunk.  The primary UI stays identical to the last verified mobile-safe build.
local __noirVisualContext = {
    tab = tab, players = Players, workspace = Workspace, runService = RunService,
    localPlayer = LocalPlayer, getPlayers = getPlayers, roleCache = roleCache,
    getMurderer = function() return murderer end, getSheriff = function() return sheriff end,
    getHero = function() return hero end, getRoundState = function() return roundState end,
    -- Visuals can request a role read immediately instead of waiting for their periodic update cycle.
    refreshRoles = function() task.spawn(refreshTarget) end,
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
local __noirVisualSource = [==[
-- Visuals run as a deferred satellite chunk so the main Noir loader remains within mobile executor limits.
local V = getgenv().__NoirV4VisualContext
if type(V) ~= "table" or not V.tab then return end

local state = {
    revision = 0,
    feature = {
        cham = {everyone=false,murderer=false,sheriff=false,hero=false,dead=false},
        esp = {everyone=false,murderer=false,sheriff=false,hero=false,dead=false},
        outline = {everyone=false,murderer=false,sheriff=false,hero=false,dead=false},
        highlight = {everyone=false,murderer=false,sheriff=false,hero=false,dead=false},
        tracer = {everyone=false,murderer=false,sheriff=false,hero=false,dead=false},
        box = {everyone=false,murderer=false,sheriff=false,hero=false,dead=false},
        avatar = {everyone=false,murderer=false,sheriff=false,hero=false,dead=false},
        fire = {everyone=false,murderer=false,sheriff=false,hero=false,dead=false},
    },
    object = {gun=false,knife=false},
}
local entries, objectEntries = {}, {}
-- Players who join after role reveal are lobby spectators until the next role reveal.
local joinedLobby, roleRevealActive = {}, false
local drawingState = nil
local prefix = "NoirSatelliteVisual_"

local function safe(label, callback)
    local ok, err = pcall(callback)
    if not ok then warn("[Noir Visuals] " .. tostring(label) .. ": " .. tostring(err)) end
    return ok
end
-- Refresh roles as soon as the Visuals satellite starts, then retry while MM2 finishes assigning roles.
task.spawn(function()
    for _, pause in ipairs({0, .25, .6, 1.2, 2}) do
        if pause > 0 then task.wait(pause) end
        if V.refreshRoles then safe("initial role refresh", V.refreshRoles) end
    end
end)
local function color(role)
    if role == "murderer" then return Color3.fromRGB(255,72,82) end
    if role == "sheriff" then return Color3.fromRGB(72,158,255) end
    if role == "hero" then return Color3.fromRGB(255,206,72) end
    if role == "dead" then return Color3.fromRGB(150,150,158) end
    return Color3.fromRGB(86,230,145)
end
local function isInactive(player, character, cached)
    if cached == "dead" or joinedLobby[player] then return true end
    local round = V.getRoundState and V.getRoundState() or "waiting"
    -- During map voting there are no assigned roles yet: all players are lobby/inactive.
    -- Once the 10-second role reveal has started, known players can use their actual roles.
    if round == "waiting" and not (V.isRoleRevealActive and V.isRoleRevealActive()) then return true end
    local teamName = player.Team and string.lower(tostring(player.Team.Name)) or ""
    if string.find(teamName,"lobby",1,true) or string.find(teamName,"spectat",1,true)
        or string.find(teamName,"waiting",1,true) or string.find(teamName,"observer",1,true) then return true end
    for _, container in ipairs({player, character}) do
        if container then
            for key, value in pairs(container:GetAttributes()) do
                local name = string.lower(tostring(key))
                if (string.find(name,"inround",1,true) or string.find(name,"ingame",1,true)
                    or string.find(name,"isplaying",1,true) or string.find(name,"alive",1,true)) and value == false then return true end
                if string.find(name,"state",1,true) or string.find(name,"status",1,true) or string.find(name,"location",1,true) then
                    local text = string.lower(tostring(value))
                    if string.find(text,"lobby",1,true) or string.find(text,"spectat",1,true)
                        or string.find(text,"dead",1,true) or string.find(text,"waiting",1,true) then return true end
                end
            end
            for _, name in ipairs({"InLobby","Spectating","Dead","IsDead"}) do
                local flag = container:FindFirstChild(name)
                if flag and flag:IsA("BoolValue") and flag.Value then return true end
            end
        end
    end
    return false
end
local function roleOf(player, character)
    local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
    local cached = V.roleCache and V.roleCache[player.UserId]
    if not humanoid or humanoid.Health <= 0 or isInactive(player, character, cached) then return "dead" end
    if player == V.getMurderer() or cached == "murderer" then return "murderer" end
    if player == V.getSheriff() or cached == "sheriff" then return "sheriff" end
    if player == V.getHero() or cached == "hero" then return "hero" end
    return "innocent"
end
local function wanted(kind, role)
    local f = state.feature[kind]
    return f and (f.everyone or f[role]) or false
end
local function anyPlayerVisual()
    for _, filters in pairs(state.feature) do
        for _, enabled in pairs(filters) do if enabled then return true end end
    end
    return false
end
local function clearPlayer(player)
    local e = entries[player]
    if not e then return end
    if e.line then pcall(function() e.line:Remove() end) end
    for _, item in ipairs(e.items) do pcall(function() item:Destroy() end) end
    entries[player] = nil
end
local function highlight(character, suffix, tint, fill, outline, e)
    local h = Instance.new("Highlight")
    h.Name = prefix .. suffix
    h.Adornee = character
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.FillColor, h.OutlineColor = tint, tint
    h.FillTransparency, h.OutlineTransparency = fill, outline
    h.Parent = character
    table.insert(e.items, h)
end
local function billboard(root, suffix, size, offset, e)
    local b = Instance.new("BillboardGui")
    b.Name = prefix .. suffix
    b.Adornee = root
    b.AlwaysOnTop = true
    b.Size = size
    b.StudsOffset = offset
    b.Parent = root
    table.insert(e.items, b)
    return b
end
local function apply(player)
    if player == V.localPlayer then return end
    local character = player.Character
    if not character then clearPlayer(player); return end
    local root = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    local role = roleOf(player, character)
    local sign = tostring(state.revision) .. ":" .. role .. ":" .. tostring(root)
    local old = entries[player]
    if old and old.character == character and old.sign == sign then return end
    clearPlayer(player)
    if not anyPlayerVisual() then return end
    local tint = color(role)
    local e = {character=character, sign=sign, tint=tint, items={}, line=nil}
    entries[player] = e
    if wanted("cham",role) then highlight(character,"Cham",tint,.45,1,e) end
    if wanted("outline",role) then highlight(character,"Outline",tint,1,0,e) end
    if wanted("highlight",role) then highlight(character,"Highlight",tint,.68,.05,e) end
    if wanted("tracer",role) then
        if drawingState == nil then
            local ok, api = pcall(function() return Drawing end)
            drawingState = ok and type(api) == "table" and type(api.new) == "function" and api or false
        end
        if drawingState then
            local line = drawingState.new("Line")
            line.Thickness, line.Transparency, line.Color, line.Visible = 1.5, 1, tint, false
            e.line = line
        end
    end
    if root and wanted("esp",role) then
        local b = billboard(root,"ESP",UDim2.fromOffset(156,42),Vector3.new(0,3.4,0),e)
        local l = Instance.new("TextLabel")
        l.Size, l.BackgroundTransparency, l.Font, l.TextSize = UDim2.fromScale(1,1), 1, Enum.Font.GothamSemibold, 14
        l.TextColor3, l.TextStrokeTransparency = Color3.new(1,1,1), .35
        l.Text, l.Parent = player.DisplayName .. "\n" .. string.upper(role), b
    end
    if root and wanted("box",role) then
        local b = billboard(root,"Box",UDim2.fromOffset(86,122),Vector3.new(0,1.8,0),e)
        local f = Instance.new("Frame")
        f.Size, f.BackgroundTransparency, f.Parent = UDim2.fromScale(1,1), 1, b
        local s = Instance.new("UIStroke")
        s.Color, s.Thickness, s.Parent = tint, 1.7, f
    end
    if root and wanted("avatar",role) then
        local b = billboard(root,"Avatar",UDim2.fromOffset(58,58),Vector3.new(0,4.8,0),e)
        local image = Instance.new("ImageLabel")
        image.Size, image.BackgroundColor3, image.BorderSizePixel, image.Parent = UDim2.fromScale(1,1), Color3.fromRGB(12,14,18), 0, b
        local c = Instance.new("UICorner"); c.CornerRadius, c.Parent = UDim.new(1,0), image
        local s = Instance.new("UIStroke"); s.Color, s.Thickness, s.Parent = tint, 1.5, image
        task.spawn(function()
            local ok, asset = pcall(function() return V.players:GetUserThumbnailAsync(player.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size150x150) end)
            if ok and image.Parent then image.Image = asset end
        end)
    end
    if root and wanted("fire",role) then
        local flame = Instance.new("Fire")
        flame.Name, flame.Color, flame.SecondaryColor, flame.Size, flame.Heat, flame.Parent = prefix.."Fire", tint, tint:Lerp(Color3.new(1,1,1),.35), 5, 7, root
        table.insert(e.items, flame)
    end
end
local function refreshPlayers()
    local seen = {}
    for _, player in ipairs(V.getPlayers()) do
        if player ~= V.localPlayer then seen[player] = true; apply(player) end
    end
    for player in pairs(entries) do if not seen[player] then clearPlayer(player) end end
end
local function objectType(instance)
    if not instance:IsA("BasePart") then return nil end
    local owner = instance:FindFirstAncestorOfClass("Model")
    if owner and V.players:GetPlayerFromCharacter(owner) then return nil end
    local name = string.lower(instance.Name)
    if name == "gundrop" or name == "gun" or string.find(name,"droppedgun",1,true) or string.find(name,"gun_drop",1,true) then return "gun" end
    if string.find(name,"throw",1,true) and string.find(name,"knife",1,true) then return "knife" end
end
local function clearObject(instance)
    local e = objectEntries[instance]
    if e then for _, item in ipairs(e) do pcall(function() item:Destroy() end) end; objectEntries[instance] = nil end
end
local function refreshObjects()
    if not state.object.gun and not state.object.knife then
        for instance in pairs(objectEntries) do clearObject(instance) end
        return
    end
    local seen = {}
    for _, instance in ipairs(V.workspace:GetDescendants()) do
        local kind = objectType(instance)
        if kind and state.object[kind] then
            seen[instance] = true
            if not objectEntries[instance] then
                local tint = kind == "gun" and Color3.fromRGB(72,158,255) or Color3.fromRGB(255,126,72)
                local h = Instance.new("Highlight")
                h.Name, h.Adornee, h.DepthMode = prefix.."Object", instance, Enum.HighlightDepthMode.AlwaysOnTop
                h.FillColor, h.OutlineColor, h.FillTransparency, h.OutlineTransparency, h.Parent = tint,tint,.72,0,instance
                local b = Instance.new("BillboardGui")
                b.Name, b.Adornee, b.AlwaysOnTop, b.Size, b.StudsOffset, b.Parent = prefix.."ObjectLabel",instance,true,UDim2.fromOffset(132,24),Vector3.new(0,1.5,0),instance
                local l = Instance.new("TextLabel")
                l.Size,l.BackgroundTransparency,l.Font,l.TextSize,l.TextColor3,l.TextStrokeTransparency,l.Text,l.Parent = UDim2.fromScale(1,1),1,Enum.Font.GothamBold,12,tint,.35,(kind=="gun" and "DROPPED GUN" or "THROWING KNIFE"),b
                objectEntries[instance] = {h,b}
            end
        end
    end
    for instance in pairs(objectEntries) do if not seen[instance] or not instance.Parent then clearObject(instance) end end
end
local function setFilter(kind, filter, enabled)
    state.feature[kind][filter] = enabled == true
    state.revision = state.revision + 1
    safe("player refresh", refreshPlayers)
end
local function setObject(kind, enabled)
    state.object[kind] = enabled == true
    safe("object refresh", refreshObjects)
end
V.runService.RenderStepped:Connect(function()
    if not next(entries) then return end
    safe("tracer", function()
        local camera = V.workspace.CurrentCamera
        if not camera then return end
        local viewport, origin = camera.ViewportSize, nil
        origin = Vector2.new(viewport.X*.5,viewport.Y)
        for _, e in pairs(entries) do
            if e.line then
                local root = e.character and e.character:FindFirstChild("HumanoidRootPart")
                if root then
                    local point, visible = camera:WorldToViewportPoint(root.Position)
                    e.line.From,e.line.To,e.line.Color,e.line.Visible = origin,Vector2.new(point.X,point.Y),e.tint,visible and point.Z>0
                else e.line.Visible = false end
            end
        end
    end)
end)
V.players.PlayerAdded:Connect(function(player)
    -- A user arriving after roles have been dealt is in the lobby for this round.
    if V.isRoleRevealActive and V.isRoleRevealActive() then joinedLobby[player] = true end
end)
V.players.PlayerRemoving:Connect(function(player)
    joinedLobby[player] = nil
    safe("cleanup",function() clearPlayer(player) end)
end)
task.spawn(function()
    while V.isRunning() do
        local revealing = V.isRoleRevealActive and V.isRoleRevealActive() or false
        -- The first role reveal of a new round admits players that were waiting before it.
        if revealing and not roleRevealActive then table.clear(joinedLobby) end
        roleRevealActive = revealing
        if anyPlayerVisual() or next(entries) then safe("player update",refreshPlayers) end
        if state.object.gun or state.object.knife or next(objectEntries) then safe("object update",refreshObjects) end
        task.wait(.35)
    end
end)

local filters = {{"Everyone","everyone"},{"Murderer Only","murderer"},{"Sheriff Only","sheriff"},{"Hero Only","hero"},{"Dead Only","dead"}}
for _, definition in ipairs({{"CHAM","cham"},{"ESP","esp"},{"OUTLINE","outline"},{"HIGHLIGHT","highlight"},{"TRACER","tracer"},{"ESP BOX","box"},{"ESP AVATAR","avatar"},{"ESP FIRE","fire"}}) do
    local title, kind = definition[1], definition[2]
    local section = V.tab:AddSection("VISUAL \u{2022} "..title,"BY PLAYER")
    for _, f in ipairs(filters) do
        local label, filter = f[1], f[2]
        section:AddToggle(label,function(enabled) safe("toggle",function() setFilter(kind,filter,enabled) end) end)
    end
end
local objects = V.tab:AddSection("VISUAL \u{2022} BY OBJECT","Object ESP")
objects:AddToggle("Dropped Gun",function(enabled) safe("object toggle",function() setObject("gun",enabled) end) end)
objects:AddToggle("Throwing Knives",function(enabled) safe("object toggle",function() setObject("knife",enabled) end) end)

]==]
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



-- Noclip and Fly are compiled in an isolated deferred chunk so they do not exceed the primary mobile Luau local-register budget.
getgenv().__NoirMovementContext = {
    tab = tab, players = Players, uis = UIS, runService = RunService, workspace = Workspace,
    localPlayer = LocalPlayer, persistence = NoirPersistence, guiParent = guiParent, coreGui = CoreGui,
    isPrimaryPress = isPrimaryPress,
}
task.defer(function()
    local __noirMovementSource = [==[
-- Noclip and Fly run in an isolated module to avoid the mobile Luau register limit in the main loader.
local M = getgenv().__NoirMovementContext
if type(M) ~= "table" or not M.tab or not M.persistence then return end

local Players, UIS, RunService, Workspace = M.players, M.uis, M.runService, M.workspace
local LocalPlayer, Persistence = M.localPlayer, M.persistence
local state = {
    noclip = false, noclipOriginals = {},
    fly = false, flyVelocity = nil, flyGyro = nil, flyConnection = nil,
    flyHumanoid = nil, flyAutoRotate = true, flyPlatformStand = false,
    flyStateEnabled = {}, flyAnimate = nil, flyAnimateDisabled = false,
    flySpeed = 48,
}
-- Uses the supplied universal-fly method: PlatformStand plus BodyGyro/BodyVelocity
-- on UpperTorso (R15) or Torso (R6), with Humanoid:TranslateBy movement.
local FLY_STATES = {
    Enum.HumanoidStateType.Climbing, Enum.HumanoidStateType.FallingDown,
    Enum.HumanoidStateType.Flying, Enum.HumanoidStateType.Freefall,
    Enum.HumanoidStateType.GettingUp, Enum.HumanoidStateType.Jumping,
    Enum.HumanoidStateType.Landed, Enum.HumanoidStateType.Physics,
    Enum.HumanoidStateType.PlatformStanding, Enum.HumanoidStateType.Ragdoll,
    Enum.HumanoidStateType.Running, Enum.HumanoidStateType.RunningNoPhysics,
    Enum.HumanoidStateType.Seated, Enum.HumanoidStateType.StrafingNoPhysics,
    Enum.HumanoidStateType.Swimming,
}

local function applyNoclip()
    if not state.noclip then return end
    local character = LocalPlayer.Character
    if not character then return end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            if state.noclipOriginals[part] == nil then state.noclipOriginals[part] = part.CanCollide end
            if part.CanCollide then part.CanCollide = false end
        end
    end
end
local function restoreNoclip()
    for part, original in pairs(state.noclipOriginals) do
        if part and part.Parent then pcall(function() part.CanCollide = original end) end
    end
    table.clear(state.noclipOriginals)
end
local function setNoclip(enabled)
    state.noclip = enabled == true
    if state.noclip then applyNoclip() else restoreNoclip() end
end
RunService.Stepped:Connect(function() if state.noclip then applyNoclip() end end)

local function restoreFlyCharacter()
    local humanoid = state.flyHumanoid
    if humanoid and humanoid.Parent then
        humanoid.AutoRotate = state.flyAutoRotate
        humanoid.PlatformStand = state.flyPlatformStand
        for _, stateType in ipairs(FLY_STATES) do
            local wasEnabled = state.flyStateEnabled[stateType.Name]
            if wasEnabled ~= nil then pcall(function() humanoid:SetStateEnabled(stateType, wasEnabled) end) end
        end
        if not state.flyPlatformStand then
            pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end)
            task.delay(.08, function()
                if humanoid.Parent and not state.fly then pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Running) end) end
            end)
        else
            pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Running) end)
        end
    end
    if state.flyAnimate and state.flyAnimate.Parent then state.flyAnimate.Disabled = state.flyAnimateDisabled end
    state.flyHumanoid, state.flyAnimate = nil, nil
    table.clear(state.flyStateEnabled)
end

local function stopFly()
    if state.flyConnection then state.flyConnection:Disconnect(); state.flyConnection = nil end
    if state.flyVelocity then state.flyVelocity:Destroy(); state.flyVelocity = nil end
    if state.flyGyro then state.flyGyro:Destroy(); state.flyGyro = nil end
    restoreFlyCharacter()
end

local function startFly()
    stopFly()
    if not state.fly then return end
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    -- The linked script handles R15 UpperTorso and R6 Torso.  HumanoidRootPart is used here
    -- for the constraints because it prevents the torso/root physics fight that causes shaking.
    local sourceTorso = character and (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"))
    if not (humanoid and root and (sourceTorso or root)) then return end

    -- Keep the source's BodyVelocity flight core, but leave Roblox's humanoid states and animation system intact.
    -- Disabling them (and forcing a BodyGyro at the camera angle) is what caused the visible body rocking.
    state.flyHumanoid, state.flyAutoRotate, state.flyPlatformStand = humanoid, humanoid.AutoRotate, humanoid.PlatformStand
    humanoid.AutoRotate = false
    -- PlatformStand is needed for a Humanoid avatar to physically pitch with the camera.
    humanoid.PlatformStand = true
    pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Physics) end)

    -- Full 3D camera orientation: use the linked Fly's high-response gyro settings for quick camera following.
    local gyro = Instance.new("BodyGyro")
    gyro.Name, gyro.P, gyro.D, gyro.MaxTorque, gyro.CFrame = "NoirFlyGyro", 9e4, 800, Vector3.new(9e9,9e9,9e9), root.CFrame
    gyro.Parent = root
    local velocity = Instance.new("BodyVelocity")
    velocity.Name, velocity.P, velocity.Velocity, velocity.MaxForce = "NoirFlyVelocity", 12000, Vector3.zero, Vector3.new(9e9,9e9,9e9)
    velocity.Parent = root
    state.flyVelocity, state.flyGyro = velocity, gyro

    state.flyConnection = RunService.Heartbeat:Connect(function()
        if not state.fly or not (character.Parent and humanoid.Parent and root.Parent and velocity.Parent and gyro.Parent) then return end
        local camera = Workspace.CurrentCamera
        if not camera then return end
        -- Mobile joystick flight: push forward/back while aiming the camera up or down to rise/descend.
        -- MoveDirection supplies the joystick vector; projecting it on the camera's flat axes preserves its intent.
        local look = camera.CFrame.LookVector
        local right = camera.CFrame.RightVector
        local flatLook = Vector3.new(look.X, 0, look.Z)
        local flatRight = Vector3.new(right.X, 0, right.Z)
        gyro.CFrame = CFrame.new(root.Position, root.Position + look)
        local input = humanoid.MoveDirection
        local desiredVelocity = Vector3.zero
        if input.Magnitude > .001 then
            local forwardInput = flatLook.Magnitude > .001 and input:Dot(flatLook.Unit) or 0
            local sideInput = flatRight.Magnitude > .001 and input:Dot(flatRight.Unit) or 0
            local flightDirection = look * forwardInput + right * sideInput
            if flightDirection.Magnitude > .001 then desiredVelocity = flightDirection.Unit * state.flySpeed end
        end
        velocity.Velocity = desiredVelocity
    end)
end

local function setFly(enabled)
    state.fly = enabled == true
    if state.fly then startFly() else stopFly() end
end

local binds = {
    noclip = { text="Noclip", key="noclip_bind_v1", default=UDim2.new(.38,0,.88,0), size=.105, enabled=false, gui=nil, button=nil, connections={} },
    fly = { text="Fly", key="fly_bind_v1", default=UDim2.new(.52,0,.88,0), size=.105, enabled=false, gui=nil, button=nil, connections={} },
}
local function disconnect(bind)
    for _, connection in ipairs(bind.connections) do pcall(function() connection:Disconnect() end) end
    table.clear(bind.connections)
end
local function updateSize(bind)
    local camera = Workspace.CurrentCamera
    if not (bind.button and camera) then return end
    local screen = camera.ViewportSize
    bind.button.Size = UDim2.new(bind.size * (screen.Y / math.max(screen.X,1)),0,bind.size,0)
end
local function updateText(bind, active)
    local label = bind.button and bind.button:FindFirstChild("Text")
    if label then label.Text = bind.text .. "\n" .. (active and "ON" or "OFF") end
end
local function removeBind(bind)
    disconnect(bind)
    if bind.gui then bind.gui:Destroy() end
    bind.gui, bind.button = nil, nil
    for _, parent in ipairs({M.guiParent, M.coreGui, LocalPlayer:FindFirstChildOfClass("PlayerGui")}) do
        if typeof(parent) == "Instance" then
            local old = parent:FindFirstChild("Noir" .. bind.text .. "BindButton")
            if old then old:Destroy() end
        end
    end
end
local function createBind(bind, isActive, setActive)
    if bind.button then return end
    removeBind(bind)
    local parent = M.guiParent
    if typeof(parent) ~= "Instance" then parent = LocalPlayer:WaitForChild("PlayerGui") end
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name, screenGui.ResetOnSpawn, screenGui.IgnoreGuiInset, screenGui.DisplayOrder = "Noir" .. bind.text .. "BindButton", false, true, 82
    screenGui.Parent = parent
    local button = Instance.new("ImageButton")
    button.Name, button.AnchorPoint = bind.text, Vector2.new(.5,.5)
    button.Position = Persistence.GetPosition(bind.key,bind.default)
    button.BackgroundColor3, button.BackgroundTransparency, button.BorderSizePixel, button.Image, button.AutoButtonColor, button.ZIndex = Color3.fromRGB(8,8,10),.28,0,"",false,5
    button.Parent = screenGui
    local circle = Instance.new("UICorner"); circle.CornerRadius = UDim.new(1,0); circle.Parent = button
    local aspect = Instance.new("UIAspectRatioConstraint"); aspect.AspectRatio = 1; aspect.Parent = button
    local outer = Instance.new("UIStroke"); outer.Color,outer.Thickness,outer.ApplyStrokeMode,outer.Parent=Color3.fromRGB(255,255,255),2,Enum.ApplyStrokeMode.Border,button
    local gradient = Instance.new("UIGradient")
    gradient.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(35,35,40)),ColorSequenceKeypoint.new(.22,Color3.fromRGB(250,250,252)),ColorSequenceKeypoint.new(.48,Color3.fromRGB(70,70,78)),ColorSequenceKeypoint.new(.72,Color3.fromRGB(255,255,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(45,45,52))})
    gradient.Parent=outer
    local inner=Instance.new("UIStroke");inner.Color,inner.Transparency,inner.Thickness,inner.Parent=Color3.fromRGB(105,105,112),.5,1,button
    local innerGradient=gradient:Clone();innerGradient.Rotation=180;innerGradient.Parent=inner
    local label=Instance.new("TextLabel")
    label.Name,label.AnchorPoint,label.Position,label.Size="Text",Vector2.new(.5,.5),UDim2.fromScale(.5,.5),UDim2.fromScale(.76,.76)
    label.BackgroundTransparency,label.TextColor3,label.TextSize,label.TextWrapped,label.Font,label.ZIndex=1,Color3.fromRGB(245,245,248),14,true,Enum.Font.Gotham,6
    label.Parent=button
    local dragging,moved,dragStart,startPosition,dragInput=false,false,nil,nil,nil
    bind.connections[#bind.connections+1]=button.InputBegan:Connect(function(input)
        if not M.isPrimaryPress(input) then return end
        dragging,moved,dragStart,startPosition=true,false,input.Position,button.Position
    end)
    bind.connections[#bind.connections+1]=button.InputChanged:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then dragInput=input end
    end)
    bind.connections[#bind.connections+1]=UIS.InputChanged:Connect(function(input)
        if not dragging or input~=dragInput then return end
        local delta=input.Position-dragStart
        if delta.Magnitude>7 then moved=true end
        button.Position=UDim2.new(startPosition.X.Scale,startPosition.X.Offset+delta.X,startPosition.Y.Scale,startPosition.Y.Offset+delta.Y)
    end)
    bind.connections[#bind.connections+1]=UIS.InputEnded:Connect(function(input)
        if not dragging or not M.isPrimaryPress(input) then return end
        dragging=false
        Persistence.SetPosition(bind.key,button.Position)
    end)
    bind.connections[#bind.connections+1]=button.Activated:Connect(function() if not moved then setActive(not isActive()) end end)
    bind.connections[#bind.connections+1]=RunService.RenderStepped:Connect(function() if gradient.Parent then gradient.Rotation=(gradient.Rotation+1)%360 end end)
    bind.gui,bind.button=screenGui,button
    updateSize(bind);updateText(bind,isActive())
end
local function setBind(bind, enabled, isActive, setActive)
    bind.enabled=enabled==true
    if bind.enabled then createBind(bind,isActive,setActive) else removeBind(bind) end
end
local function syncNoclipText() updateText(binds.noclip,state.noclip) end
local function syncFlyText() updateText(binds.fly,state.fly) end

local noclipSection=M.tab:AddSection("MAIN \u{2022} NOCLIP","Walk through local collision")
noclipSection:AddToggle("Noclip",function(enabled) setNoclip(enabled);syncNoclipText() end)
noclipSection:AddToggle("Enable Noclip Bind Button",function(enabled)
    setBind(binds.noclip,enabled,function() return state.noclip end,function(active) setNoclip(active);syncNoclipText() end)
end)
noclipSection:AddSlider("Noclip Bind Button Size",5,25,binds.noclip.size*100,function(value) binds.noclip.size=(tonumber(value) or 10.5)/100;updateSize(binds.noclip) end)

local flySection=M.tab:AddSection("MAIN \u{2022} FLY","Camera-guided movement")
flySection:AddToggle("Fly",function(enabled) setFly(enabled);syncFlyText() end)
flySection:AddToggle("Enable Fly Bind Button",function(enabled)
    setBind(binds.fly,enabled,function() return state.fly end,function(active) setFly(active);syncFlyText() end)
end)
flySection:AddSlider("Fly Bind Button Size",5,25,binds.fly.size*100,function(value) binds.fly.size=(tonumber(value) or 10.5)/100;updateSize(binds.fly) end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if state.noclip then table.clear(state.noclipOriginals);applyNoclip() end
    if state.fly then startFly() end
end)

]==]
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




-- Fun-client cosmetics run separately so the primary mobile-safe loader stays within Luau's register budget.
getgenv().__NoirAvatarCosmeticsContext = { tab = tab, localPlayer = LocalPlayer, runService = RunService }
task.defer(function()
    local __noirAvatarCosmeticsSource = [==[
-- Persistent client-side avatar cosmetics for Noir's Main tab.
local A = getgenv().__NoirAvatarCosmeticsContext
if type(A) ~= "table" or not A.tab or not A.localPlayer then return end

local LocalPlayer = A.localPlayer
local RunService = A.runService
local KORBLOX_RIGHT_LEG = 139607718
local KORBLOX_PARTS = {
    RightFoot = { mesh = "rbxassetid://902942089", transparency = 1 },
    RightLowerLeg = { mesh = "rbxassetid://902942093", transparency = 1 },
    RightUpperLeg = { mesh = "rbxassetid://902942096", texture = "rbxassetid://902843398", transparency = 0 },
}
local state = {
    korblox = false,
    headless = false,
    korbloxOriginals = setmetatable({}, {__mode = "k"}),
    korbloxPartOriginals = setmetatable({}, {__mode = "k"}),
    headOriginals = setmetatable({}, {__mode = "k"}),
    applyingKorblox = setmetatable({}, {__mode = "k"}),
}

local function getHumanoid(character)
    return character and character:FindFirstChildWhichIsA("Humanoid")
end

local function applyHeadless(character)
    if not state.headless then return end
    local head = character and character:FindFirstChild("Head")
    if not (head and head:IsA("BasePart")) then return end
    local original = state.headOriginals[head]
    if not original then
        original = { transparency = head.LocalTransparencyModifier, decals = {} }
        state.headOriginals[head] = original
        for _, descendant in ipairs(head:GetDescendants()) do
            if descendant:IsA("Decal") or descendant:IsA("Texture") then original.decals[descendant] = descendant.Transparency end
        end
    end
    head.LocalTransparencyModifier = 1
    for decal in pairs(original.decals) do
        if decal and decal.Parent then decal.Transparency = 1 end
    end
    local face = head:FindFirstChildWhichIsA("Decal")
    if face and original.decals[face] == nil then
        original.decals[face] = face.Transparency
        face.Transparency = 1
    end
end

local function restoreHeadless(character)
    local head = character and character:FindFirstChild("Head")
    local original = head and state.headOriginals[head]
    if not original then return end
    if head.Parent then head.LocalTransparencyModifier = original.transparency end
    for decal, transparency in pairs(original.decals) do
        if decal and decal.Parent then decal.Transparency = transparency end
    end
    state.headOriginals[head] = nil
end

local function applyKorbloxMesh(character)
    if not state.korblox or not character then return end
    for partName, appearance in pairs(KORBLOX_PARTS) do
        local part = character:FindFirstChild(partName)
        if part and part:IsA("MeshPart") then
            local original = state.korbloxPartOriginals[part]
            if not original then
                original = { mesh = part.MeshId, texture = part.TextureID, transparency = part.Transparency }
                state.korbloxPartOriginals[part] = original
            end
            pcall(function() part.MeshId = appearance.mesh end)
            if appearance.texture then pcall(function() part.TextureID = appearance.texture end) end
            pcall(function() part.Transparency = appearance.transparency end)
        end
    end
end

local function restoreKorbloxMesh(character)
    if not character then return end
    for _, part in ipairs(character:GetDescendants()) do
        local original = state.korbloxPartOriginals[part]
        if original and part:IsA("MeshPart") then
            pcall(function()
                part.MeshId, part.TextureID, part.Transparency = original.mesh, original.texture, original.transparency
            end)
            state.korbloxPartOriginals[part] = nil
        end
    end
end

local function applyKorblox(character)
    if not state.korblox then return end
    local humanoid = getHumanoid(character)
    if not (humanoid and humanoid.RigType == Enum.HumanoidRigType.R15) or state.applyingKorblox[character] then return end
    local ok, description = pcall(function() return humanoid:GetAppliedDescription() end)
    if not ok or not description then return end
    if state.korbloxOriginals[character] == nil then state.korbloxOriginals[character] = description.RightLeg end
    if description.RightLeg ~= KORBLOX_RIGHT_LEG then
        state.applyingKorblox[character] = true
        description.RightLeg = KORBLOX_RIGHT_LEG
        pcall(function() humanoid:ApplyDescription(description) end)
        task.delay(.4, function()
            state.applyingKorblox[character] = nil
            if character.Parent then applyKorbloxMesh(character) end
            if state.headless and character.Parent then applyHeadless(character) end
        end)
    end
    -- HumanoidDescription can be rejected or overwritten in live games; direct R15 mesh fallback keeps the cosmetic visible.
    applyKorbloxMesh(character)
    applyHeadless(character)
end

local function restoreKorblox(character)
    local originalRightLeg = character and state.korbloxOriginals[character]
    local humanoid = getHumanoid(character)
    if not (humanoid and originalRightLeg ~= nil) then return end
    local ok, description = pcall(function() return humanoid:GetAppliedDescription() end)
    if ok and description then
        description.RightLeg = originalRightLeg
        pcall(function() humanoid:ApplyDescription(description) end)
    end
    restoreKorbloxMesh(character)
    state.korbloxOriginals[character] = nil
end

local function applyCurrentCharacter()
    local character = LocalPlayer.Character
    if state.korblox then applyKorblox(character) end
    if state.headless then applyHeadless(character) end
end

local section = A.tab:AddSection("MAIN \u{2022} FUN CLIENT", "Respawn-persistent local avatar cosmetics")
section:AddToggle("Permanent Korblox (R15)", function(enabled)
    state.korblox = enabled == true
    local character = LocalPlayer.Character
    if state.korblox then applyKorblox(character) else restoreKorblox(character) end
end)
section:AddToggle("Permanent Headless", function(enabled)
    state.headless = enabled == true
    local character = LocalPlayer.Character
    if state.headless then applyHeadless(character) else restoreHeadless(character) end
end)
section:AddLabel("Both looks are reapplied after each respawn. Korblox requires an R15 character.")

LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(.75)
    applyKorblox(character)
    applyHeadless(character)
end)
LocalPlayer.CharacterAppearanceLoaded:Connect(function(character)
    task.wait(.2)
    if state.korblox then applyKorblox(character) end
    if state.headless then applyHeadless(character) end
end)
-- Games may refresh an avatar after it has spawned. Keep the two requested client cosmetics applied while enabled.
if RunService then
    -- Avatar refreshes only need to counter occasional game appearance writes; avoid doing mesh/head work every render frame.
    local nextRefresh = 0
    RunService.Heartbeat:Connect(function()
        local now = os.clock()
        if now < nextRefresh then return end
        nextRefresh = now + .12
        local character = LocalPlayer.Character
        if state.korblox then applyKorbloxMesh(character) end
        if state.headless then applyHeadless(character) end
    end)
end
task.defer(applyCurrentCharacter)

]==]
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




-- Full 7yd7 Emotes port, hosted in Noir's native Emotes page instead of as an external ODH plugin.
getgenv().__NoirEmotesContext = {
    container = emotesContent,
    theme = { base = C.base, panel = C.panel, surface = C.surface, card = C.card, button = C.btn, accent = C.accent, text = C.text, dim = C.dim, border = C.border },
    SetCanvasHeight = function(height)
        emotesContent.CanvasSize = UDim2.fromOffset(0, math.max(200, tonumber(height) or 664))
    end,
    Notify = function(textValue, duration) notify("Emotes: " .. tostring(textValue), duration or 3) end,
}
task.defer(function()
    local __noirEmotesSource = [==[
-- 7yd7 Emotes — Overdrive H plugin + responsive thumbnail card browser.
-- Original: https://github.com/7yd7/Hub/blob/Branch/GUIS/Emotes.lua
-- Catalog: 7yd7/sniper-Emote, EmoteSniper.json. No remote Lua execution.
-- Separate card GUI; original animation bundles/themes/HUD editor are not included.
-- R15 only. Asset permissions and replication remain controlled by Roblox/the game.
-- Integrated into Noir's native Emotes tab. The catalog source stays data-only; no remote Lua is executed.
local shared=getgenv().__NoirEmotesContext
local container=shared and shared.container
if not shared or not (container and typeof(container)=="Instance") then
    warn("[Noir Emotes] native Emotes tab container unavailable.")
    return
end
local KEY="Noir_7yd7_EmotesRuntime_v1"
local previous=_G[KEY]
if type(previous)=="table" and previous.alive and type(previous.Cleanup)=="function" then
    pcall(previous.Cleanup)
end
local Players=game:GetService("Players")
local Player=Players.LocalPlayer
if not Player then warn("[ODH Emotes] LocalPlayer unavailable.");return end
local HttpService=game:GetService("HttpService")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local runtime={version=7,alive=true,initializing=true,generation=0,filterGeneration=0,page=1,catalog={},filtered={},resolutions={},connections={}}
local prefs={windowTransparency=22,thumbnailSize=68,thumbnailPresetVersion=2,playbackModeVersion=2,shortcuts={},browserOnLoad=false,loop=false,walk=false,speed=1,favoritesOnly=false,query="",customId="",customKind="Catalog emote ID",favorites={}}
local FILE="ODH_Emotes_settings.json"
local CACHE="ODH_Emotes_catalog.json"
local URL="https://raw.githubusercontent.com/7yd7/sniper-Emote/refs/heads/test/EmoteSniper.json"
local PAGE_SIZE=12
local MAX_SHORTCUTS=12
local warnings={}
local function Notify(text)
    if type(shared.Notify)=="function" then pcall(shared.Notify,"Emotes: "..text,5) end
end
local function WarnOnce(key,text)
    if warnings[key] then return end
    warnings[key]=true;warn("[ODH Emotes] "..text);Notify(text)
end
local env={}
if type(getgenv)=="function" then
    local ok,value=pcall(getgenv)
    if ok and type(value)=="table" then env=value end
end
local read=type(readfile)=="function" and readfile or env.readfile
local write=type(writefile)=="function" and writefile or env.writefile
local exists=type(isfile)=="function" and isfile or env.isfile
local canSave=type(read)=="function" and type(write)=="function"
runtime.settingsFile=FILE
runtime.saveStatus=canSave and "Not saved" or "Session only"
runtime.preferences=prefs
local function AssetId(value)
    if type(value)~="number" and type(value)~="string" then return nil end
    local id=tonumber(value)
    if id and id==id and id>0 and id<9007199254740992 and id==math.floor(id) then return id end
end
local function IdText(id) return string.format("%.0f",id) end
local function ParseId(text)
    if type(text)~="string" then return nil end
    local digits=text:match("^%s*(%d+)%s*$") or text:match("^rbxassetid://(%d+)$")
        or text:match("[?&]id=(%d+)") or text:match("roblox%.com/catalog/(%d+)")
    return digits and AssetId(digits)
end
local function Item(value)
    if type(value)~="table" then return nil end
    local id=AssetId(value.id)
    if not id then return nil end
    local name=type(value.name)=="string" and value.name:gsub("[%c]"," ") or ("Emote "..IdText(id))
    if #name==0 or #name>2000 then name="Emote "..IdText(id) end
    return {id=id,name=name}
end
local function ReadJSON(path)
    if type(read)~="function" then return nil,"unavailable" end
    if type(exists)=="function" then
        local ok,found=pcall(exists,path)
        if ok and not found then return nil,"missing" end
    end
    local ok,text=pcall(read,path)
    if not ok then return nil,"read error" end
    local decoded,data=pcall(function() return HttpService:JSONDecode(text) end)
    if not decoded or type(data)~="table" then return nil,"invalid JSON" end
    return data
end
local function LoadSettings()
    if not canSave then WarnOnce("files","readfile/writefile unavailable; settings are session-only.");return end
    local data,err=ReadJSON(FILE)
    if not data then
        if err~="missing" then WarnOnce("read","Settings not loaded ("..tostring(err).."). Existing file is kept until you change a setting.") end
        return
    end
    if data.version~=1 or type(data.values)~="table" then
        WarnOnce("read","Invalid settings; existing file is kept until you change a setting.");return
    end
    local values=data.values
    -- Migrate the old forced/default Loop ON without discarding other settings.
    if values.playbackModeVersion==2 and type(values.loop)=="boolean" then prefs.loop=values.loop end
    if type(values.shortcuts)=="table" then
        local count=0
        for _,value in pairs(values.shortcuts) do
            local item=Item(value)
            if item then
                local function position(number,default)
                    if type(number)=="number" and number==number and number>-math.huge and number<math.huge then
                        return math.clamp(number,0,1)
                    end
                    return default
                end
                item.x=position(value.x,.75);item.y=position(value.y,.45)
                prefs.shortcuts[IdText(item.id)]=item;count=count+1
                if count>=MAX_SHORTCUTS then break end
            end
        end
    end
    for key,limits in pairs({windowTransparency={0,50},thumbnailSize={50,100}}) do
        local value=values[key]
        if type(value)=="number" and value==value and value>-math.huge and value<math.huge then
            prefs[key]=math.clamp(value,limits[1],limits[2])
        end
    end
    if values.thumbnailPresetVersion~=2 and prefs.thumbnailSize==78 then prefs.thumbnailSize=68 end
    for _,key in ipairs({"walk","favoritesOnly","browserOnLoad"}) do
        if type(values[key])=="boolean" then prefs[key]=values[key] end
    end
    if type(values.speed)=="number" and values.speed==values.speed and values.speed>-math.huge and values.speed<math.huge then prefs.speed=math.clamp(values.speed,0,3) end
    if type(values.query)=="string" then prefs.query=values.query:sub(1,200) end
    if type(values.customId)=="string" and #values.customId<=200 then prefs.customId=values.customId end
    if values.customKind=="Animation ID" then prefs.customKind=values.customKind end
    prefs.selected=Item(values.selected)
    if type(values.favorites)=="table" then
        local count=0
        for _,value in pairs(values.favorites) do
            local item=Item(value)
            if item then prefs.favorites[IdText(item.id)]=item;count=count+1 end
            if count>=10000 then break end
        end
    end
    runtime.saveStatus="Loaded"
end
local function SaveSettings()
    if runtime.initializing or not runtime.alive or not canSave then return false end
    local ok,err=pcall(function() write(FILE,HttpService:JSONEncode({version=1,values=prefs})) end)
    if not ok then runtime.saveStatus="Write error";WarnOnce("write","Cannot save settings: "..tostring(err));return false end
    runtime.saveStatus="Saved";warnings.write=nil;return true
end
LoadSettings()

local BUILTIN={
    {id=3360689775,name="Salute"},
    {id=5915779043,name="Applaud"},
    {id=3360692915,name="Tilt"},
    {id=15610015346,name="Yungblud Happier Jump"},
    {id=14353423348,name="Baby Queen - Bouncy Twirl"},
    {id=14353421343,name="Baby Queen - Face Frame"},
    {id=3823158750,name="Godlike"},
    {id=139021427684680,name="KATSEYE - Touch"},
    {id=133596366979822,name="Biblically Accurate Emote"},
    {id=108128682361404,name="Rambunctious"},
    {id=79127989560307,name="Moon Walk"},
    {id=5230661597,name="Bored"},
    {id=14353425085,name="Baby Queen - Strut"},
    {id=15694504637,name="d4vd - Backflip"},
    {id=104142334418357,name="[Original] It's Gangnam Style!"},
    {id=16553249658,name="Mae Stephens - Piano Hands"},
    {id=12507097350,name="Alo Yoga Pose - Lotus Position"},
    {id=15698511500,name="Cuco - Levitate"},
    {id=4689362868,name="Sleep"},
    {id=111426928948833,name="Floating on clouds"},
    {id=130245358716273,name="The Weeknd Starboy Strut"},
    {id=120642514156293,name="Secret Handshake Dance"},
    {id=15506503658,name="Victory Dance"},
    {id=3576717965,name="Shy"},
    {id=73796726960568,name="Nyan Nyan! "},
    {id=78758922757947,name="Kicking Feet Sit"},
    {id=93511411593120,name="/e fly"},
    {id=114899970878842,name="R15 Death (Accurate)"},
    {id=5104377791,name="Hero Landing"},
    {id=5917570207,name="Floss Dance"},
    {id=131763631172236,name="Xaviersobased Emote"},
    {id=132074413582912,name="California Girl Dance"},
    {id=15554010118,name="Olivia Rodrigo Head Bop"},
    {id=112758073578333,name="Bubbly Sit"},
    {id=3716636630,name="Monkey"},
    {id=123015710605336,name="Onion"},
    {id=4646306583,name="Curtsy"},
    {id=85936805522788,name="Caramell"},
    {id=14900153406,name="TWICE Feel Special"},
    {id=102492229412911,name="Deltarune - Tenna Dance"},
    {id=133142324349281,name="Flopping Fish"},
    {id=10214406616,name="Frosty Flair - Tommy Hilfiger"},
    {id=120224229260879,name="Cute crouch "},
    {id=15679955281,name="Festive Dance"},
    {id=4849502101,name="Sad"},
    {id=10214418283,name="V Pose - Tommy Hilfiger"},
    {id=92853367837757,name="Garry's Dance"},
    {id=104485625389237,name="Make You Mine"},
    {id=139830733782518,name="Phut On"},
    {id=132382355371060,name="Tank Transformation"},
    {id=103046131635200,name="Scenario - LOVE SCENARIO"},
    {id=15123050663,name="Bone Chillin' Bop"},
    {id=124305244640379,name="Shattered"},
    {id=134311528115559,name="how did he hit every beat"},
    {id=17748346932,name="Elton John - Heart Shuffle"},
    {id=93105950995997,name="Caramelldansen"},
    {id=7466046574,name="Quiet Waves"},
    {id=96557878503341,name="Caramell Dansen"},
    {id=139859849852362,name="Dead"},
    {id=17360720445,name="HUGO Let's Drive!"},
    {id=103102322875221,name="Skibidi Toilet - Titan Speakerman Laser Spin"},
    {id=3576968026,name="Shrug"},
    {id=130998336536045,name="Gangnam Style"},
    {id=84555218084038,name="Helicopter Spin"},
    {id=71302743123422,name="Popular"},
    {id=133765015173412,name="DearALICE - Ariana"},
    {id=115319301809339,name="2 Phut Hon Dance"},
    {id=70635223083942,name="Be Not Afraid"},
    {id=17746270218,name="Sturdy Dance - Ice Spice"},
    {id=129149402922241,name="griddy"},
    {id=3576686446,name="Hello"},
    {id=113547795536875,name="Gangnam Style"},
    {id=126614732606871,name="Sit"},
    {id=3762654854,name="Greatest"},
    {id=16572756230,name="HIPMOTION - Amaarae"},
    {id=16276506814,name="Sol de Janeiro - Samba"},
    {id=3576823880,name="Point2"},
    {id=78459263478161,name="Family Man Death Pose"},
    {id=14900151704,name="TWICE LIKEY"},
    {id=3360686498,name="Stadium"},
    {id=15571540519,name="Nicki Minaj Starships"},
    {id=4940597758,name="Cower"},
    {id=11394056822,name="Elton John - Elevate"},
    {id=117734400993750,name="Virtual Singer Dance"},
    {id=97263450325496,name="Teto Territory"},
    {id=4102315500,name="Haha"},
    {id=79312439851071,name="Chappell Roan HOT TO GO!"},
    {id=105851216004006,name="Electro Swing"},
    {id=92707348383277,name="Mesmerizer"},
    {id=103139492736941,name="Deltarune - Tenna Swing Dance"},
    {id=15571538346,name="Nicki Minaj Boom Boom Boom"},
    {id=15554016057,name="Olivia Rodrigo Fall Back to Float"},
    {id=70615023659736,name="Floating"},
    {id=136740085081295,name="/e hidden animation"},
    {id=119431985170060,name="Helicopter"},
    {id=87141651594092,name="No-Clip/Speed Glitch"},
    {id=16303091119,name="Beauty Touchdown"},
    {id=3934986896,name="Dizzy"},
    {id=130726889233022,name="rolling crybaby"},
    {id=11309263077,name="Elton John - Heart Skip"},
    {id=84511772437190,name="Emote Loading. Please Wait... | spinning Robloxian"},
    {id=14353417553,name="Baby Queen - Air Guitar & Knee Slide"},
    {id=15392927897,name="Paris Hilton - Sliving For The Groove"},
    {id=94796833553521,name="TWICE Takedown pt 1 from Kpop Demon Hunters"},
    {id=120437019363089,name="peter griffin death pose"},
    {id=15506506103,name="Flex Walk"},
    {id=90608224567833,name="Proud to be Expendable - Pressure"},
    {id=18526338976,name="Team USA Breaking Emote"},
    {id=99818263438846,name="Default Dance"},
    {id=103197720369544,name="Dani's Gangnam Style"},
    {id=75017857395637,name="TV Time Dance"},
    {id=73683655527605,name="Fashion Roadkill"},
    {id=15392932768,name="Paris Hilton - Iconic IT-Grrrl"},
    {id=82217023310738,name="Thanos Happy Jump - Squid Game"},
    {id=102610758906338,name="Possessed"},
    {id=95323795166399,name="Rat Dance"},
    {id=127562607220778,name="Gangnam Style "},
    {id=129132611803602,name="Helicopter"},
    {id=82345302788133,name="Dia Delicia Dance"},
    {id=15392937495,name="Paris Hilton - Checking My Angles"},
    {id=4212496830,name="Zombie"},
    {id=113016438012253,name="⌛ Best Mates EMOTE [LIMITED]"},
    {id=110537281410647,name="[Aura Farm] Wall Lean Idle"},
    {id=92903522317071,name="ILLIT - Magnetic"},
    {id=122899100558551,name="It's TV Time!"},
    {id=75528418031928,name="Rambunctious"},
    {id=103040723950430,name="Gojo Floating"},
    {id=70788193750089,name="Kickn around"},
    {id=5915776835,name="High Wave"},
    {id=84195923658292,name="Jojo"},
    {id=110731335896907,name="[⌛ Limited]  HEADLESS EMOTE "},
    {id=139271706064778,name="Hip Bounce"},
    {id=4849499887,name="Happy"},
    {id=127271798262177,name="M3GAN's Dance"},
    {id=104304182344567,name="ONCE HOP HOP!"},
    {id=85623000473425,name="TWICE Takedown pt 2 from KPop Demon Hunters"},
    {id=84067050907557,name="Pickle Rick Dance"},
    {id=86982022610765,name="Caramelldansen"},
    {id=117301403779781,name="Im Talm Bout Innit"},
    {id=84822284410814,name="Maraschino Step"},
    {id=97847706148165,name="[NEW !] Caramelldansen Kawaii Dance"},
    {id=89174456614428,name="Laying Down - Daydreaming"},
    {id=91023138078288,name="OH WHO IS YOU"},
    {id=107978036345855,name="Prince Of Egypt Dance / What You Want"},
    {id=71363859760586,name="Golden Freddy Pose"},
    {id=80877772569772,name="Default Dance | OG"},
    {id=80436375269036,name="HEADLESS HOOPER"},
    {id=93262662842394,name="Sit"},
    {id=75703899901487,name="6 7 Transformation"},
    {id=100773414188482,name="Stray Kids Walkin On Water"},
    {id=131544122623505,name="Become A Car!"},
    {id=99005087791705,name="Death Pose"},
    {id=132384701706046,name="💀MM2 Fake Dead"},
    {id=129916107176034,name="Discombobulated"},
    {id=88598010609888,name="Angry Stomp "},
    {id=132508867759412,name="xavier so based emote"},
    {id=121167704249654,name="Hide"},
    {id=137873580964093,name="Floating Human Spinner (LIMITED) "},
    {id=76700167742736,name="Belly Dance"},
    {id=87826892596287,name="levitate"},
    {id=70972410468289,name="Fake Dead (Troll Emote)"},
    {id=134615135651900,name="Young-hee Head Spin - Squid Game"},
    {id=13823339506,name="Tommy - Archer"},
    {id=109755476052324,name="IShowSpeed Dance"},
    {id=124828909173982,name="Skibidi"},
    {id=4272351660,name="Fast Hands"},
    {id=137006085779408,name="Speed Glitch+"},
    {id=89633087256727,name="Weird Spin"},
    {id=125032357496729,name="Fake Death (BEST)"},
    {id=81177294287826,name="Hug"},
    {id=88721672617892,name="P.B.J.T."},
    {id=121259524934987,name="Xaviersobased Jig"},
    {id=121067808279598,name="PARROT PARTY DANCE"},
    {id=7202898984,name="Show Dem Wrists - KSI"},
    {id=120377619472998,name="Macarena"},
    {id=4940602656,name="Jumping Wave"},
    {id=94663026124741,name="Torture Dance"},
    {id=120896030393583,name="Get Sturdy"},
    {id=137261874619072,name="Sponge Dance"},
    {id=119746055344304,name="Plane"},
    {id=78620443286892,name="Cute Laying Down"},
    {id=108922782921118,name="📸 Pose for the Pic "},
    {id=131221550165951,name="Heart Hands Pose 3.0"},
    {id=119454955259757,name="Caramel Hip Sway"},
    {id=7202900159,name="Wake Up Call - KSI"},
    {id=79752538807060,name="Griddy"},
    {id=140466682449054,name="head spin"},
    {id=107899954696611,name="Spongebob Shuffle Dance 🧽"},
    {id=96405718067779,name="Cute Sit"},
    {id=4849497510,name="Power Blast"},
    {id=89413575288931,name="Blue Shirt Guy Dancing"},
    {id=112924687333965,name="Aura Farm"},
    {id=100782362883099,name="Car Transformation"},
    {id=102323907950469,name="Space Dance"},
    {id=110521067391235,name="The Old Jitterbug"},
    {id=111304332281521,name="Druski Shuffle"},
    {id=133600250245899,name="🥤 Soda Pop - Saja Boys"},
    {id=133477296392756,name="Rasputin – Boney M."},
    {id=122949892043249,name="[Aura Farm] Sit Idle"},
    {id=82739386299071,name="Jackpot Groove"},
    {id=80422524668416,name="Dreamer"},
    {id=97968838104258,name="Subject Three / AI Cat Chinese Dance"},
    {id=91274761264433,name="Macarena"},
    {id=3994130516,name="Bodybuilder"},
    {id=5938365243,name="Dolphin Dance"},
    {id=99563839802389,name="Jumpstyle"},
    {id=85361710130557,name="Caramelldansen"},
    {id=74646784680842,name="Ishowspeed shake "},
    {id=5230615437,name="Beckon"},
    {id=135489824748823,name="Magical Pose"},
    {id=98603994713783,name="Rat Dance"},
    {id=14353419229,name="Baby Queen - Dramatic Bow"},
    {id=84052327668385,name="Floating"},
    {id=97999370392804,name="Spin my Head"},
    {id=94319114655768,name="Rat Dance"},
    {id=86849720336961,name="Mr. Ant Tennas Dance - DELTARUNE"},
    {id=124754178569693,name="Die Lit!"},
    {id=80544397800234,name="Helicopter"},
    {id=100532972764499,name="MONSTER MASH"},
    {id=88922397617835,name="What You Want"},
    {id=115810068374896,name="Garry's Dance"},
    {id=75842745124834,name="Human Snake"},
    {id=94451497143711,name="Hakari Dance"},
    {id=128972617664804,name="Fortnite Default Dance"},
    {id=73556976257737,name="Saja Boy Pose - Jinu"},
    {id=81390693780805,name="PROXIMA"},
    {id=17000058939,name="Mini Kong"},
    {id=97629500912487,name="BlockyKick Dance"},
    {id=112949099442762,name="Griddy"},
    {id=130641944883645,name=" Jinu Pose - Saja Boys"},
    {id=108474079699304,name="Dep"},
    {id=4049646104,name="Line Dance"},
    {id=91423783304464,name="criss cross sit"},
    {id=90524692306889,name="[⏳] Chill Sit"},
    {id=15506496093,name="Rock n Roll"},
    {id=134737246939931,name="GAG IT DEATH DROP"},
    {id=71787387963141,name="Worm Dance"},
    {id=128658037413893,name="I'm Going To Die Here - Pressure"},
    {id=99568437064777,name="Relaxed Sit"},
    {id=83018514370428,name="Stargazing"},
    {id=92859581691366,name="ALTÉGO - Couldn’t Care Less"},
    {id=94534169345613,name="Casual Sit"},
    {id=16126526506,name="Paris Hilton Sanasa"},
    {id=140037329261678,name="Caramel dance"},
    {id=94118707925458,name="Go Mufasa"},
    {id=105730788757021,name="Dani's BIRDBRAIN"},
    {id=91927498467600,name="Koto Nai Meme Dance"},
    {id=117450501566142,name="Hide Hidden Box Invisible Camo Emote Small tiny"},
    {id=4272484885,name="Baby Dance"},
    {id=88024974500195,name="Oppa Gangnam Style"},
    {id=7202896732,name="Boxing Punch - KSI"},
    {id=128792127841374,name="Watching silly videos (Or texting)"},
    {id=87756443172440,name="xavier so based dance"},
    {id=116770268279002,name="BirdBrain Teto"},
    {id=124935873390035,name="Hiding Human Box"},
    {id=94121796810251,name="Kicking Feet And Blushing"},
}

local statusLabel,catalogLabel,selectedLabel,searchLabel,customLabel
local function Label(control,text)
    if control then pcall(function() control:SetValue(text) end) end
end
local function Status(text)
    runtime.status=text;Label(statusLabel,text)
    if runtime.UpdateCardStatus then runtime.UpdateCardStatus() end
end
local function Dispose(track,animation)
    if track then
        pcall(function() track:Stop(0) end)
        pcall(function() track:Destroy() end)
    end
    if animation then pcall(function() animation:Destroy() end) end
end
local function StopCurrent(message)
    runtime.generation=runtime.generation+1
    if runtime.endedConnection then runtime.endedConnection:Disconnect();runtime.endedConnection=nil end
    local track,animation=runtime.track,runtime.animation
    runtime.track=nil;runtime.animation=nil;runtime.character=nil;runtime.playing=nil
    Dispose(track,animation)
    if message then Status(message) end
end
runtime.Stop=function() StopCurrent("Stopped") end
local function Current(ticket,character)
    return runtime.alive and runtime.generation==ticket and Player.Character==character
end
local function ResolveCatalog(id)
    if runtime.resolutions[id] then return runtime.resolutions[id] end
    local ok,objects=pcall(function() return game:GetObjects("rbxassetid://"..IdText(id)) end)
    if not ok or type(objects)~="table" then return nil end
    local resolved
    -- Loaded objects stay unparented. Scripts in an asset are never executed.
    pcall(function()
        for _,root in ipairs(objects) do
            if root:IsA("Animation") then resolved=ParseId(root.AnimationId) end
            if not resolved then
                local descendants=root:GetDescendants()
                for i,obj in ipairs(descendants) do
                    if i>4000 then break end
                    if obj:IsA("Animation") then resolved=ParseId(obj.AnimationId);if resolved then break end end
                end
            end
            if resolved then break end
        end
    end)
    for _,root in ipairs(objects) do pcall(function() root:Destroy() end) end
    if resolved then runtime.resolutions[id]=resolved end
    return resolved
end
local function Play(item,direct)
    if not runtime.alive then return end
    if not item or not AssetId(item.id) then Notify("Select an emote or enter a valid ID first.");return end
    StopCurrent()
    local ticket=runtime.generation
    local character=Player.Character
    if not character then Status("Waiting for character — press Play after spawning");return end
    Status("Loading: "..item.name)
    task.spawn(function()
        local track,animation
        local ok,err=pcall(function()
            if not Current(ticket,character) then return end
            local humanoid=character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid",8)
            if not Current(ticket,character) then return end
            if not humanoid or humanoid.Health<=0 then error("Character is not ready") end
            if humanoid.RigType~=Enum.HumanoidRigType.R15 then error("R15 character required") end
            local animator=humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator",8)
            if not Current(ticket,character) then return end
            if not animator then error("Animator is not ready") end
            local animationId=direct and item.id or ResolveCatalog(item.id)
            if not Current(ticket,character) then return end
            if not animationId and not direct then
                -- Roblox's native emote API is a fallback when GetObjects is unavailable.
                local nativeOK,nativeTrack=pcall(function() return humanoid:PlayEmoteAndGetAnimTrackById(item.id) end)
                if nativeOK and nativeTrack and typeof(nativeTrack)=="Instance" and nativeTrack:IsA("AnimationTrack") then track=nativeTrack end
                if not Current(ticket,character) then return end
            end
            if not track then
                animation=Instance.new("Animation")
                animation.AnimationId="rbxassetid://"..IdText(animationId or item.id)
                track=animator:LoadAnimation(animation)
            end
            if not Current(ticket,character) then return end
            if not track then error("Roblox did not return an animation track") end
            track.Priority=Enum.AnimationPriority.Action
            track.Looped=prefs.loop
            if not track.IsPlaying then track:Play(0.05,1,prefs.speed) else track:AdjustSpeed(prefs.speed) end
            runtime.track=track;runtime.animation=animation;runtime.character=character
            runtime.playing=item
            runtime.endedConnection=track.Ended:Connect(function()
                if runtime.track==track and Current(ticket,character) then StopCurrent("Finished: "..item.name) end
            end)
            -- LoadAnimation may return a track even for an inaccessible/deleted asset.
            local deadline=os.clock()+8
            while Current(ticket,character) and runtime.track==track and track.Length<=0 and os.clock()<deadline do task.wait(0.1) end
            if not Current(ticket,character) or runtime.track~=track then return end
            if track.Length<=0 then error("Animation did not load. It may be restricted, deleted, or incompatible.") end
            Status("Playing: "..item.name)
        end)
        if not Current(ticket,character) then
            -- A newer click/Stop/respawn wins even if GetObjects/LoadAnimation yielded.
            if runtime.track~=track then Dispose(track,animation) end
            return
        end
        if not ok then
            if runtime.track==track then StopCurrent() else Dispose(track,animation) end
            Status("Cannot play this emote")
            Notify(tostring(err))
        end
    end)
end
runtime.Play=function(id,name,direct) Play({id=id,name=name or IdText(id)},direct==true) end
runtime.SaveSettings=SaveSettings
runtime.connections[#runtime.connections+1]=Player.CharacterAdded:Connect(function()
    StopCurrent("Respawned — select an emote and press Play")
end)
runtime.connections[#runtime.connections+1]=RunService.Heartbeat:Connect(function()
    if not runtime.alive or not runtime.track then return end
    local character=runtime.character
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    if Player.Character~=character or not humanoid or humanoid.Health<=0 then StopCurrent("Stopped");return end
    if not prefs.walk and humanoid.MoveDirection.Magnitude>0.05 then StopCurrent("Stopped on movement") end
end)
function runtime.Cleanup()
    runtime.alive=false;runtime.filterGeneration=runtime.filterGeneration+1
    StopCurrent()
    for _,connection in ipairs(runtime.connections) do connection:Disconnect() end
    if runtime.DestroyBrowser then runtime.DestroyBrowser() end
end

local dropdown,pageLabel
local displayed={}
local syncing=false
local SENTINEL="— Select an emote —"
local function NormalizeCatalog(data)
    if type(data)~="table" then return nil end
    local source=type(data.data)=="table" and data.data or data
    local items,seen={},{}
    for i,value in ipairs(source) do
        if i>100000 then break end
        local item=Item(value)
        if item and not seen[item.id] then
            seen[item.id]=true;items[#items+1]=item
        end
    end
    return #items>0 and items or nil
end
local function SelectionLabel()
    local item=prefs.selected
    Label(selectedLabel,item and ("Selected: "..item.name.." ["..IdText(item.id).."]") or "Selected: none")
    if runtime.UpdateCardStatus then runtime.UpdateCardStatus() end
end
local function RenderPage()
    if not runtime.alive then return end
    local pages=math.max(1,math.ceil(#runtime.filtered/PAGE_SIZE))
    runtime.page=math.clamp(runtime.page,1,pages)
    local names={SENTINEL}
    displayed={}
    local selectedText=SENTINEL
    for i=(runtime.page-1)*PAGE_SIZE+1,math.min(runtime.page*PAGE_SIZE,#runtime.filtered) do
        local item=runtime.filtered[i]
        local text=item.name.." ["..IdText(item.id).."]"
        names[#names+1]=text;displayed[text]=item
        if prefs.selected and prefs.selected.id==item.id then selectedText=text end
    end
    if dropdown then
        syncing=true
        local ok,err=pcall(function() dropdown:ChangeItems(names);dropdown:Select(selectedText) end)
        syncing=false
        if not ok then WarnOnce("dropdown","Could not update the emote list: "..tostring(err)) end
    end
    Label(pageLabel,"Page "..runtime.page.." / "..pages.." • matches: "..#runtime.filtered.." • catalog: "..#runtime.catalog)
    SelectionLabel()
    if runtime.RenderCards then runtime.RenderCards() end
end
local function Filter(resetPage)
    runtime.filterGeneration=runtime.filterGeneration+1
    local ticket=runtime.filterGeneration
    local query=prefs.query:lower()
    local favoritesOnly=prefs.favoritesOnly
    local source=runtime.catalog
    if favoritesOnly then
        source={}
        for _,item in pairs(prefs.favorites) do source[#source+1]=item end
        table.sort(source,function(a,b) return a.name:lower()<b.name:lower() end)
    end
    local words={}
    for word in query:gmatch("%S+") do words[#words+1]=word end
    runtime.filtering=true
    if runtime.UpdateCardStatus then runtime.UpdateCardStatus() end
    Label(searchLabel,"Search: "..(prefs.query=="" and "(all)" or prefs.query))
    task.spawn(function()
        local filtered={}
        for i,item in ipairs(source) do
            if not runtime.alive or runtime.filterGeneration~=ticket then return end
            local haystack=item.name:lower().." "..IdText(item.id)
            local matches=true
            for _,word in ipairs(words) do
                if not haystack:find(word,1,true) then matches=false;break end
            end
            if matches then filtered[#filtered+1]=item end
            if i%500==0 then task.wait() end
        end
        if not runtime.alive or runtime.filterGeneration~=ticket then return end
        runtime.filtered=filtered;runtime.filtering=false
        if resetPage then runtime.page=1 end
        RenderPage()
    end)
end
local function AdoptCatalog(items,source)
    runtime.catalog=items
    runtime.catalogSource=source
    Label(catalogLabel,"Catalog: "..#items.." emotes • "..source)
    -- A selected item need not be on the visible page or present in a newer catalog.
    if not prefs.selected then prefs.selected=items[1] end
    SelectionLabel()
    Filter(true)
end
local function RefreshCatalog()
    if not runtime.alive or runtime.catalogBusy then return end
    runtime.catalogBusy=true
    Label(catalogLabel,"Updating catalog... current list remains available")
    task.spawn(function()
        local ok,data=pcall(function() return HttpService:JSONDecode(game:HttpGet(URL)) end)
        if not runtime.alive then return end
        local items=ok and NormalizeCatalog(data) or nil
        runtime.catalogBusy=false
        if not items then
            Label(catalogLabel,"Catalog: "..#runtime.catalog.." • offline / update failed")
            WarnOnce("network","Catalog update failed. The cached or built-in list remains available.")
            return
        end
        warnings.network=nil
        AdoptCatalog(items,"7yd7 online catalog")
        if type(write)=="function" then
            local saved=pcall(function() write(CACHE,HttpService:JSONEncode({version=1,data=items})) end)
            if not saved then WarnOnce("cache","Could not save the catalog cache; the list still works this session.") end
        end
    end)
end
runtime.RefreshCatalog=RefreshCatalog

-- Native Noir-styled Emotes page. It uses the supplied script's catalog, persistence and playback core.
do
    local UI = { connections = {}, cards = {}, settingsOpen = false, searchToken = 0 }
    runtime.browser = UI
    local theme = shared.theme or {}
    local C = {
        base = theme.base or Color3.fromRGB(9, 10, 13),
        panel = theme.panel or Color3.fromRGB(16, 18, 22),
        surface = theme.surface or Color3.fromRGB(24, 27, 32),
        card = theme.card or Color3.fromRGB(20, 24, 28),
        button = theme.button or Color3.fromRGB(34, 38, 44),
        accent = theme.accent or Color3.fromRGB(98, 230, 144),
        text = theme.text or Color3.fromRGB(240, 243, 246),
        dim = theme.dim or Color3.fromRGB(147, 156, 166),
        border = theme.border or Color3.fromRGB(68, 75, 84),
        danger = Color3.fromRGB(245, 142, 142),
    }
    local function Make(class, properties, parent)
        local instance = Instance.new(class)
        for key, value in pairs(properties or {}) do instance[key] = value end
        instance.Parent = parent
        return instance
    end
    local function Round(instance, radius)
        return Make("UICorner", { CornerRadius = UDim.new(0, radius or 10) }, instance)
    end
    local function Stroke(instance, color, transparency, thickness)
        return Make("UIStroke", { Color = color or C.border, Transparency = transparency or .45, Thickness = thickness or 1 }, instance)
    end
    local function Text(parent, value, size, position, dimensions, color)
        return Make("TextLabel", {
            BackgroundTransparency = 1, Text = value or "", TextColor3 = color or C.text,
            Font = Enum.Font.Gotham, TextSize = size or 14, TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center, Position = position or UDim2.new(), Size = dimensions or UDim2.new(1,0,1,0),
        }, parent)
    end
    local function Button(parent, value, position, dimensions)
        local button = Make("TextButton", {
            BackgroundColor3 = C.button, BackgroundTransparency = .06, BorderSizePixel = 0,
            Text = value or "", TextColor3 = C.text, Font = Enum.Font.GothamMedium,
            TextSize = 13, AutoButtonColor = false, Position = position or UDim2.new(), Size = dimensions or UDim2.new(),
        }, parent)
        Round(button, 10); Stroke(button, C.border, .52)
        button.MouseEnter:Connect(function() if button.Parent then button.BackgroundColor3 = C.surface end end)
        button.MouseLeave:Connect(function() if button.Parent then button.BackgroundColor3 = C.button end end)
        return button
    end
    local function Connect(signal, callback)
        local connection = signal:Connect(callback)
        UI.connections[#UI.connections + 1] = connection
        return connection
    end
    local function Save()
        SaveSettings()
    end
    local function SetSelected(item)
        if not item then return end
        prefs.selected = { id = item.id, name = item.name }
        Save()
        if runtime.UpdateCardStatus then runtime.UpdateCardStatus() end
    end
    local function ToggleFavorite(item)
        local key = IdText(item.id)
        if prefs.favorites[key] then prefs.favorites[key] = nil else prefs.favorites[key] = { id = item.id, name = item.name } end
        Save()
        if prefs.favoritesOnly then Filter(false) elseif runtime.UpdateCardStatus then runtime.UpdateCardStatus() end
    end
    local function SetLoop(value)
        prefs.loop = value == true
        Save()
        if runtime.track then pcall(function() runtime.track.Looped = prefs.loop end) end
        if runtime.UpdateCardStatus then runtime.UpdateCardStatus() end
    end
    local function SetMove(value)
        prefs.walk = value == true
        Save()
        if runtime.UpdateCardStatus then runtime.UpdateCardStatus() end
    end
    local function SetSpeed(value)
        prefs.speed = math.clamp(math.floor((tonumber(value) or prefs.speed) * 100 + .5) / 100, 0, 3)
        Save()
        if runtime.track then pcall(function() runtime.track:AdjustSpeed(prefs.speed) end) end
        if runtime.UpdateCardStatus then runtime.UpdateCardStatus() end
    end
    -- Circular pin buttons create draggable on-screen photo shortcuts, matching the supplied card browser behavior.
    local quickGui, quickRecords, quickConnections = nil, {}, {}
    local function clearQuickConnections()
        for _, connection in ipairs(quickConnections) do pcall(function() connection:Disconnect() end) end
        table.clear(quickConnections)
    end
    local function destroyQuickGui()
        clearQuickConnections()
        if quickGui then quickGui:Destroy() end
        quickGui, quickRecords = nil, {}
    end
    local function ensureQuickGui()
        if quickGui and quickGui.Parent then return quickGui end
        quickGui = Instance.new("ScreenGui")
        quickGui.Name, quickGui.ResetOnSpawn, quickGui.IgnoreGuiInset, quickGui.DisplayOrder = "NoirEmoteQuickButtons", false, true, 90
        local parent
        if type(gethui) == "function" then
            local ok, value = pcall(gethui)
            if ok and typeof(value) == "Instance" then parent = value end
        end
        quickGui.Parent = parent or Player:WaitForChild("PlayerGui")
        return quickGui
    end
    local function viewport()
        return workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(900,600)
    end
    local function positionQuick(record)
        local saved = prefs.shortcuts[record.key]
        if not saved then return end
        local screen = viewport()
        record.button.Position = UDim2.fromOffset(math.clamp(saved.x * screen.X, 38, math.max(38, screen.X - 38)), math.clamp(saved.y * screen.Y, 38, math.max(38, screen.Y - 38)))
    end
    local function createQuick(key, saved)
        -- Rounded-square photo control using the same dark body and metallic double border as Shoot Murder.
        local button = Instance.new("TextButton")
        button.Name, button.AnchorPoint, button.Size = "Emote_" .. key, Vector2.new(.5,.5), UDim2.fromOffset(88,88)
        button.BackgroundColor3, button.BackgroundTransparency, button.BorderSizePixel = Color3.fromRGB(8,8,10), .28, 0
        button.Text, button.AutoButtonColor, button.ZIndex = "", false, 91
        button.Parent = ensureQuickGui()
        local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0,16); corner.Parent = button
        local outline = Instance.new("UIStroke"); outline.Color, outline.Thickness, outline.ApplyStrokeMode, outline.Parent = Color3.fromRGB(255,255,255), 2, Enum.ApplyStrokeMode.Border, button
        local shine = Instance.new("UIGradient")
        shine.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(35,35,40)), ColorSequenceKeypoint.new(.22, Color3.fromRGB(250,250,252)),
            ColorSequenceKeypoint.new(.48, Color3.fromRGB(70,70,78)), ColorSequenceKeypoint.new(.72, Color3.fromRGB(255,255,255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(45,45,52)),
        })
        shine.Parent = outline
        local inner = Instance.new("UIStroke"); inner.Color, inner.Transparency, inner.Thickness, inner.Parent = Color3.fromRGB(105,105,112), .5, 1, button
        local innerShine = shine:Clone(); innerShine.Rotation = 180; innerShine.Parent = inner
        local image = Instance.new("ImageLabel")
        image.Name, image.AnchorPoint, image.Position, image.Size = "Photo", Vector2.new(.5,.5), UDim2.fromScale(.5,.5), UDim2.fromOffset(62,62)
        image.BackgroundTransparency, image.Image, image.ScaleType, image.ZIndex = 1, "rbxthumb://type=Asset&id=" .. key .. "&w=420&h=420", Enum.ScaleType.Fit, 92
        image.Parent = button
        local imageCorner = Instance.new("UICorner"); imageCorner.CornerRadius = UDim.new(0,11); imageCorner.Parent = image
        local record = { key = key, item = { id = saved.id, name = saved.name }, button = button, dragging = false, moved = false }
        quickRecords[key] = record
        positionQuick(record)
        local dragInput, start, startPosition
        quickConnections[#quickConnections+1] = button.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            record.dragging, record.moved, dragInput, start, startPosition = true, false, input, input.Position, button.Position
        end)
        quickConnections[#quickConnections+1] = UIS.InputChanged:Connect(function(input)
            if not record.dragging then return end
            if input ~= dragInput and not (dragInput.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement) then return end
            local delta = input.Position - start
            if delta.Magnitude > 7 then record.moved = true end
            button.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end)
        quickConnections[#quickConnections+1] = UIS.InputEnded:Connect(function(input)
            if not record.dragging or input ~= dragInput then return end
            record.dragging = false
            if record.moved then
                local screen = viewport()
                prefs.shortcuts[key].x = math.clamp(button.Position.X.Offset / math.max(screen.X,1), 0, 1)
                prefs.shortcuts[key].y = math.clamp(button.Position.Y.Offset / math.max(screen.Y,1), 0, 1)
                record.blockUntil = os.clock() + .25
                Save()
            end
        end)
        quickConnections[#quickConnections+1] = button.Activated:Connect(function()
            if record.moved or (record.blockUntil and os.clock() < record.blockUntil) then return end
            SetSelected(record.item); Play(record.item, false)
        end)
    end
    local function RefreshQuickButtons()
        for key, record in pairs(quickRecords) do
            if not prefs.shortcuts[key] then record.button:Destroy(); quickRecords[key] = nil end
        end
        for key, saved in pairs(prefs.shortcuts) do
            if not quickRecords[key] then createQuick(key, saved) else positionQuick(quickRecords[key]) end
        end
        if not next(prefs.shortcuts) then destroyQuickGui() end
    end
    local function ToggleQuick(item)
        local key = IdText(item.id)
        if prefs.shortcuts[key] then
            prefs.shortcuts[key] = nil
        else
            local count = 0
            for _ in pairs(prefs.shortcuts) do count += 1 end
            if count >= MAX_SHORTCUTS then Notify("Maximum " .. MAX_SHORTCUTS .. " on-screen emote buttons."); return end
            local screen = viewport()
            prefs.shortcuts[key] = { id = item.id, name = item.name, x = .86, y = math.clamp(.28 + count * .1, .18, .82) }
        end
        Save(); RefreshQuickButtons()
        if runtime.UpdateCardStatus then runtime.UpdateCardStatus() end
    end

    local function Layout()
        if not (UI.root and UI.cardsScroll) then return end
        local size = UI.root.AbsoluteSize
        if size.X < 1 or size.Y < 1 then return end
        local narrow = size.X < 570
        local veryNarrow = size.X < 410
        UI.search.Position = UDim2.fromOffset(18, 68)
        UI.search.Size = UDim2.new(1, narrow and -138 or -268, 0, 38)
        UI.favoriteFilter.Position = UDim2.new(1, narrow and -112 or -242, 0, 68)
        UI.favoriteFilter.Size = UDim2.fromOffset(narrow and 94 or 118, 38)
        UI.settingsButton.Position = UDim2.new(1, narrow and -18 or -116, 0, 18)
        UI.settingsButton.AnchorPoint = Vector2.new(1, 0)
        UI.settingsButton.Size = UDim2.fromOffset(narrow and 86 or 98, 32)
        UI.random.Position = UDim2.new(1, narrow and -18 or -18, 0, 110)
        UI.random.AnchorPoint = Vector2.new(1, 0)
        UI.random.Size = UDim2.fromOffset(narrow and 82 or 94, 30)
        UI.stop.Position = UDim2.new(1, narrow and -108 or -122, 0, 110)
        UI.stop.AnchorPoint = Vector2.new(1, 0)
        UI.stop.Size = UDim2.fromOffset(narrow and 82 or 94, 30)
        UI.summary.Position = UDim2.fromOffset(20, 112)
        UI.summary.Size = UDim2.new(1, narrow and -200 or -260, 0, 28)
        local top, footer = 148, 58
        UI.cardsScroll.Position = UDim2.fromOffset(18, top)
        UI.cardsScroll.Size = UDim2.new(1, -36, 1, -(top + footer + 10))
        UI.footer.Position = UDim2.new(0, 18, 1, -54)
        UI.footer.Size = UDim2.new(1, -36, 0, 40)
        -- Use the full Noir tab width, matching the supplied menu's three-card gallery on wider screens.
        local available = math.max(1, size.X - 48)
        -- Scale-based cells fill the whole Noir page even when the mobile UI has a UIScale applied.
        local columns, padding, cellHeight = 3, 12, 250
        UI.grid.CellSize = UDim2.new(1 / columns, -10, 0, cellHeight)
        UI.grid.FillDirectionMaxCells = columns
        local rows = math.ceil(#UI.cards / columns)
        UI.cardsScroll.CanvasSize = UDim2.fromOffset(0, math.max(0, rows * (cellHeight + padding) - padding + 8))
        UI.settings.Size = UDim2.fromOffset(math.min(290, math.max(230, size.X - 36)), math.min(470, math.max(250, size.Y - 96)))
        UI.settings.Position = UDim2.new(1, -18, 0, 58)
        UI.settings.AnchorPoint = Vector2.new(1, 0)
    end
    runtime.ApplyBrowserAppearance = Layout
    runtime.ResetBrowserPosition = function() Layout() end
    local function UpdateStatus()
        if not UI.root then return end
        local pages = math.max(1, math.ceil(#runtime.filtered / PAGE_SIZE))
        UI.page.Text = "Page " .. runtime.page .. " / " .. pages
        UI.status.Text = runtime.status or "Ready — select an emote and press Play"
        UI.summary.Text = runtime.filtering and "Searching emotes..." or (tostring(#runtime.filtered) .. " emotes")
        UI.favoriteFilter.Text = prefs.favoritesOnly and "★ Saved" or "☆ Saved"
        UI.favoriteFilter.TextColor3 = prefs.favoritesOnly and C.accent or C.text
        UI.favoriteFilter.BackgroundColor3 = prefs.favoritesOnly and C.surface or C.button
        UI.loop.Text = prefs.loop and "Loop  ON" or "Loop  OFF"
        UI.loop.TextColor3 = prefs.loop and C.accent or C.text
        UI.move.Text = prefs.walk and "Move  ON" or "Move  OFF"
        UI.move.TextColor3 = prefs.walk and C.accent or C.text
        UI.speedValue.Text = "Speed " .. tostring(prefs.speed)
        for _, card in ipairs(UI.cards) do
            local selected = prefs.selected and prefs.selected.id == card.item.id
            local playing = runtime.track and runtime.playing and runtime.playing.id == card.item.id
            card.stroke.Color = selected and C.accent or C.border
            card.stroke.Transparency = selected and .08 or .62
            card.star.Text = prefs.favorites[IdText(card.item.id)] and "★" or "☆"
            card.star.TextColor3 = prefs.favorites[IdText(card.item.id)] and C.accent or C.text
            card.pin.Text = prefs.shortcuts[IdText(card.item.id)] and "●" or "○"
            card.pin.TextColor3 = prefs.shortcuts[IdText(card.item.id)] and C.accent or C.dim
            card.play.Text = playing and "■" or "▶"
            card.play.BackgroundColor3 = playing and Color3.fromRGB(71, 91, 78) or C.button
            card.play.TextColor3 = playing and C.accent or C.text
        end
    end
    runtime.UpdateCardStatus = UpdateStatus
    local function BuildCard(item, order)
        local card = Make("Frame", { Name = "Emote_" .. IdText(item.id), LayoutOrder = order, BackgroundColor3 = C.card, BorderSizePixel = 0, ClipsDescendants = true }, UI.cardsScroll)
        local cardConnections = {}
        local function CardConnect(signal, callback)
            local connection = signal:Connect(callback)
            cardConnections[#cardConnections + 1] = connection
            return connection
        end
        Round(card, 14)
        local outline = Stroke(card, C.border, .62, 1)
        local title = Text(card, item.name, 15, UDim2.fromOffset(12, 10), UDim2.new(1, -70, 0, 36))
        title.TextWrapped = true; title.TextTruncate = Enum.TextTruncate.AtEnd; title.Font = Enum.Font.GothamMedium; title.TextYAlignment = Enum.TextYAlignment.Top
        local star = Button(card, "☆", UDim2.new(1, -50, 0, 8), UDim2.fromOffset(38, 36))
        star.BackgroundTransparency = 1; star.TextSize = 27
        local image = Make("ImageButton", { BackgroundTransparency = 1, AutoButtonColor = false, AnchorPoint = Vector2.new(.5,.5), Position = UDim2.new(.5, 0, .55, 0), Size = UDim2.fromOffset(130,130), Image = "rbxthumb://type=Asset&id=" .. IdText(item.id) .. "&w=420&h=420", ScaleType = Enum.ScaleType.Fit }, card)
        local pin = Button(card, "○", UDim2.new(1, -60, .48, 0), UDim2.fromOffset(46,46))
        pin.BackgroundTransparency = 1; pin.TextSize = 30
        local play = Button(card, "▶", UDim2.new(1, -62, 1, -62), UDim2.fromOffset(50,50)); play.TextSize = 20
        local record = { frame = card, connections = cardConnections, item = item, stroke = outline, star = star, pin = pin, play = play }
        UI.cards[#UI.cards + 1] = record
        CardConnect(image.Activated, function() SetSelected(item) end)
        CardConnect(star.Activated, function() ToggleFavorite(item) end)
        CardConnect(pin.Activated, function() ToggleQuick(item) end)
        CardConnect(play.Activated, function()
            local playing = runtime.track and runtime.playing and runtime.playing.id == item.id
            SetSelected(item)
            if playing then StopCurrent("Stopped") else Play(item, false) end
            UpdateStatus()
        end)
    end
    local function RenderCards()
        if not UI.root then return end
        -- Do not create thumbnail cards while this page is hidden. The visible-page handler performs one render on open.
        if not container.Visible then UI.needsRender = true; return end
        for _, record in ipairs(UI.cards) do
            for _, connection in ipairs(record.connections or {}) do pcall(function() connection:Disconnect() end) end
            if record.frame then record.frame:Destroy() end
        end
        UI.cards = {}
        UI.needsRender = false
        local first = (runtime.page - 1) * PAGE_SIZE + 1
        local last = math.min(runtime.page * PAGE_SIZE, #runtime.filtered)
        for index = first, last do BuildCard(runtime.filtered[index], index - first + 1) end
        UI.empty.Visible = #runtime.filtered == 0
        UI.empty.Text = runtime.filtering and "Searching..." or (prefs.favoritesOnly and "No saved emotes yet." or "No emotes match your search.")
        UI.cardsScroll.CanvasPosition = Vector2.zero
        Layout(); UpdateStatus()
    end
    runtime.RenderCards = RenderCards
    local function Build()
        local old = container:FindFirstChild("NoirEmotesNative")
        if old then old:Destroy() end
        UI.root = Make("Frame", { Name = "NoirEmotesNative", Position = UDim2.fromOffset(12, 12), Size = UDim2.new(1, -24, 0, 640), BackgroundColor3 = C.base, BorderSizePixel = 0, ClipsDescendants = true }, container)
        if shared.SetCanvasHeight then shared.SetCanvasHeight(664) end
        Round(UI.root, 18); Stroke(UI.root, C.border, .35, 1.2)
        local gradient = Make("UIGradient", { Color = ColorSequence.new(C.base, Color3.fromRGB(7, 30, 31)), Rotation = 20 }, UI.root)
        Text(UI.root, "EMOTES", 21, UDim2.fromOffset(18, 14), UDim2.new(1,-150,0,24)).Font = Enum.Font.GothamBold
        Text(UI.root, "R15 ANIMATION LIBRARY", 10, UDim2.fromOffset(19, 39), UDim2.new(1,-150,0,16), C.dim)
        UI.settingsButton = Button(UI.root, "Settings", UDim2.new(1,-116,0,18), UDim2.fromOffset(98,32))
        UI.search = Make("TextBox", { BackgroundColor3 = C.surface, BorderSizePixel = 0, Text = prefs.query, PlaceholderText = "Search emote or ID...", PlaceholderColor3 = C.dim, TextColor3 = C.text, Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false }, UI.root)
        Round(UI.search, 10); Stroke(UI.search, C.border, .55); Make("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 8) }, UI.search)
        UI.favoriteFilter = Button(UI.root, "☆ Saved", UDim2.new(), UDim2.fromOffset(118,38))
        UI.random = Button(UI.root, "Random", UDim2.new(), UDim2.fromOffset(94,30))
        UI.stop = Button(UI.root, "■ Stop", UDim2.new(), UDim2.fromOffset(94,30)); UI.stop.TextColor3 = C.danger
        UI.summary = Text(UI.root, "Loading emotes...", 12, UDim2.fromOffset(20,112), UDim2.new(1,-260,0,28), C.dim)
        UI.cardsScroll = Make("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = C.accent, CanvasSize = UDim2.fromOffset(0,0), ScrollingDirection = Enum.ScrollingDirection.Y, ElasticBehavior = Enum.ElasticBehavior.Never }, UI.root)
        Make("UIPadding", { PaddingLeft = UDim.new(0,2), PaddingRight = UDim.new(0,8), PaddingTop = UDim.new(0,2), PaddingBottom = UDim.new(0,6) }, UI.cardsScroll)
        UI.grid = Make("UIGridLayout", { SortOrder = Enum.SortOrder.LayoutOrder, CellPadding = UDim2.fromOffset(12,12), CellSize = UDim2.fromOffset(240,170) }, UI.cardsScroll)
        UI.empty = Text(UI.root, "No emotes found", 16, UDim2.fromOffset(26,185), UDim2.new(1,-52,0,200), C.dim)
        UI.empty.TextXAlignment = Enum.TextXAlignment.Center; UI.empty.TextYAlignment = Enum.TextYAlignment.Center; UI.empty.Visible = false
        UI.footer = Make("Frame", { BackgroundTransparency = 1 }, UI.root)
        UI.previous = Button(UI.footer, "‹", UDim2.fromOffset(0,0), UDim2.fromOffset(46,38)); UI.previous.TextSize = 28
        UI.next = Button(UI.footer, "›", UDim2.new(1,-46,0,0), UDim2.fromOffset(46,38)); UI.next.TextSize = 28
        UI.page = Text(UI.footer, "Page 1 / 1", 12, UDim2.fromOffset(54,0), UDim2.new(1,-108,0,38), C.dim); UI.page.TextXAlignment = Enum.TextXAlignment.Center
        UI.status = Text(UI.footer, "Ready", 11, UDim2.fromOffset(2,39), UDim2.new(1,-4,0,14), C.dim)
        -- Settings content is taller than a phone-sized drawer, so make the drawer itself vertically scrollable.
        UI.settings = Make("ScrollingFrame", { BackgroundColor3 = C.panel, BorderSizePixel = 0, Visible = false, ZIndex = 20,
            ClipsDescendants = true, Active = true, ScrollBarThickness = 4, ScrollBarImageColor3 = C.accent,
            ScrollingDirection = Enum.ScrollingDirection.Y, ElasticBehavior = Enum.ElasticBehavior.Never,
            CanvasSize = UDim2.fromOffset(0, 388) }, UI.root)
        Round(UI.settings, 14); Stroke(UI.settings, C.border, .2, 1.2)
        Text(UI.settings, "EMOTE SETTINGS", 15, UDim2.fromOffset(16,14), UDim2.new(1,-32,0,24)).Font = Enum.Font.GothamBold
        local function SettingsButton(label, y)
            local button = Button(UI.settings, label, UDim2.fromOffset(16,y), UDim2.new(1,-32,0,36)); button.ZIndex = 21; return button
        end
        UI.loop = SettingsButton("Loop  OFF", 52)
        UI.move = SettingsButton("Move  OFF", 96)
        UI.speedMinus = SettingsButton("−", 140); UI.speedMinus.Size = UDim2.fromOffset(38,36)
        UI.speedValue = SettingsButton("Speed 1", 140); UI.speedValue.Position = UDim2.fromOffset(62,140); UI.speedValue.Size = UDim2.new(1,-124,0,36)
        UI.speedPlus = SettingsButton("+", 140); UI.speedPlus.Position = UDim2.new(1,-54,0,140); UI.speedPlus.Size = UDim2.fromOffset(38,36)
        UI.custom = Make("TextBox", { BackgroundColor3 = C.surface, BorderSizePixel = 0, Position = UDim2.fromOffset(16,188), Size = UDim2.new(1,-32,0,36), Text = prefs.customId, PlaceholderText = "Custom animation ID", PlaceholderColor3 = C.dim, TextColor3 = C.text, Font = Enum.Font.Gotham, TextSize = 13, ClearTextOnFocus = false, ZIndex = 21 }, UI.settings)
        Round(UI.custom, 9); Stroke(UI.custom, C.border, .5); Make("UIPadding", { PaddingLeft = UDim.new(0,10) }, UI.custom)
        UI.playCustom = SettingsButton("Play custom animation", 232)
        UI.refresh = SettingsButton("Refresh catalog", 276)
        UI.closeSettings = SettingsButton("Close settings", 320)
        Connect(UI.settingsButton.Activated, function()
            UI.settingsOpen = not UI.settingsOpen
            UI.settings.Visible = UI.settingsOpen
            if UI.settingsOpen then UI.settings.CanvasPosition = Vector2.zero end
        end)
        Connect(UI.closeSettings.Activated, function() UI.settingsOpen = false; UI.settings.Visible = false end)
        Connect(UI.loop.Activated, function() SetLoop(not prefs.loop) end)
        Connect(UI.move.Activated, function() SetMove(not prefs.walk) end)
        Connect(UI.speedMinus.Activated, function() SetSpeed(prefs.speed - .25) end)
        Connect(UI.speedPlus.Activated, function() SetSpeed(prefs.speed + .25) end)
        Connect(UI.refresh.Activated, RefreshCatalog)
        Connect(UI.playCustom.Activated, function()
            prefs.customId = UI.custom.Text:sub(1,200); Save()
            local id = ParseId(prefs.customId)
            if not id then Notify("Enter a valid animation ID."); return end
            Play({ id = id, name = "Custom " .. IdText(id) }, true)
        end)
        Connect(UI.custom.FocusLost, function() prefs.customId = UI.custom.Text:sub(1,200); Save() end)
        Connect(UI.favoriteFilter.Activated, function() prefs.favoritesOnly = not prefs.favoritesOnly; Save(); Filter(true) end)
        Connect(UI.random.Activated, function()
            if runtime.filtering or #runtime.filtered == 0 then Notify("No emotes available yet."); return end
            local item = runtime.filtered[math.random(1,#runtime.filtered)]; SetSelected(item); Play(item,false)
        end)
        Connect(UI.stop.Activated, function() StopCurrent("Stopped") end)
        Connect(UI.previous.Activated, function() runtime.page = math.max(1, runtime.page - 1); RenderPage() end)
        Connect(UI.next.Activated, function() runtime.page = runtime.page + 1; RenderPage() end)
        Connect(UI.search:GetPropertyChangedSignal("Text"), function()
            UI.searchToken = UI.searchToken + 1
            local ticket = UI.searchToken
            task.delay(.25, function()
                if not runtime.alive or ticket ~= UI.searchToken then return end
                prefs.query = UI.search.Text:sub(1,200); Save(); Filter(true)
            end)
        end)
        Connect(UI.search.FocusLost, function() prefs.query = UI.search.Text:sub(1,200); Save(); Filter(true) end)
        Connect(UI.root:GetPropertyChangedSignal("AbsoluteSize"), function() task.defer(Layout) end)
        Connect(UI.cardsScroll:GetPropertyChangedSignal("AbsoluteSize"), function() task.defer(Layout) end)
        Connect(container:GetPropertyChangedSignal("Visible"), function()
            if container.Visible then task.delay(.05, function() if runtime.alive and UI.root then Layout(); RenderCards() end end) end
        end)
        Layout(); RenderCards(); RefreshQuickButtons()
    end
    function runtime.OpenBrowser()
        if not runtime.alive then return end
        if UI.root and UI.root.Parent then UI.root.Visible = true; RenderCards(); return end
        local ok, err = pcall(Build)
        if not ok then WarnOnce("native_ui", "Could not build the Noir Emotes page: " .. tostring(err)) end
    end
    function runtime.CloseBrowser() end
    function runtime.RestoreQuickButtons() end
    function runtime.SyncQuickButtons() end
    function runtime.ClearQuickButtons() prefs.shortcuts = {}; Save() end
    function runtime.DestroyBrowser()
        for _, connection in ipairs(UI.connections) do pcall(function() connection:Disconnect() end) end
        UI.connections = {}
        destroyQuickGui()
        if UI.root then UI.root:Destroy() end
        UI.root = nil; UI.cards = {}
    end
end

-- The supplied card browser is embedded directly in Noir's Emotes page; no duplicate native control sections.
function runtime.SyncNative() end
runtime.initializing=false
_G[KEY]=runtime
local cache=ReadJSON(CACHE)
local cachedItems=NormalizeCatalog(cache)
AdoptCatalog(cachedItems or BUILTIN,cachedItems and "saved cache" or "built-in starter list")
Status("Ready — select an emote and press Play")
RefreshCatalog()
task.defer(function()
    if runtime.alive then runtime.OpenBrowser() end
end)

]==]
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



local selfMods = tab:AddSection("MAIN \u{2022} SELF MODS", "Universal player controls")
selfMods:AddToggle("Enable WalkSpeed", function(v) utility.walkEnabled = v; applyCharacterMods() end)
selfMods:AddSlider("WalkSpeed", 8, 100, 16, function(v) utility.walkSpeed = v; applyCharacterMods() end)
selfMods:AddToggle("Enable JumpPower", function(v) utility.jumpEnabled = v; applyCharacterMods() end)
selfMods:AddSlider("JumpPower", 25, 150, 50, function(v) utility.jumpPower = v; applyCharacterMods() end)
selfMods:AddToggle("Anti AFK", function(v) utility.antiAfk = v end)

local serverMods = tab:AddSection("MAIN \u{2022} SERVER", "MM2 round information")
serverMods:AddToggle("Show Round Timer", setRoundTimerVisible)
serverMods:AddToggle("Instant Role Detection", function(v) instantRoleDetection = v; if v then task.spawn(refreshTarget) end end)
serverMods:AddToggle("Auto Notify Roles", function(v) autoNotifyRoles = v; if not v then table.clear(announcedRoles) else task.spawn(refreshTarget) end end)
serverMods:AddButton("Show Murderer Chance", showMurdererChance)
serverMods:AddButton("Refresh Roles", refreshTarget)
serverMods:AddLabel("Roles are sampled during the 10 second countdown.")

local gunUtilities = tab:AddSection("WORLD \u{2022} GUN", "Auto GG, pickup, aura, notifications and bind button")
gunUtilities:AddToggle("Enable Auto GG", setAutoGG)
gunUtilities:AddLabel("Auto GG picks up GunDrop while you do not have a Gun.")
gunUtilities:AddButton("Grab Gun", requestGrabGun)
gunUtilities:AddToggle("Gun Aura", setGunAura)
gunUtilities:AddSlider("Gun Aura Range", 5, 250, gunUtilityState.auraRange, function(value)
    gunUtilityState.auraRange = tonumber(value) or gunUtilityState.auraRange
end)
gunUtilities:AddToggle("Auto Notify Dropped Gun", function(enabled)
    gunUtilityState.droppedGunNotify = enabled == true
end)
gunUtilities:AddToggle("Gun Pickup Notify", function(enabled)
    gunUtilityState.gunPickupNotify = enabled == true
end)
gunUtilities:AddToggle("Enable Grab Gun Bind Button", setGrabGunBindButton)
gunUtilities:AddSlider("Grab Gun Bind Button Size", 5, 25, gunUtilityState.bindButtonSize * 100, function(value)
    gunUtilityState.bindButtonSize = (tonumber(value) or 11) / 100
    updateGrabGunBindButtonSize()
end)
gunUtilities:AddLabel("Round Grab Gun button: drag it to move; its size and position are saved.")

do
    local combatAim=tab:AddSection("SILENT AIM", "Server FireServer redirect")
    combatAim:AddToggle("Enabled", toggle)
    combatAim:AddToggle("Wall Check", function(v) config.wallCheck=v==true end)
    combatAim:AddToggle("Show Shoot Murder Button", setShootButtonVisible)
    combatAim:AddToggle("Lock Shoot Murder Button", function(v) config.lockShootButton=v==true end)

    local combatGun=tab:AddSection("GUN", "Gun targeting controls")
    combatGun:AddToggle("Piercer Bullet", setPiercerBullet)
    combatGun:AddLabel("Sends a target-side Gun ray when a wall blocks the selected target.")

    local combatKnife=tab:AddSection("KNIFE SILENT AIM", "Nearest player or Sheriff-only targeting")
    combatKnife:AddToggle("Knife Silent Aim", function(v)
        config.knifeEnabled=v==true
        if config.knifeEnabled then installHook() end
    end)
    -- Preserve the previous Knife Radius value when upgrading the control name.
    local oldKnifeAuraKey = "KNIFE SILENT AIM::Knife Radius"
    local newKnifeAuraKey = "KNIFE SILENT AIM::Knife Throw Aura"
    if NoirPersistence.data.sliders[newKnifeAuraKey] == nil and NoirPersistence.data.sliders[oldKnifeAuraKey] ~= nil then
        NoirPersistence.data.sliders[newKnifeAuraKey] = NoirPersistence.data.sliders[oldKnifeAuraKey]
        NoirPersistence.Save()
    end
    -- The old working Knife Silent Aim kept this behavior enabled with no separate control.
    -- First run preserves that default; later user choices are saved normally.
    local knifeAuraToggle = combatKnife:AddToggle("KnifeThrown Aura", function(v) config.knifeThrownAura=v==true end)
    if NoirPersistence.data.toggles["KNIFE SILENT AIM::KnifeThrown Aura"] == nil then
        knifeAuraToggle(true)
    end
    combatKnife:AddSlider("Knife Throw Aura", 1, 40, config.knifeRadius, function(v) config.knifeRadius = tonumber(v) or config.knifeRadius end)
    combatKnife:AddToggle("Knife Wall Check", function(v) config.knifeWallCheck=v==true end)
    combatKnife:AddToggle("Prioritize Sheriff", function(v)
        config.knifePrioritizeSheriff=v==true
    end)

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
    end
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

connectRemote("PlayerDataChanged", function(data) consumeData(data) end)
connectRemote("RoundStart", function(timerValue, roundData)
    beginRoundTimer(timerValue)
    murderer, sheriff, hero = nil, nil, nil
    table.clear(roleCache); table.clear(announcedRoles)
    if typeof(roundData) == "table" then consumeData(roundData) end
    task.spawn(refreshTarget)
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
        if config.enabled or config.knifeEnabled then
            local part = targetPart()
            local settings = config.enabled and config or config.knifeAim
            if part then sampleMotion(part, settings) end
        end
        task.wait(1 / 30)
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
    win.Position = targetPosition + UDim2.fromOffset(0, 32)
    win.BackgroundTransparency = 1
    win.Rotation = -1.2
    winScale.Scale = .68
    win.Visible = true
    TweenService:Create(win, TweenInfo.new(.56, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = targetPosition, BackgroundTransparency = .04, Rotation = 0 }):Play()
    TweenService:Create(winScale, TweenInfo.new(.62, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end)

notify("v4 ready \u{2022} " .. tostring(#getPlayers()) .. " players in server", 4)

do
    local function makeWorldPluginTab(base)
        local proxy = {}
        setmetatable(proxy, {
            __index = function(_, key)
                if key == "AddSection" then
                    return function(_, name, description)
                        name = tostring(name or "Plugin")
                        if string.sub(name, 1, 6) ~= "WORLD " then
                            name = "WORLD \u{2022} " .. name
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

    Instance.new("UICorner", bb).CornerRadius = __UD(0, 5)
    local stroke = Instance.new("UIStroke")
    stroke.Color = __RGB(255, 255, 255)
    stroke.Thickness = 1.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = bb
    local gradient = Instance.new("UIGradient")

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

    local ripple = Instance.new("Frame")
    ripple.Name = "@ripple"
    ripple.BackgroundColor3 = isGold and __RGB(255, 215, 0) or __RGB(0, 155, 255)
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
    BBSystem.Connections[id] = ODHX.Connect(__RS.RenderStepped, function()
        gradient.Rotation = (gradient.Rotation + 1) % 360
    end)
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

    local ImageButton = Instance.new("ImageButton")
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
    ripple.BackgroundColor3 = isGold and __RGB(255, 215, 0) or __RGB(0, 155, 255)
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

    Bind_MakeDraggable(ImageButton, buttonMaid, ripple, sound, clickFunc, function(position)
        BindableButtons.SavePosition(id, position)
    end)
    buttonMaid:GiveTask(ODHX.Connect(__RS.RenderStepped, function()
        Stroke.Rotation = (Stroke.Rotation + 1) % 360
    end))

    BindableButtons.Buttons[id] = ImageButton
    BindableButtons.Maids[id] = buttonMaid
    BindableButtons.Count = BindableButtons.Count + 1
    return ImageButton
end

function BindableButtons.DeleteBButton(id)
    -- Remove the managed button and any orphan left by a prior script execution.
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

-- A stale visual button must not survive while its Bind Button toggle is off.
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
        -- Only an explicit true from this toggle may create the floating Bind Button.
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
    bindButtonSize = 0.11,
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
        bigButtonSize = 200,
        bindButtonSize = 0.11,
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
    local buttonSizeY = 0.11
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
    ImageButton.BackgroundTransparency = 0.28
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
    ripple.BackgroundColor3 = Color3.fromRGB(0, 155, 255)
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

    local debounce = false
    local tInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

    local function onClick()
        if debounce then return end
        debounce = true
        local fOut = game:GetService("TweenService"):Create(ImageButton, tInfo, {ImageTransparency = 1})
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

        local fIn = game:GetService("TweenService"):Create(ImageButton, tInfo, {ImageTransparency = 0})
        fIn:Play()
        fIn.Completed:Wait()
        debounce = false
    end

    MakeDraggable(ImageButton, buttonMaid, ripple, sound, onClick)
    buttonMaid:GiveTask(ODHX.Connect(game:GetService("RunService").RenderStepped, function()
        Gradient.Rotation = (Gradient.Rotation + 1) % 360
    end))

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
local WALLHOP_COOLDOWN = 0.55

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


-- Embedded plugin: full user-supplied fling_мой.lua.txt, routed to the World page.
do
    local __pluginOk, __pluginError = xpcall(function()
-- Direct Noir integration: Fling uses Noir's own host and notification system.
local noirHost = host
assert(noirHost and type(noirHost.CreateTab) == "function", "Ultimate Fling: Noir host unavailable")
-- Local Fling state adapter. It uses no external shared-host global.
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
        return nil -- never serialize Instances, connections, functions or players
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
    X.shared=setmetatable({}, {__index=host}) -- never mutate the host API
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
        -- Options before enabling modules. Actions and player selections are never replayed.
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
        -- Route every original Fling card into Noir's existing World page.
        local raw=tab:AddSection("WORLD \u{2022} " .. name,subtitle or "")
        local section={Name=name,Raw=raw}
        local function register(kind,label,callback,default,min,max,items)
            local r={section=name,name=label,kind=kind,callback=callback,default=default,min=min,max=max,items=items,visual=false}
            r.key=key(name,label,kind)
            r.exclude=(name=="🔑 Keys") -- key-capture toggles are actions, not enabled modes
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
            -- Noir has no AddPlayerDropdown method; use its native dropdown with current player names.
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
    -- Stable GUI paths, never serialized Instances. Player name is session-independent.
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
-- END ODH 2026 ADAPTER

--[[
    ⚡ ULTIMATE FLING • FLING   —   V1.0
    Ultimate Fling GUI · Overdrive Hub plugin
    Author: K1LAS1K (original), adapted to ODH 2026
    =========================================================================
    Плагин мульти-таргет флинга: выбор игроков, непрерывный флинг,
    сохранение позиции, FPDH trick, бинды, хоткеи, HUD, настройка силы/длительности.

    ── ВОЗМОЖНОСТИ ────────────────────────────────────────────────────────────
      • Ручной флинг: Selected, Everyone, Nearest, Cancel
        и выбор конкретного игрока из списка.
      • Авто-режимы: Loop (по списку), Aura (по радиусу), Click (флинг кликом).
      • Плавающие бинды-кружки: перетаскивание с запоминанием позиции, размер,
        подсветка активности, общий звук клика.
      • Хоткеи на все действия: захват клавиши тумблером.
      • HUD-статус: пульс, имя текущей цели, перетаскивание с сохранением позиции.
      • Списки: выбор цели, список для Loop, вайтлист.
      • Сохранение настроек (readfile/writefile + JSON): длительность, сила,
        размеры и позиции кнопок/HUD, хоткеи, вайтлист.

    ── АРХИТЕКТУРА ────────────────────────────────────────────────────────────
      • Один RenderStepped-диспетчер, общие обработчики ввода.
      • Мультитач-совместимый драг, FPDH restore, cleanup + watchdog.
]]

-- ── Идентичность плагина ─────────────────────────
local AUTHOR            = "K1LAS1K"
local BRAND             = "ULTIMATE FLING"
local PLUGIN_ID         = "fling"
local PLUGIN_NAME       = BRAND .. " • FLING"
local VERSION           = "V1.0"
local VERSION_TAG       = "fling"
local MARKER_PREFIX     = "@fling_"
local CONFIG_PATH       = CONFIGS_FOLDER .. "/ODH_FLING_settings.json"
local STORAGE_NAME      = "@" .. PLUGIN_ID
local UNLOAD_GLOBAL     = "__FLING_UNLOAD"
local LEGACY_STORAGES   = { "@bindstorage_v6", "@bindstorage_v5", "@flingstorage_v1" }
local CLEAN_LEGACY_MENU = true

-- ====== Хост-уведомления ======
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

-- ====== Повторная загрузка ======
pcall(function()
    if type(getgenv) ~= "function" then return end
    local g = getgenv()
    if type(g) ~= "table" then return end
    local prev = rawget(g, UNLOAD_GLOBAL)
    rawset(g, UNLOAD_GLOBAL, nil)
    if type(prev) == "function" then pcall(prev) end
end)

-- ====== Maid ======
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

-- ====== Сервисы ======
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

-- ====== Шорткаты ======
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

-- ====== Конфигурация ======
local state_whitelist_ref = nil
local loadedWhitelist = {}
local persistDisabled = false

local DEFAULTS = {
    flingDuration     = 2,
    flingPower        = 1,
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
        "flingDuration", "flingPower", "autoReturn",
        "loopInterval", "auraInterval", "auraStuds",
        "bindButtonSize", "targetCooldown",
        "autoSheriffDelay", "autoMurdererDelay", "roleCacheTTL",
        "muteSounds", "notifications",
    }
    for _, key in ipairs(scalars) do
        local v = data[key]
        if v ~= nil and type(v) == type(DEFAULTS[key]) then config[key] = v end
    end
    -- clamp after load
    if type(config.flingDuration)=="number" then config.flingDuration=math.clamp(math.floor(config.flingDuration+0.5),1,5) end
    if type(config.flingPower)=="number" then config.flingPower=math.clamp(math.floor(config.flingPower+0.5),1,3) end
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

-- ====== Состояние ======
local state = {
    whitelist       = loadedWhitelist,
    selectedPlayers = {},
    selectedSet     = {},
    resetSelPlr     = nil,
    lastResetAt     = {},
}
state_whitelist_ref = state.whitelist

local maids = {
    loopPlr = nil, clickFling = nil, aura = nil,
    autoSheriff = nil, autoMurderer = nil,
}

-- ====== Уведомления ======
local lastNotify = { text = nil, at = 0 }
local function Notify(title, msg, dur)
    if not config.notifications then return end
    local text = msg and (title .. ": " .. msg) or title
    local t = now()
    if lastNotify.text == text and (t - lastNotify.at) < 0.35 then return end
    lastNotify.text, lastNotify.at = text, t
    hostNotify(text, dur or 3)
end

-- ====== Единый тикер ======
local Ticker = { _fns = {}, _conn = nil }

function Ticker._start()
    if Ticker._conn then return end
    Ticker._conn = RunService.RenderStepped:Connect(function(dt)
        local fns = Ticker._fns
        local i = 1
        while i <= #fns do
            local fn = fns[i]
            if fn then
                local ok, err = xpcall(fn, debug.traceback, dt)
                if not ok then
                    warn("[" .. BRAND .. "][ticker] " .. tostring(err))
                    table.remove(fns, i)
                    i = i - 1
                end
            end
            i = i + 1
        end
        if #fns == 0 and Ticker._conn then
            Ticker._conn:Disconnect()
            Ticker._conn = nil
        end
    end)
end

function Ticker.add(fn)
    if type(fn) ~= "function" then return function() end end
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
    clearTable(Ticker._fns)
end)

-- ====== Заголовки секций ======
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

-- ====== Хранилище GUI ======
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

-- ====== Реестр своих секций ======
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

-- ====== Сканер GUI ======
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

-- ====== Звук клика ======
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

-- ====== Bindable Buttons ======
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
    if not ok then warn("[" .. BRAND .. "][bind] " .. tostring(err)) end
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

    -- Noir/Shoot Murder visual style, preserved in the original circular Fling bind shape.
    local ImageButton = new("ImageButton")
    ImageButton.Name = id
    -- Pixel sizing guarantees a true circle on every screen ratio.
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
    Stroke.Color = isGold and __GOLD_NORMAL_COLOR or __NORMAL_COLOR
    local innerStroke = new("UIStroke", ImageButton)
    innerStroke.Color = rgb(105, 105, 112)
    innerStroke.Transparency = 0.5
    innerStroke.Thickness = 1
    innerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    local innerGradient = Stroke:Clone()
    innerGradient.Name = "@InnerStroke"
    innerGradient.Rotation = 180
    innerGradient.Parent = innerStroke

    local TextLabel = new("TextLabel", ImageButton)
    TextLabel.Name = "@Text"
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

    local ripple = new("Frame")
    ripple.Name = "@ripple"
    ripple.BackgroundColor3 = isGold and rgb(255, 215, 0) or rgb(0, 155, 255)
    ripple.BackgroundTransparency = 0.45
    ripple.Size = ud2(0, 0, 0, 0)
    ripple.AnchorPoint = v2(0.5, 0.5)
    ripple.Visible = false
    ripple.ZIndex = 2
    ripple.Parent = ImageButton
    new("UICorner", ripple).CornerRadius = ud(1, 0)

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

-- ====== Status HUD disabled by user request ======
-- Fling state remains fully functional; these no-op hooks preserve the action flow without creating a HUD.
local StatusHUD = { Set = function() end }
local function hudApplyPosition() end

-- ====== Цели для флинга ======
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

-- ====== Кэш ролей MM2 (для Sheriff / Murderer) ======
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

-- ====== Fling ядро (K1LAS1K / zqyDSUWX) ======
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
    BindableButtons.ResetActive=false
    StatusHUD.Set("idle")
end

-- основная функция - один таргет
local function SkidFling(TargetPlayer)
    if not TargetPlayer or not TargetPlayer.Parent then return false end
    if TargetPlayer == LocalPlayer or state.whitelist[TargetPlayer.UserId] then return false end

    -- кулдаун
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

    local savedDestroy = Workspace.FallenPartsDestroyHeight
    Workspace.FallenPartsDestroyHeight = 0/0 -- NaN trick
    if flingBV and flingBV.Parent then pcall(function() flingBV:Destroy() end) end
    flingBV = new("BodyVelocity")
    flingBV.Velocity = v3(0,0,0)
    flingBV.MaxForce = v3(9e9,9e9,9e9)
    flingBV.Parent = RootPart
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
        pcall(function() Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true) end)
        pcall(function() Workspace.CurrentCamera.CameraSubject = Humanoid end)
        if config.autoReturn and flingOldPos then
            local tries=0
            repeat
                if not RootPart or not RootPart.Parent then break end
                pcall(function()
                    RootPart.CFrame = flingOldPos * cfr(0,.5,0)
                    Character:SetPrimaryPartCFrame(flingOldPos * cfr(0,.5,0))
                    Humanoid:ChangeState("GettingUp")
                    for _, part in pairs(Character:GetChildren()) do
                        if part:IsA("BasePart") then
                            part.Velocity, part.RotVelocity = V3_ZERO, V3_ZERO
                        end
                    end
                end)
                task.wait()
                tries=tries+1
                if tries>20 then break end
            until (RootPart.Position - flingOldPos.p).Magnitude < 25
        end
        pcall(function() Workspace.FallenPartsDestroyHeight = flingFPDH end)
        BindableButtons.ResetActive=false
        StatusHUD.Set("idle")
    end
    flingObj.cancel=function() cleanup(true,true) end
    currentFling=flingObj
    BindableButtons.ResetActive=true
    StatusHUD.Set("active", TargetPlayer.Name)
    flingObj.watchdog = task.delay((config.flingDuration or 2)+2, function() if not done then cleanup(false) end end)

    local function FPos(BasePart, Pos, Ang)
        if not RootPart or not RootPart.Parent then return end
        pcall(function()
            RootPart.CFrame = cfr(BasePart.Position) * Pos * Ang
            Character:SetPrimaryPartCFrame(cfr(BasePart.Position) * Pos * Ang)
            RootPart.Velocity = v3(9e7*velMult, 9e7*10*velMult, 9e7*velMult)
            RootPart.RotVelocity = v3(9e8*rotMult, 9e8*rotMult, 9e8*rotMult)
        end)
    end

    local function SFBasePart(BasePart)
        local TimeToWait = config.flingDuration or 2
        local Time = tick()
        local Angle = 0
        repeat
            if done then break end
            if RootPart and THumanoid and BasePart and BasePart.Parent then
                if BasePart.Velocity.Magnitude < 50 then
                    Angle = Angle + 100
                    FPos(BasePart, cfr(0,1.5,0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude/1.25, CFrame.Angles(math.rad(Angle),0,0))
                    task.wait()
                    FPos(BasePart, cfr(0,-1.5,0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude/1.25, CFrame.Angles(math.rad(Angle),0,0))
                    task.wait()
                    FPos(BasePart, cfr(0,1.5,0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude/1.25, CFrame.Angles(math.rad(Angle),0,0))
                    task.wait()
                    FPos(BasePart, cfr(0,-1.5,0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude/1.25, CFrame.Angles(math.rad(Angle),0,0))
                    task.wait()
                    FPos(BasePart, cfr(0,1.5,0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle),0,0))
                    task.wait()
                    FPos(BasePart, cfr(0,-1.5,0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle),0,0))
                    task.wait()
                else
                    FPos(BasePart, cfr(0,1.5,THumanoid.WalkSpeed), CFrame.Angles(math.rad(90),0,0))
                    task.wait()
                    FPos(BasePart, cfr(0,-1.5,-THumanoid.WalkSpeed), CFrame.Angles(0,0,0))
                    task.wait()
                    FPos(BasePart, cfr(0,1.5,THumanoid.WalkSpeed), CFrame.Angles(math.rad(90),0,0))
                    task.wait()
                    FPos(BasePart, cfr(0,-1.5,0), CFrame.Angles(math.rad(90),0,0))
                    task.wait()
                    FPos(BasePart, cfr(0,-1.5,0), CFrame.Angles(0,0,0))
                    task.wait()
                    FPos(BasePart, cfr(0,-1.5,0), CFrame.Angles(math.rad(90),0,0))
                    task.wait()
                    FPos(BasePart, cfr(0,-1.5,0), CFrame.Angles(0,0,0))
                    task.wait()
                end
            else
                task.wait()
            end
        until Time + TimeToWait < tick()
    end

    if TRootPart then SFBasePart(TRootPart)
    elseif THead then SFBasePart(THead)
    elseif Handle then SFBasePart(Handle)
    else Notify("Fling", TargetPlayer.Name.." has no valid parts",2) end

    cleanup(true)
    return true
end

-- ====== Авто-модули ======
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

-- ====== Действия ======
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

local ACTION_ORDER={"sheriff","murderer","selected","all","nearest","start","cancel"}

local function runAction(id)
    local a=ACTIONS[id]
    if not a then return end
    local ok,err=xpcall(a.run, debug.traceback)
    if not ok then warn("["..BRAND.."][action:"..id.."] "..tostring(err)); Notify("Error","Action failed: "..id,3) end
end

-- ====== Хоткеи ======
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

-- ====== МЕНЮ ======

-- ⚡ Fling
local actionSection = AddSection("⚡ Fling")
actionSection:AddButton("🔫 Sheriff", function() runAction("sheriff") end)
actionSection:AddButton("🔪 Murderer", function() runAction("murderer") end)
actionSection:AddButton("🎯 Selected", function() runAction("selected") end)
actionSection:AddButton("👥 Everyone", function() runAction("all") end)
actionSection:AddButton("📍 Nearest", function() runAction("nearest") end)
actionSection:AddButton("▶ Start (list)", function() runAction("start") end)
actionSection:AddButton("⏹ Cancel", function() runAction("cancel") end)
actionSection:AddPlayerDropdown("▸ Fling player", function(p)
    if p and p ~= LocalPlayer then
        state.resetSelPlr = p
        if state.whitelist[p.UserId] then Notify("Whitelist", p.Name.." is whitelisted!",3)
        else SkidFling(p); Notify("Fling","Flinging "..p.Name,2) end
    end
end)

-- 🤖 Auto
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

-- 📋 Lists
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

-- ⚙️ Tuning
local settingsSection = AddSection("⚙️ Tuning")
settingsSection:AddSlider("Fling Duration", 1, 5, config.flingDuration, function(v) config.flingDuration=v; saveConfig() end)
settingsSection:AddSlider("Fling Power", 1, 3, config.flingPower, function(v) config.flingPower=v; saveConfig() end)
settingsSection:AddSlider("Aura Radius", 5, 50, config.auraStuds, function(v) config.auraStuds=v; saveConfig() end)
settingsSection:AddSlider("Loop Interval", 0.1, 1.0, config.loopInterval, function(v) config.loopInterval=v; saveConfig() end)
settingsSection:AddSlider("Aura Interval", 0.1, 1.0, config.auraInterval, function(v) config.auraInterval=v; saveConfig() end)
settingsSection:AddSlider("Target Cooldown", 0, 3, config.targetCooldown, function(v) config.targetCooldown=v; saveConfig() end)
settingsSection:AddSlider("Auto Sheriff Delay", 0.1, 1.0, config.autoSheriffDelay, function(v) config.autoSheriffDelay=v; saveConfig() end)
settingsSection:AddSlider("Auto Murderer Delay", 0.1, 1.0, config.autoMurdererDelay, function(v) config.autoMurdererDelay=v; saveConfig() end)
settingsSection:AddSlider("Role Cache TTL", 0.2, 3.0, config.roleCacheTTL, function(v) config.roleCacheTTL=v; saveConfig() end)
settingsSection:AddToggle("Auto Return", function(enabled) config.autoReturn=enabled and true or false; saveConfig() end)
settingsSection:AddToggle("Notifications", function(enabled) config.notifications=enabled and true or false; saveConfig() end)

-- 🔘 Binds
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
floatSection:AddSlider("Bind Size (%)", 5, 25, math.floor((config.bindButtonSize or 0.11)*100), function(value)
    BindableButtons.setSize(value/100)
end)
floatSection:AddButton("🧩 Reset bind layout", function() BindableButtons.resetLayout(); Notify("Binds","Layout reset",2) end)
floatSection:AddButton("🛑 Panic", function()
    cancelCurrentFling()
    for _,key in ipairs({"loopPlr","clickFling","aura","autoSheriff","autoMurderer"}) do stopAutoModule(key) end
    BindableButtons.clearAll()
    for _,r in ipairs(ODHX.records) do
        if r.kind=="Toggle" and (r.section=="🤖 Auto" or (r.section=="🔘 Binds" and r.name:sub(1,5)=="Bind ")) then
            ODHX.Set(r.section,r.name,r.kind,false,false)
        end
    end
    Notify("Panic","All modules stopped",3)
end)

-- 🔑 Keys
local keySection = AddSection("🔑 Keys")
for _,id in ipairs(ACTION_ORDER) do
    keySection:AddToggle("Key "..ACTIONS[id].name.." ["..keyName(id).."]", function(enabled)
        if enabled then Keybinds.capture=id; Notify("Hotkey","Press a key for "..ACTIONS[id].name.."...",5)
        else config.keybinds[id]=nil; if Keybinds.capture==id then Keybinds.capture=nil end; saveConfig(); Notify("Hotkey", ACTIONS[id].name.." key cleared",3) end
    end)
end
keySection:AddButton("🧹 Clear keys", function() clearTable(config.keybinds); Keybinds.capture=nil; saveConfig(); Notify("Hotkey","All hotkeys cleared",3) end)

-- ====== Пометить свои карточки ======
markOwnCards()

RootMaid:GiveTask(task.spawn(function()
    for _,delay in ipairs({1.5,2.5,3.0,5.0}) do
        task.wait(delay)
        pcall(markOwnCards)
        pcall(purgeForeign, true)
    end
end))

-- ====== Init ======
Audio.init()
-- Fling HUD intentionally disabled.
BindableButtons.setSize(config.bindButtonSize or 0.11)
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

-- ====== Очистка ======
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
