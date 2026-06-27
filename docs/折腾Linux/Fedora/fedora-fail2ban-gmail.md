---
tags:
  - Fedora
  - Linux
---

# Setting up fail2ban with Gmail notification to secure your Fedora server from brute force

!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## Step 0: 安装 fail2ban

```
yum install fail2ban
systemctl enable fail2ban --now
nano /etc/fail2ban/jail.local
```

在 `/etc/fail2ban/jail.local` 中添加以下内容：

```
[DEFAULT]
bantime = 3600
maxretry = 5

[sshd]
enabled = true
```

重新加载 fail2ban：

```
systemctl restart fail2ban
```

## Step 1: 配置 sendmail 以使用 Gmail

安装 sendmail：

```
yum install sendmail sendmail-cf
```

创建认证文件：

```
mkdir -p /etc/mail/authinfo
chmod 700 /etc/mail/authinfo
nano /etc/mail/authinfo/gmail-auth
```

配置用户名和密码，添加：

```
AuthInfo: "U:root" "I:user@gmail.com" "P:PASSWORD"
```

然后生成 hash：

```
makemap hash /etc/mail/authinfo/gmail-auth < /etc/mail/authinfo/gmail-auth
```

编辑 `/etc/mail/sendmail.mc`，将以下内容放到 sendmail.mc 配置文件中第一个 "MAILER" 定义行的上方：

