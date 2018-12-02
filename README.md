# IKEA Ansluta MQTT bridge
Control your IKEA Ansluta 12V transformers remotely.

This code impersonates an [IKEA Ansluta Remote](https://www.ikea.com/se/sv/catalog/products/90300773/).

Originally written by ksjoberg @ github in December 2018.

Runs on a NodeMCU build checked out on 1st December 2018, built by [nodemcu-build.com](https://nodemcu-build.com/) using the bit, file, GPIO, MQTT, net, node, SPI, timer, UART and WIFI modules.

## Wiring it up
I used a CC2500 breakout module from [ebay](https://www.ebay.co.uk/itm/CC2500-2-4GHz-Module-on-Breakout-Board-with-0-1-Header-Pins-UK-Stock-/262966744730) and hooked it up to a D1 Mini NodeMCU-compatible board, also [ebay](https://www.ebay.co.uk/itm/ESP8266-D1-Mini-Clone-WIFI-Dev-Kit-Development-Board-for-Arduino-ESP-NodeMCU-Lua/251863466044)

The SPI part of the wiring is already defined in the NodeMCU documentation. I decided to go for interrupt driven RX, so I wired GDO0 and GDO2 to the NodeMCU. This is the wiring table:

| Signal     | IO index | ESP8266 pin | CC2500 pin |
|------------|----------|-------------|------------|
| HSPI CLK   | 5        | GPIO14      | SCL        |
| HSPI /CS   | 8        | GPIO15      | CSn        |
| HSPI MOSI  | 7        | GPIO13      | MOSI       |
| HSPI MISO  | 6        | GPIO12      | MISO       |
| CHIP\_RDYn | 2        | GPIO4       | GDO2       |
| RX\_RDY    | 1        | GPIO5       | GDO0       |




## Usage
1. set up WiFi connection, MQTT topic etc. in config.lua
2. upload the respecive lua files to your device
3. run it; a restart will suffice since the `init.lua` launches it automatically. 
4. Subscribe to the `ikea-ansluta-bridge/+/+/current` topic to receive updates from the regular round remotes.
5. Publish to `ikea-ansluta-bridge/chipid/remoteid/set` with a message corresponding to your required dim level. Only three levels are supported by the transformers: 0%, 50% and 100%.  Replace `chipid` with your NodeMCU's Chip ID, and the `remoteid` with the Remote's ID that you want to send a message as.
6. If you want to attempt pairing, make up a Remote ID of your choice (16 bit hexadecimal value) and issue a dimming request setting the value to `-1`. (Untested)

