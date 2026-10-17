-- Install_Yield_Patch.lua | патчит bootstrapper чтобы VM не фризила (добавляет task.wait в цикл)
-- Запуск: loadstring(readfile("Install_Yield_Patch.lua"))()
local path = "Ixry Shizuka/files/bootstrapper.lua"
local src = readfile(path)
if not src or #src<100000 then print("not found "..path) return end
if src:find("task%.wait%(%) end;") then print("already patched") return end
-- бэкап
writefile(path..".bak2", src)
print("backup .bak2 len "..#src)
local patched = src:gsub("while v do", "while v do if task.wait then task.wait() end; ", 1)
if patched==src then
    -- пробуем другой паттерн while v do if
    patched = src:gsub("while v do if", "while v do task.wait(); if", 1)
end
writefile(path, patched)
print("patched len "..#patched.." -> "..path)
print("теперь запускай Decompile_ODH_Yield.lua или Decompile_ODH_Direct.lua")
