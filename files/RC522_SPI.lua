local function dev_write(a,v)
 gpio.write(_RC522.pin_ss, gpio.LOW)
 spi.send(1, bit.band(bit.lshift(a,1),0x7E),v)
 gpio.write(_RC522.pin_ss, gpio.HIGH)
end

local function dev_read(address)
 local val=0;
 gpio.write(_RC522.pin_ss, gpio.LOW)
 spi.send(1,bit.bor(bit.band(bit.lshift(address,1),0x7E),0x80))
 val=spi.recv(1,1)
 gpio.write(_RC522.pin_ss, gpio.HIGH)
 return string.byte(val)
end

local function set_bitmask(a,m)
 dev_write(a,bit.bor(dev_read(a),m))
end

local function clear_bitmask(a,m)
  dev_write(a,bit.band(dev_read(a),bit.bnot(m)))
end

local function card_write(com, data)
  local bd,bl,err,irq,iw,lb,n = {}, 0, false, 0x00, 0x00, 0, 0
  if com == 0x0E then irq = 0x12 iw = 0x10 end
  if com == 0x0C then irq = 0x77 iw = 0x30 end
  dev_write(0x02, bit.bor(irq, 0x80))
  clear_bitmask(0x04,0x80)
  set_bitmask(0x0A,0x80)
  dev_write(0x01,0x00)
  for i,v in ipairs(data)do dev_write(0x09,data[i])end
  dev_write(0x01,com)
  if com==0x0C then
   set_bitmask(0x0D,0x80)
  end
  local i=25
  while true do
   tmr.delay(1)
   n=dev_read(0x04)
   i=i-1
   if not((i~=0)and(bit.band(n,0x01)==0)and(bit.band(n,iw)==0))then break end
  end
  clear_bitmask(0x0D,0x80)
  if (i~=0)then
   if bit.band(dev_read(0x06),0x1B)==0x00 then
    err=false
    if(com==0x0C)then
     n=dev_read(0x0A)
     lb=bit.band(dev_read(0x0C),0x07)
     if lb~=0 then bl=(n-1)*8+lb else bl=n*8 end
     if(n==0)then n=1 end
     if (n>16) then n=16 end
     for i=1,n do bd[i]=dev_read(0x09)end
    end
   else
    err=true
   end
  end
  return err,bd,bl
end

local function toHex(t)
 local s = ""
 for i,v in ipairs(t) do
  s=s..string.format("%X",t[i])
 end
 return s
end

local function anticoll()
 local data,s,err={},0
 dev_write(0x0D,0x00)
 err,data,_=card_write(0x0C,{0x93,0x20})
 if not err then
  if table.maxn(data)==5 then
   for i, v in ipairs(data) do s=bit.bxor(s,data[i])end
   err=true
   if s==data[4] then err=false end
  end
 end
 return err and toHex(data)
end

local function request()
 local err,bits,data=true,0
 dev_write(0x0D,0x07)
 err,data,bits=card_write(0x0C,{0x26})
 if err or (bits~=0x10) then
  return false,nil
 end
 return true,toHex(data)
end

local function init()
print("init p = ".._RC522.pin_ss)
spi.setup(1, spi.MASTER, spi.CPOL_LOW, spi.CPHA_LOW, spi.DATABITS_8, 0)
gpio.mode(_RC522.pin_ss,gpio.OUTPUT)
dev_write(0x01,0x0F)
dev_write(0x2A,0x8D)
dev_write(0x2B,0x3E)
dev_write(0x2D,30)
dev_write(0x2C,0)
dev_write(0x15,0x40)
dev_write(0x11,0x3D)
if bit.bnot(bit.band(dev_read(0x14),0x03))then
  set_bitmask(0x14,0x03)
end
return "RC522 Firmware Version: 0x"..string.format("%X", dev_read(0x37))
end
return function (t)
if t.request then return request()end
if t.init then return init()end
if t.anticoll then return anticoll()end
end
