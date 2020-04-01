package = "apig-json-creator"
version = "0.2.0-1"

local pluginName = package:match("^(.+)$")  -- "apig-json-creator"

supported_platforms = {"linux", "macosx"}
source = {
  tag = "0.2.0",
  url = "http://git.inspur.com/api-gateway/APIGPlugins"
}

description = {
  summary = "An APIG plugin that enables request body transforming.",
  license = "Apache 2.0"
}

dependencies = {
  "lua = 5.1",
}

build = {
  type = "builtin",
  modules = {
    ["kong.plugins."..pluginName..".handler"] = "kong/plugins/"..pluginName.."/handler.lua",
	["kong.plugins."..pluginName..".access"] = "kong/plugins/"..pluginName.."/access.lua",
    ["kong.plugins."..pluginName..".schema"] = "kong/plugins/"..pluginName.."/schema.lua",
    --["jsonschema.compiler"] = "kong/plugins/"..pluginName.."/jsonschema/compiler.lua",
    ["jsonschema"] = "kong/plugins/"..pluginName.."/jsonschema/init.lua",
    ["jsonschema.store"] = "kong/plugins/"..pluginName.."/jsonschema/store.lua",
    ["net.url"] = "kong/plugins/"..pluginName.."/net/url.lua",
    ["etlua"] = "kong/plugins/"..pluginName.."/etlua.lua",
	["base64"] = "kong/plugins/"..pluginName.."/base64.lua",
  }
}
