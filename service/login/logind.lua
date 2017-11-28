local skynet = require "skynet"
local socket = require "socket"

local crypt = require "skynet.crypt"

local log = require "helper.log"
local protopack = require "helper.protopack"

local traceback = debug.traceback

local message_version = 0
--loginmanager
local lmanager
--时间--
local auth_timeout
local session_expire_time
local session_expire_time_in_second
--
local database
local host

local connection = {}
local saved_session = {}

local slaved = {}

--socket相关------------------------------------------
local function close (fd)
	if connection[fd] then
		socket.close (fd)
		connection[fd] = nil
	end
end

local function read (fd, size)
	return socket.read (fd, size) or error ()
end

local function read_msg (fd)
	local s = read (fd, 2)
	local size = s:byte(1) * 256 + s:byte(2)
    local data = read (fd, size)
	local name, msg = protopack.unpack(data)
end

local function send_msg(fd, name, msg)
	local data = protopack.pack(name, msg)
	socket.write(fd, data)
end


local function read_msg_encrypt (fd)
	local s = read (fd, 2)
	local size = s:byte(1) * 256 + s:byte(2)
    local data = read (fd, size)
	local name, msg = protopack.unpack(data)
end

local function send_msg_encrypt(fd, name, msg)
	local data = protopack.pack(name, msg)
	socket.write(fd, data)
end

--CMD相关------------------------------------------
local CMD = {}
--初始化--
function CMD.init (m, id, conf)
	lmanager = m
	database = skynet.uniqueservice ("database")

	message_version = conf.message_version
	auth_timeout = conf.auth_timeout * 100
	session_expire_time = conf.session_expire_time * 100
	session_expire_time_in_second = conf.session_expire_time
end

--开始登录流程--
function CMD.auth (fd, addr)
	connection[fd] = addr
	skynet.timeout (auth_timeout, function ()
		if connection[fd] == addr then
			log.warningf ("connection %d from %s auth timeout!", fd, addr)
			close (fd)
		end
	end)

	socket.start (fd)
	socket.limit (fd, 8192)
	
	local _serverkey = crypt.base64encode(crypt.randomkey())
	local _clientkey = ""
	--step1:s2c Login.Hello (serverkey base64)
	send_msg (fd,"Login.Hello",{serverkey = _serverkey})
	log.errf("step1:s2c Login.Hello:%s",_serverkey)
	
	--step2:c2s Login.Version (clientkey base64)
	local name, msg = read_msg (fd)
	log.errf("step2:c2s Login.Version:%s",msg.version)
	if name == "Login.Version" then
		if(msg.version >= message_version) and msg.clientkey then
			_clientkey = msg.clientkey
			--step3:s2c Login.Encryption 
			--(验证成功，可以开始登录流程；从step4开始的流程都使用serverkey和clientkey加密)
			send_msg (fd,"Login.Encryption",{encryption = "hello,w"})
			log.errf("step3:s2c Login.Encryption:%s",encryption)
			
			--step4:c2s Login.Signin
			name, msg = read_msg_encrypt (fd)
			assert (name == "Login.Signin" and msg, "Login.Signin Error")
			log.errf("step4:c2s Login.Signin:%s,%s",msg.name,msg.password)
			--去数据库读取帐号信息
			local account = skynet.call (database, "lua", "get", "account", msg.name) or error ("load account " .. msg.name .. " failed")
			if(account.id ~= nil and account.password == msg.password) then
				--step5:s2c登录成功
				log.errf("login ok:%s",name)
			else
				send_msg (fd,"Login.Error",{code = 200})--帐号密码错误				
			end
		else
			send_msg (fd,"Login.Error",{code = 100})--版本验证错误
		end
	end

	assert (name == "challenge")
	assert (args and args.session and args.challenge)

	local token, challenge = skynet.call (lmanager, "lua", "challenge", args.session, args.challenge)
	assert (token and challenge)

	local msg = response {
			token = token,
			challenge = challenge,
	}
	send_msg (fd, msg)

	close (fd)
end

function CMD.save_session (session, account, key, challenge)
	saved_session[session] = { account = account, key = key, challenge = challenge }
	skynet.timeout (session_expire_time, function ()
		local t = saved_session[session]
		if t and t.key == key then
			saved_session[session] = nil
		end
	end)
end

function CMD.challenge (session, secret)
	local t = saved_session[session] or error ()

	local text = aes.decrypt (secret, t.key) or error ()
	assert (text == t.challenge)

	t.token = srp.random ()
	t.challenge = srp.random ()

	return t.token, t.challenge
end

function CMD.verify (session, secret)
	local t = saved_session[session] or error ()

	local text = aes.decrypt (secret, t.key) or error ()
	assert (text == t.token)
	t.token = nil

	return t.account
end

--start------------------------------------------
skynet.start (function ()
	skynet.dispatch ("lua", function (_, _, command, ...)
		local function pret (ok, ...)
			if not ok then 
				log.warningf (...)
				skynet.ret ()
			else
				skynet.retpack (...)
			end
		end

		local f = assert (CMD[command])
		pret (xpcall (f, traceback, ...))
	end)
end)

