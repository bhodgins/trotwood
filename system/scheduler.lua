-- system/_S.lua :: Trotwood scheduler

local _S = {}
local sys       = fiostub.require('lib://sys')

--[[ handle_yieldcall :: Builds and returns a new _S state table
type:       Internal
params:     pid_max:number
returns:    _S:table ]]
local function handle_yieldcall(state, event)
  
end

--[[ sub :: Subscribes an actor to an event
type:       External
params:     pid:number, event_name:string
returns:    OK:string | ERROR:string, errno:number ]]
function _S.sub(state, pid, event_name)

end

--[[ unsub :: Ubsubscribes an actor from an event
type:       External
params:     pid:number, event:string
returns:    OK:string | ERROR:string, errno:number ]]
function _S.unsub(state, pid, event_name)

end

--[[ build :: Builds and returns a new _S state table
type:       External
params:     nil
returns:    _S:table ]]
function _S.build()
  return {
    ready           = {},
    subscribers     = {},
  }
end

--[[ next_actor :: Returns the next actor ready for processing
type:       External
params:     nil
returns:    actor:pid, event:list ]]
function _S.next_actor()

end

--[[ pub :: Publish an event to subscribed actors
type:       External
params:     state:table, event:table
returns:    nil ]]
function _S.pub(state, event)
  local ev_name = event[1]
  if ev_name:sub(1, 1) == ':' then return handle_yieldcall(state, event) end

  if state.subscribers[ev_name] == nil then return end

  for pid, placevalue in pairs(state.subscribers[ev_name]) do
      if type(placevalue) == 'function' then
        local status, result = pcall(placevalue())
        if status == true and result == true then
          _S.send(pid, ':' .. ev_name, table.unpack(event))
        end
      else _S.send(pid, ':' .. ev_name, table.unpack(event))
      end
  end
end

return _S
