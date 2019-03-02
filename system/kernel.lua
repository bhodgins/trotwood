
--[[
________________________________       _______________________
___  __/__  __ \_  __ \__  __/_ |     / /_  __ \_  __ \__  __ \
__  /  __  /_/ /  / / /_  /  __ | /| / /_  / / /  / / /_  / / /
_  /   _  _, _// /_/ /_  /   __ |/ |/ / / /_/ // /_/ /_  /_/ /
/_/    /_/ |_| \____/ /_/    ____/|__/  \____/ \____/ /_____/

]]

local sys = require '/lib/sys.lua'

if cprint == nil then cprint = function() end end	-- OC compat
if print  ~= nil then cprint = print end         	-- Testing outside of OC
if computer == nil then computer = { pullSignal = function() end } end
local yield = coroutine.yield -- shorthand

-- Host detection
local _SYSTEM = component and "OpenComputers"                   or
                string.match(_HOST      or "", "ComputerCraft") or
                "UNKNOWN"

-- SCHEDULER --

local scheduler = {}

--[[ create_environment :: Returns a new enviroment sandbox for new actors:
type:       Internal
params:     nil
returns:    senvironment:table ]]
local function create_environment()
  return {
    os          = os,               table			  = table,
    math			  = math,             spawn       = yc_spawn,
    coroutine	  = coroutine,        cprint		  = cprint,
    callback    = callback,         component   = component,
    self        = 0,                require     = require,
  }
end

--[[ find_pid :: Finds an available PID
type:       Internal
params:     state:table
returns:    pid:number ]]
local function find_pid(state)
  if next(state.free_pids) ~= nil then -- Check released PIDs first
    return ':ok', table.remove(state.free_pids, 1)
  end
  -- Return a new PID, if the cap is not met:
  if state.pid_max == state.last_new_pid then return ':error', sys.errstr(sys.E_SCH_NOPIDS) end
  return ':ok', state.last_new_pid + 1
end

local function co_handle_resume(state, pid, co_result, ...)
  yield_call = table.pack(...)
  cprint(...)
  -- TODO
end

-- PUBLIC CALLS --

--[[ build :: Builds and returns a new scheduler state table
type:       External
params:     pid_max:number
returns:    scheduler:table ]]
function scheduler.build(pid_max)
  return {
    actors          = {},
    ready           = {},
    free_pids       = {},
    last_new_pid    = 0,
    pid_max         = pid_max or 1000,
    subscribers     = {},
  }
end

--[[ enqueue :: Readies an actor for processing
type:       External
params:     state:table, pid:number
returns:    nil ]]
function scheduler.enqueue(state, pid)
  if state.actors[pid] == nil then return ':error', E_SCH_PIDNOEXIST end
  table.insert(state.ready, pid)
  return ':ok'
end

--[[ spawn :: Spawns a new actor
type:       External
params:     state:table, code:string
returns:    ok:string, pid:number ]]
function scheduler.spawn(state, code)
  ok, pid = find_pid(state)
  if ok == ':error' then return ok, pid end
  sandbox  = create_environment()
  sandbox.self = pid

  local chunk, errmsg = load(code, 'test', nil, sandbox)
  actor = { co = coroutine.create(chunk), inbox = {} }
  state.actors[pid] = actor
  scheduler.enqueue(state, pid)

  return ':ok', pid
end

--[[ dispatch :: dispatch an event to subscribed actors
type:       External
params:     state:table, event:table
returns:    nil ]]
function scheduler.dispatch(state, event)
  local ev_name = event[1]
  if state.subscribers[ev_name] == nil then return end

  for pid, placevalue in pairs(state.subscribers[ev_name]) do
      if type(placevalue) == 'function' then
        local status, result = pcall(placevalue())
        if status == true and result == true then
          scheduler.send(pid, ':' .. ev_name, table.unpack(event))
        end
      else scheduler.send(pid, ':' .. ev_name, table.unpack(event))
      end
  end
end

--[[ run :: Run the scheduler
type:       External
params:     state:table
returns:    nil ]]
function scheduler.run(state, recent_pid, ...)
  -- First: handle any coroutine that just ran:
  if recent_pid ~= nil then co_handle_resume(state, recent_pid, ...) end

  if not next(state.actors) then return ':error', sys.errstr(sys.E_SCH_NOACTORS) end
  scheduler.dispatch(state, table.pack(computer.pullSignal(0)) or {}) -- Dispatch incoming events

  -- Run the next available actor:
  if next(state.ready) then
    local pid = table.remove(state.ready, 1)
    local co  = state.actors[pid]['co']
    return scheduler.run(state, pid, coroutine.resume(co))
  end

  return scheduler.run(state)
end

-- AUTORUN --
if _G['SCHEDULER_NOAUTORUN'] == nil then
  local sched   = scheduler.build()
  scheduler.spawn(sched, _I)
  error, reason = scheduler.run(sched)
  if error == ':error' then cprint('Trotwood panic: ' .. scheduler.errstr(reason)) end
end

return scheduler
