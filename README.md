# RC522

Physical Access Control System. ESP8266 MFRC522 RFID-Reader

The plugin for [DoT](https://github.com/bondrogeen/DoT)

or run manually

```lua

RC522={
  run=true,
  pin_ss = 0,
  time = 500,
  pin_relay =1,
  del_relay =1000,
  pin_buz = 2,
  pin_btn = 4  
}

pause=0
spi.setup(1, spi.MASTER, spi.CPOL_LOW, spi.CPHA_LOW, spi.DATABITS_8, 0)
print(dofile("RC522_SPI.lua")({init=true,pin=RC522.pin_ss}))
print(dofile("RC522_dev.lua")({init=true}))
  
RC522.timer = tmr.create()
RC522.timer:register(1000, tmr.ALARM_AUTO, function()
 local isTagNear, cardType = dofile("RC522_SPI.lua")({request=true,pin=RC522.pin_ss})
 if pause~=0 then pause=pause-1 end
 if isTagNear and pause==0 then
  RC522.timer:stop()
  local serialNo = dofile("RC522_SPI.lua")({anticoll=true,pin=RC522.pin_ss})   
  print(serialNo)
  if serialNo then 
   if RC522.mode=="add"then 
    print(dofile("RC522_key.lua")({add=serialNo})) 
    dofile("RC522_dev.lua")({buz=300})
   end
   if not RC522.mode or RC522.mode=="auth"then 
    pause=10
    local access = dofile("RC522_key.lua")({auth=serialNo})
    print(type (access)) 
    dofile("RC522_dev.lua")({relay=access})
   end
   if RC522.mode=="del"then 
    print(dofile("RC522_key.lua")({del=serialNo})) 
    dofile("RC522_dev.lua")({buz=300})
   end
  end
  RC522.timer:start()
 end
end)
RC522.timer:interval(500)
RC522.timer:start()

```

## Pin connection

![Pin](https://raw.githubusercontent.com/bondrogeen/RC522/master/scheme/esp8266.JPG)

## Screenshot DoT

![Screenshot](https://raw.githubusercontent.com/bondrogeen/RC522/master/doc/images/Screenshot.jpg)

## Changelog

### 0.0.3 (2018-05-02)
* (bondrogeen) Test version.
### 0.0.1 (2018-04-04)
* (bondrogeen) init.