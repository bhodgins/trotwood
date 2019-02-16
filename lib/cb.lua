-- lib/cb.lua - Callback library for Trotwood
local sys = require('lib/sys.lua')
local _C  = {}

--[[ map :: Maps a callback to a function call
type:       Internal
params:     state:table
returns:    pid:number ]]
function _C.map(state)
  -- TODO
end

--[[ handle :: Dispatches a callback given a callback request message
type:       Internal
params:     state:table, callback:list
returns:    state:table ]]
function _C.handle(state, callback)
  -- TODO
end

--[[ next :: Yields and waits for the next message
type:       Internal
params:     Nil
returns:    callback_id:string, params:list | Nil, msg:string ]]
function _C.next()
  local msg = sys.recv()

  -- TODO
end

return _C
