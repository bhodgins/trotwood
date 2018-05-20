if cprint == nil then cprint = function() end end	-- OC compat
if print  ~= nil then cprint = print end         	-- Testing outside of OC
if computer == nil then computer = { pullSignal = function() end } end

local callback = {} -- Forward declare for callback routines

-- Scheduler --

local scheduler = function()
	local self    = {}
	local outbox  = {}
	local actors  = {}
	local ready   = {}

	-- PID tracking:
	local free_pids		= {}
	local pid_cap		= 0
	local current 		= nil
	local process_max	= 1000

	-- Returns an avilable PID either from existing available ones or new
	-- ones by lifting the PID cap:
	local function _find_pid()
		local next_pid = 0

		if #free_pids == 0 then
			-- No PIDs available, let's make one:
			table.insert(free_pids, pid_cap + 1)
		end

		next_pid = table.remove(free_pids, 1)
		return next_pid / process_max
	end

	local function _run()
		local ev = computer.pullSignal(0)

		if not next(actors) then
			cprint "Kernel panic: No more actors!"
			return
		end

		if next(ready) then
			current = table.remove(ready, 1)
			local co = actors[current]
			local status, errmsg = coroutine.resume(co, self)
			if status == false then
				cprint(errmsg)
			end

			-- Check up on the coroutine's status:
			if coroutine.status(co) == 'dead' then
				cprint("Process " .. current .. " quit unexpectedly (hanged up)")

				-- Clean up:
				table.insert(free_pids, current) -- PID is now free
				actors[current] = nil

				-- TODO: Send an event that the process quit
			end
		end

		return _run()
	end

	-- Public facing functions:

	function self.self() return current end

	function self.enqueue(pid)
		if actors[pid] ~= nil then
			table.insert(ready, pid)
			return ':ok'
		end

		cprint("Can't enqueue pid " .. pid .. ": No such pid")
		return ':error'
	end

	function self.send(pid, message)
		if actors[pid] ~= nil then
			table.insert(outbox[pid], message)
			return ':ok'
		end

		cprint("Can't send message to pid " .. pid .. ": No such pid")
		return ':error'
	end

	-- Returns the current number of messages in actors' mailbox
	function self.inbox() return #outbox[current] end

	-- Peeks at the top message in the queue:
	function self.mailpeek()
		if #outbox ~= 0 then return outbox[current][1] else nil end
	end

	function self.recv()
		if self.inbox() ~= 0 then
			return ':ok', table.remove(outbox[current], 1)
		end

		cprint("Can't receive message in pid " .. pid .. ": Empty outbox")
		return ':error'
	end

	function self.spawn(fn)
		local co = coroutine.create(fn)

		local new_pid = _find_pid() -- Process needs a new PID
		actors[new_pid] = co
		return ':ok', new_pid
	end

	function self.espawn(strfn)
		local sandbox = {
			table			= table,
			math			= math,
			scheduler	= self,
			coroutine	= coroutine,
			cprint		= cprint,
			callback      = callback,
		}

		local chunk, errmsg = load(strfn, 'test', nil, sandbox)
		if chunk == nil then
			return ':error', 'cannot load chunk: ' .. errmsg
		end

		return self.spawn(chunk)
	end

	function self.run(init)
		return _run()
	end

	return self
end

-- KPrint --

local logger = [==[
local function cprinter(msg) cprint(msg) end
local log_handler = cprinter -- For now

callback.register(':log', function(message)
	log_handler(message)
end)

spin()
]==]

-- Init

local vfs = [==[
callback.register_sync(':open', function(state, path)

end)

callback.register_sync(':close', function(state, fd)

end)

callback.register_sync(':read', function(state, fd, length)

end)

callback.register_sync(':write', function(state, fd, data, length)

end)

callback.register_sync(':register_fs', function(state, filesystem, pid)

end)

callback.register_sync(':deregister_fs', function(state, pid)

end)

callback.register_sync(':mount', function(state, filesystem, path)

end)

callback.register_sync(':umount', function(state, path)

end)

callback.spin()
]==]

local init = [==[
-- Bootstrap logging:
ok, pid = scheduler.espawn(logger)
if ok == ':error' then
	cprint('Error loading logger: ' .. pid)
end
]==]

-- Main --

local sched = scheduler()
ok, pid = sched.espawn(init)
if ok == ':ok' then
	sched.enqueue(pid) 	-- Bootstrap init
	sched.run()					-- Start the kernel scheduler
end

-- We define our callback helpers here so that both callback and the scheduler
-- are forward declared.

function callback.spin()
	local state			= nil
	local callbacks	= {}

	function callback.register_async(name, fn)
		if callbacks[name] == nil then
			callbacks[name] = fn
			return ':ok'
		else
			return ':error', 'callback already exists'
		end
	end

	function callback.register_sync(name, fn)
			if callbacks[name] == nil then
			callbacks[name] = fn
			return ':ok'
		else
			return ':error', 'callback already exists'
		end
	end

	while true do
		local maybe_call = scheduler.mailpeek()
		if type(maybe_call) == 'table' then
			if maybe_call[0] == ':callback' then
				-- This is probably a callback. Proceed:
				scheduler.recv() -- Discard the top message, we aleady have it.
				--TODO

			end
		end

		-- Otherwise, it is not, and should be left alone.
		coroutine.yield()
	end
end
