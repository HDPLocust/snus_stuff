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


local snus_table = {}
snus_table.__index = snus_table
snus_table.unpack = _G.unpack or _G.table.unpack

for k, v in pairs(_G.table) do
	snus_table[k] = v
end

--[[!MD
#### arr
Creates new array that have all functions of table and snus_table library as methods. Returns first arg passed or new empty table.
```lua
table arr = stbl.arr([table tbl])
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
]]
function snus_table.arr(tbl)
	return setmetatable(tbl or {}, snus_table)
end

--[[!MD
#### keys
Returns list of table keys (include string ones).

```lua
table keys = stbl.keys(table tbl)
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
	return output
end

--[[!MD
#### values
Returns list of all table values.

```lua
table values = stbl.values(table tbl)
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
	return output
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
Apply a function to each element of table
```lua
table output = stbl.map(table src, function func(table_element, int index, table src), bool apply_in_place)
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
	local out = inPlace and src or {}
	for i, v in ipairs(src) do
		out[i] = func(v, i, src)
	end
	return out
end

--[[!MD
#### filter
Apply a function to each element of table
```lua
table output = stbl.filter(table src, function func(table_element, int index, table src))
```

Example:
```lua
tbl = {1, 2, 3, 4}
out = stbl.filter(tbl, function(v, i)	return v % 2 == 0 end)
--> tbl {2, 4}
--> out == tbl --> true

Filtered values is removed.
```
]]
function snus_table.filter(tbl, filter)
	assert(type(tbl)  == "table",    "Arg #1 error: table expected, got " .. type(tbl))
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
table output = stbl.copy(table src)
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
	local out = {}
	for i, v in ipairs(src) do
		out[i] = v
	end
	return out
end

--[[!MD
#### merge
Merge of two tables (arrays or/and dicts)
```lua
table output = stbl.merge(table a, table b)
```

Example:
```lua
tblA = {foo = "foo", bar = "bar"}
tblB = {foo = "FOO", foobar = "foobar"}

out = stbl.merge(tblA, tblB)
--> out {foo = "foo", bar = "bar", foobar = "foobar"}
```
The first table dominates.
]]
function snus_table.merge(a, b)
	local out = {}
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
Searches nearest larger element to given in sorted arrays
```lua
stbl.binsert(table tbl, value value[, func comparefunction])
```

Compare function reveives current table element, value to insert and current array index.
]]
function snus_table.binsert(tbl, value, func)
	local len = #tbl
	local a, b = 1, len
	local diff = b - a
	while diff > 8 do
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
#### import
Adds all table function from library to `table` table.
```lua
require("snus_table").import()
```
]]
local table = _G.table
function snus_table.import(redefine)
	for k, v in pairs(snus_table) do
		table[k] = v
	end
	
	function snus_table.arr(tbl)
		return setmetatable(tbl or {}, table)
	end
end

return snus_table