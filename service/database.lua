local skynet = require "skynet"
local redis = require "skynet.db.redis"
local log = require "helper.log"
local config = require "config.db"

local center
local centerdb
--不同的table放在不同的subdb里面，目前只有1个
local subdb = {}

local function get_conn (conf,key)
	return subdb[conf.conn_id],string.format (conf.format_key, key)
end


--MODULE相关------------------------------------------
local MODULE = {}

local function module_init (name, mod)
        MODULE[name] = mod
        mod.init (get_conn)
end
--init
local function init()
	--init center
	center = require("db.center")
	center.init(centerdb)
	--init other
	local count = #config.tables
	local table
	for i = 1, count do
		table = config.tables[i]
		module_init (table.name, require(table.path))
	end
end

local traceback = debug.traceback

skynet.start (function ()
	
	init()

	centerdb = redis.connect (config.centerdb)
	for _, c in ipairs (config.subdb) do
		table.insert (subdb, redis.connect (c))
	end

	skynet.dispatch ("lua", function (_, _, mod, cmd, ...)
		local m
		if(mod == "center")then
			m = center
		else
			m = MODULE[mod]
		end
		if not m then
			return skynet.ret ()
		end
		local f = m[cmd]
		if not f then
			return skynet.ret ()
		end
		
		local function ret (ok, ...)
			if not ok then
				skynet.ret ()
			else
				skynet.retpack (...)
			end

		end
		ret (xpcall (f, traceback, ...))
	end)
end)
