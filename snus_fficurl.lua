local ffi = require'ffi'
local curl = require"libcurl"

local uri = {}

function uri.char_to_hex(c)
  return string.format("%%%02X", string.byte(c))
end

function uri.hex_to_char(x)
  return string.char(tonumber(x, 16))
end

function uri.encode(u)
  if u == nil then
    return
  end
	u = tostring(u)
  u = u:gsub("\n", "\r\n")
  u = u:gsub("([^%w ])", uri.char_to_hex)
  u = u:gsub(" ", "+")
  return u
end


function uri.decode(u)
  if u == nil then
    return
  end
	u = tostring(u)
  u = u:gsub("+", " ")
  u = u:gsub("%%(%x%x)", uri.hex_to_char)
  return u
end



ffi.cdef[[
  void Sleep(int ms);
  int poll(struct pollfd *fds, unsigned long nfds, int timeout);
	
	typedef struct { int index; } curl_index;
]]

local sleep
if ffi.os == "Windows" then
  function sleep(s)
    ffi.C.Sleep(s*1000)
  end
else
  function sleep(s)
    ffi.C.poll(nil, 0, s*1000)
  end
end

local http = {
	encode = uri.encode, 
	decode = uri.decode, 
	sleep = sleep
}

local multi = curl.multi{
	-- CURLOPT_SSL_VERIFYPEER = false,
  -- CURLOPT_RETURNTRANSFER = true,
  -- CURLOPT_TIMEOUT        = 10
}

--multi:timeout(0.5)

local REQUESTS = {}
local function keys(t)
	local n = 0
	for k, v in pairs(t) do
		n = n + 1
	end
	return n
end

