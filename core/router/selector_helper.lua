---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by zhangchenghao.
--- DateTime: 2018/9/3 下午8:06
---

local require = require
local selector_type = require("core.constants.selector_type")
local intercept_type = require("core.constants.intercept_type")
local judger = require("core.req.param_judger")
local string_format = string.format
local tonumber = tonumber
local table = table

local _M = {}

-- 判断条件是否命中
local function judge(condition)
    return judger.judge(condition.param_type, condition.param_name, condition.param_value, condition.condition_opt_type)
end

-- 记录命中结果
local function build_judge_conditions(judge_conditions, condition, actual_value)
    table.insert(judge_conditions,{
        param_type = condition.param_type,
        condition_opt_type = condition.condition_opt_type,
        param_name = condition.param_name,
        param_value = condition.param_value,
        actual_value = actual_value
    })
end

-- 单条件
local function single_condition(condition, judge_conditions)
    local is_hit, expected_value,actual_value = judge(condition)
    if is_hit then
        -- 记录命中结果
        build_judge_conditions(judge_conditions, condition,actual_value)
        return
    end
end

-- 多条件或
local function multi_condition_or(conditions,judge_conditions)
    for _, condition in ipairs(conditions) do
        -- 执行判定，is_hit -> true 命中
        local is_hit,expected_value,actual_value = judger.judge(condition.param_type, condition.param_name, condition.param_value, condition.condition_opt_type)

        ngx.log(ngx.DEBUG,string_format("multi_condition_or is_hit:%s , expected_value: %s ,actual_value:%s",is_hit,expected_value,actual_value))

        if is_hit then
            -- 记录拒绝记录
            build_judge_conditions(judge_conditions, condition,actual_value)
            return
        end
    end
end

-- 多条件且
local function multi_condition_and(conditions,judge_conditions)

    for _, condition in ipairs(conditions) do
        -- 执行判定，is_hit -> true 命中
        local is_hit,expected_value,actual_value = judger.judge(condition.param_type, condition.param_name, condition.param_value, condition.condition_opt_type)

        ngx.log(ngx.DEBUG,string_format("multi_condition_and is_hit:%s , expected_value: %s ,actual_value:%s , [param_type:%s , param_name:%s,",is_hit,expected_value,actual_value, condition.param_type, condition.param_name))

        if is_hit then -- 记录拒绝记录
            build_judge_conditions(judge_conditions, condition,actual_value)
        end
    end
end

-- 判断是否请求是否匹配选择器的条件
function _M.is_match(selector)
    local s_type =  selector.selector_type
    local conditions = selector.conditions

    local judge_conditions={} -- 命中记录

    -- 执行防火墙对应多条件
    if conditions and #conditions > 0 then

        if tonumber(s_type)==selector_type.single then -- 单条件

            single_condition(conditions[1],judge_conditions)

            if judge_conditions and #judge_conditions == 1 then
                return true, judge_conditions
            end

        elseif tonumber(s_type) == selector_type.multi_or then -- 多条件或

            multi_condition_or(conditions,judge_conditions)

            if judge_conditions and #judge_conditions == 1 then
                return true, judge_conditions
            end

        elseif tonumber(s_type) == selector_type.multi_and then -- 多条件与

            multi_condition_and(conditions,judge_conditions)

            if judge_conditions and #judge_conditions == #conditions then
                return true, judge_conditions
            end

        end
    end

    return false,judge_conditions

end

-- 根据拦截类型判断是否拦截
function _M.is_intercept_with_intercept_type(selector, i_type)
    if (not i_type) or (i_type == intercept_type.black) then
        return _M.is_match(selector)
    elseif i_type == intercept_type.white then
        local flag,hit_conditions = _M.is_match(selector)
        return not flag,hit_conditions
    else
        return nil,nil
    end
end

return _M