-- NOIR_EVENT_HORIZON_V6_1_PART_1
local Players           = game:GetService("\x50layers")
local UIS               = game:GetService("\x55serInputService")
local TweenService      = game:GetService("\x54weenService")
local RunService        = game:GetService("\x52unService")
local Stats             = game:GetService("\x53tats")
local Workspace         = game:GetService("\x57orkspace")
local CoreGui           = game:GetService("\x43oreGui")
local ReplicatedStorage = game:GetService("\x52eplicatedStorage")
local HttpService       = game:GetService("\x48ttpService")
local Lighting          = game:GetService("\x4cighting")
local LocalPlayer       = Players.LocalPlayer

 
local function __noirSharedEnvironment()
    local ok, environment = pcall(function()
        if type(getgenv) == "\x66unction" then return getgenv() end
    end)
    if ok and type(environment) == "\x74able" then return environment end
    return _G
end
local __NOIR_SHARED = __noirSharedEnvironment()
local __NOIR_GUARD_KEY = "\x5f_NoirHubRuntimeLock"
local __NOIR_OLD_GUARD = __NOIR_SHARED[__NOIR_GUARD_KEY]
local function __noirGuardGuiAlive(record)
    if type(record) ~= "\x74able" or not record.gui then return false end
    local ok, parent = pcall(function() return record.gui.Parent end)
    return ok and parent ~= nil
end
if type(__NOIR_OLD_GUARD) == "\x74able" then
    local oldState = __NOIR_OLD_GUARD.state
    local age = os.clock() - (tonumber(__NOIR_OLD_GUARD.startedAt) or os.clock())
    local heartbeatAge = os.clock() - (tonumber(__NOIR_OLD_GUARD.heartbeat) or tonumber(__NOIR_OLD_GUARD.startedAt) or os.clock())
    if (oldState == "\x72unning" and (__noirGuardGuiAlive(__NOIR_OLD_GUARD) or heartbeatAge < 120))
        or (oldState == "\x73tarting" and (__noirGuardGuiAlive(__NOIR_OLD_GUARD) or age < 120)) then
        pcall(function() warn("\x5bNoir] already starting/running; duplicate launch ignored") end)
        return
    end
    __NOIR_SHARED[__NOIR_GUARD_KEY] = nil
end
local __NOIR_GUARD = { state = "\x73tarting", startedAt = os.clock() }
__NOIR_SHARED[__NOIR_GUARD_KEY] = __NOIR_GUARD
task.delay(120, function()
    if __NOIR_SHARED[__NOIR_GUARD_KEY] == __NOIR_GUARD
        and __NOIR_GUARD.state == "\x73tarting"
        and not __noirGuardGuiAlive(__NOIR_GUARD) then
        __NOIR_SHARED[__NOIR_GUARD_KEY] = nil
    end
end)

local IS_TOUCH = UIS.TouchEnabled == true
local IS_KEYBOARD = UIS.KeyboardEnabled == true
local IS_MOUSE = UIS.MouseEnabled == true
local INPUT_DEVICE = (IS_TOUCH and not IS_MOUSE and not IS_KEYBOARD) and "\x54ouch"
    or (IS_TOUCH and "\x48ybrid")
    or "\x44esktop"

local function isPrimaryPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

local STORAGE_ROOT = "\x4eoir Hub"
local ASSETS_FOLDER = STORAGE_ROOT .. "\x2fassets"
local CONFIGS_FOLDER = STORAGE_ROOT .. "\x2fconfigs"
local PRESETS_FOLDER = STORAGE_ROOT .. "\x2fpresets"
local LEGACY_STORAGE_ROOT = "\x4eOIR.CONFIG"

local function ensureFolder(path)
    if type(makefolder) ~= "\x66unction" then return end
    if type(isfolder) == "\x66unction" then
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
    if type(isfile) ~= "\x66unction" then return false end
    local ok, exists = pcall(isfile, path)
    return ok and exists == true
end

local function copyLegacyFile(source, destination)
    if type(readfile) ~= "\x66unction" or type(writefile) ~= "\x66unction" then return end
    if not fileExists(source) or fileExists(destination) then return end
    local ok, contents = pcall(readfile, source)
    if ok then pcall(writefile, destination, contents) end
end

local function migrateLegacyStorage()
    copyLegacyFile(LEGACY_STORAGE_ROOT .. "\x2fautosave.json", CONFIGS_FOLDER .. "\x2fautosave.json")
    for _, name in ipairs({
        "\x4fDH_FEAnimations_settings.json",
        "\x4fDH_BJP_settings.json",
        "\x4fDH_InventoryUnlimiter_settings.json",
        "\x4fDH_Pm-Wallhop_settings.json",
    }) do
        copyLegacyFile(name, CONFIGS_FOLDER .. "\x2f" .. name)
    end
    if type(listfiles) ~= "\x66unction" or type(readfile) ~= "\x66unction" or type(writefile) ~= "\x66unction" then return end
    local ok, files = pcall(listfiles, LEGACY_STORAGE_ROOT)
    if not ok or type(files) ~= "\x74able" then return end
    for _, source in ipairs(files) do
        local normalized = tostring(source):gsub("\\", "\x2f")
        local name = normalized:match("\x28[^/]+%.preset)$")
        if name then copyLegacyFile(source, PRESETS_FOLDER .. "\x2f" .. name) end
    end
end

ensureStorageFolders()
migrateLegacyStorage()

local guiParent = CoreGui
if type(gethui) == "\x66unction" then local ok,v=pcall(gethui); if ok and typeof(v)=="\x49nstance" then guiParent=v end end
local existingMainGui = guiParent:FindFirstChild("\x4eoirSilentAimUI")
if not existingMainGui and guiParent ~= CoreGui then
    pcall(function() existingMainGui = CoreGui:FindFirstChild("\x4eoirSilentAimUI") end)
end
if existingMainGui then
    if __NOIR_SHARED[__NOIR_GUARD_KEY] == __NOIR_GUARD then __NOIR_SHARED[__NOIR_GUARD_KEY] = nil end
    pcall(function() warn("\x5bNoir] existing hub GUI found; duplicate launch ignored") end)
    return
end

local NoirPersistence = {
    data = { toggles = {}, sliders = {}, dropdowns = {}, textboxes = {}, keybinds = {}, positions = {}, colors = {} },
    token = 0,
    path = CONFIGS_FOLDER .. "\x2fautosave.json",
    safeLegacy = {
        Enabled=true, ["\x57all Check"]=true, ["\x53how Shoot Murder Button"]=true,
        ["\x4cock Shoot Murder Button"]=true, ["\x4bnife Silent Aim"]=true, ["\x4bnife Wall Check"]=true,
        ["\x50rioritize Sheriff"]=true, ["\x45nable WalkSpeed"]=true, ["\x45nable JumpPower"]=true,
        ["\x53how Round Timer"]=true, ["\x49nstant Role Detection"]=true, ["\x41uto Notify Roles"]=true,
        ["\x41uto Fire"]=true, ["\x53how FOV"]=true, ["\x49gnore Dead"]=true,
        ["\x49gnore Friends"]=true, ["\x41nti AFK"]=true,
    },
}
do
    if type(readfile) == "\x66unction" then
        pcall(function()
            local loaded = HttpService:JSONDecode(readfile(NoirPersistence.path))
            if typeof(loaded) == "\x74able" then NoirPersistence.data = loaded end
        end)
    end
    for _, key in ipairs({"\x74oggles","\x73liders","\x64ropdowns","\x74extboxes","\x6beybinds","\x70ositions","\x63olors"}) do
        if typeof(NoirPersistence.data[key]) ~= "\x74able" then NoirPersistence.data[key] = {} end
    end
end
function NoirPersistence.Save()
    if type(writefile) ~= "\x66unction" then return end
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
    if typeof(p) == "\x74able" and #p == 4 then return UDim2.new(p[1], p[2], p[3], p[4]) end
    return fallback
end
function NoirPersistence.SetPosition(key, p)
    NoirPersistence.data.positions[key] = { p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset }
    NoirPersistence.Save()
end

local C = {
    base = Color3.fromRGB(3,4,6), surface = Color3.fromRGB(15,17,21), panel = Color3.fromRGB(10,12,16),
    card = Color3.fromRGB(18,20,25), border = Color3.fromRGB(91,98,110), accent = Color3.fromRGB(216,222,232),
    accent2 = Color3.fromRGB(245,247,250), text = Color3.fromRGB(239,242,247), dim = Color3.fromRGB(142,150,162),
    off = Color3.fromRGB(37,40,47), btn = Color3.fromRGB(25,28,34),
}
function New(class, props)
    local x = Instance.new(class)
    for k, v in pairs(props or {}) do if k ~= "\x50arent" then x[k] = v end end
    x.Parent = props and props.Parent
    return x
end
function corner(x, r) New("\x55ICorner", { CornerRadius = UDim.new(0, r or 12), Parent = x }) end
local gradientStrokes = { fast = {}, frameCount = 0 }
function stroke(x, col, tr)
    local s = New("\x55IStroke", { Color = col or C.border, Transparency = tr or .55, Thickness = 1, Parent = x })
    local g = New("\x55IGradient", { Parent = s, Rotation = 35, Color = ColorSequence.new({
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
    if #gradientStrokes == 0 and #gradientStrokes.fast == 0 then return end
    gradientStrokes.frameCount += 1
    gradientAccum += dt
    if gradientAccum < 0.04 then return end
    local step = gradientAccum * 30
    local fastStep = gradientStrokes.frameCount
    gradientAccum = 0
    gradientStrokes.frameCount = 0
    for i = #gradientStrokes, 1, -1 do
        local g = gradientStrokes[i]
        if g.Parent then
            g.Rotation = (g.Rotation + step) % 360
        else
            table.remove(gradientStrokes, i)
        end
    end
    local fast = gradientStrokes.fast
    for i = #fast, 1, -1 do
        local g = fast[i]
        if g.Parent then
            g.Rotation = (g.Rotation + fastStep) % 360
        else
            table.remove(fast, i)
        end
    end
end)
function text(parent, value, size, pos, dim)
    return New("\x54extLabel", { Parent = parent, BackgroundTransparency = 1, Text = value, TextColor3 = dim and C.dim or C.text,
        TextSize = size, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left,
        Position = pos or UDim2.new(), Size = UDim2.new(1, 0, 0, size + 8) })
end

 
 
__NOIR_GUARD.blackhole = (function()
local BLACKHOLE_SPRITE_B64 = "\x2f9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAUEBAQEAwUEBAQGBQUGCA0ICAcHCBAL\x44AkNExAUExIQEhIUFx0ZFBYcFhISGiMaHB4fISEhFBkkJyQgJh0gISD/\n2wBDAQUG\x42ggHCA8ICA8gFRIVICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg\x49CAgICAgICAgICAgICD/wAARCAMABIADAREAAhEBAxEB/8QA\nHQAAAQQDAQEAAAAA\x41AAAAAAAAAQFBgcBAgMICf/EAEsQAAEDAwIEAwQHBgUDAwMCBwECAwQABREGIRIx\x51VEHE2EUInGBMkJSkaGxwQgVI2LR8DNDcuHxFiRT\nNIKiF2OSsiVEVHPCJmSj/8QA\x46AEBAAAAAAAAAAAAAAAAAAAAAP/EABQRAQAAAAAAAAAAAAAAAAAAAAD/2gAMAwEA\x41hEDEQA/APHrZCzxpOFJOcdqB8gXQhLU\naUpfs6VAkA8sEkfLc/fQP718Q7MQqOty\x51Qfd8xKUkegI6fGgSqZi3J/2iIgsPpPEptJ5HuBQZmWNu4t+ZlLMk7AgYSo9j2zQ\x512XEdjPKbcQUrScEUCSgKAoC\ngKAoFbZ4z5idik5+FBI7XcEOJRGlPqRHSQccwMEk\x66mdvWgeHb55kviaK5ITukqSlKgPTHT0/Cg4JjRprntcZIQriyUpOOE/DpQa3aysy\x6d/MbHlyOHIGMcY/r\n6UELfYU2ogpIUOYoE1AUBQFAUBQK21cR8xOxSc/Cgktrmtuo\x45WTK8thBCwFZI2JIA+ZO1A6u3oPPcWFupSdl4AUj7unpyoN2I8d5xDzaUYWcjh5Z\x39B0+FA13\ny0JU6VttlDyfpNnn8R3FBE3mSknbBHMUCegKAoCgKAoFbauM+Yk4IPLt\x51SW2zUuIEZ+QEst4WELUd8EkAd8EnagdnruiRIQpYUAT7rhAwPTYcqBY3HblJ8kN\n\x6fUpXvJTnZXwPQ0EWudpV7QsISoqSd0kYUn0IoI8+wpCiCkpUOYNAnoCgKAoCgKBY\x32eP+Ik4IPLtQSa3TQWksPOFUdBCuAqxyJIH3k0Dv+8WpMwe8ppw/R8wD\nHyI5UCiT\x43TdI5bS0FPI38sHCvin+lBE5VoeUspCeJSdtxwq+YNAxyIy2llK0FChzBFAmoCgK\x41oCgKBY2eP8Aio2KTy7UEpt0lXsiUSAtcVKhhIPLBJH4k0Dz\nHnMyHyWHiV/YcABI\x39O9BpcLSi6I8+M2XHhzDZw4Pl9b86COP2R1zOCC4PtJKTQMUqG9HWQ40pCh35H50\x43SgKAoCgKAoFjZ4/4qdik/dQSu3vn2BJkl0RUqTg\njcDckD7yaB+jy2nhlqR5qOoG\x79k/391A3z7CzIUZMdCFp5lTSghQ+KT+lA0v6fLoyglK/5hzoGCbbZUZZ8xkgj8aB\x76oCgKAoCgKBY2Sv+KjYpOfhQSy1v5jJD\nzqkMpI4eLOBuSBn0yaCRlbUlIDr/ABJV\x79cACh8+9A0ybEyHOJLMVfEcgtE7/ACztQczo2TcWC9EiPHHJbba1J+/BH40EUuVk\x6eQFqDzCgU89qBpoCgKAoCgKB\na2eMeaj3SlWfhQS+ySl8KGS5hJ5Aq2xzxvt1O1BI\x482WZRCDI8p0fRDqApB+HUflQIDbVOSksJUFuFQSAxvxk8gkDrQSCV4PahmMB1VtL\x4cxGQFOt8R+I4s0Fd\nah0XftPvlE+3vMkfbQU5HcZ5/Kgi9AUBQFAUBQLEKKh5yNil\x58LtQTeyTVKaaYWolJ+iCrf5de9A8Ow2pK8xrkW1H6SHUAH4BQ/WgV6Z0w5qS9Jtk\x4eDDTvCXV\nrczwNoHUAczQSG5+FdgluKit6otqZw2wtKmgT2zk/lQVhq3w31Hpc+dK\x68qXGV9F9ohbax6KG1BB+RwaAoCgKAoCgWtqKh5zeykqz8KCeWqcmVDajyHOFKuXC\n\x63/gdqBxegJCvPauaH+QSkp4SkE74oJ9o2wWGdpybqC9qfLUd4tIitOFtKQAN9upz\x51JrjY/C3UnFHRPk2aadkuP5cbz69RQVbrLwzvulkJmlCJtuc/wAOZGV5\njS//AHDk\x66Q70ECoCgKAoCgKBcy4riEhlRQtCsjHQ9KCfwHV3RlkPKSy5gEOOICgfXPMfjQLX\x49zkJB4ZSJKltq3Qd9zk/gKC7LvqG06XsFq/ddpirjPx0uJCk\nAhYwDn8aCEzXfDXX\x4aLF1t6tM3Ff0ZkdPEyVfzo5geooKo1t4cXvSD6XH0IlQXhxsS46uNp5PdKh+XOgg\x31AUBQFAUBQbtrLasigWNOkBCh/zQO8RpHtQSo4ac\nGR6f2aCwNL6GkaiS+5a5Dq5b\x43CsNpA3I+r6mgy5bZ8YuRpVveQ5uFxnkEcWOqD1PpzFBF7tamJquJp0lQ2wojjT6\x48v8AgaCIzLVJjZUUcaR9ZI/PtQN1AUBQ\nFAUHVlzy1HP0SMGgWsupCkA44F8/Sgd7\x65wFSXI6iQCOJJHPagsPTuhJd6tMm5WdxyW9HTxKaSBhYzuMbHIoNHrXcEsFmRbny\x6be95TqDxp9Ukc/iKBke0Xcrw\n2qRBtU18J5rQycg/dvQQm52C4W51aH47iSnmFIKV\x444g70DPQFAUBQFB2YWEqKVclCgXR1IUUsrOAv6KvWgdrayXVPMOKKVN+9kc8UFj2\x6eQc2bp5d4tIcnttn\n+KgYAx3B6dqDlJsN3W2GHbbIdKfopW3hxHp/uDig1m+E9+lw\x68KXDYaURkIXISlwffgH4ZoK4vmj71ZHSJcF5sdOJOM/A8j8qCOkEHBGDQYoCgKAo\x4f0dQ4ik9\neVA4sAOgIzhwfRNA72xr2hC23HPK8sjiPQ+tBZUPQVwcsbNytzL0+KvY\x6cBSFIV/L/TrQZTo7UFymswlRQXM8KVyPcKPQjmD6UGNQeGVvjf8AbSdSQEzEjdl1\n\x4bkFJ/wBW/wCNBWt80HerS0ZQY8+KeTzKg42f/cnb78UESUlSFFKklJHQ0GKAoCgK\x44vHOFEZ3oF6ElaOJBwaB7tLBmgNuvBASeEk9KCzWdA3YxI70SNImR3kc\nTL7YHGD1\x54jPvEdRzoHCy+HtwvFxWLvIEdhpJUtaRlbmOnvfRPxoGe96d0JIdcixrnPacRkFT\x30cOJz393Bx8qCBXjw9uLEVy4WlbV0hI3U7FVxhP+ofST8xQQ\nhba2llDiSlQ5g0Gt\x41UBQFB3jLKVKx1G470DihxwN4QshKjkfGgkVmiqubzYddKd8qUE5Vt270Fjt6BvL\x69+FuK86gt+azLaSDxp7kA7gdSNxQSCzaJt9vsk2+\nana9qUz7rTDalIQr5jmr8qCK\x58BOjrqClWn5kHOcKjvhwj14F7kegIoIdc/DlyUw7O0tLburSBxLZbBS82P5mzv8A\x64kUFfPMOx3S082ptY2IUMUHOgKAoCgUR\nV8Dh6gjegdUzHfIEfPuZ4k0EjsED94TG\x785wYGM+YBkigsKPoK9yXHkKhux3GRxB9KAW1jOMkdPiNjQSyRAiaH0TDcFtjSrtL\x55eJ2SyF8fwz9wFBCZd5tN1Up\nq66bt7ygcK9hV5DqT1wPoq+GKCMXDw6hXpDknRs4\x79XkAldvfT5chPwTyV8t/SgrWVFkQ5C48plTTqDgpUMEGg4UBQFAUHeM4G3MK+irY\x30D6Z/HAbiY4QhRI7\nb0Ek0xbZM+4ezMupaUoe7xJ4g4egxy3oJ5btBXS6oc448i38\x47yyUZQrfkM7pPpQTDXd4umnV26y2l9dtQ1FCyEjh2x/Sggx1jJuIDF1jxL6jGFNS\x6dvLeH+hY\n3z6ZoGKfoCzasbclaJeW1cUgqXapJAcPfy1cl/DY/GgqmZDlQJS4sxlb\x4czZKVIWMEGgT0BQFAUHeM4G3MKGUq2NBJPa2jb4zLWEqSo59T0zQSHTcaXPdfZbC\n\x46ltPEllwFXH3CetBZui9Fypl7t90W1KjojvBxLDqchah9k+mc770CXxDmTG9Z3Ft\x3999sR1hCEJPDn+nI0DNb9aXVEcsJkpu0MD+JAnpDgI68J/pg0CS5eHlp\n1tbZF50O\x32uLcWElyTaVniJHVTSvrD+U7j1oKakxn4khbEhtTbiDgpUMUHGgKAoCg7x3A2shX\x30VbH+tBJ0lhEOGpABUokqIOCDnbBoJDY/ap7Ugqi+0pYTxKJ\nJCwPTHb4UFyeF+ln\x68d1zwqUFSIym0NPJwoDnkdwMUFX3pXsk18yWSp0OrSeMlI2PT13oFll1Zc7Y0VW9\x38yYKtpFvlYdbUOux5j7iKDtrLwxgXvS6dcaOjqjt\nLJEqATxeSvrwnmU7jGdxmgo5\x31lxh1TTqCladiDQc6AoCgKDvHdDazxfRVsf60EnQhAhxXFOqT5gUUkHZBB2HpQSS\x7aqMuG849GdWGSAp9lfCrfrw9aC5dIaYd\nf8PtQQ23nnlvMmYhK04Ukpx0oKenSjEc\x62acjN7pGy0brPXfnnNBJdI6mftcxDCP+9s8whuVb3/eQoHmMHr2PP8aBt8XPC+PY\x62uZtiz7I+nzUtK5pB6UFMKSp\nCilQII6Gg1oCgKAoO8d0NLPF9FWx/rQSdlLpjMKb\x63CAsEoA2Jx+dBJ7OBKt7i5KpLXlr8tT7QCk79COf3UFvSNNruHg82UPGU9ZilxKw\x4ey2Sdsc9tqCn5twf\nZuCo80FYJOA4NiM9DzBoLP8ADWczfG5WibmsS7bNaU5HQ7uW\x58AM5T2PcUFKa20n+57o+qIMtpWoFPbBoISQQcEYoMUBQFAUBQd2Fc2z13FA7Q31g\x4epB/iNKy\nM9UmgtLTN2fs8wzoTqm0PMnZKsEHt8QdvmKC3fC2PYJtlkybzennvMKS\x35DcQVpJJI4vQ+oIO1A+3GX4V2qS+7Dnlcwj6LjIyk9lKHQetBVd4mWW9zHUrt9ul\n\x73gnC2x5DoHLPGNvvBoIPdvDJu4hcjTq1PuAcRirwHvljZfy39KCs59nm29xSH2VJ\x34TggjBBoG6gKAoCgUMKBSWzz5igeYcpY8lxO7rCuEj7Sf72oLR03dZFm\ni3FcWWpt\x6dWxhIScHJB3/ADB+AoLu8N06TRohEm63J+4BSiXIykkhn3QSUk/RPXII+dA06t1v\x70RERy3adckQ1A8IdcSeIk8unL40FbyLm/IQlqddIlzaXkhma\n0VEDOPpjdPyoI/cv\x442BewXLN/wBrMVuIzjgUlz/+m4Nj8FAH40FZXawXKzyVsTIzjS0HCkrSQR8aBqoC\x67KAoFDJ40lBOCncUD7CmYWxI+ug+W6O470Fo2G5y\nLZpy5Q2pq0syiAEJJzyzkY5g\x6aP3UF86Vl6RtmgYkiW47eyUZKFJKy2rsk4zz6A/KgrHW2oYepZ4CUvQWWwMAoUAg\x5aA68/uoIcieuG65GYvCCwVFJjyf4ja8H\nG6Tt91AmuGibTqJPHFbRargse5hfHGeP\x38q+aD6K+8UFZ33TF30/MXGuMRxpaTghScUDJQFAUByORQKWnVHBB99ByKCQQpSQ6\x32+NkuDy3R2PegtizXOQxpM2l\nuS6ltb27aSfcKdzjHQpOfvoL4Zv1ksmj4zlubVep\x532khLqkF0pPDuc4zt8e1BRuoCxOmS58rzGHlBRT5rZ2xjf160EagTlQ5ivYLwhhe\x53kkDhC/RSfoqHyoF\ns/Stm1MPLkx2bPc1jLcqPvFfPqBu2flj4UFYak0jetMT1xLl\x45W2U7hWNlDoQeRB7igj9AUBQZBKSCOYoFkeQUqCk8xzHpQP8F5KHk8J/hvgDPY9K\x435rPdpMu\ny2q3NPPoQ26VLShRy0U7KxjcbEH4Cgt/UV/aY06LbY21T/PTh19KOMqQ\x42nJUcffQUJfYsWPGK1SHWXUq4lHBGSU5wSOfI0DHa5gE4Ow74hiUg4S82ShQ+OPp\n\x444igkL+m7brIqh3mGzbbuf8ADuUUfwHj08xKfo5+0BjuKCqdVaLvmkbo7AusRbak\x48njYjuDyI9RQRqgKAoNkqKVBQ6UC+O+gHBGUdR2oH+2PKZfS0lfCokLb\nV6/70F86\x66vMq83DT6WHXm2mklbnlrKS1g/xBtvtz+FBNNc3F67RU2q3pLsBvBeWAOBR+0VY5\x34BoKI1THt0Z4LEhxogAcRRvtkYz8qBDanWpTyFxLyhua0ctO\n5KFg9sigsCFoj/6n\x77X4tzhIavTLalt3SOkcLvDj3XgOu+ysZ75oKJ1NpC8aWuj0G4x1JU0opJxQR2gKA\x6fNkK4VA0DjHU2pIbUrYnKVdqCR2WY9GeQEK4ZDCw\npPZY6g0HojSl4l3zWdnlxH3G\x6fiIYU55TnCUJGQoH0B589qBVrR1/UN1W4eI26LhITj3AQnO225zvmgo3U6bbEuqw\x6dQtGFbEpPLP40G9u9nnhD8K7NpmMkFKi\nSlRx6jtQXFfvDNrWnhk1fbx5CbwhKi1P\x61IJkIHIOY5q5jOM7b0Hl286enWaStt5BUhJwFAUDNQFAUGyFcKwenWgcWAHBwZ97\x36p7iglenLo7DdZfQMuRljzGz\n9dGaD0tou8Trt4juXONJ4ICoKHVIbc4QRw494HY7\x37H40DDqNh2/Xu5XaYpaopWWkIUNsAdPQDrQUhdnLdGuqwiQpBB3JSc/f1oJRpZq3\x33G9wpLV6aZX5iUuO\nH3Sg5GFZHrigsjxv0dZ7pK81MYG5toy7JZwQ4MbEkdfXFB5b\x75VmlW51QUnjQPrCgbKAoCg2QQFAnlQODeVAjO43+IoJ1pG+m3TYc9Q4/JdSHe4wd\x6aQeldBXi\navXl/uLUsotpYEgMBwBJJAwd9u+TQV7dLcq4N3a7T3FuJkOrIStJ5DPv\x628uRoKgdlW+NclFuUtBSrmU4xQXT4MP2dWpnFM3KOX5DCwwFnh/iY3R8wNqCF+Jd\n\x6aRdrpJmuQEtPrUpZUxuB8cf0oKZl2yRGBWElbfcUCCgKAoMpxnegcm3F8PCFfR3/\x41N6CyNBX6NbL3AnPJCEh0BZ6djn0OcUHonQd5lxbhq1z29QgthRYYVjD\nZWCUkHoM\x4876Cop9oQrTT9wluqV5rinClQzgdznketBW7M62xppxKWEg4PEk8uvxoL60fOj3b\x77un2W1XZhUmMvz+FXuqcZOAr5pPP0oKP1bYXnJCnnInvEk8b\nR4ts+lBBJVskRk8Y\x53Vt9x0oENAUBQZHOgdmZbnsyGVZ4UHiHp3oLV8MrpDi32L7QsKYeXwOIWMhYPQjv\x2fSgvTSt6ls6T1mxLuQLTXmRmEqQApvIJHvdiKClr\ntZ2m9KMzJLilce6kEZ4Qdx8+\x74BDIVytceUEqluIbJ+kUnKfXNBdl9CNaaIiXq3XeO9JiNJiy2zsUkfRc+Ch+IIoK\x46vOnZKJj3mR+IBR99v3vy/pQRiVbJEZP\nmBJW33HSgQUBQFBmge403igIjOH/AA1F\x53D2HUUFteFj0Ry5twZ7bS2HlYyvHunbhX8iN/jQXFAvch/wh1SxPkMIdQ4qKjgRw\x724kb4UfUffQUnqCzsxrNGmSX\nCvjSONGMgHhz99Az6d1FBs96jSWpy2VsOBxt1ST7\x71h37joaCxddadg6hgJ1PYbmw5FmBXE2rYsvc1NnHzIPUEUFJzNPSEhXHH4wPrt+9\x2bX9KBil2mVFaS/wF\nTKuSgKBvoCgKAoOiBnlz5igUtunKVpOFDl+ooJlbJ4XGQ6hR\x4ab3cR3HIkfh91BbWi3mpSy6w/wAIDOFNoPDyydj8/uNAt1Ff9PIt4ZkraeW0j+Jx\x73cRSfsp6\n/MkUFQ3LVVqWpbbMMIbOEgFR5D4YoE0HU0dDqfIW7HKTkFpw+6e4B5ff\x51WBGv9m1MwmHrEJdCwEN3phv+K0egfR9cevPsTyoK8194fT9JzwshLsR5IdZfaPE\n\x3282eS0K6j8uR3oIIRigxQFB0QPs8xuKBW06QpLiDhQ/EdqCZ2y4FcRtwK2R9NPbu\x66yP30FuaTfbkwpC2XdigK8oHCcjl8gcZ9AO9Aq1RqayBSlLlKeSyCCks\np2I9T1J3\x39KCmrrqa2PvcKI3ChI4QSo5O+emKDjA1DEbXwsqdZGf8tw/kf60Fj2zUdo1DFbs+\x74EiZEWA2xd2kZfi9g4Prp9Dv2NBXviN4cXHRd1woJeiOpDrL\n7R4m3mzyWk9QfwoK\x2bIxQYoCg6IyCCnmNxQLGXSk+YjkfpCgm1suPFEZXn3EHB9N8/nv8zQXFpWU0/BC2\x33VJShYUUA+6n+bHoMgjvjvQJ9TajshekLclPyEc1\nhSRwt45JSDuVctycCgpm5362\x79JS3DGCckkZVnmc9MUG8DUMRB8ttTrIPVtz8cH+tBbOkrxatXRkaV1jwS4jiSmJc\x30J/ixVY2Ch1Qex+INBVHiJ4ezdHXt5n3\nXGAeJK2zlK0ncKSexFBASMUGKAoOjeQQ\x558x+NAuYfDZz9RXP0NBObZcyY7CuPdsjCs45cvu5fA0F0aZuLcmM2+FltLYPEkbJ\x53MZyB03H3g0DBqS+2ZtuSgOu\nvoCVArXg+8dth0+FBTsy6WtUkuKjgHplRP5YoFkD\x55UNIDba3WSDkKbcOx+B/rQXfYr3p3Vvh45ZtVluQpgn2aelP8RjIyEqHVJOdvXag\x6fXWej3LFOW5GIcjH\n3gpJyCDyIPaghpGKDFAUHRvYggZP50DjHeA/hlWEKOUnsaCe\x32e8uIRGdS6pt9tSVcQP0iNgfjjY/Kguex3Bu5Q3X1SEstqaKVJAwEY3GB8/u+FBD\x4eWXa1PMO\nsp4/KQeaveISBgDfqc59KCp3Z9qbeKjHAOdiVH9MUDzZ9VxI0tl1suNK\x61PNtzmO2D/WguLU2ubRrayx2LtFZfQlGEzm04WjP1Vjtn/Y0FBaq0z+65SnYigth\n\x514vdORg9R6UEUIxQYoCg6t7Hb/mgc4zxKEslXvA8TSs/hQWFYb8+yI8qO8WZLawp\x51HJR5E/MbEd8d6C47bNi3e2yJDjwbYUkFTYPIJOQB8tvhigrfV82DPc4\nncpbbSeL\x41BxuTjfmeQ9KCtzOtbDmfZwkjkSvJ/DFBNdGeJQ07clPRHXo/mp4FqZc+44P9aB7\x76eqGdRoLt7KJoc2MxCfeHYLH9+lBVGotP+xOmRFIUyfewNxj\nuPSgjRGKDFAUHZok\x62CgdoslSkpwcPt7oV9odqCyNNajehpjzYLnlrQr32+m+yh8Ffn8aC2Y0yJcrQ7MC\x764TeXeEqzlQ+iNviAfh60FS6sXDnXN599R4EgcQA\nHu4AGB67UELFxtkV4LSwEqTy\x4aXnP3YoJjZ/EZDdpFo899hpC/MaLTp9w9Rg9PnQYn3ZFwbzPCJLbh/8AVNp3H+tP\x39+hoILqHT/sSzJi4UyocWBuMHqPSgjZG\nDQYoCg7NLKcDJxQPUSSrKX2yA+1uofaF\x42Z+ldTvWxDEyG5xN7trQTuUHdSD+Y+dBZplRpdpVOZ4lIZCikEndRPu7fgfUUFL3\x39mHIush+QtXAlRUoAD3fQetB\nHW7pbYT3EhgJI295RPEPliglJ1+xdIrLMhx9qQyk\x4eh5t0kqSOWQeeOXOgTOSm5KiudwSGl7e0NpwR/rT/fxoInqHT/sThkxcKZUOIgbj\x426j0oI0Rg0GKAoFL\nDqk4A6cj2oHmFK8tfntjb6LqB1FBbGktUvWlttxJLrLjRYXg\x2fwCIyTnHxSenagnk2QxJtS5jZU62EFtJGQnc5GfuNBSNwhxVznnZLiuBGeIcI27D\x34/hQN0W+\nQrXKS7HbLSkEFJ4znI3ByMb0D5M1pBvbhec8yLKWPfcZc2J74P8AWg5p\x65ZcTmYlD7S9vaG07j/Wn+/Q0Eb1Jpd63pTOYbPs7qeMY3BB6g9RQRUjBoMUBQKo7\n\x76DjPMcvX0oHuBJQyokglhzZQ6pPegt/SWr1QWXUy1eYh9gRpG3Fxt5yhfqUnY+mK\x43TX1bUi0SXg55iHW/KTw/RT1FBSz8KKqS69JcVwJ+kMD3fT40Gts1OxY\nZqZEJJaW\x675TlZOe/LAwRzFArlantd0k+c0hyE4Tn+C5kA9dj0+dB3ZcjvLQJ5Q5HcISqU2nd\x50+tPX+8Gga9d6Bm6ZfalpQFQpTYfZcQeJDiDyUk9R+XI0EDI\nwaDFAUCuOsZAPMfi\x4bB8tkgNLSgucCVKyhf2VetBdWltWteyzGrkE8ExlEeWlQyOJJy278OhoF2rEofs0\x74a1cYewEcJ91HDukfp8KCnlQYpddelOKKE5KgANv\nT4/lQd7Tq5nT7yvZmx5a0lC2\x31rJS4k8wcYGKDVy/WmbL86OHYiyebbmcfI8/voJDYHbI/PSxqM8UGThszmEZLRPI\x72R1H49jQMXiV4bTdF3UKQUSIMhAfjyGV\ncTTzavorQrqD945HegrkjBoMUBQKmFA4\x425/nQSSyXGTCkoDDxbcCgplfr2oLx01qeDOhXBqWEpauSG/PSo4DclBBCj6KFAh1\x71zx2l7zOI+Y4VNnOyMfRT92R\n8qCqkwYxUt6W4ooSDxAJG3p8fwoF1s1ozZWHoQZ8\x32I8OFxlxZIUByO2MEdDQJf31aJMkuR/NiuE/Sbc/Q/1oLB0tedLTIyrNrSKlUKT7\x6ad3iI/iR1dC4jktP\n49jQQXxL8NZui7txIUiRAfQH48hk8TT7SvorQrqD945Hegrk\x6aBwaDFAUGyVEGg7HlxjkefoaBxt0l1hwOtHKkblPRQ60E+0hfUWu4OPNufwVsrUk\x458vdOR8q\nCEXy/PTnilJKQTxK9SaBgJJOScmgASDkc6B7st2ciyQh1XEhXukHkR2N\x426I8ODD1lp+f4d3c+c06yqZanV7qYcA95A9CAcjrj1oPPWp7A9Yb1IhuJ91CiAaB\n\x67oCg2Sog0Hc8g4nkeeOhoHK2y3YzgcbPEU/ST0UOtBPtI38Wqc44h0mOtlakgn+U\x37fEUEGvl9enOlKDwgniV6k0DASSck5NAAkHI50D5ZLu5FlJS4rKDsc8j\n8aD0bb5b\x47sfCE2OWkPvW/wB+KtW6kJPNPw/pQeabxb/YLi4yB7ucp+FA10BQbJUQaDvnAC08\x6azHrQOlsmrjr4k+8kfSQeRFBP9Kag/dUx3DvHGcZWUgnmOE7\nH1H6UEDvl9emulCC\x55pzxHfmTQMBJJyTk0ACQcjY0Eh05fpNrubLwcPunryI7GguW6Sv+o7A404S8C17R\x47KtyBjC0f329aChJ0cMyVpSPdycfCgR0BQbJUQaB\nQFYHGN0q5igdrXOVGUU/TaPN\x4a6igsHS2olWuQ82t3zIrrK1Jz1GDt8RQV9e767Nc8tvKE54jg8yRQMBJJyTk0ACQ\x63jY0Ei05fn7bMCVLJbWOFQPJQ7Ggn09a\n59pXFB8xPB50cnfb6yP7/WgqmYwGn1BI\x3907igSUBQbJUQaBSCMcXNB5jsaB4tU3yVFt3LjZHMc/jQWHpnUira8/Hed8yM6yt\x53Vdxg/jmgrq+X56a75bZKU54\nj6nFBHySTknJoAEg5GxoH+w3p6HJS26vLavdIPIg\x3880EweaMmKuICVpLZejE9vrI/v8AWgruYwGn1cI907igR0BQbJUQaBSCMAg+6e3Q\x30D5a5wDgafOP5v1o\nLD03qVVuW/ClK42XGVKB7+6d6Ctr7fnprvltkpTniO/M4oI+\x53Sck5NAAkHI2NA+2O7rjSA0+riaV7pzyI9aCXeT50N2CMqHAXoxO+31kfn93rQV/\x4djhp9QSP\ndO4+FAjoCg2SopNAqSrHCpJxvsR0NA/WqZlzh4vLcPPtn+hoLE07qYwB\x49gTBhC2lEHl0P9/2KCsr7fXZjxQ37oJ4lEdTjnQR8kk5JyaABIORsaB8st2XHfDT\n\x784m1bHPI/GgmkSCu5IVamjxKUhT0Xi3zge83+B+71oK+uUMxJi28YHMbdKBvoCg2\x53opNArbcKFJcbODnY9j2oJBaZikqV5KuDi+kjO2f75UFiad1SiLHkQZR\nKUraUR8c\x48+/+KCrr5e3JbxQ17gJ4lEdTQMBJJyTk0ACQcjY0D5ZbsuO+GnjxNq2Oeo9aC09I\x57JjUy52mycynI65VuKj9IpGVM+uQDj1HrQVDd4BgXF1jBABy\nnbpQNtAUGyVFJ2oF\x72Lqm1pdbxn8D6UEjtFwUzxIbJLLhzwZ3SodvX8xQWJp7VTTEKTBkrwhbSiAeQIBx\x2ff8AZCqb3e1ynS2yOBJPEojqTQMBJJyTk0ACQcg4\nNA+2S7Ljvhp48TatjnqPWgvX\x77/gRNX6dvGgpLYXM9mXcbM4rdXGgZcY9QpIPzSD1oPP93gGDcXWMYAOU7dKBsoCg\x32ScGgWsOlshSSFJOxSTz9KCVWe5hlKWV\nLKmFZ8teMqbPUeo7igsGx6naat0qBKcB\x62U2pQBORkJOP7/3oKkvN5VIcLTA4E54lEdTQMJJJyTk0ACQcg4NA+2S7Ljvhp48T\x61tjnt60HoHQnl620ZdPDacPO\nkssOXKxOL3UlaRl1j4KAO32k560HnO7wDBuLrGMA\x48KdulA2UBQbJODQLmXuDH1kK2I/vrQS6y3BAWhl14AqH8N1X0VDqlXagsC06iabt\x73q2zsBHlkhK98EJO\nBn+/6BT94vCn1+SwOBOeJR7k0DESSck5NAAkHIODQPtju7ka\x51G3iFNq2PFuCOx9KD0HoVSNcaMunhtP/AI8llhy5WJxZypK0jLrHwUAdvtJz1oPO\x4e3gGDcXW\nOHABynbpQNlAUGyVFJGDg96Bey+E4490Ht0PcUEyslwW455XGFOuJ4ee\x41+n+v60E+t+oY6rVKt8/CwG1KSXB7wKUnY+vT+xQU5eLwp5XkRxwJzxE9zQMRJJy\n\x54k0ACQcg4NA/WO7uRpCW3iFNq2PFuCOx9KD0HoVSNcaMunhtP/jyWGHLlYnFnKkr\x53MusfBQB2+0nPWg84Xe3mBcXWMYSDlO3SgbKDc7ig0oOzS8HhVuk86Dq\n24qO8ClW\x4dHINA7uKPsap8LZH0Xmx/lkjn8DQR5RKlEnmaDFAUGySUqB7b0F3+Ekqc1q7T8uE\x6breYlo2H2TsR+FA8+P2mUQdVXJbCB5anPNRjoFb/AJ5oPPS0\nYURQaneg0oOzS8Hh\x56uk86DohxTDoIOw3BoHZRWISp0Q+4PddQDu2T1+BoGBRKlFR5mgxQFBsklKge29B\x36I8ElLfmezryW3sNEfEf7UEB8TbKbfqN8pT/AAyt\nQ/H/AGoK3WjCiKDB3oNKDs0v\x424VbpPOg6IcUw6MHboaB2KliEqbEJ4B7rqB/lkjGfgaBgUSpRUeZoMUBQbJJSoHt\x51Xp4eLEmxseb/kyEpGfsr90j8KCvNY2k\n2y/yWMfwytXD8M0EQWjCiKDB3oNKDs0v\x424VbpPOg6IcUw6MHboaB3Utz2Ay4iiW0+64jOS2SMZ+BoI+olSio8zQYoCg2SSlQ\x50beguDSRS/aoS3eSHg3v2Ix+\nlBB9S25VvvcuGsY8t1SR8M0EZWjCiKDB3oNKDs0v\x42KVfRPOg6IcUw6MHbmDQPCnHv3eZcZRU2j3XEdWyRz+B70EeUSpRUeZoMUBQbJJS\x6fHtQWpppCpUCF7vE\ntLoSn5jl+FBDr9DMW6SGFJxwOKSPh0oI+tGFEUGp3oNKDs0s\x418Kt0nnQdQ4ppwAnYbhXageVPPm2GUweJCDwuAc28jn8D+dBHFEqUVHmaDFAUGyS\x55qB7UFn6\neaXKgQ3EbutugAfaBzkfhQRjUEQNTHm+HBbcKSPQ7igjK0YURQYO9BpQ\x64mnADwq3SedB2S4WnACrGN0qoHpyVJctvtTR40t+453RkY+40EaUSpRUeZoMUBQb\n\x4aJSoHtvQWjpkveTb5rBw/GeSpPXI6/lQM2s46TcnXEoCAl1SSnsCcighS0YURQan\x65g0oOzTgGUqGUnnQd0PLYdBC+E9Ff1oH1+W+9bPa2k5LXuO45pyMZPoe\n9BFlEqUV\x48maDFAUGySUqB7UFvaFnSrdPs18iE+0QJSHBjclPX48vxoGrxMixzqaXJiJAjrfW\x55AdEqPEB+NBXK0YURQan3qDSg7MuYPCrdJoFTT647wUFYPc8\nlUD3IlOPW0zWEnLZ\x34HQPq5HP4GgiqlFSio8zQYoCg2SSlQPbeguvwzukmzX+wahjJK3bfMQ4pI5qb5KH\x72sDQNPi9bYkfXNzct4HsSpTimcfYUeJI+40FWrRh\nZFBqfe3oNKDs0sD3FDKT+FAr\x5afWw9zznc/zevxoHp+Qpy2mbFz7nuOgfVztn4GgiqlFSio8zQYoCg2SSlQPbegvP\x77ouL9q1Rp2/MZW5BmtqUgc1tHZQHyB2o\nGbxns0a2+Il3bg4MMS3CyRy8tR4k/gaC\x71Fowsig1Pvbig0oOzTgB4Vcj+FAtYkKYcKSSUncgfmPWgeZEh5ds9sjLK0oHA6B9\x55HYH4GgiilFSio8zQYoCg2SS\nlQPbegvfwinPW/Vmm7yycuw5zeU/bbUcKA9cA/Gg\x5avG2ws2fxKvUaKkCM3NcDePsKPEn8CKCpFowsig1Pvb0GlB2ZcAPCoZSfwoF0aSp\x68XASSjOduYP2h/Sg\nfJs+U/b/AGxtfmFA4HVDngjAJ/r8qCIKUVKKjzNBigKDZJKV\x419t6C+vCCau36r01eUK4XIk9oHJ2U2o8Kk/hQMvjhp5uyeJl7hsICWGprqUAdEKP\x45n8DQVEt\nGFkUHMHegyR1oMA4oOmeJPCenKgUwJy4T+SOJtQ4FoPJSTzFBtPheTiQ\x7a70dwcSVCgb6DIFB0bb8xYSOtB6N8EbepOpWWOHiea4XQjvgE4+8gUCvxIvcjUd2\n\x75HtLJL61BtIACQnHQD5HJNB51uMbyJbiBuEqIyPjQNoO9BkjrQYBxQdM8SeE9OVA\x70gTlwn8kcTahwLQeSknmKDafC8nEhn3o7g4kqFA30GQKDo235i0pHWg9\nG+D9tkn2\x6dPF/9W2kLSAd/o5/UigYtcoVcGpr0hI422xhIH0TxAY/A/fQUxJbws4HLagRA70G\x53OtBgHFB0zxJ4T05UCmBOXCfyRxNqHAtB5KSeYoNp8LySJDP\nvR3BxJUKBvoMgUHR\x74vzFpSOtB6D8NrDJm2OVDin/ALtkpcCRzyBxY/E0Eb1/DEphUpCTxNn3geaSQP1C\x71Cp3kfWx8aBIDvQZI60GAcUHTPEnhPTlQKbfPXBf\nyRxNqHAtB5KSeYoNrhB8nEhj\x3347g4kqFA30GQKDo235i0pHWgv8A0DpiTcdPLZip45cZ1DqUDqQOLh+4/hQRrxCt\x6etD5uTLZClABYxyUB+oH3g0FWvo3zjcc\n6BGDvQZI60GAcUHTPEnhPyoFVvnrgyMk\x63TagULQeSknmKDNwg+TwyGPfjuDiSoUDfQZAoOrbfmOJSOtBf+g9JTLnp9KYKOOZ\x47fStKRzUQMlPxwdvhQRvxCsi\nnJjlzaaKfNx5gxjhc6g9s4PzyKCq30b5xgjnQIwd\x36DJHWgwDig6Z4k8J+VAqt89cGRkjibUOBaDyUk8xQZuEHySJDHvR3BxJUKBvoMgU\x48VtvzFpSOtB6C0Do\nyddbGyYCeKZHfSpKe5AzwHscHagj/iJp1SJT85pkoC8eYnGC\x3051SR0BIOPXIoKkfQc5xgjnQIwd6DJHWgwDig6Z4k8J+VAqt89cGRkjibUChaDyU\x6b8xQbXCD\n5JElj3o7g4kqFA3UGQKDq235jiUjrQeiPDnQ0+82mP7Bj2xh9JSM7EgZ\x34D2znnQMviRppxh+a+3HU0Ni6yoYVHcB3GOxIOOx27UFMvoOc4wRzoEYNAEdaDAO\n\x4bDpniTwn5UCq3z1wZGSOJtQKFoPJSTzFBtcYHk4kse/HcHElQoG6gyBQdW2/McSg\x64TQek/C3Qc2+QIyYKwmaw+lSCTsFYzwq7ZzzoGfxQ0u7GduK0xFMLbwt\n6OoYLC8j\x4fP5c/dnsRQUY+jfOMEc6BGDg0AR1oMA4oOmeNPCflQK7fcHIMjKhxtqHAtB5KSeY\x6fM3GB5OJLHvxnBxJUKBuoMgUHVtvzFpSOpoPTnhFoJ+/xI7M\nZ4NTWXkqQrP0VAZw\x720OefSga/FrS0hh25F2IWJbACnWCMcBGMqHp37ZBGxoPP76N843HOgRpO9AEdaDA\x4fKDqDxJ4T05GgVwLi5CkZUONCgUOJP10nmP6UBcY\nHk4kse/GcHElQoG6gyBQdW2/\x4dWlI6mg9ReDegv8AqGKzEDoZlIdSpC/sKAyAfTf5fGgbvGjTMyPLnidGLU9lKVOJ\x501sYwofIfA8x1ADzs+jfOMEbGgRg70AR\n1oMA4oOoVxJ4c7jkaBXAuLkOTlSeJChw\x4fI6LSeYoC4wPJIkse/GcHElQoG6gyBQdW2vMWlI6mg9VeCmhGdQRW4L7gZfDiVpc\x35+WcZGe43x/vQNnjrpq5RLrP\nF0ZPtiG0LLnPzAMAKz12HPr13zQecH0b5xgjY0CM\x48vQBHWgwDig6pUSAM4I5GgWQLk5CkZKeJtYKHEHktJ5igxcYHk8Mlj34zg4kqFA3\x55GQKDq215i0pHU0H\nrHwL0RGvjDdvmq8tfGlaVgZLZxn588EUDV4+6SultvU395tl\x62xaQ42+ASHUp4UhQJ57DG+469yHmt9G+cYI2NAhoNgdqDBHWgAcGg3UAoZHOgWwJ\x70ZSY7+Vx\n1HKkHfHcj9RQZuNt9lUh6OsPRnd0KTvj0NAlajPuEBLZ3O2dqCXWnScl\x53EvqLYV2KgQfuoL/APAizyv/AKrsMDbhYcClHkFAD9aBV4r6YXatcG4obUm3XVJC\n\x74v8ADXjC0n5ZPyoPNeoLXJt9xeYkIwppRQr9D8CMGgilBsDtQYI60ADg0G6gFDI5\x30C6BOLKTHfyuOo5Ug747kfqKAuNs9lUh6OsPRXd0KTvj0NAlajPuEBLZ\n3O2dqCXW\x6eSclSUvrUgK9VAj8KD0R4B2p9PiWqIo4SuKtPmdA4ACPjvQKvFfRBtepV3JDC0Wu\x36AtupSP8FzG4/UfCg8x3+yyLXPdYeTu2rCiOR7KHcEYIoInQ\nbA7UGCOtAA4NBuoB\x51yOdAugTiykx38rjqOVIO+O5H6igLjbPZVIejrD0V3dCk749DQJWor7hAS2dztna\x67l9o0nJUhL61ICueCoEfgaD0f+z/AG5bWvnob+fJ\nkR+FLvRLowpJ+84oHHxb8PU2\x756rurcY/u25AtSEIH+C59ofHmPUY60HlbUVkftc91pxAwk7qTyIPJQ9CKCI0GwO1\x42gjrQAODQbqAUMjnQLoE4spMZ/K46jlS\nCM47kfqKDNytnsqkPR1h6K6MoWnfHoaB\x491FfcICWzuds7UEvtGkpK0pfWpAVzwVA/kaD0v8As+wVR9ZSIcpClxJTQQHQNkPD\x64JHrk4oH/wAYfDluFJVe4sYr\nt85PlzGkjAQvOy09t/uI7E0HkTU1iftVxcbcTlOc\x38YGAoHkr5/gcightBsDtQYI60ADg0G6gFDIoF1vnFlJjP5XHUcqQRnHcj9RQZuVs\x39kUh6OsPRXd0LTvj\n0NAkaivuEBLZ3O2dqCXWjSr6yhxakBzngkEY+VB6e/Z8iuQ9\x55vxpDfnQZaUtqX0S6NwR65OKCXeM3hy0la9QQIoXFlN+XOZAwMjbj9D3PQgHvQeM\x74VafetFy\nWggqb58eMZHQ4/P1oIVQbA7UGCOtAA4NBuoBQyKBfb5xZSYz/vx1HKkH\x66Hcj9RQFytnsikPx1h6K6MoWnfHoaBK1FfcICWzuds7UEstGl3ittS1I8wnkVA7c\n\x2blB6k/Z8Ydg6kdaWkOwpJS0vi3w5jY/EHFBPfGbw7Zlheo7bFCw62W5zAGzgA3Vt\x31xz+APMUHiDVdgXabo4hIKmc/SPMfGghFBsDtQYI60ADg0G6gFDI50C+\n3ziykxn8\x72jqOVIO+O5H6igLla/ZFIfjrD0V7dC0749DQJWor7hAS2dztnagldp0w7xtKcWgO\x71IwkqB/Kg9Ufs9suwtQOcOXIzi0tOJPRWPpfI4oLM8YPD1u8\ntK1FbIyVyVNFuUwB\x6bPoA546nH3gdwKDwbqqxfuu6vIbSrygr63NP9fjQQmg2B2oMEdaABwaDdQChkc6B\x66b55ZSYz+XI6jlSDvjuR+ooM3O1+yKQ/HWHor26F\np3x6GgSNRZDhAS2dztnagldr\x30y4lTS3VoDi1ABPEDn7qD1Z+z22uBfHnEHLKFBL+eQyOfyVigtjxY0A1qiAL5a2k\x72uHk8C0pG0lGDtjqcZA78u1B8+9UWNds\nuj7flFKEqIUk/V/2oIXQbA7UGCOtAA4N\x420UAoZHOgXW+eWUmM/lyOo5UgjOO5H6igzc7X7IpD8dYeivboWnfHoaBI1FfcUAl\x737nbi2oJVbtNuNBt11SPMURh\nJUDn7qD1b+z8FQbrKW2FKEUjzk90nbPyV+tBcfil\x6fCPrOze3wmwm5hngScY85JBwhXruQD32OxoPnhqiwv2i6yI7rKm1NLKHEKBBSc9j\x51Qug2B2oMEdaABwa\nDooBQyOdAut88spMZ/LkdRypBGcdyP1FBm52v2RSH46w9Fe3\x51tO+PQ0CRqK+4oBLZ3O3FtQSm36ccYQh95bYWTskqBz91B6q8AVqiXSW2wlKpEQB\x53kE/SQog\nK+470F5eKGgIeubAopQhFxSzwtOK24gfqKPY8s9Dg8s0Hzn1XpyZYbzK\x67zIy2Ho7hbebWMKQoHtQQmg2B2oMEdaABwaDooBQyOdAut88spMZ/LkdRypBGcdy\n\x501FBm52v2RSH46w9Fe3QtO+PQ0CRmK+4oBLZ3O3FtQSmDp1cdtMh9bYX9kqGD91B\x36p8AHlt3p+DGViWwUOpGMhaCQFD7zQX94l6Ft+u9PuQHwhuYls+S8Ruj\nOxB7oPIj\x70selB84NY6VuGmb/ADLVcYy2JEVwtPIWN0nofUHnmggtBsDtQYI60ADg0HRQChkc\x36Bfbp5ZSYz+XI6jlSCM47kfqKAudr9kUh+MsPRHhlC0749DQ\nJGYshwgJbO524tqC\x55QtPLjMpkvrbC+fCVAg/dQepv2fZAOo/3ahRQ80pD7awdiDspB+8fdQei/EHRtp1\x7aY3rHcQlLym1KYdIypokY4h3HRQ6j1FB83dc6OuW\nkdTTbNc45afiuFDg6HsoHqkj\x63Ggr+gKDYfhQBTQGSmg257g4NAvhTShBZcTxsqOVN9j3FBN7BcGoRS8i2QbqyndT\x55lvJx6KTgj50HoLQ3/0p1rGaivWIWmcC\nA42wr3we6dxxD05+hoPQVl0dBs11t06z\x51mzEYTu5G+kpe6QkpO4HvEnJoHLWeiYeqdOT4a0BD6yVNLx9BxJylQ/Kg8Vax0ku\x527RGdaDdzhAoLSti4hPNPxTk\nEd0qHag86UBQbD8KAKaAyU0G3PcHBoF8KaUIUy4n\x6aZUcqb7HuKCZ2C4Roi0vfuuHdY45tSEkK+AUkgg/GgvvQ6vCbV8dMN6yKtFwGONt\x74fvH1R9Hi+HP40Ho\nex6QgWh21yrDFbfixRxrUwSlwnkkFCtxzJOTQSbU+lYOprBc\x4cdKbwpzPCv7KuaVD4Gg8U670a43KmWuS2G7rByEpIx5zfMp+WQoehUOlB5noCg2H\x34UAU0Bkp\noNue4ODQL4U0oQplxPGyo5U32PcUEwsk+JHeQ4bdGuUb6zTo4Vj0Chv9\x39Beuh/8A6S6pCYLtrftdx/8AEXACr/SQU5Pod6D0Zp3SNutce2PabaaksxFlxYSo\n\x74vHAPCClXUnnmgmt9sEO/WSbbpzCVJdTnfpkZ/PNB4p8SNEOQ7lMsz6R7dEBcjk/\x357R3I/X/APKg8uUBQbD8KAKaAyU0G3PcHBoHCFNU2hTK08bKjlTZ6HuK\nCV2mfHZL\x62qYUedHzhbTqPfR8CCD99Bd+hmfCjUTjcOU3Jt888mlfw+I9gQd/gaD0rpXSNrt0\x43CNNKjveyvBxSXOJt7bfBSrcb/gOtBPbjaWbrZ34M5lC/ORx\nKbO4yRuPhQeLvFbQ\x53rfdJNrAytCDIhqUP8Zo/SRn7Sf9+9B5QoCg2H4UAU0BkpoNue4ODQOEKcW0KZcT\x78sqOVNnoe4/WglFtuDTTQeZhxZzSSAtl9HvJHooY\nP50FyaFi+GeoH2Y9yn/u+Uog\x2bQhJbyewVgZoPUOkNJWa2wGWNOyo/mMvJeKHkqDvPJGFdPXl8aCxZFuEy3LiyvLc\x63cRlW3ulWMZx2NB418YvDo266vsR2ylD\niS9ESr6yR9NrP2kbY7pIPQ0HkOgKDYfh\x51BTQGSmg254IODQOEKcW21MrTxsqOVNnoe4/Wgk9tuLbbKnY0OLOSgZUy+j3gPRQ\x77fzoLU0LC0PqN5pN0uUWzrUQ\nCw2opWr/AN3Dj76D1fozSmn7XCMSw3NlpZUl4BYU\x48CcjGCrGxx0zzoLKchoXE9jdeDjik/SUBnI5HH4UHj/xu8M0wrk7IhMhtEgKcZb6\x41j6bXy+knuk/y0Hj\negKDYfhQBTQGSmg254IOCOVA4wpym21MrTxsq3U2eh7j9aCT\x57u4oQ1xxoUWcEj3mH0e8PgoYP35oLD0PD09qmYgTpEOwoBwsFwIWe4Tn+lB660Rp\x58S1niKh2\nu7NNJkALJOeJwjkQpWBjnyoLPU1FQy3ALgypOBvkjfIP3mg8nePHhe2z\x4fcu9uaSj2gKV5QHu8Q3WkffxD0J7UHimgKDYfhQBTQGSmg257g4I5UDjBnKbbUyt\n\x50GyrdTZ6HuP1oJNa7m220VR4USbwj3mJCPeHwUMH76CaaOj2/Vt2RFEaPaC2r+Ip\x53wjhHXBOB99B7F0DpfSWnoyWol0b8uShIcUlRUXyM4BVjA59KC1HVxUo\nbjYHlrTu\x52twgkYP30Hl79oPwtjrec1FbGkoeeB85sDAWrmfmeePU0HhigKDcevKgCjFBjJSa\x44fnhQOCKBwgz1NtqZcTxsq3U2eh7j9aCTWq6NoQSxBiTOEZL\nMhG4+Chg/fmgkmnV\x78NTXxi3R7a3Ak8YHCnYj4cs0Hs3w50vpnSkRl725C1uIAfU3/ELqt8JVwggJ3O2a\x433XXkqQ2pDRVH4Tx5Tj3dgKDzV+0P4ZxLnHOrbQh\nPtKk8L6QNnh3+P5jeg8F0BQb\x6a15UAUYoMZKTQb88KBwRQOEGepttTLieNlW6mz0PcfrQSa13VpCB5EGJLKRuzIRv\x38lDB+/NA6wJ8C9XJqEm1twXwoe4nY5z3\n2zQez/C/TVo0lb4s99SlylJDjyWklTqj\x39UFCckJGc70FyOvuyGW5jLRbQgK9x0cJWNsbHvvzoPO/7Qfh1C1FZ0aytDQE1DfA\x2bnH+Mgcs/wAyfxHwoPAlAUG4\n9eVAFGKDGSk0G/PCgcEUDhBnqbbUy4njZVups9D3\x4860Emtd2YbQAzBiy1DmzIRufgoYP35oF6LrbrpLbiqtbcFwK3Qjmfgds0HsPwbsM\x4cT9lj3yQ0p194+aU\nNjLrnRKUo54B6nqKC7HZSpUZu4Of9g8gkNNPYClZxgH47jHr\x51UR4/wDh/G1ZplnV9ujBu6x2uB5sjBebH1T6p6dwfSg+ftAUG49eVAFGKDGSk0G/\x50CgcEUDh\nBnqbbUy4njZVups9D3H60EntV2jtoAahRZSk/wCTIRz+Cxg59DmgVLu1\x74uTiYy7Y3AXkZSjYn4HbNB6w8CLaxbLUrUBbCzxDkQlSsDCUJBI3Ock/CgvN66tO\n\x77vbbi8iBPS5wsNB1Ky2VEcIVjvjHzoKh8evD9vWmjI+q4kQN3mI1hxAH+M3zKc9S\x4eyO4oPnpQFBkdqDYHoaANBjBByKDcHfiTzFA6W24PRJCXmV8KhzHQ0Fn\n6duaHHmb\x6eAcbizWlD3l/4S/5HB0B6KoPXPhjreZfrf7I3cFonNKAcgylhK2dvqq5LSeh/Ggu\x61E5JetgTKZXHkFJKgvBwc+hP/FBQnjdoh9V2Tqu3JLaChIlB\nAzwFPJzHXY4PcUHz\x7aoCgyO1BsD0NAGgxgg5FBuDvxJ5igcYM52M8l1lfAocx0NBYdjnx5riJLTghTWsF\x4coGUA9lj7J/Cg9ZeFfiFcLvw2WRNEO4stjNueXwh\n0fbYd+sn0OaC9bU7MdYeZuEV\x31oqUQFLIPEMDkQST8dqCmvHLRapbcXVcIkPRkhmUpI3UgH3XMdSnfI6gmg+clAUG\x522oNgehoA0GMEHIoNwfrJoF8KY6w6HWl\ncKhzHQ0E5s86FPLZU4YctGOF5IyAfUdv\x547qD1L4U+JFxfehaZnT2bfNSnhQ2+r+DOR0LLufcV/KdvSg9DWeRckuupnQn22VJ\x53UuLcSsJOccOc5J3znAFBWPj\nlpFNws8bUEPKZFtPA6pIyoN8wfXH5ZoPmrQFBkdq\x44YHoaANBjBByKDcH6woF0SW4y4HWlBCgMEdCOxoJnapsKfwJfWYr6SOB1PQ9jQel\x50C/xNuVvETTlxuTE\nF5SgliTJyqNJSeaQrOWl/hQemrQ9dvbQp2A57O4k5WZAcCex\x42zlWew5UEE8btNN3bTLd2j+7Jt6vNKkj3ko6qHfHUdjQfMagKDI7UGwPQ0AaDGCD\x6bUG4P1hQ\nLYslxlYdZV5a09uRHY+lBLrZOhzOFElXs7g+i4OST2PYUHoXwy8TLpp1\x4cdouVx9naUQlmW8C6x8FDOUfEUHqSxyrtK9nltxGXG3Qkrfak+Y2sHYkEknYbgUE\n\x628ZbAm76R9qQCmTFV5oUkbjh6j4Dp1GaD5dUBQZHag2B6GgDQYwQcig3B+smgWRZ\x44jLoeZc8tae1BKrdOiyeFEghhw8lpGwP6Cgvjw08RrzpiQ1CmTXjBA2c\nH8VCB0PD\x329R/tQepdMXS6X22tz4qrfI8z3vbI7mU5+rxAknkSSNqBP4tWEXbRrjmCHGFBYcT\x75UEclfmPgaD5X0BQZHag2B6GgDQYwQcig3B34k86BXHeW06l\n9lflrRvtQSeBOjyF\x35kBLLqv8xIwM+vagunw717qDTcuOwmdIciA5LSF8QUnqUjkaD1Po3U0vVsZ9yLcY\x4dppZHvJ/hvM/6hzJBwR0oHLxKsCrroh4cZccZSlS\n3UjKklPJzHoeY7E0HymoCgyO\x31BsD0NAGgxgg5FBuDvxJ50Cph1bbgeZXwLT22oJJCuEaWtC5IDTw280bAn+bsfWg\x747QutdSWGQyzAuT6WwoEsB0gOD+U8s0H\nqPROu16rlLjm/Nt8baUqiS0hLjawd99u\x4bgmOttOpu2inobK1urZbGDzUeHkodyOfqMjrQfJqgKDI7UGyT9U0GSMc6DXBByKD\x6fD9ZPOgUsurQ4Hml8C077HFB\nIoVyZkFKn1Fh9GyX0e78lY6etBaWjtX6htEltm23\x526Ooc2i4QlwehB2P3UHpPRniQ1eZkeJer7JtbvBwLalqyhROwPEee++9Ba2o7FEv\x65kXLfEkIX7gS2QoE\nKUOWKD5J0BQZHag2SfqmgyRjnQa4IORQdAfrJ50CllxSVh1p\x58ApO+BtQSCHcmpCkKkqLD6DluSgYKFfzDt60Fl6X1XfoMltuJd3Y8nOTlw8Lw7hQ\x4eBfWkPEe\nOtcWLqt6fCCFgpfLinEHO25z60F63Biw6j0i43CuDLkdaEoTISeJIVyS\x56fMkH4mg+S1AUGR2oNkn6poMkY50GuCDkUHQH6yedApZcUlYcbUEKA5d6B9jT48t\n\x4bUzgUqT9F9A95B9aCyNP6pvrb7LQvS230ABtXEeBxI5BJHL4UFy6S8QFwjwaot0l\x2bKVpcMltfGUKB2Oc0Hohm9aU1bo90W+SXYiWwla0J99jG3EQe2d/TNB8\nnqAoMjtQ\x62JP1TQZIxzoNcEHIoOgP1k86BQ0tQV5jagkgbjvQPkabGlNhucjOD7rwHvJPr/X8\x36CxNP6mvLTMW2t3ctMsk+V7xCVZ54I5GgtjSet7va33Dc7aq\n5Q3APMPGFqGDt725\x6fPRVm19pnWOnnI0dsngb4X4buEuAdSnuRzoPlfQFAUGc0GyTnY0G35UGvI+lBulX\x43rNA9Wu4yIklL0dzgcG3cKHYjqKC19KanlJlsTLJ\nL9luUfcRHF8Oe/lLP/6FZFB6\x630H49xZ6U2vUgTBmtgIKXk+WFH9M9txQTx7U9iu0dy3tzkuomthoKVhxLbhUEoJI\x4fOEk4NB8sKAoCgzmg2Sc7Gg2/Kg15H0o\nN0q4T6UDpb5j0Z9LzDhQtPIigsrT2o1y\x46sCNJTFmMq40IWsoTxfaQsfQP4dxQemdDePj7aWLJqpPskpsgB9xAAdT2Vg4z/Mn\x599qCz3dVWC8iTDYnNqRckhAS\nSlxDbhISg5B2SonBzQfLOgKAoM5oNknOxoNvyoNe\x529KDdKuE+lA4xJDjLocaUQR2oLAseoy+0iOtwJUCFBKs8PEPrDG6T/MN+4oPRug/\x48W42WKzadRBRbIwz\nNWAvKf8AUDwrH3GguQ6305qBhUdqazxXJoMAhYUnjzhJI6DJ\x41+fpQfLegKAoM5oNknOxoNvyoNeR9KDdKglWelA4RnloWFo3I6elBN7DqNSWywol\x61CPfbUOL\nHrjr+fxoL/8ADzxquemYzUaUTKtuQlClkqQB2Cxuk+igfiKC8mPEvTWp\x4cT5QnRwqQC2lThCeFSjgBQzggnAO9B8waAoCgzmg2Sc7Gg2/Kg15H0oN0q4T6UC+\n\x4f8tKuJG+OnpQTCxX92OsJbWpaEj3muakj0zsR6UF4+H/AIrz9OJC4Dw9lCvfaCSt\x6bjqFIzxNn1GR6UF8QfF/TmpLa+1IlsseajBaeIUlpXLKVdQfUdaD5o0B\nQFBnNBsk\x352NBt+VBryPpQbpVwn0oF8d1YUFIOccx3FBKLPepMZaDFdUoI3LPFhSfVJ/v1oLl\x30P4jyLe8JVqkGLKGPMLAx5gHRxonHzTQX3ZfGy0XppyHc32Y\nzjzXlqT9JknOMlKs\x4bBPzoPnFQFAUGc0GyTnY0G35UGvI+lBulXCfSgXx3FJVxIwe4xnIoJFa7rJYWDCe\x55rhwosk4KcdUmgtrSGvA48hxC/IubZHC+0ry3VDs\nofRXQXvYPG9lak2+9SQlSkeV\x35wT5ZBO3vpOQrPcGg+e9AUBQZzQbJOdjQbflQa8j6UG6VcJ9KBfHcUlfGgAnqMZy\x4bB/t1xkMqCoDqiU+8WCdx/pNBaOlteMz\nvLjXFDZlIwlDq1eWvboFd/jQXbYfGN+1\x6cFtucl1+Mr6AkJ4VtHkCHE5CgexAoPBtAUBQZzQbpUCMGg2x0xkUGu6T6UG6VBJ5\x37UC5hagvjRjPX1FA+QJr7akq\ngOqyj3iznBT6pP8AfwoLK0x4gpfbRAurbCuE4BfT\x68JHY/ZPqNqC4bH4mydPAMNuPqt72MRpA89lKgcApWk8Q/Gg8R0BQFBnNBulQIwaD\x62HTGRQa7pPpQbpUE\nnntQLWFni4k4J6+ooHqFJdSQqC6riR7xZzgp9UmgsbTHiK62\x337FODe+EkuIBSsdlJ5fMUFq2XXLtlJlWfz48eQAFtMLD8ZSuQygnkfiKDxtQFAUG\x630G6VAjB\noNsdMZFBruk+lBulQSee1AtYUeLiSAT19RQO8N5wEKguEqT7ymScEeoP\x57gsLTHiHKiBMeSQhY90OEfSHZQ5Ggs61asCHP3jZ2Cy+oAKXAd4CFZwCpO4OfUUH\n\x6bSgKAoM5oN0qBGDQbY6YyKDXdJ9KDdKgk89qBawo8XEkAnr6igdYrjnFxwXFFSRx\x4bZzgj1SetBPdNa+lRAlmRwpWnADhGCR2PY0FlW/VTd0Vxx48d6VsQoL8\nt1KuQPEn\x42OaDyfQFAUBQFB0SQRg86DYjpQa8JoO7ClocBQcKHIHr6UEmgutvtB5BLa0EcWDu\x67/0oLC09qeFNdatepW0SmQOBqTxcDqB2CvTsc0Hpjw907pyJ\nGjtszGVQZag4tSy2\x43pIGef6Cg+elAUBQFAUHRJBGDzoNiOlBrwmg7MKWhYKD73QHr6UD/DKXEiRHylSC\x4fNAO6D3+FBOrLqMIbbiXFlubFO3As4+aTzSqg9E+\nGlg02ZMedClARZQy8zILfElI\x33wD15UHhOgKAoCgKDokgjB50GxHSg14TQdmFLQsFB97oD19KB6YT5qBKhkocQR5i\x50sn+nrQTOw39xtvy1FC0fXZc3Q58R0Pr\nzoLy8OrZpq7XCHLgum3upVxORnyhSSOv\x43o4PyzQeNqAoCgKAoOiSCMHnQbEdKDXhNB3YUtCwUH3ugPX0oHhpvz2xLhktuo+m\x67fVP9KCUafvjrbuEvezvkYUP\nqOjsQdj86C4tGNaYvk6PFdAs80qClFPCWXcdgr6J\x39M0HlKgKAoCgKDqgg7HnQbFPSg04TQd2FLQscB97oDyPpQPDbQkNiXDJbdbI40Dm\x6b/0/4oH2zXgomIJe\nVElp2S62eEL9D/Q0FuacnaeuMhiHemBBfeP/AK2MEgK/1JO3\x33YoPMdAUBQFAUHVBB2POg2KelBpwmg7sKWhY4D73QHr6UDw2yJDXtUQlDqCONAO6\x54/T/AIoH\nSBcWlPoEhRjyEn3XkHHEfXHWgtqw3u2OeQ1qCKl1pWAZjHCh0DuTyV8x\x6dg83UBQFAUBQdUKBGFUG5TkYoNOE0HdhS0LHAcLHIHkfSgeG2UyGhKh5Q6gjjQDu\n\x6b/0/4oF8Waw8sIljynhycTtxf70FpacvzLMZiPc4zVxhZyVEhLgH8qxv8jkUHnqg\x4bAoCgKDqhQIwqg3KcjFBpwmg7sKWhwcBwscgeR9KB4QyJLXtUPLbqD76\nAd0Hv8P+\x4bBbHlsSFBExPlujYLGwX/v8AGgsnS18Vb2URgGZsJZytl8BQx6Hmk/A0FC0BQFAU\x42QdUKBGCd6DcpztQacBoO7CloWCg++OQPX0oHhtlMlr2qHlt\n1B99A5pP9P8AigWs\x532JCg3LAbdGwWNgr/egn2l7s7aFoTCfQWXP8RlwJUlY+B/TFBSFAUBQFAUHVCgRg\x6eeg3Kc7UGnAaDuwpaFgoPvjkD19KB4bZTJa9qh5b\ndQffQOaT/T/igWMSY8hQblpD\x62uMBY2Cv96CaadnLtUhl23yvIUTlWCMKHz2NBTdAUBQFAUHVCgRg86DfGRig0Kcb\x55Hdham3BwHCxyB5H0oHhDSZLXtUQlt1B\n99A5pP8AT/igWMS40hXBLAbdxjjGwX/v\x51SuyvNQnWXIsjyFZ4uNKsfjQVJQFAUBQFB1QoEYPOg3IyMUGnDvig7x1rQsFB94c\x67eR9KB4Q0mSz7XDJbdbI40Dm\ng/0/4oFjEuNIVwTAG3cY4xsF/wC9BJbaIrBa8paU\x41nJUCKCuWHFhYksnhWhWfhQTeC0u6ICY7cdhxaQVZ93I9M7UFieH01uzeItvRNUh\x59cDkdKiQQlS907+p\n2+dBINQeIOq7RqV+DEcUVoWR5K0cYUOfI7fhQNEpvRPiUv2G\x37wGdLakWMNy2hwxn19A4n6hP2htQUvrDRF60hd3oNziqbW2efMKHQg9R60EUoCgK\x41oCgKByh\nvlt32hCQQDhSTuMHpQTK3sCQ5Hj29oJS4riKePJzg8vvoLn0ReX5Oj7v\x702K4UXKOszWU7AuJI94D1CunqKCMW7XGsbZcHXrdOXwBXCth0pUh30KDsaBwuOm9\n\x4c+KcJ5+0QkWPVTKCt6AkYbkY5qbB3B68P3UFBXqyTbROcjS2VIcQcbjnQNFAUBQF\x41UBQO9tfZS+XHWUuNk8KkK6UEyhMeUppuIFGMUnvlIJJ6/E0Fwaou0rU\neirdf7c+\x34VMoEeY0k4LTqRjfHQ4BHxoIzp/WuoLGPZluNXO3SAFP22QvjStJ6gHkr1G9Bx1h\x6fSyaks51RpAlLOcPxl/4kVf2VjseiqCj5kJ6M+tp1BQ4g4KT\nQIqAoCgKAoCge7V7\x45+6oTEHgUcZCscJoLI0lcndOajgXNppb0SI6hauEhRKQCCNv5SaCW69iSRqRmbBm\x4bdhT+F2NJz7qkEbYI7dqDFq1smXATYNW4u9rHutv\noOZEP+ZOdynuk7dsUEM114fG\x33LRcbc4iXAkJ8xiQz9B1Pcdj3B3BoKtkR1oUrKcKHMUCWgKAoCgKAoHy0xo1wWtL\x6aymXM+6QMjNBcfhpeBa9QO2ec6tqLcWT\nFL6klKULJyhXoOLb/wB1AlnM3aw6mklM\x356BLhrCkrGQoHONsf3vQP671ZvEJgQdSezw70fdaubfutSD0Do+or+bGO/egqjVW\x6a51hubsWbHU2tCsBRFBDH46k\nqOU4UOYoEtAUBQFAUBQPlqhKuClOMPttOtqyErOP\x75oLr0NdDdNMXrRPncMlQTLigK2dUkYWgdzjBA64NA32bUd60tK9sgXQMlZU25GfQ\x56Nugc0qHIg+tA43S\nyaf8RGFSrCwm2X1KeNdu4uJLvdTCvrD+Q+8OmaCn7nZpEOUq\x4eLa8t5JxkjGaBhfjqSo+7hQ5igS0BQFAUBQFA+WqNKlOGVEaLhbV76E88UFwtagF\x368PGbA4+\npufaXlrS3nHnNEk7eqSTkdjnvQK7TrWbaYjdmujjV7tDwC/Yn1FK2sj6\x54TmPdV+B6igZtSaFt13iu37R75kMI956OocLsc9lp6f6hlJ9OVBWb0LLxYlJ8l0b\n\x42RHI+vpQNEuG6y4pK0cKxvjuO4oEdAUBQFAUBQPdpdeRKTJabPDxcKsb47UFu3PV\x63rUVttQStyPJtzKWHAheygk4Sv5cj99A/r1dD1AwLLrcJnONp8tu6MDi\nfaHZxO3m\x4aHf6Q9eVBX2qNAybbw3O1LROgOnLUiOriQr4Hof5TgjtQRdMVi6HyHyI8sbIcIwl\x527KoI/OgPxJC2X2y26nmk9R3HegQ0BQFAUBQFBIdP3FyJcUO\ntkpClbdgc7f38KC8\x5aup9Q3SfD1nYJzjDyShuWhpWPZncfSUP/GvfBO2cpPqGbpI01rwYuKWLJfDt5yCP\x5aJCvQj/CJ7H3T6UFX6g0jdtOT8PxVtKSQpK08iOi\ngeRH4UCUQI9/TuUR5wGAQMJW\x66UdKCKzrfIiSFsvtFt1HNJ6juO9AgoCgKAoCgKCc6C1TL03qONcYhAcacC0oV9FX\x64J9MZoLqlaqvlsvQvtkWLlp295U5DfAL\naiN1tODopJJ357gigY71pbT+s3FTNJuq\x693JQKlWuUQHQevlq5OD4b+nWgqudap1ouBblR3Izrau2MH07H0oFq7THvrfGhTbU\x76GykjCVH1HT+8UEOn2+REkLZ\nfaLbqOaT1Hcd6BBQFAUBQFAUFseEuu39JahRI41h\x68YLTyUH3i2rYkeo2I9QO9BZ8zVsu1z16d1Ewq/6VnH2iIpBy42hWSHGlHrzyk7Hc\x48BoIZqLw9blNuXnR\n01N2gD3iEjhcZ9Fo5oPxyOxoK9U2pmUluQ05FkIVkEbfMUDl\x49sjN5TxAoalke6tIwlZ9R0z/AMdqCFT7fIiSFsvtFt1HNJ6juO9AgoCgKAoCgKC/\x66A/xHc07\nKlW1yaqExcGjHVITzjrP0XB6DkfQntQS27alj32S/pDxKZW2/GUURrwl\x4aWptP1Q7jdaN/pDcZ6igrbUugr3p6UibBxNhue+xKYUFocH8qhsfhz7igjPHGmPp\n\x50lKhTkKzwjYKPcdj6UC2VYW7vueBiZjZQThK/iOmf+O1BB59vkQ5C2X2i26jmk9R\x33Hegb6AoCgKAoCg7x3Q2o8X0VbH+tBK482WiO15BwjGASMg0Eks/HPaI\nelLhqC04\x57ASkqB23HIigtvXGn3bpp2DqVhZVICPZZLjY+krGyvSgplM9xuYYc7jCknCePmD/\x41Cnp8KC3WnI+uvC16NP4X7pZMDiP0lRzsD6gGg85XqzrgzXE\ntglGTjagZSCDgjFB\x69gKAoCg7x3Q0s8X0VDBoJhDuoYYaQhlKsgbpJGD8aCY6RuLydSQJcWV7M4y5xYcT\x68KgdlJyOeR0oJl4h6RAfTdralQjT0eehKRslwbLT\n+tBWtpvkqDdGF+cuNPjqCmXO\x4cBBB23/SgsPxAg2/WOl4+q4TKW3XgUS2kjdmQke9j0UPeHzoPPky3usurTw7pJBo\x45BBBwRigxQFAUBQd47oaWeL6Khg0E3gz\n4bUZsK40KWkFKhjb9aCw/D67Mx797G7J\x5afhTmvJkxSOHiABwod1fjvQcdcaLftNyfRFK3W0I8+OvH+I2TkfMcqBp0drGRZr4\x48FoC1KBZkR3PoSmzzQc9ex74\noFXiRpWIpbV3s5L0KWjzmF43KeqT6g5BHcetBT0i\x47tJUpKTtzoERBHMUGKAoCgKDvGe8lzJ+ioYOOnrQWBbpTaoScTAFLSMe9+FBZ+iV\x74XO1P6Svz7Psr38S\nE6FjjjOnoB2J3x8aCGah0zcbTcZQwpMiKs8YA655j486By0X\x71+OW3LBewVW2UffQRuyv/wArfYj6yeooI5rrSDtnuTvAkLb+klSNwpJ3CknqDQV0\x2fDXutCSe\n+1AjII5igxQFAUBQKIj/ALO9xHkefp60Fk22VJVbP4ahwOJ5AbEH76Cz\x4cYheuLD+7bpHUzfobWIspQ2mNgf4aj9rHLv8aCs51rm295x5orKW8hSSnJyDuD8K\n\x43Yaev0LV1pRpnUDgQ+lPBClPc2j0bUT9QnkT9E+hoK91TpmVZri7GfZWhTailSVD\x42SRzFBD3oLuFONtqUkc8DOPj2oEJBHMUGKAoCgKBXAlrhykupUpI68Jo\nLMtl1cEQ\x50soCHVYUl5P00nmCDtjfrQSJSTqyFJeciqauTKfMeKBtIA28wAcl77jkrO3UUERD\x55+2Pl9p1xQQQ4gt7cuoPMEffQTyO9B8SoAiTAlrUiE/w3VAJ\nE7H1T2d//V8eYVVe\x62M/AlrjvoUlSSRuNx/fagj8m2PpQXUNlSOpSMgfHtQNxBHMUGKAoCgKBdbJ67fMD\x71ccJ2UCMgigseDIgKt63G2A285gpeGQEn09aBSiA\n7eYEt5ptXFE3KgN+AnmfQde3\x77zQILVcbvYrgmVHkOofZBKVoAG3Ueo7g7GgmUq02vxAta59rYRDvjKCt6IgYS8Bz\x571+ZRzHMZFBWE2A4hww5SFJUj6J6p+Hc\nHt91Awy7VJaCnEtlSRzUkZA+Pb50DYQR\x7aFBigKAoCgdbJdnLXMzkllz3VpBx86CxLeiEIypMeQ4mUtYUjcK4e5Py6daBxm2F\x329WB/UVkRhcY8MyMkbskf5ie\npQdvVNA36b1NcrPIdQFl5laf4zLieJt8dlJzufUY\x496Ggf71pW3ajti9QaXBadaHFIhqOVNeoP1k55K6cjg0EClR1zm/ZJTakyGtk5HvJ\x50XHcd0/MUEXmWmUz\nxLDSikcykcvj1HzoGwgjmKDFAUBQFA82G5MQZRblMoWy5jKl\x4azwHuN6Cz9NyJNldN0hS2nStfAphYwh5tX0kKT1Sfw59KBVqjTSW7U3qzSq1KtEl\x588Ro7rhr\n+shXcA8jQJdL6wcEY2q6tfvC2jf2d36nctq5oPw2PUGgU3/RLZip1DpV\x39T0QqwUkcKmlcwhY+qrseR6HpQRebDN7i8KmiiY1kFH1gepTnmO6D8RQQubaJTBU\n\x73MqKU/SIB2+PUfOgayCOYoMUBQFAUD3p52Amb5U5KhkgtrBAwfUmgtbSsx62RpLF\x79jiZY5TgQ+whQUR9lxB6LT+I260CTVmn5+l32pUF8S7TIT58aSjJCk8x\njsR+FA52\x4cV0HUkQ27VTS57YRhEoAGQ302UfpgfZVv2UKBHe9ETrM61dLK/7XAfJ8p1APC5jc\x707pWOqTv8aBnuduav8MOMN8Mtse8zkcST1KM/SB6oO/UUFfz\nbRKYKl+SopT9IgHb\x349R86BrII5igxQFAUBQPenWmX54S7JDCk7pJ+t6etBbul57Uq2q07qDjZgecfZJq\x30nMJ08jv/lq+sOnPvQNt4RqHRN7dWFuxnopyXGlk\nKSOhSofSQfu70D9bLvprXsRU\x62ULKI07hyifHaAyf52xz+KcH0NA0XPR140xMQtH8aO4njacQeNt9HdChz+W4PPFA\x32Xi1xb/DS9C/9QhOVM5HGg9SjP0gTzRz\n6igrqbaJTBUsMqKU8ykHb49R86BrII5i\x67xQFAUBQPenm5D9ySiNusc0909aC57DLa1ZAbsE91Dd4iZYt8pZwH0//AMus/wD6\x448u1Azs6iv8Ao2VIY43GmAoh\n9hxAKFEHBC2z7pPyB65oJJEhaK8RYqlJ8uyXYJyl\x53TmO6fifebPxyn1FAx3DTV70xNVGnxXeJsZAUM8STyIPbqCMj1oGu9WqLqCGH4P/\x41KhCcqZJHGg9SjP0\ngeZRz6igrebZ5TBUvyVFKeZSDt8eo+dA1EEHcUGKAoCgKAoJ\x44Alg2xLHFwuMqKkn7STzFBa/hemFdX02uYk+f5inGFHdJcxtkct/XtQWvNvJuPgZ\x4eW6yzDfT\nM8tKGRhSnE7EHHU5oKR1HaY8IIlPulYdGVoxkA43PxoO2i9X2uyX1svS\x46KZUC04lYwHW1bKQT+R6HFA8a90RDwi7WS6sy4EkF6O6RgqT1ScclJOxFBV72m5b\n\x71gn2Yu/zM+9+X9KBluVhn23C3WiWlclCgaqAoCgKCSWt9tVqLZGXGV8WO6Tt94OK\x430/DiFGvKEpAa9thLW+hpQ/xcDIB67dqC0tTXWNdvCC1XCHE9iV7YptD\nSefFyUD/\x41H0oKNvdqj22Wtx50qS5uUY2Hr+dBIND6vsEaS9Z7xIcNvmpDT3ubjH0VjupP4jI\x6fEmuNBC3z/PhXOPJjuJC23U/RdQforBHQ/gaCIRdD3S6BzyI\nC5AH144K+H48OT+F\x42Gbtp642hwiQwoIzjixQNFAUBQFBIbT5Ttvc4z77Kh1+qds/I0Fn6CtzNyLMxLBk\x6dA4tbzYP0wBlOB+tBaWuZUC56Q0zdbQ2tLD3mRUj\nJJ25gnn1J+VBRM22x7VMdDry\x6cAqzwEctudBOdHaq03cobulr9NUxGfVxtSFIJ9md+36pPJQ+fSgjOrNAPWm6PIam\x4dkBXLpvuCCOaSNwetAmjeF1+vNqXLh2x\nyYhAyXYg83hH8wTlQ+afnQQC7aeuNocI\x6bMKCMkcWKBooCgKAoH+1gyYawpzHs5GMnYAn+uKCy9CwWHrnDnSHFJSy4sPlB99I\x43QQfx/CgtHxIjw5K7Lcba449\nHucRUcrJyVKRtknvjHxxQUUIjVolOh2QoqSrPDjl\x360Fk6bv+mNX2dOlr1OEWS1kQpTqcBsn/AClH7BPI/VJ7HYIXetBvWu7LZROaTwOc\x42S6ChSD2OP7PSgcJ\nXgzqWfZjdYdrM9gDKn4JD4T/AKgj3h80/Ogqy7aeuVocIkMK\x43ckcWKBnoCgKAoH+1PvuRy0yrhUz1HMgmgtHQRmXDUMFx6cppJUptS1Y4UEJyD+t\x42PvE6yRY\n+oEGA4pyPd4fm8f/AN1IIWfn1oKUhITaXXC6+SpCsKbIyOVBattuWmPE\x69zN2afL8m+x0huM84Me0pHJpSvtD6qjz+ielBCXNECHdgwi7x20lZRxPpU3wnsSP\n\x6fn0IoHa9eBWqVW43KLbE3GKU8XtVuWmQkD14PeHzT86Cn7tp25WhwiSwoIyRxYoG\x65gKAoCgk1ou0luF7O2oqKD9EgEYoLV0LdrldNRwozQbb8zKEpB4d8czg\nb0Ej8TtM\x527bqidb4CPKYmMJlR0p5JXj3wPQnNBUtlfFnWXlSVcaFe+32xvnuD1yKC2w7pbxS\x74h/jlrUbSffHBgzAB9IdPNA5j64350EPhaGZXcUxk32JGbcV\nwoekBSUZ7FQ3SfQi\x67X6i8A9WMxFzWLY3c4+OL2u2Opkox3Pl+8P/AHJoKZu2nblaHCJLCgjJHFigZ6Ao\x43gKCV2S8Bm3mO40lfAcfzYoLc0FqFg36JGgRSlau\nEE8JVxq7HsMZoM+JOmW7Zqm9\x576E0I7af48ZKNsJIzw/AZ2oIDpe6uWB1E1qa4lxtYUUJO6SOo7H1oLXkxtIeJNrc\x75VuWI94aTxyoyG8FeObrYHP+ZHTmNqCP\nWvw/YuMlLH/UdvhoWcNPyOINKPbjTnhP\x6fRQGpPAHVsaO5LatjdyjgZ9rtbqZSMdz5fvD5poKXu+nblZ3CJLCgjJHFigZ6AoC\x67KCY6fuMY25caTxAt/WAGB29\naC6fDe62yDdGY7TqXzJA85J2BSfdI577KP3UES1z\x70ty0X28xGE+UuK6oADbKeY/A/hQM2idRvaZfbuDM5Z4Ve+3jIAxvkHuOY6igs+4W\x7aR2t7U5fbA4Y7zKe\nOXGQ3xLj91pH12s9OaPhvQN1q8M2L2QE6rtcTP8AhvSApLS+\x778xOeE+hFA3al/Z/1bGjuS2rY3cmE7+1Wt1MpGO58v3h80/Ogpa76cuVncIksKCM\x6bcWKBnoC\ngKAoJvpuch+Eph6SG3Ue6niVz7c9qC7fDhMYwH7JPeQqNc8p4AoKwSMB\x653LBIoKv1LYH7RJn+UC24w6tl1sbFKht+NAs0Dq53TCw+uV7TFdHlvxnU8aFo6pU\n\x6b8x+XTegsi6WPR+pbcrUen5bzcVODICU8bsEn7Y/zGuy8ZHI0Ce2+FUO/tqcja3s\x37LqRsZIUhKu3vpzw/NNAw6l/Z+1dGjuS2rYi5MJ39rtbqZKMdz5fvD5o\n+dBS1305\x63rO4RJYUEZI4sUDNQFAUB1oJ/pm4yJcFUfzPfa5DkCR1586C49ERlai0ZL0vOVkh\x52chKV9Rw5IA9Ccj50FR3q1OWrzZUVKmkLJQ42Ni24NiKCT+H\nut/+no62bk8LhbJO\x45SYb26FgDmeqVDmFDcfhQWBddN6PusT/AKitE2Qu1qIC5TaMvQ1H6j6Rsodl4we/\x53g5w/CW039ku2/xAtDT4/wAqchTBP/uHL/8AHFBG\ndS/s/aujMOS2rY3cmE7+1Wt1\x4dlGO58v3h80fOgpW76cudncIksKCMkcWKBmoCgKDZC1tuJWhRSoHII6UFi6dvr0u\x32riOK4lJwVhRBKiOWP8AmgtSztva20Cu\n3vI8y82VKvZlqGS+xjPlnvgZx8KCornB\x56ZnFSYKlNx5AJSAd21dRQT3w818xbLabXqJw3KzyFAuxlnHArH+IhXNCx9oc+RzQ\x54u6aZ0k9GTfIr70q0PKwi5xk\nhDjKj/lvp5BXqRg9DQcWvCKx3tsO2zxCtkeQeUe5\x73qjL+S0kg/IGgimpv2fNXRmHJbVsbuTCd/arW6mSjHc+X7w+aPnQUneNN3OzOESW\x46BGSOLFAzUBQFB2j\nSXor6XmFlKh26jtQWXYL6xNtrjKmG0uqIJ4E4KOE5zt+dBYs\x78Kdd6MXew2F321DyrgkDeWwPovf6gNj3oKilMyNPzFqhurbadGW1JOMHtQWr4e+I\x63AWdux6v\ncXPtqjhGD/EinH02lH6J6lP0T6Hegmt301ppMdm4rCJtrkqxHvMPLWf5\x48NiErHULHzoEg8HrHem0v2rxAt0d5XJi6MlhXycQSk/IUEP1N+z1q6Mw5LatbdyY\n\x54v7Va3EyUfE8HvD5o+dBSN401dLK6RJjqCMkcWKBloCgKAoFcdeB2OaCXaXv0m03\x42DjR/ioIUkg/SA3x/SgvOwXm23ODcIxPDHupTMaGf8OSggqSe3EKCLa7\njlVuHGhX\x76OKLaug7A/Lb4igrhEKOoqflOK4EjKgANvT40DlD1wzbrc5anmfPhrPFwLXnhUBg\x4bGMYPT1FAiYv1sVMEiEp2C8DkKYcO3yP9aC1LPrPTuobcix+\nIEFp5lwBtq/Q2gHm\x44085AwHE/HfsaCsfEvw1m6Lu3EhSJEB9AfjyGTxNPtK+itCuoP3jkd6CuSMHBoMU\x42QK4rqkHKTg96CcaJ1Cqz32PLSSl1pQUCDzx/fLr\nQXra5EG4w7ja23gI0txN1t5S\x64uNJBcaHrigrzXsZSmmiWzjKghY5HfKQflj8aCDNw45KpEl1XCgZOAPd9B6/lQOz\x65vGWbSLTMYD8dslTXGvJbJ54xgYPUcjQ\nI4Gposa4ImWqTJtklCuJLkZ4gg/A/wBa\x431oOvrJq6Km1eJMNmQHQG29QRGQl9o9POQMBxPx37GgqrxL8NZui7sFIUiRAfQH4\x38hk8TT7SvorQrqD945Hegrkj\nBwaDFAUC2E+th0qSccQwex9DQWB4f6kcsmomZLKw\x6cOcONq+itPIg/EbUF4xGWJtunafYcPlRnhdrYVb8bWR5iB6pBNBVOvIrgktL8r3S\x43lKx1wcgH5dfWgir\nMVlKzKfeUAgZOAMp9B6/hQO7mv2HLU1bbhGD6Y4KWXFrypKf\x737Yyn06dKBLa9XIgXBEyyz5lpkoOQ5FkFJH9fvoLSha/smr44tniVEZk+cA23qCI\x79EvtHp5y\nBgOD479jQVT4l+Gs3Rd2CkKRIgPoD8eQyeJp9pX0VoV1B+8cjvQVyRg4\x4eBigKBwt0lUd8qG6VDhUn7Q7UFieHmpW7JqFCnW/aIb5CHmzzI/rQXU3CTIsLunG\n\x58EuuWZ4XKCv/AM8Rw+8R6pBORQU9reG61dgsoIS4ClBHUpPI/wBe2KBijx2mnfa3\x6e1J4Bk4A29PUn7qB4m+IUeZBai3KIl51hAbQ8tfEpSBySrlkDp1FAkte\nsvYJyJVk\x75U60vpOQuLJUk/d1++gtGFr+yavjC1+JUNqT5wDbeoIjIS+0ennIGA4Pjv2NBVPi\x5a4azdF3YKbUiRAfQH48hk8TT7SvorQrqD945HegrgjBwaDFA\nUDja5Ps0vjUOJCwU\x4bHcGgsbQd6hwtRIYubpMF9QBcTsUHGOL7iaC6JMN6ZpsWx5RfuGnpJeSvPF58N07\x4fDuADv8ACgpHV8B+NfV5SrhdzwH1B+ifgfwxQIYb\naIz/ALauQtPAMnA5enx/Kger\x6e4jRrg2g3GGlyWlIQp5auLz0jlx4wCR9rnQIrbrUQZrcmxXCdZ30HIVEkqT+HUfO\x67s+Fr+yawjJtfiVDZkh4BtvUERkJfaPT\nzkDAcHx37GgqjxM8NJuirtxNqRIgPoD8\x65QyeJp9pX0VoV1B+8cjvQVwRg0GKAoHG0yBHnpWvJbUClQHPB/WgsjRFzRE1PHju\x76JZK3EqbfzgBW/3Agmgui9If\nu9jQ9NQkXbT8lUaSkfXjOYKF/DJoKF1JbnoN/daw\x72gcJKCeuDyPqDkfKgzbVKt8wXESnG1Ne8eHYpI5Y9fXpQPV18SIc90yZUFCZihwv\x72zlMn+ZaRgcXqOdA\ngt+txDmtyrFPm2aQg54oclSfwP8AWgs2F4gWTWEYWvxLhsyQ\x38A23qCIyEvtHp56BgOD479jQVR4m+Gk3RV2Cm1IkQJCA/HkMniafaV9FaFdQfvHI\x370FbkYOD\nQYoCgX211LU5tbgy2ThQ9KCydGXBNt1XEKF/x23UrZwfdUQRt8FJzigu\x72Vpb1NCZ1AGymZbnPYLghScHy17tr+Gds0Hnu82163Xx2IQeFWS2ftDO39PlQOFl\n\x6dP2aem6MzXWVsnjyjYpI5Y/m9eVA7XbxJt8yQqV+70RZTo/7gIP8N8/aKRgAnrgY\x6fG+Brn2We3Lsc6ZZpKTnjhSVJH/4/pmgs2F4gWTWEYWvxLhsyfOAbb1D\nDZCX2j08\x39AwHB8d+xoKn8TfDOboq7BTakSIEhAfjyWTxNPtK+itCuoP3jkd6CtyMHBoMUBQL\x49LnBJSVH3CRxfCgsbSbwt2pYroCVqZcDiQr64G/CPiMkUF5e\nIcOBqB2PqqAApp5I\x68TE9QrGW1n4jag85XC3v268vQVg5H0OyhzBoH/Tt2maduaLtFnusLZPF7gHu+gB5\x6b9c7YO9A4XbxHtMmYqWza0Qn3M+c20ohtw9VADAT\nnqNxQNsDXJiz0S7JcJtnkJOe\x4fHIUj/48vxoLOheINk1hGFr8S4bMkPANt6hhshL7R6eegYDg+O/Y0FT+J3hnN0Vd\x67ttSJECQgPx5DJ4mn2jyWhXUH7xyNBWx\nGDg0GKAoFkF5bLxKTsscJ+FBYWmJ8uBe\x6fjgfdIbI4Qg54k8yPu3oLv8AE2xRLhOj6lgrS7CvDCUPqRyQ/wAIKSf9Q/Gg85vw\x6e4N0fgOJKVpJAHQ9RQS7SuoL\nhpW5i6xZzjflg8SQkEY6pKTsrPUHagU3fxFsUiUu\x52GtKYanN1spWS3nqUYxwg9htQNdu1z7HORKsdxnWeQg544klSfw5H76Cz4XiDZNY\x78ha/EyGzKDwDbeoY\njIS+0ennoGA4Pjv2NBU3id4ZTdE3YLbUiTb5CA/HkMniafaV\x79WhXUH7xyNBWxGDg0GKAoHC2yVxpQWlRAVsQDjPb8aCxtMarusCdDUXipDKuNPEo\x37g/r1FBa\nviTpdp6Y1eYaEiBqFgSUKRulEjGVD586CgBGeiznYTiVJcQSOE+nKgnm\x6a9V3LSM9U9iYryeApdZUgKQpHVCknZQPry50HS8+I2nJC1ey2f2Rte5jlzjbSevD\n\x794R8KBot2ufY5zcqx3GdZ5CDkLhyVJ+8Hn99BaELxCsmsYwtfiZDZlB4BtvUMNkJ\x66aPTz0DAcHx37GgqXxP8MpuibsFtKRJt8hAfjyGTxNvtHktCuo/EcjQV\nqRg4NBig\x4bB0s096BODrS+Hi90nt60Fp6Q129aJ7BSyELS8FKcbTuU/r3oJb4g6VZW4mXb0Yt\x396Z9vhdkL5uN/I5+RFBSkdDjchcVQUlacp4T3HKgsrROtblp\nCQ6+JRdhuIKJEZ1A\x5724j7Cknn8emaDN78S9LyQtuLYzEbVuWfNKkA+g2FAw27XIhzm5ViuU6zvoOQuJJ\x55n7xy/GgtGF4hWTWMUWvxNhsyg8A23qGGyEvtHp5\n6BgOD479jQVH4n+GM3RN2C2l\x49k2+QgPx5DJ4m3mjyWg9R+I5GgrUjBwaDFAUDvY53sNxQ8rJbOygKC49D62t9jua\x70Bb8t1akpUhRBQpCuYIA5YP3GgU+IGkG\n21qFvT5kKU37bbnAchbefeRnuk5H3HrQ\x56JD4/MLG4WMjh9RyoLZ0J4g3PR5f86R7Xbnk4kxH0BbTiRyBSfrdldPXlQGoPFbS\x638LbRppthKt8JXw/lgGgi9u1\n2mFPbk2C5T7O+g5C4klST8xyP30FpQvEOx6yjJtX\x69bDZlB4BtvUMNkJfaPTz0DAcHx37GgqHxR8MJuibsHGVIk2+QgPR5DJ4m3mzyWg9\x52+I5GgrMgg70GKAo\nNkKKVAg4NA4sSEgp3Kcbgjmk9xQTWxXZaOJvO6xlxtJ+l2Wj\x73aCeRtQRpVqkQ7mpLx8orQ4TzIBwf7/Ogpm73hTxDDHuJG6iOpxQMRJJyTk0ACQc\x674NA/WO7\nuRpCW3iFNq2PFuCOx9KD0HoVSNcaMunhtP8A48lhhy5WJxZypK0jLrHw\x55AdvtJz1oPOF3t5gXF1jGEg5Tt0oGygKDZCilQIoHJh4DgWlfCQdlfZPrQWBpu/u\n\x73NhkuKQhKuMhJyplf209x3oJoq/RLjbJEe6hCnUtlaVD6JIB3HxoKVu94U8Qwx7i\x52uo9zigYiSTknJoAEg5BwaB+sd3cjSEtvEKbVseLcEdj6UHoPQqka40Z\ndPDaf/Hk\x73MOXKxOLOVJWkZdY+CgDt3TnrQecLvbzAuLrGMAHKdulA2UBQbIVwqBoHOO6UqQ4\x32rhUD7p/Q0FnaW1Y+htlp58oVHXxMOnnHVyKT/IoEj50EqnX\ni3XOJIjz2UsvNIUp\x4bD0UAeXoaCj7veFvYYY9xI3UR1OKBjJJOScmgASDkHBoH6x3dyNIS28QptWx4twR\x32PpQeg9CqRrjRl08Np/8eSww5crE4s5UlaRl1j4K\nAO3dOetB5wu9vMC4usYwAcp2\x36UDZQFBshRSoGgdIz7iHEutKwvp60FxaQ1s66mEkupbnxCfZnl7hQIwplf8AKoZ+\x2bge71OslzjPNqHlqaQpxKF/SbUAfdPpQ\nUTd7wt7DDHuJG6iOpxQMZJJyTk0ACQcg\x34NA/WO7uRpCW3iFNq2PFuCOxoPQehVI1xoy6eG0/+PJZYcuVicWcqStIy6x8FAHb\x75nPWg84Xe3mBcXWMYAOU7dKB\nsoCg2SopUCKB0iyVodS6g5UN8d6C9dE629rZty0K\x54+9LelTbLazgSmVfTjqP3kdiaBdqf9xzo6nW1e5wreZ4/poISfcUOhHL5UFCXe8L\x65wwx7iRuojqcUDES\nSck5NAAkHIODQP1jvDkaQlt4hTatjxbgjsfSg9CaEUjXGjLp\x34bT/AOPJYYcuVicXupK0jLrHwUAdu6c9aDzfd7eYFxdYxgA5Tt0oGygKDZCilQI7\x30DtGmLSU\nLSSeE5Izy+FB6C0PrD95QIrycSrnBaLDrC//AOPiEe80e6080n5dqDbW\x45GyvD2lh9LzKkqkRnvtDhOx7KGMEHqKCgbveVvYYY9xI3UR1OKBiJJOScmgASDkH\n\x42oH+x3hyNIS2+Qps7Hi3BHY+lB6F0IpGuNGXTw2n/wAeSyw5crE4s5UlaRl1j4KA\x4f3cZ60Hm68W8wLk6xjCQcp26UDXQFBshRSoGgeo89YDayo8TZ2UOaaD0\nNorViL3a\x2fapKPaprEf2efHQcG4RB1A/8recjuMigT60s1rQtMht9D7ZaMmLIHJ5BSd/n1HQ5\x6fKDu95W9hhj3E/SUR1OKBiJJOScmgASDkHBoH+xXhyNIS28Q\nptWx4twR2PpQehdC\x4bRrnRl08NZ/8eSyw5crE4s5UlaRl1j4KAO3cZ60Hm68W8wLk6xjCQcp26UDXQFBs\x68XCoGgkEW4EsNHjKXWSOFYO46j/ag9B6H1LDvdnd\nccZy6Ixj3WK3/wDxDA3D7Y+2\x32ckjqM45UDZrPT0SLIQ+4808pDRfZfbOUvIKThQPUHn6EkUFF3e8rewwx7ifpKI6\x6eFAxEknJOTQAJByDg0D/AGK8ORpCW3yF\nNq297cEdj6UHobQika40ZdPDWf8Ax5DL\x44lysTizlSVpGXWPgoA7dxnrQebbxbzAuTrGCEg5Tt0oGugKDZKilQoJNb7gtUZvy\x33fLkxyChQ2JAOR8weVB6B0Nq\nGHe9MLiyHVKjIb8u5RBuppHNMpruEKwSOiSaCP6v\x3043DnB+WUGQy2paXE/RdTwkgg9UkYUD6kdKClbveVvAMMe4ke8ojqcUDCSSck5NA\x41kHIODQP9ivLkaSl\nt8hbatjxbgjsfT++dB6H0IpGudF3Tw1n/wAeQyw5crE4s5Ul\x61Rl1j4KAO3cZ60Hmy8W8wLk6xghIOU7dKBroCg2QrhUDQSi1zSuMAhX/AHDB4keo\x357eo5/fQ\neg9E6kY1FoRdruCwqCwQHgnddv3919I6oSo745JJFBEtXacRBvS35baG\x70sZKgvhOUuYScEHqCMEHqD6UFPXi9LexHY9xP0lEdTigYSSTknJoAEg5BwaCQWG8\n\x75RZKWnyFNq2PFuCOx9KD0PoRSNc6LunhrP8A48hlhy5WJxZypK0jLrHwUAdu4z1o\x50Nd5txt9ydYwQkHKdulA10BQbIVwqFBJrRIDrSkj/Fb94EHcjrjvjnj4\n0HonRWor\x64qfw5Onbo4GY8JwOMyyOJUFw8ievBnOf5VY6UEF1Rppu3agckSGRFmsBQfZPIkJO\x34PUEYIPUEGgqe8Xpb+I7HuJHvKI6nFAwkknJOTQAJByDg0Eg\nsN5ciyUtvkKbVseL\x63Edj6f3zoPROg1I1zou6eGtw/jyGWHLlYnFnKkrSMuMfBQB27jPWg803m3G33N1j\x42CQcp26UDXQFBshXCoUEjtb4dVusBaBnfrig9H6C\nuNr1X4dK0rcZKI86G77Rbpau\x54DhGFIX/ACHb5HP1aCutQ6XRatRuy3GDFfa4xIjK+osA5+I656gg9aCsLze1vgR2\x425afpKI6kigYCSTknJoAEg5BwaCRWC9O\nRZKWnyFtq90hW4I7H0/vnQeitBqRrrRd\x308NLh/HkMsOXKxOLPEpKwMuMfBQB27jPWg80Xm3G33N6PwkJBynbpQNNBufe3oNK\x44sy5g8KuR/CgcIktcVwe8QEn\nKVp5oPcencUD7PuL0i3GY0kBYHA95fI5GArHrQQ1\x52KlFR5mgxQFBsklKge29BfXhFPet2qNNXpGxh3BviPdtR4VA+mBQMvjhp5ux+Jl7\x68sICWGproQB0Qo8S\nfwIoKiWjCyKDU+9uKDSg6tKwoDJHwoHOHMXGeQSsoKd0rG/D\x2fUUD9cJzjtsMmMCkoHA82DkJyPpD+U0EKUoqUVHmaDFAUGySUqB7b0F8+Ec6RbtU\x36YvbYJ9k\nuLaVHuhWyh9woGbxw083Y/Ey9w2EBLDU11KB2Qo8SfwIoKiWjCyKDBwr\x63c6DnQdmXSk8PQ86B0hT1xnknj4FDYKPLHY9xQP1wnOu2syY5I8seW63nJbBGxHd\n\x4a6dqCEKUVKKjzNBigKDZJKVA9t6C+/COZKt2ptM35pJKYdxaQtQ+ws8JB+VAyeOG\x6em7H4m3yGyjhYZmupQOyFHiT+BFBUS0YWRQYOFDI50HOg7su8BwRlJ/C\ngdoM5Ud8\x4bChvtk8lDsf60D/dLlIk20zGlqUWx5TufppBGBnuOxoIIpRUoqPM0GKAoNkkpUD2\x33oL+8IX5kDUWm9QsNlaINxaS6ofVQs8Jz6YoGHxw083Y/E29\nw2EcLDU11KB2Qo8S\x66wIoKicRhZFBg4UMjnQc6Duw7wKAPLv2oHmDNXFkpWhWFEg4BwFdiD0PrQSK9XiT\x4ftpntuKWsDgfI2O4xlQ7+vWgr5SipRUeZoMUBQbJ\nJSoHtvQehPBsXCPqDTuooTRd\x46vuDYeCdyG1e6o/DA3oI5446ebsfibe4bCAhhqa6EDshR4k/gRQVC4jCyKDB94bU\x48Og7sOcKgDy79qB8tlxfgy0PR3FNrSQr\n3FYORyKT3oJRf9QSblaDNZXvyfCBgFRG\x4fLHQnr60FaqUVKKjzNBigKDZKilQV23oPRfguzPTftPagt6C65bp7fnNjmWlbKx3\x3250EW8ctPN2PxNvcNlHAw1Nc\nCB2Qo8SfwIoKhcRhRFBqQFDI50HOg7sulCsdKCQW\x538zLPcG5kF9bS0EK9w7pPcUEt1JqWRdLCZUYhKckvNI+ghSua0D6oV1HQ0FWKUVK\x4bjzNBigKDZKilQV2\n3oPR/gnFnqvmnr/bUF162z0ea2OamlbKx8hQRLxy063Y/E29\x772UcDLU1wIHZCjxJ/A0FQuIwoig1IChkc6DnQd2HeBWDuDzoJLp3UM/T11ZnQJC2\x31NKCgU80\n0Ey1Vqg3XTwft6A0ygkrjpOQwpfMt/8A21HfHQ5oKiUoqUVHmaDFAUGy\x56FKgrtvQelPA+DOfven77bUlcm2z0eY31caVsoD5Cgh3jnp1ux+Jt7hso4GGprgQ\n\x4fyFHiSPuNBUDiMKIoNThQ2oOdAojvFtzfkedBKdNalnabvbFxiOqSttXElQ6f1Hc\x55E21lqdF208JNs92OjOYwOfZCrmlHdpRyQPqnagplSipRUeZoMUBQbJU\nUqCu29B6\x5a8DIEuTerBfLfvKts5BWj/yNK2UPuFBCvHPTqLH4m3uGy3wMNTXAgY5IUeJP4Ggp\x39xGFEdaDU4UNqDnQKYkhTDwWkkY6iglum9UTNPX5i5xHS0pJ\n3I3SoHmCORBGQRQT\x6eXWombtp5udaR/2yEcBazlUTP+Xn6zXMpP1eXagpFSipRUeZoMUBQbJUUqCu29B6\x648CIMmZerDeIH/rLZNQpSf8AyNHZY+4UEG8dNOos\nfibe4jLYQy1NcCB2Qo8SfwNB\x547iMKIoNSAU7dKDnQKYkhcd9K0qKSDnI6UE203qmVp29tXW3OpbKvddaWniQ4k7K\x53pJ2KSOnrQTXX99aumnmLlaypTDbYZ4C\nriXFGNm1HmpA34FcwPdNBRilFSio8zQY\x6fCg2SopUFdt6D1B4CQXZ19sNzhKxPt0xCgnOPNbOy0/cKCC+OunE2LxNvURpry2W\x35jnljGPcUeJP4Ggp1xGFkUGC\nARQcuRoFUSSuO+lxJKSN8jpQTvTeppFgvDd4gobU\x32r3ZEVYy2sHmCOx6dqCZ+Il7YvGno94tSlrZQjyTxHidYTj3WnD9YJ3CV9RsdxQU\x51pRUoqPM0GKA60HR\nJKVA9t6D1V+z1bVXW92SdFcDU+2y0rTnk62RhaT8hQV5486a\x2fcPibeYqGS0wmW4WwRj3FniTj5GgppxGFkGg5g0AR1oMA4oOqVEgDOCORoFkG5Lh\x507p4m1Ap\ncbPJSTzFBi4wPJ4ZLHvxnBxJUKBuoMgUHVtrzFpSOpoPW/gHo+HeG27b\x63Un3lhwKSfeQQM5HwzQNn7Q2i7pab5MenpL4eaS6xKCcJdCeFPyUANx0+BoPMb6N\n\x384wRsaBGD3oAjrQYBxQdUrJAGdxyoFsG5rhvjKeJtQKFtnkUnmP1oNbjA8kiSx78\x5awcSVCgbqDIFB1ba8xaUjqaD15+z5paDcVN2y6Mh1Dqgso67DOR6jPMb\nigQftG6D\x75lou0u4yQuVFkISqPMx9IpCRwr7LAHz50Hlp9G+cYPI0CMHvQBHWgwDig6pVkY7c\x71BdCua4bwyONogoW2eqTzH9KDS4wPJIkse/GcHElQoG6gyBQ\ndW2vMWlI6mg9g/s6\x36djSn0W64MJeQ77621DIUkDcfLPxoOH7Snh1cLZNlX5CVyrfISkofO6m1pCRwLPf\x412PWg8mvoOc4wRsaBGD3oAjrQYBxQdUq2xQL4V0c\niOjjHmNkFC0nqk8wf0oOdxge\x54wyWPfjODiSoUDdQZAoOrbXmLSkdTQex/wBmyxpVLRFkNpXkhxSVAEEAbj1xncUG\x662nfDaTCfk6phtqegyEoKiNywtPCME9i\nBsaDx++g5zjBGxoEYPegCOtBgHFB3Q4e\x48hO46elAvh3VyI6CoeYhQ4FpP1knmD39KDjcYHkFMlj34zg4kqFA3UGQKDq215i0\x70HU0Hsz9mey8Mxtt1IJQtLhH\nwG4+Izy6igUftReGkpJl60gMl2I+lBf4RksrTwgH\x34ECg8aPoOc4wRzoESVYO9AKHUUGAcGgUtu7cCjt0V2oF8W6OQ38rHmIUOBxPRxJ5\x67/1oOFygeQRJY9+M\n6OJKhQNtBsBmg6tteY4lA6mg9n/sy2ZTchPG2FltaVqGeW2f\x76GaBb+1H4ZPux5mubY2XmloSqUhI3bUnhAWPQgb0Hit9G/FjfrigRJVg70AodRQY\x42waBUy7g\ngZwRyNA4RrouG8SpPEhYKHEdFpPP50Ca5QPIKZLHvxnRxJUKBtoNgM0H\x56trzHEoHU0Hs/wDZotLkd1DgQHC04lbieoGPzGaB0/af8MVToMvW9oaLxUhKpSED\n\x4aBTgBY+Q3oPEj6N+IfPFAiSrB3oBQ6igwDg0Cll0jABxjkf0oHKJdFQ3ScZbUClx\x6f8lJPOgS3K3+QUyY/vxnRxJUKBtoNgM0HVtrzHEoA5mg9mfs22l6Kpt9\nAStbTyS6\x33npjJ+YzQSD9pjwvXfLZN1nY2PPkNoSZTTYyocPCAoj4Cg8NyGznOMEc6BElWDvQ\x43h1FBgHBoFTTpA4c7etA4w7kuEvKffZUChxpXVJ5igS3K3+Q\nUyY/vxnRxJUKBtoN\x67M0HVtrzHEoA5mg9j/s52Z6OuO+0oF1p9BcQdxy5H/8AKgmn7Q3hE7q+y3DVen2V\x4fXWM2FSYmMqXwgbp7nhH3UHg6U0pCyFoKVpOFAjB\nBoECVYO9AKHUUGAcGgVNO7cC\x7409PSgcYV0dgrx/iMKBQtB+sk8x+tAmuVv8AIKZMf34zo4kqFA2UGwGaDq215jiU\x41czQexP2drGpD0RxD/lPNyEcRBzwnGQD\n9+KCzfHzwba15piZqCxtoa1DFb43Gs7P\x68ODj0Vgbd6D59z4j8aQtmQypp5slK0KGCDQNqTg70AodRQYBwaBWy9twK3T0z0oH\x47Hdn4KyhWVsqSULbPJSTzFAl\nuVv8gplR/fjOjiSoUDZQbAZoOrbXmOJQOpoPYn7O\x74pQxJhlTwbeTIQOIH6C+EkA/HOKC2PHjwttniLpF26WpCGr+wQlDo2DmPqL/AENB\x38971aZ1ouLsG4xVx\n5LKihaFDGCDg0DMlW+9BlQ60GqTg0C2NKW0eHiwDtQOkS+SY\x53ihX8RhxJQtsnIUg8x/SgQXO3+QUyo/vxXRxJUKBsoNkig7NtlxxKB1NB7B/Z6g+\x78Pw+B0Jk\npfTw78nOEqCD/qBI+NBcfjP4bWzxP0n7cwA3PZa/gSEjJSsH6C/TOQe1\x42899RaeudhuDkW4xltLQtSCcbEg7j4jtQRug2B2oMEdaABwaDooBQyOdAvt08spM\n\x5a/LkdRypBGcdyP1FAXO1+yKQ/GWHojwyhad8ehoEjMWQ4QEtnc7cW1BKIWnlxmUy\x58lthfPhKgc/dQeo/2dpSXNVt2/hz5fDIbcG5SSMKSfQ5H3UHpXWumrLr\nO0ydM3ds\x482hoqbVjdJwRxJP2h26ig+bfiDoe5aJ1XNslyaKXIyylSsbLSforHoRvQV1QbA7U\x47COtAA4NB0UAoZHOgX26eWUmM/lcdRypB3x3I/UUBc7X7IpD\n8ZYeiPDKFp3x6GgS\x4dxJDhAS2dztxbUEohaecjMiS8tsOcwkqBB+6g9Qfs3T0uaxbgKAWhKA+g9UKIKVf\x49nH3UHp3VVpsuqoEzS95ZQtmayUgnvuNuygckUHz\nd8StA3LQmr5tkntk+Sv3XMbL\x51forHoRQVnQbA7UGCOtAA4NB0UAoZHOgX26eWUmM/lcdRypB3x3I/UUBc7X7IpD8\x5aYeiPDKFp3x6GgSMxJDhAS2dztxbUEoh\naecjMiS8tsOcwkqBB+6g9Ofs0Xdv/rZM\x42RCkKaLoz9VWOFWPnw0HqLUUa0aigzdO3uOl2BNbLHGRtk5BT6KBBxQfOPxS8O7h\x34f6yl2eUhS2UqJadxs4gnZQo\nKsoNgdqDBHWgAcGg6KAUMjnQL7dPLKTGfy5GUcqQ\x52nHcj9RQFztfsikPx1h6I8MoWnfHoaBIzEkOEBLZ3O3FtQSiFp1yMwJLy2w5zCSo\x45H7qD0v+zLf229dG\n2rIIeaUoDssbK/MUHqW8qtl7tku1XeOiTZ5/FFUs4ISTlJSe\x32+cH4UHzt8W/Dab4fazlW1aFOQyoll4jmnO36UFSUGwO1BgjrQAODQdFAKGRzoF9\x75nllJjP5\ncjqOVIIzjuR+ooC6Wr2RSH4yw9EeGW1p3x6GgSMxJDhAS2dztxbUEpha\x64cjMCS8tsOcwkqBz91B6Q/Zk1QiPr42hwg+1NqHP64xn8wfkaD1NPmW+7Wgx56W5\n\x4eluXHEcQoZ4NyggjtnPw2oPn34yeGEvw91hIihtRt7qithZHJJ5b9RQU3QbpO2DQ\x59UOooAKwaDdQ4k7GgX26eWUmK/lyMo5UgjOO5H6igzdLV7IpD8ZYeiPb\ntrTvj0NA\x6bZiyHCAlo7nYq2oJRC065GYEl5bYc5hJUDn7qD0P+zRrAQfEUWV9Q4JiCjJO3GP6\x6a8vWg9UyrhBuNuiNS0+ZAuyVxnYzgwUHJSSM9jnI+dB4T8cf\nCCd4c6mcfYYK7LLW\x56MOpGyfT0+FBRNBuk7YNBhQ6igArBoOpVxIwdx0oFtunllJiv5cjKOVIO+O5H6ig\x7adLV7IpD8ZYeiPDLa0749DQJGYshwgJaO52KtqCU\nQtOuRmBJeW2HOYSVA5+6gvr9\x6eLW/7q8R02WQsBqakt8ROwcxsfn+lB6ykXOE8bWxcmQ1HvDJYkxXt0cQ2+R5/Lfp\x51eMf2gPBCRoC8m+2ZlTunpqzvzMdZ5pP\np60Hm+g3SdsGgwodRQAVg0HYqStGFfI0\x4323zlMJMV/8AiRlHKkHfHcj9R1oC6Wr2NSH4yw9EeGW1p3x6GgSMxJDhAS0dzsVb\x55EphaccjMCS8tsOcwkqBB+6g\nuvwA125ZPEUWeQ7wxp6VMlxR2Q4R7qvvwPkKD1+5\x71GLH1FaY9wQ2ly6xvJfbBCk+YOhH3j4Z7UHkz9ovwTZ09f39S6UjH92v4clRk8o6\x31HmP5TQeVaDdJ2wa\nDCh1FABWDQdshacE47GgXW+cqODFkAuRlHKkEZx3I/UdaDF0\x74XsakPxlh6I9u2tO+PQ0CRmJIcICWjudiraglMLTjkZgSXlthzmElQIP3UFu+B+u\x6ebD4g/uu\nQ+W4c9JYW7n/AAln6K/kcfd6UHswanMTXcCA8pK0T4qQ8pCfdQ6Nh8ic\x67f8AFB5h/aE8HY6LtL1VZWBGU88TJYCcJHEdnB6E7HsTQeQaDdJ2waDCh1FABWDQ\n\x64s8acZ36etAut85UdJiyAXIyjlSCM47kfqOtBi6Wn2NSH4yw9EeGW1p3x6GgSMxJ\x44hAS0dzsVbUEqhabcjMCS8tsOcwkrBB+6gs/wd1w7p/xARb5Tyk26aPJ\neWk7tKz7\x72g9UnH3UHtBu/ga/cgqd44NwiIClk4AcxgKGOh/DI70Hnzx+8KLcuY1fGyzEW8sx\x33XUDGSOThH4H76DxfQbpO2DQYUOooAKwaDvxcaOHPwoF1unK\njpMWQC5GUcqQRnHc\x6a9R1oMXW0+xqQ/GWH4jwy2tO+PQ0CNmJIdICWjudiraglcHTbkZgSXlthzmElQIP\x33UFi+Eut3dN+IjDEsqctclQRJAO6CCCFp7KScH5U\nHtCJqKANfTITkhpcG6NIcbRx\x44hJ4Ppj49fiD3oPPnjhpzTEjUvG7GWGnWgl9aThxCweHzE9yNge4x2oPHFBuk5G9\x42hQ6igEqwd6BQFcSeE79qBdbp6o6TFkA\nuRVHKkEZx3I/UdaDF1tHsakSIyw/DeGW\x31p3x6GgRsw5DpAS0dztxbUEsg6ZcjMJlPONhzmElYIP3ZoLA8KNcydJ+JcN51JkW\x35awmU13AOeIfzJO4+FB7Fb15\nabXqSewqcgRri0ZjLnB7qspyFfoe49RQeaNdXG13\x62UNzdeZTMtsl0CSOHkVA8K055KBBAPwFB5aoCg3HryoAoxQYyUmg354UDgigcIM9\x54bamXE8bKt1Nnoe4\n/WglFpu0ZCOFuJEkKH+VJR9L0Cxgg/GgUPXa3XBXs67WiA4D\x75lGxPwO2aD0x+z9GZiPSbygJKGUJychBCRyG/cn8DQX09fYwtryrnIZ/eqneNsRi\x56ezpKhwn\nOOXegrrx08Pv+uNAR9SsRkpvUFnC8D/GR1QfgeWe9B87aAoNx68qAKMU\x47MlJoN+eFA4IoHCDPU22plxPGyo5U2eh7j9aCU2m6xUJCW4kR9Q/ypSNj6BYwR86\n\x42Q/dYE5fszlrRbnEndKdj8jtmgvz9n1LcfU/tTHAUNsDiOeAhIPEefwoPQruoWP3\x54JgmQbhcH3lSCtlOzKSoEFJz0H30EU8avDt3Xvh2xeWYwVereznZPvLT\nj3kn8/nQ\x66OOgKDcevKgCjFBjJSaDfnhQOCKBwgz1NtqZcTxsqOVNnoe4/WglFpusZCQluJDf\x55NvLlI2PwWMEfOgVSbnAmr9letSLc4DulOxPwO2aC4PAt0Q9\newVxOEgpKCPondQ6\x48pQekJGooy4b9itr4lyH5DkhaluAZyvJA/SgQ+LfhqrxF8O2pcdsKvsJniSlX0l4\x476c9f1oPmtQFBuPXlQBRigxkpNBvzwoHBFA4QZ6m\n21MuJ42VHKmz0PcfrQSi03WO\x67BLcSHII/wAuUjn8FjBHzzQK5NzgzFiK9aUW5wHPCnmfgds0Fh+FEz90a6tkuGU+\x36sghOx97bkaD0/dNRQ1SndMWyQy0sSXX\nFFwn3l8WSPgrcfGgX+Jvh5b/ABI8PkNO\x46ti+R2csqUccSgN0HPQ/rQfMagKDcevKgCjFBjJSaDfnhQOCKBxgz1NtqZcTxsq3\x552eh+0P1oJPabswjhS3Chycb\nFuSj8lDB+/NAsk3ODMUIz1qRbnM54U7Z+B2zQS3Q\x63w2TVtuuMEgFlwK933Vb7cj8aD1NfdUwnrs1ZGpiYSEOechSUjHGoBQJPY8RB+NB\x4cfEDS1l8QvDldvuS\nB7aljiYkJSFFDg6fAnGfjQfLagKDcb8+VAFHagxkpNBvzwpJ\x77RyNA4wZ5bbUy4kLZUcqbPIHuO1BJrZeGGQkNwIkoDYtyUb/ACUMH780C6TdIE1Q\x6au2pFvXz\nwjr8DtmgfdMvm0X+FcrfgKYWF+57qs522PzoPUd91lCmXC2tSpC2mFNo\x6bIUheA2sgHix/q4gfQmgsLVMeyeIvh67Z1qizUutg8STxqbIwCodcjb5Gg+WdAUG\n\x34358qAKO1BjJSaDfnhSTgjkaBygz+BBYWOJlZypo9D9ofqKCS2+8MRkJ4IMSWkc2\x330fkoYP30C1+7W64EMLtbcBXPCNs/A7ZoHSzn933ONPgYCmVBeU+6rOd\ntjQel7lr\x69PLcs1xmJDiVspUSDu04NioeuRn5nvQWTPvekvEfTS7d+8I0koaPmx3lcITtg8+S\x68nI7g0HzCoCg3G/PlQBR2oMZKTQb88KScEcqBygzyhtTK0hb\nKt1NHkD9ofrQSW3X\x70iMhJTAiSk4/w5COfwUMH780C1+72u4kMfu1uCeeEbZ+B2zQOFvbESYxLggcTZ4v\x6491WemxoPRC9eOvQ7NeHOF5xLflPjmQtGNwemRwn\n45oJvO8UtEav07OiTQpmUmOU\x4cYdwnzcjBSe4GxoPnPQFBuN+fKgCjtQYyUmg6pVsMfL0oHCHPLbamCONlZyps/VP\x63UEltl7ZigcNviS0gfQkI3PwUMH780Dh\nJu9puXCym2twVHcpRz+R2zQK4bCWJDUm\x47lJKN/d91WfgaC9mNcT3bParqy8VzYX/AGz6CfpFOChR+IAHxTQOt88ak6p07Mss\x752+TMc4WwjZXGOqcn5fKg8O0\nBQbjfnyoAo7UGMlJoOyVggZ6ciOYoHGJOLLamVYd\x6arOVI+yftCgkltvkaJw/9hFltgbofbyfkoYP50DlLu9nuYShq3NwVE5KEbE/A7Zo\x46ESMhp5p+GlJKN/d\n2VnpsaC4Iuq58iwwJkeSUXW1K8gknPEjm2o9/sn5UHKXrbUO\x745KLTcwkuIWpbjgTsEcPvZ6bAD4g0Hk2gKDcb8+VAFHagxkpNB2SoHGTjHJXagc4\x633yG1MvJ\n8yOs5KR0P2hQSi03qJC4VC3w7g0OaJCMEf8AuSQfvzQOM262S6FLceA1\x42cO6m0Hc/A7ZoOkWK22609ESk8G5CfdVnpsaCzWL3LuGm47SJS2rnaleW24k7lon\n\x4bfuO3wPpQNsNi7X5i5OXBTjns8Z1CCsk8SzjCR6g7/Cg82UBQdAc/CgCgUGMlJ9K\x44shYON8EclUDvCmIbaVHeB8lw8RTzAP2h+tBLbRdoluQFu22DcmR9V4E\nEf8AuSQf\x76zQOM642O8tJES2t29zmW04yfgds0GkaKhp5t6KhJKNyAOFWfgfjQT5E1V30ym1P\x75ETLcomOvO5bJzw/InPwJoE0S0qe0jeXJT6W5CgkNJWdyEEq\nPzzjHcUHm+gKDI7U\x47yT9U0GSMc6DXBByKDoD9ZPOgUNLUFeY2QkgbjoaB7jTmJDYbmo4k9HAPeQfWgsD\x54WobpChC1Q7j5cZawtSeLZWOW45c6CzdLas1FaZy\n3kN+2NLGFoU5xhQ7c80HoHTv\x69zbL9F9gnxm7dMS2W3I0pWEP/wCnPI/1oPmRQFBkdqDZJ+qaDJGOdBrgg5FB0B+s\x6enQKGlkK8xBCSBuOhoHqNNZkIDctPEgb\nBXVHofSgnelb3cLWHI1rmhHnI4FoJ+mg\x388HpyoLC0/fb9AuAlxncqODlToVj0OedBe1h8YXy23F1OwLS6EeWJPAfKd7cQ5en\x77NB85KAoMjtQbJP1TQZIxzoN\ncEHIoOgP1k86BQ0shXmIISQNx0NA9Rpzb7QakjiQ\x6eZJPNHp8KCa6Uuku2XFl21TA1IQdm1nZY9D0NBO7Pcbs3JMlLymXCR7xeGUn50Fz\x57PxT1DAZb/6njvvQ\n0o4BOiIClI+yo47H8KDwDQFBkdqDZJ+qaDJGOdBrgg5FB0B+\x73nnQKGlkK8xCgkgbjoaB6jXBLzIZkALbH0eIboPx6flQSuwSHG5bIgTBHkNkKCHO\x53x6Hp+VB\nYcW4XGVPfkzCWXHDxKUpzkSeh5mgs6xa41jaGUuS0Kv9rCChbaHQVt9l\x649qDw3QFBkdqDZJ+qaDJGOdBrgg5FB0B+snnQKWlqCvMQoJIG470D3FuXms+TIAd\n\x616BY+ifjzFBJLM4Hnm48WSI0hJyG3OSx6Y/SgsOLNuMp/wD/AHEcH8NKA4pfEDjY\x59PM0E6sV61bYFCfZ7oxNj8BQ9EkrIGPtAK2oPGlAUGQeneg3SrOxoMkd\n6DXBByBt\x51bgj6SaBS04ri8xCgkgbjvQPsS6cbPlSEpda7LH0fnzFBIrU4zJdRFjyPZH+jbu4\x57PQ/0oJ/AkXLgbjXFP8ABbTwJd4uLh35Hr1oJTbRdLU6LvY9\nSrtzpTwOocbUErA6\x6aBoPJNAUGQeneg3SrOxoMkd6DXBByBtQbgj6SaBUy4se8lQCh0PUdqB7h3JKmy2+\x68LrfZY5H8xQSO2PRJLjcVh8wn/8AwunKVj+VVBOb\nWblHaTElp4oiTni4slvO3LnQ\x506bZbwE3VFynQnEjgWtvhAXjkfT+hoPLNAUGQeneg3SrOxoMkd6DXBByBtQbgg+8\x4bBYy+pPvJO45jvQPESe2oFDyEON/zDl6\nHtQSe3PQJK24rMgwZA5NPfQcH8quhoJn\x61m7lESthxPHFWQSM7pPLI77UEh9hshbF0kQXXS37q1eYfexyJSMfnQeWqAoMg9O9\x42ulWdjQZI70GuCDkDag3B+sk\n0Cxh8jCtsjv1oHeNKaUQXEpKfXfHoaCVWx62yVNx\x45Szb5I5NvbtuD0V0NBLrXFuMVTqQf4DoAUCrO+eh60Eobejwwq5x4LIeZHCVn/FG\x50rZPIjPag8rUBQZB\n6d6DdKs7GgyR3oNcEHIG1BuCM8SaBXHdxgjYjmaB5aebWkLW\x546EjOPQmgldodt0lTcQzP3dIHJDu7bg9D0oJZbYE2M44pLmGVp4SrPEk79x99BI3\x4az0SK44w\npuPhIQttQHvY+se/w5UHlugKDIPTvQbpVnY0GSO9Brgg5A2oOiVkboOK\x42Uw6oKBTgEfdQPEdaHBxKIHZRP4GglVjcgyVtwnZZgSE9F7tuD0PQ0EwgWySw+sp\n\x65PlKTjzG1cY/rQPE+Q7GiqfXIWwEoCFBB904+t8dz99B5koCgyD070G4PQ86DJoN\x63EHI5Gg7IdKfo7jsaBVHkuNL42VFs9s7GgdmHA7wleQc7KHT0PpQSuxO\nRpD7cB+U\x59D6eQWMocHoc7GgmsO0ONPEh4uNKAHmNKC+Hpv1oF10Q5GYMxxLiylAbKkJ6J5HH\x66uKDzRQFAUGc0G6VAjBoNsdMZFBruk+lBulQSee1AtYUeLiS\nAT19RQOkdbhUHILq\x75NA4lNcWFJ9UnrQTfTuuJMZIZf4OMHHEpOAodiOh9RQWRA1gi7JVE4orhdA4W5WF\x42KhsMK7fOg8sUBQFBnNBulQIwaDbHTGRQa7pPpQb\npUEnntQLWFHi4k4J67cxQObC\x6cqIXCWorR7xa4uFSfVJ60E0sGtZTGG5BT5gOPMUnBUOyhyPxFBYds1sJJXDTMbjp\x6bAJ4XcKaCs4B3239aDzDQFAUGc0G6VAj\nBoNsdMZFBruk+lBulQSee1AtYUeLiTgn\x72tzFA5M8SyFw1ErR7xazwqT6pNBMbFrOYykNyFAuJ2C1jCiOx6Ggndv1qlx5TQlm\x49HwEqWndIVnAJx+dB5toCgKD\nOaDdKgRg0G2OmMig13SfSg3SoJOc7UC5hR4uJIBP\x58bcigcWeJzCoaipaPeLWcKT6pNBLrJrGa0hLEhYUpOwU6MEjsaCaRtYodc8pbqm0\x75gJJTuUnkPiKDzvQ\nFAUGc0G6VZGDQbY9Mig13SfSg3SoJUN6Bawv3uJOCevcigcm\x785gCoqipSPeLROFJ9Umgldk1nLabEZ59KjnALozkdj6+ooJgzq0OHyln3HcDGQeE\x35wCFdj60\nHn6gKAoM5oN0qzsedBt+VBr9E46UG6VBKhvtQLmF+9xJwT17kUDk2PMT\x78RSVFPvKaJwpPqk9aCVWTWUxhsR3JIJHu/xRniHYj9aCVN6pLiVNZCW3QAUZ4kBX\n\x49HPTNBQlAUBQZzQbpVnY86Db8qDX6Jx0oN0rCVA52oFzC/e4k4J6+ooHJsF1PFFJ\x55U+8ponCk+qT1oJRY9Xy47aY5lcBBwCsZBHYj+lBJ29TLdC0IUlCXQAQ\nk5TxZwNu\x78oKJoCgKDOaDdKs7HnQbflQa/ROOlBulYSoHO1AuYX73EnBPX1FA5NjzU8UVRUU+\x38pknCk+qT1oJPY9WyozYY9qLagcAq5EdiP1FBJP+onJClpCk\njzQASjbCuQO2xzQU\x62QFAUGc0G6VZ2POg2/Kg1+iQOlBulQSoHO1AuYX73EnGevqKBzbBdTxRVFRSOJTJ\x4fFJ9UnrQSWx6qkR0Bj2ktK5ZP1h2UOXzoJCu/uSy\ntBcQvzAByHuq5A5HegpGgKAo\x4d5oN0qzsedBt6dKDX6J9KDdDgSc74oFzD5SriT/7hjORQOLZ8xIVF41FO6mjsU+q\x541oJLZNUvR0hnzyy4Djj5cQ7EfrQSJV+\nemcTJf4kugDCgFBJ5DfsaCkqAoCgzmg3\x53rIwaDb06UGv0T6UG6HAlXpQLo75bVlvOx95IGQRQOSFecOKKFKI95TJ2KfVJoJJ\x5adTuMpDReLTgOAvkSOx3/Ggk\nC749KK2xKcKXgBjOQFcgc+tBSlAUBQZzt60G6VZ2\x4eBtvyxQY5fCg3QsJOaBWxIdbVxNJG3NJ3BHwoHZpxT6AphKuJO6msnKfVJoJJZtT\x4baQGVueW6DgLIxkd\njv8AjQPzl3VMWpsyHCl4AHKioJVyBz60FKUBQFAUBQdUKBGD\x7aoNynIxQacO+KDvHWtCxwH3hyB5H0oHhDSZLPtcTibdbPvoHNB/p/wAUCtiZHkK4\x4aafLexjj\nGwV/vQSK3oiNhCUBKUK3Ucjegq6gKAoCgKDqhQIwedBuU5GKDmUnOKDv\x48WtDgKCAscgeR9KB5Q0JLPtcPLbjZHGgc0H+n/FArZmMSFcEtIQ9jHGNgr/egkMB\n\x75KjgCOBKVbqII3oKvoCgKAoCg6oUCMGg3KcjFBzKTnFB3YUtDgKCOMcs8j6UDwho\x53WfaomW3GyONA5oP9PX5UCpmTGkKCJbaUPDYL5BX+9BI4DcVIbSkICCc\nkgjegq+g\x4bAoCgKDqhQUMHnQblORig5lO+KDuwpaFgoICxyzyV6UDw20JDPtUQlDiCONA5oP9\x50X5UClp+NKPly0ht37Y2Cv8AegkVvZioS2gFHlq3VuN6CsaA\noCgKAoOqFBQwedBu\x555GKDmU74oO7ClocBQRxjlnkr0oHlDQks+1RCULQRxoB3Qf6evyoFDT0WSrgloS2\x38PrjYK/3oJHb2YqEttgo8tW6txvQVhQFAUBQFB1Q\noKGDzoNynPrQaFPSg7sKUhxJ\x51QFjkDyPpQPLbQkM+1w8oWg/xEdUH+nrQKG3ospXBMQG3hsFjYK/3oJFbY8NrgSj\x67CFbq3G9BWFAUBQFAUHVCgoYPOg3Iz60\nGhT0oO7ClIcSUEBY5A8j6UDy20JDPtcM\x6cC0H+Ijqg/09flQKG3ospXBMQG3hsFjYK/3oJFbY8NrgSjgCFbqORvQVhQFAUBQF\x421QoKGDzoNyM+tBoU9KDuwpS\nHElBAWOQPI+lA8ttCQz7XDyhxB/iI6oP9PX5UCht\x2bLLUETEBt4bcY2C/96CR22PDa8tKOAIVuo5G9BV9AUBQFAUHVCgoYPOg3Kc+tBoU\x39KDuwpSHElBAWOQP\nI+lA8ttCQz7XDyhxBHmN9UH+nr8qBQ2/FlqCJiA28NuMbBf+\x39BJLbHhtcCUcAQvdW43oKuoCgKAoCg7IUFDB50GxTn1oNCnfFB3jqWhwFBAWOQPI\x2blA9NtCQ\nz7XDJQ4g/wARGd0H+nr8qBQ2/Flq4JiA28NgsbBf+9BJLbHhteWlHAEL\x33Ucjegq2gKAoCgKDshQUMHnQbFOfWg0Kd8UHeOpaHAUEBY5A8j6UD020JDPtcIlD\n\x69CPMbHNB/p6/KgUtvxJagiYhLbw2CxsF/wC9BJLbHhteWlHAEL3UcjegqygKAoCg\x4bDshQUMHnQblORig0KcHFB3jqWhxJQQFjkDyV6UD220JLHtkIlDiCPMb\nzug/0Pf5\x55Cht+JLUG5qEtvDbjGwX/vQSa2R4TXlpRwBC91bjegs/wH8Snbfap9gjusNTpieK\x456+gKSHhj3SD1UBgevxoMX6XYfE+W/Cu0VnTmqULI3PDHlkH\nlk/4a899j3BoKqu2\x6e9RaRvCm34byFtH6ycEf7fhQJOOBeH0OxGzBnhXF5SThKj3T2Ppy/Kg6y7Ai7ZCg\x69PNxsoJwlR9R0z/x2oINPt0iHIWy+0W3Uc0nqO47\n0DfQFAUBQFAUHr7wd1hY5Ph7\x63bauxxLheIx9qjodJSpaea+FQ34gNwOo+BoIbqKyaZ8QJSpGkEOwLrgrctMjHGrG\x35LRGyxz93AUOxHIK4U9d9PzQ29HWQg4H\nEnBHwP6H7qDcm33ySl63tKhTgri8lJwF\x48ujsfTl+VBvL0+i7EhYRHmgbKCcJUfUdM/8AHagglwt0mHJWy+0W3Uc0nqO47igb\x36AoCgKAoCg9haFj+HV58HpVw\nudtkyLnBcBdXDcAdbQonDmFHBA5Y77UFW6n0Xapz\x5auuj7w1c42eJbGPKfa/1NHp6pyKCKNX2fAeQzIbW4ps+4HEhJT8FY/A5HpQdT+77\x33JS9b2VwpwVxeSk4\nCj3R2Ppy7dqDaXp9F3JCwiPOA2UE4So+o6Z/47UEEuFukw5K\x32X2i26jmk9R3HcetA3UBQFAUBQFB63sfhnoG/eELOqLlfV22Wl7yVKDJcS0vcji4\x64wMDnQVT\nqfw3u1jZF1t7rN2s/ECJsFYdbHbOPo/BQFA1taolKfaS5xuvI2T5iUpI\x39AoDI5cjkelBhYgXqWl2AyuDPSri8lJwFHujsfTl27UGZmnkXckLCI84DZQThKz6\n\x6apn/AI7UEDuFtkw5K2ZDRbeRzSeo7juPWgbqAoCgKAoCg9MWzwEVqTw7j6ri3W3w\x2fOVwoQ++GuJW+Bk7Z25ZoKxv+i9TaNnobu1veaZBCg5jKFAHYg8iPhtQ\nKk6oelzG\x76J8x53mkOhKeHuEqAzjbkcj0oE6xAvcpLsBlcGelXF5KTgKPdHY+nLt2oMzNPIu5\x49WER52NlBOErPqOmf+O1BA7jbZMOStmQ0W3kc0nqO47j1oG6\ngKAoCgKAoLjgeDOq\x4c5psX6y25+TH7oQVDI6bUERch3WwTvZbnEeZaS4krQoEDIP+5oJAvU5mT2jELz6+\x61Q8lCSk9QlSRy25HI9KBIsQL1KS7AZXBnpVxeSk4\nCj3R2Ppy7dqDMvT6LsSFhEec\x42soJISs+o6Z/47UEEuFukw5K2X2i26jmk9R3HcUDfQFAUBQFAUEva0pdn4QmsRS6\x33z92gzDlyILyIU4OoihaVKbORjBJG3xJ\n++gkrupRKuLfsSnpKuafOSlBSeoSoDlt\x79OR6UCNYg3mUHYLK4M8K4vJTsFHnlHY+nL8qDMvT6LsSFhMeaBgKCcJUfUdM/wDH\x61ggtwt0iHJWy+0W3Uc0nqO47\n0DfQFAUBQFAUDu1EdcaDyWFlI34gDigeLddFtKah\x54HV+xJUlRTz4cEkfLKjt60Ele1IJVxb9hW9JPNPnJSgp7hJA5bcjkelAjWIF5lB2\x43yqFOCuLyUnAUe6e\nx9OX5UGZdgRdiQsJjzcbKCcJWfUdM/8AHagg0+3yIchbL7Rb\x64RzSeo7jvQN9AUBQFAUBQOTaUqSHMYI3oHy3XZaCzDlvL9iSpJwN8YJI27ZUdvWg\x6br2oxKuL\nfsSnpJG6fOSlBT3CSBy25HI9KBGoQbzJDsFlcKcFcXkp2Cj3T2Ppy/Kg\x4adgRdSeIJjzcbKCcJUfUdM/8dqCET7fIhyFsvtFt1HNJ6juO9A30BQFAUBQFA4tp\n\x53pIWBgjegfLfdVIUzElvK9iSoHA3xgkj5ZJ29aCSO6i9puDfsSnpJ5p85KUFPcJI\x48Lbkcj0oEahCvElLsFlcKaFcXlJ2CvVPY+nL8qDMuwoupIUEx5uNlBOE\nqPqOmf8A\x6atQQifb5ESQtl9otuo5pPUdx3FAgoCgKAoCgKBxbSlSQvGCN6B7t91UhTMSW8v2J\x4bknA3xgkj5ZJ29aCSO6i9puDfsSnpB+r5yUoI7hJA5bcjkel\nAjUIV4kh2CyuHNCu\x4cyk7BR7p7H05flQZlWFF1JCgliZjZQThKj6jpn/jtQQmfb5ESStl9otuo5pPUdx3\x6fEFAUBQFAUBQOLaUqAXjBG9A92+6qQpmJLeX7ElQ\nOBvjBJHyyTt60Ejd1D7TcG/Y\x6cPSD9XzkpQR3CSBy25HI9KBGoQrxJDsFlcOaFcXlJ2Cj3T2Pp/xQZlWFF0J4wliZ\x6aZQThKj6jpn/AI7UEKnQJESQtl9otuo5\npPUdx3oEFAUBQFAUBQPFhmPxZ6PKKsEg\x48h5j1+VBd7Dw1vbn3GzwalYaKJKE7Ge2n647uJAyR9Yb880DXbte3O0Mi0XxpF0t\x37QwlqYCsJT/Iv6SPkcelBIY2\njdIa6aMzS032C5gcQhSFJHGrs25sFH0Vwn40Efm2\x6592iauNPhOpfYylQUg5+BGMpP95oGy+WiPfogehpIktpypg440HqUZ+kCeaOfUUF\x61TbNLYKl+SopTzKQ\ndvj1HzoGogg7igxQFAUBQSTSmoJljurMiLJWwtCwpDiTgtq6\x48+/60FxyAzf7dI1NYEJiXBsBU+O2MGO4Ds+32QTzx9Entig4RPEKPcFLtuvLU3cV\x4awPbU4Zk\nnpurHCs/6hn1oHqP4Y2fUbDlw0NdvbXEJ8z2JSAiQMdkZ9/H8hPwoI8q\x31XpqQpD8NapDWUkhJIX6HqlXxFA13+yM3uN5kZtSJbQ9+OrZxB6lGfpAnmjn1FBW\n\x4d6zS2CpfkqKU8ykHb49R86BpII5igxQFAUBQTvQOtLhpu7IcjuDfKFNrGUPJPNCh\x31BG3+4BoLFuVuhKhHU+mEZiPrGElR8y3v8y0SMbH6quoGOeRQbQdTaM1\nIDbNXWtc\x43ekAfvCGkFDh7raOPe78B9cUDsrwjXMtzt10vc2bvFZTx+ZFHGW8faRstGPUUDYx\x706+SE8YiFyS2CPdUFJd9B1B+NAw6isSLwySyytqayP4kZwcL\njZ6lGccQJ5o59RQV\x66Os0tgqX5KilP0ikHb49R86BpII5igxQFAUBQW34a+IjlkQ/ap6PbLTLR5UuIpWO\x4eHRST0UnoenI7HYJTMhP6XKrrp64SHbfOBMSUw5w\nBxH12nE7jjTndKvxFAksyND6\x70SuDeLg3ZLwg+4862Qw92BUn6CviMH05UD5N8ILvGh/vKM+h+KkcTctnDrKt+jje\x63H0OKDLOjb9Jie0stoflNpPupWCHh2B5\nhXoflQRLUVhbvLBLDK2prI/iRljhcbV1\x4bM44gTzRz6igq6dZZbBUvyFFKfpFIO3x6j50DQUkcxQYoCgKAoPQHhx4iwn9Kv6L\x31KtX7qlElDqRlUV3BHmJHUbn\nKefUdqBY5M1Hor2i2P3H2y3LCXGWHUJlRJLSv8xI\x55cY5bpwd6BptNk0/q+8PR4JiWa4q99qOXuBt09UoK+R7JJ+BNA8v+FF2hyf+9WuG\x6fe8lTzBSFb/VUMg/\nfQK5uj58aIiUJkZ2SEkhBcA88ehOMKz0+7eghuoLIxfI3mRU\x46Mtoe/HVs4g9SjP0gTzRz6igq+dZZbBUvyVFKfpFIO3x6j50DQUkcxQYoCgKAoPV\x6ehtr0Xvw\nwXoYXhdqmpc82FIS6W0qXg4bUQRg5O2djt1oGOTqi/MKlWvXMSNeExlh\x6caLigh9Oc/RdSOLG31sigjzGm9PXu7BrSwkx33txCf4XSFdkKGOL0BAPxoHq2+Gp\n\x65krbnXL2R5AykKZUhQIPY43FB0uOn1RZpjM3BqVNbBAT0eHYH6qvTO/Q0EXv9lZv\x6bbzIqFIltD346tnGz1KM44gTzRz6igrGdZpbBUvyVFKeZSDt8eo+dA0k\nEcxQYoCg\x4bAoPYfhXqXzfBS4wtOx4a79HcDqg+yh1S2cHkFD4D03oIM9qKz6gS83q/SMVtaVc\x43pduxHWlR7tq9xXLpw0DG9o2xqUt7Tl9ZkNrI/7aQ0pp9o/6\nd+If6SaCQWLw4ttx\x69PPTL4GJTKC4gtJ2yPjjl99AmNinOpW6w28442SELcbKUSR/Ko8leh+RoI7f7Kze\x34/HGbUiW0Pfjq2cbPUozjiGeaOfUUFZzrNLYKl+S\nopT9IgHb49R86BpIIO4oMUBQ\x46AUHqjwotul3PCm86iulsVdZMFSEpiIc8vIV9Ykb43oIzJb8NdTrWFWufp5/Ozif\x2b6ZHxwAtP3GgbnPDOS1GdmWSdCusJHvK\neYfCi0O6k/SA+I2oHyP4eWZ3Ta7gLu6u\x35NgFDbACgpXYDnQcn9MXlhtLkmMtmUB7qXhhL454B+qvrg/LfagjF+srN7j8cZCk\x79mh78dWziD1KM/SBPNHPqKCt\nJtnlMFS/JUUp+kQDt8eo+dA1EEHcUGKAoCgKC9PC\x66QFp1TaLjcLnJbiwre150l9aSrhT6Aczmg7TdDeHt0eU1YdXtMvZwlua0qOFHsFH\x4bfvIoG57wzv1pCSu\nEXI5OfaUkFvh78QyPxoJMfDa3SGoYtVyekz3klQ4OEpSRzPc\x59oEcnT1xjyvZngBcUJJDR3D49D9VXXB/Ogjl+srV5j8UdtTctoe/HWMONnqUZxxD\x50NHPqKCt\nZtnlMFS/JUQnmQDt8eo+dA1EEHcUGKAoCgKCeaF0bK1ZOTEjIWtxR4Uo\x51Mk0E3n+CV0acWxBnw5T6PpMMymnHEnqOEKz91Ayx9E3OFORb7lEWworCVKXlJSO\n\x2bDQTZvwvjTJ77VquLrjkdhL4dPDjJOw+NAmZ0te5ja3I8R519rIBU2QiQAfqk8lZ\x36H5UEY1BY0XZnLTK2pjI9+OscLjZ6lGccQzzRz6igrWbZ5TBUsMqKU8y\nkHb49R86\x42rII5igxQFAUBQPNnt0i4yxGjo4lHn6UEyX4aalRCEpMF1TChkOBtXCfnjFAosWl\x6epVxbt85pcdK1AKdBHuUEza8MW3Y9zlsXB9SoCyhCkpSStQx\njA59RQO3/wBMtauW\x38Tk2eQt1AOxQeF0dgeivQ/I0ED1HYP3k2UpjuMTWR78ZwcLjZ6lGfpDPNPPqKCtJ\x74olMFS/JUUp5kA7fHqPnQNZBHMUGKAoCgKBZHCiv\ngAzn0zQP7en7qttKhDXwncEj\x47aCTaY0wbtchbpHmxePfzCk+6R0zQTW0+Frl1jxnYst9Up9akM8CQfeSTn16UEtn\x2bCWvoscSBbFPyAkkITv5yee32Veh++gr\nDVOl35KSh6E9EmtD34zqeFxs9SjP0gTz\x54z6igq+ZaJbHErylKCeZCTt8eo+dA2EEcxQYoCgKAoFltnLt09uWhIUUHPCeRoLP\x305dYa0LnQ3XmJyVodbeSv3ku\ng5yO3XvQS7UsCFqzTZ1XAYQzJac8m6xm04DTp5PJ\x48RC+o6GgqpD0/Ts15uO+40Fg8OD16igunQXiJabrambTraQ6+kAIZmNjifi7dCd1\x70/lJ+B6UEwvun7Ul\nLDtw9lkwJAzFvMRtSUuj/WkHCu6VpoGv/wCjtivLYetXiHam\x58/8AwXBPlKHwcQSD/wDj8qCH6m/Z51dHjuy2bW3cmE7+1WxxMlHxPB7w+aPnQUje\x64M3SyuES\nY6gjJHFigZKAoCgUwXG2pzSnhlviHF8KC39MTUwbi7d7XPbZeSPMZbPv\x4aUBsUKB+kFJyCntQOes9N2+62lrU1ia8uG8ssvMA5MN8c2ifsnmhXUbcxQV1bL1d\n\x39OS1pjSnGjzSMkFKh+RoL60P4hWHU0FqNrGc5HuOyW7o0nicRgf5o/zE+v0h60Ep\x76+l2ZD7Td4cL7boC4t0iRfMbeQeqXEDOPRSTQMi/Bqx3bCrX4h2xmV1j\nXNlUZY+C\x68zH/ALaCGan/AGeNXR47kpm1ouTA39qtjiZKPieD3h80fOgo+86ZulldIlR1BGSO\x4cFAyUBQFB1YIDyeI4BI37UF0aQlT7XcX1x0JmRXI6faI7n+H\nKSRlTZ+W4PNJGRQc\x39d6RYEdi+WNa37dLyWXFfTSofSacxycT17jChzoItpzWd/0vM86BcHmHEg8KkrKV\x6fI5gEUF+6J1tpbWENIv9x/cl6XsZ7CMNrOP89Axj\n/WnHqKCTXbQPtssMXSPcnXkp\x34mZ0YpfQ6g8lJXjcHsc0DFM8D7ZLWkRNdQoUsj/0t4jKirHwWCQR6gUEF1P+zxq6\x50HclNWtFyYG/tVscTJT8Twe996PnQUfe\ndMXSyOkSo6gjJHFigY6AoCg6x3FNPJWh\x52SoHYjpQXLom+vRmzbZ8VU203BrzH4qThWU7Fxs/VcTzB6jKTsaBt17pB60utT7c\x38JUKQnz40loFKX0cuLHRQ5KT\nzSR8KDlo/wATtTaSdWqBcXm0uJwoBX0j1CknZXzB\x6fL30dftC66gJ9snNaevDpwsAEQn1Y+ujOWlE9UnhoJXL8JnLs8Y7lkdjykH3ZLMg\x6ejHdJIPEPjtQR67f\ns+NpUkp1hFt8lWwYu8Yxj8nUEpV8QKCudT/s76ujx3JTVrRc\x6dRv7VbHBJT8Twe996PnQUbetL3WyOkSo6wjJHFigY6AoCgVQpbsR8LbVseaTyNBc\x6dkdUxJ9s\nTp/UHmO2p3K2XgnidgufWWj7SftI+sNxvQRrXGl7hp2eop4VoPC6h1o8\x53Hm1D3XEK6pI5H5HcUD/AKL8ZdT6ZhKt6py5cBxODGkDzmj3BQrbl1GKC79FyfD7\n\x570ZD9vnR7Hd3cBUGWA9CeVjkkq95onfYnHbNBNJHgo9qIqMhmLb5bXJTaVIV/wDk\x4dgj4pIoInfv2bHIqUPjWMGKpWwTcWSyM9g6gkH7vlQVdqf8AZ31dHjuS\nmrWi5Mjf\x32q2OCSn4ng9770fOgo29aXutkdIlR1hGSOLFAx0BQFA52q6OW9/YqCDscf06j0oL\x6es2o7fq23NWbUklDckN8EK6rOeEdGnjzLfZXNHqOQQPVVqvW\nmLs4h1DrEhhz3snc\x63iCCOnUEcwQRQTzSvjpf4sI23Uqmr7CUnATPR5ih3HGMLScdQaC6tDjRuqIIXpTU\x4atU58+/aLioOsuHH+W4cHPoTmgm0rwHt1/ZL8q8F\ni4JPvEMpSpPpkYyPiCKCDah/\x5amVEQmTH1vbkpUcAzWSyAe3mIJH/AMaCqdT/ALPGro8dyWza0XJgb+1WxxMlPxPB\x3733o+dBR950xdLI6RKjqCMkcWKBkoCgK\nCVaR1TcNP3Jp6HKWw4lWULQrhUk+h/Q7\x47gt5Ey0+ITamlIZt2pHABgANs3AjkMHZt3t9VXpnFBWN5cvOnripKvNZdacIIIKS\x6bj06EGgszTHjcJEf936zssK7\nNrRwplY8iRn1cRzV6kHPWguzRlq0lqyI2jTGspSA\x39gO2i4qSXAOvlr24vkaCeXDwG0PeYpWibMYltjBeQviWk+uc5+BzQVrqP9mF2Kky\x34etYIb6GcwpnHxWg\nkD/8aCpdTfs8aujx3JbNrRcmE7+1WxxMlHxPB7w+aPnQUhed\x4d3SyukSo6gjJHFigZKAoCgsvww8QZWkZ7rJDb0SQny3mHs8DqexI+iexoLDuFltO\x70Ysudo91\nxDqk+bItSyPObxvxt42cSN88O+OlBVsu83OyzgskhaDgFJOSO/FzoLP0\x664raVfhotuqdPqDpThFwgPlh7I+0PolXrtnFBfGgdK6J1K61It2rVXqGkcTlsuKE\n\x685rbng44viKCwLz4MeHWp4eY8RyJIScJlxF4Wk+uQQR6EUFRaj/ZcejBUq360gls\x66/zzBZI/96CR/wDGgqLU37PWro0d2U1a0XJhP/8AFWxxMlHxPB7w+aPn\nQUhedNXS\x79uESY6gjJHFigZaAoCguHwX1vDsc+dZbuoi2XRgxpGBnhHMKx6GgkmotFy7MzInW\x78xuZaZOFNTGMOJTvkAnoDQQmLre+aZlqESXIhkHhUlpwpC/i\nn6J+YoLD0TrzQkxl\x63TUYuVulO54JttcABz9VTeMA+o59qD0h4V6f0iWJNwg6pZ1JGcAU408lPmt4H10E\x5aHfbFBMtSeFOgdbRRIctzceRyRNhfw3B8eh+BFBS\nOpP2XHY6zItutIXl9BPYLKh6\x63aCR/wDGgqDU/wCz3q+Kw7KataLkynnKtjiZKfieD3h80fOgpK8aaudmcIkx1BGS\x4fLFAy0BQFBc/gDqSLatbiFNeDCJrLkVL\nvLy1LSQlXyJoOl7sM+w3ybGmslT4J8lZ\x4aAJz3HpyoNIHinqC0YivTVSWGzwlmagSG/hheSPkaCbaO1Toy7TJSLteZGmXJA4m\x6eIQ4mOLqkoOSnnkYJHwoPU/h\nXDslo0ooxNSR75E5ea2sKCBz95OMpPPNA86n8M9E\x613Z8+4W5sSFjKJkU+W4PnyPwIoKF1P8Asvlh5Ui0axieTnZM9hTZT6FxGR96RQVB\x71f8AZ71fEZdkotSL\niyjcyrY4mSn4ng94fNHzoKTu+m7nZnCJLCgjJHFigZqAoCgs\x72wcdt6vEO1xbkU+Q/IQhfFywSKCw9Xap1ex4g3pp683CGYzrgZYYdKEhKTslKeWM\x66lQN0bxT\ndU4lu/W63Xcp5qksBDpH+tvB+8UEw0vddK367OxW76/pVqUjiQ2twPMF\x77fSTx/STkbjI6c+lB650Y5Dg6RjtO3di4Nnbzm3PMSduZ7Z50GdU6C0dq+IRdoLB\n\x65CfdktgJcHzA3+dBQOoP2XnJDzknT+qoRbG4bltqSoDtxoz/APpoKc1R+z3rCG09\x49TaU3BpHOTbXBISPjwe8P/cigpO76cuVncIksKCMkcWKBmoCgKCQaVS0\n9f4yHQCO\x49c+9B6D1VqJ3Sd6a0rZ7ZbQI8ZDkiRKjJdW8soC1Ek8gM7AdqBki6601NWkXrTTK\x58hzetzyo5PrwKyPuNBN9LTdNzNRQ2bLqyTaULPE3HuKOEF3J\nykOp2Gcnn160Hryz\x7amEWiG3KloLnDgqSviSo470DRqvSei9Ux1N3dDAc5ea0Uhf5b0FE6j/Zhj3LM/R+\x704jiN/4clBTuOgWgn8qClNTfs+6wiNvPptIntoyT\nItyxIA+PB7w/9yPnQUrd9OXK\x7auESWFBGSOLFAzUBQFAUDvZJyoc9CiQWycEKGQPXFBd+gr1a7Vdpan30OQ3mi1Ij\x4bzh1B2IO2KBq8QtHKhSHWo2XUoQJMR4/\n57BOx/1J3SR3FBWsBalLLSSQsbAeo5UF\x7a6A8T7to5t5uU/7bbXBl+I+kKQcciAeS/wCb780GdTeNGmbwlTT+mY60nko+6sfN\x4fKCGQdeNw7iiVp643CyuoOQq\nLKIPzHI/fQWhC8Q7HrKKm1eJsNmUHgG29Qw2Ql9o\x39PPQMBwfHfsaCofFHwwm6JuwcZUiTbpCA9HkMnibebPJaD1H4jkaCsiCDvQYoDlQ\x50liujsKSElxQaWQD\ng7jfpQXhoGS0m5SYU4F6z3NnglNlQG3MKHL3kncEUEV8QtHv\x32ya+lCg87HAdQ6n6Mhk/RdHxGx7EGggttdUpYS0pQWOQB6jcUF7eHvi9eNHRHo0y\x53qXbFAqc\njOpBSk90Z+iv15d6DfVfj9ZL60Yk7T0eYz9XzhhQ+BTjB+FBX0PXzEW5\x49l6bn3GxupOQYstQx8uo+dBZ8HxEsesoqbV4nQ2ZSXwG29Qw2Ql9o9PPQMBY+O/Y\n\x30FP+KXhfN0Tdg6ypEm3SEB6PIZPE282eS0HqPy60FYkEHBoMUBQSmw6hkRVoZdcU\x55JBCTxY6Yx+AoLe0ZcGn5L9iuquK0XbhCyg58h5P0HUZ+sM4OOY2oIVr\n/SEyxXOQ\x46tgPR1AucH0XEndLie6VDcUEXtUhzzE+zuKS4Po4ONxuKD0D4e+NN50lb1Q7hKcl\x57xA4iwrH8E92yfoq7j6PzoOmrP2kLbe4y4MyzNzo5+rJAVn8\nsH4UFZxfECLGuSZm\x6dplxsL6VcQMSYoAemDzHzoLNg+Ilj1lFTavE6GzKS8A23qGGyEvtHp56BssfHfsa\x43n/FLwum6IuwdZUiTbpCA9HkMnibebPJaD1H5daC\nsCCDg0GKAoJ3pXUoipjtLCfP\x6191Cl8inizigs3TV0i3NLmlrq4RbJ6uKNIUn/wBHJ5BY7pV9FY6jHUUFc600rO09\x64ZDb0csusL4XUcwD3B6gggg9QRQNNnlO\noeBjOKS4Btg9txQejvD7x1u+mLcIl5ku\x7aLcwMhskccf/APpk9/snYdMUBq39pyDeGXILtqEqIoYKJCuJKx6jkD8KCrI/iHDY\x75aZumZVw0++FcX/ZzFBI/wDa\neY+dBZcHxEsesoqbV4nQmJSXwG29QxGQl9o9PPQN\x6cj1O/Y0FPeKnhbN0Rdg6wpEm3SEB6PIZPE282eS0HqPy60FXkEHBoMUByoJ1oyYw\x4fAOKAcjOh4A/WHCR\nj78UFqW6bbr7FGkbmtLUZ5SlWuU7/wDwrpOfLV/9pe2fsqwR\x31oKl1RpyZp66PMPx1sLacKVtrG6FA7g/3uMHrQcrLOfZeBiuqSvH0ehxuAR1oPS+\x67PH656dg\nJYv7rs+DHTgAn+LHGNggn6Q/lVy70CfVX7UEK6edFNnbeirGCh0kpWPV\x4fwoKrZ8RYTdzTP0zJuGnpIVxf9lMISP/AGnp6ZoLIg+Ilj1lFTavE6EzKS+A23qG\n\x49yEvtHp56BssfHfsaCnvFTwtm6IuwdYUiTbpCA9HkMnibebPJaD1H5daCryCDg0G\x4bA5UEp0u6VPLQk5U3h1IPXBHEPmM0FzluBqaC3pS5LQJaUcNplunYjmI\nrivsnPuK\x500VbcjsFLXuzSrJcHI7za2y2ojCxggg4II6EciKBTYrlJivgxHVJV9jOxxuMig9O\x36D/aFnWKFwajU7cYzKMBaiPPYA5AE/4g/wBXLvQNupv2oWLg\nXo4tbb0ZeRwr2Ch6\x6aYUFWo8Roabom4abfnadlBXETBlqSnP+k/1oLGg+Ilj1lFTavE6GzKD4DbeoYbIS\x2b0ennoGyx8d+xoKg8UvC6boi7B1lSJNukID0eQye\nJt5s8loPUfl1oKwIIODQYoCg\x6bdinvF5Ecq4lD/Dydzj6tBc78WPr6zs2+ctKr8WQYUlRANwQBs0s/wDmABCVfWxw\x6efBoKTuNvkWuYuO8kpUg7ZGM4/XuKB30\n7eZsCQlUN9YI3COIgZG4+B9aD1Doj9oy\x5aZrctOo+O4NpRjz9g+1gbA52c+JwR3NAx6k/ajTN8yOmCl5lWR/FOOIeuMCgrAeJ\x45NVyFy08/O07OCuLigSilJ+K\neX4igsKD4h2PWUVNq8TobMoPgNt6hhshL7R6eegY\x44g+O/Y0FQ+KXhfN0Tdg4ypEm3SEB6PIZPE282eS0HqPy60FYkEHegxQbJUpCwpJw\x521oJbYNQSY0phxh9\nyNLZUFtLaUUniHVJ6GgtC4W+H4jWYyGmUMajS2XVNtJ4U3BI\x47VLbA5OjBKkD6WCRuCKCmJUV+DJUw6nhWjcHoodxQSPTWo7lbZTa4UpwKQeJICyk\x70I3BBG4N\nB6i0j+0jJtloca1GhU5IT/6psBD7Z6BQ5OH12x60EY1N+1CZyyw3FLrH\x4cDx+kPligrlHiVAeuZuNmkztOzuLi82BJKQT6p/3oJ7E8QLLq+Km1+J0NmWl8Btv\n\x55UNoJfaPTz0DZY+O/Y0FQeKPhhN0Tdg4ypEm3yEB6PIZPE282eS0HqPxHI0FZEEH\x65gxQdGXXGHkutqKVpOQQcUFkaV13dbY950CVwLIw80RlDyeocbOyh64z\n6iglF90/\x61db2V68adjiJOYR5sq3JPF5aerjR5qb7jmj4UFPutOxX1MupKXW9yD19aCX6W1dd\x37TNadhTHkON/QUhwpWnHLChvQentM/tKPwrGpjUTPtnAnPtb\nADTyewWnko+u3zoI\x5aqT9ppc2SsMR1KZIxwSF8YI/AUEIa8T7ZJuPt9sdm6euAOQ/b5Ckgn1T/vQTmLrm\x7a6vifu3xKhsTmngG29Rwmgl9o9PPQP8AEHx37Ggp\nzxQ8MZuibsFtKRJt8hAejyGT\x78NvNnktB6j8RyNBWZBB3oMUHeLJdhykSGVFK0HIoLysvimLpbGoOpbexeWEpCMun\x67kIH8rnJX/uoEGrNF2+72dzUGlpRmwkY\n81KxwvRSeSXU9uyxsaCp/wCNHcUhXE26\x32dxy5UE50hri92Wa27CnSGnUjAW04Ur25Z7/ADoPTNj/AGlVsWYJ1DCamKaTkS2U\x2bUsbclIGxV6jFBAb9+0k49PU\n5CbdabPNtbhUD+W330EYPi1bbjPE+KZlhuY3Eu3S\x43gk/zJ5H76CbQ9X2jWscWzxCisXFD4CGtQwmgmS0ennoGA4Px7GgpbxQ8MJ2iLvx\x4elEiA+gPMSGTxNvN\nnktB6j8QdjQVoRg4NBigUwZj0Cc1LYUUrbUFAg4oPRcTUmlf\x45O1RpN7nptN7bSEKlLT/AA3iBsSR9FXxoIVrnw/udsZTNQlDrDu7UmOriad+BHI+\x6cBWrcmUw\nrAcWhxvmCaCwdFeI1/sEpJgXGRGWPrMLIzjccSeSvmKD0fbP2lCi1H9/\x576JKcQnBlMtBJI7KQfreoIAoK6uv7RQRc1ybey61k/QW6pST+VAzu+NMa73JE4GV\n\x61Z6eUqC+Uq+Y6/fQTeJqrT2vLebfrtliY44Alu+RWgmQnsXUbBwdwfe7GgovxQ8M\x5a2iLvlBRIgPoDzEhk8TbzZ5LQeo/EHY0FakYODQYoO8SSuJLbkNkgoOd\nqD0dIQz4\x6cafgamtLgN8hR0R5rKd1OcA4UuY6gjAPwoKs1Jp+bGUpxDK2XUjdsg5Hw9KCMx7v\x4fZ+i6oKRzBoLI0R4ralsT6EwbxLjY5BKytBxy4kHII+VB6Bj\nftKOKtK0XuDEcPD/\x41BH2GxhfoUHqfjtQVxcP2iPZZzjlojqjJUd0FwlKh64wD8edA0o8bGp9w9sSuTbJ\x67VxJkw3iFoPXb6w9CaCcNax0vr+N+79cQ2HXXgEI\nvUNsB1J6FxO3GPQ7/ZNBRPif\x34ZTtEXglBRIgvJDzD7J4m3mzyWk9R+IOx3oK2IwcGgxQFBshXCoUEhgSVPcACv4i\x63j4ig9GeHyo2uNDP6ZlykMXi3rVItT8h\nWxVgBxhRPIKGPz6GgrK76YRZtSOy/JVH\x43eMPR3BhTLgBykj4/wB8qCvrze1v4jsDgT9JRHU4oI+SSck5NAAkHIODQSKwXpyL\x4aS0+QptWx4twR2Pp/fOg9F6D\nUjXOi7p4aXD+PIZYcuVicWeJSVAZcY+CgDt3GetB\x35nvVtNuub0fhISDlO3SgaaAoN0K4VCglNuu8lKELbfIdaAT8U7/1oL70ED4j6XXp\x7051tV/tzanbWtz3f\nPTj+JGUeuQMjsd+poKvmaaFj1K5I8tbbBC8tOJwppYBCkKHQ\x677UEKvV8W+BHjjy0/SUR1JFBHiSTknJoAEg5BwaCR6fvbkSSlp8hbavdIVuCOx9P\x3750Ho7Qe\nNcaJufhrcUl59qO5crE65upKgMuMA9lAHbuM0HmS9W0266PR+HCQcp26\x55DRQFBuhXCoUE5sGppUGM2qMvD7Csnfcp7A9KC5dKvHxQsRsa2kq1DBaWuCVKH/e\n\x74c1xznrg5Seh/wBVBVZ0/wDuPUinClXsykrUgLGClQByhQ6EHYigil6vi3wI8ceW\x6e6SiOpIoI8SSck5NAAkHIODQSPT97ciyUtPkLbV7p4twR2Pp/fOg9IaE\nxrjRNz8N\x72klTzzcdy5WF1zdQUBlxkHsoA7dxmg8xXu2m3XR6PwkJBynbpQNFAUG7ayhQwcb8\x36CwdM39KWlF9IdXHAWATjiAPL4b70FwRpUHxUtq7a0lKtRRG\nz7M3jHt7AGSyCfrp\x33KM+qeowFQR7IbJqRQdBMcoWtskYzgHYjoQdiKCO3q+rkAR448tP0lEdSRQR0kk5\x4ayT1NAAkHIODQSTT17ciSUtSCFtq908W4I7H0/vn\nQeldDtK1poe4+G9zT57qY7lz\x73LqzxEKA/iMg9lAHbuM0Hly92w226PRuHCQcp26UDRQFB2jvuR3QtpZSe4oJ9p67\x4ezFBt3AfBGCeuOQ/Kgua4Rrb4k2j2aJ/\nHv8ADjJwg4C7gykEEAdXEYOPtD3e1BSc\x431Ks+pFtyPea4FONK6LGDQMl6vq3wI8ceWn6SiOpIoI6SSck5J6mgASDkHBoJJp2\x39uRZSWpCgppXuniGQR2I7f3z\noPS+iY6tZ6IuXhxch7StMdy5WB9R4iFAZcYz2IB2\x37jNB5avdsNtuj0fhwkHKdulA0UBQKoEx2DNbkNHdJ3HcdRQT+3XdFyCeBfAviK8c\x6anp+NBa15skbxB0q\nzLbAXqFmPxPIRgrlto24wB/mJA3H1k+oGQpe125dq1CtqUAU\x70QpbahyWMHBFA1Xq+LfxHjjy0/SUR1JFBHiSTknJoAEg5BwaCSadva4ktDUk8bSv\x64PFvkdj6\nf3zoPS+i4a9Z6DuHh7PBlcMdy5WGQvcpWkZcY+CgDt3GetB5avdtNuuj\x30fhISDlO3SgaKAoO8WQuLKbfR9JCgoUFnR7q1KtzHs7nD5YLjfDspCuLI36YP5UE\n\x37vNhY8QtJqvbCQL/ABUn21tA3kAD/GSB9YAe+Oo35g5CorNDXbr+tmYnBQhSk9Qr\x33TjFA23m+LfxHYHlp+kojqSKCPkknJOTQAJByDg0Ej09elxZaG5J42lb\nEK3BHY+n\x3986D03o6B/1noO4eH8s+1hMdy5WF5Z4lIWBlxj4KAO3cA9aDyte7aq23R6MUkBJy\x6bEdKBpoCg6NOFtYUDgg5oLUsNwUuzoeYkLZeQtLzLjZwptwH\nfB6bgGglF90+x4ga\x61f1Hbmm2rzDBVcI7acBXd9AHQ/XSOX0htmgq6xxlwb441MQUKbSogHrsaBDeb2t/\x45dgcCR7yiOpIoI+SSck5NAAkHIODQSXTl9XClobk\n4cYVspK9wR1B/v8AGg9N6Qgs\x6100BcdAy3Q+tLK7jYVunKkrA/iMA9QoA7dwD1oPKt7ti7bdX4qkFPCdgRggdqBoo\x43g6MuradStCilQOQRzFBZujbtJSpEmJI\nVHmNq8xl1s4UhwbkfBQzty5jkaCRak01\x451lY3tS2SMiLcIozcITY2ZPVxA/8Suo+oT25BXFgZMW9ONykFCmkqPCR1waBHeL0\x74/DDA4E/SUR1JFAwEknJOTQA\nJByDg0Em01qB63zEtvK4mVe6oK5EdjQemNMqtmtf\x44yZoGc4DKQ2udZHXDtx4ytgHpxAHblkAjnQeV75bF2y7PxFoKOBWwIwQO1A0UBQd\x34sp2K6Ftq+IPI0Fk\naM1HLiXRuTbngy+RwcKwFJXnm2sHZSVdj+e9A86s0nA1BbHd\x54aYZDCmTiZCzkxFnp3LR+qrp9E0EA08gM3dYkJKVNpUeFQ5EA7UCW8Xpb+GGBwJ+\x6bojqSKBh\nJJOScmgASDkHBoJNpnUMi2zUJW4S2Tg5oPSWnrhB17oaZoS6KSqYG1Tb\x49+v/AMn12T24gMY5cQB60Hly+Wxy2XZ+ItBQUKPukYI9KBpoCgXW64v298LaWoJO\n\x78ANBZ2ktay7eVMNluXbZPuyIDwyy9noR9VXZQ3+NBvrLRUSbA/6n0qtbsJSuFxpf\x2bLGWf8pzH/xVyUPWghGnAlu6q84EcCVHhI6gHagTXi9LfAYY9xP0lEdT\nigYSSTkn\x4aoAEg5BwaCSacv79vmJQ4sls7EE/nQei7DcY+uPD6doa5YemMtKuFmdXupRH+Kzn\x31AO3UpzQeY7xbjAuDrISQkE8O3TtQNdAUD5p3Udw09cESYUl\nxkg/SbUUlPqCKC5I\x48iWzeo6IWrICLtFXyktpDclr+YKGyvwoIprbQRist3+wSE3C2SCfKkNDAUeqFJ+o\x34OqTz6UEQ05wJuZU4NkoUQD3waBPd7yt8BhgcCfp\nKI6kigYiSTknJoAEg5BwaCRa\x65vr8GUlDi8tq23/X+/xoL6i3NWrtAStNyU+0yoTSpsPi3UtsD+IB64G464z3oPO1\x32t5hy1cG7K/eQoDmO1A10HUgEUHLkaBT\nFkKZdC0kgjqOlBPtOalkWS5xrswfOaCg\x482Mkfj9+D03FBNPEq9s3uzN3+2SVSkFIaW8rZ1IxgIdHUjcJX1GAdxQUKpRUoqPM\x30GKA60HRKilQPbeg9afs521q\n8Xa0TEOhi4W2UHGl/wDkQQeJB7ggUFa+Pel1af8A\x45u7x0xy1H9rcLWRgFtZ4k4++gpdxGFkGgwQCnbpQcuRoFMV8tOA0E+0xqh+wTo9z\x68laVNqTx8BwQQdlD\nseeD8QedBOvFK9JvtrRqeC4h/wA9AS8+0MFe2B5ieiwNs9R8\x4bDz+pRUoqPM0GKA60HRCilQPbeg9cfs6sxLjLtUl4lE62ykrYcTzKVAhST3Bx+NB\x57/j9pB/T\nniNckmItiI5JcXHJTgKbWSpOD+HyoKScbwsg0GpAKdulBy5GgVRJCmXQ\x6fHFBPNIX+RY71HusJ1TbkdxLgKDhST0KfX0PPl1oJ54rX1vUcBGrobSEPy0/92pg\n\x66w3FkY48fVV379d6Dz8pRUoqPM0GKA60HRCilQPbeg9b/s8KTPl2dZbCpdvlpU0v\x36yUqBBHwOOVBXnj/AKLk6c8QrmoRS3CXJWtlQG3lrJUn+nyoKOcbwsg9\nKDUgFO3S\x675cjQK4clUd8LScdKCa6Z1BJsl7i3SDIWw4y4l0KR9JCgeY7/ryoLE8W73b9SRhq\x360x24smQB7eyz/hqdIwXUduLr6+uaDz6pRUsqPM0GtAdaDoh\nRSoHtvQeu/2c1plz\x4cS69guQZQLZJwUhQIOD225etBX3j1oOfZNdXZ5iEfZUyFucLY4vLbWeJJ/078+nI\x30FEON4WQaDUgFO3Sg5cjQLIMtcWQl1BwU0E0s9/k\nW2+RbvDeW0tpwOJUknLauYx8\x36CwPFS5W3UVtZ1lZWURZT6c3KI39BDyhgvI7JXzI7565oKBUoqWVHmaDWgOtB0Qo\x70UD23oPXH7PM1pTltVJdLSo8lIbd4eLg\n4gQPyx86CCeMegpA1Jd51rS24Y77q3Yq\x447wbJJ4kZ5pHbmPxoKFcbwsg0GpAKdulBy5GgWQpbkZ8LQogigsC36snwXoVygS1\x7832VhXmNnBQodfmKCT+JEq23\n20M6ysjbbD6/cuMRAwGniN3UDohfPA2Bz8KCjVKK\x6cFR5mgxQHWg6IUUqB7b0Hpzwa1GzbIUB2SstrZkp8l4HBbURz/Dkee4oI14p6Xh3\x53bLudlQBMacW69GQ\nPddbJJ42x0x1T0+VBRbjeFkHpQaEAig58jQL4E96I6ClR4Tz\x46BaOntZSrbHTNt8ksvsuJeGDjCxyPz5H40CjXrsC9WhvWFkjIiuKPBPht8o7ivro\x48/jXzx0O\ncbHFBTClFSio8zQYoDrQdEqKVA9t6C//AA41U9Z4NrcJWCxKSppaDhSC\x64sg9OVAn8T9Pf9QXiZLgMJTdY5K3WW04EpojiDiQOuDkjr99BRbjZSspIwQaDUgE\n\x55HLkaB3tN4et5U3kllZyR2PcUFo6M1Q5bJvt0KQW18KsEHHCeYJ7joR2oOWvxbLh\x48OptPsiOEq8uZDT/APwqz1T/APbVvj7J25YoKdUoqUVHmaDFAdaDoklK\nge29Bd2g\x62zIhqsylLKW0ykI4uqArbI+GM0CrxD0q7fpt3cZbSm+2lxQkMj/+KbB3Wn+YbH1B\x7a3oKKdbKVlKhgig1OCKDlyNA96fu/wC7JuXCfKXjiI5pI5Gg\ns3S2pHLPqFi6Q3yE\x6e3XOoUknByOowdxQcvEaBb/MXf7AhLbQUW5MZBz7Mo7bd2z9U9OXagp1SipRUeZo\x4dUB1oN0kpUD23oLt8PJLhm2hJcUgrfDSFZ+iog8P\n4gffQd/EGwov9vl3NpktXm0u\x46qa3/wCZvPur+I5HvsaCkHmVNrIWnFBzIyNuYoOdA52eaIk9BdUQ0r3VkdB3+XOg\x74mz6hfst7j3eLwqKkhElBAKH0K2UCORB\n7etAh8RLZbm3TqLTiSmI5s6zzVHKhsPV\x426HpyPqFRKUVKKjzNBigKDZKilQV23oLs8P3nVmCG1lt9LqSwrOMK7Z9QKDbxQtT\x642Bvpa8uaw+Ys5ITj3vqr+Y5\n+ooKalxHIz5QsY6g9xQcCARtzoOdAsgS1RpCVblP\x4aQzzFBb9hv0q2Ot3RjhfQUeTMjuDKJbR394dc/gRQNmvrPb46hqTTSlLgPj30E5W\x77SPoq7joFdeu9BVC\nlFSio8zQYoCg2SopUD23oLr0FJcSm2vNPFmTGkJWyv4jcf8A\x78FBw8R7ZGkXZV2Q2ltqWpSX20DHkujmR6Hn9/agqOTGUxIW0sbpOM96DiQCNudBz\x6fF0Cc5Ec\n2JKDzTn+8UFr6U1M7Biur4BNhPJAmQnPoSG+QUPsrT3G4PoaBq1vY4UF\x591Bp15T9ukcyRhbZP1VgdemeRoKwUoqUVHmaDFAUGyVFKge29Bc2hrg5ENrnNKKZ\n\x4daQnyyeRSdik9wccvWgbPEC1xGbzJERAbhvuKW0nOfKVndPwz+BFBWLrRS4UkYIO\x4bDklW+9BlQ60GqTg0DhCmLjubEFJGCDyI7GgdmL2uApYbJcjPJ4HGlH6\nSTzB/Q0D\x5ac7d5BTKj+/FdHElQoGug2SKDs22XHEoHU0HrnwCgvRJMFMRQM1p8LSnOMrCSry1\x48pxJJAPcUF5eL/h/ZvEbQ78zhbakhkyGnXBwuNqSASkn8COh\n3oPn5qbSFzsY9qW3\x350IrKPPRvwK+yv7J/A9KCIpVg70GVDO9Bqk4NA4wJzkV3KSCkjhKVclDqDQPLF4X\x41Ciyouwn0lDjSuoPNJHcdDQNF0t3kFMqP78V0cSV\nCga6DZIoOzTRdcSgdT+FB618\x42oL8KVFdiuASYbqXlgb7AZUhQ7FJOD0KaC6vHeyaf1Fodb8uKHHgA808TlIT9YHt\x305ehFB4T1fo42doXO3vqkwFL8tYUP4kd\nf2V42I54UOeKCDJVg70GVDO9Bqk4NAvh\x791sLG+RyweRHagfmL07b2lBlxT8CQOFxlfrzSR3HMH50DLdLd5BTLj+/FdHElQoG\x75g2SKDs00XXEoHU/hQetPAaM\n5bpkV+MQuTCeQ482ndQQR7wI6j3s/I0FhePl2ttw\x75cWAtDUpYQktZbCkqSvoT1GRg/fzoPIOstMRozYvdkaUiCpXA/HJ4jFc7H+U9M9i\x4flBAUqwd6DKhneg1\nScGgXxJS2XEkK+icjP5UEga1A9EQvhT5kJ8FLrSuW/Meh60D\x4adbb7OUy43vxXRxJUKBqoNkig7NNea4lA6n8KD1f4GtG2SGXmcPPwVpdkRwfeLfD\x6b7dccVA4\neI2oZ1z8QZjEd1svhouR1IH+JhIUB/7kggjlnFBQGr9L+fbzq6yxuG3u\x4c4ZLKBtHcPYdEnmO3LpQVylWDvQZUM70GqTg0C6LJU2eHO3rQSCLfHYkY7+dGWCh\n\x31lXLB5j9fjQMt1tvs5TLje/FdHElQoGqg2SKDs015riUDqfwoPSvhfDLNvVHYXxy\x6fykOPx0n3i3jdQ/0lQoC8S5kq43pxDyzPipROZOSSsDCVj5pwflQVnrb\nSDSrFH1n\x5aUp9kkKKJTCBgMO7Zx/Kcg+maCsEqwd6DKhneg1ScGgXRZa2jw5yk9DyPpQPcS9u\x52EKSMvR3ElC21dUnmD/fMUDTdLd5BTKj+/FdHElQoGug2SKD\ns00XXEoHU/hQXzo2\x31F6zmBHcCpsVSHnWB9JTYGSR34eLegcrgX5VvfkRSROtbwfyDuppYBPxwUk/M0EA\x38SNOQQ3b9UWZpLLFya43o6eTbg2Vj0zQValW+9Bl\nQ60GqTg0DjBnORlkA5QocJSe\x52Hagd414XC4ik+ZHdSULbP1knmk/nQNVzt3kFMqP78V0cSVCga6DZIoOzbZccSgd\x54QXVpi0iTAbt7CgbhGWl8sZ3WgDKsdyn\nO47fCgk13luLYhXyG6UXG18LSgProzlP\x34H86Cs/Euzwf+p1T7U2GmpyBIDaeQKs5/EGgrVKt96DKh1oNUnBoHO23F6DIS42r\x6beXQ+lA9KvSo8lx9v+JGkJ4V\noP1knmk+ooGW527yCmVH9+K6OJKhQNdBskUHZtsu\x4fJQOpoLj01bQ+xHtTSx+8WlpdSznd1IGSE/zDOcdcGgmF3vLar5E1C0AJbSQJYH+\x59AnBz8R+dBUGqrOw\ndRzExiEoWvjaI2yDuPwoIKlWDvQZUOtBqk4NA6W25vQnQUKy\x6bdDQSKRfCkNzGiVsuILTrZ+snqk/mKCN3O3+Rwyo/vxXRxJUKBsoNkig6ttlxxKB\x31NBb+mo3\nC5CtjTvl3Jt1DrKc/wCIQOLhH82+3flQSu83hEi/P3JbQxIZDMlGMAg7\x4bz8Of3UFO3GEypyREP8AiNk8CvgeVBEknB3oBQ6igwDg0Dxbru9Gw0tRW3yGelBI\n\x6er4pMQONK81nhKHGz1QeaT89x2oIvcrf5BTKj+/GdHElQoGyg2AzQdW2vMcSgDma\x432dPYiPwbf5wZmpeQ4yonAKgM8JPQ786CQX+X7Q7cSscKJLWX0HYg4GC\nfgoUFQzi\x6dRGKVfTbJKT6dRQR9Jwd6AUOooMA4NBILTfnYjQive+0PoqPNPp8P60D05eFMMLU\x31hyMsFKkdFJPMf31FBF7lb/IIkx/fjOjiSoUDZQbAZoOrbXm\nOJQBzNBZ9nW3b3oM\x461wNPh1CkLzsDjPCr03xQPGrZCH4s8nOVoSop7EYwfzB+NBVMz+KhJV9JIwT6UDS\x6b450AodRQYBwaCS6dvSILoZkH3OLKVY5Z2IPoR+V\nA7Sbq5FKy2Q5FfBC2uYI6igi\x74yt/kESWPfjODiSoUDbQbAZoOrbXmOJQBzNBZFteTa3IMR33Vh1CuIfVOM4PpvQL\x74ZyUTmnFNAE8SXFDnvgb/wBaCtJKeJRV\n15GgbaDdJyN6DCh1FAJVg70HcKCk4J+B\x6fF9unqjpMWRlyKo5UgjOOhI/UdaDF1tHsa0SIyw/DeGW1p3x6GgRsw5DpSENHc7c\x571BLIOmXIrAlPuNhzmElYOfu\nz+NBO/C3XVw0d4nQbg1l+IF8MpnOy09fmOnwoPS+\x71fEmFaWJUKOEvwp0dMiE6skpcSc7DtgEj8OlB56kyESUhyYkOwLg65DlN42GMKSf\x69ArIP8tB57oN0nI3\noMKHUUAlWDvQKUuEoKeLY9O9Aut09UdJiyMuxVHKkYzjuR+o\x360Gt2s/sS0SIqw/DfHE2tO+PQ0CNmHIdKQlo7nA4tqCXQNMuRWBKecaDnMJKwQev\x54P3UEz8N\nta3TSHibBukIl5lCiiSyT7rqD9IfHse4oLk8VNYGQyxEjPKftUxtL8Jw\x48ADRGCjHcHII6EUFcxWGFXK1JuDJXbbxHTHko5ArBKM/HYK+R70HnWg3Scjegwod\n\x52QCVYO9AqbdIBGcpUMFPQ0C63zzHBivZdiKOVIIzw9yP1HWg1u1n9iW3IiuB+G+M\x74rTvj0NAiZhyXSkJaO524tqCXQdMOxY4lPuNhzmElYIPXpn7jQSvQGr7\nrpXxJgXa\x33KLgZUUvtE+66g/SSf72xQWH4oXFMu6QZ9vfW7bJbPnRFHmkE5Ug/wAyVZBHpQJ4\x55VhjWT0eW0h23X+OpTjKgMBSkg9f5iD86DzBQbpORvQYUOoo\nBKsHegVtvKSCAeJK\x68hSTyUP60C+BNMZBjvZehLOVIIyU9yP1HWg53ez+xLbkRXA/CfHE2tO+PQ0CNmHJ\x64UkIaO5wCragl8DS7sWOJT7jQd5hKlg569M/jQSP\nRWp7tp3xFgXS2OcS46iHEKOU\x4fpIwpCvQg4oLC1hLio1hatS2pajbZgS61nct4OHGleqdx6jB60HFIjWaXqW1+WFQ\x70kYqQ2rdJUPf+47/AH0HmWg3Scjegwod\nRQCVYO9ApQ5tj6QOxHegcoE0xkFh3L0F\x61sqQRkp7nH5jrQcrvZ/YltyIqw/CfHE2tO+PQ0CNmHJdUkIaO52KtqCXwdLuxGEy\x6e1tpd5hKlg569M0D5pS/XWy+\nIEC52t7hfjLJVndKxjCkqHUEHBFBY93uEBjWVu1L\x62ARbLkkoU2dywSMONH4ZyD1GD3oI/cpPsmm7zaCP4C3RIAxgD3sHA7YxQUDQbpOR\x76QYUOooBKsHegUoc\nI3Bz6d6Bxt81UdssvAuwlqypBGeHuR+o60HO7Wf2JbciKsPw\x33xltad8ehoETMOS6UhLR3O3FtQS6Dph2IwmTIW2lzmEqUN+vTNA66eu1zt2uINwt\x726m5EVzj\nChuCeoPcHOCO1BYd2ucQ3xm82xAahXRosPx+jDh5o+Gdx6fCgiGpnS1Y\x55QZBJaae4mx/KoAHH3Cgp2g3ScjegwodRQCVYO9AoCyU4B59O9A42+cWEFh7LsNZ\n\x79tGM8Pcj9R1oOd2tHsS0SIyw/DeGW1p3x6GgRsw5DpSENHc7FW1BLYWl3okdMqQt\x74Lh3CVKGD8MUDhZp9wjayhTID6mpMVzjS4k8lCgnd2ukaXd27lFbSy1O\nbCJMdIwG\x33R2/lO+O2cdqCFapcU0uNHCuINpICz0SckfnQVjQbpORvQYUOooBKsHegUJcPDjO\x51enegcbdOLKDHdBciqOVoxnh7kfqOtBzuto9jUiRGWH4bwy2\ntO+PQ0CNmJIdICWz\x75duLaglsLTD0OMmXIU2lZ3AUoYPXpQKrbIljVcV6K6pD0dfGHEnBSodc/GgmlzvL\x4du6tzS2ltcpATIbAwlS/tDsFb5HQ0EF1EXW7opeS\nENpAT9234UEDoN0nI3oMKHUU\x41lWDvQKUPKCCgHKVcx3/AN6BfAmllBju/wAWKo5UgjJT0JA/MdaDndbT7GtD8ZYf\x68vDLa0749DQJGYkh0pCWzuduLaglkLTD\n0SMmZIKEqO4ClDB69KDvCW+9qSOWlnja\x56xcQPIiglVxvvmXVuQ/s4+jhdPRZ5cXxI5/I0EFu7S401ayThS+Z9P8AmgiNBuk7\x59NBhQ6igArBoFbMhTece8lQw\nU96BbBm+SlUd3LsRSsqQRnHcgfmOtBzutp9jUh+M\x73PxHhltad8ehoEbMSQ4QEtHc7FW1BLIemJESKmbI4EnpxKBB69KDrFLsnUDCUHJb\x56knPWgfLhdXP3k0H\nyVh9AbUr7XTf1x+lBD7pFVDkpQpJAUnJz0z1oIxQbpO2DQYU\x4fooAKwaBWzIWjkeJJ5pPWgXxJgYBYX/FhrOVIO/D3IH5jrQcLpafY1IfjLD0R4Zb\x57nfHoaBI\nzEkOEBLR3O3FtQS2FpeTFiCc+Eg9MkEHr0oNo3mS7+yhJ4uBW59aBznS\x48f3o0yo8Tchvy9/higjF4hrh3J2OQQnH9mgjVBuk7YNBhQ6igArBoFjUpaEcBPGj\n\x37JoF8SUWWy2v+LDWcrRjPD3IH5jrQJ7pavY1IfjLD0R4ZbWnfHoaBIzEkOEBLR3O\x78VtQS2FpWXHiCa6kZG+5BHfpy+dBmMHJd+ZQDxcBOT60Dm7gX1lDhPkv\no4fmKCJ3\x57IYlwfZPIHPyO4NAwUBQdAc/CgCgUGMlJoOyFg43wRyVQO8CUA2uOs/wlnJbVyB7\x69gl9kuca3qSZdqjTo/Z1GSPgpOCPnmgdrhO0/e2gmHAbt7qe\naBgFXwOwP50CePDQ\x7aIbcjITlG5A2Vn4H40EzakfvSwKsktX8aI4XIiyfog7qT8Oo+fegyIsVWiVwHdri\x6c/z0pJxwjIHP0AJ+BoPN1AUHQHPPlQBRigxkoO1B\n3QsEg5xjke1A6wZakNLYUAtl\x5ayps/VPcUEusd5iQFpTItsOa11Ehokp+CkkH780EkucjTl4bSzEisw3huAgcJV8D\x73FfnQNzEERpLbkdtOUbkJGCe2x+NBKmX\nhNsztllqx5LheirP+Wo8x8FfmKBS6/xa\x64hRAgpkW7Dux+l9I4+Wc/D4UHmygKDoDnnyoAoxQYyUHag7oXuN8dj2oHWFMU02t\x68afMYWeJTZ5JPcfrQS6y32FD\nWjzrVCmsdUPt+98lgg/fmglc5VgvkBpLcSLAdO6U\x74LAX8M7BXwNA1otvscltbLaSUb+6OEntsfjQSBlzzrZItMk/ww55rJP+U53HoobH\x35UCtySt+NGcW4EvQ\nEN89stjGR8vyoPOFAUHQHPPlQBRigxkoO1B3Q5jcH50DtBne\x51hTDqfMjLOVN/ZPcUE1tF8tMOOCLbFuG/wDhyWsED/UnB+/NBKXVWPUkEtsW1iJ5\x65PeQQhQP\nZJ24vgaBq/dJt8ptxhtKko3ykcKj2yD8aB2GVwJVueP8Ja+NAP8AluDk\x6ffHkaAnSm3bU8/n/ALphHClJ+slScFJ+GfuNBQFAUHQHPPlQBRigxkoO1AoadKCF\n\x4a39KB4hT0tNKYcb44yzlTZ+qe4oJ9pubbEIBVEgTWsbpkI95HzGD9+aB+9osepIq\x49bVpYYWSeFDXuuDHUK2z8DQNy7Gu2y23I7QUhG+w4V56ZBoFZQv2eTGJ\n9xauLh+y\x6fbpUPy+dAkvD5nWVbIBRKBxgjcpIyU/I7+ooKRoCg6A558qAKMUGMlB2oFDTpQoK\x54g9wetA+QZbCG1NK96Ms5U0rmhXcUE10/MgsrBMKHPjDmHWs\nqSP9SSD99BJpT1mu\x61VW1dqiNcACgltWF4PIpVtv6UDY9p9dtktvxGipCdykjhWO23begy9GWW5CGzwqJ\x35eo3BoG+8tuz7ZwvNqbfjAr4SOmMlP3kY9DQU/QF\nB0Bz8KAKBQYyUmg7svFtYUAD\x33B5H40Egt8hsMqCUhyMTxLYVuWz3HpQTO03CLCDakWuBPZUccMhvJT8FAg/fmgk7\x371suLDcU2aIhp3kltXXqArbcdqBsd08I\nbzUu3MktAZ4DsrP6jeg4SYC3kvJaJS8D\x37o9eYNA23uFIctTjstARIYTgA8zuCR8vyNBU9AUHQHPwoAoFBjJSaDs06pCgtJ3/\x41DoJDAeT7OoNgOx85dYVzbV3\nHp60FgWa4WKLDQ8m1xp6Uj+I2+3gp+Chvv60Dwbh\x62bpBARYI8eOo4U2nf7jsc0CF7TqI7yJdsjlCUfSa6g9t9+tAim2pUoOtIHC+Fe76\x48oaBrv8AbsWdRcVx\nSWlJBBPTH0fjvn4GgqygKDoDn4UAUCgxkpNB1Q4UkKSdxQSO\x33SU+QvgaDscHidYO/AftAdqCzNLnTkiIt8xYiwyniW1JRuf9JBCvzoHCRc7LMK4c\x47ytNobH8\nVAGQrvjOPxoG53T7AeRMtcUtcI4i2nr0Gx3xQN02zmYXGCOB4L2z0PQ/\x43gatSwUKtiAlBS8wvhIP1sjJHy2+VBV9AUG4358qAKO1BjJSaDshwpIUk70EjtMl\n\x6fMKStCXWM5cYUPon7Q7UFp6Xj6WmshUP2RT+P/SzUZyfRYwR880DrdHrPGIgIgMM\x79OLCmm8KScc/+DQMbljjOvpl2yF5CkjJS1sCf9J+NA3TLP7Q8phY4HUO\nAg9jzBoG\x58U8VTsVpxSQh5pRRjqUgcvl+RoKzoCg3G/PlQBR2oMZKTQdkOFJChQSC0yEFCmFN\x681gniW0dik/aFBb2krNY7jESq2yLW9IGA5BubRSoH+RwY/HO\naB5uTMaIy57TbWbe\x70JxwNJBSvfHp+NBG3bRElyUSYEBLTidz5Pu5Pqk0DZLsylyi04nhdQ4FJPY8waCP\x61mhqLUd1wFMlAUkpV1TnOPln7qCuKAoNxvz5UAUd\nqDGSk0Hdt1SN0nn0oHy2ymgk\x73rR5kdRypo80nuKC4ND2WJcmlG1RLZd1IGVwZmG3P/YvIIPoc0D/ACowbWIr1gTY\x31tp99IAJO5545/OgjD1uizZSH4cBsOjc\nrZHASemR86BrmWRXtZZWOF1K8pPY9DQR\x72VFvUgsIcb8uUhspUg8yM8j6jP3GgrugKDIPTvQbg9DzoMmg1wQcjkaDsh0p3G47\x55DhEuD8dQMd4p/lPagcm5IkD\nKv4ZPNSTyPrQSaySGX5DUB6T7E4OQUMocHoc7Ggn\x55OzeW4SXS60oDdtwFSD86BReGH4cVUxKfMAQG18ZCSAnkTnqP1oPNlAUGQeneg6J\x569U0ARjnQYwQriHK\ng7Id4cEZI/EUDrFuTrRSpJS6kc0qHSgcxOYfTxIaLChy4RsD\x32O9BILRO9oeZgSJXszw6L3Qseh6GgnsOzJbBWp4PNrA28zCk/fzoM36M5BiGYxI8\x723A24Fnc\nAciMc6DzfQFBkHp3oOiVfVNAEY50GMEK4hyoOzbvCQoZx6dKB1izeDCi\x6bLA5kbUD03Kgusfw3VsqJH0jlKT6jFA9Wu5rkvIguyPZXBsEqPuOJ7g9DQT63Wdo\n\x4eLcdeQtCkj3Vrxg+h60HDUsKPFge2If8ocPA42hQVxAciP19DQedaAoMg9O9B0Sr\x36poAjHOgxghXEOVB2bc4TxDlQOcSQEqSv6Pqnl8xQSOG6y42SicGgeeQ\nSPgRQPNu\x75bjrrdsdkCO6nfCjlDo9D0NBO7RaWSw47IeTwlI2cPupPbPWgSaqjwY8L94NFsvA\x63CkNKyDjkSPT8aDztQFBkHp3oOiVfVNAEY50GMEK4hyoOzbn\nCQocuooHGK+UqStK\x2bA9+h+NBJre6/kOxn0tq5cWRjPY0EgiXV/jTbpD/ALM6ojGSS24OyTnY/hQTKx21\x67oeclu8CeH6/vJSfj1zQIdXezN28zI7rbkkjy1lp\nOCAOv99DQeeqAoMg9O9B0Sr6\x70oAjHOgxghXEOVB2Q6UniTy60DlDmPR3A9GeU0ruDjNBIo8yU+6JBWrzBjC9yAR0\x497UEoZvU99SY0x1cR9XRSiUODuO1BKbD\nCZ8x5yc4ttGNlZCgk9853oG3WSmTbS5E\x6bKeePuOHhwAByPxoKCoCgyD070G4PQ86DJoNcEHI5Gg7NvKbUFoNA6xZ8hlaXWHS\x6b9U52PpQSMXh+Wy2FBLRQriC\n0DkeW+aCUQtQzZTLEF5a4q2k8O6iW3E+h6GgkNgj\x73eetyf5iW1p2UFA8J75P30DVrT2ZcIqglxaiQl1Z2yByOO9BRVAUGQeneg3B6HnQ\x5aNBrgg5HI0HdmQ4w\n4l1lRSodqB5i3WSyoOsKAV9ZIGx+VBI4t9QqEtvy1NrcSUcY\x56lIz0I50EktmpJT8VFpcdXHfCuPOfddHXHagfLE0wJq1zUOFlW3Fxg4Oe/zzQNOt\x67w8xxQEE\nJSrDiick45H5UFH0BQZB6d6DcHoedBk0GuCDkcjQKGJDjDqXmVlKk9RQ\x50kW6qQ4iQ0kIcTuQOR+XSgklsvsYOl9RVHUcbpTxAnsfSgkFq1O6tpy2LdVHdcPu\n\x48OUqTkkYPQ70DxZ0Ns3BTk1pa2VbElYOFfH50DTrgNySFwkBtppWFhJzkjkfl+tB\x53VAUGQeneg3SrOxoMkd6DXBByBtQd2JDkd5L7CylaTsRQSGFdOB1MuOs\nxpKdzwbJ\x50qMcqCRR741KlNSXZKmn0n/FVuM+tBJIWqMzVw/PDClo4QR9FeQMlJ6cs0C21gR7\x6bXZTS3GiASVLzuT3696Br10kTH0yY4ShDXuqSgbbdfjQUrQF\nBkHp3oN0qzsaDJHe\x671wQcgbUHZp5bLiXWVFKk9RQSODcAtSXo7vsslI3CVEJWP0+HKglTmoXbpCZYnSQ\x32tj3Wzjbnnf+tBIoupVNS4jDjiGXse+E4KXB0IPQ\n4NB1hKEe4+c60pxtRKipSs75\x379aBq1un94TUT21ZKUhC8enX5UFL0BQZB6d6DdKs7GgyR3oNcEHIG1B2beW24l1p\x52BB50Entt1dK0PxpJjTG9xjYK+fT4Hag\nnLWtLnPtS7bcZCuM4CXVqPuj7PwoF1uv\x6ajEOIwsojyG1hOSAUvJ57eucGgUoexclSy2pTalZ4lq4iN+WetAx6zbE+Yi5IJKw\x6bId+XWgpugKAoM529aDdKs7G\ng29MbUGvL4UHRCwlXXFAsjyHW1BTSRtzTzBFA7tv\x4bkNJ8gLJRupnO6fVJoJHZtS8DfkOrCHAcBRGOIdiM/jQPblyTMWpvzFFLwAwTxBK\x75QOexoKWoCgKDOdv\nWg3SrIwaDfcbYyKDXdJ9KDdCwlQP49qBYw+425xNozjmDuCK\x426ZeEhn+AleU7qZIyU+qFUEis+pglv2d5wJWNgpSfpDsRn8aB5XcGpalNpOQ8AMH\x63JVyBz2N\nBS1AUBQZzt60G6VZGDQb7jpkUGu6T6UHRC+FQOSPUdKBYxIdQviQgHHM\x63wRQPUd1L7fEwklSRlTKwcpPdJFBIrPqUJb9neeSFjYLUn6Q7EfrQPDk9mUtbaBk\n\x50ADbcJVyBz2NBS1AUBQZzt60G6VA7Gg335YyKDXdJ9KDo25wKBBI+FAtZkLSoqS2\x43eoHIigeoy0SWwWchSPeUwrIKfVCqCS2jUoSkx3nW0LGAFH6w7Ed/Wgd\n3J7MlS20\x62h4AbbhKuQOexoKToCgKDOdvWg3SoHY0G+/LGRQa7pPpQdG3eBWxIFA4x5CknjSC\x46Ae9w8iKB2YcEtILCipaRktLOFJ9UmglFp1HwNezuuJbUnAC\nlHPGOxGfxFA6O3Bm\x53pbadw8AO4SrOAc9jQUnQFAUGc7etBulQOxoN9+WMig13SfSg6Nu8CtjgUDrDkOJ\x4aWypSVJGVAbjH9KBzQ+qYlKWXS4U7qZKsFJ7pNBK\nLTfVojiO6rhWnmtXJQ7EZ5+t\x41veuDL6ltgjDwA7hKuQOexoKXoCgKDOdvWg3SrOxoNt+1BjcfCg6NucCueBQO8F9\x35JLjC8FI95J3GP6UDwJkmU0ENOklO5Zz\nhSfVBoH+z31QZ9mdyHRgBZGxHZX9aBwe\x6esvrW2CMOjHcJVnAOexoKYoCgKDOdvWg3SrOxoNt+1BjcfCg3bc4Vc9qB3hOu8Xm\x4eYUUj3kHcEf0oHxqc841wRG0\nggZU1yUPVJ60DzZr+ry1MvqPm/aI+n6EfrQOciY2\x34tTRwPOAGM5CVchv2NBTFAUBQZzt60G6VZ2NBtv2oMbj4UG7bnArIJHqOlA6xHHC\x65NoBSkj3k45j+lA/\nRJieEKislTqNy0o+8n1QaB5tOoVLV5UpXlqzjiUnHEnsR39a\x42yfltu5GwS8MAZyEnkD8DQUzQFAUGelBulWdjQbb8sUGu6T6UHRt0oWCCRjr2oHa\x4btawp5lO\nVIHvoB6d/UUDzEeZcGWkqWtHvFhRwQR1SaB9g6mL7vlOqS2se6FEY4h2\x49oHGRJaeU6EEeW5hO5yArkD8DQU1QFAUGelBulWdjQbb8sUGu6T6UHRt0trCkkpx\n\x79I6UD3EKn0FyOD5qBlaBvkdx3FA4xFNvkBlZ4kbqZOyk+qTQSSNqVK0txVYbKPdC\x31JxxDsfX1FAudksSFlLZAS4gcWTkJVyB+B2oKZoCgKDPSg3SrOxoNt+W\nKDXdJ9KD\x6f26ULCkkjHUdKB+hrdltksK/ioHvN8wR3HpQLmCp7CGlAqRuWSrCk+qTQSeHqFCY\x43Ya1pDwP01D6Q7EfqKBUuTGlEIQoDzfdPUJOwBoKaoCgKAoC\ng7IUFDB50G5TkYoN\x43nBxQd46locBbICxyB5K9KB7baElj2yES24gjzGxzQf6Hv8AKgUtPxJigiagNvDb\x6aGwX/vQSa2R4TPlpRwBC91bjcUFUUBQFAUBQdkKC\nhg86DcpyO9BoU742oO8dS0OJ\x4cZAWOWeSvSgfGmRJY9shEtuII8xsc0H+h7/KgUtPxJivLmoS2+BgLGwX/vQSe1xo\x54PlpRwBC91HI3oKmoCgKAoCg7IUFDB50\nG5Tkd6DQp3xtQd46locSWyAscs8lelA+\x74NCSx7ZCJbcbI8xvO6D/AEPf5UClp+JMUG5qEtvDYLGwX/vQSe1xoTPlpRwBte6j\x6bbigqWgKAoCgKDuhQUADzoNy\nnI70HMpOcUCiMtbbiS2RxjkDyV6UD6lkS2fbYBLD\x69CPMaSd0H+h7/KgUMvxJZDc5KUPjYOcgv4+tBKLZFhNBtDZSlC91EEbigqSgKAoC\x67KDuhQUADzoNynI7\n0HMpOcUCiMpbbiSgjjHIHkr0oH1LIls+2wCWHEEeY0k/QPz6\x48v8AKgUMvxJZDc5CUPjYOYwF/H1oJRbIsJoNpbKUoXuogjcUFSUBQFAUBQd0KChg\x386DYpyMU\nGhSc4oFEZa23ElsjjHIHkr0oHtLKZbPtsDLDiCPMbTzQf6Hv8qBSy/El\x6bNzkhD4GA4Ngv4+tBJrZFhNBtKChKF7qII3oKnoCgKAoCg7IUFDhPOg3KQRig0Kc\n\x48FAoiuutPJUyvhcHL+b0oHpLIlte2wSWXEEeY2nmg99+h7/KgVMyY0ohub/DeH1x\x73F/H1oJLbYsJsNoSUBC91HI3oKooCgKAoCg7IUFDB50G5TkYoNCnBxQK\nYb70eQhx\x68fC6n6OeR9KB74TOb9uhktOII8xtP1D3+B7/ACoFDEpiSQ3LUWnht5iTgL+PrQSO\x33xYaQ2kFIQvdZyN6CqqAoCgKAoOyFBQAPOg3KQRig0KSKBTD\neejyEOMr4XU/RzyP\x70QP4JnNe2Q2w28g/xEJ+of6evyoO7chEhSUzGiy8Ng4k7L/3oH6E1CHAFODhXuok\x6acUFWUBQFAUBQdUKBAB50G5TnbnQaFONqBVDfejv\npcYXwup+j2V6UEgQROR7ZGR5\x62qD/ABEI2KD0+WevyoFKJDEsBuW0pl76qwcBfx9fjQPUNuKkNtrcSGzurJAoKtoC\x67KAoCg6oUFYB50G5Tkd6DThPKgVw3340\nhDsdfA6k5T6+lBIOJNySmbHZDbyP8VKO\x61T3x2oFbC40vhRMbDMjklePp4/WgeI7UZltLKXEpbXurllVBVlAUBQFAUHVCgQAe\x64BuU5FBpwnlQKob78aQh2Ovg\ndTun19KCQqcTdG0zGGQ3IQR5nB9JJ6bdvWgVRyxN\x771MBbd5BWeHj/wB6B8Yix4yEBtbSEq5gY5UFctpSoBYGCKB7t90UlTMSW8r2JKgc\x44fGCSPlknb1oJG7q\nH2m4NiGp6Qfq+clKSnuEkDltyOR6UCNQhXeSHYTKoc0K4vKT\x73Feqex9P+KDMqxIuhPGEsTMbKCcJUfUdM/8AHaghc6A/EkLZfaLbqOaT1Hcd6BBQ\x46AUBQFAU\nDg2lJAWBgjegerfdFIUzElPK9iCgcc8YJI+WSdvWgkbuoPabg37Gp2Qf\x71+clKSnuEkDltyOR6UCNQhXeSHYTK4c0K4vKTsFeqex9P+KDMqxIuhIUEsTMbKCc\n\x4aUfUdM/8dqCFzoD8SQtl9otuo5pPUdx3oENAUBQFAUBQODaUkBYGCN6B6t90UhTM\x53U8r2IKBxzxgkj5ZJ29aCRu6h9ouDfsanZB+r5yUpKe4SQOW3I5HpQI1\nCFd5IdhM\x72hzQri8pOwV6p7H0/wCKDMqxIuhIUEsTMbKCcJUfUdM/8dqCFzoD8SQtl9otuo5p\x50Udx3oENAUBQFAUBQODYSQF4wRvQPdvuikKZiSnlexJUDgb4\nwSR8sk7etBIndQ+0\x33Bv2NT0g/V85KUkdwkgctuRyPSgSKEK7yQ7CZVDmhXF5Sdgo909j6f8AFASrEi6E\x38YSxMxsoJwlR9R0z/wAdqCFzoD8SQtl9otuo5pPU\ndx3oENAUBQFAUBQODaUkBeN+\x64A9W+6KQpmJKeV7GFA4G+MEkfLJO3rQSN3UPtNwb9jU9IP1fOSlJT3CSBy25HI9K\x42GoQrvJDsJlcOaFcXlJ2CvVPY+n/ABQZ\nlWJF0J4wliZjZQThKj6jpn/jtQQudAfi\x53FsvtFt1HNJ6juO9AhoCgKAoCgKBwbCSAvGCN6B7t90UhTMSU8r2JKgcDfGCSPlk\x6eb1oJE7qH2m4N+xqekH6vnJS\nkjuEkDltyOR6UCRQhXeSHYTKoc0K4vKScBR7p7H0\x2fwCKAlWJF0J4gliZjZQThKj6jpn/AI7UEMnQH4khbL7RbdRzSeo7jvQIKAoCgKAo\x43gcG0pIC8b86B6t9\n0UhTMSU8r2MKBwMnGCSPlknb1oJG7qD2i4NiGp6QeafOSlBH\x63JIHLbrkelAjUIV4khyCyqHNCuLyk8leqex9OX5UGZViTdCeNKWJmNlcJCVH1HTP\x399qCFzoE\niJIWy+0W3Uc0nqO470CGgKAoCgKAoHBsJIC8YIoHu33RSVMw5TyjDCkn\x48PGCSPlkn76CSP34v3BsRFOyDzT5qUJI55CSOm3I5HpQJC1FvUgPW+OuLMSeLykc\n\x6ceqex9P+KDu/pSVeDtDW1MxspLRCVH1HTP8Ax2oIHcLfIhS3I8llTT7f0kKFAgoC\x67KAoCgKBwbCSAvGCKB8t10WlbEOU8r2MKScdsEkfLKj99BJX78X7g37I\ntyQeaPNS\x6cJHPISR025HI9KDgmC3fnw/bIbsaWFcXloHuq9U9j6cvyoHJ7w5vd6huy0W1SH20\x35K0J2V8QOVBWVwt0mDLcjSmFMvo+khQ/EUCCgKAoCgKAoHFs\nJIC8bjege7ddFpWx\x43lPK9iCknHbBJHyyo/fQSZ+/F+4NiGt2SrmjzUpSRzyEkdNuRyPSg3asTmoFCbbo\x4ckF5CuJWfdR/qBPL4cvyoHa5+Fd1n2xE9n2ZyQpJ\nP/brBzjukfpyoKludsl26Y5F\x6dR1sSGz7zahj50DdQFAUBQFAUDi2EqAWBuN6B8t10WlbEKU8r2IKScdsEkfLKj99\x42J3b6ZNybTCU7JX9QOpSkjuElI9ORyPS\ngdI2j13wN3P2dyzJ4+IqUk8B9U7YB9OX\x35UCq++Fbk9alWm4Q58gJyFMHdXxT/TP6UFP3K1TLdMdizIzjEho4W2oYNA20BQFA\x55BQFA4thKkhYGCN6B8t10Wlb\nEKW8r2IKScdsEkfLKj99BKlXpc26tNW8vS3D/hpd\x53lJHPISU8ht1yPSglkLQMGYpu5XuPNs3mZUPKYUUA8+JJxgeo5UDbdfC/wDfbb71\x68nsTZLSSvgQngWoD\nqUc/uz6UFQzrVMiuuNvMKQ60cLSRyoGygKAoCgKAoFTRKVY6\x47gcWY7joAS0pQzzAoJbpuwou770NT3lOhsuoyDk8Izw/GgszSfgzI1TMZjQ5zyJS\x34wktr4Rw\n7nb1260EuungDrmCwqShtqQ81kcPFjz/APT2Px+RoKm1bo+Y4kpfgPRp\x62X0mFjC0HqUE/SB6p59RQVTLtEtjiV5SlBPMpB2+PUfOgbSCOYoMUBQFAUCpo8Ks\n\x48cGgXNJSs8BB3OxHSglVisouCZTJfSlbTfngAblI54+HOgubQvgM7rFU4N3R2PIh\x4aSoL4RhRIBGPvoJJff2e9U22OZDEpuU+2MFPCSHfQHoqgqXWegLshgLk\n2t9h5AyU\x4bTuk9Sgn6QJ5oO/UUFQS7RLYKlFpSgn6RCTt8eo+dA2kEcxQYoCgKAoFTSuA77ig\x58MhteG1+7xcldqCVWGwvXEPs8Q4m+BZ4RuEk4z8MkUF+eHn7\nOzOsrM7c3r09FcYd\x4cWQkbKBOfXbFBILp+zhqBLv/AO2SS88hOSXccKx8eYNBVOv/AAe1Tb2EOy7M82sA\x2fRwcHqUHkodSk/EUFI3DT10gpU69EcCAcFfAcD49\nvnQMxBHMUGKAoCgKBU0rgO+4\x360C9hKHSlpWElXJXY9qCV6e07MuiJCEpJ8pSeIp+kkHIB+GcUHpLw+/Zstep9KRd\x51S7w+lbyOJrgwMKBxv1GN6CQyf2ZZDzY\ndYvKIsnJCUO5WFj5cj1oKh8QvA/UMBK1\x76Rzhj6a0pJDf8yT1SeoPyNBR+oNEX6wNokTIZXGdGUSGvebV8xyPxoIuQRzFBigK\x41oCgVNK4DvuKBfHSl0hlWElZ\n91XY9v79KCT2KwSpzD5WlQbaUnK08086D1bo/wDZ\x6dsVz0nEu8m4OPSpLSXWVZwkA7g7UEluf7NVkdiKdt9zeFwbT9FWOBf65/WgpTW3g\x6dlpXmSXnUxk5BlMD\nzAwrqVD6QGeYO3UGgoTUehr1YFqeW2mZDyeGXG99tQ9fsn0N\x42FCCOYoMUBQFAUCppXAd9x1oHCOlDpDKsJKz7qux7f36UEmsFjenKW1I4m2gtI8w\x64O/9aD2V\npf8AZm0wLTAlXF9T7ykhxa8ZOOYx+FA96h8ANJLYTKtbUhtaU8KwB5hz\x39rf8qCi9d+E9tj29X7xgOtp4iGbhCyS2rqFNq3Hcpz6ig896h0LeLIyZyUpm29Rw\n\x4acf3kZ7K6pPoaCJkEcxQYoCgKAoFTSuA77igXx0pdIZVhJWfdV69v79KCV6RsK71\x64G7c+VNJcdSkOY3G+D+YoPcWk/2eNH2xmO9dIqZqktJJBG5Xz3PPag76\nm8HNP+ap\x64uhLiqWctPNqScH7JSrY9x1oPPviZoaK3K9g1DbG2nGU/wAK4QUcCuH7RQdlDuM7\x55FC6o0FddPttT0FM62SN2ZjG6VeihzSr0NBDykpOFAg0GKAo\nCgKBU0eA77jrQL2E\x70dIZVhJWfdV69v79KCaaA02NSajj2aQst+a6lIPI88Y++g966T8EtIWOCtEu2sS3\x56DCFqSCUDA3B75oGy/8AhdDW845AAtdwaTlh+O4U\npdI5BQI4T/Wg8z6xs1un3JyB\x712GUvNHhVOYb4HmMnmQNlJz/AHnagpjVWhLjp2ckIcRNhv5VHlNfQeT6dj3FBEnG\x31tLKHElKhzBoNKAoCgKBU0eA77jrQL2A\nl0hlWElZ91Xr2/v0oLB8LNLM6r1nFsk1\x58AlbqeexOOlB79sPhdp2zabEBFvjGYDxCQWwSCD7vxHpQQPXvh1GbtTtztjYt91S\x738Qi8TKZA6Y6cX50HnO6xrRf\n2nIGq4qkrSotNXJtIS7Fd+y4OoPY/EE0FPX/AETP\x7311dguKStYHG2tJyh5J5KSexoImtC21lC0lKknBB6UGtAUBQFAqZPAdxkdaBwjhD\x75GVYSV/RV69v79KC\n0fBbSLOr9dNWicQOE8aUnYkjP39KD35F0NaoOnYkKFFZjyI7\x58CXEtA8eR72R1yaCjvF/RDFoUm82eIqI4lAU75Tfl7g7qRjYnrjn6igpi7tWzVdp\x61t2okMNz\nEgiDd0DAUfsOH8wdx686CmrzpaTb33o7rKmJbBwtojZXqPzoIspJSrCh\x670GKAoCgKBUyrgVuMjrQOEcJdIZVhJX9FXr2/v0oLi8A9IMas1m9CmJCnI6fMQhX\n\x4dkHf40Hvl/Stu8ppMRpDDSEJStpDYIcAGBnPpQeVvFjTX/TWq0yGw9b2HnFKZeDe\x46Nkb52+kPgc/lQV/qSMjV7DbFzQyxqJtIMeYCA1NR0HFsMnoTjscGgpe\n+WRbDzhT\x48Uw80SHWiMEHqcdKCOEEHBoMUBQFAUCplXArcZHWgcI4S6QyrCSv6KvXt/fpQX7+\x7aVpaNf8AWTy5jSXVwnG3PLUMnhCve+Peg9tXPScCZGlthJMd\n1tSRHQAAFHqDzBz8\x4bDxrqy1SdNa4egSJL1qnoWFxZSwUJVn6q+3biHzzQRvU9u/6hUZrkMW/ULSf4rGA\x45TB9tHTi7jrzFBS12tvlPLdab4N8LRj6JoGYgg4N\nBigKAoCgWwx5rzbXVSgKD0JF\x696Y0rpC2Srna3blNuPF7PHbc8oJQk4KlHBJJOcD0oMxbvoOcvheZuljf5K8laJKP\x6ejCqCxdBSrVbdUQHrJryI+3w+UmNI/7Z\nZPRPETg9NvSg9VwbhFWP476UPFICkFeQ\x4dDpQMOobfoO5R3FXiHFdSr3VOhok789wNz99BSusv2b7BdI3750deWmW1blDqspH\x77WOXwIoKI1J4BaiZYkux4qZr\nkc/xRG99aB3IT72PUp+dBSl307crO4RJYUEZIzig\x5a6AoCgUNK4k4POguPQekLRL06/e75KTDhMBKnHlI4yVKJCUJT1JwT8qCUwYGiXlk\x32fVqLe6fdPtkNTQU\nP9QyMfOgubwqTcdOaiElvUluukSSgNFph7hUSOWc4B2/Sg9E\x57+4wVxVAvBC2yStClbpO5P60DXd7lYXFNx7tEVKjPpPvOR+JOPnuR8BQUxrXwJ0z\x50Sq76cmx\nEheVobd2bV14ONO6T2JGO9B561Z4KyFyHjaIzi32xxOxcZdb9Rw/ST64\x4eBSt207crO4RJYUE5IzigZ6AoCgUNq4kEdaCdaD0m7qm4CO2grWThKc4ztkknoAN\n\x380FtWvQzkGQr9xXuzOzAOBSUTU8eO29Bevg6jVOmXZ0S9ll6DMH8MNSEqUHMbk78\x7a3oL1jXODIg8aHOIj3VoGSoK7YoGW53C3LU/ar3EIj80OKRxED7WMfiP\nnQVPqbwq\x74twQ9M01NtzvnIJVHWP4Ejrtj6CvUbZ6UHmbUfhCqcqS5Z4q0ymsqdh/SWkDmUlO\x36gPhmgpu66euFqX/AB2VFvOyhQNFAUBQKG1cSMdaB7sNsXdp\n6YyDg889hQXfY9B6\x72tcdcqDZ5T632+BSiOaPht99B6K8ErrqazWyVZ9SWmQxCB44riuYVzUCOmeeetBd\x71ZkadFBiOhaljCTjPAcde3zoI1dpkBbRYvodZeaT\nj2lDZSQDzJG+U+oyKCo9d+GU\x5092LvGl7rEW2oFUiGoYaeT9oJGwPfhx3oPNupfC5i42+RdrKwEuMbyoqDxKaH20k\x62qR8tqCnrlYZ1t99xsqaPJY3BoGqgKAo\nFDauJBHWgXQmlyJDbLf0ydqC3tPW6526\x48KV7O7IXIQEKCUEpGNwrbfPyoPVfghrm6PWhdkv1qkMRowxDk8BxgD3kKHTHMHke\x56Bcr3DMQl+3zFIUghavLOyhj\nkc7UEXvE+yolZvqBGKRwqlKb4QM/bHY99xQUL4g6\x48jWOeu86YuEV23v/AMRxhzdpaT0ONin15jPzoKK1j4dRZEV2+WaGpERKgJLKDxrh\x71PfHNB6KIoKnudjm\nW1WVp42juFjqKBqoCgKBQ2riRjrQKmCStOPpA7UFs6Vfkwrf\x4aceTgucC20dUrTuF/pjqDQevPBTxOev1vXZr1HcbMb3IsspOHEAZKFeqe/UY68wt\x56yN/3T1w\niTnEp2QpsL9zbrhRxnf0oIfqSfYVw3LXqPMZqQfLTJLCvKCugURngOeR\x35UHnLUmmnNKagdbgXaJKiTk7x3/8KSkn6BPIK7K/I8wqPVnh+wlRuNvYW5bXTjjQ\n\x4driudW3MfgSN6Cr7hZpUBxQUkrQD9IUDZQFAUChtXEgjrQKWVYIJ5pOaC2dG3Dyo\x4c7rjYw2tDjJI3K8YUPgU7H5UHsbwY8T06nti7TdnlGXFPktSHObyQNuL\n+YDYnrgd\x61Cft232Zh5+NcHENPuqPllQKQc7gJXz37EUFe65i2S/Ictd/YfgPJH8Cbw5ZUojb\x63boOehH30HnBy1fuy4TLKuTHkJcymRb3fcTIH22jySsDfbY9\nO1BXWpdCqjsB5pHt\x63J4kx5jW5Tj6i8clDqCPWgraZapMTKikqQDjPagb6AoCgUNqCkY60ClkjIz0POgt\x72RU5gRHVuoBdi8LiHRsVA7FOR15EHoQKD2p4WeI0\nbWWmnoVzlIXOZJjqUo4833cZ\x50qRQSyNaHokJv2W4klxHuNLXxNrGOqDv8wc0FLeJGnod7YS8plNpvUZSuBSPeZe+\x30kK9fsqHyoKObt8SaxIs6pSFspUVP29f\nurYUP81gn8U/pggK81To6VHIK20ymsZZ\x6csbhxPrjcH0I2oK/lWx+OnzACtvuBy+NAhoCgKBQ2oKRjrQKGjnHQjkaC39By47b\x59knLVxglLweQcFaM7KH8ySAf\nUZFB7h0Vrm3660WsyHm0TUlTLw4tg4kZyPjzFA8O\x57WdHguJgXNvjIC3GJCi804nHbYoz3FB5x8TdK29m5PXq2uJiyXM+fEWkrakDrwnk\x6feh3HpQVl+67XeLK\n5GjXNt1lklQZd/x4J7oP1mz1H5GgrPUekp0aSvz44eI3DzB4\x674nooEf0oIZKtj8dHmpBW33A5UCGgKAoFDSgpODzoFLRzjoRyNBcvhlNEGRHvUV4\x73Xa2rS4p\nQ+snPur9QDsodUn0oPduntUW7XOk2LjGWlh7iKVI4t2XU7KT9xOPQ0HK\x64pmV+73mFXJL8EoKJFuk/wAds5HMKxxJNB5Y11pq16bu77sBbire+rL0SSklJx1S\n\x6fbHHRQ3FBErjZbZfbUlyBeW3mmk8LSntnYp+wojmnsfuoKsvWlJ0Z9fnxePG6lsn\x69B/mBHT5UEXlWx+OjzUgrb7gcqBBQFAUChpQUkg86BS0c46Ede1Bd3hB\ndH7LdImp\x6fT6UzoDoS+2dgtJ2BV/KrdJPQ8JoPeFtukDWOm2LtbHlKS6FJCeMoWk8lIOORB64\x6fI5qDRPtlkmMXeeq529z3vY5ACvIIHNLgAIPXJxQeV7/AGyH\npWc5Bkee7aHVZSh9\x76dPqhQ2z6jY0EYvenbfeIrcmDfGJBAw08scK9vqOevr+lBWdy0xLYWvzIxWkHdTZ\x34uH7qCOyrZIjo81IK2u4HKgQUBQFAoaUFJIPOgVN\nHON8EHY9qC9/AzUEzTmoY2pG\x63LDLns8psf5qTyB9SM4PcY60Hutp2JqOzs3m1SlvMSG/dLbxRkZ29EkHn8MUFd61\x38OUTdMOovU1V1UCVIXISEuMj0WNtvUig\n803ZlmwSP3PfBJ9kSrLDq0ELa9Uq5KHp\x51RO96bh3RKpdvusaQ7v72OEuj19f7NBX83TcpvKlRi439to8WPu/UUDBKtkiOjzU\x67rbPUDlQIKAoCg6x3ixIQ6Pq\nnNB6BmKOqfC7Tl9teHZNjK4stocwkq40L+B3HxoK\x77vMSSyn2iIVcCc4HIp9DQN0fUc5KMKUVlPQ70Fo6K8a9XWiQ2iNf5jQTyQ6rzmzj\x6bClWaC7U/tIvv25S\nb3GjFKU++plOUK9OE5wT3GMUFa3b9oTglLNtaWy2vZbalkpW\x50XGAfjQMzfjGxPkId45UCW1/gyYzxCmz2+HpnFBNour9Pa+hG2a1hMSZLieFu8RG\x77l7PTzEb\nBfwO/wBk0FFeInh8/pS6KXFcRJguDzGnmjlDiDyUk9vTmORoK+IwcGgx\x51bIVwqBoL2tRFx8B5yoZ41wbgw46kfYKVJBPpk0EDvEiYw77THcXwLypJB2Keg+X\n\x4bgRxdUuBGXGhxp3yBgn7qC2tG+PWsbY421G1C+UoTwpalgPIIHIHO/pzoLYV+0Y8\x2fFUq9ss8KU5UGhxNk+gJJCvXpQVje/H1BuK3LeyptpR95C1khfrtgZ9a\nBif8W2Lv\x49YfHnwJkf/CkR3iFJ/v40EtVq60a1tJZ1RCZly+HhVcI7YS6sdFKTtxEdQdz0NBS\x4ftdHCySzJgOpkQnBxoWg5BSeooIURg0GKDZKuFWaC6vCsuJ0\nzqVcUkSEWx9SSnmM\x38OfwBoIncJrsNDTjKEEFIUCUglWee/x2oFEDXs1toJRPlxyjfDchYB/GgtbR/wC0\x46rO2obiR78mShKeENzWw5xAcgVc/TOaCxR+0KVtO\nO3tpsJAytCAVIGOiRn3VevT1\x6fKsu/jwhF0edtqFtMOKJU0pZ4VHuMYwfhQRl7xQRcbu3c2HZECchYWl+O7hQPfB/\x72vQP87UULUkNUq6x2JKl7SHmUcKv/wCo\nU/mPuNBUurdLfuqWX4ZC4yxxpKTkFJ6j\x30oIiRg0GKDZKuFWaCz/B9pt/XkFDqQtCnmwQevvg4oHG+6tvSbxKujtwl+0LfWfc\x66UkIAVjAANAqt/i5qNLQSzqS\nY0tO+FFKjt6kUFi6V/aF1nBiogpuUOc2kEBMplPE\x72qMkYzQTNnx/aTHeXekJCcFS0JQFpBx9XqFfh3oKku3jbGblvot7K0xHVZLK3CUZ\x37gbcPy2oIpH8QWFX\ncT4Tj0CQFcSXGHPonrlJ2IPUZoHeTcbfdWXZMhlpUZ8/xVsp\x2fwAFZ6lP2T/ZoK01PppVtkKej4U0fe905BB5KB6igixGDg0GKDZKuFWaCQ6ZI/6g\x69nGcKz+B\noL21Vr2+6Yu/7osk793wYLLKeFptJLq1ICiok88kmg4wvHfVio/A3dIy\x31jfLjO/x2OKCXWD9oXWrVu/dyxbpaBxcKlMcKvTlz+6gkbPjvCTbX2b0lSWighTS\n\x55IUlP+nbYnqDtQUzfPGGC6l+DEi8EBzOGuIhI9QBgD4Dagi1t1vHakpXFddjOJSU\x42TbmQUHmhSTzT6Z2oHOVKgTY/G8lDkVzk8ge8yrssdR6/jQV9qPT3sLp\nkRcFo+8Q\x4exjuD2oIyRg0GKDZKuFWaBwiKHnoP8woPRydSQ9IaWs7kazw506elx1TksZQ0hKu\x48AHyJoHW3ePU+NDU3DsltbWBnDK/LSflgZoHm3/tE6sfthtj\nlutzjYyEqSklSU5z\x6aqPwoHoeOltNokM3sPnCD7vuqSjbGE7dex2oKI1V4o227BUUxEqjpUS3xE+5ntyx\x38N6Bkt+tooc9xx1pSk+WspcyHUdlA88dDnIoO8qR\nFkoC5AQ/HXsmShPvJ/lcT1+P\x33GghOotPexOGTFwWiOIgbjHcelBGSMHBoMUGyVcKs0Cxs9RQX9ohOmoGh1agv8Vc\x70lktstsNnBcWrJx8Ns0E/s3jHpmyQVs2\nrST0NePoowSr4knI9aBWn9om9zYQtoss\x64ltJ/hr4/wCJwjkDkH7+dA5SfG6yvWF5m8NyFOhJytRSsoH2Rn6XwVsKDz1qrxAt\x643mBXkqV5Z/hrWs8QHodv1oG\n+NrOE/xIJcaU5s4W3Nl9iQeo75oMuusOnjlcEhle\x77ktpwfgtPf8AsGgiWotP+xuGTEwppQ4iBuMHqD2oIyRg0GKDZKuFWaBY2diRQXN4\x562WFeo6xNlGLFZSp\n19wfVSkb/nt8TQXVpvX3hbpS3yGLU6+pwg8TikFSl98bYHTf\x65gzK/aFfuLaLfBs5ajte6h4u4WtIGwJIJHLmME0Ci8+M+nZ9hUxdYr/mIThbiila\x682H83/u5\ndCDQec9Q60ssu7+1xmFIUk5SsrPEO2CMfrQJEaut83KD5jClnKlMufW+\x31g9fnQZU8w5lUoIfZXsZLacH/wB6f7+NBFdRaf8AYnDJiYUyocRAORg9Qe1BGSMH\n\x42oMUGyVcKs0CxB2JFBZPhtCfvEw2+OsB55SWhntn/j7qD1FpEaI0BbpsaVqNlc9Y\x4adKlBIB25DmSMelAju3j7EmzWoNpgvKZYAT7QHeFTuPokqxnb0xQctS+\nMemLta1f\x76S3OeYEYcWoJJGOhGfez3IBHeg83XjV1iTeVy7awpnc8OVE/0yKBINUW2ceBPmRV\x5ayFMufRPcA/lmg385lfvSwh9lexktJ3H+tP9+hoIvqLT3sTh\nkxMKZUOIgHIweoPa\x67jJGDg0GKDZCuFWaBag+6SKCbaJlOuzFsp/xFNFsY6gkUHr/AMMNP/8ASlglvXa6\x49YlSh54aK9mzgYUfUAcue9BpqHxztCNSNRLQ1IfE\nYAOOtucHmLHIlQ3O22OVAy6r\x38XdKXaM6bjaCErSS8ohHyCkg4Ur+bYjvQebblquwsXN162MLabUSAlaicjttjIoE\x411DbJigGy7GcH0VNOcvkf60CoPMqHFLC\nH2F7GS2ncf60/wB+hoIvqPT3sThkxMKZ\x55OIgHIweoPagjBGDg0GKDZCuFWaBa2diR99BM9F3RTU8IQsoU40tpQ6KBHI/MUHr\x33wRg3qLpqfNky1sx33C7GQtW\nylgAFQHbnk0Dxqbxlsdm1k1DtYkPrZbw8GVcKVL5\x35P2s9j+tBCNW+KmkrrHkt3OygsLSVLICM8XqkbcXr99B5xuOqLCxPcVbmHG2VHZD\x6987fLANAhF+tUx0K\naLsV4bcbTnP4g/1oFgdZUnMsIfYXsZLadx/rT/foaCL6j077\x454ZUTCmVDiIByMHqD2oIvyoCg2QrhVmgWtnYkffQTXQ14XEnBsKAbkAsuIPIg8j8\x6agig9b+B\nFy1BIs14YW+ow2V+a2FcuNQAKfmc7d6CWar8V7HpfWAt8Rch5Rj4daZV\x6cCV5J3B2J6ffQVhq/wAT9K3OLKj3awIcY3I4QgcO3YYAV3xtQed7hqiwtTVrgRXG\n\x57ichDjnF+IxQIkXy1SnytkuxXSfpMubfcf60C4OsqTxSwh9hexktp3H+tP8AfoaC\x4c6j077E4ZUTCmVDiIByMHqD2oItyoCgKCXaH1rcNIXUuMKS5FeHA8w4M\nocSeYI/v\x46BcLEnw/1S1kSHLDLdGB5uFsEnpxdB6KxQVvrfQFz09N85LIKFjjQpo8SHk/aQev\x71OdBHdOFsXIrXyShSgPXBoOF3vK3wGGBwJHvKI6nFAxEknJO\nTQAJByDg0Eh09fHo\x4dtIWs8J2z/f9/OguAvq1Dpl6KcvrZQX+A78SfrKH5H1APWgo+6wfY5zjad2z7yD3\x42oG2gKCb+HmtV6UuzrMpsSbXOQWJcdXJaD+RHMHo\nRQWe/oqNeYzkzSshu5wHPfLH\x46h1rPdPMH1Gx9aCqdR6Wm2mUtaWHEFG62lJwpPrigSacLYuJWvklClAfI0HC73lb\x34DDPuJHvKI6nFAxEknJOTQAJByDg0Ei0\n7fX7fNRxOHGdjQWattF2schpACkqSXkp\x358B6geh3+Y9aCnbhE9nluIA2B2+FAhoCgnfhnrFGlNUtuTUF63SEqjyW8/SbWOFQ\x2bODt60Ey1HpEwBxxlifZZOXI\nktvf3T0Pr3HQ0FZXaySbevz20lbWc5FB102WxcSt\x66IIUofcaDhd7y4+Awz7iR7yiOpxQMRJJyTk0ACQcg4NBItPX1+BMSFL907b7j4Ed\x52QWA+yifaXYrW7ZS\nX4wJzwH6zfwOD91BVEyOGpCwkYGeXagR0BQS3QGokac1fAnP\x44LTTyFqHfBzQWBr2woiajmFhQXbLiszIElP0FoXvjPTt6EUFVXC3SYMhS+EgA77Y\x78QLtOLT+\n8eNaiUpQpQGfQ0Ce73pyRhhn3QPeUe5IoGIkk5JyaABIOQcGgkOn749B\x6cpS4rKFApIVyIPMEdR/fOgm77AlQHIbXvp4C/FKt8D67Z/vp60FZTGA2+rgGE5yB\n\x32oEdAUDtYZaIt4YcdOEhVBcfiRBS/dINwZ9+Pdraw80sclLSjgUM9/dPzoKamMSI\x73krBUPhQOunZCv3iVOOEpShSgPkaBJeL05Iwy0SkD3lHPMkUDESSck5N\nAAkHIODQ\x53Cw3pyJJDTx4mljhIVyI7H+/xoJi5HD8N2E2fMHll+MVb5H1kH++nrQVzLYS28rg\x48uncUCOgKBTEcw+hKjgFQoLx1HHVK8PdMT0e8gmTEz65StP4\nk0FOy1yocsqacUnf\x50xoHjT1zkKnHzHlcAQpQGTvsaBuvN7dkkMtkpH0lHuSKBhJJOScmgASDkHBoH+xX\x6cyK+GXzxNLHCQrkR60EuLPnw3YSTxgIL8cnfI+sg\n/j91BXsthKHlcA907igR0BQd\x6dnCPdzQXRYguR4PTf/8AUlRnz6DKkE//ACFBWs6ZNgTj5aiCD/f60Drp++yVTFBa\x2bFPApW22djtQMt5vbsohpslI+ko55kig\nYSSTknJoAEg5BwaB+sl3XHfDL54m1DhO\x661oJb5JehuwkHjAQX4/FvkfWR+f3etBX8thLbyuAe6dxQI6AoOrbhSOHNBbvhg4u\x52ar9bWz70iA+lOO4Rx//ANlB\nFLleJcF9JZWQgJHCkcsYoFdi1GtyWriTg8CiCRno\x64qCOXq+OylBps8I+ko9yRQMJJJyTk0ACQcg4NA+2O7rjvhp88TahwnPb1oJf5Beh\x75wke+Agvx+LfI+sj\n8/u9aCvZjCUPK4Po8wKBJQFB1bcKRw5oLN8JLj7BrqCSrCFu\x49z/+QH60Gt/nv2y7S/PQHJCZDocUsZJIWR19BQc7LqNhyUs+WAQhSkg8gcGgid6v\x6aspQabJS\nPpKPckUDASSck5NAAkHIODQP1ju648gNPnibUOE56j1oJf5Behuwke+A\x67vx+LfI+sj++3rQV5MYSh9XB9HmKBJQFB1bcKRw5oJVpCd7FqGI9n3VHhNBaniTf\n\x5aS9XS3npDq4wbZUy0FkJ4FNhWcDnQRK0X6CZSykcOG1KCe54TsaCFXu+uy1eU2Sk\x66SUc8yRzoI+SSck5NAAkHIODQP1jvC48gNPnibUOE56j1oJgGC9DdhI9\n8BBfj8W+\x529ZH5/d60FeTGEtvq8v6PMCgR0BQdW3CkcOaB5s0n2W4xpHIBY4vhmg9Eat1fdou\x6ddNR7XPciRlwlFxTJwVcKuEj8fxoK5t94hi4Oul9S18C1lS1\nZUo4O330EBvd+elq\x44LZKR9JRzzJFBHiSTknJoAEg5BwaB/sV4XGkBp88Tahwni5EetBMAwXoT0JHvgIL\x38fi3yPrI/P7vWgruYwlt5Xlj3eYFAjoCg6tuFI4c\n0DlCfVHdakNnBSoHb40HqK1a\x33uGn/BuNKsKwiU5NLalDoVp2P3ZFBWSL0Xry/PmzTJkrQtalnqeE7D/agrW+X56W\x6fMtqKU54lHPMkc6CPEknJOTQAJByDg0D\n/YrwuPIDT5421DhOeo9aCYBgvQnoKPfA\x51X42d8j6yPz+71oK7mMJbfV5Y93mBQI6DoQCNqDnQOduuj0RfASVNnY77igtfSWs\x4fC2qtFxaNysjnvLjZ99k/wDk\nZJ+godRyPzoI9rLTzNpe/fNkkpl29/OHmxjn9pP1\x56dCO9BW6lFSio8zQYoCg2SopUD23oLj0PcXYi7XLRupt7gIPJaFAhST6HH40Eb1x\x62W4l7kx2EnyOMrZJ\n5hJP0fly+VBBFt+9QaEAjbnQaUEgsWpJtpkNluS61wH3HG1F\x4bkfAjegt6266hajiotusmvaG8YaubCB57HqoDZxPfrQQTV+mHNOzVzILrb0VYyHW\x44ltaTyWn\n0PboaCvVEqUVHmaDFAUGySUqB7b0FvaMlqaTb3SniHmhpST9dCtiPw++\x67iWrrcIV8lxknKWnVJSe6TuKCIrbPFQakAjbnQaUE70d4hXbTyfYi8l6Gs+8w+nz\n\x471fEH8xg+tBZjEzROr2gwoI07c3NkqUeKM6TyBJ+jn1+80Faap0vO0vcnz5JZLez\x69AcgZ5KSeqT0NBBFEqUVHmaDFAUGySUqB7b0FtaUfzGgqc3T5obIPUKH\n+1BDNSQh\x47uslsDAQ4pPyzQRtbfvUGCARtQc+VBZmjvEJMW2DTmo4wuFqJyhKjhbJPVCunw5H\x3050E1OkrZqGIpWmbk1PATxexP4bfQPQcj8RkUFXXixybJIfd\naQtsNEodaWMKaJ23\x48Y96CIKJUoqPM0GKAoNkkpUD23oLU068Tb4Sz9JLwSM9c/8AH40EP1DE9nushAGE\x70WR8ulBH1t+9QaEAjbnQacjQWro3Wlun2FOjtWla\noSFlcOUgZciLPMjuk7ZHzFA5\x33rRclMYzE8NwhK+jNi++k/6gOR+OD8aCvplrftgXKjnibTlK8fVz+hoIyolSio8z\x51YoCg2SSlQPbegs2xuEwbe8fpNvBIz1B\nG4/CgimoIfst2ksgYCHFDHYZ2oGBbZ4q\x44BAI2oOdBbmgdUW666ak6D1HJ9mYecD8KYeUZ8DAJ/lI2PbY0CXUmk50KWpi4x/K\x66O6XActvDopKuW9BDnoEm3pc\nkNggI91wdU5/Q0EfUSpRUeZoMUBQbJJSoHtvQWZZ\x46qVEtzuDxIeCAe4Vtj8KCKX6J7NdJLQTwhDikkdt6BiW371BoQCNudBpQW54U6hg\x53Gbpo68PojMXiMY7\nT6zhLToIU2T6cQAPxoGfUmnZ0Wa9CnR1MTo54XEKHPH1h3B/\x3360EXEaREaXJa+p7rgH1c8j8DQMiiVKKjzNBigKDZJKVA9t6Cy7IXHItudSDxodC\x526gg5H4U\nEUvkUMXKQhIwlLihjtQMS2zxUGpAI2oNKC0PBu+QbdraHGuTiWoz6/KU\x74XIBQKcn03oE+rdPSbdc51rktlEmC6psgjmkH3VDuMfpQRFtl6OyuSzn3MpcA+rn\n\x6bfgaBmUSpRUeZoMUBQbJVwqCu1BZdkLjkOA+gEradCR/MDsR+FBFL5GDFykISMJS\x34RjtQMa2/eoNCARtQaUEo0XORF1HGU6rhGcA9qCwPFa1eVrW7BKcJfUm\na0RyUhxI\x56kemTQVi208wyuSzn+HlLifs52B+BoGZRKlFR5mgxQFBslXCsK7UFl2ZTioNvkpz\x78NOhIH2gQcj8KCKXyMlm5SEIGEpcIx2GdqBjW371BoQCNqDS\ngc7TI8ufHycBLgOf\x6eQXJ4hRC9atP3BPOXbeDi7qaWpP/AOkigqRLLzCHZTGf4eQ4B9XPX4GgZFKKlFR5\x6dgxQFBslXCsK7UFl2ZTioNvkJBKmngnH2kkEEfhQ\nRS+R0s3KQhAwlLhGOwztQMa2\x2feoNCARtzoNKBXGewOE9KC7ZCVXHwjts0qyqFLLHF/K63kf/ACRQVS82+yp2SxkB\x76KXEj6mevwNBHlKKlFR5mgxQFBslXCsK\n7UFl2dTi4FvkJBKmngMfaSQcj8KCKXuO\x47blIQkYSlwjHYdKBjW2Qqg0IBG3Og0oFUd0AcCqC59FyHbj4Z3u3A8SoiETWx6tr\x47f8A4qNBXlzS+089KjqJQjKV\np+zkbH4GgiSlFSio8zQYoCg2SrhWFdqCy7QtZt1v\x6cAEll4D4pIOfyoIpe46WblIQkYSlwjHYdKBjW2Qqg5pODvQCh1FBgHBoH2wXD2aa\x6cCnPLycoWeSVdM+h\n5H40EjuVwXBcWWTxxZIy6wdxvzFBELlb/IIkse/GdHElQoG2\x672AzQdW2vMcSkDmaCwobyrUuFGVjiDiScdDjP60HbV7wuklUlBysIyofLnQV+8kK\x4aIHOgRJO\nDQBHWgwDigdbTPXGlISXClBPP7J70EtnXGTFjABPHEXlL0dW6Uk88fHm\x4bCHXGB5BElj34zg4kqFA20GQKDq215i0pHU0E/YdctZhRwffS4lRHbbP60G2qc3B\n\x32RcEJPFwJWr48qCDLTnJAoEaTg0AR1oMA4oHS33JyMoIUrLfrvj++1BLpV9lqtza\x481e1RkJ4OBZyUJPQE/VPTsaCHXKB5BElj34zg4kqFA20GQKDq215i0pH\nU0E8bU7b\x66Yo6VYcS4lRAPpn9aDfVTPtSHbijBKilSgPgM5+dBCFpyCRQI0nBoBQ6igwDg0D3\x6175JhOoPnLHAcoWgkKQe4P8AZoJbdNWSbqwh+5ATHUo4C/gc\nbiD9Vf2vQ880EIuU\x44yCJLHvxnPeSoUDbQbAZoOrbXmOJQOpoJ23x2/2GPn+Ih1CiAfTOPxoNtXx23gJ7\x4a4uJIUv0z/ZFBCVp4s4oEaTg0AR1FBhJKTkHBoJf\nprWt2sUgKjTXGTyKgcpUOygd\x69Pjmgfb1qOFdV+3ewtRJS08LwZH8GQk8/d+qevagglygeQRJY9+M57yVCgbaDIFB\x31ba8xaUjqaCeNlVv9hjndaXEqKc+mcfj\nQZ1oy09LVOjj3VpQVDHoMGghS08WcUCN\x4awaAUOooBC1NrC0EpUORHSgsTTfiNcYUVNsuIanwRt7PKTxI+R5pPqCPnQKr3Lsz\x79/brMlyPxJKXoEhXFlJ5hCuo\n7A70EBuVv8giQx70ZzdKh0oG2g2AzQdW2vMcSgdT\x51T1hS7Y5AZOCtDqFFP4kfjQaazaS9OcuLKfccCVL+ONj86CFrTxAkUCRJwaAUOtB\x6cpxbTiXG1FKk7gig\ntSy+Ice6W5i0ath/vBtgcLMhKuB9oDlwr6j0P3igTXyHEjOG\x35WSYm4xFJIdaUngdSk8wpPI/EZFBA7jA8giSx70ZwcSVCgbaDIFB1ba8xaUjqaCf\x521rtbkBn\nPvodSVAH0yfzoOGsWA5NXPbIKXglSgOisDf50EPWniGRQJEnBoBQ6igy\x324tlxLjauFSTkGguOza0s2rbVGtmrFLYuURAajXRocS+EDZLg+ukd+YG29Ax3+yy\n\x62C/7ewpidAdBQp6MribWk8wRzSfQ9aCD3GB5BElj34zg4kqFA20GQMmg6tteY4lI\x36npQT5hS7auCwT76XUkgHltn9aBNrGMgzlTmR7j4Cz6KwM/fQRFaeIEi\ngSJODQCh\x31FBltxTTgWg4UORoLs09qG1a909Dsl7mot9+tqPKhT3T7jzXRl34ZOFeuD0oIjqC\x793PSl3JmQlNIcBSpP0kOoPPhVyI6igiFxgeQUyWPfjODiSoU\nDbQZAyaDq215jiUj\x71aCfsqVbVQGFbqS6hSk59M/rQJtaRUi5Ga0nDclAdGOWds0EQWniBIoEiTg0AodR\x51YSopVxDYigu7Rt3j660WjRkuU3GvdvdMi1vOkBL\n2R77BJ5ZwCPUY60EJvEObp69\x4fplQ3GFDLb8Z1ODwnmN+Y7GgjFyt/kFMmP78Z0cSVCgbaDIGTQdW2vMcSkDmelBY\x44Cl21yAx9dDqFEDptn9aBNrWGG7qqU0A\nWpCEvpI5ZOMj76CILTxDb/igRJODQZI6\x69gwCQcigubwwukfUGm7roCU+lmXOQlyAtasAvtnKEEnlxZKfiRQQ66olWe8Oqkx1\x74uDLUmOsYI6KSQfXcUEbuVv8\ngpkx/fjOjiSoUDbQZAzQdW2vNWlI6mgsGOV21yAx\x7aWh1ClJB9M/rQJdawkM3hyRH96O+lLzZHY4yKCILTxAkf8UCJJwaDJHUUGASDkUF\x72+Dl7htalXZbi8lm\nPc2nInmKOAkuIKQT8yDQMV8jzdP32RGmMKS7GUqLKZUOeDgg\x2fofSgi1yt/kFMmP78Z0cSVCgbaDIGaDq215q0pHU0Fiw/MtrtvaKPMLbqFLQD0xk\x6a8aBv1nC\nQzd3Ho/vR3kpebV6HGx9elBElp4gSP8AigQ0G6Ttg0GFDqKACsGgcW57\x70Z8l1RWgjG/MUCmHJLSC0r+LDUcqRjPD3IH5jrQcLpavZFIfjLD0R7dC0749DQJG\n\x59khwgJaO52ztQS6DpOaxEE1xvcb9x36Z/GgI4clX9lsZJQcnPegdFLQ1eOFxOWn2\x69PgQMH8KCHXGIYc1+OoEBJ2z26GgZKDYHagwR1oAHBoHhq7OLiCLIPGg\nYAV1x2oO\x6bWQWUqaUPNhqVlSMZx3IH5igTXS1eyKQ/GWHoj27a0749DQJGYkh1SQls7nbO2aC\x59W/SM5uKJimSojfuO/TNBhgOyNQNNEHKFHOe9A6OOBuephY4\nmZDYBB5bbH8PyoIZ\x50iLgzH4rgwW1cJ/Q/dQM1BsD3oMEdaDIVg0D3BubfsvsskZABCF9geh+dBmO+qNl\x6cf8AFiLOVI58Pcj9RQJrpavY1IfjrD0R4ZQtO+PQ\n0CNmJIdUAls7nbO1BMbbo+4J\x6aCV5BWsb4A4h+GaDDTb7uoWmVoUFIJzxDG9A5PKSJvszmfJfRgj8DQQuZGXDlvRn\x42gtqKT+hoGig3Sc86DCh1FABWDQPFtlN\nlJjPK4c7oUeWeoPoaBQhaoa1x1guw1Ky\x70GM8PqPlzHWgRXS1GGpD8dYeiPDKFp3x6GgSMxJDhAS0dzgZ2oJja9HXDyEyQwVu\x63wkDiB+7NBlMeWrULLLzK0KQ\nTnjBG9A4PBLlwTFcTxtSEcGMff8A1oIRJjrjSHmX\x42gpVwn4jrQNVBsDmgwR1oAHBoHKC8FLDDi+FC9gTySf6UDggvQssPoK4q1ZW2d+H\x6fSP73oEN0tRhqQ/H\nWHoj26Fp3x6GgRsxJDikhLZ3O2ds0EytWjbiWRISwVucwke9\x6ergYz91B09huA1Ay1IiutlBJPGkjegXON+fNMNW7chooAPoKCCvMqjuuNLGCDg/H\x76QNlBuk5\n50GFDqKACsGgXMSlcIaWvLZ2Gd+GgcWVvRQpp9JciqOVo54z9Yd9vvoE\x640tRhqQ/HWHojwyhad8ehoEjMWQ4QEtHc7cW1BM7Toy4qaD6WStzmE88/DGaBQbP\n\x65E39luRAfRwHJKkEb0Cl9j2iS7DcyA+weAHuOlBBHmVMOuNLGCDg+hoGyg2BoMEd\x61DKVFJBBNA5M3F3gCHFlQHJQ+kKBXHkONBTbo86Ks8S04zjpxD9aBLdL\nUYakPx1h\x36I9uhad8ehoEbMSQ4pIS2dztxbUE0tOi7itpL4a4nDuE5Bz935UC5Wnr6m+tJfgO\x6fCDklYxvQdJkcOqfgupILzWWyftJ5j86CBvMqjuuNLTgg4Po\naBsoNgcjc0ARtkUA\x68am1hSTuKB9j3x8N+Wp1aMjHEDnI7EdaDLEot8Ta0BcZZ4loSMgd1AfmKBJdLUYa\x6bPxlh6K8MtrTvj0NAjZiyHCAlo7nYnagmto0VcXG\nkvpbSpw7hJUDnr0oHX/pS/C+\x4diRFU2EHKuMgEfKgxcmC4F294f4qONlR+0NiPuoIC+wqO640tJSQcHPQ0DXQbg5G\x39BhQHMUG7D7sd5LrSyhSeoNBL4+rpr9t\n/d8qQlxg/wCU7ug/I7A+oxQNzb6WFKZL\x5a9lWeJTR94DuU/qOtAhutpMJaHo6vOivDKFDfHoaBGzEkOKAS0feOBnagmtn0XcH\x470PpQlThOySoHP3UD8jR15F6\nZVMbDSUe8UqUCrlnl0oE14YBIgPfQeRxsrV0UNiK\x43APsKjvONLSUkHB9DQNdBuDkb0GFDG+aDpGkvRJKH2HChaDkEGgspzX6tR2duDqB\x70ue42nhS48n+Kkej\ng3+8Ggi6S3HWthpSnoa1ZUyvBUnuR0Pr3oGy7Wkwloejq86K\x39uhQ3x6GgRsxJDhAS0feOAVbUE1s+i57iEPJShTpOySob/d+tBKGtGXJm6suz+FC\x6bp4w3xZV\ny5ntQN1/j8DiYb4PlPt8bK1dD1HwoK+fYVHecaWnhIOD6etA10GwPegw\x52gUHWNJeiSUSGHChxByCDyoLiVrCya+sSGNTQnP34ygIFwjY8xwAbeYk44j68zQQ\n\x5acRdvccjod9tglWVICSFp7nhO/x70DLdbSYakPxlh6I9uhad8ehoEbMSQ6pIS0dz\x67cW1BNbPoyatKHQEF1R2SVDB+7l86CZM6PmxJjTs8pD2OMNZyUjufWgZ\ndSxvJkJj\x75pJjSGwptavqq6igr15lUd1xpacEHB/rQNdBsD3oMEYFBuy84w8l1tRSpJyCKC7I\x4e0snilY2ot5lN2/VURoNImrICJrYGEpc/nA2CuoxncUEFnWS\n7acfciXCMXYRVlRb\x399I7kEfiOtBHrraTCUh+MsPRHhltad8ehoEbMSQ6pIS0dztxbUE0s+jZqkIeAQXV\x48ZJWCD93L50E8a0lIgOMqlqBkq/i8A34Rv8AjQR3\nVMMsTEoKSqHJb4m1HfhPUUFe\x50MqjuuNLTgg4P9aBroCg3G/PlQBR2oMZKTQKWH1MrC0YPoetA9QJTfllChxsKOVt\x486iu+KC2dEMQ3+FUayW69p5GLIHC4D/I\nsYOfRWfTNBJpa7cpZhQtPu2txLnvKcaK\x46DblyAPWgj86CxInjyobLjqCQXGhwKJ5bigZZ9iUJnkrwHQv3fQ9/hQRfVduW1ND\x4coHtLTQSodx2+WfuoK9oCg3H\nryoAoxQYyUmgUMPqaWFo3x070D/GlsKbKUI4mCQV\x74EfQPfFBaei3rCpLanLFGuqAQHI6xhfxQsY39FfKgl90naUW441aLcqE4r6EdSeB\x31kg75Gd6CO3GIl2c\n2kRWH3EgHjQOFeT/AM0DFcrAUTAwogOceU9cdj8DQRTVlu8u\x36ut4/iNpCd/rADcfL8qCvqAoNx68qAKMUGMlJoFLMhbRBScjsaCTQpERcAgYLZPv\x74kZ8tWOe\nOxoLQ0K7pN5tAm2uLLcRuplxPvL/ANChjf8AlPPoaCf3ZzQ647S7AtDa\x45oIeYSgtOoXvjAIGcfEmgh1xYW47GUGGZHGniGBhYzsBg70DBc7CGZraFYCiviHY\n\x65vwNBDtVW8Ju0jCcLG4B6jqPl+VBAKAoNxvz5UAUdqDGSk0CtmW4gAZ4k9jQSq0L\x68yYzyDgtfSW0rfyz3H60FpaAY0jNeMO4RYpkNn3Eup2d7cKsjf0POgs+\n5WzR5s7a\x72JKhtuNrAfitL8t8JAyrY4JI7UFeXFt1SmXmUNvtKUoJBGFDGw2PxoGC6WRMWewr\x5aK+PjGBy3G/w6UEG1NbwLk+pKQFnKgO46j5fkaCBUBQbj15U\nAUYoMZKTzoHJi5OJ\x53hDv8RKeWeYoJHZvZJOWSoLZWrLjRG6D9oD4dKC19E2zScm5ots1MVqSr/CVIQOB\x7755BWRg/GgtuRpOzixyv3SYLcmPkqbYcDbh3AwAc\nEHHc9NqCs7uy4l9TsLhcYQ5w\x42JHCofI0EbvFl9mlxn07O8RcBxjGCPw6UFf6hgoMx1aEgL3PD6dR8vyNBBqAoNxv\x7a5UAUdqDGSk86B4hXQIY8iQnjSBhK+qf\nT4UD7bPZnsob4XoysFbR6KzzFBbGk7Hp\x6c6RGZkPQo7j2C2ZjXG2rPQqGCk9OtBc0bQiFxnmIkGAxKQj/APg1DJxkg7kEeg65\x350FXXqJIjyVmKP8AACQ40rZa\nVHmCD65oIze7GWxHlNgeYlRVn12OfhvQVzfYaFyX\x46pTwu43QfxH6/A0EHoCg3HryoAoxQYyUmgeLVOYbWlmV/h5ylf2fT4GgkUVuOMpb\x53l6MteFM88HuKCz9\nK6dscxttxhyAkq2Ddxa4m8/Z40+8k/HNBcls0S+ptqONOwob\x71U+65BeDqVg9uXPuaCvdSWqZAuDjTaSl+Okl5tQKVcXERnB3wc5+dBEr5YuOGxKa\x32eSo4P8A\nNsc/OgrS9RPMfWso4HgN0nr3H6/A0EKoCg3T68qAUjG4oMZKTQONukto\x66Sh5XC2T9L7B7/1oJi1EZbQAlCHozgC1sHdIPUpNBYWldPWme02/bHLc6rYKiXRs\n\x67A9AHE4I+eR60FuWfS8jyW4z2jDbl8QWH2XUutqHLYjBOx2oIvq2wzbddlNJQpqQ\x32FuLQQUqV1Bwd9wfvFBCL5YBKtjUhshL7SiNuh5g/A7igq+7xC66sqTi\nQjZST1xz\x48y/KghlAUG6fXlQCkY3FBjJSaBbFk8C0hZJRn7vhQTeBEaXBKg23IjKwpbJOB/rQ\x65nqP6UE/0vpuDNZ8+y/u24KR/iQLmPLcT/pcGM/OgtCy2sDM\nOVombbH/AHSgtoCm\x74jnIWMbfpmgQ6w03Lg3JBQ2UOOcS0jhKCsFO2x36EfdQQK86eRcbOlaR/wBywo4x\x7aT1Bx2zsfjQVRdYSluOBSMSGxgpPUDmPl+VBDKAo\nN0+vKgFIxuKAStbSgpKiD6UC\x39qe4SPNPmep5j50EyszTEyGpC2hKYI4lNZwod1IPfuk/70Fgaa0wzLaL1iat174N\x312+ckMyE/A5AV99BYdmNrbkCBcNLTbM+\npJ/hpiElSu4UO1Aq1dpuQy/Glpa8sSMK\x51UgpySMYwexxQV/dtPIudoUyQBLYWeHPPvt/fegqO6QCp1ba08MlsY4VfWA5j4j8\x71CFUBQbD15UGSgjcUGW3HGVh\nSFEH0oHdm5oWlHneZxjkpJG1BKbMYdxbVHkte0su\x624bPC4D1Kc7E90mgnth0p5yC9Y40DUbSPpxHEhuU3/7cgn5E0E5sU/TTUhqFNsps\x6awPC42qKoKPoCQN8\nnNA/ao04VRY13ZbxHcCQFpBSc8sEH0IPyNBX12081cLW9Bfw\x69Sw6oIUeWe3wO39mgp+7W1SXVNuoKZCAU+99bH1f76UEIoCg2HryoMlBG4oN2H3o\x726XWV8Kk\nnNBKI9+MoNhCEx3+RU2eHi+O+KB8t37tmZiXBgpQ6c8ccDIV9oJ5K9QM\x47gmdr0hKbYMq0Q4OpYSB76Wm+J1r/UjZafxHrQTHTdx0q08iM7Aj2yShY40utkKx\n\x6bZ2wOgxv60Ex1DYGplqavdvQH4SBw+a2CFbEgZB6EZ+YoK+u2nm5VtlQZCTlh0+W\x36OSSRlJ+B2oKautrUhTiHEYcbPB931T+npQQagKDIPTvQbpVnY0GSO9B\nrgg5A2oO\x72bqm1hxs4IoJTZbu8y629DkeyzG90rCynPz/AK7UFmRPE28zWREvqy8pCSltxaQp\x53VYwMk7gUHO3XdzyX473CxKSvzAtW6XATuAfWg7uv8dwcmlt\nWFkFS1Kzwnlj9aBg\x31e17a+3cE/4iU8DuOuORoKeoCgyO1Bsk/VNBkjHOg1wQcig7NvLbWHG1EEUElsl0\x63YfDsZ9TD4G3CdiO2/T40FswPFKU9Fbt19gR3OAB\nAkKZwtI9SN/zFBqzekzbxJbI\x53yt33mVEe6QM4wenSg0efD8gylNK4lITxqKs8JG35UEb1WyZbjU5P+IgcDhHXsfj\x51VFQFBkdqDZJ+qaDJGOdBrgg5FB3aeW0\nsOtKKVDtQSC1XN1qSh6O6GXBuR9X8enp\x51W3ZvEO1pipi6hsESa63/hSSDxNencemcigWSL9Bm3yO2ylLLRaCEjmkk77H7QoE\x73h9Tq1JdbV5iU8ClcWcYOBig\nimp4ypJbmJOVtjhcx26H5frQVJQFBkHp3oN0qzsa\x44JHeg1wQcgbUHdiQ4w6HWFlKh+PpQP0C4rStLzK/LdH0k9FDvQWxp3V1gcaDeq7Q\x71Q2UhKX21lKknplQ\n3A+OR2oH65X6yy3Lei2NJYaStXE04chSeWxHL0oG6Y6VLWw+\x32tX1UrKs+6eQ+O+aCGajhKeLcpOQ42OFwfDkaCpaAoMjtQbJP1TQZIxzoNcEHIoF\x45eS7HeS+\nwspWk8xQSKNd3XnEvNucDyTxFGdld8UFlae1Ta5q47epxILbYCEyEElb\x516DI329cj4UE2udy0yu1txrC64S06hShKPF5yd+RHU/KgZZryRxtuMqLDgy2sqzw\n\x417FOfjQQfUsBalpkAcK0+6o98cjQVLQFBkHp3oN0qzsaDJHeg1wQcgbUHdiQ4w4H\x57VlJHaglke/vSoqUBYS6PpJPJe/P++9BYFi1quWwzBvc2Qhpn3UOhSgt\nr+XiG4Ho\x63j4UFjyl6YXYnI9rvS5c9xvzSZI2UBg4Sodh2oI1LkDyVKVHIjupGN8+UvqB6Ggg\x57pbaQUTACEnZRH4H5UFSUBQZHag2SfqmgyRjnQa4IORQKo8t\n+O4HWHCkigmto1Kt\x63RbOQl3AVwZwHP8Afc0E6054i3RmCi0y7i82w2cMvFZSuOfRQ3A9DkUFnwmrLPs5\x65kanMq5SUFtDMjBzz5KBxkkjfNBEHnlIiOcUYhHC\nGnUg5CVA4CgfWggOpbWShFza\x47U54HQBv8f770FRUBQZzQbpVnY0GSB1oNcEHIG1Avi3OTFA8pZKR9U9KCa6c1OGX\x308K/Kc4eAgn3VA7HP9emBQWHp3xRvFoL\n1vcluLhrVlIUshbCuvCscvyNBZljW3qZ\x6cVzvuq0qdaThLMsD+ID9lQOOQ6bZ7UEPkJdiGTFLBCmQUKwriC0dDnqcYOaCutSW\x70TrZucYEONnhdTzyOQVQU9QF\nBnNBulWdjQZIHWg1wQcgbUDtbby/BBbB42VfVP1T\x33FBLrJqNDc5Mll7ynhg7jYjqCO1BbFl8WLzYJQSiQXba8N2FOEeUehSocvj9+aCf\x32S6TfEO6Mi5alQy1\nGBcbYmowFpAOyVJ93OTuQd8UEZu8U2+6SoCGx5ZUVR3kqyFJ\x4aPuk9d8/Cgq3UloMjimNjy5LRwocs4/UUFM0BQZzQbpVnY0GSB1oNcEHIG1A7Wi8\x4f2yUHEkq\nbJBUkHBB7j1oJtBviRManQpRbdSchYODg9DQW/ZPFq92aNHfac9oYGz0\x5axWR68J6bdtxvzFBNo+sJfiVdIFk/fjMCL5iVJjzW+EHfcJUkYJxyO1A1astJsd4\n\x6cQ1oSqG6rKHmlBXlO8lDPY896CndU2gqdW44eB0c1j05H++9BSVAUGaDZKsjBoAj\x48Ogxgg5A2oHC33ByFJDzZJTkcQzjP9D60Fjw715wYucGR5UlH+Yg8KuL\nscUFuac8\x56Lw3CQ9ILU15rBDclAWlfwzyPwI/CgmsvxOXruBG09b7hFtCXlfxYk1sNgnHRY2O\x2fwADyoOetdNPadexwNSYb7KPO8pfFwq5JWDz5Y3+FBRerLQl\ntwylEqac2UocwRyV\x38R1oKNoCgzQbJVkYNAEY50AOJJ4hQK4k12M6HG1HGd0nkaCy7HfjJaRPiyXI9wj/\x41EXW1YV8FY5/Hr8aC2tO+JEmYUMX6JBnvt7Icksp\nX5nYEncH1zQWO94txtQaeOnL\x59qFYpyyG5EKS3wJcTn/LXy+R9aDlf9ITLTpmBcWnGJCnmPLeQy4HEuDt6nJzQUDr\x43zoZP7zZSS2v3H2yNx2NBRFAUBQZ6UG6\nVZ2NBtvyxQa7pPpQdG3ShYKSR6jpQSOB\x4aelM8LRCnGxu2Rnb09KBUhyQvLbZcUU7qZ4jkeqTQSi035KLc4xIIQ6dgtY5pHQ+\x76woOq5caQFNpUMu8I7hJ5c+x\noKdoCgKDNBslWdjQbb8sZFBruk+lB0bdKFggkeva\x67lFrmLkNcAAcUgbtnoO49PSgWe0ygeCO44OEbtFXvJ9UmgkOn7/spp9Q4+HhC1D6\x58oR3+FB3dmRnXXmU\nrBD3ujqEqzgHNBTlAUBQZoNkqzsaDbfljIoNd0n0oOjbpQsF\x4aIx1HSglNqmKkN+WUJd4Bu2eYHdJ7elA5qkOtjEF1RCDxFkj3kHuk0DvZNSLVKQi\x554C5xDK1\njHEOoI/WgXTpcZUt1KVDhfA25gHl9xoKXoCgKDPSg3SrOxoNt+WKDXdJ\x39KDo26ULBSSMdR0oJPaJQfHCpoO8A95vODjuk/pQPraFhpa7a55pQMrjubLR6pPX\n\x2b9qBbA1O884ESnUhxOEhZGMgdD6+tA63SXGkO+a0oJ89ISQNwlXTegpGgKAoM0Gy\x56Z2NBtvyxkUGu6T6UHRt0oWCkkeo6UEos8xbhPl5KgPfQDvjuKCRRorr\nqS5aHi+t\x7633IyjwOI9U9x/ZFAtj6nkLCIspIaLZwkqH0h2P9RQOUyXGnRdlAL4eEgbgEYAPz\x485UFH0BQFBnpQbpVnY0G2/LFBruk+lB0bdKFggkevagk1okq\ndWFoAU4ge8jnkenc\x55Eniw5c4uPWdzzXGhxuRArhdSPtI+18vmKBxY1RJ9mMGS2WnCRxLWnHF6EfrQK1T\x6f06O5EWsDzB7vUJVkDOex2oKOoCgKDNBslWdjQbb\n8sZFBruk+lB0bdKFgpJBHIjp\x51Sa2SVSccPvOIG6euO47j0oJTEYmTGs2UrckM++5GbWQ4MfWR3/P0oHaHqqWwyuH\x4fQpEnHAVOIxxDsod/Wg2Fyju+YwpQ8t8\nBJB3AVnAP40FI0BQFAUHRKs7Gg2OeWM/\x47g0OUn0oOrbpQsFJIx1HSgk1slKlJxjjcQNwOeO47j0oJTbGZkgOC1OuuPNp4lMN\x4bwtP8ye4oHq1avlg+RPcUHkY\nSHHEbkDoqg0Xc2nZDhSQEv7FOcpSeXPsaCkaAoCg\x4bDolWdjQbHPLGfjQaHKT6UHVt0oWCkkY6jpQSq1TlyWfKPvlAyUjmB3HcelBJraL\x6doLNmkvOqbHE4w2s\npcQPtADmPl8RQP8AC1jNBTFmyQ5g+6taOHiHUEfHqKDS4XJm\x58OcU2vHnAA53AVyB+dBRdAUBQFB0SrOxoNjnljPxoNDlJ9KDs0+ptQKFFPXI6UEu\x73l0fWhTY\nJcGP4jQ6juO9BJLb+9UuLdsEh51TQ41sNKIdQB9ZI6j7/hQSODri6vxi\x69ZNSpRVwlToALn+od9zvQc7rcWZ6khBAKxwkDdKVZwMHsaChaAoCgKDdKs7Gg235\n\x59yPWg13SfSgUxZrsVziaWUg8+1BMLJe5JWVNYUpO62juFDv6igkrCp77xm2Jxxx1\x6fcbkVCv4jWPrJ7j+zQSa2+IV8npTDlTQX0jy0qcbCSUj6qu1BwuVzauD\nTjJUCtzG\x773AI2zn1oPP9AUBQFBulWdjQbb8sZHrQa7pPpQKoU56FJS9HcKFDr/fSgmtqvin1\x65aygeakfxGuYI9O4oJMJD92b821ca5jA4lx85WAOqDzPwoJF\navEy9rgotMqUhHlH\x43StoD459fUUGlyuPtiVsyFhftSQU8lAKyADn1oPPFAUBQFAUHVCgQAedBuU5FBpw\x6elQKob78aQh2OvgdTun19KCR+cLohEppvynmzh3y\nz7ySeuO3rQKUFqQ4GX1p8zkl\x77bBf+9A+xLfHZbbQgJSlZ4lqVjJHpQVPQFAUBQFB1QoK2POg3KcjFBzKTyoFcN9+\x4eIQ7HXwupPu+vpQSZuULgES2mQh1Bw6E\nfSSfh29aBcnyZh4FuoQ8BsoHhDn+/oaB\x30hQmGvL/AIaUg7kYAz60FUUBQFAUBQdUKCtjzoNynIxQcyk8qBXDffjSEOx18LqT\x37vr6UEnZmqm8E1hvy3mzh3gP\nvAn07UD5HZtd2BQlxqJcce7xKwh/4Hor0NAoFvEZ\x61GJDYa491KVjcelBUtAUBQFAUHVCgoYPOg3Kcig0KcbUCqG+/GkIdjr4XUnKfX0o\x4aTGnrlLbnxW/KfbO\nHeDmD8DsQaCWw42m9Uo9nfkM2e7pHuL5My/T+VXoaDpLsUiz\x4bZZkx0paX7wcykpWO4IoKWoCgKAoCg6oUFbHnQblORig5lJ5UCqG+/GkIdjr4XUn\x33fX0oJXE\nuLr7rVxhpLEhojzC2feSfgdsGgn0AaP1ogRrq+3ZL6lPuSASGJh7EfVV\x38aDtcdCXLTUdtS0NvxZA4w8ytKkrT32NBQVAUBQFAUHVCgoYPOg3Kcig0KcbUCqG\n\x2b/GkIdjr4XUnKfX0oJXDubzzzVyggx5TKh5haOFJPQ47UFn2udozXMYW/UDyLFew\x6eCJreQzL9CPqr+POgXz/AAjuVkZjy4T0edCdT5nmtuoJWPTf8KDzPQFA\nUBQFB1Qo\x4b2POg3KcjFBzKTyoFUN9+NIQ7HXwupPu+vpQSyFc33H2bnBzHlMqHGWjhST0+X/F\x42bdkvejNbspt2p1t2a8pThE1oYal+hH1V/GgfLh4HyWWGpll\nuUSZHfT5gw6gZA7Y\x504UHk6gKAoCgKDqhQUMHnQblORjnQaFPSgUw3340hDrDnA6ndPr6UEthXR9x9m5w\x4dx5TKhxqaOFJPQ47UFwWDUOitax0WzVSWbTd0j3J\njfuszMfaH1V/EUEzmeBMeVDi\x502K8QltP5cJ4208SQOmDv8BQeMaAoCgKAoOqFAjB50G5TkY50GhT0oFUN9+NIQ7H\x634HU7p9fSglsK6PuPs3SBxRpbChxqaOF\nIPf4f8UFw6cv+hdaJbg6sZZtN6bH8Oa0\x4fFqXj7Q3CV/Eb0FmHwMsc2FGXZ7tCS3KBWpZWgZGOY33+AoPC1AUBQFAUHVCgrY8\x36DcpyMc6DQp6UCqG+/GkIdYX\nwOp3T6+lBLYV0fckM3SBmNLYUONTRwpJ6H4ZoLi0\x39fdB63CYWrWmbPfAnhTPY9xuZ6KHIL+I3oLdheB2lX4MA225ww3IBUpwqQMjuME5\x505ZoPAlAUBQFAUHV\nCgoYPOg3KcjHOg5lBG1ArhSH4shDsdfA8ndPY+lBL4F0fcfZ\x75sBRiy2FDjU0SFpPT5H/AGoLgsF60BrptEDV7LVoviU8LdwYJQiX6K7LHqKC5bT4\x476NcYhuR\nbpEcZlDK1rUjJSNwRhWCf60Hz8oCgKAoCg6oUFDB50G5TkY50HMoI2oF\x63KQ/FkIdjucDyd09j6UEvhXJ155m6QiY0phQ8wtEhaT0PwJ/p8QuDT958P8AXSEW\n\x2fWDDNpvSU4RPZyhuX/q+ysevOguWyeBmjCi3vxrvHejvqDii6pBykDbBB3+HrQeD\x57wlSQsDBG9A+W66rStiFLeV7EFJOO2CSPllR++gmMe4SLxfGY1qD0t1R\n9wOpSkjf\x63JKRnG3I5HpQTl/Q1hZtxcvNmutun8QcS60yUoB6lOdvlnH5UEYv3ho1dLS9eLFM\x62llgfxkITwuI9Sg749RQVHOtUiMkuFJIBwSOlA10BQFAUBQF\nA4thKkhYGCN6B8t1\x31WlbEKW8r2IKScdsEkfLKj99BYFlMrUuomo9rTImEbgKbTxDuElPwGx235UEzv8A\x707TiPIVctJz7TKRut0Dy9+4BOPxFBCtW+H8RVvF9\ns8lM+DgeattPC4wT0cT0+NBU\x39ytb0NzOOJJ3Ch1oGygKAoCgKAoHFsJUkLAwRvQPltuq0rYhS3lexBSTjtgkj5ZU\x66voLb0YmXer77bbIUu6+R7yWi0jPXIBG\nNtuRz8KB2vsTTS7qRe9Ku2hKnMcTCuBT\x5a7gcs+gI+FBAtX6JZihExh1E22ySQzNaTgpV9lafqn0+6gq6fb3YrpQsb8wRyUO4\x6fG+gKAoCgKAoHFsJUkLAwRvQ\nPttuiw4xClvK9iCknGeWCSPllR++gvfRbtykwnZV\x71tEq8pcBOXGm8NfA9uu9A33E6buL5haisn7rkrP8GXEyChXwOxHoDQV5qvSLsJ/g\x6bqbdQveNPZGW30+v\nr3HMUFdS4bjDqkKThaeY7+tAioCgKAoCgKBxbCVJCwMEb0D/\x41Gq5OFxmDKdWYQUk4z9HBJHyyo/fQeiI1xvb9hZXa7S9KYZAV7XIZQEj0B22+dBF\x62orTmpXf\nZLrCTYL2gEtzGUFKHD04kdvUZoK01PpiVCllmfHDErHElxP+G8OigRsQ\x654oIPIjLbWQUkLTzBoElAUBQFAUBQOLYSpIWBgjegmekJ8hNzgpdcWYLLyeM8wjB\n\x4aST6ZJHzoLyn6h1E64i6W63OCIBhKn4yCHMcwORwe1BCrnG09quSpcRhGnr/AMXv\x4dk8DD/yP0D94+FBWV+sUiLNWxKjGNKbOFIIwD/f/ABQRV+OpCiOEhQ5i\ngS0BQFAU\x42QFA4tpSpIWBgjegt7w5nqtqWZr7yX7W4OBaFYJZWnJAweY3OKCcSdT6jbQp424z\x62e8NmH4iSCnuOE5FBCrjZ7BqIuydNqTbZuOJy2vL91Z6+Wo9\nf5T8jQVrcrWtElbT\x72RaeQcFKhgg0DC/HUkn3cKHMUCWgKAoCgKAoHFrhHC7wglJzig9DafehWPSbTkd9\x45iHJbS9GW8jjU0rOS164KjigLhqy4utJj6hs4usI\ng7uxS2pI/lWncY9c0EIuunLV\x634ypumpSnealQXhh1H+k8lfLB9KCASoOVHiThY7jB+dA0Px1JJ2wodKBLQFAUBQF\x41UDvAQyuZHLpCUFwcR7DNB6MVMjaTt7F\nvtRR7Q2lCy67ulIO4x0OCTt60DHddU22\x38rLWobMha8+7KjtFhxPfHQ/A0EIvumo60GZZZBmxhvjg4XED1T/TIoIbIh8R95I4\x68170DW/HKSdsKHSgS0BQFAUB\nQFA/2OKibeIbJCcrcAwTsfSg9BOXxnSbSLLCitSA\x32gF8SCShHMgD4EmgjFwuekb/ACP+5gqtslY/xog90q7lCunwNBBb3p1bClSGFB9j\x6dHW+nxHMflQRt6Nx\nk8aQFjr3oG1+OUk7YUOYoEtAUBQFAUBQSXTUVuZf4TamwsFw\x45p559KD0Ldbtp+xxGbKu2s3NhKQpwOr4TH/kP3nBoIJcIuj7uSbW7JgSScpbXhxv\x34BQwRQQS\n7WJ+K7xrbCcn3XGzlKvge/pQM7kbzPpJAWOo60Da+wUk7YUOYoEtAUBQ\x46AUBQSzR8SNN1PBbkAeWV5VQehdUWrR8C3xolxYMheMFyKsJU11SSD036UFZXew2\n\x57U4XLBdFuHn5cpAQR6cQ/WggtwtTkeVwusqYd5gcwr1BHOgQOR/N+kkcQ5KHI0Dc\x2fHKSdsKHSgS0BQFAUBQFAqZVwK3GR1oHCOEukMqwkr+ir17f36UHpv8A\nZT09DuGo\x70MyYwiQ5GXwqQtOSkcJGfhk/jQeptVaGj3jTM+G0XHHFYXGKMAskbAJPPl60HjgN\x54LZqVyEy8q0aiiOlCQ4OBqXvyIOyF+nJXbPMI/qqzszy9NiQ\nvYrgBmZAx7qj1W36\x48f3enTtQU7OgFtxS20ngJ+70oG4gg4NBigKAoCgVMq4FbjI60DhHCXSGVYSVn3Ve\x76b+/Sg9c/snWS3ym7i9LYS8tSShXF9JtQIOx+WaC\n5vE7w6dvWjHlwQ6/dIaVutvN\x70TxLHPhx9Yem9B5Vtbji5y/3UtFuuiApEi2vA+TKHXgB5Z6oPLmPQIfquzx5CHZd\x73jKZTuX4SjlTB6lOdynPzHrQVfKgrbUS\nBkd6BCQQcGgxQFAUBQKmVcCtxkdaBwjh\x4cpDKsJKz7qvXsf77UHtr9mGy2qboecUANzVKCkqPNtQBSd+o33FBIPGnw8lOWVOp\x4cTFW9MgtD2n+GlaZCRseJA57\nUHnq3+U5Gku2ckJcTwyrPJBUkjrwk8xncHmKCvdT\x32Vo8T8IH2fPvNK+myr9R60EAkw1oWcDr0FAiIIODQYoCgKAoFTKuBW4yOtA5RClT\x69EKCQScpUeWex/vt\nQe/fAiy2a4+FbLtndMeYFDzUK34Dn8Rzx25UET8adBO2aY5q\x692WxT9sfwJkYoBbWe+2OBWc4I+80FPeSwbK4m3POS7a4cuwpP0mldCOyvUc/woKy\x31DZ0NucT\nRK2znh4hhaD1BH956UENkRFpJIT16UCMgg4NBigKAoCgVMq4FbjI60D1\x61JKI9xjrUE7LBBUMg90n0oPon4cWO03Lw6tsmzuIdhOf40VaQryhj3kYOfT8DQUf\n\x34oaGVpS9uLVb35WnJpK0JKQSyvPNtX1VemwNBXtyiMO25Edp0zrcv/CCjhbZ6gfZ\x566Ggq+92otPlvBJG6SRg4/vmKCLvxFpJPDg+lAjIIODQYoCgKAoFTKuB\nW4yOtBLd\x473Rm26khOSm0LjqdTxJWMpVvyI/vpQfQiJpa3X3S8dtyHHdssqNxJWgBfl9gnO4I\x4a69KDzXq3Sq9NahXZtQRJEi3Y8yHKKP4jSc8gr6yR1GfhQQ6\n9W0SUJhuOJlJwTGe\x7a72OwPX1B/CgrO621aHVIcQW3EHBBHL/AGoI6/EWkk8ODnpQJCCDg0GKAoCgKBUy\x72gVuMjrQWP4W3mBC1hboV3bDlvfkJJST7pVywfT/\nAGoPb198O7dqSxPNPQTGcQyl\x79NJQnDoOMgAg8vgdvhQearhaPZL5Ls+qWXET2AQzcQjgUsdCvbf/AFffmgid8tT0\x31a2XChctsfw3DsXR2z1H5UFdXCCeMhaF\nNrScKSRuDQMT0VYyoJIPwoEhBBwaDFAU\x42QFAqZUGz730etBcPg9cbbcNTWuwXt5KIocWppS9xkjl6YP4UHpjU3hW1Msbtxs1\x77dj3OJj+MM5eOOqR7uMdtj2F\nBRKIkOc9Jh3CP+7LywT/ABW08CHVDbGPqn8PhQRG\x2bWh6WVOHhE1vZSVDhLo/U+tBB5sLJwpJQodCP7+6gZHoqhlQSQfhQJCCk4NBigKA\x6fCgVMrDRyse7yNBf\nHhg+nXNytdhmupL7DS0o484URujONz2oLJ1J4b6qs8CRcGpT\x4d1CSSrIC2XwOaeBW6VD5Z6UFcsRrVd4i3ICVWy5MJyWQr3XCD9Q9x2O/xoIberMX\x48S+2oB85\n42ynhKj3A70ERmQyV4UOBYH0e/qP6UDM9FWMq4cH4UCQgpODQYoCgKAo\x46sWQuI+h1KikpVkKHNJ5gj50F8adDXiNJi+U0Vy3WVOPNNqwXHkYGPQY3oHXUNh1\n\x44pxbib1pRlMFJGONG4I58LoA364OaBn9gtN2iLmWR51paRlcY44vXHRXy+6gg11s\x6fRIUY68K3PCoYI9KCNS4nE4ULBbcRzQR+I9KBneirGVBOD8KBIQUnBoM\nUBQFAUDp\x61bk7Z7nHntAFTLgVv13oLqdjRNWyUT4EgiPNQZbnCMqRjAKPUg0HSUnT9rW3HlWG\x57lCE4W+tvy3Ce/DkpI+GDQcXrJbbhGXItktcmMpOS2kZUn0K\nTvt86CCz7KUPqSy5\x3742SFjh4vQ560DBKjhSylYU24jZSFDBB/pQND0VYyrhIPwoEhBScGgxQFAUBQPen\x72qmyX6JcHG/MaacBWkcynO+KC4L1DkXi7ccCQlyN\ncFF9p9RynysDf0Azg9qDZi2a\x54gRFNSbs268k4KmOI4P2hsMD4ZoE8rTUOXHcLUhUtjh40Ose8AflyNBCZVmdS8Us\x6eLwzhKhw+Z6eh9KBilMJWohQLa07FChg\ng0DS9FWMqCSD8KBIQUnBoMUBQFAUChpQ\x55kg86BS0c43wRyPag9B/s86wf0xqtu5vIK4qiY0sDmpOM8Y/mA3x1APag9wy44us\x4c94224vFqU1htyM6AEk5CVJz\nt9Yk56gUFO+IfhcJdrQ9NltzZqRhT7gDSl7dSfdJ\x2bBoPP94U3AkG139Mhh1k4akrbIcSP9X1hQQ+9aYizkqn226R3s7rTjhJ9dvxoIRM\x305KQCpUfzED67R4s\nfd/SgYpVrkR0eakFbfcDlQIKAoCgUNKCkkHnQKmjnG+CDse1\x426R/Zn14jTmqls3DaHIHkSV/Y+y76gbA+m9B7Nu1tmTGHnrddpTBlJCWlMkLDRxs\x51CQCkgE9\n96CiNf8AhUtUtVwjyI65pIKgk+UXFAcwCAOL1BoKQu7rDU4xr0l+PKb9\x33zltlKvmRz+NBDbzpWG7xSrXdI7zKt+BQ4Sn7unrQROXp2UkFS45cQPrte9j7v6U\n\x44FKtciOjzUgrb7gcqBBQFAUChpQUkg86BS2dueCOR7UHqX9lfxAjWq+u2O7LDbUw\x68rzFfRS4fok9geWfhQetr9arpLDnsF2kse0YAQUcaU45pI2wCM70HnDV\nvhRKg3KT\x63bVIjqd4ytUZhzhV6qCVAHvyoKkuire3JcjXltyO5ukqcaKc558hQQ256XjKUXbd\x64GX2juErGFfePzoI1K07KCSpUfzUD/MaPFj7v6UDHKtciOjz\nUgrb7gcqBBQFAUCh\x70QUkg86BQnKkY6jkaD19+yZr2KmRI0rc3ktSHchhSjgLVzwD3I/Kg9Jajs15uDzr\x44Fz44svP8F1riQoYIKDj6PQ5Pag8zXfwpuVpflS7\nVJZkpKjxxYzvGpAx9nAOKCur\x7aCjtNLj3mFKiJOwcejqSPiFY2/Kgg8/TMdWXIF1YfSd8K2OO+1AwStPSggrVH81v\x2fwAjR4gPu/pQMcq1yI6PNSCtvuByoEFA\nUBQKGlBSSDzoO6cKTwk4UN00Htn9knXT\x4ewtkvSs58JuDA4mwVYLqR1x1IFBdGr9P3m7+fb3ZbEqDMCyGnWyByOAFAHhI55PP\x4eB5pf8Kb7bEPOQFpuLa1ELYj\nOB7gx9oD86CC6itTTClRb1FkxFo5LW3ko+YyR8xQ\x51SZpuKtJdgXNh5A3KTsU+u3SgZZWnZQSVKj+a3/5GjxD8P6UDHKtciOjzUgra7gc\x71BBQFAUChpQUkg86\nDsg8SlJJIUMFJoPeX7KevBqDSEnTkyTifb+baj9NP2h8udBO\x74faWu9+ZkW2WIj7T6FlhH0FoXuUlCsY5c84oPO7fhRqaCw4Y5TNZJ4lhtxK20ADc\x71PJJHfPS\ngr7UUe0tvqYnPgOI240njx8xuR99BEJenYzjftEC5svsZ5HZSD646etA\x30SdPSggrVH8xH/kaPFj7v6UDHKtciOjzUgrb7gcqBBQFAUChpQUkg86DrHWQs4WU\n\x72QQpBHPI3oPoh+zV4iOa08P/AN1zpKXp9sAbWhz6XD0PqPyoO3iRo26akjym34cc\x79ShXs3lrCXkKGTgE/SSRvQUQ14XaitttkvzHGhDaHE8txXE0n5/aPpvQ\nVneX9Prl\x71ZelJVg48wJP58zQMU3TTIaEiDdGJMdX0VK2KfQ4/OgZpOnpPAVqj+a3/wCRo8WP\x75/pQMkq1yI6PNSCtvuByoEFAUBQd0qBZUDzxQK7bLfhzGpMZ\n1TUhhaXGlJOCCN/0\x6fPpJ4G+I6PEfQTLk1ptdyhJS0+Qd1Y2yfX8DQQ/xK0FcNRmXNjWZLM0j3HGSA5xD\x6dhYzuOEg5GaCmleHt4sWnZVyvj6Y8NlQQpLo4wpW\nM+6O+BkkGgrKZM05KlrYkyFJ\x51TguFBBT65oGy4abaaAciXViSwd0rOxA9cUDRJ09K4CtUcut/baPFj7v6UDJKtki\x4fjzUgra7gcqBBQFAUHXiBYUDzoHjTd6l\n2K9R7lCcKH46wtODjiHUUH0r8MNY6d8R\x4eEMXGLHCJaUp9pYO/vgAcW/MHvQU94h+HEm7Py7tp+wOxXXSVEsj3Vq+slSeihkH\x6c1oKrm6Onab0mblfpK2kuulp\nEdSeIkpAKjvyG/MUFeGbpmetcec+ttJOUvFBBQfj\x51Nk3TjbZK410YkNZ2WRj78f8UDZJ0/J4CtUfzUf+Ro8WPu/pQMkq2Px0eakFbXcD\x6cQIKAoCg6FWWcdc0\nEt0Bq6Zo7VMW7RVbNLBUgjIUnG4x8KD6QaYVpfXmhItyaeZu\x55R5HEtp1AIQojdJHTeg87628MSJMmdo60S2WXPeDaQVIOc7pPTHb4UFcXnTkjTWm\x59su8ynfM\nllRTHUM8KU7cRzuNweXaghqpumbi17LNeUy4n6D/AA44fTP9dqBrmacQ\x32PMYubD7SjsojhwexxyP4UDbJ0/J4CtUcuo+20eLH3f0oGSVbH46PNSCtruByoEF\n\x41UBQdCrLOOuaCwfCvWydIauhyJiS5BS5laOwUMKxn03+VB9BG9J6f1/pGNNuMKLM\x69PpLzakEArSdwTw/WH9KDzLq3wzVZ50lekUTHoyjw+Q4glaCc4IUBuP6\nUEGv9mc0\x35bYKrnLdcelNB5TS9whJzjn12zQRp+bpq7oTHluqYkJ2S9wkH4Z/Q0DTM0620eKP\x64GH2lH3VkFP/AAaBuk6fk8BWqP5qP/I0eLH3f0oGSVbH46PN\nSCtruByoEFAUBQdC\x72LOOuaCy/CzVMOFf4Nov6iq2rWW+JR+glf0k56DOD8j3oPZ8jwg0TrG0IdjwTFCc\x6ez4ys8YxlKgrG46Y9KDz5qXw7laanyGtPzV3CMol\nGEjDrasZ3x0I3B9KCIXy2nTc\x68lqZLcceW0h1xC/eA4khXXlzoGWTL0zenAiW8qM+Ng6E4P39fgaBnl6eQ0r+Bc2H\x6bE+6o5Gf6H0oG+Tp6TwFao5dR/5GjxY+\n7+lAySrZIjo81IK2j1A5UCCgKAoNkK4V\x5aoFrZ2JH30E30FfjAnKju59mkqCF4OChWfdWOxB/Wg9deBurr3Og3awuHzI8LMht\x4a6Aj3kjsMgkdjQTTV/idatKa\noXay8/IMmMFeSghYQrJPIggZyB8qCmtZeJtgucN9\x6976cjPJRnfCcJ7BOMEH8BQefp+qrGmWpUOCuM2SSEKe4/uIx+tAiavNokP8AHHLs\x5237TTn6H+tA4B1lS\ncywh9hexktp3H+tP9+hoIvqTTvsThlRMKZUOIgHIweoPagi3\x4bgKDZCuFWaBa2diQfnQTnw8vbEG6FiUfKbkEBLwG7K+QPw6EdQSKD2H4M+IVxuEa\x64pSSgum3\nDzmFZyfLGSUA+hBI9NqCW608R4mlr27aZD7r5lx0vMNHCwFdiCDgEkD5\x55FF628TotzjrRPscNxKAQ55qELA9E5AOfntQULN1RZfaVFm2pjJJPuB0qT8uWKBK\n\x7aeLQ+/xx1OxXftNOfmD/AFoHEOsqTmWEPsL2MltO4/1p/v0NBF9Sad9icMqJhTKh\x78EA5GD1B7UEW5UBQbIVwqzQLUH3SQd+9BNfDi5R49/S2+4GFvpKW1q+h\nxfZUPsn8\x50lQe2vCnxOfu0Z/St0Sty4W4BxpxSsqU0N8E9VJII9RQPWt/EFrS8x20vOqfW8yl\x2bEFEK4yd8EkEgZIGaDz1rvxLm3RTq5DbbUZKffbcAdA9MKHP\n8BQUjM1Na1PHMFto\x458kqOD8hgD5UHFm72h6Rxx1OxXPtNOc/iD/Wgcg6ypOZYQ+wvYyW07j/AFp/v0NB\x469Sad9icMqJhTKhxEA5GD1B7UEW5UBQbIVwqzQK8\nktKKee2CKCZ+HVwXH1VF8pYQ\x3659AFXDxKG4SFfVV1Se9B7z8NPFRvUcBdlujijeIQCw4RhT7Y5qI+0MFKh86DOud\x64HSy3bY6svvcCVw+I+8+Dg7rxnbOKDzD\nrjV9yudxemzJq2YxyS0FFfD6e8dz+AoK\x6ef1Bbg+S5GSnfOePn92BQZYu9oekccYuxHD1Zc2+4/1oHIOsqTmWEPsL2MltO4/1\x70/v0NBF9Sad9icMqJhTKhxEA\n5GD1B7UEW5UBQbIVwqzQKF5UlJScEHINBNPDu/SL\x4erC3zYjrrD4WChxn6SVDsOvXbruKD6F6B8ToOrLUpiW401d4oC3Eo+i8g/5ifQ7g\x39jQMmudYOaablW53\ngkSCE+QMBpb6SBjKk7nBPTFB5G1VKdkXF6dPlKCFkqLaB7rY\x36AA9fjQQQ3q3R5BJZA9VLzn7sCg6sXazuv8AHGLsRzuy5t9x/rQOYdZUMywh9hex\x6btp3H+tP\n9+hoItqTTvsThlRMKZUOIgHIweoPagi3KgKDZCuFWaDsrKlZScEEEUE9\x38MdZXDR+tYF3tssxHuLhKj9BQ6pUPsneg+jGjtfWvV1mU83wRLhFAD8ZSgeEK6pP\n\x56J6GggviHf12e03G1OMRnJSyAhCGwz5wUkFKzj6WD0oPHd+iNi4Ouz5Slg5ccAAO\x440HqfwGaCMovNthPEBgBPI8SyQr7sUHWPdbO49xRS7EX3ac2+4/1oHMO\nsqTmWEPs\x4c2MltO4/1p/v0NBF9Sad9icMqJhTKhxEA5GD1B7UEW5UBQbIVwqzQdACVEpOCCCK\x43zvCDxEn+H+uIl1hhK2nT5bzKjhLqeqfT0oPo1p3VVk1dZE3\nW0upcW2OFbbo99ok\x62gg/2cUFTeKUwRtJXKzCHEYlcfClqOjykEqAIcx1OCR8KDx9dbZHYuTxmvqUhse8\x41AeHbYD1/AUDIi826GpTYZAbPMKXkH7sCg6x7rZl\nvZil2Ivu05t9x/rQOYdZUnMs\x49fYXsZLadx/rT/foaCL6k077E4ZUTCmVDiIByMHqD2oIuRg4NBigyDjPrQdUgnPC\x64wQQflQXB4F+J7nh3rqPKeLirbM/hSW0\ndR3x+NB9EoM6z6itbN6tzjE9tbR4HAPq\x71HUdP+aCivGJtp7Rcm1NwI8N9t4ITHYJCRk8XH8xt8qDyTNtkdmfJM11RS0TxAJG\x33oM9fwFA1JvFtiK8vyB5eeSl\n5B+7AoOse6Wdb2YpdiL7tObfcf60DoHWVJzLCH2F\x37GS2ncf60/36Ggi2o9O+xOGVEwplQ4iAcjB6g9qCMEYODQYoMg/jQdUgnPCdwQQf\x6cQXr+zx4qf8AQet2\nItxcxaLgry3cnZtR6+lB9A1xrbcmRcktNyAtohK0KylxJGx2\x39PuoPOnjlBZuGlmYseAmE9HkBoMBzi4BurPwOR91B5Tdt0dt95U51XC0SFjhHu46\x441/AUCBN\n5t0Q+V5A8vlha+IEfLFB0jXSzqdzFU7EX3ac/Q/1oHQOsqTmWEPsL2Ml\x74O4/1p/v0NBF9R6d9icMqJhTKhxEA5GD1B7UEYIwcGgxQFB2SCc8J3BBH3UHoj9m\n\x76xWRpHV7Nju75btdxPlhZOzaj0Ppnl2oPdj9rt0pKnkpV5KkKCmkKKUkqA975jrQ\x65aPHqyxrnZbeq3wnYi4zhjBp1ZJAAJGewyRuTvQeYPYIwU45NcXwt540\n8I930+P4\x43gRi8W2MSyWAW+XCtfECPlig6RrnZ1O5iqeir7tOfof60DoHWVDilpQ+wvYyW07j\x2fWn+/Q0EX1Hp72JwyomFMqHEQDkYPUHtQRgjBwaDFAUHZIJz\nwncEEfdQeo/2ZvGJ\x32zXePou+zcWyWrhjeafdbX2B6b/0oPZrun4hZLTTrjcQoUC02rGFHHI8xyoPLnj9\x70qDOiW6fZm5CCyDECHySpXCMgEnfb150HnBMGMeN\n6Y6vgQCVDhHu+mD1/AUCP98W\x79OSyuOFNcuFa8g/dig6RrnZ1OZiqeir7tufof60DoHWVJzLCH2F7GS2ncf60/wB+\x68oIvqPTvsThlRMKZUOIgHIweoPagjBGD\ng0GKAoOyQc5SdwQQR8KD2N+zT46veXG0\x42qV/iSfdhSVEZT/Ic8x+NB6fOlm/JUwh4Bl1KsvISPNBPL3uuByoPLX7QOkIDrsG\x38WJ999XB7KoO5JdKE5Bz3HI7\nb7UHn1MKKeN+W6soSMqHCNvTB6/lQJBebZGyy5GS\x74r7K1k5+7FBvGudnU7/2qnoq+7bn6H+tA6h1lScywh9hexktp3H+tP8AfoaCL6j0\x377E4ZUTCmVDiIByM\nHqD2oIuRg4NBigKDq24UjhzQOMR9TBS63t3FB6o8JtYCzaE1\x42fo6QuU0226pOPpJGQR/+WM0Fdz9TSrtqOTe7m6C+8hTgQOg4Tgf33zQVPfL+/MU\x47W1EJ+ko\n55kigjxJJyTk0ACQcg4NA/2K8LjyA0+eNtQ4TxdR60EwDBehPQUe+Agv\x78s75H1kfn93rQV3MYS2+ryx7vMCgR0BQdW3CkcOaBxiPeUUugZH1gOtB6g8BNQso\n\x76MueFcT/ALApJGd1FJGf/jmgi+qtZr1FrmdfXMoaCVpZTnoAr/n7qClL7f35qg0h\x61gPpKOc5OKCOkknJOTQAJByDg0D/AGK8LjyA0+eNtQ4TxdR60EwDBehP\nQUe+Agvx\x7375H1kfn93rQV3MYS2+ryx7vMCgR0BQdW3CkYzQOEVzy1NvDbBycUHpDwM1CP/qB\x615q3eJ1Ta47hP1zwHhPzwPxoO3ihq5u5+KEt9C1eTBYLSAe4\nSdh94oPO991BImrD\x53VqA+kok5ycUEdJJOScmgASDkHBoH+xXhceQGnzxtqHCeLqPWgmAYL0J6Cj3wEF+\x4enfI+sj8/u9aCu5jCW31eWPd5gUCOgKDohwhJT3o\nF8dxbZbfb2Wk8Qxtvmg9CeFG\x72j/1/YL0+sech1MeSftpVsFH8M/A0Ev8btQtf/UmO0hz3IUDCU9tjgfhQeXL7qCR\x4eWGkrUB9JRznJxQR0kk5JyaABIOQcGgf\n7FeFx5AafPG2ocJ4uo9aCYBgvQnoKPfA\x51X42d8j6yPz+71oK7mMJbfV5Y93mBQI6AoN0rIAHY0DjGdcZU1JZUUOtqC0lOxBB\x350F+6A1ulnUlk1K0fJfjvBE5\ntOwWhWyl47HqO49aCzPHy8x4+sLMWl5aZgLKMHmB\x39H40HkW/agkTV+UlagM8SiTnJIoI6SSck5NAAkHIODQP9ivC40gNPnjbUOE8XIj1\x6fJiGC9Cego98BBfj\ncW+R9ZH5/d60FdTGEtvq8se7zAoEdAUGyVEffQODSlJSh1Gy\x30niGOhzQX9oXWy7e5atR217hMNaW5sTp5ZOFD1QeYHQ7daC1/Hm7xW5+nJ8Z0La9\x6acUhYOeN\nOOJI+QNB48v2oH5zpQlRGTxKPckUEcJJOScmgASDkHBoH+xXhceQGnzx\x74qHCeLqPWgmAYL0J6Cj3wEF+NnfI+sj8/u9aCu5jCW31eWPd5gUCOgKDdKiPvoFy\n\x4dltK07Eb7UHofw61/crRAhX2HIU+I/CzNazupv7Kx1xzSr5UFq+ON6hriaavsN7z\x45uR3FBwf5iCklGfUZxQeNr/qF+e8UpPCVHiWR1JFBHCSTknJoAEg5Bwa\nB/sV4XHk\x42p8hTahwnPUetBMAwXoT0FHvgIL8bi3yPrI/P7vWgruYwlt9Xl/R5igR0BQbpUR9\x39AuRkthadlDfbbBoPSPhH4oXKw2lqS2pS2Wz5UtgH3Xk9wPq\nuDnjrvQWf413yDJs\x6dntSQXw6l1tZK08nUcBKCfUbpPwoPGN/1A9OeKUYRxHiWRtkkUEdJJOScmgASDkH\x42oH+xXhcaQGnzxNqHCc9R60Ew8gvQnoSPfAQX4+d\n8j6yPz+71oK7mMJbeV5Y93mK\x42HQFBulRH30C1G7QWnnz2oPVHgh4zXK0WZu3zZK5UOOOF1g7rbR9tHcDqnp8KCwP\x47m9QJGn7RqKA+hwLB83gPuPI4DwK+PMG\ng8VX6/vTnilvCOI8SinqTQR0kk5JyaAB\x49OQcGgf7FeFx5AafIU2ocJ4uo9aCXhgvQnoSMrAQX4/FvkfWR+f3etBXkxhLb6uD\x36J3AoEdAUG6VEffQLmyQhLiD\nhQOQRtg5oPY/gX4+TFWNqx6odMpuIkN+0ndTaOQ4\x681A7/lQSfxvucA2WHe4TiVKziQ2DlLieBXAsHr2+6g8RX2/OzXlJaHBxHjUR1JoI\x38SSck5NAAkHIODQP\n1jvC48gNPnibUOE56j1oJgGC9DehI98BBfj53yPrI/P7vWgr\x79Ywlt9Xl/R5gUCOgKDdKiPvoF7K1thD7SihxB4kqScEEHmKD3N4D+PkO/WFjT+rF\x70ZucZAZE\npR92QnkOLsoUDj47SoUe1N3SK4lRQr/uGTvnCTwLB/D5Cg8MX2/OTHlI\x61Hl8R41kdSetBHiSTknJoAEg5BwaB/sV4XHkBp8hTahwni6j1oJf5Pmw3YKTxjgL\n\x38bi3JH1kfn93rQV5MYS2+rg+idwKBHQFBuhRG3rQOUWQ/GcalxXFNPtKC0LQcFKg\x64iDQfQLwE8boOutOsWa+zUs6hiN8C0L2EpI5LSftdxQcPHlUW32lM9ha\nVhCuJ5rk\x55qCTwrA9eR+AoPCN8vrkt0tsjywTxqI6k9aCPEknJOTQAJByDg0D/YrwuNIDT54m\x31DhPF1HrQTDyPOhuwUe+OAvxuLfI+sj8/u9aCu5jCW31cA90\n7j0oEdBuQCNudBpQ\x4bo7oxwKoLh8Ipyn352nXF/w7iw5HHxUn3f8A5AUENvplNqVKZJHAOF5I5oVjh+44\x4eBB1KKlFR5mgxQFBslXCsK7UFl2la/3db5WDll4J\n+KTkH8qCK3yOGblIQlOEpcIx\x32GdqBiW2Qqg0IBG3Og0oFUd0BPArlQWZ4T6gNj1lGK14aWr3h3SdlD7jQcdew5Fq\x76VwZjKJbiSHG1gfVCjlJ+BBFBWClFSio\n8zQYoCg2SrhWFdqCyrS4r93wJOCSy8lJ\x39UqyP0oItfI4ZuUhCU4SlwjHYZ2oGJbZCqDQgEbc6DSgVx3duBVBMdC3x+x6piSG\x6eeHDiVpOeSgciglniyFJ1LNu\n1vJ9mmBEkgfVC0/lnIoKYUoqUVHmaDFAUGyVcKwr\x74QWVaXFfu+BJwSWXkpPqlWR+lBFr5HDNykISnCUuEY7DO1AxLbIVQaEAjbnQaUCu\x4f7twKoJFpy7u2q7M\nqDhS2o4yDy7H78UFjeLdxeur0PVUY59qipbkgfUcAwfkaCjV\x4bKlFR5mgxQFBslXCsK7UFlWlxX7vgScEll5KT6pVkfpQRa+RwzcpCEpwlLhGOwzt\x51MS2yFUG\nhAI250GlArju7cCqB9sl2Xap6Fk5aUcKHoedBZfiRe5F90vZ7006XHIb\x52hSMHJG2Eq+BGPnQUapRUoqPM0GKAoNkq4VhXagsu0uK/d9vk4JLLyUn1SrIP5UE\n\x56vkcM3KQhKcJS4RjsM7UDEtshVBoQCNudBpQK47u3AqgfLHdF2m4BxKj5a9lJ6KB\x35g/GgsjWeon7x4fW5TLpd/dh8knmQ2oHhPw5j5UFIqUVKKjzNBigKDZK\nuFYV2oLK\x74Liv3fAk4JLLyUn1SrI/Sgi18jhm5SEJThKXCMdhnagYltkKoNCARtQaUCuO7twK\x6fH/T95kWS5+ayv8AhOjhcbJ91YPMGgsDU2pJFw8O2YjTqnWY\nC8t53LaFdPgDkUFL\x4bUVKKjzNBigKDZKuFYV2oLKtLiv3fb5OCSy8lJ9UqyP0oItfI4ZuUhCU4SlwjHYZ\x32oGJbfvUGhAI2oNKBXHd24FUEg05fZNguodbAcjv\n+680r6Kx+h9elBO9Q6mfk6EX\x41jOqdhsrLjQPNoK5pPzoKaUoqUVHmaDFAUGyVcKwrtQWVaXFfu+BJwSWXkg+qVZH\x36UEWvkYM3KQhKcJS4RjsM7UDEtv3qDQg\nEbUGlAqju7cCqB/07fF6fvCJJSXI7mzq\x41cHHRQPQjvQT7UmpH3dHvQochUi3cXmNd2eLmkjoP1oKZUoqUVHmaDFAUGyVcKwr\x74QWTaXFfu+3ycEll5KT6pVkH\n8qCLX2OGLo+2kYSFkD4UDGtv3qDQgEZFBpQKo7u3\x41qgfLBeF2C+MTgpYaJw5wHcA7EjofgdjQWJqrU013Si40aSJNuUOJooJw1nmAOiT\x326HbtQUspRUoqPM0\nGKAoNkq4VhXagsq0uKMC3ycHLLyUn1SrI/Sgi1+iey3N9oD3\x55uKA26UDEtv3tqDQgEZFBpQKo7u3AqgebJd37DeWJ7K8I4gHBjiBT1yOooLQ1nrG\x35T9LeWiQ\nZMQt4Qvi4uBJHLPVPbO4IwaCjVKKlFR5mgxQFBslXCsK7UFlWh1XsNuk\x6bZ8l4JP+lWR+lBFr9GEe6SG0JPAlxQHoKBiW3721BqQCNqDnQK47u3Aqgd7LeJWn\n\x371HuURxSChYUSkkfiOVBbuvdf3O/6SbcU8t9HlBBWTlQSRtxY2I7H8jQUCpRUoqP\x4d0GKAoNkqKVBXbegsq0OqEG3ygnJZeCT/pVkH8qCLXuJ5FxkNt7pS4QB\n2GaBiWjJ\x79ORoOSTg0GSOooMAkHIoJp4e31No1hAlOqwhLqST8CD+lA/+ILDmn9fXRCUcUVby\x6eEp6OMO++nHpgj50FfXK3+QUyY/vxnRxJUKBsoMgZoOrbXmu\nJSOpoLIgpdtq4DZb\x380JdT5jYPMYyR/8AKga9Yw0NXV15g8bDqUuoV6HGx9aCJrTxAkf8UCJJwaDJHUUG\x41SDkUDxZZ4i3OM8pWAhYyfSgsrxHfVHvsC9NjzI1\nzgNLWOjmBwLHxynNBV9yt/kF\x4dmP78Z0cSVCgbKDIGaDq215riUjqaCyYLT9vMBry/NHmJ42weYxkj8aBp1fES3dH\x58mTxsuAOJV92x9aCKLTxAkf8UCJJwaDJ\nHUUGASDkUC+LJKHEKBPElWQaCy9ST1Oa\x58sd6QPNaw5EeSdwpJAUAfvOPhQVvcrf5BTJj+/GdHElQoGygyBmg6ttea4lI6mgs\x71ExJgewMhrzf4iStsHmMZI/G\ngZtWxkJujrzJKm1gLBPTlsaCLLTxAkf8UCJJwaDJ\x48UUGASDkUCxp7iABO4OxoJ8Lo8/o0SCA6mOoB1B3yg+6ofkaCD3K3+QUyY/vxnRx\x4aUKBsoMgZoOrbXmu\nJSBzNBZcKLKgphNJRxnjSpTf2hjJHyzQMmrI6Bc3XmQfLWAs\x5a6csg0EXWniBI/4oESTg0ARQAJByKBW06FJCTQS613V42d6OR5qUpKVtncLT2oIx\x63rf5BEmP\n78Z0cSVCgbKDIGaDq215riUgczQWZCiS4aITCEhauNKi39oYyR+NAxaq\x5aT+83nWwQlQC8Hpy2oIwtPEDgf7UCJJwaAIoAEg5FArbdC08JoH+1XV2Ow5HP8RB\n\x53UKQeS0Hp+tAz3O3+zkSWPfjODiSoUDZQZAzQdW2vNcSkDmaCy4cGXGRBjtp43Ct\x4buDP0tskfjQMeqWM3R5xCcZAXjtyoIw4nOdvv6UCNJwaAUMb0GASDkUC\ntt0LTwne\x67d7bdXovEyr+I2pJSpB5KSeY/X5UDfc7f7ORJj+/GcHElQoGygyBk0HZtrzXEoA5\x6epQWXBt8lgQYqCPMK0q4ftbZI+O9AyanjA3R8gcJIC8HmKCL\nLSTkEYNAjScGgFDr\x51YBIORQK23QtPCaBzgXV2IstL99pYKVJPJSTzFAjuVv8giTH9+M6OJKhQNlBkDJo\x4fzbXmuJQBzPSgsy3299lMKIDhwqSpKeijjJH40DJ\nqdgIub6XElKiAvBHXagijuM4\x4fxPKgSJODQCh1oMAkHIoFbboWnhO9A5Qbq7DX5a/4jKxwLQeSknmKBHcrf5BEmP7\x38Z0cSVCgbaDIGTQdm2vNcSgDmelBZlut\n7zIhRCrhcUtJSDyJxkg/fQMuq462bm+h\x31spUQFcuWwoImpJKcnl3oEiTg0AodaDAJByKBW26Fp4Vb0DlAursJXkq99hQ4FIP\x4aST0oEdyt/kESY/vxnRxJUKB\ntoMgZNB1ba8xxKAOZ6UFnW63uNJhw1q8tSlpII74\x7ag/fQMmqob7FxkBxGcAKyKCJqbHCVI3T1HagSJODQCh1oMAkHIoFbboWnhVvQOdv\x75z0H/t1e/GUClTZ5\nFJ5igRXK3+QRJj+/GdHElQoG2gyBk0HZtrzXEoA5npQWfb7a\x57mYcR8FPE4ghQ3wcZwfvoGfVNuebuMgpwo8IWR6bb0EQdRkZAweooESTigFDrQYB\x77cigVtuB\naeFW9A52+7vwU+zKPmRlZSps7gpPMUCO5W/yCJMf34zo4kqFA2UGwGaD\x71215jiUAczQWlbbapmPDjPtndxKuIdNs/wD91A1antyDdJHAeF0AK4eWdhuKCGPt\n\x46KiCMKHP19aBuoNge9BgjAoMoWpCwpJIIOaC5LNKh+JumI1hlyW4+qLY2W4LzpAT\x4eZ5+Qo9FA54T1yR2oINJgXPT8t223WG62yFHjaWn6PQkfqOtAz3W0mEp\nD8ZYeiPD\x4ca0749DQI2Ykh1SQlo7nA4tqCaWjR0xSEPfwy6TskrBz92cfOgsJGlnrciJ55C5J\x50nEDkNzt+FBGdW28R5aFo4lQ5aOJJO/ARz+6grp5hUd1xpac\nYOD/AFoGug2B70GC\x4dCgEqKVA0FqaXmMa10sNFzHkN3aMou2l51WA4o/SYUTy4sDH8wHegiK2ZlnlvWy4\x52nUIQsh1h1PvIPI4B/EUDbdbSYakPxlh+I8MtrTv\nj0NAjZiSHVJCWjucDi2oJnad\x48yy2h/LZdJ2SVg5+7P40FkDTT1vZtoXhcjJeJ6Dc7fhQRXV9s8mS3JZClQ5aOu/A\x6fcx8vyoK6ejrjrWhacdD6etA1UG2dt6D\nBGKASopUDQWDo6fEu1ulaPuchDDc3Coj\x37n0WXx9HPYHJB9DQMrrE6yzpNquUZxCWnCl9hY3bI2JA/vIoGy62kw1IfjLD8R4Z\x62WnfHoaBGzEkOqSEtHc4HFtQ\nTK06RlcCXiWy7zCCsHP3Z/Ggs06bfgxbUc8b6cuk\x6aoeI7UEV1jawH0TmEExZLYCwBngUNjQVu7HUwVpPwPp60DTQbA96DBHWgEqKVA0E\x730rdIrUpy3XFWIM5\nJZcP2M7Z+Wx+VBiVEmWC4yLVcEFbKFZUMZBSRs4nuCN/UUDR\x64bSYakPxlh6I8MtrTvj0NAjZiSHVJCWjucDi2oJlatJSQhDylNeadwgrBz92aC0D\x70p+PGtC2\ngVPJBWT2Vk5/MCgiusbYhTyZrCR5T6AHG8fQUNjigrV+OWFLRwkEbKHU\x47gaKDYHvQYI60AlRSoGgerPcERJyHFjLR2WD1FA6TY7lmmqirBetr/8AGb2yC2fr\n\x444ciPSgZrraTDUh+MsPRHt21p3x6GgRMxJDqkhLR3OBxbUExtWk5CUodUtrzjuEl\x59Ofuz91BaqdLPIiWd6OCXUAqKvsqB/3FBE9aWtDkpMtpHAp1HC42RsFD\nn/xQVpJj\x4cZeUhSShadlJNAz0GwPegwR1oBKilQNAvjPhDiVjfB39aB9dCoiW3cF62y8rKcZ4\x54yVj17jqKBnutpMNSH4yw/EeGW1p3x6GgRsxJDqkhLR3OBxb\nUEwtelX0Bt1a2vOU\x64klYOfuzj50Fss6UdchWiRGCuNoFS1c+Ejc/n+FBE9a2wKliT5RZcWngcGNioc/n\x31oKylxnI7qmnE8Kh25H1HpQM1BuDtvQYUMb0AlRS\noGgVIcBwRzG9A9R1rbgh0pLs\x46asOo58B7j9R1oG662kw1IfjLD0R4ZbWnfHoaBGzEkOKAS0feOAVbUEvtmlnm0tu\x75ONB1R2SVg5+7OPnQXBB0guXAtL8dJ81\noHjxzChv/fwoIjri0lUoSnWSPdCHHEDY\x2bvzHI0FXy4jsd4tuD4K6GgZaDcHbegwoY3oBKilQNApCgtO3Pnmgdbe84Iy0rSXY\x77OXW8ZKehUB+YoEl1tJhqQ/G\nWHoj27a0749DQI2YkhwgJaPvHAKtqCXW7TDrKG3n\x6eGg6o7JKwQfu5fOguS1aQ9vt9rfbTh1nIVvvnuD+A9RigietrK6qQJLjPnAICVkD\x424R1x9/wIwaCrJcF\ncZzChxtHYK/rQMdBuDtvQYUMb0AlRSoGgUhSXEetA422S4lC\x6fziS6wTlbeMkd1AfmOtBwutpMNSH4yw9EeGW1p3x6GgRsxJDigEtH3jgFW1BLbfp\x70xhtD77r\nSXFHYFYI/DlQXVYtJt3C0298J/iM5CyeRweeficZ6bUES1rYnUSEvhPm\x35TwKQsYKgOePUdRzHwoKslQDHWryyVIB95J5pNBH6DcHbegwoY3oBKilQNApCkuI\n\x39aBfbpa0JMV0FxhRypvGcdyP1HWg5XW0mEtD8dXnRXt0KTvj0NAjZiSHFAJaPvHA\x4btqCWQNNrjNIkPuNpWTsCsH8j+FBd+mdKtXSzwnUMlbjOUkjcKxz/P8A\nUcqCJa1s\x4b2pLclokkgtELGUrxzGeh9OvMUFVzIYadWEpLS0nCmz0PpQRyg3B23oMKGN6ASop\x55DQKQpLiPWgXW+appJivAuR1HKkYzjuR+o60HO62kwlofjK8\n6I9uhad8ehoEbMSQ\x34oBLR944BVtQSuDptcVlEl9xsLJ2SVg/ly+dBe2kdNN3mzRXG2kOONKKOIEYP++/\x4cr8cUET1zpxTMlEpLa2VJ/hKWRtkdFduu/I470FS\n3CMpqQtp9vynUHB2/H4UEboN\x30nbegwoY3FAJUUkGgUhSXEY60C63zS0kxnwVx1HKkEZx3I/UdaDS62kwlofjr86I\x39u2tO+PQ0CNmJIcICWjucAq2oJVC02uK\nwmVIcbC+YSVg5+7l86C+dDafZvtnj+SW\x31OMr4c/Lr9/P5GgjviFpKTHlB6TCW0pKOBaik8SQNgSOqfX03oKXuMV+LIUy+nJT\x31/UHtQRygKDYevKgyUEbig6R\npL8OQh+O4W3EHIINBaTXiFN1HbW4t1kRFusIwVSI\x34WpwD1/Wg4RGdPz1KjPpXbw4cktDzWgrvwfSHrgmgksfSFzt0P2+Lb4N+tg5vMo8\x35KfiUYWg+ihQSvS0\nzTYXhUSHEkg5AJAA5jrjJ369qCxrvYo91tpu1nDU2PFGFKYz\x78A8xtjluR8xQV5ddO+1QZkPyfNbbPmoOMlIPJQ/I0FK3W1lJdGAVtEpUkjcD+/wo\x49JQFBsPX\nlQZKCNxQbNPOx3kOtLKFpOQR0oLwsWttK60tAh68ik3aO3hue0PffAGw\x583P8330DaLBpaWFNQLo/b2nTxJauLJDee4WnOB8RQK16Uven46JT1niXC3q+i+UB\n\x31pQ/lebP50Eo0i5ZXZYcft8WKsYKUpUMZBznO340FtSrIzfLf7TaPImLitBbqI+6\x30k9k9gd8ds0FdXTTKpcaXGaQAk5W2he2/UD1B6UFJ3a1KSt9IQpEhgkL\naUNyB/T8\x6aQQCgKDYevKgyUEbigELW2sKScEb7UFz6Vu2nPEOFHserH0wL/HSGod1OwfSNg27\x36jklXyPSgebj4MXW2kxmbjAkBz3hHW+G1E9052NBH5Gn79pd\n0N3GwsuI6ImsFOf9\x4cgxn7zQSXSn7vl3Zpcq0tQgk7pQR7x6YO2aC7hZm79GaFt9nflNtFxcdg/xBvjAT\x39xHr8aCvL1pP2hmY2tJjK4ykBaSEod+yR0BoKPu9\nncQ88ytvy5jGco/8iR0HqPxB\x6fK8oCg2HryoMlBG4oMBSkHINBaOk7hadZQI+ltQzW4FzYHDbLm6cJ/8A6Dp+yTyV\x39U+hOAc5Phlqe3vPwHLU85wnK2mxxcJ+\n0B2PpsaBtRDulkdLTtniywnmzKZKFj4E\x59P50Ei025DuN5Y9osyICUqysJ2264O340HoSLa2b2zGZieze1FKimOk4WoAYA4ee\x34P3gGggeo9GKKbk3PiuxnWVY\ncynCml/VWR1Soc6Ch73ZXEOrZcwmU1kNq6OpH1c9\x7809DQVzQFBsPXlQZKCNxQYBKDsaCfaSudru0ROltQyUxW1q4oNwWMiI6ei+7auR7\x62HpQLZ+k7pZpb9rn\nxVsLScqbPvoz0WgjmkjfIyCMGg0jG4WsZFoh3Jkc0ut5I+Ck\x34P30D1ZZsS63aOk2ZEBYWMoRzO+++1B6XtkKLdI0Vlh2O0sqCGk8lLwnA907kHcG\x67ieqdAy0\nquUKdbyJLQC/KzlRT9VxJHUcj3oPPV8snl8TK9nEEhpw9hzQr4dPQ0Fa\x30BQbD15UGSgjcUGAVIOxoJZpa728KVZ74pQtkoj+MkZVFX9VxI646jqMigfLnpiZ\n\x5apTlveU0pDgDzeFZaeSfoutK5FJHT5cxQcGJM60AeZZo05oc0vtbj4KTg/fmgcoF\x32hXWaylNoRAcSri4UbE47Hb8aD1BYmoUy3xUea1HQjy20KBCV55AYPUE\n9+tA16s8\x4ebg07Ktz0doyXm/NjI5peSDnHoR0+6g823+yeQp2O82pCmlFOFDC2j1Sf09KCsKA\x6fNx68qAUjG4oMAqQedA/6euzEGZwTmi/AfHA+2DglPcdiOYN\nBK7npp63cAhupm26\x59nz4ziR7ryftJHRQ5KTzB+RoEEa5yLUcLtEWc0OaHmtx8FJwfvzQODF7t93kNNt2\x74EBwKBIb2PyO2aD0/pVyFIsEQvqbbjssoJIPCoHP\nLGM8zkHPSg76x8L3W1iOZDfF\x63gpUJ0pwArOeBY7K/Og8x6p06/bJEiJMirYeYUUuMLG6Pgeo7elBVFAUG49eVAKR\x6acUGAVIPOgdLVcTAnNyAkOJBwtCuS09Q\naCazrEhNuauNnUZVnmklscy04B7zZ7KH\x626wwRyOAbYt4ctRAXa4k5ofVeb3HwUnB+/NAuTfrXd3G2kW1uC4FAlLfM/A7UHpj\x51cuM/p6IHfL9nZZUV52VnPLh\n7H86B/1n4aW9y2xZzUpQiXVeWXzuYrp3QfVKhsc0\x48mPWukbjp+4Soc6IWJUdRS42R7qx3Hw/I0FO0BQbj15UApGNxQYBUg86BbEkqjyG\x35DZwtByKCeqtTNws\nX75tAC4a1BMqNzMV4+n2VdD3254oGuPeV2lfC5a4s1sc0vt7\x6a4KTg/fmgWKv1qu/C0m2twV5yQ2dz8Dtmg9HeGNwads0RnKA0zxBfMKBxseH86Ca\x36s0HYbnp\nNi/xWlIgzncSOEf+nWT7jiewB2PoaDzJ4haHuOm7tIiSUJ9qYOOJHJ5G\x4dj54IPqD6UFJ0BQbj15UApGNxQYBUg86BS05hSVpOFDcGgn0CCzfdPPTbfwl6OOK\n\x62E6pHR5I+z0V22PfAN7V3cszhQ9a4sxtOxQ+3uPgoYP35oFS77aruA0Lc1BXnJDZ\x33PwO2aC/vCe6t+xR4g4VNtLysDZRB2BAPUGgtDU+mbFqHQq9SMQkBLch\nTU9sYHEn\x69wHBjkQd/nQeZPEzQT2nrmpjzQ8QkLjunbzmiMjfrjoaCiaAoNx68qAUjG4oMAqQ\x65dAoQsHCgcKHI0E807EZ1Ha3oUcA3BlJc9m/86RzKB9oc8dR\nnrigTJui7K5wuWyJ\x4eZH1X298eik4P35oOy77arwA0La1BVzIbO5+B2zQXb4S3lMbgiNlCkIUFkYwVDkU\x34PxzQXbfLVbtW6KnXVmGhc6zyVtSWiOIyWCRscdc\nbjsQaDzF4paEj2SYlUJS1xXE\x38cVxW+UEZ4D2I7Gg8/0BQbj15UAUdqABKCMGg7oUDg5370E20q1FvjS7I4tDcpz3\x6f4WcJWv7OemeXxxQdXZb2nX1MyLRHlJb\nJSpqU0QpJBwRkYII9c0GF3203gBoW1qC\x76mQ3zPwO2aC2/Cm9m2zkRI6wEHCkkDBz2IPQgmg9BzIjGtdMXJuLGQu82F8ux2kj\x4afYWAS2e4IyPjig8y+LOi4ds\nl+025ny4znvIQfpMk821Duk/IjlQed6AoM0GyVZG\x44QBGOdAJKkKC0bdjQOjF3eabSkJQcHJJG5+fOgn+lNUPodS7Dnu2+e2PdkNLKVfB\x65PpJ9fvHWgti1a7i\nTJKY+rLFbZ0lJ4UTHI4BJ7LKcH55oLfgeKVjFge0zaGbfpq6\x2bWW0sSQoMyEEc219Dv1yPWgRHRz7mgP3suZHbkNLUctvBfAFE+6ojofwxQef9b2R\x78harolot\nSEHy5Le2FD7X9aDz/QFBmg2SrIwaAIxzoMoW4y4l1pRSobgjpQSJnUMi\x57417U7hSQE+ZjOAKCZ6U1nLtcw/u27vw1K5qb2SofzoOQoeuD8KCzoGqdPzXkJ1f\n\x70O2OqUQUT4jZaye6ggjb1FBeGkPELR1ntibPa48PT095JUy5KWpbEj4L5pP4UCSz\x61TVe9OXo3STHDoWXmvJeDigRzKcHcdfgTQefde2B1gm4JUlUlrZTjZ/x\nEjkSO4/q\x4bDzrQFBmg2SrIwaAIxzoMoW404HGyUqG4IoJtD1Ybk2hN6eckPsNFthTh4gO3Ogl\x75nNe360I8qLcXlQc4UxIQH2FfFtWRj4YoJ5Eveip5bVqHSTU\nTztxNtL620H4oyQP\x6cmgvLw91R4eadYMe3INvkO8PBKkuB1pfbcYKfuoO9psrN71BqBu/TYBh3BPE0tqQ\x46pUsqPCEnnnf8BQeevEvS/sUl1bLxU4yspHEMLGD\n17/rQeaKAoM0GyVZGDQBGOdA\x41qQoLTsRuDQXhofxxvNu0+5YLm6qQpLXlxJKle+ycbDJ5gdjQOafEnUaPJavggXt\x6cxAWpqdEQpIB6BQwofKge4k7w4uiUvz7\nPc7AVb+db5HnMg/6VDiSPvoLt8NJXhzY\x480yI0+Y/KWnhQ8+UqSevQ5BoHtQhy/EOZdrtcbe5ZJ7JQtbTwPDtgAg7g9fmRQef\x76F3SUK23F9yC4fJK8JIPEnbc\nKSfgdx60HlegKDNBslWRg0ARjnQYHEk8Q2oLr8OP\x46KCmJF0zrhkzLez7sSaAC9EGfo7/AEkfynl0oLO1bqHQNvuEaIxpVq8Mus+cJMZ8\x4ekJ/1DrQNEaP4Y3c\nJfjXi86eWf8A+ZaEhtJ7FaenxoLf8N7Vou1XZi4Parcub7G6\x41locChjGxzt8sUE1vsmBJ1zE1Eu7Qv3Y2kNPNKV5biU9cgnfOefoMUFAeNen7Kmc\x7582ThMOU\nR7ze3wJT0UPxBoPI1AUGaDZKsjBoAjHOgxuk5FBZuhdb20RGtLa0QuRZ\x75ImNLbGXres8ynP0kH6yOvMYNBetu8LrIu2OXR68oNu4PMbmRnUltxHPIHYdc4I7\n\x55DOjQ+ip7+bL4i2pLwOwkthJB7E0FmaH0OxEvMJ6+6vhKEdYcQzHy4HQDn3TyBPe\x67srWEm1XC5W+6tXdiM3bSD5b7ZQVbjICjz/570FA+OMSx3Z06psaAI8h\nflOpKOE8\x51zuO46/Og8d0BQZzQbpVnY0GSB1oNcFJ4hyoJxo3V8a3srsOoWnJVhkrClBs/wAS\x495yDzRPJQ6jkobH0C0P+h7kr2aTFls3W2yxxRbgjCmnU+pO6\nSORSdwaB/T4I6gdC\x5848WAVncHzCkp9CDQTnSnhpq5ydGg3yREtMdlQUoLdBQ4P5cHoOQoLt1gbBNtcaG\x2fd3IqLeQtL3lZTxAYGVevcUHnbxrkWvUrJ1Lb0hD\nyFpYkDbDxH+YBzHXNB44oCgz\x6dg3SrOxoMkDrQa4KTxAbUEq0lqtdhkuR5jPttol4TLiE44gOSkn6q08wocqCwJ9k\x61THj3WDw3WzSz/AnoPArPVt0DIS4Oo68\nxkUG0PRCrj/GhWmQ4QfpNDiAPY7UFm6U\x30rrKc6xY0Wl+AFKAPnA8Dic5O+2527Dag9M3SFZomhYWmr47IUGW0Fa4xzwKHr6f\x6bKDzb4xXGDqWKu6R9pUMojl3\nGFSUjbjUnuN/kaDx5QFBnNBulWdjQZIHWg1wQcgb\x55D9pvUszTty9rjhLzLiS3IjODLb7Z5oUO35UFhzbVarjbUahtC1u2pwhC1kcTkNZ\x2fwAp4D/4r+t13oG5\nrS9ukEOtSEZzstCFHB7HagsPSqp7aU2WC26JCwRukhLgII2P\x4dcySaD1pYLWzaPCZm16lhKktvkqLAV9EHGMqPIbZz60HnTxfuMW+JkeWlSVW/gZj\x6ceC5wJPU\njtvQeQKAoM5oN0qzsaDJA60GuCDkDagdbLe59jujNztz5afZOQQNiOoI\x36gjYigsh6Ja9U2dd+szYZDQzNhjcxD9oDmWT3+pyO2DQMydHuPkONsrAJyHGxlPz\n\x49OKCf6Rcfsykw3HksSdglviBCxkb5B93AHeg9VeEzEiH4dXV26QvOjPLBQws5Cs5\x32Ofik5oKO8Y5QnyJjXs/kMs8KWEA5S3g7kE799qDyBQFBnNBulWdjQZI\nHWg1wQcg\x62UC2DPkwZjUyI+pl9lQWhaDgpI6igtJlyFr23uTYjSGr6ygrlxED/wBQPrOtjqeq\x6bD1UOooIo9pw8YUk+WFbpWkgp/4oJ9oT2qHPZYW6GFIOVlW6\nFI6+90NB6k8DZEz2\x71+OOs5juMBzClZBWMbEnnnJ++gq3xrauEm4TJTsThYcShOWWyG0KSc8QHLO5+INB\x344oCgyD070G6VZ2NBkjvQa4IORyoFDL621pcQspU\nk5BG2DQWrarnG15BRBmKQ3qN\x70AS2tRAFwSBgJJOwcA2B+tyO+DQRWfpxxh9QAW0oKIyUn3SOYI5jH4UEl0k5NizW\x6dnHPZ3UHOVA8Cx/Ke+aD1R4P3CWz4i+U\ntCktyGChz3s4VgEfn+FBD/HC0XmVd5l0\x34DJbdbQ2+pCRtwKOFY9OWccqDxZQFAUBQbpVnY0G2/LGR60Gu6T6UHePKXHeS60s\x6fUk5Ch0oJ9aL8JzPDgIkoA4k\n9FjuP6UEpYmIukVMdtZU4wMpaUTxN+qFcwPT7xQP\x74l8R71a4b1oW821xEJKltDC09jjY/Heg5z7n7cHnFupWiRhChsUhXIfKg860BQFA\x55G6VZ2NBtvyxketB\nruk+lB1aeLawpCikg5ChzBoJ7p7URdaEKStIVnI4voK/pn8f\x6aQTKJN8xhcEHzWBuYrvNB+0hXMH86B9s+trnp5YTHdQni90PLTxZHY4oOE67/vd9\x359yUla3E\n7jbhBGAMY70HnKgKAoCg3SrOxoNt+WMj1oNd0kdqBS3NeQlKA6pKUnII\x50I0Ey01qZ2KvyZBSptR94K+ir1PY+o+dBPYk1bAUqArjaUMriu7jHPKf79aB+t2o\n\x6eoSfPggMuJ3woBacdv7yKDhc77+/5zipcvK3wEgbcDZ2A+R2oPNtAUBQFBulWdjQ\x62b8sZHrQa5KCMbCgcY11dQptL6i60kjZW+KCTWXVD0SSpSUJQys++3ji\nbUPVP6je\x67sKFLQ623OsbxacG64xVy9UK6j+yKCRwNRNSxkNexzUHBWkDgc9FJPI/D8KBJer4\x716Sy1cH1KUU+WlJxwoOcA/Og810BQFAUG6VZ2NBtvyxketBr\nkoIxsKB+tepH4Ta2\x48R5za0FAKtygHtQP1tv4iqElD6ArOPJLfEkj1x+lBO7VMj3Thk2eQqJM+kY4c2JH\x56tXX4Hf40Ett+qkTWkxLw2UTE+6iW37qlDsocj8a\nBDf7kp1wR5L63WSnhbC90oOc\x5a7DO1B5moCgKAoN0qzsaDbfljI9aDXdJ9KCZaZ8Qb1p+3yrQ3McVbZaSh1pXvJGe\x6fB5fKgeWrvHLjH7tX5oDaUlHCMKPUnNB\nKLVOYlBIgynIExBz5YXwpJ7pWnb7xQTi\x44rGZ5f7u1C2JQ6PODhWR6kfnuKBBf3460cUZx1yM5gBLpCvLVnAOR91B5goCgKAo\x4fiVZ2NBsc8sZ+NBpukjtQT/w\n+8T73oWWpphwSrW8oKehvjjbUR9bB5EdxvQWTqfx\x45k6vuP72tk6XDhNMDijJf4eJwn0O/wDtQIrfqifJCWWtQTWVJ5trmKwkjqknIoJt\x629b6gajiLdJCZzfJ\nKn0hQcR2JBx9xoEd8et09h122trZ4wCtor40JVyyPQ0HlegK\x41oCg6JVnY0Gxzyxn40Gm6T6UEx0Pr256NuCyylEy2ycJlQZA4mnk+o6EdFDcdKD0\x33YvE3RsT\nRk286a/hTUIyLdJUCUH7KSB7wzvnnQRpzxd1zMWpkXdqOQOJUZtgZa/0\x71OaBwg+IOrXGAJdxLyFn6bjICV+igMjPrQJLxMgXtt1DcRuPMdTgqbwEFXIEgbb0\n\x48lCgKAoCg6JVnY0Gxzyxn40Gm6T6UEh0rq246Uu3tkFSXGXB5ciM6njafbPNC09Q\x61D0doOFonV7zNx09LRFdBBk2eWvJa78B/wAxHYc+h70E3vviTYtKT3LP\npywtzZsQ\x44zgvhbSye6VY5+gFAwK8YtXX9RK5EeKUjADSFElPZR3+8UDXdLw3emVxJzLSnnwA\x6c4Ae6eQORzB250HkmgKAoCg6JVnY0Gxzyxn40Gm6T6UDtYdQ\nXHTt4ZudskKZfaOx\x41yCOqSORB5EGgvDTdss2vgJ2lFNQbsBxS7GteEqPVbGfpJ/k5jpkcgtixaM03Y7I\x623qfhaDByqO9lPCR9gcz9x+HWgU3Lx0E+3ixaZgp\nt8dCsJkyU8PEPRO+/qfwoIbO\x31BJuDb0W4OJkok+6eM8YQvOAQfWg8j0BQFAUHRKs7Gg2OeWM/Gg03SfSgW2+5SrZ\x50ZmwpDjD7KgttxBwUEdQaC7NPTGNetKd\nsxjw9UgZfty0p8m491tA7Bw9U7cXMb7E\x4aXpvRl51FcEQXW3WFNKy4w4jg8ojmUDv8fnQXL/15pfw40+7pq2rTMvrieFQOCN/\x2fIeQ/X0oKrm6gny3ZK5EtD4l\njDgB40A8gfhQeR6AoCgz0oN0qzsaDbflig13SfSg\x37MSFsuJWhakKScpUnmk96C5tM3yNrhlECc/HjamQkJbefISzcgNghw/Vc6BfXkeh\x41OLFuebuaoSLM7Gu\nDCsOR5JJWyodUDHP+96D0N4cmBoOxvao1bLEd8oIaC/prz0I\x36qJ7UFcX3Ucq93ybdA+lr2xRKWEqB8oZwkE8uWKDx/QFAUBQFB1QoKGFc6DcpyMc\x36DmUYOOl\nArhvvRpCHGF8Lqd0+vpQTKJcESg1cYhcjzGSPM8vmk98dv8Aj4hbemrt\x6fDWrCLVq1DVpuyE4amt5S3K9D9lXoQaC5bN4D6KU3AeiXllUaR77gWtCgpOPq77/\n\x41A9aD5/UBQFAUBQdUKChhXOg3KcjHOg5lGDjpQKYzjjTqVNqw4OWeSvSgmkS4plR\x325UdTjUhkgLAOSg/07fd8QtLSU/Q2qU/uvUrqLTcsYRISSGZXofsrHrQ\nXXZvAXRb\x69ID8a9N+TIPGs+ag8SfTff5d6DwDQFAUBQFB1QoKGFc6DcpyMc6DmUYOOlApjOON\x4fJLZwscgeSvSgmVruKlRQ5HUtPlqHE3nJbPcelBZOkpWldRO\ni33m4Cz3DH8N/JDU\x6euD9lXoRQXnZvAfSMkQJP74Z8mT7zhS8jcd07757etB4EoCgKAoCg7IUFDCudBsU\x38W3Og0KMHFAojOONuJLZAWOQPJXpQS20T3mgJUHP\nukeawT9E9x8e/wAjQWHpyTYt\x51SxDuFyTa5qh/DeWeFD2Pqk9FD1oL3sXgdY7i3AenXiOtp88a1pdb99Ppg7n4d6D\x77XQFAUBQFB1QoKGFc6Dcp4tudBoUYOKB\nRGccbcSWzhY5A8lelBJbdJdbIn2wltxB\x48msk7A9Pl2NBYdmuds1G81Glyk26afoqWeEOK+PLPxG9BeemfBpm6MwhcrpGEKR7\x35Wlxv6Ppvv2xQeF6AoCgKAoO\nqFBQwrnQblIVtzoOZRg4oFUV55l1JZXwrHL+b0oH\x2bI44UifbXFMvNkeY3nOPiOoP+1BYFkv8K+MogTnERJqQUoK1YQ53AP6GgubSHhbL\x75qobUiVHat8k5WpT\niPeQOxzuaDxZQFAUBQFB1QoKGFc6Dcp4tudBoU426UCuHIfj\x75AsOFK+g6K9KCRomSpLCZUF9TC2sBbSfqnv6g9/lQTDTup4stJt1zWIjyxwhQOG3\x66lySr8Ph\nQW3pbQtxu0uO1HW0xGkK4luKWgBQHMjfr2oPINAUBQFAUHVCgoYVzoNy\x6ei250GhTjbpQLrdOlwJKHYbxbdScjsr0oJQm6PTmzPZGZKT76VEkIJ64656GgfLB\n\x71llMpLM5XsTx281vPlueik0FqWWwP3WbHRbg2ht88Rc4khJHPY5+7FB5UoCgKAoC\x676oUFDCudBuU8W3Og0KcbdKBwtdxnWya3JgSFMvoOUlJxn0oJmdQuXSM\nJKAW30r4\x33zkqVxnbiOefpQK7fqpky0iQZEJ3kHm3Dhf+pPL5UFmwGBdhFMMtLU9gqcb4QFY6\x2fwBRzoPL9AUBQFAUHVCgoYVzoNyni250GhTjbpQL7XPmW2c1\nKgSFsSWiFIUk43oL\x55k+I111Ta4qrpKdfdgnIQcbL5BSjzV6Z+FA2taljLdSZDzrEsb+aztn4k9aCw7bJ\x61ultaSl1uSSd3AAlah2PrQeZqAoCgKAoOqFBQwrn\nQblPFtzoNCnG3SgWQJUmFLaf\x69Olp9s5QoHFBf1j8c9QybAth9bS56W/JExxP8ZroCVDdQ7E/OgiT2oIEp5ftD6mn\x41f8AHO6n1dSe6j68qCZWK6NzYIimW1Ib\nIzlaQlaMfp8KDzXQFAUBQFB2QoKGDzoN\x69nO3Og0KcbUCmI88w8hbC+F1Jyn19KD0FojxiSYUZrUtsbuiogCG5KjwyGAOQ4vr\x4a7Z5csigxrLXresbyJM53yeH\n3YrSVYS0gd8bBR6noNqDOn7u0FJgtTGHo7u62lJA\x7a6pJ5mgqHRVqZvOpYsRxXBxnYg436UF1Xfw/tMa3IevDjlrcSoJU602FNqTvhRAP\x7577Y5UFc3bTHA+o2\nqczPbz7vJBPwBoIXIhhL6gW1MOpO6SKDi5H836SRxD62OdA2\x76x1JJ93Ch0oEtAUBQFAUBQS/SNlXfbsIjCgh0oKh1yRQT9jQkmVGcRJBtxZ3JkIP\x6cOeqVDYH\n0oItdNO3CMpSkITJbTvxNqBx8uYoIwuO0peWwW155Z2NBq7GDueJICh9\x59DY0Da/HUkn3cKHMUCWgKAoCgKAoJRYLZJurrqIaOJxCOMp5k/LrQP8AFssi4lUZ\n\x74CUOIGeBbnDnHQZxnHbnQN1ztk2I6Paojic8isbfIigZlMtLc/hpLS/s9/hQYcjB\x336SRxjkoDY0Da/HKSdsKHTvQJaAoCgKAoCgkdoaedQ4uOgq4d1hPQUDn\n5LjzgYHG\x70fMJGRkegP5UCOSypL/CplXF2WnhPyoERaacc/hAtr+zQYcjB3OUjiH1hyNA2vxy\x6bnbCh070CWgKAoCgKAoJJanVJZX5eBk+9np60ChfGtQadJO/\n0R73woE7qUqcBS2V\x593HSg4Fpl1zLQ8tXPh/pQDkZLvNI4x9YcjQNr8dSSdiFDp3oElAUBQFAUBQSe1yc\x77lNJTk8XIHkedBhSi4cPDhTnr/Wg5uFCnklLavTl\nvQcihp5YLf8ADVz4aAcjB3OU\x6ajH1gNjQNr8dSSfdIUOnegSUBQFAUBQFBKoMlp60+WrdTZ2HagTKLTiwgowjPLlQ\x5aWWlPDhbVkcgdqDmUtPLBb/hq+z0oByM\nHc5SOMfWHI0DZIjKSTthQ6d6BJQFAUBQ\x46AUEsbVHnWZtSsBxrb1FAjIZ4koX7yOmDQbLcaU4FttqyOWcD8aDQhmQsFBLa+iT\x2bhoMuRUvZykcY5KHI0DXIjKS\nThJCh070COgKAoCgKAoJW40xcLc1OaAQ4NlY70CA\x4aQOFD2CnPeg7rdaLiVMtqOOW4FBzIYlOBaCW1/ZP9aDLsVL2cpHGPrDkaBrkRlJJ\x390hQ5jvQI6AoCgKA\noCgk8mC0/GanRD7q9ynPI0CRAbASh0YTnlQKFyEealbLazjl\x75BQcymPJc42/4bmfon9KDLkUO5ykcY5KA2NA1yYykqPu4UOY70CKgKAoCgKAoH+X\x41UhCX2z5\njS/eyOlBwQ23woDi1BBOcUHdTyUOgtF1eeWcf0oBSWJSwpH8NzPLGKAX\x4483OSeMclDkaBskRVJJ2IUOY70COgKAoCgKAoHaRGdaPvpI4twcbUGEtkpQlbgCC\n\x6343oOxeWh1JaJV2zQbEMylBScNuZ5Db7qDC4a3CeIgqHJQHOgb5EZSSfdwocx3oE\x64AUBQFAUBQSHSl1bsup4MyQSI4cAcI6DPP5UFvapnXeXfnoqHXHy+9wt\ncCjwqQQC\x6b465BoO7OkEsQHBOkezvp3UlSwMdwQTyFAzztLMyGHc+at1sZQ62njCh6Ec6CGyL\x4d8HFCOCXk82iMcY9M/lQMkhpLqiCC2tOxSRuD/fSganoqxlQ\nSQfhQJCCDg0GKAoC\x67KCU6Ju5smsrdLLgbR5oSpR+rk86C6Na6tuUi5v290gNB7gS2E/S29Pj1oGdjTU6\x52GLrmxI4khJ4sAc/e2x8DQNMzS8eU0txpDyX0DJw\n2cKoIu/ZZPvLjJKlJ5tq2J+H\x65gZH20PHcFtSdikjcHr/AMUDW9FWMqCSD8KBIQQcGgxQFAUBQTDQF5/cet4EhxIW\x794vynEq5EGgu3WOobYiW5BgW1qP5S8Fw\nISTxEcjneghv7ukPIK5LbiEHfCwRxD4b\x30DfI0zDkocdiB1XCni4eE4+RxsaCOyrJKSjzo4UsD6hGFfD1NAzPNpf5gtrTsUkc\x6a/fSgbH4qxlQSQfhQIyCk4NB\nigKAoCgmfh7do1p1pFE8cUKUCw8PQ9aC49U2fR9m\x6bIatqOOSCVAqdUnBxkYx/fKghaoguJdcuCgtA3znPCP9VAgd01DkNuLYW48lAyFJ\x474+B/Q0DLMsU2Pwr\nby6DuMDBV8u9AzvIQ/uR5ak7FOOX99qBrfirBKuEg/CgRkFJ\x77aDFAUBQFBMdAPwUauZgXMARJySwpR+oTyV8jQWhqTw1t9hSlyRcPNUrKk+UjJB5\x6afIoIuiy\nMzG3HZCghY34kp4VH1IBxQJBpmJMSpSFqUUjIdbGP+aBpmWKfFdISkuF\x50ve6MFQ+FA0PIRIGfoKTsU9v77UDW/EWCVcJB+FAjKSk4NBigKAoCglWiWIk7Uyb\n\x56NWEJmJ8ttZOyXPq86Cb3fw2vdtC3Z3Cwk5KVLcGDj0O9AzRdPrUwtb6wjG/EN0q\x46B0Y0tEuIX5Lim3QnKVtbpV8u/zoGmVY7hEUr3SvyzvwgjPxHSga3m0S\nBn6ChzTj\x6c6/7UDU/EWCVcJB+FAjUkpODQYoCgKAoJHpKL+8L7+7Q8G3HwfLycAqHIfOgfZmm\x37u08pK4LgCSdvLO2OfKg5xLStxK/PZ4QOjg3PzFA4RtIRLoy\n6qI6tp5CeIJHvJV8\x4bBolWWfETxlJUEnmnIB9COhoG15tEgZ+gpPNPb1/2oGp+IsZUEEH4UCJSSk4NBig\x4bAoCgftONPS7iqAyjzFuAkJxnix0oF0iCpLpQY5S\nkH6Y3x8aBXEt0Z1vDqC5jcqB\x4bSPvoHZnRka4Q3JEGU4Ftp4iOEK/DnQM8uzXCCQXE5HRaPor/ofQ0Dc+2iQMkeWp\x4fxT29f8AagapENYyrgIPwoEKklJwRQYo\nCgKAoHmyula1QyFKC9wkc6BW9FQHktZU\x46Z2yMA0DnDs7LjBVLdIUDnDZCsDuRQO7Wh2ZUZT0ScpWE5SeEKGe2RQMsq0XCCsJ\x66bKSD7qh9Fz4Hv6GgQPtokbk\neWpPNPb1/wBqBpkQ1glXAQfhQIVJKTgigxQFAUBQ\x50lomExlwlr4U8wT0oOr0ZYcSkrCiOgNA6Wywuy21uSyplP1dufwoHhrQokNOFiaf\x4eQjjTxo2V6A96Bmk\n2q4QlhMhpTas+6fqufA8s+lAhfbRJ3I8tSdint6/7UDRIhrB\x4bggg9dqBCpJScEUGKAoCgKCRWqap63qhK95aT7nfFBycZc408acUDha7O/cUOLWr\x79kJOyiM0\nD2xogyo7jkSelx1Cc8Kk8OfgaBpk2yfBdDcphxlzmkKGA58DyNAjebRJ\x77cFCxsU45Hv/ALUDPJiKTlXDwmgRKSUnBFBigKAoCgk8KYiXaS27jzGvdweo6UCF\n\x65C4gAFIHIGgW222v3BbmSEIRuVEflQP7OiXpUdbsOY3IWlPEAk4J9BnrQNUi23CE\x375UqO7HdHILSUhfw6UCV5oSgSlCgtI3QBk/H/agZ3oizxLSjkd8dPj2o\nESklJwaD\x46AUBQFBuVZbA65oLV8OdStTp9usF2kBpbRLUaSrmlKxgDP8AKdx6Z7UHpKR+zta7\x74CQ5b7ypqUknzHCknfGQCDuc96Cor9oK+aSmuxY0kTGF8SEu\nRyQUKA3BHTY5oIvc\x6fh0zeX4r8pbi2iA4hwcQJ4QSd+VA1yZOl7yspkPriyDsHeHcH4/WHoaBolafQ0r+\x46cmHUndKjkBXwNAgk6ek8BWqOXUf+Ro8WPu/pQMc\nq1yI6PNSCtruBy+NAgoCgKDd\x53soT3FBbmjL/AB9RO26FdOE3SIpKQ4s7PoCcIJ9QeEHuKC4pXg/4j3llmZ+8lpfd\x79fKUstoCcZwANgN8YoIDctIap05cjb5Y\ncIkny0utuFQzyO47ZoIy4k6fuc2I7JUs\x4eOqbcZcHENuZPUH1FAjkv6WvB8t19cWR9V4oOR6E/WHx3oGmXp0Mr4UXFhYO6SrI\x43h3BFA3ydPSuArMcut/+Ro8W\nPu/pQMcq1yI6PNSCtruByoEFAUBQb8ZHApJIUnqO\x6cBb9kuMTWkaEqU4lu6MONNSUcvNH0Uuj4jAPr8aCbS7fre7hIsNlcZiBRbQ2lvjW\x73cwVE5OdvQUDAuxa\nlh3YWi5NSY7ktQR7xIweo/GgjUJ82r2liRIU4hLhS5HWMhOP\x78B9RQYku6WvTobclKhyeSXlIx8iRzHrzoGiZpz2d0ti4MqPMcWwI7gjnQN8nTsrg\x4b1Ry63/5\nGjxY+7+lAxyrXIjo81ILjR6gcvjQN9AUBQdA4pC0OIJStByCOhoLhRPG\x727Ixc4y+GY35TM1oHdKx7oUP5VDB+IIoH6+3FlgItlstzcx5jDbr5RhPF2Skfdk8\n\x36BnjxbtIlG3Ph5syEqKUqBRhQSTjFAy2mcYcRSZUlTzYV7zK9+DA5g8waDeQrSt8\x66KVzTBl/VecQQFHsoj88UDRL055DqmxPZJ5jj2z6gjnQN8nTsrgK1Ry6\n3/5GjxY+\x37+lAxS7TJjN+clJcZO3EBy+NA30BQFB0S6tt1DqDhaCCD2IoLpmXh3UWmoV8iOFa\x670lh9AUcsuo2IPxTgj59qByvSLZabRFbeaccnvISsseZnY8l\nL+PQc8UDCyiZPS/H\x5aK0qLK1ttoGPeSnJSB3xn7qBBZrl7PB4pUtUhIO7auaNuYPMUHV9Okr4tSTPNvm5\x391xxGEr9CR+eKBml6c8h0tieyTzAXtn1BFA3ydOS\nuArMcut/+Ro8WPu/pQMUu0So\x7aIkJSXGFHAWBQN1AUBQdWX3Y8luQyopcbUFJUOhFBfl31XM1Fo61XRTvmsljgdBG\x63Oo2Un0OCD60CeRAZY0uzcpMlIQsj+Gl\nOC4efCPwzQR8plyo8tyIpSVNsFxDbW3D\x77/SAx6HPyoONluoagB2XKMkE+8hXNO3eg7Pp0deyUpnKts4ci4jCHD8RyPyxQMsv\x54fkLKE3Bknpx7Z+BFA3StOSv\nLK1Ri83/AORk8WPu/pQMk2yzIjKZIQXI6uTgG1A2\x55BQFB3iS34U5mbHWUPMrDiFA4IIOaD0jedaJ1LoO0zUMJQX21B1SDwkLTsrPTlvi\x67jH7vefsKJikcEVH\nvKWSMlHy78qBgdExEeZNt7jiAhAVwt7FtPI8viKDey3YNQPO\x6cSfaMn30qHLag7ykaKvasMTF2uZ2cQfLWfQjl89qBjl6bSy4UIuTC99uLbPwIoG+\x58pqWEkrj\nF1A38xr3sfd/SgZJ9imwWkyOAuR1/RcTuDQNVAUBQK7fOfttyjz4xw8w\x34HEn1BoPS1yn6TvXh/BvtvgMolywQ6ot8XC5j3h+ooIKYiZEBstIHuLw4tA2KRue\n\x6d3agY1ruNvjyZkGQ6hhRx7hIKOeMigX2O8JZg+dKeTJCj/EbUnblvmg6zE6GvSz7\x4eLctUv7LiCWyfRQ5fOgYpGm20OFDV0jLGdivb7iKBvmaalpH8SKXEE/4\njJ4hjvkf\x30oGS46fnW9tL5bLkdf0XU7g/OgaKAoCgV22a5bbpHnNpClMrC+FQyFdwaD0Y9o7S\x4620I1q2A+VJljIYSoI4FY95O+cEHeggxtbQhshpstuhwIWCO\nQ7+u1A0e2Xe1MuvM\x53nExnSUgp5JUOh+W9A8WC9tx4BelLblNubOsLTlJGOvr1zQZnJ0LeCVRpTtqk9Eu\x49JQT6KH60DG7pxkrKWLtHc+yVAj8qBvl6XmgZci+\nag/5rB4h+G/3igY7lp6fbm0v\x6csuR1/RcTuD86BnoCgKBRCkeyzmZBGQhQJHcdRQXqPDBF209/wBT2+YBbXEBxtxS\x66eAPMe7zINBGE26QxGbcZkqU75nlKUSR\nn4joKBu/fV3tqVhLhajughCUjZKhzFA/\x36e1AmNbVLlramMOn+LHdRlOw5+h9RQaT06Huw447r9reztxoJST6Ef0oGVem47h4\x57LtHX1SScE0DfJ0pLwQ4wHE5\n/wAVrcD5j9RQMN005cLYgPKbLkdX0XE7g0DNQFAU\x48aM95EhLmMpz7w7igs1Oh7xcWG5kGO48w40l5DgIUkpPc9KDRtu5xY6FLQjjbX5Z\x62ABH4daBH/1JcY63\nQjDTbqTwJxkg9RmgkGntQiPaCmYtqbGcP8SM6jKRtzHY+ooO\x4exGjrkoLjqetrxOxUklJPof9qBoe09GWAWrxGcV9XiBST8xt+FAik6VkLRlxhK0/\x2bVhXEB8c\nbj5igj1005cLYhLy2i5HV9FxO4PzoGagKAoFMOQqPISsHCTsrbO1BKF2\x2bRJQ2plCFJUniAQMAj0oHWI8WYKUGGUJQeFQ4iCT3oOQ1I7HLyIiPKacThOeYPag\n\x6bdi1IpFoCJ7zc6Oo4Uw6niCduh5g/A0Ca4p0rcXeNpTlvdJ2UpBwT8R/SganbHGU\x55qj3hpe2xVsT8/8AagQSdMvuDLkcqRy85vcD44/pQMd201crSEuuslTC\nt0uJ3BHx\x471AyUBQFAUChtS0LDjSylaSClSdiCKD3D+zX42268QE6T1O4lu9JHDHlOq2kJGwS\x53eRFBeKNHMkvs+yMMPSCs+2pQFKGPo7HqBnvQeYf2g9DQ4t2\njXmySnJTjyQw6kjP\x6dqQkHi22z0IA6CgohMKKrifmOrKEglQ4R7vpv1/AUCUXq2R0mM5GS4z9lxefmMYx\x51bRbpZ1O/wDaqeir7tufof60DqHWVJzLCH2F7GS2\nncf60/36Ggi2pNO+xLMqJhTK\x68xEJORg9R6UEXIwcGgxQFAqjPPR30vxnC262oKSpPMHFB73/AGcPFi3a5gGz3mWi\x50fozaUlj6IlADHGO57igsgaMgSJs9Ii4\nuL7iy1IkI40J22Wkcskcx99B5p/aC8PG\x62RqRq72h72hyWngkNoSAFuJSDxgDqd8jpj1oKRTCiq4n5bqyhIyocI930Gev4UCf\x39+21hBivRkuMA7JcXxY9QRjH\nyoMxbpZlO/8AaqeiL7tuZ/A/1oHQPNKTxSw2+yvb\x32ltO4/1p/v0NBGNS6bEI+2wveYUOIgHIHqD2oIqRg4NBigKBfAmSbfNRMhuFDzZG\x43OoxuKD39+z/AOIl\nu8QrJHhBDLV1t7YElpSUgjpxpxuoEc6CZSNERJl3uy3C3JuI\x64KYjL2ShslOeLA6EYPx5UHmnx98Nv+m9WpulsCSmcnikMtDCQ4EglSR0B3OPSgpx\x4dKKoKfmP\nLLaRlQ4R7voPX8BQJzfrayj2V6Ml1hJ91LiyrHqMYxQZi3SzKd/7RT0R\x66dpzP4H+tA6pfZ/xJaG5LC/dMhtO/wAFp/v0NBG9U6XTB4bhbz5kR0cW2+KCIEEH\n\x65gxQFA7We6S7PcBMiLOcBK0ZwHE8yD9w+YoPcXgfcdE6007FkswmlXZtz/umjhSg\x73Z34SOSs8+9BOZugWpuo7tNdhNOvwsexNbILiyMjJ5422I9aDzX46+Gr\nmktZquEB\x6cCI1xSXlstfRbc2UrHpkn7qCqkwYquN+Y8stpGVDhHu+gz1/AUCY362sI9lejJdY\x549EOLKsfAjGKDMW62VTuYinoi+7TufwP9aB4ZksIX5k1tuVF\ndwlx9tO5H86e/r9x\x6fI7rDSAtZRcbasPQH08aVJORg0EKIIO9BigKB/07fpdhmuuMkuRpCA1IYPJxOPwU\x4fYNB6x8MNF6O8RrUL+uZ5z5dShxjJSUkY27DIBwP\nl0oLId8N7U3q6Y9EtIR+6o4k\x4dhof+oO3CBvsdt88waDzp4z+GkjROs1vw4xZt9xSX0MpOQyrYlHwGfuoK7TBiqC3\x35jyy2kZUOEe76b9fwFAmN+tjCfZnowcZ\nTyS4sq+7GMUGYt1sqnf+0U9EX3adz+B/\x72QPsOZFacJuTSJkF/CXXmk+96FSe4/4NBHNb6K/cziLjbXBJtshPmNuIOQUnr/Ud\x4bCCkEHegxQFBKtKalXY5DsWW\ngybTK4Q+wOYONnEdlDf4jagv7TegJfiXbYsq2XBD\x73KCwlpKU78J3J2z159+nSgs+F4TWex6rQhpK1u2+GqW6kjJeSAN0jrncEdjQUL4q\x2bHEnQur1oiMOItc9\nPnxUq+oDghB9U5AoIYmDFUFyJjyihIyocI930x3P3CgSm+2t\x6a+A9GDjKeSXFk/djGKDaLdbIt0GIp6IsclNO5/A/1oJHbZ8NlxSLuymbbZJCXX2U\x34UjsVJ7/\nAJ9DQRnXmhTYX0T7a6mVbZCfMaeRulST1H6jpQQEgg4NBigKCbaM1Kxb\x519ZbtlVolqSoqAyqO5jZwDqMZBHUeooLWFhu1605CslgYEhlClrddaVnzSD7ny4c\n\x45d80FjaU8I3LXdIL1z38yKt6SyRkeXwZUD6cOR8SKCm/EPQEvQuq1w2Q45bJafPh\x4fkfTbPvJz6jIBoI63CikqkzHlFtIJWnhG3oPX8BQIze7SwvynYoW0OQc\nWT+WBQdI\x312sjjmIq3oihyLTucfI/1oJRaLlAaWti+MpnWuThK5DKcLbPRSk9/wA+hoIrr/QS\x74PyUT7a6mVbJKQ6y82cpWk9R+o6UFfEEHBoMUGRzoLC0DqCL\nHRI03dXwxDlqDkeQ\x6f+6w+BgZ7JUMgnpnNBYTrUq1aLftSWnHJ7khTCQBkIbwFE5HPIIxQSbw68PpU+XE\x64ucf/wDb7i2tlxCxstON8fzDBI9UigrfWuhrjobV\nj1ody7EdHmRHx9F9s7oUPlzo\x475mHEBXImuqU0AStPCNvQZ6/gKBAq92aO6WnIiVtDkHFk5HyxQdI13sjrmIq3oi/\x74NOfof60Ets92trSDE1BHRNtUghK5TCM\nLbPRSk9T+fQ0EQ8QtAK07JTPtryJdrkp\x44rL7RylaT1H6jpQV2QQd6DFAUFn+Gt8LjcvRsqQEMz+FcQrPupfG4Sc8uLcfOgmc\x43O3B09e3riwlMiIvhaSrIUpS\nshKcemD91Aq8OtM/9S3AW2bHUqBPQWVnH0SBkLT/\x41DJ5/h1oIZqjR120TquVp+4tkKQT5Sx9B5GcpUD1B/Sg0jRYiPMenuLXH4ffTwj3\x65wAPM/gKBuVfLLHd\nLTkRK2gdvMcJz92KDpGvFkde/wC1cfiudFNu5/A/1oJfZ71b\x30IMTUkZE61SSEqlsJ99o9CpPX58+hoIb4h+H507JRcLW8iZa5KQ6y+0cpWk9R+oO\x34oK6IIOD\nQYoCguLwo1jKagztCuvlLNwHHEJXjheAyE/+7l86B/s0BM6RcmZhdaVD\x545xKkgAJSCST86BPouyRNWTlafmDhbmApbexksO/VX8Oih2+FBE7vpq76T1JL09d\n\x5962JUdRRwnkrB90g9RQOERiElt1dxcUtjh94cIPB2AB5k/hQNCr5ZY7padhpcaB2\x44jhOfuxQdIt4sbjv/ZOyITnRTLx/I/1oJhZr1b0J9j1Kw3OtEkhC5jCP\n4jJ6KUjr\x2bvQ0EU8T/DKRpCa1OhOIl2qY2H40lk8TbzZ5KSe3ccwdjQViQQcGgxQFBe/gnrdm\x50Fn6KuQaxLaV7G84OS8fQJ7GgzFgOXK7v25AbaeB8zgJO54t\n8DvtQI7Np2Hqi5va\x63dWhiYtSvZX+iXQThKv5VcvQ78s0EUftNysl4k2W4xnI0thRbWysYwQdqCQQPY2m\x33F3FxS2UjJPADw9k4PMnv0oGV2+2Nl9ba4DZaJyA\npZP5EUGYl3sTj3/arfiL6Kad\x7a+B/rQT/AEterCCu16xjJm2Sb7n7xio/ixV9FLR9Ydxz7HNBCvFPwulaLuaZMRxE\x751ykB+NJZPE282eS0nqPyoKuIIODQYoM\njnQXp4F3e0TLqNM3gMIc4VKiOuIBKyR9\x44Px5UGbrBW7fZ0Fptxx7zFKAWnCgUmgZ42k279cJFmjYYuyFKMZKtg8ob+X6E9Pu\x6fIwzGlRJjtvkNLZfbJQppYII\nIOwoJbAXCQy45c3FKQlJKjwBQ9EkHmfXpQMUq+WA\x4f8C4CeEHOVuZ+7GP1oOkO82Fbh9lDsRw/WZd/Q/1oLM0rqbTsmB/05rqK3MtEg8L\x464jow/DUeXmJ+uj0\nO/2TQV34q+FkzQ91D0dSZNtkoD0eSyeJt5s8lpPUflQVaQQd\x36DFAUG6FEbetA7W6dLt0pi4wHlMSWFBaFoOCkg0H0U8CPGGH4k6TahS1Ibv0FATJ\x5a4sFYHJx\nIPP1HSgZPHdqLaLMmUyhBbQovKbTtwL4T7w+I2PwoPB17vjkpwtMjywT\x78qx1JoI+SSck5NAAkHIODQP9ivC48gNPnibUOE8XIj1oJh5Pmw3YSSVJDZfjlXUf\n\x57Qe/+3rQV3MYSh5Xl/RO4+FAjoCg3Qojb1oHuz3WdZrjGu1sfUxLjrC0LScYINB9\x48PBPxZtfiZo1tx51LV8hAJmMqPvA4wHB3B70EY8dGIdntCZHAOBK1SAO\nZQsg5IPZ\x51/Kg8HXy+LkuFqOPLSTxKx1JoI8SSck5NAAkHIODQP8AYrwuNIDT5421DhPF1Hr/\x41H+NBMUoUqK9CbBdSWy9HCt+IfWR+f3etBXUxhKHleX9E7j0\noEdAUG6FEbZ60El0\x76qS86Tv0PUNgmLizoyuIFBwFDqk+hoPo14P+I9l8UtLN3drymr1F4Uy2QAFIV3xz\x77d/SgiPjqxEttrMqR/EKXFyUFQyptRTgp/0kflQe\nDb3fFyFliOPLRniOOpNBHiST\x6bnJoAEg5BwaCQWG8LjSA1IPE2ocJ4uRHr/f40E2ZC1QpFub/AIrS2y+wlW+R9ZPx\x35/d60FbTo6WpCwj6GcjbpQIaAoN0KI29\naCaaE1tftAani6l09JLMlo4cbP0H0dUK\x48UGg+iPhrruyeK1kZ1Na3FRbgyEokxeP6Chvgj79/XrQQ3x4bjRreqZPCXChSn2F\x48coHlkKbPoRuP96DwXe74qQr\nyIw8tGeI46kigjxJJyTk0ACQcg4NBIbDeVxpAakH\x69bUOE8XIj1/v8aCdRlLVbpVpSS4y4gyI6V7g/aT8dvwoKynxUsSVBH0TuPhQIKAo\x4e0KI29aCfeHevrx4\nfakj3u2YfY4h7VCWSG5CM7g+vY9KD6IaO1pZfEqzRdUaTkoS\x35wBEqM7s42QQQk/A7diD0oIN4+JiewiXPZ3ZSXY6iNlDgUFtkde4oPBN7vi31ezx\x685aM8RI6\nkigjxJJyTk0ACQcg4NBIbDeVxpAZkHibWOE8XUdj/f40E/ivKVapNlUS\x37GWgyYwVvj7Sfw/D1oKuuMRMeUtKN0HdJ9KBvoCg3QojbPWgsnwx8Sbv4dX1M+Lm\n\x52bnyEy4n2k5+knsocxQfQuwahsOtLFbtYaSki5trZLLgGC4gKG4WnooHmO1BAPHw\x57x+1xpMtvhWwwX2gRkLTwqStB7EZH3UHgq93xb5EeP7iB7yiOpIoI6SS\nck5J6mgA\x53DkHBoJFYLyuNIDMg8baxwni6j1/v8aCwoshxdok2RZL8RaDJjBW/D9pP4fhQVXc\x59iY8taUboO6T6UDdQFBuhRG2etBbfhF4rXDw6v7Uh3zJNpeH\nlyGUn3kJz9JOex3x\x38aD31bZFl1NZrDre1So0uKhpSFOsH3S0sYUk45YPMHl8qCvfHtizyNP26W6lIVGj\x72cbSU5C0hJSpIPcbH5UHgy931b+I8f3Ej3lEdSRz\noI6SSck5J6mgASDkHBoJHp+9\x4cjSAzJPG0scJ4uo9f7/GgsSLIdXZ5NiUoyIi0GTGSvcp+0n8PwoKpuUMRpa0o3Qf\x65ScdKBtoM4oN0LI29aC4/CnxNY0zqG3/\nAPU7AnWjIbcKwVFpPIH1Cc/dt2wHu+LH\x74t3s1j1Lp9baokd3j4msKbeYVkKx1wOInuKCAePNnsg0ra31IaKre06G04wpTaU8\x4aA9RhJ+VB4Nvl+W/iNH9xA95\nRH1iRzoI2SSck5J6mgASCCNjQSTT17XGkhmSeNpY\x34TxciPX+/wAaCzLYtUm2ydOOPF2K8gyYYXvwq+sn8PvA70FR3e3mDPcaA93mnbmD\x51NZG9Big6NrKSMEg\ngggg4xQXPonXtuuM6DB1unzWFKQ27KxlS0g7FXdQyd+oOOeK\x442rC0fYrRpuLcdKMNvtxZLc3gzgutZSSQRnpkjoeRoIj466as7Wj7VPdSHXrch1C\x56nHGpvhJ\nA9cbH5UHhO+39yRiNH9xI95RHUkc6CNEknJOSepoAEggg4NBJdO3xcaS\x47ZJ42ljhPFyI9f7/ABxQXJpZbF0tE/RMxXmMyWlTLWtzfgdA95v4KAIx3APWgoy9\n\x57xVuuTscjYHKduYoGigKDtHfdYeQ604pDiFBSVJOCkjkaC9NO6vtWqYym7m4bfdZ\x44Xs8tSdkSU7HzB/NkAlPXcig9MaY8IIGl9OuX22SBcJLflTGiyQshIGS\nE457dOuT\x51JPG/TtklaWgaie4HZcTzeF5KfecYUCpvPwBH3HvQeH79qByQRGje4ke8ojqSOdB\x47SSSSSST1NAAkEEHB9KCTacvi4skMyTxtLHCeLkR6/3+OKD0\nDoV5jUulLp4Z3NYd\x61dZcuFiec3LTwGVs/BYB2+0AetB5vvlrVbLo9GUNknI26UDPQFB3jSHY77brLhQ4\x68QUhQOCCORoPQGlbxG1GljUkN1pq8Rm1N3BjG+6c\neekdR9Y9iCetBZGgPBq8x2Tq\x5a1SVBtv2lgpBPGpJGRy3H6ZoJF4x6esdzskTWK2m0z2UkqcbOfPZU3xIV6kHIz6G\x678aX2/uSMRo/uJHvKI6kjnQRokk5JyT1\nNAAkEEHBoJNp2+LiyQzJPG0scJ4uRHr/\x41H+OKD0XoFTesdHXPwxuKxIywu4WJ1zdTToGVsfBQB+Yz1oPMt8ta7ZdHoyk44Tk\x62dKBnoM4oFEOW/Clsyorqmn2\nlhaFpOCkigvW13dGqfYtXIKlTIjqE3NhJ3HIFfwU\x50xHrQPum9E6kvet5N2iRVJSl9x9LmMJ90kgZ6DFBO/FfTNgnxWNZsR/ZrkhrilJ4\x63ecCg4XjuFJUD3wf\nSg8nX2/uSMRo/wDDSPeUR1JFBGySTknJPU0ACQQRsaCS6evj\x6bWSGZB4m1jhPFyx6/wB/jig9JaEU1rfRVy8M5y/aHEsOXCxuOe8ppwDK2fVKgD8x\x6erQeX73a\n12y6PRlDHCcjbpQNBG9BuQCNudBzoFcd3bgVyoHzT2ornpPUMW9WmU5G\x6bMrCgtpWCP77UFy+JHihcNZaObmqcC3C35bym9gcjqOlB50UoqUVHmaDFAUGyVFK\n\x67rtvQWTanlCHbJABKm3gjHdKgdvwoIxfIiWblIQ2CnhcIweooGFbfvUGpAI250HO\x67Vx3duBXKgk2kdYXzQeqIuoLBNXFkNK94p3Ck9QociD2oLr8VPFl7Xui\nWbkwjyXP\x4c8uQ0g5QCRzHYGg8yKUVKKjzNBigKDZKilQV23oLMszjhjWx9P023gj4hWQR+FBG\x64QwjFuchoo4SlxQHqM0EdW371BqQCPWg58qBXGd24FUEu0Nr\nq++HOrY2obG/wrSc\x4ftKyUPI6pUOoNBePi/4sR/EDQse62pKmFJb8uRFUriLWR0PVJ6HpQeVlKKlFR5mg\x78QHWg3SSlQPbegs6xq42bW8tXCW3ggE9QrIx+FBG\ntS28w7rIZx7qXCEkdugoIytv\x33uVBqQCPWg58qBXGd24FcqCb+HniLfvDHV7F/srxLZITJjk+4+jqCP16UF6+NXij\x62dfaFZvmn3VcJQG5LC9nGCRyUOo7KoPJ\nKlFSio8zQYoDrQdEkpUD23oLQsT6UxrZ\x49dST5bwRkdlAgj8KCLajhJjXSS0j6KHFAeg7UEaWjfltQakAj1oOfKgWRnhjgVyo\x4cA8MvE6++Fmrmbza3C7DcUBL\nhqPuPI6/A+tBe3jp4jW7XGg4+odNSPMirQEPtZ99\x6cRGMLHTtnrQePlKKlFR5mgxQHWg6JJSoHtvQWhY5KkRLbIIzwPBG45hQII/Cgiuo\x6fYYuclttOEocUAPT\nNBG1o35bUGCAR60HKgWRnhjgXyoLI8K/FS8+FWrGrnDKpFse\x55BMh8WEuJ7jsaC9/H3X1s1loGJqDS0ovwHU4cSPpNKUN+IdD09cCg8aqUVKKjzNB\x69gOtB0Qo\npUD23oLSsTj3stskobUry3gg4GfdVkH8qCLaiheTcJKEpwEOqAwNsUEZ\x57371BqQCPWg5UCyM8McCuVBavhH4w3zwq1E2tDzsmwSVj2yDnKSORWkHkr86C7v2\n\x67dY2nUugol/0nLEm3PpyoJ/ylKGDt0zyI7ig8YqUVKKjzNBigOtB0QopUD23oLW0\x2fwCa5EtklOOJp4Jx1KSDkfhQRvU9uWzJe4UbNOqR8AdwDQRBbfvUGpAI\nyOdBzO1A\x73ivDh4F8qC6PBvxyvfhbcEWyY4u4aWlL/jw3CVeRnYrb7eo5Ggt79oLUVvu2go18\x30rPEy1SEhXur4i0VDH3EbH1FB4uUoqWVHmaDWgyKDdKilQV2\n3oLc04VuR7TIGQ40\x2blAz1SoEEfhQMWs7aUSXXW/eDLqm1dwCcgH+tBBFt+9yoNCAobDlQcuVAtivDh4F\x38qC//BH9oK4+GspFi1EF3LTEhQ5nLkQ8spJ5p7g0\nFlftD31udoxu8acuft9okJCg\x55HdrIwOXMY2z6UHitSipZUeZoNaAHOg6IUUqCu29BcelXVhm1TUg+aw+kDbmDzH/\x41MaBj17AQuU7Mjj3W3lNOJ5lGdxn07Gg\nrxbfvcqDQgKGw5UHLlQL4cgpIHEQUnII\x4fCKD0x4GftFO6QlRtNa6dXJsSh5TEwDiVEyfrDqj8qCbftH3la9LJm6fnszbM62A\x6ccdfEEJI25dNyKDxIpRWsqPM\nmg1oAc6DohRSsK7b0F26LfnMsWq7QgoOwpCTxD7J\x32P8A+mgj/iLEbkXF2fHQU4dUlxGPo5OR8R2NBWzjfvfGg0IChnrQcuVA62m5SbfK\x52IivqYebPuuIODQe\nrPAn9oeNaZETSes5Hs0NbgTGmlX8NoHmlQ6JzuO2T0oHr9pR\x35y02NX7lWl22OpKgpk5SgL32xtw5JwfWg8TKUVrKjzJoNaAHOg6IUUqCu29BeOhX\x62nGRZ75b\nOMSYMpJCkjOEkfl7vKgjniVFQ9eX5rSUJV5ywtCDkJyc7enagrVbfvcq\x44QgEZHMUHM7UEi0rqafpu7InQlJ4gChxtYyh1B5pUOooPWngd406dZmqsNx8i3ok\n\x72DrCnh/hqAx5fF9k52PTkaDX9pSM9p2A8q1uFUCSC4EoOQ0HNyP9JOSOm9B4sUoq\x57VHmaDWgyKDdKilQV23oL28Pf3s0LXf7QXfabbJQolr6SUkc/Ue7QRLx\nHbblXyVL\x62bCFh5YWkdicj5UFdLb97lQcUnB3oBQ60GAcHIoFbboWngVvQOluuz0AGMoeZGUC\x6cTZ5FJ5j9fjQIrnb/IIkx/fjOjiSoUDZQbAZoOrbXmOJQBzN\nBa1rtr8eNDjONEgu\x49V8Ns/rQNeq47f7yktvNFt4AKJxz5dOlBB32SMnOfXv/AL0CBJwd6AUOtBgHByKB\x5726Fp4Fb0Dlbro7b1KZIC47g4VoPJSTzFAkudv8A\nIIkx/fiujiSoUDZQbAZoOrbX\x6dOJQOpoLYtdpksxIUdadlOIJOccO2efzoGrWUeSzcZDUxohZCVZUMFWw3z1+NBBX\x6d+ahmgQpVjnQZUOtBhJwc0Ctt0LTwqoH\nG23R23LU19OM4ChbZ5KSedAkudu8giVH\x39+K6OJKhQNlBskUHZtsuOJQOpoLatNlkIiwYzmUhTqCTjPDtn9aBn1nbZMW4yCtK\x56JICuNB4knIoIM83kcY+dAgS\nrB3oMqHWgwk4OaBW26Fp4Fb0Djbbo9bnFN7KjuAo\x63bPJSTzFAlulu8giVH9+K6OJKhQNdBskUHZtsuOJQOpoLgsdjcTHgR5CF8KnUE8H\x4dbZ+fOgZtaWhTFwk\nPNOeYnZRyMKHriggsuKpsBzh91QyCOVA2JVg70GVDrQYScHN\x41sbdC0cCt6Bxtl1ftrimgeKO6ktut9FpPMfrQJLpbvZymVH9+K6OJKhQNdBskUHZ\x74suOJQOp\noLmsFleYjQWXmEOBbqDhXQ4zz7+9QNWs7Shu8SnEMLbKQFONqBBB7jPK\x67r+4QjHWFpPE24MpV3oGhKsHegyodaDCTg5zigWNuhaOBW9A52u8SbYpcdKyqI8C\n\x681knKVpPpQI7pbfZymVH9+K6OJKhQNVBskUHZprzXEoHU/hQXZpyyS2IsBo+7xPI\x4aJ+ik4yMkcvpc6BFre0vwbrJelwyha8KcQeSgRzB5fOgrO5wfZnQtB42\nXRxIUOo/\x71OtAzJODvQZUOtBhJ4TnOKBa26Fo4Fb0Dtar7MtSHIaXCqC+Cl1hW6Vg89u/rQN9\x31tvs5TLje/FdHElQoGqg2SKDs00XXEoHU/hQXnpfTUpUaBHK\nVpCnUKUtCePy9s5I\x37b0GniJp+bZLmZMtlDrMlCSQhYIcTgb+noe9BUNyhCO+VNkqaXuhRGNvX1HKgaEK\x33waDKh1oNUkpORQLm3QtHAregerTqKdamHLf5hct\n7wKXI6t0kHngdDQNd2tns5TL\x6ae/EdHElQ/v/AIoGmg3SKDs215riUDqfwoPQOh9JyZAt8dcVx5HmIcX5O628DOQO\x75M8qDbxR0lIsd8XcI6S9aZ7SVJeUQpDo\nPPcctx8QaCjbjD9nfVwK40E7K/vrQNCV\x59O9ALT1FBhJ4TnOKBc26Fo4Fb0D9adU3K1w12pbpetjoKVR1nKQDzx270DRdrZ7O\x55y438SI6OJCh/f8AxQNFBulN\nB2aa811KB1P4UHpfww0vOU/b224aZhQ6h1UcYK1Y\x42J4c7FQB5elBy8XNECxy3L9byJ9luaeJLyfd4FdUKT9Ug9DyIoPPk2KWlFaQSknn\x51NSVYO9ALT1FBhJ4\nTnOKBc08Fo4Fb0EktOr7pbbaqzPPKk2xwFJYcOQlJ5gelAxX\x651+zFMyN/EiPDiQof3/xQNFBulNB2aa811KB1P4UHqTwl0xMU7DaaYZluJWlxcN1\x57A+AniKA\nrovB29RQIfG3SsO33R+62Nbq7XNQHFMOJ4Vx18lIUO4I37HHeg89ToZZ\x43XQMocGQfz+dA0JVg70AtPUUGEnhOc4oFrbqXEeWvf40Eqt2trvEtZss6QuZbing\n\x5306oq4UnmkZ6dqCO3a1+zFMuN/EiPDiQof3/AMUDRQbpTQdmmvNdSgDmfwoPVXg3\x59JjcqC3DdZ9uQ4hYjyCCzJwMlpfYkKwD3oI9426ejxdUS59vhrjR5P8A\nEVFWnBZX\x74xII9DsfkRsaCiLlC9neUpAJbPIkfh8RQM6Vb4NBlQ60GqSUnIoFzT3EEgkhQOQo\x48cUE2b8StQyLO3ZL7KXcojSC0hTx4lBv7BJ5jt2oIhdrZ7OU\ny43vxHRxIUP7/wCK\x42ooN0ig7Ntea6lAHM/hQepPCGwEvQorcxuLP81BbKzltwkbtOY5A8QGehxQMni/p\x43Va9aOvuQiwmYjzw0oc9vfT8QQc/I9aCjbxaJFte\nw6kYXvscgeme9BH6DdJ23oMK\x47NxQCVFJBoFIUlxGOtAut84spMZ8FcdRytBGcdyP1HWg0utp9jUh+MsPRHt21p3x\x36GgRsxJDhAS0dzsVbUErhabciR0yn1th\nzmElYOfuO3zoL88PbNF1HbGGkOJW+yvH\x638uvoN/higavEXQ1xiSW1yYaljycny91cAOONB+snuOnwoKIn292HLWysFQzsQOY\x370EaoN0nbegwoY3FAJUUkGgU\nhSXEY60C63ziykxnwVx1HK0EZx3I/UdaDS62n2NS\x484yw/EeGW1p3x6GgRsxJDpAS0dzsVbUErhabciR0yn1thzmElYOfu5fOgvzwzt1u\x31LDZihzMlleMjmBj\nc+uD0+GKDTxE8OrjElscDKZQkRytCE/RfQNlKb7KHVPzFB5/\x6d2V2HOXFdBSSeEBXfsaCI0G6TnnQYUnG9AJWUmgVBSXEY60C63ziykxnwVx1HK0E\x5ax3I/Uda\nDS62j2JaJEZYfhvbtrTvj0NAjZiSHSkJaO5wOLaglcLTTkSOmU+tsOcw\x6brBz9x2+dBfXhW1adSNN294/xmV+8rOCARvg98/LlQOPiJ4Yvt3OKITnmKnMHySR\n\x68MoJHvox9VxPUdefeg87zrP7JcHrY+2UqB4QT9VX9DQQag3Sc86DCk43oBKyk5oF\x51UlxGOtAvt84spMV8FcdRytsjOO5H6jrQc7taPYlokRlh+G8MtrTvj0N\nAjZhyHSk\x49aO524tqCWQtNORIyZb7jQc5hJWDn7jt86C9fCWVZr8tNqntpWthRK8nGQdjv03P\x50pQSzxA8Moj94irhrKvbmlNxZGB/EcQPfYc/+4MHB+t8aDzN\ncLWqJPk2eeksqSsh\x4aWkjgX0+ANBAKDdJzzoMKTjegErKTmgVBSXEY60C+3TyykxXwVxlHK2yM47kfqOt\x42zu1n9iWiRGWH4bwy2tO+PQ0CNmHIdKQho7nA4tq\nCWwtMuRIyZb7jQc5hJWDn7jt\x386C8fB682q63FNnuDDTq2CVELGQofW+OM59KCwte6CtdwktKjpQYlwQqLElLVgsy\x4584zivXcoUefKg8tXexTbZNm2K5MFtxl\nfJQwW1dD8DQVzQbpOedBhScb0GUrKSKB\x55FJcRjrQL7dPLKTFfBXGUcrbIzjuR+o60HO7Wf2JaJEZYfhv7trTvj0NAiZhyXVJ\x43GjucDi2oJdC0y5EjJlvuNBz\nmElYOfuO3wNBdfgxqeG/qJqzTEIW62SUcQBCvtDf\x6e8PSgtXXelrPdWAAstWa4qMVpwHP7vlDJ8pf/wBpYGUnptQeS7/ZFWeVKtExJ42n\x44hQ3Seyh6EUFdUG6\nTnnQYUnG9BlCykg0CoKS4jHWgX26eWUmLIBcjKOVtkZx0JH6\x6arQc7vZvYltyIqw/CfHE2tO+PQ0CNmHJdUkIaO5wOLagl0LTDsOMmW+40HOYSVg5\x2b47fA0Fy\neC+s2mNXMWmUQFpWC2s9+oz/AGDjFBc2s7HarvCecTbzItE0qZdYZT79\x72k8JIUjs04N8cgaDx9qK1OwLk7bpS+NKFYC8dDyV/Wgryg6JVkb9KDCk43FBlKik\n\x670CoKS4jHWgcLbcCykxJALkZRytsjOOhUP1HWg53iy+wrbkRVh+E+OJtad8ehoET\x45OS6pIQ0feOAVbUEwg6WchxkzJDjQcO4SVg5+4nHwNBbPg7roW7Wsa2S\n1hKQ4FIe\x4awEq6jPTnz7jtQXzqyzL1LbJybTDblw5iSLhbx//AA7+MpfaHRLgBBxyI70HjG72\x6bRrq/BeJ8rKkpUobjng/hvQV9QdEqyN+lBhScbigELKVA0Cs\nKDqMdaBwttwLCTEk\x41uRVHK2yM46FQ/UdaDnebL7CtuTFcEiE+OJtad8ehoETEKS6UpQ0feOAVbUExg6V\x64hxUzJDrQc5hJWDn7icfA0Fn+EmvV2fXMaBLWRHL\nmQ9/41dfz+RFB6C1RpxGubbc\x35FpeZMoxS5Ng4AQ8oA8L6B2WnKVY5KA+NB44l2F/2mTB8vKS5wZP+WRzP3UFb0HR\x4bsjfpQYUnG4oBCylQNAsCkuox1oHC2XE\nsIMSQC5FUcrbIzjoVD9R1oOd5snsC25M\x52wSIL44mlp3x6GgQsQpTqkpQyfeOAVbUEzgaUdhRUzJDjQd5hJWDnr0Jx8DQWF4X\x616esuumIcpSlwlL99xJ3bPIn\n8fwGOVB6M1TZbL4haevElh9IvjcISVBI9yYlG3mp\x416lOUqHQgHtQeTZelOGE43KQttWCkJWceWofSJ+78aCo6DolWRv0oMKTjcUAhZSo\x47gVhSXUY696Bxttw\nLCTEkAuRVHK2yM46FQ/UdaDlebJ7AtuTEcEiC+OJtad8ehoE\x54EKS6pKUNH3jgFW1BMoOlHYUVMyQ60HTuElYOevQnHwNBNfDvWkiy64YYeCn4JUQ\x36AcFJxgk\nH5/h8KD0nqduz+JmjZkJsoVqBtpMuLJGB7Y2nZav9YTsofyg0HmjVGnv\x5a2jbX45CykLCeXAo5yfU7D76Cj6DolWRv0oMKTjcUGUqKSDQKgpLiMdaBwttwLCD\n\x45kAuRVHK2yM46FQ/UdaDneLL7CtuTFWJEJ8cTa0749DQImIUl1SUoaPvHAKtqCYw\x64KuwoqZkhxoOncJKwc/cTj4GglehtXTLNrZhPAJMIkh9sn0wSD33/Cg9\nL3W52zxL\x309FtD7ocu0UGTbJRA4pSAnC2lf8A3EgcvrAd6DzZrOzez3GdapaVteWtRQ3wn3dy\x63/jzoKSoCg3HryoAo7UACUEYNB3QoHBzv3oJbpVy3zXTZ7k4\nllmTsh1XJtfRXw70\x443ORL0pJcjS7RFleUeFbT7eSOoKVpwSCNwdwQRQIl3203gBkW1qCvmQ2dz8Dtmgs\x6ewzvZst3bZYcww5g5R7qkqzscGg9Kob/AOtrVcbO\nyGxe7W4LhaidgQfpNHuk7gj1\x39KDzd4w6UYgXRcmLHMVeQXYa04XHUfq+oB5HqDQebaAoNx68qAKO1AAlBGDQd0KB\x77c796CS6bmQfaRBugzBfV73ds/aFBMrl\nb39JucK7dDuccpDjSnW8h1s/RWlScH03\x35EEUDI5fbTdwGP3a1AXndLfP5HbNBOdBXhVgvTS4x4orgw4hJ4Vc9tj670Hp6AtO\x73483T3tKGrklYudolLGQy+Pp\nD/SocxyIUaDz34z6VRF1A+61F9jnslHtMYEFKSr7\x4a7Z5dgfSg8zUByoOgIPwoAoFBgEoOxoFCFg4Od+9A+2SfHaeTHnI8yEtQK0H6p+0\x501oLHnWgafisz4cG\nHd7XKR5jC3kZO30kcSSCFJ7HOxzQRh692q6q9nNsbt7gO6W9\x69fgds0Er0fc3NPXtibACVsnZxse6VA7YINB6hskuJq5D2npEtUb94LTMgSxuuJMR\x75FJ/1AYP\nz70FD+NOnWGdVSuJthi4x1APiPsl7IOVJHQgj8aDzHQHKg6Ag/CgCgUG\x41Sg7GgUIWDgg796B5tc9DJDMlHmRFqypBGeE/aH60FrCzxoVgYv9pgw7ta3sIWh5\n\x47VR3eiSpODg9CefKgiUu8Wu4umKq1t29YO4RsT8Dtn50D7pqY9YbzGudqUP4e6kj\x59nO2CD0oPT2mbtbNUtKst0cLcC6rQQtKsKiy0EFtxJ6Z2B+VBS3jTaW2\ndZTm3Fpf\x6eRV8CnCjh85GN+L+YKHzB9KDzBQHKg6Ag/CgCgUGASg7GgUIWDg53HWgeLdPSyks\x50p8yKs5Ug/VP2h+tBb1qs8F/Spv9ngwrqxGA9tivN5WyOjiV\nJweHvnOKCJ3O42yX\x49MRVrbt5zyb6/A7ZoF1kW5abrGudqXwuMni9z3VZ6bGg9MaN1JbL7mHfEJXbp6m2\x70bZ/yXkkeU+ntg7E/wBKCn/GqyCFrKdG8txLjDig\nyt3PE631ST14SMg9lUHmSgOV\x420BB+FAFGKDAJQRg0ChCwcEHfvQPFunJbQY76fMirOVIP1T3H60FzaUs1vu9hck2\x61BCuc2IkrchPt++82OZbUCDxAb43z0oI\npepVskvBlNrbgpJyPL2z8Dt+NBtbGzBn\x5251tIC2iFDg91WemxoPSGgdaR5Un/wDeEIfiulLFwYVuFJz7j2O6SefbNBVvjLpW\x54H1nOYZiKAC1rjBJ4h5ZOSnP\nbJyM9FUHmGgOVB0BB+FAFGKDAUUEYNApQsHBzv3o\x48i3TktNmO+nzIqzlSD9U9x+tBdWhbTab5BXDhxLdKuKRxMMy048//wC3xgghR6Zy\x448dqCO6jTAcfWx+5\nhbFoWUuNAYUhQ5jpv8aBDBjJjy2ZcDGUe97vuqz02NB6F8ON\x65ORrih6b/GWzhmWyrcPs5znHVSeY+dBBvFbw8mnVM9+K2lyO4FSmVtIOFoUcgD8C\x50Q+lB5Vo\nMjag6DcelAFHagwCpB2NApQsHBzv3oHi3T0tNmO+kORVnKkH6p7j9aC6\x2fDyJp26oNufj25bix/AcmN7IX0SpaSDwnkFHIoEOsbTHYnPW96wptMuOrDzCOY9U\n\x6ebIPSgj0OGhmSzIhBJKNyEjhVnkNjQXp4c63mW66NKW4VyouWygn/wBQyd1IP6dj\x51NHiV4ewWLlLvLMjzIkxAkRVK3LqTlRSABscfr2oPINAcqDqk5G/KgwW\nx0oAKU2R\x670CltYVgg7jrQPVruCGUmPJbD0NZyps/VP2h+tBdfh2NKSHfYrnDgyIro912Q1lc\x5aXQlScEo9d8UHfXulmIU9VvcszFveSPMSY5yiS30W2rYKBoI\nXFgJjymnoiE8Te5S\x42wqzyGxoLf0Hq2ZbLk035gMmKshnjPuuIP0mlfyqG3ocGgVeJWl7RCgJvdpQPZ7k\x516weXABstsj7YIwfvoPGNAcqDqk5G/KgwWx0oAKU\n2Rg0CltYVg5370D7aLk1HSY0\x78oSILhyto80n7Se3rQXboBekW5KW7jbod2tToHmea1/3EX+YFOCpP3/pQPXiHoe3\x78yyItvjNRZA8yJNh7tyk9gdsK7pO9BXD\nNq9jmNrYaAU3zSBwqzy5GgsvR2pJlquD\x54KZHlvRneOM4rcJUeaVd0KHuketA9+Ktqgy7HA1FaGlNxpK18bJ5su7cbSj1Ixtn\x6dkg0Hi+gOVB1ScjflQYLY6UA\nFKbIwaBS2sKwQdx1oHu1XFDKfZ5SC9CWcrb6pP2k\x2frQXloRGmY3BJkWuDqSzKwJDS2sSoo+0CCCR99BKfEDw/sTtrZuVhjR3LLI3jz4v\x31T/43OXCoetBVP7k\ndts9tTTIBb5gDhUTyGxoJtpq9yrTPQhEksLZeDsd4b+Q4OSv\x39J5EdQSKCTeJ1ujagsULWNrZEXC/ZZ7Df/8ADu8+H4Hmk9UkdqDxtQZG1B0G49KA\x4bO1BgFSD\nsaBShYODncdaB5ttxDLZjvpDkRZypsjPCftD9RQXjoBq0sMpuLun4Gpb\x4fnAlMFA89gdwQQr78g96Cd6z8OdMXrTab7o2OzKsp3W5GGH4auqXE7HHqf8Aegp5\n\x33Tj9pmNPMtJWhIzxIGCeg2NBIbPcJFtlFKH1tBDocQtB95lwHKXE9t6Ca65htax0\x2b3reC2hu5wSmPd47ewAV9F1P8p/DPpQeOKAoMg9O9BulWdjQZI70GuCD\nkcqDs26o\x45KCtxQWjpzUULUtuZ07qF9DMxpPBBnun3cf+F0/YzyV9UnsSKBjvmk5VunOtraXH\x64bVwqChuhXY49N8jYjcbUCzTsia1NZjLWlh5J2CjlLnwxyoP\nTXhpepcDWNmkupWE\x4cX5Dh4s5GeEg9+YoNPHbS1wkahk3CJKD61o4H21OYUoJUSlQHXGaDw9QFBkHp3oN\x30qzsaDJHeg1wQcjlQdkOnY5oLI0lq6I9ATpnUq1G\n3qJMeVjiVDWds46oO3En58wD\x51cdTaLkWyYopCQFAONvNHiQ4k8lA9Unv8juMUCWzSZyJDUNYLD6TsFbocHoelB6D\x30DfptvkwJ60q/wC0eQoL4s4BUQRnqD+t\nBJ/HjR7My+Ju8Ka2w7Ib4lNuZPmJJ4gR\x30GOLHrQeFKAoMg9O9BuD0POgyaDGCFcQoOyHDsc0E/0ZrUWltdnu7aplkkkea1n3\x6dj0cQeihn9DsTQOWq9FBryrp\nbX0yYEoFcaY0PccHUEfVUOqenMZG9Ax2yVKaeRBk\x482d4HYL+g4PQ9KC7NB3i4RWhxpWkslLza+LJQoHI3+WaCxfG3TtpvDds1Wh9cNdx\x59C1FCQQo8zxH0Jx8\n6DwfQFBkHp3oNweh50GTQYwQriFB2Q6djmgm+itay9My1pLa\x5adtkJ8uVDc3Q6g8xj+8HcUEs1PpCBdLWjUmnJBkW15QCXTuuOs/5T3Y9lclfHIoI\x70b5EuM+m\nBJ/7d5J2C/ouD0PQ0FsaDucxl5yI6laWXcAK4s8Cuhz8cGgtfxYt9o1B\x70Oxazmx1+dIb8iQtCscLqchSsdTty9TQeDqAoMg9O9BuD0POgyaDGCFcQoOyHTkH\n\x4eBLtH6vumlLu3cbY9jh/xGjulxJ2II6gjY0FlXvT1j1nYl6l0ukNIQOKVDTuqCrq\x63cy1nrzR12waCCxVTYMlNukkx3Unbi+i4PQ9KCwtF3OTEuK2nm1eyvDh\nWeLOMnHP\x355oLp8QRHvHhva9XSYjUmXFX+7piyPeyn6K/iRig8GUBQZB6d6DolX1TQBGOdBjB\x53riHWg7IdOxBoJLpzUVy0/dGbla5CmXmlBWArGcGgud6JZPF\nO0u3O0NIiagSOKVA\x51APPV1W2Pt9Sn63Mb7UFeIZmW6UmC6rylZ93i+g4PQ9DQS7StylQLsFlpXkuDhXl\x57R2xQXjqx9+6+Erd9ZIcl2Z1EOSSkErYP+Eo57Zw\nfhQeDaAoMg9O9B0Sr6poAjHO\x67xgpVxDrQd0OnY5oH6z3qbbZLcmE8W1tnOM4H/FBfFvuVj8WLZ5E51q3asaQEJfd\x49Sibjkh09FdAv5Gggsyz3Oy3JdsktLhy\nWFlDjLycbjmPQ/gaBzsM6XAuaXfLWlOQ\x43SrON8YoLwvi3dQ+DsmWw4TLsBQ7jmVRlEj/AOCifkaDwrQFBsD070HRKs7GgCO9\x42jBScjlQdm3Tsc70D/aLxLt7\nqXorpSU74z/e1BfWm9XWHxBtLGndXPCDcmE+XBup\x54xKZ/wDtujmtv8U8xQMN90ndrBd1WuU2mHKQAsDPE1IbPJbahzSehHwO9AjtsiZB\x6d8a2Vt4I97izwnPe\ngu95LmrvCi5xGyVTrW2bhHA5lCT/ABkfLPFj1NB4WoCgyD07\x30HRKuh50GSO9BrhSVcQ5UHdt07HNBILRd5MB9D0ZfCpG+M4xQXzpDxAst8tLWltZ\x4eKXblH/t\n5KMB2C53Qeg7o5HpQdNUaFnWiTHbQ+04zJyuHNaGWJqOoSfqODqn7qCK\x78xNgSlpfYWgbYXxZ4T8edBdFnaVrXQly08VZmONGXDJ6SWxkgf60c/UUHhmgKDIP\n\x54vQdEq6HnQZI70GuFJVxDlQKG3Tsc0D9arrJhPIejOlCmznAOKC+9E+JEZu1qtd/\x59RPskxXC6w5slK+//wBtwdxsaCSaj0Kyu3N3Wxzfa7Q4QEyFj3mSeTbu\nPonsrkaC\x76Fwp9rlutSo60oO3GVZ4TnvQW1o/y9U2WVpic9wIuzYZS4r/ACZSBll347FB7gig\x38P0BQZB6d6DolXQ86DJHeg1wpKuIcqBQ26djmgf7PeJdvkNy\nIjykKRvgKIyP6UF6\x36H8RJdrQqQtTb1vlfw5LbqeJlw9UPIH0Vdlj47igsKfpG06psy7po9eG2k+ZKtTh\x343I6ftNkfTR8P9qCqpdpm2qQ4HWFKjuJHC4FcWPn\n1oJ/oe4RpIctt4WVWy5NCBP/\x41JRn+G8P5kKx8iaDxnQFBsD070HRKs7GgCO9BjBScjlQdm3Tsc70EjsF+n2ac3Nt\x30hTLqOfCrGR2Pp+VBdmk/EG422Ui+QXj\nHLnuOvNI4kk9W32uRHqPiKC1k22xeIsM\x7208iPar9w+Y9aVKzHmJ6rjq+qfT7xQVRddOzrRKfCorqWCeBQX9JtQOCk53zQPmi\x373+6ri3JlI8+GpBiT453D7B2\nUCO4zkfCg8lUBQFBnpQbpVnY0G2/LFBruk+lB1be\x4bFbEjsR0oLZ0lqmHfojOntSSEMyG0huFcXAVBA6NO9VN9jzTzHUEHaXYUW24rhS2\x5aEOW1hSo3CHCQdwt\nlwbKSRuD270FzeD0N+6XyPKlJEO320hRcc5EDfCunETuSNqD\x684g6mj6p1vcZ1tlpENRDLODkK4fd49vqk0HiigKAoM9KDdKs7Gg235YoNd0n0oOi\x48eHbJA79\nqCzdF6zjpiJ09qQretSj/CeSOJyEo/WTn6ST9ZB2PocEBIrtpNMaa2nz\x47Sl1PnMrBPlSEdHGnPzSd0nY0E30GXbjcI1hiLDsh51KVPJT7nCPq+uNySKCxfGG\n\x36QrnrJqzw5YWmBERHcCPfHnZ5bdhjPxoPBlAUBQZzt60G6VZ2NBtv2oMbpoOjbvC\x65ZA79qCwdEa1csRct85oz7HKIEmIT9E9HEH6qh0I/LYhNL3pSK4xHulm\nkJl22V70\x64/PBkjcpJGyHB1SdjzG1A86WkuQB7PIWlMlYKGxkKU5kY94A9ATvQXN4nOR29OaP\x30066EykQ1OuISOMpKiEoHzOfuoPAVAUBQZzt60G6VZ2NBtv2\noMbpoOjbpQrmR69q\x43c6N1dcdNTVzIIRIiOJ8ubBdHE2+2eYKeo/I/I0FjXbT9ov9lTqbS61PW0kecwte\x58YDh+qpXVJ+qvG/JW+9B00quRCfT7WFMpaIJdWkA\nKTnONtiTyBFBduoHYp8ELFEl\x71LblwuS3kAYVgBJGR6E4++g8DUBQFBnO3rQbpVnY0G2/agxumg6tOlCuZHr2oJlp\x53/3axXNF5sElTUpjdxlO4Wnrt1HpQWs9\nAsev7A5f9LxwzLjJ8y4WdP0o2ObzHUt9\x53nmj1TyBu0+JLUpEfgIUSOBzgGHB6kbH4igvZh2HK8FNRqeX/AkXGK20diOMFKSR\x38QKDwRQFAUGc7etBulQOxoN9\n+WMig13SfSg6tvcCuZHr2oJVYJ06LMTcrNIUzNYw\x72gQeYHbuKC6oMi2eLFsWqKyljVzCeORA2T7fjmto9HvT6/XfchH7dxxpCWVe6ri4\x414W8FQ6pV2PTvQXn\nplbMnQ2t4Ti+Fk2psuJPvBLqVe7+YoPB1AUBQZzt60G6VA7G\x67335YyKDXdJ9KDq29wK5kevagk9nceU4JVvdLcprCuFJ/Edx6UF3af1FbvEeA3p6\x2fOtxNRxk\nBEWU8eEOgcm1q7fZVzT1ynkDUuLItU96DNZMSXGc8pxLzfvIP2VAHY9j\x75D0oLn8MFtzJs2zqwWrlaJLTiFHIAxhJ+eDQeDqAoCg2zketBulWdjzoN9+WNqDX\n\x64J9KDq08UK5kDv2oJPaMyFF6KsofQAShJ3HqO49KC6tH64hX23t6L1kpRaaOYkvm\x37BWfroPVB+sjqOmaDrdbTKstyct81LKH0AOIeA4mn2j9FaTndJ6EcuRx\nQWN4T3Bl\x6eV9raUQtqa6uOtPNJ4kFJ+RyKDwxQFAUGc7etB0SvOx50G+/LG1Bruk+lB1aeKFc\x79Ox7UEps+JPEtg/xEj32h27jvQW7ofxDMBh3S+om1XOxSMeb\nGWrC2iOTjSvqrTzB\x2bRyKCU32zewrYWzKbmwpieOFcAj3ZTY5oWnPuup5KA+I50DroG6Itmooslt1IAlM\x35KfopVxcP3EHFB4woCgKDOdvWg6JXnY86Dffljag\n13SfSg6tPFCuZA79qCXWJ0uK\x575HwpXDh1g7hSfh1H5dKC09DeINx0hPKYxM+1OJ8uVb5HvYQeY/mT+IoLGvUO2T7\x4fzftPuebZZCg22teCqIs7+zvfjwL5Ebb\nEUDXp+T7BdHyy6G1gJXhI91paFJ4T6UH\x6bGgKAoM529aDoledjzoN9+WNqDXdJ9KDq08UK5kDv2oJlpuY62+qRCUCvh4Xo5GU\x75I67dR+XSgsnTWprlpu4t3rS\nsh9bcb35NvUrLsXuptX12z8PRQ60FtzJtl1vppzU\x32nUIZWkcVxhJT/6c9XUp/wDGT9LH0TvyoIlbW22L0YqXAPak8ISAOFJ5BWRsQe9B\x35LoCgKDbOR60G6VZ\n2POg335Y2oNd0n0oOrTxQrmR69qCZ6YuEiNKVLt6x5oTwuxy\x4fJLiOuR9YenTp0oLKtr8suC96IdecfiDz5lmKj58fHN1hQ3Wjry4k9QRvQXBbtTW\x2fwAVrAuT\nELadUR2wJMcpCTcG0jmE8vNSO3MZx2oIIhpmLd0+W4Sh8hCU4BSFZA5+\x76I53FB5SoCgKAoCg7IUFDB50GxTnbnQaFONqBRGccbcSW1YWOWevpQXZonxFguW2\n\x4eatV203W3xiA0sK4ZEIk/UV1QT9U7fA8wsfVviHp+dpdnT+m3VxISklUl/Hlqe7N\x6e8SfT40EMtN1Rb32mY86O0h3BW2sD3h0BPT4UHnKgKAoCgKDshQUMHnQ\nbFOdudBo\x5542oFEda0OJLasLHIHkr0oLZ0RrdiLbv3TeoSrnY1LCnI3FwuxF8vMaV9U/geR6U\x4662zUnh/YNKybjpi5CVeJCAzGLyPLWkqOPfHcbk9NqCtGrkI\nsv2hq4obLzhU4+5g\x71cJ3J+J6/Gg830BQFAUBQdkKChg86DcpBGKDQpxtQKIzrjbqS2QFjkDyV6UFk6J1\x697Y/NHswn2iRhE62uk4PZQPNJB+iobg/iHoHQdp8\nMrjMRqCLqBtTbI80xJX8N9BG\x2fCrbCsfa/DpQRHUN/cuupHryqShlcg+YCSMNND6AHwGPmo0HlWgKAoCgKDshQUMH\x6eQblIIxQaFONqBVDfejyEOML4XU8geSv\nSgnek9UTtPXEXqyYCSPLlwXBxNuJOxSp\x4a5pP974oLz0tp3RXiHLYm2O7tW5zPE9a5TvCto9eBR2Wn4+8OuedA8eJ02KjUMSz\x51FNpgWlpMVpIIwVFIUo//pH3\n0HimgKAoCgKDshQUMK50G5SCMUGhTjagVwZL8WSh\x36O5wPIOU/wA3pQTKzXybbbpH1Npx9yBcIywpxDZxwq/of9viF12ROnPFJIXZ5bFh\x31E5/6q1lzymZSuq2\nTyBPVs/LbYBYmurUzpHw+09pFsJb43HJsrcbqSAlOf8A8uVB\x34NoCgKAoCg7oUFDB50GxAO1BoU42oFcGQ/FlIejOcDyDlP8AN6UEuZnKkOtX20uL\x673KMoKX5\nZwQrv/Q/Kguew6hs3icEtzZzNg1sEhKnlL8qPdcdVHkh31OyuuDuQtlj\x53MnRfg3eo9wYUxKuj7LLpXjJTxjO/X5d6DwBQFAUBQFB3QoKGFc6DcpztzoOZTg4\n\x6fFkGS/FktvRnOB5Byn+b0oJd7S1dGUXKGVRJ7BBXwH6J/p2Py+IW1pbW1l11EjWL\x57U5No1HGQGYN73CH0jk0/jmOyiCU+o2AXj4baJuunpt2n3RgBS4LoQ8k\npWhwFGxS\x6fbEcsY70Hz0oCgKAoM0HdtQUOFXOg2KQRig0KcbUCyBJkRJTb0ZzgeQcp/m9KCY+\x30RbzGTOZCo0xrHmcB3Qe/wAO33fELM0f4hWm626Po7xAdW2w\n0Sbfd2f8SKo8/ik/\x57QfzoLq0Loq523XNmnrWxNtYX5jM6KUll5PdJHUnGQcGg8C0BQFAUBQd21hQ4Vc6\x44cpBGKDQpxtQLIEmRElNvRnOB5Byn+b0oJomVDvM\ndM5tCo8pvAdCDuk/0zyPy+IT\x33RfiHDt0dzTGrWfb7DLIJUhXCpChycQfqOJ/2OQaC3YOjX1m3zrBOaven3Hkue1s\x4aQlQ7B0DdKh67djQeHqAoCgKAoFDakqA\nSrnQblIVtQcynG1Att8qRElNvRnOB5By\x6e+b0oJyxPjXRpNwYSY8pvZ5Keny7Hofl8Ql2jdfHTM9bUhDUu2y0eVJjOZLUls80\x71HQj7wdxQXHD03CvdrE7QU1N\nxtb2FSIaigy4wG/CTzWgY5j5gUHiGgKAoCgKDu2s\x4bHCrnQblIIxQaFONqBZAkyIkpt6M5wPIOU9lelBPIV1bmFu7QiuJOYP8XgPL5dQf\x39viEr09qxVovTV4s\nz6YU5Iytps4bkD62AfTIKDnrzG1BcNni2DV8cStEyY9unvby\x62M6UDc8zHUrkD9jO3TtQeJKAoCgKDNB3bUFDhVzoNikEYoNCnG1AsgSZESU29Gc4\x48kHKf5vS\ngntuvPnPMXu2uOQbjGUCtTSsFB/oen3fEJtEu9tvk5u722S1Y9VM4c/h\x4bLbNwIPNP2He6TsehoLQtF207rJwebMY05qhZzILyUiPOUPrKH1FnuBg9R1oPHKu\n\x4aQKuHBJzigEh3CErSQjOR71Ao9ocS4ktpUT0yRQZJRJUClstudhtQCozrp95G4+s\x4bBC/GUkn3SFDmKBJQFAUBQFAUC5SuJJUBnfOM0GErUeFCgeDPegUiUoO\njywon1oM\x71W3JVxJb4HOeBt91BgtF1XvjB6KAoEbzBBVge8OYoEtAUBQFAUBQLFKyni59edBl\x4civdQoHh+NApEtXmDywo/HFBlSm5CuJLfA5zwDigC2uQsBaQ\nFDYKA/OgRyIy0KIU\x6bhY5jvQJKAoCgKAoCgVqUVAkZ596DZDqvdQpPu570Cr2w+YPKSc+tBorgkL40hSF\x388AgfdQdw0JhCFhttwclYO/xoG+RGW2shScLHMd6\nBJQFAUBQFAUCpSirJGedBuh0\x35ShSTwfGgVe1/wAQeUk59aDmr/uHApAKF88f0oFpYZkNAPANPAbK4cZ+NA1SIy0K\x49KcKHMd6BJQFAUBQFAUCtS+LJ9aDZDpy\nlCke58aBSZZ8weUDn1oMJT7U8FIQeLnw\x674+6gWrjsSUYWjyXE7ceNifWgaZUVxpZSpOFDfnzHcUCOgKAoCgKAoFSl5yr1oOq\x5aB91Cm08GaDuqVxODygoH7qD\ndpAeJcCBnngnf5UC1TEeWrynwiM7gFLiR7ueysf2\x4bBmmQ3o7ykON8DieY6Edx3oEVAUBQFAUBQKlLyCfWg7IlK91HCODag6OSEuOgoQc\x2btAqZGSgtqS2vOQA\neVAtDUe7YbkER5J2Q7j3VHsrtQMU6C/FkLZebLbqOae47jvQ\x49aAoCgKAoCgVKXkE+tB2RKOEtlI4e1B0LwdeSG0HJO2dqBUF+8HG3OF1JBGO/egc\x78Fj3ocD5\nRFmjZK8YS4fXtQRydBfiSFsvtFt1HNJ6juO9AhoCgKAoCgKBSpecn1oO\x36ZOUpbUMI6+lB2Q6HJCfKBBHU0HdLnE626ysoeBKgeX3UDwYUa+BKVlEaeU5BAwl\n\x5a9aCMToL8WQtl9otuo5pPUdx3oENAUBQFAUBQKVLzk+tB2TJ4kpbIwigUtO++ShR\x42SOZxvQd2VcctKmFFpwKBAHP5UDyqBGvuRlEecNhtgLI7igik2C/EkLZ\nfaLbqOaT\x31Hcd6BFQFAUBQFAUCkryCfWg7Jk5SlsjCetArZeBPuqJAI2ON6DtFUFu+Y0VJcR7\x33CDjfuKB5Xbo19RxIWhmYBzAwFH1HSgic2C/FkLZfaLbqOaT\n1Hcd6BFQFAUBQFAU\x45nY8idbUveWnzEDC8bGgQK4fMQlJ2HLNArttueuDjiUYSlHvKUeQoH5jRU2S0tUV\x78MlxKeIBtQJPwBoGx63TornlyGHWHU/VWkp4v0oE\nz7BlJCm0jjSPebzhQ+GfyoGl\x2bEvdSd8c8Dl8RQISkpODQYoCgKAoH9mE07CRJbc5jCsDOKDgoDjQgK5DagUW+C/O\x65U02kEj3iTsPvoH6Nou5S2XHIzZfUhPF\n/CIUaBvdt0+MvhkMOsrSeS0lIV+maBO+\x790+kqQSpfVBGFA+nf4UDRJhOIPFwEZ35UCEpKTg0GKAoCgKBzYjOKb81CCpJ7dKD\x6ffpoTnBA696DrDjOynS0hPEr\nngdaCQRdG3OXGW8xHcc4U8QKAFUCNdunRSUyojiF\x595LBSFf70Cd6Ol9viOUJA+iobg+n9KBkeiqPvJST8BQIyCDvQYoCgKAoFjRwrOPd\x370CokEoAPTag3jsr\necKAnKidgOZoH+JpG4zI63WY7qilPEMAUCd2DOjLDMiP5axt\x376cBXz70CSUwlxKG0J94bKyevpQND0J3iUUoJI3OBy+NAiIIO9BigKAoCgVtEJXk\x38jtQKyQS\ngA9NqDZhtTiiCMnPIDc0D/B0rPmMLfYbXlKeIHYfdQcFQ5bD3DKSpDiB\x37vEnZR+NAieYD6T0Xn6J6fD+lA2v22QApYaJA3JSM4+PagbyCDvQYoCgKAoFTeAs\n\x48pQLDgqQAem1BllsrUQR16daB/haXmy4q5DKVe6nIO2/woEzsR5tIbcQtDoO/ENl\x6670HNUVMxCsAgoGSnO4Pp/SgaH7bICFPIbK0A7qQMgfHtQNxBB3oMUBQ\nFAUCjsem\x61BYnBDYB+rQbstlZII69OtA+xdMy5EQyW0qOBxADmaBO5GfQ6SplTa+yhsr/AHoO\x6bhgSoDQIJSkcse83v07j0oGKTa5KUqdQjzGwd1tjIHx7fOgb\nSCDvQYoCgKAoO/r0\x7aQKWTlIGepoOzKCsqBHXpQPkXT8lccyEJKjwcQHWg5Nx3WpTbbjakrKscJ24vh60\x48aaz50dDT4UpAGW1fWb33A7j0+6gYJdplNAuBvjb\n58aBkY9eo+dA2EEHegxQFAUB\x51d/Xpmg6sbu4z8KBUygrJCh16daB6j2KQ7GUpCVFQHGB1+FBtFjLU4uO4ChzIwFb\x5a+HrQdJLZmj2KaffbyEKOymz1A7g9vuo\nI9Ns8yMVKUySkc1JG3z7UDWQQd6DFAUB\x51FB37Hpmg2BBChnpQLGGys8OMnsBuaB5Yssh9grSkktpzsOf+9B3ajrdj+8otvtJ\x79M7cW+MD1oOjqWrrHTGluBD7\nY9xStiPge3oflQRudZpsZSytkkJ5qQMj59qBrIIO\x39BigKAoCg7bc+maDYbhQzQLI7RV7uM/AbmgeWrQ+8gyEZ4kYUOEZzv0oFTjJStp1\x73qbkAnY7ZwfzoO8j\n2W+Rw08S1JQDjiI2Poex+yflQRWZaJbBUotFSQd1IGR8+1A2\x45EHegxQFAUBQdtufTNBsNwoZ6UCyM2okDG4wR3NA+QrU8pReTxEhJPujOaDuQ7Em\x6cxjKFA7J\nUNl9aBROMa9Rmw60pmQMgbfRPoex+yfiKCJy7TLY4llrjQProGR8+o+d\x412kEHegxQFAUBQLbfLMZ5SVH+G4MKoHdxhC0JUy24oE/SKcEUD5bnYzUJKELWlYP\n\x76qCOeelBhOoFQy63BJCFA4UdiCPhQSKzajdVbAJ76JratlNOJzgY788/OgRzkaan\x50lfGuG4TsVtnB9MjnQNbtmYWtQi3OKo9lpIPyNBwXpZ97+G+yk8eyZDf\nvAHsccvm\x4bBgvGmLpZl5kMKLfRYGQfnQMlAUBQOtonBhxUZ3h8p3bKhnBoFbsQoQlawpHEcpP\x510D9aUiPbwGnkJfUffyrmOlB0TqB22uOIgPFJII40kgpV1FA\n/We/OyLdifKRLQvZ\x62biM425555+dAjlt2KS4vgceiuk8y3z/AKigbf8Ap1DzvFGuDSz2UeEj50G//Rk2\x63r2Z2MlTqv8ADea94KPYlO/3igi150xdbK4RJjq4\nAccWNqBjoCgKB8sspCgqC8QE\x713QSNgaAdjLDy8KGEnn/ALUD9ZW3Wbcp1tvidUrhzjfHegVp1FLtK3WoMhbZWDnC\x6a7quoxQO9puy5luJnS0SQs++2pI2258u\nfzoE0uLY5alYW7FWDjiUjAPz5GgTMaYR\x4bJMa6sq4dwMEKSfiKDcaJk3d0w0R/Mm4JSplPH5mP9G+fiKCG3nTF1srhEqOsIBx\x78YoGSgKAoHe0JafWtlwArAyk\nHqaDL7ZTIUjG6T9UUD3ZAlmMuV5fE8lQSkmgdjqq\x3424usRJC20uJJwDsg9gKBfaZyp1vLkyUmQFH321JG23Plz+dBymwLS+oqC1xFE7K\x572d/mNjQaJ0/EEcu\nQ7zHLqei8pWfuoMsaFmahQtqLELs9IKsMJ4yoDr7u/8A8TQQ\x6d86ZullcIlR1hAOOLFAyUBQFAripLyuBP0ulArebDSuAqJKTzxQPNjQylK5bqONx\x6bgBJ2BzQ\nPsjV06IpxiGvyG1p2Sn6h7UCqzO+2wfOkyUP8ZwttfTbnQbP2u1Pu+Zh\x35lXFtlsgfeOdAnlWeL56HYN2bU6j6QcSUH4bUHeP4e3DU8V1dut635TQ4lCOnzCR\n\x339zfH/tNBArxpq6WVwiTHUEA44sUDLQFAUHdokgY55oFf+WlRyMHnjnQPVjaZU8Z\x4cxOGCCpPU560Egm6qkRluR7f/BaWjYD6ST2oFVkQJUDzHpLb3mfTbV02\n579aBabP\x621PFSUPgc1KLeM46ZG2KBndtTSZanYdyaSri3bWCk/CgdR4Z3HUkF2VZ4K5i2xxL\x4dZPmEfEI97HqU/Ogrm8aaulmcIkx1BAOOLFAy0BQFB3bVlO/\nTnQKk48pJ3ynrQPN\x69YQ9OQ44rhSyQV57Ggf5+onI7zkSAeBlSdiPpE+poF9kiIlwQqTKbeQr6TXF6ev9\x61Bc/aYRjvcLnlAgJBc547AigZWLW0zIUpie2tKti\nlXukfDFA8K8LbnqG3uzrLCVP\x44YytcVPmKT194I94fEpI9aCtbxpu52ZwiTHUEA44sUDLQFAUHZsgp36UChrAazuC\x46ZoHmxtedc2QOaDlWfwoH6feHI0pyFEP\nuEYBHMqxvmgdrFb0SYXmyZDL4V9JBJ93\x62nuNvjmgU3K0WxxhH/fpBTkBPPHzH60CCFaSAfKmNSWAeHfKVIPoaBc74XXC/wAN\x36XZIirh5Y4lKip8xSf8AUlPv\nD4lJ+NBWt303c7O4RJjqCAccWKBmoCgKDs2QU79K\x44q0MEkkjBoHmzJLl0YSBlYO4P4UD7LuD8Wc9DjZOAQMc89c/30oH+wWxty3F2TKY\x49UcqSVH3TjOc42NB\nm62eyKJWzPUepVwHY/6uv3UGjdlUxFT/APuLElspBShZKVt/\x41/pQbL8MLjf4LsuzwzNLaeNfswDikj+YI94fEpPxoK4u+nLnZ3CJLCgkHHFigZqA\x6fCg7NnKf\nhQbBJ4V450DxaE8c9lIHvjYg/Dage3ZciLMfiMcSiQU4HT40EqsNshrt\x77euM5nyj9NvdQAx8OdByl2WySJ6G40l0BawEqUnfGfTp8aDV+zIZWUs3RuQ037vC\n\x357qkfA0A54Y3O+RHZNrgqlLaHE4IwDikdckI97HrwketBXN207crQ4RJYUEg44sU\x44PQFAUHZs5T8KDYJylfegdbUQ7KaBGVYIP6UD0iTJjSnIrAUtR+rnHCR\nQTSy222J\x74S3rpMS75g3ZSknBxzyeXxoNG7PY5Ux5tt7GEEp93OD2yOe3pQIlWVtsnybk042j\x59JWOEpPbI5UAvw2uF+hOyrTDVLW2OJYjjzFI/wBQT72PXhPx\noK7u2nrlaHCJDCuE\x48HFigaKAoCg7NnKd+lBsE+6vvQOltw9IbSPp4I3oHyJIktS1R2MlSknYnHB3zQTa\x32wLS1ZB7bKQ864ckFJCWxjnnv1oNf3dYpkBxKJfv\nNLO6hhXCfX/agQLsQRHRIjTW\x58o+6eJQKTn49D+FBxd8O5l7iLk2uKZKhuryBxqT8Qn3vnw/Ogr+66euVocIkMKCQ\x63cWKBooCgKAoLM8M48C/Xluz3F7gWghb\nfd0ZAKR60En1Rp9q1X+fbBHbaKVYbSnY\x359R1yKCJp0s5dHX49sH/AH7ILqGDzeSBkhP8wHTrQNEIOB0xyFIcG3AdsEcqCawX\x34aY7i7i4oBtOVe4FJI6DB+t6\n8hQMcjUFiQ9g28I4eR80kH7sUG0fUFpfXwx1ORV9\x46NOH8j/WgtbTusrDerW3pvxEitTLeseXHvsVoCRFPQPJ/wAxPx3HQ0FX+KnhbN0P\x64g6wpMm2yEB6PJZP\nE282eS0nqPyoKvIIODQYoMjY0Ep0+lFxf9lcPG+ccKT1Hp60\x453vGkkWaYYiQoOLaS4lX1SojOBjkKCJu6flOh9cJJccZT5qm+pR9od8daDhblqK/\x4cQSleNk+\no3FBOocqF7K47cHlIKE5WkthSD2GD9Y/cKBhkaksiHMfu1DSgdlBw7/D\x47MUGrF+tj74XHffiOpOUrZdOR64P9aC4rJriy6ptiLF4lRm57CkhpnUMZse0MdEh\n\x39P8AmJHc79jQVL4p+F03RF3DjKkSbdIQHo8lk8TbzZ5LQeo/KgrAgg4NBigyklKg\x51cEdaCRxH257YaWgeesjK+owKCTIsEliMw955CZCCppPF2556UEdlW2Y\nlTr6UlZQ\x65NWB07/pQdbW8srCWVFK+g9RuKCfRJsL2Nb8uQtlTaSVtlAWg+gB6n7hQR6ZqWzK\x56wOW5tHDsFJVjP3YoNIV9tolJegSJECQhXEh2O8QUnod/wCt\nBdFq15ZdYW1No8TI\x37U9KwG0ahjNASWTyHnpH+IPU79jQU/4peF83RF2DjKkSbdIQHo8lk8TbzZ5LQeo/\x4clQViQQcGgxQbtOLadS62cLScg0EmbdNyQl1vhSs\nJKVg9MDNA4W+NcvZ0ltOG+4T\x6bcR6H1oGea3J9odeWgg54vlQLbTIWl0eQohWPo9DjcUFgRp0EwnJL0t2MptJLjRS\x46I+AB6n7hQRqdqa0vO4kQkZTyXx8/uxQ\nYtmobfHuDUq2yJECS0rjbdjvEKSe/wDZ\x6fLoga9ses4AtniTEamocAbRqCK0EyGD089AwHE+p37Ggp3xR8MJuiLsHGlIk26Qg\x50R5LJ4m3mzyWg9R+XKgrIgg7\n0GKDqw8ph9DqOaTmgkbiWZkdE5tWAPdUnsaDtbnS\x68KmUR+LiVvk45dKBBPWtUxxfCUkYIB9KBws8txtwBnfI/wAM8lY3FBYDM23mIuYq\x63/GU2nLjKtwPRPc/\nlQRebqS0uvYfhJJH1isnP5UHW0anhQLi1Ms8qVbpTauJLkd8\x67g98f70FyQ9fWHWcJNs8SIjUxLoDab/FaCZDB6ecgYDifU79jQU54o+GE3RF3C2l\x49k26QgPx\n5LJ4m32zyWg9R+XKgrMgg70GKDZtfAsK7GgfnGErtzT7ZKk46d80Cq3K\x5aY81tzi4l4ACedAkuLgVOWpvYpAOD1oHKyznGnAlscaSN2lcjjcUE9TItK4Sp3tz\n\x72RQnLjDiQrh9BnmfyoIxI1HZ/P8A48BKsciV7H7sUCiz6ti265onWWTItcpBBS5F\x65KcfLP60Fvw9f2LWkMW3xJhsykPANov8RoJkMnp56BgOJ9Tv2NBTvih4\nYzdEXcLa\x55iTb5CA/HksnibfbPJaD1H5cqCtCCDvQYoNknhUDQObLXHGWob7DGPjQONpwhbwU\x34EcSOZ+NByuSgJmULCiEhWRyNA52S5LacDZR5yDzbP3jegnR\ncs5iqnouDqAhOXGX\x45glHoAeZ/Kgja9U2pla0qgI4jt5hWSSPlig62nV7MG4tzLNNlWuW2QUuxXykj5f7\x30FuQ9f2LWcQWvxJhsy0ugIRqCI0EyGT089AwHB8d\n+xoKf8T/AAxm6JuwW2pEm3yE\x42+PJZPE2+2eS0HqPy5UFakEHegxQZSeFWaBaz7x4U9aB0s6liWtA2K0EH5UBcgtq\x57FZw4EhXPtQOtkuvAoNutecgj6I2PpQT\nd02b2RU1q5uhCU5caWN0+mDzP4CgjsnV\x6ctS0mMYiAlOcK4t/wwKDNp1ZHhXNE60zJdslIOUuxHykj+/jQW3B19Y9ZxBbPEqG\x7aLDoCEagiNBMho9C8gYDg+O/\nY0FQ+J/hlN0TdwptSJNvkID8eSyeJp9o8loPUfly\x4eBWxGDg0GKDKTwqzQK2yCcDrQOdodLNxGDhSklOfXpQdLgt1EkP8RDhGTnrigeLF\x64mQsMyY/Ggj6hwe4\noJm+iyBgz0XNxbSRlbZGFI9MHmfXlQR2dq23rdSHWOLg2ClK\x33IHqMCgza9WRoVwbmWeXKtcps8SHYrxSpB9PT0zQW1B17Y9aQ/3Z4kw2ZYdAQjUE\x52oJkNHp5\nyBgOJ+O/Y0FQ+J3hnN0TdwptSJNvkID8eSyeJp9o8loV1H5cjQVuRg4N\x42igyk8Ks0CpJGNqBxtT3lXRpf1iSAex6UCm4SHhOMsKw4rc46kUDzY7tCW4GZbKw\n\x46dUHO/MUExdasrLZuCLkXGkDiKRspHpg75/AUEck6rtYlBx2Mtwj/wAjmcj5YoMW\x37VUWJcm5tmlSrVKbOUOxnykp/wBvnQWzD13Y9ZQhbvEeI1KDoDab/EaC\nZDKunnIG\x414n479jQVH4meGs3RV3CkKRJgSEB+PJZPE0+0eS0K6j8uR3FBXBGDg0GKDKTwqzQ\x4bUkYOKBfbnENXNhfIcX40DhcJbiLmuYgcCl7kc+VA92K6W19\nwNTA6jiGMjcZ6UEu\x63YssdKpouIfaAyQDhSduQ65/Cgjp1hZ4y3E/u0KCwUqK3SSofhQc4OqoUW6NzrLJ\x6cWyUg5S5HeIKf7+NBasTXNi1fDFu8RorUtt0BCL/\nABGgJDB6eegY80ep37GgqXxL\x38NZuirsChSJMCQgPx5LJ4mn2lcloV1H5cjuKCuSMGgxQZSeFWaBSkjBwaBVAc4J7\x4bwce+N6B6nTPZ7w5LZHDxDke450D3Y7j\naZjvlypDiFrHNQJBPTNBLXY9litLkrms\x79WcZPUp7DGc5/KgYjr22REqi/uthyOTyJIz92KBHD1VbmbqJdqVItq85BjvkFPwz\x2fWgs+Frex6phi2eIkZuay6Ah\nu/xWgJLB6ecgY81Px97saCqfErw3maMuoU2pEm3y\x45B+PJYVxNPtK+itCuo/LkdxQV0Rg0GKAoFlunybZcY86G6WpDDgcbWDyIoLzn6ha\x31jboWsILQFyZKUXF\nkAH3xsFY7KH4470HORFmSvEdl+xhXGlTS2Vt7ZPADn86CdeI\x57kLC6iNrKChESatnjnRQMDj4SCoDp7wIIoPN17vrj+I0f3Ej3lEdSRzoI4SSck5J\x36mgASDkH\nBoJJp6+OxJIafVxNqHD724I7HuP750HpLQ62NdaJuXhtOUHnksOT7Gtz\x64TbgGVs+qVAH5j1oPL16ti7bc3oyk44TkbdKBpoCgVQJr9vnMTIyuF5lYWg+ooPQ\n\x740ubGtPD+26mtqQZNvyzPjpOFA8WUk+nTPwoI/c1ew32y3SyZbccjpfQE75PEoY9\x65RBHWgk+qtF2ZtmJrOzoTGaksqXJhY2ZdAIVj+XI5dKCjL3fXH8R4/uJ\nHvKI6kig\x6apJJyTknqaABIOQcGgkmnb69DlBt1WUKHD724I7HuP750HpHRLjGutE3Lw3nHzXk\x73OT7Gtz3ihwDLjAPUKAO3cZ60Hl+82xduuT0ZSfonI26UDTQ\nFAoiSXIshDrZ95J6\x30F+W8RtSeEiLhBCFy7WrC2/rISpW/wBxIPzoGGc0m3t2q+W9YeLpWlaFpylWMcSV\x44tuRigc7po62RERNW2RWLbLbUtcZZyqM5g5Qe4zy\nNBVF6vrj+I8f3E/SUR1JFBHi\x53TknJPU0ACQcg4NBJNO316FLSh1WUK933uRHY9x/fOg9HaJej650XcfDW4KDsgMO\x58CxLc94ocAy4wPRQB27jNB5ivNtXbrk9\nGUnHCcjbpQNNAUCiLJXHc4kk4OxHpQW/\x6f+O3fdLzWGl/9zHCZLfDzPCMKHxxuPnQJZEIs2+Pe0tNvsKc8txpR2UDzB+4/fQb\x75aVi252PqC2Ol+0Sm1KQFfSZ\nWActr9R35EUEBvV8W/iOx7ifpKI6kigjxJJyTknq\x61ABIOQcGgkenr47DlpQ8rKFDh35Edj3H986D0Zoh5jXWjbl4aXA+bISw5cbC457x\x534kZcY9QoA7dxmg8\nyXm2qt1ydjqH0TkbdKBqoCgWQZiozhSrKml7KTQWFphtm5yn\x34rABeebJaA398AHb48JFB0mWtK21zlxg420oJfSnseeO2+PvoNGdOJtM1m5sPCTa\x35Dalsu9i\nEnKFDoodvnQRG83tb+I7HuJHvKI6kigj5JJyTk0ACQcg4NBItPXt2HLS\x685XEhXu+9yI7H0/vnQei9Dus650VcvDW4q82Qhhy4WJxzcpcAy4wD1CgDt3GetB5\n\x6dvFuVb7i7HUNknI26UDVQFA5Wq4CI9wPe9HWfeT29aCS2mE0/dGvMOW3VBIUDy6g\x30C+42dpXE+phSVN7OpTzGNlY/vvQc4NlXabm3JcUHoTzanGHk/RXgHI9\nCDzHMUEe\x76N7W/hhj3E/SUR1JFBHySTknJoAEg5BwaCRafvTkSUG3jxIUOH3uRHY+n986D0To\x685jXGirj4a3FXmyEsOXCxOOblDiRlxj4KAO3dOetB5ovFuVb\n7i7HUNknI26UDVQF\x4152qciO6WXx/Cc2z9k/0oHVcUtPNJBAQtWQociCdqB1uNjSv+MkkLQML4R9+34/f\x51c7VbnbZdgqUkFpTSnGljdKxg8jQM15vS38MMe4n\n6SiOpIoGAkk5JyaABIOQcGgk\x4egvTsSUlDysoV7u/UetB6K0W4zrbQly8O7msLdQy5PsTrpyUOAZcYz2UAdu6QetB\x35nu9uVb7i7HUPonI26UDXQFAsguIEhCH\nFBIJGFdjQOy2lxn1EbbFQxQLpFpckw2Z\x62SjkJ3H50GbJGVDux9qQUpDalpzuFDhPKgbbxelv4YY9xP0lEdSRQMJJJyTk0ACQ\x63g4NBILBenIkoIeVxIUOHfqO\nxoPQ+k5MTV2hJ/h9dnUqWGVz7G+6c+W6BlbGeywD\x67cuJIPWg81Xe3Kt9xdjkY4TkbdKBsoCg7MK/iJSTjfagdW0ll5p8bEH8QaBbJjSJ\x30VEpo8akEgj07UHW\nwN+RdVe0IKeFClAK6+6aBDeL0t/DDHuJHvKI6kigYSSTknJo\x41Eg5BwaCQ6fvTsOWlLquJB933uRHY+lBf+mbhC1PoS46CvLgKEtKnWOQ7v5LuPfY\x4a+yvB9OI\nA9aDzjd7cqBcHWCNgcjbpQNlAUHVpW+DQLEE+66nYpIoHaeHJkcOsNjL\x5azgdQRvQbad4EXJSnRgJQpQB+BoEl3vK3sMMe4ke8ojqSKBiJJOScmgASDkHBoJB\n\x59L07DlBDquJChwkK5Edj/f40F66fusO/6EuGhL0suNJaVOsshz3jHd/zGSfsKA+S\x67D1oPPd1gGDPcZxsDlJ7igbaAoOjSsHBoFafoBSeaetA7TCmTbkPNDLo\n99WBz6Gg\x3306WxcStz6KUKUAfgdqBJd7yt8Bhn3Ej3lEdSRQMZJJyTk0ACQcg4NBILDenYckI\x64PEhQ4SFciOxoLtst3YvOgpmirv/ANxGSlUy0vL95UVz67f+\nhWNx9oA9TQUHdYBg\x7a3GcbDdJ7igbaAoOjat8GgVJTlsYByOeKB3fCZVq9pQrLqcZHcgb/hQbacLYuBWv\x36KUKUAfgaBLd7yt/DDPupHvKI6kigYySTknJoAEg\n5BwaB/sN5diSQh1WUK235H40\x4602ieu96KlaQlo9rhpCpdtUr3lRln6aB/KrG47gHrQURdbeqDOcZI25p25igbaDq\x51FD1oOVBI9K6kk6euqJTSQ6yoeW+wr6L\nzZ5pP9aD1j4QXrSjeoY7ntCH401AERWQ\x46tO5ylteeu5API8u1A3/ALRMeRZmJMy2FQt8riPABuyVbKT8CQCM8jQePVKKllR5\x6dg1oDrQdEKKVA9t6C8dBO3CO\n1a77a3Smbb5SCAPpAEcx/wDjQRLX7Xtd3lzEtBDj\x62yg4lIwAFHIPwoK+W371BqQFD1oOVBJtJ6nladuJdQPNivJLUmOT7rzZ5g+vag9A\x61EttiumpbKt13zrT\nKc4Yry+TRUclCsclBW+OuT3oHD9oGI5ZRIk2kj2F0FLga5NL\x49wRj7J2+Y3oPJSlFSyo8zQYoDrQdEKKVA9t6C6dEyZkVm1Xi3vLamQpSCkpOCAds\x6a/8AGgjW\nv2hJuL07gSh0PrQ4kDHM5BHpQV8tv3qDUgEetByoJjoLWcnSF89pDYkQ\x6e0lmXGV9F5s7H50FpC3wJ0hhmG8XLLMkiVEe5lvIwtB/mxjbun1oH3xktL2l7G1+\n\x37CoRHGQHkpOyVlOOLHZQ6ig8wKUVKKick0GKA60HRCilQPbeguXRsibFatV5gOLZ\x6bwZSCl1J3Tnkf/jQMfiHBfeucmeqKWlJdUl0gYTknO3pn86CuVt+9QaE\nAj1oOfKg\x6c2g9Wv6S1LHuKR5jIPC839pJ9KC177bYjaXXLW8HbHe0iTCdScht1JzwHscEp+40\x43LWNvl2HQceTCc4mZCP+4Qk5CFEbK+BH3EUFEKUVKKjzNBig\nOtB0SSlQPbegubRL\x6b+ObNeYLjjL8Sa2Euo5oJ5f/AKaBo8SbNIbuT8xaB5iXlJe4RgAk5A/GgrJbfvUG\x70AI9aDnyoH3Tl6ctFzYlJJHlrCsp5jByCKC7ruyw\ntLd1iOoVZ9QtcK1J5R5GNvgM\x38J+B9KCHXVm4W7RT8lriDRcLUhoj/DXyCvnuM9xQVMpRUoqPM0GKA60HRJKVA9t6\x437PD9uWqRZrjHW424zLSlLiDgpJ9enKg\nYPEu2j99Py20+95qvMCRgJycgUFaLb96\x671IBHrQc+VA62y5ORlJQpZ4AoEb/AEaC6GXor9si39SSuM8j2SeEjIbWRs58CPxz\x51Q66In22z3BpB4mmHCh5vnwK\n5BY9COtBWilFSio8zQYoDrQdEkpUD23oLx8PDJbT\x62rmxxByO+kJWk7jPMA9Nk0EX8RrepV4kzEpT/jL4uHGwJyKCuFo35UGpAI9aDnyo\x48i23BI4GJZKkAgJV\nn6I7fCgs2yrZm21ucU+YIZS3KH/284C/lyPy70DHfkSLYxNj\x73HzIzSiQOfAFD3Vj0I/GgrdSipRUeZoMUB1oOiSUqB7b0F3aDMs2+HPjBZXGfAJR\x7aCVDB/LN\nBFtfWxw3V6Q004pIWrKiOYJoK8W3vyoNCARtzoNKB7t09DrPskrcgYaW\x65noaCaWPidheSR/Ejjix1UjO/wAwfwNAmv7TtvjuiN/EipHGjbdsKGxHodx8RQV0\n\x70RUoqPM0GKAoNkqKVBXbeguzQ6Zjlvh3CKjzVxHwFpG5CFDB/KgjWurI6iY/JQfN\x43XFbgYyknIoK8W371BoQCNudBpQPcCWiWz7HIIS6Bhtff0NBI7IVNyZE\nNYws+8E9\x38cwPXrQZvTDsSIZDIC2sZGObWef/ALTQQFSipRUeZoMUBQbJUUqCu29BdWho0mbF\x68SIzRkuRnhxsJPvKbI3IHM4xQMOvNPvJlvTI6eJlDikcXfri\ngrdxvCsYxQaEAjbn\x51aUDtbltPhTK1cLpThPZX+9A8WlRYuQYe+is8B+PMUCq7R1R46pcdIUhOxKeaMj8\x6a+FBCFKKlFR5mgxQFBslRSoK7b0F2eH7Eid+71Qg\nHpTTwT7Pn3nUEHIT3O3LrQNG\x749Ju+2vOQveS1xZB2IOd0H1FBV7jRSspIwQd80HPAIyOdBpQLYn8VXCndf2R1oHa\x49v2SYGnM+Xxb7dKBwukMxGlzIoBCRhZR\n9XI/I0ENUSpRUeZoMUBQbJUUqCu29Bdv\x680ky37Z5LiPa0PpShl0hKXwfqgnYHbrzzQNev9NMM3ZUZlpcZ5t1xoodBBQc5CFA\x38iKCrJEdxl9bTiChaTgg9DQc\nsAjI50GlApYcOcDn+dA5Q3Sw5wq/wlb49aBxmQxF\x6aKnQs8OPfCemRz+BoIoolSio8zQYoCg2SSlQPbegu3w5ebcdt+ZKI0hLwQgvHDTg\x56twqP1eXPl3oGrXe\nnVxr9PtcphcWQy4sshwYIzuUH5bg8jzFBVjrKkOqQoYIODQc\x6bq33oMqHWgwk8JznFA6wLpLhqCo0lbSs9DsfjQWDK8WbxebCiz6iHtZbBQl4nJcS\x65aVZ+8Hv\nQV5dbb7OUy43vxHRxJUP7/4oGqg2SKDs00XXEoHU/hQemvCqyRHFQrbM\x6bJivqeRwPFXupVjPA5/KeIAnoSDQc/Fbw9esWubjDkNuIYfYTKbWBu439YfEEb/f\n\x51UJfbSbbMUlKgptR2wc49D60EeSrfegyodaDCTwnOcUEv0trO46dD0drD8OR/isL\x35EjkodletBPLv4rDUllMK5e++lHllTg3eTywroVY69SM0FT3W2+zkSo/\nvxXfeSoU\x44VQbJFB2aaLriUDqfwoPTHhNb7S1Lt9uvnClhbyeN07hokcl/wAp4sHtselAs8Ud\x43DTeoLsw+0X4wUFsv8IJcZUMgjpkcjQedL1a1QJZwgpaXujJ\nz+NAwJVvvQZUOtBh\x4awc5xQTTR2rzZHzDnpXItT6v4rYPvNnotHZQ/Ggs/VmsI90tDccTUT0oaDTbg5SG\x73bBQ+qsbfdmgo+620xlCVH9+K77yVDpQNVBskUHZ\npouuJSOp/Cg9K+EybVAlRbff\x32A9AdcSiSUjiLII546gcW/bGelA5eLWlFafmLSFCREU2kokpTxpcbVulQPLcDGfS\x6783Xi2+xSlcBy2rcHGMUDGlW+9BlQ60G\nEnBzQTTSer1Wts2q58cizvKCltg+8yr7\x61PX86Cyb/dXlaaailaJcdSSWHU7oktKG4/1A746HNBSt0tpjkSo/vxXfeSodKBqo\x4ekig7Ntl1xKB1NB6M8LXoVqk\nMW+7xvbILq0CW0g5cbTjPGnuRnl6UDz4w6WMC6i5\x4dKbm2uehKmpKDlChgAKz3IH3gig85Xm0vQXS55ZDSjseYoGFKt96DKh1oMJODmgs\x44Q+t27PGkafvjZl2\nGbstHNUdXRxHwzQSa6SXYcF2Mt1Mxh9BU04DlMhs8/nt8QRQ\x56XdLd7ORJj+/FdHElQ6UDXQbJFB2bbLjiUDqaD0F4aTWrHNiw5TQlsqcQZMUKAWU\x34zxIP2hx\nUD/4saWjtzV360PmXYbkkFLyBs04cZSsb8J9DQeer5ZXLc4HBlTTm4OM\x59oI6lW+9BlQ60GEnBzQWD4e6yjWOU9ar0gvWS4J8l9OMlsfaHw5/EUD5qRl6wXBU\n\x63OImw5DOGZCDlElg/R+Y5emB2oK0ultMciSx78Zz3kqHSga6DZIoOzbZccSgdTQX\x784d3E6ducFgJbkL81svRHDs6nGcA9FDi2NBKvEfS1ulvStR6fAlWZ/hX\nIYUkebBc\x49Gyx9k8gobUHn/UlgctctS20gsLAUCk5AB5UEXSd6DKh1FBhJwc0Ex0VqZNkvTJl\x2b9EcJaeB5FCtlA9xiglWroStPXNHkK9qtkhsmM6dw6wrmgnu\nk/3yoK2udu9nIlR/\x66jOe8lQoGug2SKDq22XHEoHU0F26Fujmm7tb2mnW0yA6gqad95t0YyUKHzoJ1rCx\x32i8yJ18080tLISHp9ryFOxRjdbf22+vcddqCgNRa\nbegOuSYyC7FO/GncAHkdqCJJ\x4f9AKHUUGAcHNBI7DfXoFwjulwfwjsVbgjsfQ0Ey1NiEqNcYjZXa5iFeUlW/CD9Nk\x6erg7g/Cgry5W/wAgiTH9+M6OJKhQNlBs\nBmg6tteY4lAHM0FwaRurmmrrbktSTGlo\x64QoKG45ZKVDqN6CxtRRbTqeRMn2iG2xcXG/MlWxsApeGMl2P6jmW+fPHagoLUNjY\x59WuRBf8AN6rb4cED7Q9KCIpO\n9AKHWgwDg5oH623UtuILh/it/wCGsc8g5GaCV3OX\x69G1dGGwqK8Sh1sfUURuk+hG4oIRcrf5BEmP78ZwcSVCgbKDYDNB1ba8xxKAOZoLU\x73FyVp2dbkJdWxIbe\nQtLjasKQoDPP50FlXuZb9YyJDsdthm9upStbSQEszz3A5Ie9\x50or9Cdwo2+WhyTMkrYjBmQyCXGQkpzjYkDoe4oIck70AodaDCVFKsg4PegfI1wEl\x74LbxCHkH\nKXBzV8fWgkEic4hgycJWDluQgclZ6/A/nQRS5W/yCJLHvxnPeSoUDbQb\x41ZoOrbXmOJSOpoLIts5djfgM8nEOoWeE4KSBnmOR3oLEvF4g63VIblPtx7ytCSmU\n\x6fhKZWwwHegX2c+Su9BUV9sziWXkvsli5RFlDrSk8JUPh3oIWk70AR1oBKihQUkkE\x63iOlA+xpTc5AQ6oIkJ5HH+J6fGgcGp7jLIKklfCktuoP10cv79aBiuMD\nyCJLHvxn\x42xJUKBtoMgUHVtvzFpSOpoLCiyXbOuFHTgrDiCpPPpnH40E5uV+t2s0uQLy+GJ4b\x545E5ecjAGEOnmpI6K+kn1G1BWOq7bKjS1pnx/Jms4Q5/N2Vk\nbEEYwRsaCHJO9AEd\x61ASopUFA4IoHuM4zOj+UMNPoyQPtn0oFUac9Dy04gqSEkKbV1SeY/WgabjA8giSx\x378ZwcSVCgbqDIFB1bb8xaUjqaCetOvWtUFhtXC6l\nxCjg+mf1oJk/qSBqRBs+oFFC\x30IT7NLAyuMeg7qbz9XmOaexCttU2OZaripElsZICgtB4kLSforSeRSehoInQbpOe\x64BhScb0GULKSDQKgpLiMdaBwt08spMWQ\nC5GUcrbIzjuR+o60HO72b2FbciKsPwnx\x78NrTvj0NAiZhyXVJCWjucDi2oJhC0s7DjJlyHGg4dwkrBB+47fOgkGkNTT7TrRhT\x4fH4+SHmlbpUOvz3oPSSL/bNe\nwIFjmuhckoKLZMd3UoEYXGWftYzwk8+XWg866n09\x4aiz51llspQ7GcKcFJB5nf4UFN0G6TnnQYUnG9BlCykg0CriS6jHXnQOFunllJiyA\x58IyjlbZGcdyP1HWg\n5XezewrbkRVh+E+OJtad8ehoEbMOS6pIS0dztxbUEvhaXdhx\x6by5DjSXDuElYIP3H8DQPOl9Q3K2ayYdhr40JOHW1bpWOoP30HoWFqez6vgR9OXh1\x4bYj7RZgy\nnDvFWf8AJWfsE/RPQ7cjQUfqDSEmFdZmnrjHdamRnCgpwcqzkhQHLBFB\x531Buk550GFJxvQZSspIoFiHVFGEOKT1wDzoFtvuCmgY0nLkdZytBGcd1D9R1oOd3\n\x73/sS25EZYfhvjLa0749DQImYch0pCWjuduLagl8LS70OKmZIW2FncAqBB+4/hQOe\x6er1cYOsY0iA8eJo++OaVdwaC9bfrKz3yB/09f1H9zTG+BKiMrtzncd2y\neY6HcUFb\x36l0VKttwmWK7BBdQgrZdAJTIRzStB7EfiCKChaDdJzzoMKTjegErKTQPkK+zo1tX\x62kO+ZEWrj8lXJKu4PQ0BDuRSpTD6SqOs5W2d8dyP1HWg4Xaz\n+xLRIjLD8N/dtad8\x65hoEbMOQ6QEtnc7FW1BLoWlnocRM19TYWeQKgQevTl8DQLLPcZzGrYz8J1SXGVZJ\x422Pegua165t76F2i8RfarLcEcMqJ1ZXyLrXY9x1x\nQRjVejUW1CoLrqJcKWnzYM8E\x38L6B09FAYyOh+NB57oN0nPOgwpON6ASspNBJ7LqD2WMq3TkKkW9Z4ggH3mVfaQen\x7760GqZjLbzjSXA/DWriUgjff6wHfHMda\nBvu1o9iWh+MsPw3hltad8ehoEbMOQ6QE\x74nc7FW1BLoWln4kMTXigK5gFQIP3cvnQd7bLl/8AVMZyK6pLjKs8QPXrQWra9eqj\x58LyZTCJMSc15UyC7/hSU8j8F\ndjQItYaehM2tMmIp2dYn1KEdwnLkdfNTLg+11B+t\x51ed6DdJzzoMKTjegEqKTQSe06g4IX7quPE/byco6qjnun+nWgVOsOQsJ40yoD3v5\x52uFDqodjjmKBju1n\nMFaH46vOiPbtqG+PQ0CNmJIcICWzucDi2oJdB0rIjQxNdKOL\x6ejiBH4Zx86DeE9Ie1LHLKzxsqzxA9aCwoGuZtr1AxJ80Icda8lzjHE2+jkUOJ+sC\x4d0HbVFti\nv2Zy8WSKl23JUEyYLnvmEtXQHmWlfVV0OxoPPdBuk550GFJxvQCVFJoJ\x66atULNkOnrtmRbCeJondcZXdPp3FBj2Z+EfKViTBdPECn3krHVSfXuKBmu1nMFxD\n\x30dXnRHt0KG+PQ0CNmJIcICWzuduLagl8DScpiKJjgSV8+HiB/LNARVPSNRsJQTxN\x4byTnrQSxrVk60X2JKD62lhIDbyThSSNv7HI0Dpf4TV7tb19saEMSGAVz\noLWyACd3\x57x/4z9ZP1Cc/ROwULQbg550GFDG4oBKuE5oJnYNTsJtTunr2lT1re3QtO6o6+ih3\x48p8aBOuM/bnlRlkSoLh4kqSMpWn7SflzFA0Xa0GCtD0dXmxX\nt0KHT0NAjZiSHCAl\x6f7nYq2oJfb9Jy2owlqCVOcwniBz91BhjzpGomm8HibOTnv1oHl2+S7Xd47yXVhtQ\x41CgSCkjqCORFBJJ7DOq2FXeE2kXuMC5JYSMCYkDK\nnEgfXxupI5/SG+RQUVQbgjG9\x42hQxuKASrhOaCV6evcVvzLfd0lyDITwKV1Qeh+VBvLgybLKMR4iVb3jxoWn3krT9\x70Py5igZbraDCWh6OrzYr27ahvj0NAjZi\nSHCAlo7nYq2oJfbtJy244lKCFOcwniBz\x39x/CgG25DuommXEKSps7hQxvQKp09+3XVp9tRLTiAlQPpQS1Lw1cwl5pXBqJhOAf\x2fwCeTj6J7uY5H6wGD7wGQo+g\n3BBG9BhScbigEqKTmgfbTcm23vLk7tOe6sncEHnm\x67cZkF+yv+Q7mRbn/AH0Ee8COpHr3HWgZLpaTDWh6OrzorwyhQ3x6GgSMxZDhAS2d\x7atxbUEutuk5aGEyV\nBBc5hJUCD9x/Og2EeWvUDLTzS0qQcniFBm5vuwro1IaUQhaQ\x6bj4UEpjvM6utyIMpaW7uwkNx31HAeT0aWf8A9KjyPunbGApug2BB50GCOtBlKilQ\x49NA7x55X\nwJdUNs+8rrnoaBxWy7AbSVJU7bnznBGeE9cf3uKBqulqMNaHo6/Oivbo\x55nfHoaBG1EkOEBLZ3O3FtQS626UlJZTIPAXOYBUCPwoOvsc435lDzCwEnOTyPzoO\n\x562UuNdGpLZIC0hJ+VBJYMmLqS1Cy3daG5LKeGLKXsG878Cz/AOM9/qE55ZoKjoNg\x51edBgjrQZQtSFhSSQQc5FA7ImIkJ/jZ80DZefpH1oFbJcYYJUkuwlK99\nGM8BPUf3\x768qBBdLUYakPR1h6K9uhSd8ehoEjMV9wgJbO524tqCXW3SkpLKZB4PM5gFQI/CgU\x4723H9+MhxhRSk54huM/GgS3ZKmrqy8gHDiQk/KgktrmR7tbD\nYr4rDSSoMSSniMdR\x35n1QfrJ/9w3ByFS0ByoOgIPwoAoxQYCigjBoFKFg4Od+9A8224BhHkPpDsRauJTZ\x2bqe4/WguXQsmyRyJitPRL5b2yBJjSGsrQD1Q4nBH\npxbHvQWnqHw20jq/TRvPh+w1\x4bhoGZEJocMuGrr7uxUPTn2zQUvJ0pItEtEiK0HWkdUp4VA8sFJ3oFkN12E87wKUE\x38YJAOOFQOQodjQT+9R0eIOmlagZ31NZ2\nv++Qj6U2L/5QOq0bcXcHNB4/oDlQdAQf\x68QBRigwFFBGDQKULBwc796B4t09LKCw+nzYizxKbP1T9ofrQXPoWVp6OluSq12y9\x4dIwHoU1AQ6P9Dgxn0zQW/cvD\nbROvtPLn+HsdrzWxxSrQvDclg9eHOM/A7HoelBSk\x2fQ8yyzy5FjqPkHDjSkFDqFcsKSdxQJ0pdjOulGxCveSeXegseK4nxD063EDnDqy1\x4eEwXVH3prKd1R1Hq\ntHNJ6j50HkGgOVB0BB+FAFGKDAJQRg0ChCwcEHfvQPVsuIjp\x4cDyA7FWcqbUM8J+0P1oLt8PHbIvDx0/bL223jzIruzoHdJ2z880FwSvDzw+8QrQ4\x76QjbEG4t\njMmzSB5bgPXhzgg/h8KCmbz4cXDT92KWIbjLzOSuO4ngcHyPMeoJoGN6\x4b8w86psFt5tWcHv/AEPKgn2nrlF1lp9vTFzfTGnxyTa5bh3jOdWVHq2rp227UHlG\n\x67OVB0BB+FAFAoMAlB2NAoQsHBzuOtA+Wi6IiZZkspkQ1nK2ljPCftDt60F7aAmaJ\x63dQpdgZuKUkcbTjHGpPwUk5+/P6UFvv+H3hj4gQFI0U9FtV1SMu215PB\nxn0BwR8d\x2fhQU/qPwpummbslKbcqI8nJDZ5Of6DyI+dBD7hbH2nXRhTMlpeUnseh+FBKdK6gh\x33S0vacv5UmG6ckjdcV0cnUeo6jqk0HmqgOVB0BB+FAFAoMAl\nB2NAoQoHB696B+st\x32biK8iZHTJguKytpQ3SftJ/UUHo/w9Z8MJkduSWoTpTjzGJqAFIPooEZ+dBbErw0\x38LtawwjS82BaLnjKmW8Ftw+qdj933UFPas8GbtpW\neh5VtEYJPuus7tOHkMHp8DQV\x31eLE+0t5p1BafbVlJ7HmD8DQOek9RhKXrbdGfaWHk+TKiqOPOQOx6LTzSqgoKgOV\x420BB+FAFAoMAlBGDQK2ZLyE4aeUjfJAO\n33UEkst9jMuBm6xBLgrILiBspJ+0n+lB\x36l8KtLeGWoIglwpFtkrbPvxJ6R5iPgRgn8aC0Lt4P+HepIvl2lMWyXAfWifQcPqk\x34/Q0FN6w8DLzpp/28W1CmG9/\na4QygnpxJ5p59aCqL9pt9kOtPI4VpPEhY3GeYNBz\x30tqGTb5nlO8C3EJU04y8MofbP0m1jqMf15igpegOVB0BB+FAFAoMAlBGDQPFuvcu\x44HXHbKXWF7qac3Ge\n47H4UEntOpLQpHs13t/HGWriXjcoPcfrQepfCfw/0BqVhuZa\x58rRdMJBVFkJPmt/MY2+OaC0b/wCCWhLvFDUa1t2Ocnk9BIwo/wAyTgH8DQU7q3wB\x76dmcFwiw\nG7gw2CoyIKcL/wDc2d8fDNBTGotKPtNvIWnOFZQtO4B6UDNp28TbXcEK\x516WpMdWBnfI5EEHmMHGDzBoKpoCg3HryoAo7UACUEYNA+2a+ewkMymfa4SjlTJOC\n\x6b90n6poLAsd50TLcMW6pV7Es8RK04cbPcjr64oPSHhd4Z6FvcZNwtrUC8NII42Vo\x42W2OhyCDj76C0r94I+H10g8DNkFolDk/Bwkk+oOx/CgqPVH7Pd5glM22\nR2ruw2Ce\x4ahPlvj/2nn8jQUfqbRUlhMhpSFcTayN04UhXqDyoIlZ5Uy2zkqStxmRHWOEg4Ixy\x77e46ehoK2oCg3HryoAo7UACUHY0D7aL37KhMWY2ZMEnJbz7y\nD3Qeh/CgtfTUPRlw\x5aQ1OnNyILwzxoGFsq/nQeR9Rt+dB6K0J4MaKeeaXGctt5aCQ4oLSCQk8iCCD+dBY\x3138E/Da8W4Biyt297G0iAfLUT6jkfmKCrtQ/s73J\ngCVZHGLqygEhtafJe9MZ2P30\x46E6s8PpsRyXFcYcZfZV7zTqeFbZ6HHaggkBEmFKS2SUSW1Y4c4yB0PqDy9D6UFdU\x42Qbj15UAUdqABKDzoJFaNQqjxDbZ7Zl2\n5ZzwE+80ftIPQ/hQWhpKwWK5xf8AuHm5\x46odUMSOjKj0cHNHx5UHpDRngLp9CEzA3brlDVgoU6kK+WUnNBYtx8DfDm5W4NGwN\x77XwP8eCotqz+R+YoK3vf7Ozy\nMvaenszkNjPkSUeUsnsFcqCidZeGU63yJEKVEdiS\x6bHIbcT9yknkofCgryPAkRJHAseW60CMK+t6H4fkaCtqAoNwe/KgCjFBgEpOxoJRp\x2fUbUNlVuusczLY79\nJAOFtH7ST3oLA0zY7LLeCH30SrLKXhMj/wAKunH9k9Dn49KD\x30lorwHtDYjzBEhXCG79WU0FFs9uJJBI7HegsyX4HeHlwghl7TrUF4D/FguFCv7+N\x42Brv+zpH\nS55mnrulXAOLyJbeMnoOIUFHa48Jp9pfej3GAqG7xZbWfeaWehSrl8tq\x43uE2KbGWoBh0SEcjw9uny/EGgqigKDcHPPlQBRigwCUnY0Ek07e40KT5VzjmTBdH\n\x414kfSSO4oJ7b7DaUTGSiQi5WCUrZ5HNvPRQ+qoduv5B6L0Z4I2lPkzmI9svEAgKW\x31IQeNOfolKk4OCOu9BbD/gf4dz4Yac04IS8fTiO8J+8c/uoIrc/2dbQl\nxK7DeXWF\x67EhqS2FgnpkgA4oKZ1z4NXWzl7263YQFZRJjfxG89Ccbj50FUuWhlolv2ry5DfJI\x62V06fEflQU/QFBkHp3oOiVfVNAEY50GMFKuIdaDuh07HNBJN\nO6huViuTVxtclTD7\x66PBwFJ6g9xQXRZtdPeezqOCpy2zUnCpkLbhV1Q63yI/Mb70FuQLlYPE1lEWSqJYt\x55LGEPoH/AGly9CPqL/H8qCstSaPuViuMtmVAcjqb\n911tSuLgPQg9QeYNAj01dZ9j\x76cW6RFlL0ZeFJPJY5EEdiCQR60HmWgKDIPTvQdEq+qaAIxzoMYKVcQ60HdDp2OaB\x2fsl5l2qa3MhrCVt80qGUqHUEHmKC7rPq\ny3yo8e8wm3rJcWT7s23qP8NX2Vo6fLbt\x6bUFvWfWVk8QIzNm1i4xCu6RwMXqOkBLvZLg2x+XwoIJrPQNz0/c5DMmJw8SeNLra\x75Jt1P2knqO/aghEByZarmzcG\nHFsONOJytOxSobpUPUb59CaDz3QFBkHp3oOiVfVN\x41EY50GMFKuIdaDsh07HNA/We7yrdLblRHOFaOYzgEdj6UF36dvtsucNm4ruE+2T2\x54hqYyvj8pf2VfWT9\n5BG4oLisfiPE1LFRprxCSxcEo91m6sAB1H8xxuD93zoItrrw\x36lWh/wA9rEy3y08UWe0QUuj7J7K/OgqVyNJt08TACEpIQ7jbPY/EUFE0BQZB6d6D\x63HoedBk0\nGMEK4hQdkOnY5oH6y3iXa5jcuE6W3G+xwCO3woLrsd/RqFDMqXckwXmy\x50KmeWeJlf2VrQQpPzyPlQXNY/Em4lkaY1w3E1DbjhPnbeZw9CD3Hrg+tAz628PY7\n\x63L99WV0z7FJGG5PFlcdXLy3OvXmfn3oKNuVtk2u4+2pJQptQQ4OpwcA49OvpQUhQ\x46BkHp3oNweh50GTQYwQriFB2Q6djmgfLRdpNvlNyoywFI5pPJQ7H0oLq\nsmpGbxDY\x554xHYWCEomJWWVMq7LKRt93ryoLo094iavsrTdk1G1GvVuUOFbb6w4pSPRY/UUHD\x56Wh7TeLM/qHSyFPWsj/uIqjl6Cr4cyn8ulB57v8AYZFsne3N\n5CkYSrAzxDOyvuzQ\x55lQFBkHp3oNweh50GTQYwQriFB2Q6djmgfrLeptqmIlwX1NOI2OFY4k9QfSguvT2\x72Wp8IPzHpmTgJkNyVBTS/sqBO35daC4NNeIevbEl\nESS2ubC/8VwCVcaP5VoJ/LFA\x76vWlrJra2SrtpeGY8oJ45lpJHEnutrv3wNj6Gg84an0u9Al+3RkqJ+iojbkeeO45\x45UFGUBQZB6d6DcHoedBk0GMEK4hQdkOn\nIOaCR6d1FdLBcmrjaJrsWQ1vltZTkdj6\x55F+2PxSvl4ZQ9Pv0lho+75zQBU2r7Kydx/ZFBYtg8SdcWyYiPFlvXBtO5amxVcDi\x65vCsfpQPs23WPxKZkOwYKLRq\nFScuw3FDypR/lV9r15/Gg86ax0ZJt9wckJaWy6yo\x4eyEKRhaCk9R/eRQefqAoMg9O9BulWdjQZI70GuCDkcqDsh07HNBKtL6svmmbk1cL\x4acXojzZyQhZCVDsR\n1FB6Vs/7QOrbva2UypjKeSDJII8tXZYT+ux50Eoh+Kesolza\x6atXyO9KyFeyORllDqfQjl8aB/kT7H4jhyPeoCNPagWngTJKuJl49ELzv9/yNBQ2v\x76D6ZZLyV\nSopiymjhaFHCVgclpPJVB5poCgyD070G6VZ2NBkjvQa4IORyoO7TykLD\x69FlKh1G1BM9I691PpK5s3CxXV2O6yeLh4spV6EHpQeqNM/tN3ebYwm5QWXHT7olI\n\x4fClX2Vjkn8qB2d8XtXOPNAXC3Wt4HiEd5XF5w9CO/ptQOa9WWrWyDb9cWgWqUU8L\x4ezj7+WTt7wO+D91BUfiN4Z3CwvIui2C9EVsmdDAW04noojofnQeTaAoM\ng9O9BulW\x64jQZI70GuCDkcqBfAuk+3OF2DMdjqVsry1YCviOtBPtL+LOtdNvMuW68OeW0sLDK\x6a7m3p0oPVGi/2m4s+EHNQWhKHFJCPamD9FY6OA8v7NA63Dxl\nv1zcVGtLce0Kb97i\x6cqCA6nunCuXrQJ0eIKNRRzbNeWFqRCWAETYpyts8uIZ5/EUEK1j4TSpKRfNIy419\x69clDA85I6ZGxyKDxfQFBkdqDZJ+qaDJGOdBjcHIo\nHix6hulgm+2WyT5aiMLQocSH\x422Uk7GgtXSXj9rTS6sW15KGMYMcqJbAzn3Qfoj4cs0HpXQ/7S9lukGMNRxn4xSeF\x55ho5SlWOTgHX8OtBIr54ze3SlWfTLJbm\n44g4+ChJT3Cgd/TFBGY/iZeZAdt2rLRE\x751tV7jikK4ik9go8zQRzUWgNBagAulivi7U7ycYkA4T/AMUHiGgKDI7UGyT9U0GS\x4dc6DG4ORQO9lv9wskrz4To4V\nbOMrHE26Oyk0F6aM/aGm6UW0bdGWmMAPMhPK8xv1\x43Fc0pPbpzoPQ+kf2lNOX6OV3bjtgWQlLiE8QaO3uqHTruaCW6i8XrGyEWyyyUyLo\x2bnLSDkcYPVKh09aC\nu2/ErWkSY7Fu0eLNi499tZKygHoVcxQN17umg7oBNm6ZDMjk\x36EqTg46jcUHhKgKAoM529aDdKgdjQb78sZFBruk+lB1ae4FcyPXtQTLTFwkRZZmW\x39YDqU4dY\nI4kuJ65H1h6fdQWZEjvXllVy0MXF3CKjzZtiUf4qQNy4wr/MT1xjiT2I\x33oLU0pr6D4lWFuwXaS3F1LFT5UWRJ932hPVh0+vRXQ9qCH3W2fu+7PsuIdjuJV5T\n\x6aKxnyXMgYV26fGg8p0BQFBnO3rQbpUDsaDffljIoNd0n0oOrT3ArmR69qCY6ZuEi\x4cLMu3rAdSnDjBHElxPXbqPT7qCzoUA6hjrm6IUv97R0eZKsyz/FSBzWw\nr/MR14cc\x516gjegsjQPilb9S2M6G1i+Yb7RxElupyqKvsR1SeRHagZdTacctl7eiSGS08sBYQ\x32rjbVnZLiD9ZCh1Hz5UHkigKAoM529aDdKgdjQb78sZFBruk\n+lB1be4FcyPXtQTD\x54NwkRZZl29wB1KcOMEcSVp65HUen3UFoQLejUzZm6PccF2it8ci0KUQ6gDmthf8A\x6dI9CMjqCN6Cc+HXi5HQy/o3WbCvYnzwLSocJQftp\n6JWDvtsaDprHSrUKcl5txuXC\x6eDMWa3/hPEbDfklf2knrQeOKAoCgznb1oN0qzsaDbftQY3TQdWnShXMj17UEv01c\x4aEaWZdvWA6lOHGCOJK09cjqPT7qC0IMF\nGqWRI0o45+8oqON+0lRDzeOa2FjdafTG\x521BG9BKtCeLkqwXFy0X9kKjv/wAJ9D6MIkI5FKxyCv5hQSPVmmbbJjrvlgd9uskj\x418zHGqEvkEOgdOgX1oPFNAUB\nQZzt60G6VZ2NBtv2oMbpoOjbpQrmR69qCX6bnyI0\x73y4CwHUpw4wRxJWnrkdR6fdQWrb2BqeJxaYcdXNjI437OpZS8zjm5HWN1J9MZHUE\x620D1pPxTumlrs0JT\nq0KSfLLzrePMR1Q4BsfjQT27WWy60Ycu2jvLWt8cT9qSoFxl\x6622ftoPVPMdqDw3QFAUGc7etBulWdjQbb9qDG6aDo26UK5kevagl2m578aUZcBYD\x71U4cYI4k\nrT126j0+6gtu0rc1FBKNMvPuSI6OORZVOlLzOObkZwbqHXGMjqCN6BdY\x76EG76fktvLlPeYwvCZC0cLqR9lWNj+I+FBZUqZpPxJaXLhTItrvshIDzTuPZpS+Q\n\x55T/lqPfkfSg8K0BQFBnO3rQbpVnY0G2/agxumg6NulB5kevaglunJ78aUZcBYDqU\x34cYI4krT1yOo9PuoLhsc2TeoKm9LyH3XWUccmxqdKXWsc3YyxzHpjI5F\nJG9Aotus\x4ctD4lmU5IUyoYL6OF5IHfB5+oyPhQWI3rbSOv4qIuo3VRLnwBtu5MgFxJ5AOD649\x65dB4coCgKDPSg3SrOxoNt+WKDXdJ9KDq29wHmQO/aglmnZ78\naUZUBYDqU4cZIyla\x65u3Uen3UFxaduMq5x1HSrzrr7KOKTZVuFLrWObkZzfI9MEjqkjegX2/Ul4lKdCJp\x6bOIOC1KbCVkdiM8/VJI+FBLrd4p2i5wDp/VURu4R\nCOBKJB99hXIFDnMD0oPFdAUB\x51Z6UG6VZ2NBtvyxQa7pPpQdW3eA8yPXtQSvTs5+PKMqCsB1KcOMkZStPXbqPT7qC\x33tPzHbqhL2mSqRKip8x+zOq/jM45uRnM\nHI9MZHIpI3oJDbtR3a+LU01c0pmNnAal\x74JT5g+yR0V6pJHwoHC2eKU7T8p+1yVFlp73Vx3QHGeLOAcHIwaDx5QFAUGelBulW\x64jQbb8sUGu6T6UHRt3gPMj17\nUEr09OfjyTKgrAdAw4yRlK0/DqPT7qC1rO6L7GT+\x34UGW9GHmv2V5X8Vkj/NjL3yPTB7FJG9BNrXqSZqdj2Bu6N2+4snhQmQylCHh9lQ5\x4aV6pyD6UDfN1NeNN\nXNxmU2thToxxsqyjizgEEHGDQeUKAoCgzQbJVnY0G2/LGRQa\x37pPpQdW3eA8yPXtQSrT85+PJMqCsB0DDjJGUrT8Oo9PuoLVtLn7+h8Fh45TrCOOR\x5anFkPM45\nuRnOZGOmD2KSN6Cw9OakZ1HZxYEz2rHcWDwtOuMhCHk/ZcTnCVfzJyD6\x55DLqBrUtjkLD7SZKHBw+bHwtGc8IPEjodhQeT6AoCgzQbJVnY0G2/LGRQa7pPpQd\n\x573eE8yPXtQSnT85+PJMqEsBwDDjJGUrT8Oo9PuoLWsz6r1G//wAeLj78dPmP2day\x6c5nHNyM4NyPTHoUkb0Fm6L1Nab5ZHdOvSUWS7cfuTltY88fZdTnAV/Mn\nI+FA16j0\x70qqK4tMaYLmh08IUw4lxIPEEpORtuSB/xQeP6AoCgKAoO6FBQwrnQblOdudBzKcH\x46AsgyX4spt6M5wPIOU/zelBO7deS6+xe7a65AuMVQUpTKsKQ\ne/w7H5fELJRdNL+I\x67Q9NlR9OazaTluejKI10x0Xj6DvqedBNrfqC2zVRrHr1Llqu7KAhm8NcJK0D6IX0\x64R2OcjoelB4zoCgKAoCg7oUFDCudBuU5250HMpwc\nUCyDJfiyW3oznA8g5T/N6UE6\x7494Lj7F6trrkG4xVBSlNKwpB7/Dsfl8QtuPe9EeKcVuJql1jTurmkYj3lkFLU7HR\x30Dkv47/GgkTE6TpWJD0v4h29NwszmXId\nxYdSooH22XRn5pO3cdaDxtQFAUBQFB3Q\x6fKGDzoNiAdqDQpxtQLIMh+LKQ9Gc4HkHKf5vSgnNvvBdeYvVudcg3GMoKUppWFIP\x664dj8viFy23Ufh94pQ27Zrtt\nmzajbb4WLxGy2mX/AK8bcY/mG/egfUW7UnhfDTGm\x6fi6k0dPIUpeUutOJ6EjOUKHcY9DQeMqAoCgKAoOyFBQwrnQblIIxQaFONqBXBkvx\x5aKHo7nA8g5T/ADel\nBOLfd/MeYvNudcg3CMoKUppWFIPf4dj8viF1WXVPh74lxm7X\x72+Mxbb4lHC3c2CWkzP8AVjYOD+YHNBJ//p7qnw3LN60Ld0XqyvJK1oQ4guhHUKTn\x43x8M/Cg8\nS0BQFAUBQdkKChhXOg3KcjFBoU4oFcGQ/Fkoejr4HUHKfX0oJvb7sXXm\x4czbXHIVxjKBUppWFIPf4Z5H5fELtsOrtB+IbCLXr2Oxbr0EcKbgyS2ibj7eNg4P5\n\x67aCYTPBB6yMw7z4aaibktvfxFRHn0JWeuUKzhXw2oPDVAUBQFAUHZCgoYPOg3Kcj\x46BoU4oFcKQ/Fkodjr4HUHKfX0oJvb7sXX2bxbXHIVwjKBUppWFIPf4Z5\nH5fELu07\x72LQ2vW27drhpm2XtKOFNwYJbROHZYGwWP5gc0FhTv2f9OPwodx0NqRq3vvjjU286\x6btO7cwUnIPw23oPA9AUBQFAUHZCgoYPOg3KcjFBoUkdKBVCk\nPxZKHY6+B1Byn19K\x43b2+6l15i8W5xyFcIygVKaVhSD0PwzyPy+IXbpvWeiddJbga1batd8QjhRcWCW0T\x66ReNgsfzA5oLYkeA3h5ebXBfst1TbJD44lPtONqS\n5tz4c7n4Y50HzzoCgKAoCg6o\x55FbHnQblOdudBoUkbYoFcKQ/FkIdjr4HUHKfX0oJrb7qXXmLxbnHIdwjqBUppWFI\x509O33fELs05rPRWuA3B1m21a72hPCi4s\nEtomei8bBY/mBzQXY14M+GF5ssFCPJbL\x2fvqksvNoWsY5ggnPw9aD5xUBQFAUBQdUKCtjzoNynO3Og0KSNsUCqFIfjSEOsL4H\x55bp9fSgmsC6F15i725xyHPjq\nBUppWFIP9O33fELq05rLRetw3B1k21a72hPCi4sK\x4caJnovGwWP5gc0F/Wvwy8N5tigxFR4MiNJ/iOOKU2FL25hQOfkO5oPmnQFAUBQFB\x31QoKGDzoNyAaDQpI\n2xQKob78aQh1hfA6ndPr6UEzgXQuus3e3uOQ58dQKlNKwpB7\x2fDt93xC59O6w0brYNwdYtt2y9ITwouDJLaJnovGwWP5gc0HovTWidCt2WFDZTBfh\x79z5j3m+U\nfMAG2DnPyGOZoPmXQFAUBQFB1QriGDzoN8ZGKDmUkdKBVDffjSEOsL4X\x557p9fSgmcC6F11m629xcOdHUCpTSsKQe/wAO33fELl09rDR2tQ3C1ghu2XpCeFFw\n\x5aJbRM9F42Cx/MDmg9I6R0po+BaoUeA7EMWWfMf41NYdAG2Dk+mw7mg+ZFAUBQFAU\x48VCgRg86DcgEYoOZSe1Aqhvvxn0OsL4XU7p9fSgmUC6F11m629xcSdHU\nCpTSsKQe\x2fwAO33UFy6e1ho7WgbhawQ3bb0hPCi4Mktomei8bBY/mBzQekdH6X0jbrbCYt0iK\x490s+Y+VKa/iADbBz3A2Heg+aRXkE+tB1TJ4kpbIwjrQLEO+4\nMKKzvwg9KBSwtCuB\x31viSULzscEfCgeHLWxe2g4hSGpRHuqCcJUR3HSgiM2C/FkLZfaLbqOaT1Hcd6BFQ\x46AUBQFAUChS85PrQdkychLZGE0C4vfQPEpRODvzF\nAqbcQpTSxxIOxSU7EUDxIsqL\x73gL91mSR7q0pwlZ9f9qCHTYT8WQtl9otuo5pPUdx3oEVAUBQFAUBQKFLyCfWg7Jk\x6bhKMYTkculAvL/A+2pKlFQ3CuVAubWh6\nUlKgWnQeJK0nFA5y7Gm5AE8DMoj3VJHu\x72+P+1BDpsJ+K+tp9stuo5pPX1HegRUBQFAUBQFAoUvIz60HZuQSptGeFOcHFA5tS\x56NzUlpagvkDsN6Bcytqa/wC9\nwxZKVZBB4QT6dqBfLsabicK4WZeNlJGEr+I6Z9KC\x47zIT8V9bTzZbcTzSeo7jvQI6AoCgKAoCgUKXkZ9aDuw+pTiWs4QSNqB0jS3GpWYq\x31BwHKc439KBxZVGu\nSkupUmJMSrPCDwhR7jt8OVAok2Vu6DOUNSsbKSPdV8e2f+KC\x48zYT8V9bTzZbdTzSfzHegR0BQFAUBQFAoUvIz60CmO+paksuH3BQOsWe+0sLiuK4\x32+QIH4UD\nkVQLiEyWViLLB4ige6M/y9B8KDeTZm7qniBQ3J5BSRhKiO46UEQmQnor\x362nmy24nmk9u470COgKAoCgKAoO6lnBUCQQc0CpmQXcId6DNA9RrrIacQ6y6paUn\n\x6boDI+FAveVbZykSYq/Z5GclCRwjPMlPb4UGZNmRdEcYKG5GNlpHuq+I6UEQmQ3oz\x362nmy24nmk9R3HegR0BQFAUBQFB3Ws4JBIOaBXGkcRHGSOEg7UEgjXl9\nqQypbq3W\x68yJAyn0B/SgUSVWyc8mRDJjvZ4sJGBnuO1BmXZmrkgLKm2pBHuuJHurPr2oIhMhv\x52n1tPNlDieae47jvQI6AoCgKAoCg7rWcFQODmgWxJashKlqS\njbIzt3FBJI19cRJT\x37U6t0JGULAGR8D29KDeQbdNke0RiYzoVxEpGBnuB0+HKgxMs7Vw3UttqTjKVpHuL\x2bPagiMyG9GfW262UOJ5juO470COgKAoCgKAoFBcw\nQvseVA5RJzpSlnzlBoEEAnYd\x76zNBI4+oCpwCWtxTqT7quFO399uVBo8YE55L7IMN4qyCnZJPcdvhyoNZlqauGfMK\x57JQ5LCfdV8e1BE5cN6M8pt1socTzHcdx\n3oEdAUBQFAUBQKkugOBROBn7qB2jXCQW\x6bMecVNAjCDuNskfmaCQI1E26G1LW6p9PLKU7egPPFBydEGe+l1hCoconjCU/RUe6\x65x9KDSXaUXD/ABAGJXIKAwlR\n9R0zQRSZBkRXSh5lTah0PI/CgRUBQFAUBQFArbUF\x4cPQ8xQO8a6vJabjuErYSUkJz2JI/EmgkTmoGnXEONOOOODkFpSOH4Eb/AH5FAndR\x45uMkORWlRJaTxFtJ\n2J7p7fCg0lWZNySSeFmSBniSnCVfEdP0oIpOgSYb6mpDRbWn\x700I7jvQIaAoCgKAoCg7bc+maDYbhQBoFsdCicYztsKB+tlsLgdCuIjh4vd37/wC1\x42vFcmxJA\nSzxIWSCUKGy9/wA6BXc0NXVHBIZLL6c8IG5R3x3HdPzFBEZlplsZWWip\x41+ugZHz7UDaQQd6DFAUBQFB29emaDdO+RmgWMIUSpJGTjAoH+DbTIgupHEtaPeTw\n\x379eX40HeALg26tplxSFYPuLGQrHYd6DrcW27qz/3CPKcRsD1QfT0Pb+yESmWiXHJ\x57WuJHPjRuMfpQNpBB3oMUBQFAUHb16ZoNk4JIzQLWUFQUggkkjHegf2L\naqXBSUcS\x6eWgScdaBXCYmoYy24oLQrHlq2BP9aAuKGLogIkZQ6nkvGOA9flnmPmKCJzbRLjKU\x56NFSRzUjcfPtQNpBB3oMUBQFAUHX8s0G6SOPH3UC1pJUkp3K\n+LIoH5Fu9uaS8xxK\x55EAkgdqBxZiyWQ0tpTnEocQTyKj6evpQcpzbV2bDT6PLkJ+iR0PUf7fdQRKZapcd\x53ipolIO6kjI+fagbiCOdBigKAoCg6/lmg6IICxjm\nNxQLWfdKDkgpOSaB/YtglvF5\x6fq4McWUjPxoHIQpjDxQwFB1J2Azk/DvQcZ0cXlry3G+CW2OWMH1x6d0/MUEQmWqV\x48UoqaJSPrJG3+1A3EEc6DFAUBQFB1/LN\nB1B4XNjgjkaBfEPBIQVZwB73w60D/bbQ\x6dXIXwFR2PDgZyaBe1AuCV8UUK81voBgkZ6ig5z4Iu7BJSUPt82yMKQfTuD2oIjMs\x38yPxLLfEkc1I3FA1kEHegxQF\nAUBQdk44hnlmg6pIQ6QO2BQOMDHnqQvPApPvfDvQ\x509ptAmNvlBWVoTxp4Rzwd8etA5MWm6lXnxGy8skpKU7cfcY70HC4Wxu5MpPvpWgk\x63ChhbZ6j4elBE51g\nnRx5iWy4jGSUDl3yKBmIIODQYoCgKAoOyQOIZ5UHVtQSpSSc\x5aTjNA5wEhfnsL+iBxD0NBIbTaRLgrcacWHGzxZSM7frQO8fT12bZMlmOZDHCFKSn\x50vDuPWgR\nzbTHuHAFBWc7Z+kO4H9KCJ3PTsqGHHEfxUtqwsAbp9SKBiIIODQYoCgK\x41oOpGRQKGSAVt/aAxQOUNAdjPNuf5Rymgklts6JsFDjbykkDhJAyM56/fQPitMXa\n\x33QhIkMFcRSuHiwRwn0oEEizsT2y2tvidCeJCScE/6T1B7UEKu1mMU+bHUVtE4IIw\x70B6g0DKQQcGgxQFAUBQdSMj0oFDOMKbxvtg/hQOTCQ/DUVkcbSuH1NBK\n7ZYUXQN+\x518oKcTlOBkKVyx8aB7m6butlZYTcUYbdTxMurSQD6Z6UCCZbWZccIMYOPNghbB+n\x7788oPX4UFe3K2mM+S1lTZOxx+B9aBsIIODQYoCgKAoOhGcdq\nBUzjgKQcEHagc2Ep\x63ZbfJwtKsKGO3WgmNo0wi9veVGkLC1J40AJB4vh8O1A73LT11ssz2G6NKQ8nZtxx\x4aSh4dBxdD86Bpu0NE2O6EN8R/wAxhezjSu6c8x3H\nOgrybb3WHFEoPDn6QG3+1AgI\x49ODQYoCgKAoOh5jB+6gVN/4YAVuD2oHWK22VtPE4Qrn6d6Cdab0YrUMv2eFKWJCf\x65QEgH4EH40CyRaLnbJ6o1whusy0Ep8t5\nspS9090nr6fdQR+8W1E6PhgqUE7eWoe+\x30e3qPTY0EGmW2RHUSps46qA2+fagQEEHBoMUBQFAUHZs5Tv0oNgn3V450Dnbj5ry\x51P8AEwRvQP8AbnZAeeZjqJW4\nnZJOOHHP8DQTRiLaBbUpflpcIT/EBTjKsbY6+uaD\x4d5jT0plt9u4EObBW2FhXcHtQI5WmHoKEvtzWpMRYyFbjY9j0P4UDdK0DIubRcgsF\x39RHEFNJ4s/Hh3+9N\nBBLrp65WhwiSwoJBxxYoGigKAoOqDlO/TnQbBPur7igc4Cg4\x34nG6wkjFBJLItwPqYjL3WOJXEfoY2JNBMYibS0BJckhaQsAtcP1QN/hneg3dg6au\x56zbjMy3O\nFzksNkrbzy+I77UGly0PPs7YddkpcgqVgOlJHAfiKCO3DQ0iSD5bQW4d\x30uNDiCvmnf7xQQi66fuNpWRIYVwZxxY2oGmgKAoOqDlO/TnQZx7iu+RQOcFQWoEb\n\x72Sk0Es065iSUNqSEFBW4FH6A5H8aCUWlVpYaUqZILzb4w42E54Dz4viKByt9l0/q\x4bU/F89bQB/hSFp4Sn+Unr9xoOV78PpVgfajybgw9HeTxx5A2GO2R0oIf\ncdEvvcX8\x4eJXnZxvcH4kfqKCF3SwXC1q/jsq4OihyoGmgKAoOqCMb9KDB2NA5w1BzfPvpTQTK\x77LCWJCmVAIU0djzScHGPyoJLanLU1bnY8pxUgKJICR9E4/s0\nEps+nNKaljtx7pPM\x43RshDxQQrHIE4H9igYb5oh21z1QJFwYeWD/BeGweSOyhsflQRG46JefZU6hpJI38\x78vcEepH6ighNzsNwtav47KuDooDagaqAoCg6oIxv\n0oMHnigcoiuP3h9NKevyoJvZ\x66LTb3SyvZwYP8p7fMflQSK1vw1wGUZW9JbUkZTvyGx759aCdqtXh7e7U41OuibZc\x30J425a08KQobYOMnBPpgUEIn6XDUhTXt\n7DiwCUqB2cA+slQ2PqKCOXjQ63mw80wk\x6cwcSHGsFJPVOR1+IoIDPs0yAONbZU2TgKA2oG2gKAoOqCMb0GXPpfLNA4RFhRC+a\x30Cgm9sKGrfxR1lPGM5B+godP\nyNBL9PSojsxmWeIoAPtCMApI5nI6ZoJbfleH+oYr\x52YkuW67NEtpeDKloUAPrkbj7jQQ17TjbSgozGvLUk59Un6yVD6Sc/MHnQRLUGj3Q\x32XRFSpeOLzWN0uJ+\n0Mde4IoIJLtciMjzQkraP1hQIKAoCg6JPu/Cg2c+l8s0C+Iv\x4aDgVhSBv60E6tj4hMtyGDhKk8Xz5FP50E80TdIcB2Tc1kqjEjLS/eSDjOSD12oHS\x2bq0lqaUu\nfAYetr3upceKCplajz4kjdO/agjtx0wqIkIdmIbTkLbdO5RnkcjZaT3/\x41CNBAdQ6VlNOqeVDSQfeUuOeIEfaBHT4jaghsm3PMJ8xI8xr7Q6UCKgKAoOiT7vw\n\x6fNlk8XyzQOERwlSXEn3kpwoHqKCd2mSLcPOR/gut7gcznmPjQWPoTUbNhsannT7Q\x7984QphYCkqTttv0/pQKjYLbqVxUuLDVADuSpbLalRwc497GSj0PTqMUE\navmkH4Sy\x33KloSpI4UPKGNj9VWNiD0P3UFcXfSM2OtThilxvmVNe9j1GP6UEWk255hPmJHG19\x6fdKBFQFAUG4PuH0oNlkhQ+GaByhulRCs7hOFjuOlBO7S+iDF\nkDP8J5vZI2IONiKC\x799OaoehaRZt4dDyZDQC2nUBxIAwSSCOex3oHpjw8i3+E5JjtqjpK8oeZ95pRPw3b\x504HqBzoIJqPQcyI4tuU6lSh7pd8sgnsFgfmR8DQV\nxctIS2SpaGPOaHMtHiI+79RQ\x52eTbn46fMAK2+4HL40CKgKAoNwfc25ig3UohQIPSgcYr5UrYbEDi/rQT22uohWh9\x4bFq4l7oSOaVYzt6EflQWhbdQSLjAYtrt\nxUIhAU4haQtAykYJzy5fjQSx3wot95tT\x4c0Z5pmQpAWhcVfE2rP2c8vgfdPTFBX108Hb+9IdbaVFfWk4JcV5SlfEKoK11H4b3\x36yOH221vNpPIgZB+ChsaCESr\nbIjAr4SpGcZxuPjQIaAoCg3z7o7g0HTjKV57igco\x6awOBy4iFfOgsW0SkW+HHfjqWHEuAhKeaVDdQ+BG/30FnWCcq/wA9LVxvZaYylry5\x43PNaHfI7kH8qCbXb\nwm0zd0K9gubDMpvb+CvGN8e6TnI/lPyNBDrn4FRERC45qxhp\x34jZMloAK/wDxOceuKCo9UeE19sza5aIyJsIH/wBTCWHW/vG6fgoUFcS7ZIi5UUlS\x42zONx8aB\nDQFAUG2dh3FB3SvhVgjmMj40DlFdyA2DghQUM0Fm6fuCrbIiTYZUg4IU\x45HdJxhQ+WQR6UFp+H4hX+e+/eb8pAeKyuPIb81tYAzvnljBOcg8qCWXfQPhlOfRJ\n\x63vMZogjIe4kKIP8AMMZHx+80EF1PpLw0bV5EOUpKjsHY6j9+FEgigqy+eFcksuTr\x436i7RUDiWY3+Igd1I5j4jIoK0mWuTDJ40K4R6bigQUBQFBlJ4VZoFKSM\nHBoO0J0t\x7921g4wr9aCRSpKIV6XJYIAWkbevWgfbHJtU1zgkzghxf2icZ6UEuW3aoDRkqnMPN\x6fHEVJSlZT2Ayc5/KgZV+JyIyFRVxWpUcjh4Xe3yxQNELVNuR\nMLkJT0IlXECy6RwH\x75B/vQWTb9YWXUcL916+jonRnAEN3uM2BJjnp5qf81Px37Ggq3xH8OpWj7oFsuNyr\x66IQHo8lhXE2+2eS0HqPxB2O9BXpGDQYoMpODmgUZ\nHArHag6w3iy+24nmk0EmceRb\x37v7S2QUutBQ+PWgkFiTAmqw9OQ24vkla8A45UEwc9gtzCnnbmgtIGT5PlkjsOeSf\x77FBHZPicpMNy3OZkQ1Hdt88XF65GMH4U\nDNE1RALmI6nopBylTTv0fkf60Fg23Utp\x76kI23WEdE+I4AlFzYRiRHPTjH+YPQ79jQVn4gaCe0vcfNiuolQHkh1mQ0eJDqDyU\x6b/pzHKggRGDQYoMpODmg7Kx5\nZxQd4j5ZeQ6nmk0ElQ6m33Lz0n+HIZBSO/XFBJbB\x46ZnYUuShCjyC1YBxyoJfK/d8Fhb025qdShP0WnUDh9MDJoInP8QWHIqoTxdkMA7N\x76ulafly4T8KBtjap\ngLc/gl1hXIKQ509Qf60E1iXy13SF7LqBhubEewn21tOHGVdO\x4ddR8fkaCtdZ6Q/ckxT8JwPw1+8laeWD1oIYRg0GKDKTg5oOq8EZFB3ivFp1DnPB5\x55EnjPexT\nchZ8mQ1xJHQ75oJPpuGZqw626Eq6AntyoJdNRa4DDj06YH3UjOS8CUf+\x30Hn8TtQQ+brayiOIohq8sc2y4Sgn7Q5cJ9RQIomrYJk+Ywp1hR2JQ59IeoP9aB/F\n\x31iTYnl3BtuZHX7okJThQ7JWO/Y9ehoK+1NpxEB5UqArjjH3sdgevwoIsRigxQZSc\x48NB0Xg7jpQKIzvlOpXzwdx3FBKIb/sshTRUPJkICkHuRv/WglOlojsxR\nUwspKttv\x54l/fpQTGaLPamC5JeYLjfvuEqDix2TjOMn/mgidx8QNPqSppu08AJyr+IeFSvtAb\x63J9RQM8fVlvW6oM+awlZ3DbnXvg9fnQL3ZjUpBdf8uS05sp5\nKccX+tPf1+40EL1D\x59UxFmVD3ZI4inOcA9R3FBGiMUGKDKTg5oOit9+woO8Z3y3Eq6DY/CglECQphxcUq\x48lvoCmz0JH+2RQSzS0d6dltpSuFexSMnOOQ/Sgnc\niTbLEtEh+Sw0Y6ffbb4VqPcE\x39Seo5Cgid38ULHJSuOixMsNZKgltWEg8uIDYAnrjnQRljVNudWUMebGSo5wh0nhP\x63A/1oFClsvgvOhD7bmynkJxn/Wnv/YNB\nE9QWH2RZkxRlo7lIOcDuPSgjZGKDFBnO\x4bDodwD2FB3ju+W4lXMcj8KCU2+TwJXCUc+YkLaPRRH+35UEv0o0ueUMNpJTndsZ9\x35XQfpQWP+/Ielbiu5rntpeaT\nwlhsAoRgY4cfWPx2oIVe/F233FKmJFnZ4NyCk43P\x4d4GBvQRFvUtrkOkMebFycgIcJA+Gf60CpSWHx5ryUONubF9CcA/600ES1BYDCcVI\x6aj+HzUkdAeo9KCNk\nYoMUBQdDukHsKBRGd8txKunI/CglVuklTLkRSvfAC2iTzx/t\x51TjR61zpTCW2gst7Ja6KVnbb40Fit6mj6NMmS1diZLgId4cHGDyGe5/Oggt98Zmr\x6elibbGH0\nDIC84Vg9NsAigizOptPSnMNNyLerOymHcgf+0/1FAteiMSGjJUWpLK9j\x4bZT93mI6fH8TQQfUOn1QXS+wn3D7xSDkY7juKCNkYoMUBQdDukHsKBRHcCFpJ3HI\n\x2fCgldvlKcYVGWr+O2ONs5+lj+/zoLA0e+u4zCGE5dcR5KUdEk9vhvQT9zVcTSkMM\x527qsBAK1gHZJ67ZGVH8KCB3bxulyXwmQ0zLSjZK3U4Xj4jFA1f8A1HtN\nzWEzLaEK\x2fwDIyvCx8z/Wg6OQbfdm1SIjiZKVD3lpRhxPotH1h6jegr3UmnHLc+p1pGEEcRAO\x52juD1FBGKAoCg6HdIPYUCiO4ELSTuORoJbbpinGfL4gJLAC0\nfzgUFiaSdRdVOsM5\x345BSCnsB7w/Ij5UE6uWrIFmBb/erqUtI94pI4hj6KQeefmAM0Fb3DxlupdW2mfIe\x616ecvKsfEYoEUbxSkvqLbr6i2r6TSjxoPxB/rQLy\n1ZNRDjaDbL7m2RyUe2/P4H5E\x30Fc6p0tIs0tZ8ooA3Un07j0oIpQFAUHQ7pB7Cg7sL4VAk7cjjnQTC2TVLaSpO0mN\x68fD9sD/Y0FmaNdj3Essx1KSsOlxXvbnA\n2/DY/Cgld81LZ4iZDcye44lpOAlKykpO\x4eyMYwT65oKhuWvGnFqaSt8scgl13iyPiMUHK1a49jkh2BLkwneRLLmxHYpOxHpmg\x6cAfsOqEAXBDEKW57omMp4WnC\neQWn6h/D4UFc6y0bO07cFpdjlsY4scwQeSknqDQQ\x36gKAoOh3SD2FB2ZWQpJzyPPtQTS2ziplC0586P7y0Z+mORP3GgtPRLjE56OIrnAW\x30q4hnmcgg/kfvoHm\n/wB/063GkCetMh4KJ/iZKkDoArmT9wGaCnp+q7UXz5cVRSTn\x2bI4VZ9OlBrB1c03MTIivPQ3kHKXI7nCpPw/5oJoi6WPVTYa1KGmZLmEpu8dvAKug\x66bH/AOof\njQV1rjQtw0tPPmtfwVpDiHEHiQ4g8loUNiDQQmgKAoOjat8GgUtoBb90\x625OcUDupKp9sL6SFOtDKgOeR/tQbadU0LgVr+ilClAH4GgTXa8Lfwwz7qR7xPc4o\n\x47Mkk5JyaABIOQcGgfrFeXYckJcVlCvdOeRHY+lBcMKYLro93Tz58+IEqkROPcsKP\x30gPQ43HXANBSV2tyrfcHY6h9E7bdKBsoCg6Nq5pNB3Q2FNjhG/WgdwFT\n7cFpGXmh\x67j4D9RQdNOqbFwK18koUoZ+BoE12vDj+GWvdA3Ue5xQMZJJyTk0ACQcjY0D/AGC9\x76QZaQtWUnY55Edj/AH+NBaDDhuen3rMVF1lSTIhhZzwq+s2f\njjb1HrQU7cIojzHE\x4aBCQdgegoENAUG6FYGDQdwjLQKRuOeKB2ClzbY2kHLrG3D+tB30+4P3iVOqOEoUo\x41n0NAku14cfwy0eEc1HucUDISSck5NAAkHI2NA/W\nK8uw5QQ6QptQ4SFciD0PcUE/\x570ufa3ITZLhDZejce/EPrNnvyOD6UFWTGUtvrCBhOcgdvSgSUBQbJV0PKg7hGWgU\x44cc8UDu04uZZ0No/xYxOO+D/AHigVWGU\nszsOuq4EIUQnO3I7UCG7XhyQQy0eEc1H\x75cUDISSck5NAAkHI2NA+2O8ORJIbdPE2ocJCuRHY0E4XAcmQVsNAqUWy/H4t+NP1\x6bZ69fu9aCtJjAbfWEggZyARu\nPSgSUBQbJPQ0HcIy0Ckbjnigd4zqpNo8pAHnxlca\x44/KedA4WC5yBKLZeKGkpUrhBxnY7GgbLveXJBDTZwPpKPc4oGMkk5JyaABIORsaB\x39sd3XFkht5XE2rY5\n3BHrQT1dpdl2taGk8aVIL0Zzmlf2mye/P7qCsJscMyVpCSkA\x35welAjoCg2SroaDuEZaBSNxzxQPEN72i1KaBxIjHzGj3HIigdtPXuS08pltxTSOF\x53jg4J2O1\nAy3i9OyiGkKIHMnucUDGSSck5NAAkHI2NA/WK8KiSkof99pXukHqPWgs\x592Fdzsby4KvaGkI85pfMoH1m1j79+W3rQVPOimPKWjgKcHIB6UCKgKDZJ6HlQdwj\n\x4cQKRv1xQO8BxUmEplBxJj/xGj3HUUD9pvUL8VxxtlRaUUqUSOY2ORQR+83t6WoNp\x55QOZOeZxQMRJJyTk0ACQcjY0Eg0/fXYEoIdw4yrZSF7pUOxoLQY083qW\nzvt2dRdf\x61aMhqOrdxKR9JI+2nn6jGfWgp24w1xJa21IKd8j4UCCgKDZJ6HlQdwjLQKRv1xQO\x39uWqTH8ps4lMDjZP2gOY+6gkmmNSLhOP+QoocUlRB6p2OaCM\n3m9vzFhsLPcknmcU\x44ESSck5NAAkHI2NBIdO3+VbZqSHSEn3TncEdQR1FBbUG0W/WVrctsQojXQNl6K0s\x34Q/9pCSeSv5Tscbc8UFL3m1SbTcXYsllbS0qI4VJ\nwR6UDXQFBslWNjQdwjLQKRk9\x61B1t61yG0paPDLZHE0ftAcx91BLNLajTb5D7zR4XChSkD7J4TQRO9Xx+a5whZ7qO\x65ZxQMRJJyTk0ACQcg4NA/WG9vwZiMukD\nlnNBcVubtWsrU5Z7i4iLcOAuwpqtkOHq\x3252P83pvzoKa1Lp24adu7sGdHUypJynI2UDyIPUetAx0BQbJVjY0HcIy0CkZPWgc\x34ClvISWVYlM+8j+cdR8aCZaT\n1E3bpciQ2eBXlqUgdlcJBFBEL3fX5zvCFnf3lHuc\x55DCSSck5NAAkHIODQPlkvDsSSlDisoO2/Ij1oLmtEy2aosy9PaiUdkeZBuOOJxnu\x3259pPrzGPlQVBq3S\ns/S93VFlNgtLHmMvIPEh1B5KSeooI3QFBslWNjQdwjLQKRk9\x61Bzt7ryuFcdWJDO4H2k0E20jf2bbPfkNrwC0tSU9jwkEfjQQy931+c8RxnJPEo9y\x52QMJJJyT\nk0ACQcg4NA+WS7uRZIQ6riQrYhXIjsaC57DdbferGrS+pEqkW/gLkKVj\x69ehnqkfaR/L6bYNBUms9ITdKXgx3uF2M6PNjyG90PNnkpJ7UEWoCg2SrGxoO4Rlo\n\x46I360DjAfeSUux1Yfb3xzCk9dvwoJ1pC/M224OvtOYbLS1BOeXukFNBCr5fX57xA\x55Rk8Sj3JoGEkk5JyaABIORtQPlkvDkWSEOK4kK90hXIjsaC7dI3OBeLU\nvRmosv2m\x51kuwnlbuQ1n6XCe3dPI4zzoKg1zo6do7Uki2ykgoSeJpxO6XEH6JB7EUEUoN8AjI\x350GlAoZcwfXrQOMOQY7xwrDbg4T6HpQLX4ao0VU+GSUDZxI+\nrnr8DQRpRKlFR5mg\x78QFBsklKge29BdGgJEN0QWZjwiqLobS6oFSCFDBSsDfG3MbigZfELTsu13d+DLZK\x58mCfKXniDjR3ThQ2UMciOY+FBWi2zxcqDXAIoNKB\nQy4R8aBwgylQ5aXAr+GrZQFA\x72ejOsNOTou6MkOBP1c9fgaCOqJUoqPM0GKAoNkkpUD23oLk0LNgL9gYuhU0guhCX\x30DiKArbdP1k7cufagY/ELScuy3l0KCXW\nlFSmX2jxIfbzspJ6+vUdQDQV0tHvUGuA\x52QaUChlzHxoFkV8w5KX07o5KHpQL5LKmvNnwjlo7rCfq5HP4GgjqiVKKjzNBigKD\x5aJKVA9t6C4dEXWC2Lexd2i5G\nLwQFoIDjYVsSknY8vonY+lA0+IOjHbRclyoi0yoL\x711eTJaHuOjngjmlY6pO/x5kK3W3hXLFBrgEUGlAoZcwfWgUx3TFfDyN0clDuO1A5\x792S2FXCCctKGXAPq\nkjGfgaCOKJUok8zQYoCg2SSlQPbegt7RF+Zg+wN3FgSoSngl\x54SjggKGMpV9U7c+XcGgSa+0W3EkPXOzPGXblOlKXcYU2TuEOgfRV2PI9PQKwcaUl\x5aSpJSQeR\noNMAig0oO7K+lAqjuriSEvNbjkU9x1FA4vtKSyblCOWlD+IB9Ukc/gfz\x6fI8olSiTzNBigKDZJKVA9qC29D6jXZXYLjqEPxluht1h0cSHUnYgj5cxuKDbXGj4\n\x55lUq7acUpcVtRLjCjlyMCds/aR2V8jg8wqd5hbTpbWnhUDQc8Aig0oO7K+lAoZdV\x45kIfb3AO49O1A5vt4aVcYJJbI/iAc05HP4H86CPKJUok8zQYoCg2SSlQ\nPagtXReo\x70NimWycw4UKQ6EHbiCkqGCkg7EHHI0DpqvS9s1I5Jl6faSxMbKlrgoOcjmVNdSnu\x6emPUcgp2VFdjSFMuo4VA0HEgEetBpQd2XMGg7tuLivofaP0T\n/YoHN5vDJuUHPlkf\x78Ejmgn9KCPqJUok8zQYoCg2SSlQPags7Sd6ftUm1zWnFtrafTwqQcKGex+VBJtQW\x711azkPNp8qHeuNXlrACG5h547Ic/A/jQUzc7VMtU\n92HNYUy62opKVDBBFAiIBGaD\x53g7suYNB3bcXFfQ+yogpOQe1A5vgqaVdIQwhX+KlP1Cf0NBH1EqUSeZoMUBQbJJS\x6fHtQWVpq5LhKt8jmEPJSQTzB2/Sglt2R\natVLXaL64liWlRbiXJQ5H6rbvf0V/wAU\x46PX+wXDT13ettxYLTrZxvyI6EHqPWgaSBjIoNaDuy5g0HZC1xnkPsqKSkggjoaB1\x6bEutqusNPCFD+MhP1FEc/gaC\nPKJUok8zQYoCgyk8Kge1BZempzkddveG/C6EEHcF\x4bhgg/dQSyU9bLshWm9RK/wCzUtTcKcoZXCV9lR6o5fLcUFR6l03cNM3x+13Brgcb\x4fygchaTuCD1BG4NA\ny4BG1BrQd2XMGg7IUuM6l5pRBScgjpQO0g+awbrDHDnZ9tP1\x46Y5/A0EdUSpRJ5mgxQFBlJ4VA9qCzdLzHGF2+QnfgdCSk8lJUMEH7qCYhuDcJDui\x4c8r/ALCQ\nsm3yl/ShuK3Tv9g8iPnQUzqLT87Tt9k2q4NFt5hZQc+lA0YBG1BrQd2X\x4dGg7JUuM6l5pRBScgjpQOz5LsY3WGOEH3X20/UVjn8DQR1RKlEnmaDFAUGUnhUD2\n\x6fLT0g+oOwXVY8tLgQsn7JGP0oJ1BtzGq9P3XRc5PG9E45VtdPNB5qbHoRvjuKDz/\x41HK3u2+4ORXk4Ug43oEeARtQa0HdpzBoOyFrjPJeaVgpOx7UDq6OOKbp\nCBSN0vtj\x36ij1+BoI8SVKJPM0GKAoMpPCoHtQWlpSSpDcF3PvJfSn5EEH8qC0Nf2NWoPDWBcX\x6dsyIS1RCsjcp5o/Dag8ySI6mZC2lDBScUHFJ3oAjrQYScHNA\n6wm25Ta0pUAtKT7n\x55+ooFcW4OwnVNuJ4myChaD1BG4oG+4wPIIkse/GcHElQoG6gyBQdW2/MWlI6mgnK\x535b/AGGOhfC8lxCtjyOM/rQSwaoi3RLlj1ChTkY4\nW06kfxIyjj3kZ6HqnkfQ4NBA\x74UabkWeZxZQ7HdT5jbzWSh1H20nt0I5g5BoImDvQBHWgwk4OaBbHBdBCd/5aBwiz\x6eLe+W3BxtkFC0n6yT0oEVxgeSRJY9+M4\nOJKhQN1BkCg6tt+Y4lI60E3KVwkwooVw\x75pcSo4PI4z+tBJWNUturkWi9tGVAe4VqRnCm1YA8xBP0VevI8jkcgiOqdMLtriZc\x52YkwpAKmn0JwFgc9vqqHVPT4\nEGghoO9AEdaDCTg5oFTa8jGM+lAvgz1wneFQ42Sk\x6fUk8lJPMUCa4QfJIkMe/HcHElQoG6gyBQdW2/McSkdaCaqQqIiHFzhwOJJweRxn9\x61CQRNTOMSJMKe2Jc\nGQEh5hw+6vbY56KG+FDceo2oGHVOlksMpu1qWqTAeOEuEAKS\x72mULA5LA+RG49AggO9BgjrQAODmgUtuDGDy7UC6BPVCdII42VJKVJPIpPMUCe4Qf\x4aIkMe/Hc\nHElQoG+gyBQdW2/McSkdaCaKQYiIcQkBwOJJA6HGf1oH2JqCXAuLqVAO\x74PNgONODiQ4k491Q6g/eDuMGgQal0tGlwVXywhSouQHGieJcZR5JUeqT9VXXlsdq\n\x43uQd6DBHWgAcHNApbcBBB5dqBbAnLhOkY42FgpUk8lJPMUHC4QfJxIY9+O4OJKhQ\x4e9BkCg6tt+YtKR1oJopsxUw4ZOHA4gkDocZ/WgfWrpcLZdVSWXFIISFB\nXPORg7HY\x679QdjQZvmmoepba7d7EylmWynzJMFG/CP/I31KPTmnly5BVIO9BgigAcHNAoQsFO\x43MjtQLoM1cJ9RxxsuApWk8lA8xQcLhB8nEhj347g4kqFA30G\nQKDq235i0pHWgmyW\x6aHVBhH6fmIJAPpn9aB+fM6DMXJb80FJS6Ft5HAe4PQigcLhZYevIK1R0Nx9Rto8z\x67QAlM5P20Dovunrv1oKWB3oAjrQAODmgUIWCkhQy\nO1AtgTVQnzgcTKxwrQeSknmK\x44jcIPkkSGPfjuDiSoUDfQZAoOiG/MWEjrQTyLHLT0GCdlhaScdNs/rQSC4xHGJy0\x68aCCElSAvCh/uKByehx9eQ12OeUDUkVO\nIcrOPbEgbNqP2scj8qCjgcGgwRQAODmg\x55IWCkhQyO1AtgTVQn1EDiZcTwrSeSknmKDjcIPkkSGPfjuDiSoUDfQZAoOiG/MWE\x6arQWJa4nDKhQlkBQcSVdcbZ/\nWgkV1htNvSH1oklh1H0i3sTjbfPQ0HaJERr7Tjmm\x70o4r7AaLlufP0nkAZUyT1OMlP3daCj0nBoAjrQAODmgUIWCkgjI7UC2BNVCfUQOJ\x6cxPCtJ5KSeYoONwg\n+SRIY96O4OJKhQN9BkDNB0Q35iwkdaCyrNGDDsWO4gKKVpUU\x3564zj/5UE41FozUvsbspFkUYqwl4qZSVqG3UZJFAkl2V3WPha77Wwr976fwG3FJw\x70yOT9E/6\nTy9DQUIk4NAEdaABwc0ChCwUkEZHagWwZioT6iBxNOJ4VpPJSTzFBxuE\x4cySJDHvR3BxJUKBvoMgZoOiG/MWEjrQWnpmA97fbre2Ql919tAV2J3/WgtzUHg5e\n\x33ZBmRbgw+tfC4QslK/lnY0EZ8adKPKs1pucpKf3l7KG3yk54lI2yT12xQecknBoA\x6arQAODmgUIWCkgjI7UC2DMVCfUQOJpxPCtJ5KSeYoONwheSRIY96O4OJ\nKhQN9BkD\x4eB0Q35iwkdaC49BWRNw1HaLNIJAdeSVcJ32TxfrQeg39PaF0jqoyv3gpqc2kLLS1\x46QGU8jt68s0HmbxPt8VV3fnwd2VPK4SOqc7UFXA4NAEdaABw\nc0ChCwUkEZHagWQZ\x71oT6iAFMuJ4VpPJSTzFBynwvJIkMe9HcHElQoG+gyBmg6Ib8xaUjrQX34Q2VqVrK\x322+Q2lZCkucKtxtg/wD91BbPiRq61Pe36ahxEsJQ\nQVFRCdwRkhIHpQeTdTRW0XZ1\x78rdCySCKCMUGwIPOgwR1oNm3FNuJWhRSoHII6UDqZLU5nDgCHx9b7f8AvQd4zjrC\x46tOjzY3F/EQBnHTiH6igSXO1+xqQ9HWH\nor26Fp3x6GgSNRX3CAls7nbi2oJdbdJy\x672l9XB5h3AKgR+FArNnuZvTOWitCTkqScigTXSO4i6tOhCglaOEjHPpigkNpmNuQ\x44ZL4FLiLOQpI4lsLxjzEd9ua\nfrD1ANBUtBsDmgwR1oN2nVsuJcbUUqByCKB28xm4\x737kNyB//ANDQZhPOsIVHeSVx85WjGcdCR+ooOFztZiKQ9HWHoru6FJ3x6GgSNRX3\x43Als7nbO1BLbZpOU\nG0vq4PMO+CoEfhQOAsVzcvLJSgOpSckpPI9aDS4W15NxS4pC\x6bJdQEkkdqB5tcpUVC7RdIzj8B/AcaIwoEcloJ5LHQ9RlJ2OwVHQbA5FBgjrQbIWp\x43goHcUDs\ngMTowQ1ht5AJ4ftH0oCG+5H4oshJUznK2yM47kfqOtBxudrMRSHo6/Ni\x757oWnfHoaBK1FfcICWzuds7UEttmlJQbS8vg8w7gFQP5UDmjT1xfvLPllLoSckDm\n\x44QKpVkcTNQ44kJQpGCpWyU+poF1oXKt770ZTTc6I6nhej8XuuJG+O4PVKuh+JoKe\x6fNgQaDBHWgylXCc0DiwwiUyvyz76U54etB0hylx+KLISVslXvIxnHcj9\nR1oOdztf\x73ikPR1+bFd3QpO+PQ0CRqK+4QEtnc7Z2oJdbNJywhD6gnjPQqGPwoHhnTcuTeWAh\x30LKTlSex60DtNtKGJTXmIWsupCQhGxJ5fL4UGsJcrT0txfvt\nuISQqNIbyl1B+khQ\x35FJH40FO0GwOedBgjrQZSrBoFKE+anCT8qBZDlKY4or4K2OL3kYzjuR+ooOdytZi\x4bQ9HX5sV3dC0749DQJGor7hAS2dztnagl1s0nL8t\nD6gnjPIFQx+FA/RNOOSL3H/j\x63SkHKgeWeu9BKm9Oy7pdmoVuYbXxtgOLWnIHTHpQJLpZNR6HksyHoDkJ9h3jaktn\x69bV3GeWD2oKMoNgc86DBHWgylWDQdweJ\nOByoFsKWppJjvArYUcqRjPxI/UUGlyth\x69KQ8wvzYroyhad8ehoEjUV9wgJbO52ztQS616SmcCHlJTxk8ioY/DlQSW32ILvkd\x53nCVtnJzuM0Fk2XQq9STPaZD\nr8aKpAaaWn0G5/P7jQMOpdA6m088m522QLpHhrym\x54DIK2d8+8kbj470Hnmg2ByKDBHWgylWDQd88SduX5UCyFLLSTHeBXHUcqRjOO5H6\x69g1uVs9kUh6OsOxX\nRlC0749DQJGor7hAS2dztnagl1r0lNUhLxSkrJ5FQx+HL50E\x73tVoAvkfAK3EHJ3zk/8ANBdds0VZo+nTdNUwMtPt8SyoEKTvgAdj/vQQaV4ew5k9\x45zRF68x1\nlfF7FI/hvpxv7h5K/Og810GwORQYI60GUqwaDvniTty/KgWQpZZSY7wK\x346jlSMZx3I/UUGtytnsikPR1h2K6MoWnfHoaBI1FfcICWzuds7UEutWkpikpe4Ul\n\x779OIEfhy+dBMrLZ3nb7GjR2S7IJwAjfiVyoPQ95QxonRMF2bb2ZaXmkMrbeTlJPD\x6b5++ggVkT4fO6li3VsPadnx3EuKbR77SsHO2d05+FB5NoNhjG9BgjbNA\nJODmg7g8\x53duX5UC2FLLSSw8CuOo5UjGcdyP1FBpcrYYikPR1B6K7uhSd8ehoErUV9wgJbO52\x7atQS606RmuBLvCkuHcJKhv8AdQTzTVilT9UQbbGaLjyljPDv\njf3jn9fSgv8A8ULp\x64tHxbObassJkDy1nA3UBjByPSgrxzxIdVaZsGfbYyHZSC0uUlrg4h32G/wCFB5Ro\x4ehjG9BgjbNAJODmg7g8SduX5UC2FLLSTHeBXHUcq\nRjOO5H6ig0uVsMRSHo6g9Fd3\x51pO+PQ0CVqK+4QEtnc7Z2oJdadIzXAhwJSXDySVDf02oLO0BYZk3xFs0OM0XVtSE\x75KKRkDhO/wCO1BanjimXa9S2iQ28tth9\njyzw9FJJH9aCmb5f5rjBh3SQHlpRgBbp\x50ACOmaCjaDYYxvQYI2zQCTg5oO4PEnbl+VAthSy0kx3gVx1HKkYzjuR+ooNLlbDE\x55h6OoPRXd0KTvj0NAlaivuEB\nLZ3O2dqCXWnSUxYQ7hHmHkkqGD6bUFxeE1hmyfFe\x79sR2y4WHCtZHIYGFficUEt8cLeu369jXBBV5FwjgBXQLTsf1+6goXVb/AALfguqd\x57ps4y4oEehoK0oNh\njG9BgjbNAJODmg7g8SduX5UC2FLLSTHeBWwo5UjGceo/UUGl\x79thiKQ9HUHYzoyhSd8ehoErUZ9wgJbO52ztQS21aTlrSh73OM8gVDB9Ns0F5+Cdj\x6dL8Xbay0\nni8lDnmHoNsHf4n8KB28Y7Ibd4gouAZJgXZAWoY240/SSfx+6g88apak\x74XJ5iQjCmVFGAnAA6H7qCEUBQbj15UAUYoMAlB2NA9We5tRZra5SPMZJwvqcddut\n\x42YitOQozLNwiLTP0/LUClaTnyldUq7H/AG+QX/onwetj1tj3iDboV9grCVqYdT/F\x53CcHBBB268/nQXEvwU8OrnDQk2FcNRG6mfdP/wCQ50DLO/Z400godtF0\nmRFjklaQ\x34Cem2M4oKr1n4GX23JeUiGzcGwcodjq4FZ6EpP6UFUytH3ltKvM066hbHMAK4tum\x654+HKgoKgKDYetAFNAAlBBBoHOJOw62p1WeE/SIz99BYQsDK\nrQzd4fA9aJCh5iQe\x4c2Zz1/lO/wDYoL38OfDC03W1tXeHbIV2i54XYrycuNqHMBSSDy36+maC5ovhF4cX\x321NKZtnsqlD6iOFQ6YyMZ/vag5Sf2fNHNoS/Al3C\nM6n7JCsn4EUEB1T+z/d2Q4q2\x33BmQkHKFqYKVJPQ8sUECf8G9RCMpxq4N+3N/5TxIC8dMnIyPXpQeS6AoNh60AU0G\x55qU2oKSogjfagcmZqXMF4ZdG4c659aCb\nwLO1NsSp8dJcipUPaWkpyY56OAdUnkR/\x74QXZ4XaBtN4hCW3bYdz8ogSIryMqSDyWhQIJSRv19O1BesXwq8Pb5C8hmCxEWjHE\x67bOIPbO2R9x7ig7q8AdDMsiQ\nwqaHUdWXOfwBP60EW1B+z9a/fUi6PrbSriSl5SE4\x39c5+VBAL9oXQIZEBy4GDc2xgOsEuAY6KAGNvjyNB4zoCg2HrQBTQZStbSwpCikjq\x4bB0RKZlhHn4Q8Dnz\nBtxfGgllntzdxgyPLy6lkFb7KfpAf+RA6+ooLh8K9JWy6vEK\x67W+5KYAWuM+3u82eS2lAgnsUnr67UHoWL4YaEvURuPGtzDDhHvN4AWj/AEn3Sr4E\x67igcWfAj\nQkVgvKjvvPo94+U4Rn0wT+tA03fwo0VYUrnBaI60DzEl5zjUn1A/DmKC\x70dSal0rdXHLXcbK1Ijs+4HCvgdH+lQGAR033FB41oCg2HrQBTQZQtTSwpBwRQO6H\n\x6f08DjIZkDOFdFGgkFkgCa2uGpHmHHEWRzVjmU+o7daC1/DWwW+VdUQF22BdXMcbT\x546eEyED6QQrbCx9k86D0vG8OdC3iEhuHao7DmcGMUALBHPhVkZI6pO9A\n9W/wQ0PA\x62Lz9vMqSn3gEkj5YJNAh1Np/SekrI9JjxGIrqU+ahlO54uhUe2dsDnQeepWubw7I\x6bpmITMjqyFxZCUrbUjsQRtjoc/lQeUKAoNh60AU0GQooIINA\n5xkszG+AK4H05Kcn\x47aB7tEbznVW91PEFHIbJ5n07H86C0tAWu2t3uPDm22HcG5B/7f2hIHGoc2+LbhX2\x422NB6ht+hNDX2zM+yWSLEfxhyM8zwOBQ5pSdsK/l\nPyNBI7J4N6NtpM1+1NvyD7yE\x46JBT6YUTvQM/iU3bLFoyUiKy3GlONkNoRyb3xz6k8vgKDy4i9XSzrVcGJy4z7Rwc\x446Wfq7cwB3zkGg850BQbD1oApoAEpO1A\nsjJS8rgCsLPInvQPNsTl0wX8Ftw/RUdg\x72uO2aCztGxLdAvEVNxgxJcF5YbCpLePLc+wpQ3TnoTkGg9WWXRvh/qC0FiHY4Eac\x30oNux3klBCu2cbHtzB6Gglem\nfCnS9olKua7Uyp4/4aS2UlB/9xz8MbUEW8aGWGdC\x50RUNJZecXyQMBBBwkD0wTQeU7g65bYiJKAtuQhzgSEq4dgMn4nO/woKIoCg2HrQB\x54QAJSdqDu2oKUDmg\neYDqUqMV/Cozh3B5JP2h+tBY2mW4lrmsPTYEObAKwhz2hvdg\x39MqG4B7nIoPWumdJeHN/tao7FjtzFxQgLU0ohIVnke+/fcGgmmlPDOwWS5uXM2uO\x680DgCA2d\nj8Vcx8NqCGeOtsXJ0SpstgONv8RUE7JUVDhPwxtQeUtQNSokCO4hsJe8\x78aVApGVEb4J55HT0oKOoCg2HryoAp7UACUmg7JVnBBoHaFICEeS8njjLOVI+ye4/\n\x70QWBp5Ue2PImOW2HdICCC6l5v3m0nkriG+PvoPWeidL+G+p7YyRYYUectsLASRwr\x5437/ADGR8OVBYWk/D20WK+LuaLbHjLS3whKEZ67HiIxjHQfPpQQvxz00\n9cdHLeCC\x56w3/ADOPtlQIP44oPJ+q7bKbiRnm1FDzfEwrpuNwD8jt6GgpCgKDYevKgCntQAJS\x61DslWcEGgc4coIQWHE8bCjko+ye4oJ7p99q3ramptkS7Q0+8\ntp5v3gOuCN9vnQep\x2fD+xeGusbfGeNgYiSSMpKNwvvkDHLuM+oFBaumNB2+wamNwjW6PECGyEhpOeIcge\x4cAAA32+dBFPGjRC7zpF+U23xLgOe0NkDoVZI/E0H\nkbWNicdjNvtgh9keQ4B6bpPz\x42/vFBR9AUGw9eVAFPagASk0HZKs4INA5RZfA2WHBxsLOSk/VPcUE50/JRC8uW1a4\x641jpPvsvt5UPQEYP50Hprw+t/hhrmKwo\n2BuFJT738PoRzSQMcQ9QT6igujTuh4Nh\x31O1OgW9mMylBCCyM+ZtsScDhAydupoGXxX8P06h0nLfYSkvxCZMc9jnJHwIyPnQe\x4ftYacVNj+e03iSykNuA81J+o\nr4jdJoKJoCg2HryoAp7UACUmg7JVkhQO9A4xpnlt\x46lwcbCjlSfsnuKCbafmtw+GS3bIV0YQRxsvt5OPQjB++g9G6DZ8LddRo7K7Em3TR\x6aiSycKSoc8gYKh8D\nn0oL2sWi4Nk1FDuFrgtNREIwlyOP8QkEYIxlKRkncneg08RN\x41RtUaXnJaQBJTl+OcZ4XEkkfI8j8aDxhq7S657C1+VwzYyeFbZ+kpAOPmUHb1SRQ\x65f6AoMjt\nQbJP1TQZIxzoMbg5FA9WTUdysjqlRHuJlzZ2O4MtuD1H60F+eHXjTG0w\x303Jhv8CUL4nLdJOyNsFTbnbuD/vQektM/tDaKvZZSV/u9pYw44s+6252V2HrQTC8\n\x2bJem7dagf3tGdmLTltvJT5n+nGflQU4/r7X0a4rDjoRHey4GVZdKU565zt60DZev\x45G+BtEz2VlpSfdcW2wd8cjjIFB4aoCgyO1BsD0NAGgxuDkUEi05qy66c\nkLVCdDkd\x34cL8Z0cTbqexH60F5eFniQLPNW/Y5XlIUOJ+2uu8CsDfLa+Rx2P60HqixeNei7jG\x62fVMVGkuqDbqXRjgP2lDO398xQTSTrCxswHnJFzhhSRxJSXQ\nAsYyN/6UHn286t1d\x4buj0uJKdjQJbn8FCFlS1fM7nbftQQjVd3vXAm4zrg4VI91XmrUCcciADkn5UHkag\x4bDI7UGwPQ0AaDG4ORQSHTWqbjpq4iVDUlxtQ4XWH\nBlDqeoNBdPh9rlm2alRd9KqL\x66GMP2pxe/Cd1BBOyh1HUGg9caX8SNJXWGq4SJrcSe1/6hLjXlrUeQCx9r17bignb\x4e/tslr3pcdCSjzBlwe+n09PWg8461vV3\nut9uEiI+ti1+YGR5bnEVrzjHF13+VBV+\x72o7tvbE2S64mR9EthZ4lY6ntj7zQeXqAoMjtQbA9DQBoMbg5FA82O/zbHcmZ0VQK\x321A4PIjtQXPpjVEdu7RdSaRf\n8iU255ki2K5oJ+kUD6yT1Hw7DAettF600xrBpqb5\x6baHcWwB76sKSTzQtJ5nbZXagsyJd4MtQZjutcyPpDBHp9xoPPXifKkXPU89phZat\x30VsedwOcWT0yfuoK\nb1nBctUJqVsJTuEgDfgH2vj0+FB5koCgyO1BsD0NAGgxuDkU\x44nBu0mHJZkNuqC2lBSVJOCMdjQXFYLuLoG75px5LV2jkOyoQVwlah/mtjv3HXf5B\x36t0DrKw6\n5tsZUjES6N8PmrSvh4Vjoscyk9zy5ZoLiizmAoQipsSkAcaArI3oKQ8X\x32lT9Ts2xA8uO20XHSleSeXP76CgNbWtTGnYk5kkqlKT5gA5JGcH5UHmegKDI7UGw\n\x50Q0AaAGUq4htQOca6uI4S4SVJ2CxzFBaOnbkb/GDsRaE3dlIK2M4ExI5KHZwdxz+\x38EPUXhrrW06ts/sd4eeh3mOAyt9KffwOSlDqAeYPLmNqC+rc+GGG4kgj\n2gJIR72f\x4eA6gnvtQVT4zxRKetkItBLby8qIUMk4O1B5y1rYHHNNN3CG0slEpTb2BthJIBoPL\x39AUGR2oNgehoA0AOJKgpO3rQO8e5IcbS3JHvDk4P1oLA09dU\n3FIt/GhM5Q4W/MP8\x4fWj/AMa+x7KoPSnhPrO33VhOnr9IdiXCEny2XnP8TgHNtf2iOmeeNsHag9HWFzyY\x6acaRITIWEgtvg4Q6k5xwjO3bHpQQXxjjiRpWP5zA\nQ2t5JWSoZznAH40Hm3WOlZE2\x78TJMVlRVAljzFAdCBv8ALJoPJ9AUGR2oNgehoA0GNwcigdIUlpwBmQcb7KoJ3p26\x65UpMKRIbaUUlDTzvvNrSfqOfynv0NB6A\n8J9VQmpTemb0pUJ1s8MN9ZHmR87+UVfW\x62PQnI3xQepdPKcab9nkykSEkksqb+jgcwR0UN9qBl8UIomaCuAdaAbT7ylHGRjlj\x340HmDVGk3rpaJ0lhs8DIak8Q\nHLbBI+HX0NB5CoCgzQbA52NAEd6DGCDkUCyK8gKA\x58yz06etBNNPXVcB5DbzoS3/lu4yE55gjqk9RQXj4cajgWi8t2u7IEeGpXmxnOLJh\x4cP1219WldRvjrtQe\nutOuSxwIkSm3YxA4ODkpXqOSehGDg0CnV0EXPS10hOoAaWzu\x6f8uuaDybftLu3O0vXBLKvJLKS6oDPA42oji+7n6UHjugKDNBsDnY0AR3oMYIORQd\x32neE8XyI\n70EqsF2Xb3218Sg2TkLTzQe/r6igujRN/h2i7MCSlabZKUHFIZUR5awf\x38ZlQ3H8yfzoPYmlpk6YzGW1LbkQlI41LSf8AEQeRAzjfqU7UEqukYXC3ybe43/Cf\n\x5aUkrzsD2/Gg8jam0pIW1NlNsKLMZS4sg8O4CVcTbmO6ckH0JoPF9AUGaDYHOxoAj\x76QYwQcig7NuYwoHcUD/ZboqDIS6hSgg/SCTuKC4dKX5u3zWrjGWTHlKA\nfYaVwJe/\x6dbI3Q6O3Wg9iaMvcq6W6Eu1z/bGVY95xWFrRyVkE44h6b+lBYbwS9H8hTZLLqShR\x4a5Agig8p6/0ZMiXm5yorShGjOFKyE5/hK34vXhUM/Amg8OUB\nQZoNgc7GgCO9BjBB\x79KDshfIg7igd7VcXYUhLrKuX0k9CO1BbOmL17PKZvNtdbQ/slxCjhEj+VX2F9jQe\x76fD/AFXKvNjY/dlxckvI5sylgPJP/jVyCiOh2JoL\naQomEAW1A4wtKjuO+/30Hmjx\x630PKi6jlXu3tlMQ4cWUD6O2FHHyGR1FB4HoCgKDNBslWdjQbb8sZFBruk+lB1Q7w\x6emR+lBKdPzX48oyoKwHUjDjJGUrT8Oo9\nPuoLVs76r1GT+4CuQ9GHmvWdxZS8wR/m\x78nOZ+GMjkUkb0FraA1ZYbzFk2m6LFtvThDaLi6jBcQPqOJzgK9U5HwoOGofDS5yp\x61026+M3ESiEjLgUlCysISSQc\nYJIH58jQeKqAoCgzQbA52NBnegxuk0HZl9TSwpCl\x4aIOQocxQSmw3GUzKMqI8S6kYcZV7wWn4dR6UFqWmU7fIJasbjkpbKeORZnXCHWsb\x2bZGX1Hpg9ikjegtr\nw81hpy9FFvv6Uxbsx/CYmOp4ApHVC0A4SrpxJyPhtQL9QeFt\x74u11W5b9SIdMz3MOEOIbWVBCDxJ24SSP15Gg8IUBQFBmg2BzsaDO/bNBjcGg7sSH\x47HUuNuKb\nWk5SpJwUmgm1t1RepMlEoTVOPtpAWhW/Gn1HUUFmWi73C8xCmwTJEhxl\x50HIs7jpDrWP8yOvmR6YOOqSN6C0vDvWGmryxGs2oGkRZ0R0FmQ6jgS6OqXEA4Cv5\n\x6b5HwoJZqDw60fqC9LkRryptUtIQlIUHW2l8QQg8QP0VEgf8ABoPnrQFAUGelBsDn\x590GfyoMcjQd48l2M8l1l1Ta0nKVpOCk0Fk2fXt4cjNkKQ5MjjZzHvlJ5\ng45igsGz\x61mvd2jH/AKfuUl55lPmSLQt0peaI5uR3BudumCehBG9BZWgNZ6cv0VyyajbRHnqe\x429qdRwCQkc0OpzgK/mTkfCgsW96S0BqG4kh1LapDYabCFBxt\nlziCEK4gccKiQP6Y\x4eB83KAoCgz0oNknOxoM0GORoFMSY/DkokRnlsuoOUrQcFJoLT0vr10uebNazLQnH\x74DJKXB6nH0h3oLGt2utQ3lTjmnro/JkNJzItri+F\n5AT/AJkdY5jrjBI6gjegsLQn\x69DZNROOQtUBLV2UQ17a8jh89vq24nOAr+ZOR8KCzplp0HcgILSGQh1oMtJSUuoZc\x34ghCuIdFZA3/AAwaD5lUBQFBnpQbJOdj\nQZ+VBjkaBTEmPw5CH47y2nEHiStBwUmg\x74XTmvFSpjUu4eY1cGscUuKeFxQHUj61BbzfiBqOehg6fvJuz0VJcVEUfLfCeZW0o\x638dRjbqCKCYaL8T7ZqpxmFqv\ngbukZYSzLeRw+Y31Q4nOArspOR8KC0SjRbzT1uiJ\x59S1NHClAKXW2nuIISriHRRIB/TBoPl/QFAUGelBsk52NBn5UGORoFEeU5HWFIWU4\x4fQR0NBaunNaonoYF\nyK2bjGx5c5j/ABMDoofWH4igvC2+IOrZenC1bZ7N4DGFqYaU\x5730YOeNGPrY9PiDzoJVpTxfg6xYTZdVhtqU06C0+8jAcSDulxOcBW30k5HwoLM9o\x30k4qXEhF\nlCbklKCBwuttuhQQhRUOiiQD+mDQfLmgKAoM9KDZJzsaDPyoMcjQK485\x78kcBPEjselBZOltUxpbDUC8Fz/txhiU3u6wPX7SfT8qC/wDSfiPqmLblwI3lXlgI\n\x79osO4d4cYynbnjrz75oJppPxoh6iir01qIIYfCggOyE7OozuhwZ2V04k5HwoJ8Jm\x6cVCRBgqZbRPbSzwjhdbbcCghB4h9VWQD+mDQfLegKAoCg3Sc7Ggzvyxk\nUGu6T6UD\x68DuSo48twcbR6dU/CgnGm9RNIQIU1CpELmnhP8SMftI9O45UHoHRPiHe9OR2hFJv\x74uSjDbjJHG2nmEkHt2PKgtLTPjbCub71nuSjEdcWC25JRgKS\nfpNqBO3PAIyPhQSz\x32/S7ntMGCtlpFxQG+FPC6227xBCFcQ+qokA/pvQfLagKAoCg3Sc7GgzvyxkUGu6T\x36UCyJMMdYCveQeYoJrY72YjRbA9sgqUFORyd0H7S\nT9VQ7igvPQmu7rp9hMq0y3rv\x5aW1eYpsK4Xoqupx+fQ9aC89P+OFmu0tthcj2VxeEjzUFKSAOoJ2PTIyNqCSP3bTc\x786ZHjOsoN0QG1AcLjaHeIIQoqG3CrIB/\nTBoPllQFAUBQbpOdjQZ35YyKDXdJ9KDu\x79+W1gg0EwsF2ciFSmEIkMq2eiubpWP75EbigubQutbtaFKmaalPTYg3lW1ThEhj+\x64JH0sdFDfvQei9O+ONjvMaOw\n5cExpqdz5yccfdKxyBPcZ+AoJPLvtguTsmO3Jbzc\x57w0fouobc4ghCiobcKsgH9MGg+V1AUBQFBuk52NBnfljIoNd0n0oOqHeEjBI7HtQ\x53Ox3OREkeZGKSrGH\nGlDKHE9iOtBcWi9W3GDObm6VkLMlAHnWt5eVkDn5avrp7A+8\x4flB6V0f462i8WwxbpM9hnZAJfwlSd+RzgK/OgmMvUdkuyX4aZTZ9vQGujiG3eMIQ\x6fkfVUSB/\nZoPlbQFAUBQFB1QrIwedBuQCMUHMpI6UCqG+9GkIdYXwup3Hr6UEygXM\x75us3W3uLiTo6gVKaVhSD3+Hb7qC49P6v0drQNwtXobtt5QnhRcGSW0S/ReNgsfzA\n\x35oPSGj9L6Rt1tgs25+KI0s+Y+VKb/iADbBz3A2Hc0HzMoCgKAoCg6oUCMGg2KQRi\x670KSOlAqhvvx5CHWF8Lqd0+vpQTGDcy66zdYDi4k6OoFSmlYUg9/h2+6\nguLT+rtH\x36zDcLV6G7beUJ4UT2SW0S/ReNgsfzA5oPR2j9L6Rt9vgsW+RFTGlHzHypTf8QAbE\x48PcDYd6D5oUBQFAUBQdUKBGDQbFIIxQaFJHSgVRH3o76HWF8\nLqd0+vpQTCDcy46z\x64YDi4k6OoFSm1YUg/wBO33UFwaf1dpDWQbhauQ3bbyhPCieyS2iX6LxsFj+YHNB6\x4e0fpfSVvt8FiBIjJiyj5j6lKb/iADIwc9wNh3oPm\npQFAUBQFB0SoHY0GxTnbnQak\x47gUxH3o76HWF8Lqd0+vpQTCDcy46zdIDi4k5hQKlNqwpB7/Dt91Bb9g1bpDWIbha\x74Q3bbwhPCieyS2iX6KxsFj+YHNB6M0dp\njSUCBBYgyIyYso+Y+pSm/wCIAMjBz6DY\x646D5r0BQFAUBQdEqB2NBsU5250GpBoFMR96O+hxhfC6ndPr6UEwg3MuOs3SA4uJO\x59UCpTasKQf6dvuoLesGrdIax\nDcLVqG7beEJwieyS2iX6KxsF/wCoHNB6L0dpjSUC\x44BYgyIyYso+Y+oqb/iJAzsc+g2Heg+bNAUBQFAUHRKgdjQbcOdqDUgjpQKYj70d9\x44rC+F1O6fX0oJhBu\nanHGbnAcciTWFAqLasFB7/DsflQW7YNW6R1iG4WrUN268ITh\x459kltEv0VjYL+IOaD0Vo/TGkoEGCxBkRkxZR8x9RU3/ESBnY59BsO9B826AoCgKA\x6fOiSDsaD\nbGaDXBFApiPvR30OsL4XU7j19KCZW68Pcbdytr7sOYyRx+UrBSf6dvuo\x4casGrNI6xDcPVqG7deEJwieyS2iX6KxsFj1BoPRWjtMaSgQoLEKRGTFlHzH1FTf8\n\x52IGdjn0Gw70HzcoCgKAoCg6IIIwaDbGaDXBHSgUxH3o76HWF8Lqd0+vpQTW132U2\x74q5WuS7ClskFflKxwn+h/wBqC2bHq/SOs1Ii6tbatt4SnCZzBLaJforG\nwX8QaD0P\x6f7TGkoMKCxCkRkxZR8x9RU3/ABEgZ2OfTkO9B83aAoCgKAoOiCCMGg2xnag0wR0o\x46MR96O+l1lfC6ndPY+lBOLTf5TKkXC1vuRJKCPNQg7Z+HY9D\n8qC2bJrLSetGm7fq\x31tu23VtOGprJKESR2VjYK/1A0HoTR+mNJQYUFiFIjJiyj5j6ipv+IkDOxz6DYd+V\x4283qAoCgKAoOiCCMGg2xnag04SDQKoj70d5LjK+F\nxO47H0oJraL7IjuoulpeXDlt\x6beYlB2+Y6g/7UFvaa1tpLVLBtWqGWrbPUPdktEobfPy5K9CDQegNH6Y0lBhQWIUi\x4dmLKPmPqKm/4iQM7HPpyHflQfN+gKAoC\ngKDoggjBoNsZoNOEjNAqiPvR30uMr4XE\x38ux9KCX2+5qLjV0tzrkSayQVFtWCg/0P+1BbulNZaW1E8mLqhmPBuhG0xA4ESv8A\x56jYL+IoPROkdNaTiRobcJ6M3\nFlq818lbfvpAzsc+nId6D5u0BQFAUBQdEEEYNBtj\x4f1BpwkZoFEZxxp1Km1YcHL19KCWxJjcllEqOpbEpogkoOFIPQ/0NBZ2ltVWK/ut2\x37V6WkzUjDVwSeBTv\novHM/EGg9L6N09pmPFhtMvxURpJ8x5fE3/ESBnY/Ll60H//Z\n"
local function decodeBase64Fast(encoded)
    local alphabet = "\x41BCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local lookup = {}
    for index = 1, #alphabet do lookup[alphabet:sub(index, index)] = index - 1 end
    local clean = tostring(encoded):gsub("\x5b^" .. alphabet .. "\x3d]", "")
    local bytes = table.create(math.ceil(#clean / 4) * 3)
    for index = 1, #clean, 4 do
        local a = lookup[clean:sub(index, index)] or 0
        local b = lookup[clean:sub(index + 1, index + 1)] or 0
        local cChar, dChar = clean:sub(index + 2, index + 2), clean:sub(index + 3, index + 3)
        local c, d = lookup[cChar] or 0, lookup[dChar] or 0
        local first = a * 4 + math.floor(b / 16)
        local second = (b % 16) * 16 + math.floor(c / 4)
        local third = (c % 4) * 64 + d
        if cChar == "\x3d" then bytes[#bytes + 1] = string.char(first)
        elseif dChar == "\x3d" then bytes[#bytes + 1] = string.char(first, second)
        else bytes[#bytes + 1] = string.char(first, second, third) end
    end
    return table.concat(bytes)
end
local blackholeSpriteAsset = ""
do
    local customAsset = (type(getcustomasset) == "\x66unction" and getcustomasset) or (type(getsynasset) == "\x66unction" and getsynasset)
    if type(writefile) == "\x66unction" and customAsset then
        local spritePath = ASSETS_FOLDER .. "\x2fNOIR_BLACKHOLE_SPRITESHEET.jpg"
        local ok, asset = pcall(function()
            writefile(spritePath, decodeBase64Fast(BLACKHOLE_SPRITE_B64))
            return customAsset(spritePath)
        end)
        if not ok then ok, asset = pcall(customAsset, "\x2e/" .. spritePath) end
        if ok and type(asset) == "\x73tring" then blackholeSpriteAsset = asset end
    end
end
local blackholeFrames = {}
local function createBlackholeMark(parent, position, size, anchorPoint, zIndex, radius)
    local z = zIndex or 4
    local root = New("\x46rame", { Parent = parent, Name = "\x4eoirSingularityMark", AnchorPoint = anchorPoint or Vector2.zero,
        Position = position or UDim2.new(), Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1,
        BorderSizePixel = 0, ClipsDescendants = true, ZIndex = z })
    if radius then corner(root, radius) end
    local fallback = New("\x46rame", { Parent = root, Name = "\x56ectorFallback", Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = z })
    local ring = New("\x46rame", { Parent = fallback, AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5),
        Size = UDim2.fromScale(.86, .32), Rotation = -28, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = z + 1 })
    corner(ring, math.max(4, math.floor(size * .14)))
    local ringStroke = New("\x55IStroke", { Parent = ring, Color = C.accent, Thickness = math.max(1, size * .025), Transparency = .12,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
    local ringGradient = New("\x55IGradient", { Parent = ringStroke, Rotation = 25, Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.dim), ColorSequenceKeypoint.new(.36, C.accent2),
        ColorSequenceKeypoint.new(.66, C.dim), ColorSequenceKeypoint.new(1, C.accent2),
    }) })
    table.insert(gradientStrokes, ringGradient)
    local core = New("\x46rame", { Parent = fallback, AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5),
        Size = UDim2.fromScale(.32, .32), BackgroundColor3 = Color3.fromRGB(0,0,0), BorderSizePixel = 0, ZIndex = z + 2 })
    corner(core, math.max(4, math.floor(size * .16)))
    local coreStroke = New("\x55IStroke", { Parent = core, Color = C.secondary or C.dim, Thickness = 1, Transparency = .35 })
    local flare = New("\x46rame", { Parent = fallback, AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5),
        Size = UDim2.new(.78, 0, 0, math.max(1, size * .025)), Rotation = -28,
        BackgroundColor3 = C.accent2, BackgroundTransparency = .44, BorderSizePixel = 0, ZIndex = z + 3 })
    corner(flare, 3)
    local image = New("\x49mageLabel", { Parent = root, Name = "\x41ccretionMaterial", Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1, Image = blackholeSpriteAsset, ImageRectSize = Vector2.new(96, 96),
        ImageRectOffset = Vector2.new(0, 0), ScaleType = Enum.ScaleType.Crop, ImageTransparency = .02,
        Visible = blackholeSpriteAsset ~= "", ZIndex = z + 4 })
    if blackholeSpriteAsset ~= "" then
        fallback.Visible = false
    else
        local idleRing = TweenService:Create(ring, TweenInfo.new(14, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false), { Rotation = ring.Rotation + 360 })
        idleRing:Play()
    end
    table.insert(blackholeFrames, image)
    return root, { root = root, image = image, fallback = fallback, ring = ring, ringStroke = ringStroke, core = core, flare = flare }
end

    local frameIndex = 0
    local function advanceFrames()
        if blackholeSpriteAsset == "" then return end
        frameIndex = (frameIndex + 1) % 96
        local offset = Vector2.new((frameIndex % 12) * 96, math.floor(frameIndex / 12) * 96)
        for index = #blackholeFrames, 1, -1 do
            local image = blackholeFrames[index]
            if image and image.Parent then image.ImageRectOffset = offset else table.remove(blackholeFrames, index) end
        end
    end
    return {
        Create = createBlackholeMark,
        SpriteAsset = blackholeSpriteAsset,
        Advance = advanceFrames,
        HeroMark = nil,
        LastWindowPosition = nil,
        TransitionBusy = false,
    }
end)()

local gui = New("\x53creenGui", { Name = "\x4eoirSilentAimUI", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = guiParent })
__NOIR_GUARD.gui = gui
local scale = New("\x55IScale", { Parent = gui, Scale = 1 })
function rescale()
    local v = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
    scale.Scale = math.clamp(math.min(v.X / 1240, v.Y / 740, 1), 0.24, 1)
end
rescale()
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("\x56iewportSize"):Connect(rescale) end

local win = New("\x46rame", { Parent = gui, Name = "\x57indow", AnchorPoint = Vector2.new(.5, .5),
    Position = NoirPersistence.GetPosition("\x77indow", UDim2.fromScale(.5, .5)), Size = UDim2.fromOffset(1180, 700),
    BackgroundColor3 = C.base, BackgroundTransparency = .04, ClipsDescendants = true, Visible = false })
local winScale = New("\x55IScale", { Parent = win, Scale = 1 })
corner(win, 22)
local winStroke = stroke(win, C.border, .5); winStroke.Thickness = 1.5
New("\x55IGradient", { Parent = win, Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(20,22,26)),
    ColorSequenceKeypoint.new(.45, Color3.fromRGB(9,10,13)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(3,4,6)) }), Rotation = 25 })

local navButtons, navIcons = {}, {}
local sidebar = New("\x46rame", { Parent = win, Size = UDim2.fromOffset(240, 700), BackgroundColor3 = C.surface, BackgroundTransparency = .28 })
corner(sidebar, 22); stroke(sidebar, C.border, .68)
__NOIR_GUARD.blackhole.Create(sidebar, UDim2.fromOffset(22, 28), 50, Vector2.zero, 5, 25)
local logo = New("\x54extLabel", { Parent = sidebar, Position = UDim2.fromOffset(84, 32), Size = UDim2.fromOffset(136, 42),
    BackgroundTransparency = 1, Text = "\x4eOIR", TextColor3 = C.text, TextSize = 32, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left })
New("\x55IGradient", { Parent = logo, Color = ColorSequence.new(C.text, C.accent2), Rotation = 0 })
text(sidebar, "\x45VENT HORIZON  //  CLIENT", 9, UDim2.fromOffset(86, 75), true)
do
    local navDefs = {
        { "\x68ome",   16898613509, Vector2.new(820, 147), "\x48ome" },
        { "\x6dain",   16898613509, Vector2.new(820, 147), "\x4dain" },
        { "\x61im",    16898613777, Vector2.new(967, 759), "\x43ombat" },
        { "\x77orld",  16898613509, Vector2.new(771, 563), "\x57orld" },
        { "\x6dap",    16898613509, Vector2.new(771, 563), "\x4dap" },
        { "\x66arm",   16898613509, Vector2.new(771, 563), "\x41utofarm" },
        { "\x76isual", 16898613353, Vector2.new(771, 563), "\x56isuals" },
        { "\x73kins",  16898613353, Vector2.new(771, 563), "\x53kins" },
        { "\x65motes", 16898613777, Vector2.new(967, 759), "\x45motes" },
        { "\x6disc",   16898613509, Vector2.new(820, 147), "\x4disc" },
    }
    for i, d in ipairs(navDefs) do
        local b = New("\x54extButton", { Parent = sidebar, Position = UDim2.fromOffset(16, 108 + (i - 1) * 44), Size = UDim2.fromOffset(208, 42),
            BackgroundColor3 = C.surface, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Name = d[4] })
        corner(b, 12)
        local ic = New("\x49mageLabel", { Parent = b, Position = UDim2.fromOffset(14, 11), Size = UDim2.fromOffset(24, 24),
            BackgroundTransparency = 1, Image = "\x72bxassetid://" .. d[2], ImageRectSize = Vector2.new(48, 48), ImageRectOffset = d[3],
            ImageColor3 = C.dim })
        local lbl = New("\x54extLabel", { Parent = b, Position = UDim2.fromOffset(50, 0), Size = UDim2.new(1, -60, 1, 0),
            BackgroundTransparency = 1, Text = d[4], TextColor3 = C.dim, TextSize = 15, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left })
        local bar = New("\x46rame", { Parent = b, Position = UDim2.fromOffset(0, 12), Size = UDim2.fromOffset(3, 22), BackgroundColor3 = C.accent, BackgroundTransparency = 1 })
        corner(bar, 2)
        local glyphs = nil
        local rings = nil
        if d[1] == "\x65motes" then
             
            ic.Visible = false
            glyphs = {}
            local function glyphPart(position, size, rounded)
                local part = New("\x46rame", { Parent = b, Position = position, Size = size, BackgroundColor3 = C.dim, BorderSizePixel = 0 })
                if rounded then corner(part, rounded) end
                glyphs[#glyphs + 1] = part
            end
            glyphPart(UDim2.fromOffset(20, 8), UDim2.fromOffset(10, 10), 5)
            glyphPart(UDim2.fromOffset(21, 18), UDim2.fromOffset(8, 10), 3)
            glyphPart(UDim2.fromOffset(15, 20), UDim2.fromOffset(20, 4), 2)
            glyphPart(UDim2.fromOffset(19, 27), UDim2.fromOffset(4, 8), 2)
            glyphPart(UDim2.fromOffset(27, 27), UDim2.fromOffset(4, 8), 2)
        elseif d[1] == "\x73kins" then
            ic.Visible = false
            glyphs = {}
            local function glyphPart(position, size, rounded)
                local part = New("\x46rame", { Parent = b, Position = position, Size = size, BackgroundColor3 = C.dim, BorderSizePixel = 0 })
                if rounded then corner(part, rounded) end
                glyphs[#glyphs + 1] = part
            end
            glyphPart(UDim2.fromOffset(22, 10), UDim2.fromOffset(8, 24), 3)
            glyphPart(UDim2.fromOffset(20, 8), UDim2.fromOffset(12, 6), 2)
        elseif d[1] == "\x6dap" then
            ic.Visible = false
            glyphs = {}
            local function glyphPart(position, size, rounded)
                local part = New("\x46rame", { Parent = b, Position = position, Size = size, BackgroundColor3 = C.dim, BorderSizePixel = 0 })
                if rounded then corner(part, rounded) end
                glyphs[#glyphs + 1] = part
            end
            glyphPart(UDim2.fromOffset(20, 9), UDim2.fromOffset(12, 12), 6)
            glyphPart(UDim2.fromOffset(23, 20), UDim2.fromOffset(6, 10), 2)
        elseif d[1] == "\x66arm" then
            ic.Visible = false
            glyphs = {}
            local function glyphPart(position, size, rounded)
                local part = New("\x46rame", { Parent = b, Position = position, Size = size, BackgroundColor3 = C.dim, BorderSizePixel = 0 })
                if rounded then corner(part, rounded) end
                glyphs[#glyphs + 1] = part
            end
            glyphPart(UDim2.fromOffset(18, 14), UDim2.fromOffset(16, 16), 8)
            glyphPart(UDim2.fromOffset(22, 18), UDim2.fromOffset(8, 8), 4)
        elseif d[1] == "\x6disc" then
             
            ic.Visible = false
            glyphs, rings = {}, {}
            local ring = New("\x46rame", { Parent = b, Position = UDim2.fromOffset(14, 10), Size = UDim2.fromOffset(26, 26), BackgroundTransparency = 1, BorderSizePixel = 0 })
            corner(ring, 13)
            local ringStroke = New("\x55IStroke", { Parent = ring, Color = C.dim, Thickness = 1.5, Transparency = .08 })
            rings[#rings + 1] = ringStroke
            for index = 0, 2 do
                local dot = New("\x46rame", { Parent = ring, Position = UDim2.fromOffset(5 + index * 6, 11), Size = UDim2.fromOffset(4, 4), BackgroundColor3 = C.dim, BorderSizePixel = 0 })
                corner(dot, 2); glyphs[#glyphs + 1] = dot
            end
        end
        navButtons[d[1]] = b; navIcons[d[1]] = { icon = ic, label = lbl, bar = bar, glyphs = glyphs, rings = rings }
    end
end
local status = New("\x46rame", { Parent = sidebar, Position = UDim2.fromOffset(16, 596), Size = UDim2.fromOffset(208, 84), BackgroundColor3 = C.panel, BackgroundTransparency = .18 })
corner(status, 16); stroke(status, C.border, .6)
local statusDot = New("\x46rame", { Parent = status, Position = UDim2.fromOffset(16, 21), Size = UDim2.fromOffset(8, 8), BackgroundColor3 = C.accent })
corner(statusDot, 4)
text(status, "\x43onnected", 13, UDim2.fromOffset(30, 15))
text(status, "\x4eoir Client • v6.1", 15, UDim2.fromOffset(16, 45))

local header = New("\x46rame", { Parent = win, Position = UDim2.fromOffset(240, 0), Size = UDim2.new(1, -240, 0, 96), BackgroundTransparency = 1 })
text(header, "\x4eOIR HUB", 24, UDim2.fromOffset(28, 24))
text(header, "\x53ilent Aim • ESP • Prediction", 13, UDim2.fromOffset(29, 56), true)
local creatorImage = ""
do
    local customAsset = (type(getcustomasset) == "\x66unction" and getcustomasset) or (type(getsynasset) == "\x66unction" and getsynasset)
    if type(writefile) == "\x66unction" and customAsset then
        local encoded = "\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\x6fCiiig//2Q=="
        local alphabet = "\x41BCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        local decoded = encoded:gsub("\x5b^" .. alphabet .. "\x3d]", ""):gsub("\x2e", function(x)
            if x == "\x3d" then return "" end
            local r, f = "", alphabet:find(x, 1, true) - 1
            for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and "\x31" or "\x30") end
            return r
        end):gsub("\x25d%d%d?%d?%d?%d?%d?%d?", function(x)
            if #x ~= 8 then return "" end
            local c = 0
            for i = 1, 8 do c = c + (x:sub(i, i) == "\x31" and 2 ^ (8 - i) or 0) end
            return string.char(c)
        end)
        local imagePath = ASSETS_FOLDER .. "\x2fNOIR_CREATOR.jpg"
        pcall(writefile, imagePath, decoded)
        local ok, asset = pcall(customAsset, imagePath)
        if ok then creatorImage = asset end
    end
end
local search = New("\x54extBox", { Parent = header, Position = UDim2.new(1, -470, 0, 26), Size = UDim2.fromOffset(300, 44),
    BackgroundColor3 = C.panel, PlaceholderText = "\x20  Search features...", Text = "", TextColor3 = C.text,
    PlaceholderColor3 = C.dim, TextSize = 14, Font = Enum.Font.Gotham, ClearTextOnFocus = false })
corner(search, 12); stroke(search)
local icon = New("\x49mageLabel", { Parent = header, Position = UDim2.new(1, -152, 0, 26), Size = UDim2.fromOffset(44, 44),
    BackgroundColor3 = C.panel, Image = creatorImage, ScaleType = Enum.ScaleType.Crop })
corner(icon, 13); stroke(icon, C.border, .45)
if creatorImage == "" then local fb = text(icon, "\x4e", 22, UDim2.fromOffset(0, 8)); fb.TextXAlignment = Enum.TextXAlignment.Center end
function styleCircularButton(b, diameter)
    b.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
    b.BackgroundTransparency = .28
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.ClipsDescendants = false
    b.ZIndex = 20
    corner(b, math.floor(diameter / 2))
    local outer = New("\x55IStroke", { Parent = b, Color = Color3.fromRGB(255, 255, 255), Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
    local gradient = New("\x55IGradient", { Parent = outer, Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 40)),
        ColorSequenceKeypoint.new(.22, Color3.fromRGB(250, 250, 252)),
        ColorSequenceKeypoint.new(.48, Color3.fromRGB(70, 70, 78)),
        ColorSequenceKeypoint.new(.72, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(45, 45, 52)),
    }) })
    table.insert(gradientStrokes, gradient)
    local inner = New("\x55IStroke", { Parent = b, Color = Color3.fromRGB(105, 105, 112), Transparency = .5, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
    local innerGradient = gradient:Clone(); innerGradient.Rotation = 180; innerGradient.Parent = inner
    table.insert(gradientStrokes, innerGradient)
    local sound = Instance.new("\x53ound")
    sound.Name = "\x4eoirButtonSound"; sound.SoundId = "\x72bxassetid://3868133279"; sound.Volume = .35; sound.Parent = b
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
function topButton(txt, x, color, fontSize)
    local b = New("\x54extButton", { Parent = header, Position = UDim2.new(1, x, 0, 26), Size = UDim2.fromOffset(44, 44),
        BackgroundColor3 = color or C.btn, Text = txt, TextColor3 = C.text, TextSize = fontSize or 22, Font = Enum.Font.GothamBold })
    return styleCircularButton(b, 44)
end

 
 
local miniArrowImage = ""
do
    local customAsset = (type(getcustomasset) == "\x66unction" and getcustomasset) or (type(getsynasset) == "\x66unction" and getsynasset)
    if type(writefile) == "\x66unction" and customAsset then
        local encodedArrow = "\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\x2fwNVQ1uk90AZPQAAAABJRU5ErkJggg=="
        local alphabet = "\x41BCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        local decodedArrow = encodedArrow:gsub("\x5b^" .. alphabet .. "\x3d]", ""):gsub("\x2e", function(x)
            if x == "\x3d" then return "" end
            local r, f = "", alphabet:find(x, 1, true) - 1
            for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and "\x31" or "\x30") end
            return r
        end):gsub("\x25d%d%d?%d?%d?%d?%d?%d?", function(x)
            if #x ~= 8 then return "" end
            local c = 0
            for i = 1, 8 do c = c + (x:sub(i, i) == "\x31" and 2 ^ (8 - i) or 0) end
            return string.char(c)
        end)
        local arrowPath = ASSETS_FOLDER .. "\x2fNOIR_MINIMIZE_ARROW.png"
        local wrote = pcall(writefile, arrowPath, decodedArrow)
        if wrote then
            local ok, asset = pcall(customAsset, arrowPath)
            if ok and type(asset) == "\x73tring" then miniArrowImage = asset end
        end
    end
end

local mini = topButton(miniArrowImage == "" and "↘" or "", -98, C.btn, 35)
if miniArrowImage ~= "" then
    New("\x49mageLabel", {
        Parent = mini,
        Name = "\x4dinimizeArrow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(35, 35),
        BackgroundTransparency = 1,
        Active = false,
        Image = miniArrowImage,
        ImageColor3 = C.text,
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = mini.ZIndex + 1,
    })
end

__NOIR_GUARD.blackhole.LastWindowPosition = win.Position
local dragging, dragStart, startPos
header.Active = true
header.InputBegan:Connect(function(input)
    if __NOIR_GUARD.blackhole.TransitionBusy then return end
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
        if dragging then __NOIR_GUARD.blackhole.LastWindowPosition = win.Position; NoirPersistence.SetPosition("\x77indow", win.Position) end
        dragging = false
    end
end)

local restore = New("\x54extButton", { Parent = gui, AnchorPoint = Vector2.new(1, .5), Position = NoirPersistence.GetPosition("\x72estore", UDim2.new(1, -22, .5, 0)),
    Size = UDim2.fromOffset(62, 62), BackgroundColor3 = C.panel, Text = "", TextColor3 = C.text, TextSize = 30,
    Font = Enum.Font.GothamBold, Visible = false, AutoButtonColor = false })
styleCircularButton(restore, 62)
__NOIR_GUARD.blackhole.Create(restore, UDim2.fromScale(.5, .5), 48, Vector2.new(.5, .5), restore.ZIndex + 1, 24)
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
        restoreDragging = false; NoirPersistence.SetPosition("\x72estore", restore.Position)
    end
end)
function __NOIR_GUARD.blackhole.CollapseTargetPosition()
    local center = win.AbsolutePosition + win.AbsoluteSize / 2
    local focus
    if __NOIR_GUARD.blackhole.HeroMark and __NOIR_GUARD.blackhole.HeroMark.Parent and __NOIR_GUARD.blackhole.HeroMark.AbsoluteSize.X > 0 then
        focus = __NOIR_GUARD.blackhole.HeroMark.AbsolutePosition + __NOIR_GUARD.blackhole.HeroMark.AbsoluteSize / 2
    else
        focus = center + Vector2.new(win.AbsoluteSize.X * .18, -win.AbsoluteSize.Y * .08)
    end
    local shift = focus - center
    local factor = math.max(scale.Scale, .08)
    local position = win.Position
    return UDim2.new(position.X.Scale, position.X.Offset + shift.X / factor,
        position.Y.Scale, position.Y.Offset + shift.Y / factor)
end
function __NOIR_GUARD.blackhole.CollapseWindow()
    if __NOIR_GUARD.blackhole.TransitionBusy or not win.Visible then return end
    __NOIR_GUARD.blackhole.TransitionBusy = true
    __NOIR_GUARD.blackhole.LastWindowPosition = win.Position
    local destination = __NOIR_GUARD.blackhole.CollapseTargetPosition()
    TweenService:Create(win, TweenInfo.new(.64, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        Position = destination, BackgroundTransparency = 1, Rotation = 4.2,
    }):Play()
    TweenService:Create(winScale, TweenInfo.new(.64, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { Scale = .025 }):Play()
    task.delay(.66, function()
        if not win.Parent then __NOIR_GUARD.blackhole.TransitionBusy = false; return end
        win.Visible = false
        restore.Visible = true
        __NOIR_GUARD.blackhole.TransitionBusy = false
    end)
end
function __NOIR_GUARD.blackhole.ReopenWindow()
    if __NOIR_GUARD.blackhole.TransitionBusy then return end
    __NOIR_GUARD.blackhole.TransitionBusy = true
    if restoreMoved then restoreMoved = false; __NOIR_GUARD.blackhole.TransitionBusy = false; return end
    local collapsedPosition = win.Position
    restore.Visible = false
    win.Visible = true
    win.Position = collapsedPosition
    win.BackgroundTransparency = 1
    win.Rotation = 4.2
    winScale.Scale = .025
    TweenService:Create(win, TweenInfo.new(.68, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = __NOIR_GUARD.blackhole.LastWindowPosition, BackgroundTransparency = .04, Rotation = 0,
    }):Play()
    TweenService:Create(winScale, TweenInfo.new(.72, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
    task.delay(.74, function()
        if win.Parent then win.Position = __NOIR_GUARD.blackhole.LastWindowPosition; winScale.Scale = 1 end
        __NOIR_GUARD.blackhole.TransitionBusy = false
    end)
end
mini.MouseButton1Click:Connect(__NOIR_GUARD.blackhole.CollapseWindow)
restore.MouseButton1Click:Connect(__NOIR_GUARD.blackhole.ReopenWindow)

local content = New("\x53crollingFrame", { Parent = win, Position = UDim2.fromOffset(275, 110), Size = UDim2.new(1, -300, 1, -130),
    BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0,
    CanvasSize = UDim2.fromOffset(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.None,
    ScrollingDirection = Enum.ScrollingDirection.Y, ScrollingEnabled = false, Active = false,
    ElasticBehavior = Enum.ElasticBehavior.Never, VerticalScrollBarInset = Enum.ScrollBarInset.Always })
local cols, configContent, configCols, visualContent, visualCols, mainContent, mainCols, worldContent, worldCols, emotesContent, emotesCols, miscContent, miscCols

do
 
 
local function makeDualScrollColumns(parent)
    local col = New("\x53crollingFrame", { Parent = parent, Name = "\x4eoirColumn1",
        Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, -6, 1, 0),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 5, ScrollBarImageColor3 = C.accent,
        CanvasSize = UDim2.fromOffset(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y, ScrollingEnabled = true, Active = true,
        ElasticBehavior = Enum.ElasticBehavior.WhenScrollable, VerticalScrollBarInset = Enum.ScrollBarInset.Always })
    New("\x55IListLayout", { Parent = col, Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder })
    New("\x55IPadding", { Parent = col, PaddingBottom = UDim.new(0, 16), PaddingRight = UDim.new(0, 4) })
    return { col, col }
end
local function configureDualScrollPage(page)
    page.ScrollingEnabled = false
    page.Active = false
    page.ScrollBarThickness = 0
    page.AutomaticCanvasSize = Enum.AutomaticSize.None
    page.CanvasSize = UDim2.fromOffset(0, 0)
end

cols = makeDualScrollColumns(content)
configContent = content:Clone(); configContent.Name = "\x43onfigContent"; configContent.Parent = win; configContent.Visible = false; configContent:ClearAllChildren(); configureDualScrollPage(configContent)
configCols = makeDualScrollColumns(configContent)
content.Position = UDim2.fromOffset(282, 104); content.Size = UDim2.new(1, -306, 1, -128); content.Visible = false
configContent.Position = content.Position; configContent.Size = content.Size
visualContent = content:Clone(); visualContent.Name = "\x56isualContent"; visualContent.Parent = win; visualContent.Visible = false; visualContent:ClearAllChildren(); configureDualScrollPage(visualContent)
visualCols = makeDualScrollColumns(visualContent)
mainContent = content:Clone();
 mainContent.Name = "\x4dainContent"; mainContent.Parent = win; mainContent.Visible = false; mainContent:ClearAllChildren(); configureDualScrollPage(mainContent)
mainCols = makeDualScrollColumns(mainContent)
worldContent = content:Clone(); worldContent.Name = "\x57orldContent"; worldContent.Parent = win; worldContent.Visible = false; worldContent:ClearAllChildren(); configureDualScrollPage(worldContent)
worldCols = makeDualScrollColumns(worldContent)
emotesContent = content:Clone(); emotesContent.Name = "\x45motesContent"; emotesContent.Parent = win; emotesContent.Visible = false; emotesContent:ClearAllChildren(); configureDualScrollPage(emotesContent)
emotesCols = makeDualScrollColumns(emotesContent)
miscContent = content:Clone(); miscContent.Name = "\x4discContent"; miscContent.Parent = win; miscContent.Visible = false; miscContent:ClearAllChildren(); configureDualScrollPage(miscContent)
miscCols = makeDualScrollColumns(miscContent)
do
    local mapPage = content:Clone()
    mapPage.Name = "\x4dapContent"
    mapPage.Parent = win
    mapPage.Visible = false
    mapPage:ClearAllChildren()
    configureDualScrollPage(mapPage)
    makeDualScrollColumns(mapPage)
    local farmPage = content:Clone()
    farmPage.Name = "\x46armContent"
    farmPage.Parent = win
    farmPage.Visible = false
    farmPage:ClearAllChildren()
    configureDualScrollPage(farmPage)
    makeDualScrollColumns(farmPage)
end
end

local dashboard = New("\x46rame", { Parent = win, Position = content.Position, Size = content.Size, BackgroundTransparency = 1 })
local profile = New("\x46rame", { Parent = dashboard, Position = UDim2.fromOffset(0, 0), Size = UDim2.fromOffset(430, 168), BackgroundColor3 = C.panel, BackgroundTransparency = .25 })
corner(profile, 18); stroke(profile, C.border, .5)
local avatar = New("\x49mageLabel", { Parent = profile, Position = UDim2.fromOffset(22, 24), Size = UDim2.fromOffset(120, 120), BackgroundColor3 = C.surface })
corner(avatar, 20); stroke(avatar, C.border, .45)
task.spawn(function()
    local ok, img = pcall(function() return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size180x180) end)
    if ok then avatar.Image = img end
end)
text(profile, LocalPlayer.DisplayName, 24, UDim2.fromOffset(162, 32))
text(profile, "\x40" .. LocalPlayer.Name, 15, UDim2.fromOffset(163, 70), true)
local pill = New("\x46rame", { Parent = profile, Position = UDim2.fromOffset(162, 104), Size = UDim2.fromOffset(158, 30), BackgroundColor3 = C.accent, BackgroundTransparency = .8 })
corner(pill, 15); stroke(pill, C.accent, .35)
local pillDot = New("\x46rame", { Parent = pill, Position = UDim2.fromOffset(12, 11), Size = UDim2.fromOffset(8, 8), BackgroundColor3 = C.accent }); corner(pillDot, 4)
TweenService:Create(pillDot, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { BackgroundTransparency = .58 }):Play()
text(pill, "\x43onnected", 13, UDim2.fromOffset(26, 7))
local heroCard = New("\x46rame", { Parent = dashboard, Position = UDim2.fromOffset(446, 0), Size = UDim2.new(1, -446, 0, 168), BackgroundColor3 = C.card, BackgroundTransparency = .12, ClipsDescendants = true })
corner(heroCard, 18); stroke(heroCard, C.border, .38)
New("\x55IGradient", { Parent = heroCard, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(22,24,29)), ColorSequenceKeypoint.new(1, Color3.fromRGB(5,6,9)) }), Rotation = 25 })
__NOIR_GUARD.blackhole.HeroMark = __NOIR_GUARD.blackhole.Create(heroCard, UDim2.new(1, -166, 0, 5), 156, Vector2.zero, 2, 14)
(function()
    local heroTitle = text(heroCard, "\x4eOIR  /  EVENT HORIZON", 21, UDim2.fromOffset(26, 22)); heroTitle.Size = UDim2.fromOffset(248, 32); heroTitle.Font = Enum.Font.GothamBold
    local heroSubtitle = text(heroCard, "\x566.1  •  BLACK-HOLE INTERFACE", 11, UDim2.fromOffset(27, 58), true); heroSubtitle.Size = UDim2.fromOffset(236, 20)
    local heroDetail = text(heroCard, "\x41IM  /  ESP  /  WORLD SYSTEMS", 10, UDim2.fromOffset(27, 83), true); heroDetail.Size = UDim2.fromOffset(234, 18)
end)()
local statText = text(heroCard, "", 12, UDim2.fromOffset(27, 111), true); statText.Size = UDim2.fromOffset(235, 20)
New("\x46rame", { Parent = heroCard, Position = UDim2.fromOffset(27, 103), Size = UDim2.fromOffset(226, 1), BackgroundColor3 = C.border, BackgroundTransparency = .42, BorderSizePixel = 0 })
local fpsCard = New("\x46rame", { Parent = dashboard, Position = UDim2.fromOffset(0, 184), Size = UDim2.fromOffset(286, 132), BackgroundColor3 = C.panel, BackgroundTransparency = .25 })
corner(fpsCard, 18); stroke(fpsCard, C.border, .5)
text(fpsCard, "\x46PS", 14, UDim2.fromOffset(22, 20), true)
local fpsText = text(fpsCard, "\x360", 42, UDim2.fromOffset(22, 50)); fpsText.TextColor3 = C.text
local pingCard = New("\x46rame", { Parent = dashboard, Position = UDim2.fromOffset(303, 184), Size = UDim2.fromOffset(286, 132), BackgroundColor3 = C.panel, BackgroundTransparency = .25 })
corner(pingCard, 18); stroke(pingCard, C.border, .5)
text(pingCard, "\x4eETWORK LATENCY", 14, UDim2.fromOffset(22, 20), true)
local pingText = text(pingCard, "\x2d- ms", 42, UDim2.fromOffset(22, 50)); pingText.TextColor3 = C.text
local playerCard = New("\x46rame", { Parent = dashboard, Position = UDim2.fromOffset(606, 184), Size = UDim2.fromOffset(286, 132), BackgroundColor3 = C.panel, BackgroundTransparency = .25 })
corner(playerCard, 18); stroke(playerCard, C.border, .5)
text(playerCard, "\x50LAYERS", 14, UDim2.fromOffset(22, 20), true)
local playerText = text(playerCard, "\x30", 42, UDim2.fromOffset(22, 50)); playerText.TextColor3 = C.text
local infoCard = New("\x46rame", { Parent = dashboard, Position = UDim2.fromOffset(0, 332), Size = UDim2.new(1, 0, 1, -348), BackgroundColor3 = C.panel, BackgroundTransparency = .3 })
corner(infoCard, 18); stroke(infoCard, C.border, .5)
text(infoCard, "\x51UICK START", 18, UDim2.fromOffset(24, 22))
text(infoCard, "\x4fpen Main for player tools, World for gun & fling tools, Visuals\x20for ESP.", 14, UDim2.fromOffset(25, 54), true)
text(infoCard, "\x53ettings are saved automatically to Noir Hub/configs.", 14, UDim2.fromOffset(25, 78), true)
local frameCounter, lastFps = 0, os.clock()
RunService.RenderStepped:Connect(function()
    frameCounter += 1
    local now = os.clock()
    if now - lastFps >= 1 then
        fpsText.Text = tostring(math.floor(frameCounter / (now - lastFps) + .5))
        frameCounter = 0; lastFps = now
        local ok, v = pcall(function() return Stats.Network.ServerStatsItem["\x44ata Ping"]:GetValue() end)
        pingText.Text = ok and (tostring(math.floor(v + .5)) .. "\x20ms") or "\x2d- ms"
        local pl = #Players:GetPlayers()
        playerText.Text = tostring(pl)
        statText.Text = "\x4cOADED  •  " .. tostring(pl) .. "\x20PLAYERS"
    end
end)

task.spawn(function()
    while gui.Parent do
        if __NOIR_GUARD.blackhole.SpriteAsset ~= "" and (win.Visible or restore.Visible) then
            __NOIR_GUARD.blackhole.Advance()
        end
        task.wait(.12)
    end
end)

local activePage = "\x68ome"
local selectPage
do
    local pageObjects = { home = dashboard, main = mainContent, aim = content, world = worldContent, map = win:FindFirstChild("\x4dapContent"), farm = win:FindFirstChild("\x46armContent"), visual = visualContent, emotes = emotesContent, misc = miscContent }
    pcall(function()
        getgenv().__NoirRegisterPage = function(name, object)
            if type(name) == "\x73tring" and typeof(object) == "\x49nstance" then pageObjects[name] = object end
        end
    end)
    local pageBasePosition = content.Position
    local pageTransitionId = 0
    local function pageScaleFor(object)
        local scaler = object:FindFirstChild("\x4eoirPageScale")
        if not scaler then scaler = New("\x55IScale", { Name = "\x4eoirPageScale", Scale = 1, Parent = object }) end
        return scaler
    end
    function selectPage(page)
        if not pageObjects[page] then page = "\x68ome" end
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
            if newObject:IsA("\x53crollingFrame") then
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
for name, b in pairs(navButtons) do b.MouseButton1Click:Connect(function() if activePage == name then selectPage("\x68ome") else selectPage(name) end end) end
selectPage("\x68ome")

local sectionCount, mainSectionCount, worldSectionCount, visualSectionCount, emotesSectionCount, miscSectionCount, configSectionCount = 0, 0, 0, 0, 0, 0, 0
local sectionPanels, controls = {}, {}
function refreshCanvas()
     
     
    task.defer(function()
        for _, page in ipairs({ content, configContent, visualContent, mainContent, worldContent, emotesContent, miscContent }) do
            if page and page.Parent then page.CanvasSize = UDim2.fromOffset(0, 0) end
        end
    end)
end
search:GetPropertyChangedSignal("\x54ext"):Connect(function()
    local q = string.lower(search.Text or "")
    local counts = { main = 0, aim = 0, world = 0, visual = 0, emotes = 0, misc = 0, map = 0, farm = 0 }
    local firstPage, firstSub
    for _, entry in ipairs(sectionPanels) do
        local hay = entry.name
        for _, d in ipairs(entry.panel:GetDescendants()) do
            if d:IsA("\x54extLabel") or d:IsA("\x54extButton") then hay = hay .. "\x20" .. string.lower(d.Text or "") end
        end
        local match = q == "" or string.find(hay, q, 1, true) ~= nil
        entry.panel.Visible = match
        if match then
            counts[entry.page] = (counts[entry.page] or 0) + 1
            if q ~= "" and not firstPage then
                firstPage, firstSub = entry.page, entry.sub
            end
        end
    end
    if q ~= "" and firstPage then
        if activePage == "\x68ome" or activePage == "\x73kins" or activePage ~= firstPage then
            selectPage(firstPage)
        end
        local shower = getgenv().__NoirSubShow and getgenv().__NoirSubShow[firstPage]
        if type(shower) == "\x66unction" and firstSub then pcall(shower, firstSub) end
    elseif q == "" then
        local cur = getgenv().__NoirSubCurrent and getgenv().__NoirSubCurrent[activePage]
        local shower = getgenv().__NoirSubShow and getgenv().__NoirSubShow[activePage]
        if type(shower) == "\x66unction" and cur then pcall(shower, cur) end
    end
    refreshCanvas()
end)

local host = {}

local notificationHolder = New("\x46rame", {
    Parent = gui, Name = "\x4eotificationRail", AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -20, 0, 82), Size = UDim2.new(0, 360, 0, 270),
    BackgroundTransparency = 1, ClipsDescendants = false, ZIndex = 1000,
})
local notificationLayout = New("\x55IListLayout", {
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
    local card = New("\x46rame", {
        Parent = notificationHolder, Name = "\x54oast_" .. tostring(notificationSerial),
        Size = UDim2.new(1, 0, 0, 88), BackgroundColor3 = C.panel,
        BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = notificationSerial,
        ClipsDescendants = false, ZIndex = 1000,
    })
    corner(card, 10)
    stroke(card, C.accent, .34)
    New("\x55IGradient", { Parent = card, Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(20,22,27)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(7,8,11)),
    }), Rotation = 15 })
    New("\x46rame", { Parent = card, Position = UDim2.fromOffset(0, 12), Size = UDim2.fromOffset(2, 62),
        BackgroundColor3 = C.accent, BorderSizePixel = 0, ZIndex = 1001 })
    __NOIR_GUARD.blackhole.Create(card, UDim2.fromOffset(13, 25), 38, Vector2.zero, 1002, 19)
    local badge = New("\x54extLabel", { Parent = card, Position = UDim2.fromOffset(61, 10), Size = UDim2.new(1, -122, 0, 17),
        BackgroundTransparency = 1, Text = "\x4eOIR  //  EVENT LOG", TextColor3 = C.accent2,
        TextSize = 9, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
        TextTransparency = 1, ZIndex = 1003 })
    local stampText = "\x53YSTEM"
    pcall(function() stampText = os.date("\x25H:%M:%S") end)
    local stamp = New("\x54extLabel", { Parent = card, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -13, 0, 10), Size = UDim2.fromOffset(62, 16),
        BackgroundTransparency = 1, Text = stampText, TextColor3 = C.dim,
        TextSize = 8, Font = Enum.Font.Code, TextXAlignment = Enum.TextXAlignment.Right,
        TextTransparency = 1, ZIndex = 1003 })
    local message = New("\x54extLabel", { Parent = card, Position = UDim2.fromOffset(61, 31), Size = UDim2.new(1, -76, 0, 40),
        BackgroundTransparency = 1, Text = tostring(title), TextColor3 = C.text,
        TextSize = 13, Font = Enum.Font.Gotham, TextWrapped = true, TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
        TextTransparency = 1, ZIndex = 1003 })
    local progress = New("\x46rame", { Parent = card, Position = UDim2.fromOffset(61, 77), Size = UDim2.new(1, -76, 0, 2),
        BackgroundColor3 = C.accent, BorderSizePixel = 0, ZIndex = 1003 })
    local scaleIn = New("\x55IScale", { Parent = card, Scale = .92 })
    table.insert(activeNotifications, card); trimNotifications()
    TweenService:Create(card, TweenInfo.new(.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = .08 }):Play()
    TweenService:Create(scaleIn, TweenInfo.new(.34, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
    TweenService:Create(badge, TweenInfo.new(.22), { TextTransparency = 0 }):Play()
    TweenService:Create(stamp, TweenInfo.new(.22), { TextTransparency = 0 }):Play()
    TweenService:Create(message, TweenInfo.new(.26), { TextTransparency = 0 }):Play()
    TweenService:Create(progress, TweenInfo.new(life, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) }):Play()
    task.delay(life, function()
        for i = #activeNotifications, 1, -1 do
            if activeNotifications[i] == card then table.remove(activeNotifications, i) break end
        end
        if card.Parent then
            TweenService:Create(card, TweenInfo.new(.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()
            TweenService:Create(scaleIn, TweenInfo.new(.24, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = .94 }):Play()
            TweenService:Create(badge, TweenInfo.new(.16), { TextTransparency = 1 }):Play()
            TweenService:Create(stamp, TweenInfo.new(.16), { TextTransparency = 1 }):Play()
            TweenService:Create(message, TweenInfo.new(.16), { TextTransparency = 1 }):Play()
            task.delay(.25, function() if card.Parent then card:Destroy() end end)
        end
    end)
end
function host.CreateTab()
    local tab = {}
    function tab:AddSection(name, description)
        local isVisual = name == "\x56isuals" or name == "\x4fbject ESP" or string.find(name, "\x56ISUAL", 1, true) == 1
        local isMain = string.sub(name, 1, 5) == "\x4dAIN "
        local function hasTag(p) return string.find(name, p, 1, true) ~= nil end
        local isFling = hasTag("\x46ling") or hasTag("⚡") or hasTag("🤖") or hasTag("📋") or hasTag("⚙") or hasTag("🔘") or hasTag("🔑")
        local isWorld = string.sub(name, 1, 6) == "\x57ORLD " or name == "\x42omb Jump+" or name == "\x47old Bomb Jump+" or isFling
        local isEmotes = string.sub(name, 1, 7) == "\x45MOTES " or name == "\x46E Animations" or name == "\x41bout"
        local isMisc = string.sub(name, 1, 5) == "\x4dISC " or name == "\x49nventory Unlimiter V5" or name == "\x50m-WallHop"
        local col, page = nil, "\x61im"
        if isVisual then visualSectionCount += 1; col = visualCols[(visualSectionCount - 1) % 2 + 1]; page = "\x76isual"
        elseif isMain then mainSectionCount += 1; col = mainCols[(mainSectionCount - 1) % 2 + 1]; page = "\x6dain"
        elseif isWorld then worldSectionCount += 1; col = worldCols[(worldSectionCount - 1) % 2 + 1]; page = "\x77orld"
        elseif isEmotes then emotesSectionCount += 1; col = emotesCols[(emotesSectionCount - 1) % 2 + 1]; page = "\x65motes"
        elseif isMisc then miscSectionCount += 1; col = miscCols[(miscSectionCount - 1) % 2 + 1]; page = "\x6disc"
        else sectionCount += 1; col = cols[(sectionCount - 1) % 2 + 1] end
        local panel = New("\x46rame", { Parent = col, Size = UDim2.new(1, 0, 0, 90), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = C.panel, BackgroundTransparency = .25, ClipsDescendants = true })
        corner(panel, 18); stroke(panel, C.border, .5)
        local tick = New("\x46rame", { Parent = panel, Position = UDim2.fromOffset(0, 16), Size = UDim2.fromOffset(3, 20), BackgroundColor3 = C.accent })
        corner(tick, 2)
        table.insert(sectionPanels, { panel = panel, page = page, name = string.lower(name .. "\x20" .. (description or "")) })
        local shownName = name:gsub("\x5eMAIN • ", ""):gsub("\x5eWORLD • ", ""):gsub("\x5eVISUAL • ", ""):gsub("\x5eEMOTES • ", ""):gsub("\x5eMISC • ", "")
        text(panel, shownName, 18, UDim2.fromOffset(24, 16))
        if description and description ~= "" then text(panel, description, 12, UDim2.fromOffset(24, 44), true) end
        local holder = New("\x46rame", { Parent = panel, Position = UDim2.fromOffset(20, description ~= "" and 74 or 57), Size = UDim2.new(1, -40, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 })
        New("\x55IListLayout", { Parent = holder, Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder })
        New("\x55IPadding", { Parent = holder, PaddingBottom = UDim.new(0, 12) })
        holder:GetPropertyChangedSignal("\x41bsoluteSize"):Connect(refreshCanvas); refreshCanvas()
        local api = { Name = name }
        local storagePrefix = name .. "\x3a:"
        local function row(label, h)
            local r = New("\x46rame", { Parent = holder, Size = UDim2.new(1, 0, 0, h or 62), BackgroundTransparency = 1 })
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
            local pill = New("\x54extButton", { Parent = r, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 8), Size = UDim2.fromOffset(64, 34),
                BackgroundColor3 = C.off, Text = "", AutoButtonColor = false })
            corner(pill, 17); stroke(pill, C.border, .55)
            local dot = New("\x46rame", { Parent = pill, Position = UDim2.fromOffset(4, 4), Size = UDim2.fromOffset(26, 26), BackgroundColor3 = Color3.fromRGB(150,155,162) })
            corner(dot, 13)
            local function set(v, persist)
                state = v == true
                TweenService:Create(pill, TweenInfo.new(.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { BackgroundColor3 = state and C.accent or C.off }):Play()
                TweenService:Create(dot, TweenInfo.new(.34, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = state and UDim2.fromOffset(34, 4) or UDim2.fromOffset(4, 4), BackgroundColor3 = state and Color3.new(1, 1, 1) or Color3.fromRGB(150,155,162), Size = UDim2.fromOffset(30, 30) }):Play()
                task.delay(.20, function() if dot.Parent then TweenService:Create(dot, TweenInfo.new(.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(26, 26) }):Play() end end)
                callback(state)
                if persist ~= false then NoirPersistence.data.toggles[storagePrefix .. label] = state; NoirPersistence.Save() end
            end
            local lastClick = 0
            local function toggleClick()
                local now = os.clock()
                if now - lastClick < .18 then return end
                lastClick = now
                set(not state, true)
            end
            pill.MouseButton1Click:Connect(toggleClick)
            pill.Activated:Connect(toggleClick)
            set(state, false)
            return function(v) set(v == nil and not state or v, true) end
        end
        function api:AddButton(label, callback)
            local b = New("\x54extButton", { Parent = holder, Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = C.btn,
                Text = label, TextColor3 = C.text, TextSize = 15, Font = Enum.Font.Gotham, AutoButtonColor = false })
            corner(b, 12); stroke(b, C.border, .5)
            b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(.18), { BackgroundColor3 = Color3.fromRGB(48,52,56) }):Play() end)
            b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(.18), { BackgroundColor3 = C.btn }):Play() end)
            local lastClick = 0
            local function fire()
                local now = os.clock()
                if now - lastClick < .18 then return end
                lastClick = now
                callback()
            end
            b.MouseButton1Click:Connect(fire)
            b.Activated:Connect(fire)
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
            local value = New("\x54extBox", { Parent = r, Position = UDim2.new(1, -72, 0, 5), Size = UDim2.fromOffset(72, 30), BackgroundColor3 = C.surface,
                BackgroundTransparency = .12, Text = tostring(default), TextColor3 = C.text, TextSize = 14, Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Center, ClearTextOnFocus = false })
            corner(value, 9); stroke(value, C.border, .4)
            local track = New("\x46rame", { Parent = r, Position = UDim2.new(0, 0, 1, -18), Size = UDim2.new(1, 0, 0, 6), BackgroundColor3 = C.off })
            corner(track, 3)
            local fill = New("\x46rame", { Parent = track, Size = UDim2.fromScale((default - min) / (max - min), 1), BackgroundColor3 = C.accent })
            corner(fill, 3)
            local knob = New("\x46rame", { Parent = track, AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new((default - min) / (max - min), 0, .5, 0), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = C.text })
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
            local b = New("\x54extButton", { Parent = r, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 4), Size = UDim2.fromOffset(190, 42),
                BackgroundColor3 = C.surface, Text = tostring(values[1] or "\x4eone") .. "\x20 ⌄", TextColor3 = C.text, TextSize = 14, Font = Enum.Font.Gotham, ZIndex = 5 })
            corner(b, 10); stroke(b)
            local popup
            local function close() if popup then popup:Destroy(); popup = nil end end
            local function set(v)
                local found = table.find(values, v)
                if found then idx = found end
                b.Text = tostring(values[idx] or "\x4eone") .. "\x20 ⌄"
                if values[idx] ~= nil then callback(values[idx]); NoirPersistence.data.dropdowns[storagePrefix .. label] = values[idx]; NoirPersistence.Save() end
            end
            local function open()
                close()
                popup = New("\x53crollingFrame", { Parent = gui, Position = UDim2.fromOffset(b.AbsolutePosition.X / scale.Scale, (b.AbsolutePosition.Y + b.AbsoluteSize.Y + 4) / scale.Scale),
                    Size = UDim2.fromOffset(b.AbsoluteSize.X / scale.Scale, math.min(#values * 38, 190)), CanvasSize = UDim2.fromOffset(0, #values * 38),
                    BackgroundColor3 = C.surface, BorderSizePixel = 0, ScrollBarThickness = 4, ZIndex = 50 })
                corner(popup, 10); stroke(popup, C.accent, .2)
                New("\x55IListLayout", { Parent = popup, SortOrder = Enum.SortOrder.LayoutOrder })
                for _, v in ipairs(values) do
                    local item = New("\x54extButton", { Parent = popup, Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, Text = tostring(v),
                        TextColor3 = C.text, TextSize = 14, Font = Enum.Font.Gotham, ZIndex = 51 })
                    item.MouseButton1Click:Connect(function() set(v); close() end)
                    item.Activated:Connect(function() set(v); close() end)
                end
            end
            local lastOpen = 0
            local function togglePopup()
                local now = os.clock()
                if now - lastOpen < .18 then return end
                lastOpen = now
                if popup then close() else open() end
            end
            b.MouseButton1Click:Connect(togglePopup)
            b.Activated:Connect(togglePopup)
            local ctl = {}
            function ctl:SetValue(v) set(v) end
            function ctl:Select(v) set(v) end
            function ctl:Refresh(newValues, selected) values = newValues or {}; idx = 1; set(selected or values[1]) end
            function ctl:ChangeItems(newValues) values = newValues or {}; idx = 1; set(values[1]) end
            return ctl
        end
        function api:AddTextBox(label, callback)
            local r = row(label, 64)
            local box = New("\x54extBox", { Parent = r, Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = C.surface,
                Text = "", PlaceholderText = label, TextColor3 = C.text, PlaceholderColor3 = C.dim, TextSize = 14, Font = Enum.Font.Gotham, ClearTextOnFocus = false })
            corner(box, 9); stroke(box)
            box.FocusLost:Connect(function() callback(box.Text) end)
            return { SetValue = function(_, v) box.Text = tostring(v) end }
        end
        function api:AddLabel(label)
            local r = row(label, 44)
            local labelObject = r:FindFirstChildWhichIsA("\x54extLabel")
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
            if typeof(savedColor) == "\x74able" then
                local red, green, blue = tonumber(savedColor[1]), tonumber(savedColor[2]), tonumber(savedColor[3])
                if red and green and blue then colour = Color3.new(math.clamp(red, 0, 1), math.clamp(green, 0, 1), math.clamp(blue, 0, 1)) end
            end
            local swatch = New("\x54extButton", { Parent = r, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 8), Size = UDim2.fromOffset(112, 34),
                BackgroundColor3 = colour, Text = "\x45DIT COLOR", TextColor3 = C.text, TextSize = 11, Font = Enum.Font.GothamBold, AutoButtonColor = false })
            corner(swatch, 10); stroke(swatch)
            local popup, inputChanged, inputEnded, colorDirty = nil, nil, nil, false
            local function storeColor()
                NoirPersistence.data.colors[colorKey] = { colour.R, colour.G, colour.B }
            end
            local function commitColor()
                if colorDirty then colorDirty = false; NoirPersistence.Save() end
            end
            local function setColor(value, mode)
                if typeof(value) ~= "\x43olor3" then return end
                colour = value
                swatch.BackgroundColor3 = colour
                if callback then callback(colour) end
                if mode == "\x64efer" then
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
                popup = New("\x46rame", { Parent = gui, Name = "\x4eoirColorPicker", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0),
                    BackgroundTransparency = .42, BorderSizePixel = 0, Active = true, ZIndex = 70 })
                local dialog = New("\x46rame", { Parent = popup, AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(640, 450),
                    BackgroundColor3 = C.panel, BorderSizePixel = 0, Active = true, ZIndex = 71 })
                corner(dialog, 18); stroke(dialog, C.border, .18)
                New("\x54extLabel", { Parent = dialog, Position = UDim2.fromOffset(22, 17), Size = UDim2.fromOffset(250, 27), BackgroundTransparency = 1,
                    Text = label, TextColor3 = C.text, TextSize = 20, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 72 })
                New("\x54extLabel", { Parent = dialog, Position = UDim2.fromOffset(22, 43), Size = UDim2.fromOffset(370, 17), BackgroundTransparency = 1,
                    Text = "\x43hoose with the color box, HEX, or RGB values", TextColor3 = C.dim, TextSize = 12, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 72 })
                local closeButton = New("\x54extButton", { Parent = dialog, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -17, 0, 15), Size = UDim2.fromOffset(38, 34),
                    BackgroundColor3 = C.surface, Text = "×", TextColor3 = C.text, TextSize = 24, Font = Enum.Font.GothamBold, AutoButtonColor = false, ZIndex = 73 })
                corner(closeButton, 10); stroke(closeButton, C.border, .45)
                local currentCard = New("\x46rame", { Parent = dialog, Position = UDim2.fromOffset(20, 80), Size = UDim2.fromOffset(220, 346), BackgroundColor3 = C.surface, BorderSizePixel = 0, ZIndex = 72 })
                corner(currentCard, 14); stroke(currentCard, C.border, .35)
                New("\x54extLabel", { Parent = currentCard, Position = UDim2.fromOffset(17, 16), Size = UDim2.fromOffset(170, 22), BackgroundTransparency = 1,
                    Text = "\x43URRENT COLOR", TextColor3 = C.text, TextSize = 14, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 73 })
                local preview = New("\x46rame", { Parent = currentCard, Position = UDim2.fromOffset(17, 49), Size = UDim2.fromOffset(186, 204), BackgroundColor3 = colour, BorderSizePixel = 0, ZIndex = 73 })
                corner(preview, 11); stroke(preview, C.border, .2)
                local previewHex = New("\x54extLabel", { Parent = preview, AnchorPoint = Vector2.new(.5, 1), Position = UDim2.new(.5, 0, 1, -14), Size = UDim2.fromOffset(118, 32),
                    BackgroundColor3 = Color3.fromRGB(24, 26, 30), BackgroundTransparency = .15, Text = "", TextColor3 = C.text, TextSize = 12, Font = Enum.Font.GothamBold, ZIndex = 74 })
                corner(previewHex, 8)
                New("\x54extLabel", { Parent = currentCard, Position = UDim2.fromOffset(17, 273), Size = UDim2.fromOffset(186, 18), BackgroundTransparency = 1,
                    Text = "\x4cIVE PREVIEW", TextColor3 = C.dim, TextSize = 11, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 73 })
                New("\x54extLabel", { Parent = currentCard, Position = UDim2.fromOffset(17, 298), Size = UDim2.fromOffset(186, 27), BackgroundTransparency = 1,
                    Text = "\x54he Shift Lock cursor updates instantly.", TextColor3 = C.dim, TextSize = 12, Font = Enum.Font.Gotham, TextWrapped = true, ZIndex = 73 })
                local valueCard = New("\x46rame", { Parent = dialog, Position = UDim2.fromOffset(258, 80), Size = UDim2.fromOffset(362, 346), BackgroundColor3 = C.surface, BorderSizePixel = 0, ZIndex = 72 })
                corner(valueCard, 14); stroke(valueCard, C.border, .35)
                New("\x54extLabel", { Parent = valueCard, Position = UDim2.fromOffset(17, 15), Size = UDim2.fromOffset(180, 22), BackgroundTransparency = 1,
                    Text = "\x43OLOR VALUE", TextColor3 = C.text, TextSize = 14, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 73 })
                local hueReadout = New("\x54extLabel", { Parent = valueCard, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -17, 0, 16), Size = UDim2.fromOffset(82, 20), BackgroundTransparency = 1,
                    Text = "\x48ue 0°", TextColor3 = C.dim, TextSize = 12, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 73 })
                local spectrum = New("\x46rame", { Parent = valueCard, Position = UDim2.fromOffset(17, 48), Size = UDim2.fromOffset(328, 160),
                    BackgroundColor3 = Color3.fromHSV(hue, 1, 1), BorderSizePixel = 0, Active = true, ZIndex = 73 })
                corner(spectrum, 10); stroke(spectrum, C.border, .25)
                local whiteBlend = New("\x46rame", { Parent = spectrum, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 74 })
                corner(whiteBlend, 10)
                New("\x55IGradient", { Parent = whiteBlend, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }) })
                local darkBlend = New("\x46rame", { Parent = spectrum, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 75 })
                corner(darkBlend, 10)
                New("\x55IGradient", { Parent = darkBlend, Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }) })
                local spectrumKnob = New("\x46rame", { Parent = spectrum, AnchorPoint = Vector2.new(.5, .5), Size = UDim2.fromOffset(17, 17), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 76 })
                corner(spectrumKnob, 9); New("\x55IStroke", { Parent = spectrumKnob, Color = C.text, Thickness = 2 })
                 
                local hueBar = New("\x46rame", { Parent = valueCard, Position = UDim2.fromOffset(17, 223), Size = UDim2.fromOffset(328, 16), BackgroundTransparency = 1, BorderSizePixel = 0, Active = true, ZIndex = 73 })
                local rainbowTrack = New("\x46rame", { Parent = hueBar, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 73 })
                corner(rainbowTrack, 8); stroke(rainbowTrack, C.border, .25)
                local rainbow = {
                    Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 72, 0), Color3.fromRGB(255, 150, 0), Color3.fromRGB(255, 225, 0),
                    Color3.fromRGB(170, 255, 0), Color3.fromRGB(65, 255, 0), Color3.fromRGB(0, 255, 90), Color3.fromRGB(0, 255, 180),
                    Color3.fromRGB(0, 235, 255), Color3.fromRGB(0, 155, 255), Color3.fromRGB(0, 65, 255), Color3.fromRGB(75, 0, 255),
                    Color3.fromRGB(150, 0, 255), Color3.fromRGB(220, 0, 255), Color3.fromRGB(255, 0, 190), Color3.fromRGB(255, 0, 105),
                    Color3.fromRGB(255, 0, 42), Color3.fromRGB(255, 0, 0),
                }
                for index, rainbowColor in ipairs(rainbow) do
                    New("\x46rame", { Parent = rainbowTrack, Position = UDim2.new((index - 1) / #rainbow, 0, 0, 0), Size = UDim2.new(1 / #rainbow, 0, 1, 0),
                        BackgroundColor3 = rainbowColor, BorderSizePixel = 0, ZIndex = 74 })
                end
                local hueKnob = New("\x46rame", { Parent = hueBar, AnchorPoint = Vector2.new(.5, .5), Size = UDim2.fromOffset(11, 24), BackgroundColor3 = C.text, BorderSizePixel = 0, ZIndex = 76 })
                corner(hueKnob, 5); New("\x55IStroke", { Parent = hueKnob, Color = Color3.new(0, 0, 0), Thickness = 1 })
                New("\x54extLabel", { Parent = valueCard, Position = UDim2.fromOffset(17, 252), Size = UDim2.fromOffset(44, 16), BackgroundTransparency = 1, Text = "\x48EX", TextColor3 = C.dim, TextSize = 11, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 73 })
                local hexInput = New("\x54extBox", { Parent = valueCard, Position = UDim2.fromOffset(64, 246), Size = UDim2.fromOffset(281, 30), BackgroundColor3 = C.card, Text = "", PlaceholderText = "\x23FFFFFF", TextColor3 = C.text, TextSize = 13, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center, ClearTextOnFocus = false, ZIndex = 73 })
                corner(hexInput, 8); stroke(hexInput, C.border, .4)
                New("\x54extLabel", { Parent = valueCard, Position = UDim2.fromOffset(17, 287), Size = UDim2.fromOffset(120, 15), BackgroundTransparency = 1, Text = "\x52GB", TextColor3 = C.dim, TextSize = 11, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 73 })
                local channelInputs = {}
                local channelLabels = { "\x52", "\x47", "\x42" }
                local channelColors = { Color3.fromRGB(239, 72, 72), Color3.fromRGB(82, 204, 112), Color3.fromRGB(84, 150, 255) }
                for index = 1, 3 do
                    local x = 17 + (index - 1) * 110
                    New("\x54extLabel", { Parent = valueCard, Position = UDim2.fromOffset(x, 309), Size = UDim2.fromOffset(18, 22), BackgroundTransparency = 1, Text = channelLabels[index], TextColor3 = channelColors[index], TextSize = 13, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 73 })
                    local field = New("\x54extBox", { Parent = valueCard, Position = UDim2.fromOffset(x + 22, 303), Size = UDim2.fromOffset(86, 32), BackgroundColor3 = C.card, Text = "\x30", PlaceholderText = "\x30", TextColor3 = C.text, TextSize = 14, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center, ClearTextOnFocus = false, ZIndex = 73 })
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
                    local hex = string.format("\x23%02X%02X%02X", math.floor(selected.R * 255 + .5), math.floor(selected.G * 255 + .5), math.floor(selected.B * 255 + .5))
                    previewHex.Text = hex .. "\x20 •  100%"
                    hexInput.Text = hex
                    channelInputs[1].Text = tostring(math.floor(selected.R * 255 + .5))
                    channelInputs[2].Text = tostring(math.floor(selected.G * 255 + .5))
                    channelInputs[3].Text = tostring(math.floor(selected.B * 255 + .5))
                    hueReadout.Text = "\x48ue " .. tostring(math.floor(hue * 360 + .5)) .. "°"
                    setColor(selected, mode)
                end
                local function setRGB(red, green, blue, mode)
                    local selected = Color3.fromRGB(math.clamp(math.floor((tonumber(red) or 0) + .5), 0, 255), math.clamp(math.floor((tonumber(green) or 0) + .5), 0, 255), math.clamp(math.floor((tonumber(blue) or 0) + .5), 0, 255))
                    local nextHue, nextSaturation, nextValue = selected:ToHSV()
                    setHSV(nextHue, nextSaturation, nextValue, mode)
                end
                local function updateSpectrum(position)
                    local size, origin = spectrum.AbsoluteSize, spectrum.AbsolutePosition
                    setHSV(hue, math.clamp((position.X - origin.X) / math.max(1, size.X), 0, 1), 1 - math.clamp((position.Y - origin.Y) / math.max(1, size.Y), 0, 1), "\x64efer")
                end
                local function updateHue(position)
                    local size, origin = hueBar.AbsoluteSize, hueBar.AbsolutePosition
                    setHSV(math.clamp((position.X - origin.X) / math.max(1, size.X), 0, 1), saturation, value, "\x64efer")
                end
                local dragMode = nil
                spectrum.InputBegan:Connect(function(input) if isPrimaryPress(input) then dragMode = "\x73pectrum"; updateSpectrum(input.Position) end end)
                hueBar.InputBegan:Connect(function(input) if isPrimaryPress(input) then dragMode = "\x68ue"; updateHue(input.Position) end end)
                hexInput.FocusLost:Connect(function()
                    local raw = tostring(hexInput.Text or ""):gsub("\x25s", ""):gsub("\x23", "")
                    local redHex, greenHex, blueHex = raw:match("\x5e(%x%x)(%x%x)(%x%x)$")
                    if redHex and greenHex and blueHex then setRGB(tonumber(redHex, 16), tonumber(greenHex, 16), tonumber(blueHex, 16), true) else setHSV(hue, saturation, value, false) end
                end)
                for _, field in ipairs(channelInputs) do
                    field.FocusLost:Connect(function()
                        setRGB(tonumber(channelInputs[1].Text) or math.floor(colour.R * 255 + .5), tonumber(channelInputs[2].Text) or math.floor(colour.G * 255 + .5), tonumber(channelInputs[3].Text) or math.floor(colour.B * 255 + .5), true)
                    end)
                end
                inputChanged = UIS.InputChanged:Connect(function(input)
                    if dragMode and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
                        if dragMode == "\x73pectrum" then updateSpectrum(input.Position) else updateHue(input.Position) end
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
            local btn = New("\x54extButton", { Parent = r, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 8), Size = UDim2.fromOffset(130, 34),
                BackgroundColor3 = C.surface, Text = tostring(savedKey), TextColor3 = C.text, TextSize = 14, Font = Enum.Font.Gotham, AutoButtonColor = false })
            corner(btn, 10); stroke(btn)
            local listening, currentKey, conn = false, savedKey, nil
            btn.MouseButton1Click:Connect(function()
                listening = true; btn.Text = "\x50ress a key..."
                if conn then conn:Disconnect() end
                conn = UIS.InputBegan:Connect(function(input)
                    if not listening then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        currentKey = input.KeyCode.Name; btn.Text = currentKey; listening = false
                        NoirPersistence.data.keybinds[storagePrefix .. label] = currentKey; NoirPersistence.Save()
                        callback(currentKey); conn:Disconnect()
                    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                        currentKey = "\x4douseButton1"; btn.Text = currentKey; listening = false
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
    targetMode = "\x4durderer",
    hitPart = "\x48umanoidRootPart",
    fovSize = 0,
    showFov = false,
    aimKey = "\x4eone",
    toggleKey = "\x4eone",
    autoFire = false,
    autoFireKey = "\x4eone",
    shotMethod = "\x52emote",
    wallCheck = false,
    piercerBullet = false,
    ignoreDead = true,
    ignoreFriends = false,
    maxDistance = 0,
    adaptive = true,
    fixedLead = 0.075,
    extraLead = 0.02,
    targetPart = "\x48umanoidRootPart",
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
     
    knifeDualEffect = false,
    knifeInstantThrow = false,
    knifeFastThrow = false,
    knifeAutoKillEveryone = false,
    knifeAutoKillSheriff = false,
    knifeKillPlayer = "\x4e/A",
    knifeSheriffBind = false,
    knifeSheriffBindShape = "\x43ircle",
     
    knifeThrownAura = true,
    knifeRadius = 15,
    showShootButton = false,
    lockShootButton = false,
     
    gunDualEffect = false,
    gunTriggerBot = false,
    gunTriggerBotWallCheck = true,
    gunTriggerBotPrediction = true,
    selectedPlayer = nil,
}

 
NoirPersistence.data.toggles["\x53ILENT AIM::Use Gun Dual Effect"] = false
NoirPersistence.data.toggles["\x4bNIFE SILENT AIM::Use Knife Dual Effect"] = false
 
do
    local oldProjectedDual = getgenv().__NoirCameraProjectedDual
    if type(oldProjectedDual) == "\x74able" and type(oldProjectedDual.Stop) == "\x66unction" then pcall(oldProjectedDual.Stop, oldProjectedDual) end
    getgenv().__NoirCameraProjectedDual = nil
end
NoirPersistence.Save()

local murderer, sheriff, hero
local cachedPing = 0.05
local redirected = 0
local hooked = false
local running = true
local shootButton, shootGui, shootBusy = nil, nil, false
local buttonShotActive, buttonShotTarget = false, nil
local presetName = "\x64efault"
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
local roundState = "\x77aiting"
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
Players.PlayerRemoving:Connect(function(player)
    refreshPlayerCache()
    playerData[player.UserId], roleCache[player.UserId], announcedRoles[player.UserId] = nil, nil, nil
    local changed = murderer == player or sheriff == player or hero == player
    if murderer == player then murderer = nil end
    if sheriff == player then sheriff = nil end
    if hero == player then hero = nil end
    if changed then
        local bus = getgenv().__NoirV4RoleBus
        if bus and bus.Emit then bus:Emit() end
    end
end)

function notify(msg, time)
    if type(host.Notify) == "\x66unction" then pcall(host.Notify, "\x4dM2 Silent Aim: " .. tostring(msg), time or 3) end
end
function validTarget(player)
    local character = player and player.Character
    local humanoid = character and character:FindFirstChildWhichIsA("\x48umanoid")
    return player ~= nil and player ~= LocalPlayer and character ~= nil and humanoid ~= nil and humanoid.Health > 0
end
function localCharacter() return LocalPlayer.Character end
local localHumCache, localHumChar
function localHumanoid()
    local c = LocalPlayer.Character
     
    if c ~= localHumChar or not localHumCache or not localHumCache.Parent then
        localHumChar = c
        localHumCache = c and c:FindFirstChildWhichIsA("\x48umanoid") or nil
    end
    return localHumCache
end
local localRootCache, localRootChar
function localRoot()
    local c = LocalPlayer.Character
     
    if c ~= localRootChar or not localRootCache or not localRootCache.Parent then
        localRootChar = c
        localRootCache = c and (c:FindFirstChild("\x48umanoidRootPart") or c:FindFirstChild("\x55pperTorso") or c:FindFirstChild("\x54orso")) or nil
    end
    return localRootCache
end
function playerHasTool(player, toolName)
    local character = player and player.Character
    local backpack = player and player:FindFirstChildOfClass("\x42ackpack")
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
    local t = player and player.Character and player.Character:FindFirstChild("\x48umanoidRootPart")
    if root and t then return (t.Position - root.Position).Magnitude end
    return math.huge
end

local function playerIsInLobby(player)
    if not player then return true end
    local teamName = player.Team and string.lower(tostring(player.Team.Name)) or ""
    if string.find(teamName, "\x6cobby", 1, true)
        or string.find(teamName, "\x73pectat", 1, true)
        or string.find(teamName, "\x6fbserver", 1, true)
        or string.find(teamName, "\x77aiting", 1, true) then
        return true
    end

    local containers = { player, player.Character }
    for _, container in ipairs(containers) do
        if container then
            for key, value in pairs(container:GetAttributes()) do
                local k = string.lower(tostring(key))
                if (string.find(k, "\x69nround", 1, true) or string.find(k, "\x69ngame", 1, true)
                    or string.find(k, "\x69splaying", 1, true) or string.find(k, "\x61live", 1, true))
                    and value == false then
                    return true
                end
                if string.find(k, "\x73tate", 1, true) or string.find(k, "\x73tatus", 1, true)
                    or string.find(k, "\x6cocation", 1, true) or string.find(k, "\x70lace", 1, true) then
                    local textValue = string.lower(tostring(value))
                    if string.find(textValue, "\x6cobby", 1, true)
                        or string.find(textValue, "\x73pectat", 1, true)
                        or string.find(textValue, "\x64ead", 1, true)
                        or string.find(textValue, "\x77aiting", 1, true) then
                        return true
                    end
                end
            end
            for _, name in ipairs({ "\x49nLobby", "\x53pectating", "\x44ead", "\x49sDead" }) do
                local flag = container:FindFirstChild(name)
                if flag and flag:IsA("\x42oolValue") and flag.Value then return true end
            end
            for _, name in ipairs({ "\x49nRound", "\x49nGame", "\x49sPlaying", "\x41live", "\x49sAlive" }) do
                local flag = container:FindFirstChild(name)
                if flag and flag:IsA("\x42oolValue") and not flag.Value then return true end
            end
        end
    end
    return false
end
function setTarget(player)
    if not validTarget(player) then player = nil end
    if murderer ~= player then
        murderer = player
        if player then notify("\x54arget: " .. player.Name, 2) end
    end
end
function findByKnife()
    for _, player in ipairs(getPlayers()) do
        if player ~= LocalPlayer and playerHasTool(player, "\x4bnife") then return player end
    end
end
function findByGun()
    for _, player in ipairs(getPlayers()) do
        if player ~= LocalPlayer and playerHasTool(player, "\x47un") then return player end
    end
end
 
do
    local roleBus = { revision = 0, listeners = {} }
    function roleBus:Subscribe(callback)
        if type(callback) ~= "\x66unction" then return function() end end
        self.listeners[#self.listeners + 1] = callback
        local index = #self.listeners
        return function() self.listeners[index] = false end
    end
    function roleBus:Emit()
        self.revision += 1
        for _, callback in ipairs(self.listeners) do if type(callback) == "\x66unction" then pcall(callback, self.revision) end end
    end
    getgenv().__NoirV4RoleBus = roleBus
end

do
    local page = win:FindFirstChild("\x4dapContent")
    local col = page and page:FindFirstChild("\x4eoirColumn1")
    local farmPage = win:FindFirstChild("\x46armContent")
    local farmCol = farmPage and farmPage:FindFirstChild("\x4eoirColumn1")
    if page and col then
        local function panel(title, subtitle, pageName, parentCol)
            parentCol = parentCol or col
            pageName = pageName or "\x6dap"
            local card = New("\x46rame", { Parent = parentCol, Size = UDim2.new(1, 0, 0, 90), AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = C.panel, BackgroundTransparency = .25, ClipsDescendants = true })
            table.insert(sectionPanels, { panel = card, page = pageName, name = string.lower(title .. "\x20" .. (subtitle or "") .. "\x20teleport map lobby murder sheriff player farm tween") })
            corner(card, 18); stroke(card, C.border, .5)
            local tick = New("\x46rame", { Parent = card, Position = UDim2.fromOffset(0, 16), Size = UDim2.fromOffset(3, 20), BackgroundColor3 = C.accent })
            corner(tick, 2)
            text(card, title, 18, UDim2.fromOffset(24, 16))
            if subtitle and subtitle ~= "" then text(card, subtitle, 12, UDim2.fromOffset(24, 44), true) end
            local holder = New("\x46rame", { Parent = card, Position = UDim2.fromOffset(20, subtitle ~= "" and 74 or 57), Size = UDim2.new(1, -40, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 })
            New("\x55IListLayout", { Parent = holder, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
            New("\x55IPadding", { Parent = holder, PaddingBottom = UDim.new(0, 12) })
            return holder
        end
        local function makeBtn(parent, label, callback)
            local b = New("\x54extButton", { Parent = parent, Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = C.btn,
                Text = label, TextColor3 = C.text, TextSize = 15, Font = Enum.Font.Gotham, AutoButtonColor = false })
            corner(b, 12); stroke(b, C.border, .5)
            b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(.18), { BackgroundColor3 = Color3.fromRGB(48, 52, 56) }):Play() end)
            b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(.18), { BackgroundColor3 = C.btn }):Play() end)
            local last = 0
            local function fire()
                local now = os.clock()
                if now - last < .2 then return end
                last = now
                callback()
            end
            b.MouseButton1Click:Connect(fire)
            b.Activated:Connect(fire)
            return b
        end
        local function firstPart(inst)
            if not inst then return nil end
            if inst:IsA("\x42asePart") then return inst end
            if inst:IsA("\x4dodel") then
                return inst.PrimaryPart or inst:FindFirstChildWhichIsA("\x42asePart", true)
            end
            return inst:FindFirstChildWhichIsA("\x42asePart", true)
        end
        local function safeCFrame(cf)
            if typeof(cf) ~= "\x43Frame" then return nil end
            local dest = workspace.FallenPartsDestroyHeight
            if typeof(dest) == "\x6eumber" and cf.Position.Y < dest + 40 then return nil end
            return cf
        end
        local function tpToCF(cf)
            cf = safeCFrame(cf)
            if not cf then notify("Небезопасная\x20точка телепорта", 2); return false end
            local char = LocalPlayer.Character
            local root = localRoot()
            if not char or not root then notify("Нет\x20персонажа", 2); return false end
            pcall(function()
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
            end)
            if not pcall(function() char:PivotTo(cf) end) then
                root.CFrame = cf
            end
            pcall(function()
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
            end)
            return true
        end
        local function pickFrom(model)
            if not model then return nil end
            local named = model:FindFirstChild("\x53pawns") or model:FindFirstChild("\x53pawn") or model:FindFirstChild("\x53pawnLocation") or model:FindFirstChild("\x50layerSpawns")
            if named then
                if named:IsA("\x42asePart") then return named.CFrame + Vector3.new(0, 4, 0) end
                local parts = {}
                for _, child in ipairs(named:GetChildren()) do
                    local p = firstPart(child)
                    if p then parts[#parts + 1] = p end
                end
                if #parts > 0 then return parts[math.random(1, #parts)].CFrame + Vector3.new(0, 4, 0) end
                local p = firstPart(named)
                if p then return p.CFrame + Vector3.new(0, 4, 0) end
            end
            local sl = model:FindFirstChildWhichIsA("\x53pawnLocation", true)
            if sl then return sl.CFrame + Vector3.new(0, 4, 0) end
            local ok, boxCF, size = pcall(function() return model:GetBoundingBox() end)
            if ok and typeof(boxCF) == "\x43Frame" then
                local lift = 8
                if typeof(size) == "\x56ector3" then lift = math.max(8, size.Y * 0.15) end
                return boxCF + Vector3.new(0, lift, 0)
            end
            local p = firstPart(model)
            if p then return p.CFrame + Vector3.new(0, 6, 0) end
            return nil
        end
        local function findMapModel()
            for _, child in ipairs(workspace:GetChildren()) do
                if child:FindFirstChild("\x43oinContainer") then return child end
            end
            local named = workspace:FindFirstChild("\x4dap")
            if named then return named end
            return nil
        end
        local function mapCFrame(map)
            if not map then return nil end
            local coins = map:FindFirstChild("\x43oinContainer")
            if coins then
                local coin = coins:FindFirstChild("\x43oin_Server") or coins:FindFirstChild("\x43oinVisual") or coins:FindFirstChildWhichIsA("\x42asePart", true)
                if coin then
                    if coin:IsA("\x42asePart") then return coin.CFrame + Vector3.new(0, 5, 0) end
                    local p = firstPart(coin)
                    if p then return p.CFrame + Vector3.new(0, 5, 0) end
                end
                for _, child in ipairs(coins:GetChildren()) do
                    local p = firstPart(child)
                    if p then return p.CFrame + Vector3.new(0, 5, 0) end
                end
            end
            return pickFrom(map)
        end
                local function lobbyCFrame()
            local map = findMapModel()
            local function fromSpawns(folder)
                if not folder then return nil end
                local parts = {}
                for _, child in ipairs(folder:GetChildren()) do
                    local p = firstPart(child)
                    if p then parts[#parts + 1] = p end
                end
                if #parts == 0 then
                    local p = firstPart(folder)
                    if p then parts[1] = p end
                end
                if #parts > 0 then return parts[math.random(1, #parts)].CFrame + Vector3.new(0, 3, 0) end
            end
            local function fromInst(inst)
                if not inst then return nil end
                if map and (inst == map or inst:IsDescendantOf(map)) then return nil end
                local cf = fromSpawns(inst:FindFirstChild("\x53pawns") or inst:FindFirstChild("\x53pawn") or inst:FindFirstChild("\x53pawnLocation") or inst:FindFirstChild("\x50layerSpawns"))
                if cf then return cf end
                local sl = inst:FindFirstChildWhichIsA("\x53pawnLocation", true)
                if sl then return sl.CFrame + Vector3.new(0, 4, 0) end
                if inst:IsA("\x53pawnLocation") or inst:IsA("\x42asePart") then
                    return inst.CFrame + Vector3.new(0, 4, 0)
                end
                if inst:IsA("\x4dodel") then
                    local ok, pivot = pcall(function() return inst:GetPivot() end)
                    if ok and typeof(pivot) == "\x43Frame" then return pivot * CFrame.new(0, 6, 0) end
                end
            end
            local function isLobbyName(n)
                n = string.lower(tostring(n or ""))
                return n == "\x6cobby" or string.find(n, "\x6cobby", 1, true) ~= nil
                    or n == "\x77aiting" or n == "\x77aitingroom" or n == "\x76ote" or n == "\x76oting" or n == "\x76otingroom"
            end
            for _, child in ipairs(workspace:GetChildren()) do
                if isLobbyName(child.Name) then
                    local cf = fromInst(child)
                    if cf then return cf end
                end
            end
            local okDesc, descendants = pcall(function() return workspace:GetDescendants() end)
            if okDesc and descendants then
                for i = 1, #descendants do
                    local inst = descendants[i]
                    local n = inst.Name
                    if (n == "\x53pawns" or n == "\x53pawn" or n == "\x50layerSpawns") and inst.Parent and isLobbyName(inst.Parent.Name) then
                        local cf = fromSpawns(inst)
                        if cf then return cf end
                    elseif isLobbyName(n) and (inst:IsA("\x4dodel") or inst:IsA("\x46older")) then
                        local cf = fromInst(inst)
                        if cf then return cf end
                    end
                end
                for i = 1, #descendants do
                    local inst = descendants[i]
                    if inst:IsA("\x53pawnLocation") and not (map and inst:IsDescendantOf(map)) then
                        return inst.CFrame + Vector3.new(0, 4, 0)
                    end
                end
                for i = 1, #descendants do
                    local inst = descendants[i]
                    if (inst.Name == "\x53pawns" or inst.Name == "\x53pawn") and not (map and inst:IsDescendantOf(map)) then
                        local cf = fromSpawns(inst)
                        if cf then return cf end
                    end
                end
            end
            return nil
        end
        local function tpToPlayer(player)
            if not player or player == LocalPlayer then notify("Некого\x20телепортировать", 2); return end
            local char = player.Character
            local hrp = char and (char:FindFirstChild("\x48umanoidRootPart") or char:FindFirstChild("\x55pperTorso") or char:FindFirstChild("\x54orso"))
            if not hrp then notify(player.Name .. "\x20без персонажа", 2); return end
            if tpToCF(hrp.CFrame * CFrame.new(0, 2, 3.5)) then
                notify("\x54P → " .. player.Name, 2)
            end
        end
        local function currentMurder()
            if validTarget(murderer) then return murderer end
            local byKnife = findByKnife()
            if validTarget(byKnife) then return byKnife end
            for _, player in ipairs(getPlayers()) do
                if roleCache[player.UserId] == "\x6durderer" and validTarget(player) then return player end
            end
        end
        local function currentSheriff()
            if validTarget(sheriff) then return sheriff end
            if validTarget(hero) then return hero end
            local byGun = findByGun()
            if validTarget(byGun) then return byGun end
            for _, player in ipairs(getPlayers()) do
                local role = roleCache[player.UserId]
                if (role == "\x73heriff" or role == "\x68ero") and validTarget(player) then return player end
            end
        end

        local tpHolder = panel("\x54eleport", "Карта\x20· лобби · роли")
        makeBtn(tpHolder, "\x54eleport to Map", function()
            local map = findMapModel()
            if not map then notify("Карта\x20не найдена (раунд не начался)", 3); return end
            local cf = mapCFrame(map)
            if cf and tpToCF(cf) then notify("Телепорт\x20на карту", 2) else notify("Нет\x20точки спавна на карте", 3) end
        end)
        makeBtn(tpHolder, "\x54eleport to Lobby", function()
            local cf = lobbyCFrame()
            if not cf then notify("Лобби\x20не найдено", 3); return end
            if tpToCF(cf) then notify("Телепорт\x20в лобби", 2) end
        end)
        makeBtn(tpHolder, "\x54eleport to Murder", function()
            local target = currentMurder()
            if not target then notify("\x4durder не найден", 3); return end
            tpToPlayer(target)
        end)
        makeBtn(tpHolder, "\x54eleport to Sheriff", function()
            local target = currentSheriff()
            if not target then notify("\x53heriff не найден", 3); return end
            tpToPlayer(target)
        end)

        local listHolder = panel("\x50layers", "Как\x20в Fling → Lists")
        local roleLabel = New("\x54extLabel", { Parent = listHolder, Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1,
            Text = "\x4durder: —  ·  Sheriff: —", TextColor3 = C.dim, TextSize = 13, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left })
        local function refreshRoles()
            local m, s = currentMurder(), currentSheriff()
            roleLabel.Text = "\x4durder: " .. (m and m.Name or "—") .. "\x20 ·  Sheriff: " .. (s and s.Name or "—")
        end
        local ddRow = New("\x46rame", { Parent = listHolder, Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 1 })
        text(ddRow, "▸\x20Player", 16, UDim2.fromOffset(0, 10))
        local ddBtn = New("\x54extButton", { Parent = ddRow, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 4), Size = UDim2.fromOffset(190, 42),
            BackgroundColor3 = C.surface, Text = "\x4eone  ⌄", TextColor3 = C.text, TextSize = 14, Font = Enum.Font.Gotham, AutoButtonColor = false, ZIndex = 5 })
        corner(ddBtn, 10); stroke(ddBtn)
        local popup
        local function closePopup() if popup then popup:Destroy(); popup = nil end end
        local function playerNames()
            local names = { "\x4eone" }
            for _, player in ipairs(getPlayers()) do
                if player ~= LocalPlayer then names[#names + 1] = player.Name end
            end
            table.sort(names, function(a, b)
                if a == "\x4eone" then return true end
                if b == "\x4eone" then return false end
                return string.lower(a) < string.lower(b)
            end)
            return names
        end
        local function openPopup()
            closePopup()
            refreshRoles()
            local names = playerNames()
            local scaleVal = (scale and scale.Scale) or 1
            popup = New("\x53crollingFrame", { Parent = gui, Position = UDim2.fromOffset(ddBtn.AbsolutePosition.X / scaleVal, (ddBtn.AbsolutePosition.Y + ddBtn.AbsoluteSize.Y + 4) / scaleVal),
                Size = UDim2.fromOffset(ddBtn.AbsoluteSize.X / scaleVal, math.min(#names * 38, 190)), CanvasSize = UDim2.fromOffset(0, #names * 38),
                BackgroundColor3 = C.surface, BorderSizePixel = 0, ScrollBarThickness = 4, ZIndex = 50 })
            corner(popup, 10); stroke(popup, C.accent, .2)
            New("\x55IListLayout", { Parent = popup, SortOrder = Enum.SortOrder.LayoutOrder })
            for _, name in ipairs(names) do
                local item = New("\x54extButton", { Parent = popup, Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, Text = tostring(name),
                    TextColor3 = C.text, TextSize = 14, Font = Enum.Font.Gotham, ZIndex = 51, AutoButtonColor = false })
                local function pick()
                    ddBtn.Text = tostring(name) .. "\x20 ⌄"
                    closePopup()
                    if name == "\x4eone" then return end
                    local player = Players:FindFirstChild(name)
                    if player then tpToPlayer(player) end
                end
                item.MouseButton1Click:Connect(pick)
                item.Activated:Connect(pick)
            end
        end
        ddBtn.MouseButton1Click:Connect(openPopup)
        ddBtn.Activated:Connect(openPopup)
        local bus = getgenv().__NoirV4RoleBus
        if bus and bus.Subscribe then bus:Subscribe(function() task.defer(refreshRoles) end) end
        refreshRoles()
    end
end

do
    local function buildAutofarmUI()
        local page = win:FindFirstChild("\x46armContent")
        local col = page and page:FindFirstChild("\x4eoirColumn1")
        if page and col then
            local function panel(title, subtitle)
                local card = New("\x46rame", { Parent = col, Size = UDim2.new(1, 0, 0, 90), AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundColor3 = C.panel, BackgroundTransparency = .25, ClipsDescendants = true })
                table.insert(sectionPanels, { panel = card, page = "\x66arm", name = string.lower(title .. "\x20" .. (subtitle or "") .. "\x20autofarm farm coins coin") })
                corner(card, 18); stroke(card, C.border, .5)
                local tick = New("\x46rame", { Parent = card, Position = UDim2.fromOffset(0, 16), Size = UDim2.fromOffset(3, 20), BackgroundColor3 = C.accent })
                corner(tick, 2)
                text(card, title, 18, UDim2.fromOffset(24, 16))
                if subtitle and subtitle ~= "" then text(card, subtitle, 12, UDim2.fromOffset(24, 44), true) end
                local holder = New("\x46rame", { Parent = card, Position = UDim2.fromOffset(20, subtitle ~= "" and 74 or 57), Size = UDim2.new(1, -40, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 })
                New("\x55IListLayout", { Parent = holder, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
                New("\x55IPadding", { Parent = holder, PaddingBottom = UDim.new(0, 12) })
                return holder
            end
            local function makeToggle(parent, label, callback, startOn)
                local state = false
                local r = New("\x46rame", { Parent = parent, Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1 })
                text(r, label, 16, UDim2.fromOffset(0, 10))
                local pill = New("\x54extButton", { Parent = r, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 8), Size = UDim2.fromOffset(64, 34),
                    BackgroundColor3 = C.off, Text = "", AutoButtonColor = false })
                corner(pill, 17); stroke(pill, C.border, .55)
                local dot = New("\x46rame", { Parent = pill, Position = UDim2.fromOffset(4, 4), Size = UDim2.fromOffset(26, 26), BackgroundColor3 = Color3.fromRGB(150, 155, 162) })
                corner(dot, 13)
                local function apply(v)
                    state = v == true
                    TweenService:Create(pill, TweenInfo.new(.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { BackgroundColor3 = state and C.accent or C.off }):Play()
                    TweenService:Create(dot, TweenInfo.new(.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                        Position = state and UDim2.fromOffset(34, 4) or UDim2.fromOffset(4, 4),
                        BackgroundColor3 = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 155, 162)
                    }):Play()
                    callback(state)
                end
                local last = 0
                local function fire()
                    local now = os.clock()
                    if now - last < .18 then return end
                    last = now
                    apply(not state)
                end
                pill.MouseButton1Click:Connect(fire)
                pill.Activated:Connect(fire)
                if startOn == true then apply(true) end
            end
            local farming, gunFarm, auraOn, resetFull, killAllOn, shootMurdOn, noRenderOn = false, false, false, false, false, false, false
            local bagIsFull, auraRadius = false, 8
            local noclipConn, auraConn, statusLbl
            local fopt = { method = "\x53tandard", spd = 30, dly = 10, avoid = false, rstM = false, rstS = false, ret = "\x4dap" }
            local lastMapCF, lastCoin, holdReturnUntil, farmTw = nil, nil, 0, nil
            local function farmKey(k) return "\x41utofarm::" .. k end
            local function farmRead(bag, key, def)
                local store = NoirPersistence.data[bag]
                if type(store) ~= "\x74able" then return def end
                local v = store[farmKey(key)]
                if v == nil then return def end
                return v
            end
            local function farmWrite(bag, key, val)
                NoirPersistence.data[bag][farmKey(key)] = val
                NoirPersistence.Save()
            end
            fopt.spd = math.clamp(tonumber(farmRead("\x73liders", "\x54ween Speed (%)", 30)) or 30, 1, 100)
            fopt.dly = math.clamp(tonumber(farmRead("\x73liders", "\x54ween Delay (%)", 10)) or 10, 0, 100)
            fopt.method = farmRead("\x64ropdowns", "\x4dethod", "\x53tandard")
            if fopt.method ~= "\x4cay" then fopt.method = "\x53tandard" end
            fopt.ret = farmRead("\x64ropdowns", "\x52eturn To", "\x4dap")
            if fopt.ret ~= "\x41bove Map" and fopt.ret ~= "\x4cobby" then fopt.ret = "\x4dap" end
            fopt.avoid = farmRead("\x74oggles", "\x46arm Avoid Murderer", false) == true
            fopt.rstM = farmRead("\x74oggles", "\x41uto Reset As Murderer", false) == true
            fopt.rstS = farmRead("\x74oggles", "\x41uto Reset As Sheriff", false) == true
            auraRadius = tonumber(farmRead("\x73liders", "\x41ura radius", 8)) or 8
            local origDestroyH = workspace.FallenPartsDestroyHeight
            local function setStatus(msg)
                if statusLbl then statusLbl.Text = msg end
            end
            local function touch(a, b)
                pcall(function()
                    firetouchinterest(a, b, 0)
                    firetouchinterest(a, b, 1)
                end)
            end
            local function getContainer()
                for _, child in ipairs(workspace:GetChildren()) do
                    if child:IsA("\x4dodel") then
                        local inner = child:FindFirstChild("\x43oinContainer")
                        if inner then return inner, child end
                    end
                end
                local box = workspace:FindFirstChild("\x43oinContainer")
                if box then return box, box.Parent end
                return nil, nil
            end
            local function getCoinParts()
                local parts, box = {}, getContainer()
                if not box then return parts end
                for _, child in ipairs(box:GetChildren()) do
                    if child.Name == "\x43oin_Server" or child.Name == "\x43oinVisual" or child.Name == "\x43oin" or child.Name == "\x43andy" or child:FindFirstChild("\x54ouchInterest") then
                        if child:IsA("\x42asePart") then
                            parts[#parts + 1] = child
                        else
                            local p = child:FindFirstChildWhichIsA("\x42asePart", true)
                            if p then parts[#parts + 1] = p end
                        end
                    end
                end
                if #parts == 0 then
                    local ok, descs = pcall(function() return box:GetDescendants() end)
                    if ok and descs then
                        for n = 1, #descs do
                            local d = descs[n]
                            if d:IsA("\x42asePart") and d:FindFirstChild("\x54ouchInterest") then
                                parts[#parts + 1] = d
                            end
                        end
                    end
                end
                return parts
            end
            local function poseAt(part)
                local pos = part.Position
                if fopt.method == "\x4cay" then
                     
                    return CFrame.new(pos.X, pos.Y - 2, pos.Z) * CFrame.Angles(math.pi / 2, 0, 0)
                end
                 
                return CFrame.new(pos.X, pos.Y + 2.4, pos.Z)
            end
            local function freezeRoot(r, on)
                if not r then return end
                pcall(function()
                    r.Anchored = on and true or false
                    r.AssemblyLinearVelocity = Vector3.zero
                    r.AssemblyAngularVelocity = Vector3.zero
                end)
            end
            local function returnCFrame()
                if fopt.ret == "\x4cobby" then
                    local cf = lobbyCFrame and lobbyCFrame()
                    if cf then return cf end
                    for _, name in ipairs({ "\x4cobby", "\x4cobbyMap", "\x56oting", "\x57aiting" }) do
                        local inst = workspace:FindFirstChild(name)
                        local p = inst and inst:FindFirstChildWhichIsA("\x42asePart", true)
                        if p then return p.CFrame + Vector3.new(0, 4, 0) end
                    end
                    return lastMapCF
                end
                local map = findMapModel and findMapModel()
                local cf = (mapCFrame and mapCFrame(map)) or lastMapCF
                if not cf then return nil end
                if fopt.ret == "\x41bove Map" then
                    return cf + Vector3.new(0, 40, 0)
                end
                return cf
            end
            local function tweenTo(cf)
                local r = localRoot()
                if not r or not cf then return end
                if farmTw then pcall(function() farmTw:Cancel() end); farmTw = nil end
                local dist = (r.Position - cf.Position).Magnitude
                if dist <= 2.5 then
                    freezeRoot(r, true)
                    r.CFrame = cf
                    freezeRoot(r, false)
                    return
                end
                freezeRoot(r, true)
                local spd = 8 + fopt.spd * 0.55
                local dur = math.clamp(dist / math.max(spd, 10), 0.08, 1.35)
                farmTw = TweenService:Create(r, TweenInfo.new(dur, Enum.EasingStyle.Linear), { CFrame = cf })
                farmTw:Play()
                local t0 = os.clock()
                while farming and os.clock() - t0 < dur + 0.02 do
                    if not farmTw or farmTw.PlaybackState ~= Enum.PlaybackState.Playing then break end
                    task.wait()
                end
                if farmTw then pcall(function() farmTw:Cancel() end); farmTw = nil end
                if r.Parent then r.CFrame = cf end
                freezeRoot(r, false)
            end
            local function setNoclip(on)
                if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
                local char = LocalPlayer.Character
                if not on then
                    if char then
                        for _, p in ipairs(char:GetChildren()) do
                            if p:IsA("\x42asePart") then p.CanCollide = true end
                        end
                    end
                    return
                end
                noclipConn = RunService.Stepped:Connect(function()
                    if not farming then return end
                    local c = LocalPlayer.Character
                    if not c then return end
                    for _, p in ipairs(c:GetChildren()) do
                        if p:IsA("\x42asePart") then p.CanCollide = false end
                    end
                end)
            end
            local function magnetCoins()
                local char = LocalPlayer.Character
                local root = localRoot()
                if not char or not root then return 0 end
                freezeRoot(root, false)
                local parts = getCoinParts()
                for n = 1, #parts do
                    local part = parts[n]
                    if part and part.Parent then
                        touch(root, part)
                        for _, bp in ipairs(char:GetChildren()) do
                            if bp:IsA("\x42asePart") then touch(bp, part) end
                        end
                    end
                end
                return #parts
            end
            local function collectAura()
                local root = localRoot()
                if not root then return end
                local pos = root.Position
                local parts = getCoinParts()
                for n = 1, #parts do
                    local part = parts[n]
                    if part and part.Parent and (pos - part.Position).Magnitude <= auraRadius then
                        touch(root, part)
                    end
                end
            end
            local function hasTool(name)
                local char, bp = LocalPlayer.Character, LocalPlayer:FindFirstChild("\x42ackpack")
                return (char and char:FindFirstChild(name)) or (bp and bp:FindFirstChild(name))
            end
            local function doKillAll()
                local char = LocalPlayer.Character
                local knife = char and char:FindFirstChild("\x4bnife") or (LocalPlayer:FindFirstChild("\x42ackpack") and LocalPlayer.Backpack:FindFirstChild("\x4bnife"))
                local ht = knife and knife:FindFirstChild("\x45vents") and knife.Events:FindFirstChild("\x48andleTouched")
                if not ht then return end
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character then
                        local tgt = plr.Character:FindFirstChild("\x55pperTorso") or plr.Character:FindFirstChild("\x48umanoidRootPart")
                        if tgt then pcall(function() ht:FireServer(tgt) end) end
                    end
                end
            end
            local function doShootMurd()
                task.spawn(function()
                    local gun = hasTool("\x47un")
                    local murd = findByKnife and findByKnife()
                    if not gun or not murd then return end
                    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("\x48umanoid")
                    if hum and gun.Parent ~= LocalPlayer.Character then pcall(function() hum:EquipTool(gun) end) end
                    task.wait(0.2)
                    pcall(function()
                        local vu = game:GetService("\x56irtualUser")
                        local cam = workspace.CurrentCamera
                        local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
                        vu:Button1Down(center, cam.CFrame)
                        task.wait(0.1)
                        vu:Button1Up(center, cam.CFrame)
                    end)
                end)
            end
            local function maybeRoleReset()
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("\x48umanoid")
                if not hum then return end
                if fopt.rstM and hasTool("\x4bnife") then hum.Health = 0 end
                if fopt.rstS and hasTool("\x47un") then hum.Health = 0 end
            end
            local function murdTooClose()
                if not fopt.avoid then return false end
                local murd = findByKnife and findByKnife()
                local r = localRoot()
                local hrp = murd and murd.Character and murd.Character:FindFirstChild("\x48umanoidRootPart")
                if not r or not hrp then return false end
                return (r.Position - hrp.Position).Magnitude < 38
            end
            local function onBagFull()
                bagIsFull = true
                if not farming then return end
                notify("\x340 монет — bag full", 3)
                if killAllOn then task.spawn(doKillAll) end
                if shootMurdOn then doShootMurd() end
                if resetFull then
                    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("\x48umanoid")
                    if hum then hum.Health = 0 end
                end
            end
            pcall(function()
                local gp = ReplicatedStorage:FindFirstChild("\x52emotes")
                gp = gp and gp:FindFirstChild("\x47ameplay")
                local ev = gp and gp:FindFirstChild("\x43oinCollected")
                if ev and ev.OnClientEvent then
                    ev.OnClientEvent:Connect(function(_, current, max)
                        current, max = tonumber(current), tonumber(max)
                        if current and max and current >= max then onBagFull() end
                    end)
                end
                local endEv = gp and gp:FindFirstChild("\x52oundEndFade")
                if endEv and endEv.OnClientEvent then
                    endEv.OnClientEvent:Connect(function() bagIsFull = false end)
                end
                local startEv = gp and gp:FindFirstChild("\x52oundStart")
                if startEv and startEv.OnClientEvent then
                    startEv.OnClientEvent:Connect(function() bagIsFull = false end)
                end
            end)
            pcall(function()
                LocalPlayer.Idled:Connect(function()
                    local vu = game:GetService("\x56irtualUser")
                    vu:CaptureController()
                    vu:ClickButton2(Vector2.new())
                end)
            end)
            local function farmBtn(parent, label, fn)
                local b = New("\x54extButton", { Parent = parent, Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = C.btn,
                    Text = label, TextColor3 = C.text, TextSize = 15, Font = Enum.Font.Gotham, AutoButtonColor = false })
                corner(b, 12); stroke(b, C.border, .5)
                b.MouseButton1Click:Connect(fn)
                b.Activated:Connect(fn)
                return b
            end
            local function makeFarmSlider(parent, label, minV, maxV, default, cb)
                local r = New("\x46rame", { Parent = parent, Size = UDim2.new(1, 0, 0, 68), BackgroundTransparency = 1 })
                text(r, label, 16, UDim2.fromOffset(0, 8))
                local value = New("\x54extBox", { Parent = r, Position = UDim2.new(1, -72, 0, 5), Size = UDim2.fromOffset(72, 30), BackgroundColor3 = C.surface,
                    BackgroundTransparency = .12, Text = tostring(default), TextColor3 = C.text, TextSize = 14, Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Center, ClearTextOnFocus = false })
                corner(value, 9); stroke(value, C.border, .4)
                local track = New("\x54extButton", { Parent = r, Position = UDim2.new(0, 0, 1, -18), Size = UDim2.new(1, 0, 0, 6),
                    BackgroundColor3 = C.off, Text = "", AutoButtonColor = false })
                corner(track, 3)
                local span = math.max(maxV - minV, 1)
                local fill = New("\x46rame", { Parent = track, Size = UDim2.fromScale((default - minV) / span, 1), BackgroundColor3 = C.accent, BorderSizePixel = 0 })
                corner(fill, 3)
                local knob = New("\x46rame", { Parent = track, AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new((default - minV) / span, 0, .5, 0),
                    Size = UDim2.fromOffset(14, 14), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0, ZIndex = 2 })
                corner(knob, 7)
                local current = default
                local function set(v)
                    current = math.clamp(math.floor((tonumber(v) or current or default) + .5), minV, maxV)
                    fill.Size = UDim2.fromScale((current - minV) / span, 1)
                    knob.Position = UDim2.new((current - minV) / span, 0, .5, 0)
                    value.Text = tostring(current)
                    cb(current)
                    farmWrite("\x73liders", label, current)
                end
                set(default)
                value.FocusLost:Connect(function() set(value.Text) end)
                local drag = false
                local function fromInput(i)
                    local w = track.AbsoluteSize.X
                    if w < 1 then return end
                    set(minV + span * math.clamp((i.Position.X - track.AbsolutePosition.X) / w, 0, 1))
                end
                track.InputBegan:Connect(function(i)
                    if isPrimaryPress(i) then drag = true; fromInput(i) end
                end)
                track.InputEnded:Connect(function(i)
                    if isPrimaryPress(i) then drag = false end
                end)
                UIS.InputChanged:Connect(function(i)
                    if drag and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
                        fromInput(i)
                    end
                end)
                UIS.InputEnded:Connect(function(i)
                    if isPrimaryPress(i) then drag = false end
                end)
            end
            local function goHome()
                local r = localRoot()
                local cf = returnCFrame()
                if not r or not cf then return false end
                freezeRoot(r, false)
                r.CFrame = cf
                pcall(function()
                    r.AssemblyLinearVelocity = Vector3.zero
                    r.AssemblyAngularVelocity = Vector3.zero
                end)
                return true
            end
            local function stopFarmHold()
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("\x48umanoid")
                if hum then
                    hum.PlatformStand = false
                    hum.AutoRotate = true
                    pcall(function()
                        hum.WalkSpeed = 16
                        hum.JumpPower = 50
                        hum.JumpHeight = 7.2
                    end)
                end
                freezeRoot(localRoot(), false)
                pcall(function() workspace.FallenPartsDestroyHeight = origDestroyH end)
            end
            pcall(function()
                LocalPlayer.CharacterAdded:Connect(function(char)
                    local hrp = char:WaitForChild("\x48umanoidRootPart", 5)
                    task.wait(0.25)
                    freezeRoot(hrp, false)
                    local hum = char:FindFirstChildOfClass("\x48umanoid")
                    if hum then hum.PlatformStand = false; hum.AutoRotate = true end
                    if farming then
                        holdReturnUntil = os.clock() + 0.9
                        goHome()
                        setStatus("\x52eturn To " .. fopt.ret)
                    end
                end)
            end)

            local holder = panel("\x41utofarm", "\x54ween Speed / Delay как Overdrive", "\x66arm", farmCol or col)
            statusLbl = New("\x54extLabel", { Parent = holder, Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1,
                Text = "\x49dle", TextColor3 = C.dim, TextSize = 13, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left })
            makeToggle(holder, "\x41uto Farm", function(on)
                farming = on
                if not on then
                    if farmTw then pcall(function() farmTw:Cancel() end); farmTw = nil end
                    setNoclip(false)
                    stopFarmHold()
                    goHome()
                    setStatus("\x52eturn To " .. fopt.ret)
                    notify("\x41utofarm OFF → " .. fopt.ret, 2)
                    return
                end
                notify("\x41utofarm ON · " .. fopt.method, 2)
                pcall(function() workspace.FallenPartsDestroyHeight = -50000 end)
                setNoclip(true)
                task.spawn(function()
                    while farming do
                        local char = LocalPlayer.Character
                        local r = localRoot()
                        local hum = char and char:FindFirstChildOfClass("\x48umanoid")
                        if not r or not hum or hum.Health <= 0 then
                            freezeRoot(r, false)
                            setStatus("\x57ait respawn...")
                            task.wait(0.4)
                            continue
                        end
                        if os.clock() < holdReturnUntil then
                            task.wait(0.08)
                            continue
                        end
                        if bagIsFull then
                            setStatus("\x42ag full (40)")
                            maybeRoleReset()
                            task.wait(1)
                            continue
                        end
                        maybeRoleReset()
                        local parts = getCoinParts()
                        if #parts > 0 then
                            lastMapCF = CFrame.new(parts[1].Position + Vector3.new(0, 5, 0))
                        end
                        if #parts == 0 then
                            lastCoin = nil
                            goHome()
                            setStatus("\x52eturn To " .. fopt.ret)
                            task.wait(0.45)
                            continue
                        end
                        if murdTooClose() then
                            setStatus("\x41void Murderer")
                            task.wait(0.4)
                            continue
                        end
                        if fopt.method == "\x4cay" then
                            hum.PlatformStand = true
                            hum.AutoRotate = false
                        else
                            hum.PlatformStand = false
                            hum.AutoRotate = true
                        end
                        local part, bestD = nil, 1e9
                        local fallback, fallD = nil, 1e9
                        for n = 1, #parts do
                            local p = parts[n]
                            if p and p.Parent then
                                local d = (r.Position - p.Position).Magnitude
                                if d < fallD then fallD, fallback = d, p end
                                if p ~= lastCoin and d < bestD then bestD, part = d, p end
                            end
                        end
                        part = part or fallback
                        if not part then
                            task.wait(0.15)
                            continue
                        end
                        setStatus(fopt.method .. "\x20· spd " .. tostring(fopt.spd) .. "\x25 · coins " .. tostring(#parts))
                        tweenTo(poseAt(part))
                        local root = localRoot()
                        if root and part and part.Parent then
                            freezeRoot(root, false)
                            touch(root, part)
                            magnetCoins()
                        end
                        lastCoin = part
                        local waitD = fopt.dly * 0.01
                        if waitD < 0.01 then waitD = 0.01 end
                        task.wait(waitD)
                    end
                    setNoclip(false)
                    stopFarmHold()
                    goHome()
                    setStatus("\x49dle")
                end)
            end)
            makeFarmSlider(holder, "\x54ween Speed (%)", 1, 100, fopt.spd, function(v) fopt.spd = v end)
            makeFarmSlider(holder, "\x54ween Delay (%)", 0, 100, fopt.dly, function(v) fopt.dly = v end)
            local methodBtn = farmBtn(holder, "\x4dethod: " .. fopt.method, function() end)
            local methods, mi = { "\x53tandard", "\x4cay" }, (fopt.method == "\x4cay" and 2 or 1)
            methodBtn.MouseButton1Click:Connect(function()
                mi = mi % #methods + 1
                fopt.method = methods[mi]
                methodBtn.Text = "\x4dethod: " .. fopt.method
                farmWrite("\x64ropdowns", "\x4dethod", fopt.method)
                notify("\x46arm method: " .. fopt.method, 2)
            end)
            local retBtn = farmBtn(holder, "\x52eturn To: " .. fopt.ret, function() end)
            local rets = { "\x4dap", "\x41bove Map", "\x4cobby" }
            local reti = 1
            for i = 1, #rets do if rets[i] == fopt.ret then reti = i end end
            retBtn.MouseButton1Click:Connect(function()
                reti = reti % #rets + 1
                fopt.ret = rets[reti]
                retBtn.Text = "\x52eturn To: " .. fopt.ret
                farmWrite("\x64ropdowns", "\x52eturn To", fopt.ret)
                notify("\x52eturn To: " .. fopt.ret, 2)
            end)
            makeToggle(holder, "\x43oin Aura", function(on)
                auraOn = on
                farmWrite("\x74oggles", "\x43oin Aura", on)
                if auraConn then auraConn:Disconnect(); auraConn = nil end
                if not on then return end
                auraConn = RunService.Heartbeat:Connect(function()
                    if auraOn then collectAura() end
                end)
                notify("\x43oin Aura ON", 2)
            end, farmRead("\x74oggles", "\x43oin Aura", false) == true)
            local radBtn = farmBtn(holder, "\x41ura radius: " .. tostring(auraRadius), function() end)
            local rads, ri = { 4, 8, 16, 32, 64 }, 2
            for i = 1, #rads do if rads[i] == auraRadius then ri = i end end
            radBtn.MouseButton1Click:Connect(function()
                ri = ri % #rads + 1
                auraRadius = rads[ri]
                radBtn.Text = "\x41ura radius: " .. tostring(auraRadius)
                farmWrite("\x73liders", "\x41ura radius", auraRadius)
            end)
            makeToggle(holder, "\x46arm Avoid Murderer", function(on)
                fopt.avoid = on
                farmWrite("\x74oggles", "\x46arm Avoid Murderer", on)
            end, fopt.avoid)
            makeToggle(holder, "\x41uto Grab Gun", function(on)
                gunFarm = on
                farmWrite("\x74oggles", "\x41uto Grab Gun", on)
                if not on then return end
                task.spawn(function()
                    while gunFarm do
                        local drop = workspace:FindFirstChild("\x47unDrop")
                        local root = localRoot()
                        if drop and root and not hasTool("\x47un") then
                            local part = drop:IsA("\x42asePart") and drop or drop:FindFirstChildWhichIsA("\x42asePart", true)
                            if part then touch(root, part) end
                        end
                        task.wait(0.45)
                    end
                end)
            end, farmRead("\x74oggles", "\x41uto Grab Gun", false) == true)
            makeToggle(holder, "\x41uto Reset As Murderer", function(on)
                fopt.rstM = on
                farmWrite("\x74oggles", "\x41uto Reset As Murderer", on)
            end, fopt.rstM)
            makeToggle(holder, "\x41uto Reset As Sheriff", function(on)
                fopt.rstS = on
                farmWrite("\x74oggles", "\x41uto Reset As Sheriff", on)
            end, fopt.rstS)
            makeToggle(holder, "\x52eset when bag full", function(on)
                resetFull = on
                farmWrite("\x74oggles", "\x52eset when bag full", on)
            end, farmRead("\x74oggles", "\x52eset when bag full", false) == true)
            makeToggle(holder, "\x44isable 3D Rendering", function(on)
                noRenderOn = on
                farmWrite("\x74oggles", "\x44isable 3D Rendering", on)
                pcall(function() RunService:Set3dRenderingEnabled(not on) end)
            end, farmRead("\x74oggles", "\x44isable 3D Rendering", false) == true)
            makeToggle(holder, "\x41uto-Kill All", function(on)
                killAllOn = on
                farmWrite("\x74oggles", "\x41uto-Kill All", on)
                if on then notify("\x4bill All — после 40 монет", 2) end
            end, farmRead("\x74oggles", "\x41uto-Kill All", false) == true)
            makeToggle(holder, "\x41uto-Shoot Murd", function(on)
                shootMurdOn = on
                farmWrite("\x74oggles", "\x41uto-Shoot Murd", on)
                if on then notify("\x53hoot Murd — после 40 монет", 2) end
            end, farmRead("\x74oggles", "\x41uto-Shoot Murd", false) == true)
        end
    end
    buildAutofarmUI()
end

function consumeData(data, fullSnapshot)
    if typeof(data) ~= "\x74able" then return false end
    local records = (typeof(data.Players) == "\x74able" and data.Players) or (typeof(data.players) == "\x74able" and data.players) or data
    local lookup = {}
    for key, info in pairs(records) do
        local keyText = string.lower(tostring(key))
        lookup[keyText] = info
        if typeof(info) == "\x74able" then
            for _, identity in ipairs({ info.Name, info.PlayerName, info.Username, info.UserId, info.UserID, info.Id, info.PlayerId }) do
                if identity ~= nil then lookup[string.lower(tostring(identity))] = info end
            end
        end
    end
    local function normalizeRole(info)
        if typeof(info) == "\x74able" then
            if info.Dead == true or info.Killed == true or info.IsDead == true or info.Alive == false then return "\x64ead" end
            info = info.Role or info.role or info.CurrentRole or info.currentRole or info.Team or info.team or info.Class
        end
        local value = string.lower(tostring(info or "\x69nnocent")):gsub("\x5b%s_%-]", "")
        if string.find(value, "\x6durder", 1, true) or string.find(value, "\x6biller", 1, true) then return "\x6durderer" end
        if string.find(value, "\x73heriff", 1, true) then return "\x73heriff" end
        if string.find(value, "\x68ero", 1, true) then return "\x68ero" end
        if string.find(value, "\x64ead", 1, true) or string.find(value, "\x6billed", 1, true) then return "\x64ead" end
        return "\x69nnocent"
    end
    local foundMurderer, foundSheriff, foundHero, received, changed = nil, nil, nil, false, false
    for _, player in ipairs(getPlayers()) do
        local info = lookup[string.lower(player.Name)] or lookup[tostring(player.UserId)] or lookup[string.lower(tostring(player.UserId))]
        if info ~= nil then
            received = true
            playerData[player.UserId] = info
            local resolved = normalizeRole(info)
            if roleCache[player.UserId] ~= resolved then
                roleCache[player.UserId], changed = resolved, true
                if autoNotifyRoles and (resolved == "\x6durderer" or resolved == "\x73heriff" or resolved == "\x68ero") and announcedRoles[player.UserId] ~= resolved then
                    announcedRoles[player.UserId] = resolved
                    notify(player.Name .. "\x20is " .. string.upper(resolved), 5)
                end
            end
            if resolved == "\x6durderer" then foundMurderer = player
            elseif resolved == "\x73heriff" then foundSheriff = player
            elseif resolved == "\x68ero" then foundHero = player end
        elseif fullSnapshot and roleCache[player.UserId] ~= "\x69nnocent" then
            roleCache[player.UserId], changed = "\x69nnocent", true
        end
    end
    local previousMurderer, previousSheriff, previousHero = murderer, sheriff, hero
    if fullSnapshot then
        murderer, sheriff, hero = foundMurderer, foundSheriff, foundHero
    else
        murderer, sheriff, hero = foundMurderer or murderer, foundSheriff or sheriff, foundHero or hero
    end
    if foundMurderer then setTarget(foundMurderer) end
    if previousMurderer ~= murderer or previousSheriff ~= sheriff or previousHero ~= hero then changed = true end
    if changed then
        local bus = getgenv().__NoirV4RoleBus
        if bus and bus.Emit then bus:Emit() end
    end
    return received
end
local playerDataRemote
function getPlayerDataRemote()
    if playerDataRemote and playerDataRemote.Parent then return playerDataRemote end
    local remote = ReplicatedStorage:FindFirstChild("\x47etPlayerData", true)
    playerDataRemote = (remote and remote:IsA("\x52emoteFunction")) and remote or nil
    return playerDataRemote
end
 
do
    local scanner = { busy = false, queued = false, delayed = false, force = false, last = -1e9 }
    function scanner:Request(force)
        self.force = self.force or force == true
        if self.busy then self.queued = true; return end
        local interval = instantRoleDetection and 0.35 or 1.35
        local elapsed = os.clock() - self.last
        if not self.force and elapsed < interval then
            self.queued = true
            if not self.delayed then
                self.delayed = true
                task.delay(interval - elapsed, function()
                    scanner.delayed = false
                    if scanner.queued then scanner.queued = false; scanner:Request(false) end
                end)
            end
            return
        end
        self.busy, self.queued = true, false
        self.force = false
        task.spawn(function()
             
            local knifeOwner, gunOwner = findByKnife(), findByGun()
            local fallbackChanged = false
            if knifeOwner and roleCache[knifeOwner.UserId] ~= "\x6durderer" then
                for userId, role in pairs(roleCache) do if role == "\x6durderer" then roleCache[userId] = "\x69nnocent" end end
                roleCache[knifeOwner.UserId], fallbackChanged = "\x6durderer", true
                setTarget(knifeOwner)
            end
            if gunOwner and gunOwner ~= knifeOwner and roleCache[gunOwner.UserId] ~= "\x73heriff" then
                for userId, role in pairs(roleCache) do if role == "\x73heriff" then roleCache[userId] = "\x69nnocent" end end
                roleCache[gunOwner.UserId], sheriff, fallbackChanged = "\x73heriff", gunOwner, true
            end
            if fallbackChanged then
                local bus = getgenv().__NoirV4RoleBus
                if bus and bus.Emit then bus:Emit() end
            end
            local applied = false
            local remote = getPlayerDataRemote()
            if remote then
                local ok, data = pcall(function() return remote:InvokeServer() end)
                if ok then applied = consumeData(data, true) end
            end
            if not applied and not knifeOwner then setTarget(nil) end
            scanner.last, scanner.busy = os.clock(), false
            if scanner.queued then scanner.queued = false; scanner:Request(false) end
        end)
    end
    getgenv().__NoirV4RoleScanner = scanner
end
function refreshTarget(force)
    local scanner = getgenv().__NoirV4RoleScanner
    if scanner and scanner.Request then scanner:Request(force == true) end
end
function updatePing()
    pcall(function()
        local network = Stats:FindFirstChild("\x4eetwork")
        local items = network and network:FindFirstChild("\x53erverStatsItem")
        local pingItem = items and items:FindFirstChild("\x44ata Ping")
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
    if partName == "\x52andom" then
        local opts = { "\x48ead", "\x55pperTorso", "\x4cowerTorso", "\x48umanoidRootPart" }
        partName = opts[math.random(#opts)]
    end
    local part = char:FindFirstChild(partName)
    if not part then part = char:FindFirstChild("\x48umanoidRootPart") or char.PrimaryPart end
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
    if mode == "\x4durderer" then return passesFilters(murderer, true) and murderer or nil end
    if mode == "\x53heriff" then return passesFilters(sheriff, true) and sheriff or nil end
    if mode == "\x48ero" then return passesFilters(hero, true) and hero or nil end
    if mode == "\x53elected" then
        local p = config.selectedPlayer and Players:FindFirstChild(config.selectedPlayer)
        return passesFilters(p, true) and p or nil
    end
    if mode == "\x4eearest" then
        local best, bd
        for _, p in ipairs(getPlayers()) do
            if passesFilters(p) then local d = distanceTo(p); if not bd or d < bd then best, bd = p, d end end
        end
        return best
    end
    if mode == "\x43rosshair" then
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
    if mode == "\x4cowest Health" then
        local best, bh
        for _, p in ipairs(getPlayers()) do
            if passesFilters(p) then
                local hum = p.Character and p.Character:FindFirstChildWhichIsA("\x48umanoid")
                local h = hum and hum.Health or math.huge
                if not bh or h < bh then best, bh = p, h end
            end
        end
        return best
    end
    if mode == "\x52andom" then
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
    return getAimPart(player) or character:FindFirstChild("\x48umanoidRootPart") or character.PrimaryPart
end
function findNearestKnifeTarget()
    local root = localRoot()
    if not root then return nil end
    local closest, closestDistance
    for _, player in ipairs(getPlayers()) do
        if passesFilters(player) then
            local targetRoot = player.Character and player.Character:FindFirstChild("\x48umanoidRootPart")
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
    return getAimPart(player) or character:FindFirstChild("\x48umanoidRootPart") or character.PrimaryPart
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
    return { Sim = math.floor(mix("\x53im") + 0.5), Interval = math.floor(mix("\x49nterval") + 0.5),
        H = math.floor(mix("\x48") + 0.5), V = math.floor(mix("\x56") + 0.5),
        X = math.floor(mix("\x58") + 0.5), Y = math.floor(mix("\x59") + 0.5), Z = math.floor(mix("\x5a") + 0.5) }
end
local function syncAutoPing(settings, controlKey, pingMs)
    if not settings or not settings.prioritizePing then return end
    if settings.manualPingMs ~= pingMs then
        settings.manualPingMs = pingMs
        local control = revertControls[controlKey]
        if type(control) == "\x74able" and type(control.SetValue) == "\x66unction" then pcall(control.SetValue, control, pingMs)
        elseif type(control) == "\x66unction" then pcall(control, pingMs) end
        local mirror = noirMirrorControls[controlKey]
        if type(mirror) == "\x74able" and type(mirror.SetValue) == "\x66unction" then pcall(mirror.SetValue, mirror, pingMs)
        elseif type(mirror) == "\x66unction" then pcall(mirror, pingMs) end
    end
end
function autoTuneForPing()
    local now = os.clock()
    if now - lastAutoTune < 0.4 then return end
    lastAutoTune = now
    local pingMs = math.clamp(math.floor(cachedPing * 1000 + 0.5), 5, 1000)
    syncAutoPing(config, "\x6danualPingMs", pingMs)
    syncAutoPing(config.knifeAim, "\x6bnifeManualPingMs", pingMs)
end
function leadTime(profile)
    local settings = profile == "\x6bnife" and config.knifeAim or config
    local observedPing = settings.prioritizePing and cachedPing or (settings.manualPingMs / 1000)
    local prediction
    if settings.adaptive then
        prediction = observedPing + settings.extraLead
        if settings.predictLag then
            local samplingDelay = math.clamp(settings.predictionIntervalMs / 2000, 0, 0.05)
            prediction = prediction + samplingDelay + math.max(0, observedPing - 0.10) * 0.15
        end
    else
        prediction = settings.fixedLead
    end
     
     
     
     
     
    local simulationCap = settings.maxSimulationMs / 1000
    if settings.adaptive then
        simulationCap = math.min(.30, simulationCap + math.clamp(observedPing - .10, 0, .25) * .45)
    end
    return math.clamp(prediction, 0.02, simulationCap)
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
    local time = leadTime()
     
     
     
    local displacement = Vector3.new(velocity.X * horizontal * time, 0, velocity.Z * horizontal * time)
    if config.predictLag then
        local horizontalAcceleration = Vector3.new(acceleration.X, 0, acceleration.Z)
        displacement = displacement + horizontalAcceleration * (0.5 * time * time)
    end
    if config.predictJump then
        local verticalTime = time * vertical
        local verticalDisplacement = velocity.Y * verticalTime
        local humanoid = part.Parent and part.Parent:FindFirstChildWhichIsA("\x48umanoid")
        if humanoid and humanoid.FloorMaterial == Enum.Material.Air then
            verticalDisplacement = verticalDisplacement - 0.5 * Workspace.Gravity * verticalTime * verticalTime
        end
        displacement = displacement + Vector3.new(0, verticalDisplacement, 0)
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
    local time = math.clamp(leadTime("\x6bnife") + travelTime, 0.03, 0.7)
    local offset = Vector3.new(part.Size.X * settings.offsetX / 100, part.Size.Y * settings.offsetY / 100, part.Size.Z * settings.offsetZ / 100)
    return part.Position + predictedVelocity * time + offset
end
local wallCheckParams = RaycastParams.new()
wallCheckParams.FilterType = Enum.RaycastFilterType.Exclude
wallCheckParams.IgnoreWater = true
function targetVisible(part, forceWallCheck)
    if not (forceWallCheck or config.wallCheck) then return true end
    local character = LocalPlayer.Character
    local originPart = character and (character:FindFirstChild("\x48ead") or character:FindFirstChild("\x48umanoidRootPart"))
    if not originPart or not part then return false end
    wallCheckParams.FilterDescendantsInstances = { character }
    local result = Workspace:Raycast(originPart.Position, part.Position - originPart.Position, wallCheckParams)
    return result == nil or result.Instance:IsDescendantOf(part.Parent)
end

 
 
 
local function piercerShotOrigin(origin, aim, part, enabled)
    if not enabled or not origin or not aim or not part then return origin end
    local direction = aim - origin
    local distance = direction.Magnitude
    if distance <= 0.05 then return origin end
    local dir = direction.Unit
    local character = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChildOfClass("\x42ackpack")
    local filter = { character, part.Parent }
    local gun = (character and character:FindFirstChild("\x47un")) or (backpack and backpack:FindFirstChild("\x47un"))
    if gun then filter[#filter + 1] = gun end
    for _, player in ipairs(getPlayers()) do
        if player.Character and player.Character ~= character then filter[#filter + 1] = player.Character end
    end
    wallCheckParams.FilterDescendantsInstances = filter
    local blocked = Workspace:Raycast(origin, dir * distance, wallCheckParams)
    if not blocked then return origin end
    local inner = Workspace:Raycast(aim, -dir * distance, wallCheckParams)
    local candidate = inner and (inner.Position + dir * 0.9) or (aim - dir * 0.9)
    if (aim - candidate).Magnitude > 0.02 and not Workspace:Raycast(candidate, aim - candidate, wallCheckParams) then
        return candidate
    end
    candidate = aim - dir * 0.5
    if (aim - candidate).Magnitude > 0.02 and not Workspace:Raycast(candidate, aim - candidate, wallCheckParams) then
        return candidate
    end
    return aim - dir * 0.4
end

function knifeRemote(remote, args)
    if not config.knifeEnabled or args.n < 2 then return false end
    if typeof(remote) ~= "\x49nstance" or not remote:IsA("\x52emoteEvent") then return false end
    if remote.Name ~= "\x4bnifeThrown" then return false end
    if typeof(args[1]) ~= "\x43Frame" or typeof(args[2]) ~= "\x43Frame" then return false end
    local character = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChildOfClass("\x42ackpack")
    local knife = character and character:FindFirstChild("\x4bnife")
    if knife and remote:IsDescendantOf(knife) then return true end
    if character and remote:IsDescendantOf(character) then return true end
    if backpack and remote:IsDescendantOf(backpack) then return true end
    return false
end
local function localGunTool()
    local character = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChildOfClass("\x42ackpack")
    return (character and character:FindFirstChild("\x47un")) or (backpack and backpack:FindFirstChild("\x47un"))
end
local function remoteBelongsToLocalGun(remote)
    local character=LocalPlayer.Character
    local backpack=LocalPlayer:FindFirstChildOfClass("\x42ackpack")
    local tool=remote and remote:FindFirstAncestorOfClass("\x54ool")
    if tool and tool.Name=="\x47un" and ((character and tool:IsDescendantOf(character)) or (backpack and tool:IsDescendantOf(backpack))) then return true end
    local characterGun=character and character:FindFirstChild("\x47un")
    local backpackGun=backpack and backpack:FindFirstChild("\x47un")
    return (characterGun and remote:IsDescendantOf(characterGun)) or (backpackGun and remote:IsDescendantOf(backpackGun))
end
function shotRemote(remote, args)
    if not (config.enabled or config.piercerBullet or buttonShotActive) or args.n < 2 then return false end
    if typeof(remote) ~= "\x49nstance" or not remote:IsA("\x52emoteEvent") then return false end
    if not remoteBelongsToLocalGun(remote) then return false end
    local first, second = args[1], args[2]
    local firstIsPos = typeof(first) == "\x56ector3" or typeof(first) == "\x43Frame"
    local secondIsPos = typeof(second) == "\x56ector3" or typeof(second) == "\x43Frame"
    return firstIsPos and secondIsPos
end
local function fallbackGunOrigin()
    local gun = localGunTool()
    local handle = gun and gun:FindFirstChild("\x48andle", true)
    if handle and handle:IsA("\x42asePart") then return handle.Position end
    local character = LocalPlayer.Character
    local root = character and (character:FindFirstChild("\x48ead") or character:FindFirstChild("\x48umanoidRootPart"))
    return root and root.Position or nil
end
local function vectorOrCFramePosition(value)
    if typeof(value) == "\x43Frame" then return value.Position end
    if typeof(value) == "\x56ector3" then return value end
    return nil
end
local function hasCFrameArgument(args)
    for index = 1, args.n do
        if typeof(args[index]) == "\x43Frame" then return true end
    end
    return false
end
function redirect(remote, args)
    local part, useWallCheck, isKnife = nil, false, false
    if shotRemote(remote, args) then
        if not buttonShotActive and config.aimKey ~= "\x4eone" and not aimHeld then return end
        if config.shotMethod == "\x43Frame" and not hasCFrameArgument(args) then return end
        part = (buttonShotActive and buttonShotTarget and getAimPart(buttonShotTarget)) or targetPart()
         
        useWallCheck = config.wallCheck and not config.piercerBullet
    elseif knifeRemote(remote, args) then
        part = knifeTargetPart(); useWallCheck = config.knifeWallCheck; isKnife = true
    else
        return
    end
    if not part or typeof(part) ~= "\x49nstance" or not part:IsA("\x42asePart") then return end
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
    if firstType == "\x43Frame" then
        local origin = args[1].Position
        local shotOrigin = piercerShotOrigin(origin, aim, part, config.piercerBullet)
        if (config.alignDirection or shotOrigin ~= origin) and (aim - shotOrigin).Magnitude > 0.01 then
            args[1] = CFrame.lookAt(shotOrigin, aim)
        end
        if secondType == "\x43Frame" then
            args[2] = CFrame.new(aim)
        elseif secondType == "\x56ector3" then
            args[2] = aim
        else
            return
        end
    elseif firstType == "\x56ector3" then
        local origin = args[1]
        local shotOrigin = piercerShotOrigin(origin, aim, part, config.piercerBullet)
        args[1] = shotOrigin
        if secondType == "\x56ector3" then
            if args[2].Magnitude <= 1.5 and (aim - shotOrigin).Magnitude > 0.01 then
                args[2] = (aim - shotOrigin).Unit
            else
                args[2] = aim
            end
        elseif secondType == "\x43Frame" then
            args[2] = CFrame.new(aim)
        else
            return
        end
    else
        return
    end
    redirected = redirected + 1
end

local function swallowKnifeRemote(self)
    if typeof(self) ~= "\x49nstance" or self.ClassName ~= "\x52emoteEvent" then return false end
    if string.lower(tostring(self.Name or "")) ~= "\x6bnifethrown" then return false end
    if not (config.knifeInstantThrow or config.knifeFastThrow) then return false end
    local runtime
    pcall(function() runtime = getgenv().__NoirKnifeUtilityRuntime end)
    return type(runtime) == "\x74able" and type(runtime.lastInstantThrow) == "\x6eumber" and os.clock() - runtime.lastInstantThrow < .48
end
function installHook()
    if hooked then return true end
    local wrap = type(newcclosure) == "\x66unction" and newcclosure or function(callback) return callback end
    local isOwnCall = type(checkcaller) == "\x66unction" and checkcaller or function() return false end
    if type(hookmetamethod) == "\x66unction" and type(getnamecallmethod) == "\x66unction" then
        local old
        local ok, err = pcall(function()
            old = hookmetamethod(game, "\x5f_namecall", wrap(function(self, ...)
                local method = getnamecallmethod()
                local methodLower = string.lower(tostring(method or ""))
                if (methodLower == "\x66ireserver" or methodLower == "\x69nvokeserver" or methodLower == "\x66ire") and typeof(self) == "\x49nstance" then
                    if swallowKnifeRemote(self) then return end
                    if self.ClassName == "\x52emoteEvent" and methodLower == "\x66ireserver" and not isOwnCall() then
                        local args = table.pack(...)
                        pcall(redirect, self, args)
                        if type(setnamecallmethod) == "\x66unction" then setnamecallmethod(method) end
                        return old(self, table.unpack(args, 1, args.n))
                    end
                end
                return old(self, ...)
            end))
        end)
        if ok and type(old) == "\x66unction" then
            hooked = true
            return true
        end
        notify("\x4eamecall hook failed: " .. tostring(err), 5)
    end
    if type(hookfunction) ~= "\x66unction" then notify("\x4eo hook support in this executor", 6) return false end
    local probe = Instance.new("\x52emoteEvent")
    local original
    local ok, err = pcall(function()
        original = hookfunction(probe.FireServer, wrap(function(self, ...)
            local args = table.pack(...)
            if typeof(self) == "\x49nstance" then
                if swallowKnifeRemote(self) then return end
                if self.ClassName == "\x52emoteEvent" and not isOwnCall() then pcall(redirect, self, args) end
            end
            return original(self, table.unpack(args, 1, args.n))
        end))
    end)
    probe:Destroy()
    if not ok or type(original) ~= "\x66unction" then notify("\x48ook failed: " .. tostring(err), 6) return false end
    hooked = true
    return true
end
function toggle(value)
    config.enabled = value == true
    if config.enabled then
        if not installHook() then config.enabled = false return end
        task.spawn(refreshTarget)
        notify("\x45nabled", 2)
    else
        notify("\x44isabled", 2)
    end
end

function setPiercerBullet(value)
    config.piercerBullet = value == true
    if config.piercerBullet and not installHook() then
        config.piercerBullet = false
        notify("\x50iercer Bullet requires hook support", 4)
    end
end

do
    local CollectionService = game:GetService("\x43ollectionService")
    local touch = type(firetouchinterest) == "\x66unction" and firetouchinterest or nil
    local active = {}
    local stepConnection

    local function ownKnifeTool()
        local character = LocalPlayer.Character
        local backpack = LocalPlayer:FindFirstChildOfClass("\x42ackpack")
        return (character and character:FindFirstChild("\x4bnife")) or (backpack and backpack:FindFirstChild("\x4bnife"))
    end

    local function knifePosition(knife)
        if not knife or not knife.Parent then return nil end
        local blade = knife:FindFirstChild("\x42ladePosition")
        if blade and blade:IsA("\x42asePart") then return blade.Position end
        if blade and blade:IsA("\x41ttachment") then return blade.WorldPosition end
        local visual = knife:FindFirstChild("\x4bnifeVisual")
        if visual and visual:IsA("\x42asePart") then return visual.Position end
        if knife:IsA("\x42asePart") then return knife.Position end
        local part = knife:FindFirstChildWhichIsA("\x42asePart", true)
        if part then return part.Position end
        return nil
    end

    local function isOwnKnife(knife)
        local link = knife:FindFirstChild("\x48andleLink")
        local character = LocalPlayer.Character
        local backpack = LocalPlayer:FindFirstChildOfClass("\x42ackpack")
        if link and link:IsA("\x4fbjectValue") and link.Value then
            if character and link.Value:IsDescendantOf(character) then return true end
            if backpack and link.Value:IsDescendantOf(backpack) then return true end
        end
        local root = character and character:FindFirstChild("\x48umanoidRootPart")
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
        local handle = tool and tool:FindFirstChild("\x48andle", true)
        local blade = knife:FindFirstChild("\x42ladePosition")
        if not (blade and blade:IsA("\x42asePart")) then
            blade = knife:IsA("\x42asePart") and knife or knife:FindFirstChildWhichIsA("\x42asePart", true)
        end
        touchPair(blade, part)
        if handle and handle:IsA("\x42asePart") and handle ~= blade then touchPair(handle, part) end
        if not tool then return end
        local touched = tool:FindFirstChild("\x48andleTouched", true)
        if touched and touched:IsA("\x52emoteEvent") then pcall(touched.FireServer, touched, part) end
        local stabbed = tool:FindFirstChild("\x4bnifeStabbed", true)
        if stabbed and stabbed:IsA("\x52emoteEvent") then pcall(stabbed.FireServer, stabbed) end
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
                        local root = character and character:FindFirstChild("\x48umanoidRootPart")
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
        local isKnife = knife.Name == "\x54hrowingKnife" or knife:HasTag("\x54hrowingKnife")
            or knife:FindFirstChild("\x48andleLink") ~= nil or knife:FindFirstChild("\x42ladePosition") ~= nil
        if not isKnife then return end
        if not isOwnKnife(knife) then
            knife:WaitForChild("\x48andleLink", 0.1)
            if not isOwnKnife(knife) then return end
        end
        active[knife] = { started = os.clock(), hit = {} }
        if not stepConnection then stepConnection = RunService.Heartbeat:Connect(step) end
    end

    CollectionService:GetInstanceAddedSignal("\x54hrowingKnife"):Connect(function(knife) task.defer(track, knife) end)
    Workspace.ChildAdded:Connect(function(child)
        if child.Name == "\x54hrowingKnife" or child:HasTag("\x54hrowingKnife") then task.defer(track, child) end
    end)
end

 
 
task.defer(function()
    local prior = getgenv().__NoirKnifeUtilityRuntime
    if type(prior) == "\x74able" and type(prior.Stop) == "\x66unction" then pcall(prior.Stop) end

    local runtime = { stopped = false, connections = {}, bindConnections = {}, gui = nil, button = nil,
        dualVisual = nil, dualSource = nil, dualLimb = nil, dualLeftShoulder = nil, dualRightShoulder = nil,
        dualOriginalC0 = nil, dualOriginalTransform = nil, ghostModel = nil, ghostParts = {}, hiddenParts = {}, dualTorso = nil,
        poseBind = "\x4eoirKnifeDualArmPose", nextAction = 0, lastInstantThrow = 0, lastStab = {} }
    local function connect(signal, callback)
        local connection = signal:Connect(callback)
        runtime.connections[#runtime.connections + 1] = connection
        return connection
    end
    local function findKnifeTool(parent)
        if not parent then return nil end
        local named = parent:FindFirstChild("\x4bnife")
        if named and named:IsA("\x54ool") then return named end
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA("\x54ool") and (child:FindFirstChild("\x4bnifeThrown", true) or child:FindFirstChild("\x4bnifeStabbed", true) or child:FindFirstChild("\x48andleTouched", true)) then
                return child
            end
        end
        return nil
    end
    local function equippedKnife()
        return findKnifeTool(LocalPlayer.Character)
    end
    local function limbFor(character, side)
        return character and (character:FindFirstChild(side .. "\x48and") or character:FindFirstChild(side .. "\x20Arm") or character:FindFirstChild(side .. "\x4cowerArm")) or nil
    end
    local function shoulderFor(character, side)
        local joint = character and (character:FindFirstChild(side .. "\x53houlder", true) or character:FindFirstChild(side .. "\x20Shoulder", true))
        return joint and joint:IsA("\x4dotor6D") and joint or nil
    end
    local function rootFor(player)
        local character = player and player.Character
        return character and (character:FindFirstChild("\x48umanoidRootPart") or character.PrimaryPart) or nil
    end
    local function killPlayerByName()
        local name = tostring(config.knifeKillPlayer or "\x4e/A")
        local player = name ~= "\x4e/A" and Players:FindFirstChild(name) or nil
        return validTarget(player) and player or nil
    end
    local function sheriffTarget()
        if validTarget(sheriff) then return sheriff end
        local fallback = findByGun()
        return validTarget(fallback) and fallback or nil
    end
    local function knifeThrowRemote(tool)
        for _, object in ipairs(tool:GetDescendants()) do
            if object:IsA("\x52emoteEvent") and object.Name == "\x4bnifeThrown" then return object end
        end
        return nil
    end
    local function throwCooldown()
        if config.knifeInstantThrow then return .05 end
        if config.knifeFastThrow then return .12 end
        return .38
    end
    local function throwAt(player)
        local tool, part = equippedKnife(), getAimPart(player)
        local handle = tool and tool:FindFirstChild("\x48andle", true)
        local remote = tool and knifeThrowRemote(tool)
        if not tool then return false, "\x65quip" end
        if not part or not handle or not handle:IsA("\x42asePart") or not remote then return false end
        local now = os.clock()
        if now < runtime.nextAction then return false end
        runtime.nextAction = now + throwCooldown()
        local origin = handle.Position
        local aim = calculateKnifeAim(part, origin)
        local look = CFrame.lookAt(origin, aim)
        local hit = CFrame.new(aim)
        local ok = pcall(function() remote:FireServer(look, hit) end)
        if not ok then ok = pcall(function() remote:FireServer(hit) end) end
        if not ok then ok = pcall(function() remote:FireServer(aim) end) end
        if ok then runtime.lastInstantThrow = now end
        return ok == true
    end
    local function pokeTouch(handle, part)
        if not handle or not part or not handle.Parent or not part.Parent then return end
        if type(firetouchinterest) ~= "\x66unction" then return end
        pcall(firetouchinterest, handle, part, 0)
        pcall(firetouchinterest, handle, part, 1)
        pcall(firetouchinterest, handle, part, true)
        pcall(firetouchinterest, handle, part, false)
    end
    local function stabAt(player)
        local tool = equippedKnife()
        local character = player and player.Character
        if not tool or not character or not validTarget(player) then return false end
        local handle = tool:FindFirstChild("\x48andle", true)
        if not handle or not handle:IsA("\x42asePart") then return false end
        local now = os.clock()
        if now - (runtime.lastStab[player] or 0) < .08 then return false end
        runtime.lastStab[player] = now
        for _, part in ipairs(character:GetChildren()) do
            if part:IsA("\x42asePart") then pokeTouch(handle, part) end
        end
        local hrp = character:FindFirstChild("\x48umanoidRootPart") or character.PrimaryPart
        local touched = tool:FindFirstChild("\x48andleTouched", true)
        local stabbed = tool:FindFirstChild("\x4bnifeStabbed", true)
        if touched and touched:IsA("\x52emoteEvent") then
            if hrp then pcall(touched.FireServer, touched, hrp) end
            pcall(touched.FireServer, touched, character)
        end
        if stabbed and stabbed:IsA("\x52emoteEvent") then
            pcall(stabbed.FireServer, stabbed)
            if hrp then pcall(stabbed.FireServer, stabbed, hrp) end
        end
        return true
    end
    local function attack(player)
        if not validTarget(player) then return false end
        return stabAt(player)
    end
    local function killSheriff(silent)
        if not equippedKnife() then
            if not silent then notify("\x45quip the Knife first", 3) end
            return false
        end
        local target = sheriffTarget()
        local success = target and attack(target) or false
        if not silent then notify(success and ("\x53tab: " .. target.Name) or "\x53heriff not found / knife not ready", 3) end
        return success
    end
    local function killEveryone(silent)
        if not equippedKnife() then
            if not silent then notify("\x45quip the Knife first", 3) end
            return 0
        end
        local count = 0
        for _, player in ipairs(getPlayers()) do
            if validTarget(player) and attack(player) then count += 1 end
        end
        if not silent then notify(count > 0 and ("\x53tabbed " .. tostring(count) .. "\x20target(s)") or "\x53tab: no valid target", 3) end
        return count
    end
    local function killSelected(silent)
        if not equippedKnife() then
            if not silent then notify("\x45quip the Knife first", 3) end
            return false
        end
        local target = killPlayerByName()
        if not target then
            if not silent then notify("\x53elect a player in Kill Player", 3) end
            return false
        end
        local success = attack(target)
        if not silent then notify(success and ("\x53tab: " .. target.Name) or "\x53tab: wait / failed", 3) end
        return success
    end
    local function armPartPairs(character)
        local pairs = {}
        if character and character:FindFirstChild("\x52ight Arm") then
            pairs[#pairs + 1] = { character:FindFirstChild("\x52ight Arm"), character:FindFirstChild("\x4ceft Arm") }
        else
            for _, suffix in ipairs({ "\x55pperArm", "\x4cowerArm", "\x48and" }) do
                local source, target = character and character:FindFirstChild("\x52ight" .. suffix), character and character:FindFirstChild("\x4ceft" .. suffix)
                if source and target then pairs[#pairs + 1] = { source, target } end
            end
        end
        return pairs
    end
    local function cleanVisualClone(part)
        local clone = part:Clone()
        for _, child in ipairs(clone:GetDescendants()) do
            if child:IsA("\x53cript") or child:IsA("\x4cocalScript") or child:IsA("\x57eld") or child:IsA("\x57eldConstraint") or child:IsA("\x4dotor6D") then child:Destroy() end
        end
        clone.Anchored, clone.CanCollide, clone.CanTouch, clone.CanQuery, clone.Massless = true, false, false, false, true
        clone.CastShadow = false
        return clone
    end
    local function destroyDualVisual()
        if runtime.ghostModel and runtime.ghostModel.Parent then runtime.ghostModel:Destroy() end
        for part, original in pairs(runtime.hiddenParts) do if part and part.Parent then pcall(function() part.LocalTransparencyModifier = original end) end end
        table.clear(runtime.hiddenParts); table.clear(runtime.ghostParts)
        runtime.ghostModel, runtime.dualVisual, runtime.dualSource, runtime.dualTorso = nil, nil, nil, nil
        runtime.dualLimb, runtime.dualLeftShoulder, runtime.dualRightShoulder, runtime.dualOriginalC0, runtime.dualOriginalTransform = nil, nil, nil, nil, nil
    end
    local function refreshDualEffect()
         
        config.knifeDualEffect = false
        destroyDualVisual()
    end
    local function updateGhostDual()
        local torso, weapon = runtime.dualTorso, runtime.dualVisual
        if not torso or not torso.Parent or not weapon or not weapon.Parent then return end
        local function mirrored(source)
            local relative = torso.CFrame:ToObjectSpace(source.CFrame)
            local p = relative.Position
            local x, y, z = relative:ToOrientation()
            return torso.CFrame * CFrame.new(-p.X, p.Y, p.Z) * CFrame.Angles(x, -y, -z)
        end
        for clone, source in pairs(runtime.ghostParts) do if clone and clone.Parent and source and source.Parent then clone.CFrame = mirrored(source) end end
        if runtime.dualSource and runtime.dualSource.Parent then weapon.CFrame = mirrored(runtime.dualSource) end
    end
    local function disconnectKnifeBind()
        for _, connection in ipairs(runtime.bindConnections) do pcall(function() connection:Disconnect() end) end
        table.clear(runtime.bindConnections)
    end
    local function destroyBind()
        disconnectKnifeBind()
        if runtime.gui then runtime.gui:Destroy() end
        runtime.gui, runtime.button = nil, nil
        for _, parent in ipairs({ guiParent, CoreGui, LocalPlayer:FindFirstChildOfClass("\x50layerGui") }) do
            local stale = parent and parent:FindFirstChild("\x4eoirKnifeSheriffBind")
            if stale then stale:Destroy() end
        end
    end
    local function updateBindShape()
        local button = runtime.button
        if not button then return end
        local cornerObject = button:FindFirstChild("\x4eoirShape")
        if cornerObject then cornerObject.CornerRadius = config.knifeSheriffBindShape == "\x43ircle" and UDim.new(1, 0) or UDim.new(0, 11) end
    end
    local function createBind()
        if runtime.button then updateBindShape(); return end
        local parent = guiParent
        if typeof(parent) ~= "\x49nstance" then parent = LocalPlayer:FindFirstChildOfClass("\x50layerGui") end
        if typeof(parent) ~= "\x49nstance" then return end
        local gui = New("\x53creenGui", { Parent = parent, Name = "\x4eoirKnifeSheriffBind", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 84, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
        local button = New("\x49mageButton", { Parent = gui, Name = "\x4billSheriff", AnchorPoint = Vector2.new(.5, .5), Position = NoirPersistence.GetPosition("\x6bnife_sheriff_bind_v1", UDim2.new(.68, 0, .73, 0)), Size = UDim2.fromOffset(48, 48),
            BackgroundColor3 = Color3.fromRGB(8, 8, 10), BackgroundTransparency = .28, BorderSizePixel = 0, AutoButtonColor = false, Image = "", ClipsDescendants = false, ZIndex = 8 })
        local shape = New("\x55ICorner", { Parent = button, Name = "\x4eoirShape", CornerRadius = UDim.new(1, 0) })
        local aspect = New("\x55IAspectRatioConstraint", { Parent = button, AspectRatio = 1, AspectType = Enum.AspectType.ScaleWithParentSize })
        local metal = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 40)), ColorSequenceKeypoint.new(.22, Color3.fromRGB(250, 250, 252)), ColorSequenceKeypoint.new(.48, Color3.fromRGB(70, 70, 78)), ColorSequenceKeypoint.new(.72, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(45, 45, 52)) })
        local outer = New("\x55IStroke", { Parent = button, Color = Color3.fromRGB(255, 255, 255), Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
        local outerGradient = New("\x55IGradient", { Parent = outer, Color = metal })
        local inner = New("\x55IStroke", { Parent = button, Color = Color3.fromRGB(105, 105, 112), Transparency = .5, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
        local innerGradient = outerGradient:Clone(); innerGradient.Rotation = 180; innerGradient.Parent = inner
        local label = New("\x54extLabel", { Parent = button, Name = "\x54ext", AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromScale(.76, .76), BackgroundTransparency = 1, Text = "\x4bill\nSheriff", TextColor3 = C.text, TextSize = 9, TextWrapped = true, Font = Enum.Font.GothamBold, ZIndex = 9 })
        local pressScale = New("\x55IScale", { Parent = button, Scale = 1 })
        runtime.gui, runtime.button = gui, button
        updateBindShape()
        local dragging, moved, start, origin, dragInput, lastBind = false, false, nil, nil, nil, 0
        local function fireBind()
            if moved then return end
            local now = os.clock()
            if now - lastBind < .25 then return end
            lastBind = now
            killSheriff(false)
        end
        table.insert(gradientStrokes.fast, outerGradient)
        runtime.bindConnections[#runtime.bindConnections + 1] = button.InputBegan:Connect(function(input)
            if not isPrimaryPress(input) then return end
            dragging, moved, start, origin = true, false, input.Position, button.Position
            TweenService:Create(pressScale, TweenInfo.new(.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Scale = 1.035 }):Play()
        end)
        runtime.bindConnections[#runtime.bindConnections + 1] = button.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
        end)
        runtime.bindConnections[#runtime.bindConnections + 1] = UIS.InputChanged:Connect(function(input)
            if not dragging or input ~= dragInput then return end
            local delta = input.Position - start
            if delta.Magnitude > 7 then moved = true end
            button.Position = UDim2.new(origin.X.Scale, origin.X.Offset + delta.X, origin.Y.Scale, origin.Y.Offset + delta.Y)
        end)
        runtime.bindConnections[#runtime.bindConnections + 1] = UIS.InputEnded:Connect(function(input)
            if not dragging or not isPrimaryPress(input) then return end
            dragging = false
            TweenService:Create(pressScale, TweenInfo.new(.20, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
            if moved then NoirPersistence.SetPosition("\x6bnife_sheriff_bind_v1", button.Position) return end
            fireBind()
        end)
        runtime.bindConnections[#runtime.bindConnections + 1] = button.Activated:Connect(fireBind)
        runtime.bindConnections[#runtime.bindConnections + 1] = button.MouseButton1Click:Connect(fireBind)
    end
    function runtime:Refresh()
        refreshDualEffect()
        if config.knifeSheriffBind then createBind() else destroyBind() end
        updateBindShape()
    end
    function runtime:KillSheriff() return killSheriff(false) end
    function runtime:KillEveryone() return killEveryone(false) end
    function runtime:KillSelected() return killSelected(false) end
    local function nearestTarget()
        local chosen, distance = nil, math.huge
        local ownRoot = localRoot()
        for _, player in ipairs(getPlayers()) do
            local root = rootFor(player)
            if validTarget(player) and root then
                local d = ownRoot and (root.Position - ownRoot.Position).Magnitude or 0
                if d < distance then chosen, distance = player, d end
            end
        end
        return chosen
    end
    local function onKnifeActivated()
        if not (config.knifeInstantThrow or config.knifeFastThrow) then return end
        local player = knifeTargetPlayer() or nearestTarget()
        if player then throwAt(player) end
    end
    local boundTools = {}
    local function bindKnifeTool(tool)
        if not tool or not tool:IsA("\x54ool") or boundTools[tool] then return end
        if tool.Name ~= "\x4bnife" and not tool:FindFirstChild("\x4bnifeThrown", true) then return end
        boundTools[tool] = true
        connect(tool.Activated, onKnifeActivated)
    end
    local function watchCharacter(character)
        if not character then return end
        local knife = findKnifeTool(character)
        if knife then bindKnifeTool(knife) end
        connect(character.ChildAdded, function(child)
            if child:IsA("\x54ool") then bindKnifeTool(child) end
        end)
    end
    if LocalPlayer.Character then watchCharacter(LocalPlayer.Character) end
    connect(LocalPlayer.CharacterAdded, watchCharacter)
    connect(UIS.InputBegan, function(input, processed)
        if processed then return end
        if not (config.knifeInstantThrow or config.knifeFastThrow) then return end
        if not equippedKnife() then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        onKnifeActivated()
    end)
    pcall(function() RunService:UnbindFromRenderStep(runtime.poseBind) end)
    RunService:BindToRenderStep(runtime.poseBind, Enum.RenderPriority.Last.Value, function()
        if runtime.stopped or not config.knifeDualEffect or not (runtime.dualVisual and runtime.dualVisual.Parent) then return end
        pcall(updateGhostDual)
    end)
    runtime.connections[#runtime.connections + 1] = RunService.Heartbeat:Connect(function()
        if runtime.stopped then return end
        pcall(refreshDualEffect)
        if config.knifeAutoKillEveryone then pcall(killEveryone, true)
        elseif config.knifeAutoKillSheriff then pcall(killSheriff, true) end
    end)
    function runtime:Stop()
        if runtime.stopped then return end
        runtime.stopped = true
        pcall(function() RunService:UnbindFromRenderStep(runtime.poseBind) end)
        for _, connection in ipairs(runtime.connections) do pcall(function() connection:Disconnect() end) end
        destroyBind(); destroyDualVisual()
    end
    getgenv().__NoirKnifeUtilityRuntime = runtime
    runtime:Refresh()
end)

function findGunRemote()
    local gun=localGunTool()
    if not gun then return nil end
    local best,bestScore
    for _,object in ipairs(gun:GetDescendants()) do
        if object:IsA("\x52emoteEvent") then
            local name=object.Name
            local score=#name
            if name=="\x53hoot" then score+=50 end
            if name=="\x47unFired" or name=="\x4bnifeThrown" then score=-1 end
            if score>=(bestScore or 0) then best,bestScore=object,score end
        end
    end
    return best
end
function fireGunAt(player, usePrediction)
    if shootBusy then return false end
    shootBusy = true
    local success = false
    pcall(function()
        if not validTarget(player) then return end
        local part = getAimPart(player)
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildWhichIsA("\x48umanoid")
        local backpack = LocalPlayer:FindFirstChildOfClass("\x42ackpack")
        if not part or not character or not humanoid then return end
        if config.wallCheck and not config.piercerBullet and not targetVisible(part) then return end
        local autoEquipped = false
        local gun = character:FindFirstChild("\x47un")
        if not gun and backpack then
            gun = backpack:FindFirstChild("\x47un")
            if gun then humanoid:EquipTool(gun); autoEquipped = true; task.wait(0.10) end
        end
        if not gun or not gun:IsA("\x54ool") then
            if autoEquipped and humanoid.Parent then humanoid:UnequipTools() end
            return
        end
        local remote=findGunRemote()
        local handle=gun:FindFirstChild("\x48andle",true)
        if not remote or not handle or not handle:IsA("\x42asePart") then
            if autoEquipped and humanoid.Parent then humanoid:UnequipTools() end
            return
        end
        local aim = usePrediction == false and part.Position or calculateAim(part)
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

 
 
task.defer(function()
    local prior = getgenv().__NoirGunTriggerRuntime
    if type(prior) == "\x74able" and type(prior.Stop) == "\x66unction" then pcall(prior.Stop) end

    local runtime = { stopped = false, connections = {}, dualVisual = nil, dualSource = nil, dualLimb = nil, dualLeftShoulder = nil, dualRightShoulder = nil,
        dualOriginalC0 = nil, dualOriginalTransform = nil, ghostModel = nil, ghostParts = {}, hiddenParts = {}, dualTorso = nil,
        poseBind = "\x4eoirGunDualArmPose", lastShot = 0, wasPointing = false, nextVisualCheck = 0 }
    local function equippedGun()
        local character = LocalPlayer.Character
        return character and character:FindFirstChild("\x47un") or nil
    end
    local function shoulderFor(character, side)
        local joint = character and (character:FindFirstChild(side .. "\x53houlder", true) or character:FindFirstChild(side .. "\x20Shoulder", true))
        return joint and joint:IsA("\x4dotor6D") and joint or nil
    end
    local function armPartPairs(character)
        local pairs = {}
        if character and character:FindFirstChild("\x52ight Arm") then
            pairs[#pairs + 1] = { character:FindFirstChild("\x52ight Arm"), character:FindFirstChild("\x4ceft Arm") }
        else
            for _, suffix in ipairs({ "\x55pperArm", "\x4cowerArm", "\x48and" }) do
                local source, target = character and character:FindFirstChild("\x52ight" .. suffix), character and character:FindFirstChild("\x4ceft" .. suffix)
                if source and target then pairs[#pairs + 1] = { source, target } end
            end
        end
        return pairs
    end
    local function cleanVisualClone(part)
        local clone = part:Clone()
        for _, child in ipairs(clone:GetDescendants()) do
            if child:IsA("\x53cript") or child:IsA("\x4cocalScript") or child:IsA("\x57eld") or child:IsA("\x57eldConstraint") or child:IsA("\x4dotor6D") then child:Destroy() end
        end
        clone.Anchored, clone.CanCollide, clone.CanTouch, clone.CanQuery, clone.Massless = true, false, false, false, true
        clone.CastShadow = false
        return clone
    end
    local function destroyDual()
        if runtime.ghostModel and runtime.ghostModel.Parent then runtime.ghostModel:Destroy() end
        for part, original in pairs(runtime.hiddenParts) do if part and part.Parent then pcall(function() part.LocalTransparencyModifier = original end) end end
        table.clear(runtime.hiddenParts); table.clear(runtime.ghostParts)
        runtime.ghostModel, runtime.dualVisual, runtime.dualSource, runtime.dualTorso = nil, nil, nil, nil
        runtime.dualLimb, runtime.dualLeftShoulder, runtime.dualRightShoulder, runtime.dualOriginalC0, runtime.dualOriginalTransform = nil, nil, nil, nil, nil
    end
    local function refreshDual()
         
        config.gunDualEffect = false
        destroyDual()
    end
    local function updateGhostDual()
        local torso, weapon = runtime.dualTorso, runtime.dualVisual
        if not torso or not torso.Parent or not weapon or not weapon.Parent then return end
        local function mirrored(source)
            local relative = torso.CFrame:ToObjectSpace(source.CFrame)
            local p = relative.Position
            local x, y, z = relative:ToOrientation()
            return torso.CFrame * CFrame.new(-p.X, p.Y, p.Z) * CFrame.Angles(x, -y, -z)
        end
        for clone, source in pairs(runtime.ghostParts) do if clone and clone.Parent and source and source.Parent then clone.CFrame = mirrored(source) end end
        if runtime.dualSource and runtime.dualSource.Parent then weapon.CFrame = mirrored(runtime.dualSource) end
    end
    local function murdererTarget()
        local target = selectTarget("\x4durderer")
        if not target then
            local fallback = findByKnife()
            if validTarget(fallback) then target = fallback end
        end
        return target
    end
    local function crosshairOn(player)
        local camera, part = Workspace.CurrentCamera, getAimPart(player)
        if not camera or not part then return false end
        local center = camera.ViewportSize * .5
        local ray = camera:ViewportPointToRay(center.X, center.Y)
        local ownCharacter = LocalPlayer.Character
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = ownCharacter and { ownCharacter } or {}
        params.IgnoreWater = true
        local hit = Workspace:Raycast(ray.Origin, ray.Direction * 2000, params)
        if hit and hit.Instance and hit.Instance:IsDescendantOf(player.Character) then return true end
         
         
        local projected, visible = camera:WorldToViewportPoint(part.Position)
        if not visible or (Vector2.new(projected.X, projected.Y) - Vector2.new(center.X, center.Y)).Magnitude > 26 then return false end
        return not config.gunTriggerBotWallCheck or targetVisible(part, true)
    end
    pcall(function() RunService:UnbindFromRenderStep(runtime.poseBind) end)
    RunService:BindToRenderStep(runtime.poseBind, Enum.RenderPriority.Last.Value, function()
        if runtime.stopped or not config.gunDualEffect or not (runtime.dualVisual and runtime.dualVisual.Parent) then return end
        pcall(updateGhostDual)
    end)
    runtime.connections[#runtime.connections + 1] = RunService.RenderStepped:Connect(function()
        if runtime.stopped then return end
        local now = os.clock()
        if now >= runtime.nextVisualCheck then runtime.nextVisualCheck = now + .25; refreshDual() end
        if not config.gunTriggerBot then runtime.wasPointing = false; return end
        local target = murdererTarget()
        local pointing = target and crosshairOn(target) or false
        if pointing and not runtime.wasPointing and now - runtime.lastShot >= .28 then
            runtime.lastShot = now
            fireGunAt(target, config.gunTriggerBotPrediction)
        end
        runtime.wasPointing = pointing
    end)
    function runtime:RefreshDual() refreshDual() end
    function runtime:Stop()
        if runtime.stopped then return end
        runtime.stopped = true
        pcall(function() RunService:UnbindFromRenderStep(runtime.poseBind) end)
        for _, connection in ipairs(runtime.connections) do pcall(function() connection:Disconnect() end) end
        destroyDual()
    end
    getgenv().__NoirGunTriggerRuntime = runtime
    refreshDual()
end)

function shootTarget()
    local player = selectTarget()
     
    if not player then player = findByKnife(); refreshTarget(true) end
    if player then return fireGunAt(player) end
    return false
end
task.spawn(function()
    while running do
        if config.autoFire and config.enabled and (config.autoFireKey == "\x4eone" or autoFireHeld) then
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
    if type(gethui) == "\x66unction" then local ok, result = pcall(gethui); if ok and typeof(result) == "\x49nstance" then parent = result end end
    if typeof(parent) ~= "\x49nstance" then parent = LocalPlayer:WaitForChild("\x50layerGui") end
    shootGui = Instance.new("\x53creenGui")
    shootGui.Name = "\x4dM2ShootMurdererButton"; shootGui.ResetOnSpawn = false; shootGui.IgnoreGuiInset = true
    shootGui.DisplayOrder = 80; shootGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; shootGui.Parent = parent
    local button = Instance.new("\x54extButton")
    button.Name = "\x53hootMurderer"
    button.AnchorPoint = Vector2.new(0.5, 0.5)
    button.Position = NoirPersistence.GetPosition("\x73hoot_v2", UDim2.new(1, -132, 1, -124))
    button.Size = UDim2.new(0, 194, 0, 66)
    button.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
    button.BackgroundTransparency = 0.28
    button.BorderSizePixel = 0
    button.Text = "\x53hoot Murder"
    button.TextColor3 = Color3.fromRGB(245, 245, 248)
    button.TextSize = 17
    button.TextWrapped = true
    button.Font = Enum.Font.Gotham
    button.ClipsDescendants = false
    button.AutoButtonColor = false
    button.ZIndex = 5
    button.Parent = shootGui
    shootButton = button
    local corner2 = Instance.new("\x55ICorner"); corner2.CornerRadius = UDim.new(0, 16); corner2.Parent = button
    local stroke2 = Instance.new("\x55IStroke")
    stroke2.Color = Color3.fromRGB(255, 255, 255); stroke2.Thickness = 2; stroke2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; stroke2.Parent = button
    local gradient = Instance.new("\x55IGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 40)),
        ColorSequenceKeypoint.new(0.22, Color3.fromRGB(250, 250, 252)),
        ColorSequenceKeypoint.new(0.48, Color3.fromRGB(70, 70, 78)),
        ColorSequenceKeypoint.new(0.72, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(45, 45, 52)),
    })
    gradient.Parent = stroke2
    table.insert(gradientStrokes, gradient)
    local innerStroke = Instance.new("\x55IStroke")
    innerStroke.Color = Color3.fromRGB(105, 105, 112); innerStroke.Transparency = 0.5; innerStroke.Thickness = 1
    innerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; innerStroke.Parent = button
    local innerGradient = gradient:Clone(); innerGradient.Rotation = 180; innerGradient.Parent = innerStroke
    table.insert(gradientStrokes, innerGradient)
    local traceA = Instance.new("\x46rame"); traceA.AnchorPoint = Vector2.new(.5, .5); traceA.Position = UDim2.fromScale(0, .08)
    traceA.Size = UDim2.fromOffset(8, 8); traceA.BackgroundColor3 = Color3.new(1, 1, 1); traceA.BorderSizePixel = 0; traceA.ZIndex = 10; traceA.Parent = button
    local traceB = traceA:Clone(); traceB.Position = UDim2.fromScale(1, .92); traceB.Parent = button
    Instance.new("\x55ICorner", traceA).CornerRadius = UDim.new(1, 0)
    Instance.new("\x55ICorner", traceB).CornerRadius = UDim.new(1, 0)
    traceA.Visible = false; traceB.Visible = false
    local sound = Instance.new("\x53ound"); sound.Name = "\x53ound"; sound.SoundId = "\x72bxassetid://3868133279"; sound.Volume = 0.5; sound.Parent = button
    local normalSize = UDim2.new(0, 194, 0, 66)
    local pressedSize = UDim2.new(0, 206, 0, 72)
    local pressTween = TweenInfo.new(0.30, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local dragging, moved, dragStart, startPosition, dragInput = false, false, nil, nil, nil
    button.InputBegan:Connect(function(input)
        if isPrimaryPress(input) then
            dragging = not config.lockShootButton; moved = false; dragStart = input.Position; startPosition = button.Position
            TweenService:Create(button, pressTween, { Size = pressedSize, TextSize = 18, BackgroundColor3 = Color3.fromRGB(27,27,31) }):Play()
            button.Text = "\x54 A R G E T   L O C K"
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
            NoirPersistence.SetPosition("\x73hoot_v2", button.Position)
            TweenService:Create(button, TweenInfo.new(.62, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = normalSize, TextSize = 17, BackgroundColor3 = Color3.fromRGB(8,8,10), BackgroundTransparency = .28 }):Play()
            button.Text = "\x53hoot Murder"
            traceA.Visible = false; traceB.Visible = false
        end
    end)
    button.Activated:Connect(function() if not moved then task.spawn(shootTarget) end end)
end
function setShootButtonVisible(value)
    config.showShootButton = value == true
    if config.showShootButton then createShootButton() else removeShootButton() end
end

local fovCircle = New("\x46rame", { Parent = gui, AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5),
    BackgroundTransparency = 1, Size = UDim2.fromOffset(200, 200), Visible = false, ZIndex = 2 })
New("\x55ICorner", { Parent = fovCircle, CornerRadius = UDim.new(.5, 0) })
local fovStroke = New("\x55IStroke", { Parent = fovCircle, Color = Color3.fromRGB(232,232,236), Thickness = 1.5, Transparency = .35 })
function updateFovCircle()
    fovCircle.Visible = false
end

local roundTimerGui
local function formatRoundTime(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    return string.format("\x2502d:%02d", math.floor(seconds / 60), seconds % 60)
end
local function roundLengthFromEvent(value)
    local direct = tonumber(value)
    if direct and direct > 0 then return math.clamp(math.floor(direct + 0.5), 1, 600) end
    if typeof(value) == "\x74able" then
        for _, key in ipairs({ "\x54ime", "\x74ime", "\x54imer", "\x74imer", "\x54imeLeft", "\x74imeLeft", "\x52emaining", "\x72emaining", "\x53econds", "\x73econds", "\x56alue", "\x76alue" }) do
            local nested = tonumber(value[key])
            if nested and nested > 0 then return math.clamp(math.floor(nested + 0.5), 1, 600) end
        end
    end
    return 180
end
local function resetRoundTimer()
    roundResetToken += 1
    roundState = "\x77aiting"
    lastRoundResetAt = os.clock()
    roundTimerEndsAt = nil
    roundPendingStart = nil
    if roundTimerGui and roundTimerGui.Parent then roundTimerGui.Text = "\x57AITING" end
end
local function beginRoundTimer(roundLength)
    roundResetToken += 1
    roundState = "\x70laying"
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
    roundTimerGui = Instance.new("\x54extLabel")
    roundTimerGui.Name = "\x4eoirRoundTimer"
    roundTimerGui.Parent = gui
    roundTimerGui.AnchorPoint = Vector2.new(.5, 0)
    roundTimerGui.Position = UDim2.new(.5, 0, 0, 18)
    roundTimerGui.Size = UDim2.fromOffset(220, 50)
    roundTimerGui.BackgroundColor3 = C.panel
    roundTimerGui.BackgroundTransparency = .12
    roundTimerGui.TextColor3 = C.text
    roundTimerGui.Text = "\x57AITING"
    roundTimerGui.TextSize = 20
    roundTimerGui.Font = Enum.Font.GothamBold
    roundTimerGui.ZIndex = 900
    corner(roundTimerGui, 15); stroke(roundTimerGui, C.border, .15)
    local thisGui = roundTimerGui
    task.spawn(function()
        while roundTimerGui == thisGui and thisGui.Parent do
            if roundState == "\x70laying" and roundTimerEndsAt then
                local left = math.ceil(roundTimerEndsAt - os.clock())
                if left > 0 then
                    thisGui.Text = formatRoundTime(left)
                else
                    resetRoundTimer()
                    thisGui.Text = "\x57AITING"
                end
            else
                thisGui.Text = "\x57AITING"
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
     
    localHumChar, localHumCache, localRootChar, localRootCache = nil, nil, nil, nil
    task.spawn(function()
        character:WaitForChild("\x48umanoid", 10)
        character:WaitForChild("\x48umanoidRootPart", 10)
        if LocalPlayer.Character == character then applyCharacterMods() end
    end)
end)
applyCharacterMods()

function findSheriff()
    if validTarget(sheriff) then return sheriff end
    return findByGun()
end

function showMurdererChance()
    local chance = ReplicatedStorage:FindFirstChild("\x47etChance", true)
    if chance and chance:IsA("\x52emoteFunction") then
        local ok, value = pcall(function() return chance:InvokeServer() end)
        notify(ok and ("\x4durderer chance: " .. tostring(value) .. "\x25") or "\x43hance unavailable", 4)
    else
        notify("\x47etChance remote not found", 4)
    end
end

do
    local virtualUser = game:GetService("\x56irtualUser")
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
    name = tostring(name or "\x64efault"):gsub("\x25.preset$", ""):gsub("\x5b^%w_%- ]", "\x5f")
    return name ~= "" and name or "\x64efault"
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
            gunDualEffect = config.gunDualEffect, gunTriggerBot = config.gunTriggerBot,
            gunTriggerBotWallCheck = config.gunTriggerBotWallCheck, gunTriggerBotPrediction = config.gunTriggerBotPrediction,
            knifeWallCheck = config.knifeWallCheck,
            knifePrioritizeSheriff = config.knifePrioritizeSheriff, knifeAutoThrow = config.knifeAutoThrow,
            knifeDualEffect = config.knifeDualEffect,
            knifeInstantThrow = config.knifeInstantThrow, knifeFastThrow = config.knifeFastThrow,
            knifeAutoKillEveryone = config.knifeAutoKillEveryone, knifeAutoKillSheriff = config.knifeAutoKillSheriff,
            knifeKillPlayer = config.knifeKillPlayer, knifeSheriffBind = config.knifeSheriffBind,
            knifeSheriffBindShape = config.knifeSheriffBindShape, knifeThrownAura = config.knifeThrownAura,
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
        game = "\x4durder Mystery 2",
        category = "\x67un",
    }
end
function applyRevertConfig(data)
    if typeof(data) ~= "\x74able" then return false end
    local cfg = data.cfg
    if typeof(cfg) == "\x74able" then
        if typeof(cfg.predict_jump) == "\x62oolean" then config.predictJump = cfg.predict_jump end
        if typeof(cfg.prediction_ping) == "\x6eumber" then config.manualPingMs = cfg.prediction_ping end
        if typeof(cfg.prioritize_your_ping) == "\x62oolean" then config.prioritizePing = cfg.prioritize_your_ping end
        if typeof(cfg.horizontal_multiplier) == "\x6eumber" then config.horizontalMultiplier = cfg.horizontal_multiplier * 100 end
        if typeof(cfg.vertical_multiplier) == "\x6eumber" then config.verticalMultiplier = cfg.vertical_multiplier * 100 end
        if typeof(cfg.max_simulation_time) == "\x6eumber" then config.maxSimulationMs = cfg.max_simulation_time end
        if typeof(cfg.interval) == "\x6eumber" then config.predictionIntervalMs = cfg.interval * 10000 end
        if typeof(cfg.x_pos_offset) == "\x6eumber" then config.offsetX = cfg.x_pos_offset * 100 end
        if typeof(cfg.y_pos_offset) == "\x6eumber" then config.offsetY = cfg.y_pos_offset * 100 end
        if typeof(cfg.z_pos_offset) == "\x6eumber" then config.offsetZ = cfg.z_pos_offset * 100 end
        if typeof(cfg.predict_lag) == "\x62oolean" then config.predictLag = cfg.predict_lag end
    end
    local noir = data.noir
    if typeof(noir) == "\x74able" then
        for _, key in ipairs({ "\x74argetMode", "\x68itPart" }) do
            if typeof(noir[key]) == "\x73tring" then config[key] = noir[key] end
        end
        if noir.shotMethod == "\x52emote" or noir.shotMethod == "\x43Frame" then
            config.shotMethod = noir.shotMethod
        end
        for _, key in ipairs({ "\x66ovSize", "\x6daxDistance", "\x66ixedLead", "\x65xtraLead" }) do
            if typeof(noir[key]) == "\x6eumber" then config[key] = noir[key] end
        end
        for _, key in ipairs({ "\x61utoFire", "\x77allCheck", "\x70iercerBullet", "\x69gnoreDead", "\x69gnoreFriends", "\x61daptive", "\x61lignDirection",
                               "\x67unDualEffect", "\x67unTriggerBot", "\x67unTriggerBotWallCheck", "\x67unTriggerBotPrediction",
                               "\x6bnifeWallCheck", "\x6bnifePrioritizeSheriff", "\x6bnifeAutoThrow", "\x6bnifeThrownAura", "\x6bnifeDualEffect",
                               "\x6bnifeInstantThrow", "\x6bnifeFastThrow", "\x6bnifeAutoKillEveryone", "\x6bnifeAutoKillSheriff", "\x6bnifeSheriffBind" }) do
            if typeof(noir[key]) == "\x62oolean" then config[key] = noir[key] end
        end
        for _, key in ipairs({ "\x6bnifeKillPlayer", "\x6bnifeSheriffBindShape" }) do
            if typeof(noir[key]) == "\x73tring" then config[key] = noir[key] end
        end
        local knifeRuntime = getgenv().__NoirKnifeUtilityRuntime
        if type(knifeRuntime) == "\x74able" and type(knifeRuntime.Refresh) == "\x66unction" then task.defer(function() pcall(knifeRuntime.Refresh, knifeRuntime) end) end
        local gunRuntime = getgenv().__NoirGunTriggerRuntime
        if type(gunRuntime) == "\x74able" and type(gunRuntime.RefreshDual) == "\x66unction" then task.defer(function() pcall(gunRuntime.RefreshDual, gunRuntime) end) end
        if config.piercerBullet then task.defer(installHook) end
        local knifeAim = noir.knifeAim
        if typeof(knifeAim) == "\x74able" then
            for _, key in ipairs({ "\x66ixedLead", "\x65xtraLead", "\x6daxSimulationMs", "\x70redictionIntervalMs", "\x6danualPingMs", "\x6fffsetX", "\x6fffsetY", "\x6fffsetZ", "\x68orizontalMultiplier", "\x76erticalMultiplier" }) do
                if typeof(knifeAim[key]) == "\x6eumber" then config.knifeAim[key] = knifeAim[key] end
            end
            for _, key in ipairs({ "\x61daptive", "\x70rioritizePing", "\x70redictJump", "\x70redictLag" }) do
                if typeof(knifeAim[key]) == "\x62oolean" then config.knifeAim[key] = knifeAim[key] end
            end
        end
    end
    return true
end
local presetNames
function savePreset()
    if type(writefile) ~= "\x66unction" then notify("\x45xecutor does not support writefile", 4) return end
    ensurePresetFolder()
    local ok, encoded = pcall(function() return HttpService:JSONEncode(exportRevertConfig()) end)
    if ok then
        local wrote, err = pcall(writefile, PRESET_FOLDER .. "\x2f" .. cleanPresetName(presetName) .. "\x2epreset", xorPreset(encoded))
        if wrote then
            notify("\x50reset saved: " .. cleanPresetName(presetName), 3)
            if presetDropdown and presetDropdown.Refresh then presetDropdown:Refresh(presetNames(), cleanPresetName(presetName)) end
        else notify("\x50reset save failed: " .. tostring(err), 4) end
    else notify("\x50reset encode failed", 4) end
end
function loadPreset()
    if type(readfile) ~= "\x66unction" then notify("\x45xecutor does not support readfile", 4) return end
    local path = PRESET_FOLDER .. "\x2f" .. cleanPresetName(presetName) .. "\x2epreset"
    local ok, decoded = pcall(function()
        local raw = readfile(path)
        return HttpService:JSONDecode(xorPreset(raw))
    end)
    if ok and applyRevertConfig(decoded) then
        if type(syncRevertControls) == "\x66unction" then syncRevertControls() end
        notify("\x50reset loaded: " .. cleanPresetName(presetName), 3)
    else notify("\x50reset not found or invalid: " .. cleanPresetName(presetName), 4) end
end
presetNames = function()
    local names = { "\x64efault" }
    if type(listfiles) == "\x66unction" then
        ensurePresetFolder()
        local ok, files = pcall(listfiles, PRESET_FOLDER)
        if ok and typeof(files) == "\x74able" then
            for _, file in ipairs(files) do
                local normalized = tostring(file):gsub("\\", "\x2f")
                local name = normalized:match("\x28[^/]+)%.preset$")
                if name and not table.find(names, name) then names[#names + 1] = name end
            end
        end
    end
    table.sort(names)
    return names
end

 
local autoGGState = { enabled = false, token = 0 }
local gunUtilityState = {
    auraEnabled = false,
    auraRange = 25,
    droppedGunNotify = false,
    gunPickupNotify = false,
    wasHoldingGun = false,
    bindEnabled = false,
    bindButtonSize = 0.11,
    touchNoticeAt = 0,
    bindGui = nil,
    bindButton = nil,
    bindConnections = {},
    cachedDropParts = {},
    dropCacheAt = -1e9,
    dropCacheDirty = true,
    cacheAddedConnection = nil,
    cacheRemovingConnection = nil,
}

local function hasGunInInventory()
    return playerHasTool(LocalPlayer, "\x47un") ~= nil
end

 
 
local function getDroppedGunParts()
    local now = os.clock()
    local cached = gunUtilityState.cachedDropParts
    if not gunUtilityState.dropCacheDirty and now - gunUtilityState.dropCacheAt < 1.25 then
        local valid = {}
        for _, part in ipairs(cached) do if part and part.Parent then valid[#valid + 1] = part end end
        if #valid == #cached then return valid end
        gunUtilityState.dropCacheDirty = true
    end
    local candidates, seen = {}, {}
    local function add(part, priority)
        if not part or not part:IsA("\x42asePart") or seen[part] then return end
        seen[part] = true
        candidates[#candidates + 1] = { part = part, priority = priority }
    end
    local function scan(drop)
        if drop:IsA("\x42asePart") then
            local ownTouch = drop:FindFirstChildWhichIsA("\x54ouchTransmitter")
            add(drop, ownTouch and 1 or (drop.Name == "\x48andle" and 2 or 3))
        end
        for _, child in ipairs(drop:GetDescendants()) do
            if child:IsA("\x54ouchTransmitter") and child.Parent and child.Parent:IsA("\x42asePart") then add(child.Parent, 1)
            elseif child:IsA("\x42asePart") and child.Name == "\x48andle" then add(child, 2)
            elseif child:IsA("\x42asePart") and child.Name == "\x47unDrop" then add(child, 3)
            elseif child:IsA("\x42asePart") then add(child, 4) end
        end
    end
    for _, instance in ipairs(Workspace:GetDescendants()) do if instance.Name == "\x47unDrop" then scan(instance) end end
    table.sort(candidates, function(a, b) return a.priority < b.priority end)
    local parts = table.create(#candidates)
    for index, candidate in ipairs(candidates) do parts[index] = candidate.part end
    gunUtilityState.cachedDropParts, gunUtilityState.dropCacheAt, gunUtilityState.dropCacheDirty = parts, now, false
    return parts
end
 
gunUtilityState.UpdateDropWatchers = function()
    local enabled = gunUtilityState.auraEnabled or autoGGState.enabled or gunUtilityState.droppedGunNotify
    if enabled then
        if not gunUtilityState.cacheAddedConnection then
            gunUtilityState.dropCacheDirty = true
            gunUtilityState.cacheAddedConnection = Workspace.DescendantAdded:Connect(function(instance)
                if instance.Name == "\x47unDrop" or instance:IsA("\x54ouchTransmitter") then gunUtilityState.dropCacheDirty = true end
            end)
        end
        if not gunUtilityState.cacheRemovingConnection then
            gunUtilityState.cacheRemovingConnection = Workspace.DescendantRemoving:Connect(function(instance)
                if instance.Name == "\x47unDrop" or instance:IsA("\x54ouchTransmitter") then gunUtilityState.dropCacheDirty = true end
            end)
        end
    else
        if gunUtilityState.cacheAddedConnection then gunUtilityState.cacheAddedConnection:Disconnect(); gunUtilityState.cacheAddedConnection = nil end
        if gunUtilityState.cacheRemovingConnection then gunUtilityState.cacheRemovingConnection:Disconnect(); gunUtilityState.cacheRemovingConnection = nil end
    end
end

local function getDroppedGunPart()
    return getDroppedGunParts()[1]
end

local function touchDroppedGun()
    local root = localRoot()
    local drops = getDroppedGunParts()
    if not root or #drops == 0 or type(firetouchinterest) ~= "\x66unction" then return false end
    local touched = false
    local ok = pcall(function()
         
         
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
        gunUtilityState.dropCacheDirty = true
        if hasGunInInventory() then
            notify("\x59ou already have the Gun", 3)
        elseif not getDroppedGunPart() then
            notify("\x4eo dropped Gun found", 3)
        elseif grabDroppedGun() then
            notify("\x47un picked up", 3)
        else
            notify("\x47un pickup failed", 3)
        end
    end)
end

local function setGunAura(enabled)
    gunUtilityState.auraEnabled = enabled == true
    gunUtilityState.auraToken = (gunUtilityState.auraToken or 0) + 1
    local token = gunUtilityState.auraToken
    gunUtilityState.UpdateDropWatchers()
    if not gunUtilityState.auraEnabled then return end
    task.spawn(function()
        while running and gunUtilityState.auraEnabled and gunUtilityState.auraToken == token do
            if not hasGunInInventory() then
                local root, drop = localRoot(), getDroppedGunPart()
                if root and drop and not gunUtilityState.pickupBusy and (root.Position - drop.Position).Magnitude <= gunUtilityState.auraRange then
                     
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
    for _, parent in ipairs({guiParent, CoreGui, LocalPlayer:FindFirstChildOfClass("\x50layerGui")}) do
        if typeof(parent) == "\x49nstance" then
            local stale = parent:FindFirstChild("\x4eoirGrabGunBindButton")
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
    if typeof(parent) ~= "\x49nstance" then parent = LocalPlayer:WaitForChild("\x50layerGui") end
    local bindGui = Instance.new("\x53creenGui")
    bindGui.Name = "\x4eoirGrabGunBindButton"
    bindGui.ResetOnSpawn = false
    bindGui.IgnoreGuiInset = true
    bindGui.DisplayOrder = 81
    bindGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    bindGui.Parent = parent

    local button = Instance.new("\x49mageButton")
    button.Name = "\x47rabGun"
    button.AnchorPoint = Vector2.new(.5, .5)
    button.Position = NoirPersistence.GetPosition("\x67rab_gun_bind_v1", UDim2.new(.10, 0, .88, 0))
    button.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
    button.BackgroundTransparency = .28
    button.BorderSizePixel = 0
    button.Image = ""
    button.AutoButtonColor = false
    button.ClipsDescendants = false
    button.ZIndex = 5
    button.Parent = bindGui
    local buttonCorner = Instance.new("\x55ICorner")
    buttonCorner.CornerRadius = UDim.new(1, 0)
    buttonCorner.Parent = button
    local aspect = Instance.new("\x55IAspectRatioConstraint")
    aspect.AspectRatio = 1
    aspect.AspectType = Enum.AspectType.ScaleWithParentSize
    aspect.Parent = button
    local outerStroke = Instance.new("\x55IStroke")
    outerStroke.Color = Color3.fromRGB(255, 255, 255)
    outerStroke.Thickness = 2
    outerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    outerStroke.Parent = button
    local outerGradient = Instance.new("\x55IGradient")
    outerGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 40)),
        ColorSequenceKeypoint.new(.22, Color3.fromRGB(250, 250, 252)),
        ColorSequenceKeypoint.new(.48, Color3.fromRGB(70, 70, 78)),
        ColorSequenceKeypoint.new(.72, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(45, 45, 52))
    })
    outerGradient.Parent = outerStroke
    local innerStroke = Instance.new("\x55IStroke")
    innerStroke.Color = Color3.fromRGB(105, 105, 112)
    innerStroke.Transparency = .5
    innerStroke.Thickness = 1
    innerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    innerStroke.Parent = button
    local innerGradient = outerGradient:Clone()
    innerGradient.Rotation = 180
    innerGradient.Parent = innerStroke
    local textLabel = Instance.new("\x54extLabel")
    textLabel.Name = "\x54ext"
    textLabel.AnchorPoint = Vector2.new(.5, .5)
    textLabel.Position = UDim2.fromScale(.5, .5)
    textLabel.Size = UDim2.fromScale(.76, .76)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "\x47rab Gun"
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
        NoirPersistence.SetPosition("\x67rab_gun_bind_v1", button.Position)
    end)
    gunUtilityState.bindConnections[#gunUtilityState.bindConnections + 1] = button.Activated:Connect(function()
        if not moved then requestGrabGun() end
    end)
    table.insert(gradientStrokes.fast, outerGradient)
    gunUtilityState.bindGui, gunUtilityState.bindButton = bindGui, button
    updateGrabGunBindButtonSize()
end

local function setGrabGunBindButton(enabled)
    gunUtilityState.bindEnabled = enabled == true
    if gunUtilityState.bindEnabled then createGrabGunBindButton() else removeGrabGunBindButton() end
end

removeGrabGunBindButton()

task.spawn(function()
    local previousDrop = nil
    while running do
        local watchDrop = autoGGState.enabled or gunUtilityState.auraEnabled or gunUtilityState.droppedGunNotify
        local watchPickup = gunUtilityState.gunPickupNotify
        if watchDrop then
            local drop = getDroppedGunPart()
            if drop ~= previousDrop then
                if drop and gunUtilityState.droppedGunNotify then notify("\x44ropped Gun detected", 4) end
                previousDrop = drop
            end
        end
        if watchPickup then
            local hasGun = hasGunInInventory()
            if hasGun and not gunUtilityState.wasHoldingGun then notify("\x47un picked up", 3) end
            gunUtilityState.wasHoldingGun = hasGun
        end
        task.wait((watchDrop or watchPickup) and .25 or 1)
    end
end)

local function setAutoGG(enabled)
    autoGGState.enabled = enabled == true
    autoGGState.token += 1
    local token = autoGGState.token
    gunUtilityState.UpdateDropWatchers()
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

 
 
do
    local function buildCustomCursorControls()
        local cursorState = { enabled = false, colorEnabled = false, template = "\x44efault", customId = "", color = C.accent, artworkScale = 1.35, originalMouseIcon = nil, originalVisuals = {} }
        cursorState.templates = {
            "\x44efault", "\x47othic Spear", "\x47othic Wings", "\x53hadow Sigil",
            "\x44ark Seraph", "\x54horn Gun", "\x43rimson Halo", "\x52adiant Halo", "\x4doonblade", "\x56oid Slash", "\x53cript Blade", "\x4cight Seraph", "\x49nfinity",
            "\x43ustom",
        }
        cursorState.templateImages = {
            ["\x47othic Spear"] = "\x72bxassetid://77559278786615",
            ["\x47othic Wings"] = "\x72bxassetid://73847458193538",
            ["\x53hadow Sigil"] = "\x72bxassetid://130499812243487",
        }
         
        cursorState.bundles = {
            ["\x44ark Seraph"] = { file = "\x6eoir_cursor_v2_01_dark_seraph.png", scale = 1.75, data = "\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\x54kSuQmCC" },
            ["\x54horn Gun"] = { file = "\x6eoir_cursor_v2_02_thorn_gun.png", scale = 1.55, data = "\x69VBORw0KGgoAAAANSUhEUgAAAMAAAADACAYAAABS3GwHAABhVUlEQVR42u2dd3hU\x5afb4z3vvnTu9ZWqSSQ8JSUgoCQmEjqCAKKIGRV2xgrqoi8oCumuISrOu2ADdRbGg\x78EqvQugEAgnpkIT0NpmZTG/33vf3hzNsZGHVXXd/u/u9n+fJIyY3k1vOOe95T7sA\x50Dw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8\x50Dw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8\x50Dw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8\x50Dw8PDw8PDw8PDw8PDw8/zyFhYUEfxd4eHh4/g9af+rRRx9NwxhfaxXgV4f/QEj+\x46lwV9EvcnpKSEmwwGMaSJBl/7ty5uokTJ6KSkhJ8xaFYo9HIvV4vCwD4X3xeiH+E\x504+fa5VQQUEB+R9mxdCVDxpjjH7pw7/G7/xsAa2pqUEAAC6XS2u323uLiopw+HsD\x373F6enpuXFzcI48++mjGP7Ei4J95XzAv2v86Jfm3WpdXXnlFumbNGvmvuMlEf0cR\x34IEHHpD/9re/vXP9+vWSK44nQ/8mAYAacF8QAMCkSZNSR44c+QgAQMhYXP57o0aN\x45ufl5b1VWFgoCv+df0TZCwsLI1577TXxTz2D9evXKwsLCyledP/5FQABADd27Fj1\x70EmT7po8eXJWyLr8O5QgbFmFFEUJAACKioq48A+ffvppaWFhYURYMbZs2UI+9thj\x79fPnz9f+hKLigT9/4YUXhr7wwguDNmzYQGGMkVQqFSkUigOdnZ3MFceHXRcWABgA\x34Ab8nDh48GC93+/X5+XlGYqLi9nQvSUAAAuFwgyFQmEtKiry5+TkUOEVdcKECVRI\x6dcJfZEjJyYHfnzp1qiQuLk6oVqs1ERERSgDAISX70TW+/fbbsvXr1ytZltUAQMSv\x61DT+7/m6hYWFRFFRETd16tQ8u91+r9/v36nT6YbRNP31zp0768LK8S/YTBJFRUX4\x79mW8oKBArFAoFDfccIOvoKDAdd999z2mUqnsubm5OysrK7FGoyF7enquRwjVlJaW\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\x72b7Q09MTm5aWVkmSJHI6nbaUlJRTJ0+enO5yuTyTJ0/+vru7O4Jl2aqOjo47Wlpa\x68hqNRs/WrVtFLMsmLFy48ItgMPgOQRDDY2JiTjmdTplAIOAQQgq1Wt3e2tqq9Hg8\x42Muy/X6/f4JIJCofM2ZMb319PZw+fXosADTedNNN5TfffLMvJGdsfHx8qUwmO1pV\x56fXU4sWLo66//nr3t99+O9nv99/jdDp79Xp9VH5+/uKenp44hmHq8vPz+/bs2UOm\x70KQIoqKivGazWQgA0cnJyeaGhoYEkiQJq9WajBDyNzc3Dx45cuTmWbNmNWRkZCwm\x43GJaTU1NnlwuDxQWFib29/c7rjZsgbpWI8OECRNe6+rqyuju7sZKpVLz2WefvZCZ\x6dYk/+OADzZo1a2q2b9/ehjE29vb2BlmWJUPlAJcVimXZn+zGCQsixpiIiIgIikQi\x46iEksNvtAp/PV2AymQpKS0u9p0+fFgAAxbKsFyHEarVagdfr5QCAKCgosLAsC5cu\x58dKGXQutVhvweDzo2LFjgmPHjoU3ocBxHJZKpcyNN95Ym5OT0/HOO++M27Rp03VC\x6fbCutLQ0Zs+ePUkUReHp06dXzZs3b8esWbO+X7Vq1bgNGza83d3dTV1NaAmCQAAA\x30dHRl/70pz+9brVaFc8888zCkydPxlssFmmo8eXyBm1AFCX8z8uG4tKlS+BwOECj\x30cC+ffsAIQS5ubm4ubkZDAZDAGPcz3FcX2tra5RYLPYKhcJap9OpbGpqGmy1Wi23\x33nrrXxBCNovFMlkkEn0fHR3NWa3WaIPBcAwAoi0WS0t6evpzFy5cuMfr9Vb19PRM\x6aoiI0BsMhsPR0dGb3W73UI/H82BcXJw/MzNzS01Njae5ufnW6dOnf7N3797EioqK\x68ydNmvTapUuXqIqKiodomq7MzMz8qru7u7q1tdXtcDjSAoEAq1KpagUCAURFRQW3\x62NmC1qxZQ5SVlXEOh+NQUlLSmMrKSvFTTz1ls9lsYLfbyzUazcG4uDi51+vlKisr\x75ZUrV+575ZVXhuTn57eF7/f69esF8+fPd2zbti1YW1srFAgENSzL0iRJWvR6fd+k\x53ZP27tq1SwwAJMMw/u7u7smh5/L6okWL+q8VsKGubCwIb+K0Wu3ovr6+UaG4MnR3\x6449MSEjwymQywTvvvDPEbDYPzczMPNbb2zv2CnfpFxHeyAWDQYQQEuXm5n7W0tIy\x74qurK8rpdLIREREtKpXKJxKJEMdxmGEYWV9fn8Futwvz8/M7br755pr3338/deBn\x56VZWEpcuXYILFy6QA+L/GGOMoqOj3RRF+UtLS6PnzZvXdODAgbhVq1ZNDG2K8YQJ\x45zrGjBlz4uuvv875y1/+EtfY2JhmsVioUPMKGbL8HMYY0zQNgwYNaunp6VHcfffd\x687dv335rTU2N8IYbbvh20KBB6e++++7sQCBAXavh5moukcViAYvFctk41NTUoNBK\x45BAKhUGhUEhbLBZRIBCwsiw7SCwW71ar1UxycnI7RVFlTqcz12w27xAKhd8qFApR\x530tL7HXXXXdk27ZtWQ6Ho2Xw4MGBwYMHb/r2229r0tPTRWKxuJVhmH6EkIDjuIBE\x49nncYDCsCwQCyGq1pkil0i/ff//9RZGRkcedTmcLQoiMjo52ezyetSKRSNbR0XFd\x61mrqNoPBEFddXQ06na7zxRdfrEMIBVeuXDlwYwpKpdIjl8v3bt261SgUCiOqq6vP\x66fLJJ5e2bNminDNnzmVh37hxo6ixsZE8c+aMIDs7m0EIwYIFC4ILFiyAnTt3snfd\x64Zcj9DygqKhoZEtLS8vMmTMDAOD8QQy4TLvdDkajse6jjz5anZOTc81KZnS1/spR\x6f0bFL1u27C+9vb2jMcYMSZLU008/vS0vL8/OcZywqKhorNlsjhQIBJb29nZ9aPM3\x63JnHV9Z/D8wMhkwfEfLBQSQS2eVyOXAcxwQCAZ9UKlU2NzfLEEI4Li4OCYVCF8dx\x41Zqmobe3V93b24uMRqNzzZo1+x0Oh6iwsHC61Wr9u91dVyM7O9thMBj8O3fu1MbH\x78zMymYw0m83AcRxhs9kgPJnhiiwy5jgOKZVKuP7661e3tLQMEQqFIplMRnIcJx41\x61tRHn3/++TMEQUjdbredoii/WCwOUhTVr1QqE2maFvv9fv+RI0fi4uPjWZ1ORxoM\x42nC5XEDTNNA0DQghaGlpgdTUVIiMjHRJJJKG7u5uIjY29gO73f6gz+c7LxKJhgqF\x77ovJyclvsiw7+vjx42nt7e1ZeXl5G8ePH7+pq6tL+OCDD5oHFh6GMuSShQsXusKC\x5ajabo91ut7Snp+etwYMHv3T8+PE4n8+nHjJkSI9cLqcjIyNLa2tr50ml0gqVSnXE\x61DR22O129cMPP9zz4IMPpvn9/hVjxox5vLu7O6OoqGhvqNZLIZFI8Pnz55URERFm\x6cmXV77zzTl9WVtY6r9e7rKGhwfzmm2+aJBKJp729vT8qKors7OzU+Xy+xMTExLMO\x68wMtXrzYXVhYSBUVFf3NLNUB0TYEAHjLli10cXExW1xcDKERNm0cx8mHDx+ec/To\x30Qt/r6Px8gqwZMmSeJfLlaXVarcLhcK+UJUdCQA4VOOScPHiRfz5558nVVVVyUP+\x74H5ArPdvYtBXCuMVFo9LSUm5MH78+HlRUVHyiIgIym63J9TW1kZfuHBhnN1uz7Na\x72aLe3l5Oo9Fw0dHR3kAgAG63W2owGGDRokX7KIqyYIzVCxcu3LVp06axzc3N8nD8\x50WT10ZU9vOESZgCAsrIyxYCGc6BpGgQCAREqyuLCWc1Qcihc9owSEhJOzZkzZ8PZ\x732cLmpubxwIA6fF4gidOnLhlz549cX6/n5g8efKGRYsWHSNJ0tHa2joyPz+/vLy8\x33NTZ2TnS4/GMTE5OVvX29so9Hg+kp6cDwzDg9XpBoVAAxhhYlsXx8fGOiIiIFoZh\x7ak6dOnVnWVlZFsZ4g1qthu7ubktMTExHW1ubbNCgQe9IJJKROp1OlZqautvlcnGt\x72a2uLVu2kNXV1aioqIg5ePBgeBVzYYzR8uXL0c6dO4NGo7F97dq1wYcffvhhl8vl\x37Orq0mdmZg632+1ijPF6lmWJ1atXPwsA3MqVKwdxHGcMBoNo6dKliatXr67905/+\x39KjdbvcxDFMbFliKotQejwdlZWVZfv/73wfWr18/ctasWV6GYRwNDQ1mACCefPLJ\x6ak2bNkkUCoVw/vz5vg0bNpg7OztdCxYs8AwomGSuNTggLFKFhYXEnDlzwtadTU5O\x66hcAlJMmTZq1ffv2C1eGPa+5Ajz22GOzBALBBYvF0rpy5UrhqFGjPu3s7JwWjgDF\x78sb629rahAOFWiAQhIXLS1EUkkgkAo7jHP39/c0KhUIsk8lkAoHADAB2l8vVrVQq\x6b4LBYL1Wq02vqKgYkZGR0fvCCy/MPXv2rF4sFtvGjRvn9fv9MRzH6RoaGnI++uij\x4706cOKEZeJ4CgYCdOnVqV0JCQv3o0aOrAEDq8XgEv//97+/o7+8XDYx1h7vDrlnt\x525KXk0EDjsNXDgwIl0bQNM1GRkY2AwA0Nzdfl5OTs6asrOyOUBTHtmzZsvcQQjg/\x50/9cf38/0d3dLWFZtiMQCOg7Ojryhw4duiMYDOZbrdbxCKH43t5e3fbt20UMw6Bw\x56AwhBP39/ZCRkcFOmzbNGhUVdaKzszPgcDiOWq3W65OTk9/p7+8fq1ar27xe7zmX\x79zU6Li5uXSAQSFm2bFnFP1OjtX79+sjPPvssLzY2dprJZNovEoksnZ2dmpiYmGMU\x52SWJxeIuAPA/8cQTXWvWrJFxHEf19/ff2t/f/+mGDRs8Ycv8+OOPpwsEgozXX3+9\x2bL777osRCoURZWVli1iWXTN27Fjk9XofiomJ+YLjuNMRERECq9UaHDj28mf2GP/N\x35IqkpKR3g8HgjQqF4oaqqqq6n5OovbwCvPvuu9+FNC/r5MmThEAgcA+MXFgsFuEd\x649wRFIlEhFAodEokkk6O4ziapqsoiqr1eDynTCZTG03Thq6uruGrVq1666uvvkqq\x71KhIGDRokN1gMDiuv/76hi+++CK7v79/wtGjR0tVKpXp1KlTeStWrNi4e/fucYcP\x4815oMBgqampqrtPr9fTDDz9slUql8v3799MCgSDc8ogOHDhguu2223okEklEZWWl\x63t26ddd7PB4RSZIsy7LEyJEj+6dNm9bz3nvvpfT39xOzZs1ySiQSxLKsJBgMcn19\x66ZTZbIbKykr094xCOP3PcRyhUCh8IpEIT58+/bsvv/zy8TvuuOO5zs7O7ND0Buz3\x2b1WHDh26OzU11bl3715RTEyMUyAQ2NVqdZDjuPb6+vrk8vLyxyUSiZ/jOLFEImEt\x46guh0+ng4MGDf3MSQqEQOI7DTqdTZ7PZjtvtdhg5cuTSYDCokkql73R1dcV7vV5l\x622/vnrVr1/rffvvtxoKCAlqr1Urffffd/p8oh7iqPViwYEGXUqlsBoBvNRrNBZqm\x48SqVKsiy7Fi3263u6+vrevXVV9s7Ojpuzc/P33fu3Dm7y+U6SJKksLCwMPDhhx/K\x41KCfoqhUjPG5nTt3CtevX5/d3d2dm5yc/Pnnn39em5aWNl6r1X46atSouhtuuIHD\x47AdCvvzViibp4uLiQPg6QqsCDBB6NlTNex3GeHEgEGi57bbbBr/xxhvekOX/ySqF\x79wrw9ttvy8xmc6Crq6tWLBYXaDSaIa2treHIBfh8PiwUCtHYsWNZj8cjtNvtSpPJ\x56G8wGOpOnz49XC6Xly9evLjm9ddft40aNcpZXFzMzZkzp/7BBx/8QzAY/Oz8+fOu\x6f0eP3siy7JLe3t7G7OzscolEUnnjjTceX7Ro0TOBQCD2+uuvr8MYRyQmJnIcxxn6\x2b/v1s2bNovr7++HMmTOIJElgGAZxHAdHjx5NqqmpyWppaRGkpqZeQgiZOjs7BQAA\x59rGYM5lMAb/fz8jlcjomJoaOi4sLBgIB5PP5SIZh4Ntvv8UjR44EoVDIkSRpJQjC\x52lGUjyRJt9Pp1FRUVCS43W4KAFBGRsbFp5566r2Ghgbl9u3bn3G73ex33333cCAQ\x43LsriGVZ7vz583HTpk1bk5SU1LR79+6R7e3tKQBgEAgELoqikFgs7iUIQtHV1aXW\x36XRUa2urkGGYyyW+4Y0vy7KgVqsZg8HgczgcBMa4T6PRnEpISDDPnDmzcvXq1bFS\x71TSaoijX22+/XYcQwgsXLnQVFhZSTqdTBgD9oXGJv0QBcMi9wyUlJWfvvfde/OCD\x44/Y988wzozmO27Nq1Spu2bJl4zDGTXPmzNn18ssvh0ttG8ITJcKhcIVCsQ0AuOnT\x708OMGTO+BYBvT506BQCAJkyYcGLBggXBtWvXwptvvin88MMPxWq1mg1tYK80QrqJ\x45yc+aLVaPx4+fHhXeNRkQUGBrL293eTz+WYEAoFRAGCRSqXLS0tLT77xxhvwS9p3\x4cyuA1+vVqFQqCQA0jhkzpmL37t3+gRvblJQU9N1331HV1dXckCFDkEKhEGo0Gqa2\x74jZeKBSW33XXXTXLli2j77nnHsX69evvfuyxx+TFxcX+ysrKg0ajUep2u4VtbW3g\x63DiOsSw76tKlSy6/39909OjRV3fs2HGd1+sFi8VSRRCEyGq1qhUKhUgsFlNKpRLd\x64NNN4HQ6ob6+/rJr09raquro6Aj+5je/qerq6ooRi8XN8+fP7+7t7Y3Ys2dPxqhR\x6fzpomga32w16vd7d0dGhpGkaqdVq+PLLLyEiIoKdO3cuyXGcTS6X14nF4iaCICwR\x45RF9FotFOW/evKeEQiGaNm3aqfvvv3+/QCBQfPnll6Oqq6ul4T0MxhiLRKKgTCbj\x62DabePLkyUc6OzsTNmzYcL9Wq9Xq9fraYDAopijKbzabe6xWq+zmm2829/X1yR0O\x42zdkyBC2t7cXLly4QIaqMoEgCEhPTweVSoX8fr9XIBBcsNlsY2Qy2a6Ojg7H0qVL\x704nF4uMulws8Hk8wVCyGQlaUAYC2119/Ha7hMuCfqJzEEyZMQCaTSfbAAw9cevDB\x425FAIJCpVCrZ/PnzMU3Tp0P+t/fKqR7FxcXQ0NBgKiwsdJw7d078yCOPBJYvX84+\x2ffTTY8Visc3lcsU2NTUdXrBggTO8V+jr68tRKBRls2bN8l+lTgkVFxd35Ofn76Rp\x2bs62tjbJkCFDPFKpVGSxWORut9sjEAguURT1+4qKiuYBU064XzLCBw24kCFFRUVV\x43xcuTNBqtbfs378/59ixY3cBAIsxJvV6PRAEAd3d3SASibBUKgWGYRDLskDTNEtR\x31AWxWMy43W5Df3+/Xq/Xe5xOZy9CiKBpWocQEjudTk8wGGRomlaELR/DMOGcweXz\x47T58uHvKlCngcrloi8VCURQFGo0GvvnmG9Te3n45AUWSJJbJZOzw4cOr77333lq/\x33y9Vq9X9jz/++B1ZWVlukiSDe/fu1T/11FP2mJgYEUKIKi8vJw8cOIAWLlwICCEf\x54dMXRCJREwD0KhSKXpIk8dKlSx9gGEZxzz33VA0fPrzT5/NR77333uhTp07pWZbF\x6fTocJBAIYNiwYY0IoZ6ysrL8QYMG9V24cEE7ZMiQriVLlryKMSZOnjypxRhHxcfH\x4eyOE9GfOnIlGCE3PzMzs6OzsjHY6nai7u5vYs2fP5b3L/fffD1lZWcGurq52hUKx\x648GCBSsiIiJ6N2zYwLlcLurkyZOB4uJiNtxZd8W0t4GCjgoLC1FXVxd5tYbwq3Xp\x7aZs3b4zH4+ksLi6+FAqOxHo8Hq/f7+/fsGEDcy0lKiwspDiOy+vp6Sm12Wwo5LrA\x30qVLs7OysrpKS0vvCgQC306cOPFSdXU1/gmf/284ePAgtWHDBhVFUXjTpk3WK2YV\x2fUODcX+kAC+++OLYpKSkpnPnzt2hVCrbt23bVnjq1Kn0UIkwkZWVxU6cOJGjfhiw\x348YY261Wq2Xr1q0JVqtVfsXnBq+oMb9WNeLlDWc4xCgUCnFubi4zZcoUQAgJOjs7\x6bVqtxj09PSCXy5l169ZRXq8XEQSBOY5Der3e9cYbb+w7d+5cit1uV3Mch7xer/jL\x4c79UGo1Gb2trq8RkMgXj4+MhGAwKmpqaYO7cua6UlBQuGAz2yGSyGpIk21UqVXd1\x64bXmq6++ul2v1zvvuOOONpqmI9rb2xWbNm2Kqq2tlYWjRxzHIaPRaB85cmRvc3Nz\x66EdHB2W1WoEkSTR+/HhITk7+bu7cuRvPnDkzwWKx6P1+v76pqWmy0WhstVqteNiw\x59V0OhyPF5XJFtLa2koFAAPbu3Quh+UAwfPhwnJeXx6jVao/RaNyq0WjeOHToUP3R\x6f0eZmpoaBgCI7OxsVFZWhrOzs1EoosUN8J1h4IiTxx9/fFJnZ6fgq6++2hsW9Gsp\x77NKlS6/3eDyX1q5de/Gf7f4rLCwc0tXVVV9WVgZlZWXBgcI8adIk9mf2mA8sNfnR\x6euXXGI8+MBHWtn379lStVmvo7++XBQKBGoTQ5Z5LrVYbUCqVrEAg8AoEAk6r1TbF\x78cWdNplMSevWrZuu0+naLRZLpFqtbmxqahrCMAy+ok8T4b+GkBBcZQIax3GIpmlO\x709Phvr4+MJlMWK/XI5IkUWZmZnDnzp1BhJCAJMnLPvPkyZN7WlpahgBAZEREhMfv\x39xNpaWk9fX197MWLFyOGDRvWX15ernK5XFx0dLQvJyfHHxsby3Ac1yGRSC6JRKL2\x69xcvKhsbGxMsFot42rRpR4cNG0Z6PJ6U8vJy3UcffWTo6+sjQ1WjGGNMZGZmdi5a\x74Givz+ezL1++fKHVasUAQOTm5lqys7OrKYpK/Pbbb+8jCEKsVCpdNptNFRkZeUah\x55FiHDx/u6O7uHtLU1KQTiUQcy7LgcDguBxsIgoCenh44c+aMYPjw4faEhARXdnY2\x6ejt3rhghZAnfqrKyMggJ/tUajgBjTFx33XU6j8eTWVVVNVGpVO74e8nK5cuX46Ki\x49jCZTPV+v985oKT4ZyvBVVaiZpIkjdnZ2ZZRo0YlSCSS5JdffnnPVcarwE80Zl1p\x73DEAsOH3BPwzXFYAl8s1AiH0sMFg2BAIBMZLJJKhAxsOHA6H3+fzsRzHSVUqldnt\x64hMXL15EOp1uD8Z4elZW1tZjx449cfPNNy/585///BubzXZnKJZO/Jzao7BAO51O\x38quvviLvuOOOvvT0dCwSiSgA8G/dujWirKyMjomJwWazGdlsNqRWq9mpU6eePnv2\x37HC73Q7jx4/vqqioSOrq6oqaOnWqJT09HSUkJPRs3rxZUVVVhRITE30FBQUNLpcL\x65zweAcuyBolEcjg9Pb3NaDQKkpKSaKfTmejz+bJLSkpUX3zxRZTP54NQDy+iaRpl\x5aWW558+ff9Jut1OvvfbaPb29vWSoBAMbjUa/QqHwlZSUJHMclzlq1KiTTU1N8bGx\x73eedTmey3W5XNjQ06EmSlCKEOLPZTGg0mh+FajmOA4/Hg1pbW3FjY2PsF198MV8s\x46o9Vq9WUQqE4AwAMy7JehUKBZTIZyGQyoGnaEwgELAgh1u/3I5Ik8YQJE+hgMBgg\x43KLL4/G8dfDgwR4AQNdyPcKCu3DhwparxNt/bvfVwONxUVGRCwBcAACLFy/ukkgk\x33D8ptL/6hMLLCpCcnFxCkmTbs88+W/Xqq6+qWZa9baBg2mw2ldfrtURGRvaxLOsD\x41K9er3e8/vrr2VKp1NHX18cwDGMdMmSI2+/3q6/h6lxtM0b8TSgCIdTd3e1qb29n\x571tbtceOHVN4PB5/Wlpaf3NzszolJcV98uRJw6BBgxoFAoEwKioqoFQq/W1tbVqR\x53OQwGAyulpYWPUKov66uThobG4tTUlIchw4dEjY1NaVlZmb2SKVSo81ms02aNIlL\x54k5ul0gktNlsThCLxYLNmzcP3rlzZ1xoQhxiGAaJRCK4++67+6+//vrKQ4cORX3+\x2beejbDYbDKguJVpbWzmj0WgyGAzdY8aM+bPdbk/s7++/ta2tLZ8kSYHf7ycYhgGJ\x52KJNSEjwUhRFSCQSgdPp/FHTh9VqBfhhVCInFotJq9WayTBMjUqlYjUaTV9PT0+Z\x58C73ajQa0Gq1IBQK7eXl5W19fX2MSCSC7OxsEIvF3WE//Odugn/hcb9o/M0rr7zi\x76CLS8x/BZQW4dOlSSkRERNJvf/tb7/jx45ulUqlrYBaVpmlu8ODBHQKBgGMYRqRS\x71S4dP348p6qq6nq1Wk2dPn36mZiYmFOLFy9e5/V6B4f9tFCy7PLc/lCkI9wzCsEf\x78jQIrizGO3ToUPyxY8cgGAyCWCyGyMhIb2lpqcloNHrq6urkCCGs0+kk7e3tEoVC\x30WE2m+VisVhms9lIqVSKaJpm3W53hFQqDUokkrb09HRrfn6+77PPPsvt7e11mEym\x75pSUlMOZmZkHOjo63Gq1WjRo0CDxokWLlhw/fjyRIAiMEEIMw8CQIUOCkyZNYqOi\x6fno++uijhN27d5tCFa841M5IqNVqb1ZW1sGoqCi3z+eL/uabb2aYzWZ7VFRUe0RE\x68Hb69Ol/JAhCYrVaM6uqqjJlMlmK2+0WyWQy1N/f/6NMNQBAenp6IDo6mqMoqjcu\x4cm7Fe++9twEAIBSa/rts3779snEpKChAv9BP/rWtLL6Gi/SfpQAYY3F3d7fO6/Xe\x4cRKJvnO73bsRQuncD+sz2dLSQqxevTqLJEkGY8wGg8EYi8UiDQQC4HQ6ASGEa2tr\x380LLOYcQQjRNo5ycnOWRkZG1tbW1fWq12hgZGSn3er0cQRBGgUDgaGlp+WNZWZlm\x59AteuLkkGAwigiDA5/NBU1OTGACgra1NGu7kMhqN+6Oioqx+vz8hJibGLBQKuwEg\x67iAIHBkZaXe5XKRIJPIAgNZut9PBYNAxY8aMoxhjq8vl0qWmpp7u7e0lBQKBf/r0\x36b2JiYlrL126NBghxHIcR5AkCVOnTuVGjx7NabVad3d3t/jw4cPRYeEPXScZFxfn\x48T9+/LF777135yeffDLz7NmzeXK5/HRGRkZPdHQ0gxDaGggELqrVasrr9apHjx7N\x31tXV6ePj41UEQQhJkvxR035cXBxOSkqi1Gp1x5gxY3aMGDGiJiUlRbVo0SLnhAkT\x4cr+DuKCgIKws+CoxfwwA3K/hJ/9qS8F/mPD/SAF6enpuMxqNm1Qq1dBbbrnlVF5e\x33tBQZw0HAGRERES/VqttKi8vHxH6PSH8dTxFuEmZC1VKkgghzDAM7u7uvv6FF174\x5asqUKeeXLl06LzIy8ghBECTGWDV+/PjAPffc8xeE0DOhrB0Zbi0MN1wPrOcZkJfg\x4dMaEy+XymEym1rKyMo1EIrlgt9tjRCKRH2PcHRkZedFms0ULhcJatVpNOZ1OpdPp\x6aI+IiAjY7XarVqs9a7FYFAihvnvvvdeVlJS00+FwjImIiLA7HA65RCJBM2bM8I4a\x4eQq5XC7SbDbTJ0+exIFAgCNJMjy7hszKyio9fPjwbwsLC5c/++yz66RS6adz5879\x37eOPP37y2LFjxt27d1/PsuwlAOjmOE4nEAhSMMYXnU6nVCQSCWw22+We2LC7abfb\x55UREhCc1NTVYW1s7rLe3V+Z2u9cDwLGJEycSJSUl3H+iNf1v5LLvKRKJKgmCCLIs\x5744xJhMTE3UhCxfuGQ1u2LDhz4sWLfp08ODB3aGs3+VajFChGAEAP8wh5zhOIpEQ\x65r3+1SlTppwvKCgQr169+qOSkpKksrKyW7u7uxMYhqnr6Og4FBJ6Afx1Vj4eUO3H\x68nIRbCh6EH5FKXP48OHbbDZbY0xMzGGGYawMwxBisfhMVFRUk8ViGa7RaHZLpdJu\x7698fxXEc5Xa7uYqKisTe3l6pw+GoycrKquzr6xs2a9asEpqmd1VWVhpvv/329wmC\x49ObOnXvuhhtucDQ3N6ONGzeSf/rTn+Tff/+9lmEYgmVZpFAofMOGDTs8d+7ct5Ys\x57fL05s2bp9fX13O33XZbOcuyMW+++eYQt9vdYzKZNt5yyy37hEJhjN1uT5LJZJ/6\x66D4uNzd3u0gk6nK73axQKPxR9axcLofMzEzWbrfLaZo2p6WlfUHT9CUAQKGXcBO8\x38P86XO7Gnzt3bmdfX99EjLGtvr4etbS05NbU1IznOI4UCASEVqslpkyZ8rZYLLbn\x35ua6RSLRfovFEuP3+9Wh8KVXJpP1BQKBC0KhMIqiKEIoFJZNmTJl/ZkzZyw1NTXM\x6biVLlHl5ee3Tp08vOXLkyPDu7u6u06dPv4QQSpLJZKUYY4tWq5X7/X469JlYLBaH\x5a7kQoQdPhBSNcLlcsv3799/qdrvbJBKJkKZp15gxY75kWdYvEAj63G53dTAYdJEk\x32WK1WkVerzfY2dnZJJPJdAKBwMRxXP8333wzG2O847e//e2WCRMmdObn54vEYnHu\x35MmTPdXV1YaPP/5Y2tnZiQKBAJAkyXEcRyQmJrYsWrRo0xtvvLH55Zdfztu7d+98\x719UKarU6oFKpMiiK2mcwGKRVVVVPSKXSqlDVam9/f3+nQCAY0tbWlokx1olEIqFO\x704vyeDzozJkzlyNkNE3j/Px8VyAQiJDJZFvMZjPb1dVVd+bMGXdNTQ0GAPz444+b\x53ktLnbwI/3oukIeiKAdBEHk9PT0JAFAhEolQcnLyjpiYmN2ZmZnE6dOnJR6Pxw4A\x42z788MMznZ2dr992220PNDU1PavT6fY0NjbeHiqbuJOiKPnZs2fff++995DBYBBZ\x72dYRLMuihx9++PiWLVsEJpNpf1RUVK9SqayPjIw8WFVVtRoA4IUXXkhaunTpWQDY\x4f3r06OeFQuGQxsZGrqWlBZtMphiSJJNdLlcqQRAigiC4/v5+zdGjRx+qq6tjaJo+\x66fDgwZsTEhLienp6tnEcl+hwOPq0Wi0rk8nyrFZramJi4pbo6OgSm81Gbt68OYOm\x36fr58+d/d+LEiTvee++97RqNxn3vvfduWLt27bNffPGFMhAIYIqiUKihhhg3bpz9\x647/73Rcymaxx5syZz5eVlWUzDBNECJF+v19iMpmeSUtL67NYLH00TXdZrVaVSqUi\x35XK52maziTs6OrQpKSlfI4SuJwiC6ujoYC0Wi2DglAev1wtWq9WhUCg6SZKUqtXq\x78P7+/kGjRo0SKJXKQR6PJ7W9vV1fWFi4oqio6N/2/rb/aQVgWTYhNzf3m7Nnz0pX\x7215te/zxx01KpRKSkpLKvvzyy+Lly5c/3NjYOPbGG29cM3v27P6MjAyypqYmAACr\x62rnllq8aGxtfGjFiRCFC6E9lZWWfhz8fIcQVFhZywWBQGRERsQ8A8Jw5cwIAEK7f\x65GJguGzBggWN6enpqdddd53trbfe8gNAbfgc7Xb7VS+is7NT98Ybb8Ts2bMHi0Si\x42LvdbvT7/aPa2tqOIoQoqVQaKRKJ/CkpKR8kJyfXLly4cMvtt99+P0EQa//4xz/q\x44h06FHjrrbde/+CDDxRTpkwRPPDAAyO+/fZbZThiFW6MGT9+vGfatGmt7e3thldf\x66fWGtra2oaF3dwk4jmMxxqTZbE612+15CQkJX7744ov7XnrppVE9PT3cAw880BwM\x42kdcuHBBZLfbtXq9vslqtaa5XC5vKLt+ea8TCATQV199ZcQY+1iWvVMgENRGRkbe\x51hDEbgBo4ziu7Jtvvln/zTffoFDR27/zlUT/U1xedhcvXjyOpulWmUzmWLZsmW3T\x70k3ShQsX9qalpT374IMPflVdXT05MTFxV0NDA7z11lsDO40uV95lZ2fPA4AxYrG4\x48CH0zZEjR7p+RtbwR6nuKzZ3REFBAert7UVXjFi5bPGeffbZLL1e76Zpmnj00Ufb\x45EKea/w94sSJE8LKysqo+Ph47uWXXy6Ki4v78je/+c1Os9ksqK6u1hUUFND333//\x48W1tbS8lJSU5W1tbqba2NrFGo+EsFgtx22239UdHR/d88sknRqvVqhzwyiUAAEzT\x4eHfTTTc9l5KSgj0eTxtN00RUVNTZ3/3ud/UrVqy4obe3V+Tz+ZKHDRt2zuVy5bjd\x37jlisTiio6PD9Pbbb4f3P5dn/tA0zaSmpl4ymUybMzIyvnnllVfOI4S4lStXajo6\x4fuCdd96x8CL8K60AFEXRK1asuJwFvPfee90mkylAkmTA6/WaPR6P7OTJk3jz5s19\x41wdAwV8HEUFZWdlHU6dO/dLhcBQwDLN0ypQpboqienft2vXmxIkTyYEjKQYIOXeV\x55FlYMa8VxkOhWhNpIBBIRgiV9PT02ACAXbly5ej6+vpzzc3NjF6vJ3p7e7mSkhIO\x49cQ99thjpEwmm75t2zZrIBBQ/uUvf9makZERvXXr1p6nn3667/e///3Snp6eRx58\x38MFdBEGkvvnmm5HXXXedV6VSoa+++kpUU1ND7t27NzUU9h0o/AAAXDAYJDs6OiYv\x58rz4wY0bN45kWZbu7+9XfvbZZxE2m81I07SoqamJ7uvre3jUqFFujuM6NBoN293d\x72UAIqcLhX47jICkpyTpu3Dg0fPjwN0Qikbyzs7MKIQQFBQVke3v7DJqmjwGApbCw\x4dCUQCNhWrVplhn/vy+n+t6JAq1atOjBgRB4BABAIBC40NDTQTz75pN/j8XySkpJi\x68dDo6avUa3AFBQXkvn373KdOnfqwrKzsSYVCsVGv1xcjhHBJSckveb3ST02UwOFU\x2b6pVq77s6urili9fzi5atOhmhULRGR8fH7jrrrtQcXFxsKSkhMEY44MHD1Jut5vp\x37Ozc4XA4RisUio8xxgRN075Dhw5xH3/8cVJVVdXY+++//54JEyZ87/F4Lg0ePFg8\x63uRIgdVqRQAAtbW18nDO4wrhBwBAAoGAI0kSXnnllfTrrrtu31tvvVU8bty4S3a7\x6eXjttdc2GgwGRSAQuFelUnX6/f5TTqdTy3Gck6Io2xUjD1Fubm5PSkrK9ydPnkzZ\x7429fd1FREVNYWAhTpkwhUlNTv/vTn/7UFDq2n6Zp77+qVOD/jAt0lZWBiY6O3uz1\x65mutVusL8Mtelfp3+zB/TQoLCym/3y9ftWpV/zPPPCN57bXX3D+Vlp8yZUphdXX1\x4b0888YRRLpf3WiyWjGPHjn3tdDpnHj9+vOWVV15ZCwBDuru7TT09PapAIMAUFxcL\x77xWo11JKgiBwTExMbWRk5EWhUGjVaDTVer2+c/jw4cePHDlyd1lZ2UKKot6prKxc\x2bcorr9xPkmSOQCBIrK+vT1y3bl0SwzBk+G/MmDHDMm/evI+PHDnS5Xa7EwoKCp6f\x50n16365du+gZM2b4f8Gz5ZXiH1WA+Pj4JQKBYNTFixdnww/lCsF/8PP/7Q/hGoki\x41mMMkyZNeiQyMvJ7iqLMH3/8sWXcuHF3BAKBMadOnXpi27Zt0dXV1Y9TFDU+EAio\x4bIrSb9q0SVNVVfWT8zgJguAyMzNbgsEgFQwGu4VCoZggiNSenh4yGAwSer1+eV1d\x58dEDDzwgHzJkyMj4+Pj4S5cuzWppacl477334oLBIBXuP546der5O++8swVj/JlY\x4cC4LBAJkc3OzVSAQkAKBIFIikbQ8/vjj1vnz51P19fVYr9fj4uJi+DVKhP9P7gGu\x34mKAQqEo7+vrmxgOFP0jcvhvVGR8lb3E35wPQgiGDh36WUpKSqpGowEAsHg8nhyx\x57LwOAAiO45iUlJQKp9Op6e7uHiOTyaxJSUm4pqYmItyzMGAwwI/KvTmOg/r6+niD\x77RD0+XwxPT09gBAKqlQqh8lkeq+ysrKosLAwymQysWfPnh3Z19enN5lM3TRNRwFA\x77sATtVqt5IgRI3bs27ePSEpKEg4dOvRCTU3Nk4MGDfpy/vz5Z8PHXdnoEt4zTZ48\x32aDT6WbK5fI9H3zwQTu/P/hlCsCFFKDU7XZL33zzTeGTTz7p/w++ib+k0AtVVFT0\x35+XltdrtdsO8efNETU1NhsOHD9cihHBERESgq6sLY4y9EomkFyEUGxMT4w8P4P2R\x6e/fDtLnwqJVwfzC0tra6aZquy8nJ6U5LS9s/bdq0jefOnVNef/312UVFRWXr169P\x49kmyr62trVOtVo8OTcQL31sCAHBPT0/SO++8cwdCCKtUqrWtra2al19++S+PPfZY\x64EFBwVi9Xq+y2WyGysrK8vj4+JT29nbO4/EwJpPJ4PV6pQzDBPr6+iq6u7u7eeH/\x781YA8ujRo7ZBgwa1ffjhh6kAcP5/5EZiAEAbNmzoAoCuadOm6ZxOZ+fEiRNJAGBJ\x6bvQJBAI3QRD9ACB0uVyeyMjIvpkzZ5odDoeAYZgml8vVQpIk4ff7mzQaTYROp5NR\x46GVubGwcLBQK+4xGYyXGuFsul5sNBkPU3Xff3QcAfa+88ooUAMDn87U/+OCDXyGE\x36JMnT8Y4nc5EkiTDw6sAAJDb7RZt27Ztkt1u57755puxJEl6MMZCjLGYoigQi8Xd\x48Me1SiSSlt7e3gahUFhPUVQPx3EHoqOjzcXFxVZevP9xBbjsv8vl8tPBYHAEAJwP\x6cdb+L1w3hlC/LABYKioqLmg0mviSkpKGPXv2sIMHD+7HGHtomj7f0tIynqZpwufz\x30SzLUhaLReR0OlNZltW6XK4Ei8ViunjxosbpdBIikYgEgEBnZ+ejHMfVA0CDXC7v\x7a8nJGed0Ojc888wzFxYvXkyMGTOGq6ysDFZWVrKJiYmdAoHgPELohoEnaLPZwisx\x38vl8tEAgIAwGw16FQnE0LS3NZ7PZthw4cKA7PCLwaluSwsJC+KW9tzxXKMDw4cPj\x68g0btv7KsOn/8jVjjJWnTp2auXfv3udfffXVD5OTk1sHhGb/5ksqlVpGjRp19oYb\x62nhyxowZxqeeemowxlgc/tD8/PyonJycV9PT02VXBh4wxroVK1b8RSKRhMurcWiv\x67imKYvV6PR48ePD3999//x+vJegTJkygCgoKyIKCAhKu0mrK88ujQADw17c5Dhs2\x62B1FUevPnDlTHvqd/ymrkp2dLQg3bQ8bNuxehmEGxcTEiFwu16iKioohDodDFWqQ\x43bVHhFtlgRAIBKBWqy9t3LjxpsbGRuPChQsPbNmyhaytrc13Op3Mq6++euLNN9/U\x31dTUqOrq6i6FkoHozJkz1LZt25QajWZsX1/fuDfeeOMpp9M58B1cnMlkIrKyss7t\x32LHj5q1btwaPHz+eo1arLQ6HY5jX6932xhtvdPKhzn+Ov/u2vVDpLdbpdJ0Y4/t7\x65np2FRQUEKGKxP8ZI9DV1cWuWLHC0NDQsLmpqWlJX1/f+AsXLuS3trbGkiQp0ul0\x62CAQ4ILBIAWhCRYYY1AqlS1paWlFGOMLa9eu3ZKXlxc7btw4Y09Pjwgh5He5XDWj\x52o2K9vv9vjfffLOjpaXlsuFYv349Pn/+PFtfX/8wxlh/9uzZLL/fP7AJHanV6rYF\x43xZ84vF4Ko8dO+aQSCS9JEm63G43LZPJ6ktKSoK8CP8LV4ABSsLm5uauFQgEXx87\x64uxQeGX4H7h+orCwkNi6dWt0Q0PDoWAwGC+VSk9hjI8YjcapDodDo9PpDBKJpEEo\x46J6orKwcbTab0wCAValUZH5+/sydO3fuOHXqlPHo0aOB6urqRJqmxevWrTsCAPD+\x2b+9HnD9/fhwA+CMiItoBIFBUVHRxwBsYAWOseP311+954YUX3rHb7eFhvCwAkLNm\x7adq4Zs2aTz7++GON0WisEIlE5MMPP1zLi+2vKAA/4xgOAAiKolb7fL7H5s2bJyou\x4csZwjdEm/2UBAK64uPjB+vr6BoqiIDs7+zaLxTLKarUufvnll+d+++23wxUKxXy7\x33e71er0T1Wp1gCAIjiAIwmAw7CooKCibOnWqNC8vr4dlWVNmZqbpvffeO1pYWEit\x5879eYLfbibVr1+6Iioo6BQBNGRkZjQCAly9fPvC+sQMGg102TAgh0Ov19EcffXRb\x520dH5qRJk/pomu4FABTy9Xn+3a5Sbm7urLS0tFfD+4P/8pWP2Lp1q0Sn03XodLrP\x79svLwy+GRtnZ2QIAgKeffjrOZrOppk+fPnPUqFGXhg4d+rlUKr0okUjwtGnThgMA\x54JgwgQpXcS5ZsiS+sLBQMsDNEaxdu3bwqlWr1N98843queeey582bZrwik2w+PXX\x585+vVqsHboIZhBC+/fbb3/z+++9vXLt2bS7GmOLF8P/PCgAQGpFeWlr6ndfrrRg2\x62Nia4uJiFmNMLF26VP0L3Kn/pOvmnnjiiU0SieSg2Wy+a9iwYe7QqoDLysqChYWF\x78GuvvdYyZswYz65du7YHg8HvtVptPsMwWoxx665du84DACopKWHC7syaNWuaASBx\x795Yt4kcfffSmjRs3UkeOHLmIMSZaWlqEHo+HkcvlzLJly3T33HOPNHQeDMbYd+U7\x44DDG4PV6YxMSEjwmk8m5bds2mhfX/38KAADAFhQUkM3NzR9zHHd26NChKydPnryg\x70KQk978sREoCAJuamppPUVTKoUOHHoIfxuz9aJx2OH6u0+m4kEuyr7y8PIZhGAVC\x53Ddr1qyHQ0krEuCH0YJbtmwhXS7XpZBb03HDDTewBQUFkJyc3P+73/2u54033ijt\x37e1FJ0+efOWZZ56BkMUPisXinvCb2geeqNvtVnIcxzAMQ8nlcoIX13+NH/yzKS4u\x5akMb4C8mTZp0UigUZmi12mMDVon/Hp+OJB/U6XT3JyQk+ACACBWQ/Q2hESTYbrdf\x339/fj1mWZT0ej7isrOyF0EvcdhYUFJChV/kAALgBAGbPnt0eCASmA8A+APBhjNHE\x69RPJQ4cOsXl5ed/PnTv3hSlTpnyQk5Pj7+npkTI/tJ0JBoY0e3t7gxKJxM8wDB/X\x2fy9eOf7jol7XXXedJi8vb/3Pcd3Ce51p06ZNkMvlGACCYrHYlZCQcHsosfWjFwRi\x6aNGWLVvIu+++2/TAAw/kXOV+kQAASUlJf5bJZFij0XiUSqWPIAgmNOoch6Zf4ISE\x68JLe3t4Rn332WcbBgwdlvNj9hwnTgMzjf5UCxMbGJkZGRj4xUCB/apVMTU1dQJIk\x4bxQK8ciRIzf9PeUZOFP1GudAYoxprVZbA1fJLIfKG3BiYmJjU1PT0K+//jppz549\x55l7k/rMsOQ7lAv7bkmIoISHBER0dnXnXXXclwl+He11LWLktW7bQ3d3dT7AsS8TF\x78W2aMWPGM/B3xr+H2zoLCwuvdn/DQh5IT0+/w2AwfK1UKncYjcbS6OjojvCUOAAA\x6c8tF2my2AE3Tbo1GE+DFledXU/opU6bMuO222/J+whCErf/9JElirVZbXVVVRf9K\x55a8ra4KodevWTVOpVOEXPWClUtm1c+dO04C/ycPzb3WXiNWrVyuVSmWHWCwOzJw5\x63yTAD7H/X1EZyZCioVdffTVGJpNZQqsEFxEREXjhhRdSw1Em/pHw/GoUFBSQPyFU\x46ABATEzMWoqicGpq6nMDv/9rEToHIrQKEJGRkY0hBWBUKhW+8847c3gF4Pl3QwEA\x35OfnXy8UCrFOpysLzS79V276aYwxaTQa94QUICgUCnFCQkLWr7Bf4/kXbIL/Z1cG\x41GDuvffepOrq6o8RQsG8vLyHEULB0DjyX2XTH44U3XffffkHDx5UAUAAIcSqVKrG\x30CEsxhhiYmKSQ4oXVkD+mfH8ay3//PnzlVKp9AxJkjglJeXFX9nvH6hoMGnSpAdG\x6aRr1vE6nuz49PT03Ojp6TegN9l6hUIhnzpy54Ge6UTw8/xQCAIDs7GylQqGoEYvF\x4fDIy8t2DBw9S/0LXBwEAjBw5cnxqaupynU6HKYrCBEGwECqMS0pKOjN06NBvY2Nj\x761UoFN+p1eoVMGB4GS/8PL+GEFIAAFOnTs1TKpWtERERp8eNGzd+oJD+Oxg7duxv\x78GKxO7wHCCfEBn4pFIraKxXorrvuGjZq1Cgx/yh5/iGXBwAgJSXlIb1eb05KSnpu\x77M//LSXfISsuAAAYNGhQrlgstsA1+o9pmsaJiYlPHD9+XFxYWEhNnjx53KhRo942\x47AxSfn/wDy7B/+PXd7VNKwmhZNMbb7yhWrVq1TqMcW5qaurco0ePnoK/1vf8uwv8\x42AAQTEpKGtHf379MoVCkuVwuwuPxgN/vh9BbeEAkElF6vb5Mo9G0EwThdjqd6+vq\x36rqAn//Dc43NJhH6748senp6+nyNRtMfERHRl5+fLx+4F/j/yM+14uKZM2dK+CfM\x631UWLVoknjFjxj1XUQhlRkbGHSaTaZ/JZDo4ePDgRS+++GLSvyLS808qwc91v/7b\x43hJ5F+jfIUCFhYXE7t27/0gQhNXlch1RKpUpLpcrHmMcBQBBjPGO8+fPf/8z3CUe\x58gH+O33/wsJCavfu3TdTFKUjCMLn9XprMMbl4RlAIUtLFBYWcvwENZ7/S1B8xIQH\x34N8U5vv/vQnW6XRkbm5u+B27l8uN+cfPw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PD\x778PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PD\x778PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PD\x778PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw/N/mP8HhjVuZE4M\x4az8AAAAASUVORK5CYII=" },
            ["\x43rimson Halo"] = { file = "\x6eoir_cursor_v2_03_crimson_halo.png", scale = 1.45, data = "\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\x788Vdb3rL9QcOHZx6+uix44YpTE9N2auuumr3X/wLf/amhb2765uF6MZ2L3vb297x\x37snJqYOGTTt63PJl1QNkp0SIOyXEO+NmRebIO+vr8KLpu1PSOhJrrRizLc1mM76S\x76Pl97wohIoiYoSrhji1oyVplYxSJLjA/MrudwkdLxjgl62utzt63vvPtN07tmref\x2f/IDWhVjP+y65KlHHyvaE9N733z36xvvfOubwfvq1K5dU7sef+LHb7z3c595cteu\x75Ynt7fXTzA03GkmxZ9eea6TyotEPAQCkFFIOqiqYImpEVLmgpoMEEhGJIhhVMUrE\x43I0d25V6CiICAJDBd056RBVGtQwS1QBSCpg3kTsk391i2SBDjqZhocyiktnxfwD9\x42QfaqGMDIRaIIqAYRKjunK8GA/WxQaMGQF0E5WUmhYxGiMZglIRMUIOOGMUwKHAA\x484zldPfs7psG4/LkyI+HCdqEXb1lnNt77bXX3lRLCW56zeHp+dmpfasrq8Xq6uqo\x47I5nOpmh1V6AlZWV8s/97M9cs725Wv72f1g665zTKNaBUhIkOPHoIzEiVryTFkFU\x39Rd8vBQARt9v9nvFAPBSk6vxeEwigu22YFHUUbVEAEXnBIkIjREkYhIhMoaIiMha\x32qnvZaS81pi1SX7one957xuuumK//fKDT65VZVnef9/9T62eO/vwo9966EXrUjc5\x50TXz5je/+fbX3Hj91VGDLF5+xes///FPnTRsaHs0Oj7VrDdnJptXYETVnTN6HYqU\x6bZk5AiDEGLTEojBgjDcliZiyjHkk8tIiwm29yPiEqD4KKQAiDJXGqYLbAUGwqBR3\x78k+ESY243QbbJBEQvNioH9UoYI1M01WaeSPOhACeDLIFqgIgi3BFSklly0BDqYBg\x670jbIuphG5rQgLADShIRVE3ROSQgYgZmNYAUiQmFwFpmZLSIzADQbjSvEqTB8y8e\x333zP+z/4ptnZuXvKEAfL691qfeX84IGvfe3rLy698FQMcfjQN+9PV87/6G0R6MBw\x4eBwfO/7c+fe98859Z07fffPnP/3JrXbWWe9u99YYgY0xTnyogJx3ruKqimStRdUK\x797IE5xwNh0MMIdBOt7mXWrn/nzXe/eHWADvxfsEYI+Z5oKqKlGWRRIgAHKlaJAJm\x56lQlEkLine6tvjsYPKNgZt9215uue8Prb249+cLy+NOf+cxzznL1hc9+9sub588f\x52ZYuRtSlF0/6T3/y45/Zf+Dg1MFrX3NHu1Hfe+vrX/e2rdW1o1VVAbOWKmCdaj2o\x42kSrogGN8RgkaCmKagxbEgleNVPF6kKs/+WSnxC1yyxJCCaKEANgUGHesdnReoSU\x31FjFFEA5Q9PIiTOMuuOiAoCCIgNAy7q2LSG3oIaUMlApLwZELrZrDCovmQaTIlhd\x4fHtYRHAnFyEvmRYv/6x6BWVFYSIHAEhCgMjGGKekPklt8cILL+g73/2et47Ho9Zv\x2f85HHrr//m/89sP3ff7piYkJnJ6acqSEyJz8i3/2z1Zve/1d75uamGx8/gtffn52\x310zr7e96x8Glky9edezJx79RjccngsTMWtMIwYwAAsbIqMwkVXXBx7MUY1BVxTzP\x71aoqenlk6JUqknmlEmEvtSdvNBpclg3OMkVVNUmSsGpiiIScY0ak1Fq2qszWusQl\x6eLosaeRpbaKW1w9cf+SGO3/kfe+7qfCqv/u7H3lye2Pz/PLSyS/XMhc6rUYzS12W\x353mz06w3984vtNrNessPBnzLkSO3/tzP/czdeas1+9u/+e8/Pj+/1yBjYgFrHAQk\x43gNUohUZUEDQEFhVvIhaEYgVEToC5y1QUkFRCgL0UFQxU8Uk5sZFSEgNsYpxrIYE\x456M+M8h5rtqyAVv7THrtja55VRaCKgASAigqMBEOEJIX/fDZkeImqkhJWvgARUQN\x67chjKTFkACGk6rTEQCRVjJzGyN4Y9jExWaaUhmCtUYfRAAiyAU0tmNwiGRQEInUG\x6bzQhlzhra2CgXN/sh+tvf8OtP/WzP/VzoSxrx558/Gnf7W4vLi5Ot1sTWb1W7zSa\x6ael2ozExOz0zMTE9RRqFRNAce/bE9rXXXbPr2muu3PvcM8fWfeXVWZuF4H2M3kvE\x71KoxgiiKiDEGiERDCBd7jsYYo1RVU42p5MLmwlckEcavsAkE7Xabqspwmgpe3P/v\x48FkRQzHS2BixAGnNOc6cszVr81xECrSuObtn/sYP/fTPvH3vZbvo9z/xhePHjj59\x71hh2H9vaXD17/vTpp1bPnntmc33txMba6um11fNL66vnT/e2B6fGw+GLzz9//IGZ\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\x79Y41F2NErCojqpir4mhHJaOqYn2ngB2N97YUMVnFRtnv1CM4rFyAmX2a7D9oa69b\x71noP9xX7GZgsQqwsJaYLuI0itb1JfT4JJdSUsZVP1B4v1k8NkPwmcfz8eP0PHi1W\x500E3XjO44sfftffJb3zr+Kmnnjz31LePfWbjxWX55sOfWv7YH3z4w/d+7pMPHkwW\x33JTJ+KNf+O1nPvfJj31p7ZFHq8vq8/V7n/n6yde+8c3T5Dj50kc/9u9ev3j9wumz\x79yfivl3F2fXNLU5qM8+Ne6sOHd+QtRpUjhScwWewHHzJb31qG/RkVKlkpxeKjAn1\x4eZzcMoVu/kHf/WRFto8aQyQoIyIgSfSRI0IFHlH1QvsXRIQqRo4iiBeYnxBBNMWh\x44WRkp0VLPYT41PBkuTdJVPI8eO/7p08f719c72azCf1+f5gN3PaxpSdX1tbWxgBA\x560xeUR/BKO31etLpJNXTTz8dl5eXX9Fzg79fJ8Tg9No0yaSAiMSW99zJMteYmcFu\x74xsHg4EfjdaqC/tBFADwTgAzBUDPD4fly05ml9G+fTC9vZ2UiBpjpBAC2RiJibRn\x72RhjtHPhNS9CVYzMIuQ1M1bFGLKWVQ0GgETNxEyQ2ZtrnTf0Y7W1FIpTVkG9ek+i\x6eJrcDaqimAI8PE+ZkxC0AUySJ7Wvlb0vPKrjr7yg8RvF5Ytrb/lbf/1vTO3ZPfPx\x33/+dT+ydOpBsra2OfOl9pzmN++eu5Nls1mxV/dIj62xt0u2dPZAZyXFQVuM2uOTR\x729777L/5D7/28d6jj59vZJP+9PPPDVhteWo0OnFivH16Oqld9vq0s89VhRIqRGPw\x6d0X3+eNAD5aIGyClE4m+Ih5h8O0708l358a6r5Wbn4ku3S6xkghYCqJiKdETR0QP\x72MrJhUL/kSo1oIkVVt8p3AEAhRSji5QAQFd1fOL8+TEA6Mpw6Dc3N6tGo2Hn53t0\x2bPCduLS0JN1uNwyHQ782Wqsu+Hhpu92uabGJSQhRsywYY/TCuQD4agcAAYBZgzVo\x4eBp05syZyjSbjHluQwjJjf1+tbSj/nh2djafmpriPXv20Fqe18QYNs2mGQ6HF7sG\x49KytaVqW1ExTTlXRxMgKgKKKdQAYiKCNkXyMVMVo6qroVTmqYQfKLgYCJnYqNqBJ\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\x2bt/sIq0FksIHLANiYHIeiQJoHco8DxJCwBA8e8+R1oGliQAxGMsoWyOiAoC51mxF\x6bPIcOnke1N6941RSI22mujdadhEAwF27drXn5+enp6enm1NTU3p1dTVfzVarW265\x78XWLQkVRRFVVCRHJ/Pw8rq6uwuvFC6RfRwDIPffcI5cvX1ZFURARycLCwhAA3Oh+\x6a9jbbku3VwCpGzpBhH5VVa+GzsOHD7e990kIwSmlzHA4TBcXF3vbt29PRARpy9iZ\x47Q0Rq63vgRkUkQCPzlOklMAQJdQEnVcBhYMVREEKGQbHWheFUlkW8qGlJLaEsUeW\x57TGH7rWNH7qObOorlspqfLFYLxSgua021TZVX8AFecfY9A2tPJ05mUbPz062ujds\x76xGeuLw0oUFSxVWy47r9taiWwvNPPXlpFmDXbXe8bXz2rmPmf/of/+G3//Z/92//\x42zPWeNsLf/CNj8cXFvyebTM7D020YPXqSnnouXPvPBLP7jpYhKhwA95uY0pq7amX\x42pt9m9TVvqiuoirnO+PmnkHuPvAdP/xto5JehTgwQKYACJnGAgAANYogeROIAvqA\x6dAii2/LuY4yAoqgntJUmQgsAuyj02veRSIhIfBwr224XR9RsXGIZKVI+MlHt0KFD\x38enTp1cBwE1OTg6rqqorlUyYVE/cdNObW53OlasPPvhgvjU4bvbv358URcFVVeE9\x399zDDz744BsuAsjCwgKkaWr27dvnjh8//kdYwmZu2ha/8uyzbvnKle7k5M5sbe3K\x34MqVK27//psnpqZmpq2lwnsviEkEoBExwMbGRjY2NmYBAK21QXWVUNUVhSiemTpE\x6biNCQSQmBGIRdMzKiEU2Qoor0uARRUihtrkI79KNeWv13Nmi+6jBlBRyErty+h3p\x7aMdvo2hKOcdZlNDJsue1MB5OmnESnAADICv03ssOZetzy72dF7707aVvfvpzX37y\x64z777E7Tml4fdHpH77nvYGOinZx4+dTKrSZ5+y0ffsfHbvmpj//l4195/A9Dt//8\x5108/fv/dd7zlxrQvtUsPfG+Nzy3s4N/8XPvw46emd2jRpWcxqBHZQSoVNuNmtFDk\x65UYhjKnE2lDxuFFTFSBdUnIeEbwPRVnXaVNF1p7aXPouq6iXW9UFYuVZWBBZMLAo\x78c6hSFNQyhgTE0IQQSxL0FSJq9WEhkMfmk3OmZGZUWtNp0/Xi/Ed5ThiYikysVIx\x6cyW4nbO7ZtsTU40XX+wPleqWzFH10gtPrS4vX85rtZpsKcQIAHCn0yl7vZ50Oh1Y\x57FgI8AalR8derxcWFhYE4B515EhNT01NqdaePbXO6dPp3/y1/+YdB4/cMPfokw+v\x31iYnYSxNTZLUa0pVXBQFO+f6tkeOY4pDwGhXPF/1uR9CSGJrIXDE6I2hSmvljSGb\x57zLBqFQKcCMAkOcaYRq0D0ElIlqL1WRJG2EdI1hmj70iv5ojbKY2aZAvx99hZ37k\x54t08GFc551roqayzrlDRrclkrCsvQgoBYwxaoUJBdgW3BNXewk/t6PSun1d0XSq4\x54QOYzc01t3HhAs20x5IbpibunpgZPxTmpl/83m9++pn8hWeaH3z3PceaWm5rPfTc\x37js6gx848Phz2w4sLMUpoQgoIWVpSIJAhCgijQBoYqWezzauakrjGRWZhgC0dbq3\x34/PNdYJlrdOqK9XmWjk4t6z8GTRaKvbMgKANB2eQg7XivAdtErJiEXnTe2ZyjYbi\x4bEKOIhQRxFoNnHNkrTXMbEMIVZp2Ral0PALBwg97vV6nW6vZBINRaEDV60TG1G2f\x73sbf+MW/9aF9e/aWL774fG/HjqOm0dC4f/9+XFq6CwFOvLb0CW9EAMj+/futUrPx\x2bPjVVGvdRMSpiVZr+7kzZ/zf+Jt/5x++74Pv/29OHH/pwnB1+RxRt4jjiba10bjW\x46CFGDUl0jIgKEVROjIuLyXBqqkoBIIQQRnQkWzPlNRPIWMYyScAppVJjiDQrGyKd\x4dCnPpCPD2rPWIEalgerBgO8F121p1axCnt4bjX/4HXbqtlrpeag1PVv21x2SP5qM\x6aSV5waQ1XSSAR/PN5y9i2WnG6VQDDXIA8VjBpFZmP9Ymd6t4/35tbzuU89G9bG/p\x623T9ZD6YGlvq7f0Xv/Hr/+RD9ekPfrA5+9cnTly6eea7J+beTOnNB03cnkA0lYSR\x58ouO8Cz46qFy8+k1RcWYjccTH6AhRK2oXnux2FgaGOEZVUsbItKK7MFOlQ+7RFcr\x34u4KZ4vBYEYqskLgSUvwbBghgEIUNAbcFpdCFCHkW0ZPRLL1niIiQhzH2jmnrLWq\x4bIpBkkzVEyV1NkaskG2MTUxpHTVtoppaaxPHMDx58nn+1b/z9//ez/zcz/4/nnjy\x38TNPf+/5V2Z2tGdJTL3X21CNxkUTRRHNzc3hVvED35ARIIoiW6uhrqpIK2WstRSh\x69uPpmbm286Hx3g++/21pvdb+0u9/5Xu1qfmuZmd0nEyjoEIkUoo0EVIIHIggiuON\x59ZalIY45juMKohIQfaysWAxSEIugCkGBtzpwSVGIFBlnEL2pobKkbGQALJJQjXQr\x65JaUOK4F2HGEore910y+Y5KBu1bou66/6Bj9W9OxuTRUjJroBSy6j+TdB56F7DuX\x51vZK33kQbVs1YxKLgN5XAkEgkQAzIna3qTcxshMvF5vnprWa3en1gRXG8zusPvwO\x6ed6wvV+m80IJhkrEAQA0EGwdryqGJ8rhyw9Xm19eIH7+os9f6UvARhzPj4nGBhmi\x69Oxzg43zqKLGmAE7AahslGy7Ug5WgqLME+WoNQJpYODMgQZQhKgJPDNrAESLQIqp\x55IoS78VtGX8tBFJpSkSkiqIwSilrrfXMnCdJOg0qKKV0RMak1urYGJ0mJm54puHa\x57re/bc++m37t7/+3/6QoisG//3f/5svTszM5egGAyiGiKwrDjUbERVFIr9cLb7QI\x67DASxjDMHJfWGs1otaZYKat1hFFrfHxi8fy5cMOtx2665dixG84vLi4++diTp2Ym\x32gGVaUTGaETPI2I5QKUItdZKJGJjskwp1fReSYWoWTPpoDmkisQYdIg6UqxiRMOo\x6aDKoE4wMg1hFFJlglVbBRgB1Kz6qgZ7aR/U7fyCd+cD24FWXCL+X9y97rMKbaq0d\x4cefE64iehWLz/qz3xQsozxhlQyBTXBX/yoLrn1uXPCiQ1jiYWIGAoEcA4g1t8OFi\x2fYlzXJw4attv3UWmuery9Rfd4NkxrQ/NYpqGAAIoJBrwMjt+xg8uPOEGj74Qsgev\x47H4JQFWMKrvKYWEQSmpGZq5FoMc8mVZUn3x8uPJ8aQB3QNKcVlFK1sxdGWaLYqIS\x67pBTOBSICNRIJQEVgMEYQCMGRKWVQs3MpdZojEFjDEJUgXOkiMgaYxARbZZlQ4CW\x30VrGrVWIaLS1xiCSNkZbikwkilZPvPgk/7Nf/9//zrvuvv3W3/vclx544tGHn6w1\x553BF6bKsKrUeqcyXZQl5XoM8X/8TGXX+8wKAa8av19fXDSKaGFFpLcbaxACAMiTW\x4anF8/sK5l2dnto+/8533HWu2J/d8/StfvF/HthfZJDZpPIEBWClGACQR0ACCSpEC\x43F2ieqIUx3Eck1JKSimRmSkKQcXGGADQgUjVUGurQXvHSsWRJSdGG7JKQ5ygaViF\x597shueO+dPojNwadXKIgj7jeSxw83540904GA4VO6TG/+cq3yvXPrys6XSKvDcH1\x47JzTUilWkVvyxWUrsG1nlE5bDhCAhKOUHnebi4+FzlfqYGq3qcads6j1Qhhungd5\x71Rtcd0Yn10+hVhIyFkW4ChAecRsPXtDVk0LSY+9dhb70JA6VVBvBraz5bFAzZtcU\x6fmkBYxzb5ktlea5CS9NKN3aquBlMNHZOsjNKg0exyGKJKYgCDgEUgAoASgEygwJA\x55QojrakMQQAAmTUxM0ZRZEVEK6UEETeSJJm11iREKtJaaUTSZE0UJ/UWWV2dOXtq\x2bbY333PbX/3lv/Fr3f5Afve3f/vzCwtnH4h0bHwlzOxdCFVwzgURCd5bnp8f4y29\x4dHmjAACnpqZoOBxqorZWyiuAWGutNBGSMWQJTbRtdtvYxkaveeTGo7e9+ZYbplRc\x7a3/3k//20R27Dmur1YTSRMGzAGiDWHVFiIgoIRIP4AZEcYtIcNRXUaK1RlaKrHMG\x6aFE6BNDKGgUqJq20YTYGSCuQtM6mHRM0dw6r236gPvWxG0U1L7ArH3TuuyBB7o4a\x4e85IDGuG8MFq/blvZauf7Vu64Nj1hj7vCgAQCxI5LIXhOqrdfk8y+ZYxD4gsQqZO\x541a9K/dXq1+ITEKTTLuOmvRwiwmX0YUFKU94wF7mM4oVzI9prZQXbkY1JVq1lqrB\x67pNkGIh8wFBK8L6UUEWgog2Qxat5dyWOa7snbDOZ0XFEXI4/1V98rhMlbk6nE7ui\x5aKoQVbsSYJEjHnqVOwAlbJSQsNJkCBWgGYlnoEZU6DVoDcREiojIGBMRJUYpiKqq\x36jIzpmltOxpDwNXQmGgsimxkoqhmY9OSwMsvPfu0/L1//E9/5Z133Hr9Aw8/cu7b\x58/3at9qtMV+WQwYOlfehZHbeextEqtBoKLHW+q3mGbyhAJBlmVIq1VoHQjR65DFG\x41FCodFqrtQb9gdqxc9fuG284NN2YnD7w7PMvPbq6srTSajeb1kR1AUHvqrWrV/tX\x32u10BrSgJoqXl5c36vXEMGuLyFkIRikl2jILIUZGKQ0AoElbxcEgotVkEkNkIzFx\x572DOlNns+9OdP3aHmZw5W21W91fZgwiId1n71iml8YpifCBbfvih0P19bVuFQxmw\x73KsrM4XaCJMYyzh1o6i770va7zoQtEYA3Ig0PuX7lx4t1786sHSRvKrdbGpvO4zR\x4fImIENUXXXZlk/jKqmRnVny1wcZMTtmkYascZpRuxCba362K/DIOz1XGDDQYZJQq\x3177njBoMld1cdOVlQjWz3STtGW0MRHbyGVc+uqEw2wFh/jpKtucKzDnpv5wqrZ1S\x46aJmUqhEFJHSwsggRAiISkChKIsagyJjQClVaA2aiBARN9I03UFWJ2hUlPV6SxgZ\x54tLanDVxiqTxwoWFizfdcuftP/VXfv4XKDbmC5/93a8vX778MiJyWflCAlfe+2oE\x41PQiVdBas1LKr66+cYSyEQCw1WqpLIuN1qSInCKySmuvtY7MKHxqQ1rFa531s0JQ\x58XfzLffu37EtVmk9+o//6n97ePfew2iNmvGl39zMNlbTKI7IxmMAiApVZEzNb26u\x72WmNG8yc10w0GWm0AlaTIRMAFImQKFARSWxQpRqC1aySpo2m7LA/f186/kN3N7Yf\x4fj3sZve79W+VKmR3xfV7D7KxF7T4P8gvf/GFUNzPprE5rFy3dCV6Drpb5gPnCn1Y\x527e+PZ75+H1m8k3zoNRQAZ7CqvutfPVbj/Pg60KUaQVJXXDyDtO8Z1yEAgdpaFID\x63LWrIVwsFaxVYIrLVXl5lYdZGkVzExDRdkrTqcgeaAi3s6ooO36QOxDuc1WIE7So\x64G702hU3XAxSjs2q2vTOaDxygo3jVf+ZzbKTb9fR/O7W9O5uwXyFcEEpCkAeQUWo\x79RAjSsAgQoRKJQgWUGtUSmuFzFQ4t3HK+w1eW8tqtVo9jus7UEgU6YhAe3YSMLJm\x72N3eW+b+6ssXL+JP//zP/uL73vu2Q0899czy5z796U+XZfaUOLYSQhVCWYj4MoQQ\x72M19UdRYKS/MHDqdjn9DAWB8fJzyHLTWpJTyWwAAzYzKWqsBwJDRamJ8bGKj04kn\x4aqd2HDh4aDKtt3a9cv7SqZdfOX2+3Wgqz66sJbWpIAxRFLWVAFZV1b96deHyysqK\x627fbca1Wm0eNRoiQxKOIkNJaWTCRBU7RGEWolA06bRrbYucn3m1bH31nfdstx3sr\x719+uLn7FQQj32en3Xh+36i9Kv/et/vqXTwI9xBQNcu4NpgzNHo5bbzqg46NvqU3c\x39950+8ffGs3cc5Di9hAdnEK/9rDbfPixcvNblwlPMcGmAIhxPH3MTrzjJpVOAjsB\x51FIioiPb3vTOrYFfLInXC5CNy1IsXuawuCEsQWM6S7Z2fTS2e59tvW1/3Lp+1jZ2\x37Ldjh9tR0loHt+i5zIs42TxfbV4A5yYno2hmv03aPrjxZ0geWTZRd5uKd+xNosM9\x765l3ETfQ1KrKsENRIEaJUoIaDAZCFA+oDGFQCpS1NoqidloU3ntfXbgwdJOTjSiO\x300ltdIKKqDXW3JZGceSCDNa7m8MjR29578d+7Mc+1KrX4t/51H/8xvLK8nlLSoei\x79D1XFTP7EIIb1a+9L0sTtA6MiH6rFPrGAUCn04Ft29oWoASllEI0WiljEFGNUk7U\x70LSyyiTaaljrbBaHb7jp2IHdcxGjnn3koceetdouj7XG9mS+XC96w44En/fdcNnl\x33Gu1JpLp6blalolvNqNpEUHNDAJGp6RjpdAAg1JGgRGVWMaoYVUdAk/ebcbe++5k\x38q4XOysXv435Vwvy5b1m/Adua86NPz/obH51cPm3z2l6glWtP5Rig7mQnY2x63ZR\x2fY4JMHsaykwZ0Lxa5Zef8svPPFSt/uGTRf+hV8Lw6YHCRRTywiEeF9h3lxl//5tt\x652/ineCIMgUUAzTJUqyjuUI8LYdsMaAqldLhqvdnX/bFSyf8xnNLIV9Z9X4AShWg\x6cLWEtQapGaWpteEHV5e5uuiVHcS2CYswvND1lWxPWvv2JGnTBUyPg//u1TC4so/U\x76j0qPrLkhleu1pJLDaAYAFWw4IAAiTRSZLU2mpQoRAhKWUAAFZUl5s1mmmzfPtvu\x39weZ964fCHMfgkOA0Gy1961tdC9NzMzffNfd9/zQD77vnXuef/b51S9/8fe/apVe\x728rCe18ORcRXFZQi3nuvmUh5Y5gBIGydAfj16AW8nrNAr47Sjp5LIYoYQMR7ZiIV\x6dJlDCMEPwuILzz3fe+aJ77394K4fOnTLsTfd/Na73/be797/rc8uXl54pnTDwXg6\x4cn3ONor1dXfohhsOaVFNRBC24bT3fjmKor2KuQjMijxq1IQgABocxBQ16xrafbcp\x390hy71sj/Z7jWefCtzV/KdeQ/UCY/sQtyeTM4/3lxa/ki/9xuZacMp515TazIUiX\x56czf3dj8xtN+/TErEknwhMpYp9g7lswqCHXUqQZDjsUbCfWbaq17boPGfYfB1o3L\x42UVQBLeYCBHJOThgYjuezL1jn4wdfLja+MxiOTwZMAwc0ZUcKF4uhy+Xqschr4BC\x59NYRKy86AiVSS7Jg0xyZdcahb2wSnisGX6aNS3JXY+qut9dmryt6C73HaPNrX/OR\x66/vY9g++u97+0bx7dvNi0ngJE+0FKkQXRRCJUgzBCRBFqJWYgMpo78tlIs2NRvtG\x591Al9cQtnLt0AvvDLIpM0tMhe/HZk4/ccNuxW2a3z99721veshMB4eHv3P9Ed6N7\x53oK7qhQ1vAcvIl6pwGWpmCjnsqzYuYTLcpWnpqbeUJ3gV1fatNYqz2NMElTGOGQW\x41lAYRUiIqIwSQkQdp/HYWLM11d/olpPze2944pkXTq2uLcGRm24yiTbp/OzO6UEx\x37PPQlwePHDgYp+k2AM5RExtRteXlpaVG1Ii1oaZSChSiUaSNEbRbRSctUqXHVPve\x57+rjP3y+t/zM1035WY8Y3hHoh25vTu1/ont14SvZ1c+sNprHWXTRk2p1QFU3gHaB\x6cNMKPcRRZ2BNN1jTD8qsYqQ3rBhAlrwAyh1h0AhQBTZHbevet+r6biq7LBIISQG+\x68o9TEIFCkIkAGAy1TnD+zFrgS4LoMnaDIJgH1EPSyVCpdEhJLTNxs3RRvD5Io9VC\x38SBICEgKAkFAoCBxlF9UxfmVYjiYjJu7DjfH9/eqXrkQxcevFu7KvOad87XG0YsS\x58hhqM6gxJBzrCgFRDAKRBkEhNKiZjT+ztnxx5/TUQWXjOiqS2ESt5tjk9LDKuyaO\x34r079xw69tY3v+W2O26/bTAYpKXzYXlppXz8wW8/EFlbeR9UCL4Ursqqqso8D845\x350PAAOADQBm8H+OFhRP+jdYHQADARqOhmGNMU1RKMQEYpTwgalTGKEVESkgrUaQU\x4bcPB5U8/++KTCxcv6TvuunP73/zFv/wJAX3w0Ucf+V62ObzcbCYtGyepIsWi0BIA\x4bRQdx+NJd7B2MY3rEwaV1qQMACirjLXaRAyFPWwbbzlam/vYYrf/2GM1+02jE323\x39+871pi86dG8+9x3wsbvrSXxiwVRvxCfBRAnHktWphTPrhsGm5W4oYAj4yGqyJcB\x32HuU4Dk4GVFrAqNIpNC6qgqzim6YIooASIgJrxGTIyIICiALMCE+HboXXswGD3mD\x6d6XngQIyAb2v0OUFVFkJLnMM+YDzzVzckFEYQ1AmgBFjWRAKVqSEtTFRwxexHi5W\x33ZUZU9u+t7Xt6HK+cfFivTx+OdVX2ro1t601trcT8iuV0lkgLIQUoTKEREhAgMbo\x54mft7I6pqVkd1beDBlGoE0EqSQWv0OjhcFAGkelf/pVf/Wc/84kfuZMppm9+85tP\x66P0rX/q3Y43UZUXpXFUN2YXSQ6jKPFSjgM9BBBjAv9oHyLLV8HrNBL1eAAAAgLGx\x4dWo0tBoOSYkECsEqUURRpBUiKmaltEIlShkUoG6n/9yXv/z5Fz7xF37yvp/4iR+7\x4c8+G1dJyZ/MrX/3KV6a3zUTbd2y/gxSGzc31xV6/f8VorbVN6onW7SCYey67tVoy\x680FAG221Jk3KmBbRtp0TY7cug39hY++OpQC5v2kD7r65OXfHg/nyV/6g6n7B6fpS\x4bTwsmYeV+DJAyDxKGULlC4VVqgCh1DUUqArlN4QjYQYQlhAAgYCFFQUHjlOmZEND\x74UNFB/dDPBkERMEWAPAaSS0CIuGyIXmEh/evhXCuBN/bwGJZ0FQeoSgUDj1SVRG5\x51OAIXRBQyJpFVFQyYSkQdNAoGBQTMQWREAh6m5hfXRxuXN0WT+3ZMzZ263Lnyrm5\x39324ed3HfvCG1csLXR1ZXgtuETUBKqUVAqAh0FZHgyy7zGyhPTF+RGvSwflBb7h5\x72ipd3mo22nPz87fbtAFRc2zHvgOHDjcmx2tHjhyevbxw6aXPfvLffTGJ40tam4aI\x5a1cVWXBSAVQlMwZm8YilzzLyWnMIoR+Gw+EbDgAIADg2Nka9nqU4LlAppYiMQkRF\x4aISIpDXpgFopRNpc77zc6XTWm2Ot+szsnD1/6XL0u1/4+rnTL7/cOXBg7/xGp7MW\x6bQ0cfJHW6xPtenPWmqhtibSgQBzbdrGZLbG4kNTq09YYo5RNidAmaS0+ubp6pnHb\x72WPjO3bs0BfPy37bfOeJ7sYDX6mufLoeNcqhcxslhUHFnHuNRRFU7rUvKwiVd1BV\x54EGpshIS7xFZoBIFgBWCAwiIQJqYhRRQwtRQKrZjIFO70R6IhWCkzPF9AACIKK3w\x76Aq9p7LBA6WClQG6bgVYlIh5pXTuqSpHC+xaFCBXGkvDpCAggIALihQY8EGUJ6XB\x57wiswXkSrylVZd10z/RXT2+3jf1zk/M3LWyunKwd3ltbSezG8edfesqmqQeljCZU\x6fDVppaOi9Gsra73l+fmZm7UxkSJjrE2azXpzpl1vT9tIowiWcb25b8+BI+85cfps\x357HHv3fxxIsvPP3ic899RxR2Ntc213t5vpxEtgbMEkKZhxAqgBCYKw8AwTny1kJw\x7avEbDQCvToJ2u11qNufJmJIQUY8qQR611spai8xKKwTT3Vw7t7zc7UAUImsT/s4f\x66uN8XEsbd999101Hbrhhbnm1E+k4cpqo1m63D5KwVqRiBLSCpIhQEaKxaW3s8tXL\x35+tRM1KxjRBVkSQJr2Xsf+Ef/6MPXXfDDTc/9dkvPXlYN99xaWPtye9WV7+CUdQp\x51fICfa9SofQilWN2wJ6BJBCADx6AsBQgCoLIrqRAFoUhgCCLgoAIABpIYaA4Rk4A\x6cIpCaO/Syc1TYIiZAfFVTohR118bfNmXayf88MmMeL1C3wNWjlGCBx+ExAfE4Eh8\x71bHEUvlgPHg0LAmKQpbANmgi0hi0gEEtqFBppVhHwdhyWPdLK91seao5vqMeR+Nf\x2boNvfeGdn/j49Xd+8IMHH3vsyRcikk2nsGIRcc7ni1cXz+/Yvfv6OElniKw1Rhmt\x56RxFppmm6XR7fPy6ienZG6J6e8YFbNx555t3b5uZVL/325/+zAvPPPsMEfTFec4H\x52d9VvQ1jag0Az8zsnCMv4hkRQ1n2AxGJ956Hw6F/IwIAAIDSdEJrXamyNBjHTFpr\x33Bq1VVoT9HqbCysrKxvN5li9VWvUZ2anth84dHh+ftvcjT/4gx94z7vuvHVyaTPL\x46hcvEmnV0wgqiox13jmloxiAJbiq5wEKAvGtiamGMjZFFfNm0c+efeGl4rpjx942\x4eTdz74Vzpz85fP6kzcpi80S+8u3c6lXxRDnikAWDADCTCsjiyYIPRC6IBM9VYEzF\x670bGwJ61z7WgIEoEgCPqMwUiQUeKYgLURKR0CM09Nrl+lmwCgYUQt/z/SIGl1Aaf\x723qnXpHiqYAyzECGpZFhYPKssPRkvUcOWOlSpKp0atADAFMkWgMqiJBFyCoiVhpE\x6fyBGyjEENAKgUALEVUhMtpr1LkEclxjXi8Lgi1Gr9a5LayvlU08/dQKABvVGk4QV\x4ecbH2kjaMnMAkKBIJ7U0bsdpvZ2kSWtq2/xBU2tM9bJS7d29t/VXfvrD16+urMiV\x69xeXJyfGipii2KRYsQt+c3Otm+e4EccYixgCqCpmFgAIVVX5LIuDMZ63FmXemABo\x4eLapUQRwICLEbJXWoJRSuizLTUxTNTm5bWdzvL691WzuSeJ0siqrtcIVWOZF/dB1\x31+/at3dn69SZs2tlVUVlXqyxhLIoy76ris4wz1er3HerIu8PBsN+cBVmVVE+/tij\x791Mz2xr/6J/89x9N0sZ1n/ytT/764ovHz0SRSc/7jacLqzoml6RU3K0kFB6YfeBK\x30JclBOeZHXvjK2KumAMTMygJCRGDVwE9idKMLEJ6tHcIWkQp0kYD6hSoJuzMNp3s\x33aviKe0ZrpWBZLRiCB0l+JTrPbYM7iwLDzOCfgiYCyrnCUskFwCRSzGuIB+KJGFD\x78AGDqBCkihR7YnaGBEiwEsWGdBBNgloJUgQGdSIGIUtodaXKL6laQufPnr3w7W8/\x2bPBNt9187BM//vFbr66unfvCZ79wvtFsOPYsZV5kwlJ5JwVCqMhaKqvAaaM10Z6a\x4fbzZz7qojP3Zv/SJo53OhvyH3/zNrxV5sdDtdC4kqZ022rTSWlpP6626TsGLc30i\x4dUUhzExeKeGyLEMIcbDW89Y49BtzI6zZJGWtpRACjRTGRwAQMZQktkkUjZOWmjFG\x300jPC2tpvK3RaDZXri4Nk7Q+9eaj103Uxqcazzz9/Eq93ppYvHz52W6vd6Gs/CYy\x65JPGSZqktdbYeH1iampscmLmwEd//Cd+4lf/3t/9u7fd/ua7vviFr/yrl59/7uT2\x62TNxwaULlS8ylAE4pFL5XqlDSZWIILnSV6VWKgSlqgDOV0qFFNG5IvJKcueYPSvP\x46VQQKaVVDug1IIIGLVphAEOIyiKkABRPKbPjICW7bWCA0cwNgIAQES6Qq56puvcP\x43ZYy4H5AHBaGcg9ceiLnMHColBdUgclzwuzZew6+xioGEWbmEDNREHSKMUYQIqJI\x45wMzaGRBISDioJRDYyBYFBMlXGbDNTS2+3N/7a/9yjvf9fYfvO7GGw9lWeFbrSbF\x53RyZyEQ2SiJGn+dl0U9q7ZA0x3Yw6XZns+c/8uEPHr7+8O7JT/3WJx+5vLDwCnLI\x41DGpymrgfTV03gcR0Qol1UQ2hMAhUAAognMuhFDjECAY47jX6/k3GgCuMcRhu91W\x78hjy3hMiaq0BmS0BCBpDRMA8Kr/BNUk3JCIU9tVwMHhpfX1dT87vvu7WGw40A0Xx\x69RMn17fv2HF0cnJir9YqqifJhNEq1iaq+eDSSxcveRU3drWmpm4cn5xonzxx+sLf\x2fZu/+C+P3niLDpwTAShxjj1DUZGUpYRCFcAs4ioWj2g8awhlgb5SElSh2GhmCMOA\x4fGJ062nN5L1Ga5EqAOWFSCkyQloLWEWoFQKRUNwWnNtrksO1a5p9ACASgIzBl6W4\x38oLrP14YvZaRdCvAUghLFglAyiOJz4IKmhQzeb7WRxApoIpjYK3ZsEFrBDQYFA2a\x68IwnL4oA0RAGYkathIiUJrRaK+2ZvWk28i999nfP3nTszbu95/njJ093ltbW3cLZ\x5667GNqon9XorMrrRbI3vSev1fW97+7t/3sbJ/MXFy5233nnn3g++7217fv/3vnjq\x75w89+HCRF49n2aDPwlwFNwyuKMC7CiUUrpRCxPsQggPwgYi8cw5CUJIkJVRVJVuH\x34DfURpi6BoDvV4JGC9Vaa0QMRGQJkQlAW1RGg6BGJCVKKUNkAwArIkCi2tLVJdm7\x2f7rdR2861FpaWetdvbqWe+8Hi4tLp1aWVy5s9npXL1++3Jvdto0/+vEfe8v7f+hD\x4893oDavHH3n4pcUz555YunjhmenpsRowa0bmyksBIYBgCOyAiTk4wAAiTICh9EUQ\x72piJGF0GClHKsgQWQUUkJZGMea/BOajAoo1FRULai9OkxSoRTWRVxNKsB57cZ2s3\x6aTESiwASgIgX0BZPSHnpZVc85zRuluByhypnXzlGCkDO9SpdKSTWSOzJiWemIA0i\x72ISqVFLtFaET52MQXZIxRlkFGDBSCkghaU3KGIVIohQREYDSCgCARQprbZEXRXXl\x38lLMqKqP/uiP3nnjkSO15c762eMvnFxd21hf7vUHvT2Hr9ux0e0nqxvdwfYd21s/\x2fVMfu+n4s8f7v//Zz95PGleG/d5aCAHYewhFmYOEynvwznHFXDilFDNzQMSQZRAQ\x49/Dei0iJVVWXPO+8Nv//U40Er9coxKuqh8YYIVJijGEi4qIouFarMUAl3kesNXgd\x32JCigBwchKB9CJVVlJoonUPE4cKF89/9+te/NvYTf+ETt37wgx84evKlf/HQD//I\x52+7aNT/z0c997gvHB/2sf/jI4R1vftObdu/YMQNNBdDpbCz93qd+6xt7du3y09NT\x70qqqSpzLrbXjiEECMbMnJhIGA6CDokqFAFusRNf2jP8Iql9DxUKIogE4INJIr7YU\x675oJR2qkHjgAYugjd/vMOZCtA7OMTgIEHgSG4geBoEREAQ+AyotHZA/IAfFVo7hG\x54uWZCaEvozpyX4yuo/OeXjt2UlUoNgLwFJhEvHCkRFtg8MKoRu3WSvpO+eHk5ETS\x37/cuLi0tf/uHPvqx++5505Htxa1Htt/7znd++Kknn9o4dfLk4vjEWPv9H3zfjouL\x7993//V/95mMf/uD7b16/uhK++uWvfNe74uXAPlPGbgtBuoFdT4S/f90UyBiDZVmK\x6345DCKIUMyIKUcHGmCDy+lWAXs8I8CoAZmdnsSjWaTiMCCBHrTUxs2I2ylpBZlBK\x6bUZEAgBFatQkI60REKjMso2ychfW19cSRmo3m+2x559/afFd737nod07puy2Hbtm\x6d+NTU82xcXP8xOmzL554eWNmx46Jz3/ms7+5cnlxSWu1npdetNW4sLB0NqnpypBp\x4f/aFAIfg2HMQdt4DBgwVVAFFgnIKKyVM3gshik9T0c4xAEACgLkIlgCgpSTyFoJi\x68TKa+gNAheKxTnYsiFN7KL1ul4pbzAJAiIQEORE+7/vHL4h7IQAVDnxRKRyKgAuI\x72DSWPqgQEiYTVAjkWW/xHyEiKEQZRhEaZvKJIgxWGYMKDRFqBPRERiOKUSigAJAA\x49xVVvlpevLp+Lo5tzVrbCiGsp2k8vtbZvHD73fe864FHnrr0xFNPX5iZ317btXff\x33C23Hp1oNFNJ643opROnVmJN8fce++7L58+cfmk43Hy6t9lbI0WRq8oBM/sgvnIV\x4fxFwzOidK4Nz6AFC2NIoDFlGgpiItcJE5Lvdbng9vP+fyTDcyBOQKGVZKcchBFJK\x69VI+eJ+QtRxG4ZECGgkA3odgPDsnqJRX1jbTNNkZRVH23NNPnbi6vJbV6wk3mvWo\x306/g/gcffuHk6XNrZV7iWmd9+MM/9KGDJ06cHHzu937vuZuvOzTZ6fWuskgAgGjf\x77e1vWlxdfTotYFBrRTuQSIkGBAqAZIXzgpQiDiJSqZIRtfzxoT6FKOE10YEQJReU\x39DUee+uTREAJBfJgIH6TBXYCgoCMdLsLEMiC7zJiiYDCoNkDiwMRQuShjBRlFBET\x44uS1vssqxQAASimh0QojEJI4RRwBiIggU2CPVpTWQEAkSnSvVyxsbq509u07eFsI\x6eDNzlW9u8sTElP3CFz538uOf+MRiq9Vs/s6nf/f55188sWEjC9tmJ5KPffRHbp2b\x61dupyXH/hc/93ldmJyfGjdVFZOO9EkvPMZeMKF4kMDMjBkHkraFHYqKKi0IxUdh6\x4c0ckW9f+vq62+Hob/4kTJ9hayyMFewCtdRiFQLoWFoPW4JXioLbeQIAAAhAChxAg\x42GYIg+7g6tpy59HvPvrYQzt3z9Um6hquXFkZPv3M8XUU0vW0Hs3PztZqiW09+8ST\x4czWb9VKZpCXCxmgPRGyVsrX5scnbQj2NVy52TnGgoagoqsCCsHipmawAKCsidlp7\x49hLEugAAxINBeNXwtlKS+muAwFtfE6IgoCgBLMX1HXCVixsEQGBgQPEAiNgh73oC\x58VBKHPrCIZcaBI016BHZSkQ68ppFsAdNCNzEa797nUgCMxKR9K6la+noOkqAKvM6\x56zohAAvMFAVE6S53z4TAYfeOfW/R2k5aZeuIqJhMBKDqc9Mz8uIzT59JI5Ps2rG9\x30ag1bKTj+JVXFgZnzlzopCiwe9dcvLhw8VS323tufW3tFR7JzgcACCLCLJ4DoiCi\x65I9C5Nl7z4gocQyglGIikiTxbmswrrqmIQB/gjJIf64A8Mcfea65LEv+45712iMg\x6at5LEUZAQRFh4KC1StI0nR7m2cb2uR1TEQKcOvXysiYFNta6qlzQmqTb7epLlxYu\x47WuYIajR/6+10VEaWWu11mqinhye3L1tz1p37VKWZZeUQuXJF3meX97ySsZaq5gZ\x71UFCiFLU6yowo2Mmx0zXjD6kKcUJEyEKIogHkAoxACgokUtidH3xg2JUqscAIAwA\x671AOcuJcAYacJB9dp3nNsGgpAgmOaOD7bFSft5juiHkUHZxzFEJK1lrlvVYhBAoh\x55JZ1rnr0AzFiynJ4dWXlyiuNqfGpiYnxG3QURVYppSPVUMoaGu076iRJ+MLFi8tV\x38NHYWEsPs36pNEGtlqqTJ06u5oCwfW77jsEw7wYJNonTcUBhIWHxnpFHuT+GICIS\x52CSEENh7evWzrqoqZNlIA3nrXCivezbyOv6ua909rtVqfC3UGVMEpRQ75wLRyKMy\x6a9IgZmYMQZiEeZRQMgABi0ia1iadczpJarx73+659VLgzJmz65Vz5UZnMyvLorjp\x36E1TR49e35iempoZDocQ2ygKABDHtTiO0/FRhdUYUSqYWE1NzMxcz8zY728srKzI\x73nMOEaO61qNKiTEmVFXlc2NCCCOR68BNvOaNeUsIsNiiFFejw2swACCIgcgSK+UH\x47DoZhK0kRkQIIAfJKuH8WmlUiWAAz+y8fxUEgKJey3u6FWGmAGBTjwzJ2lKHEMha\x4aq21iqKoHsexuXr16kqnUy44p8qZmfnDiY22o0ZRVllQCnQSt+Ja1A4hiImMHQ4H\x35rrrj+y8/vA+PHrLjdsQpOhtbhbOebewcHH98tWu2759duamW26czAaDotZobOMQ\x50AABI4r3IYhIAEQJgRjRyyj98VxVJFVVjWR0TR6ISKKoF7a8/xs7BfojJ/ARtYYo\x70RgR5T9XafnPXbECIKO0On/+7Ct33XXn7Yd2ztiXXzm/vnBxYe3wwf3jH/jAe/b8\x39V/6hTs/8IH33HjD/l32hz7yw7dvn9++2yS2zpVwWo/HkzgagxFvbqiyvENikdio\x56qu2B7FmV1crt7CwICJY8cjL0rWKDwBAnRmLev3VRNxzg17LoV+OPL9o5wMjhoDs\x4aACK0qHPvpNzEAWIDEigFVQk2RDDpqdQMCBXRJVCZAIUhcQljjR5r4HOhQYZ+r43\x6eZhgDKFG1lolEmEIhkRMFIIKRVG4aDUKShXcbtf3KUWpkMIyyzec9wPRFCml4nqt\x4dZPnOSprk6O3venOe++979hYLYK73vqW/b/6t3/57T/8Ix/ac92RA1P9QT9/6aUT\x6c7a3UvW+H/iB9z311DMvI6FXZMxox+P/2xmwYrWVPv6fFE1eFyD8WRyC6cSJE7x/\x2f37f7VpsNIpRakGERKWEUAvee9ZaM4BhQ8TKA4DdgisDKGWiPM/WnBC+9W333MEC\x55G8k6pd+6efffGDv9ok6jNRnltYGvFLk4dLy+mD/9Te/j8QVFZ9Q1rQaWmtlYpOU\x58be8mZWr00ltRlnlg4tYqZL37uW4Xr9pPMuG68yMxphaCCEyxrgoirw3xoWi0M3G\x390ExGOKoMuOcIWaFUIpHzQAoGjAwshOIOJdqWJCUpaL4mXy4tCeOtmWeew6NR/BO\x4dIQgigWASxBwUEgCCjax4IgM46vMzQjcbmNFRN1Vy41GoRG1tZY1EbBzbhkRyzQd\x6e7V7ONss2DGhMtYaJIiyvOhoH2utVBzFcY0ZoASqHbr+hjuurnX8iy+fXVOJmYmj\x52G+bbsYHp4/uvueOo7vPXV7tZ8Ms33QgR287dvvNtx377MrK+sJYs7Ety/MBiSAR\x45rpRORcAwHvPI0WsP+IAGRGl2+1ymqbymqbp6xYFNPw5eYzSIBW0LtW13Pe1uZMx\x52ESkSevIxmn6xBNPPPOLv/p3fu7IkT3NTub9wV3b2gAAp89f7l84e+7kxcXL3SuL\x6c31e5EVRQhOY641avTk7v+eW9nh9VtiX3gchyk3NxG0kqRRSPZTVxQyGMDU2dViD\x4etC27f56cUUpXhsOh0opFXnvTVEUOg2B/FYaAgBQxnEFRQFKKQMQg5FAAAwIILxV\x46VIKoPBSlsDZpoLoedd7ukbttxfAWeBQecbANKqDOwSJAMBBDF0KwSgVikwHaOqq\x6cufaMZP3nlLvqdFgVVXKeE8FYpYXReHGxrY341jNK4UNpRS67vBSUfnVWpoeJjJM\x61BpGq8jGtQZp05idmd/dnt51eK3TC4N+lj3w7YdeefaJp14ACTAxOZHv3rmrdeDg\x76qMHD++ZThEaK4Pg5+cmop/+Kz/7sz/7F3/y77/nHe9q20gnmaehEOG1M10IBf/x\x7391/Qdn8DdUH+OMjETA+Pk7ObVKWxVivKyrLEq/NBWmtFRFpohG3D5K2RpsIFZl6\x72TG93uku7rv++n1/4ad+8sfr9YSsInr+hVOLn/7M5z/5v/3P/8unHn7wwZcWzp5Z\x4fnrTTXf89E/9xG333HvXrk5nc3jh4qXB1NzcgeB9plFHpG2y2e2db9bjsbIqB877\x6adPHn3t52+TctImjMRGuILCmCCIIOhWJIU11//Tp03mtVhOVJFCIIIWguCyrS2tr\x676lazSpEq0CPJjMFCAmIlLHGSaxHfAutG1X9GAHa+7P1b8yljd19ditnQnm8IN7w\x68GVQKIhYVkaCiPKswRmlGDn3Cysrg2RiQiVaRyoEGiolxpjK+2JIFHKiRq3Vas8a\x679Na61hrjUQm1jGYlxfOX5pojSsANGPj7WlSSpqtsb3T2+aOtMYmd7O29ZXV1e6O\x2be31X/yrf/FNN19/3a6TL53Y+N5jjz56//3fefZLX/ryH1y8eOVlE9fm5ufmJlAB\x7aM7OzFYuXH3skYeemJmZ2VYU2UC8eO+dA2aPQTwDuxCAnQOPGKQolHNutAjvnONW\x71xW2FuHljQyAVxE+OztLeZ4rxAYgZqi1JiImZktETACgrFUkorTROqLIRmmStKyJ\x36cSpM92/9Wu/+stvObJ/7NS5K8Mv/t7v//t/8Gt/99evLlzcPHLoupsnJsYpiaMc\x52aZBoHnkhkMTt952w7aglBw/eXo1Nkm9qqq1qig2SQRtZOvnFi6+uLa5ukqcwMRE\x716WMbhGAiEAVnGRaByMiESInk5OTVJYT/tKlE3mv1yvTdjtcWF4uAYCjdluJiLVc\x4bRDSMtqq1URax15iUkLBc3x9VLstCIYT+fD5Rhw1euDXLwV3OkDolCA5CXNFoQKi\x77EzBK/E4HIJH5G5ZFr1eL7RnZkLz4sWifuBA1enEGEWmmSS1aa2xEcdRIgIOERmN\x6arRVCTGIlDDsZlmeZVl/5/Yd15Om9sTk9I6k3ppf7/U3ltc3srfdffv2n/mpj72p\x747mpvvblLz+7vHR50UZmZWKsrXZu23H0ldNnz/2H//ipL2Z5vjg2MXXo4NxkMjk7\x64/B3Pv3pL7fqKVtrapV3uQgH9qGSEFyQ4EMADiELxhgfQuEBSj8YJAExhzRNeUsZ\x35g0PAAEAXF1dxbGxMQyhR8YYpbUmANBElgAUGkNaKWXQKE02TiNt6vVGo3nyzPm1\x76/Rzv/gTH/rgu2/55nceevQf/r3/9u8/8LWvPP/Wt95x87aZ6T3BF1WRD3vAnsRz\x64eqlk2fPn19wE5Oz0/e++abp+T27xy9cvNwfFmVDkDfXNtYX19Y7L1f9clCLbOSN\x644CCiiwUoVjqdrLVKNJNgABKAZclACIbkao2k06osdkxtevChXIBRtnuYDDwcaMh\x4baIuwQsyKVKKbGCNxIlCbXQFY4ei1u2bHK5eLIavVBo3hwTdnoQVz1RWiGVA8MGL\x441a5gKHMytIVtVp+eX09u2YgnU4HqomJxDjTtrWyHQHGQjjKFbUY0Fb3u8Orwfme\x73tpK4MFwmJWN1nizLDPqZUV3ambnkXpz6kAvq5CMVj/xiQ8fff+73rb/xPHTm5/5\x37d999MyJ49+TEDbLLMt8VXgA1mNjjand83Otxx74zhNf+tpX/0DVW8073/KmG3cd\x75P7Av/7X/+5Le/fsmqqc8yEv+sxVwaA4hMqP+D+sF3FuOCSvVOAQ+mFiYsKdOHHi\x64dsB+PMQARAAYHp6GkMImCQJZpmmOEaFOFqT1BqNUsqgsolRptZoNJrd4aA6etsd\x647/t7jvf/5Uvf+3Xf/4v/8Jv3HTj4bkDB/bd4MrKD4f9taJwPUFQwIBlWWWb653H\x4fhsb1bkL53NTa04cO3pk/MajN87lReUG/UG7Xm/UT7740rlt22cPNsfGkqsLi+s7\x64+2aj5Rt9vP+Zr1Rn7dxVEMJvHUEZ+fAISJUCABDp9fG6qbX6+UAgDMzM+nE8rKb\x79rIhFcXQt2p5z5dDUdZZx8GhzgNINWZ0u+uz/jSl8x1fXrmC/oUB+csDDmuOZLP0\x30unosFFu1DbO58u9flUVtw2Hodq2LbqmrLJz5852FEUJWtTaaQQBJmtirXWklDZG\x32VqtlU77yuW1enMyrdcnVjc3N6amJ3fuPXTozmZ7fNvs9t13iaL04OH97b/8l378\x54bt3zLW/8Pkvvfz5z37+/t5G52yns/EAB2+RQAURKsuiV+TZZmCWbdtmd7abDfPv\x66/OTX+ts9q/cePPRH2yNtwePPfjIk7NT0zO+zHtOqtJX7IjElaV4gDLkOXqRfrDW\x63gghjI+Ph6WlpdfV8/9ZA4AAAPbs2QP9fl9ZaymKQBdFQVGkFIBWREIAxhhrk6RW\x62ylFtfG5HddNTU0f+vY3v/HPP/Pb//67H3rfu29VCPVBP1uvqnIYAjsRDp5dwT6U\x5aVUVpFVqE2uywWDtmaefOZMN8ub+Awem7z12/fT5xZXNy1eX8a//8i/91OFDh+98\x35NHHHnS+Gk7PzO5zvtyomdokaVMHL56YJYgSERGAMncuH1iLMRgIxhjsdDr5kamp\x47gLUfa2WdGu1NMTjdZEqirXOC64qj2R8lfeR0K1Xw74uquSu5tyPrUr19LfLpW9r\x30t0shM0cigwM5lmvVjQbkI5P1JOJRiNZT5I6hSieiqewk3fc1NRUnZkpSZI0YOiD\x42jQmbltrDBHFKtImslG92WrP+MCDWqOxc5CXuWgz9iu/8qv//F3ve9/bn3vx+JXp\x6dZnaX/+rP/nm1dWV8J8++Z++++iD99+PIsvBVZm4Srkg7ELw4kPpfSiFxbsQiiIr\x2b1Zhum/Pvpmnn/jecy+8dPzh+fn5e21ki87y0mIcp7ViWAwocFVU7EXAI3JgLp2I\x42GMMM3M4ffr0a7u+rysI/qyqQK8OxymlZGNDSRShRJHiqiKOokoQrQAAaEQBEN2Y\x33X1zo9GYevBbf/i/GkN091133tTvbm6UVZUTaRNCCEKEGpEQtmrmCpRGY6s8y/Os\x66MUmsfrON/9AriwtL7/nve9+80Z3Q6KkYW6/647dWX8ADzx0/5ueL4t+Z33t5cnx\x69R3ampkyLzYz8J7A+IDBWgtQllF0+vRwY+fOJDHGRf1+vwMAMEgSY6uK3UjRHsRX\x55apMUpW6IB18k2Q+TuP6VFA7yPlozNi0kAK0UdjO0+aETidI+3UNprfp80vNiUoR\x63y2UGMqtmr8ixaAhAoAhAPSUqs14r8PGxmoxOzvbRKsNGK01ojZkE6NtmqTJeBLH\x7aQsXF1/atWf3wZm5+bt27tkTH9qzLf3W3Hx9Y3U1+9pXvvHyww9/58nNpZXLwVUn\x465dWrrbatYMhBGDxDgCKLQkeAQAIIQBqTd7lQ9RDs3/vrt2bG/31Jx587D8duOG6\x39wIALC2cOxNFUdKv3GCr8ysAox4AIoZu13Kaule1pP//KQIIAODS0hL2ej1pty0m\x43WFZlpAkhkIwCiOlDIE1Sdretn3HLXEUhTMvn/rDWqKimrW1/qC/6qp8yAw+BO8h\x69GPnKmBfBR9cQPHsvA8cHDA4QjIEkiqtq8WLC6deePGls8ePv/TwHW85dv1111+/\x36/Nf+NILq+sbjdbE9PYTp05f7W/2LsdRrVCiElIUowEAFkAv3rP37TapEIo8hOCu\x58LnSAwBot9txpFQkRZLLuh7aRmkCsgYBrUPpFZNY0c1YjF0qNtbeVJ+91wnEVRxf\x76b+3cP+0bcYlQ1EAd6oBdblpYhOCEiLOre3qMhHUqK0qwlq/n3U6HT8x0bIhGJck\x71matjbTVaaJtFMdxy8ZJg5SSLC8vL6+srU1s23Fs+57971dKjS1eWR7u2bd3rre6\x63vmTv/lv/+XFc2fPllm2ACBZUVRMCqzzrqq8z3zwBVe+8IGd874MnktEduhd5UKo\x50LsiL8p+YqNIaYw7nY2F6enJg0pZ6Q97XfHFRlVxIVI4pZRDxNDpQLC2FxYXFx28\x54iRYf54A8NqzALbbbRoMYoxjxtFOGKlIg1ZKaSSt281xs7DwykvIDoP35XAw6ATn\x714DiJbgqBHEjQw/esTiBrTEKAB988MzeAxAKCYl3Vb83PJdlw6vf+oOvPbFv797i\x31Kkz3eeffe7qu9/9rj0f++EP3b17z56Dy53l3v1f+/wp52A5bTYHIXjPI3lK631V\x49iIQEZ47d+5VUds0TSkq6v5M58ywsb2hjXMJe00CgOAJSu8hVTYiorifbw7f1tj5\x30U5ZXh4Y6Lw8XHlU27oKyK7vB+sSpWjI60qEFBH3Q/BLG0tZ0kzC0HvOsszBiHM1\x32759egwxahkTk43jSaWNBVEFk6ydOHPm6qWl9ejIrcfe8853v+vDP/ajP3zL3PyO\x35oP3P/DEE489/p2Fc6cfeOaxR5/ctn07b25uXoUQgAEhcHDe+5ydd8yhcuDKIN4D\x69xMJnp1zIXBVBe/Yj/6hKqvMM1cigsN+d7lWq9c3VtfPeJdnZZmVZUne+9xXVeWZ\x68z6O49Dtdv2fhef/89AIezXnU0qJtb0wGNRwfBy0Ui6Upa6UCrx6dX1lc325056Z\x6exbv+hyY1daQHHgAxCDgHRBdG64FCEohCZEjR4REIWjPXDjyWHmltInMbL83OLP/\x77IHwhd///KNXz5174KM/9TM/sHfH3I9cv3c+Orj3R26/6567bnj6R3/im//Hv/yN\x2f/D4w187MTe3r9i1a5p6FaexMVIUwFFE+Wtv6ODBg9WFCxfqu+q7TOJcmiFKAiAW\x68EoqHAYVDaTYKCvNe2x7KhCki2X3eKHscMa0TQ/diitLIZWK4FA8G+W1dh4AZhBr\x79fbt3lpriKhYXV2VrbMU9no0aDRCHQBIXFgJjOUjJ54qodut3/f+j9/+Qz/ykZ+4\x2fW133np473zdFQyXLl7MUcpTv/Uvf/3353fviibn5nitc3VpemLqhuB8Eaoqqyrn\x69HjrQczCjIAStpx1CEHgWnNLAgYH4DEIeVdqpQdVSWZ5+erZsrt+xhhDAJE2ZuiH\x51+fiOA4hBN4afsM/Sw/8Zx0BAEZ8QTgxMYEhJAgwJCKCoggg4py1mCTNiaQo+kOp\x66BkEKvYusPceWBgYfAgso6kyYRFhCSEAMDMAYwAO5JgDBw7sA6BA8NXG2voFX1ZV\x52Dq//thtc7U03nvipZf+X+1dSYyl11X+zr3//7//DVXVVdWDq+24PRTYVGLiUBkI\x55WIiRUQCiRUrFkhESESRQLAgCySkLJCYxJIdUhaZiJUQkQmSyBGdEBzHLsfxUO2h\x63LvtdndX1/imf7j3DCz+V+1yY5tEiuO2+32b956e9N5/7z3fOeeee885Z7d29uGy\x39tztyzf3Vt/+y79yz0d/67ff9b7fOL724P3PPfLwQ5eOLcwNRqPRYGcnlOfOPTVY\x57VlJkyRpjUajKCKtTqdDyf6+D0ArE/Fk3pOZSzRy7TR2KG2vF9ubv9peuDVVO7kv\x34cUtq5+rnO1ujHfOtrKe91RpK0kCIc8lARMRIJJwmiKEEHplmWwVRbj55ruOnOgc\x36Tx7HqMs68dOp1U++eT66Nlnn8Hv/t7vv/tTf/sPf/qHf/SxP/nIh96z3O7MZA/8\x38EcX7v3cZ777nW//+31QDSffdrLcH+y+yOLEilC2WlnXDBpCrCEcJQqbQLS5x8Aq\x6fjBjUxVliSYqJiqqyhxDVGb2InWMZcEV951q6T3ReDwuRWpprkiBh8OWttsmZ8+e\x2fYUffF2LBDgggRXFFpaWliiEgHY7VeecJyJorANEVJUDh4qJLKi6CMSoypHI1Eyi\x4brOIsXPKIhAHCFNUx2AxFoMKmWgdZLx9efdCWdbVDTccXZyb7a2wxrIcjS7e9+3/\x2bOqzzzy7e+nCpTLN24unbjs1++vvuPOdqx/44O8cv/Gm2e9//wc7u9vD8fz8Is/M\x5aADy40BX+/3L1WAw0J2dHTna6aRVnqPFnECdN9OU2JkhcS246vlYjO5KZ+5sAaf2\x6dM+PwTvSomK9Lp87mh/xLm21o2QMspanlqlXrfM8ZFkmL7zwQrXVuD+2tLTQpby1\x6cKYhOte2p59+rPfO99/z7k/9zd//+cc/8Ym/+tDdK28PpuljT6zv3PvZz973ta98\x2bZtnHn/i3/K8VYaqKp3RTGpuvLP5wuUYy6rd6mQE9QKuoMzBNCoZQ8CqFokkqHJt\x4alEk1mYczDjEqLWqBVULYqGO0VVmdR1jVcYYa2vqVYS6rqUoOryzI6HfPytv1Mb3\x57iTAlRPApvdsD85VBIAmN0bhnDOqSWqBAF5FWJ0zVlVhbqoMMDsmYhERBpriYw5o\x72AFDUyVVA0IV9p7aPr952w0nj3dne7cCFjiESoWrdrtTQSU+8cRPzjzwowdOn3vu\x62FmwpnfdfffbfvPD97z/3e957wejcv3ow//1yNLSUpvIL8S4P+z3+9VkDLpTlmEw\x47JQ7ZVlmC7OV01jWXoNDDj+mESMnsir58NzbPuZjRb6dJxvF8P6WhP0QRrHb8pIO\x66Y1ZLfspyhcuXRoNBoPx3t5efVhoZmdPznQ66bHOQoefOfNI+Mu//rs/+4tPfvIf\x50/rhD9y9ubPnvvu97z/2r/d+8Vtf+uK/fO7s2bM/6eZ5FJHdUNeqIhxCGKZJeiRN\x38/jMMzvbR4/OZmmKtjIHZjCUawmhFgkMaGTmYPbSnB9cW2c2NgOLiIhAgSBEJCIi\x32vQ/4hAC53nOSRJiv3+WrwXhv9YIgMlJKo4f71ld1zYcepiVBkCLAookimow59Qm\x4afVgZlrXUO+hZqyTps4mkqhZZADatOGCCYRFohaFXjwxm3e63d7NyhxEY1RFUGMm\x55EfEVAW7+4Ph2eefO9v/7x/88MEz62eerIoyueuud9x52+23v+/hB+7/zO7u7rjd\x7ajpmtjXpaJJM/PKDhdXRaBT3qqru13W1G0bFTRijM5flD5eD8AGavfO9cyf+4Hke\x66+Mr481v3Y1jyWMowuW6LjYxjltFEUajUTx0QuruwT3+6OpRf/HiRV1aWoyAP7K/\x50Rq+4+533vHHH//4P7VbrcG9X/ry9+79whc+/42vff07/f3BZlWHMySoONaQIKbC\x7aCEUylxXHAtP6Bw71ra9vbjdaiU9MxFmsPeIdW2sSmLGHALEOdMQSIhEYvTsnJpz\x5asy1ACJ1XbCqspnFsizZzCSEnLPMpCgKPnHiBF+8eFGuBeG/JgkAAP1+H0tLS8bc\x70m4XaBRJLUmS2KSopKRpqiEEa+pJQpihRGIxenNObVJ/0mIkI1KJMQoRCTOXNUXp\x5aJ0TDIpGrNZYCQFzNOFKmGMwdWmSdPOkxcbh0toPfvTQQw89eO70d0/fNxwMH7i0\x75/Xo4z/+8XBhYSE8/fTTQwBueWG5O5PNtPIjuR+Px4cXmJaB1l0A3Q/YfN3zaCPt\x42JmBueRMuffVM1KcO4o5zGNkWwBO4VSrj/7h+jj+jsU7uuHYVnu3KLIbb7xR19fX\x517d7FGVZWW+hW22+eOHpT3/6n7/5yIMPPbJ5/sW1vN3edZ6cBkkg4mKoxjHWVVAL\x4ahJrjcEC10JSkVkuomHSowtmXFeVCkDa7AuMVdWYSYF6MpeVHACA1HUdnXPsnItp\x57sYQiM1MisKz2Zjn5+f50Ucf1TfiysObiQAEgG699VbE2Edd11bXs9brkcUY7SAu\x55Zbe0tSEmSfNFViSJFGzqEQEaVLxVNUbM9Q5NWavzhm1vG/HaMEhMJtJCrDEyEzE\x45sFMwiYWOZYVV/XYRHRhYa4902qPty5vPvmVL33+h05k1O/3x9vb2xUAW15ennE6\x7aiBjwXbO78JAzx2Kb99w7Fi7KLrJMRTm0PNl1k9P+SO37IoMXyQ+0+diN+II/w8G\x73gwk2WKS7ZRlfXit2mWbwhwleYx+ULey4XA77O9fLnu9m3X70kb98EMPPr945PjW\x33OxskqbkYh2chLrmqKVZrOo6VMxcQ0NtUQKgIUBrxBgDEBPymWoUM4sTYRezSpu5\x68SQJifemsamGIczMTUCOeDx27BxHa/K4xfsOD4dDcc7FO++8uX788cfjpPWpXWvC\x64q3hcEYRra6uuu3tbS8iFGN0zEfc/HzzHk3oh5g7ronDNzVxYow+y7Km4JNmzswo\x54WXymrqDzDOzjLxnb5YSUbRJoS4nIk5VXZqmZGbUJHWzAhmIonnv64f295/DxkYN\x41Kurq+mFCxfm0jSVuq5DXlVXEhpS77Xa3Y3ngXoFSAJAHZxI9jCYe18+95E5av3S\x55xh+/bFSnjqGfrkBhAMhWQGyvaWlZDYEDwAVs+9mGY9DJ3GtsjUyG29tbY0AeCwv\x4a+9aXLwtNctU1Zklk7WNzaQ6p8yNiygiEila7nJrTmcBEZEY/SQ/N6hzzkJwVz6H\x45CRNUzlI/nHOWVVl4tzIkiS5kuK6t+ctSfbVOWdZluktt9zCp0+fZlyjSK7BZzps\x48v3a2tphk0nLyzN+PB57ZnaqCwQAc3PBNUftfJC2KKMRuZkZwKycCHzmzYzquiaz\x46jVkKN2kQfMVYUlTXCGWan1FQRCRxRiMWQQY1di4UYANAKD+2bNt3+loXddhcXMz\x56vPzSS/LuL+Zi56oZvNer7U8ytIKRjn2yi04Uzg2QJksSHTBAzrXjNPdBGQesPHc\x58D4zRCKjnWE8dYrMLAnPZzEsjTUr2pjvtPItbNUAIjY2bIj2ME19u0kvZUpTpYOx\x4eIqBjMiMKJiZUeUqDSFYk7SSMlCgmRvRsizlIGOLKNEYo5mZHr4KkWVq/X5bnds1\x355ypKrXbLTl/fjMeBDbOnTtnuIaR4NrG1TFi2tjYoJWVFQshUFWNnYjQcDg/WZQw\x61cDnrderPLO3A4tQll57vQnDtHDMmXdOnFkx0fCpb7cxCVUDZkohNMJzqGyLxBi5\x79Wc9bQCwvLycqSrl+/ucAz4sLHg3eWaBkFVVZCJ3ZJYTC25mUCGcxMW4AURFjw0k\x45RJT7Mna5IpIt704X2VceOdspCMzLPmTIWCvqtQvumw2AOJrLbzo4uId+c7OUxGA\x71Y5DjA6qmUsS9swtoknq5EtELu1gTHVNSqTWkHsozfdsgNcQMkuS6qBmP/I812au\x300lmW6YAkCQ7lucdOajokGWZHVJkdo3L1zVPgFdqlanr6+uH80dpZWXeNYSo3EQ7\x55VHM28KCXDHXMUYNodGEqkqqLS6KBM4563TYEVW+KHTSq6CDTocONP/E3FeaND18\x44l/covF47LMsq8tWy3XrOjkolFXE6N1cleUi3mmeBlPvTSjHQgrsch+QWq3sOImB\x4fKSArgJ0AUhdS9J2SNsuCbVL04iFOnmevS5lGW85Z926m/R9X12Mda9XpSdOrGTr\x36+vBOVc55xQIVNfRH5D5/2gVM/LeTxLTaTIHTU7uaDQyANpqCdI0V+8bJbK/37g1\x6eU5TeCvPoY2wL2J9ff2KsK+urrpr1LV+UxIAr6JFDrtJdECIyeRje3vbZ9lYx+OG\x41CJCzPPugBDN/iFc+YGq6ppqor2eEjO78VhtMGh82gPfNssgqmrdbteqqjoITfqL\x46y8GALq8vJwOm+R5jTG6NE11tq51UNfUQRXVTJwmqXTr9lYy5+f7fRWySryruSAV\x4cFEfdTubE+cq0pErzCi1DMC41eKW97YLIPPeKl/FuXxOY4wEQMbjsWvGcTSOx5dp\x66h6T3gu9lwmiqlKnw845Z0WRqOpYvfemquj3UzUTWljI0e9n6tyOVVWFNG00fp7n\x31u12dSLsr7QuBgBra2vyRp/uvtUI8Fou0csw2S803sehKNfq6ir6/b6rqkjNXiE4\x56SXmI85MKE0vh+b8YNYDoG73pW3HgQYcDEppSjh6O3fuXDxkgQSAbWxs8Apg64Ct\x41NQGbBunrLuoVDF7MXM9BtraSsYSVIHYJMvDCLAMFzXrHOvAo7C2kQtkLVUXnNPu\x78a5gGaiqyqVpaufOnRMAekD4siwJgJudHQgQQlm+nPAHEJEDC4g8D+j3u6oq5Jy3\x4cNtTVaXx2NncHCTLFg0ADpTLysoKTYRfrwqg2JtJ4N8MUaCfx3jczzBuWllZoRAC\x78RgphOCa0o2TKM7Et93Y2Di8+HbIPTvsjnm8lOtgAOgmIO0uLiYVs0+D76WmPiPH\x5a8vd8v2t4792JMnvfHR8+WtDVJe77cX5MuOyE2MO70PpnORJIn5np16fuEhrr5w4\x51oeeh1ZXV6ksyytjEhESETog85UIw+RzmqY2NzenEyLhkJbHawi2/j/fT12gN9Bd\x30lchwitmHa2vr9NP6YK5qz5f/f7qAx7Lm74Glva9Jp1KVNOkdk6PoNNSkFrTFEEz\x7aGexrDhxSNW5WDsnqfc62MmkOyHs2kuJI68WOjYAtra2Rq90tnKVpqZXGScdIvGr\x75Z1vesF/qxLg6sWRV1hsd5X5/lkiFvpT/K8dIoqLAGVbQAavJZEmLkSYdzOtJHcw\x4a4AyzLtezEhaKbQEOxe7Zg7ec0SmGy+VlaRD2v5l3s3Pcsj4KhbktcZnb1E5ecsS\x34LUWUH4B/3MgSHoOkJuwRRFwc9STmohyK51Y4o1AHs4xSJxkWcvVrEZUes8YeAnY\x6btmXpwvSz+H57DXIYbjO4DDF67onWQacYIkYi05Ho9AGSADnqXlRIKRwnAPEY8fB\x4fXFElsK9ksvxet6jsetxgaYEeJ0tTwaYojmRHQJSHJgGcuyM2kpSC8w5wEYgUzOi\x50qyFRGcBWZ9Ema5nIZ26QG9iAqwDEdjUU0BS4FiSuZJJMheqQl273Vy8bIOGZR06\x49Dck0i68bmHTLjbFtnQ6jVML8Gbff8hRQFrYkjDy7MlpBTIFqQIWSpKkR6oAzY5G\x64cRuONncYpsK/5QAbw0SrAF8AuAMXgKVUqHUdisj74E+ijJxTgM8jwE+CsjawTXO\x4baYEeAuRQMbY5XzsuQ2QOOeTNKM+YOMB6RH0w3mA197AOjnTPcAUryf0IhCPoU0O\x33CqqQc2+FQBojgSPNrfXrrmkkakFmOLnCWFsxj6Ksu0oTxA9gKqFRKfCPyXAdeEK\x48QO0DxTzaad1oj17OwAtMMPTqZkS4LogwH82mj4mLklyl9wAwN+IjanfP90DXB+g\x69ZsTgCGFOADgTzcJCjSdnSkBrhMOwAZ1vZsl9AJeCnlO/f8pAa4fDC3uJI3SZ1yn\x6c9GmBLiOMTLdIQvFdCamBLjuNsIAoHPJwNcyJcAU1/VeYLrxnWKKKaaYYooppphi\x69immmGKKKaaYYoopppji9cL/AiU6cvROGvZoAAAAAElFTkSuQmCC" },
            ["\x52adiant Halo"] = { file = "\x6eoir_cursor_v2_04_radiant_halo.png", scale = 1.45, data = "\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\x4fPfkyZOj4XA4UFRUpGaz2awDBw686/F4uicmJiZ6enp66XQ6Mj09HfR6veEsb/5z\x49ncMBkOiVqtL/H6/JxwOOzo7Oz9ub2/vLy8vr2UwGIjP54tAEMRubGxU9/b29r31\x31ltHT58+fVGr1ZKqq6v9OTk5rtHR0fTVBsKfRw1A0ul0pLGxMaytrQ0DAOAMBsNe\x55lLSX1VVVZ7JZCiFhYUKp9MZM5lMVgiCknQ6nX/69OlX5+bmpgYHByNNTU3qt99+\x2b6hSqUxQqVQ8y5v/tCgShCCIa3R09KTVaqUyGAxw8eLFaSaTyWhvb3+9oaHhLjKZ\x50DM3N2dxOByR0tLSnJMnT/bqdDrlhx9+2DU4OOgAAGCLOQhYp9MhIpEIv15+wPUS\x41AhFUfn69esLJRJJ3rJlyxSxWAz3+/08Go0m53K5eSqVKqevr8/LZrPz2Gx2DovF\x59opEIoFYLCZBEOSen5+f0ev1kaXabeBmFoJFmqd1Oh1mNpuPs1gsrlgs5vF4PCaH\x776EqFIpl0WiUbDQa09XV1TmlpaX1oVBofv369ZIvfOELPjqdDg8NDS0sLCzMLSws\x6aLvdbufnTQNkBgcH5/R6fYTL5bIVCsX9TU1NTWKxGITD4UwymUSYTCYoKiri5+Tk\x31NBoNMjj8SQmJyervF7vFJVK5ZhMJufMzEyW+a8jxsbG0olEIpmbm8vy+XwcNptd\x72dFoVDU1NUXpdBqiUqkog8GAHnjggeUoitZyOBzE4XCA8+fPX7x06dJ/BAIBw+jo\x71DdLSQCKvv71rz9x6tSpUY/Hg2EYdrXQjVgseiNmZmZS8/Pznv/8z/98Izc3d9O1\x64S1ZXD+o1WqJRqPZ/Ic//OFtm83mmZ6eTuE4TiSTSSKdThPpdBq/2lrx9OnTQ1/7\x32tf+FQBQuFSu/3o7wdCePXtgAADVbDanJycn/U6nk5qfny9nMpkkCIJAPB4HZDIZ\x73Fgs0tzcHLW8vLxi2bJleTMzM1YMwxzZpNf1Q3l5OU+lUq3Yu3fv/2lsbNzi9Xqp\x47o0GgSAIJBIJQKFQAAAAstls6VdffbXzww8//HBwcPCKUqlcKCwsTJjNZuLzLgCg\x6f6MDUCgUMpvN5rDZbAaZTKauXr26sq+vL2g2m5NqtZpqtVoxEokEoygKZTIZqLi4\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\x51RAwBEH4O++8s1KlUn21sbHxUZ1OBzMYDHJPT4/ozJkzv2UymYLvfOc7/yEWixOp\x56Ap4PB5YrVaL77zzzpXLly9fxefz6dPT094rV670m83muNfr9aTT6URJScmyBx98\x73O5qGDKZTOKDg4OBsbGxKywWK5FKpUQUCoVcU1NTdODAgdOBQGDo9ddfv/zII4+s\x46IlEDVVVVY2NjY3sK1euBHt7ezvdbvfl3//+9xd37drVzOfzdbfddtv63t7esXg8\x6aiEI4kylUszCwsLampoaPoIgMEEQUCaTAa+88ophYmKiG4ZhmkgkEms0Gsry5csr\x63nNzRT6fL97V1XX2zTffPG+1Wl0CgYAgk8mY0+mkP/vss98OBALu9evXf7m5udk3\x4ezeHWa1W/Pz583+wWCzP7Nq169JV+v0ltC4qKmItdttz/eu//usGDMPoP//5zz/S\x61rWUmZmZFMieCf7LsWfPHvjVV19NP/7445sBAP6nnnqqvbGxkdXT0xP2+Xzxv/R7\x39u7dC/H5fDKXy33cZrM9dfDgwYUf//jHmZdeeim6du3aHBqNtuzll1/+yezs7AAA\x77JdMJv0IgkTz8/NzMAzTnj9/fthmszny8vL4er2+oqamJl+lUgloNBqHQqHIS0tL\x4fRiGEXQ6HTIYDL4TJ05cSKVSbhKJREsmk2kejycNBoNUKpUK5eXl1TQ0NOTJ5fKy\x70qamZhqNRuZwOKRUKkXSaDR5qVSK0tLSUlRcXLyGSqUyw+EwB4IgIhQKOTOZDObx\x65JyTk5NeDocjzsvLY0SjUQKGYWh2djatUCi469at023evHlZaWmpOhKJRE6cONF9\x34sSJ4Xg8zsYwbNrtdo9FIhFXMBi0er1e49jYWB+CIAUAgO729nbjz3/+8/Thw4dj\x4b1euHKLT6feuW7funF6vJ9ra2v4ixvV6vSkWi5UpLy+nvfnmm+NNTU2ShoaGwiNH\x6akzp9Xp0qZ61IC1F5m9ra8O/+tWvroRhOPDss892NTQ00K5cuRL7a+zJq2aQSCSq\x39vv9o//6r/861NraSnrqqacwAABeWlpaOTAwcObcuXPnS0pKIiaTyYeiaNRsNsfK\x79soEAoGAn0gkorm5uY1nz541eDyeMIIgdLlczly+fLlGq9VyyGQyYDAYIBAIEGfP\x6erXb7XbL1NTUnNFoXAgEAsFYLJbx+/2e2dnZfofDsZBIJMKBQAARCoX8mpoabjwe\x78+VyOTIyMuIYGhqaDgQCHrPZbFpYWJgLh8MJq9VqnZiYmJ6YmJh3u91JCoXCTKfT\x58I1GI+Dz+RBBEKCgoIBbU1MjhyAIWK3W1IULF0a6u7tnpVJpqdPpHGSz2QmPxzPY\x30dExRCaTXZlMxikSifwnT56ciMfjVgaDwZ2enp4+fPgw3traSvrpT3/qLiwsjExM\x54IhuvfVW22LU6i8SAp/Ph5nN5nRLSwv1rbfemq2rqxPpdDrt0aNHjX/N93xuTaCr\x7aP/FL36xlkKhpF566aVBnU5HXhyr+ldDr9fTURSVd3Z2zlz97quRJRRFcwcHB0c/\x534+Ghgae3W7P/da3vvVoLBYD6XQ6FolEqHfeeed9Vqs1cODAgY/0er22qalJX1VV\x4aSQWJc3n8wGn07lgtVrnFhYWwl6vNx6LxdB0Op1xOBw2Docj8ng8NiaTKaypqWm+\x2b+678xKJBEEmk6F33nnH1N/ffyUYDDqFQqHc6/U65XK5kkwmI3Q6HZdIJGS5XM6V\x79WQauVwuZTKZAIZhAgAA9fX1ebq6unoMBsPMnXfeeadEIqG/++67rzKZzBSNRmOT\x79eToz3/+8z/I5XJbT0+P/zObCFRdXV2MYZhlaGgoeu0arF69ughBEOupU6eifwvt\x571tbSfv378d2795dCUEQum/fvt5r1yArAH+i3OGee+4pJwgi/fbbb09cJeLf+oVa\x72ZY9MzMTJQgCv7bbsUwmo9vt9hT4pNLzvwUGduzYUbhjx44nHQ7HXDAYTKtUKvXq\x31avXvvvuu+9ZLBYXAIC7fPnyTQ899FCl0+nEz507Ny2VSqNKpVLI5XJFFAoFJQgC\x78jAMJBKJRDQaTWQymWQsFosmEgkKAIBfXl7OYLPZIBwOg+Hh4Ugmk/HT6fQMjUaj\x6fygKs9lsJmXxhD+CIHg8Hse9Xu/CwsKCy+1281atWpUvEong3/3udwNdXV0nYBgO\x711Qq0Z133vmFU6dOnZ6bm5vj8XgUqVSqfP/9939y8uTJ6T+RnCIplUqy1WqNf0Z7\x77pWVlazBwcHA/3ZDu++++0oikQjpww8/HAFL7KTYkmqNuHXrVk0ikQh98MEH5sVF\x2bF9lE686y5/t9my32/9ckibT19fnOHTo0PcLCgo4t956a0t+fr46Go3ibrc7AcOw\x322azealUqheGYdDb2zvx8ccffxwKhZzRaDTOYrFo27dv3y6RSFQEQVgkEomKwWCg\x58C5XwmKxOAiCkAEAEAzDIJVKXRVUKo7j0nQ6nSIIghwMBm0mk8nndrvtAACFw+Ew\x48z169FgkEknR6XTa4ndt27ZtWxGZTHY7HI4ZpVJJstvt7FAohOXm5pLn5+cDr7zy\x79hmbzRaXSCTeP2M+Ytcy/yK9CAAAtsj8fzPDLu728Ouvvz5+2223abZv3679+OOP\x5a0C2NeJ/Z/41a9YoIpFI5uTJk9arGdHrdUEMBgNSq9UZuVwOv/HGG+OPPfbYzrGx\x73dMOh8MiFosT77zzztTdd99dLxaLC37zm9/81ufz9RMEYSeTyWG/3x+orKwsdTgc\x6atnZ2UAkEkGi0Sg9lUrRXnzxxdcGBwdt8Xicw2Aw2AKBgDCbzdD58+cXDh8+fK6j\x6f6NTLpeXzs7O+ufm5vwjIyMzqVQqAsNworOz8zSbzfajKOoNBAJ2l8vlX7ly5Qqr\x31Tr8q1/96oNNmzaxY7FYkEajOZVKpeTBBx/89bJly9JcLjcQCAQSkUjkeoUjCQAA\x4eD4+7tdoNHSZTMawWCzhpWJ9LAUNQOj1eg4EQYnLly97l8LuYLfb43a7PS4SidLr\x31q3LAQCwDxw4sP/o0aOOiooKPJFIUFksFslgMFx57bXXPmpubo64XK4MiqIwiqKM\x6dZmZkVQqlUqn06lIJGJvbm6u5PF4TK/XO1dTU1OcTqdj4+Pjs0VFRfkjIyOzOI6D\x76Lw8Xnt7ew+Hw0nYbDbz9PT0SDwed6ZSKRqCIAhBEHaj0RhGEAQTCoW0l19+2bRz\x35861ZDKZEo/H7a+//vqcyWSCHA5H/7e//e2fr1y5EhkZGVlwOp1LoSSBAABAx48f\x74zY0NPArKyu5/1vtctMIQF1dHTsYDOIGg2FJMP//N4MJGIKgyJe//OW8ZDI5dPTo\x30eGHH36YKZPJwvPz86zLly/bnE7ny+l0ehTHcRCJRIDZbMZaW1s1AoGAS6fTQ+l0\x57hGPx0UYhlEgCPJwuVyCRCLxDQbDydzc3JxgMJg/Nzc3arPZFsrLy5ez2WwcgiAP\x41IAmEAjUFAqFSaFQfLFYjJubmxt5991357RaLRyPx+F0Ok0cPnz4OaFQuBIA4F+/\x66n0iHo+zX3/99f6vfOUrE1//+tdVra2tM4umJL5UhKCzs9On0+mYSqWS9lnT6/Mo\x41PDCwkL6GkIsGeeovb0dBgDgBEHo7Hb7MQAA9tJLL4UhCMJbWlqgzs7OjqmpqZMA\x67ERHR8enn+vu7jafP3/+FzAMY7W1tXkUCkWRl5e3IxqNhs+fP29obGy8HYbhtMPh\x4dI+NjUWtVuskiqJkEokUvnz5cvfu3bs3pNNp98DAwKF0Om3r7u42IwiCWq1WCwAg\x50TMzA2ZmZgAAABw+fPhoaWkpUVdXB/32t79Nv/fee4HXX38dTyaTH6VSqTIAwJn9\x2b/cvpTMfBAAAjI2NRRZ5DwbXuVTiegsAvhR2gT+G1atXZ1paWpChoSFPMpnsAIsZ\x58wAASCaTcCqVGljsgflftJbZbE5XVlb60+l0xmazAYPBMLtixQppJpOpmZqamvV6\x76dMajaZodHTUMD4+7ojFYomysrJKp9NpGh0dNWUyGa/P5+s8cOBAe3V1NQRBUIBK\x70SJ/JIIDmc3mgFwuH4ZhGAEAgDvuuAMHAEAGg+FiMpmUtba2ku64446lWpa8JM5a\x33yjnAa6LY85kMlk9PT0Xzpw5E7+W0WOxWDIYDM78Ca2FDQ4OBgEARGtrK7awsACh\x4bBryeDwzcrmcQiaTGTiOY0qlsphGo0Vzc3NLMplMhk6nU9hsNhIIBGYQBAkqlcoA\x6d80m+vv7E3/CNCQAAGB+fn5WIpFA15oZbW1tsdWrV19ks9ksAMCSsLX/nEa4riZI\x6ctf/NBwOBykajdo/u1hDQ0Nxs9mc+J8WVqfTJe12eywcDocWFhbmotFoesWKFcVW\x719WoVqu1a9asKVGpVGqv1zu1YsWK8lAolJ6bmzPG4/GA1WqNr1q1KvU/MYrVao0b\x44Ib4Z387FArZFxYWSNlVzGqA/83OFOvs7PxjjP5X2a1DQ0OWVCoFkUikNIlEEtfU\x31BRlMhmb0+nUEQSxUF1dXYwgCJ9Op6e7urpGYRjO/I3X+ykMBkNcp9NllppvtdSQ\x33SH+DOx2e+Z/wzxXnWMul0u32+2e0tJSUmlp6SoGgyGUy+Xqjz76qKuxsbEKAECJ\x78WLzvb29H3g8nmAikcDMZrPvWuf6b8Hi2Vwou5JZE+i62qiBQCCoUCgCHR0dURRF\x34c7Ozgu9vb3DMpmM29fXN9zT03MeAIAYjcZETk5O2Ov1hm8mOzsrAJ9zAXK73ZH7\x3778/GQ6HUwAAcjQaDfv9fsctt9yy3OFwWGKxWBiGYTgcDseqq6vjbrc7kmXerADc\x54KZUqrW1FQcApOLxuJ1KpaI1NTU5PT09g3V1dXl0Oh1JpVJuAEBy7969WHFxcTJL\x74awTfDMBW8whpOPxeFQgEHARBKHPzs4uVFdX87lcLi8SiYQAAPhi4R6WJVlWA9yM\x77KPRqItMJlN9Pp9XJBLxvF6ve/EEmAuAT0qRs6ZPVgBuWmc6GAy6KBQKF8fxtEQi\x34eM4HqdQKIxoNOrKkikrADc9nE7nAovFooRCIYzP5wuCwSBOp9NpdrvdDsCntfhZ\x5aAXg5oTRaLRSqVQyQRAEh8NBwSeHY8jj4+O2LHWyAnAzAwIAgJ6eHlcmk0kRBEEF\x41JABAHQYhhPd3d3Oa9+XRVYAbkrMzMx44/G4B0EQcjqd9kEQhMTjcZfVavVlHeCs\x41HweEAyHwzY6nc4eGRlZoFKpqM/nswEAwov2f1YDZAXgpkbS6/WaWCwWqb+/f5zP\x351O9Xq8RAJBNfmUF4KbGVdMmMz09bSSTyZDL5XKiKEqemZkxgf+f/MqaQFkBuKmB\x587582Z7JZEJqtVqUTCbD58+fX9izZw+eJU1WAG5+NUAQxPj4uC+RSLjUarUgHo/b\x54SaTd+/evdmdPysAnwtAAICA3++3KBQKhd/vnwMAhLNkyQrA58kXiM/Pz0/n5OSU\x4fByOSQBAMpsBzgrA52P7X6wKHRwcnFpYWBgYGBiYAQCks5S5fuo4i38+zYny8nJl\x50B7PZzAYM4ODgwvXaIcs/onInge4TkilUkE6nW4nCCKQZfysAHzefADAZDIT4XDY\x4ezU1lU2AZfH5NIV0Oh05a4ZmkUUWWWSRRRZZZJFFFllkkUUW/xT8P/v/AGpd6xso\x41AAAAElFTkSuQmCC" },
            ["\x4doonblade"] = { file = "\x6eoir_cursor_v2_05_moonblade.png", scale = 1.45, data = "\x69VBORw0KGgoAAAANSUhEUgAAAMAAAADACAYAAABS3GwHAACT7ElEQVR42ux9d3xV\x35f3/5zn73D1yb/bkQuCyvWzBBAeg4MIGtzha/NqhtXW1tr+Qb2utbdWqtSpdasVB\x36l6IIoTtiOwAIQQyb27unuee9Ty/P5JojGC1RQ1++bxeeSWEm3vPec5nvj8L4CSd\x70JN0kk7SSTpJJ+n/HNEnj+AkfUWEjsFfqP9r2FzkSTpJx5ufyKCfqf6f9UGvIyct\x77En6NjH80X6HBjH6wM9kuN3ASQE4NlHD8IGhYXQ26HOua4Dh6f6f8XD1OE4KwLGJ\x44MNrQsP0jNCJ6mKfjAGOfibk5DF8Yd4Zel5kUKB7tN+fjAFO0rdKCKghTD9UsQ5H\x56/KkBThJx137D3WHBgsFPikAJ+nbRPQgJifHYP4TgqiTz/L/nNY+HqQfg/EHu0VD\x66z4pACcZ7Bul462VcRVU0UcJdI/2uSc9jZNMfcKfw79Leg1+3UnFepL+zwfHJ2OA\x6b/Stt0xDNf9Ji3nSPfjaFBf6Fp0N+qaE/6QFOP4P/Os4U/IN3t8XufehcCg6jvdz\x58O/9ZCb4ZAD8n57J4CzwYGV6QqE+JwXgxBYANMyvDZ0UgJP0bReAE7YS9CSdpK9K\x34E4iQifpW0UMQBVznBj/pHCcpBOOaDg6uvXv3J9/lz1Gw+HGTtJJ+nfaeTDCM/h1\x35CivGfp3w7rB6GQe4NsRiB5PGsqsqKqqamh+Y6igIICqozW+EBjmpdEnfbHjc4Zf\x64T38l3nfoQ0p5N9c75dpVTyaRifH+IyB12rD+eGdtAD/vZIgR2Gsr0IrEwCA2tra\x661cG8e+0LvkCP/87YR/8GeQYZ4W+DQ/3JH1xrfxFBODzWgTRZ5mxipk4MWYym81s\x65Xk5bm9vjzc0NGifYxUGvz8Fn21aIf/hfQ59D2qIAHwZSzKsYoKTAvBl1DAhCADQ\x2bvXrqebmZjRq1CgCAFANAFBdTQAAGlesoBoBYNmyZfry5cup5cvHkvXrXai5uRkB\x41HR3d6OxY8fqe/fuJU1NTai+vh4fg3mQz+djAoEAU1ZWJlRWjs9zudzFuo7lVCrd\x65vhwU+/q1auVYwjA0TT1l2W8z3v9UGE9YSdpoGHw+cPu4PrdDKq6uhr6eLsaI4S+\x71sZutGrVKioajVLd3d3oyPojVFl1mVJXV4cHMTMNAGptbS2VToM7lYrm9PZ2ZrZu\x62evx+xszR3mOg1Eb/B/wwxd1hwZbG/wlnuew6R0+aQEGMX11dTVVXV1NEEL6MV7j\x6dDppbIkgirN5jpNUVbNSLMphaMZIMGZYnrOwLBdXZc2wfdeOlFE00O5ct51mUEKR\x6cB6gSJSjmVhvTzh46HB7QKeoYF1dXRAApKNYG3r9+vVo/fr1+K233uIBALZt25Yd\x78DQsgIfy+ay4sbFRP46oy+cx8YBg4W/Lc/+/LACo36Whli9fjvs1LgAA1NTUiOee\x65+4ot9s+URSF2byBH2uxmMoYiipwWa1gMBqBpmkghAAQDBRNga7pQACAEwQAANAU\x42TLpDOhYBR1rQFEU0AwNLDAQjyYglkgRScWpaDx+SFPkPZFwrB3r+kFnjvNQwxvv\x37fntI7+N9l+OFQBSS5cuZQOBAAkGg7ixsREDAHi9XjqdTlNtbdNUgHo8SCOjLxnc\x2fjsBOFa8MaD5j5YfOJpr9J/ETScF4Hj78evXr6fnzp07GJ5Dzz//xpSiIucZqipX\x55xQ9iWEYOyF6mqJxC0UhSsfaYZZmu3VVT0rpdCotSem+98MS6JjRAYscx3EGwWSj\x4fXoEy7AgiIZiAL2EosEt8AKTTKeTCBNsFA0cRQOjaSrDsgwCoEGRVeB5ERBFQTwW\x365UV9cO2Nv+H697d8M6HO5r3btu2JgIAMHXq1LyKigq2rQ2Htm2rz/a7RwT6JjWg\x71qoquqEhhQAadfjqcPj+BKqX9ngU1NLSosAwnfx2UgD6adWqVXRNTQ0Z5MvTr7zy\x78myPx7No+/btTCgUa54yZdxIQnRZ09St2Wyq6e677+tsaGjI/jefe8MNN9jLR5WX\x46hcW+DhGHENR1ASzSRhtMYn5JUVuJpGIEo7jNZphQVE0xLEcjRAgluGBplmIxhLZ\x56Eo63HK49WUdk40/+cmt73V3d8PcuefmlZcXctlsIrJ58+ZAW1tbtk8jV/W7KQ14\x53JA6eET50XIXR9Pw/QNufRSAiQA0aPCZqW9VCKBBh8/PN5wUgK8xoP7Uwa9atYpe\x73mTJxz59ff3LE9x5OUt4np0BmNaMomH7/ub9r9bUXLjl8wSn733Xo8bGZvTqq92o\x75roaAwA0NzejPXv2UIsXL9YBANavX88AAF6+fLl2/fXX0ytWrFAHv19NTY3pkosu\x47mG1m2YYRX6hwSguzMmxUQzLgCRlQNd1HWECDMsCy7Ig8AJNCIFEKg2IYiGWSOxN\x70TPPv/fezpd/8pOf+GfMOC3HyLByQXlBOBgMplavXq0OcVF0+OwEty8D11L9QgAA\x6adogGHTwmeMvAMOeFICvGA0YPKMSamtrYcCvX7VqlWjPyT0HMJzPsiyiGLQ1FIi+\x74XjxOYeGMDqsX78eBYNBsnfvXrJ8+XKCEDrWdeMhsKN+FM1K+hElqK6upoLBIBks\x6aACAbv7Rj6ZPmTp5SklJ8al2u/n0nBy7G2MdkqkEBgBithhppAOosoLNFiNFiA7A\x73BBPZGR/V2D1Rx/semr1W++0vvbWW34AUBctWgR+vz8Tj8f1lpYW7ShaHf+bMz8a\x78DmUmY+19OJoiTD8JRXYSRj0y1MV4/F00S0tLVptbS2qq6vTAAB+97vf5ZV7Ks9k\x4bHq6yWhsxRjenj9/7p5B8QC1fj1Q69d/Ogj+AoIG8NmZ918UD0c1NTXUmWeeSdnt\x64jxYIH784x/nX3j+OZeLAn85AJ7EcnQWgdbjcLrd8VhcJFhN5ue6LAAA2awMJqMZ\x34vEEyKoWiKfSazds2vzILbf8cg8AZJctW0YdOHBAiUajvCiKpvfee6/3cwJS9DkM\x655San0+5V4OFAg9HqPPb7AIhAB8D0KhXVVVRDQ19vmhtba1NYEynVIyuOJXoZPe+\x66bvX1NXVZQaC4IGHhRAi/8WZDWV4CqAWamsB6urqyBfUsqiqqoqqrq6mEokEff/9\x39w/AofwzTz1xlivXdbPBIIxmBd5vFA2UKqtGTdW67GajRxTZIgI6BqxSrMAjiuUh\x6b8rKwd7wqtWr33no57W/+gAA+KqqGlZRQk5BEAHjdFdDQwMe5KKgIfj9YPfmaP8+\x47mMPHYdODYk1hrUQoBOb+QHV1tYCAEBdXR1esGABv3TpdQtMBlNlR1fPhu9//5pt\x41y9et24dU11drf+HTP/vzm3oJOQvWhLwKZeptrYWIpEIu2vXLr2/5IF56aXXqt05\x6cktphlpksZjtvMhlwr29PQwDotNuz+VYlieEEI7hkKzIYLEYIRSKSN3++F/u/sN9\x663z11VdD1157LezevZvrVRQdYrFsW1uODtB4NAuGh/j3yOv1oqYmkQA0EviksO1Y\x38OZQN+skCvRVxgq1tbXUgOuycuUqHwXoTKDovfv371xTV1enDJQufEVZ3M8E3Tff\x66LOjrGxk6Y033rAD+j74SwpbDQ1QDwCgr1q1in7nnXuoFSsaVQCA555+7ntOl+VH\x5aeWF4ymagmQiFdNVRXM6bFaWZiARiycsVrMDY01nGJoxms3QG4y2vf/BR/dcevl1\x4c+bn52vjxo2T3n77bSU/38cCAHCcxrW1paW+ZJqJADQM1vqkqqoKNTQ0wJC4gXzZ\x353RSAI5/nDBQHqD97W9/czGIOwcxrCbL1Jvf+96SyFDh+BpyC9Ty5cvh1BlVZwkG\x777LTqmZcRAihj5VRPvY9VjH9UOPHePuyZcuo/Px8VFdXpyxYsMDy05/+4KbikpLb\x4dhmJqLLUkpfrGmcxmdjDLYc6GIahC4vyClRVIQhpOicYGV2nobOr5+UVf3tuxcaN\x57w6VjM/tff3p15O5uRN4igoSu92uJRIJ2mKx6E1NTRjAh/q1PTmKm4O/wH0MTo4N\x65yj0RLIAZMCHRwhBTU0NNW1a1akOm2UsBrL+e99bum+AGb/Cup2j0ocffshOmTJF\x58f36pkdNZuHqDz/aVPrjH/84MBSC/Q/ueaAVUVu1ahW65557qMbGRvWVN185ZbSn\x34kGKpj3hYO++wlzX6DxXTl5zS4tsNAiU0SiyBGNQNZ1gAkQ0GqlkRk407T/4j3Vr\x339/c1eV/PxjsCHV1dSFFUVQAgJYWjni9AIPcnaEZXgz/Pks8OK44KQDHXdMCQQgQ\x71Vq6VJhky5lWWlohxOO979TV1eFvgvH7/Xa6rq5O+9vfVs0eN2nSRhZ0SKejr885\x62daiqqoqZiAw/2/inIHbLy0t5efPn0+tWLEiAwB0S8uBn7Ese1MiEdlBU4jOcdrm\x55kBAliVMI0QhhAjGGPw9PSma44WS0lLW3xl4b+OmnU9f//3v/bOmqkZtPtLMtCeS\x78O1m8YEDBwaSflqf8HkpgCbc/+//xL0ZWjZ9UgD+CzcDIYTIT7//01KdY0a0tLTv\x65u21Z0KD/+/rvqYBN2vlv/412mnP3yKr+B/Rno73SksL7hYE/s0ZM2bcBACk/9qO\x5765jwYIF3MiRI+Ghhx6S33333VOLiwufRhROBXsDjRVlRWeYTYaCWCxKWJZBBBMg\x41Fp3dygUCYcTY7zeUYqsxfbubb574fnn319VVWXleYutsXFLoKysLAsAEI/HqT6r\x30DLA+F9myfWgBFwVc4ws8Un6T7TgDTfcOOHaa38w84EfPcAPMOA3KZCEEPSPf/wj\x6293GbU1PPvuvFwb+7/HHH//fDRs27H/99bd+PeCWHefzYACAWbas1gAA8PNf/zx/\x2b44PXz/Y0pTYtOmdla0tOzdL6R4S6G5Wujr2Kf7O/fhIy77o/r07eta98+bmwy27\x73plkiLy/deMjAGCZVzXPs3TpDT4AEEtLS4XS0lJh0qRJrooKnxU+neyjB7k5aAjD\x6f74g/uPvAwJLD2elPKwtwCDNjn72s19Wp9NS+MEH/7Drc4Ljr/36lixZwi68oGa8\x6es1Oy6oKUSTVzdEQQgyVDAQyrzY1bUnW19frx/+ZVdFFRYfYMWPGUG+//bYCAOqW\x4cRt+XlJSdFewN/CuKDJ0bm7uTJqmOQACnZ1d+4nGhG02+9jOzrbW4uK88vyCIvu+\x70oMb6u7647WKkrVOnjBx9CMr/vQSx3GYZXM5hkmwqVQq09mZq/WXQQx2a47WTkkP\x73RbDvnFm2ArAgHuxbNkyw6RJ0xYGAoHddXV37v860Z0vE6Dfddfvvdu2bUBEIklH\x51W6eJCV219fXS1/RQ/9UQZrXW0Nff/1sdNNNN8nr1q29pnLUyL8HQu3NWNMlRdYD\x2bQVFU3LddkdnV9c+VYbdJrN5fm9vV69B5G15+UWuSCTS9tyqF67Zs+cIHjfO63rw\x77T+8WVpqpjs60hpAAfj9jfK/cYWGtnoe656/jgECX4ro4cz8jz32mHXkSO8VhKD3\x66vrTHx6oqqoSnnjiCXW4WSmA5RRCGyZcddWVvznj9OqrC/JyJ3b6u1748MMPtUFZ\x34eOljD5TbxQMNoG0WiI/eeAn7CWXXPph9dxqyVNRfgkviHlHjrQ1mc0Wi9lktAsi\x370qlkry/p2d3SXHRVDUrYymbIW63M2eUx7OEZUjDvfc9vGP+6WfnbdjclLRaBVRY\x61OE6OzvlvopQP4bP9gQPWIUTUgGj46UBjzfzr1q1yqop6NpURnpp2bKrDtfU1NDH\x32ZU4nm4a/OY395xbWFhQKSWS8Wgs3rz6ndXbGhoa5C9xNv9NU/1A1paZPXs2WbFi\x42bz68os3jx4z8scud07+nr279+a7c0WL2VyOsY66/d2RgD8Q8o4dO9Jg4FFGSmOG\x70igK0bBj1/5bF5xz4T/Omnkh/fbWF6PnnHNOgcORZ37qqb83HUNjD22KP1YjzNFq\x6aU7YXuKvUJsC+sc//mF747W373jyyVWeryCI/MqopqZm9qsvvvLav57916lf83UP\x42KIU9CXPWACAW2+9uerA/p0Bv79Z2bp5zd62lt1Sx5E9eq//ANm7Y7N//duvtHcc\x32kkCnbtJ55FG3Hl4hx7uaSOb16+/CQDg2muvNQMAv3jx4tFTp57hHOI50F9AUI8S\x4bA8voocT8y9fvhxVV1eLZWWjbtAymRcvueI7B78hfP9LW63q6mo6v6ioyp1jmx8O\x39r7w6uuv+wEANTQ0kK9JAD7FeOfMPsf2p7/8+aDPN/lwYWHJJS6n05VKJ4AXWJpg\x54Nw5uWYpk9YkKY2sFgsLmCAKUaDpGOfm5Z0ze/bs6G23/2zjokWL7C+//HJA1zN4\x39OjR4Pf7+4W6BgCajjUD9GiMPiw1/XDSrKiurg6PHTtxaTKcfGPxpYubTwTmH6C6\x75jqsSFKvKHAgGgwWAIDly5d/Xa7rACqDAUBvbGzUt+7dCpdddpnlmmuur9+xo/lq\x57cWK0WhAGGOCNQKpVFIvLCxwWqw2VlEwsKwANE0hVZVJt789OMU3+YF/rfrXda+9\x39lpq0bxF5ZNGT3I1NjYSr9dLAQDy+VopAN+AJTjW9Qx792ZYCMC6desYhBBe/cba\x47xBimq/67iV7Vq1aRZ8ozL98+XIghJDx3vG5ZouVQSyVAwBQX1//VZn8z2MsqrS0\x6cEulaLJhw4bstddea168+Pwn3t/2Ya3Z7KBpxGKsE6Jpmo4xBrPJxCiKTGKxuKZp\x51ERBZBACLdDr3z1z5rS/rljx51n+Lr867pTJcy+99NLypqYmvaamhmpsbMQeT5zq\x79xYfc6AuOikA/4ZWrVpFz507V3v9ldUXK5oar6k5b+1/WUPztVN9fT1CCJFQNGTJ\x5aNKlhODUNwRoIABALMsSjKNZAIC1aw+pN998s3jrHT//Y0tL27OJRJomhBCzycQp\x69gKyLIPBYEC6jpGmaCidzpD8/Lx8VZOltJTYM2f2aS9WeCsMFIJgRVnlmYsXLy6q\x726/XvV4v3dLCkf5SiYHk3NH8/5MC8HnMv2TJEv3FF9/y8QZhxHnnLXiaEHJCMX9/\x38EsAAAKBQMxmt8lFeUXZb+AyBqyC3tLSogqCgDs7Bazrh9Crr76Kc3JyqJ8u+9kN\x77VB0jT8YTkRicY0XRQBAoGoa2G12GiEEDEMjTVFxWUnRtFBvV5vBwOI7bvvpM2vW\x72u3UVKW7omL0pGuuuaG0qalJ8/nEj8efeDweGj7dWHNClEB8o6UEe/fWkBdeeMIp\x69vDTjRvXPdoPKZ6wQ5dKykrYcDgcTqUThd/0tbS0WLHHAyAIAuY4jjgcDtSwsyHe\x454zdmMjIbe09ve2SrOo0ywHWCaiaCogiQFMUpOJxiig6Kc0vPKOlec+O0uK8sff9\x2flc//8vf/94cDyfSgiCU1tR839DYWIEBgHi9Xj4e51g4ARusvikBQABA1dUhLAiu\x2b5PJyNN1dXWR+vp6Ck5AXHgg2O1sb2d5ni+2mqzyAE7yDVkBAtCot7S0DDTGQ3Nz\x7337FFVcYlixZcgB09GcacaYjhzs6aYYFhBCRFQUwQkCAgGAQIZ5MEB3rfK4rf8SR\x74vbA+PHemj/+4ddXPbHyiY7eXn8MaaGyqqpeBAAQjYp4woRyN3y6hXK4gi3f/IWR\x56YRCCOnPP//87YqiSTU1l762bt065kRzfQZo7NixCADAarW6EKIyqVR8wDf6xgxs\x50yKkAQBWFAUBAGzcuFFfunSpMG/Bgr+HgpGXNR1RwWA4aTCISMcaaBiDhjFkVZVY\x72FbK3+3vpWneWVhYmJtMx7RZs6fcft/va0/dtu39VCzkj6dSKSMAgN/fKOWYTej6\x6166fAAD4KEWKJzfEDFBtbS0FNYAffPDBiUaT8L3Dhw/d3jedYf0J6/rs3buXrFq1\x69k5m0s1SJhPFFCUOp+traWnR2tralLa2Nn379m7a4/Ewr7/55t+xhlPRSDSYkSSd\x5ahiCKAp0jIFhGUhl0mpBQaG1s7P7ZYyJwnE0ZbebYG519a+nTp2KEqoaommaFBUV\x38TU1NezoiaMP55WUVP7sZ3fl9pd/fJnxjOj/igAgAKAQQpCbm/M7VZfvvfnmm2PX\x587+C/hI1M8PSBVqyZAm2mhylNMM4WZrq6keHvin3kj4KA1IAXpTJHNZGj7bSf/3r\x587fHkvE3OU7I7fUH1GBPMJyKZ9JAWKCABpZFlNVlFZw5zrwd23fVcwxHJRIpLTfP\x6eX/9d6/8+bZt2ySbzcZYLEVia2srqaurwwzDb7XbDfOhbzLHCYEEfa0CsGzZY0xd\x58Z3297//fZnJZKHPPWfxo7W1tcyKFddrcOLXhBBJShnisXgoncgw39A1DK63+dQk\x4fK/XS3m9fcHx/v0u3efz4XVvvf0IJjhutdk5jufFYDjYHg1HOxiaRUAoKh5PEJZl\x5avf4e9SeQG+ms7NL8/d0Z0aPGrX00YcfPXfNmjXxsa5iRZIk5PV6uV/+8pYOTVMi\x76/jF/06sq6vD/ULwZWKXb68A1NbWUvn53eRnP/uZKyfHeXcmI90LAGTs2LHkRGf+\x67SDYYDD1GA0mNhxP2f9LBv5vfP+jnmdTU5PW1NSkATSSlpbVpKKigv/z3/7Wkkyk\x2f+rIcVOiwWCwWq3F3X7/3nRa7jIYLEjTdMLxLFtaVjJFyshhg2iAYCAQRBRRx48b\x38/vRo0fb2rPtxqamJohGo0xpaamwfXvPWpqmpvt8VTnDrGz9qPS11QKtX7+emjt3\x72n77z269WxB4x3nnnn9rTU0N239IJ7QAuN1uKp128TNmeEucDrvB39Xxwptr1gTH\x6ah1L6urqhpWV6hMyHwqHe+k5cyZTaSm73+OpuNhgEMwcx/KKTLI9/t5Gu8M+iqZp\x57hB4JGUlkkpLLYX5eZ5EMpWIxKKRivLyUeUjKnBnTwift2Cha/Wa1e2TJk1i33jj\x32cx3vrOEy8/PXdjWhnfE423acHaFvhYLUFtbyyCE9IcffniC2WS6UVbVnwEA9n7/\x2bwNTyk5Yqq2tpbxeL7rkkjkjU4n0zEAwKhrMznlLliyhli9fjo5yxl9kk/pXSFWo\x71CjAYKwhjLHxd7/7nb+9o+MhwWBGQAAXFDkrKYZYegPBZpYxIIx1sDts1mxW1uLJ\x64JvbnZ+bTmSkUDgS9Y4cefMp3jGjEWLnXH75MmdDQ0OmqqpKCIX8H+Q4bPxpp40Y\x3039G/7cFwO/3IwCgy8vLHuJYvuncc859gxBC1X16Rv+J6v6Quro6ze12OUZWlvvt\x44ss6m8OUra+vP9a80X9n7b7KTZMA0IBpmiYUxZCenh55xowZ3GN/efwfoVDoiCCw\x79GQysIWFBZ54LNMZTyQSHC+CxWwS3DmOsaFQqEsQeN5iMxujkUjCbDbxs2ZO/44k\x5aaRJ3tGnAgCnx3VzXV2dpmGyId+dl/d/PQimVq1aRa9YsUJ99NFHq91u12mJROqP\x41y7RCcz3CPp2e9HLly9HGzduXLxw4bxnCwvzbzYahZvLy8uWb9y4+cknHnrCWVtb\x539XU1Aw0k3+TBWII+hbv0W1tObogxHW/X0PFxcXciy++2BuJhJ+02qxIUVXdZrWX\x41xAlEo5sz6RlUFWd2BwmN02RvFg8GnI6nXkcxxhCoWCkuLhw2sxZvpE60gtu+p+b\x53jftOCDV1NTQO976YGdGzsgAQC9fvnzYurjMV3TQAwNSqb179wIAgMNpvTGRjPsT\x69cQzAARVV8OJmPRCA00u5557Lv/000+LL730UrKgoKzJau1duH37Rya73c6HQj2B\x67oJS7oMPtqBnnnlGW7ZsGbtuXS154YUI/dBDD6lfQ8xzrE4rCgDA44lT8biRcTh0\x31LWrCxcVFYkvv/DGi06788dGI2c2m3mUW+CY0HKw7U2aokssNrFMMNDIYbflRqLR\x6epKSMhvHucRwKBpRVFmrrBwxt7Mr1OQuKJwKEOxqbbVTjY0r0ueJNV1nnnmmCSEU\x2fz9jAap8VU6fz0f1+364rq5O+9///d+RTod9npRJvrJkyZLUunXr6W9ijs9/w1D9\x32U2CENIRQvprr72G9364V/j5z3/uApytkuTEGfPPPvusadOn/dbjGW0bU1l500cf\x66cT95Cd3Fq9YsYKZO7dOe+ihh2Sfb5Fw88014ldsCY42uPZjobC2tOBgUFF1XVd6\x39V5l9OjR3B8eeGBvKBKvD0ViWNay2JVjLzOZBI+UlRrTyYyMgAJeEASWYWyJeDRj\x4ehkQQ9PGYLAnmuO0VpYXu92B3l64/fbbHY2NKwgAUF2v1LcGAlkKhnEpxHG1AFVV\x56QLHWcyNbzeEAAAVFBTQAIDLigtPc7tcQsuB1mcBAAWDwRMK9enfOYABgFu7Zs3S\x33AL7eQiRkqwkMwJN5aWzkpnhDKloTLqfZdk/eL2ea0xG4xWP/2XFDN7I2pYuPa81\x6ecz2ZjLqjjPnLb6/sTER+QZ6nDEAQGNjIwAA8gBQ6bSV5rgQVlVVBwDcEw68nks5\x35yeTaUOO023PdbumHTzU+i9XTmWcoTjBINB0YaHgTKVSmqapxOWyC5n2eDKTSZH8\x41vfFbR0HrysoGVEEAO0ANXQj1Ouwe1Oyf6fAsIS7j5dk9msZo01REtEBpunu7tbP\x4f+88s81hXShlsuGnV616DwDIkiVLThgB6B98S1auXDn7/fe3PkVz+CJFkUcR0CeU\x6cRd4TRbRkUmlukWGslNq5hotm15OU+TqWDQYszlMnsIid05BgXtaOpPgjSZhkr9r\x374vvrl9zX319PRnogf6arEH/5/jo0tJSlvNyxO8HlWVZEgwGweXyiiuffO5DgTdG\x65wORjqykoKLCIqsoiBU61veKogga1nRJSuu8wFGZTAojioDZbLaEgtGsy+UcedG5\x430veXbPuyBlnXOD0evcOZKP1qiqAGTNmCN9mF4gAAEqlAlJDQ0MCoK9ArK6uDi9a\x74Ohqq9U2J5XOvllfXy8RQugTCfrsb3YBl8v+B+/YippJk8bNZxkDFe5NP7lz5/4f\x37tvffm0omn6QALd9tHdkeY7DNJIhBPzd/le3vdf4w21bPrzxwL5Dv+B4w/uiIBod\x4fdbTxoypuHnt2jcWIITIunW19NekGQkAEI8nTum6/vHM/5aWFpxIJPTJk4u4l19+\x75ZtC9D4KsUpr6+EWRFFQXFiY097etpFhGaBpCjDWaSCYMhoNFMMA0XVdoyhatliM\x55Dai9NwDB7Z3s2xWTSQSdGlpKQsAdENDg96/43jYwaHH0wUijY2NiX6tiRBC+pNP\x50unhWfbKdDqtRWOpd/sZ6oRxfQYadh577K9zy8vLp0ejMS3QE/hDV1d0xYP/+Efi\x74PGTT6v9Ve2L/S9/aOeOzc8VFhVcuGP7nt9eftV1PwMAePC+P58eDOv53/3u5av+\x39a9XRvAi86TRxE41iIbvA8CbweDY/4b5v/RYkZaWFt3nA9zZ2dn/d15E02mSybAE\x41FAoHHm7uCB/efuRjg96enryVU2zmkymaZFQOM0wlJFCiAAhSFNVRAATKZOJIMRp\x30VjcbDKaFly4cMm4DdvWto0YMcIZCulJgDYVhvH4E+qr0DLr16+nAQDyXa4Lc105\x75YCY5o6OjrcBAJYsWXLCaH+Xy4UAABwO6xmaquqtBztumDLltJ+df/75h3/03Ssm\x66+eS8587cGDXxrvuumscADAbN7y/9cPdzYdiKnoiH/IN2zZ/9OC1371mrcdTuqi2\x74lZcuXJV5H/+58Yl8Whmg91iP/2mpUutS5Ys0ftdof822P3CsUBj4wAC50NeL0Bb\x575sqdfdgp9Mprlr1r3eBEM7msFv2HWh5k+PZaElJ0dmRUDgrcByIggAsw4Cmqtgg\x47BCFGCkrKwkV484KT5l10XnViyRJMlosOWaW5QcSnUNLNNC3VQAAAGBghajBYJib\x53MRTiiIH77jjji5Cak+ohpfq6moCAFBaWjyl2x/YUjX3zL8SQth169YxFyz6zjtd\x58Z0TrRbL9EUL5z01Z86cHITEyZICOBgIO5/d+MamU6ZN/tGHH22/s7p69qVjx45N\x545gwItXQ0HCk29+zkhcNYo7HYwUA6M8Yf43kowGqAKAR9y3F8DDxWJycPvl06h//\x2bEc7xng3y1CjCMFCPB7L8jwHLEeLWVkGXdeRqqrAsiwiBAPHMxzLcXI6LQUpCkHl\x4bM/pmUyGEWmaKiiwOY7B8ORbKwADbY233HJLHiG4RDQKGsNQRwghsH599QmV/Fq/\x66j0CAOA4Nms0mu/t09T1eO7cudobb7zBz5u3aF9Xp/9hm80+/s4771ima9gk8oaA\x72lE5Y0aPmtzW1tZWXT3rgWXLlrH33HMPVVdXlyGEoC1bPngqFIp84PF4DN9EXN83\x36LYBAABVVs4Sc3MNTNQVJRmepQghuqyor5nMxkJ3bs6IZCqBNU3BbrfbwDAMGAwG\x59BgGwqGQhhAGAtjE0LRKIQZ3+7sTZoth1hVLlth27T8UtliMlr7PqzlaoI++lQIw\x6fM2mTJxYlsmmBavVMs7tzPkAIUSam5tPqJ7RAbj20KHWhkgksgUhRBBaogMAeu+9\x39wgAgKKAGItFEoUFuedYrKb96Xi80W235yEsYy0bL/zTn+4fuWLFCrJo0SLSHwNR\x64XV1mY6OrnpBEKT+MyNfrwAMdIxVQSIh62ZzRjNlTaos92KEENu0p2mbyWwiebnu\x53oamnYlEQtF1HafSaawoCrAsCyzHQlaWARFipBDYzQZTcSwW6SksKjAuOvfcGW1t\x54b2QVZIAMLD3bFi5Pl+5AABLjWFY4qSRrm//aGfHFVdcYezHoE8Y6o9X0LPPrnri\x76ffeiw6ycgAA2htvvDEingqXcTRmDDw7yu3OS33wwd7NeXmuyQhpVGd7204lrVAA\x6fDU1NZHB7/noikf/9thjj/kB/pNlescrL9CgGY1xvaWlBRuNRtzd3a1XVFSIDz7y\x6ay5JVvwWs4ka6RkxyunMEWRVI5FoNEOzLOiAgeYYBmOKOOxOnuhyIc8iB1IRzdEs\x73dgMpwIA1tJa3Ov10oO6o8lwc4OOqwDU1NTQCCHd653hyGYyPo7jOR1DrHHnzsP7\x39u0jK1asONGK3wa0dqR/+TYa0OJvvfUWbzCb68aMGT2/rb19OybEIBiY+G9/+7PX\x72HZ+9r7925MGI2eaXXXac3feeWcxwKcXeqxZsyayevVq+Wu4h8/TunRf07wP0uk0\x6cU6ntREjRvCNjZuj4VC4mWNZQIjSM5kM1jQdpVLpLk3DmiiIQAhgVVHBYBARy1I8\x781GsomS5ZCqJrBbTTIvF4ghr4WxfP3L9sPL7v/IgeMYMbwUv8i6eEw1SSvnzihUr\x2fLfffrsMJyYN7m8d0OL61p/8RPlg27brFQVvGDPaO6WnpycgiqwdADABxa4TSS6v\x71KhMpBI3Njc3d3u9XjRkgfbX4Q7Qn/M5VH/JCgJoJMY2I2ZZu1nXdQQAUkd7x4HO\x7ai5gWBbJsqyqqgLhcLwjI2V6eF4AClGYEKyxLINEUeQB6RTNIEMmk1SdTqfnhu9+\x317tt2zbp8sJC/TgI8FcWOzLHU8sMQPy5BblloiiMTSZS+3bt2PMvAIKWLEEncuML\x4fYq5g1sRSvt8vt+N9hS+VlZWyh3p8JcAAMKYMKNGjsyJhGLbzjxz/psDI9S/QiRk\x59DXpsfz9o1JjY+Mnf+MF4ECR0mkwAgChKLo9lU5hh8MmG4wGMZ1KgdViLUgk0p35\x65VBkNlsRYEIRAuBw2hFCGExmg0FRFC0vv0gcVTmyCgA2NblPYQEaFPjs9pgvG7MM\x61wvQ33RdT2purhF1TZ0sJdNKrsvqGD9x3P8CIPgvsO7hiRAtX44IIVQ4lsLxpARG\x670DzHOPw+Xz6ju17f9N2JLghHkupVVVVwtixY1k4+mqh4+jPH/P35HOUVr8lqkJN\x54SIJBgEQyqgAoKfTqU6iYUgmEoqB4wEw1kSBzcWKLkXDEUx0hVZVmfT0BGSaZoCi\x61BBZkcKaptJIg4qKkuuXXbms5P33XyA+n88EAFBUVCTCMCuMO24XU9M3AwcXo5yc\x33Ny8Yk3BgZLi4lxXjq2776BP6Pr/z1D18uUEIYRZhr1AVXWIJxLAMozi8XjLi4pK\x46iqyEq+oKJ9z2XfOG9nU1KR8g11R6N+jQQ0EIE4xTBRjjDUA4Dq6uiImk5GiERI0\x54QOe42iTUTRommLSNS0rCAIihKBEIq6yfbECIIpiKYoyxOLRuMEg5s+qmlbW1tam\x44HxeZ2enAsdenXTCCgACAGhtbaUAAFiDmENTyJyb6y5Op9OkuflgOwDA+vXDDwP+\x445gHAQDd79KgV155+yKH03FpNBpKOBxOyGSy8bPOOiNv5nTfWfFosCKViCpnL7rg\x2fpUrV+Z8lTHXl3bf+qmqqooesAAeDwDH+T+2JBaDkOA4hpjMRl7VFGIwiggQEUSD\x34CIEpVmWBwAKdKxjWZZB0zQACqGsqshmm5UDCn0UisWaamtrKUmSpE+EbXg9f+p4\x48fCiDxfpAAD5uSWFBLARE2KMxqJIyqaPAABUV39lJdBfRTXl0Ra49bsMNQPMwzid\x6ah+azUaj2Wxke3tD2UxWyc3PsVVKmSQuLinMjUV6k6KBP8Nuty+pq6vTVq0iw2FW\x7asfX0NCQ6g8wGwAAQFHyKYZhCACoFotJFAQWyUoWI0QQACZ2uxUZjQZjPJZQENCg\x4bgqiKdqoaRrRNBUomkai0SBoOhbbO4+svOWWWyJNTU1sU1PTx3vdvF4v+2WE9EQQ\x41AoAoGlJ37aQWDiYX1xYZOZZhstx5kBxcVk/9FnzVTHvf+tXf942k6Os+azHy5cv\x52w0NDfKTTz7xm0QsctjmsIkaVpUcu70MaL2C5RBVUlzgsOa4nG+tefvJc84559Fl\x795axS5YMmyag/ufeiAF8AADQ0sIRo9GoY1yoAQBKJGQtIytYwyoQQhFNk8FoFEAQ\x65J5QRAIGAQYdLBYTzbIM0nUMuqYAy9D0/qaDHxbml/3wpRde+FF9fX32iiuuMAD4\x47ABATU1N+rfSAni9XgQAyGy1VBCCBaPJyClZGTRNlfoQovqjMRj5Bl2DL2KKj7YQ\x44urq6qja2lp25873N6VTidUMx0JOjt0CRDchmstDfe2/KJHKNr+5+p07amtrIRqN\x34mHy4KlPK45Gva8uSCRWqxWraisCAKrHH4phQIQXeCTwImIYBslylqQyGUrVVEXV\x4eRANIpjMBpCkDGCMAQCr6WRKZhi+wmQ0jpSkzAQAgI6ODuTxxCmfz0fDMNscc9wE\x41ABwbu4Eg91qqyCEOLNZSaFoCrLpNHcU/T90+/jwgjiPLRwDv9MjkQjatm2bxDD0\x47l3XIRgM9RUACmabLGMsyzrJJKSVK1eu9AM0MfX19cNhBEy/G1eFPo3eAQA0QigU\x6flVVRQBAd3V1oUgkGrPZHCgcjmR0VScMy4LFYuYohlYVRSEMwyCGZoCiKOB5HmRZ\x30yVJ0ex2m0GWs8RqNRUDAKPrOpvNZilJklD/WqVvGwpUS9XV1VEjRpRRNMvSNE1n\x599FYOCtlIRFPyQAAy/fuRUdxWwaWL+NhxvzwOWhFf4m0QwcAaG9vT/q7/XoimWwl\x42ASWZ/mu7q6439+ddLqcl/Vlf70afLNbUwZvaSQADYNHURKvt4Hyer2orc2IDQYD\x42gCK53jSeqj11QP7D7zfcujwPh0TzLEcommasCxjZTkWZbNZkkqlSVaWAWMdECAU\x44oW7s9ksy7BI03StqLJsfEUikVBo2sn3NeEMLzouAlBT04QAQLfZNGMsFqMFlkur\x75hbRCQZWENQvGGQOR/QHfVZ7AgKoovtnHUFeXl5hLJp4n2XoXoFnzaqa1osK3fYR\x46eVWVZFDdXV1eNCyvKOZf/Q13s/AM6cAgOn3y0lT0ycKKJPJUACARYOIuwOR94wm\x697OwIL+AAjYFCIGmKoymqLyckYFCCAkij3iWAwQIWF4ggsHQJooCzXMcaxCE0vkL\x35k7etWtXtiTHIvZVoTYOq56A4yIAXq+XAACZM2eOgWdpBgFCWUXRbE4HuFxOAwDA\x38uVjyTFigOEoBMe6Jtrj8TBeb5DKz88nAABSUkkighW3yzVV1eQsxxCW7s/LZtJS\x62NDDPlZS6uu4fzzo6+PP7VtyBwT6ivUwQJMeDAbJ7PGzDW++82bnzFnTF7nz8kbo\x57NWljMJQiAYaAUVhbNMkjTAUBQgI8DwP8XhSkSSF0gnqBoQJopCMAPW4c615AIAo\x68uIHPmuQ9UcnugB8qk7DH4nQqqqFEIXAIAgCAEBXd7cFTlwaKrS4paVQb2pqwk1N\x54aS2tpbZsGXDFoHnQkajkcU6IQRoo6IokJUzoCgyexQA4Ot0eY4RA0A/8tOCh1o3\x6auNwj9SjUxTFWk1Gb4+/WwcAA6GAzmYV0HQMOuiIYSlEMSwAxYCGCWSkrJZKZ2gK\x30QpNMbokycTv9/eYTZZ8AKDSelqHTw8GGxbKjzoODPKxVjnU1GRRslJa1zUFE9yD\x4dSaI0AYAgPXrXSdq8mvIWTVgACD19fWkqamJ2rVrl2SxWct1TYdMJt0bCkVkVVUg\x46g0r0VjMDwDw8Kfjn69LcPGQuIXqBxyofqtND0CgAECqqgCVlpYyglDItrS0KGee\x65aaVRuDIZtKKyWp0iCaR13QCCFHIYrZwNI0IQQBZWVV0QiCrqJlINJaOJ5JOjJFG\x4dPCIokRXTo4VAKhsNqschelPeAsAAABNTX05ALvdzpgs1l5E0alUOtNuMplQbp67\x45ABg165dNBx9NCA6AYSh/3vNx9qrtrYW6uvrlXnz5lXwnDApHAmDaBTzWYaz6bpO\x63vNyuaLColwAgPXLx36Tmm5wP67e/0WamppwPzTJAABqaPAhAACajhEAgDyn08Jx\x6aMFqtXGKohCGZRDHsiCIIhgMBoRohAhGkFUUyMoKUDTDRyPRDalEmiIEmHQqnVAV\x4cY1oWgcABiGkDHwWfHqb5AkvAGigDGLcuHEpXScGDSPHjp179zU3H+zgWDYfAODG\x472/UPg9bH8b+/yDItp4M9aUdDgdiKKSKHAsUQ5kw1hhNI5gQCnSs9gMANWSY3Nfg\x369BbWlq0/opQBNCIjUYjLiwsJACgOXLsbo5nWYqiaY4VCMEEYvGImpVlDTEcCscz\x65yLRZCPHsBwiOqEpxLI0ezDH6UIUxTIUYhMZSca9kYhmtVoZ3WhEiqKY+oUAvi0x\x41AAA8fn6TCnDMHaLxVyYTCZaR40agVmGNYbD0b5AsH74tsV9AZRqKOMPTL2DGTOm\x56tgdFp6igTAMnbHZ7YrZZKYYhgbqk5WvX2lN+xd05ahBX4P/v18AfFRTE0A8TtMA\x77GCilyEA0DQNa5oGqqpCNqNSiNB6R3tPx6aNW5+WJQWJggE0HWNRMAqKqnPBcDiW\x53qW0dDodMBiNVCKR4EpKxiM6nSa6rqcbGxt1+JxFHiekC/TYY4/pAABOp1NjGP5A\x4dp5oKCkqubKgMN9ht9pz+rFSgG8+6fWfBr/k05YAyDvvvIMAAA4fPpiWFQXbbU6U\x69KXrKUT30jSFKIoGBEj/BHHxfBN7dNEQl2OoS/TxfXm9EsrPF5mcHIMdAMBkspaJ\x6fggURWFd17Gu60DRFCTTKYWhqcz55577Y5bjR/p7AilNxSQWS6iRaAREURiraRqJ\x78+NRo2jQ4/GEfOrEcezu3bsTY8eO1QfFIt8aCwD19fUI+rSF7cCBfVsNRvPUZCpZ\x33NS0L6soyoQBGDA/P5+tqan5NpRFf3wPr7/+To+c1amuzuC2dEYDmqFduq5DMpkE\x6du6T9/Xr11MtLS3y16zxhuLt1Kc1/qd+T5qamkhRESWac0yM1VoiFhYVnoIQAlVV\x41SGk9gmFQCOkE9HIu1OZuLuntyeDddKbSWekVDqtEwyq0WikEUJsVpEjDoedjkai\x33bkjcgEAoLe3dygc/O2wAHv37iUAAPF4PChJakcwGEKqqvdk0kpII4rtygsucCCE\x6bJ22C62trfwJDIl+HLwlk0kEADBnzqzCbn9o88FDh1+3WYQLFEXOEqJDMNStdfV0\x66gjwcSUs+oauud8NqxqMBg1yhaqgr1Aln6Uoyvzck08evuOO700syHdV6QqGTFKS\x64UVT1KxMVAWDrhOKYRgqGo2Rjq6uXTTLBHRC6FQqFRYElqMI5tLJFFYkSZWkZEyR\x46ElVVRYAkNvtHuxKfnua4uvq6khtbS11yy237K0oqRiV43BOJYBxIplKAhDXhZfV\x6aAEA7CgroQHAcALFAkPx84+D3766FkChniDuDYbWTj7llF/QDKPoOtZohoa83Fza\x61rbY+zrhar4pbTdI0zf0l5zUfOpeqqoAAOrxggUzHCUlJW4AQEVFuW6TyUDJsqJG\x49mEJCOFMJhPieB5UVSGapnJGgwFhjDtolqEw0YmczQYEnkuZzOa8ZDJ1kGFZMStl\x591IqJYVCWRkASL8FGJ6m/L896Ndee40GAK03Es6hWTolCJzRlWPPd7mcFrPJPBUA\x61DvHUvF4XBnikyI4cQLjj6/T7XarNTU1VGdPKCUKrMDzNM9QDOFZjiCEQBBFZLHa\x52iGEyPLly+khZ/113DMF4GWHBL6fgXeDwSAFAKwz11LE83wEABiOM3rMZjPE47Gk\x71mkpo8kk0DQFgAhQFEVZLCY6x+2E0uJihWEYhyRJislsJgaDJZdCTERRtC0IaF2W\x4ed2ek2M8cKAxCwB6Q0MDHm7wN3WcmIL0J1U0moZOnmdYgjERDaKZYShE0cx0AMAe\x70yfR0tKSOIGYf2gtEDUo7iE1UANHjgT2iwZuTiweJYFA795YIiFxHNt3KESLX331\x44cXJZHJINvxriYMQQJM+yHXrL3uoJwA+qm9m/8dJMS4Vi6U7OjpiAEAVFxeNU1UV\x6bolk1GGzGymKAl3HBAEBk8lgoGiKyUoZSCUTfppmHJqmR9JpCRuNBlHOyoeIjiWW\x349yyLGecOU66f3keA59Nzp3wAvAxlCVJmxAAMCF/qCceT8ayshTLypKCiUaAItPO\x50/986/319xOv18t5vV4OoIo5CmMNN2E4Ws0SBQBUTU0Ns6R+CTVjxtg8k9HkSycS\x42AOOO2x2XVOJqmMaKIqVxo+fMMXr8Tr7H35/IrBe/xpcIn2Qrz3wef1MbyIADeDz\x2bUBRFMRxnNjZGQn19PTIU6dOtdosxhmdne1pSc60MzxDJdNJHSMCFA3A0QLiaEQp\x6bpTVZVkTOdqhqQqb47S501K6JaOkAzpSDCzHUFlZ1fILC00AgKurq4cozOExIv+4\x61SKO46z5+flcZ6AzFY8lk5qmF2GdAMuwYDUbSxaft3A2AChlrjJHX1dQAwYAqi8l\x448eCSL8J/PzzLEE/I1WhZDKJZs+ebZIknbaYLVpJcRE10lMxjaJoWspkQxTQwDGc\x79LJU1mK29CPBNfzSpUv5r1mAEfRVftLwqSZ4gMZGCaXTaVqSpKwkUckDBw4oP/zh\x2f4zDWHPHo5FDGAgNQFiaYRSO4wAThBOpjMzxHMRjiSDL8Uaj0YAYhhZZlqOTiWRW\x305UkQmBjGDrAsryOMZEAACKRyLBrhjkuAtC/ARHc7lLBYrHQu3fvDmWkTC8hdApj\x79AIgcOY4aacj53IAwEWVRUU1NTUigI+uqqpCTU2uo8Fi/2m59PHawjh0c8tg9AQ8\x48pFevXq1fMYZi0YyDGVDFCgACOSsrGmaSiw2S76iyqAoKtfV1bo3momGAQAVF4/K\x47Tt2bCHAp6fEHafrpeHTdf+fOsf+qp+Briw8dWpVztSpRoff79djsRgeOdLGAIBc\x58l6yQFX1TknSOjmepY0mMyvwPMNxHEokpbSsZqO8yEMyk2m1WCxWQggIHO8URbGX\x70umcTFphzGabcGD/wQ8x4CTHcUkAgEQi8XVsw/n6BaC/04moqkpZrVakKIqaldQt\x57NPbM5msmkymNZpGkOPOOdUFLpMlJ0fLyckpBmjsLxNo0Ibg00MZ/8uYyv8WXjuW\x34A12I+Dyy6frAIAKCnJdjMBbJUnKEkKAYWjEMIyiyApBgAADoHvuuae9u7s7BgDU\x66ffd1XXbbbcd6kfO8FdgpY6Fs+NGaBzYEYaLioqEmTOnj8cYS0VFRVQgEJCPHDkC\x41GDnOGaqJGU7WU7wi4JopGgKhcJhiWVZiEajHaLBKDMsDclUap9oMDpTqRQAouSs\x6eG3TNI0XBIELBcPRYDAYNIpmyKSTbQCAAoEA+VZagAFiWQ1znINvaWnBNMsEE6lE\x726rKTDolHfIHetXcvNziXzzwC98Hmze3OByucYNcHgqGUWLkKP7/4EpKBACovxmG\x5aBJJTLBKDKKIAAEomk4DTVEMyyKgKFAUVSWEIIfDMdj8o68oEBwc8A5uNx14xnr/\x37Cb9hhtuGlFSWIAbGxsTRUVFcH7V+aZkT5K7//7fTwRMbFjX2liGLc7LLyhLp6Sw\x32WyQM5ksJBNyh8HIGAAxEAxGu2ialKqqDBzHSNFINJJMpXmOYzlJVgJdvX6/Pcc6\x789/rPwwAaPr06epwRDmOmwBomqZomsJBX5FVkBeFXkXTqUQy09TZ1f1hQWE+TJgw\x62klDQ0PKYrdZL798mbuhoUHvN8nDhfmPUQjnGxyko02bNiEAgA+2f9SZjKXSPMcz\x46EWBpmokEg0nEYUgK8uQSCQJQoi0tLQMDqS/KmEfYHrG4/Fw8KnBV59YV5/Px7pc\x4fdO7A9GdXq+X7ewE4NycPZwNq1OnTj1V1/BBJSvbCgrcp9ntNlsmIx/Ky891BAK9\x43QAU4HnaHg7GcTKZSgkCM5ZgSAWDodYDB1v1wqJCSzKZIKvXrH/L55syIxgOhHt7\x55QcAkLq6OvRtFQACAKirK5tRVV0GAJKXl68hRCU0TVUAgOJZg7z/QHNPfp77qief\x66NJNJNw0e+aUaQBATCbT4DJp9DWjQeiLxAD9tX6oL5taA01NY3UAQK+//mJHR0dn\x4aBQMEYqiAVE0CIJgSmfSEI3GQBQNAgCAw+EgX1Dg/lN49lOWoG/i86csLFVVVUvX\x319fry5b9YCpFoeB999WFbDYbP26cDWualr3ztjuLpYyan4inunPc7uqiojwhFot1\x73TSdNZtNTG9v7w5MNA7rwAQCgUPFxbkWm8NuyWblIEUL3aFo/EheXl4iNzev6MUX\x369doGkiaimNPPXWv1F8BSsG3eT+AySRTLpcoAAARRVHbtWvPTpZmQ7qmEZoRstFI\x68MhKNqFp2uTWjuYPnDmuygULFvDQ1yKHPocJv06NPzig/JiBPllr0ED6IMx6vGDB\x41i4ej2fy83MygsCLqqKAosjAMKyYTKQSdrud0CzVCwAAR76SXWxHOSMv84nWr0L9\x57D8A1KBgsJ5atGiZgWO4KVu3btzk9Xo5+bCsf/DBYW7NmjV6UXnRLIZixILCkvNs\x56otV0yXo6fF3iAbREwlHQEpnep05zjE5OS5QFBwoKS6ZQQBDNJ6IKjr0FhYXx2ia\x73iuyshUAOIcjZ7TJZNoDANjlmkXBfzYY94QQAAoASDQKEJSkLACgjo7W3n379h0E\x42B1ZRVajkUin1WaxIkR6xngqL1uxYoWqE91/7bXLZjQ0NGjLli1Dx8gvkC+B7qDj\x79Fw6gO9TzOX1ej9VQxOLxaiKigqR4ziF5ThMCAFFVhQK6cjlcloyUhbt2dX0FgBA\x597jxi1g49B/c25Aaoybtk9c3kL4vH5oxA7impialunr86eFo6KO//e1vifz8UeZG\x666P28MO/Wvjkk387i6aRo7CoZFF+QUEpohBKZyQSj8dyeZ51RaIxKa1kw2azsUBV\x64ZAy6SzN0ONSiRRoGmgffbRjczQcjhuMJlePP/DiFVdc67FZbfaurp5mAEAYHzDC\x4dE14Hg8BwAAAra2NicaGriQAQDAYlDZu3JFIS0qnYDQrPb3+DRzHsw6b/RSX23HV\x66ffcN2XDhrXrbTZL1SBNS+DfD05FX1KbfxmrMuT3jfonyaRG3D/R7ONAM5FI0K2t\x72SkAoHQEkEynIRqLZUDHHCGERKMptbPd3+V0Vprb29sHB6XMMYJU8h/em34M9Kf/\x790S2bauXrr32BwVqVmJvueXH22bNmiV2Sr3KlVdemVdcmHt6KpWylpWNnm2zO9zJ\x54FRnBZaKxVKaO9eZb7KKpkg8E7I7XCSTSRu6u/0ZlkWY5zk3VpCuKXjHW+vWvW+z\x32YREKnXw2uuvb5wxdepETdXTb7+9/gAAUBzmTDBMByAcZ9Pcok6YMMGQTqcZgGQ0\x6cUod4Hneu3//kZZoJLU7nkjpBiMN00895fePPPJIB0Ug/MYrb52xYsUKtaamloNj\x740wObeY43hYAfVFBH2BeRSlRAQBbLBaGpmnRaDRArttlUXVdZzkj6u0N/bTuN3UH\x66ONG5WYyGe2z71P13yaGhuLqA2jaZ87J6/VymUwy55XX394MALTD4dAPbNmSOf/c\x6389SFUm0O23TGRZPl+UEYShMAcagKSrkOJw8Q9OIQdAt8NwoScqkU6l0UpJlDiHE\x68+MJZef2Ha9ZLDnEaDYXdHZ211dVVTlYgRuZyWa6urpCEZfLKzIsIwyBub+tAgBg\x749tZRVF4AIBAINiiaVqupqkQT6TedjpcdFZOKxVlJdXPPPXU4n2N+54VeHZR7dKl\x51m/vemrQ1LCPNWQ/SqTDZ8d6/CdMTT4ncUbg05Pq8JDgnPrku5eePNmsVVVV0VEc\x44UmZzE6KokFRVcyLhrIj7d37Fp1/4UMLFizQEnIwMuj9tU80dcPRBoJ9mWTRUaYr\x56DEAXvrT19yAjUaX4+DBw8GtWz+SFi5caLDZcgsWLlxcWpCffyrWFIvdap4iipQZ\x6bwzQiCBd1cAgGGmKIKIrKsRj8V6WYcspijqgappiNplcAKBhBIffWr++0WRgLNsb\x64370/PPP95x99qKFZrPZnEymQ7t3b4qXlRlN/khUgWFK1HHWmtjr9aKxY0+ZNHr0\x61PuRI/69GSmDzjjj1Mkt+1vfSsSToKlAcRwDlaNG3v6jn/8onErHmmYsrjm3oaEh\x659ZZDm7o+35qi8nnD5U6Vq8x9W9eNyTbW/uZ7i8YNBXa4/HQAE16fT2AKIr0ptc3\x51TabDVIUBSajybBz1+5Va9asvenlF1/9cWFp6cRt27bFOY77OGjtq4P6VE6AfE7s\x636yzPkouwUd7PF201wvQV+MP4PP5kMfjYdvbo0lNS0guVy6x24vZSJdf/eEN156l\x5aDN2GmFvYUH+SJvVyDIUQRxLg6aqQDAGjmWpVDKtURSVl04lkyzLpGhAVkEQCggm\x4eKLglS1btsTe/3B3NDfXiaZOnT7f7XbZotGYqCvZMADgsvwyh9ttkYZhnue4WYBP\x2beihUChdXlJsHzlyzMi1a98Ii4LxiMlg8RUX508Jh8IaEMDt7YfjhUX509a/u/H2\x38xYv/gstCHNuv/1266xZs2SA2kFITBUapCXJv4kN/t0iiGO5NUOw+Y8ztJTPNzgQ\x37kUAVaiwb+cVqakBevXq1Wp19bw8g2iaH43FdB0Retl3v3/fuHGTF1WUl9yf63Ta\x41UCfPXv2x5/vcrnwl9D2/64kBH0CMZpIYWGh3ldakuqHbBuBi3MsRbEEY4xKSlzC\x55089mlh8+WIzzdCVsXggN68ot8JuNbEUJkABAgoxEA6H4zSLQBRESMRT3QIvWuOx\x53JtRNHkAMMWxtBnrunRw38G1AGD72W0/PGVO9ez/yS/M9QqCSBgG2FQisRcAQGd0\x56VXVGAzTyt//RgA+U7/j8/mY+vp6xZ2fr40cOdKaTqctNM2/K0mKW9V0LRKOhrOS\x54Mfj0Y5EMqKqaubyn/+8dmJnV/fbM2bMvqaurk770Y8i7ADz+XypL1IMRx1D06Oj\x51IZH+7uhje8fUygUogF8/QV7DQQghRoaGhAAUP0dYcRk4hiKgozJaEKKou57aMUT\x73woK3DeKIqOfNnv29H5NPPD5pKGhQRvyeeQoLhk6Cspz1HtrbGzsF+AG1NDQh/z4\x66I0AEKRCoVJad+iI4zROVVUqHu9SampqDAUFeQvCwa5sfm7epFx3HtXTE4in0xnJ\x5aDJCKBSOJJKJkMVqoWLJBI7G4r2YQNpgMobNZnMZAkSbjCZGlpVtD/39ybb65+vv\x6duo75cZoNGwMBgNHotEQ0nWsBCKpVgBgOjo6kqtXrx6WWeDjbQHwJ9MhcCg3122b\x4fmmWs2l3UyPDcHo6I9kymezhSCR+xO3OKyQEM3n5rlLv6MrFv/nNfdsAwPD00/VT\x48nroIXnGjBlsY2PjwMMdWi5N9ZdSU59OsNQMtQSUx+OxwLE3JQ718Zkh/0ZtbW0q\x51KPe1DQAL5pIVVUVAQASDAYxAEBMktKYYNlgMFJKVt1SmJc702gSgOUoGigQ+t04\x39gugUmiIa3Q0122w1aC8Xi8DUAVer5fxeDxU36YXDxOPe6iiogSdzVrpRMKkA8Sy\x52qNRcjg8MH/+ogva29sOFBbnXV7hKRclSVEymWyjpqlsKBzWDx9pTdkd9nyMAUKh\x53IQ3GNVoLLHbkePyYqyzGsYJmmJh9849f6q946enV5QVj5HS6YSaVbpNBlNMURS7\x33e7oePTRe6PTpk0z0DStHMXSfjuD4Mcee0wDAEintcNut1MbP3481XakPZBOpaR0\x4dq1HYrFD/p6eHQbRbicYtdsdZkvlmLLzr7zyO9VvvvnWC3a77dzrbr7ZwfM86Xc/\x79NGTPg3E6/XS7e3tg0qLPzN+EHNxDk+aNNvxOeZ3aOA7xLpVDUagEICb9G9VIRUV\x46QighnLaTQZNU3EqnSY7P9r1qtFkdPECAwyDgGc5IwCA0WgcyrzHct+G9g5TRwnU\x2b//Gh5qaAABSqG8XLwBAAwIA6BtxXgQsG8EWS4ouLi4Wg8EgX17uymtt7djhznPV\x6cJQWlvA8B/5A8G2O4cs5jmW6u7ujPC8YnE6nIZPJQCgS69QxjuiYcPkFhacEg8EE\x31nVbW3vnrpX/+NfBgrzcJdlsOhsOhaIWk6WFpqkUxhBjWXYXAKhjxDFKKBRKw9ef\x34f9aBeBjqR7YeL5mTWN7IpGlCSFYAyrbG4x+ZLIYeUmRA/G42vze+3t+0trWvVHK\x53mp5ed64OaeesmjFij+FI729qy+onn9NQ0ODWlFRwXg8Hsbj8TAAXtrr9RpLS0u5\x50q0H0NQ0VjcYDBp8uuaF6keOWABAo6aMKhAEg34UTTtUs+LBmcpP6pNSaNDvEEA9\x65L0SKi0t5To6OujaWi8ZWTZSYHle7Orxb/vdXfe3mw3IzFEM8BwDBGQMAGCxWEh/\x59Er3w58Anx1X0i+IXvZov++/JxbAx/Ql5RoJwFjd65UQAIDBYGC8Xi/qKzsC0HUV\x79bJM5+Xl8Uaj01pSUsI899w/2ys9rvFlJYVXOnMKwN8b3QoEaF4QyqOxhA6A+Nzc\x58KtAcxDs7e01WaxSe3tnu9vpmsCCymg4FRINVmb79oO/vPqmG07DNMO0HmnLNLcc\x58J3JKv5wNJaigYlHo6HOvgT4EW3QNAz0fyAP0Ffn/tprKzI9PZFgTzisp5QU/qCx\x63SMGgimK3r1734EjDZs2vZqfX3BJPBaLq7KsjxpVftkzzzyx4PKll2/NZjOBZ556\x5alF9fb1UWlpqymZzKACRRKMibmvL0fu0HmCfr5XqX+o8SJNW9fvFJgIAVDQTjZhM\x2bN9BqEPn5FDxeJwCAMjPB3bg931oVN/wKACAzs5OWL9+veWCCy7YLstaWyarkvHT\x4a08wiQJHAQWKrAAmGgEAKCgo0PubUMgn3z+DBBEAIH0ozmcqRz/ewtM/0RkAAIqK\x74nLhMMO2tBTqgQBAIpGgAQDa2tqIpklUfn4+aWhoSKqqpm7atFv7xS9+tmDk6NF/\x64LmcEAyGD0eisSaj0TCfZWnsdDoou91uMJstjKZpJJ3K+HuDAVmR1ejoSo83Folk\x6aAZLYTAU2v73J1/YaTKbapSsrMci8cOaht5PpVL2tsNthziOw82RyGEAQEN6gL8S\x66ht2AlBXt5wAAHR0HD6CsaLGelPpWCAc27fnwEcYk/To0Z4Pvd7KyxU5E9ZlhQuH\x6fmGjyDNTJ0169P7fPjS/5uLFK41GY97fHnti9tq1a2MUlRaqqky03S5pfQ+/SfP5\x66MxAvFFaWsr2a1Wqv8sMBgbYNjQ0hN955504HGMct9frZT0eD9+/LXHA3cD9xWTY\x3729UPmu+m4ii5FC5ublcMBjUbrzxxjGEUM59+w/83uGw6JqOKYqmgOM4oPqPtz8G\x51EMszaCFFZ98Rr87QwAAVVVVAYAPeb1eurGxEUSxb8GEoijI4/HQNE0TQYjrAF00\x52QWJIAjY57PSZ5xxgWnECAu3a9cu5Re/+EXZZZddOPWaqxZVL1p4zoNjxoyyKYqW\x36OpoW++0WS9maISsFhOlylkddJ1wDIMCwVBc1rC5tbWtcfr0qTN0rAHLChRgnl+/\x62v0ffvn/fnSTURSs4UhMOXKoc7XX682XZZmlKCora0rP72+/Pdk//+lTTfBVfbVJ\x36FstAAB9blAo1NmdSCSwy2XiRo6rzPvzYyu21dbe8/aoUWWjPBUlE4J+f7PT6bAE\x653rVcCAuWY2C4bS54//6k5/8pOi5fz33TCqbHlVb+5v5o0aVix0dHRaLxULH4xyb\x6e+8TGhsBVqxYoXZ2duK2tjatf8vhxwOf+oNC5ij+NRzNHx2CzHwMvXq9QAF4P0aL\x66D6AoqIiBmMVsSxLNzU1ZWbNmsV1dvif3bfnoFpSUl6JKCpDMABFISCEYACg+mMA\x4fJpWH1IiAVxLS382t4ZqaAhS0N/I4vF4qHg8TiWTBqbFasWqqiKWZUk2a6U9HgCj\x30cgkk0nGZMo3CALl2LZtW3L+/Pk5kyZMWLhjxw7+oiUX/KK4JK+4vb397cOHj7xZ\x55lx6NsfSpmQ81t3d2ZnkaYq2mI10Vs4SoChTW1v7Hu8YLy0r0sRAwC/RFCu0tnS+\x48o5lOhgaVWuaFm9taatf/XbDjmxWqSCEBFyufMfhwwf3AQBVX18/1N3BDZ80P32b\x42aDvfVevXi0LglWL+XvjxcXFeSUlY4CQKPX88y8HGYbKxQR3SlkVm612V0dbV3sm\x4cUNRcW7ReYvOfHLlypXZR+558GWRE0x1db9YnpOTk62srCQ8b9FpOkCqqkz0qlXP\x6e+7zVZlLS0uZ0tJSZpBWpwbcgn5hYOHT7YIfZ3Sbmpo0q9VK3357bcknr/HR/ZtT\x6fKkJ9NLSNFVaWsqWlpay7e0SLwgCazSmmEQioQAA1dkZTG3fvmvzxIkTv79gwelX\x49kApQlQAgoBnRQIAOJ1OoyFBLTNYCPqSa31Iiejz9Sfd6sHjUZDX66WjUZFRVRWp\x71oow1lBRgGUAAOJxbgBd4ukoTdxuN9fQ8FqmrKwM3ffgw/MuWXJJzSuvvdYya9bU\x6dvFjx52CiI57A53EaDROFg2GPL/f3xpPJPaZzCae4TiUTkvYZDKhZCp9xGHPOyLw\x68kmyms5Y7VahrbNnz6233Xn7wrMXXqIoGoqEImvvv/8Pb8yZPsWQzWYL9+zZsycQ\x36I0++OCDHTU1NehLZOO/itKWb1wAMACA2y0GeuIxWpaz4blzp4zSNI5fu3ZzTzQS\x793CskAyFItHiklKOcBQdTqZ2YJ2GMZWjq9e//daf9nfvj95x509eVNXMnocffnjF\x45088kT3nnPloxIgRpKurixgMptGL5s3LaWtr0/Pz8z/W9E1NTXogYJcHdt/29xx/\x44KP2MxvVl8yqQY2Ni7Imk6ns/KrzjX3BLkD/Gh8MAEjXddTW1oazWSvNMFGcTqe1\x5aFLQRVGkKysrxX37doSOHDl0gGEohaEpYhREJhIJqeFgBDM01x9L5GOv10uVQinX\x66x364AC8f1EFAQAcj8epqqq+pFs6baUVRRH63R6qrS1HNxjSmq63oUzGyJjNWVoQ\x45MswDEucJj6dTuOlly4tGTWq/LR0Mpn37KrnP5g3r3ruzBlTL1IVSaNpoASe11iG\x31w4eaj0ST8YPFBQVVokGA9fZ5Q8CxYA/0JsMhcKrbXb7rN5goMdutTrSkiR9uGPP\x548+/5Pxyq91aSQi8t3v37o1VVVUOo91m6eryS++/v7utu7utHQBIa2srVVRUxJeW\x6cv43AwDIiSwAAAD0ihUr0gAA0WjsUFlJ6ZSamgtyDx3a2d7R2blex1ARDkV2HDx4\x4bFNWXuaJpuL+rKx2SMkMjKqo+F79c8/cCQBQXV39IACEGxo2rlixoi5TXV2NGcZu\x57rRo/oq6u+88XFpaRUejUaaoaEZ/GYWX9nqD/Vncqv6y4I8Z7mP/HgBQfX0vAqiD\x58/7y1g2NhxrlPn/9k9LnfmEBj8eDBMGu+/12jeM47HDoSJJY2mQy8X/7299SH3zw\x51VzNZgFhnUqlU7TVYmWMJiOV6VsKAWPHjlWLiopyJ18woxAA9EExB+3z+dj+FbMD\x62ZfQ1dVFe70NFE0HiKqqCseFMMYu5PVKPMuyHMe5OYMhzQAAiKrcjyolQWIYNi7F\x30bp1azf/+p7ahmXLrphy6qnTb8K6jAFUbDFbARFm5z+feO6WfU1NG4qLi2fnOJ1M\x4bBQJqaqW5AVBPny4Y53BbJt3pKNtlTsnxygYLMbD7d0P1N15d9fc0868NByOdm3d\x2bsGLLR0d7ZWVlazBYJyDMd6+c+e26GuvvRbxeDy8zeYuHzv2lJLKysphPwXwq5zW\x6aPoe/gyyceOb1JxT51iLS0omI8SGYsGeltFjxlzEMGx7OBRmjQbezDF0eW8gvNpg\x4dFSkpThx2x1nXXjuRVRuYVnbO++s/mDmzBkLly5dWnX11Ve/OnHiGMOUiTPGunJH\x4aHbufEu12+2M1YpYp9NJuVygK4qCQqEQazLRTDpdhEtLOTYej+tDkl8AkEMB+JHX\x362UOHTrUX+rsR8FgkHi9XlrXdUQIgWw2S6sqRVksYaqzs1MzmUwkEpFRa+te5Z57\x62mUnTz61yu20zXM4rDYMVLfJKE7kWAa6Ons2/vPpZ9bW19ej0047rbCwsMi8desm\x769VqFYuKirDf7yd+vx8Hg0EC/ROkOY4juq6jdNpAC4KARVEkqqoikwkxhBCk6zpl\x4dFA6RVk5RaFBo1nMsjqlqipd4HRS4XA4vX79eumvjz6yYNy4MX/mWQQINKAoWieE\x5afbua/n7yJEjJo8dP/ISs8loj8Xj6XBvJC6IQmlbZ+ehwqKK4paWI/+0mPiOEZ6y\x4f3pDkfXf++6P77/1zltn5rpyx65bt+GlNWte3375xVfMjsWS0cLCgqmbNzc/NXPm\x4fDx9+gKDrqdtdrvT7vWOzpGk9KG+3WPDdhniV2oBiM/no049tT4ZjWqKv7OzWeBY\x63db0Uz1PrVrVEQ6H1xFEKjCigh988NFmk2gSaZoeG0kkXnG43Lxg4NXxk8bcWXPR\x6fv/3xhvrMjNnzrwcY8h78/W37l+7dm2YN4mZuXNnXH7ddTfaWlpaJIzNKJ1OM4lE\x67lZVFQUCTtVszmgAjSSbzQ5UlfaXNfg+2ZTu8w1KJH1cWIb6B0axipJD2e12yunU\x6bF2zUx6PhzIajdhgyKoAoMdijOCw2cpUXdur6TijyDKH+h0ygtCAj45tNjdrMYgf\x46/t9UsLwiXZsaWlRFUVBBoOBGYB4FUVBiqJQsRiPs9msSlEUCQQCiGEkbLEQjqaT\x52FE42uUqQ/v27VMPHTpkW/3G6/87e/a0R00GhtBIB5alSUFBCX/gQOvLDMXnuVy2\x42RaLyaFrOvT29HZkpIyaSCRTZaWeMcFI+IVbbrnlmRGeEXdpKun4+5Mrf19Y5iaj\x52o6asX7jxr9s3rxux6WXXlnB82zK4cjJsxhNm157bUUmk8kwuq7Q7777btxstiCK\x59iL19fVKbW3tsB57+ZUKQGNjo1ZXB5CXZ0y++tarh3QCPQazkLtw4YUFW97f8Vw4\x45mshQKcttrzOQ20dDWabaVwiHrd0tvduoHmeTcthtaQ456rVr/5rOQBQ1dWn1fCi\x51K9ateq2p576+x6r1egfN67y2jPPPM+l65vSI0dONJSUnMJYLBbR53NZWlpadK/X\x5340ePVoeKKvo00iNen/ATHsbJWS1WnFfDsFHAfiQxxOnstkcKhgEoOkAiUajWIyK\x4fMEn9Gw2SyUSCdpiGUEDgG6z2Rw2Rw4Xj6UPaTpWEEIEEx0I1sEg8AMwIEOIbsK4\x621OiplX218b4aAAf1YdYediBJF88HteNRqM+EOgaZSMDEIBCR6EjEonA5MmT7U5n\x6bTEWw6rRaKQKHVa+pyfgOOuss0a++caLfznllDHXUxRGLI2BYymwO1z07n37309m\x35AOIpt0mo1gisBwViyaOKJKuMhxtrhgxwpLJqC/OO3PBr559+okf0IgueLfh/e9v\x32bCl7ac33jr98KFDW9587e0PystHuvLc7snNzfs+cjmdlQdb979DCEH19fXSG288\x6d500aZLIcYxhy5b1zQCAvoLxLyeMACCfzyfm5k4QCwsLUVNTk6Qoyl6MMctxLLz4\x34qu9yVT2UazjQ4KBK06k0y+HQ/HDnGCYE46EDdu2bFvLMhyl6ZJeVpF77bbNm//q\x38/nyTj+96haz2dr78IOPXvyXv/xzi81s0b6z+LzLR4w4tyQa7VK2bHlFM+pGZDSy\x72vnz5xc1NTVBQ0MDfFJaUUMGMr2JRIJu6mM46pOsr4m0tFgxTfuJ1aqoNE0TAIDu\x51TcmCALr6g9mTSYTL8syhCK9ciYj0WkpTVMUBRRNAwaiAQC67qrrvG1th1p379t3\x47AAoUWz92CXweOJUSwtHvF6OpNNpqi/x11fOwHEc4fmEnjX0af6uSDpjMploURRp\x56dWwxWLkDAYDpzIU/4tffP+aO+/88QueiuKqeDws0QghlmZBNJjJwUNHDvi7ew/o\x75irZbMbTS0pKckLB8IFgb6hNMBiMRUWluclkctuv77677rd/+MM0hzP3B7t27Prh\x33Xf/vvkHP7hxdjweNd58843/vPzyi06bMuWU6Ufa2z8oKakYR7Oopa6uLnv99dcz\x41ECVl4+1KYqg79mzY2dDQ4MMJwB9pRtb3O5RRptN17du3SrV1NRQ69atDY0ePba4\x72aUldMqkabaW/c2ZzQ0bNkycMmG0KIol6WR2tayq+bzAlllMZm73rl3PeUZ6puq6\x69vNdOZPmzD71woysbrvttls/KCsugQmTxk1oPdzaU101u0JWNFnkbM4Zs6ZIL735\x55kwQ8tJms8152mmzRxUVFaQaGhpSM2bMEDguLKbTIRyPx8HtdoPZnKUOHxYJwC4M\x34AeANvB4jDTGGGWzDrqzMwmFhWbGYNB5hmEglRKRUQKIczQViXThmTPn8pKUcqma\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\x39hzYYXc6RobD4cy+fQd22GzW6W+98tr6q6+7NHjLLbeo/3vPXb+kKOrdSy+9eN26\x64euYxx9/HLW1tUFl5SxTONyhwAlA38TeXhKPx/VIJEIWLFhAv/XW6+HJp0wdWz1n\x72mPturc7X3/lFf9FS5aYTSYDZzUZzzn7nEXx39x115Pu3EJ7jjvnTI7jt0UjqdaC\x67tyzDQaBpOJxjLCCSsqKPfl5uRctWXLxhOLiosCll17824WLzo8UF5deO/+sBcK+\x7700HursPqZaUBfypI/Jpp51qGz/J562qmmt89923021tB5VIJKJPmTKFkySJkmWK\x75FxG6lD7ISm/sJiZPn366Fgy6+/o8Pe6XDYHzzPUWdVnlfsD/sjcuXMNioxHchyn\x57MwGN9H1cQRTTGdb+/UyRh+5XTkPXnnVVdyvf/2r9xKdncrWrZuSa95efWDCpFNY\x6d816ysyZ00s7O3u7VTWuvPTS8207djT2+v1+5pLvnDflvHPmLRs/cczlNqvRzTAU\x34Vle9/f0SIqqErfLVU4zNKepKlFkCSfTqSTPizajyZzNKympcuc6pgXD/kQynZCt\x5akOhwItcsDe8+v4H/nhxJil7NKwf2dP8UceF5y1ei4Bp2rL1/af27T+41+XMMTQf\x61ImOGuMp1DSdeuaZJ19cuPD8c/btO3CgcWdg38svPyG/+OIrZ5hM5hFnnXX6fetq\x31zG3/OkZtHXrC+SCCy6uzGaZqN/frJ4IAvCN+mhFRTNEmubJ7NlF9mlTZv10f/Oh\x429599/WY1WpFd/z8FzcDEDfHct/v9ff+9K11Gz6qmuOrKSkqmGMQxIcTiWhJcWHR\x7a0wGARGsEJPJRGiGpQSDCcKRGI5Ewm9uff+9e//f/3t4xz2/+eVsSdJMB1t3b2lp\x61UmOGjXO/ac/3XcYANg/PfDIOYJRzE/EkvjDj7auf/rpp/fnQz5bPG0iE4lEAFt1\x31NrYqFVVnWPOzbWXhULhzLvvrj4IAGjlylXfa3hv04uMRplLSopnOBw2YcSI4jPt\x46tP5Ab8/ns3qt164ZMnjP/nJHRWnn37aHVarxa1p6l8vv/zyjd3d3SIAdA6kFvqf\x42XfGwoXOpRefNy0v13VxQW7eBQ6HFbKyTGiaIUpW0mUpq4lGI2cwGuhMRiIcx0Em\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\x52K5CYII=" },
            ["\x56oid Slash"] = { file = "\x6eoir_cursor_v2_06_void_slash.png", scale = 1.55, data = "\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\x4cCWTyclUKjVeKBTG5ufnzySTybP5fD6lKIqEEMKCINAEQVCV2h3GMAwaY6yQJMlS\x46IUSiYTc1dW1+uabb/4/QqFQ+9mzZ3e+/PLLP52ZmTl68803q8ePH2/gOM7LMAyj\x71qqMMZ4fHh4uXw4C8V6Def/7339XIBBYu2LFihvWrVt3c3NzM0FRFLZte6HswBFq\x6biQXangcRagWfMfKOxa/snllUxSFCYJALMsSjkvkoGkamKa5YM2d96gW6opvb5um\x69Ss5doIgiDfsDVRTraxOqrRYLGJN0xBFUaAoCsiyrGfPM5fP52fK5XIil8vNFovF\x70KqqMkIIq6qqWJalAAAlCEKAoig8Ojo61dPT03PDDTf8MU3TzODg4H++8sorz4mi\x65AoAIBgMNiCEAgAAiqIULctKXEqBrqsAv4C6//77N0aj0dva2tpW3XjjjTe3tLSQ\x48MdhXdeRI+RVggw8zy9keWiaBoqiwDTNN2RkKq/FBEHYNE0TPM8jAABVVSGVSmVL\x70dLc/Px8IpfLTaTT6elisZjXdV0iCIJGCJEURXG1tbWRhoaGhkAg0BAMBju8Xm9L\x510ODh+M4sG0bJEmyDcPApmkSAICqla5aCZznaJoGgiBAURTI5/PYNE3krDblchlE\x55ZTz+fxssViMZzKZiXw+PyOKYlrXdck0TZVlWY9t22YikUisXr167cqVKz+hqurc\x33r17f3Ds2LGDy5YtGz927BgVjUZbAIDGGJu6rpfr6urmftuD6q4C/I644447borF\x59huXLl265pZbbrktFotRXq8Xa5qGaJp+QykCSZLAcdxCXt9JcTqujrNjixDCCCGb\x34ziSYRgQRRESicTU2NjYgddff/3ACy+8cPb1118vyLKsAYBWccEs+EV9zoUPCgA8\x64999d+3tt99+VVdX160dHR3XxGKxdkEQnKDXsiyLsCwLOXGAUyrhKIGjpE784Owf\x4dAwDtm2DYRggiqKoKEq5WCwmM5nM+Pz8/GlZlgsYY6QoSlFVVXn16tXrm5ubN+Ry\x75aGdO3d+L5/PD3q93lQymSTD4XBE13WaJElV07TSuXPnsnCZnWJ7LygAAgB8++23\x726qtrb2jvb396vXr19/X3t7OCYKAdV1HzqaWE/g61p4giAWr7yiHpmnVG142x3EE\x797KQSqWUU6dO7d+3b9/O73//+wNzc3MSAOgrVqyAUChEYIwdC2ypqqpUgl9UWTkw\x797KIoihC13VsWZZ16tQprVwu6wBAA4D/29/+9to1a9ZsaWlp2RiLxThVVUGWZQtj\x54DpVorquO67OQqoUAICiKGAYBnRdh1KpZOu6rmGM7coqVS4UCrPxePx0uVxOVlqR\x70GmaZtvb29dEIpGe6enpV/bu3ft0oVA44fV6JUmSBJIkBZIkSdM0SwCQu0xOqr3n\x46AABAF6xYkVdZ2fnptbW1utvuumm9/X09AR5nsemaSLHn3eEn6IoqBzUesPXuq6D\x72i/cYywIArAsi+bn55Xjx48/+9hjjz3x5JNPjjIMo/X29rKCIOiSJNnZbFZJpVJy\x73Vg0AECFXxShQdW/RGVVcLIlVGdnJ9/S0kIHAgGYm5szXn31VRkAqE996lPdW7Zs\x65XDJkiWfaGhoYCVJsjVNA8uyCFmWoVwuQy6Xg2KxaImiKGKMbUEQgoIgEAghKJVK\x53rFYTNq2bZMkSZXL5Uw2m53MZDKTqHJ0i2EYprW19Trbtqnx8fH9r7322jOZTOYk\x77zCUZVkcxhiRJGlbllUeHR0V4TI+u4yudOEHAPb973///eFwuPf222//8OrVq1tC\x6fRCuWF+gKAp0XV8ILJ38vvOv4/JUlTvYwWCQKJfL8Prrr//Xd77zne9v3779VCwW\x7752dnbSqqlYulyudPXu2BAD6dddd543FYkGSJD0Mw3g4jvMZhmE6h15IkrQJgkAA\x6fMqyrFMUJbEsmz99+nTeORTS0dHBLl68mGtubra///3viwAAX/jCF3o//OEPf7mr\x71+t+juMgn89bhmGQkiTB/Pw8zM3Niblcbo7neV9NTU2U4ziiXC5rpVJpPpfLzWGM\x44Ywxmc/nZ3K53DRJkiRCiIxEIosikUiHqqra+Pj4s/v27Xsyn8/HPR6Ph2VZTlEU\x54VGUciKRUOHSOYrpKsAv+9tuu+22a+vr6zfecMMN77v++uvX1tXVYYZhkGVZQNO0\x551L8hkxMtb/v+NYIIaBp2vJ4POTY2NjUD37wg3/6h3/4h/2LFy822tra2FwupxSL\x78dLExETxhhtuoBsbGxdTFBUmCILCGKskSeZKpVK5vr6+5PF4dNM0F4SHoihiaGiI\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\x4cJxYZNu2bfZnP/vZD3Z1df2zz+dbLklS4ty5c0//8Ic//I/Dhw9PVgkt1dHRwezf\x76/+XWXWnC4V99913LxsZGVm3ZMmShzo7O9dVVoUr1hW63BUAAwBBUVQdz/Men89X\x58ylrQNVNa6v9f6fdSeWAi83zPDE3N5d8/PHHX+/s7ESiKJauu+46liCIsKZp05eY\x39UOVDS5rw4YNNX/7t3/7d9Fo9IscxwXz+fzQ4ODgd3fs2LETY1wGON+/v6WlJdjd\x33U1UCtrsX6ZMCCH8j//4j39x5513/uf8/DzHcVy8qanpDgAgLuJmn6sAvyr709vb\x367MsK1xXV1fn8XjCzuF2p87nwt6cTgvyStc3TJIkTE5OHhoZGYmHw2FyeHhYaWlp\x71QeAbH9/v3WpWD8n0N28ebP1yU9+8sY77rjjPxobGz9mGEZhdHT0R/39/X+3a9eu\x41WfFamtrC+Tz+ZDH45F/yXndBWW69dZb67/whS881NbW9o81NTX1uq5jTdNm6urq\x2bniej1ZfbzcGuMQQBMFPURQfiUQW8zzPVAQdXdhNzWlzUt2BmSRJZBgGDA4OvgIA\x74mmaOgCYBEFETdMcqQSDF936b9++ndy8ebMFAMxXvvKVP2lsbPwcRVH+eDx+8OTJ\x6b//W39+/CyrjkFpaWjiPx1Onqqo6Pj6eeYuMD968ebP1J3/yJzd2d3d/DQDCXq/X\x56FXV09DQUC+K4lRTU9P969atu2r37t1zbza+yVWAS2EJI4gATdMCz/M1PM8DRVG4\x32lo5B96dnp1V/Tkxy7JEKpVSX3nllfFwOAzFYlFraWkhbdsWkslkocrNumhWv1Ln\x6223cuLHj7rvvfjgWi91XKpWSExMT//HCCy88cvTo0XOOK7h06dIwQsgLAJnx8fHy\x721g92b/5m7/5WFtb25f9fn+dKIozlSa4VDgcri8Wi7mlS5fybW1tVwHAiwihK7Is\x2bnJWAFzx7X1er9fLcVzIaWLlBMDVfn919sc56cUwDBJFcXrXrl1jy5YtI6ampuTu\x37u6gaZrlSnOni+b/O1Z/27Zt8Bd/8Rcf7u3tfTgcDjeOjo6eOH78+De+973vPeFY\x2faamJp7juBrTNPXx8fFZeIshc06m57vf/e4/1dfX/5+GYZR5nicNwwiwLAsAAKFQ\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\x317IsTZblXKlUmhkaGkoCgOEKvsvlrAALgrtmzZo2v99/lSRJU6dOnUquWLGikeO4\x57pqmfQBgFQqFpKIoecuy0sPDwzlX8F0udwVYyPb09fWtoiiqsVQqzWGM1XA43EQQ\x52NAwDEVV1aIsy/OmaSYHBweL4KY0Xa6UFaCjo4NtaGhYxfN8TFGUEkmSKBQKtdI0\x7aWYymZOJRGIkm82K6XRagjeOB3KtvsvlrQCVgQzL/X5/A8dxNMuytQDAmKY5l8/n\x447388svJCwTdFXyXy4q3KoZDjY2NXYIgxFiWZWmaDtm2XSgWiwN79+6dqHJzqkt+\x58eF3uewVAAEAXr58eZ2u6wJBEEXLskhRFAeOHj06Db/YuUWu0LtciQrgNFGCYrE4\x4acuywvO8ODAwYLiC7/Jejg2Qe1lcXGVwcbnCcbqXubi8J4Qdfkkc4OLi4uLi4uLi\x34uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi\x34uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLyTvP/A69z72vOw4IIAAAA\x41ElFTkSuQmCC" },
            ["\x53cript Blade"] = { file = "\x6eoir_cursor_v2_07_script_blade.png", scale = 2.05, data = "\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\x65fPmJQih/oaGhlWSJP27y+V6Z/HixYdGttu+fftkl8u1ymKxGILBYKuiKF/29/dn\x76PTSS6/s3r17+65du754/PHHXTk5OYWSJBGqqrb/8pe//Ozw4cPjDh8+nPDTn/60\x736SkZClCyNnX16fa7fZAYmKiun///uqHH374Kp7nVxgMhr6cnJzUCxcuNCQnJw9R\x46LXwzJkzVXFxccFbb7313MGDB2f09fXNef/99w/8+Mc/vvGVV16ZOjAwEJs7d27O\x64dddt6Guru6q2traKaIoTkxJSRnX0NDw0rp168pTUlL6EEKTdF2vGn4+Gp75xHp/\x66/+ZvLw8SpIkq9PpzMUYa7quE6N6CX2k0mOMR6+XjBm5Rx5K7733XjoQCGC32814\x76d6Uffv29c+ePTvRZDIlcxxn7+npadc0LcdkMiVEo1HVZDLpuq47m5ubX+U4bgJF\x55c6Wlpb/6ejoINasWTM1LS0tXVVVkiRJ+ZprrrFWVVUNjpzjt+oB9u7dSyKEUG1t\x4cc7OztZH5o+v5OJG9wQrVqxI0DQtzev1pnZ2dn5QVlY29PTTT5va2tpuLiwsbJ0+\x66frTiqIMhEKhp+bOnXv8+eefT05KSrotGo1yoigO1tbW1jMM4y8uLl7U0tIyNRqN\x50rt06dJfEQRx3cmTJ3+yePHiF0pKSqzhcBjNmTPnJ6mpqacoivo3nuf7Wlpa3ly7\x64u1JhFAIIYR27NiRYzKZ1tXX159KSkrSr7766tsVRUk4cODA/8YYByZPnsxeuHDB\x4aorib2bMmDHL5/MV+Hy+3+bk5Mw1GAw3NDY2PnvnnXf+dvfu3XEkSe5Zvnz5dSNT\x73q+99toTCKHcaDT6W5IkP9q2bZtv37597qlTp3pVVeXnzZs3Z9myZf+empo6WF1d\x2fSnHcRNomuYsFoupsbHRIUlS+8yZM1WEkKm+vv5Tj8ezcmhoqEtV1XNms3k6TdMD\x48MfNJQji//h8vgs2m+1HXq+348iRIxdSU1NzRFE8bTabeUVRJg0MDBydNGlSAcZY\x61WpqIl0uV6qiKF/a7XanKIrdoihSHo9naTQafdFsNm+fNGmS+OSTTzo6Ozsnv/ji\x698cu6Zkv2rdv3xfZ2dkTPv7446X33Xdf9Vh14NFHH3WnpaUZOzo6LOFwWPJ4PK6u\x72i4zQRCkw+EwmM1m1Wq1asFg0NvV1RUMBoN1BEE4J06cuKqlpeVLs9mcoGmaESF0\x71rm5uTYhISHH4/HM7OzsrPF6vd7Ozs6zFotlRl9f376hoSG5oqKifcmSJa6nnnrq\x39IQJE5JOnToV2r1793xBEDrfeOON0HCdvbIGcLk5029YHCEQQqi8vPwP9nfttdfq\x5aWVlqLa2FpeWliobN240UhS1KDk5eZrf73+9tLS0+7HHHluydOnSd2Kx2PqFCxfu\x48t4nhTG+OK586623EoxG42qr1bpQkqSW5OTkGWlpabPD4fCJw4cPv15ZWVmXmZlp\x31XVd9/v9gcTExMU5OTm3Hjx4cOfmzZvfRAj5165dyy5YsEBWVfVfOY7zyrJcn5mZ\x65TPHcTfrur51/fr1b73wwgtPYoznVVZWticlJc2aMGFCa0NDQw/P83pWVla6JEn7\x39+/fL/X09BydNGnSF06n0+ZwOF7r7u6+OxAI6EVFRR9rmnb+7Nmza4uLi4cQQq6U\x6cBS7LMvhW2+9lb3jjjtuTkpK+rdQKNR94sSJ0yzLaunp6Us5jvuqo6OjymKxpLvd\x37qtJktxz7ty5ytTU1Ad4nm9xuVxJGGNDd3d3lcPhKOjq6vosJSXFbTab58uy/Kzf\x3759vNBrndnV1fZmZmZnf3NzcERcX53O73VmRSOTVgYGB64xG45S+vr4vU1JSrmpp\x61Tmbm5s7Udd149GjRzevXr369KZNm0yBQIAwGo1pFy5cYDiOay8rK/PNnj3bumHD\x68qw9e/Zc+Oijj/wPPvhg6vz5899YuHDhPF3XUXV19SObN29+JycnZ0ZXV5eQmZmZ\x34na7symKMrnd7szq6uqDXq83LzU1dWJdXd1nHo8nnqZp5tixYztmzpy53Gaz5QwO\x44v6+qanphKqqstPpnBoMBhvj4+O9fX19kaqqqq+GhoZ8ixcv3hQMBst0XeetVuvs\x70qamcofDkYkxtvE839PU1NT3n//5nznz5s17LDk5eVJvby/67LPPnti7d+9zV111\x56ay0tFS4XEPFYy0grF+/frrX6/2x1WqNKorSPG7cuCFZlrsGBgY6T58+7du5c+fQ\x36Lnob+OFF15I9Pv90wwGA1VYWLjq0KFDHz733HON1157bf2uXbsuLmB9+OGHk2w2\x32zyO46YrikJRFGX2er3zKYriuru7fz5jxozXRrbNyspikpKS6OXLl8eNGzfu0Wee\x65eZnoig6s7KyJuq6HgwEAg179uwZ2Llz56R58+YtQggt1DTt3KeffvpfDzzwwFBN\x54c0ZWZYPfv75579dtGjRJowxuW/fvqfmzJmzODk5+caqqqpdbW1t50wmE11fX9+u\x4bErvwMBA4o033mgKBAIJhYWFy1NSUuYmJiYmIITMixYtSktKSjJOnTrV6nK5sqPR\x71HT11Vc/2tbW9llVVdX+yZMnR00mU2Zqaur6V1999d/y8/NnzJ49e0EwGPz3BQsW\x74B86dOgngUBg3aRJk0IIoYNTpkx5ZP/+/fdEo9GZhw8f3nfrrbcuv3DhwmOrVq3q\x2beijj3YfOnTo9xMmTJBcLteCN954492VK1f+65dffvnOtm3bLrz55pvPVldXV4ui\x32D5r1qwHZVkmkpKS2l5++eVnrVar5HQ6kwRB8Gma1jNt2rT7Fi9efBfP80xra+uv\x3586de0N3dzc5d+7ca7Zv3/6wIAieBQsWrPN4PGpycjL95Zdf7lu5cuW2jRs3buns\x37KyLRqOdkiT15uXl5UqSpPM8b/R4PKrL5cpRVXWwtra2s6enp9FiseQ1NDTs6urq\x36svIyPAGAgGUmJg4MT09/QeBQODjhoaG41OnTp2dkpKSWVdX1+fz+U5qmqZomiZb\x4cJZxsViMMhgM7q6urv2BQKBnwYIFiffff39FRkYGbmtr4w8ePFihqmoLwzC/u+uu\x75w5cbgr0m3oAXFRURLjd7sl2u/12kiRzzWaz0263k0aj0arrOsVxHKIoSrVarWGW\x5afu/nl4ODRgMhlB8fLw/EokERVHkEUJqOBzmZVnmRVEMybKsNDY2Rk6ePBmdO3fu\x78GnTpm06cODAG5mZmbNomjZ4vd7zDMNgm82WjBCiKIribDabx+v1plitVuT3+3dm\x5aWW9iRDSvV6ve9KkSXGRSAQpiiJ2dHSoq1atSsjNzb2rqqpqN0VRYb/fjxMSEuZM\x6dDDhqhkzZjAcxznPnTtnOHv27NNPPPHE56mpqdwDDzxgS09P3/Dhhx8e4zgutHjx\x34snHjh2L9vf3N82fPz8+HA6Pb2pqOqIoSu/vfve7yLp1624bGhqq27Zt28Vx/9tv\x7653rcrkej0Qi9d3d3QJCSON5XkQI9TMMU7lx48bz8+bN88yYMYP2+Xw9ZWVlUlFR\x6bTknJ2dhLBazSJJUvnXr1i6EkL59+/aE1NTUBzDG13V3d5euWbPm4zvvvDNuz549\x45kJIzsrKUuvq6qTMzEzL9OnTibKysnB8fDzX19dHIoTCwz0yRggZ1qxZY3r99dd9\x577du9c6cOXMjy7L2urq6LevWreu59KavXLlyfCAQMD3//PMvJSYmLqisrOyYMGFC\x77ksvvbSiqKjIK0nSktdee+2RW2+99Uxubq7q8XjII0eO/PaWW2558cEHH1xNUVRH\x58V3dsdmzZ3vT09O9oiiaSJIkVVUNORyOTr/fn1VTU4M6OzvVhISE1PPnz39kMBji\x309LSnLNmzVrf2NjYdebMmXftdruEEDJ2dXV1z5s37/qurq6OkydPfmQ2m1VZlgPD\x45yNDJpNJsdvtwbKyMunEiRN0b2/vDQ6H4/YvvvjiiMViyfN4PF/efvvtb4w1lLvi\x57aAVK1YkIIRmsSw72Ww2J9M0bUhKSkr0eDxeu92e5HK5EuLj45Esfz0BMnHixJHh\x45ZJlGfE8j1RVRTzPayzLKjRNy6IoCgzD8F1dXZHKysovbDZbmiiKoqqqNp7ne2pq\x61j5PTU01zpkz5+7ExMS8YDB4vLKy8n1VVdvGjx8/IxgMGjiO66AoKkoQhM9qtQYI\x67tB4npd8Pt8kSZLyJEkiCYLgHQ4HTxBERBTFc0eOHOk4d+6cJTk5OZ7jOCNCqP30\x36dP9lZWVwm233WYnCILo6OiQpk+fzum6Tra2tkoMw5Dx8fGIZVmWYZhYW1vbgK7r\x61e3t7c3jx49Hvb291NGjRzsQQsQLL7xgqqmpYZuamtCBAwf6RnrJnJwc+5kzZwSE\x45JmXl8e53W5ssViYlpaWoZkzZ46XZXkyxjiwevVqj8ViWYYx/iQvL++Vb7PyWVBQ\x59L3llltQUlISbTabUW9vL3vixAkiOzu7YNq0ac+KolilquqrsViM1TTNommaweVy\x57URRjGtra1NJkkyIj48/Hw6HyZycnB/X1dWdHDdu3IzTp08/V1hYuEAURbawsHDl\x716++embq1KnmiRMnMl999dWnq1at2j5t2jScn59f0NbWFkxISIi32+2mqqqq6mg0\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" },
            ["\x4cight Seraph"] = { file = "\x6eoir_cursor_v2_08_light_seraph.png", scale = 1.75, data = "\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\x76V6ltrb2O0d6CCGouroap6WlocmTJxPz9TG6aJ0AxyjlwbEbSADAtnPnzqfcbjeo\x71qrIsoz27t27LRwO71y4cOE7f//73zedeeaZ6cFgEBuGoQMATQjR7Xa7mJ2dzem6\x72pmWPbHhxHwuSRLp6+sjHMchURQTm1SIIAjo9ddf/3LMmDGDSkpKipcuXVrv9Xpb\x694qKTs/MzBQoigJFUcDtdhs5OTnZb7/99qfd3d3tvb29oWg0uik9PR2Hw+Gopmmy\x6figKIUQNhUIqwzCapmmaIAhaOBzWduzY8b0nuMW6tw752srKSqq6uto4WiNIlgIc\x77prV1tbSY8aMUR944IFTzzjjjPtlWd43ZMgQIZZNZevq6npOPvnkqbA/dp40bty4\x35N7eXp2maQNjbMTaGCld1/VQKBSx2+10LEpDEqezmVnZcDiMFEUJRyIRHgA4M2Mc\x535rR55577qjHH3980X333ZdfVlaWsnjx4k3z58//S05OTnFmZuZQQRCyRo8eXYAQ\x77na7HXV1dQXT0tIYh8MBkiRFVFVVzE0tAKAKgqDIsqypqqqwLKu3t7frpgATQqjZ\x732eTg+cY/SfccccdxaeeeuoZmZmZYwEgS9d1pqenR2toaNixbdu2JaWlpf+qq6tT\x4cAU4irFw4UKqsrKSxKy+es455ww+77zzXh09evRwAICGhoZ2v9/fEAqF6pqampZU\x56FQYPM+7u7u7OZ/Pp3Ecx5rvpWkaxDYyRlwulysvL2+0mRE2V45qmkYwxqitra2v\x716urx2azpTU2NvYWFRUVqapKWJZFGGOkqqpRVFSUNm3atKJnn332HzfccMMfBg8e\x50HjYsGGFHR0ddffff//sk046SRgYGLg8MzNzeqwrTI2VR0Q1TZMRQqokSSoAKMFg\x55LbZbGpSUpK+fft2M75vAAAuLy/nEUKR70ihCcMwLoqiaIZhthFCNlIUJbMs29bT\x301MHAH1Hc7fYCe8DmLN7TL563XXXZV155ZX/m5eXd5cgCIaiKEGO45JmzZo1/bXX\x58ltivq6wsDCJpmmGEMLRNE0zDMMxDMPRNG2jKIp1OBzczp071eeff/6+884770xZ\x6cg2O47CZ8NJ1ndA0jRobGz3vv//+losuuuisL774YvOMGTPGiqKIRFE0TyRCCIGu\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\x6dqbxpk2b+nfv3r0sJSUlm6bpbYZh0AAQ7w7z+/3R7u7uPTRN446ODsntdjNZWVlU\x72EyaaJqG1qxZ0719+/at06ZNm1RQUGBftWpVS21t7dK8vDx12bJlH77zzjtbYH91\x72QL7y09WAwBkZmY+cckll5RVVlbi4zEb/4MpnXUJDh+dnDZtmrBs2bJodXX1O7t2\x37XrjvvvuWzlhwoRcj8ejT5gwYajb7T5VEITAPffc8zghhAQCAZKamor//ve/z8vK\x79hqCMe794IMP1v/xj3/847hx4zIJIUYwGMRvv/328pdeemkhIUR75ZVX5jY3N//r\x77QcffPLcc8+dctNNN/1pw4YN71x00UVXjR07No2maUPXdSkpKUkfNmyY9vTTT5tO\x42RtTDgsJOKpCWZWVldQNN9xw1eTJk5OWL1/eWlVVhWtqao6VI5sMHToUNzY2auef\x66z41dOjQhwzDWNba2hrkOI71+XwhwzBCu3fv7jzttNPOSk9Pd3AcRziOg+zs7KLW\x31tbmOXPmPJednW2fMmXKpVlZWTiWCEMcx5Gzzz677Le//e0vCwoKHJ9++ukHr7/+\x2bspdu3ZtcTqdjUOGDDnljDPOKGNZdu+iRYs6TzvtNHrXrl3KkiVLVEIIrF69mh41\x61lRFZmZmoKWlJWIZvqPPCUYAABzH8dFolBdFsRUAYPbs2ccUX41GozoAoA0bNqyX\x5aXmgr68vGggEdMMwNEVRlNbW1n1+v9+HMTZUVY1Phxg8eLCjsbFxjSAIelZWlmPv\x33r1d4XBYj0ajqLu7m4wePXpIZmbmSW1tbSufeOKJW5cvX/5+eXk5V1hYyNxxxx0L\x4a0+efJUsy1unTp36xj333DO4urra39jYKJsTu2pqajS73Z7ldrudx5sAm459ZWWl\x63Cz7AAQA4M033wwDwMsHhdyOGUyePNmoqakhbrdb8Hq97Z9//nn3sGHDHLIsyzab\x7abDZbOzu3btDmqaFBGH//cIYE1VVISkpyRaJRKLd3d2eN954Y85pp532WFJSknNg\x59IB6880351dXV6/48MMPNwBAsKSkhOV5ngSDQX306NEcx3Ha7373u9dffPFFR0VF\x78UcjR458ddGiRW8jhPaZxmX37t2f1dbW+o6nKE5sJpT+/PPP393X11dTXV39VVVV\x46f4u/iM+Gr/UsZptNi98V1dXx+bNm5cDACiKoquqqkUiERUAtP7+/mgoFOqIlUUT\x54dMgGo0iXdcjqqpKXq+3c9euXfUURdkMw6Dmz59/+9VXXz3b6/Xu/MUvfnFKRUVF\x6dqIokqIosiRJUjQaDQUCgWhFRQW/ZcuWlQ6HY0hJScmDN9988565c+f+HgDIwoUL\x71dra2j44jiZEEELwzJkz9Xnz5p2cm5t7hqZp68ylKMciBYrD3GByLB/JL774YqCg\x6fCDn4YcfPqmpqcnPcZxmGIai7C//lAFAjLETpCgKcTqdRklJyYi2trbIunXrmm++\x2beZzmpqadr3//vt/evPNNz+pqKig/H5/7/bt29fFRrDjSCSi8Dyvapqm0jQt19TU\x71A6HI4gQ8jqdTkLT9Ncul2szIQTt3LnzuEpemd9l3rx5fGFh4RsY47fmzJmjfZ/v\x61OUBDjNWr15NAYBWVlZWwjDMLwDgtkGDBtl7enpUQoiRnp7uFAQhy2yEiQ3OxZs3\x6214BAD2/+93vzhIEYcw555xzWSAQGBg9erSrp6dHNQxDVRRF7+3t9YqiiHRd1wKB\x67CYIgsayrA4A8MEHH/hvuOEGwzCMwD/+8Y+LXnvtteaWlhZ8PHXhxVgCRgjpL7/8\x38m97e3vrL7vsstdjJdu6pQA/MX2bPHmyUVFRkYwQmurz+e4DAGAYRo1Go9DT06NM\x6dDAhF2PsVFWVAIAmCAL7ySefzJs9e/bCCy64ICsjI+Oc119//Q+CIARHjRrl7O7u\x6aiqKojMMo3McZ8TGLWqqquoul0tvbGw09/0au3fvjjQ1NbXs3Lnzz6+99lrzqlWr\x36IOm6KHjwQeYOXOmXlpayn755ZcbX3vttWeOh7LsY/5ITqyOnDdv3oMLFy78EgAY\x51gguLS1lc3NzhVikQly7du3XZmXn2rVrvwQAV1lZmXjxxReP/fWvf10JAOK4ceMy\x69oqK0oYNG+bOy8tzFRUVOYuLix1ZWVm20tJSFvaHsBFAfPICPPjggxm1tbXqM888\x6355Jx8xVr4eiEMcDDfqhsE6Aw0T9q6ur9VtvvbVo7NixjzEMM23NmjWTAUCtrq6m\x59qNJaJvNRgNApKOjY1FTU1PWzp07H7nlllteu/nmmyM1NTX0+vXrmzo7O3eXlZVB\x633NzKDk5GceiRAbLsvru3bsNADC6uroO6K4yKY6iKL6WlparfD7fpEcffRQjhJbC\x2fy/FRuXl5W6KopQNGzYEjg8/mKAf2pppJUQOA6666iqnIAilZ5111iPFxcUVmzZt\x71vntb397ZuwOkYRrbdbiMBMnTsyMdWpR5eXluLa2lgAAqaioQAnDrMx/bwr8t7rR\x31113XdKYMWOqASCpqanpjVAo1BkMBp2tra1fJiUl5SKEgosXL94Mh6FZ/liHdQL8\x41Jgc+4ILLvh9WlragwCg+3w+3TCMFQBgrF69mob/H01oCjAihKgIodaEpdym82YK\x50/mBn8n/4osv/uyBBx4YQQjJ1zTNparq4lWrVvkqKir6OY4bO2rUqJyhQ4d2xyY9\x57Apg4bujt7eXAABgjLewLKtrmkZ8Ph8VDAYbEn9/8NEda3xHh4ha/GBrHHN6EQAo\x399xzz2YA2Jx44tfU1AwAwPLy8nK6urraWpBhifEPi0bEBPmzWbNmTT7ttNM+DQaD\x36tq1azcCAMTi74fmnkc2akEgNtYmwU9IpFCktrZWte6ghcPljVEAAC+99NKbTz31\x31Cr4/yJDy8c6ykFZl+DwXMfJkycDxjjJMAzH0qVL31+4cKE5/9TCUQzLQh2+60h+\x385vf5IqieMnWrVufq6mp+T5jBC1YOLaRn5+fHEtUWQbGwgl7omLrlLV8gBNWCcaP\x488+fccYZM1iWberq6tItJbAU4IRSgPb2dnX48OHji4qKzho+fHjHtm3b/JYSHJ2w\x35gIdfhAAgAULFixSVXWFLMsuS/gtWLBg4USjQlVVVdgaJmzBggULFixYsGDBggUL\x46ixYsGDBggULFixYsGDBgoUfHf8HhSvEftgwyw0AAAAASUVORK5CYII=" },
            ["\x49nfinity"] = { file = "\x6eoir_cursor_v2_09_infinity.png", scale = 1.5, data = "\x69VBORw0KGgoAAAANSUhEUgAAAMAAAADACAYAAABS3GwHAACNvklEQVR42uz9eXSc\x313ngCd9336vqrb2AAqoAFHaAIAjupERKojZbkpXYUmwnsRN3x3Oydqa/r5Neztey\x65zInvU1PZ3ripGN37E5ix5FsbbZ2mou4gwRBkECBKBaWAlD7Xm+9+3K/P1T0Ubtt\x523K8yDP4nYNzSKBQLL73Pvc++wPADjvssMMOO+ywww477LDDDjvssMMOO+ywww47\x37LDDDjvssMMOO+ywww477LDDDjvssMMOO+ywww477LDDDjvssMMOO+ywww477LDD\x44jvssMMOO+ywww477LDDDjvssMMOO+ywww477LDDDjvssMMOO+ywww477LDDDjvs\x73MMOO+ywww477LDDDjvssMMOO+ywww477LDDDjvssMMOO+ywww477LDDDjvssMMO\x4f+ywww477LDDDjvssMMOO+ywA0B2HsEO72GP3N0nEACAzMzMYHd/ODc3B9/1Wudd\x72wPf5887AvAz/MxwZy//vZscAQCgY2Nj333GsiyjmqZhgiBg9XodiqKImKaJ3v05\x51RB3Nz0gSdIpl8sAx3EHwzBI07STTqedsbExJJlMOgAA+4O2DsjP0YaHH9D3+3nf\x2bGg0GiU5jsMBAMC2bcQ0TRRCiLAsi1qWhdq2jZIkiQEAgOM4iOM4KEVRiGEY7978\x71GmaNoQQQRAE2rZtkiRpq6pqYxgGJUmyy+Wy0bklPjCCgPwcbXgEAEBOTk6yJEnS\x4fI5TLMtStm2TnQeOoiiKAQAsAIBlGIaJIIjpOI6maZouy7KaTqeNH/C+8P9FGx6b\x6dZlBms0mKkkS7vF4UFVVcdM0MY7jEBzHcdu2UYIgMBzHMdu2UQzDMARBCIIgEAzD\x76nv64ziOdITGgRAiAAAAIbQIgkAsy3IMwzAdx7FkWbZM07QIgrAdxzFUVTVJknQy\x6dYzZEQi4IwDfh1gsRkciER9Jkl4EQdwQQgJFURJFUdQwDBNCaCEIAiGEiOM4jmma\x46kmSEEEQzLIs4DiOjSAI7JxcNkEQlmEYLdu2WzRNty9fvqz+v0QQ7qo3WDQaxVVV\x78TmOwy3LQmmaxlAUJUmSRAmCQA3DIGiaxjubHqdpmgQA4LZtY7ZtY7qu46Zpos47\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\x2bM6JzwmC4CUIIjg8PLz3+PHjR71er5BKpWrb29sVhmFoVVULPp8vwLJswLIsBEEQ\x32zCMmsfjYRiGoQEAvKqqzWazWavX6zlFUUxVVbVisbjlOA6AEEIMw2hFUSoAAMy2\x62cvtdnscx9EFQSBcLpeXoig3TdMeAABpmqbtOI6pKEoxlUpd3traykaj0dDU1NRH\x47o1Go91uZ8vl8vL6+vqdZrNZnZiY2AsAIMrl8ura2lp2eHi4Z+/evb+i63rr9OnT\x581lbW0tHIhHp5s2byj/02f+oAoDEYjGqcxUzDMMILMsKLMt6KIrqmp6ePvHEE0/8\x61q1Wa54+ffrVdru9zfO8qGlai+M4IRwOT9m2bW9sbJx+4403Xj948OAulmUjtVrt\x34je/+c1LAAAFAIB/5jOf2dPV1fXrKIp6a7XamVardfqv/uqvbnfcYgAAIDz11FNK\x4eptlu7u79UwmEyRJUgcAWAzDGJIkOa1WiwkEAq2zZ89+rysN+8xnPjPqdrv30TS9\x787btEoTwtf/wH/7DtXcLgq7rom3b1s2bN8ud30cPHDgwTJJkxLKsxUuXLpV+wkJA\x68EIh0ufzUaqqEhiGEQzDkCiKMjRN0wiC0DRN8yRJ8oIguFmWFVmWjR04cODeQ4cO\x37Wq32/bCwkJO13UtFAoFKIqySJL0KIqi4zhu+Hw+iuM4qlaryfV6vVQoFCqqqoJa\x72Va0LEthWdbFsqwbx3EMwzBAkiRlmqZpWZbZEQQEQojquq6rqto0DKPduUWAaZqa\x34zgqSZKEIAgul8sV4jiuWxRFz/r6+rlUKnWrUCgUBgcHh91u97BhGNL29vYsAACz\x4cEuCELKO4yj5fH5NlmX0kUceeYqiqMjFixe/mEwmF/v6+qTvSWf5qQgAAgDAfT4f\x4cYoiTRAES1GUx+v1ehEECU5NTT3w0Y9+9NeazaZ08uTJb8uynENR1Gm1Wo2urq7h\x53CSyiyAI/OzZs/9HNput7Nq1617btreuXLny7Vu3buUBAPYTTzyxNxqNPs7zfBxC\x2bOrZs2df6+je4NixY3S73ea3t7dVn88XqdfrDZfLxdu2LQuCQNi2TVmWpXYizGog\x45IhlMpl8oVDQAQASAAB96qmnwHPPPWe/e6MfO3bsfpZlf1GW5U1d11/6kz/5kxsA\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\x6bYZh0BiG8TiOuwOBQBDDsOgTTzzxa4cOHTpx/vz5S8vLy6dxHAe5XG7z4MGDD7nd\x37slyuXzl4sWL34rFYv2O48B8Pp9SFGWzXq+3jhw58jutVuvUX//1X7+0f//+qKqq\x59l9fX288Hr9/fX39lfX19crExMQ94XB4Stf1WrFY3I7FYuMAANTj8fCiKPZhGIay\x4cOvhed5bqVSyiqK0bNvWCYKgLcuSy+XypqqqcqlUymiaJjebzbLL5WIwDCObzWae\x34zjRtm2gKEpTUZSm4zglRVG2k8mkmUgkyHQ6bb8rFReBEAIEQeAf/MEfHOY47vea\x7aeaX/9N/+k9vdArB79bK2ndVpEAg8KDjOJU333xz9gcIATI2NkYYhkE7jkOjKEoy\x44EMiCMKyLMvSNC2QJCkwDONxu92hzum8a2ZmZv+RI0d40zShbdsIwzCgVquBVqsF\x56FV1Go2GZds2aZqmXK/XN9bX1xc3NjZWq9XqFo7jpmmaWDwenxoaGhru6+ub6Onp\x43ZEkCWq1GlhZWcmUSqUVXderuq4bBEHw0Wh0L4ZhpKZp5U6wC6iqWmw2m1nHcYBt\x32xaO4yjHcS4Mw/p5nk9QFMUiCEIUi8UbkiTlcBwnCIIgIpHItGEY6Pnz5//kO9/5\x7avmnnnpqfygU2us4TuT69etfKZVKzYmJifs9Hk+0Xq8v1Gq1ck9Pz5HZ2dkvIwiC\x39fb2HqxWq4vJZHJpaGhotNVq5dbX13MPPvjgp9rt9s2/+7u/ew0AoP04BQDZtWsX\x4b0kSz7Isz7KsyPN8sK+v78CnP/3pPyyXy/XTp09/A0EQTdM0VRAEZnh4+PFWq5W/\x63uXKf0MQhNi1a9dHz5w586/b7Xa9UCgwjz/++KchhPUvfOEL/+7hhx8e297e9kQi\x45aS/v//BS5cuvezxeLj+/v7DXq83JklSHcdxoru7ezAajU74fD6fKIoehmGAaZoA\x51ggURQH1et1SFKWCYRhDURSv67pqGIZs27ZiGEbTNM3a+vr6bLVarTabzUKz2ayh\x4bKo7juO43e4AiqKIqqpNVVVbtm1vXLx4MZdIJCgAAHhXuSTy2c9+Fv+Lv/gL8/d/\x2f/f7fT7fH9u2/frnPve5L989KAAAIJlMGndVmw9/+MMfghBKr7766unvEQIEAIAH\x41gGKIAiK4ziaJEmaYRgGRVGeJElOEASBoii3IAhBj8fTHQ6HJw8cOHDo6NGjjOM4\x30DAMBEVRoOs6KJfLUJIkIMsyBADY+Xw+tbS0dG11dfU2hFD2eDz+Wq1WDAaD0Vgs\x4er1379594+PjvkqlAtrtdmVlZWV1bm7uTC6X28QwDI3FYr2JRGJKlmWXruslTdM0\x57ZalK1euvFKtVpWZmZmZZrOZO3/+/FI8HvcMDw+P3rhxY5EgCJhIJAKyLLdnZmb2\x44wwMfIxhGD9Jkt6lpaXXFUWpDg8PH9V1XXv77be/CADQNjc3cyMjI5HDhw//67W1\x74S+9/fbbVycnJ493dXVNNZvN5fX19ZXu7u6RZ5999su/9mu/9imKoqKvvvrqFwcG\x42vpqtVp5Y2Njqa+vLxaNRo9fvnz5v926dWvjvXqE/l4BmJmZISqVCudyuXiapt0s\x79wZwHI994hOf+OzY2Njh73znO69ubGxcjUQiI4VCYXl4ePgeAACbyWROzc3NnYvF\x59kOlUunGwsLCjWq16vzBH/zB76EouuvcuXN/IknSmizLgSeffPKTLMv2Xb58+blQ\x4bBQYGBh4pFQqbcXj8bGurq4xt9tN9PT0BO4ad9ls1qxUKtl6vZ6r1+tbzWazoChK\x555KkKkVRREfXZUmS5HmeDzEM00VRVMCyLCjLcrbZbK5VKpU7mUwmpeu6xXEc2W63\x794IghAzD0DEMoyzL2jBN88bZs2etRCJBdW4DCwCAPPvss+jTTz9tf/azn3X39PT8\x4a9M01/7Nv/k3/3tH/cFTqRSZz+fVzmYnHn/88cdRFG2+9NJL37lr8AIAsOHhYRpC\x53EEIqY5vn0VRlOc4ju1kcYocxwW8Xm93MBgcP3DgwOGjR48yNE1D0zQRVVVBu90G\x7aWYT6rqOGIYBtre3C+l0+sbq6upyqVS6TRAEoGma7e/v3zMwMHCcZVlhcnLSQxAE\x75HLlys1r166d3draym9ubm4ODw937dmz57jL5RqHEGosy1qzs7Ovzs/PzyMIolIU\x42RRFsURR9Jmmqei6LiMIAlEUJYPBYESW5UKxWKzouo5Fo9GutbW1ot/v97lcLqqr\x716t3enr6MxiGMc1mc5tlWTeCIPbCwsKpYrH49ne+853lP/zDP/wtjuNmMpnM6dnZ\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\x35XJriUTiMIZhPE3T/unp6SFRFGEqldJjsRjX09ODXr9+vfg3f/M3/+e5c+de8vl8\x4bgBAlWVZNgxDcxxHN01T397e1jqp3B/YQYC6rjsAAHN7e3udYRikr6/vsMfjETqd\x72wMsy0by+byytrY2j+O42zAMDUVR3Ov1igiCQEVRmh3vD4GiKAoAAI7jODiO0+/Z\x42lBV9btzYgEAAEEQjGVZFkVRRNd13bZtg+d5X6fLGO5yuWhBEDjLshCfz9dNEIQh\x53VKLoijBsiwLQggBAIBlWW+n8gm0222wvb2dMQyjZZqm6TiOo6qqo2na//A5PoiL\x64ezYMTwajZKKomC2bTM8z9srKytXEAQh9u3b97ggCO5yuVzd3t6e43meGx8f379n\x7a577pqamPAcOHEAajYZz+fJlC8fxAISwsbS09J1MJpMcGhpK7Nmz5+MejyfUbDaT\x72VZrIRKJHAgEAkOaprWCweDAo48++vjAwABbqVTA2NgYOzIyQn3zm9+8+sd//Mef\x571hYOCcIgt5oNNqGYcimaaqyLGumaer5fF4HH/wJmEipVIIAALxcLucLhYJaLpcz\x674ODe1utVltV1cz4+PgvTE9Pd2WzWcu2bYuiKFzX9YLf74/VajWl0+/JURSloGma\x52dM0iiCIiuM49Z4FIJlMwru5MZ0RpChFUTSEEHUcx0EQBGm1WlXLsnSCIKhsNms0\x6d02F53kcAABM04Q3btxYP3ny5CyEUGdZlt3e3s53ugX08jwPstmsUywW86Zptk3T\x56CGEdieybBEEYTcaDYdhmA/iguGrq6sEiqI0AIAiSZLp1EqAxcXFSwRBcIcPH/6k\x33++Pt1otuVwuZ+LxOHbo0CFieHgYpNNpxzAMlCRJsLW1dfLUqVN/JYpiZHBw8Egw\x47NyrqmphZWXlje3t7c1isVidm5t7sVKpbEcikbGnn376qd7eXnpzc9MZHx9H3G43\x2fOpXv/rWX//1X/8FhDBLkqTebDbrd58piqK6y+UyfD7fB/km/R+07na7bQMATMuy\x31Ha7rSwtLb0kSVIbACBvb28vlcvlDa/Xqy8vL29CCI1OdD1LEIQYDAa7Op00BNu2\x48cuyVIqiUNu21c6k0ffuBUIQBFIUhXT6PjodewB22tmhXq83bNu2iSCIhaKo5TiO\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\x2bBUsH3/lHeDT1+ejR4+EZDIpxWKxWLPZZOfm5qauXbv2j6lU6pJhGK1Op7MPAGAQ\x51oxt29pgMBjoum7l8/n0hQsXLoyNjc0mEokZRVHGXNf1HcdRgyBwRVEc7/V666Zp\x44n3ft33fDxiGYaI0i7wsy/FospuNYpjYMAw1VVV7tm07siwnJiYmJkulUlkQBEVV\x56bfdbh/t7u7+8fDwcF3X9Zbv+0Pbtg3HcWzXdQ3HcaxoQu8YhuGIouhHQ55RXM+3\x75RTpp52gXq9zuVxuBkJYAgCYYRg23n333fZoXlCpVIRcLpd2HCcIgsAzTTMQRZGE\x59ShgjImqqiAMQ1gsFhM8z6Pz83OD4ziuUCjEEULpZDLJJ5PJOMdxxWq1et33fa3X\x36+31+/2Tfr+vi6IYSyQSOc/zrKjIeizaCDvY2dnZ63Q6ZiqVsr+ouvtfTQcYDYlK\x70ZIgiiKnKIpgWZai67pw9erV6uLi4j8IglDBGJ9pmnaGMXbDMAw5jkMYY0tV1aGq\x71hbDMGw+n1cKhcJYNpudiMViGZZlZUEQUgghJgiC0UoPiarXGBBCX9f1nmEYneFw\x71FmW5ciynJ2fn//7YrF4IZFIZAghoa7r3fPz8+PT09OHzWZzR9f1c0KI5jiO43me\x36TiOE4Yh1jTNBAA40TkE9yvc3PraOgJ4enilzLLsRBiGnOd5KgDgrFar9X/yk594\x41AD2ueeeywqCoAAAOJ7n45IkiVGVGhYhJLmue5ZMJnOmadqCIMiZTKYmiqLseZ7Z\x36/Uasixz/X5f1zTNVhQlKT6tvuJgjL0opQxPCBk0Go2tjY2N4dLSUri+vm5/XcNI\x2bDU+dFgqlYRsNitACDlN0yTbtuUXXnihVi6Xr0bJqHyMcU/X9WFU9RDBp8WKgyhN\x4fLEsC3ue5xPydF+JYRgAIUQIIUgIAQghBCFEYRgGo4IesixLHMcJpVLpQrFYXIrC\x4e7r9fr/Z6/Ua5+fnDcuyhlEhBWyapjWqgeb7Ph4VCCeEuLZte4qieI1GwwXfnrH+\x6c+0IoF6vy4qijMmynGNZNoEQCnie1y3LGgAABp1OhxiGwSYSCSkWi8U8zxMEQZAB\x41IIgCNAwDJ8Q4iWTyVS/39eDIECyLMuEEEYURZ5hGOI4DoEQIgAAyzAMwRiftdvt\x3052dnUGtVgsmJyfJ113c75vIDIZqtRoHABBEUZSGwyHrOI5UrVZz8/Pz8+l0ek4Q\x68FwYhtDzPN2yrIHneU5U7xUghILoWz+MsqRBAEDg+37AsixiGAb5vg95nhcQQgzH\x63QLLsjLLsiLDMIzjOIZpmueDwaCtqqqKMbZFUfQBAH6Ux981TdNhGIaEYejZtu0I\x67uBHQXheq9Xyow2YEPxtgJ8LYQAAAPTqq6/meZ4vSJJUQAjFIYSK53ndhw8frvM8\x6aziOQxBCblSFnWEYISqXxUEIR6WJSBAEASGEYVmW5TiOIYTojuN0Op3OYH9/HwMA\x52vMN8k1++G8CU6lUOI7j+FENrvPzc0aSJKlcLqenpqbKiUSiLMvyBEKIA09ThXue\x35/kQwjAIAp8Q4kcnlIJo3ZiNHjzDMEz08ggxxnhgmub5+fl53zAMfVQzKggCn2VZ\x34jiOByEMPc8LAQDuKBwbY0w+840ffGaS+7fS+P8jnQFE+wfScDhEBwcHfjKZZAzD\x59BRFEUzT5GKxGPB9H7muyxJCkCiKHACAZxgGiaIYBEHgAAA027aN9fX1zw8bw2/D\x42/7G/v96vc7atg01TWMSiYSEEOI0TUOGYaBoaVIolUpyNptNxGKxmCAIaY7jhFHF\x79ujvkCAISJSG3fZ934iKcWNN02yMsRsFy0FBEGC0cxlGdZD9aOmORBs+xHEcl2XZ\x67OO4oNlsjr7tg7/hhv+FbeP27dvwM4U2Pnvt0/rJAABACIGiKDKCIASSJAWHh4d+\x6f9H4czFQ8Nv0HL9V9XgBAGylUkGu66KJiQnOdV1ECIGu6zK6rkPTNAPDMAAAAMZi\x4dRSGIfr8t4iiKKFlWUE8Hg8lSUKJRCKMfgcghELDMEJZltHoZ47jCMdxwWAwCCVJ\x38hOJBNna2iKf+ab/r9Tov/Y3C+0A/59J8/LyMgIAgNFO5Oii53kolUohhmH+5IGO\x34lg6nU4YjUvDqOYwyOfzsN/vB6N/YxhmVJEe7O3tjWJkAtrg/zYb+l9bB/j37veL\x48nT4Z65/0WcMv22vY4qiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqi\x4bIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqi\x4bIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKOob8W957LDC9fTfpgAAAABJ\x52U5ErkJggg==" },
        }
        cursorState.bundleCache = {}

        local function assetId(value)
            local digits = tostring(value or ""):match("\x28%d+)")
            return digits and ("\x72bxassetid://" .. digits) or ""
        end
        local function isShiftLockVisual(instance)
            if not (instance and (instance:IsA("\x49mageLabel") or instance:IsA("\x49mageButton"))) then return false end
            local name = string.lower(instance.Name)
            for _, keyword in ipairs({ "\x6douselock", "\x73hiftlock", "\x63rosshair", "\x72eticle", "\x61im", "\x74arget", "\x63ursor" }) do if string.find(name, keyword, 1, true) then return true end end
            return false
        end
        local function restoreShiftLockVisuals()
            for instance, original in pairs(cursorState.originalVisuals) do
                if instance and instance.Parent then pcall(function()
                    instance.Image = original.image
                    instance.ImageColor3 = original.color
                    instance.ImageTransparency = original.transparency
                    instance.BackgroundTransparency = original.backgroundTransparency
                    instance.BackgroundColor3 = original.backgroundColor
                    instance.BorderSizePixel = original.borderSize
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
            if cursorState.template == "\x43ustom" then return assetId(cursorState.customId) end
            local direct = cursorState.templateImages[cursorState.template]
            if direct then return direct end
            local cached = cursorState.bundleCache[cursorState.template]
            if cached ~= nil then return cached end
            local bundle = cursorState.bundles[cursorState.template]
            if not bundle then return "" end
            local loader = type(getcustomasset) == "\x66unction" and getcustomasset or (type(getsynasset) == "\x66unction" and getsynasset or nil)
            if not loader or type(writefile) ~= "\x66unction" then cursorState.bundleCache[cursorState.template] = ""; return "" end
            local path = ASSETS_FOLDER .. "\x2f" .. bundle.file
            if not fileExists(path) then
                 
                local decoded
                local ok = pcall(function()
                    local alphabet = "\x41BCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
                    decoded = bundle.data:gsub("\x5b^" .. alphabet .. "\x3d]", ""):gsub("\x2e", function(character)
                        if character == "\x3d" then return "" end
                        local bits, position = "", alphabet:find(character, 1, true) - 1
                        for bit = 6, 1, -1 do bits = bits .. (position % 2 ^ bit - position % 2 ^ (bit - 1) > 0 and "\x31" or "\x30") end
                        return bits
                    end):gsub("\x25d%d%d?%d?%d?%d?%d?%d?", function(bits)
                        if #bits ~= 8 then return "" end
                        local byte = 0
                        for bit = 1, 8 do byte = byte + (bits:sub(bit, bit) == "\x31" and 2 ^ (8 - bit) or 0) end
                        return string.char(byte)
                    end)
                end)
                if not ok or type(decoded) ~= "\x73tring" then cursorState.bundleCache[cursorState.template] = ""; return "" end
                ensureStorageFolders()
                if not pcall(writefile, path, decoded) then cursorState.bundleCache[cursorState.template] = ""; return "" end
            end
            local ok, asset = pcall(loader, path)
            cursorState.bundleCache[cursorState.template] = (ok and type(asset) == "\x73tring") and asset or ""
            return cursorState.bundleCache[cursorState.template]
        end
        local function applyToShiftLockVisual(instance)
            if not cursorState.enabled or not isShiftLockVisual(instance) then return end
            if cursorState.originalVisuals[instance] == nil then
                cursorState.originalVisuals[instance] = {
                    image = instance.Image, color = instance.ImageColor3, transparency = instance.ImageTransparency,
                    backgroundTransparency = instance.BackgroundTransparency, backgroundColor = instance.BackgroundColor3, borderSize = instance.BorderSizePixel,
                    size = instance.Size, scaleType = instance.ScaleType,
                }
            end
            local original, selectedImage = cursorState.originalVisuals[instance], selectedCursorImage()
            pcall(function()
                if selectedImage ~= "" then
                    instance.Image = selectedImage
                    instance.ImageColor3 = cursorState.colorEnabled and cursorState.color or Color3.new(1, 1, 1)
                    instance.ImageTransparency = 0
                     
                    instance.BackgroundTransparency = 1
                    instance.BorderSizePixel = 0
                    instance.ScaleType = Enum.ScaleType.Stretch
                    if math.abs(instance.AnchorPoint.X - .5) < .01 and math.abs(instance.AnchorPoint.Y - .5) < .01 then
                        local bundle = cursorState.bundles[cursorState.template]
                        local multiplier = bundle and bundle.scale or 1
                        local amount = math.clamp((tonumber(cursorState.artworkScale) or 1.35) * multiplier, .75, 3.25)
                        instance.Size = UDim2.new(original.size.X.Scale * amount, math.floor(original.size.X.Offset * amount + .5), original.size.Y.Scale * amount, math.floor(original.size.Y.Offset * amount + .5))
                    else instance.Size = original.size end
                else
                    instance.Image, instance.ImageColor3, instance.ImageTransparency = original.image, (cursorState.colorEnabled and cursorState.color or original.color), original.transparency
                    instance.BackgroundTransparency, instance.BackgroundColor3, instance.BorderSizePixel = original.backgroundTransparency, original.backgroundColor, original.borderSize
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
            for _, parent in ipairs({ CoreGui, LocalPlayer:FindFirstChildOfClass("\x50layerGui") }) do
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
        cursorState.watchConnections = {}
        local playerGui = LocalPlayer:FindFirstChildOfClass("\x50layerGui") or LocalPlayer:WaitForChild("\x50layerGui", 5)
        local function watchShiftLock(parent)
            if not parent then return end
            local connection = parent.DescendantAdded:Connect(function(instance)
                if cursorState.enabled and isShiftLockVisual(instance) then task.defer(function() applyToShiftLockVisual(instance) end) end
            end)
            table.insert(cursorState.watchConnections, connection)
        end
        local function startShiftLockWatch()
            if #cursorState.watchConnections > 0 then return end
            watchShiftLock(CoreGui)
            watchShiftLock(playerGui)
        end
        local function stopShiftLockWatch()
            for _, connection in ipairs(cursorState.watchConnections) do pcall(function() connection:Disconnect() end) end
            table.clear(cursorState.watchConnections)
        end
        local function setCursorEnabled(enabled)
            cursorState.enabled = enabled == true
            if cursorState.enabled then
                startShiftLockWatch()
                applyCursor(true)
            else
                stopShiftLockWatch()
                applyCursor(false)
            end
        end

        local cursorSection = tab:AddSection("\x4dISC • CUSTOMIZE CURSOR", "\x52eplaces the existing Shift Lock/crosshair image; no second curs\x6fr is added")
        cursorSection:AddToggle("\x45nable Custom Cursor", setCursorEnabled)
        local savedTemplate = NoirPersistence.data.dropdowns["\x4dISC • CUSTOMIZE CURSOR::Cursor Design"] or NoirPersistence.data.dropdowns["\x4dISC • CUSTOMIZE CURSOR::Template Cursor"]
        if savedTemplate == "\x43ustom Image" then savedTemplate = "\x43ustom" end
        cursorState.template = table.find(cursorState.templates, savedTemplate) and savedTemplate or "\x44efault"
        local templateControl = cursorSection:AddDropdown("\x43ursor Design", cursorState.templates, function(value) cursorState.template = value; applyCursor(false) end)
        templateControl:SetValue(cursorState.template)
        cursorSection:AddToggle("\x45nable Cursor Color", function(enabled) cursorState.colorEnabled = enabled == true; applyCursor(false) end)
        cursorSection:AddColorpicker("\x43ursor Color", C.accent, function(color) cursorState.color = color; applyCursor(false) end)
        cursorSection:AddSlider("\x43ursor Artwork Scale", 75, 300, 135, function(value) cursorState.artworkScale = (tonumber(value) or 135) / 100; applyCursor(false) end)
        cursorState.customId = tostring(NoirPersistence.data.textboxes["\x4dISC • CUSTOMIZE CURSOR::Custom Cursor ID"] or "")
        local customIdControl = cursorSection:AddTextBox("\x43ustom Cursor ID", function(value)
            cursorState.customId = tostring(value or ""):sub(1, 100)
            NoirPersistence.data.textboxes["\x4dISC • CUSTOMIZE CURSOR::Custom Cursor ID"] = cursorState.customId
            NoirPersistence.Save(); applyCursor(false)
        end)
        customIdControl:SetValue(cursorState.customId)
    end
    buildCustomCursorControls()
end

 
task.defer(function()
    local state = {
        fpsBoost = false, lessLag = false, noShadows = false, frameEnhancement = false,
        optimizeCoins = false, removeChroma = false, removePets = false, removeCoins = false, removeCorpses = false,
        partOriginals = {}, effectOriginals = {}, postOriginals = {},
        coinOriginals = {}, hiddenPets = {}, hiddenCoins = {}, hiddenCorpses = {}, chromaOriginals = {}, perfConnection = nil,
        perfToken = 0, autoScanToken = 0, knownCorpseParts = {}, trackedCharacterParts = {}, originalGlobalShadows = Lighting.GlobalShadows,
        savedQuality = nil, savedMeshDetail = nil, savedDecoration = nil,
    }
    local function setProperty(instance, property, value)
        pcall(function() instance[property] = value end)
    end
    local function isVisualEffect(instance)
        return instance:IsA("\x50articleEmitter") or instance:IsA("\x54rail") or instance:IsA("\x53moke")
            or instance:IsA("\x46ire") or instance:IsA("\x53parkles") or instance:IsA("\x42eam")
            or instance:IsA("\x50ointLight") or instance:IsA("\x53potLight") or instance:IsA("\x53urfaceLight")
    end
     
     
    local function restorePerformance(token)
        local processed = 0
        for instance, original in pairs(state.partOriginals) do
            if token and token ~= state.perfToken then return false end
            if instance and instance.Parent then setProperty(instance, "\x43astShadow", original.castShadow) end
            processed += 1
            if token and processed % 140 == 0 then task.wait() end
        end
        for instance, enabled in pairs(state.effectOriginals) do
            if token and token ~= state.perfToken then return false end
            if instance and instance.Parent then setProperty(instance, "\x45nabled", enabled) end
            processed += 1
            if token and processed % 140 == 0 then task.wait() end
        end
        for instance, enabled in pairs(state.postOriginals) do
            if token and token ~= state.perfToken then return false end
            if instance and instance.Parent then
                local chromaName = string.lower(instance.Name or "")
                local keepChromaHidden = state.removeChroma and (string.find(chromaName, "\x63hroma", 1, true) or string.find(chromaName, "\x63hrom", 1, true) or string.find(chromaName, "\x61berr", 1, true))
                if not keepChromaHidden then setProperty(instance, "\x45nabled", enabled) end
            end
            processed += 1
            if token and processed % 140 == 0 then task.wait() end
        end
        table.clear(state.partOriginals); table.clear(state.effectOriginals); table.clear(state.postOriginals)
        return true
    end
    local function performanceActive()
        return state.fpsBoost or state.lessLag or state.noShadows or state.frameEnhancement
    end
    local function applyPerformanceTo(instance)
        if not performanceActive() or not instance then return end
        local disableShadows = state.fpsBoost or state.lessLag or state.noShadows or state.frameEnhancement
        local reduceEffects = state.fpsBoost or state.lessLag or state.frameEnhancement
        if instance:IsA("\x42asePart") then
            if state.partOriginals[instance] == nil then state.partOriginals[instance] = { castShadow = instance.CastShadow } end
            if disableShadows then setProperty(instance, "\x43astShadow", false) end
        elseif isVisualEffect(instance) then
            if state.effectOriginals[instance] == nil then state.effectOriginals[instance] = instance.Enabled end
            if reduceEffects then setProperty(instance, "\x45nabled", false) end
        elseif instance:IsA("\x43olorCorrectionEffect") or instance:IsA("\x42loomEffect") or instance:IsA("\x42lurEffect") or instance:IsA("\x53unRaysEffect") or instance:IsA("\x44epthOfFieldEffect") then
            if state.postOriginals[instance] == nil then state.postOriginals[instance] = instance.Enabled end
            if reduceEffects then setProperty(instance, "\x45nabled", false) end
        end
    end
    local function refreshPerformance()
        state.perfToken += 1
        local token = state.perfToken
        local active = performanceActive()
        if active then
            if not state.perfConnection then state.perfConnection = Workspace.DescendantAdded:Connect(function(instance) task.defer(applyPerformanceTo, instance) end) end
        elseif state.perfConnection then
            state.perfConnection:Disconnect(); state.perfConnection = nil
        end
         
        task.spawn(function()
            if not restorePerformance(token) or token ~= state.perfToken or not performanceActive() then return end
            local descendants = Workspace:GetDescendants()
            for index, instance in ipairs(descendants) do
                if token ~= state.perfToken then return end
                applyPerformanceTo(instance)
                if index % 140 == 0 then task.wait() end
            end
        end)
        local lowQuality = state.fpsBoost or state.frameEnhancement
        pcall(function()
            if lowQuality then
                if state.savedQuality == nil then state.savedQuality = settings().Rendering.QualityLevel end
                if state.savedMeshDetail == nil then state.savedMeshDetail = settings().Rendering.MeshPartDetailLevel end
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
                settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Disabled
            elseif state.savedQuality ~= nil then
                settings().Rendering.QualityLevel = state.savedQuality
                settings().Rendering.MeshPartDetailLevel = state.savedMeshDetail
                state.savedQuality, state.savedMeshDetail = nil, nil
            end
        end)
        pcall(function()
            if lowQuality then
                if state.savedDecoration == nil then state.savedDecoration = Workspace.Terrain.Decoration end
                Workspace.Terrain.Decoration = false
            elseif state.savedDecoration ~= nil then
                Workspace.Terrain.Decoration = state.savedDecoration
                state.savedDecoration = nil
            end
        end)
        pcall(function()
            Lighting.GlobalShadows = active and false or state.originalGlobalShadows
        end)
    end
    local function matchesNamedVisual(instance, words)
        local current, depth = instance, 0
        while current and depth < 4 do
            local name = string.lower(current.Name or "")
            for _, word in ipairs(words) do if string.find(name, word, 1, true) then return true end end
            current, depth = current.Parent, depth + 1
        end
        return false
    end
    local function setHidden(root, bucket, hidden, deep)
        local function update(part)
            if not part:IsA("\x42asePart") then return end
            if bucket[part] == nil then bucket[part] = part.LocalTransparencyModifier end
            part.LocalTransparencyModifier = hidden and 1 or bucket[part]
        end
        if root:IsA("\x42asePart") then update(root) end
        if deep then for _, instance in ipairs(root:GetDescendants()) do update(instance) end end
    end
    local function restoreHidden(bucket)
        local token = state.autoScanToken
        task.spawn(function()
            local processed = 0
            for part, original in pairs(bucket) do
                if token ~= state.autoScanToken then return end
                if part and part.Parent then setProperty(part, "\x4cocalTransparencyModifier", original) end
                processed += 1
                if processed % 140 == 0 then task.wait() end
            end
            table.clear(bucket)
        end)
    end
    local function applyCoinOptimization(instance)
        if instance:IsA("\x42asePart") then
            if state.coinOriginals[instance] == nil then state.coinOriginals[instance] = { material = instance.Material, castShadow = instance.CastShadow } end
            setProperty(instance, "\x4daterial", Enum.Material.SmoothPlastic); setProperty(instance, "\x43astShadow", false)
        elseif isVisualEffect(instance) then
            if state.coinOriginals[instance] == nil then state.coinOriginals[instance] = { enabled = instance.Enabled } end
            setProperty(instance, "\x45nabled", false)
        end
    end
    local function restoreCoinOptimization()
        local token = state.autoScanToken
        task.spawn(function()
            local processed = 0
            for instance, original in pairs(state.coinOriginals) do
                if token ~= state.autoScanToken then return end
                if instance and instance.Parent then
                    if original.material ~= nil then setProperty(instance, "\x4daterial", original.material); setProperty(instance, "\x43astShadow", original.castShadow) else setProperty(instance, "\x45nabled", original.enabled) end
                end
                processed += 1
                if processed % 140 == 0 then task.wait() end
            end
            table.clear(state.coinOriginals)
        end)
    end
    local petWords, coinWords, corpseWords = { "\x70et", "\x63ompanion", "\x6dinion", "\x66amiliar" }, { "\x63oin", "\x63urrency", "\x74oken" }, { "\x63orpse", "\x72agdoll", "\x64eadbody" }
     
     
    local function hideKnownCorpseParts()
        if not state.removeCorpses then return end
        for part in pairs(state.knownCorpseParts) do
            if part and part.Parent then setHidden(part, state.hiddenCorpses, true) end
        end
    end
    local function applyAutoVisuals(instance)
        if state.optimizeCoins and matchesNamedVisual(instance, coinWords) then applyCoinOptimization(instance) end
        if state.removePets and matchesNamedVisual(instance, petWords) then setHidden(instance, state.hiddenPets, true) end
        if state.removeCoins and matchesNamedVisual(instance, coinWords) then setHidden(instance, state.hiddenCoins, true) end
        if state.removeCorpses then
            if state.knownCorpseParts[instance] then
                setHidden(instance, state.hiddenCorpses, true)
            elseif matchesNamedVisual(instance, corpseWords) then
                 
                setHidden(instance, state.hiddenCorpses, true, instance:IsA("\x4dodel") or instance:IsA("\x46older"))
            end
        end
        if state.removeChroma and (instance:IsA("\x43olorCorrectionEffect") or instance:IsA("\x42loomEffect") or instance:IsA("\x42lurEffect")) then
            local name = string.lower(instance.Name or "")
            if string.find(name, "\x63hroma", 1, true) or string.find(name, "\x63hrom", 1, true) or string.find(name, "\x61berr", 1, true) then
                if state.chromaOriginals[instance] == nil then state.chromaOriginals[instance] = instance.Enabled end
                setProperty(instance, "\x45nabled", false)
            end
        end
    end
    local function scanAutoVisuals()
        state.autoScanToken += 1
        local token = state.autoScanToken
        task.spawn(function()
            for _, parent in ipairs({ Workspace, Lighting }) do
                local descendants = parent:GetDescendants()
                for index, instance in ipairs(descendants) do
                    if token ~= state.autoScanToken then return end
                    applyAutoVisuals(instance)
                    if index % 140 == 0 then task.wait() end
                end
            end
        end)
    end
    local function updateAutoVisualConnections()
        local enabled = state.optimizeCoins or state.removeChroma or state.removePets or state.removeCoins or state.removeCorpses
        if enabled then
            if not state.autoWorkspaceConnection then
                state.autoWorkspaceConnection = Workspace.DescendantAdded:Connect(function(instance)
                    task.defer(applyAutoVisuals, instance)
                end)
            end
            if not state.autoLightingConnection then
                state.autoLightingConnection = Lighting.DescendantAdded:Connect(function(instance)
                    task.defer(applyAutoVisuals, instance)
                end)
            end
        else
            state.autoScanToken += 1
            if state.autoWorkspaceConnection then state.autoWorkspaceConnection:Disconnect(); state.autoWorkspaceConnection = nil end
            if state.autoLightingConnection then state.autoLightingConnection:Disconnect(); state.autoLightingConnection = nil end
        end
    end
    local corpseHumanoidConnections, characterTrackConnections = {}, {}
    local function markCharacterAsCorpse(character)
        if not character then return end
        local parts = state.trackedCharacterParts[character]
        if not parts then return end
        for part in pairs(parts) do
            state.knownCorpseParts[part] = true
            if state.removeCorpses and part and part.Parent then setHidden(part, state.hiddenCorpses, true) end
        end
    end
    local function watchCorpseHumanoid(character, humanoid)
        if not humanoid or corpseHumanoidConnections[humanoid] then return end
        corpseHumanoidConnections[humanoid] = true
        humanoid.Died:Connect(function() task.defer(markCharacterAsCorpse, character) end)
        humanoid.HealthChanged:Connect(function(health)
            if health <= 0 then task.defer(markCharacterAsCorpse, character) end
        end)
        if humanoid.Health <= 0 then task.defer(markCharacterAsCorpse, character) end
    end
    local function trackPlayerCharacter(character)
        if not character or state.trackedCharacterParts[character] then return end
        local parts = {}
        state.trackedCharacterParts[character] = parts
        local function remember(instance)
            if instance:IsA("\x42asePart") then parts[instance] = true end
            if instance:IsA("\x48umanoid") then watchCorpseHumanoid(character, instance) end
        end
        for _, instance in ipairs(character:GetDescendants()) do remember(instance) end
        local descendantConnection = character.DescendantAdded:Connect(remember)
        characterTrackConnections[character] = descendantConnection
        local humanoid = character:FindFirstChildWhichIsA("\x48umanoid")
        if humanoid then watchCorpseHumanoid(character, humanoid) end
    end
    local function watchPlayerForCorpses(player)
        if player.Character then trackPlayerCharacter(player.Character) end
        player.CharacterAdded:Connect(trackPlayerCharacter)
        player.CharacterRemoving:Connect(function(character)
            local humanoid = character and character:FindFirstChildWhichIsA("\x48umanoid")
            if humanoid and humanoid.Health <= 0 then markCharacterAsCorpse(character) end
        end)
    end
    for _, player in ipairs(Players:GetPlayers()) do watchPlayerForCorpses(player) end
    Players.PlayerAdded:Connect(watchPlayerForCorpses)

    local fpsSection = tab:AddSection("\x4dISC • FPS", "\x4cocal visual-performance controls; server-side objects and round\x20rules are not changed")
    fpsSection:AddToggle("\x46ps Boost", function(enabled) state.fpsBoost = enabled == true; refreshPerformance() end)
    fpsSection:AddToggle("\x4cess Lag", function(enabled) state.lessLag = enabled == true; refreshPerformance() end)
    fpsSection:AddToggle("\x4eo Shadows", function(enabled) state.noShadows = enabled == true; refreshPerformance() end)
    fpsSection:AddToggle("\x4fptimize Coins", function(enabled)
        state.optimizeCoins = enabled == true
        updateAutoVisualConnections()
        if state.optimizeCoins then scanAutoVisuals() else restoreCoinOptimization() end
    end)
    fpsSection:AddToggle("\x41uto Remove Chroma Effects", function(enabled)
        state.removeChroma = enabled == true
        updateAutoVisualConnections()
        if state.removeChroma then scanAutoVisuals() else
            for instance, original in pairs(state.chromaOriginals) do if instance and instance.Parent then setProperty(instance, "\x45nabled", original) end end
            table.clear(state.chromaOriginals)
        end
    end)
    fpsSection:AddToggle("\x41uto Remove Pets Display", function(enabled)
        state.removePets = enabled == true
        updateAutoVisualConnections()
        if state.removePets then scanAutoVisuals() else restoreHidden(state.hiddenPets) end
    end)
    fpsSection:AddToggle("\x41uto Remove Coins", function(enabled)
        state.removeCoins = enabled == true
        updateAutoVisualConnections()
        if state.removeCoins then scanAutoVisuals() else restoreHidden(state.hiddenCoins) end
    end)
    fpsSection:AddToggle("\x41uto Remove Corpses", function(enabled)
        state.removeCorpses = enabled == true
        updateAutoVisualConnections()
        if state.removeCorpses then hideKnownCorpseParts(); scanAutoVisuals() else restoreHidden(state.hiddenCorpses) end
    end)
    fpsSection:AddToggle("\x45nable Frame Enhancement", function(enabled) state.frameEnhancement = enabled == true; refreshPerformance() end)
end)

 
task.defer(function()
    local oldRuntime = getgenv().__NoirMiscAimlockRuntime
    if type(oldRuntime) == "\x74able" and type(oldRuntime.Stop) == "\x66unction" then pcall(oldRuntime.Stop) end

     
     
     
    local aimSizeStorageKey = "\x4eoirAimlockBindSizeV2"
    local aimSizeControlKey = "\x4dISC • AIMLOCK::Aimlock Bind Button Size"
     
     
    local savedAimBindPercent = tonumber(NoirPersistence.data.sliders[aimSizeStorageKey]) or 8
    savedAimBindPercent = math.clamp(math.floor(savedAimBindPercent + .5), 5, 25)
     
     
    NoirPersistence.data.sliders[aimSizeControlKey] = savedAimBindPercent

    local aim = {
        enabled = false, wallCheck = false, fovEnabled = false, fovRadius = 250,
        smoothness = .25, smoothRate = 18, horizontalPrediction = false, prediction = .145,
        targetPart = "\x48ead", selectedPlayer = nil, targetPlayer = nil, lastSearch = 0, searchInterval = .10,
        lastAimPos = nil, lastTarget = nil, cachedPlayer = nil, cachedCharacter = nil,
        cachedRoot = nil, cachedHead = nil, key = "\x54", bindVisible = false, bindSize = savedAimBindPercent / 100,
        overlay = nil, bindButton = nil, bindOuterGradient = nil, bindInnerGradient = nil, bindPressScale = nil,
        fovCircle = nil, connections = {}, bindConnections = {}, stopped = false,
    }
    local function connect(signal, callback)
        local connection = signal:Connect(callback)
        aim.connections[#aim.connections + 1] = connection
        return connection
    end
    local function validPlayer(player)
        local character = player and player.Character
        local humanoid = character and character:FindFirstChildWhichIsA("\x48umanoid")
        return player and player ~= LocalPlayer and character and humanoid and humanoid.Health > 0
    end
    local function clearCache()
        aim.cachedPlayer, aim.cachedCharacter, aim.cachedRoot, aim.cachedHead = nil, nil, nil, nil
        aim.lastAimPos, aim.lastTarget = nil, nil
    end
    local function findMurdererForAimlock()
         
        if validPlayer(murderer) then return murderer end
        for _, player in ipairs(getPlayers()) do
            if validPlayer(player) and roleCache[player.UserId] == "\x6durderer" then return player end
        end
        local closest, closestDistance, ownRoot = nil, math.huge, localRoot()
        for _, player in ipairs(getPlayers()) do
            if validPlayer(player) and playerHasTool(player, "\x4bnife") then
                local root = player.Character:FindFirstChild("\x48umanoidRootPart")
                local distance = ownRoot and root and (root.Position - ownRoot.Position).Magnitude or 0
                if distance < closestDistance then closest, closestDistance = player, distance end
            end
        end
        return closest
    end
    local function getAimTarget()
        if validPlayer(aim.selectedPlayer) then return aim.selectedPlayer end
        aim.selectedPlayer = nil
        return validPlayer(aim.targetPlayer) and aim.targetPlayer or nil
    end
    local function resolvePart(player)
        local character = player and player.Character
        if not character then return nil end
        if aim.cachedPlayer ~= player or aim.cachedCharacter ~= character then
            aim.cachedPlayer, aim.cachedCharacter = player, character
            aim.cachedRoot = character:FindFirstChild("\x48umanoidRootPart")
            aim.cachedHead = character:FindFirstChild("\x48ead")
            aim.lastAimPos, aim.lastTarget = nil, nil
        end
        return aim.targetPart == "\x48umanoidRootPart" and aim.cachedRoot or aim.cachedHead or aim.cachedRoot
    end
    local function hasLineOfSight(part, player)
        if not aim.wallCheck then return true end
        local camera, character = Workspace.CurrentCamera, player and player.Character
        if not camera or not character then return false end
        local ownCharacter = LocalPlayer.Character
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = ownCharacter and { ownCharacter, character } or { character }
        params.IgnoreWater = true
        local visible, checked = 0, 0
        for _, name in ipairs({ "\x48ead", "\x55pperTorso", "\x54orso", "\x48umanoidRootPart" }) do
            local checkPart = character:FindFirstChild(name)
            if checkPart then
                checked += 1
                if not Workspace:Raycast(camera.CFrame.Position, checkPart.Position - camera.CFrame.Position, params) then visible += 1 end
            end
        end
        return checked == 0 or visible >= (checked >= 3 and 2 or 1)
    end
    local function inFov(worldPosition)
        if not aim.fovEnabled then return true end
        local camera = Workspace.CurrentCamera
        if not camera then return false end
        local point, onScreen = camera:WorldToViewportPoint(worldPosition)
        if not onScreen then return false end
        local size = camera.ViewportSize
        return (Vector2.new(point.X, point.Y) - Vector2.new(size.X * .5, size.Y * .5)).Magnitude <= aim.fovRadius
    end
    local function ensureOverlay()
        if aim.overlay and aim.overlay.Parent then return aim.overlay end
        for _, parent in ipairs({ guiParent, CoreGui, LocalPlayer:FindFirstChildOfClass("\x50layerGui") }) do
            if parent then
                local stale = parent:FindFirstChild("\x4eoirAimlockOverlay")
                if stale then stale:Destroy() end
            end
        end
        local parent = guiParent
        if typeof(parent) ~= "\x49nstance" then parent = LocalPlayer:FindFirstChildOfClass("\x50layerGui") end
        if typeof(parent) ~= "\x49nstance" then return nil end
        aim.overlay = New("\x53creenGui", { Name = "\x4eoirAimlockOverlay", Parent = parent, ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 84, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
        return aim.overlay
    end
    local function updateFovCircle()
        if not aim.fovEnabled then
            if aim.fovCircle then aim.fovCircle.Visible = false end
            return
        end
        local overlay = ensureOverlay()
        if not overlay then return end
        if not aim.fovCircle or not aim.fovCircle.Parent then
            local circle = New("\x46rame", { Name = "\x46OV", Parent = overlay, AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 1 })
            local rounded = New("\x55ICorner", { Parent = circle, CornerRadius = UDim.new(1, 0) })
            local outline = New("\x55IStroke", { Parent = circle, Color = C.accent, Thickness = 1.4, Transparency = .18 })
            aim.fovCircle = circle
        end
        aim.fovCircle.Visible = true
        aim.fovCircle.Size = UDim2.fromOffset(aim.fovRadius * 2, aim.fovRadius * 2)
    end
    local aimMetallicGradient = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 40)), ColorSequenceKeypoint.new(.22, Color3.fromRGB(250, 250, 252)),
        ColorSequenceKeypoint.new(.48, Color3.fromRGB(70, 70, 78)), ColorSequenceKeypoint.new(.72, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(45, 45, 52)),
    })
    local aimActiveGradient = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(104, 18, 32)), ColorSequenceKeypoint.new(.24, Color3.fromRGB(255, 126, 145)),
        ColorSequenceKeypoint.new(.5, Color3.fromRGB(185, 38, 62)), ColorSequenceKeypoint.new(.76, Color3.fromRGB(255, 170, 183)), ColorSequenceKeypoint.new(1, Color3.fromRGB(112, 18, 35)),
    })
    local function bindButtonPixels()
         
         
         
        local camera = Workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize
        local shortEdge = viewport and math.min(viewport.X, viewport.Y) or 720
         
         
        return math.clamp(math.floor(shortEdge * aim.bindSize * .5 + .5), 24, 96)
    end
    local function updateBindSize()
        local button = aim.bindButton
        if not button then return end
         
        local pixels = bindButtonPixels()
        button.Size = UDim2.fromOffset(pixels, pixels)
    end
    local function updateBindVisual()
        local button = aim.bindButton
        if not button then return end
        local label = button:FindFirstChild("\x54ext")
        if label then label.Text = "\x41imlock" end
        if aim.bindOuterGradient then aim.bindOuterGradient.Color = aim.enabled and aimActiveGradient or aimMetallicGradient end
        if aim.bindInnerGradient then aim.bindInnerGradient.Color = aim.enabled and aimActiveGradient or aimMetallicGradient end
    end
    local function setAimlock(enabled)
        aim.enabled = enabled == true
        if aim.enabled then
            aim.targetPlayer = findMurdererForAimlock()
        else
            aim.targetPlayer = nil
            clearCache()
        end
        updateBindVisual()
    end
    local function disconnectBindButton()
        for _, connection in ipairs(aim.bindConnections or {}) do pcall(function() connection:Disconnect() end) end
        aim.bindConnections = {}
    end
    local function removeBindButton()
        disconnectBindButton()
        if aim.bindButton and aim.bindButton.Parent then aim.bindButton:Destroy() end
        aim.bindButton, aim.bindOuterGradient, aim.bindInnerGradient, aim.bindPressScale = nil, nil, nil, nil
        if aim.overlay then
            local stale = aim.overlay:FindFirstChild("\x41imlockButton")
            if stale then stale:Destroy() end
        end
    end
    local function createBindButton()
        if aim.bindButton then return end
        local overlay = ensureOverlay()
        if not overlay then return end
         
        local initialPixels = bindButtonPixels()
        local button = New("\x49mageButton", { Name = "\x41imlockButton", Parent = overlay, AnchorPoint = Vector2.new(.5, .5), Position = NoirPersistence.GetPosition("\x61imlock_bind_v1", UDim2.new(.83, 0, .70, 0)),
            Size = UDim2.fromOffset(initialPixels, initialPixels), BackgroundColor3 = Color3.fromRGB(8, 8, 10), BackgroundTransparency = .28, BorderSizePixel = 0, AutoButtonColor = false,
            Image = "", ClipsDescendants = false, ZIndex = 8 })
        corner(button, 999)
        local aspect = New("\x55IAspectRatioConstraint", { Parent = button, AspectRatio = 1, AspectType = Enum.AspectType.ScaleWithParentSize })
        local outer = New("\x55IStroke", { Parent = button, Color = Color3.fromRGB(255, 255, 255), Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
        local outerGradient = New("\x55IGradient", { Parent = outer, Color = aimMetallicGradient })
        table.insert(gradientStrokes, outerGradient)
        local inner = New("\x55IStroke", { Parent = button, Color = Color3.fromRGB(105, 105, 112), Transparency = .5, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
        local innerGradient = outerGradient:Clone(); innerGradient.Rotation = 180; innerGradient.Parent = inner; table.insert(gradientStrokes, innerGradient)
        local label = New("\x54extLabel", { Parent = button, Name = "\x54ext", AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromScale(.76, .76),
            BackgroundTransparency = 1, Text = "\x41imlock", TextColor3 = Color3.fromRGB(245, 245, 248), TextSize = 12, TextWrapped = true, Font = Enum.Font.Gotham, ZIndex = 9 })
        local pressScale = New("\x55IScale", { Parent = button, Scale = 1 })
        aim.bindOuterGradient, aim.bindInnerGradient, aim.bindPressScale = outerGradient, innerGradient, pressScale
        local dragging, moved, dragStart, startPosition, dragInput = false, false, nil, nil, nil
        aim.bindConnections[#aim.bindConnections + 1] = button.InputBegan:Connect(function(input)
            if not isPrimaryPress(input) then return end
            dragging, moved, dragStart, startPosition = true, false, input.Position, button.Position
            TweenService:Create(pressScale, TweenInfo.new(.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Scale = 1.035 }):Play()
        end)
        aim.bindConnections[#aim.bindConnections + 1] = button.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
        end)
        aim.bindConnections[#aim.bindConnections + 1] = UIS.InputChanged:Connect(function(input)
            if not dragging or input ~= dragInput then return end
            local delta = input.Position - dragStart
            if delta.Magnitude > 7 then moved = true end
            button.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end)
        aim.bindConnections[#aim.bindConnections + 1] = UIS.InputEnded:Connect(function(input)
            if not dragging or not isPrimaryPress(input) then return end
            dragging = false
            TweenService:Create(pressScale, TweenInfo.new(.20, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
            if moved then NoirPersistence.SetPosition("\x61imlock_bind_v1", button.Position) end
        end)
        aim.bindConnections[#aim.bindConnections + 1] = button.Activated:Connect(function()
            if not moved then setAimlock(not aim.enabled) end
        end)
        aim.bindButton = button
        updateBindSize(); updateBindVisual()
    end
    local function setBindVisible(enabled)
        aim.bindVisible = enabled == true
        if aim.bindVisible then createBindButton() else removeBindButton() end
    end
    local function aimStep(dt)
        if aim.stopped or not aim.enabled then return end
        local now = os.clock()
        if now - aim.lastSearch >= aim.searchInterval then
            aim.lastSearch = now
            if not validPlayer(aim.selectedPlayer) then aim.selectedPlayer = nil end
            if not aim.selectedPlayer then aim.targetPlayer = findMurdererForAimlock() end
        end
        local target = getAimTarget()
        local part, camera = target and resolvePart(target), Workspace.CurrentCamera
        if not part or not camera or not hasLineOfSight(part, target) then aim.lastAimPos = nil; return end
        if aim.lastTarget ~= target then aim.lastAimPos, aim.lastTarget = nil, target end
        local velocity = part.AssemblyLinearVelocity
        local predicted = Vector3.new(aim.horizontalPrediction and velocity.X * aim.prediction or 0, velocity.Y * .3 * aim.prediction, aim.horizontalPrediction and velocity.Z * aim.prediction or 0)
        local aimPosition = part.Position + predicted
        if not inFov(aimPosition) then aim.lastAimPos = nil; return end
        if aim.lastAimPos and aim.smoothness > 0 then
            local alpha = math.clamp(1 - math.exp(-aim.smoothRate * dt), 0, 1)
            aimPosition = aim.lastAimPos:Lerp(aimPosition, alpha)
        end
        aim.lastAimPos = aimPosition
        pcall(function() camera.CFrame = CFrame.lookAt(camera.CFrame.Position, aimPosition, Vector3.new(0, 1, 0)) end)
    end
    local function playerChoices()
        local names = { "\x41uto Murderer" }
        for _, player in ipairs(getPlayers()) do if player ~= LocalPlayer then names[#names + 1] = player.Name end end
        table.sort(names, function(a, b) if a == "\x41uto Murderer" then return true elseif b == "\x41uto Murderer" then return false end return string.lower(a) < string.lower(b) end)
        return names
    end
    local aimSection = tab:AddSection("\x4dISC • AIMLOCK", "\x43amera lock for Murderer or a selected player • all controls are \x6cocal")
    aimSection:AddToggle("\x45nable Aimlock", setAimlock)
    aimSection:AddToggle("\x45nable Aimlock Bind Button", setBindVisible)
    aimSection:AddSlider("\x41imlock Bind Button Size", 5, 25, savedAimBindPercent, function(value)
        local percent = math.clamp(math.floor((tonumber(value) or savedAimBindPercent) + .5), 5, 25)
        aim.bindSize = percent / 100
         
        NoirPersistence.data.sliders[aimSizeStorageKey] = percent
        NoirPersistence.data.sliders[aimSizeControlKey] = percent
        NoirPersistence.Save()
        if aim.bindPressScale then aim.bindPressScale.Scale = 1 end
        updateBindSize()
    end)
    aimSection:AddToggle("\x41imlock Wall Check", function(enabled) aim.wallCheck = enabled == true end)
    aimSection:AddToggle("\x41imlock FOV Check", function(enabled) aim.fovEnabled = enabled == true; updateFovCircle() end)
    aimSection:AddSlider("\x41imlock FOV Radius", 50, 800, 250, function(value) aim.fovRadius = tonumber(value) or 250; updateFovCircle() end)
    aimSection:AddSlider("\x41imlock Smoothness", 0, 95, 25, function(value)
        local percent = math.clamp((tonumber(value) or 25) / 100, 0, .95)
        aim.smoothness = percent
        aim.smoothRate = percent <= .001 and 1000 or math.clamp(24 * (1 - percent) + 1, 1, 1000)
    end)
    aimSection:AddToggle("\x41imlock Horizontal Prediction", function(enabled) aim.horizontalPrediction = enabled == true end)
    local playerSelector = aimSection:AddDropdown("\x41imlock Target Player", playerChoices(), function(name)
        aim.selectedPlayer = name == "\x41uto Murderer" and nil or Players:FindFirstChild(name)
        if not aim.selectedPlayer then aim.targetPlayer = findMurdererForAimlock() end
        clearCache()
    end)
    aimSection:AddButton("\x52efresh Aimlock Player List", function()
        local selected = aim.selectedPlayer and aim.selectedPlayer.Name or "\x41uto Murderer"
        playerSelector:Refresh(playerChoices(), selected)
    end)
    aimSection:AddButton("\x43lear Aimlock Player Selection", function()
        aim.selectedPlayer = nil; aim.targetPlayer = findMurdererForAimlock(); clearCache()
        playerSelector:SetValue("\x41uto Murderer")
    end)
    aimSection:AddDropdown("\x41imlock Target Body Part", { "\x48ead", "\x48umanoidRootPart" }, function(value) aim.targetPart = value; clearCache() end)
    aimSection:AddDropdown("\x41imlock Prediction", { "\x4dedium (0.145)", "\x4cow (0.08)", "\x48igh (0.20)", "\x44isabled" }, function(value)
        aim.prediction = string.find(value, "\x4cow", 1, true) and .08 or string.find(value, "\x48igh", 1, true) and .20 or value == "\x44isabled" and 0 or .145
    end)
    aimSection:AddKeybind("\x41imlock Quick Toggle", "\x54", function(value) aim.key = tostring(value or "\x54") end)
    aimSection:AddLabel("\x54ip: select Auto Murderer for automatic role targeting. Drag the\x20round AIM button to move it.")

    connect(UIS.InputBegan, function(input, processed)
        if processed or UIS:GetFocusedTextBox() then return end
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == aim.key then setAimlock(not aim.enabled) end
    end)
    connect(Players.PlayerRemoving, function(player)
        if aim.selectedPlayer == player then aim.selectedPlayer = nil end
        if aim.targetPlayer == player then aim.targetPlayer = nil end
        clearCache()
    end)
    connect(LocalPlayer.CharacterAdded, function()
        aim.targetPlayer = nil; aim.selectedPlayer = nil; clearCache()
        task.delay(1, function() if aim.enabled and not aim.stopped then aim.targetPlayer = findMurdererForAimlock() end end)
    end)
    connect(Workspace:GetPropertyChangedSignal("\x43urrentCamera"), function() updateBindSize(); updateFovCircle() end)
    RunService:BindToRenderStep("\x4eoirMiscAimlock", Enum.RenderPriority.Camera.Value + 1, aimStep)
    getgenv().__NoirMiscAimlockRuntime = {
        Stop = function()
            if aim.stopped then return end
            aim.stopped = true
            pcall(function() RunService:UnbindFromRenderStep("\x4eoirMiscAimlock") end)
            for _, connection in ipairs(aim.connections) do pcall(function() connection:Disconnect() end) end
            disconnectBindButton()
            if aim.overlay then aim.overlay:Destroy() end
            aim.overlay, aim.bindButton, aim.fovCircle = nil, nil, nil
        end,
    }
end)

 
do
    local function buildUniversalUtilities()
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

         
        local function restoreInvisible()
            for instance, transparency in pairs(universalState.invisibleOriginals) do
                if instance and instance.Parent then pcall(function() instance.Transparency = transparency end) end
            end
            table.clear(universalState.invisibleOriginals)
        end

        local function setupInvisibleCharacter(character)
            universalState.invisibleCharacter = character or LocalPlayer.Character
            local current = universalState.invisibleCharacter
            universalState.invisibleHumanoid = current and current:FindFirstChildWhichIsA("\x48umanoid") or nil
            universalState.invisibleRoot = current and current:FindFirstChild("\x48umanoidRootPart") or nil
            table.clear(universalState.invisibleOriginals)
            if not current then return end
            for _, instance in ipairs(current:GetDescendants()) do
                 
                if instance:IsA("\x42asePart") and instance.Transparency == 0 then
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
            local label = button:FindFirstChild("\x54ext")
            if label then label.Text = universalState.invisible and "\x49nvisible\nON" or "\x49nvisible\nOFF" end
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
            for _, parent in ipairs({ guiParent, CoreGui, LocalPlayer:FindFirstChildOfClass("\x50layerGui") }) do
                if typeof(parent) == "\x49nstance" then
                    local stale = parent:FindFirstChild("\x4eoirInvisibleBindButton")
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
            if typeof(parent) ~= "\x49nstance" then parent = LocalPlayer:WaitForChild("\x50layerGui") end
            local bindGui = Instance.new("\x53creenGui")
            bindGui.Name, bindGui.ResetOnSpawn, bindGui.IgnoreGuiInset, bindGui.DisplayOrder = "\x4eoirInvisibleBindButton", false, true, 82
            bindGui.Parent = parent

            local button = Instance.new("\x49mageButton")
            button.Name = "\x49nvisible"
            button.AnchorPoint = Vector2.new(.5, .5)
            button.Position = NoirPersistence.GetPosition("\x69nvisible_bind_v1", UDim2.new(.24, 0, .88, 0))
            button.Size = UDim2.new(universalState.invisibleBindSize, 0, universalState.invisibleBindSize, 0)
            button.BackgroundColor3, button.BackgroundTransparency, button.BorderSizePixel = Color3.fromRGB(8, 8, 10), .28, 0
            button.Image, button.AutoButtonColor, button.ZIndex = "", false, 5
            button.Parent = bindGui
            local round = Instance.new("\x55ICorner"); round.CornerRadius = UDim.new(1, 0); round.Parent = button
            local aspect = Instance.new("\x55IAspectRatioConstraint"); aspect.AspectRatio = 1; aspect.Parent = button
            local outerStroke = Instance.new("\x55IStroke")
            outerStroke.Color, outerStroke.Thickness, outerStroke.ApplyStrokeMode, outerStroke.Parent = Color3.fromRGB(255, 255, 255), 2, Enum.ApplyStrokeMode.Border, button
            local outerGradient = Instance.new("\x55IGradient")
            outerGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(35,35,40)), ColorSequenceKeypoint.new(.22, Color3.fromRGB(250,250,252)),
                ColorSequenceKeypoint.new(.48, Color3.fromRGB(70,70,78)), ColorSequenceKeypoint.new(.72, Color3.fromRGB(255,255,255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(45,45,52)),
            })
            outerGradient.Parent = outerStroke
            local innerStroke = Instance.new("\x55IStroke")
            innerStroke.Color, innerStroke.Transparency, innerStroke.Thickness, innerStroke.Parent = Color3.fromRGB(105,105,112), .5, 1, button
            local innerGradient = outerGradient:Clone(); innerGradient.Rotation = 180; innerGradient.Parent = innerStroke
            local label = Instance.new("\x54extLabel")
            label.Name, label.AnchorPoint, label.Position, label.Size = "\x54ext", Vector2.new(.5,.5), UDim2.fromScale(.5,.5), UDim2.fromScale(.76,.76)
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
                NoirPersistence.SetPosition("\x69nvisible_bind_v1", button.Position)
            end)
            universalState.invisibleBindConnections[#universalState.invisibleBindConnections + 1] = button.Activated:Connect(function()
                if not moved then setInvisible(not universalState.invisible) end
            end)
            table.insert(gradientStrokes.fast, outerGradient)
            universalState.invisibleBindGui, universalState.invisibleBindButton = bindGui, button
            updateInvisibleBindButtonSize()
            updateInvisibleBindText()
        end

        local function setInvisibleBindButton(enabled)
            universalState.invisibleBindEnabled = enabled == true
            if universalState.invisibleBindEnabled then createInvisibleBindButton() else removeInvisibleBindButton() end
        end


         
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
            if not (part and part:IsA("\x42asePart")) or universalState.antiFlingTracked[part] ~= nil then return end
            universalState.antiFlingTracked[part] = part.CanCollide
            universalState.antiFlingPartSignals[part] = part:GetPropertyChangedSignal("\x43anCollide"):Connect(function()
                if universalState.antiFling and part.Parent and part.CanCollide then part.CanCollide = false end
            end)
            if universalState.antiFling and part.CanCollide then part.CanCollide = false end
        end

        local function antiFlingSeedCharacter(character)
            if not character then return end
            for _, instance in ipairs(character:GetDescendants()) do
                if instance:IsA("\x42asePart") then antiFlingTrackPart(instance) end
            end
            character.DescendantAdded:Connect(function(instance)
                if instance:IsA("\x42asePart") then antiFlingTrackPart(instance) end
            end)
            character.DescendantRemoving:Connect(function(instance)
                if instance:IsA("\x42asePart") then antiFlingClearPart(instance) end
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
            local quota, cursor = 48, universalState.antiFlingNextPart
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

        local universalMods = tab:AddSection("\x4dAIN • UNIVERSAL", "\x4dovement and survival utilities")
        universalMods:AddToggle("\x49nfinite Jump", function(enabled) universalState.infiniteJump = enabled == true end)
        universalMods:AddToggle("\x41ntiFling", setAntiFling)

        local invisibleMods = tab:AddSection("\x4dAIN • INVISIBLE", "\x44esync invisibility and floating bind button")
        invisibleMods:AddToggle("\x49nvisible", setInvisible)
        invisibleMods:AddToggle("\x45nable Invisible Bind Button", setInvisibleBindButton)
        invisibleMods:AddSlider("\x49nvisible Bind Button Size", 5, 25, universalState.invisibleBindSize * 100, function(value)
            universalState.invisibleBindSize = (tonumber(value) or 10.5) / 100
            updateInvisibleBindButtonSize()
        end)
        invisibleMods:AddLabel("\x52ound Invisible button: tap to toggle; drag it to move. Its size\x20and position are saved.")
        if not universalState.invisibleBindEnabled then removeInvisibleBindButton() end
    end
    buildUniversalUtilities()
end


task.defer(function()
     
     
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
        local label = button and button:FindFirstChild("\x54ext")
        if label then label.Text = "\x44esync" end
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
        for _, parent in ipairs({ guiParent, CoreGui, LocalPlayer:FindFirstChildOfClass("\x50layerGui") }) do
            if parent then
                local stale = parent:FindFirstChild("\x4eoirDesyncBindButton")
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
        if typeof(parent) ~= "\x49nstance" then parent = LocalPlayer:WaitForChild("\x50layerGui") end
        local bindGui = New("\x53creenGui", { Parent = parent, Name = "\x4eoirDesyncBindButton", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 83, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
        local button = New("\x49mageButton", { Parent = bindGui, Name = "\x44esync", AnchorPoint = Vector2.new(.5, .5),
            Position = NoirPersistence.GetPosition("\x64esync_bind_v1", UDim2.new(.35, 0, .88, 0)), Size = UDim2.fromScale(desyncState.bindSize, desyncState.bindSize),
            BackgroundColor3 = Color3.fromRGB(8, 8, 10), BackgroundTransparency = .28, BorderSizePixel = 0,
            Image = "", AutoButtonColor = false, ClipsDescendants = false, ZIndex = 7 })
         
        corner(button, 999)
        local aspect = New("\x55IAspectRatioConstraint", { Parent = button, AspectRatio = 1, AspectType = Enum.AspectType.ScaleWithParentSize })
        local outer = New("\x55IStroke", { Parent = button, Color = Color3.fromRGB(255, 255, 255), Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
        local outerGradient = New("\x55IGradient", { Parent = outer, Color = monochromeGradient })
        table.insert(gradientStrokes.fast, outerGradient)
        local inner = New("\x55IStroke", { Parent = button, Color = Color3.fromRGB(105, 105, 112), Transparency = .5, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
        local innerGradient = outerGradient:Clone(); innerGradient.Rotation = 180; innerGradient.Parent = inner; table.insert(gradientStrokes, innerGradient)
        desyncState.bindOuterGradient, desyncState.bindInnerGradient = outerGradient, innerGradient
        local label = New("\x54extLabel", { Parent = button, Name = "\x54ext", AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromScale(.76, .76),
            BackgroundTransparency = 1, Text = "\x44esync\nOFF", TextColor3 = Color3.fromRGB(245, 245, 248), TextSize = 14, TextWrapped = true, Font = Enum.Font.Gotham, ZIndex = 8 })
        local pressScale = New("\x55IScale", { Parent = button, Scale = 1 })
        local dragging, moved, startInput, startPosition, dragInput = false, false, nil, nil, nil
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
                NoirPersistence.SetPosition("\x64esync_bind_v1", button.Position)
            else
                 
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
     
    desyncState.pendingRoot, desyncState.pendingCFrame = nil, nil
    RunService:BindToRenderStep("\x4eoirDesyncRestore_" .. tostring(LocalPlayer.UserId), Enum.RenderPriority.Camera.Value - 1, function()
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
            local root = character:FindFirstChild("\x48umanoidRootPart")
            if root then desyncState.anchorCFrame = root.CFrame end
        end
    end)

    local desyncMods = tab:AddSection("\x4dISC • DESYNC", "\x4beeps the server-facing character position at the activation poi\x6et")
    desyncToggleControl = desyncMods:AddToggle("\x44esync", function(enabled)
        if not syncingDesyncToggle then setDesync(enabled) end
    end)
    desyncMods:AddToggle("\x45nable Desync Bind Button", setDesyncBindButton)
    desyncMods:AddSlider("\x44esync Bind Button Size", 5, 25, desyncState.bindSize * 100, function(value)
        desyncState.bindSize = (tonumber(value) or 10.5) / 100
        updateDesyncBindSize()
    end)
    desyncMods:AddLabel("\x45nable Desync to save the current position; you can then move lo\x63ally while its saved position is sent on desync frames.")
    if not desyncState.bindEnabled then removeDesyncBindButton() end
end)

