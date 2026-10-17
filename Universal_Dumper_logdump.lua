-- Luraph ODH SAFE v2 | фикс Malicious Loader Detected (file 8 kick)
-- Добавлен байпас: CoreGui @bubbles.elia + odh_shared_plugins.kick + Players.Kick
-- Всё ещё без hookfunction (стелс)
-- Запуск ДО ODH: loadstring(readfile("Luraph_ODH_Dumper_SAFE_v2.lua"))() then loader
-- Папка: logdump_odh_safe2

local LOG="logdump_odh_safe2"
pcall(function() if makefolder then pcall(makefolder, LOG) end end)
local seen,cnt={},0
local MIN=500
local function save(tag, src, extra)
    if type(src)~="string" or #src<MIN then return end
    local h=#src..":"..src:sub(1,80)
    if seen[h] then return end
    seen[h]=true; cnt=cnt+1
    local name=string.format("%s/%02d_%s.lua", LOG, cnt, tag)
    pcall(function() writefile(name, "-- SAFE2 "..tag.." "..tostring(extra or "").." "..os.date().."\n\n"..src) end)
    print("[SAFE2] saved "..name.." ("..#src..") "..tostring(extra or ""))
end

print("=== SAFE2 ON (Malicious Loader bypass) ===")

-- 1. Байпас CoreGui @bubbles.elia (file 8 проверяет Version v3.2/v3.5)
pcall(function()
    local ok, CoreGui = pcall(function() return game:GetService("CoreGui") end)
    if ok and CoreGui then
        local orig_Find = CoreGui.FindFirstChild
        -- стелс подмена без hookfunction
        CoreGui.FindFirstChild = function(self, name, rec)
            if name=="@bubbles.elia" or (type(name)=="string" and name:find("bubbles")) then
                print("[SAFE2] blocked FindFirstChild bubbles")
                return nil
            end
            return orig_Find(self, name, rec)
        end
        -- также для :FindFirstChild с разными вызывами
        local orig_FFC = game.FindFirstChild
        print("[SAFE2] CoreGui patch done")
    end
end)

-- 2. Байпас odh_shared_plugins.kick и shared.kick (file 8 и другие)
pcall(function()
    -- ждём создания odh_shared_plugins
    task.spawn(function()
        for i=1,50 do
            task.wait(0.2)
            local host = rawget(getgenv(), "odh_shared_plugins") or shared and shared.odh_shared_plugins or _G.odh_shared_plugins
            -- также глобальный shared
            if getgenv().odh_shared_plugins then host=getgenv().odh_shared_plugins end
            if host and type(host)=="table" then
                if host.kick then
                    print("[SAFE2] found odh_shared_plugins.kick -> neutralized")
                    host.kick = function(...) print("[SAFE2] kick blocked", ...) end
                end
                if host.Kick then host.Kick = host.kick end
            end
            if shared and shared.kick then
                print("[SAFE2] shared.kick blocked")
                shared.kick = function(...) print("[SAFE2] shared kick blocked") end
            end
            if _G.odh_shared_plugins and _G.odh_shared_plugins.kick then
                _G.odh_shared_plugins.kick = function() end
            end
        end
    end)
    -- немедленная заглушка на случай если уже есть
    if getgenv().odh_shared_plugins and getgenv().odh_shared_plugins.kick then
        getgenv().odh_shared_plugins.kick = function() print("[SAFE2] early kick block") end
    end
end)

-- 3. Байпас Players.LocalPlayer.Kick (прямая подмена)
pcall(function()
    local plr = game:GetService("Players").LocalPlayer
    if plr and plr.Kick then
        pcall(function() plr.Kick = function(...) print("[SAFE2] Player Kick blocked") task.wait(5) end end)
        print("[SAFE2] Player Kick patch attempted")
    end
end)

-- 4. loadstring wrapper без hookfunction (как в SAFE v1) + vm_return
do
    local orig_ls = loadstring
    local orig_load = load
    local function makeWrapper(orig_fn, tag)
        return function(...)
            print("[SAFE2] VM call "..tag)
            local a,b,c,d = pcall(orig_fn, ...)
            -- pcall возвращает ok, ret...
            -- Но orig_fn уже защищена pcall, нужно unpack правильно
            -- На самом деле orig_fn может кикнуть - оборачиваем
            if not a then
                print("[SAFE2] VM pcall error: "..tostring(b))
                error(b,0)
            end
            -- b,c,d - это возвраты VM (их может быть 1-3)
            local ret=b
            if type(ret)=="string" and #ret>=MIN then
                save("vm_return", ret, tag)
                print("[SAFE2] vm_return string "..#ret)
            elseif type(ret)=="table" then
                local n=0; for _ in pairs(ret) do n=n+1 end
                print("[SAFE2] vm_return table keys="..n)
                if n>100 then
                    -- handlers таблица как 1.8M - не сохраняем как vm_return, это не чистый
                    print("[SAFE2] handlers table detected (534) - это не чистый, нужен ПК-деобф")
                else
                    pcall(function()
                        local hs=game:GetService("HttpService")
                        local j=hs:JSONEncode(ret)
                        if #j>=MIN then save("vm_return_table", j, tag.." json") end
                    end)
                end
            else
                print("[SAFE2] vm_return type="..type(ret))
            end
            return b,c,d
        end
    end
    getgenv().loadstring = function(s, chunk, ...)
        if type(s)=="string" and #s>=MIN then pcall(save, "loadstring_src", s, chunk or "") end
        local fn, err = orig_ls(s, chunk, ...)
        if type(fn)=="function" then return makeWrapper(fn, tostring(chunk or "ls")), err end
        return fn, err
    end
    getgenv().load = function(s, chunk, ...)
        if type(s)=="string" and #s>=MIN then pcall(save, "load_src", s, chunk or "") end
        local fn, err = orig_load(s, chunk, ...)
        if type(fn)=="function" then return makeWrapper(fn, tostring(chunk or "load")), err end
        return fn, err
    end
    print("[SAFE2] loadstring wrapped")
end

-- 5. buffer.fromstring стелс
pcall(function()
    if buffer and buffer.fromstring then
        local orig=buffer.fromstring
        buffer.fromstring=function(str,...)
            if type(str)=="string" and #str>=800 then pcall(save, "buffer_fromstring", str, "fromstring") end
            return orig(str,...)
        end
        print("[SAFE2] buffer patch done")
    end
end)
pcall(function()
    local orig=game.HttpGet
    game.HttpGet=function(self,url,...)
        local r=orig(self,url,...)
        if type(r)=="string" and #r>=MIN then pcall(save,"HttpGet",r,url) end
        return r
    end
end)

print("[SAFE2] Готово. Запускай ODH лоадер сейчас. Если опять Malicious - скинь папку "..LOG)
print("[SAFE2] Если не поможет - просто скинь 02 файл (568K) мне, сделаю офлайн-деобф на ПК")
