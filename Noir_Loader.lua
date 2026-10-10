--[[
    NOIR HUB  |  EVENT HORIZON BOOT LOADER
    Executors (compatibility list, как ODH):
      Windows: Xeno, Solara, Madium, Real, SirHurt, Potassium, Volt
      Android: Delta, Codex, Arceus X
      iOS: Delta
      Mac: Opiumware, Macsploit

    Все три release-part файла должны быть загружены в Gga/main.
    Raw-ссылки подключены ниже; loader скачивает, объединяет и запускает части без проверки версий.
]]

local RAW = {
    "https://raw.githubusercontent.com/mellnikovden968-web/Gga/refs/heads/main/Noir_Part1.lua",
    "https://raw.githubusercontent.com/mellnikovden968-web/Gga/refs/heads/main/Noir_Part2.lua",
    "https://raw.githubusercontent.com/mellnikovden968-web/Gga/refs/heads/main/Noir_Part3.lua",
}

-- Executor environment --------------------------------------------------------
local function getEnvironment()
    local ok, result = pcall(function()
        if type(getgenv) == "function" then return getgenv() end
    end)
    if ok and type(result) == "table" then return result end

    ok, result = pcall(function()
        if type(getfenv) == "function" then return getfenv(0) end
    end)
    if ok and type(result) == "table" then return result end
    return _G
end

local G = getEnvironment()
local HUB_LOCK_KEY = "__NoirHubRuntimeLock"
local LOADER_LOCK_KEY = "__NoirLoaderRuntimeLock"

local function recordGuiAlive(record)
    if type(record) ~= "table" or not record.gui then return false end
    local ok, parent = pcall(function() return record.gui.Parent end)
    return ok and parent ~= nil
end

local function duplicateNotice(message)
    pcall(function() warn("[Noir] " .. message) end)
end

local existingHub = G[HUB_LOCK_KEY]
if type(existingHub) == "table" then
    local age = os.clock() - (tonumber(existingHub.startedAt) or os.clock())
    local heartbeatAge = os.clock() - (tonumber(existingHub.heartbeat) or tonumber(existingHub.startedAt) or os.clock())
    if (existingHub.state == "running" and (recordGuiAlive(existingHub) or heartbeatAge < 120))
        or (existingHub.state == "starting" and (recordGuiAlive(existingHub) or age < 120)) then
        duplicateNotice("hub already starting/running; duplicate launch ignored")
        return
    end
    G[HUB_LOCK_KEY] = nil
end

local existingLoader = G[LOADER_LOCK_KEY]
if type(existingLoader) == "table" then
    local age = os.clock() - (tonumber(existingLoader.startedAt) or os.clock())
    local state = existingLoader.status
    if ((state == "loading" or state == "compiling" or state == "launching") and (recordGuiAlive(existingLoader) or age < 180))
        or ((state == "failed" or state == "running") and recordGuiAlive(existingLoader)) then
        duplicateNotice("loader already active; duplicate launch ignored")
        return
    end
    G[LOADER_LOCK_KEY] = nil
end

local loaderRecord = { status = "loading", startedAt = os.clock() }
G[LOADER_LOCK_KEY] = loaderRecord

local function pick(...)
    for i = 1, select("#", ...) do
        local value = select(i, ...)
        if type(value) == "function" then return value end
    end
end

local loadFn = pick(G.loadstring, loadstring, G.load, load)
local function requestFn()
    local synApi = G.syn or syn
    local fluxusApi = G.fluxus or fluxus
    local krnlApi = G.krnl or krnl
    return pick(
        synApi and synApi.request,
        G.http_request,
        G.request,
        G.http and G.http.request,
        fluxusApi and fluxusApi.request,
        krnlApi and krnlApi.request
    )
end

