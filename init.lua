-- init.lua - ootstrapper for Trotwood

yield = coroutine.yield -- shorthand

_SYSTEM = component and "OpenComputers" or
  string.match(_HOST      or "", "ComputerCraft") or
  "UNKNOWN"

if _SYSTEM == "UNKNOWN" then stub = require('stub/standard') end

local core = stub.require('system://core')
local initial_state = core.build(1000)
core.spawn(initial_state, "while true do cprint('Hello, World I am a new process, my pid is: ' .. _SELF .. ' and I am running on target system: ' .. _SYSTEM .. '!') coroutine.yield() end")
core.run(initial_state)
