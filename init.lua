-- init.lua - ootstrapper for Trotwood

yield = coroutine.yield -- shorthand

_SYSTEM = component and "OpenComputers" or
  string.match(_HOST or "", "ComputerCraft") or
  "UNKNOWN"

if _SYSTEM == "UNKNOWN" then stub = require('stub/standard') end
if _SYSTEM == "OpenComputers" then
  if _OSVERSION ~= nil then
    if string.find(_OSVERSION, "OpenOS") ~= nil then
      stub = require('stub/oc')
    end
  end
end

local core = stub.require('system://core')
local initial_state = core.build(1000)
core.spawn(initial_state, "while true do _cprint('Hello, World I am a new process, my pid is: ' .. _SELF .. ' and I am running on target system: ' .. _SYSTEM .. '!') coroutine.yield() end")
core.run(initial_state)
