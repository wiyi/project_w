local util = require "helper.util"
local skynet = require "skynet"
local message = require "config.message"

local M = {}
--len(ushort)--id(ushort)--data--
function M.pack(name, msg)
	local buf = skynet.call("pbc", "lua", "encode", name, msg)
	local id = message.getid(name)
	local len = 2 + 2 + #buf
	return string.pack(">HHs2", len, id, buf)
end

--id(ushort)--data--
function M.unpack(data)
	local id, buf = string.unpack(">Hs2", data)
	local name = message.getname(id)
	util.print_buff(buf)
	local msg = skynet.call("pbc", "lua", "decode", name, buf)
	return name, msg
end

return M

--[[
用于 string.pack， string.packsize， string.unpack 的第一个参数。 它是一个描述了需要创建或读取的结构之布局。

格式串是由转换选项构成的序列。 这些转换选项列在后面：

<: 设为小端编码
>: 设为大端编码
=: 大小端遵循本地设置
![n]: 将最大对齐数设为 n （默认遵循本地对齐设置）
b: 一个有符号字节 (char)
B: 一个无符号字节 (char)
h: 一个有符号 short （本地大小）
H: 一个无符号 short （本地大小）
l: 一个有符号 long （本地大小）
L: 一个无符号 long （本地大小）
j: 一个 lua_Integer
J: 一个 lua_Unsigned
T: 一个 size_t （本地大小）
i[n]: 一个 n 字节长（默认为本地大小）的有符号 int
I[n]: 一个 n 字节长（默认为本地大小）的无符号 int
f: 一个 float （本地大小）
d: 一个 double （本地大小）
n: 一个 lua_Number
cn: n字节固定长度的字符串
z: 零结尾的字符串
s[n]: 长度加内容的字符串，其长度编码为一个 n 字节（默认是个 size_t） 长的无符号整数。
x: 一个字节的填充
Xop: 按选项 op 的方式对齐（忽略它的其它方面）的一个空条目
' ': （空格）忽略
（ "[n]" 表示一个可选的整数。） 除填充、空格、配置项（选项 "xX <=>!"）外， 每个选项都关联一个参数（对于 string.pack） 或结果（对于 string.unpack）。

对于选项 "!n", "sn", "in", "In", n 可以是 1 到 16 间的整数。 
所有的整数选项都将做溢出检查； string.pack 检查提供的值是否能用指定的字长表示； string.unpack 检查读出的值能否置入 Lua 整数中。

任何格式串都假设有一个 "!1=" 前缀， 即最大对齐为 1 （无对齐）且采用本地大小端设置。

对齐行为按如下规则工作： 对每个选项，格式化时都会填充一些字节直到数据从一个特定偏移处开始， 
这个位置是该选项的大小和最大对齐数中较小的那个数的倍数； 
这个较小值必须是 2 个整数次方。 选项 "c" 及 "z" 不做对齐处理； 
选项 "s" 对对齐遵循其开头的整数。	
--]]
