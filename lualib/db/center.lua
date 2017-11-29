local M = {}
local db
local key = "GLOBAL"

function init_global_id(id)
    local tempid
    if db:exists (key) then
        tempid = db:hget (key, "id")
    end
    local id = tonumber (tempid)
    if not id then
        set_global_id(100001)
    end
end

function get_global_id()
    local tempid = db:hget (key, "id")
    local id = tonumber (tempid)
    set_global_id(id+1)
    return id
end

function set_global_id(id)
    assert (db:hmset (key, "id", id) ~= 0, "set_global_id failed")
end



function M.init(centerdb)
    db = centerdb
    init_global_id()
end

function M.genid ()
    return get_global_id()
end

return M
