---
tags:
  - Spring Security
  - SpringBoot
  - Java
  - Keycloak
---

# SpringBoot 2.5.1 对接 Keycloak 认证

## Spring 项目配置

在 `pom.xml` 加入依赖：

```xml
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-security</artifactId>
</dependency>
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-oauth2-client</artifactId>
</dependency>
```

添加 application.properties 配置：

```ini
spring.security.oauth2.client.registration.keycloak.client-id=test-client
spring.security.oauth2.client.registration.keycloak.authorization-grant-type=authorization_code
spring.security.oauth2.client.registration.keycloak.scope=openid
spring.security.oauth2.client.provider.keycloak.issuer-uri=http://ubuntu.hxp.lan:8080/realms/test
spring.security.oauth2.client.provider.keycloak.user-name-attribute=preferred_username
spring.security.oauth2.resourceserver.jwt.issuer-uri=http://ubuntu.hxp.lan:8080/realms/test
```

## Keycloak 配置

本次使用的 Keycloak 开发服务器， docker-compose 配置如下：

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
    restart: always
  keycloak:
    image: quay.io/keycloak/keycloak:24.0
    command: start-dev
    environment:
      KC_HOSTNAME: ubuntu.hxp.lan
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

docker 的 2 个容器启动完成之后，进入 `http://ubuntu.hxp.lan:8080/` 配置 Keycloak （用户名和密码均为 `admin` ），做如下配置：

1. 新建名称为 test 的 Realm
2. 新建类型为 OpenID Connect ，ID 为 test-client 的 client
3. test-client 的 Client authentication 为 OFF
4. test-client 的 Valid redirect URIs 为 \*
5. test-client 的 Web origins 为 \*
6. 在名称为 test 的 Realm 里新建用户 testuser

之后启动 Spring 后端，会自动跳转到 Keycloak 登录页面。

## 在 Spring 里 配置 SecurityConfig

新建文件 `src/main/java/com/onlyoffice/integration/config/SecurityConfig.java` ：

```java
package com.onlyoffice.integration.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.oauth2.client.oidc.userinfo.OidcUserRequest;
import org.springframework.security.oauth2.client.oidc.userinfo.OidcUserService;
import org.springframework.security.oauth2.client.registration.ClientRegistration;
import org.springframework.security.oauth2.client.userinfo.OAuth2UserService;
import org.springframework.security.oauth2.core.OAuth2AccessToken;
import org.springframework.security.oauth2.core.oidc.user.DefaultOidcUser;
import org.springframework.security.oauth2.core.oidc.user.OidcUser;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.util.StringUtils;

import java.util.HashSet;
import java.util.Set;

@Configuration
@EnableWebSecurity
public class SecurityConfig {
    @Bean
    public SecurityFilterChain filterChain(final HttpSecurity http) throws Exception {
        http.csrf().disable().authorizeRequests().antMatchers("/track", "/download").permitAll().anyRequest().authenticated().and().oauth2Login(oauth2 -> oauth2.userInfoEndpoint(userInfo -> userInfo.oidcUserService(this.oidcUserService())));
        return http.build();
    }

    private OAuth2UserService<OidcUserRequest, OidcUser> oidcUserService() {
        final OidcUserService delegate = new OidcUserService();

        return (userRequest) -> {
            // Delegate to the default implementation for loading a user
            OidcUser oidcUser = delegate.loadUser(userRequest);

            OAuth2AccessToken accessToken = userRequest.getAccessToken();
            Set<GrantedAuthority> mappedAuthorities = new HashSet<>();

            // TODO
            // 1) Fetch the authority information from the protected resource using accessToken
            // 2) Map the authority information to one or more GrantedAuthority's and add it to mappedAuthorities

            // 3) Create a copy of oidcUser but use the mappedAuthorities instead
            ClientRegistration.ProviderDetails providerDetails = userRequest.getClientRegistration().getProviderDetails();
            String userNameAttributeName = providerDetails.getUserInfoEndpoint().getUserNameAttributeName();
            if (StringUtils.hasText(userNameAttributeName)) {
                oidcUser = new DefaultOidcUser(mappedAuthorities, oidcUser.getIdToken(), oidcUser.getUserInfo(), userNameAttributeName);
            } else {
                oidcUser = new DefaultOidcUser(mappedAuthorities, oidcUser.getIdToken(), oidcUser.getUserInfo());
            }

            return oidcUser;
        };
    }
}
```

注意这里我禁用了 CSRF ，并且允许 `/track` 和 `/download` 非授权访问。

## 在 Spring 里读取已登录的 Keycloak 用户信息

在适当的地方引用如下依赖：

```java
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.client.authentication.OAuth2AuthenticationToken;
```

获取用户信息的示例如下：

```java
String userFullName = "匿名用户";
Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
System.out.println(authentication.getPrincipal().getClass());
if (authentication.getPrincipal() instanceof DefaultOidcUser) {
    DefaultOidcUser userDetails = (DefaultOidcUser) authentication.getPrincipal();
    userFullName = userDetails.getFullName();
}
```

## 参考资料

https://www.baeldung.com/spring-boot-security-autoconfiguration

https://www.baeldung.com/spring-security-5-oauth2-login

https://spring.io/guides/tutorials/spring-boot-oauth2

https://spring.io/blog/2018/03/06/using-spring-security-5-to-integrate-with-oauth-2-secured-services-such-as-facebook-and-github

https://docs.spring.io/spring-security/reference/5.7/servlet/oauth2/login/advanced.html#oauth2login-advanced-oidc-user-service
