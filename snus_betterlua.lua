--[[!MD
# snus_betterlua [beta]
## This library is developed to ruin your Lua expirience. Get ready to get dirty and have fun.

snus_betterlua adds an object model to basic Lua types, such as numbers, booleans, nil, functions, coroutines and partially tables. Strings already have an object model, so this library just adds a few methods to them to unify them with other objects. Unfortunately (or fortunately), Lua cannot globally add functionality to custom data/userdata types, so this appears to be unaffected.

### Usage:
```lua
require("snus_betterlua")
````
From this moment on, your life will cease to be the same.
]]

local dsmt = debug.setmetatable
local dgmt = debug.getmetatable
local smt, gmt = setmetatable, getmetatable
local unpack = table.unpack or unpack

local function defaultprint(obj, fmt, ...)
	if fmt and ... then
		print(fmt:format(obj, ...))
	elseif fmt then
		print(fmt:format(obj))
	else
		print(obj)
	end
	return obj
end

--[[!MD 
### String extension

```lua
local result
local mystring = "abcdef"
result = mystring:print() --> "abcdef"
result = mystring:print("mystring is %s") --> "String is abcdef"
result = mystring:print("mystring is %s %s", mystring:type()) --> "String is abcdef string"

local mystring = "123abc"
local mynumber = mystring:tonumber(16) --> 1194684
```
]]
string.print    = defaultprint
string.tonumber = tonumber
function string:type() return "string" end

--[[!MD 
### Number extension

```lua
local result
local mynumber = 123.456
result = mynumber:print() --> 123.456, rules for print is same as in String extension
result = mynumber:type() --> "number"
result = mynumber:format("%0.2f") --> "123.45"
result = mynumber:tostring() --> "123.456"
```

Also, any `math` function may be called as number method:
```lua
local result = mynumber:floor():pow(2):print("Number is %d") --> "Number is 15129"
```
]]
math.tostring = tostring
math.print    = defaultprint
function math:type() return "number" end

function math:format(f)
	return f:format(self)
end

dsmt(0, {__index = math})

--[[!MD 
### Boolean extension

```lua
local result
local myboolean = true
result = myboolean:print("Value is %s") --> "Value is true"
result = myboolean:type() --> "boolean"
result = myboolean:tostring() --> "true"
result = myboolean:tonumber() --> 1 (or 0 if false)
```
]]
local bool = {print = defaultprint, tostring = tostring}
function bool:type() return "boolean" end
function bool:tonumber() return self and 1 or 0 end

dsmt(true, {__index = bool})

--[[!MD 
### Nil extension, yes

```lua
local result
result = mynil:print("Value is %s") --> "Value is nil"
result = mynil:type() --> "nil"
result = mynil:tostring() --> "nil"
```

THIS EXTENSION MAY LEAD TO UNEXPECTED BEHAVIOR:
```lua
local mytable = {foo = {}}
local result = mytable.foo.bar.baz 
```
Pros: This will not raise errors, unlike basic Lua behavior.
Cons: `mytable.foo.bar.print`, `mytable.foo.bar.type` and `mytable.foo.bar.tostring` will be functions (from nil metatable)
]]
local nilmt = {print = defaultprint, tostring = tostring}
function nilmt:type() return "nil" end
dsmt(nil,  {__index = nilmt})

--[[!MD 
### Coroutine extension

```lua
local result
local mycoroutine = coroutine.create(function() return 10 end)
result = mycoroutine:print("Coroutine is %s") --> "Coroutine is thread 0x12345"
result = mycoroutine:type() --> "thread"
result = mycoroutine:tostring() --> "thread 0x12345"
-- also any coroutine function may be called as method:
local status, result = mycoroutine:resume() --> false, 10
```
]]
coroutine.print = defaultprint
coroutine.tostring = tostring
function coroutine:type() return "thread" end

--[[!MD 
### Function extension

```lua
local result
local myfunction = function(a, b, c) return 10 end
result = myfunction:print("Function is %s") --> "Function is function 0x12345"
result = myfunction:type() --> "function"
result = myfunction:tostring() --> "function 0x12345"

local file = io.open:assert("myfile.txt", "rb") --> will raise error with message from io.open
local file = io.open:massert("File not found", "myfile.txt", "rb") --> will raise error with first arg message
local time = myfunction:benchmark(10000, os.clock) --> will call function 10000 times with os.clock as time measure function
local status, result = myfunction:pcall(10, 20, 30) --> regular pcall
local status, result = myfunction:xpcall(debug.traceback, 10, 20, 30) --> regular xpcall
local result = myfunction:safe(10, 20, 30) --> pcall but without status in success
local result = myfunction:xsafe(debug.traceback, 10, 20, 30) --> xpcall, but without status in success
local tinfo = myfunction:getinfo() --> basic debug.getinfo about function
```
]]
local func = {print = defaultprint, tostring = tostring}

function func:type() return "function" end

function func:assert(...)
	return assert(self(...))
end

function func:massert(msg, ...)
	return assert(self(...), msg)
end

function func:benchmark(amount, timefunc, ...)
	timefunc = timefunc or os.clock
	local starttime = timefunc()
	for i = 1, amount do
		self(...)
	end
	return timefunc() - starttime
end

func.pcall  = pcall
func.xpcall = xpcall

function func:safe(...)
	local status, a, b, c, d, e, f, g, h = pcall(self, ...)
	if not status then return nil, a end
	return a, b, c, d, e, f, g, h
end

function func:xsafe(traceback, ...)
	local status, a, b, c, d, e, f, g, h = xpcall(self, traceback, ...)
	if not status then return nil, a end
	return a, b, c, d, e, f, g, h
end

function func:getlocal(level, index)
	return debug.getlocal(self, level, index)
end

function func:setlocal(level, index, value)
	return debug.setlocal(self, level, index, value)
end

function func:getupvalue(index)
	return debug.getupvalue(self, index)
end

function func:setupvalue(index, value)
	return debug.getupvalue(self, index, value)
end

function func:setfenv(t)
	return debug.setfenv(self, t)
end

function func:getinfo(what)
	return debug.getinfo(self, what)
end

local f, err = function() end
dsmt(f, {__index = func})
dsmt(coroutine.create(f), {__index = coroutine})
f = nil

--[[!MD 
### Table extension

```lua
local result
local mytable = table.new({1, 2, 3, 4})
result = mytable:print("Table is %s") --> "Table is table 0x12345"
result = mytable:type() --> "table"
result = mytable:tostring() --> "table 0x12345"

-- also any table function may be called as method:
local length = mytable:length() --> 4

result = mytable:concat(" ") --> 1 2 3 4
for i, v in mytable:ipairs() do
	print(i, v)
end
```
]]
table.__index = table
table.print = defaultprint
table.tostring = tostring
table.pairs  = pairs
table.ipairs = ipairs
function table.type() return "table" end

function table.new(t)
	return smt(t or {}, self)
end

local tblmt = assert(gmt(table) == nil, "table [table] already have metatable")
smt(table, {__call = function(self, t)
	return smt(t or {}, self)
end})