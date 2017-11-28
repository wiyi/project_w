local config = {}

local host = "127.0.0.1"
local port = 6379
local db = 0

local centerdb = 
{
	host = host,
	port = port,
	db = db,
}

config.tables = 
{
	{name = "account", path = "db.account", conn_id = 1, format_key = "acc:%s"}
}

local count = 1
local subdb = {}
for i = 1, count do
	table.insert (subdb, { host = host, port = port + i, db = db })
end

config.centerdb = centerdb
config.subdb = subdb

return config
