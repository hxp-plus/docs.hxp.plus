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

## 为 ProxyJump 跳板用户免除 OTP

如果需要新建一个专用于 SSH ProxyJump 的用户（如 `proxy`），该用户仅做端口转发跳板、不分配 shell、不需要 OTP，其他用户仍走公钥 + OTP 双因素认证，按以下步骤配置。

### 1. 创建 proxy 用户

```bash
sudo useradd -m -s /sbin/nologin proxy
```

!!! note

    `-s /sbin/nologin` 使该用户无法获得 shell，但 SSH ProxyJump（端口转发）不需要 shell 也能正常工作。

### 2. 修改 PAM 配置：proxy 用户跳过 OTP

编辑 `/etc/pam.d/sshd`，将原来的：

```pam
auth required pam_google_authenticator.so
```

改为：

```pam
# proxy 用户跳过 OTP，其他用户必须 OTP
auth [success=done default=ignore] pam_succeed_if.so user = proxy
auth required pam_google_authenticator.so
```

- `pam_succeed_if.so user = proxy` — 如果当前用户是 `proxy`，`success=done` 直接跳过后续 auth 模块（OTP 被跳过）
- 其他用户匹配 `default=ignore`，继续走下一行 `pam_google_authenticator.so`

### 3. 修改 sshd_config：proxy 用户仅需公钥

在 `/etc/ssh/sshd_config` 中，`AuthenticationMethods` 下方增加 `Match` 块：

```conf
# 普通用户：公钥 + OTP
AuthenticationMethods publickey,keyboard-interactive

# proxy 用户：仅公钥即可
Match User proxy
    AuthenticationMethods publickey
    AllowTcpForwarding yes
    X11Forwarding no
    PermitTTY no
    GatewayPorts no
```

### 4. 为 proxy 用户配置公钥

```bash
sudo mkdir -p /home/proxy/.ssh
sudo cp /path/to/authorized_keys /home/proxy/.ssh/authorized_keys
sudo chown -R proxy:proxy /home/proxy/.ssh
sudo chmod 700 /home/proxy/.ssh
sudo chmod 600 /home/proxy/.ssh/authorized_keys
```

!!! note

    proxy 用户不需要运行 `google-authenticator`，PAM 层已经跳过了 OTP 验证。

### 5. 验证并重启

```bash
sudo sshd -t && sudo systemctl restart sshd
```

### 使用示例

在其他机器的 `~/.ssh/config` 中通过跳板机连接目标服务器：

```ssh-config
Host via-proxy
    HostName target.example.com
    ProxyJump proxy@jump-server
    IdentityFile ~/.ssh/id_ed25519
```

### 安全要点

| 措施                                                   | 作用                                           |
| ------------------------------------------------------ | ---------------------------------------------- |
| `-s /sbin/nologin`                                     | proxy 用户无法获得 shell                       |
| `PermitTTY no`                                         | 禁止分配终端                                   |
| `Match User proxy` + `AuthenticationMethods publickey` | 仅需公钥，无 OTP                               |
| 不为 proxy 生成 OTP secret                             | 纵深防御，即使 PAM 配置出错也无法通过 OTP 认证 |

!!! warning

    `DisablePTTY` 不是 OpenSSH 合法指令，不要使用，`PermitTTY no` 已足够。
