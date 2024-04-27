---
tags:
  - AWX
---

## AWX 创建并使用 Token 方法

访问 AWX 的 API Web 页面：<http://22.122.63.17/awx/api/v2/tokens/>，拉到最底下，点下“POST”，把返回的 token 记录下来。使用 token 的 shell 示例如下：

```bash
export TOKEN=WYWAiswJYBsQUqQBXsfGnOn4a52CaC
curl -s -X GET -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" http://22.122.63.17/awx/api/v2/inventories/
```

python 示例：

```python
#!/usr/bin/python3
# -*- coding: utf-8 -*-
import json,sys,requests
token="WYWAiswJYBsQUqQBXsfGnOn4a52CaC"
endpoint="http://22.122.63.17/awx/api/v2/"
headers={ "Authorization": "Bearer %s" %token ,"Content-Type": "application/json"}
inventories=requests.get(endpoint+"inventories?search=C-PSI", headers=headers)
for i in inventories.json()["results"]:
	print(i)
```

API 参考手册：<https://docs.ansible.com/ansible-tower/latest/html/towerapi/api_ref.html>
