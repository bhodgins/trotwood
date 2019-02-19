local _SYS = {}

_SYS.HOST_OC    = "OpenComputers"
_SYS.HOST_CC    = "ComputerCraft"
_SYS.HOST_OTHER = "UNKNOWN"

--[[
Yield calls provide a means to communicate with the scheduler without having
access to the scheduler's environment directly. It also helps ensure that
any program that does anything 'useful' is less likely to block execution of
other actors. There are only 7 primitive yield calls: quit(), send(), recv(),
wake(), sub(), unsub(), and spawn():

quit(): nil :: Decomposes an actor
send(pid:number, ...): nil :: Sends a message to an actor
recv(): ... :: Receives a message rom an actor
wake(pid:number): nil :: Wakes up an actor.
sub(event:string, filter:function) :: Subscribe to an event, filter optional
unsub(event:string) :: Unsubscribes from an event
]]

_SYS.YC_QUIT = 100
_SYS.YC_SEND = 110
_SYS.YC_WUP  = 120
_SYS.YC_RECV = 130
_SYS.YC_SPWN = 140
_SYS.YC_SUB  = 150
_SYS.YC_USUB = 160

function _SYS.quit()                  yield(_SYS.YC_QUIT)                   end
function _SYS.send(pid, ...)          yield(_SYS.YC_SEND, pid, ...)         end
function _SYS.wake(pid)               yield(_SYS.YC_WUP,  pid)              end
function _SYS.recv()                  yield(_SYS.YC_RECV)                   end
function _SYS.sub(event)              yield(_SYS.YC_SUB, event, fn)         end
function _SYS.unsub(event)            yield(_SYS.YC_USUB, event)            end
function _SYS.spawn(code, sopts, ...) yield(_SYS.YC_SPWN, code, sopts, ...) end

-- ERRORS --

_SYS.E_SCH_PIDNOEXIST = 100
_SYS.E_SCH_NOACTORS   = 110
_SYS.E_SCH_NOPIDS     = 120

--[[ errstr :: Returns an error string for the specified error number
type:       External
params:     error number:number
returns:    error string:string ]]
function _SYS.errstr(e)
  return ({
  'No such PID',
  'All actors have halted',
  'PID count exhausted',
})[(e / 10) - 9]
end

return _SYS
