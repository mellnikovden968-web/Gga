-- MINIMAL SAFE DUMPER | только loadstring, без makefolder/HttpGet
-- Для теста: если этот запустится без ошибки, значит проблема была в makefolder/hook
print("[MINIMAL] start")
local LOG="logdump"
-- НЕ делаем makefolder вообще
local seen,cnt={},0
local function save(tag, src, extra)
    if type(src)~="string" or #src<500 then return end
    local h=#src..":"..src:sub(1,50)
    if seen[h] then return end
    seen[h]=true
    cnt=cnt+1
    local name=LOG.."/"..cnt.."_"..tag..".lua"
    local ok,err=pcall(function() writefile(name, "-- "..tag.." "..tostring(extra or "").."\n\n"..src) end)
    if ok then print("[MINIMAL] saved "..name.." "..#src)
    else print("[MINIMAL] writefile fail "..tostring(err)) end
end
print("[MINIMAL] hook loadstring")
local orig = loadstring
if not orig then
    print("[MINIMAL] loadstring is nil! try load")
    orig = load
end
if orig then
    getgenv().loadstring = function(s, chunk, ...)
        print("[MINIMAL] loadstring called", chunk or "no chunk", s and #s or 0)
        if type(s)=="string" and #s>=500 then pcall(save, "loadstring", s, chunk) end
        return orig(s, chunk, ...)
    end
    print("[MINIMAL] hook ok")
else
    print("[MINIMAL] no loadstring/load found!")
end
print("[MINIMAL] done, запусти любой скрипт")
