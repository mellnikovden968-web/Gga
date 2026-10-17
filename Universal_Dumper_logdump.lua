-- Decompile ODH Direct | ТОЛЬКО ТЕЛЕФОН, без ПК, без хуков loadstring
-- Не хукает loadstring -> не палится Malicious Loader
-- Просто вызывает bootstrapper напрямую и декомпилит результат
-- Запуск: loadstring(readfile("Decompile_ODH_Direct.lua"))()

local bootPath = "Ixry Shizuka/files/bootstrapper.lua"
-- если файл запатчен stealth-патчем, откати:
if isfile(bootPath..".bak") and isfile(bootPath) then
    local s=readfile(bootPath)
    if s:find("STEALTH HOOK") then
        print("[DIRECT] найден stealth патч, откатываю на .bak")
        pcall(function() writefile(bootPath, readfile(bootPath..".bak")) end)
    end
end

local src = readfile(bootPath)
if not src or #src < 100000 then
    -- пробуем второй путь
    bootPath = "Ixry Shizuka/files/bootstrapper.lua"
    src = readfile(bootPath)
end
if not src then
    print("[DIRECT] не нашёл "..bootPath.." -> качаю с CDN")
    local ok, r = pcall(function() return game:HttpGet("https://cdn.overdrivehub.xyz/bootstrapper.lua") end)
    if ok and r and #r>100000 then src=r; writefile(bootPath, src) end
end
print("[DIRECT] boot len "..tostring(src and #src or 0))

-- байпас кика ДО вызова VM (без хуков loadstring)
pcall(function()
    -- CoreGui @bubbles
    local ok,cg=pcall(function() return game:GetService("CoreGui") end)
    if ok and cg and cg.FindFirstChild then
        local orig=cg.FindFirstChild
        cg.FindFirstChild=function(self,n,rec)
            if type(n)=="string" and n:find("bubbles") then return nil end
            return orig(self,n,rec)
        end
        print("[DIRECT] CoreGui bypass ok")
    end
end)
pcall(function()
    getgenv().shared = getgenv().shared or {}
    getgenv().shared.kick = function(...) print("[DIRECT] shared.kick blocked") end
    -- odh_shared_plugins появится после VM, перехватим через poll
    task.spawn(function()
        for i=1,100 do
            task.wait(0.2)
            local h = rawget(getgenv(),"odh_shared_plugins") or rawget(_G,"odh_shared_plugins")
            if h and h.kick then h.kick=function() print("[DIRECT] odh kick blocked") end; print("[DIRECT] odh kick hooked"); break end
        end
    end)
end)

-- ключи из лоадера Ixry Shizuka (те же что в 01)
local key1 = "\25\31\98\86\30\24\99\81\30\24\96\81\31\25\102\80\30\24\99\81\30\24\96\81\9\15\113\70\9\15\112\70\20\18\111\91\21\19\108\90\20\18\111\91\21\19\108\90\21\19\108\90\9\15\112\70\14\8\113\65\11\13\115\68\9\15\115\70\21\19\110\90\11\13\114\68\14\8\113\65\8\14\112\71\9\15\112\70\9\15\113\70\9\15\112\70\14\8\113\65\21\19\108\90\8\14\114\71\20\18\110\91\21\19\110\90\14\8\113\65\8\14\112\71\8\14\112\71\21\19\108\90\20\18\111\91\9\15\115\70\8\14\112\71\21\19\108\90\20\18\108\91\20\18\110\91\9\15\112\70\20\18\108\91\20\18\111\91"
local key2 = "\21\19\100\90\27\29\107\84\31\25\110\80\30\24\107\81\25\31\107\86\31\25\110\80\29\27\108\82\13\11\125\66\17\23\98\94\30\24\107\81\30\24\110\81\24\30\106\87\28\26\111\83\25\31\107\86\13\11\125\66\24\30\85\87\29\27\108\82\25\31\106\86\13\11\125\66\31\25\111\80\28\26\111\83\25\31\107\86\28\26\111\83\14\8\120\65"

print("[DIRECT] keys ready, calling VM...")

local fn, err = loadstring(src)
if not fn then print("[DIRECT] loadstring failed "..tostring(err)) return end
print("[DIRECT] loadstring ok")

local ok, ret = pcall(fn, key1, key2)
print("[DIRECT] VM pcall ok="..tostring(ok).." ret type="..type(ret))
if not ok then
    print("[DIRECT] VM error: "..tostring(ret))
    return
end

-- ret может быть function, string, table
if type(ret)=="function" then
    print("[DIRECT] ret is function, decompiling...")
    if decompile then
        local ok2, code = pcall(decompile, ret)
        if ok2 and code and #code>1000 then
            writefile("logdump_stealth/ODH_CLEAN.lua", code)
            print("[DIRECT] SAVED logdump_stealth/ODH_CLEAN.lua ("..#code..")")
            print(code:sub(1,800))
        else
            print("[DIRECT] decompile fail "..tostring(code))
        end
    else
        print("[DIRECT] no decompile available, trying to call ret()")
        local ok2, r2 = pcall(ret)
        print("call ret ok="..tostring(ok2).." "..type(r2))
        if type(r2)=="string" and #r2>1000 then writefile("logdump_stealth/ODH_CLEAN2.lua", r2) print("saved2 "..#r2) end
    end
elseif type(ret)=="string" then
    writefile("logdump_stealth/ODH_CLEAN.lua", ret)
    print("[DIRECT] ret string saved "..#ret)
elseif type(ret)=="table" then
    local n=0; for _ in pairs(ret) do n=n+1 end
    print("[DIRECT] ret table n="..n)
    -- если handlers таблица (как 1.8M), пробуем найти внутри неё функцию с кодом
    for k,v in pairs(ret) do
        if type(v)=="function" then
            print("found function at key "..tostring(k)..", decompiling...")
            if decompile then
                local ok2, code = pcall(decompile, v)
                if ok2 and code and #code>1000 then
                    writefile("logdump_stealth/ODH_CLEAN_"..tostring(k)..".lua", code)
                    print("saved "..k.." "..#code)
                    break
                end
            end
        end
    end
    -- также попробуем getgc
    if getgc then
        print("[DIRECT] scanning getgc for large functions...")
        for _,f in ipairs(getgc(true)) do
            if type(f)=="function" then
                local ok2, code = pcall(decompile, f)
                if ok2 and code and #code>5000 and code:find("Overdrive") then
                    writefile("logdump_stealth/ODH_gc.lua", code)
                    print("found gc Overdrive "..#code)
                    break
                end
            end
        end
    end
else
    print("[DIRECT] unknown ret "..tostring(ret))
end

print("[DIRECT] done, смотри logdump_stealth/")
