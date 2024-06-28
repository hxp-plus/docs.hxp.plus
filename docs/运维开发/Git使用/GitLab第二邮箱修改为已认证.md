---
tags:
  - GitLab
---

# GitLab 第二邮箱修改为已认证

## 问题背景

在内网环境中使用 GitLab ，如果需要添加第二个电子邮件，电子邮件需要被验证，但是验证的邮件发不出去，就无法验证并完成添加。此时需要一种方法手动修改邮箱为已认证。

## 登录 Rails 控制台手动修改第二邮箱为已认证

登录到 GitLab 服务器上，进入 Rails 控制台修改邮箱为已认证：

```
[root@gitlab gitlab]# gitlab-rails console production
-------------------------------------------------------------------------------------
 GitLab:       11.5.1 (c90ae59)
 GitLab Shell: 8.4.1
 postgresql:   9.6.8
-------------------------------------------------------------------------------------
Both Deployment and its :status machine have defined a different default for "status". Use only one or the other for defining defaults to avoid unexpected behaviors.
Loading production environment (Rails 4.2.10)
irb(main):003:0> email = Email.find_by(email: "hxp@hxp.plus")
=> #<Email id: 2, user_id: 51, email: "hxp@hxp.plus", created_at: "2024-06-05 03:59:21", updated_at: "2024-06-05 03:59:21">
irb(main):004:0> email.confirmed_at = Time.zone.now
=> Wed, 05 Jun 2024 04:37:42 UTC +00:00
irb(main):005:0> email.save!
=> true
irb(main):006:0> exit
```

## 参考资料

https://gist.github.com/macdja38/3d62d4f251bd7c46f0128bb6a9d35544
