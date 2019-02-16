-- init.lua - OCFS boot compatability for Trotwood

local function send(co, ...)
  -- TODO
end

local function require()

while true do
  coroutine.yield()
end

local ocfs_disk_ns = 'ocfs|' .. ocfs_disk_uuid
send(vfs, -1, ':mount', ocfs_disk_ns, ocfs_pid)

-- OCFS is not namespace friendly, so we must bind file:// to namespaces
send(vfs, -1, ':bind', 'system', ocfs_disk_ns .. ':///system/$u')
send(vfs, -1, ':bind', 'boot', ocfs_disk_ns .. ':///boot/$u')
send(vfs, -1, ':bind', 'lib', ocfs_disk_ns .. ':///lib/$u')
