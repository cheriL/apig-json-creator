local access = require "kong.plugins.apig-json-creator.access"
local cjson = require "cjson.safe"

local next = next
local lower = string.lower
local find = string.find

local CONTENT_TYPE = "Content-Type"
local JSON = "application/json"

local reqTransformerSpHandler = {}

reqTransformerSpHandler.PRIORITY = 1998
reqTransformerSpHandler.VERSION = "0.2.0"

function reqTransformerSpHandler:access(conf)
  local start_time = os.clock()

  --body template transforming
  local content_type_value = lower(kong.request.get_header(CONTENT_TYPE) or '')
  if find(content_type_value, JSON, nil, true) then
    local body = kong.request.get_body(JSON)
    local json_string
    --
    if next(conf.jsonSchema) then
      --kong.log.notice('[SCHEMA]' .. conf.jsonSchema[1])
      local json_schema = cjson.decode(conf.jsonSchema[1])
      access.validate(json_schema, body)
    end

    --
    if next(conf.jsonTemplate) then
      --kong.log.notice('[TEMPLATE]' .. conf.jsonTemplate[1])
      local success
      success, json_string = access.template_transform(conf.jsonTemplate[1], body)

      if not success and conf.faultTolerant then
        kong.log.warn("Go on!!!" .. "[" .. json_string .. "]")
        return
      elseif not success and not conf.faultTolerant then
        kong.response.exit(415, { message = json_string })
      end
    end

    if json_string then
      --处理cjson.null
      json_string = string.gsub(json_string, '"userdata: NULL"', 'null')
      json_string = string.gsub(json_string, 'userdata: NULL', 'null')
      kong.service.request.set_header("Content-Type", "application/json")
      kong.service.request.set_raw_body(json_string)
      kong.log.notice(json_string)
      return
    end
  end

  --head, query 2 body
    local headers = kong.request.get_headers()
    local querys = kong.request.get_query()
    local changed, json_table

    local pattern = conf.queryPattern
    if next(pattern) then
        changed, querys, json_table = access.param2Json(pattern, querys, json_table)
        if changed == true then
            kong.service.request.set_query(querys)
        end
    end

    pattern = conf.headPattern
    if next(pattern) then
        changed, headers, json_table = access.param2Json(pattern, headers, json_table)
        if changed == true then
            kong.service.request.set_headers(headers)
        end
    end

  --
    if type(json_table) == "table" and next(json_table) then
      local json = cjson.encode(json_table)
      if json ~= nil and json ~= 'null' then
        kong.service.request.set_header("Content-Type", "application/json")
        kong.service.request.set_raw_body(json)
        kong.log.notice(json)
      end
    end

    kong.log.notice("[apig-json-creator] q2b spend time : " .. os.clock() - start_time .. ".")
end

return reqTransformerSpHandler
