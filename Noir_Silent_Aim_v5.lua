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
        local encoded = "/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAcFBQYFBAcGBgYIBwcICxILCwoKCxYPEA0SGhYbGhkWGRgcICgiHB4mHhgZIzAkJiorLS4tGyIyNTEsNSgsLSz/2wBDAQcICAsJCxULCxUsHRkdLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCz/wAARCAEAAQADASIAAhEBAxEB/8QAHAAAAQUBAQEAAAAAAAAAAAAAAAMEBQYHAgEI/8QAQRAAAgEDAgQEBAMGAwcEAwAAAQIDAAQRBSEGEjFBBxNRYSIycYEUI5EVQlKhscEzYvAIFiRygtHhNFOSskPC8f/EABUBAQEAAAAAAAAAAAAAAAAAAAAB/8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAAwDAQACEQMRAD8A+baKKKAooooCiiigKKKKAoooxmgKK9xXSoTQcYr0LmlRHgnIrvywgYtsQcYoG/LXvLTpIQQS2FHLkE7ZpIJjqRQJBc0chzSwUFhgbbZp00UYllQb8pwDQR5U15ipmfSJYh8Q3PpTF7RkGWGM9KBnRS5hpMpg0HFFBGKKAooooCiiigKKKKAooooCiiigKKKKAooxRQFFFehSe1B53rpVya95CDg7UtFESwJ6etBzHHntUjDYDlWRs8uM7DJrm0tUMg8yQADqAd8VL3mpWVugj0uRpGZOVgYznvmgibqKJLeVubGwCqMEknff02qNaUtkDYE5x2zSs07syq7tyx5wh2xk7ikwiySErhQTnGcBfuaBSGNppAqhpHPQCnLJGnKhdHc9Qoyo9s9z79K9D2kEYXe4fGdvhiB+mMt/IV1bWzyklC0rN+6kJYYJ/l+lAk8katguuD1WJc5+p6V4JFz+X0923qSfT7VIgksjedjeOKIkge+cb03ljs+UhEdOX/3FIP8ALagVm1tWGEtkhx2yWLfVjuf5ClLCyuNRjFw6t5OWRTjAJC5P6bVESIhdfLZifU7VY9Bjv74x20EE1/FbgtywTLEEG+TuM4x3/wC9BH3OmtEW2IxjH60xltmjkww7VoPnWl9qcWl2Nmed1VpWZW5lbO4JbfbFR2saC5tbm4j5eSEhWOe4G9BRJE5T0pIipK5g5MZIyd8UhcWjwFVdSrEc2DQM6K9Yb15QHavQd687Ggdd6Dr9f0rwj60c31oJ+tB5RRRQFFFFAAUoApGNwf5V4p2xsfrSkaLn4/l9B1oOZccwx6CvIk55VX1NOprZoUUt8UTjKuOlcvbNbsrbMh3SRd1bHpQcS2728mD16g+o9a8EJZeZR9R6VL2kIeaG3uo18qVsrIBuFbuD6A7/AK1OaLwhe3GtyWvkvyoxRyR0HTegqcFo8rBVXmzVw4c4NubxhLcQ8lqdmZ/h/TPertp/D+g8PhjKFurhBlsjKqcZwB3NQcnEKQcSC5uGN4sZJSLsvpv0UD6E0E7B4e2EFoWMEFzIFJL3WREg9cDc/rWU8S6O2j6oy8wCSMTGAOQsufmCblVPbO5re47y+1IaZHawwpNeRvIPM5jGmFGQQNz19vrWRcarpml61qSXTDVtTmLI7cxUW7gsM7d9hhenqT3CiPudlxtvSkcSMpLSBcddtq7e3KXTQjfqNj7ZrmGdraQNHguBsSM8p9vf3oOn86FgsilS2G3HxY7Uss9wjD/i5fiGR8bU2YcxaTmZj1JPUmgOUxJnJYlT7igfR6ld2smfPkPN8zB2+L9D9f1rs3EmC6Sycg7q5P8AI1HSA4x0A3HqK6TkMYyCWBxn0FA8a5iYszhUmKlccuAQRjt0PemtrPcW0yvC7IyuCCp6sDkfzrgRu7lQAfUnt96eyQrp1ouZFeZzkqOifD0II3O/0FBsfhh+DuFvZNaZf2tdXA54plHOGIyCAfiGdzk7E1Y9Z4XseINOns7Z/IFs4B5RtuoI2+/esU4W1W7s9btNT8yC7umcIn4iZ0KsSdyw2A36n+LtW48HajZXtrdai+mmyu3WP8S3PzrKzIDlTk5GAD2oMx1Tge7026kuru1JggHPyjo+/wAKj6nGfbNUnU7a9kuJJbmOUyNuSUNfT9mlnc6MzyXn7ThkclGdRsM9Pfesc4s0y01XWLldE1CWSRSSYXdgWPflz1+lBljxNv8AA23saT5Tk+1SF7b3FtK8chkVgdwSetMiDkk5NAlRXfJmuhESM0CWKKVKYGaTIoPKKKKAooooClFOKTpRVJ6dqCfvYo5tOsxbzIAYz+Wx+Y5G31/7UytHby5bKTmETnmCkfI46H+xpqkTsVjOSp3H371ctC0WK3tY73UoxJGQTDHnBkI7k9kHc/YUE/wTwvDqGkSR6rH5cMbedBNkBunxAeo6H61aLzjzR9IkCQwPLiRVlYgLjPf3NV3SruPUbz8TqcoW1igdYoLc4LAbHp8qDI37+9U7iK9jub2aMRcg6KB0T1AP72/egn/EO/urO/TU9ENxFb3C5eX5sdNu+F6f0qoaRrMdrewSajGZ4ywBXr8Pr9Qe1TXC1zd6xp8mkTJm1jcM9w7f4KgjYZ2yegH37VTr2K3GoXItSwtkciPnOWIBwKD6I4cS14s4cs52t9RspYmbyxEPJlGCM8rk/CpGBzZ6VVeMeDYRJqt9LbW+nWWn2Cyw2kK87LzM4DMcYZiynJbJ3696ifCPivU7TVoNMmSe706R/LXlXn8p2wFz3CevYZrWeJNBTU04kkuo1ZoNHSWJsA+Wfzxt/r37UHy88ckd0zFGQDs4wQCNs++KQjUM2GJC9W5ewrVPFjgxdHveWyaJLe3h8+blTlUczBI0BJJkfbc9ub61lSq0jiNRkk4AA60HUpIOAww25AP9a6jcJGQAC3XJHTak5InjcqylSOoPUV0sZxkkKvqe/wBqAIeQhjk8xxk9zS3KIUCsRlhuO4ruG6jgccsRdAxIUnBI+tJv+a/mugRG3CJ/o/qaD2Myo6+SMc5yjOcYx3Gdh9a5SGe5leONTK2eZiN/bP03rmZSqoGOCB0z0/7VbPD/AIal1vWLeRYHuoopR58CzCMyLgnlBIO5waC08PcPizbhS7iLOkmoxQzLNF5bxy4JZCP31HL1ONz3HTQzALa3e1hIi/DW0KHYA/KDuamuKLBrzUuD45YpLfy9WVuSRQCAsEjAAjZhlR39KpfiTxTbcNT63EHH7QnaD8Kg3O0Yyx/hH6ZoHAuryDho2NgZA6IxQRr8R3zgH7/zrLzGsCNq1ywCySvGiJJhi/qc5wAf6UlwDxNqNhdX1naxPe3N3C3kRM53kCnp746D2qrSzSJEkTE7Esc9cnqaCy2ctjqySHUXZbmVxyznJC+gYdwfXrTLUuGbqxmdpk/LB+EqRh89Me1R2lRvc3RHMERBzOx6AD+/tWgaHq9jewLptxbn8OBlGkb4ozjv7ZoM+axkjh8x0xzHApS0tPNk5SMgjtWg6pw5JHax/lfMzMBnI32BqPj0YadbSz3PLHKFPIh77d6ClXkCROVByBtUc4AqQv5GeQ/2qNZsmg5ooooCiiig9FLRowwR0O2aRAqc4dt/xWoLbtCZo5BhlBxj3HuKCwcI6XZXozqOY1jJeMgfPgZZc/Tf9aa6jq4uZJ2uZCFAwgQABsbBPZQP9b06tVvl1Oyt7IN5UVyEiOP3ubB5vf1+9Icdx2E2qGXTY1jhiJgZV6EgnDff+1A54Pu7f9vQtd6hbw2rfDOrqcyIRuo9AOg9Kj9R0uVNSjsFWWS5MpRWOPLdP3GU9fXPbH3qAhjkLfCpY4zgDJrUOA4ZIbBLq/RHW5XCtO+0UPQtv05jt9AetAwvFTRuGP2bZ3QVbjC+aEBMkjfvKc9+nsM1HweHi3zRRNqfl3g3vA+4Vsjmx68ucH3Ne8X8XwJqs1jZWdncLbhkhu+U8yFsZ5R026A79M1oXBusRa9odnbJqFvJdxcr3EcihnkU9R1HxEfzB2oH3hhwDpuia7NdWt3JOz2vMrS/CygyEEY22PKN+/0rQtZjRLLicuFQDSEBP3m603065ih44ZGCKv7Mj5Qq4H+K4/tUVqGq+bwZx9qc86BQ11ZxlmAC+W7Kq/U8wwO9A940t+Hb3X5bfVZ7VSNKAiVyrNzec5wqnODtgnGcGvl7iGwh0a5jSxmcu8KO+AAykqObOCSoycAHB23A2q/cdcccNx8SyXmhaRC0txbqvnspgRQGb4ljXBJb1bc7HbOKyu81K5uncSTcwZVTCgKuB0AAwBQcwXn4QExxq0xyOdxkLkY2HTPvSDkkAsSWxgA9h2r1MxS8/wAOV3HMMj9K85zI7O55mO5z3oO1nZDlQoHXGM10byVmZmPNI3738P0HakOYtsTt6V0pAIAAyO/WgeWluk91Das/JJI4DMVLcp7DA3O/9a+g/B/Q5tF1W9ttQ0qa3uNOUhzEnMJGVcdOoPxZ6ZyaxPhKeLROJbe5vbSK5S2niklWQbAK4c79sgda+pNB1zStbtJ9X0yWGTzjzTgvh1blX4HI6NsfbbuM0D3XruG6uOGropJDGuocxWeMxuP+Gmx8J37187eKum3Gp+IOsX1vaNcRi3jkOWCsnwhc8vU4wdv1rd7931TUdOa8jWSO1nWSNgwb4vLkGSBup6e29Z7qOsJD4j6lHdwoqSRrBazmIAOxUFlJ7np6DY96DGI3OhzWU8HPDqUb+ejk5KAgFAR2bYt9GGanuN9Pg1C3suLdOjCWmr834iNelvdL/iR+wPzD2NLcd8NyWmqTX9sjyWt0xdiy7q3Xc++aZ8H6rBGt7w1qjhdN1gKnmMfhtrgH8qb2wdm/yk+lBV3kYBYYvkB29WPqf9bVP6DqEduhknDNOjqE3wMb5Bx9qgtQsp9P1Geyu0aGeCRo5UYbqwOCKTgflflRixboMY3oPo/Q7yz4q0hC8ar5WzKnfH9KoXiWJINRaNB+UAMKO1J+H3E0OkajNHNPm3CKvTA5j1/pVl470231Cx/aEUoZG/8AbHNg4zj79R96oxCR8z7+/wDSmJPtT28iAnfBJA6kjFMiKg8ooooCgUV0BQeqKmNN1SXTIibcp5sm3Py5ZP8A+0zs7b8RMi9j1+nepCx06a+uLiSGLmWIcxQfXYD3oH2patBYJazaNNLBKY1E8bbjmA6/XOTn9KmeGNH0HXrFIZNYe2unIjMTKu7nccuTvkD+XrVOWWIXAFxEWjU4dWJBG+4z26VceMNK0+LhrT9S0KxcLdOZ1kVfjgVVy65XbY75ztQSOq8EaNoSW0kmvyRCIs3OIlD4yM4xuwx9cfSrdf8AB37ajZJdTeKzyHVYIQuQBy4O+2w2GMdTtVA4P4kt9P0KWLWbUTWxfDTJHzyqOULytkdCCBkHIB79lrHxE0u1vVSWyuUtXn8xkSXPkFV5VZOmSepB2Hag51/gTSo9ak0vTr6b9qeT56RyhRGRt8JbrkjLfbFOeF7zTuG9Mk1GIl7m1kJlEY+FlzsMttk46DO4qv8AEXFset8VNezjyoAxi82DPO0O4woJwDg49Kl9G4y4SW3VNR0Rke1PLayIvmuEG6k5IHNzbnAxQTmo+Ilx/vN+0NWWXTbd7FUS1gk/MdOYsivynO+cndOvfvSbvjvV7vhy70dZltdMurh7iaKKMZkZ2DFc/urkDYY6b5qN4p1a11bV57mztPwqu5ZuZuZnPqe36VEAhomMkjZX5VAoC5kE1wzI0jINl8xuZgOwJriIfHz4yE3NcocHfaus8qkAY+9BLahpzyRRvaxmSFiwhYLgso3wR/EBj7VC4q9cD8mo2b2sjBXtHEodz8KJ3J9AN8ntUNxDbaXeajd3Ogrcmzh5eZ5gPiY9cY984z1AztQQIKkYwR71cfDrgq74s10SFFi06zIlup5UzHGg3OfXYHbvURw3Y6U+r2g125mtbWWQLzJDzgb/ADNv0z6Zrd/EnUtJ4H8NrbQ9FKrbaicc8bfE8QALtnuX2X6MfSgxRdSli4svdTt0SYXC3DiO5jD8yOGALLsM4OR0AwPap3gnxBk4etpA2lwXFocRzeWvLKAQccrDcZ39RnPTJql2l+X1aS5uIVuPNSQGM5x8SMBsOwJB+1IQyfhfxK8+H5eQcvQ/EM0H1BwnxBY8Qv51rqsd4HiUraiHypbfB5W2yebZh03G/qKzK/03TNY4uuLmW6ubPzZf8EIAEblAJOeh7nbrVa8OdVjsdduZps+W8BD46/OpOPsKW0XjyKOWVtb01NWE0YQSlys0OFABDd/oc0GqXejW1/pjwz6pcyR4MTKYU+IgDBDNsM5Az6mqRqPBPB1vrCaYNeuBfzuEW35VGCSMBiFODg9O5py2rwanwte2GnXyXlvLGxNvdlYZidjtvy5B3ypPTYb1VeF9QtdE4jfiHiDnkk+IokRDmSQkAsfTbJ69aC63fhFY314JLjVtSmkMQJd1QsQMAAnG5x/br2Y3fg5Y25QwajeMCSGZlUFRjbAA3zU9D4wcNCJkaTUuQEHJtgWx3BOemMe/WurPxQ0PVpk0zSrW9lu5fggieLC5x3OScDqT6UFTtuA9NtbKST8deJJhSwfkHJ1O5GR096m+H7SysYiPxk95p8sXOxkChFAwRnoc9CP9Zktdkmjs2Mai6kK7DZeb29MHpj++9UDiPW7q11JLCOUhIyHmTIOHIzyEjYgb/r7UETxVpTadqM0JAZI2/LIGzBtw36VV+Qk47ntWv6po/wC2+D7DUYwCyR+WfULnYH6bj6YrObbTmuLiR4xzoHMUZXfmI6kUEKUwa5KEdamb6xjtZDG7DzB8wG+Ki5Rg0DcUrGuWFJDrTq2Qs4wKCc0q3xbTS9CFIB+29Wzh+y/B6PGdxLOfNbO30H6Y/WqTDqMlvbywFfhYYGeo9as2n8VWV75C388tk8L8w8s/lNtjB9vrQMeI+Gl/CtqNmpUgs8yZJ6nJI+lOPDDV4bHiP8Ld8phuVMaLIcqpO2QDtnt7gmrKLO21C0lRX82GSI8jZzt+u/8AL0rNtS0i80XUDHIuZISJOUZxy9Q4/wAv9MGg2PifS7XT7WW4t7WD9m3BUXsQXby91ZkAweZBhvbBrFdY0w6TqtxZlxKI2/LlQ5WROqsD6EYNbdwxe2vEWgXF+4Ek7Wzedbr8XnKoO4XswGxA67HfIrNOL9Ikh8sQQzRw28KzW0cq/mR27Ekq3ujnG++GoKaX5lAPbpS/koBEDKBzrnOPlPoatFvwkvEmmjU9CCRNFypd20sgBic7B1J+aNiOvVDsdt6g9T0u40zVrmwvLeW0uIjvBMPiRuvKf+/fb1oGMvmRScrKA3Zuufp2rgg9T0Yda7ChivL8O+NzsDSsqBVAIIcjOc4G/agakHpintrpdxPZtd45LdJBEXbYFsFiB9AP5j1qb0rhNbrRZdY1C7jtLNGEcS8wM1zIeiRp1P8AzHYe/SrPx5wZqfDHBWjm9gECzTOyQxtlYgd9+5YgDc77dqDPdOS9czpZrKRJEyy8i5Pl5BOcdumaluEdCm4k4mh0GGVreK6lHnOzYWONcszt2wq5P2qR8K9WbSfEnh+QSmJZbj8NKcAjkkPIcg7EfF0PpU1r2v6TpFjrVvp2nNp/Et9I2nX8Ue8EUaN+Y0PdfNIAK52AONmoKdxDw3caFxheaI4eaSCYxoUHMZR+4Vx15gVI+tecUprVhdw6LrUrGbTE8sQs4cwc2GKEjuMjbt07VpnB/Ef7R1Ph1JNLlttXtoDbahqkikctjCC45M9JGjUoX64AAxnNZZqeovreo6vqtwB511MZznqCzk4H60DGMyWt2wjkZGAZSy7HBBB/kSKT8su/wZZmPQDOaneFeEtR4v1Brewe3iIwC88vIMnoAOpOx2APStW1/wAErjhngu4vLC9ikdUMl5cSriQRAbqi5OAemOp7kDagyHQ2CXEvvCf6iouJ8LjOPenVhMIrpjglSpHXG1NVjUtuxC+wyT9KBa0/EXF3HFZo7TMfhC9fr7VZbnTLG0tI3k1C3ur6VMu4/wACNj0Vcf4j++yj/NUF5T/gpGVfIhUAEKCzOf8AMeg+n8jTeeNrUxnzH8/HMwwRyen1oCUhbhomi8hgeVskkqe9aP4W6CfKuL5onaW65reORGKGOL991OMZJwBuNs1mlvC91cRQhgpc8oJ6D1JrauFLCG9hW81AY0+KOOK0slfy0QKcBnIOWY8xIz0ye5FBK8V6na8O8OTXbxAFGEdtEVwGbGV6dh/Raw5LqV7kyOQ7yNzMzjPMT1J/Wp7xA4g/bWvtBDLI9paEogaTny+wcjG2MjAxttnvVYdxbqoRszHOfRfbfv8A0oL+vEd62kx8LaUy3NzqirCpBI8oMd8Dtkdfual9ZsLXhXRrfTbZxNdxxEZH7vTLfc1U+DQuh2TcQSTQwXsrm3smuDhB/HIR1IA229SKkNae1W6muLG+fUGmfmmvPLKiVu+CdsDOABsAKCl3bN5zZ653zTF29etSV4qgs5zv61Fucmg5HWpDT4+eUL61HjrT6zd0dTGAWByKC2PpUN7HBE+FLty8w6jYn+1V3XNBm0WVOeeF1k3TlbDEepXrSkutahDcxSc3ltAeZVxt9/Wktb4jutb8tZ4oUSL5VRdwT13O/wBqDzQ9dutGu45Azvak/mRZ2YHY49D71oevR2PGPCgv9EVnv7ZspGoxNvsy47jv+tZXDLJCwdO2dmGQR3yD1pf8Y0E63Fi72jghsRsRyEdCDnP69KCxcA8RTaHrixfGVlPwqGC4k6Drtv8AKc+o9Ku/FuqNfKl35CfirGRnNuyYDc2BIjegIJP2zWT3d3LqF297Jy+e555GX4eZv4sevriruuv/AO8egwzTvi+tQIpm6mXbCnHv3980EFwbZT6jxdaadGt0LeWUvIsH+IqLksV2O4A7gg43rbOL/CF9a0qO3/H8+t2MTfg3KnmngX5Y2PfGRy5+IfEu4AxVvAqyS48QjdRJzwWMMkksxPViMKo9tyfflB7VvazxNcuMpIqkkuWPMrEH5ffB60HxRNBL+LkhmTy5kJDhvhwR1zXDspkwjFgoyzMMAfQVtXj9wnDbNbcT2KxBrkeRenHV+okA7E5IP0HrWGqhkkWOIF2YgAY3JPag2LwP4KbiHXoOIr5FbS9OkPKrnPNKoUpn1+Ig/wDTVz/2hrmOHhm3idhzIDHFkElmYrzH9N6tfAejx8K8G6HpXliO4EPnz5XGZH3Of8wGB7VjX+0NxImo8ZxaLCGC6YuJCTkM7AMf0yRQZZYXK2erW87B2WGVXwjlG2IOzDofetHuvGnULTWb2fQ9E0vTIp53keSKHmnlyeryvk5PX4eWmPhz4S6lxxL+LuHbTtKjflkuWALMcZ5UUnJOPtX0Tw34V8E8P20UlvoyXl0hJ/EXoEjk+uOgHcDG1B8+6p4ncYatpshvbG2FtOp/MnWU84wRsXf4u/QGs28wnnGAOc7gDAr7C4p8NdB4iS7/ABF1PbTSr8DwkA5xj42OWcZ/d5gK+efEHw1u+CIonjkjv7KQ/wDq1OG5vTk6qPffPqOlBoX+zvpejpBqWpR5uNXUcsZZcCGPoe+AWJ6Zzhe3e1+I3G9vw/olyst1BdXd5GYLayiHPls7u4OfhH8JG59s4xbw74f4s17T7tNFlS0sOYJPLIcCTZm5MfvDIGQPUZ2prxzp1/wxxOz6gI76Wf8AMhlukLcy+vIfhG/Yj7AYoH3DPhZxbxfJ+MitLaGEsS89zOoAPpyAlh+netL4c/2dtLsis3EGrvfXHMGMVsnLF1+U825yfp9Kl/CjxBPEmnCygtWiTToQZpTGiKzsSAqqgAUDBO4OaQ8UuN9V4S0JL60ulWa5lNvCgjwVIHM785yT2AAAG/Wgtt/4Y8EXaQSXehwvFaqFRfMaONQP8qkKPfbfvXS+HnBZsmi/3S01Y5FHMBH8XsObr/OvmqHWOMPERV02Gae8nMryzyFiEjQqoy7E4Vev9q17g2wPCmm2+kQ3lzfTXEnPLKxJ+PpyoMnlX+Zzv6AEOP8AwY4ci0S81vRI5bWe3QyGATgRSAdQOYHlb2zg9NiayV+LpbTh+WGBis1wDGu+65AyfqMbVufiPxhaaHwhqcCz27XeBbvCjgkM/MFBAO3ysxJ/hAGcnHy3kT3CIz8iEheY9h60HCyFThRkHaul5EUliCewFA5mZkjOEz1O23uaXihHmxpaAz3B3Pw7KR6Z6/egf2mn3E8lq93G7idgkMbk9Dg82PQjO1al4jRBdP02ZY/LD2y/AFwBgY2FZrpseralqKCGXypYGHmXL4+A7jb3xnatW1zhqLTuGbYeZPdXLpmSa4kLO5ODk5Ow9ANhQY1fAuxOce1Nfwb+V5pGEPc96tSaVZWTNeaw7CHcxwJ88x9vRfUn7VAavqz6hN8iQwrskSDZR/egiR1qQ07H4qNT3OKjh1p7p5xdxH0YUFtbT7aa18+VUfy1IwzhRvjuemKQveBgumyXkN4nMqF1j+YMBvs1OII1uIJLdZXjBzzFQCSKj9b0uaxsw1ndS/hJc80ZOACO3pvnp9aCrA4yK6jBEg2Dd+U96XmukuBEHt40ZAQzpsX9z2z9qLWze6vkgjZcMfnb5VA6k+woO7u1jMX4qy52t8gOrbtEx/dPqPQ9/rXFlcvbSHkbl80cjH0Bp/ZafcwveSvE0f4UcssbbK2T8rZ7d/0x60rw9oM3E3E+l6Vp0eGu5liLfwnOWY57AZP0FB9AeGGiQ8M+Hk2olJQdUYOQ4wxRcgNgdM9h6VYtPvbd7ExQvHEUUrGc/wCI3KzcgB6thWP0FQfEnEcGXhgKeQjeXb47RIAB9Obc7VnvG3FN7w4/DkgbMpkOoOmd2A/LB33B5VIH1ag0riaCx4p4fk0QuplkDci9MtjIUbYBO2/YgVhnhlw+l74o2lvfDEGnO91OHGByxZbf03A/pWpXUjWt1BeWsiNZ3sYukIfJcE5OD2O+PapG4t9O0e61nXbTkiutZEcU0K/NG6EmVv8AlY8p27lqCxWOvyX/ABPFJKWESOxlBzyhQCeo+hH6ViGgaKniH4r6zqupGT9nwXEl1cFdjy8xCLntnAA7nf0JFpvNYl0PgLW79JAskqCBDjcvI3Y9RgK1WLgPh2Dhnw+0z8XmGa7/AOPuSw3ZmUiNT32Tt/m+tBcbGSOy0+OG2iit3iQrFAhAWNWx19ydyepPvWP+JvjDfh4dM4avHt7eSMvcTo3xSEsQVB7L8J6dc154uce3ens3D+nSeRLcxLLfOh3XO6RqewC4JxjdvasZJlunijVWdwBGqqMk77AD70G9+EPHOq8UW2qaVqtyXSyhFxBKQSUXmC8jHOSPiGMntUn4r3Fvf+E92kk2ZbSaJ4mYD4jnBGfUgnH6VDcG6HLwPwK7XHlrqmsMHcbEwxJkqp9y3p/DUfxYTqNloPCvM5m1W/TzuXdljB5QR/8AJj9qC5eGNnHw74baUs0RjkvWa4nbHxEP8v25VH/msu8aL+e84zFmoURwRrEqKedy27EE9dmcqB7dK1hbuPU+IRbQbWlrJyRKCcKF+XPoMLWE8VXacQeJt0YmZ4pLvyVZOrfFgke5Ykj60GzcDaYnCPh5p0fPGLrVF8+4cHm5Rk8ox322z0znB70hxRpGj8WX1ne6tdyTWljCUis4Th5ZHJZ2Zuir8uw3OO1e6tOt7rH4eH4Y41FqsSjPkqqhQPTAA/lT63ttOuLeZdLkivJbKQrcBLgM6lSRkr0O4+lAlcNpujaLZww/htD089ZC+Oc8ufhHV2wcZ/pVK13xRjtuHJU4bWW0c3XlrdEgzOvKCW7hMnsMk9yKnOI+GtO4h5bXXRNaXakpFfQ5Zge/PGThhnHTBHvWdcUeHOucPWBkg5NU0wN5oubXLADGMsnVfr0oIBr6e90PVJbiZpZri8hld3OSx5ZcnP3qKCsUL42BwT9a6WZltXgwOV3VyfcAgf8A2NJ7k0DmztJL2YRQqCwBZi7BUUepJ6VM2KzPaNDZSeVAx5ZrrHKX9lHUDp7nv6VGwOtvGsdzzeTIRzopxkZzv3x3x3qzpxDosaokalEVQi8qE4HvnAHegl+HuTTrqS2NrFPzYRTKTlCAd9uv32NahxPNC3DtvJOeV3TKlht96gPDzSLfVdJN88P/AAvOzq2c87ZxgfYYONs058R2BjiimlW3hSInmJIA3OBt1PTagxTXpJ5b6VpG79zUI5HQb+9P75mlkIMyFFOBlt6YOANgc0CY608tVPmqR2OaaDrTm3+celBYpmlgLSR5TIB5iM/pUxpsto1nPdzxR3DQwliZjkjboOwz7Cmk8PPoMM4PyAAgd+1Qr6hJb2M9qp5VmHK+RnagR03TY9ZnuSrC3YYZV2CLk4GSe2cCu9OdbGOe0nhTzrllU+cuAqdSQT74Pphe+aj4ZYkmVHLLbsw8zBOSM7081nVTqUhjhjVLOE4gQoAyr2ye5oJd7ma4057GztVkhcrIJ2hPLOykjB9AASR/PrtdvB2xSGPiDXeTy7WFDbxyKPlJGWZT2PID9OZfWsqhuJ7iNbJmLoxHLkZC47+23X2+gr6A4L0ebT/CPTrCblMup3UlxIi7gQqeULt/EUJJ7+9BCslzdTuyKVWR1yij5DjPKAf4QQKy7j/V11jjO9kgfmtbci1t/QRxjlGPrgn71q/EuqPwxwxeaqg8qfUeeK3RwCUUbFvT5mAHfGawTfGaDV/C+8j13RZ+H5pSb6zL3ViGbAZcfmJ/+w+hqav1vTJHZiJhzAMXOcA7jp0wdqyHhzWbjh3iKx1W2cpJazLICBnYHf8Almvp+1S14tg0rWdPgVbW/XmAXDGF92ZCfZunqMUGbeIb2ekcF6NY3Ks891emdARkKqABmPqcsQB7mr1xHqg/3milnj/IdmK42woOc56Z6jp9Kyzxm1Rjxfp8SDMVlCu6sCrSElnII6dQPsKk+GuLtI13Q7XQ7q4W2vrVUjt57pgEmTqUZjsrA5wehGNwaCI8RuCeINS42k1HTtPu9Rt9SIeKSKMvg4AIbGeXB9cVK8HeFyaPJHqXFKvHcBx5NijAn2Z2B+HcgY69TV5XhzV57eWNZ3ijkdf8GTm5lz7dgcd8bb96R4j460HhiOaWXUodSvI0SBLS2fmGw5SefpnY5x69c0DbXsae0mqayrWdrCwVgowVxvyqCeuAAF+lU3w4uLri/wAUb3WmLB7Kyla3j/hyvlxr9BzknHXB9arviXxxecY6pZNIotrSG2jaO3QkqrsgLMfVidsnfAFSvglq9tpPFzG6k5UmjbIHcqC4z2IHKxx64oLzrccvDXBGu6oG8tljEMJbIJZ2AGPflBP61nHg9psWoeIMM1ygeOzRrkM24EgGI8+vxlcDucVO+M3GC61YaVY2zgQS814YwclVOFjDe/KM/wDVUF4WasNO16C0RfNn1C4jijjzgZ+UM3bA5y2/8NBonF1snDvAmq6oGKzTFYYlZuVyzvufXYBunqKw7StVu9P1yG/t7h4phKGLKdz8WSD6j2O1aH428Zx67rcelWJH4G1AdSoA5ySSCf8Ap5KzCBed1XlZmJwAOtBqmm+Lyi9ubTW7RHt2lflnhTLR/ESDy5wev+sVp+gXtheQC74f1CO+z+dJCx5WCnPxeWcHpkZHTp9fmtOHdZuJSYdMu5yT+5EW/XFSWlycTcFXsWpi21DTfLLBJXiZE5ipGMkYO9Bsur+CelcRTPfWd1+zS+XeMRZbPfA2B6bdM+nc4zr3CWo8NSyPIiXUEbcvnRA4Q+jqfiRsdmGPQmte0Xxrjh0vTrvUIeS5a3d51QExMRLyDlGeZNt8DIyenarRxHw5w94r6Hba7p2opYalJGUilaUfFyndW36DPX33HoHyuxLyM7knJzvvmpHQtKbXNatbEN5SzSBS3KcKO52BqV4w4J1nhHUXg1SLlwR+ZGhCnPf2/wBYqI0mwlvLkhLlLXCkiWQsq5HQZFB9SaUtlpVtZaPYhMRwcxQ9fLX4eY/9Xr6Gs08X7gjUUSSQIiJhMsN/Xbr361S9B0DVeJdenil1sTyKpMkiXfmM4B9SenX6elMNVEenalM2BfkEqsl0TL02yOmenWggZI3ky6qWTPzDp+tNmGDTy/uHupfNbIU7Bc5A+lMjQeU5tm5XFNqVibBFBe+H0N/YzWpOScMo9KYa/oM0MyhYjzMccuP0xSvCdwsF4jvIEUbnJ6D3NaHrElhc6Ak5wGcflPy9/TPbNBh8sarll/8AH0rmGN7mVIYxlmOAKmLvSp7i+/JVfi3ffHlnPekbzT4rBFaGcyTqQWO3KPp670Cem2N1ea3baVF+XLLMse3rnqfXHWvrAW1lbHRbMp8VxGLSzUnAVE/eII68pD/U+1fM3COZuMtOaONmnadTsCcDPUDuScDFa7xzxsIfF97SK5zFo1hLbRKu+ZjCzSNnt8gWgzfxb4gGt8ZzWtpKDp1iBDCo2GyjJPvnNULOMr2NKT3DSs0jnLvuf0qf4J4J1DjPVDFCRb2MJBuruQErEp9P4mPZR19hvQVxIpJpAkaM7nYBRkmtc8MuPbvhrhDWdLP5JgBuLW4BBQyj9wE7ZbBxjrg1p2kcPcIcCS2OmW1jC19fOIYmulWS4nODzN6KoGSe2+N9qy7jq2ueO+PZuH+D7ET2tlMzyzrhI3lPzOx6Ko3UfQ+tBnvE2tft3V7i6TmEck7yIpHyqQoH/wBajbaR7e4SZQ55WGChK79t+1bDb+GXBPClpHLxfxI5u3JzFbuqJjocbM7fXAp5xRwh4cW/BdxfWUF3a3PlBreS5mlyWJwAyHcbA4BAoM4PH+uScP3mnG6WK3k8sCFEABwSSSTux9yTVcis7/Upi8UE9y7ZdmVS23ck+nvW+QcOeH3AfCthrEmh3PE0upBI4eeMS+c+OYlEOMDb06Y65qk+IHidr+oWn7EHD9tw1ZSKCbdIR5ki/u5JAwMdgBQV3gjgu8464pSx5hBbWqqbqfIIjQEL16ZPQVL6rwXqdt4q6zo+i2TSMnOlsiZwsbqVQk9sKTv7VfOHrdPDfhLStHmQyaxr91G06x/EUQkZ6b/ArAf8zH0pn4lX/FfDPEbcQaHfmCzns4oJpxMmOdcgoBnJ7HpQIWH+z3rWp3H4vXNZtLGMgDkhBmcAAKBnZRsB3NdXHDXh54f4urPX59f17LRW9rE4ILkFc8se/wC9t8XWprRuILqDwE1PV9X1Oe61S+t5pVeeTPVjFGo9OhOBVZ8LtCs+GuHZOONRjElxGHaBDgiKJQQ0gHdicgfSgcWHgRqGqxS6lrOoW+nXUwJissMwBx8IdgSRgdR12rzw94d03hjxEk4c4g4eXUNSlQy29wz88CoAWJ5Dt+77nO21VjROJNf408TbTUXllCWr+fyRseSKNTnGPc4HuTWt6VNHfeI97e3WHvNMsIYHkZhyK0hLMpGx5uUDvgfegR1njniV+LZ9C4X0K2mjtQrS3c7skSFlDEMBgDGflyScbCo/jjxHk0DRptPvJrW91OSLlEbIXRSR83lsTjHb7U9nuE440+c8M6/FZR4dy8MI81W78wJyM+qjOM7msN4v4N4i4buzNrUErJO55Lskukvvze4wd6CLvLrzrC1zjmKyBsDA3kz0qQk1O6s+HdHa3naFo3uCCpx1ZP8AtUAQdh0xT9Zofwtsk5LxwsxCAfNkjO/2oL1pnidf3UcGnaranWoBGyKrxh5LfIwWQ9x3KnAGPeo+/wCEYYpxeNfpf2cvxRlJMAH+Ej1HoN8VXpNQtkvVl0dZ9ObHKX80nbG/TferPw9wzqGq2qX8d2l1EW5ZIm+EKfUj6b5FBY0uF0DhBpYreKCe6HKkagKAg7nuc+9ZZf3MlxcNJI5csanuLeIJb2+8lHIggHlxqcbKKqjOzEkmg5ZsjFcUE0UBXaPynbr61xRQPobpo12bfP6VfdK1NNT0W20u4ZzzQggjrzcxwc/y+4rOFO9TFhdmC4tn32QDHqMmgmdRtbi6v/w6J5M6oe+OcqMkEnuQO/cY71X5DGVMjsQq46b5NaHeWK8V2MTRYF0mEkXPzL2c/wBDVT4n0GbhzVEW+SO6t5UPJ5b8oJx7dCDj6/egV4J1OLStVu9ZVjG9hbtNHz43kxyoPc85VseiGom21CS94mub6WQs8yXDFm6nMTj9aaPzx6cYjyr5jiRgD0ABCg/qaaIWU86jl2Iz9RQSnDehTcTcR2ulwNyecxLPjIjQDLMfoATW5X+raRwhwu0VvB5GjWI8uKIYEl1Md927uSMk9AAfQVXPBDTNPGja9ql5OluFiWIzSOECJ1b7ZwSdugG+9c+K2h8R6zqVjY6ZoV1Lp8ERkhmQcwk5sFicbDBPffp7UGbajxdqeqa9c6xcTH8XKCsZViBApO6oOwwSPuasPhLZX+s8f2tuLiZbUMZ7oczBXA3w2PU461P8K+C6i2XVeLb+Oxs4yWeCOQB8DszdF6e5Ht2tHA+t6ZecSa5JpiQQ6Ro1pzQQW8fLDjOWYZ3dsKPjbf0wOoSnEWjaHpd1ecRDT7jWNUsYwkMAXmWEA5+Fe5ySSeo6gbGsW1Diabjfi61/a7C108zjFrCCQqlvlG4yx6cxI+1SnCni5qfD2rObsPqGnvKz8hYJImSTlW7denSrLPqvBfEfEGncS6T5VnrVrMs0lnMqxJdEHON/h589DkA+mdqC1cXcb6xw1q1hoHCWkG8vVgUp8DSiAN8IU4xk8qjcnG1V/QuAb48YprPGt1Ff6xJG97+Cdw2MY5WfHUcxG2y7dT0qJ4n8aLlbq6h0LTzZzOeV7q5GZQwznlQ7LtsM7/Sq3pvFeuDR9UmSW7vdZ1VljaZsySeUu5x3xnI29KCe4w8VdUstXvtO0po43RzFJdjDMcHcL2ABz1zT7xu0yBOH+GNWtm547iN1DAgjdVfG3uT6/Wqpa+EPHOo8tw2jvEs2G555UTPMMjqc5Pp13q+3HhHxhq3CWh6Tf3NpbvZPKIxLJzDlPKVG223xUDXxE/A6b4LaHb28h86fyIGQ43EatzMMf58/epPg640PizwsXQJbpYLhLMQ3EjuEMZDnlIJOMAFdj1ye/RlxB4daa2n6Ta65x/pNqmm23kFFctzEyO5bPbPMR07VTpNB8PtOkZjxjfXfLti0tOUsOmAWIoLbe61wt4XaTJZaLLFqGrSdeRxKFcLs7t8pweijYZ7mongjipbDw/4y1S8maXUbh1xIwB5pJFcDPvsx+lU+7/3Le4YWY1RIEGR50ihm27YVh19h96YTajYx6XNZWtvceRJOsv5k4O6qQDso/iP60DHT9QvdLvVu7C8mtbqM5WSJyrfqK0vSfHLVVsTpnE2m2utWDr5cqsgjkK9MnAwT7kVlmF5CR1Jxj0rw5DENvQaTxLwnwvq2jw6/wnqiQC6ZwNMvGEcoZeUuqnODjmH1ztWetbTLM0LxOGQ4KkYINLSsw0W0BdiollwvZdk3H1/tXcE1xKjXDOsxQchV9yo7MPof0NA807SkndLdCr3DNuMHfOML/M1rWl2GnaLw9c6ZHfob+ZCZFRxsfQdqoPCGoWNtdtJIj/iuUiLJyGY9PoaY6y8tjGmXInlJeQKdgOw/rQRmsQxpeSBWPXoRiodqd3V0Z/ifdqZk5NB5RRRQFFFFB6OtOraTkfmz03ppSiZwfpQWbSuJZ9NuVmi+Jwc4/i9vpVgMUWo6ff8AEl5NA1yFChpNlhPTy1U/McHY9fpWfJIybbe9SNpdozxi6VrhI91jZvgXPXagjppJLkk4PlqenYfX3pPGSFJ/8VoPE+lSHgnTpbUQw2afE8bYVy56HPfbO1VOOKAaNNFb2ck92ZV5rn9yNP4QOxJ7mgt/hbxJbWWuQaNqMavY3heKRGOI12zzN69CT/0+laxxJx1Ho2kXl3NaokltItvCzMRFLE4Lxsn7zZVVJGAPfbbDbzhuXhjTtM1O6keO8uWLeUw5Si8p3+vSmfEupXF7K4ldnMkFkWJ78tuB/egX4q481jit/Knm8u1HSCMcqnvuB79v69ab6Rq02lcJazFBIUl1B4rYkHfy8Oz/AK4QVF22ntLvJLHbIRnzJWwPsACT9hT23utJsFGbeTUWRuYLKxiiJwN+VfiP/wAhQcaBw3qHEd4LXT4HnkJ+WNeZh7+w9yRWqaX4I6bYQifizV49PiC8xzdIGO+MBRnuRvn7Vn91x7ry24srK4XTrYD/AArRBGoOOwH9evuahFv727ldpLqWSRhuWYknG/8Aag+gNKtvCLQtXS1NxFqN9KOTLhrgAAE7Fth061E33j7o1k/laDw2oXATnkxF8PTGF/1+tY3p3mQ6rDMSS2T8WfVT3+9RhVo5OVxgqcEUGpca+MnFZ4i1Sw0vUP2bZw3MkSC3UKxUMQCWx1wOtUU8U67LqkF/dareXcsUglBmnZ8kHO+T3pPU7dr7izUFB2NzKzN/CvMSTTiTSA0DXAUiIjKjG/LjOT9sfcgUEXep5F5NGjFogx5GB2IzsabAbZbO1SFnp82pTFYI+eSQ8kcSnqfU+wAyTSExjGQFzGByhunMe7f67UCAwZF2yD1pxb2zTSfABgEnkzXsUbNb5EQKBxh8be/36U70NoX1MiTO4Yqc7+vTv0oGOoW4tb+SILhdiB7EZrqHT5bkkQrzHlLgeoAyas93pdleTQXDqVZTiUZ+deXb71GWVpFa6wbWZ2jikbCTKx+HtuO4PQ0DSJ4yUtp1eODvkZKE4yR7bClZ7OTS7rzIJYpvKbPwnm265I9KkNb0c2FysZbFsc+U+ebl78vuO9Q8kUqyArjBGxVsigcG4t5pkliBt3Jy6g7fVfT6UzubovI45iy5OM1xdCNSPLbJx8WOmfamrOW69aAZs1zRRQFFFFAUUUUBXoOM15g0YNB1zUtFLyEe1N8Yr0Ggn1v5tRWGG5laWGI5VCdge5Nalwu+iajoKaTJHDC3MJOULgFgdm+tYrDOYyMHFSltqkluC0bsJP3SD0NBZPE3UZbvWls5OVhacyhlGAQdwMeoHeqpqbmS6XoB5MIz9IlFJXF3LcPmZizHqWO9c30qSzApkIERfqQoH9qBuZCxwCT6URKvnqHORnLY9K6jiaZ+SNMD0FLXWnz208kYQ7Ej7UHUcKXYmJkWNkXm371w0T2EkM5KuSebl/saQMM0bZKFSKcMGMBE4cNsY27UF803Q4LuGC9tQHWX8wDPy59R0+1VfiDS0gjivoAxSVmjkyPlcE7fp/TvUnwNrQt5X064kKo554WP7j4x+h9Omafa9dT2V6EtrXz7a6mWWZWXIDjYY7DpnPfvQI23Dz3MplmUpHeSvcTP1PLk8kYHcsTkj2pfiieax0u20liJL67XnmdQAEXOwHp0P19anNP1G3s7O8upLkyhW85ufoo5R8p69MfcmqbZibiniWS4u38tJiSd8cqDcJ9MYG1BH882maewtuZZ7mEiRh/+OE9vYtjf227mm1v5V5aTxLDy3OVaPB29wB7/ANqlOJYfwDNbwsGW4/MkbA+Ns7cvcAD+tNrS2OkCKWUgXEoyoG7RL3P1PTPbeg7tozb2MtlymWSRkZlXcgg9Pr601tbdrfUkHIWkifoP3t6XsVmW+xEXEhyAU61Y9Ps7HSrn8bfTB5h8Swo/Meb/ADH+1BJ2+gXNys00Vu8EDvlEkIyBvsT7VE6xb6fa2TRyOJbkjYr0U051HjZ7tXtsiKNxgEHoe2fWqTeXbyStzE5zvQOm1uc2f4aTDcuwLb7VEvLua5kfLZzSZNB0WzXFFFAUUUUBRRRQFHaijtQejevQPb+dcivc+1AHYdK8r3PtXmfagAcUrHMyZwcEjrSVFAoGJOevrXo+LcnlHrSYY4x2ozQLo48wsBj0HpRPIZZWY7knJpENijNB2oBPvTpI3dSmNsZAporYOe4pVJiD13oHjStb6ekaBUfzeYsuxOOlWzTtaW7sg0nzEYdSc7+1UnzeZ0zvg5pzHfPHJzKe2KCd4gv2ureOxth8BIL8uwwOgpzpTfhxJJKqIQPLUAbADr+tV5dRIz03outRZvgVjgfzNA91ieCbUkuMhmTsdxntTP8AaHmXDu453fbmbt6fao+SUtSPNv1oJH8fLHsshx7GuZrwuoPMd9yKYc9eF80CrzEnrSTuW6neuc15QGaKKKAooooCiiigKKKKAooooCiiigKKKKAooooCiiigKKKKAzXua8ooOg2K656TooO+c+teFzXNFB7zV5miigKKKKAooooCiiigKKKKAooooCiiig//2Q=="
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
                local hueBar = New("Frame", { Parent = valueCard, Position = UDim2.fromOffset(17, 223), Size = UDim2.fromOffset(328, 16), BackgroundColor3 = Color3.fromRGB(255, 0, 0), BorderSizePixel = 0, Active = true, ZIndex = 73 })
                corner(hueBar, 8); stroke(hueBar, C.border, .25)
                New("UIGradient", { Parent = hueBar, Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)), ColorSequenceKeypoint.new(.166, Color3.fromRGB(255, 255, 0)),
                    ColorSequenceKeypoint.new(.333, Color3.fromRGB(0, 255, 0)), ColorSequenceKeypoint.new(.5, Color3.fromRGB(0, 255, 255)),
                    ColorSequenceKeypoint.new(.666, Color3.fromRGB(0, 0, 255)), ColorSequenceKeypoint.new(.833, Color3.fromRGB(255, 0, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
                }) })
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
    if c ~= localHumChar then
        localHumChar = c
        localHumCache = c and c:FindFirstChildWhichIsA("Humanoid")
    end
    return localHumCache
