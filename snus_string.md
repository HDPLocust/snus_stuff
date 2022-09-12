
# snus_string
## String library. Contains a lot of borrowed code.
### Usage:

```lua
local sstr = require("snus_string") -- or whatever
````

All function accessible from returned table, like

```lua
output = sstr.usub("abcdef", 2, 5)
```

Or you can inject library to extend standard string library:

```lua
require("snus_string").import([bool skip_redefinition])
```

In that case, all function can be called as string methods:

```lua
mystring = "abcdef"
output = mystring:usub(2, 5)
```

(be sure, it will raises error on redefinition of existed methods from other libraries like [strong](https://github.com/mebens/strong))
This library also does not override the standard metamethods like __add/__div, so this behavior is unchanged.


### Windows ANSI module

May be used for conversion between cp1251 (cyrillic) and utf8. May be useful if you're working on ru localed windows.
Have two functions:
```lua
string decoded = sstr.ansiToUtf8(string cp1251text[, bool skip_chars])`
string encoded = sstr.utf8ToAnsi(string utf8text[, bool skip_chars])`
```

If skip_chars is false, all characters that not fit encoding will be replaced to "?", skipped otherwise


### URL module
Provides basic url encoding and decoding.

```lua
string encoded = sstr.urlencode(string text[, bool space_to_plus])`
string decoded = sstr.urldecode(string encoded_text[, bool space_to_plus])`
```
If space_to_plus is true, all space characters will be replaced to "+" like on url query, or to %20 otherwise. Same in decoding.


### Unicode module
Provides manipulation of unicode and utf8 strings.

Contains sstring.charpattern key "[%z\1-\x7F\xC2-\xF4][\x80-\xBF]*" which is a template for a single utf8 character.


#### uchars
Unicode character iterator
```lua
for int endbyte, string u8char in sstr.uchars(string u8text) do
  print(endbyte, char)
end
```

Endbyte is byteindex of last byte of current char, have internal usage.
u8char is multibyte utf8 character as string.
All non utf8 charaters is skipped.


#### uoffsets
Unicode character offset iterator
```lua
for int startbyte, int endbyte in sstr.uoffsets(string u8text) do
	local char = u8text:sub(startbyte, endbyte)
	print(char, startbyte, endbyte)
end
```

Startbyte is byteindex of first byte of current multibyte character.
Endbyte is byteindex of last byte.
Used to calculate the boundaries of character sequences.


#### uencode
Provides encoding to unicode codepoints and back.

```lua
string encoded = sstr.uencode(string text[, string prefix])`
```
Default prefix is "\u", but also can be "U+", "u", "\" etc.

#### udecode
```lua
string decoded = sstr.udecode(string encoded_text[, string prefix])`
```

Default prefix is "\u".


#### ubyte
Returns codepoint number by given index.

```lua
int codepoint = sstr.ubyte(int index)`
```


#### uchar
Returns utf8 string by given codepoint.

```lua
string char = sstr.uchar(int codepoint)`
```


#### ulen
Returns length of utf8 string in characters.

```lua
int length = sstr.ulen(string u8text)`
```

Non utf8 chars is skipped.


#### ureverse
Returns reversed utf8 string.

```lua
string reversedu8text = sstr.ureverse(string u8text)`
```

Non utf8 chars is skipped.


#### usub
Returns substring of utf8 string.

```lua
string u8text = sstr.usub(string u8text, int firstchar, int lastchar)`
```

Should work exactly like string.sub but for utf8 characters


#### uindex
Returns utf8 char by index and it's start and end offsets
```lua
string u8char, int startoffset, int endbyteoffset = sstring.uindex(string u8text, int index)
```


#### usanitize
Returns utf8 string without any non-utf8 character
```lua
string u8sanitazed = sstring.usanitize(string u8text)
```


### Utility module
#### split

Returns table of string or several strings from given string
```lua
table splitted = sstring.split(string text[, string separator, bool unpack_result])
```

Examples:
```lua
splitted = sstring.split("Hello,world")
--> {"Hello", "World"}

a, b = sstring.split(string "Hello world", " ", true)
--> a == "Hello"; b == "world"
```


#### slice

Returns one or several chunks of separate formatted string
```lua
table slice = sstring.slice(string text, int startindex, int endindex, string separator[, bool unpack_result])
```


#### bfind
Something like "%b" modifier in string patterns but little more complex.

```lua
string found, startindex, endindex = sstring.bfind(string header, string footer[, int offset, bool exclude_bounds, bool header_and_footer_as_plain_text])
```

Examples:
```lua
text = [[
<div>
	<div> foo </div>
	<div>	bar </div>
	<div>	foobar </div>
</div>
]]

found = sstring.bfind(text, "<div>", "</div>", 0, true)

--> [[
	<div> foo </div>
	<div>	bar </div>
	<div>	foobar </div>
]]
```


#### lines
Lines iterator
```lua
for string line, table info in sstr.lines(string text[, string separator]) do
	print(line, info.str, info.index, info.sep)
end
```

Default separator is "\r\n?"


#### field
Returns one line (or field) by index
```lua
string field = sstr.field(string text, string separator, int index)
```

Default separator is "\r\n?"


#### trim
Cuts given characters from front and back of text
```lua
string trimmed = sstr.trim(string text, string charset)
```
Default set of trimming characters is "\r\n%s"


#### starts
Checks if a string starts with the given pattern.
```lua
bool isStarts = sstr.starts(string text, string pattern[, bool isRegex])
```


#### ends
Checks if a string ends with the given pattern.
```lua
bool isEnds = sstr.ends(string text, string pattern[, bool isRegex])
```


#### cat
Concatenates everything into one string.
```lua
string concatted = sstr.cat(string text1[, string text2, string text3, ...])
```


#### concat
Same as cat but with separator.
```lua
string concatted = sstr.concat(string text1[, string text2, string text3, ...], string separator)
```


#### import
Adds all string function from library to `string` table.
```lua
sstring.import([bool redefine])
```

If redefine is set to true, the library will be forced to be imported with method overrides.
Otherwise, it will raise an error for already existing functions.
