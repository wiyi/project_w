local msg_id_name = 
{
    [10001] = "Login.Hello",
    [10002] = "Login.Version",
}

local msg_name_id = 
{
    ["Login.Hello"] = 10001,
    ["Login.Version"] = 10002,
}

local message = {}
function message.getname(id)
    return msg_id_name[id]
end

function message.getid(name)
    return msg_name_id[name]
end

return message
