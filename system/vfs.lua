-- vfs.lua - Virtual Filesystem for Trotwood
local cb  = require('lib/cb.lua')

local function split_uri(uri)

cb.map ':open' (function(state, pid, uri, options)
  -- TODO
end)

cb.map ':mount' (function(state, pid, namespace, pid) -- Map namespace to process PID
  -- TODO
end)

cb.map ':umount' (function(state, pid, namespace)
  -- TODO
end)

cb.map ':bind' (function(state, pid, uri)
  -- TODO
end)

cb.map ':ubind' (function(state, pid, namespace)
  -- TODO
end)


-- INIT:
local state = {
  mount = {},
  fh    = {},
}

while true do cb.handle( cb.next(state) ) end
