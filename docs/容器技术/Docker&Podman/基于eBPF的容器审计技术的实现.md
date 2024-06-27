---
tags:
  - Podman
  - Tetragon
  - eBPF
---

# 基于 eBPF 的容器审计技术的实现

## 项目需求

某项目需要监视运行在 podman 宿主机内容器中所有文件的修改和系统调用，作为审计日志。日志中至少需要包含执行命令的容器、命令内容或修改的文件。

使用 auditd 无法实现此需求，因为容器内 auditd 无法启动，audit 依赖于内核 kaudit 进程，其工作方式为内核态 kauditd 在系统调用层记录日志，把日志放入一个 netlink 套接字中，用户态 auditd 进程监听这个套接字，将日志转储到系统日志或日志文件中。且一个机器上只要有一个容器或者宿主机开启 auditd ，其它容器或宿主机都无法再次启动 auditd 。

而且， auditd 不支持 namespace ，不可能知道是那个容器里执行了什么命令。因此解决这个方法需要使用 eBPF 内核探针。

此方案在 RHEL8 内核版本 `4.18.0-553.el8_10` ， podman 版本 `4.9.4-rhel` 上测试通过。

## 云原生方案下的容器审计工具 Tetragon

Tetragon 是一个应用于 k8s 、 docker 等容器环境下的审计工具，它依赖于 eBPF 技术，以容器的方式运行，通过 eBPF 的 kprobe 设立 hook 的方式完成对一个容器宿主机上所有容器的命令执行与文件修改、甚至网络连接的审计。本次方案在 podman 容器宿主机上使用此方案实现。

## 运行 Tetragon 容器

首先新建文件审计配置文件 `file_monitoring.yaml` ：

```yaml
apiVersion: cilium.io/v1alpha1
kind: TracingPolicy
metadata:
  name: "file-monitoring-filtered"
spec:
  kprobes:
    - call: "security_file_permission"
      syscall: false
      return: true
      args:
        - index: 0
          type: "file" # (struct file *) used for getting the path
        - index: 1
          type: "int" # 0x04 is MAY_READ, 0x02 is MAY_WRITE
      returnArg:
        index: 0
        type: "int"
      returnArgAction: "Post"
      selectors:
        - matchArgs:
            - index: 0
              operator: "NotPrefix"
              values:
                - "/dev/" # Reads to sensitive directories
                - "/proc/" # Reads to sensitive directories
                - "/var/log/tetragon/tetragon.log"
            - index: 1
              operator: "Equal"
              values:
                - "4" # MAY_READ
        - matchArgs:
            - index: 0
              operator: "NotPrefix"
              values:
                - "/dev" # Writes to sensitive directories
                - "/proc/" # Reads to sensitive directories
                - "/var/log/tetragon/tetragon.log"
            - index: 1
              operator: "Equal"
              values:
                - "2" # MAY_WRITE
    - call: "security_mmap_file"
      syscall: false
      return: true
      args:
        - index: 0
          type: "file" # (struct file *) used for getting the path
        - index: 1
          type: "uint32" # the prot flags PROT_READ(0x01), PROT_WRITE(0x02), PROT_EXEC(0x04)
        - index: 2
          type: "uint32" # the mmap flags (i.e. MAP_SHARED, ...)
      returnArg:
        index: 0
        type: "int"
      returnArgAction: "Post"
      selectors:
        - matchArgs:
            - index: 0
              operator: "Prefix"
              values:
                - "/" # Reads to sensitive directories
            - index: 1
              operator: "Equal"
              values:
                - "1" # MAY_READ
            - index: 2
              operator: "Mask"
              values:
                - "1" # MAP_SHARED
        - matchArgs:
            - index: 0
              operator: "Prefix"
              values:
                - "/" # Writes to sensitive directories
            - index: 1
              operator: "Mask"
              values:
                - "2" # PROT_WRITE
            - index: 2
              operator: "Mask"
              values:
                - "1" # MAP_SHARED
    - call: "security_path_truncate"
      syscall: false
      return: true
      args:
        - index: 0
          type: "path" # (struct path *) used for getting the path
      returnArg:
        index: 0
        type: "int"
      returnArgAction: "Post"
      selectors:
        - matchArgs:
            - index: 0
              operator: "Prefix"
              values:
                - "/" # Truncate to sensitive directories
```

注意，实际使用中，需要对此配置文件进行调整。此配置文件审计所有文件，日志量极大。新建日志存储路径配置 `export-filename` :

```
/var/log/tetragon/tetragon.log
```

之后启动 Tetragon 容器：

