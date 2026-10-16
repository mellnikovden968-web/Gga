-- Universal Dumper -> workspace/logdump
-- Кинул этот скрипт ПЕРВЫМ, потом запускаешь любой скрипт который хочешь задампить
-- Дампы смотри: Files -> чита -> workspace -> logdump
-- Работает на Delta / CodeX / Arceus X Neo / Fluxus / Solara

local LOG_FOLDER = "logdump"
local HttpService = game:GetService("HttpService")

-- создаем папку
pcall(function()
    if makefolder and not isfolder(LOG_FOLDER) then
        makefolder(LOG_FOLDER)
    elseif makefolder and isfolder and not isfolder("workspace/"..LOG_FOLDER) then
        makefolder("workspace/"..LOG_FOLDER)
    end
end)

local count = 0
local function safeName(str)
    str = tostring(str):gsub("[^%w%-%_]", "_"):sub(1,40)
    if str=="" then str="chunk" end
    return str
end

local function saveDump(tag, source, extra)
    if type(source) ~= "string" or #source < 10 then return end
    -- фильтр мусора (не луа)
    if not source:find("function") and not source:find("local") and not source:find("game:") and #source < 50 then return end
    count += 1
    local name = string.format("%s/%03d_%s_%s.lua", LOG_FOLDER, count, tag, safeName(extra or ""))
    -- защита от перезаписи workspace/ префикс для некоторых экзекуторов
    local ok, err = pcall(function()
        if writefile then
            writefile(name, "-- DUMP "..tag.." "..os.date("%Y-%m-%d %H:%M:%S").."\n-- source: "..tostring(extra or "").."\n\n"..source)
        end
    end)
    if not ok then
        pcall(function() writefile("workspace/"..name, source) end)
    end
    print("[DUMPER] saved -> "..name.." ("..#source.." bytes)")
    if rconsoleprint then rconsoleprint("[DUMPER] "..name.."\n") end
end

-- 1. Хукаем loadstring / load
do
    local old_loadstring = loadstring
    local old_load = load
    if old_loadstring then
        local function hooked_loadstring(str, chunkname, ...)
            saveDump("loadstring", str, chunkname)
            return old_loadstring(str, chunkname, ...)
        end
        -- пробуем hookfunction если есть (обходит детекты)
        if hookfunction and type(hookfunction)=="function" then
            pcall(hookfunction, old_loadstring, hooked_loadstring)
            rawset(getgenv(), "loadstring", hooked_loadstring)
        else
            rawset(getgenv(), "loadstring", hooked_loadstring)
            if getfenv then pcall(function() getfenv().loadstring = hooked_loadstring end) end
        end
    end
    if old_load and old_load ~= old_loadstring then
        local function hooked_load(str, chunkname, ...)
            saveDump("load", str, chunkname)
            return old_load(str, chunkname, ...)
        end
        if hookfunction then pcall(hookfunction, old_load, hooked_load) end
        rawset(getgenv(), "load", hooked_load)
    end
end

-- 2. Хукаем HttpGet / HttpGetAsync / request - ловим скрипты которые грузят через HttpGet
do
    local function hookHttp(obj, method)
        if not obj or not obj[method] then return end
        local old = obj[method]
        local hooked = function(self, url, ...)
            local res = old(self, url, ...)
            if type(res)=="string" and #res > 50 and (res:find("function") or res:find("loadstring") or res:find("getgenv")) then
                saveDump("HttpGet", res, url)
            end
            return res
        end
        if hookfunction then pcall(hookfunction, old, hooked) else pcall(function() obj[method]=hooked end) end
    end
    pcall(hookHttp, game, "HttpGet")
    pcall(hookHttp, game, "HttpGetAsync")
    -- syn.request / http_request / request
    for _,tbl in ipairs({ (getgenv().syn and getgenv().syn.request and getgenv().syn), getgenv().http, getgenv() }) do
        if tbl and tbl.request then
            local old = tbl.request
            local hooked = function(req, ...)
                local res = old(req, ...)
                local body = type(res)=="table" and res.Body or res
                if type(body)=="string" and #body>50 then
                    local url = type(req)=="table" and req.Url or tostring(req)
                    if body:find("function") or body:find("local") then
                        saveDump("request", body, url)
                    end
                end
                return res
            end
            if hookfunction then pcall(hookfunction, old, hooked) else pcall(function() tbl.request=hooked end) end
        end
    end
end

-- 3. Хукаем require - если скрипт лежит в ModuleScript
do
    local old_require = require
    local function hooked_require(obj, ...)
        local ret = old_require(obj, ...)
        -- если это ModuleScript и мы можем его декомпилить
        if typeof and typeof(obj)=="Instance" and obj:IsA("ModuleScript") then
            pcall(function()
                if decompile then
                    local src = decompile(obj)
                    saveDump("ModuleScript", src, obj:GetFullName())
                elseif getscriptbytecode then
                    local bc = getscriptbytecode(obj)
                    saveDump("bytecode", bc, obj:GetFullName())
                end
            end)
        end
        return ret
    end
    if hookfunction then pcall(hookfunction, old_require, hooked_require) else rawset(getgenv(),"require", hooked_require) end
end

-- 4. Ручной дамп всех уже загруженных скриптов (вызови dumpAll() в консоли)
getgenv().dumpAll = function()
    print("[DUMPER] scanning getgc / getscripts ...")
    -- через getgc
    if getgc then
        local ok, gc = pcall(getgc, true)
        if ok and type(gc)=="table" then
            for i,v in ipairs(gc) do
                if type(v)=="function" then
                    pcall(function()
                        local src = nil
                        if decompile then src = decompile(v) end
                        if src and #src>100 then
                            local info = debug and debug.getinfo and debug.getinfo(v)
                            saveDump("getgc_func", src, info and info.name or "func_"..i)
                        end
                    end)
                end
            end
        end
    end
    -- через getscripts / getrscripts
    for _,fn in ipairs({"getscripts","getrscripts","getloadedmodules"}) do
        local f = getgenv()[fn]
        if f then
            pcall(function()
                for _,scr in ipairs(f()) do
                    if scr:IsA("LocalScript") or scr:IsA("ModuleScript") then
                        local src = nil
                        if decompile then src = decompile(scr) end
                        if src then saveDump(fn, src, scr:GetFullName()) end
                    end
                end
            end)
        end
    end
    -- DataModel dump (как Dump_Game_Roblox)
    pcall(function()
        if decompile then
            for _,v in ipairs(game:GetDescendants()) do
                if v:IsA("LocalScript") or v:IsA("ModuleScript") then
                    local s,e = pcall(decompile, v)
                    if s and e and #e > 100 then
                        saveDump("DataModel", e, v:GetFullName():gsub("%.","_"))
                    end
                end
            end
        end
    end)
    print("[DUMPER] done. Check workspace/"..LOG_FOLDER)
end

-- 5. Авто-сообщение
print("========================================")
print("[DUMPER] Universal Dumper AKTIVEN!")
print("[DUMPER] Папка: workspace/"..LOG_FOLDER)
print("[DUMPER] Теперь запусти любой скрипт - он автоматом сохранится")
print("[DUMPER] Для полного дампа игры напиши: dumpAll()")
print("========================================")
if game:GetService("StarterGui") then
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "DUMPER ON",
            Text = "workspace/"..LOG_FOLDER.." - запускай скрипт",
            Duration = 5
        })
    end)
end

-- 6. Проверка прав
task.spawn(function()
    task.wait(1)
    pcall(function()
        writefile(LOG_FOLDER.."/_test.txt", "dumper ok "..os.date())
        print("[DUMPER] test write OK -> "..LOG_FOLDER.."/_test.txt")
        -- удаляем тест
        if delfile then pcall(delfile, LOG_FOLDER.."/_test.txt") end
    end)
    if isfolder and not isfolder(LOG_FOLDER) and not isfolder("workspace/"..LOG_FOLDER) then
        warn("[DUMPER] ВНИМАНИЕ: папка не создалась! Проверь что экзекутор поддерживает makefolder/writefile")
        warn("[DUMPER] Попробуй вручную создать папку logdump в workspace")
    end
end)
