--[[!MD
# snus_table
## Table library.
### Usage:

```lua
local stbl = require("snus_table") -- or whatever
````

All function accessible from returned table, like

```lua
output = stbl.filter({1, 2, 3, 4}, function(v) return v % 2 == 0 end)
```

Or you can inject library to standard table library:

```lua
require("snus_table").import([bool skip_redefinition])
```

In that case, all function can be called from table library:

```lua
output = table.filter({1, 2, 3, 4}, function(v) return v % 2 == 0 end)
```

(be sure, it will raises error on redefinition of existed methods from other libraries.
]]

local table = _G.table

local snus_table = {}
snus_table.__index = snus_table
snus_table.unpack = _G.table.unpack or _G.unpack

for k, v in pairs(table) do
	if type(v) == "function" then
		snus_table[k] = v
	end
end

--[=[!MD
#### arr
Creates new array that have all functions of table and snus_table library as methods. Returns first arg passed or new empty table.
```lua
snus_table  arr = stbl.arr([table tbl])
--> arr == tbl --> true
```

```lua
myArray = stbl.arr{10, 20, 30, 40}

myArray:insert(20, 4)
--> myArray = {10, 20, 30, 20, 40}

myArray:map(function(v) return v + 1 end)

for i, v in myArray:ripairs(4) do
	print(i, v)
end
--> 4  21
--> 3  31
--> 2  21
--> 1  11
```
]=]

function snus_table.arr(tbl)
	return setmetatable(tbl or {}, snus_table)
end

snus_table.new = snus_table.arr

--[[!MD
#### min
Returns first least item inside table and it's index.

```lua
value, index = stbl.min(table tbl[, function comparefunction(a, b)])
```
]]
function snus_table.min(tbl, func)
	assert(type(tbl) == "table", "Arg #1 error: table expected, got " .. type(tbl))
	local len = #tbl
	if len == 0 then return nil end
	local min, p = #tbl[1], 1
	for i = #tbl, 2, -1 do
		local v = tbl[i]
		if func then
			if func(v, min) then
				min, p = v, i
			end
		else 
			if v < min then
				min, p = v, i
			end
		end
	end
	return min, p
end

--[[!MD
#### max
Returns first largest item inside table and it's index.

```lua
value, index = stbl.max(table tbl[, function comparefunction(a, b)])
```
]]
function snus_table.max(tbl, func)
	assert(type(tbl) == "table", "Arg #1 error: table expected, got " .. type(tbl))
	local len = #tbl
	if len == 0 then return nil end
	local max, p = #tbl[1], 1
	for i = #tbl, 2, -1 do
		local v = tbl[i]
		if func then
			if func(v, max) then
				max, p = v, i
			end
		else 
			if v > max then
				max, p = v, i
			end
		end
	end
	return max, p
end

--[[!MD
#### summ
Returns summ of elements in the table.

```lua
int summ = stbl.summ(table tbl[, function tonumberfunction])
```
]]
function snus_table.summ(tbl, func)
	assert(type(tbl) == "table", "Arg #1 error: table expected, got " .. type(tbl))
	local summ = 0
	for i = 1, #tbl do
		local v = tbl[i]
		summ = summ + func and func(tbl[i]) or tbl[i]
	end
	return max, p
end

--[[!MD
#### index
Returns index of table value if exists, nil otherwise.

```lua
int index = stbl.index(table tbl, any value)
```
]]
function snus_table.index(tbl, value)
	assert(type(tbl) == "table", "Arg #1 error: table expected, got " .. type(tbl))
	for i = 1, #tbl do
		if tbl[i] == value then return i end
	end
	return nil
end

--[[!MD
#### keys
Returns list of table keys (include string ones).

```lua
snus_table keys = stbl.keys(table tbl)
```
]]
function snus_table.keys(tbl)
	assert(type(tbl) == "table", "Arg #1 error: table expected, got " .. type(tbl))
	local output = {}
	local i = 0
	for k, v in pairs(tbl) do
		i = i + 1
		output[i] = k
	end
	return snus_table.arr(output)
end

--[[!MD
#### values
Returns list of all table values.

```lua
snus_table values = stbl.values(table tbl)
```
]]
function snus_table.values(tbl)
	assert(type(tbl) == "table", "Arg #1 error: table expected, got " .. type(tbl))
	local output = {}
	local i = 0
	for k, v in pairs(tbl) do
		i = i + 1
		output[i] = v
	end
	return snus_table.arr(output)
end

--[[!MD
#### reverse
Regular array reverse.

```lua
table out = stbl.reverse(table tbl)
--> out == tbl --> true
```
]]
function snus_table.reverse(tbl)
	assert(type(tbl) == "table", "Arg #1 error: table expected, got " .. type(tbl))
	local len = #tbl
	for i = 1, len / 2 do
		local ii = len - i + 1
		tbl[i], tbl[ii] =	tbl[ii], tbl[i]
	end
	return tbl
end

--[[!MD
#### slice
Returns slice of array table, original table is unchanged
```lua
table out = stbl.slice(table tbl, int start[, int end, bool unpack_result])
```
]]
function snus_table.slice(tbl, i, j, unp)
	i, j = i or 1, j or #tbl
	i = i < 0 and #tbl + i     or i
	j = j < 0 and #tbl + j + 1 or j

	local out = {}
	for i = i, j do
		out[#out + 1] = tbl[i]
	end
	if unp then
		return snus_table.unpack(out) or out
	end
	return out
end

--[[!MD
#### sipairs
Works exactly like ipairs but starts from given index

```lua
for i, v in stbl.sipairs({10, 20, 30, 40}, 3) do
	print(i, v)
end
--> 3 30
--> 4 40
```
]]
local function sipairs_next(tbl, index)
	index = index + 1
	local v = tbl[index]
	if not v then return end

	return index, v
end

-- strait ipairs with optional start index
function snus_table.sipairs(tbl, index)
	assert(type(tbl) == "table", "Arg #1 error: table expected, got " .. type(tbl))
	index = index or 0
	index = index > 0 and index - 1 or index
	return sipairs_next, tbl, index % #tbl
end

--[[!MD
#### ripairs
Works exactly like ipairs but in reverse order (optional start index included)

```lua
for i, v in stbl.ripairs({10, 20, 30}, 2) do
	print(i, v)
end
--> 2 20
--> 1 10
```
]]
local function ripairs_next(tbl, index)
	index = index - 1
	local v = tbl[index]
	if not v then return end
	return index, v
end

function snus_table.ripairs(tbl, index)
	assert(type(tbl) == "table", "Arg #1 error: table expected, got " .. type(tbl))
	index = index or #tbl
	index = index > 0 and index - 1 or index
	return ripairs_next, tbl, index % #tbl + 2
end

--[[!MD
#### map
Apply a function to each element of table in place
```lua
snus_table output = stbl.map(table src, function func(table_element, int index, table src), bool apply_in_place)
```

Example:
```lua
tbl = {10, 20, 30}
out = stbl.map(tbl, function(v, i)) do
	return v + 1
end
--> tbl {10, 20, 30}
--> out {11, 21, 31}

tbl = {10, 20, 30}
out = stbl.map(tbl, function(v, i) return v + 1 end, true)
--> tbl {11, 21, 31}
--> out == tbl --> true
```
]]
function snus_table.map(src, func, inPlace)
	assert(type(src)  == "table",    "Arg #1 error: table expected, got " .. type(src))
	assert(type(func) == "function", "Arg #2 error: function expected, got " .. type(func))
	local out = inPlace and src or snus_table.arr({})
	for i, v in ipairs(src) do
		out[i] = func(v, i, src)
	end
	return out
end

--[[!MD
#### filter
Apply a function to each element of table and remove filtered elements from that table in place
```lua
table output = stbl.filter(table src, function func(table_element, int index, table src))
```

Example:
```lua
tbl = {1, 2, 3, 4}
out = stbl.filter(tbl, function(v, i) return v % 2 == 0 end)
--> tbl {2, 4}
--> out == tbl --> true
```
]]
function snus_table.filter(tbl, filter)
	assert(type(tbl)    == "table",    "Arg #1 error: table expected, got " .. type(tbl))
	assert(type(filter) == "function", "Arg #2 error: function expected, got " .. type(filter))
	local p = 1
	for i = 1, #tbl do
		tbl[p] = tbl[i]
		if filter(tbl[i], i, tbl) then
			p = p + 1
		end
	end

	for i = #tbl, p, -1 do
		tbl[i] = nil
	end
	return tbl
end

--[[!MD
#### where
Returns a table that contains elements from src filtered by filter function
```lua
snus_table output = stbl.where(table src, function func(table_element, int src_index, table src, table dst))
```

Example:
```lua
tbl = {1, 2, 3, 4}
out = stbl.where(tbl, function(v, i) return v % 2 == 0 end)
--> tbl {2, 4}
--> out == tbl --> false
```
]]
function snus_table.where(tbl, filter)
	assert(type(tbl)    == "table",    "Arg #1 error: table expected, got " .. type(tbl))
	assert(type(filter) == "function", "Arg #2 error: function expected, got " .. type(filter))
	local out, oi = {}, 1
	for i = 1, #tbl do
		if filter(tbl[i], i, tbl) then
			out[oi] = tbl[i]
			oi = oi + 1
		end
	end
	
	return out
end

--[[!MD
#### filter
Apply a function to each element of table and remove filtered elements
```lua
table output = stbl.filter(table src, function func(table_element, int index, table src))
```

Example:
```lua
tbl = {1, 2, 3, 4}
out = stbl.filter(tbl, function(v, i)	return v % 2 == 0 end)
--> tbl {2, 4}
--> out == tbl --> true
```
]]
function snus_table.filter(tbl, filter)
	assert(type(tbl)    == "table",    "Arg #1 error: table expected, got " .. type(tbl))
	assert(type(filter) == "function", "Arg #2 error: function expected, got " .. type(filter))
	local p = 1
	for i = 1, #tbl do
		tbl[p] = tbl[i]
		if filter(tbl[i], i, tbl) then
			p = p + 1
		end
	end

	for i = #tbl, p, -1 do
		tbl[i] = nil
	end
	return tbl
end

--[[!MD
#### copy
Simple array copy. No deep.
```lua
snus_table output = stbl.copy(table src)
```

Example:
```lua
tbl = {1, 2, 3, 4}
out = stbl.copy(tbl)
--> tbl {1, 2, 3, 4}
--> out {1, 2, 3, 4}
--> out == tbl --> false
```
]]
function snus_table.copy(src)
	local out = snus_table.arr({})
	for i = 1, #src do
		out[i] = src[i]
	end
	return snus_table.arr(out)
end

--[[!MD
#### merge
Merge of two tables (arrays or/and dicts)
```lua
snus_table output = stbl.merge(table a, table b)
```

Example:
```lua
tblA = {foo = "foo", bar = "bar"}
tblB = {foo = "FOO", foobar = "foobar"}

out = stbl.merge(tblA, tblB)
--> out {foo = "foo", bar = "bar", foobar = "foobar"}
```
Keys from the b-table are added only if they are missing from the a-table.
]]
function snus_table.merge(a, b)
	local out = snus_table.arr({})
	for k, v in pairs(b) do
		out[k] = v
	end
	for k, v in pairs(a) do
		out[k] = v
	end
	return out
end

--[[!MD
#### update
Update a table with content of another table
```lua
table output = stbl.update(table a, table b)
```

Example:
```lua
tblA = {foo = "foo", bar = "bar"}
tblB = {foo = "FOO", foobar = "foobar"}

out = stbl.update(tblA, tblB)
--> out {foo = "FOO", bar = "bar", foobar = "foobar"}
--> out == tblA --> true
```
]]
function snus_table.update(a, b)
	for k, v in pairs(b) do
		a[k] = v
	end
	return a
end

--[[!MD
#### binsearch
Searches nearest larger element to given in sorted arrays
```lua
int index, value element = stbl.binsearch(table tbl, value value)
```

If you want to keep array sorted, you may `table.insert` your value to given index.
Tip: `table.insert(tbl, stbl.binsearch(tbl, value), value)`
]]
local insert = table.insert
local floor = math.floor
function snus_table.binsearch(tbl, value)
	local len = #tbl
	local a, b = 1, len
	local diff = b - a
	while diff > 8 do
		local m = floor(a + diff * .5)
		if tbl[m] > value then
			b = m
		else
			a = m
		end
		diff = b - a
	end
	
	for i = a, b do
		if tbl[i] >= value then
			return i, tbl[i]
		end
	end
	return len, tbl[len]
end

--[[!MD
#### binsert
Searches nearest larger element to given in sorted arrays and inserts value to it's position.
```lua
stbl.binsert(table tbl, value value[, func comparefunction(value a, value b, int index)])
```

Compare function receives current table element, value to insert and current array index.
]]
function snus_table.binsert(tbl, value, func)
	local len = #tbl
	local a, b = 1, len
	local diff = b - a
	while diff > 11 do
		local m = floor(a + diff * .5)
		if func and func(tbl[m], value, m) or tbl[m] >= value then
			b = m
		else
			a = m
		end
		diff = b - a
	end
	
	for i = a, b do
		if func and func(tbl[i], value, m) or tbl[i] >= value then
			return insert(tbl, i, value)
		end
	end
	return insert(tbl, len, value)
end

--[[!MD
#### str
Returns string representation of this table (array part)
```lua
string text = stbl.str(table tbl[, func tostring_func(value a)])
```

Example:
```lua
print( stbl.str{10, 20, 30, "hello", "world"} )
--> {10, 20, 30, "hello", " \"world\" "}
```
]]
function snus_table.str(tbl, tostring_func)
	local text = {}
	local len = #tbl
	
	if tostring_func then
		for i = 1, len do
			text[len + 1] = tostring_func(tbl[i])
		end
	else
		for i = 1, len do
			local value = tbl[i]
			local tvalue = type(value)
			if tvalue == "string" then
				value = "\"" .. value:gsub("\"", "\\\"") .. "\""
			end
			text[i] = tostring(value)
		end
	end
	
	return "{" .. table.concat(text, ", ") .. "}"
end

--[[!MD
#### import
Adds all table function from library to `table` table.
```lua
require("snus_table").import()
```
]]

function snus_table.import(redefine)
	if redefine then
		local tmt = {__index = table}
		function snus_table.arr(tbl)
			return setmetatable(tbl or {}, tmt)
		end
		snus_table.new = snus_table.arr
	end

	for k, v in pairs(snus_table) do
		if not table[k] or redefine then
			table[k] = v
		end
	end
end

return snus_table