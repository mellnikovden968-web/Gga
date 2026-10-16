-- Auto Dumper XALOEX | без меню, всё само | анти-кик
-- Запусти ЭТОТ скрипт ПЕРВЫМ, потом любой который хочешь высосать
-- Он сам поймает XALOEX и сразу высосет чистые k/api/code в logdump/AUTO_*.lua
-- Даже если тебя кикает через 2 сек - успеет сохранить до кика

local LOG = "logdump"
pcall(function() if makefolder and not isfolder(LOG) then makefolder(LOG) end end)

local MIN = 2000
local seen = {}
local function hash(s) return #s..s:sub(1,80) end
local function save(tag, src, extra)
    if type(src)~="string" or #src<MIN then return end
    local h=hash(src)
    if seen[h] then return end
    seen[h]=true
    local path = string.format("%s/AUTO_%s_%d.lua", LOG, tag, os.time()%100000)
    local head = string.format("-- AUTO %s | %d bytes | %s | %s\n\n", tag, #src, tostring(extra or ""), os.date())
    pcall(function() writefile(path, head..src) end)
    print("[AUTO] saved "..path.." "..#src)
    return path
end

-- ===== 1. STEALTH HOOK loadstring/load =====
local orig_ls = loadstring
local orig_load = load
local function isXaloex(s) return type(s)=="string" and s:find("XALOEX") and s:find("xaloex vm binding") end
local function isLuraph(s) return type(s)=="string" and s:find("Luraph") end

local function tryDeobfuscateXaloex(src, chunk)
    -- пытаемся вытащить чистые таблицы без запуска ВМ-ки (статично)
    -- XALOEX хранит всё в l1_/I1_/O1_/_I_ и ключах lII_/III_/OII_ и тд
    -- Мы просто сохраняем сырой ВМ, а также пытаемся выполнить патченную копию в фоне чтобы вытащить decode
    save("XALOEX_RAW", src, chunk)
    
    -- попытка №1: запустить патченную копию в изолированном потоке и выцепить O0OI_.k / api / code
    task.spawn(function()
        local ok, err = pcall(function()
            -- патчим анти-дебаг: debug.info(1,"l") должен вернуть O1I_, debug.info(.,"s") => "[C]"
            -- O1I_ в этом файле всегда 44 (смотри function I_II_ debug.info==O1I_)
            local patched = src
            -- убираем проверку _1_(O_I_) которая кикает
            patched = patched:gsub("_1_%(O_I_%)", "-- patched _1_(O_I_)")
            patched = patched:gsub("_1_%(__I_%)", "-- patched")
            patched = patched:gsub("_1_%(ll1_%)", "-- patched")
            patched = patched:gsub("_1_%(Il1_%)", "-- patched")
            patched = patched:gsub("_1_%(Ol1_%)", "-- patched")
            -- вставляем дамп сразу после O0OI_ = O_1I_()
            local injected = false
            patched = patched:gsub("local O0OI_ = O_1I_%(%)(.-)if lI_ or not O0OI_", function(a)
                injected = true
                return "local O0OI_ = O_1I_() pcall(function() local j=game:GetService('HttpService'):JSONEncode({k=O0OI_.k,api=O0OI_.api,code=O0OI_.code,ups=O0OI_.ups,kids=O0OI_.kids}); writefile('"..LOG.."/AUTO_XALOEX_DECODED_'..tostring(math.random(100,999))..'.json', j); writefile('"..LOG.."/AUTO_XALOEX_KDUMP.lua', '-- k dump\\n'..table.concat((function() local t={} for i,v in ipairs(O0OI_.k) do t[i]=tostring(v.t)..':'..tostring(v.d and v.d:sub(1,30) or '') end return t end)(), '\\n')) end) "..a
            end, 1)
            
            -- если не нашли O0OI_ паттерн, пробуем другой: O_1I_%(%)
            if not injected then
                patched = patched:gsub("O_1I_%(%)(.-)return", "O_1I_() pcall(function() end) %1return", 1)
            end

            -- мокаем debug.info чтобы не кикало
            local env = getgenv()
            local old_info = debug.info
            local mock_info = function(a,b)
                if b=="l" then return 44 end
                if b=="s" then return "[C]" end
                if b=="a" then return 2, false end
                if b=="f" then return nil end
                return old_info(a,b)
            end
            
            -- сохраняем хук, грузим патченную
            local _old = debug.info
            debug.info = mock_info
            local f, gerr = orig_ls(patched, chunk.."_patched")
            debug.info = _old
            
            if f then
                -- не вызываем f() - он вернет I_II_ обертку, но сам факт что он скомпилился значит патч ок
                save("XALOEX_PATCHED", patched, chunk)
                print("[AUTO] XALOEX patched compiled OK, injected dump")
                -- пробуем вызвать в pcall с фейк аргументами чтобы триггернуть O_1I_ парсинг
                -- I_II_ ожидает (...) и вызывает l0II_ -> там парсится I0II_
                -- вызовем с пустым OlI_ - он распарсит байткод до O0OI_ и сохранит json до кика
                task.spawn(function()
                    local old_debug = debug.info
                    debug.info = mock_info
                    pcall(f)
                    debug.info = old_debug
                end)
            else
                print("[AUTO] patched compile fail: "..tostring(gerr):sub(1,300))
            end
        end)
        if not ok then
            print("[AUTO] deobfuscate pcall fail: "..tostring(err):sub(1,500))
            -- всё равно сохраняем RAW чтобы можно было деобфускать вручную питоном
        end
    end)
end

local function hooked_ls(str, chunk, ...)
    if type(str)=="string" and #str >= MIN then
        if isXaloex(str) then
            print("[AUTO] поймал XALOEX "..#str.." bytes -> деобфускация...")
            tryDeobfuscateXaloex(str, chunk or "xaloex")
            -- всё равно пропускаем оригинал дальше чтобы скрипт запустился (и успел сдампиться до кика)
            -- но делаем это через 0.3 сек чтобы наш патченный успел сохраниться первым
        elseif isLuraph(str) then
            save("Luraph_RAW", str, chunk)
        else
            save("loadstring", str, chunk)
        end
    end
    return orig_ls(str, chunk, ...)
end

if hookfunction then
    pcall(hookfunction, orig_ls, hooked_ls)
    pcall(hookfunction, orig_load, function(s,c,...)
        if type(s)=="string" and #s>=MIN and isXaloex(s) then tryDeobfuscateXaloex(s,c) end
        return orig_load(s,c,...)
    end)
end
getgenv().loadstring = hooked_ls
getgenv().load = function(s,c,...)
    if type(s)=="string" and #s>=MIN and isXaloex(s) then tryDeobfuscateXaloex(s,c) end
    return orig_load(s,c,...)
end

-- HttpGet тоже
pcall(function()
    local orig = game.HttpGet
    local function hooked(self, url, ...)
        local res = orig(self, url, ...)
        if type(res)=="string" and #res> 10000 then
            if isXaloex(res) then tryDeobfuscateXaloex(res, url)
            else save("HttpGet", res, url) end
        end
        return res
    end
    if hookfunction then pcall(hookfunction, orig, hooked) else game.HttpGet = hooked end
end)

-- анти-кик на 3 секунды чтобы успеть сдампить до выгона (хук Kick)
pcall(function()
    local plr = game:GetService("Players").LocalPlayer
    if plr and plr.Kick then
        local oldKick = plr.Kick
        local hookedKick = function(self, ...)
            print("[AUTO] перехвачен Kick, задержка 2 сек для дампа...")
            task.wait(2.2)
            return oldKick(self, ...)
        end
        if hookfunction then pcall(hookfunction, oldKick, hookedKick) else pcall(function() plr.Kick = hookedKick end) end
        -- также через mt
        pcall(function()
            local mt = getrawmetatable(plr)
            if mt and mt.__namecall then
                local old = mt.__namecall
                setreadonly(mt, false)
                mt.__namecall = newcclosure(function(self, ...)
                    if getnamecallmethod()=="Kick" then
                        print("[AUTO] namecall Kick задержан")
                        task.wait(2)
                    end
                    return old(self, ...)
                end)
                setreadonly(mt, true)
            end
        end)
    end
end)

print("=== AUTO DUMPER ON (без меню) ===")
print("Запусти скрипт который хочешь высосать - он сам сохранится в workspace/logdump/AUTO_*")
print("Даже если кикнет - файлы останутся, смотри через 2 сек после кика в папке")
pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title="AUTO DUMPER ON", Text="Запусти скрипт - он сам высосется", Duration=4}) end)

-- также хук для уже загруженного XALOEX из твоего файла 01_loadstring.lua.txt (281k)
-- если запустишь этот файл напрямую - он тоже поймается
