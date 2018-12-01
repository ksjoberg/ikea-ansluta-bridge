-- file: setup.lua
local module = {}

local function wifi_wait_ip()
  if wifi.sta.getip()== nil then
    print("IP unavailable, Waiting...")
  else
    tmr.stop(1)
    print("\n====================================")
    print("ESP8266 mode is: " .. wifi.getmode())
    print("MAC address is: " .. wifi.ap.getmac())
    print("IP is " .. wifi.sta.getip())
    print("====================================")
    app.start()
  end
end

local function wifi_start(list_aps)
    if list_aps then
        local found = false
        for _, station_cfg in pairs(config.WIFI) do
            for key,value in pairs(list_aps) do
                if station_cfg.ssid == key then
                    wifi.setmode(wifi.STATION);
                    wifi.sta.config(station_cfg)
                    wifi.sta.connect()
                    print("Connecting to " .. key .. " ...")
                    found = true
                    --config.SSID = nil  -- can save memory
                    tmr.alarm(1, 2500, 1, wifi_wait_ip)
                end
            end
        end
        if not found then
            print("Error: Failed to connect to WIFI, no matching config! Found these networks:")
            for key,value in pairs(list_aps) do
                print(" - " .. key)
            end
            print("I have configuration for these:")
            for _, station_cfg in pairs(config.WIFI) do
                print(" - " .. station_cfg.ssid)
            end
        end
    else
        print("Error getting AP list")
    end
end

function module.start()
  print("Configuring Wifi ...")
  wifi.setmode(wifi.STATION);
  wifi.sta.getap(wifi_start)
end

return module