```
podman run -d --rm --name tetragon-container --rm \
  --pid=host --cgroupns=host --privileged \
  -v /sys/kernel/btf/vmlinux:/var/lib/tetragon/btf \
  -v ${PWD}/file_monitoring.yaml:/etc/tetragon/tetragon.tp.d/file_monitoring.yaml \
  -v ${PWD}/export-filename:/etc/tetragon/tetragon.conf.d/export-filename \
  quay.io/cilium/tetragon-ci:latest
```

如果想查看实时审计日志：

```
podman exec tetragon-container tetra getevents -o json
```

## 测试审计结果

运行一个临时的 ubuntu 容器：

```
podman run -it --rm ubuntu /bin/bash
```

之后在容器内部，运行命令：

```
useradd testuser
cat /etc/shadow
echo "Hello, world!" > /tmp/passwd
exit
```

之后进入 Tetragon 容器：

```
podman exec -it tetragon-container /bin/bash
```

查看审计日志：

```
grep /tmp/passwd -rni /var/log/tetragon
```

找到审计日志如下：

```json
{
  "process_exit": {
    "process": {
      "exec_id": "OGJiZjEyNWNmNGI3OjI3NzM2NDExODc3ODU0Njg6NTc2NjY0",
      "pid": 576664,
      "uid": 0,
      "cwd": "/",
      "binary": "/usr/sbin/useradd",
      "arguments": "testuser",
      "flags": "execve rootcwd clone",
      "start_time": "2024-06-27T06:06:07.223409055Z",
      "auid": 0,
      "docker": "89052e071b4ae7de344adf937794275",
      "parent_exec_id": "OGJiZjEyNWNmNGI3OjI3NzM2MzU4NzIxMjg2MTI6NTc2NjUy",
      "tid": 576664
    },
    "parent": {
      "exec_id": "OGJiZjEyNWNmNGI3OjI3NzM2MzU4NzIxMjg2MTI6NTc2NjUy",
      "pid": 576652,
      "uid": 0,
      "cwd": "/",
      "binary": "/bin/bash",
      "flags": "execve rootcwd clone",
      "start_time": "2024-06-27T06:06:01.907752059Z",
      "auid": 0,
      "docker": "89052e071b4ae7de344adf937794275",
      "parent_exec_id": "OGJiZjEyNWNmNGI3OjI3NzM2MzU3NTQxODkyNTg6NTc2NjQy",
      "tid": 576652
    },
    "time": "2024-06-27T06:06:07.248861466Z"
  },
  "node_name": "8bbf125cf4b7",
  "time": "2024-06-27T06:06:07.248861562Z"
}
```

```json
{
  "process_kprobe": {
    "process": {
      "exec_id": "OGJiZjEyNWNmNGI3OjI3NzM2NDEyMTM3ODA4ODc6NTc2Njcx",
      "pid": 576671,
      "uid": 0,
      "cwd": "/",
      "binary": "/usr/bin/cat",
      "arguments": "/etc/shadow",
      "flags": "execve rootcwd clone",
      "start_time": "2024-06-27T06:06:07.249404483Z",
      "auid": 0,
      "docker": "89052e071b4ae7de344adf937794275",
      "parent_exec_id": "OGJiZjEyNWNmNGI3OjI3NzM2MzU4NzIxMjg2MTI6NTc2NjUy",
      "refcnt": 1,
      "tid": 576671
    },
    "parent": {
      "exec_id": "OGJiZjEyNWNmNGI3OjI3NzM2MzU4NzIxMjg2MTI6NTc2NjUy",
      "pid": 576652,
      "uid": 0,
      "cwd": "/",
      "binary": "/bin/bash",
      "flags": "execve rootcwd clone",
      "start_time": "2024-06-27T06:06:01.907752059Z",
      "auid": 0,
      "docker": "89052e071b4ae7de344adf937794275",
      "parent_exec_id": "OGJiZjEyNWNmNGI3OjI3NzM2MzU3NTQxODkyNTg6NTc2NjQy",
      "tid": 576652
    },
    "function_name": "security_file_permission",
    "args": [
      { "file_arg": { "path": "/etc/shadow", "permission": "-rw-r-----" } },
      { "int_arg": 4 }
    ],
    "return": { "int_arg": 0 },
    "action": "KPROBE_ACTION_POST",
    "policy_name": "file-monitoring-filtered",
    "return_action": "KPROBE_ACTION_POST"
  },
  "node_name": "8bbf125cf4b7",
  "time": "2024-06-27T06:06:07.249857560Z"
}
```

