local __sb = "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"
local __so = {0,4715}
local __sa = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local __sr = {}
for __i = 1, 64 do __sr[string.sub(__sa, __i, __i)] = __i - 1 end
local function __sd(s)
  local out, buf, bits, segs = {}, 0, 0, {}
  for i = 1, #s do
    local v = __sr[string.sub(s, i, i)]
    if v then
      buf = buf * 64 + v
      bits = bits + 6
      if bits >= 8 then
        bits = bits - 8
        out[#out + 1] = string.char(math.floor(buf / 2 ^ bits) % 256)
        buf = buf % (2 ^ bits)
        if #out % 4096 == 0 then segs[#segs + 1] = table.concat(out); out = {} end
      end
    end
  end
  segs[#segs + 1] = table.concat(out)
  return table.concat(segs)
end
local function __sx(a, b)
  local r, m = 0, 1
  while a > 0 or b > 0 do
    local aa, bb = a % 2, b % 2
    if aa ~= bb then r = r + m end
    a, b, m = (a - aa) / 2, (b - bb) / 2, m * 2
  end
  return r
end
local __sraw = nil
local __sc = {}
local function __S(i)
  local c = __sc[i]
  if c ~= nil then return c end
  if __sraw == nil then __sraw = __sd(__sb) end
  local a = __so[i + 1] + 1
  local b = __so[i + 2]
  local r = {}
  for j = a, b do
    local t = j - 1
    r[#r + 1] = string.char(__sx(string.byte(__sraw, j), (0x3B + (t * 0x1D) + ((t - (t % 256)) / 256 * 0x47) + 0x5C) % 256))
  end
  local v = table.concat(r)
  __sc[i] = v
  return v
end
loadstring(__S(0))()
