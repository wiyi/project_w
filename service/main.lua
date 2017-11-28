local skynet = require "skynet"
local config = require "config.base"

skynet.start(function()
        skynet.error("main---->>start")
        --初始化配置表--
        --暂时未用 skynet.uniqueservice("datamanager")

        skynet.newservice ("debug_console", config.debug_port)

        local pbc = skynet.uniqueservice("pbc")
        skynet.send(pbc, "lua", "init")
        
	skynet.uniqueservice ("database")

	local loginmanager = skynet.newservice ("loginmanager")
	skynet.call (loginmanager, "lua", "open", config.login)	

	--local gamed = skynet.newservice ("gamed", loginmanager)
        --skynet.call (gamed, "lua", "open", game_config)

        --如果不是后台模式，则启动控制台--
        --[[暂时屏蔽
        if not skynet.getenv "daemon" then
                local console = skynet.newservice("console")
        end
        --]]
        skynet.exit()
end)

