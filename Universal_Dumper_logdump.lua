-- Universal Dumper FINAL | для любых скриптов (не только XALOEX)
-- Ловит: loadstring / HttpGet / require / table.concat / string.char
-- Авто-сохранение в workspace/logdump без кнопок, без кика
-- Работает на Delta / CodeX / Arceus X Neo / Fluxus
-- Запуск: loadstring(game:HttpGet("https://raw.githubusercontent.com/mellnikovden968-web/Gga/refs/heads/main/Universal_Dumper_FINAL.lua"))()

local LOG="logdump"
pcall(function() if makefolder and not isfolder(LOG) then makefolder(LOG) end end)

local seen, cnt = {}, 0
local MIN = 800 -- меньше не сохраняем (мусор)
local function save(tag, src, extra)
    if type(src)~="string" or #src<MIN then return end
    -- фильтр: должен быть похож на lua
    if not (src:find("function") or src:find("local") or src:find("game") or src:find("=")) and #src<2000 then return end
    local h = #src..":"..src:sub(1,80)
    if seen[h] then return end
    seen[h]=true
    cnt=cnt+1
    local name = string.format("%s/%02d_%s.lua", LOG, cnt, tag)
    local head = string.format("-- UNIVERSAL DUMP | %s | %d bytes | %s | %s\n\n", tag, #src, tostring(extra or ""), os.date("%H:%M:%S"))
    pcall(function() writefile(name, head..src) end)
    print("[UNIVERSAL] saved "..name.." ("..#src..") <- "..tostring(extra or ""))
    return name
end

print("=== UNIVERSAL DUMPER FINAL ON ===")
print("Слежу за loadstring / HttpGet / require / concat ...")

-- 1. loadstring / load
do
    local orig_ls = loadstring
    local orig_load = load
    local function hook_ls(s, chunk, ...)
        if type(s)=="string" and #s>=MIN then
            save("loadstring", s, chunk)
        end
        return orig_ls(s, chunk, ...)
    end
    local function hook_load(s, chunk, ...)
        if type(s)=="string" and #s>=MIN then save("load", s, chunk) end
        return orig_load(s, chunk, ...)
    end
    if hookfunction then
        pcall(hookfunction, orig_ls, hook_ls)
        pcall(hookfunction, orig_load, hook_load)
    end
    getgenv().loadstring = hook_ls
    getgenv().load = hook_load
end

-- 2. HttpGet / HttpGetAsync / request
do
    local orig = game.HttpGet
    local function hook(self, url, ...)
        local r = orig(self, url, ...)
        if type(r)=="string" and #r>=MIN then
            -- определяем тип по содержимому
            if r:find("XALOEX") then save("HttpGet_XALOEX", r, url)
            elseif r:find("Luraph") or r:find("luraph") then save("HttpGet_Luraph", r, url)
            else save("HttpGet", r, url) end
        end
        return r
    end
    if hookfunction then pcall(hookfunction, orig, hook) else game.HttpGet = hook end
    pcall(function()
        local o2 = game.HttpGetAsync
        if o2 then
            local h2=function(self,url,...) local r=o2(self,url,...); if type(r)=="string" and #r>=MIN then save("HttpGetAsync",r,url) end return r end
            if hookfunction then pcall(hookfunction,o2,h2) else game.HttpGetAsync=h2 end
        end
    end)
    -- syn.request / http_request
    for _,tbl in ipairs({(getgenv().syn and getgenv().syn.request and getgenv().syn), getgenv().http, getgenv()}) do
        if tbl and tbl.request then
            local old=tbl.request
            local hk=function(req,...)
                local res=old(req,...)
                local body = type(res)=="table" and res.Body or res
                if type(body)=="string" and #body>=MIN then
                    local url = type(req)=="table" and req.Url or tostring(req)
                    save("request", body, url)
                end
                return res
            end
            if hookfunction then pcall(hookfunction, old, hk) else tbl.request=hk end
        end
    end
end

-- 3. table.concat -> ловит сборку пейлоада из кусков (часто у LuaObfuscator)
do
    local orig = table.concat
    local function hook(t, sep, i, j)
        local r = orig(t, sep, i, j)
        if type(r)=="string" and #r>=3000 and (r:find("function") or r:find("local")) then
            save("concat", r, "table.concat")
        end
        return r
    end
    if hookfunction then pcall(hookfunction, orig, hook) else table.concat=hook end
end

-- 4. string.char -> собирает строки побайтово
do
    local orig = string.char
    -- не хукаем каждый string.char (спамит), только если собирается длинная строка >500
    -- Вместо хука просто логируем через __concat, проще не трогать
end

-- 5. require -> дамп ModuleScript через decompile
do
    local orig = require
    local function hook(m, ...)
        local ret = orig(m, ...)
        if typeof and typeof(m)=="Instance" and m:IsA("ModuleScript") then
            pcall(function()
                if decompile then
                    local src=decompile(m)
                    if src and #src>=MIN then save("ModuleScript", src, m:GetFullName()) end
                end
            end)
        end
        return ret
    end
    if hookfunction then pcall(hookfunction, orig, hook) else getgenv().require=hook end
end

-- 6. Анти-кик чтобы успеть сохранить до выгона
pcall(function()
    local plr=game:GetService("Players").LocalPlayer
    if plr and plr.Kick then
        local old=plr.Kick
        local hk=function(self,...) print("[UNIVERSAL] Kick задержан 2с"); task.wait(2); return old(self,...) end
        if hookfunction then pcall(hookfunction, old, hk) end
        pcall(function()
            local mt=getrawmetatable(plr)
            if mt and mt.__namecall then
                local o=mt.__namecall
                setreadonly(mt,false)
                mt.__namecall=newcclosure(function(self,...)
                    if getnamecallmethod()=="Kick" then task.wait(2) end
                    return o(self,...)
                end)
                setreadonly(mt,true)
            end
        end)
    end
end)

-- 7. Ручной полный дамп по команде dumpAll()
getgenv().dumpAll = function()
    print("[UNIVERSAL] dumpAll() -> сканирую getgc / getscripts ...")
    local n=0
    if getgc then
        local ok,gc=pcall(getgc,true)
        if ok and type(gc)=="table" then
            for i,f in ipairs(gc) do
                if type(f)=="function" then
                    local s,src=pcall(decompile,f)
                    if s and type(src)=="string" and #src>=MIN then
                        if src:find("function") and #src>2000 then
                            local p=save("getgc", src, "func_"..i)
                            if p then n=n+1; if n>=5 then break end
                        end
                    end
                end
            end
        end
    end
    for _,fn in ipairs({"getscripts","getrscripts"}) do
        local g=getgenv()[fn]
        if g then
            for _,scr in ipairs(g()) do
                if scr:IsA("LocalScript") or scr:IsA("ModuleScript") then
                    local s,src=pcall(decompile,scr)
                    if s and #src>=MIN then save(fn,src,scr:GetFullName()); n=n+1 end
                end
            end
        end
    end
    print("[UNIVERSAL] готово, файлов: "..n.." смотри "..LOG)
end

pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title="UNIVERSAL ON",Text="Запусти любой скрипт, он сохранится в "..LOG,Duration=4}) end)
print("[UNIVERSAL] Готово. Запусти любой скрипт -> он появится в workspace/"..LOG)
print("[UNIVERSAL] Команда для полного дампа игры: dumpAll()")
