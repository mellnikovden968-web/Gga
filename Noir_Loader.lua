--[[
    NOIR HUB  |  BOOT LOADER
    Executors (compatibility list, как ODH):
      Windows: Xeno, Solara, Madium, Real, SirHurt, Potassium, Volt
      Android: Delta, Codex, Arceus X
      iOS: Delta
      Mac: Opiumware, Macsploit

    Noir_Part1/2/3.lua должны быть в репозитории Gga, ветка main.
    Raw-ссылки уже подключены ниже. Запускай только этот файл.
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

-- Noir palette ---------------------------------------------------------------
local C = {
    backdrop = Color3.fromRGB(5, 8, 10),
    panelTop = Color3.fromRGB(25, 31, 36),
    panelBottom = Color3.fromRGB(15, 19, 23),
    surface = Color3.fromRGB(29, 36, 42),
    surfaceHover = Color3.fromRGB(37, 47, 52),
    edge = Color3.fromRGB(66, 78, 83),
    text = Color3.fromRGB(241, 244, 243),
    secondary = Color3.fromRGB(166, 177, 179),
    muted = Color3.fromRGB(105, 119, 123),
    accent = Color3.fromRGB(135, 226, 143),
    accentDeep = Color3.fromRGB(43, 94, 57),
    error = Color3.fromRGB(255, 112, 112),
    warning = Color3.fromRGB(250, 193, 103),
}

local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local parentGui = getGuiParent()

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
    shellScale.Scale = math.max(0.64, scale)
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
    Position = UDim2.fromOffset(386, 16),
    Size = UDim2.fromOffset(27, 27),
    BackgroundColor3 = C.surface,
    BackgroundTransparency = 0.12,
    BorderSizePixel = 0,
    AutoButtonColor = false,
    Text = "×",
    TextColor3 = C.secondary,
    TextSize = 20,
    Font = Enum.Font.Gotham,
    ZIndex = 5,
})
round(closeButton, 9)

local logo = make("Frame", card, {
    Name = "LogoMark",
    Position = UDim2.fromOffset(24, 42),
    Size = UDim2.fromOffset(48, 48),
    BackgroundColor3 = C.accentDeep,
    BorderSizePixel = 0,
    ZIndex = 3,
})
round(logo, 15)
outline(logo, C.accent, 0.66, 1)
label(logo, "N", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), 25, C.accent, Enum.Font.GothamBold, Enum.TextXAlignment.Center).ZIndex = 4

label(card, "NOIR HUB", UDim2.fromOffset(85, 43), UDim2.fromOffset(192, 31), 22, C.text, Enum.Font.GothamBold)
label(card, "SILENT AIM   •   V5", UDim2.fromOffset(87, 72), UDim2.fromOffset(205, 18), 10, C.secondary, Enum.Font.GothamMedium)

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
label(card, "BOOT SEQUENCE", UDim2.fromOffset(24, 115), UDim2.fromOffset(180, 13), 9, C.muted, Enum.Font.GothamBold)
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
shellScale.Scale = shellScale.Scale * 0.94
-- Keep the game fully covered during download/compile/run so the hub UI
-- cannot peek through before the loader reaches READY.
TweenService:Create(overlay, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
    BackgroundTransparency = 0,
}):Play()
TweenService:Create(shellScale, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Scale = shellScale.Scale / 0.94,
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
    statePill.BackgroundColor3 = mode == "error" and Color3.fromRGB(76, 34, 39) or C.accentDeep
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
    if viewportConnection then pcall(function() viewportConnection:Disconnect() end) end
    pcall(function() pulseTween:Cancel() end)
    pcall(function()
        TweenService:Create(overlay, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 }):Play()
        TweenService:Create(shellScale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = shellScale.Scale * 0.96 }):Play()
    end)
    task.delay(0.2, function()
        pcall(function() gui:Destroy() end)
    end)
end

local startLoading
local function fail(titleText, detailText, logText)
    busy = false
    retryButton.Visible = true
    footerMeta.Visible = false
    setStatus(titleText, shorten(detailText, 112), "error")
    if logText and type(warn) == "function" then pcall(warn, "[Noir Loader] " .. tostring(logText)) end
end

startLoading = function()
    if not active or busy then return end
    busy = true
    attemptId = attemptId + 1
    local myAttempt = attemptId
    retryButton.Visible = false
    footerMeta.Visible = true
    setProgress(0)
    setStatus("Preparing Noir Hub", "Connecting to the Noir source…", "loading")

    task.spawn(function()
        local chunks = {}
        for i, url in ipairs(RAW) do
            if not active or myAttempt ~= attemptId then return end
            if type(url) ~= "string" or url == "" or string.find(url, "USER/REPO", 1, true) then
                fail("Source links missing", "Add the three GitHub raw links to the loader.", "RAW URLs are not configured")
                return
            end

            setStatus("Downloading module " .. tostring(i) .. " / 3", "Fetching Noir_Part" .. tostring(i) .. ".lua…", "loading")
            local body, fetchError = fetch(url)
            if not active or myAttempt ~= attemptId then return end
            local lower = type(body) == "string" and string.lower(body:sub(1, 512)) or ""
            if type(body) ~= "string" or #body < 32 or string.find(lower, "<html", 1, true) or string.find(lower, "404: not found", 1, true) then
                local reason = fetchError or "empty or invalid response"
                fail("Download failed", "Module " .. tostring(i) .. " could not be fetched. Check its raw GitHub URL.", "Part " .. tostring(i) .. ": " .. tostring(reason))
                return
            end

            chunks[i] = body
            setProgress((i / 3) * 0.72)
            task.wait(0.12)
        end

        if not active or myAttempt ~= attemptId then return end
        setStatus("Compiling build", "Joining the three modules into one Noir chunk…", "loading")
        setProgress(0.84)
        if type(loadFn) ~= "function" then
            fail("Compiler unavailable", "This executor does not expose loadstring.", "loadstring/load is nil on " .. executorName)
            return
        end

        local source = table.concat(chunks, "\n")
        local compileOk, runChunk, compileError = pcall(loadFn, source)
        if not compileOk or type(runChunk) ~= "function" then
            local detail = compileError or runChunk or "compiler returned no function or error"
            fail("Compile failed", shorten(detail, 112), "compile failed: " .. tostring(detail))
            return
        end

        if not active or myAttempt ~= attemptId then return end
        setStatus("Launching Noir", "Starting the hub in the current session…", "loading")
        setProgress(0.94)
        local runOk, runError = pcall(runChunk)
        if not runOk then
            fail("Startup failed", shorten(runError, 112), "runtime failed: " .. tostring(runError))
            return
        end

        busy = false
        setProgress(1)
        setStatus("Noir is ready", "The hub has started successfully.", "success")
        task.wait(0.75)
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