local function fetch(url)
    local request = requestFn()
    local lastError
    if request then
        local ok, response = pcall(request, {
            Url = url,
            Method = "GET",
            Headers = { ["User-Agent"] = "Mozilla/5.0" },
        })
        if ok and type(response) == "table" then
            local code = tonumber(response.StatusCode or response.status_code or response.Status)
            local body = response.Body or response.body or response.Source
            if code and (code < 200 or code >= 300) then
                lastError = "HTTP " .. tostring(code)
            elseif type(body) == "string" and #body > 32 then
                return body
            else
                lastError = "empty response"
            end
        elseif ok and type(response) == "string" and #response > 32 then
            return response
        else
            lastError = tostring(response)
        end
    end

    local ok, body = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and type(body) == "string" and #body > 32 then return body end
    if not ok then lastError = tostring(body) end

    ok, body = pcall(function()
        return game:HttpGetAsync(url)
    end)
    if ok and type(body) == "string" and #body > 32 then return body end
    if not ok then lastError = tostring(body) end
    return nil, lastError or "no supported HTTP method"
end

local getHiddenNative = pick(
    G.gethui, G.gethiddenui, G.get_hidden_gui, G.GetHiddenUI,
    gethui, gethiddenui
)
local function getGuiParent()
    if getHiddenNative then
        local ok, parent = pcall(getHiddenNative)
        if ok and typeof(parent) == "Instance" then return parent end
    end

    local coreGui = game:GetService("CoreGui")
    local clone = pick(G.cloneref, cloneref)
    if clone then
        local ok, parent = pcall(clone, coreGui)
        if ok and typeof(parent) == "Instance" then return parent end
    end
    return coreGui
end

-- Noir palette: deep-space black, graphite, and silver only --------------------
local C = {
    backdrop = Color3.fromRGB(2, 3, 5),
    panelTop = Color3.fromRGB(18, 20, 25),
    panelBottom = Color3.fromRGB(5, 6, 9),
    surface = Color3.fromRGB(17, 20, 25),
    surfaceHover = Color3.fromRGB(34, 38, 46),
    edge = Color3.fromRGB(84, 91, 103),
    text = Color3.fromRGB(244, 246, 250),
    secondary = Color3.fromRGB(171, 178, 190),
    muted = Color3.fromRGB(100, 108, 120),
    accent = Color3.fromRGB(222, 228, 238),
    accentDeep = Color3.fromRGB(39, 43, 51),
    error = Color3.fromRGB(226, 228, 233),
    warning = Color3.fromRGB(156, 163, 174),
}

local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local parentGui = getGuiParent()
local existingHubGui = parentGui:FindFirstChild("NoirSilentAimUI")
if not existingHubGui then
    pcall(function() existingHubGui = game:GetService("CoreGui"):FindFirstChild("NoirSilentAimUI") end)
end
if existingHubGui then
    G[LOADER_LOCK_KEY] = nil
    duplicateNotice("Noir Hub GUI already exists; duplicate launch ignored")
    return
end

pcall(function()
    local old = parentGui:FindFirstChild("NoirHubLoader")
    if old then old:Destroy() end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "NoirHubLoader"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 10000
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function()
    local protect = (G.syn and G.syn.protect_gui) or G.protect_gui or protect_gui
    if type(protect) == "function" then protect(gui) end
end)
local parentOk = pcall(function() gui.Parent = parentGui end)
if not parentOk then
    pcall(function()
        local player = game:GetService("Players").LocalPlayer
        gui.Parent = player and player:FindFirstChildOfClass("PlayerGui")
    end)
end
loaderRecord.gui = gui

local function make(className, parent, properties)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

