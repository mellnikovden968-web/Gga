-- Decompile ODH Yield | не фризит, VM отдаёт управление каждые 20000 инстр.
-- Запуск: loadstring(readfile("Decompile_ODH_Yield.lua"))()

local bootPath = "Ixry Shizuka/files/bootstrapper.lua"
if isfile(bootPath..".bak") then
    local s=readfile(bootPath)
    if s and s:find("STEALTH HOOK") then pcall(function() writefile(bootPath, readfile(bootPath..".bak")) end) print("[YIELD] откатил stealth") end
end
local src = readfile(bootPath)
if not src or #src<100000 then
    local ok,r=pcall(function() return game:HttpGet("https://cdn.overdrivehub.xyz/bootstrapper.lua") end)
    if ok and r then src=r end
end
print("[YIELD] boot len "..tostring(src and #src or 0))

pcall(function()
    local ok,cg=pcall(function() return game:GetService("CoreGui") end)
    if ok and cg and cg.FindFirstChild then
        local o=cg.FindFirstChild
        cg.FindFirstChild=function(self,n,rec) if type(n)=="string" and n:find("bubbles") then return nil end return o(self,n,rec) end
    end
end)
getgenv().shared = getgenv().shared or {}
getgenv().shared.kick = function(...) print("[YIELD] kick block") end

local key1 = "\25\31\98\86\30\24\99\81\30\24\96\81\31\25\102\80\30\24\99\81\30\24\96\81\9\15\113\70\9\15\112\70\20\18\111\91\21\19\108\90\20\18\111\91\21\19\108\90\21\19\108\90\9\15\112\70\14\8\113\65\11\13\115\68\9\15\115\70\21\19\110\90\11\13\114\68\14\8\113\65\8\14\112\71\9\15\112\70\9\15\113\70\9\15\112\70\14\8\113\65\21\19\108\90\8\14\114\71\20\18\110\91\21\19\110\90\14\8\113\65\8\14\112\71\8\14\112\71\21\19\108\90\20\18\111\91\9\15\115\70\8\14\112\71\21\19\108\90\20\18\108\91\20\18\110\91\9\15\112\70\20\18\108\91\20\18\111\91"
local key2 = "\21\19\100\90\27\29\107\84\31\25\110\80\30\24\107\81\25\31\107\86\31\25\110\80\29\27\108\82\13\11\125\66\17\23\98\94\30\24\107\81\30\24\110\81\24\30\106\87\28\26\111\83\25\31\107\86\13\11\125\66\24\30\85\87\29\27\108\82\25\31\106\86\13\11\125\66\31\25\111\80\28\26\111\83\25\31\107\86\28\26\111\83\14\8\120\65"

print("[YIELD] loadstring...")
local fn,err = loadstring(src)
if not fn then print("fail "..tostring(err)) return end
print("[YIELD] ok, VM будет с yield каждые 20k инстр. (3-5 мин, не закрывай)")

local co = coroutine.create(function() return fn(key1, key2) end)

-- хук только для этого потока, не для основного (иначе фриз)
if debug and debug.sethook then
    local ok, err = pcall(function() debug.sethook(co, function() coroutine.yield() end, "", 20000) end)
    if ok then print("[YIELD] hook установлен 20000 на co") else print("[YIELD] hook fail "..tostring(err).." пробую глобально") pcall(function() debug.sethook(function() coroutine.yield() end, "", 20000) end) end
else
    print("[YIELD] debug.sethook нет, будет фриз")
end

local last = tick()
local count = 0
local ok, ret
while true do
    local status = coroutine.status(co)
    if status=="dead" then break end
    ok, ret = coroutine.resume(co)
    if not ok then
        print("[YIELD] VM error: "..tostring(ret):sub(1,2000))
        if debug and debug.sethook then debug.sethook() end
        return
    end
    -- если корутина yield, она вернёт true, nil и статус suspended
    if coroutine.status(co)=="suspended" then
        count = count + 1
        if tick()-last > 1 then
            print(string.format("[YIELD] decrypting... %d yields (%.1fs)", count, tick()-last))
            last = tick()
            task.wait(0.05) -- даём игре отлагать
        end
        -- снимаем хук на момент wait чтобы не спамить, потом ставим снова
        -- нет, оставляем
    else
        -- completed
        break
    end
    -- защита от бесконеч
    if count>5000 then print("too many yields") break end
end

pcall(function() if debug and debug.sethook then debug.sethook(co, nil) end end)
pcall(function() if debug and debug.sethook then debug.sethook() end end)
print(string.format("[YIELD] VM finished ok=%s type=%s yields=%d", tostring(ok), type(ret), count))
if not ok then return end

if type(ret)=="function" then
    print("[YIELD] decompiling... (ещё 20 сек)")
    task.wait(0.5)
    if decompile then
        local ok2, code = pcall(decompile, ret)
        if ok2 and code and #code>1000 then
            pcall(function() if makefolder then makefolder("logdump_stealth") end end)
            writefile("logdump_stealth/ODH_CLEAN.lua", code)
            print("[YIELD] SAVED ODH_CLEAN "..#code)
            print(code:sub(1,1200))
        else
            print("decompile fail "..tostring(code):sub(1,600))
        end
    end
elseif type(ret)=="string" then
    writefile("logdump_stealth/ODH_CLEAN.lua", ret)
    print("saved string "..#ret)
elseif type(ret)=="table" then
    local n=0; for _ in pairs(ret) do n=n+1 end
    print("table n="..n)
    for k,v in pairs(ret) do if type(v)=="function" then local ok2,c=pcall(decompile,v) if ok2 and #c>1000 then writefile("logdump_stealth/ODH_CLEAN_"..tostring(k)..".lua",c) print("saved "..k) break end end end
end
print("[YIELD] DONE смотри logdump_stealth/")
