local route66 = require "route66"
local http = require "luanode.http"
local fs = require "luanode.fs"

local server = http.createServer(function(self, request, response)
	response:writeHead(200, {["Content-Type"] = "text/plain"})
	response:finish("Unhandled request")
end)

local function wrap(f)
	return function (req, res)
		if req.headers.accept == "text/event-stream" then
			f(req, res)
		else
			res:writeHead(200, { ["Content-Type"] = "text/plain",
								["Cache-Control"] = "no-cache"
						})
			res:finish("go away")
		end
	end
end

local router = route66.new()

router:get("/time", wrap(function(req, res)
	res:writeHead(200, { ["Content-Type"] = "text/event-stream",
						["Cache-Control"] = "no-cache",
						["Connection"] = "keep-alive",
						})

	res:write("id\n\n")
	setInterval(function()
		res:write("data: "..os.date("%H:%M:%S").."\n\n")
	end, 1000)
end))

router:get("/stream", wrap(function(req, res)
	res:writeHead(200, { ["Content-Type"] = "text/event-stream",
						 ["Cache-Control"] = "no-cache",
						 ["Connection"] = "keep-alive",
						})
				
	res:write("id\n\n")

	setInterval(coroutine.wrap(function()
		local steps = 1000
		while true do
			for i = 0, steps do
				local result = math.floor(math.abs(math.cos(i / steps * 2 * math.pi) * 100))
				res:write("event: amplitude\ndata: "..result.."\n\n")
				coroutine.yield()
			end
		end
	end), 100)
end))

router:get("/main", function(req, res)
	res:writeHead(200, { ["Content-Type"] = "text/html"})

	fs.readFile("main.html", function(err, data)
		res:finish(data)
	end)
end)

server:listen(8124)

router:bindServer(server)

console.log("Server running at http://127.0.0.1:8124/")
console.log("Now go to http://127.0.0.1:8124/main")

process:loop()
