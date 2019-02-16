
local function send(co, ...)
  -- TODO
end

while true do
  coroutine.yield()
end

send(vfs, -1, 'bind', 'system', 'file:///system/')
send(vfs, -1, 'bind', 'config', 'file:///config/')
send(vfs, -1, 'bind', 'lib',    'file:///lib/')
send(vfs, -1, 'bind', 'log',    'file:///log/')
