local skynet = require "skynet"

local CMD = {}
local SOCKET = {}
local gate
local pool = {}

local agents = {}

--service start------------------------------------------
skynet.start(function()
	skynet.error("gatemanager---->>start")
    --注册socket处理函数--
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		if cmd == "socket" then
			local f = SOCKET[subcmd]
			f(...)
			-- socket api don't need return
		else
			local f = assert(CMD[cmd])
			skynet.ret(skynet.pack(f(subcmd, ...)))
		end
	end)

    --初始化一个 gate server--
	gate = skynet.newservice("gate")
end)
--gatemanger 相关命令------------------------------------------
function CMD.start(gate_conf)
	skynet.error("gatemanager---->>CMD.start")
	--向 gate server 发送一个open的命令--
	skynet.call(gate, "lua", "open" , gate_conf)
end

function CMD.close(fd)
	skynet.error("gatemanager---->>CMD.close")
	close_agent(fd)
end

--登录验证成功了--
function CMD.OnLogin(fd, addr)
end

--SOCKET 相关处理------------------------------------------
--关闭连接--
local function close_agent(fd)
        local a = agents[fd]
        agents[fd] = nil
        if a then
                skynet.call(gate, "lua", "kick", fd)
                -- disconnect never return
                skynet.send(a, "lua", "disconnect")
        end
end
----------
--新连接--
function SOCKET.open(fd, addr)
	skynet.error("gatemanager---->>SOCKET.open : " .. addr)	
    skynet.call(gate, "lua", "accept", fd)

	--不直接生成代理agent
	--先交给登录服务验证
	--验证成功后再生成agent,并接受gate转发管理
	--agent[fd] = skynet.newservice("agent")
	--skynet.call(agent[fd], "lua", "start", { gate = gate, client = fd, gatemanager = skynet.self() })
end
--关闭连接--
function SOCKET.close(fd)
 	skynet.error("gatemanager---->>SOCKET.close")
	close_agent(fd)
end
--连接错误--
function SOCKET.error(fd, msg)
	skynet.error("gatemanager---->>SOCKET.error")
	close_agent(fd)
end
--socket警告--
function SOCKET.warning(fd, size)
	-- size K bytes havn't send out in fd
	skynet.error("gatemanager---->>SOCKET.WARNING")
end
--数据--
function SOCKET.data(fd, msg)
	 skynet.error("gatemanager---->>data!!!")
end