local function round(object, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = object
    return corner
end

local function outline(object, color, transparency, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Transparency = transparency or 0
    stroke.Thickness = thickness or 1
    stroke.Parent = object
    return stroke
end

local function label(parent, text, position, size, fontSize, color, font, align)
    return make("TextLabel", parent, {
        BackgroundTransparency = 1,
        Position = position,
        Size = size,
        Font = font or Enum.Font.Gotham,
        Text = text,
        TextSize = fontSize,
        TextColor3 = color,
        TextXAlignment = align or Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = false,
        BorderSizePixel = 0,
        ZIndex = 3,
    })
end

-- Responsive canvas ----------------------------------------------------------
local overlay = make("Frame", gui, {
    Name = "Backdrop",
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = C.backdrop,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
})

local shell = make("Frame", gui, {
    Name = "LoaderShell",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(460, 330),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
})
local shellScale = Instance.new("UIScale")
shellScale.Parent = shell

local function fitToViewport()
    local camera = Workspace.CurrentCamera
    local view = camera and camera.ViewportSize or Vector2.new(1280, 720)
    local scale = math.min(view.X / 480, view.Y / 350, 1)
    shellScale.Scale = math.clamp(scale, 0.50, 1)
end
fitToViewport()
local camera = Workspace.CurrentCamera
local viewportConnection
if camera then
    viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(fitToViewport)
end

local glow = make("Frame", shell, {
    Name = "AccentGlow",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(452, 318),
    BackgroundColor3 = C.accent,
    BackgroundTransparency = 0.93,
    BorderSizePixel = 0,
    ZIndex = 1,
})
round(glow, 26)
outline(glow, C.accent, 0.9, 1)

local card = make("Frame", shell, {
    Name = "MainCard",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(430, 300),
    BackgroundColor3 = C.panelBottom,
    BorderSizePixel = 0,
    ZIndex = 2,
})
round(card, 21)
outline(card, C.edge, 0.48, 1)
local cardGradient = Instance.new("UIGradient")
cardGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, C.panelTop),
    ColorSequenceKeypoint.new(1, C.panelBottom),
})
cardGradient.Rotation = 90
cardGradient.Parent = card

local topAccent = make("Frame", card, {
    Name = "TopAccent",
    Position = UDim2.fromOffset(24, 0),
    Size = UDim2.new(1, -48, 0, 2),
    BackgroundColor3 = C.accent,
    BackgroundTransparency = 0.12,
    BorderSizePixel = 0,
    ZIndex = 3,
})
round(topAccent, 2)

-- Header / identity ----------------------------------------------------------
label(card, "NOIR  /  SYSTEMS", UDim2.fromOffset(24, 15), UDim2.fromOffset(190, 15), 9, C.muted, Enum.Font.GothamBold)

local closeButton = make("TextButton", card, {
    Name = "CloseButton",
    Position = UDim2.fromOffset(374, 12),
    Size = UDim2.fromOffset(35, 35),
    BackgroundColor3 = C.surface,
    BackgroundTransparency = 0.12,
    BorderSizePixel = 0,
    AutoButtonColor = false,
    Text = "×",
    TextColor3 = C.secondary,
    TextSize = 23,
    Font = Enum.Font.Gotham,
    ZIndex = 5,
})
round(closeButton, 11)

local logo = make("Frame", card, {
    Name = "LogoMark",
    Position = UDim2.fromOffset(24, 42),
    Size = UDim2.fromOffset(48, 48),
    BackgroundColor3 = C.panelBottom,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    ZIndex = 3,
})
round(logo, 15)
outline(logo, C.accent, 0.56, 1)

