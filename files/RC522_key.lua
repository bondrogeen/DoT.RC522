local function read()
 local r
 if file.open("key.json","r") then
  local ok, json = pcall(sjson.decode,file.read('\n'))
  file.close()
  if ok then r=json end
 end
 return r
end
local function get()
local r
local ok, json = pcall(sjson.encode,read())
if ok then r=json end
return r
end
local function auth(s)
 local r
 local t = read() and read() or {}
 for i = 1, #t do
 if t[i]==s then r=i end
 end
 return r
end
local function save(t)
local r
local ok, json = pcall(sjson.encode,t)
 if ok then
  if file.open("key.json", "w") then
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
 if t.init=="add" and t.key then r=add(t.key) end
 if t.init=="get" then r=get() end
 if t.init=="del" and t.key then r=del(t.key) end
 if t.init=="auth" and t.key then r=auth(t.key) and true or false end
 return tostring (r)
end
