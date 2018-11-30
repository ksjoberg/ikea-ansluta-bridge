--init.lua
function startup()
    if abort == true then
        print('startup aborted')
        return
    end
    wifi.setmode(wifi.STATION)
    station_cfg={}
    station_cfg.ssid="myWifi"
    station_cfg.pwd="12345678ABCDEF"
    station_cfg.save=false
    wifi.sta.config(station_cfg)
    wifi.sta.connect()
    tmr.alarm(1, 1000, 1, function()
        if wifi.sta.getip() == nil then
            print("IP unavailable, waiting...")
        else
            tmr.stop(1)
            print("IP is "..wifi.sta.getip())
            dofile ("main.lua")
        end
    end)
end

print('Type "abort = true" to abort startup.')
abort = false
tmr.alarm(0,5000,0,startup)