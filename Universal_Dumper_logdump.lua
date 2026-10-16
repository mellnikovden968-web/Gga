-- Noir DUMPER Menu | by mellnikovden968-web/Gga
-- Запуск: loadstring(game:HttpGet("https://raw.githubusercontent.com/mellnikovden968-web/Gga/refs/heads/main/Noir_Dumper_Menu.lua"))()
-- Требует Delta / CodeX / Arceus X Neo (writefile/makefolder)

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local SG = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")

local LOG_FOLDER = "logdump"
pcall(function() if makefolder and not isfolder(LOG_FOLDER) then makefolder(LOG_FOLDER) end end)

-- ===== DUMPER CORE (V2 FIX) =====
local seen, count, MIN_SIZE = {}, 0, 2048
local function hash(s) return #s..":"..s:sub(1,60) end
local function save(tag, src, extra)
    if type(src)~="string" or #src < MIN_SIZE then return end
    local h = hash(src)
    if seen[h] then return end
    seen[h]=true
    count+=1
    local name = string.format("%s/%02d_%s.lua", LOG_FOLDER, count, tag)
    local header = string.format("-- NOIR DUMP | TAG: %s | SIZE: %d | FROM: %s | %s\n\n", tag, #src, tostring(extra or "?"), os.date("%Y-%m-%d %H:%M:%S"))
    pcall(function() writefile(name, header..src) end)
    return name, #src
end

local dumperOn = false
local function enableDumper()
    if dumperOn then return false end
    dumperOn = true
    -- loadstring
    local orig_ls = loadstring
    local function hooked_ls(str, chunk, ...)
        if type(str)=="string" and #str >= MIN_SIZE then save("loadstring", str, chunk) end
        return orig_ls(str, chunk, ...)
    end
    if hookfunction then pcall(hookfunction, orig_ls, hooked_ls) end
    getgenv().loadstring = hooked_ls
    if load ~= orig_ls then
        local orig_l = load
        local function hooked_l(str, chunk, ...) 
            if type(str)=="string" and #str >= MIN_SIZE then save("load", str, chunk) end
            return orig_l(str, chunk, ...) 
        end
        if hookfunction then pcall(hookfunction, orig_l, hooked_l) end
        getgenv().load = hooked_l
    end
    -- HttpGet
    pcall(function()
        local orig = game.HttpGet
        local function hooked(self, url, ...)
            local res = orig(self, url, ...)
            if type(res)=="string" and #res > 10000 then save("HttpGet", res, url) end
            return res
        end
        if hookfunction then pcall(hookfunction, orig, hooked) else game.HttpGet = hooked end
    end)
    return true
end

getgenv().dumpMain = function()
    local out = {}
    local found=0
    if getgc then
        local ok, gc = pcall(getgc, true)
        if ok then
            for _,f in ipairs(gc) do
                if type(f)=="function" then
                    local s, src = pcall(decompile, f)
                    if s and type(src)=="string" and #src > 5000 and not seen[hash(src)] then
                        if src:find("Noir") or src:find("Overdrive") or src:find("Velocity") or src:find("AntiAim") or #src>25000 then
                            local n,l = save("MAIN_getgc", src, debug.getinfo(f).name or "anon")
                            if n then 
                                found+=1
                                table.insert(out, n.." ("..l.."b)")
                                if found>=3 then break end
                            end
                        end
                    end
                end
            end
        end
    end
    for _,fn in ipairs({"getscripts","getrscripts"}) do
        local g = getgenv()[fn]
        if g then
            for _,scr in ipairs(g()) do
                if scr:IsA("ModuleScript") or scr:IsA("LocalScript") then
                    local s, src = pcall(decompile, scr)
                    if s and #src > 5000 and not seen[hash(src)] then
                        local n,l = save(fn, src, scr:GetFullName())
                        if n then table.insert(out, n) end
                    end
                end
            end
        end
    end
    return out
end

enableDumper()

-- ===== NOIR GUI =====
if getgenv().NoirDumperGui then pcall(function() getgenv().NoirDumperGui:Destroy() end) end

local gui = Instance.new("ScreenGui")
gui.Name = "NoirDumper"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 9999
getgenv().NoirDumperGui = gui
pcall(function() gui.Parent = LP:FindFirstChildOfClass("PlayerGui") or gethui and gethui() or game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = game:GetService("CoreGui") end

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromOffset(440, 520)
frame.Position = UDim2.fromScale(0.5,0.5)
frame.AnchorPoint = Vector2.new(0.5,0.5)
frame.BackgroundColor3 = Color3.fromRGB(13,13,18)
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,16)
local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(170,120,255)
stroke.Thickness = 1.2
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

-- header
local header = Instance.new("Frame", frame)
header.Size = UDim2.new(1,0,0,54)
header.BackgroundColor3 = Color3.fromRGB(20,20,28)
header.BorderSizePixel = 0
Instance.new("UICorner", header).CornerRadius = UDim.new(0,16)
local fix = Instance.new("Frame", header)
fix.Size = UDim2.new(1,0,0,12)
fix.Position = UDim2.new(0,0,1,-12)
fix.BackgroundColor3 = Color3.fromRGB(20,20,28)
fix.BorderSizePixel = 0
fix.ZIndex = 0

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(1,-60,0,22)
title.Position = UDim2.fromOffset(16,10)
title.BackgroundTransparency = 1
title.Text = "NOIR  •  DUMPER"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 2

local sub = Instance.new("TextLabel", header)
sub.Size = UDim2.new(1,-60,0,14)
sub.Position = UDim2.fromOffset(16,30)
sub.BackgroundTransparency = 1
sub.Text = "высоси любой скрипт в 2 клика"
sub.TextColor3 = Color3.fromRGB(170,120,255)
sub.Font = Enum.Font.Gotham
sub.TextSize = 11
sub.TextXAlignment = Enum.TextXAlignment.Left
sub.ZIndex = 2

local close = Instance.new("TextButton", header)
close.Size = UDim2.fromOffset(32,32)
close.Position = UDim2.new(1,-42,0,11)
close.Text = "×"
close.TextSize = 20
close.Font = Enum.Font.GothamBold
close.TextColor3 = Color3.fromRGB(200,200,210)
close.BackgroundColor3 = Color3.fromRGB(35,35,42)
close.ZIndex = 2
Instance.new("UICorner", close).CornerRadius = UDim.new(0,8)
close.MouseButton1Click:Connect(function() gui:Destroy() end)

-- status dot
local dot = Instance.new("Frame", frame)
dot.Size = UDim2.fromOffset(8,8)
dot.Position = UDim2.fromOffset(16,68)
dot.BackgroundColor3 = Color3.fromRGB(90,255,120)
Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)

