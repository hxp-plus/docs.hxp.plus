# 华为 HCS 8 与银河麒麟 V10SP4 cloud-init 适配问题解决

## 问题现象

在制作银河麒麟 V10SP4 虚拟机镜像时，安装后检查发现没有安装 cloud-init ，进一步调查 packer 日志如下：

```
qemu: install-cloud-init.sh executing ......
qemu: /usr/bin/python3
qemu: python version check success
qemu: /usr/bin/systemctl
qemu: setuptools install failed, try to install setuptools through specified directory
qemu: uninstall old setuptools, try to install setuptools again
```

日志指向为 setuptools 安装失败。尝试挂载 image-tools 的 ISO 进行手动安装：

```bash
mount /dev/sr0 /mnt
mkdir /opt/image-tools
cp -r /mnt/linux/ /opt/image-tools/
umount /mnt
cd /tmp
tar zxvf /root/install/drivers/cloud-init-depends.tar.gz
find /tmp/cloud-init-depends -type f -exec cp {} /opt/image-tools/linux/cloud-init/cloudinit_depend/ \;
cd /opt/image-tools/linux
chmod +x *.sh
./install-cloud-init.sh
```

可以复现相同的报错。

## 排查过程

安装 setuptools 的 Shell 代码位于 `/opt/image-tools/linux/cloud-init/install_script/utils/common_func.sh` ：

```bash
# install python setuptools
fnSetuptoolsInstall()
{
    setuptools_name=${setuptools_pkg}
    cd "${PKG_PATH}" || exit
    tar -xzvf ${setuptools_name}.tar.gz >> "$LOG_FILE" 2>&1
    cd "${PKG_PATH}"/${setuptools_name} || exit
    ${PYTHON_EXEC} bootstrap.py >> "$LOG_FILE" 2>&1
    ${PYTHON_EXEC} setup.py install >> "$LOG_FILE" 2>&1

    if [ $? -ne 0 ]; then
        echo "setuptools install failed, try to install setuptools through specified directory"
        ${PYTHON_EXEC} setup.py install --prefix=/ >> "$LOG_FILE" 2>&1
    fi
    if [ $? -ne 0 -a -n "$(${PYTHON_EXEC} -m pydoc setuptools | grep VERSION)" ]; then
        echo "uninstall old setuptools, try to install setuptools again"
        fnSetuptoolsUnInstall
        ${PYTHON_EXEC} setup.py install >> "$LOG_FILE" 2>&1
    fi
    fnResultCheck ${setuptools_name} $?
}
```

进一步使用 `bash -xv install-cloud-init.sh` 打印 Shell 脚本详细调试信息如下：

```
++ fnSetuptoolsInstall
++ '[' -e /etc/.productinfo ']'
+++ grep -c Kylin /etc/.productinfo
++ '[' 1 -ne 0 ']'
+++ grep -c 'V10 (SP3)' /etc/.productinfo
++ '[' 0 -ne 0 ']'
++ setuptools_name=setuptools-65.6.3
++ cd /opt/image-tools/linux/cloud-init/cloudinit_depend
++ tar -xzvf setuptools-65.6.3.tar.gz
++ cd /opt/image-tools/linux/cloud-init/cloudinit_depend/setuptools-65.6.3
++ python3 bootstrap.py
++ python3 setup.py install
++ '[' 1 -ne 0 ']'
++ echo 'setuptools install failed, try to install setuptools through specified directory'
setuptools install failed, try to install setuptools through specified directory
++ python3 setup.py install --prefix=/
+++ grep VERSION
+++ python3 -m pydoc setuptools
++ '[' 1 -ne 0 -a -n VERSION ']'
++ echo 'uninstall old setuptools, try to install setuptools again'
uninstall old setuptools, try to install setuptools again
```

该脚本实际运行的安装命令如下：

```bash
python3 setup.py install --prefix=/
```

手动执行，发现开源版本 setuptools 不能安装：

