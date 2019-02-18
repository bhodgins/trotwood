-- init.lua - OCFS boot compatability for Trotwood

local ocfs = component.proxy(computer.getBootAddress())

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

--[[ require :: requires a Lua source file
type:       Implied
params:     file:string
returns:    any ]]
function require(file)
  local fh      = ocfs.open(file)
  local content = slurp(fh, "")
  local chunk = load(content, file)
  local result, err = pcall(chunk)

  if result == false then error(err) return nil end

  return result
end

local kernel = require('system/kernel.lua')

while true do
  coroutine.yield()
end

--[[

local ocfs_disk_ns = 'ocfs|' .. ocfs_disk_uuid
send(vfs, -1, ':mount', ocfs_disk_ns, ocfs_pid)

-- OCFS is not namespace friendly, so we must bind file:// to namespaces
send(vfs, -1, ':bind', 'system', ocfs_disk_ns .. ':///system/$u')
send(vfs, -1, ':bind', 'boot', ocfs_disk_ns .. ':///boot/$u')
send(vfs, -1, ':bind', 'lib', ocfs_disk_ns .. ':///lib/$u')

--]]