local status = Instance.new("TextLabel", frame)
status.Size = UDim2.new(1,-40,0,14)
status.Position = UDim2.fromOffset(30,65)
status.BackgroundTransparency = 1
status.Text = "DUMPER AKTIVEN • фильтр 2kb • папка workspace/logdump"
status.TextColor3 = Color3.fromRGB(120,255,120)
status.Font = Enum.Font.Gotham
status.TextSize = 11
status.TextXAlignment = Enum.TextXAlignment.Left

local function label(txt, y, clr, sz)
    local l = Instance.new("TextLabel", frame)
    l.Size = UDim2.new(1,-32,0,14)
    l.Position = UDim2.fromOffset(16, y)
    l.BackgroundTransparency = 1
    l.Text = txt
    l.TextColor3 = clr or Color3.fromRGB(200,200,210)
    l.Font = Enum.Font.Gotham
    l.TextSize = sz or 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextWrapped = true
    return l
end

-- инструкция
local stepsBg = Instance.new("Frame", frame)
stepsBg.Size = UDim2.new(1,-32,0,132)
stepsBg.Position = UDim2.fromOffset(16, 88)
stepsBg.BackgroundColor3 = Color3.fromRGB(22,22,30)
Instance.new("UICorner", stepsBg).CornerRadius = UDim.new(0,12)

label("КАК ПОЛЬЗОВАТЬСЯ:", 94, Color3.fromRGB(255,255,255), 11)
local s1 = Instance.new("TextLabel", stepsBg)
s1.Size = UDim2.new(1,-20,1,-16)
s1.Position = UDim2.fromOffset(10,8)
s1.BackgroundTransparency = 1
s1.TextWrapped = true
s1.TextYAlignment = Enum.TextYAlignment.Top
s1.TextXAlignment = Enum.TextXAlignment.Left
s1.Font = Enum.Font.Gotham
s1.TextSize = 11
s1.TextColor3 = Color3.fromRGB(180,180,190)
s1.Text = "1. Дампер уже включен (зеленая точка)\n2. Запусти ЛЮБОЙ скрипт который хочешь высосать\n   (Noir / Overdrive / твой dump.lua)\n3. Дождись меню скрипта\n4. Нажми кнопку НИЖЕ «ВЫСОСАТЬ ОСНОВУ»\n5. Иди в Файлы → workspace → logdump"

-- кнопки
local function makeBtn(txt, y, color, txtColor)
    local b = Instance.new("TextButton", frame)
    b.Size = UDim2.new(1,-32,0,42)
    b.Position = UDim2.fromOffset(16, y)
    b.Text = txt
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.TextColor3 = txtColor or Color3.fromRGB(255,255,255)
    b.BackgroundColor3 = color
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,10)
    local s = Instance.new("UIStroke", b)
    s.Color = Color3.fromRGB(255,255,255)
    s.Transparency = 0.9
    s.Thickness = 1
    return b
end

local btnDump = makeBtn("⬇  ВЫСОСАТЬ ОСНОВУ  (dumpMain)", 234, Color3.fromRGB(170,120,255), Color3.fromRGB(255,255,255))
local btnClear = makeBtn("🗑  ОЧИСТИТЬ LOGDUMP", 284, Color3.fromRGB(30,30,38), Color3.fromRGB(200,200,210))
local btnCopy = makeBtn("📋  СКОПИРОВАТЬ ПУТЬ", 334, Color3.fromRGB(30,30,38), Color3.fromRGB(200,200,210))
local btnFolder = makeBtn("📁  ОТКРЫТЬ ПАПКУ (показать путь)", 384, Color3.fromRGB(45,45,55), Color3.fromRGB(200,200,210))

