
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


#### clamp
Returns number trimmed between lower and upper numbers
```lua
number result = smath.clamp(number value, number lower, number upper)
```


#### loopf
When the upper limit is exceeded, number is transferred to the lower limit and vice versa.
```lua
number result = smath.loopf(number value, number lower, number upper)
```


#### loop
Cyclic normalization of the number to the specified limits.
The default lower bound is 1.
```lua
number result = smath.loop(number value[, number lower], number upper)
```


#### lerp
Returns result of linear interpolation between start, finish by factor t.
```lua
number result = smath.lerp(number start, number finish, number t)
```


#### round
Returns number rounded to nearest int
```lua
number result = smath.round(number value)
```


#### sign
Returns 1, if number is positive, 0 if number is negative, or 0 if number is 0.
```lua
number result = smath.sign(number value)
```


#### fract
Returns fractional part of number.
```lua
number result = smath.fract(number value)
```


#### isnan
Checks number is NaN.
```lua
boolean result = smath.isnan(number value)
```


#### isinf
Checks number is inf.
```lua
boolean result = smath.isinf(number value)
```


#### iseven
Checks number is even.
```lua
boolean result = smath.iseven(number value)
```
Thanks to the presence of this function, I expect at least 10k stars on Github and 2m of forks.


#### import
Adds all functions from library to `math` table.
```lua
require("snus_math").import([bool redefine])
```

If redefine is set to true, the library will be forced to be imported with functions override.
Otherwise, it will raise an error for already existing functions.