```
[root@localhost setuptools-65.6.3]# python3 setup.py install
Traceback (most recent call last):
  File "setup.py", line 87, in <module>
    dist = setuptools.setup(**setup_params)
  File "/opt/image-tools/linux/cloud-init/cloudinit_depend/setuptools-65.6.3/setuptools/__init__.py", line 87, in setup
    return distutils.core.setup(**attrs)
  File "/opt/image-tools/linux/cloud-init/cloudinit_depend/setuptools-65.6.3/setuptools/_distutils/core.py", line 147, in setup
    _setup_distribution = dist = klass(attrs)
  File "/opt/image-tools/linux/cloud-init/cloudinit_depend/setuptools-65.6.3/setuptools/dist.py", line 479, in __init__
    for k, v in attrs.items()
  File "/opt/image-tools/linux/cloud-init/cloudinit_depend/setuptools-65.6.3/setuptools/_distutils/dist.py", line 283, in __init__
    self.finalize_options()
  File "/opt/image-tools/linux/cloud-init/cloudinit_depend/setuptools-65.6.3/setuptools/dist.py", line 898, in finalize_options
    for ep in sorted(loaded, key=by_order):
  File "/opt/image-tools/linux/cloud-init/cloudinit_depend/setuptools-65.6.3/setuptools/dist.py", line 897, in <lambda>
    loaded = map(lambda e: e.load(), filtered)
  File "/opt/image-tools/linux/cloud-init/cloudinit_depend/setuptools-65.6.3/setuptools/_vendor/importlib_metadata/__init__.py", line 196, in load
    return functools.reduce(getattr, attrs, module)
AttributeError: type object 'Distribution' has no attribute '_finalize_feature_opts'
```

其中报错的 python 代码位于 `/opt/image-tools/linux/cloud-init/cloudinit_depend/setuptools-65.6.3/setuptools/__init__.py` ：

```python
from setuptools.dist import Distribution
```

看起来像是 python 在安装时检查 Linux 发行版版本，不识别银河麒麟系列操作系统。因此断定需要安装麒麟修改后的 setuptools 而非开源版本。这一点华为云工程师已经考虑到了，代码 `/opt/image-tools/linux/cloud-init/cloudinit_scripts/offdeploy-cloud-init.sh` 里有对麒麟操作系统的判断：

```bash
# install python setuptools
fnSetuptoolsInstall()
{
    # 当前仅针对Kylin V10 SP3进行特殊处理，使用系统自带的setuptools，其他操作系统仍沿用老的逻辑
    if [ -e /etc/.productinfo ] && [ `grep -c "Kylin" /etc/.productinfo` -ne '0' ] && [ `grep -c "V10 (SP3)" /etc/.productinfo` -ne '0' ]; then
        hasInstallSetuptools=$(python -m pydoc setuptools | grep __version__)
        if [ -n "$hasInstallSetuptools" ]; then
                echo "setuptools has already installed on this machine, skip install setuptools"
                return
        fi
    fi
    setuptools_name=${setuptools_pkg}
    cd "${PKG_PATH}" || exit
    tar -xzvf ${setuptools_name}.tar.gz >> "$LOG_FILE" 2>&1
    cd "${PKG_PATH}"/${setuptools_name} || exit
    ${PYTHON_EXEC} bootstrap.py >> "$LOG_FILE" 2>&1
    ${PYTHON_EXEC} setup.py install >> "$LOG_FILE" 2>&1

    if [ $? -ne 0 ]; then
        echo "setuptools install failed, try to install setuptools through specified directory"
        ${PYTHON_EXEC} setup.py install --prefix=/ >> "$LOG_FILE" 2>&1
    fi
    if [ $? -ne 0 -a -n "$(${PYTHON_EXEC} -m pydoc setuptools | grep VERSION)" ]; then
        echo "uninstall old setuptools, try to install setuptools again"
        fnSetuptoolsUnInstall
        ${PYTHON_EXEC} setup.py install >> "$LOG_FILE" 2>&1
    fi
    if [ $? -ne 0 ]; then
        echo "setuptools install failed, try to install setuptools 41.1.0"
        setuptools_pkg="setuptools-41.1.0"
        setuptools_name=${setuptools_pkg}
        cd "${PKG_PATH}" || exit
        tar -xzvf ${setuptools_name}.tar.gz >> "$LOG_FILE" 2>&1
        cd "${PKG_PATH}"/${setuptools_name} || exit
        ${PYTHON_EXEC} bootstrap.py >> "$LOG_FILE" 2>&1
        ${PYTHON_EXEC} setup.py install >> "$LOG_FILE" 2>&1
    fi
    fnResultCheck ${setuptools_name} $?
}
```

