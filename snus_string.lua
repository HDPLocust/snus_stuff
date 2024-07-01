--[[!MD
# snus_string
## String library. 
Contains a lot of borrowed code.
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
]]


-- CP1251 kyr
local ansi_decode={
  [128]='\208\130',[129]='\208\131',[130]='\226\128\154',[131]='\209\147',[132]='\226\128\158',[133]='\226\128\166',
  [134]='\226\128\160',[135]='\226\128\161',[136]='\226\130\172',[137]='\226\128\176',[138]='\208\137',[139]='\226\128\185',
  [140]='\208\138',[141]='\208\140',[142]='\208\139',[143]='\208\143',[144]='\209\146',[145]='\226\128\152',
  [146]='\226\128\153',[147]='\226\128\156',[148]='\226\128\157',[149]='\226\128\162',[150]='\226\128\147',[151]='\226\128\148',
  [152]='\194\152',[153]='\226\132\162',[154]='\209\153',[155]='\226\128\186',[156]='\209\154',[157]='\209\156',
  [158]='\209\155',[159]='\209\159',[160]='\194\160',[161]='\209\142',[162]='\209\158',[163]='\208\136',
  [164]='\194\164',[165]='\210\144',[166]='\194\166',[167]='\194\167',[168]='\208\129',[169]='\194\169',
  [170]='\208\132',[171]='\194\171',[172]='\194\172',[173]='\194\173',[174]='\194\174',[175]='\208\135',
  [176]='\194\176',[177]='\194\177',[178]='\208\134',[179]='\209\150',[180]='\210\145',[181]='\194\181',
  [182]='\194\182',[183]='\194\183',[184]='\209\145',[185]='\226\132\150',[186]='\209\148',[187]='\194\187',
  [188]='\209\152',[189]='\208\133',[190]='\209\149',[191]='\209\151'
}
local utf8_decode={
  [128]={[147]='\150',[148]='\151',[152]='\145',[153]='\146',[154]='\130',[156]='\147',[157]='\148',[158]='\132',[160]='\134',[161]='\135',[162]='\149',[166]='\133',[176]='\137',[185]='\139',[186]='\155'},
  [130]={[172]='\136'},
  [132]={[150]='\185',[162]='\153'},
  [194]={[152]='\152',[160]='\160',[164]='\164',[166]='\166',[167]='\167',[169]='\169',[171]='\171',[172]='\172',[173]='\173',[174]='\174',[176]='\176',[177]='\177',[181]='\181',[182]='\182',[183]='\183',[187]='\187'},
  [208]={[129]='\168',[130]='\128',[131]='\129',[132]='\170',[133]='\189',[134]='\178',[135]='\175',[136]='\163',[137]='\138',[138]='\140',[139]='\142',[140]='\141',[143]='\143',[144]='\192',[145]='\193',[146]='\194',[147]='\195',[148]='\196',
    [149]='\197',[150]='\198',[151]='\199',[152]='\200',[153]='\201',[154]='\202',[155]='\203',[156]='\204',[157]='\205',[158]='\206',[159]='\207',[160]='\208',[161]='\209',[162]='\210',[163]='\211',[164]='\212',[165]='\213',[166]='\214',
    [167]='\215',[168]='\216',[169]='\217',[170]='\218',[171]='\219',[172]='\220',[173]='\221',[174]='\222',[175]='\223',[176]='\224',[177]='\225',[178]='\226',[179]='\227',[180]='\228',[181]='\229',[182]='\230',[183]='\231',[184]='\232',
    [185]='\233',[186]='\234',[187]='\235',[188]='\236',[189]='\237',[190]='\238',[191]='\239'},
  [209]={[128]='\240',[129]='\241',[130]='\242',[131]='\243',[132]='\244',[133]='\245',[134]='\246',[135]='\247',[136]='\248',[137]='\249',[138]='\250',[139]='\251',[140]='\252',[141]='\253',[142]='\254',[143]='\255',[144]='\161',[145]='\184',
    [146]='\144',[147]='\131',[148]='\186',[149]='\190',[150]='\179',[151]='\191',[152]='\188',[153]='\154',[154]='\156',[155]='\158',[156]='\157',[158]='\162',[159]='\159'},[210]={[144]='\165',[145]='\180'}
}