-- Compact 48-frame monochrome sprite, packed as an 8x6 grid of 96px cells.
-- Accretion material itself animates at 24 Hz; no orbit overlays are added.
-- It is decoded only when the executor exposes custom-asset APIs; the vector
-- fallback remains available everywhere else.
local BLACKHOLE_SPRITE_B64 = [=[
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
Uc80AI8EE8AI4wsAAIoUoUAI4kQkAIIYsYAMIkoYAMYUwUAIIEEUAAEIIsAAEMskAAEM8QAAAMo4AQAYUwAQAgwQAQAwM0AQAwcIwMAEAAcAoMAAU4IEAAEI
8EAAEA4EAAEE0MAAQAsIAAAY8MAA4wgIkIA800IIIggEgI8k4QoIoIQssIscsgEIswkQsIs8gYEAYskwQEQ0swogAg0wcgAI8wMkAE0w8kAgMw4sQskw4oQs
cwIog8IUE8w8gQA8w8gQc808UYU40sAQcQ0c0QEIwcQQcg04MQIQAIYoMgAI4k0kAI44AQAI8kQUAIsUkYAIs8oYAA4QsIAo0cYEAQAwcIAAEcAoAAEc8cAQ
UIIYAQUIogAQUII4AAEc8EAAUIsIgsAMAAgwoMAAgwcEAAQYoMAAEMkEAAssoMAA8UsMAAgMgEAA8AEYAA88YcAA4sM0IAogoEAIooAMEIg0AsEIEIsYIIA0
A8AIQUUwIgQ8swMgAMEwYgA4UwMgAQkwcoAwEwcgAo8wMAA8Uwgo04AQUY0ssQMY08MQU0w8IQcQw8oQAgw8oQI4w8IQMsgsocwMAogg4wAoEAkIAokEUsAA
4sQAAA44QUAAoEEIAIIY4QAIYwsYAAUIooAAUI04AAUckMAAEMwUAAEcsAAAEMs4AAAMwgAQAgYIYMcEAAA84MAAwUEMAA40oMAAEwcEAAgMUEAAIIQMAAYA
YEAAgkg0sIwc8AoIAsoMoIAMUEAIAQ0EkIYUkAoIs8cEMIMUk0AIAs8wAAIsswwgYkswAMYYkw0sIw0wEIYIkwEAA80wwgAskw0Ag88c4wg40c0gAg8II8Aw
cIAwgogU8ogo8cg4gswcgMgsYcAwAIYUswAMccwAA8Ac0YA8AsEEAMcsQAAMc00QAIYwUAAIYg0oAQAgwMAQAg4EAQwQAUAQwQEEAQAg40AQAgMAAQA4kMAQ
A4AkEQ4MAAUwkMAA0IkEAA0YsEAA8EEMAAEsgMAAY4IMAAEUgEAAcIMoEIYA00kIYk4UsIo4YIMIsEsEAIM80EMIQYA0MAAc0UkAA8MwsIQwkw8sAIEwoEAI
EwYkQAMw4IQk8w4gYwcwsMYwkwIMw8AQUg0cwQUE0ocYUw04QQUk0sIUAY08EU0A08MU0c08MU08AIIAccAIoYYsAI4QIMA4U0E0A4EY0UA4wQcIA408U4A4
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
]=]
local logoImage = make("ImageLabel", logo, {
    Name = "AccretionSprite",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Image = "",
    ImageRectSize = Vector2.new(96, 96),
    ImageRectOffset = Vector2.new(0, 0),
    ScaleType = Enum.ScaleType.Crop,
    Visible = false,
    ZIndex = 4,
})
local fallbackMark = make("Frame", logo, {
    Name = "SingularityFallback",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    ZIndex = 4,
})
local fallbackRing = make("Frame", fallbackMark, {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromScale(0.82, 0.30),
    Rotation = -28,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 4,
})
round(fallbackRing, 20)
outline(fallbackRing, C.accent, 0.15, 1.5)
local fallbackCore = make("Frame", fallbackMark, {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromScale(0.34, 0.34),
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    BorderSizePixel = 0,
    ZIndex = 5,
})
round(fallbackCore, 99)
outline(fallbackCore, C.secondary, 0.35, 1)

