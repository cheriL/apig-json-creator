local jsonschema = require 'jsonschema'
local cjson = require "cjson.safe"
local etlua = require "etlua"

local _M = {}

local gsub = string.gsub
local find = string.find
local match = string.match
local gmatch = string.gmatch

local function set_json_value(table, key, value)
    if not key or key == '' then
        return table
    end

    local json_table = table
    if not json_table then 
        json_table = {}
    end

    local json_path = key
    
    local pos = string.find(json_path, "%.")
    if not pos then
        local node_name, index_str = string.match(json_path, '([^%[]*)%[?(%d*)%]?') --node_name[index]
        local index = tonumber(index_str)
        if not index then
            json_table[node_name] = value
        else
            if node_name == '' then
                json_table[index] = value
            else
                if type(json_table[node_name]) ~= 'table' then
                    json_table[node_name] = {}
                end
                json_table[node_name][index] = value
            end
        end
    elseif pos == 1 then
        json_path = string.sub(json_path, pos + 1, #json_path)
        json_table = set_json_value(json_table, json_path, value)
    elseif pos == #json_path then
        json_path = string.sub(json_path, 1, #json_path - 1)
        json_table = set_json_value(json_table, json_path, value)
    else
        local node = string.sub(json_path, 1, pos - 1)
        json_path = string.sub(json_path, pos + 1, #json_path)
        local node_name, index_str = string.match(node, '([^%[]*)%[?(%d*)%]?') --node_name[index]
        local index = tonumber(index_str)
        if not index then
            json_table[node_name] = set_json_value(json_table[node_name], json_path, value)
        else
            if node_name == '' then
                json_table[index] = set_json_value(json_table[index], json_path, value)
            else
                if type(json_table[node_name]) ~= 'table' then
                    json_table[node_name] = {}
                end
                json_table[node_name][index] = set_json_value(json_table[node_name][index], json_path, value)
            end
        end
    end
        
    return json_table
end

function _M.param2Json(pattern, param_table, json_table)
    local changed

    for i = 1, #pattern do --遍历配置
        local old_patt, new_patt, type = pattern[i]:match("^([^;]+);([^;]+);([0-9])$")
        if not old_patt or not new_patt then
            goto failed
        end

        if find(old_patt, "%.N") ~= nil then
            local key1 = gsub(old_patt, '%.N', '.%%d+')
            --遍历query, 找到match的query的key, 使用下标index填充[]
            for k, v in pairs(param_table) do              
                if(match(k, key1) == k) then
                    local key2 = new_patt
                    for index in gmatch(k, '%.(%d+)') do
                        key2 = gsub(key2, "(%[%])", '[' .. index .. ']', 1)
                    end

                    param_table[k] = nil
                    changed = true

                    local value
                    if type == '1' or type == '2' then
                        value = tonumber(v) or v
                    elseif type == '3' then
                        if v == "true" then
                            value = true
                        elseif v == "false" then
                            value = false
                        end
                    else
                        value = v
                    end
                    json_table = set_json_value(json_table, key2, value)
                end
            end
        else
            local value = param_table[old_patt]
            if type == '1' or type == '2' then
                value = tonumber(value) or value
            elseif type == '3' then
                if value == "true" then
                    value = true
                elseif v == "false" then
                    value = false
                end
            end

            param_table[old_patt] = nil
            changed = true

            json_table = set_json_value(json_table, new_patt, value)
        end
        ::failed::
    end

    return changed, param_table, json_table
end

--validate
function _M.validate(schema, body)
  if type(schema) == 'table' and next(schema) then
    local func_validator = jsonschema.generate_validator(schema)

    if type(func_validator) == 'function' then
      if type(body) == 'table' and next(body) then
        kong.log.notice('Validating ...')

        local ok, err_msg = func_validator(body)
        if not ok then
          kong.response.exit(415, { message = err_msg })
        end
      end
    end
  end
end

--template transform body
function _M.template_transform(template, body)
  --generate template function
  local func_template = etlua.compile(template)
  if type(func_template) ~= 'function' then
    return false, 'Template compilation failed.'
  end

  local ok, msg = pcall(func_template, body)
  return ok, msg
end

return _M
