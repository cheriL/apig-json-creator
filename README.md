# apig-json-creator
请求过程的json生成与模板转换插件

## 功能

### json生成
代码暴力转换实现，仅支持一维json的生成，即array与object相互嵌套格式的json

### json校验
json校验功能是使用jsonschema对请求的body体（目前仅支持‘application/json’）进行校验，如果不匹配会返回415的错误

### 模板转换
模板生成报文

## 代码模块

### 目录结构
```
apig-json-creator
├─ apig-json-creator-0.2.0-1.rockspec 
└─ kong
   └─ plugins
      └─ apig-json-creator
         ├─ handler.lua //基础模块，封装openresty的不同阶段的调用接口
         ├─ schema.lua //配置模块，定义插件的配置
         ├─ access.lua //access阶段的处理模块
         ├─ etlua.lua //etlua源码
         ├─ base64.lua //base64模块
         ├─ jsonschema //jsonschema校验模块源码
         │  ├─ compiler.lua
         │  ├─ init.lua
         │  └─ store.lua
         └─ net //jsonschema依赖
            └─ url.lua
```
### 配置说明
这里对schema模块的配置项进行说明。

```
config.queryPattern //query参数生成json规则
config.headPattern //head参数生成json规则
config.jsonSchema //控制台下发的json schema字符串
config.jsonTemplate //控制台下发的模板字符串
config.faultTolerant //校验容错
```

#### 配置规则：

##### config.queryPattern和config.headPattern
queryPattern和headPattern的规则由三部分组成，用分号隔开，分别是query(或head)的参数名，json绝对路径，数据类型，格式如下：

```
a.N.N;data.search_data[].elements[].rating;0
```
1. a.N.N： 实际情况下为a.1.1,a.1.2,a.2.1,a.2.2 等 (N的位置为具体的数字，表示json路径中[]内的值，即array层的位置)
2. data.search_data[].elements[].rating:  json路径的例子
3. 数据类型:  0:string1:number2:integer3:boolean6:null7:any

##### config.jsonSchema
这个配置项存放json schema字符串。

##### config.jsonTemplate
这个配置项存放模板字符串。