local nmdc = {
  [36]  = '$',
  [124] = '|'
}

local string, table = _G.string, _G.table
local floor = math.floor
local format, byte, char = string.format, string.byte, string.char
local concat, insert, unpack = table.concat, table.insert, _G.unpack or table.unpack

local snus_string = {}

--[[!MD
### Windows ANSI module

May be used for conversion between cp1251 (cyrillic) and utf8. May be useful if you're working on ru localed windows.
Have two functions:
```lua
string decoded = sstr.ansiToUtf8(string cp1251text[, bool skip_chars])`
string encoded = sstr.utf8ToAnsi(string utf8text[, bool skip_chars])`
```

If skip_chars is false, all characters that not fit encoding will be replaced to "?", skipped otherwise
]]
function snus_string:ansiToUtf8(skipchars)
	local s, r, b = self, ''

	for i = 1, s and s:len() or 0 do
		b = s:byte(i)
		if b < 128 then
			r = r..char(b)
		else
			if b > 239 then
				r = r..'\209'..char(b - 112)
			elseif b > 191 then
				r = r..'\208'..char(b - 48)
			elseif ansi_decode[b] then
				r = r..ansi_decode[b]
			else
				r = r..(skipchars and '' or '?')
			end
		end
	end
	return r
end

function snus_string:utf8ToAnsi(skipchars)
	local s, a, j, r, b = self, 0, 0, ''
	for i = 1, s and s:len() or 0 do
		b = s:byte(i)
		if b < 128 then
			if nmdc[b] then
				r = r..nmdc[b]
			else
				r = r..char(b)
			end
		elseif a == 2 then
			a, j = a - 1, b
		elseif a == 1 then
			a, r = a - 1, r..utf8_decode[j][b]
		elseif b == 226 then
			a = 2
		elseif b == 194 or b == 208 or b == 209 or b == 210 then
			j, a = b, 1
		else
			r = r..(skipchars and '' or '?')
		end
	end
	return r
end

--[[!MD
### URL module
Provides basic url encoding and decoding.

```lua
string encoded = sstr.urlencode(string text[, bool space_to_plus])`
string decoded = sstr.urldecode(string encoded_text[, bool space_to_plus])`
```
If space_to_plus is true, all space characters will be replaced to "+" like on url query, or to %20 otherwise. Same in decoding.
]]

local char_to_hex = function(c)
	return format("%%%02X", byte(c))
end

function snus_string:urlencode(space_to_plus)
	self = self:gsub("\n", "\r\n")
	self = self:gsub("([^%w ])", char_to_hex)
	self = self:gsub(" ", space_to_plus and "+" or "%%20")
	return self
end

local hex_to_char = function(x)
	return char(tonumber(x, 16))
end

function snus_string:urldecode(space_to_plus)
	if space_to_plus then
		self = self:gsub("+", " ")
	end
  self = self:gsub("%%(%x%x)", hex_to_char)
  return self
end

--[[!MD
### Unicode module
Provides manipulation of unicode and utf8 strings.

Contains sstring.charpattern key "[%z\1-\x7F\xC2-\xF4][\x80-\xBF]*" which is a template for a single utf8 character.
]]

--[[!MD
#### uchars
Unicode character iterator
```lua
for int endbyte, string u8char in sstr.uchars(string u8text) do
  print(endbyte, u8char)
end
```

Endbyte is byteindex of last byte of current char, have internal usage.
u8char is multibyte utf8 character as string.
All non utf8 charaters is skipped.
]]
snus_string.charpattern = "[%z\1-\x7F\xC2-\xF4][\x80-\xBF]*"

local cp = snus_string.charpattern
local function utf8_next(line, index)
	local a, b = line:find(cp, index + 1)
	if not a then return end
	return b, line:sub(a, b)
end

function snus_string:uchars()
	return utf8_next, self, 0
end
local uchars = snus_string.uchars

--[[!MD
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
]]
local function _utf8_next(line, index)
	local a, b = line:find(cp, index + 1)
	if not a then return end
	return a, b
