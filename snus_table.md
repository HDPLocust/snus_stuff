
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
mystring = "abcdef"
output = table.filter({1, 2, 3, 4}, function(v) return v % 2 == 0 end)
```

(be sure, it will raises error on redefinition of existed methods from other libraries.


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
out = stbl.map(tbl, function(v, i) return v + 1 end)
--> tbl {11, 21, 31}
--> out == tbl --> true
```


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


#### merge
Merge of two tables (not arrays or dicts)
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


#### binsearch
Searches nearest larger element to given in sorted arrays
```lua
int index, value element = stbl.binsearch(table tbl, value value)
```

If you want to keep array sorted, you may `table.insert` your value to given index.
Tip: `table.insert(tbl, stbl.binsearch(tbl, value), value)`


#### binsert
Searches nearest larger element to given in sorted arrays
```lua
stbl.binsert(table tbl, value value[, func comparefunction])
```

Compare function reveives current table element, value to insert and current array index.


#### import
Adds all table function from library to `table` table.
```lua
require("snus_table").import([bool redefine])
```

If redefine is set to true, the library will be forced to be imported with functions override.
Otherwise, it will raise an error for already existing functions.
