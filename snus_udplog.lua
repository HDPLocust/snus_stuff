local socket = require'socket'

local function gettime()
	local time = socket.gettime()
	local msec = time - math.floor(time)
	local date = os.date("%d.%m.%y-%X", time)
	return ("%-21s"):format(date .. "." .. math.floor(msec * 300))
end

local function getFamilyHostName(address, family)
	family = family or "inet"
	local data = socket.dns.getaddrinfo(address)
	for i, v in ipairs(data) do
		if v.family == family then
			return v.addr
		end
	end
end

local function isIPv4(address)
	return not not address:find("^%d+%.%d+%.%d+%.%d+$")
end

local function isIPv6(address)
	if not address:find(":") then return false end
	
	local _, count = address:gsub("::", "")
	if count > 1 then return false end

	local segments = 0
	for part in address:gmatch("([^:]+)") do
		if not part:match("^%x?%x?%x?%x$") then return false end
		segments = segments + 1
	end
	return segments <= 8
end

local function server(host, port, family)
	host = host or "*"
	port = port or 4096
	family = family or "inet"
	local mode = family == "inet6" and "udp6" or "udp4"
	local udp = (socket[mode] or socket.udp)()
	
	assert(udp:setsockname(host, port))
	--udp:listen()
	
	return function()
		local msg, host, port = udp:receivefrom()
		print(gettime() .. " " .. host .. ":" .. port .. " > " .. msg)
	end, udp:getsockname()
end

local function client(host, port, family)
	family = family or (isIPv6(host) and "inet6") or "inet"
	host = host or family == "inet" and "127.0.0.1" or "::1"
	port = port or 4096
	local mode = family == "inet6" and "udp6" or "udp4"
	local udp = (socket[mode] or socket.udp)()

	if not isIPv4(host) and not isIPv6(host) then
		host = getFamilyHostName(host, family)
	end
	
	local mode = family == "inet6" and "udp6" or "udp4"
	local udp = (socket[mode] or socket.udp)()
	udp:setpeername(host, port)
	-- print("sock stats: ", udp:getpeername())
	
	return function(...)
		local msg = ""
		for i = 1, select("#", ...) do
			msg = msg .. "\t" .. tostring(select(i, ...))
		end
		udp:send(msg)
	end
end

if (... or ""):find("udplog") then
	return {
		server = server,
		client = client
	}
end

local help = [[
This is application + library for udp logging
Server usage: 
lua snus_udplog.lua [options]

options for server app:
-help - print this
-h example.com/127.0.0.1/::1     host address binds address to, default is "*" i.e. any.
-p 4096                          listening port
-f inet/inet6                    address family, inet is default.

Also server is available as library with same arguments.

Client usage:
local udplog = require'snus_udplog'

-- default host is "127.0.0.1" or "::1" if selected family is "inet6"
-- default port is 4096
-- default family is "inet"
local log = udplog.client([host, port, family])

log("Hello!", "from", "application!")
]]


local host, port, family
local a = {}
for i, v in ipairs(arg) do
	if v == "help" or v == "-help" or v == "/help" or v == "/?" then
		return print(help)
	end
	
	if v == "h" or v == "-h" or v == "/h" then
		host = assert(arg[i + 1], "Host address should be given")
	end

	if v == "p" or v == "-p" or v == "/p" then
		local p = assert(tonumber(arg[i + 1]), "Port should be given")
		assert(p > 0 and p < 65535, "Port should be in 1-65535 range")
		port = p
	end
	
	if v == "f" or v == "-f" or v == "/f" then
		local f = assert(arg[i + 1], "Network family should be given")
		assert(f == "inet" or f == "inet6", "Family should be inet or inet6")
		family = f
	end
end

local server, host, port = server(host, port, family)
--host = socket.dns.toip("")
print("listen [" .. host .. " - " .. port .. "]")

while 1 do
	server()
end