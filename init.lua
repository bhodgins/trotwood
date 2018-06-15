if cprint == nil then cprint = function() end end	-- OC compat
if print  ~= nil then cprint = print end         	-- Testing outside of OC
if computer == nil then computer = { pullSignal = function() end } end

local callback = {} -- Forward declare for callback routines

-- Scheduler --

local scheduler = function()
	local self        = {}
	local outbox      = {}
	local actors      = {}
	local named       = {}
	local ready       = {}
	local subscribers = {}

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
			pid_cap = pid_cap + 1
		end

		next_pid = table.remove(free_pids, 1)
		return next_pid / process_max
	end

	function self.send(pid, ...)
		local arg = table.pack(...)

		if actors[pid] ~= nil then
			table.insert(outbox[pid], arg)
			self.enqueue(pid)

			return ':ok'
		end

		cprint("Can't send message to pid " .. pid .. ": No such pid")
		return ':error'
	end

	function self.enqueue(pid)
		if actors[pid] ~= nil then
			table.insert(ready, pid)
			return ':ok'
		end

		cprint("Can't enqueue pid " .. pid .. ": No such pid")
		return ':error'
	end

	-- External event subscription
	function self.subscribe(pid, event)
		if subscribers[event] == nil then subscribers[event] = {} end

		-- Make sure we're not already subscribed:
		for _, subscriber in ipairs(subscribers[event]) do
			if subscriber == pid then
				cprint("Can't subscribe to event" .. event .. ": Already subscribed")
				return ':error'
			end
		end

		table.insert(subscribers[event], current)
	end

	-- External event unsubscription
	function self.unsubscribe(pid, event)
		if subscribers[event] == nil then
			goto not_subscribed
		end

		-- We need to find the index it may be located at:
		for index, subscriber in ipairs(subscribers[event]) do
			if subscriber == pid then
				table.remove(subscriber[event], index)
				return ':ok'
			end
		end

		::not_subscribed::
		return ':error', 'not subscribed'
	end

	local function _run()
		--[[
			As much as it may not seem like it, events and messaging is top priority
			in such a system. It is much more important to ensure that messages are
			delivered so that they can be handled, rather than encourage processes to
			work for long periods of time to do more work at once. Try to keep your
			processing time short, so that the responsiveness of the system increases.
		]]

		local ev = table.pack(computer.pullSignal(0)) or {} -- Check for events
		local ev_name = table.remove(ev, 1) or ''

		if subscribers[ev_name] ~= nil then
			--[[ In theory we just have a subscriber list. I thought of having an
			actor take care of event subscriptions but it then the performance
			becomes a linear vertical translation f(n) = O(n) + alpha, where alpha is
			the average runtime of the message passing and subscription lookup. --]]

			for _, subscriber in ipairs(subscribers[ev_name]) do
				self.send(subscriber, ':ev', ev_name, table.unpack(ev))
			end
		end

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

	local function subscribe(event)   return self.subscribe(current, event)   end
	local function unsubscribe(event) return self.unsubscribe(current, event) end

	-- Returns the current number of messages in actors' mailbox
	function self.inbox() return #outbox[current] end

	-- Peeks at the top message in the queue:
	function self.mailpeek()
		if #outbox ~= 0 then return outbox[current][1] else return nil end
	end

	function self.recv()
		coroutine.yield()

		--[[
			It is possible for a process to be force-resumed using scheduler.enqueue()
			If this happens, and we are in the middle of a recv() call, then we might
			assume that some process wants to break an existing recv() call:
		--]]
		if self.inbox() == 0 then return ':error', 'Wakeup: broke out of recv loop' end

		return ':ok', table.remove(outbox[current], 1)
	end

	function self.spawn(fn, name)
		local co = coroutine.create(fn)

		local new_pid = _find_pid() -- Process needs a new PID
		cprint('starting process with pid ' .. new_pid)
		outbox[new_pid] = {}        -- Setup mailbox

		if name ~= nil then named[name] = new_pid end
		actors[new_pid] = co
		return ':ok', new_pid
	end

	function self.espawn(strfn)
		local sandbox = {
			table			  = table,
			math			  = math,
			scheduler	  = self,
			subscribe   = subscribe,
			unsubscribe = unsubscribe,
			coroutine	  = coroutine,
			cprint		  = cprint,
			callback    = callback,
			component   = component,
		}

		-- Process callbacks can be easier this way:
		--[[
		setmetatable(sandbox, {
			__index = function()

			end
		}) --]]

		local chunk, errmsg = load(strfn, 'test', nil, sandbox)
		if chunk == nil then
			return ':error', 'cannot load chunk: ' .. errmsg
		end

		return self.spawn(chunk)
	end

	function self.run() return _run() end

	return self
end

local init = [==[
-- (PRE-INIT)

local eeprom = component.proxy((component.list("eeprom"))())
local boot_uuid = eeprom.getData()
cprint("boot device hint is: " .. boot_uuid)

-- Try and locate tboot.lua:
local fs = component.proxy(boot_uuid)

if not fs.exists("/tboot.lua") then return end
local fh = fs.open("/tboot.lua")

local chunk    = ""
local contents = ""

while chunk ~= nil do
	contents = contents .. chunk
	chunk = fs.read(fh, 8192)
	scheduler.enqueue(scheduler.self())
	coroutine.yield()
end fs.close(fh)

local ok, pid = scheduler.espawn(contents)
if ok == ':ok' then
	scheduler.enqueue(pid)
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
		if callbacks[name] ~= nil then
			return ':error', 'callback already exists'
		end

		callbacks[name] = { fn = fn }
		return ':ok'
	end

	function callback.register_sync(name, fn)
		local ok, errmsg = callback.register_async(name, fn)
		if ok == ':error' then return ok, errmsg end
		callbacks[name][sync] = true
		return ':ok'
	end

	while true do
		local msg = scheduler.recv()
		if type(msg) == 'table' then
			local hint     = msg[1]
			local callback = msg[2]
			local args     = msg[3] or {}
			local source   = msg[4]
			local tag      = msg[5]

			if hint == ':callback' then
				-- This is probably a callback. Proceed:
				if callbacks[callback] ~= nil then
					local retvals = table.pack( callbacks.callback['fn'](state, table.unpack(args)) )

					-- Syncronous callbacks need return values:
					if source ~= nil and callbacks.callback['sync'] ~= nil then
						scheduler.send( source, {':callback-return', self(), callback, tag, retvals} )
					end
				end
			end
		end
	end

end
