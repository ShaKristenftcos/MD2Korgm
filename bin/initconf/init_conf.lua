---
--- 功能：初始化conf
--- Created by: yusai.
--- DateTime: 2018/4/18
---
local conf_loader = require "bin.initconf.conf_loader"
local prefix_handler = require("bin.initconf.utils.prefix_handler")
local assert = assert
local init = function(conf_path,prefix)
    local conf = assert(conf_loader(conf_path,prefix))
    local res,err =  prefix_handler.prepare_prefix(conf)
    return res,err
end


-- args
    -- ngr_conf
    -- prefix
return function(args)
   return init(args.ngr_conf,args.prefix)
end
