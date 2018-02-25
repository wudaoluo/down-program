-----
----- Created by wudaoluo.
----- DateTime: 2017/12/28 下午3:07
-----
--
--
---- 1.判断最新的版本

package.path = string.format("%s;%s","/home/v1",package.path)

local lfs = require "lfs"
local req = require "req"
local cjson = require "cjson"



function getType(path)
    return lfs.attributes(path).mode
end

function isDir(path)
    return getType(path) == "directory"
end



---- 返回最新版本号
function getNewVer(path)
    local verTable = {}
    for dirname in lfs.dir(path) do
        if isDir(path.."/"..dirname) then
        --  将 str改成 float 类型 插入 table
            table.insert(verTable,tonumber(dirname))
        end
    end
    return path.."/"..string.format("%0.1f", math.max(unpack(verTable)))
end

---- 切割 string
function Split(s, sp)
    local res = {}

    local temp = s
    local len = 0
    while true do
        len = string.find(temp, sp)
        if len ~= nil then
            local result = string.sub(temp, 1, len-1)
            temp = string.sub(temp, len+1)
            table.insert(res, result)
        else
            table.insert(res, temp)
            break
        end
    end
    return res
end

-- 读取 file 流
function downFile(filedir,filename)
    local file, err = io.open(filedir,"r")
    if not file then
        ngx.log(ngx.ERR, "打开文件失败:", filedir)
        ngx.exit(404)
    end

    local data
    while true do
        data = file:read(1024)
        if nil == data then
            break
        end
        ngx.header["Content-Type"]="application/octet-stream"
        ngx.header["Content-disposition"]="attachment;filename="..ngx.escape_uri(filename)
        ngx.print(data)
        ngx.flush(true)
    end
    file:close()
end





local t = {}
local args = req.getArgs()
t = Split(ngx.var.uri, '/')


if args["dir"]~= nil and args["dir"] == 'true' then
    local verTable = {}
    local path = ngx.var.document_root.."/".. t[2]
    for dirname in lfs.dir(path) do
        if isDir(path.."/"..dirname) and dirname ~= '.' and dirname ~= '..' then
            table.insert(verTable,dirname.."\n")
        end
    end
    ngx.say(verTable)
    ngx.exit(200)
end

if args['ver'] ~= nil then
    local path = ngx.var.document_root.."/".. t[2]
    downFile(path.."/"..args['ver'].."/"..t[3],t[3])
    ngx.exit(200)
end


if args['help'] then
    ngx.say(cjson.encode({ver="下载特定版本",dir="显示存在的版本号",null="不加任何参数下载最新版本"}))
    ngx.exit(200)
end

local ngxpath = getNewVer(ngx.var.document_root.."/".. t[2])
downFile(ngxpath.."/"..t[3],t[3])
ngx.exit(200)

