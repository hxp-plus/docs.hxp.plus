---
tags:
  - OpenStack
---

# OpenStack 租户网络


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

原英文标题：OpenStack Tenant Network

 ## 环境描述

### 外部网络

需要 5 台可访问外网的 CentOS 8.3 服务器。下表描述了硬件需求。

| 角色       | 主机名   | IP 地址   | CPU    | 内存  | 磁盘  |
| ---------- | ---------- | ------------ | ------ | ---- | ----- |
| Controller | controller | 192.168.8.10 | 2vCPUs | 8GB  | 100GB |
| Compute    | compute01  | 192.168.8.20 | 4vCPUs | 16GB | 200GB |
| Compute    | compute02  | 192.168.8.21 | 4vCPUs | 16GB | 200GB |
| Network    | network    | 192.168.8.30 | 2vCPUs | 8GB  | 100GB |
| NTP        | ntp        | 192.168.8.40 | 1vCPU  | 2GB  | 20GB  |

网络配置如下

- 网关 IP 地址: 192.168.8.1
- 子网地址: 192.168.8.0/24
- 可用 IP 地址: 192.168.8.50 - 150
- DNS 服务器: 192.168.8.1

### 内部网络

下表描述了硬件需求。

| 角色       | 主机名   | IP 地址     |
| ---------- | ---------- | -------------- |
| Controller | controller | 192.168.128.10 |
| Compute    | compute01  | 192.168.128.20 |
| Compute    | compute02  | 192.168.128.21 |
| Network    | network    | 192.168.128.30 |

网络配置如下

- 子网地址: 192.168.128.0/24

---

## 原文（English）

# OpenStack Tenant Network


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

 ## Environment Description

### External Network

5 CentOS 8.3 with external network access is needed. The following table describes the hardware requirements.

| Role       | hostname   | IP address   | CPU    | RAM  | Disk  |
| ---------- | ---------- | ------------ | ------ | ---- | ----- |
| Controller | controller | 192.168.8.10 | 2vCPUs | 8GB  | 100GB |
| Compute    | compute01  | 192.168.8.20 | 4vCPUs | 16GB | 200GB |
| Compute    | compute02  | 192.168.8.21 | 4vCPUs | 16GB | 200GB |
| Network    | network    | 192.168.8.30 | 2vCPUs | 8GB  | 100GB |
| NTP        | ntp        | 192.168.8.40 | 1vCPU  | 2GB  | 20GB  |

Network configuration is described below

- Gateway IP Address: 192.168.8.1
- Subnet Address: 192.168.8.0/24
- Available IP Address: 192.168.8.50 - 150
- DNS Server: 192.168.8.1

### Internal Network

The following table describes the hardware requirements.

| Role       | hostname   | IP address     |
| ---------- | ---------- | -------------- |
| Controller | controller | 192.168.128.10 |
| Compute    | compute01  | 192.168.128.20 |
| Compute    | compute02  | 192.168.128.21 |
| Network    | network    | 192.168.128.30 |

Network configuration is described below

- Subnet Address: 192.168.128.0/24
