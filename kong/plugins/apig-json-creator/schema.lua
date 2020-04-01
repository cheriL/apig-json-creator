local typedefs = require "kong.db.schema.typedefs"
--[[=====================================================================
版本更新说明：
*VERSION: 0.2.0
 |--description: enables request body validating and transforming
                 (only support 'application/json' for now)
 |--new config fields: jsonSchema, jsonTemplate, faultTolerant
 |--details:
    |--jsonSchema[1]: model for validator
    |--jsonTemplate[1]: template for request body tramsforming
    |--faultTolerant: fault tolerant for ERRORS

*VERSION: 0.1.0
 |--description: enables request body validating and transforming
 |--config fields: queryPattern, headPattern
 |--Example:
    |--queryPattern:  a.N.N;data.search_data[].elements[].rating;0
    |
    |--Details:   正则匹配的规则分为三部分，由 ; 隔开
              (1) 转换前的参数模式:    a.N.N
              (2) 对应的json path:   data.search_data[].elements[].rating
              (3) 参数类型(db)：      0:string
                                    1:number
                                    2:integer
                                    3:boolean
                                    6:null
                                    7:any
======================================================================--]]

local pattern_map_array = {
  type = "array",
  default = {},
  elements = { type = "string", match = "^[^;]+;[^;]+;[0-9]$" },
}

local string_array = {
  type = "array",
  default = {},
  elements = { type = "string" },
}

return {
  name = "apig-json-creator",
  fields = {
    { run_on = typedefs.run_on_first },
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {         
          { queryPattern = pattern_map_array },
          { headPattern = pattern_map_array },
          { jsonSchema = string_array },
          { jsonTemplate = string_array },
          { faultTolerant = { type = "boolean", default = false }, },
        }
      },
    },
  }
}
