---
tags:
  - Linux
---

!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

使用ubuntu下载apt源，首先安装软件apt-mirror，然后修改配置文件`/etc/apt/mirror.list`，假设要下载的是deepin的apt源：
```
############# config ##################
#
set base_path    /var/spool/apt-mirror
#
# set mirror_path  $base_path/mirror

# set skel_path    $base_path/skel
# set var_path     $base_path/var
# set cleanscript $var_path/clean.sh
# set defaultarch  <running host architecture>
# set postmirror_script $var_path/postmirror.sh
# set run_postmirror 0
set nthreads     20
set _tilde 0
#
############# end config ##############
deb https://mirrors.tuna.tsinghua.edu.cn/deepin apricot main contrib non-free
deb-i386 https://mirrors.tuna.tsinghua.edu.cn/deepin apricot main contrib non-free
clean https://mirrors.tuna.tsinghua.edu.cn/deepin
```
其中`/var/spool/apt-mirror`是下载路径，可以根据需要修改。之后下载apt源：
```bash
nohup apt-mirror &
```
下载日志在 nohup.out查看：
```bash
tail -f nohup.out
```
