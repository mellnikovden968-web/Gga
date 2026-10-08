--[[
    NOIR HUB  ·  Loader
    Executors (как ODH):
      Windows: Xeno, Solara, Madium, Real, SirHurt, Potassium, Volt
      Android: Delta, Codex, Arceus X
      iOS: Delta
      Mac: Opiumware, Macsploit

    1. Noir_Part1/2/3.lua должны лежать в репозитории Gga, ветка main
    2. Raw-ссылки уже прописаны в RAW
    3. Запускай только этот файл
]]

local RAW = {
    "https://raw.githubusercontent.com/mellnikovden968-web/Gga/refs/heads/main/Noir_Part1.lua",
    "https://raw.githubusercontent.com/mellnikovden968-web/Gga/refs/heads/main/Noir_Part2.lua",
    "https://raw.githubusercontent.com/mellnikovden968-web/Gga/refs/heads/main/Noir_Part3.lua",
}

local function env()
    local ok, g = pcall(function()
        if getgenv then return getgenv() end
    end)
    if ok and type(g) == "table" then return g end
    ok, g = pcall(function()
        if getfenv then return getfenv(0) end
    end)
    if ok and type(g) == "table" then return g end
    return _G
end

local G = env()
if type(G.getgenv) ~= "function" then
    G.getgenv = function() return G end
end

local function pick(...)
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        if type(v) == "function" then return v end
    end
end

G.loadstring = pick(G.loadstring, loadstring, G.load, load)
local ls = G.loadstring

local function reqFn()
    local syn = G.syn
    return pick(
        syn and syn.request,
        G.http_request,
        G.request,
        G.http and G.http.request,
        fluxus and fluxus.request,
        krnl and krnl.request,
        G.fluxus and G.fluxus.request
    )
end

local function httpget(url)
    local req = reqFn()
    if req then
        local ok, res = pcall(req, { Url = url, Method = "GET", Headers = { ["User-Agent"] = "Mozilla/5.0" } })
        if ok and type(res) == "table" then
            local body = res.Body or res.body or res.Source
            if type(body) == "string" and #body > 32 then return body end
        elseif ok and type(res) == "string" and #res > 32 then
            return res
        end
    end
    local ok, body = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and type(body) == "string" and #body > 32 then return body end
    ok, body = pcall(function()
        return game:HttpGetAsync(url)
    end)
    if ok and type(body) == "string" and #body > 32 then return body end
    return nil
end

G.httpget = G.httpget or httpget
if type(G.http) ~= "table" then G.http = {} end
if type(G.http.request) ~= "function" then G.http.request = reqFn() end
if type(G.request) ~= "function" then G.request = reqFn() end

local function hiddenGui()
    local fn = pick(G.gethui, G.gethiddenui, G.get_hidden_gui, G.GetHiddenUI)
    if fn then
        local ok, ui = pcall(fn)
        if ok and typeof(ui) == "Instance" then return ui end
    end
    local cg = game:GetService("CoreGui")
    if type(G.cloneref) == "function" then
        local ok, c = pcall(G.cloneref, cg)
        if ok and typeof(c) == "Instance" then return c end
    end
    return cg
end

G.gethui = G.gethui or hiddenGui

local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local parentGui = hiddenGui()

local C = {
    panel = Color3.fromRGB(13, 15, 18),
    accent = Color3.fromRGB(93, 168, 94),
    text = Color3.fromRGB(233, 235, 238),
    dim = Color3.fromRGB(124, 130, 138),
    border = Color3.fromRGB(120, 126, 134),
}

pcall(function()
    local old = parentGui:FindFirstChild("NoirHubLoader")
    if old then old:Destroy() end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "NoirHubLoader"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function()
    if G.syn and G.syn.protect_gui then G.syn.protect_gui(gui) end
end)
gui.Parent = parentGui

local dim = Instance.new("Frame")
dim.Size = UDim2.fromScale(1, 1)
dim.BackgroundColor3 = Color3.new(0, 0, 0)
dim.BackgroundTransparency = 0.45
dim.BorderSizePixel = 0
dim.Parent = gui

