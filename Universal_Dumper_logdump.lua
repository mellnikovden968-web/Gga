-- Universal Dumper SAFE | без hookfunction, не ломает скрипты
-- Фикс ошибки "attempt to call a nil value" из скрина
-- Просто ставит getgenv().loadstring, не трогает метатаблицы
-- Запуск: loadstring(game:HttpGet("https://raw.githubusercontent.com/mellnikovden968-web/Gga/refs/heads/main/Universal_Dumper_SAFE.lua"))()

local LOG="logdump"
pcall(function() if makefolder then pcall(makefolder, LOG) end end)

local seen,cnt={},0
local MIN=500
local function save(tag, src, extra)
    if type(src)~="string" or #src<MIN then return end
    if not (src:find("function") or src:find("local") or src:find("game") or src:find("=")) then return end
    local h=#src..":"..src:sub(1,60)
    if seen[h] then return end
    seen[h]=true
    cnt=cnt+1
    local p=string.format("%s/%02d_%s.lua",LOG,cnt,tag)
    pcall(function() writefile(p,"-- SAFE DUMP "..tag.." "..os.date().." "..tostring(extra or "").."\n\n"..src) end)
    print("[SAFE] saved "..p.." "..#src)
end

print("=== SAFE DUMPER ON ===")

-- Только getgenv, без hookfunction/newcclosure
local orig_ls = loadstring
local orig_load = load

getgenv().loadstring = function(s, chunk, ...)
    if type(s)=="string" and #s>=MIN then
        -- защита pcall чтобы не сломать если s не lua
        pcall(save, "loadstring", s, chunk)
    end
    return orig_ls(s, chunk, ...)
end

getgenv().load = function(s, chunk, ...)
    if type(s)=="string" and #s>=MIN then pcall(save, "load", s, chunk) end
    return orig_load(s, chunk, ...)
end

-- HttpGet без hookfunction, просто обертка
local origHttp = game.HttpGet
game.HttpGet = function(self, url, ...)
    local ok, res = pcall(origHttp, self, url, ...)
    if ok and type(res)=="string" and #res>=MIN then
        pcall(save, "HttpGet", res, url)
        return res
    end
    if ok then return res else error(res) end
end

-- table.concat так же безопасно
local origConcat = table.concat
table.concat = function(t, sep, i, j)
    local ok, res = pcall(origConcat, t, sep, i, j)
    if ok and type(res)=="string" and #res>=3000 and res:find("function") then
        pcall(save, "concat", res, "table.concat")
    end
    if ok then return res else error(res) end
end

-- dumpAll ручной
getgenv().dumpAll = function()
    print("[SAFE] dumpAll...")
    local n=0
    if decompile and getgc then
        local ok,gc=pcall(getgc,true)
        if ok then
            for i,f in ipairs(gc) do
                if type(f)=="function" then
                    local s,src=pcall(decompile,f)
                    if s and type(src)=="string" and #src>=1000 and src:find("function") then
                        if pcall(save,"getgc",src,"func_"..i) then n=n+1; if n>=3 then break end
                    end
                end
            end
        end
    end
    print("[SAFE] готово "..n.." файлов в "..LOG)
end

print("[SAFE] Готово. Запусти скрипт -> смотри workspace/"..LOG)
print("[SAFE] Если опять ошибка - скинь мне сам скрипт, проверю без дампера")
pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title="SAFE ON",Text="Запусти скрипт",Duration=3}) end)
