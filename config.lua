-- file: config.lua
local module = {}

module.WIFI = {{ ssid = "myWifi", pwd = "12345678ABCDEF" }}

module.HOST = "broker.example.com"
module.PORT = 1883
module.ID = node.chipid()

module.ENDPOINT = "ikea-ansluta-bridge/"

return module