local log = Instance.new("TextLabel", frame)
log.Size = UDim2.new(1,-32,0,56)
log.Position = UDim2.fromOffset(16, 434)
log.BackgroundColor3 = Color3.fromRGB(18,18,24)
log.TextColor3 = Color3.fromRGB(140,255,140)
log.Font = Enum.Font.Code
log.TextSize = 11
log.TextWrapped = true
log.TextYAlignment = Enum.TextYAlignment.Top
log.TextXAlignment = Enum.TextXAlignment.Left
log.Text = "лог: дампер ждет скрипта..."
log.ClipsDescendants = true
Instance.new("UICorner", log).CornerRadius = UDim.new(0,8)
local pad = Instance.new("UIPadding", log)
pad.PaddingTop = UDim.new(0,6)
pad.PaddingLeft = UDim.new(0,8)
pad.PaddingRight = UDim.new(0,8)
pad.PaddingBottom = UDim.new(0,6)

local function logAdd(txt, clr)
    log.Text = txt
    if clr then log.TextColor3 = clr end
    print("[NOIR DUMPER] "..txt)
end

-- проверка папки
task.spawn(function()
    task.wait(0.5)
    local ok = pcall(function() writefile(LOG_FOLDER.."/_test.txt","ok") end)
    if ok then
        if delfile then pcall(delfile, LOG_FOLDER.."/_test.txt") end
        logAdd("✓ папка готова: workspace/"..LOG_FOLDER.."  | поймано: "..count, Color3.fromRGB(120,255,120))
    else
        logAdd("✗ нет доступа к writefile! Смени экзекутор (Delta/CodeX)", Color3.fromRGB(255,120,120))
        dot.BackgroundColor3 = Color3.fromRGB(255,80,80)
        status.Text = "ОШИБКА: нет прав на файлы"
        status.TextColor3 = Color3.fromRGB(255,120,120)
    end
end)

-- счетчик пойманного
task.spawn(function()
    while gui.Parent do
        task.wait(1)
        if count>0 then
            status.Text = "поймано чанков: "..count.." • жми ВЫСОСАТЬ когда скрипт загрузится"
        end
    end
end)

btnDump.MouseButton1Click:Connect(function()
    btnDump.Text = "⏳ ВЫСАСЫВАЮ..."
    task.wait(0.2)
    local res = dumpMain()
    if #res==0 then
        if count>0 then
            logAdd("поймано "..count.." чанков через loadstring, но MAIN не найден.\nПопробуй еще раз через 3 сек или скрипт - лоадер без основы.", Color3.fromRGB(255,220,120))
        else
            logAdd("ничего не найдено.\n1) Ты точно запустил скрипт ПОСЛЕ дампера?\n2) Подожди 5 сек и жми снова.", Color3.fromRGB(255,120,120))
        end
    else
        logAdd("✓ ГОТОВО! Сохранено "..#res.." файла(ов):\n"..table.concat(res,"\n"), Color3.fromRGB(120,255,120))
        pcall(function() SG:SetCore("SendNotification",{Title="Noir Dumper", Text="Готово! "..#res.." файла в workspace/logdump", Duration=4}) end)
    end
    btnDump.Text = "⬇  ВЫСОСАТЬ ОСНОВУ  (dumpMain)"
end)

btnClear.MouseButton1Click:Connect(function()
    if listfiles then
        for _,f in ipairs(listfiles(LOG_FOLDER)) do pcall(delfile, f) end
        seen, count = {}, 0
        logAdd("папка очищена", Color3.fromRGB(200,200,210))
    else
        logAdd("listfiles не поддерживается на этом экзекуторе", Color3.fromRGB(255,120,120))
    end
end)

btnCopy.MouseButton1Click:Connect(function()
    if setclipboard then setclipboard("workspace/"..LOG_FOLDER) logAdd("путь скопирован: workspace/"..LOG_FOLDER) 
    else logAdd("setclipboard нет, путь: workspace/"..LOG_FOLDER) end
end)

btnFolder.MouseButton1Click:Connect(function()
    local files = {}
    if listfiles then files = listfiles(LOG_FOLDER) end
    if #files==0 then logAdd("папка пуста: workspace/"..LOG_FOLDER.."\nСначала высоси скрипт!") 
    else
        local t = "файлов: "..#files.."\n"..table.concat(files,"\n"):sub(1,300)
        logAdd(t)
        if setclipboard then setclipboard(table.concat(files,"\n")) end
    end
end)

-- drag
local dragging, ds, sp
frame.InputBegan:Connect(function(i) 
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then 
        dragging=true ds=i.Position sp=frame.Position 
        i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dragging=false end end) 
    end 
end)
frame.InputChanged:Connect(function(i) 
    if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then 
        local d=i.Position-ds 
        frame.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y) 
    end 
end)

logAdd("NOIR DUMPER включен. Запусти любой скрипт, потом жми ВЫСОСАТЬ ОСНОВУ")
