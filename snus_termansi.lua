

local term = {}
term.pattern = {
	"\27[%s",
	"\27[%d%s",
	"\27[%d;%d%s",
	"\27[%d;%d;%d%s",
	"\27[%d;%d;%d;%d%s",
	"\27[%d;%d;%d;%d;%d%s",
}

term.csi = "\0x1B0x5B" -- \27[
term.write = io.write

function term.altwrite(...)
	return ...
end

function term.fmt(...)
	local n = select("#", ...)
	local p = assert(term.pattern[n], "Too many arguments: "..tostring(n))
	return p:format(...)
end

-- Cursor positioning
function term.cursorUp(n)
	return term.write(term.fmt(n or 0, "A")) -- \271A
end

function term.cursorDown(n)
	return term.write(term.fmt(n or 0, "B")) -- \271B
end

function term.cursorForward(n)
	return term.write(term.fmt(n or 0, "C")) -- \271C
end

function term.cursorBack(n)
	return term.write(term.fmt(n or 0, "D")) -- \271D
end

function term.cursorNextLine(n)
	return term.write(term.fmt(n or 0, "E")) -- \271E
end

function term.cursorPreviousLine(n)
	return term.write(term.fmt(n or 0, "F")) -- \271F
end

function term.cursorHorizontalAbsolute(n)
	return term.write(term.fmt(n or 0, "G")) -- \271G
end

function term.cursorVerticalAbsolute(n)
	return term.write(term.fmt(n or 0, "d")) -- \271G
end

function term.cursorPosition(x, y)
	return term.write(term.fmt(y or 0, x or 0, "H")) -- \270;0H
end

function term.cursorHorizontalVerticalPosition(x, y)
	return term.write(term.fmt(y or 0, x or 0, "f")) -- \270;0f
end

function term.saveCursor()
	return term.write(term.fmt("s")) -- \27s
end

function term.restoreCursor()
	return term.write(term.fmt("u")) -- \27u
end

-- Cursor visibility
function term.textCursorEnableBlinking()
	return term.write("\27[?12h")
end

function term.textCursorDisableBlinking()
	return term.write("\27[?12l")
end

function term.textCursorEnableModeShow()
	return term.write("\27[?25h")
end

function term.textCursorDisableModeShow()
	return term.write("\27[?25l")
end

-- Cursor shape

function term.cursorUserShape()
	return term.write("\27[0 q")
end

function term.cursorBlinkingBlock()
	return term.write("\27[1 q")
end

function term.cursorSteadyBlock()
	return term.write("\27[2 q")
end

function term.cursorBlinkingUnderline()
	return term.write("\27[3 q")
end

function term.cursorSteadyUnderline()
	return term.write("\27[4 q")
end

function term.cursorBlinkingBar()
	return term.write("\27[5 q")
end

function term.cursorSteadyBar()
	return term.write("\27[5 q")
end

-- Viewport positioning
function term.scrollUp(n)
	return term.write(term.fmt(n or 0, "S")) -- \270S
end

function term.scrollDown(n)
	return term.write(term.fmt(n or 0, "T")) -- \270T
end

-- Text modification
function term.insertCharacter(n)
	return term.write(term.fmt(n or 0, "@")) -- \270@
end

function term.deleteCharacter(n)
	return term.write(term.fmt(n or 0, "p")) -- \270p
end

function term.eraseCharacter(n)
	return term.write(term.fmt(n or 0, "X")) -- \270X
end

function term.insertLine(n)
	return term.write(term.fmt(n or 0, "L")) -- \270L
end

function term.deleteLine(n)
	return term.write(term.fmt(n or 0, "M")) -- \270M
end

function term.erase(n)
	return term.write(term.fmt(n or 0, "J")) -- \270J
end

function term.eraseInLine(n)
	return term.write(term.fmt(n or 0, "K")) -- \270K
end



local colors = {
	black    = 30,
	red      = 31,
	green    = 32,
	yellow   = 33,
	blue     = 34,
	magenta  = 35,
	cyan     = 36,
	white    = 37,
	default  = 39,
	
	bright_black    = 90,
	bright_red      = 91,
	bright_green    = 92,
	bright_yellow   = 93,
	bright_blue     = 94,
	bright_magenta  = 95,
	bright_cyan     = 96,
	bright_white    = 97,
}

local codes = {
	


}

function term.setGraphicsRendition(opts)
	if not opts then return term.write("\27[0m") end
	local res = {}
	local insert = table.insert
	
	local fg = opts.foreground
	if fg then
		if type(fg) == "number" then -- Set color to <n> index in 88 or 256 color table*
			insert(res, 38)
			insert(res, 5)
			insert(res, fg)
		elseif type(fg) == "string" then
			insert(res, assert(colors[fg], "No color " .. fg))
		elseif type(fg) == "table" then
			insert(res, 38)
			insert(res, 2)
			insert(res, assert(fg[1]))
			insert(res, assert(fg[2]))
			insert(res, assert(fg[3]))
		end
	end
	
	local bg = opts.background
	if bg then
		if type(bg) == "number" then
			insert(res, 48)
			insert(res, 5)
			insert(res, bg)
		elseif type(bg) == "string" then
			insert(res, assert(colors[bg], "No color " .. bg) + 10)
		elseif type(bg) == "table" then
			insert(res, 48)
			insert(res, 2)
			insert(res, assert(bg[1]))
			insert(res, assert(bg[2]))
			insert(res, assert(bg[3]))
		end
	end

	insert(res, opts.bold      and 1 or 22)
	insert(res, opts.underline and 4 or 24)
	insert(res, opts.negative  and 7 or 27)

	return term.write("\27[" .. table.concat(res, ";") .. "m")
end

if ... then
	return term
end

os.execute("chcp 65001 > nul")
print("Foo")


local sleep = require'socket'.sleep


local r, g, b = 50, 50, 50
for i = 0, 990 do
	if i % 5 == 0 then 
		term.scrollUp()
	end
	term.setGraphicsRendition{
		background = {r, g, b}, 
		foreground = {g, b, r},
		bold = math.floor(i / 10) % 2 == 0
	}
	io.write("Hello!")
	r = r + 1; g = g - 1; b = b + 2
	if r > 255 then r = 0 end
	if g < 0 then g = 255 end
	if b > 255 then b = 0 end
	sleep(.03)
end