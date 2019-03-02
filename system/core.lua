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
local scheduler = fiostub.require('system://scheduler')
local sys       = fiostub.require('lib://sys')

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
  return table.byval({
    os          = os,               table			  = table,
    math			  = math,             spawn       = yc_spawn,
    coroutine	  = coroutine,        cprint		  = cprint,
    callback    = callback,         component   = component,
    self        = 0,                require     = require,
  })
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

--[[ enqueue :: Readies an actor for processing
type:       External
params:     state:table, pid:number
returns:    nil ]]
function scheduler.enqueue(state, pid)
  if state.actors[pid] == nil then return ':error', sys.E_CORE_PIDNOEXIST end
  table.insert(state.ready, pid)
  return ':ok'
end

--[[ spawn :: Spawns a new actor
type:       External
params:     state:table, code:string
returns:    ok:string, pid:number ]]
function spawn(state, code)
  ok, pid = find_pid(state)
  if ok == ':error' then return ok, pid end
  sandbox  = create_environment()
  sandbox.self = pid

  local chunk, errmsg = load(code, 'test', nil, sandbox)
  actor = { co = coroutine.create(chunk), inbox = {} }
  state.actors[pid] = actor
  enqueue(state, pid)

  return ':ok', pid
end

--[[ co_handle_resume :: Splits off and handles coroutine and actor yield calls
type:       Internal
params:     state:table, sched:table, recent_pid:number, co_status:boolean,
  ...:list
returns:    state:table ]]
local function co_handle_resume(state, sched, recent_pid, co_status, ...)

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
  }
end

--[[ run :: Run the core
type:       External
params:     state:table
returns:    nil ]]
function _C.run(state, sched, recent_pid, ...)
  -- First: handle any coroutine that just ran:
  if recent_pid ~= nil then co_handle_resume(state, sched, recent_pid, ...) end

  if not next(state.actors) then return ':error', sys.E_CORE_NOACTORS end
  sched.dispatch(sched, table.pack(computer.pullSignal(0)) or {})

  -- Run the next available actor:
  local pid, event = sched.next_actor()
  if pid then
    local actor  = state.actors[pid]['co']
    return run(sched, sched, pid, coroutine.resume(actor, event))
  end

  return run(state, sched)
end
