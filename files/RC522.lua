local pin_ss

local function dev_write(address, value)
  gpio.write(pin_ss, gpio.LOW)
  spi.send(1, bit.band(bit.lshift(address,1), 0x7E), value)
  gpio.write(pin_ss, gpio.HIGH)
end

local function dev_read(address)
  local val = 0;
  gpio.write(pin_ss, gpio.LOW)
  spi.send(1,bit.bor(bit.band(bit.lshift(address,1), 0x7E), 0x80))
  val = spi.recv(1,1)
  gpio.write(pin_ss, gpio.HIGH)
  return string.byte(val)
end

local function set_bitmask(address, mask)
  local current = dev_read(address)
  dev_write(address, bit.bor(current, mask))
end

local function clear_bitmask(address, mask)
  local current = dev_read(address)
  dev_write(address, bit.band(current, bit.bnot(mask)))
end

local function card_write(command, data)
  local back_data,back_length,err,irq,irq_wait,last_bits,n = {}, 0, false, 0x00, 0x00, 0, 0
  if command == 0x0E then
    irq = 0x12
    irq_wait = 0x10
  end
  if command == 0x0C then
    irq = 0x77
    irq_wait = 0x30
  end
  dev_write(0x02, bit.bor(irq, 0x80))
  clear_bitmask(0x04, 0x80)
  set_bitmask(0x0A, 0x80)
  dev_write(0x01, 0x00)
  for i,v in ipairs(data) do
    dev_write(0x09, data[i])
  end
  dev_write(0x01, command)
  if command == 0x0C then
    set_bitmask(0x0D, 0x80)
  end
  local i = 25
  while true do
    tmr.delay(1)
    n = dev_read(0x04)
    i = i - 1
    if not ((i ~= 0) and (bit.band(n, 0x01) == 0) and (bit.band(n, irq_wait) == 0)) then
      break
    end
  end
  clear_bitmask(0x0D, 0x80)
  if (i ~= 0) then
    if bit.band(dev_read(0x06), 0x1B) == 0x00 then
      err = false
      if (command == 0x0C) then
        n = dev_read(0x0A)
        last_bits = bit.band(dev_read(0x0C),0x07)
        if last_bits ~= 0 then
          back_length=(n-1)*8+last_bits
        else
          back_length=n*8
        end
        if (n==0)then
          n=1
        end
        if (n>16) then
          n=16
        end
        for i=1, n do
        back_data[i] = dev_read(0x09)
        end
      end
    else
      err=true
    end
  end
  return  err, back_data, back_length
end

local function anticoll()
  local back_data,num,serial,err = {}, {}, 0
  dev_write(0x0D, 0x00)
  num[1] = 0x93
  num[2] = 0x20
  err, back_data, _ = card_write(0x0C, num)
  if not err then
    if table.maxn(back_data) == 5 then
      for i, v in ipairs(back_data) do
        serial = bit.bxor(serial, back_data[i])
      end
      if serial ~= back_data[4] then
        err=true
      end
    else
      err=true
    end
  end
  return error, back_data
end

local function request()
 local err,back_bits,back_data = true, 0
 dev_write(0x0D, 0x07)
 err, back_data, back_bits = card_write(0x0C, { 0x26 })
 if err or (back_bits ~= 0x10) then
  return false, nil
 end
 return true, back_data
end

local function init()
print("init p = "..pin_ss)
gpio.mode(pin_ss,gpio.OUTPUT)
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
pin_ss = t.pin
if t.com=="request" then return request()end
if t.com=="init" then return init()end
if t.com=="anticoll" then return anticoll()end
end
