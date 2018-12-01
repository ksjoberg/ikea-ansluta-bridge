local module = {}

module.on_command = nil

local SPI_CS = 8
local CCPIN_RXRDY = 1 -- Originally 6 (MISO), but hardwire-mapped to 1 
                      -- because NodeMCU can't read a pin assigned to the SPI hardware
local CCPIN_CHIPRDY = 2

local delayB = 20000
local delayC = 10
local delayE = 200

local CC2500_SIDLE   = 0x36      -- Exit RX / TX
local CC2500_STX     = 0x35      -- Enable TX. If in RX state, only enable TX if CCA passes
local CC2500_SFTX    = 0x3B      -- Flush the TX FIFO buffer. Only issue SFTX in IDLE or TXFIFO_UNDERFLOW states
local CC2500_SRES    = 0x30      -- Reset chip
local CC2500_FIFO    = 0x3F      -- TX and RX FIFO
local CC2500_SRX     = 0x34      -- Enable RX. Perform calibration if enabled
local CC2500_SFRX    = 0x3A      -- Flush the RX FIFO buffer. Only issue SFRX in IDLE or RXFIFO_OVERFLOW states

local Light_OFF      = 0x01      -- Command to turn the light off
local Light_ON_50    = 0x02      -- Command to turn the light on 50%
local Light_ON_100   = 0x03      -- Command to turn the light on 100%
local Light_PAIR     = 0xFF      -- Command to pair a remote to the light

local cc2500_reg = {
    REG_IOCFG2           = 0x0000,
    REG_IOCFG1           = 0x0001,
    REG_IOCFG0           = 0x0002,
    REG_FIFOTHR          = 0x0003,
    REG_SYNC1            = 0x0004,
    REG_SYNC0            = 0x0005,
    REG_PKTLEN           = 0x0006,
    REG_PKTCTRL1         = 0x0007,
    REG_PKTCTRL0         = 0x0008,
    REG_ADDR             = 0x0009,
    REG_CHANNR           = 0x000A,
    REG_FSCTRL1          = 0x000B,
    REG_FSCTRL0          = 0x000C,
    REG_FREQ2            = 0x000D,
    REG_FREQ1            = 0x000E,
    REG_FREQ0            = 0x000F,
    REG_MDMCFG4          = 0x0010,
    REG_MDMCFG3          = 0x0011,
    REG_MDMCFG2          = 0x0012,
    REG_MDMCFG1          = 0x0013,
    REG_MDMCFG0          = 0x0014,
    REG_DEVIATN          = 0x0015,
    REG_MCSM2            = 0x0016,
    REG_MCSM1            = 0x0017,
    REG_MCSM0            = 0x0018,
    REG_FOCCFG           = 0x0019,
    REG_BSCFG            = 0x001A,
    REG_AGCCTRL2         = 0x001B,
    REG_AGCCTRL1         = 0x001C,
    REG_AGCCTRL0         = 0x001D,
    REG_WOREVT1          = 0x001E,
    REG_WOREVT0          = 0x001F,
    REG_WORCTRL          = 0x0020,
    REG_FREND1           = 0x0021,
    REG_FREND0           = 0x0022,
    REG_FSCAL3           = 0x0023,
    REG_FSCAL2           = 0x0024,
    REG_FSCAL1           = 0x0025,
    REG_FSCAL0           = 0x0026,
    REG_RCCTRL1          = 0x0027,
    REG_RCCTRL0          = 0x0028,
    REG_FSTEST           = 0x0029,
    REG_PTEST            = 0x002A,
    REG_AGCTEST          = 0x002B,
    REG_TEST2            = 0x002C,
    REG_TEST1            = 0x002D,
    REG_TEST0            = 0x002E,
    REG_PARTNUM          = 0x0030,
    REG_VERSION          = 0x0031,
    REG_FREQEST          = 0x0032,
    REG_LQI              = 0x0033,
    REG_RSSI             = 0x0034,
    REG_MARCSTATE        = 0x0035,
    REG_WORTIME1         = 0x0036,
    REG_WORTIME0         = 0x0037,
    REG_PKTSTATUS        = 0x0038,
    REG_VCO_VC_DAC       = 0x0039,
    REG_TXBYTES          = 0x003A,
    REG_RXBYTES          = 0x003B,
    REG_RCCTRL1_STATUS   = 0x003C,
    REG_RCCTRL0_STATUS   = 0x003D,
    REG_DAFUQ            = 0x007E
}
local cc2500_cfg = {
    REG_IOCFG2 = 0x01, -- GDO2: RX Ready
    REG_IOCFG1 = 0x2E, -- Tristate (default)
    REG_IOCFG0 = 0x29, -- GDO0 CHIP_RDYn 
    REG_PKTLEN = 0xFF,
    REG_PKTCTRL1 = 0x04,
    REG_PKTCTRL0 = 0x05,
    REG_ADDR = 0x01,
    REG_CHANNR = 0x10,
    REG_FSCTRL1 = 0x09,
    REG_FSCTRL0 = 0x00,
    REG_FREQ2 = 0x5D,
    REG_FREQ1 = 0x93,
    REG_FREQ0 = 0xB1,
    REG_MDMCFG4 = 0x2D,
    REG_MDMCFG3 = 0x3B,
    REG_MDMCFG2 = 0x73, -- MSK, No Manchester
    REG_MDMCFG1 = 0xA2,
    REG_MDMCFG0 = 0xF8,
    REG_DEVIATN = 0x01,
    REG_MCSM2 = 0x07,
    REG_MCSM1 = 0x30,
    REG_MCSM0 = 0x18,
    REG_FOCCFG = 0x1D,
    REG_BSCFG = 0x1C,
    REG_AGCCTRL2 = 0xC7,
    REG_AGCCTRL1 = 0x00,
    REG_AGCCTRL0 = 0xB2,
    REG_WOREVT1 = 0x87,
    REG_WOREVT0 = 0x6B,
    REG_WORCTRL = 0xF8,
    REG_FREND1 = 0xB6,
    REG_FREND0 = 0x10,
    REG_FSCAL3 = 0xEA,
    REG_FSCAL2 = 0x0A,
    REG_FSCAL1 = 0x00,
    REG_FSCAL0 = 0x11,
    REG_RCCTRL1 = 0x41,
    REG_RCCTRL0 = 0x00,
    REG_FSTEST = 0x59,
    REG_TEST2 = 0x88,
    REG_TEST1 = 0x31,
    REG_TEST0 = 0x0B,
    REG_DAFUQ = 0xFF }

