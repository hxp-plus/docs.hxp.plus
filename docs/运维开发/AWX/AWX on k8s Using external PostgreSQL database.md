---
tags:
  - AWX
  - Kubernetes
  - Ansible
---

# AWX on k8s: Using external PostgreSQL database


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## 外部 PostgreSQL 配置

安装 PostgreSQL 13：

```
sudo dnf install https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo dnf -qy module disable postgresql
sudo dnf install postgresql13 postgresql13-server
/usr/pgsql-13/bin/postgresql-13-setup initdb
systemctl enable --now postgresql-13
```

创建用户和数据库：

```
[root@haproxy-1 ~]# su - postgres
[postgres@haproxy-1 ~]$ psql
psql (10.23)
Type "help" for help.

postgres=# CREATE USER awx WITH ENCRYPTED PASSWORD 'awx';
CREATE ROLE
postgres=# CREATE DATABASE awx OWNER awx;
CREATE DATABASE
```

在 `/var/lib/pgsql/13/data/pg_hba.conf` 中添加以下行：

```
host    all             all             0.0.0.0/0               md5
host    all             all             ::/0                    md5
```

编辑 `/var/lib/pgsql/13/data/postgresql.conf`：

```
#listen_addresses = 'localhost'
listen_addresses = '*'
```

重启 PostgreSQL：

```
systemctl restart postgresql-13
```

## AWX 配置

首先使用 managed Postgres 配置 AWX：

```
[root@k8s-1 ~]# cat awx-postgres-configuration.yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: awx-postgres-configuration
  namespace: awx
stringData:
  host: 192.168.100.11
  port: "5432"
  database: awx
  username: awx
  password: awx
  sslmode: prefer
  type: managed
type: Opaque
[root@k8s-1 ~]# kubectl apply -f awx-postgres-configuration.yaml
secret/awx-postgres-configuration configured
```

```
[root@k8s-1 ~]# cat awx-demo.yaml
---
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx-demo
  namespace: awx
spec:
...
  postgres_configuration_secret: awx-postgres-configuration
...
[root@k8s-1 ~]# kubectl apply -f awx-demo.yaml
awx.awx.ansible.com/awx-demo configured
```

如果之前没有配置用户，请创建数据库用户 AWX：

```
[root@k8s-1 ~]# kubectl -n awx exec -it pods/awx-demo-web-576544b489-xv9ml -- /bin/bash
bash-5.1$ psql -h mypostgres -U postgres
Password for user postgres:
psql (13.11, server 13.0 (Debian 13.0-1.pgdg100+1))
Type "help" for help.

postgres=# CREATE USER awx WITH ENCRYPTED PASSWORD 'awx';
CREATE ROLE
postgres=# CREATE DATABASE awx OWNER awx;
CREATE DATABASE
postgres=# exit
bash-5.1$ exit
exit
```

获取部署日志：

```
kubectl -n awx logs -f pods/awx-operator-controller-manager-66c5b94884-l2pks
```

然后删除 AWX，并使用 unmanaged Postgres 重新创建：

```
[root@k8s-1 ~]# kubectl delete -f awx-demo.yaml
```

```
[root@k8s-1 ~]# cat awx-postgres-configuration.yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: awx-postgres-configuration
  namespace: awx
stringData:
...
  type: unmanaged
...
[root@k8s-1 ~]# kubectl apply -f awx-postgres-configuration.yaml
secret/awx-postgres-configuration configured
[root@k8s-1 ~]# kubectl apply -f awx-demo.yaml
[root@k8s-1 ~]# kubectl get pods -n awx
NAME                                               READY   STATUS    RESTARTS   AGE
awx-demo-task-59b956677f-t5jq8                     4/4     Running   0          3m46s
awx-demo-web-6879fb9bd-hblp2                       3/3     Running   0          3m39s
awx-operator-controller-manager-66c5b94884-8xxwk   2/2     Running   0          3h33m
```

# 参考链接

<https://elatov.github.io/2022/03/deploying-awx-in-k8s-with-awx-operator/>

<https://github.com/ansible/awx-operator/blob/8391ed3501ff326647485b7272e537942da0dd68/docs/user-guide/database-configuration.md?plain=1#L7>

<https://tecadmin.net/postgresql-allow-remote-connections/>

<https://computingforgeeks.com/install-postgresql-13-on-centos-rhel/>

