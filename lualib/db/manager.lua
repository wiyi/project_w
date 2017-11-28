local M = {}

function M.set (connection,key,...)
	assert (connection:hmset (key,...) ~= 0, string.format ("[set] %s.%s -> (%s) failed ",_table,_key,key))
	--TODO 通知mysql数据库备份
end

function M.new (connection,key,...)
	assert (connection:hsetnx (key,...) ~= 0, string.format ("[new] %s.%s -> (%s) failed ",_table,_key,key))
	--TODO 通知mysql数据库备份
end

return M
