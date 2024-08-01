
# snus_betterlua [beta]
## This library is developed to ruin your Lua expirience. Get ready to get dirty and have fun.

snus_betterlua adds an object model to basic Lua types, such as numbers, booleans, nil, functions, coroutines and partially tables. Strings already have an object model, so this library just adds a few methods to them to unify them with other objects. Unfortunately (or fortunately), Lua cannot globally add functionality to custom data/userdata types, so this appears to be unaffected.

### Usage:
```lua
require("snus_betterlua")
````
From this moment on, your life will cease to be the same.

 
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

 
### Boolean extension

```lua
local result
local myboolean = true
result = myboolean:print("Value is %s") --> "Value is true"
result = myboolean:type() --> "boolean"
result = myboolean:tostring() --> "true"
result = myboolean:tonumber() --> 1 (or 0 if false)
```

 
### Nil extension, yes

To activate methods, you must call function returned by `require("snus_betterlua")()`
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
Cons: `mytable.foo.bar.print`, `mytable.foo.bar.type` and `mytable.foo.bar.tostring` will be functions (from nil metatable if methods are activated)

 
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
