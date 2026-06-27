---
tags:
  - AWX
  - Kubernetes
  - Ansible
---
# AWX-ee执行环境容器镜像封装

!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## 准备环境

```bash
yum install podman
python3 -m venv .
source bin/activate
pip install ansible-builder==3.0.1
```
## 编写yaml配置文件
编写配置文件`execution-environment.yml`：
```yaml
---
version: 3

build_arg_defaults:
  ANSIBLE_GALAXY_CLI_COLLECTION_OPTS: "--pre"

dependencies:
  ansible_core:
    package_pip: ansible-core==2.15.9
  ansible_runner:
    package_pip: ansible-runner==2.3.6
  galaxy:
    collections:
      - awx.awx
      - ansible.posix
      - community.general
      - community.postgresql
      - community.mysql
      - community.mongodb
  python:
    - six
    - psutil
    - et
    - et-xmlfile
    - openpyxl
    - xlrd
  system:
    - sqlite
    - openssh-clients
    - sshpass
    - mariadb

images:
  base_image:
    name: quay.io/centos/centos:stream9
    # Other available base images:

    #   - quay.io/rockylinux/rockylinux:9
    #   - quay.io/centos/centos:stream9
    #   - registry.fedoraproject.org/fedora:38
    #   - registry.redhat.io/ansible-automation-platform-23/ee-minimal-rhel8:latest
    #     (needs an account)
# additional_build_files:
#     - src: files/ansible.cfg
#       dest: configs

# additional_build_steps:
#   prepend_base:
#     # Enable Non-default stream before packages provided by it can be installed. (optional)
#     - RUN $PKGMGR module enable postgresql:15 -y
#     - RUN $PKGMGR install -y postgresql
#   prepend_galaxy:
#     - ADD _build/configs/ansible.cfg ~/.ansible.cfg

# prepend_final: |
#   RUN whoami
#   RUN cat /etc/os-release
# append_final:
#   - RUN echo This is a post-install command!
#   - RUN ls -la /etc

```
## 构建镜像

```bash
ansible-builder build --tag=custom-awx-ee --container-runtime=podman --verbosity=3 --squash all
```
## 导出镜像
```bash
podman image tag custom-awx-ee boc.cn/awx-ee:v240329
podman image save boc.cn/awx-ee:v240329 | gzip > boc.cn_awx-ee_v240329.tar.gz
```
## 参考文献

<https://docs.ansible.com/automation-controller/latest/html/userguide/execution_environments.html>

<https://docs.ansible.com/automation-controller/4.0.0/html_ja/userguide/ee_reference.html>

<https://ansible.readthedocs.io/projects/builder/en/latest/usage/>

<https://medium.com/@frederic.egmorte/awx-create-a-new-execution-environment-with-ansible-builder-aee127d5bbdd>

<https://ansible.readthedocs.io/projects/builder/en/stable/definition/#version-3-sample-file>

<https://ansible.readthedocs.io/en/latest/getting_started_ee/build_execution_environment/>

<https://ansible.readthedocs.io/en/latest/getting_started_ee/index.html>

---

## 原文（English）

```
---
tags:
  - AWX
  - Kubernetes
  - Ansible
---

!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## 准备环境

```bash
yum install podman
python3 -m venv .
source bin/activate
pip install Ansible-builder==3.0.1
```
## 编写yaml配置文件
编写配置文件`execution-environment.yml`：
```yaml
---
version: 3

build_arg_defaults:
  ANSIBLE_GALAXY_CLI_COLLECTION_OPTS: "--pre"

dependencies:
  ansible_core:
    package_pip: Ansible-core==2.15.9
  ansible_runner:
    package_pip: Ansible-runner==2.3.6
  galaxy:
    collections:
      - AWX.AWX
      - Ansible.posix
      - community.general
      - community.PostgreSQL
      - community.MySQL
      - community.mongodb
  Python:
    - six
    - psutil
    - et
    - et-xmlfile
    - openpyxl
    - xlrd
  system:
    - sqlite
    - openssh-clients
    - sshpass
    - mariadb

images:
  base_image:
    name: quay.io/CentOS/CentOS:stream9
    # Other available base images:

    #   - quay.io/rockylinux/rockylinux:9
    #   - quay.io/centos/centos:stream9
    #   - registry.fedoraproject.org/fedora:38
    #   - registry.redhat.io/ansible-automation-platform-23/ee-minimal-rhel8:latest
    #     (needs an account)
# additional_build_files:
#     - src: files/ansible.cfg
#       dest: configs

# additional_build_steps:
#   prepend_base:
#     # Enable Non-default stream before packages provided by it can be installed. (optional)
#     - RUN $PKGMGR module enable postgresql:15 -y
#     - RUN $PKGMGR install -y postgresql
#   prepend_galaxy:
#     - ADD _build/configs/ansible.cfg ~/.ansible.cfg

# prepend_final: |
#   RUN whoami
#   RUN cat /etc/os-release
# append_final:
#   - RUN echo This is a post-install command!
#   - RUN ls -la /etc

```
## 构建镜像

```bash
Ansible-builder build --tag=custom-AWX-ee --container-runtime=podman --verbosity=3 --squash all
```
## 导出镜像
```bash
podman image tag custom-AWX-ee boc.cn/AWX-ee:v240329
podman image save boc.cn/AWX-ee:v240329 | gzip > boc.cn_awx-ee_v240329.tar.gz
```
## 参考文献

<https://docs.ansible.com/automation-controller/latest/html/userguide/execution_environments.html>

<https://docs.ansible.com/automation-controller/4.0.0/html_ja/userguide/ee_reference.html>

<https://ansible.readthedocs.io/projects/builder/en/latest/usage/>

<https://medium.com/@frederic.egmorte/awx-create-a-new-execution-environment-with-ansible-builder-aee127d5bbdd>

<https://ansible.readthedocs.io/projects/builder/en/stable/definition/#version-3-sample-file>

<https://ansible.readthedocs.io/en/latest/getting_started_ee/build_execution_environment/>

<https://ansible.readthedocs.io/en/latest/getting_started_ee/index.html>
```
