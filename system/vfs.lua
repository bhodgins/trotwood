local cb  = require('lib/cb.lua')

cb.map ':open' (function(state, pid, uri, options)
  -- TODO
end)

cb.map ':close' (function(state, pid, fh)
  if fh.state ~= ':open' then return ':error' end
  -- TODO
end)

cb.map ':read' (function(state, pid, fh, length)
  if fh.state ~= ':open' then return ':error' end
  -- TODO
end)

cb.map ':write' (function(state, pid, fh, buffer)
  if fh/state ~= ':open' then return ':error' end
  -- TODO
end)

cb.map ':mount' (function(state, pid, namespace, pid) -- Map namespace to process PID
  -- TODO
end)

cb.map ':umount' (function(state, pid, namespace)
  -- TODO
end)

cb.map ':bind' (function(state, pid, uri))

-- INIT:
local state = {
  mount = {},
  fh    = {},
}

while true do cb.handle( cb.next(state) ) end
