-- system/_S.lua :: Trotwood scheduler

local sys       = stub.require('lib://sys')

--[[ enqueue :: Readies an actor for processing
params:     state:table, pid:number
returns:    nil ]]
local function enqueue(state, pid)
  table.insert(state.ready, {pid, {}})
  return ':ok'
end

--[[ handle_yieldcall :: Builds and returns a new _S state table
type:       Internal
params:     pid_max:number
returns:    _S:table ]]
local function handle_yieldcall(state, event)

end

--[[ sub :: Subscribes an actor to an event
params:     pid:number, event_name:string
returns:    OK:string | ERROR:string, errno:number ]]
local function sub(state, pid, event_name)
  ev = state.subscribers[event_name]
  if ev ~= nil then return ':ok', table.insert(ev, pid) end
  state.subscribers[event_name] = { pid }
  return ':ok'
end

--[[ unsub :: Ubsubscribes an actor from an event
params:     pid:number, event:string
returns:    OK:string | ERROR:string, errno:number ]]
local function unsub(state, pid, event_name, _acc)
  local ev = state.subscribers[event_name]
  if ev == nil then return ':error' end
  
  local ev = fnutil.filter(ev, function(sub_pid)if sub_pid ~= pid then return true end end)
  return ':ok'
end

--[[ build :: Builds and returns a new _S state table
params:     nil
returns:    _S:table ]]
local function build()
  return {
    ready           = {},
    subscribers     = {},
  }
end

--[[ next_actor :: Returns the next actor ready for processing
params:     nil
returns:    actor:pid, event:list ]]
local function next_actor(state)
  local _a = table.remove(state.ready, 1)
  if _a == nil then return {nil, nil} end
  return _a
end

--[[ pub :: Publish an event to subscribed actors
params:     state:table, event:table
returns:    nil ]]
local function pub(state, event)
  local ev_name = event[1]
  -- if ev_name:sub(1, 1) == ':' then return handle_yieldcall(state, event) end

  if state.subscribers[ev_name] == nil then return end

  for pid, _ in pairs(state.subscribers[ev_name]) do
    local i = find_index(state.ready, function(e) return e[1] == pid end)

    -- Just throw it on if the actor isn't already ready:
    if i == nil then table.insert(state.ready, {pid, {event}}) end

    -- Actor is already in a ready state, append to event queue:
    table.insert(state.ready[i][2], event)
  end
end

return {
  pub         = pub,
  next_actor  = next_actor,
  build       = build,
  unsub       = unsub,
  sub         = sub,
  enqueue     = enqueue,
}
