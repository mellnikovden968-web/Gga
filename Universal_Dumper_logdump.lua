-- Luraph ODH SAFE | без hookfunction/newcclosure = не палится античитом, не кикает
-- Ловит loadstring src + то что VM вернула (vm_return)
-- Запуск ДО ODH: loadstring(readfile("Luraph_ODH_Dumper_SAFE.lua"))()
-- Папка: logdump_odh_safe

local LOG="logdump_odh_safe"
pcall(function() if makefolder then pcall(makefolder, LOG) end end)
local seen,cnt={},0
local MIN=500
local function save(tag, src, extra)
    if type(src)~="string" or #src<MIN then return end
    local h=#src..":"..src:sub(1,80)
    if seen[h] then return end
    seen[h]=true; cnt=cnt+1
    local name=string.format("%s/%02d_%s.lua", LOG, cnt, tag)
    local head=string.format("-- SAFE ODH | %s | %d bytes | %s | %s\n\n", tag, #src, tostring(extra or ""), os.date("%H:%M:%S"))
    pcall(function() writefile(name, head..src) end)
    print("[SAFE-ODH] saved "..name.." ("..#src..") "..tostring(extra or ""))
    return name
end
local function saveTable(tag, t, extra)
    if type(t)~="table" then return end
    local n=0; for _ in pairs(t) do n=n+1 end
    if n<20 then return end
    print("[SAFE-ODH] table "..tag.." n="..n)
    pcall(function()
        local hs=game:GetService("HttpService")
        local j=hs:JSONEncode(t)
        if #j>=MIN then save(tag, j, extra.."_json") end
    end)
end

print("=== SAFE ODH DUMPER ON (no hookfunction) ===")

-- Анти-кик максимально стелс: просто подменяем Kick если получится, без метатаблиц
pcall(function()
    local plr=game:GetService("Players").LocalPlayer
    if plr and plr.Kick then
        -- пробуем прямую подмену (на некоторых эксплоитах срабатывает)
        -- не используем hookfunction чтобы не палиться
        local orig=plr.Kick
        pcall(function() plr.Kick = function(...) print("[SAFE-ODH] Kick blocked (direct)") task.wait(3) return end end)
        -- запасной план: если не получилось, хотя бы предупредим
        if plr.Kick==orig then print("[SAFE-ODH] Kick not writable, будет кик но файлы уже сохранятся до него") end
    end
end)

-- Обёртка для loadstring без hookfunction
do
    local orig_ls = loadstring
    local orig_load = load
    local function makeWrapper(orig_fn, tag)
        return function(...)
            print("[SAFE-ODH] VM call "..tag.." ...")
            local ok, ret1, ret2, ret3 = pcall(orig_fn, ...)
            if not ok then
                print("[SAFE-ODH] VM error: "..tostring(ret1))
                error(ret1, 0)
            end
            -- ret1.. может быть string/table/function/nil
            local rets={ret1, ret2, ret3}
            -- если orig_fn вернула 0 значений (nil), то вызов VM вернул nil
            -- но loadstring обычно возвращает 1 функцию; мы оборачиваем именно ту функцию
            -- Здесь orig_fn это УЖЕ расшифрованная функция (результат loadstring), и мы её вызвали
            -- Поэтому проверяем что она вернула
            for i=1,3 do
                local v=rets[i]
                if v~=nil then
                    print("[SAFE-ODH] ret"..i.." type="..type(v)..(type(v)=="string" and " len="..#v or type(v)=="table" and (function() local c=0;for _ in pairs(v) do c=c+1 end return " keys="..c end)() or ""))
                    if type(v)=="string" and #v>=MIN then
                        save("vm_return_"..i, v, tag)
                        if v:find("%[6%]=function") or v:find("Luraph") then
                            print("[SAFE-ODH] похоже это handlers таблица (как 1.8M) - чистого loadstring нет")
                        end
                    elseif type(v)=="table" then
                        saveTable("vm_return_"..i, v, tag)
                    end
                end
            end
            return ret1, ret2, ret3
        end
    end

    getgenv().loadstring = function(s, chunk, ...)
        if type(s)=="string" and #s>=MIN then
            pcall(save, "loadstring_src", s, chunk or "")
        end
        local fn, err = orig_ls(s, chunk, ...)
        if type(fn)=="function" then
            -- возвращаем обёрнутую функцию, чтобы поймать что она вернёт при вызове a(key1,key2)
            local wrapped = makeWrapper(fn, tostring(chunk or "loadstring"))
            return wrapped, err
        end
        return fn, err
    end

    getgenv().load = function(s, chunk, ...)
        if type(s)=="string" and #s>=MIN then pcall(save, "load_src", s, chunk or "") end
        local fn, err = orig_load(s, chunk, ...)
        if type(fn)=="function" then return makeWrapper(fn, tostring(chunk or "load")), err end
        return fn, err
    end
    print("[SAFE-ODH] loadstring/load wrapped (stealth)")
end

-- buffer.fromstring стелс (без hookfunction)
pcall(function()
    if buffer and buffer.fromstring then
        local orig=buffer.fromstring
        buffer.fromstring = function(str, ...)
            if type(str)=="string" and #str>=MIN then
                pcall(save, "buffer_fromstring", str, "fromstring")
                print("[SAFE-ODH] buffer.fromstring "..#str)
            end
            return orig(str, ...)
        end
        print("[SAFE-ODH] buffer.fromstring wrapped")
    end
end)

-- HttpGet стелс
pcall(function()
    local orig=game.HttpGet
    -- перезаписываем метод на объекте game (стелс)
    game.HttpGet = function(self, url, ...)
        local r=orig(self, url, ...)
        if type(r)=="string" and #r>=MIN then
            if r:find("Luraph") then pcall(save, "HttpGet_Luraph", r, url)
            elseif r:find("XALOEX") then pcall(save, "HttpGet_XALOEX", r, url)
            else pcall(save, "HttpGet", r, url) end
        end
        return r
    end
    print("[SAFE-ODH] HttpGet wrapped")
end)

print("[SAFE-ODH] Готово. Теперь запускай ODH лоадер. Даже если кикнет - файлы до кика уже в "..LOG)
print("[SAFE-ODH] Если кикает сразу - попробуй второй вариант: запусти ODH БЕЗ дампера 1 раз, потом файл Ixry Shizuka/files/bootstrapper.lua (568K) вручную через tail -n +3")
