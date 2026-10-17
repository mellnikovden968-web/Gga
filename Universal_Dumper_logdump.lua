-- Decompile ODH Async | не вешает игру, показывает прогресс
-- Запуск: loadstring(readfile("Decompile_ODH_Async.lua"))()

local bootPath = "Ixry Shizuka/files/bootstrapper.lua"
if isfile(bootPath..".bak") then
    local s=readfile(bootPath)
    if s and s:find("STEALTH HOOK") then pcall(function() writefile(bootPath, readfile(bootPath..".bak")) end) print("[ASYNC] откатил stealth патч") end
end
local src = readfile(bootPath)
if not src or #src<100000 then
    local ok,r=pcall(function() return game:HttpGet("https://cdn.overdrivehub.xyz/bootstrapper.lua") end)
    if ok and r then src=r end
end
print("[ASYNC] boot len "..tostring(src and #src or 0))

-- байпасы
pcall(function()
    local ok,cg=pcall(function() return game:GetService("CoreGui") end)
    if ok and cg and cg.FindFirstChild then
        local o=cg.FindFirstChild
        cg.FindFirstChild=function(self,n,rec) if type(n)=="string" and n:find("bubbles") then return nil end return o(self,n,rec) end
    end
end)
getgenv().shared = getgenv().shared or {}
getgenv().shared.kick = function(...) print("[ASYNC] kick blocked") end

local key1 = "\25\31\98\86\30\24\99\81\30\24\96\81\31\25\102\80\30\24\99\81\30\24\96\81\9\15\113\70\9\15\112\70\20\18\111\91\21\19\108\90\20\18\111\91\21\19\108\90\21\19\108\90\9\15\112\70\14\8\113\65\11\13\115\68\9\15\115\70\21\19\110\90\11\13\114\68\14\8\113\65\8\14\112\71\9\15\112\70\9\15\113\70\9\15\112\70\14\8\113\65\21\19\108\90\8\14\114\71\20\18\110\91\21\19\110\90\14\8\113\65\8\14\112\71\8\14\112\71\21\19\108\90\20\18\111\91\9\15\115\70\8\14\112\71\21\19\108\90\20\18\108\91\20\18\110\91\9\15\112\70\20\18\108\91\20\18\111\91"
local key2 = "\21\19\100\90\27\29\107\84\31\25\110\80\30\24\107\81\25\31\107\86\31\25\110\80\29\27\108\82\13\11\125\66\17\23\98\94\30\24\107\81\30\24\110\81\24\30\106\87\28\26\111\83\25\31\107\86\13\11\125\66\24\30\85\87\29\27\108\82\25\31\106\86\13\11\125\66\31\25\111\80\28\26\111\83\25\31\107\86\28\26\111\83\14\8\120\65"

print("[ASYNC] loadstring...")
local fn,err = loadstring(src)
if not fn then print("fail "..tostring(err)) return end
print("[ASYNC] loadstring ok, VM стартует (телефон зависнет на 60-90 сек, не трогай!)")

-- heartbeat чтобы видеть что не умер
task.spawn(function()
    for i=1,120 do
        task.wait(1)
        print("[ASYNC] heartbeat "..i.."s / VM decrypting...")
    end
end)

-- запуск VM в отдельном потоке чтобы не вешать проверку heartbeat
task.spawn(function()
    local t0 = tick()
    local ok, ret = pcall(fn, key1, key2)
    print(string.format("[ASYNC] VM done in %.1fs ok=%s type=%s", tick()-t0, tostring(ok), type(ret)))
    if not ok then print("VM err "..tostring(ret):sub(1,2000)) return end
    if type(ret)=="function" then
        print("[ASYNC] ret function, decompiling (ещё 30 сек)...")
        task.wait(1)
        if decompile then
            local ok2, code = pcall(decompile, ret)
            if ok2 and code and #code>1000 then
                pcall(function() if makefolder then makefolder("logdump_stealth") end end)
                writefile("logdump_stealth/ODH_CLEAN.lua", code)
                print("[ASYNC] SAVED ODH_CLEAN "..#code.." -> logdump_stealth/ODH_CLEAN.lua")
                print(code:sub(1,1000))
            else
                print("decompile fail "..tostring(code):sub(1,500))
            end
        else
            print("no decompile, trying call ret()")
            local ok2,r2=pcall(ret)
            print("r2 "..type(r2).." "..tostring(r2 and #r2 or 0))
            if type(r2)=="string" and #r2>1000 then writefile("logdump_stealth/ODH_CLEAN2.lua", r2) print("saved2") end
        end
    elseif type(ret)=="string" then
        pcall(function() if makefolder then makefolder("logdump_stealth") end end)
        writefile("logdump_stealth/ODH_CLEAN.lua", ret)
        print("[ASYNC] saved string "..#ret)
    elseif type(ret)=="table" then
        local n=0; for _ in pairs(ret) do n=n+1 end
        print("table n="..n)
        for k,v in pairs(ret) do
            if type(v)=="function" then
                print("try decompile key "..tostring(k))
                if decompile then
                    local ok2,code=pcall(decompile,v)
                    if ok2 and code and #code>1000 then
                        writefile("logdump_stealth/ODH_CLEAN_"..tostring(k)..".lua", code)
                        print("saved "..k)
                        break
                    end
                end
            end
        end
    end
    print("[ASYNC] DONE смотри logdump_stealth/")
end)
print("[ASYNC] VM запущена в фоне, жди heartbeat и не закрывай игру 2 минуты")
