-- file.lua - VFS helper library
local sys = require('lib/sys.lua')
local _F = {}

function _F.open(uri, options) return sys.call(':vfs',    ':open',  uri, options) end
function _F.close(fh)          return sys.call(fh.fs_pid, ':close', fh)           end
function _F.read(fh, length)   return sys.call(fh.fs_pid, ':read',  fh, length)   end
function _F.write(fh, buffer)  return sys.call(fh.fs_pid, ':write', fh, buffer)   end

return _F
