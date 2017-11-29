local skynet = require "skynet"
local socket = require "skynet.socket"
local log = require "helper.log"
local config = require "config.base"

--logind列表
local logind_list = {}
--logind数量
local logind_count = 1

--CMD相关--
local CMD = {}

--open--
function CMD.open (conf)	
	for i = 1, conf.count do
		local s = skynet.newservice ("logind")
		skynet.call (s, "lua", "init", skynet.self (), i, conf)
		table.insert (logind_list, s)
	end
	logind_count = #logind_list

	local host = conf.host or "0.0.0.0"
	local port = assert (tonumber (conf.port))
	local sock = socket.listen (host, port)

	log.noticef ("listen on %s:%d", host, port)

	--均衡？--
	local balance = 1
	socket.start (sock, function (fd, addr)
		local s = logind_list[balance]
		balance = balance + 1
		if balance > logind_count then balance = 1 end

		skynet.call (s, "lua", "auth", fd, addr)
	end)
end

skynet.start (function ()
	skynet.dispatch ("lua", function (_, _, command, ...)
		local f = assert (CMD[command])
		skynet.retpack (f (...))
	end)
end)
