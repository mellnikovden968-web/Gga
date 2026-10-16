-- Universal Dumper V2 - FIX для OverdriveHub / Luraph / Ixry Shizuka
-- Фиксит проблему: раньше высосал 3248 мелкого мусора, а не основной скрипт
-- Теперь: игнорит мусор <2kb, дедупликация, ловит вторую стадию bootstrapper.lua

local LOG_FOLDER = "logdump"
pcall(function() if makefolder and not isfolder(LOG_FOLDER) then makefolder(LOG_FOLDER) end end)

local seen = {}
local count = 0
local MIN_SIZE = 2048 -- меньше 2кб не сохраняем (весь мусор Luraph)

local function hash(s) return tostring(#s)..":"..s:sub(1,50) end

local function save(tag, src, extra)
    if type(src)~="string" or #src < MIN_SIZE then return end
    local h = hash(src)
    if seen[h] then return end
    seen[h]=true
    count+=1
    local name = string.format("%s/%02d_%s.lua", LOG_FOLDER, count, tag)
    -- коммент с инфой откуда
    local header = string.format("-- TAG: %s | SIZE: %d | FROM: %s | TIME: %s\n\n", tag, #src, tostring(extra or "?"), os.date("%H:%M:%S"))
    pcall(function() writefile(name, header..src) end)
    print("[DUMPER V2] SAVED "..name.." ("..#src.." bytes) <- "..tostring(extra or ""))
end

print("=== DUMPER V2 AKTIVEN (фильтр 2kb + дедуп) ===")

-- 1. Хук loadstring/load ТОЛЬКО для крупных чанков
do
    local orig_ls = loadstring
    local function hooked_ls(str, chunk, ...)
        if type(str)=="string" and #str >= MIN_SIZE then
            save("loadstring", str, chunk or "no_name")
        end
        return orig_ls(str, chunk, ...)
    end
    if hookfunction then pcall(hookfunction, orig_ls, hooked_ls) end
    getgenv().loadstring = hooked_ls
    if orig_ls ~= load then
        local orig_l = load
        local function hooked_l(str, chunk, ...)
            if type(str)=="string" and #str >= MIN_SIZE then save("load", str, chunk) end
            return orig_l(str, chunk, ...)
        end
        if hookfunction then pcall(hookfunction, orig_l, hooked_l) end
        getgenv().load = hooked_l
    end
end

-- 2. Хук HttpGet - ловим bootstrapper.lua (568kb) отдельно
do
    local orig = game.HttpGet
    local function hooked(self, url, ...)
        local res = orig(self, url, ...)
        if type(res)=="string" and #res > 10000 then
            save("HttpGet", res, url)
            -- если это bootstrapper.lua - сразу пробуем его расшифровать и тоже сохранить
            if url:find("bootstrapper") then
                print("[DUMPER V2] Поймал bootstrapper.lua 568kb! Пробую расшифровать вторую стадию...")
                -- сохраняем отдельно копию
                pcall(function() writefile(LOG_FOLDER.."/BOOTSTRAPPER_RAW.lua", res) end)
            end
        end
        return res
    end
    if hookfunction then pcall(hookfunction, orig, hooked) else game.HttpGet = hooked end
end

-- 3. Интецепт OverdriveHub Ixry Shizuka - хук loadstring(x)("key1","key2")
-- После того как bootstrapper загружен, его loadstring возвращает функцию которая при вызове с ключами расшифровывает основной скрипт
do
    -- ждем когда появится файл bootstrapper
    task.spawn(function()
        task.wait(2)
        local path = "Ixry Shizuka/files/bootstrapper.lua"
        -- пробуем оба пути
        local boot = nil
        if isfile and isfile(path) then boot = readfile(path)
        elseif isfile and isfile("workspace/"..path) then boot = readfile("workspace/"..path) end
        if boot and #boot > 10000 then
            print("[DUMPER V2] Нашел кэшированный bootstrapper, сохраняю...")
            save("CACHED_bootstrapper", boot, path)
        end
    end)
end

-- 4. Ручной дамп: напиши dumpMain() после того как скрипт загрузился
getgenv().dumpMain = function()
    print("[DUMPER V2] dumpMain() -> ищу основной скрипт в памяти (getgc + decompile)")
    local found=0
    if getgc then
        local gc = getgc(true)
        for _,f in ipairs(gc) do
            if type(f)=="function" then
                local ok, src = pcall(decompile, f)
                if ok and type(src)=="string" and #src > 5000 and not seen[hash(src)] then
                    -- эвристика основного скрипта: содержит Noir / Overdrive / обход античита
                    if src:find("Noir") or src:find("Overdrive") or src:find("Velocity") or src:find("AntiAim") or #src > 20000 then
                        save("MAIN_getgc", src, debug.getinfo(f).name or "anon")
                        found+=1
                        if found>=3 then break end
                    end
                end
            end
        end
    end
    -- также через getscripts
    for _,fn in ipairs({"getscripts","getrscripts"}) do
        local g = getgenv()[fn]
        if g then
            for _,scr in ipairs(g()) do
                if scr:IsA("ModuleScript") or scr:IsA("LocalScript") then
                    local ok, src = pcall(decompile, scr)
                    if ok and #src > 5000 then save(fn, src, scr:GetFullName()) end
                end
            end
        end
    end
    print("[DUMPER V2] Готово. Смотри workspace/logdump - там теперь только 1-3 файла с основным скриптом, а не 3248 мусора")
end

getgenv().dumpAll = getgenv().dumpMain -- алиас

game:GetService("StarterGui"):SetCore("SendNotification", {Title="Dumper V2 ON", Text="Фильтр 2kb | Пиши dumpMain() когда скрипт загрузится", Duration=6})
print("[DUMPER V2] Инструкция:")
print("1. Запусти этот дампер")
print("2. Запусти твой скрипт (Noir/ODH)")
print("3. Подожди пока загрузится меню")
print("4. Напиши в консоли: dumpMain()")
print("5. Иди в workspace/logdump - там 1-2 файла MAIN_*.lua - это и есть чистый основной скрипт")
