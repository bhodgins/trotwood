--[[ system/core.lua :: Trotwood core
________________________________       _______________________
___  __/__  __ \_  __ \__  __/_ |     / /_  __ \_  __ \__  __ \
__  /  __  /_/ /  / / /_  /  __ | /| / /_  / / /  / / /_  / / /
_  /   _  _, _// /_/ /_  /   __ |/ |/ / / /_/ // /_/ /_  /_/ /
/_/    /_/ |_| \____/ /_/    ____/|__/  \____/ \____/ /_____/

Please read LICENSE in the root repository directory before editing.

THIS FILE REQUIRES FILEIO STUBS IN ORDER TO BOOTSTRAP TROTWOOD.
]]

local _C = {}

local PID_MAX = 1000
local _SYSTEM = component and "OpenComputers"                   or
                string.match(_HOST      or "", "ComputerCraft") or
                "UNKNOWN"

-- Compat:
if cprint == nil then cprint = function() end end	-- OC compat
if print  ~= nil then cprint = print end         	-- Testing outside of OC
if computer == nil then computer = { pullSignal = function() end } end
local yield = coroutine.yield -- shorthand


-- some external files we need:
local scheduler = stub.require('system://scheduler')
local sys       = stub.require('lib://sys')

-- Environment modifications --

--[[ table.byval :: Performs a deep copy of a table
type:       Internal
params:     tbl:table
returns:    tbl:table ]]
table.byval = function(tbl)

end

-- Core functions --

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
    _SELF       = 0,                require     = require,
    _SYSTEM     = _SYSTEM,          string      = string,
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

--[[ spawn :: Spawns a new actor
type:       External
params:     state:table, code:string
returns:    ok:string, pid:number ]]
function _C.spawn(state, code)
  ok, pid = find_pid(state)
  if ok == ':error' then return ok, pid end
  sandbox  = create_environment()
  for k, _ in pairs(sandbox) do print(k) end
  print("spawning pid " .. pid)
  sandbox._SELF = pid

  local chunk, errmsg = load(code, 'test', nil, sandbox)
  actor = coroutine.create(chunk) -- Note: Inboxes have been moved to the scheduler
  state.actors[pid] = actor
  scheduler.enqueue(state.sched, pid)

  return ':ok', pid
end

--[[ co_handle_resume :: Splits off and handles coroutine and actor yield calls
type:       Internal
params:     state:table, sched:table, recent_pid:number, co_status:boolean,
  ...:list
returns:    state:table ]]
local function co_handle_resume(state, sched, recent_pid, co_status, ...)
  if co_status == false then
    print("actor with pid " .. recent_pid .. " has crashed! error message:")
    print(...)
  end
end

--[[ build :: Build the core
type:       External
params:     nil
returns:    state:table ]]
function _C.build(max_pid)
  max_pid = pid_max or PID_MAX
  return {
    free_pids       = {},
    actors          = {},
    last_new_pid    = 0,
    pid_max         = max_pid,
    sched           = scheduler.build()
  }
end

--[[ _run :: Run the core
type:       Internal
params:     state:table, sched:scheduler, recent_pid:number, ...:any
returns:    nil ]]
local function _run(state, sched, recent_pid, ...)
  if _SYSTEM ~= "UNKNOWN" then yield() end

  -- First: handle any coroutine that just ran:
  if recent_pid ~= nil then co_handle_resume(state, sched, recent_pid, ...) end

  if not next(state.actors) then return ':error', sys.E_CORE_NOACTORS end
  local event = stub.get_event()
  if event ~= nil then scheduler.pub(sched, event) end

  -- Run the next available actor:
  local pid, events = table.unpack(scheduler.next_actor(sched))
  if pid then
    return _run(state, sched, pid, coroutine.resume(state.actors[pid], event))
  end

  return _run(state, sched)
end

--[[ run :: Run the core
type:       External
params:     state:table
returns:    nil ]]
function _C.run(state, sched, recent_pid, ...)
  local state = state or _C.build(1000)
  return _run(state, state.sched)
end

return _C
