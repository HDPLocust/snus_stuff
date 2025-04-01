
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


#### min
Returns first least item inside table and it's index.

```lua
value, index = stbl.min(table tbl[, function comparefunction(a, b)])
```


#### max
Returns first largest item inside table and it's index.

```lua
value, index = stbl.max(table tbl[, function comparefunction(a, b)])
```


#### summ
Returns summ of elements in the table.

```lua
int summ = stbl.summ(table tbl[, function tonumberfunction])
```


#### index
Returns index of table value if exists, nil otherwise.

```lua
int index = stbl.index(table tbl, any value)
```


#### keys
Returns list of table keys (include string ones).

```lua
snus_table keys = stbl.keys(table tbl)
```


#### values
Returns list of all table values.

```lua
snus_table values = stbl.values(table tbl)
```


#### reverse
Regular array reverse.

```lua
table out = stbl.reverse(table tbl)
--> out == tbl --> true
```


#### slice
Returns slice of array table, original table is unchanged
```lua
table out = stbl.slice(table tbl, int start[, int end, bool unpack_result])
```


#### sipairs
Works exactly like ipairs but starts from given index

```lua
for i, v in stbl.sipairs({10, 20, 30, 40}, 3) do
	print(i, v)
end
--> 3 30
--> 4 40
```


#### ripairs
Works exactly like ipairs but in reverse order (optional start index included)

```lua
for i, v in stbl.ripairs({10, 20, 30}, 2) do
	print(i, v)
end
--> 2 20
--> 1 10
```


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


#### binsearch
Finds the closest greater element to a given element in a sorted array
```lua
int index, value element = stbl.binsearch(table tbl, value value[, func comparefunction(value a, value b, int index)])
```

Default comparefunction is like
```lua
function(a, b) a < b end
```

You may use it with `table.insert` to keep array sorted:
```lua
table.insert(tbl, stbl.binsearch(tbl, value), value)
```


#### binsert
Searches nearest larger element to given in sorted arrays and inserts value to it's position.
```lua
table tbl, int index, value element = stbl.binsert(table tbl, value value[, func comparefunction(value a, value b, int index)])
```


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


#### import
Adds all table function from library to `table` table.
```lua
require("snus_table").import()
```
