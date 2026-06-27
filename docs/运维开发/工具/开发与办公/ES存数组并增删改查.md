---
tags:
  - Linux
  - 工具
---

```json
# 查询所有数据

GET /osops.monitor_scripts/_search
{
  "query": {
    "match_all": {}
  }
}

# 删除索引
DELETE /osops.monitor_scripts/

# 建立索引
PUT /osops.monitor_scripts/
{
  "mappings": {
    "properties": {
      "last_updated": {
        "type": "date",
        "format": "yyyy-MM-dd HH:mm:ss||strict_date_optional_time||epoch_millis"
      },
      "reachable": {
        "type": "boolean"
      },
      "monitor_scripts": {
        "type": "nested",
        "properties": {
          "name": { "type": "keyword" },
          "md5sum": { "type": "keyword" }
        }
      }
    }
  }
}

# 监控脚本ABC均部署且版本为最新
PUT /osops.monitor_scripts/_doc/192.168.12.1
{
  "last_updated": "2024-04-19 02:39:00",
  "monitor_scripts": [
    {"name": "A","md5sum": "a"},
    {"name": "B","md5sum": "b"},
    {"name": "C","md5sum": "c"}
  ],
  "reachable": true
}

# 监控脚本AB部署且版本为最新，C未部署
PUT /osops.monitor_scripts/_doc/192.168.12.2
{
  "last_updated": "2024-04-19 02:39:00",
  "monitor_scripts": [
    {"name": "A","md5sum": "a"},
    {"name": "B","md5sum": "b"}
  ],
  "reachable": true
}

# 监控脚本A部署且版本为最新，BC部署为旧版本
PUT /osops.monitor_scripts/_doc/192.168.12.3
{
  "last_updated": "2024-04-19 02:39:00",
  "monitor_scripts": [
    {"name": "A","md5sum": "a"},
    {"name": "B","md5sum": "d"},
    {"name": "C","md5sum": "e"}
  ],
  "reachable": true
}

# 查找所有C已部署但是为旧版本的机器，只返回ID
GET /osops.monitor_scripts/_search
{
  "_source": false, 
  "query": {
    "nested": {
      "path": "monitor_scripts",
      "query": {
        "bool": {
          "must": [
            { "term": { "monitor_scripts.name": "C" } }
          ],
          "must_not": [
            { "term": { "monitor_scripts.md5sum": "c" } }
          ]
        }
      }
    }
  }
}

# 查找所有C未部署的机器
GET /osops.monitor_scripts/_search
{
  "query": {
    "bool": {
      "must_not": {
        "nested": {
          "path": "monitor_scripts",
          "query": {
            "term": { "monitor_scripts.name": "C" }
          }
        }
      }
    }
  }
}
```

!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。
