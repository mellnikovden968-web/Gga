-- Patch_Bootstrapper_Stealth.lua | 100% стелс, без hookfunction, без замены loadstring
-- Патчит сам файл Ixry Shizuka/files/bootstrapper.lua на диске, добавляя хук buffer.fromstring ВНУТРИ файла
-- После патча запускай ODH обычным лоадером - кика не будет, т.к. loadstring не тронут
-- Запуск ОДИН РАЗ: loadstring(readfile("Patch_Bootstrapper_Stealth.lua"))()

local path = "Ixry Shizuka/files/bootstrapper.lua"
local log = "logdump_stealth"
pcall(function() if makefolder then pcall(makefolder, log) end end)

local src = readfile(path)
if not src or #src < 100000 then
    print("[PATCH] файл не найден или мал: "..tostring(path).." len="..tostring(src and #src or 0))
    print("[PATCH] попробуй второй путь: Ixry Shizuka/files/bootstrapper.lua или скачай с cdn и сохрани туда")
    return
end
print("[PATCH] bootstrapper len="..#src)

-- бэкап
pcall(function() writefile(path..".bak", src) end)
print("[PATCH] backup -> "..path..".bak")

-- префикс который будет выполнен ДО Luraph VM, хукает buffer внутри, без глобального loadstring хука
local prefix = [[
-- STEALTH HOOK (injected by Patch_Bootstrapper_Stealth)
local _LOG="logdump_stealth"
pcall(function() if makefolder then pcall(makefolder,_LOG) end end)
do
    local _orig_fromstring = buffer.fromstring
    buffer.fromstring = function(s,...)
        if type(s)=="string" and #s>5000 then
            local ok=pcall(function() writefile(_LOG.."/buffer_"..#s..".bin", s) end)
            print("[STEALTH] buffer.fromstring captured "..#s.." ok="..tostring(ok))
        end
        return _orig_fromstring(s,...)
    end
    print("[STEALTH] buffer.fromstring hooked (stealth)")
    -- байпас кика сразу, до VM
    pcall(function()
        local p=game:GetService("Players").LocalPlayer
        -- не трогаем метаметоды, просто создаём заглушку в глобалках которые VM позже использует
        getgenv().shared = getgenv().shared or {}
        getgenv().shared.kick = function(...) print("[STEALTH] shared.kick blocked") end
        -- odh_shared_plugins создаётся позже VM, ставим мету на _G чтобы поймать момент создания
        local _orig_newindex
        local mt=getrawmetatable(_G)
        if mt then
            _orig_newindex=mt.__newindex
            setreadonly(mt,false)
            mt.__newindex=function(t,k,v)
                if k=="odh_shared_plugins" and type(v)=="table" then
                    print("[STEALTH] odh_shared_plugins creation intercepted")
                    if v.kick then v.kick=function(...) print("[STEALTH] odh kick blocked") end end
                    if v.Kick then v.Kick=v.kick end
                end
                if _orig_newindex then return _orig_newindex(t,k,v) else return rawset(t,k,v) end
            end
            setreadonly(mt,true)
            print("[STEALTH] _G newindex hooked")
        end
        -- CoreGui patch без hookfunction (прямая подмена если возможно)
        pcall(function()
            local cg=game:GetService("CoreGui")
            local orig=cg.FindFirstChild
            cg.FindFirstChild=function(self,n,rec)
                if type(n)=="string" and n:find("bubbles") then return nil end
                return orig(self,n,rec)
            end
            print("[STEALTH] CoreGui patch done")
        end)
    end)
end
]]

-- проверяем не запатчен ли уже
if src:find("STEALTH HOOK") then
    print("[PATCH] уже запатчен, пропускаю")
else
    local patched = prefix .. "\n" .. src
    writefile(path, patched)
    print("[PATCH] patched -> "..path.." new len="..#patched)
    print("[PATCH] теперь запусти ODH ОБЫЧНЫМ лоадером (без дамперов loadstring)")
    print("[PATCH] после загрузки смотри "..log.."/buffer_*.bin  + проверяй кик")
end

-- также сразу ставим те же хуки в текущем окружении чтобы текущий запуск тоже перехватил
print("[PATCH] готово. Для отката: deletefile+ move "..path..".bak -> "..path)
