-- file: init.lua

app = {}
config = {}

print('Type "abort = true" to abort startup.')
abort = false
tmr.alarm(0,5000,0,function()
	    if abort == true then
        	print('startup aborted')
        	return
        end
        
        app = require("application")
        config = require("config")
        setup = require("setup")
        radio = require("cc2500")

        setup.start()
    end)