end
local localRootCache, localRootChar
function localRoot()
    local c = LocalPlayer.Character
    if c ~= localRootChar then
        localRootChar = c
        localRootCache = c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso"))
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
LocalPlayer.CharacterAdded:Connect(function() task.wait(1); applyCharacterMods() end)
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
    local cursorTemplates = { "Default", "Gothic Spear", "Gothic Wings", "Shadow Sigil", "Custom" }
    local cursorTemplateImages = {
        ["Gothic Spear"] = "rbxassetid://77559278786615",
        ["Gothic Wings"] = "rbxassetid://73847458193538",
        ["Shadow Sigil"] = "rbxassetid://130499812243487",
    }
    local cursorKeywords = { "mouselock", "shiftlock", "crosshair", "reticle", "aim", "target", "cursor" }

    local function assetId(value)
        local digits = tostring(value or ""):match("(%d+)")
        return digits and ("rbxassetid://" .. digits) or ""
    end
    local function isShiftLockVisual(instance)
        if not (instance and (instance:IsA("ImageLabel") or instance:IsA("ImageButton"))) then return false end
        local name = string.lower(instance.Name)
        for _, keyword in ipairs(cursorKeywords) do if string.find(name, keyword, 1, true) then return true end end
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
        return cursorTemplateImages[cursorState.template] or ""
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
    cursorState.template = table.find(cursorTemplates, savedTemplate) and savedTemplate or "Default"
    local templateControl = cursorSection:AddDropdown("Cursor Design", cursorTemplates, function(value) cursorState.template = value; applyCursor(false) end)
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
