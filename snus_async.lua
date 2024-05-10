-- queue for new routines to perform
-- stack for old routines to perform
-- all routines from queue are transported to stack before performing
-- used to execute all routines, including those created by other routines, in single update.
local queue = {}
local stack = {}

local async = {}
async.__index = async

local unpack = table.unpack or unpack
local traceback = debug.traceback
local crunning, ccreate = coroutine.running, coroutine.create
local cresume, cyield   = coroutine.resume,  coroutine.yield

local pack = table.pack or pack or function(...)
	local t = {n = select("#", ...)}
	for i = 1, t.n do t[i] = select(i, ...) end
	return t
end

function async.getTasksCount(separate)
	local i, j = 0, 0
	for _ in pairs(stack) do i = i + 1 end
	for _ in pairs(queue) do j = j + 1 end
	
	if separate then
		return i, j
	end
	return i + j
end

function async.running()
	local co, isMain = crunning()
	if not co or (co and isMain) then
		return false
	end
	return true
end

async.clock = os.clock
function async.sleep(delay)
	if type(delay) ~= "number" then
		error("bad argument #1 to 'sleep' (number expected, got " .. type(delay) .. ")", 2)
	end
	
	if not async.running() then
		error("Sleep should be called inside async function", 2)
	end
	
	local target = async.clock() + delay
	while async.clock() < target do
		cyield()
	end
end

-- perform all promises
function async.update()
	for r in pairs(stack) do
		r:perform()
	end
	
	local r = next(queue)
	while r do
		queue[r] = nil
		stack[r] = true
		r:perform()
		r = next(queue)
	end
	return async.getTasksCount() == 0 and false or true
end

-- wait until function returns result
function async.await(func, ...)
	if not async.running() then
		error("await should be called inside async function", 2)
	end
	
	local routine = async._new(func, ...)
	queue[routine] = true
	while not routine.result and not routine.error do
		cyield()
	end
	
	if routine.error then
		return nil, routine.error
	end
	
	return unpack(routine.result)
end

-- wait until immediate function returns true (with timeout)
function async.waitfor(func, timeout, ...)
	if not async.running() then
		error("waitfor should be called inside async function", 2)
	end
	
	timeout = async.clock() + (timeout or math.huge)
	local a1, a2, a3, a4, a5, a6 = func(...)
	while not a1 and not a2 and not a3 do
		coroutine.yield()
		a1, a2, a3, a4, a5, a6 = func(...)
		if async.clock() < timeout then
			return nil, 'timeout'
		end
	end
	
	return a1, a2, a3, a4, a5, a6
end

function async.yield(...)
	if not async.running() then
		error("yield should be called inside async function")
	end
	return cyield(...)
end

function async._new(func, ...)
	local self = setmetatable({}, async)

	local routine, err = ccreate(func)
	if not routine then return nil, err end
	
	self.args = {self, ...}
	self.info    = debug.getinfo(func)
	self.routine = routine
	return self
end


--[[
	async object:
	{
		args = {args that will be passed to next perform},
		info = {
			-- debug.getinfo of called function
		},
		onNext = async function,
		onError = async function,
		timeout = number (clock + delay),
		result = {up to 6 arguments that will be passed to then}
	}
]]

function async.new(func, ...)
	local self = async._new(func, ...)
	queue[self] = true
	return self
end

function async.__tostring(self)
	local i = self.info
	return "Async function: <" .. (i.short_src or i.source) 
		.. ": " .. (i.namewhat ~= "" and i.namewhat or "local")
		.. " "  .. (i.name or "chunk")
		.. " [" .. i.currentline .. "]>"
end

async.errorhandler = function(coro, err)
	print("Error: " .. tostring(coro) .. " " .. tostring(err))
end

setmetatable(async, {__call = function(self, ...) return async.new(...) end})

-- tell promise that you want to stop it
function async:stop()
	self.timeout = 0
	return self
end

-- check inside promise that someone tries to stop it
function async:teststop()
	return self.timeout <= 0
end

-- promise will raise error on timeout and stops
function async:settimeout(delay)
	if type(delay) ~= 'number' then
		error("bad argument #1 to 'Timeout' (number expected, got " .. type(delay) .. ")", 2)
	end
	self.timeout = async.clock() + delay
	return self
end

function async:perform()
	--print("Perform ", self)
	local timeout
	local ok, a1, a2, a3, a4, a5, a6
	
	if self.timeout and async.clock() >= self.timeout then
		ok, a1, timeout = false, "timeout", true
	end

	if not timeout then
		if self.args then
			ok, a1, a2, a3, a4, a5, a6 = cresume(self.routine, unpack(self.args))
			self.args = nil
		else
			ok, a1, a2, a3, a4, a5, a6 = cresume(self.routine)
		end
	end
	
	--print("Perform", self, ok, a1, a2, a3)
	if not ok then
		stack[self] = nil
		if a1 == "cannot resume dead coroutine" then
			return
		end
		
		self.error = a1 .. "\n" .. debug.traceback(self.routine)
		
		--print("Error: ", a1, trace)
		if self.onError then
			self.onError.args = {self.onError, self.error}
			queue[self.onError] = true
		else
			self.errorhandler(self, self.error)
		end
		return
	end
	
	if a1 then
		stack[self] = nil
		self.result = {a1, a2, a3, a4, a5, a6}
		if self.onNext then
			self.onNext.args = {self.onNext, a1, a2, a3, a4, a5, a6}
			queue[self.onNext] = true
		end
	end
end

-- Then
function async:next(callback, errfunc)
	if type(callback) ~= 'function' then
		error("bad argument #1 to 'next' (function expected, got " .. type(callback) .. ")", 2)
	end
	
	self.onNext = async._new(callback)
	if errfunc then
		if type(errfunc) ~= 'function' then
			error("bad argument #2 to 'next' (function expected, got " .. type(errfunc) .. ")", 2)
		end
		self:catch(callback)
	end
	return self.onNext
end

-- Catch
function async:catch(errfunc)
	if type(errfunc) ~= 'function' then
		error("bad argument #1 to 'Catch' (function expected, got " .. type(errfunc) .. ")", 2)
	end
	self.onError = async._new(errfunc)
	return self
end

if ... then
	return async
end


local function f(self, a, b, c)
	print("Start f", os.clock())
	local a = async.await(function()
		print("Hello!", os.clock())
		async.sleep(2)
		print("World!", os.clock())
		return 10
	end)

	local b = async.await(function()
		print("Good bye!", os.clock())
		async.sleep(2)
		print("World!", os.clock())
		return 20
	end)
	
	print("Results, ", a + b, os.clock())
end

async(f, 10, 20)

async(function(self, a, b)
	print("  Start g", os.clock())
	return a + b
end, 10, 20):next(function(self, result)
	print("  start next g", os.clock(), result)
	return result + 20
end):next(function(self, result) 
	print("  start next next g", os.clock(), result)  
end)

while async:update() do end