local function decodeBase64(encoded)
    local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local lookup = {}
    for index = 1, #alphabet do lookup[alphabet:sub(index, index)] = index - 1 end
    local clean = tostring(encoded):gsub("[^" .. alphabet .. "=]", "")
    local bytes = table.create(math.ceil(#clean / 4) * 3)
    for index = 1, #clean, 4 do
        local a = lookup[clean:sub(index, index)] or 0
        local b = lookup[clean:sub(index + 1, index + 1)] or 0
        local cChar, dChar = clean:sub(index + 2, index + 2), clean:sub(index + 3, index + 3)
        local c, d = lookup[cChar] or 0, lookup[dChar] or 0
        local first = a * 4 + math.floor(b / 16)
        local second = (b % 16) * 16 + math.floor(c / 4)
        local third = (c % 4) * 64 + d
        if cChar == "=" then
            bytes[#bytes + 1] = string.char(first)
        elseif dChar == "=" then
            bytes[#bytes + 1] = string.char(first, second)
        else
            bytes[#bytes + 1] = string.char(first, second, third)
        end
    end
    return table.concat(bytes)
end

local logoAsset = ""
pcall(function()
    local customAsset = pick(G.getcustomasset, G.getsynasset, getcustomasset, getsynasset)
    local writeFile = pick(G.writefile, writefile)
    if not customAsset or not writeFile then return end
    local path = "Noir_Blackhole_Sprite_Compact.jpg"
    writeFile(path, decodeBase64(BLACKHOLE_SPRITE_B64))
    local assetOk, asset = pcall(customAsset, path)
    if not assetOk then assetOk, asset = pcall(customAsset, "./" .. path) end
    if assetOk and type(asset) == "string" then logoAsset = asset end
end)
if logoAsset ~= "" then
    logoImage.Image = logoAsset
    logoImage.Visible = true
    fallbackMark.Visible = false
end

label(card, "NOIR HUB", UDim2.fromOffset(85, 43), UDim2.fromOffset(192, 31), 22, C.text, Enum.Font.GothamBold)
label(card, "EVENT HORIZON   •   03 MODULES", UDim2.fromOffset(87, 72), UDim2.fromOffset(220, 18), 9, C.secondary, Enum.Font.GothamMedium)

local statePill = make("Frame", card, {
    Name = "StatePill",
    Position = UDim2.fromOffset(298, 53),
    Size = UDim2.fromOffset(80, 25),
    BackgroundColor3 = C.accentDeep,
    BackgroundTransparency = 0.42,
    BorderSizePixel = 0,
    ZIndex = 3,
})
round(statePill, 12)
local statePillStroke = outline(statePill, C.accent, 0.78, 1)
local stateDot = make("Frame", statePill, {
    Name = "StateDot",
    Position = UDim2.fromOffset(9, 9),
    Size = UDim2.fromOffset(7, 7),
    BackgroundColor3 = C.accent,
    BorderSizePixel = 0,
    ZIndex = 4,
})
round(stateDot, 7)
local stateText = label(statePill, "BOOTING", UDim2.fromOffset(21, 0), UDim2.new(1, -25, 1, 0), 8, C.accent, Enum.Font.GothamBold)
stateText.ZIndex = 4

local headerLine = make("Frame", card, {
    Name = "HeaderDivider",
    Position = UDim2.fromOffset(24, 103),
    Size = UDim2.new(1, -48, 0, 1),
    BackgroundColor3 = C.edge,
    BackgroundTransparency = 0.65,
    BorderSizePixel = 0,
    ZIndex = 3,
})

-- Status ---------------------------------------------------------------------
label(card, "BOOT SEQUENCE  /  01—03", UDim2.fromOffset(24, 115), UDim2.fromOffset(220, 13), 9, C.muted, Enum.Font.GothamBold)
local statusTitle = label(card, "Preparing Noir Hub", UDim2.fromOffset(24, 130), UDim2.new(1, -48, 0, 24), 16, C.text, Enum.Font.GothamBold)
local statusDetail = label(card, "Connecting to the Noir source…", UDim2.fromOffset(24, 155), UDim2.new(1, -48, 0, 32), 11, C.secondary, Enum.Font.Gotham)
statusDetail.TextWrapped = true
statusDetail.TextYAlignment = Enum.TextYAlignment.Top
statusDetail.TextTruncate = Enum.TextTruncate.AtEnd

-- Three-part progress indicator ---------------------------------------------
local progressFills = {}
local progressLabels = {}
local segmentWidth = 122
local segmentGap = 8
for i = 1, 3 do
    local x = 24 + (i - 1) * (segmentWidth + segmentGap)
    local track = make("Frame", card, {
        Name = "ProgressTrack" .. tostring(i),
        Position = UDim2.fromOffset(x, 197),
        Size = UDim2.fromOffset(segmentWidth, 7),
        BackgroundColor3 = C.surface,
        BorderSizePixel = 0,
        ZIndex = 3,
    })
    round(track, 4)
    local fill = make("Frame", track, {
        Name = "ProgressFill" .. tostring(i),
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = C.accent,
        BorderSizePixel = 0,
        ZIndex = 4,
    })
    round(fill, 4)
    local fillGradient = Instance.new("UIGradient")
    fillGradient.Color = ColorSequence.new(C.accentDeep, C.accent)
    fillGradient.Parent = fill
    progressFills[i] = fill

    local partLabel = label(card, "PART 0" .. tostring(i), UDim2.fromOffset(x, 208), UDim2.fromOffset(segmentWidth, 15), 8, C.muted, Enum.Font.GothamBold)
    progressLabels[i] = partLabel
end

local footerLine = make("Frame", card, {
    Name = "FooterDivider",
    Position = UDim2.fromOffset(24, 243),
    Size = UDim2.new(1, -48, 0, 1),
    BackgroundColor3 = C.edge,
    BackgroundTransparency = 0.7,
    BorderSizePixel = 0,
    ZIndex = 3,
})
label(card, "EXECUTOR", UDim2.fromOffset(24, 253), UDim2.fromOffset(90, 12), 8, C.muted, Enum.Font.GothamBold)
local executorValue = label(card, "Unknown", UDim2.fromOffset(24, 267), UDim2.fromOffset(230, 18), 11, C.secondary, Enum.Font.GothamMedium)
executorValue.TextTruncate = Enum.TextTruncate.AtEnd
local footerMeta = label(card, "RAW  •  03 MODULES", UDim2.fromOffset(276, 262), UDim2.fromOffset(126, 17), 8, C.muted, Enum.Font.GothamBold, Enum.TextXAlignment.Right)

local retryButton = make("TextButton", card, {
    Name = "RetryButton",
    Position = UDim2.fromOffset(306, 258),
    Size = UDim2.fromOffset(96, 28),
    BackgroundColor3 = C.accentDeep,
    BackgroundTransparency = 0.08,
    BorderSizePixel = 0,
    AutoButtonColor = false,
    Text = "RETRY",
    TextColor3 = C.accent,
    TextSize = 10,
    Font = Enum.Font.GothamBold,
    Visible = false,
    ZIndex = 4,
})
round(retryButton, 9)
outline(retryButton, C.accent, 0.58, 1)

-- Intro animation ------------------------------------------------------------
overlay.BackgroundTransparency = 1
shell.Rotation = -1.1
shellScale.Scale = shellScale.Scale * 0.94
-- Keep the game fully covered during download/compile/run so the hub UI
-- cannot peek through before the loader reaches READY.
TweenService:Create(overlay, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
    BackgroundTransparency = 0,
}):Play()
TweenService:Create(shellScale, TweenInfo.new(0.50, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
    Scale = shellScale.Scale / 0.94,
}):Play()
TweenService:Create(shell, TweenInfo.new(0.42, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
    Rotation = 0,
}):Play()

local executorName = "Unknown"
pcall(function()
    local identify = pick(G.identifyexecutor, identifyexecutor)
    if identify then
        local result = identify()
        if result and tostring(result) ~= "" then executorName = tostring(result) end
    end
end)
executorValue.Text = executorName

local active = true
local busy = false
local attemptId = 0
local progressValue = 0
local glowTween = TweenService:Create(glow, TweenInfo.new(2.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
    BackgroundTransparency = 0.89,
})
glowTween:Play()
local logoFrameIndex = 0
task.spawn(function()
    while active and gui.Parent do
        if logoAsset ~= "" and logoImage.Parent then
            logoFrameIndex = (logoFrameIndex + 1) % 48
            logoImage.ImageRectOffset = Vector2.new((logoFrameIndex % 8) * 96, math.floor(logoFrameIndex / 8) * 96)
            task.wait(1 / 24) -- 48-frame optimized sheet, sampled at a smooth 24 Hz.
        else
            task.wait(.35)
        end
    end
end)
local pulseTween = TweenService:Create(
    stateDot,
    TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    { BackgroundTransparency = 0.45 }
)
pulseTween:Play()

local function setMode(mode)
    local color, pillColor, textValue
    if mode == "error" then
        color, pillColor, textValue = C.error, C.error, "FAILED"
        pcall(function() pulseTween:Cancel() end)
        stateDot.BackgroundTransparency = 0
    elseif mode == "success" then
        color, pillColor, textValue = C.accent, C.accent, "READY"
        pcall(function() pulseTween:Cancel() end)
        stateDot.BackgroundTransparency = 0
    else
        color, pillColor, textValue = C.accent, C.accent, "BOOTING"
        if pulseTween.PlaybackState ~= Enum.PlaybackState.Playing then pulseTween:Play() end
    end
    stateDot.BackgroundColor3 = color
    statePill.BackgroundColor3 = mode == "error" and Color3.fromRGB(58, 61, 69) or C.accentDeep
    statePillStroke.Color = pillColor
    stateText.TextColor3 = color
    stateText.Text = textValue
end

local function setProgress(value)
    progressValue = math.clamp(tonumber(value) or 0, 0, 1)
    for i = 1, 3 do
        local fillAmount = math.clamp(progressValue * 3 - (i - 1), 0, 1)
        TweenService:Create(progressFills[i], TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(fillAmount, 0, 1, 0),
        }):Play()
        progressLabels[i].TextColor3 = fillAmount > 0 and C.accent or C.muted
    end
end

local function setStatus(titleText, detailText, mode)
    statusTitle.Text = titleText
    statusDetail.Text = detailText
    if mode == "error" then
        statusTitle.TextColor3 = C.error
        statusDetail.TextColor3 = C.secondary
    elseif mode == "success" then
        statusTitle.TextColor3 = C.accent
        statusDetail.TextColor3 = C.secondary
    else
        statusTitle.TextColor3 = C.text
        statusDetail.TextColor3 = C.secondary
    end
    setMode(mode or "loading")
end

local function shorten(text, limit)
    text = tostring(text or "")
    text = text:gsub("[%c]+", " "):gsub("%s+", " ")
    if #text > limit then text = text:sub(1, limit - 1) .. "…" end
    return text
end

local function closeLoader()
    if not active then return end
    active = false
    attemptId = attemptId + 1
    if G[LOADER_LOCK_KEY] == loaderRecord then G[LOADER_LOCK_KEY] = nil end
    if viewportConnection then pcall(function() viewportConnection:Disconnect() end) end
    pcall(function() pulseTween:Cancel() end)
    pcall(function() glowTween:Cancel() end)
    pcall(function()
        local focus = logo.AbsolutePosition + logo.AbsoluteSize / 2
        if focus.X < 1 or focus.Y < 1 then focus = Vector2.new(Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize.X / 2 or 640, 360) end
        TweenService:Create(overlay, TweenInfo.new(0.48, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1,
        }):Play()
        TweenService:Create(shell, TweenInfo.new(0.48, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Position = UDim2.fromOffset(focus.X, focus.Y),
            Rotation = 4.5,
        }):Play()
        TweenService:Create(shellScale, TweenInfo.new(0.48, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Scale = math.max(0.06, shellScale.Scale * 0.06),
        }):Play()
        TweenService:Create(glow, TweenInfo.new(0.30, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1,
        }):Play()
        TweenService:Create(card, TweenInfo.new(0.34, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1,
        }):Play()
    end)
    task.delay(0.52, function()
        pcall(function() gui:Destroy() end)
    end)
end

local startLoading
local function clearStartingHubGuard()
    local hub = G[HUB_LOCK_KEY]
    if type(hub) == "table" and hub.state == "starting" then
        if hub.gui then pcall(function() hub.gui:Destroy() end) end
        G[HUB_LOCK_KEY] = nil
    end
end

local function fail(titleText, detailText, logText)
    busy = false
    loaderRecord.status = "failed"
    loaderRecord.startedAt = os.clock()
    retryButton.Visible = true
    footerMeta.Visible = false
    setStatus(titleText, shorten(detailText, 112), "error")
    if logText and type(warn) == "function" then pcall(warn, "[Noir Loader] " .. tostring(logText)) end
end

startLoading = function()
    if not active or busy then return end
    busy = true
    loaderRecord.status = "loading"
    loaderRecord.startedAt = os.clock()
    attemptId = attemptId + 1
    local myAttempt = attemptId
    retryButton.Visible = false
    footerMeta.Visible = true
    setProgress(0)

    -- Check every URL first, then fetch all three modules at the same time.
    for i, url in ipairs(RAW) do
        if type(url) ~= "string" or url == "" or string.find(url, "USER/REPO", 1, true) then
            fail("Source links missing", "Add the three GitHub raw links to the loader.", "RAW URL " .. tostring(i) .. " is not configured")
            return
        end
    end
    setStatus("Connecting to GitHub", "Fetching the three Noir modules in parallel…", "loading")

    task.spawn(function()
        local chunks = {}
        local completed = 0
        local finished = 0
        local failed = false

        for i, url in ipairs(RAW) do
            task.spawn(function()
                local fetchCallOk, body, fetchError = pcall(fetch, url)
                if not fetchCallOk then
                    fetchError = tostring(body)
                    body = nil
                end
                if not active or myAttempt ~= attemptId then return end

                local lower = type(body) == "string" and string.lower(body:sub(1, 512)) or ""
                if type(body) ~= "string" or #body < 32 or string.find(lower, "<html", 1, true) or string.find(lower, "404: not found", 1, true) then
                    if not failed then
                        failed = true
                        local reason = fetchError or "empty or invalid response"
                        fail("Download failed", "Module " .. tostring(i) .. " could not be fetched. Check its raw GitHub URL.", "Part " .. tostring(i) .. ": " .. tostring(reason))
                    end
                else
                    chunks[i] = body
                    completed = completed + 1
                    if not failed then
                        setProgress((completed / #RAW) * 0.72)
                        setStatus("Downloading modules", "Received " .. tostring(completed) .. " of " .. tostring(#RAW) .. " modules…", "loading")
                    end
                end
                finished = finished + 1
            end)
        end

        while finished < #RAW do
            if not active or myAttempt ~= attemptId then return end
            task.wait()
        end
        if not active or myAttempt ~= attemptId then return end
        if failed then return end

        loaderRecord.status = "compiling"
        setStatus("Compiling build", "Joining the three downloaded modules into one Noir chunk…", "loading")
        setProgress(0.84)
        if type(loadFn) ~= "function" then
            fail("Compiler unavailable", "This executor does not expose loadstring.", "loadstring/load is nil on " .. executorName)
            return
        end

        local source = table.concat(chunks, "\n")
        -- Drop the three fetched buffers before compilation; loadstring only needs the joined chunk.
        for i = 1, #RAW do chunks[i] = nil end
        chunks = nil
        local compileOk, runChunk, compileError = pcall(loadFn, source)
        source = nil
        if not compileOk or type(runChunk) ~= "function" then
            local detail = compileError or runChunk or "compiler returned no function or error"
            fail("Compile failed", shorten(detail, 112), "compile failed: " .. tostring(detail))
            return
        end

        if not active or myAttempt ~= attemptId then return end
        loaderRecord.status = "launching"
        loaderRecord.startedAt = os.clock()
        setStatus("Launching Noir", "Starting the Event Horizon hub in the current session…", "loading")
        setProgress(0.94)
        local runOk, runError = pcall(runChunk)
        runChunk = nil
        if not runOk then
            clearStartingHubGuard()
            fail("Startup failed", shorten(runError, 112), "runtime failed: " .. tostring(runError))
            return
        end

        local hubState = G[HUB_LOCK_KEY]
        if type(hubState) ~= "table" or hubState.state ~= "running" then
            clearStartingHubGuard()
            fail("Hub startup incomplete", "Noir did not finish starting. Check the downloaded files and retry.", "hub did not report running state")
            return
        end

        loaderRecord.status = "running"
        loaderRecord.startedAt = os.clock()
        busy = false
        setProgress(1)
        setStatus("Noir is ready", "The Event Horizon hub has started successfully.", "success")
        task.wait(0.42)
        closeLoader()
    end)
end

closeButton.Activated:Connect(closeLoader)
retryButton.Activated:Connect(startLoading)
closeButton.MouseEnter:Connect(function()
    TweenService:Create(closeButton, TweenInfo.new(0.12), { BackgroundColor3 = C.surfaceHover, TextColor3 = C.text }):Play()
end)
closeButton.MouseLeave:Connect(function()
    TweenService:Create(closeButton, TweenInfo.new(0.12), { BackgroundColor3 = C.surface, TextColor3 = C.secondary }):Play()
end)
retryButton.MouseEnter:Connect(function()
    TweenService:Create(retryButton, TweenInfo.new(0.12), { BackgroundColor3 = C.surfaceHover }):Play()
end)
retryButton.MouseLeave:Connect(function()
    TweenService:Create(retryButton, TweenInfo.new(0.12), { BackgroundColor3 = C.accentDeep }):Play()
end)

startLoading()
