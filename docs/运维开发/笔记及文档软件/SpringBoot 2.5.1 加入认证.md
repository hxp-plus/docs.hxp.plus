---
tags:
  - Spring Security
  - SpringBoot
  - Java
---

# SpringBoot 2.5.1 加入认证

在 `pom.xml` 加入依赖：

```xml
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-security</artifactId>
</dependency>
```

添加 application.properties 配置：

```ini
spring.security.user.name=admin
spring.security.user.password=password
```

## 参考资料

https://www.baeldung.com/spring-boot-security-autoconfiguration
