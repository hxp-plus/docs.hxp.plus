---
tags:
  - AWX
---

# AWX 增加并使用 token

## 创建 Token

### 为自己创建 Token

访问 AWX 的 API Web 页面：<http://awx.hxp.lan:30623/awx/api/v2/tokens/>，拉到最底下，点下“POST”，把返回的 token 记录下来。

### 为别的用户创建 Token

使用 POST 请求调用此接口创建 Token ：

<http://awx.hxp.lan:30623/api/v2/users/<用户ID>/personal_tokens/>

## Token 使用示例

使用 token 的 shell 示例如下：

```bash
export TOKEN=WYWAiswJYBsQUqQBXsfGnOn4a52CaC
curl -s -X GET -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" http://awx.hxp.lan:30623/awx/api/v2/inventories/
```

python 示例：

```python
#!/usr/bin/python3
# -*- coding: utf-8 -*-
import json,sys,requests
token="WYWAiswJYBsQUqQBXsfGnOn4a52CaC"
endpoint="http://awx.hxp.lan:30623/awx/api/v2/"
headers={ "Authorization": "Bearer %s" %token ,"Content-Type": "application/json"}
inventories=requests.get(endpoint+"inventories?search=C-PSI", headers=headers)
for i in inventories.json()["results"]:
	print(i)
```

## 参考资料

API 参考手册：<https://docs.ansible.com/ansible-tower/latest/html/towerapi/api_ref.html>
