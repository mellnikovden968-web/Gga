-- Auto Dumper XALOEX FIXED | без меню, авто-деобфускация
-- Фикс: правильно патчит O0OI_ и debug.info("sl")="[C]"
-- Запусти ПЕРВЫМ, потом скрипт. Сохранит даже если кикнет.

local LOG="logdump"
pcall(function() if makefolder and not isfolder(LOG) then makefolder(LOG) end end)
local seen={}
local function save(tag,src,extra)
    if type(src)~="string" or #src<2000 then return end
    local h=#src..src:sub(1,80)
    if seen[h] then return end
    seen[h]=true
    local p=string.format("%s/AUTO_%s_%d.lua",LOG,tag,math.random(10000,99999))
    pcall(function() writefile(p,"-- "..tag.." "..os.date().." "..tostring(extra or "").."\n\n"..src) end)
    print("[AUTO-FIXED] saved "..p.." "..#src)
    return p
end
local function isXaloex(s) return type(s)=="string" and s:find("XALOEX") and s:find("xaloex vm binding") end

local function tryDeobfuscate(src, chunk)
    save("XALOEX_RAW", src, chunk)
    task.spawn(function()
        local ok,err=pcall(function()
            local patched=src
            -- 1. патчим кик-функции _1_(...)
            patched=patched:gsub("_1_%(O_I_%)","--_1_(O_I_)")
            patched=patched:gsub("_1_%(__I_%)","--_1_(__I_)")
            patched=patched:gsub("_1_%(ll1_%)","--_1_(ll1_)")
            patched=patched:gsub("_1_%(Il1_%)","--_1_(Il1_)")
            patched=patched:gsub("_1_%(Ol1_%)","--_1_(Ol1_)")
            patched=patched:gsub("_1_%(l_I_%)","--_1_(l_I_)")
            -- 2. инъекция дампа ПОСЛЕ O0OI_ = O_1I_()  (правильно с возвратом if)
            -- находим "local O0OI_ = O_1I_()   if lI_ or not O0OI_"
            local injected=false
            patched, _ = patched:gsub("local O0OI_ = O_1I_%(%)(.-)if lI_ or not O0OI_", function(spaces)
                injected=true
                -- сохраняем пробелы + if часть
                return "local O0OI_ = O_1I_() pcall(function() local j=game:GetService('HttpService'):JSONEncode({k=O0OI_.k,api=O0OI_.api,code=O0OI_.code,ups=O0OI_.ups,kids=O0OI_.kids,sk=O0OI_.sk}); writefile('"..LOG.."/DECODED_'..tostring(math.random(1000,9999))..'.json',j); local t={}; for i,v in ipairs(O0OI_.k) do t[i]=string.format('%d t=%d d=%s',i,v.t or -1, tostring(v.d and v.d:sub(1,40) or 'nil'):gsub('\\n',' ')) end; writefile('"..LOG.."/KDUMP_'..tostring(math.random(1000,9999))..'.txt', table.concat(t,'\\n')); end) "..spaces.."if lI_ or not O0OI_"
            end, 1)
            if not injected then
                -- fallback: просто после первого O_1I_()
                patched=patched:gsub("local O0OI_ = O_1I_%(%)", "local O0OI_ = O_1I_() pcall(function() writefile('"..LOG.."/DECODED_FALLBACK.json', game:GetService('HttpService'):JSONEncode(O0OI_)) end)", 1)
            end
            -- 3. мокаем debug.info правильно: "l"->44, "s" и "sl" -> "[C]", "a"->2,false, "f"->nil
            local old_info=debug.info
            local function mock_info(a,b)
                if type(b)=="string" then
                    if b:find("l") then return 44 end
                    if b:find("s") then return "[C]" end
                    if b:find("a") then return 2,false end
                    if b:find("f") then return nil end
                end
                -- вызов debug.info(string.byte,"sl") -> должен вернуть "[C]", 0
                if a==string.byte and b=="sl" then return "[C]",0 end
                if a==string.byte then return "[C]",0 end
                return old_info(a,b)
            end
            -- временно подменяем
            debug.info=mock_info
            local f, gerr = loadstring(patched, chunk.."_patched")
            debug.info=old_info
            if not f then
                print("[AUTO-FIXED] patched compile fail: "..tostring(gerr):sub(1,400))
                -- сохраняем патченный чтобы дебажить
                pcall(function() writefile(LOG.."/PATCH_FAIL.lua", patched:sub(1,2000).."\n--ERR:"..tostring(gerr)) end)
                return
            end
            save("XALOEX_PATCHED", patched, chunk)
            print("[AUTO-FIXED] patched OK, запускаю для дампа...")
            -- вызываем в мокнутом окружении, чтобы триггернуть O_1I_ парсинг и наш pcall дамп
            task.spawn(function()
                local old=debug.info
                debug.info=mock_info
                -- глушим _1_ кик если вдруг осталась
                local old_1 = getgenv()._1_
                getgenv()._1_ = function() end
                pcall(f)
                debug.info=old
                getgenv()._1_ = old_1
                print("[AUTO-FIXED] pcall(f) done, смотри "..LOG.."/DECODED_*.json")
            end)
        end)
        if not ok then print("[AUTO-FIXED] err: "..tostring(err):sub(1,600)) end
    end)
end

local orig_ls=loadstring
local hooked_ls=function(str,chunk,...)
    if type(str)=="string" and #str>=2000 and isXaloex(str) then
        print("[AUTO-FIXED] поймал XALOEX "..#str.." bytes")
        tryDeobfuscate(str, chunk or "xaloex")
    elseif type(str)=="string" and #str>=2000 then
        save("loadstring",str,chunk)
    end
    return orig_ls(str,chunk,...)
end
if hookfunction then pcall(hookfunction, orig_ls, hooked_ls) end
getgenv().loadstring=hooked_ls
getgenv().load=function(s,c,...)
    if type(s)=="string" and #s>=2000 and isXaloex(s) then tryDeobfuscate(s,c) end
    return load(s,c,...)
end
pcall(function()
    local orig=game.HttpGet
    local h=function(self,url,...)
        local r=orig(self,url,...)
        if type(r)=="string" and #r>10000 and isXaloex(r) then tryDeobfuscate(r,url) end
        return r
    end
    if hookfunction then pcall(hookfunction, orig,h) else game.HttpGet=h end
end)
-- анти-кик задержка
pcall(function()
    local plr=game:GetService("Players").LocalPlayer
    if plr and plr.Kick then
        local old=plr.Kick
        local hk=function(self,...)
            print("[AUTO-FIXED] Kick задержан 2.5с для дампа")
            task.wait(2.5)
            return old(self,...)
        end
        if hookfunction then pcall(hookfunction, old, hk) end
        pcall(function()
            local mt=getrawmetatable(plr)
            if mt and mt.__namecall then
                local o=mt.__namecall
                setreadonly(mt,false)
                mt.__namecall=newcclosure(function(self,...)
                    if getnamecallmethod()=="Kick" then task.wait(2.2) end
                    return o(self,...)
                end)
                setreadonly(mt,true)
            end
        end)
    end
end)
print("=== AUTO DUMPER FIXED ON ===")
print("Запусти скрипт -> смотри workspace/logdump/DECODED_*.json и KDUMP_*.txt")
pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title="AUTO FIXED ON",Text="Запусти XALOEX скрипт",Duration=4}) end)