但是此代码仅能判断银河麒麟 V10 SP3 ，实测判断命令在 银河麒麟 V10 SP4 上输出如下：

```
[root@localhost linux]# grep -c "V10 (SP3)" /etc/.productinfo
0
[root@localhost linux]# cat /etc/.productinfo
Kylin Linux Advanced Server
release V10 SP3 2403/(Halberd)-aarch64-Build20/20240426
[root@localhost linux]# python -m pydoc setuptools | grep __version__
-bash: python: command not found
[root@localhost linux]# python3 -m pydoc setuptools | grep __version__
[root@localhost linux]# python2 -m pydoc setuptools | grep __version__
-bash: python2: command not found
[root@localhost linux]# ls -lh /usr/bin/python
ls: cannot access '/usr/bin/python': No such file or directory
[root@localhost linux]# ls -lh /usr/bin/python3
lrwxrwxrwx 1 root root 9 Mar 18  2024 /usr/bin/python3 -> python3.7
```

## 解决方法

修改上述代码，加入 SP4 版本判断逻辑，将以下代码：

```bash
    # 当前仅针对Kylin V10 SP3进行特殊处理，使用系统自带的setuptools，其他操作系统仍沿用老的逻辑
    if [ -e /etc/.productinfo ] && [ `grep -c "Kylin" /etc/.productinfo` -ne '0' ] && [ `grep -c "V10 (SP3)" /etc/.productinfo` -ne '0' ]; then
        hasInstallSetuptools=$(python -m pydoc setuptools | grep __version__)
        if [ -n "$hasInstallSetuptools" ]; then
                echo "setuptools has already installed on this machine, skip install setuptools"
                return
        fi
    fi
```

修改为：

```bash
    if [ -e /etc/.productinfo ] && [ `grep -c "Kylin" /etc/.productinfo` -ne '0' ] && [ `grep -cE "V10 (SP3)|V10 SP3 2403" /etc/.productinfo` -ne '0' ]; then
        hasInstallSetuptools=$(${PYTHON_EXEC} -m pydoc setuptools | grep version)
        if [ -n "$hasInstallSetuptools" ]; then
                echo "setuptools has already installed on this machine, skip install setuptools"
                return
        fi
    fi
```

如果需要使用 Shell 脚本自动化修改，代码如下：

```bash
if [ -e /etc/.productinfo ] && [ `grep -c "Kylin" /etc/.productinfo` -ne '0' ] && [ `grep -cE "V10 (SP3)|V10 SP3 2403" /etc/.productinfo` -ne '0' ]; then
    cp -f /opt/image-tools/linux/cloud-init/cloudinit_scripts/offdeploy-cloud-init.sh /opt/image-tools/linux/cloud-init/cloudinit_scripts/offdeploy-cloud-init.sh.bak
    chmod +w /opt/image-tools/linux/cloud-init/cloudinit_scripts/offdeploy-cloud-init.sh
    sed -i 's/grep -c "V10 (SP3)" \/etc\/.productinfo/grep -cE "V10 (SP3)|V10 SP3 2403" \/etc\/.productinfo/' /opt/image-tools/linux/cloud-init/cloudinit_scripts/offdeploy-cloud-init.sh
    sed -i 's/python -m pydoc setuptools | grep __version__/${PYTHON_EXEC} -m pydoc setuptools | grep version/' /opt/image-tools/linux/cloud-init/cloudinit_scripts/offdeploy-cloud-init.sh
    diff /opt/image-tools/linux/cloud-init/cloudinit_scripts/offdeploy-cloud-init.sh /opt/image-tools/linux/cloud-init/cloudinit_scripts/offdeploy-cloud-init.sh.bak
fi
```

之后重新安装 cloud-init 。
