---
tags:
  - Geeker-Admin
  - Vue3
  - Keycloak
  - TypeScript
---

# Geeker-Admin 接入 Keycloak 认证

## 前置条件

1. Keycloak 服务器运行在 <http://localhost:8080/> 。
2. Keycloak 服务器创建 Realm，名称为 test ，并在其中创建 Client ID 为 test-client 、 Client type 为 OpenID Connect 、 Client authentication 关闭、 Valid redirect URIs 和 Web origins 均为 \* 的 Client 。

## 安装 Keycloak 对接器

```
npm i --save keycloak-js@24.0
```

## 加入环境变量

在 `.env.development` 加入：

```
# keycloak options
VITE_APP_KEYCLOAK_OPTIONS_URL = 'http://localhost:8080/'
VITE_APP_KEYCLOAK_OPTIONS_REALM = 'test'
VITE_APP_KEYCLOAK_OPTIONS_CLIENTID = 'test-client'
VITE_APP_KEYCLOAK_OPTIONS_ONLOAD = 'login-required'
```

## 在 main.ts 中加入 keycloak 认证

在 `src/main.ts` 中加入以下代码，引入 Keycloak：

```javascript
// 引入Keycloak
// 参考：https://github.com/achernetsov/vue-keycloak-template
import Keycloak, {
  type KeycloakConfig,
  type KeycloakInitOptions,
} from "keycloak-js";
import { useKeycloakStore } from "@/store/modules/keycloakStore";
```

为 Keycloak 加入 store，创建文件 `src/stores/modules/keycloakStore.ts` ：

```javascript
import { ref } from "vue";
import { defineStore } from "pinia";
import type Keycloak from "keycloak-js";

// https://pinia.vuejs.org/getting-started.html
export const useKeycloakStore = defineStore("keycloakStore", () => {
  const keycloak = ref(null as Keycloak | null);
  return { keycloak };
});

```

在 `main.ts` 中加入 Keycloak 将以下代码：

```javascript
app
  .use(ElementPlus)
  .use(directives)
  .use(router)
  .use(I18n)
  .use(pinia)
  .mount("#app");
```

替换为：

```javascript
app.use(ElementPlus).use(directives).use(router).use(I18n).use(pinia);

let keycloakConfig: KeycloakConfig = {
  url: import.meta.env.VITE_APP_KEYCLOAK_OPTIONS_URL,
  realm: import.meta.env.VITE_APP_KEYCLOAK_OPTIONS_REALM,
  clientId: import.meta.env.VITE_APP_KEYCLOAK_OPTIONS_CLIENTID,
};
let keycloak = new Keycloak(keycloakConfig);
const keycloakStore = useKeycloakStore();
keycloakStore.keycloak = keycloak;
let initOptions: KeycloakInitOptions = {
  onLoad: "login-required",
  enableLogging: true,
  responseMode: "query", // 参考：https://github.com/keycloak/keycloak/issues/14742
};
keycloak.init(initOptions).then((auth) => {
  if (!auth) {
    console.warn("Authentication failed");
  } else {
    console.log("Authenticated");
    keycloak.loadUserInfo().then(() => {
      app.mount("#app");
    });
  }
  //Token Refresh
  setInterval(() => {
    keycloak
      .updateToken(70)
      .then((refreshed) => {
        if (refreshed) {
          console.log("Token refreshed");
        } else {
          console.warn("Token not refreshed");
        }
      })
      .catch(() => {
        console.error("Failed to refresh token");
      });
  }, 6000);
});
```
