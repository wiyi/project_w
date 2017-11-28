local skynet = require "skynet"
require "skynet.manager"

local util = require "helper.util"
local log = require "helper.log"
local config = require "config.proto"

local protobuf = require "protobuf"

local cmd = {}

function cmd.init()
	for _,v in ipairs(config.pb_files) do
		util.print(protobuf.register_file(v))
	end
end

function cmd.encode(msg_name, msg)
	skynet.error("encode"..msg_name)
	util.print(msg)
	return protobuf.encode(msg_name, msg)
end

function cmd.decode(msg_name, data)
	skynet.error("decode ".. msg_name.. " " .. type(data) .." " .. #data)
	return protobuf.decode(msg_name, data)
end

function cmd.test()
	skynet.error("pbc test...")
	local msg = {account = "name"}
	util.print("msg = ",msg)
	skynet.error("encode")
	local data = cmd.encode("Login.Login", msg)
	skynet.error("decode"..#(data))
	local de_msg = cmd.decode("Login.Login", data)
	skynet.error(de_msg.account)
end

skynet.start(function ()
	skynet.error("init pbc...")
	cmd.init()

	skynet.dispatch("lua", function (session, address, command, ...)
		local f = cmd[command]
		if not f then
			skynet.ret(skynet.pack(nil, "Invalid command" .. command))
		end

		if command == "decode" then
			local name
			local buf
			name,buf = ...
			skynet.ret(skynet.pack(cmd.decode(name,buf)))
			return
		end
		local ret = f(...)
			skynet.ret(skynet.pack(ret))
	end)

	skynet.register("pbc")
end)
