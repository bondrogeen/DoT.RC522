
local function buz(t)
 gpio.write(_RC522.pin_buz,gpio.HIGH)
 local mytimer=tmr.create()
 mytimer:register(t or 1000,tmr.ALARM_SINGLE,function(t)
  gpio.write(_RC522.pin_buz, gpio.LOW)
  t:unregister()
  end)
 mytimer:start()
 return true
end

local function relay(d)
 if d=="true" then
 buz()
 gpio.write(_RC522.pin_relay,gpio.HIGH)
 local mytimer=tmr.create()
 mytimer:register(_RC522.del_relay,tmr.ALARM_SINGLE,function(t)
  gpio.write(_RC522.pin_relay,gpio.LOW)
  t:unregister()
 end)
 mytimer:start()
 else
 buz(300)
 end
 return true
end

local function init()
 gpio.mode(_RC522.pin_buz,gpio.OUTPUT)
 gpio.mode(_RC522.pin_relay,gpio.OUTPUT)
 gpio.mode(_RC522.pin_btn,gpio.INT,gpio.PULLUP)
 function set0(level)
  tmr.delay(50000)
  dofile("RC522_dev.lua")({relay="true"})
  print("pin2 "..level)
 end
 gpio.trig(_RC522.pin_btn,"down",set0)
end

return function (t)
 local r
 if t.init then r=init() end
 if t.buz then r=buz(t.buz) end
 if t.relay then r=relay(t.relay) end
 return tostring (r)
end
