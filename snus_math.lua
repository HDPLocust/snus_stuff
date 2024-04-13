--[[!MD
# snus_math
## Basic math library.
### Usage:

```lua
local smath = require("snus_math") -- or whatever
````

All function accessible from returned table, like

```lua
output = smath.clamp(10, 2, 7)
```

Or you can inject library to standard table library:

```lua
require("snus_math").import([bool skip_redefinition])
```

In that case, all function can be called from math library:
```lua
output = math.clamp(10, 2, 7)
```

(be sure, it will raises error on redefinition of existed methods from other libraries.
]]


local snus_math = {}
snus_math.__index = snus_math

local huge = math.huge
local min, max = math.min, math.max
local floor, ceil = math.floor, math.ceil

--[[!MD
#### clamp
Returns number trimmed between lower and upper numbers
```lua
number result = smath.clamp(number value, number lower, number upper)
```
]]
function snus_math.clamp(value, lower, upper)
	return value < lower and lower or value > upper and upper or value
end

--[[!MD
#### loopf
When the upper limit is exceeded, number is transferred to the lower limit and vice versa.
```lua
number result = smath.loopf(number value, number lower, number upper)
```
]]
function snus_math.loopf(value, lower, upper)
	return value < lower and upper or value > upper and lower or value
end

--[[!MD
#### loop
Cyclic normalization of the number to the specified limits.
The default lower bound is 1.
```lua
number result = smath.loop(number value[, number lower], number upper)
```
]]
function snus_math.loop(value, lower, upper)
	if not upper then lower, upper = 1, lower end
	local root = upper - lower + 2
	return (value - root) % (root - 1) + lower
end

--[[!MD
#### lerp
Returns result of linear interpolation between start, finish by factor t.
```lua
number result = smath.lerp(number start, number finish, number t)
```
]]
function snus_math.lerp(start, finish, t)
	return start * (1 - t) + finish * t
end

--[[!MD
#### round
Returns number rounded to nearest int
```lua
number result = smath.round(number value)
```
]]
function snus_math.round(value)
	local f = floor(value)
	return value - f < 0.5 and f or f + 1
end

--[[!MD
#### sign
Returns 1, if number is positive, 0 if number is negative, or 0 if number is 0.
```lua
number result = smath.sign(number value)
```
]]
function snus_math.sign(value)
	return value == 0 and 0 or value > 0 and 1 or -1
end

--[[!MD
#### fract
Returns fractional part of number.
```lua
number result = smath.fract(number value)
```
]]
function snus_math.fract(value)
	return value % 1
end

--[[!MD
#### isnan
Checks number is NaN.
```lua
boolean result = smath.isnan(number value)
```
]]
function snus_math.isnan(value)
	return value ~= value
end

--[[!MD
#### isinf
Checks number is inf.
```lua
boolean result = smath.isinf(number value)
```
]]
function snus_math.isinf(value)
	return value == huge
end

--[[!MD
#### iseven
Checks number is even.
```lua
boolean result = smath.iseven(number value)
```
Thanks to the presence of this function, I expect at least 10k stars on Github and 2m of forks.
]]
function snus_math.iseven(value)
	return value % 2 == 0
end

--[[!MD
#### import
Adds all functions from library to `math` table.
```lua
require("snus_math").import([bool redefine])
```

If redefine is set to true, the library will be forced to be imported with functions override.
Otherwise, it will raise an error for already existing functions.
]]
local math = _G.math
function snus_math.import(redefine)
	for k, v in pairs(snus_math) do
		if math[k] and math[k] ~= v then
			if not redefine then
				error("Redefining of [" .. k .. "] function")
			end
		end
		math[k] = v
	end
end

if ... then
	return snus_math
end