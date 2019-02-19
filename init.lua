-- init.lua - OCFS boot compatability for Trotwood

local ocfs = component.proxy(computer.getBootAddress())
SCHEDULER_NOAUTORUN = true

local function send(co, ...)
  -- TODO
end

--[[ slurp :: Loads an entire file into a string
type:       Internal
params:     fh:number, acc:string
returns:    file:string ]]
local function slurp(fh, acc)
  local content = ocfs.read(fh, 4096)
  if content ~= nil then return slurp(fh, acc .. content) end
  return acc
end

--[[ absorb :: slurp, but by filename
type:       Internal
params:     file:string
returns:    file:string ]]
local function absorb(file)
  local fh = ocfs.open(file)
  return slurp(fh, "")
end

--[[ require :: requires a Lua source file
type:       Implied
params:     file:string
returns:    any ]]
function require(file)
  local fh      = ocfs.open(file)
  local content = slurp(fh, "")
  local chunk, err = load(content, file)
  assert(chunk, err)

  return chunk()
end

local kernel = require('system/kernel.lua')

local kinstance = kernel.build()
local sysinit = absorb('system/sysinit.lua')
local ok, pid = kernel.spawn(kinstance, sysinit)

local ok, err = kernel.run(kinstance)
assert(ok == ':ok', err)

--[[

local ocfs_disk_ns = 'ocfs|' .. ocfs_disk_uuid
send(vfs, -1, ':mount', ocfs_disk_ns, ocfs_pid)

-- OCFS is not namespace friendly, so we must bind file:// to namespaces
send(vfs, -1, ':bind', 'system', ocfs_disk_ns .. ':///system/$u')
send(vfs, -1, ':bind', 'boot', ocfs_disk_ns .. ':///boot/$u')
send(vfs, -1, ':bind', 'lib', ocfs_disk_ns .. ':///lib/$u')

--]]