```json
{
  "process_kprobe": {
    "process": {
      "exec_id": "OGJiZjEyNWNmNGI3OjI3NzM2MzU4NzIxMjg2MTI6NTc2NjUy",
      "pid": 576652,
      "uid": 0,
      "cwd": "/",
      "binary": "/bin/bash",
      "flags": "execve rootcwd clone",
      "start_time": "2024-06-27T06:06:01.907752059Z",
      "auid": 0,
      "docker": "89052e071b4ae7de344adf937794275",
      "parent_exec_id": "OGJiZjEyNWNmNGI3OjI3NzM2MzU3NTQxODkyNTg6NTc2NjQy",
      "refcnt": 1,
      "tid": 576652
    },
    "parent": {
      "exec_id": "OGJiZjEyNWNmNGI3OjI3NzM2MzU3NTQxODkyNTg6NTc2NjQy",
      "pid": 576642,
      "uid": 0,
      "cwd": "/tmp",
      "binary": "/usr/bin/conmon",
      "arguments": "--api-version 1 -c 89052e071b4ae7de344adf937794275ccdb977e9d4aa1d68a9fdb5cc63959048 -u 89052e071b4ae7de344adf937794275ccdb977e9d4aa1d68a9fdb5cc63959048 -r /usr/bin/runc -b /var/lib/containers/storage/overlay-containers/89052e071b4ae7de344adf937794275ccdb977e9d4aa1d68a9fdb5cc63959048/userdata -p /run/containers/storage/overlay-containers/89052e071b4ae7de344adf937794275ccdb977e9d4aa1d68a9fdb5cc63959048/userdata/pidfile -n angry_wozniak --exit-dir /run/libpod/exits --full-attach -s -l k8s-file:/var/lib/containers/storage/overlay-containers/89052e071b4ae7de344adf937794275ccdb977e9d4aa1d68a9fdb5cc63959048/userdata/ctr.log --log-level warning --syslog --runtime-arg --log-format=json --runtime-arg --log --runtime-arg=/run/containers/storage/overlay-containers/89052e071b4ae7de344adf937794275ccdb977e9d4aa1d68a9fdb5cc63959048/userdata/oci-log -t --conmon-pidfile /run/containers/storage/overlay-containers/89052e071b4ae7de344adf937794275ccdb977e9d4aa1d68a9fdb5cc63959048/userdata/conmon.pid --exit-command /usr/bin/podman --exit-command-arg --root --exit-command-arg /var/lib/containers/storage --exit-command-arg --runroot --exit-command-arg /run/containers/storage --exit-command-arg --log-level --exit-command-arg warning --exit-command-arg --cgroup-manager --exit-command-arg systemd --exit-command-arg --tmpdir --exit-command-arg /run/libpod --exit-command-arg --network-config-dir --exit-command-arg  --exit-command-arg --network-backend --exit-command-arg cni --exit-command-arg --volumepath --exit-command-arg /var/lib/containers/storage/volumes --exit-command-arg --db-backend --exit-command-arg sqlite --exit-command-arg --transient-store=false --exit-command-arg --runtime --exit-command-arg runc --exit-command-arg --storage-driver --exit-command-arg overlay --exit-command-arg --storage-opt --exit-command-arg overlay.mountopt=nodev,metacopy=on --exit-command-arg --events-backend --exit-command-arg file --exit-command-arg container --exit-command-arg cleanup --exit-command-arg --rm --exit-command-arg 89052e071b4ae7de344adf937794275ccdb977e9d4aa1d68a9fdb5cc63959048",
      "flags": "execve",
      "start_time": "2024-06-27T06:06:01.789813045Z",
      "auid": 0,
      "parent_exec_id": "OGJiZjEyNWNmNGI3OjI3NzM2MzU3NDM1NTE5NDM6NTc2NjQx",
      "refcnt": 1,
      "tid": 576642
    },
    "function_name": "security_file_permission",
    "args": [
      { "file_arg": { "path": "/tmp/passwd", "permission": "-rw-r--r--" } },
      { "int_arg": 2 }
    ],
    "return": { "int_arg": 0 },
    "action": "KPROBE_ACTION_POST",
    "policy_name": "file-monitoring-filtered",
    "return_action": "KPROBE_ACTION_POST"
  },
  "node_name": "8bbf125cf4b7",
  "time": "2024-06-27T06:06:07.250057584Z"
}
```

## 参考资料

https://tetragon.io/docs/getting-started/file-events/

https://tetragon.io/docs/concepts/tracing-policy/options/

https://github.com/cilium/tetragon/blob/main/examples/quickstart/file_monitoring.yaml

https://medium.com/@boutnaru/the-linux-process-journey-kauditd-25718f6c502d

https://medium.com/@rhonnava/audit-logging-with-container-id-tagging-65e92c570f12

https://access.redhat.com/articles/4494341