local function render(t)
	local res = {"{"}
	for k, v in pairs(t) do
		res[#res + 1] = "    " .. tostring(k) .. " = " .. tostring(v)
	end
	res[#res + 1] = "}"
	
	return table.concat(res, "\r\n")
end

function REQUESTS:update(timeout)
	--print("MULTIWAIT ")
	--multi:wait(timeout or 1)
	--print("MULTIPERFORM", keys(REQUESTS), render(REQUESTS))
	local transfers = multi:perform()
	--print("MULTIPERFORMDONE", transfers)
	local results, queue = multi:info_read()
	--print("REQ UPDAte", results, queue)
	if results then
		local info = results
		local strkey = tostring(info.easy_handle):match("0x%x+")
		local response = REQUESTS[strkey]
		response.body = table.concat(response.body)
		response.done = true
		
		--print("REQ INFO ", info.msg, info.easy_handle, response, info.data.result)
		
		multi:remove(info.easy_handle)
		response.etr:close()
		response.etr = nil
		REQUESTS[strkey] = nil
	end
	
	return transfers > 0 and transfers
end


local request_meta = {}
function request_meta:isDone()
	REQUESTS:update(0)
	
end


--[[
request = {
	url = "http://example.com",
	method = "get",
	headers = {
		["Content-Type"] = "application/json"
	},
	
	
	bodyfile = "c:\\file.txt",
	outfile = "c:\\out_file.txt",
	curlopt = {
		noprogress = 1,
		sslcert = "mycert.pem",
		sslkey = "mykey.pem",
		keypasswd = "s3cret",
		cookie = "mycookie",
		cookiefile = 
	},
	
	
}


async response = {
	done = true,
	headers = {
		["Content-Type"] = "plain/text"
	},
	body = "abcdef",
	code = 200,
	status = "OK"
}
]]

function http.request(url, body)
	local response = {code = 0, status = "", body = {}, headers = {}, progress = 0, url = url}
	local request = type(url) == 'table' and url or {url = url, body = body}
	request.headers = request.headers or {}

	
	local curlopt = {}
	curlopt.url = assert(request.url, "Arg 1 URL required")
	curlopt.noprogress = curlopt.noprogress or 1
	curlopt.maxfilesize = request.maxfilesize or 1024*1024*1024 -- 1gb
	
		-- POST BODY STUFF
	if request.body or request.bodyfile then
		local body = request.body
		local headers = request.headers
		local bodytype = type(body)
		request.method = request.method or "POST"

		if bodytype == "string" or bodytype == "table" then
			if bodytype == "string" then
				headers['Content-Type'] = headers['Content-Type'] or "text/plain"
			elseif bodytype == "table" then
				headers['Content-Type'] = headers['Content-Type'] or "application/x-www-form-urlencoded"
				local form = {}
				for key, value in pairs(body) do
					local tk, tv = type(key), type(value)
					assert(tk == "string" or tk == "number", "POST string key required")
					assert(tv == "string" or tv == "number", "POST string value required")
					form[#form + 1] = uri.encode(key) .. "=" .. uri.encode(value)
				end
				body = table.concat(form, "&")
			end
			
			headers['Content-Length'] = #body
			
			local cursor = 1
			function curlopt.readfunction(outptr, size, nmemb)
				local bufsize = tonumber(size * nmemb)
				local chunk = body:sub(cursor, cursor + bufsize - 1)
				ffi.copy(outptr, chunk, #chunk)
				cursor = cursor + #chunk
				return #chunk
			end
		elseif bodytype == "nil" and request.bodyfile then
			local bodyfile = io.open(request.bodyfile, "rb+")
			local filesize = bodyfile:seek("end")
			bodyfile:seek("set", 0)
			
			headers['Content-Type'] = headers['Content-Type'] or "application/octet-stream"
			headers['Content-Length'] = filesize
			
			function curlopt.readfunction(outptr, size, nmemb)
				local bufsize = tonumber(size * nmemb)
				local chunk = bodyfile:read(bufsize)
				if not chunk or (#chunk == 0) then 
					bodyfile:close(); return 0 
				end
				print("READFUNC", bufsize, chunk and chunk:sub(1, 10))
				ffi.copy(outptr, chunk, #chunk)
				return #chunk
			end
		end
	end
	
	-- HEADERS STUFF
	if next(request.headers) then
		curlopt.httpheader = {}
		for k, v in pairs(request.headers) do
			table.insert(curlopt.httpheader, k .. ": " .. v)
		end
	end
	
	if request.proxy then
		curlopt.proxy = request.proxy
	end
	
	if request.timeout then
		curlopt.timeout = request.timeout
	end
	
	if request.range then
		local range = request.range
		if type(range) == "table" then
			curlopt.range = tonumber(range[1]) .. "-" .. tonumber(range[2])
		elseif type(range) == "string" then
			curlopt.range = range
		end
	end
	
	if request.allowredirect then
		curlopt.followlocation = 1
	end
	
	curlopt.noprogress = 1
	
	if request.method then
		local method = request.method:upper()
		if method == "GET" then
			curlopt.httpget = 1
		elseif method == "POST" then
			curlopt.post = 1
		elseif method == "PUT" then
			curlopt.put = 1
		end
	end
	
	-- CURLOPTS
	if request.curlopt then
		for k, v in pairs(request.curlopt) do
			curlopt[k] = v
		end
	end
	
	function curlopt.xferinfofunction(clientp, total, now, utotal, unow)
		print("PROGRESS", clientp, total, now, utotal, unow)
		return 0
	end
	
	curlopt.progressfunction = curlopt.xferinfofunction
	
	curlopt.verbose = 1
	function curlopt.debugfunction(handle, type, data, size) 
		if type == 0 or type == 7 then
			response.info = ffi.string(data, size)
			--print("DEBUG", response.info:gsub("\r\n", " "))
		end
		return 0
	end
	
	function curlopt.writefunction(data, size)
		--print("WRITEFUNC", data, size)
		if request.writefunction then
			request.writefunction(ffi.string(data, size))
		else
			table.insert(response.body, ffi.string(data, size))
		end
		return size
	end
	
	if request.outfile then
		function curlopt.writefunction(data, size)
			local file = io.open(request.outfile, "ab+")
			local range = (response.headers["Content-Range"] or ""):match("bytes: (%d+)")
			if range then
				file:seek("set", tonumber(range))
			end
			file:write(ffi.string(data, size))
			file:close()
			return size
		end
	end
	
	function curlopt.headerfunction(data, size)
		--print("HEADER: ", data, size, ffi.string(data, size))
		local line = ffi.string(data, size)
		
		local key, value = line:match("(.-): (.*)")
		if key then
			response.headers[key] = value
		elseif line:find("^HTTP.-") then
			local proto, status, descr = line:match("(.-) (.-) (.-)[\r\n]*$")
			response.proto = proto
			response.code = tonumber(status)
			response.status = descr
		end
		return size
	end
	
	response.etr = curl.easy(curlopt)
	
	if request.routine then
		local co, isMain = coroutine.running()
		if not co or (co and isMain) then 
			error("Request: routine mode should be called inside coroutine")
		end
		
		multi:add(response.etr)
		local strkey = tostring(response.etr):match("0x%x+")
		REQUESTS[strkey] = response
		response.isDone = function()
			REQUESTS:update(0)
			return response.done
		end
		
		while not response:isDone() do
			--print(os.clock(), "UPDATE routine", response.etr)
			coroutine.yield()
		end
		
		return response.body, response.status, response.headers
	end
	
	--print("CONF REQUEST", require'inspect'(curlopt))
	if request.async then
		multi:add(response.etr)
		local strkey = tostring(response.etr):match("0x%x+")
		REQUESTS[strkey] = response
		response.isDone = function()
			REQUESTS:update(0)
			return response.done
		end
		return response
	end
	
	local etr, err, code = response.etr:perform()
	if not etr then
		return nil, err, code
	end

	response.etr:close()
	
	return request.outfile or table.concat(response.body), response.status, response.headers
end



if ... then return http end


local res1 = http.request{
	url = "https://www.gamasutra.com/db_area/images/news/312469/2_Cruncher.gif", 
	async = true, 
	allowredirect = true, 
	proxy = "9jdJCG:YNHy1h@193.31.101.133:9575"
}
while not res1:isDone() do
	
end
--local res2 = http.request{url = "https://yandex.ru", async = true}
print(require'inspect'(res1))


requests = {}
for i = 1, 5 do
	requests[i] = http.request{url = "https://www.gamasutra.com/db_area/images/news/312469/2_Cruncher.gif", outfile = "f:\\log\\opts.gif", async = true, allowredirect = false}
end

local alldone = false
while not alldone do
	alldone = true
	for i, req in ipairs(requests) do
		if not req:isDone() then alldone = false end
	end
end

print("DONE REQUESTS:", require'inspect'(REQUESTS))

--print("mperf", multi:perform())

--res.etr:perform()

print("RESILT1", require'inspect'(requests[1]))
-- print("RESILT2", require'inspect'(res2))



