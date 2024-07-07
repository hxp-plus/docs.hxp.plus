---
tags:
  - Keycloak
  - Docker
---

# 使用 docker-compose 搭建 keycloak 开发环境

开发环境需要 keycloak ，使用 docker-compose 搭建运行在 `172.21.1.56:8085` 的 keycloak ，新建文件 `compose.yaml` ：

```yaml
---
networks:
  geeker-admin:
    driver: bridge
    name: geeker-admin
services:
  keycloak:
    command: start-dev
    container_name: geeker-admin-keycloak
    depends_on:
      - mysql
    environment:
      KC_DB: mysql
      KC_DB_PASSWORD: MyKeycloakMySQLPassword
      KC_DB_URL: jdbc:mysql://mysql:3306/keycloak
      KC_DB_USERNAME: keycloak
      KC_HEALTH_ENABLED: true
      KC_HOSTNAME: 172.21.1.56
      KC_HOSTNAME_PORT: 8085
      KC_HOSTNAME_STRICT_BACKCHANNEL: false
      KC_HOSTNAME_STRICT_HTTPS: false
      KC_HTTP_ENABLED: true
      KEYCLOAK_ADMIN: admin
      KEYCLOAK_ADMIN_PASSWORD: admin
    expose:
      - 8080
    image: quay.io/keycloak/keycloak:24.0
    networks:
      - geeker-admin
    ports:
      - 8085:8080
    restart: always
  mysql:
    container_name: geeker-admin-mysql
    environment:
      MYSQL_DATABASE: keycloak
      MYSQL_PASSWORD: MyKeycloakMySQLPassword
      MYSQL_ROOT_PASSWORD: MyRootPassword
      MYSQL_USER: keycloak
    expose:
      - 3306
    image: mysql:8.0
    networks:
      - geeker-admin
    restart: always
    volumes:
      - mysql:/var/lib/mysql
volumes:
  mysql:
    driver: local
    name: geeker-admin-mysql
```

特别注意， `KC_HOSTNAME` 一定配置成服务器外部域名或 IP，不能是 `localhost` 。启动：

```
docker compose up
```

注：第一次启动可能不成功，需要重启一次。
