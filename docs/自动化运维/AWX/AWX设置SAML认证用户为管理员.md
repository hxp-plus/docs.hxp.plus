---
tags:
  - AWX
---

## AWX 创建 SAML 用户为管理员

1. Keycloak 上，创建一个 role：awx_admin
   ![](images/AWX设置SAML认证用户为管理员_1.png)
2. Keycloak 上，将 awx_system_admin 加入这个 role
   ![](images/AWX设置SAML认证用户为管理员_2.png)
3. AWX 上，修改 AWX 的 “SAML User Flags Attribute Mapping”
   ![](images/AWX设置SAML认证用户为管理员_3.png)