end

function snus_string:uoffsets()
	return _utf8_next, self, 0
end
local uoffsets = snus_string.uoffsets

--[[!MD
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
]]
local function utf8_to_unicode(utf8str, pos)
	-- pos = starting byte position inside input string (default 1)
	pos = pos or 1
	local code, size = utf8str:byte(pos), 1
	if code >= 0xC0 and code < 0xFE then
		local mask = 64
		code = code - 128
		repeat
			local next_byte = utf8str:byte(pos + size) or 0
			if next_byte >= 0x80 and next_byte < 0xC0 then
				code, size = (code - mask - 2) * 64 + next_byte, size + 1
			else
				code, size = utf8str:byte(pos), 1
			end
			mask = mask * 32
		until code < mask
	end
	-- returns code, number of bytes in this utf8 char
	return code, size
end

local function escape_prefix(prefix)
	return prefix:gsub("[%+-]", "%%%1")
end

function snus_string:uencode(prefix)
	prefix = prefix or "\\u"
	local out = {}
	for i, c in uchars(self) do
		local code = utf8_to_unicode(c)
		insert(out, prefix)
		insert(out, code)
	end

	return table.concat(out)
end

local function unicode_to_utf8(code)
	-- converts numeric UTF code (U+code) to UTF-8 string
	code = tonumber(code)
	local t, h = {}, 128
	while code >= h do
		t[#t+1] = 128 + code%64
		code = floor(code/64)
		h = h > 32 and 32 or h/2
	end
	t[#t+1] = 256 - 2*h + code
	return char(unpack(t)):reverse()
end

function snus_string:udecode(prefix)
	prefix = escape_prefix(prefix or "\\u")
	return self:gsub(prefix .. "(%d+)", unicode_to_utf8)
end

--[[!MD
#### ubyte
Returns codepoint number by given index.

```lua
int codepoint = sstr.ubyte(u8string, int index)`
```
]]
function snus_string:ubyte(index)
	local c = uindex(self, index)
	return utf8_to_unicode(c)
end

--[[!MD
#### uchar
Returns utf8 string by given codepoint.

```lua
string char = sstr.uchar(int codepoint)`
```
]]
snus_string.uchar = unicode_to_utf8

--[[!MD
#### ulen
Returns length of utf8 string in characters.

```lua
int length = sstr.ulen(string u8text)`
```

Non utf8 chars is skipped.
]]
function snus_string:ulen()
	local len = 0
	for _ in uoffsets(self) do
		len = len + 1
	end
	return len
end
local ulen = snus_string.ulen

--[[!MD
#### ureverse
Returns reversed utf8 string.

```lua
string reversedu8text = sstr.ureverse(string u8text)`
```

Non utf8 chars is skipped.
]]
function snus_string:ureverse()
	if #self > 500 then
		local out, len = {}, 1
		for _, c in uchars(self) do
			out[len] = c
			len = len + 1
		end

		for i = 1, len / 2 do
			out[i], out[len - i] = out[len - i], out[i]
		end
		return concat(out)
	end

	local out = ""
	for _, c in uchars(self) do
		out = c .. out
	end
	return out
end

--[[!MD
#### usub
Returns substring of utf8 string.

```lua
string u8text = sstr.usub(string u8text, int firstchar, int lastchar)`
```

Should work exactly like string.sub but for utf8 characters
]]
local function _fastsub(self, a, b)
	local i = 1
	local start
	for oa, ob in uoffsets(self) do
		if i == a then
			if not b then
				return self:sub(oa)
			else
				start = oa
			end
		end
		if b and i == b then
			return self:sub(start, ob)
		end
		i = i + 1
	end
	if start then
		return self:sub(start)
	end
	return ""
end

function snus_string:usub(a, b)
	if a > 0 and (not b or (b > 0 and a <= b)) then
		return _fastsub(self, a, b)
	end

	local len = ulen(self)
	b = b or len

	if a < 0 then
		a = len + a + 1
	end
	if b < 0 then
		b = len + b + 1
	end
	if a > b then return "" end

	local i = 1
	local offstart
	for oa, ob in uoffsets(self) do
		if i == a then
			offstart = oa
		end
		if i == b then
			return self:sub(offstart, ob)
		end
		i = i + 1
	end
	if offstart then
		return self:sub(offstart)
	end
	return ""
end

--[[!MD
#### uindex
Returns utf8 char by index and it's start and end offsets
```lua
string u8char, int startoffset, int endbyteoffset = sstring.uindex(string u8text, int index)
```
]]
function snus_string:uindex(index)
	if index < 0 then
		local len = ulen(self)
		index = len + index + 1
		if index < 0 or index > len then
			return ""
		end
	end

	if index == 0 then
		local a, b = _utf8_next(self, 0)
		return self:sub(a, b), a, b
	end

	local i = 0
	for a, b in uoffsets(self) do
		i = i + 1
		if i >= index then
			return self:sub(a, b), a, b
		end
	end
	return "", -1, -1
end
local uindex = snus_string.uindex

--[[!MD
#### usanitize
Returns utf8 string without any non-utf8 character
```lua
string u8sanitazed = sstring.usanitize(string u8text)
```
]]
function snus_string:usanitize()
	local out, i = {}, 0
	for _, uchar in uchars(self) do
		i = i + 1
		out[i] = uchar
	end
	return table.concat(out)
end

--[[!MD
### Utility module
#### split

Returns table of string or several strings from given string
```lua
table splitted = sstring.split(string text[, string separator, bool unpack_result, bool isregex])
```
This function is optimized for performance, so default separator should be plain text, but it is possible to specify the interpretation of the separator as a regex using isregex arg.

Examples:
```lua
splitted = sstring.split("Hello,world")
--> {"Hello", "World"}

a, b = sstring.split("Hello world", " ", true)
--> a == "Hello"; b == "world"

splitted = sstring.split("   ❤️Hello   ❤️ world❤️  !", "%s*❤️%s*", false, true)
--> {"", Hello", "world", "!"}

```
]]
function snus_string:split(sep, unp, regex)
	sep = sep or ","
	local lsep = #sep
	local out = {}
	local a, b, c, i, _ = 1, #self, nil, 1
	c, b = self:find(sep, 1, not regex)

	while a and b do
		out[i] = self:sub(a, c - 1)
		a, i = b + 1, i + 1
		c, b = self:find(sep, a, not regex)
	end

	out[i] = self:sub(a)

	if unp then
		return unpack(out) or out
	end
	return out
end
local split = snus_string.split

--[[!MD
#### slice

Returns one or several chunks of separate formatted string
```lua
table slice = sstring.slice(string text, int startindex, int endindex, string separator[, bool unpack_result])
```
]]
function snus_string:slice(i, j, sep, unp)
	local list = split(self, sep)

	i, j = i or 1, j or #list
	i = i < 0 and #list + i     or i
	j = j < 0 and #list + j + 1 or j

	local out = {}
	for i = i, j do
		out[#out + 1] = list[i]
	end
	if unp then
		return unpack(out) or out
	end
	return out
end

--[[!MD
#### swap

Returns a string in which all occurrences of [from] are replaced by [to] strings. Works like string.gsub but without pattern matchmaking.
```lua
string swapped = sstring.swap(string text, string from, string to)
```
]]
function snus_string.swap(text, from, to)
	local out = {}
	local last = 0
	local a, b = text:find(from, 0, true)
	while a do
		out[#out + 1] = text:sub(last, a - 1)
		out[#out + 1] = to
		last = b + 1
		a, b = text:find(from, last, true)
	end
	
	out[#out + 1] = text:sub(last)
	return table.concat(out)
end

--[=[!MD
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
]=]
local huge, min = math.huge, math.min
function snus_string:bfind(head, tail, offset, ex_bounds, plain)
	local header_start, header_end = self:find(head, offset or 1, plain)
	if not header_start then return nil end
	local cursor  = header_end
	local last_tail_start = 0
	local counter = 1
	while counter > 0 do
		local ha, hb = self:find(head, cursor + 1, plain)
		if not ha then ha, hb = huge, huge end
		local ta, tb = self:find(tail, cursor + 1, plain)
		if not ta then return nil end
		counter = counter + (ha < ta and 1 or -1)
		cursor = min(hb, tb)
		last_tail_start = ta
	end
	if ex_bounds then
		local a, b = header_end + 1, last_tail_start - 1
		return self:sub(a, b), a, b
	end
	return self:sub(header_start, cursor), header_start, cursor
end

--[[!MD
#### lines
Lines iterator
```lua
for string line, table info in sstr.lines(string text[, string separator]) do
	print(line, info.str, info.index, info.sep)
end
```

Default separator is "\r?\n"
]]
local function str_lines(str, args)
	if str.str then -- lua reverses args after string:lines but not reverses after str_lines
		args = str
		str = args.str
	end

	local strlen, index, sep = #str, args.index, args.sep
	if index == strlen then return end

	local a, b = str:find(sep, index)

	if not a then
		args.index = strlen
		return str:sub(index), args
	end

	args.index = b + 1

	return str:sub(index, a - 1), args
end

function snus_string:lines(sep)
	local args = {str = self, index = 0, sep = sep or "\r?\n"}

	return str_lines, args
end
local lines = snus_string.lines

--[[!MD
#### field
Returns one line (or field) by index
```lua
string field = sstr.field(string text, string separator, int index)
```

Default separator is "\r?\n"
]]
function snus_string:field(sep, index)
	local curr = 0
	for line in lines(self, sep) do
		curr = curr + 1
		if curr == index then return line end
	end
	return ""
end

--[[!MD
#### trim
Cuts given characters from front and back of text
```lua
string trimmed = sstr.trim(string text, string charset)
```
Default set of trimming characters is "\r\n%s"
]]
function snus_string:trim(chars)
	chars = chars or "\r\n "
	return self:match("^[" .. chars .. "]*(.-)[" .. chars .. "]*$")
end

--[[!MD
#### starts
Checks if a string starts with the given pattern.
```lua
bool isStarts = sstr.starts(string text, string pattern[, bool isRegex])
```
]]
function snus_string:starts(pattern, re)
	if re then return self:find("^"..pattern) end
	return pattern == '' or self:sub(1, #pattern) == pattern
end

--[[!MD
#### ends
Checks if a string ends with the given pattern.
```lua
bool isEnds = sstr.ends(string text, string pattern[, bool isRegex])
```
]]
function snus_string:ends(pattern, re)
	if re then return self:find(pattern .. "$") end
	return pattern == '' or self:sub(-#pattern) == pattern
end

--[[!MD
#### cat
Concatenates everything into one string.
```lua
string concatted = sstr.cat(string text1[, string text2, string text3, ...])
```
]]
function snus_string:cat(...)
	self = tostring(self)
	local n = select('#', ...)
	if n == 1 then return self end
	if n == 2 then
		return self .. tostring((...))
	end
	return concat{self, ...}
end

--[[!MD
#### concat
Same as cat but with separator.
```lua
string concatted = sstr.concat(string text1[, string text2, string text3, ...], string separator)
```
]]
function snus_string:concat(...)
	self = tostring(self)
	local n = select('#', ...)
	if n == 0 then return self end
	local sep = assert(select(n, ...), "Separator (last argument) should be given")

	if n == 1 then return self end
	if n == 2 then
		return self .. sep .. tostring((...))
	end
	local out = {self}
	for i = 1, n - 1 do
		out[i + 1] = tostring( select(i, ...) )
	end
	return concat(out, sep)
end

--[[!MD
#### import
Adds all string function from library to `string` table.
```lua
sstring.import([bool redefine])
```

If redefine is set to true, the library will be forced to be imported with method overrides.
Otherwise, it will raise an error for already existing functions.
]]
function snus_string.import(redefine)
	for k, v in pairs(snus_string) do
		if string[k] and string[k] ~= v then
			if not redefine then
				error("Redefining of [", k, "] string method")
			end
		end
		string[k] = v
	end
end

if ... then
	return snus_string
end

if package.config:sub(1, 1) == "\\" then
	os.execute("chcp 65001")
end

print(snus_string.uchar(0x042B))