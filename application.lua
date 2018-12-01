-- file : application.lua
local module = {}
m = nil

-- Sends a simple ping to the broker
local function send_ping()
    m:publish(config.ENDPOINT .. "ping","id=" .. config.ID,0,0)
end

-- Sends my id to the broker for registration
local function register_myself()
    m:subscribe(config.ENDPOINT .. config.ID .. "/+/set",0,function(conn)
        print("Successfully subscribed to data endpoint")
    end)
end

local function mqtt_handle_error(client, reason)
    -- In reality, the connected function should do something useful!
    -- https://nodemcu.readthedocs.io/en/master/en/modules/mqtt/#connection-failure-callback-reason-codes

    tmr.create():alarm(10 * 1000, tmr.ALARM_SINGLE, mqtt_connect)
end

local function mqtt_connect()
    -- Connect to broker
    m:connect(config.HOST, config.PORT, 0, 0, function(con)
        register_myself()
        -- And then pings each 60*1000 milliseconds
        tmr.stop(6)
        tmr.alarm(6, 60*1000, 1, send_ping)
    end, mqtt_handle_error)
end

local function mqtt_start()
    m = mqtt.Client(config.ID, 120)
    -- register message callback beforehand
    m:on("message", function(conn, topic, data) 
        if data ~= nil then
            print(topic .. ": " .. data)
            local saddr = string.match(topic, "/" .. config.ID .. "/(%x+)/set")
            
            local addr = tonumber(saddr, 16)
            local dimlevel = tonumber(data, 10)

            if dimlevel > 74 then
                radio.SendCommand(addr, 3)  -- 100%
            elseif dimlevel > 24 then
                radio.SendCommand(addr, 2)  -- 50%
            elseif dimlevel > -1 then
                radio.SendCommand(addr, 1)  -- OFF
            else
                radio.SendCommand(addr, 0xFF) -- Learn
            end
        end
    end)
    mqtt_connect()
end

function module.start()
  mqtt_start()

  radio.start()
  radio.on_command = function(addr, cmd)
    local dimlevel = 0
    if (cmd == 2) then
        dimlevel = 50
    elseif (cmd == 3) then
        dimlevel = 100
    elseif (cmd == 0xFF) then
        return
    end

    m:publish(config.ENDPOINT .. config.ID .. string.format('/%04X/current', addr),
        string.format('%d', dimlevel), 0, 0)
  end
end

return module
