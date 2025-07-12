---
tags:
  - Linux
  - OTP
  - google-authenticator
---

# Linux 开启 OTP 认证

## 安装 google-authenticator

CentOS 运行：

```bash
sudo yum install epel-release
sudo dnf install google-authenticator qrencode qrencode-libs
```

## 配置令牌

直接使用 google-authenticator 配置（此处配置的是当前用户令牌）：

```bash
google-authenticator
```

## 配置 PAM

编辑 `/etc/pam.d/sshd` ：

```pam
auth required pam_google_authenticator.so
```

## 配置 sshd 使用二次验证

修改 `/etc/ssh/sshd_config` 配置，加入：

```conf
AuthenticationMethods publickey,keyboard-interactive
```

找到 `/etc/ssh/sshd_config.d/50-redhat.conf` 并注释以下行：

```conf
ChallengeResponseAuthentication no
```

检查配置无误后重启 sshd 服务：

```bash
sudo sshd -t && sudo systemctl restart sshd
```

此时 SSH 登录会变成需要公钥、密码和二次认证码，如果要求只要公钥和二次认证码，找到 `/etc/pam.d/sshd` 并注释：

```pam
auth       substack     password-auth
```
