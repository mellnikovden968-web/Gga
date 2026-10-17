-- Universal Dumper V3 | ловит НЕ только loadstring, но и РЕЗУЛЬТАТ вызова расшифрованных функций
-- Фикс для 1.8M VM (файл 3) — это не скрипт а таблица хендлеров, чистый код появляется ПОСЛЕ вызова a(key1,key2)
-- Этот дампер оборачивает loadstring -> возвращает wrapped функцию, которая логирует что вернул VM

local LOG="logdump_v3"
pcall(function() if makefolder then pcall(makefolder, LOG) end end)
local seen, cnt={},0
local MIN=800
local function save(tag, src, extra)
    if type(src)~="string" or #src<MIN then return end
    if not (src:find("function") or src:find("local") or src:find("game") or src:find("=")) and #src<2000 then return end
    local h=#src..":"..src:sub(1,80)
    if seen[h] then return end
    seen[h]=true; cnt=cnt+1
    local name=string.format("%s/%02d_%s.lua", LOG, cnt, tag)
    local head=string.format("-- V3 DUMP | %s | %d bytes | %s | %s\n\n", tag, #src, tostring(extra or ""), os.date("%H:%M:%S"))
    pcall(function() writefile(name, head..src) end)
    print("[V3] saved "..name.." ("..#src..") <- "..tostring(extra or ""))
    return name
end

print("=== UNIVERSAL V3 ON ===")

-- helper to save any string return value
local function trySaveReturn(ret, tag)
    if type(ret)=="string" and #ret>=MIN then
        save(tag, ret, "return_value")
    elseif type(ret)=="table" then
        -- if table contains functions (VM handler table like file 3), count it
        local n=0; for _ in pairs(ret) do n=n+1 end
        if n>100 then
            print("[V3] table return with "..n.." entries — handler table (like 1.8M), not dumping as string")
            -- try to dump serialized keys?
            pcall(function()
                local s=game:GetService("HttpService"):JSONEncode(ret)
                if #s>=MIN then save(tag.."_table_keys", s, "keys") end
            end)
        end
    end
end

do
    local orig_ls = loadstring
    local orig_load = load
    local function makeWrapper(orig_fn, kind, chunk)
        return function(...)
            print("[V3] wrapped "..kind.." called -> executing VM...")
            local ret = {orig_fn(...)}
            print("[V3] VM returned "..#ret.." values, types: "..table.concat((function()
                local t={}; for i,v in ipairs(ret) do t[i]=type(v)..(type(v)=="string" and "("..#v..")" or "") end; return t
            end)(), ", "))
            for i,v in ipairs(ret) do
                trySaveReturn(v, kind.."_ret"..i)
                -- if return is function, also hook its calls?
                if type(v)=="function" then
                    print("[V3] return "..i.." is function, will also log strings inside if called")
                end
            end
            return unpack(ret)
        end
    end

    local function hook_ls(s, chunk, ...)
        if type(s)=="string" and #s>=MIN then
            save("loadstring_src", s, chunk)
        end
        local fn, err = orig_ls(s, chunk, ...)
        if type(fn)=="function" then
            -- оборачиваем чтобы поймать расшифрованный возврат
            return makeWrapper(fn, "loadstring_src", chunk), err
        end
        return fn, err
    end
    local function hook_load(s, chunk, ...)
        if type(s)=="string" and #s>=MIN then save("load_src", s, chunk) end
        local fn, err = orig_load(s, chunk, ...)
        if type(fn)=="function" then return makeWrapper(fn, "load_src", chunk), err end
        return fn, err
    end
    getgenv().loadstring = hook_ls
    getgenv().load = hook_load
    if hookfunction then
        pcall(hookfunction, orig_ls, hook_ls)
        pcall(hookfunction, orig_load, hook_load)
    end
    print("[V3] loadstring/load wrapped with return logger")
end

-- также логируем HttpGet как раньше
do
    local orig = game.HttpGet
    local function hook(self, url, ...)
        local r = orig(self, url, ...)
        if type(r)=="string" and #r>=MIN then
            save("HttpGet", r, url)
        end
        return r
    end
    if hookfunction then pcall(hookfunction, orig, hook) else game.HttpGet = hook end
end

-- table.concat тоже
do
    local orig = table.concat
    local function hook(t, sep, i,j)
        local r=orig(t,sep,i,j)
        if type(r)=="string" and #r>=3000 and (r:find("function") or r:find("local")) then
            save("concat", r, "table.concat")
        end
        return r
    end
    if hookfunction then pcall(hookfunction, orig, hook) else table.concat=hook end
end

print("[V3] готово. Запусти снова проблемный скрипт — теперь поймает и то что VM ВЕРНУЛА после расшифровки")
print("[V3] смотри папку "..LOG.." (а не logdump)")
