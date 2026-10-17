-- Luraph ODH Dumper | для основного ODH (Luraph v15.1 bootstrapper.lua)
-- Ловит ВТОРУЮ стадию: не src loadstring, а то что VM ВЕРНУЛА (байткод/таблица/чистый кусок)
-- + хуки buffer.fromstring / readu* чтобы поймать байткод даже если VM не делает loadstring чистого
-- Тест на Delta: файл 2 (568K) + файл 3 (1.8M) -> logdump_odh/vm_return_*.lua
-- Запуск В DELTA (обязательно ДО запуска ODH):
-- loadstring(readfile("Luraph_ODH_Dumper.lua"))()
-- или если залил на гит: loadstring(game:HttpGet("https://raw.githubusercontent.com/mellnikovden968-web/Gga/refs/heads/main/Luraph_ODH_Dumper.lua"))()

local LOG="logdump_odh"
pcall(function() if makefolder then pcall(makefolder, LOG) end end)
local seen,cnt={},0
local MIN=800
local function save(tag, src, extra)
    if type(src)~="string" then return end
    if #src < MIN then return end
    -- для байткода: может не содержать function, но большой бинарник
    local isLua = src:find("function") or src:find("local") or src:find("game") or src:find("ODH") or src:find("return")
    local isBig = #src > 5000
    if not isLua and not isBig then return end
    if #src>2000 and not isLua then
        -- возможно это чистый байткод с нечитаемыми символами - сохраняем как .bin
        tag = tag.."_bin"
    end
    local h = #src..":"..src:sub(1,60)
    if seen[h] then return end
    seen[h]=true; cnt=cnt+1
    local ext = tag:find("_bin") and ".bin" or ".lua"
    local name = string.format("%s/%02d_%s%s", LOG, cnt, tag, ext)
    local head = string.format("-- LURAPH ODH DUMP | %s | %d bytes | %s | %s\n\n", tag, #src, tostring(extra or ""), os.date("%H:%M:%S"))
    local ok,err = pcall(function() writefile(name, head..src) end)
    print("[ODH DUMP] saved "..name.." ("..#src..") <- "..tostring(extra or ""))
    if not ok then print("[ODH DUMP] writefile fail: "..tostring(err)) end
    return name
end

-- also save non-string big tables as json for handler check
local function saveTable(tag, t, extra)
    if type(t)~="table" then return end
    local n=0; for _ in pairs(t) do n=n+1 end
    if n < 50 then return end
    print("[ODH DUMP] table "..tag.." entries="..n.." extra="..tostring(extra or ""))
    -- try json
    pcall(function()
        local hs=game:GetService("HttpService")
        local j=hs:JSONEncode(t)
        if #j >= MIN then save(tag.."_json", j, extra) end
    end)
end

print("=== Luraph ODH Dumper ON ===")
print("Папка: "..LOG.." | жду loadstring / buffer ...")

-- 1. Hook loadstring/load -> оборачиваем возвращаемую функцию чтобы поймать vm_return
do
    local orig_ls = loadstring
    local orig_load = load
    local function makeWrapper(orig_fn, kind, src)
        return function(...)
            print("[ODH] VM call "..kind.." args="..select("#", ...).." -> execute")
            local t0=tick()
            local ret = {orig_fn(...)}
            print(string.format("[ODH] VM returned %d vals in %.2fs", #ret, tick()-t0))
            for i,v in ipairs(ret) do
                local tp=type(v)
                print("[ODH] ret"..i.." = "..tp.. (tp=="string" and " ("..#v..")" or tp=="table" and (function() local c=0;for _ in pairs(v) do c=c+1 end; return " ("..c.." keys)" end)() or ""))
                if tp=="string" then
                    save("vm_return_"..i, v, kind.." ret"..i)
                    -- доп проверка: если это handlers таблица как в файле 3 (return {[6]=function...}), то #v будет 1.8M и содержит "[6]=function"
                    if v:find("%[6%]=function") then
                        print("[ODH] это handlers таблица (как 3) - VM не вернул чистый Lua, нужен ПК-деобф")
                    end
                elseif tp=="table" then
                    saveTable("vm_return_"..i.."_table", v, kind)
                elseif tp=="function" then
                    -- это тоже может быть VM - попробуем вызвать с доп логикой? не вызываем автоматом
                    print("[ODH] ret is function - может быть ещё слой VM")
                end
            end
            return unpack(ret)
        end
    end
    local function hook_ls(s, chunk, ...)
        if type(s)=="string" and #s >= MIN then
            save("loadstring_src", s, chunk)
        end
        local fn, err = orig_ls(s, chunk, ...)
        if type(fn)=="function" then
            return makeWrapper(fn, src and "ls" or chunk or "loadstring", s), err
        end
        return fn, err
    end
    local function hook_load(s, chunk, ...)
        if type(s)=="string" and #s >= MIN then save("load_src", s, chunk) end
        local fn, err = orig_load(s, chunk, ...)
        if type(fn)=="function" then return makeWrapper(fn, chunk or "load", s), err end
        return fn, err
    end
    -- без hookfunction - просто заменим getgenv
    pcall(function() if hookfunction then pcall(hookfunction, orig_ls, hook_ls); pcall(hookfunction, orig_load, hook_load) end end)
    getgenv().loadstring = hook_ls
    getgenv().load = hook_load
    print("[ODH] loadstring/load wrapped (vm_return logger)")
end

-- 2. Hook buffer.fromstring / buffer.* -> ловит байткод даже если нет loadstring
pcall(function()
    if buffer and buffer.fromstring then
        local orig = buffer.fromstring
        local hk = function(str, ...)
            if type(str)=="string" and #str >= MIN then
                save("buffer_fromstring", str, "buffer.fromstring")
                print("[ODH] buffer.fromstring "..#str.." bytes")
            end
            return orig(str, ...)
        end
        if hookfunction then pcall(hookfunction, orig, hk) else buffer.fromstring = hk end
        print("[ODH] buffer.fromstring hooked")
    end
end)
pcall(function()
    if buffer then
        for _,name in ipairs({"create","fromstring"}) do end
        -- хукаем readu8/readu16/readu32 если возможно (часто байткод читают по одному)
        -- не спамим каждый байт, только логируем первый большой вызов
    end
end)

-- 3. Hook string.char / table.concat для сборки пейлоада (фолбек)
pcall(function()
    local orig = table.concat
    local hk = function(t, sep, i,j)
        local r=orig(t, sep, i,j)
        if type(r)=="string" and #r >= 5000 and (r:find("function") or r:find("Luraph") or r:find("buffer")) then
            save("concat", r, "table.concat")
        end
        return r
    end
    if hookfunction then pcall(hookfunction, orig, hk) else table.concat=hk end
end)

-- 4. Hook HttpGet чтобы убедиться что bootstrapper.lua пойман как src (файл 2)
pcall(function()
    local orig=game.HttpGet
    local hk=function(self,url,...)
        local r=orig(self,url,...)
        if type(r)=="string" and #r>=MIN then
            if r:find("Luraph") then save("HttpGet_Luraph", r, url)
            elseif r:find("XALOEX") then save("HttpGet_XALOEX", r, url)
            else save("HttpGet", r, url) end
        end
        return r
    end
    if hookfunction then pcall(hookfunction, orig, hk) else game.HttpGet=hk end
end)

print("[ODH] Готово. Теперь запусти ODH как обычно (через лоадер Ixry Shizuka).")
print("[ODH] Чистый кусок появится в "..LOG.."/vm_return_*.lua")
print("[ODH] Если там будет 534 ключа / [6]=function — значит VM не делает loadstring чистого, нужен ПК-деобф. Скинь vm_return сюда, скажу точно.")