```
define(`SMART_HOST',`[smtp.gmail.com]')dnl
define(`RELAY_MAILER_ARGS', `TCP $h 587')dnl
define(`ESMTP_MAILER_ARGS', `TCP $h 587')dnl
define(`confAUTH_OPTIONS', `A p')dnl
TRUST_AUTH_MECH(`EXTERNAL DIGEST-MD5 CRAM-MD5 LOGIN PLAIN')dnl
define(`confAUTH_MECHANISMS', `EXTERNAL GSSAPI DIGEST-MD5 CRAM-MD5 LOGIN PLAIN')dnl
FEATURE(`authinfo',`hash -o /etc/mail/authinfo/gmail-auth.db')dnl
```

不要将以上内容放在 sendmail.mc 配置文件的顶部！

下一步需要重新构建 sendmail 的配置。执行：

```
make -C /etc/mail
```

重新加载：

```
systemctl restart sendmail
```

测试配置：

```
echo "Just testing my sendmail gmail relay" | mail -s "Sendmail gmail Relay" my-email@my-domain.com
```

然后遇到了以下错误：

```
Aug 22 09:56:56 hxp-us-server sendmail[27062]: No worthy mechs found
Aug 22 09:56:56 hxp-us-server sendmail[27062]: 07M1sPB2026583: AUTH=client, available mechanisms do not fulfill requirements
Aug 22 09:56:56 hxp-us-server sendmail[27062]: AUTH=client, relay=smtp.gmail.com., temporary failure, connection abort
```

通过运行以下命令解决：

```
yum install cyrus-sasl*
```

再次发送邮件后，立即在 `/var/spool/mail/root` 收到了邮件：

```
>>> AUTH dialogue
<<< 534-5.7.9 Application-specific password required. Learn more at
<<< 534 5.7.9  https://support.google.com/mail/?p=InvalidSecondFactor t123sm644947oie.40 - gsmtp
```

这表明需要使用应用专用密码（Application-specific password）。

创建一个应用专用密码，替换 `/etc/mail/authinfo/gmail-auth` 中的密码，然后重新生成 hash。

再次重试发送，几秒钟后，邮件成功到达了我的 Gmail。

## Step 2: 配置 fail2ban 发送邮件

编辑 `/etc/fail2ban/jail.local`：

```
[DEFAULT]
destemail = yourname@example.com
sender = yourname@example.com

# 封禁并发送包含 whois 报告的邮件到 destemail
action = %(action_mw)s

# 与 action_mw 相同，但还会发送相关日志行
#action = %(action_mwl)s
```

重启 `fail2ban`：

又出现了另一个问题：

```
Aug 22 10:20:26 hxp-us-server sendmail[27826]: My unqualified host name (hxp-us-server) unknown; sleeping for retry
Aug 22 10:21:29 hxp-us-server sendmail[27854]: My unqualified host name (hxp-us-server) unknown; sleeping for retry
Aug 22 10:22:29 hxp-us-server sendmail[27872]: My unqualified host name (hxp-us-server) unknown; sleeping for retry
```

将主机名 `hxp-us-server` 添加到 `/etc/hosts` 解决了问题：

```
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4 hxp-us-server
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6 hxp-us-server
```

## Step 3: 检查 IP 是否确实被封禁

```
ipset list
```

---

## 原文（English）

---
tags:
  - Fedora
  - Linux
---

# Setting up fail2ban with Gmail notification to secure your Fedora server from brute force

!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## Step 0: Install fail2ban

```
yum install fail2ban
systemctl enable fail2ban --now
nano /etc/fail2ban/jail.local
```

Add these lines in `/etc/fail2ban/jail.local`

```
[DEFAULT]
bantime = 3600
maxretry = 5

[sshd]
enabled = true
```

Reload fail2ban

```
systemctl restart fail2ban
```

## Step 1: Configure sendmail to use Gmail

Install sendmail
```
yum install sendmail sendmail-cf
```

Create Auth file

```
mkdir -p /etc/mail/authinfo
chmod 700 /etc/mail/authinfo
nano /etc/mail/authinfo/gmail-auth
```

Configure your username and password, add

```
AuthInfo: "U:root" "I:user@gmail.com" "P:PASSWORD"
```

and then create hash

```
makemap hash /etc/mail/authinfo/gmail-auth < /etc/mail/authinfo/gmail-auth
```

Edit `/etc/mail/sendmail.rc`,Put bellow lines into your sendmail.mc configuration file right above first "MAILER" definition line:

```
define(`SMART_HOST',`[smtp.gmail.com]')dnl
define(`RELAY_MAILER_ARGS', `TCP $h 587')dnl
define(`ESMTP_MAILER_ARGS', `TCP $h 587')dnl
define(`confAUTH_OPTIONS', `A p')dnl
TRUST_AUTH_MECH(`EXTERNAL DIGEST-MD5 CRAM-MD5 LOGIN PLAIN')dnl
define(`confAUTH_MECHANISMS', `EXTERNAL GSSAPI DIGEST-MD5 CRAM-MD5 LOGIN PLAIN')dnl
FEATURE(`authinfo',`hash -o /etc/mail/authinfo/gmail-auth.db')dnl
```
Do not put the above lines on the top of your sendmail.mc configuration file !

In the next step we will need to re-build sendmail's configuration. To do that execute:

```
make -C /etc/mail
```

Reload

```
systemctl restart sendmail
```

Configuration test

```
echo "Just testing my sendmail gmail relay" | mail -s "Sendmail gmail Relay" my-email@my-domain.com
```

Then I encountered an error:

```
Aug 22 09:56:56 hxp-us-server sendmail[27062]: No worthy mechs found
Aug 22 09:56:56 hxp-us-server sendmail[27062]: 07M1sPB2026583: AUTH=client, available mechanisms do not fulfill requirements
Aug 22 09:56:56 hxp-us-server sendmail[27062]: AUTH=client, relay=smtp.gmail.com., temporary failure, connection abort
```

Solved it by running

```
yum install cyrus-sasl*
```

And then send mail agian, instantly, I received a mail at `/var/spool/mail/root`

```
>>> AUTH dialogue
<<< 534-5.7.9 Application-specific password required. Learn more at
<<< 534 5.7.9  https://support.google.com/mail/?p=InvalidSecondFactor t123sm644947oie.40 - gsmtp
```

Indicating that we need Application-specific password

Create one app password and replace the password in `/etc/mail/authinfo/gmail-auth`, and remake hash.

And then retry sending, after a few seconds, the email arrived at my gmail.

## Step 2: Configure fail2ban to send email

Edit `/etc/fail2ban/jail.local`

```
[DEFAULT]
destemail = yourname@example.com
sender = yourname@example.com

# to ban & send an e-mail with whois report to the destemail.
action = %(action_mw)s

# same as action_mw but also send relevant log lines
#action = %(action_mwl)s
```

Restart `fail2ban`

Another problem occured:

```
Aug 22 10:20:26 hxp-us-server sendmail[27826]: My unqualified host name (hxp-us-server) unknown; sleeping for retry
Aug 22 10:21:29 hxp-us-server sendmail[27854]: My unqualified host name (hxp-us-server) unknown; sleeping for retry
Aug 22 10:22:29 hxp-us-server sendmail[27872]: My unqualified host name (hxp-us-server) unknown; sleeping for retry
```

Add my hostname `hxp-us-server` to `/etc/hosts` solved the problem

```
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4 hxp-us-server
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6 hxp-us-server
```

# Step 3: Check if an ip is really banned

```
ipset list
```