<https://github.com/ansible/awx-operator/issues/1190>

---

## 原文（English）

```
---
tags:
  - AWX
  - Kubernetes
  - Ansible
---

# AWX on k8s: Using external PostgreSQL database


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## External PostgreSQL setup

Install PostgreSQL 13:

```
sudo dnf install https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo dnf -qy module disable postgresql
sudo dnf install postgresql13 postgresql13-server
/usr/pgsql-13/bin/postgresql-13-setup initdb
systemctl enable --now postgresql-13
```

create user and database:

```
[root@haproxy-1 ~]# su - postgres
[postgres@haproxy-1 ~]$ psql
psql (10.23)
Type "help" for help.

postgres=# CREATE USER awx WITH ENCRYPTED PASSWORD 'awx';
CREATE ROLE
postgres=# CREATE DATABASE awx OWNER awx;
CREATE DATABASE
```

Add a line below in `/var/lib/pgsql/13/data/pg_hba.conf` :

```
host    all             all             0.0.0.0/0               md5
host    all             all             ::/0                    md5
```

Edit `/var/lib/pgsql/13/data/postgresql.conf` :

```
#listen_addresses = 'localhost'
listen_addresses = '*'
```

Restart PostgreSQL :

```
systemctl restart postgresql-13
```

## AWX setup

first setup AWX with managed Postgres :

```
[root@k8s-1 ~]# cat awx-postgres-configuration.yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: awx-postgres-configuration
  namespace: awx
stringData:
  host: 192.168.100.11
  port: "5432"
  database: awx
  username: awx
  password: awx
  sslmode: prefer
  type: managed
type: Opaque
[root@k8s-1 ~]# kubectl apply -f awx-postgres-configuration.yaml
secret/awx-postgres-configuration configured
```

```
[root@k8s-1 ~]# cat awx-demo.yaml
---
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx-demo
  namespace: awx
spec:
...
  postgres_configuration_secret: awx-postgres-configuration
...
[root@k8s-1 ~]# kubectl apply -f awx-demo.yaml
awx.awx.ansible.com/awx-demo configured
```

create database user AWX if the user is not configured before :

```
[root@k8s-1 ~]# kubectl -n awx exec -it pods/awx-demo-web-576544b489-xv9ml -- /bin/bash
bash-5.1$ psql -h mypostgres -U postgres
Password for user postgres:
psql (13.11, server 13.0 (Debian 13.0-1.pgdg100+1))
Type "help" for help.

postgres=# CREATE USER awx WITH ENCRYPTED PASSWORD 'awx';
CREATE ROLE
postgres=# CREATE DATABASE awx OWNER awx;
CREATE DATABASE
postgres=# exit
bash-5.1$ exit
exit
```

get the deployment logs by:

```
kubectl -n awx logs -f pods/awx-operator-controller-manager-66c5b94884-l2pks
```

and then delete AWX, and recreate it with unmanaged Postgres :

```
[root@k8s-1 ~]# kubectl delete -f awx-demo.yaml
```

```
[root@k8s-1 ~]# cat awx-postgres-configuration.yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: awx-postgres-configuration
  namespace: awx
stringData:
...
  type: unmanaged
...
[root@k8s-1 ~]# kubectl apply -f awx-postgres-configuration.yaml
secret/awx-postgres-configuration configured
[root@k8s-1 ~]# kubectl apply -f awx-demo.yaml
[root@k8s-1 ~]# kubectl get pods -n awx
NAME                                               READY   STATUS    RESTARTS   AGE
awx-demo-task-59b956677f-t5jq8                     4/4     Running   0          3m46s
awx-demo-web-6879fb9bd-hblp2                       3/3     Running   0          3m39s
awx-operator-controller-manager-66c5b94884-8xxwk   2/2     Running   0          3h33m
```

# References

<https://elatov.github.io/2022/03/deploying-awx-in-k8s-with-awx-operator/>

<https://github.com/ansible/awx-operator/blob/8391ed3501ff326647485b7272e537942da0dd68/docs/user-guide/database-configuration.md?plain=1#L7>

<https://tecadmin.net/postgresql-allow-remote-connections/>

<https://computingforgeeks.com/install-postgresql-13-on-centos-rhel/>

<https://github.com/ansible/awx-operator/issues/1190>
```
