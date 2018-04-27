local function read()
 local r
 if file.open("RC522_key.json","r") then
  local ok, json = pcall(sjson.decode,file.read('\n'))
  file.close()
  if ok then r=json end
 end
 return r
end

local function auth(s)
 local r
 local t = read() and read() or {}
 for i, val in ipairs(t) do
   if val==s then r=i end
 end
 return r
end

local function save(t)
local r
local ok, json = pcall(sjson.encode,t)
 if ok then
  if file.open("RC522_key.json", "w") then
   file.write(json)
   file.close()
  end
   print(json)
   r = true
 end
 return r
end
local function add(s)
 local t = read() and read() or {}
 local i = not auth(s)
 if i then t[#t+1]=s i=save(t) end
 return i
end
local function del(s)
 local t = read() and read() or {}
 local i = auth(s)
 if i then table.remove(t,i) i=save(t) end
 return i
end

return function (t)
 local r
 if t.add then r=add(t.add) end
 if t.mode then RC522=t.mode r=t.mode end
 if t.del then r=del(t.del) end
 if t.auth then r=auth(t.auth) and true or false end
 return tostring (r)
end
