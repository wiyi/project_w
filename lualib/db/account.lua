local M = {}
--{module = "account", path = "db.account", conn_id = 1, format_key = "acc:%s"}
local conf
local get_conn

function M.init(config,connection)
    conf = config
    get_conn = connection
end


function M.load (name)
	assert (name)

	local acc = { name = name }

	local connection, key = get_conn (conf,name)
    if connection:exists (key) then
        acc.id = connection:hget (key, "id")
        acc.password = connection:hget (key, "password")
	end

	return acc
end

function account.create (id, name, password)
	assert (id and name and #name < 24 and password and #password < 24, "invalid argument")
	
	local connection, key = make_key (name)
	assert (connection:hsetnx (key, "account", id) ~= 0, "create account failed")

	local salt, verifier = srp.create_verifier (name, password)
	assert (connection:hmset (key, "salt", salt, "verifier", verifier) ~= 0, "save account verifier failed")

	return id
end

return M