local card = Instance.new("Frame")
card.AnchorPoint = Vector2.new(0.5, 0.5)
card.Position = UDim2.fromScale(0.5, 0.5)
card.Size = UDim2.fromOffset(340, 168)
card.BackgroundColor3 = C.panel
card.BorderSizePixel = 0
card.Parent = gui
Instance.new("UICorner", card).CornerRadius = UDim.new(0, 18)
local st = Instance.new("UIStroke", card)
st.Color = C.border
st.Transparency = 0.5
st.Thickness = 1

local tick = Instance.new("Frame")
tick.Size = UDim2.fromOffset(3, 22)
tick.Position = UDim2.fromOffset(18, 20)
tick.BackgroundColor3 = C.accent
tick.BorderSizePixel = 0
tick.Parent = card
Instance.new("UICorner", tick).CornerRadius = UDim.new(0, 2)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(32, 16)
title.Size = UDim2.new(1, -48, 0, 28)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = C.text
title.Text = "NOIR HUB"
title.Parent = card

local execName = "unknown"
pcall(function()
    if identifyexecutor then
        execName = tostring(identifyexecutor())
    elseif G.identifyexecutor then
        execName = tostring(G.identifyexecutor())
    end
end)

local sub = Instance.new("TextLabel")
sub.BackgroundTransparency = 1
sub.Position = UDim2.fromOffset(32, 44)
sub.Size = UDim2.new(1, -48, 0, 20)
sub.Font = Enum.Font.Gotham
sub.TextSize = 13
sub.TextXAlignment = Enum.TextXAlignment.Left
sub.TextColor3 = C.dim
sub.Text = "Loading · " .. execName
sub.Parent = card

local barBg = Instance.new("Frame")
barBg.Position = UDim2.fromOffset(32, 88)
barBg.Size = UDim2.new(1, -64, 0, 8)
barBg.BackgroundColor3 = Color3.fromRGB(42, 45, 50)
barBg.BorderSizePixel = 0
barBg.Parent = card
Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

local bar = Instance.new("Frame")
bar.Size = UDim2.new(0.08, 0, 1, 0)
bar.BackgroundColor3 = C.accent
bar.BorderSizePixel = 0
bar.Parent = barBg
Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

local status = Instance.new("TextLabel")
status.BackgroundTransparency = 1
status.Position = UDim2.fromOffset(32, 110)
status.Size = UDim2.new(1, -48, 0, 36)
status.Font = Enum.Font.Gotham
status.TextSize = 12
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextColor3 = C.dim
status.TextWrapped = true
status.Text = "Connecting…"
status.Parent = card

local function setBar(a)
    pcall(function()
        TweenService:Create(bar, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { Size = UDim2.new(a, 0, 1, 0) }):Play()
    end)
end

task.spawn(function()
    local chunks = {}
    for i, url in ipairs(RAW) do
        if type(url) ~= "string" or string.find(url, "USER/REPO", 1, true) then
            status.Text = "Вставь raw-ссылки GitHub в RAW = { ... }"
            status.TextColor3 = Color3.fromRGB(220, 90, 90)
            return
        end
        status.Text = "Part " .. tostring(i) .. " / 3"
        setBar(i / 3 * 0.7)
        local body = httpget(url)
        if type(body) ~= "string" or #body < 32 or string.find(body, "<html", 1, true) then
            status.Text = "Не скачался Part " .. tostring(i) .. " (" .. execName .. ")"
            status.TextColor3 = Color3.fromRGB(220, 90, 90)
            return
        end
        chunks[i] = body
        task.wait()
    end
    status.Text = "Starting…"
    setBar(0.88)
    if type(ls) ~= "function" then
        status.Text = "Нет loadstring на " .. execName
        status.TextColor3 = Color3.fromRGB(220, 90, 90)
        return
    end
    local src = table.concat(chunks, "\n")
    local fn, err = ls(src)
    if type(fn) ~= "function" then
        status.Text = "Compile: " .. tostring(err)
        status.TextColor3 = Color3.fromRGB(220, 90, 90)
        return
    end
    local ran, runErr = pcall(fn)
    if not ran then
        status.Text = "Runtime: " .. tostring(runErr)
        status.TextColor3 = Color3.fromRGB(220, 90, 90)
        return
    end
    setBar(1)
    status.Text = "Ready"
    status.TextColor3 = C.accent
    task.wait(0.45)
    pcall(function() gui:Destroy() end)
end)