-- Forward declaration of ReadPacket
local ReadPacket

local function On_RxReady()
    ReadPacket()
end

local function ChipSelect(on)
    if on then
        gpio.write(SPI_CS, gpio.LOW)
        repeat
        until gpio.read(CCPIN_CHIPRDY) == 0
    else
        repeat
        until gpio.read(CCPIN_CHIPRDY) == 0
        
        gpio.write(SPI_CS, gpio.HIGH)
    end
end

local function SendStrobe(val)
    ChipSelect(true)
    spi.send(1, val)
    ChipSelect(false)
    tmr.delay(delayB)
end

local function WriteReg(addr, val)
    ChipSelect(true)
    spi.send(1, addr)
    tmr.delay(delayE)
    spi.send(1, val)

    ChipSelect(false)
end

local function ReadReg(addr)
    ChipSelect(true)
    --WaitForMisoLow()
    wrote, status = spi.send(1, addr + 0x80)
    --print(string.format('%02X', status))
    tmr.delay(delayE)
    local r = spi.recv(1, 1)

    ChipSelect(false)
    return r
end

local function ReadAllRxData()
    ChipSelect(true)

    _, status = spi.send(1, CC2500_FIFO + 0x80 + 0x40) -- Burst
    local rxBytes = bit.band(status, 0x0F)
    
    tmr.delay(delayE)
    local r = ""
    if rxBytes > 0 then
        r = spi.recv(1, rxBytes)
    end
    ChipSelect(false)
    return r
end

ReadPacket = function()
    local packet = ReadAllRxData()
--    print(encoder.toHex(packet))
    
    if packet:len() == 9 then
        if packet:byte(1) == 0x06 and packet:byte(2) == 0x55 and packet:byte(7) == 0xaa then
            -- Valid framing
            local address = bit.lshift(packet:byte(4),8) + packet:byte(5)
            local cmd = packet:byte(6)
            
            if not (module.on_command == nil) then
                module.on_command(address, cmd)
            else
                print(string.format('%04X %02X', address, cmd))
            end
        end
    end
    
    SendStrobe(CC2500_SIDLE)      -- Needed to flush RX FIFO
    SendStrobe(CC2500_SFRX)       -- Flush RX FIFO
    
    SendStrobe(CC2500_SRX)
end


local function init_cc2500()
    local reg
    local value
    for reg, value in pairs(cc2500_cfg) do
        WriteReg(cc2500_reg[reg], value)
    end
end


function module.SendCommand(address, command)
    for i = 0, 10 do
        SendStrobe(CC2500_SIDLE)   -- 0x36 SIDLE Exit RX / TX, turn off frequency synthesizer and exit Wake-On-Radio mode if applicable.
        SendStrobe(CC2500_SFTX)    -- 0x3B SFTX Flush the TX FIFO buffer. Only issue SFTX in IDLE or TXFIFO_UNDERFLOW states.

        ChipSelect(true)
        --WaitForMisoLow()
        spi.send(1, 0x7F)
        spi.send(1, 0x06)
        spi.send(1, 0x55)
        spi.send(1, 0x01)
        spi.send(1, bit.rshift(address, 8))
        spi.send(1, bit.band(address, 0xFF))
        spi.send(1, command)
        spi.send(1, 0xAA)
        spi.send(1, 0xFF)
        ChipSelect(false)
        SendStrobe(CC2500_STX)
        tmr.delay(delayC)
    end
    -- Re-enter RX mode
    SendStrobe(CC2500_SRX)
end

function module.start()
    -- SPI MODE 0 (CPOL=0, CPHA=0)
    -- Divisor = 16 = 80MHz / 16 = 5MHz SPI clock
    spi.setup(1, spi.MASTER, spi.CPOL_LOW, spi.CPHA_LOW, 8, 16, spi.FULLDUPLEX)
    gpio.mode(CCPIN_RXRDY, gpio.INPUT, gpio.PULLUP)
    -- Put CS under manual control
    gpio.mode(SPI_CS, gpio.OUTPUT)
    ChipSelect(false)
    tmr.delay(30)
    ChipSelect(true)
    tmr.delay(30)
    ChipSelect(false)
    tmr.delay(45)
    
    
    SendStrobe(CC2500_SRES)
    init_cc2500()
    WriteReg(0x3E, 0xFF)  --Maximum transmit power - write 0xFF to 0x3E (PATABLE)

    SendStrobe(CC2500_SIDLE)      -- Needed to flush RX FIFO
    SendStrobe(CC2500_SFRX)       -- Flush RX FIFO
    
    SendStrobe(CC2500_SRX)
    gpio.trig(CCPIN_RXRDY, 'up', On_RxReady) -- Enable RX trigger
end

return module
