local config = {}

-- 1:debug 2:info 3:notice 4:warning 5:error
config.log_level = 1 

config.debug_port = 9100

--服务器设定--
config.gate = { port = 8888, maxclient = 1024, nodelay = true}     
config.game = { name = "gameserver", port = 9555, maxclient = 64, pool = 32}

config.login = 
{
	message_version = 0,--消息版本
	port = 9200, --端口
	count = 8,--实例数量
	auth_timeout = 10, -- 验证时间10秒
	session_expire_time = 30 * 60, -- session到期时间秒
}

return config
