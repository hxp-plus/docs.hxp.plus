---
tags:
  - Keycloak
  - Docker
---

# 使用 docker-compose 搭建 keycloak 开发环境

开发环境需要 keycloak ，使用 docker-compose 搭建：

```yaml
version: "3"

services:
  mysql:
    image: mysql:8.0
    volumes:
      - mysql_data:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: MyRootPassword
      MYSQL_DATABASE: keycloak
      MYSQL_USER: keycloak
      MYSQL_PASSWORD: MyKeycloakMySQLPassword
  keycloak:
    image: quay.io/keycloak/keycloak:24.0
    command: start-dev
    environment:
      KC_HOSTNAME: localhost
      KC_HOSTNAME_PORT: 8080
      KC_HOSTNAME_STRICT_BACKCHANNEL: false
      KC_HTTP_ENABLED: true
      KC_HOSTNAME_STRICT_HTTPS: false
      KC_HEALTH_ENABLED: true
      KEYCLOAK_ADMIN: admin
      KEYCLOAK_ADMIN_PASSWORD: admin
      KC_DB: mysql
      KC_DB_URL: jdbc:mysql://mysql:3306/keycloak
      KC_DB_USERNAME: keycloak
      KC_DB_PASSWORD: MyKeycloakMySQLPassword
    ports:
      - 8080:8080
    restart: always
    depends_on:
      - mysql
volumes:
  mysql_data:
    driver: local
```

启动：

```
docker-compose up
```

注：第一次启动可能不成功，需要重启一次。
